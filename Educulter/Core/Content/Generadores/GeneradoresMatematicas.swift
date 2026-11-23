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

// MARK: - 1. porcentajeDe

/// Porcentajes: «p % de B», «cantidad a partir de un %» («el 20 % de un número es 12»), aumentos,
/// descuentos y (dificultad 6) cambios sucesivos.
///
/// | Dif. | Variantes | p | Base |
/// |---|---|---|---|
/// | 1 | p % de B | 10, 20, 25, 50 | múltiplos de 10 hasta 200, resultado entero |
/// | 2 | + descuento | múltiplos de 5 | múltiplos de 10 hasta 500, entero |
/// | 3 | + aumento, cantidad desde % | 1–99 | múltiplos de 20 hasta 1000, entero |
/// | 4 | todas | 1–99 | múltiplos de 25 hasta 5000, ≤ 2 decimales |
/// | 5 | todas | 0,5–99,5 (medios) | múltiplos de 50 hasta 10 000, ≤ 2 decimales |
/// | 6 | dos cambios sucesivos | múltiplos de 5 | múltiplos de 100 hasta 10 000, ≤ 2 decimales |
///
/// Reglas de error: correr la coma, restar los puntos del %, quedarse con la parte en vez del
/// total, sumar en vez de restar, aplicar el % al revés, sumar porcentajes sucesivos.
struct GeneradorPorcentaje: GeneradorItems {
    let tipo = "porcentajeDe"
    let mecanicas: Set<Mecanica> = [.numerico, .eleccion]
    let marcadores: Set<String> = ["pregunta", "p", "p2", "base", "parte", "unidad", "contexto"]

    struct Nivel { let variantes: [String]; let ps: [Racional]; let paso: Int; let maxBase: Int; let maxDecimales: Int }

    static func nivel(_ d: Int) -> Nivel {
        let medios = (1...199).map { r($0, 2) }
        switch d {
        case 1: return Nivel(variantes: ["porcentajeDe"], ps: [10, 20, 25, 50].map { r($0) }, paso: 10, maxBase: 200, maxDecimales: 0)
        case 2: return Nivel(variantes: ["porcentajeDe", "descuento"], ps: stride(from: 5, to: 100, by: 5).map { r($0) }, paso: 10, maxBase: 500, maxDecimales: 0)
        case 3: return Nivel(variantes: ["porcentajeDe", "aumento", "descuento", "cantidadDesde"], ps: (1...99).map { r($0) }, paso: 20, maxBase: 1000, maxDecimales: 0)
        case 4: return Nivel(variantes: ["porcentajeDe", "aumento", "descuento", "cantidadDesde"], ps: (1...99).map { r($0) }, paso: 25, maxBase: 5000, maxDecimales: 2)
        case 5: return Nivel(variantes: ["porcentajeDe", "aumento", "descuento", "cantidadDesde"], ps: medios, paso: 50, maxBase: 10000, maxDecimales: 2)
        default: return Nivel(variantes: ["sucesivos"], ps: stride(from: 5, to: 100, by: 5).map { r($0) }, paso: 100, maxBase: 10000, maxDecimales: 2)
        }
    }

    private func decimales(_ v: Racional) -> Int? {
        guard let t = FormatoNumero.decimal(v) else { return nil }
        return t.split(separator: ",").dropFirst().first?.count ?? 0
    }

