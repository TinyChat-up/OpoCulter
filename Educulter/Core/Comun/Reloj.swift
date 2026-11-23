import Foundation

/// Fuente de la hora actual. Se inyecta en todo el núcleo para que los tests sean deterministas.
protocol Reloj: Sendable {
    var ahora: Date { get }
}

/// Reloj real del sistema.
struct RelojSistema: Reloj {
    var ahora: Date { Date() }
}

/// Reloj con una hora fija (tests y previsualizaciones).
struct RelojFijo: Reloj {
    var ahora: Date
}

/// Generador pseudoaleatorio con semilla (SplitMix64). Reproducible en los tests;
/// en la app se siembra con un valor aleatorio del sistema.
struct GeneradorConSemilla: RandomNumberGenerator, Sendable {
    private var estado: UInt64

    init(semilla: UInt64) {
        estado = semilla
    }

    /// Generador sembrado con entropía del sistema.
    static func aleatorio() -> GeneradorConSemilla {
        var sistema = SystemRandomNumberGenerator()
        return GeneradorConSemilla(semilla: sistema.next())
    }

    mutating func next() -> UInt64 {
        estado &+= 0x9E37_79B9_7F4A_7C15
        var z = estado
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
