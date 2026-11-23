import Foundation

/// Número racional exacto, usado para interpretar y comparar respuestas numéricas
/// sin errores de coma flotante ("0,1 + 0,2" o "2/6 = 1/3").
///
/// Formatos admitidos (separador decimal: coma, como en España):
/// - entero: `-12`, `573`
/// - decimal: `573,75`, `-0,5`
/// - fracción: `3/4`, `-7/2`
struct Racional: Hashable, Sendable, CustomStringConvertible {
    /// Formato textual reconocido al interpretar una cadena.
    enum Formato: String, Sendable {
        case entero, decimal, fraccion
    }

    /// Numerador y denominador normalizados (fracción reducida, denominador positivo).
    let numerador: Int
    let denominador: Int

    init?(numerador: Int, denominador: Int) {
        guard denominador != 0 else { return nil }
        let signo = denominador < 0 ? -1 : 1
        let (n, o1) = numerador.multipliedReportingOverflow(by: signo)
        let (d, o2) = denominador.multipliedReportingOverflow(by: signo)
        guard !o1, !o2 else { return nil }
        let g = Self.mcd(abs(n), d)
        self.numerador = n / g
        self.denominador = d / g
    }

    var description: String {
        denominador == 1 ? "\(numerador)" : "\(numerador)/\(denominador)"
    }

    var valorDouble: Double { Double(numerador) / Double(denominador) }

    /// Interpreta un texto y devuelve su valor y el formato en que estaba escrito.
    /// Devuelve `nil` si el texto no es un número válido.
    static func interpretar(_ texto: String) -> (valor: Racional, formato: Formato, irreducible: Bool)? {
        let limpio = texto.trimmingCharacters(in: .whitespaces)
        guard !limpio.isEmpty else { return nil }

        if limpio.contains("/") {
            let partes = limpio.split(separator: "/", omittingEmptySubsequences: false)
            guard partes.count == 2,
                  let n = enteroEstricto(String(partes[0])),
                  let d = enteroSinSigno(String(partes[1])), d != 0,
                  let r = Racional(numerador: n, denominador: d) else { return nil }
            return (r, .fraccion, mcd(abs(n), d) == 1)
        }

        if limpio.contains(",") {
            let partes = limpio.split(separator: ",", omittingEmptySubsequences: false)
            guard partes.count == 2,
                  let parteEntera = enteroEstricto(String(partes[0])),
                  !partes[1].isEmpty, partes[1].allSatisfy(\.isASCIIDigitoDecimal),
                  partes[1].count <= 9 else { return nil }
            let negativo = partes[0].hasPrefix("-")
            let escala = Int(pow(10.0, Double(partes[1].count)))
            guard let fraccion = Int(partes[1]) else { return nil }
            let (base, o1) = abs(parteEntera).multipliedReportingOverflow(by: escala)
            let (total, o2) = base.addingReportingOverflow(fraccion)
            guard !o1, !o2, let r = Racional(numerador: negativo ? -total : total, denominador: escala)
            else { return nil }
            return (r, .decimal, true)
        }

        guard let n = enteroEstricto(limpio), let r = Racional(numerador: n, denominador: 1) else { return nil }
        return (r, .entero, true)
    }

    // MARK: - Auxiliares

    static func mcd(_ a: Int, _ b: Int) -> Int {
        var x = a, y = b
        while y != 0 { (x, y) = (y, x % y) }
        return max(x, 1)
    }

    private static func enteroEstricto(_ s: String) -> Int? {
        var cuerpo = Substring(s)
        if cuerpo.hasPrefix("-") { cuerpo = cuerpo.dropFirst() }
        guard !cuerpo.isEmpty, cuerpo.count <= 15, cuerpo.allSatisfy(\.isASCIIDigitoDecimal) else { return nil }
        return Int(s)
    }

    private static func enteroSinSigno(_ s: String) -> Int? {
        guard !s.isEmpty, s.count <= 15, s.allSatisfy(\.isASCIIDigitoDecimal) else { return nil }
        return Int(s)
    }
}

private extension Character {
    var isASCIIDigitoDecimal: Bool { ("0"..."9").contains(self) }
}
