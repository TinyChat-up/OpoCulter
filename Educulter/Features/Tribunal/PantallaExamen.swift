import SwiftUI

/// Sala de examen (05I §3): aspecto de cuadernillo (papel y serif), cuenta atrás, mapa de preguntas,
/// «Marcar para revisar», borrador por pregunta y «Entregar». Sin personajes, sin XP y sin colores de
/// acierto: ningún feedback hasta entregar.
struct PantallaExamen: View {
    @Bindable var modelo: ModeloExamen
    let cerrar: () -> Void
    /// Hoja abierta al entrar (capturas): «mapa» o «borrador».
    var hojaInicial: String?
    @Environment(\.scenePhase) private var fase
    @State private var verMapa = false
    @State private var verBorrador = false
    @State private var confirmarEntrega = false
    @State private var verTexto = false
    @State private var corrigiendo = false

    private let unidades = ["€", "m", "cm", "mm", "km", "m²", "cm²", "dm²", "ha", "m³", "dm³", "cm³", "l", "ml", "kg", "g", "h", "min", "%"]

    var body: some View {
        Group {
            if modelo.entregado || corrigiendo {
                PantallaCorreccionExamen(modelo: modelo, cerrar: cerrar)
            } else {
                sala
            }
        }
        .onChange(of: fase) { _, nueva in if nueva != .active { modelo.pausar() } }
        .onAppear {
            if hojaInicial == "mapa" { verMapa = true }
            if hojaInicial == "borrador" { verBorrador = true }
        }
    }

