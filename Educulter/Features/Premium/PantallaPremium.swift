import StoreKit
import SwiftUI

/// Pantalla Premium (fase 06 §1.4): `SubscriptionStoreView` con una cabecera propia en la identidad
/// v5. Lo que incluye en 3 líneas; precio y periodo de StoreKit (a través del servicio de acceso);
/// la prueba de 7 días y qué pasa después; Restaurar compras, Términos de uso y Política de
/// privacidad siempre visibles abajo. Sin cuentas atrás ni planes preseleccionados (cada plan es su
/// propio botón). Solo se abre a petición del usuario: Ajustes > Premium o «Ver Premium».
struct PantallaPremium: View {
    @Environment(EntornoApp.self) private var entorno
    @Environment(\.dismiss) private var cerrar
    @State private var ofertas: [OfertaPremium]?
    @State private var restaurando = false
    @State private var mensaje: String?

    var body: some View {
        SubscriptionStoreView(productIDs: ProductosPremium.todos) {
            cabecera
        }
        .subscriptionStoreControlStyle(.buttons)
        .subscriptionStoreButtonLabel(.multiline)
        // Restaurar y los enlaces legales van en el pie propio, siempre visibles.
        .storeButton(.hidden, for: .restorePurchases)
        .storeButton(.hidden, for: .policies)
        .storeButton(.hidden, for: .cancellation)
        .onInAppPurchaseCompletion { _, resultado in
            if case .success(.success(let verificacion)) = resultado { await entorno.acceso.registrar(verificacion) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { pie }
        .containerBackground(Paleta.fondo, for: .subscriptionStore)
        .background(Paleta.fondo.ignoresSafeArea())
        .tint(Paleta.matematicas)
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .task { ofertas = await entorno.acceso.ofertas() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaPremium")
    }

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            HStack(alignment: .center, spacing: Espacio.m) {
                MarcaView(tamano: 44)
                Text("Educulter Premium").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: Espacio.s) {
                ForEach(TextosPremium.incluye, id: \.self) { linea in
                    Label { Text(linea).fixedSize(horizontal: false, vertical: true) } icon: {
                        Image(systemName: "checkmark").foregroundStyle(Paleta.matematicas)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Paleta.textoPrincipal)
                }
            }
            if entorno.acceso.premium {
                Label("Ya tienes Premium. ¡Gracias!", systemImage: "checkmark.seal")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityIdentifier("textoYaPremium")
            }
            VStack(alignment: .leading, spacing: Espacio.xs) {
                if let ofertas, !ofertas.isEmpty {
                    ForEach(ofertas) { o in
                        Text(o.condiciones).font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(TextosPremium.renovacion).font(.footnote).foregroundStyle(Paleta.textoSecundario)
                        .fixedSize(horizontal: false, vertical: true)
                } else if ofertas != nil {
                    Text("No se han podido cargar los precios del App Store. Revisa la conexión e inténtalo más tarde.")
                        .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                }
                Text(TextosPremium.gratis).font(.footnote).foregroundStyle(Paleta.textoSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("condicionesPremium")
        }
        .padding(.horizontal, Espacio.l)
        .padding(.top, Espacio.l)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pie: some View {
        VStack(spacing: Espacio.xs) {
            if let mensaje {
                Text(mensaje).font(.footnote).foregroundStyle(Paleta.textoPrincipal).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("mensajeRestaurar")
            }
            DisposicionFlujo(espacioH: Espacio.l, espacioV: Espacio.xs) {
                Button(restaurando ? "Restaurando…" : "Restaurar compras") { Task { await restaurar() } }
                    .disabled(restaurando)
                    .accessibilityIdentifier("botonRestaurarCompras")
                Link("Términos de uso", destination: EnlacesLegales.terminos)
                    .accessibilityIdentifier("enlaceTerminos")
                Link("Política de privacidad", destination: EnlacesLegales.privacidad)
                    .accessibilityIdentifier("enlacePrivacidad")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Paleta.textoPrincipal)
            .frame(minHeight: Medidas.tactilMinimo)
        }
        .padding(.horizontal, Espacio.l)
        .padding(.vertical, Espacio.s)
        .frame(maxWidth: .infinity)
        .background(Paleta.fondo)
    }

    private func restaurar() async {
        restaurando = true
        defer { restaurando = false }
        do {
            try await entorno.acceso.restaurar()
            mensaje = entorno.acceso.premium ? "Compras restauradas: tienes Premium." : "No hay ninguna suscripción activa con esta cuenta."
        } catch {
            mensaje = "No se ha podido conectar con el App Store. Inténtalo más tarde."
        }
    }
}

/// Hoja que aparece al tocar algo bloqueado (fase 06 §1.4): qué incluye Premium y «Ver Premium».
/// Solo se abre al tocar; nunca salta sola.
struct HojaBloqueoPremium: View {
    let motivo: MotivoBloqueo
    @Environment(\.dismiss) private var cerrar
    @State private var verPremium = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    HStack(spacing: Espacio.m) {
                        Image(systemName: "lock").font(.title2).foregroundStyle(Paleta.textoPrincipal).accessibilityHidden(true)
                        Text("Incluido en Premium").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(motivo.texto).font(.body).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: Espacio.s) {
                        ForEach(TextosPremium.incluye, id: \.self) { linea in
                            Label { Text(linea).fixedSize(horizontal: false, vertical: true) } icon: {
                                Image(systemName: "checkmark").foregroundStyle(Paleta.matematicas)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Paleta.textoPrincipal)
                        }
                    }
                    Text("La muestra del Tribunal y todo el aprendizaje diario son gratis.")
                        .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                    BotonPrincipal(titulo: "Ver Premium", icono: "arrow.right", acento: Paleta.matematicas) { verPremium = true }
                        .accessibilityIdentifier("botonVerPremium")
                    Button("Ahora no") { cerrar() }
                        .buttonStyle(EstiloBotonSecundario())
                        .accessibilityIdentifier("botonAhoraNo")
                }
                .padding(Espacio.l)
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationDestination(isPresented: $verPremium) { PantallaPremium() }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hojaBloqueoPremium")
    }
}

/// Qué se ha tocado (texto de la hoja de bloqueo).
struct MotivoBloqueo: Identifiable, Equatable {
    var texto: String
    var id: String { texto }

    static let simulacro = MotivoBloqueo(texto: "Los simulacros originales, con su corrección y su informe, son de Premium.")
    static let convocatorias = MotivoBloqueo(texto: "Las convocatorias anteriores (los 7 exámenes oficiales, con sus enunciados y el modo examen) son de Premium.")
    static let bloques = MotivoBloqueo(texto: "La práctica «Por bloques» según el plano del examen es de Premium.")
    static let resultado = MotivoBloqueo(texto: "La corrección y el informe de este simulacro son de Premium.")
}
