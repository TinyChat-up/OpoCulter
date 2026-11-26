import Foundation
import Testing
@testable import Educulter

// Fase 05E parte 2, §5: ejemplos resueltos (pasos con porqué en los generadores).

@Suite("Fase 05E parte 2 · Pasos de los ejemplos resueltos")
struct PasosResueltosTests {
    static let banco = try! CargadorContenido.desdeBundle().cargar(politica: .soloAprobados, semillaBase: 3)

    /// Plantillas con pasos: todas las aprobadas de Matemáticas y `oracionSimple` salvo las de clases
    /// de palabras (que no se resuelven con la estructura de la oración).
    static var conPasos: [Plantilla] {
        banco.plantillas.filter { p in
            Catalogo.area(de: p.competencia) == "MAT" || (p.tipo == "oracionSimple" && GeneradorOracionSimple.modo(p) != "clases")
        }
    }

    /// El último resultado intermedio es la solución: el mismo valor en las numéricas; en las demás,
    /// la solución tal como la describe la app.
    static func coincide(_ paso: PasoResuelto, _ item: Item) -> Bool {
        if case .numerico(let n) = item.payload {
            guard let a = Racional.interpretar(paso.valor), let b = Racional.interpretar(n.respuesta) else { return false }
            return a.valor == b.valor
        }
        return paso.valor == DescripcionSolucion.texto(item.payload)
    }

    @Test("1000 semillas por plantilla: 2–5 pasos, frases ≤ 60, porqué ≤ 70 en al menos un paso y el último es la solución")
    func coherencia() throws {
        let plantillas = Self.conPasos
        #expect(Set(plantillas.filter { Catalogo.area(de: $0.competencia) == "MAT" }.map(\.tipo)).count >= 15, "\(Set(plantillas.map(\.tipo)))")
        var fallos: [String] = []
        for p in plantillas {
            for semilla in UInt64(0)..<1000 {
                guard let item = try? MotorGeneradores.generar(p, semilla: semilla, recursos: Self.banco.recursos) else { fallos.append("\(p.id)#\(semilla): no genera"); continue }
                let pasos = item.pasos
                if !PasoResuelto.rangoPasos.contains(pasos.count) { fallos.append("\(item.id): \(pasos.count) pasos"); continue }
                if let f = pasos.first(where: { $0.frase.count > PasoResuelto.maxFrase }) { fallos.append("\(item.id): frase larga «\(f.frase)»") }
                if let f = pasos.first(where: { ($0.porque?.count ?? 0) > PasoResuelto.maxPorque }) { fallos.append("\(item.id): porqué largo «\(f.porque!)»") }
                if !pasos.contains(where: { $0.porque != nil }) { fallos.append("\(item.id): sin porqué") }
                if pasos.contains(where: { $0.frase.isEmpty || $0.resultado.isEmpty || $0.valor.isEmpty }) { fallos.append("\(item.id): paso vacío") }
                if !Self.coincide(pasos.last!, item) { fallos.append("\(item.id): último paso «\(pasos.last!.valor)» ≠ \(DescripcionSolucion.texto(item.payload))") }
                // Las explicaciones de Matemáticas incluyen la frase de porqué.
                if Catalogo.area(de: p.competencia) == "MAT", !item.explicacion.localizedCaseInsensitiveContains("porque") {
                    fallos.append("\(item.id): explicación sin porqué")
                }
            }
        }
        #expect(fallos.isEmpty, "\(fallos.count) fallos: \(fallos.prefix(10))")
    }

    @Test("Los pasos son deterministas y viajan con el ítem (también al reproducirlo desde su id)")
    func determinismo() throws {
        for p in Self.conPasos.prefix(12) {
            let a = try MotorGeneradores.generar(p, semilla: 77, recursos: Self.banco.recursos)
            let b = try #require(Self.banco.item(id: a.id))
            #expect(a.pasos == b.pasos && !a.pasos.isEmpty, "\(p.id)")
        }
        // Los estáticos no tienen pasos y el JSON sin el campo se sigue leyendo.
        #expect(Self.banco.itemsEstaticos.allSatisfy { $0.pasos.isEmpty })
        let item = try MotorGeneradores.generar(Self.conPasos[0], semilla: 1, recursos: Self.banco.recursos)
        let copia = try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(item))
        #expect(copia.pasos == item.pasos)
    }

    /// Muestra de 20 ítems de la auditoría de la parte 1 (`docs/AUDITORIA_05E.md`, semilla 2026). En la
    /// parte 1, 8 de 20 explicaban el porqué. Los de Matemáticas llevan ahora la frase de porqué; los de
    /// Lengua no cambian (4 ya lo daban y 2 no: autor ↔ obra y formas no personales).
    @Test("Muestra de 20 ítems de la auditoría: ≥ 80 % con porqué")
    func muestraAuditoria() throws {
        let matematicas = ["MAT.NUM.ORDEN.G02#1", "MAT.NUM.FRAOP.G01#0", "MAT.POR.CALC.G02#17", "MAT.OPE.ECUAC.G01#2", "MAT.OPE.ECUAC.G03#4",
                           "MAT.NUM.FRAPROB.G02#11", "MAT.UNI.TIEM.G01#16", "MAT.OPE.JER.G02#4", "MAT.NUM.FRAPROB.G01#13", "MAT.ROM.ESCR.G02#8",
                           "MAT.UNI.TIEM.G01#2", "MAT.UNI.VOL.G01#5", "MAT.UNI.LMC.G02#10", "MAT.UNI.VOL.G01#15"]
        let lenguaConPorque = ["LEN.LIT.UNIV.G02#15", "LEN.SIN.COMPL.G03#6", "LEN.ORT.AGU.G04#9", "LEN.VER.ANALISIS.G04#13"]
        let lenguaSin = ["LEN.LIT.UNIV.G01#2", "LEN.VER.NOPERS.G05#17"]
        #expect(matematicas.count + lenguaConPorque.count + lenguaSin.count == 20)
        var conPorque = lenguaConPorque.count
        for id in matematicas {
            let item = try #require(Self.banco.item(id: id), "\(id)")
            if item.explicacion.localizedCaseInsensitiveContains("porque") && item.pasos.contains(where: { $0.porque != nil }) { conPorque += 1 }
        }
        #expect(Double(conPorque) / 20 >= 0.8, "\(conPorque) de 20")
        #expect(conPorque == 18)
    }
}
