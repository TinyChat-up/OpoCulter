import Foundation

// Generadores de Matemáticas del lote 02 (parte B): conversión de unidades, tiempo sexagesimal
// y escalas. Redacciones propias señaladas con «A.2».

private typealias A = AyudaMat

// MARK: - C3. conversionUnidades

/// Conversión de unidades por familia (`parametros.familia`): `lmc` (longitud, masa y capacidad,
/// MAT.UNI.LMC), `sup` (superficie, MAT.UNI.SUP) y `vol` (volumen y capacidad, MAT.UNI.VOL).
///
/// | Dif. | lmc | sup | vol |
/// |---|---|---|---|
/// | 1 | 1 cambio habitual (m → cm, kg → g, l → ml) | 1 salto (×100) | 1 salto (×1000) |
/// | 2 | 2–3 saltos, en los dos sentidos | 2 saltos | 2 saltos |
/// | 3 | compleja → incompleja («3 km 25 m = ? m») | compleja → incompleja | volumen ↔ capacidad (1 dm³ = 1 l) |
/// | 4 | examen: compleja de 3 términos → unidad intermedia (2022 M14) | compleja → unidad mayor | compleja → unidad mayor |
/// | 5 | suma de 3 cantidades con decimales | suma con decimales | volumen ↔ capacidad con saltos y decimales |
/// | 6 | capacidad → masa de agua (1 l = 1 kg) | unidades agrarias (ha, a, ca) | volumen → capacidad → masa de agua |
struct GeneradorConversionUnidades: GeneradorItems {
    let tipo = "conversionUnidades"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    /// Unidad: magnitud (L, M, C, S, V; las agrarias son S) y exponente de 10 respecto a la base
    /// (m, g, l, m²; el volumen se expresa en litros: 1 dm³ = 1 l).
    struct Unidad: Equatable { let simbolo: String; let magnitud: Character; let e: Int }
    static let listas: [Character: [Unidad]] = [
        "L": [("km", 3), ("hm", 2), ("dam", 1), ("m", 0), ("dm", -1), ("cm", -2), ("mm", -3)].map { Unidad(simbolo: $0.0, magnitud: "L", e: $0.1) },
        "M": [("kg", 3), ("hg", 2), ("dag", 1), ("g", 0), ("dg", -1), ("cg", -2), ("mg", -3)].map { Unidad(simbolo: $0.0, magnitud: "M", e: $0.1) },
        "C": [("kl", 3), ("hl", 2), ("dal", 1), ("l", 0), ("dl", -1), ("cl", -2), ("ml", -3)].map { Unidad(simbolo: $0.0, magnitud: "C", e: $0.1) },
        "S": [("km²", 6), ("hm²", 4), ("dam²", 2), ("m²", 0), ("dm²", -2), ("cm²", -4), ("mm²", -6)].map { Unidad(simbolo: $0.0, magnitud: "S", e: $0.1) },
        "V": [("m³", 3), ("dm³", 0), ("cm³", -3), ("mm³", -6)].map { Unidad(simbolo: $0.0, magnitud: "V", e: $0.1) },
        "A": [("ha", 4), ("a", 2), ("ca", 0)].map { Unidad(simbolo: $0.0, magnitud: "S", e: $0.1) },
    ]
    static func unidad(_ s: String) -> Unidad { listas.values.flatMap { $0 }.first { $0.simbolo == s }! }

    struct Caso { var terminos: [(Racional, Unidad)]; var destino: Unidad; var agua: Bool; var modo: String }

    /// Resultado exacto del caso.
    static func resolver(_ c: Caso) -> Racional {
        var total = rac(0)
        for (v, u) in c.terminos { total = total + v * A.potencia(10, u.e + (c.agua ? 3 : 0)) }
        return total * A.potencia(10, -c.destino.e)
    }

    static func cantidad(_ c: Caso, separador: String = " ") -> String { c.terminos.map { "\(A.texto($0.0)) \($0.1.simbolo)" }.joined(separator: separador) }

