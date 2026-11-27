import Foundation
import Observation

/// Estado y lógica de una ronda en pantalla. Toda la lógica de aprendizaje y progreso
/// vive en el núcleo (`ServicioSesion`); este modelo solo gestiona la secuencia de la ronda.
@MainActor
@Observable
final class RondaViewModel: Identifiable {
    enum Fase: Equatable {
        /// Tarjetas de teoría previas (competencia en el peldaño 1).
        case teoria
        case respondiendo
        case corregido
        case resumen
        /// No hay ítems para esta ronda.
        case vacia
    }

    /// Resumen que se muestra al terminar.
    struct Resumen: Equatable {
        var aciertos: Int
        var total: Int
        var xp: Int
        var comboMaximo: Int
        var subidas: [String]
        var racha: EstadoRacha
        var cambiosRacha: EstadoRacha.Cambios
        var logros: [Logro]
        /// Área con más ítems en la ronda (`LEN` o `MAT`): da color a "Otra ronda".
        var areaPredominante: String = "LEN"
        /// Peldaño al que sube cada competencia de `subidas`.
        var peldanosNuevos: [String: Int] = [:]
        /// Errores típicos detectados en la ronda (§3.4).
        var errores: [ErrorDetectado] = []
        /// Sesión diaria: el resumen ofrece «5 minutos más».
        var esSesion = false
    }

    let id = UUID()
    let servicio: ServicioSesion
    /// Semilla de la ronda para el orden de presentación de las opciones (05G §1.1).
    let semillaOrden: UInt64
    private(set) var ronda: RondaPreparada
    private(set) var items: [Item] = []
    private(set) var indice = 0
    private(set) var fase: Fase = .vacia

    /// Borrador de la respuesta que va construyendo la mecánica.
    var respuesta: Respuesta? {
        didSet {
            // Al elegir otra opción o fragmento en el reintento, la marca del error anterior se quita.
            if oldValue != respuesta, let m = itemActual?.mecanica, m == .evidencia || m == .eleccion { marcasReintento = [] }
        }
    }
    /// Contrato de intento de los juegos (05G §2): primer intento, pista y reintento.
    private(set) var flujo: FlujoIntento?
    /// Errores del primer intento, marcados en la pieza durante el reintento.
    private(set) var marcasReintento: [String] = []
    private var primerResultado: Resultado?
    private var primeraRespuesta = ""
    private var inicioItem = Date()
    private(set) var resultado: Resultado?
    private(set) var efecto: EfectoRespuesta?
    private(set) var usoPista = false
    private(set) var pistasVisibles = 0
    /// Ejemplo resuelto (§5): pasos ya mostrados (el último lo completa el usuario).
    private(set) var pasosVisibles = 0

    private(set) var combo = ContadorCombo()
    /// Aumenta en cada hito de combo (×3, ×5, ×10 y cada 10 más): dispara la animación y la
    /// vibración de impacto.
    private(set) var hitosCombo = 0
    private(set) var aciertos = 0
    private(set) var respondidos = 0
    private(set) var xpRonda = 0
    private(set) var subidas: [String] = []
    private(set) var peldanosNuevos: [String: Int] = [:]
    private(set) var erroresDetectados: [ErrorTipico] = []
    private(set) var logros: [Logro] = []
    private(set) var resumen: Resumen?
    private(set) var mensajeError: String?

    /// Tarjeta abierta con "Ver regla".
    var teoriaAbierta: TarjetaTeoria?

    // MARK: Modos con ítems dinámicos (Fase 05D)

    /// Supervivencia: estado de la partida y su registro (los ítems se piden uno a uno).
    private(set) var supervivencia: EstadoSupervivencia?
    private(set) var partida: PartidaSupervivencia?
    private(set) var resultadoPartida: ResultadoPartida?
    /// Puntos ganados con la última respuesta (para el "+N" en vivo).
    private(set) var puntosUltimo = 0
    /// Diagnóstico: sesión adaptativa y plan resultante.
    private(set) var sesionDiagnostico: SesionDiagnostico?
    private(set) var plan: PlanDiagnostico?
    /// Resultado de la prueba de nivel o del Reto de bloque (`nil` en otras rondas).
    private(set) var efectoFinal: EfectoRonda?
    /// Tras la primera ronda completada se pregunta (una vez) por el recordatorio diario.
    var preguntarRecordatorio = false
    /// Sonidos (los inyecta la vista; se respetan los ajustes).
    var sonido: (any ServicioSonido)?

