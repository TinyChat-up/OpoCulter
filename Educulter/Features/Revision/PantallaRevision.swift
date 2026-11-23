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
                    Text(c.nombre).font(.title3.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
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

/// Lámina de los 12 avatares con su nombre.
struct CatalogoAvatares: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Espacio.l) {
                ForEach(Avatar.todos) { a in
                    VStack(spacing: Espacio.xs) {
                        VistaAvatar(avatar: a, tamano: 64)
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
