import Foundation

// MARK: - Compatibilidad semántica (gramatica/compatibilidad.json, lote 02b, D-086)

/// Formato neutro de la dirección (lote 02b): sustantivos y adjetivos con etiquetas semánticas
/// (las finas para el CD: `abrible`, `comprable`, `prestable`, `lavable`…), verbos con el sujeto y
/// el objeto que admiten, y complementos circunstanciales por tipo. La gramática generativa lo
/// usa para que ninguna oración sea absurda (D-086).
struct CompatibilidadGramatica: Codable, Sendable, Equatable {
    struct Sustantivo: Codable, Sendable, Equatable {
        var lema: String
        var genero: String
        var plural: String
        var etiquetas: [String]

        func forma(_ numero: String) -> String { numero == "p" ? plural : lema }
        /// Persona o animal: como CD o CI va con «a» + posesivo («a su vecino»).
        var animado: Bool { etiquetas.contains("persona") || etiquetas.contains("animal") }
    }

    struct Adjetivo: Codable, Sendable, Equatable {
        var ms: String
        var fs: String
        var mp: String
        var fp: String
        var etiquetas: [String]

        /// Forma concordada. Solo se eligen las cuatro formas de los datos: nunca se deriva una.
        func forma(genero: String, numero: String) -> String {
            switch (genero, numero) {
            case ("f", "s"): fs
            case ("f", "p"): fp
            case (_, "p"): mp
            default: ms
            }
        }

        /// Invariable en género (amable, azul, grande, fácil…): solo cambia en número.
        var invariableEnGenero: Bool { ms == fs && mp == fp }
        var formas: Set<String> { [ms, fs, mp, fp] }
    }

    struct Verbo: Codable, Sendable, Equatable {
        var infinitivo: String
        /// 1 (-ar), 2 (-er) o 3 (-ir).
        var conjugacion: Int
        var regimen: String
        /// Etiquetas de los sustantivos que admite como CD (transitivos).
        var objeto: [String]?
        var admiteCI: Bool
        var participioIrregular: String?
        /// Etiquetas de los sustantivos que admite como sujeto.
        var sujeto: [String]
    }

    var version: Int = 0
    var sustantivos: [Sustantivo] = []
    var adjetivos: [Adjetivo] = []
    var verbos: [Verbo] = []
    /// CCL, CCT, CCM y CCC.
    var complementosCircunstanciales: [String: [String]] = [:]

    var vacia: Bool { verbos.isEmpty || sustantivos.isEmpty }

    /// Complementos que no se usan en la generación porque sus palabras no tienen una clase
    /// inequívoca para `clasificar` (D-081): «junto al río» (contracción) y «a las cinco» (numeral).
    static let complementosExcluidos: Set<String> = ["junto al río", "a las cinco"]

    static func articulo(genero: String, numero: String) -> String {
        switch (genero, numero) {
        case ("f", "s"): "la"
        case ("f", "p"): "las"
        case (_, "p"): "los"
        default: "el"
        }
    }

    func comparten(_ a: [String], _ b: [String]?) -> Bool { !Set(a).isDisjoint(with: b ?? []) }

    /// Adjetivos que pueden calificar al sustantivo (comparten etiqueta).
    func adjetivos(para s: Sustantivo) -> [Adjetivo] { adjetivos.filter { comparten($0.etiquetas, s.etiquetas) } }

    /// Clase de palabra de un token de complemento circunstancial (det, prep, adv o sust).
    static func clase(_ palabra: String, tras anterior: String?) -> String {
        let preposiciones: Set<String> = ["a", "en", "por", "con", "para", "de", "desde", "hasta"]
        let determinantes: Set<String> = ["el", "la", "los", "las", "su", "sus", "todos", "todas", "un", "una"]
        let adverbios: Set<String> = ["ayer", "hoy", "deprisa", "despacio", "tranquilamente", "mañana", "siempre", "pronto", "tarde"]
        if preposiciones.contains(palabra) { return "prep" }
        if determinantes.contains(palabra) { return "det" }
        // «por la mañana»: tras un determinante, «mañana» es sustantivo.
        if let anterior, determinantes.contains(anterior) { return "sust" }
        return adverbios.contains(palabra) ? "adv" : "sust"
    }
}

