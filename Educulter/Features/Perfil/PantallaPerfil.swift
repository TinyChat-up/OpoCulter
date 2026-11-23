import SwiftUI

/// Cuadrícula de los 12 avatares (bienvenida y Perfil).
struct SelectorAvatar: View {
    @Binding var seleccion: Int?
    @Environment(\.dynamicTypeSize) private var tamano

    var body: some View {
        let columnas = Array(repeating: GridItem(.flexible(), spacing: Espacio.m), count: tamano.isAccessibilitySize ? 3 : 4)
        LazyVGrid(columns: columnas, spacing: Espacio.m) {
            ForEach(Avatar.todos) { avatar in
                let elegido = seleccion == avatar.id
                Button {
                    seleccion = avatar.id
                } label: {
                    VistaAvatar(avatar: avatar, tamano: 52)
                        .padding(Espacio.s)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(elegido ? Paleta.matematicasTinte : Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous)
                            .strokeBorder(elegido ? Paleta.matematicasTinta : .clear, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(avatar.nombre)
                .accessibilityAddTraits(elegido ? .isSelected : [])
                .accessibilityIdentifier("avatar_\(avatar.id)")
            }
        }
        .sensoryFeedback(.selection, trigger: seleccion)
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
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .accessibilityAddTraits(.isHeader)
                        Text("Rondas cortas de Lengua y Matemáticas para la prueba A1. Tilde te acompaña en Lengua y Cuarto en Matemáticas.")
                            .font(.body)
                            .foregroundStyle(Paleta.textoSecundario)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: Espacio.m) {
                        Text("Elige tu avatar").font(.headline).foregroundStyle(Paleta.textoPrincipal)
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
                    Text("Perfil").font(.title2.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    if let actual = Avatar.con(id: seleccion) {
                        HStack(spacing: Espacio.m) {
                            VistaAvatar(avatar: actual, tamano: 64)
                            Text(actual.nombre).font(.headline).foregroundStyle(Paleta.textoPrincipal)
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
