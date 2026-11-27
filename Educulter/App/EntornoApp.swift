import Foundation
import Observation
import SwiftData

/// Opciones de arranque. **Solo se aplican en Debug** (tests de UI, capturas y revisión).
struct OpcionesArranque: Equatable {
    /// Progreso en memoria (no toca el almacén real).
    var enMemoria = false
    /// Semilla fija para la aleatoriedad (rondas reproducibles).
    var semilla: UInt64?
    /// Muestra el botón "Rellenar (pruebas)" en las rondas.
    var ayudasDePrueba = false
    /// "Empezar ronda" lanza una ronda con un ítem de cada mecánica.
    var rondaDemostracion = false
    /// "Empezar ronda" lanza una ronda con estos ítems, en orden (`-rondaItems id1,id2…`).
    var rondaItems: [String]?
    /// Escena que se abre directamente para generar capturas.
    var captura: String?
    /// Avatar preseleccionado (se salta la bienvenida en tests y capturas).
    var avatar: Int?
    /// Almacén SwiftData en disco con este nombre (test de cierre y reapertura).
    var almacenPruebas: String?
    /// Borra el almacén de pruebas al arrancar.
    var borrarAlmacen = false
    /// Carga solo el contenido aprobado, como en Release.
    var politicaRelease = false
    /// Muestra la bienvenida aunque haya avatar (tests del flujo bienvenida → diagnóstico → plan).
    var forzarBienvenida = false
    /// Capturas: genera progreso real con el motor antes de mostrar la escena.
    var progresoDemo = false
    /// Tests de UI: da por respondida la pregunta del recordatorio (no aparece la alerta).
    var sinAvisoRecordatorio = false
    /// Historial de prueba (solo Debug): dos fallos del mismo error de porcentajes, que queda activo
    /// y trae su remedio a la siguiente sesión.
    var errorDemo = false
    /// Tests de interfaz (Debug): modo oscuro, para la auditoría. El texto grande se pide con el
    /// argumento del sistema `-UIPreferredContentSizeCategoryName` (no fija el tamaño).
    var modoOscuro = false

    static func desde(_ argumentos: [String]) -> OpcionesArranque {
        #if DEBUG
        var o = OpcionesArranque()
        o.enMemoria = argumentos.contains("-enMemoria")
        o.ayudasDePrueba = argumentos.contains("-ayudasDePrueba")
        o.rondaDemostracion = argumentos.contains("-rondaDemostracion")
        if let i = argumentos.firstIndex(of: "-rondaItems"), i + 1 < argumentos.count {
            o.rondaItems = argumentos[i + 1].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let i = argumentos.firstIndex(of: "-semilla"), i + 1 < argumentos.count { o.semilla = UInt64(argumentos[i + 1]) }
        if let i = argumentos.firstIndex(of: "-captura"), i + 1 < argumentos.count { o.captura = argumentos[i + 1] }
        if let i = argumentos.firstIndex(of: "-avatar"), i + 1 < argumentos.count { o.avatar = Int(argumentos[i + 1]) }
        if let i = argumentos.firstIndex(of: "-almacenPruebas"), i + 1 < argumentos.count { o.almacenPruebas = argumentos[i + 1] }
        o.borrarAlmacen = argumentos.contains("-borrarAlmacen")
        o.politicaRelease = argumentos.contains("-politicaRelease")
        o.forzarBienvenida = argumentos.contains("-forzarBienvenida")
        o.progresoDemo = argumentos.contains("-progresoDemo")
        o.errorDemo = argumentos.contains("-errorDemo")
        o.modoOscuro = argumentos.contains("-modoOscuro")
        o.sinAvisoRecordatorio = argumentos.contains("-sinAvisoRecordatorio") || o.captura != nil
        return o
        #else
        return OpcionesArranque()
        #endif
    }
}

/// Composición raíz: carga el contenido, crea la persistencia y el servicio de sesión.
@MainActor
@Observable
final class EntornoApp {
    let opciones: OpcionesArranque
    let servicio: ServicioSesion?
    let errorCarga: String?
    /// Sonidos sintetizados que respetan el interruptor de Ajustes (silencio en capturas).
    let sonido: any ServicioSonido
    /// Recordatorio diario local.
    let recordatorio: ProgramadorRecordatorio
    /// Copia observable de los ajustes (vibración y sonido se leen en las vistas).
    var ajustes = Ajustes()

    var banco: BancoContenido? { servicio?.banco }

    init(opciones: OpcionesArranque, servicio: ServicioSesion?, errorCarga: String?,
         centro: any CentroNotificaciones = CentroNotificacionesSistema()) {
        self.opciones = opciones
        self.servicio = servicio
        self.errorCarga = errorCarga
        self.recordatorio = ProgramadorRecordatorio(centro: centro, calendario: .current)
        let base: any ServicioSonido = opciones.captura == nil ? SonidoSintetizado() : SonidoSilencioso()
        var lector: (() -> Bool)?
        self.sonido = SonidoConAjustes(destino: base) { lector?() ?? true }
        self.ajustes = (try? servicio?.ajustes()) ?? Ajustes()
        lector = { [weak self] in self?.ajustes.sonido ?? true }
    }

    /// Guarda los ajustes y reprograma el recordatorio.
    func guardar(_ nuevos: Ajustes) {
        ajustes = nuevos
        try? servicio?.guardar(nuevos)
        Task { await reprogramarRecordatorio() }
    }

    /// Recarga los ajustes guardados (tras responder a la pregunta del recordatorio).
    func recargarAjustes() {
        ajustes = (try? servicio?.ajustes()) ?? ajustes
    }

