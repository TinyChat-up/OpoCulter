import SwiftUI

/// Punto de entrada de la app.
/// Fase 00: solo contiene una pantalla de verificación técnica, sin funcionalidad de producto.
@main
struct EduculterApp: App {
    var body: some Scene {
        WindowGroup {
            PantallaVerificacionView()
        }
    }
}
