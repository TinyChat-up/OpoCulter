import SwiftUI
import Observation

@MainActor
@Observable
final class HoyViewModel {
    let servicio: ServicioSesion
    private(set) var estado: EstadoHoy?
    private(set) var mensajeError: String?
    var rondaActiva: RondaViewModel?
    /// Área elegida en el panel protagonista (por defecto, la de la competencia en curso).
    var area: String?
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
            if !bienvenidaDecidida {
                bienvenidaDecidida = true
                mostrarBienvenida = estado?.avatar == nil || forzarBienvenida
            } else if estado?.avatar == nil {
                mostrarBienvenida = true   // tras "Borrar mi progreso"
            }
            mensajeError = nil
            if area == nil || !(estado?.propuestas.contains { $0.area == area } ?? false) {
                area = estado?.competenciaEnCurso.map { Catalogo.area(de: $0.id) } ?? estado?.propuestas.first?.area
            }
        } catch {
            mensajeError = "No se ha podido cargar tu progreso."
        }
    }

    var propuesta: PropuestaRonda? {
        estado?.propuestas.first { $0.area == area } ?? estado?.propuestas.first
    }

    /// La ronda recomendada si el área elegida es la de la competencia en curso; si no, la del área.
    func tipoRonda(principal: TipoRonda) -> TipoRonda {
        guard let propuesta, let enCurso = estado?.competenciaEnCurso else { return principal }
        return Catalogo.area(de: enCurso.id) == propuesta.area ? principal : .area(propuesta.area)
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

/// Pestaña Hoy (v2): cabecera con avatar, racha y nivel; un único panel protagonista (la ronda);
/// baldosas compactas neutras; misiones como filas.
struct PantallaHoy: View {
    @Environment(EntornoApp.self) private var entorno
    @State var modelo: HoyViewModel
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
            .padding(Espacio.l)
        }
        // Margen inferior: la barra de pestañas flotante no tapa el final del contenido.
        .contentMargins(.bottom, Espacio.xxl * 2, for: .scrollContent)
        .defaultScrollAnchor(entorno.opciones.captura == "hoy:final" ? .bottom : .top)
        .background(Paleta.fondo.ignoresSafeArea())
        .onAppear {
            if entorno.opciones.captura == "hoy:mates", modelo.area == nil { modelo.area = "MAT" }
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
        let grande = tamano >= .xxxLarge
        let disposicion = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.s)) : AnyLayout(HStackLayout(alignment: .center, spacing: Espacio.m))
        return VStack(alignment: .leading, spacing: Espacio.m) {
            disposicion {
                HStack(spacing: Espacio.m) {
                    botonAvatar
                    titulo
                }
                if !grande { Spacer(minLength: Espacio.s) }
                if let estado = modelo.estado {
                    ChipRacha(dias: estado.racha.actual, protectores: estado.racha.protectores, record: estado.racha.record,
                              abrirAyudaAlAparecer: entorno.opciones.captura == "hoy:globo")
                }
            }
            if let estado = modelo.estado { nivel(estado) }
        }
    }

    @ViewBuilder
    private var botonAvatar: some View {
        if let avatar = Avatar.con(id: modelo.estado?.avatar) {
            Button { mostrarPerfil = true } label: {
                VistaAvatar(avatar: avatar, tamano: 52)
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

    /// Nivel como fila (no tarjeta): número, XP y barra fina.
    private func nivel(_ estado: EstadoHoy) -> some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            HStack {
                Text("Nivel \(estado.nivel)").font(.redondeada(.subheadline, peso: .semibold)).foregroundStyle(Paleta.textoPrincipal)
                Spacer()
                Text("\(estado.xpEnNivel)/\(estado.xpParaSiguiente) XP").font(.redondeada(.subheadline)).foregroundStyle(Paleta.textoSecundario)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Paleta.superficie)
                    Capsule().fill(Paleta.recompensa).frame(width: max(10, geo.size.width * estado.fraccionNivel))
                    Capsule().strokeBorder(Paleta.contorno, lineWidth: Trazo.fino)
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nivel \(estado.nivel)")
        .accessibilityValue("\(estado.xpEnNivel) de \(estado.xpParaSiguiente) XP para el siguiente nivel. \(estado.xpTotal) XP en total")
        .accessibilityIdentifier("tarjetaNivel")
    }

    // MARK: Contenido

    @ViewBuilder
    private func contenido(_ estado: EstadoHoy) -> some View {
        if estado.rachaEnRiesgo { avisoRacha(estado) }
        panelRonda(estado)
        baldosas(estado)
        misiones(estado)
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

    private func avisoRacha(_ estado: EstadoHoy) -> some View {
        HStack(spacing: Espacio.m) {
            VistaPersonaje(companero: .tilde, estado: ReglasPersonaje.estado(para: .rachaEnRiesgo), tamano: 44)
            Text("Tu racha de \(estado.racha.actual) \(estado.racha.actual == 1 ? "día" : "días") está en riesgo: quedan menos de \(max(estado.horasHastaMedianoche, 1)) h para medianoche.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Paleta.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        .contornoTinta(radio: Radio.ficha)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("avisoRacha")
    }

    /// Panel protagonista: la ronda recomendada del área elegida, con vista previa de la mecánica.
    @ViewBuilder
    private func panelRonda(_ estado: EstadoHoy) -> some View {
        let area = modelo.propuesta?.area ?? "LEN"
        PanelProtagonista(tinte: Paleta.tinte(area: area), relleno: Espacio.xl) {
            VStack(alignment: .leading, spacing: Espacio.l) {
                if estado.propuestas.count > 1 {
                    Picker("Área", selection: Binding(get: { modelo.area ?? area }, set: { modelo.area = $0 })) {
                        ForEach(estado.propuestas, id: \.area) { p in
                            Text(p.area == "MAT" ? "Matemáticas" : "Lengua").tag(p.area)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("selectorArea")
                }
                if let p = modelo.propuesta {
                    VStack(alignment: .leading, spacing: Espacio.xs) {
                        Text("Ronda recomendada").font(.caption.weight(.semibold)).foregroundStyle(Paleta.tinta(area: area)).textCase(.uppercase)
                        HStack(alignment: .firstTextBaseline, spacing: Espacio.s) {
                            Image(systemName: SimboloBloque.de(competencia: p.competencia.id))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Paleta.tinta(area: area))
                                .accessibilityHidden(true)
                            Text(p.competencia.nombre)
                                .font(.exhibicion(.title2))
                                .foregroundStyle(Paleta.textoPrincipal)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("competenciaPanel")
                        }
                        Text("6–8 ítems · 2–5 minutos").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    }
                    if let mecanica = p.mecanica {
                        VistaPreviaMecanica(mecanica: mecanica, area: area)
                    }
                }
                BotonPrincipal(titulo: "Empezar ronda", icono: "play.fill", acento: Paleta.acento(area: area)) {
                    modelo.empezar(modelo.tipoRonda(principal: entorno.tipoRondaPrincipal))
                }
                .accessibilityIdentifier("botonEmpezarRonda")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panelRonda")
    }

    /// Baldosas compactas: Rescate, Ortografía exprés y Supervivencia activas; Tribunal llega en la 05E (desactivada
    /// con su motivo, no botones falsos).
    private func baldosas(_ estado: EstadoHoy) -> some View {
        // Pilas normales (no `LazyVGrid`, que no reajusta el texto al cambiar su tamaño): dos
        // columnas y, con texto de accesibilidad, una.
        let fila = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Espacio.m)) : AnyLayout(HStackLayout(alignment: .top, spacing: Espacio.m))
        let lista = baldosasLista(estado)
        return VStack(spacing: Espacio.m) {
            fila { lista[0]; lista[1] }
            fila { lista[2]; lista[3] }
        }
    }

    private func baldosasLista(_ estado: EstadoHoy) -> [Baldosa] {
        [
            Baldosa(titulo: "Rescate", icono: "lifepreserver",
                    detalle: estado.rescatesPendientes == 0 ? "Sin errores pendientes" :
                        (estado.rescatesPendientes == 1 ? "1 error por rescatar" : "\(estado.rescatesPendientes) errores por rescatar"),
                    activa: true, id: "botonRescate") { modelo.mostrarRescate = true },
            Baldosa(titulo: "Ortografía exprés", icono: "character.cursor.ibeam", detalle: "5 ítems de ortografía y tildes",
                    activa: estado.itemsOrtografia > 0, id: "botonOrtografia") { modelo.empezar(.ortografiaExpres) },
            Baldosa(titulo: "Supervivencia", icono: "heart",
                    detalle: estado.supervivenciaDisponible ? (estado.recordSupervivencia.map { "Récord: \($0) puntos" } ?? "3 vidas · sin récord aún") : "Contenido en preparación",
                    activa: estado.supervivenciaDisponible, id: "baldosaSupervivencia") { modelo.mostrarSupervivencia = true },
            Baldosa(titulo: "Tribunal", icono: "checkmark.seal", detalle: "Llega en 05E", activa: false, id: "baldosaTribunal") {},
        ]
    }

    /// Misiones del día como filas (sin tarjetas).
    private func misiones(_ estado: EstadoHoy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Misiones de hoy").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                .padding(.bottom, Espacio.s)
            ForEach(Array(estado.misiones.enumerated()), id: \.element.id) { i, mision in
                if i > 0 { Divider().overlay(Paleta.borde) }
                filaMision(mision)
            }
        }
    }

    private func filaMision(_ mision: Mision) -> some View {
        HStack(spacing: Espacio.m) {
            Image(systemName: mision.completada ? "checkmark.circle.fill" : icono(mision.tipo))
                .font(.body.weight(.semibold))
                .foregroundStyle(mision.completada ? Paleta.exito : Paleta.textoSecundario)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(mision.titulo).font(.body).foregroundStyle(Paleta.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Espacio.s)
            Text("\(min(mision.progreso, mision.objetivo))/\(mision.objetivo)")
                .font(.redondeada(.subheadline, peso: .semibold))
                .foregroundStyle(mision.completada ? Paleta.exito : Paleta.textoSecundario)
        }
        .padding(.vertical, Espacio.m)
        .frame(minHeight: Medidas.tactilMinimo)
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
        case .ortografiaExpres: "character.cursor.ibeam"
        case .combo: "bolt"
        case .ganarXP: "sparkles"
        case .aciertosSinPista: "lightbulb.slash"
        }
    }

    private var vacio: some View {
        VStack(spacing: Espacio.l) {
            VistaPersonaje(companero: .tilde, estado: ReglasPersonaje.estado(para: .estadoVacio))
            Text("Aún no hay contenido").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal)
            Text("Cuando el banco de ejercicios esté listo, aquí aparecerá tu ronda del día.")
                .font(.body).foregroundStyle(Paleta.textoSecundario)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, Espacio.xxl)
    }
}

/// Baldosa neutra compacta. Desactivada: sin aspecto de botón y con el motivo como texto.
struct Baldosa: View {
    let titulo: String
    let icono: String
    let detalle: String
    let activa: Bool
    let id: String
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(alignment: .leading, spacing: Espacio.xs) {
                HStack(spacing: Espacio.s) {
                    Image(systemName: icono).font(.body.weight(.semibold)).accessibilityHidden(true)
                    Text(titulo).font(.exhibicion(.headline))
                        .fixedSize(horizontal: false, vertical: true)
                    // Sin chevrón: la sombra dura ya marca que se puede pulsar (D-059) y el título
                    // («Supervivencia») cabe sin partirse.
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Paleta.textoPrincipal)
                Text(detalle).font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Espacio.m)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
            // Activa: contorno de tinta y sombra dura. Desactivada: plana y con borde suave.
            .superficiePulsable(Paleta.superficie, radio: Radio.ficha, borde: activa ? Paleta.contorno : Paleta.borde, sombra: activa)
        }
        .buttonStyle(.pulsable)
        .allowsHitTesting(activa)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(activa ? .isButton : [])
        .accessibilityIdentifier(id)
    }
}

