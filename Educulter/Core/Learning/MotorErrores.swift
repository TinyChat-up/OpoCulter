import Foundation

/// Error típico (05E parte 2, §4, D-107): un fallo concreto que el usuario puede repetir, con su
/// descripción en segunda persona (≤ 12 palabras) y el remedio que lo trabaja.
struct ErrorTipico: Codable, Sendable, Equatable, Identifiable {
    struct Remedio: Codable, Sendable, Equatable {
        /// Plantilla que trabaja el error.
        var plantilla: String
        var dificultad: Int
        /// Tarjeta de teoría opcional.
        var tarjeta: String?
    }

    /// `ERR.<competencia>.<n>`.
    var id: String
    var competencia: String
    var descripcion: String
    var remedio: Remedio
}
