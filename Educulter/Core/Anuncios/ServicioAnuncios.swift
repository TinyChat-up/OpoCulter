import Foundation
import Network
import Observation

/// Lo que el servicio necesita del SDK de anuncios y de UMP. En la app, `ProveedorGoogle`; en los
/// tests, uno falso.
@MainActor
protocol ProveedorAnuncios: AnyObject {
    /// Hay un intersticial cargado.
    var cargado: Bool { get }
    /// UMP permite pedir anuncios (`canRequestAds`).
    var puedePedirAnuncios: Bool { get }
    /// UMP exige ofrecer el botón de opciones de privacidad.
    var opcionesPrivacidadRequeridas: Bool { get }
    /// Actualiza el consentimiento y, si hace falta, muestra el formulario de UMP. `eee` (solo Debug)
    /// fuerza la geografía de depuración del EEE.
    func actualizarConsentimiento(eee: Bool) async
    /// Pide el permiso de seguimiento (ATT) si aún no se ha pedido.
    func pedirPermisoSeguimiento() async
    /// Inicializa el SDK (una vez).
    func iniciar() async
    /// Carga un intersticial (si no hay ya uno).
    func cargar(_ bloque: String) async
    /// Presenta el intersticial cargado. `false` si no hay ninguno o no se puede presentar.
    func presentar(alCerrar: @escaping @MainActor () -> Void) -> Bool
    func abrirOpcionesPrivacidad() async
}

/// ¿Hay conexión a internet?
protocol MonitorConexion: AnyObject, Sendable {
    var conectado: Bool { get }
}

/// Conexión real con `NWPathMonitor`.
final class ConexionSistema: MonitorConexion, @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let cerrojo = NSLock()
    private var estado = true

    init() {
        monitor.pathUpdateHandler = { [weak self] ruta in
            guard let self else { return }
            cerrojo.withLock { estado = ruta.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "educulter.conexion", qos: .utility))
    }

    deinit { monitor.cancel() }

    var conectado: Bool { cerrojo.withLock { estado } }
}

/// Anuncios de la versión gratuita (fase 06 §2): aplica `PoliticaAnuncios`, guarda su registro y
/// coordina UMP → ATT → SDK → intersticial. Solo intersticiales, nunca para Premium.
@MainActor
@Observable
final class ServicioAnuncios {
    private static let claveRegistro = "anuncios.registro"

    private(set) var registro: RegistroAnuncios
    /// El consentimiento ya se ha actualizado en este arranque.
    private(set) var consentimientoActualizado = false
    let politica: PoliticaAnuncios
    let identificadores: IdentificadoresAnuncios
    @ObservationIgnored private let acceso: ServicioAcceso
    @ObservationIgnored private let proveedor: any ProveedorAnuncios
    @ObservationIgnored private let almacen: any AlmacenClaves
    @ObservationIgnored private let reloj: any Reloj
    @ObservationIgnored private let conexion: any MonitorConexion
    @ObservationIgnored private var preparando = false
    /// Solo Debug: geografía de depuración EEE para ver el formulario de UMP.
    @ObservationIgnored var depuracionEEE = false

    init(acceso: ServicioAcceso, proveedor: any ProveedorAnuncios, almacen: any AlmacenClaves, reloj: any Reloj = RelojSistema(),
         conexion: any MonitorConexion, identificadores: IdentificadoresAnuncios = .actuales(), politica: PoliticaAnuncios = PoliticaAnuncios()) {
        self.acceso = acceso
        self.proveedor = proveedor
        self.almacen = almacen
        self.reloj = reloj
        self.conexion = conexion
        self.identificadores = identificadores
        self.politica = politica
        if let r = almacen.valor(RegistroAnuncios.self, Self.claveRegistro) {
            registro = r
        } else {
            // Primera apertura: hoy es el día 1.
            registro = RegistroAnuncios(primeraApertura: DiaCivil(reloj.ahora, calendario: politica.calendario))
            almacen.guardar(valor: registro, Self.claveRegistro)
        }
    }

    #if DEBUG
    /// Solo Debug (capturas y tests de interfaz): simula el día de uso y las rondas ya terminadas.
    func simular(diaDeUso: Int?, rondas: Int?) {
        if let diaDeUso {
            registro.primeraApertura = DiaCivil(reloj.ahora, calendario: politica.calendario).sumando(dias: -(max(diaDeUso, 1) - 1)).clave
        }
        if let rondas { registro.rondasDesdeUltimo = rondas }
        guardarRegistro()
    }
    #endif

    var entorno: EntornoAnuncio {
        EntornoAnuncio(premium: acceso.premium, conectado: conexion.conectado, consentimiento: proveedor.puedePedirAnuncios,
                       identificadores: identificadores.validos, cargado: proveedor.cargado)
    }

    /// Ya pueden salir anuncios (gratis y desde el día 3).
    var activos: Bool { politica.prepararConsentimiento(registro, premium: acceso.premium, ahora: reloj.ahora) && identificadores.validos }

    var opcionesPrivacidadRequeridas: Bool { consentimientoActualizado && proveedor.opcionesPrivacidadRequeridas }

    /// En la pantalla de inicio, ya visible: desde el día 3 y sin Premium, actualiza el
    /// consentimiento (UMP, con su formulario si hace falta), pide ATT si UMP permite anuncios,
    /// inicializa el SDK y precarga el primer intersticial. Nunca dentro de una ronda.
    func prepararEnInicio() async {
        guard activos, !preparando, !consentimientoActualizado else { return }
        preparando = true
        defer { preparando = false }
        await proveedor.actualizarConsentimiento(eee: depuracionEEE)
        consentimientoActualizado = true
        guard proveedor.puedePedirAnuncios else { return }
        await proveedor.pedirPermisoSeguimiento()
        await proveedor.iniciar()
        await precargar()
    }

    /// Carga el siguiente intersticial si puede haber anuncios.
    func precargar() async {
        guard activos, consentimientoActualizado, proveedor.puedePedirAnuncios, conexion.conectado, !proveedor.cargado else { return }
        await proveedor.cargar(identificadores.intersticial)
    }

    /// El usuario pulsa «Continuar» en el resultado de una ronda (o de una pantalla del Tribunal):
    /// la ronda cuenta y, si la política lo permite, sale un intersticial; `seguir` se llama al
    /// cerrarlo, o en el acto si no hay anuncio (nunca se espera a que cargue).
    func continuar(_ momento: MomentoAnuncio, seguir: @escaping @MainActor () -> Void) {
        let ahora = reloj.ahora
        if momento == .continuarTrasRonda {
            registro = politica.rondaTerminada(registro, premium: acceso.premium, ahora: ahora)
        }
        let decision = politica.decidir(momento, registro: registro, entorno: entorno, ahora: ahora)
        if decision == .mostrar, proveedor.presentar(alCerrar: { [weak self] in
            seguir()
            Task { await self?.precargar() }
        }) {
            registro = politica.anuncioMostrado(registro, ahora: ahora)
        } else {
            if decision == .no(.noCargado) { Task { await precargar() } }
            seguir()
        }
        guardarRegistro()
    }

    func abrirOpcionesPrivacidad() async {
        await proveedor.abrirOpcionesPrivacidad()
    }

    private func guardarRegistro() {
        almacen.guardar(valor: registro, Self.claveRegistro)
    }
}
