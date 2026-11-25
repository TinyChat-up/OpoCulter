import Foundation
import SwiftData
import Testing
@testable import Educulter

// Tests de la Fase 05D: Supervivencia, Camino (prueba de nivel y Reto de bloque), plan del
// diagnóstico, Rescate por competencia, recordatorio, estadísticas, sonido y persistencia.

@MainActor
private func servicio(_ banco: BancoContenido, repo: any RepositorioProgreso = RepositorioEnMemoria(),
                      ahora: Date = Fx.fecha(2026, 11, 23, 10), semilla: UInt64 = 7) -> ServicioSesion {
    ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: ahora), calendario: Fx.madrid,
                   rng: GeneradorConSemilla(semilla: semilla))
}

private let bancoDebug: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 3))!

/// Juega una ronda preparada respondiendo bien los `aciertos` primeros ítems y la completa.
@MainActor
private func jugar(_ s: ServicioSesion, _ tipo: TipoRonda, aciertos: Int) throws -> (RondaPreparada, EfectoRonda) {
    let ronda = try s.prepararRonda(tipo)
    var buenos = 0
    for (i, ir) in ronda.items.enumerated() {
        let item = try #require(s.banco.item(id: ir.itemId))
        let correcto = i < aciertos
        let r = Evaluador.evaluar(correcto ? RespuestaEjemplo.correcta(item.payload) : RespuestaEjemplo.conUnError(item.payload), para: item)
        if r.correcto { buenos += 1 }
        try s.registrar(item: item, resultado: r, usoPista: false, combo: 1, motivo: ir.motivo)
    }
    return (ronda, try s.completarRonda(ronda, aciertos: buenos))
}

// MARK: - Supervivencia

@Suite("Supervivencia: reglas, puntuación y récords")
struct SupervivenciaTests {
    @Test("Sube un nivel cada 4 aciertos seguidos hasta el 6; un fallo quita vida y baja uno (mín. 1)")
    func dificultad() {
        var e = EstadoSupervivencia()
        #expect(e.vidas == 3 && e.dificultad == 1)
        for _ in 0..<4 { e.responder(correcto: true) }
        #expect(e.dificultad == 2)
        for _ in 0..<3 { e.responder(correcto: true) }
        e.responder(correcto: false)
        #expect(e.dificultad == 1 && e.vidas == 2 && e.combo == 0, "La racha de nivel se pierde con el fallo")
        e.responder(correcto: false)
        #expect(e.dificultad == 1 && e.vidas == 1, "No baja de 1")
        for _ in 0..<40 { e.responder(correcto: true) }
        #expect(e.dificultad == 6 && e.nivelMaximo == 6, "Tope en 6 «Experto»")
        e.responder(correcto: false)
        #expect(e.terminada && e.vidas == 0 && e.dificultad == 5 && e.nivelMaximo == 6)
        #expect(e.responder(correcto: true) == 0, "Terminada: no suma nada")
    }

    @Test("Puntos: 10 × dificultad con multiplicador de combo hasta ×2")
    func puntos() {
        let r = ReglasSupervivencia.estandar
        #expect(r.puntos(dificultad: 1, combo: 1) == 10)
        #expect(r.puntos(dificultad: 3, combo: 2) == 38)   // 30 × 1,25 = 37,5 → 38
        #expect(r.puntos(dificultad: 6, combo: 5) == 120)  // × 2
        #expect(r.puntos(dificultad: 6, combo: 50) == 120) // tope ×2
        var e = EstadoSupervivencia()
        let ganados = (0..<4).map { _ in e.responder(correcto: true) }
        #expect(ganados == [10, 13, 15, 18] && e.puntos == 56)
    }

