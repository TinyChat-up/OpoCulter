import SwiftUI

/// Raíz de la app: barra de pestañas Hoy, Mapa, Examen y Progreso.
struct VistaRaiz: View {
    @Environment(EntornoApp.self) private var entorno

    var body: some View {
        if let servicio = entorno.servicio {
            TabView {
                PantallaHoy(modelo: HoyViewModel(servicio: servicio))
                    .tabItem { Label("Hoy", systemImage: "sun.max.fill") }
                VistaLlegaPronto(titulo: "Mapa", icono: "map",
                                 texto: "Las rutas de Lengua y Matemáticas, con el dominio de cada competencia y los Retos de bloque.")
                    .tabItem { Label("Mapa", systemImage: "map.fill") }
                VistaLlegaPronto(titulo: "Examen", icono: "doc.text",
                                 texto: "Simulacros completos de 90 minutos con autocorrección por rúbrica.")
                    .tabItem { Label("Examen", systemImage: "doc.text.fill") }
                VistaLlegaPronto(titulo: "Progreso", icono: "chart.bar",
                                 texto: "Tu dominio por bloque, tu evolución, tus logros y los ajustes.")
                    .tabItem { Label("Progreso", systemImage: "chart.bar.fill") }
            }
            .tint(Paleta.matematicas)
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
            Image(systemName: icono)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Paleta.matematicas)
                .frame(width: 96, height: 96)
                .background(Paleta.matematicas.opacity(0.1), in: Circle())
                .accessibilityHidden(true)
            Text(titulo)
                .font(.title2.bold())
                .foregroundStyle(Paleta.textoPrincipal)
                .accessibilityAddTraits(.isHeader)
            Text("Llega pronto")
                .font(.redondeada(.subheadline, peso: .bold))
                .foregroundStyle(Paleta.textoSobreRecompensa)
                .padding(.horizontal, Espacio.m)
                .padding(.vertical, Espacio.xs)
                .background(Paleta.recompensa, in: Capsule())
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
