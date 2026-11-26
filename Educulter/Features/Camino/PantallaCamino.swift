import SwiftUI

/// Camino: una ruta vertical por área con las competencias agrupadas por bloque, su estado real y
/// el Reto al final de cada bloque con contenido.
struct PantallaCamino: View {
    let servicio: ServicioSesion
    @Environment(EntornoApp.self) private var entorno
    @State private var area = "LEN"
    @State private var tramos: [TramoCamino] = []
    @State private var nodoAbierto: NodoCamino?
    @State private var ronda: RondaViewModel?
    @State private var pendiente: TipoRonda?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text("Camino").font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    Picker("Área", selection: $area) {
                        Text("Lengua").tag("LEN")
                        Text("Matemáticas").tag("MAT")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("areaCamino")
                    ForEach(tramos) { tramo in vistaTramo(tramo) }
                }
                .padding(Espacio.l)
            }
            .contentMargins(.bottom, Espacio.xxl * 2, for: .scrollContent)
            .background(Paleta.fondo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear(perform: cargar)
        .onChange(of: area) { _, _ in cargar() }
        .sheet(item: $nodoAbierto, onDismiss: {
            if let tipo = pendiente { pendiente = nil; ronda = RondaViewModel(servicio: servicio, tipo: tipo) }
        }) { nodo in
            HojaNodo(nodo: nodo, servicio: servicio, recomendada: recomendada) { tipo in pendiente = tipo; nodoAbierto = nil }
        }
        .fullScreenCover(item: $ronda) { r in
            PantallaRonda(modelo: r, ayudasDePrueba: entorno.opciones.ayudasDePrueba) { ronda = nil; cargar() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaCamino")
    }

    private var recomendada: String? {
        tramos.flatMap(\.nodos).first { $0.estado == .enCurso && $0.esEnCurso }?.competencia.nombre
            ?? tramos.flatMap(\.nodos).first { $0.estado != .sinContenido && $0.estado != .dominada }?.competencia.nombre
    }

    private func cargar() {
        tramos = (try? servicio.camino(area: area)) ?? []
    }

    private func vistaTramo(_ tramo: TramoCamino) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Espacio.s) {
                Image(systemName: SimboloBloque.de(bloque: tramo.bloque.id)).font(.headline).accessibilityHidden(true)
                Text(tramo.bloque.nombre).font(.exhibicion(.title3))
                Spacer()
                if tramo.medallaObtenida {
                    Image(systemName: "medal.fill").foregroundStyle(Paleta.recompensaTexto).accessibilityLabel("Medalla obtenida")
                }
            }
            .foregroundStyle(Paleta.textoPrincipal)
            .accessibilityAddTraits(.isHeader)
            .padding(.bottom, Espacio.s)
            ForEach(Array(tramo.nodos.enumerated()), id: \.element.id) { i, nodo in
                filaNodo(nodo, ultimo: i == tramo.nodos.count - 1 && !tramo.retoDisponible)
            }
            if tramo.retoDisponible {
                Button {
                    ronda = RondaViewModel(servicio: servicio, tipo: .retoBloque(tramo.bloque.id))
                } label: {
                    HStack(spacing: Espacio.m) {
                        Image(systemName: tramo.medallaObtenida ? "medal.fill" : "flag.checkered")
                            .font(.title3.weight(.semibold))
                            .frame(width: 56, height: 56)
                            .superficiePulsable(Paleta.recompensa, radio: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reto de bloque").font(.headline)
                            Text("8 ítems sin ayudas, dificultad 4–5. Con 6 aciertos, medalla.").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Paleta.textoPrincipal)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pulsable)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Reto de bloque: \(tramo.bloque.nombre)")
                .accessibilityValue(tramo.medallaObtenida ? "medalla obtenida" : "sin medalla")
                .accessibilityIdentifier("reto_\(tramo.bloque.id)")
            }
        }
        .padding(.bottom, Espacio.l)
    }

    private func filaNodo(_ nodo: NodoCamino, ultimo: Bool) -> some View {
        let acento = Paleta.acento(area: area)
        let sinContenido = nodo.estado == .sinContenido
        return Button {
            nodoAbierto = nodo
        } label: {
            HStack(alignment: .top, spacing: Espacio.m) {
                VStack(spacing: 0) {
                    ZStack {
                        if sinContenido {
                            Circle().strokeBorder(Paleta.borde, style: StrokeStyle(lineWidth: Trazo.grueso, dash: [6, 4]))
                        } else {
                            Circle().fill(nodo.estado == .dominada ? acento : Paleta.superficie)
                                .overlay(Circle().strokeBorder(Paleta.borde, lineWidth: Trazo.fino))
                            if nodo.estado == .enCurso {
                                AnilloDominio(fraccion: max(nodo.dominio, 0.06), acento: acento, grosor: 5).padding(7)
                            }
                        }
                        Image(systemName: icono(nodo))
                            .font(.headline)
                            .foregroundStyle(sinContenido ? Paleta.textoSecundario : (nodo.estado == .dominada ? Paleta.textoSobre(acento) : Paleta.textoPrincipal))
                    }
                    .frame(width: 56, height: 56)
                    if !ultimo {
                        Rectangle().fill(Paleta.borde).frame(width: 3, height: 22)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(nodo.competencia.nombre).font(.body.weight(.semibold))
                        .foregroundStyle(sinContenido ? Paleta.textoSecundario : (nodo.estado == .dominada ? Paleta.textoSobre(acento) : Paleta.textoPrincipal))
                    Text(detalle(nodo)).font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                }
                .padding(.top, Espacio.s)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pulsable)
        .disabled(sinContenido)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nodo.competencia.nombre)
        .accessibilityValue(detalle(nodo))
        .accessibilityAddTraits(sinContenido ? [] : .isButton)
        .accessibilityIdentifier("nodo_\(nodo.id)")
    }

    private func icono(_ n: NodoCamino) -> String {
        switch n.estado {
        case .sinContenido: "hourglass"
        case .dominada: "checkmark"
        default: n.bloqueadoPorOrden ? "lock.fill" : SimboloBloque.de(competencia: n.id)
        }
    }

    private func detalle(_ n: NodoCamino) -> String {
        switch n.estado {
        case .sinContenido: "En preparación"
        case .dominada: "Dominada"
        case .enCurso: "\(Peldano.nombre(n.peldano)) · peldaño \(n.peldano) de 5\(n.esEnCurso ? " · en curso" : "")"
        case .disponible: n.bloqueadoPorOrden ? "Más adelante · se puede abrir con una prueba de nivel" : "Disponible"
        }
    }
}

