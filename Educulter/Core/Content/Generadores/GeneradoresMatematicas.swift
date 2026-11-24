import Foundation

// Generadores de Matemáticas (Fase 05C). Cada uno documenta cómo escalan sus parámetros con la
// dificultad (1–6) y qué reglas de error producen sus distractores. La solución la calcula el
// código; los tests de propiedades la comprueban con un oráculo independiente.

private func r(_ n: Int, _ d: Int = 1) -> Racional { Racional(numerador: n, denominador: d)! }

/// Payload numérico a partir de un racional (entero, decimal exacto o fracción).
private func numerico(_ v: Racional, unidad: String? = nil, irreducible: Bool? = nil) -> Payload {
    let texto = FormatoNumero.numero(v)
    let formato: Payload.Numerico.Formato = texto.contains("/") ? .fraccion : (texto.contains(",") ? .decimal : .entero)
    return .numerico(Payload.Numerico(respuesta: texto, formato: formato, tolerancia: nil, unidad: unidad,
                                      exigeIrreducible: formato == .fraccion ? irreducible : nil))
}

/// Errores habituales numéricos (respuesta = texto que teclearía el usuario), sin duplicados ni
/// coincidencias con la correcta.
private func erroresNumericos(_ correcta: Racional, _ reglas: [(Racional?, String)]) -> [ErrorHabitual] {
    var vistos: Set<String> = [FormatoNumero.numero(correcta)]
    return reglas.compactMap { v, f in
        guard let v else { return nil }
        let t = FormatoNumero.numero(v)
        guard !t.contains("/") || FormatoNumero.decimal(v) == nil, vistos.insert(t).inserted else { return nil }
        return ErrorHabitual(respuesta: t, feedback: f)
    }
}

/// Monta numérico o elección (según la mecánica de la plantilla) con los mismos errores.
private func respuesta(_ p: Plantilla, correcta: Racional, unidad: String?, reglas: [(Racional?, String)],
                       rng: inout GeneradorConSemilla) -> (Payload, [ErrorHabitual]) {
    let errores = erroresNumericos(correcta, reglas)
    if p.mecanica == .eleccion {
        let sufijo = unidad.map { " \($0)" } ?? ""
        let (e, err) = Opciones.eleccion(correcta: FormatoNumero.numero(correcta) + sufijo,
                                         distractores: errores.map { ($0.respuesta + sufijo, $0.feedback) }, rng: &rng)
        return (.eleccion(e), err)
    }
    return (numerico(correcta, unidad: unidad), errores)
}

private func digitos(_ n: Int) -> Double { n == 0 ? 1 : floor(log10(Double(abs(n)))) + 1 }

// MARK: - 3. fraccionBarras

/// Representar fracciones en una barra.
///
/// | Dif. | Modo | Fracción |
/// |---|---|---|
/// | 1 | colorear, barra en d partes | d = 2–4 |
/// | 2 | colorear | d = 2–8 |
/// | 3 | colorear con equivalentes (barra en k·d partes) | d = 2–6 |
/// | 4 | dividir y colorear (cualquier partición válida) | d = 2–6 |
/// | 5 | dividir y colorear en particiones concretas («en 6 o en 9 partes») | d = 2–4 |
/// | 6 | dividir y colorear; la fracción se da como decimal o porcentaje | d = 2, 4, 5, 10 |
struct GeneradorFraccionBarras: GeneradorItems {
    let tipo = "fraccionBarras"
    let mecanicas: Set<Mecanica> = [.fraccionBarras]
    let marcadores: Set<String> = ["fraccion", "partes", "particiones", "contexto"]

    struct Caso: Hashable { let n: Int; let d: Int; let partes: Int?; let permitidas: [Int]?; let forma: String }

