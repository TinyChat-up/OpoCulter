import Foundation

/// Tarjeta de teoría breve de una competencia (`Content/teoria/<bloque>.json`).
struct TarjetaTeoria: Codable, Sendable, Equatable, Identifiable {
    struct BloqueTeoria: Codable, Sendable, Equatable {
        enum Tipo: String, Codable, Sendable {
            case texto, regla, ejemplo, esquema
        }
        var tipo: Tipo
        var contenido: String
    }

    var id: String
    var competencia: String
    var titulo: String
    var bloques: [BloqueTeoria]
    var procedencia: Procedencia
    var validacion: Validacion
}

/// Simulacro de examen completo (`Content/simulacros/<id>.json`).
struct Simulacro: Codable, Sendable, Equatable, Identifiable {
    struct TextoBase: Codable, Sendable, Equatable {
        var texto: String
        var autor: String?
        var obra: String?
        var procedencia: Procedencia
    }

    struct Rubrica: Codable, Sendable, Equatable {
        /// Criterio para 1 punto.
        var bien: String
        /// Criterio para 0,5 puntos.
        var regular: String
        /// Criterio para 0 puntos.
        var mal: String
    }

    struct Pregunta: Codable, Sendable, Equatable {
        var numero: Int
        /// `LEN` o `MAT`.
        var area: String
        var enunciado: String
        var solucionModelo: String
        var puntos: Double
        var rubrica: Rubrica
        var competencias: [String]
    }

    var id: String
    var titulo: String
    var duracionMin: Int
    var textoBase: TextoBase?
    var preguntas: [Pregunta]
    var validacion: Validacion
}
