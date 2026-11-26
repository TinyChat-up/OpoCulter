import Foundation

// Generadores de Matemáticas del lote 02 (parte A): porcentajes, regla de tres, unidades,
// tiempo sexagesimal y escalas. Las redacciones literales de la especificación de la dirección
// viven aquí (la plantilla usa `{{pregunta}}`) para que cada contexto solo se use con datos que
// tengan sentido (p. ej., alumnos enteros). Las redacciones propias se señalan con «A.2».

private typealias A = AyudaMat

// MARK: - C1. porcentajeDe

/// Porcentajes por competencia (`parametros.variante`): `calc` (MAT.POR.CALC), `total`
/// (MAT.POR.TOTAL) y `var` (MAT.POR.VAR).
///
/// | Dif. | Porcentajes | Base | Pasos |
/// |---|---|---|---|
/// | 1 | 10, 50 | múltiplos de 10 hasta 200 | 1 |
/// | 2 | 25, 20, 5 | múltiplos de 20 hasta 400 | 1 |
/// | 3 | 15, 30, 40, 75 | hasta 1000, resultado entero | 1 |
/// | 4 (examen) | 12, 15, 22, 35, 60, 12,5 | de 100 a 2000, ≤ 2 decimales | 1–2 |
/// | 5 | 1–99 | hasta 5000 | 2 |
/// | 6 | `var`: dos variaciones encadenadas; `total`: precio original tras una rebaja; `calc`: % con medios | hasta 10 000 | 2–3 |
struct GeneradorPorcentaje: GeneradorItems {
    let tipo = "porcentajeDe"
    let mecanicas: Set<Mecanica> = [.numerico, .construir]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    struct Nivel { let ps: [Racional]; let bases: [Int]; let maxDec: Int }

    static func nivel(_ d: Int, variante: String) -> Nivel {
        switch d {
        case 1: return Nivel(ps: [10, 50].map { rac($0) }, bases: Array(stride(from: 10, through: 200, by: 10)), maxDec: 0)
        case 2: return Nivel(ps: [25, 20, 5].map { rac($0) }, bases: Array(stride(from: 20, through: 400, by: 20)), maxDec: 0)
        case 3: return Nivel(ps: [15, 30, 40, 75].map { rac($0) }, bases: Array(20...1000), maxDec: 0)
        // Perfil del examen (2017 M16, 2022 M16, 2026 M16): porcentaje no redondo y base de 3 o 4 cifras.
        case 4: return Nivel(ps: [rac(12), rac(15), rac(22), rac(35), rac(60), rac(25, 2)], bases: Array(100...2000), maxDec: 2)
        case 5: return Nivel(ps: (1...99).map { rac($0) }, bases: Array(100...5000), maxDec: 2)
        default:
            if variante == "calc" { return Nivel(ps: (0...99).map { rac(2 * $0 + 1, 2) }, bases: Array(stride(from: 1000, through: 10_000, by: 10)), maxDec: 2) }
            return Nivel(ps: (1...12).map { rac($0 * 5) }, bases: Array(stride(from: 100, through: 10_000, by: 10)), maxDec: 2)
        }
    }

    /// Dificultad del porcentaje para el cálculo mental.
    static func clase(_ p: Racional) -> Double {
        guard p.esEntero else { return 2 }
        switch p.numerador {
        case 10, 50: return 0
        case 5, 20, 25: return 0.5
        case let n where n % 5 == 0: return 0.75
        default: return 1
        }
    }

    struct Caso { let variante: String; let sub: String; let p: Racional; let p2: Racional?; let base: Int; let sol: Racional; let parte: Racional; let final: Racional }