    func casos(_ dif: Int) -> [Caso] {
        var out: [Caso] = []
        func propias(_ ds: [Int]) -> [(Int, Int)] { ds.flatMap { d in (1..<d).filter { Racional.mcd($0, d) == 1 }.map { ($0, d) } } }
        switch dif {
        case 1: out = propias([2, 3, 4]).map { Caso(n: $0.0, d: $0.1, partes: $0.1, permitidas: nil, forma: "fraccion") }
        case 2: out = propias(Array(2...8)).map { Caso(n: $0.0, d: $0.1, partes: $0.1, permitidas: nil, forma: "fraccion") }
        case 3:
            for (n, d) in propias(Array(2...6)) { for k in 2...6 where k * d <= 12 { out.append(Caso(n: n, d: d, partes: k * d, permitidas: nil, forma: "fraccion")) } }
        case 4: out = propias(Array(2...6)).map { Caso(n: $0.0, d: $0.1, partes: nil, permitidas: nil, forma: "fraccion") }
        case 5:
            for (n, d) in propias([2, 3, 4]) {
                let multiplos = (2...6).map { $0 * d }.filter { $0 <= 12 }
                for a in multiplos { for b in multiplos where b > a { out.append(Caso(n: n, d: d, partes: nil, permitidas: [a, b], forma: "fraccion")) } }
            }
        default:
            for (n, d) in propias([2, 4, 5, 10]) { for forma in ["decimal", "porcentaje"] { out.append(Caso(n: n, d: d, partes: nil, permitidas: nil, forma: forma)) } }
        }
        return out
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let todos = casos(p.dificultad)
        guard !todos.isEmpty else { throw ErrorGenerador.sinCaso(tipo) }
        let c = rng.elemento(todos)
        let fr = r(c.n, c.d)
        let texto: String = switch c.forma {
        case "decimal": FormatoNumero.decimal(fr) ?? "\(c.n)/\(c.d)"
        case "porcentaje": "\(FormatoNumero.numero(fr * r(100))) %"
        default: "\(c.n)/\(c.d)"
        }
        let modo: Payload.FraccionBarras.Modo = c.partes == nil ? .dividirYColorear : .colorear
        let equivalentes = c.partes.map { $0 != c.d } ?? true
        let payload = Payload.FraccionBarras(modo: modo, partes: c.partes, objetivo: "\(c.n)/\(c.d)", aceptarEquivalentes: equivalentes,
                                             particionesPermitidas: c.permitidas)
        let particiones = c.permitidas.map { $0.map(String.init).joined(separator: " o en ") } ?? ""
        var explicacion = "\(texto) = \(c.n)/\(c.d): se divide la barra en \(c.d) partes iguales y se colorean \(c.n)"
        if let partes = c.partes, partes != c.d { explicacion = "\(c.n)/\(c.d) = \(c.n * partes / c.d)/\(partes): en una barra de \(partes) partes se colorean \(c.n * partes / c.d)" }
        if let k = c.permitidas?.first { explicacion += " (en \(k) partes, \(c.n * k / c.d))" }
        let complejidad = Double(p.dificultad >= 4 ? 2 : 1) + (equivalentes ? 1 : 0) + Double(c.d) / 6 + (c.forma == "fraccion" ? 0 : 1) + (c.permitidas == nil ? 0 : 1)
        return Muestra(clave: "\(modo.rawValue)|\(c.n)/\(c.d)|\(c.partes.map(String.init) ?? "-")|\(particiones)|\(c.forma)",
                       valores: ["fraccion": texto, "partes": c.partes.map(String.init) ?? "", "particiones": particiones],
                       payload: .fraccionBarras(payload), explicacion: explicacion + ".",
                       erroresHabituales: [ErrorHabitual(respuesta: "partes", feedback: "La barra se divide en tantas partes iguales como indica el denominador (o en un múltiplo)."),
                                           ErrorHabitual(respuesta: "coloreadas", feedback: "Colorea tantas partes como indica el numerador (multiplicado si la barra tiene más partes).")],
                       pistas: ["El denominador dice en cuántas partes iguales se divide; el numerador, cuántas se toman."],
                       complejidad: complejidad, datos: ["n": "\(c.n)", "d": "\(c.d)"])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(casos(p.dificultad).map { c in
            "\(c.partes == nil ? "dividirYColorear" : "colorear")|\(c.n)/\(c.d)|\(c.partes.map(String.init) ?? "-")|\(c.permitidas.map { $0.map(String.init).joined(separator: " o en ") } ?? "")|\(c.forma)"
        }.prefix(limite))
    }
}

