import Charts
import SwiftUI

/// Corrección e informe del tribunal (05I §5): autoevaluación de lo abierto con el modelo y la
/// rúbrica, nota orientativa con la penalización aparte, sello «Apto», evolución de los simulacros
/// e informe con «Repasar ahora».
struct PantallaCorreccionExamen: View {
    @Bindable var modelo: ModeloExamen
    let cerrar: () -> Void
    /// Abre desplazada hasta el informe del tribunal (capturas).
    var alInforme = false
    @State private var indice = 0
    @State private var enviadas: [String]?
    @State private var verRevision = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { desplazador in
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    if let r = modelo.sesion.resultado {
                        resultado(r)
                    } else if modelo.pendientes.isEmpty {
                        Text("No hay respuestas abiertas que autoevaluar.").font(.body)
                        BotonPrincipal(titulo: "Ver la nota", acento: Paleta.primario) { modelo.corregir() }
                    } else {
                        autoevaluacion
                    }
                }
                .foregroundStyle(Paleta.textoPrincipal)
                .padding(Espacio.l)
            }
            .onAppear { if alInforme { desplazador.scrollTo("informe", anchor: .top) } }
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationTitle(modelo.sesion.resultado == nil ? "Corrección" : "Resultado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar", action: cerrar).accessibilityIdentifier("botonCerrarCorreccion") } }
            .sheet(isPresented: $verRevision) { PantallaRevisionExamen(modelo: modelo) }
        }
    }

    // MARK: Autoevaluación

    @ViewBuilder private var autoevaluacion: some View {
        let pendientes = modelo.pendientes
        let i = pendientes[min(indice, pendientes.count - 1)]
        Text("Autoevaluación \(min(indice, pendientes.count - 1) + 1) de \(pendientes.count)").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
        Text("Pregunta \(modelo.codigo(i))").font(.exhibicion(.title3)).accessibilityAddTraits(.isHeader)
        Text(modelo.enunciado(i)).font(.system(.body, design: .serif)).fixedSize(horizontal: false, vertical: true)
        bloque("Tu respuesta", texto: textoRespuesta(i))
        bloque("Modelo", texto: modelo.oficial(i)?.solucionModelo ?? modeloRecuerdo(i))
        rubrica(i)
        let actual = modelo.sesion.autoevaluaciones[i]
        Text("¿Cómo está tu respuesta?").font(.subheadline.weight(.semibold))
        HStack(spacing: Espacio.s) {
            ForEach(SesionExamen.Autoevaluacion.Nivel.allCases, id: \.self) { n in
                Button {
                    modelo.autoevaluar(i, .init(nivel: n, palabras: actual?.palabras ?? 0, tildes: actual?.tildes ?? 0))
                } label: {
                    Ficha(texto: "\(n.letra) · \(FormatoNumero.numero(Racional(numerador: Int(n.valor * 10), denominador: 10)!))",
                          estado: actual?.nivel == n ? .seleccionada : .normal, acento: Paleta.primario, anchoCompleto: true)
                }
                .buttonStyle(.pulsable)
                .accessibilityLabel(n == .bien ? "Bien, 1 punto" : (n == .regular ? "Regular, medio punto" : "Mal, 0 puntos"))
                .accessibilityIdentifier("nivel_\(n.rawValue)")
            }
        }
        if modelo.area(i) == "LEN", let a = actual {
            Text("Faltas de ortografía (compara con el modelo; cada palabra cuenta una vez aunque se repita)")
                .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            Stepper("Palabras mal escritas: \(a.palabras)", value: Binding(get: { a.palabras }, set: { modelo.autoevaluar(i, .init(nivel: a.nivel, palabras: max(0, $0), tildes: a.tildes)) }), in: 0...30)
            Stepper("Tildes: \(a.tildes)", value: Binding(get: { a.tildes }, set: { modelo.autoevaluar(i, .init(nivel: a.nivel, palabras: a.palabras, tildes: max(0, $0))) }), in: 0...30)
        }
        HStack {
            if indice > 0 { Button("Anterior") { indice -= 1 }.buttonStyle(EstiloBotonSecundario()) }
            Spacer()
            if indice + 1 < pendientes.count {
                Button("Siguiente") { indice += 1 }.buttonStyle(EstiloBotonSecundario()).disabled(actual == nil)
            }
        }
        if pendientes.allSatisfy({ modelo.sesion.autoevaluaciones[$0] != nil }) {
            BotonPrincipal(titulo: "Ver la nota", icono: "checkmark.seal", acento: Paleta.primario) { modelo.corregir() }
                .accessibilityIdentifier("botonVerNota")
        }
    }

    private func textoRespuesta(_ i: Int) -> String {
        let r = modelo.sesion.respuestas[i] ?? .init()
        if r.enPapel { return "Respondida en papel." }
        if case .recuerdo(let rec)? = r.item { return rec.enPapel ? "Respondida en papel." : rec.texto }
        if !r.valor.isEmpty { return r.valor + (r.unidad.map { " \($0)" } ?? "") }
        return r.texto.isEmpty ? "Sin responder." : r.texto
    }

    private func modeloRecuerdo(_ i: Int) -> String {
        if case .recuerdo(let p)? = modelo.item(i)?.payload { return p.modelo }
        return ""
    }

    @ViewBuilder private func rubrica(_ i: Int) -> some View {
        if let o = modelo.oficial(i) {
            let oficial = o.fuenteRubrica == "oficial"
            VStack(alignment: .leading, spacing: Espacio.xs) {
                Text(oficial ? "Rúbrica oficial (plantilla de corrección de la convocatoria)" : "Rúbrica propia de la app (la convocatoria no publica una)")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                    .accessibilityIdentifier("etiquetaRubrica")
                Text("B · \(o.rubrica.bien)").font(.footnote)
                Text("R · \(o.rubrica.regular)").font(.footnote)
                Text("M · \(o.rubrica.mal)").font(.footnote)
                if let nota = o.notaRubrica { Text(nota).font(.caption).foregroundStyle(Paleta.textoSecundario) }
            }
            .fixedSize(horizontal: false, vertical: true)
        } else if case .recuerdo(let p)? = modelo.item(i)?.payload {
            VStack(alignment: .leading, spacing: Espacio.xs) {
                Text("Criterios propios de la app").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                ForEach(p.criterios, id: \.self) { Text("· \($0)").font(.footnote) }
            }
        }
    }

    private func bloque(_ titulo: String, texto: String) -> some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            Text(titulo).font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            Text(texto).font(.system(.body, design: .serif)).fixedSize(horizontal: false, vertical: true)
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha))
    }

    // MARK: Resultado e informe

    @ViewBuilder private func resultado(_ r: ResultadoExamen) -> some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("Nota orientativa").font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
            HStack(alignment: .firstTextBaseline) {
                Text(formato(r.notaFinal)).font(.resultado(.largeTitle)).accessibilityIdentifier("notaFinal")
                Text("sobre 10").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                Spacer()
                if r.apto { SelloApto() }
            }
            ForEach(r.notasArea.keys.sorted(), id: \.self) { a in
                Text("\(a == "LEN" ? "Lengua" : "Matemáticas"): \(formato(r.notasArea[a]!))").font(.body)
            }
            Text("Sin penalización: \(formato(r.nota)) · Penalización ortográfica \(r.etiquetaPenalizacion): −\(formato(r.penalizacion))")
                .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
            if !r.ponderacionDocumentada {
                Text(CorrectorExamen.sinPonderacion).font(.footnote).foregroundStyle(Paleta.textoSecundario).accessibilityIdentifier("sinPonderacion")
            }
            if !modelo.sesion.noIncluye.isEmpty {
                Text("Este simulacro no incluye: \(modelo.sesion.noIncluye.map(nombre).joined(separator: ", ")).").font(.footnote).foregroundStyle(Paleta.textoSecundario)
            }
        }
        .padding(Espacio.l)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta))
        evolucion
        informe(r)
        Button { verRevision = true } label: { Label("Revisar el examen", systemImage: "doc.text.magnifyingglass") }
            .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonRevisar")
    }

    @ViewBuilder private var evolucion: some View {
        let simulacros = ((try? modelo.servicio.historialExamenes()) ?? []).filter { if case .simulacro = $0.modo { true } else { false } }
            .compactMap { s in s.resultado.map { (s.inicio, $0.notaFinal) } }.sorted { $0.0 < $1.0 }
        if simulacros.count >= 1 {
            VStack(alignment: .leading, spacing: Espacio.s) {
                Text("Simulacros · mejor nota \(formato(simulacros.map(\.1).max() ?? 0))").font(.subheadline.weight(.semibold))
                Chart(Array(simulacros.enumerated()), id: \.offset) { k, s in
                    LineMark(x: .value("Simulacro", k + 1), y: .value("Nota", s.1)).foregroundStyle(Paleta.primario)
                    PointMark(x: .value("Simulacro", k + 1), y: .value("Nota", s.1)).foregroundStyle(Paleta.primario)
                    RuleMark(y: .value("Apto", 5)).foregroundStyle(Paleta.borde).lineStyle(StrokeStyle(dash: [4, 4]))
                }
                .chartYScale(domain: 0...10)
                .frame(height: 120)
                .accessibilityLabel("Evolución de los simulacros: \(simulacros.map { formato($0.1) }.joined(separator: ", "))")
            }
            .padding(Espacio.l)
            .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta))
        }
    }

    @ViewBuilder private func informe(_ r: ResultadoExamen) -> some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("Informe del tribunal").font(.exhibicion(.title3)).accessibilityAddTraits(.isHeader)
            if !r.fuertes.isEmpty {
                Text("Puntos fuertes").font(.subheadline.weight(.semibold))
                ForEach(r.fuertes, id: \.self) { Label(nombre($0), systemImage: "checkmark.circle").font(.footnote) }
            }
            if !r.debiles.isEmpty {
                Text("Para repasar").font(.subheadline.weight(.semibold))
                ForEach(r.debiles, id: \.self) { Label(nombre($0), systemImage: "arrow.counterclockwise.circle").font(.footnote) }
                if let enviadas {
                    Text(enviadas.isEmpty ? "No hay contenido aprobado para repasar esas competencias todavía."
                         : "Enviadas a Rescate: \(enviadas.map(nombre).joined(separator: ", ")). Sus remedios saldrán en la sesión diaria.")
                        .font(.footnote).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                } else {
                    BotonPrincipal(titulo: "Repasar ahora", icono: "lifepreserver", acento: Paleta.primario) { enviadas = modelo.repasarAhora() }
                        .accessibilityIdentifier("botonRepasarAhora")
                }
            }
        }
        .padding(Espacio.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta))
        .accessibilityIdentifier("informeTribunal")
        .id("informe")
    }

    private func nombre(_ c: String) -> String { modelo.banco.catalogo.todasLasCompetencias.first { $0.id == c }?.nombre ?? c }

    private func formato(_ v: Double) -> String { FormatoNumero.numero(Racional(numerador: Int((v * 100).rounded()), denominador: 100)!) }
}

