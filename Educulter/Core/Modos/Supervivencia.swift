import Foundation

/// Reglas de Supervivencia (D-069). Sin cronómetro, por accesibilidad.
struct ReglasSupervivencia: Sendable, Equatable {
    var vidas = 3
    var dificultadInicial = 1
    var dificultadMaxima = 6
    /// Aciertos seguidos para subir un nivel.
    var aciertosParaSubir = 4
    var puntosBase = 10
    /// Multiplicador del combo: +0,25 por acierto seguido a partir del segundo, hasta ×2.
    var incrementoCombo = 0.25
    var multiplicadorMaximo = 2.0

    static let estandar = ReglasSupervivencia()

    func multiplicador(combo: Int) -> Double {
        min(multiplicadorMaximo, 1 + incrementoCombo * Double(max(combo - 1, 0)))
    }

    /// Puntos de un acierto: `10 × dificultad`, con el multiplicador del combo (redondeo al entero).
    func puntos(dificultad: Int, combo: Int) -> Int {
        Int((Double(puntosBase * dificultad) * multiplicador(combo: combo)).rounded())
    }
}

/// Estado de una partida en curso. Puro: no sabe de ítems ni de persistencia.
struct EstadoSupervivencia: Sendable, Equatable {
    let reglas: ReglasSupervivencia
    private(set) var vidas: Int
    private(set) var dificultad: Int
    private(set) var nivelMaximo: Int
    /// Aciertos seguidos en el nivel actual (para subir).
    private(set) var rachaNivel = 0
    private(set) var combo = 0
    private(set) var puntos = 0
    private(set) var aciertos = 0
    private(set) var fallos = 0

    init(reglas: ReglasSupervivencia = .estandar) {
        self.reglas = reglas
        vidas = reglas.vidas
        dificultad = reglas.dificultadInicial
        nivelMaximo = reglas.dificultadInicial
    }

    var terminada: Bool { vidas <= 0 }

    /// Registra una respuesta a un ítem de la dificultad actual y devuelve los puntos ganados.
    /// Acierto: suma puntos y, cada 4 seguidos, sube un nivel (máx. 6). Fallo: resta una vida y
    /// baja un nivel (mín. 1); el combo y la racha de nivel vuelven a 0.
    @discardableResult
    mutating func responder(correcto: Bool) -> Int {
        guard !terminada else { return 0 }
        if correcto {
            combo += 1
            aciertos += 1
            let ganados = reglas.puntos(dificultad: dificultad, combo: combo)
            puntos += ganados
            rachaNivel += 1
            if rachaNivel >= reglas.aciertosParaSubir {
                dificultad = min(dificultad + 1, reglas.dificultadMaxima)
                nivelMaximo = max(nivelMaximo, dificultad)
                rachaNivel = 0
            }
            return ganados
        }
        fallos += 1
        vidas -= 1
        combo = 0
        rachaNivel = 0
        dificultad = max(dificultad - 1, reglas.dificultadInicial)
        return 0
    }
}

/// Pesos de los bloques en Supervivencia, derivados de la MATRIZ de exámenes oficiales
/// (docs/examenes/MATRIZ.md, 7 cuadernillos 2017–2026): número de preguntas del bloque.
/// El peso efectivo se multiplica por la debilidad del usuario (`0,5 + debilidad`, de 0,5 a 1,5).
enum PesosSupervivencia {
    static let frecuenciaExamen: [String: Int] = [
        "LEN.LIT": 14, "LEN.COM": 12, "LEN.LEX": 10, "LEN.SIN": 7, "LEN.VER": 6, "LEN.REC": 6,
        "LEN.CLA": 5, "LEN.ORT": 4, "LEN.FOR": 4, "LEN.MET": 1,
        "MAT.NUM": 13, "MAT.OPE": 12, "MAT.GEO": 10, "MAT.POR": 8, "MAT.UNI": 8, "MAT.EST": 7,
        "MAT.ROM": 4, "MAT.DIV": 4, "MAT.PRO": 4,
    ]

    /// Peso del bloque en el examen dentro de su área (suma 1 por área).
    static func pesoExamen(_ bloque: String) -> Double {
        let area = Catalogo.area(de: bloque)
        let total = frecuenciaExamen.filter { Catalogo.area(de: $0.key) == area }.values.reduce(0, +)
        return Double(frecuenciaExamen[bloque] ?? 1) / Double(max(total, 1))
    }

