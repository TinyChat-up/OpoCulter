import Foundation

/// Resultado de cerrar una partida de Supervivencia.
struct ResultadoPartida: Sendable, Equatable {
    var partida: PartidaSupervivencia
    /// Mejor partida anterior (global y del mismo modo de área), para la comparación.
    var mejorAnterior: PartidaSupervivencia?
    var mejorAnteriorArea: PartidaSupervivencia?
    var esRecord: Bool
    var esRecordArea: Bool
    var efectoRonda: EfectoRonda?
    var logrosNuevos: [Logro]
}

/// Modos de juego de la Fase 05D sobre el mismo motor: Camino (práctica, prueba de nivel y Reto de
/// bloque), Supervivencia, Rescate por competencia, diagnóstico, Progreso y ajustes.
extension ServicioSesion {
    // MARK: Contenido

    func tieneContenido(_ competencia: String) -> Bool {
        banco.tieneItems(competencia: competencia, peldanoMaximo: configRonda.peldanoMaximoEnRonda)
    }

    // MARK: Camino

    func camino(area: String) throws -> [TramoCamino] {
        let medallas = Set(try repositorio.logros().map(\.logroId))
        return ConstructorCamino(banco: banco, escalera: configAprendizaje.escalera, peldanoMaximoEnRonda: configRonda.peldanoMaximoEnRonda)
            .tramos(area: area, estados: try repositorio.estadosCompetencia(), enCurso: try competenciaEnCurso(area: area), medallas: medallas)
    }

    func estado(competencia: String) throws -> EstadoCompetencia {
        try repositorio.estadosCompetencia()[competencia] ?? EstadoCompetencia(competenciaId: competencia)
    }

    /// Ronda de práctica de una competencia: ítems de su peldaño (los no vistos en 24 h primero) y,
    /// en el peldaño 1, sus tarjetas de teoría antes.
    func prepararPractica(_ id: String, esReciente: (String) -> Bool) throws -> RondaPreparada {
        let peldano = try estado(competencia: id).escalera.peldano
        let candidatos = ConstructorRondas(banco: banco, config: configRonda).candidatos(competencia: id, peldano: peldano).shuffled(using: &rng)
        let ordenados = candidatos.filter { !esReciente($0.id) } + candidatos.filter { esReciente($0.id) }
        // Sin preguntas repetidas en la ronda aunque cambie el id (D-087).
        let items = ordenados.sinPreguntasRepetidas().prefix(configRonda.objetivo).map { ItemRonda(itemId: $0.id, motivo: .practica) }
        let teoria = peldano == 1 ? banco.teoria(competencia: id).map(\.id) : []
        return RondaPreparada(tipo: .competencia(id), items: Array(items), competenciaEnCurso: id, teoriaPrevia: teoria)
    }

    /// Efectos propios de la prueba de nivel y del Reto de bloque al completar la ronda.
    func aplicarModo(_ ronda: RondaPreparada, aciertos: Int?, perfil: inout PerfilJugador, efecto: inout EfectoRonda) throws {
        let config = ConfiguracionCamino.estandar
        switch ronda.tipo {
        case .pruebaNivel(let id):
            guard let aciertos, ronda.items.count == config.itemsPruebaNivel else { return }
            let superada = aciertos >= config.aciertosPruebaNivel
            efecto.pruebaNivelSuperada = superada
            guard superada else { return }
            var estado = try estado(competencia: id)
            if estado.escalera.peldano < config.peldanoPruebaNivel {
                estado.escalera = EstadoEscalera(peldano: config.peldanoPruebaNivel, ventana: [])
            }
            if estado.leitner == nil { estado.leitner = .inicial(hoy: hoy, config: configAprendizaje.leitner) }
            try repositorio.guardar(estado)
            perfil.desbloqueos.append(Desbloqueo(competenciaId: id, fecha: reloj.ahora, aciertos: aciertos, total: ronda.items.count))
            perfil.metricas[.pruebasNivelSuperadas, default: 0] += 1
        case .retoBloque(let bloque):
            guard let aciertos, ronda.items.count == config.itemsReto else { return }
            let superado = aciertos >= config.aciertosReto
            efecto.retoSuperado = superado
            guard superado, let b = banco.catalogo.todosLosBloques.first(where: { $0.id == bloque }) else { return }
            let medalla = MotorLogros.medalla(b)
            let ya = try repositorio.logros().contains { $0.logroId == medalla.id }
            if !ya {
                try repositorio.registrarLogro(LogroObtenido(logroId: medalla.id, fecha: reloj.ahora))
                perfil.metricas[.medallasBloque, default: 0] += 1
                efecto.logrosNuevos.append(medalla)
            }
        default:
            break
        }
    }

