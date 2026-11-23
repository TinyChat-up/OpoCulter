import SwiftUI

/// Punto de entrada de la app.
@main
struct EduculterApp: App {
    @State private var entorno = EntornoApp.crear()

    var body: some Scene {
        WindowGroup {
            raiz
                .environment(entorno)
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
