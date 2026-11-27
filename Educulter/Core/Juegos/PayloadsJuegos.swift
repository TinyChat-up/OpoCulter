import Foundation

// Payloads de los patrones nuevos de la Fase 05G: evidencia, recuerdo y modelo con figura (D-117).

extension Payload {
    /// Patrón `evidencia`: un texto base partido en fragmentos que se tocan. Vale cualquiera de los
    /// `aceptados`; tocar un `detalle` es un error explicado (con su pista).
    struct Evidencia: Codable, Sendable, Equatable {
        var titulo: String
        /// El texto entero, en orden, partido en fragmentos tocables.
        var fragmentos: [ElementoTexto]
        var aceptados: [String]
        var detalles: [String]
        /// Pista de razonamiento cuando se toca un detalle (no da la solución).
        var pistaDetalle: String
        /// Pista cuando se toca otro fragmento.
        var pistaOtro: String
    }

    /// Patrón `recuerdo`: el usuario escribe (o lo hace en papel) y después se autoevalúa con un modelo
    /// y unos criterios. No es una nota automática ni cuenta para el dominio.
    struct Recuerdo: Codable, Sendable, Equatable {
        var modelo: String
        var criterios: [String]
        /// Longitud máxima del campo breve.
        var maximo: Int
    }

    /// Patrón `modelo` con figura: área de una figura compuesta sobre una cuadrícula.
    struct FiguraArea: Codable, Sendable, Equatable {
        /// Pieza de la figura (en las coordenadas del dibujo; las medidas reales van en los rótulos).
        enum Forma: Codable, Sendable, Equatable {
            case poligono([Punto])
            /// Semicírculo con el diámetro entre `a` y `b`, hacia fuera del polígono.
            case semicirculo(a: Punto, b: Punto)
        }

        struct Punto: Codable, Sendable, Equatable, Hashable {
            var x: Double
            var y: Double
        }

        struct Segmento: Codable, Sendable, Equatable, Hashable, Identifiable {
            var id: String
            var a: Punto
            var b: Punto
        }

        struct Rotulo: Codable, Sendable, Equatable {
            var a: Punto
            var b: Punto
            var texto: String
        }

        /// Parte de una descomposición: su área (texto con coma) y las medidas que la dan.
        struct Parte: Codable, Sendable, Equatable, Identifiable {
            var id: String
            var forma: Forma
            /// `+1` se suma; `-1` se resta (hueco).
            var signo: Int
            var area: String
            /// Cómo se calcula, para la explicación («6 × 4 = 24»).
            var calculo: String
        }

        struct Descomposicion: Codable, Sendable, Equatable, Identifiable {
            var id: String
            var estrategia: Estrategia
            /// Ids de los segmentos de corte que la definen.
            var cortes: [String]
            var partes: [Parte]
        }

        enum Estrategia: String, Codable, Sendable, CaseIterable {
            case sumar, restar
            var nombre: String { self == .sumar ? "Sumar partes" : "Restar el hueco" }
        }

        /// Región pintada: piezas que se suman (y huecos que se restan).
        var region: [Parte]
        /// Ancho y alto del dibujo (para escalarlo) y paso de la cuadrícula.
        var ancho: Double
        var alto: Double
        var paso: Double
        var rotulos: [Rotulo]
        /// Cortes candidatos de todas las descomposiciones (se muestran discontinuos en los peldaños 1–2).
        var cortes: [Segmento]
        var descomposiciones: [Descomposicion]
        var mostrarCortes: Bool
        /// Área total (texto con coma) y unidad cuadrada correcta («m²»).
        var total: String
        var unidad: String
        var unidadesOpciones: [String]
        /// Descripción textual de la figura para VoiceOver: medidas y relaciones, sin la operación.
        var descripcion: String
        /// Totales que delatan un error típico (código → valor con coma): sumar el hueco, usar el
        /// perímetro, el triángulo sin dividir entre 2, no convertir las unidades mixtas.
        var erroneos: [String: String] = [:]
    }
}

extension Respuesta {
    /// Respuesta del modelo con figura: estrategia, cortes elegidos, área de cada parte, total y unidad.
    struct RespuestaFigura: Sendable, Equatable {
        var estrategia: Payload.FiguraArea.Estrategia?
        var cortes: Set<String> = []
        var areas: [String: String] = [:]
        var total: String = ""
        var unidad: String?
    }

    /// Respuesta del recuerdo: lo escrito (o «en papel»), si ya se ha visto el modelo y los criterios
    /// que el usuario marca como cumplidos.
    struct RespuestaRecuerdo: Sendable, Equatable {
        var texto: String = ""
        var enPapel = false
        var modeloVisto = false
        var cumplidos: Set<Int> = []
    }
}

extension Payload.FiguraArea {
    /// Descomposición que forman los cortes elegidos con esa estrategia (si es una de las válidas).
    func descomposicion(estrategia: Estrategia?, cortes: Set<String>) -> Descomposicion? {
        guard let estrategia else { return nil }
        return descomposiciones.first { $0.estrategia == estrategia && Set($0.cortes) == cortes }
    }

    var estrategiasValidas: Set<Estrategia> { Set(descomposiciones.map(\.estrategia)) }
}

extension Payload.FiguraArea {
    /// Respuesta correcta de referencia: la primera descomposición, con sus áreas.
    var respuestaCorrecta: Respuesta.RespuestaFigura {
        let d = descomposiciones.first
        return Respuesta.RespuestaFigura(estrategia: d?.estrategia, cortes: Set(d?.cortes ?? []),
                                         areas: Dictionary((d?.partes ?? []).map { ($0.id, $0.area) }, uniquingKeysWith: { a, _ in a }),
                                         total: total, unidad: unidad)
    }
}
