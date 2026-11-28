import Foundation
import StoreKit

// Qué incluye cada versión (fase 06 §1.2, con la corrección de la dirección): una tabla pura que no
// sabe de StoreKit. El servicio de acceso le pasa si hay Premium; las vistas preguntan al servicio.

/// Funciones de la app sujetas a la tabla de acceso.
enum FuncionApp: String, CaseIterable, Sendable {
    // Aprendizaje: todo gratis.
    case camino, sesionDiaria, rescate, juegos, teoria, glosario
    /// Usar la app sin anuncios.
    case sinAnuncios
    // Tribunal.
    /// La muestra SIM.DEMO.01 (hacerla, imprimirla y corregirla): lo único gratis del Tribunal.
    case tribunalMuestra
    /// «Convocatorias anteriores»: los 7 exámenes oficiales, también para consultar los enunciados.
    case convocatoriasAnteriores
    case simulacros, modoExamen, correccion, informe, porBloques
    /// Supervivencia: 1 partida al día gratis; ilimitada con Premium.
    case supervivencia
}

enum Acceso: Sendable, Equatable {
    case permitido, soloPremium
}

enum TablaAcceso {
    /// Partidas de Supervivencia al día en la versión gratuita.
    static let partidasSupervivenciaGratis = 1

    /// Acceso a una función. `partidasSupervivenciaHoy` solo cuenta para Supervivencia (las que ya
    /// se han empezado hoy, día natural del dispositivo).
    static func acceso(_ funcion: FuncionApp, premium: Bool, partidasSupervivenciaHoy: Int = 0) -> Acceso {
        if premium { return .permitido }
        switch funcion {
        case .camino, .sesionDiaria, .rescate, .juegos, .teoria, .glosario, .tribunalMuestra:
            return .permitido
        case .sinAnuncios, .convocatoriasAnteriores, .simulacros, .modoExamen, .correccion, .informe, .porBloques:
            return .soloPremium
        case .supervivencia:
            return partidasSupervivenciaHoy < partidasSupervivenciaGratis ? .permitido : .soloPremium
        }
    }

    /// Un simulacro del catálogo: la muestra es gratis en los dos formatos (hacerla, imprimirla y
    /// corregirla); el resto, con Premium. Sin derecho, un simulacro de pago no se hace, ni se
    /// imprime ni se comparte.
    static func acceso(_ entrada: CatalogoTribunal.Entrada, premium: Bool) -> Acceso {
        acceso(entrada.esMuestra ? .tribunalMuestra : .simulacros, premium: premium)
    }

    /// Exámenes oficiales (completos o medios) y simulacros generados: con Premium.
    static func acceso(_ modo: SesionExamen.Modo, premium: Bool) -> Acceso {
        switch modo {
        case .oficial, .medio: acceso(.convocatoriasAnteriores, premium: premium)
        case .simulacro: acceso(.simulacros, premium: premium)
        }
    }
}

/// Productos de la suscripción «Premium» (un grupo, dos suscripciones autorrenovables con 7 días
/// gratis). Los ids se derivan del identificador del paquete: `<bundleID>.premium.mensual|anual`.
enum ProductosPremium {
    static let prefijoPorDefecto = "com.educulter.dev"

    static func prefijo(_ bundle: Bundle = .main) -> String {
        // En los tests, el paquete principal es la app anfitriona (com.educulter.dev).
        bundle.bundleIdentifier ?? prefijoPorDefecto
    }

    static var mensual: String { prefijo() + ".premium.mensual" }
    static var anual: String { prefijo() + ".premium.anual" }
    static var todos: [String] { [mensual, anual] }
}

/// Último estado conocido del Premium, guardado para funcionar sin conexión.
struct EstadoPremium: Codable, Sendable, Equatable {
    /// Producto con derecho vigente (nil = sin Premium).
    var producto: String?
    /// Fin del periodo pagado o de prueba (las suscripciones siempre lo traen).
    var caducidad: Date?
    /// El derecho vigente empezó con la oferta introductoria (7 días gratis).
    var enPrueba = false
    /// Cuándo se leyó de StoreKit.
    var actualizado: Date?

    static let gratis = EstadoPremium()

    /// Hay Premium en `ahora`: un producto con derecho y sin caducar.
    func activo(_ ahora: Date) -> Bool {
        guard producto != nil else { return false }
        return caducidad.map { $0 > ahora } ?? true
    }
}

