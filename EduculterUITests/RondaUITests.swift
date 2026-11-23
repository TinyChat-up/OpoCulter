import XCTest

/// Base de los tests de interfaz: arranque, auditoría de accesibilidad con excepciones
/// justificadas (D-048) y toques que desplazan el contenido si hace falta.
class CasoUI: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func lanzar(_ extra: [String] = [], base: [String] = ["-enMemoria", "-semilla", "42", "-ayudasDePrueba", "-avatar", "0"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = base + extra
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60))
        return app
    }

    /// Incidencias de accesibilidad acumuladas en el test (se informa de todas al final).
    var incidencias: [String] = []

    /// Excepciones justificadas (D-048):
    /// - `bordesDelScroll`: en Hoy, el contenido que el scroll deja bajo la barra de pestañas
    ///   flotante o bajo el efecto de borde superior (material del sistema) da falsos positivos
    ///   de contraste que dependen de la posición del scroll.
    /// - `trasPopover`: con el globo de la racha abierto, el contenido de Hoy sigue visible
    ///   detrás del popover modal y VoiceOver lo ignora (correcto), lo que la auditoría marca
    ///   como "texto potencialmente inaccesible" sin elemento asociado.
    /// - Siempre: el contraste de un elemento del contenido del scroll que queda fuera de su
    ///   área visible (oculto o recortado por el borde) se mide sobre píxeles que no son suyos; se
    ///   ignora solo en ese caso. Si está entero a la vista, cuenta.
    @MainActor
    func auditar(_ app: XCUIApplication, _ pantalla: String, bordesDelScroll: Bool = false, trasPopover: Bool = false) throws {
        let alto = app.windows.firstMatch.frame.maxY
        // Se espera a que terminen las transiciones (los fundidos bajan el contraste temporalmente).
        Thread.sleep(forTimeInterval: 1)
        let scroll = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch.frame : .null
        // Si el simulador va lento, la auditoría puede agotar su tiempo (código -56): se repite
        // una sola vez. Las incidencias reales nunca se reintentan.
        do {
            try auditarUnaVez(app, pantalla, alto: alto, scroll: scroll, bordesDelScroll: bordesDelScroll, trasPopover: trasPopover)
        } catch let error as NSError where error.code == -56 {
            print("AUDITORIA-REINTENTO [\(pantalla)] \(error.localizedDescription)")
            Thread.sleep(forTimeInterval: 2)
            try auditarUnaVez(app, pantalla, alto: alto, scroll: scroll, bordesDelScroll: bordesDelScroll, trasPopover: trasPopover)
        }
    }

    @MainActor
    private func auditarUnaVez(_ app: XCUIApplication, _ pantalla: String, alto: CGFloat, scroll: CGRect,
                               bordesDelScroll: Bool, trasPopover: Bool) throws {
        try app.performAccessibilityAudit { incidencia in
            if incidencia.auditType == .contrast, let e = incidencia.element, !scroll.isNull,
               e.frame.maxY > scroll.maxY + 0.5 || e.frame.minY < scroll.minY - 0.5,
               Self.perteneceAlScroll(e, app) {
                print("AUDITORIA-EXCEPCION [\(pantalla)] oculto o recortado por el borde del scroll: \(e.label)")
                return true
            }
            if bordesDelScroll, incidencia.auditType == .contrast, let e = incidencia.element,
               e.frame.maxY > alto - 90 || e.frame.minY < 130 {
                print("AUDITORIA-EXCEPCION [\(pantalla)] contraste bajo una barra del sistema: \(e.label)")
                return true
            }
            if trasPopover, incidencia.element == nil, incidencia.compactDescription.contains("inaccessible text") {
                print("AUDITORIA-EXCEPCION [\(pantalla)] texto de Hoy tras el popover modal")
                return true
            }
            let texto = "[\(pantalla)] \(incidencia.compactDescription) · \(incidencia.element?.debugDescription.prefix(160) ?? "-")"
            self.incidencias.append(texto)
            print("AUDITORIA \(texto)")
            return true
        }
    }

    /// El elemento forma parte del contenido del scroll (no es, p. ej., un botón del pie).
    @MainActor
    private static func perteneceAlScroll(_ e: XCUIElement, _ app: XCUIApplication) -> Bool {
        let candidatos = app.scrollViews.firstMatch.descendants(matching: e.elementType)
            .matching(NSPredicate(format: "label == %@", e.label))
        return candidatos.allElementsBoundByIndex.contains { $0.frame == e.frame }
    }

    override func tearDownWithError() throws {
        let lista = incidencias
        incidencias = []
        XCTAssertTrue(lista.isEmpty, "Incidencias de accesibilidad (\(lista.count)):\n" + lista.joined(separator: "\n"))
    }

    @MainActor
    func tocar(_ app: XCUIApplication, _ ids: [String]) {
        for id in ids {
            let e = app.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "No existe \(id)")
            // Si el elemento queda bajo el panel inferior (Comprobar), se desplaza el contenido.
            let panel = app.buttons["botonComprobar"].frame.minY
            var intentos = 0
            while e.frame.maxY > panel - 4, intentos < 4 {
                app.scrollViews.firstMatch.swipeUp(velocity: .slow)
                intentos += 1
            }
            e.tap()
        }
    }
}

