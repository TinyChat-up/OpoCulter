import SwiftUI

// MARK: - Colocar la tilde

/// La palabra en letras grandes, como fichas. Tocar una vocal coloca la tilde (cae desde
/// arriba); tocarla otra vez la quita. «Sin tilde» responde que la palabra no la lleva.
/// Tras corregir: la palabra correcta con la sílaba tónica resaltada.
struct MecanicaColocarTilde: View {
    let p: Payload.ColocarTilde
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @Environment(\.accessibilityReduceMotion) private var reducir

    private var elegido: Int?? {
        if case .colocarTilde(let i) = respuesta { return .some(i) }
        return nil
    }

    var body: some View {
        VStack(spacing: Espacio.l) {
            // Una sola fila: las letras se reparten el ancho (la palabra nunca se parte).
            HStack(spacing: Espacio.xs) {
                ForEach(Array(p.letras.enumerated()), id: \.offset) { i, letra in letraVista(i, letra) }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: ctx.corregido ? .ignore : .contain)
            .accessibilityLabel(ctx.corregido ? "Palabra correcta: \(p.correcta)" : "Palabra \(p.palabra)")
            .accessibilityIdentifier("palabraTilde")

            if ctx.corregido {
                correccion
            } else {
                botonSinTilde
            }
        }
        .sensoryFeedback(.selection, trigger: respuesta)
    }

    // MARK: Letras

    private func letraVista(_ i: Int, _ letra: Character) -> some View {
        let esVocal = Payload.ColocarTilde.vocales.contains(letra)
        let conTilde = mostrarTilde(en: i)
        let tonica = ctx.corregido && silabaTonica.contains(i)
        let marcadaMal = ctx.corregido && elegido == .some(i) && p.indiceTilde != i
        return Group {
            if esVocal && !ctx.corregido {
                Button {
                    // Tocar la vocal que ya tiene la tilde la quita (sin respuesta, no «Sin tilde»).
                    respuesta = elegido == .some(i) ? nil : .colocarTilde(i)
                } label: {
                    ficha(letra, conTilde: conTilde, vocal: true, tonica: false, mal: false)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Vocal \(String(letra))")
                .accessibilityValue(conTilde ? "con tilde" : "sin tilde")
                .accessibilityHint(conTilde ? "Toca para quitar la tilde" : "Toca para poner la tilde aquí")
                .accessibilityAddTraits(conTilde ? .isSelected : [])
                .accessibilityIdentifier("letra_\(i)")
            } else {
                ficha(letra, conTilde: conTilde, vocal: esVocal, tonica: tonica, mal: marcadaMal)
                    .accessibilityHidden(true)
            }
        }
    }

    /// La tilde que se muestra: la del usuario mientras responde; la correcta tras corregir.
    private func mostrarTilde(en i: Int) -> Bool {
        ctx.corregido ? p.indiceTilde == i : elegido == .some(i)
    }

    private func ficha(_ letra: Character, conTilde: Bool, vocal: Bool, tonica: Bool, mal: Bool) -> some View {
        let base = Text(String(letra))
            .font(.redondeada(.largeTitle, peso: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(vocal || ctx.corregido ? Paleta.textoPrincipal : Paleta.textoSecundario)
        return base
            .frame(maxWidth: 56, minHeight: Medidas.fichaMinima * 1.4)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                if conTilde {
                    MarcaTilde()
                        .fill(mal ? Paleta.fallo : (ctx.corregido ? Paleta.exito : ctx.tinta))
                        .frame(width: 14, height: 18)
                        .padding(.top, 3)
                        .transition(reducir ? .opacity : .asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .background(fondoFicha(vocal: vocal), in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous)
                    .strokeBorder(mal ? Paleta.fallo : (vocal ? Paleta.borde : .clear), lineWidth: mal ? 2 : 1)
            )
            // Sílaba tónica: barra en la tinta del área bajo sus letras (no es un error).
            .overlay(alignment: .bottom) {
                if tonica {
                    Capsule().fill(ctx.tinta).frame(height: 4).padding(.horizontal, 2).offset(y: 8).accessibilityHidden(true)
                }
            }
            .animation(reducir ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.6), value: conTilde)
    }

    /// Vocales (tocables) en el fondo claro; consonantes, sin fondo, sobre el tinte del panel.
    private func fondoFicha(vocal: Bool) -> Color {
        vocal ? Paleta.fondo : .clear
    }

    private var silabaTonica: Range<Int> {
        let escrita = p.correcta
        let silabas = Silabeo.silabas(escrita)
        let k = Silabeo.silabaTonica(escrita, indiceTilde: p.indiceTilde)
        return silabas.indices.contains(k) ? silabas[k] : 0..<0
    }

    // MARK: Sin tilde y corrección

    private var botonSinTilde: some View {
        let elegido = self.elegido == .some(nil)
        return Button {
            respuesta = elegido ? nil : .colocarTilde(nil)
        } label: {
            Ficha(texto: "Sin tilde", estado: elegido ? .seleccionada : .normal, acento: ctx.acento)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(elegido ? .isSelected : [])
        .accessibilityHint("Responde que la palabra no lleva tilde")
        .accessibilityIdentifier("botonSinTilde")
    }

    private var correccion: some View {
        let silabas = Silabeo.silabas(p.correcta).map { r in String(Array(p.correcta)[r]) }
        let k = Silabeo.silabaTonica(p.correcta, indiceTilde: p.indiceTilde)
        let separada = silabas.enumerated().map { $0.offset == k ? $0.element.uppercased() : $0.element }.joined(separator: "-")
        let tuya: String = {
            switch elegido {
            case .some(.none): "sin tilde"
            case .some(.some(let i)): "«\(p.escrita(conTildeEn: i))»"
            case .none: "—"
            }
        }()
        return VStack(spacing: Espacio.xs) {
            Text("Sílaba tónica: \(separada)")
                .font(.headline)
                .foregroundStyle(Paleta.textoPrincipal)
            if ctx.resultado?.correcto == false {
                Text("Tu respuesta: \(tuya)")
                    .font(.subheadline)
                    .foregroundStyle(Paleta.textoSecundario)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("correccionTilde")
    }
}

/// Trazo de la tilde (acento agudo): un paralelogramo inclinado.
struct MarcaTilde: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX - r.width * 0.25, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.15))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.25, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.15))
        p.closeSubpath()
        return p
    }
}

