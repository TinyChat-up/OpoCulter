import Foundation

enum TipoMision: String, Codable, Sendable, CaseIterable {
    case rescatarErrores
    case repasarCompetencias
    case rondaLengua
    case rondaMatematicas
    case ortografiaExpres
    case combo
    case ganarXP
    case aciertosSinPista
}

struct Mision: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var tipo: TipoMision
    var objetivo: Int
    var progreso = 0

    var completada: Bool { progreso >= objetivo }

    /// Texto para la interfaz (español de España).
    var titulo: String {
        switch tipo {
        case .rescatarErrores: objetivo == 1 ? "Rescata 1 error" : "Rescata \(objetivo) errores"
        case .repasarCompetencias: objetivo == 1 ? "Repasa 1 competencia" : "Repasa \(objetivo) competencias"
        case .rondaLengua: "Completa 1 ronda de Lengua"
        case .rondaMatematicas: "Completa 1 ronda de Matemáticas"
        case .ortografiaExpres: "Haz una Ortografía exprés"
        case .combo: "Consigue un combo de \(objetivo)"
        case .ganarXP: "Gana \(objetivo) XP"
        case .aciertosSinPista: "Acierta \(objetivo) ítems sin pista"
        }
    }
}

/// Hechos que hacen avanzar las misiones.
enum EventoMision: Sendable, Equatable {
    /// Ronda terminada; `area` es la de la competencia en curso (`LEN`/`MAT`).
    case rondaCompletada(area: String?)
    case rescate
    case repaso
    case ortografiaExpres
    case combo(Int)
    case xp(Int)
    case aciertoSinPista
}

/// Estado del usuario del que dependen las misiones del día.
struct ContextoMisiones: Sendable, Equatable {
    var rescatesPendientes = 0
    var repasosVencidos = 0
    /// Proporción de competencias dominadas (0…1) por área.
    var dominioLengua = 0.0
    var dominioMatematicas = 0.0
}

/// Genera y actualiza las 3 misiones diarias.
enum GeneradorMisiones {
    static let cantidad = 3

    /// 1.ª misión: lo más urgente (Rescate o repasos); 2.ª: una ronda del área más débil;
    /// 3.ª y siguientes: variedad (ortografía, combo, XP, aciertos sin pista).
    static func generar(dia: DiaCivil, contexto: ContextoMisiones, rng: inout some RandomNumberGenerator) -> [Mision] {
        var tipos: [(TipoMision, Int)] = []
        if contexto.rescatesPendientes > 0 {
            tipos.append((.rescatarErrores, min(3, contexto.rescatesPendientes)))
        } else if contexto.repasosVencidos > 0 {
            tipos.append((.repasarCompetencias, min(3, contexto.repasosVencidos)))
        }
        let areaDebil: TipoMision
        if contexto.dominioLengua == contexto.dominioMatematicas {
            areaDebil = Bool.random(using: &rng) ? .rondaLengua : .rondaMatematicas
        } else {
            areaDebil = contexto.dominioLengua < contexto.dominioMatematicas ? .rondaLengua : .rondaMatematicas
        }
        tipos.append((areaDebil, 1))
        let variedad: [(TipoMision, Int)] = [(.ortografiaExpres, 1), (.combo, 5), (.ganarXP, 100), (.aciertosSinPista, 10)]
        for opcion in variedad.shuffled(using: &rng) where tipos.count < cantidad {
            tipos.append(opcion)
        }
        return tipos.enumerated().map { i, t in Mision(id: "\(dia.clave)-\(i + 1)", tipo: t.0, objetivo: t.1) }
    }

    /// Aplica un evento a las misiones. Devuelve las que se acaban de completar.
    @discardableResult
    static func registrar(_ evento: EventoMision, en misiones: inout [Mision]) -> [Mision] {
        var completadas: [Mision] = []
        for i in misiones.indices where !misiones[i].completada {
            switch (misiones[i].tipo, evento) {
            case (.rescatarErrores, .rescate), (.repasarCompetencias, .repaso),
                 (.ortografiaExpres, .ortografiaExpres), (.aciertosSinPista, .aciertoSinPista):
                misiones[i].progreso += 1
            case (.rondaLengua, .rondaCompletada(let area)) where area == "LEN":
                misiones[i].progreso += 1
            case (.rondaMatematicas, .rondaCompletada(let area)) where area == "MAT":
                misiones[i].progreso += 1
            case (.combo, .combo(let n)):
                misiones[i].progreso = max(misiones[i].progreso, n)
            case (.ganarXP, .xp(let n)):
                misiones[i].progreso += n
            default:
                break
            }
            if misiones[i].completada { completadas.append(misiones[i]) }
        }
        return completadas
    }
}