    // MARK: Supervivencia

    func siguienteSupervivencia(dificultad: Int, area: String?, usados: Set<String>, huellas: Set<String>? = nil) throws -> Item? {
        let selector = SelectorSupervivencia(banco: banco)
        let debilidades = selector.debilidades(estados: try repositorio.estadosCompetencia(), diagnostico: try repositorio.diagnostico())
        return selector.siguiente(dificultad: dificultad, area: area, debilidades: debilidades, usados: usados, huellasUsadas: huellas, rng: &rng)
    }

    func recordsSupervivencia() throws -> RecordsSupervivencia {
        RecordsSupervivencia(partidas: try repositorio.partidas())
    }

    /// Cierra la partida: la guarda con su historial y, si no está abandonada, calcula récords,
    /// cuenta como ronda (racha y misiones) y concede los logros. Las abandonadas no cuentan para
    /// el récord.
    func cerrarPartida(_ partida: PartidaSupervivencia, abandonada: Bool, ronda: RondaPreparada) throws -> ResultadoPartida {
        var p = partida
        p.fin = reloj.ahora
        p.abandonada = abandonada
        let previas = try repositorio.partidas().filter { $0.id != p.id }
        let antes = RecordsSupervivencia(partidas: previas)
        let mejor = antes.global, mejorArea = antes.porArea[p.area ?? "MIX"]
        let esRecord = !abandonada && p.puntos > 0 && (mejor.map { p.puntos > $0.puntos } ?? false)
        let esRecordArea = !abandonada && p.puntos > 0 && (mejorArea.map { p.puntos > $0.puntos } ?? false)
        try repositorio.guardar(p)
        guard !abandonada else {
            return ResultadoPartida(partida: p, mejorAnterior: mejor, mejorAnteriorArea: mejorArea, esRecord: false, esRecordArea: false,
                                    efectoRonda: nil, logrosNuevos: [])
        }
        var perfil = try repositorio.perfil()
        perfil.metricas[.partidasSupervivencia, default: 0] += 1
        perfil.metricas[.nivelMaximoSupervivencia] = max(perfil.metricas[.nivelMaximoSupervivencia] ?? 0, p.nivelMaximo)
        if esRecord { perfil.metricas[.recordsSupervivencia, default: 0] += 1 }
        try repositorio.guardar(perfil)
        let efecto = try completarRonda(ronda)
        return ResultadoPartida(partida: p, mejorAnterior: mejor, mejorAnteriorArea: mejorArea, esRecord: esRecord, esRecordArea: esRecordArea,
                                efectoRonda: efecto, logrosNuevos: efecto.logrosNuevos)
    }

    // MARK: Diagnóstico

    func nuevaSesionDiagnostico() -> SesionDiagnostico {
        SesionDiagnostico(banco: banco, rng: GeneradorConSemilla(semilla: rng.next()))
    }

