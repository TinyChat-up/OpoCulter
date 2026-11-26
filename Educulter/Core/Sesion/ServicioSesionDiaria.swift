import Foundation

/// Sesión diaria mixta, meta semanal, modo descanso y motor de errores (05E parte 2 §3–§4).
extension ServicioSesion {
    // MARK: - Sesión diaria

    /// Remedios de los errores activos, el más reciente primero, con la dificultad un punto por
    /// debajo de la del último fallo (mínimo 1).
    func remediosPendientes() throws -> [RemedioPendiente] {
        let eventos = try repositorio.eventosError()
        let estado = EstadoErrores(eventos: eventos)
        return estado.activos.compactMap { s -> RemedioPendiente? in
            guard let error = banco.recursos.errores[s.errorId] else { return nil }
            let ultimo = eventos.last { $0.errorId == s.errorId && $0.tipo == .fallo }
            let dificultad = ultimo.flatMap { banco.item(id: $0.itemId)?.dificultad } ?? error.remedio.dificultad
            return RemedioPendiente(error: error, dificultad: max(1, dificultad - 1))
        }
    }

    /// Competencias para lo nuevo: la en curso primero y después el plan (D-103) sin dominar y con
    /// contenido; en Mixto, áreas alternadas.
    func planSesion(foco: FocoSesion) throws -> [String] {
        let estados = try repositorio.estadosCompetencia()
        let plan = PlanEstudio(banco: banco, diagnostico: try repositorio.diagnostico())
        var ordenadas = plan.ordenadas(area: foco.area).filter { valida($0, estados) }
        if foco == .mixto { ordenadas = plan.mixto(ordenadas) }
        let enCurso: String?
        if let area = foco.area { enCurso = try competenciaEnCurso(area: area) } else { enCurso = try competenciaEnCurso() }
        if let enCurso, let i = ordenadas.firstIndex(of: enCurso) {
            ordenadas.remove(at: i)
            ordenadas.insert(enCurso, at: 0)
        }
        return ordenadas
    }

    /// Semilla de la sesión: el día y las respuestas de hoy (tras una sesión, «5 minutos más» da otra).
    func semillaSesion() throws -> UInt64 {
        let respuestas = try repositorio.intentos(desde: hoy.fecha(calendario: calendario)).count
        return UInt64(hoy.clave) &* 1_000_003 &+ UInt64(respuestas)
    }

    /// Sesión diaria. El diagnóstico se ofrece en la bienvenida (con «Saltar») y en Ajustes; la sesión
    /// solo lo lanza si no hay nada que componer (sin repasos, remedios ni plan con contenido). Sin
    /// diagnóstico, el plan usa la debilidad por defecto (D-103), así que «Saltar» se respeta (D-110).
    func prepararSesion(duracion: DuracionSesion, foco: FocoSesion) throws -> RondaPreparada {
        let ahora = reloj.ahora
        let n = ConstructorSesion.numeroItems(duracion, intentos: try repositorio.intentos(desde: ahora.addingTimeInterval(-30 * 24 * 3600)))
        let sesion = ConstructorSesion(banco: banco, config: configRonda).construir(
            n: n, foco: foco, estados: try repositorio.estadosCompetencia(), remedios: try remediosPendientes(),
            plan: try planSesion(foco: foco), vistos: try repositorio.vistos(desde: ahora.addingTimeInterval(-configRonda.segundosSinRepetir)),
            ahora: ahora, calendario: calendario, semilla: try semillaSesion())
        if sesion.requiereDiagnostico { return try prepararRonda(.diagnostico) }
        return RondaPreparada(tipo: .sesion(duracion: duracion, foco: foco), items: sesion.items,
                              competenciaEnCurso: sesion.competenciaEnCurso, teoriaPrevia: sesion.teoriaPrevia)
    }

    /// Ítems aproximados de una sesión de esa duración (para el texto «≈ 10 min · 15 preguntas»).
    func itemsSesion(_ duracion: DuracionSesion) throws -> Int {
        ConstructorSesion.numeroItems(duracion, intentos: try repositorio.intentos(desde: reloj.ahora.addingTimeInterval(-30 * 24 * 3600)))
    }

    // MARK: - Meta semanal y modo descanso

    func metaSemanal() throws -> MetaSemanal {
        let perfil = try repositorio.perfil()
        return MetaSemanal(meta: try repositorio.ajustes().metaSemanal, hoy: hoy, diasSesion: Set(perfil.diasSesion),
                           descanso: ModoDescanso.dias(perfil.racha.descanso, hasta: hoy.sumando(dias: 6)), calendario: calendario)
    }

