// Compone una hoja de contactos (cuadrícula con nombre) con todas las PNG de una carpeta.
// Uso: swift scripts/hoja_contactos.swift <carpeta> <salida.png>
import AppKit

let args = CommandLine.arguments
guard args.count == 3 else { print("Uso: hoja_contactos.swift <carpeta> <salida.png>"); exit(1) }
let carpeta = URL(fileURLWithPath: args[1]), salida = URL(fileURLWithPath: args[2])
let archivos = try FileManager.default.contentsOfDirectory(at: carpeta, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "png" && $0.lastPathComponent != salida.lastPathComponent }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

let columnas = 6, anchoMini: CGFloat = 260, margen: CGFloat = 24, alturaTexto: CGFloat = 36
let imagenes = archivos.compactMap { url in NSImage(contentsOf: url).map { (url.deletingPathExtension().lastPathComponent, $0) } }
let proporcion = imagenes.first.map { $0.1.size.height / $0.1.size.width } ?? 2.17
let altoMini = anchoMini * proporcion
let filas = Int((Double(imagenes.count) / Double(columnas)).rounded(.up))
let ancho = CGFloat(columnas) * (anchoMini + margen) + margen
let alto = CGFloat(filas) * (altoMini + alturaTexto + margen) + margen + 60

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(ancho), pixelsHigh: Int(alto), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor(white: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: ancho, height: alto).fill()
// Título a partir de la carpeta: "fase05a1" → "Fase 05A.1".
let nombreCarpeta = carpeta.lastPathComponent
var fase = nombreCarpeta
if nombreCarpeta.hasPrefix("fase") {
    let codigo = String(nombreCarpeta.dropFirst(4)).uppercased()
    fase = "Fase " + (codigo.count > 3 ? String(codigo.prefix(3)) + "." + String(codigo.dropFirst(3)) : codigo)
}
let titulo = "Educulter · \(fase) · \(imagenes.count) capturas (iPhone 16)" as NSString
titulo.draw(at: NSPoint(x: margen, y: alto - 44), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 22), .foregroundColor: NSColor.black])
let estilo = NSMutableParagraphStyle(); estilo.alignment = .center
for (i, (nombre, imagen)) in imagenes.enumerated() {
    let f = i / columnas, c = i % columnas
    let x = margen + CGFloat(c) * (anchoMini + margen)
    let y = alto - 60 - CGFloat(f + 1) * (altoMini + alturaTexto + margen)
    let marco = NSRect(x: x, y: y + alturaTexto, width: anchoMini, height: altoMini)
    imagen.draw(in: marco)
    NSColor(white: 0.7, alpha: 1).setStroke()
    NSBezierPath(rect: marco).stroke()
    (nombre as NSString).draw(in: NSRect(x: x, y: y + 6, width: anchoMini, height: alturaTexto - 6),
                              withAttributes: [.font: NSFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: NSColor.black, .paragraphStyle: estilo])
}
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: salida)
print("Hoja: \(salida.path) (\(imagenes.count) capturas, \(Int(ancho))×\(Int(alto)))")
