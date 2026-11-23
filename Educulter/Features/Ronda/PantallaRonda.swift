import SwiftUI

/// Pantalla de una ronda: progreso, combo, enunciado, mecánica, Comprobar y feedback.
struct PantallaRonda: View {
    @Bindable var modelo: RondaViewModel
    var ayudasDePrueba = false
    let cerrar: () -> Void

    @State private var confirmarSalida = false
    /// XP que muestra el contador de la cabecera (se actualiza cuando aterriza el vuelo).
    @State private var xpMostrado = 0
    @State private var vuelo: VueloXP.Datos?
    @Environment(\.accessibilityReduceMotion) private var reducir
    @Environment(\.dynamicTypeSize) private var tamano

    var body: some View {
        ZStack {
            Paleta.fondo.ignoresSafeArea()
            switch modelo.fase {
            case .resumen:
                if let resumen = modelo.resumen {
                    PantallaResumen(resumen: resumen, nombreCompetencia: modelo.nombreCompetencia,
                                    otraRonda: { modelo.otraRonda() }, terminar: cerrar)
                        .transition(Movimiento.transicion(reducir: reducir))
                }
            case .vacia:
                estadoVacio
            case .teoria:
                teoriaPrevia
            case .respondiendo, .corregido:
                pantallaItem
            }
        }
        .animacionApp(modelo.fase)
        .sheet(item: $modelo.teoriaAbierta) { tarjeta in
            NavigationStack {
                ScrollView {
                    VistaTarjetaTeoria(tarjeta: tarjeta, acento: Paleta.acento(competencia: tarjeta.competencia))
                        .padding(Espacio.l)
                }
                .background(Paleta.fondo)
                .navigationTitle("Regla")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Cerrar") { modelo.teoriaAbierta = nil }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("¿Salir de la ronda?", isPresented: $confirmarSalida, titleVisibility: .visible) {
            Button("Salir", role: .destructive, action: cerrar)
            Button("Seguir jugando", role: .cancel) {}
        } message: {
            Text("Lo que has respondido ya está guardado.")
        }
    }

    // MARK: Ítem

    private var pantallaItem: some View {
        let item = modelo.itemActual
        let acento = item.map { Paleta.acento(competencia: $0.competencia) } ?? Paleta.matematicas
        return VStack(spacing: 0) {
            cabecera(acento: acento)
            GeometryReader { geo in
            ScrollView {
                if let item {
                    VStack(alignment: .leading, spacing: Espacio.l) {
                        Label {
                            Text(modelo.nombreCompetencia(item.competencia).uppercased())
                        } icon: {
                            Image(systemName: SimboloBloque.de(competencia: item.competencia)).accessibilityHidden(true)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(acento)
                        .accessibilityIdentifier("cabeceraCompetencia")
                        Text(item.enunciado)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("enunciado")
                        ForEach(modelo.pistasMostradas, id: \.self) { pista in
                            Label { Text(pista) } icon: { Image(systemName: "lightbulb.fill").foregroundStyle(Paleta.recompensaTexto) }
                                .font(.subheadline)
                                .foregroundStyle(Paleta.textoPrincipal)
                                .padding(Espacio.m)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Paleta.recompensa.opacity(0.15), in: RoundedRectangle(cornerRadius: Radio.ficha))
                                .accessibilityIdentifier("pista")
                        }
                        // La mecánica se reparte en el espacio libre (no se amontona arriba).
                        Spacer(minLength: 0)
                        VistaMecanica(contexto: ContextoMecanica(item: item, acento: acento, resultado: modelo.resultado),
                                      respuesta: $modelo.respuesta)
                            .modifier(PulsoAcierto(disparo: modelo.resultado?.correcto == true ? modelo.respondidos : 0))
                            .id(item.id)
                        Spacer(minLength: 0)
                    }
                    .padding(Espacio.l)
                    .frame(minHeight: geo.size.height, alignment: .top)
                }
            }
            .scrollDismissesKeyboard(.never)
            }
            // El pie va debajo del scroll (no superpuesto): el contenido nunca queda tapado por
            // el panel, solo recortado por el borde del scroll (D-049).
            pie(acento: acento)
                .padding(.horizontal, Espacio.l)
                .padding(.bottom, Espacio.s)
                .padding(.top, Espacio.s)
                .background(Paleta.fondo)
        }
        .sensoryFeedback(trigger: modelo.resultado) { _, nuevo in
            guard let nuevo else { return nil }
            return nuevo.correcto ? .success : .error
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: modelo.hitosCombo)
        .overlayPreferenceValue(AnclasVueloXP.self) { anclas in
            GeometryReader { geo in
                if let vuelo, let destino = anclas["destino"] {
                    let fin = geo[destino]
                    let inicio = anclas["origen"].map { geo[$0] } ?? CGRect(x: geo.size.width / 2, y: geo.size.height - 160, width: 0, height: 0)
                    VueloXP(datos: vuelo, inicio: CGPoint(x: inicio.midX, y: inicio.midY), fin: CGPoint(x: fin.midX, y: fin.midY))
                        .id(vuelo.id)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .onChange(of: modelo.xpRonda) { anterior, nuevo in
            guard nuevo > anterior else { xpMostrado = nuevo; return }
            if reducir {
                withAnimation(.easeInOut(duration: 0.25)) { xpMostrado = nuevo }
                return
            }
            let datos = VueloXP.Datos(xp: nuevo - anterior)
            vuelo = datos
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(650))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { xpMostrado = nuevo }
                if vuelo?.id == datos.id { vuelo = nil }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaRonda")
    }

    @ViewBuilder
    private func cabecera(acento: Color) -> some View {
        // Con texto de accesibilidad, la barra de progreso pasa a una segunda línea.
        if tamano.isAccessibilitySize {
            VStack(spacing: Espacio.xs) {
                HStack(spacing: Espacio.m) {
                    botonSalir
                    Spacer(minLength: 0)
                    ContadorXP(xp: xpMostrado)
                    IndicadorCombo(combo: modelo.combo.actual, hitos: modelo.hitosCombo)
                }
                barra(acento: acento)
            }
            .padding(.horizontal, Espacio.l)
            .padding(.vertical, Espacio.s)
        } else {
            HStack(spacing: Espacio.m) {
                botonSalir
                barra(acento: acento)
                ContadorXP(xp: xpMostrado)
                IndicadorCombo(combo: modelo.combo.actual, hitos: modelo.hitosCombo)
            }
            .padding(.horizontal, Espacio.l)
            .padding(.vertical, Espacio.s)
        }
    }

    private func barra(acento: Color) -> some View {
        BarraProgresoRonda(actual: modelo.indice + (modelo.fase == .corregido ? 1 : 0), total: modelo.total, acento: acento)
    }

    private var botonSalir: some View {
            Button {
                if modelo.respondidos == 0 && modelo.fase == .respondiendo { cerrar() } else { confirmarSalida = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Paleta.textoSecundario)
                    .frame(width: Medidas.tactilMinimo, height: Medidas.tactilMinimo)
            }
            .accessibilityLabel("Salir de la ronda")
            .accessibilityIdentifier("botonSalir")
    }

    @ViewBuilder
    private func pie(acento: Color) -> some View {
        if modelo.fase == .corregido, let resultado = modelo.resultado, let item = modelo.itemActual {
            HojaFeedback(
                correcto: resultado.correcto, explicacion: item.explicacion,
                feedbackEspecifico: modelo.feedbackEspecifico, solucion: modelo.solucion,
                xp: modelo.efecto?.xp ?? 0, acento: acento, subioPeldano: modelo.efecto?.subioPeldano ?? false,
                puedeVerRegla: modelo.teoriaDelItem != nil,
                verRegla: { modelo.verRegla() },
                continuar: { modelo.continuar() })
            .transition(Movimiento.transicion(reducir: reducir))
        } else {
            VStack(spacing: Espacio.s) {
                #if DEBUG
                if ayudasDePrueba {
                    Button {
                        modelo.rellenarParaPruebas()
                    } label: {
                        Text("Rellenar (pruebas)").font(.footnote).frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo)
                    }
                        .accessibilityIdentifier("botonRellenarDebug")
                }
                #endif
                // Con texto de accesibilidad, Pista y Comprobar se apilan a todo el ancho.
                let apilar = tamano.isAccessibilitySize
                let disposicion = apilar ? AnyLayout(VStackLayout(spacing: Espacio.s)) : AnyLayout(HStackLayout(spacing: Espacio.m))
                disposicion {
                    if modelo.puedePedirPista {
                        Button {
                            modelo.pedirPista()
                        } label: {
                            Label("Pista", systemImage: "lightbulb")
                        }
                        .buttonStyle(EstiloBotonSecundario(acento: Paleta.recompensaTexto))
                        .frame(maxWidth: apilar ? .infinity : 140)
                        .accessibilityHint("Con pista, este ítem no da XP")
                        .accessibilityIdentifier("botonPista")
                    }
                    BotonPrincipal(titulo: "Comprobar", acento: acento) { modelo.comprobar() }
                        .disabled(!modelo.puedeComprobar)
                        .accessibilityIdentifier("botonComprobar")
                }
            }
        }
    }

    // MARK: Teoría previa y vacío

    private var teoriaPrevia: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text("Antes de empezar").font(.title2.bold()).foregroundStyle(Paleta.textoPrincipal)
                    ForEach(modelo.tarjetasPrevias) { tarjeta in
                        VistaTarjetaTeoria(tarjeta: tarjeta, acento: Paleta.acento(competencia: tarjeta.competencia))
                    }
                }
                .padding(Espacio.l)
            }
            BotonPrincipal(titulo: "Empezar", icono: "play.fill") { modelo.empezarTrasTeoria() }
                .padding(Espacio.l)
                .accessibilityIdentifier("botonEmpezarTrasTeoria")
        }
    }

    private var estadoVacio: some View {
        VStack(spacing: Espacio.l) {
            Image(systemName: "tray").font(.largeTitle).foregroundStyle(Paleta.textoSecundario).accessibilityHidden(true)
            Text("No hay ítems para esta ronda").font(.title3.bold()).foregroundStyle(Paleta.textoPrincipal)
            Text("Vuelve más tarde o prueba otra ronda.").font(.body).foregroundStyle(Paleta.textoSecundario)
            Button("Volver", action: cerrar).buttonStyle(EstiloBotonSecundario())
        }
        .multilineTextAlignment(.center)
        .padding(Espacio.xl)
    }
}

