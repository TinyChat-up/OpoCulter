import SwiftUI

/// Segmentar una oración o un verso en tramos etiquetados, con anidamiento.
///
/// Interacción (sin arrastre): tocar la primera palabra del tramo, tocar la última (o la
/// misma otra vez para un tramo de una palabra) y elegir la etiqueta. Si el tramo queda
/// dentro de otro, se anida automáticamente; si envuelve tramos existentes, pasan a ser
/// sus hijos. Los tramos se dibujan como corchetes de color por niveles bajo las palabras,
/// y se listan en forma de árbol (plegable), donde se pueden borrar.
///
/// Tras el primer toque, el tramo se ilumina en vivo: mientras se pulsa la palabra final,
/// se tiñe todo el tramo desde el inicio hasta ella, antes de soltar (D-049).
struct MecanicaSegmentar: View {
    let p: Payload.Segmentar
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var inicio: Int?
    @State private var fin: Int?
    @State private var aviso: String?
    /// Palabra que se está pulsando (vista previa del tramo antes del segundo toque).
    @State private var previa: Int?
    @State private var arbolPlegado = false
    @ScaledMetric(relativeTo: .caption2) private var altoBarra: CGFloat = 6

    private var segmentos: [Respuesta.SegmentoRespuesta] {
        if case .segmentar(let s) = respuesta { return s }
        return []
    }

