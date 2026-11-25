import SwiftUI
import CoreText

/// Colores del estilo "Rubber Hose moderno" (D-059), evolución del sistema v2 (D-053): papel
/// crema, tinta gruesa y rellenos retro saturados. Definidos en el Asset Catalog
/// (`Resources/Assets.xcassets/Colores`) con variante clara y oscura y contraste AA comprobado
/// (UX_UI.md §4.1). Regla: **el texto sobre un relleno de color va siempre en tinta**.
enum Paleta {
    /// Papel: `#FBF3E8` en claro, `#17130F` en oscuro.
    static let fondo = Color("Fondo")
    /// Tinta de contornos y sombras duras (`#1A1714`; clara en modo oscuro).
    static let contorno = Color("Tinta")
    /// Superficie neutra: baldosas, filas y fichas fuera del panel protagonista.
    static let superficie = Color("Superficie")
    static let textoPrincipal = Color("TextoPrincipal")
    static let textoSecundario = Color("TextoSecundario")
    static let borde = Color("Borde")
    /// Relleno de Lengua (coral `#F2674B`), siempre con texto en tinta encima.
    static let lengua = Color("Lengua")
    /// Relleno de Matemáticas (azul cielo `#4AA3E8`).
    static let matematicas = Color("Matematicas")
    /// Acentos secundarios (rellenos, con texto en tinta): turquesa, violeta y oliva.
    static let turquesa = Color("Turquesa")
    static let violeta = Color("Violeta")
    static let oliva = Color("Oliva")
    /// Tinte del panel protagonista de cada área (uno por pantalla).
    static let lenguaTinte = Color("LenguaTinte")
    static let matematicasTinte = Color("MatematicasTinte")
    /// Tinta de cada área: texto con color de área (títulos de competencia, etiquetas).
    static let lenguaTinta = Color("LenguaTinta")
    static let matematicasTinta = Color("MatematicasTinta")
    /// Éxito como texto o icono (AA sobre papel y tintes).
    static let exito = Color("Exito")
    /// Éxito como relleno, con texto en tinta (botón "Continuar" tras acertar).
    static let exitoRelleno = Color("ExitoRelleno")
    static let fallo = Color("Fallo")
    /// Relleno de recompensa (siempre con `textoSobreRecompensa` encima).
    static let recompensa = Color("Recompensa")
    /// Ámbar legible como texto sobre fondo, superficie o tintes.
    static let recompensaTexto = Color("RecompensaTexto")
    /// Texto sobre cualquier relleno de color: tinta oscura en los dos modos.
    static let textoSobreAcento = Color("TextoSobreAcento")
    static let textoSobreRecompensa = Color("TextoSobreRecompensa")

    /// Primario de un área (`LEN` → coral, `MAT` → índigo).
    static func acento(area: String) -> Color { area == "MAT" ? matematicas : lengua }
    static func tinte(area: String) -> Color { area == "MAT" ? matematicasTinte : lenguaTinte }
    static func tinta(area: String) -> Color { area == "MAT" ? matematicasTinta : lenguaTinta }

    static func acento(competencia: String) -> Color { acento(area: Catalogo.area(de: competencia)) }
    static func tinte(competencia: String) -> Color { tinte(area: Catalogo.area(de: competencia)) }
    static func tinta(competencia: String) -> Color { tinta(area: Catalogo.area(de: competencia)) }

    /// Colores (todos AA) para distinguir pares y etiquetas; siempre acompañados de número o texto.
    static let pares: [Color] = [matematicasTinta, lenguaTinta, exito, recompensaTexto, textoSecundario]
}

/// Escala de espaciado 4/8/12/16/24/32.
enum Espacio {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Radios generosos (Rubber Hose): paneles 20, fichas y piezas 14, celdas manipulables 6.
enum Radio {
    static let tarjeta: CGFloat = 20
    static let ficha: CGFloat = 14
    static let celda: CGFloat = 6
}

/// Grosor del contorno de tinta: 2,5 pt en fichas, paneles, botones y celdas; 1,5 pt en
/// elementos pequeños (chips, cápsulas, celdas de menos de 32 pt).
enum Trazo {
    static let grueso: CGFloat = 2.5
    static let fino: CGFloat = 1.5
}

/// "Sombra dura" plana: desplazamiento en tinta, sin desenfoque. Es la única sombra de la app
/// y es funcional: marca lo que se puede pulsar. Al pulsar, el elemento "se hunde" (0 pt).
enum SombraDura {
    static let desplazamiento: CGFloat = 3
}

extension View {
    /// Contorno de tinta alrededor de una forma redondeada.
    func contornoTinta(radio: CGFloat, grosor: CGFloat = Trazo.grueso, color: Color = Paleta.contorno) -> some View {
        overlay(RoundedRectangle(cornerRadius: radio, style: .continuous).strokeBorder(color, lineWidth: grosor))
    }

