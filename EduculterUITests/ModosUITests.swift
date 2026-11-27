import XCTest

/// Tests de interfaz de la Fase 05D: bienvenida → diagnóstico → plan, Supervivencia hasta perder
/// las 3 vidas, Camino → nodo → prueba de nivel, Rescate, Progreso y Ajustes, y persistencia de
/// récords y ajustes tras cerrar y reabrir. Auditoría de accesibilidad en todas las pantallas nuevas.
final class ModosUITests: CasoUI {
    /// Responde el ítem en curso con el botón de pruebas (correcto o con error) y continúa.
    @MainActor
    private func responder(_ app: XCUIApplication, correcto: Bool) {
        let id = correcto ? "botonRellenarDebug" : "botonRellenarErrorDebug"
        let boton = app.buttons[id]
        XCTAssertTrue(boton.waitForExistence(timeout: 10))
        boton.tap()
        comprobar(app, rellenar: id)
        XCTAssertTrue(app.buttons["botonContinuar"].waitForExistence(timeout: 5))
        app.buttons["botonContinuar"].tap()
    }

    /// Toca un elemento después de desplazarlo fuera de la zona de la barra de pestañas flotante.
    @MainActor
    private func tocarVisible(_ app: XCUIApplication, _ e: XCUIElement) {
        XCTAssertTrue(e.waitForExistence(timeout: 10))
        let alto = app.windows.firstMatch.frame.maxY
        var vueltas = 0
        while (!e.isHittable || e.frame.maxY > alto - 120) && vueltas < 6 {
            app.scrollViews.firstMatch.swipeUp()
            vueltas += 1
        }
        e.tap()
    }

    @MainActor
    private func pestana(_ app: XCUIApplication, _ nombre: String) {
        app.tabBars.buttons[nombre].firstMatch.tap()
    }

    // MARK: Bienvenida → diagnóstico → plan

    @MainActor
    func testBienvenidaDiagnosticoYPlan() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-enMemoria", "-semilla", "5", "-ayudasDePrueba", "-politicaRelease", "-sinAvisoRecordatorio"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["pantallaBienvenida"].waitForExistence(timeout: 60))
        app.buttons["avatar_2"].tap()
        app.buttons["botonEmpezarBienvenida"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["ofertaDiagnostico"].waitForExistence(timeout: 10))
        try auditar(app, "Oferta de diagnóstico")
        app.buttons["botonEmpezarDiagnostico"].tap()
        XCTAssertTrue(app.staticTexts["progresoDiagnostico"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["progresoDiagnostico"].label.hasPrefix("1 de "), "Progreso «x de N»")
        try auditar(app, "Diagnóstico")
        var vueltas = 0
        while !app.descendants(matching: .any)["pantallaPlan"].exists && vueltas < 30 {
            responder(app, correcto: vueltas % 2 == 0)
            vueltas += 1
        }
        XCTAssertTrue(app.descendants(matching: .any)["pantallaPlan"].waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(vueltas, 2)
        XCTAssertTrue(app.descendants(matching: .any)["planRecomendadas"].exists, "«Empezamos por…»")
        XCTAssertTrue(app.descendants(matching: .any)["planSinDatos"].exists, "Aviso honesto de bloques sin datos")
        try auditar(app, "Plan")
        app.buttons["botonIrAHoy"].tap()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["pantallaBienvenida"].exists)
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }

    // MARK: Supervivencia