/// Sello «Apto» (animación breve; sin ella con Reducir movimiento).
struct SelloApto: View {
    @Environment(\.accessibilityReduceMotion) private var reducir
    @State private var puesto = false

    var body: some View {
        Text("APTO")
            .font(.system(.title2, design: .serif).weight(.bold))
            .foregroundStyle(Paleta.exito)
            .padding(.horizontal, Espacio.m)
            .padding(.vertical, Espacio.xs)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Paleta.exito, lineWidth: 3))
            .rotationEffect(.degrees(-8))
            .scaleEffect(reducir || puesto ? 1 : 1.6)
            .opacity(reducir || puesto ? 1 : 0)
            .onAppear { withAnimation(reducir ? nil : .spring(duration: 0.45, bounce: 0.3)) { puesto = true } }
            .accessibilityLabel("Apto")
            .accessibilityIdentifier("selloApto")
    }
}

/// Revisión de un examen corregido o repaso de uno oficial: cada pregunta con la respuesta, la
/// solución, las notas de la app y la rúbrica, sin cronómetro.
struct PantallaRevisionExamen: View {
    let modelo: ModeloExamen
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<modelo.total, id: \.self) { i in
                    VStack(alignment: .leading, spacing: Espacio.xs) {
                        Text("Pregunta \(modelo.codigo(i))").font(.subheadline.weight(.semibold))
                        Text(modelo.enunciado(i)).font(.system(.footnote, design: .serif))
                        if let o = modelo.oficial(i) {
                            Text("Solución: \(o.solucionModelo)").font(.footnote)
                            if o.esAnulada { Text("Anulada: no puntúa.").font(.caption).foregroundStyle(Paleta.textoSecundario) }
                        } else if let item = modelo.item(i) {
                            Text("Solución: \(DescripcionSolucion.texto(item.payload))").font(.footnote)
                            if !item.pasos.isEmpty { Text(item.pasos.map { "\($0.frase): \($0.resultado)" }.joined(separator: " · ")).font(.caption) }
                        }
                        if let p = modelo.sesion.resultado?.preguntas.first(where: { $0.indice == i }), let v = p.puntuacion {
                            Text("Puntuación: \(FormatoNumero.numero(Racional(numerador: Int(v * 10), denominador: 10)!)) · \(p.automatica ? "corregida por la app" : "autoevaluada")")
                                .font(.caption).foregroundStyle(Paleta.textoSecundario)
                        }
                    }
                    .padding(.vertical, Espacio.xs)
                }
            }
            .navigationTitle("Revisión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { cerrar() } } }
        }
    }
}
