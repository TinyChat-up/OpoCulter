import SwiftUI

/// Pantalla de una ronda: progreso, combo, enunciado, mecánica, Comprobar y feedback.
struct PantallaRonda: View {
    @Bindable var modelo: RondaViewModel
    var ayudasDePrueba = false
    let cerrar: () -> Void

    @State private var confirmarSalida = false
    @Environment(\.accessibilityReduceMotion) private var reducir

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
            ScrollView {
                if let item {
                    VStack(alignment: .leading, spacing: Espacio.l) {
                        Text(modelo.nombreCompetencia(item.competencia).uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(acento)
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
                        VistaMecanica(contexto: ContextoMecanica(item: item, acento: acento, resultado: modelo.resultado),
                                      respuesta: $modelo.respuesta)
                            .id(item.id)
                    }
                    .padding(Espacio.l)
                }
            }
            .scrollDismissesKeyboard(.never)
        }
        .safeAreaInset(edge: .bottom) {
            pie(acento: acento)
                .padding(.horizontal, Espacio.l)
                .padding(.bottom, Espacio.s)
                .padding(.top, Espacio.s)
                .background(Paleta.fondo.opacity(0.97))
        }
        .sensoryFeedback(trigger: modelo.resultado) { _, nuevo in
            guard let nuevo else { return nil }
            return nuevo.correcto ? .success : .error
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: modelo.hitosCombo)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaRonda")
    }

    private func cabecera(acento: Color) -> some View {
        HStack(spacing: Espacio.m) {
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
            BarraProgresoRonda(actual: modelo.indice + (modelo.fase == .corregido ? 1 : 0), total: modelo.total, acento: acento)
            IndicadorCombo(combo: modelo.combo.actual)
        }
        .padding(.horizontal, Espacio.l)
        .padding(.vertical, Espacio.s)
    }

    @ViewBuilder
    private func pie(acento: Color) -> some View {
        if modelo.fase == .corregido, let resultado = modelo.resultado, let item = modelo.itemActual {
            HojaFeedback(
                correcto: resultado.correcto, explicacion: item.explicacion,
                feedbackEspecifico: modelo.feedbackEspecifico, solucion: modelo.solucion,
                xp: modelo.efecto?.xp ?? 0, subioPeldano: modelo.efecto?.subioPeldano ?? false,
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
                HStack(spacing: Espacio.m) {
                    if modelo.puedePedirPista {
                        Button {
                            modelo.pedirPista()
                        } label: {
                            Label("Pista", systemImage: "lightbulb")
                        }
                        .buttonStyle(EstiloBotonSecundario(acento: Paleta.recompensaTexto))
                        .frame(maxWidth: 140)
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
                        dato("+\(resumen.xp)", "XP", icono: "sparkles", color: Paleta.recompensaTexto)
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
                        BotonPrincipal(titulo: "Otra ronda", icono: "arrow.clockwise", accion: otraRonda)
                            .accessibilityIdentifier("botonOtraRonda")
                        Button("Terminar", action: terminar)
                            .buttonStyle(EstiloBotonSecundario())
                            .accessibilityIdentifier("botonTerminar")
                    }
                    .padding(.top, Espacio.s)
                }
                .padding(Espacio.l)
            }
        }
        .onAppear { aparecer = true }
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

    private func dato(_ valor: String, _ titulo: String, icono: String, color: Color) -> some View {
        VStack(spacing: Espacio.xs) {
            Image(systemName: icono).foregroundStyle(color).accessibilityHidden(true)
            Text(valor).font(.redondeada(.title2, peso: .bold)).foregroundStyle(Paleta.textoPrincipal)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(titulo).font(.caption).foregroundStyle(Paleta.textoSecundario)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espacio.m)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(Paleta.borde))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titulo)
        .accessibilityValue(valor)
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