// MARK: - 7. mcmMcd

/// Mínimo común múltiplo y máximo común divisor, con y sin contexto.
///
/// | Dif. | Números | Contexto |
/// |---|---|---|
/// | 1 | 2 números de 2 a 12 | no |
/// | 2 | 2 números de 4 a 30 | no |
/// | 3 | 2 números de 6 a 60 | coincidencias (m.c.m.) o repartos (m.c.d.) |
/// | 4 | 3 números de 2 a 40 | no |
/// | 5 | 3 números de 6 a 100 | sí |
/// | 6 | 3 números de 2 a 12; múltiplo común entre dos cotas («entre 300 y 350») | sí |
///
/// Errores: multiplicar los números; confundir m.c.m. y m.c.d.; dar el mayor (o el menor) número.
struct GeneradorMcmMcd: GeneradorItems {
    let tipo = "mcmMcd"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["a", "b", "c", "numeros", "operacion", "min", "max", "contexto"]

    static func mcd(_ a: Int, _ b: Int) -> Int { Racional.mcd(a, b) }
    static func mcm(_ a: Int, _ b: Int) -> Int { a / mcd(a, b) * b }

    static func nivel(_ d: Int) -> (k: Int, rango: ClosedRange<Int>) {
        switch d {
        case 1: return (2, 2...12)
        case 2: return (2, 4...30)
        case 3: return (2, 6...60)
        case 4: return (3, 2...40)
        case 5: return (3, 6...100)
        default: return (3, 2...12)
        }
    }

