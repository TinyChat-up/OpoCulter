import SwiftUI

// MARK: - Representación intercambiable (D-054)

/// Cómo se dibuja un compañero. Desde la 05E parte 2, `.vectorial` son los personajes v3 dibujados
/// pieza a pieza desde los SVG de la dirección (D-105). `.ilustracion(nombreAsset:)` sigue
/// disponible por si se aportan imágenes por estado.
protocol RepresentacionPersonaje: Sendable {
    @MainActor func vista(_ companero: Companero, estado: EstadoPersonaje, animar: Bool) -> AnyView
}

struct RepresentacionVectorial: RepresentacionPersonaje {
    @MainActor func vista(_ companero: Companero, estado: EstadoPersonaje, animar: Bool) -> AnyView {
        AnyView(FiguraV3(companero: companero, estado: estado, animar: animar))
    }
}

/// Ilustraciones del Asset Catalog: `<nombreAsset>_<companero>_<estado>` (p. ej. `personaje_tilde_alegre`).
struct RepresentacionIlustracion: RepresentacionPersonaje {
    let nombreAsset: String

    @MainActor func vista(_ companero: Companero, estado: EstadoPersonaje, animar: Bool) -> AnyView {
        AnyView(Image("\(nombreAsset)_\(companero.rawValue)_\(estado.rawValue)").resizable().scaledToFit())
    }
}

extension RepresentacionPersonaje where Self == RepresentacionVectorial {
    static var vectorial: RepresentacionVectorial { RepresentacionVectorial() }
}

extension RepresentacionPersonaje where Self == RepresentacionIlustracion {
    static func ilustracion(nombreAsset: String) -> RepresentacionIlustracion { RepresentacionIlustracion(nombreAsset: nombreAsset) }
}

private struct ClaveRepresentacion: EnvironmentKey {
    static let defaultValue: any RepresentacionPersonaje = RepresentacionVectorial()
}

extension EnvironmentValues {
    var representacionPersonaje: any RepresentacionPersonaje {
        get { self[ClaveRepresentacion.self] }
        set { self[ClaveRepresentacion.self] = newValue }
    }
}

// MARK: - Vista

/// Personaje en un estado. Decorativo para VoiceOver salvo cuando transmite un estado («Mimo te
/// anima»). Nunca recibe toques. Como mucho uno por pantalla y nunca mientras se resuelve un ítem.
struct VistaPersonaje: View {
    let companero: Companero
    let estado: EstadoPersonaje
    var tamano: CGFloat = 64
    /// `false` en las pruebas instantáneas: pose final, sin animación ni parpadeo.
    var animar = true
    @Environment(\.representacionPersonaje) private var representacion

    var body: some View {
        let etiqueta = ReglasPersonaje.etiqueta(AparicionPersonaje(companero: companero, estado: estado))
        representacion.vista(companero, estado: estado, animar: animar)
            .frame(width: tamano, height: tamano * DibujosV3.lienzoPersonaje.height / DibujosV3.lienzoPersonaje.width)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(etiqueta ?? "")
            .accessibilityHidden(etiqueta == nil)
            .accessibilityIdentifier("personaje_\(companero.rawValue)_\(estado.rawValue)")
    }
}

/// Personaje v3 (Tilde, Cuarto o Mimo) con las animaciones de cada estado (≤ 0,6 s; el parpadeo es el
/// único bucle). Con «Reducir movimiento», el estado cambia sin movimiento (pose final, sin parpadeo).
struct FiguraV3: View {
    let companero: Companero
    let estado: EstadoPersonaje
    var animar = true
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var parpadeo = false
    /// Contador que dispara las animaciones de un solo golpe (rebote, latido).
    @State private var golpe = 0

    private var lienzo: CGSize { DibujosV3.lienzoPersonaje }
    private var movimiento: Bool { animar && !reducirMovimiento }

    var body: some View {
        ZStack {
            ForEach(Array(grupos.enumerated()), id: \.offset) { _, g in pieza(g) }
        }
        .modifier(Rebote(activo: movimiento && estado == .alegre, golpe: golpe))
        .rotationEffect(.degrees(companero == .mimo && estado == .pensando ? -8 : 0), anchor: .bottom)
        .animation(movimiento ? .smooth(duration: 0.4) : nil, value: estado)
        .onAppear { golpe += 1 }
        .onChange(of: estado) { _, _ in golpe += 1 }
        .task(id: movimiento && estado == .neutro) { await parpadear() }
    }

