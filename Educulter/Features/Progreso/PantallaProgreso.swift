import Charts
import SwiftUI

/// Progreso: dominio, evolución (Swift Charts), estadísticas, preguntas disponibles, logros y ajustes.
/// Todo sale del historial real; si no hay datos, lo dice.
struct PantallaProgreso: View {
    let servicio: ServicioSesion
    @Environment(EntornoApp.self) private var entorno
    @Environment(\.dynamicTypeSize) private var tamanoTexto
    @State private var estadisticas: EstadisticasProgreso?
    @State private var logros: [(logro: Logro, obtenido: Date?)] = []
    @State private var preguntas: RecuentoCatalogo?
    @State private var estados: [String: EstadoCompetencia] = [:]
    @State private var serie = "Aciertos"
    @State private var confirmarBorrado = false
    @State private var confirmarBorradoFinal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.xl) {
                    Text("Progreso").font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    seccionDominio
                    if let e = estadisticas {
                        seccionEvolucion(e)
                        seccionEstadisticas(e)
                    }
                    seccionPreguntas
                    seccionLogros
                    NavigationLink {
                        PantallaAjustes(servicio: servicio)
                    } label: {
                        Label("Ajustes", systemImage: "gearshape.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .padding(.horizontal, Espacio.l)
                            .superficiePulsable(Paleta.superficie, radio: Radio.tarjeta)
                    }
                    .buttonStyle(.pulsable)
                    .foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityIdentifier("botonAjustes")
                    Button("Borrar mi progreso", role: .destructive) { confirmarBorrado = true }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Paleta.fallo)
                        .frame(maxWidth: .infinity, minHeight: Medidas.tactilMinimo)
                        .accessibilityIdentifier("botonBorrarProgreso")
                }
                .padding(Espacio.l)
            }
            .contentMargins(.bottom, Espacio.xxl * 2, for: .scrollContent)
            .background(Paleta.fondo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear(perform: cargar)
        // Doble confirmación: primero un diálogo y después una alerta.
        .confirmationDialog("¿Borrar todo tu progreso?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Continuar", role: .destructive) { confirmarBorradoFinal = true }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrarán tus respuestas, peldaños, Rescate, XP, racha, logros, diagnósticos y partidas. Los ajustes se conservan.")
        }
        .alert("¿Seguro? No se puede deshacer.", isPresented: $confirmarBorradoFinal) {
            Button("Borrar", role: .destructive) {
                try? servicio.borrarProgreso()
                cargar()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaProgreso")
    }

    private func cargar() {
        estadisticas = try? servicio.estadisticas()
        logros = (try? servicio.catalogoLogros()) ?? []
        estados = (try? servicio.repositorio.estadosCompetencia()) ?? [:]
        if preguntas == nil { preguntas = servicio.preguntasDisponibles() }
    }

    // MARK: Secciones

    private var seccionDominio: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            titulo("Dominio")
            ForEach(servicio.banco.catalogo.areas, id: \.id) { area in
                let acento = Paleta.acento(area: area.id)
                VStack(alignment: .leading, spacing: Espacio.s) {
                    let d = servicio.dominioArea(area.id, estados: estados)
                    // Con texto de accesibilidad, el porcentaje va debajo del nombre; si no, en la misma
                    // línea y con prioridad de diseño, para que el número nunca se parta (§4.3 de la 05E).
                    // ViewThatFits daba en la auditoría «Dynamic Type font sizes are partially unsupported»
                    // sobre el nombre del área y el porcentaje (textos de la variante no mostrada), D-097.
                    let porcentaje = Text("\(Int((d * 100).rounded())) %").font(.redondeada(.subheadline))
                        .foregroundStyle(Paleta.textoSecundario)
                    let nombre = Text(area.nombre).font(.headline).foregroundStyle(Paleta.textoPrincipal)
                        .fixedSize(horizontal: false, vertical: true)
                    let disposicion = tamanoTexto.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.xs))
                        : AnyLayout(HStackLayout(spacing: Espacio.s))
                    HStack(alignment: tamanoTexto.isAccessibilitySize ? .top : .center, spacing: Espacio.m) {
                        AnilloDominio(fraccion: max(d, 0.02), acento: acento).frame(width: 44, height: 44)
                        disposicion {
                            nombre.layoutPriority(1)
                            if !tamanoTexto.isAccessibilitySize { Spacer(minLength: Espacio.s) }
                            porcentaje.layoutPriority(2)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    ForEach(area.bloques.sorted { $0.orden < $1.orden }, id: \.id) { b in
                        HStack(spacing: Espacio.m) {
                            if let db = servicio.dominio(bloque: b, estados: estados) {
                                AnilloDominio(fraccion: max(db, 0.02), acento: acento, grosor: 4).frame(width: 28, height: 28)
                                Text(b.nombre).foregroundStyle(Paleta.textoPrincipal)
                                    .fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                                Spacer()
                                Text("\(Int((db * 100).rounded())) %").font(.redondeada(.footnote)).foregroundStyle(Paleta.textoSecundario)
                            } else {
                                Circle().strokeBorder(Paleta.borde, style: StrokeStyle(lineWidth: 2, dash: [4, 3])).frame(width: 28, height: 28)
                                Text(b.nombre).foregroundStyle(Paleta.textoSecundario)
                                    .fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                                Spacer()
                                Text("En preparación").font(.footnote).foregroundStyle(Paleta.textoSecundario)
                            }
                        }
                        .font(.subheadline)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(Espacio.m)
                .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                .contornoTinta(radio: Radio.tarjeta)
            }
        }
        .accessibilityIdentifier("seccionDominio")
    }

    private func seccionEvolucion(_ e: EstadisticasProgreso) -> some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            titulo("Evolución · 4 semanas")
            Picker("Serie", selection: $serie) {
                Text("Aciertos").tag("Aciertos")
                Text("XP").tag("XP")
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("serieEvolucion")
            if e.evolucion.allSatisfy({ $0.respondidos == 0 }) {
                Text("Aún no hay actividad en las últimas 4 semanas.").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
            }
            Chart(e.evolucion) { d in
                BarMark(x: .value("Día", d.fecha, unit: .day), y: .value(serie, serie == "XP" ? d.xp : d.aciertos))
                    .foregroundStyle(serie == "XP" ? Paleta.recompensa : Paleta.matematicas)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: 7)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
            .frame(height: 180)
            // Un solo elemento accesible con descripción y gráfico de audio (las etiquetas de los
            // ejes no son elementos sueltos).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(serie) por día en las últimas 4 semanas")
            .accessibilityValue("Total: \(e.evolucion.map { serie == "XP" ? $0.xp : $0.aciertos }.reduce(0, +))")
            .accessibilityChartDescriptor(DescriptorEvolucion(dias: e.evolucion, serie: serie))
            .accessibilityIdentifier("graficoEvolucion")
        }
        .padding(Espacio.m)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .contornoTinta(radio: Radio.tarjeta)
    }

    private func seccionEstadisticas(_ e: EstadisticasProgreso) -> some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            titulo("Estadísticas")
            fila("Racha actual", e.rachaActual == 1 ? "1 día" : "\(e.rachaActual) días")
            fila("Récord de racha", e.rachaRecord == 1 ? "1 día" : "\(e.rachaRecord) días")
            fila("Récord de Supervivencia", e.recordSupervivencia.map { "\($0) puntos" } ?? "Sin partidas")
            fila("Ítems respondidos", "\(e.respondidos)")
            fila("Acierto en Lengua", e.porArea["LEN"]?.porcentaje.map { "\(Int(($0 * 100).rounded())) %" } ?? "—")
            fila("Acierto en Matemáticas", e.porArea["MAT"]?.porcentaje.map { "\(Int(($0 * 100).rounded())) %" } ?? "—")
        }
        .accessibilityIdentifier("seccionEstadisticas")
    }

    private var seccionPreguntas: some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            titulo("Preguntas disponibles")
            Text(preguntas.map { "\($0.exacto ? "" : "Al menos ")\($0.total.formatted()) preguntas distintas" } ?? "Contando…")
                .font(.redondeada(.title3)).foregroundStyle(Paleta.textoPrincipal)
            Text("Solo cuenta el contenido revisado y aprobado. Crece con cada lote.")
                .font(.footnote).foregroundStyle(Paleta.textoSecundario)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("preguntasDisponibles")
    }

    private var seccionLogros: some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            titulo("Logros · \(logros.filter { $0.obtenido != nil }.count) de \(logros.count)")
            LazyVStack(spacing: Espacio.s) {
                ForEach(logros, id: \.logro.id) { l in
                    HStack(spacing: Espacio.m) {
                        Image(systemName: l.obtenido == nil ? "trophy" : "trophy.fill")
                            .font(.title3)
                            .foregroundStyle(l.obtenido == nil ? Paleta.textoSecundario : Paleta.recompensaTexto)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.logro.titulo).font(.body.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                            Text(l.obtenido.map { "Conseguido el \($0.formatted(.dateTime.day().month(.wide)))" } ?? l.logro.descripcion)
                                .font(.footnote).foregroundStyle(Paleta.textoSecundario)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(l.obtenido == nil ? "pendiente" : "conseguido")
                }
            }
        }
        .accessibilityIdentifier("seccionLogros")
    }

    private func titulo(_ t: String) -> some View {
        Text(t).font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
    }

    private func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).foregroundStyle(Paleta.textoPrincipal)
            Spacer()
            Text(v).font(.redondeada(.body)).foregroundStyle(Paleta.textoSecundario)
        }
        .frame(minHeight: Medidas.tactilMinimo)
        .accessibilityElement(children: .combine)
    }
}

