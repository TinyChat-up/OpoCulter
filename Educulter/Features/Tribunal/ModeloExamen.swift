import Foundation
import Observation

/// Estado en pantalla de un examen del Tribunal. La lógica (cuenta atrás, entrega, corrección)
/// vive en `SesionExamen`, `CorrectorExamen` y el servicio; aquí solo se reparte el tiempo y se guarda.
@MainActor
@Observable
final class ModeloExamen: Identifiable {
    let id = UUID()
    let servicio: ServicioSesion
    private(set) var sesion: SesionExamen
    /// Último instante en que se contó el tiempo (se guarda: el reloj no se detiene al salir, 05J).
    private var ultimoTick: Date?
    /// Aviso discreto de los 15 y los 5 minutos.
    private(set) var aviso: String?
    private(set) var mensajeError: String?

    init(servicio: ServicioSesion, sesion: SesionExamen) {
        self.servicio = servicio
        self.sesion = sesion
        self.ultimoTick = sesion.marca
    }

    var banco: BancoContenido { servicio.banco }
    var datos: DatosTribunal { banco.tribunal }
    var examen: ExamenOficial? { sesion.modo.examenId.flatMap(datos.examen) }
    var actual: Int { sesion.actual }
    var total: Int { sesion.preguntas.count }

    // MARK: Preguntas

    func oficial(_ i: Int) -> ExamenOficial.Pregunta? {
        guard sesion.preguntas.indices.contains(i), case .oficial(let e, let n) = sesion.preguntas[i] else { return nil }
        return datos.examen(e)?.preguntas.first { $0.numero == n }
    }

    func item(_ i: Int) -> Item? {
        guard sesion.preguntas.indices.contains(i), case .item(let id, _) = sesion.preguntas[i] else { return nil }
        return banco.item(id: id)
    }

    func area(_ i: Int) -> String { CorrectorExamen.area(sesion.preguntas[i], datos: datos) }

    func enunciado(_ i: Int) -> String { oficial(i)?.enunciadoVisible ?? item(i)?.enunciado ?? "" }

    /// Rótulo de la pregunta en el mapa: «L3», «M7».
    func codigo(_ i: Int) -> String {
        if let o = oficial(i) { return o.codigo }
        let enArea = sesion.preguntas[..<i].filter { CorrectorExamen.area($0, datos: datos) == area(i) }.count + 1
        return "\(area(i) == "LEN" ? "L" : "M")\(enArea)"
    }

    // MARK: Respuestas

    var respuesta: SesionExamen.RespuestaPregunta {
        get { sesion.respuestas[actual] ?? .init() }
        set { sesion.respuestas[actual] = newValue; guardar() }
    }

    var respuestaItem: Respuesta? {
        get { respuesta.item }
        set { var r = respuesta; r.item = newValue; respuesta = r }
    }

    func ir(a i: Int) {
        guard sesion.preguntas.indices.contains(i) else { return }
        sesion.actual = i
        guardar()
    }

    func alternarMarca() {
        if sesion.marcadas.contains(actual) { sesion.marcadas.remove(actual) } else { sesion.marcadas.insert(actual) }
        guardar()
    }

    var borrador: Data {
        get { sesion.borradores[actual] ?? Data() }
        set { sesion.borradores[actual] = newValue; guardar() }
    }

    // MARK: Tiempo

    /// Cuenta el tiempo transcurrido desde el último tic (también el pasado fuera de la app).
    func tic(_ ahora: Date) {
        guard sesion.estado == .enCurso else { return }
        if let ultimo = ultimoTick, let a = sesion.avanzar(ahora.timeIntervalSince(ultimo), ahora: ahora) {
            aviso = "Quedan \(Int(a / 60)) minutos"
        }
        ultimoTick = ahora
        sesion.marca = ahora
        if Int(sesion.restante) % 10 == 0 || sesion.estado != .enCurso { guardar() }
    }

    /// La app pasa a segundo plano o se sale: el examen se guarda; el reloj sigue contando.
    func pausar() {
        guardar()
    }

    func quitarAviso() { aviso = nil }

    var entregado: Bool { sesion.estado != .enCurso }

    func entregar() {
        sesion.entregar(ahora: servicio.reloj.ahora)
        guardar()
    }

    // MARK: Corrección

    var pendientes: [Int] { CorrectorExamen.pendientesDeAutoevaluar(sesion, banco: banco) }

    func autoevaluar(_ i: Int, _ a: SesionExamen.Autoevaluacion) {
        sesion.autoevaluaciones[i] = a
        guardar()
    }

    func corregir() {
        do { sesion = try servicio.corregir(sesion) } catch { mensajeError = "No se ha podido guardar la corrección." }
    }

    @discardableResult
    func repasarAhora() -> [String] {
        guard let r = sesion.resultado else { return [] }
        return (try? servicio.repasarAhora(r)) ?? []
    }

    private func guardar() {
        do { try servicio.guardarExamen(sesion) } catch { mensajeError = "No se ha podido guardar el examen." }
    }
}
