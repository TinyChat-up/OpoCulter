import AVFoundation
import Foundation

/// Sonidos sintetizados en tiempo real con AVAudioEngine (D-073): tonos originales generados
/// por código, sin archivos de audio de terceros. Cada sonido dura como mucho 250 ms y tiene una
/// envolvente suave (ataque y caída) para no ser estridente. La sesión es `.ambient`: respeta el
/// interruptor de silencio y no interrumpe la música del usuario.
@MainActor
final class SonidoSintetizado: ServicioSonido {
    /// Nota: frecuencia (Hz), duración (s) e intensidad (0–1).
    struct Nota: Sendable, Equatable { var frecuencia: Double; var duracion: Double; var volumen: Float }

    static let duracionMaxima = 0.25
    /// Recetas de cada sonido (todas suman ≤ 250 ms).
    static let recetas: [String: [Nota]] = [
        "acierto": [Nota(frecuencia: 659.25, duracion: 0.09, volumen: 0.22), Nota(frecuencia: 987.77, duracion: 0.13, volumen: 0.22)],
        "fallo": [Nota(frecuencia: 196.00, duracion: 0.20, volumen: 0.16)],
        "combo": [Nota(frecuencia: 783.99, duracion: 0.07, volumen: 0.2), Nota(frecuencia: 987.77, duracion: 0.07, volumen: 0.2), Nota(frecuencia: 1318.5, duracion: 0.1, volumen: 0.2)],
        "record": [Nota(frecuencia: 523.25, duracion: 0.06, volumen: 0.22), Nota(frecuencia: 659.25, duracion: 0.06, volumen: 0.22),
                   Nota(frecuencia: 783.99, duracion: 0.06, volumen: 0.22), Nota(frecuencia: 1046.5, duracion: 0.07, volumen: 0.22)],
        "finRonda": [Nota(frecuencia: 587.33, duracion: 0.1, volumen: 0.18), Nota(frecuencia: 880.0, duracion: 0.14, volumen: 0.18)],
        "tilde": [Nota(frecuencia: 1174.7, duracion: 0.05, volumen: 0.14), Nota(frecuencia: 880.0, duracion: 0.05, volumen: 0.12)],
        "celda": [Nota(frecuencia: 698.46, duracion: 0.06, volumen: 0.12)],
    ]

    private let motor = AVAudioEngine()
    private let reproductor = AVAudioPlayerNode()
    private let formato: AVAudioFormat
    private var preparado = false

    init() {
        formato = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    private func preparar() -> Bool {
        if preparado { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            motor.attach(reproductor)
            motor.connect(reproductor, to: motor.mainMixerNode, format: formato)
            try motor.start()
            reproductor.play()
            preparado = true
        } catch {
            preparado = false
        }
        return preparado
    }

    /// Muestras de una secuencia de notas (seno con armónico suave y envolvente lineal de 8 ms).
    static func muestras(_ notas: [Nota], frecuenciaMuestreo: Double = 44_100) -> [Float] {
        var out: [Float] = []
        for n in notas {
            let total = Int(n.duracion * frecuenciaMuestreo)
            let rampa = Int(0.008 * frecuenciaMuestreo)
            for i in 0..<total {
                let t = Double(i) / frecuenciaMuestreo
                let envolvente = Float(min(1, Double(i) / Double(max(rampa, 1)), Double(total - i) / Double(max(rampa * 4, 1))))
                let onda = sin(2 * .pi * n.frecuencia * t) + 0.25 * sin(4 * .pi * n.frecuencia * t)
                out.append(Float(onda) * n.volumen * envolvente * 0.8)
            }
        }
        return out
    }

    private func tocar(_ clave: String) {
        guard let notas = Self.recetas[clave], preparar() else { return }
        let datos = Self.muestras(notas)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: formato, frameCapacity: AVAudioFrameCount(datos.count)) else { return }
        buffer.frameLength = AVAudioFrameCount(datos.count)
        datos.withUnsafeBufferPointer { origen in
            buffer.floatChannelData?[0].update(from: origen.baseAddress!, count: datos.count)
        }
        reproductor.scheduleBuffer(buffer, completionHandler: nil)
    }

    func acierto() { tocar("acierto") }
    func fallo() { tocar("fallo") }
    func combo(_ n: Int) { tocar("combo") }
    func finRonda() { tocar("finRonda") }
    func record() { tocar("record") }
    func tildeCae() { tocar("tilde") }
    func celdaColoreada() { tocar("celda") }
}

/// Envoltorio que solo reproduce si el sonido está activado en Ajustes.
@MainActor
final class SonidoConAjustes: ServicioSonido {
    let destino: any ServicioSonido
    let activo: () -> Bool

    init(destino: any ServicioSonido, activo: @escaping () -> Bool) {
        self.destino = destino
        self.activo = activo
    }

    func acierto() { if activo() { destino.acierto() } }
    func fallo() { if activo() { destino.fallo() } }
    func combo(_ n: Int) { if activo() { destino.combo(n) } }
    func finRonda() { if activo() { destino.finRonda() } }
    func record() { if activo() { destino.record() } }
    func tildeCae() { if activo() { destino.tildeCae() } }
    func celdaColoreada() { if activo() { destino.celdaColoreada() } }
}
