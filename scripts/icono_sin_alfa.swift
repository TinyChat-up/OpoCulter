// Uso: swift scripts/icono_sin_alfa.swift <entrada.png> <salida.png>
// Redibuja un PNG en un contexto RGB opaco (sin canal alfa) de 1024 × 1024: el icono de la app debe
// ser opaco y a sangre completa (05E parte 2, §2.3). La entrada es el rasterizado de qlmanage del SVG.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count == 3, let fuente = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(fuente, 0, nil) else { print("Uso: icono_sin_alfa.swift <entrada.png> <salida.png>"); exit(1) }
let lado = 1024
guard let ctx = CGContext(data: nil, width: lado, height: lado, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(2) }
ctx.interpolationQuality = .high
ctx.draw(img, in: CGRect(x: 0, y: 0, width: lado, height: lado))
let salida = ctx.makeImage()!
let destino = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destino, salida, nil)
CGImageDestinationFinalize(destino)
print("\(a[2]): \(salida.width)×\(salida.height), alfa: \(salida.alphaInfo == .none || salida.alphaInfo == .noneSkipLast ? "no" : "sí")")
