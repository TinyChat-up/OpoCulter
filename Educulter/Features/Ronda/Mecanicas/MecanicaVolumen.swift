import SwiftUI

// MARK: - «Capas y sólidos» (patrón modelo con figura, 05K §1)

/// Volumen por capas: en los peldaños 1–2 el sólido se ve como cubos (se cuentan los de la capa de
/// la base y las capas, que se apilan); después se teclean el área de la base y la altura. El
/// resultado y su unidad, por separado.
struct MecanicaVolumen: View {
    let p: Payload.FiguraVolumen
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    /// Campo que escribe el teclado: el id de un paso o «resultado».
    @State private var campo = ""
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    static let resultado = "resultado"

    private var r: Respuesta.RespuestaVolumen {
        if case .volumen(let r) = respuesta { return r }
        return Respuesta.RespuestaVolumen()
    }

    private func actualizar(_ cambio: (inout Respuesta.RespuestaVolumen) -> Void) {
        var nuevo = r
        cambio(&nuevo)
        respuesta = .volumen(nuevo)
    }

    private var errores: [String] { ctx.resultado?.errores ?? ctx.marcasReintento }

    /// Capas rellenas: la de la base al empezar y, al indicar las capas, hasta ese número.
    private var capasLlenas: Int? {
        guard p.cubos, let total = p.capas else { return nil }
        guard let texto = r.valores["capas"], let n = Int(texto), n > 0 else { return 1 }
        return min(n, total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.l) {
            DibujoSolido(p: p, capasLlenas: capasLlenas, reducirMovimiento: reducirMovimiento)
                .animation(reducirMovimiento ? nil : .spring(duration: 0.45), value: capasLlenas)
            pasos
            resultado
            TecladoNumerico(texto: textoCampo, acento: ctx.acento, maximo: 10)
        }
        .onAppear { if campo.isEmpty { campo = p.campos.first?.id ?? Self.resultado } }
    }

    // MARK: Pasos

    private var pasos: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            if p.cubos {
                ForEach(Array(p.campos.enumerated()), id: \.element.id) { n, c in
                    Text(n == 0 ? "1. Cuenta los cubos de la capa de la base (o teclea el área de la base)" : "\(n + 1). Indica el número de capas")
                        .font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)
                    paso(c)
                }
            } else {
                Text("Pasos").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                ForEach(p.campos) { c in paso(c) }
            }
        }
    }

    private func paso(_ c: Payload.FiguraVolumen.Campo) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            campoValor(etiqueta: c.etiqueta, id: c.id, valor: r.valores[c.id] ?? "")
            if errores.contains("campo_\(c.id)") { MarcaError(texto: "Revisa este paso con las medidas del dibujo") }
        }
    }

    private var resultado: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text(p.cubos ? "\(p.campos.count + 1). Teclea el volumen" : "\(p.etiquetaResultado) y unidad")
                .font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            campoValor(etiqueta: p.etiquetaResultado, id: Self.resultado, valor: r.resultado)
            if errores.contains(where: { $0 == "resultado" || p.erroneos[$0] != nil }) { MarcaError(texto: "El resultado no es correcto") }
            HStack(spacing: Espacio.s) {
                ForEach(p.unidadesOpciones, id: \.self) { u in
                    Button { actualizar { $0.unidad = u } } label: { Text(u).frame(maxWidth: .infinity) }
                        .buttonStyle(EstiloBotonSecundario())
                        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                            .strokeBorder(r.unidad == u ? Paleta.matematicas : .clear, lineWidth: Trazo.estado))
                        .accessibilityLabel(Self.nombreUnidad(u))
                        .accessibilityAddTraits(r.unidad == u ? .isSelected : [])
                        .accessibilityIdentifier("unidad_\(u)")
                }
            }
            if errores.contains("unidad") { MarcaError(texto: "Revisa la unidad") }
        }
    }

    /// Nombre de la unidad para VoiceOver («centímetros cúbicos»).
    static func nombreUnidad(_ u: String) -> String {
        let nombres = ["mm": "milímetros", "cm": "centímetros", "dm": "decímetros", "m": "metros", "l": "litros", "ml": "mililitros"]
        if u.hasSuffix("³"), let n = nombres[String(u.dropLast())] { return "\(n) cúbicos" }
        if u.hasSuffix("²"), let n = nombres[String(u.dropLast())] { return "\(n) cuadrados" }
        return nombres[u] ?? u
    }

    private func campoValor(etiqueta: String, id: String, valor: String) -> some View {
        Button { campo = id } label: {
            HStack {
                Text(etiqueta).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text(valor.isEmpty ? "?" : valor).font(.numerica(.title3)).foregroundStyle(Paleta.textoPrincipal)
            }
            .padding(Espacio.m)
            .frame(minHeight: Medidas.tactilMinimo)
            .superficiePulsable(Paleta.superficie, radio: Radio.ficha, borde: campo == id ? Paleta.matematicas : Paleta.borde,
                                grosor: campo == id ? Trazo.estado : Trazo.fino)
        }
        .buttonStyle(.pulsable)
        .accessibilityLabel(etiqueta)
        .accessibilityValue(valor.isEmpty ? "vacío" : valor)
        .accessibilityAddTraits(campo == id ? .isSelected : [])
        .accessibilityIdentifier("campo_\(id)")
    }

    /// Texto que edita el teclado: el campo elegido.
    private var textoCampo: Binding<String> {
        Binding {
            campo == Self.resultado ? r.resultado : (r.valores[campo] ?? "")
        } set: { nuevo in
            let id = campo
            actualizar { if id == Self.resultado { $0.resultado = nuevo } else { $0.valores[id] = nuevo } }
        }
    }
}

