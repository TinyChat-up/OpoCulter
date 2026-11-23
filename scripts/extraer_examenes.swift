#!/usr/bin/env swift
// Extrae el texto de los cuadernillos oficiales (docs/examenes/oficiales/*.pdf) a docs/examenes/texto/*.txt.
// Usa la capa de texto del PDF (PDFKit). Si una página no la tiene o es casi vacía (escaneada),
// la rasteriza a 300 ppp y aplica OCR con Vision (VNRecognizeTextRequest, idioma es-ES, nivel preciso).
// Uso: swift scripts/extraer_examenes.swift [carpeta_pdf] [carpeta_salida]
import Foundation
import PDFKit
import Vision
import AppKit

let args = CommandLine.arguments
let entrada = URL(fileURLWithPath: args.count > 1 ? args[1] : "docs/examenes/oficiales")
let salida = URL(fileURLWithPath: args.count > 2 ? args[2] : "docs/examenes/texto")
try FileManager.default.createDirectory(at: salida, withIntermediateDirectories: true)

func ocr(_ pagina: PDFPage) -> String {
    let caja = pagina.bounds(for: .mediaBox)
    let escala: CGFloat = 300.0 / 72.0
    let ancho = Int(caja.width * escala), alto = Int(caja.height * escala)
    guard let ctx = CGContext(data: nil, width: ancho, height: alto, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return "" }
    ctx.setFillColor(.white)
    ctx.fill(CGRect(x: 0, y: 0, width: ancho, height: alto))
    ctx.scaleBy(x: escala, y: escala)
    pagina.draw(with: .mediaBox, to: ctx)
    guard let imagen = ctx.makeImage() else { return "" }
    let peticion = VNRecognizeTextRequest()
    peticion.recognitionLevel = .accurate
    peticion.recognitionLanguages = ["es-ES"]
    peticion.usesLanguageCorrection = true
    try? VNImageRequestHandler(cgImage: imagen).perform([peticion])
    // Orden de lectura: de arriba abajo (Vision usa origen abajo a la izquierda).
    let obs = (peticion.results ?? []).sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
    return obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

let pdfs = try FileManager.default.contentsOfDirectory(at: entrada, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension.lowercased() == "pdf" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
for url in pdfs {
    guard let doc = PDFDocument(url: url) else { print("No se puede abrir \(url.lastPathComponent)"); continue }
    var texto = ""
    var paginasOCR = 0
    for i in 0..<doc.pageCount {
        guard let p = doc.page(at: i) else { continue }
        var t = p.string ?? ""
        if t.trimmingCharacters(in: .whitespacesAndNewlines).count < 80 {
            t = ocr(p)
            paginasOCR += 1
        }
        texto += "\n===== Página \(i + 1) =====\n" + t + "\n"
    }
    let destino = salida.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".txt")
    try texto.write(to: destino, atomically: true, encoding: .utf8)
    print("\(url.lastPathComponent): \(doc.pageCount) páginas, \(paginasOCR) con OCR, \(texto.count) caracteres")
}
