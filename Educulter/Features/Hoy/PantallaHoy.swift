import SwiftUI
import Observation

@MainActor
@Observable
final class HoyViewModel {
    let servicio: ServicioSesion
    private(set) var estado: EstadoHoy?
    private(set) var mensajeError: String?
    var rondaActiva: RondaViewModel?

    init(servicio: ServicioSesion) {
        self.servicio = servicio
    }

    func cargar() {
        do {
            estado = try servicio.estadoHoy()
            mensajeError = nil
        } catch {
            mensajeError = "No se ha podido cargar tu progreso."
        }
    }

    func empezar(_ tipo: TipoRonda) {
        rondaActiva = RondaViewModel(servicio: servicio, tipo: tipo)
    }

    func cerrarRonda() {
        rondaActiva = nil
        cargar()
    }
}

/// Pestaña Hoy: ronda recomendada, racha, nivel, misiones, Rescate y Ortografía exprés.
struct PantallaHoy: View {
    @Environment(EntornoApp.self) private var entorno
    @State var modelo: HoyViewModel
    @State private var mostrarRevision = false
    @Environment(\.dynamicTypeSize) private var tamano

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.xl) {
                cabecera
                if let estado = modelo.estado {
                    if estado.hayContenido {
                        contenido(estado)
                    } else {
                        vacio
                    }
                } else if let error = modelo.mensajeError {
                    Text(error).foregroundStyle(Paleta.fallo)
                }
            }
            .padding(Espacio.l)
        }
        // Margen inferior extra: la barra de pestañas flotante no debe tapar el final del
        // contenido (Rescate y Ortografía exprés quedan siempre visibles al desplazar).
        .contentMargins(.bottom, Espacio.xxl * 2, for: .scrollContent)
        // Solo para capturas (Debug): escena desplazada hasta el final.
        .defaultScrollAnchor(entorno.opciones.captura == "hoy:final" ? .bottom : .top)
        .background(Paleta.fondo.ignoresSafeArea())
        .onAppear { modelo.cargar() }
        .fullScreenCover(item: $modelo.rondaActiva) { ronda in
            PantallaRonda(modelo: ronda, ayudasDePrueba: entorno.opciones.ayudasDePrueba) { modelo.cerrarRonda() }
        }
        #if DEBUG
        .sheet(isPresented: $mostrarRevision) {
            PantallaRevision()
        }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaHoy")
    }

    private var cabecera: some View {
        // Disposición según el tamaño de texto (no `ViewThatFits`, que la auditoría de
        // Dynamic Type interpreta como texto que no escala).
        let grande = tamano >= .xxxLarge
        let disposicion = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.s)) : AnyLayout(HStackLayout(alignment: .center, spacing: Espacio.m))
        return disposicion {
            titulo
            if !grande { Spacer(minLength: Espacio.s) }
            chip
        }
    }

    private var titulo: some View {
        Text("Hoy")
            .font(.largeTitle.bold())
            .foregroundStyle(Paleta.textoPrincipal)
            .accessibilityAddTraits(.isHeader)
            #if DEBUG
            .onLongPressGesture { mostrarRevision = true }
            .accessibilityAction(named: "Revisión de contenido") { mostrarRevision = true }
            #endif
            .accessibilityIdentifier("tituloHoy")
    }

    @ViewBuilder
    private var chip: some View {
        if let estado = modelo.estado {
            ChipRacha(dias: estado.racha.actual, protectores: estado.racha.protectores, record: estado.racha.record,
                      abrirAyudaAlAparecer: entorno.opciones.captura == "hoy:globo")
        }
    }

    @ViewBuilder
    private func contenido(_ estado: EstadoHoy) -> some View {
        nivel(estado)

        // Ronda recomendada.
        let acento = estado.competenciaEnCurso.map { Paleta.acento(competencia: $0.id) } ?? Paleta.matematicas
        TarjetaSuperficie(relleno: Espacio.xl) {
            VStack(alignment: .leading, spacing: Espacio.l) {
                VStack(alignment: .leading, spacing: Espacio.xs) {
                    Text("Ronda recomendada").font(.caption.bold()).foregroundStyle(acento).textCase(.uppercase)
                    HStack(alignment: .firstTextBaseline, spacing: Espacio.s) {
                        Image(systemName: estado.competenciaEnCurso.map { SimboloBloque.de(competencia: $0.id) } ?? "sparkles")
                            .font(.title3.bold())
                            .foregroundStyle(acento)
                            .accessibilityHidden(true)
                        Text(estado.competenciaEnCurso?.nombre ?? "Repaso general")
                            .font(.title2.bold())
                            .foregroundStyle(Paleta.textoPrincipal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("6–8 ítems · 2–5 minutos").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                }
                BotonPrincipal(titulo: "Empezar ronda", icono: "play.fill", acento: acento) {
                    modelo.empezar(entorno.tipoRondaPrincipal)
                }
                .accessibilityIdentifier("botonEmpezarRonda")
            }
        }

        // Misiones.
        VStack(alignment: .leading, spacing: Espacio.m) {
            Text("Misiones de hoy").font(.title3.bold()).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            ForEach(estado.misiones) { mision in filaMision(mision) }
        }

        // Rescate y Ortografía exprés.
        VStack(spacing: Espacio.m) {
            tarjetaAccion(titulo: "Rescate", icono: "lifepreserver", color: Paleta.fallo,
                          detalle: estado.rescatesPendientes == 0 ? "Sin errores pendientes" :
                            (estado.rescatesPendientes == 1 ? "1 error por rescatar" : "\(estado.rescatesPendientes) errores por rescatar"),
                          boton: "Rescatar", activo: estado.rescatesPendientes > 0, id: "botonRescate") { modelo.empezar(.rescate) }
            tarjetaAccion(titulo: "Ortografía exprés", icono: "textformat.abc", color: Paleta.lengua,
                          detalle: "5 ítems de ortografía y tildes", boton: "Empezar", activo: estado.itemsOrtografia > 0,
                          id: "botonOrtografia") { modelo.empezar(.ortografiaExpres) }
        }
    }

    private func nivel(_ estado: EstadoHoy) -> some View {
        TarjetaSuperficie {
            HStack(spacing: Espacio.l) {
                Text("\(estado.nivel)")
                    .font(.redondeada(.title, peso: .bold))
                    .foregroundStyle(Paleta.textoSobreRecompensa)
                    .frame(minWidth: 52, minHeight: 52)
                    .background(Paleta.recompensa, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Espacio.s) {
                    let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.xs)) : AnyLayout(HStackLayout())
                    disposicion {
                        Text("Nivel \(estado.nivel)").font(.headline).foregroundStyle(Paleta.textoPrincipal)
                        if !tamano.isAccessibilitySize { Spacer() }
                        Text("\(estado.xpEnNivel)/\(estado.xpParaSiguiente) XP")
                            .font(.redondeada(.subheadline))
                            .foregroundStyle(Paleta.textoSecundario)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Paleta.borde)
                            Capsule().fill(Paleta.recompensa).frame(width: geo.size.width * estado.fraccionNivel)
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nivel \(estado.nivel)")
        .accessibilityValue("\(estado.xpEnNivel) de \(estado.xpParaSiguiente) XP para el siguiente nivel. \(estado.xpTotal) XP en total")
        .accessibilityIdentifier("tarjetaNivel")
    }

    private func filaMision(_ mision: Mision) -> some View {
        TarjetaSuperficie(relleno: Espacio.m) {
            HStack(spacing: Espacio.m) {
                Image(systemName: mision.completada ? "checkmark.circle.fill" : icono(mision.tipo))
                    .font(.title3)
                    .foregroundStyle(mision.completada ? Paleta.exito : Paleta.matematicas)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Espacio.xs) {
                    Text(mision.titulo).font(.body.weight(.medium)).foregroundStyle(Paleta.textoPrincipal)
                    ProgressView(value: Double(min(mision.progreso, mision.objetivo)), total: Double(mision.objetivo))
                        .tint(mision.completada ? Paleta.exito : Paleta.matematicas)
                        .accessibilityHidden(true)
                }
                Text("\(min(mision.progreso, mision.objetivo))/\(mision.objetivo)")
                    .font(.redondeada(.subheadline))
                    .foregroundStyle(Paleta.textoSecundario)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mision.titulo)
        .accessibilityValue(mision.completada ? "completada" : "\(mision.progreso) de \(mision.objetivo)")
        .accessibilityIdentifier("mision_\(mision.tipo.rawValue)")
    }

    private func icono(_ tipo: TipoMision) -> String {
        switch tipo {
        case .rescatarErrores: "lifepreserver"
        case .repasarCompetencias: "arrow.triangle.2.circlepath"
        case .rondaLengua: "text.book.closed"
        case .rondaMatematicas: "function"
        case .ortografiaExpres: "textformat.abc"
        case .combo: "bolt"
        case .ganarXP: "sparkles"
        case .aciertosSinPista: "lightbulb.slash"
        }
    }

    private func tarjetaAccion(titulo: String, icono: String, color: Color, detalle: String, boton: String,
                               activo: Bool, id: String, accion: @escaping () -> Void) -> some View {
        TarjetaSuperficie {
            let grande = tamano >= .xxxLarge
            let disposicion = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.m)) : AnyLayout(HStackLayout(spacing: Espacio.m))
            disposicion {
                textosAccion(titulo, icono, color, detalle)
                if !grande { Spacer(minLength: Espacio.s) }
                Button(boton, action: accion)
                    .buttonStyle(EstiloBotonSecundario(acento: color))
                    .fixedSize(horizontal: !grande, vertical: false)
                    .disabled(!activo)
                    .accessibilityIdentifier(id)
            }
        }
    }

    private func textosAccion(_ titulo: String, _ icono: String, _ color: Color, _ detalle: String) -> some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            Label(titulo, systemImage: icono).font(.headline).foregroundStyle(color)
            Text(detalle).font(.subheadline).foregroundStyle(Paleta.textoSecundario)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var vacio: some View {
        VistaLlegaPronto(titulo: "Aún no hay contenido", icono: "tray",
                         texto: "Cuando el banco de ejercicios esté listo, aquí aparecerá tu ronda del día.")
    }
}
