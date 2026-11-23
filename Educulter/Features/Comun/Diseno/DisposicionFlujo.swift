import SwiftUI

/// Disposición en flujo: coloca los elementos en filas y salta de línea cuando no caben.
/// Se usa para tokens de texto, piezas y fichas, y se adapta a Dynamic Type.
struct DisposicionFlujo: Layout {
    var espacioH: CGFloat = Espacio.s
    var espacioV: CGFloat = Espacio.s

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let filas = calcular(ancho: proposal.width ?? .infinity, subviews: subviews)
        let alto = filas.map(\.alto).reduce(0, +) + espacioV * CGFloat(max(filas.count - 1, 0))
        let ancho = filas.map(\.ancho).max() ?? 0
        return CGSize(width: proposal.width ?? ancho, height: alto)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for fila in calcular(ancho: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for (indice, tamano) in fila.elementos {
                subviews[indice].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(tamano))
                x += tamano.width + espacioH
            }
            y += fila.alto + espacioV
        }
    }

    private struct Fila {
        var elementos: [(Int, CGSize)] = []
        var ancho: CGFloat = 0
        var alto: CGFloat = 0
    }

    private func calcular(ancho: CGFloat, subviews: Subviews) -> [Fila] {
        var filas: [Fila] = [Fila()]
        for (i, vista) in subviews.enumerated() {
            var tamano = vista.sizeThatFits(.unspecified)
            if tamano.width > ancho { tamano = vista.sizeThatFits(ProposedViewSize(width: ancho, height: nil)) }
            let necesario = filas[filas.count - 1].elementos.isEmpty ? tamano.width : filas[filas.count - 1].ancho + espacioH + tamano.width
            if necesario > ancho, !filas[filas.count - 1].elementos.isEmpty {
                filas.append(Fila())
            }
            var fila = filas.removeLast()
            fila.ancho = fila.elementos.isEmpty ? tamano.width : fila.ancho + espacioH + tamano.width
            fila.alto = max(fila.alto, tamano.height)
            fila.elementos.append((i, tamano))
            filas.append(fila)
        }
        return filas.filter { !$0.elementos.isEmpty }
    }
}
