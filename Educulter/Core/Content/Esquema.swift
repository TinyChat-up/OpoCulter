import Foundation

/// Fila de un bloque de teoría de tipo `esquema` (D-034).
///
/// Convención: cada línea (separada por `\n`) es una fila.
/// - `Etiqueta: valor` → fila de dos columnas.
/// - `A → B → C` → secuencia con flechas.
/// - Cualquier otra línea → texto.
/// Si una línea tiene dos puntos antes de la primera flecha, se interpreta como par
/// (el valor puede contener flechas).
enum FilaEsquema: Sendable, Equatable {
    case par(etiqueta: String, valor: String)
    case flecha([String])
    case texto(String)

    static func filas(de contenido: String) -> [FilaEsquema] {
        contenido.split(separator: "\n", omittingEmptySubsequences: true).compactMap { bruta in
            let linea = bruta.trimmingCharacters(in: .whitespaces)
            guard !linea.isEmpty else { return nil }
            let dosPuntos = linea.firstIndex(of: ":")
            let flecha = linea.range(of: "→")
            if let dosPuntos, flecha.map({ dosPuntos < $0.lowerBound }) ?? true {
                let etiqueta = linea[..<dosPuntos].trimmingCharacters(in: .whitespaces)
                let valor = linea[linea.index(after: dosPuntos)...].trimmingCharacters(in: .whitespaces)
                if !etiqueta.isEmpty, !valor.isEmpty { return .par(etiqueta: etiqueta, valor: valor) }
            }
            if flecha != nil {
                let partes = linea.components(separatedBy: "→").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if partes.count >= 2 { return .flecha(partes) }
            }
            return .texto(linea)
        }
    }
}
