import Foundation

/// Tipos de ronda que se pueden lanzar desde la interfaz.
enum TipoRonda: Sendable, Equatable {
    /// La ronda que compone el motor (repasos, Rescate, competencia en curso, intercalado).
    case recomendada
    /// Solo ítems de la cola de Rescate.
    case rescate
    /// 5 ítems de Ortografía y tildes.
    case ortografiaExpres
    /// Ítems concretos, en orden (revisión de contenido y demostraciones).
    case items([String])
}

struct RondaPreparada: Sendable, Equatable {
    var tipo: TipoRonda
    var items: [ItemRonda]
    var competenciaEnCurso: String?
    var teoriaPrevia: [String]
}

/// Consecuencias de responder un ítem.
struct EfectoRespuesta: Sendable, Equatable {
    var xp = 0
    var subioPeldano = false
    var peldanoNuevo: Int?
    var acabaDeDominarse = false
    var rescatado = false
    var misionesCompletadas: [Mision] = []
    var logrosNuevos: [Logro] = []
}

/// Consecuencias de terminar una ronda.
struct EfectoRonda: Sendable, Equatable {
    var cambiosRacha = EstadoRacha.Cambios()
    var racha = EstadoRacha()
    var misionesCompletadas: [Mision] = []
    var logrosNuevos: [Logro] = []
}

/// Lo que muestra la pestaña Hoy.
struct EstadoHoy: Sendable, Equatable {
    var racha: EstadoRacha
    var xpTotal: Int
    var nivel: Int
    var xpEnNivel: Int
    var xpParaSiguiente: Int
    var fraccionNivel: Double
    var misiones: [Mision]
    var rescatesPendientes: Int
    var competenciaEnCurso: Catalogo.Competencia?
    var hayContenido: Bool
    var itemsOrtografia: Int
}

/// Orquesta el núcleo para una sesión de juego: compone rondas, registra respuestas y
/// actualiza escalera, Leitner, Rescate, XP, racha, misiones y logros en el repositorio.
@MainActor
final class ServicioSesion {
    static let bloqueOrtografia = "LEN.ORT"
    static let itemsOrtografiaExpres = 5
    static let maxItemsRescate = 8

    let banco: BancoContenido
    let repositorio: any RepositorioProgreso
    let reloj: any Reloj
    let calendario: Calendar
    var configAprendizaje = ConfiguracionAprendizaje.estandar
    var configRonda = ConfiguracionRonda.estandar
    var curva = CurvaNiveles.estandar
    var motorLogros = MotorLogros()
    private var rng: GeneradorConSemilla

    init(banco: BancoContenido, repositorio: any RepositorioProgreso, reloj: any Reloj = RelojSistema(),
         calendario: Calendar = .current, rng: GeneradorConSemilla = .aleatorio()) {
        self.banco = banco
        self.repositorio = repositorio
        self.reloj = reloj
        self.calendario = calendario
        self.rng = rng
    }

    var hoy: DiaCivil { DiaCivil(reloj.ahora, calendario: calendario) }

    /// Ítems utilizables en rondas (peldaños 1–4).
    private var itemsDeRonda: [Item] { banco.items.filter { $0.peldano <= configRonda.peldanoMaximoEnRonda } }

    // MARK: - Hoy

    func estadoHoy() throws -> EstadoHoy {
        var perfil = try repositorio.perfil()
        try asegurarMisiones(&perfil)
        let enCurso = try competenciaEnCurso(perfil: &perfil)
        try repositorio.guardar(perfil)
        let progreso = curva.progreso(xp: perfil.xpTotal)
        return EstadoHoy(
            racha: perfil.racha.vigente(hoy: hoy),
            xpTotal: perfil.xpTotal, nivel: progreso.nivel, xpEnNivel: progreso.xpEnNivel,
            xpParaSiguiente: progreso.xpParaSiguiente, fraccionNivel: progreso.fraccion,
            misiones: perfil.misiones,
            rescatesPendientes: try repositorio.colaRescate().cantidad,
            competenciaEnCurso: enCurso.flatMap { id in banco.catalogo.todasLasCompetencias.first { $0.id == id } },
            hayContenido: itemsDeRonda.count >= configRonda.minimo,
            itemsOrtografia: itemsOrtografia.count
        )
    }

    /// Competencia en curso: se mantiene la guardada mientras no esté dominada y tenga
    /// ítems; si no, la siguiente sin dominar por prioridad de bloque y orden del catálogo.
    func competenciaEnCurso() throws -> String? {
        var perfil = try repositorio.perfil()
        let id = try competenciaEnCurso(perfil: &perfil)
        try repositorio.guardar(perfil)
        return id
    }

