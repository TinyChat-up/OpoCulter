import SwiftUI

/// Animaciones cortas con muelle (≤ 0,35 s). Con "Reducir movimiento" se sustituyen por fundidos.
enum Movimiento {
    static func animacion(reducir: Bool) -> Animation {
        reducir ? .easeInOut(duration: 0.2) : .spring(duration: 0.3, bounce: 0.25)
    }

    static func transicion(reducir: Bool, borde: Edge = .bottom) -> AnyTransition {
        reducir ? .opacity : .move(edge: borde).combined(with: .opacity)
    }
}

extension View {
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

/// Sonidos de la app. En la Fase 05A no hay implementación (D-041): el protocolo queda
/// preparado para la 05B.
@MainActor
protocol ServicioSonido: AnyObject {
    func acierto()
    func fallo()
    func combo(_ n: Int)
    func finRonda()
}

/// Implementación vacía.
@MainActor
final class SonidoSilencioso: ServicioSonido {
    func acierto() {}
    func fallo() {}
    func combo(_ n: Int) {}
    func finRonda() {}
}
