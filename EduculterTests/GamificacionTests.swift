import Foundation
import Testing
@testable import Educulter

@Suite("XP, combo y niveles")
struct ExperienciaTests {
    @Test("XP por respuesta")
    func xp() {
        #expect(CalculadoraXP.xp(correcto: true, usoPista: false, peldano: 2, combo: 1) == 15, "10 + 5 sin pista")
        #expect(CalculadoraXP.xp(correcto: true, usoPista: false, peldano: 4, combo: 1) == 25, "+10 en Justifica")
        #expect(CalculadoraXP.xp(correcto: true, usoPista: true, peldano: 2, combo: 3) == 0, "0 si se usó pista")
        #expect(CalculadoraXP.xp(correcto: false, usoPista: false, peldano: 4, combo: 0) == 0)
        #expect(CalculadoraXP.xp(correcto: true, usoPista: false, peldano: 2, combo: 1, esRescate: true) == 20)
        #expect(CalculadoraXP.xp(correcto: true, usoPista: false, peldano: 2, combo: 2) == 17, "15 × 1,1 = 16,5 → 17")
        #expect(CalculadoraXP.xp(correcto: true, usoPista: false, peldano: 4, combo: 6) == 38, "25 × 1,5 = 37,5 → 38")
    }

    @Test("Multiplicador de combo hasta ×1,5")
    func multiplicador() {
        #expect(CalculadoraXP.multiplicador(combo: 0) == 1)
        #expect(CalculadoraXP.multiplicador(combo: 1) == 1)
        #expect(abs(CalculadoraXP.multiplicador(combo: 3) - 1.2) < 1e-9)
        #expect(CalculadoraXP.multiplicador(combo: 6) == 1.5)
        #expect(CalculadoraXP.multiplicador(combo: 50) == 1.5)
        var c = ContadorCombo()
        do { let v = c.registrar(correcto: true); #expect(v == 1) }
        do { let v = c.registrar(correcto: true); #expect(v == 2) }
        do { let v = c.registrar(correcto: false); #expect(v == 0) }
        c.registrar(correcto: true)
        #expect(c.actual == 1 && c.maximo == 2)
    }

    @Test("Curva de niveles suave y configurable")
    func niveles() {
        let curva = CurvaNiveles.estandar
        #expect(curva.xpAcumulada(paraNivel: 1) == 0)
        #expect(curva.xpAcumulada(paraNivel: 2) == 100)
        #expect(curva.xpAcumulada(paraNivel: 3) == 283)
        #expect(curva.xpAcumulada(paraNivel: 10) == 2700)
        #expect(curva.nivel(xp: 0) == 1 && curva.nivel(xp: 99) == 1 && curva.nivel(xp: 100) == 2 && curva.nivel(xp: 2700) == 10)
        let p = curva.progreso(xp: 150)
        #expect(p.nivel == 2 && p.xpEnNivel == 50 && p.xpParaSiguiente == 183)
        let lineal = CurvaNiveles(base: 50, exponente: 1, nivelMaximo: 3)
        #expect(lineal.nivel(xp: 1_000_000) == 3)
        #expect(lineal.progreso(xp: 1_000).fraccion == 1)
        // Monótona creciente.
        let umbrales = (1...50).map(curva.xpAcumulada(paraNivel:))
        #expect(zip(umbrales, umbrales.dropFirst()).allSatisfy { $0 < $1 })
    }
}

@Suite("Racha diaria")
struct RachaTests {
    func dia(_ m: Int, _ d: Int, _ a: Int = 2026) -> DiaCivil { Fx.dia(a, m, d) }

    @Test("Días consecutivos suman; repetir el mismo día no")
    func consecutivos() {
        var r = EstadoRacha()
        do { let v = r.registrarRonda(hoy: dia(11, 10)); #expect(v.incrementada) }
        do { let v = r.registrarRonda(hoy: dia(11, 10)); #expect(!v.incrementada) }
        r.registrarRonda(hoy: dia(11, 11))
        let c = r.registrarRonda(hoy: dia(11, 12))
        #expect(r.actual == 3 && r.record == 3 && c.nuevoRecord && r.protectores == 2)
    }

    @Test("Un día saltado consume un protector y la racha sigue")
    func protector() {
        var r = EstadoRacha()
        r.registrarRonda(hoy: dia(11, 10))
        let c = r.registrarRonda(hoy: dia(11, 12))
        #expect(c.protectoresUsados == 1 && c.rachaPerdida == nil && r.actual == 2 && r.protectores == 1)
    }

    @Test("Sin protectores suficientes la racha se rompe y se conserva el récord")
    func ruptura() {
        var r = EstadoRacha()
        for d in 10...14 { r.registrarRonda(hoy: dia(11, d)) }
        // Salta del 15 al 18 (4 días): 2 protectores no bastan.
        let c = r.registrarRonda(hoy: dia(11, 19))
        #expect(c.protectoresUsados == 2 && c.rachaPerdida == 5)
        #expect(r.actual == 1 && r.record == 5 && r.protectores == 0)
    }

    @Test("Protectores: se reponen el día 1 aunque caiga en mitad de un hueco")
    func reposicionMensual() {
        var r = EstadoRacha(actual: 4, record: 4, protectores: 0, ultimoDiaActivo: dia(1, 31), ultimoDiaProcesado: dia(1, 30))
        let c = r.registrarRonda(hoy: dia(2, 2))
        #expect(c.protectoresUsados == 1 && c.rachaPerdida == nil)
        #expect(r.actual == 5 && r.protectores == 1, "El 1 de febrero repone a 2 y consume 1")
        // La reposición rellena hasta 2, no suma.
        var s = EstadoRacha(actual: 1, protectores: 3, ultimoDiaActivo: dia(2, 28), ultimoDiaProcesado: dia(2, 27))
        s.registrarRonda(hoy: dia(3, 1))
        #expect(s.protectores == 3)
    }

    @Test("Semana completa: +1 protector, con un máximo de 3")
    func semanaCompleta() {
        var r = EstadoRacha()
        var ganados = 0
        for d in 2...15 { if r.registrarRonda(hoy: dia(11, d)).protectorGanado { ganados += 1 } }
        #expect(r.actual == 14 && ganados == 1 && r.protectores == 3)
    }

    @Test("Medianoche: 23:59 y 00:01 son días distintos")
    func medianoche() {
        let cal = Fx.madrid
        var r = EstadoRacha()
        r.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 5, 10, 23, 59), calendario: cal))
        r.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 5, 11, 0, 1), calendario: cal))
        #expect(r.actual == 2 && r.protectores == 2)
    }

    @Test("Zona horaria: viajar al oeste no rompe ni duplica la racha")
    func zonaHoraria() {
        var r = EstadoRacha()
        r.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 5, 11, 1, 0), calendario: Fx.madrid))
        // Mismo instante + 1 h, ya en Nueva York: allí todavía es día 10.
        let c = r.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 5, 11, 2, 0), calendario: Fx.calendario("America/New_York")))
        #expect(!c.incrementada && r.actual == 1)
        r.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 5, 12, 20, 0), calendario: Fx.calendario("America/New_York")))
        #expect(r.actual == 2 && r.protectores == 2)
    }

    @Test("Cambio de horario de verano: no se pierde ni se gana ningún día")
    func horarioDeVerano() {
        let cal = Fx.madrid
        var r = EstadoRacha()
        // Rondas a las 00:30 locales alrededor del 29/03/2026 y del 25/10/2026.
        for d in 27...31 { r.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 3, d, 0, 30), calendario: cal)) }
        #expect(r.actual == 5 && r.protectores == 2)
        var s = EstadoRacha()
        for d in 24...26 { s.registrarRonda(hoy: DiaCivil(Fx.fecha(2026, 10, d, 23, 30), calendario: cal)) }
        #expect(s.actual == 3 && s.protectores == 2)
    }

    @Test("Muchos días saltados: se rompe, y el resultado no depende de cuántas veces se consulte")
    func diasSaltados() {
        var a = EstadoRacha()
        a.registrarRonda(hoy: dia(10, 1))
        var b = a
        let c = a.registrarRonda(hoy: dia(12, 20))
        #expect(c.rachaPerdida == 1 && a.actual == 1 && a.protectores == 2, "Rota; el 1 de nov. y de dic. reponen a 2")
        // Consultando cada día por el camino se llega al mismo estado.
        var d = dia(10, 2)
        while d < dia(12, 20) { b.avanzar(hasta: d); d = d.sumando(dias: 1) }
        b.registrarRonda(hoy: dia(12, 20))
        #expect(a == b)
        #expect(a.vigente(hoy: dia(12, 20)) == a)
        #expect(EstadoRacha().vigente(hoy: dia(1, 1)).actual == 0)
    }

    @Test("Fecha anterior a la última actividad: no cambia nada")
    func fechaAnterior() {
        var r = EstadoRacha()
        r.registrarRonda(hoy: dia(5, 10))
        let antes = r
        do { let v = r.registrarRonda(hoy: dia(5, 8)); #expect(!v.incrementada) }
        #expect(r.actual == antes.actual && r.ultimoDiaActivo == antes.ultimoDiaActivo)
    }
}