// MARK: - Resumen

struct PantallaResumen: View {
    let resumen: RondaViewModel.Resumen
    let nombreCompetencia: (String) -> String
    let otraRonda: () -> Void
    let terminar: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reducir
    @Environment(\.dynamicTypeSize) private var tamano
    @State private var aparecer = false
    @State private var xpMostrado = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Espacio.xl) {
                    VStack(spacing: Espacio.s) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Paleta.recompensa)
                            .symbolEffect(.bounce, value: aparecer)
                            .accessibilityHidden(true)
                        Text("¡Ronda completada!")
                            .font(.redondeada(.largeTitle, peso: .bold))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.top, Espacio.xl)

                    let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Espacio.m)) : AnyLayout(HStackLayout(spacing: Espacio.m))
                    disposicion {
                        dato("\(resumen.aciertos)/\(resumen.total)", "Aciertos", icono: "checkmark.circle.fill", color: Paleta.exito)
                        dato("+\(xpMostrado)", "XP", icono: "sparkles", color: Paleta.recompensaTexto, valorAccesible: "+\(resumen.xp)")
                            .accessibilityIdentifier("resumenXP")
                        dato("×\(resumen.comboMaximo)", "Combo máx.", icono: "bolt.fill", color: Paleta.recompensaTexto)
                    }

                    VStack(spacing: Espacio.s) {
                        ChipRacha(dias: resumen.racha.actual, protectores: resumen.racha.protectores, record: resumen.racha.record)
                        if let texto = textoRacha {
                            Text(texto).font(.subheadline.weight(.medium)).foregroundStyle(Paleta.textoSecundario)
                                .multilineTextAlignment(.center)
                        }
                    }

                    if !resumen.subidas.isEmpty {
                        seccion("Subes de peldaño", icono: "arrow.up.circle.fill") {
                            ForEach(resumen.subidas, id: \.self) { Text(nombreCompetencia($0)) }
                        }
                    }
                    if !resumen.misionesCompletadas.isEmpty {
                        seccion("Misiones completadas", icono: "checkmark.seal.fill") {
                            ForEach(resumen.misionesCompletadas) { Text($0.titulo) }
                        }
                    }
                    if !resumen.logros.isEmpty {
                        seccion("Logros", icono: "trophy.fill") {
                            ForEach(resumen.logros) { logro in
                                VStack(alignment: .leading) {
                                    Text(logro.titulo).bold()
                                    Text(logro.descripcion).font(.footnote).foregroundStyle(Paleta.textoSecundario)
                                }
                            }
                        }
                    }
                    // Los botones van al final del contenido (no fijos), para que nada quede
                    // cortado bajo ellos.
                    VStack(spacing: Espacio.m) {
                        BotonPrincipal(titulo: "Otra ronda", icono: "arrow.clockwise",
                                       acento: Paleta.acento(area: resumen.areaPredominante), accion: otraRonda)
                            .accessibilityIdentifier("botonOtraRonda")
                        Button("Terminar", action: terminar)
                            .buttonStyle(EstiloBotonSecundario(acento: Paleta.acento(area: resumen.areaPredominante)))
                            .accessibilityIdentifier("botonTerminar")
                    }
                    .padding(.top, Espacio.s)
                }
                .padding(Espacio.l)
            }
        }
        .onAppear {
            aparecer = true
            contarXP()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("resumenRonda")
    }

    private var textoRacha: String? {
        let c = resumen.cambiosRacha
        if let perdida = c.rachaPerdida { return "Tu racha de \(perdida) días se rompió. ¡Empiezas una nueva!" }
        if c.protectoresUsados > 0 { return c.protectoresUsados == 1 ? "Has usado 1 protector." : "Has usado \(c.protectoresUsados) protectores." }
        if c.protectorGanado { return "¡Semana completa! Ganas un protector." }
        if c.incrementada && resumen.racha.actual == 1 { return "¡Empiezas tu racha! Vuelve mañana para mantenerla." }
        if c.nuevoRecord { return "¡Nuevo récord de racha!" }
        if c.incrementada { return "Racha mantenida hoy." }
        return nil
    }

    /// El contador de XP sube animado; con "Reducir movimiento", aparece con un fundido.
    private func contarXP() {
        let final = resumen.xp
        guard final > 0 else { return }
        if reducir {
            withAnimation(.easeIn(duration: 0.3)) { xpMostrado = final }
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            let pasos = min(final, 24)
            for paso in 1...pasos {
                try? await Task.sleep(for: .milliseconds(35))
                withAnimation(.snappy(duration: 0.1)) { xpMostrado = final * paso / pasos }
            }
        }
    }

    private func dato(_ valor: String, _ titulo: String, icono: String, color: Color, valorAccesible: String? = nil) -> some View {
        VStack(spacing: Espacio.xs) {
            Image(systemName: icono).foregroundStyle(color).accessibilityHidden(true)
            Text(valor).font(.redondeada(.title2, peso: .bold)).foregroundStyle(Paleta.textoPrincipal)
                .contentTransition(.numericText())
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(titulo).font(.caption).foregroundStyle(Paleta.textoSecundario)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espacio.m)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(Paleta.borde))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titulo)
        .accessibilityValue(valorAccesible ?? valor)
    }

    private func seccion<C: View>(_ titulo: String, icono: String, @ViewBuilder contenido: () -> C) -> some View {
        let cuerpo = contenido()
        return TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.s) {
                Label(titulo, systemImage: icono).font(.headline).foregroundStyle(Paleta.recompensaTexto)
                cuerpo.font(.body).foregroundStyle(Paleta.textoPrincipal)
            }
        }
    }
}

