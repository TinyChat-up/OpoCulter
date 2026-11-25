import Foundation

// Utilidades comunes de los generadores del lote 02 (D-077).

/// Racional a partir de numerador y denominador (no nulo).
func rac(_ n: Int, _ d: Int = 1) -> Racional { Racional(numerador: n, denominador: d)! }

enum AyudaMat {
    /// Nombres propios permitidos en los enunciados (lote 02, A.6).
    static let nombres = ["Ana", "Luis", "Marta", "Diego", "Lucía", "Hugo", "Sara", "Pablo", "Irene", "Mario", "Nora", "Álex"]

    /// Número de decimales de un racional con expresión decimal exacta (`nil` si no la tiene).
    static func decimales(_ v: Racional) -> Int? {
        guard let t = FormatoNumero.decimal(v) else { return nil }
        return t.split(separator: ",").dropFirst().first?.count ?? 0
    }

    /// Texto de un número: entero con separador de miles (RAE), decimal con coma o fracción.
    static func texto(_ v: Racional) -> String {
        if v.esEntero { return FormatoNumero.miles(v.numerador) }
        if let d = FormatoNumero.decimal(v) {
            let partes = d.split(separator: ",")
            guard let e = Int(partes[0]), abs(e) >= 10_000 else { return d }
            return FormatoNumero.miles(e) + "," + partes[1]
        }
        return "\(v.numerador)/\(v.denominador)"
    }

    /// Fracción como texto (`3/4`, o el entero si lo es).
    static func fraccion(_ v: Racional) -> String { v.esEntero ? "\(v.numerador)" : "\(v.numerador)/\(v.denominador)" }

    /// Importe en euros sin el símbolo: entero o con dos decimales («12,50»).
    static func euros(_ v: Racional) -> String {
        guard !v.esEntero, let d = FormatoNumero.decimal(v) else { return texto(v) }
        let partes = d.split(separator: ",")
        let dec = partes.count > 1 ? String(partes[1]) : ""
        let entero = Int(partes[0]).map { abs($0) >= 10_000 ? FormatoNumero.miles($0) : String(partes[0]) } ?? String(partes[0])
        return entero + "," + (dec.count == 1 ? dec + "0" : dec)
    }

    static func cifras(_ n: Int) -> Double { n == 0 ? 1 : floor(log10(Double(abs(n)))) + 1 }
    static func log(_ v: Racional) -> Double { max(0, log10(max(1, abs(v.valorDouble)))) }

    static func menor(_ a: Racional, _ b: Racional) -> Bool { a.numerador * b.denominador < b.numerador * a.denominador }

    static func potencia(_ b: Int, _ e: Int) -> Racional {
        var v = rac(1)
        for _ in 0..<abs(e) { v = v * rac(b) }
        return e >= 0 ? v : (rac(1) / v)!
    }

    /// Payload numérico (entero, decimal exacto o fracción; las fracciones se exigen irreducibles).
    static func numerico(_ v: Racional, unidad: String?, comoFraccion: Bool = false) -> Payload {
        let decimal = comoFraccion ? nil : FormatoNumero.decimal(v)
        let texto = v.esEntero ? "\(v.numerador)" : (decimal ?? "\(v.numerador)/\(v.denominador)")
        let formato: Payload.Numerico.Formato = v.esEntero ? .entero : (decimal != nil ? .decimal : .fraccion)
        return .numerico(Payload.Numerico(respuesta: texto, formato: formato, tolerancia: nil, unidad: unidad,
                                          exigeIrreducible: formato == .fraccion ? true : nil))
    }

    /// Errores habituales numéricos: sin duplicados, positivos, distintos de la solución.
    static func errores(_ correcta: Racional, _ reglas: [(Racional?, String)], comoFraccion: Bool = false) -> [ErrorHabitual] {
        func t(_ v: Racional) -> String {
            if v.esEntero { return "\(v.numerador)" }
            if !comoFraccion, let d = FormatoNumero.decimal(v) { return d }
            return "\(v.numerador)/\(v.denominador)"
        }
        var vistos: Set<Racional> = [correcta]
        return reglas.compactMap { v, f in
            guard let v, v.numerador > 0, v.denominador <= 10_000, abs(v.numerador) < 100_000_000,
                  vistos.insert(v).inserted else { return nil }
            return ErrorHabitual(respuesta: t(v), feedback: f)
        }
    }

    /// Opciones de elección con números (la correcta y los distractores con su feedback).
    static func eleccionNumerica(_ correcta: Racional, _ reglas: [(Racional?, String)], sufijo: String = "",
                                 rng: inout GeneradorConSemilla) -> (Payload, [ErrorHabitual]) {
        let errores = errores(correcta, reglas)
        let (e, err) = Opciones.eleccion(correcta: texto(correcta) + sufijo,
                                         distractores: errores.map { (texto(Racional.interpretar($0.respuesta)!.valor) + sufijo, $0.feedback) },
                                         rng: &rng)
        return (.eleccion(e), err)
    }
}
