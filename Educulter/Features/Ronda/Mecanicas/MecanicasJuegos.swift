import SwiftUI

// Mecánicas de los patrones nuevos de la Fase 05G (evidencia, recuerdo y modelo con figura). Todas
// siguen las reglas comunes: el botón inferior (Comprobar) es el de la ronda, todo se hace con
// toques, y el error se marca en la propia pieza con texto, no solo con color.

/// Marca de error en una pieza: icono y texto (no solo color).
struct MarcaError: View {
    let texto: String
    var body: some View {
        Label(texto, systemImage: "xmark.circle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Paleta.fallo)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Evidencia

/// Patrón `evidencia`: el texto base, fragmento a fragmento; se toca el que sostiene lo que pide la
/// consigna.
struct MecanicaEvidencia: View {
    let p: Payload.Evidencia
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?

    private var elegido: String? { if case .evidencia(let id) = respuesta { id } else { nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text(p.titulo).font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal)
                .accessibilityAddTraits(.isHeader)
            ForEach(p.fragmentos, id: \.id) { f in
                Button { respuesta = .evidencia(f.id) } label: {
                    VStack(alignment: .leading, spacing: Espacio.xs) {
                        Text(f.texto)
                            .font(.body)
                            .foregroundStyle(elegido == f.id && !ctx.corregido ? Paleta.textoSobre(ctx.acento) : Paleta.textoPrincipal)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if let marca = marca(f.id) { marca }
                    }
                    .padding(.horizontal, Espacio.m)
                    .padding(.vertical, Espacio.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .superficiePulsable(fondo(f.id), radio: Radio.celda, borde: borde(f.id), grosor: elegido == f.id ? Trazo.estado : Trazo.fino)
                }
                .buttonStyle(.pulsable)
                .accessibilityAddTraits(elegido == f.id ? .isSelected : [])
                .accessibilityValue(valorAccesible(f.id))
                .accessibilityIdentifier("fragmento_\(f.id)")
            }
        }
    }

    /// Tras corregir o en el reintento: el fragmento elegido dice si es la idea central o un detalle.
    private func marca(_ id: String) -> MarcaError? {
        let errores = ctx.resultado?.errores ?? ctx.marcasReintento
        guard id == elegido || (ctx.corregido && p.aceptados.contains(id) && ctx.resultado?.correcto == false) else { return nil }
        if ctx.corregido, p.aceptados.contains(id) { return nil }
        if errores.contains("detalle") { return MarcaError(texto: "Es un detalle") }
        if errores.contains("otro") { return MarcaError(texto: "No es la idea central") }
        return nil
    }

    private func fondo(_ id: String) -> Color {
        if ctx.corregido, p.aceptados.contains(id) { return Paleta.lenguaTinte }
        return elegido == id && !ctx.corregido ? ctx.acento : Paleta.superficie
    }

    private func borde(_ id: String) -> Color {
        if ctx.corregido {
            if p.aceptados.contains(id) { return Paleta.exito }
            if id == elegido { return Paleta.fallo }
        }
        if id == elegido, !ctx.marcasReintento.isEmpty { return Paleta.fallo }
        return id == elegido ? ctx.acento : Paleta.borde
    }

    private func valorAccesible(_ id: String) -> String {
        if ctx.corregido, p.aceptados.contains(id) { return "idea central" }
        if let m = marca(id) { return m.texto }
        return elegido == id ? "elegido" : ""
    }
}

// MARK: - Recuerdo

/// Patrón `recuerdo`: un campo breve (o «Lo he escrito en papel»); el modelo y los criterios solo
/// aparecen después, y el usuario se autoevalúa criterio a criterio.
struct MecanicaRecuerdo: View {
    let p: Payload.Recuerdo
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?

    private var r: Respuesta.RespuestaRecuerdo {
        if case .recuerdo(let r) = respuesta { return r }
        return Respuesta.RespuestaRecuerdo()
    }

    private func actualizar(_ cambio: (inout Respuesta.RespuestaRecuerdo) -> Void) {
        var nuevo = r
        cambio(&nuevo)
        respuesta = .recuerdo(nuevo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.l) {
            if !r.modeloVisto { escribir } else { autoevaluar }
        }
    }

    private var escribir: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            TextField("Escribe tu resumen", text: Binding(get: { r.texto }, set: { t in actualizar { $0.texto = String(t.prefix(p.maximo)) } }), axis: .vertical)
                .lineLimit(3...8)
                .padding(Espacio.m)
                .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
                .contornoTinta(radio: Radio.ficha)
                .accessibilityIdentifier("campoRecuerdo")
            Text("\(r.texto.count) de \(p.maximo) caracteres").font(.footnote).foregroundStyle(Paleta.textoSecundario)
            Button { actualizar { $0.enPapel.toggle() } } label: {
                Label(r.enPapel ? "Lo he escrito en papel ✓" : "Lo he escrito en papel", systemImage: r.enPapel ? "checkmark.square" : "square")
            }
            .buttonStyle(EstiloBotonSecundario())
            .accessibilityAddTraits(r.enPapel ? .isSelected : [])
            .accessibilityIdentifier("botonEnPapel")
            Button { actualizar { $0.modeloVisto = true } } label: { Label("Ver el modelo y los criterios", systemImage: "eye") }
                .buttonStyle(EstiloBotonPrincipal(acento: Paleta.primario))
                .disabled(!r.enPapel && r.texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("botonVerModelo")
        }
    }

    private var autoevaluar: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            if !r.texto.isEmpty {
                Text("Tu resumen").font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario).textCase(.uppercase)
                Text(r.texto).font(.body).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
            }
            Text("Modelo").font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario).textCase(.uppercase)
            Text(p.modelo).font(.body).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
                .padding(Espacio.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Paleta.lenguaTinte, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
                .accessibilityIdentifier("modeloRecuerdo")
            Text("¿Qué cumple tu resumen?").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            ForEach(Array(p.criterios.enumerated()), id: \.offset) { i, c in
                let marcado = r.cumplidos.contains(i)
                Button { actualizar { if marcado { $0.cumplidos.remove(i) } else { $0.cumplidos.insert(i) } } } label: {
                    HStack(alignment: .top, spacing: Espacio.m) {
                        Image(systemName: marcado ? "checkmark.square.fill" : "square").foregroundStyle(marcado ? Paleta.exito : Paleta.textoSecundario)
                            .accessibilityHidden(true)
                        Text(c).foregroundStyle(Paleta.textoPrincipal).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: Medidas.tactilMinimo)
                }
                .accessibilityAddTraits(marcado ? .isSelected : [])
                .accessibilityIdentifier("criterio_\(i)")
            }
            Text("Es una autoevaluación: no cuenta como nota ni para el dominio.").font(.footnote).foregroundStyle(Paleta.textoSecundario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Figura (modelo)

/// Patrón `modelo` con figura: estrategia, cortes, área de cada parte, total y unidad por separado.
struct MecanicaFiguraArea: View {
    let p: Payload.FiguraArea
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    /// Campo que escribe el teclado: el id de una parte o «total».
    @State private var campo = "total"
    /// Guía de corte (peldaños 3–5): orientación y posición en el lienzo.
    @State private var guiaVertical = true
    @State private var guia: Double = 0
    @State private var avisoCorte: String?

    private var r: Respuesta.RespuestaFigura {
        if case .figura(let r) = respuesta { return r }
        return Respuesta.RespuestaFigura()
    }

    private func actualizar(_ cambio: (inout Respuesta.RespuestaFigura) -> Void) {
        var nuevo = r
        cambio(&nuevo)
        respuesta = .figura(nuevo)
    }

    private var errores: [String] { ctx.resultado?.errores ?? ctx.marcasReintento }
    private var descomposicion: Payload.FiguraArea.Descomposicion? { p.descomposicion(estrategia: r.estrategia, cortes: r.cortes) }
    private var cortesVisibles: Bool { p.mostrarCortes && !ctx.sinAyudas }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.l) {
            figura
            estrategia
            if r.estrategia != nil { cortes }
            if let d = descomposicion { partes(d) }
            total
            TecladoNumerico(texto: textoCampo, acento: ctx.acento, maximo: 10)
        }
        .onAppear { guia = p.ancho / 2 }
    }

    // MARK: Dibujo

    private var figura: some View {
        let lienzo = CGSize(width: p.ancho, height: p.alto)
        return GeometryReader { geo in
            let escala = min(geo.size.width / lienzo.width, geo.size.height / lienzo.height)
            let origen = CGPoint(x: (geo.size.width - lienzo.width * escala) / 2, y: (geo.size.height - lienzo.height * escala) / 2)
            let punto = { (q: Payload.FiguraArea.Punto) in CGPoint(x: origen.x + q.x * escala, y: origen.y + q.y * escala) }
            ZStack {
                Canvas { c, _ in
                    // Cuadrícula.
                    var rejilla = Path()
                    var x = 0.0
                    while x <= p.ancho + 0.001 { rejilla.move(to: punto(.init(x: x, y: 0))); rejilla.addLine(to: punto(.init(x: x, y: p.alto))); x += p.paso }
                    var y = 0.0
                    while y <= p.alto + 0.001 { rejilla.move(to: punto(.init(x: 0, y: y))); rejilla.addLine(to: punto(.init(x: p.ancho, y: y))); y += p.paso }
                    c.stroke(rejilla, with: .color(Paleta.borde.opacity(0.6)), lineWidth: 0.5)
                    // Región pintada con el color del área; el hueco, en blanco (superficie), bien distinto.
                    for pieza in p.region where pieza.signo > 0 { c.fill(camino(pieza.forma, punto), with: .color(Paleta.matematicas.opacity(0.3))) }
                    for pieza in p.region where pieza.signo < 0 { c.fill(camino(pieza.forma, punto), with: .color(Paleta.superficie)) }
                    for pieza in p.region { c.stroke(camino(pieza.forma, punto), with: .color(Paleta.contorno), lineWidth: 2) }
                    // Cortes: discontinuos los candidatos (peldaños 1–2), continuos los elegidos.
                    for s in p.cortes {
                        let elegido = r.cortes.contains(s.id)
                        guard elegido || cortesVisibles else { continue }
                        var l = Path(); l.move(to: punto(s.a)); l.addLine(to: punto(s.b))
                        c.stroke(l, with: .color(elegido ? Paleta.matematicas : Paleta.textoSecundario),
                                 style: StrokeStyle(lineWidth: elegido ? 3 : 2, dash: elegido ? [] : [6, 5]))
                    }
                    // Guía de corte (peldaños 3–5).
                    if !cortesVisibles, r.estrategia != nil {
                        var g = Path()
                        if guiaVertical { g.move(to: punto(.init(x: guia, y: 0))); g.addLine(to: punto(.init(x: guia, y: p.alto))) }
                        else { g.move(to: punto(.init(x: 0, y: guia))); g.addLine(to: punto(.init(x: p.ancho, y: guia))) }
                        c.stroke(g, with: .color(Paleta.recompensaTexto), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    }
                }
                // Rótulos de las medidas.
                ForEach(Array(p.rotulos.enumerated()), id: \.offset) { _, rot in
                    let a = punto(rot.a), b = punto(rot.b)
                    Text(rot.texto).font(.numerica(.caption)).foregroundStyle(Paleta.textoPrincipal)
                        .padding(.horizontal, 3).background(Paleta.fondo.opacity(0.9), in: Capsule())
                        .position(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                }
                // Nombres de las partes (A, B, C).
                if let d = descomposicion {
                    ForEach(d.partes) { parte in
                        // Al restar, el centro de la pieza grande cae en el hueco: su letra va en la esquina.
                        let c = parte.signo > 0 && d.partes.contains { $0.signo < 0 } ? esquina(parte.forma, punto) : centro(parte.forma, punto)
                        Text(parte.id).font(.headline).foregroundStyle(errores.contains("parte_\(parte.id)") ? Paleta.fallo : Paleta.textoPrincipal)
                            .position(c)
                    }
                }
                // Toques sobre los cortes candidatos (peldaños 1–2).
                if cortesVisibles && r.estrategia != nil {
                    ForEach(p.cortes) { s in
                        let a = punto(s.a), b = punto(s.b)
                        Button { alternar(s.id) } label: { Color.clear.frame(width: 44, height: 44).contentShape(Rectangle()) }
                            .position(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                            .accessibilityLabel("Línea de corte \(s.id)")
                            .accessibilityAddTraits(r.cortes.contains(s.id) ? .isSelected : [])
                            .accessibilityIdentifier("corte_\(s.id)")
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 4).onChanged { v in
                guard !cortesVisibles, r.estrategia != nil else { return }
                let pos = guiaVertical ? (v.location.x - origen.x) / escala : (v.location.y - origen.y) / escala
                guia = min(max((pos / p.paso).rounded() * p.paso, 0), guiaVertical ? p.ancho : p.alto)
            })
        }
        .aspectRatio(p.ancho / p.alto, contentMode: .fit)
        .frame(maxHeight: 260)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Figura")
        .accessibilityValue(p.descripcion)
        .accessibilityIdentifier("figuraArea")
    }

    private func camino(_ f: Payload.FiguraArea.Forma, _ punto: (Payload.FiguraArea.Punto) -> CGPoint) -> Path {
        var path = Path()
        switch f {
        case .poligono(let v):
            guard let primero = v.first else { return path }
            path.move(to: punto(primero))
            for q in v.dropFirst() { path.addLine(to: punto(q)) }
            path.closeSubpath()
        case .semicirculo(let a, let b):
            let pa = punto(a), pb = punto(b)
            let centro = CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2)
            let radio = hypot(pb.x - pa.x, pb.y - pa.y) / 2
            let angulo = atan2(pb.y - pa.y, pb.x - pa.x)
            path.move(to: pa)
            path.addArc(center: centro, radius: radio, startAngle: .radians(angulo + .pi), endAngle: .radians(angulo), clockwise: false)
            path.closeSubpath()
        }
        return path
    }

    private func esquina(_ f: Payload.FiguraArea.Forma, _ punto: (Payload.FiguraArea.Punto) -> CGPoint) -> CGPoint {
        guard case .poligono(let v) = f else { return centro(f, punto) }
        let ps = v.map(punto)
        return CGPoint(x: (ps.map(\.x).min() ?? 0) + 18, y: (ps.map(\.y).min() ?? 0) + 18)
    }

    private func centro(_ f: Payload.FiguraArea.Forma, _ punto: (Payload.FiguraArea.Punto) -> CGPoint) -> CGPoint {
        switch f {
        case .poligono(let v):
            let ps = v.map(punto)
            return CGPoint(x: ps.map(\.x).reduce(0, +) / CGFloat(max(ps.count, 1)), y: ps.map(\.y).reduce(0, +) / CGFloat(max(ps.count, 1)))
        case .semicirculo(let a, let b):
            let pa = punto(a), pb = punto(b)
            return CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2 + (pa.y == pb.y ? -18 : 0))
        }
    }

    // MARK: Pasos

    private var estrategia: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("1. Estrategia").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            HStack(spacing: Espacio.s) {
                ForEach(Payload.FiguraArea.Estrategia.allCases, id: \.self) { e in
                    Button { actualizar { $0.estrategia = e; $0.cortes = []; $0.areas = [:] }; avisoCorte = nil } label: {
                        Text(e.nombre).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EstiloBotonSecundario())
                    .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                        .strokeBorder(r.estrategia == e ? Paleta.matematicas : .clear, lineWidth: Trazo.estado))
                    .accessibilityAddTraits(r.estrategia == e ? .isSelected : [])
                    .accessibilityIdentifier("estrategia_\(e.rawValue)")
                }
            }
            if let e = r.estrategia, !p.estrategiasValidas.contains(e) {
                MarcaError(texto: e == .restar ? "Esta figura no tiene ningún hueco que restar: suma sus partes." : "Aquí es más sencillo restar el hueco.")
            }
        }
    }

