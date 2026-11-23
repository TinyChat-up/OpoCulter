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
        var misionesCompletadas: [Mision]
        var logros: [Logro]
        /// Área con más ítems en la ronda (`LEN` o `MAT`): da color a "Otra ronda".
        var areaPredominante: String = "LEN"
    }

    let id = UUID()
    let servicio: ServicioSesion
    private(set) var ronda: RondaPreparada
    private(set) var items: [Item] = []
    private(set) var indice = 0
    private(set) var fase: Fase = .vacia

    /// Borrador de la respuesta que va construyendo la mecánica.
    var respuesta: Respuesta?
    private(set) var resultado: Resultado?
    private(set) var efecto: EfectoRespuesta?
    private(set) var usoPista = false
    private(set) var pistasVisibles = 0

    private(set) var combo = ContadorCombo()
    /// Aumenta en cada hito de combo (×3, ×5, ×10 y cada 10 más): dispara la animación y la
    /// vibración de impacto.
    private(set) var hitosCombo = 0
    private(set) var aciertos = 0
    private(set) var respondidos = 0
    private(set) var xpRonda = 0
    private(set) var subidas: [String] = []
    private(set) var misionesCompletadas: [Mision] = []
    private(set) var logros: [Logro] = []
    private(set) var resumen: Resumen?
    private(set) var mensajeError: String?

    /// Tarjeta abierta con "Ver regla".
    var teoriaAbierta: TarjetaTeoria?

    init(servicio: ServicioSesion, tipo: TipoRonda) {
        self.servicio = servicio
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
        guard fase == .respondiendo, let item = itemActual, let respuesta else { return false }
        return respuesta.esCompleta(para: item.payload)
    }

    /// Las pistas solo existen en los peldaños 1 y 2 (D-033).
    var puedePedirPista: Bool {
        guard fase == .respondiendo, let item = itemActual else { return false }
        return item.peldano <= Peldano.practica.rawValue && pistasVisibles < item.pistas.count
    }

    var pistasMostradas: [String] {
        Array(itemActual?.pistas.prefix(pistasVisibles) ?? [])
    }

    var feedbackEspecifico: [String] {
        guard let resultado, let item = itemActual else { return [] }
        return Evaluador.feedback(para: resultado, item: item)
    }

    var solucion: String? {
        itemActual.map { DescripcionSolucion.texto($0.payload) }
    }

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
    }

    func comprobar() {
        guard puedeComprobar, let item = itemActual, let respuesta else { return }
        let r = Evaluador.evaluar(respuesta, para: item)
        let comboActual = combo.registrar(correcto: r.correcto)
        resultado = r
        respondidos += 1
        if r.correcto {
            aciertos += 1
            if Self.esHitoCombo(comboActual) { hitosCombo += 1 }
        }
        do {
            let e = try servicio.registrar(item: item, resultado: r, usoPista: usoPista, combo: comboActual,
                                           motivo: ronda.items[indice].motivo)
            efecto = e
            xpRonda += e.xp
            if e.subioPeldano, !subidas.contains(item.competencia) { subidas.append(item.competencia) }
            misionesCompletadas += e.misionesCompletadas
            logros += e.logrosNuevos
        } catch {
            mensajeError = "No se ha podido guardar la respuesta."
        }
        fase = .corregido
    }

    func continuar() {
        guard fase == .corregido else { return }
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

    /// Nueva ronda del mismo tipo (las rondas de ítems fijos pasan a ser recomendadas).
    func otraRonda() {
        switch ronda.tipo {
        case .items: preparar(.recomendada)
        default: preparar(ronda.tipo)
        }
    }

    // MARK: - Internos

    private func preparar(_ tipo: TipoRonda) {
        do {
            ronda = try servicio.prepararRonda(tipo)
        } catch {
            ronda = RondaPreparada(tipo: tipo, items: [], competenciaEnCurso: nil, teoriaPrevia: [])
            mensajeError = "No se ha podido preparar la ronda."
        }
        items = ronda.items.compactMap { banco.item(id: $0.itemId) }
        indice = 0
        combo = ContadorCombo()
        hitosCombo = 0
        aciertos = 0
        respondidos = 0
        xpRonda = 0
        subidas = []
        misionesCompletadas = []
        logros = []
        resumen = nil
        reiniciarItem()
        if items.isEmpty {
            fase = .vacia
        } else {
            fase = tarjetasPrevias.isEmpty ? .respondiendo : .teoria
        }
    }

    private func reiniciarItem() {
        respuesta = nil
        resultado = nil
        efecto = nil
        usoPista = false
        pistasVisibles = 0
    }

    private func finalizar() {
        var efectoRonda = EfectoRonda()
        do {
            efectoRonda = try servicio.completarRonda(ronda)
        } catch {
            mensajeError = "No se ha podido guardar la ronda."
        }
        misionesCompletadas += efectoRonda.misionesCompletadas
        logros += efectoRonda.logrosNuevos
        resumen = Resumen(aciertos: aciertos, total: items.count, xp: xpRonda, comboMaximo: combo.maximo,
                          subidas: subidas, racha: efectoRonda.racha, cambiosRacha: efectoRonda.cambiosRacha,
                          misionesCompletadas: misionesCompletadas, logros: logros, areaPredominante: areaPredominante)
        fase = .resumen
    }

    #if DEBUG
    /// Solo para pruebas y capturas: rellena la respuesta correcta o una con un error.
    func rellenarParaPruebas(correcta: Bool = true) {
        guard let item = itemActual, fase == .respondiendo else { return }
        respuesta = correcta ? RespuestaEjemplo.correcta(item.payload)
            : RespuestaEjemplo.conUnError(item.payload, erroresHabituales: item.erroresHabituales)
    }
    #endif
}
