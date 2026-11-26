import Foundation
import Testing
import UIKit
@testable import Educulter

// Fase 05E, parte 2: ajustes 1b (plan, catálogo perezoso, tarjetas del ANEXO B) y lo que sigue.

@Suite("Fase 05E parte 2 · Ajustes 1b")
struct Ajustes1bTests {
    static let release = try! CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)

    @Test("Plan: prioridad × debilidad del diagnóstico × preguntas oficiales; Mixto alterna áreas (diagnóstico sintético)")
    func plan() {
        let banco = Self.release
        #expect(banco.preguntasOficiales.values.reduce(0, +) == 139)
        let diagnostico = ResultadoDiagnostico(fecha: Date(timeIntervalSince1970: 0), niveles: [
            NivelBloque(bloqueId: "LEN.LIT", nivel: 0.9, respondidos: 2, aciertos: 2),
            NivelBloque(bloqueId: "MAT.NUM", nivel: 0.1, respondidos: 2, aciertos: 0),
            NivelBloque(bloqueId: "LEN.SIN", nivel: 0.0, respondidos: 2, aciertos: 0),
        ], plan: [])
        let plan = PlanEstudio(banco: banco, diagnostico: diagnostico)
        // Puntuación calculada aquí a mano para tres competencias.
        let q = { (c: String) in Double(banco.preguntasOficiales[c] ?? 0) }
        #expect(abs(plan.puntuacion("LEN.LIT.HIST") - 3 * 0.1 * q("LEN.LIT.HIST")) < 1e-9)
        #expect(abs(plan.puntuacion("MAT.NUM.ORDEN") - 3 * 0.9 * q("MAT.NUM.ORDEN")) < 1e-9)
        #expect(abs(plan.puntuacion("LEN.SIN.COMPL") - 3 * 1.0 * q("LEN.SIN.COMPL")) < 1e-9)
        let orden = plan.ordenadas()
        #expect(orden.first == "LEN.SIN.COMPL", "\(orden.prefix(5))")
        #expect(orden.firstIndex(of: "MAT.NUM.ORDEN")! < orden.firstIndex(of: "LEN.LIT.HIST")!, "LIT fuerte baja; NUM débil sube")
        // Ordenado de mayor a menor puntuación.
        let p = orden.map(plan.puntuacion)
        #expect(zip(p, p.dropFirst()).allSatisfy { $0 >= $1 })
        // Mixto: se alternan áreas mientras quedan de las dos.
        let mixto = plan.mixto(orden.filter { banco.tieneItems(competencia: $0) })
        let areas = mixto.prefix(10).map { Catalogo.area(de: $0) }
        #expect(zip(areas, areas.dropFirst()).allSatisfy { $0 != $1 }, "\(areas)")
        // Sin diagnóstico, debilidad 0,5 para todos: manda la frecuencia en el examen.
        let sinDatos = PlanEstudio(banco: banco).ordenadas()
        #expect(sinDatos.first == "LEN.LIT.HIST", "\(sinDatos.prefix(3))")
    }

    @Test("Catálogo perezoso: al cargar no se genera ninguna variante; al pedir una competencia, solo las suyas")
    func perezoso() throws {
        let banco = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados, semillaBase: 7)
        #expect(banco.plantillasGeneradas == 0)
        #expect(banco.tieneItems(competencia: "LEN.SIN.SUJPRED") && banco.plantillasGeneradas == 0)
        let sujpred = banco.items(competencia: "LEN.SIN.SUJPRED")
        #expect(!sujpred.isEmpty && banco.plantillasGeneradas == banco.plantillas.filter { $0.competencia == "LEN.SIN.SUJPRED" }.count)
        // Mismo orden y mismos ítems que generando todo.
        let todos = banco.items
        #expect(banco.plantillasGeneradas == banco.plantillas.count)
        #expect(todos.filter { $0.competencia == "LEN.SIN.SUJPRED" } == sujpred)
        #expect(Array(todos.prefix(banco.numeroEstaticos)) == Array(banco.itemsEstaticos))
    }

    @Test("Las 9 tarjetas del ANEXO B, aprobadas y válidas; SUJPRED, ANALISIS y NOPERS pasan a completas")
    func tarjetas() {
        let banco = Self.release
        let ids = ["LEN.SIN.SUJPRED.T02", "LEN.SIN.COMPL.T01", "LEN.SIN.CLASE.T01", "LEN.VER.ANALISIS.T01", "LEN.VER.NOPERS.T01",
                   "LEN.LIT.GEN.T01", "LEN.LIT.HIST.T01", "LEN.LIT.UNIV.T01", "LEN.LIT.INF.T01"]
        let competencias = Set(banco.catalogo.todasLasCompetencias.map(\.id))
        for id in ids {
            let t = banco.teoria.first { $0.id == id }
            #expect(t?.validacion == Validacion(estado: .aprobado, revisor: "direccion", fecha: "2026-11-25"), "\(id)")
            if let t { #expect(ValidadorContenido(anioActual: 2026).validar(tarjeta: t, competencias: competencias).isEmpty, "\(id)") }
        }
        #expect(banco.teoria.first { $0.id == "LEN.SIN.SUJPRED.T02" }?.bloques.map(\.tipo) == [.regla, .truco, .esquema, .texto])
        for c in ["LEN.SIN.SUJPRED", "LEN.VER.ANALISIS", "LEN.VER.NOPERS"] {
            let items = banco.items(competencia: c) + banco.plantillas.filter { $0.competencia == c }.map { MotorGeneradores.ajustada($0, dificultad: $0.dificultad) }.compactMap { try? MotorGeneradores.generar($0, semilla: 0, recursos: banco.recursos) }
            #expect(Set(items.map(\.peldano)) == [1, 2, 3, 4, 5] && Set(items.map(\.dificultad)).count >= 3 && !banco.teoria(competencia: c).isEmpty, "\(c)")
        }
    }
}