/// Descripción accesible (gráfico de audio de VoiceOver) de la evolución diaria.
struct DescriptorEvolucion: AXChartDescriptorRepresentable {
    let dias: [EstadisticasProgreso.Dia]
    let serie: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let valores = dias.map { Double(serie == "XP" ? $0.xp : $0.aciertos) }
        let formato = DateFormatter()
        formato.dateFormat = "d MMM"
        formato.locale = Locale(identifier: "es_ES")
        let x = AXCategoricalDataAxisDescriptor(title: "Día", categoryOrder: dias.map { formato.string(from: $0.fecha) })
        let y = AXNumericDataAxisDescriptor(title: serie, range: 0...max(valores.max() ?? 1, 1), gridlinePositions: []) { "\(Int($0)) \(serie == "XP" ? "XP" : "aciertos")" }
        let datos = AXDataSeriesDescriptor(name: serie, isContinuous: false,
                                           dataPoints: zip(dias, valores).map { AXDataPoint(x: formato.string(from: $0.fecha), y: $1) })
        return AXChartDescriptor(title: "\(serie) por día, últimas 4 semanas",
                                 summary: "Total: \(Int(valores.reduce(0, +))). Días con actividad: \(valores.filter { $0 > 0 }.count) de \(dias.count).",
                                 xAxis: x, yAxis: y, additionalAxes: [], series: [datos])
    }
}

