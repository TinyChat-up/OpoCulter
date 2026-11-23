import SwiftUI

/// Cuadrícula de 3 × 2 con los 6 avatares del propietario (bienvenida y Perfil). Todos llevan
/// contorno de tinta; el elegido, además, sombra dura, fondo mostaza y una marca ✓ (el estado no
/// depende solo del color).
struct SelectorAvatar: View {
    @Binding var seleccion: Int?

    var body: some View {
        VStack(spacing: Espacio.l) {
            ForEach(0..<2, id: \.self) { fila in
                HStack(spacing: Espacio.l) {
                    ForEach(Avatar.todos[(fila * 3)..<(fila * 3 + 3)]) { celda($0) }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: seleccion)
    }

    private func celda(_ avatar: Avatar) -> some View {
        let elegido = seleccion == avatar.id
        return Button {
            seleccion = avatar.id
        } label: {
            VistaAvatar(avatar: avatar, tamano: 76)
                .padding(Espacio.s)
                .frame(maxWidth: .infinity, minHeight: 92)
                .superficiePulsable(elegido ? Paleta.recompensa : Paleta.superficie, radio: Radio.ficha, sombra: elegido)
                .overlay(alignment: .topTrailing) {
                    if elegido {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Paleta.fondo, Paleta.contorno)
                            .offset(x: 6, y: -6)
                            .accessibilityHidden(true)
                    }
                }
                .estiramiento(elegido)
        }
        .buttonStyle(.pulsable)
        .accessibilityLabel("Avatar con \(avatar.nombre)")
        .accessibilityAddTraits(elegido ? .isSelected : [])
        .accessibilityIdentifier("avatar_\(avatar.id)")
    }
}

/// Bienvenida: los dos compañeros, una frase y la elección de avatar.
struct PantallaBienvenida: View {
    let elegir: (Int) -> Void
    @State private var seleccion: Int?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.xl) {
                    HStack(spacing: Espacio.m) {
                        VistaPersonaje(companero: .tilde, estado: ReglasPersonaje.estado(para: .bienvenida))
                        VistaPersonaje(companero: .cuarto, estado: ReglasPersonaje.estado(para: .bienvenida))
                    }
                    VStack(alignment: .leading, spacing: Espacio.s) {
                        Text("Te damos la bienvenida")
                            .font(.exhibicion(.largeTitle))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .accessibilityAddTraits(.isHeader)
                        Text("Rondas cortas de Lengua y Matemáticas para la prueba A1. Tilde te acompaña en Lengua y Cuarto en Matemáticas.")
                            .font(.body)
                            .foregroundStyle(Paleta.textoSecundario)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: Espacio.m) {
                        Text("Elige tu avatar").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal)
                        SelectorAvatar(seleccion: $seleccion)
                    }
                }
                .padding(Espacio.l)
            }
            BotonPrincipal(titulo: "Empezar", icono: "arrow.right", acento: Paleta.matematicas) {
                if let seleccion { elegir(seleccion) }
            }
            .disabled(seleccion == nil)
            .padding(Espacio.l)
            .accessibilityIdentifier("botonEmpezarBienvenida")
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaBienvenida")
    }
}

/// Perfil: cambiar el avatar (el editor completo llega después del MVP). Botones propios en el
/// contenido (los de la barra del sistema no escalan con Dynamic Type ni cumplen el contraste).
struct PantallaPerfil: View {
    let avatar: Int?
    let elegir: (Int) -> Void
    @State private var seleccion: Int?
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text("Perfil").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    if let actual = Avatar.con(id: seleccion) {
                        HStack(spacing: Espacio.m) {
                            VistaAvatar(avatar: actual, tamano: 64)
                            Text("Avatar con \(actual.nombre)").font(.headline).foregroundStyle(Paleta.textoPrincipal)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    SelectorAvatar(seleccion: $seleccion)
                }
                .padding(Espacio.l)
            }
            VStack(spacing: Espacio.s) {
                BotonPrincipal(titulo: "Guardar", acento: Paleta.matematicas) {
                    if let seleccion { elegir(seleccion) }
                    cerrar()
                }
                .accessibilityIdentifier("botonGuardarPerfil")
                Button("Cancelar") { cerrar() }
                    .buttonStyle(EstiloBotonSecundario(acento: Paleta.matematicasTinta))
                    .accessibilityIdentifier("botonCancelarPerfil")
            }
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .onAppear { seleccion = avatar }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaPerfil")
    }
}
