import XCTest

/// Tests de interfaz de la Fase 05E parte 2: Hoy y la sesión diaria, el ejemplo resuelto paso a
/// paso, el resumen, el motor de errores (Rescate y Progreso), la meta semanal y el modo descanso,
/// y la auditoría de accesibilidad en modo oscuro y con texto grande.
final class SesionDiariaUITests: CasoUI {
    @MainActor
    private func pestana(_ app: XCUIApplication, _ nombre: String) {
        let boton = app.tabBars.buttons[nombre].firstMatch
        XCTAssertTrue(boton.waitForExistence(timeout: 10))
        boton.tap()
    }

    @MainActor
    private func visible(_ app: XCUIApplication, _ e: XCUIElement) {
        XCTAssertTrue(e.waitForExistence(timeout: 10), e.debugDescription)
        var n = 0
        while !e.isHittable && n < 10 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); n += 1 }
    }

    @MainActor
    private func terminar(_ app: XCUIApplication) {
        let b = app.buttons["botonTerminar"]
        visible(app, b)
        b.tap()
    }

    /// Sesión de 5 minutos de Matemáticas: el primer bloque nuevo (peldaño 1) es un ejemplo resuelto,
    /// con los pasos uno a uno, «Comprobar» solo al final y el gemelo detrás; después, el resumen.
    @MainActor
    func testSesionConEjemploResueltoYResumen() throws {
        let app = lanzar(["-politicaRelease"])
        try auditar(app, "Hoy", bordesDelScroll: true)
        XCTAssertTrue(app.descendants(matching: .any)["puntosSemana"].exists, "Meta semanal en Hoy")
        let mates = app.segmentedControls["selectorArea"].buttons["Matemáticas"]
        visible(app, mates)
        mates.tap()
        elegirDuracion(app, 5)
        app.scrollViews.firstMatch.swipeDown()
        let empezar = app.buttons["botonEmpezarRonda"]
        visible(app, empezar)
        empezar.tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }

        var ejemplos = 0, vueltas = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 12 {
            XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 10))
            if app.descendants(matching: .any)["ejemploResuelto"].exists {
                ejemplos += 1
                // Paso a paso: el primero a la vista; con más de dos pasos, sin «Comprobar» hasta el final.
                XCTAssertTrue(app.descendants(matching: .any)["paso_1"].exists)
                XCTAssertTrue(app.descendants(matching: .any)["paso_1"].label.hasPrefix("Paso 1:"), "VoiceOver lee el paso")
                XCTAssertNotEqual(app.buttons["botonComprobar"].exists, app.buttons["botonSiguientePaso"].exists)
                if ejemplos == 1 { try auditar(app, "Ejemplo resuelto") }
                var n = 1
                while app.buttons["botonSiguientePaso"].exists && n < 6 {
                    app.buttons["botonSiguientePaso"].tap()
                    n += 1
                    XCTAssertTrue(app.descendants(matching: .any)["paso_\(n)"].waitForExistence(timeout: 3) || app.buttons["botonComprobar"].exists)
                }
                // El último paso lo completa el usuario.
                XCTAssertTrue(app.descendants(matching: .any)["pasoFinal"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.buttons["botonComprobar"].exists)
                if ejemplos == 1 { try auditar(app, "Ejemplo resuelto: último paso") }
            }
            app.buttons["botonRellenarDebug"].tap()
            app.buttons["botonComprobar"].tap()
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
            app.buttons["botonContinuar"].tap()
            vueltas += 1
        }
        XCTAssertGreaterThanOrEqual(ejemplos, 1, "Lo nuevo del peldaño 1 empieza con un ejemplo resuelto")
        XCTAssertEqual(vueltas, 8)
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["resumenXP"].exists)
        XCTAssertTrue(app.buttons["botonOtraRonda"].label.contains("5 minutos más"))
        try auditar(app, "Resumen de la sesión")
        terminar(app)
        // La sesión cuenta para la meta semanal.
        let semana = app.staticTexts["metaSemanalTexto"]
        XCTAssertTrue(semana.waitForExistence(timeout: 10))
        XCTAssertTrue(semana.label.contains("1 de 4 días"), semana.label)
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }

    /// Error activo (historial de prueba: dos fallos del mismo error de porcentajes): Rescate lo
    /// agrupa primero, Progreso lo muestra y la sesión trae su remedio.
    @MainActor
    func testErrorActivoEnRescateProgresoYSesion() throws {
        let app = lanzar(["-politicaRelease", "-errorDemo"])
        let rescate = app.buttons["botonRescate"]
        visible(app, rescate)
        XCTAssertTrue(rescate.label.contains("1 error activo"), rescate.label)
        rescate.tap()
        let grupo = app.descendants(matching: .any)["grupoError_ERR.MAT.POR.TOTAL.4"]
        XCTAssertTrue(grupo.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Errores que se repiten"].exists)
        try auditar(app, "Rescate por error")
        app.buttons["botonCerrarRescate"].tap()
        pestana(app, "Progreso")
        let fila = app.descendants(matching: .any)["error_ERR.MAT.POR.TOTAL.4"]
        XCTAssertTrue(fila.waitForExistence(timeout: 10))
        XCTAssertTrue(fila.label.contains("2 veces"), fila.label)
        XCTAssertTrue(app.descendants(matching: .any)["seccionNivelExamen"].exists)
        try auditar(app, "Progreso con errores", bordesDelScroll: true)
        // Al final del scroll (logros), sin nada bajo la barra de pestañas.
        for _ in 0..<12 { app.scrollViews.firstMatch.swipeUp() }
        try auditar(app, "Progreso al final", bordesDelScroll: true)
        // La sesión de Matemáticas empieza por el remedio (primero en la prioridad).
        pestana(app, "Hoy")
        let mates = app.segmentedControls["selectorArea"].buttons["Matemáticas"]
        visible(app, mates)
        mates.tap()
        app.scrollViews.firstMatch.swipeDown()
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }
        let cabecera = app.descendants(matching: .any)["cabeceraCompetencia"]
        XCTAssertTrue(cabecera.waitForExistence(timeout: 10))
        XCTAssertTrue(cabecera.label.uppercased().contains("PORCENTAJE") || cabecera.label.uppercased().contains("TOTAL"), cabecera.label)
    }

    /// Ajustes: meta semanal (3–7) y modo descanso; Hoy los refleja.
    @MainActor
    func testMetaSemanalYModoDescanso() throws {
        let app = lanzar(["-politicaRelease"])
        pestana(app, "Progreso")
        let ajustes = app.buttons["botonAjustes"]
        visible(app, ajustes)
        ajustes.tap()
        let meta = app.steppers["ajusteMetaSemanal"]
        XCTAssertTrue(meta.waitForExistence(timeout: 10))
        meta.buttons.element(boundBy: 1).tap()   // +1: 5 días
        let cinco = NSPredicate(format: "label CONTAINS '5 días'")
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: cinco, object: meta)], timeout: 5), .completed, meta.label)
        let descanso = app.switches["ajusteDescanso"]
        visible(app, descanso)
        descanso.switches.firstMatch.tap()
        XCTAssertEqual(descanso.value as? String, "1")
        XCTAssertTrue(app.staticTexts["textoDescanso"].label.contains("Te quedan"), app.staticTexts["textoDescanso"].label)
        try auditar(app, "Ajustes: meta y descanso", bordesDelScroll: true)
        pestana(app, "Hoy")
        let semana = app.staticTexts["metaSemanalTexto"]
        XCTAssertTrue(semana.waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["avisoDescanso"].exists, "Modo descanso visible en Hoy")
        // Con descanso, hoy figura como día de descanso.
        let hoy = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'dia_' AND value == 'descanso'"))
        XCTAssertGreaterThanOrEqual(hoy.count, 1, semana.label)
        try auditar(app, "Hoy en descanso", bordesDelScroll: true)
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }

    /// Auditoría en modo oscuro y con texto de accesibilidad grande: Hoy, ejemplo resuelto,
    /// resumen y Progreso.
    @MainActor
    func testAuditoriaOscuroYTextoGrande() throws {
        let grande = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        for modo in [["-modoOscuro"], grande, ["-modoOscuro"] + grande] {
            let nombre = modo.joined(separator: " ")
            let app = lanzar(["-politicaRelease", "-errorDemo"] + modo)
            try auditar(app, "Hoy \(nombre)", bordesDelScroll: true)
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
            try auditar(app, "Hoy abajo \(nombre)", bordesDelScroll: true)
            pestana(app, "Progreso")
            XCTAssertTrue(app.descendants(matching: .any)["seccionErrores"].waitForExistence(timeout: 10))
            try auditar(app, "Progreso \(nombre)", bordesDelScroll: true)
            pestana(app, "Hoy")
            let empezar = app.buttons["botonEmpezarRonda"]
            app.scrollViews.firstMatch.swipeDown()
            visible(app, empezar)
            empezar.tap()
            if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }
            var vueltas = 0, ejemplo = false
            while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 30 {
                XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 10))
                if !ejemplo && app.descendants(matching: .any)["ejemploResuelto"].exists {
                    ejemplo = true
                    try auditar(app, "Ejemplo resuelto \(nombre)")
                }
                app.buttons["botonRellenarDebug"].tap()
                app.buttons["botonComprobar"].tap()
                XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
                app.buttons["botonContinuar"].tap()
                vueltas += 1
            }
            XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
            try auditar(app, "Resumen \(nombre)")
            app.terminate()
        }
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }
}