    func resolver(_ nums: [Int], op: String, d: Int) -> (Int, cota: Int?)? {
        guard Set(nums).count == nums.count else { return nil }
        let m = nums.dropFirst().reduce(nums[0], Self.mcm), g = nums.dropFirst().reduce(nums[0], Self.mcd)
        if d == 6 {
            guard m >= 20, m <= 200 else { return nil }
            let cota = (300 / m + 1) * m - m / 2   // un único múltiplo de m en [cota, cota + m − 1]
            return ((cota + m - 1) / m * m, cota)
        }
        if op == "mcd" { return g >= 2 && !nums.contains(g) ? (g, nil) : nil }
        return m <= 600 && !nums.contains(m) ? (m, nil) : nil
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let op = p.textos("operacion", porDefecto: ["mcm"]).first ?? "mcm"
        let nv = Self.nivel(p.dificultad)
        for _ in 0..<2000 {
            let nums = (0..<nv.k).map { _ in rng.entero(nv.rango) }.sorted()
            guard let (sol, cota) = resolver(nums, op: op, d: p.dificultad) else { continue }
            let lista = nums.count == 2 ? "\(nums[0]) y \(nums[1])" : "\(nums[0]), \(nums[1]) y \(nums[2])"
            let m = nums.dropFirst().reduce(nums[0], Self.mcm), g = nums.dropFirst().reduce(nums[0], Self.mcd)
            let producto = nums.reduce(1, *)
            let nombre = op == "mcd" ? "máximo común divisor" : "mínimo común múltiplo"
            var reglas: [(Racional?, String)] = [
                (r(producto), "Multiplicar los números da un múltiplo común, pero no el menor: busca el m.c.m. con la descomposición en factores primos."),
                (op == "mcd" ? r(m) : r(g), op == "mcd" ? "Ese es el mínimo común múltiplo; aquí se pide el mayor divisor común." : "Ese es el máximo común divisor; aquí se pide el menor múltiplo común."),
                (r(op == "mcd" ? nums.first! : nums.last!), op == "mcd" ? "El menor número no siempre divide a los demás." : "El mayor número no siempre es múltiplo de los demás."),
            ]
            var explicacion = "Factores primos de \(lista). \(op == "mcd" ? "m.c.d." : "m.c.m.") = \(op == "mcd" ? g : m)."
            var valores = ["a": "\(nums[0])", "b": "\(nums[1])", "c": nums.count > 2 ? "\(nums[2])" : "", "numeros": lista,
                           "operacion": nombre, "min": "", "max": ""]
            if let cota {
                valores["min"] = "\(cota)"; valores["max"] = "\(cota + m - 1)"
                reglas.append((r(m), "Ese es el m.c.m., pero el número tiene que estar entre \(cota) y \(cota + m - 1): busca el múltiplo del m.c.m. en ese intervalo."))
                explicacion = "m.c.m.(\(lista)) = \(m). El único múltiplo de \(m) entre \(cota) y \(cota + m - 1) es \(sol)."
            }
            return Muestra(clave: "\(op)|\(nums.map(String.init).joined(separator: ","))|\(cota.map(String.init) ?? "-")", valores: valores,
                           payload: numerico(r(sol)), explicacion: explicacion, erroresHabituales: erroresNumericos(r(sol), reglas),
                           pistas: ["Descompón cada número en factores primos."],
                           complejidad: Double(nv.k) + digitos(sol) + (cota == nil ? 0 : 2) + (p.contextos == nil ? 0 : 0.5),
                           datos: ["op": op, "numeros": nums.map(String.init).joined(separator: ","), "cota": cota.map(String.init) ?? "", "respuesta": "\(sol)"])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let op = p.textos("operacion", porDefecto: ["mcm"]).first ?? "mcm"
        let nv = Self.nivel(p.dificultad)
        var claves: [String] = []
        let rango = Array(nv.rango)
        func visitar(_ nums: [Int]) -> Bool {
            if let (_, cota) = resolver(nums, op: op, d: p.dificultad) {
                claves.append("\(op)|\(nums.map(String.init).joined(separator: ","))|\(cota.map(String.init) ?? "-")")
            }
            return claves.count < limite
        }
        for i in rango.indices { for j in rango.indices where j > i {
            if nv.k == 2 { if !visitar([rango[i], rango[j]]) { return claves } } else {
                for k in rango.indices where k > j { if !visitar([rango[i], rango[j], rango[k]]) { return claves } }
            }
        } }
        return claves
    }
}

// MARK: - 8. estadisticaBasica

/// Media, mediana, moda y rango de 5–8 datos.
///
/// | Dif. | Datos | Valores | Medidas |
/// |---|---|---|---|
/// | 1 | 5 | 1–10 | moda, rango |
/// | 2 | 5 | 1–10 | + media (entera) |
/// | 3 | 6 | 1–20 | + mediana (puede ser x,5) |
/// | 4 | 7 | 1–50 | media con una cifra decimal |
/// | 5 | 8 | 10–100 | media con hasta dos decimales |
/// | 6 | 8 | decimales con una cifra (0,5–20) | todas |
///
/// Errores: dividir entre n − 1, calcular la mediana sin ordenar, dar el máximo como rango, dar
/// el valor mayor como moda.
struct GeneradorEstadistica: GeneradorItems {
    let tipo = "estadisticaBasica"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["medida", "datos", "n", "contexto"]

    static func nivel(_ d: Int) -> (n: Int, valores: [Racional], medidas: [String], maxDec: Int) {
        switch d {
        case 1: return (5, (1...10).map { r($0) }, ["moda", "rango"], 0)
        case 2: return (5, (1...10).map { r($0) }, ["moda", "rango", "media"], 0)
        case 3: return (6, (1...20).map { r($0) }, ["moda", "rango", "media", "mediana"], 1)
        case 4: return (7, (1...50).map { r($0) }, ["media", "mediana", "moda", "rango"], 1)
        case 5: return (8, (10...100).map { r($0) }, ["media", "mediana", "moda", "rango"], 2)
        default: return (8, (5...200).map { r($0, 10) }, ["media", "mediana", "moda", "rango"], 2)
        }
    }

