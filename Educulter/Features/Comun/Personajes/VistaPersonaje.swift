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

// MARK: - Rasgos comunes Rubber Hose (D-059)

/// Grosor del trazo de tinta de los personajes, proporcional al tamaño (2,5 pt a 64 pt).
private func trazo(_ l: CGFloat) -> CGFloat { max(1.5, l * 0.04) }

/// Ojos ovalados verticales con brillo y boca en tinta. Nada de ojos "de tarta" ni rasgos que
/// recuerden a personajes existentes: óvalos lisos con un punto de luz redondo.
private struct Cara: View {
    let estado: EstadoPersonaje

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            let ojoY = l * 0.42, sepOjos = l * 0.16
            let desvio: CGFloat = estado == .pensando ? l * 0.04 : 0
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { lado in
                    ojo(l: l)
                        .position(x: l / 2 + lado * sepOjos + desvio, y: ojoY - desvio)
                }
                boca(l: l).stroke(Paleta.textoSobreAcento, style: StrokeStyle(lineWidth: trazo(l) * 1.1, lineCap: .round, lineJoin: .round))
                if estado == .sorprendido {
                    Ellipse().fill(Paleta.textoSobreAcento).frame(width: l * 0.11, height: l * 0.14).position(x: l / 2, y: l * 0.68)
                }
            }
        }
    }

    @ViewBuilder
    private func ojo(l: CGFloat) -> some View {
        let tinta = Paleta.textoSobreAcento
        switch estado {
        case .celebra:
            ArcoOjo(abajo: false).stroke(tinta, style: StrokeStyle(lineWidth: trazo(l) * 1.2, lineCap: .round)).frame(width: l * 0.12, height: l * 0.06)
        case .dormido:
            ArcoOjo(abajo: true).stroke(tinta, style: StrokeStyle(lineWidth: trazo(l) * 1.1, lineCap: .round)).frame(width: l * 0.12, height: l * 0.04)
        case .anima:
            ZStack {
                Ellipse().fill(tinta).frame(width: l * 0.08, height: l * 0.11)
                Circle().fill(Paleta.fondo).frame(width: l * 0.03).offset(x: -l * 0.012, y: -l * 0.025)
            }
            .overlay(alignment: .top) {
                // Párpado suave: mirada amable de ánimo.
                Capsule().fill(tinta).frame(width: l * 0.1, height: max(1.5, l * 0.025)).offset(y: -l * 0.012).rotationEffect(.degrees(-8))
            }
        case .sorprendido:
            ZStack {
                Ellipse().fill(Paleta.fondo).frame(width: l * 0.12, height: l * 0.16)
                Ellipse().strokeBorder(tinta, lineWidth: trazo(l)).frame(width: l * 0.12, height: l * 0.16)
                Ellipse().fill(tinta).frame(width: l * 0.05, height: l * 0.07)
            }
        case .neutral, .pensando:
            ZStack {
                Ellipse().fill(tinta).frame(width: l * 0.08, height: l * 0.12)
                Circle().fill(Paleta.fondo).frame(width: l * 0.03).offset(x: -l * 0.012, y: -l * 0.028)
            }
        }
    }

    private func boca(l: CGFloat) -> Path {
        var p = Path()
        let cx = l / 2, y = l * 0.64, ancho = l * 0.14
        switch estado {
        case .celebra:
            // Sonrisa abierta (media luna cerrada).
            p.move(to: CGPoint(x: cx - ancho * 1.2, y: y - l * 0.03))
            p.addQuadCurve(to: CGPoint(x: cx + ancho * 1.2, y: y - l * 0.03), control: CGPoint(x: cx, y: y + l * 0.16))
            p.closeSubpath()
        case .neutral, .anima:
            p.move(to: CGPoint(x: cx - ancho, y: y))
            p.addQuadCurve(to: CGPoint(x: cx + ancho, y: y), control: CGPoint(x: cx, y: y + l * 0.08))
        case .pensando:
            p.move(to: CGPoint(x: cx - ancho * 0.6, y: y + l * 0.02))
            p.addQuadCurve(to: CGPoint(x: cx + ancho * 0.7, y: y), control: CGPoint(x: cx, y: y - l * 0.02))
        case .dormido:
            p.move(to: CGPoint(x: cx - ancho * 0.35, y: y + l * 0.02))
            p.addLine(to: CGPoint(x: cx + ancho * 0.35, y: y + l * 0.02))
        case .sorprendido:
            break
        }
        return p
    }
}

private struct ArcoOjo: Shape {
    /// `false`: ∩ (ojos sonrientes); `true`: ∪ (ojos cerrados).
    let abajo: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: abajo ? r.minY : r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: abajo ? r.minY : r.maxY),
                       control: CGPoint(x: r.midX, y: abajo ? r.maxY + r.height : r.minY - r.height))
        return p
    }
}

