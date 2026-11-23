import Foundation
import Testing
@testable import Educulter

@Suite("Escalera de dominio")
struct EscaleraTests {
    @Test("Sube con 4 aciertos en los 5 últimos intentos")
    func subeConCuatroDeCinco() {
        var e = EstadoEscalera(peldano: 2)
        for r in [true, false, true, true] { do { let v = e.registrar(correcto: r, peldanoDelItem: 2); #expect(!v) } }
        do { let v = e.registrar(correcto: true, peldanoDelItem: 2); #expect(v) }
        #expect(e.peldano == 3 && e.ventana.isEmpty)
    }

    @Test("Cuatro aciertos seguidos bastan; los fallos antiguos salen de la ventana")
    func ventanaDeslizante() {
        var e = EstadoEscalera(peldano: 2)
        do { let v = e.registrar(correcto: false, peldanoDelItem: 2); #expect(!v) }
        do { let v = e.registrar(correcto: false, peldanoDelItem: 2); #expect(!v) }
        for _ in 0..<3 { do { let v = e.registrar(correcto: true, peldanoDelItem: 2); #expect(!v) } }
        #expect(e.ventana == [false, false, true, true, true])
        do { let v = e.registrar(correcto: true, peldanoDelItem: 2); #expect(v, "Ventana [F,T,T,T,T] → 4 de 5") }
        var f = EstadoEscalera(peldano: 1)
        for _ in 0..<3 { f.registrar(correcto: true, peldanoDelItem: 1) }
        do { let v = f.registrar(correcto: true, peldanoDelItem: 1); #expect(v) }
    }

    @Test("Los ítems de otros peldaños no cuentan")
    func otrosPeldanos() {
        var e = EstadoEscalera(peldano: 3)
        for _ in 0..<5 { do { let v = e.registrar(correcto: true, peldanoDelItem: 2); #expect(!v) } }
        #expect(e.peldano == 3 && e.ventana.isEmpty)
    }

    @Test("Dominada al superar los peldaños 3 y 4; el 5 es el tope")
    func dominio() {
        var e = EstadoEscalera(peldano: 3)
        for _ in 0..<4 { e.registrar(correcto: true, peldanoDelItem: 3) }
        #expect(e.peldano == 4 && !e.dominada())
        for _ in 0..<4 { e.registrar(correcto: true, peldanoDelItem: 4) }
        #expect(e.peldano == 5 && e.dominada())
        for _ in 0..<5 { do { let v = e.registrar(correcto: true, peldanoDelItem: 5); #expect(!v) } }
        #expect(e.peldano == 5)
    }

    @Test("Regla configurable por peldaño")
    func configurable() {
        var config = ConfiguracionEscalera()
        config.reglasPorPeldano[1] = .init(ventana: 2, aciertos: 2)
        var e = EstadoEscalera()
        do { let v = e.registrar(correcto: true, peldanoDelItem: 1, config: config); #expect(!v) }
        do { let v = e.registrar(correcto: true, peldanoDelItem: 1, config: config); #expect(v) }
        #expect(config.regla(para: 2) == config.reglaGeneral)
    }
}

@Suite("Leitner")
struct LeitnerTests {
    let hoy = Fx.dia(2026, 11, 23)

    @Test("Estado inicial: caja 1 y repaso al día siguiente")
    func inicial() {
        let l = EstadoLeitner.inicial(hoy: hoy)
        #expect(l.caja == 1 && l.proximoRepaso == Fx.dia(2026, 11, 24))
        #expect(!l.vencido(hoy: hoy) && l.vencido(hoy: Fx.dia(2026, 11, 24)) && l.vencido(hoy: Fx.dia(2026, 12, 30)))
    }

    @Test("Acierto sube una caja con intervalos 1, 3, 7, 14, 30")
    func intervalos() {
        var l = EstadoLeitner(caja: 1, proximoRepaso: hoy)
        var dia = hoy
        for (caja, intervalo) in [(2, 3), (3, 7), (4, 14), (5, 30), (5, 30)] {
            do { let v = l.registrarRepaso(correcto: true, hoy: dia); #expect(v) }
            #expect(l.caja == caja && l.proximoRepaso == dia.sumando(dias: intervalo))
            dia = l.proximoRepaso
        }
    }

    @Test("Un fallo baja dos cajas, con mínimo la caja 1")
    func fallo() {
        var l = EstadoLeitner(caja: 4, proximoRepaso: hoy)
        l.registrarRepaso(correcto: false, hoy: hoy)
        #expect(l.caja == 2 && l.proximoRepaso == hoy.sumando(dias: 3))
        var m = EstadoLeitner(caja: 2, proximoRepaso: hoy)
        m.registrarRepaso(correcto: false, hoy: hoy)
        #expect(m.caja == 1 && m.proximoRepaso == hoy.sumando(dias: 1))
    }

    @Test("Solo cuenta el primer intento del día y solo si está vencida")
    func unaVezAlDia() {
        var l = EstadoLeitner(caja: 2, proximoRepaso: hoy)
        do { let v = l.registrarRepaso(correcto: true, hoy: hoy.sumando(dias: -1)); #expect(!v) }
        do { let v = l.registrarRepaso(correcto: true, hoy: hoy); #expect(v) }
        do { let v = l.registrarRepaso(correcto: false, hoy: hoy); #expect(!v) }
        #expect(l.caja == 3)
        #expect(ConfiguracionLeitner().intervalo(caja: 99) == 30 && ConfiguracionLeitner().intervalo(caja: 0) == 1)
    }

    @Test("Estado de competencia: primer intento inicia Leitner; luego repasos y escalera")
    func estadoCompetencia() {
        var e = EstadoCompetencia(competenciaId: "LEN.SIN.SUJPRED")
        #expect(!e.vencida(hoy: hoy))
        let c1 = e.registrar(correcto: true, peldanoDelItem: 1, hoy: hoy)
        #expect(!c1.repasoAplicado && e.leitner?.caja == 1)
        let manana = hoy.sumando(dias: 1)
        #expect(e.vencida(hoy: manana))
        let c2 = e.registrar(correcto: true, peldanoDelItem: 1, hoy: manana)
        #expect(c2.repasoAplicado && e.leitner?.caja == 2)

        var d = EstadoCompetencia(competenciaId: "X", escalera: EstadoEscalera(peldano: 4, ventana: [true, true, true]))
        let c3 = d.registrar(correcto: true, peldanoDelItem: 4, hoy: hoy)
        #expect(c3.subioPeldano && c3.acabaDeDominarse && d.id == "X")
    }
}

@Suite("Cola de Rescate")
struct RescateTests {
    let a1 = Fx.item("LEN.SIN.SUJPRED.0001", peldano: 2)
    let a2 = Fx.item("LEN.SIN.SUJPRED.0002", peldano: 2)
    let a3 = Fx.item("LEN.SIN.SUJPRED.0003", peldano: 3)
    let b1 = Fx.item("MAT.NUM.FRACSUM.0001", peldano: 2)
    var banco: BancoContenido { Fx.banco([a1, a2, a3, b1]) }
    let fecha = Fx.fecha(2026, 11, 23)

    @Test("Un fallo entra una sola vez")
    func fallo() {
        var cola = ColaRescate()
        cola.registrarFallo(a1, fecha: fecha)
        cola.registrarFallo(a1, fecha: fecha)
        #expect(cola.cantidad == 1 && !cola.estaVacia)
        #expect(cola.entradas.first == EntradaRescate(itemId: a1.id, competencia: a1.competencia, peldano: 2, fecha: fecha))
    }

    @Test("Se rescata con una variante, no con el mismo ítem si hay variante")
    func variante() {
        var cola = ColaRescate()
        cola.registrarFallo(a1, fecha: fecha)
        do { let v = cola.registrarAcierto(a1, banco: banco); #expect(v == nil, "Hay variante: el mismo ítem no rescata") }
        do { let v = cola.registrarAcierto(a3, banco: banco); #expect(v == nil, "Otro peldaño no rescata") }
        do { let v = cola.registrarAcierto(b1, banco: banco); #expect(v == nil, "Otra competencia no rescata") }
        do { let v = cola.registrarAcierto(a2, banco: banco); #expect(v?.itemId == a1.id) }
        #expect(cola.estaVacia)
    }

    @Test("Sin variante, se rescata con el mismo ítem")
    func sinVariante() {
        var cola = ColaRescate()
        cola.registrarFallo(b1, fecha: fecha)
        do { let v = cola.registrarAcierto(b1, banco: banco); #expect(v?.itemId == b1.id) }
    }

    @Test("Ítem propuesto para rescatar")
    func propuesta() {
        var rng = GeneradorConSemilla(semilla: 1)
        var cola = ColaRescate()
        cola.registrarFallo(a1, fecha: fecha)
        cola.registrarFallo(b1, fecha: fecha)
        let entradaA = cola.entradas[0], entradaB = cola.entradas[1]
        #expect(cola.itemParaRescatar(entradaA, banco: banco, excluir: [], esReciente: { _ in false }, rng: &rng)?.id == a2.id)
        #expect(cola.itemParaRescatar(entradaA, banco: banco, excluir: [a2.id], esReciente: { _ in false }, rng: &rng) == nil)
        #expect(cola.itemParaRescatar(entradaA, banco: banco, excluir: [], esReciente: { _ in true }, rng: &rng)?.id == a2.id,
                "Si solo hay variantes recientes, se usan")
        #expect(cola.itemParaRescatar(entradaB, banco: banco, excluir: [], esReciente: { _ in false }, rng: &rng)?.id == b1.id)
        #expect(cola.itemParaRescatar(entradaB, banco: banco, excluir: [b1.id], esReciente: { _ in false }, rng: &rng) == nil)
    }
}

@Suite("Constructor de rondas")
struct RondasTests {
    static let enCurso = "LEN.SIN.SUJPRED"
    static let repaso = "LEN.ORT.TILDES"
    static let avanzada = "MAT.NUM.FRACSUM"

    let ahora = Fx.fecha(2026, 11, 23, 10)
    let banco: BancoContenido = {
        var items: [Item] = []
        for i in 1...10 { items.append(Fx.item("\(enCurso).\(String(format: "%04d", i))", peldano: 2, dificultad: (i % 5) + 1)) }
        for i in 1...3 { items.append(Fx.item("\(enCurso).\(String(format: "%04d", 20 + i))", peldano: 1)) }
        for i in 1...4 { items.append(Fx.item("\(repaso).\(String(format: "%04d", i))", peldano: 2)) }
        for i in 1...4 { items.append(Fx.item("\(avanzada).\(String(format: "%04d", i))", peldano: 3)) }
        items.append(Fx.item("\(avanzada).0099", peldano: 5))
        let teoria = TarjetaTeoria(id: "\(enCurso).T01", competencia: enCurso, titulo: "T",
                                   bloques: [.init(tipo: .texto, contenido: "x")], procedencia: Fx.original, validacion: Fx.borrador)
        return Fx.banco(items, teoria: [teoria])
    }()

    var estados: [String: EstadoCompetencia] {
        let hoy = Fx.dia(2026, 11, 23)
        return [
            Self.enCurso: EstadoCompetencia(competenciaId: Self.enCurso, escalera: .init(peldano: 2), leitner: .init(caja: 1, proximoRepaso: hoy)),
            Self.repaso: EstadoCompetencia(competenciaId: Self.repaso, escalera: .init(peldano: 2), leitner: .init(caja: 2, proximoRepaso: hoy.sumando(dias: -2))),
            Self.avanzada: EstadoCompetencia(competenciaId: Self.avanzada, escalera: .init(peldano: 3), leitner: .init(caja: 3, proximoRepaso: hoy.sumando(dias: 5))),
        ]
    }

    var rescate: ColaRescate {
        var cola = ColaRescate()
        for id in ["\(Self.enCurso).0001", "\(Self.enCurso).0002", "\(Self.enCurso).0003"] {
            cola.registrarFallo(banco.item(id: id)!, fecha: ahora)
        }
        return cola
    }

    func ronda(estados: [String: EstadoCompetencia]? = nil, rescate: ColaRescate? = nil, enCurso: String? = enCurso,
               vistos: [String: Date] = [:], semilla: UInt64 = 7, config: ConfiguracionRonda = .estandar) -> Ronda {
        var rng = GeneradorConSemilla(semilla: semilla)
        return ConstructorRondas(banco: banco, config: config).construir(
            estados: estados ?? self.estados, rescate: rescate ?? self.rescate, enCurso: enCurso,
            vistos: vistos, ahora: ahora, calendario: Fx.madrid, rng: &rng)
    }

    @Test("Prioridades: repaso, Rescate (máx. 2), en curso e intercalado; 6–8 ítems sin repetir")
    func prioridades() throws {
        let r = ronda()
        #expect((6...8).contains(r.items.count))
        #expect(Set(r.items.map(\.itemId)).count == r.items.count)
        #expect(r.items.first?.motivo == .repaso)
        #expect(banco.item(id: r.items[0].itemId)?.competencia == Self.repaso)
        #expect(r.items.filter { $0.motivo == .rescate }.count == 2)
        #expect(r.items.filter { $0.motivo == .intercalado }.count == 1)
        let intercalado = try #require(r.items.first { $0.motivo == .intercalado })
        #expect(banco.item(id: intercalado.itemId)?.competencia == Self.avanzada)
        #expect(banco.item(id: intercalado.itemId)?.peldano == 3, "Nunca peldaño 5 en ronda")
        let motivos = r.items.map(\.motivo)
        #expect(motivos == motivos.sorted { orden($0) < orden($1) })
        let dificultades = r.items.filter { $0.motivo == .enCurso }.compactMap { banco.item(id: $0.itemId)?.dificultad }
        #expect(dificultades == dificultades.sorted(), "Dificultad creciente en la competencia en curso")
        #expect(r.items.filter { $0.motivo == .enCurso }.allSatisfy { banco.item(id: $0.itemId)?.peldano == 2 })
        #expect(r.teoriaPrevia.isEmpty && r.competenciaEnCurso == Self.enCurso)
    }

    private func orden(_ m: ItemRonda.Motivo) -> Int {
        [.repaso: 0, .rescate: 1, .enCurso: 2, .intercalado: 3, .relleno: 4][m] ?? 9
    }

    @Test("Los rescates usan variantes distintas del ítem fallado")
    func rescatesConVariantes() {
        let r = ronda()
        let rescates = r.items.filter { $0.motivo == .rescate }.map(\.itemId)
        // Las dos primeras entradas de la cola se rescatan con un ítem distinto del fallado.
        #expect(rescates.count == 2)
        for (item, entrada) in zip(rescates, rescate.entradas) {
            #expect(item != entrada.itemId)
            #expect(banco.item(id: item)?.competencia == entrada.competencia && banco.item(id: item)?.peldano == entrada.peldano)
        }
    }

    @Test("No repite ítems vistos en 24 h si hay alternativa")
    func sinRepetir() {
        let vistosEnCurso = (1...6).map { "\(Self.enCurso).\(String(format: "%04d", $0))" }
        var vistos: [String: Date] = [:]
        for id in vistosEnCurso { vistos[id] = ahora.addingTimeInterval(-3600) }
        let r = ronda(rescate: ColaRescate(), vistos: vistos)
        #expect(r.items.allSatisfy { !vistosEnCurso.contains($0.itemId) })
        // Vistos hace más de 24 h vuelven a estar disponibles; si no hay alternativa, se repiten.
        var todos: [String: Date] = [:]
        for item in banco.items { todos[item.id] = ahora.addingTimeInterval(-3600) }
        #expect(ronda(rescate: ColaRescate(), vistos: todos).items.count >= 6)
    }

    @Test("Peldaño 1: se adjunta la teoría y se usan los ítems guiados")
    func peldanoUno() {
        var estados = self.estados
        estados[Self.enCurso] = EstadoCompetencia(competenciaId: Self.enCurso)
        let r = ronda(estados: estados, rescate: ColaRescate())
        #expect(r.teoriaPrevia == ["\(Self.enCurso).T01"])
        #expect(r.items.filter { $0.motivo == .enCurso }.allSatisfy { banco.item(id: $0.itemId)?.peldano == 1 })
    }

    @Test("Relleno hasta el mínimo cuando falta contenido, y deterministas con la misma semilla")
    func rellenoYDeterminismo() {
        let r = ronda(estados: [:], rescate: ColaRescate(), enCurso: nil)
        #expect(r.items.count == 6 && r.items.allSatisfy { $0.motivo == .relleno })
        #expect(r.items.allSatisfy { (banco.item(id: $0.itemId)?.peldano ?? 9) <= 4 })
        #expect(ronda() == ronda())
        var config = ConfiguracionRonda()
        config.maximo = 6; config.objetivo = 6
        #expect(ronda(config: config).items.count == 6)
    }

    @Test("Candidatos: peldaño inferior más cercano y nunca el 5")
    func candidatos() {
        let c = ConstructorRondas(banco: banco)
        #expect(c.candidatos(competencia: Self.avanzada, peldano: 5).allSatisfy { $0.peldano == 3 })
        #expect(c.candidatos(competencia: Self.repaso, peldano: 4).allSatisfy { $0.peldano == 2 })
        #expect(c.candidatos(competencia: "NO.EXI.STE", peldano: 2).isEmpty)
    }
}

@Suite("Diagnóstico inicial")
struct DiagnosticoTests {
    /// 2 bloques ★★★ de Lengua, 1 de Matemáticas y 1 bloque ★★; ítems de dificultad 1–4.
    let banco: BancoContenido = {
        var items: [Item] = []
        for comp in ["LEN.SIN.SUJPRED", "LEN.ORT.TILDES", "MAT.NUM.FRACSUM", "MAT.ROM.LECTURA"] {
            for d in 1...4 { items.append(Fx.item("\(comp).000\(d)", peldano: 2, dificultad: d)) }
        }
        items.append(Fx.item("LEN.SIN.SUJPRED.0009", peldano: 5, dificultad: 5))
        return Fx.banco(items, extras: ["LEN.LIT.CRONO"], prioridades: ["MAT.ROM": 2])
    }()

    @Test("Un ítem por bloque ★★★, alternando áreas y con dificultad inicial 2")
    func seleccionInicial() {
        let s = SesionDiagnostico(banco: banco, rng: GeneradorConSemilla(semilla: 3))
        let bloques = s.pendientes.compactMap { banco.item(id: $0) }.map { String($0.competencia.prefix(7)) }
        #expect(bloques == ["LEN.SIN", "MAT.NUM", "LEN.ORT"], "LEN.LIT no tiene ítems; MAT.ROM es ★★")
        #expect(s.pendientes.compactMap { banco.item(id: $0)?.dificultad }.allSatisfy { $0 == 2 })
        #expect(!s.terminado && s.siguienteItem != nil)
    }

    @Test("Acierto → ítem más difícil (máx. 2 por bloque); fallo → nada más")
    func adaptativo() throws {
        var s = SesionDiagnostico(banco: banco, rng: GeneradorConSemilla(semilla: 3))
        var respuestas: [String: Bool] = [:]
        // Lengua sintaxis: acierta las dos. Matemáticas: falla. Ortografía: acierta y falla la difícil.
        let plan: [String: [Bool]] = ["LEN.SIN": [true, true], "MAT.NUM": [false], "LEN.ORT": [true, false]]
        var cursor: [String: Int] = [:]
        var vueltas = 0
        while let item = s.siguienteItem, vueltas < 20 {
            let bloque = String(item.competencia.prefix(7))
            let i = cursor[bloque, default: 0]
            let correcto = plan[bloque]?[i] ?? false
            cursor[bloque] = i + 1
            respuestas[item.id] = correcto
            s.registrar(itemId: item.id, correcto: correcto)
            vueltas += 1
        }
        #expect(s.terminado && vueltas == 5)
        #expect(cursor == ["LEN.SIN": 2, "MAT.NUM": 1, "LEN.ORT": 2])
        #expect(s.respuestas["LEN.SIN"]?.map(\.dificultad) == [2, 3])
        s.registrar(itemId: "NO.EXISTE.0001", correcto: true)

        let r = s.resultado(fecha: Fx.fecha(2026, 11, 23))
        let niveles = Dictionary(uniqueKeysWithValues: r.niveles.map { ($0.bloqueId, $0.nivel) })
        #expect(niveles == ["LEN.SIN": 1, "MAT.NUM": 0, "LEN.ORT": 0.5])
        // Plan: debilidad × prioridad. MAT.NUM (1×3) > LEN.ORT (0,5×3) > MAT.ROM (0,5×2, sin datos) > LEN.SIN (0).
        #expect(r.plan.map(\.bloqueId) == ["MAT.NUM", "LEN.ORT", "MAT.ROM", "LEN.SIN"])
        #expect(r.plan.first?.puntuacion == 3)
    }

    @Test("Si se acierta y no hay ítem más difícil, el bloque queda en nivel 1")
    func sinMasDificil() {
        let solo = Fx.banco([Fx.item("LEN.SIN.SUJPRED.0001", dificultad: 4)])
        var s = SesionDiagnostico(banco: solo, rng: GeneradorConSemilla(semilla: 1))
        #expect(s.pendientes == ["LEN.SIN.SUJPRED.0001"])
        s.registrar(itemId: "LEN.SIN.SUJPRED.0001", correcto: true)
        #expect(s.terminado)
        #expect(s.resultado(fecha: .distantPast).niveles.first?.nivel == 1)
    }
}