// MARK: - Recompensa al acertar

/// Contador de XP de la ronda en la cabecera (destino del vuelo de "+N XP").
struct ContadorXP: View {
    let xp: Int

    var body: some View {
        HStack(spacing: Espacio.xs) {
            Image(systemName: "sparkles").foregroundStyle(Paleta.recompensaTexto).accessibilityHidden(true)
            Text("\(xp)")
                .font(.redondeada(.subheadline, peso: .bold))
                .foregroundStyle(Paleta.textoPrincipal)
                .contentTransition(.numericText(value: Double(xp)))
        }
        .padding(.horizontal, Espacio.m)
        .frame(minHeight: Medidas.tactilMinimo)
        .background(Paleta.superficie, in: Capsule())
        .overlay(Capsule().strokeBorder(Paleta.borde))
        .anchorPreference(key: AnclasVueloXP.self, value: .bounds) { ["destino": $0] }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("XP de la ronda")
        .accessibilityValue("\(xp)")
        .accessibilityIdentifier("contadorXP")
    }
}

/// Cápsula "+N XP" que vuela desde el panel de feedback hasta el contador de la cabecera.
struct VueloXP: View {
    struct Datos: Equatable {
        let id = UUID()
        let xp: Int
    }

    let datos: Datos
    let inicio: CGPoint
    let fin: CGPoint
    @State private var llegado = false

