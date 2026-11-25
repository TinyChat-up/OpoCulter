import XCTest

/// Recuperación (D-085): ítems de comprensión con texto base. El panel se ve desplegado sobre el
/// enunciado, se pliega en la pestaña «Ver texto», se vuelve a desplegar y sigue a la vista al
/// comprobar. Auditoría de accesibilidad con el panel desplegado, plegado y tras comprobar.
final class ComprensionUITests: CasoUI {
    @MainActor
    func testTextoBasePlegadoYDesplegado() throws {
        let app = lanzar(["-politicaRelease"])
        app.tabBars.buttons["Camino"].firstMatch.tap()
        let nodo = app.buttons["nodo_LEN.COM.TEMA"]
        XCTAssertTrue(nodo.waitForExistence(timeout: 15))
        var vueltas = 0
        while !nodo.isHittable && vueltas < 12 { app.scrollViews.firstMatch.swipeUp(); vueltas += 1 }
        nodo.tap()
        XCTAssertTrue(app.buttons["botonPracticar"].waitForExistence(timeout: 10))
        app.buttons["botonPracticar"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }

        // Desplegado: título, cuerpo del texto y el ítem debajo.
        let panel = app.descendants(matching: .any)["panelTextoBase"]
        XCTAssertTrue(panel.waitForExistence(timeout: 15), "El ítem de comprensión muestra su texto base")
        XCTAssertFalse(app.staticTexts["tituloTextoBase"].label.isEmpty)
        XCTAssertTrue(app.staticTexts["cuerpoTextoBase"].exists)
        XCTAssertTrue(app.staticTexts["enunciado"].exists && app.buttons["botonComprobar"].exists, "El ítem se responde debajo")
        XCTAssertLessThan(panel.frame.maxY, app.staticTexts["enunciado"].frame.minY + 1, "El texto va encima del enunciado")
        try auditar(app, "Texto base desplegado")

        // Plegado: queda la pestaña «Ver texto».
        app.buttons["botonPlegarTexto"].tap()
        XCTAssertTrue(app.buttons["botonVerTexto"].waitForExistence(timeout: 5))
        XCTAssertFalse(panel.exists)
        try auditar(app, "Texto base plegado")

        // Se vuelve a desplegar y sigue a la vista al comprobar.
        app.buttons["botonVerTexto"].tap()
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        app.buttons["botonRellenarDebug"].tap()
        app.buttons["botonComprobar"].tap()
        XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
        XCTAssertTrue(panel.exists, "El texto sigue a la vista en la corrección")
        try auditar(app, "Texto base tras comprobar")
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }
}