    @MainActor
    func testSupervivenciaHastaPerderLasTresVidas() throws {
        let app = lanzar(["-politicaRelease"], base: ["-enMemoria", "-semilla", "9", "-ayudasDePrueba", "-avatar", "0"])
        tocarVisible(app, app.buttons["baldosaSupervivencia"])
        XCTAssertTrue(app.buttons["botonJugarSupervivencia"].waitForExistence(timeout: 10))
        try auditar(app, "Inicio de Supervivencia")
        app.buttons["botonJugarSupervivencia"].tap()
        let vidas = app.descendants(matching: .any)["vidas"]
        XCTAssertTrue(vidas.waitForExistence(timeout: 10))
        XCTAssertEqual(vidas.value as? String, "3 de 3")
        try auditar(app, "Partida")
        // 4 aciertos: sube al nivel 2.
        for _ in 0..<4 { responder(app, correcto: true) }
        XCTAssertTrue(app.staticTexts["nivelSupervivencia"].label.hasPrefix("Nivel 2"))
        let puntos = Int(app.staticTexts["puntosSupervivencia"].value as? String ?? "") ?? 0
        XCTAssertEqual(puntos, 10 + 13 + 15 + 18, "10 × nivel con el combo")
        for k in 0..<3 {
            responder(app, correcto: false)
            if k < 2 { XCTAssertEqual(vidas.value as? String, "\(2 - k) de 3") }
        }
        XCTAssertTrue(app.descendants(matching: .any)["finPartida"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["datosFinPartida"].exists)
        try auditar(app, "Fin de partida")
        app.buttons["botonTerminar"].tap()
        XCTAssertTrue(app.buttons["baldosaSupervivencia"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["baldosaSupervivencia"].label.contains("Récord: 56 puntos"), app.buttons["baldosaSupervivencia"].label)
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }

    // MARK: Camino

    @MainActor
    func testCaminoNodoYPruebaDeNivel() throws {
        let app = lanzar(["-politicaRelease"])
        pestana(app, "Camino")
        let nodo = app.buttons["nodo_LEN.ORT.AGU"]
        XCTAssertTrue(nodo.waitForExistence(timeout: 10))
        // Desde la 05E, LEN.SIN.SUJPRED tiene contenido; LEN.SIN.SINT sigue sin él.
        XCTAssertTrue(app.buttons["nodo_LEN.SIN.SINT"].exists == false || app.buttons["nodo_LEN.SIN.SINT"].isEnabled == false,
                      "Sin contenido aprobado: no se puede pulsar")
        try auditar(app, "Camino", bordesDelScroll: true)
        while !nodo.isHittable { app.scrollViews.firstMatch.swipeUp() }
        nodo.tap()
        XCTAssertTrue(app.buttons["botonPruebaNivel"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["estadoNodo"].exists)
        try auditar(app, "Hoja del nodo")
        app.buttons["botonPruebaNivel"].tap()
        XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 15))
        for i in 0..<5 { responder(app, correcto: i < 4) }
        let resultado = app.staticTexts["resultadoModo"]
        XCTAssertTrue(resultado.waitForExistence(timeout: 10))
        XCTAssertTrue(resultado.label.hasPrefix("Prueba de nivel superada"))
        try auditar(app, "Resultado de la prueba")
        let terminar = app.buttons["botonTerminar"]
        while !terminar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        terminar.tap()
        XCTAssertTrue(nodo.waitForExistence(timeout: 10))
        XCTAssertTrue((nodo.value as? String ?? "").contains("Resolver · peldaño 3"), nodo.value as? String ?? "")
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }

    // MARK: Rescate

    @MainActor
    func testRescatePorCompetencia() throws {
        let app = lanzar(["-politicaRelease"], base: ["-enMemoria", "-semilla", "10", "-ayudasDePrueba", "-avatar", "0"])
        // Sin errores: estado vacío.
        tocarVisible(app, app.buttons["botonRescate"])
        XCTAssertTrue(app.descendants(matching: .any)["rescateVacio"].waitForExistence(timeout: 10))
        try auditar(app, "Rescate vacío")
        app.buttons["botonCerrarRescate"].tap()
        // Una ronda con todos los ítems fallados (un acierto posterior de la misma competencia y
        // peldaño rescataría los fallos anteriores dentro de la misma ronda).
        elegirDuracion(app, 5)
        app.scrollViews.firstMatch.swipeDown()
        app.buttons["botonEmpezarRonda"].tap()
        if app.buttons["botonEmpezarTrasTeoria"].waitForExistence(timeout: 5) { app.buttons["botonEmpezarTrasTeoria"].tap() }
        var i = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && i < 12 { responder(app, correcto: false); i += 1 }
        let terminar = app.buttons["botonTerminar"]
        XCTAssertTrue(terminar.waitForExistence(timeout: 5))
        while !terminar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        terminar.tap()
        XCTAssertTrue(app.buttons["botonRescate"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["botonRescate"].label.contains("\(i) ítems"), app.buttons["botonRescate"].label)
        tocarVisible(app, app.buttons["botonRescate"])
        XCTAssertTrue(app.buttons["botonRescatarTodo"].waitForExistence(timeout: 10))
        try auditar(app, "Rescate")
        let ver = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'verItem_'")).firstMatch
        ver.tap()
        XCTAssertTrue(app.descendants(matching: .any)["itemRepaso"].waitForExistence(timeout: 10))
        try auditar(app, "Ítem de nuevo")
        app.buttons["botonCerrarItem"].tap()
        let rescatar = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'rescatar_'")).firstMatch
        XCTAssertTrue(rescatar.waitForExistence(timeout: 5))
        while !rescatar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        rescatar.tap()
        XCTAssertTrue(app.buttons["botonComprobar"].waitForExistence(timeout: 15))
        var j = 0
        while !app.descendants(matching: .any)["resumenRonda"].exists && j < 10 { responder(app, correcto: true); j += 1 }
        XCTAssertGreaterThanOrEqual(j, 1)
        while !terminar.isHittable { app.scrollViews.firstMatch.swipeUp() }
        terminar.tap()
        XCTAssertTrue(app.buttons["botonRescate"].waitForExistence(timeout: 10))
        let etiqueta = app.buttons["botonRescate"].label
        XCTAssertFalse(etiqueta.contains("\(i) ítems"), "El contador baja de verdad: \(etiqueta)")
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }

    // MARK: Progreso, ajustes, recordatorio y persistencia

    @MainActor
    func testRecordYAjustesTrasCerrarYReabrir() throws {
        let almacen = ["-almacenPruebas", "UITestModos", "-semilla", "9", "-ayudasDePrueba", "-politicaRelease", "-avatar", "0"]
        var app = XCUIApplication()
        app.launchArguments = almacen + ["-borrarAlmacen"]
        app.launch()
        XCTAssertTrue(app.buttons["botonEmpezarRonda"].waitForExistence(timeout: 60))
        // Partida: 4 aciertos y 3 fallos = 56 puntos.
        tocarVisible(app, app.buttons["baldosaSupervivencia"])
        XCTAssertTrue(app.buttons["botonJugarSupervivencia"].waitForExistence(timeout: 10))
        app.buttons["botonJugarSupervivencia"].tap()
        for _ in 0..<4 { responder(app, correcto: true) }
        for _ in 0..<3 { responder(app, correcto: false) }
        // Primera partida terminada: pregunta del recordatorio, en contexto (una sola vez).
        let alerta = app.alerts.firstMatch
        XCTAssertTrue(alerta.waitForExistence(timeout: 10), "Se pregunta por el recordatorio tras la primera ronda")
        XCTAssertTrue(alerta.label.contains("Te aviso"))
        alerta.buttons["Ahora no"].tap()
        app.buttons["botonTerminar"].tap()
        // Progreso → Ajustes: sonido desactivado.
        pestana(app, "Progreso")
        XCTAssertTrue(app.descendants(matching: .any)["seccionDominio"].waitForExistence(timeout: 10))
        try auditar(app, "Progreso", bordesDelScroll: true)
        let ajustes = app.buttons["botonAjustes"]
        while !ajustes.isHittable { app.scrollViews.firstMatch.swipeUp() }
        ajustes.tap()
        let sonido = app.switches["ajusteSonido"]
        XCTAssertTrue(sonido.waitForExistence(timeout: 10))
        // Con el grupo «Tu semana», el final de Ajustes queda bajo la barra de pestañas flotante (D-048).
        try auditar(app, "Ajustes", bordesDelScroll: true)
        sonido.switches.firstMatch.tap()
        XCTAssertEqual(sonido.value as? String, "0")
        // Cerrar y reabrir.
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = almacen
        app.launch()
        XCTAssertTrue(app.buttons["baldosaSupervivencia"].waitForExistence(timeout: 60))
        XCTAssertTrue(app.buttons["baldosaSupervivencia"].label.contains("Récord: 56 puntos"), app.buttons["baldosaSupervivencia"].label)
        pestana(app, "Progreso")
        let ajustes2 = app.buttons["botonAjustes"]
        XCTAssertTrue(ajustes2.waitForExistence(timeout: 10))
        while !ajustes2.isHittable { app.scrollViews.firstMatch.swipeUp() }
        ajustes2.tap()
        XCTAssertEqual(app.switches["ajusteSonido"].value as? String, "0", "El ajuste se conserva")
        app.buttons["botonCreditos"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pantallaCreditos"].waitForExistence(timeout: 10))
        try auditar(app, "Créditos")
        XCTAssertTrue(incidencias.isEmpty, incidencias.joined(separator: "\n"))
    }
}