    private func competenciaEnCurso(perfil: inout PerfilJugador) throws -> String? {
        let estados = try repositorio.estadosCompetencia()
        func valida(_ id: String) -> Bool {
            !(estados[id]?.escalera.dominada(configAprendizaje.escalera) ?? false)
                && banco.items(competencia: id).contains { $0.peldano <= configRonda.peldanoMaximoEnRonda }
        }
        if let actual = perfil.competenciaEnCurso, valida(actual) { return actual }
        let bloques = banco.catalogo.todosLosBloques.enumerated().sorted { ($1.element.prioridad, $0.offset) < ($0.element.prioridad, $1.offset) }
        let siguiente = bloques.flatMap { $0.element.competencias.sorted { $0.orden < $1.orden } }.map(\.id).first(where: valida)
        perfil.competenciaEnCurso = siguiente
        return siguiente
    }

    private var itemsOrtografia: [Item] {
        banco.items(bloque: Self.bloqueOrtografia).filter { $0.peldano <= configRonda.peldanoMaximoEnRonda }
    }

    // MARK: - Rondas

    func prepararRonda(_ tipo: TipoRonda) throws -> RondaPreparada {
        let ahora = reloj.ahora
        let vistos = try repositorio.vistos(desde: ahora.addingTimeInterval(-configRonda.segundosSinRepetir))
        let esReciente: (String) -> Bool = { vistos[$0] != nil }
        switch tipo {
        case .recomendada:
            let enCurso = try competenciaEnCurso()
            let ronda = ConstructorRondas(banco: banco, config: configRonda).construir(
                estados: try repositorio.estadosCompetencia(), rescate: try repositorio.colaRescate(), enCurso: enCurso,
                vistos: vistos, ahora: ahora, calendario: calendario, rng: &rng)
            return RondaPreparada(tipo: tipo, items: ronda.items, competenciaEnCurso: enCurso, teoriaPrevia: ronda.teoriaPrevia)
        case .rescate:
            let cola = try repositorio.colaRescate()
            var usados = Set<String>()
            var items: [ItemRonda] = []
            for entrada in cola.entradas where items.count < Self.maxItemsRescate {
                if let item = cola.itemParaRescatar(entrada, banco: banco, excluir: usados, esReciente: esReciente, rng: &rng) {
                    usados.insert(item.id)
                    items.append(ItemRonda(itemId: item.id, motivo: .rescate))
                }
            }
            return RondaPreparada(tipo: tipo, items: items, competenciaEnCurso: nil, teoriaPrevia: [])
        case .ortografiaExpres:
            let todos = itemsOrtografia.shuffled(using: &rng)
            let ordenados = todos.filter { !esReciente($0.id) } + todos.filter { esReciente($0.id) }
            let items = ordenados.prefix(Self.itemsOrtografiaExpres).map { ItemRonda(itemId: $0.id, motivo: .relleno) }
            return RondaPreparada(tipo: tipo, items: Array(items), competenciaEnCurso: nil, teoriaPrevia: [])
        case .items(let ids):
            let items = ids.filter { banco.item(id: $0) != nil }.map { ItemRonda(itemId: $0, motivo: .relleno) }
            return RondaPreparada(tipo: tipo, items: items, competenciaEnCurso: nil, teoriaPrevia: [])
        }
    }

    // MARK: - Respuestas

