import Foundation

/// Personajes de la identidad v3 (05E parte 2, D-105), creados por el propietario y redibujados por
/// la dirección: «Tilde» (coral con lupa) acompaña a Lengua y las pistas; «Cuarto» (marino que guiña),
/// a Matemáticas, Supervivencia y las celebraciones; «Mimo» (crema con corazón), la bienvenida, la
/// racha, el ánimo tras un error repetido y Rescate.
enum Companero: String, Sendable, CaseIterable {
    case tilde
    case cuarto
    case mimo

    static func de(area: String) -> Companero { area == "MAT" ? .cuarto : .tilde }

    var nombre: String {
        switch self {
        case .tilde: "Tilde"
        case .cuarto: "Cuarto"
        case .mimo: "Mimo"
        }
    }
}

/// Los 6 estados (cada uno con su evento real; animaciones ≤ 0,6 s y sin bucle salvo el parpadeo).
enum EstadoPersonaje: String, Sendable, CaseIterable {
    /// Parpadeo cada 4–6 s.
    case neutro
    /// Rebote gomoso y chispas amarillas.
    case alegre
    /// Tilde acerca la lupa; Cuarto mira arriba; Mimo inclina la cabeza.
    case pensando
    /// Mimo aprieta el corazón.
    case animo
    /// Cuarto guiña.
    case guino
    /// Ojos cerrados y brote caído.
    case descanso
}

/// Situaciones reales que hacen aparecer a un personaje. Nunca aparece por aparecer ni mientras se
/// resuelve un ítem: solo en el feedback, en Hoy, en el resumen y en la bienvenida.
enum EventoPersonaje: Sendable, Equatable {
    /// Hoy o la bienvenida, sin otro evento.
    case visible(area: String?)
    case acierto(area: String)
    /// Fallo sin error repetido: no aparece nadie (el feedback ya informa).
    case fallo
    case finSesion(area: String?)
    case subePeldano(area: String)
    case pistaAbierta(area: String)
    /// Error repetido activo (motor de errores, §4).
    case errorRepetido
    case record
    case logro
    case modoDescanso
    case bienvenida
    case primerDia
}

/// Personaje y estado que tocan en un evento (o ninguno).
struct AparicionPersonaje: Sendable, Equatable {
    var companero: Companero
    var estado: EstadoPersonaje
}

enum ReglasPersonaje {
    /// Personaje y estado de cada evento. Como mucho uno por pantalla (cada evento da uno o ninguno).
    static func aparicion(para evento: EventoPersonaje) -> AparicionPersonaje? {
        switch evento {
        case .visible(let area): AparicionPersonaje(companero: area.map(Companero.de(area:)) ?? .mimo, estado: .neutro)
        case .acierto(let area): AparicionPersonaje(companero: .de(area: area), estado: .alegre)
        case .fallo: nil
        case .finSesion(let area): AparicionPersonaje(companero: area.map(Companero.de(area:)) ?? .cuarto, estado: .alegre)
        case .subePeldano(let area): AparicionPersonaje(companero: .de(area: area), estado: .alegre)
        case .pistaAbierta(let area): AparicionPersonaje(companero: .de(area: area), estado: .pensando)
        case .errorRepetido: AparicionPersonaje(companero: .mimo, estado: .animo)
        case .record, .logro: AparicionPersonaje(companero: .cuarto, estado: .guino)
        case .modoDescanso: AparicionPersonaje(companero: .mimo, estado: .descanso)
        case .bienvenida, .primerDia: AparicionPersonaje(companero: .mimo, estado: .neutro)
        }
    }

    /// Etiqueta de VoiceOver: solo cuando el personaje transmite un estado; si no, es decorativo.
    static func etiqueta(_ a: AparicionPersonaje) -> String? {
        switch a.estado {
        case .animo: "\(a.companero.nombre) te anima"
        case .descanso: "\(a.companero.nombre) descansa: modo descanso activo"
        case .guino: "\(a.companero.nombre) te guiña un ojo"
        default: nil
        }
    }

    /// Segundos hasta el siguiente parpadeo (4–6 s), aleatorio con semilla.
    static func intervaloParpadeo(_ rng: inout GeneradorConSemilla) -> Double { Double.random(in: 4...6, using: &rng) }

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

/// Avatar del usuario: las 6 ilustraciones del propietario (D-061), en `Assets.xcassets/Avatares`.
/// La lista sale de `Content/avatares.json` (`AvatarCatalogo`), para cambiarlos por datos.
struct Avatar: Sendable, Equatable, Identifiable {
    let id: Int
    /// Rasgo que lo distingue, para VoiceOver ("Avatar con …").
    let nombre: String
    /// Nombre del recurso en el Asset Catalog.
    var recurso: String

    init(id: Int, nombre: String, recurso: String? = nil) {
        self.id = id
        self.nombre = nombre
        self.recurso = recurso ?? String(format: "avatar_%02d", id + 1)
    }

    static var todos: [Avatar] { AvatarCatalogo.estandar.avatares }

    static func con(id: Int?) -> Avatar? { migrar(id).flatMap { i in todos.first { $0.id == i } } }

    /// Migración de los 12 avatares geométricos de la Fase 05B: los ids 6–11 pasan a 0–5
    /// (`id % 6`); los negativos o desconocidos se descartan (el usuario vuelve a elegir).
    static func migrar(_ id: Int?) -> Int? {
        guard let id, id >= 0, id < 12 else { return nil }
        return id % todos.count
    }
}

/// Catálogo de avatares (`Content/avatares.json`): preparado para sustituir los 6 actuales por los
/// definitivos del propietario cambiando solo los datos (05E parte 2, D-105).
struct AvatarCatalogo: Sendable, Equatable {
    struct Entrada: Codable, Sendable, Equatable { var id: Int; var recurso: String; var nombre: String }
    private struct Archivo: Codable { var avatares: [Entrada] }

    let avatares: [Avatar]

    static let respaldo: [Avatar] = [
        "gorra roja y blanca", "pelo rizado y gafas redondas", "cinta deportiva",
        "pañuelo rojo y aros", "boina y pelo naranja", "gafas de aviador",
    ].enumerated().map { Avatar(id: $0.offset, nombre: $0.element) }

    /// Lee el catálogo de una carpeta de contenido; sin archivo (o vacío), los avatares de respaldo.
    static func cargar(_ raiz: URL?) -> AvatarCatalogo {
        guard let raiz, let datos = try? Data(contentsOf: raiz.appendingPathComponent("avatares.json")),
              let archivo = try? JSONDecoder().decode(Archivo.self, from: datos), !archivo.avatares.isEmpty else {
            return AvatarCatalogo(avatares: respaldo)
        }
        return AvatarCatalogo(avatares: archivo.avatares.map { Avatar(id: $0.id, nombre: $0.nombre, recurso: $0.recurso) })
    }

    static let estandar = cargar(Bundle.main.url(forResource: CargadorContenido.carpetaEnBundle, withExtension: nil))
}
