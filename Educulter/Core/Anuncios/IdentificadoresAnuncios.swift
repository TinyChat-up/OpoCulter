import CryptoKit
import Foundation

/// Identificadores de AdMob (fase 06 §2.4).
///
/// - Debug: siempre los de prueba de Google para iOS (solo existen dentro de `#if DEBUG`).
/// - Release: los reales del xcconfig (`Config/Anuncios-Release.xcconfig` → Info.plist). Mientras
///   valgan `PENDIENTE`, o si no tienen el formato de AdMob, no se muestra ningún anuncio y la app no
///   se cierra ni avisa (falla en seguro).
/// - Nunca se envían IDs de prueba a producción: en Release, un identificador del editor de prueba
///   de Google se rechaza. Se compara por su huella SHA-256 para que el número del editor de prueba
///   no viaje en el binario de Release.
struct IdentificadoresAnuncios: Sendable, Equatable {
    static let claveIntersticial = "EduculterAdMobIntersticial"
    static let claveApp = "GADApplicationIdentifier"

    var app: String
    var intersticial: String
    /// Se pueden pedir anuncios con estos identificadores.
    var validos: Bool

    #if DEBUG
    static let pruebaApp = "ca-app-pub-3940256099942544~1458002511"
    static let pruebaIntersticial = "ca-app-pub-3940256099942544/4411468910"
    #endif

    /// Huella SHA-256 del número del editor de prueba de Google.
    static let huellaEditorPrueba = "02c8c3ab2d26560310ea95e9fefd38a76b77fae88a7283ed60d2fd94a296c426"

    /// Identificadores de esta compilación.
    static func actuales(_ bundle: Bundle = .main) -> IdentificadoresAnuncios {
        #if DEBUG
        return IdentificadoresAnuncios(app: pruebaApp, intersticial: pruebaIntersticial, validos: true)
        #else
        let app = bundle.object(forInfoDictionaryKey: claveApp) as? String ?? ""
        let intersticial = bundle.object(forInfoDictionaryKey: claveIntersticial) as? String ?? ""
        return IdentificadoresAnuncios(app: app, intersticial: intersticial, validos: validosParaProduccion(app: app, intersticial: intersticial))
        #endif
    }

    /// Reglas de Release: formato de AdMob (`ca-app-pub-<editor>~<app>` y `ca-app-pub-<editor>/<bloque>`),
    /// el mismo editor en los dos y que no sea el de prueba de Google.
    static func validosParaProduccion(app: String, intersticial: String) -> Bool {
        guard let a = partes(app, separador: "~"), let i = partes(intersticial, separador: "/"),
              a.editor == i.editor else { return false }
        return huella(a.editor) != huellaEditorPrueba
    }

    static func huella(_ texto: String) -> String {
        SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func partes(_ id: String, separador: Character) -> (editor: String, numero: String)? {
        let prefijo = "ca-app-pub-"
        guard id.hasPrefix(prefijo) else { return nil }
        let resto = id.dropFirst(prefijo.count).split(separator: separador, omittingEmptySubsequences: false)
        guard resto.count == 2, resto.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }
        return (String(resto[0]), String(resto[1]))
    }
}
