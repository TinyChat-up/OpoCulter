import XCTest

final class PantallaVerificacionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBotonComprobarActualizaMensaje() throws {
        let app = XCUIApplication()
        app.launch()

        let boton = app.buttons["botonComprobar"]
        XCTAssertTrue(boton.waitForExistence(timeout: 10))
        XCTAssertEqual(boton.label, "Comprobar el entorno")

        boton.tap()

        let mensaje = app.staticTexts["mensajeEstado"]
        XCTAssertTrue(mensaje.waitForExistence(timeout: 5))
        XCTAssertEqual(mensaje.label, "Comprobaciones: 1")
    }
}
