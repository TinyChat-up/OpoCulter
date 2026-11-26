import Foundation

/// Error típico (05E parte 2, §4, D-107): un fallo concreto que el usuario puede repetir, con su
/// descripción en segunda persona (≤ 12 palabras) y el remedio que lo trabaja.
struct ErrorTipico: Codable, Sendable, Equatable, Identifiable {
    struct Remedio: Codable, Sendable, Equatable {
        /// Plantilla que trabaja el error.
        var plantilla: String
        var dificultad: Int
        /// Regla breve que se muestra antes de los ítems del remedio.
        var explicacion: String
        /// Tarjeta de teoría opcional.
        var tarjeta: String?
    }

    /// Distractor de un generador que delata el error: tipo de generador y expresión regular sobre
    /// el texto de feedback del distractor (los generadores no conocen el catálogo de errores).
    struct Deteccion: Codable, Sendable, Equatable {
        var generador: String
        var patron: String
    }

    /// `ERR.<competencia>.<n>`.
    var id: String
    var competencia: String
    var descripcion: String
    var remedio: Remedio
    var detecta: [Deteccion] = []

    private enum CodingKeys: String, CodingKey { case id, competencia, descripcion, remedio, detecta }

    init(id: String, competencia: String, descripcion: String, remedio: Remedio, detecta: [Deteccion] = []) {
        self.id = id
        self.competencia = competencia
        self.descripcion = descripcion
        self.remedio = remedio
        self.detecta = detecta
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        competencia = try c.decode(String.self, forKey: .competencia)
        descripcion = try c.decode(String.self, forKey: .descripcion)
        remedio = try c.decode(Remedio.self, forKey: .remedio)
        detecta = try c.decodeIfPresent([Deteccion].self, forKey: .detecta) ?? []
    }
}

/// Catálogo de errores típicos (`Content/errores.json`). Etiqueta los distractores de los ítems
/// generados: el primer error de la competencia del ítem cuyo patrón casa con el feedback.
struct CatalogoErrores: Codable, Sendable, Equatable {
    var version: Int
    var errores: [ErrorTipico]

    private enum CodingKeys: String, CodingKey { case version, errores }

    /// Patrones compilados por «competencia|generador», en el orden del archivo.
    private let indice: [String: [Patron]]
    private struct Patron: @unchecked Sendable {
        let error: String
        let regex: NSRegularExpression
    }

    init(version: Int = 1, errores: [ErrorTipico] = []) {
        self.version = version
        self.errores = errores
        var indice: [String: [Patron]] = [:]
        for e in errores {
            for d in e.detecta {
                guard let r = try? NSRegularExpression(pattern: d.patron) else { continue }
                indice["\(e.competencia)|\(d.generador)", default: []].append(Patron(error: e.id, regex: r))
            }
        }
        self.indice = indice
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(version: try c.decode(Int.self, forKey: .version), errores: try c.decode([ErrorTipico].self, forKey: .errores))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(errores, forKey: .errores)
    }

    static func == (a: CatalogoErrores, b: CatalogoErrores) -> Bool { a.version == b.version && a.errores == b.errores }

    subscript(id: String) -> ErrorTipico? { errores.first { $0.id == id } }

    /// Errores con patrones inválidos (los detecta el validador).
    var patronesInvalidos: [String] {
        errores.flatMap { e in e.detecta.filter { (try? NSRegularExpression(pattern: $0.patron)) == nil }.map { "\(e.id): \($0.patron)" } }
    }

    /// Id del error que delata un feedback de un generador en una competencia.
    func etiqueta(competencia: String, generador: String, feedback: String) -> String? {
        guard let patrones = indice["\(competencia)|\(generador)"] else { return nil }
        let rango = NSRange(feedback.startIndex..., in: feedback)
        return patrones.first { $0.regex.firstMatch(in: feedback, range: rango) != nil }?.error
    }

    /// Etiqueta los distractores que aún no tienen error (los estáticos pueden traerlo puesto).
    func etiquetar(_ errores: [ErrorHabitual], competencia: String, generador: String) -> [ErrorHabitual] {
        errores.map { e in
            var e = e
            if e.error == nil { e.error = etiqueta(competencia: competencia, generador: generador, feedback: e.feedback) }
            return e
        }
    }
}

// MARK: - Seguimiento de los errores del usuario

