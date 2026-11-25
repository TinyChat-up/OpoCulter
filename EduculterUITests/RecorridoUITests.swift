import XCTest

/// Recorrido de extremo a extremo con el contenido de Release y un almacén nuevo en disco:
/// bienvenida → diagnóstico → plan → Hoy → ronda de Camino → Supervivencia → Rescate → Progreso →
/// Ajustes; después, una ronda de comprensión con texto base y otra de frases con hueco (`-rondaItems`).
/// Guarda una captura de cada pantalla (`XCTAttachment`, se conservan siempre) para
/// revisar en el iPhone lo que ve el usuario. Las respuestas se dan con los botones de pruebas
/// (solo Debug), unas bien y otras mal, para que Rescate y Progreso tengan datos reales.
final class RecorridoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func captura(_ app: XCUIApplication, _ nombre: String) {
        let adjunto = XCTAttachment(screenshot: app.screenshot())
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
    }

    @MainActor
    private func responder(_ app: XCUIApplication, correcto: Bool, capturaCorregido: String? = nil) {
        let boton = app.buttons[correcto ? "botonRellenarDebug" : "botonRellenarErrorDebug"]
        XCTAssertTrue(boton.waitForExistence(timeout: 15))
        boton.tap()
        app.buttons["botonComprobar"].tap()
        XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 10))
        if let capturaCorregido { captura(app, capturaCorregido) }
        app.buttons["botonContinuar"].tap()
    }

    /// Toca un elemento después de desplazarlo fuera de la zona de la barra de pestañas flotante.
    @MainActor
    private func tocarVisible(_ app: XCUIApplication, _ e: XCUIElement) {
        XCTAssertTrue(e.waitForExistence(timeout: 15))
        let alto = app.windows.firstMatch.frame.maxY
        var vueltas = 0
        while (!e.isHittable || e.frame.maxY > alto - 120) && vueltas < 8 {
            app.scrollViews.firstMatch.swipeUp()
            vueltas += 1
        }
        e.tap()
    }

    /// Cambia de pestaña. En iOS 26+ la barra de pestañas flotante se minimiza al desplazar: se
    /// desplaza hacia arriba hasta que la pestaña se pueda pulsar y se comprueba el destino.
    @MainActor
    private func pestana(_ app: XCUIApplication, _ nombre: String, destino: XCUIElement) {
        for _ in 0..<4 {
            let boton = app.tabBars.buttons[nombre].firstMatch
            var vueltas = 0
            while !(boton.exists && boton.isHittable) && vueltas < 5 { app.swipeDown(); vueltas += 1 }
            if boton.isHittable { boton.tap() }
            if destino.waitForExistence(timeout: 5) { return }
        }
        XCTFail("No se pudo abrir la pestaña \(nombre)")
    }

    @MainActor
    private func terminarRonda(_ app: XCUIApplication) {
        let terminar = app.buttons["botonTerminar"]
        XCTAssertTrue(terminar.waitForExistence(timeout: 10))
        var vueltas = 0
        while !terminar.isHittable && vueltas < 8 { app.scrollViews.firstMatch.swipeUp(); vueltas += 1 }
        terminar.tap()
    }

    @MainActor
    func testRecorridoCompleto() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-almacenPruebas", "UITestRecorrido", "-borrarAlmacen", "-semilla", "11", "-ayudasDePrueba",
                               "-politicaRelease", "-sinAvisoRecordatorio"]
        app.launch()

        // Bienvenida y diagnóstico.
        XCTAssertTrue(app.descendants(matching: .any)["pantallaBienvenida"].waitForExistence(timeout: 60))
        captura(app, "01_bienvenida")
        app.buttons["avatar_1"].tap()
        app.buttons["botonEmpezarBienvenida"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["ofertaDiagnostico"].waitForExistence(timeout: 15))
        captura(app, "02_oferta_diagnostico")
        app.buttons["botonEmpezarDiagnostico"].tap()
        XCTAssertTrue(app.staticTexts["progresoDiagnostico"].waitForExistence(timeout: 15))
        captura(app, "03_diagnostico")
        var vueltas = 0
        while !app.descendants(matching: .any)["pantallaPlan"].exists && vueltas < 30 {
            responder(app, correcto: vueltas % 3 != 1)
            vueltas += 1
        }
        XCTAssertTrue(app.descendants(matching: .any)["pantallaPlan"].waitForExistence(timeout: 15))
        captura(app, "04_plan")
        app.buttons["botonIrAHoy"].tap()

        // Hoy.
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 15))
        captura(app, "05_hoy")
        app.scrollViews.firstMatch.swipeUp()
        captura(app, "06_hoy_abajo")
        app.scrollViews.firstMatch.swipeDown()

        // Una ronda de Camino: el primer nodo de Lengua con contenido.
        pestana(app, "Camino", destino: app.descendants(matching: .any)["pantallaCamino"])
        captura(app, "07_camino")
        let nodo = app.buttons["nodo_LEN.ORT.AGU"]
        tocarVisible(app, nodo)
        XCTAssertTrue(app.buttons["botonPracticar"].waitForExistence(timeout: 15))
        captura(app, "08_hoja_nodo")
        app.buttons["botonPracticar"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) {
            captura(app, "09_teoria_previa")
            app.buttons["botonEmpezarTrasTeoria"].tap()
        }
        XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 15))
        captura(app, "10_camino_item")
        var i = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && i < 10 {
            responder(app, correcto: i != 1 && i != 3, capturaCorregido: i == 1 ? "11_camino_fallo" : (i == 0 ? "11_camino_acierto" : nil))
            i += 1
        }
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 10))
        captura(app, "12_camino_resumen")
        terminarRonda(app)

        // Supervivencia.
        pestana(app, "Hoy", destino: app.buttons["baldosaSupervivencia"])
        tocarVisible(app, app.buttons["baldosaSupervivencia"])
        XCTAssertTrue(app.buttons["botonJugarSupervivencia"].waitForExistence(timeout: 15))
        captura(app, "13_supervivencia_inicio")
        app.buttons["botonJugarSupervivencia"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["vidas"].waitForExistence(timeout: 15))
        captura(app, "14_supervivencia_partida")
        for k in 0..<5 { responder(app, correcto: true, capturaCorregido: k == 4 ? "15_supervivencia_nivel" : nil) }
        for _ in 0..<3 { responder(app, correcto: false) }
        XCTAssertTrue(app.descendants(matching: .any)["finPartida"].waitForExistence(timeout: 15))
        captura(app, "16_supervivencia_fin")
        app.buttons["botonTerminar"].tap()

        // Rescate: los fallos reales de la ronda y de la partida.
        tocarVisible(app, app.buttons["botonRescate"])
        XCTAssertTrue(app.buttons["botonRescatarTodo"].waitForExistence(timeout: 15))
        captura(app, "17_rescate")
        app.buttons["botonRescatarTodo"].tap()
        XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 15))
        captura(app, "18_rescate_item")
        var j = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && j < 10 { responder(app, correcto: true); j += 1 }
        XCTAssertGreaterThanOrEqual(j, 1)
        captura(app, "19_rescate_resumen")
        terminarRonda(app)

        // Progreso y Ajustes.
        pestana(app, "Progreso", destino: app.descendants(matching: .any)["seccionDominio"])
        captura(app, "20_progreso")
        app.scrollViews.firstMatch.swipeUp()
        captura(app, "21_progreso_2")
        app.scrollViews.firstMatch.swipeUp()
        captura(app, "22_progreso_3")
        let ajustes = app.buttons["botonAjustes"]
        var k = 0
        while !ajustes.isHittable && k < 8 { app.scrollViews.firstMatch.swipeUp(); k += 1 }
        ajustes.tap()
        XCTAssertTrue(app.switches["ajusteSonido"].waitForExistence(timeout: 15))
        captura(app, "23_ajustes")

        // Recuperación: una ronda de comprensión con texto base (Bécquer, Machado y un texto
        // original) y una de frases con hueco, sobre el mismo almacén (sin borrarlo).
        let base = ["-almacenPruebas", "UITestRecorrido", "-semilla", "11", "-ayudasDePrueba", "-politicaRelease", "-sinAvisoRecordatorio"]
        app.terminate()
        app.launchArguments = base + ["-rondaItems", "LEN.COM.TEMA.0002,LEN.COM.INFER.0002,LEN.COM.RESU.0003"]
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60))
        app.buttons["botonEmpezarRonda"].tap()
        let panel = app.descendants(matching: .any)["panelTextoBase"]
        XCTAssertTrue(panel.waitForExistence(timeout: 15), "La ronda de comprensión muestra el texto base")
        XCTAssertTrue(app.staticTexts["autorTextoBase"].exists, "Texto literario: autor y año")
        captura(app, "24_comprension_texto")
        app.buttons["botonPlegarTexto"].tap()
        XCTAssertTrue(app.buttons["botonVerTexto"].waitForExistence(timeout: 5))
        captura(app, "25_comprension_plegado")
        app.buttons["botonVerTexto"].tap()
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        var c = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && c < 6 {
            responder(app, correcto: true, capturaCorregido: c == 1 ? "26_comprension_machado" : nil)
            c += 1
        }
        XCTAssertEqual(c, 3)
        terminarRonda(app)

        app.terminate()
        app.launchArguments = base + ["-rondaItems", "LEN.ORT.DIA.G01#3,LEN.ORT.HOM.G01#5,LEN.ORT.PQ.G01#2,LEN.ORT.HOM.G02#8"]
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60))
        app.buttons["botonEmpezarRonda"].tap()
        XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 15))
        captura(app, "27_frase_hueco")
        var f = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && f < 6 {
            responder(app, correcto: f != 1, capturaCorregido: f == 1 ? "28_frase_fallo" : (f == 2 ? "29_frase_construir" : nil))
            f += 1
        }
        XCTAssertEqual(f, 4)
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 10))
        captura(app, "30_frases_resumen")
    }
}
