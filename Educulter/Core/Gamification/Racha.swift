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
    /// Periodos del modo descanso (05E parte 2 §3.3): sus días no rompen la racha ni gastan protectores.
    var descanso: [PeriodoDescanso] = []

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
        let diasDescanso = ModoDescanso.dias(descanso, hasta: ayer)
        while dia <= ayer {
            reponerSiEsDiaUno(dia, config)
            if actual > 0, dia != ultimoDiaActivo, !diasDescanso.contains(dia) {
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

// MARK: - Modo descanso y meta semanal (05E parte 2 §3.3, D-105)

/// Periodo del modo descanso: desde `inicio` hasta `fin` (incluido) o, si sigue abierto, hasta hoy.
struct PeriodoDescanso: Codable, Sendable, Equatable {
    var inicio: DiaCivil
    var fin: DiaCivil?
}

/// Modo descanso: congela la racha y la meta semanal hasta 7 días por mes natural. Al gastar los 7
/// días del mes, el periodo abierto termina solo (y no revive el mes siguiente).
enum ModoDescanso {
    static let maxDiasMes = 7

    /// Días de descanso efectivos hasta `hoy` (incluido): los de los periodos, como mucho 7 por mes.
    static func dias(_ periodos: [PeriodoDescanso], hasta hoy: DiaCivil) -> Set<DiaCivil> {
        var dias = Set<DiaCivil>()
        var porMes: [Int: Int] = [:]
        for p in periodos.sorted(by: { $0.inicio < $1.inicio }) {
            var d = p.inicio
            let fin = min(p.fin ?? hoy, hoy)
            // Un periodo termina en cuanto agota el cupo del mes: no revive el mes siguiente.
            while d <= fin {
                let mes = d.anio * 100 + d.mes
                guard porMes[mes, default: 0] < maxDiasMes else { break }
                if dias.insert(d).inserted { porMes[mes, default: 0] += 1 }
                d = d.sumando(dias: 1)
            }
        }
        return dias
    }

    /// Días de descanso gastados en el mes de `hoy` (hasta hoy).
    static func usados(_ periodos: [PeriodoDescanso], mesDe hoy: DiaCivil) -> Int {
        dias(periodos, hasta: hoy).filter { $0.anio == hoy.anio && $0.mes == hoy.mes }.count
    }

    /// Días que quedan este mes (contando hoy si el modo está activo).
    static func disponibles(_ periodos: [PeriodoDescanso], hoy: DiaCivil) -> Int {
        max(0, maxDiasMes - usados(periodos, mesDe: hoy))
    }

    /// El modo está activo hoy: hay un periodo abierto y hoy es día de descanso.
    static func activo(_ periodos: [PeriodoDescanso], hoy: DiaCivil) -> Bool {
        guard let ultimo = periodos.last, ultimo.inicio <= hoy, (ultimo.fin ?? hoy) >= hoy else { return false }
        return dias(periodos, hasta: hoy).contains(hoy)
    }

    /// Activa el modo hoy (si quedan días este mes). Devuelve `false` si no se puede.
    static func activar(_ periodos: inout [PeriodoDescanso], hoy: DiaCivil) -> Bool {
        guard !activo(periodos, hoy: hoy) else { return true }
        cerrarAgotado(&periodos, hoy: hoy)
        guard disponibles(periodos, hoy: hoy) > 0 else { return false }
        periodos.append(PeriodoDescanso(inicio: hoy, fin: nil))
        return true
    }

    /// Desactiva el modo: el periodo abierto termina ayer (hoy ya no es descanso).
    static func desactivar(_ periodos: inout [PeriodoDescanso], hoy: DiaCivil) {
        guard let i = periodos.indices.last, periodos[i].fin == nil || periodos[i].fin! >= hoy else { return }
        let ayer = hoy.sumando(dias: -1)
        if periodos[i].inicio > ayer { periodos.remove(at: i) } else { periodos[i].fin = ayer }
    }

    /// Cierra el periodo abierto si ya no le quedan días (agotado el cupo del mes).
    static func cerrarAgotado(_ periodos: inout [PeriodoDescanso], hoy: DiaCivil) {
        guard let i = periodos.indices.last, periodos[i].fin == nil, !activo(periodos, hoy: hoy) else { return }
        let dias = dias(periodos, hasta: hoy)
        periodos[i].fin = dias.filter { $0 >= periodos[i].inicio }.max() ?? periodos[i].inicio.sumando(dias: -1)
        if periodos[i].fin! < periodos[i].inicio { periodos.remove(at: i) }
    }
}

/// Meta semanal: días con al menos una sesión completada, de lunes a domingo (3–7; por defecto 4).
struct MetaSemanal: Sendable, Equatable {
    static let rango = 3...7
    static let porDefecto = 4

    enum EstadoDia: String, Sendable, Equatable { case hecho, descanso, pendiente, futuro, sinSesion }

    struct Dia: Sendable, Equatable {
        var dia: DiaCivil
        var estado: EstadoDia
    }

    var meta: Int
    var dias: [Dia]

    var hechos: Int { dias.filter { $0.estado == .hecho }.count }
    /// Los días de descanso reducen la meta (congelada), sin bajar de 0.
    var metaEfectiva: Int { max(0, min(meta, 7 - dias.filter { $0.estado == .descanso }.count)) }
    var cumplida: Bool { hechos >= metaEfectiva }

    /// Semana (lunes a domingo) que contiene `hoy`.
    init(meta: Int, hoy: DiaCivil, diasSesion: Set<DiaCivil>, descanso: Set<DiaCivil>, calendario: Calendar) {
        self.meta = min(max(meta, Self.rango.lowerBound), Self.rango.upperBound)
        var gregoriano = Calendar(identifier: .gregorian)
        gregoriano.timeZone = calendario.timeZone
        let diaSemana = gregoriano.component(.weekday, from: hoy.fecha(calendario: gregoriano))  // 1 = domingo
        let lunes = hoy.sumando(dias: -((diaSemana + 5) % 7))
        dias = (0..<7).map { k in
            let d = lunes.sumando(dias: k)
            let estado: EstadoDia = diasSesion.contains(d) ? .hecho
                : descanso.contains(d) ? .descanso
                : d > hoy ? .futuro
                : d == hoy ? .pendiente : .sinSesion
            return Dia(dia: d, estado: estado)
        }
    }
}