    @Test("Récords: las abandonadas y las no terminadas no cuentan; global y por área")
    func records() {
        let base = Fx.fecha(2026, 11, 20)
        let partidas = [
            PartidaSupervivencia(inicio: base, fin: base, area: "LEN", puntos: 200),
            PartidaSupervivencia(inicio: base.addingTimeInterval(60), fin: base, area: nil, puntos: 350),
            PartidaSupervivencia(inicio: base.addingTimeInterval(120), fin: base, area: "MAT", puntos: 900, abandonada: true),
            PartidaSupervivencia(inicio: base.addingTimeInterval(180), area: "MAT", puntos: 990),
        ]
        let r = RecordsSupervivencia(partidas: partidas)
        #expect(r.global?.puntos == 350)
        #expect(r.porArea["LEN"]?.puntos == 200 && r.porArea["MIX"]?.puntos == 350 && r.porArea["MAT"] == nil)
    }

    @Test("Pesos por bloque de la MATRIZ (suman 1 por área) y efecto de la debilidad")
    func pesos() {
        let len = PesosSupervivencia.frecuenciaExamen.keys.filter { $0.hasPrefix("LEN") }.map(PesosSupervivencia.pesoExamen).reduce(0, +)
        let mat = PesosSupervivencia.frecuenciaExamen.keys.filter { $0.hasPrefix("MAT") }.map(PesosSupervivencia.pesoExamen).reduce(0, +)
        #expect(abs(len - 1) < 1e-9 && abs(mat - 1) < 1e-9)
        #expect(PesosSupervivencia.frecuenciaExamen.values.reduce(0, +) == 139, "Las 139 preguntas de la matriz")
        #expect(abs(PesosSupervivencia.pesoExamen("LEN.LIT") - 14.0 / 69) < 1e-9)
        #expect(PesosSupervivencia.peso("MAT.NUM", debilidad: 1) == 3 * PesosSupervivencia.peso("MAT.NUM", debilidad: 0))
    }

    @Test("El selector da ítems de la dificultad exacta (generados @dN) que el banco reproduce por id")
    @MainActor
    func selector() throws {
        let sel = SelectorSupervivencia(banco: bancoDebug)
        var rng = GeneradorConSemilla(semilla: 11)
        let validador = ValidadorContenido(anioActual: 2026)
        let comps = Set(bancoDebug.catalogo.todasLasCompetencias.map(\.id))
        for d in 1...6 {
            for _ in 0..<20 {
                let item = try #require(sel.siguiente(dificultad: d, area: nil, debilidades: [:], usados: [], rng: &rng))
                if item.id.contains("@d") {
                    #expect(item.dificultad == d && item.id.contains("@d\(d)#"))
                    #expect(bancoDebug.item(id: item.id) == item, "Reproducible por id (Rescate)")
                } else {
                    #expect(item.peldano >= 2)
                }
                #expect(validador.validar(item: item, competencias: comps).isEmpty)
            }
        }
        #expect(sel.bloques(area: "MAT").allSatisfy { $0.hasPrefix("MAT") })
        let soloLen = Fx.banco([Fx.item("LEN.ORT.AGU.0001", peldano: 1), Fx.item("LEN.ORT.AGU.0002", peldano: 2)])
        #expect(SelectorSupervivencia(banco: soloLen).bloques(area: nil) == ["LEN.ORT"], "Solo bloques con contenido (peldaño ≥ 2)")
        #expect(SelectorSupervivencia(banco: soloLen).bloques(area: "MAT").isEmpty)
    }