@Suite("Logros")
struct LogrosTests {
    @Test("Motor de reglas: 5 logros de ejemplo y 6 de la Fase 05D")
    func motor() {
        let motor = MotorLogros()
        #expect(motor.logros.count == 11 && Set(motor.logros.map(\.id)).count == 11)
        #expect(motor.nuevos(metricas: [:], obtenidos: []).isEmpty)
        let m: [Metrica: Int] = [.rondasCompletadas: 1, .rescates: 10, .rachaRecord: 7, .sintaxisPerfectas: 1, .competenciasDominadas: 1]
        #expect(motor.nuevos(metricas: m, obtenidos: []).map(\.id) == ["primera-ronda", "sintaxis-perfecta", "rescatador", "semana-de-fuego"])
        #expect(motor.nuevos(metricas: m, obtenidos: ["primera-ronda", "rescatador"]).map(\.id) == ["sintaxis-perfecta", "semana-de-fuego"])
        var todas = m
        todas[.simulacrosAprobados] = 1
        #expect(motor.nuevos(metricas: todas, obtenidos: []).last?.id == "listo-para-examen")
    }

    @Test("Condiciones compuestas")
    func condiciones() {
        let c = CondicionLogro.alguna([.alMenos(.rescates, 3), .todas([.alMenos(.rondasCompletadas, 2), .alMenos(.aciertosTotales, 5)])])
        #expect(!c.cumple([:]))
        #expect(c.cumple([.rescates: 3]))
        #expect(!c.cumple([.rondasCompletadas: 2]))
        #expect(c.cumple([.rondasCompletadas: 2, .aciertosTotales: 5]))
        let propio = MotorLogros(logros: [Logro(id: "d", titulo: "D", descripcion: "", condicion: .alMenos(.diagnosticosCompletados, 1))])
        #expect(propio.nuevos(metricas: [.diagnosticosCompletados: 1], obtenidos: []).count == 1)
    }
}