@Suite("Fase 05E parte 2 · Paleta editorial y contraste WCAG")
struct PaletaTests {
    /// Luminancia relativa WCAG de un color del catálogo en el modo indicado.
    static func luminancia(_ nombre: String, oscuro: Bool) -> Double {
        let rasgos = UITraitCollection(userInterfaceStyle: oscuro ? .dark : .light)
        let c = UIColor(named: nombre, in: .main, compatibleWith: rasgos)!.resolvedColor(with: rasgos)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        func f(_ x: CGFloat) -> Double { let v = Double(x); return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
    }

    static func contraste(_ a: String, _ b: String, oscuro: Bool) -> Double {
        let la = luminancia(a, oscuro: oscuro), lb = luminancia(b, oscuro: oscuro)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// Pares texto/fondo que usa la app (texto normal: 4,5:1).
    static let pares: [(String, [String])] = [
        ("TextoPrincipal", ["Fondo", "Superficie", "LenguaTinte", "MatematicasTinte"]),
        ("TextoSecundario", ["Fondo", "Superficie", "LenguaTinte", "MatematicasTinte"]),
        ("LenguaTinta", ["Fondo", "Superficie", "LenguaTinte"]),
        ("MatematicasTinta", ["Fondo", "Superficie", "MatematicasTinte"]),
        ("RecompensaTexto", ["Fondo", "Superficie"]),
        ("Exito", ["Fondo", "Superficie", "LenguaTinte", "MatematicasTinte"]),
        ("Fallo", ["Fondo", "Superficie", "LenguaTinte", "MatematicasTinte"]),
        ("TextoSobreAcento", ["Lengua"]),
        ("TextoSobreBosque", ["Matematicas", "ExitoRelleno"]),
        ("TextoSobreRecompensa", ["Recompensa"]),
    ]

    @Test("Todos los pares texto/fondo usados tienen contraste ≥ 4,5:1 en claro y en oscuro", arguments: [false, true])
    func contraste(_ oscuro: Bool) {
        for (texto, fondos) in Self.pares {
            for fondo in fondos {
                let c = Self.contraste(texto, fondo, oscuro: oscuro)
                #expect(c >= 4.5, "\(texto) sobre \(fondo) (\(oscuro ? "oscuro" : "claro")): \(String(format: "%.2f", c))")
            }
        }
        // Marca e iconos en tinta, y los rellenos de los botones primarios (componentes gráficos): ≥ 3:1.
        #expect(Self.contraste("Tinta", "Fondo", oscuro: oscuro) >= 3)
        #expect(Self.contraste("Matematicas", "Fondo", oscuro: oscuro) >= 3)
    }

    @Test("Tokens de la identidad editorial (tabla de la dirección del 26/11/2026)")
    func tokens() {
        func hex(_ n: String, _ oscuro: Bool) -> String {
            let rasgos = UITraitCollection(userInterfaceStyle: oscuro ? .dark : .light)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(named: n, in: .main, compatibleWith: rasgos)!.resolvedColor(with: rasgos).getRed(&r, green: &g, blue: &b, alpha: &a)
            return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
        }
        let tabla: [(String, String, String)] = [
            ("Tinta", "#16241F", "#E7F0E0"), ("Fondo", "#F4F8F0", "#142019"), ("Superficie", "#E7F0E0", "#1E302A"),
            ("Lengua", "#A9BD9F", "#8FA685"), ("Matematicas", "#2F4A40", "#A9BD9F"), ("Recompensa", "#C98A2E", "#E0A84F"),
            ("ExitoRelleno", "#3F7A55", "#7FBF93"),
        ]
        for (n, claro, oscuro) in tabla { #expect(hex(n, false) == claro && hex(n, true) == oscuro, "\(n)") }
        // Los colores con nombre se comparan por nombre: `textoSobre` elige bien el texto de cada relleno.
        #expect(Paleta.textoSobre(Paleta.matematicas) == Paleta.textoSobreBosque)
        #expect(Paleta.textoSobre(Paleta.exitoRelleno) == Paleta.textoSobreBosque)
        #expect(Paleta.textoSobre(Paleta.lengua) == Paleta.textoSobreAcento)
        #expect(Paleta.textoSobre(Paleta.recompensa) == Paleta.textoSobreAcento)
    }
}
