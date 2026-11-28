import SwiftUI

/// Ajustes > «Privacidad y anuncios» (fase 06 §2.3): explicación sencilla y, cuando UMP lo exige, el
/// botón para volver a abrir las opciones de privacidad.
struct PantallaPrivacidadAnuncios: View {
    @Environment(EntornoApp.self) private var entorno

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.l) {
                Text("Privacidad y anuncios").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityAddTraits(.isHeader)
                bloque("Tu progreso es tuyo",
                       "La app no tiene cuentas ni servidor: tu progreso se guarda solo en este iPhone.")
                bloque("Cuándo hay anuncios",
                       "En la versión gratuita, a veces sale un anuncio a pantalla completa al terminar una ronda. Nunca durante una ronda, en el Tribunal ni en tus dos primeros días; como mucho, uno cada dos rondas y cuatro al día. Con Premium no hay anuncios.")
                bloque("Quién los muestra",
                       "Los anuncios los sirve Google (AdMob). Antes del primero te pedimos tu consentimiento cuando la ley lo exige y, después, el permiso de seguimiento de Apple. Si dices que no, la app funciona exactamente igual.")
                if entorno.acceso.premium {
                    Text("Tienes Premium: no se muestran anuncios ni se cargan.")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                } else if entorno.anuncios.opcionesPrivacidadRequeridas {
                    Button("Opciones de privacidad") { Task { await entorno.anuncios.abrirOpcionesPrivacidad() } }
                        .buttonStyle(EstiloBotonSecundario())
                        .accessibilityIdentifier("botonOpcionesPrivacidad")
                } else {
                    Text("Ahora no hay opciones de privacidad que cambiar.")
                        .font(.footnote).foregroundStyle(Paleta.textoSecundario)
                        .accessibilityIdentifier("textoSinOpcionesPrivacidad")
                }
                Text("El permiso de seguimiento se cambia en los Ajustes del iPhone > Privacidad y seguridad > Rastreo.")
                    .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            }
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaPrivacidadAnuncios")
    }

    private func bloque(_ titulo: String, _ texto: String) -> some View {
        TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.xs) {
                Text(titulo).font(.headline).foregroundStyle(Paleta.textoPrincipal)
                Text(texto).font(.subheadline).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
