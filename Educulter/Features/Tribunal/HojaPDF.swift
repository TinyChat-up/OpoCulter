import PDFKit
import SwiftUI
import UIKit

/// Vista previa del PDF de un simulacro con Imprimir y Compartir del sistema (05J §2). Verlo o
/// compartirlo no empieza el reloj ni registra ningún intento; eso lo hacen «Empezar en papel» y
/// «Corregir una prueba hecha en papel».
struct HojaPDF: View {
    let simulacro: SimulacroOriginal
    let empezarEnPapel: () -> Void
    let corregirEnPapel: () -> Void
    @Environment(\.dismiss) private var cerrar
    @State private var archivo: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let archivo {
                    VistaPDF(url: archivo).accessibilityIdentifier("vistaPDF")
                } else if let error {
                    Text(error).padding(Espacio.l)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                VStack(spacing: Espacio.s) {
                    HStack(spacing: Espacio.s) {
                        Button { imprimir() } label: { Label("Imprimir", systemImage: "printer") }
                            .buttonStyle(EstiloBotonSecundario())
                            .disabled(archivo == nil)
                            .accessibilityIdentifier("botonImprimir")
                        if let archivo {
                            ShareLink(item: archivo) { Label("Compartir", systemImage: "square.and.arrow.up") }
                                .buttonStyle(EstiloBotonSecundario())
                                .accessibilityIdentifier("botonCompartir")
                        }
                    }
                    BotonPrincipal(titulo: "Empezar en papel", icono: "timer", acento: Paleta.primario) { empezarEnPapel() }
                        .accessibilityIdentifier("botonEmpezarPapel")
                    Button("Corregir una prueba hecha en papel") { corregirEnPapel() }
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: Medidas.tactilMinimo)
                        .accessibilityIdentifier("botonCorregirPapel")
                    Text("«Empezar en papel» pone en marcha la cuenta atrás de \(simulacro.entrada.minutos) min. Corregir sin tiempo deja la duración como desconocida.")
                        .font(.caption).foregroundStyle(Paleta.textoSecundario).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Espacio.l)
                .background(Paleta.fondo)
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationTitle(simulacro.entrada.titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { cerrar() } } }
        }
        .task {
            do { archivo = try PDFSimulacro.archivo(simulacro) } catch { self.error = "No se ha podido preparar el PDF." }
        }
    }

    private func imprimir() {
        guard let archivo else { return }
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = simulacro.entrada.titulo
        let c = UIPrintInteractionController.shared
        c.printInfo = info
        c.printingItem = archivo
        c.present(animated: true)
    }
}

struct VistaPDF: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.backgroundColor = .secondarySystemBackground
        v.document = PDFDocument(url: url)
        return v
    }

    func updateUIView(_ v: PDFView, context: Context) {}
}