    /// Resuelve un caso (o `nil` si no cumple los decimales del nivel).
    static func resolver(variante: String, sub: String, p: Racional, p2: Racional?, base: Int, nivel n: Nivel) -> Caso? {
        let b = rac(base), parte = b * p * rac(1, 100)
        var sol: Racional
        var final = b
        switch sub {
        case "calc": sol = parte
        case "total": sol = b
        case "inv": final = b - parte; sol = b
        case "desc": sol = b - parte
        case "aum": sol = b + parte
        case "dd": let t = b - parte; sol = t - t * p2! * rac(1, 100)
        default: let t = b + parte; sol = t - t * p2! * rac(1, 100)
        }
        for v in [parte, sol, final] { guard let d = A.decimales(v), d <= n.maxDec, v.numerador > 0 else { return nil } }
        if let p2, p2 == p, sub == "dd" { return nil }
        return Caso(variante: variante, sub: sub, p: p, p2: p2, base: base, sol: sol, parte: parte, final: final)
    }

    static func subs(_ variante: String, _ d: Int) -> [String] {
        switch variante {
        case "total": return d >= 6 ? ["inv"] : ["total"]
        case "var": return d >= 6 ? ["dd", "ad"] : ["desc", "aum"]
        default: return ["calc"]
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let variante = p.textos("variante", porDefecto: ["calc"]).first ?? "calc"
        let n = Self.nivel(p.dificultad, variante: variante)
        for _ in 0..<600 {
            let sub = rng.elemento(Self.subs(variante, p.dificultad))
            let pc = rng.elemento(n.ps)
            let p2 = ["dd", "ad"].contains(sub) ? rng.elemento(n.ps) : nil
            let base = rng.elemento(n.bases)
            guard let c = Self.resolver(variante: variante, sub: sub, p: pc, p2: p2, base: base, nivel: n) else { continue }
            if p.mecanica == .construir, let p2, (rac(1) - pc * rac(1, 100)) == (rac(1) - p2 * rac(1, 100)) { continue }
            let m = construir(p, c, rng: &rng)
            return m.conPasos(Self.pasos(c, payload: p.mecanica == .construir ? m.payload : nil))
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Pasos del ejemplo resuelto (§5). Con `payload` (mecánica construir), el último paso es construir
    /// la operación.
    static func pasos(_ c: Caso, payload: Payload?) -> [PasoResuelto] {
        typealias P = Pasos
        let ps = A.texto(c.p), b = rac(c.base), bs = A.texto(b), pd = c.p * rac(1, 100)
        let porqueP = "porque el \(ps) % significa \(ps) de cada 100"
        var r: [PasoResuelto]
        switch c.sub {
        case "calc":
            r = [P.op("Pasa el porcentaje a número decimal", "\(ps) : 100", pd, porque: porqueP),
                 P.op("Multiplica la cantidad por ese número", "\(bs) × \(A.texto(pd))", c.sol)]
        case "total":
            let uno = c.parte / c.p
            r = [P.op("Divide la parte entre el porcentaje", "\(A.texto(c.parte)) : \(ps)", uno!, porque: "porque así sabes cuánto vale el 1 %"),
                 P.op("Multiplica por 100 para tener el total", "\(A.texto(uno!)) × 100", c.sol, porque: "porque el total es el 100 %")]
        case "inv":
            let q = rac(100) - c.p, uno = (c.final / q)!
            r = [P.op("Calcula qué porcentaje del precio pagas", "100 − \(ps)", q, porque: "porque la rebaja se quita del precio original"),
                 P.op("Divide el precio rebajado entre ese %", "\(A.euros(c.final)) : \(A.texto(q))", uno),
                 P.op("Multiplica por 100: es el precio original", "\(A.texto(uno)) × 100", c.sol, euros: true)]
        case "desc", "aum":
            let desc = c.sub == "desc"
            r = [P.op(desc ? "Calcula la rebaja" : "Calcula el aumento", "\(bs) × \(ps) : 100", c.parte, porque: porqueP, euros: true),
                 P.op(desc ? "Réstala del precio" : "Súmalo al precio", "\(bs) \(desc ? "−" : "+") \(A.euros(c.parte))", c.sol,
                      porque: desc ? "porque se paga el precio menos la rebaja" : "porque el precio nuevo es el de antes más la subida", euros: true)]
        default:
            let p2 = c.p2!, sube = c.sub == "ad"
            let tras1 = sube ? b + c.parte : b - c.parte
            let parte2 = tras1 * p2 * rac(1, 100)
            r = [P.op(sube ? "Aplica la subida" : "Aplica la primera rebaja", "\(bs) \(sube ? "+" : "−") \(A.euros(c.parte))", tras1, euros: true),
                 P.op("Calcula la segunda rebaja sobre ese precio", "\(A.euros(tras1)) × \(A.texto(p2)) : 100", parte2,
                      porque: "porque se aplica sobre lo que queda, no sobre el total", euros: true),
                 P.op("Réstala", "\(A.euros(tras1)) − \(A.euros(parte2))", c.sol, euros: true)]
        }
        if let payload { r.append(P.solucion("Construye la operación con esos números", payload: payload)) }
        return r
    }

    private func construir(_ p: Plantilla, _ c: Caso, rng: inout GeneradorConSemilla) -> Muestra {
        let ps = A.texto(c.p), bs = A.texto(rac(c.base)), b = rac(c.base)
        let nombre = rng.elemento(A.nombres)
        var pregunta = ""
        var reglas: [(Racional?, String)] = []
        var explicacion = ""
        var unidad: String? = "€"
        let coma = "Revisa la coma decimal: el \(ps) % son \(ps) de cada 100."
        switch c.sub {
        case "calc":
            var textos = ["¿Cuánto es el \(ps) % de \(bs)?",
                          "\(nombre) ha gastado el \(ps) % de sus \(bs) € ahorrados. ¿Cuántos euros ha gastado?"]
            if c.sol.esEntero && c.base <= 1000 { textos.append("En el colegio hay \(bs) alumnos y el \(ps) % come en el comedor. ¿Cuántos alumnos comen allí?") }
            let i = rng.entero(0...(textos.count - 1))
            pregunta = textos[i]
            unidad = i == 1 ? "€" : nil
            reglas = [(c.sol * rac(10), coma), (c.sol * rac(1, 10), coma),
                      (b - c.sol, "Has calculado lo que queda, no el \(ps) %: no hay que restar."),
                      (b / c.p, "Has dividido entre el porcentaje: multiplica por \(ps) y divide entre 100.")]
            explicacion = "\(ps) % de \(bs) = \(bs) × \(ps) : 100 = \(A.texto(c.sol))."
        case "total":
            let partes = A.texto(c.parte)
            var textos = ["El \(ps) % de un número es \(partes). ¿Cuál es el número?"]
            if c.parte.esEntero && c.base <= 1200 { textos.append("\(nombre) ha leído \(partes) páginas, que son el \(ps) % del libro. ¿Cuántas páginas tiene el libro?") }
            pregunta = rng.elemento(textos)
            unidad = nil
            reglas = [(c.parte * c.p * rac(1, 100), "Aquí \(partes) ya es el \(ps) % del total: no hay que calcular su porcentaje, sino dividir entre \(ps) y multiplicar por 100."),
                      ((c.parte * rac(100)) / (rac(100) - c.p), "Has usado el porcentaje que falta (\(A.texto(rac(100) - c.p)) %)."),
                      (c.parte + c.parte * c.p * rac(1, 100), "Has calculado el porcentaje sobre el resultado, no sobre la cantidad inicial."),
                      (c.sol * rac(10), coma)]
            explicacion = "Si \(partes) es el \(ps) %, el total es \(partes) × 100 : \(ps) = \(A.texto(c.sol))."
        case "inv":
            let fs = A.euros(c.final)
            // A.2: redacción propia (precio original a partir del rebajado).
            pregunta = "Tras una rebaja del \(ps) %, un artículo cuesta \(fs) €. ¿Cuánto costaba antes de la rebaja?"
            reglas = [(c.final + c.final * c.p * rac(1, 100), "Has calculado el porcentaje sobre el resultado, no sobre la cantidad inicial: el \(ps) % se rebajó del precio original."),
                      (c.final + c.p, "Has sumado los puntos del porcentaje como si fueran euros."),
                      ((c.final * rac(100)) / c.p, "El precio rebajado es el \(A.texto(rac(100) - c.p)) % del original, no el \(ps) %.")]
            explicacion = "Pagar \(fs) € es pagar el \(A.texto(rac(100) - c.p)) % del precio: \(fs) × 100 : \(A.texto(rac(100) - c.p)) = \(A.euros(c.sol)) €."
        case "desc", "aum":
            let desc = c.sub == "desc"
            if desc {
                let objeto = c.base <= 400 ? "Un abrigo" : (c.base <= 3000 ? "Un ordenador" : "Una furgoneta de segunda mano")
                pregunta = "\(objeto) cuesta \(bs) € y tiene un descuento del \(ps) %. ¿Cuánto se paga?"
            } else {
                pregunta = c.base <= 200 ? "Una entrada de \(bs) € sube un \(ps) %. ¿Cuál es el nuevo precio?"
                    : (c.base <= 3000 ? "Un alquiler de \(bs) € al mes sube un \(ps) %. ¿Cuál es el nuevo precio?"
                       : "Una reforma presupuestada en \(bs) € sube un \(ps) %. ¿Cuál es el nuevo precio?")
            }
            reglas = [(c.parte, desc ? "Esa es la rebaja, no el precio final: réstala de \(bs) €." : "Ese es solo el aumento: súmalo a \(bs) €."),
                      (desc ? b + c.parte : b - c.parte, desc ? "Has sumado la rebaja en lugar de restarla." : "Has restado el aumento en lugar de sumarlo."),
                      (desc ? b - c.p : b + c.p, "Has \(desc ? "restado" : "sumado") los puntos del porcentaje como si fueran euros."),
                      (c.sol * rac(1, 10), coma)]
            explicacion = "\(desc ? "Rebaja" : "Aumento"): \(bs) × \(ps) : 100 = \(A.euros(c.parte)) €. Precio final: \(bs) \(desc ? "−" : "+") \(A.euros(c.parte)) = \(A.euros(c.sol)) €."
        default:
            let p2s = A.texto(c.p2!)
            let tras1 = c.sub == "dd" ? b - c.parte : b + c.parte
            if c.sub == "dd" {
                pregunta = "Un artículo de \(bs) € se rebaja un \(ps) % y después otro \(p2s) % sobre el precio rebajado. ¿Cuál es el precio final?"
                reglas = [(b - b * (c.p + c.p2!) * rac(1, 100), "Los descuentos sucesivos no se suman: el segundo se aplica sobre el precio ya rebajado.")]
            } else {
                // A.2: aumento seguido de descuento.
                pregunta = "Un artículo de \(bs) € sube un \(ps) % y después se rebaja un \(p2s) % sobre el nuevo precio. ¿Cuál es el precio final?"
                reglas = [(b + b * (c.p - c.p2!) * rac(1, 100), "Las variaciones sucesivas no se suman ni se restan: la segunda se aplica sobre el precio ya modificado.")]
            }
            reglas += [(tras1, "Te falta aplicar la segunda variación (\(p2s) %)."),
                       (b - b * c.p2! * rac(1, 100), "La segunda variación se aplica sobre el precio ya modificado, no sobre el inicial.")]
            explicacion = "Primero: \(bs) \(c.sub == "dd" ? "−" : "+") \(ps) % = \(A.euros(tras1)) €. Después, −\(p2s) % sobre \(A.euros(tras1)) €: \(A.euros(c.sol)) €."
        }
        let pasos: Double = ["calc": 1, "total": 2, "desc": 2, "aum": 2, "inv": 3][c.sub] ?? 3
        let complejidad = pasos + log10(Double(c.base)) + 0.5 * Double(A.decimales(c.sol) ?? 0) + Self.clase(c.p) + (c.p2.map(Self.clase) ?? 0)
        let clave = [p.mecanica.rawValue, c.variante, c.sub, A.texto(c.p), c.p2.map(A.texto) ?? "-", "\(c.base)"].joined(separator: "|")
        let datos = ["variante": c.sub, "p": A.texto(c.p), "p2": c.p2.map(A.texto) ?? "", "base": "\(c.base)", "respuesta": A.texto(c.sol)]
        if p.mecanica == .construir { return justificacion(p, c, pregunta: pregunta, explicacion: explicacion, clave: clave, complejidad: complejidad, datos: datos, rng: &rng) }
        return Muestra(clave: clave, valores: ["pregunta": pregunta], payload: A.numerico(c.sol, unidad: unidad),
                       explicacion: explicacion, erroresHabituales: A.errores(c.sol, reglas),
                       pistas: ["El \(ps) % significa \(ps) de cada 100."], complejidad: complejidad, datos: datos)
    }

    /// Peldaño «Justifica»: se construye la operación con el factor multiplicador.
    private func justificacion(_ p: Plantilla, _ c: Caso, pregunta: String, explicacion: String, clave: String,
                               complejidad: Double, datos: [String: String], rng: inout GeneradorConSemilla) -> Muestra {
        let b = rac(c.base)
        func factor(_ pc: Racional, _ sube: Bool) -> Racional { sube ? rac(1) + pc * rac(1, 100) : rac(1) - pc * rac(1, 100) }
        var correctas: [(String, String)] = []
        var falsas: [String] = []
        let resultado = A.euros(c.sol)
        var plantilla = ""
        switch c.sub {
        case "dd", "ad":
            let f1 = factor(c.p, c.sub == "ad"), f2 = factor(c.p2!, false)
            plantilla = "\(A.texto(b)) € × {f1} × {f2} = {resultado} €"
            correctas = [("f1", A.texto(f1)), ("f2", A.texto(f2)), ("resultado", resultado)]
            let suma = c.sub == "dd" ? rac(1) - (c.p + c.p2!) * rac(1, 100) : rac(1) + (c.p - c.p2!) * rac(1, 100)
            falsas = [A.texto(suma), A.texto(c.p * rac(1, 100)), A.euros(b * suma)]
        default:
            let sube = c.sub == "aum"
            plantilla = "\(A.texto(b)) € × {factor} = {resultado} €"
            correctas = [("factor", A.texto(factor(c.p, sube))), ("resultado", resultado)]
            falsas = [A.texto(c.p * rac(1, 100)), A.texto(factor(c.p, !sube)), A.euros(c.parte), A.euros(sube ? b - c.parte : b + c.parte)]
        }
        var textos = Set(correctas.map(\.1))
        let distractores = falsas.filter { textos.insert($0).inserted }
        let piezas = rng.barajar(correctas.map(\.1) + distractores).enumerated().map { ElementoTexto(id: "p\($0.offset + 1)", texto: $0.element) }
        let huecos = correctas.map { h in Payload.Construir.Hueco(id: h.0, correcta: piezas.first { $0.texto == h.1 }!.id) }
        return Muestra(clave: clave, valores: ["pregunta": pregunta + " Construye la operación."],
                       payload: .construir(Payload.Construir(plantilla: plantilla, huecos: huecos, piezas: piezas)),
                       explicacion: explicacion,
                       erroresHabituales: [ErrorHabitual(respuesta: "construir", feedback: c.sub == "dd" ? "Los descuentos sucesivos no se suman: el segundo se aplica sobre el precio ya rebajado." : "Quitar el \(A.texto(c.p)) % es multiplicar por \(A.texto(rac(1) - c.p * rac(1, 100))); subirlo, por \(A.texto(rac(1) + c.p * rac(1, 100))).")],
                       complejidad: complejidad, datos: datos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let variante = p.textos("variante", porDefecto: ["calc"]).first ?? "calc"
        let n = Self.nivel(p.dificultad, variante: variante)
        var claves: [String] = []
        for sub in Self.subs(variante, p.dificultad) { for pc in n.ps {
            for p2 in (["dd", "ad"].contains(sub) ? n.ps.map(Optional.some) : [nil]) { for base in n.bases {
                guard let c = Self.resolver(variante: variante, sub: sub, p: pc, p2: p2, base: base, nivel: n) else { continue }
                if p.mecanica == .construir, let p2, (rac(1) - pc * rac(1, 100)) == (rac(1) - p2 * rac(1, 100)) { continue }
                claves.append([p.mecanica.rawValue, c.variante, c.sub, A.texto(pc), p2.map(A.texto) ?? "-", "\(base)"].joined(separator: "|"))
                if claves.count >= limite { return claves }
            } }
        } }
        return claves
    }
}

// MARK: - C2. reglaDeTres

/// Proporcionalidad directa (MAT.POR.PROP).
///
/// | Dif. | Caso |
/// |---|---|
/// | 1 | factor ×2 (recetas y precios) |
/// | 2 | factor ×3 o ×4, cantidades mayores |
/// | 3 | factor fraccionario con números pequeños (de 4 a 6 personas) |
/// | 4 | factor fraccionario con números mayores; también velocidad y distancia |
/// | 5 | reducción a la unidad con decimales (precios y consumo) |
/// | 6 | dos magnitudes encadenadas (consumo y precio del litro) |
struct GeneradorReglaDeTres: GeneradorItems {
    let tipo = "reglaDeTres"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    static let ingredientes: [(nombre: String, unidad: String, palabra: String)] = [
        ("harina", "g", "gramos"), ("azúcar", "g", "gramos"), ("arroz", "g", "gramos"),
        ("mantequilla", "g", "gramos"), ("leche", "ml", "mililitros"), ("tomate", "g", "gramos"),
    ]
    static let objetos = ["cuadernos", "lápices", "bolígrafos", "barras de pan", "entradas de cine", "botellas de agua", "libretas", "kilos de naranjas"]

    /// Caso: a1 → b1 (dato) y a2 (pregunta); en la 6, l litros cada 100 km a pl € el litro.
    struct Caso { let modo: String; let a1: Int; let b1: Racional; let a2: Int; let extra: Racional? }

    static func valido(_ c: Caso) -> Racional? {
        let sol: Racional
        if c.modo == "cadena" { sol = c.b1 * rac(c.a2, 100) * c.extra! } else { sol = c.b1 * rac(c.a2, c.a1) }
        guard let d = AyudaMat.decimales(sol), d <= 2, sol.numerador > 0 else { return nil }
        if c.modo != "precio" && c.modo != "cadena" && c.modo != "consumo" && !sol.esEntero { return nil }
        return sol
    }

    func caso(_ d: Int, rng: inout GeneradorConSemilla) -> Caso {
        switch d {
        case 1:
            let a1 = rng.entero(2...4)
            return rng.probabilidad(0.5) ? Caso(modo: "receta", a1: a1, b1: rac(25 * rng.entero(2...8)), a2: 2 * a1, extra: nil)
                : Caso(modo: "precio", a1: a1, b1: rac(rng.entero(2...12)), a2: 2 * a1, extra: nil)
        case 2:
            let a1 = rng.entero(2...5), f = rng.entero(3...4)
            return rng.probabilidad(0.5) ? Caso(modo: "receta", a1: a1, b1: rac(10 * rng.entero(10...50)), a2: f * a1, extra: nil)
                : Caso(modo: "precio", a1: a1, b1: rac(rng.entero(8...40)), a2: f * a1, extra: nil)
        case 3:
            let a1 = rng.elemento([2, 3, 4, 6, 8]), a2 = rng.entero(2...12)
            return Caso(modo: rng.probabilidad(0.6) ? "receta" : "precio", a1: a1, b1: rac(rng.entero(2...60) * a1), a2: a2, extra: nil)
        case 4:
            let a1 = rng.entero(3...12), a2 = rng.entero(4...20)
            let modo = rng.elemento(["receta", "precio", "velocidad"])
            return Caso(modo: modo, a1: a1, b1: rac(rng.entero(5...90) * a1), a2: a2, extra: nil)
        case 5:
            if rng.probabilidad(0.5) {
                let a1 = rng.entero(3...9)
                return Caso(modo: "precio", a1: a1, b1: rac(rng.entero(40...900) * a1, 20), a2: rng.entero(2...15), extra: nil)
            }
            return Caso(modo: "consumo", a1: 100, b1: rac(rng.entero(45...95), 10), a2: 10 * rng.entero(5...60), extra: nil)
        default:
            return Caso(modo: "cadena", a1: 100, b1: rac(rng.entero(45...95), 10), a2: 10 * rng.entero(5...60), extra: rac(rng.entero(130...190), 100))
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        for _ in 0..<500 {
            let c = caso(p.dificultad, rng: &rng)
            guard c.a1 != c.a2, let sol = Self.valido(c) else { continue }
            if p.dificultad >= 3 && p.dificultad <= 4 && c.a2 % c.a1 == 0 { continue }
            return construir(c, sol: sol, dificultad: p.dificultad, rng: &rng).conPasos(Self.pasos(c, sol: sol))
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Pasos del ejemplo resuelto (§5): reducción a la unidad.
    static func pasos(_ c: Caso, sol: Racional) -> [PasoResuelto] {
        let u = c.b1 * rac(1, c.a1)
        let porque = "porque si una cantidad se multiplica, la otra también"
        if c.modo == "cadena" {
            let litros = u * rac(c.a2)
            return [Pasos.op("Calcula los litros por kilómetro", "\(AyudaMat.texto(c.b1)) : 100", u, porque: porque),
                    Pasos.op("Multiplica por los kilómetros del viaje", "\(AyudaMat.texto(u)) × \(c.a2)", litros),
                    Pasos.op("Multiplica por el precio del litro", "\(AyudaMat.texto(litros)) × \(AyudaMat.euros(c.extra!))", sol,
                             porque: "porque cada litro cuesta lo mismo", euros: true)]
        }
        return [Pasos.op("Reduce a la unidad: divide entre \(c.a1)", "\(AyudaMat.texto(c.b1)) : \(c.a1)", u, porque: porque, euros: c.modo == "precio"),
                Pasos.op("Multiplica por \(c.a2)", "\(AyudaMat.texto(u)) × \(c.a2)", sol, euros: c.modo == "precio")]
    }

    private func construir(_ c: Caso, sol: Racional, dificultad d: Int, rng: inout GeneradorConSemilla) -> Muestra {
        let factor = rac(c.a2, c.a1)
        let fs = AyudaMat.texto(factor)
        var pregunta = "", unidad = "", explicacion = ""
        var reglas: [(Racional?, String)] = [
            (c.b1 * rac(c.a1, c.a2), "Es proporcionalidad directa: si aumenta una cantidad, la otra también aumenta."),
            (c.b1 * rac(c.a2), "Has multiplicado por \(c.a2), pero falta dividir entre \(c.a1)."),
        ]
        let aditivo = c.b1 + rac(c.a2 - c.a1)
        switch c.modo {
        case "receta":
            let ing = rng.elemento(Self.ingredientes)
            unidad = ing.unidad
            pregunta = "Una receta para \(c.a1) personas lleva \(AyudaMat.texto(c.b1)) \(ing.unidad) de \(ing.nombre). ¿Cuántos \(ing.palabra) hacen falta para \(c.a2) personas?"
            reglas.insert((aditivo, "De \(c.a1) a \(c.a2) personas son \(abs(c.a2 - c.a1)) \(c.a2 > c.a1 ? "más" : "menos"), pero no se \(c.a2 > c.a1 ? "suma" : "resta"): se multiplica por \(fs)."), at: 0)
            explicacion = "Para 1 persona: \(AyudaMat.texto(c.b1)) : \(c.a1); para \(c.a2): × \(c.a2). Resultado: \(AyudaMat.texto(sol)) \(ing.unidad)."
        case "precio":
            let obj = rng.elemento(Self.objetos)
            unidad = "€"
            pregunta = "Si \(c.a1) \(obj) cuestan \(AyudaMat.euros(c.b1)) €, ¿cuánto cuestan \(c.a2)?"
            reglas.insert((aditivo, "No se suma la diferencia de unidades: el precio se multiplica por \(fs)."), at: 0)
            explicacion = "Precio de uno: \(AyudaMat.euros(c.b1)) : \(c.a1) = \(AyudaMat.euros(c.b1 * rac(1, c.a1))) €. De \(c.a2): \(AyudaMat.euros(sol)) €."
        case "velocidad":
            unidad = "km"
            // A.2: velocidad y distancia.
            pregunta = "Un tren recorre \(AyudaMat.texto(c.b1)) km en \(c.a1) horas a velocidad constante. ¿Cuántos kilómetros recorre en \(c.a2) horas?"
            reglas.insert((aditivo, "No se suma la diferencia de horas: la distancia se multiplica por \(fs)."), at: 0)
            explicacion = "En 1 hora: \(AyudaMat.texto(c.b1)) : \(c.a1) = \(AyudaMat.texto(c.b1 * rac(1, c.a1))) km. En \(c.a2) horas: \(AyudaMat.texto(sol)) km."
        case "consumo":
            unidad = "l"
            // A.2: consumo.
            pregunta = "Un coche gasta \(AyudaMat.texto(c.b1)) l de gasolina cada 100 km. ¿Cuántos litros gasta en \(c.a2) km?"
            reglas.insert((aditivo, "No se suma la diferencia de kilómetros: el consumo se multiplica por \(fs)."), at: 0)
            explicacion = "En 1 km: \(AyudaMat.texto(c.b1)) : 100. En \(c.a2) km: \(AyudaMat.texto(c.b1)) × \(c.a2) : 100 = \(AyudaMat.texto(sol)) l."
        default:
            unidad = "€"
            let litros = c.b1 * rac(c.a2, 100)
            // A.2: dos magnitudes encadenadas.
            pregunta = "Un coche gasta \(AyudaMat.texto(c.b1)) l de gasolina cada 100 km y el litro cuesta \(AyudaMat.euros(c.extra!)) €. ¿Cuánto cuesta la gasolina para recorrer \(c.a2) km?"
            reglas = [(litros, "Eso son los litros: falta multiplicar por el precio del litro."),
                      (rac(c.a2) * c.extra!, "Has multiplicado los kilómetros por el precio: primero calcula los litros que se gastan."),
                      (c.b1 * c.extra!, "Ese es el coste de 100 km, no el de \(c.a2) km.")]
            explicacion = "Litros: \(AyudaMat.texto(c.b1)) × \(c.a2) : 100 = \(AyudaMat.texto(litros)) l. Coste: \(AyudaMat.texto(litros)) × \(AyudaMat.euros(c.extra!)) = \(AyudaMat.euros(sol)) €."
        }
        let pasos: Double = c.modo == "cadena" ? 3 : (factor.esEntero ? 1 : 2)
        let maximo = max(c.b1.valorDouble, Double(c.a2), sol.valorDouble)
        let complejidad = pasos * 1.5 + log10(max(1, maximo)) + Double(AyudaMat.decimales(sol) ?? 0) + (c.b1.esEntero ? 0 : 0.5)
        return Muestra(clave: [c.modo, "\(c.a1)", AyudaMat.texto(c.b1), "\(c.a2)", c.extra.map(AyudaMat.texto) ?? "-"].joined(separator: "|"),
                       valores: ["pregunta": pregunta], payload: AyudaMat.numerico(sol, unidad: unidad),
                       explicacion: explicacion, erroresHabituales: AyudaMat.errores(sol, reglas),
                       pistas: ["Calcula primero cuánto corresponde a una unidad."], complejidad: complejidad,
                       datos: ["modo": c.modo, "a1": "\(c.a1)", "b1": AyudaMat.texto(c.b1), "a2": "\(c.a2)", "extra": c.extra.map(AyudaMat.texto) ?? "", "respuesta": AyudaMat.texto(sol)])
    }

    /// El espacio es muy grande: se enumera por muestreo determinista.
    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var vistos = Set<String>()
        var rng = GeneradorConSemilla(semilla: 7)
        for _ in 0..<min(limite, 20_000) {
            let c = caso(p.dificultad, rng: &rng)
            guard c.a1 != c.a2, Self.valido(c) != nil else { continue }
            // Mismo filtro que `muestra`: en dificultad 3–4 el factor no es entero.
            if p.dificultad >= 3 && p.dificultad <= 4 && c.a2 % c.a1 == 0 { continue }
            vistos.insert([c.modo, "\(c.a1)", AyudaMat.texto(c.b1), "\(c.a2)", c.extra.map(AyudaMat.texto) ?? "-"].joined(separator: "|"))
        }
        return Array(vistos)
    }
}
