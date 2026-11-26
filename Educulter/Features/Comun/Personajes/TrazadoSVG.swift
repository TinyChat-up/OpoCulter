import SwiftUI

/// Intérprete del subconjunto de SVG que usan los dibujos de la dirección (`docs/arte/v3/`, ANEXO A
/// de la 05E parte 2): órdenes `M L C Q Z` (absolutas) y `l z` (relativas), con comas o espacios.
/// Así cada pieza de un personaje o de la marca se dibuja con los datos exactos del SVG.
enum TrazadoSVG {
    /// Path en el sistema de coordenadas del SVG (sin escalar).
    static func path(_ d: String) -> Path {
        var p = Path()
        let tokens = separar(d)
        var i = 0
        var orden: Character = "M"
        var actual = CGPoint.zero, inicio = CGPoint.zero
        func numero() -> CGFloat {
            guard i < tokens.count, case .numero(let n) = tokens[i] else { return 0 }
            i += 1
            return n
        }
        func punto() -> CGPoint { let x = numero(); return CGPoint(x: x, y: numero()) }
        while i < tokens.count {
            if case .orden(let o) = tokens[i] {
                orden = o
                i += 1
                if o == "Z" || o == "z" { p.closeSubpath(); actual = inicio }
                continue
            }
            // Números tras una orden (o repetición implícita de la anterior).
            switch orden {
            case "M":
                actual = punto(); inicio = actual; p.move(to: actual); orden = "L"
            case "L":
                actual = punto(); p.addLine(to: actual)
            case "l":
                let d = punto(); actual = CGPoint(x: actual.x + d.x, y: actual.y + d.y); p.addLine(to: actual)
            case "C":
                let c1 = punto(), c2 = punto(); actual = punto(); p.addCurve(to: actual, control1: c1, control2: c2)
            case "Q":
                let c = punto(); actual = punto(); p.addQuadCurve(to: actual, control: c)
            default:
                i += 1
            }
        }
        return p
    }

    private enum Token: Equatable { case orden(Character), numero(CGFloat) }

    private static func separar(_ d: String) -> [Token] {
        var tokens: [Token] = []
        var actual = ""
        func cerrar() { if let v = Double(actual) { tokens.append(.numero(CGFloat(v))) }; actual = "" }
        for c in d {
            if "MLCQZmlcqz".contains(c) { cerrar(); tokens.append(.orden(c)) }
            else if c == "," || c == " " || c == "\n" { cerrar() }
            else if c == "-" && !actual.isEmpty && actual.last != "e" { cerrar(); actual = "-" }
            else { actual.append(c) }
        }
        cerrar()
        return tokens
    }
}

/// Forma de una pieza: trazado SVG, elipse o círculo.
enum FormaPieza: Sendable, Equatable {
    case trazado(String)
    case elipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat)

    var path: Path {
        switch self {
        case .trazado(let d): TrazadoSVG.path(d)
        case .elipse(let cx, let cy, let rx, let ry): Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
        }
    }

    static func circulo(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> FormaPieza { .elipse(cx: cx, cy: cy, rx: r, ry: r) }
}

/// Pieza de un dibujo: forma, relleno y trazo opcionales (colores en hexadecimal del SVG).
struct PiezaSVG: Sendable, Equatable {
    var forma: FormaPieza
    var relleno: UInt32?
    var trazo: UInt32? = nil
    var grosor: CGFloat = 0
    /// Contorno de silueta en modo oscuro (Rubber Hose en tinta): solo cuerpo y extremidades.
    var silueta = false
}

/// Grupo con nombre (los `id` del SVG): la unidad que se anima.
struct GrupoSVG: Sendable, Equatable {
    var id: String
    var piezas: [PiezaSVG]
    /// Punto de anclaje para rotar o escalar el grupo (en coordenadas del SVG).
    var ancla: CGPoint
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

/// Dibuja un grupo escalado al tamaño de la vista (el SVG mide `lienzo`).
struct VistaGrupoSVG: View {
    let grupo: GrupoSVG
    let lienzo: CGSize
    var siluetaOscura = false
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Canvas { ctx, tam in
            let escala = min(tam.width / lienzo.width, tam.height / lienzo.height)
            let desplazamiento = CGPoint(x: (tam.width - lienzo.width * escala) / 2, y: (tam.height - lienzo.height * escala) / 2)
            ctx.translateBy(x: desplazamiento.x, y: desplazamiento.y)
            ctx.scaleBy(x: escala, y: escala)
            for pieza in grupo.piezas {
                let path = pieza.forma.path
                if let r = pieza.relleno { ctx.fill(path, with: .color(Color(hex: r))) }
                if let t = pieza.trazo, pieza.grosor > 0 {
                    ctx.stroke(path, with: .color(Color(hex: t)), style: StrokeStyle(lineWidth: pieza.grosor, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
