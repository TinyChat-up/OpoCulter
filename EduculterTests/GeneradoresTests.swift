import Foundation
import SwiftData
import Testing
import UIKit
@testable import Educulter

// Tests de la Fase 05C: generadores paramétricos (propiedades con 1000 semillas por plantilla y
// oráculos independientes), léxico, catálogo de preguntas, integración con rondas y Rescate,
// migración de avatares y fuente de exhibición.

private let bancoGeneradores: BancoContenido = {
    (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 1))!
}()

private let validador = ValidadorContenido(anioActual: 2026)
private let competencias = Set(bancoGeneradores.catalogo.todasLasCompetencias.map(\.id))

// MARK: - Oráculos independientes (no usan el código de los generadores)

enum Oraculo {
    static func racional(_ t: String) -> Double? {
        let s = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        if s.contains("/") {
            let p = s.split(separator: "/").compactMap { Double($0) }
            return p.count == 2 && p[1] != 0 ? p[0] / p[1] : nil
        }
        return Double(s)
    }

    /// Evaluador recursivo de expresiones con ( ) [ ] { }, ×, :, +, − y la variable x.
    static func evaluar(_ texto: String, x: Double = 0) -> Double? {
        var t = texto.replacingOccurrences(of: " ", with: "")
        // Multiplicación implícita: 3x, 3(, )(.
        var salida = ""
        for c in t {
            if let ultimo = salida.last, (c == "x" || "([{".contains(c)), ultimo.isNumber || ultimo == "x" || ")]}".contains(ultimo) { salida.append("×") }
            salida.append(c)
        }
        t = salida
        let cs = Array(t)
        var i = 0
        func numero() -> Double? {
            if i < cs.count, "([{".contains(cs[i]) { i += 1; let v = suma(); i += 1; return v }
            if i < cs.count, cs[i] == "x" { i += 1; return x }
            if i < cs.count, cs[i] == "−" || cs[i] == "-" { i += 1; return numero().map { -$0 } }
            var s = ""
            while i < cs.count, cs[i].isASCII, cs[i].isNumber || cs[i] == "," { s.append(cs[i]); i += 1 }
            guard var v = Double(s.replacingOccurrences(of: ",", with: ".")) else { return nil }
            // Fracción escrita como número (3/4).
            if i + 1 < cs.count, cs[i] == "/", cs[i + 1].isNumber {
                i += 1
                var d = ""
                while i < cs.count, cs[i].isASCII, cs[i].isNumber { d.append(cs[i]); i += 1 }
                v /= Double(d)!
            }
            // Exponente en superíndice (2³).
            let sup: [Character: Int] = ["⁰": 0, "¹": 1, "²": 2, "³": 3, "⁴": 4, "⁵": 5, "⁶": 6, "⁷": 7, "⁸": 8, "⁹": 9]
            var e = ""
            while i < cs.count, let k = sup[cs[i]] { e += "\(k)"; i += 1 }
            if let k = Int(e) { v = pow(v, Double(k)) }
            return v
        }
        func producto() -> Double? {
            guard var v = numero() else { return nil }
            while i < cs.count, cs[i] == "×" || cs[i] == ":" {
                let op = cs[i]; i += 1
                guard let w = numero() else { return nil }
                v = op == "×" ? v * w : v / w
            }
            return v
        }
        func suma() -> Double? {
            guard var v = producto() else { return nil }
            while i < cs.count, cs[i] == "+" || cs[i] == "−" || cs[i] == "-" {
                let op = cs[i]; i += 1
                guard let w = producto() else { return nil }
                v = op == "+" ? v + w : v - w
            }
            return v
        }
        return suma()
    }