    static func medida(_ m: String, _ datos: [Racional]) -> Racional? {
        let o = datos.sorted { $0.valorDouble < $1.valorDouble }
        switch m {
        case "media": return (datos.reduce(r(0), +) / r(datos.count))
        case "mediana": return o.count % 2 == 1 ? o[o.count / 2] : ((o[o.count / 2 - 1] + o[o.count / 2]) / r(2))
        case "rango": return o.last! - o.first!
        default:
            var freq: [Racional: Int] = [:]
            for v in datos { freq[v, default: 0] += 1 }
            let maximo = freq.values.max() ?? 0
            let modas = freq.filter { $0.value == maximo }.map(\.key)
            return maximo >= 2 && modas.count == 1 ? modas[0] : nil
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nv = Self.nivel(p.dificultad)
        let medidas = p.textos("medidas", porDefecto: nv.medidas)
        for _ in 0..<3000 {
            let m = rng.elemento(medidas)
            var datos = (0..<nv.n).map { _ in rng.elemento(nv.valores) }
            if m == "moda" { datos[rng.entero(1...(nv.n - 1))] = datos[0] }
            guard let sol = Self.medida(m, datos), let t = FormatoNumero.decimal(sol),
                  (t.split(separator: ",").dropFirst().first?.count ?? 0) <= nv.maxDec else { continue }
            let textos = datos.map(FormatoNumero.numero)
            let suma = datos.reduce(r(0), +)
            let o = datos.sorted { $0.valorDouble < $1.valorDouble }
            var reglas: [(Racional?, String)] = []
            var explicacion = ""
            switch m {
            case "media":
                reglas = [(suma / r(nv.n - 1), "La media se divide entre el número de datos (\(nv.n)), no entre \(nv.n - 1)."),
                          (suma, "Falta dividir la suma entre el número de datos.")]
                explicacion = "Media = suma : número de datos = \(FormatoNumero.numero(suma)) : \(nv.n) = \(t)."
            case "mediana":
                let sinOrdenar = nv.n % 2 == 1 ? datos[nv.n / 2] : ((datos[nv.n / 2 - 1] + datos[nv.n / 2]) / r(2))
                reglas = [(sinOrdenar, "Antes de buscar el valor central hay que ordenar los datos.")]
                explicacion = "Ordenados: \(o.map(FormatoNumero.numero).joined(separator: ", ")). Mediana = \(t)."
            case "rango":
                reglas = [(o.last!, "El rango es el mayor menos el menor, no solo el mayor."), (o.last! + o.first!, "El rango es una resta: mayor − menor.")]
                explicacion = "Rango = \(FormatoNumero.numero(o.last!)) − \(FormatoNumero.numero(o.first!)) = \(t)."
            default:
                reglas = [(o.last!, "La moda es el valor que más se repite, no el mayor.")]
                explicacion = "El valor que más se repite es \(t)."
            }
            let nombre = ["media": "media aritmética", "mediana": "mediana", "moda": "moda", "rango": "rango"][m] ?? m
            return Muestra(clave: "\(m)|\(textos.joined(separator: ";"))",
                           valores: ["medida": nombre, "datos": textos.joined(separator: "; "), "n": "\(nv.n)"],
                           payload: numerico(sol), explicacion: explicacion, erroresHabituales: erroresNumericos(sol, reglas),
                           complejidad: Double(nv.n) * 0.5 + digitos(o.last!.numerador / o.last!.denominador) + Double(t.split(separator: ",").dropFirst().first?.count ?? 0) + (m == "media" || m == "mediana" ? 1 : 0),
                           datos: ["medida": m, "datos": textos.joined(separator: ";"), "respuesta": t])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Espacio enorme (valores^n): cota inferior por semillas consecutivas.
    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

// MARK: - 9. probabilidadSimple

/// Probabilidad de Laplace en fracción: dados, bolsas y tarjetas.
///
/// | Dif. | Experimento |
/// |---|---|
/// | 1 | un dado: par, impar, mayor que k, igual a k |
/// | 2 | bolsa con bolas de 2 colores |
/// | 3 | bolsa de 3 colores; también «no sacar» un color (contrario) |
/// | 4 | tarjetas numeradas de 1 a n (n = 8–20): par, primo, múltiplo de k |
/// | 5 | dos dados: suma igual a s (fracción irreducible) |
/// | 6 | dos dados: suma mayor que s o dobles (fracción irreducible) |
///
/// Errores: favorables entre desfavorables; restar uno a los casos posibles; dar el suceso contrario.
struct GeneradorProbabilidad: GeneradorItems {
    let tipo = "probabilidadSimple"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["experimento", "suceso", "contexto"]

    struct Caso { let clave: String; let experimento: String; let suceso: String; let favorables: Int; let posibles: Int }

    static func esPrimo(_ n: Int) -> Bool { n >= 2 && (2..<n).allSatisfy { n % $0 != 0 } }

    func casos(_ d: Int) -> [Caso] {
        var out: [Caso] = []
        switch d {
        case 1:
            out.append(Caso(clave: "dado|par", experimento: "Se lanza un dado de seis caras.", suceso: "salga un número par", favorables: 3, posibles: 6))
            out.append(Caso(clave: "dado|impar", experimento: "Se lanza un dado de seis caras.", suceso: "salga un número impar", favorables: 3, posibles: 6))
            for k in 1...6 { out.append(Caso(clave: "dado|=\(k)", experimento: "Se lanza un dado de seis caras.", suceso: "salga un \(k)", favorables: 1, posibles: 6)) }
            for k in 1...4 { out.append(Caso(clave: "dado|>\(k)", experimento: "Se lanza un dado de seis caras.", suceso: "salga un número mayor que \(k)", favorables: 6 - k, posibles: 6)) }
        case 2, 3:
            let colores = ["rojas", "azules", "verdes"]
            let k = d == 2 ? 2 : 3
            func bolsas(_ resto: [Int], _ actual: [Int]) {
                if actual.count == k {
                    let total = actual.reduce(0, +)
                    let desc = zip(actual, colores).map { $0 == 1 ? "1 bola \(["rojas": "roja", "azules": "azul", "verdes": "verde"][$1] ?? $1)" : "\($0) bolas \($1)" }.joined(separator: d == 2 ? " y " : ", ")
                    for (i, c) in colores.prefix(k).enumerated() {
                        let singular = ["rojas": "roja", "azules": "azul", "verdes": "verde"][c] ?? c
                        out.append(Caso(clave: "bolsa|\(actual)|\(c)", experimento: "Una bolsa tiene \(desc).", suceso: "la bola sea \(singular)", favorables: actual[i], posibles: total))
                        if d == 3 { out.append(Caso(clave: "bolsa|\(actual)|no\(c)", experimento: "Una bolsa tiene \(desc).", suceso: "la bola no sea \(singular)", favorables: total - actual[i], posibles: total)) }
                    }
                    return
                }
                for v in resto { bolsas(resto, actual + [v]) }
            }
            bolsas(Array(1...9), [])
        case 4:
            for n in 8...20 {
                let pares = n / 2, primos = (1...n).filter(Self.esPrimo).count
                out.append(Caso(clave: "tarjetas|\(n)|par", experimento: "Hay \(n) tarjetas numeradas del 1 al \(n).", suceso: "salga un número par", favorables: pares, posibles: n))
                out.append(Caso(clave: "tarjetas|\(n)|primo", experimento: "Hay \(n) tarjetas numeradas del 1 al \(n).", suceso: "salga un número primo", favorables: primos, posibles: n))
                for k in 3...5 { out.append(Caso(clave: "tarjetas|\(n)|mult\(k)", experimento: "Hay \(n) tarjetas numeradas del 1 al \(n).", suceso: "salga un múltiplo de \(k)", favorables: n / k, posibles: n)) }
            }
        case 5:
            for s in 2...12 {
                let f = (1...6).flatMap { a in (1...6).map { a + $0 } }.filter { $0 == s }.count
                out.append(Caso(clave: "dosDados|=\(s)", experimento: "Se lanzan dos dados y se suman los puntos.", suceso: "la suma sea \(s)", favorables: f, posibles: 36))
            }
        default:
            for s in 3...10 {
                let f = (1...6).flatMap { a in (1...6).map { a + $0 } }.filter { $0 > s }.count
                out.append(Caso(clave: "dosDados|>\(s)", experimento: "Se lanzan dos dados y se suman los puntos.", suceso: "la suma sea mayor que \(s)", favorables: f, posibles: 36))
            }
            out.append(Caso(clave: "dosDados|dobles", experimento: "Se lanzan dos dados.", suceso: "salgan dobles (los dos dados iguales)", favorables: 6, posibles: 36))
        }
        return out.filter { $0.favorables > 0 && $0.favorables < $0.posibles }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let todos = casos(p.dificultad)
        guard !todos.isEmpty else { throw ErrorGenerador.sinCaso(tipo) }
        let c = rng.elemento(todos)
        let sol = r(c.favorables, c.posibles)
        let irreducible = p.dificultad >= 5
        let reglas: [(Racional?, String)] = [
            (r(c.favorables, c.posibles - c.favorables), "La probabilidad es favorables entre posibles (\(c.posibles)), no entre desfavorables."),
            (r(c.favorables, max(1, c.posibles - 1)), "Los casos posibles son \(c.posibles)."),
            (r(c.posibles - c.favorables, c.posibles), "Esa es la probabilidad del suceso contrario."),
        ]
        let respuesta = "\(sol.numerador)/\(sol.denominador)"
        var errores: [ErrorHabitual] = []
        var vistos: Set<String> = [respuesta]
        for (v, f) in reglas { if let v, v.denominador > 1, vistos.insert("\(v.numerador)/\(v.denominador)").inserted { errores.append(ErrorHabitual(respuesta: "\(v.numerador)/\(v.denominador)", feedback: f)) } }
        return Muestra(clave: c.clave, valores: ["experimento": c.experimento, "suceso": c.suceso],
                       payload: .numerico(Payload.Numerico(respuesta: respuesta, formato: .fraccion, tolerancia: nil, unidad: nil, exigeIrreducible: irreducible ? true : nil)),
                       explicacion: "Casos favorables: \(c.favorables). Casos posibles: \(c.posibles). P = \(c.favorables)/\(c.posibles)\(c.favorables * sol.denominador == c.posibles * sol.numerador && sol.denominador != c.posibles ? " = \(respuesta)" : "").",
                       erroresHabituales: errores, pistas: ["Probabilidad = casos favorables / casos posibles."],
                       complejidad: Self.complejidadEscenario(c.clave) + digitos(c.posibles) * 0.3 + (irreducible ? 0.5 : 0),
                       datos: ["clave": c.clave, "respuesta": respuesta])
    }

    /// Complejidad del experimento: un dado < bolsa de 2 colores < bolsa de 3 (y contrario) <
    /// tarjetas (primos, múltiplos) < suma de dos dados < suma mayor que / dobles.
    static func complejidadEscenario(_ clave: String) -> Double {
        let p = clave.split(separator: "|")
        switch p.first {
        case "dado": return 1
        case "bolsa": return (p[1].filter { $0 == "," }.count >= 2 ? 2.5 : 2) + (p[2].hasPrefix("no") ? 0.5 : 0)
        case "tarjetas": return 3.5 + (p[2] == "par" ? 0 : 0.5)
        default: return p[1].hasPrefix("=") ? 4.5 : 5.5
        }
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] { Array(casos(p.dificultad).map(\.clave).prefix(limite)) }
}