    func reprogramarRecordatorio() async {
        guard let servicio else { return }
        await recordatorio.reprogramar(ajustes: ajustes, sesionHoy: (try? servicio.sesionCompletadaHoy()) ?? false, ahora: servicio.reloj.ahora)
    }

    /// Activa el recordatorio tras pedir el permiso en contexto (después de la primera ronda).
    func activarRecordatorio() async {
        let permitido = await recordatorio.centro.solicitarPermiso()
        var a = (try? servicio?.ajustes()) ?? ajustes
        a.recordatorioPreguntado = true
        a.recordatorio = permitido
        guardar(a)
    }

    /// Al completar una ronda: si ya está la sesión diaria de hoy, la notificación de hoy sobra.
    func rondaCompletada() {
        guard let servicio, (try? servicio.sesionCompletadaHoy()) == true else { return }
        recordatorio.cancelarHoy(ahora: servicio.reloj.ahora)
    }

    static func crear(argumentos: [String] = ProcessInfo.processInfo.arguments) -> EntornoApp {
        let opciones = OpcionesArranque.desde(argumentos)
        do {
            // Variantes de las plantillas: distintas en cada sesión; fijas con `-semilla`.
            var semillas = SystemRandomNumberGenerator()
            let semillaBase = opciones.semilla.map { UInt64($0) } ?? semillas.next() % 1_000_000
            let banco = opciones.politicaRelease
                ? try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados, semillaBase: semillaBase)
                : try CargadorContenido.desdeBundle().cargar(semillaBase: semillaBase)
            let repositorio: any RepositorioProgreso
            if opciones.enMemoria {
                repositorio = RepositorioEnMemoria()
            } else if let nombre = opciones.almacenPruebas {
                let url = URL.applicationSupportDirectory.appending(path: "\(nombre).store")
                if opciones.borrarAlmacen {
                    for sufijo in ["", "-shm", "-wal"] { try? FileManager.default.removeItem(at: URL(filePath: url.path(percentEncoded: false) + sufijo)) }
                }
                try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
                repositorio = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(url: url))
            } else {
                repositorio = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor())
            }
            let rng = opciones.semilla.map(GeneradorConSemilla.init(semilla:)) ?? .aleatorio()
            let servicio = ServicioSesion(banco: banco, repositorio: repositorio, rng: rng)
            if let avatar = opciones.avatar { try servicio.elegirAvatar(avatar) }
            #if DEBUG
            if opciones.errorDemo { try ProgresoDemo.forzarError(servicio) }
            #endif
            if opciones.sinAvisoRecordatorio {
                var a = try servicio.ajustes()
                a.recordatorioPreguntado = true
                try servicio.guardar(a)
            }
            return EntornoApp(opciones: opciones, servicio: servicio, errorCarga: nil)
        } catch {
            return EntornoApp(opciones: opciones, servicio: nil, errorCarga: "\(error)")
        }
    }

    /// Ronda que lanza el botón principal de Hoy: la sesión diaria con la duración y el foco elegidos
    /// (los tests de interfaz pueden fijar ítems con `-rondaItems` o `-rondaDemostracion`).
    var tipoRondaPrincipal: TipoRonda {
        let sesion = TipoRonda.sesion(duracion: ajustes.duracion, foco: ajustes.foco)
        guard let banco else { return sesion }
        if let ids = opciones.rondaItems {
            let existentes = ids.filter { banco.item(id: $0) != nil }
            if !existentes.isEmpty { return .items(existentes) }
        }
        guard opciones.rondaDemostracion else { return sesion }
        return .items(Self.itemsDemostracion(banco))
    }

    /// Ítem fijo de demostración por mecánica (estable para tests de UI y capturas).
    static let demostracionPreferida: [Mecanica: String] = [
        .eleccion: "LEN.REC.FIGURAS.0001", .verdaderoFalso: "LEN.CLA.SUSTADJ.0002", .clasificar: "LEN.CLA.SUSTADJ.0001",
        .ordenar: "LEN.LIT.CRONO.0001", .emparejar: "LEN.LEX.SINON.0001", .marcarTexto: "LEN.CLA.VERBO.0001",
        .segmentar: "LEN.SIN.COMPL.0001", .ruedas: "LEN.VER.ANALISIS.0001", .construir: "LEN.ORT.AGU.0008",
        .numerico: "MAT.OPE.FRACSUM.0001",
        .colocarTilde: "LEN.ORT.AGU.0010", .fraccionBarras: "MAT.NUM.FRAREP.0003",
    ]

    /// Un ítem por mecánica, en el orden del catálogo de mecánicas: el preferido si existe y, si no,
    /// el primero de esa mecánica.
    static func itemsDemostracion(_ banco: BancoContenido) -> [String] {
        // Las mecánicas de los juegos (05G) no entran en la demostración: tienen su propio flujo.
        Mecanica.allCases.filter { ![.evidencia, .recuerdo, .figuraArea].contains($0) }.compactMap { m in
            if let id = demostracionPreferida[m], banco.item(id: id)?.mecanica == m { return id }
            return banco.items.first { $0.mecanica == m && $0.peldano <= 4 }?.id
        }
    }

    /// Servicio aislado (en memoria) para revisar contenido sin alterar el progreso real.
    func servicioDeRevision() -> ServicioSesion? {
        banco.map { ServicioSesion(banco: $0, repositorio: RepositorioEnMemoria(), rng: GeneradorConSemilla(semilla: 1)) }
    }
}
