import SwiftUI

/// Colores del sistema de diseño v2 "Laboratorio táctil" (D-053). Definidos en el Asset
/// Catalog (`Resources/Assets.xcassets/Colores`) con variante clara y oscura y contraste AA
/// comprobado (UX_UI.md §4.1). El color codifica el área y el estado; nunca decora.
enum Paleta {
    static let fondo = Color("Fondo")
    /// Superficie neutra: baldosas, filas y fichas fuera del panel protagonista.
    static let superficie = Color("Superficie")
    static let textoPrincipal = Color("TextoPrincipal")
    static let textoSecundario = Color("TextoSecundario")
    static let borde = Color("Borde")
    /// Primario de Lengua (coral): rellenos con texto blanco, objetos manipulables y gráficos.
    static let lengua = Color("Lengua")
    /// Primario de Matemáticas (índigo).
    static let matematicas = Color("Matematicas")
    /// Tinte del panel protagonista de cada área (uno por pantalla).
    static let lenguaTinte = Color("LenguaTinte")
    static let matematicasTinte = Color("MatematicasTinte")
    /// Tinta de cada área: texto con color de área (títulos de competencia, etiquetas).
    static let lenguaTinta = Color("LenguaTinta")
    static let matematicasTinta = Color("MatematicasTinta")
    static let exito = Color("Exito")
    static let fallo = Color("Fallo")
    /// Relleno de recompensa (siempre con `textoSobreRecompensa` encima).
    static let recompensa = Color("Recompensa")
    /// Ámbar legible como texto sobre fondo, superficie o tintes.
    static let recompensaTexto = Color("RecompensaTexto")
    /// Texto sobre un relleno primario (Lengua, Matemáticas, éxito, fallo).
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

/// Radios v2: panel protagonista 16, fichas y piezas 10, celdas manipulables 4.
enum Radio {
    static let tarjeta: CGFloat = 16
    static let ficha: CGFloat = 10
    static let celda: CGFloat = 4
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

/// Panel protagonista: el único elemento tintado de la pantalla (la actividad principal).
struct PanelProtagonista<Contenido: View>: View {
    let tinte: Color
    var relleno: CGFloat = Espacio.l
    @ViewBuilder let contenido: () -> Contenido

    var body: some View {
        contenido()
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tinte, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
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
        "MAT.UNI": "ruler",
        "MAT.GEO": "triangle",
        "MAT.POR": "percent",
        "MAT.NUM": "divide.circle",
        "MAT.DIV": "square.grid.3x3",
        "MAT.OPE": "plus.forwardslash.minus",
        "MAT.ROM": "building.columns",
        "MAT.EST": "chart.bar",
        "MAT.PRO": "dice",
    ]

    static func de(bloque: String) -> String { porBloque[bloque] ?? "square.stack" }

    /// Símbolo a partir de un id de competencia o de ítem (`LEN.ORT.AGU`, `LEN.ORT.AGU.0001`).
    static func de(competencia: String) -> String {
        de(bloque: competencia.split(separator: ".").prefix(2).joined(separator: "."))
    }
}

extension Font {
    /// SF Rounded con estilo de Dynamic Type: números, XP y recompensas.
    static func redondeada(_ estilo: Font.TextStyle, peso: Font.Weight = .semibold) -> Font {
        .system(estilo, design: .rounded).weight(peso)
    }
}
