import SwiftUI

/// Colores del sistema de diseño ("Calma enfocada"). Definidos en el Asset Catalog
/// (`Resources/Assets.xcassets/Colores`) con variante clara y oscura y contraste AA
/// comprobado (ver UX_UI.md §4).
enum Paleta {
    static let fondo = Color("Fondo")
    static let superficie = Color("Superficie")
    static let textoPrincipal = Color("TextoPrincipal")
    static let textoSecundario = Color("TextoSecundario")
    static let borde = Color("Borde")
    static let lengua = Color("Lengua")
    static let matematicas = Color("Matematicas")
    static let exito = Color("Exito")
    static let fallo = Color("Fallo")
    /// Relleno de recompensa (siempre con `textoSobreRecompensa` encima).
    static let recompensa = Color("Recompensa")
    /// Ámbar legible como texto sobre fondo o superficie.
    static let recompensaTexto = Color("RecompensaTexto")
    /// Texto sobre un relleno de acento (Lengua, Matemáticas, éxito, fallo).
    static let textoSobreAcento = Color("TextoSobreAcento")
    static let textoSobreRecompensa = Color("TextoSobreRecompensa")

    /// Color de acento de un área (`LEN` → coral, `MAT` → índigo).
    static func acento(area: String) -> Color {
        area == "MAT" ? matematicas : lengua
    }

    static func acento(competencia: String) -> Color {
        acento(area: Catalogo.area(de: competencia))
    }

    /// Colores (todos AA) para distinguir pares y etiquetas; siempre acompañados de número o texto.
    static let pares: [Color] = [matematicas, lengua, exito, recompensaTexto, textoSecundario]
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

enum Radio {
    static let tarjeta: CGFloat = 16
    static let ficha: CGFloat = 12
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