    /// Grupos del dibujo según el personaje y el estado (cambia de qué ojo o si hay chispas).
    private var grupos: [GrupoSVG] {
        switch companero {
        case .tilde:
            var g = DibujosV3.tilde
            if estado == .alegre { g.append(DibujosV3.cuarto.first { $0.id == "chispas" }!) }
            return g
        case .cuarto:
            return DibujosV3.cuarto.compactMap { g in
                switch g.id {
                case "ojoDerGuino": estado == .guino ? g : DibujosV3.cuartoOjoDerAbierto
                case "chispas": estado == .alegre || estado == .guino ? g : nil
                default: g
                }
            }
        case .mimo:
            return DibujosV3.mimo.filter { $0.id != "chispas" || estado == .alegre }
        }
    }

    private static let ojos: Set<String> = ["ojoDer", "ojoIzq", "lupa"]

    @ViewBuilder
    private func pieza(_ g: GrupoSVG) -> some View {
        let ancla = UnitPoint(x: g.ancla.x / lienzo.width, y: g.ancla.y / lienzo.height)
        if estado == .descanso && Self.ojos.contains(g.id) {
            // Ojos cerrados: una línea curva en lugar del ojo (en la lupa, dentro de la lente). En
            // Cuarto, en papel, como su guiño, para que se vea sobre el cuerpo bosque.
            VistaGrupoSVG(grupo: Self.ojoCerrado(g, color: companero == .cuarto ? 0xF4F8F0 : 0x16241F), lienzo: lienzo)
        } else {
            VistaGrupoSVG(grupo: pupilas(g), lienzo: lienzo, siluetaOscura: true)
                .scaleEffect(x: 1, y: parpadeo && Self.ojos.contains(g.id) ? 0.1 : 1, anchor: ancla)
                .scaleEffect(escala(g), anchor: ancla)
                .rotationEffect(.degrees(giro(g)), anchor: ancla)
                .offset(desplazamiento(g))
                .modifier(Latido(activo: movimiento && estado == .animo && g.id == "corazon", golpe: golpe))
        }
    }

    /// Cuarto mira arriba al pensar: las pupilas (piezas 2 y 3 de cada ojo) suben.
    private func pupilas(_ g: GrupoSVG) -> GrupoSVG {
        guard companero == .cuarto, estado == .pensando, g.id.hasPrefix("ojo") else { return g }
        var c = g
        for i in c.piezas.indices.dropFirst() {
            if case .elipse(let cx, let cy, let rx, let ry) = c.piezas[i].forma { c.piezas[i].forma = .elipse(cx: cx, cy: cy - 10, rx: rx, ry: ry) }
        }
        return c
    }

    private func escala(_ g: GrupoSVG) -> CGFloat {
        if companero == .tilde && estado == .pensando && g.id == "lupa" { return 1.15 }
        return 1
    }

    private func giro(_ g: GrupoSVG) -> Double {
        if estado == .descanso && g.id == "brote" { return 38 }
        return 0
    }

    private func desplazamiento(_ g: GrupoSVG) -> CGSize {
        if companero == .tilde && estado == .pensando && g.id == "lupa" { return CGSize(width: -3, height: -3) }
        return .zero
    }

    /// Ojo cerrado: arco por la mitad inferior del ojo, en tinta del personaje.
    static func ojoCerrado(_ g: GrupoSVG, color: UInt32 = 0x16241F) -> GrupoSVG {
        // En la lupa se conservan el mango y la lente (piezas 1 y 2) y se cierra el ojo de dentro (pieza 3).
        let conservadas = g.id == "lupa" ? Array(g.piezas.prefix(2)) : []
        let ojo = g.id == "lupa" ? g.piezas[2] : g.piezas.first
        guard case .elipse(let cx, let cy, let rx, _)? = ojo?.forma else { return g }
        let d = "M\(cx - rx * 0.8) \(cy) C \(cx - rx * 0.4) \(cy + rx * 0.5), \(cx + rx * 0.4) \(cy + rx * 0.5), \(cx + rx * 0.8) \(cy)"
        return GrupoSVG(id: g.id, piezas: conservadas + [PiezaSVG(forma: .trazado(d), relleno: nil, trazo: color, grosor: 7)], ancla: g.ancla)
    }

