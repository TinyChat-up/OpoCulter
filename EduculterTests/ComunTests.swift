import Foundation
import Testing
@testable import Educulter

@Suite("Día civil")
struct DiaCivilTests {
    @Test("Clave AAAAMMDD y descripción")
    func clave() {
        let d = Fx.dia(2026, 3, 9)
        #expect(d.clave == 20260309)
        #expect(DiaCivil(clave: 20260309) == d)
        #expect(DiaCivil(clave: 20261301) == nil)
        #expect(DiaCivil(clave: 20260100) == nil)
        #expect(d.description == "2026-03-09")
    }

    @Test("Aritmética entre meses, años y bisiestos")
    func aritmetica() {
        #expect(Fx.dia(2026, 1, 31).sumando(dias: 1) == Fx.dia(2026, 2, 1))
        #expect(Fx.dia(2028, 2, 28).sumando(dias: 1) == Fx.dia(2028, 2, 29))
        #expect(Fx.dia(2026, 12, 31).sumando(dias: 1) == Fx.dia(2027, 1, 1))
        #expect(Fx.dia(2026, 3, 1).sumando(dias: -1) == Fx.dia(2026, 2, 28))
        #expect(Fx.dia(2026, 1, 1).dias(hasta: Fx.dia(2027, 1, 1)) == 365)
        #expect(Fx.dia(2026, 3, 30).dias(hasta: Fx.dia(2026, 3, 28)) == -2)
        #expect(Fx.dia(2026, 1, 1) < Fx.dia(2026, 1, 2))
    }

    @Test("Medianoche y zona horaria del usuario")
    func zonaHoraria() {
        let madrid = Fx.madrid, nuevaYork = Fx.calendario("America/New_York")
        #expect(DiaCivil(Fx.fecha(2026, 5, 10, 23, 59), calendario: madrid) == Fx.dia(2026, 5, 10))
        #expect(DiaCivil(Fx.fecha(2026, 5, 11, 0, 1), calendario: madrid) == Fx.dia(2026, 5, 11))
        // El mismo instante es día 11 en Madrid y día 10 en Nueva York.
        let instante = Fx.fecha(2026, 5, 11, 2, 0)
        #expect(DiaCivil(instante, calendario: madrid) == Fx.dia(2026, 5, 11))
        #expect(DiaCivil(instante, calendario: nuevaYork) == Fx.dia(2026, 5, 10))
    }

    @Test("Cambio de horario de verano: los días siguen siendo consecutivos")
    func horarioDeVerano() throws {
        let madrid = Fx.madrid
        // 29/03/2026: en Madrid se pasa de 2:00 a 3:00 (día de 23 h).
        let inicio = try #require(Fx.dia(2026, 3, 29).inicio(en: madrid))
        let siguiente = try #require(Fx.dia(2026, 3, 30).inicio(en: madrid))
        #expect(siguiente.timeIntervalSince(inicio) == 23 * 3600)
        #expect(DiaCivil(inicio.addingTimeInterval(23 * 3600 - 1), calendario: madrid) == Fx.dia(2026, 3, 29))
        // 25/10/2026: día de 25 h.
        let otono = try #require(Fx.dia(2026, 10, 25).inicio(en: madrid))
        #expect(DiaCivil(otono.addingTimeInterval(24.5 * 3600), calendario: madrid) == Fx.dia(2026, 10, 25))
        #expect(Fx.dia(2026, 3, 28).dias(hasta: Fx.dia(2026, 3, 30)) == 2)
    }

    @Test("Con un calendario no gregoriano se usa igualmente el gregoriano")
    func calendarioNoGregoriano() {
        var budista = Calendar(identifier: .buddhist)
        budista.timeZone = TimeZone(identifier: "Europe/Madrid")!
        #expect(DiaCivil(Fx.fecha(2026, 7, 1), calendario: budista) == Fx.dia(2026, 7, 1))
    }
}

@Suite("Números racionales")
struct RacionalTests {
    @Test("Interpretación de entero, decimal con coma y fracción")
    func interpretar() throws {
        let entero = try #require(Racional.interpretar(" -12 "))
        #expect(entero.valor == Racional(numerador: -12, denominador: 1) && entero.formato == .entero)
        let decimal = try #require(Racional.interpretar("573,75"))
        #expect(decimal.valor == Racional(numerador: 2295, denominador: 4) && decimal.formato == .decimal)
        let negativo = try #require(Racional.interpretar("-0,5"))
        #expect(negativo.valor == Racional(numerador: -1, denominador: 2))
        let fraccion = try #require(Racional.interpretar("6/8"))
        #expect(fraccion.valor == Racional(numerador: 3, denominador: 4) && !fraccion.irreducible)
        #expect(Racional.interpretar("-3/4")?.irreducible == true)
        #expect(Racional.interpretar("3/4")?.valor.description == "3/4")
        #expect(Racional.interpretar("8/4")?.valor.description == "2")
        #expect(Racional.interpretar("1/3")?.valor.valorDouble ?? 0 > 0.333)
    }

    @Test("Textos no válidos")
    func noValidos() {
        for texto in ["", "abc", "1.5", "1,", ",5", "1/0", "1/-2", "1/2/3", "--1", "1,2,3", "12345678901234567", "1,1234567890"] {
            #expect(Racional.interpretar(texto) == nil, "«\(texto)» no debería interpretarse")
        }
        #expect(Racional(numerador: 1, denominador: 0) == nil)
        #expect(Racional(numerador: 2, denominador: -4)?.description == "-1/2")
        #expect(Racional(numerador: Int.min, denominador: -1) == nil)
    }
}

@Suite("Reloj y aleatoriedad inyectables")
struct RelojTests {
    @Test("El generador con semilla es reproducible")
    func semilla() {
        var a = GeneradorConSemilla(semilla: 42), b = GeneradorConSemilla(semilla: 42)
        #expect((0..<5).map { _ in a.next() } == (0..<5).map { _ in b.next() })
        var c = GeneradorConSemilla.aleatorio()
        _ = c.next()
    }

    @Test("Relojes")
    func relojes() {
        let f = Fx.fecha(2026, 1, 1)
        #expect(RelojFijo(ahora: f).ahora == f)
        #expect(abs(RelojSistema().ahora.timeIntervalSinceNow) < 5)
    }
}