    static func romanoAEntero(_ s: String) -> Int {
        let v: [Character: Int] = ["I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000]
        let n = s.compactMap { v[$0] }
        return n.indices.reduce(0) { acc, i in acc + (i + 1 < n.count && n[i] < n[i + 1] ? -n[i] : n[i]) }
    }

    static func enteroARomano(_ n: Int) -> String {
        let tabla: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"), (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var resto = n, s = ""
        for (v, t) in tabla { while resto >= v { s += t; resto -= v } }
        return s
    }

    /// Exponentes (respecto a la unidad base) y factor por salto, escritos aparte del generador.
    static let unidades: [String: (Int, Int)] = [
        "km": (3, 10), "hm": (2, 10), "dam": (1, 10), "m": (0, 10), "dm": (-1, 10), "cm": (-2, 10), "mm": (-3, 10),
        "kg": (3, 10), "hg": (2, 10), "dag": (1, 10), "g": (0, 10), "dg": (-1, 10), "cg": (-2, 10), "mg": (-3, 10),
        "kl": (3, 10), "hl": (2, 10), "dal": (1, 10), "l": (0, 10), "dl": (-1, 10), "cl": (-2, 10), "ml": (-3, 10),
        "km²": (6, 10), "hm²": (4, 10), "dam²": (2, 10), "m²": (0, 10), "dm²": (-2, 10), "cm²": (-4, 10), "mm²": (-6, 10),
        "m³": (9, 10), "dm³": (6, 10), "cm³": (3, 10), "mm³": (0, 10),
    ]

    static func mcd(_ a: Int, _ b: Int) -> Int { (1...min(a, b)).last { a % $0 == 0 && b % $0 == 0 }! }
    static func mcm(_ a: Int, _ b: Int) -> Int { (max(a, b)...(a * b)).first { $0 % a == 0 && $0 % b == 0 }! }

    /// Probabilidad por recuento del espacio muestral a partir de la clave del caso.
    static func probabilidad(_ clave: String) -> Double? {
        let p = clave.split(separator: "|").map(String.init)
        switch p[0] {
        case "dado":
            let caras = Array(1...6)
            let favorables: Int
            if p[1] == "par" { favorables = caras.filter { $0 % 2 == 0 }.count }
            else if p[1] == "impar" { favorables = caras.filter { $0 % 2 == 1 }.count }
            else if p[1].hasPrefix("=") { favorables = caras.filter { $0 == Int(p[1].dropFirst())! }.count }
            else { favorables = caras.filter { $0 > Int(p[1].dropFirst())! }.count }
            return Double(favorables) / 6
        case "bolsa":
            let numeros = p[1].dropFirst().dropLast().split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces))! }
            let colores = ["rojas", "azules", "verdes"]
            let no = p[2].hasPrefix("no")
            let i = colores.firstIndex(of: no ? String(p[2].dropFirst(2)) : p[2])!
            let total = numeros.reduce(0, +)
            return Double(no ? total - numeros[i] : numeros[i]) / Double(total)
        case "tarjetas":
            let n = Int(p[1])!
            let t = Array(1...n)
            let f: Int
            if p[2] == "par" { f = t.filter { $0 % 2 == 0 }.count }
            else if p[2] == "primo" { f = t.filter { k in k > 1 && (2..<k).allSatisfy { k % $0 != 0 } }.count }
            else { let k = Int(p[2].dropFirst(4))!; f = t.filter { $0 % k == 0 }.count }
            return Double(f) / Double(n)
        default:
            let tiradas = (1...6).flatMap { a in (1...6).map { (a, $0) } }
            if p[1] == "dobles" { return Double(tiradas.filter { $0.0 == $0.1 }.count) / 36 }
            let s = Int(p[1].dropFirst())!
            return Double(tiradas.filter { p[1].hasPrefix("=") ? $0.0 + $0.1 == s : $0.0 + $0.1 > s }.count) / 36
        }
    }

    /// Acentuación independiente del generador: cuenta núcleos vocálicos (sin silabear las
    /// consonantes), separa hiatos (dos vocales abiertas o una cerrada con tilde) y aplica las
    /// reglas generales para la tónica cuando no hay tilde. Devuelve (sílabas, tónica, clase).
    static func acento(_ palabra: String, tonica declarada: Int? = nil) -> (silabas: Int, tonica: Int, clase: String) {
        let l = Array(palabra.lowercased())
        let abiertas: Set<Character> = ["a", "e", "o", "á", "é", "ó"], cerradasTilde: Set<Character> = ["í", "ú"]
        let vocales: Set<Character> = abiertas.union(["i", "u", "ü"]).union(cerradasTilde)
        var nucleos: [[Int]] = []
        var actual: [Int] = []
        var anterior: Int? = nil
        for (k, c) in l.enumerated() {
            let muda = c == "u" && k > 0 && (l[k - 1] == "q" || l[k - 1] == "g") && k + 1 < l.count && "eiéí".contains(l[k + 1])
            if vocales.contains(c) && !muda {
                let pegada = anterior.map { a in (a + 1 ..< k).allSatisfy { l[$0] == "h" } } ?? false
                if pegada, let a = anterior {
                    let separa = (abiertas.contains(l[a]) && abiertas.contains(c)) || cerradasTilde.contains(c) || cerradasTilde.contains(l[a])
                    if separa { nucleos.append(actual); actual = [k] } else { actual.append(k) }
                } else {
                    if !actual.isEmpty { nucleos.append(actual) }
                    actual = [k]
                }
                anterior = k
            }
        }
        if !actual.isEmpty { nucleos.append(actual) }
        let n = nucleos.count
        let conTilde = nucleos.firstIndex { $0.contains { "áéíóú".contains(l[$0]) } }
        let ultima = l.last!, penultima = l.count > 1 ? l[l.count - 2] : " "
        let llanaPorRegla = vocales.contains(ultima) || ((ultima == "n" || ultima == "s") && vocales.contains(penultima))
        let t = declarada ?? conTilde ?? (n >= 2 && llanaPorRegla ? n - 2 : n - 1)
        let clase = ["aguda", "llana", "esdrujula", "sobresdrujula"][min(n - 1 - t, 3)]
        return (n, t, clase)
    }

    /// Factores de las unidades respecto a la base de su magnitud, escritos aparte del generador.
    /// Capacidad y volumen comparten base (litros: 1 dm³ = 1 l); la masa va en gramos.
    static let factores: [String: (String, Double)] = [
        "km": ("L", 1000), "hm": ("L", 100), "dam": ("L", 10), "m": ("L", 1), "dm": ("L", 0.1), "cm": ("L", 0.01), "mm": ("L", 0.001),
        "kg": ("M", 1000), "hg": ("M", 100), "dag": ("M", 10), "g": ("M", 1), "dg": ("M", 0.1), "cg": ("M", 0.01), "mg": ("M", 0.001),
        "kl": ("C", 1000), "hl": ("C", 100), "dal": ("C", 10), "l": ("C", 1), "dl": ("C", 0.1), "cl": ("C", 0.01), "ml": ("C", 0.001),
        "m³": ("C", 1000), "dm³": ("C", 1), "cm³": ("C", 0.001), "mm³": ("C", 0.000001),
        "km²": ("S", 1e6), "hm²": ("S", 1e4), "dam²": ("S", 100), "m²": ("S", 1), "dm²": ("S", 0.01), "cm²": ("S", 1e-4), "mm²": ("S", 1e-6),
        "ha": ("S", 1e4), "a": ("S", 100), "ca": ("S", 1),
    ]

    /// Números que aparecen en un texto (con coma decimal y puntos de miles).
    static func numeros(_ t: String) -> [Double] {
        var out: [Double] = [], actual = ""
        for c in t + " " {
            if c.isASCII && (c.isNumber || ((c == "," || c == ".") && !actual.isEmpty)) { actual.append(c) }
            else if !actual.isEmpty {
                while actual.last == "," || actual.last == "." { actual.removeLast() }
                if let v = racional(actual) { out.append(v) }
                actual = ""
            }
        }
        return out
    }

    /// Formas verbales escritas a mano: forma → (persona, número, tiempo, modo).
    static let formas: [String: (String, String, String, String)] = [
        "cantaré": ("1.ª", "Singular", "Futuro simple", "Indicativo"),
        "vivís": ("2.ª", "Plural", "Presente", "Indicativo"),
        "subirías": ("2.ª", "Singular", "Condicional simple", "Indicativo"),
        "bebíamos": ("1.ª", "Plural", "Pretérito imperfecto", "Indicativo"),
        "miren": ("3.ª", "Plural", "Presente", "Subjuntivo"),
        "tuvo": ("3.ª", "Singular", "Pretérito perfecto simple", "Indicativo"),
        "dijeron": ("3.ª", "Plural", "Pretérito perfecto simple", "Indicativo"),
        "pongamos": ("1.ª", "Plural", "Presente", "Subjuntivo"),
        "tendrán": ("3.ª", "Plural", "Futuro simple", "Indicativo"),
        "habéis comido": ("2.ª", "Plural", "Pretérito perfecto compuesto", "Indicativo"),
        "hayas temido": ("2.ª", "Singular", "Pretérito perfecto compuesto", "Subjuntivo"),
        "hiciste": ("2.ª", "Singular", "Pretérito perfecto simple", "Indicativo"),
        "saltaron": ("3.ª", "Plural", "Pretérito perfecto simple", "Indicativo"),
        "comeréis": ("2.ª", "Plural", "Futuro simple", "Indicativo"),
        "hubierais puesto": ("2.ª", "Plural", "Pretérito pluscuamperfecto", "Subjuntivo"),
    ]
}

// MARK: - Comprobaciones por ítem

private func respuestaCorrecta(_ item: Item) -> String? {
    switch item.payload {
    case .numerico(let n): n.respuesta
    case .eleccion(let e): e.opciones.first { $0.id == e.correcta }?.texto
    default: nil
    }
}

