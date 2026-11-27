import SwiftUI

// Mecánicas de la Fase 05H (D-123). Son el patrón `marcar` con una capa de `clasificar` (Rayos X) o
// de elección de forma (Editor): mismas fichas, misma disposición en flujo, todo con toques y el error
// marcado en la propia pieza. Necesitan su propio contenedor porque varias capas se resuelven sobre la
// misma oración (o el mismo párrafo) y la comprobación es por capas.

/// Orden fijo de las funciones para asignarles color (andamiaje de los peldaños 1–3).
private let ordenFunciones = ["SUJ", "NV", "CD", "CI", "ATR", "CCL", "CCT", "CCM", "CCC"]
private func colorFuncion(_ f: String) -> Color {
    Paleta.pares[(ordenFunciones.firstIndex(of: f) ?? 0) % Paleta.pares.count]
}

// MARK: - Rayos X

struct MecanicaRayosX: View {
    let p: Payload.RayosX
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var aviso: String?
    @State private var grupoElegido: String?
    @State private var verPersonas = false

    private var r: Respuesta.RespuestaRayosX {
        if case .rayosX(let r) = respuesta { return r }
        return Respuesta.RespuestaRayosX()
    }

    private func actualizar(_ cambio: (inout Respuesta.RespuestaRayosX) -> Void) {
        var nuevo = r
        cambio(&nuevo)
        respuesta = .rayosX(nuevo)
    }