// MARK: - Dibujo isométrico

/// Sólidos en perspectiva isométrica dibujados con `Path`, con las medidas rotuladas. Los cubos se
/// dibujan por capas (cada capa es una vista, para que se apilen con una transición breve).
struct DibujoSolido: View {
    let p: Payload.FiguraVolumen
    var capasLlenas: Int?
    var reducirMovimiento = false

    /// Proyección isométrica escalada al tamaño disponible.
    struct Mapa {
        let escala: Double
        let origen: CGPoint
        static let cos30 = 0.866_025_4
        static let sen30 = 0.5

        static func plano(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
            CGPoint(x: (x - y) * cos30, y: (x + y) * sen30 - z)
        }

        init(_ p: Payload.FiguraVolumen, tamano: CGSize, margen: Double = 34) {
            var puntos: [CGPoint] = []
            for s in p.solidos {
                for x in [s.x, s.x + s.largo] { for y in [s.y, s.y + s.ancho] { for z in [s.z, s.z + s.alto] { puntos.append(Self.plano(x, y, z)) } } }
            }
            let minX = puntos.map(\.x).min() ?? 0, maxX = puntos.map(\.x).max() ?? 1
            let minY = puntos.map(\.y).min() ?? 0, maxY = puntos.map(\.y).max() ?? 1
            let ancho = max(maxX - minX, 0.001), alto = max(maxY - minY, 0.001)
            escala = max(min((tamano.width - 2 * margen) / ancho, (tamano.height - 2 * margen) / alto), 0.1)
            origen = CGPoint(x: (tamano.width - ancho * escala) / 2 - minX * escala, y: (tamano.height - alto * escala) / 2 - minY * escala)
        }

