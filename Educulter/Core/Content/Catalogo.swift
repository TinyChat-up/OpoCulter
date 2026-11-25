import Foundation

/// Catálogo de áreas, bloques y competencias (`Content/catalogo.json`).
struct Catalogo: Codable, Sendable, Equatable {
    var version: Int
    var areas: [Area]

    struct Area: Codable, Sendable, Equatable, Identifiable {
        var id: String
        var nombre: String
        var bloques: [Bloque]
    }

    struct Bloque: Codable, Sendable, Equatable, Identifiable {
        var id: String
        var nombre: String
        /// 1 (★) a 3 (★★★). Los bloques de prioridad 3 entran en el diagnóstico.
        var prioridad: Int
        var orden: Int
        var competencias: [Competencia]
    }

    struct Competencia: Codable, Sendable, Equatable, Identifiable {
        var id: String
        var nombre: String
        var orden: Int
        /// Competencia del mapa curricular de la A1 que sustituye a esta (Fase 05E, D-091). El id
        /// antiguo se conserva por el progreso guardado; sin contenido, no se muestra en el Camino.
        var equivaleA: String? = nil
    }

    /// Todos los bloques, en el orden de áreas y de `orden`.
    var todosLosBloques: [Bloque] {
        areas.flatMap { $0.bloques.sorted { $0.orden < $1.orden } }
    }

    /// Todas las competencias del catálogo.
    var todasLasCompetencias: [Competencia] {
        todosLosBloques.flatMap { $0.competencias.sorted { $0.orden < $1.orden } }
    }

    func bloque(id: String) -> Bloque? {
        todosLosBloques.first { $0.id == id }
    }

    /// Bloque al que pertenece una competencia.
    func bloque(deCompetencia competenciaId: String) -> Bloque? {
        todosLosBloques.first { $0.competencias.contains { $0.id == competenciaId } }
    }

    /// Área (`LEN` o `MAT`) a la que pertenece un bloque o una competencia, por su prefijo.
    static func area(de id: String) -> String {
        String(id.prefix { $0 != "." })
    }
}
