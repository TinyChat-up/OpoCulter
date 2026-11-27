import Foundation

/// Frases de tilde en contexto del lote 06 (`Content/tildeContexto.json`): para cada palabra que
/// solo se distingue por la tilde, sus variantes con su categoría y las frases de la dirección.
struct BancoTildeContexto: Codable, Sendable, Equatable {
    struct Variante: Codable, Sendable, Equatable {
        var forma: String
        var categoria: String
    }

    struct Frase: Codable, Sendable, Equatable {
        /// Frase con el hueco «___».
        var frase: String
        var correcta: String
        /// La correcta y las demás formas de la lista de la palabra.
        var opciones: [String]
        var notaDireccion: String?
    }

    struct Palabra: Codable, Sendable, Equatable {
        var palabra: String
        var categoria: String
        var variantes: [Variante]
        var frases: [Frase]?

        /// Formas de la palabra (la palabra y sus variantes) con su categoría.
        var formas: [(forma: String, categoria: String)] { [(palabra, categoria)] + variantes.map { ($0.forma, $0.categoria) } }
        func categoria(de forma: String) -> String? { formas.first { $0.forma == forma }?.categoria }
    }

    var version: Int
    var nota: String?
    var palabras: [Palabra]
}

/// LEN.ORT.CTX «Tilde que cambia el significado» (05J, lote 06): elegir la forma correcta en una
/// frase con contexto. Dificultad 2: frase de la palabra principal; 3: frase de una variante;
/// 4: «rio» y «frio» (monosílabos ortográficos sin tilde). Los distractores son siempre formas de la
/// misma palabra.
struct GeneradorTildeContexto: GeneradorItems {
    let tipo = "tildeContexto"
    let mecanicas: Set<Mecanica> = [.eleccion]
    let marcadores: Set<String> = ["frase"]

    /// Formas verbales que la Ortografía de 2010 escribe sin tilde por ser monosílabos ortográficos.
    static let monosilabos: Set<String> = ["rio", "frio"]

    struct Caso: Sendable, Equatable {
        var id: String
        var palabra: BancoTildeContexto.Palabra
        var frase: BancoTildeContexto.Frase
        var dificultad: Int
    }

    static func casos(_ banco: BancoTildeContexto) -> [Caso] {
        banco.palabras.flatMap { p in
            (p.frases ?? []).enumerated().map { n, f in
                let d = monosilabos.contains(f.correcta.lowercased()) ? 4 : (f.correcta.lowercased() == p.palabra.lowercased() ? 2 : 3)
                return Caso(id: "CTX.\(p.palabra).\(n + 1)", palabra: p, frase: f, dificultad: d)
            }
        }
    }

    /// Los casos del nivel pedido; si no hay, los del nivel inferior más cercano; y si no, los del
    /// nivel más fácil que haya (para que la dificultad no decrezca con el nivel).
    func casos(_ p: Plantilla, _ banco: BancoTildeContexto) -> [Caso] {
        let todos = Self.casos(banco)
        for d in stride(from: p.dificultad, through: 1, by: -1) {
            let de = todos.filter { $0.dificultad == d }
            if !de.isEmpty { return de }
        }
        guard let minimo = todos.map(\.dificultad).min() else { return [] }
        return todos.filter { $0.dificultad == minimo }
    }

    static func tieneTilde(_ s: String) -> Bool { s.contains { "áéíóúÁÉÍÓÚ".contains($0) } }

    /// «Lleva tilde porque…» o «No lleva tilde porque…», según la categoría de la forma correcta.
    static func explicacion(_ c: Caso) -> String {
        let f = c.frase
        let otras = f.opciones.filter { $0 != f.correcta }
        let contraste = otras.map { "«\($0)» es \(c.palabra.categoria(de: $0) ?? "otra palabra")" }.joined(separator: "; ")
        if monosilabos.contains(f.correcta.lowercased()) {
            return "No lleva tilde porque «\(f.correcta)» es un monosílabo ortográfico: «rio» y «frio» se escriben sin tilde (RAE, Ortografía, 2010). En cambio, \(contraste)."
        }
        let categoria = c.palabra.categoria(de: f.correcta) ?? c.palabra.categoria
        return "\(tieneTilde(f.correcta) ? "Lleva tilde" : "No lleva tilde") porque aquí «\(f.correcta)» es \(categoria). En cambio, \(contraste)."
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let banco = recursos.tildeContexto else { throw ErrorGenerador.sinRecursos(tipo) }
        let lista = casos(p, banco)
        guard !lista.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let c = rng.elemento(lista)
        let f = c.frase
        let distractores = f.opciones.filter { $0 != f.correcta }.map { o in
            (texto: o, feedback: "«\(o)» es \(c.palabra.categoria(de: o) ?? "otra palabra"). Aquí va «\(f.correcta)».")
        }
        let (e, errores) = Opciones.eleccion(correcta: f.correcta, distractores: distractores, maximo: 4, rng: &rng)
        return Muestra(clave: "\(c.id)|eleccion", valores: ["frase": f.frase.replacingOccurrences(of: "___", with: "_____")],
                       payload: .eleccion(e), explicacion: Self.explicacion(c), erroresHabituales: errores,
                       complejidad: Double(c.dificultad) + Double(f.opciones.count) * 0.1,
                       datos: ["frase": c.id, "correcta": f.correcta, "palabra": c.palabra.palabra], origen: c.id)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        guard let banco = recursos.tildeContexto else { return [] }
        return Array(casos(p, banco).map { "\($0.id)|eleccion" }.prefix(limite))
    }
}
