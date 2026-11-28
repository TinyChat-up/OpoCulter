import StoreKitTest
import XCTest

/// Capturas de la fase 06 (no es un test de la suite: necesita red y los servidores de prueba de
/// Google). Solo se ejecuta con `TEST_RUNNER_CAPTURAS=1`. Guarda las capturas como adjuntos del
/// resultado: «premium», «hoja-bloqueo», «ump-eee», «intersticial» y «privacidad-anuncios».
final class CapturasFase06UITests: CasoUI {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["CAPTURAS"] == "1", "Solo para generar capturas (TEST_RUNNER_CAPTURAS=1)")
        continueAfterFailure = true
    }

    @MainActor
    func captura(_ nombre: String) {
        let adjunto = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
    }

    @MainActor
    func esperar(_ segundos: TimeInterval) { RunLoop.current.run(until: Date().addingTimeInterval(segundos)) }

    /// Primer botón cuya etiqueta contiene alguno de los textos (formularios web de UMP y alertas del sistema).
    @MainActor
    func boton(_ raiz: XCUIElement, _ textos: [String]) -> XCUIElement? {
        for t in textos {
            let b = raiz.descendants(matching: .button).matching(NSPredicate(format: "label CONTAINS[c] %@", t)).firstMatch
            if b.exists { return b }
        }
        return nil
    }

    /// Pantalla Premium con los precios del archivo `Educulter.storekit` y la hoja de bloqueo.
    @MainActor
    func testPremiumYHoja() throws {
        let sesion = try SKTestSession(contentsOf: URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Educulter.storekit"))
        sesion.resetToDefaultState()
        sesion.clearTransactions()
        sesion.disableDialogs = true
        let app = lanzar(["-gratis"])
        app.tabBars.buttons["Tribunal"].firstMatch.tap()
        let simulacro = app.buttons["simulacro_SIM.OR.01"]
        XCTAssertTrue(simulacro.waitForExistence(timeout: 15))
        var vueltas = 0
        while !simulacro.isHittable && vueltas < 6 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); vueltas += 1 }
        simulacro.tap()
        XCTAssertTrue(app.buttons["botonVerPremium"].waitForExistence(timeout: 10))
        esperar(1.5)
        captura("hoja-bloqueo")
        app.buttons["botonVerPremium"].tap()
        XCTAssertTrue(app.buttons["botonRestaurarCompras"].waitForExistence(timeout: 15))
        esperar(6)
        captura("premium")
    }

    /// Día 3, gratis: formulario de UMP (EEE de depuración) en Hoy, ATT, una ronda y el intersticial
    /// de prueba al terminarla; después, Ajustes > Privacidad y anuncios.
    @MainActor
    func testConsentimientoIntersticialYPrivacidad() throws {
        let app = lanzar(["-gratis", "-diaUso", "3", "-rondasAnuncio", "1", "-rondaItems", "LEN.ORT.AGU.0010"])
        // UMP: el formulario es una vista web.
        // Se espera a que el formulario esté cargado y visible (su botón de consentimiento).
        var aceptar: XCUIElement?
        for _ in 0..<60 where aceptar == nil {
            aceptar = boton(app.webViews.firstMatch, ["Consentir", "Consent", "Aceptar", "Accept"]).flatMap { $0.isHittable ? $0 : nil }
            if aceptar == nil { esperar(1) }
        }
        esperar(1.5)
        captura("ump-eee")
        if let aceptar { aceptar.tap() } else { XCTFail("No ha aparecido el formulario de UMP") }
        // ATT: alerta del sistema.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alerta = springboard.alerts.firstMatch
        if alerta.waitForExistence(timeout: 15), let no = boton(alerta, ["no rastree", "Not to Track", "Permitir", "Allow"]) { no.tap() }
        // SDK y precarga del intersticial de prueba.
        esperar(12)
        app.buttons["botonEmpezarRonda"].tap()
        jugarHastaElFinal(app)
        XCTAssertTrue(app.buttons["botonTerminar"].waitForExistence(timeout: 15))
        app.buttons["botonTerminar"].tap()
        esperar(6)
        captura("intersticial")
        // Cerrar el anuncio (el botón de cierre del SDK) y abrir Ajustes > Privacidad y anuncios.
        if let cerrar = boton(app, ["Close", "Cerrar"]) { cerrar.tap() }
        esperar(3)
        app.tabBars.buttons["Progreso"].firstMatch.tap()
        let ajustes = app.buttons["botonAjustes"]
        vueltasHasta(app, ajustes)
        ajustes.tap()
        let privacidad = app.buttons["botonPrivacidadAnuncios"]
        vueltasHasta(app, privacidad)
        privacidad.tap()
        XCTAssertTrue(app.descendants(matching: .any)["pantallaPrivacidadAnuncios"].waitForExistence(timeout: 10))
        esperar(1.5)
        captura("privacidad-anuncios")
    }

    @MainActor
    func vueltasHasta(_ app: XCUIApplication, _ e: XCUIElement) {
        XCTAssertTrue(e.waitForExistence(timeout: 15))
        var n = 0
        while !e.isHittable && n < 10 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); n += 1 }
    }
}
