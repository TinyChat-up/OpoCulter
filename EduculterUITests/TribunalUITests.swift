import XCTest

/// Fase 05J: Tribunal v2. Desde la pestaña Tribunal, la muestra SIM.DEMO.01 ofrece «Imprimir PDF»
/// (vista previa con «Empezar en papel») y «Hacer en la app», con el mapa de preguntas.
final class TribunalUITests: CasoUI {
    @MainActor
    func testMuestraEnLaAppConMapaYOpcionDePapel() throws {
        let app = lanzar()
        app.tabBars.buttons["Tribunal"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["tarjetaPrincipal"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["La caja de las semillas"].exists, "La tarjeta principal es la muestra")

        // Papel / PDF: la vista previa no empieza nada; se cierra sin intento.
        let pdf = app.buttons["botonImprimirPDF"]
        XCTAssertTrue(pdf.exists && app.buttons["botonHacerApp"].exists)
        pdf.tap()
        XCTAssertTrue(app.buttons["botonEmpezarPapel"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["botonCorregirPapel"].exists)
        app.buttons["Cerrar"].firstMatch.tap()
        XCTAssertTrue(app.buttons["botonHacerApp"].waitForExistence(timeout: 10), "Sin intento tras la vista previa")

        // En la app: la sala con el mapa de preguntas de la muestra.
        app.buttons["botonHacerApp"].tap()
        XCTAssertTrue(app.buttons["botonMapa"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["cuentaAtras"].exists)
        app.buttons["botonMapa"].tap()
        for id in ["L01", "L02", "M01", "M02"] {
            XCTAssertTrue(app.buttons["mapa_\(id)"].waitForExistence(timeout: 5), "Mapa: \(id)")
        }
        XCTAssertFalse(app.buttons["mapa_L03"].exists, "La muestra tiene 4 preguntas")
    }

    /// Fase 06: un usuario gratis toca un simulacro de pago → hoja de bloqueo → «Ver Premium» → la
    /// pantalla Premium con Restaurar compras y los enlaces a Términos de uso y Política de privacidad.
    @MainActor
    func testGratisSimulacroAbreHojaYPantallaPremium() throws {
        let app = lanzar(["-gratis"])
        app.tabBars.buttons["Tribunal"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["tarjetaPrincipal"].waitForExistence(timeout: 15))
        let simulacro = app.buttons["simulacro_SIM.OR.01"]
        XCTAssertTrue(simulacro.waitForExistence(timeout: 10))
        var vueltas = 0
        while !simulacro.isHittable && vueltas < 6 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); vueltas += 1 }
        XCTAssertTrue(simulacro.label.contains("Premium"), "Con candado: \(simulacro.label)")
        simulacro.tap()

        XCTAssertTrue(app.descendants(matching: .any)["hojaBloqueoPremium"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["botonAhoraNo"].exists)
        app.buttons["botonVerPremium"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["pantallaPremium"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["botonRestaurarCompras"].waitForExistence(timeout: 10))
        // Los `Link` de SwiftUI se exponen como botones o como enlaces según la versión del sistema.
        for id in ["enlaceTerminos", "enlacePrivacidad"] {
            XCTAssertTrue(app.descendants(matching: .any)[id].exists, "Falta \(id)")
        }
    }
}
