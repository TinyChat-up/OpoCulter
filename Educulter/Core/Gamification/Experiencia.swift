import Foundation

struct ConfiguracionXP: Sendable, Equatable {
    var porAcierto = 10
    var bonusSinPista = 5
    var bonusJustifica = 10
    /// XP extra al rescatar un error (el diseño dice "Rescatar da XP extra").
    var bonusRescate = 5
    /// Incremento del multiplicador por cada acierto consecutivo a partir del segundo.
    var pasoCombo = 0.1
    var multiplicadorMaximo = 1.5

    static let estandar = ConfiguracionXP()
}

/// Cálculo de XP por respuesta.
enum CalculadoraXP {
    /// Multiplicador para una racha de `combo` aciertos seguidos (incluido el actual):
    /// 1 → ×1,0; 2 → ×1,1; … hasta ×1,5.
    static func multiplicador(combo: Int, config: ConfiguracionXP = .estandar) -> Double {
        guard combo > 1 else { return 1 }
        return min(1 + config.pasoCombo * Double(combo - 1), config.multiplicadorMaximo)
    }

    /// XP de una respuesta: 0 si es un fallo o si se usó pista; si no, 10 + 5 (sin pista)
    /// + 10 (peldaño 4, Justifica) + bonus de rescate, todo multiplicado por el combo.
    static func xp(correcto: Bool, usoPista: Bool, peldano: Int, combo: Int, esRescate: Bool = false,
                   config: ConfiguracionXP = .estandar) -> Int {
        guard correcto, !usoPista else { return 0 }
        var base = config.porAcierto + config.bonusSinPista
        if peldano == Peldano.justifica.rawValue { base += config.bonusJustifica }
        if esRescate { base += config.bonusRescate }
        return Int((Double(base) * multiplicador(combo: combo, config: config)).rounded(.toNearestOrAwayFromZero))
    }
}

/// Aciertos consecutivos dentro de una ronda.
struct ContadorCombo: Sendable, Equatable {
    private(set) var actual = 0
    private(set) var maximo = 0

    /// Registra una respuesta y devuelve el combo resultante (0 tras un fallo).
    @discardableResult
    mutating func registrar(correcto: Bool) -> Int {
        actual = correcto ? actual + 1 : 0
        maximo = max(maximo, actual)
        return actual
    }
}

/// Curva de niveles suave: XP acumulada para llegar al nivel n = base · (n − 1)^exponente.
/// Con los valores por defecto: nivel 2 = 100 XP, nivel 3 ≈ 283, nivel 5 = 800, nivel 10 = 2 700.
struct CurvaNiveles: Sendable, Equatable {
    var base: Double = 100
    var exponente: Double = 1.5
    var nivelMaximo = 100

    static let estandar = CurvaNiveles()

    func xpAcumulada(paraNivel nivel: Int) -> Int {
        guard nivel > 1 else { return 0 }
        return Int((base * pow(Double(nivel - 1), exponente)).rounded())
    }

    func nivel(xp: Int) -> Int {
        var n = 1
        while n < nivelMaximo, xp >= xpAcumulada(paraNivel: n + 1) { n += 1 }
        return n
    }

    /// Progreso dentro del nivel actual (0…1).
    func progreso(xp: Int) -> (nivel: Int, xpEnNivel: Int, xpParaSiguiente: Int, fraccion: Double) {
        let n = nivel(xp: xp)
        let inicio = xpAcumulada(paraNivel: n)
        guard n < nivelMaximo else { return (n, xp - inicio, 0, 1) }
        let tramo = xpAcumulada(paraNivel: n + 1) - inicio
        return (n, xp - inicio, tramo, tramo == 0 ? 1 : Double(xp - inicio) / Double(tramo))
    }
}
