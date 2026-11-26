// Uso: swift scripts/marca_lanzamiento.swift <carpeta del imageset>
// Dibuja la imagen de la pantalla de lanzamiento (05E parte 2, D-109): la marca v5
// (docs/arte/v5/marca.svg, cuadrícula de cuatro módulos) y, debajo, una banda de rayas verticales
// salvia y bosque como textura. Genera la variante clara y la oscura a @3x, con fondo transparente
// (el color de fondo lo pone UILaunchScreen con el token Fondo).
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let escala: CGFloat = 3
let ladoMarca: CGFloat = 160          // pt
let separacion: CGFloat = 36          // pt entre la marca y la banda
let banda = CGSize(width: 160, height: 14)
let rayas = 16
let lienzo = CGSize(width: ladoMarca, height: ladoMarca + separacion + banda.height)

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// Módulos de marca.svg en el lienzo 500 × 500 (viewBox 262 262 500 500 trasladado), en coordenadas
/// con el eje y hacia abajo.
func modulos() -> [(CGPath, Bool)] {
    let arribaIzq = CGMutablePath()
    arribaIzq.move(to: CGPoint(x: 10, y: 230))
    arribaIzq.addArc(center: CGPoint(x: 230, y: 230), radius: 220, startAngle: .pi, endAngle: 1.5 * .pi, clockwise: false)
    arribaIzq.addLine(to: CGPoint(x: 230, y: 230))
    arribaIzq.closeSubpath()
    let abajoDer = CGMutablePath()
    abajoDer.move(to: CGPoint(x: 270, y: 270))
    abajoDer.addLine(to: CGPoint(x: 490, y: 270))
    abajoDer.addArc(center: CGPoint(x: 270, y: 270), radius: 220, startAngle: 0, endAngle: 0.5 * .pi, clockwise: false)
    abajoDer.closeSubpath()
    let arribaDer = CGPath(roundedRect: CGRect(x: 270, y: 10, width: 220, height: 220), cornerWidth: 30, cornerHeight: 30, transform: nil)
    let abajoIzq = CGPath(roundedRect: CGRect(x: 10, y: 270, width: 220, height: 220), cornerWidth: 30, cornerHeight: 30, transform: nil)
    return [(arribaIzq, true), (arribaDer, false), (abajoIzq, false), (abajoDer, true)]
}

func dibujar(tinta: UInt32, salvia: UInt32, bosque: UInt32, salida: URL) {
    let w = Int(lienzo.width * escala), h = Int(lienzo.height * escala)
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Eje y hacia abajo, en puntos.
    ctx.translateBy(x: 0, y: CGFloat(h))
    ctx.scaleBy(x: escala, y: -escala)
    ctx.saveGState()
    ctx.scaleBy(x: ladoMarca / 500, y: ladoMarca / 500)
    for (path, esSalvia) in modulos() {
        ctx.addPath(path)
        ctx.setFillColor(color(esSalvia ? salvia : tinta))
        ctx.fillPath()
    }
    ctx.restoreGState()
    let y = ladoMarca + separacion
    let ancho = banda.width / CGFloat(rayas)
    let x0 = (lienzo.width - banda.width) / 2
    for i in 0..<rayas {
        ctx.setFillColor(color(i % 2 == 0 ? salvia : bosque))
        ctx.fill(CGRect(x: x0 + CGFloat(i) * ancho, y: y, width: ancho, height: banda.height))
    }
    let img = ctx.makeImage()!
    let destino = CGImageDestinationCreateWithURL(salida as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destino, img, nil)
    CGImageDestinationFinalize(destino)
    print("\(salida.lastPathComponent): \(img.width)×\(img.height)")
}

let a = CommandLine.arguments
guard a.count == 2 else { print("Uso: marca_lanzamiento.swift <carpeta del imageset>"); exit(1) }
let carpeta = URL(fileURLWithPath: a[1])
dibujar(tinta: 0x16241F, salvia: 0xA9BD9F, bosque: 0x2F4A40, salida: carpeta.appendingPathComponent("marca@3x.png"))
dibujar(tinta: 0xE7F0E0, salvia: 0x8FA685, bosque: 0xA9BD9F, salida: carpeta.appendingPathComponent("marca_oscura@3x.png"))
