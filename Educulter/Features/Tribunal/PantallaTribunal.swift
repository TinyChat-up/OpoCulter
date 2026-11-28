import SwiftUI

/// Entrada del Tribunal (05J §2): el examen escrito, separado de los juegos. Arriba, una tarjeta
/// principal (primero la muestra; luego el siguiente simulacro sin hacer) con «Continuar» si hay un
/// intento activo o, si no, «Hacer en la app» e «Imprimir PDF» al mismo nivel. Debajo, los
/// resultados anteriores y los bloques «Simulacros originales», «Convocatorias anteriores» y «Por
/// bloques». Sin anuncios. Versión gratuita (fase 06 §1.2): solo la muestra SIM.DEMO.01; lo demás
/// se ve con candado y, al tocarlo, abre la hoja de bloqueo con «Ver Premium».
struct PantallaTribunal: View {
    let servicio: ServicioSesion
    @Environment(EntornoApp.self) private var entorno
    @State private var principal: SimulacroOriginal?
    @State private var activo: IntentoEscrito?
    @State private var entregados: [IntentoEscrito] = []
    @State private var oficialEnCurso: SesionExamen?
    @State private var escrito: ModeloEscrito?
    @State private var examen: ModeloExamen?
    @State private var pdf: SimulacroOriginal?
    @State private var ronda: RondaViewModel?
    @State private var error: String?
    @State private var bloqueo: MotivoBloqueo?

