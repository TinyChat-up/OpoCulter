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
        .retroHaptica(.selection, trigger: seleccion)
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

/// Bienvenida (Fase 05D): avatar → diagnóstico opcional (con "Saltar") → plan → Hoy.
struct PantallaBienvenida: View {
    enum Paso { case avatar, oferta }
    /// Sin servicio (capturas), la bienvenida termina al elegir avatar.
    var servicio: ServicioSesion? = nil
    var ayudasDePrueba = false
    let elegir: (Int) -> Void
    var terminar: () -> Void = {}
    @State private var seleccion: Int?
    @State private var paso = Paso.avatar
    @State private var diagnostico: RondaViewModel?

    var body: some View {
        Group {
            if let diagnostico {
                PantallaRonda(modelo: diagnostico, ayudasDePrueba: ayudasDePrueba, cerrar: terminar)
            } else if paso == .oferta {
                oferta
            } else {
                eleccionAvatar
            }
        }
        .background(Paleta.fondo.ignoresSafeArea())
    }

    private var eleccionAvatar: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.xl) {
                    // Marca (parpadea una vez y el brote se mece) y Mimo, el personaje de la bienvenida (D-105).
                    HStack(alignment: .bottom, spacing: Espacio.m) {
                        MarcaView(tamano: 88, animar: true)
                        VistaPersonaje(companero: .mimo, estado: .neutro)
                    }
                    VStack(alignment: .leading, spacing: Espacio.s) {
                        Text("Te damos la bienvenida")
                            .font(.exhibicion(.largeTitle))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .accessibilityAddTraits(.isHeader)
                        Text("Rondas cortas de Lengua y Matemáticas para la prueba A1. Tilde te acompaña en Lengua, Cuarto en Matemáticas y Mimo en los repasos.")
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
                guard let seleccion else { return }
                elegir(seleccion)
                if servicio == nil { terminar() } else { paso = .oferta }
            }
            .disabled(seleccion == nil)
            .padding(Espacio.l)
            .accessibilityIdentifier("botonEmpezarBienvenida")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaBienvenida")
    }

    private var oferta: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    VistaPersonaje(companero: .mimo, estado: .neutro)
                    Text("¿Vemos desde dónde partes?").font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal)
                        .accessibilityAddTraits(.isHeader)
                    Text("Un diagnóstico corto (unos minutos) con los bloques que ya tienen contenido. Con el resultado te proponemos por dónde empezar. Puedes repetirlo cuando quieras desde Progreso.")
                        .font(.body).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                }
                .padding(Espacio.l)
            }
            VStack(spacing: Espacio.s) {
                BotonPrincipal(titulo: "Empezar diagnóstico", icono: "play.fill", acento: Paleta.matematicas) {
                    if let servicio { diagnostico = RondaViewModel(servicio: servicio, tipo: .diagnostico) }
                }
                .accessibilityIdentifier("botonEmpezarDiagnostico")
                Button("Saltar", action: terminar).buttonStyle(EstiloBotonSecundario())
                    .accessibilityIdentifier("botonSaltarDiagnostico")
            }
            .padding(Espacio.l)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ofertaDiagnostico")
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
