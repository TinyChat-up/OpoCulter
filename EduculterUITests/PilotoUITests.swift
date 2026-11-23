import XCTest

/// Tests de interfaz del piloto 05B: bienvenida y persistencia tras cerrar y reabrir; rondas de
/// Lengua (colocarTilde) y Matemáticas (fraccionBarras) con toques reales y sin arrastre.
final class PilotoUITests: CasoUI {
    /// Respuestas correctas de colocarTilde (lote LEN.ORT, Fase 05B): palabra → índice de la tilde.
    private let tildes: [String: Int?] = [
        "cancion": 5, "arbol": 0, "examen": nil, "musica": 1, "cafe": 3, "reloj": nil,
        "lapiz": 1, "telefono": 3, "robots": nil, "jovenes": 1, "joven": nil, "facil": 1,
    ]

    // MARK: Bienvenida, avatar y persistencia

    @MainActor
    func testBienvenidaYProgresoTrasCerrarYReabrir() throws {
        let almacen = ["-almacenPruebas", "UITestPersistencia", "-semilla", "7", "-ayudasDePrueba", "-politicaRelease"]
        var app = XCUIApplication()
        app.launchArguments = almacen + ["-borrarAlmacen"]
        app.launch()

        // Bienvenida: sin avatar no se puede empezar.
        XCTAssertTrue(app.descendants(matching: .any)["pantallaBienvenida"].waitForExistence(timeout: 60))
        try auditar(app, "Bienvenida")
        app.buttons["avatar_5"].tap()
        app.buttons["botonEmpezarBienvenida"].tap()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 10))
        try auditar(app, "Hoy v2", bordesDelScroll: true)

        // Una ronda completa con la ayuda de pruebas.
        jugarRonda(app)
        let antes = estadoVisible(app)
        XCTAssertTrue(antes.racha.hasPrefix("1 día"), "Racha tras la ronda: \(antes.racha)")
        XCTAssertTrue(antes.diagnostico.contains("LEN.ORT.AGU:p"), "Peldaño y Leitner guardados: \(antes.diagnostico)")
        XCTAssertTrue(antes.diagnostico.contains("avatar:5"))

        // Cerrar y reabrir la app sobre el mismo almacén.
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = almacen
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60), "Sin bienvenida al reabrir")
        XCTAssertFalse(app.descendants(matching: .any)["pantallaBienvenida"].exists)
        let despues = estadoVisible(app)
        XCTAssertEqual(despues.racha, antes.racha)
        XCTAssertEqual(despues.nivel, antes.nivel)
        XCTAssertEqual(despues.misiones, antes.misiones)
        XCTAssertEqual(despues.avatar, antes.avatar)
        XCTAssertEqual(despues.diagnostico, antes.diagnostico, "Peldaño, Leitner, Rescate, XP y avatar")

        // Perfil: cambiar el avatar.
        app.buttons["botonPerfil"].tap()
        XCTAssertTrue(app.buttons["avatar_9"].waitForExistence(timeout: 5))
        try auditar(app, "Perfil")
        app.buttons["avatar_9"].tap()
        app.buttons["botonGuardarPerfil"].tap()
        XCTAssertTrue(app.buttons["botonPerfil"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["botonPerfil"].value as? String, "Hexágono coral con gafas")
    }

    private struct EstadoVisible: Equatable {
        var racha: String
        var nivel: String
        var misiones: [String]
        var avatar: String
        var diagnostico: String
    }

    @MainActor
    private func estadoVisible(_ app: XCUIApplication) -> EstadoVisible {
        XCTAssertTrue(app.descendants(matching: .any)["diagnosticoProgreso"].waitForExistence(timeout: 10))
        let misiones = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'mision_'"))
            .allElementsBoundByIndex.map { "\($0.label): \($0.value as? String ?? "")" }
        return EstadoVisible(
            racha: app.descendants(matching: .any)["chipRacha"].firstMatch.value as? String ?? "",
            nivel: app.descendants(matching: .any)["tarjetaNivel"].firstMatch.value as? String ?? "",
            misiones: misiones,
            avatar: app.buttons["botonPerfil"].value as? String ?? "",
            diagnostico: app.descendants(matching: .any)["diagnosticoProgreso"].firstMatch.label)
    }

    /// Juega la ronda que abre "Empezar ronda" con el botón de pruebas y vuelve a Hoy.
    @MainActor
    private func jugarRonda(_ app: XCUIApplication) {
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }
        var vueltas = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 10 {
            XCTAssertTrue(app.buttons["botonRellenarDebug"].waitForExistence(timeout: 10))
            app.buttons["botonRellenarDebug"].tap()
            app.buttons["botonComprobar"].tap()
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
            app.buttons["botonContinuar"].tap()
            vueltas += 1
        }
        let terminar = app.buttons["botonTerminar"]
        XCTAssertTrue(terminar.waitForExistence(timeout: 5))
        while !terminar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        terminar.tap()
    }

    // MARK: Rondas del piloto con toques reales

    @MainActor
    func testRondaDeMatematicasConFraccionBarras() throws {
        let app = lanzar(["-politicaRelease"])
        let mates = app.buttons["Matemáticas"].firstMatch
        XCTAssertTrue(mates.waitForExistence(timeout: 5))
        mates.tap()
        XCTAssertTrue(app.staticTexts["Representar fracciones"].waitForExistence(timeout: 5))
        try auditar(app, "Hoy · Matemáticas", bordesDelScroll: true)
        let respondidas = try jugarConToquesReales(app, mecanica: "fraccionBarras")
        XCTAssertGreaterThanOrEqual(respondidas, 2, "La ronda de Matemáticas debe incluir fraccionBarras")
        // La misión de Matemáticas (si es la de área de hoy) queda cumplida.
        let mision = app.descendants(matching: .any)["mision_rondaMatematicas"]
        if mision.waitForExistence(timeout: 5) { XCTAssertEqual(mision.value as? String, "completada") }
    }

    @MainActor
    func testRondaDeLenguaConColocarTilde() throws {
        let app = lanzar(["-politicaRelease"], base: ["-enMemoria", "-semilla", "10", "-ayudasDePrueba", "-avatar", "0"])
        XCTAssertTrue(app.staticTexts["Agudas, llanas y esdrújulas"].waitForExistence(timeout: 5))
        let respondidas = try jugarConToquesReales(app, mecanica: "colocarTilde")
        XCTAssertGreaterThanOrEqual(respondidas, 1, "La ronda de Lengua debe incluir colocarTilde")
    }

    /// Juega la ronda: la mecánica indicada con toques reales (y auditoría antes y después de
    /// comprobar); el resto, con el botón de pruebas. Devuelve cuántos ítems de esa mecánica hubo.
    @MainActor
    private func jugarConToquesReales(_ app: XCUIApplication, mecanica: String) throws -> Int {
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) {
            try auditar(app, "Teoría previa")
            app.buttons["botonEmpezarTrasTeoria"].tap()
        }
        var reales = 0
        var vueltas = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && vueltas < 10 {
            XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 10))
            if app.descendants(matching: .any)["mecanica_\(mecanica)"].exists {
                try auditar(app, "\(mecanica) antes")
                if mecanica == "colocarTilde" { responderTilde(app) } else { try responderBarra(app) }
                app.buttons["botonComprobar"].tap()
                XCTAssertTrue(app.staticTexts["¡Correcto!"].waitForExistence(timeout: 5), "\(mecanica) con toques reales debería ser correcta")
                try auditar(app, "\(mecanica) corregido")
                reales += 1
            } else {
                app.buttons["botonRellenarDebug"].tap()
                app.buttons["botonComprobar"].tap()
            }
            XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
            app.buttons["botonContinuar"].tap()
            vueltas += 1
        }
        XCTAssertTrue(app.descendants(matching: .any)["resumenRonda"].waitForExistence(timeout: 5))
        try auditar(app, "Resumen")
        let terminar = app.buttons["botonTerminar"]
        while !terminar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        terminar.tap()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 5))
        return reales
    }

    @MainActor
    private func responderTilde(_ app: XCUIApplication) {
        let etiqueta = app.descendants(matching: .any)["palabraTilde"].firstMatch.label
        let palabra = etiqueta.replacingOccurrences(of: "Palabra ", with: "")
        guard let indice = tildes[palabra] else { return XCTFail("Palabra desconocida: \(palabra)") }
        tocar(app, [indice.map { "letra_\($0)" } ?? "botonSinTilde"])
    }

    /// Lee la fracción del enunciado, ajusta las partes si hay que dividir y colorea las celdas.
    @MainActor
    private func responderBarra(_ app: XCUIApplication) throws {
        let enunciado = app.staticTexts["enunciado"].label
        var (n, d) = (1, 2) // «la mitad»
        if let r = enunciado.range(of: #"\d+/\d+"#, options: .regularExpression) {
            let partes = enunciado[r].split(separator: "/").compactMap { Int($0) }
            (n, d) = (partes[0], partes[1])
        }
        let control = app.descendants(matching: .any)["controlPartes"]
        if control.exists {
            // «Representa 1/3 dividiendo la barra en 6 o en 9 partes»: la primera partición nombrada.
            var objetivo = d
            if let r = enunciado.range(of: #"en (\d+) o en"#, options: .regularExpression) {
                objetivo = Int(enunciado[r].filter(\.isNumber)) ?? d
            }
            var actual = Int(control.value as? String ?? "") ?? 2
            while actual != objetivo {
                tocar(app, [actual < objetivo ? "botonMasPartes" : "botonMenosPartes"])
                actual += actual < objetivo ? 1 : -1
            }
            XCTAssertEqual(control.value as? String, "\(objetivo)")
            n = n * objetivo / d
            d = objetivo
        }
        let celdas = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'celda_'")).count
        let colorear = celdas * n / d
        tocar(app, (0..<colorear).map { "celda_\($0)" })
        XCTAssertEqual(app.descendants(matching: .any)["lecturaFraccion"].value as? String, "\(colorear) de \(celdas)")
    }
}