/// Tests de interfaz de las Fases 05A y 05B (ronda recomendada y todas las mecánicas).
final class RondaUITests: CasoUI {
    /// Ronda recomendada de principio a fin (Hoy → ronda → feedback → resumen → Hoy).
    @MainActor
    func testRondaRecomendadaCompleta() throws {
        let app = lanzar()
        // Hoy arriba y desplazado hasta el final (el margen inferior deja ver todo el contenido).
        try auditar(app, "Hoy", bordesDelScroll: true)
        app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        Thread.sleep(forTimeInterval: 3)
        try auditar(app, "Hoy (final)", bordesDelScroll: true)
        app.scrollViews.firstMatch.swipeDown(velocity: .slow)
        Thread.sleep(forTimeInterval: 3)
        // Globo explicativo de la racha.
        app.buttons["chipRacha"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["globoRacha"].waitForExistence(timeout: 5))
        try auditar(app, "Globo de racha", bordesDelScroll: true, trasPopover: true)
        let globo = app.descendants(matching: .any)["globoRacha"]
        let fuera = app.otherElements["PopoverDismissRegion"].firstMatch
        if fuera.exists { fuera.tap() } else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap() }
        XCTAssertTrue(globo.waitForNonExistence(timeout: 5), "El globo debería cerrarse al tocar fuera")
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 5))
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) {
            try auditar(app, "Teoría previa")
            app.buttons["botonEmpezarTrasTeoria"].tap()
        }
        var vueltas = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 10 {
            XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 10), app.debugDescription)
            app.buttons["botonRellenarDebug"].tap()
            app.buttons["botonComprobar"].tap()
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
            app.buttons["botonContinuar"].tap()
            vueltas += 1
        }
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        XCTAssertTrue((6...8).contains(vueltas), "La ronda debe tener 6–8 ítems (tiene \(vueltas))")
        try auditar(app, "Resumen")
        let terminar = app.buttons["botonTerminar"]
        while !terminar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        terminar.tap()
        let racha = app.descendants(matching: .any)["chipRacha"].firstMatch
        XCTAssertTrue(racha.waitForExistence(timeout: 5))
        XCTAssertTrue((racha.value as? String ?? "").hasPrefix("1 día"), "Racha tras la ronda: \(racha.value ?? "")")
    }

    /// Ronda de demostración con las 10 mecánicas, respondiendo con toques reales (modo sin
    /// arrastre) donde es posible y auditando la accesibilidad de cada mecánica.
    @MainActor
    func testTodasLasMecanicasConAuditoria() throws {
        let app = lanzar(["-rondaDemostracion"])
        app.buttons["botonEmpezarRonda"].tap()

        // Toques por mecánica (ítems de demostración fijos: `EntornoApp.demostracionPreferida`).
        let toques: [String: [String]] = [
            "eleccion": ["opcion_a"],
            "verdaderoFalso": ["botonFalso"],
            "clasificar": ["ficha_f1", "caja_SUS", "ficha_f2", "caja_SUS", "ficha_f3", "caja_ADJ", "ficha_f4", "caja_ADJ"],
            "emparejar": ["izq_i1", "der_d2", "izq_i2", "der_d3", "izq_i3", "der_d1"],
            "marcarTexto": ["token_t2", "token_t5"],
            "segmentar": ["seg_token_t1", "seg_token_t6", "etiqueta_PRED",
                          "seg_token_t1", "seg_token_t1", "etiqueta_NV",
                          "seg_token_t2", "seg_token_t6", "etiqueta_CCL",
                          "seg_token_t5", "seg_token_t6", "etiqueta_CN"],
            "construir": ["pieza_p1", "pieza_p3"],
            "numerico": ["tecla3", "teclaFraccion", "tecla4"],
            "colocarTilde": ["letra_5"],
            "fraccionBarras": ["botonMasPartes", "celda_0", "celda_1"],
        ]
        var vistas: [String] = []
        for _ in 0..<12 {
            let mecanica = try XCTUnwrap(["eleccion", "verdaderoFalso", "clasificar", "ordenar", "emparejar", "marcarTexto",
                                          "segmentar", "ruedas", "construir", "numerico", "colocarTilde", "fraccionBarras"].first { app.descendants(matching: .any)["mecanica_\($0)"].waitForExistence(timeout: 1) },
                                         "No se reconoce la mecánica en pantalla")
            vistas.append(mecanica)
            try auditar(app, mecanica)
            if let ids = toques[mecanica] {
                tocar(app, ids)
            } else {
                app.buttons["botonRellenarDebug"].tap()
            }
            app.buttons["botonComprobar"].tap()
            XCTAssertTrue(app.staticTexts["¡Correcto!"].waitForExistence(timeout: 5), "La respuesta de \(mecanica) debería ser correcta")
            try auditar(app, "\(mecanica) corregido")
            app.buttons["botonContinuar"].tap()
        }
        XCTAssertEqual(Set(vistas).count, 12)
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        try auditar(app, "Resumen")
    }
}