    var esSupervivencia: Bool { if case .supervivencia = ronda.tipo { true } else { false } }
    var esDiagnostico: Bool { if case .diagnostico = ronda.tipo { true } else { false } }

    /// Diagnóstico: total estimado (respondidos + pendientes), para "x de N".
    var totalDiagnostico: Int {
        let enCola = sesionDiagnostico?.pendientes.filter { id in !items.contains { $0.id == id } }.count ?? 0
        return items.count + enCola
    }

    init(servicio: ServicioSesion, tipo: TipoRonda) {
        self.servicio = servicio
        self.semillaOrden = servicio.rng.next()
        self.ronda = RondaPreparada(tipo: tipo, items: [], competenciaEnCurso: nil, teoriaPrevia: [])
        preparar(tipo)
    }

    // MARK: - Consultas

    var banco: BancoContenido { servicio.banco }
    var itemActual: Item? { items.indices.contains(indice) ? items[indice] : nil }
    var total: Int { items.count }

    var tarjetasPrevias: [TarjetaTeoria] {
        ronda.teoriaPrevia.compactMap { id in banco.teoria.first { $0.id == id } }
    }

    var puedeComprobar: Bool {
        guard fase == .respondiendo, ejemploListo, let item = itemActual, let respuesta else { return false }
        return respuesta.esCompleta(para: item.payload)
    }

    // MARK: Ejemplo resuelto y retirada de ayudas (§5)

    /// El ítem en curso es un ejemplo resuelto (peldaño 1): los pasos aparecen uno a uno.
    var esEjemplo: Bool {
        guard let item = itemActual, ronda.items.indices.contains(indice) else { return false }
        return ronda.items[indice].ejemplo && item.pasos.count >= 2
    }

    /// Pasos que se enseñan en el ejemplo: todos menos el último, que completa el usuario.
    var pasosEjemplo: [PasoResuelto] { esEjemplo ? Array(itemActual!.pasos.dropLast()) : [] }

    /// Ya se han visto todos los pasos del ejemplo: toca completar el último.
    var ejemploListo: Bool { !esEjemplo || pasosVisibles >= pasosEjemplo.count }

    func siguientePaso() {
        guard esEjemplo, pasosVisibles < pasosEjemplo.count else { return }
        pasosVisibles += 1
    }

    /// Pistas del ítem: en el peldaño 2 (Practicar), si tiene pasos, solo el primero; en el 1, las de
    /// siempre (D-033); desde el 3, ninguna.
    func pistas(de item: Item) -> [String] {
        guard item.peldano <= Peldano.practica.rawValue, !sinAyudas else { return [] }
        if item.peldano == Peldano.practica.rawValue, let p = item.pasos.first {
            return ["Primer paso: \(p.frase) → \(p.resultado)"]
        }
        return item.pistas
    }

    /// Pasos que se ven en la explicación tras un fallo (desde el peldaño 3 es el único sitio donde se ven).
    var pasosTrasFallo: [PasoResuelto] {
        guard let resultado, !resultado.correcto, let item = itemActual else { return [] }
        return item.pasos
    }

    /// Las pistas solo existen en los peldaños 1 y 2 (D-033).
    var puedePedirPista: Bool {
        guard fase == .respondiendo, let item = itemActual, !esEjemplo else { return false }
        return pistasVisibles < pistas(de: item).count
    }

    /// Variante sin ayudas (05G §2): sin pistas ni cortes candidatos.
    var sinAyudas: Bool { ronda.items.indices.contains(indice) && ronda.items[indice].sinAyudas }

    /// Pista de razonamiento del reintento (no da la solución).
    var pistaReintento: String? { if case .reintento(let p) = flujo?.fase { p } else { nil } }

    /// Título de la hoja de feedback en los juegos (05G §2).
    var tituloFeedback: String? {
        switch flujo?.resultado {
        case .enProgreso: "Correcto con ayuda"
        case .autoevaluacion: "Autoevaluación hecha"
        default: nil
        }
    }

    var pistasMostradas: [String] {
        itemActual.map { Array(pistas(de: $0).prefix(pistasVisibles)) } ?? []
    }

