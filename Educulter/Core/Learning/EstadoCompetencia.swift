import Foundation

// MARK: - Escalera de dominio

struct ConfiguracionEscalera: Sendable, Equatable {
    /// Regla de subida: `aciertos` en los `ventana` últimos intentos del peldaño.
    struct Regla: Sendable, Equatable {
        var ventana: Int
        var aciertos: Int
    }

    var reglaGeneral = Regla(ventana: 5, aciertos: 4)
    /// Excepciones por peldaño (p. ej. el peldaño 1, que solo tiene 1–2 ítems guiados).
    var reglasPorPeldano: [Int: Regla] = [:]
    var peldanoMaximo = 5
    /// Una competencia está dominada cuando alcanza este peldaño (ha superado el 3 y el 4).
    var peldanoDominio = 5

    func regla(para peldano: Int) -> Regla {
        reglasPorPeldano[peldano] ?? reglaGeneral
    }

    static let estandar = ConfiguracionEscalera()
}

/// Posición de una competencia en la escalera de dominio.
struct EstadoEscalera: Codable, Sendable, Equatable {
    var peldano: Int = 1
    /// Resultados de los últimos intentos *en el peldaño actual* (el más reciente al final).
    var ventana: [Bool] = []

    func dominada(_ config: ConfiguracionEscalera = .estandar) -> Bool {
        peldano >= config.peldanoDominio
    }

    /// Registra un intento. Solo cuentan los ítems del peldaño actual; los repasos de
    /// peldaños inferiores no hacen subir. Devuelve `true` si se ha subido de peldaño.
    @discardableResult
    mutating func registrar(correcto: Bool, peldanoDelItem: Int, config: ConfiguracionEscalera = .estandar) -> Bool {
        guard peldanoDelItem == peldano, peldano < config.peldanoMaximo else { return false }
        let regla = config.regla(para: peldano)
        ventana.append(correcto)
        if ventana.count > regla.ventana { ventana.removeFirst(ventana.count - regla.ventana) }
        guard ventana.filter({ $0 }).count >= regla.aciertos else { return false }
        peldano += 1
        ventana = []
        return true
    }
}

// MARK: - Leitner

struct ConfiguracionLeitner: Sendable, Equatable {
    /// Días hasta el siguiente repaso según la caja (caja 1 → intervalos[0]).
    var intervalos = [1, 3, 7, 14, 30]
    var subidaPorAcierto = 1
    var bajadaPorFallo = 2

    var cajaMaxima: Int { intervalos.count }

    func intervalo(caja: Int) -> Int {
        intervalos[min(max(caja, 1), cajaMaxima) - 1]
    }

    static let estandar = ConfiguracionLeitner()
}

/// Caja de Leitner de una competencia. Las fechas son días civiles del usuario.
struct EstadoLeitner: Codable, Sendable, Equatable {
    var caja: Int
    var proximoRepaso: DiaCivil
    var ultimoRepaso: DiaCivil?

    /// Estado al practicar la competencia por primera vez: caja 1, repaso al día siguiente.
    static func inicial(hoy: DiaCivil, config: ConfiguracionLeitner = .estandar) -> EstadoLeitner {
        EstadoLeitner(caja: 1, proximoRepaso: hoy.sumando(dias: config.intervalo(caja: 1)), ultimoRepaso: nil)
    }

    func vencido(hoy: DiaCivil) -> Bool {
        hoy >= proximoRepaso
    }

    /// Aplica el resultado de un repaso. Solo cuenta el primer intento de un día en que la
    /// competencia está vencida; el resto de intentos no mueven la caja (si no, una sola
    /// ronda subiría la competencia hasta la caja 5). Devuelve `true` si se ha aplicado.
    @discardableResult
    mutating func registrarRepaso(correcto: Bool, hoy: DiaCivil, config: ConfiguracionLeitner = .estandar) -> Bool {
        guard vencido(hoy: hoy), ultimoRepaso != hoy else { return false }
        caja = correcto
            ? min(caja + config.subidaPorAcierto, config.cajaMaxima)
            : max(caja - config.bajadaPorFallo, 1)
        proximoRepaso = hoy.sumando(dias: config.intervalo(caja: caja))
        ultimoRepaso = hoy
        return true
    }
}

// MARK: - Estado completo por competencia

/// Configuración conjunta del motor de aprendizaje.
struct ConfiguracionAprendizaje: Sendable, Equatable {
    var escalera = ConfiguracionEscalera.estandar
    var leitner = ConfiguracionLeitner.estandar

    static let estandar = ConfiguracionAprendizaje()
}

/// Progreso del usuario en una competencia: peldaño y caja de repaso.
struct EstadoCompetencia: Codable, Sendable, Equatable, Identifiable {
    var competenciaId: String
    var escalera = EstadoEscalera()
    /// `nil` hasta el primer intento.
    var leitner: EstadoLeitner?

    var id: String { competenciaId }

    init(competenciaId: String, escalera: EstadoEscalera = EstadoEscalera(), leitner: EstadoLeitner? = nil) {
        self.competenciaId = competenciaId
        self.escalera = escalera
        self.leitner = leitner
    }

    /// Cambios producidos por un intento.
    struct Cambios: Sendable, Equatable {
        var subioPeldano = false
        var repasoAplicado = false
        var acabaDeDominarse = false
    }

    /// Actualiza escalera y Leitner con el resultado de un ítem de esta competencia.
    @discardableResult
    mutating func registrar(correcto: Bool, peldanoDelItem: Int, hoy: DiaCivil,
                            config: ConfiguracionAprendizaje = .estandar) -> Cambios {
        var cambios = Cambios()
        let antes = escalera.dominada(config.escalera)
        cambios.subioPeldano = escalera.registrar(correcto: correcto, peldanoDelItem: peldanoDelItem, config: config.escalera)
        cambios.acabaDeDominarse = !antes && escalera.dominada(config.escalera)
        if leitner == nil {
            leitner = .inicial(hoy: hoy, config: config.leitner)
        } else {
            cambios.repasoAplicado = leitner?.registrarRepaso(correcto: correcto, hoy: hoy, config: config.leitner) ?? false
        }
        return cambios
    }

    func vencida(hoy: DiaCivil) -> Bool {
        leitner?.vencido(hoy: hoy) ?? false
    }
}