    func caso(_ familia: String, _ d: Int, rng: inout GeneradorConSemilla) -> Caso? {
        let lineal = rng.elemento(["L", "M", "C"] as [Character])
        let mag: Character = familia == "sup" ? "S" : (familia == "vol" ? "V" : lineal)
        let lista = Self.listas[mag]!
        func simple(saltos: ClosedRange<Int>, soloBajar: Bool, valores: [Racional]) -> Caso? {
            let i = rng.entero(0...(lista.count - 1)), s = rng.entero(saltos)
            let j = soloBajar || rng.probabilidad(0.5) ? i + s : i - s
            guard lista.indices.contains(j) else { return nil }
            return Caso(terminos: [(rng.elemento(valores), lista[i])], destino: lista[j], agua: false, modo: rng.elemento(["expresa", "cuantos"]))
        }
        func compleja(_ l: [Unidad], terminos: ClosedRange<Int>, decimal: Bool = false) -> [(Racional, Unidad)] {
            let n = min(rng.entero(terminos), l.count)
            let indices = Array(rng.barajar(Array(l.indices)).prefix(n)).sorted()
            return indices.enumerated().map { k, i in
                let v = decimal && k == 0 ? rac(rng.entero(11...99), 10) : rac(rng.entero(1...(k == n - 1 ? 99 : 9)))
                return (v, l[i])
            }
        }
        switch (familia, d) {
        case ("lmc", 1):
            let par = rng.elemento([("km", "m"), ("m", "cm"), ("m", "mm"), ("cm", "mm"), ("kg", "g"), ("l", "ml"), ("l", "cl")])
            return Caso(terminos: [(rac(rng.entero(1...20)), Self.unidad(par.0))], destino: Self.unidad(par.1), agua: false, modo: rng.elemento(["expresa", "cuantos"]))
        case (_, 1): return simple(saltos: 1...1, soloBajar: true, valores: (1...(familia == "vol" ? 20 : 50)).map { rac($0) })
        case ("lmc", 2): return simple(saltos: 2...3, soloBajar: false, valores: (1...999).map { rac($0) })
        case ("vol", 2):
            // Dos saltos de volumen son ×1.000.000: al bajar, cantidades de una cifra (3 m³ = 3.000.000 cm³);
            // al subir, millones exactos (5.000.000 cm³ = 5 m³). Así el resultado es entero y legible.
            let i = rng.entero(0...1), k = rng.entero(1...9)
            let modo = rng.elemento(["expresa", "cuantos"])
            if rng.probabilidad(0.5) { return Caso(terminos: [(rac(k), lista[i])], destino: lista[i + 2], agua: false, modo: modo) }
            return Caso(terminos: [(rac(k * 1_000_000), lista[i + 2])], destino: lista[i], agua: false, modo: modo)
        case (_, 2): return simple(saltos: 2...2, soloBajar: false, valores: (1...999).map { rac($0) })
        case ("vol", 3):
            let v = rng.elemento(Array(Self.listas["V"]!.prefix(3))), cap = rng.elemento(Self.listas["C"]!)
            let haciaCapacidad = rng.probabilidad(0.6)
            let (de, a) = haciaCapacidad ? (v, cap) : (cap, v)
            let modo = de.simbolo == "dm³" && a.simbolo == "l" ? "deposito" : rng.elemento(["expresa", "cuantos"])
            return Caso(terminos: [(rac(rng.entero(1...99)), de)], destino: a, agua: false, modo: modo)
        case (_, 3):
            let t = compleja(lista, terminos: 2...(familia == "sup" ? 2 : 3))
            let menor = t.map(\.1).last!
            let idx = lista.firstIndex(of: menor)!
            return Caso(terminos: t, destino: lista[min(lista.count - 1, idx + rng.entero(0...1))], agua: false, modo: "expresa")
        case ("lmc", 4):
            // Perfil del examen: 3 términos (el último, de hasta dos cifras) → una unidad entre la mayor y la menor.
            let t = compleja(lista, terminos: 3...3)
            let i0 = lista.firstIndex(of: t[0].1)!, i2 = lista.firstIndex(of: t[2].1)!
            return Caso(terminos: t, destino: lista[rng.entero((i0 + 1)...(i2 - 1))], agua: false, modo: "expresa")
        case (_, 4):
            let t = compleja(lista, terminos: 2...2)
            return Caso(terminos: t, destino: t[0].1, agua: false, modo: "expresa")
        case ("vol", 5):
            let v = rng.elemento(Array(Self.listas["V"]!.prefix(3))), cap = rng.elemento(Self.listas["C"]!)
            let haciaCapacidad = rng.probabilidad(0.6)
            let (de, a) = haciaCapacidad ? (v, cap) : (cap, v)
            guard abs(de.e - a.e) >= 2 else { return nil }
            return Caso(terminos: [(rac(rng.entero(1...999), rng.elemento([10, 100])), de)], destino: a, agua: false, modo: rng.elemento(["expresa", "cuantos"]))
        case (_, 5):
            let t = compleja(lista, terminos: (familia == "lmc" ? 3 : 2)...3, decimal: true)
            let medio = lista[min(lista.count - 1, lista.firstIndex(of: t[0].1)! + 1 + rng.entero(0...1))]
            return Caso(terminos: t, destino: medio, agua: false, modo: "suma")
        case ("lmc", _):
            let t = compleja(Self.listas["C"]!, terminos: 2...3)
            return Caso(terminos: t, destino: Self.unidad(rng.elemento(["kg", "g"])), agua: true, modo: "pesa")
        case ("sup", _):
            let t = compleja(Self.listas["A"]!, terminos: 2...3)
            return Caso(terminos: t, destino: Self.unidad(rng.elemento(["ha", "m²", "hm²"])), agua: false, modo: "finca")
        default:
            let u = rng.elemento(Array(Self.listas["V"]!.prefix(3)))
            return Caso(terminos: [(rac(rng.entero(11...999), 10), u)], destino: Self.unidad("kg"), agua: true, modo: "depositoMasa")
        }
    }

    static func valido(_ c: Caso, _ sol: Racional) -> Bool {
        guard let d = A.decimales(sol), d <= 4, sol.numerador > 0, sol.valorDouble < 10_000_000 else { return false }
        return c.terminos.count == Set(c.terminos.map(\.1.simbolo)).count
    }

    /// Cifras de un entero sin contar los ceros finales (2500 → 2).
    static func cifrasSignificativas(_ n: Int) -> Double {
        var m = abs(n)
        while m >= 10 && m % 10 == 0 { m /= 10 }
        return A.cifras(m)
    }

