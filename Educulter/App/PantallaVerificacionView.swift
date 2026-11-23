import SwiftUI

/// Estado mínimo de la pantalla de verificación. Se separa de la vista para poder
/// probarlo con un test unitario.
struct EstadoVerificacion: Equatable, Sendable {
    private(set) var pulsaciones = 0

    var mensaje: String {
        pulsaciones == 0
            ? String(localized: "Entorno listo")
            : String(localized: "Comprobaciones: \(pulsaciones)")
    }

    mutating func registrarPulsacion() {
        pulsaciones += 1
    }
}

/// Pantalla de prueba de la Fase 00. Muestra un texto y un botón accesible
/// (VoiceOver, Dynamic Type y colores del sistema con contraste suficiente).
struct PantallaVerificacionView: View {
    @State private var estado = EstadoVerificacion()

    var body: some View {
        VStack(spacing: 24) {
            Text("Educulter")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(estado.mensaje)
                .font(.title3)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("mensajeEstado")

            Button {
                estado.registrarPulsacion()
            } label: {
                Text("Comprobar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(Text("Comprobar el entorno"))
            .accessibilityHint(Text("Actualiza el mensaje de estado"))
            .accessibilityIdentifier("botonComprobar")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    PantallaVerificacionView()
}