// MARK: - Oración con compatibilidad

extension GeneradorOracionSimple {
    /// Datos de concordancia de la oración para el oráculo de los tests (no se muestran).
    struct Concordancia: Equatable {
        var sujetoLema: String
        var cdLema: String?
        var ciLema: String?
        /// `forma|lema|genero|numero` de cada adjetivo con el sustantivo al que califica.
        var adjetivos: [String]
        /// Tipos de CC en orden de aparición.
        var circunstanciales: [String]
        var tiempo: String
    }

    /// Construye una oración con `compatibilidad.json` (D-086):
    /// - sujeto y CD de etiquetas compatibles con el verbo (`sujeto`, `objeto`);
    /// - CI de persona, nunca el mismo referente que el sujeto (ni que el CD);
    /// - como mucho 2 CC, de tipos distintos; un CCT puede ir delante (no en `segmentar`), y
    ///   entonces es el primer constituyente y va seguido de coma;
    /// - adjetivos de etiqueta compatible y concordados con las cuatro formas de los datos;
    /// - concordancia artículo-sustantivo (género y número) y sujeto-verbo (número).
    func construirCompatible(_ d: Int, _ c: CompatibilidadGramatica, piezas g: PiezasGramatica, verbos banco: BancoVerbos,
                             anteponerCCT: Bool, rng: inout GeneradorConSemilla) -> (Oracion, Concordancia)? {
        let regimenes: [String] = switch d {
        case 1: ["intransitivo"]
        case 2, 4, 5, 6: ["transitivo"]
        default: ["transitivo", "intransitivo"]
        }
        let posibles = c.verbos.filter { v in
            regimenes.contains(v.regimen)
                && c.sustantivos.contains { c.comparten($0.etiquetas, v.sujeto) }
                && (v.regimen != "transitivo" || c.sustantivos.contains { c.comparten($0.etiquetas, v.objeto) })
                && ((d != 4 && d != 5) || v.admiteCI)
        }
        guard !posibles.isEmpty else { return nil }
        let v = rng.elemento(posibles)
        let sujeto = rng.elemento(c.sustantivos.filter { c.comparten($0.etiquetas, v.sujeto) })
        let numero = rng.probabilidad(0.5) ? "p" : "s"
        var adjetivos: [String] = []

        /// Sintagma nominal con artículo (y adjetivo opcional concordado).
        func nominal(_ s: CompatibilidadGramatica.Sustantivo, numero n: String, conAdjetivo: Bool) -> [(String, String)] {
            var t = [(CompatibilidadGramatica.articulo(genero: s.genero, numero: n), "det"), (s.forma(n), "sust")]
            let candidatos = c.adjetivos(para: s)
            if conAdjetivo, !candidatos.isEmpty {
                let a = rng.elemento(candidatos)
                let forma = a.forma(genero: s.genero, numero: n)
                t.append((forma, "adj"))
                adjetivos.append("\(forma)|\(s.lema)|\(s.genero)|\(n)")
            }
            return t
        }
        /// Persona o animal como CD o CI: «a su vecino» (sin contracción «al», D-081).
        func animado(_ s: CompatibilidadGramatica.Sustantivo) -> [(String, String)] { [("a", "prep"), ("su", "det"), (s.lema, "sust")] }

        var funciones: [(String, [(String, String)])] = []
        var cd: CompatibilidadGramatica.Sustantivo?
        if v.regimen == "transitivo" {
            let candidatos = c.sustantivos.filter { c.comparten($0.etiquetas, v.objeto) && $0.lema != sujeto.lema }
            guard !candidatos.isEmpty else { return nil }
            let o = rng.elemento(candidatos)
            cd = o
            let n = d >= 3 && !o.animado && rng.probabilidad(0.3) ? "p" : "s"
            funciones.append(("CD", o.animado ? animado(o) : nominal(o, numero: n, conAdjetivo: d >= 5 && rng.probabilidad(0.5))))
        }
        var ci: CompatibilidadGramatica.Sustantivo?
        let conCI = v.admiteCI && (d == 5 || d == 4 || (d == 6 && rng.probabilidad(0.5)))
        if conCI {
            // CI ≠ sujeto (y ≠ CD): nunca el mismo referente.
            let candidatos = c.sustantivos.filter { $0.etiquetas.contains("persona") && $0.lema != sujeto.lema && $0.lema != cd?.lema }
            if !candidatos.isEmpty {
                let p = rng.elemento(candidatos)
                ci = p
                funciones.append(("CI", animado(p)))
            }
        }
        let numCC = switch d {
        case 1, 4: rng.entero(0...1)
        case 2: 0
        case 3: v.regimen == "intransitivo" ? 2 : 1
        case 5: 1
        default: 2
        }
        let tipos = rng.barajar(["CCL", "CCT", "CCM", "CCC"].filter { t in
            (c.complementosCircunstanciales[t] ?? []).contains { !CompatibilidadGramatica.complementosExcluidos.contains($0) }
        })
        guard tipos.count >= numCC else { return nil }
        var circunstanciales: [(String, [(String, String)])] = []
        var tiempos = ["Presente", "Pretérito perfecto simple", "Pretérito imperfecto", "Futuro simple"]
        for t in tipos.prefix(numCC) {
            let texto = rng.elemento((c.complementosCircunstanciales[t] ?? []).filter { !CompatibilidadGramatica.complementosExcluidos.contains($0) })
            let palabras = texto.split(separator: " ").map(String.init)
            let tokens = palabras.enumerated().map { (i, p) in (p, CompatibilidadGramatica.clase(p, tras: i > 0 ? palabras[i - 1] : nil)) }
            circunstanciales.append((t, tokens))
            // Tiempo verbal compatible con el CCT («ayer» → pasado), según piezas.json.
            if t == "CCT", let restriccion = g.complementos["CCT"]?.first(where: { $0.texto == texto })?.tiempo {
                tiempos = tiempos.filter(restriccion.contains)
            }
        }
        guard !tiempos.isEmpty else { return nil }
        let tiempo = rng.elemento(tiempos)
        guard let formas = Conjugador.formas(v.infinitivo, tiempo: tiempo, modo: Conjugador.indicativo, irregulares: banco.irregulares) else { return nil }

        // Orden: [CCT antepuesto,] SUJ V [CD] [CI] [CC…].
        let antepuesto = anteponerCCT ? circunstanciales.firstIndex { $0.0 == "CCT" } : nil
        var tokens: [(String, String)] = []
        var constituyentes: [(String, Int, Int)] = []
        var comaTras: Int?
        func anadir(_ f: String, _ t: [(String, String)]) {
            let desde = tokens.count
            tokens += t
            constituyentes.append((f, desde, tokens.count - 1))
        }
        if let i = antepuesto {
            anadir("CCT", circunstanciales[i].1)
            comaTras = tokens.count - 1
        }
        anadir("SUJ", nominal(sujeto, numero: numero, conAdjetivo: d >= 4 && rng.probabilidad(0.4)))
        let inicioPred = tokens.count
        anadir("NV", [(formas[numero == "p" ? 5 : 2], "verbo")])
        for (f, t) in funciones { anadir(f, t) }
        for (k, cc) in circunstanciales.enumerated() where k != antepuesto { anadir(cc.0, cc.1) }
        constituyentes.append(("PRED", inicioPred, tokens.count - 1))
        if let primero = tokens.first?.0 { tokens[0].0 = primero.prefix(1).uppercased() + primero.dropFirst() }
        // El sujeto y el NV van primero en la lista de constituyentes (lo esperan las mecánicas).
        constituyentes.sort { a, b in
            let orden = ["SUJ": 0, "NV": 1]
            return (orden[a.0] ?? 2, a.1) < (orden[b.0] ?? 2, b.1)
        }
        var o = Oracion(tokens: tokens, constituyentes: constituyentes, sujetoNumero: numero, sujetoGenero: sujeto.genero,
                        verbo: v.infinitivo, regimen: v.regimen, atributo: nil)
        o.comaTras = comaTras
        let datos = Concordancia(sujetoLema: sujeto.lema, cdLema: cd?.lema, ciLema: ci?.lema, adjetivos: adjetivos,
                                 circunstanciales: constituyentes.filter { $0.0.hasPrefix("CC") }.sorted { $0.1 < $1.1 }.map(\.0),
                                 tiempo: tiempo)
        return (o, datos)
    }
}
