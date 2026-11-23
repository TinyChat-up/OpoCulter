#!/usr/bin/env swift
// Recorta los 6 avatares del propietario (docs/arte/avatares_propietario.png, cuadrícula 3 × 2 de
// círculos sobre fondo crema) y los exporta con máscara circular y fondo transparente a
// Assets.xcassets/Avatares/avatar_01…06 (@2x 160 px, @3x 240 px; 80 pt en pantalla).
//
// Detección (reproducible, sin parámetros a mano por avatar):
//  1. Cada celda de la cuadrícula se amplía un 8 % en horizontal (los círculos rozan el borde
//     lateral); en vertical no, porque la ropa del avatar de arriba entraría en la celda de abajo.
//  2. Color del disco = el tono saturado más frecuente en una corona exterior de la celda
//     (entre el 78 % y el 96 % del semilado), donde predomina el disco y no el personaje.
//  3. Extremos izquierdo, derecho y superior de los píxeles de ese color → centro y radio
//     (el inferior no sirve: la ropa del personaje llega al borde del círculo).
//  4. Máscara circular con 2 px de margen hacia dentro y borde suavizado de 1,5 px.
// Uso: swift scripts/recortar_avatares.swift [imagen] [carpeta_assets]
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
let rutaImagen = args.count > 1 ? args[1] : "docs/arte/avatares_propietario.png"
let carpeta = URL(fileURLWithPath: args.count > 2 ? args[2] : "Educulter/Resources/Assets.xcassets/Avatares")

guard let fuente = CGImageSourceCreateWithURL(URL(fileURLWithPath: rutaImagen) as CFURL, nil),
      let original = CGImageSourceCreateImageAtIndex(fuente, 0, nil) else { fatalError("No se puede leer \(rutaImagen)") }
let ancho = original.width, alto = original.height
var px = [UInt8](repeating: 0, count: ancho * alto * 4)
let espacio = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: &px, width: ancho, height: alto, bitsPerComponent: 8, bytesPerRow: ancho * 4,
                    space: espacio, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(original, in: CGRect(x: 0, y: 0, width: ancho, height: alto))

func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
    let i = (y * ancho + x) * 4 // y = 0 es la fila superior en este búfer
    return (Int(px[i]), Int(px[i + 1]), Int(px[i + 2]))
}
func saturacion(_ c: (Int, Int, Int)) -> Int { max(c.0, c.1, c.2) - min(c.0, c.1, c.2) }

struct Circulo { var cx: Double; var cy: Double; var r: Double }
var circulos: [Circulo] = []
let (cols, filas) = (3, 2)
for fila in 0..<filas {
    for col in 0..<cols {
        let cw = Double(ancho) / Double(cols), ch = Double(alto) / Double(filas)
        let x0 = max(0, Int(Double(col) * cw - cw * 0.08)), x1 = min(ancho - 1, Int(Double(col + 1) * cw + cw * 0.08))
        let y0 = Int(Double(fila) * ch), y1 = min(alto - 1, Int(Double(fila + 1) * ch) - 1)
        // Histograma de tonos saturados (cuantizado a 16 niveles por canal) en la corona exterior.
        var hist: [Int: Int] = [:]
        let (ccx, ccy) = ((Double(col) + 0.5) * cw, (Double(fila) + 0.5) * ch)
        let semilado = min(cw, ch) / 2
        for y in stride(from: y0, through: y1, by: 2) {
            for x in stride(from: Int(Double(col) * cw), to: Int(Double(col + 1) * cw), by: 2) {
                let d = hypot(Double(x) - ccx, Double(y) - ccy) / semilado
                guard d > 0.78 && d < 0.96 else { continue }
                let c = rgb(x, y)
                guard saturacion(c) > 70 else { continue }
                hist[(c.0 >> 4) << 8 | (c.1 >> 4) << 4 | (c.2 >> 4), default: 0] += 1
            }
        }
        let clave = hist.max { $0.value < $1.value }!.key
        let disco = ((clave >> 8 & 15) * 16 + 8, (clave >> 4 & 15) * 16 + 8, (clave & 15) * 16 + 8)
        func esDisco(_ c: (Int, Int, Int)) -> Bool {
            abs(c.0 - disco.0) + abs(c.1 - disco.1) + abs(c.2 - disco.2) < 60
        }
        var minX = Int.max, maxX = Int.min, minY = Int.max
        for y in y0...y1 {
            for x in x0...x1 where esDisco(rgb(x, y)) {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y)
            }
        }
        let r = Double(maxX - minX + 1) / 2
        let c = Circulo(cx: Double(minX + maxX) / 2 + 0.5, cy: Double(minY) + r, r: r)
        circulos.append(c)
        print(String(format: "avatar_%02d: disco RGB(%d,%d,%d) centro (%.1f, %.1f) radio %.1f",
                     circulos.count, disco.0, disco.1, disco.2, c.cx, c.cy, c.r))
    }
}

func png(_ circulo: Circulo, lado: Int) -> Data {
    let out = CGContext(data: nil, width: lado, height: lado, bitsPerComponent: 8, bytesPerRow: 0,
                        space: espacio, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    out.interpolationQuality = .high
    let r = circulo.r - 2 // margen hacia dentro para no arrastrar el halo crema
    let escala = Double(lado) / (2 * r)
    // Máscara circular suavizada.
    out.addEllipse(in: CGRect(x: 0, y: 0, width: lado, height: lado).insetBy(dx: 0.75, dy: 0.75))
    out.clip()
    // Dibujar la imagen completa desplazada: el origen de CoreGraphics está abajo a la izquierda.
    let destino = CGRect(x: -(circulo.cx - r) * escala,
                         y: -(Double(alto) - (circulo.cy + r)) * escala,
                         width: Double(ancho) * escala, height: Double(alto) * escala)
    out.draw(original, in: destino)
    let datos = NSMutableData()
    let dest = CGImageDestinationCreateWithData(datos, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, out.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    return datos as Data
}

let fm = FileManager.default
try fm.createDirectory(at: carpeta, withIntermediateDirectories: true)
try #"{"info":{"author":"xcode","version":1},"properties":{"provides-namespace":false}}"#
    .write(to: carpeta.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
for (i, c) in circulos.enumerated() {
    let nombre = String(format: "avatar_%02d", i + 1)
    let set = carpeta.appendingPathComponent("\(nombre).imageset")
    try fm.createDirectory(at: set, withIntermediateDirectories: true)
    try png(c, lado: 160).write(to: set.appendingPathComponent("\(nombre)@2x.png"))
    try png(c, lado: 240).write(to: set.appendingPathComponent("\(nombre)@3x.png"))
    let contents = """
    {
      "images" : [
        { "idiom" : "universal", "scale" : "1x" },
        { "filename" : "\(nombre)@2x.png", "idiom" : "universal", "scale" : "2x" },
        { "filename" : "\(nombre)@3x.png", "idiom" : "universal", "scale" : "3x" }
      ],
      "info" : { "author" : "xcode", "version" : 1 }
    }
    """
    try contents.write(to: set.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}
print("Exportados \(circulos.count) avatares en \(carpeta.path)")