    func descansoActivo() throws -> Bool { ModoDescanso.activo(try repositorio.perfil().racha.descanso, hoy: hoy) }

    func diasDescansoDisponibles() throws -> Int { ModoDescanso.disponibles(try repositorio.perfil().racha.descanso, hoy: hoy) }

    /// Activa o desactiva el modo descanso. Devuelve `false` si no quedan días este mes.
    @discardableResult
    func cambiarDescanso(_ activo: Bool) throws -> Bool {
        var perfil = try repositorio.perfil()
        let ok: Bool
        if activo { ok = ModoDescanso.activar(&perfil.racha.descanso, hoy: hoy) } else { ModoDescanso.desactivar(&perfil.racha.descanso, hoy: hoy); ok = true }
        try repositorio.guardar(perfil)
        return ok
    }

    /// Hoy ya hay una sesión diaria completada (el recordatorio no se envía).
    func sesionCompletadaHoy() throws -> Bool { try repositorio.perfil().diasSesion.contains(hoy) }

    // MARK: - Errores

    /// Error activo o corregido para la interfaz.
    struct ErrorSeguido: Sendable, Equatable, Identifiable {
        var error: ErrorTipico
        var apariciones: Int
        var ultimoFallo: Date?
        var activo: Bool
        var aciertosSeguidos: Int
        var corregidoEn: Date?
        var id: String { error.id }
    }

    /// Errores activos y corregidos en el último mes (sección de Progreso).
    func erroresSeguidos() throws -> (activos: [ErrorSeguido], corregidos: [ErrorSeguido]) {
        let eventos = try repositorio.eventosError()
        let estado = EstadoErrores(eventos: eventos)
        func valor(_ s: SeguimientoError) -> ErrorSeguido? {
            guard let e = banco.recursos.errores[s.errorId] else { return nil }
            let fallos = eventos.filter { $0.errorId == s.errorId && $0.tipo == .fallo }
            return ErrorSeguido(error: e, apariciones: s.activo ? s.fallos.count : fallos.count, ultimoFallo: fallos.last?.fecha,
                                activo: s.activo, aciertosSeguidos: s.aciertosSeguidos, corregidoEn: s.corregidoEn)
        }
        let haceUnMes = reloj.ahora.addingTimeInterval(-30 * 24 * 3600)
        return (estado.activos.compactMap(valor), estado.corregidos.filter { ($0.corregidoEn ?? .distantPast) >= haceUnMes }.compactMap(valor))
    }

    /// Ronda de Rescate de un error activo: 3 ítems de su remedio.
    func prepararRescateError(_ errorId: String) throws -> RondaPreparada? {
        guard let r = try remediosPendientes().first(where: { $0.error.id == errorId }), let p = banco.plantilla(id: r.error.remedio.plantilla) else { return nil }
        let variantes = banco.variantes(de: MotorGeneradores.ajustada(p, dificultad: r.dificultad)).shuffled(using: &rng).sinPreguntasRepetidas()
        let items = variantes.prefix(ConstructorSesion.tamanoBloque).map { ItemRonda(itemId: $0.id, motivo: .remedio, errorId: errorId) }
        return items.isEmpty ? nil : RondaPreparada(tipo: .rescateError(errorId), items: Array(items), competenciaEnCurso: nil, teoriaPrevia: [])
    }

    /// Día en que vuelve a trabajarse un error detectado en la sesión: mañana (la siguiente sesión).
    func diaVuelta(_ error: ErrorTipico) -> DiaCivil { hoy.sumando(dias: 1) }

    /// Errores detectados en una sesión, sin repetir, con si ya están activos (su remedio entra en la
    /// próxima sesión) y el día en que vuelven.
    func erroresDetectados(_ errores: [ErrorTipico]) throws -> [ErrorDetectado] {
        let activos = Set(try estadoErrores().activos.map(\.errorId))
        var vistos = Set<String>()
        return errores.filter { vistos.insert($0.id).inserted }.map {
            ErrorDetectado(error: $0, activo: activos.contains($0.id), vuelve: activos.contains($0.id) ? diaVuelta($0) : nil)
        }
    }
}

/// Error detectado en una sesión (resumen, §3.4).
struct ErrorDetectado: Sendable, Equatable, Identifiable {
    var error: ErrorTipico
    /// Activo (2 apariciones en 7 días): su remedio entra en la próxima sesión.
    var activo: Bool
    /// Día en que vuelve (solo si está activo).
    var vuelve: DiaCivil?
    var id: String { error.id }
}
