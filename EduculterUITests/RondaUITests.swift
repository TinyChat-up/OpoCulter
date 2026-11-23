import XCTest

/// Tests de interfaz de la Fase 05A. Se ejecutan en Debug con progreso en memoria y semilla fija.
final class RondaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func lanzar(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-semilla", "42", "-ayudasDePrueba"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60))
        return app
    }

    /// Incidencias de accesibilidad acumuladas en el test (se informa de todas al final).
    private var incidencias: [String] = []

    /// Excepción justificada: en Hoy, el contenido que el scroll deja bajo la barra de pestañas
    /// (material translúcido) da falsos positivos de contraste que dependen de la posición.
    @MainActor
    private func auditar(_ app: XCUIApplication, _ pantalla: String, ignorarBajoBarraPestanas: Bool = false) throws {
        let limite = app.windows.firstMatch.frame.maxY - 90
        // Se espera a que terminen las transiciones (los fundidos bajan el contraste temporalmente).
        Thread.sleep(forTimeInterval: 1)
        try app.performAccessibilityAudit { incidencia in
            if ignorarBajoBarraPestanas, incidencia.auditType == .contrast, let e = incidencia.element, e.frame.maxY > limite {
                print("AUDITORIA-EXCEPCION [\(pantalla)] contraste bajo la barra de pestañas: \(e.label)")
                return true
            }
            let texto = "[\(pantalla)] \(incidencia.compactDescription) · \(incidencia.element?.debugDescription.prefix(160) ?? "-")"
            self.incidencias.append(texto)
            print("AUDITORIA \(texto)")
            return true
        }
    }

    override func tearDownWithError() throws {
        let lista = incidencias
        incidencias = []
        XCTAssertTrue(lista.isEmpty, "Incidencias de accesibilidad (\(lista.count)):\n" + lista.joined(separator: "\n"))
    }

    @MainActor
    private func tocar(_ app: XCUIApplication, _ ids: [String]) {
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

    /// Ronda recomendada de principio a fin (Hoy → ronda → feedback → resumen → Hoy).
    @MainActor
    func testRondaRecomendadaCompleta() throws {
        let app = lanzar()
        try auditar(app, "Hoy", ignorarBajoBarraPestanas: true)
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) {
            try auditar(app, "Teoría previa")
            app.buttons["botonEmpezarTrasTeoria"].tap()
        }
        var vueltas = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 10 {
            XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 10))
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
    func testDiezMecanicasConAuditoria() throws {
        let app = lanzar(["-rondaDemostracion"])
        app.buttons["botonEmpezarRonda"].tap()

        // Toques por mecánica (ítems de demostración: el primero de cada mecánica en el banco).
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
            "construir": ["pieza_p1", "pieza_p4"],
            "numerico": ["tecla3", "teclaFraccion", "tecla4"],
        ]
        var vistas: [String] = []
        for _ in 0..<10 {
            let mecanica = try XCTUnwrap(["eleccion", "verdaderoFalso", "clasificar", "ordenar", "emparejar", "marcarTexto",
                                          "segmentar", "ruedas", "construir", "numerico"].first { app.descendants(matching: .any)["mecanica_\($0)"].waitForExistence(timeout: 1) },
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
        XCTAssertEqual(Set(vistas).count, 10)
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        try auditar(app, "Resumen")
    }
}