/// Almacén de claves pequeñas (estado de acceso y de anuncios). En la app, `UserDefaults`; con
/// `-enMemoria` y en los tests, un diccionario que no sobrevive al proceso.
protocol AlmacenClaves: AnyObject, Sendable {
    func datos(_ clave: String) -> Data?
    func guardar(_ datos: Data?, _ clave: String)
}

extension AlmacenClaves {
    func valor<V: Decodable>(_ tipo: V.Type, _ clave: String) -> V? {
        datos(clave).flatMap { try? JSONDecoder().decode(V.self, from: $0) }
    }

    func guardar<V: Encodable>(valor: V?, _ clave: String) {
        guardar(valor.flatMap { try? JSONEncoder().encode($0) }, clave)
    }
}

final class AlmacenUserDefaults: AlmacenClaves, @unchecked Sendable {
    private let defaults: UserDefaults
    private let prefijo: String

    init(_ defaults: UserDefaults = .standard, prefijo: String = "educulter.") {
        self.defaults = defaults
        self.prefijo = prefijo
    }

    func datos(_ clave: String) -> Data? { defaults.data(forKey: prefijo + clave) }
    func guardar(_ datos: Data?, _ clave: String) { defaults.set(datos, forKey: prefijo + clave) }
}

final class AlmacenEnMemoria: AlmacenClaves, @unchecked Sendable {
    private let cerrojo = NSLock()
    private var valores: [String: Data] = [:]

    init() {}

    func datos(_ clave: String) -> Data? { cerrojo.withLock { valores[clave] } }
    func guardar(_ datos: Data?, _ clave: String) { cerrojo.withLock { valores[clave] = datos } }
}

/// Un plan Premium tal como lo da StoreKit, para los textos de venta.
struct OfertaPremium: Identifiable, Sendable, Equatable {
    var id: String
    var nombre: String
    /// Precio con su moneda, de StoreKit (`displayPrice`).
    var precio: String
    /// Periodo en singular con su artículo para «al …»: «mes», «año», «3 meses».
    var periodo: String
    /// Días de prueba gratis, si el usuario aún tiene derecho a ella.
    var diasPrueba: Int?

    static func periodo(_ unidad: Product.SubscriptionPeriod.Unit, _ valor: Int) -> String? {
        let (uno, varios): (String, String)
        switch unidad {
        case .day: (uno, varios) = ("día", "días")
        case .week: (uno, varios) = ("semana", "semanas")
        case .month: (uno, varios) = ("mes", "meses")
        case .year: (uno, varios) = ("año", "años")
        @unknown default: return nil
        }
        return valor == 1 ? uno : "\(valor) \(varios)"
    }

    static func dias(_ unidad: Product.SubscriptionPeriod.Unit, _ valor: Int) -> Int? {
        switch unidad {
        case .day: valor
        case .week: valor * 7
        default: nil
        }
    }

    /// «Mensual: 7 días gratis. Después, 9,99 € al mes.» (fase 06 §1.4), o sin la prueba si ya se usó.
    var condiciones: String {
        let cada = periodo.first?.isNumber == true ? "cada \(periodo)" : "al \(periodo)"
        if let diasPrueba { return "\(nombre): \(diasPrueba) días gratis. Después, \(precio) \(cada)." }
        return "\(nombre): \(precio) \(cada)."
    }
}

/// Textos de venta: sencillos y honestos (fase 06 §1.5). Sin cuentas atrás ni urgencias.
enum TextosPremium {
    /// Lo que incluye, en 3 líneas cortas.
    static let incluye = [
        "Simulacros y los 7 exámenes oficiales, con su tiempo.",
        "Corrección con criterios, informe y práctica por bloques.",
        "Sin anuncios y Supervivencia sin límite.",
    ]
    static let renovacion = "Se renueva sola. Puedes cancelar cuando quieras en Ajustes > tu nombre > Suscripciones."
    static let gratis = "El aprendizaje diario (Camino, sesión diaria, Rescate, juegos, teoría y Glosario) sigue siendo gratis."
}

/// Enlaces legales de la pantalla Premium.
enum EnlacesLegales {
    /// Términos de uso: el EULA estándar de Apple.
    static let terminos = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// Política de privacidad. PROVISIONAL: la URL definitiva se fija en la fase 08 (ver
    /// docs/legal/PENDIENTES_PROPIETARIO.md). `example.com` es un dominio reservado, sin dueño.
    static let privacidad = URL(string: "https://example.com/educulter/privacidad")!
}
