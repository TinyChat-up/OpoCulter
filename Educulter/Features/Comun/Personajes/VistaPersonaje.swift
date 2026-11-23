import SwiftUI

// MARK: - Representación intercambiable (D-054)

/// Cómo se dibuja un compañero. Hoy, `.vectorial` (formas de SwiftUI). Si el propietario
/// aporta ilustraciones propias, basta con `.ilustracion(nombreAsset:)`: las vistas no cambian.
/// Formato de entrega en UX_UI.md §4.10 (PDF o SVG vectorial, un archivo por estado, fondo
/// transparente, nombre `<prefijo>_<estado>`).
protocol RepresentacionPersonaje: Sendable {
    @MainActor func vista(_ companero: Companero, estado: EstadoPersonaje) -> AnyView
}

struct RepresentacionVectorial: RepresentacionPersonaje {
    @MainActor func vista(_ companero: Companero, estado: EstadoPersonaje) -> AnyView {
        switch companero {
        case .tilde: AnyView(FiguraTilde(estado: estado))
        case .cuarto: AnyView(FiguraCuarto(estado: estado))
        }
    }
}

/// Ilustraciones del Asset Catalog: `<nombreAsset>_<companero>_<estado>` (p. ej. `personaje_tilde_celebra`).
struct RepresentacionIlustracion: RepresentacionPersonaje {
    let nombreAsset: String

    @MainActor func vista(_ companero: Companero, estado: EstadoPersonaje) -> AnyView {
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

/// Compañero en un estado. Decorativo para VoiceOver: el mensaje siempre va en texto al lado.
/// Nunca recibe toques (no bloquea la interacción). Durante la actividad, como máximo 64 pt.
struct VistaPersonaje: View {
    let companero: Companero
    let estado: EstadoPersonaje
    var tamano: CGFloat = 64
    @Environment(\.representacionPersonaje) private var representacion
    @Environment(\.accessibilityReduceMotion) private var reducir

    var body: some View {
        representacion.vista(companero, estado: estado)
            .frame(width: tamano, height: tamano)
            .id(estado)
            .transition(reducir ? .opacity : .scale(scale: 0.85).combined(with: .opacity))
            .animation(reducir ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.6), value: estado)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Rasgos comunes (ojos y boca por estado)

/// Ojos y boca dibujados con formas. Todo en coordenadas relativas al lado del personaje.
private struct Cara: View {
    let estado: EstadoPersonaje
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            let ojoY = l * 0.42, sepOjos = l * 0.17, ojo = l * 0.09
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { lado in
                    ojoVista(tam: ojo)
                        .position(x: l / 2 + lado * sepOjos + (estado == .pensando ? l * 0.04 : 0),
                                  y: ojoY - (estado == .pensando ? l * 0.04 : 0))
                }
                boca(l: l).stroke(color, style: StrokeStyle(lineWidth: max(2, l * 0.045), lineCap: .round))
                if estado == .sorprendido {
                    Circle().stroke(color, lineWidth: max(2, l * 0.045)).frame(width: l * 0.12, height: l * 0.14).position(x: l / 2, y: l * 0.64)
                }
            }
        }
    }

    @ViewBuilder
    private func ojoVista(tam: CGFloat) -> some View {
        switch estado {
        case .celebra:
            ArcoOjo(abajo: false).stroke(color, style: StrokeStyle(lineWidth: max(2, tam * 0.45), lineCap: .round)).frame(width: tam * 1.4, height: tam * 0.8)
        case .dormido:
            Capsule().fill(color).frame(width: tam * 1.3, height: max(2, tam * 0.35))
        case .anima:
            ArcoOjo(abajo: true).stroke(color, style: StrokeStyle(lineWidth: max(2, tam * 0.45), lineCap: .round)).frame(width: tam * 1.3, height: tam * 0.6)
        case .sorprendido:
            Circle().fill(color).frame(width: tam * 1.35, height: tam * 1.35)
        case .neutral, .pensando:
            Circle().fill(color).frame(width: tam, height: tam)
        }
    }

    private func boca(l: CGFloat) -> Path {
        var p = Path()
        let cx = l / 2, y = l * 0.64, ancho = l * 0.16
        switch estado {
        case .celebra:
            p.move(to: CGPoint(x: cx - ancho * 1.2, y: y - l * 0.02))
            p.addQuadCurve(to: CGPoint(x: cx + ancho * 1.2, y: y - l * 0.02), control: CGPoint(x: cx, y: y + l * 0.14))
        case .neutral, .anima:
            p.move(to: CGPoint(x: cx - ancho, y: y))
            p.addQuadCurve(to: CGPoint(x: cx + ancho, y: y), control: CGPoint(x: cx, y: y + l * 0.07))
        case .pensando:
            p.move(to: CGPoint(x: cx - ancho * 0.5, y: y + l * 0.02))
            p.addLine(to: CGPoint(x: cx + ancho * 0.7, y: y))
        case .dormido:
            p.move(to: CGPoint(x: cx - ancho * 0.4, y: y + l * 0.02))
            p.addLine(to: CGPoint(x: cx + ancho * 0.4, y: y + l * 0.02))
        case .sorprendido:
            break
        }
        return p
    }
}

private struct ArcoOjo: Shape {
    /// `false`: ∩ (sonrisa de ojos); `true`: ∪ suave.
    let abajo: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: abajo ? r.minY : r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: abajo ? r.minY : r.maxY),
                       control: CGPoint(x: r.midX, y: abajo ? r.maxY + r.height : r.minY - r.height))
        return p
    }
}

// MARK: - «Tilde» (Lengua)