/// Pose de brazos y piernas "de manguera" (curvas suaves, sin codos) para cada estado.
/// Coordenadas relativas al lado del personaje (0…1). Los brazos salen de los hombros.
struct PoseManguera: Equatable {
    struct Miembro: Equatable { var fin: CGPoint; var control: CGPoint }
    var brazoIzq: Miembro
    var brazoDer: Miembro
    var piernaIzq: Miembro
    var piernaDer: Miembro

    static func para(_ estado: EstadoPersonaje) -> PoseManguera {
        let reposoI = Miembro(fin: CGPoint(x: 0.08, y: 0.74), control: CGPoint(x: 0.02, y: 0.56))
        let reposoD = Miembro(fin: CGPoint(x: 0.92, y: 0.74), control: CGPoint(x: 0.98, y: 0.56))
        let piernaI = Miembro(fin: CGPoint(x: 0.34, y: 0.95), control: CGPoint(x: 0.30, y: 0.86))
        let piernaD = Miembro(fin: CGPoint(x: 0.66, y: 0.95), control: CGPoint(x: 0.70, y: 0.86))
        switch estado {
        case .neutral:
            return PoseManguera(brazoIzq: reposoI, brazoDer: reposoD, piernaIzq: piernaI, piernaDer: piernaD)
        case .celebra:
            // Brazos arriba y piernas abiertas: salto.
            return PoseManguera(brazoIzq: Miembro(fin: CGPoint(x: 0.06, y: 0.16), control: CGPoint(x: -0.02, y: 0.44)),
                                brazoDer: Miembro(fin: CGPoint(x: 0.94, y: 0.16), control: CGPoint(x: 1.02, y: 0.44)),
                                piernaIzq: Miembro(fin: CGPoint(x: 0.24, y: 0.94), control: CGPoint(x: 0.34, y: 0.90)),
                                piernaDer: Miembro(fin: CGPoint(x: 0.76, y: 0.94), control: CGPoint(x: 0.66, y: 0.90)))
        case .anima:
            // Un brazo en alto, como quien dice "¡vamos!".
            return PoseManguera(brazoIzq: reposoI,
                                brazoDer: Miembro(fin: CGPoint(x: 0.96, y: 0.26), control: CGPoint(x: 1.04, y: 0.52)),
                                piernaIzq: piernaI, piernaDer: piernaD)
        case .pensando:
            // Mano en la barbilla.
            return PoseManguera(brazoIzq: reposoI,
                                brazoDer: Miembro(fin: CGPoint(x: 0.62, y: 0.70), control: CGPoint(x: 1.0, y: 0.82)),
                                piernaIzq: piernaI, piernaDer: piernaD)
        case .sorprendido:
            return PoseManguera(brazoIzq: Miembro(fin: CGPoint(x: 0.0, y: 0.38), control: CGPoint(x: 0.10, y: 0.36)),
                                brazoDer: Miembro(fin: CGPoint(x: 1.0, y: 0.38), control: CGPoint(x: 0.90, y: 0.36)),
                                piernaIzq: piernaI, piernaDer: piernaD)
        case .dormido:
            return PoseManguera(brazoIzq: Miembro(fin: CGPoint(x: 0.16, y: 0.86), control: CGPoint(x: 0.08, y: 0.70)),
                                brazoDer: Miembro(fin: CGPoint(x: 0.84, y: 0.86), control: CGPoint(x: 0.92, y: 0.70)),
                                piernaIzq: Miembro(fin: CGPoint(x: 0.30, y: 0.95), control: CGPoint(x: 0.36, y: 0.90)),
                                piernaDer: Miembro(fin: CGPoint(x: 0.70, y: 0.95), control: CGPoint(x: 0.64, y: 0.90)))
        }
    }
}

/// Brazos y piernas de manguera con manos redondas (del color del cuerpo, no guantes) y zapatos
/// ovalados en tinta. Se dibujan detrás del cuerpo.
private struct Extremidades: View {
    let pose: PoseManguera
    let color: Color
    var hombroY: CGFloat = 0.5
    var caderaY: CGFloat = 0.78

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            let p: (CGPoint) -> CGPoint = { CGPoint(x: $0.x * l, y: $0.y * l) }
            let manguera = StrokeStyle(lineWidth: max(2.5, l * 0.07), lineCap: .round)
            let hombros = [CGPoint(x: 0.24, y: hombroY), CGPoint(x: 0.76, y: hombroY)]
            let caderas = [CGPoint(x: 0.40, y: caderaY), CGPoint(x: 0.60, y: caderaY)]
            let brazos = [pose.brazoIzq, pose.brazoDer], piernas = [pose.piernaIzq, pose.piernaDer]
            ZStack {
                ForEach(0..<2, id: \.self) { i in
                    curva(desde: p(caderas[i]), piernas[i], l: l).stroke(Paleta.textoSobreAcento, style: manguera)
                    Ellipse().fill(Paleta.textoSobreAcento)
                        .frame(width: l * 0.15, height: l * 0.08)
                        .position(x: piernas[i].fin.x * l + (i == 0 ? -l * 0.03 : l * 0.03), y: piernas[i].fin.y * l - l * 0.01)
                    // Brazo: trazo de tinta con relleno del color del cuerpo (manguera con contorno).
                    curva(desde: p(hombros[i]), brazos[i], l: l)
                        .stroke(Paleta.textoSobreAcento, style: StrokeStyle(lineWidth: max(4, l * 0.1), lineCap: .round))
                    curva(desde: p(hombros[i]), brazos[i], l: l)
                        .stroke(color, style: StrokeStyle(lineWidth: max(2, l * 0.1 - trazo(l) * 2), lineCap: .round))
                    Circle().fill(color)
                        .overlay(Circle().strokeBorder(Paleta.textoSobreAcento, lineWidth: trazo(l)))
                        .frame(width: l * 0.13, height: l * 0.13)
                        .position(p(brazos[i].fin))
                }
            }
        }
    }

    private func curva(desde inicio: CGPoint, _ m: PoseManguera.Miembro, l: CGFloat) -> Path {
        var camino = Path()
        camino.move(to: inicio)
        camino.addQuadCurve(to: CGPoint(x: m.fin.x * l, y: m.fin.y * l), control: CGPoint(x: m.control.x * l, y: m.control.y * l))
        return camino
    }
}