    @Test("Partida completa: efectos reales, récord solo al batir una partida anterior, abandonada sin récord")
    @MainActor
    func partida() throws {
        let repo = RepositorioEnMemoria()
        let s = servicio(bancoDebug, repo: repo)
        func jugarPartida(aciertos: Int) throws -> ResultadoPartida {
            let ronda = try s.prepararRonda(.supervivencia(area: nil))
            var estado = EstadoSupervivencia()
            var p = PartidaSupervivencia(inicio: s.reloj.ahora, area: nil)
            var usados = Set<String>()
            var item = try #require(ronda.items.first.flatMap { s.banco.item(id: $0.itemId) })
            var i = 0
            while !estado.terminada {
                let correcto = i < aciertos
                let r = Evaluador.evaluar(correcto ? RespuestaEjemplo.correcta(item.payload) : RespuestaEjemplo.conUnError(item.payload), para: item)
                try s.registrar(item: item, resultado: r, usoPista: false, combo: estado.combo + 1, motivo: .supervivencia)
                let ganados = estado.responder(correcto: r.correcto)
                p.jugadas.append(.init(itemId: item.id, bloqueId: "", dificultad: item.dificultad, correcto: r.correcto, puntos: ganados))
                usados.insert(item.id)
                i += 1
                if !estado.terminada { item = try #require(try s.siguienteSupervivencia(dificultad: estado.dificultad, area: nil, usados: usados)) }
            }
            p.puntos = estado.puntos; p.nivelMaximo = estado.nivelMaximo; p.aciertos = estado.aciertos; p.fallos = estado.fallos
            return try s.cerrarPartida(p, abandonada: false, ronda: ronda)
        }
        let primera = try jugarPartida(aciertos: 5)
        #expect(!primera.esRecord && primera.mejorAnterior == nil, "La primera no bate a nadie")
        #expect(primera.partida.puntos > 0 && primera.partida.fallos == 3)
        #expect(try repo.colaRescate().cantidad >= 1, "Los errores van a Rescate")
        #expect(try repo.intentos(desde: nil).filter { $0.motivo == .supervivencia }.count == primera.partida.jugadas.count)
        #expect(primera.logrosNuevos.contains { $0.id == "superviviente" })
        let segunda = try jugarPartida(aciertos: 12)
        #expect(segunda.esRecord && segunda.mejorAnterior?.puntos == primera.partida.puntos)
        #expect(segunda.logrosNuevos.contains { $0.id == "nuevo-record" })
        // Abandonada: se guarda con lo jugado, sin récord.
        let ronda = try s.prepararRonda(.supervivencia(area: nil))
        var abandonada = PartidaSupervivencia(inicio: s.reloj.ahora, area: nil, puntos: 99_999)
        abandonada.jugadas = [.init(itemId: "x", bloqueId: "", dificultad: 1, correcto: true, puntos: 10)]
        let r = try s.cerrarPartida(abandonada, abandonada: true, ronda: ronda)
        #expect(!r.esRecord && r.efectoRonda == nil)
        #expect(try repo.partidas().count == 3)
        #expect(try s.recordsSupervivencia().global?.puntos == segunda.partida.puntos)
        #expect(try s.estadoHoy().recordSupervivencia == segunda.partida.puntos)
    }
}

// MARK: - Camino

@Suite("Camino: estados, prueba de nivel y Reto de bloque")
struct CaminoTests {
    /// LEN.ORT.AGU con 3 ítems del peldaño 1 y 5 del 3; LEN.ORT.DIA con 2 ítems; LEN.ORT.HIA sin contenido.
    static let banco: BancoContenido = {
        var items = (1...3).map { Fx.item("LEN.ORT.AGU.000\($0)", peldano: 1) }
        items += (4...8).map { Fx.item("LEN.ORT.AGU.000\($0)", peldano: 3, dificultad: 4) }
        items += (1...2).map { Fx.item("LEN.ORT.DIA.000\($0)", peldano: 1) }
        items += (1...8).map { Fx.item("LEN.SIN.SUJPRED.00\($0 + 10)", peldano: 3, dificultad: $0 % 2 == 0 ? 4 : 5) }
        return Fx.banco(items, extras: ["LEN.ORT.HIA", "MAT.NUM.FRAREP"])
    }()

