import Foundation

// Generadores de Matemáticas del lote 02 (parte C): romanos, operaciones combinadas, ecuaciones,
// ordenar números, operar fracciones y problemas con fracciones. Redacciones propias: «A.2».

private typealias A = AyudaMat

// MARK: - Expresiones (operaciones combinadas y fracciones)

/// Expresión aritmética: números (enteros o fracciones), potencias, agrupaciones, sumas y productos.
indirect enum ExprArit: Sendable, Equatable {
    case n(Racional)
    case pot(Int, Int)
    case grupo(ExprArit)
    case suma([ExprArit], [Character])
    case prod([ExprArit], [Character])

    enum Token: Equatable { case num(Racional), pot(Int, Int), op(Character), abre, cierra }

    /// Analiza una lista de tokens (`+ - * :` y paréntesis).
    static func analizar(_ t: [Token]) -> ExprArit? {
        var i = 0
        func factor() -> ExprArit? {
            guard i < t.count else { return nil }
            switch t[i] {
            case .num(let v): i += 1; return .n(v)
            case .pot(let b, let e): i += 1; return .pot(b, e)
            case .abre:
                i += 1
                guard let s = suma(), i < t.count, t[i] == .cierra else { return nil }
                i += 1
                return .grupo(s)
            default: return nil
            }
        }
        func producto() -> ExprArit? {
            guard let f = factor() else { return nil }
            var fs = [f], ops: [Character] = []
            while i < t.count, case .op(let o) = t[i], o == "*" || o == ":" { i += 1; guard let g = factor() else { return nil }; fs.append(g); ops.append(o) }
            return fs.count == 1 ? f : .prod(fs, ops)
        }
        func suma() -> ExprArit? {
            guard let p = producto() else { return nil }
            var ts = [p], ops: [Character] = []
            while i < t.count, case .op(let o) = t[i], o == "+" || o == "-" { i += 1; guard let q = producto() else { return nil }; ts.append(q); ops.append(o) }
            return ts.count == 1 ? p : .suma(ts, ops)
        }
        let e = suma()
        return i == t.count ? e : nil
    }

    /// Agrupaciones anidadas dentro (0 si no hay).
    var profundidad: Int {
        switch self {
        case .n, .pot: return 0
        case .grupo(let x): return 1 + x.profundidad
        case .suma(let xs, _), .prod(let xs, _): return xs.map(\.profundidad).max() ?? 0
        }
    }

    static let superindice: [Character: Character] = ["0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"]
    static let simbolo: [Character: String] = ["+": "+", "-": "−", "*": "×", ":": ":"]

    /// Texto con paréntesis, corchetes y llaves según el anidamiento.
    var texto: String {
        switch self {
        case .n(let v): return A.fraccion(v)
        case .pot(let b, let e): return "\(b)" + String(String(e).map { Self.superindice[$0]! })
        case .grupo(let x):
            let (a, c) = [("(", ")"), ("[", "]"), ("{", "}")][min(x.profundidad, 2)]
            return a + x.texto + c
        case .suma(let xs, let ops), .prod(let xs, let ops):
            var s = xs[0].texto
            for (o, x) in zip(ops, xs.dropFirst()) { s += " \(Self.simbolo[o]!) " + x.texto }
            return s
        }
    }

    var operaciones: Int {
        switch self {
        case .n: return 0
        case .pot: return 1
        case .grupo(let x): return x.operaciones
        case .suma(let xs, let ops), .prod(let xs, let ops): return ops.count + xs.map(\.operaciones).reduce(0, +)
        }
    }

    var potencias: Int {
        switch self {
        case .pot: return 1
        case .grupo(let x): return x.potencias
        case .suma(let xs, _), .prod(let xs, _): return xs.map(\.potencias).reduce(0, +)
        default: return 0
        }
    }

    /// Reglas de cálculo: `fracciones` admite resultados no enteros; `ingenuo` suma fracciones
    /// sumando numeradores y denominadores y divide sin invertir (para los distractores).
    struct Reglas { var fracciones = false; var ingenuo = false; var maximo = 9999 }

    static func operar(_ a: Racional, _ o: Character, _ b: Racional, _ r: Reglas) -> Racional? {
        let v: Racional?
        switch o {
        case "+": v = r.ingenuo && !(a.esEntero && b.esEntero) ? Racional(numerador: a.numerador + b.numerador, denominador: a.denominador + b.denominador) : a + b
        case "-": v = r.ingenuo && !(a.esEntero && b.esEntero) ? Racional(numerador: a.numerador - b.numerador, denominador: a.denominador - b.denominador) : a - b
        case "*": v = a * b
        default:
            guard b.numerador != 0 else { return nil }
            v = r.ingenuo && !(a.esEntero && b.esEntero) ? rac(a.numerador * b.numerador, a.denominador * b.denominador) : a / b
        }
        guard let v, v.numerador >= 0, v.valorDouble <= Double(r.maximo), v.denominador <= 500, r.fracciones || v.esEntero else { return nil }
        return v
    }

    static func nombre(_ o: Character) -> String { ["+": "Sumar", "-": "Restar", "*": "Multiplicar", ":": "Dividir"][o]! }

    /// Valor con los pasos en el orden de la jerarquía: agrupaciones y potencias, después
    /// multiplicaciones y divisiones (de izquierda a derecha) y por último sumas y restas.
    func resolver(_ r: Reglas, pasos: inout [String]) -> Racional? {
        func plegar(_ vs: [Racional], _ ops: [Character]) -> Racional? {
            var v = vs[0]
            for (o, w) in zip(ops, vs.dropFirst()) {
                guard let x = Self.operar(v, o, w, r) else { return nil }
                pasos.append("\(Self.nombre(o)): \(A.fraccion(v)) \(Self.simbolo[o]!) \(A.fraccion(w)) = \(A.fraccion(x))")
                v = x
            }
            return v
        }
        switch self {
        case .n(let v): return v
        case .pot(let b, let e):
            let v = A.potencia(b, e)
            pasos.append("Potencia: \(ExprArit.pot(b, e).texto) = \(A.fraccion(v))")
            return v
        case .grupo(let x): return x.resolver(r, pasos: &pasos)
        case .prod(let fs, let ops):
            var vs: [Racional] = []
            for f in fs { guard let v = f.resolver(r, pasos: &pasos) else { return nil }; vs.append(v) }
            return plegar(vs, ops)
        case .suma(let ts, let ops):
            var parciales: [([Racional], [Character])] = []
            for t in ts {
                if case .prod(let fs, let o) = t {
                    var vs: [Racional] = []
                    for f in fs { guard let v = f.resolver(r, pasos: &pasos) else { return nil }; vs.append(v) }
                    parciales.append((vs, o))
                } else {
                    guard let v = t.resolver(r, pasos: &pasos) else { return nil }
                    parciales.append(([v], []))
                }
            }
            var valores: [Racional] = []
            for (vs, o) in parciales { guard let v = plegar(vs, o) else { return nil }; valores.append(v) }
            return plegar(valores, ops)
        }
    }

    /// Error habitual: operar de izquierda a derecha sin respetar la jerarquía (sí las agrupaciones).
    func izquierdaADerecha(_ r: Reglas) -> Racional? {
        func aplanar(_ e: ExprArit) -> [(Character, ExprArit)] {
            switch e {
            case .suma(let ts, let ops):
                var out = aplanar(ts[0])
                for (o, t) in zip(ops, ts.dropFirst()) { var f = aplanar(t); f[0].0 = o; out += f }
                return out
            case .prod(let fs, let ops):
                var out: [(Character, ExprArit)] = [(" ", fs[0])]
                for (o, f) in zip(ops, fs.dropFirst()) { out.append((o, f)) }
                return out
            default: return [(" ", e)]
            }
        }
        func valor(_ e: ExprArit) -> Racional? {
            switch e {
            case .n(let v): return v
            case .pot(let b, let k): return A.potencia(b, k)
            case .grupo(let x): return x.izquierdaADerecha(r)
            default: return e.izquierdaADerecha(r)
            }
        }
        let lista = aplanar(self)
        guard var v = valor(lista[0].1) else { return nil }
        for (o, e) in lista.dropFirst() { guard let w = valor(e), let x = Self.operar(v, o, w, r) else { return nil }; v = x }
        return v
    }

    /// La misma expresión sin agrupaciones (error habitual: ignorar los paréntesis).
    var sinAgrupar: ExprArit {
        switch self {
        case .grupo(let x): return x.sinAgrupar
        case .suma(let xs, let o): return .suma(xs.map(\.sinAgrupar), o)
        case .prod(let xs, let o): return .prod(xs.map(\.sinAgrupar), o)
        default: return self
        }
    }

    /// Texto para el oráculo de los tests (con `x`, `−`, `:`, superíndices y fracciones).
    var textoOraculo: String { texto }
}