    private var cortes: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("2. Cortes").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            if cortesVisibles {
                Text("Toca las líneas discontinuas para cortar la figura en partes conocidas.")
                    .font(.subheadline).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Arrastra la guía sobre la figura (o muévela con los botones) y corta donde separe partes conocidas.")
                    .font(.subheadline).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Espacio.s) {
                    Button(guiaVertical ? "Guía vertical" : "Guía horizontal") { guiaVertical.toggle(); guia = (guiaVertical ? p.ancho : p.alto) / 2 }
                        .buttonStyle(EstiloBotonSecundario())
                        .accessibilityIdentifier("botonOrientacionGuia")
                    Button { guia = max(0, guia - p.paso) } label: { Image(systemName: guiaVertical ? "arrow.left" : "arrow.up") }
                        .buttonStyle(EstiloBotonSecundario()).frame(width: 64)
                        .accessibilityLabel("Mover la guía atrás")
                    Button { guia = min(guiaVertical ? p.ancho : p.alto, guia + p.paso) } label: { Image(systemName: guiaVertical ? "arrow.right" : "arrow.down") }
                        .buttonStyle(EstiloBotonSecundario()).frame(width: 64)
                        .accessibilityLabel("Mover la guía adelante")
                }
                Button("Cortar aquí") { cortarConGuia() }
                    .buttonStyle(EstiloBotonSecundario())
                    .accessibilityIdentifier("botonCortarAqui")
                if !r.cortes.isEmpty {
                    Button("Quitar los cortes") { actualizar { $0.cortes = []; $0.areas = [:] } }
                        .font(.subheadline)
                        .accessibilityIdentifier("botonQuitarCortes")
                }
            }
            if let avisoCorte { MarcaError(texto: avisoCorte) }
            if !r.cortes.isEmpty && descomposicion == nil {
                Text("Con estos cortes aún no quedan partes conocidas.").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
            }
            if r.estrategia == .restar, descomposicion == nil, p.descomposiciones.contains(where: { $0.estrategia == .restar && $0.cortes.isEmpty }) {
                Button("Sin cortes: el rectángulo completo y el hueco") { actualizar { $0.cortes = [] } }
                    .font(.subheadline)
            }
        }
    }

    private func alternar(_ id: String) {
        actualizar { if $0.cortes.contains(id) { $0.cortes.remove(id) } else { $0.cortes.insert(id) }; $0.areas = [:] }
    }

    /// Corta por la guía: vale si coincide con un corte candidato.
    private func cortarConGuia() {
        let candidato = p.cortes.first { s in
            guiaVertical ? (abs(s.a.x - guia) < 0.001 && abs(s.b.x - guia) < 0.001) : (abs(s.a.y - guia) < 0.001 && abs(s.b.y - guia) < 0.001)
        }
        if let candidato {
            avisoCorte = nil
            actualizar { $0.cortes.insert(candidato.id); $0.areas = [:] }
        } else {
            avisoCorte = "Ese corte no separa la figura en partes conocidas."
        }
    }

    private func partes(_ d: Payload.FiguraArea.Descomposicion) -> some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("3. Área de cada parte").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            ForEach(d.partes) { parte in
                VStack(alignment: .leading, spacing: 2) {
                    campoValor(etiqueta: "\(parte.id) (\(parte.signo > 0 ? "suma" : "resta"))", id: parte.id, valor: r.areas[parte.id] ?? "")
                    if errores.contains("parte_\(parte.id)") { MarcaError(texto: "Revisa qué dos medidas son la base y la altura de esta parte") }
                }
            }
        }
    }

    private var total: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("4. Total y unidad").font(.headline).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            campoValor(etiqueta: "Total", id: "total", valor: r.total)
            if errores.contains("total") { MarcaError(texto: "El total no es correcto") }
            HStack(spacing: Espacio.s) {
                ForEach(p.unidadesOpciones, id: \.self) { u in
                    Button { actualizar { $0.unidad = u } } label: { Text(u).frame(maxWidth: .infinity) }
                        .buttonStyle(EstiloBotonSecundario())
                        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                            .strokeBorder(r.unidad == u ? Paleta.matematicas : .clear, lineWidth: Trazo.estado))
                        .accessibilityAddTraits(r.unidad == u ? .isSelected : [])
                        .accessibilityIdentifier("unidad_\(u)")
                }
            }
            if errores.contains("unidadLineal") { MarcaError(texto: "Multiplicas metros por metros: el área va en unidades cuadradas") }
            else if errores.contains("unidad") { MarcaError(texto: "Revisa la unidad") }
        }
    }

    private func campoValor(etiqueta: String, id: String, valor: String) -> some View {
        Button { campo = id } label: {
            HStack {
                Text(etiqueta).foregroundStyle(Paleta.textoSecundario)
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
            campo == "total" ? r.total : (r.areas[campo] ?? "")
        } set: { nuevo in
            actualizar { if campo == "total" { $0.total = nuevo } else { $0.areas[campo] = nuevo } }
        }
    }
}