/// Ajustes: sonido, vibración, recordatorio (con hora), repetir diagnóstico, avatar y créditos.
struct PantallaAjustes: View {
    let servicio: ServicioSesion
    @Environment(EntornoApp.self) private var entorno
    @State private var ronda: RondaViewModel?
    @State private var mostrarPerfil = false

    var body: some View {
        let ajustes = Binding(get: { entorno.ajustes }, set: { entorno.guardar($0) })
        // Diseño propio (no `Form`): los encabezados del sistema no cumplen el contraste sobre el
        // papel ni escalan del todo con Dynamic Type.
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.l) {
                Text("Ajustes").font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                grupo("Sonido y vibración") {
                    Toggle("Sonido", isOn: ajustes.sonido).accessibilityIdentifier("ajusteSonido")
                    Toggle("Vibración", isOn: ajustes.vibracion).accessibilityIdentifier("ajusteVibracion")
                }
                grupo("Recordatorio") {
                    Toggle("Recordatorio diario", isOn: Binding(get: { entorno.ajustes.recordatorio }, set: { activar in
                        if activar { Task { await entorno.activarRecordatorio() } } else { var a = entorno.ajustes; a.recordatorio = false; entorno.guardar(a) }
                    }))
                    .accessibilityIdentifier("ajusteRecordatorio")
                    if entorno.ajustes.recordatorio {
                        DatePicker("Hora", selection: Binding(get: {
                            Calendar.current.date(bySettingHour: entorno.ajustes.hora, minute: entorno.ajustes.minuto, second: 0, of: .now) ?? .now
                        }, set: { fecha in
                            var a = entorno.ajustes
                            let c = Calendar.current.dateComponents([.hour, .minute], from: fecha)
                            a.minutoRecordatorio = (c.hour ?? 20) * 60 + (c.minute ?? 0)
                            entorno.guardar(a)
                        }), displayedComponents: .hourAndMinute)
                        .accessibilityIdentifier("ajusteHora")
                    }
                    Text("Un aviso local al día, sin servidor. Si ese día ya has hecho una ronda, no suena.")
                        .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                }
                grupo("Tu cuenta") {
                    Button("Repetir diagnóstico") { ronda = RondaViewModel(servicio: servicio, tipo: .diagnostico) }
                        .buttonStyle(EstiloBotonSecundario())
                        .accessibilityIdentifier("botonRepetirDiagnostico")
                    Button("Cambiar avatar") { mostrarPerfil = true }
                        .buttonStyle(EstiloBotonSecundario())
                        .accessibilityIdentifier("botonCambiarAvatar")
                    NavigationLink { PantallaCreditos() } label: { Text("Créditos") }
                        .buttonStyle(EstiloBotonSecundario())
                        .accessibilityIdentifier("botonCreditos")
                }
            }
            .padding(Espacio.l)
        }
        .tint(Paleta.contorno)
        .background(Paleta.fondo.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $ronda) { r in
            PantallaRonda(modelo: r, ayudasDePrueba: entorno.opciones.ayudasDePrueba) { ronda = nil }
        }
        .sheet(isPresented: $mostrarPerfil) {
            PantallaPerfil(avatar: try? servicio.repositorio.perfil().avatar) { id in try? servicio.elegirAvatar(id) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaAjustes")
    }

    private func grupo<C: View>(_ titulo: String, @ViewBuilder _ contenido: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            Text(titulo).font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            contenido()
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .contornoTinta(radio: Radio.tarjeta)
        .foregroundStyle(Paleta.textoPrincipal)
    }
}

/// Créditos: el texto de `Resources/Creditos.md` (copia de CREDITOS.md; un test comprueba que coinciden).
struct PantallaCreditos: View {
    nonisolated static var texto: String {
        guard let url = Bundle.main.url(forResource: "Creditos", withExtension: "md"),
              let t = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return t
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.m) {
                ForEach(Array(Self.texto.split(separator: "\n").enumerated()), id: \.offset) { _, linea in
                    let l = String(linea)
                    if l.hasPrefix("# ") {
                        Text(l.dropFirst(2)).font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                    } else {
                        Text((try? AttributedString(markdown: l.hasPrefix("- ") ? "• " + l.dropFirst(2) : l)) ?? AttributedString(l))
                            .foregroundStyle(Paleta.textoPrincipal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .navigationTitle("Créditos")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaCreditos")
    }
}