/// Vista previa estática de la mecánica que toca (no interactiva).
struct VistaPreviaMecanica: View {
    let mecanica: Mecanica
    let area: String

    var body: some View {
        HStack(spacing: Espacio.m) {
            dibujo
                .frame(width: 96, height: 40, alignment: .leading)
                .accessibilityHidden(true)
            Text(mecanica.nombreVisible)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Paleta.textoPrincipal)
        }
        .padding(Espacio.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
        .contornoTinta(radio: Radio.ficha, grosor: Trazo.fino)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mecánica: \(mecanica.nombreVisible)")
        .accessibilityIdentifier("vistaPreviaMecanica")
    }

    @ViewBuilder
    private var dibujo: some View {
        let color = Paleta.acento(area: area)
        switch mecanica {
        case .fraccionBarras:
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: Radio.celda).fill(i < 3 ? color : Paleta.superficie)
                        .overlay(RoundedRectangle(cornerRadius: Radio.celda).strokeBorder(Paleta.contorno, lineWidth: Trazo.fino))
                }
            }
        case .colocarTilde:
            HStack(spacing: 2) {
                ForEach(Array("café".enumerated()), id: \.offset) { i, letra in
                    Text(String(letra)).font(.redondeada(.headline, peso: .semibold))
                        .foregroundStyle(i == 3 ? Paleta.tinta(area: area) : Paleta.textoPrincipal)
                        .frame(width: 20, height: 30)
                        .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.celda))
                        .overlay(RoundedRectangle(cornerRadius: Radio.celda).strokeBorder(Paleta.contorno, lineWidth: Trazo.fino))
                }
            }
        default:
            Image(systemName: mecanica.simbolo).font(.title2.weight(.semibold)).foregroundStyle(Paleta.tinta(area: area))
        }
    }
}

