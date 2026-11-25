import SwiftUI

/// Datos comunes que recibe cada mecánica.
struct ContextoMecanica {
    let item: Item
    /// Primario del área: rellenos (con texto blanco) y objetos manipulables.
    let acento: Color
    /// Resultado tras comprobar (nil mientras se responde).
    let resultado: Resultado?

    /// Tinte del panel protagonista y tinta (texto con color de área), v2.
    var tinte: Color { Paleta.tinte(competencia: item.competencia) }
    var tinta: Color { Paleta.tinta(competencia: item.competencia) }

    var corregido: Bool { resultado != nil }

    func esError(_ id: String) -> Bool { resultado?.errores.contains(id) ?? false }
}

/// Despacha a la vista de cada mecánica. Todas escriben en `respuesta` el borrador de la
/// respuesta (aunque esté incompleta); `Respuesta.esCompleta` decide si se puede comprobar.
struct VistaMecanica: View {
    let contexto: ContextoMecanica
    @Binding var respuesta: Respuesta?

    var body: some View {
        // Tras corregir, la respuesta queda fija: se ignoran las escrituras y los toques, pero no
        // se usa `.disabled` (atenuaría el contenido y bajaría el contraste de la corrección).
        let corregido = contexto.corregido
        let actual = respuesta
        let fija = Binding<Respuesta?>(get: { corregido ? actual : respuesta }, set: { if !corregido { respuesta = $0 } })
        return contenido(fija)
            .allowsHitTesting(!corregido)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("mecanica_\(contexto.item.mecanica.rawValue)")
    }

    @ViewBuilder
    private func contenido(_ respuesta: Binding<Respuesta?>) -> some View {
        Group {
            switch contexto.item.payload {
            case .eleccion(let p): MecanicaEleccion(p: p, ctx: contexto, respuesta: respuesta)
            case .verdaderoFalso(let p): MecanicaVerdaderoFalso(p: p, ctx: contexto, respuesta: respuesta)
            case .clasificar(let p): MecanicaClasificar(p: p, ctx: contexto, respuesta: respuesta)
            case .ordenar(let p): MecanicaOrdenar(p: p, ctx: contexto, respuesta: respuesta)
            case .emparejar(let p): MecanicaEmparejar(p: p, ctx: contexto, respuesta: respuesta)
            case .marcarTexto(let p): MecanicaMarcarTexto(p: p, ctx: contexto, respuesta: respuesta)
            case .segmentar(let p): MecanicaSegmentar(p: p, ctx: contexto, respuesta: respuesta)
            case .ruedas(let p): MecanicaRuedas(p: p, ctx: contexto, respuesta: respuesta)
            case .construir(let p): MecanicaConstruir(p: p, ctx: contexto, respuesta: respuesta)
            case .numerico(let p): MecanicaNumerico(p: p, ctx: contexto, respuesta: respuesta)
            case .colocarTilde(let p): MecanicaColocarTilde(p: p, ctx: contexto, respuesta: respuesta)
            case .fraccionBarras(let p): MecanicaFraccionBarras(p: p, ctx: contexto, respuesta: respuesta)
            }
        }
    }
}

/// Texto de instrucción breve encima de la mecánica.
struct Instruccion: View {
    let texto: String

