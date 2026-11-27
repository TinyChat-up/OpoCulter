import SwiftUI

/// Entrada del Tribunal (05I §3): examen oficial completo, medio examen, simulacro original y repaso
/// de un examen oficial; el examen en curso (para reanudarlo) y el historial.
struct PantallaTribunal: View {
    let servicio: ServicioSesion
    @State private var convocatoria: String = ""
    @State private var examen: ModeloExamen?
    @State private var enCurso: SesionExamen?
    @State private var historial: [SesionExamen] = []
    @State private var error: String?

    private var examenes: [ExamenOficial] { servicio.banco.tribunal.examenes.sorted { ($0.anio, $0.convocatoria) > ($1.anio, $1.convocatoria) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text("Exámenes oficiales de la prueba A1 y simulacros con su formato y su tiempo. Sin feedback hasta entregar.")
                        .font(.subheadline).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                    if let enCurso { tarjetaEnCurso(enCurso) }
                    selectorConvocatoria
                    modo("Examen oficial completo", detalle: "Lengua y Matemáticas · 90 min", icono: "doc.text", id: "modoOficial") {
                        empezar(.oficial(convocatoria))
                    }
                    modo("Medio examen · Lengua", detalle: "Solo Lengua · 45 min", icono: "textformat", id: "modoMedioLEN") { empezar(.medio(convocatoria, area: "LEN")) }
                    modo("Medio examen · Matemáticas", detalle: "Solo Matemáticas · 45 min", icono: "function", id: "modoMedioMAT") { empezar(.medio(convocatoria, area: "MAT")) }
                    modo("Simulacro original", detalle: "20 preguntas según el plano del examen · 90 min", icono: "wand.and.stars", id: "modoSimulacro") {
                        empezar(.simulacro(semilla: UInt64(servicio.reloj.ahora.timeIntervalSince1970)))
                    }
                    NavigationLink {
                        if let e = servicio.banco.tribunal.examen(convocatoria) { PantallaRepasoOficial(examen: e) }
                    } label: {
                        filaModo("Repaso del examen oficial", detalle: "Cada pregunta con su solución, sus notas y su rúbrica, sin cronómetro", icono: "book")
                    }
                    .accessibilityIdentifier("modoRepaso")
                    if let error { Text(error).font(.footnote).foregroundStyle(Paleta.fallo) }
                    historialVista
                }
                .foregroundStyle(Paleta.textoPrincipal)
                .padding(Espacio.l)
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationTitle("Tribunal")
            .onAppear(perform: cargar)
            .fullScreenCover(item: $examen, onDismiss: cargar) { m in PantallaExamen(modelo: m) { examen = nil } }
        }
        .accessibilityIdentifier("pantallaTribunal")
    }

    private func cargar() {
        if convocatoria.isEmpty { convocatoria = examenes.first?.id ?? "" }
        enCurso = try? servicio.examenEnCurso()
        historial = (try? servicio.historialExamenes()) ?? []
    }

    private func empezar(_ modo: SesionExamen.Modo) {
        guard AccesoTribunal.acceso(modo) == .permitido else { return }
        do { examen = ModeloExamen(servicio: servicio, sesion: try servicio.empezarExamen(modo)) } catch { self.error = "No se ha podido preparar el examen." }
    }

    private var selectorConvocatoria: some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            Text("Convocatoria").font(.subheadline.weight(.semibold))
            Picker("Convocatoria", selection: $convocatoria) {
                ForEach(examenes) { e in Text(e.nombre).tag(e.id) }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("selectorConvocatoria")
        }
    }

    private func tarjetaEnCurso(_ s: SesionExamen) -> some View {
        Button { examen = ModeloExamen(servicio: servicio, sesion: s) } label: {
            filaModo("Continuar: \(s.modo.nombre)", detalle: "Quedan \(Int(s.restante / 60)) min · pregunta \(s.actual + 1) de \(s.preguntas.count)", icono: "play.fill")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("botonContinuarExamen")
    }

    private func modo(_ titulo: String, detalle: String, icono: String, id: String, accion: @escaping () -> Void) -> some View {
        Button(action: accion) { filaModo(titulo, detalle: detalle, icono: icono) }
            .buttonStyle(.plain)
            .disabled(enCurso != nil)
            .accessibilityIdentifier(id)
    }

    private func filaModo(_ titulo: String, detalle: String, icono: String) -> some View {
        HStack(spacing: Espacio.m) {
            Image(systemName: icono).font(.title3).foregroundStyle(Paleta.primario).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(.headline).foregroundStyle(Paleta.textoPrincipal)
                Text(detalle).font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Espacio.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .contornoTinta(radio: Radio.tarjeta)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var historialVista: some View {
        if !historial.isEmpty {
            Text("Historial").font(.exhibicion(.title3)).accessibilityAddTraits(.isHeader)
            ForEach(historial) { s in
                Button { examen = ModeloExamen(servicio: servicio, sesion: s) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.modo.nombre + (s.modo.examenId.flatMap { servicio.banco.tribunal.examen($0)?.nombre }.map { " · \($0)" } ?? "")).font(.subheadline.weight(.semibold))
                            Text(s.inicio.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(Paleta.textoSecundario)
                        }
                        Spacer()
                        if let r = s.resultado {
                            Text(FormatoNumero.numero(Racional(numerador: Int((r.notaFinal * 100).rounded()), denominador: 100)!))
                                .font(.numerica(.headline)).foregroundStyle(Paleta.textoPrincipal)
                        }
                    }
                    .padding(Espacio.m)
                    .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha))
                }
                .buttonStyle(.plain)
            }
        }
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
                    if let f = q.figura {
                        Text("Figura: \(f)").font(.footnote).foregroundStyle(Paleta.textoSecundario)
                        if let url = URL(string: examen.fuente) { Link("Ver la figura en el cuadernillo oficial", destination: url).font(.footnote) }
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
