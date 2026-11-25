import Foundation
import Testing
@testable import Educulter

// Fase 05E, §3: calibración «nivel examen». Por cada ancla reproducible de
// `Content/calibracion/anclas.json`, 1000 semillas en el nivel 4 dan ítems con el mismo perfil
// estructural que la pregunta oficial (mismos pasos y mismo tipo de números). El perfil se mide aquí,
// sobre los datos y el payload del ítem, sin usar el código del generador.

struct Ancla: Decodable, Sendable, CustomTestStringConvertible {
    struct Comprobacion: Decodable, Sendable {
        var generador: String
        var operaciones: Int?
        var profundidad: Int?
        var maximoNumero: Int?
        var soloNaturales: Bool?
        var cantidad: Int?
        var mezcla: Bool?
        var maximoDecimales: Int?
        var maximoDenominador: Int?
        var fracciones: Int?
        var sobreLoQueQueda: Bool?
        var tiempos: Int?
        var sinNormalizar: Bool?
        var terminos: Int?
        var destinoIntermedio: Bool?
        var modo: String?
        var maximaEscala: Int?
        var porcentajeNoRedondo: Bool?
        var base: [Int]?
        var factorNoEntero: Bool?
        var maximoDato: Int?
        var rango: [Int]?
        var sustractivos: Int?
        var numeros: [Int]?
        var experimento: String?
        var datos: [Int]?
        var maximoValor: Int?
        var separacion: [Int]?
        var opciones: [Int]?
        var ambito: String?

        private enum CodingKeys: String, CodingKey {
            case generador, operaciones, profundidad, maximoNumero, soloNaturales, cantidad, mezcla, maximoDecimales, maximoDenominador,
                 fracciones, sobreLoQueQueda, tiempos, sinNormalizar, terminos, destinoIntermedio, modo, maximaEscala, porcentajeNoRedondo,
                 base, factorNoEntero, maximoDato, rango, sustractivos, numeros, experimento, datos, maximoValor, separacion, opciones, ambito
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            generador = try c.decode(String.self, forKey: .generador)
            operaciones = try? c.decode(Int.self, forKey: .operaciones)
            profundidad = try? c.decode(Int.self, forKey: .profundidad)
            maximoNumero = try? c.decode(Int.self, forKey: .maximoNumero)
            soloNaturales = try? c.decode(Bool.self, forKey: .soloNaturales)
            cantidad = try? c.decode(Int.self, forKey: .cantidad)
            mezcla = try? c.decode(Bool.self, forKey: .mezcla)
            maximoDecimales = try? c.decode(Int.self, forKey: .maximoDecimales)
            maximoDenominador = try? c.decode(Int.self, forKey: .maximoDenominador)
            // `fracciones` es un número (problemaFraccion) o un rango [min, max] (fraccionesOperar).
            if let n = try? c.decode(Int.self, forKey: .fracciones) { fracciones = n; numeros = nil }
            else if let r = try? c.decode([Int].self, forKey: .fracciones) { fracciones = nil; numeros = r }
            sobreLoQueQueda = try? c.decode(Bool.self, forKey: .sobreLoQueQueda)
            if let t = try? c.decode(Int.self, forKey: .tiempos) { tiempos = t }
            sinNormalizar = try? c.decode(Bool.self, forKey: .sinNormalizar)
            terminos = try? c.decode(Int.self, forKey: .terminos)
            destinoIntermedio = try? c.decode(Bool.self, forKey: .destinoIntermedio)
            modo = try? c.decode(String.self, forKey: .modo)
            maximaEscala = try? c.decode(Int.self, forKey: .maximaEscala)
            porcentajeNoRedondo = try? c.decode(Bool.self, forKey: .porcentajeNoRedondo)
            base = try? c.decode([Int].self, forKey: .base)
            factorNoEntero = try? c.decode(Bool.self, forKey: .factorNoEntero)
            maximoDato = try? c.decode(Int.self, forKey: .maximoDato)
            rango = try? c.decode([Int].self, forKey: .rango)
            sustractivos = try? c.decode(Int.self, forKey: .sustractivos)
            if numeros == nil { numeros = try? c.decode([Int].self, forKey: .numeros) }
            experimento = try? c.decode(String.self, forKey: .experimento)
            datos = try? c.decode([Int].self, forKey: .datos)
            maximoValor = try? c.decode(Int.self, forKey: .maximoValor)
            separacion = try? c.decode([Int].self, forKey: .separacion)
            opciones = try? c.decode([Int].self, forKey: .opciones)
            ambito = try? c.decode(String.self, forKey: .ambito)
        }
    }
    var pregunta: String
    var competencia: String
    var plantilla: String
    var nivelQueLaReproduce: Int?
    var reproducible: Bool
    var comprobacion: Comprobacion?
    var nota: String

    var testDescription: String { "\(pregunta) → \(plantilla)" }

    static let todas: [Ancla] = {
        struct Archivo: Decodable { var anclas: [Ancla] }
        let url = Bundle.main.url(forResource: "Content", withExtension: nil)!.appendingPathComponent("calibracion/anclas.json")
        return (try? JSONDecoder().decode(Archivo.self, from: Data(contentsOf: url)).anclas) ?? []
    }()
}