// MARK: - Fracciones con barras

/// Barra manipulable: se colorean celdas tocándolas. En `dividirYColorear`, antes se elige
/// en cuántas partes dividir (2–12) con un control ajustable; la barra se redibuja en vivo.
struct MecanicaFraccionBarras: View {
    let p: Payload.FraccionBarras
    let ctx: ContextoMecanica
    @Binding var respuesta: Respuesta?
    @Environment(\.accessibilityReduceMotion) private var reducir
    /// Partes elegidas en `dividirYColorear` antes de colorear nada.
    @State private var partesElegidas: Int?

    private var partes: Int {
        if case .fraccionBarras(let n, _) = respuesta { return n }
        return p.partes ?? partesElegidas ?? Payload.FraccionBarras.rangoPartes.lowerBound
    }

    private var coloreadas: Set<Int> {
        if case .fraccionBarras(_, let c) = respuesta { return c }
        return []
    }

    var body: some View {
        VStack(spacing: Espacio.l) {
            if p.modo == .dividirYColorear && !ctx.corregido {
                controlPartes
            }
            VStack(spacing: Espacio.s) {
                Barra(partes: partes, coloreadas: coloreadas, color: colorRelleno, borde: colorBorde,
                      interactiva: !ctx.corregido, reducir: reducir) { i in alternar(i) }
                Text("\(coloreadas.count)/\(partes)")
                    .font(.redondeada(.title2, peso: .semibold))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Coloreado")
                    .accessibilityValue("\(coloreadas.count) de \(partes)")
                    .accessibilityIdentifier("lecturaFraccion")
            }
            if ctx.corregido, ctx.resultado?.correcto == false {
                solucion
            }
        }
        .sensoryFeedback(.selection, trigger: coloreadas)
        .sensoryFeedback(.selection, trigger: partes)
    }

    private var colorRelleno: Color {
        guard let r = ctx.resultado else { return ctx.acento }
        return r.correcto ? Paleta.exito : Paleta.fallo
    }

    private var colorBorde: Color {
        guard let r = ctx.resultado else { return Paleta.borde }
        return r.correcto ? Paleta.exito : Paleta.fallo
    }