    @Test("Estados de nodo, candado orientativo y prueba de nivel disponible")
    @MainActor
    func estados() throws {
        let s = servicio(Self.banco)
        let tramos = try s.camino(area: "LEN")
        let nodos = Dictionary(uniqueKeysWithValues: tramos.flatMap(\.nodos).map { ($0.id, $0) })
        #expect(nodos["LEN.ORT.HIA"]?.estado == .sinContenido)
        #expect(nodos["LEN.ORT.AGU"]?.estado == .enCurso, "La competencia en curso")
        #expect(nodos["LEN.ORT.DIA"]?.estado == .disponible && nodos["LEN.ORT.DIA"]?.bloqueadoPorOrden == true, "Después de la recomendada: candado")
        #expect(nodos["LEN.ORT.AGU"]?.pruebaNivelDisponible == true && nodos["LEN.ORT.DIA"]?.pruebaNivelDisponible == false, "Hacen falta 5 ítems del peldaño 3")
        #expect(tramos.first { $0.id == "LEN.SIN" }?.retoDisponible == true && tramos.first { $0.id == "LEN.ORT" }?.retoDisponible == false)
    }

    @Test("Prueba de nivel: 4 de 5 supera los peldaños 1–2 y queda registrado; 3 de 5 no")
    @MainActor
    func pruebaNivel() throws {
        let repo = RepositorioEnMemoria()
        let s = servicio(Self.banco, repo: repo)
        let (ronda, fallida) = try jugar(s, .pruebaNivel("LEN.ORT.AGU"), aciertos: 3)
        #expect(ronda.items.count == 5 && ronda.items.allSatisfy { $0.motivo == .pruebaNivel })
        #expect(fallida.pruebaNivelSuperada == false)
        #expect(try s.estado(competencia: "LEN.ORT.AGU").escalera.peldano < 3)
        let (_, superada) = try jugar(s, .pruebaNivel("LEN.ORT.AGU"), aciertos: 4)
        #expect(superada.pruebaNivelSuperada == true)
        #expect(try s.estado(competencia: "LEN.ORT.AGU").escalera.peldano == 3)
        #expect(try repo.perfil().desbloqueos.map(\.competenciaId) == ["LEN.ORT.AGU"])
        #expect(superada.logrosNuevos.contains { $0.id == "salto-de-nivel" })
        #expect(try s.camino(area: "LEN").flatMap(\.nodos).first { $0.id == "LEN.ORT.AGU" }?.pruebaNivelDisponible == false)
    }

    @Test("Reto de bloque: 8 ítems sin ayudas de dificultad 4–5; 6 aciertos dan la medalla")
    @MainActor
    func reto() throws {
        let repo = RepositorioEnMemoria()
        let s = servicio(Self.banco, repo: repo)
        let (ronda, fallido) = try jugar(s, .retoBloque("LEN.SIN"), aciertos: 5)
        let items = ronda.items.compactMap { s.banco.item(id: $0.itemId) }
        #expect(items.count == 8 && items.allSatisfy { $0.peldano >= 3 && (4...5).contains($0.dificultad) && $0.pistas.isEmpty })
        #expect(fallido.retoSuperado == false)
        let (_, ganado) = try jugar(s, .retoBloque("LEN.SIN"), aciertos: 6)
        #expect(ganado.retoSuperado == true && ganado.logrosNuevos.contains { $0.id == "medalla-LEN.SIN" })
        #expect(try repo.logros().contains { $0.logroId == "medalla-LEN.SIN" })
        #expect(try s.camino(area: "LEN").first { $0.id == "LEN.SIN" }?.medallaObtenida == true)
        #expect(try s.prepararRonda(.retoBloque("LEN.ORT")).items.isEmpty, "Sin contenido suficiente no hay Reto")
    }

    @Test("Reto con plantillas: completa con generados de dificultad 4–5 y peldaño ≥ 3, válidos y reproducibles")
    @MainActor
    func retoGenerado() throws {
        let c = ConstructorCamino(banco: bancoDebug)
        var rng = GeneradorConSemilla(semilla: 2)
        let items = c.itemsReto("MAT.ROM", rng: &rng)
        #expect(items.count == 8)
        let comps = Set(bancoDebug.catalogo.todasLasCompetencias.map(\.id))
        for i in items {
            #expect((4...5).contains(i.dificultad) && i.peldano >= 3 && i.pistas.isEmpty)
            #expect(bancoDebug.item(id: i.id) == i)
            #expect(ValidadorContenido(anioActual: 2026).validar(item: i, competencias: comps).isEmpty)
        }
    }