    /// Parpadeo cada 4–6 s (aleatorio con semilla) mientras el personaje está en estado neutro.
    private func parpadear() async {
        guard movimiento && estado == .neutro else { parpadeo = false; return }
        var rng = GeneradorConSemilla(semilla: UInt64(companero.rawValue.unicodeScalars.reduce(0) { $0 &* 31 &+ UInt64($1.value) }))
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(ReglasPersonaje.intervaloParpadeo(&rng)))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.06)) { parpadeo = true }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeOut(duration: 0.08)) { parpadeo = false }
        }
    }
}

/// Rebote gomoso (alegre): aplastar, estirar y volver, en 0,5 s, anclado en los pies.
private struct Rebote: ViewModifier {
    let activo: Bool
    let golpe: Int
    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(1), trigger: golpe) { vista, y in
            vista.scaleEffect(x: activo ? 2 - y : 1, y: activo ? y : 1, anchor: .bottom)
        } keyframes: { _ in
            KeyframeTrack {
                if activo {
                    CubicKeyframe(0.96, duration: 0.12)
                    SpringKeyframe(1.03, duration: 0.18, spring: .smooth)
                    SpringKeyframe(1, duration: 0.2, spring: .smooth)
                } else {
                    LinearKeyframe(1, duration: 0.01)
                }
            }
        }
    }
}

/// Latido de Mimo (ánimo): el corazón pasa de 1 a 1,08 y vuelve, en 0,4 s.
private struct Latido: ViewModifier {
    let activo: Bool
    let golpe: Int
    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(1), trigger: golpe) { vista, e in
            vista.scaleEffect(activo ? e : 1, anchor: UnitPoint(x: 0.5, y: 296 / 420))
        } keyframes: { _ in
            KeyframeTrack {
                if activo {
                    SpringKeyframe(1.08, duration: 0.2, spring: .smooth)
                    SpringKeyframe(1, duration: 0.2, spring: .smooth)
                } else {
                    LinearKeyframe(1, duration: 0.01)
                }
            }
        }
    }
}

// MARK: - Marca v5

/// Marca de la app (`docs/arte/v5/marca.svg`): la cuadrícula de cuatro módulos, sin fondo. Los
/// módulos de tinta usan el token `Tinta` (claro en modo oscuro) y los salvia, `Lengua`, así que se
/// leen sobre el papel en los dos modos. Con `animar`, los módulos entran uno a uno (0,6 s en total);
/// con «Reducir movimiento», aparecen ya colocados.
struct MarcaView: View {
    var tamano: CGFloat = 120
    var animar = false
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var visibles = 0

    /// Retardo de entrada de cada módulo y su duración: 4 × 0,1 s + 0,2 s = 0,6 s.
    static let retardo = 0.1
    static let duracion = 0.2

    private var conMovimiento: Bool { animar && !reducirMovimiento }

    var body: some View {
        Canvas { ctx, tam in
            let escala = min(tam.width / DibujosV3.lienzoMarca.width, tam.height / DibujosV3.lienzoMarca.height)
            ctx.scaleBy(x: escala, y: escala)
            for m in DibujosV3.Modulo.allCases where !conMovimiento || m.rawValue < visibles {
                ctx.fill(m.path, with: .color(m.salvia ? Paleta.lengua : Paleta.contorno))
            }
        }
        .frame(width: tamano, height: tamano)
        .task(id: conMovimiento) {
            guard conMovimiento else { visibles = DibujosV3.Modulo.allCases.count; return }
            visibles = 0
            for i in 1...DibujosV3.Modulo.allCases.count {
                try? await Task.sleep(for: .seconds(Self.retardo))
                withAnimation(.easeOut(duration: Self.duracion)) { visibles = i }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Avatar del usuario

/// Avatar del propietario recortado en círculo, con borde fino.
struct VistaAvatar: View {
    let avatar: Avatar
    var tamano: CGFloat = 44

    var body: some View {
        Image(avatar.recurso)
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: tamano, height: tamano)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Paleta.borde, lineWidth: Trazo.fino))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Avatar con \(avatar.nombre)")
    }
}