    /// Filtro común de `muestra` y `enumerar` (el recuento del catálogo solo cuenta casos que se
    /// pueden generar): caso válido, con conversión real y resultado entero hasta la dificultad 3.
    static func aceptable(_ c: Caso, _ sol: Racional, dificultad: Int) -> Bool {
        valido(c, sol) && (c.terminos.count > 1 || c.terminos[0].1 != c.destino) && (dificultad > 3 || sol.esEntero)
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let familia = p.textos("familia", porDefecto: ["lmc"]).first ?? "lmc"
        for _ in 0..<500 {
            guard let c = caso(familia, p.dificultad, rng: &rng) else { continue }
            let sol = Self.resolver(c)
            guard Self.aceptable(c, sol, dificultad: p.dificultad) else { continue }
            return construir(c, sol: sol, familia: familia).conPasos(Self.pasos(c, sol: sol))
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Pasos del ejemplo resuelto (§5): la equivalencia de cada unidad con la de destino (calculada) y
    /// la conversión de cada término; con varios términos, la suma.
    static func pasos(_ c: Caso, sol: Racional) -> [PasoResuelto] {
        let hasta = c.destino.simbolo
        let u0 = c.terminos[0].1
        let cambio = (u0.magnitud == "V") != (c.destino.magnitud == "V")
        let porque: String = c.agua ? "porque 1 l de agua pesa 1 kg"
            : cambio ? "porque 1 dm³ ocupa lo mismo que 1 l"
            : u0.magnitud == "S" ? "porque en superficie cada unidad es 100 veces la siguiente"
            : u0.magnitud == "V" ? "porque en volumen cada unidad es 1.000 veces la siguiente"
            : "porque cada unidad es 10 veces la siguiente"
        func factor(_ u: Unidad) -> Racional { A.potencia(10, u.e + (c.agua ? 3 : 0) - c.destino.e) }
        func convertir(_ v: Racional, _ u: Unidad) -> String {
            let f = factor(u)
            return A.menor(f, rac(1)) ? "\(A.texto(v)) : \(A.texto((rac(1) / f)!))" : "\(A.texto(v)) × \(A.texto(f))"
        }
        var r: [PasoResuelto] = []
        if c.terminos.count == 1 {
            let (v, u) = c.terminos[0]
            r.append(Pasos.op("Busca la equivalencia entre \(u.simbolo) y \(hasta)", "1 \(u.simbolo) en \(hasta)", factor(u), porque: porque))
            r.append(Pasos.op(A.menor(factor(u), rac(1)) ? "Divide la cantidad" : "Multiplica la cantidad", convertir(v, u), sol))
            return r
        }
        for (v, u) in c.terminos where factor(u) != rac(1) {
            r.append(Pasos.op("Pasa \(A.texto(v)) \(u.simbolo) a \(hasta)", convertir(v, u), v * factor(u), porque: r.isEmpty ? porque : nil))
        }
        let sumandos = c.terminos.map { A.texto($0.0 * factor($0.1)) }.joined(separator: " + ")
        r.append(Pasos.op("Suma, ya en la misma unidad", sumandos, sol, porque: "porque solo se suman cantidades de la misma unidad"))
        return r
    }

    private func construir(_ c: Caso, sol: Racional, familia: String) -> Muestra {
        let cantidad = Self.cantidad(c), hasta = c.destino.simbolo
        let pregunta: String
        switch c.modo {
        case "cuantos": pregunta = "¿Cuántos \(hasta) son \(cantidad)?"
        case "deposito": pregunta = "Un depósito de \(cantidad) se llena de agua. ¿Cuántos litros caben?"
        case "suma": pregunta = "Calcula y expresa en \(hasta): \(Self.cantidad(c, separador: " + "))."   // A.2
        case "pesa": pregunta = "¿Cuántos \(hasta == "kg" ? "kilogramos" : "gramos") pesan \(cantidad) de agua? (1 l de agua pesa 1 kg)."   // A.2
        case "finca": pregunta = "Una finca mide \(cantidad). Expresa su superficie en \(hasta)."   // A.2
        case "depositoMasa": pregunta = "Un depósito de \(cantidad) se llena de agua. ¿Cuántos kilogramos de agua caben? (1 l de agua pesa 1 kg)."   // A.2
        default: pregunta = "Expresa \(cantidad) en \(hasta)."
        }
        let (v0, u0) = c.terminos[0]
        let saltoBase: Int = u0.magnitud == "S" ? 100 : (u0.magnitud == "V" ? 1000 : 10)
        let cambio = (u0.magnitud == "V") != (c.destino.magnitud == "V") || c.agua
        var reglas: [(Racional?, String)] = []
        if c.terminos.count == 1 && !cambio {
            let delta = (u0.e - c.destino.e) / (u0.magnitud == "S" ? 2 : (u0.magnitud == "V" ? 3 : 1))
            reglas.append((v0 * A.potencia(10, c.destino.e - u0.e), "Al pasar a una unidad menor se multiplica; a una mayor, se divide."))
            if u0.magnitud == "S" { reglas.append((v0 * A.potencia(10, delta), "En superficie, cada salto es ×100.")) }
            if u0.magnitud == "V" { reglas.append((v0 * A.potencia(100, delta), "En volumen, cada salto es ×1.000.")) }
            reglas.append((sol * rac(saltoBase), "Has dado un salto de más: cuenta las unidades que hay entre \(u0.simbolo) y \(hasta)."))
            reglas.append((sol / rac(saltoBase), "Has dado un salto de menos: cuenta las unidades que hay entre \(u0.simbolo) y \(hasta)."))
        } else if c.terminos.count > 1 {
            reglas.append((c.terminos.reduce(rac(0)) { $0 + $1.0 }, "Has sumado los números sin pasarlos antes a la misma unidad."))
            reglas.append((sol * rac(10), "Revisa la conversión de cada término: hay un salto de más."))
            reglas.append((sol / rac(10), "Revisa la conversión de cada término: hay un salto de menos."))
        }
        if cambio && !c.agua { reglas.insert((v0, "Volumen y capacidad tienen unidades distintas: 1 dm³ = 1 l y 1 cm³ = 1 ml."), at: 0); reglas.append((sol * rac(1000), "Revisa la equivalencia: 1 m³ = 1.000 l y 1 dm³ = 1 l.")) }
        if c.agua { reglas.append((sol * rac(1000), "1 l de agua pesa 1 kg, no 1 g.")); reglas.append((sol / rac(1000), "1 l de agua pesa 1 kg = 1.000 g.")) }
        let explicacion: String
        if c.terminos.count == 1 && !cambio {
            explicacion = "\(cantidad) = \(A.texto(sol)) \(hasta): de \(u0.simbolo) a \(hasta) \(u0.e > c.destino.e ? "se multiplica" : "se divide") por \(A.texto(A.potencia(10, abs(u0.e - c.destino.e))))."
        } else {
            let partes = c.terminos.map { "\(A.texto($0.0)) \($0.1.simbolo) = \(A.texto($0.0 * A.potencia(10, $0.1.e + (c.agua ? 3 : 0) - c.destino.e))) \(hasta)" }
            explicacion = (c.agua ? "1 l de agua = 1 kg. " : (cambio ? "1 dm³ = 1 l. " : "")) + partes.joined(separator: "; ") + ". Total: \(A.texto(sol)) \(hasta)."
        }
        // Complejidad: saltos de cada término, decimales, cambio de sistema y, desde el lote 02, el
        // trabajo de combinar varios términos (+1 por cada término adicional que se convierte y se
        // suma). El tamaño del número cuenta por sus cifras significativas: 5.000.000 cm³ no es
        // más difícil de convertir que 5 m³ (los saltos ya están en el primer término).
        var complejidad = Double(c.terminos.count - 1)
        for (v, u) in c.terminos { complejidad += 0.5 * Double(abs(u.e + (c.agua ? 3 : 0) - c.destino.e)) + 1 + (v.esEntero ? 0 : 1) }
        complejidad += 0.5 * Double(A.decimales(sol) ?? 0) + (u0.e < c.destino.e ? 0.5 : 0) + 0.3 * Self.cifrasSignificativas(v0.numerador / v0.denominador)
        complejidad += (cambio ? 3 : 0) + (familia == "vol" && c.agua ? 3 : 0) + (c.modo == "finca" ? 1 : 0)
        let terminos = c.terminos.map { "\(A.texto($0.0)):\($0.1.simbolo)" }.joined(separator: ";")
        return Muestra(clave: [terminos, hasta, c.agua ? "agua" : "-", c.modo].joined(separator: "|"),
                       valores: ["pregunta": pregunta], payload: A.numerico(sol, unidad: hasta), explicacion: explicacion,
                       erroresHabituales: A.errores(sol, reglas), pistas: ["Cada salto entre unidades vale \(A.texto(rac(saltoBase)))."],
                       complejidad: complejidad, datos: ["terminos": terminos, "hasta": hasta, "agua": c.agua ? "1" : "0", "respuesta": A.texto(sol)])
    }

    /// Espacio grande: se enumera por muestreo determinista.
    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let familia = p.textos("familia", porDefecto: ["lmc"]).first ?? "lmc"
        var rng = GeneradorConSemilla(semilla: 11)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 20_000) {
            guard let c = caso(familia, p.dificultad, rng: &rng) else { continue }
            let sol = Self.resolver(c)
            guard Self.aceptable(c, sol, dificultad: p.dificultad) else { continue }
            vistos.insert([c.terminos.map { "\(A.texto($0.0)):\($0.1.simbolo)" }.joined(separator: ";"), c.destino.simbolo, c.agua ? "agua" : "-", c.modo].joined(separator: "|"))
        }
        return Array(vistos)
    }
}

