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

/// Avatar del usuario: 12 combinaciones geométricas originales de forma, color y accesorio.
struct Avatar: Sendable, Equatable, Identifiable {
    enum Forma: String, Sendable, CaseIterable { case circulo, cuadrado, triangulo, hexagono }
    enum Tono: String, Sendable, CaseIterable { case indigo, coral, verde, ambar }
    enum Accesorio: String, Sendable, CaseIterable { case gafas, gorro, auriculares }

    let id: Int
    let forma: Forma
    let tono: Tono
    let accesorio: Accesorio

    /// Descripción para VoiceOver y la pantalla de elección.
    var nombre: String {
        let f = ["circulo": "Círculo", "cuadrado": "Cuadrado", "triangulo": "Triángulo", "hexagono": "Hexágono"][forma.rawValue] ?? ""
        let t = ["indigo": "índigo", "coral": "coral", "verde": "verde", "ambar": "ámbar"][tono.rawValue] ?? ""
        let a = ["gafas": "con gafas", "gorro": "con gorro", "auriculares": "con auriculares"][accesorio.rawValue] ?? ""
        return "\(f) \(t) \(a)"
    }

    /// Cada forma aparece 3 veces, cada tono 3 y cada accesorio 4; no hay dos iguales.
    static let todos: [Avatar] = {
        let combinaciones: [(Forma, Tono, Accesorio)] = [
            (.circulo, .indigo, .gafas), (.circulo, .coral, .gorro), (.circulo, .verde, .auriculares),
            (.cuadrado, .ambar, .gafas), (.cuadrado, .indigo, .gorro), (.cuadrado, .coral, .auriculares),
            (.triangulo, .verde, .gafas), (.triangulo, .ambar, .gorro), (.triangulo, .indigo, .auriculares),
            (.hexagono, .coral, .gafas), (.hexagono, .verde, .gorro), (.hexagono, .ambar, .auriculares),
        ]
        return combinaciones.enumerated().map { Avatar(id: $0.offset, forma: $0.element.0, tono: $0.element.1, accesorio: $0.element.2) }
    }()

    static func con(id: Int?) -> Avatar? { id.flatMap { i in todos.first { $0.id == i } } }
}