/// Distractores sin duplicados ni iguales a la solución; errores habituales coherentes.
private func comprobarDistractores(_ item: Item) {
    switch item.payload {
    case .eleccion(let e):
        let textos = e.opciones.map(\.texto)
        #expect(Set(textos).count == textos.count, "Opciones duplicadas en \(item.id): \(textos)")
        #expect(e.opciones.contains { $0.id == e.correcta })
        for err in item.erroresHabituales { #expect(err.respuesta != e.correcta, "\(item.id): error habitual = correcta") }
    case .numerico(let n):
        let correcta = Racional.interpretar(n.respuesta)?.valor
        let respuestas = item.erroresHabituales.map(\.respuesta)
        #expect(Set(respuestas).count == respuestas.count, "Errores duplicados en \(item.id)")
        for r in respuestas {
            let v = Racional.interpretar(r)?.valor
            #expect(v != nil, "\(item.id): error «\(r)» no interpretable")
            #expect(v != correcta, "\(item.id): error «\(r)» igual a la solución")
        }
        // Distintos también por su valor (0,5 y 1/2 serían el mismo distractor).
        let valores = respuestas.compactMap { Racional.interpretar($0)?.valor }
        #expect(Set(valores).count == valores.count, "Errores con el mismo valor en \(item.id): \(respuestas)")
    case .construir(let c):
        let textos = c.piezas.map(\.texto)
        #expect(Set(textos).count == textos.count, "Piezas duplicadas en \(item.id)")
    default: break
    }
}

/// Oráculo independiente según el tipo de generador.
private func comprobarOraculo(_ p: Plantilla, _ m: Muestra, _ item: Item) {
    let d = m.datos
    let sol = respuestaCorrecta(item).map { $0.replacingOccurrences(of: " \(p.parametros["unidad"]?.textos?.first ?? "@@")", with: "") }
    switch p.tipo {
    case "porcentajeDe":
        let pc = Oraculo.racional(d["p"]!)! / 100, base = Double(d["base"]!)!
        let p2 = d["p2"].flatMap(Oraculo.racional).map { $0 / 100 } ?? 0
        let esperado: Double = switch d["variante"]! {
        case "calc": base * pc
        case "total", "inv": base
        case "desc": base * (1 - pc)
        case "aum": base * (1 + pc)
        case "dd": base * (1 - pc) * (1 - p2)
        default: base * (1 + pc) * (1 - p2)
        }
        if case .construir(let c) = item.payload {
            let textos = Dictionary(uniqueKeysWithValues: c.piezas.map { ($0.id, $0.texto) })
            let valores = Dictionary(uniqueKeysWithValues: c.huecos.map { ($0.id, Oraculo.racional(textos[$0.correcta]!)!) })
            let factores = c.huecos.filter { $0.id != "resultado" }.map { valores[$0.id]! }
            #expect(abs(factores.reduce(base, *) - esperado) < 0.006, "\(item.id): factores \(factores)")
            #expect(abs(valores["resultado"]! - esperado) < 1e-6, "\(item.id): resultado")
        } else {
            #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-6, "\(item.id): \(sol!) ≠ \(esperado)")
        }
        // Los datos del enunciado son los del caso (base o parte visibles).
        let enTexto = Oraculo.numeros(item.enunciado)
        #expect(enTexto.contains { abs($0 - base) < 1e-9 || abs($0 - base * pc) < 1e-9 || abs($0 - base * (1 - pc)) < 1e-9 }, "\(item.id): \(item.enunciado)")
        #expect(base <= 10_000)
    case "fraccionBarras":
        guard case .fraccionBarras(let f) = item.payload else { Issue.record("payload"); return }
        let solucion = f.solucion
        #expect(Double(solucion.coloreadas) / Double(solucion.partes) == Double(d["n"]!)! / Double(d["d"]!)!)
        #expect(Evaluador.evaluar(.fraccionBarras(partes: solucion.partes, coloreadas: Set(0..<solucion.coloreadas)), para: item).correcto)
    case "reglaDeTres":
        let a1 = Double(d["a1"]!)!, b1 = Oraculo.racional(d["b1"]!)!, a2 = Double(d["a2"]!)!
        let esperado = d["modo"] == "cadena" ? b1 * a2 / 100 * Oraculo.racional(d["extra"]!)! : b1 * a2 / a1
        #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-6, "\(item.id): \(sol!) ≠ \(esperado)")
        let enTexto = Oraculo.numeros(item.enunciado)
        #expect(enTexto.contains(b1) && enTexto.contains(a2), "\(item.id): \(item.enunciado)")
    case "conversionUnidades":
        let terminos = d["terminos"]!.split(separator: ";").map { $0.split(separator: ":").map(String.init) }
        let destino = Oraculo.factores[d["hasta"]!]!
        var total = 0.0
        for t in terminos {
            let f = Oraculo.factores[t[1]]!
            if d["agua"] == "1" { #expect(f.0 == "C") } else { #expect(f.0 == destino.0, "\(item.id): magnitudes distintas") }
            total += Oraculo.racional(t[0])! * f.1 * (d["agua"] == "1" ? 1000 : 1)
        }
        let esperado = total / destino.1
        #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-6 * max(1, esperado), "\(item.id): \(sol!) ≠ \(esperado)")
    case "sexagesimal":
        let t1 = Int(d["t1"]!)!, t2 = Int(d["t2"]!)!, k = Int(d["k"]!)!
        let partes: [[Int]] = (d["partes"] ?? "").split(separator: ";").map { p in p.split(separator: ":").map { Int($0)! } }
        let sumaPartes: Int = partes.map { $0[0] * 3600 + $0[1] * 60 + $0[2] }.reduce(0, +)
        let segundos: Int = switch d["op"]! {
        case "suma": t1 + t2
        case "resta": t1 - t2
        case "dur": t2 - t1
        case "medianoche": (t2 + 86_400 - t1) % 86_400
        case "mul": t1 * k
        // Suma de tiempos sin normalizar (05E): cada uno «h:min:s», calculado aquí.
        case "sumaN": sumaPartes
        default: t1
        }
        #expect(segundos > 0 && Int(d["segundos"]!)! == segundos)
        if case .ruedas(let rr) = item.payload {
            let v = Dictionary(uniqueKeysWithValues: rr.ruedas.map { ($0.id, Int($0.correcta)!) })
            #expect(v["h"]! * 3600 + v["min"]! * 60 + (v["s"] ?? 0) == segundos, "\(item.id)")
            #expect(v["min"]! < 60 && (v["s"] ?? 0) < 60)
        } else {
            #expect(Int(sol!)! * (d["unidad"] == "min" ? 60 : 1) == segundos, "\(item.id): \(sol!)")
        }
    case "escala":
        let n = Oraculo.numeros(item.enunciado)
        let esperado: Double = switch d["modo"]! {
        case "mr": n[1] * n[2] / (d["unidad"] == "km" ? 100_000 : 100)   // 1:e, d cm
        case "mrPlano": n[1] * n[2] / (d["unidadPlano"] == "mm" ? 1000 : 100)   // 1:e, d cm o mm → m
        case "rm": n[0] * 100_000 / n[2]                                  // D km, 1:e
        default: n[0] * 100_000 / n[1]                                    // D km, d cm
        }
        #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-6 * max(1, esperado), "\(item.id): \(item.enunciado) → \(sol!) ≠ \(esperado)")
    case "problemaFraccion":
        let total = Double(d["total"]!)!, fs = d["fracciones"]!.split(separator: ";").map { Oraculo.racional(String($0))! }
        var queda = total
        if d["resto"] == "1" { for f in fs { queda -= queda * f } } else { queda -= fs.reduce(0, +) * total }
        #expect(abs(Oraculo.racional(sol!)! - queda) < 1e-6, "\(item.id): \(sol!) ≠ \(queda)")
    case "fraccionesOperar":
        let esperado = Oraculo.evaluar(d["expresion"]!)!
        #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-9, "\(item.id): \(d["expresion"]!) = \(esperado) ≠ \(sol!)")
        if sol!.contains("/") { let p = sol!.split(separator: "/").map { Int($0)! }; #expect(Oraculo.mcd(p[0], p[1]) == 1, "Irreducible") }
    case let t where t == "ordenarNumeros" || (t == "operacionesCombinadas" && p.mecanica == .ordenar):
        guard case .ordenar(let o) = item.payload else { Issue.record("payload"); return }
        let textos = Dictionary(uniqueKeysWithValues: o.fichas.map { ($0.id, $0.texto) })
        if p.tipo == "ordenarNumeros" {
            let valores = o.ordenCorrecto.map { Oraculo.racional(textos[$0]!)! }
            #expect(valores == valores.sorted(), "\(item.id): orden incorrecto \(valores)")
            #expect(Set(valores).count == valores.count, "\(item.id): valores repetidos")
        } else {
            let ultimo = textos[o.ordenCorrecto.last!]!
            let resultado = Oraculo.racional(ultimo.split(separator: "=").last!.trimmingCharacters(in: .whitespaces))!
            #expect(abs(resultado - Oraculo.evaluar(d["expresion"]!)!) < 1e-9, "\(item.id): \(d["expresion"]!) ≠ \(resultado)")
            let operadores = d["expresion"]!.filter { "+−×:".contains($0) }.count + d["expresion"]!.filter { "²³".contains($0) }.count
            #expect(o.fichas.count == operadores, "\(item.id): \(o.fichas.count) pasos para \(operadores) operaciones")
        }
    case "operacionesCombinadas":
        let esperado = Oraculo.evaluar(d["expresion"]!)!
        #expect(abs(esperado - Oraculo.racional(sol!)!) < 1e-9, "\(item.id): \(d["expresion"]!) = \(esperado) ≠ \(sol!)")
    case "romanos":
        switch item.payload {
        case .construir(let c):
            let textos = Dictionary(uniqueKeysWithValues: c.piezas.map { ($0.id, $0.texto) })
            #expect(c.huecos.map { textos[$0.correcta]! }.joined() == Oraculo.enteroARomano(Int(d["numero"]!)!))
        case .eleccion(let e) where d["malEscrito"] != nil:
            let malos = e.opciones.filter { Oraculo.enteroARomano(Oraculo.romanoAEntero($0.texto)) != $0.texto }
            #expect(malos.count == 1 && malos.first?.id == e.correcta, "\(item.id): \(e.opciones.map(\.texto))")
        default:
            #expect(Oraculo.romanoAEntero(d["romano"]!) == Int(sol!)!)
            #expect(Oraculo.enteroARomano(Int(sol!)!) == d["romano"]!)
        }
    case "mcmMcd":
        let nums = d["numeros"]!.split(separator: ",").map { Int($0)! }
        let mcm = nums.dropFirst().reduce(nums[0], Oraculo.mcm), mcd = nums.dropFirst().reduce(nums[0], Oraculo.mcd)
        if let cota = Int(d["cota"]!) {
            #expect((cota..<(cota + mcm)).filter { $0 % mcm == 0 } == [Int(sol!)!])
        } else {
            #expect(Int(sol!)! == (d["op"] == "mcd" ? mcd : mcm))
        }
    case "estadisticaBasica":
        let datos = d["datos"]!.split(separator: ";").map { Oraculo.racional(String($0))! }
        let o = datos.sorted()
        let esperado: Double = switch d["medida"]! {
        case "media": datos.reduce(0, +) / Double(datos.count)
        case "mediana": o.count % 2 == 1 ? o[o.count / 2] : (o[o.count / 2 - 1] + o[o.count / 2]) / 2
        case "rango": o.last! - o.first!
        default: Dictionary(grouping: datos, by: { $0 }).max { $0.value.count < $1.value.count }!.key
        }
        #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-9, "\(item.id): \(sol!) ≠ \(esperado)")
    case "probabilidadSimple":
        #expect(abs(Oraculo.racional(sol!)! - Oraculo.probabilidad(d["clave"]!)!) < 1e-12)
    case "ecuacionLineal":
        let lados = d["ecuacion"]!.split(separator: "=").map(String.init)
        let soluciones = (-100...100).filter { x in
            guard let a = Oraculo.evaluar(lados[0], x: Double(x)), let b = Oraculo.evaluar(lados[1], x: Double(x)) else { return false }
            return abs(a - b) < 1e-9
        }
        #expect(soluciones == [Int(sol!)!], "\(item.id): \(d["ecuacion"]!) → \(soluciones)")
    case "colocarTilde":
        guard case .colocarTilde(let c) = item.payload else { Issue.record("payload"); return }
        #expect(c.correcta == d["palabra"]!, "\(item.id): \(c.correcta) ≠ \(d["palabra"]!)")
        // La tilde escrita coincide con la que piden las reglas según el oráculo.
        let o = Oraculo.acento(d["palabra"]!)
        let tilde = d["palabra"]!.contains { "áéíóú".contains($0) }
        let hiato = d["palabra"]!.contains { "íú".contains($0) } && o.silabas > 1
        let l = Array(d["palabra"]!)
        let vocalNS = "aeiouáéíóú".contains(l.last!) || ((l.last! == "n" || l.last! == "s") && "aeiouáéíóú".contains(l[l.count - 2]))
        let porClase: Bool
        switch o.clase {
        case "aguda": porClase = o.silabas > 1 && vocalNS
        case "llana": porClase = !vocalNS
        default: porClase = true
        }
        let pideTilde = hiato || porClase
        #expect(tilde == pideTilde, "\(item.id): «\(d["palabra"]!)» \(o)")
    case "clasificarAcentuacion":
        if case .clasificar(let c) = item.payload {
            for f in c.fichas { #expect(f.categoria == Oraculo.acento(f.texto, tonica: ["robots": 1, "tictacs": 1, "zigzags": 1][f.texto]).clase, "\(item.id): \(f.texto)") }
            #expect((4...6).contains(c.fichas.count) && Set(c.fichas.map(\.categoria)).count >= 2)
        } else {
            #expect(d["clase"] == Oraculo.acento(d["palabra"]!).clase, "\(item.id): \(d["palabra"]!)")
        }
    case "silabaTonica":
        guard case .marcarTexto(let mt) = item.payload else { Issue.record("payload"); return }
        let o = Oraculo.acento(d["palabra"]!, tonica: ["robots": 1, "tictacs": 1, "zigzags": 1][d["palabra"]!])
        #expect(mt.tokens.count == o.silabas, "\(item.id): \(mt.tokens.map(\.texto)) frente a \(o.silabas) sílabas")
        #expect(mt.tokens.firstIndex { $0.id == mt.correctos.first } == o.tonica, "\(item.id): \(d["palabra"]!)")
    case "oracionSimple":
        // Oráculo de la estructura y reglas de naturalidad (D-090): GramaticaCompatibilidadTests.
        let f = OraculoOracion.comprobar(m, item, p)
        #expect(f.isEmpty, "\(item.id): \(f)")
    case "analisisVerbal":
        let f = Oraculo05E.comprobarAnalisis(m, item)
        #expect(f.isEmpty, "\(item.id): \(f)")
        if case .ruedas(let rr) = item.payload, let esperado = Oraculo.formas[d["forma"]!] {
            #expect(Array(rr.ruedas.map(\.correcta).prefix(4)) == [esperado.0, esperado.1, esperado.2, esperado.3], "\(d["forma"]!)")
        }
    case "terminoDesconocido":
        // Se resuelve aquí cada igualdad con su operación inversa.
        let partes = d["igualdades"]!.split(separator: "|").map { $0.split(separator: ":").map(String.init) }
        let f1 = partes[0], a1 = Oraculo.racional(f1[1])!, n1 = Oraculo.racional(f1[2])!
        let x: Double = switch f1[0] { case "mul", "div": n1 / a1; case "suma": n1 - a1; default: n1 + a1 }
        var esperado = x
        if partes.count == 2 {
            let k = Double(partes[1][1])!
            esperado = switch partes[1][0] { case "div": x / k; case "suma": x - k; default: x + k }
            #expect(abs(Double(d["a"]!)! - x) < 1e-9, "\(item.id): a")
        }
        #expect(abs(Oraculo.racional(sol!)! - esperado) < 1e-9, "\(item.id): \(item.enunciado) → \(sol!) ≠ \(esperado)")
        #expect(esperado == esperado.rounded() && esperado > 0, "\(item.id): solución natural")
    case "formasNoPersonales":
        let f = Oraculo05E.comprobarNoPersonales(m, item)
        #expect(f.isEmpty, "\(item.id): \(f)")
    case "literatura":
        let f = Oraculo05E.comprobarLiteratura(m, item)
        #expect(f.isEmpty, "\(item.id): \(f)")
    case "fraseHueco":
        if let c = respuestaCorrecta(item) { #expect(c == d["correcta"]) }
    default: Issue.record("Sin oráculo para \(p.tipo)")
    }
}

// MARK: - Suites

@Suite("Generadores: propiedades (1000 semillas por plantilla)")
struct GeneradoresPropiedadesTests {
    static let plantillas = bancoGeneradores.plantillas

    @Test("Hay plantillas para los 23 tipos y todas sus mecánicas; las del lote 02, 02b y 05E aprobadas están aprobadas")
    func cobertura() {
        let tipos = Set(Self.plantillas.map(\.tipo))
        #expect(tipos == Set(MotorGeneradores.generadores.keys))
        for (tipo, g) in MotorGeneradores.generadores {
            let mecanicas = Set(Self.plantillas.filter { $0.tipo == tipo }.map(\.mecanica))
            #expect(mecanicas == g.mecanicas, "\(tipo): \(mecanicas) ≠ \(g.mecanicas)")
        }
        // Lote 02 (38) y frases del lote 02b (4, D-089): aprobadas por la dirección; el resto (05C) siguen en borrador.
        let lote02 = Self.plantillas.filter { $0.procedencia.notas?.hasPrefix("Lote 02") == true }
        let lote02b = Self.plantillas.filter { $0.procedencia.notas?.hasPrefix("Plantilla del lote 02b") == true }
        let fase05E = Self.plantillas.filter { $0.procedencia.notas?.hasPrefix("Fase 05E") == true }
        #expect(lote02.count == 38 && lote02b.count == 4 && fase05E.count == 38)
        #expect(lote02.allSatisfy { $0.validacion == Validacion(estado: .aprobado, revisor: "direccion", fecha: "2026-11-24") })
        #expect(lote02b.allSatisfy { $0.validacion == Validacion(estado: .aprobado, revisor: "direccion", fecha: "2026-11-25") })
        // Las de la 05E: aprobadas solo si superan estos tests (ver PlantillasNuevas05ETests); el resto (05C), en borrador.
        #expect(fase05E.allSatisfy { $0.validacion.estado == .borrador || $0.validacion == Validacion(estado: .aprobado, revisor: "direccion", fecha: "2026-11-25") })
        // Aprobadas en la 05E parte 2 (D-101): MCD, CENTRAL y LAPLACE (plantillas de la 05C que superan propiedades y anclas).
        let aprobadas05C: Set<String> = ["MAT.DIV.MCD.G01", "MAT.EST.CENTRAL.G01", "MAT.PRO.LAPLACE.G01"]
        #expect(Self.plantillas.filter { aprobadas05C.contains($0.id) }.allSatisfy { $0.validacion == Validacion(estado: .aprobado, revisor: "direccion", fecha: "2026-11-25") })
        #expect(Self.plantillas.filter { !lote02.contains($0) && !lote02b.contains($0) && !fase05E.contains($0) && !aprobadas05C.contains($0.id) }.allSatisfy { $0.validacion.estado == .borrador })
    }

    @Test("Validador, oráculo, distractores, determinismo y clave enumerable", arguments: bancoGeneradores.plantillas)
    func propiedades(_ p: Plantilla) throws {
        let g = try #require(MotorGeneradores.generador(p.tipo))
        let espacio = Set(g.enumerar(p, recursos: bancoGeneradores.recursos, limite: 200_000))
        // Solo se comprueba la pertenencia cuando el espacio se ha enumerado entero.
        let muestreado = CatalogoPreguntas.muestreados.contains(p.tipo) || p.mecanica == .clasificar || espacio.count >= 200_000
        var fallos = 0
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGeneradores.recursos)
            let item = MotorGeneradores.item(p, semilla: semilla, muestra: m)
            #expect(item.id == "\(p.id)#\(semilla)")
            #expect(item.mecanica == p.mecanica)
            let errores = validador.validar(item: item, competencias: competencias)
            #expect(errores.isEmpty, "\(errores)")
            #expect(!item.enunciado.contains("{{"), "Marcador sin rellenar: \(item.enunciado)")
            comprobarDistractores(item)
            comprobarOraculo(p, m, item)
            if !muestreado { #expect(espacio.contains(m.clave), "\(p.id): clave \(m.clave) fuera del espacio enumerado") }
            if semilla % 100 == 0 {
                #expect(try MotorGeneradores.generar(p, semilla: semilla, recursos: bancoGeneradores.recursos) == item, "No determinista")
            }
            if !errores.isEmpty || item.enunciado.contains("{{") || (!muestreado && !espacio.contains(m.clave)) { fallos += 1 }
            if fallos >= 3 { break }
        }
    }

    @Test("La complejidad media crece con la dificultad (1→6) en cada plantilla", arguments: bancoGeneradores.plantillas.map(\.id))
    func dificultadCreciente(_ clave: String) throws {
        let base = try #require(Self.plantillas.first { $0.id == clave })
        var medias: [Double] = []
        for d in 1...6 {
            var p = base
            p.dificultad = d
            // Parámetros por defecto del generador (salvo los que fijan qué se pregunta).
            p.parametros = base.parametros.filter { ["operacion", "variante", "familia", "agrupaciones", "modo", "rasgos", "pregunta", "ambitos"].contains($0.key) }
            var suma = 0.0
            for semilla in UInt64(0)..<200 { suma += try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGeneradores.recursos).complejidad }
            medias.append(suma / 200)
        }
        // Los generadores de Lengua dependen del tamaño del léxico y del banco de prueba: con
        // recursos pequeños varios niveles comparten palabras (no decrece y el 6 supera al 1).
        let recursosPequenos = ["colocarTilde", "clasificarAcentuacion", "silabaTonica", "fraseHueco", "analisisVerbal", "oracionSimple"].contains(base.tipo)
        for d in 1..<6 {
            if recursosPequenos { #expect(medias[d] >= medias[d - 1] - 1e-9, "\(clave): \(medias)") }
            else { #expect(medias[d] > medias[d - 1], "\(clave): \(medias)") }
        }
        #expect(medias[5] > medias[0], "\(clave): \(medias)")
    }
}

@Suite("Generadores: motor, validador y conjugación")
struct GeneradoresMotorTests {
    @Test("Ids generados: formato, partes y regeneración desde el banco")
    func ids() throws {
        let p = try #require(bancoGeneradores.plantilla(id: "MAT.ROM.LEER.G01"))
        let item = try MotorGeneradores.generar(p, semilla: 987_654, recursos: bancoGeneradores.recursos)
        #expect(MotorGeneradores.partes(de: item.id)! == ("MAT.ROM.LEER.G01", 987_654))
        #expect(MotorGeneradores.partes(de: "LEN.ORT.AGU.0001") == nil)
        #expect(bancoGeneradores.item(id: item.id) == item, "El banco regenera cualquier semilla")
        #expect(bancoGeneradores.item(id: "MAT.ROM.LEER.G99#1") == nil)
        #expect(validador.validar(item: item, competencias: competencias).isEmpty)
    }

    @Test("El banco materializa variantes únicas y el contenido completo es válido")
    func materializadas() {
        let generados = bancoGeneradores.items.dropFirst(bancoGeneradores.numeroEstaticos)
        #expect(generados.count > bancoGeneradores.plantillas.count * 5)
        #expect(Set(bancoGeneradores.items.map(\.id)).count == bancoGeneradores.items.count)
        #expect(validador.validar(bancoGeneradores).isEmpty, "\(validador.validar(bancoGeneradores).prefix(5))")
        let otraSesion = try! CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5000)
        #expect(Set(otraSesion.items.map(\.id)) != Set(bancoGeneradores.items.map(\.id)), "Otra sesión, otras variantes")
    }

    @Test("Release carga solo las plantillas aprobadas (lote 02), no las de prueba")
    func release() throws {
        let banco = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        #expect(banco.plantillas.count == 83)
        #expect(banco.plantillas.allSatisfy { $0.validacion.estado == .aprobado })
        #expect(validador.validar(banco).isEmpty, "\(validador.validar(banco).prefix(5))")
    }

    @Test("El validador detecta plantillas mal formadas")
    func validadorPlantillas() throws {
        var p = try #require(bancoGeneradores.plantilla(id: "MAT.POR.CALC.G01"))
        p.tipo = "inventado"
        #expect(validador.validar(plantilla: p, competencias: competencias, recursos: .vacios).contains { $0.mensaje.contains("no hay generador") })
        p = bancoGeneradores.plantilla(id: "MAT.POR.CALC.G01")!
        p.enunciados = ["{{desconocido}}"]
        #expect(validador.validar(plantilla: p, competencias: competencias, recursos: .vacios).contains { $0.mensaje.contains("{{desconocido}}") })
        p = bancoGeneradores.plantilla(id: "MAT.POR.CALC.G01")!
        p.mecanica = .ordenar
        p.dificultad = 7
        let m = validador.validar(plantilla: p, competencias: competencias, recursos: .vacios).map(\.mensaje)
        #expect(m.contains { $0.contains("no admite") } && m.contains { $0.contains("1–6") })
        p = bancoGeneradores.plantilla(id: "LEN.ORT.AGU.G01")!
        #expect(validador.validar(plantilla: p, competencias: competencias, recursos: .vacios).contains { $0.mensaje.contains("Faltan recursos") })
        p.id = "LEN.ORT.AGU.X1"
        #expect(validador.validar(plantilla: p, competencias: competencias, recursos: bancoGeneradores.recursos).contains { $0.mensaje.contains("Gnn") })
    }

    @Test("Dificultad 6 admitida en ítems; 7 no")
    func dificultadSeis() throws {
        var item = try #require(bancoGeneradores.items.first)
        item.dificultad = 6
        #expect(!validador.validar(item: item, competencias: competencias).contains { $0.mensaje.contains("dificultad") })
        item.dificultad = 7
        #expect(validador.validar(item: item, competencias: competencias).contains { $0.mensaje.contains("1–6") })
    }

    @Test("Conjugación regular e irregular contra una tabla escrita a mano")
    func conjugacion() {
        let irr = bancoGeneradores.recursos.verbos.irregulares
        for (forma, (persona, numero, tiempo, modo)) in Oraculo.formas {
            let i = (Conjugador.personas.firstIndex(of: persona)!) + (numero == "Plural" ? 3 : 0)
            let verbo = ["cantaré": "cantar", "vivís": "vivir", "subirías": "subir", "bebíamos": "beber", "miren": "mirar", "tuvo": "tener",
                         "dijeron": "decir", "pongamos": "poner", "tendrán": "tener", "habéis comido": "comer", "hayas temido": "temer",
                         "hiciste": "hacer", "saltaron": "saltar", "comeréis": "comer", "hubierais puesto": "poner"][forma]!
            #expect(Conjugador.formas(verbo, tiempo: tiempo, modo: modo, irregulares: irr)?[i] == forma, "\(forma)")
        }
        #expect(Conjugador.formas("cantar", tiempo: "Condicional compuesto", modo: "Subjuntivo", irregulares: []) == nil)
        #expect(Conjugador.formas("cantar", tiempo: "Pretérito anterior", modo: "Subjuntivo", irregulares: []) == nil)
    }

    @Test("Las formas ambiguas no se preguntan")
    func ambiguas() {
        let g = GeneradorAnalisisVerbal()
        let formas = g.casos(2, bancoGeneradores.recursos.verbos).map(\.forma)
        #expect(!formas.contains("cantaba"), "cantaba es 1.ª y 3.ª")
        #expect(!formas.contains("cantamos"), "cantamos es presente y pretérito")
        #expect(formas.contains("cantaste"))
    }

    @Test("Utilidades: formato español, marcadores y parámetros JSON")
    func utilidades() throws {
        #expect(FormatoNumero.numero(Racional(numerador: 1147, denominador: 2)!) == "573,5")
        #expect(FormatoNumero.numero(Racional(numerador: 1, denominador: 3)!) == "1/3")
        #expect(FormatoNumero.numero(Racional(numerador: -5, denominador: 4)!) == "-1,25")
        #expect(FormatoNumero.miles(12500) == "12.500" && FormatoNumero.miles(4500) == "4500")
        #expect(Marcadores.en("a {{x}} b {{y}}") == ["x", "y"])
        let json = #"{"a": 3, "b": "t", "c": [1, 2], "d": {"min": 1, "max": 3}, "e": true}"#
        let v = try JSONDecoder().decode([String: ParametroJSON].self, from: Data(json.utf8))
        #expect(v["a"]?.enteros == [3] && v["b"]?.textos == ["t"] && v["c"]?.enteros == [1, 2] && v["d"]?.enteros == [1, 2, 3])
        #expect(v["e"] == .booleano(true))
        let ida = try JSONDecoder().decode([String: ParametroJSON].self, from: JSONEncoder().encode(v))
        #expect(ida == v)
    }
}

@Suite("Léxico y acentuación")
struct LexicoTests {
    @Test("Léxico del lote 02: 818 palabras, 0 discrepancias entre su tilde y el silabeador con las reglas de la RAE")
    func coherente() {
        let lexico = bancoGeneradores.recursos.lexico
        #expect(lexico.count == 818 && Set(lexico.map(\.palabra)).count == 818)
        let informe = Acentuacion.informe(lexico)
        print("LEXICO discrepancias \(informe.count)")
        for linea in informe { print("LEXICO \(linea)") }
        #expect(informe.isEmpty, "\(informe)")
        #expect(validador.avisos(bancoGeneradores).isEmpty)
        // Todas las palabras no diacríticas de 2+ sílabas se pueden usar en los generadores, salvo las
        // ambiguas sin contexto (05E, §4.1).
        #expect(bancoGeneradores.recursos.palabras.count == Acentuacion.utilizables(lexico).count - bancoGeneradores.recursos.palabrasAmbiguas.count)
        let usadas = Set(bancoGeneradores.recursos.palabras.map(\.analisis.palabra))
        for e in lexico where !Acentuacion.analizar(e).coherente { #expect(!usadas.contains(e.palabra.lowercased()), "«\(e.palabra)» con discrepancia no debe usarse") }
        // Oráculo independiente: clase y tónica de todas las palabras utilizables.
        for w in bancoGeneradores.recursos.palabras {
            let o = Oraculo.acento(w.analisis.palabra, tonica: lexico.first { $0.palabra == w.analisis.palabra }?.tonica)
            #expect(o.silabas == w.analisis.silabas.count && o.tonica == w.analisis.tonica && o.clase == w.analisis.clase?.rawValue,
                    "«\(w.analisis.palabra)»: \(w.analisis.silabas) tónica \(w.analisis.tonica) frente a \(o)")
        }
        // Formas verbales del nivel 6, todas en el léxico.
        #expect(Set(bancoGeneradores.recursos.formasVerbales).isSubset(of: Set(lexico.map(\.palabra))))
        let porNivel = Dictionary(grouping: bancoGeneradores.recursos.palabras, by: \.nivel).mapValues(\.count)
        print("LEXICO niveles " + porNivel.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: " · "))
        #expect((1...6).allSatisfy { (porNivel[$0] ?? 0) > 0 }, "\(porNivel)")
    }

    @Test("Niveles de palabra del lote 02 (plural que cambia la tilde, excepciones, formas verbales)")
    func niveles() {
        let n = Dictionary(uniqueKeysWithValues: bancoGeneradores.recursos.palabras.map { ($0.analisis.palabra, $0.nivel) })
        #expect(n["casa"] == 1 && n["ventana"] == 2 && n["país"] == 3)
        #expect(n["camino"] == nil, "camino/caminó: ambigua sin contexto (05E)")
        #expect(n["canciones"] == 4 && n["exámenes"] == 4 && n["jóvenes"] == 4)
        #expect(n["caracteres"] == 5 && n["bíceps"] == 5 && n["robots"] == 5)
        #expect(n["comía"] == 6 && n["dígaselo"] == 6 && n["actúa"] == 6)
        #expect(n["policía"] == 3, "sustantivo con hiato: no es forma verbal")
    }

    @Test("Las discrepancias salen en el informe (no fallan en silencio)")
    func informe() {
        // Sin tilde escrita ni tónica declarada, la tónica sale de las propias reglas (siempre
        // coherente): las discrepancias detectables son una tilde que las reglas no piden o una
        // tónica declarada que exige tilde.
        let malo = [EntradaLexico(palabra: "relój"), EntradaLexico(palabra: "exámen"), EntradaLexico(palabra: "arbol", tonica: 0),
                    EntradaLexico(palabra: "robots", tonica: 1), EntradaLexico(palabra: "tú", diacritica: true)]
        let r = Acentuacion.informe(malo)
        #expect(r.count == 3, "\(r)")
        #expect(r.contains { $0.contains("«arbol»") && $0.contains("«árbol»") })
        #expect(r.contains { $0.contains("«relój»") && $0.contains("«reloj» (sin tilde)") })
        #expect(!r.contains { $0.contains("robots") || $0.contains("«tú»") })
        #expect(Acentuacion.utilizables(malo).map(\.palabra) == ["robots"])
    }

    @Test("Deducción de silabeo, tónica y clase")
    func deduccion() {
        let a = Acentuacion.analizar(EntradaLexico(palabra: "canción"))
        #expect(a.silabas == ["can", "ción"] && a.clase == .aguda && a.tildePredicha == 5)
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "país")).hiato)
        // La h intercalada no impide el hiato, ni delante ni detrás de la vocal cerrada tónica.
        for palabra in ["prohíbe", "ahínco", "rehúso", "búho"] {
            let h = Acentuacion.analizar(EntradaLexico(palabra: palabra))
            #expect(h.hiato && h.coherente, "\(palabra): \(h.silabas) \(h.motivo)")
        }
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "prohíbe")).silabas == ["pro", "hí", "be"])
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "dígaselo")).clase == .sobresdrujula)
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "robots", tonica: 1)).clase == .aguda)
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "robots")).clase == .aguda, "-s tras consonante: aguda también sin tónica declarada")
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "examen", tonica: 2)).tildePredicha == 4, "Una tónica declarada que exige tilde")
        #expect(Acentuacion.analizar(EntradaLexico(palabra: "bíceps")).coherente)
        #expect(Acentuacion.nivel(Acentuacion.analizar(EntradaLexico(palabra: "joven")), singular: nil, verbo: false) == 1)
        #expect(Acentuacion.nivel(Acentuacion.analizar(EntradaLexico(palabra: "bíceps")), singular: nil, verbo: false) == 5)
    }
}