// MARK: - C4. sexagesimal

/// Tiempo en el sistema sexagesimal (MAT.UNI.TIEM). Con `numerico`, el resultado se pide en una
/// sola unidad; con `ruedas`, en horas, minutos y segundos.
///
/// | Dif. | Caso |
/// |---|---|
/// | 1 | h → min o min → s (ruedas: min → h y min) |
/// | 2 | h y min → s (ruedas: s → h, min y s) |
/// | 3 | sumar dos tiempos (h, min) con llevada, o duración en el mismo día |
/// | 4 (examen) | sumar tres tiempos escritos sin normalizar («165 min 900 s») y expresarlo en una unidad (2019 A M12, 2026 A M12) |
/// | 5 | sumar cuatro tiempos sin normalizar |
/// | 6 | multiplicar un tiempo (h, min, s) por un número, o duración que cruza la medianoche |
struct GeneradorSexagesimal: GeneradorItems {
    let tipo = "sexagesimal"
    let mecanicas: Set<Mecanica> = [.numerico, .ruedas]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    static func tiempo(_ s: Int) -> String {
        let h = s / 3600, m = s % 3600 / 60, ss = s % 60
        var partes: [String] = []
        if h > 0 { partes.append("\(h) h") }
        if m > 0 { partes.append("\(m) min") }
        if ss > 0 { partes.append("\(ss) s") }
        return partes.isEmpty ? "0 s" : partes.joined(separator: " ")
    }
    static func reloj(_ s: Int) -> String { String(format: "%d:%02d", s / 3600 % 24, s % 3600 / 60) }

    /// Caso: operación, tiempos en segundos, factor y unidad de la respuesta numérica (s o min).
    /// En `sumaN`, `partes` son los tiempos escritos sin normalizar: (h, min, s) de cada uno.
    struct Caso {
        let op: String; let t1: Int; let t2: Int; let k: Int; let unidad: String
        var partes: [(Int, Int, Int)] = []
    }

    static func escrito(_ p: (Int, Int, Int)) -> String {
        var t: [String] = []
        if p.0 > 0 { t.append("\(p.0) h") }
        if p.1 > 0 { t.append("\(p.1) min") }
        if p.2 > 0 { t.append("\(p.2) s") }
        return t.joined(separator: " ")
    }

    /// Tiempo escrito sin normalizar, como en el examen: minutos o segundos que pasan de 59.
    static func desordenado(_ rng: inout GeneradorConSemilla, enMinutos: Bool) -> (Int, Int, Int) {
        switch rng.entero(0...2) {
        case 0: return (rng.entero(1...3), rng.entero(1...59), enMinutos ? 0 : rng.entero(1...59))
        case 1: return (0, rng.entero(60...210), 60 * rng.entero(2...40))
        default: return (rng.entero(1...2), rng.entero(60...99), enMinutos ? 60 * rng.entero(1...10) : rng.entero(60...150))
        }
    }

    static func resultado(_ c: Caso) -> Int {
        switch c.op {
        case "suma": return c.t1 + c.t2
        case "resta": return c.t1 - c.t2
        case "dur": return c.t2 - c.t1
        case "medianoche": return 86_400 - c.t1 + c.t2
        case "mul": return c.t1 * c.k
        case "sumaN": return c.partes.map { $0.0 * 3600 + $0.1 * 60 + $0.2 }.reduce(0, +)
        default: return c.t1
        }
    }