    private func alternar(_ i: Int) {
        var c = coloreadas
        if c.contains(i) { c.remove(i) } else { c.insert(i) }
        respuesta = c.isEmpty && p.modo == .colorear ? nil : .fraccionBarras(partes: partes, coloreadas: c)
    }

    private func cambiarPartes(_ delta: Int) {
        let nuevo = min(max(partes + delta, Payload.FraccionBarras.rangoPartes.lowerBound), Payload.FraccionBarras.rangoPartes.upperBound)
        guard nuevo != partes else { return }
        partesElegidas = nuevo
        // Al cambiar la división se vacía la barra.
        respuesta = .fraccionBarras(partes: nuevo, coloreadas: [])
    }

    private var controlPartes: some View {
        HStack(spacing: Espacio.l) {
            botonPaso("minus", etiqueta: "Menos partes", id: "botonMenosPartes", activo: partes > Payload.FraccionBarras.rangoPartes.lowerBound) { cambiarPartes(-1) }
            VStack(spacing: 0) {
                Text("\(partes)")
                    .font(.redondeada(.title, peso: .semibold))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .contentTransition(.numericText())
                Text("partes").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
            }
            .frame(minWidth: 72)
            botonPaso("plus", etiqueta: "Más partes", id: "botonMasPartes", activo: partes < Payload.FraccionBarras.rangoPartes.upperBound) { cambiarPartes(1) }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Partes de la barra")
        .accessibilityValue("\(partes)")
        .accessibilityHint("Desliza arriba o abajo para cambiar en cuántas partes se divide")
        .accessibilityAdjustableAction { direccion in
            switch direccion {
            case .increment: cambiarPartes(1)
            case .decrement: cambiarPartes(-1)
            @unknown default: break
            }
        }
        .accessibilityIdentifier("controlPartes")
    }

    private func botonPaso(_ icono: String, etiqueta: String, id: String, activo: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.title3.weight(.semibold))
                .foregroundStyle(activo ? ctx.tinta : Paleta.textoSecundario)
                .frame(width: Medidas.fichaMinima, height: Medidas.fichaMinima)
                .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(activo)
        .accessibilityLabel(etiqueta)
        .accessibilityIdentifier(id)
    }

    private var solucion: some View {
        let (partesSol, coloreadasSol) = p.solucion
        return VStack(spacing: Espacio.s) {
            Text("Solución").font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            Barra(partes: partesSol, coloreadas: Set(0..<coloreadasSol), color: Paleta.exito, borde: Paleta.exito,
                  interactiva: false, reducir: reducir) { _ in }
            Text(DescripcionSolucion.texto(.fraccionBarras(p)))
                .font(.redondeada(.title3, peso: .semibold))
                .foregroundStyle(Paleta.textoPrincipal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("solucionBarra")
    }
}

/// Barra dividida en celdas iguales (radio 4); cada celda es un botón accesible.
struct Barra: View {
    let partes: Int
    let coloreadas: Set<Int>
    let color: Color
    let borde: Color
    let interactiva: Bool
    let reducir: Bool
    let alTocar: (Int) -> Void

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(partes, 1), id: \.self) { i in
                let llena = coloreadas.contains(i)
                Button {
                    alTocar(i)
                } label: {
                    RoundedRectangle(cornerRadius: Radio.celda, style: .continuous)
                        .fill(llena ? color : Paleta.superficie)
                        .overlay(RoundedRectangle(cornerRadius: Radio.celda, style: .continuous).strokeBorder(llena ? color : borde, lineWidth: 1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .allowsHitTesting(interactiva)
                .accessibilityLabel("celda \(i + 1) de \(partes)")
                .accessibilityValue(llena ? "coloreada" : "sin colorear")
                .accessibilityAddTraits(llena ? .isSelected : [])
                .accessibilityIdentifier(interactiva ? "celda_\(i)" : "celdaSolucion_\(i)")
            }
        }
        .frame(minHeight: Medidas.tactilMinimo)
        .animation(reducir ? .easeInOut(duration: 0.2) : .spring(response: 0.25, dampingFraction: 0.8), value: partes)
        .animation(reducir ? nil : .easeOut(duration: 0.15), value: coloreadas)
    }
}
