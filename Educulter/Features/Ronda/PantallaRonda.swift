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
    /// Panel del texto base plegado (se conserva entre ítems; se despliega con cada texto nuevo).
    @State private var textoPlegado = false
    /// Alto de la pantalla, para limitar el panel del texto base a una parte de ella.
    @State private var altoPantalla: CGFloat = 800
    @Environment(\.accessibilityReduceMotion) private var reducir
    @Environment(\.dynamicTypeSize) private var tamano
    @Environment(\.vibracionActiva) private var vibracionActiva
    @Environment(\.sonido) private var sonido
    @Environment(EntornoApp.self) private var entorno

    var body: some View {
        ZStack {
            Paleta.fondo.ignoresSafeArea()
            switch modelo.fase {
            case .resumen:
                if let plan = modelo.plan {
                    PantallaPlan(plan: plan, servicio: modelo.servicio, terminar: cerrar)
                        .transition(Movimiento.transicion(reducir: reducir))
                } else if let r = modelo.resultadoPartida {
                    PantallaFinPartida(resultado: r, servicio: modelo.servicio, otraPartida: { modelo.otraRonda() }, terminar: cerrar)
                        .transition(Movimiento.transicion(reducir: reducir))
                } else if let resumen = modelo.resumen {
                    PantallaResumen(resumen: resumen, nombreCompetencia: modelo.nombreCompetencia,
                                    resultadoModo: textoModo, otraRonda: { modelo.otraRonda() }, terminar: cerrar)
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
        .background {
            GeometryReader { g in
                Color.clear
                    .onAppear { altoPantalla = g.size.height }
                    .onChange(of: g.size.height) { _, nuevo in altoPantalla = nuevo }
            }
        }
        .sheet(item: $modelo.teoriaAbierta) { tarjeta in
            NavigationStack {
                ScrollView {
                    VistaTarjetaTeoria(tarjeta: tarjeta, acento: Paleta.tinta(competencia: tarjeta.competencia))
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
        .confirmationDialog(modelo.esSupervivencia ? "¿Abandonar la partida?" : "¿Salir de la ronda?", isPresented: $confirmarSalida, titleVisibility: .visible) {
            Button(modelo.esSupervivencia ? "Abandonar" : "Salir", role: .destructive) {
                modelo.abandonar()
                cerrar()
            }
            Button("Seguir jugando", role: .cancel) {}
        } message: {
            Text(modelo.esSupervivencia ? "Lo jugado se guarda, pero una partida abandonada no cuenta para el récord." : "Lo que has respondido ya está guardado.")
        }
        // Tras la primera ronda completada se pregunta una vez, en contexto, por el recordatorio.
        .alert("¿Te aviso cada día?", isPresented: $modelo.preguntarRecordatorio) {
            Button("Sí") { Task { await entorno.activarRecordatorio() } }
            Button("Ahora no", role: .cancel) { modelo.responderRecordatorio(false); entorno.recargarAjustes() }
        } message: {
            Text("¿Te aviso cada día a las \(entorno.ajustes.horaTexto) para no perder la racha? Puedes cambiarlo en Progreso → Ajustes.")
        }
        .onAppear { modelo.sonido = sonido }
        .onChange(of: modelo.fase) { _, nueva in if nueva == .resumen { entorno.rondaCompletada() } }
    }

    /// Resultado de la prueba de nivel o del Reto de bloque, para el resumen.
    private var textoModo: String? {
        guard let e = modelo.efectoFinal else { return nil }
        if let superada = e.pruebaNivelSuperada {
            return superada ? "Prueba de nivel superada: los peldaños 1 y 2 quedan superados y empiezas en el 3."
                : "Prueba de nivel no superada (hacen falta 4 aciertos de 5). Puedes practicar desde el principio o repetirla."
        }
        if let superado = e.retoSuperado {
            return superado ? "¡Reto superado! Has ganado la medalla del bloque." : "Reto no superado (hacen falta 6 aciertos de 8). Inténtalo otra vez cuando quieras."
        }
        return nil
    }

    // MARK: Ítem

    private var pantallaItem: some View {
        let item = modelo.itemActual
        let acento = item.map { Paleta.acento(competencia: $0.competencia) } ?? Paleta.matematicas
        return VStack(spacing: 0) {
            cabecera(acento: acento)
            if let texto = modelo.textoBase {
                // Texto base fijo arriba: el ítem se responde debajo sin perderlo de vista.
                // Como mucho un 30 % de la pantalla (22 % con texto de accesibilidad): el ítem y el pie
                // con «Comprobar» caben siempre debajo.
                VistaTextoBase(texto: texto, anio: modelo.anioTextoBase, plegado: $textoPlegado,
                               altoMaximo: max(110, altoPantalla * (tamano.isAccessibilitySize ? 0.22 : 0.3)))
                    .padding(.horizontal, Espacio.l)
                    .padding(.bottom, Espacio.s)
                    .transition(Movimiento.transicion(reducir: reducir))
            }
            GeometryReader { geo in
            ScrollView {
                if let item {
                    VStack(alignment: .leading, spacing: Espacio.l) {
                        Label {
                            Text(modelo.nombreCompetencia(item.competencia).uppercased())
                        } icon: {
                            Image(systemName: SimboloBloque.de(competencia: item.competencia)).accessibilityHidden(true)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Paleta.tinta(competencia: item.competencia))
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
                        // Panel protagonista: el único elemento tintado de la pantalla (v2).
                        PanelProtagonista(tinte: Paleta.tinte(competencia: item.competencia)) {
                            VistaMecanica(contexto: ContextoMecanica(item: item, acento: acento, resultado: modelo.resultado),
                                          respuesta: $modelo.respuesta)
                        }
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
            guard vibracionActiva, let nuevo else { return nil }
            return nuevo.correcto ? .success : .error
        }
        .retroHaptica(.impact(weight: .heavy), trigger: modelo.hitosCombo)
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
                try? await Task.sleep(for: .milliseconds(370))
                withAnimation(.smooth(duration: 0.3)) { xpMostrado = nuevo }
                if vuelo?.id == datos.id { vuelo = nil }
            }
        }
        .onChange(of: modelo.textoBase?.id) { anterior, nuevo in
            if nuevo != nil && nuevo != anterior { textoPlegado = false }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaRonda")
    }

    @ViewBuilder
    private func cabecera(acento: Color) -> some View {
        if let estado = modelo.supervivencia {
            CabeceraSupervivencia(estado: estado, puntosUltimo: modelo.puntosUltimo, salir: { botonSalir })
                .padding(.horizontal, Espacio.l)
                .padding(.vertical, Espacio.s)
        } else if modelo.esDiagnostico {
            HStack(spacing: Espacio.m) {
                botonSalir
                BarraProgresoRonda(actual: modelo.respondidos, total: max(modelo.totalDiagnostico, 1), acento: acento)
                Text("\(min(modelo.indice + 1, modelo.totalDiagnostico)) de \(modelo.totalDiagnostico)")
                    .font(.numerica(.subheadline))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .fixedSize()
                    .accessibilityIdentifier("progresoDiagnostico")
            }
            .padding(.horizontal, Espacio.l)
            .padding(.vertical, Espacio.s)
        } else if tamano.isAccessibilitySize {
            // Con texto de accesibilidad, la barra de progreso pasa a una segunda línea.
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
                xp: modelo.efecto?.xp ?? 0, acento: acento, aparicion: modelo.aparicionFeedback,
                tinta: Paleta.tinta(competencia: item.competencia),
                subioPeldano: modelo.efecto?.subioPeldano ?? false,
                puedeVerRegla: modelo.teoriaDelItem != nil,
                verRegla: { modelo.verRegla() },
                continuar: { modelo.continuar() })
            .transition(Movimiento.transicion(reducir: reducir))
        } else {
            VStack(spacing: Espacio.s) {
                #if DEBUG
                if ayudasDePrueba {
                    HStack {
                        Button {
                            modelo.rellenarParaPruebas()
                        } label: {
                            Text("Rellenar (pruebas)").font(.footnote).fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo)
                        }
                        .accessibilityIdentifier("botonRellenarDebug")
                        Button {
                            modelo.rellenarParaPruebas(correcta: false)
                        } label: {
                            Text("Con error (pruebas)").font(.footnote).fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo)
                        }
                        .accessibilityIdentifier("botonRellenarErrorDebug")
                    }
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
                    Text("Antes de empezar").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                    ForEach(modelo.tarjetasPrevias) { tarjeta in
                        VistaTarjetaTeoria(tarjeta: tarjeta, acento: Paleta.tinta(competencia: tarjeta.competencia))
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
            Text("No hay ítems para esta ronda").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal)
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
    /// Resultado de la prueba de nivel o del Reto de bloque (Fase 05D).
    var resultadoModo: String? = nil
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
                        // Fin de sesión: el personaje del área predominante, alegre (D-105).
                        VistaPersonaje(companero: Companero.de(area: resumen.areaPredominante), estado: .alegre, tamano: 80)
                        Text("¡Ronda completada!")
                            .font(.exhibicion(.largeTitle))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.top, Espacio.xl)

                    if let resultadoModo {
                        Text(resultadoModo)
                            .font(.headline)
                            .foregroundStyle(Paleta.textoPrincipal)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(Espacio.m)
                            .frame(maxWidth: .infinity)
                            .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
                            .contornoTinta(radio: Radio.ficha)
                            .accessibilityIdentifier("resultadoModo")
                    }

                    let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Espacio.m)) : AnyLayout(HStackLayout(spacing: Espacio.m))
                    disposicion {
                        dato("\(resumen.aciertos)/\(resumen.total)", "Aciertos", icono: "checkmark.circle.fill", color: Paleta.exito)
                        dato("+\(xpMostrado)", "XP", icono: "sparkles", color: Paleta.recompensaTexto, valorAccesible: "+\(resumen.xp)")
                            .accessibilityIdentifier("resumenXP")
                        dato("×\(resumen.comboMaximo)", "Combo máx.", icono: "bolt.fill", color: Paleta.recompensaTexto)
                    }
                    // Los tres datos comparten una sola baldosa neutra (sin tarjetas repetidas).
                    .padding(Espacio.m)
                    .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                    .contornoTinta(radio: Radio.tarjeta)

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
                                    Text(logro.titulo).fontWeight(.semibold)
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
                            .buttonStyle(EstiloBotonSecundario(acento: Paleta.tinta(area: resumen.areaPredominante)))
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
            let pasos = min(final, 12)
            for paso in 1...pasos {
                try? await Task.sleep(for: .milliseconds(28))
                withAnimation(.snappy(duration: 0.1)) { xpMostrado = final * paso / pasos }
            }
        }
    }

    private func dato(_ valor: String, _ titulo: String, icono: String, color: Color, valorAccesible: String? = nil) -> some View {
        VStack(spacing: Espacio.xs) {
            Image(systemName: icono).foregroundStyle(color).accessibilityHidden(true)
            Text(valor).font(.numerica(.title2, peso: .semibold)).foregroundStyle(Paleta.textoPrincipal)
                .contentTransition(.numericText())
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(titulo).font(.caption).foregroundStyle(Paleta.textoSecundario)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espacio.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titulo)
        .accessibilityValue(valorAccesible ?? valor)
    }

    private func seccion<C: View>(_ titulo: String, icono: String, @ViewBuilder contenido: () -> C) -> some View {
        // Secciones como grupos con título (no tarjetas repetidas, v2).
        let cuerpo = contenido()
        return VStack(alignment: .leading, spacing: Espacio.s) {
            Label(titulo, systemImage: icono).font(.headline).foregroundStyle(Paleta.recompensaTexto)
            cuerpo.font(.body).foregroundStyle(Paleta.textoPrincipal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .font(.numerica(.subheadline, peso: .semibold))
                .foregroundStyle(Paleta.textoPrincipal)
                .contentTransition(.numericText(value: Double(xp)))
        }
        .padding(.horizontal, Espacio.m)
        .frame(minHeight: Medidas.tactilMinimo)
        .background(Paleta.superficie, in: Capsule())
        .overlay(Capsule().strokeBorder(Paleta.borde, lineWidth: Trazo.fino))
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
            .font(.numerica(.subheadline, peso: .semibold))
            .foregroundStyle(Paleta.textoSobreRecompensa)
            .padding(.horizontal, Espacio.s)
            .padding(.vertical, Espacio.xs)
            .background(Paleta.recompensa, in: Capsule())
            .overlay(Capsule().strokeBorder(Paleta.borde, lineWidth: Trazo.fino))
            .scaleEffect(llegado ? 0.6 : 1.1)
            .opacity(llegado ? 0 : 1)
            .position(llegado ? fin : inicio)
            .onAppear {
                withAnimation(.easeIn(duration: 0.35)) { llegado = true }
            }
    }
}

/// Pulso breve de escala sobre la mecánica al acertar (≤ 0,35 s, sin brillos ni sombras).
/// Con "Reducir movimiento", un fundido breve.
struct PulsoAcierto: ViewModifier {
    /// Cambia (distinto de 0) en cada acierto.
    let disparo: Int
    @Environment(\.accessibilityReduceMotion) private var reducir
    @State private var escala: CGFloat = 1
    @State private var brillo = 0.0

    func body(content: Content) -> some View {
        content
            .opacity(1 - brillo * 0.25)
            .scaleEffect(escala)
            .onChange(of: disparo) { _, nuevo in
                guard nuevo > 0 else { return }
                if reducir {
                    withAnimation(.easeOut(duration: 0.15)) { brillo = 1 }
                    withAnimation(.easeIn(duration: 0.2).delay(0.15)) { brillo = 0 }
                } else {
                    withAnimation(.smooth(duration: 0.15)) { escala = 1.03 }
                    withAnimation(.smooth(duration: 0.2).delay(0.15)) { escala = 1 }
                }
            }
    }
}