/// Hoja de un nodo: estado real, teoría, Practicar y prueba de nivel.
struct HojaNodo: View {
    let nodo: NodoCamino
    let servicio: ServicioSesion
    let recomendada: String?
    let lanzar: (TipoRonda) -> Void


    var body: some View {
        let estado = (try? servicio.estado(competencia: nodo.id)) ?? EstadoCompetencia(competenciaId: nodo.id)
        let teoria = servicio.banco.teoria(competencia: nodo.id)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text(nodo.competencia.nombre).font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    TarjetaSuperficie {
                        VStack(alignment: .leading, spacing: Espacio.s) {
                            fila("Peldaño", "\(estado.escalera.peldano) de 5 · \(Peldano.nombre(estado.escalera.peldano))")
                            fila("Caja de repaso", estado.leitner.map { "\($0.caja) de 5" } ?? "Aún sin repasos")
                            fila("Próximo repaso", estado.leitner.map { $0.proximoRepaso.fecha(calendario: servicio.calendario).formatted(.dateTime.day().month(.wide)) } ?? "Sin repasos todavía")
                        }
                    }
                    .accessibilityIdentifier("estadoNodo")
                    if nodo.bloqueadoPorOrden {
                        Label {
                            Text("Te recomendamos antes \(recomendada.map { "«\($0)»" } ?? "las anteriores"), pero puedes abrirla ya con una prueba de nivel.")
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: { Image(systemName: "lock.fill") }
                        .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    }
                    if nodo.pruebaNivelDisponible {
                        VStack(alignment: .leading, spacing: Espacio.s) {
                            Button {
                                lanzar(.pruebaNivel(nodo.id))
                            } label: {
                                Label("Prueba de nivel", systemImage: "bolt.fill")
                            }
                            .buttonStyle(EstiloBotonPrincipal(acento: Paleta.recompensa))
                            .accessibilityIdentifier("botonPruebaNivel")
                            Text("5 ítems del peldaño 3. Con 4 aciertos superas los peldaños 1 y 2.")
                                .font(.footnote).foregroundStyle(Paleta.textoSecundario)
                        }
                    }
                    // Con prueba de nivel, Practicar pasa a secundario. Dos ramas con su estilo concreto: un
                    // estilo envuelto en otro no recibe su `@Environment` (`isEnabled`).
                    if nodo.pruebaNivelDisponible {
                        botonPracticar.buttonStyle(EstiloBotonSecundario())
                    } else {
                        botonPracticar.buttonStyle(EstiloBotonPrincipal(acento: Paleta.acento(competencia: nodo.id)))
                    }
                    ForEach(teoria) { t in
                        VistaTarjetaTeoria(tarjeta: t, acento: Paleta.tinta(competencia: t.competencia))
                    }
                }
                .padding(Espacio.l)
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hojaNodo")
    }

    private var botonPracticar: some View {
        Button {
            lanzar(.competencia(nodo.id))
        } label: {
            Label("Practicar", systemImage: "play.fill")
        }
        .accessibilityIdentifier("botonPracticar")
    }

    private func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).foregroundStyle(Paleta.textoSecundario)
            Spacer()
            Text(v).font(.body.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal).multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
