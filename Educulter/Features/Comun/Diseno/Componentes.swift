import SwiftUI

// MARK: - Botón principal

struct EstiloBotonPrincipal: ButtonStyle {
    var acento: Color = Paleta.matematicas
    @Environment(\.isEnabled) private var activo
    @Environment(\.accessibilityReduceMotion) private var reducir

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(activo ? Paleta.textoSobreAcento : Paleta.textoSecundario)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Espacio.l)
            .padding(.vertical, Espacio.xs)
            .background(activo ? acento : Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .overlay {
                if !activo { RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(Paleta.borde, lineWidth: 1.5) }
            }
            .scaleEffect(configuration.isPressed && !reducir ? 0.97 : 1)
            .animation(Movimiento.animacion(reducir: reducir), value: configuration.isPressed)
    }
}

struct BotonPrincipal: View {
    let titulo: String
    var icono: String?
    var acento: Color = Paleta.matematicas
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: Espacio.s) {
                if let icono { Image(systemName: icono).accessibilityHidden(true) }
                Text(titulo)
            }
        }
        .buttonStyle(EstiloBotonPrincipal(acento: acento))
    }
}

/// Botón secundario: contorno, sin relleno.
struct EstiloBotonSecundario: ButtonStyle {
    var acento: Color = Paleta.matematicas
    @Environment(\.isEnabled) private var activo

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(activo ? acento : Paleta.textoSecundario)
            .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo)
            .padding(.horizontal, Espacio.l)
            .background(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(activo ? acento : Paleta.borde, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Tarjeta de superficie

/// Baldosa neutra (v2): superficie sin borde ni sombra. Dentro del panel tintado usa el fondo.
struct TarjetaSuperficie<Contenido: View>: View {
    var relleno: CGFloat = Espacio.l
    @ViewBuilder let contenido: () -> Contenido
    @Environment(\.enPanelTintado) private var enPanel

    var body: some View {
        contenido()
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(enPanel ? Paleta.fondo : Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
    }
}

// MARK: - Ficha

/// Estado visual de una ficha.
enum EstadoFicha: Equatable {
    case normal
    case seleccionada
    /// Dentro del tramo que se está marcando (segmentar): tinte suave del acento.
    case enTramo
    case correcta
    case incorrecta
    /// Elemento que el usuario no marcó pero formaba parte de la solución.
    case faltante
    case desactivada
}

/// Ficha táctil (palabra, opción, pieza…). Mínimo 52 pt de alto (D-049).
struct Ficha: View {
    let texto: String
    var estado: EstadoFicha = .normal
    var acento: Color = Paleta.matematicas
    var anchoCompleto = false
    var alineacion: Alignment = .center
    @Environment(\.enPanelTintado) private var enPanel

    var body: some View {
        HStack(spacing: Espacio.s) {
            if let icono { Image(systemName: icono).font(.subheadline.weight(.semibold)).foregroundStyle(colorBorde).accessibilityHidden(true) }
            Text(texto)
                .font(.body)
                .multilineTextAlignment(alineacion == .leading ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .foregroundStyle(colorTexto)
        .padding(.horizontal, Espacio.l)
        .padding(.vertical, Espacio.m)
        .frame(minWidth: Medidas.fichaMinima, maxWidth: anchoCompleto ? .infinity : nil, minHeight: Medidas.fichaMinima, alignment: alineacion)
        .background(colorFondo, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous)
                .strokeBorder(colorBorde, style: StrokeStyle(lineWidth: estado == .normal ? 1 : 2, dash: estado == .faltante ? [6, 4] : []))
        )
        .contentShape(RoundedRectangle(cornerRadius: Radio.ficha))
    }

    private var icono: String? {
        switch estado {
        case .correcta: "checkmark"
        case .incorrecta: "xmark"
        case .faltante: "plus"
        default: nil
        }
    }

    private var colorTexto: Color {
        switch estado {
        // En correcta/incorrecta el texto mantiene el color principal (contraste AA sobre el
        // fondo tintado); el estado lo indican el icono y el borde.
        case .seleccionada: Paleta.textoSobreAcento
        case .desactivada: Paleta.textoSecundario
        case .normal, .enTramo, .correcta, .incorrecta, .faltante: Paleta.textoPrincipal
        }
    }

    private var colorFondo: Color {
        switch estado {
        case .seleccionada: acento
        case .enTramo: acento.opacity(0.18)
        default: enPanel ? Paleta.fondo : Paleta.superficie
        }
    }

    private var colorBorde: Color {
        switch estado {
        case .seleccionada, .enTramo: acento
        case .correcta, .faltante: Paleta.exito
        case .incorrecta: Paleta.fallo
        default: Paleta.borde
        }
    }
}

extension EstadoFicha {
    /// Texto para VoiceOver que acompaña a la etiqueta de la ficha.
    var descripcionAccesible: String? {
        switch self {
        case .seleccionada: "seleccionada"
        case .enTramo: "en el tramo"
        case .correcta: "correcta"
        case .incorrecta: "incorrecta"
        case .faltante: "faltaba marcarla"
        default: nil
        }
    }
}

// MARK: - Barra de progreso de ronda

struct BarraProgresoRonda: View {
    let actual: Int
    let total: Int
    var acento: Color = Paleta.matematicas

    var body: some View {
        ZStack {
            Color.clear.frame(height: Medidas.tactilMinimo)
            HStack(spacing: Espacio.xs) {
                ForEach(0..<max(total, 1), id: \.self) { i in
                    Capsule()
                        .fill(i < actual ? acento : Paleta.borde)
                        .frame(height: 8)
                }
            }
        }
        .contentShape(Rectangle())
        .animacionApp(actual)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso de la ronda")
        .accessibilityValue("\(min(actual + 1, total)) de \(total)")
        .accessibilityIdentifier("barraProgreso")
    }
}

// MARK: - Indicador de combo

/// Cápsula del combo. En los hitos (×3, ×5, ×10…) da un salto con destello; con "Reducir
/// movimiento", solo un fundido del destello.
struct IndicadorCombo: View {
    let combo: Int
    /// Aumenta en cada hito de combo (dispara la animación).
    var hitos: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reducir
    @State private var escala: CGFloat = 1
    @State private var destello = 0.0

    var body: some View {
        let activo = combo >= 2
        HStack(spacing: Espacio.xs) {
            Image(systemName: "bolt.fill")
                .symbolEffect(.bounce, options: .speed(1.5), value: reducir ? 0 : hitos)
                .accessibilityHidden(true)
            Text("×\(combo)")
                .font(.redondeada(.subheadline, peso: .semibold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(activo ? Paleta.textoSobreRecompensa : Paleta.textoSecundario)
        .padding(.horizontal, Espacio.m)
        .frame(minHeight: Medidas.tactilMinimo)
        .background(activo ? Paleta.recompensa : Paleta.superficie, in: Capsule())
        .overlay(Capsule().strokeBorder(activo ? Color.clear : Paleta.borde))
        .opacity(1 - destello * 0.4)
        .scaleEffect(escala)
        .animacionApp(combo)
        .onChange(of: hitos) { _, nuevo in
            guard nuevo > 0 else { return }
            // Confirma el hito en ≤ 0,35 s; con "Reducir movimiento", un fundido breve.
            if reducir {
                withAnimation(.easeOut(duration: 0.15)) { destello = 1 }
                withAnimation(.easeIn(duration: 0.2).delay(0.15)) { destello = 0 }
            } else {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) { escala = 1.3 }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8).delay(0.15)) { escala = 1 }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Combo")
        .accessibilityValue(activo ? "\(combo) aciertos seguidos" : "sin combo")
    }
}

// MARK: - Anillo de dominio

struct AnilloDominio: View {
    /// 0…1
    let fraccion: Double
    var acento: Color = Paleta.matematicas
    var grosor: CGFloat = 6

    var body: some View {
        ZStack {
            Circle().stroke(Paleta.borde, lineWidth: grosor)
            Circle()
                .trim(from: 0, to: min(max(fraccion, 0), 1))
                .stroke(acento, style: StrokeStyle(lineWidth: grosor, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animacionApp(fraccion)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dominio")
        .accessibilityValue("\(Int((fraccion * 100).rounded())) %")
    }
}

// MARK: - Chip de racha

struct ChipRacha: View {
    let dias: Int
    let protectores: Int
    let record: Int
    /// Solo para capturas (Debug): abre el globo al aparecer.
    var abrirAyudaAlAparecer = false

    @Environment(\.dynamicTypeSize) private var tamano
    @State private var mostrarAyuda = false

    var body: some View {
        Button { mostrarAyuda = true } label: { chip }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Racha")
            .accessibilityValue("\(dias == 1 ? "1 día" : "\(dias) días"). \(protectores) protectores. Récord: \(record)")
            .accessibilityHint("Explica qué significa cada icono")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("chipRacha")
            .popover(isPresented: $mostrarAyuda, arrowEdge: .top) {
                GloboRacha(dias: dias, protectores: protectores, record: record)
                    .presentationCompactAdaptation(.popover)
            }
            .task {
                if abrirAyudaAlAparecer {
                    try? await Task.sleep(for: .seconds(1))
                    mostrarAyuda = true
                }
            }
    }

    private var chip: some View {
        let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.xs)) : AnyLayout(HStackLayout(spacing: Espacio.m))
        return disposicion {
            Label {
                Text(dias == 1 ? "1 día" : "\(dias) días").font(.redondeada(.headline, peso: .semibold))
                    .fixedSize()
            } icon: {
                Image(systemName: "flame.fill").foregroundStyle(dias > 0 ? Paleta.recompensaTexto : Paleta.textoSecundario)
            }
            if !tamano.isAccessibilitySize { Divider().frame(height: 20) }
            Label {
                Text("\(protectores)").font(.redondeada(.subheadline))
            } icon: {
                Image(systemName: "shield.fill").foregroundStyle(Paleta.matematicas)
            }
            Label {
                Text("\(record)").font(.redondeada(.subheadline))
            } icon: {
                Image(systemName: "trophy.fill").foregroundStyle(Paleta.recompensaTexto)
            }
        }
        .foregroundStyle(Paleta.textoPrincipal)
        .padding(.horizontal, Espacio.l)
        .padding(.vertical, tamano.isAccessibilitySize ? Espacio.m : 0)
        .frame(minHeight: Medidas.tactilMinimo)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Paleta.borde))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Globo que explica la racha, los protectores y el récord.
struct GloboRacha: View {
    let dias: Int
    let protectores: Int
    let record: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.m) {
                fila("flame.fill", Paleta.recompensaTexto, "Racha",
                     "Días seguidos completando al menos una ronda. Llevas \(dias == 1 ? "1 día" : "\(dias) días").")
                fila("shield.fill", Paleta.matematicas, "Protectores",
                     "Salvan tu racha si un día no juegas. Se reponen a 2 cada mes y ganas uno más por cada semana completa (máximo 3). Tienes \(protectores).")
                fila("trophy.fill", Paleta.recompensaTexto, "Récord",
                     "Tu racha más larga hasta ahora: \(record == 1 ? "1 día" : "\(record) días").")
            }
            .padding(Espacio.l)
        }
        .frame(idealWidth: 320, maxWidth: 360)
        .background(Paleta.superficie)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("globoRacha")
    }

    private func fila(_ icono: String, _ color: Color, _ titulo: String, _ texto: String) -> some View {
        HStack(alignment: .top, spacing: Espacio.m) {
            Image(systemName: icono).font(.title3).foregroundStyle(color).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Espacio.xs) {
                Text(titulo).font(.headline).foregroundStyle(Paleta.textoPrincipal)
                Text(texto).font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Hoja de feedback

struct HojaFeedback: View {
    let correcto: Bool
    let explicacion: String
    var feedbackEspecifico: [String] = []
    var solucion: String?
    var xp: Int = 0
    /// Color del área: "Continuar" y "Ver regla" lo usan también tras un fallo (fallar no castiga).
    var acento: Color = Paleta.matematicas
    /// Compañero del área del ítem: celebra al acertar y anima tras un fallo (D-054).
    var companero: Companero?
    /// Tinta del área para el texto de "Ver regla" (AA sobre superficie).
    var tinta: Color = Paleta.textoPrincipal
    var subioPeldano = false
    var puedeVerRegla = false
    var verRegla: () -> Void = {}
    let continuar: () -> Void

    @Environment(\.dynamicTypeSize) private var tamano
    private var color: Color { correcto ? Paleta.exito : Paleta.fallo }

    var body: some View {
        // Si no cabe (texto muy grande), el contenido pasa a ser desplazable en vez de recortarse.
        Group {
            if tamano.isAccessibilitySize {
                // Con texto muy grande el panel se desplaza en lugar de recortarse.
                ScrollView { contenido }.frame(maxHeight: 420)
            } else {
                contenido
            }
        }
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(color, lineWidth: 2))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hojaFeedback")
    }

    private var contenido: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            HStack(spacing: Espacio.s) {
                if let companero {
                    VistaPersonaje(companero: companero, estado: ReglasPersonaje.estado(para: .feedback(correcto: correcto)), tamano: 44)
                        .accessibilityIdentifier("personajeFeedback")
                }
                Image(systemName: correcto ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(correcto ? "¡Correcto!" : "No es correcto")
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Espacio.s)
                if xp > 0 {
                    Text("+\(xp) XP")
                        .font(.redondeada(.subheadline, peso: .semibold))
                        .foregroundStyle(Paleta.textoSobreRecompensa)
                        .padding(.horizontal, Espacio.s)
                        .padding(.vertical, Espacio.xs)
                        .background(Paleta.recompensa, in: Capsule())
                        .anchorPreference(key: AnclasVueloXP.self, value: .bounds) { ["origen": $0] }
                }
            }
            .foregroundStyle(color)

            if subioPeldano {
                Label("¡Subes de peldaño!", systemImage: "arrow.up.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Paleta.recompensaTexto)
            }
            if let solucion, !correcto {
                Text("**Solución:** \(solucion)")
                    .font(.subheadline)
                    .foregroundStyle(Paleta.textoPrincipal)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("textoSolucion")
            }
            ForEach(feedbackEspecifico, id: \.self) { texto in
                Label { Text(texto) } icon: { Image(systemName: "lightbulb.fill").foregroundStyle(Paleta.recompensaTexto) }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("feedbackEspecifico")
            }
            Text(explicacion)
                .font(.subheadline)
                .foregroundStyle(Paleta.textoSecundario)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("explicacion")

            let disposicion = tamano >= .xxxLarge ? AnyLayout(VStackLayout(spacing: Espacio.s)) : AnyLayout(HStackLayout(spacing: Espacio.m))
            disposicion { botones }
        }
        .padding(Espacio.l)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var botones: some View {
        if puedeVerRegla {
            Button("Ver regla", action: verRegla)
                .buttonStyle(EstiloBotonSecundario(acento: tinta))
                .accessibilityIdentifier("botonVerRegla")
        }
        Button("Continuar", action: continuar)
            .buttonStyle(EstiloBotonPrincipal(acento: correcto ? Paleta.exito : acento))
            .accessibilityIdentifier("botonContinuar")
    }
}

// MARK: - Vuelo de la XP

/// Anclas del vuelo de "+N XP": "origen" (cápsula del panel) y "destino" (contador de la cabecera).
struct AnclasVueloXP: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}
