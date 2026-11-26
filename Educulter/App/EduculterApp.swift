import SwiftUI

/// Punto de entrada de la app.
@main
struct EduculterApp: App {
    @State private var entorno = EntornoApp.crear()

    var body: some Scene {
        WindowGroup {
            raiz
                #if DEBUG
                .preferredColorScheme(entorno.opciones.modoOscuro ? .dark : nil)
                #endif
                .environment(entorno)
                .environment(\.sonido, entorno.sonido)
                .environment(\.vibracionActiva, entorno.ajustes.vibracion)
                .task { await entorno.reprogramarRecordatorio() }
        }
    }

    @ViewBuilder
    private var raiz: some View {
        #if DEBUG
        if let escena = entorno.opciones.captura {
            VistaCaptura(escena: escena)
        } else {
            VistaRaiz()
        }
        #else
        VistaRaiz()
        #endif
    }
}