    var body: some View {
        Text(texto)
            .font(.footnote)
            .foregroundStyle(Paleta.textoSecundario)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Elección

struct MecanicaEleccion: View {
    let p: Payload.Eleccion
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?

    private var elegida: String? {
        if case .eleccion(let id) = respuesta { return id }
        return nil
    }

    var body: some View {
        VStack(spacing: Espacio.m) {
            ForEach(p.opciones, id: \.id) { opcion in
                let estado = estado(de: opcion.id)
                Button {
                    respuesta = .eleccion(opcion.id)
                } label: {
                    Ficha(texto: opcion.texto, estado: estado, acento: ctx.acento, anchoCompleto: true, alineacion: .leading)
                }
                .buttonStyle(.pulsable)
                .accessibilityValue(estado.descripcionAccesible ?? "")
                .accessibilityAddTraits(elegida == opcion.id ? .isSelected : [])
                .accessibilityIdentifier("opcion_\(opcion.id)")
            }
        }
        .retroHaptica(.selection, trigger: elegida)
    }

    private func estado(de id: String) -> EstadoFicha {
        if ctx.corregido {
            if id == p.correcta { return .correcta }
            return id == elegida ? .incorrecta : .normal
        }
        return id == elegida ? .seleccionada : .normal
    }
}

// MARK: - Verdadero o falso

struct MecanicaVerdaderoFalso: View {
    let p: Payload.VerdaderoFalso
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @State private var desplazamiento: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reducir
    @Environment(\.dynamicTypeSize) private var tamano

    private var elegida: Bool? {
        if case .verdaderoFalso(let v) = respuesta { return v }
        return nil
    }

    var body: some View {
        VStack(spacing: Espacio.l) {
            Text(p.afirmacion)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.textoPrincipal)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Espacio.xl)
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(colorBorde, lineWidth: ctx.corregido ? 3 : Trazo.grueso))
                .sombraDura(radio: Radio.tarjeta, activa: !ctx.corregido)
                .offset(x: desplazamiento)
                .rotationEffect(.degrees(reducir ? 0 : Double(desplazamiento) / 25))
                .gesture(
                    DragGesture()
                        .onChanged { desplazamiento = $0.translation.width }
                        .onEnded { valor in
                            if abs(valor.translation.width) > 80 { respuesta = .verdaderoFalso(valor.translation.width > 0) }
                            withAnimation(Movimiento.animacion(reducir: reducir)) { desplazamiento = 0 }
                        }
                )
                .accessibilityAddTraits(.isStaticText)
                .accessibilityIdentifier("afirmacion")

            Instruccion(texto: "Desliza la tarjeta: a la izquierda, falso; a la derecha, verdadero. O usa los botones.")

            let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Espacio.m)) : AnyLayout(HStackLayout(spacing: Espacio.m))
            disposicion {
                boton(valor: false, titulo: "Falso", icono: "hand.thumbsdown")
                boton(valor: true, titulo: "Verdadero", icono: "hand.thumbsup")
            }
        }
        .retroHaptica(.selection, trigger: elegida)
    }

    private var colorBorde: Color {
        guard let elegida else { return Paleta.contorno }
        if ctx.corregido { return elegida == p.esVerdadera ? Paleta.exito : Paleta.fallo }
        return Paleta.contorno
    }

    private func boton(valor: Bool, titulo: String, icono: String) -> some View {
        let estado: EstadoFicha = {
            if ctx.corregido {
                if valor == p.esVerdadera { return .correcta }
                return elegida == valor ? .incorrecta : .normal
            }
            return elegida == valor ? .seleccionada : .normal
        }()
        return Button {
            respuesta = .verdaderoFalso(valor)
        } label: {
            Ficha(texto: titulo, estado: estado, acento: ctx.acento, anchoCompleto: true)
        }
        .buttonStyle(.pulsable)
        .accessibilityAddTraits(elegida == valor ? .isSelected : [])
        .accessibilityValue(estado.descripcionAccesible ?? "")
        .accessibilityIdentifier(valor ? "botonVerdadero" : "botonFalso")
    }
}

// MARK: - Marcar texto

struct MecanicaMarcarTexto: View {
    let p: Payload.MarcarTexto
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?

    private var marcados: Set<String> {
        if case .marcarTexto(let s) = respuesta { return s }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            Instruccion(texto: p.unidad == .silaba ? "Toca las sílabas que correspondan." : "Toca las palabras que correspondan.")
            TarjetaSuperficie {
                DisposicionFlujo(espacioH: p.unidad == .silaba ? 2 : Espacio.s, espacioV: Espacio.s) {
                    ForEach(p.tokens, id: \.id) { token in
                        let estado = estado(de: token.id)
                        Button {
                            var s = marcados
                            if s.contains(token.id) { s.remove(token.id) } else { s.insert(token.id) }
                            respuesta = s.isEmpty ? nil : .marcarTexto(s)
                        } label: {
                            Ficha(texto: token.texto, estado: estado, acento: ctx.acento)
                        }
                        .buttonStyle(.pulsable)
                        .accessibilityAddTraits(marcados.contains(token.id) ? .isSelected : [])
                        .accessibilityValue(estado.descripcionAccesible ?? "")
                        .accessibilityIdentifier("token_\(token.id)")
                    }
                }
            }
        }
        .retroHaptica(.selection, trigger: marcados)
    }

    private func estado(de id: String) -> EstadoFicha {
        let marcado = marcados.contains(id)
        if ctx.corregido {
            let correcto = p.correctos.contains(id)
            switch (marcado, correcto) {
            case (true, true): return .correcta
            case (true, false): return .incorrecta
            case (false, true): return .faltante
            case (false, false): return .normal
            }
        }
        return marcado ? .seleccionada : .normal
    }
}

// MARK: - Numérico

struct MecanicaNumerico: View {
    let p: Payload.Numerico
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?

