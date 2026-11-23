import XCTest

/// Rendimiento del piloto 05B en el simulador: arranque en frío y fluidez (tirones de fotogramas)
/// al manipular `fraccionBarras` y `colocarTilde`. Los valores se leen del resultado del test
/// (`xcresulttool`) y se documentan en TESTING.md §9.
final class RendimientoUITests: XCTestCase {
    private var opciones: XCTMeasureOptions {
        let o = XCTMeasureOptions()
        o.iterationCount = 5
        return o
    }

    @MainActor
    func testArranqueEnFrio() throws {
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)], options: opciones) {
            let app = XCUIApplication()
            app.launchArguments = ["-enMemoria", "-avatar", "0", "-politicaRelease"]
            app.launch()
        }
    }

    @MainActor
    @available(iOS 26.0, *)
    func testFluidezFraccionBarras() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-avatar", "0", "-captura", "item:MAT.NUM.FRAEQ.0003:antes"]
        app.launch()
        XCTAssertTrue(app.buttons["celda_0"].waitForExistence(timeout: 30))
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app), XCTClockMetric()], options: opciones) {
            // Colorear y descolorear 12 celdas (cada toque anima la celda).
            for i in 0..<12 { app.buttons["celda_\(i)"].tap() }
            for i in 0..<12 { app.buttons["celda_\(i)"].tap() }
        }
    }

    @MainActor
    @available(iOS 26.0, *)
    func testFluidezDividirBarra() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-avatar", "0", "-captura", "item:MAT.NUM.FRAREP.0003:antes"]
        app.launch()
        XCTAssertTrue(app.buttons["botonMasPartes"].waitForExistence(timeout: 30))
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app), XCTClockMetric()], options: opciones) {
            // La barra se redibuja en vivo de 2 a 12 partes y vuelve.
            for _ in 0..<10 { app.buttons["botonMasPartes"].tap() }
            for _ in 0..<10 { app.buttons["botonMenosPartes"].tap() }
        }
    }

    @MainActor
    @available(iOS 26.0, *)
    func testFluidezColocarTilde() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-avatar", "0", "-captura", "item:LEN.ORT.AGU.0017:antes"]
        app.launch()
        XCTAssertTrue(app.buttons["letra_3"].waitForExistence(timeout: 30))
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app), XCTClockMetric()], options: opciones) {
            // «telefono»: la tilde cae en cada vocal y se quita.
            for i in [1, 3, 5, 7, 3, 3] { app.buttons["letra_\(i)"].tap() }
            app.buttons["botonSinTilde"].tap()
        }
    }
}

/// Interacción sobre una app ya lanzada (sin relanzarla), para medir con Instruments
/// («Animation Hitches» adjunto al proceso). Solo se ejecuta con `TEST_RUNNER_INSTRUMENTS=1`.
final class InteraccionInstrumentsUITests: XCTestCase {
    @MainActor
    func testInteraccionParaInstruments() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["INSTRUMENTS"] == "1", "Solo para medir con xctrace")
        let app = XCUIApplication()
        app.activate()
        if app.buttons["botonMasPartes"].waitForExistence(timeout: 10) {
            for _ in 0..<3 {
                for _ in 0..<10 { app.buttons["botonMasPartes"].tap() }
                for _ in 0..<10 { app.buttons["botonMenosPartes"].tap() }
            }
        } else if app.buttons["celda_0"].waitForExistence(timeout: 5) {
            for _ in 0..<3 {
                for i in 0..<12 { app.buttons["celda_\(i)"].tap() }
                for i in 0..<12 { app.buttons["celda_\(i)"].tap() }
            }
        } else {
            XCTAssertTrue(app.buttons["letra_3"].waitForExistence(timeout: 5))
            for _ in 0..<4 {
                for i in [1, 3, 5, 7, 3, 3] { app.buttons["letra_\(i)"].tap() }
            }
        }
    }
}
