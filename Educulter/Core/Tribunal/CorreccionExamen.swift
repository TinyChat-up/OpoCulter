import Foundation

/// Resultado de un examen (`Nota orientativa`, nunca «oficial»; 05I §5).
struct ResultadoExamen: Codable, Sendable, Equatable {
    struct Pregunta: Codable, Sendable, Equatable {
        var indice: Int
        var area: String
        var competencia: String?
        /// 0…1 del valor de la pregunta (`nil` si está anulada: no puntúa).
        var puntuacion: Double?
        /// Corregida por la app (ítem cerrado o de cálculo) o autoevaluada.
        var automatica: Bool
        var peso: Double
    }

    var preguntas: [Pregunta]
    /// Nota sobre 10 por área («LEN», «MAT»).
    var notasArea: [String: Double]
    /// Nota sobre 10 sin la penalización.
    var nota: Double
    var penalizacion: Double
    /// «según las bases de 2026» o «orientativa (bases de 2026)».
    var etiquetaPenalizacion: String
    var ponderacionDocumentada: Bool
    var fecha: Date

    var notaFinal: Double { max(0, nota - penalizacion) }
    var apto: Bool { notaFinal >= 5 }

    /// Puntuación media por competencia (para el informe del tribunal).
    var porCompetencia: [String: Double] {
        var suma: [String: (Double, Int)] = [:]
        for p in preguntas {
            guard let c = p.competencia, let v = p.puntuacion else { continue }
            let s = suma[c] ?? (0, 0)
            suma[c] = (s.0 + v, s.1 + 1)
        }
        return suma.mapValues { $0.0 / Double($0.1) }
    }

    var fuertes: [String] { porCompetencia.filter { $0.value >= 0.75 }.keys.sorted() }
    var debiles: [String] { porCompetencia.filter { $0.value < 0.5 }.keys.sorted() }
}

/// Corrección de un examen entregado.
enum CorrectorExamen {
    static let sinPonderacion = "Ponderación no documentada: reparto igual"

    /// Área de cada pregunta.
    static func area(_ p: SesionExamen.Pregunta, datos: DatosTribunal) -> String {
        switch p {
        case .oficial(let e, let n): datos.examen(e)?.preguntas.first { $0.numero == n }?.area ?? "LEN"
        case .item(_, let area): area
        }
    }

    /// La pregunta se corrige sola (ítem cerrado del simulacro) o necesita autoevaluación (oficial,
    /// o recuerdo del simulacro). Las oficiales no traen clave estructurada (D-132).
    static func esAutomatica(_ p: SesionExamen.Pregunta, banco: BancoContenido) -> Bool {
        guard case .item(let id, _) = p, let item = banco.item(id: id) else { return false }
        return item.mecanica != .recuerdo
    }

    static func anulada(_ p: SesionExamen.Pregunta, datos: DatosTribunal) -> Bool {
        guard case .oficial(let e, let n) = p else { return false }
        return datos.examen(e)?.preguntas.first { $0.numero == n }?.esAnulada ?? false
    }

    /// Preguntas que el usuario tiene que autoevaluar (respondidas y no automáticas ni anuladas).
    static func pendientesDeAutoevaluar(_ s: SesionExamen, banco: BancoContenido) -> [Int] {
        s.preguntas.indices.filter { i in
            !esAutomatica(s.preguntas[i], banco: banco) && !anulada(s.preguntas[i], datos: banco.tribunal) && s.respondida(i)
        }
    }

    static func corregir(_ s: SesionExamen, banco: BancoContenido, fecha: Date) -> ResultadoExamen {
        let datos = banco.tribunal
        let examen = s.modo.examenId.flatMap(datos.examen)
        // Pesos: los de la convocatoria si constan; si no, reparto igual dentro de cada área (D-131).
        let documentada = examen?.pesos != nil
        var porArea: [String: [Int]] = [:]
        for i in s.preguntas.indices where !anulada(s.preguntas[i], datos: datos) {
            porArea[area(s.preguntas[i], datos: datos), default: []].append(i)
        }
        var preguntas: [ResultadoExamen.Pregunta] = []
        for (i, p) in s.preguntas.enumerated() {
            let a = area(p, datos: datos)
            let competencia: String?
            switch p {
            case .oficial(let e, let n): competencia = datos.competencia(examen: e, numero: n)
            case .item(let id, _): competencia = banco.item(id: id)?.competencia
            }
            if anulada(p, datos: datos) {
                preguntas.append(.init(indice: i, area: a, competencia: competencia, puntuacion: nil, automatica: true, peso: 0))
                continue
            }
            var peso = 1.0 / Double(max(porArea[a]?.count ?? 1, 1))
            if documentada, case .oficial(_, let n) = p, let q = examen?.preguntas.first(where: { $0.numero == n }),
               let pesos = examen?.pesos, let total = Optional(porArea[a]?.compactMap { idx -> Double? in
                   guard case .oficial(_, let m) = s.preguntas[idx], let qq = examen?.preguntas.first(where: { $0.numero == m }) else { return nil }
                   return pesos[qq.codigo]
               }.reduce(0, +) ?? 0), total > 0 {
                peso = (pesos[q.codigo] ?? 0) / total
            }
            let automatica = esAutomatica(p, banco: banco)
            var valor = 0.0
            if !s.respondida(i) {
                valor = 0
            } else if automatica, case .item(let id, _) = p, let item = banco.item(id: id), let r = s.respuestas[i]?.item {
                valor = Evaluador.evaluar(r, para: item).correcto ? 1 : 0
            } else {
                valor = s.autoevaluaciones[i]?.nivel.valor ?? 0
            }
            preguntas.append(.init(indice: i, area: a, competencia: competencia, puntuacion: valor, automatica: automatica, peso: peso))
        }
        var notasArea: [String: Double] = [:]
        for a in porArea.keys {
            notasArea[a] = preguntas.filter { $0.area == a }.reduce(0) { $0 + ($1.puntuacion ?? 0) * $1.peso } * 10
        }
        let nota = notasArea.isEmpty ? 0 : notasArea.values.reduce(0, +) / Double(notasArea.count)
        let palabras = s.autoevaluaciones.values.reduce(0) { $0 + $1.palabras }
        let tildes = s.autoevaluaciones.values.reduce(0) { $0 + $1.tildes }
        let aplica = examen?.penalizacionAplicable ?? true
        return ResultadoExamen(preguntas: preguntas, notasArea: notasArea, nota: nota,
                               penalizacion: Penalizacion.calcular(palabras: palabras, tildes: tildes, reglas: datos.reglas),
                               etiquetaPenalizacion: aplica ? "según las bases de 2026" : "orientativa (bases de 2026)",
                               ponderacionDocumentada: documentada, fecha: fecha)
    }
}