        func pt(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
            let q = Self.plano(x, y, z)
            return CGPoint(x: origen.x + q.x * escala, y: origen.y + q.y * escala)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let m = Mapa(p, tamano: geo.size)
            ZStack {
                if p.cubos, let s = p.solidos.first, let llenas = capasLlenas {
                    Canvas { c, _ in Self.silueta(c, m, s) }
                    ForEach(0..<llenas, id: \.self) { k in
                        Canvas { c, _ in Self.caja(c, m, x: s.x, y: s.y, z: Double(k), l: s.largo, a: s.ancho, h: 1, rejilla: true) }
                            .transition(reducirMovimiento ? .opacity : .asymmetric(insertion: .offset(y: -28).combined(with: .opacity), removal: .opacity))
                    }
                } else {
                    Canvas { c, _ in
                        for s in p.solidos.sorted(by: { ($0.x + $0.y, $0.z) < ($1.x + $1.y, $1.z) }) {
                            switch s.forma {
                            case .ortoedro:
                                if let agua = p.agua, s.id == p.solidos.first?.id {
                                    Self.deposito(c, m, s, agua: agua)
                                } else {
                                    Self.caja(c, m, x: s.x, y: s.y, z: s.z, l: s.largo, a: s.ancho, h: s.alto, rejilla: false)
                                }
                            case .cilindro: Self.cilindro(c, m, s)
                            }
                        }
                        if p.solidos.count > 1 {
                            for s in p.solidos { Self.nombre(c, m, s) }
                        }
                    }
                }
                ForEach(Array(p.rotulos.enumerated()), id: \.offset) { _, rot in
                    if let s = p.solidos.first(where: { $0.id == rot.solido }) {
                        let (pos, linea) = Self.posicion(rot, s, m, otros: p.solidos, agua: p.agua)
                        if let linea {
                            Path { l in l.move(to: linea.0); l.addLine(to: linea.1) }
                                .stroke(Paleta.contorno, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        }
                        Text(rot.texto).font(.numerica(.caption)).foregroundStyle(Paleta.textoPrincipal)
                            .padding(.horizontal, 3).background(Paleta.fondo.opacity(0.9), in: Capsule())
                            .fixedSize()
                            .position(pos)
                    }
                }
            }
        }
        .frame(height: 230)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(p.cubos ? "Sólido de cubos" : "Sólido")
        .accessibilityValue(p.descripcion + (capasLlenas.map { " Capas apiladas: \($0)." } ?? ""))
        .accessibilityIdentifier("figuraVolumen")
    }

    // MARK: Piezas

    private static func poligono(_ v: [CGPoint]) -> Path {
        var path = Path()
        guard let primero = v.first else { return path }
        path.move(to: primero)
        for q in v.dropFirst() { path.addLine(to: q) }
        path.closeSubpath()
        return path
    }

    /// Ortoedro con sus tres caras visibles sombreadas y, si `rejilla`, las aristas de los cubos.
    static func caja(_ c: GraphicsContext, _ m: Mapa, x: Double, y: Double, z: Double, l: Double, a: Double, h: Double,
                     rejilla: Bool, color: Color = Paleta.matematicas, opacidad: Double = 1) {
        let (x1, y1, z1) = (x + l, y + a, z + h)
        let arriba = poligono([m.pt(x, y, z1), m.pt(x1, y, z1), m.pt(x1, y1, z1), m.pt(x, y1, z1)])
        let derecha = poligono([m.pt(x1, y, z), m.pt(x1, y1, z), m.pt(x1, y1, z1), m.pt(x1, y, z1)])
        let izquierda = poligono([m.pt(x, y1, z), m.pt(x1, y1, z), m.pt(x1, y1, z1), m.pt(x, y1, z1)])
        c.fill(arriba, with: .color(Paleta.superficie))
        c.fill(arriba, with: .color(color.opacity(0.22 * opacidad)))
        c.fill(izquierda, with: .color(Paleta.superficie))
        c.fill(izquierda, with: .color(color.opacity(0.42 * opacidad)))
        c.fill(derecha, with: .color(Paleta.superficie))
        c.fill(derecha, with: .color(color.opacity(0.62 * opacidad)))
        if rejilla {
            var r = Path()
            var i = 1.0
            while i < l - 0.001 {
                r.move(to: m.pt(x + i, y, z1)); r.addLine(to: m.pt(x + i, y1, z1))
                r.move(to: m.pt(x + i, y1, z)); r.addLine(to: m.pt(x + i, y1, z1))
                i += 1
            }
            var j = 1.0
            while j < a - 0.001 {
                r.move(to: m.pt(x, y + j, z1)); r.addLine(to: m.pt(x1, y + j, z1))
                r.move(to: m.pt(x1, y + j, z)); r.addLine(to: m.pt(x1, y + j, z1))
                j += 1
            }
            c.stroke(r, with: .color(Paleta.contorno.opacity(0.55)), lineWidth: 1)
        }
        for cara in [arriba, izquierda, derecha] { c.stroke(cara, with: .color(Paleta.contorno), lineWidth: 1.5) }
    }