    private var texto: Binding<String> {
        Binding {
            if case .numerico(let t) = respuesta { return t }
            return ""
        } set: { nuevo in
            respuesta = nuevo.isEmpty ? nil : .numerico(nuevo)
        }
    }

    var body: some View {
        VStack(spacing: Espacio.l) {
            HStack(alignment: .firstTextBaseline, spacing: Espacio.s) {
                Text(texto.wrappedValue.isEmpty ? "?" : texto.wrappedValue.replacingOccurrences(of: "-", with: "−"))
                    .font(.redondeada(.largeTitle, peso: .semibold))
                    .foregroundStyle(colorTexto)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let unidad = p.unidad, !unidad.isEmpty {
                    Text(unidad).font(.redondeada(.title2)).foregroundStyle(Paleta.textoSecundario)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, Espacio.l)
            .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(colorBorde, lineWidth: ctx.corregido ? 3 : Trazo.grueso))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tu resultado")
            .accessibilityValue(texto.wrappedValue.isEmpty ? "vacío" : "\(texto.wrappedValue) \(p.unidad ?? "")")
            .accessibilityIdentifier("pantallaNumerica")

            if p.formato == .fraccion {
                Instruccion(texto: p.exigeIrreducible == true ? "Escribe una fracción irreducible con la barra /." : "Usa la barra / para escribir una fracción.")
            }
            TecladoNumerico(texto: texto, acento: ctx.acento)
        }
    }

    private var colorBorde: Color {
        guard let r = ctx.resultado else { return Paleta.contorno }
        return r.correcto ? Paleta.exito : Paleta.fallo
    }

    private var colorTexto: Color {
        guard let r = ctx.resultado else { return texto.wrappedValue.isEmpty ? Paleta.textoSecundario : Paleta.textoPrincipal }
        return r.correcto ? Paleta.exito : Paleta.fallo
    }
}

// MARK: - Ruedas

struct MecanicaRuedas: View {
    let p: Payload.Ruedas
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @Environment(\.dynamicTypeSize) private var tamano

    private var valores: [String: String] {
        if case .ruedas(let r) = respuesta { return r }
        return [:]
    }

    var body: some View {
        VStack(spacing: Espacio.m) {
            if let r = ctx.resultado {
                Image(systemName: r.correcto ? "lock.open.fill" : "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(r.correcto ? Paleta.exito : Paleta.fallo)
                    .symbolEffect(.bounce, value: r.correcto)
                    .accessibilityLabel(r.correcto ? "Caja fuerte abierta" : "Caja fuerte cerrada")
                    .accessibilityIdentifier("cajaFuerte")
            } else {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Paleta.textoSecundario)
                    .accessibilityHidden(true)
            }
            ForEach(p.ruedas, id: \.id) { rueda in
                fila(rueda)
            }
        }
        .retroHaptica(.selection, trigger: valores)
    }

    private func fila(_ rueda: Payload.Ruedas.Rueda) -> some View {
        let seleccion = Binding<String?> {
            valores[rueda.id]
        } set: { nuevo in
            var v = valores
            v[rueda.id] = nuevo
            respuesta = .ruedas(v)
        }
        let error = ctx.esError(rueda.id)
        let borde: Color = ctx.corregido ? (error ? Paleta.fallo : Paleta.exito) : Paleta.contorno
        let corto = rueda.opciones.count <= 3 && rueda.opciones.allSatisfy { $0.count <= 10 } && !tamano.isAccessibilitySize
        return VStack(alignment: .leading, spacing: Espacio.s) {
            HStack {
                Text(rueda.nombre).font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                Spacer()
                if ctx.corregido {
                    Image(systemName: error ? "xmark" : "checkmark")
                        .foregroundStyle(error ? Paleta.fallo : Paleta.exito)
                        .accessibilityLabel(error ? "incorrecta" : "correcta")
                }
            }
            if corto {
                Picker(rueda.nombre, selection: seleccion) {
                    ForEach(rueda.opciones, id: \.self) { Text($0).tag(Optional($0)) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: Medidas.tactilMinimo)
            } else {
                Picker(rueda.nombre, selection: seleccion) {
                    Text("Elige…").tag(String?.none)
                    ForEach(rueda.opciones, id: \.self) { Text($0).tag(Optional($0)) }
                }
                .pickerStyle(.menu)
                .tint(ctx.tinta)
                .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo, alignment: .leading)
            }
            if ctx.corregido, error {
                Text("Correcta: \(rueda.correcta)").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.exito)
            }
        }
        .padding(Espacio.m)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous).strokeBorder(borde, lineWidth: ctx.corregido ? 3 : Trazo.grueso))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rueda_\(rueda.id)")
    }
}
