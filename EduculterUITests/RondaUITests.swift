import XCTest

/// Base de los tests de interfaz: arranque, auditoría de accesibilidad con excepciones
/// justificadas (D-048) y toques que desplazan el contenido si hace falta.
extension XCTestCase {
    /// Pulsa «Comprobar»; si el ítem es de un juego y se abre el reintento (contrato de intento, 05G),
    /// repite la misma respuesta y vuelve a comprobar.
    @MainActor
    func comprobar(_ app: XCUIApplication, rellenar boton: String) {
        app.buttons["botonComprobar"].tap()
        if !app.buttons["botonContinuar"].waitForExistence(timeout: 3), app.descendants(matching: .any)["pistaReintento"].exists {
            app.buttons[boton].tap()
            app.buttons["botonComprobar"].tap()
        }
    }
}

class CasoUI: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func lanzar(_ extra: [String] = [], base: [String] = ["-enMemoria", "-semilla", "42", "-ayudasDePrueba", "-avatar", "0"]) -> XCUIApplication {
        let app = XCUIApplication()
        // La pregunta del recordatorio tras la primera ronda tiene su propio test (ModosUITests).
        app.launchArguments = base + extra + (extra.contains("-conAvisoRecordatorio") ? [] : ["-sinAvisoRecordatorio"])
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60))
        return app
    }

    /// Juega la ronda en pantalla hasta el resumen (o el plan del diagnóstico) con el botón de
    /// pruebas, que también deja vistos los pasos de un ejemplo resuelto. Devuelve los ítems jugados.
    @MainActor
    @discardableResult
    func jugarHastaElFinal(_ app: XCUIApplication, maximo: Int = 40, fallos: Set<Int> = []) -> Int {
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }
        var vueltas = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && !app.descendants(matching: .any)["pantallaPlan"].exists && vueltas < maximo {
            XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 10), app.debugDescription)
            let boton = fallos.contains(vueltas) ? "botonRellenarErrorDebug" : "botonRellenarDebug"
            app.buttons[boton].tap()
            comprobar(app, rellenar: boton)
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
            app.buttons["botonContinuar"].tap()
            vueltas += 1
        }
        return vueltas
    }

    /// Elige la duración de la sesión en Hoy (5, 10 o 15 min).
    @MainActor
    func elegirDuracion(_ app: XCUIApplication, _ minutos: Int) {
        let boton = app.segmentedControls["selectorDuracion"].buttons["\(minutos) min"]
        XCTAssertTrue(boton.waitForExistence(timeout: 5))
        var n = 0
        while !boton.isHittable && n < 8 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); n += 1 }
        boton.tap()
        XCTAssertTrue(boton.isSelected)
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
        let filtro: (XCUIAccessibilityAuditIssue) throws -> Bool = { incidencia in
            if incidencia.auditType == .contrast, let e = incidencia.element, !scroll.isNull,
               e.frame.maxY > scroll.maxY + 0.5 || e.frame.minY < scroll.minY - 0.5,
               Self.perteneceAlScroll(e, app) {
                print("AUDITORIA-EXCEPCION [\(pantalla)] oculto o recortado por el borde del scroll: \(e.label)")
                return true
            }
            // Texto del scroll visto a través de la barra de pestañas translúcida: la auditoría lo
            // detecta en la imagen sin elemento asociado (comprobado al final del scroll, donde el
            // contenido acaba por encima de la barra y la incidencia desaparece).
            if bordesDelScroll, incidencia.element == nil, incidencia.compactDescription.contains("inaccessible text") {
                print("AUDITORIA-EXCEPCION [\(pantalla)] texto del scroll bajo la barra de pestañas")
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
            print("AUDITORIA-DETALLE [\(pantalla)] \(incidencia.detailedDescription)")
            self.incidencias.append(texto)
            print("AUDITORIA \(texto)")
            return true
        }
        // El contraste se audita primero y por separado: la comprobación de Dynamic Type cambia el
        // tamaño del texto y, con el scroll al final del contenido, lo desplaza; en una sola pasada,
        // el contraste llegaba a medirse sobre píxeles que ya no eran del elemento (D-075).
        try app.performAccessibilityAudit(for: .contrast, filtro)
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(.contrast), filtro)
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
    /// Sesión diaria de principio a fin (Hoy → 5 minutos → feedback → resumen → Hoy).
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
        // Sesión de 5 minutos (8 preguntas): la duración elegida se ve debajo de «Empezar».
        elegirDuracion(app, 5)
        XCTAssertTrue(app.staticTexts["duracionSesion"].label.contains("8 preguntas"), app.staticTexts["duracionSesion"].label)
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) {
            try auditar(app, "Teoría previa")
            app.buttons["botonEmpezarTrasTeoria"].tap()
        }
        let vueltas = jugarHastaElFinal(app)
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        XCTAssertEqual(vueltas, 8, "La sesión de 5 minutos tiene 8 preguntas")
        XCTAssertTrue(app.buttons["botonOtraRonda"].label.contains("5 minutos más"))
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
            // Desde la 05H, el ítem de segmentar es generado (morfemas): se responde con el botón de pruebas.
            if let ids = toques[mecanica] {
                tocar(app, ids)
            } else {
                app.buttons["botonRellenarDebug"].tap()
            }
            comprobar(app, rellenar: "botonRellenarDebug")
            XCTAssertTrue(app.staticTexts["¡Correcto!"].waitForExistence(timeout: 5), "La respuesta de \(mecanica) debería ser correcta")
            try auditar(app, "\(mecanica) corregido")
            app.buttons["botonContinuar"].tap()
        }
        XCTAssertEqual(Set(vistas).count, 12)
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        try auditar(app, "Resumen")
    }
}
