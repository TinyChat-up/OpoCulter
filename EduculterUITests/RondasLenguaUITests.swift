import XCTest

/// Fase 05E: una ronda real de LEN.SIN, otra de LEN.VER y otra de LEN.LIT con el contenido de Release,
/// entrando por el Camino (nodo → Practicar). Guarda una captura de cada pregunta y de su corrección
/// para describir las rondas en el informe. Las respuestas se dan con los botones de pruebas (solo
/// Debug): bien, salvo la segunda de cada ronda, que se falla para ver la corrección.
final class RondasLenguaUITests: CasoUI {
    @MainActor
    private func captura(_ app: XCUIApplication, _ nombre: String) {
        let adjunto = XCTAttachment(screenshot: app.screenshot())
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
    }

    @MainActor
    private func ronda(_ app: XCUIApplication, competencia: String, prefijo: String) throws {
        let camino = app.tabBars.buttons["Camino"].firstMatch
        XCTAssertTrue(camino.waitForExistence(timeout: 10))
        camino.tap()
        let nodo = app.buttons["nodo_\(competencia)"]
        XCTAssertTrue(nodo.waitForExistence(timeout: 15), "No está el nodo \(competencia)")
        var vueltas = 0
        let alto = app.windows.firstMatch.frame.maxY
        while (!nodo.isHittable || nodo.frame.maxY > alto - 120) && vueltas < 30 { app.scrollViews.firstMatch.swipeUp(); vueltas += 1 }
        nodo.tap()
        XCTAssertTrue(app.buttons["botonPracticar"].waitForExistence(timeout: 15))
        captura(app, "\(prefijo)_00_nodo")
        app.buttons["botonPracticar"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 4) { app.buttons["botonEmpezarTrasTeoria"].tap() }
        XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 15))
        // Se audita con la pantalla ya quieta: durante la transición de entrada el texto está a media
        // opacidad y la auditoría de contraste da falsos positivos.
        Thread.sleep(forTimeInterval: 2)
        try auditar(app, "Ronda \(competencia)")
        var i = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && i < 12 {
            captura(app, String(format: "%@_%02d_pregunta", prefijo, i + 1))
            let boton = app.buttons[i == 1 ? "botonRellenarErrorDebug" : "botonRellenarDebug"]
            XCTAssertTrue(boton.waitForExistence(timeout: 15))
            boton.tap()
            app.buttons["botonComprobar"].tap()
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 10))
            captura(app, String(format: "%@_%02d_corregida", prefijo, i + 1))
            app.buttons["botonContinuar"].tap()
            i += 1
        }
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 10))
        captura(app, "\(prefijo)_99_resumen")
        let terminar = app.buttons["botonTerminar"]
        vueltas = 0
        while !terminar.isHittable && vueltas < 8 { app.scrollViews.firstMatch.swipeUp(); vueltas += 1 }
        terminar.tap()
    }

    @MainActor
    func testRondasDeSintaxisVerboYLiteratura() throws {
        let app = lanzar(["-politicaRelease"])
        try ronda(app, competencia: "LEN.SIN.SUJPRED", prefijo: "SIN")
        try ronda(app, competencia: "LEN.VER.ANALISIS", prefijo: "VER")
        try ronda(app, competencia: "LEN.LIT.HIST", prefijo: "LIT")
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }
}
