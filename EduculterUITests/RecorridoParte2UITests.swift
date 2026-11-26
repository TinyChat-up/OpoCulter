import XCTest

/// Recorrido de la Fase 05E parte 2 (§6): una captura por pantalla, en el simulador o en el iPhone.
/// Historial de prueba solo en Debug: `-errorDemo` deja activo un error de porcentajes, así que la
/// sesión de Matemáticas trae su remedio.
final class RecorridoParte2UITests: CasoUI {
    @MainActor
    private func captura(_ nombre: String, _ imagen: XCUIScreenshot) {
        let adjunto = XCTAttachment(screenshot: imagen)
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
    }

    @MainActor
    private func captura(_ app: XCUIApplication, _ nombre: String) {
        Thread.sleep(forTimeInterval: 1)
        captura(nombre, app.screenshot())
    }

    @MainActor
    private func visible(_ app: XCUIApplication, _ e: XCUIElement) {
        XCTAssertTrue(e.waitForExistence(timeout: 15), e.debugDescription)
        var n = 0
        while !e.isHittable && n < 10 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); n += 1 }
    }

    @MainActor
    func testRecorridoParte2() throws {
        // Icono en la pantalla de inicio, junto a otras apps.
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        captura("00_inicio_icono", XCUIScreen.main.screenshot())

        // Lanzamiento (captura inmediata) y bienvenida.
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-semilla", "21", "-ayudasDePrueba", "-politicaRelease", "-sinAvisoRecordatorio", "-errorDemo"]
        app.launch()
        captura("01_lanzamiento", XCUIScreen.main.screenshot())
        XCTAssertTrue(app.descendants(matching: .any)["pantallaBienvenida"].waitForExistence(timeout: 60))
        captura(app, "02_bienvenida")
        app.buttons["avatar_1"].tap()
        app.buttons["botonEmpezarBienvenida"].tap()
        XCTAssertTrue(app.buttons["botonSaltarDiagnostico"].waitForExistence(timeout: 15))
        app.buttons["botonSaltarDiagnostico"].tap()

        // Hoy: foco Matemáticas y 5 minutos.
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 15))
        let mates = app.segmentedControls["selectorArea"].buttons["Matemáticas"]
        visible(app, mates)
        mates.tap()
        elegirDuracion(app, 5)
        app.scrollViews.firstMatch.swipeDown()
        captura(app, "03_hoy")
        app.scrollViews.firstMatch.swipeUp()
        captura(app, "04_hoy_modos")
        app.scrollViews.firstMatch.swipeDown()

        // Sesión de 5 minutos: remedio (el error activo), ejemplo resuelto y el resto.
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) {
            captura(app, "05_teoria_previa")
            app.buttons["botonEmpezarTrasTeoria"].tap()
        }
        var vueltas = 0, ejemplo = false, remedio = false
        while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 12 {
            XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 15))
            let cabecera = app.descendants(matching: .any)["cabeceraCompetencia"].label.uppercased()
            if !remedio && (cabecera.contains("PORCENTAJE") || cabecera.contains("TOTAL")) {
                remedio = true
                captura(app, "06_remedio")
            }
            if !ejemplo && app.descendants(matching: .any)["ejemploResuelto"].exists {
                ejemplo = true
                captura(app, "07_ejemplo_paso1")
                while app.buttons["botonSiguientePaso"].exists { app.buttons["botonSiguientePaso"].tap() }
                captura(app, "08_ejemplo_ultimo_paso")
            }
            // El segundo ítem se falla para ver la corrección con los pasos.
            app.buttons[vueltas == 1 ? "botonRellenarErrorDebug" : "botonRellenarDebug"].tap()
            app.buttons["botonComprobar"].tap()
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 10))
            if vueltas == 1 { captura(app, "09_fallo") }
            app.buttons["botonContinuar"].tap()
            vueltas += 1
        }
        XCTAssertTrue(remedio, "La sesión trae el remedio del error activo")
        XCTAssertTrue(ejemplo, "La sesión empieza lo nuevo con un ejemplo resuelto")
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 15))
        captura(app, "10_resumen")
        app.scrollViews.firstMatch.swipeUp()
        captura(app, "11_resumen_abajo")
        let terminar = app.buttons["botonTerminar"]
        visible(app, terminar)
        terminar.tap()

        // Rescate agrupado por error.
        let rescate = app.buttons["botonRescate"]
        visible(app, rescate)
        rescate.tap()
        XCTAssertTrue(app.buttons["botonCerrarRescate"].waitForExistence(timeout: 15))
        captura(app, "12_rescate")
        app.buttons["botonCerrarRescate"].tap()

        // Progreso: errores y nivel examen.
        app.tabBars.buttons["Progreso"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["seccionErrores"].waitForExistence(timeout: 15))
        captura(app, "13_progreso")
        app.scrollViews.firstMatch.swipeUp()
        captura(app, "14_progreso_2")

        // Ajustes: meta semanal y modo descanso.
        let ajustes = app.buttons["botonAjustes"]
        visible(app, ajustes)
        ajustes.tap()
        XCTAssertTrue(app.steppers["ajusteMetaSemanal"].waitForExistence(timeout: 15))
        captura(app, "15_ajustes")
        let descanso = app.switches["ajusteDescanso"]
        visible(app, descanso)
        descanso.switches.firstMatch.tap()
        captura(app, "16_ajustes_descanso")
        app.tabBars.buttons["Hoy"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["avisoDescanso"].waitForExistence(timeout: 15))
        app.scrollViews.firstMatch.swipeDown()
        captura(app, "17_hoy_descanso")
    }
}
