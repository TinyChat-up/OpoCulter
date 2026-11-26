import Foundation

/// Paso de un ejemplo resuelto (05E parte 2 §5): una frase corta (≤ 60 caracteres), la operación con
/// su resultado intermedio y, en al menos un paso de cada ejemplo, el porqué (≤ 70 caracteres): la
/// razón, no la operación. Los resultados los calcula el generador con los datos del caso; ninguno se
/// escribe a mano.
struct PasoResuelto: Codable, Sendable, Equatable {
    var frase: String
    /// Lo que se ve resaltado: la operación y su resultado («0,15 × 240 = 36»).
    var resultado: String
    /// Solo el resultado intermedio («36»). El del último paso es la solución del ítem.
    var valor: String
    var porque: String?

    static let maxFrase = 60
    static let maxPorque = 70
    static let rangoPasos = 2...5
}

/// Construcción de pasos con resultados calculados.
enum Pasos {
    typealias A = AyudaMat

    /// Paso con operación: `resultado` = «expresión = valor».
    /// `valor` va sin separador de miles (se compara con la respuesta); `resultado`, como se lee.
    static func op(_ frase: String, _ expresion: String, _ valor: Racional, porque: String? = nil, euros: Bool = false) -> PasoResuelto {
        let v = euros ? A.euros(valor) : A.texto(valor)
        return PasoResuelto(frase: frase, resultado: "\(expresion) = \(v)", valor: FormatoNumero.numero(valor), porque: porque)
    }

    /// Paso sin operación (un dato, una lectura o una conclusión).
    static func dato(_ frase: String, _ resultado: String, valor: String? = nil, porque: String? = nil) -> PasoResuelto {
        PasoResuelto(frase: frase, resultado: resultado, valor: valor ?? resultado, porque: porque)
    }

    /// Último paso de un ítem que no es numérico: su valor es la solución tal como la describe la app.
    static func solucion(_ frase: String, payload: Payload, porque: String? = nil) -> PasoResuelto {
        let s = DescripcionSolucion.texto(payload)
        return PasoResuelto(frase: frase, resultado: s, valor: s, porque: porque)
    }
}

extension Muestra {
    /// La misma muestra con sus pasos y, si `porqueEnExplicacion` (Matemáticas), al final de la
    /// explicación la frase de porqué del primer paso que la tenga (si no la incluye ya).
    func conPasos(_ pasos: [PasoResuelto], porqueEnExplicacion: Bool = true) -> Muestra {
        var m = self
        m.pasos = pasos
        if porqueEnExplicacion, let porque = pasos.compactMap(\.porque).first, !m.explicacion.contains(porque) {
            let p = porque.prefix(1).uppercased() + porque.dropFirst()
            m.explicacion += (m.explicacion.hasSuffix(".") ? " " : ". ") + p + (p.hasSuffix(".") ? "" : ".")
        }
        return m
    }
}
