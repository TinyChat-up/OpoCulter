import XCTest

/// Pasada corta de accesibilidad (D-141, anexo a la 05K): `performAccessibilityAudit()` en Inicio,
/// Camino, la sesión diaria (su primera ronda), una ronda suelta, Tribunal y las pantallas nuevas de
/// la 05K. La auditoría completa es de la fase 07.
final class AccesibilidadUITests: CasoUI {
    override func setUpWithError() throws {
        // Se recogen todos los problemas de cada pantalla, no solo el primero.
        continueAfterFailure = true
    }

    /// Lanza una escena fija (`-captura`) y espera a que aparezca el elemento.
    @MainActor
    func escena(_ escena: String, espera id: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-semilla", "42", "-avatar", "0", "-sinAvisoRecordatorio", "-captura", escena]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)[id].waitForExistence(timeout: 60), "\(escena): falta \(id)")
        return app
    }

    /// Borde superior de lo que tapa el contenido por abajo: la barra de pestañas flotante o la barra
    /// de acciones de la ronda (Pista, Comprobar).
    @MainActor
    func bordeInferior(_ app: XCUIApplication) -> CGFloat {
        var y = app.frame.maxY
        if app.tabBars.firstMatch.exists { y = min(y, app.tabBars.firstMatch.frame.minY) }
        for id in ["botonComprobar", "botonContinuar"] where app.buttons[id].exists { y = min(y, app.buttons[id].frame.minY - 16) }
        return y
    }

    /// Audita la pantalla arriba del todo y, si se desplaza, otra vez abajo: lo que en una pasada queda
    /// bajo la barra inferior (material translúcido, D-141) se audita en la otra.
    @MainActor
    func auditar(_ app: XCUIApplication, _ pantalla: String) throws {
        try auditarVista(app, pantalla)
        let scroll = app.scrollViews.firstMatch
        if scroll.exists {
            scroll.swipeUp(velocity: .slow)
            // Que termine la inercia del desplazamiento antes de auditar (si no, mide texto en movimiento).
            RunLoop.current.run(until: Date().addingTimeInterval(2.5))
            try auditarVista(app, pantalla + " (desplazada)", desplazada: true)
        }
    }

    @MainActor
    func auditarVista(_ app: XCUIApplication, _ pantalla: String, desplazada: Bool = false) throws {
        let borde = bordeInferior(app)
        // Desplazada, lo de arriba queda bajo la barra de estado y su difuminado (unos 110 pt): se
        // auditó entero en la primera pasada.
        let techo: CGFloat = desplazada ? 110 : 0
        try app.performAccessibilityAudit { problema in
            // Los avisos sobre elementos del sistema sin identificador propio (barra de estado) no son de la app.
            if let e = problema.element, e.elementType == .statusBar || e.identifier.hasPrefix("StatusBar") { return true }
            // Contraste de un texto tapado a medias por la barra inferior: se mide contra el material, no
            // contra el fondo; ese texto se audita entero en la otra pasada.
            if problema.auditType == .contrast, let e = problema.element, e.frame.maxY > borde || e.frame.minY < techo { return true }
            // Desplazada, el auditor no identifica algunos nodos de arriba (los 7 días de la semana de Inicio).
            if problema.auditType == .contrast, desplazada, problema.element == nil { return true }
            let e = problema.element
            XCTContext.runActivity(named: "PROBLEMA \(pantalla): \(problema.compactDescription) · tipo \(e?.elementType.rawValue ?? 0) · id «\(e?.identifier ?? "")» · etiqueta «\(e?.label ?? "")» · \(e?.frame ?? .zero)") { _ in }
            return false
        }
    }

    @MainActor
    func testInicioCaminoYTribunal() throws {
        let app = lanzar()
        try auditar(app, "Inicio")
        app.tabBars.buttons["Camino"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["pantallaCamino"].waitForExistence(timeout: 15))
        try auditar(app, "Camino")
        app.tabBars.buttons["Tribunal"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["tarjetaPrincipal"].waitForExistence(timeout: 15))
        try auditar(app, "Tribunal")
    }

    @MainActor
    func testSesionDiaria() throws {
        let app = lanzar()
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }
        XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 15))
        try auditar(app, "Sesión diaria")
    }

    @MainActor
    func testRonda() throws {
        try auditar(escena("item:LEN.ORT.AGU.0010:antes", espera: "mecanica_colocarTilde"), "Ronda")
    }

    @MainActor
    func testPantallasFase05K() throws {
        for (escena, id) in [("item:MAT.GEO.VOL.G01#3:relleno", "figuraVolumen"), ("item:MAT.GEO.VOL.G04#2:antes", "figuraVolumen"),
                             ("item:MAT.PRO.SUCESOS.G01@d4#1:antes", "mecanica_marcarTexto"),
                             ("item:LEN.CLA.VAR.G01#1:antes", "mecanica_clasificar"),
                             ("item:LEN.LEX.DICC.G01@d5#2:antes", "mecanica_ordenar")] {
            try auditar(self.escena(escena, espera: id), escena)
        }
    }

    /// Fase 06: la hoja de bloqueo del Tribunal y la pantalla Premium (usuario gratis).
    @MainActor
    func testHojaBloqueoYPantallaPremium() throws {
        let app = lanzar(["-gratis"])
        app.tabBars.buttons["Tribunal"].firstMatch.tap()
        let simulacro = app.buttons["simulacro_SIM.OR.01"]
        XCTAssertTrue(simulacro.waitForExistence(timeout: 15))
        var vueltas = 0
        while !simulacro.isHittable && vueltas < 6 { app.scrollViews.firstMatch.swipeUp(velocity: .slow); vueltas += 1 }
        simulacro.tap()
        XCTAssertTrue(app.descendants(matching: .any)["hojaBloqueoPremium"].waitForExistence(timeout: 10))
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        try auditarVista(app, "Hoja de bloqueo")
        app.buttons["botonVerPremium"].tap()
        XCTAssertTrue(app.buttons["botonRestaurarCompras"].waitForExistence(timeout: 15))
        // Que termine de cargar la tienda (o su aviso) antes de auditar.
        RunLoop.current.run(until: Date().addingTimeInterval(4))
        try auditarVista(app, "Pantalla Premium")
    }
}