    /// Registra una respuesta y actualiza todo el progreso. `combo` incluye esta respuesta.
    @discardableResult
    func registrar(item: Item, resultado: Resultado, usoPista: Bool, combo: Int,
                   motivo: ItemRonda.Motivo?, confianza: Int? = nil) throws -> EfectoRespuesta {
        let ahora = reloj.ahora
        var efecto = EfectoRespuesta()
        var perfil = try repositorio.perfil()
        try asegurarMisiones(&perfil)

        // Escalera y Leitner.
        var estado = try repositorio.estadosCompetencia()[item.competencia] ?? EstadoCompetencia(competenciaId: item.competencia)
        let cambios = estado.registrar(correcto: resultado.correcto, peldanoDelItem: item.peldano, hoy: hoy, config: configAprendizaje)
        try repositorio.guardar(estado)
        efecto.subioPeldano = cambios.subioPeldano
        efecto.peldanoNuevo = cambios.subioPeldano ? estado.escalera.peldano : nil
        efecto.acabaDeDominarse = cambios.acabaDeDominarse

        // Rescate.
        var cola = try repositorio.colaRescate()
        if resultado.correcto {
            efecto.rescatado = cola.registrarAcierto(item, banco: banco) != nil
        } else {
            cola.registrarFallo(item, fecha: ahora)
        }
        try repositorio.guardar(cola)

        // XP y métricas.
        efecto.xp = CalculadoraXP.xp(correcto: resultado.correcto, usoPista: usoPista, peldano: item.peldano,
                                     combo: combo, esRescate: efecto.rescatado)
        perfil.xpTotal += efecto.xp
        if resultado.correcto { perfil.metricas[.aciertosTotales, default: 0] += 1 }
        if efecto.rescatado { perfil.metricas[.rescates, default: 0] += 1 }
        if cambios.acabaDeDominarse { perfil.metricas[.competenciasDominadas, default: 0] += 1 }
        if item.mecanica == .segmentar, resultado.correcto, resultado.fraccionCorrecta == 1, !usoPista {
            perfil.metricas[.sintaxisPerfectas, default: 0] += 1
        }

        // Misiones.
        var eventos: [EventoMision] = [.xp(efecto.xp), .combo(combo)]
        if resultado.correcto, !usoPista { eventos.append(.aciertoSinPista) }
        if efecto.rescatado { eventos.append(.rescate) }
        if cambios.repasoAplicado { eventos.append(.repaso) }
        for evento in eventos { efecto.misionesCompletadas += GeneradorMisiones.registrar(evento, en: &perfil.misiones) }

        efecto.logrosNuevos = try comprobarLogros(perfil, fecha: ahora)
        try repositorio.guardar(perfil)
        try repositorio.registrarIntento(Intento(
            fecha: ahora, itemId: item.id, competenciaId: item.competencia, peldano: item.peldano,
            correcto: resultado.correcto, fraccionCorrecta: resultado.fraccionCorrecta, usoPista: usoPista,
            confianza: confianza, xp: efecto.xp, motivo: motivo))
        return efecto
    }

    /// Cierra una ronda terminada: racha, métricas, misiones y logros.
    func completarRonda(_ ronda: RondaPreparada) throws -> EfectoRonda {
        var perfil = try repositorio.perfil()
        try asegurarMisiones(&perfil)
        var efecto = EfectoRonda()
        efecto.cambiosRacha = perfil.racha.registrarRonda(hoy: hoy)
        efecto.racha = perfil.racha
        perfil.metricas[.rondasCompletadas, default: 0] += 1
        perfil.metricas[.rachaRecord] = max(perfil.metricas[.rachaRecord] ?? 0, perfil.racha.record)

        let area: String?
        switch ronda.tipo {
        case .ortografiaExpres:
            area = "LEN"
            efecto.misionesCompletadas += GeneradorMisiones.registrar(.ortografiaExpres, en: &perfil.misiones)
        default:
            let competencias = ronda.items.compactMap { banco.item(id: $0.itemId)?.competencia }
            area = (ronda.competenciaEnCurso ?? competencias.first).map(Catalogo.area(de:))
        }
        efecto.misionesCompletadas += GeneradorMisiones.registrar(.rondaCompletada(area: area), en: &perfil.misiones)
        efecto.logrosNuevos = try comprobarLogros(perfil, fecha: reloj.ahora)
        try repositorio.guardar(perfil)
        return efecto
    }

    // MARK: - Auxiliares

    private func asegurarMisiones(_ perfil: inout PerfilJugador) throws {
        guard perfil.diaMisiones != hoy else { return }
        let estados = try repositorio.estadosCompetencia()
        perfil.misiones = GeneradorMisiones.generar(dia: hoy, contexto: ContextoMisiones(
            rescatesPendientes: try repositorio.colaRescate().cantidad,
            repasosVencidos: estados.values.filter { $0.vencida(hoy: hoy) }.count,
            dominioLengua: dominio(area: "LEN", estados: estados),
            dominioMatematicas: dominio(area: "MAT", estados: estados)), rng: &rng)
        perfil.diaMisiones = hoy
    }

    /// Proporción de competencias con contenido que están dominadas en un área.
    func dominio(area: String, estados: [String: EstadoCompetencia]) -> Double {
        let ids = banco.catalogo.todasLasCompetencias.map(\.id)
            .filter { Catalogo.area(de: $0) == area && !banco.items(competencia: $0).isEmpty }
        guard !ids.isEmpty else { return 0 }
        let dominadas = ids.filter { estados[$0]?.escalera.dominada(configAprendizaje.escalera) ?? false }.count
        return Double(dominadas) / Double(ids.count)
    }

    private func comprobarLogros(_ perfil: PerfilJugador, fecha: Date) throws -> [Logro] {
        let obtenidos = Set(try repositorio.logros().map(\.logroId))
        let nuevos = motorLogros.nuevos(metricas: perfil.metricas, obtenidos: obtenidos)
        for logro in nuevos { try repositorio.registrarLogro(LogroObtenido(logroId: logro.id, fecha: fecha)) }
        return nuevos
    }
}
