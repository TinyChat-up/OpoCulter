import Foundation

/// Valor de un parámetro de plantilla en JSON: número, texto, lista o rango `{"min":…, "max":…}`.
enum ParametroJSON: Codable, Sendable, Equatable {
    case numero(Double)
    case texto(String)
    case booleano(Bool)
    case lista([ParametroJSON])
    case rango(min: Double, max: Double)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .booleano(b); return }
        if let n = try? c.decode(Double.self) { self = .numero(n); return }
        if let s = try? c.decode(String.self) { self = .texto(s); return }
        if let l = try? c.decode([ParametroJSON].self) { self = .lista(l); return }
        let r = try c.decode([String: Double].self)
        guard let min = r["min"], let max = r["max"] else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "rango sin min o max")
        }
        self = .rango(min: min, max: max)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .numero(let n): try c.encode(n)
        case .texto(let s): try c.encode(s)
        case .booleano(let b): try c.encode(b)
        case .lista(let l): try c.encode(l)
        case .rango(let min, let max): try c.encode(["min": min, "max": max])
        }
    }

    var textos: [String]? {
        switch self {
        case .texto(let s): [s]
        case .lista(let l): l.compactMap { if case .texto(let s) = $0 { s } else { nil } }
        default: nil
        }
    }

    var enteros: [Int]? {
        switch self {
        case .numero(let n): [Int(n)]
        case .lista(let l): l.compactMap { if case .numero(let n) = $0 { Int(n) } else { nil } }
        case .rango(let a, let b): a <= b ? Array(Int(a)...Int(b)) : nil
        default: nil
        }
    }
}

/// Plantilla de generador (`Content/plantillas/<bloque>.json`). Declara qué generador de código
/// la implementa (`tipo`), en qué mecánica, con qué parámetros y con qué redacciones.
///
/// - `enunciados`: varias redacciones con marcadores `{{nombre}}` que rellena el generador
///   (cada generador declara los suyos en `marcadores`); el motor elige una con la semilla.
/// - `contextos`: redacciones opcionales de contexto (problemas); se elige una con la semilla y
///   se expone como `{{contexto}}`, con sus propios marcadores ya rellenados.
/// - `parametros`: restringen o amplían lo que el generador usa por defecto para su dificultad.
struct Plantilla: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var competencia: String
    var peldano: Int
    /// 1–6 (6 = "Experto", por encima del examen).
    var dificultad: Int
    var mecanica: Mecanica
    var tipo: String
    var objetivo: String?
    var parametros: [String: ParametroJSON]
    var enunciados: [String]
    var contextos: [String]?
    var pistas: [String]?
    var procedencia: Procedencia
    var validacion: Validacion
    var version: Int

    init(id: String, competencia: String, peldano: Int, dificultad: Int, mecanica: Mecanica, tipo: String,
         objetivo: String? = nil, parametros: [String: ParametroJSON] = [:], enunciados: [String],
         contextos: [String]? = nil, pistas: [String]? = nil,
         procedencia: Procedencia = Procedencia(tipo: .original, licencia: "propia"),
         validacion: Validacion = Validacion(estado: .borrador), version: Int = 1) {
        self.id = id
        self.competencia = competencia
        self.peldano = peldano
        self.dificultad = dificultad
        self.mecanica = mecanica
        self.tipo = tipo
        self.objetivo = objetivo
        self.parametros = parametros
        self.enunciados = enunciados
        self.contextos = contextos
        self.pistas = pistas
        self.procedencia = procedencia
        self.validacion = validacion
        self.version = version
    }

    private enum CodingKeys: String, CodingKey {
        case id, competencia, peldano, dificultad, mecanica, tipo, objetivo, parametros, enunciados, contextos,
             pistas, procedencia, validacion, version
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        competencia = try c.decode(String.self, forKey: .competencia)
        peldano = try c.decode(Int.self, forKey: .peldano)
        dificultad = try c.decode(Int.self, forKey: .dificultad)
        mecanica = try c.decode(Mecanica.self, forKey: .mecanica)
        tipo = try c.decode(String.self, forKey: .tipo)
        objetivo = try c.decodeIfPresent(String.self, forKey: .objetivo)
        parametros = try c.decodeIfPresent([String: ParametroJSON].self, forKey: .parametros) ?? [:]
        enunciados = try c.decode([String].self, forKey: .enunciados)
        contextos = try c.decodeIfPresent([String].self, forKey: .contextos)
        pistas = try c.decodeIfPresent([String].self, forKey: .pistas)
        procedencia = try c.decode(Procedencia.self, forKey: .procedencia)
        validacion = try c.decode(Validacion.self, forKey: .validacion)
        version = try c.decode(Int.self, forKey: .version)
    }

    /// Lista de textos de un parámetro (o `porDefecto`).
    func textos(_ nombre: String, porDefecto: [String]) -> [String] {
        parametros[nombre]?.textos.flatMap { $0.isEmpty ? nil : $0 } ?? porDefecto
    }

    /// Lista de enteros de un parámetro (o `porDefecto`).
    func enteros(_ nombre: String, porDefecto: [Int]) -> [Int] {
        parametros[nombre]?.enteros.flatMap { $0.isEmpty ? nil : $0 } ?? porDefecto
    }
}

/// Marcadores `{{nombre}}` de un texto, en orden de aparición.
enum Marcadores {
    static func en(_ texto: String) -> [String] {
        var resultado: [String] = []
        var resto = Substring(texto)
        while let abre = resto.range(of: "{{") {
            let tras = resto[abre.upperBound...]
            guard let cierra = tras.range(of: "}}") else { break }
            resultado.append(String(tras[..<cierra.lowerBound]))
            resto = tras[cierra.upperBound...]
        }
        return resultado
    }

    /// Sustituye los marcadores por sus valores. Los que no tienen valor se dejan tal cual
    /// (el test de plantillas los detecta).
    static func rellenar(_ texto: String, con valores: [String: String]) -> String {
        var t = texto
        for (clave, valor) in valores { t = t.replacingOccurrences(of: "{{\(clave)}}", with: valor) }
        return t
    }
}