    @Test("Practicar una competencia: solo ítems suyos y teoría en el peldaño 1")
    @MainActor
    func practicar() throws {
        let s = servicio(bancoDebug)
        let ronda = try s.prepararRonda(.competencia("LEN.ORT.AGU"))
        #expect(!ronda.items.isEmpty && ronda.items.allSatisfy { s.banco.item(id: $0.itemId)?.competencia == "LEN.ORT.AGU" })
        #expect(ronda.teoriaPrevia == bancoDebug.teoria(competencia: "LEN.ORT.AGU").map(\.id))
    }
}

// MARK: - Diagnóstico, Rescate y Progreso

@Suite("Diagnóstico, Rescate y estadísticas")
struct DiagnosticoRescateProgresoTests {
    @Test("Plan: fuerte, medio y débil; 2 recomendadas; aviso de bloques sin datos")
    func plan() {
        let banco = Fx.banco([Fx.item("LEN.ORT.AGU.0001"), Fx.item("MAT.NUM.FRAREP.0001"), Fx.item("LEN.SIN.SUJPRED.0001")],
                             extras: ["LEN.LIT.CRONO", "MAT.GEO.AREAS"])
        let resultado = ResultadoDiagnostico(fecha: .distantPast, niveles: [
            NivelBloque(bloqueId: "LEN.ORT", nivel: 1, respondidos: 2, aciertos: 2),
            NivelBloque(bloqueId: "MAT.NUM", nivel: 0, respondidos: 1, aciertos: 0),
            NivelBloque(bloqueId: "LEN.SIN", nivel: 0.5, respondidos: 2, aciertos: 1),
        ], plan: SesionDiagnostico.plan(niveles: [
            NivelBloque(bloqueId: "LEN.ORT", nivel: 1, respondidos: 2, aciertos: 2),
            NivelBloque(bloqueId: "MAT.NUM", nivel: 0, respondidos: 1, aciertos: 0),
            NivelBloque(bloqueId: "LEN.SIN", nivel: 0.5, respondidos: 2, aciertos: 1),
        ], banco: banco, config: .estandar))
        let plan = PlanDiagnostico(resultado: resultado, banco: banco) { !banco.items(competencia: $0).isEmpty }
        #expect(plan.bloques.map(\.nivel) == [.fuerte, .debil, .medio])
        #expect(plan.recomendadas.map(\.id) == ["MAT.NUM.FRAREP", "LEN.SIN.SUJPRED"], "Por debilidad × prioridad")
        #expect(Set(plan.sinDatos.map(\.id)) == ["LEN.LIT", "MAT.GEO"])
    }

    @Test("Diagnóstico completo con el servicio: prefiere generados de dificultad 2–3, guarda historial y logro")
    @MainActor
    func diagnostico() throws {
        let repo = RepositorioEnMemoria()
        let s = servicio(bancoDebug, repo: repo)
        for _ in 0..<2 {
            var sesion = s.nuevaSesionDiagnostico()
            var vueltas = 0
            while let item = sesion.siguienteItem, vueltas < 50 {
                sesion.registrar(itemId: item.id, correcto: vueltas % 2 == 0)
                vueltas += 1
            }
            let generados = sesion.respuestas.values.flatMap { $0 }.filter { $0.itemId.contains("#") }
            #expect(!generados.isEmpty && generados.allSatisfy { (2...5).contains($0.dificultad) })
            _ = try s.completarDiagnostico(sesion)
        }
        #expect(try repo.diagnosticos().count == 2, "El anterior queda en el historial")
        #expect(try repo.perfil().metricas[.diagnosticosCompletados] == 2)
        #expect(try repo.logros().contains { $0.logroId == "diagnostico" })
    }

