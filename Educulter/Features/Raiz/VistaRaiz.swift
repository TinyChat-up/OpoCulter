import SwiftUI

/// Raíz de la app: barra de pestañas Hoy, Camino, Tribunal y Progreso.
struct VistaRaiz: View {
    @Environment(EntornoApp.self) private var entorno
    @State private var pestana = Pestana.hoy

    var body: some View {
        if let servicio = entorno.servicio {
            TabView(selection: $pestana) {
                PantallaHoy(modelo: HoyViewModel(servicio: servicio), irA: { pestana = $0 })
                    .tabItem { Label("Hoy", systemImage: "sun.max.fill") }
                    .tag(Pestana.hoy)
                PantallaCamino(servicio: servicio)
                    .tabItem { Label("Camino", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
                    .tag(Pestana.camino)
                PantallaTribunal(servicio: servicio)
                    .tabItem { Label("Tribunal", systemImage: "checkmark.seal.fill") }
                    .tag(Pestana.tribunal)
                PantallaProgreso(servicio: servicio)
                    .tabItem { Label("Progreso", systemImage: "chart.bar.fill") }
                    .tag(Pestana.progreso)
            }
            .tint(Paleta.primario)
        } else {
            VistaLlegaPronto(titulo: "No se ha podido cargar el contenido", icono: "exclamationmark.triangle",
                             texto: entorno.errorCarga ?? "Error desconocido.")
        }
    }
}

/// Estado vacío elegante para lo que llega en la Fase 05B.
struct VistaLlegaPronto: View {
    let titulo: String
    let icono: String
    let texto: String

    var body: some View {
        VStack(spacing: Espacio.l) {
            Text(titulo)
                .font(.exhibicion(.title2))
                .foregroundStyle(Paleta.textoPrincipal)
                .accessibilityAddTraits(.isHeader)
            Text("Llega pronto")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Paleta.textoSecundario)
            Text(texto)
                .font(.body)
                .foregroundStyle(Paleta.textoSecundario)
        }
        .multilineTextAlignment(.center)
        .padding(Espacio.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Paleta.fondo.ignoresSafeArea())
    }
}
