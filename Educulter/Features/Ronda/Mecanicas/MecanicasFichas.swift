import SwiftUI

// MARK: - Clasificar

/// Fichas a cajas. Arrastrar o, sin arrastre, tocar la ficha y después la caja.
struct MecanicaClasificar: View {
    let p: Payload.Clasificar
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var seleccion: String?

    private var asignacion: [String: String] {
        if case .clasificar(let r) = respuesta { return r }
        return [:]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            let sueltas = p.fichas.filter { asignacion[$0.id] == nil }
            if !ctx.corregido {
                Instruccion(texto: "Arrastra cada ficha a su caja, o tócala y después toca la caja.")
            }
            if !sueltas.isEmpty {
                DisposicionFlujo {
                    ForEach(sueltas, id: \.id) { ficha in fichaVista(ficha) }
                }
                .padding(.vertical, Espacio.xs)
            }
            ForEach(p.categorias, id: \.id) { categoria in caja(categoria) }
        }
        .sensoryFeedback(.selection, trigger: asignacion)
    }

    private func fichaVista(_ ficha: Payload.Clasificar.Ficha) -> some View {
        let colocada = asignacion[ficha.id] != nil
        let estado: EstadoFicha = ctx.corregido
            ? (ctx.esError(ficha.id) ? .incorrecta : .correcta)
            : (seleccion == ficha.id ? .seleccionada : .normal)
        return Button {
            if colocada {
                var r = asignacion
                r[ficha.id] = nil
                respuesta = .clasificar(r)
                seleccion = ficha.id
            } else {
                seleccion = seleccion == ficha.id ? nil : ficha.id
            }
        } label: {
            Ficha(texto: ficha.texto, estado: estado, acento: ctx.acento)
        }
        .buttonStyle(.plain)
        .draggable(ficha.id)
        .accessibilityValue(estado.descripcionAccesible ?? (colocada ? "colocada" : "sin colocar"))
        .accessibilityHint(colocada ? "Toca para devolverla al montón" : "Toca para seleccionarla y después toca una caja")
        .accessibilityActions {
            ForEach(p.categorias, id: \.id) { c in
                Button("Mover a \(c.nombre)") { colocar(ficha.id, en: c.id) }
            }
        }
        .accessibilityIdentifier("ficha_\(ficha.id)")
    }

    private func caja(_ categoria: ElementoNombre) -> some View {
        let dentro = p.fichas.filter { asignacion[$0.id] == categoria.id }
        let activa = seleccion != nil && !ctx.corregido
        return VStack(alignment: .leading, spacing: Espacio.s) {
            // Cabecera de la caja: es el botón de destino en el modo sin arrastre.
            Button {
                if let seleccion { colocar(seleccion, en: categoria.id) }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoria.nombre).font(.subheadline.bold()).foregroundStyle(ctx.acento)
                    if dentro.isEmpty || activa {
                        Text(activa ? "Toca para colocar aquí" : "Vacía")
                            .font(.footnote)
                            .foregroundStyle(Paleta.textoSecundario)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Caja \(categoria.nombre)")
            .accessibilityValue(dentro.isEmpty ? "vacía" : dentro.map(\.texto).joined(separator: ", "))
            .accessibilityHint("Toca para colocar aquí la ficha seleccionada")
            .accessibilityIdentifier("caja_\(categoria.id)")
            if !dentro.isEmpty {
                DisposicionFlujo {
                    ForEach(dentro, id: \.id) { ficha in fichaVista(ficha) }
                }
            }
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                .strokeBorder(activa ? ctx.acento : Paleta.borde, style: StrokeStyle(lineWidth: activa ? 2 : 1, dash: activa ? [6, 4] : []))
        )
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            colocar(id, en: categoria.id)
            return true
        }
        .accessibilityElement(children: .contain)
    }

    private func colocar(_ fichaId: String, en categoria: String) {
        guard !ctx.corregido, p.fichas.contains(where: { $0.id == fichaId }) else { return }
        var r = asignacion
        r[fichaId] = categoria
        respuesta = .clasificar(r)
        seleccion = nil
    }
}

// MARK: - Ordenar

/// Lista reordenable: arrastrar una ficha sobre otra, tocar una y luego su nuevo puesto,
/// o acciones "Subir"/"Bajar" con VoiceOver.
struct MecanicaOrdenar: View {
    let p: Payload.Ordenar
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var seleccion: String?

