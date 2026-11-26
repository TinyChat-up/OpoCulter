import SwiftUI
import Observation

/// Pestañas de la raíz (Hoy puede abrir Camino desde su baldosa).
enum Pestana: Hashable { case hoy, camino, tribunal, progreso }

@MainActor
@Observable
final class HoyViewModel {
    let servicio: ServicioSesion
    private(set) var estado: EstadoHoy?
    private(set) var meta: MetaSemanal?
    private(set) var descanso = false
    private(set) var diasDescanso = 0
    private(set) var erroresActivos = 0
    /// Ítems de la sesión de cada duración (calibrados con el historial).
    private(set) var itemsPorDuracion: [DuracionSesion: Int] = [:]
    private(set) var mensajeError: String?
    var rondaActiva: RondaViewModel?
    /// Bienvenida (avatar → diagnóstico → plan) a pantalla completa. Se decide al primer cargar.
    var mostrarBienvenida = false
    private var bienvenidaDecidida = false
    var mostrarRescate = false
    var mostrarSupervivencia = false
    /// Ronda que se lanza al cerrar una hoja (Rescate o Supervivencia).
    var pendiente: TipoRonda?

    init(servicio: ServicioSesion) {
        self.servicio = servicio
    }

    func cargar(forzarBienvenida: Bool = false) {
        do {
            estado = try servicio.estadoHoy()
            meta = try servicio.metaSemanal()
            descanso = try servicio.descansoActivo()
            diasDescanso = try servicio.diasDescansoDisponibles()
            erroresActivos = try servicio.erroresSeguidos().activos.count
            itemsPorDuracion = Dictionary(uniqueKeysWithValues: try DuracionSesion.allCases.map { ($0, try servicio.itemsSesion($0)) })
            if !bienvenidaDecidida {
                bienvenidaDecidida = true
                mostrarBienvenida = estado?.avatar == nil || forzarBienvenida
            } else if estado?.avatar == nil {
                mostrarBienvenida = true   // tras "Borrar mi progreso"
            }
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

    func elegirAvatar(_ id: Int) {
        try? servicio.elegirAvatar(id)
        cargar()
    }

    func terminarBienvenida() {
        mostrarBienvenida = false
        cargar()
    }

    func lanzarPendiente() {
        if let tipo = pendiente {
            pendiente = nil
            empezar(tipo)
        }
    }
}

/// Pestaña Hoy (05E parte 2 §3.1): la semana y la racha, un único botón «Empezar» con la duración
/// debajo, los selectores de duración y de foco, y las baldosas de los modos. Nada más.
struct PantallaHoy: View {
    @Environment(EntornoApp.self) private var entorno
    @State var modelo: HoyViewModel
    /// Abre otra pestaña (la baldosa de Camino).
    var irA: (Pestana) -> Void = { _ in }
    @State private var mostrarRevision = false
    @State private var mostrarPerfil = false
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
            .padding(.horizontal, Espacio.l)
            .padding(.vertical, Espacio.xl)
        }
        // Margen inferior: la barra de pestañas flotante no tapa el final del contenido.
        .contentMargins(.bottom, Espacio.xxl * 2, for: .scrollContent)
        .defaultScrollAnchor(entorno.opciones.captura == "hoy:final" ? .bottom : .top)
        .background(Paleta.fondo.ignoresSafeArea())
        .onAppear {
            modelo.cargar(forzarBienvenida: entorno.opciones.forzarBienvenida)
        }
        .fullScreenCover(item: $modelo.rondaActiva) { ronda in
            PantallaRonda(modelo: ronda, ayudasDePrueba: entorno.opciones.ayudasDePrueba) { modelo.cerrarRonda() }
        }
        .fullScreenCover(isPresented: $modelo.mostrarBienvenida) {
            PantallaBienvenida(servicio: modelo.servicio, ayudasDePrueba: entorno.opciones.ayudasDePrueba,
                               elegir: { id in try? modelo.servicio.elegirAvatar(id) },
                               terminar: { modelo.terminarBienvenida() })
        }
        .sheet(isPresented: $modelo.mostrarRescate, onDismiss: { modelo.lanzarPendiente(); modelo.cargar() }) {
            PantallaRescate(servicio: modelo.servicio) { tipo in modelo.pendiente = tipo }
        }
        .sheet(isPresented: $modelo.mostrarSupervivencia, onDismiss: { modelo.lanzarPendiente() }) {
            PantallaInicioSupervivencia(servicio: modelo.servicio) { area in modelo.pendiente = .supervivencia(area: area) }
        }
        .sheet(isPresented: $mostrarPerfil) {
            PantallaPerfil(avatar: modelo.estado?.avatar) { id in modelo.elegirAvatar(id) }
        }
        #if DEBUG
        .sheet(isPresented: $mostrarRevision) {
            PantallaRevision()
        }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaHoy")
    }

