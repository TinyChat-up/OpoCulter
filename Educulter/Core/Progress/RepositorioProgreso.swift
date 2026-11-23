import Foundation

/// Un intento de respuesta a un ítem.
struct Intento: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var fecha: Date
    var itemId: String
    var competenciaId: String
    var peldano: Int
    var correcto: Bool
    var fraccionCorrecta: Double
    var usoPista = false
    /// Confianza declarada antes de responder (1–3), si se preguntó.
    var confianza: Int?
    var xp = 0
    var motivo: ItemRonda.Motivo?
}

/// Datos globales del jugador: XP, racha, misiones del día y métricas de logros.
struct PerfilJugador: Codable, Sendable, Equatable {
    var xpTotal = 0
    var racha = EstadoRacha()
    var misiones: [Mision] = []
    var diaMisiones: DiaCivil?
    var metricas: [Metrica: Int] = [:]
    /// Competencia que se está trabajando en las rondas recomendadas.
    var competenciaEnCurso: String?
    /// Avatar elegido (índice en `Avatar.todos`); `nil` hasta la bienvenida.
    var avatar: Int?
}

struct LogroObtenido: Codable, Sendable, Equatable {
    var logroId: String
    var fecha: Date
}

/// Acceso al progreso del usuario. Aislado en el MainActor porque `ModelContext` no es `Sendable`
/// y la interfaz lo consume desde el hilo principal. Los tipos que entran y salen son valores.
@MainActor
protocol RepositorioProgreso: AnyObject {
    func registrarIntento(_ intento: Intento) throws
    /// Intentos desde una fecha (incluida), del más antiguo al más reciente.
    func intentos(desde: Date?) throws -> [Intento]

    func estadosCompetencia() throws -> [String: EstadoCompetencia]
    func guardar(_ estado: EstadoCompetencia) throws

    func colaRescate() throws -> ColaRescate
    func guardar(_ cola: ColaRescate) throws

    func perfil() throws -> PerfilJugador
    func guardar(_ perfil: PerfilJugador) throws

    func logros() throws -> [LogroObtenido]
    /// Idempotente: registrar dos veces el mismo logro no lo duplica.
    func registrarLogro(_ logro: LogroObtenido) throws

    func diagnostico() throws -> ResultadoDiagnostico?
    func guardar(_ diagnostico: ResultadoDiagnostico) throws
}

extension RepositorioProgreso {
    /// Último momento en que se vio cada ítem (para no repetir en 24 h).
    func vistos(desde: Date) throws -> [String: Date] {
        try intentos(desde: desde).reduce(into: [:]) { $0[$1.itemId] = max($0[$1.itemId] ?? .distantPast, $1.fecha) }
    }
}

/// Implementación en memoria, para tests y previsualizaciones.
@MainActor
final class RepositorioEnMemoria: RepositorioProgreso {
    private var intentosGuardados: [Intento] = []
    private var estados: [String: EstadoCompetencia] = [:]
    private var cola = ColaRescate()
    private var perfilGuardado = PerfilJugador()
    private var logrosGuardados: [LogroObtenido] = []
    private var diagnosticoGuardado: ResultadoDiagnostico?

    init() {}

    func registrarIntento(_ intento: Intento) throws { intentosGuardados.append(intento) }

    func intentos(desde: Date?) throws -> [Intento] {
        intentosGuardados.filter { i in desde.map { i.fecha >= $0 } ?? true }.sorted { $0.fecha < $1.fecha }
    }

    func estadosCompetencia() throws -> [String: EstadoCompetencia] { estados }
    func guardar(_ estado: EstadoCompetencia) throws { estados[estado.competenciaId] = estado }

    func colaRescate() throws -> ColaRescate { cola }
    func guardar(_ cola: ColaRescate) throws { self.cola = cola }

    func perfil() throws -> PerfilJugador { perfilGuardado }
    func guardar(_ perfil: PerfilJugador) throws { perfilGuardado = perfil }

    func logros() throws -> [LogroObtenido] { logrosGuardados }
    func registrarLogro(_ logro: LogroObtenido) throws {
        guard !logrosGuardados.contains(where: { $0.logroId == logro.logroId }) else { return }
        logrosGuardados.append(logro)
    }

    func diagnostico() throws -> ResultadoDiagnostico? { diagnosticoGuardado }
    func guardar(_ diagnostico: ResultadoDiagnostico) throws { diagnosticoGuardado = diagnostico }
}
