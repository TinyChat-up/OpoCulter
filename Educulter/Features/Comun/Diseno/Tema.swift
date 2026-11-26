import SwiftUI
import CoreText

/// Colores de la identidad editorial (05E parte 2, D-109), derivados del logo v5: tinta verde
/// noche, papel menta, salvia (Lengua), bosque (Matemáticas y botones primarios) y ámbar
/// (recompensa). Definidos en el Asset Catalog (`Resources/Assets.xcassets/Colores`) con variante
/// clara y oscura; un test comprueba el contraste WCAG de cada par texto/fondo usado (≥ 4,5:1).
/// Superficies planas: sin degradados, sin brillos y sin sombras.
/// Regla: **el texto sobre un relleno de color va en `textoSobre(relleno)`**.
enum Paleta {
    /// Papel: `#F4F8F0` en claro, `#142019` en oscuro.
    static let fondo = Color("Fondo")
    /// Tinta (`#16241F`; `#E7F0E0` en oscuro): marca, iconos y la línea de foco.
    static let contorno = Color("Tinta")
    /// Superficie (papel2: `#E7F0E0` / `#1E302A`): baldosas, filas y fichas.
    static let superficie = Color("Superficie")
    static let textoPrincipal = Color("TextoPrincipal")
    static let textoSecundario = Color("TextoSecundario")
    /// Línea fina de separación y borde de las superficies.
    static let borde = Color("Borde")
    /// Relleno de Lengua (salvia `#A9BD9F` / `#8FA685`), con `textoSobreAcento` encima.
    static let lengua = Color("Lengua")
    /// Relleno de Matemáticas y de los botones primarios (bosque `#2F4A40` / `#A9BD9F`), con
    /// `textoSobreBosque` encima.
    static let matematicas = Color("Matematicas")
    static let primario = matematicas
    /// Tinte del panel protagonista de cada área (uno por pantalla).
    static let lenguaTinte = Color("LenguaTinte")
    static let matematicasTinte = Color("MatematicasTinte")
    /// Tinta de cada área (salvia oscurecida `#536948`, bosque `#2F4A40`): texto con color de área, AA.
    static let lenguaTinta = Color("LenguaTinta")
    static let matematicasTinta = Color("MatematicasTinta")
    /// Acierto como texto o icono (AA sobre papel y tintes).
    static let exito = Color("Exito")
    /// Acierto como relleno, con `textoSobreBosque` encima.
    static let exitoRelleno = Color("ExitoRelleno")
    static let fallo = Color("Fallo")
    /// Relleno de recompensa (ámbar; siempre con `textoSobreRecompensa` encima).
    static let recompensa = Color("Recompensa")
    /// Ámbar legible como texto sobre fondo, superficie o tintes.
    static let recompensaTexto = Color("RecompensaTexto")
    /// Texto sobre salvia y ámbar: tinta oscura en los dos modos.
    static let textoSobreAcento = Color("TextoSobreAcento")
    static let textoSobreRecompensa = Color("TextoSobreRecompensa")
    /// Texto sobre bosque y sobre el relleno de acierto: papel en claro, tinta en oscuro.
    static let textoSobreBosque = Color("TextoSobreBosque")

    /// Color del texto sobre un relleno de la paleta.
    static func textoSobre(_ relleno: Color) -> Color {
        relleno == matematicas || relleno == exitoRelleno ? textoSobreBosque : textoSobreAcento
    }

    /// Primario de un área (`LEN` → salvia, `MAT` → bosque).
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

/// Radios (identidad editorial): paneles y botones 24, fichas 20, celdas manipulables 8.
enum Radio {
    static let tarjeta: CGFloat = 24
    static let ficha: CGFloat = 20
    static let celda: CGFloat = 8
}

/// Líneas finas: 1 pt en superficies y celdas; 2 pt solo para marcar un estado (seleccionado,
/// correcto o incorrecto).
enum Trazo {
    static let grueso: CGFloat = 1
    static let fino: CGFloat = 1
    static let estado: CGFloat = 2
}

extension View {
    /// Borde fino alrededor de una forma redondeada (por defecto, la línea suave de la paleta).
    func contornoTinta(radio: CGFloat, grosor: CGFloat = Trazo.fino, color: Color = Paleta.borde) -> some View {
        overlay(RoundedRectangle(cornerRadius: radio, style: .continuous).strokeBorder(color, lineWidth: grosor))
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
    /// Superficie pulsable plana: relleno y borde fino, sin sombra. Al pulsar se atenúa un poco
    /// (sin rebote). `sombra` se conserva por compatibilidad y ya no dibuja nada: lo que no se puede
    /// tocar queda igual de plano.
    func superficiePulsable(_ relleno: Color, radio: CGFloat, borde: Color = Paleta.borde,
                            grosor: CGFloat = Trazo.fino, discontinuo: Bool = false, sombra: Bool = true) -> some View {
        modifier(SuperficiePulsable(relleno: relleno, radio: radio, borde: borde, grosor: grosor, discontinuo: discontinuo, pulsable: sombra))
    }
}

private struct SuperficiePulsable: ViewModifier {
    let relleno: Color
    let radio: CGFloat
    let borde: Color
    let grosor: CGFloat
    let discontinuo: Bool
    let pulsable: Bool
    @Environment(\.pulsado) private var pulsado
    @Environment(\.isEnabled) private var activo

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: radio, style: .continuous)
        content
            .background(relleno, in: forma)
            .overlay(forma.strokeBorder(borde, style: StrokeStyle(lineWidth: grosor, dash: discontinuo ? [6, 4] : [])))
            .contentShape(forma)
            .opacity(pulsado && pulsable && activo ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: pulsado)
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

/// Panel protagonista: el único elemento tintado de la pantalla (la actividad principal), plano y
/// sin borde. Lo pulsable está dentro.
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
    /// Números y datos con la fuente del sistema (SF Pro) y cifras tabulares, con Dynamic Type.
    static func numerica(_ estilo: Font.TextStyle, peso: Font.Weight = .semibold) -> Font {
        .system(estilo).weight(peso).monospacedDigit()
    }

    /// Títulos: la serif del sistema (New York) en los estilos de título; SF Pro seminegrita en los
    /// demás. Escala con Dynamic Type.
    static func exhibicion(_ estilo: Font.TextStyle) -> Font {
        switch estilo {
        case .largeTitle, .title, .title2, .title3: return .system(estilo, design: .serif).weight(.semibold)
        default: return .system(estilo).weight(.semibold)
        }
    }

    /// Números de resultado (resumen, XP, récords): serif del sistema con cifras tabulares.
    static func resultado(_ estilo: Font.TextStyle = .largeTitle) -> Font {
        .system(estilo, design: .serif).weight(.semibold).monospacedDigit()
    }
}

/// Banda de rayas verticales salvia y bosque: solo como textura, en la pantalla de lanzamiento y en
/// la bienvenida (D-109). Decorativa para VoiceOver.
struct BandaRayas: View {
    var alto: CGFloat = 14
    var anchoRaya: CGFloat = 10

    var body: some View {
        Canvas { ctx, tam in
            var x: CGFloat = 0
            var i = 0
            while x < tam.width {
                ctx.fill(Path(CGRect(x: x, y: 0, width: anchoRaya, height: tam.height)), with: .color(i % 2 == 0 ? Paleta.lengua : Paleta.matematicas))
                x += anchoRaya
                i += 1
            }
        }
        .frame(height: alto)
        .accessibilityHidden(true)
    }
}
