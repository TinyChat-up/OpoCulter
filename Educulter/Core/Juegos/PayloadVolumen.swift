import Foundation

// «Capas y sólidos» (MAT.GEO.VOL, Fase 05K §1): patrón `modelo` con un sólido en perspectiva
// isométrica. Los pasos intermedios (área de la base, capas o altura, partes) ayudan a construir el
// resultado; el valor final y su unidad, elegida aparte, deciden si la respuesta es correcta.

extension Payload {
    struct FiguraVolumen: Codable, Sendable, Equatable {
        enum Forma: String, Codable, Sendable {
            case ortoedro, cilindro
        }

        /// Sólido en las coordenadas del dibujo: `x` a lo largo, `y` a lo ancho (fondo) y `z` hacia
        /// arriba. En el cilindro, `largo` = `ancho` = diámetro.
        struct Solido: Codable, Sendable, Equatable, Identifiable {
            var id: String
            var forma: Forma
            var x: Double = 0
            var y: Double = 0
            var z: Double = 0
            var largo: Double
            var ancho: Double
            var alto: Double
        }

        enum Arista: String, Codable, Sendable {
            case largo, ancho, alto, radio, diametro, agua
        }

        /// Medida rotulada sobre una arista de un sólido.
        struct Rotulo: Codable, Sendable, Equatable {
            var solido: String
            var arista: Arista
            var texto: String
        }

        /// Paso intermedio que se teclea (su valor es texto con coma).
        struct Campo: Codable, Sendable, Equatable, Identifiable {
            var id: String
            var etiqueta: String
            var valor: String
        }

        var solidos: [Solido]
        var rotulos: [Rotulo]
        /// Altura del agua (en unidades del dibujo) dentro del primer sólido, si es un depósito.
        var agua: Double?
        /// El sólido se ve como cubos unitarios que se apilan por capas (peldaños 1–2).
        var cubos: Bool
        var campos: [Campo]
        /// Resultado final (texto con coma) y su unidad, que se elige aparte.
        var resultado: String
        var unidad: String
        var unidadesOpciones: [String]
        /// Etiqueta del resultado («Volumen», «Capacidad», «Altura del agua»).
        var etiquetaResultado: String
        /// Descripción para VoiceOver: el sólido y sus medidas, sin la operación.
        var descripcion: String
        /// Resultados que delatan un error típico (código → valor con coma).
        var erroneos: [String: String] = [:]

        /// Capas del sólido en cubos (su altura), si se ve como cubos.
        var capas: Int? { cubos ? solidos.first.map { Int($0.alto.rounded()) } : nil }
    }
}

extension Respuesta {
    /// Respuesta de «Capas y sólidos»: los pasos tecleados, el resultado y la unidad.
    struct RespuestaVolumen: Codable, Sendable, Equatable {
        var valores: [String: String] = [:]
        var resultado: String = ""
        var unidad: String?
    }
}

extension Payload.FiguraVolumen {
    var respuestaCorrecta: Respuesta.RespuestaVolumen {
        Respuesta.RespuestaVolumen(valores: Dictionary(campos.map { ($0.id, $0.valor) }, uniquingKeysWith: { a, _ in a }),
                                   resultado: resultado, unidad: unidad)
    }

    /// Manda el resultado (por valor) con su unidad. Los pasos intermedios tecleados que no
    /// coinciden se señalan (`campo_<id>`); el error típico cuyo valor coincide con el resultado va
    /// primero (su pista es la del reintento); si no hay ninguno, `resultado`.
    func evaluar(_ r: Respuesta.RespuestaVolumen) -> Resultado {
        func valor(_ t: String) -> Racional? { Racional.interpretar(t)?.valor }
        let bien = valor(r.resultado) != nil && valor(r.resultado) == valor(resultado)
        let unidadBien = r.unidad == unidad
        var errores: [String] = []
        if !bien {
            let tipicos = erroneos.sorted { $0.key < $1.key }.filter { valor($0.value) == valor(r.resultado) }.map(\.key)
            errores += tipicos.isEmpty ? ["resultado"] : tipicos
        }
        for c in campos {
            if let dado = r.valores[c.id], !dado.isEmpty, valor(dado) != valor(c.valor) { errores.append("campo_\(c.id)") }
        }
        if !unidadBien { errores.append("unidad") }
        let correcto = bien && unidadBien
        return Resultado(correcto: correcto, fraccionCorrecta: correcto ? 1 : (bien || unidadBien ? 0.5 : 0), errores: correcto ? [] : errores)
    }
}
