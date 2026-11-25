import SwiftUI

/// Movimiento "gomoso" (Rubber Hose, D-059): muelles con rebote (≤ 0,35 s). Con "Reducir
/// movimiento" se sustituyen por fundidos.
enum Movimiento {
    /// Duración máxima de cualquier animación de confirmación.
    static let duracionMaxima: Double = 0.35

    static func animacion(reducir: Bool) -> Animation {
        reducir ? .easeInOut(duration: 0.2) : .spring(duration: 0.3, bounce: 0.4)
    }

    static func transicion(reducir: Bool, borde: Edge = .bottom) -> AnyTransition {
        reducir ? .opacity : .move(edge: borde).combined(with: .opacity)
    }
}

extension View {
    /// *Squash & stretch* sutil al cambiar `disparador` (encajar, acertar, desbloquear): se aplasta
    /// (1,08 × 0,92) y vuelve con rebote, en 0,3 s. Con "Reducir movimiento", un fundido breve.
    func estiramiento<V: Equatable>(_ disparador: V) -> some View {
        modifier(Estiramiento(disparador: disparador))
    }

    /// Aplica `animation` respetando "Reducir movimiento".
    func animacionApp<V: Equatable>(_ valor: V) -> some View {
        modifier(AnimacionApp(valor: valor))
    }
}

private struct AnimacionApp<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducir
    let valor: V

    func body(content: Content) -> some View {
        content.animation(Movimiento.animacion(reducir: reducir), value: valor)
    }
}

private struct Estiramiento<V: Equatable>: ViewModifier {
    let disparador: V
    @Environment(\.accessibilityReduceMotion) private var reducir
    @State private var aplastado = false
    @State private var opacidad = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: aplastado ? 1.08 : 1, y: aplastado ? 0.92 : 1, anchor: .bottom)
            .opacity(opacidad)
            .onChange(of: disparador) { _, _ in
                if reducir {
                    withAnimation(.easeOut(duration: 0.1)) { opacidad = 0.6 }
                    withAnimation(.easeIn(duration: 0.15).delay(0.1)) { opacidad = 1 }
                } else {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) { aplastado = true }
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.45).delay(0.1)) { aplastado = false }
                }
            }
    }
}

private struct ClaveVibracion: EnvironmentKey {
    static let defaultValue = true
}

private struct ClaveSonido: EnvironmentKey {
    static let defaultValue: any ServicioSonido = SonidoSilencioso()
}

extension EnvironmentValues {
    /// Vibración activada en Ajustes.
    var vibracionActiva: Bool {
        get { self[ClaveVibracion.self] }
        set { self[ClaveVibracion.self] = newValue }
    }

    /// Sonidos de la app (respetan Ajustes).
    var sonido: any ServicioSonido {
        get { self[ClaveSonido.self] }
        set { self[ClaveSonido.self] = newValue }
    }
}

extension View {
    /// `sensoryFeedback` que respeta el ajuste de vibración.
    func retroHaptica<T: Equatable>(_ retro: SensoryFeedback, trigger: T) -> some View {
        modifier(RetroHaptica(retro: retro, disparador: trigger))
    }
}

private struct RetroHaptica<T: Equatable>: ViewModifier {
    let retro: SensoryFeedback
    let disparador: T
    @Environment(\.vibracionActiva) private var activa

    func body(content: Content) -> some View {
        content.sensoryFeedback(retro, trigger: disparador) { _, _ in activa }
    }
}

/// Sonidos de la app (D-073). La implementación real (`SonidoSintetizado`) sintetiza tonos con
/// AVAudioEngine; `SonidoConAjustes` respeta el interruptor de Ajustes.
@MainActor
protocol ServicioSonido: AnyObject, Sendable {
    func acierto()
    func fallo()
    func combo(_ n: Int)
    func finRonda()
    func record()
    func tildeCae()
    func celdaColoreada()
}

/// Implementación vacía (tests, previsualizaciones y capturas).
@MainActor
final class SonidoSilencioso: ServicioSonido {
    func acierto() {}
    func fallo() {}
    func combo(_ n: Int) {}
    func finRonda() {}
    func record() {}
    func tildeCae() {}
    func celdaColoreada() {}
}