    /// Personaje del feedback (D-109): solo Mimo, con ánimo, ante un error repetido. Los personajes
    /// aparecen únicamente en la bienvenida, el resumen y ese ánimo.
    var aparicionFeedback: AparicionPersonaje? {
        guard let resultado, !resultado.correcto, efecto?.errorRepetido != nil else { return nil }
        return ReglasPersonaje.aparicion(para: .errorRepetido)
    }

    var feedbackEspecifico: [String] {
        guard let resultado, let item = itemActual else { return [] }
        return Evaluador.feedback(para: resultado, item: item)
    }

    var solucion: String? {
        itemActual.map { DescripcionSolucion.texto($0.payload) }
    }

    /// Texto base del ítem en curso (comprensión, D-085) y año de su obra si es literario.
    var textoBase: TextoBase? { itemActual.flatMap { banco.texto(de: $0) } }
    var anioTextoBase: Int? { textoBase.flatMap { banco.anio(de: $0) } }

    var teoriaDelItem: TarjetaTeoria? {
        itemActual.flatMap { banco.teoria(competencia: $0.competencia).first }
    }

    static func esHitoCombo(_ combo: Int) -> Bool {
        combo == 3 || combo == 5 || (combo >= 10 && combo % 10 == 0)
    }

    /// Área con más ítems en la ronda (en empate, Lengua).
    var areaPredominante: String {
        let mat = items.filter { Catalogo.area(de: $0.competencia) == "MAT" }.count
        return mat > items.count - mat ? "MAT" : "LEN"
    }

    func nombreCompetencia(_ id: String) -> String {
        banco.catalogo.todasLasCompetencias.first { $0.id == id }?.nombre ?? id
    }

    // MARK: - Acciones

    func empezarTrasTeoria() {
        guard fase == .teoria else { return }
        fase = items.isEmpty ? .vacia : .respondiendo
    }

    func pedirPista() {
        guard puedePedirPista else { return }
        pistasVisibles += 1
        usoPista = true
        flujo?.ayudas.insert(.pista)
    }

    func comprobar() {
        guard puedeComprobar, let item = itemActual, let respuesta else { return }
        var r = Evaluador.evaluar(respuesta, para: item)
        // Juegos (05G §2): si falla el primer intento, pista y reintento editando la misma respuesta.
        if var f = flujo {
            let primero = f.fase == .primerIntento
            let pista = Evaluador.feedback(para: r, item: item).first ?? item.pistas.first ?? "Revisa tu respuesta paso a paso."
            // Rayos X (05H): una capa fallada y repetida cuenta como primer intento con pista.
            if primero, case .rayosX(let rx) = respuesta, !rx.fallos.isEmpty { f.ayudas.insert(.pista) }
            f.comprobar(correcto: r.correcto, pista: pista)
            flujo = f
            if primero {
                primerResultado = r
                primeraRespuesta = respuesta.registro
            }
            if !f.terminado {
                marcasReintento = r.errores
                sonido?.fallo()
                return
            }
            if f.resultado == .enProgreso { usoPista = true }
            if f.resultado == .fallo, let p = primerResultado { r.errores = Array(Set(r.errores).union(p.errores)).sorted() }
        }
        marcasReintento = []
        let comboActual = combo.registrar(correcto: r.correcto)
        resultado = r
        respondidos += 1
        if r.correcto {
            aciertos += 1
            if Self.esHitoCombo(comboActual) { hitosCombo += 1; sonido?.combo(comboActual) } else { sonido?.acierto() }
        } else {
            sonido?.fallo()
        }
        if var estado = supervivencia, var p = partida {
            puntosUltimo = estado.responder(correcto: r.correcto)
            p.jugadas.append(.init(itemId: item.id, bloqueId: banco.catalogo.bloque(deCompetencia: item.competencia)?.id ?? "",
                                   dificultad: item.dificultad, correcto: r.correcto, puntos: puntosUltimo))
            p.puntos = estado.puntos
            p.nivelMaximo = estado.nivelMaximo
            p.aciertos = estado.aciertos
            p.fallos = estado.fallos
            supervivencia = estado
            partida = p
        }
        sesionDiagnostico?.registrar(itemId: item.id, correcto: r.correcto)
        do {
            let e = try servicio.registrar(item: item, resultado: r, usoPista: usoPista, combo: comboActual,
                                           motivo: ronda.items[indice].motivo, errorRemedio: ronda.items[indice].errorId,
                                           actividad: intentoActividad(item, respuesta: respuesta, final: r), primerIntento: primerResultado)
            efecto = e
            xpRonda += e.xp
            if e.subioPeldano, !subidas.contains(item.competencia) { subidas.append(item.competencia) }
            if e.subioPeldano, let p = e.peldanoNuevo { peldanosNuevos[item.competencia] = p }
            erroresDetectados += e.erroresDetectados
            logros += e.logrosNuevos
        } catch {
            mensajeError = "No se ha podido guardar la respuesta."
        }
        fase = .corregido
    }