    // MARK: Cabecera

    private var cabecera: some View {
        HStack(spacing: Espacio.m) {
            titulo
            Spacer(minLength: Espacio.s)
            botonAvatar
        }
    }

    @ViewBuilder
    private var botonAvatar: some View {
        if let avatar = Avatar.con(id: modelo.estado?.avatar) {
            Button { mostrarPerfil = true } label: {
                VistaAvatar(avatar: avatar, tamano: 44)
                    .frame(minWidth: Medidas.tactilMinimo, minHeight: Medidas.tactilMinimo)
            }
            .buttonStyle(.pulsable)
            .accessibilityLabel("Perfil")
            .accessibilityValue(avatar.nombre)
            .accessibilityHint("Cambia tu avatar")
            .accessibilityIdentifier("botonPerfil")
        }
    }

    private var titulo: some View {
        Text("Hoy")
            .font(.exhibicion(.largeTitle))
            .foregroundStyle(Paleta.textoPrincipal)
            .accessibilityAddTraits(.isHeader)
            #if DEBUG
            .onLongPressGesture { mostrarRevision = true }
            .accessibilityAction(named: "Revisión de contenido") { mostrarRevision = true }
            #endif
            .accessibilityIdentifier("tituloHoy")
    }

    // MARK: Contenido

    @ViewBuilder
    private func contenido(_ estado: EstadoHoy) -> some View {
        if let meta = modelo.meta { semana(meta, estado) }
        panelSesion
        baldosas(estado)
        #if DEBUG
        if entorno.opciones.almacenPruebas != nil {
            // Solo en el test de cierre y reapertura: el progreso guardado, legible por el test.
            Text((try? modelo.servicio.resumenProgreso()) ?? "-")
                .font(.footnote)
                .foregroundStyle(Paleta.textoSecundario)
                .accessibilityIdentifier("diagnosticoProgreso")
        }
        #endif
    }

    // MARK: Semana (meta semanal) y racha

