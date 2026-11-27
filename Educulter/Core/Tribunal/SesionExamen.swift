import Foundation

/// Un examen del Tribunal en curso o terminado (05I §3). Se guarda tal cual (JSON en SwiftData):
/// si la app se cierra, se reanuda en la misma pregunta y con el tiempo que quedaba.
struct SesionExamen: Codable, Sendable, Equatable, Identifiable {
    enum Modo: Codable, Sendable, Equatable {
        /// Examen oficial completo (90 min).
        case oficial(String)
        /// Medio examen: solo un área (45 min).
        case medio(String, area: String)
        /// Simulacro original generado con semilla (90 min).
        case simulacro(semilla: UInt64)

        var nombre: String {
            switch self {
            case .oficial: "Examen oficial"
            case .medio(_, let area): area == "LEN" ? "Medio examen · Lengua" : "Medio examen · Matemáticas"
            case .simulacro: "Simulacro original"
            }
        }

        var examenId: String? {
            switch self {
            case .oficial(let id), .medio(let id, _): id
            case .simulacro: nil
            }
        }
    }

    /// Pregunta del examen: oficial (por convocatoria y número) o un ítem del banco (simulacro).
    enum Pregunta: Codable, Sendable, Equatable {
        case oficial(examen: String, numero: Int)
        case item(id: String, area: String)
    }

    enum Estado: String, Codable, Sendable { case enCurso, entregado, corregido }

    /// Respuesta de una pregunta: breve (Lengua), valor y unidad (Matemáticas), «en papel» o la
    /// respuesta con la mecánica del ítem (simulacro).
    struct RespuestaPregunta: Codable, Sendable, Equatable {
        var texto = ""
        var valor = ""
        var unidad: String?
        var enPapel = false
        var item: Respuesta?

        var vacia: Bool { texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && valor.isEmpty && !enPapel && item == nil }
    }

    /// Autoevaluación de una pregunta abierta: B (1), R (0,5) o M (0) del valor, y las faltas
    /// (palabras distintas) contadas comparando con el modelo.
    struct Autoevaluacion: Codable, Sendable, Equatable {
        enum Nivel: String, Codable, Sendable, CaseIterable {
            case bien, regular, mal
            var valor: Double { switch self { case .bien: 1; case .regular: 0.5; case .mal: 0 } }
            var letra: String { switch self { case .bien: "B"; case .regular: "R"; case .mal: "M" } }
        }
        var nivel: Nivel
        var palabras = 0
        var tildes = 0
    }

    var id = UUID()
    var inicio: Date
    var modo: Modo
    var preguntas: [Pregunta]
    var respuestas: [Int: RespuestaPregunta] = [:]
    var marcadas: Set<Int> = []
    var actual = 0
    /// Duración y tiempo que queda (segundos).
    var duracion: Double
    var restante: Double
    var estado: Estado = .enCurso
    var autoevaluaciones: [Int: Autoevaluacion] = [:]
    /// Borrador de cada pregunta (dibujo de PencilKit serializado); persiste durante el examen.
    var borradores: [Int: Data] = [:]
    /// Competencias del plano que el simulacro no pudo incluir (sin contenido aprobado).
    var noIncluye: [String] = []
    var fin: Date?
    var resultado: ResultadoExamen?
    /// Se entregó solo al llegar a 0.
    var entregaAutomatica = false

    init(modo: Modo, preguntas: [Pregunta], duracionMin: Int, inicio: Date, noIncluye: [String] = []) {
        self.modo = modo
        self.preguntas = preguntas
        self.duracion = Double(duracionMin * 60)
        self.restante = Double(duracionMin * 60)
        self.inicio = inicio
        self.noIncluye = noIncluye
    }

    // MARK: Cuenta atrás

    /// Avisos discretos a los 15 y a los 5 minutos.
    static let avisos: [Double] = [15 * 60, 5 * 60]

    /// Descuenta tiempo (solo mientras la app está activa: en segundo plano el reloj se pausa). Al
    /// llegar a 0, el examen se entrega solo. Devuelve el aviso que se cruza, si alguno.
    @discardableResult
    mutating func avanzar(_ segundos: Double, ahora: Date) -> Double? {
        guard estado == .enCurso, segundos > 0 else { return nil }
        let antes = restante
        restante = max(0, restante - segundos)
        if restante == 0 { entregar(ahora: ahora, automatica: true) }
        return Self.avisos.first { antes > $0 && restante <= $0 }
    }

    mutating func entregar(ahora: Date, automatica: Bool = false) {
        guard estado == .enCurso else { return }
        estado = .entregado
        fin = ahora
        entregaAutomatica = automatica
    }

    // MARK: Respuestas

    func respondida(_ i: Int) -> Bool { !(respuestas[i]?.vacia ?? true) }
    var sinResponder: Int { preguntas.indices.filter { !respondida($0) }.count }
    var area: String? { if case .medio(_, let a) = modo { a } else { nil } }
}

extension SesionExamen.Pregunta {
    var area: String {
        switch self {
        case .oficial: ""
        case .item(_, let area): area
        }
    }
}