    func continuar() {
        guard fase == .corregido else { return }
        // Supervivencia y diagnóstico piden el siguiente ítem al terminar el anterior.
        if let estado = supervivencia {
            if !estado.terminada,
               let siguiente = try? servicio.siguienteSupervivencia(dificultad: estado.dificultad, area: areaSupervivencia, usados: Set(items.map(\.id)),
                                                                 huellas: Set(items.map(\.huella))) {
                items.append(siguiente)
                ronda.items.append(ItemRonda(itemId: siguiente.id, motivo: .supervivencia))
            }
        } else if let sesion = sesionDiagnostico, let siguiente = sesion.siguienteItem, !items.contains(where: { $0.id == siguiente.id }) {
            items.append(siguiente)
            ronda.items.append(ItemRonda(itemId: siguiente.id, motivo: .diagnostico))
        }
        if indice + 1 < items.count {
            indice += 1
            reiniciarItem()
            fase = .respondiendo
        } else {
            finalizar()
        }
    }

    func verRegla() {
        teoriaAbierta = teoriaDelItem
    }

    /// Nueva ronda del mismo tipo (las rondas de ítems fijos pasan a ser recomendadas). Tras una
    /// sesión diaria, «5 minutos más»: otra sesión corta con el mismo foco.
    func otraRonda() {
        switch ronda.tipo {
        case .items, .diagnostico: preparar(.recomendada)
        case .sesion(_, let foco): preparar(.sesion(duracion: .cinco, foco: foco))
        default: preparar(ronda.tipo)
        }
    }

    var esSesion: Bool { if case .sesion = ronda.tipo { true } else { false } }

    /// Salir a mitad: en Supervivencia, la partida se guarda como abandonada (con lo jugado) y no
    /// cuenta para el récord. Las respuestas ya están guardadas en todos los modos.
    func abandonar() {
        guard fase != .resumen, let p = partida, !p.jugadas.isEmpty else { return }
        _ = try? servicio.cerrarPartida(p, abandonada: true, ronda: ronda)
    }

    /// Respuesta a la pregunta del recordatorio (se hace una sola vez).
    func responderRecordatorio(_ activar: Bool) {
        preguntarRecordatorio = false
        guard var ajustes = try? servicio.ajustes() else { return }
        ajustes.recordatorioPreguntado = true
        if activar { ajustes.recordatorio = true }
        try? servicio.guardar(ajustes)
    }

    // MARK: - Internos

    private var areaSupervivencia: String? {
        if case .supervivencia(let area) = ronda.tipo { return area }
        return nil
    }

    private func preparar(_ tipo: TipoRonda) {
        supervivencia = nil
        partida = nil
        resultadoPartida = nil
        sesionDiagnostico = nil
        plan = nil
        efectoFinal = nil
        do {
            if case .diagnostico = tipo {
                // La sesión adaptativa vive en el modelo: el siguiente ítem depende de las respuestas.
                let sesion = servicio.nuevaSesionDiagnostico()
                sesionDiagnostico = sesion
                ronda = RondaPreparada(tipo: tipo, items: sesion.siguienteItem.map { [ItemRonda(itemId: $0.id, motivo: .diagnostico)] } ?? [],
                                       competenciaEnCurso: nil, teoriaPrevia: [])
            } else {
                ronda = try servicio.prepararRonda(tipo)
            }
        } catch {
            ronda = RondaPreparada(tipo: tipo, items: [], competenciaEnCurso: nil, teoriaPrevia: [])
            mensajeError = "No se ha podido preparar la ronda."
        }
        if case .supervivencia(let area) = tipo {
            supervivencia = EstadoSupervivencia()
            partida = PartidaSupervivencia(inicio: servicio.reloj.ahora, area: area)
        }
        items = ronda.items.compactMap { banco.item(id: $0.itemId) }
        indice = 0
        combo = ContadorCombo()
        hitosCombo = 0
        aciertos = 0
        respondidos = 0
        xpRonda = 0
        subidas = []
        peldanosNuevos = [:]
        erroresDetectados = []
        logros = []
        resumen = nil
        reiniciarItem()
        if items.isEmpty {
            fase = .vacia
        } else {
            fase = tarjetasPrevias.isEmpty ? .respondiendo : .teoria
        }
    }