    private var acceso: ServicioAcceso { entorno.acceso }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text("Tribunal").font(.exhibicion(.largeTitle)).accessibilityAddTraits(.isHeader)
                    Text("El examen escrito de la prueba A1, aparte de los juegos: en la app o impreso en papel, con su tiempo y corregido con criterios.")
                        .font(.subheadline).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                    tarjetaPrincipal
                    if let oficialEnCurso { tarjetaOficialEnCurso(oficialEnCurso) }
                    if let error { Text(error).font(.footnote).foregroundStyle(Paleta.fallo) }
                    resultados
                    seccion("Simulacros originales") {
                        ForEach(servicio.originales) { s in
                            let filaSimulacro = fila(s.entrada.titulo, detalle: "\(s.etiqueta) · \(resumen(s))", icono: s.entrada.esMuestra ? "gift" : "doc.text",
                                                     estado: entregados.contains { $0.simulacro == s.id } ? "Hecho" : nil,
                                                     bloqueada: acceso.acceso(s.entrada) != .permitido)
                            Group {
                                if acceso.acceso(s.entrada) == .permitido {
                                    NavigationLink { fichaSimulacro(s) } label: { filaSimulacro }
                                } else {
                                    Button { bloqueo = .simulacro } label: { filaSimulacro }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("simulacro_\(s.id)")
                        }
                    }
                    seccion("Convocatorias anteriores") {
                        ForEach(convocatorias) { e in
                            let libre = acceso.permitido(.convocatoriasAnteriores)
                            let filaConvocatoria = fila(e.nombre, detalle: "Reproducción literal · Comunidad de Madrid", icono: "building.columns",
                                                        estado: e.completo ? "Modo examen" : "Solo repaso", bloqueada: !libre)
                            Group {
                                if libre {
                                    NavigationLink { PantallaConvocatoria(examen: e, empezar: { empezarOficial(e) }, bloqueado: oficialEnCurso != nil) } label: { filaConvocatoria }
                                } else {
                                    Button { bloqueo = .convocatorias } label: { filaConvocatoria }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("convocatoria_\(e.id)")
                        }
                    }
                    seccion("Por bloques") {
                        Text("Práctica de 12–20 minutos con ítems de juego, explicación y pistas. Su puntuación no se compara con la del examen.")
                            .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                        ForEach([("LEN", "Bloque de Lengua", "textformat"), ("MAT", "Bloque de Matemáticas", "function")], id: \.0) { a in
                            Button { empezarBloque(a.0) } label: {
                                fila(a.1, detalle: "Unas 10 preguntas según el plano del examen", icono: a.2, estado: nil, bloqueada: !acceso.permitido(.porBloques))
                            }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("bloque_\(a.0)")
                        }
                    }
                }
                .foregroundStyle(Paleta.textoPrincipal)
                .padding(Espacio.l)
            }
            .contentMargins(.bottom, Espacio.xxl * 2, for: .scrollContent)
            .background(Paleta.fondo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: cargar)
        }
        .fullScreenCover(item: $escrito, onDismiss: cargar) { m in PantallaEscrito(modelo: m) { escrito = nil } }
        .fullScreenCover(item: $examen, onDismiss: cargar) { m in PantallaExamen(modelo: m) { examen = nil } }
        .fullScreenCover(item: $ronda, onDismiss: cargar) { r in
            PantallaRonda(modelo: r, ayudasDePrueba: entorno.opciones.ayudasDePrueba, enTribunal: true) { ronda = nil }
        }
        .sheet(item: $bloqueo) { m in HojaBloqueoPremium(motivo: m) }
        .sheet(item: $pdf) { s in
            HojaPDF(simulacro: s, empezarEnPapel: { pdf = nil; empezar(s, .papel) }, corregirEnPapel: { pdf = nil; corregirPapel(s) })
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaTribunal")
    }

    private var convocatorias: [ExamenOficial] {
        servicio.banco.tribunal.examenes.sorted { ($0.completo ? 0 : 1, -$0.anio, $0.convocatoria) < ($1.completo ? 0 : 1, -$1.anio, $1.convocatoria) }
    }

    private func cargar() {
        activo = try? servicio.intentoActivo()
        principal = activo.flatMap { servicio.banco.tribunal.original($0.simulacro) } ?? (try? servicio.simulacroPrincipal())
        entregados = (try? servicio.intentosEntregados()) ?? []
        oficialEnCurso = try? servicio.examenEnCurso()
    }

    private func resumen(_ s: SimulacroOriginal) -> String {
        "\(s.datos.preguntas.count) preguntas · \(s.entrada.minutos) min"
    }

    // MARK: Acciones

    private func abrir(_ i: IntentoEscrito) {
        guard let s = servicio.banco.tribunal.original(i.simulacro) else { return }
        guard acceso.acceso(s.entrada) == .permitido else { bloqueo = .resultado; return }
        escrito = ModeloEscrito(servicio: servicio, simulacro: s, intento: i)
    }

    private func empezar(_ s: SimulacroOriginal, _ formato: IntentoEscrito.Formato) {
        guard acceso.acceso(s.entrada) == .permitido else { bloqueo = .simulacro; return }
        do { abrir(try servicio.empezarEscrito(s.id, formato: formato)) } catch { self.error = "No se ha podido preparar el simulacro." }
    }

    private func corregirPapel(_ s: SimulacroOriginal) {
        guard acceso.acceso(s.entrada) == .permitido else { bloqueo = .simulacro; return }
        do { abrir(try servicio.corregirEnPapel(s.id)) } catch { self.error = "No se ha podido preparar la corrección." }
    }

    private func imprimir(_ s: SimulacroOriginal) {
        guard acceso.acceso(s.entrada) == .permitido else { bloqueo = .simulacro; return }
        pdf = s
    }

    private func empezarOficial(_ e: ExamenOficial) {
        guard e.completo else { return }
        guard acceso.acceso(.oficial(e.id)) == .permitido else { bloqueo = .convocatorias; return }
        do { examen = ModeloExamen(servicio: servicio, sesion: try servicio.empezarExamen(.oficial(e.id))) } catch { self.error = "No se ha podido preparar el examen." }
    }

    private func empezarBloque(_ area: String) {
        guard acceso.permitido(.porBloques) else { bloqueo = .bloques; return }
        guard let ids = try? servicio.bloquePractica(area: area), !ids.isEmpty else { error = "Aún no hay preguntas aprobadas para este bloque."; return }
        ronda = RondaViewModel(servicio: servicio, tipo: .items(ids))
    }

    // MARK: Tarjeta principal

    @ViewBuilder private var tarjetaPrincipal: some View {
        if let s = principal {
            let permitido = acceso.acceso(s.entrada) == .permitido
            TarjetaSuperficie {
                VStack(alignment: .leading, spacing: Espacio.m) {
                    Text(s.entrada.esMuestra ? "MUESTRA GRATUITA" : s.etiqueta.uppercased())
                        .font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                    Text(s.entrada.titulo).font(.exhibicion(.title2)).fixedSize(horizontal: false, vertical: true)
                    Text("Lengua y Matemáticas · \(s.entrada.minutos) min · \(s.datos.preguntas.count) preguntas")
                        .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    if let a = activo, a.simulacro == s.id {
                        Text(a.formato == .papel ? "En papel · quedan \(a.restante(servicio.reloj.ahora) / 60) min" : "Quedan \(a.restante(servicio.reloj.ahora) / 60) min")
                            .font(.subheadline.weight(.semibold))
                        BotonPrincipal(titulo: "Continuar", icono: "play.fill", acento: Paleta.primario) { abrir(a) }
                            .accessibilityIdentifier("botonContinuar")
                    } else if permitido {
                        botonesFormato(s)
                    } else {
                        botonBloqueado(.simulacro)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("tarjetaPrincipal")
        }
    }

    private func botonesFormato(_ s: SimulacroOriginal) -> some View {
        HStack(spacing: Espacio.s) {
            Button { empezar(s, .app) } label: { Label("Hacer en la app", systemImage: "iphone") }
                .buttonStyle(EstiloBotonSecundario())
                .accessibilityIdentifier("botonHacerApp")
            Button { imprimir(s) } label: { Label("Imprimir PDF", systemImage: "printer") }
                .buttonStyle(EstiloBotonSecundario())
                .accessibilityIdentifier("botonImprimirPDF")
        }
    }

    private func tarjetaOficialEnCurso(_ s: SesionExamen) -> some View {
        Button {
            guard acceso.acceso(s.modo) == .permitido else { bloqueo = .convocatorias; return }
            examen = ModeloExamen(servicio: servicio, sesion: s)
        } label: {
            fila("Continuar: \(s.modo.examenId.flatMap { servicio.banco.tribunal.examen($0)?.nombre } ?? s.modo.nombre)",
                 detalle: "Convocatoria anterior · pregunta \(s.actual + 1) de \(s.preguntas.count)", icono: "play.fill", estado: nil)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("botonContinuarExamen")
    }

    // MARK: Ficha de un simulacro

    private func fichaSimulacro(_ s: SimulacroOriginal) -> some View {
        let permitido = acceso.acceso(s.entrada) == .permitido
        let activoDe = activo?.simulacro == s.id ? activo : nil
        return ScrollView {
            VStack(alignment: .leading, spacing: Espacio.l) {
                Text(s.etiqueta.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                Text(s.entrada.titulo).font(.exhibicion(.title2)).fixedSize(horizontal: false, vertical: true)
                Text("Lengua y Matemáticas · \(resumen(s)) · puntuación sobre \(s.entrada.esMuestra ? 2 : 10)")
                    .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                if let a = activoDe {
                    BotonPrincipal(titulo: "Continuar", icono: "play.fill", acento: Paleta.primario) { abrir(a) }
                } else if permitido {
                    botonesFormato(s)
                    Button("Corregir una prueba hecha en papel") { corregirPapel(s) }
                        .font(.subheadline.weight(.semibold)).frame(minHeight: Medidas.tactilMinimo)
                } else {
                    botonBloqueado(.simulacro)
                }
                let propios = entregados.filter { $0.simulacro == s.id }
                if !propios.isEmpty {
                    Text("Tus intentos").font(.headline)
                    ForEach(propios) { i in filaIntento(i) }
                }
            }
            .foregroundStyle(Paleta.textoPrincipal)
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .navigationTitle(s.entrada.titulo)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Resultados

    @ViewBuilder private var resultados: some View {
        if !entregados.isEmpty {
            seccion("Resultados anteriores") {
                ForEach(entregados.prefix(5)) { i in filaIntento(i) }
            }
        }
    }

    private func filaIntento(_ i: IntentoEscrito) -> some View {
        let s = servicio.banco.tribunal.original(i.simulacro)
        let r = servicio.resultado(i)
        return Button { abrir(i) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s?.entrada.titulo ?? i.simulacro).font(.subheadline.weight(.semibold))
                    Text("\((i.entrega ?? .now).formatted(date: .abbreviated, time: .omitted)) · \(i.formato == .app ? "en la app" : "en papel")")
                        .font(.caption).foregroundStyle(Paleta.textoSecundario)
                }
                Spacer()
                if let r, let total = r.totalConPenalizacion {
                    Text("\(CorrectorEscrito.texto(total)) / \(r.maximo / 100)").font(.numerica(.headline))
                } else {
                    Text("Revisión pendiente").font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                }
            }
            .padding(Espacio.m)
            .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha))
            .contornoTinta(radio: Radio.ficha)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: Piezas

    private func seccion<C: View>(_ titulo: String, @ViewBuilder contenido: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text(titulo).font(.exhibicion(.title3)).accessibilityAddTraits(.isHeader)
            contenido()
        }
    }

    /// «Incluido en Premium» con candado: abre la hoja de bloqueo.
    private func botonBloqueado(_ motivo: MotivoBloqueo) -> some View {
        Button { bloqueo = motivo } label: { Label("Incluido en Premium", systemImage: "lock") }
            .buttonStyle(EstiloBotonSecundario())
            .accessibilityIdentifier("botonIncluidoPremium")
    }

    private func fila(_ titulo: String, detalle: String, icono: String, estado: String?, bloqueada: Bool = false) -> some View {
        HStack(spacing: Espacio.m) {
            Image(systemName: icono).font(.title3).foregroundStyle(Paleta.primario).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(.headline).foregroundStyle(Paleta.textoPrincipal).fixedSize(horizontal: false, vertical: true)
                Text(detalle).font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if bloqueada {
                // Solo el candado (con texto, recortaba el título); VoiceOver lo lee como «Premium».
                Image(systemName: "lock").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                    .accessibilityLabel("Premium")
            } else if let estado {
                Text(estado).font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            }
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Paleta.textoSecundario).accessibilityHidden(true)
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        .contornoTinta(radio: Radio.ficha)
        .accessibilityElement(children: .combine)
    }
}

/// Una convocatoria anterior: fuente, reproducción literal y, si está completa, el modo examen
/// (90 min, rúbrica B/R/M); si no, solo el repaso con soluciones y enlaces, y el motivo.
struct PantallaConvocatoria: View {
    let examen: ExamenOficial
    let empezar: () -> Void
    var bloqueado = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.l) {
                Text("Convocatoria \(examen.nombre)").font(.exhibicion(.title2))
                Text(examen.cita).font(.footnote).fixedSize(horizontal: false, vertical: true)
                if let url = URL(string: examen.fuente) { Link("Cuadernillo oficial (Comunidad de Madrid)", destination: url).font(.footnote.weight(.semibold)) }
                if examen.completo {
                    BotonPrincipal(titulo: "Hacer el examen (\(examen.duracionMin) min)", icono: "doc.text", acento: Paleta.primario, accion: empezar)
                        .disabled(bloqueado)
                        .accessibilityIdentifier("botonExamenOficial")
                    if examen.penalizacionAplicable {
                        Text(ResultadoEscrito.etiquetaPenalizacion + ": la penalización ortográfica se muestra aparte.")
                            .font(.caption).foregroundStyle(Paleta.textoSecundario)
                    }
                } else if let motivo = examen.motivoSoloRepaso {
                    Label("Solo repaso. \(motivo)", systemImage: "info.circle").font(.footnote).fixedSize(horizontal: false, vertical: true)
                }
                NavigationLink { PantallaRepasoOficial(examen: examen) } label: {
                    Label("Repaso con soluciones", systemImage: "book")
                }
                .buttonStyle(EstiloBotonSecundario())
                .accessibilityIdentifier("botonRepasoOficial")
            }
            .foregroundStyle(Paleta.textoPrincipal)
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .navigationTitle(examen.nombre)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Tabla de un enunciado oficial.
struct VistaTabla: View {
    let tabla: Tabla

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Espacio.m, verticalSpacing: Espacio.xs) {
            GridRow { ForEach(tabla.cabecera, id: \.self) { Text($0).font(.subheadline.weight(.semibold)) } }
            Divider()
            ForEach(Array(tabla.filas.enumerated()), id: \.offset) { _, fila in
                GridRow { ForEach(Array(fila.enumerated()), id: \.offset) { _, c in Text(c).font(.subheadline).fixedSize(horizontal: false, vertical: true) } }
            }
        }
        .padding(Espacio.m)
        .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.celda))
        .accessibilityElement(children: .contain)
    }
}