@Suite("Catálogo de preguntas, rondas y Rescate")
struct CatalogoPreguntasTests {
    @Test("Recuento del catálogo completo en menos de 2 s, sin duplicados y con desglose")
    func recuento() {
        let inicio = Date()
        let r = CatalogoPreguntas.contar(bancoGeneradores)
        let segundos = Date().timeIntervalSince(inicio)
        // El límite de 2 s se aplica sin cobertura; con cobertura (instrumentación) solo se registra.
        let conCobertura = ProcessInfo.processInfo.environment["LLVM_PROFILE_FILE"] != nil
        if conCobertura {
            print("Recuento del catálogo con cobertura: \(segundos) s")
        } else {
            #expect(segundos < 2, "El recuento tarda \(segundos) s")
        }
        #expect(CatalogoPreguntas.contar(bancoGeneradores, paralelo: false) == r, "Paralelo y secuencial dan el mismo recuento")
        let ordenar = r.plantillas.first { $0.tipo == "ordenarNumeros" }
        #expect((ordenar?.variantes ?? 0) <= CatalogoPreguntas.maximoOrdenarNumeros && ordenar?.exacto == false && ordenar?.nota != nil)
        #expect(r.estaticos == bancoGeneradores.numeroEstaticos)
        #expect(r.generados == r.plantillas.map(\.variantes).reduce(0, +))
        #expect(r.porArea.values.reduce(0, +) == r.total)
        #expect(r.porBloque.values.reduce(0, +) == r.total && r.porDificultad.values.reduce(0, +) == r.total)
        #expect(r.plantillas.first { $0.id == "MAT.ROM.LEER.G01" }?.variantes == 360, "40–399")
        #expect(r.plantillas.first { $0.tipo == "operacionesCombinadas" }?.exacto == false, "Muestreo: cota inferior")
        // Caché por versión: la segunda llamada es inmediata y da lo mismo.
        let primera = CatalogoPreguntas.recuento(bancoGeneradores)
        let t = Date()
        #expect(CatalogoPreguntas.recuento(bancoGeneradores) == primera)
        #expect(Date().timeIntervalSince(t) < 0.05)
    }