    /// Sombra dura detrás de la vista (sin desenfoque). `activa: false` la quita (elementos no pulsables).
    func sombraDura(radio: CGFloat, activa: Bool = true) -> some View {
        background {
            if activa {
                RoundedRectangle(cornerRadius: radio, style: .continuous)
                    .fill(Paleta.contorno)
                    .offset(x: SombraDura.desplazamiento, y: SombraDura.desplazamiento)
            }
        }
    }
}

/// Estilo de botón "pulsable": se comporta como `.plain`, pero publica en el entorno si el botón
/// está pulsado para que la superficie de dentro (`superficiePulsable`) "se hunda" sobre su sombra.
struct EstiloPulsable: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.environment(\.pulsado, configuration.isPressed)
    }
}

extension ButtonStyle where Self == EstiloPulsable {
    static var pulsable: EstiloPulsable { EstiloPulsable() }
}

private struct ClavePulsado: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// `true` mientras el botón que contiene la vista está pulsado (lo publica `EstiloPulsable`).
    var pulsado: Bool {
        get { self[ClavePulsado.self] }
        set { self[ClavePulsado.self] = newValue }
    }
}

extension View {
    /// Superficie pulsable Rubber Hose: relleno, contorno de tinta y sombra dura de 3 pt. Al pulsar,
    /// se desplaza 3 pt sobre la sombra ("se hunde"). `sombra: false` para lo que ya no se puede
    /// tocar (corregido o desactivado), que queda plano.
    func superficiePulsable(_ relleno: Color, radio: CGFloat, borde: Color = Paleta.contorno,
                            grosor: CGFloat = Trazo.grueso, discontinuo: Bool = false, sombra: Bool = true) -> some View {
        modifier(SuperficiePulsable(relleno: relleno, radio: radio, borde: borde, grosor: grosor, discontinuo: discontinuo, sombra: sombra))
    }
}

private struct SuperficiePulsable: ViewModifier {
    let relleno: Color
    let radio: CGFloat
    let borde: Color
    let grosor: CGFloat
    let discontinuo: Bool
    let sombra: Bool
    @Environment(\.pulsado) private var pulsado
    @Environment(\.isEnabled) private var activo
    @Environment(\.accessibilityReduceMotion) private var reducir

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: radio, style: .continuous)
        let conSombra = sombra && activo
        let hundido = pulsado && conSombra
        content
            .background(relleno, in: forma)
            .overlay(forma.strokeBorder(borde, style: StrokeStyle(lineWidth: grosor, dash: discontinuo ? [6, 4] : [])))
            .contentShape(forma)
            .offset(x: hundido ? SombraDura.desplazamiento : 0, y: hundido ? SombraDura.desplazamiento : 0)
            .background {
                if conSombra {
                    forma.fill(Paleta.contorno).offset(x: SombraDura.desplazamiento, y: SombraDura.desplazamiento)
                }
            }
            .animation(reducir ? nil : .spring(response: 0.16, dampingFraction: 0.55), value: hundido)
    }
}

/// Indica que la vista está dentro del panel tintado protagonista: las superficies interiores
/// usan el fondo (claro) en lugar de la superficie neutra, para separarse del tinte sin sombras.
private struct ClaveEnPanel: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var enPanelTintado: Bool {
        get { self[ClaveEnPanel.self] }
        set { self[ClaveEnPanel.self] = newValue }
    }
}

/// Panel protagonista: el único elemento tintado de la pantalla (la actividad principal), con
/// contorno de tinta. No lleva sombra dura porque no se pulsa: lo pulsable está dentro.
struct PanelProtagonista<Contenido: View>: View {
    let tinte: Color
    var relleno: CGFloat = Espacio.l
    @ViewBuilder let contenido: () -> Contenido

