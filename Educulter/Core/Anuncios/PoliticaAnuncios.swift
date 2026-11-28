import Foundation

/// Momento en que la app podría mostrar un anuncio. Solo `continuarTrasRonda` lo permite.
enum MomentoAnuncio: Sendable, Equatable {
    /// El usuario pulsa «Continuar» en el resultado de una ronda terminada.
    case continuarTrasRonda
    /// Cualquier pantalla del Tribunal (incluidas las rondas de «Por bloques»).
    case tribunal
    case aperturaApp, mitadRonda, bienvenida, diagnostico
}

/// Registro persistente de los anuncios: primera apertura, rondas desde el último y los del día.
struct RegistroAnuncios: Codable, Sendable, Equatable {
    /// Día natural de la primera apertura (clave `AAAAMMDD`).
    var primeraApertura: Int
    /// Rondas terminadas (que cuentan) desde el último anuncio.
    var rondasDesdeUltimo = 0
    /// Día natural del contador diario y anuncios mostrados ese día.
    var dia: Int?
    var anunciosDia = 0

    init(primeraApertura: DiaCivil) {
        self.primeraApertura = primeraApertura.clave
    }
}

/// Situación del dispositivo y del SDK en el momento de decidir.
struct EntornoAnuncio: Sendable, Equatable {
    var premium: Bool
    /// Hay conexión a internet.
    var conectado: Bool
    /// UMP permite pedir anuncios (`canRequestAds`).
    var consentimiento: Bool
    /// Los identificadores son válidos para esta compilación (en Release, no `PENDIENTE`).
    var identificadores: Bool
    /// Hay un intersticial cargado y listo.
    var cargado: Bool
}

/// Política de anuncios de la versión gratuita (fase 06 §2.2). Pura: la fecha, el calendario y el
/// estado se inyectan.
///
/// - Nunca para Premium.
/// - Nunca los 2 primeros días naturales desde la primera apertura (desde el día 3, sí).
/// - Solo al pulsar «Continuar» en el resultado de una ronda terminada; nunca al abrir la app, a
///   mitad de ronda, en la bienvenida ni en el Tribunal.
/// - Uno cada 2 rondas terminadas desde el último (solo cuentan las rondas del día 3 en adelante).
/// - Como mucho 4 al día (día natural, zona horaria del dispositivo).
/// - Sin conexión, sin consentimiento o con identificadores pendientes, ninguno.
/// - Si no está cargado, no se espera: se sigue sin anuncio (y la ronda sigue contando).
struct PoliticaAnuncios: Sendable {
    static let diasDeGracia = 2
    static let rondasPorAnuncio = 2
    static let maximoDiario = 4

    var calendario: Calendar = .current

    enum Decision: Sendable, Equatable {
        case mostrar
        case no(Motivo)
    }

    enum Motivo: Sendable, Equatable {
        case premium, diasDeGracia, momento, faltanRondas, maximoDiario, sinConexion, sinConsentimiento, identificadores, noCargado
    }

    /// Día natural de uso desde la primera apertura (la primera apertura es el día 1).
    func diaDeUso(_ registro: RegistroAnuncios, ahora: Date) -> Int {
        guard let inicio = DiaCivil(clave: registro.primeraApertura) else { return 1 }
        return inicio.dias(hasta: DiaCivil(ahora, calendario: calendario)) + 1
    }

    /// Ya han pasado los días de gracia (desde el día 3).
    func fueraDeGracia(_ registro: RegistroAnuncios, ahora: Date) -> Bool {
        diaDeUso(registro, ahora: ahora) > Self.diasDeGracia
    }

    func anunciosHoy(_ registro: RegistroAnuncios, ahora: Date) -> Int {
        registro.dia == DiaCivil(ahora, calendario: calendario).clave ? registro.anunciosDia : 0
    }

    /// Una ronda terminada: cuenta para el siguiente anuncio si ya pueden salir anuncios.
    func rondaTerminada(_ registro: RegistroAnuncios, premium: Bool, ahora: Date) -> RegistroAnuncios {
        guard !premium, fueraDeGracia(registro, ahora: ahora) else { return registro }
        var r = registro
        r.rondasDesdeUltimo += 1
        return r
    }

    /// ¿Se muestra un anuncio ahora? Se llama después de `rondaTerminada`.
    func decidir(_ momento: MomentoAnuncio, registro: RegistroAnuncios, entorno: EntornoAnuncio, ahora: Date) -> Decision {
        if entorno.premium { return .no(.premium) }
        guard momento == .continuarTrasRonda else { return .no(.momento) }
        guard fueraDeGracia(registro, ahora: ahora) else { return .no(.diasDeGracia) }
        guard registro.rondasDesdeUltimo >= Self.rondasPorAnuncio else { return .no(.faltanRondas) }
        guard anunciosHoy(registro, ahora: ahora) < Self.maximoDiario else { return .no(.maximoDiario) }
        guard entorno.identificadores else { return .no(.identificadores) }
        guard entorno.conectado else { return .no(.sinConexion) }
        guard entorno.consentimiento else { return .no(.sinConsentimiento) }
        guard entorno.cargado else { return .no(.noCargado) }
        return .mostrar
    }

    /// Un anuncio mostrado: el contador de rondas vuelve a 0 y suma uno al día.
    func anuncioMostrado(_ registro: RegistroAnuncios, ahora: Date) -> RegistroAnuncios {
        var r = registro
        let hoy = DiaCivil(ahora, calendario: calendario).clave
        r.anunciosDia = (r.dia == hoy ? r.anunciosDia : 0) + 1
        r.dia = hoy
        r.rondasDesdeUltimo = 0
        return r
    }

    /// El consentimiento (UMP) y el SDK solo se preparan cuando ya pueden salir anuncios.
    func prepararConsentimiento(_ registro: RegistroAnuncios, premium: Bool, ahora: Date) -> Bool {
        !premium && fueraDeGracia(registro, ahora: ahora)
    }
}
