import Foundation
import Observation

/// Estado en pantalla de un intento de simulacro escrito (05J). El reloj se calcula desde la hora de
/// inicio guardada (no se pausa) y el intento se guarda en cada edición y al pasar a segundo plano.
@MainActor
@Observable
final class ModeloEscrito: Identifiable {
    let id = UUID()
    let servicio: ServicioSesion
    let simulacro: SimulacroOriginal
    private(set) var intento: IntentoEscrito
    private(set) var ahora: Date
    private(set) var mensajeError: String?

    init(servicio: ServicioSesion, simulacro: SimulacroOriginal, intento: IntentoEscrito) {
        self.servicio = servicio
        self.simulacro = simulacro
        self.intento = intento
        self.ahora = servicio.reloj.ahora
        tic(servicio.reloj.ahora)
    }

    var datos: SimulacroEscrito { simulacro.datos }
    var preguntas: [SimulacroEscrito.Pregunta] { datos.preguntas }
    var enPapel: Bool { intento.formato == .papel }

    // MARK: Navegación

    var actual: String { intento.actual ?? preguntas.first?.id ?? "" }
    var indice: Int { preguntas.firstIndex { $0.id == actual } ?? 0 }
    var pregunta: SimulacroEscrito.Pregunta? { datos.pregunta(actual) }

    func ir(a id: String) {
        intento.actual = id
        guardar()
    }

    func mover(_ delta: Int) {
        let i = indice + delta
        guard preguntas.indices.contains(i) else { return }
        ir(a: preguntas[i].id)
    }

    // MARK: Respuestas, marcas y borrador

    var respuesta: String {
        get { intento.respuestas[actual] ?? "" }
        set { intento.respuestas[actual] = newValue.isEmpty ? nil : newValue; guardar() }
    }

    func alternarMarca(_ id: String? = nil) {
        let p = id ?? actual
        if intento.marcas.contains(p) { intento.marcas.remove(p) } else { intento.marcas.insert(p) }
        guardar()
    }

    var borrador: Data {
        get { intento.borradores[actual] ?? Data() }
        set { intento.borradores[actual] = newValue; guardar() }
    }

    var sinResponder: Int { preguntas.filter { !intento.respondida($0.id) }.count }

    // MARK: Tiempo

    var restante: Int { intento.restante(ahora) }

    func tic(_ fecha: Date) {
        ahora = fecha
        if intento.comprobarTiempo(fecha) { guardar() }
    }

    func alternarReloj() {
        intento.relojOculto.toggle()
        guardar()
    }

    /// Al pasar a segundo plano: se guarda (el reloj sigue contando desde la hora de inicio).
    func segundoPlano() { guardar() }

    func entregar() {
        do { intento = try servicio.entregar(intento) } catch { mensajeError = "No se ha podido guardar la entrega." }
    }

    // MARK: Corrección

    func criterios(_ id: String) -> [Bool]? { intento.criterios[id] }

    func marcarCriterio(_ id: String, _ n: Int, _ valor: Bool) {
        guard let p = datos.pregunta(id) else { return }
        var c = intento.criterios[id] ?? Array(repeating: false, count: p.rubrica.count)
        c[n] = valor
        intento.criterios[id] = c
        guardar()
    }

    /// La pregunta está corregida aunque no cumpla ningún criterio.
    func ningunCriterio(_ id: String) {
        guard let p = datos.pregunta(id) else { return }
        intento.criterios[id] = Array(repeating: false, count: p.rubrica.count)
        guardar()
    }

    var faltasPalabras: Int {
        get { intento.faltasPalabras }
        set { intento.faltasPalabras = max(0, newValue); guardar() }
    }

    var faltasTildes: Int {
        get { intento.faltasTildes }
        set { intento.faltasTildes = max(0, newValue); guardar() }
    }

    var aplicarPenalizacion: Bool {
        get { intento.aplicarPenalizacion }
        set { intento.aplicarPenalizacion = newValue; guardar() }
    }

    var resultado: ResultadoEscrito { CorrectorEscrito.corregir(intento, simulacro: datos, reglas: servicio.banco.tribunal.reglas) }

    var prioridades: [(competencia: String, nombre: String, bloque: String, practicable: Bool)] { servicio.prioridades(intento) }

    var sugerencia: String { (try? servicio.sugerencia(tras: intento)) ?? "" }

    private func guardar() {
        do { try servicio.guardar(intento) } catch { mensajeError = "No se ha podido guardar el simulacro." }
    }
}
