import Foundation

/// Contrato de intento común a todos los juegos (Fase 05G §2, D-116).
///
/// Flujo de cada actividad: primer intento → si falla, una pista que explica el razonamiento (no
/// la solución) y un reintento editando la misma respuesta → si vuelve a fallar, la solución con su
/// porqué. En la misma sesión o en la siguiente, una variante sin ayudas (la misma plantilla, otra
/// semilla, sin pista ni colores).
struct IntentoActividad: Codable, Sendable, Equatable, Identifiable {
    enum Ayuda: String, Codable, Sendable, CaseIterable { case pista, colores, ejemplo }

    /// Resultado final del intento.
    enum ResultadoFinal: String, Codable, Sendable {
        /// Acierto sin ayudas y en el primer intento: el único que cuenta para el dominio.
        case dominio
        /// Acierto con pista o en el reintento: «en progreso» (no sube de caja en Leitner).
        case enProgreso
        /// Falla también el reintento: se muestra la solución.
        case fallo
        /// Recuerdo: autoevaluación, no es una nota automática ni cuenta para el dominio.
        case autoevaluacion
    }

    var id = UUID()
    var fecha: Date
    /// Id del ítem (o de la actividad) fuente y su versión.
    var fuente: String
    var version: Int
    var competencia: String
    /// Destreza que entrena (p. ej., «idea central», «área compuesta»).
    var destreza: String
    var patron: Patron
    var primeraRespuesta: String
    var primerCorrecto: Bool
    var ayudas: Set<Ayuda> = []
    var reintento: String?
    var reintentoCorrecto: Bool?
    var errorId: String?
    /// Variante sin ayudas (programada tras la primera actividad de la competencia).
    var sinAyudas = false
    var resultado: ResultadoFinal
    /// Duración en segundos.
    var duracion: Double

    /// Resultado final según el contrato: dominio solo con acierto en el primer intento y sin ayudas.
    static func resultado(primerCorrecto: Bool, ayudas: Set<Ayuda>, reintentoCorrecto: Bool?, autoevaluacion: Bool = false) -> ResultadoFinal {
        if autoevaluacion { return .autoevaluacion }
        if primerCorrecto { return ayudas.isEmpty ? .dominio : .enProgreso }
        return reintentoCorrecto == true ? .enProgreso : .fallo
    }

    /// Cuenta para el dominio (escalera y Leitner suben).
    var cuentaParaDominio: Bool { resultado == .dominio }
}

/// Estado del flujo de una actividad en pantalla (puro y testeable).
struct FlujoIntento: Sendable, Equatable {
    enum Fase: Sendable, Equatable {
        case primerIntento
        /// Falló el primer intento: se muestra la pista y se edita la misma respuesta.
        case reintento(pista: String)
        /// Terminado: con la solución si falló también el reintento.
        case terminado(IntentoActividad.ResultadoFinal)
    }

    private(set) var fase: Fase = .primerIntento
    private(set) var primerCorrecto: Bool?
    private(set) var reintentoCorrecto: Bool?
    var ayudas: Set<IntentoActividad.Ayuda> = []
    let autoevaluacion: Bool

    init(autoevaluacion: Bool = false, ayudasIniciales: Set<IntentoActividad.Ayuda> = []) {
        self.autoevaluacion = autoevaluacion
        self.ayudas = ayudasIniciales
    }

    /// Registra una comprobación. `pista` es la del error cometido (o la general).
    mutating func comprobar(correcto: Bool, pista: String) {
        switch fase {
        case .primerIntento:
            primerCorrecto = correcto
            if correcto || autoevaluacion {
                fase = .terminado(IntentoActividad.resultado(primerCorrecto: correcto, ayudas: ayudas, reintentoCorrecto: nil, autoevaluacion: autoevaluacion))
            } else {
                ayudas.insert(.pista)
                fase = .reintento(pista: pista)
            }
        case .reintento:
            reintentoCorrecto = correcto
            fase = .terminado(IntentoActividad.resultado(primerCorrecto: false, ayudas: ayudas, reintentoCorrecto: correcto))
        case .terminado:
            break
        }
    }

    var terminado: Bool { if case .terminado = fase { true } else { false } }
    var resultado: IntentoActividad.ResultadoFinal? { if case .terminado(let r) = fase { r } else { nil } }
}

/// Retención (§2): la variante sin ayudas de cada competencia nueva se programa a los 2 días.
enum RetencionJuegos {
    static let diasHastaVariante = 2

    /// Competencias con una variante sin ayudas pendiente a fecha `hoy`: tienen intentos de juego
    /// sin ayudas programados (el primero hace al menos 2 días) y ninguna variante sin ayudas después.
    static func variantesPendientes(_ intentos: [IntentoActividad], hoy: DiaCivil, calendario: Calendar) -> [String] {
        let porCompetencia = Dictionary(grouping: intentos, by: \.competencia)
        return porCompetencia.compactMap { c, lista -> String? in
            let normales = lista.filter { !$0.sinAyudas }.sorted { $0.fecha < $1.fecha }
            guard let primero = normales.first else { return nil }
            let vence = DiaCivil(primero.fecha, calendario: calendario).sumando(dias: diasHastaVariante)
            guard vence <= hoy else { return nil }
            let hecha = lista.contains { $0.sinAyudas && $0.fecha >= primero.fecha }
            return hecha ? nil : c
        }.sorted()
    }
}