    private var sala: some View {
        VStack(spacing: 0) {
            cabecera
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    pregunta
                    respuestaVista
                }
                .padding(Espacio.l)
            }
            .background(Paleta.superficie)
            pie
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .sheet(isPresented: $verMapa) { mapa }
        .sheet(isPresented: $verBorrador) {
            HojaBorrador(enunciado: modelo.enunciado(modelo.actual), dibujo: $modelo.borrador)
        }
        .sheet(isPresented: $verTexto) { textoBase }
        .confirmationDialog("¿Entregar el examen?", isPresented: $confirmarEntrega, titleVisibility: .visible) {
            Button("Entregar") { modelo.entregar() }
            Button("Seguir con el examen", role: .cancel) {}
        } message: {
            Text("Quedan \(modelo.sesion.sinResponder) preguntas sin responder y \(modelo.sesion.marcadas.count) marcadas para revisar.")
        }
    }

    // MARK: Cabecera

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            HStack {
                Button { modelo.pausar(); cerrar() } label: { Image(systemName: "xmark").font(.headline) }
                    .frame(minWidth: Medidas.tactilMinimo, minHeight: Medidas.tactilMinimo)
                    .accessibilityLabel("Salir (el examen se guarda)")
                    .accessibilityIdentifier("botonSalirExamen")
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { contexto in
                    reloj.onChange(of: contexto.date) { _, ahora in modelo.tic(ahora) }
                }
                Spacer()
                Button { verMapa = true } label: { Label("Mapa", systemImage: "square.grid.3x3") }
                    .frame(minHeight: Medidas.tactilMinimo)
                    .accessibilityIdentifier("botonMapa")
            }
            Text(modelo.examen?.cita ?? "Simulacro original con el formato de la prueba A1 (no es un examen oficial).")
                .font(.caption2).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("citaExamen")
            if let aviso = modelo.aviso {
                Label(aviso, systemImage: "clock").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.recompensaTexto)
                    .onTapGesture { modelo.quitarAviso() }
                    .accessibilityIdentifier("avisoTiempo")
            }
        }
        .padding(.horizontal, Espacio.l)
        .padding(.vertical, Espacio.s)
        .foregroundStyle(Paleta.textoPrincipal)
    }

    private var reloj: some View {
        let s = Int(modelo.sesion.restante)
        return Text(String(format: "%d:%02d", s / 60, s % 60))
            .font(.numerica(.title3, peso: .semibold))
            .foregroundStyle(Paleta.textoPrincipal)
            .accessibilityLabel("Quedan \(s / 60) minutos y \(s % 60) segundos")
            .accessibilityIdentifier("cuentaAtras")
    }

    // MARK: Pregunta

    @ViewBuilder private var pregunta: some View {
        let i = modelo.actual
        HStack {
            Text("Pregunta \(modelo.codigo(i)) · \(i + 1) de \(modelo.total)")
                .font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            Spacer()
            if modelo.sesion.marcadas.contains(i) {
                Label("Marcada", systemImage: "flag.fill").font(.footnote).foregroundStyle(Paleta.recompensaTexto)
            }
        }
        if let o = modelo.oficial(i) {
            Text(o.enunciadoVisible)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Paleta.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("enunciadoExamen")
            if o.esAnulada {
                Label("Pregunta anulada por el tribunal: se muestra, pero no puntúa.", systemImage: "nosign")
                    .font(.footnote).foregroundStyle(Paleta.textoSecundario)
            }
            if let figura = o.figura { remision(texto: "Figura: \(figura)", pagina: o.paginaFigura, titulo: "Ver la figura en el cuadernillo oficial") }
            if o.citaProtegida { remision(texto: "El pasaje citado es de un texto protegido por derechos de autor: no se reproduce.", pagina: nil, titulo: "Consultar el cuadernillo oficial") }
            if o.area == "LEN", modelo.examen != nil {
                Button { verTexto = true } label: { Label("Texto del examen", systemImage: "doc.text") }
                    .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonTextoExamen")
            }
        } else if let item = modelo.item(i) {
            Text(item.enunciado)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Paleta.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("enunciadoExamen")
        }
    }

    private func remision(texto: String, pagina: Int?, titulo: String) -> some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            Text(texto).font(.footnote).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
            if let fuente = modelo.examen?.fuente, let url = URL(string: fuente) {
                Link(pagina.map { "\(titulo), página \($0)" } ?? titulo, destination: url).font(.footnote.weight(.semibold))
            }
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.ficha))
        .accessibilityElement(children: .combine)
    }

    // MARK: Respuesta

    @ViewBuilder private var respuestaVista: some View {
        let i = modelo.actual
        if let item = modelo.item(i) {
            // Simulacro: la mecánica del ítem, sin corrección hasta entregar.
            VistaMecanica(contexto: ContextoMecanica(item: item, acento: Paleta.primario, resultado: nil),
                          respuesta: Binding(get: { modelo.respuestaItem }, set: { modelo.respuestaItem = $0 }))
        } else if let o = modelo.oficial(i), !o.esAnulada {
            VStack(alignment: .leading, spacing: Espacio.m) {
                if o.area == "MAT" {
                    Text("Resultado").font(.subheadline.weight(.semibold))
                    Text(modelo.respuesta.valor.isEmpty ? "—" : modelo.respuesta.valor)
                        .font(.resultado(.title2)).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Espacio.m).background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.ficha))
                        .accessibilityIdentifier("valorExamen")
                    TecladoNumerico(texto: Binding(get: { modelo.respuesta.valor }, set: { var r = modelo.respuesta; r.valor = $0; modelo.respuesta = r }),
                                    acento: Paleta.primario, maximo: 16)
                    Text("Unidad").font(.subheadline.weight(.semibold))
                    DisposicionFlujo(espacioH: Espacio.s, espacioV: Espacio.s) {
                        ForEach(["sin unidad"] + unidades, id: \.self) { u in
                            let valor: String? = u == "sin unidad" ? nil : u
                            Button { var r = modelo.respuesta; r.unidad = valor; modelo.respuesta = r } label: {
                                Ficha(texto: u, estado: modelo.respuesta.unidad == valor && !modelo.respuesta.valor.isEmpty ? .seleccionada : .normal, acento: Paleta.primario)
                            }
                            .buttonStyle(.pulsable)
                        }
                    }
                } else {
                    Text("Respuesta breve").font(.subheadline.weight(.semibold))
                    TextField("Escribe aquí (o en papel)", text: Binding(get: { modelo.respuesta.texto }, set: { var r = modelo.respuesta; r.texto = $0; modelo.respuesta = r }),
                              axis: .vertical)
                        .lineLimit(3...8)
                        .font(.system(.body, design: .serif))
                        .padding(Espacio.m)
                        .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.ficha))
                        .accessibilityIdentifier("campoRespuesta")
                }
                Toggle("Lo he respondido en papel", isOn: Binding(get: { modelo.respuesta.enPapel }, set: { var r = modelo.respuesta; r.enPapel = $0; modelo.respuesta = r }))
                    .accessibilityIdentifier("enPapel")
            }
            .foregroundStyle(Paleta.textoPrincipal)
        }
    }

    // MARK: Pie

    private var pie: some View {
        VStack(spacing: Espacio.s) {
            HStack(spacing: Espacio.s) {
                Button { modelo.ir(a: modelo.actual - 1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(EstiloBotonSecundario()).disabled(modelo.actual == 0).accessibilityLabel("Anterior")
                Button { modelo.alternarMarca() } label: {
                    Label(modelo.sesion.marcadas.contains(modelo.actual) ? "Desmarcar" : "Marcar para revisar", systemImage: "flag")
                }
                .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonMarcar")
                Button { verBorrador = true } label: { Label("Borrador", systemImage: "pencil.and.scribble") }
                    .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonBorrador")
                Button { modelo.ir(a: modelo.actual + 1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(EstiloBotonSecundario()).disabled(modelo.actual + 1 >= modelo.total).accessibilityLabel("Siguiente")
            }
            BotonPrincipal(titulo: "Entregar", icono: "tray.and.arrow.up", acento: Paleta.primario) { confirmarEntrega = true }
                .accessibilityIdentifier("botonEntregar")
        }
        .padding(Espacio.l)
        .background(Paleta.fondo)
    }

    // MARK: Mapa y texto

    private var mapa: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.m) {
                    HStack(spacing: Espacio.l) {
                        leyenda("Sin responder", Paleta.superficie)
                        leyenda("Respondida", Paleta.primario.opacity(0.25))
                        Label("Marcada", systemImage: "flag.fill").font(.caption).foregroundStyle(Paleta.recompensaTexto)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espacio.s), count: 5), spacing: Espacio.s) {
                        ForEach(0..<modelo.total, id: \.self) { i in
                            Button { modelo.ir(a: i); verMapa = false } label: {
                                VStack(spacing: 2) {
                                    Text(modelo.codigo(i)).font(.subheadline.weight(.semibold))
                                    Image(systemName: modelo.sesion.marcadas.contains(i) ? "flag.fill" : (modelo.sesion.respondida(i) ? "checkmark" : "circle"))
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(modelo.sesion.respondida(i) ? Paleta.primario.opacity(0.25) : Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha))
                                .overlay(RoundedRectangle(cornerRadius: Radio.ficha).strokeBorder(i == modelo.actual ? Paleta.contorno : Paleta.borde, lineWidth: i == modelo.actual ? 2 : 1))
                            }
                            .foregroundStyle(Paleta.textoPrincipal)
                            .accessibilityLabel("Pregunta \(modelo.codigo(i)): \(modelo.sesion.respondida(i) ? "respondida" : "sin responder")\(modelo.sesion.marcadas.contains(i) ? ", marcada para revisar" : "")")
                            .accessibilityIdentifier("mapa_\(i)")
                        }
                    }
                }
                .padding(Espacio.l)
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationTitle("Mapa de preguntas")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func leyenda(_ t: String, _ c: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(c).overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Paleta.borde)).frame(width: 14, height: 14)
            Text(t).font(.caption)
        }
    }

    private var textoBase: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.m) {
                    if let e = modelo.examen {
                        Text("\(e.textoBase.obra) · \(e.textoBase.autor)").font(.subheadline.weight(.semibold))
                        if e.textoBase.protegido || e.textoBase.texto == nil {
                            Text("El texto base está protegido por derechos de autor y no se reproduce. Consúltalo en el cuadernillo oficial.")
                                .font(.body)
                            if let url = URL(string: e.fuente) { Link("Abrir el cuadernillo oficial", destination: url) }
                        } else {
                            Text(e.textoBase.texto ?? "").font(.system(.body, design: .serif)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .foregroundStyle(Paleta.textoPrincipal)
                .padding(Espacio.l)
            }
            .background(Paleta.superficie.ignoresSafeArea())
            .navigationTitle("Texto del examen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