    @Test("Duplicados entre plantillas del mismo tipo cuentan una vez")
    func duplicados() throws {
        let p = try #require(bancoGeneradores.plantilla(id: "MAT.PRO.LAPLACE.G01"))
        var copia = p
        copia.id = "MAT.PRO.LAPLACE.G02"
        let banco = BancoContenido(catalogo: bancoGeneradores.catalogo, items: [], plantillas: [p, copia], recursos: bancoGeneradores.recursos)
        let r = CatalogoPreguntas.contar(banco)
        #expect(r.plantillas[1].variantes == 0 && r.generados == r.plantillas[0].variantes)
    }

    @Test("Generar una ronda de 8 ítems con plantillas tarda menos de 50 ms")
    func rendimientoRonda() {
        let constructor = ConstructorRondas(banco: bancoGeneradores)
        var rng = GeneradorConSemilla(semilla: 3)
        let ahora = Fx.fecha(2026, 11, 23, 10)
        var peor = 0.0
        for competencia in ["MAT.ROM.LEER", "MAT.OPE.JER", "LEN.SIN.COMPL", "MAT.EST.CENTRAL"] {
            let inicio = Date()
            let ronda = constructor.construir(estados: [:], rescate: ColaRescate(), enCurso: competencia, vistos: [:], ahora: ahora,
                                              calendario: Fx.madrid, rng: &rng)
            // Regenerar cada ítem desde su id (lo que hace la sesión al mostrarlo).
            let items = ronda.items.compactMap { bancoGeneradores.item(id: $0.itemId) }
            peor = max(peor, Date().timeIntervalSince(inicio))
            #expect(items.count == ronda.items.count && items.count >= 6)
            #expect(items.contains { $0.id.contains("#") }, "\(competencia): la ronda usa ítems generados")
        }
        #expect(peor < 0.05, "Ronda en \(peor * 1000) ms")
    }

