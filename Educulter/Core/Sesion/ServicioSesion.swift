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
    /// Ronda de un área (`LEN` o `MAT`) con su competencia en curso.
    case area(String)
    /// Practicar una competencia concreta (Camino).
    case competencia(String)
    /// Prueba de nivel: 5 ítems del peldaño 3; con 4 aciertos se superan los peldaños 1–2 (D-070).
    case pruebaNivel(String)
    /// Reto de bloque: 8 ítems sin ayudas de dificultad 4–5; con 6 aciertos, medalla (D-070).
    case retoBloque(String)
    /// Rescate de una sola competencia.
    case rescateCompetencia(String)
    /// Supervivencia (los ítems se piden uno a uno); `area` nil = mixta (D-069).
    case supervivencia(area: String?)
    /// Diagnóstico inicial (adaptativo, ítem a ítem).
    case diagnostico
    /// Sesión diaria mixta (05E parte 2 §3).
    case sesion(duracion: DuracionSesion, foco: FocoSesion)
    /// Rescate de un error típico activo: 3 ítems de su remedio (05E parte 2 §4).
    case rescateError(String)
}

/// Propuesta de ronda por área para el panel protagonista de Hoy.
struct PropuestaRonda: Sendable, Equatable {
    var area: String
    var competencia: Catalogo.Competencia
    /// Mecánica más frecuente de los ítems que tocan ahora (vista previa del panel).
    var mecanica: Mecanica?
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
    /// El fallo activa (o repite) un error típico activo (motor de errores, §4 de la 05E parte 2).
    var errorRepetido: ErrorTipico?
    /// Errores típicos que delata este fallo (activos o no), para el resumen de la sesión.
    var erroresDetectados: [ErrorTipico] = []
}

/// Consecuencias de terminar una ronda.
struct EfectoRonda: Sendable, Equatable {
    var cambiosRacha = EstadoRacha.Cambios()
    var racha = EstadoRacha()
    var misionesCompletadas: [Mision] = []
    var logrosNuevos: [Logro] = []
    /// Prueba de nivel: `true` si se han superado los peldaños 1–2.
    var pruebaNivelSuperada: Bool?
    /// Reto de bloque: `true` si se ha ganado la medalla.
    var retoSuperado: Bool?
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
    /// Una propuesta por área con contenido (Lengua primero).
    var propuestas: [PropuestaRonda] = []
    var avatar: Int?
    /// Racha en riesgo: hay racha, hoy no hay ronda y quedan menos de 4 h (D-054).
    var rachaEnRiesgo = false
    var horasHastaMedianoche = 24
    /// Récord de Supervivencia (puntos) y si hay contenido para jugar.
    var recordSupervivencia: Int?
    var supervivenciaDisponible = false
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
    var rng: GeneradorConSemilla

    init(banco: BancoContenido, repositorio: any RepositorioProgreso, reloj: any Reloj = RelojSistema(),
         calendario: Calendar = .current, rng: GeneradorConSemilla = .aleatorio()) {
        self.banco = banco
        self.repositorio = repositorio
        self.reloj = reloj
        self.calendario = calendario
        self.rng = rng
    }