    @Test("Rescate por competencia: grupos, ronda de una competencia y contador que baja de verdad")
    @MainActor
    func rescate() throws {
        let repo = RepositorioEnMemoria()
        let banco = Fx.banco((1...4).map { Fx.item("LEN.ORT.AGU.000\($0)") } + (1...3).map { Fx.item("MAT.NUM.FRAREP.000\($0)") })
        let s = servicio(banco, repo: repo)
        for id in ["LEN.ORT.AGU.0001", "LEN.ORT.AGU.0002", "MAT.NUM.FRAREP.0001"] {
            let item = try #require(banco.item(id: id))
            try s.registrar(item: item, resultado: Evaluador.evaluar(.verdaderoFalso(false), para: item), usoPista: false, combo: 0, motivo: nil)
        }
        let grupos = try s.gruposRescate()
        #expect(grupos.map(\.cantidad).reduce(0, +) == 3 && Set(grupos.map(\.id)) == ["LEN.ORT.AGU", "MAT.NUM.FRAREP"])
        #expect(grupos.first { $0.id == "LEN.ORT.AGU" }?.area == "LEN")
        let ronda = try s.prepararRonda(.rescateCompetencia("MAT.NUM.FRAREP"))
        #expect(ronda.items.count == 1 && ronda.items.allSatisfy { $0.motivo == .rescate && $0.itemId.hasPrefix("MAT.NUM") })
        let item = try #require(banco.item(id: ronda.items[0].itemId))
        try s.registrar(item: item, resultado: Evaluador.evaluar(.verdaderoFalso(true), para: item), usoPista: false, combo: 1, motivo: .rescate)
        #expect(try repo.colaRescate().cantidad == 2 && (try s.gruposRescate()).count == 1)
    }

    @Test("Estadísticas de Progreso contra un historial sintético")
    func estadisticas() {
        let cal = Fx.madrid
        let hoy = Fx.dia(2026, 11, 23)
        func intento(_ d: Int, _ comp: String, _ ok: Bool, xp: Int) -> Intento {
            Intento(fecha: Fx.fecha(2026, 11, d, 10), itemId: "x", competenciaId: comp, peldano: 2, correcto: ok, fraccionCorrecta: ok ? 1 : 0, xp: xp)
        }
        let intentos = [intento(23, "LEN.ORT.AGU", true, xp: 10), intento(23, "LEN.ORT.AGU", false, xp: 0), intento(22, "MAT.NUM.FRAREP", true, xp: 12),
                        Intento(fecha: Fx.fecha(2026, 10, 20, 10), itemId: "y", competenciaId: "MAT.NUM.FRAREP", peldano: 2, correcto: true,
                                fraccionCorrecta: 1, xp: 5)]
        var perfil = PerfilJugador()
        perfil.racha = EstadoRacha(actual: 2, record: 5, protectores: 2, ultimoDiaActivo: hoy, ultimoDiaProcesado: hoy)
        let partidas = [PartidaSupervivencia(inicio: .distantPast, fin: .distantPast, puntos: 120)]
        let e = EstadisticasProgreso(intentos: intentos, perfil: perfil, partidas: partidas, hoy: hoy, calendario: cal)
        #expect(e.evolucion.count == 28 && e.evolucion.last?.dia == hoy && e.evolucion.first?.dia == hoy.sumando(dias: -27))
        #expect(e.evolucion.last?.aciertos == 1 && e.evolucion.last?.respondidos == 2 && e.evolucion.last?.xp == 10)
        #expect(e.evolucion[26].xp == 12)
        #expect(e.evolucion.map(\.respondidos).reduce(0, +) == 3, "El intento del 20 de octubre queda fuera de las 4 semanas")
        #expect(e.respondidos == 4 && e.aciertos == 3)
        #expect(e.porArea["LEN"]?.porcentaje == 0.5 && e.porArea["MAT"]?.porcentaje == 1)
        #expect(e.rachaActual == 2 && e.rachaRecord == 5 && e.recordSupervivencia == 120)
    }
}

// MARK: - Recordatorio, sonido y persistencia

@MainActor
final class CentroSimulado: CentroNotificaciones {
    var permiso = true
    var programadas: [String: (cuerpo: String, fecha: DateComponents)] = [:]
    var permisoPedido = 0