    /// Guarda el resultado (los anteriores quedan en el historial) y devuelve el plan.
    func completarDiagnostico(_ sesion: SesionDiagnostico) throws -> (ResultadoDiagnostico, [Logro]) {
        let resultado = sesion.resultado(fecha: reloj.ahora)
        try repositorio.guardar(resultado)
        var perfil = try repositorio.perfil()
        perfil.metricas[.diagnosticosCompletados, default: 0] += 1
        let logros = try comprobarLogros(perfil, fecha: reloj.ahora)
        try repositorio.guardar(perfil)
        return (resultado, logros)
    }

    func plan(_ resultado: ResultadoDiagnostico) -> PlanDiagnostico {
        PlanDiagnostico(resultado: resultado, banco: banco, tieneContenido: tieneContenido)
    }

    // MARK: Rescate

    func gruposRescate() throws -> [GrupoRescate] {
        GrupoRescate.agrupar(try repositorio.colaRescate(), catalogo: banco.catalogo)
    }

    // MARK: Progreso

    func estadisticas(dias: Int = 28) throws -> EstadisticasProgreso {
        EstadisticasProgreso(intentos: try repositorio.intentos(desde: nil), perfil: try repositorio.perfil(),
                             partidas: try repositorio.partidas(), hoy: hoy, calendario: calendario, dias: dias)
    }

    /// Dominio (0…1) de un bloque: peldaño medio de sus competencias con contenido.
    func dominio(bloque: Catalogo.Bloque, estados: [String: EstadoCompetencia]) -> Double? {
        let ids = bloque.competencias.map(\.id).filter(tieneContenido)
        guard !ids.isEmpty else { return nil }
        return ids.map { Double(min((estados[$0]?.escalera.peldano ?? 1) - 1, 4)) / 4 }.reduce(0, +) / Double(ids.count)
    }

    /// Dominio (0…1) de un área con la misma medida que los bloques: peldaño medio de sus
    /// competencias con contenido (0 si no tiene ninguna).
    func dominioArea(_ area: String, estados: [String: EstadoCompetencia]) -> Double {
        let ids = banco.catalogo.todasLasCompetencias.map(\.id).filter { Catalogo.area(de: $0) == area && tieneContenido($0) }
        guard !ids.isEmpty else { return 0 }
        return ids.map { Double(min((estados[$0]?.escalera.peldano ?? 1) - 1, 4)) / 4 }.reduce(0, +) / Double(ids.count)
    }

    /// Catálogo de logros: los del motor y las medallas de los bloques con Reto, con su fecha si se tienen.
    func catalogoLogros() throws -> [(logro: Logro, obtenido: Date?)] {
        let obtenidos = Dictionary(try repositorio.logros().map { ($0.logroId, $0.fecha) }, uniquingKeysWith: { a, _ in a })
        let constructor = ConstructorCamino(banco: banco)
        let medallas = banco.catalogo.todosLosBloques.filter { constructor.retoDisponible($0.id) }.map(MotorLogros.medalla)
        return (motorLogros.logros + medallas).map { ($0, obtenidos[$0.id]) }
    }

    /// Cifra real de preguntas disponibles: solo contenido aprobado (lo que ve la app en Release).
    func preguntasDisponibles() -> RecuentoCatalogo {
        let aprobados = Array(banco.itemsEstaticos.filter { $0.validacion.estado == .aprobado })
        let plantillas = banco.plantillas.filter { $0.validacion.estado == .aprobado }
        let soloAprobado = BancoContenido(catalogo: banco.catalogo, items: aprobados, teoria: banco.teoria,
                                          plantillas: plantillas, recursos: banco.recursos, variantesPorPlantilla: 0)
        return CatalogoPreguntas.recuento(soloAprobado)
    }

    // MARK: Ajustes

    func ajustes() throws -> Ajustes { try repositorio.ajustes() }
    func guardar(_ ajustes: Ajustes) throws { try repositorio.guardar(ajustes) }

    /// Borra todo el progreso (los ajustes se conservan).
    func borrarProgreso() throws { try repositorio.borrarProgreso() }

    var racha: EstadoRacha { (try? repositorio.perfil().racha.vigente(hoy: hoy)) ?? EstadoRacha() }
}