    /// Resultado de un caso (o `nil` si no cumple las condiciones del nivel).
    func resolver(variante: String, p: Racional, p2: Racional?, base: Int, nivel n: Nivel) -> (parte: Racional, respuesta: Racional)? {
        let b = r(base)
        let parte = b * p * r(1, 100)
        let resultado: Racional
        switch variante {
        case "porcentajeDe", "cantidadDesde": resultado = parte
        case "aumento": resultado = b + parte
        case "descuento": resultado = b - parte
        default:
            guard let p2 else { return nil }
            let tras1 = b + parte
            resultado = tras1 - tras1 * p2 * r(1, 100)
        }
        let respuesta = variante == "cantidadDesde" ? b : resultado
        guard let dp = decimales(parte), let dr = decimales(resultado), max(dp, dr) <= n.maxDecimales,
              resultado.numerador > 0 else { return nil }
        if variante == "cantidadDesde" { guard dp <= n.maxDecimales else { return nil } }
        return (parte, respuesta)
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let n = Self.nivel(p.dificultad)
        let variantes = p.textos("variantes", porDefecto: n.variantes)
        let unidad = p.parametros["unidad"]?.textos?.first
        for _ in 0..<400 {
            let v = rng.elemento(variantes)
            let pc = rng.elemento(n.ps)
            let p2 = v == "sucesivos" ? rng.elemento(n.ps) : nil
            let base = n.paso * rng.entero(1...(n.maxBase / n.paso))
            guard let (parte, sol) = resolver(variante: v, p: pc, p2: p2, base: base, nivel: n) else { continue }
            return construir(p, v: v, pc: pc, p2: p2, base: base, parte: parte, sol: sol, unidad: unidad, rng: &rng)
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    private func construir(_ p: Plantilla, v: String, pc: Racional, p2: Racional?, base: Int, parte: Racional, sol: Racional,
                           unidad: String?, rng: inout GeneradorConSemilla) -> Muestra {
        let ps = FormatoNumero.numero(pc), bs = FormatoNumero.miles(base), partes = FormatoNumero.numero(parte)
        let u = unidad.map { " \($0)" } ?? ""
        let b = r(base)
        let pregunta: String
        var reglas: [(Racional?, String)] = []
        var explicacion: String
        switch v {
        case "porcentajeDe":
            pregunta = rng.elemento(["¿Cuánto es el \(ps) % de \(bs)\(u)?", "Calcula el \(ps) % de \(bs)\(u)."])
            reglas = [(sol * r(10), "Revisa la coma: el \(ps) % es \(ps) de cada 100, no de cada 10."),
                      (b - pc, "Has restado el porcentaje a la cantidad: hay que multiplicar por \(ps) y dividir entre 100."),
                      (b / pc, "Has dividido entre el porcentaje: multiplica por \(ps) y divide entre 100."),
                      (sol * r(1, 10), "Revisa la coma: has dividido entre 1000 en lugar de entre 100.")]
            explicacion = "\(ps) % de \(bs) = \(bs) × \(ps) : 100 = \(partes)\(u)."
        case "descuento":
            pregunta = rng.elemento(["Un artículo de \(bs)\(u) tiene un descuento del \(ps) %. ¿Cuánto se paga?",
                                     "Si a \(bs)\(u) le aplicamos una rebaja del \(ps) %, ¿cuánto queda?"])
            reglas = [(parte, "Esa es la rebaja, no el precio final: réstala de \(bs)."),
                      (b - pc, "Has restado los puntos del porcentaje como si fueran unidades."),
                      (b + parte, "Has sumado la rebaja en lugar de restarla.")]
            explicacion = "Rebaja: \(bs) × \(ps) : 100 = \(partes). Precio final: \(bs) − \(partes) = \(FormatoNumero.numero(sol))\(u)."
        case "aumento":
            pregunta = rng.elemento(["Una cantidad de \(bs)\(u) aumenta un \(ps) %. ¿Cuánto es ahora?",
                                     "Si \(bs)\(u) sube un \(ps) %, ¿cuál es la nueva cantidad?"])
            reglas = [(parte, "Ese es solo el aumento: súmalo a \(bs)."),
                      (b + pc, "Has sumado los puntos del porcentaje como si fueran unidades."),
                      (b - parte, "Has restado el aumento en lugar de sumarlo.")]
            explicacion = "Aumento: \(bs) × \(ps) : 100 = \(partes). Total: \(bs) + \(partes) = \(FormatoNumero.numero(sol))\(u)."
        case "cantidadDesde":
            pregunta = rng.elemento(["El \(ps) % de un número es \(partes). ¿Cuál es ese número?",
                                     "Sabemos que \(partes) es el \(ps) % de una cantidad. ¿Cuál es la cantidad?"])
            reglas = [(parte * pc * r(1, 100), "Has calculado el \(ps) % de \(partes): aquí \(partes) ya es el \(ps) % del total."),
                      (parte + pc, "Has sumado el porcentaje al dato."),
                      ((parte * r(100)) / (r(100) - pc), "Has usado el porcentaje que falta (\(FormatoNumero.numero(r(100) - pc)) %).")]
            explicacion = "Si \(partes) es el \(ps) %, el total es \(partes) × 100 : \(ps) = \(FormatoNumero.numero(sol))."
        default:
            let p2s = FormatoNumero.numero(p2!)
            pregunta = "Un precio de \(bs)\(u) sube un \(ps) % y después baja un \(p2s) %. ¿Cuál es el precio final?"
            reglas = [(b + b * (pc - p2!) * r(1, 100), "Los porcentajes sucesivos no se suman ni se restan: aplica uno detrás de otro."),
                      (b + parte, "Te falta aplicar la segunda variación (−\(p2s) %)."),
                      (b, "Subir y bajar el mismo porcentaje no deja el precio igual: el segundo se aplica sobre el nuevo precio.")]
            explicacion = "\(bs) + \(ps) % = \(FormatoNumero.numero(b + parte)); después −\(p2s) %: \(FormatoNumero.numero(sol))\(u)."
        }
        let (payload, errores) = respuesta(p, correcta: sol, unidad: unidad, reglas: reglas, rng: &rng)
        let pasos: Double = ["porcentajeDe": 1, "descuento": 2, "aumento": 2, "cantidadDesde": 2][v] ?? 3
        let decs = Double(decimales(sol) ?? 0) + (pc.esEntero ? 0 : 1)
        return Muestra(clave: [v, FormatoNumero.numero(pc), p2.map(FormatoNumero.numero) ?? "-", "\(base)"].joined(separator: "|"),
                       valores: ["pregunta": pregunta, "p": ps, "p2": p2.map(FormatoNumero.numero) ?? "", "base": bs, "parte": partes, "unidad": unidad ?? ""],
                       payload: payload, explicacion: explicacion, erroresHabituales: errores,
                       pistas: ["El \(ps) % significa \(ps) de cada 100."],
                       complejidad: pasos + digitos(base) + decs * 0.5,
                       datos: ["variante": v, "p": ps, "p2": p2.map(FormatoNumero.numero) ?? "", "base": "\(base)", "respuesta": FormatoNumero.numero(sol)])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let n = Self.nivel(p.dificultad)
        var claves: [String] = []
        for v in p.textos("variantes", porDefecto: n.variantes) {
            for pc in n.ps {
                for p2 in (v == "sucesivos" ? n.ps.map(Optional.some) : [nil]) {
                    for k in 1...(n.maxBase / n.paso) {
                        let base = n.paso * k
                        guard resolver(variante: v, p: pc, p2: p2, base: base, nivel: n) != nil else { continue }
                        claves.append([v, FormatoNumero.numero(pc), p2.map(FormatoNumero.numero) ?? "-", "\(base)"].joined(separator: "|"))
                        if claves.count >= limite { return claves }
                    }
                }
            }
        }
        return claves
    }
}

// MARK: - 2. conversionUnidades

/// Conversión de unidades del sistema métrico decimal y del tiempo, de 1 a 3 saltos.
///
/// | Dif. | Magnitudes | Saltos | Valor |
/// |---|---|---|---|
/// | 1 | longitud, masa, capacidad | 1, a la unidad menor | entero 1–99 |
/// | 2 | longitud, masa, capacidad | 1–2, en los dos sentidos | entero 1–999 |
/// | 3 | longitud, masa, capacidad | 2–3 | decimal con una cifra |
/// | 4 | superficie (×100) y volumen (×1000) | 1–2 | entero o decimal |
/// | 5 | expresiones complejas (3 km 4 hm 3 dam; 2 h 45 min 30 s) | — | enteros |
/// | 6 | volumen ↔ capacidad (1 dm³ = 1 l) | 1–3 | decimal |
///
/// Reglas de error: un salto de más o de menos, multiplicar en vez de dividir, usar ×10 en
/// superficie o volumen.
struct GeneradorConversionUnidades: GeneradorItems {
    let tipo = "conversionUnidades"
    let mecanicas: Set<Mecanica> = [.numerico, .ruedas]
    let marcadores: Set<String> = ["cantidad", "desde", "hasta", "resultado", "magnitud", "contexto"]

    struct Unidad { let simbolo: String; let exponente: Int }
    /// Unidades por magnitud (exponente respecto a la unidad base) y base de cada salto.
    static let magnitudes: [String: (base: Int, unidades: [Unidad])] = [
        "longitud": (10, [("km", 3), ("hm", 2), ("dam", 1), ("m", 0), ("dm", -1), ("cm", -2), ("mm", -3)].map(Unidad.init)),
        "masa": (10, [("kg", 3), ("hg", 2), ("dag", 1), ("g", 0), ("dg", -1), ("cg", -2), ("mg", -3)].map(Unidad.init)),
        "capacidad": (10, [("kl", 3), ("hl", 2), ("dal", 1), ("l", 0), ("dl", -1), ("cl", -2), ("ml", -3)].map(Unidad.init)),
        "superficie": (100, [("km²", 3), ("hm²", 2), ("dam²", 1), ("m²", 0), ("dm²", -1), ("cm²", -2), ("mm²", -3)].map(Unidad.init)),
        "volumen": (1000, [("m³", 0), ("dm³", -1), ("cm³", -2), ("mm³", -3)].map(Unidad.init)),
    ]

    static func potencia(_ base: Int, _ e: Int) -> Racional {
        var v = r(1)
        for _ in 0..<abs(e) { v = v * r(base) }
        return e >= 0 ? v : (r(1) / v)!
    }

    /// Caso simple: valor (en décimas o unidades), magnitud, unidad origen y destino.
    struct Caso { let magnitud: String; let valor: Racional; let desde: Int; let hasta: Int; let compuesta: [(Int, Int)] }

    private func casos(_ d: Int, _ p: Plantilla) -> (magnitudes: [String], saltos: ClosedRange<Int>, valores: [Racional], soloMenor: Bool) {
        let basicas = p.textos("magnitudes", porDefecto: ["longitud", "masa", "capacidad"])
        switch d {
        case 1: return (basicas, 1...1, (1...99).map { r($0) }, true)
        case 2: return (basicas, 1...2, (1...999).map { r($0) }, false)
        case 3: return (basicas, 2...3, (1...999).map { r($0, 10) }, false)
        case 4: return (p.textos("magnitudes", porDefecto: ["superficie", "volumen"]), 1...2, (1...99).map { r($0) } + (1...99).map { r($0, 10) }, false)
        // 5 y 6 solo se usan con ruedas (con numerico van a las expresiones complejas y a volumen ↔ capacidad).
        case 5: return (p.textos("magnitudes", porDefecto: ["superficie", "volumen"]), 2...3, (1...99).map { r($0, 10) }, false)
        default: return (p.textos("magnitudes", porDefecto: ["superficie", "volumen"]), 3...3, (1...99).map { r($0, 100) }, false)
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        // Con ruedas (elegir la unidad) solo hay conversiones simples: en 5 y 6, más saltos en superficie y volumen.
        if p.mecanica == .numerico && p.dificultad == 5 { return compuesta(p, rng: &rng) }
        if p.mecanica == .numerico && p.dificultad >= 6 { return volumenCapacidad(p, rng: &rng) }
        let c = casos(p.dificultad, p)
        for _ in 0..<300 {
            let mag = rng.elemento(c.magnitudes)
            guard let info = Self.magnitudes[mag] else { continue }
            let i = rng.entero(0...(info.unidades.count - 1)), salto = rng.entero(c.saltos)
            let j = c.soloMenor || rng.probabilidad(0.5) ? i + salto : i - salto
            guard info.unidades.indices.contains(j) else { continue }
            let valor = rng.elemento(c.valores)
            if let m = simple(p, mag: mag, valor: valor, i: i, j: j, rng: &rng) { return m }
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    private func simple(_ p: Plantilla, mag: String, valor: Racional, i: Int, j: Int, rng: inout GeneradorConSemilla) -> Muestra? {
        guard let info = Self.magnitudes[mag] else { return nil }
        let de = info.unidades[i], a = info.unidades[j]
        let factor = Self.potencia(info.base, de.exponente - a.exponente)
        let sol = valor * factor
        guard FormatoNumero.decimal(sol) != nil, sol.numerador < 100_000_000 else { return nil }
        let saltos = abs(i - j)
        let vs = FormatoNumero.numero(valor), ss = FormatoNumero.numero(sol)
        let clave = [mag, vs, de.simbolo, a.simbolo, p.mecanica.rawValue].joined(separator: "|")
        let dir = de.exponente > a.exponente ? "multiplica" : "divide"
        let explicacion = "De \(de.simbolo) a \(a.simbolo) hay \(saltos) \(saltos == 1 ? "salto" : "saltos"): se \(dir) por \(FormatoNumero.miles(Self.potencia(info.base, saltos).numerador)). \(vs) \(de.simbolo) = \(ss) \(a.simbolo)."
        let unSalto = Self.potencia(info.base, 1)
        let reglas: [(Racional?, String)] = [
            (sol * unSalto, "Has dado un salto de más: cuenta las unidades que hay entre \(de.simbolo) y \(a.simbolo)."),
            (sol / unSalto, "Has dado un salto de menos: cuenta las unidades que hay entre \(de.simbolo) y \(a.simbolo)."),
            ((valor / factor), "Al pasar a una unidad \(dir == "multiplica" ? "menor se multiplica" : "mayor se divide"), no al revés."),
            (info.base == 10 ? nil : valor * Self.potencia(10, de.exponente - a.exponente),
             "En \(mag) cada salto vale \(info.base), no 10."),
        ]
        let complejidad = Double(saltos) + (info.base == 10 ? 0 : Double(String(info.base).count - 1)) + (valor.esEntero ? 0 : 1) + digitos(sol.numerador) * 0.3
        if p.mecanica == .ruedas {
            let opciones = info.unidades.map(\.simbolo)
            let rueda = Payload.Ruedas.Rueda(id: "unidad", nombre: "Unidad", opciones: opciones, correcta: a.simbolo)
            return Muestra(clave: clave, valores: ["cantidad": "\(vs) \(de.simbolo)", "desde": de.simbolo, "hasta": a.simbolo, "resultado": ss, "magnitud": mag],
                           payload: .ruedas(Payload.Ruedas(ruedas: [rueda])), explicacion: explicacion,
                           erroresHabituales: [ErrorHabitual(respuesta: "unidad", feedback: "Cuenta los saltos: cada salto multiplica o divide por \(info.base).")],
                           complejidad: complejidad, datos: ["valor": vs, "desde": de.simbolo, "hasta": a.simbolo, "resultado": ss])
        }
        return Muestra(clave: clave, valores: ["cantidad": "\(vs) \(de.simbolo)", "desde": de.simbolo, "hasta": a.simbolo, "resultado": "", "magnitud": mag],
                       payload: numerico(sol, unidad: a.simbolo), explicacion: explicacion,
                       erroresHabituales: erroresNumericos(sol, reglas), pistas: ["Cada salto entre unidades vale \(info.base)."],
                       complejidad: complejidad, datos: ["valor": vs, "desde": de.simbolo, "hasta": a.simbolo, "respuesta": ss])
    }

    /// Dificultad 5: expresión compleja (2–3 términos) a una sola unidad.
    private func compuesta(_ p: Plantilla, rng: inout GeneradorConSemilla) -> Muestra {
        if rng.probabilidad(0.5) {
            let h = rng.entero(1...5), mi = rng.entero(1...59), s = rng.entero(1...59)
            let total = h * 3600 + mi * 60 + s
            let cantidad = "\(h) h \(mi) min \(s) s"
            return Muestra(clave: "tiempo|\(cantidad)|s", valores: ["cantidad": cantidad, "desde": "h, min y s", "hasta": "s", "resultado": "", "magnitud": "tiempo"],
                           payload: numerico(r(total), unidad: "s"),
                           explicacion: "\(h) h = \(h * 3600) s; \(mi) min = \(mi * 60) s; total: \(h * 3600) + \(mi * 60) + \(s) = \(FormatoNumero.miles(total)) s.",
                           erroresHabituales: erroresNumericos(r(total), [
                            (r(h * 100 * 60 + mi * 60 + s), "Una hora tiene 60 minutos, no 100."),
                            (r(h * 60 + mi * 60 + s), "Has pasado las horas a minutos, no a segundos (× 3600)."),
                           ]),
                           complejidad: 5 + digitos(total) * 0.3, datos: ["tiempo": "\(h),\(mi),\(s)", "respuesta": "\(total)"])
        }
        let mag = rng.elemento(p.textos("magnitudes", porDefecto: ["longitud", "masa", "capacidad"]))
        let info = Self.magnitudes[mag] ?? Self.magnitudes["longitud"]!
        let indices = Array(rng.barajar(Array(0..<4)).prefix(rng.entero(2...3))).sorted()
        let terminos = indices.map { ($0, rng.entero(1...9)) }
        let destino = rng.entero((indices.last ?? 3)...min(info.unidades.count - 1, (indices.last ?? 3) + 2))
        var total = r(0)
        for (i, v) in terminos { total = total + r(v) * Self.potencia(info.base, info.unidades[i].exponente - info.unidades[destino].exponente) }
        let cantidad = terminos.map { "\($0.1) \(info.unidades[$0.0].simbolo)" }.joined(separator: " ")
        let hasta = info.unidades[destino].simbolo
        let suma = FormatoNumero.numero(total)
        return Muestra(clave: "\(mag)|\(cantidad)|\(hasta)", valores: ["cantidad": cantidad, "desde": "varias unidades", "hasta": hasta, "resultado": "", "magnitud": mag],
                       payload: numerico(total, unidad: hasta),
                       explicacion: "Se pasa cada término a \(hasta) y se suman: \(suma) \(hasta).",
                       erroresHabituales: erroresNumericos(total, [(r(terminos.reduce(0) { $0 + $1.1 }), "Has sumado los números sin pasarlos antes a la misma unidad.")]),
                       complejidad: 5 + Double(terminos.count) * 0.5, datos: ["compuesta": terminos.map { "\(info.unidades[$0.0].simbolo):\($0.1)" }.joined(separator: ";"), "hasta": hasta, "respuesta": suma])
    }

    /// Dificultad 6: volumen ↔ capacidad (1 m³ = 1 kl, 1 dm³ = 1 l, 1 cm³ = 1 ml).
    private func volumenCapacidad(_ p: Plantilla, rng: inout GeneradorConSemilla) -> Muestra {
        // Exponentes en litros: kl 3, hl 2, dal 1, l 0, dl −1, cl −2, ml −3; m³ = 3, dm³ = 0, cm³ = −3.
        let vol: [(String, Int)] = [("m³", 3), ("dm³", 0), ("cm³", -3)]
        let cap = Self.magnitudes["capacidad"]!.unidades
        let v = rng.elemento(vol), c = rng.elemento(cap)
        let haciaCapacidad = rng.probabilidad(0.5)
        let valor = r(rng.entero(1...999), rng.elemento([1, 10, 100]))
        let factor = haciaCapacidad ? Self.potencia(10, v.1 - c.exponente) : Self.potencia(10, c.exponente - v.1)
        let sol = valor * factor
        let (de, a) = haciaCapacidad ? (v.0, c.simbolo) : (c.simbolo, v.0)
        let vs = FormatoNumero.numero(valor), ss = FormatoNumero.numero(sol)
        return Muestra(clave: "volcap|\(vs)|\(de)|\(a)", valores: ["cantidad": "\(vs) \(de)", "desde": de, "hasta": a, "resultado": "", "magnitud": "volumen y capacidad"],
                       payload: numerico(sol, unidad: a),
                       explicacion: "1 dm³ = 1 l (1 m³ = 1 kl, 1 cm³ = 1 ml). \(vs) \(de) = \(ss) \(a).",
                       erroresHabituales: erroresNumericos(sol, [(valor, "Volumen y capacidad no se miden igual: usa 1 dm³ = 1 l."),
                                                                 (sol * r(10), "Has dado un salto de más."), (sol / r(10), "Has dado un salto de menos.")]),
                       complejidad: 6 + Double(abs(v.1 - c.exponente)) * 0.3 + (valor.esEntero ? 0 : 1),
                       datos: ["volcap": "\(vs)|\(de)|\(a)", "respuesta": ss])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var claves: [String] = []
        if p.dificultad >= 5 && p.mecanica == .numerico {
            // Espacio de expresiones complejas: se cuenta por construcción (tiempo + longitudes).
            outer: for h in 1...5 { for mi in 1...59 { for s in 1...59 {
                claves.append("tiempo|\(h) h \(mi) min \(s) s|s"); if claves.count >= limite { break outer }
            } } }
            return claves
        }
        let c = casos(p.dificultad, p)
        for mag in c.magnitudes {
            guard let info = Self.magnitudes[mag] else { continue }
            for i in info.unidades.indices { for j in info.unidades.indices {
                let salto = abs(i - j)
                guard c.saltos.contains(salto), !c.soloMenor || j > i else { continue }
                let factor = Self.potencia(info.base, info.unidades[i].exponente - info.unidades[j].exponente)
                for v in c.valores {
                    let sol = v * factor
                    guard FormatoNumero.decimal(sol) != nil, sol.numerador < 100_000_000 else { continue }
                    claves.append([mag, FormatoNumero.numero(v), info.unidades[i].simbolo, info.unidades[j].simbolo, p.mecanica.rawValue].joined(separator: "|"))
                    if claves.count >= limite { return claves }
                }
            } }
        }
        return claves
    }
}

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

// MARK: - 4. ordenarNumeros

/// Ordenar fracciones y decimales (de mayor a menor o de menor a mayor).
///
/// | Dif. | Cantidad | Conjunto de números |
/// |---|---|---|
/// | 1 | 4 | decimales con una cifra entre 0,1 y 9,9 |
/// | 2 | 4 | decimales y fracciones de denominador 2, 4, 5 o 10 |
/// | 3 | 4 | decimales y fracciones de denominador ≤ 8 entre 0 y 2 |
/// | 4 | 5 | incluye fracciones impropias y decimales de dos cifras (0–3) |
/// | 5 | 5 | valores muy próximos entre 0,5 y 1 (fracciones ≤ 12 y centésimas) |
/// | 6 | 6 | incluye negativos (−2 a 2) y valores muy próximos |
struct GeneradorOrdenarNumeros: GeneradorItems {
    let tipo = "ordenarNumeros"
    let mecanicas: Set<Mecanica> = [.ordenar]
    let marcadores: Set<String> = ["orden", "numeros", "contexto"]

    struct Numero: Hashable { let valor: Racional; let texto: String }

    func conjunto(_ d: Int) -> (cantidad: Int, numeros: [Numero]) {
        var porValor: [Racional: Numero] = [:]
        func anadir(_ v: Racional, _ t: String) { if porValor[v] == nil { porValor[v] = Numero(valor: v, texto: t) } }
        func dec(_ v: Racional) { if let t = FormatoNumero.decimal(v) { anadir(v, t) } }
        func fr(_ n: Int, _ den: Int) { anadir(r(n, den), "\(n)/\(den)") }
        switch d {
        case 1: for k in 1...99 { dec(r(k, 10)) }
        case 2: for k in 1...20 { dec(r(k, 10)) }; for den in [2, 4, 5, 10] { for n in 1..<(2 * den) where Racional.mcd(n, den) == 1 { fr(n, den) } }
        case 3: for k in 1...19 { dec(r(k, 10)) }; for den in 2...8 { for n in 1..<(2 * den) where Racional.mcd(n, den) == 1 { fr(n, den) } }
        case 4: for k in 1...30 { dec(r(k * 10 + 5, 100)) }; for den in 2...6 { for n in 1..<(3 * den) where Racional.mcd(n, den) == 1 { fr(n, den) } }
        case 5: for k in 50...100 where k % 2 == 1 { dec(r(k, 100)) }; for den in 2...12 { for n in 1..<den where Racional.mcd(n, den) == 1 && 2 * n >= den { fr(n, den) } }
        default:
            for k in -20...20 where k != 0 { dec(r(k, 10)) }
            for den in 3...7 { for n in (-2 * den)...(2 * den) where n != 0 && Racional.mcd(abs(n), den) == 1 { fr(n, den) } }
        }
        let cantidad = d <= 3 ? 4 : (d <= 5 ? 5 : 6)
        return (cantidad, porValor.values.sorted { $0.valor.valorDouble < $1.valor.valorDouble })
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let (k, numeros) = conjunto(p.dificultad)
        guard numeros.count >= k else { throw ErrorGenerador.sinCaso(tipo) }
        // En los niveles 5 y 6 se eligen valores contiguos (muy próximos) de una ventana.
        let elegidos: [Numero]
        if p.dificultad >= 5 {
            let inicio = rng.entero(0...(numeros.count - k * 2))
            elegidos = Array(rng.barajar(Array(numeros[inicio..<(inicio + k * 2)])).prefix(k))
        } else {
            elegidos = Array(rng.barajar(numeros).prefix(k))
        }
        let ordenes = p.textos("orden", porDefecto: ["mayorAMenor", "menorAMayor"])
        let desc = rng.elemento(ordenes) == "mayorAMenor"
        let ordenados = elegidos.sorted { desc ? $0.valor.valorDouble > $1.valor.valorDouble : $0.valor.valorDouble < $1.valor.valorDouble }
        let mostrados = rng.barajar(elegidos)
        let fichas = mostrados.enumerated().map { ElementoTexto(id: "n\($0.offset + 1)", texto: $0.element.texto) }
        let idDe = Dictionary(uniqueKeysWithValues: zip(mostrados.map(\.texto), fichas.map(\.id)))
        let orden = ordenados.compactMap { idDe[$0.texto] }
        let huecoMin = zip(ordenados, ordenados.dropFirst()).map { abs($0.valor.valorDouble - $1.valor.valorDouble) }.min() ?? 1
        let equivalencias = ordenados.filter { $0.texto.contains("/") }.map { "\($0.texto) ≈ \(String(format: "%.3f", $0.valor.valorDouble).replacingOccurrences(of: ".", with: ","))" }
        let explicacion = (equivalencias.isEmpty ? "" : "Pasadas a decimal: " + equivalencias.joined(separator: "; ") + ". ")
            + (desc ? "De mayor a menor: " : "De menor a mayor: ") + ordenados.map(\.texto).joined(separator: desc ? " > " : " < ") + "."
        let clave = (desc ? "desc|" : "asc|") + elegidos.map(\.texto).sorted().joined(separator: ";")
        let fracciones = Double(elegidos.filter { $0.texto.contains("/") }.count)
        return Muestra(clave: clave,
                       valores: ["orden": desc ? "de mayor a menor" : "de menor a mayor", "numeros": mostrados.map(\.texto).joined(separator: "; ")],
                       payload: .ordenar(Payload.Ordenar(fichas: fichas, ordenCorrecto: orden, etiquetaInicio: desc ? "Mayor" : "Menor", etiquetaFin: desc ? "Menor" : "Mayor")),
                       explicacion: explicacion, pistas: ["Pasa las fracciones a decimal para compararlas."],
                       complejidad: Double(k) + fracciones * 0.5 + min(3, 0.1 / max(huecoMin, 0.001)) + (elegidos.contains { $0.valor.numerador < 0 } ? 1 : 0),
                       datos: ["orden": desc ? "desc" : "asc", "numeros": mostrados.map(\.texto).joined(separator: ";")])
    }

    /// El espacio son las combinaciones de `k` números del conjunto del nivel, en los dos sentidos.
    /// Se enumeran en orden lexicográfico hasta `limite`.
    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let (k, numeros) = conjunto(p.dificultad)
        let n = numeros.count
        guard n >= k else { return [] }
        var claves: [String] = []
        var idx = Array(0..<k)
        let sentidos = p.textos("orden", porDefecto: ["mayorAMenor", "menorAMayor"]).map { $0 == "mayorAMenor" ? "desc|" : "asc|" }
        while true {
            if p.dificultad < 5 || idx.last! - idx.first! < k * 2 {
                let textos = idx.map { numeros[$0].texto }.sorted().joined(separator: ";")
                for s in sentidos { claves.append(s + textos); if claves.count >= limite { return claves } }
            }
            var i = k - 1
            while i >= 0 && idx[i] == n - k + i { i -= 1 }
            if i < 0 { break }
            idx[i] += 1
            for j in (i + 1)..<k { idx[j] = idx[j - 1] + 1 }
        }
        return claves
    }
}

// MARK: - 5. romanos

/// Números romanos (1–3999): arábigo → romano (`construir`) y romano → arábigo (`numerico`).
///
/// | Dif. | Rango | Grupos sustractivos (IV, IX, XL, XC, CD, CM) |
/// |---|---|---|
/// | 1 | 1–39 | cualquiera |
/// | 2 | 40–399 | cualquiera |
/// | 3 | 400–1999 | como mucho 1 |
/// | 4 | 2000–3999 | como mucho 1 |
/// | 5 | 1–3999 | exactamente 2 |
/// | 6 | 1–3999 | 3 o más |
///
/// Error típico: leer sumando todos los símbolos sin restar (IX = 11); escribir IIII, VIIII…
struct GeneradorRomanos: GeneradorItems {
    let tipo = "romanos"
    let mecanicas: Set<Mecanica> = [.numerico, .construir]
    let marcadores: Set<String> = ["numero", "romano", "contexto"]

    static let grupos: [[String]] = [
        ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"],
        ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"],
        ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"],
        ["", "M", "MM", "MMM"],
    ]
    /// Escritura errónea típica de cada cifra (aditiva en 4 y 9; la cifra vecina en el resto).
    static let erroneos: [[String]] = [
        ["", "II", "III", "IIII", "IIII", "IV", "VII", "VIII", "IIX", "VIIII"],
        ["", "XX", "XXX", "XXXX", "XXXX", "XL", "LXX", "LXXX", "XXC", "LXXXX"],
        ["", "CC", "CCC", "CCCC", "CCCC", "CD", "DCC", "DCCC", "CCM", "DCCCC"],
        ["", "MM", "MMM", "MMMM"],
    ]

    static func cifras(_ n: Int) -> [Int] { [n % 10, n / 10 % 10, n / 100 % 10, n / 1000] }
    static func romano(_ n: Int) -> String { cifras(n).enumerated().reversed().map { grupos[$0.offset][$0.element] }.joined() }
    static func sustractivos(_ n: Int) -> Int { cifras(n).prefix(3).filter { $0 == 4 || $0 == 9 }.count }

    /// Lectura aditiva (error): suma todos los símbolos.
    static func lecturaAditiva(_ s: String) -> Int {
        let v: [Character: Int] = ["I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000]
        return s.reduce(0) { $0 + (v[$1] ?? 0) }
    }

    func valido(_ n: Int, _ d: Int) -> Bool {
        let s = Self.sustractivos(n)
        switch d {
        case 1: return (1...39).contains(n)
        case 2: return (40...399).contains(n)
        case 3: return (400...1999).contains(n) && s <= 1
        case 4: return (2000...3999).contains(n) && s <= 1
        case 5: return (1...3999).contains(n) && s == 2
        default: return (1...3999).contains(n) && s >= 3
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let candidatos = (1...3999).filter { valido($0, p.dificultad) }
        guard !candidatos.isEmpty else { throw ErrorGenerador.sinCaso(tipo) }
        let n = rng.elemento(candidatos)
        let rom = Self.romano(n)
        let complejidad = digitos(n) + Double(Self.sustractivos(n)) * 1.2 + Double(rom.count) * 0.1
        if p.mecanica == .construir {
            var piezas: [ElementoTexto] = []
            var huecos: [Payload.Construir.Hueco] = []
            func pieza(_ t: String) -> String {
                if let e = piezas.first(where: { $0.texto == t }) { return e.id }
                let id = "p\(piezas.count + 1)"
                piezas.append(ElementoTexto(id: id, texto: t))
                return id
            }
            for (lugar, cifra) in Self.cifras(n).enumerated().reversed() where cifra > 0 {
                let correcta = pieza(Self.grupos[lugar][cifra])
                _ = pieza(Self.erroneos[lugar][cifra])
                huecos.append(.init(id: "h\(huecos.count + 1)", correcta: correcta))
            }
            let plantilla = "\(n) = " + huecos.map { "{\($0.id)}" }.joined()
            return Muestra(clave: "aRomano|\(n)", valores: ["numero": "\(n)", "romano": ""],
                           payload: .construir(Payload.Construir(plantilla: plantilla, huecos: huecos, piezas: rng.barajar(piezas))),
                           explicacion: "\(n) se descompone en millares, centenas, decenas y unidades: \(rom).",
                           erroresHabituales: huecos.map { ErrorHabitual(respuesta: $0.id, feedback: "Un símbolo no se repite más de tres veces: 4 = IV, 9 = IX, 40 = XL, 90 = XC, 400 = CD, 900 = CM.") },
                           pistas: ["Escribe por separado millares, centenas, decenas y unidades."],
                           complejidad: complejidad, datos: ["numero": "\(n)", "romano": rom])
        }
        return Muestra(clave: "aArabigo|\(n)", valores: ["numero": "", "romano": rom],
                       payload: numerico(r(n)),
                       explicacion: "\(rom) = \(n): un símbolo menor delante de otro mayor resta.",
                       erroresHabituales: erroresNumericos(r(n), [(r(Self.lecturaAditiva(rom)), "Un símbolo menor delante de uno mayor resta: IX = 9, no 11.")]),
                       pistas: ["Lee de izquierda a derecha: si un símbolo es menor que el siguiente, se resta."],
                       complejidad: complejidad, datos: ["romano": rom, "respuesta": "\(n)"])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let prefijo = p.mecanica == .construir ? "aRomano|" : "aArabigo|"
        return Array((1...3999).filter { valido($0, p.dificultad) }.map { prefijo + "\($0)" }.prefix(limite))
    }
}

// MARK: - 6. operacionesCombinadas

/// Operaciones combinadas con paréntesis, corchetes y llaves, en dos fases: `ordenar` los pasos
/// (cadena: cada paso usa el resultado del anterior, así el orden es único) o dar el resultado
/// (`numerico`).
///
/// | Dif. | Operaciones | Agrupaciones | Números |
/// |---|---|---|---|
/// | 1 | 2 (+, −, ×) | ninguna obligatoria | 1–10 |
/// | 2 | 3 (+, −, ×) | paréntesis | 1–12 |
/// | 3 | 3 (con :) | paréntesis | 1–20 |
/// | 4 | 4 | paréntesis y corchetes | 1–20 |
/// | 5 | 5 | corchetes | 1–30 |
/// | 6 | 6 | llaves | 1–50 |
///
/// Errores: operar de izquierda a derecha sin jerarquía; ignorar los paréntesis.
struct GeneradorOperacionesCombinadas: GeneradorItems {
    let tipo = "operacionesCombinadas"
    let mecanicas: Set<Mecanica> = [.ordenar, .numerico]
    let marcadores: Set<String> = ["expresion", "contexto"]

    indirect enum Expr {
        case n(Int)
        case op(Character, Expr, Expr)

        var valor: Int? {
            switch self {
            case .n(let v): return v
            case .op(let o, let a, let b):
                guard let x = a.valor, let y = b.valor else { return nil }
                switch o {
                case "+": return x + y
                case "−": return x - y >= 0 ? x - y : nil
                case "×": return x * y
                default: return y != 0 && x % y == 0 ? x / y : nil
                }
            }
        }
        var prec: Int { if case .op(let o, _, _) = self { return o == "+" || o == "−" ? 1 : 2 }; return 3 }
        var operaciones: Int { if case .op(_, let a, let b) = self { return 1 + a.operaciones + b.operaciones }; return 0 }
    }

    /// Texto con agrupaciones mínimas: ( ) en el primer nivel, [ ] en el segundo y { } en el tercero.
    static func texto(_ e: Expr) -> (String, Int) {
        guard case .op(let o, let a, let b) = e else { if case .n(let v) = e { return ("\(v)", 0) }; return ("", 0) }
        func hijo(_ h: Expr, derecha: Bool) -> (String, Int) {
            let (t, prof) = texto(h)
            let necesita = h.prec < e.prec || (derecha && h.prec == e.prec && h.prec < 3)
            guard necesita else { return (t, prof) }
            let (abre, cierra) = [("(", ")"), ("[", "]"), ("{", "}")][min(prof, 2)]
            return (abre + t + cierra, prof + 1)
        }
        let (ta, pa) = hijo(a, derecha: false), (tb, pb) = hijo(b, derecha: true)
        return ("\(ta) \(o == ":" ? ":" : String(o)) \(tb)", max(pa, pb))
    }

    static let nombre: [Character: String] = ["+": "Sumar", "−": "Restar", "×": "Multiplicar", ":": "Dividir"]

    /// Pasos en el orden de la jerarquía (agrupaciones internas, × y : antes que + y −, de izquierda a derecha).
    static func pasos(_ e: Expr) -> [String] {
        var resultado: [String] = []
        func eval(_ e: Expr) -> Int {
            guard case .op(let o, let a, let b) = e else { if case .n(let v) = e { return v }; return 0 }
            let x = eval(a), y = eval(b)
            let v = Expr.op(o, .n(x), .n(y)).valor ?? 0
            resultado.append("\(nombre[o]!): \(x) \(o) \(y) = \(v)")
            return v
        }
        _ = eval(e)
        return resultado
    }

    /// Resultado operando estrictamente de izquierda a derecha sobre el texto plano (sin jerarquía
    /// ni agrupaciones): error típico.
    static func izquierdaADerecha(_ e: Expr) -> Int? {
        func planos(_ e: Expr) -> [String] {
            guard case .op(let o, let a, let b) = e else { if case .n(let v) = e { return ["\(v)"] }; return [] }
            return planos(a) + [String(o)] + planos(b)
        }
        let t = planos(e)
        guard var acc = Int(t[0]) else { return nil }
        var i = 1
        while i + 1 < t.count {
            guard let y = Int(t[i + 1]), let v = Expr.op(Character(t[i]), .n(acc), .n(y)).valor else { return nil }
            acc = v; i += 2
        }
        return acc
    }

    static func nivel(_ d: Int) -> (ops: Int, maxN: Int, division: Bool, prof: Int) {
        switch d {
        case 1: return (2, 10, false, 0)
        case 2: return (3, 12, false, 1)
        case 3: return (3, 20, true, 1)
        case 4: return (4, 20, true, 2)
        case 5: return (5, 30, true, 2)
        default: return (6, 50, true, 3)
        }
    }

    private func construirExpr(_ d: Int, cadena: Bool, rng: inout GeneradorConSemilla) -> Expr? {
        let nv = Self.nivel(d)
        let ops: [Character] = nv.division ? ["+", "−", "×", ":"] : ["+", "−", "×"]
        func numero() -> Expr { .n(rng.entero(1...nv.maxN)) }
        var e: Expr = .op(rng.elemento(ops), numero(), numero())
        while e.operaciones < nv.ops {
            let o = rng.elemento(ops)
            if cadena || rng.probabilidad(0.6) {
                e = rng.probabilidad(0.5) ? .op(o, e, numero()) : .op(o, numero(), e)
            } else {
                let otra: Expr = .op(rng.elemento(ops), numero(), numero())
                e = rng.probabilidad(0.5) ? .op(o, e, otra) : .op(o, otra, e)
            }
        }
        guard let v = e.valor, v >= 0, v <= 2000 else { return nil }
        let (_, prof) = Self.texto(e)
        guard prof >= min(nv.prof, 2), prof <= 3 else { return nil }
        return e
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let cadena = p.mecanica == .ordenar
        for _ in 0..<2000 {
            guard let e = construirExpr(p.dificultad, cadena: cadena, rng: &rng), let v = e.valor else { continue }
            let (t, prof) = Self.texto(e)
            let pasos = Self.pasos(e)
            guard Set(pasos).count == pasos.count else { continue }
            let explicacion = "Primero las agrupaciones de dentro afuera; después × y :, y por último + y −. " + pasos.joined(separator: " → ") + "."
            let complejidad = Double(e.operaciones) + Double(prof) + digitos(v) * 0.3
            if cadena {
                let barajados = rng.barajar(Array(pasos.enumerated()))
                let fichas = barajados.enumerated().map { ElementoTexto(id: "p\($0.offset + 1)", texto: $0.element.element) }
                let orden = pasos.indices.compactMap { i in barajados.firstIndex { $0.offset == i }.map { "p\($0 + 1)" } }
                return Muestra(clave: "ordenar|\(t)", valores: ["expresion": t],
                               payload: .ordenar(Payload.Ordenar(fichas: fichas, ordenCorrecto: orden, etiquetaInicio: "Primer paso", etiquetaFin: "Último paso")),
                               explicacion: explicacion, pistas: ["Empieza por la agrupación más interior."],
                               complejidad: complejidad, datos: ["expresion": t, "respuesta": "\(v)"])
            }
            let errores = erroresNumericos(r(v), [(Self.izquierdaADerecha(e).map { r($0) }, "Has operado de izquierda a derecha: resuelve primero las agrupaciones, después × y :, y al final + y −.")])
            return Muestra(clave: "numerico|\(t)", valores: ["expresion": t], payload: numerico(r(v)),
                           explicacion: explicacion, erroresHabituales: errores, pistas: ["Empieza por la agrupación más interior."],
                           complejidad: complejidad, datos: ["expresion": t, "respuesta": "\(v)"])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// El espacio de expresiones es enorme: se enumeran claves distintas recorriendo semillas
    /// consecutivas hasta `limite` (cota inferior del espacio; ver `CatalogoPreguntas`).
    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
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

// MARK: - 10. ecuacionLineal

/// Ecuaciones de primer grado con solución entera.
///
/// | Dif. | Forma | Coeficientes | Solución |
/// |---|---|---|---|
/// | 1 | x + b = c | b ≤ 20 | 1–20 |
/// | 2 | a·x = c | a 2–10 | 1–12 |
/// | 3 | a·x + b = c | a 2–9, b ≤ 30 | 1–15 |
/// | 4 | a·x − b = c | a 2–12 | −10 a 15 |
/// | 5 | a·x + b = c·x + d | a ≠ c | −10 a 15 |
/// | 6 | a·(x + b) = c·x + d | a ≠ c | −15 a 15 |
///
/// Errores: cambiar de miembro sin cambiar el signo; dividir antes de restar; olvidar dividir.
struct GeneradorEcuacionLineal: GeneradorItems {
    let tipo = "ecuacionLineal"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["ecuacion", "contexto"]

    static func signo(_ n: Int) -> String { n < 0 ? "− \(-n)" : "+ \(n)" }
    static func coef(_ a: Int) -> String { a == 1 ? "x" : "\(a)x" }

    struct Caso { let texto: String; let x: Int; let reglas: [(Racional?, String)]; let clave: String }

    func caso(_ d: Int, a: Int, b: Int, c: Int, x: Int) -> Caso? {
        switch d {
        case 1:
            return Caso(texto: "x + \(b) = \(x + b)", x: x, reglas: [(r(x + 2 * b), "Al pasar \(b) al otro miembro cambia de signo: se resta.")], clave: "1|\(b)|\(x)")
        case 2:
            return Caso(texto: "\(a)x = \(a * x)", x: x, reglas: [(r(a * x * a), "Si x está multiplicada por \(a), se despeja dividiendo."), (r(a * x - a), "Se divide, no se resta.")], clave: "2|\(a)|\(x)")
        case 3, 4:
            let bb = d == 3 ? b : -b
            let rhs = a * x + bb
            return Caso(texto: "\(Self.coef(a)) \(Self.signo(bb)) = \(rhs)", x: x,
                        reglas: [((r(rhs + bb) / r(a)), "Al pasar \(Self.signo(bb)) al otro miembro hay que cambiarle el signo."),
                                 (r(rhs - bb), "Falta dividir entre \(a)."),
                                 ((r(rhs) / r(a)).map { $0 - r(bb) }, "Primero se pasa el término independiente y después se divide.")],
                        clave: "\(d)|\(a)|\(bb)|\(x)")
        case 5:
            guard a != c else { return nil }
            let d2 = a * x + b - c * x
            return Caso(texto: "\(Self.coef(a)) \(Self.signo(b)) = \(Self.coef(c)) \(Self.signo(d2))", x: x,
                        reglas: [((r(d2 - b) / r(a + c)), "Al pasar \(Self.coef(c)) al primer miembro cambia de signo."),
                                 ((r(d2 + b) / r(a - c)), "Al pasar \(Self.signo(b)) al segundo miembro cambia de signo.")],
                        clave: "5|\(a)|\(b)|\(c)|\(x)")
        default:
            guard a != c else { return nil }
            let d2 = a * (x + b) - c * x
            return Caso(texto: "\(a)(x \(Self.signo(b))) = \(Self.coef(c)) \(Self.signo(d2))", x: x,
                        reglas: [((r(d2 - b) / r(a - c)), "El \(a) multiplica a los dos términos del paréntesis: \(a)x \(Self.signo(a * b))."),
                                 ((r(d2 - a * b) / r(a + c)), "Al pasar \(Self.coef(c)) al primer miembro cambia de signo.")],
                        clave: "6|\(a)|\(b)|\(c)|\(x)")
        }
    }

    static func rangos(_ d: Int) -> (a: ClosedRange<Int>, b: ClosedRange<Int>, c: ClosedRange<Int>, x: ClosedRange<Int>) {
        switch d {
        case 1: return (1...1, 1...20, 1...1, 1...20)
        case 2: return (2...10, 0...0, 1...1, 1...12)
        case 3: return (2...9, 1...30, 1...1, 1...15)
        case 4: return (2...12, 1...30, 1...1, -10...15)
        case 5: return (2...9, -20...20, 1...8, -10...15)
        default: return (2...6, -9...9, 1...8, -15...15)
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let rg = Self.rangos(p.dificultad)
        for _ in 0..<500 {
            guard let c = caso(p.dificultad, a: rng.entero(rg.a), b: rng.entero(rg.b), c: rng.entero(rg.c), x: rng.entero(rg.x)),
                  !(p.dificultad >= 5 && c.texto.contains("+ 0")) else { continue }
            return Muestra(clave: c.clave, valores: ["ecuacion": c.texto], payload: numerico(r(c.x)),
                           explicacion: "Se agrupan las x en un miembro y los números en el otro, y se despeja: x = \(c.x).",
                           erroresHabituales: erroresNumericos(r(c.x), c.reglas), pistas: ["Lo que suma en un miembro pasa restando al otro."],
                           complejidad: Double(p.dificultad >= 5 ? 3 : (p.dificultad >= 3 ? 2 : 1)) + (p.dificultad == 1 ? 0 : 0.5) + (c.x < 0 ? 1 : 0) + Double(c.texto.filter(\.isNumber).count) * 0.15 + (p.dificultad == 6 ? 1 : 0),
                           datos: ["ecuacion": c.texto, "respuesta": "\(c.x)"])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let rg = Self.rangos(p.dificultad)
        var claves: [String] = []
        for a in rg.a { for b in rg.b { for c in rg.c { for x in rg.x {
            guard let k = caso(p.dificultad, a: a, b: b, c: c, x: x), !(p.dificultad >= 5 && k.texto.contains("+ 0")) else { continue }
            claves.append(k.clave)
            if claves.count >= limite { return claves }
        } } } }
        return claves
    }
}
