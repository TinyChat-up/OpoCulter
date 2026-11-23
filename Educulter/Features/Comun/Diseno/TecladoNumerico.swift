import SwiftUI

/// Teclado numérico propio: dígitos, coma, signo menos, barra de fracción y borrar.
/// Nunca se usa el teclado del sistema.
struct TecladoNumerico: View {
    @Binding var texto: String
    var acento: Color = Paleta.matematicas
    var desactivado = false
    /// Longitud máxima del texto.
    var maximo = 12

    private enum Tecla: Hashable {
        case digito(Int), coma, menos, fraccion, borrar

        var etiqueta: String {
            switch self {
            case .digito(let d): "\(d)"
            case .coma: ","
            case .menos: "−"
            case .fraccion: "/"
            case .borrar: ""
            }
        }

        var nombreAccesible: String {
            switch self {
            case .digito(let d): "\(d)"
            case .coma: "Coma decimal"
            case .menos: "Signo menos"
            case .fraccion: "Barra de fracción"
            case .borrar: "Borrar"
            }
        }

        var identificador: String {
            switch self {
            case .digito(let d): "tecla\(d)"
            case .coma: "teclaComa"
            case .menos: "teclaMenos"
            case .fraccion: "teclaFraccion"
            case .borrar: "teclaBorrar"
            }
        }
    }

    private let filas: [[Tecla]] = [
        [.digito(7), .digito(8), .digito(9), .borrar],
        [.digito(4), .digito(5), .digito(6), .menos],
        [.digito(1), .digito(2), .digito(3), .fraccion],
        [.digito(0), .coma],
    ]

    var body: some View {
        Grid(horizontalSpacing: Espacio.s, verticalSpacing: Espacio.s) {
            ForEach(filas.indices, id: \.self) { f in
                GridRow {
                    ForEach(filas[f], id: \.self) { tecla in
                        boton(tecla)
                            .gridCellColumns(tecla == .digito(0) ? 3 : 1)
                    }
                }
            }
        }
        .disabled(desactivado)
        .sensoryFeedback(.selection, trigger: texto)
    }

    private func boton(_ tecla: Tecla) -> some View {
        Button {
            pulsar(tecla)
        } label: {
            Group {
                if tecla == .borrar {
                    Image(systemName: "delete.left")
                } else {
                    Text(tecla.etiqueta)
                }
            }
            .font(.redondeada(.title2))
            .foregroundStyle(Paleta.textoPrincipal)
            .frame(maxWidth: .infinity, minHeight: 52)
            // Teclas de acción con el relleno del área y texto en tinta (D-059).
            .superficiePulsable(esAccion(tecla) ? acento : Paleta.superficie, radio: Radio.ficha)
        }
        .buttonStyle(.pulsable)
        .accessibilityLabel(tecla.nombreAccesible)
        .accessibilityIdentifier(tecla.identificador)
    }

    private func esAccion(_ tecla: Tecla) -> Bool {
        if case .digito = tecla { return false }
        return true
    }

    private func pulsar(_ tecla: Tecla) {
        switch tecla {
        case .borrar:
            if !texto.isEmpty { texto.removeLast() }
        case .menos:
            // El signo alterna al principio del número (o del numerador).
            if texto.hasPrefix("-") { texto.removeFirst() } else if texto.count < maximo { texto = "-" + texto }
        case .coma:
            guard texto.count < maximo, !texto.contains(","), !texto.contains("/") else { return }
            texto += (texto.isEmpty || texto == "-") ? "0," : ","
        case .fraccion:
            guard texto.count < maximo, !texto.contains("/"), !texto.contains(","),
                  texto.last.map({ $0.isNumber }) ?? false else { return }
            texto += "/"
        case .digito(let d):
            guard texto.count < maximo else { return }
            texto += "\(d)"
        }
    }
}