    @Test("Rescate reproduce el ítem exacto por id y busca variantes con otras semillas")
    func rescate() throws {
        let p = try #require(bancoGeneradores.plantilla(id: "MAT.OPE.ECUAC.G01"))
        let fallado = try MotorGeneradores.generar(p, semilla: 123_456, recursos: bancoGeneradores.recursos)
        var cola = ColaRescate()
        cola.registrarFallo(fallado, fecha: Fx.fecha(2026, 11, 23, 9))
        let entrada = try #require(cola.entradas.first)
        #expect(bancoGeneradores.item(id: entrada.itemId) == fallado, "El id con semilla reproduce el ítem")
        var rng = GeneradorConSemilla(semilla: 9)
        let variante = cola.itemParaRescatar(entrada, banco: bancoGeneradores, excluir: [], esReciente: { _ in false }, rng: &rng)
        #expect(variante != nil && variante?.id != fallado.id && variante?.id.hasPrefix("MAT.OPE.ECUAC.G01#") == true)
        #expect(cola.registrarAcierto(variante!, banco: bancoGeneradores) != nil, "Acertar otra semilla de la plantilla rescata")
    }
}

@Suite("Avatares del propietario y fuente")
struct AvataresFuenteTests {
    @Test("Seis avatares con recurso y etiqueta descriptiva; migración id % 6")
    func avatares() {
        #expect(Avatar.todos.count == 6)
        #expect(Avatar.todos.map(\.recurso) == (1...6).map { String(format: "avatar_%02d", $0) })
        #expect(Avatar.con(id: 0)?.nombre == "gorra roja y blanca" && Avatar.con(id: 5)?.nombre == "gafas de aviador")
        #expect(Avatar.migrar(9) == 3 && Avatar.migrar(11) == 5 && Avatar.migrar(4) == 4)
        #expect(Avatar.migrar(12) == nil && Avatar.migrar(-1) == nil && Avatar.migrar(nil) == nil)
        for a in Avatar.todos { #expect(UIImage(named: a.recurso) != nil, "Falta \(a.recurso) en el Asset Catalog") }
    }

    @Test("Migración en SwiftData: un perfil con el avatar 9 (05B) pasa al 3 y se guarda")
    @MainActor
    func migracionSwiftData() throws {
        let url = URL.temporaryDirectory.appending(path: "migracion-\(UUID().uuidString).store")
        do {
            let contenedor = try EsquemaProgreso.contenedor(url: url)
            let registro = PerfilRegistro()
            registro.avatar = 9
            contenedor.mainContext.insert(registro)
            try contenedor.mainContext.save()
        }
        let repo = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(url: url))
        #expect(try repo.perfil().avatar == 3)
        let reabierto = try EsquemaProgreso.contenedor(url: url)
        #expect(try reabierto.mainContext.fetch(FetchDescriptor<PerfilRegistro>()).first?.avatar == 3, "La migración queda guardada")
    }