    /// Contorno discontinuo del sólido entero con las líneas de cada capa (se ve cuántas hay).
    static func silueta(_ c: GraphicsContext, _ m: Mapa, _ s: Payload.FiguraVolumen.Solido) {
        let (x, y, x1, y1, h) = (s.x, s.y, s.x + s.largo, s.y + s.ancho, s.alto)
        var r = Path()
        let aristas: [((Double, Double, Double), (Double, Double, Double))] = [
            ((x, y, h), (x1, y, h)), ((x1, y, h), (x1, y1, h)), ((x1, y1, h), (x, y1, h)), ((x, y1, h), (x, y, h)),
            ((x, y1, 0), (x, y1, h)), ((x1, y1, 0), (x1, y1, h)), ((x1, y, 0), (x1, y, h)),
        ]
        for (a, b) in aristas { r.move(to: m.pt(a.0, a.1, a.2)); r.addLine(to: m.pt(b.0, b.1, b.2)) }
        var k = 1.0
        while k < h - 0.001 {
            r.move(to: m.pt(x, y1, k)); r.addLine(to: m.pt(x1, y1, k)); r.addLine(to: m.pt(x1, y, k))
            k += 1
        }
        c.stroke(r, with: .color(Paleta.textoSecundario), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    /// Depósito transparente con el agua hasta su altura.
    static func deposito(_ c: GraphicsContext, _ m: Mapa, _ s: Payload.FiguraVolumen.Solido, agua: Double) {
        caja(c, m, x: s.x, y: s.y, z: s.z, l: s.largo, a: s.ancho, h: agua, rejilla: false, color: Paleta.lengua, opacidad: 1.2)
        let (x, y, x1, y1, h) = (s.x, s.y, s.x + s.largo, s.y + s.ancho, s.alto)
        var r = Path()
        let aristas: [((Double, Double, Double), (Double, Double, Double))] = [
            ((x, y, h), (x1, y, h)), ((x1, y, h), (x1, y1, h)), ((x1, y1, h), (x, y1, h)), ((x, y1, h), (x, y, h)),
            ((x, y1, 0), (x, y1, h)), ((x1, y1, 0), (x1, y1, h)), ((x1, y, 0), (x1, y, h)),
            ((x, y1, 0), (x1, y1, 0)), ((x1, y1, 0), (x1, y, 0)),
        ]
        for (a, b) in aristas { r.move(to: m.pt(a.0, a.1, a.2)); r.addLine(to: m.pt(b.0, b.1, b.2)) }
        c.stroke(r, with: .color(Paleta.contorno), lineWidth: 1.5)
    }

    /// Cilindro: base y tapa elípticas unidas por los lados.
    static func cilindro(_ c: GraphicsContext, _ m: Mapa, _ s: Payload.FiguraVolumen.Solido) {
        let rad = s.largo / 2, cx = s.x + rad, cy = s.y + rad
        func elipse(_ z: Double, desde: Double = 0, hasta: Double = 2 * .pi) -> [CGPoint] {
            (0...48).map { i in
                let t = desde + (hasta - desde) * Double(i) / 48
                return m.pt(cx + rad * cos(t), cy + rad * sin(t), z)
            }
        }
        // Silueta: tangentes en θ = 135° (izquierda) y θ = −45° (derecha); delante, θ = 45°.
        let frenteAbajo = elipse(s.z, desde: -.pi / 4, hasta: 3 * .pi / 4)
        let atrasArriba = elipse(s.z + s.alto, desde: 3 * .pi / 4, hasta: 7 * .pi / 4)
        let cuerpo = poligono(frenteAbajo + atrasArriba)
        c.fill(cuerpo, with: .color(Paleta.superficie))
        c.fill(cuerpo, with: .color(Paleta.matematicas.opacity(0.45)))
        let tapa = poligono(elipse(s.z + s.alto))
        c.fill(tapa, with: .color(Paleta.superficie))
        c.fill(tapa, with: .color(Paleta.matematicas.opacity(0.2)))
        c.stroke(tapa, with: .color(Paleta.contorno), lineWidth: 1.5)
        var r = Path()
        r.move(to: frenteAbajo[0])
        for q in frenteAbajo.dropFirst() { r.addLine(to: q) }
        r.move(to: m.pt(cx + rad * cos(-.pi / 4), cy + rad * sin(-.pi / 4), s.z)); r.addLine(to: m.pt(cx + rad * cos(-.pi / 4), cy + rad * sin(-.pi / 4), s.z + s.alto))
        r.move(to: m.pt(cx + rad * cos(3 * .pi / 4), cy + rad * sin(3 * .pi / 4), s.z)); r.addLine(to: m.pt(cx + rad * cos(3 * .pi / 4), cy + rad * sin(3 * .pi / 4), s.z + s.alto))
        c.stroke(r, with: .color(Paleta.contorno), lineWidth: 1.5)
    }

    /// Letra del sólido (A, B) sobre su tapa.
    static func nombre(_ c: GraphicsContext, _ m: Mapa, _ s: Payload.FiguraVolumen.Solido) {
        let centro = m.pt(s.x + s.largo / 2, s.y + s.ancho / 2, s.z + s.alto)
        c.draw(Text(s.id).font(.headline).foregroundStyle(Paleta.textoPrincipal), at: centro)
    }

    /// Posición del rótulo de una arista (y la línea de la medida, en el radio y el diámetro).
    static func posicion(_ rot: Payload.FiguraVolumen.Rotulo, _ s: Payload.FiguraVolumen.Solido, _ m: Mapa,
                         otros: [Payload.FiguraVolumen.Solido], agua: Double? = nil) -> (CGPoint, (CGPoint, CGPoint)?) {
        let (x, y, z, x1, y1, z1) = (s.x, s.y, s.z, s.x + s.largo, s.y + s.ancho, s.z + s.alto)
        func medio(_ a: CGPoint, _ b: CGPoint, _ dx: Double, _ dy: Double) -> CGPoint { CGPoint(x: (a.x + b.x) / 2 + dx, y: (a.y + b.y) / 2 + dy) }
        let tapado = otros.contains { $0.id != s.id && $0.x >= x1 - 0.001 }
        switch rot.arista {
        case .largo: return (medio(m.pt(x, y1, z), m.pt(x1, y1, z), -14, 14), nil)
        case .ancho:
            if tapado { return (medio(m.pt(x, y, z1), m.pt(x, y1, z1), -16, -10), nil) }
            return (medio(m.pt(x1, y, z), m.pt(x1, y1, z), 16, 12), nil)
        case .alto:
            if s.forma == .cilindro {
                let r = s.largo / 2
                let a = m.pt(s.x + r + r * cos(3 * .pi / 4), s.y + r + r * sin(3 * .pi / 4), z)
                let b = m.pt(s.x + r + r * cos(3 * .pi / 4), s.y + r + r * sin(3 * .pi / 4), z1)
                return (medio(a, b, -26, 0), nil)
            }
            return (medio(m.pt(x, y1, z), m.pt(x, y1, z1), -26, 0), nil)
        case .agua:
            // Junto a la arista trasera derecha, a media altura del agua, con la línea de la medida.
            let a = m.pt(x1, y, z), b = m.pt(x1, y, z + (agua ?? s.alto))
            return (medio(a, b, 30, 0), (CGPoint(x: a.x + 8, y: a.y), CGPoint(x: b.x + 8, y: b.y)))
        case .radio:
            let r = s.largo / 2
            let centro = m.pt(s.x + r, s.y + r, z1), borde = m.pt(s.x + r + r * cos(-.pi / 4), s.y + r + r * sin(-.pi / 4), z1)
            return (medio(centro, borde, 0, -10), (centro, borde))
        case .diametro:
            let r = s.largo / 2
            let a = m.pt(s.x + r + r * cos(3 * .pi / 4), s.y + r + r * sin(3 * .pi / 4), z1)
            let b = m.pt(s.x + r + r * cos(-.pi / 4), s.y + r + r * sin(-.pi / 4), z1)
            return (medio(a, b, 0, -10), (a, b))
        }
    }
}