    private func semana(_ meta: MetaSemanal, _ estado: EstadoHoy) -> some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tu semana").font(.headline).foregroundStyle(Paleta.textoPrincipal)
                Spacer(minLength: Espacio.s)
                Text("\(meta.hechos) de \(meta.metaEfectiva) días")
                    .font(.numerica(.subheadline))
                    .foregroundStyle(meta.cumplida ? Paleta.exito : Paleta.textoSecundario)
            }
            PuntosSemana(meta: meta)
            VStack(alignment: .leading, spacing: Espacio.xs) {
                ChipRacha(dias: estado.racha.actual, protectores: estado.racha.protectores, record: estado.racha.record,
                          abrirAyudaAlAparecer: entorno.opciones.captura == "hoy:globo")
                if modelo.descanso {
                    Label("Modo descanso: tu racha y tu meta están en pausa.", systemImage: "moon.zzz")
                        .font(.footnote)
                        .foregroundStyle(Paleta.textoSecundario)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("avisoDescanso")
                }
            }
        }
        .padding(Espacio.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tarjetaSemana")
    }

    // MARK: Sesión

    /// La acción principal: «Empezar» con la duración debajo y, después, los selectores.
    private var panelSesion: some View {
        let ajustes = entorno.ajustes
        let items = modelo.itemsPorDuracion[ajustes.duracion] ?? ajustes.duracion.itemsPorDefecto
        return VStack(alignment: .leading, spacing: Espacio.l) {
            VStack(alignment: .leading, spacing: Espacio.xs) {
                Text("Sesión de hoy").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityAddTraits(.isHeader)
                Text("Lo nuevo, el repaso que toca y los errores que estás corrigiendo.")
                    .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: Espacio.s) {
                BotonPrincipal(titulo: "Empezar", icono: "play.fill", acento: Paleta.primario) {
                    modelo.empezar(entorno.tipoRondaPrincipal)
                }
                .accessibilityHint("Sesión de unos \(ajustes.duracion.rawValue) minutos, \(items) preguntas")
                .accessibilityIdentifier("botonEmpezarRonda")
                Text("≈ \(ajustes.duracion.rawValue) min · \(items) preguntas")
                    .font(.numerica(.footnote, peso: .regular))
                    .foregroundStyle(Paleta.textoSecundario)
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("duracionSesion")
            }
            selectores
        }
        .padding(Espacio.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.lenguaTinte, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panelRonda")
    }

    private var selectores: some View {
        let ajustes = entorno.ajustes
        return VStack(alignment: .leading, spacing: Espacio.s) {
            Picker("Duración", selection: Binding(get: { ajustes.duracion }, set: { var a = entorno.ajustes; a.duracion = $0; entorno.guardar(a) })) {
                ForEach(DuracionSesion.allCases, id: \.self) { d in Text("\(d.rawValue) min").tag(d) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("selectorDuracion")
            Picker("Foco", selection: Binding(get: { ajustes.foco }, set: { var a = entorno.ajustes; a.foco = $0; entorno.guardar(a) })) {
                ForEach(FocoSesion.allCases, id: \.self) { f in Text(f.nombre).tag(f) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("selectorArea")
        }
    }

    // MARK: Modos

    /// Baldosas de los modos: Camino, Supervivencia, Rescate (con su número) y Tribunal (próximamente,
    /// desactivada con su motivo).
    private func baldosas(_ estado: EstadoHoy) -> some View {
        // Pilas normales (no `LazyVGrid`, que no reajusta el texto al cambiar su tamaño): dos
        // columnas y, con texto de accesibilidad, una.
        let fila = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Espacio.m)) : AnyLayout(HStackLayout(alignment: .top, spacing: Espacio.m))
        let lista = baldosasLista(estado)
        return VStack(alignment: .leading, spacing: Espacio.m) {
            Text("Modos").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
            fila { lista[0]; lista[1] }
            fila { lista[2]; lista[3] }
        }
    }

    private func baldosasLista(_ estado: EstadoHoy) -> [Baldosa] {
        let rescate: String = {
            if estado.rescatesPendientes == 0 && modelo.erroresActivos == 0 { return "Sin errores pendientes" }
            var partes: [String] = []
            if estado.rescatesPendientes > 0 { partes.append(estado.rescatesPendientes == 1 ? "1 ítem" : "\(estado.rescatesPendientes) ítems") }
            if modelo.erroresActivos > 0 { partes.append(modelo.erroresActivos == 1 ? "1 error activo" : "\(modelo.erroresActivos) errores activos") }
            return partes.joined(separator: " · ")
        }()
        return [
            Baldosa(titulo: "Camino", icono: "point.topleft.down.to.point.bottomright.curvepath",
                    detalle: estado.competenciaEnCurso.map { "Sigue con \($0.nombre)" } ?? "Tu ruta por el temario",
                    activa: true, id: "baldosaCamino") { irA(.camino) },
            Baldosa(titulo: "Supervivencia", icono: "heart",
                    detalle: estado.supervivenciaDisponible ? (estado.recordSupervivencia.map { "Récord: \($0) puntos" } ?? "3 vidas · sin récord aún") : "Contenido en preparación",
                    activa: estado.supervivenciaDisponible, id: "baldosaSupervivencia") { modelo.mostrarSupervivencia = true },
            Baldosa(titulo: "Rescate", icono: "lifepreserver", detalle: rescate, numero: estado.rescatesPendientes + modelo.erroresActivos,
                    activa: true, id: "botonRescate") { modelo.mostrarRescate = true },
            Baldosa(titulo: "Tribunal", icono: "checkmark.seal", detalle: "Próximamente", activa: false, id: "baldosaTribunal") {},
        ]
    }

    private var vacio: some View {
        VStack(spacing: Espacio.l) {
            Text("Aún no hay contenido").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal)
            Text("Cuando el banco de ejercicios esté listo, aquí aparecerá tu sesión del día.")
                .font(.body).foregroundStyle(Paleta.textoSecundario)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, Espacio.xxl)
    }
}

/// Los 7 días de la semana (lunes a domingo): relleno bosque los días con sesión, luna los de
/// descanso, anillo el de hoy si falta. Un solo elemento para VoiceOver con la lectura completa.
struct PuntosSemana: View {
    let meta: MetaSemanal
    static let iniciales = ["L", "M", "X", "J", "V", "S", "D"]
    static let nombres = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(meta.dias.enumerated()), id: \.offset) { i, d in
                VStack(spacing: Espacio.xs) {
                    punto(d.estado)
                    Text(Self.iniciales[i]).font(.caption2.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Meta semanal")
        .accessibilityValue(Self.lectura(meta))
        .accessibilityIdentifier("puntosSemana")
    }

    @ViewBuilder
    private func punto(_ e: MetaSemanal.EstadoDia) -> some View {
        let lado: CGFloat = 28
        switch e {
        case .hecho:
            Circle().fill(Paleta.matematicas).frame(width: lado, height: lado)
                .overlay(Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(Paleta.textoSobreBosque))
        case .descanso:
            Circle().strokeBorder(Paleta.borde, lineWidth: Trazo.fino).frame(width: lado, height: lado)
                .overlay(Image(systemName: "moon.fill").font(.caption2).foregroundStyle(Paleta.textoSecundario))
        case .pendiente:
            Circle().strokeBorder(Paleta.matematicas, lineWidth: Trazo.estado).frame(width: lado, height: lado)
        case .futuro, .sinSesion:
            Circle().strokeBorder(Paleta.borde, lineWidth: Trazo.fino).frame(width: lado, height: lado)
        }
    }

    /// «2 de 4 días. Lunes, hecho. Martes, descanso. …»
    static func lectura(_ meta: MetaSemanal) -> String {
        let dias = meta.dias.enumerated().map { i, d -> String in
            let estado = switch d.estado {
            case .hecho: "hecho"
            case .descanso: "descanso"
            case .pendiente: "hoy, pendiente"
            case .futuro: "por llegar"
            case .sinSesion: "sin sesión"
            }
            return "\(nombres[i].capitalized), \(estado)"
        }
        return (["\(meta.hechos) de \(meta.metaEfectiva) días"] + dias).joined(separator: ". ")
    }
}

/// Baldosa de modo: superficie plana con borde fino. Desactivada: sin aspecto de botón y con el
/// motivo como texto. `numero` muestra un contador discreto (Rescate).
struct Baldosa: View {
    let titulo: String
    let icono: String
    let detalle: String
    var numero: Int = 0
    let activa: Bool
    let id: String
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(alignment: .leading, spacing: Espacio.xs) {
                HStack(spacing: Espacio.s) {
                    Image(systemName: icono).font(.body.weight(.semibold)).accessibilityHidden(true)
                    Text(titulo).font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if numero > 0 {
                        Text("\(numero)")
                            .font(.numerica(.footnote, peso: .semibold))
                            .foregroundStyle(Paleta.textoSobreBosque)
                            .padding(.horizontal, Espacio.s)
                            .frame(minWidth: 24, minHeight: 24)
                            .background(Paleta.matematicas, in: Capsule())
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(activa ? Paleta.textoPrincipal : Paleta.textoSecundario)
                Text(detalle).font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Espacio.l)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .superficiePulsable(activa ? Paleta.superficie : Paleta.fondo, radio: Radio.ficha, sombra: activa)
        }
        .buttonStyle(.pulsable)
        .allowsHitTesting(activa)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(activa ? .isButton : [])
        .accessibilityIdentifier(id)
    }
}
