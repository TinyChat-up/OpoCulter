import UIKit

/// PDF A4 de un simulacro escrito, generado en la app a partir del mismo JSON (05J §2): portada,
/// texto base, preguntas con su id estable (L01…M10) y espacio para responder, con márgenes de
/// impresión. Sin soluciones. Generarlo no empieza el reloj ni registra ningún intento.
enum PDFSimulacro {
    /// A4 en puntos (210 × 297 mm).
    static let pagina = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    /// Márgenes de impresión: 2 cm.
    static let margen: CGFloat = 56.7

    static func generar(_ s: SimulacroOriginal) -> Data {
        let formato = UIGraphicsPDFRendererFormat()
        formato.documentInfo = [kCGPDFContextTitle as String: s.entrada.titulo,
                                kCGPDFContextCreator as String: "Educulter",
                                kCGPDFContextSubject as String: s.etiqueta]
        let renderer = UIGraphicsPDFRenderer(bounds: pagina, format: formato)
        return renderer.pdfData { ctx in
            var y: CGFloat = 0
            var numeroPagina = 0
            let ancho = pagina.width - 2 * margen
            let fondo = pagina.height - margen - 20

            func nuevaPagina() {
                ctx.beginPage()
                numeroPagina += 1
                y = margen
                if numeroPagina > 1 {
                    let pie = "\(s.entrada.titulo) · \(s.etiqueta) · página \(numeroPagina)"
                    (pie as NSString).draw(at: CGPoint(x: margen, y: pagina.height - margen + 8), withAttributes: atributos(8, color: .darkGray))
                }
            }

            /// Dibuja texto partiéndolo en párrafos para que pueda cruzar de página.
            func escribir(_ texto: String, _ attrs: [NSAttributedString.Key: Any], despues: CGFloat = 6) {
                for parrafo in texto.components(separatedBy: "\n") {
                    let a = NSAttributedString(string: parrafo.isEmpty ? " " : parrafo, attributes: attrs)
                    let alto = ceil(a.boundingRect(with: CGSize(width: ancho, height: .greatestFiniteMagnitude),
                                                   options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
                    if y + alto > fondo { nuevaPagina() }
                    a.draw(with: CGRect(x: margen, y: y, width: ancho, height: alto), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    y += alto + 2
                }
                y += despues
            }

            func espacioRespuesta(_ lineas: Int) {
                let alto = CGFloat(lineas) * 22
                if y + alto > fondo { nuevaPagina() }
                let c = ctx.cgContext
                c.setStrokeColor(UIColor.lightGray.cgColor)
                c.setLineWidth(0.5)
                for i in 1...lineas {
                    let ly = y + CGFloat(i) * 22
                    c.move(to: CGPoint(x: margen, y: ly))
                    c.addLine(to: CGPoint(x: margen + ancho, y: ly))
                }
                c.strokePath()
                y += alto + 14
            }

            // Portada.
            nuevaPagina()
            y = margen + 120
            escribir(s.etiqueta.uppercased(), atributos(11, peso: .semibold, color: .darkGray), despues: 10)
            escribir(s.entrada.titulo, atributos(26, peso: .bold, serif: true), despues: 18)
            let mins = s.entrada.minutos
            let n = s.datos.preguntas.count
            escribir("Prueba A1 · Lengua Castellana y Literatura y Matemáticas", atributos(12))
            escribir("\(n) preguntas · \(mins) minutos · puntuación máxima \(CorrectorEscrito.texto(s.maximo).replacingOccurrences(of: ",00", with: "")) puntos", atributos(12), despues: 24)
            escribir("Instrucciones", atributos(13, peso: .semibold))
            escribir("Responda en el espacio de cada pregunta. Identifique cada respuesta con el código de la pregunta (L01, M01…). Cada pregunta vale 0,5 puntos y se corrige con tres criterios.", atributos(11))
            escribir("Las faltas de ortografía se descuentan según las bases de 2026 (BOCM nº 36, 12/02/2026): −0,50 por palabra y −0,25 por tilde.", atributos(11), despues: 30)
            escribir("Material original de Educulter. No es un examen oficial.", atributos(9, color: .darkGray))

            // Texto base.
            nuevaPagina()
            escribir("Texto base", atributos(15, peso: .semibold), despues: 10)
            escribir(s.datos.texto, atributos(12, serif: true), despues: 10)

            // Preguntas.
            for (titulo, preguntas) in [("Lengua Castellana y Literatura", s.datos.lengua), ("Matemáticas", s.datos.matematicas)] where !preguntas.isEmpty {
                nuevaPagina()
                escribir(titulo, atributos(15, peso: .semibold), despues: 10)
                for p in preguntas {
                    if y + 60 > fondo { nuevaPagina() }
                    escribir("\(p.id) · \(CorrectorEscrito.texto(p.maximo)) puntos", atributos(11, peso: .bold), despues: 2)
                    escribir(p.enunciado, atributos(11.5, serif: true), despues: 4)
                    espacioRespuesta(p.area == "MAT" ? 9 : 7)
                }
            }
        }
    }

    static func atributos(_ tamano: CGFloat, peso: UIFont.Weight = .regular, serif: Bool = false, color: UIColor = .black) -> [NSAttributedString.Key: Any] {
        var fuente = UIFont.systemFont(ofSize: tamano, weight: peso)
        if serif, let d = fuente.fontDescriptor.withDesign(.serif) { fuente = UIFont(descriptor: d, size: tamano) }
        let estilo = NSMutableParagraphStyle()
        estilo.lineSpacing = 2
        estilo.hyphenationFactor = 0
        return [.font: fuente, .foregroundColor: color, .paragraphStyle: estilo]
    }

    /// Archivo temporal para compartir o imprimir («La caja de las semillas.pdf»).
    static func archivo(_ s: SimulacroOriginal) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(s.entrada.titulo).pdf")
        try generar(s).write(to: url, options: .atomic)
        return url
    }
}
