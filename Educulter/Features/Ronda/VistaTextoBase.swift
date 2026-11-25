import SwiftUI

/// Panel del texto base de un ítem de comprensión (D-085). Va encima del enunciado, en una
/// superficie neutra (el panel tintado sigue siendo el de la mecánica). Desplegado ocupa como
/// mucho `altoMaximo` y el texto se desplaza dentro, de modo que el ítem se responde debajo sin
/// perder el texto de vista. Plegado queda una pestaña «Ver texto».
struct VistaTextoBase: View {
    let texto: TextoBase
    /// Año de la obra según la base literaria (solo textos literarios).
    let anio: Int?
    @Binding var plegado: Bool
    /// Alto máximo del panel desplegado (el resto de la pantalla es para el ítem).
    var altoMaximo: CGFloat = 280
    /// Sin pestaña de plegar (vistas de repaso, donde el texto va dentro del propio scroll).
    var plegable = true

    @Environment(\.accessibilityReduceMotion) private var reducir
    /// Alto del texto completo: el panel se ajusta a él y solo se desplaza si supera el máximo.
    @State private var altoTexto: CGFloat = 0

    /// «Autor · Obra (año)» de un texto literario.
    nonisolated static func referencia(_ t: TextoBase, anio: Int?) -> String? {
        guard t.esLiterario, let autor = t.autor else { return nil }
        var partes = [autor]
        if let obra = t.obra { partes.append(anio.map { "\(obra) (\($0))" } ?? obra) } else if let anio { partes.append("\(anio)") }
        return partes.joined(separator: " · ")
    }

    var body: some View {
        if plegado && plegable {
            Button {
                cambiar(false)
            } label: {
                Label("Ver texto", systemImage: "doc.text")
                    .font(.redondeada(.subheadline))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .padding(.horizontal, Espacio.l)
                    .frame(minHeight: Medidas.tactilMinimo)
                    .background(Paleta.superficie, in: Capsule())
                    .contornoTinta(radio: Medidas.tactilMinimo / 2)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Ver texto: \(texto.titulo)")
            .accessibilityHint("Muestra el texto en el que se basa la pregunta")
            .accessibilityIdentifier("botonVerTexto")
        } else {
            TarjetaSuperficie(relleno: Espacio.m) {
                VStack(alignment: .leading, spacing: Espacio.s) {
                    HStack(alignment: .top, spacing: Espacio.s) {
                        VStack(alignment: .leading, spacing: Espacio.xs) {
                            Text(texto.titulo)
                                .font(.exhibicion(.headline))
                                .foregroundStyle(Paleta.textoPrincipal)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("tituloTextoBase")
                            if let ref = Self.referencia(texto, anio: anio) {
                                Text(ref)
                                    .font(.subheadline)
                                    .foregroundStyle(Paleta.textoSecundario)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityIdentifier("autorTextoBase")
                            }
                        }
                        Spacer(minLength: 0)
                        if plegable {
                            Button {
                                cambiar(true)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.headline)
                                    .foregroundStyle(Paleta.textoSecundario)
                                    .frame(width: Medidas.tactilMinimo, height: Medidas.tactilMinimo)
                            }
                            .accessibilityLabel("Plegar el texto")
                            .accessibilityIdentifier("botonPlegarTexto")
                        }
                    }
                    if plegable {
                        // Ajustado al texto si cabe (sin huecos); si no, desplazable dentro del alto máximo.
                        ScrollView {
                            cuerpo.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { altoTexto = $0 }
                        }
                        .scrollIndicators(.visible)
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(height: altoTexto > 0 ? min(altoTexto, altoMaximo) : altoMaximo)
                    } else {
                        cuerpo
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("panelTextoBase")
        }
    }

    private var cuerpo: some View {
        Text(texto.texto)
            .font(.body)
            .foregroundStyle(Paleta.textoPrincipal)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("cuerpoTextoBase")
    }

    private func cambiar(_ nuevo: Bool) {
        if reducir { plegado = nuevo } else { withAnimation(.easeInOut(duration: 0.25)) { plegado = nuevo } }
    }
}
