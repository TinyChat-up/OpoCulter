import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// Google Mobile Ads (solo intersticiales) y User Messaging Platform (fase 06 §2.1). Es el único
/// archivo que importa los SDK de Google.
@MainActor
final class ProveedorGoogle: NSObject, ProveedorAnuncios {
    private var anuncio: InterstitialAd?
    private var cargando = false
    private var iniciado = false
    private var alCerrar: (@MainActor () -> Void)?

    var cargado: Bool { anuncio != nil }
    var puedePedirAnuncios: Bool { ConsentInformation.shared.canRequestAds }
    var opcionesPrivacidadRequeridas: Bool { ConsentInformation.shared.privacyOptionsRequirementStatus == .required }

    func actualizarConsentimiento(eee: Bool) async {
        let parametros = RequestParameters()
        #if DEBUG
        if eee {
            let depuracion = DebugSettings()
            depuracion.geography = .EEA
            parametros.debugSettings = depuracion
        }
        #endif
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parametros)
            try await ConsentForm.loadAndPresentIfRequired(from: Self.controladorSuperior())
        } catch {
            // Sin respuesta de UMP, `canRequestAds` decide (falso si nunca se ha obtenido).
        }
    }

    func pedirPermisoSeguimiento() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    func iniciar() async {
        guard !iniciado else { return }
        iniciado = true
        _ = await MobileAds.shared.start()
    }

    func cargar(_ bloque: String) async {
        guard anuncio == nil, !cargando else { return }
        cargando = true
        defer { cargando = false }
        do {
            let nuevo = try await InterstitialAd.load(with: bloque, request: Request())
            nuevo.fullScreenContentDelegate = self
            anuncio = nuevo
        } catch {
            // Sin anuncio: la próxima ronda se sigue sin él y se vuelve a intentar.
        }
    }

    func presentar(alCerrar: @escaping @MainActor () -> Void) -> Bool {
        guard let anuncio, let raiz = Self.controladorSuperior(), (try? anuncio.canPresent(from: raiz)) != nil else { return false }
        self.anuncio = nil
        self.alCerrar = alCerrar
        anuncio.present(from: raiz)
        return true
    }

    func abrirOpcionesPrivacidad() async {
        try? await ConsentForm.presentPrivacyOptionsForm(from: Self.controladorSuperior())
    }

    private func cerrado() {
        let accion = alCerrar
        alCerrar = nil
        accion?()
    }

    /// El controlador que está encima de todo (la hoja o la pantalla completa de la ronda).
    static func controladorSuperior() -> UIViewController? {
        let escenas = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let escena = escenas.first { $0.activationState == .foregroundActive } ?? escenas.first
        var vc = escena?.windows.first(where: \.isKeyWindow)?.rootViewController ?? escena?.windows.first?.rootViewController
        while let siguiente = vc?.presentedViewController, !siguiente.isBeingDismissed { vc = siguiente }
        return vc
    }
}

extension ProveedorGoogle: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        Task { @MainActor in self.cerrado() }
    }

    nonisolated func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Task { @MainActor in self.cerrado() }
    }
}
