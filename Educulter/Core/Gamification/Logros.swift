import Foundation

/// Contadores del usuario sobre los que se definen los logros.
enum Metrica: String, Codable, Sendable, CaseIterable {
    case aciertosTotales
    case rondasCompletadas
    case rescates
    case rachaRecord
    case competenciasDominadas
    /// Ítems de segmentar (sintaxis) resueltos sin ningún error.
    case sintaxisPerfectas
    case simulacrosAprobados
    case diagnosticosCompletados
    /// Fase 05D.
    case partidasSupervivencia
    case recordsSupervivencia
    case nivelMaximoSupervivencia
    case pruebasNivelSuperadas
    case medallasBloque
}

/// Condición declarativa de un logro (datos, no código: se puede ampliar sin tocar el motor).
indirect enum CondicionLogro: Sendable, Equatable {
    case alMenos(Metrica, Int)
    case todas([CondicionLogro])
    case alguna([CondicionLogro])

    func cumple(_ metricas: [Metrica: Int]) -> Bool {
        switch self {
        case .alMenos(let m, let umbral): (metricas[m] ?? 0) >= umbral
        case .todas(let cs): cs.allSatisfy { $0.cumple(metricas) }
        case .alguna(let cs): cs.contains { $0.cumple(metricas) }
        }
    }
}

struct Logro: Sendable, Equatable, Identifiable {
    var id: String
    var titulo: String
    var descripcion: String
    var condicion: CondicionLogro
}

/// Motor genérico de logros basado en reglas.
struct MotorLogros: Sendable {
    var logros: [Logro]

    init(logros: [Logro] = MotorLogros.ejemplos) {
        self.logros = logros
    }

    /// Logros que se cumplen ahora y aún no se habían obtenido, en el orden del catálogo.
    func nuevos(metricas: [Metrica: Int], obtenidos: Set<String>) -> [Logro] {
        logros.filter { !obtenidos.contains($0.id) && $0.condicion.cumple(metricas) }
    }

    /// 5 logros de ejemplo. El catálogo completo (~20) se define con el contenido (Fase 05).
    static let ejemplos: [Logro] = [
        Logro(id: "primera-ronda", titulo: "Primer paso", descripcion: "Completa tu primera ronda.",
              condicion: .alMenos(.rondasCompletadas, 1)),
        Logro(id: "sintaxis-perfecta", titulo: "Sintaxis perfecta", descripcion: "Analiza una oración sin ningún error.",
              condicion: .alMenos(.sintaxisPerfectas, 1)),
        Logro(id: "rescatador", titulo: "Rescatador", descripcion: "Rescata 10 errores.",
              condicion: .alMenos(.rescates, 10)),
        Logro(id: "semana-de-fuego", titulo: "Semana de fuego", descripcion: "Mantén una racha de 7 días.",
              condicion: .alMenos(.rachaRecord, 7)),
        Logro(id: "listo-para-examen", titulo: "Listo para el examen",
              descripcion: "Domina una competencia y aprueba un simulacro.",
              condicion: .todas([.alMenos(.competenciasDominadas, 1), .alMenos(.simulacrosAprobados, 1)])),
        // Fase 05D.
        Logro(id: "diagnostico", titulo: "Punto de partida", descripcion: "Completa el diagnóstico inicial.",
              condicion: .alMenos(.diagnosticosCompletados, 1)),
        Logro(id: "superviviente", titulo: "Superviviente", descripcion: "Termina una partida de Supervivencia.",
              condicion: .alMenos(.partidasSupervivencia, 1)),
        Logro(id: "nuevo-record", titulo: "Nuevo récord", descripcion: "Supera tu mejor partida de Supervivencia.",
              condicion: .alMenos(.recordsSupervivencia, 1)),
        Logro(id: "experto", titulo: "Nivel Experto", descripcion: "Llega al nivel 6 en Supervivencia.",
              condicion: .alMenos(.nivelMaximoSupervivencia, 6)),
        Logro(id: "salto-de-nivel", titulo: "Salto de nivel", descripcion: "Supera una prueba de nivel en el Camino.",
              condicion: .alMenos(.pruebasNivelSuperadas, 1)),
        Logro(id: "primera-medalla", titulo: "Primera medalla", descripcion: "Supera un Reto de bloque.",
              condicion: .alMenos(.medallasBloque, 1)),
    ]

    /// Medalla de un bloque (se concede al superar su Reto; no depende de métricas).
    static func medalla(_ bloque: Catalogo.Bloque) -> Logro {
        Logro(id: ConstructorCamino.medalla(bloque.id), titulo: "Medalla: \(bloque.nombre)",
              descripcion: "Supera el Reto de bloque de \(bloque.nombre).", condicion: .alMenos(.medallasBloque, Int.max))
    }
}