    private var terminado: Bool { r.capa > p.capas }
    private var verResultado: Bool { ctx.corregido || (terminado && p.porCapas) }
    private var colores: Bool { p.colores && !ctx.sinAyudas }
    private var preguntas: Bool { p.preguntas && !ctx.sinAyudas }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            if !terminado {
                Text(titulo).font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityAddTraits(.isHeader).accessibilityIdentifier("capaRayosX")
                if preguntas, let g = p.guias["capa\(r.capa)"] {
                    Label(g, systemImage: "questionmark.circle").font(.footnote).foregroundStyle(Paleta.textoSecundario)
                        .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("guiaRayosX")
                }
            }
            TarjetaSuperficie {
                VStack(alignment: .leading, spacing: Espacio.s) {
                    DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                        ForEach(p.tokens, id: \.id) { token in tokenVista(token) }
                    }
                    if r.capa >= 3 || ctx.corregido {
                        Label("\(p.predicado): «\(p.texto(predicado))»", systemImage: "rectangle.dashed")
                            .font(.footnote.weight(.medium)).foregroundStyle(Paleta.textoSecundario)
                            .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("predicadoRayosX")
                    }
                    if let omitido = r.omitido {
                        Label("Sujeto omitido: \(omitido)", systemImage: "person.crop.circle.badge.questionmark")
                            .font(.footnote.weight(.medium)).foregroundStyle(colores ? colorFuncion("SUJ") : Paleta.textoPrincipal)
                    }
                }
            }
            if let aviso {
                MarcaError(texto: aviso).accessibilityIdentifier("avisoCapa")
            }
            if !terminado && !ctx.corregido { controlesCapa }
            if ctx.corregido { erroresFinales }
            if verResultado {
                Text("Esquema del análisis").font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                MecanicaSegmentar(p: p.esquema, ctx: ContextoMecanica(item: ctx.item, acento: ctx.acento,
                                                                      resultado: Resultado(correcto: true, fraccionCorrecta: 1, errores: [])),
                                  respuesta: .constant(.segmentar(p.esquema.segmentos.map {
                                      .init(id: $0.id, desde: $0.desde, hasta: $0.hasta, etiqueta: $0.etiqueta, padre: $0.padre)
                                  })), tituloLista: "Esquema del análisis")
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("esquemaRayosX")
            }
        }
        .retroHaptica(.selection, trigger: r.capa)
    }

    private var titulo: String {
        switch r.capa {
        case 1: "Capa 1 · Toca el verbo (núcleo del predicado)"
        case 2: "Capa 2 · Toca las palabras del sujeto"
        default: "Capa 4 · Lleva cada grupo del predicado a su función"
        }
    }

    private var predicado: [String] { p.verbo + p.grupos.flatMap(\.tokens) }

    // MARK: Fichas de la oración

    private func funcionDe(_ id: String) -> String? {
        if r.verbo.contains(id) && r.capa > 1 { return "NV" }
        if r.sujeto.contains(id) && r.capa > 2 { return "SUJ" }
        if let g = p.grupos.first(where: { $0.tokens.contains(id) }), let f = r.funciones[g.id] { return f }
        return nil
    }

    private func tokenVista(_ token: ElementoTexto) -> some View {
        let f = funcionDe(token.id)
        let seleccionada = (r.capa == 1 && r.verbo.contains(token.id)) || (r.capa == 2 && r.sujeto.contains(token.id))
        let estado: EstadoFicha = seleccionada ? .seleccionada : (f != nil && !colores ? .seleccionada : .normal)
        return VStack(spacing: 2) {
            Button { tocar(token.id) } label: {
                Ficha(texto: token.texto, estado: estado, acento: ctx.acento)
            }
            .buttonStyle(.pulsable)
            .disabled(ctx.corregido || terminado || r.capa > 2)
            Capsule().fill(f.map { colores ? colorFuncion($0) : Paleta.contorno } ?? .clear).frame(height: 4)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(f.map { GeneradorOracionSimple.nombres[$0] ?? $0 } ?? (seleccionada ? "marcada" : ""))
        .accessibilityIdentifier("rx_\(token.id)")
    }

    private func tocar(_ id: String) {
        aviso = nil
        actualizar { r in
            switch r.capa {
            case 1: r.verbo = r.verbo.contains(id) ? [] : [id]
            case 2:
                guard !r.verbo.contains(id) else { return }
                r.omitido = nil
                if r.sujeto.contains(id) { r.sujeto.remove(id) } else { r.sujeto.insert(id) }
            default: break
            }
        }
    }

    // MARK: Controles de la capa

    @ViewBuilder private var controlesCapa: some View {
        if r.capa == 2 {
            Button { verPersonas.toggle() } label: {
                Label("Sujeto omitido", systemImage: "person.crop.circle.badge.questionmark")
            }
            .buttonStyle(EstiloBotonSecundario(acento: ctx.acento))
            .accessibilityIdentifier("botonSujetoOmitido")
            if verPersonas {
                DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                    ForEach(p.personas, id: \.self) { persona in
                        Button {
                            aviso = nil
                            actualizar { $0.omitido = persona; $0.sujeto = [] }
                        } label: {
                            Ficha(texto: persona, estado: r.omitido == persona ? .seleccionada : .normal, acento: ctx.acento)
                        }
                        .buttonStyle(.pulsable)
                    }
                }
            }
        }
        if r.capa == 4 { capaFunciones }
        Button(p.porCapas ? "Comprobar la capa" : "Siguiente capa") { confirmarCapa() }
            .buttonStyle(EstiloBotonSecundario(acento: ctx.acento))
            .disabled(!capaCompleta)
            .accessibilityIdentifier("botonCapa")
    }

    private var capaCompleta: Bool {
        switch r.capa {
        case 1: !r.verbo.isEmpty
        case 2: !r.sujeto.isEmpty || r.omitido != nil
        default: p.grupos.allSatisfy { r.funciones[$0.id] != nil }
        }
    }

    private func confirmarCapa() {
        let capa = r.capa
        if p.porCapas {
            let errores = p.errores(capa: capa, r)
            if !errores.isEmpty {
                aviso = explicacion(errores.first!)
                actualizar { $0.fallos.insert(capa) }
                return
            }
        }
        aviso = nil
        actualizar { r in
            r.capa = capa + 1
            // La capa 3 (el predicado) se forma sola con el resto.
            if r.capa == 3 { r.capa = p.capas >= 4 ? 4 : p.capas + 1 }
        }
    }

    private func explicacion(_ error: String) -> String {
        if error.hasPrefix("grupo_"), let g = p.grupos.first(where: { "grupo_\($0.id)" == error }) {
            let elegida = r.funciones[g.id] ?? ""
            let nombre = p.funciones.first { $0.id == elegida }?.nombre ?? elegida
            return "«\(p.texto(g.tokens))» no es \(nombre.lowercased()): \(p.explicaciones[elegida] ?? "")"
        }
        return p.explicaciones[error] ?? "Revisa esta capa."
    }

    private var capaFunciones: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Instruccion(texto: "Toca un grupo y después su función (o arrástralo).")
            DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                ForEach(p.grupos) { g in
                    let asignada = r.funciones[g.id]
                    Button { grupoElegido = grupoElegido == g.id ? nil : g.id } label: {
                        VStack(spacing: 2) {
                            Ficha(texto: p.texto(g.tokens), estado: grupoElegido == g.id ? .seleccionada : .normal, acento: ctx.acento)
                            if let asignada {
                                Text(p.funciones.first { $0.id == asignada }?.nombre ?? asignada).font(.caption2.weight(.semibold))
                                    .foregroundStyle(colores ? colorFuncion(asignada) : Paleta.textoSecundario)
                            }
                        }
                    }
                    .buttonStyle(.pulsable)
                    .draggable(g.id)
                    .accessibilityIdentifier("grupo_\(g.id)")
                }
            }
            DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                ForEach(p.funciones, id: \.id) { f in
                    Button {
                        guard let g = grupoElegido else { return }
                        aviso = nil
                        actualizar { $0.funciones[g] = f.id }
                        grupoElegido = nil
                    } label: {
                        Ficha(texto: f.nombre, estado: .normal, acento: ctx.acento)
                            .overlay(alignment: .bottom) {
                                Capsule().fill(colores ? colorFuncion(f.id) : .clear).frame(height: 3).padding(.horizontal, Espacio.m)
                            }
                    }
                    .buttonStyle(.pulsable)
                    .dropDestination(for: String.self) { ids, _ in
                        guard let g = ids.first, p.grupos.contains(where: { $0.id == g }) else { return false }
                        actualizar { $0.funciones[g] = f.id }
                        return true
                    }
                    .accessibilityIdentifier("funcion_\(f.id)")
                }
            }
        }
    }

    @ViewBuilder private var erroresFinales: some View {
        let errores = (1...p.capas).flatMap { p.errores(capa: $0, r) }
        ForEach(errores, id: \.self) { e in MarcaError(texto: explicacion(e)) }
    }
}