    /// Registro del contrato de intento (solo en los ítems con reintento).
    private func intentoActividad(_ item: Item, respuesta: Respuesta, final r: Resultado) -> IntentoActividad? {
        guard let f = flujo, let resultado = f.resultado else { return nil }
        let reintento = f.reintentoCorrecto != nil ? respuesta.registro : nil
        return IntentoActividad(fecha: servicio.reloj.ahora, fuente: item.id, version: item.version, competencia: item.competencia,
                                destreza: item.destreza, patron: item.mecanica.patron, primeraRespuesta: primeraRespuesta,
                                primerCorrecto: f.primerCorrecto ?? r.correcto, ayudas: f.ayudas, reintento: reintento,
                                reintentoCorrecto: f.reintentoCorrecto, errorId: EstadoErrores.errores(de: primerResultado ?? r, item: item).first,
                                sinAyudas: sinAyudas, resultado: resultado, duracion: servicio.reloj.ahora.timeIntervalSince(inicioItem))
    }

    private func reiniciarItem() {
        marcasReintento = []
        primerResultado = nil
        primeraRespuesta = ""
        inicioItem = servicio.reloj.ahora
        if let item = itemActual, item.conReintento {
            var ayudas: Set<IntentoActividad.Ayuda> = []
            if esEjemplo { ayudas.insert(.ejemplo) }
            flujo = FlujoIntento(autoevaluacion: item.mecanica == .recuerdo, ayudasIniciales: ayudas)
        } else {
            flujo = nil
        }
        respuesta = nil
        resultado = nil
        efecto = nil
        usoPista = false
        pistasVisibles = 0
        pasosVisibles = esEjemplo ? 1 : 0
    }

    private func finalizar() {
        var efectoRonda = EfectoRonda()
        do {
            if let p = partida {
                let r = try servicio.cerrarPartida(p, abandonada: false, ronda: ronda)
                resultadoPartida = r
                partida = r.partida
                efectoRonda = r.efectoRonda ?? EfectoRonda()
                if r.esRecord { sonido?.record() }
            } else if let sesion = sesionDiagnostico {
                let (resultado, logrosNuevos) = try servicio.completarDiagnostico(sesion)
                plan = servicio.plan(resultado)
                logros += logrosNuevos
            } else {
                efectoRonda = try servicio.completarRonda(ronda, aciertos: aciertos)
                efectoFinal = efectoRonda
            }
            if !esDiagnostico {
                sonido?.finRonda()
                let ajustes = try servicio.ajustes()
                preguntarRecordatorio = !ajustes.recordatorioPreguntado
            }
        } catch {
            mensajeError = "No se ha podido guardar la ronda."
        }
        logros += efectoRonda.logrosNuevos
        resumen = Resumen(aciertos: aciertos, total: items.count, xp: xpRonda, comboMaximo: combo.maximo,
                          subidas: subidas, racha: efectoRonda.racha, cambiosRacha: efectoRonda.cambiosRacha,
                          logros: logros, areaPredominante: areaPredominante,
                          peldanosNuevos: peldanosNuevos, errores: (try? servicio.erroresDetectados(erroresDetectados)) ?? [],
                          esSesion: esSesion)
        fase = .resumen
    }

    #if DEBUG
    /// Solo para pruebas y capturas: rellena la respuesta correcta o una con un error.
    func rellenarParaPruebas(correcta: Bool = true) {
        guard let item = itemActual, fase == .respondiendo else { return }
        pasosVisibles = max(pasosVisibles, pasosEjemplo.count)
        respuesta = correcta ? RespuestaEjemplo.correcta(item.payload)
            : RespuestaEjemplo.conUnError(item.payload, erroresHabituales: item.erroresHabituales)
    }
    #endif
}
