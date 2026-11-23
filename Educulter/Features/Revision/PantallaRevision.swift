#if DEBUG
import SwiftUI

/// Revisión de contenido (solo Debug). Lista todos los ítems por bloque, permite abrir
/// cualquiera en su mecánica real (sobre un progreso en memoria, sin tocar el real) y
/// muestra los errores del validador. Se abre con una pulsación larga en el título de Hoy.
struct PantallaRevision: View {
    @Environment(EntornoApp.self) private var entorno
    @Environment(\.dismiss) private var cerrar
    @State private var ronda: RondaViewModel?
    @State private var filtro = ""

    var body: some View {
        NavigationStack {
            List {
                if let banco = entorno.banco {
                    seccionValidacion(banco)
                    seccionGeneradores(banco)
                    ForEach(banco.catalogo.todosLosBloques) { bloque in
                        let items = banco.items(bloque: bloque.id).filter { filtro.isEmpty || $0.id.localizedCaseInsensitiveContains(filtro) }
                        if !items.isEmpty {
                            Section("\(bloque.nombre) · \(items.count)") {
                                ForEach(items) { item in fila(item) }
                            }
                        }
                    }
                    let tarjetas = banco.teoria
                    if !tarjetas.isEmpty {
                        Section("Teoría · \(tarjetas.count)") {
                            ForEach(tarjetas) { t in
                                NavigationLink {
                                    ScrollView { VistaTarjetaTeoria(tarjeta: t, acento: Paleta.tinta(competencia: t.competencia)).padding() }
                                        .background(Paleta.fondo)
                                        .navigationTitle(t.id)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(t.titulo).font(.body.weight(.medium))
                                        Text(t.id).font(.caption).foregroundStyle(Paleta.textoSecundario)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $filtro, prompt: "Filtrar por id")
            .navigationTitle("Revisión de contenido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { cerrar() } }
            }
            .fullScreenCover(item: $ronda) { modelo in
                PantallaRonda(modelo: modelo, ayudasDePrueba: true) { ronda = nil }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaRevision")
    }

    private func seccionValidacion(_ banco: BancoContenido) -> some View {
        let errores = ValidadorContenido().validar(banco)
        return Section("Validador · \(errores.count) errores") {
            if errores.isEmpty {
                Label("Todo el contenido es válido", systemImage: "checkmark.seal.fill").foregroundStyle(Paleta.exito)
            } else {
                ForEach(Array(errores.enumerated()), id: \.offset) { _, e in
                    VStack(alignment: .leading) {
                        Text(e.elemento).font(.caption.weight(.semibold)).foregroundStyle(Paleta.fallo)
                        Text(e.mensaje).font(.footnote)
                    }
                }
            }
        }
    }

    /// Plantillas de generador (con selector de semilla) y recuento del catálogo de preguntas.
    private func seccionGeneradores(_ banco: BancoContenido) -> some View {
        Section("Plantillas · \(banco.plantillas.count)") {
            NavigationLink {
                RevisionRecuentos(banco: banco)
            } label: {
                Label("Recuentos del catálogo de preguntas", systemImage: "number")
            }
            .accessibilityIdentifier("revisionRecuentos")
            ForEach(banco.plantillas) { p in
                NavigationLink {
                    RevisionPlantilla(plantilla: p, banco: banco) { id in
                        if let servicio = entorno.servicioDeRevision() { ronda = RondaViewModel(servicio: servicio, tipo: .items([id])) }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(p.id) · \(p.tipo)").font(.body.weight(.medium))
                        Text("\(p.mecanica.rawValue) · peldaño \(p.peldano) · dificultad \(p.dificultad) · \(p.validacion.estado.rawValue)")
                            .font(.caption).foregroundStyle(Paleta.textoSecundario)
                    }
                }
                .accessibilityIdentifier("plantilla_\(p.id)")
            }
        }
    }

    private func fila(_ item: Item) -> some View {
        Button {
            if let servicio = entorno.servicioDeRevision() {
                ronda = RondaViewModel(servicio: servicio, tipo: .items([item.id]))
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.enunciado).font(.body).foregroundStyle(Paleta.textoPrincipal).lineLimit(2)
                Text("\(item.id) · \(item.mecanica.rawValue) · peldaño \(item.peldano) · \(item.validacion.estado.rawValue)")
                    .font(.caption).foregroundStyle(Paleta.textoSecundario)
            }
        }
        .accessibilityIdentifier("revision_\(item.id)")
    }
}

/// Una plantilla con selector de semilla: muestra el ítem generado y lo abre en su mecánica real.
struct RevisionPlantilla: View {
    let plantilla: Plantilla
    let banco: BancoContenido
    let abrir: (String) -> Void
    @State private var semilla: Int = 0

    var body: some View {
        let generado = Result { try MotorGeneradores.generar(plantilla, semilla: UInt64(semilla), recursos: banco.recursos) }
        let muestra = try? MotorGeneradores.muestra(plantilla, semilla: UInt64(semilla), recursos: banco.recursos)
        List {
            Section("Semilla") {
                Stepper("Semilla \(semilla)", value: $semilla, in: 0...999_999)
                    .accessibilityIdentifier("selectorSemilla")
                HStack {
                    Button("−100") { semilla = max(0, semilla - 100) }
                    Spacer()
                    Button("Aleatoria") { semilla = Int.random(in: 0...999_999) }
                    Spacer()
                    Button("+100") { semilla = min(999_999, semilla + 100) }
                }
                .buttonStyle(.borderless)
            }
            switch generado {
            case .success(let item):
                Section("Ítem \(item.id)") {
                    Text(item.enunciado).font(.body)
                    if let muestra {
                        LabeledContent("Clave canónica", value: muestra.clave)
                        LabeledContent("Complejidad", value: String(format: "%.2f", muestra.complejidad))
                    }
                    Text(item.explicacion).font(.footnote).foregroundStyle(Paleta.textoSecundario)
                    ForEach(Array(item.erroresHabituales.enumerated()), id: \.offset) { _, e in
                        Text("\(e.respuesta): \(e.feedback)").font(.caption).foregroundStyle(Paleta.textoSecundario)
                    }
                    let errores = ValidadorContenido().validar(item: item, competencias: Set(banco.catalogo.todasLasCompetencias.map(\.id)))
                    Label(errores.isEmpty ? "Pasa el validador" : "\(errores.count) errores", systemImage: errores.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(errores.isEmpty ? Paleta.exito : Paleta.fallo)
                    Button("Abrir en su mecánica") { abrir(item.id) }
                        .accessibilityIdentifier("abrirPlantilla")
                }
            case .failure(let error):
                Section("Error") { Text(String(describing: error)).foregroundStyle(Paleta.fallo) }
            }
        }
        .navigationTitle(plantilla.id)
        .accessibilityIdentifier("revisionPlantilla")
    }
}

/// Tabla de recuentos del catálogo de preguntas (ítems estáticos + variantes únicas).
struct RevisionRecuentos: View {
    let banco: BancoContenido
    @State private var recuento: RecuentoCatalogo?

    var body: some View {
        List {
            if let r = recuento {
                Section("Total") {
                    LabeledContent("Preguntas únicas", value: "\(r.exacto ? "" : "≥ ")\(r.total)")
                    LabeledContent("Estáticas", value: "\(r.estaticos)")
                    LabeledContent("Generadas", value: "\(r.generados)")
                }
                Section("Por área") { filas(r.porArea) }
                Section("Por bloque") { filas(r.porBloque) }
                Section("Por dificultad") { filas(Dictionary(uniqueKeysWithValues: r.porDificultad.map { ("Dificultad \($0.key)", $0.value) })) }
                Section("Por peldaño") { filas(Dictionary(uniqueKeysWithValues: r.porPeldano.map { ("Peldaño \($0.key)", $0.value) })) }
                Section("Por plantilla") {
                    ForEach(r.plantillas, id: \.id) { p in
                        LabeledContent("\(p.id) · \(p.tipo)", value: "\(p.exacto ? "" : "≥ ")\(p.variantes)")
                    }
                }
            } else {
                ProgressView("Contando…")
            }
        }
        .navigationTitle("Recuentos")
        .accessibilityIdentifier("revisionRecuentosTabla")
        .task {
            let banco = banco
            recuento = await Task.detached { CatalogoPreguntas.recuento(banco) }.value
        }
    }

    private func filas(_ d: [String: Int]) -> some View {
        ForEach(d.sorted { $0.key < $1.key }, id: \.key) { k, v in LabeledContent(k, value: "\(v)") }
    }
}

/// Escenas fijas para generar capturas (`-captura <escena>`).
struct VistaCaptura: View {
    @Environment(EntornoApp.self) private var entorno
    let escena: String
    @State private var ronda: RondaViewModel?

    var body: some View {
        Group {
            let partes = escena.split(separator: ":").map(String.init)
            switch partes.first {
            case "item", "resumen":
                if let ronda { PantallaRonda(modelo: ronda) {} } else { Paleta.fondo }
            case "teoria":
                ScrollView {
                    if let t = entorno.banco?.teoria.first(where: { $0.id == partes.dropFirst().first }) {
                        VistaTarjetaTeoria(tarjeta: t, acento: Paleta.tinta(competencia: t.competencia)).padding(Espacio.l)
                    }
                }
                .background(Paleta.fondo.ignoresSafeArea())
            case "revision":
                PantallaRevision()
            case "mapa":
                VistaLlegaPronto(titulo: "Camino", icono: "point.topleft.down.to.point.bottomright.curvepath",
                                 texto: "Las rutas de Lengua y Matemáticas, competencia a competencia, con tu dominio y los Retos de bloque.")
            case "bienvenida":
                PantallaBienvenida { _ in }
            case "perfil":
                PantallaPerfil(avatar: 0) { _ in }
            case "personajes":
                CatalogoPersonajes()
            case "avatares":
                CatalogoAvatares()
            case "plantilla":
                if let banco = entorno.banco, let p = banco.plantilla(id: partes.dropFirst().first ?? "") {
                    NavigationStack { RevisionPlantilla(plantilla: p, banco: banco) { _ in } }
                }
            case "recuentos":
                if let banco = entorno.banco { NavigationStack { RevisionRecuentos(banco: banco) } }
            default:
                VistaRaiz()
            }
        }
        .task { preparar() }
    }

    private func preparar() {
        guard ronda == nil, let servicio = entorno.servicio, let banco = entorno.banco else { return }
        let partes = escena.split(separator: ":").map(String.init)
        if partes.first == "item", partes.count >= 2 {
            let modelo = RondaViewModel(servicio: servicio, tipo: .items([partes[1]]))
            let modo = partes.count >= 3 ? partes[2] : "antes"
            if modo == "relleno" {
                // Respuesta correcta puesta pero sin comprobar.
                modelo.rellenarParaPruebas(correcta: true)
            } else if modo != "antes" {
                modelo.rellenarParaPruebas(correcta: modo == "correcto")
                modelo.comprobar()
            }
            ronda = modelo
        } else if partes.first == "resumen" {
            let modelo = RondaViewModel(servicio: servicio, tipo: .items(EntornoApp.itemsDemostracion(banco)))
            var i = 0
            while modelo.fase == .respondiendo {
                modelo.rellenarParaPruebas(correcta: i != 2)
                modelo.comprobar()
                modelo.continuar()
                i += 1
            }
            ronda = modelo
        }
    }
}

/// Lámina de los dos compañeros en sus 6 estados (capturas y documentación).
struct CatalogoPersonajes: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.l) {
                ForEach(Companero.allCases, id: \.self) { c in
                    Text(c.nombre).font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Espacio.m) {
                        ForEach(EstadoPersonaje.allCases, id: \.self) { e in
                            VStack(spacing: Espacio.xs) {
                                VistaPersonaje(companero: c, estado: e, tamano: 80)
                                Text(e.rawValue).font(.footnote).foregroundStyle(Paleta.textoSecundario)
                            }
                        }
                    }
                }
            }
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
    }
}

/// Lámina de los 6 avatares del propietario con su etiqueta de VoiceOver.
struct CatalogoAvatares: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Espacio.l) {
                ForEach(Avatar.todos) { a in
                    VStack(spacing: Espacio.xs) {
                        VistaAvatar(avatar: a, tamano: 96)
                        Text("\(a.id) · \(a.nombre)").font(.caption).foregroundStyle(Paleta.textoSecundario).multilineTextAlignment(.center)
                    }
                }
            }
            .padding(Espacio.l)
        }
        .background(Paleta.fondo.ignoresSafeArea())
    }
}
#endif