    var hoy: DiaCivil { DiaCivil(reloj.ahora, calendario: calendario) }


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
            hayContenido: banco.cuentaSinGenerar(peldanoMaximo: configRonda.peldanoMaximoEnRonda) >= configRonda.minimo,
            itemsOrtografia: itemsOrtografia.count,
            propuestas: try propuestas(enCurso: enCurso),
            avatar: perfil.avatar,
            rachaEnRiesgo: ReglasPersonaje.rachaEnRiesgo(perfil.racha.vigente(hoy: hoy), ahora: reloj.ahora, calendario: calendario),
            horasHastaMedianoche: ReglasPersonaje.horasHastaMedianoche(ahora: reloj.ahora, calendario: calendario),
            recordSupervivencia: RecordsSupervivencia(partidas: try repositorio.partidas()).global?.puntos,
            supervivenciaDisponible: !SelectorSupervivencia(banco: banco).bloques(area: nil).isEmpty
        )
    }

    /// Resumen compacto del progreso guardado (peldaño y caja de Leitner por competencia, Rescate,
    /// XP y avatar). Lo usa el test de interfaz de cierre y reapertura (Debug).
    func resumenProgreso() throws -> String {
        let estados = try repositorio.estadosCompetencia().values.sorted { $0.competenciaId < $1.competenciaId }
        let perfil = try repositorio.perfil()
        let competencias = estados.map { "\($0.competenciaId):p\($0.escalera.peldano):c\($0.leitner?.caja ?? 0)" }
        return (competencias + ["rescate:\(try repositorio.colaRescate().cantidad)", "xp:\(perfil.xpTotal)",
                                "avatar:\(perfil.avatar.map(String.init) ?? "-")"]).joined(separator: ";")
    }

    /// Guarda el avatar elegido en el perfil.
    func elegirAvatar(_ id: Int) throws {
        guard Avatar.todos.contains(where: { $0.id == id }) else { return }
        var perfil = try repositorio.perfil()
        perfil.avatar = id
        try repositorio.guardar(perfil)
    }

    /// Competencia en curso de un área: la en curso global si es de esa área; si no, la
    /// primera sin dominar del área por prioridad de bloque y orden del catálogo.
    func competenciaEnCurso(area: String) throws -> String? {
        let estados = try repositorio.estadosCompetencia()
        if let global = try competenciaEnCurso(), Catalogo.area(de: global) == area { return global }
        return competenciasOrdenadas().filter { Catalogo.area(de: $0) == area }.first { valida($0, estados) }
    }

    private func propuestas(enCurso: String?) throws -> [PropuestaRonda] {
        let estados = try repositorio.estadosCompetencia()
        return try ["LEN", "MAT"].compactMap { area -> PropuestaRonda? in
            guard let id = try competenciaEnCurso(area: area),
                  let c = banco.catalogo.todasLasCompetencias.first(where: { $0.id == id }) else { return nil }
            let peldano = estados[id]?.escalera.peldano ?? 1
            let candidatos = ConstructorRondas(banco: banco, config: configRonda).candidatos(competencia: id, peldano: peldano)
            let frecuencias = Dictionary(grouping: candidatos, by: \.mecanica).mapValues(\.count)
            let mecanica = frecuencias.max { ($0.value, $1.key.rawValue) < ($1.value, $0.key.rawValue) }?.key
            return PropuestaRonda(area: area, competencia: c, mecanica: mecanica)
        }
    }

    /// Orden de lo nuevo (D-103): prioridad × debilidad del diagnóstico × preguntas oficiales.
    func competenciasOrdenadas() -> [String] {
        PlanEstudio(banco: banco, diagnostico: try? repositorio.diagnostico()).ordenadas()
    }

    func valida(_ id: String, _ estados: [String: EstadoCompetencia]) -> Bool {
        !(estados[id]?.escalera.dominada(configAprendizaje.escalera) ?? false)
            && banco.tieneItems(competencia: id, peldanoMaximo: configRonda.peldanoMaximoEnRonda)
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
        if let actual = perfil.competenciaEnCurso, valida(actual, estados) { return actual }
        let siguiente = competenciasOrdenadas().first { valida($0, estados) }
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
        case .recomendada, .area:
            // La ronda de un área usa la competencia en curso de esa área; el resto (repasos,
            // Rescate e intercalado) lo compone el motor igual que en la recomendada.
            let enCurso: String?
            if case .area(let area) = tipo { enCurso = try competenciaEnCurso(area: area) } else { enCurso = try competenciaEnCurso() }
            let estados = try repositorio.estadosCompetencia()
            let ronda = ConstructorRondas(banco: banco, config: configRonda).construir(
                estados: estados, rescate: try repositorio.colaRescate(), enCurso: enCurso,
                vistos: vistos, ahora: ahora, calendario: calendario, rng: &rng)
            var items = ronda.items
            // Peldaño 1 (Descubrir): ejemplo resuelto y gemelo (§5).
            if let enCurso, (estados[enCurso]?.escalera.peldano ?? 1) == Peldano.descubre.rawValue {
                items = EjemplosResueltos.aplicar(items, competencia: enCurso, banco: banco, rng: &rng)
            }
            return RondaPreparada(tipo: tipo, items: items, competenciaEnCurso: enCurso, teoriaPrevia: ronda.teoriaPrevia)
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
        case .competencia(let id):
            return try prepararPractica(id, esReciente: esReciente)
        case .pruebaNivel(let id):
            let items = ConstructorCamino(banco: banco).itemsPruebaNivel(id).shuffled(using: &rng).sinPreguntasRepetidas()
                .prefix(ConfiguracionCamino.estandar.itemsPruebaNivel).map { ItemRonda(itemId: $0.id, motivo: .pruebaNivel) }
            return RondaPreparada(tipo: tipo, items: items.count == ConfiguracionCamino.estandar.itemsPruebaNivel ? Array(items) : [],
                                  competenciaEnCurso: id, teoriaPrevia: [])
        case .retoBloque(let bloque):
            let items = ConstructorCamino(banco: banco).itemsReto(bloque, rng: &rng).map { ItemRonda(itemId: $0.id, motivo: .reto) }
            return RondaPreparada(tipo: tipo, items: items, competenciaEnCurso: nil, teoriaPrevia: [])
        case .rescateCompetencia(let id):
            let cola = try repositorio.colaRescate()
            var usados = Set<String>()
            var items: [ItemRonda] = []
            for entrada in cola.entradas where entrada.competencia == id && items.count < Self.maxItemsRescate {
                if let item = cola.itemParaRescatar(entrada, banco: banco, excluir: usados, esReciente: esReciente, rng: &rng) {
                    usados.insert(item.id)
                    items.append(ItemRonda(itemId: item.id, motivo: .rescate))
                }
            }
            return RondaPreparada(tipo: tipo, items: items, competenciaEnCurso: nil, teoriaPrevia: [])
        case .supervivencia(let area):
            let primero = try siguienteSupervivencia(dificultad: ReglasSupervivencia.estandar.dificultadInicial, area: area, usados: [])
            return RondaPreparada(tipo: tipo, items: primero.map { [ItemRonda(itemId: $0.id, motivo: .supervivencia)] } ?? [],
                                  competenciaEnCurso: nil, teoriaPrevia: [])
        case .sesion(let duracion, let foco):
            return try prepararSesion(duracion: duracion, foco: foco)
        case .rescateError(let id):
            return try prepararRescateError(id) ?? RondaPreparada(tipo: tipo, items: [], competenciaEnCurso: nil, teoriaPrevia: [])
        case .diagnostico:
            let sesion = nuevaSesionDiagnostico()
            return RondaPreparada(tipo: tipo, items: sesion.siguienteItem.map { [ItemRonda(itemId: $0.id, motivo: .diagnostico)] } ?? [],
                                  competenciaEnCurso: nil, teoriaPrevia: [])
        }
    }

    // MARK: - Respuestas

    /// Registra una respuesta y actualiza todo el progreso. `combo` incluye esta respuesta.
    @discardableResult
    func registrar(item: Item, resultado: Resultado, usoPista: Bool, combo: Int,
                   motivo: ItemRonda.Motivo?, confianza: Int? = nil, errorRemedio: String? = nil) throws -> EfectoRespuesta {
        let ahora = reloj.ahora
        var efecto = EfectoRespuesta()
        try registrarErrores(item: item, resultado: resultado, errorRemedio: errorRemedio, fecha: ahora, efecto: &efecto)
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

    /// Motor de errores (05E parte 2 §4, D-107): guarda los fallos que delatan un error típico y las
    /// respuestas a su remedio. `errorRepetido` es el error activo que esta respuesta repite.
    private func registrarErrores(item: Item, resultado: Resultado, errorRemedio: String?, fecha: Date,
                                  efecto: inout EfectoRespuesta) throws {
        var eventos: [EventoError] = []
        if let errorRemedio {
            eventos.append(EventoError(fecha: fecha, errorId: errorRemedio, tipo: resultado.correcto ? .remedioAcierto : .remedioFallo, itemId: item.id))
        }
        for id in EstadoErrores.errores(de: resultado, item: item) where id != errorRemedio {
            eventos.append(EventoError(fecha: fecha, errorId: id, tipo: .fallo, itemId: item.id))
        }
        guard !eventos.isEmpty else { return }
        var estado = EstadoErrores(eventos: try repositorio.eventosError())
        for e in eventos {
            try repositorio.registrar(e)
            let s = estado.aplicar(e)
            if e.tipo == .fallo, let error = banco.recursos.errores[e.errorId] { efecto.erroresDetectados.append(error) }
            if e.tipo == .fallo, s.activo, efecto.errorRepetido == nil { efecto.errorRepetido = banco.recursos.errores[e.errorId] }
        }
    }

    /// Estado del motor de errores del usuario.
    func estadoErrores() throws -> EstadoErrores { EstadoErrores(eventos: try repositorio.eventosError()) }

    /// Cierra una ronda terminada: racha, métricas, misiones y logros. `aciertos` decide la prueba
    /// de nivel y el Reto de bloque.
    func completarRonda(_ ronda: RondaPreparada, aciertos: Int? = nil) throws -> EfectoRonda {
        var perfil = try repositorio.perfil()
        try asegurarMisiones(&perfil)
        var efecto = EfectoRonda()
        try aplicarModo(ronda, aciertos: aciertos, perfil: &perfil, efecto: &efecto)
        efecto.cambiosRacha = perfil.racha.registrarRonda(hoy: hoy)
        if case .sesion = ronda.tipo { perfil.registrarSesion(hoy) }
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
        efecto.logrosNuevos += try comprobarLogros(perfil, fecha: reloj.ahora)
        try repositorio.guardar(perfil)
        return efecto
    }

    // MARK: - Auxiliares

    func asegurarMisiones(_ perfil: inout PerfilJugador) throws {
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

    func comprobarLogros(_ perfil: PerfilJugador, fecha: Date) throws -> [Logro] {
        let obtenidos = Set(try repositorio.logros().map(\.logroId))
        let nuevos = motorLogros.nuevos(metricas: perfil.metricas, obtenidos: obtenidos)
        for logro in nuevos { try repositorio.registrarLogro(LogroObtenido(logroId: logro.id, fecha: fecha)) }
        return nuevos
    }
}
