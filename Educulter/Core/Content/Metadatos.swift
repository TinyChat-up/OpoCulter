import Foundation

/// Origen y licencia de un contenido. Obligatoria en todos los elementos del banco.
struct Procedencia: Codable, Sendable, Equatable {
    enum Tipo: String, Codable, Sendable {
        case original
        case dominioPublico
    }

    var tipo: Tipo
    var autorTexto: String?
    var anioMuerteAutor: Int?
    var fuente: String?
    /// `"propia"` (contenido original) o `"dominio publico"`.
    var licencia: String
    var notas: String?

    static let licenciasValidas: Set<String> = ["propia", "dominio publico"]
}

/// Estado de revisión editorial de un elemento.
struct Validacion: Codable, Sendable, Equatable {
    enum Estado: String, Codable, Sendable {
        case borrador, revisado, aprobado
    }

    var estado: Estado
    var revisor: String?
    /// Fecha de la revisión, `AAAA-MM-DD`.
    var fecha: String?
}

/// Relación del ítem con el examen real y la normativa.
struct Referencia: Codable, Sendable, Equatable {
    var tipoPregunta: String?
    /// Exámenes en los que aparece este tipo de pregunta, con formato `AAAA-L9` / `AAAA-M3`.
    var examenes: [String]?
    var normativa: String?
}

/// Feedback específico para una respuesta errónea frecuente.
struct ErrorHabitual: Codable, Sendable, Equatable {
    /// Id de la opción/ficha elegida o valor de la respuesta errónea.
    var respuesta: String
    var feedback: String
    /// Error típico que delata (`ERR.…` de `errores.json`, 05E parte 2 §4). En los ítems generados lo
    /// pone el catálogo de errores; en los estáticos puede venir en el JSON.
    var error: String? = nil
}
