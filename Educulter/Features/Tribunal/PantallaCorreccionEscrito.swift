import SwiftUI

/// Corrección e informe del simulacro escrito (05J §2): por pregunta, la respuesta (en la app), la
/// solución razonada con sus alternativas válidas y los tres criterios con sus puntos para marcar.
/// Lengua /5, Matemáticas /5, total /10 (la muestra, /2) y la penalización ortográfica aparte. Si
/// queda alguna pregunta sin corregir: «Revisión pendiente», nunca un 0. Sin clasificaciones,
/// percentiles ni «nota oficial».
struct PantallaCorreccionEscrito: View {
    @Bindable var modelo: ModeloEscrito
    let cerrar: () -> Void
    /// Abre desplazada hasta el informe (capturas).
    var alInforme = false
    @Environment(EntornoApp.self) private var entorno
    @State private var ronda: RondaViewModel?

    var body: some View {
        NavigationStack {
            ScrollViewReader { desplazador in
                ScrollView {
                    VStack(alignment: .leading, spacing: Espacio.l) {
                        cabecera
                        ForEach(modelo.preguntas) { p in pregunta(p) }
                        ortografia
                        informe.id("informe")
                    }
                    .foregroundStyle(Paleta.textoPrincipal)
                    .padding(Espacio.l)
                }
                .onAppear { if alInforme { desplazador.scrollTo("informe", anchor: .top) } }
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationTitle("Corrección")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar", action: cerrar).accessibilityIdentifier("botonCerrarCorreccion") } }
        }
        .fullScreenCover(item: $ronda) { r in
            PantallaRonda(modelo: r, ayudasDePrueba: entorno.opciones.ayudasDePrueba) { ronda = nil }
        }
    }

    // MARK: Cabecera

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            Text(modelo.simulacro.etiqueta.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            Text(modelo.simulacro.entrada.titulo).font(.exhibicion(.title2)).accessibilityAddTraits(.isHeader)
            Text(detalleIntento).font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            Text("Marca los criterios que cumple cada respuesta después de leer la solución. La app no compara textos.")
                .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var detalleIntento: String {
        let i = modelo.intento
        let formato = i.formato == .app ? "Hecho en la app" : "Hecho en papel"
        let duracion = i.duracionReal.map { "\(max(1, Int((Double($0) / 60).rounded(.up)))) min" } ?? "desconocida"
        let fecha = (i.entrega ?? modelo.servicio.reloj.ahora).formatted(date: .abbreviated, time: .shortened)
        return "\(formato) · duración \(duracion)\(i.entregaAutomatica ? " (entregado al acabar el tiempo)" : "") · \(fecha)"
    }

    // MARK: Pregunta

    private func pregunta(_ p: SimulacroEscrito.Pregunta) -> some View {
        let criterios = modelo.criterios(p.id)
        let puntos = CorrectorEscrito.puntos(p, criterios: criterios)
        return TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.s) {
                HStack {
                    Text(p.id).font(.headline)
                    Spacer()
                    Text(puntos.map { "\(CorrectorEscrito.texto($0)) / \(CorrectorEscrito.texto(p.maximo))" } ?? "Sin corregir")
                        .font(.numerica(.subheadline)).foregroundStyle(puntos == nil ? Paleta.textoSecundario : Paleta.textoPrincipal)
                }
                Text(p.enunciado).font(.system(.body, design: .serif)).fixedSize(horizontal: false, vertical: true)
                if modelo.intento.formato == .app {
                    bloque("Tu respuesta", modelo.intento.respuestas[p.id].flatMap { $0.isEmpty ? nil : $0 } ?? "Sin responder")
                }
                bloque("Solución razonada y alternativas válidas", p.solucion)
                Text("Criterios").font(.subheadline.weight(.semibold))
                ForEach(Array(p.rubrica.enumerated()), id: \.offset) { n, c in
                    Toggle(isOn: Binding(get: { criterios?[n] ?? false }, set: { modelo.marcarCriterio(p.id, n, $0) })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.criterio).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                            Text("\(CorrectorEscrito.texto(c.puntos)) puntos").font(.caption).foregroundStyle(Paleta.textoSecundario)
                        }
                    }
                    .toggleStyle(CasillaCriterio())
                    .accessibilityIdentifier("criterio_\(p.id)_\(n)")
                }
                if criterios == nil {
                    Button("No cumple ninguno") { modelo.ningunCriterio(p.id) }
                        .font(.footnote.weight(.semibold))
                        .frame(minHeight: Medidas.tactilMinimo)
                        .accessibilityIdentifier("ninguno_\(p.id)")
                }
            }
        }
    }

    private func bloque(_ titulo: String, _ texto: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titulo).font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            Text(texto).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espacio.m)
        .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.celda))
    }

    // MARK: Ortografía

    private var ortografia: some View {
        TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.s) {
                Text("Ortografía").font(.headline)
                Text(ResultadoEscrito.etiquetaPenalizacion).font(.caption).foregroundStyle(Paleta.textoSecundario)
                Stepper("Palabras mal escritas: \(modelo.faltasPalabras)", value: $modelo.faltasPalabras, in: 0...99)
                    .accessibilityIdentifier("faltasPalabras")
                Stepper("Tildes: \(modelo.faltasTildes)", value: $modelo.faltasTildes, in: 0...99)
                    .accessibilityIdentifier("faltasTildes")
                Toggle("Aplicar penalización", isOn: $modelo.aplicarPenalizacion).accessibilityIdentifier("aplicarPenalizacion")
                Text("−0,50 por palabra y −0,25 por tilde; cada palabra cuenta una vez.").font(.caption).foregroundStyle(Paleta.textoSecundario)
            }
            .font(.subheadline)
        }
    }

    // MARK: Informe

    @ViewBuilder private var informe: some View {
        let r = modelo.resultado
        TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.m) {
                Text("Puntuación del simulacro").font(.exhibicion(.title3)).accessibilityAddTraits(.isHeader)
                ForEach(["LEN", "MAT"], id: \.self) { a in
                    if let maximo = r.maximoArea[a] {
                        fila(a == "LEN" ? "Lengua" : "Matemáticas", valor: r.areas[a] ?? nil, maximo: maximo)
                    }
                }
                Divider()
                if let total = r.total {
                    fila("Total", valor: total, maximo: r.maximo, destacada: true)
                    if r.penalizacion > 0 {
                        fila("Penalización ortográfica", texto: "−\(CorrectorEscrito.texto(r.penalizacion))")
                        if r.aplicarPenalizacion, let con = r.totalConPenalizacion {
                            fila("Con la penalización", valor: con, maximo: r.maximo, destacada: true)
                        }
                    }
                } else {
                    Label("Revisión pendiente: faltan \(r.pendientes.count) preguntas por corregir (\(r.pendientes.joined(separator: ", "))).",
                          systemImage: "hourglass")
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("revisionPendiente")
                }
                Text("Puntuación orientativa con los criterios de este simulacro original. No es una nota oficial.")
                    .font(.caption).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            }
        }
        if !r.revisionPendiente { prioridades }
        let sugerencia = modelo.sugerencia
        if !sugerencia.isEmpty {
            Label(sugerencia, systemImage: "calendar").font(.subheadline).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sugerenciaSimulacro")
        }
    }

    @ViewBuilder private var prioridades: some View {
        let lista = modelo.prioridades
        if !lista.isEmpty {
            VStack(alignment: .leading, spacing: Espacio.s) {
                Text("Prioridades").font(.headline).accessibilityAddTraits(.isHeader)
                ForEach(lista, id: \.competencia) { p in
                    HStack(alignment: .center, spacing: Espacio.m) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.nombre).font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                            Text(p.practicable ? p.bloque : "Repásala en el bloque «\(p.bloque)»").font(.caption).foregroundStyle(Paleta.textoSecundario)
                        }
                        Spacer(minLength: 0)
                        if p.practicable {
                            Button("Practicar") { ronda = RondaViewModel(servicio: modelo.servicio, tipo: .competencia(p.competencia)) }
                                .buttonStyle(EstiloBotonSecundario()).frame(maxWidth: 140)
                                .accessibilityIdentifier("practicar_\(p.competencia)")
                        }
                    }
                }
            }
        }
    }

    private func fila(_ titulo: String, valor: Int?, maximo: Int, destacada: Bool = false) -> some View {
        fila(titulo, texto: valor.map { "\(CorrectorEscrito.texto($0)) / \(CorrectorEscrito.texto(maximo).replacingOccurrences(of: ",00", with: ""))" } ?? "Revisión pendiente",
             destacada: destacada)
    }

    private func fila(_ titulo: String, texto: String, destacada: Bool = false) -> some View {
        HStack {
            Text(titulo).font(destacada ? .headline : .subheadline)
            Spacer()
            Text(texto).font(.numerica(destacada ? .title3 : .subheadline))
        }
        .accessibilityElement(children: .combine)
    }
}

/// Casilla de criterio: cuadro con marca, todo el renglón pulsable.
struct CasillaCriterio: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .top, spacing: Espacio.m) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(configuration.isOn ? Paleta.primario : Paleta.textoSecundario)
                    .accessibilityHidden(true)
                configuration.label
                Spacer(minLength: 0)
            }
            .frame(minHeight: Medidas.tactilMinimo)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Paleta.textoPrincipal)
        .accessibilityAddTraits(configuration.isOn ? [.isSelected] : [])
    }
}