// MARK: - «Tilde» (Lengua)

/// Cuerpo de goma coral con contorno de tinta y una tilde (acento agudo) en la cabeza. Al
/// celebrar, la tilde salta; al animar, se inclina hacia delante; dormido, cae tumbada.
struct FiguraTilde: View {
    let estado: EstadoPersonaje

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            let cuerpo = RoundedRectangle(cornerRadius: l * 0.26, style: .continuous)
            ZStack {
                Extremidades(pose: .para(estado), color: Paleta.lengua)
                cuerpo.fill(Paleta.lengua)
                    .overlay(cuerpo.strokeBorder(Paleta.textoSobreAcento, lineWidth: trazo(l)))
                    .frame(width: l * 0.6, height: l * 0.56)
                    .position(x: l / 2, y: l * 0.53)
                Cara(estado: estado)
                    .frame(width: l * 0.6, height: l * 0.56)
                    .position(x: l / 2, y: l * 0.53)
                MarcaTilde()
                    .fill(Paleta.recompensa)
                    .overlay(MarcaTilde().stroke(Paleta.textoSobreAcento, style: StrokeStyle(lineWidth: trazo(l) * 0.8, lineJoin: .round)))
                    .frame(width: l * 0.16, height: l * 0.2)
                    .rotationEffect(.degrees(estado == .dormido ? 70 : (estado == .anima ? 15 : 0)))
                    .position(x: l * 0.56, y: estado == .celebra ? l * 0.08 : l * 0.15)
            }
            .rotationEffect(.degrees(estado == .dormido ? -6 : 0), anchor: .bottom)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - «Cuarto» (Matemáticas)

/// Círculo azul cielo de goma con contorno de tinta y un cuarto separado como un sector. Al
/// celebrar, el cuarto se aleja; pensando, gira; dormido, encaja del todo.
struct FiguraCuarto: View {
    let estado: EstadoPersonaje

    var body: some View {
        GeometryReader { geo in
            let l = min(geo.size.width, geo.size.height)
            let separacion: CGFloat = switch estado {
            case .celebra, .sorprendido: l * 0.07
            case .dormido: 0
            default: l * 0.04
            }
            let linea = StrokeStyle(lineWidth: trazo(l), lineJoin: .round)
            ZStack {
                Extremidades(pose: .para(estado), color: Paleta.matematicas, hombroY: 0.52, caderaY: 0.8)
                Sector(desde: .degrees(0), hasta: .degrees(270))
                    .fill(Paleta.matematicas)
                    .overlay(Sector(desde: .degrees(0), hasta: .degrees(270)).stroke(Paleta.textoSobreAcento, style: linea))
                    .frame(width: l * 0.62, height: l * 0.62)
                    .position(x: l / 2, y: l * 0.52)
                Sector(desde: .degrees(270), hasta: .degrees(360))
                    .fill(Paleta.recompensa)
                    .overlay(Sector(desde: .degrees(270), hasta: .degrees(360)).stroke(Paleta.textoSobreAcento, style: linea))
                    .frame(width: l * 0.62, height: l * 0.62)
                    .rotationEffect(.degrees(estado == .pensando ? 12 : 0))
                    .offset(x: separacion, y: -separacion)
                    .position(x: l / 2, y: l * 0.52)
                Cara(estado: estado)
                    .frame(width: l * 0.5, height: l * 0.5)
                    .position(x: l * 0.46, y: l * 0.58)
            }
            .rotationEffect(.degrees(estado == .dormido ? -6 : 0), anchor: .bottom)
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

/// Avatar del propietario recortado en círculo, con contorno de tinta (Rubber Hose).
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
            .overlay(Circle().strokeBorder(Paleta.contorno, lineWidth: tamano < 48 ? Trazo.fino : Trazo.grueso))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Avatar con \(avatar.nombre)")
    }
}