    func solicitarPermiso() async -> Bool { permisoPedido += 1; return permiso }
    func programar(id: String, titulo: String, cuerpo: String, fecha: DateComponents) async { programadas[id] = (cuerpo, fecha) }
    func cancelar(ids: [String]) { for id in ids { programadas[id] = nil } }
    func pendientes() async -> [String] { Array(programadas.keys) }
}

@MainActor
final class SonidoEspia: ServicioSonido {
    var reproducidos: [String] = []
    func acierto() { reproducidos.append("acierto") }
    func fallo() { reproducidos.append("fallo") }
    func combo(_ n: Int) { reproducidos.append("combo") }
    func finRonda() { reproducidos.append("finRonda") }
    func record() { reproducidos.append("record") }
    func tildeCae() { reproducidos.append("tilde") }
    func celdaColoreada() { reproducidos.append("celda") }
}

@Suite("Recordatorio, sonido y persistencia de la 05D")
struct RecordatorioSonidoTests {
    @Test("Programa 7 días a la hora elegida; hoy no si ya hay ronda o la hora ha pasado; desactivado, nada")
    @MainActor
    func programacion() async {
        let centro = CentroSimulado()
        let p = ProgramadorRecordatorio(centro: centro, calendario: Fx.madrid)
        let hoy = Fx.dia(2026, 11, 23)
        var ajustes = Ajustes(recordatorio: true, minutoRecordatorio: 20 * 60 + 30)
        let racha = EstadoRacha(actual: 5, record: 5, protectores: 2, ultimoDiaActivo: hoy.sumando(dias: -1), ultimoDiaProcesado: hoy.sumando(dias: -1))
        await p.reprogramar(ajustes: ajustes, racha: racha, ahora: Fx.fecha(2026, 11, 23, 10))
        #expect(centro.programadas.count == 7)
        let deHoy = centro.programadas[ProgramadorRecordatorio.id(hoy)]
        #expect(deHoy?.fecha.hour == 20 && deHoy?.fecha.minute == 30)
        #expect(deHoy?.cuerpo == "Tu racha de 5 días te espera: una ronda de 3 minutos basta.")
        // Ronda hecha hoy: se cancela solo la de hoy.
        p.cancelarHoy(ahora: Fx.fecha(2026, 11, 23, 12))
        #expect(centro.programadas.count == 6 && centro.programadas[ProgramadorRecordatorio.id(hoy)] == nil)
        // Al reprogramar con la ronda de hoy hecha, hoy no se programa.
        let conRonda = EstadoRacha(actual: 6, record: 6, protectores: 2, ultimoDiaActivo: hoy, ultimoDiaProcesado: hoy)
        await p.reprogramar(ajustes: ajustes, racha: conRonda, ahora: Fx.fecha(2026, 11, 23, 10))
        #expect(centro.programadas.count == 6)
        // Hora pasada: tampoco hoy.
        await p.reprogramar(ajustes: ajustes, racha: racha, ahora: Fx.fecha(2026, 11, 23, 21))
        #expect(centro.programadas[ProgramadorRecordatorio.id(hoy)] == nil && centro.programadas.count == 6)
        ajustes.recordatorio = false
        await p.reprogramar(ajustes: ajustes, racha: racha, ahora: Fx.fecha(2026, 11, 23, 10))
        #expect(centro.programadas.isEmpty)
        #expect(ProgramadorRecordatorio.texto(racha: 0).contains("racha nueva") && !ProgramadorRecordatorio.texto(racha: 1).contains("días"))
    }