enum PerfilEstructural {
    /// Enteros que aparecen en un texto.
    static func enteros(_ t: String) -> [Int] {
        var out: [Int] = [], actual = ""
        for c in t + " " {
            if c.isASCII && c.isNumber { actual.append(c) } else if !actual.isEmpty { out.append(Int(actual)!); actual = "" }
        }
        return out
    }

    static func profundidad(_ t: String) -> Int {
        var p = 0, m = 0
        for c in t {
            if "([{".contains(c) { p += 1; m = max(m, p) } else if ")]}".contains(c) { p -= 1 }
        }
        return m
    }

    static func sustractivos(_ n: Int) -> Int { [n % 10, n / 10 % 10, n / 100 % 10].filter { $0 == 4 || $0 == 9 }.count }

    /// Fallos del perfil de una muestra frente a la comprobación del ancla.
    static func comprobar(_ c: Ancla.Comprobacion, _ m: Muestra, _ item: Item) -> [String] {
        let d = m.datos
        var f: [String] = []
        switch c.generador {
        case "operacionesCombinadas":
            let e = d["expresion"]!
            let ops = e.filter { "+−×:".contains($0) }.count
            if ops != c.operaciones { f.append("\(e): \(ops) operaciones") }
            if let p = c.profundidad, profundidad(e) != p { f.append("\(e): profundidad \(profundidad(e))") }
            if c.soloNaturales == true && (e.contains("/") || e.contains(",") || e.contains("²") || e.contains("³")) { f.append("\(e): no son naturales") }
            if let mx = c.maximoNumero, enteros(e).contains(where: { $0 > mx }) { f.append("\(e): número de más de 2 cifras") }
        case "ordenarNumeros":
            guard case .ordenar(let o) = item.payload else { return ["payload"] }
            let t = o.fichas.map(\.texto)
            if t.count != c.cantidad { f.append("\(t.count) números") }
            if c.mezcla == true && !(t.contains { $0.contains("/") } && t.contains { $0.contains(",") }) { f.append("sin mezcla: \(t)") }
            for x in t where x.contains(",") && x.split(separator: ",")[1].count > (c.maximoDecimales ?? 9) { f.append("decimales: \(x)") }
            for x in t where x.contains("/") && Int(x.split(separator: "/")[1])! > (c.maximoDenominador ?? 99) { f.append("denominador: \(x)") }
        case "fraccionesOperar":
            let e = d["expresion"]!
            let fr = e.split(separator: " ").filter { $0.contains("/") }
            if let r = c.numeros, !(r[0]...r[1]).contains(fr.count) { f.append("\(e): \(fr.count) fracciones") }
            if e.contains("×") || e.contains(":") || e.contains("(") { f.append("\(e): operación o agrupación fuera del perfil") }
            let dens = fr.map { Int($0.split(separator: "/")[1])! }
            if dens.contains(where: { $0 > (c.maximoDenominador ?? 99) }) || Set(dens).count < 2 { f.append("\(e): denominadores") }
        case "problemaFraccion":
            if d["fracciones"]!.split(separator: ";").count != c.fracciones { f.append("fracciones: \(d["fracciones"]!)") }
            if (d["resto"] == "1") != (c.sobreLoQueQueda ?? false) { f.append("no es sobre lo que queda") }
        case "sexagesimal":
            let partes = (d["partes"] ?? "").split(separator: ";").map { $0.split(separator: ":").map { Int($0)! } }
            if d["op"] != "sumaN" || partes.count != c.tiempos { f.append("op \(d["op"]!) con \(partes.count) tiempos") }
            if c.sinNormalizar == true && !partes.contains(where: { $0[1] >= 60 || $0[2] >= 60 }) { f.append("todos normalizados: \(d["partes"]!)") }
        case "conversionUnidades":
            let t = d["terminos"]!.split(separator: ";").map { $0.split(separator: ":").map(String.init) }
            if t.count != c.terminos { f.append("\(t.count) términos") }
            if c.destinoIntermedio == true, let a = Oraculo.factores[t.first![1]]?.1, let b = Oraculo.factores[t.last![1]]?.1, let x = Oraculo.factores[d["hasta"]!]?.1,
               !(x < a && x > b) { f.append("destino \(d["hasta"]!) no intermedio: \(d["terminos"]!)") }
        case "escala":
            if d["modo"] != c.modo { f.append("modo \(d["modo"]!)") }
            if let e = Int(d["e"]!), e > (c.maximaEscala ?? .max) { f.append("escala 1:\(e)") }
            if d["unidadPlano"] != "mm" && !d["d"]!.contains(",") { f.append("medida entera en cm: \(d["d"]!)") }
        case "porcentajeDe":
            let p = d["p"]!
            if c.porcentajeNoRedondo == true && ["5", "10", "20", "25", "50"].contains(p) { f.append("porcentaje redondo: \(p)") }
            if let b = c.base, let base = Int(d["base"]!), !(b[0]...b[1]).contains(base) { f.append("base \(base)") }
            if case .numerico(let n) = item.payload, n.respuesta.contains(","), n.respuesta.split(separator: ",")[1].count > (c.maximoDecimales ?? 2) { f.append("decimales \(n.respuesta)") }
        case "reglaDeTres":
            let a1 = Int(d["a1"]!)!, a2 = Int(d["a2"]!)!
            if c.factorNoEntero == true && a2 % a1 == 0 { f.append("factor entero \(a2)/\(a1)") }
            if let mx = c.maximoDato, (Oraculo.racional(d["b1"]!) ?? 0) > Double(mx) { f.append("dato \(d["b1"]!)") }
        case "romanos":
            let n = Int(d["numero"] ?? "") ?? Int(d["respuesta"] ?? "") ?? -1
            if let r = c.rango, !(r[0]...r[1]).contains(n) { f.append("número \(n)") }
            if sustractivos(n) < (c.sustractivos ?? 0) { f.append("\(n) sin grupo sustractivo") }
        case "mcmMcd":
            let nums = d["numeros"]!.split(separator: ",").map { Int($0)! }
            if let r = c.numeros, !(r[0]...r[1]).contains(nums.count) { f.append("\(nums.count) números") }
            if nums.contains(where: { $0 > (c.maximoNumero ?? .max) }) { f.append("números \(nums)") }
        case "probabilidadSimple":
            if !(d["clave"] ?? "").hasPrefix(c.experimento ?? "") { f.append("experimento \(d["clave"] ?? "")") }
        case "estadisticaBasica":
            let datos = d["datos"]!.split(separator: ";").map(String.init)
            if let r = c.datos, !(r[0]...r[1]).contains(datos.count) { f.append("\(datos.count) datos") }
            if datos.contains(where: { Int($0) == nil || Int($0)! > (c.maximoValor ?? .max) }) { f.append("datos \(datos)") }
        case "analisisVerbal":
            guard case .ruedas(let r) = item.payload else { return ["payload"] }
            if !GeneradorAnalisisVerbal.banco(banco05E.recursos).regulares.contains(d["verbo"]!) { f.append("verbo no regular \(d["verbo"]!)") }
            let tiempos = Set(r.ruedas.first { $0.id == "tiempo" }!.opciones)
            for t in ["Pretérito pluscuamperfecto", "Futuro compuesto", "Condicional simple", "Pretérito imperfecto"] where !tiempos.contains(t) { f.append("falta \(t)") }
        case "literatura":
            guard case .ordenar(let o) = item.payload else { return ["payload"] }
            let autores = o.ordenCorrecto.map { id in Oraculo05E.literatura.autores.first { $0.nombre == o.fichas.first { $0.id == id }!.texto }! }
            let fechas = autores.map { $0.nacimiento! }
            let menor = zip(fechas.dropFirst(), fechas).map { $0 - $1 }.min()!
            if let s = c.separacion, !(s[0]...s[1]).contains(menor) { f.append("separación mínima \(menor)") }
            if autores.contains(where: { $0.ambito != (c.ambito ?? $0.ambito) }) { f.append("ámbito") }
        case "fraseHueco":
            guard case .eleccion(let e) = item.payload else { return ["payload"] }
            if let r = c.opciones, !(r[0]...r[1]).contains(e.opciones.count) { f.append("\(e.opciones.count) opciones") }
            if !item.enunciado.contains("_____") { f.append("sin hueco") }
        default: f.append("generador sin perfil: \(c.generador)")
        }
        return f
    }
}