/// Rellena un patrón: `n` número, `f` fracción, `p` potencia, `~` ±, `&` × o :, `*`, `:`, `+`, `-`, paréntesis.
private func rellenar(_ patron: String, maxN: Int, rng: inout GeneradorConSemilla) -> [ExprArit.Token] {
    patron.map { c -> ExprArit.Token in
        switch c {
        case "n": return .num(rac(rng.entero(2...maxN)))
        case "f":
            let d = rng.entero(2...9)
            return .num(rac(rng.entero(1...(d + d / 2)), d))
        case "p":
            let b = rng.entero(2...10)
            return .pot(b, b <= 5 ? rng.entero(2...3) : 2)
        case "~": return .op(rng.probabilidad(0.5) ? "+" : "-")
        case "&": return .op(rng.probabilidad(0.35) ? ":" : "*")
        case "(": return .abre
        case ")": return .cierra
        default: return .op(c)
        }
    }
}

// MARK: - C6. romanos

/// Leer (`numerico`, `eleccion`) y escribir (`construir`) números romanos.
///
/// | Dif. | Números |
/// |---|---|
/// | 1 | 1–39 |
/// | 2 | 40–399 (XL, XC) |
/// | 3 | 400–1999 (CD, CM) |
/// | 4 (examen) | 300–3999 con al menos un grupo sustractivo (2019 A M19, 2026 A M19) |
/// | 5 | 1000–3999 con al menos dos grupos sustractivos y, al escribir, siglos |
/// | 6 | `eleccion`: detectar el romano mal escrito; `numerico` y `construir`: 3 o más grupos sustractivos |
struct GeneradorRomanos: GeneradorItems {
    let tipo = "romanos"
    let mecanicas: Set<Mecanica> = [.numerico, .eleccion, .construir]
    let marcadores: Set<String> = ["pregunta", "romano", "numero", "contexto"]