/// Repaso de un examen oficial: cada pregunta con su solución, las notas de la app y la rúbrica,
/// sin cronómetro.
struct PantallaRepasoOficial: View {
    let examen: ExamenOficial

    var body: some View {
        List {
            Section {
                Text(examen.cita).font(.caption)
                Text(examen.aviso).font(.caption).foregroundStyle(Paleta.textoSecundario)
                if let notas = examen.notas { Text(notas).font(.caption).foregroundStyle(Paleta.textoSecundario) }
            }
            ForEach(examen.preguntas) { q in
                VStack(alignment: .leading, spacing: Espacio.xs) {
                    Text("\(q.codigo)\(q.esAnulada ? " · anulada, no puntúa" : "")").font(.subheadline.weight(.semibold))
                    Text(q.enunciadoVisible).font(.system(.body, design: .serif)).fixedSize(horizontal: false, vertical: true)
                    if let t = q.tabla { VistaTabla(tabla: t) }
                    if let f = q.figura {
                        Text("Figura: \(f)").font(.footnote).foregroundStyle(Paleta.textoSecundario)
                        if let url = URL(string: examen.fuente) { Link("Ver la figura en el cuadernillo oficial" + (q.paginaFigura.map { ", página \($0)" } ?? ""), destination: url).font(.footnote) }
                    }
                    Text("Solución: \(q.solucionModelo)").font(.footnote).fixedSize(horizontal: false, vertical: true)
                    Text("Rúbrica \(q.fuenteRubrica == "oficial" ? "oficial" : "propia de la app"): B · \(q.rubrica.bien) R · \(q.rubrica.regular) M · \(q.rubrica.mal)")
                        .font(.caption).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                    if let n = q.notaRubrica { Text(n).font(.caption).foregroundStyle(Paleta.textoSecundario) }
                }
                .padding(.vertical, Espacio.xs)
            }
        }
        .navigationTitle("Repaso \(examen.nombre)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