    private var orden: [String] {
        if case .ordenar(let o) = respuesta { return o }
        return Self.ordenInicial(p)
    }

    /// Orden de partida: el del archivo; si coincidiera con el correcto, se rota una posición.
    static func ordenInicial(_ p: Payload.Ordenar) -> [String] {
        let ids = p.fichas.map(\.id)
        guard ids == p.ordenCorrecto, ids.count > 1 else { return ids }
        return Array(ids.dropFirst()) + [ids[0]]
    }

    var body: some View {
        let textos = Dictionary(p.fichas.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
        VStack(alignment: .leading, spacing: Espacio.s) {
            if !ctx.corregido {
                Instruccion(texto: "Arrastra para reordenar, o toca una ficha y después el puesto al que quieres moverla.")
            }
            if let inicio = p.etiquetaInicio {
                Label(inicio, systemImage: "arrow.down").font(.footnote.bold()).foregroundStyle(ctx.acento)
            }
            ForEach(Array(orden.enumerated()), id: \.element) { indice, id in
                let estado: EstadoFicha = ctx.corregido
                    ? (ctx.esError(id) ? .incorrecta : .correcta)
                    : (seleccion == id ? .seleccionada : .normal)
                Button {
                    tocar(id)
                } label: {
                    HStack(spacing: Espacio.m) {
                        Text("\(indice + 1)")
                            .font(.redondeada(.headline))
                            .foregroundStyle(ctx.acento)
                            .frame(minWidth: 28)
                        Ficha(texto: textos[id] ?? id, estado: estado, acento: ctx.acento, anchoCompleto: true, alineacion: .leading)
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(Paleta.textoSecundario)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)
                .draggable(id)
                .dropDestination(for: String.self) { ids, _ in
                    guard let origen = ids.first else { return false }
                    mover(origen, a: indice)
                    return true
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Puesto \(indice + 1): \(textos[id] ?? id)")
                .accessibilityValue(estado.descripcionAccesible ?? "")
                .accessibilityActions {
                    Button("Subir") { mover(id, a: max(indice - 1, 0)) }
                    Button("Bajar") { mover(id, a: min(indice + 1, orden.count - 1)) }
                }
                .accessibilityIdentifier("orden_\(id)")
            }
            if let fin = p.etiquetaFin {
                Label(fin, systemImage: "flag.checkered").font(.footnote.bold()).foregroundStyle(ctx.acento)
            }
        }
        .onAppear { if respuesta == nil { respuesta = .ordenar(Self.ordenInicial(p)) } }
        .sensoryFeedback(.selection, trigger: orden)
    }

    private func tocar(_ id: String) {
        if let actual = seleccion, actual != id, let destino = orden.firstIndex(of: id) {
            mover(actual, a: destino)
            seleccion = nil
        } else {
            seleccion = seleccion == id ? nil : id
        }
    }

    private func mover(_ id: String, a destino: Int) {
        guard !ctx.corregido, let origen = orden.firstIndex(of: id) else { return }
        var o = orden
        o.remove(at: origen)
        o.insert(id, at: min(destino, o.count))
        respuesta = .ordenar(o)
    }
}

// MARK: - Emparejar

/// Dos columnas: tocar un elemento de cada una crea el par (color y número compartidos).
struct MecanicaEmparejar: View {
    let p: Payload.Emparejar
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var izquierdaSeleccionada: String?
    @State private var derechaSeleccionada: String?
    @Environment(\.dynamicTypeSize) private var tamano

    private var pares: [Respuesta.ParRespuesta] {
        if case .emparejar(let r) = respuesta { return r }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            if !ctx.corregido {
                Instruccion(texto: "Toca un elemento de cada columna para unirlos. Toca un par para deshacerlo.")
            }
            let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Espacio.l)) : AnyLayout(HStackLayout(alignment: .top, spacing: Espacio.m))
            disposicion {
                columna(p.izquierda, izquierda: true)
                columna(p.derecha, izquierda: false)
            }
        }
        .sensoryFeedback(.selection, trigger: pares)
    }