    static func peso(_ bloque: String, debilidad: Double) -> Double {
        pesoExamen(bloque) * (0.5 + min(max(debilidad, 0), 1))
    }
}

/// Elige el siguiente ítem de Supervivencia: bloque por peso (examen × debilidad) y, dentro del
/// bloque, un ítem de la dificultad actual. Los generados se piden exactamente a esa dificultad
/// (`<plantilla>@dN#semilla`); los estáticos (peldaño ≥ 2) se usan si tienen esa dificultad y,
/// si no hay ninguna fuente exacta, el estático más cercano.
struct SelectorSupervivencia: Sendable {
    let banco: BancoContenido

    /// Bloques con contenido para Supervivencia en un área (`nil`: las dos).
    func bloques(area: String?) -> [String] {
        banco.catalogo.todosLosBloques.map(\.id).filter { b in
            (area == nil || Catalogo.area(de: b) == area) && (!estaticos(b).isEmpty || !plantillas(b).isEmpty)
        }
    }

    func estaticos(_ bloque: String) -> [Item] {
        banco.itemsEstaticos.filter { $0.peldano >= 2 && banco.catalogo.bloque(deCompetencia: $0.competencia)?.id == bloque }
    }

    func plantillas(_ bloque: String) -> [Plantilla] {
        banco.plantillas.filter { banco.catalogo.bloque(deCompetencia: $0.competencia)?.id == bloque }
    }

    /// Debilidad de cada bloque (0 fuerte … 1 débil): peldaño medio de sus competencias con
    /// estado; si no hay, el último diagnóstico; si tampoco, 0,5.
    func debilidades(estados: [String: EstadoCompetencia], diagnostico: ResultadoDiagnostico?) -> [String: Double] {
        var r: [String: Double] = [:]
        for b in banco.catalogo.todosLosBloques {
            let conEstado = b.competencias.compactMap { estados[$0.id] }
            if !conEstado.isEmpty {
                let medio = conEstado.map { Double($0.escalera.peldano - 1) / 4 }.reduce(0, +) / Double(conEstado.count)
                r[b.id] = 1 - medio
            } else if let n = diagnostico?.niveles.first(where: { $0.bloqueId == b.id }) {
                r[b.id] = 1 - n.nivel
            } else {
                r[b.id] = 0.5
            }
        }
        return r
    }

    func siguiente(dificultad: Int, area: String?, debilidades: [String: Double], usados: Set<String>,
                   rng: inout GeneradorConSemilla) -> Item? {
        let disponibles = bloques(area: area)
        guard !disponibles.isEmpty else { return nil }
        let pesos = disponibles.map { PesosSupervivencia.peso($0, debilidad: debilidades[$0] ?? 0.5) }
        var tirada = Double.random(in: 0..<pesos.reduce(0, +), using: &rng)
        var bloque = disponibles[0]
        for (b, w) in zip(disponibles, pesos) {
            if tirada < w { bloque = b; break }
            tirada -= w
        }
        // Fuentes exactas: estáticos de esa dificultad no usados y plantillas del bloque.
        let exactos = estaticos(bloque).filter { $0.dificultad == dificultad && !usados.contains($0.id) }
        let fuentes = plantillas(bloque)
        let total = exactos.count + fuentes.count
        if total > 0 {
            let k = Int.random(in: 0..<total, using: &rng)
            if k < exactos.count { return exactos[k] }
            let p = MotorGeneradores.ajustada(fuentes[k - exactos.count], dificultad: dificultad)
            for _ in 0..<10 {
                let semilla = UInt64.random(in: 0...999_999, using: &rng)
                if let item = try? MotorGeneradores.generar(p, semilla: semilla, recursos: banco.recursos), !usados.contains(item.id) {
                    return item
                }
            }
        }
        // Sin fuente exacta: el estático no usado de dificultad más cercana.
        let resto = estaticos(bloque).filter { !usados.contains($0.id) }
        guard let cercania = resto.map({ abs($0.dificultad - dificultad) }).min() else {
            return estaticos(bloque).randomElement(using: &rng)
        }
        return resto.filter { abs($0.dificultad - dificultad) == cercania }.randomElement(using: &rng)
    }
}