// MARK: - Editor

struct MecanicaEditor: View {
    let p: Payload.Editor
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?

    private var r: Respuesta.RespuestaEditor {
        if case .editor(let r) = respuesta { return r }
        return Respuesta.RespuestaEditor()
    }

    private func texto(_ id: String) -> String { p.tokens.first { $0.id == id }?.texto ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            Instruccion(texto: "Toca las palabras mal escritas y elige su forma correcta.")
            TarjetaSuperficie {
                DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                    ForEach(p.tokens, id: \.id) { token in
                        Button { marcar(token.id) } label: {
                            Ficha(texto: r.cambios[token.id] ?? token.texto, estado: estado(token.id), acento: ctx.acento)
                        }
                        .buttonStyle(.pulsable)
                        .disabled(ctx.corregido)
                        .accessibilityAddTraits(r.marcadas.contains(token.id) ? .isSelected : [])
                        .accessibilityIdentifier("ed_\(token.id)")
                    }
                }
            }
            if !ctx.corregido {
                ForEach(r.marcadas.sorted { orden($0) < orden($1) }, id: \.self) { id in eleccion(id) }
            } else {
                resultado
            }
        }
        .retroHaptica(.selection, trigger: r.marcadas)
    }

    private func orden(_ id: String) -> Int { p.tokens.firstIndex { $0.id == id } ?? 0 }

    private func estado(_ id: String) -> EstadoFicha {
        let falta = p.faltas.first { $0.token == id }
        if ctx.corregido {
            if let falta { return r.cambios[id] == falta.correcta ? .correcta : (r.marcadas.contains(id) ? .incorrecta : .faltante) }
            return r.marcadas.contains(id) ? .incorrecta : .normal
        }
        return r.marcadas.contains(id) ? .seleccionada : .normal
    }

    private func marcar(_ id: String) {
        var n = r
        if n.marcadas.contains(id) {
            n.marcadas.remove(id); n.cambios[id] = nil
        } else {
            n.marcadas.insert(id)
            // Sin otra forma posible, la palabra se queda como está (y la marca cuenta como error).
            if p.formas[id] == nil { n.cambios[id] = texto(id) }
        }
        respuesta = n.marcadas.isEmpty ? nil : .editor(n)
    }

    @ViewBuilder private func eleccion(_ id: String) -> some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            Text("«\(texto(id))» →").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
            if let formas = p.formas[id] {
                DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                    ForEach(formas, id: \.self) { f in
                        Button {
                            var n = r
                            n.cambios[id] = f
                            respuesta = .editor(n)
                        } label: {
                            Ficha(texto: f, estado: r.cambios[id] == f ? .seleccionada : .normal, acento: ctx.acento)
                        }
                        .buttonStyle(.pulsable)
                        .accessibilityIdentifier("forma_\(id)_\(f)")
                    }
                }
            } else {
                Instruccion(texto: "Esta palabra no tiene otra forma en este juego. Si crees que está mal, piensa por qué.")
            }
        }
    }

    @ViewBuilder private var resultado: some View {
        ForEach(p.faltas, id: \.token) { f in
            let bien = r.cambios[f.token] == f.correcta
            Label("«\(f.correcta)»: \(f.uso)", systemImage: bien ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.footnote).foregroundStyle(bien ? Paleta.exito : Paleta.fallo).fixedSize(horizontal: false, vertical: true)
        }
        ForEach(r.marcadas.subtracting(p.faltas.map(\.token)).sorted(), id: \.self) { id in
            MarcaError(texto: "«\(texto(id))» estaba bien escrita.")
        }
        if p.penalizacion {
            let palabras = p.faltas.filter { !$0.tilde && r.cambios[$0.token] != $0.correcta }.count
            let tildes = p.faltas.filter { $0.tilde && r.cambios[$0.token] != $0.correcta }.count
            let total = Double(palabras) * 0.5 + Double(tildes) * 0.25
            Text("En el examen: −0,5 por palabra mal escrita y −0,25 por tilde. Te habrían quitado \(FormatoNumero.numero(Racional(numerador: Int(total * 100), denominador: 100)!)) puntos.")
                .font(.footnote.weight(.medium)).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("penalizacionEditor")
        }
    }
}