/// Suceso del motor de errores: un fallo que delata un error típico o una respuesta a un ítem de
/// su remedio. Se guarda tal cual (solo se añaden sucesos, compatible con CloudKit) y el estado se
/// reconstruye con `EstadoErrores`.
struct EventoError: Codable, Sendable, Equatable, Identifiable {
    enum Tipo: String, Codable, Sendable { case fallo, remedioAcierto, remedioFallo }
    var id = UUID()
    var fecha: Date
    var errorId: String
    var tipo: Tipo
    var itemId: String
}

/// Estado de un error típico para el usuario.
struct SeguimientoError: Sendable, Equatable {
    var errorId: String
    /// Fallos desde la última corrección (o desde siempre).
    var fallos: [Date] = []
    var activo = false
    var activadoEn: Date?
    /// Aciertos seguidos en el remedio desde la activación.
    var aciertosSeguidos = 0
    var corregidoEn: Date?
    /// Veces que se ha corregido (puede reactivarse).
    var correcciones = 0
}

/// Reglas del motor de errores (D-107): un error se activa con 2 apariciones en 7 días y se da por
/// corregido con 3 aciertos seguidos en su remedio. Puro: el estado sale de los sucesos.
struct EstadoErrores: Sendable, Equatable {
    static let aparicionesParaActivar = 2
    static let ventana: TimeInterval = 7 * 24 * 3600
    static let aciertosParaCorregir = 3

    private(set) var seguimientos: [String: SeguimientoError] = [:]

    init(eventos: [EventoError] = []) {
        for e in eventos.sorted(by: { $0.fecha < $1.fecha }) { aplicar(e) }
    }

    /// Aplica un suceso. Devuelve el seguimiento resultante.
    @discardableResult
    mutating func aplicar(_ e: EventoError) -> SeguimientoError {
        var s = seguimientos[e.errorId] ?? SeguimientoError(errorId: e.errorId)
        switch e.tipo {
        case .fallo:
            s.fallos.append(e.fecha)
            if !s.activo {
                let recientes = s.fallos.filter { e.fecha.timeIntervalSince($0) <= Self.ventana }
                if recientes.count >= Self.aparicionesParaActivar {
                    s.activo = true
                    s.activadoEn = e.fecha
                    s.aciertosSeguidos = 0
                }
            } else {
                // Un fallo del mismo error mientras está activo reinicia la cuenta del remedio.
                s.aciertosSeguidos = 0
            }
        case .remedioAcierto:
            guard s.activo else { break }
            s.aciertosSeguidos += 1
            if s.aciertosSeguidos >= Self.aciertosParaCorregir {
                s.activo = false
                s.corregidoEn = e.fecha
                s.correcciones += 1
                s.fallos = []
                s.aciertosSeguidos = 0
            }
        case .remedioFallo:
            if s.activo { s.aciertosSeguidos = 0 }
        }
        seguimientos[e.errorId] = s
        return s
    }

    /// Errores activos, el más reciente primero.
    var activos: [SeguimientoError] {
        seguimientos.values.filter(\.activo).sorted { ($0.activadoEn ?? .distantPast, $0.errorId) > ($1.activadoEn ?? .distantPast, $1.errorId) }
    }

    /// Errores corregidos (y no reactivados), el más reciente primero.
    var corregidos: [SeguimientoError] {
        seguimientos.values.filter { !$0.activo && $0.corregidoEn != nil }
            .sorted { ($0.corregidoEn ?? .distantPast, $0.errorId) > ($1.corregidoEn ?? .distantPast, $1.errorId) }
    }

    func activo(_ errorId: String) -> Bool { seguimientos[errorId]?.activo ?? false }

    /// Errores típicos que delata una respuesta fallida (sin repetir). En los numéricos se compara el
    /// valor (12,50 delata el mismo error que 12,5); en el resto, el id de la respuesta.
    static func errores(de resultado: Resultado, item: Item) -> [String] {
        guard !resultado.correcto else { return [] }
        let fallados = Set(resultado.errores)
        let valores = Set(resultado.errores.compactMap { Racional.interpretar($0)?.valor })
        var vistos = Set<String>()
        return item.erroresHabituales.filter { h in
            if fallados.contains(h.respuesta) { return true }
            guard case .numerico = item.payload, let v = Racional.interpretar(h.respuesta)?.valor else { return false }
            return valores.contains(v)
        }.compactMap(\.error).filter { vistos.insert($0).inserted }
    }
}
