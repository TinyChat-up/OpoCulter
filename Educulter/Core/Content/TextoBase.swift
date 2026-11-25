import Foundation

/// Texto base de los ítems de comprensión (`Content/textos/<archivo>.json`, lote 03a, D-085).
/// Un ítem lo cita con `textoRef`; la ronda lo muestra en un panel plegable sobre el enunciado.
struct TextoBase: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var titulo: String
    var autor: String?
    var obra: String?
    /// `poesia`, `narrativo`, `expositivo`, `argumentativo`… (texto libre, no vacío).
    var tipo: String
    /// Texto plano; `\n` separa versos y párrafos.
    var texto: String
    var procedencia: Procedencia
    var validacion: Validacion

    /// Un texto es literario si tiene autor (los originales de la dirección no lo tienen).
    var esLiterario: Bool { !(autor ?? "").isEmpty }
}

/// Base literaria del lote 05a (`Content/literatura/literatura.json`, D-078 y D-079). Son datos
/// para el motor literario de la Fase 05F; por ahora la app solo la carga, la valida y la usa
/// para fechar los textos base literarios.
struct BaseLiteraria: Codable, Sendable, Equatable {
    struct Movimiento: Codable, Sendable, Equatable, Identifiable {
        var id: String
        var nombre: String
        var periodo: String
        var inicio: Int
        var fin: Int?
        var rasgos: [String]
    }

    struct Obra: Codable, Sendable, Equatable {
        var titulo: String
        var anio: Int?
        var genero: String
    }

    struct Autor: Codable, Sendable, Equatable, Identifiable {
        var id: String
        var nombre: String
        var nacimiento: Int?
        var muerte: Int?
        var aproximado: Bool
        /// Época escrita (p. ej. «s. VIII a. C.») de los autores antiguos sin años (Fase 05E, §4.4).
        var epoca: String? = nil
        var ambito: String
        var pais: String
        var movimiento: String
        var generos: [String]
        var obras: [Obra]
        var rasgo: String
        var dominioPublico: Bool
        var fragmentosPermitidos: Bool
    }

    static let ambitos: Set<String> = ["espanola", "hispanoamericana", "universal", "infantil"]
    static let ambitosConFragmentos: Set<String> = ["espanola", "hispanoamericana"]
    static let generos: Set<String> = ["poesia", "narrativa", "teatro", "ensayo"]

    var version: Int
    var movimientos: [Movimiento]
    var autores: [Autor]

    /// Año de una obra de un autor (por nombre del autor y título de la obra), si consta.
    func anio(autor: String?, obra: String?) -> Int? {
        guard let autor, let obra else { return nil }
        return autores.first { $0.nombre == autor }?.obras.first { $0.titulo == obra }?.anio
    }
}