    static let grupos: [[String]] = [
        ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"],
        ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"],
        ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"],
        ["", "M", "MM", "MMM"],
    ]
    static func cifras(_ n: Int) -> [Int] { [n % 10, n / 10 % 10, n / 100 % 10, n / 1000] }
    static func romano(_ n: Int) -> String { cifras(n).enumerated().reversed().map { grupos[$0.offset][$0.element] }.joined() }
    static func sustractivos(_ n: Int) -> Int { cifras(n).prefix(3).filter { $0 == 4 || $0 == 9 }.count }
    /// Lectura sumando todos los símbolos (error: no restar en IV, IX…).
    static func lecturaAditiva(_ s: String) -> Int { s.reduce(0) { $0 + (["I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000][String($1)] ?? 0) } }
    /// Romanos mal escritos (repetir V, L o D, más de tres iguales o restas no permitidas).
    static let malEscritos = ["IIII", "VV", "VX", "IC", "IL", "XM", "LL", "DD", "XXXX", "CCCC", "IIX", "VL", "XD", "LC", "IM", "MMMM"]

    static func rango(_ d: Int) -> [Int] {
        switch d {
        case 1: return Array(1...39)
        case 2: return Array(40...399)
        case 3: return Array(400...1999)
        case 4: return (300...3999).filter { sustractivos($0) >= 1 }
        case 5: return (1000...3999).filter { sustractivos($0) >= 2 }
        default: return (1000...3999).filter { sustractivos($0) >= 3 }
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let m = try muestraSinPasos(p, rng: &rng)
        if let n = m.datos["numero"].flatMap(Int.init) {
            return m.conPasos(p.mecanica == .construir ? Self.pasosEscribir(n, payload: m.payload) : Self.pasosLeer(n))
        }
        let malo = m.datos["malEscrito"] ?? ""
        return m.conPasos([Pasos.dato("Busca el que rompe una regla", "\(malo) = \(Self.lecturaAditiva(malo)) si se sumara todo, pero está mal",
                                      porque: "porque V, L y D no se repiten y solo se restan I, X y C"),
                           Pasos.solucion("Elige ese número", payload: m.payload)])
    }

    /// Valor de cada grupo de símbolos, de los millares a las unidades.
    static func gruposDe(_ n: Int) -> [(romano: String, valor: Int)] {
        cifras(n).enumerated().reversed().filter { $0.element > 0 }.map { (grupos[$0.offset][$0.element], $0.element * Int(pow(10, Double($0.offset)))) }
    }

    /// Pasos de lectura (§5): cada grupo con su valor y la suma (último valor = el número).
    static func pasosLeer(_ n: Int) -> [PasoResuelto] {
        let g = gruposDe(n)
        var conPorque = false
        var r = g.prefix(4).map { x -> PasoResuelto in
            let resta = x.romano.count == 2 && lecturaCorrecta(x.romano) < lecturaAditiva(x.romano)
            defer { if resta { conPorque = true } }
            return Pasos.op("Lee \(x.romano)", x.romano, rac(x.valor), porque: resta && !conPorque ? "porque un símbolo menor delante de uno mayor se resta" : nil)
        }
        r.append(Pasos.op("Suma los valores", g.map { A.texto(rac($0.valor)) }.joined(separator: " + "), rac(n),
                          porque: conPorque ? nil : "porque los símbolos ordenados de mayor a menor se suman"))
        return Array(r.suffix(5))
    }

    /// Pasos de escritura (§5): cada cifra en romano y, al final, construir el número con las piezas.
    static func pasosEscribir(_ n: Int, payload: Payload) -> [PasoResuelto] {
        let nombres = [1000: "los millares", 100: "las centenas", 10: "las decenas", 1: "las unidades"]
        var r = gruposDe(n).map { x in
            Pasos.dato("Escribe \(nombres[x.valor >= 1000 ? 1000 : (x.valor >= 100 ? 100 : (x.valor >= 10 ? 10 : 1))]!): \(x.valor)", "\(x.valor) = \(x.romano)", valor: x.romano)
        }
        r[0].porque = "porque cada cifra se escribe por separado, de mayor a menor"
        r.append(Pasos.solucion("Une los grupos en orden", payload: payload))
        return Array(r.suffix(5))
    }

    private func muestraSinPasos(_ p: Plantilla, rng: inout GeneradorConSemilla) throws -> Muestra {
        if p.mecanica == .eleccion && p.dificultad >= 6 { return malEscrito(rng: &rng) }
        let n = rng.elemento(Self.rango(p.dificultad))
        // Siglos al escribir (dificultad 5): el siglo del año.
        if p.mecanica == .construir && p.dificultad == 5 && n <= 2100 && rng.probabilidad(0.4) {
            let siglo = (n - 1) / 100 + 1
            return escribir(siglo, pregunta: "¿En qué siglo está el año \(n)? Escríbelo en números romanos.", extra: 4.5, clave: "construir|siglo|\(n)", rng: &rng)   // A.2
        }
        let r = Self.romano(n)
        let extra = p.dificultad >= 5 ? 1.5 : 0
        switch p.mecanica {
        case .construir: return escribir(n, pregunta: "Escribe en números romanos: \(n)", extra: extra, clave: "construir|\(n)", rng: &rng)
        default:
            let pregunta = p.mecanica == .eleccion ? "¿Qué número es \(r)?" : "Escribe en cifras: \(r)"   // A.2 (elección)
            let aditiva = Self.lecturaAditiva(r)
            var reglas: [(Racional?, String)] = [(rac(aditiva), "Un símbolo menor delante de uno mayor se resta: IV es 4, no 6.")]
            for (k, c) in Self.cifras(n).enumerated() where c > 0 {
                let paso = Int(pow(10, Double(k)))
                reglas.append((rac(n + paso), "Revisa \(Self.grupos[k][c]): vale \(c * paso)."))
                reglas.append((rac(n - paso), "Revisa \(Self.grupos[k][c]): vale \(c * paso)."))
            }
            let (payload, errores) = p.mecanica == .eleccion ? A.eleccionNumerica(rac(n), reglas, rng: &rng) : (A.numerico(rac(n), unidad: nil), A.errores(rac(n), reglas))
            return Muestra(clave: "\(p.mecanica.rawValue)|\(n)", valores: ["pregunta": pregunta, "romano": r, "numero": "\(n)"], payload: payload,
                           explicacion: explicacion(n), erroresHabituales: errores,
                           pistas: ["I = 1, V = 5, X = 10, L = 50, C = 100, D = 500 y M = 1000."],
                           complejidad: complejidad(n, extra: extra), datos: ["romano": r, "numero": "\(n)"])
        }
    }

    private func explicacion(_ n: Int) -> String {
        let partes = Self.cifras(n).enumerated().reversed().filter { $0.element > 0 }.map { "\(Self.grupos[$0.offset][$0.element]) = \($0.element * Int(pow(10, Double($0.offset))))" }
        return "\(Self.romano(n)) = \(partes.joined(separator: " + ")) = \(n)."
    }

    private func complejidad(_ n: Int, extra: Double) -> Double {
        Double(Self.romano(n).count) * 0.5 + Double(Self.sustractivos(n)) + A.cifras(n) * 0.5 + extra
    }

    private func escribir(_ n: Int, pregunta: String, extra: Double, clave: String, rng: inout GeneradorConSemilla) -> Muestra {
        let partes = Self.cifras(n).enumerated().reversed().filter { $0.element > 0 }.map { (id: ["u", "d", "c", "m"][$0.offset], texto: Self.grupos[$0.offset][$0.element]) }
        var textos = Set(partes.map(\.texto))
        let falsos = rng.barajar(Self.malEscritos).filter { textos.insert($0).inserted }.prefix(3)
        let piezas = rng.barajar(partes.map(\.texto) + falsos).enumerated().map { ElementoTexto(id: "p\($0.offset + 1)", texto: $0.element) }
        let huecos = partes.map { h in Payload.Construir.Hueco(id: h.id, correcta: piezas.first { $0.texto == h.texto }!.id) }
        return Muestra(clave: clave, valores: ["pregunta": pregunta, "romano": Self.romano(n), "numero": "\(n)"],
                       payload: .construir(Payload.Construir(plantilla: partes.map { "{\($0.id)}" }.joined(), huecos: huecos, piezas: piezas)),
                       explicacion: explicacion(n),
                       erroresHabituales: [ErrorHabitual(respuesta: "construir", feedback: "V, L y D no se repiten; I, X y C se repiten como mucho tres veces, y solo se resta I de V y X, X de L y C, y C de D y M.")],
                       pistas: ["Escribe cada cifra por separado: millares, centenas, decenas y unidades."],
                       complejidad: complejidad(n, extra: extra), datos: ["numero": "\(n)", "romano": Self.romano(n)])
    }

    /// Dificultad 6 con elección: ¿cuál está mal escrito?
    private func malEscrito(rng: inout GeneradorConSemilla) -> Muestra {
        let malo = rng.elemento(Self.malEscritos)
        let prefijo = rng.elemento(["", "M", "C", "X", "MC", "DC", "CX"])
        let incorrecto = prefijo + malo
        var correctos: [String] = []
        while correctos.count < 3 {
            let r = Self.romano(rng.entero(4...3999))
            if !correctos.contains(r) && r != incorrecto { correctos.append(r) }
        }
        let (e, _) = Opciones.eleccion(correcta: incorrecto, distractores: correctos.map { ($0, "\($0) está bien escrito: es \(Self.lecturaCorrecta($0)).") }, rng: &rng)
        let errores = e.opciones.filter { $0.id != e.correcta }.map { ErrorHabitual(respuesta: $0.id, feedback: "\($0.texto) está bien escrito: es \(Self.lecturaCorrecta($0.texto)). Busca el que repite V, L o D, repite más de tres veces o resta de forma no permitida.") }
        return Muestra(clave: "mal|\(incorrecto)|\(correctos.joined(separator: ","))", valores: ["pregunta": "¿Cuál de estos números romanos está mal escrito?", "romano": incorrecto, "numero": ""],
                       payload: .eleccion(e),
                       explicacion: "\(incorrecto) está mal escrito: V, L y D no se repiten; I, X y C, como mucho tres veces; y solo se resta I de V y X, X de L y C, y C de D y M.",
                       erroresHabituales: errores, complejidad: 9 + Double(incorrecto.count) * 0.2,
                       datos: ["malEscrito": incorrecto, "opciones": e.opciones.map(\.texto).joined(separator: ",")])
    }

    static func lecturaCorrecta(_ s: String) -> Int {
        let v = s.map { ["I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000][String($0)] ?? 0 }
        return v.indices.reduce(0) { $0 + ($1 + 1 < v.count && v[$1] < v[$1 + 1] ? -v[$1] : v[$1]) }
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        if p.mecanica == .eleccion && p.dificultad >= 6 { return [] }
        var claves = Self.rango(p.dificultad).map { "\(p.mecanica.rawValue)|\($0)" }
        if p.mecanica == .construir && p.dificultad == 5 { claves += Self.rango(5).map { "construir|siglo|\($0)" } }
        return Array(claves.prefix(limite))
    }
}

// MARK: - C7. operacionesCombinadas

/// Operaciones combinadas. `parametros.agrupaciones` = false (MAT.OPE.JER, solo jerarquía) o
/// true (MAT.OPE.COMB). Con `ordenar` se ordenan los pasos; con `numerico`, se da el resultado.
///
/// | Dif. | JER (sin agrupaciones) | COMB |
/// |---|---|---|
/// | 1 | 3 números, + y × | 3 números con paréntesis |
/// | 2 | 4 números, + − × : (división exacta) | 4 números con paréntesis |
/// | 3 | 5 números | paréntesis (uno o dos) |
/// | 4 (examen) | 6 números | paréntesis y corchetes, 7 operaciones con números de hasta dos cifras (2019 M20) |
/// | 5 | 5 números y una potencia | llaves y potencias |
/// | 6 | 4 fracciones | fracciones con paréntesis |
struct GeneradorOperacionesCombinadas: GeneradorItems {
    let tipo = "operacionesCombinadas"
    let mecanicas: Set<Mecanica> = [.numerico, .ordenar]
    let marcadores: Set<String> = ["pregunta", "expresion", "contexto"]

    static func patrones(_ d: Int, agrupaciones: Bool) -> (patrones: [String], maxN: Int) {
        if agrupaciones {
            switch d {
            case 1: return (["(n~n)*n", "n*(n~n)", "(n+n):n"], 10)
            case 2: return (["(n~n)&n~n", "n~n&(n~n)", "n&(n~n)~n", "(n~n)*(n~n)"], 12)
            case 3: return (["(n~n)&n~(n~n)", "n&(n~n&n)~n", "(n~n&n)&n~n", "n~(n~n)&(n~n)"], 15)
            // Perfil del examen: dos niveles de agrupación y 7 operaciones («[(16 × 8 + 12) : 4] + [3 (38 − 5 × 4)]»).
            case 4: return (["((n&n~n)&n)~(n&(n~n&n))", "((n~n)&n~n)&n~(n&n~n)", "(n&(n~n)~n)&n~((n~n)&n)"], 20)
            case 5: return (["(((n~n)&n~n)&n~p)&n", "n~(((n~n)&n~p)&n~n)", "p~((n~(n~n)&n)~n)&n"], 12)
            default: return (["(f~f)*f~f", "f*(f~f)~f", "(f~f):f~f", "f~f*(f~f)"], 9)
            }
        }
        switch d {
        case 1: return (["n+n*n", "n*n+n"], 10)
        case 2: return (["n~n&n~n", "n&n~n&n", "n~n&n&n", "n&n&n~n"], 12)
        case 3: return (["n~n&n~n&n", "n&n~n&n~n", "n&n&n~n~n", "n~n~n&n&n"], 15)
        case 4: return (["n&n~n&n~n&n", "n~n&n&n~n~n", "n&n~n~n&n&n"], 20)
        case 5: return (["p~n&n~n&n", "n&p~n&n~n", "n~p&n~n&n"], 15)
        default: return (["f~f*f~f", "f*f~f~f", "f~f~f*f"], 9)
        }
    }

    func caso(_ p: Plantilla, rng: inout GeneradorConSemilla) -> (ExprArit, Racional, [String])? {
        let agrup = p.parametros["agrupaciones"].map { if case .booleano(let b) = $0 { b } else { false } } ?? false
        let (pats, maxN) = Self.patrones(p.dificultad, agrupaciones: agrup)
        let fracciones = p.dificultad >= 6
        for _ in 0..<4000 {
            guard let e = ExprArit.analizar(rellenar(rng.elemento(pats), maxN: maxN, rng: &rng)) else { continue }
            var pasos: [String] = []
            guard let v = e.resolver(ExprArit.Reglas(fracciones: fracciones, maximo: 999), pasos: &pasos) else { continue }
            if fracciones && (v.esEntero || v.denominador > 60) { continue }
            if Set(pasos).count != pasos.count { continue }
            return (e, v, pasos)
        }
        return nil
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let (e, v, pasos) = caso(p, rng: &rng) else { throw ErrorGenerador.sinCaso(tipo) }
        let m = muestraSinPasos(p, e: e, v: v, pasos: pasos, rng: &rng)
        return m.conPasos(Self.pasosResueltos(pasos, agrupaciones: e.profundidad > 0, payload: p.mecanica == .ordenar ? m.payload : nil))
    }

    /// Pasos del ejemplo resuelto (§5): las operaciones en el orden de la jerarquía (las del
    /// resolutor), agrupadas para que no pasen de 5. Con `ordenar`, el último paso es ordenar.
    static func pasosResueltos(_ operaciones: [String], agrupaciones: Bool, payload: Payload?) -> [PasoResuelto] {
        let maximo = payload == nil ? 5 : 4
        let tam = Int((Double(operaciones.count) / Double(maximo)).rounded(.up))
        let verbos = ["Sumar": "suma", "Restar": "resta", "Multiplicar": "multiplica", "Dividir": "divide", "Potencia": "calcula la potencia"]
        var r: [PasoResuelto] = stride(from: 0, to: operaciones.count, by: max(tam, 1)).enumerated().map { k, i in
            let grupo = operaciones[i..<min(i + tam, operaciones.count)]
            let nombres = grupo.map { String($0.prefix { $0 != ":" }) }
            let cuentas = grupo.map(ExprArit.sinNombre)
            let valor = cuentas.last!.components(separatedBy: " = ").last!
            var verbosGrupo: [String] = []
            for n in nombres where !verbosGrupo.contains(verbos[n] ?? n.lowercased()) { verbosGrupo.append(verbos[n] ?? n.lowercased()) }
            let frase = verbosGrupo.count == 1 ? verbosGrupo[0].prefix(1).uppercased() + verbosGrupo[0].dropFirst()
                : (k == 0 ? "Empieza: " : "Después, ") + verbosGrupo.joined(separator: " y ")
            return PasoResuelto(frase: String(frase), resultado: cuentas.joined(separator: "; "), valor: valor)
        }
        if r.count == 1 { r.insert(Pasos.dato("Mira qué operación va primero", operaciones.first.map(ExprArit.sinNombre) ?? ""), at: 0) }
        r[0].porque = agrupaciones ? "porque lo que está entre paréntesis se calcula antes" : "porque × y : se hacen antes que + y −"
        if let payload { r.append(Pasos.solucion("Ordena los pasos así", payload: payload)) }
        return r
    }

    private func muestraSinPasos(_ p: Plantilla, e: ExprArit, v: Racional, pasos: [String], rng: inout GeneradorConSemilla) -> Muestra {
        let fracciones = p.dificultad >= 6
        let reglas = ExprArit.Reglas(fracciones: true, maximo: 100_000)
        let complejidad = Double(e.operaciones - e.potencias) * (fracciones ? 3.5 : 1) + Double(e.potencias) * 1.5 + Double(e.profundidad) + 0.3 * A.log(v)
        let explicacion = "Primero paréntesis, después potencias, multiplicaciones y divisiones, y por último sumas y restas: " + pasos.map(ExprArit.sinNombre).joined(separator: "; ") + "."
        let datos = ["expresion": e.texto, "respuesta": A.fraccion(v)]
        if p.mecanica == .ordenar {
            let fichas = pasos.enumerated().map { ElementoTexto(id: "s\($0.offset + 1)", texto: $0.element) }
            return Muestra(clave: "ordenar|" + e.texto, valores: ["pregunta": "Ordena los pasos para calcular \(e.texto).", "expresion": e.texto],   // A.2
                           payload: .ordenar(Payload.Ordenar(fichas: rng.barajar(fichas), ordenCorrecto: fichas.map(\.id), etiquetaInicio: "Primer paso", etiquetaFin: "Último paso")),
                           explicacion: explicacion,
                           erroresHabituales: [ErrorHabitual(respuesta: "orden", feedback: "Primero paréntesis, después multiplicaciones y divisiones, y por último sumas y restas.")],
                           pistas: ["Empieza por lo que está entre paréntesis."], complejidad: complejidad, datos: datos)
        }
        var errores: [(Racional?, String)] = [(e.izquierdaADerecha(reglas), "Primero paréntesis, después multiplicaciones y divisiones, y por último sumas y restas.")]
        if e.profundidad > 0 {
            var nada: [String] = []
            errores.append((e.sinAgrupar.resolver(reglas, pasos: &nada), "Lo que está entre paréntesis se calcula primero."))
        }
        if fracciones {
            var nada: [String] = []
            errores.append((e.resolver(ExprArit.Reglas(fracciones: true, ingenuo: true, maximo: 100_000), pasos: &nada), "Para sumar fracciones, primero se busca un denominador común."))
        }
        return Muestra(clave: "numerico|" + e.texto, valores: ["pregunta": "Calcula: \(e.texto)", "expresion": e.texto],   // A.2
                       payload: A.numerico(v, unidad: nil, comoFraccion: fracciones), explicacion: explicacion,
                       erroresHabituales: A.errores(v, errores, comoFraccion: fracciones),
                       pistas: ["Primero paréntesis, después multiplicaciones y divisiones, y por último sumas y restas."],
                       complejidad: complejidad, datos: datos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 19)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 3000) { if let (e, _, _) = caso(p, rng: &rng) { vistos.insert("\(p.mecanica.rawValue)|" + e.texto) } }
        return Array(vistos)
    }
}

// MARK: - C8. ecuacionLineal

/// Ecuaciones de primer grado con solución entera (MAT.OPE.ECUAC).
///
/// | Dif. | Ecuación |
/// |---|---|
/// | 1 | x + a = b |
/// | 2 | ax = b |
/// | 3 | ax + b = c (o ax − b = c) |
/// | 4 | incógnita en los dos miembros |
/// | 5 | paréntesis |
/// | 6 | problema con enunciado («el triple de un número menos 7 es 20») |
struct GeneradorEcuacionLineal: GeneradorItems {
    let tipo = "ecuacionLineal"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["pregunta", "x", "ecuacion", "contexto"]

    static func signo(_ n: Int) -> String { n < 0 ? "− \(-n)" : "+ \(n)" }
    static func coef(_ a: Int) -> String { a == 1 ? "x" : "\(a)x" }
    static let veces = [2: "doble", 3: "triple", 4: "cuádruple", 5: "quíntuple"]

    struct Caso {
        let ecuacion: String; let x: Int; let pasos: Double; let reglas: [(Int?, String)]; let enunciado: String?
        /// Ejemplo resuelto (§5).
        var resueltos: [PasoResuelto] = []
        func con(_ p: [PasoResuelto]) -> Caso { var c = self; c.resueltos = p; return c }
    }

    static let porqueTransponer = "porque lo que suma en un miembro pasa restando al otro"
    static func dividir(_ c: Int, _ a: Int, _ x: Int) -> PasoResuelto {
        Pasos.op("Divide entre \(a) para dejar la x sola", "\(c) : \(a < 0 ? "(\(a))" : "\(a)")", rac(x))
    }

    func caso(_ d: Int, rng: inout GeneradorConSemilla) -> Caso {
        let transponer = "Al pasar un término al otro miembro, cambia de signo: lo que suma pasa restando y lo que resta pasa sumando."
        let dividir = "Lo que multiplica a la x pasa dividiendo, no restando."
        switch d {
        case 1:
            let x = rng.entero(1...20), a = rng.entero(1...20)
            return Caso(ecuacion: "x + \(a) = \(x + a)", x: x, pasos: 1, reglas: [(x + 2 * a, transponer)], enunciado: nil)
                .con([Pasos.dato("Pasa el \(a) al otro miembro restando", "x = \(x + a) − \(a)", porque: Self.porqueTransponer),
                      Pasos.op("Resta", "\(x + a) − \(a)", rac(x))])
        case 2:
            let a = rng.entero(2...10), x = rng.entero(1...12)
            return Caso(ecuacion: "\(a)x = \(a * x)", x: x, pasos: 1.5, reglas: [(a * x - a, dividir), (a * a * x, "Lo que multiplica pasa dividiendo, no multiplicando.")], enunciado: nil)
                .con([Pasos.dato("El \(a) multiplica a la x: pasa dividiendo", "x = \(a * x) : \(a)", porque: "porque dividir deshace la multiplicación"),
                      Self.dividir(a * x, a, x)])
        case 3:
            let a = rng.entero(2...9), x = rng.entero(1...15), b = rng.entero(1...30) * (rng.probabilidad(0.5) ? 1 : -1)
            let c = a * x + b
            let error = (c + b) % a == 0 ? (c + b) / a : nil
            return Caso(ecuacion: "\(Self.coef(a)) \(Self.signo(b)) = \(c)", x: x, pasos: 2.5, reglas: [(error, transponer), (c - b - a, dividir)], enunciado: nil)
                .con([Pasos.dato("Pasa el \(abs(b)) al otro miembro", "\(Self.coef(a)) = \(c) \(b > 0 ? "−" : "+") \(abs(b)) = \(a * x)", valor: "\(a * x)",
                                 porque: Self.porqueTransponer),
                      Self.dividir(a * x, a, x)])
        case 4:
            let a = rng.entero(2...9), c = rng.entero(1...8), x = rng.entero(-10...15), b = rng.entero(-20...20)
            guard a != c else { return caso(d, rng: &rng) }
            let dd = (a - c) * x + b
            let e1 = (a + c) != 0 && (dd - b) % (a + c) == 0 ? (dd - b) / (a + c) : nil
            let e2 = (dd + b) % (a - c) == 0 ? (dd + b) / (a - c) : nil
            return Caso(ecuacion: "\(Self.coef(a)) \(Self.signo(b)) = \(Self.coef(c)) \(Self.signo(dd))", x: x, pasos: 3.5 + (x < 0 ? 0.5 : 0), reglas: [(e2, transponer), (e1, "Al pasar \(Self.coef(c)) al primer miembro, cambia de signo: resta.")], enunciado: nil)
                .con([Pasos.dato("Pasa las x a un miembro y los números al otro", "\(Self.coef(a)) − \(Self.coef(c)) = \(dd) \(b > 0 ? "−" : "+") \(abs(b))",
                                 porque: "porque al cambiar de miembro, cada término cambia de signo"),
                      Pasos.dato("Opera en cada miembro", "\((a - c) == 1 ? "x" : "\(a - c)x") = \(dd - b)", valor: "\(dd - b)"),
                      Self.dividir(dd - b, a - c, x)])
        case 5:
            let a = rng.entero(2...6), b = rng.entero(-9...9), x = rng.entero(-10...15)
            guard b != 0 else { return caso(d, rng: &rng) }
            let c = a * (x + b)
            let sinDistribuir = (c - b) % a == 0 ? (c - b) / a : nil
            return Caso(ecuacion: "\(a)(x \(Self.signo(b))) = \(c)", x: x, pasos: 4.5 + (x < 0 ? 0.5 : 0),
                        reglas: [(sinDistribuir, "Multiplica \(a) por todos los términos del paréntesis."), (c / a + b, transponer)], enunciado: nil)
                .con([Pasos.dato("Quita el paréntesis: multiplica \(a) por todo", "\(a)x \(Self.signo(a * b)) = \(c)",
                                 porque: "porque el \(a) multiplica a todo lo que hay dentro"),
                      Pasos.dato("Pasa el \(abs(a * b)) al otro miembro", "\(a)x = \(c - a * b)", valor: "\(c - a * b)"),
                      Self.dividir(c - a * b, a, x)])
        default:
            let k = rng.entero(2...5), x = rng.entero(2...20)
            switch rng.entero(0...2) {
            case 0:
                let b = rng.entero(1...15), resta = rng.probabilidad(0.5) && k * x - b > 0
                let c = resta ? k * x - b : k * x + b
                let texto = "El \(Self.veces[k]!) de un número \(resta ? "menos" : "más") \(b) es \(c). ¿Cuál es el número?"
                let e = (resta ? (c - b) : (c + b)) % k == 0 ? (resta ? (c - b) : (c + b)) / k : nil
                return Caso(ecuacion: "\(k)x \(resta ? "− \(b)" : "+ \(b)") = \(c)", x: x, pasos: 4.5, reglas: [(e, transponer)], enunciado: texto)
                    .con([Pasos.dato("Escribe la ecuación", "\(k)x \(resta ? "− \(b)" : "+ \(b)") = \(c)",
                                     porque: "porque «el \(Self.veces[k]!) de un número» se escribe \(k)x"),
                          Pasos.dato("Pasa el \(b) al otro miembro", "\(k)x = \(resta ? c + b : c - b)", valor: "\(k * x)"),
                          Self.dividir(k * x, k, x)])
            case 1:
                let c = (k + 1) * x
                return Caso(ecuacion: "x + \(k)x = \(c)", x: x, pasos: 4.5, reglas: [(c / k, "El número también cuenta: x + \(k)x = \(k + 1)x.")],
                            enunciado: "La suma de un número y su \(Self.veces[k]!) es \(c). ¿Cuál es el número?")
                    .con([Pasos.dato("Escribe la ecuación", "x + \(k)x = \(c)", porque: "porque el número es x y su \(Self.veces[k]!), \(k)x"),
                          Pasos.dato("Junta las x", "\(k + 1)x = \(c)", valor: "\(c)"),
                          Self.dividir(c, k + 1, x)])
            default:
                let b = rng.entero(1...9), c = k * (x - b)
                guard c > 0 else { return caso(d, rng: &rng) }
                return Caso(ecuacion: "\(k)(x − \(b)) = \(c)", x: x, pasos: 5.5, reglas: [(c / k - b, transponer), ((c + b) % k == 0 ? (c + b) / k : nil, "Multiplica \(k) por todo el paréntesis.")],
                            enunciado: "Si a un número le restas \(b) y multiplicas el resultado por \(k), obtienes \(c). ¿Cuál es el número?")
                    .con([Pasos.dato("Escribe la ecuación", "\(k)(x − \(b)) = \(c)", porque: "porque primero se resta y después se multiplica"),
                          Pasos.op("Divide los dos miembros entre \(k)", "x − \(b) = \(c) : \(k)", rac(c / k)),
                          Pasos.op("Suma \(b) a los dos miembros", "\(c / k) + \(b)", rac(x))])
            }
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let c = caso(p.dificultad, rng: &rng)
        let sol = rac(c.x)
        // Los errores negativos también se admiten (el teclado tiene signo): se filtran solo los iguales.
        let errores = c.reglas.compactMap { v, f -> ErrorHabitual? in
            guard let v, v != c.x else { return nil }
            return ErrorHabitual(respuesta: "\(v)", feedback: f)
        }
        var vistos = Set<String>()
        let unicos = errores.filter { vistos.insert($0.respuesta).inserted }
        let pregunta = c.enunciado ?? "Calcula el valor de x: \(c.ecuacion)"
        return Muestra(clave: c.enunciado ?? c.ecuacion, valores: ["pregunta": pregunta, "x": "x", "ecuacion": c.ecuacion],
                       payload: A.numerico(sol, unidad: nil),
                       explicacion: "\(c.ecuacion) → x = \(c.x). Comprobación: sustituye x por \(c.x) y los dos miembros valen lo mismo.",
                       erroresHabituales: unicos, pistas: ["Deja la x sola en un miembro: lo que suma pasa restando y lo que multiplica pasa dividiendo."],
                       complejidad: c.pasos + 0.2 * A.cifras(abs(c.x)) + (c.enunciado == nil ? 0 : 1),
                       datos: ["ecuacion": c.ecuacion.replacingOccurrences(of: "−", with: "-"), "x": "\(c.x)"])
            .conPasos(c.resueltos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 23)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 20_000) { let c = caso(p.dificultad, rng: &rng); vistos.insert(c.enunciado ?? c.ecuacion) }
        return Array(vistos)
    }
}

// MARK: - C9. ordenarNumeros

/// Ordenar de menor a mayor (MAT.NUM.ORDEN).
///
/// | Dif. | Cantidad | Números |
/// |---|---|---|
/// | 1 | 4 | decimales con una cifra decimal |
/// | 2 | 4 | decimales con dos cifras decimales |
/// | 3 | 5 | decimales con distinto número de cifras (0,5 frente a 0,45), o fracciones con el mismo denominador o numerador |
/// | 4 (examen) | 4 | fracciones (denominador ≤ 24, también impropias) y decimales (1–3 cifras) mezclados |
/// | 5 | 5 | mezclados, todos entre dos enteros consecutivos (valores muy cercanos) |
/// | 6 | 6 | con negativos y fracciones impropias |
///
/// Calibración de la Fase 05E (`Content/calibracion/anclas.json`): el nivel 4 reproduce el perfil
/// de las preguntas oficiales de ordenar (2017 M11, 2019 M14, 2026 A M14).
struct GeneradorOrdenarNumeros: GeneradorItems {
    let tipo = "ordenarNumeros"
    let mecanicas: Set<Mecanica> = [.ordenar]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    /// Números (valor y texto) del caso.
    func numeros(_ d: Int, rng: inout GeneradorConSemilla) -> [(Racional, String)] {
        func dec(_ v: Racional) -> (Racional, String) { (v, FormatoNumero.decimal(v)!) }
        func fr(_ v: Racional) -> (Racional, String) { (v, A.fraccion(v)) }
        switch d {
        case 1: let e = rng.entero(0...8); return (0..<4).map { _ in dec(rac(e * 10 + rng.entero(1...19), 10)) }
        case 2: let e = rng.entero(0...5); return (0..<4).map { _ in dec(rac(e * 100 + rng.entero(1...150), 100)) }
        case 3:
            if rng.probabilidad(0.5) { return (0..<5).map { _ in dec(rac(rng.entero(1...999), rng.elemento([10, 100, 1000]))) } }
            if rng.probabilidad(0.5) { let den = rng.entero(5...12); return (0..<5).map { _ in fr(rac(rng.entero(1...(2 * den)), den)) } }
            let num = rng.entero(1...9); return (0..<5).map { _ in fr(rac(num, rng.entero(2...12))) }
        case 4:
            return (0..<4).map { _ in
                if rng.probabilidad(0.5) { let den = rng.entero(2...24); return fr(rac(rng.entero(1...(2 * den)), den)) }
                // Decimales de 1 a 3 cifras entre 0 y 2,5, como en el examen (0,5; 1,18; 1,205).
                let k = rng.elemento([1, 10, 100])
                return dec(rac(rng.entero(1...(25 * k)), 10 * k))
            }
        case 5:
            let e = rng.entero(0...2)
            return (0..<5).map { _ in
                if rng.probabilidad(0.5) { let den = rng.entero(2...24); return fr(rac(e * den + rng.entero(1...(den - 1)), den)) }
                return dec(rac(e * 1000 + rng.entero(1...999), rng.elemento([100, 1000])))
            }
        default:
            return (0..<6).map { _ in
                switch rng.entero(0...2) {
                case 0: return dec(rac(rng.entero(-25...30), 10))
                case 1: return fr(rac(rng.entero(-12...20), rng.entero(2...8)))
                default: return fr(rac(rng.entero(5...20), rng.entero(2...4)))
                }
            }
        }
    }

    func caso(_ d: Int, rng: inout GeneradorConSemilla) -> [(Racional, String)]? {
        for _ in 0..<500 {
            let ns = numeros(d, rng: &rng)
            guard Set(ns.map(\.0)).count == ns.count, Set(ns.map(\.1)).count == ns.count, ns.allSatisfy({ !$0.0.esEntero }) else { continue }
            if d == 3 && Set(ns.map { $0.1.count }).count < 2 { continue }
            if d == 3 && ns.allSatisfy({ $0.1.contains("/") }) && Set(ns.map { $0.0.denominador }).count > 1 && Set(ns.map { $0.0.numerador }).count > 1 { continue }
            if (d == 4 || d == 5) && !(ns.contains { $0.1.contains("/") } && ns.contains { $0.1.contains(",") }) { continue }
            if d == 6 && !(ns.contains { $0.0.numerador < 0 } && ns.contains { $0.1.contains("/") && $0.0.numerador > $0.0.denominador }) { continue }
            return ns
        }
        return nil
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let ns = caso(p.dificultad, rng: &rng) else { throw ErrorGenerador.sinCaso(tipo) }
        let ordenados = ns.sorted { A.menor($0.0, $1.0) }
        let fichas = ns.enumerated().map { ElementoTexto(id: "n\($0.offset + 1)", texto: $0.element.1) }
        let orden = ordenados.map { o in fichas.first { $0.texto == o.1 }!.id }
        let tipoPeso: Double = [1: 0, 2: 0.5, 3: 1.5, 4: 3.5, 5: 4, 6: 5][p.dificultad] ?? 5
        return Muestra(clave: ns.map(\.1).sorted().joined(separator: ";"), valores: ["pregunta": "Ordena de menor a mayor."],
                       payload: .ordenar(Payload.Ordenar(fichas: fichas, ordenCorrecto: orden, etiquetaInicio: "Menor", etiquetaFin: "Mayor")),
                       explicacion: "De menor a mayor: \(ordenados.map(\.1).joined(separator: " < ")).",
                       erroresHabituales: [ErrorHabitual(respuesta: "orden", feedback: "Iguala las cifras decimales antes de comparar (0,5 = 0,50 > 0,45) y pasa las fracciones a decimal o a común denominador.")],
                       pistas: ["Compara primero la parte entera y después las décimas, las centésimas…"],
                       complejidad: Double(ns.count) + tipoPeso, datos: ["orden": "asc"])
            .conPasosOrdenar(ns)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 29)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 5000) { if let ns = caso(p.dificultad, rng: &rng) { vistos.insert(ns.map(\.1).sorted().joined(separator: ";")) } }
        return Array(vistos)
    }
}

extension Muestra {
    /// Pasos de ordenar números (§5): las fracciones a decimal, las cifras decimales igualadas y, al
    /// final, el orden.
    fileprivate func conPasosOrdenar(_ ns: [(Racional, String)]) -> Muestra {
        func fijo(_ v: Racional, _ cifras: Int) -> String {
            String(format: "%.\(cifras)f", v.valorDouble).replacingOccurrences(of: ".", with: ",")
        }
        let cifras = min(3, ns.map { AyudaMat.decimales($0.0) ?? 3 }.max() ?? 1)
        var pasos: [PasoResuelto] = []
        let fracciones = ns.filter { $0.1.contains("/") }
        if !fracciones.isEmpty {
            let lista = fracciones.map { f in AyudaMat.decimales(f.0).map { _ in "\(f.1) = \(FormatoNumero.decimal(f.0)!)" } ?? "\(f.1) ≈ \(fijo(f.0, 3))" }
            pasos.append(Pasos.dato("Pasa cada fracción a número decimal", lista.joined(separator: "; "),
                                    porque: "porque así todos los números se comparan de la misma forma"))
        }
        pasos.append(Pasos.dato("Iguala las cifras decimales y compara", ns.map { fijo($0.0, fracciones.isEmpty ? cifras : 3) }.joined(separator: " · "),
                                porque: fracciones.isEmpty ? "porque 0,5 es lo mismo que 0,50: los ceros del final no cambian nada" : nil))
        pasos.append(Pasos.solucion("Ordénalos de menor a mayor", payload: payload))
        return conPasos(pasos)
    }
}

// MARK: - C10. fraccionesOperar

/// Operar con fracciones; resultado irreducible (MAT.NUM.FRAOP).
///
/// | Dif. | Caso |
/// |---|---|
/// | 1 | suma o resta con el mismo denominador |
/// | 2 | denominadores múltiplos |
/// | 3 | m.c.m. de dos denominadores ≤ 12, o multiplicación y división |
/// | 4 (examen) | tres o cuatro fracciones con sumas y restas y denominadores distintos (2019 M11) |
/// | 5 | combinadas sin paréntesis (sumas, productos y cocientes) |
/// | 6 | combinadas con paréntesis |
struct GeneradorFraccionesOperar: GeneradorItems {
    let tipo = "fraccionesOperar"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["pregunta", "expresion", "contexto"]

    func caso(_ d: Int, rng: inout GeneradorConSemilla) -> (ExprArit, Racional)? {
        for _ in 0..<2000 {
            func f(_ den: Int) -> ExprArit.Token { .num(rac(rng.entero(1...(den - 1)), den)) }
            func op() -> ExprArit.Token { .op(rng.probabilidad(0.5) ? "+" : "-") }
            var t: [ExprArit.Token]
            switch d {
            case 1: let den = rng.entero(3...12); t = [f(den), op(), f(den)]
            case 2: let a = rng.entero(2...6), den2 = a * rng.entero(2...3); t = [f(a), op(), f(den2)]
            case 3:
                if rng.probabilidad(0.5) { t = [f(rng.entero(2...9)), .op(rng.probabilidad(0.5) ? "*" : ":"), f(rng.entero(2...9))]; break }
                let a = rng.entero(3...12), b = rng.entero(3...12)
                guard a % b != 0, b % a != 0, a / Racional.mcd(a, b) * b <= 60 else { continue }
                t = [f(a), op(), f(b)]
            case 4:
                // Denominadores distintos también después de simplificar (2/4 se escribe 1/2).
                let n = rng.entero(3...4)
                let fs = (0..<n).map { _ in f(rng.entero(2...15)) }
                let dens = fs.compactMap { x -> Int? in if case .num(let r) = x { r.denominador } else { nil } }
                guard Set(dens).count >= 2 else { continue }
                t = [fs[0]]
                for x in fs.dropFirst() { t += [op(), x] }
            case 5:
                let mul: ExprArit.Token = .op(rng.probabilidad(0.5) ? "*" : ":")
                t = rng.probabilidad(0.5) ? [f(rng.entero(2...8)), op(), f(rng.entero(2...8)), mul, f(rng.entero(2...8))]
                                          : [f(rng.entero(2...8)), mul, f(rng.entero(2...8)), op(), f(rng.entero(2...8)), op(), f(rng.entero(2...8))]
            default:
                let patrones: [[ExprArit.Token]] = [
                    [.abre, f(rng.entero(2...6)), op(), f(rng.entero(2...6)), .cierra, .op("*"), f(rng.entero(2...9))],
                    [f(rng.entero(2...6)), .op(":"), .abre, f(rng.entero(2...6)), op(), f(rng.entero(2...6)), .cierra],
                    [.abre, f(rng.entero(2...6)), op(), f(rng.entero(2...6)), .cierra, .op("*"), f(rng.entero(2...9)), op(), f(rng.entero(2...6))],
                ]
                t = rng.elemento(patrones)
            }
            guard let e = ExprArit.analizar(t) else { continue }
            var pasos: [String] = []
            guard let v = e.resolver(ExprArit.Reglas(fracciones: true, maximo: 50), pasos: &pasos), v.numerador > 0, v.denominador <= 144 else { continue }
            return (e, v)
        }
        return nil
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let (e, v) = caso(p.dificultad, rng: &rng) else { throw ErrorGenerador.sinCaso(tipo) }
        var nada: [String] = []
        let ingenuo = e.resolver(ExprArit.Reglas(fracciones: true, ingenuo: true, maximo: 100_000), pasos: &nada)
        var reglas: [(Racional?, String)] = []
        if case .prod(let fs, let ops) = e, fs.count == 2, case .n(let a) = fs[0], case .n(let b) = fs[1] {
            if ops[0] == ":" { reglas.append((rac(a.numerador * b.numerador, a.denominador * b.denominador), "Para dividir fracciones, se multiplica por la inversa de la segunda.")) }
            else { reglas.append((rac(a.numerador * b.denominador, a.denominador * b.numerador), "Para multiplicar fracciones, se multiplican los numeradores entre sí y los denominadores entre sí.")) }
        } else {
            reglas.append((ingenuo, "Para sumar fracciones, primero se busca un denominador común."))
        }
        if e.profundidad > 0 { var x: [String] = []; reglas.append((e.sinAgrupar.resolver(ExprArit.Reglas(fracciones: true, maximo: 100_000), pasos: &x), "Lo que está entre paréntesis se calcula primero.")) }
        var pasos: [String] = []
        _ = e.resolver(ExprArit.Reglas(fracciones: true, maximo: 50), pasos: &pasos)
        // Peso por operación: mismo denominador 1, múltiplos 2, m.c.m. 3, producto o cociente 4 (inversa y simplificación).
        let pesoOps: Double = [1: 1, 2: 2, 3: 3, 4: 3, 5: 3.5, 6: 4][p.dificultad] ?? 4
        let complejidad = Double(e.operaciones) * pesoOps + Double(e.profundidad) + 0.5 * log10(Double(v.numerador * v.denominador + 1))
        return Muestra(clave: e.texto, valores: ["pregunta": "Calcula y simplifica: \(e.texto)", "expresion": e.texto],
                       payload: A.numerico(v, unidad: nil, comoFraccion: true),
                       explicacion: pasos.map(ExprArit.sinNombre).joined(separator: "; ") + ". Resultado irreducible: \(A.fraccion(v)).",
                       erroresHabituales: A.errores(v, reglas, comoFraccion: true),
                       pistas: ["Para sumar o restar, busca un denominador común; al final, simplifica."],
                       complejidad: complejidad, datos: ["expresion": e.texto, "respuesta": A.fraccion(v)])
            .conPasos(Self.pasos(pasos, e: e))
    }

    /// Pasos del ejemplo resuelto (§5): las operaciones del resolutor en orden, con el porqué de la
    /// primera (denominador común, producto o inversa).
    static func pasos(_ operaciones: [String], e: ExprArit) -> [PasoResuelto] {
        // Una sola operación: se enseña el procedimiento (denominador común, producto o inversa).
        if case .suma(let ts, let ops) = e, ts.count == 2, case .n(let a) = ts[0], case .n(let b) = ts[1], let v = (ops[0] == "+" ? a + b : a - b) as Racional? {
            let m = a.denominador / Racional.mcd(a.denominador, b.denominador) * b.denominador
            let s = ops[0] == "+" ? "+" : "−"
            return [Pasos.dato("Busca un denominador común", "m.c.m.(\(a.denominador), \(b.denominador)) = \(m)", valor: "\(m)",
                               porque: "porque solo se suman fracciones con el mismo denominador"),
                    Pasos.dato("Pasa las dos fracciones a ese denominador", "\(a.numerador * (m / a.denominador))/\(m) \(s) \(b.numerador * (m / b.denominador))/\(m)"),
                    PasoResuelto(frase: "Opera los numeradores y simplifica", resultado: "\(A.fraccion(v))", valor: A.fraccion(v))]
        }
        if case .prod(let fs, let ops) = e, fs.count == 2, case .n(let a) = fs[0], case .n(let b) = fs[1] {
            let divide = ops[0] == ":"
            let c = divide ? rac(b.denominador, b.numerador) : b
            let sinSimplificar = "\(a.numerador * c.numerador)/\(a.denominador * c.denominador)"
            var r: [PasoResuelto] = []
            if divide { r.append(Pasos.dato("Da la vuelta a la segunda fracción", "\(A.fraccion(b)) → \(b.denominador)/\(b.numerador)",
                                            porque: "porque dividir es multiplicar por la fracción inversa")) }
            r.append(Pasos.dato("Multiplica numeradores y denominadores", "\(a.numerador) × \(c.numerador) / \(a.denominador) × \(c.denominador) = \(sinSimplificar)",
                                valor: sinSimplificar, porque: divide ? nil : "porque multiplicar fracciones es tomar una parte de otra parte"))
            let v = a * c
            r.append(PasoResuelto(frase: "Simplifica", resultado: "\(sinSimplificar) = \(A.fraccion(v))", valor: A.fraccion(v)))
            return r
        }
        var r = GeneradorOperacionesCombinadas.pasosResueltos(operaciones, agrupaciones: e.profundidad > 0, payload: nil)
        let primera = operaciones.first ?? ""
        r[0].porque = primera.hasPrefix("Multiplicar") ? "porque se multiplican numeradores entre sí y denominadores entre sí"
            : primera.hasPrefix("Dividir") ? "porque dividir es multiplicar por la fracción inversa"
            : e.profundidad > 0 ? "porque lo que está entre paréntesis se calcula antes"
            : "porque solo se suman fracciones con el mismo denominador"
        return r
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 31)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 5000) { if let (e, _) = caso(p.dificultad, rng: &rng) { vistos.insert(e.texto) } }
        return Array(vistos)
    }
}

// MARK: - C11. problemaFraccion

/// Problemas de partes de una cantidad (MAT.NUM.FRAPROB): lo que queda tras gastos sucesivos.
///
/// | Dif. | Caso |
/// |---|---|
/// | 1 | un gasto de fracción unitaria |
/// | 2 | un gasto de fracción no unitaria |
/// | 3 | dos gastos: sobre el total, o el segundo sobre lo que queda |
/// | 4 (examen) | tres gastos, cada uno sobre lo que queda (2019 A M11, 2026 A M11) |
/// | 5 | tres gastos sobre lo que queda, con fracciones no unitarias y cantidades mayores |
/// | 6 | cuatro gastos, cada uno sobre lo que queda |
struct GeneradorProblemaFraccion: GeneradorItems {
    let tipo = "problemaFraccion"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    static let cosas = ["un libro", "material escolar", "fruta", "una entrada de cine", "ropa", "un regalo", "la merienda", "un juego de mesa"]

    /// Caso: total y fracciones; `resto` = cada gasto sobre lo que queda.
    struct Caso { let total: Int; let fracciones: [Racional]; let resto: Bool }

    static func queda(_ c: Caso) -> Racional {
        var q = rac(c.total)
        if c.resto { for f in c.fracciones { q = q - q * f } }
        else { q = rac(c.total) - c.fracciones.reduce(rac(0)) { $0 + $1 } * rac(c.total) }
        return q
    }

    func caso(_ d: Int, rng: inout GeneradorConSemilla) -> Caso {
        func fraccion(unitaria: Bool) -> Racional {
            let den = rng.entero(2...8)
            return unitaria ? rac(1, den) : rac(rng.entero(1...(den - 1)), den)
        }
        let n = [1: 1, 2: 1, 3: 2, 4: 3, 5: 3][d] ?? 4
        let fs = (0..<n).map { _ in d == 5 ? rac(rng.entero(2...7), rng.entero(3...8)) : fraccion(unitaria: d == 1) }
        let maximo = [1: 60, 2: 120, 3: 240, 4: 600, 5: 1200][d] ?? 2400
        return Caso(total: rng.entero(2...maximo), fracciones: fs.map { $0.numerador < $0.denominador ? $0 : rac(1, $0.denominador) },
                    resto: d >= 4 || (d == 3 && rng.probabilidad(0.5)))
    }

    static func valido(_ c: Caso) -> Bool {
        let q = queda(c)
        guard q.esEntero, q.numerador > 0 else { return false }
        // Cada gasto intermedio también debe ser un número entero de euros.
        var r = rac(c.total)
        for f in c.fracciones { let g = (c.resto ? r : rac(c.total)) * f; guard g.esEntero else { return false }; if c.resto { r = r - g } }
        return true
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        for _ in 0..<3000 {
            let c = caso(p.dificultad, rng: &rng)
            guard Self.valido(c) else { continue }
            return construir(c, rng: &rng).conPasos(Self.pasos(c))
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Pasos del ejemplo resuelto (§5): cada gasto y lo que queda.
    static func pasos(_ c: Caso) -> [PasoResuelto] {
        let t = rac(c.total)
        if !c.resto && c.fracciones.count > 1 {
            let suma = c.fracciones.reduce(rac(0)) { $0 + $1 }, gasto = t * suma
            return [Pasos.op("Suma las fracciones que gasta", c.fracciones.map(A.fraccion).joined(separator: " + "), suma,
                             porque: "porque todas las partes son del mismo total"),
                    Pasos.op("Calcula cuánto es esa parte de \(c.total) €", "\(c.total) × \(A.fraccion(suma))", gasto),
                    Pasos.op("Resta lo gastado", "\(c.total) − \(A.texto(gasto))", queda(c))]
        }
        if c.fracciones.count == 1 {
            let f = c.fracciones[0], g = t * f
            return [Pasos.op("Calcula \(A.fraccion(f)) de \(c.total) €", "\(c.total) : \(f.denominador) × \(f.numerador)", g,
                             porque: "porque \(A.fraccion(f)) es repartir en \(f.denominador) partes y tomar \(f.numerador)"),
                    Pasos.op("Resta lo gastado", "\(c.total) − \(A.texto(g))", queda(c))]
        }
        var r = t
        return c.fracciones.enumerated().map { k, f in
            let g = r * f, antes = r
            r = r - g
            return PasoResuelto(frase: k == 0 ? "Gasta \(A.fraccion(f)) del total" : "Gasta \(A.fraccion(f)) de lo que queda",
                                resultado: "\(A.texto(antes)) × \(A.fraccion(f)) = \(A.texto(g)); quedan \(A.texto(antes)) − \(A.texto(g)) = \(A.texto(r))",
                                valor: FormatoNumero.numero(r),
                                porque: k == 0 ? "porque cada gasto se calcula sobre lo que queda en ese momento" : nil)
        }
    }

    private func construir(_ c: Caso, rng: inout GeneradorConSemilla) -> Muestra {
        let nombre = rng.elemento(A.nombres)
        let cosas = Array(rng.barajar(Self.cosas).prefix(c.fracciones.count))
        let fs = c.fracciones.map(A.fraccion)
        let pregunta: String
        switch c.fracciones.count {
        case 1: pregunta = "\(nombre) tiene \(c.total) €. Gasta \(fs[0]) en \(cosas[0]). ¿Cuánto dinero le queda?"   // A.2
        case 2 where !c.resto: pregunta = "\(nombre) tiene \(c.total) €. Gasta \(fs[0]) en \(cosas[0]) y \(fs[1]) en \(cosas[1]). ¿Cuánto dinero le queda?"   // A.2
        case 2: pregunta = "\(nombre) tiene \(c.total) €. Gasta \(fs[0]) en \(cosas[0]) y \(fs[1]) de lo que le queda en \(cosas[1]). ¿Cuánto dinero le queda?"
        case 3: pregunta = "\(nombre) tiene \(c.total) €. Gasta \(fs[0]) en \(cosas[0]), \(fs[1]) de lo que le queda en \(cosas[1]) y \(fs[2]) del resto en \(cosas[2]). ¿Cuánto dinero le queda?"   // A.2
        default: pregunta = "\(nombre) tiene \(c.total) €. Gasta \(fs[0]) en \(cosas[0]), \(fs[1]) de lo que le queda en \(cosas[1]), \(fs[2]) del resto en \(cosas[2]) y \(fs[3]) de lo que aún le queda en \(cosas[3]). ¿Cuánto dinero le queda?"   // 05E
        }
        let sol = Self.queda(c)
        let t = rac(c.total)
        var reglas: [(Racional?, String)] = [(t - sol, "Eso es lo que gasta, no lo que le queda.")]
        if c.resto { reglas.insert((t - c.fracciones.reduce(rac(0)) { $0 + $1 } * t, "La segunda fracción se aplica a lo que queda, no al total."), at: 0) }
        if c.fracciones.count > 1 { reglas.append((t - t * c.fracciones[0], "Te falta restar el \(c.resto ? "siguiente" : "segundo") gasto.")) }
        var r = t
        var pasos: [String] = []
        for (f, fsTexto) in zip(c.fracciones, fs) {
            let g = (c.resto ? r : t) * f
            pasos.append("\(fsTexto) de \(A.texto(c.resto ? r : t)) = \(A.texto(g)) €")
            r = r - g
        }
        let complejidad = Double(c.fracciones.count) * 1.5 + (c.resto ? 1.5 : 0) + (c.fracciones.allSatisfy { $0.numerador == 1 } ? 0 : 0.75) + 0.3 * log10(Double(c.total))
        return Muestra(clave: "\(c.total)|\(fs.joined(separator: ","))|\(c.resto)", valores: ["pregunta": pregunta],
                       payload: A.numerico(sol, unidad: "€"),
                       explicacion: pasos.joined(separator: "; ") + ". Le quedan \(A.texto(sol)) €.",
                       erroresHabituales: A.errores(sol, reglas), pistas: ["Para calcular a/b de una cantidad, divide entre b y multiplica por a."],
                       complejidad: complejidad,
                       datos: ["total": "\(c.total)", "fracciones": fs.joined(separator: ";"), "resto": c.resto ? "1" : "0", "respuesta": A.texto(sol)])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 37)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 20_000) {
            let c = caso(p.dificultad, rng: &rng)
            if Self.valido(c) { vistos.insert("\(c.total)|\(c.fracciones.map(A.fraccion).joined(separator: ","))|\(c.resto)") }
        }
        return Array(vistos)
    }
}

extension ExprArit {
    /// Paso sin su nombre («División: 3 : 3 = 1» → «3 : 3 = 1»). Solo se quita el primer prefijo:
    /// el paso puede contener el signo de dividir « : » (05E; antes se mostraba «3 = 1»).
    static func sinNombre(_ paso: String) -> String {
        guard let r = paso.range(of: ": ") else { return paso }
        return String(paso[r.upperBound...])
    }
}