    var body: some View {
        contenido()
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tinte, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .contornoTinta(radio: Radio.tarjeta)
            .environment(\.enPanelTintado, true)
    }
}

enum Medidas {
    /// Área táctil mínima (HIG).
    static let tactilMinimo: CGFloat = 44
    /// Alto mínimo de fichas y opciones de las mecánicas (más peso táctil, D-049).
    static let fichaMinima: CGFloat = 52
}

/// Símbolo SF que identifica cada bloque del temario (cabecera de ronda, Ronda recomendada
/// y, en la 05B, el Mapa). Tabla en UX_UI.md §4.7.
enum SimboloBloque {
    static let porBloque: [String: String] = [
        "LEN.SIN": "point.3.connected.trianglepath.dotted",
        "LEN.ORT": "character.cursor.ibeam",
        "LEN.CLA": "tag",
        "LEN.VER": "clock.arrow.circlepath",
        "LEN.LIT": "books.vertical",
        "LEN.COM": "text.magnifyingglass",
        "LEN.REC": "theatermasks",
        "LEN.MET": "music.quarternote.3",
        "LEN.LEX": "character.book.closed",
        "LEN.FOR": "puzzlepiece",
        "LEN.HAB": "globe.europe.africa",
        "MAT.UNI": "ruler",
        "MAT.GEO": "triangle",
        "MAT.POR": "percent",
        "MAT.NUM": "divide.circle",
        "MAT.DIV": "square.grid.3x3",
        "MAT.OPE": "plus.forwardslash.minus",
        "MAT.ROM": "building.columns",
        "MAT.EST": "chart.bar",
        "MAT.PRO": "dice",
        "MAT.ALG": "arrow.triangle.branch",
    ]

    static func de(bloque: String) -> String { porBloque[bloque] ?? "square.stack" }

    /// Símbolo a partir de un id de competencia o de ítem (`LEN.ORT.AGU`, `LEN.ORT.AGU.0001`).
    static func de(competencia: String) -> String {
        de(bloque: competencia.split(separator: ".").prefix(2).joined(separator: "."))
    }
}

extension Font {
    /// SF Pro Rounded con estilo de Dynamic Type: números, XP y recompensas.
    static func redondeada(_ estilo: Font.TextStyle, peso: Font.Weight = .semibold) -> Font {
        .system(estilo, design: .rounded).weight(peso)
    }

    /// Títulos con la fuente de exhibición (Fredoka SemiBold, SIL OFL; D-060). Escala con Dynamic
    /// Type: `Font.custom(_:size:relativeTo:)` aplica `UIFontMetrics` del estilo indicado.
    static func exhibicion(_ estilo: Font.TextStyle) -> Font {
        FuenteExhibicion.registrar()
        return .custom(FuenteExhibicion.nombre, size: FuenteExhibicion.tamanoBase(estilo), relativeTo: estilo)
    }
}

/// Fuente de exhibición empaquetada (`Resources/Fuentes/Fredoka.ttf` + `OFL.txt`). Se registra
/// en tiempo de ejecución con CoreText (sin tocar el Info.plist).
enum FuenteExhibicion {
    static let nombre = "Fredoka-SemiBold"

    /// Tamaños base (en el tamaño de texto por defecto, "Grande") de cada estilo.
    static func tamanoBase(_ estilo: Font.TextStyle) -> CGFloat {
        switch estilo {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .subheadline: 15
        case .callout: 16
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    /// Registra la fuente una sola vez. Devuelve `true` si está disponible.
    @discardableResult
    static func registrar() -> Bool { registrada }

    private static let registrada: Bool = {
        guard let url = Bundle.main.url(forResource: "Fredoka", withExtension: "ttf") else { return false }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        return UIFont(name: nombre, size: 17) != nil
    }()

    /// Versión UIKit escalada con `UIFontMetrics` (la usan los tests de Dynamic Type).
    static func uiFont(_ estilo: UIFont.TextStyle, base: CGFloat, compatibleCon rasgos: UITraitCollection? = nil) -> UIFont {
        registrar()
        let fuente = UIFont(name: nombre, size: base) ?? .systemFont(ofSize: base, weight: .semibold)
        return UIFontMetrics(forTextStyle: estilo).scaledFont(for: fuente, compatibleWith: rasgos)
    }
}