    func caso(_ d: Int, ruedas: Bool, rng: inout GeneradorConSemilla) -> Caso {
        switch d {
        case 1:
            if ruedas { return Caso(op: "conv", t1: 60 * rng.entero(61...300), t2: 0, k: 1, unidad: "min") }
            return rng.probabilidad(0.5) ? Caso(op: "conv", t1: 3600 * rng.entero(1...10), t2: 0, k: 1, unidad: "min")
                : Caso(op: "conv", t1: 60 * rng.entero(1...10), t2: 0, k: 1, unidad: "s")
        case 2:
            if ruedas { return Caso(op: "conv", t1: rng.entero(3601...15_000), t2: 0, k: 1, unidad: "s") }
            return Caso(op: "conv", t1: 3600 * rng.entero(1...3) + 60 * rng.entero(1...59), t2: 0, k: 1, unidad: "s")
        case 3:
            if rng.probabilidad(0.5) {
                let m1 = rng.entero(20...59), m2 = rng.entero(max(1, 61 - m1)...59)
                return Caso(op: "suma", t1: 3600 * rng.entero(0...5) + 60 * m1, t2: 3600 * rng.entero(1...5) + 60 * m2, k: 1, unidad: "min")
            }
            let a = 60 * (60 * rng.entero(7...14) + 5 * rng.entero(0...11))
            return Caso(op: "dur", t1: a, t2: a + 60 * (5 * rng.entero(13...100)), k: 1, unidad: "min")
        case 4, 5:
            // Perfil del examen: tres tiempos (cuatro en el nivel 5), alguno sin normalizar.
            let unidad = ruedas ? "s" : (rng.probabilidad(0.5) ? "min" : "s")
            var partes = (0..<(d == 4 ? 3 : 4)).map { _ in Self.desordenado(&rng, enMinutos: unidad == "min") }
            // Al menos uno sin normalizar (minutos o segundos que pasan de 59), como en el examen.
            if !partes.contains(where: { $0.1 >= 60 || $0.2 >= 60 }) {
                partes[rng.entero(0...(partes.count - 1))] = (0, rng.entero(60...210), 60 * rng.entero(2...40))
            }
            return Caso(op: "sumaN", t1: 0, t2: 0, k: 1, unidad: unidad, partes: partes)
        default:
            if rng.probabilidad(0.5) {
                let a = 60 * (60 * rng.entero(19...23) + 5 * rng.entero(0...11))
                return Caso(op: "medianoche", t1: a, t2: 60 * (60 * rng.entero(0...9) + 5 * rng.entero(0...11)), k: 1, unidad: "min")
            }
            return Caso(op: "mul", t1: 3600 * rng.entero(0...2) + 60 * rng.entero(1...59) + rng.entero(1...59), t2: 0, k: rng.entero(2...9), unidad: "s")
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let ruedas = p.mecanica == .ruedas
        for _ in 0..<200 {
            let c = caso(p.dificultad, ruedas: ruedas, rng: &rng)
            let r = Self.resultado(c)
            guard r > 0, c.op != "resta" || c.t1 != c.t2 else { continue }
            let m = construir(p, c, r: r, ruedas: ruedas, rng: &rng)
            return m.conPasos(Self.pasos(c, r: r, payload: ruedas ? m.payload : nil))
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// La operación del caso con los tiempos en segundos (o en minutos con `divisor` 60).
    static func operacionEnSegundos(_ c: Caso, divisor: Int = 1) -> String {
        let a = A.texto(rac(c.t1 / divisor)), b = A.texto(rac(c.t2 / divisor))
        switch c.op {
        case "suma": return "\(a) + \(b)"
        case "resta": return "\(a) − \(b)"
        case "dur": return "\(b) − \(a)"
        case "medianoche": return "\(A.texto(rac(86_400 / divisor))) − \(a) + \(b)"
        case "mul": return "\(a) × \(c.k)"
        default: return a
        }
    }

    /// Pasos del ejemplo resuelto (§5). En una unidad (numérico): cada tiempo pasado a esa unidad y la
    /// operación. Con ruedas: las llevadas de 60 en 60 y, al final, las ruedas.
    static func pasos(_ c: Caso, r: Int, payload: Payload?) -> [PasoResuelto] {
        let porque60 = "porque el tiempo va de 60 en 60, no de 100 en 100"
        if let payload {
            var pasos: [PasoResuelto] = []
            if c.op == "sumaN" {
                let h = c.partes.map(\.0).reduce(0, +), m = c.partes.map(\.1).reduce(0, +), s = c.partes.map(\.2).reduce(0, +)
                pasos.append(Pasos.dato("Suma horas con horas, minutos con minutos…", "\(h) h \(m) min \(s) s",
                                        porque: "porque solo se suman cantidades de la misma unidad"))
                let mins = m + s / 60
                pasos.append(Pasos.dato("Cada 60 s forman 1 min", "\(s) s = \(s / 60) min \(s % 60) s → \(mins) min \(s % 60) s", porque: porque60))
                pasos.append(Pasos.dato("Cada 60 min forman 1 h", "\(mins) min = \(mins / 60) h \(mins % 60) min → \(tiempo(r))"))
            } else if c.unidad == "s" {
                let mins = r / 60
                if c.op != "conv" { pasos.append(Pasos.op("Pasa los tiempos a segundos y opera", operacionEnSegundos(c), rac(r))) }
                pasos.append(Pasos.dato("Divide los segundos entre 60", "\(A.texto(rac(r))) s : 60 = \(mins) min y \(r % 60) s", porque: porque60))
                pasos.append(Pasos.dato("Divide los minutos entre 60", "\(mins) min : 60 = \(mins / 60) h y \(mins % 60) min"))
            } else {
                let mins = r / 60
                if c.op != "conv" { pasos.append(Pasos.op("Pasa los tiempos a minutos y opera", operacionEnSegundos(c, divisor: 60), rac(mins))) }
                pasos.append(Pasos.dato("Divide los minutos entre 60", "\(mins) min : 60 = \(mins / 60) h y \(mins % 60) min", porque: "porque cada 60 minutos forman una hora"))
            }
            pasos.append(Pasos.solucion("Coloca las ruedas", payload: payload))
            return pasos
        }
        let div = c.unidad == "min" ? 60 : 1, u = c.unidad
        func en(_ s: Int) -> Racional { rac(s / div) }
        /// Expresión que pasa (h, min, s) a la unidad de la respuesta.
        func expresion(_ h: Int, _ m: Int, _ s: Int) -> String {
            var t: [String] = []
            if u == "min" {
                if h > 0 { t.append("\(h) × 60") }
                if m > 0 { t.append("\(m)") }
                if s > 0 { t.append("\(s) : 60") }
            } else {
                if h > 0 { t.append("\(h) × 3.600") }
                if m > 0 { t.append("\(m) × 60") }
                if s > 0 { t.append("\(s)") }
            }
            return t.isEmpty ? "0" : t.joined(separator: " + ")
        }
        func partes(_ s: Int) -> (Int, Int, Int) { (s / 3600, s % 3600 / 60, s % 60) }
        let porqueMisma = "porque solo se suman cantidades de la misma unidad"
        switch c.op {
        case "conv":
            let (h, m, s) = partes(c.t1)
            if h > 0 && m > 0 {
                return [Pasos.op("Pasa las horas a \(u == "s" ? "segundos" : "minutos")", expresion(h, 0, 0), en(h * 3600), porque: porque60),
                        Pasos.op("Suma los minutos ya convertidos", "\(A.texto(en(h * 3600))) + \(expresion(0, m, s))", rac(r / div))]
            }
            let unidad = h > 0 ? "h" : (m > 0 ? "min" : "s"), cantidad = h > 0 ? h : (m > 0 ? m : s)
            let factor = rac((unidad == "h" ? 3600 : 60) / div)
            return [Pasos.op("Busca cuántos \(u) tiene 1 \(unidad)", "1 \(unidad) en \(u)", factor, porque: porque60),
                    Pasos.op("Multiplica por \(cantidad)", "\(cantidad) × \(A.texto(factor))", rac(r / div))]
        case "suma":
            let a = partes(c.t1), b = partes(c.t2)
            return [Pasos.op("Pasa el primer tiempo a \(u)", expresion(a.0, a.1, a.2), en(c.t1), porque: porqueMisma),
                    Pasos.op("Pasa el segundo tiempo a \(u)", expresion(b.0, b.1, b.2), en(c.t2)),
                    Pasos.op("Suma", "\(A.texto(en(c.t1))) + \(A.texto(en(c.t2)))", rac(r / div))]
        case "resta":
            return [Pasos.op("Pasa el primer tiempo a \(u)", expresion(partes(c.t1).0, partes(c.t1).1, partes(c.t1).2), en(c.t1), porque: porqueMisma),
                    Pasos.op("Pasa el segundo tiempo a \(u)", expresion(partes(c.t2).0, partes(c.t2).1, partes(c.t2).2), en(c.t2)),
                    Pasos.op("Resta", "\(A.texto(en(c.t1))) − \(A.texto(en(c.t2)))", rac(r / div))]
        case "dur":
            return [Pasos.op("Pasa la salida a \(u) desde las 0:00", expresion(partes(c.t1).0, partes(c.t1).1, 0), en(c.t1),
                             porque: "porque la duración es lo que va de una hora a otra"),
                    Pasos.op("Pasa la llegada a \(u) desde las 0:00", expresion(partes(c.t2).0, partes(c.t2).1, 0), en(c.t2)),
                    Pasos.op("Resta llegada menos salida", "\(A.texto(en(c.t2))) − \(A.texto(en(c.t1)))", rac(r / div))]
        case "medianoche":
            let hasta24 = 86_400 - c.t1
            return [Pasos.op("Cuenta desde la salida hasta las 24:00", "\(A.texto(en(86_400))) − \(A.texto(en(c.t1)))", en(hasta24),
                             porque: "porque a medianoche el reloj vuelve a las 0:00"),
                    Pasos.op("Cuenta desde las 0:00 hasta la llegada", expresion(partes(c.t2).0, partes(c.t2).1, 0), en(c.t2)),
                    Pasos.op("Suma los dos tramos", "\(A.texto(en(hasta24))) + \(A.texto(en(c.t2)))", rac(r / div))]
        case "mul":
            let (h, m, s) = partes(c.t1)
            return [Pasos.op("Pasa el tiempo a \(u)", expresion(h, m, s), en(c.t1), porque: "porque así multiplicas una sola cantidad"),
                    Pasos.op("Multiplica por \(c.k)", "\(A.texto(en(c.t1))) × \(c.k)", rac(r / div))]
        default:
            let valores = c.partes.map { $0.0 * 3600 + $0.1 * 60 + $0.2 }
            var pasos = c.partes.enumerated().map { k, t in
                Pasos.op("Pasa \(escrito(t)) a \(u)", expresion(t.0, t.1, t.2), en(valores[k]), porque: k == 0 ? porqueMisma : nil)
            }
            pasos.append(Pasos.op("Suma", valores.map { A.texto(en($0)) }.joined(separator: " + "), rac(r / div)))
            return pasos
        }
    }

    private func construir(_ p: Plantilla, _ c: Caso, r: Int, ruedas: Bool, rng: inout GeneradorConSemilla) -> Muestra {
        let nombre = rng.elemento(A.nombres)
        let unidadTexto = c.unidad == "s" ? "segundos" : "minutos"
        let enUnidad = ruedas ? "" : " Expresa el resultado en \(unidadTexto)."
        var pregunta: String
        switch c.op {
        case "conv":
            if ruedas { pregunta = "Expresa \(A.texto(rac(c.t1 / (c.unidad == "min" ? 60 : 1)))) \(c.unidad) en horas\(c.unidad == "s" ? ", minutos y segundos" : " y minutos")." }   // A.2
            else if c.t1 % 3600 == 0 && c.unidad == "min" { pregunta = "¿Cuántos minutos son \(c.t1 / 3600) h?" }   // A.2
            else if c.t1 < 3600 { pregunta = "¿Cuántos segundos son \(c.t1 / 60) min?" }   // A.2
            else { pregunta = "¿Cuántos segundos son \(c.t1 / 3600) h \(c.t1 % 3600 / 60) min?" }
        case "suma": pregunta = "Suma \(Self.tiempo(c.t1)) y \(Self.tiempo(c.t2))." + enUnidad
        case "sumaN":
            let lista = c.partes.map(Self.escrito)
            pregunta = "Tres aparatos funcionan uno detrás de otro durante \(lista.dropLast().joined(separator: "; ")) y \(lista.last!). ¿Cuánto tiempo funcionan en total?" + enUnidad   // 05E
            if c.partes.count == 4 { pregunta = pregunta.replacingOccurrences(of: "Tres aparatos", with: "Cuatro aparatos") }
        case "resta": pregunta = "Resta \(Self.tiempo(c.t2)) a \(Self.tiempo(c.t1))." + enUnidad   // A.2
        case "dur", "medianoche":
            pregunta = "\(nombre) sale a las \(Self.reloj(c.t1)) y llega a las \(Self.reloj(c.t2)). ¿Cuánto dura el viaje?" + enUnidad
        default: pregunta = "Cada vuelta a la pista dura \(Self.tiempo(c.t1)). ¿Cuánto duran \(c.k) vueltas?" + enUnidad   // A.2
        }
        let explicacion: String
        switch c.op {
        case "conv": explicacion = "1 h = 60 min y 1 min = 60 s. \(Self.tiempo(c.t1)) = \(ruedas ? Self.tiempo(r) : "\(r / (c.unidad == "min" ? 60 : 1)) \(c.unidad)")."
        case "medianoche": explicacion = "Hasta las 24:00: \(Self.tiempo(86_400 - c.t1)); después, hasta las \(Self.reloj(c.t2)): \(Self.tiempo(c.t2)). Total: \(Self.tiempo(r))."
        case "mul": explicacion = "\(Self.tiempo(c.t1)) × \(c.k) = \(Self.tiempo(r)) (cada 60 s son 1 min y cada 60 min, 1 h)."
        case "sumaN":
            let segundos = c.partes.map { "\(Self.escrito($0)) = \($0.0 * 3600 + $0.1 * 60 + $0.2) s" }
            explicacion = "Se pasa cada tiempo a segundos y se suma: " + segundos.joined(separator: "; ") + ". Total: \(r) s = \(Self.tiempo(r))."
        default: explicacion = "Se opera por separado con horas, minutos y segundos, y cada 60 se lleva 1 a la unidad mayor: \(Self.tiempo(r))."
        }
        let llevadas: Double
        if c.op == "sumaN" {
            let s = c.partes.map(\.2).reduce(0, +), m = c.partes.map(\.1).reduce(0, +) + s / 60
            llevadas = Double((s >= 60 ? 1 : 0) + (m >= 60 ? 1 : 0)) + 0.5 * Double(c.partes.filter { $0.1 >= 60 || $0.2 >= 60 }.count)
        } else if c.op == "mul" {
            let s = c.t1 % 60 * c.k, m = c.t1 % 3600 / 60 * c.k + s / 60
            llevadas = Double((s >= 60 ? 1 : 0) + (m >= 60 ? 1 : 0))
        } else {
            llevadas = Double((c.t1 % 60 + c.t2 % 60 >= 60 ? 1 : 0) + (c.t1 % 3600 / 60 + c.t2 % 3600 / 60 >= 60 ? 1 : 0))
        }
        let operacion: Double = ["conv": c.t1 % 3600 == 0 || c.t1 < 3600 ? 1 : 2, "suma": 3, "resta": 3, "dur": 3, "medianoche": 8, "mul": 8,
                                 "sumaN": 2 + Double(c.partes.count) * 0.5][c.op] ?? 1
        let unidades = Double([r / 3600 > 0, r % 3600 / 60 > 0, r % 60 > 0].filter { $0 }.count)
        let complejidad = operacion + llevadas + unidades * 0.5 + 0.3 * log10(Double(max(r, 1)))
        let partes = c.partes.map { "\($0.0):\($0.1):\($0.2)" }.joined(separator: ";")
        let clave = [p.mecanica.rawValue, c.op, "\(c.t1)", "\(c.t2)", "\(c.k)", c.unidad, partes].joined(separator: "|")
        let datos = ["op": c.op, "t1": "\(c.t1)", "t2": "\(c.t2)", "k": "\(c.k)", "unidad": c.unidad, "segundos": "\(r)", "partes": partes]
        if ruedas {
            let h = r / 3600, m = r % 3600 / 60, s = r % 60
            var lista = [Payload.Ruedas.Rueda(id: "h", nombre: "Horas", opciones: (0...max(23, h + 3)).map(String.init), correcta: "\(h)"),
                         Payload.Ruedas.Rueda(id: "min", nombre: "Minutos", opciones: (0...59).map(String.init), correcta: "\(m)")]
            if c.unidad == "s" || s > 0 { lista.append(Payload.Ruedas.Rueda(id: "s", nombre: "Segundos", opciones: (0...59).map(String.init), correcta: "\(s)")) }
            return Muestra(clave: clave, valores: ["pregunta": pregunta], payload: .ruedas(Payload.Ruedas(ruedas: lista)),
                           explicacion: explicacion,
                           erroresHabituales: [ErrorHabitual(respuesta: "min", feedback: "El tiempo no es decimal: 1 h 30 min no son 1,30 h, son 1,5 h. Cada 60 minutos forman una hora."),
                                               ErrorHabitual(respuesta: "h", feedback: "Revisa las llevadas: cada 60 minutos son 1 hora.")],
                           pistas: ["Cada 60 segundos son 1 minuto y cada 60 minutos, 1 hora."], complejidad: complejidad, datos: datos)
        }
        let divisor = c.unidad == "min" ? 60 : 1
        let sol = rac(r / divisor)
        let h = r / 3600, m = r % 3600 / 60, s = r % 60
        let decimal = c.unidad == "min" ? rac(h * 100 + m) : rac(h * 10_000 + m * 100 + s)
        let reglas: [(Racional?, String)] = [
            (decimal, "El tiempo no es decimal: 1 h 30 min no son 1,30 h, son 1,5 h. Una hora tiene 60 minutos, no 100."),
            (c.unidad == "s" ? rac(h * 60 + m) : rac(h), "Te has quedado a medias: pasa todo a \(unidadTexto)."),
            (c.op == "medianoche" ? rac(abs(c.t1 - c.t2) / divisor) : nil, "Al pasar la medianoche, cuenta hasta las 24:00 y suma lo que falta."),
        ]
        return Muestra(clave: clave, valores: ["pregunta": pregunta], payload: A.numerico(sol, unidad: c.unidad),
                       explicacion: explicacion, erroresHabituales: A.errores(sol, reglas),
                       pistas: ["1 h = 60 min y 1 min = 60 s."], complejidad: complejidad, datos: datos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 13)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 20_000) {
            let c = caso(p.dificultad, ruedas: p.mecanica == .ruedas, rng: &rng)
            guard Self.resultado(c) > 0 else { continue }
            vistos.insert([p.mecanica.rawValue, c.op, "\(c.t1)", "\(c.t2)", "\(c.k)", c.unidad, c.partes.map { "\($0.0):\($0.1):\($0.2)" }.joined(separator: ";")].joined(separator: "|"))
        }
        return Array(vistos)
    }
}

// MARK: - C5. escala

/// Escalas de mapas y planos (MAT.UNI.ESC).
///
/// | Dif. | Caso |
/// |---|---|
/// | 1 | plano 1:100, de cm a m |
/// | 2 | plano 1:1000 o 1:10 000, de cm a m |
/// | 3 | mapa 1:10 000 a 1:100 000, de cm a km |
/// | 4 (examen) | plano 1:20 a 1:1000 con la medida decimal en cm o en mm, resultado en m (2026 O M20) |
/// | 5 | de la realidad (km) al mapa (cm) |
/// | 6 | averiguar la escala (distancias enteras o decimales) |
struct GeneradorEscala: GeneradorItems {
    let tipo = "escala"
    let mecanicas: Set<Mecanica> = [.numerico]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    /// Caso: modo (`mr` mapa → realidad, `rm` realidad → mapa, `esc` escala), escala, distancia en el
    /// mapa (cm) y unidad de la distancia real.
    struct Caso {
        let modo: String; let e: Int; let d: Racional; let unidad: String
        /// Unidad de la medida en el plano (cm o mm; en `mrPlano` puede ser mm).
        var unidadPlano = "cm"
    }

    static func real(_ c: Caso) -> Racional { c.d * rac(c.e) * A.potencia(10, (c.unidad == "km" ? -5 : -2) - (c.unidadPlano == "mm" ? 1 : 0)) }

    func caso(_ dif: Int, rng: inout GeneradorConSemilla) -> Caso {
        switch dif {
        case 1: return Caso(modo: "mr", e: 100, d: rac(rng.entero(1...40)), unidad: "m")
        case 2: return Caso(modo: "mr", e: rng.elemento([1000, 10_000]), d: rac(rng.entero(1...30)), unidad: "m")
        case 3: return Caso(modo: "mr", e: rng.elemento([10_000, 50_000, 100_000]), d: rac(rng.entero(2...40), 2), unidad: "km")
        case 4:
            // Perfil del examen: «2,5 cm | 1:200», «35 mm | 1:20», resultado en metros.
            let e = rng.elemento([20, 50, 200, 500, 1000])
            if rng.probabilidad(0.5) { return Caso(modo: "mrPlano", e: e, d: rac(rng.entero(11...99), 10), unidad: "m") }
            return Caso(modo: "mrPlano", e: e, d: rac(rng.entero(11...95)), unidad: "m", unidadPlano: "mm")
        case 5: return Caso(modo: "rm", e: rng.elemento([50_000, 100_000, 200_000]), d: rac(rng.entero(2...40), 2), unidad: "km")
        default:
            if rng.probabilidad(0.5) { return Caso(modo: "esc", e: rng.elemento([10_000, 20_000, 25_000, 50_000, 100_000, 200_000, 500_000]), d: rac(rng.entero(2...20)), unidad: "km") }
            return Caso(modo: "esc", e: rng.elemento([20_000, 25_000, 50_000, 200_000, 250_000, 500_000, 1_000_000]), d: rac(rng.entero(3...39), 2), unidad: "km")
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        for _ in 0..<300 {
            let c = caso(p.dificultad, rng: &rng)
            let r = Self.real(c)
            guard let dr = A.decimales(r), dr <= 3 else { continue }
            if p.dificultad == 4 && c.unidadPlano == "cm" && c.d.esEntero { continue }
            return construir(c, real: r).conPasos(Self.pasos(c, real: r))
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Pasos del ejemplo resuelto (§5).
    static func pasos(_ c: Caso, real r: Racional) -> [PasoResuelto] {
        let e = FormatoNumero.miles(c.e), ds = A.texto(c.d), enUd = c.d * rac(c.e)
        switch c.modo {
        case "mr", "mrPlano":
            let ud = c.modo == "mrPlano" ? c.unidadPlano : "cm"
            let divisor = c.unidad == "km" ? 100_000 : (ud == "mm" ? 1000 : 100)
            return [Pasos.op("Multiplica la medida por la escala", "\(ds) × \(e)", enUd, porque: "porque cada \(ud) del plano son \(e) \(ud) reales"),
                    Pasos.op("Pasa de \(ud) a \(c.unidad)", "\(A.texto(enUd)) : \(FormatoNumero.miles(divisor))", r)]
        case "rm":
            return [Pasos.op("Pasa los kilómetros a centímetros", "\(A.texto(r)) × 100.000", enUd, porque: "porque la escala compara centímetros con centímetros"),
                    Pasos.op("Divide entre la escala", "\(A.texto(enUd)) : \(e)", c.d)]
        default:
            return [Pasos.op("Pasa los kilómetros a centímetros", "\(A.texto(r)) × 100.000", enUd, porque: "porque las dos distancias tienen que ir en centímetros"),
                    Pasos.op("Divide la distancia real entre la del mapa", "\(A.texto(enUd)) : \(ds)", rac(c.e))]
        }
    }

    private func construir(_ c: Caso, real r: Racional) -> Muestra {
        let es = "1:\(FormatoNumero.miles(c.e))", ds = A.texto(c.d), rs = A.texto(r)
        let enCm = c.d * rac(c.e)
        var pregunta: String, sol: Racional, unidad: String?, explicacion: String
        var reglas: [(Racional?, String)] = []
        switch c.modo {
        case "mrPlano":
            sol = r; unidad = "m"
            let ud = c.unidadPlano
            pregunta = "En un plano a escala \(es), una pared mide \(ds) \(ud). ¿Cuántos metros mide en la realidad?"   // 05E
            let enUd = c.d * rac(c.e)
            reglas = [(enUd, "Has dejado el resultado en \(ud == "mm" ? "milímetros: 1 m = 1.000 mm" : "centímetros: 1 m = 100 cm")."),
                      (r * rac(10), "Revisa el paso a metros: \(ud == "mm" ? "1 m = 1.000 mm" : "1 m = 100 cm")."),
                      (r * rac(1, 10), "Revisa el paso a metros: \(ud == "mm" ? "1 m = 1.000 mm" : "1 m = 100 cm")."),
                      (c.d / rac(c.e), "En el plano las medidas son más pequeñas: para pasar a la realidad se multiplica por \(FormatoNumero.miles(c.e)).")]
            explicacion = "\(ds) \(ud) × \(FormatoNumero.miles(c.e)) = \(A.texto(enUd)) \(ud) = \(rs) m."
        case "mr":
            sol = r; unidad = c.unidad
            if c.unidad == "km" {
                pregunta = "En un mapa a escala \(es), dos pueblos están a \(ds) cm. ¿A cuántos kilómetros están en la realidad?"
                reglas = [(r * rac(1000), "Has dejado el resultado en metros: 1 km = 1.000 m."),
                          (enCm, "Has dejado el resultado en centímetros: 1 km = 100.000 cm.")]
            } else {
                let lugar = c.e == 100 ? "una habitación" : "un parque"
                pregunta = "En un plano a escala \(es), \(lugar) mide \(ds) cm de largo. ¿Cuántos metros mide en la realidad?"   // A.2
                reglas = [(enCm, "Has dejado el resultado en centímetros: 1 m = 100 cm."),
                          (r * rac(1, 10), "Revisa el paso de centímetros a metros: 1 m = 100 cm.")]
            }
            reglas.append((c.d / rac(c.e), "En el mapa las distancias son más pequeñas: para pasar a la realidad se multiplica por \(FormatoNumero.miles(c.e))."))
            explicacion = "\(ds) cm × \(FormatoNumero.miles(c.e)) = \(A.texto(enCm)) cm = \(rs) \(c.unidad)."
        case "rm":
            sol = c.d; unidad = "cm"
            pregunta = "Dos pueblos están a \(rs) km. ¿A cuántos centímetros están en un mapa a escala \(es)?"   // A.2
            reglas = [((r * rac(1000)) / rac(c.e), "Pasa primero los kilómetros a centímetros: 1 km = 100.000 cm, no 1.000."),
                      (r * rac(c.e), "Para pasar de la realidad al mapa se divide entre la escala, no se multiplica."),
                      (c.d * rac(10), "Revisa la coma: 1 km = 100.000 cm.")]
            explicacion = "\(rs) km = \(A.texto(enCm)) cm; \(A.texto(enCm)) : \(FormatoNumero.miles(c.e)) = \(ds) cm."
        default:
            sol = rac(c.e); unidad = nil
            pregunta = "En un mapa, dos pueblos que están a \(rs) km aparecen separados \(ds) cm. La escala es 1:n. ¿Cuánto vale n?"   // A.2
            reglas = [(rac(c.e) / rac(1000), "Pasa los kilómetros a centímetros (1 km = 100.000 cm) antes de dividir."),
                      (rac(c.e) / rac(100), "Las dos distancias deben estar en centímetros antes de dividir."),
                      (r / c.d, "Pasa los kilómetros a centímetros antes de dividir.")]
            explicacion = "\(rs) km = \(A.texto(enCm)) cm; \(A.texto(enCm)) : \(ds) = \(FormatoNumero.miles(c.e)). Escala \(es)."
        }
        // `mrPlano`: multiplicar un decimal (o mm) y pasar por dos unidades hasta el metro.
        let direccion: Double = ["mr": 1, "mrPlano": 3.5, "rm": 4, "esc": 5][c.modo] ?? 1
        let complejidad = 0.5 * (c.unidad == "km" ? 5 : 2) + direccion + 0.2 * log10(Double(c.e)) + (c.d.esEntero ? 0 : 1)
        return Muestra(clave: [c.modo, "\(c.e)", ds, c.unidad, c.unidadPlano].joined(separator: "|"), valores: ["pregunta": pregunta],
                       payload: A.numerico(sol, unidad: unidad), explicacion: explicacion, erroresHabituales: A.errores(sol, reglas),
                       pistas: ["1:\(FormatoNumero.miles(c.e)) significa que 1 cm del mapa son \(FormatoNumero.miles(c.e)) cm reales."],
                       complejidad: complejidad,
                       datos: ["modo": c.modo, "e": "\(c.e)", "d": ds, "unidad": c.unidad, "unidadPlano": c.unidadPlano, "respuesta": A.texto(sol)])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        var rng = GeneradorConSemilla(semilla: 17)
        var vistos = Set<String>()
        for _ in 0..<min(limite, 20_000) {
            let c = caso(p.dificultad, rng: &rng)
            guard let dr = A.decimales(Self.real(c)), dr <= 3, p.dificultad != 4 || c.unidadPlano == "mm" || !c.d.esEntero else { continue }
            vistos.insert([c.modo, "\(c.e)", A.texto(c.d), c.unidad, c.unidadPlano].joined(separator: "|"))
        }
        return Array(vistos)
    }
}