extension Mecanica {
    /// Nombre de la mecánica para la interfaz.
    var nombreVisible: String {
        switch self {
        case .eleccion: "Elige la respuesta"
        case .verdaderoFalso: "Verdadero o falso"
        case .clasificar: "Clasifica"
        case .ordenar: "Ordena"
        case .emparejar: "Empareja"
        case .marcarTexto: "Marca en el texto"
        case .segmentar: "Analiza la oración"
        case .ruedas: "Gira las ruedas"
        case .construir: "Construye con piezas"
        case .numerico: "Calcula"
        case .colocarTilde: "Coloca la tilde"
        case .fraccionBarras: "Colorea la fracción"
        }
    }

    var simbolo: String {
        switch self {
        case .eleccion: "list.bullet"
        case .verdaderoFalso: "checkmark.circle"
        case .clasificar: "tray.2"
        case .ordenar: "arrow.up.arrow.down"
        case .emparejar: "link"
        case .marcarTexto: "highlighter"
        case .segmentar: "text.line.first.and.arrowtriangle.forward"
        case .ruedas: "dial.low"
        case .construir: "square.on.square"
        case .numerico: "number"
        case .colocarTilde: "character.cursor.ibeam"
        case .fraccionBarras: "rectangle.split.3x1"
        }
    }
}