    @Test("Fredoka se registra y escala con Dynamic Type")
    func fuente() {
        #expect(FuenteExhibicion.registrar())
        let normal = FuenteExhibicion.uiFont(.title1, base: 28, compatibleCon: UITraitCollection(preferredContentSizeCategory: .large))
        let grande = FuenteExhibicion.uiFont(.title1, base: 28, compatibleCon: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        #expect(normal.fontName == "Fredoka-SemiBold")
        #expect(grande.pointSize > normal.pointSize * 1.5)
        #expect(Bundle.main.url(forResource: "OFL", withExtension: "txt") != nil, "La licencia va en el bundle")
    }
}

/// Estimación del espacio de cada generador con sus parámetros por defecto en los 6 niveles
/// (informe de la 05C, §13). Solo se ejecuta con `TEST_RUNNER_ESTIMAR=1`.
@Suite("Estimación del espacio (informe)", .enabled(if: ProcessInfo.processInfo.environment["ESTIMAR"] == "1"))
struct EstimacionEspacioTests {
    @Test func estimar() throws {
        var lineas: [String] = []
        let tipos = Set(bancoGeneradores.plantillas.map { "\($0.tipo)|\($0.mecanica.rawValue)" }).sorted()
        for clave in tipos {
            var p = bancoGeneradores.plantillas.first { "\($0.tipo)|\($0.mecanica.rawValue)" == clave }!
            p.parametros = p.parametros.filter { ["operacion", "variante", "familia", "agrupaciones"].contains($0.key) }
            var porNivel: [String] = []
            var total = 0
            var exacto = true
            for d in 1...6 {
                p.dificultad = d
                let g = MotorGeneradores.generador(p.tipo)!
                let n = g.enumerar(p, recursos: bancoGeneradores.recursos, limite: 3_000_000).count
                if CatalogoPreguntas.muestreados.contains(p.tipo) { exacto = false }
                porNivel.append("\(n)")
                total += n
            }
            lineas.append("ESTIMACION \(clave) | \(porNivel.joined(separator: " · ")) | total \(exacto ? "" : "≥ ")\(total)")
        }
        let r = CatalogoPreguntas.contar(bancoGeneradores)
        lineas.append("CATALOGO total \(r.exacto ? "" : "≥ ")\(r.total) · estaticos \(r.estaticos) · generados \(r.generados)")
        lineas.append("CATALOGO area " + r.porArea.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: " · "))
        lineas.append("CATALOGO bloque " + r.porBloque.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: " · "))
        lineas.append("CATALOGO dificultad " + r.porDificultad.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: " · "))
        for p in r.plantillas { lineas.append("CATALOGO plantilla \(p.id) \(p.tipo) \(p.exacto ? "" : "≥ ")\(p.variantes)") }
        let release = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        let rr = CatalogoPreguntas.contar(release)
        lineas.append("CATALOGO release total \(rr.total) · " + rr.porArea.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: " · ") + " · " + rr.porBloque.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: " · "))
        let texto = lineas.joined(separator: "\n")
        print(texto)
        try texto.write(to: URL.temporaryDirectory.appending(path: "estimacion_generadores.txt"), atomically: true, encoding: .utf8)
    }
}