/// Forma redondeada coral con una tilde como rasgo. Al celebrar, la tilde salta; al animar,
/// se inclina hacia delante; dormido, cae tumbada.
struct FiguraTilde: View {
    let estado: EstadoPersonaje

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: l * 0.34, style: .continuous)
                    .fill(Paleta.lengua)
                    .frame(width: l * 0.82, height: l * 0.72)
                    .position(x: l / 2, y: l * 0.6)
                Cara(estado: estado, color: Paleta.textoSobreAcento)
                    .frame(width: l * 0.82, height: l * 0.72)
                    .position(x: l / 2, y: l * 0.6)
                MarcaTilde()
                    .fill(Paleta.lenguaTinta)
                    .frame(width: l * 0.2, height: l * 0.24)
                    .rotationEffect(.degrees(estado == .dormido ? 70 : (estado == .anima ? 15 : 0)))
                    .position(x: l * 0.56, y: estado == .celebra ? l * 0.1 : l * 0.17)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - «Cuarto» (Matemáticas)

/// Círculo índigo con un cuarto separado como un sector. Al celebrar, el cuarto se aleja;
/// pensando, gira; dormido, encaja del todo.
struct FiguraCuarto: View {
    let estado: EstadoPersonaje

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            let separacion: CGFloat = switch estado {
            case .celebra, .sorprendido: l * 0.09
            case .dormido: 0
            default: l * 0.05
            }
            ZStack {
                Sector(desde: .degrees(0), hasta: .degrees(270))
                    .fill(Paleta.matematicas)
                    .frame(width: l * 0.8, height: l * 0.8)
                    .position(x: l / 2, y: l / 2)
                Sector(desde: .degrees(270), hasta: .degrees(360))
                    .fill(Paleta.matematicasTinta)
                    .frame(width: l * 0.8, height: l * 0.8)
                    .rotationEffect(.degrees(estado == .pensando ? 12 : 0))
                    .offset(x: separacion, y: -separacion)
                    .position(x: l / 2, y: l / 2)
                Cara(estado: estado, color: Paleta.textoSobreAcento)
                    .frame(width: l * 0.62, height: l * 0.62)
                    .position(x: l * 0.46, y: l * 0.56)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct Sector: Shape {
    let desde: Angle
    let hasta: Angle
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        p.move(to: c)
        p.addArc(center: c, radius: min(r.width, r.height) / 2, startAngle: desde, endAngle: hasta, clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Avatar del usuario

/// Avatar geométrico: forma de color con un accesorio.
struct VistaAvatar: View {
    let avatar: Avatar
    var tamano: CGFloat = 44

    var body: some View {
        ZStack {
            forma.fill(color)
            accesorio
        }
        .frame(width: tamano, height: tamano)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(avatar.nombre)")
    }

    private var color: Color {
        switch avatar.tono {
        case .indigo: Paleta.matematicas
        case .coral: Paleta.lengua
        case .verde: Paleta.exito
        case .ambar: Paleta.recompensa
        }
    }

    private var forma: AnyShape {
        switch avatar.forma {
        case .circulo: AnyShape(Circle())
        case .cuadrado: AnyShape(RoundedRectangle(cornerRadius: tamano * 0.22, style: .continuous))
        case .triangulo: AnyShape(TrianguloRedondeado())
        case .hexagono: AnyShape(Hexagono())
        }
    }

    @ViewBuilder
    private var accesorio: some View {
        let tinta = avatar.tono == .ambar ? Paleta.textoSobreRecompensa : Paleta.textoSobreAcento
        let l = tamano
        switch avatar.accesorio {
        case .gafas:
            HStack(spacing: l * 0.06) {
                Circle().stroke(tinta, lineWidth: max(1.5, l * 0.05)).frame(width: l * 0.24, height: l * 0.24)
                Circle().stroke(tinta, lineWidth: max(1.5, l * 0.05)).frame(width: l * 0.24, height: l * 0.24)
            }
            .offset(y: avatar.forma == .triangulo ? l * 0.12 : 0)
        case .gorro:
            Capsule().fill(tinta).frame(width: l * 0.5, height: l * 0.12).offset(y: avatar.forma == .triangulo ? l * 0.02 : -l * 0.2)
        case .auriculares:
            ZStack {
                ArcoSuperior().stroke(tinta, style: StrokeStyle(lineWidth: max(1.5, l * 0.06), lineCap: .round))
                    .frame(width: l * 0.56, height: l * 0.3)
                    .offset(y: -l * 0.04)
                HStack(spacing: l * 0.44) {
                    Capsule().fill(tinta).frame(width: l * 0.1, height: l * 0.2)
                    Capsule().fill(tinta).frame(width: l * 0.1, height: l * 0.2)
                }
                .offset(y: l * 0.1)
            }
            .offset(y: avatar.forma == .triangulo ? l * 0.12 : 0)
        }
    }
}

private struct TrianguloRedondeado: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.04))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.06))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.06))
        p.closeSubpath()
        return p.strokedPath(StrokeStyle(lineWidth: r.width * 0.08, lineJoin: .round)).union(p)
    }
}

private struct Hexagono: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), radio = min(r.width, r.height) / 2
        for k in 0..<6 {
            let a = Double(k) * .pi / 3 - .pi / 2
            let punto = CGPoint(x: c.x + radio * cos(a), y: c.y + radio * sin(a))
            if k == 0 { p.move(to: punto) } else { p.addLine(to: punto) }
        }
        p.closeSubpath()
        return p
    }
}

private struct ArcoSuperior: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY), radius: r.width / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return p
    }
}