    @Test("Con el sonido desactivado no se reproduce nada; activado, sí")
    @MainActor
    func sonido() {
        let espia = SonidoEspia()
        var activo = false
        let s = SonidoConAjustes(destino: espia) { activo }
        s.acierto(); s.fallo(); s.combo(3); s.finRonda(); s.record(); s.tildeCae(); s.celdaColoreada()
        #expect(espia.reproducidos.isEmpty)
        activo = true
        s.acierto(); s.record()
        #expect(espia.reproducidos == ["acierto", "record"])
    }

    @Test("Cada sonido sintetizado dura 250 ms como máximo y no satura")
    @MainActor
    func duracion() {
        for (clave, notas) in SonidoSintetizado.recetas {
            #expect(notas.map(\.duracion).reduce(0, +) <= SonidoSintetizado.duracionMaxima + 1e-9, "\(clave)")
            let m = SonidoSintetizado.muestras(notas)
            #expect(Double(m.count) / 44_100 <= SonidoSintetizado.duracionMaxima + 0.001)
            #expect(m.allSatisfy { abs($0) <= 1 })
        }
        #expect(Set(SonidoSintetizado.recetas.keys) == ["acierto", "fallo", "combo", "record", "finRonda", "tilde", "celda"])
    }

    @Test("Ajustes, partidas, desbloqueos y diagnósticos persisten en disco; borrar el progreso conserva los ajustes")
    @MainActor
    func persistencia() throws {
        let url = URL.temporaryDirectory.appending(path: "modos-\(UUID().uuidString).store")
        do {
            let repo = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(url: url))
            try repo.guardar(Ajustes(sonido: false, vibracion: false, recordatorio: true, minutoRecordatorio: 19 * 60, recordatorioPreguntado: true))
            try repo.guardar(PartidaSupervivencia(inicio: Fx.fecha(2026, 11, 22), fin: Fx.fecha(2026, 11, 22), area: "MAT", puntos: 77))
            var perfil = try repo.perfil()
            perfil.desbloqueos = [Desbloqueo(competenciaId: "LEN.ORT.AGU", fecha: Fx.fecha(2026, 11, 22), aciertos: 4, total: 5)]
            try repo.guardar(perfil)
            try repo.guardar(ResultadoDiagnostico(fecha: Fx.fecha(2026, 11, 1), niveles: [], plan: []))
            try repo.guardar(ResultadoDiagnostico(fecha: Fx.fecha(2026, 11, 22), niveles: [], plan: []))
        }
        let repo = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(url: url))
        #expect(try repo.ajustes().sonido == false && repo.ajustes().minutoRecordatorio == 19 * 60)
        #expect(try repo.partidas().first?.puntos == 77)
        #expect(try repo.perfil().desbloqueos.first?.aciertos == 4)
        #expect(try repo.diagnosticos().count == 2 && repo.diagnostico()?.fecha == Fx.fecha(2026, 11, 22))
        try repo.borrarProgreso()
        #expect(try repo.partidas().isEmpty && repo.diagnosticos().isEmpty && repo.perfil() == PerfilJugador())
        #expect(try repo.ajustes().recordatorio == true, "Los ajustes se conservan")
    }

    @Test("Los créditos de la app coinciden con CREDITOS.md")
    func creditos() throws {
        let raiz = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let original = try String(contentsOf: raiz.appending(path: "CREDITOS.md"), encoding: .utf8)
        #expect(PantallaCreditos.texto == original)
        #expect(original.contains("Fredoka") && original.contains("Avatares"))
    }

    @Test("Preguntas disponibles: solo el contenido aprobado")
    @MainActor
    func preguntas() {
        let s = servicio(bancoDebug)
        let r = s.preguntasDisponibles()
        #expect(r.estaticos == bancoDebug.itemsEstaticos.filter { $0.validacion.estado == .aprobado }.count)
        // Lotes 02 y 02b: cuentan las variantes de las 42 plantillas aprobadas; las de prueba (borrador), no.
        #expect(r.plantillas.count == 42 && r.generados > 10_000)
    }
}