    private func columna(_ elementos: [ElementoTexto], izquierda: Bool) -> some View {
        VStack(spacing: Espacio.s) {
            ForEach(elementos, id: \.id) { e in
                let indicePar = pares.firstIndex { izquierda ? $0.izquierda == e.id : $0.derecha == e.id }
                let seleccionado = izquierda ? izquierdaSeleccionada == e.id : derechaSeleccionada == e.id
                Button {
                    tocar(e.id, izquierda: izquierda)
                } label: {
                    elementoVista(e.texto, indicePar: indicePar, seleccionado: seleccionado, estado: estado(e.id, izquierda: izquierda))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(e.texto)
                .accessibilityValue(valorAccesible(e.id, izquierda: izquierda, indicePar: indicePar))
                .accessibilityAddTraits(seleccionado ? .isSelected : [])
                .accessibilityActions {
                    if izquierda {
                        ForEach(p.derecha, id: \.id) { d in
                            Button("Emparejar con \(d.texto)") { emparejar(e.id, d.id) }
                        }
                    }
                }
                .accessibilityIdentifier(izquierda ? "izq_\(e.id)" : "der_\(e.id)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func elementoVista(_ texto: String, indicePar: Int?, seleccionado: Bool, estado: EstadoFicha?) -> some View {
        let color = indicePar.map { Paleta.pares[$0 % Paleta.pares.count] }
        return HStack(spacing: Espacio.s) {
            if let indicePar, let color {
                Text("\(indicePar + 1)")
                    .font(.redondeada(.caption, peso: .bold))
                    .foregroundStyle(Paleta.superficie)
                    .frame(width: 24, height: 24)
                    .background(color, in: Circle())
                    .accessibilityHidden(true)
            }
            Text(texto)
                .font(.body)
                .foregroundStyle(seleccionado ? Paleta.textoSobreAcento : Paleta.textoPrincipal)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let estado, estado == .correcta || estado == .incorrecta {
                Image(systemName: estado == .correcta ? "checkmark" : "xmark")
                    .foregroundStyle(estado == .correcta ? Paleta.exito : Paleta.fallo)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Espacio.m)
        .padding(.vertical, Espacio.s)
        .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo, alignment: .leading)
        .background(seleccionado ? ctx.acento : Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous)
                .strokeBorder(borde(estado: estado, color: color, seleccionado: seleccionado), lineWidth: indicePar == nil ? 1 : 2)
        )
        .contentShape(Rectangle())
    }

    private func borde(estado: EstadoFicha?, color: Color?, seleccionado: Bool) -> Color {
        if estado == .correcta { return Paleta.exito }
        if estado == .incorrecta { return Paleta.fallo }
        if seleccionado { return ctx.acento }
        return color ?? Paleta.borde
    }

    private func estado(_ id: String, izquierda: Bool) -> EstadoFicha? {
        guard ctx.corregido, izquierda else { return nil }
        return ctx.esError(id) ? .incorrecta : .correcta
    }

    private func valorAccesible(_ id: String, izquierda: Bool, indicePar: Int?) -> String {
        var partes: [String] = []
        if let indicePar {
            let par = pares[indicePar]
            let otro = izquierda ? p.derecha.first { $0.id == par.derecha }?.texto : p.izquierda.first { $0.id == par.izquierda }?.texto
            partes.append("emparejado con \(otro ?? "")")
        } else {
            partes.append("sin pareja")
        }
        if let e = estado(id, izquierda: izquierda)?.descripcionAccesible { partes.append(e) }
        return partes.joined(separator: ", ")
    }

    private func tocar(_ id: String, izquierda: Bool) {
        // Tocar un elemento ya emparejado deshace el par.
        if let i = pares.firstIndex(where: { izquierda ? $0.izquierda == id : $0.derecha == id }) {
            var r = pares
            r.remove(at: i)
            respuesta = r.isEmpty ? nil : .emparejar(r)
            return
        }
        if izquierda {
            izquierdaSeleccionada = izquierdaSeleccionada == id ? nil : id
        } else {
            derechaSeleccionada = derechaSeleccionada == id ? nil : id
        }
        if let i = izquierdaSeleccionada, let d = derechaSeleccionada { emparejar(i, d) }
    }

    private func emparejar(_ izquierda: String, _ derecha: String) {
        guard !ctx.corregido else { return }
        var r = pares.filter { $0.izquierda != izquierda && $0.derecha != derecha }
        r.append(.init(izquierda: izquierda, derecha: derecha))
        respuesta = .emparejar(r)
        izquierdaSeleccionada = nil
        derechaSeleccionada = nil
    }
}

// MARK: - Construir

/// Plantilla con huecos y banco de piezas. Tocar una pieza la coloca en el hueco
/// seleccionado (o en el primero libre); tocar un hueco lleno lo vacía.
struct MecanicaConstruir: View {
    let p: Payload.Construir
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var huecoSeleccionado: String?

    private var colocadas: [String: String] {
        if case .construir(let r) = respuesta { return r }
        return [:]
    }

    /// Partes de la plantilla: palabras sueltas (para que el texto fluya) y huecos.
    private enum Parte: Hashable { case palabra(String), hueco(String) }

    private var partes: [Parte] {
        var resultado: [Parte] = []
        var resto = Substring(p.plantilla)
        while let abre = resto.firstIndex(of: "{"), let cierra = resto[abre...].firstIndex(of: "}") {
            resultado += resto[..<abre].split(separator: " ").map { .palabra(String($0)) }
            resultado.append(.hueco(String(resto[resto.index(after: abre)..<cierra])))
            resto = resto[resto.index(after: cierra)...]
        }
        resultado += resto.split(separator: " ").map { .palabra(String($0)) }
        return resultado
    }

    var body: some View {
        let textos = Dictionary(p.piezas.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
        let numeros = Dictionary(p.huecos.enumerated().map { ($1.id, $0 + 1) }, uniquingKeysWith: { a, _ in a })
        VStack(alignment: .leading, spacing: Espacio.l) {
            TarjetaSuperficie {
                DisposicionFlujo(espacioH: Espacio.xs, espacioV: Espacio.s) {
                    ForEach(Array(partes.enumerated()), id: \.offset) { _, parte in
                        switch parte {
                        case .palabra(let palabra):
                            Text(palabra).font(.body).foregroundStyle(Paleta.textoPrincipal).frame(minHeight: Medidas.tactilMinimo)
                        case .hueco(let id):
                            huecoVista(id, numero: numeros[id] ?? 0, texto: colocadas[id].flatMap { textos[$0] })
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("plantilla")

            if !ctx.corregido {
                Instruccion(texto: "Toca una pieza para colocarla en el hueco marcado, o arrástrala.")
                let usadas = Set(colocadas.values)
                DisposicionFlujo {
                    ForEach(p.piezas.filter { !usadas.contains($0.id) }, id: \.id) { pieza in
                        Button {
                            colocar(pieza.id, en: huecoSeleccionado ?? p.huecos.first { colocadas[$0.id] == nil }?.id)
                        } label: {
                            Ficha(texto: pieza.texto, acento: ctx.acento)
                        }
                        .buttonStyle(.plain)
                        .draggable(pieza.id)
                        .accessibilityHint("Toca para colocarla en el hueco seleccionado")
                        .accessibilityActions {
                            ForEach(p.huecos, id: \.id) { h in
                                Button("Colocar en el hueco \(numeros[h.id] ?? 0)") { colocar(pieza.id, en: h.id) }
                            }
                        }
                        .accessibilityIdentifier("pieza_\(pieza.id)")
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: colocadas)
    }

    private func huecoVista(_ id: String, numero: Int, texto: String?) -> some View {
        let seleccionado = huecoSeleccionado == id
        let estado: EstadoFicha = ctx.corregido
            ? (ctx.esError(id) ? .incorrecta : .correcta)
            : (seleccionado ? .seleccionada : .normal)
        return Button {
            if colocadas[id] != nil {
                var r = colocadas
                r[id] = nil
                respuesta = r.isEmpty ? nil : .construir(r)
                huecoSeleccionado = id
            } else {
                huecoSeleccionado = seleccionado ? nil : id
            }
        } label: {
            Ficha(texto: texto ?? "    \(numero)    ", estado: texto == nil && estado == .normal ? .normal : estado, acento: ctx.acento)
                .overlay {
                    if texto == nil, !seleccionado {
                        RoundedRectangle(cornerRadius: Radio.ficha).strokeBorder(ctx.acento, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }
                }
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { ids, _ in
            guard let pieza = ids.first else { return false }
            colocar(pieza, en: id)
            return true
        }
        .accessibilityLabel("Hueco \(numero)")
        .accessibilityValue([texto ?? "vacío", estado.descripcionAccesible].compactMap { $0 }.joined(separator: ", "))
        .accessibilityIdentifier("hueco_\(id)")
    }

    private func colocar(_ pieza: String, en hueco: String?) {
        guard !ctx.corregido, let hueco, p.piezas.contains(where: { $0.id == pieza }) else { return }
        var r = colocadas.filter { $0.value != pieza }
        r[hueco] = pieza
        respuesta = .construir(r)
        huecoSeleccionado = p.huecos.first { r[$0.id] == nil }?.id
    }
}
