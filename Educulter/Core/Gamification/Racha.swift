import Foundation

struct ConfiguracionRacha: Sendable, Equatable {
    /// Protectores que se reponen el día 1 de cada mes (se rellena hasta este número).
    var protectoresMensuales = 2
    /// Tope de protectores acumulados.
    var maxProtectores = 3
    /// Días activos seguidos que cuentan como "semana completa" (+1 protector).
    var diasSemanaCompleta = 7

    static let estandar = ConfiguracionRacha()
}

/// Racha diaria: se mantiene con al menos 1 ronda al día.
///
/// Los días se procesan de uno en uno al cerrarse, de modo que el resultado no depende de
/// cuántas veces se consulte la racha. Un día cerrado sin actividad consume un protector;
/// si no quedan, la racha se rompe. El día 1 de cada mes se reponen los protectores hasta
/// `protectoresMensuales` (sin quitar los que ya se tuvieran), y cada semana completa de
/// actividad suma uno más, hasta `maxProtectores`.
struct EstadoRacha: Codable, Sendable, Equatable {
    var actual = 0
    var record = 0
    var protectores = 2
    var ultimoDiaActivo: DiaCivil?
    /// Último día ya cerrado y evaluado.
    var ultimoDiaProcesado: DiaCivil?

    init(actual: Int = 0, record: Int = 0, protectores: Int = ConfiguracionRacha.estandar.protectoresMensuales,
         ultimoDiaActivo: DiaCivil? = nil, ultimoDiaProcesado: DiaCivil? = nil) {
        self.actual = actual
        self.record = record
        self.protectores = protectores
        self.ultimoDiaActivo = ultimoDiaActivo
        self.ultimoDiaProcesado = ultimoDiaProcesado
    }

    struct Cambios: Sendable, Equatable {
        var protectoresUsados = 0
        /// Valor de la racha que se ha perdido, si se ha roto.
        var rachaPerdida: Int?
        var incrementada = false
        var protectorGanado = false
        var nuevoRecord = false
    }

    /// Cierra los días anteriores a `hoy` que falten por procesar.
    @discardableResult
    mutating func avanzar(hasta hoy: DiaCivil, config: ConfiguracionRacha = .estandar) -> Cambios {
        var cambios = Cambios()
        let ayer = hoy.sumando(dias: -1)
        guard let procesado = ultimoDiaProcesado else {
            ultimoDiaProcesado = ayer
            return cambios
        }
        var dia = procesado.sumando(dias: 1)
        while dia <= ayer {
            reponerSiEsDiaUno(dia, config)
            if actual > 0, dia != ultimoDiaActivo {
                if protectores > 0 {
                    protectores -= 1
                    cambios.protectoresUsados += 1
                } else {
                    cambios.rachaPerdida = actual
                    actual = 0
                }
            }
            dia = dia.sumando(dias: 1)
        }
        if procesado < ayer { ultimoDiaProcesado = ayer }
        reponerSiEsDiaUno(hoy, config)
        return cambios
    }

    /// Registra una ronda completada hoy.
    @discardableResult
    mutating func registrarRonda(hoy: DiaCivil, config: ConfiguracionRacha = .estandar) -> Cambios {
        var cambios = avanzar(hasta: hoy, config: config)
        if let activo = ultimoDiaActivo, hoy <= activo { return cambios }
        actual += 1
        ultimoDiaActivo = hoy
        cambios.incrementada = true
        if actual > record {
            record = actual
            cambios.nuevoRecord = true
        }
        if actual % config.diasSemanaCompleta == 0, protectores < config.maxProtectores {
            protectores += 1
            cambios.protectorGanado = true
        }
        return cambios
    }

    /// Racha que se mostraría hoy (sin modificar el estado guardado).
    func vigente(hoy: DiaCivil, config: ConfiguracionRacha = .estandar) -> EstadoRacha {
        var copia = self
        copia.avanzar(hasta: hoy, config: config)
        return copia
    }

    private mutating func reponerSiEsDiaUno(_ dia: DiaCivil, _ config: ConfiguracionRacha) {
        if dia.dia == 1 { protectores = max(protectores, config.protectoresMensuales) }
    }
}
