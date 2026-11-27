import Foundation

// Payloads de la Fase 05H: Rayos X (sintaxis por capas) y Editor (detecta la falta y corrígela).
// Son configuraciones del patrón `marcar` (con `clasificar` en la última capa de Rayos X y la
// elección de forma del Editor); ver D-123.

extension Payload {
    /// Rayos X: 1) el verbo (núcleo del predicado); 2) el sujeto (o «Sujeto omitido» con su
    /// persona); 3) el predicado, que se forma solo; 4) la función de cada grupo del predicado.
    struct RayosX: Codable, Sendable, Equatable {
        struct Grupo: Codable, Sendable, Equatable, Identifiable {
            var id: String
            var tokens: [String]
            var funcion: String
        }

        var tokens: [ElementoTexto]
        /// Núcleo del predicado (un token).
        var verbo: [String]
        /// Tokens del sujeto (vacío si está omitido).
        var sujeto: [String]
        /// Persona del sujeto omitido («nosotros / nosotras»), si lo está.
        var omitido: String?
        /// Personas que ofrece el botón «Sujeto omitido».
        var personas: [String]
        /// Grupos del predicado, sin el verbo, con su función.
        var grupos: [Grupo]
        /// Funciones que se ofrecen en la capa 4 (las de la oración y alguna más).
        var funciones: [ElementoNombre]
        /// 3 (sujeto y predicado) o 4 (también las funciones).
        var capas: Int
        /// Andamiaje (se retira por peldaños): colores por función, pregunta guía visible y
        /// comprobación capa a capa.
        var colores: Bool
        var preguntas: Bool
        var porCapas: Bool
        /// «Predicado verbal» o «Predicado nominal».
        var predicado: String
        /// Preguntas guía y explicación de una línea por capa y por función.
        var guias: [String: String]
        var explicaciones: [String: String]
        /// Esquema completo con corchetes (sujeto/predicado, núcleos y funciones), para el final.
        var esquema: Segmentar
    }

    /// Editor: un párrafo con faltas de una misma familia de formas; se toca la palabra mal escrita
    /// y se elige la forma correcta entre las de su familia.
    struct Editor: Codable, Sendable, Equatable {
        struct Falta: Codable, Sendable, Equatable {
            var token: String
            /// Forma correcta tal como se ve (con su mayúscula y su puntuación).
            var correcta: String
            /// Uso que justifica la forma correcta.
            var uso: String
            /// La forma escrita solo se diferencia de la correcta en la tilde.
            var tilde: Bool
        }

        var tokens: [ElementoTexto]
        /// Formas que se pueden elegir para cada palabra de una familia (con mayúscula y puntuación).
        var formas: [String: [String]]
        var faltas: [Falta]
        /// Penalización del examen visible al final (niveles 5–6).
        var penalizacion: Bool
    }
}

extension Respuesta {
    struct RespuestaRayosX: Sendable, Equatable {
        var verbo: Set<String> = []
        var sujeto: Set<String> = []
        var omitido: String?
        var funciones: [String: String] = [:]
        /// Capa en curso (1…capas); `capas + 1` cuando todas están confirmadas.
        var capa = 1
        /// Capas que han fallado alguna vez (cuenta como un primer intento con pista).
        var fallos: Set<Int> = []
    }

    struct RespuestaEditor: Sendable, Equatable {
        var marcadas: Set<String> = []
        var cambios: [String: String] = [:]
    }
}

extension Payload.RayosX {
    /// Errores de cada capa (vacío si la capa está bien).
    func errores(capa: Int, _ r: Respuesta.RespuestaRayosX) -> [String] {
        switch capa {
        case 1: return r.verbo == Set(verbo) ? [] : ["verbo"]
        case 2:
            if let omitido { return r.omitido == omitido && r.sujeto.isEmpty ? [] : (r.sujeto.isEmpty ? ["omitido"] : ["sujetoOmitido"]) }
            return r.omitido == nil && r.sujeto == Set(sujeto) ? [] : (r.omitido != nil ? ["noOmitido"] : ["sujeto"])
        case 3: return []
        default: return grupos.filter { r.funciones[$0.id] != $0.funcion }.map { "grupo_\($0.id)" }
        }
    }

    var respuestaCorrecta: Respuesta.RespuestaRayosX {
        Respuesta.RespuestaRayosX(verbo: Set(verbo), sujeto: Set(sujeto), omitido: omitido,
                                  funciones: capas >= 4 ? Dictionary(uniqueKeysWithValues: grupos.map { ($0.id, $0.funcion) }) : [:],
                                  capa: capas + 1)
    }

    /// Texto de un grupo de tokens.
    func texto(_ ids: [String]) -> String {
        let porId = Dictionary(tokens.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
        return ids.compactMap { porId[$0] }.joined(separator: " ")
    }
}

extension Payload.Editor {
    var respuestaCorrecta: Respuesta.RespuestaEditor {
        Respuesta.RespuestaEditor(marcadas: Set(faltas.map(\.token)), cambios: Dictionary(uniqueKeysWithValues: faltas.map { ($0.token, $0.correcta) }))
    }

    /// Penalización del examen si las faltas quedan sin corregir: −0,5 por palabra, −0,25 por tilde.
    var puntosPenalizacion: Double { faltas.reduce(0) { $0 + ($1.tilde ? 0.25 : 0.5) } }
}