@Suite("Fase 05E · Calibración «nivel examen» (anclas)")
struct AnclasTests {
    @Test("El archivo de anclas se carga y cada ancla apunta a una plantilla y una competencia del catálogo")
    func archivo() {
        #expect(Ancla.todas.count >= 60)
        let ids = Set(banco05E.catalogo.todasLasCompetencias.map(\.id))
        for a in Ancla.todas {
            #expect(ids.contains(a.competencia), "\(a.pregunta): \(a.competencia)")
            #expect(banco05E.plantillas.contains { $0.id == a.plantilla }, "\(a.pregunta): \(a.plantilla)")
            #expect(a.reproducible == (a.comprobacion != nil) && (!a.reproducible || a.nivelQueLaReproduce == 4))
            if !a.reproducible { #expect(!a.nota.isEmpty, "\(a.pregunta): falta el motivo") }
        }
    }

    @Test("1000 semillas en el nivel 4 reproducen el perfil de la pregunta oficial", arguments: Ancla.todas.filter(\.reproducible))
    func nivelCuatro(_ a: Ancla) throws {
        let base = try #require(banco05E.plantillas.first { $0.id == a.plantilla })
        let c = try #require(a.comprobacion)
        let p = MotorGeneradores.ajustada(base, dificultad: 4)
        var fallos: [String] = []
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: banco05E.recursos)
            fallos += PerfilEstructural.comprobar(c, m, MotorGeneradores.item(p, semilla: semilla, muestra: m))
            if fallos.count > 5 { break }
        }
        #expect(fallos.isEmpty, "\(a.pregunta): \(fallos)")
    }
}
