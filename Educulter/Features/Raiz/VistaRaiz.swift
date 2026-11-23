import SwiftUI

/// Raíz de la app: barra de pestañas Hoy, Mapa, Examen y Progreso.
struct VistaRaiz: View {
    @Environment(EntornoApp.self) private var entorno

    var body: some View {
        if let servicio = entorno.servicio {
            TabView {
                PantallaHoy(modelo: HoyViewModel(servicio: servicio))
                    .tabItem { Label("Hoy", systemImage: "sun.max.fill") }
                VistaLlegaPronto(titulo: "Camino", icono: "point.topleft.down.to.point.bottomright.curvepath",
                                 texto: "Las rutas de Lengua y Matemáticas, competencia a competencia, con tu dominio y los Retos de bloque.")
                    .tabItem { Label("Camino", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
                VistaLlegaPronto(titulo: "Tribunal", icono: "checkmark.seal",
                                 texto: "Simulacros con el formato y el tiempo del examen, corregidos con la rúbrica del tribunal.")
                    .tabItem { Label("Tribunal", systemImage: "checkmark.seal.fill") }
                VistaLlegaPronto(titulo: "Progreso", icono: "chart.bar",
                                 texto: "Tu dominio por bloque, tu evolución, tus logros y los ajustes.")
                    .tabItem { Label("Progreso", systemImage: "chart.bar.fill") }
            }
            .tint(Paleta.contorno)
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
            VistaPersonaje(companero: .cuarto, estado: ReglasPersonaje.estado(para: .estadoVacio))
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
