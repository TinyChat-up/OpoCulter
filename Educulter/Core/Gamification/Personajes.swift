import Foundation

/// Compañeros guía (originales del proyecto, D-054): «Tilde» acompaña a Lengua y «Cuarto»
/// a Matemáticas.
enum Companero: String, Sendable, CaseIterable {
    case tilde
    case cuarto

    static func de(area: String) -> Companero { area == "MAT" ? .cuarto : .tilde }

    var nombre: String {
        switch self {
        case .tilde: "Tilde"
        case .cuarto: "Cuarto"
        }
    }
}

/// Los 6 estados animables de cada compañero.
enum EstadoPersonaje: String, Sendable, CaseIterable {
    case neutral
    case pensando
    case celebra
    /// Tras un fallo: anima, nunca se burla.
    case anima
    /// Récord (p. ej., de Supervivencia).
    case sorprendido
    /// Racha en riesgo.
    case dormido
}

/// Situaciones reales que hacen aparecer a un compañero. Nunca aparece por aparecer.
enum EventoPersonaje: Sendable, Equatable {
    case feedback(correcto: Bool)
    case resumenRonda(aciertos: Int, total: Int)
    case estadoVacio
    case bienvenida
    case rachaEnRiesgo
    case recordSupervivencia
}

enum ReglasPersonaje {
    /// Estado que corresponde a cada evento.
    static func estado(para evento: EventoPersonaje) -> EstadoPersonaje {
        switch evento {
        case .feedback(let correcto): correcto ? .celebra : .anima
        case .resumenRonda(let aciertos, let total): total > 0 && aciertos * 2 >= total ? .celebra : .anima
        case .estadoVacio: .pensando
        case .bienvenida: .neutral
        case .rachaEnRiesgo: .dormido
        case .recordSupervivencia: .sorprendido
        }
    }

    /// Horas antes de medianoche a partir de las que se avisa (D-054).
    static let horasAvisoRacha = 4

    /// La racha está en riesgo si hay racha, hoy todavía no se ha completado ninguna ronda y
    /// quedan menos de 4 horas para medianoche (en el calendario del usuario).
    static func rachaEnRiesgo(_ racha: EstadoRacha, ahora: Date, calendario: Calendar) -> Bool {
        let hoy = DiaCivil(ahora, calendario: calendario)
        guard racha.actual > 0, racha.ultimoDiaActivo != hoy,
              let manana = calendario.date(byAdding: .day, value: 1, to: calendario.startOfDay(for: ahora)) else { return false }
        return manana.timeIntervalSince(ahora) < Double(horasAvisoRacha) * 3600
    }

    /// Horas completas que quedan hasta medianoche (para el texto del aviso).
    static func horasHastaMedianoche(ahora: Date, calendario: Calendar) -> Int {
        guard let manana = calendario.date(byAdding: .day, value: 1, to: calendario.startOfDay(for: ahora)) else { return 0 }
        return max(0, Int(manana.timeIntervalSince(ahora) / 3600))
    }
}

/// Avatar del usuario: las 6 ilustraciones del propietario (D-061), recortadas de
/// `docs/arte/avatares_propietario.png` con `scripts/recortar_avatares.swift` y guardadas en
/// `Assets.xcassets/Avatares/avatar_01…06`. Los ids 0–5 son los nuevos avatares.
struct Avatar: Sendable, Equatable, Identifiable {
    let id: Int
    /// Rasgo que lo distingue, para VoiceOver ("Avatar con …").
    let nombre: String

    /// Nombre del recurso en el Asset Catalog.
    var recurso: String { String(format: "avatar_%02d", id + 1) }

    static let todos: [Avatar] = [
        "gorra roja y blanca",
        "pelo rizado y gafas redondas",
        "cinta deportiva",
        "pañuelo rojo y aros",
        "boina y pelo naranja",
        "gafas de aviador",
    ].enumerated().map { Avatar(id: $0.offset, nombre: $0.element) }

    static func con(id: Int?) -> Avatar? { migrar(id).flatMap { i in todos.first { $0.id == i } } }

    /// Migración de los 12 avatares geométricos de la Fase 05B: los ids 6–11 pasan a 0–5
    /// (`id % 6`); los negativos o desconocidos se descartan (el usuario vuelve a elegir).
    static func migrar(_ id: Int?) -> Int? {
        guard let id, id >= 0, id < 12 else { return nil }
        return id % todos.count
    }
}