    var body: some View {
        Text("+\(datos.xp) XP")
            .font(.redondeada(.subheadline, peso: .bold))
            .foregroundStyle(Paleta.textoSobreRecompensa)
            .padding(.horizontal, Espacio.s)
            .padding(.vertical, Espacio.xs)
            .background(Paleta.recompensa, in: Capsule())
            .shadow(color: Paleta.recompensa.opacity(0.6), radius: 8)
            .scaleEffect(llegado ? 0.6 : 1.1)
            .opacity(llegado ? 0 : 1)
            .position(llegado ? fin : inicio)
            .onAppear {
                withAnimation(.easeIn(duration: 0.6)) { llegado = true }
            }
    }
}

/// Pulso breve de escala y brillo verde sobre la mecánica al acertar. Con "Reducir
/// movimiento", solo el brillo (fundido), sin escala.
struct PulsoAcierto: ViewModifier {
    /// Cambia (distinto de 0) en cada acierto.
    let disparo: Int
    @Environment(\.accessibilityReduceMotion) private var reducir
    @State private var escala: CGFloat = 1
    @State private var brillo = 0.0

    func body(content: Content) -> some View {
        content
            .shadow(color: Paleta.exito.opacity(brillo * 0.55), radius: 18)
            .scaleEffect(escala)
            .onChange(of: disparo) { _, nuevo in
                guard nuevo > 0 else { return }
                if reducir {
                    withAnimation(.easeOut(duration: 0.2)) { brillo = 1 }
                    withAnimation(.easeIn(duration: 0.4).delay(0.2)) { brillo = 0 }
                } else {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { escala = 1.03; brillo = 1 }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.18)) { escala = 1 }
                    withAnimation(.easeIn(duration: 0.5).delay(0.25)) { brillo = 0 }
                }
            }
    }
}
