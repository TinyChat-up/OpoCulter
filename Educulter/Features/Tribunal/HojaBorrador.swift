import PencilKit
import SwiftUI

/// Borrador táctil (05I §4): PencilKit en una hoja inferior de dos alturas, con cuadrícula de
/// cuaderno, lápiz, goma, deshacer y borrar todo, y una copia fija del enunciado arriba. Con la hoja
/// cerrada no captura gestos. No cuenta como pista.
struct HojaBorrador: View {
    let enunciado: String
    @Binding var dibujo: Data
    @State private var lienzo = PKCanvasView()
    @State private var goma = false
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            HStack {
                Text("Borrador").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Cerrar") { guardar(); cerrar() }.accessibilityIdentifier("botonCerrarBorrador")
            }
            Text(enunciado)
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(Paleta.textoSecundario)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Enunciado: \(enunciado)")
            HStack(spacing: Espacio.s) {
                herramienta("Lápiz", icono: "pencil", activa: !goma) { goma = false; aplicarHerramienta() }
                herramienta("Goma", icono: "eraser", activa: goma) { goma = true; aplicarHerramienta() }
                Spacer()
                Button { lienzo.undoManager?.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .accessibilityLabel("Deshacer").frame(minWidth: Medidas.tactilMinimo, minHeight: Medidas.tactilMinimo)
                Button(role: .destructive) { lienzo.drawing = PKDrawing(); guardar() } label: { Image(systemName: "trash") }
                    .accessibilityLabel("Borrar todo").frame(minWidth: Medidas.tactilMinimo, minHeight: Medidas.tactilMinimo)
                    .accessibilityIdentifier("botonBorrarBorrador")
            }
            LienzoBorrador(lienzo: lienzo, dibujo: dibujo) { guardar() }
                .background(CuadriculaCuaderno())
                .clipShape(RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous).strokeBorder(Paleta.borde, lineWidth: Trazo.fino))
                .accessibilityLabel("Hoja de borrador: escribe o dibuja con el dedo")
                .accessibilityIdentifier("lienzoBorrador")
        }
        .padding(Espacio.l)
        .background(Paleta.superficie.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: aplicarHerramienta)
        .onDisappear(perform: guardar)
    }

    private func herramienta(_ nombre: String, icono: String, activa: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Label(nombre, systemImage: icono).font(.subheadline.weight(activa ? .semibold : .regular))
        }
        .buttonStyle(EstiloBotonSecundario(acento: activa ? Paleta.primario : Paleta.textoSecundario))
        .accessibilityAddTraits(activa ? .isSelected : [])
    }

    private func aplicarHerramienta() {
        lienzo.tool = goma ? PKEraserTool(.vector) : PKInkingTool(.pencil, color: UIColor(Paleta.textoPrincipal), width: 3)
    }

    private func guardar() { dibujo = lienzo.drawing.dataRepresentation() }
}

/// El lienzo de PencilKit (con el dedo: no exige Apple Pencil).
private struct LienzoBorrador: UIViewRepresentable {
    let lienzo: PKCanvasView
    let dibujo: Data
    let cambio: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        lienzo.drawingPolicy = .anyInput
        lienzo.backgroundColor = .clear
        lienzo.isOpaque = false
        lienzo.drawing = (try? PKDrawing(data: dibujo)) ?? PKDrawing()
        lienzo.delegate = context.coordinator
        return lienzo
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(cambio: cambio) }

    final class Coordinador: NSObject, PKCanvasViewDelegate {
        let cambio: () -> Void
        init(cambio: @escaping () -> Void) { self.cambio = cambio }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) { cambio() }
    }
}

/// Cuadrícula de cuaderno (cuadros de 20 pt).
struct CuadriculaCuaderno: View {
    var body: some View {
        Canvas { c, tam in
            var p = Path()
            var x: CGFloat = 0
            while x <= tam.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: tam.height)); x += 20 }
            var y: CGFloat = 0
            while y <= tam.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: tam.width, y: y)); y += 20 }
            c.stroke(p, with: .color(Paleta.borde.opacity(0.5)), lineWidth: 0.5)
        }
        .background(Paleta.fondo)
        .accessibilityHidden(true)
    }
}