    private var posicion: [String: Int] {
        Dictionary(p.tokens.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private func rango(_ s: Respuesta.SegmentoRespuesta) -> ClosedRange<Int> {
        let a = posicion[s.desde] ?? 0, b = posicion[s.hasta] ?? a
        return min(a, b)...max(a, b)
    }

    private func nivel(_ s: Respuesta.SegmentoRespuesta) -> Int {
        var n = 0
        var actual = s.padre
        let porId = Dictionary(segmentos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        while let id = actual, n < 16 {
            n += 1
            actual = porId[id]?.padre
        }
        return n
    }

    private var rangoPendiente: ClosedRange<Int>? {
        guard let inicio, let fin else { return nil }
        return min(inicio, fin)...max(inicio, fin)
    }

    /// Tramo en vivo: del inicio a la palabra pulsada, mientras no hay segundo toque.
    private var rangoPrevio: ClosedRange<Int>? {
        guard let inicio, fin == nil, let previa else { return nil }
        return min(inicio, previa)...max(inicio, previa)
    }

    private func colorEtiqueta(_ id: String) -> Color {
        let i = p.etiquetas.firstIndex { $0.id == id } ?? 0
        return Paleta.pares[i % Paleta.pares.count]
    }

    private func nombreEtiqueta(_ id: String) -> String {
        p.etiquetas.first { $0.id == id }?.nombre ?? id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.l) {
            if !ctx.corregido {
                Text(textoInstruccion)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(aviso == nil ? Paleta.textoPrincipal : Paleta.fallo)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("instruccionSegmentar")
                // Etiquetas justo encima de las palabras: se ven sin desplazarse.
                etiquetas
            }
            TarjetaSuperficie {
                DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.m) {
                    ForEach(Array(p.tokens.enumerated()), id: \.element.id) { i, token in tokenVista(i, token) }
                }
            }
            if !segmentos.isEmpty {
                arbol
            }
        }
        .sensoryFeedback(.selection, trigger: segmentos.count)
        .sensoryFeedback(.error, trigger: aviso) { _, nuevo in nuevo != nil }
    }

    private var textoInstruccion: String {
        if let aviso { return aviso }
        if inicio == nil { return "1. Toca la primera palabra del tramo." }
        if fin == nil { return "2. Toca la última palabra (o la misma, si es una sola)." }
        return "3. Elige la etiqueta del tramo."
    }

    // MARK: Tokens con corchetes por niveles

    private func tokenVista(_ i: Int, _ token: ElementoTexto) -> some View {
        let niveles = (segmentos.map(nivel).max() ?? -1) + 1
        let enPendiente = rangoPendiente?.contains(i) ?? (inicio == i)
        let enPrevia = !enPendiente && (rangoPrevio?.contains(i) ?? false)
        let contiene = segmentos.filter { rango($0).contains(i) }
        return VStack(alignment: .leading, spacing: 2) {
            Button {
                tocar(i)
            } label: {
                Ficha(texto: token.texto, estado: enPendiente ? .seleccionada : (enPrevia ? .enTramo : .normal), acento: ctx.acento)
            }
            .buttonStyle(EstiloPulsacion { pulsado in
                if pulsado { previa = i } else if previa == i { previa = nil }
            })
            .animation(.easeOut(duration: 0.12), value: rangoPrevio)
            .accessibilityLabel(token.texto)
            .accessibilityValue(valorToken(i, enPendiente: enPendiente, contiene: contiene))
            .accessibilityHint(inicio == nil || fin != nil ? "Marca el inicio del tramo" : "Marca el final del tramo")
            .accessibilityIdentifier("seg_token_\(token.id)")

            // Del nivel más interno (arriba) al más externo (abajo).
            ForEach((0..<niveles).reversed(), id: \.self) { n in
                let s = contiene.first { nivel($0) == n }
                // Barra del tramo en el color de su etiqueta (la leyenda de etiquetas y el árbol
                // dan el nombre). Sin texto dentro: así todo el texto visible es accesible y escala.
                // Decorativa para VoiceOver, que lee los tramos en cada palabra y en el árbol.
                Capsule()
                    .fill(s.map { colorEtiqueta($0.etiqueta) } ?? .clear)
                    .frame(height: altoBarra)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }
        }
    }

    private func color(de s: Respuesta.SegmentoRespuesta) -> Color {
        if ctx.corregido { return esCorrecto(s) ? Paleta.exito : Paleta.fallo }
        return colorEtiqueta(s.etiqueta)
    }

    private func valorToken(_ i: Int, enPendiente: Bool, contiene: [Respuesta.SegmentoRespuesta]) -> String {
        var partes: [String] = []
        if enPendiente { partes.append(inicio == i && fin == nil ? "inicio del tramo" : "en el tramo seleccionado") }
        partes += contiene.sorted { nivel($0) < nivel($1) }.map { "en \(nombreEtiqueta($0.etiqueta))" }
        return partes.joined(separator: ", ")
    }

    // MARK: Etiquetas

    private var etiquetas: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            DisposicionFlujo {
                ForEach(p.etiquetas, id: \.id) { e in
                    Button {
                        crear(etiqueta: e.id)
                    } label: {
                        HStack(spacing: Espacio.s) {
                            Circle().fill(colorEtiqueta(e.id)).frame(width: 12, height: 12).accessibilityHidden(true)
                            Text("\(e.nombre) · \(e.id)").font(.body.weight(.medium)).foregroundStyle(Paleta.textoPrincipal)
                        }
                        .padding(.horizontal, Espacio.m)
                        .frame(minHeight: Medidas.tactilMinimo)
                        .superficiePulsable(Paleta.superficie, radio: 22, borde: rangoPendiente == nil ? Paleta.borde : Paleta.contorno,
                                            sombra: rangoPendiente != nil)
                    }
                    .buttonStyle(.pulsable)
                    .accessibilityLabel("Etiquetar como \(e.nombre)")
                    .accessibilityHint(rangoPendiente == nil ? "Primero marca el inicio y el final del tramo" : "")
                    .accessibilityIdentifier("etiqueta_\(e.id)")
                }
            }
        }
    }

    // MARK: Árbol de segmentos

    private var arbol: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { arbolPlegado.toggle() }
            } label: {
                HStack {
                    Text("Tu análisis (\(segmentos.count))").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Paleta.textoSecundario)
                        .rotationEffect(.degrees(arbolPlegado ? -90 : 0))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: Medidas.tactilMinimo)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pulsable)
            .accessibilityLabel("Tu análisis, \(segmentos.count) tramos")
            .accessibilityValue(arbolPlegado ? "plegado" : "desplegado")
            .accessibilityHint(arbolPlegado ? "Despliega el árbol" : "Pliega el árbol")
            .accessibilityIdentifier("plegarArbol")
            if !arbolPlegado || ctx.corregido {
            ForEach(segmentos.sorted { (rango($0).lowerBound, -rango($0).upperBound, nivel($0)) < (rango($1).lowerBound, -rango($1).upperBound, nivel($1)) }, id: \.id) { s in
                let texto = p.tokens[rango(s)].map(\.texto).joined(separator: " ")
                HStack(spacing: Espacio.s) {
                    RoundedRectangle(cornerRadius: 2).fill(colorEtiqueta(s.etiqueta)).frame(width: 6).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(nombreEtiqueta(s.etiqueta)) (\(s.etiqueta))").font(.subheadline.weight(.semibold)).foregroundStyle(color(de: s))
                        Text(texto).font(.subheadline).foregroundStyle(Paleta.textoPrincipal)
                    }
                    Spacer(minLength: 0)
                    if ctx.corregido {
                        Image(systemName: esCorrecto(s) ? "checkmark" : "xmark")
                            .foregroundStyle(esCorrecto(s) ? Paleta.exito : Paleta.fallo)
                            .accessibilityHidden(true)
                    } else {
                        Button {
                            borrar(s.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Paleta.textoSecundario)
                                .frame(width: Medidas.tactilMinimo, height: Medidas.tactilMinimo)
                        }
                        .buttonStyle(.pulsable)
                        .accessibilityLabel("Borrar \(nombreEtiqueta(s.etiqueta)): \(texto)")
                        .accessibilityIdentifier("borrar_\(s.id)")
                    }
                }
                .padding(.leading, CGFloat(nivel(s)) * Espacio.l)
                .frame(minHeight: Medidas.tactilMinimo)
                .accessibilityElement(children: .combine)
                .accessibilityValue(ctx.corregido ? (esCorrecto(s) ? "correcto" : "incorrecto") : "")
            }
            }
        }
        .padding(Espacio.m)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .contornoTinta(radio: Radio.tarjeta)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("arbolSegmentos")
    }

    /// Un tramo del usuario es correcto si coincide en rango y etiqueta con uno esperado.
    private func esCorrecto(_ s: Respuesta.SegmentoRespuesta) -> Bool {
        p.segmentos.contains { $0.etiqueta == s.etiqueta && posicion[$0.desde] == rango(s).lowerBound && posicion[$0.hasta] == rango(s).upperBound }
    }

    // MARK: Acciones

    private func tocar(_ i: Int) {
        aviso = nil
        previa = nil
        if inicio == nil || fin != nil {
            inicio = i
            fin = nil
        } else {
            fin = i
        }
    }

    private func crear(etiqueta: String) {
        guard let r = rangoPendiente else { return }
        let existentes = segmentos
        // Un tramo no puede cruzarse con otro: o está dentro, o lo contiene, o va aparte.
        if existentes.contains(where: { s in
            let o = rango(s)
            return o.overlaps(r) && !(o.contains(r.lowerBound) && o.contains(r.upperBound)) && !(r.contains(o.lowerBound) && r.contains(o.upperBound))
        }) {
            aviso = "Ese tramo se cruza con otro. Ajusta el inicio o el final."
            inicio = nil
            fin = nil
            return
        }
        if existentes.contains(where: { rango($0) == r && $0.etiqueta == etiqueta }) {
            inicio = nil
            fin = nil
            return
        }
        // Padre: el tramo más pequeño (y más profundo) que contiene al nuevo.
        let padre = existentes
            .filter { rango($0).contains(r.lowerBound) && rango($0).contains(r.upperBound) }
            .min { (rango($0).count, -nivel($0)) < (rango($1).count, -nivel($1)) }
        let numero = (existentes.compactMap { Int($0.id.dropFirst()) }.max() ?? 0) + 1
        let nuevo = Respuesta.SegmentoRespuesta(id: "u\(numero)", desde: p.tokens[r.lowerBound].id, hasta: p.tokens[r.upperBound].id,
                                                etiqueta: etiqueta, padre: padre?.id)
        var resultado = existentes.map { s -> Respuesta.SegmentoRespuesta in
            var s = s
            // Los hermanos que quedan dentro del nuevo tramo pasan a ser sus hijos.
            if s.padre == padre?.id, rango(s) != r, r.contains(rango(s).lowerBound), r.contains(rango(s).upperBound) { s.padre = nuevo.id }
            return s
        }
        resultado.append(nuevo)
        respuesta = .segmentar(resultado)
        inicio = nil
        fin = nil
    }

    private func borrar(_ id: String) {
        guard let s = segmentos.first(where: { $0.id == id }) else { return }
        let resto = segmentos.filter { $0.id != id }.map { hijo -> Respuesta.SegmentoRespuesta in
            var hijo = hijo
            if hijo.padre == id { hijo.padre = s.padre }
            return hijo
        }
        respuesta = resto.isEmpty ? nil : .segmentar(resto)
    }
}

/// Estilo sin decoración que avisa de cuándo se pulsa y se suelta (vista previa en vivo).
struct EstiloPulsacion: ButtonStyle {
    let alCambiar: @MainActor (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pulsado in alCambiar(pulsado) }
    }
}
