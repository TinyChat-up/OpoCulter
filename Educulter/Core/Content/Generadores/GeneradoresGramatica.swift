import Foundation

// MARK: - Recursos de gramática (Content/gramatica/*.json)

/// Sintagma tipado: tokens `[texto, clase]` (clase: det, sust, verbo, adj, prep, adv, pron) y,
/// si es nominal, su género y número (`m`/`f`, `s`/`p`). `tiempo` restringe el tiempo verbal
/// compatible (un CCT como «ayer» exige pasado).
struct Sintagma: Codable, Sendable, Equatable {
    var tokens: [[String]]
    var genero: String?
    var numero: String?
    var tiempo: [String]?

    var texto: String { tokens.map { $0.first ?? "" }.joined(separator: " ") }
}

/// Verbo con su régimen y sus complementos directos compatibles (para que las oraciones tengan sentido).
struct VerboPieza: Codable, Sendable, Equatable {
    var infinitivo: String
    /// `intransitivo`, `transitivo` o `copulativo`.
    var regimen: String
    var cd: [Sintagma]?
    /// Admite complemento indirecto.
    var ci: Bool?
}

/// Atributo concordable: formas `ms`, `fs`, `mp`, `fp`.
struct AtributoPieza: Codable, Sendable, Equatable {
    var formas: [String: String]
}

/// Piezas de la gramática generativa controlada (`gramatica/piezas.json`).
struct PiezasGramatica: Codable, Sendable, Equatable {
    var sujetos: [Sintagma] = []
    var verbos: [VerboPieza] = []
    /// Complementos por función: CI, CCL, CCT, CCM.
    var complementos: [String: [Sintagma]] = [:]
    var atributos: [AtributoPieza] = []
}

/// Verbo irregular (`gramatica/verbos.json`): formas completas por `modo|tiempo` (6 personas);
/// los tiempos que no aparecen se conjugan con las reglas regulares.
struct VerboIrregular: Codable, Sendable, Equatable {
    var infinitivo: String
    var participio: String?
    var formas: [String: [String]]
}

struct BancoVerbos: Codable, Sendable, Equatable {
    var regulares: [String] = []
    var irregulares: [VerboIrregular] = []
}

/// Frase con hueco (`gramatica/frases.json`): `texto` lleva `___` donde va la forma correcta.
struct FraseHueco: Codable, Sendable, Equatable {
    var id: String
    var familia: String
    var texto: String
    var correcta: String
    var dificultad: Int
}

/// Familia de formas que se confunden (tú/tu, porque/por qué…) con el uso de cada una.
struct FamiliaFormas: Codable, Sendable, Equatable {
    struct Forma: Codable, Sendable, Equatable { var texto: String; var uso: String }
    var id: String
    var formas: [Forma]
}

struct BancoFrases: Codable, Sendable, Equatable {
    var familias: [FamiliaFormas] = []
    var frases: [FraseHueco] = []
}

// MARK: - Conjugación

/// Conjugador de verbos regulares (-ar, -er, -ir) con tabla de irregulares. Español de España
/// (incluye vosotros). Personas: 1ª, 2ª y 3ª del singular y del plural (índices 0–5).
enum Conjugador {
    static let indicativo = "Indicativo", subjuntivo = "Subjuntivo"
    static let simplesIndicativo = ["Presente", "Pretérito imperfecto", "Pretérito perfecto simple", "Futuro simple", "Condicional simple"]
    static let compuestosIndicativo = ["Pretérito perfecto compuesto", "Pretérito pluscuamperfecto", "Futuro compuesto", "Condicional compuesto"]
    static let simplesSubjuntivo = ["Presente", "Pretérito imperfecto"]
    static let compuestosSubjuntivo = ["Pretérito perfecto compuesto", "Pretérito pluscuamperfecto"]

    private static let haber: [String: [String]] = [
        "Indicativo|Presente": ["he", "has", "ha", "hemos", "habéis", "han"],
        "Indicativo|Pretérito imperfecto": ["había", "habías", "había", "habíamos", "habíais", "habían"],
        "Indicativo|Futuro simple": ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"],
        "Indicativo|Condicional simple": ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"],
        "Subjuntivo|Presente": ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"],
        "Subjuntivo|Pretérito imperfecto": ["hubiera", "hubieras", "hubiera", "hubiéramos", "hubierais", "hubieran"],
    ]
    private static let auxiliarDe: [String: String] = [
        "Pretérito perfecto compuesto": "Presente", "Pretérito pluscuamperfecto": "Pretérito imperfecto",
        "Futuro compuesto": "Futuro simple", "Condicional compuesto": "Condicional simple",
    ]

    static func participio(_ inf: String, irregular: VerboIrregular?) -> String {
        if let p = irregular?.participio { return p }
        return String(inf.dropLast(2)) + (inf.hasSuffix("ar") ? "ado" : "ido")
    }

    /// Las 6 formas de un tiempo, o `nil` si el tiempo no existe en ese modo.
    static func formas(_ inf: String, tiempo: String, modo: String, irregulares: [VerboIrregular]) -> [String]? {
        let irr = irregulares.first { $0.infinitivo == inf }
        if let f = irr?.formas["\(modo)|\(tiempo)"], f.count == 6 { return f }
        if let aux = auxiliarDe[tiempo] {
            guard let h = haber["\(modo)|\(aux)"] else { return nil }
            let part = participio(inf, irregular: irr)
            return h.map { "\($0) \(part)" }
        }
        let raiz = String(inf.dropLast(2)), t = String(inf.suffix(2))
        let ar = t == "ar", ir = t == "ir"
        let desinencias: [String]
        switch (modo, tiempo) {
        case (indicativo, "Presente"): desinencias = ar ? ["o", "as", "a", "amos", "áis", "an"] : (ir ? ["o", "es", "e", "imos", "ís", "en"] : ["o", "es", "e", "emos", "éis", "en"])
        case (indicativo, "Pretérito imperfecto"): desinencias = ar ? ["aba", "abas", "aba", "ábamos", "abais", "aban"] : ["ía", "ías", "ía", "íamos", "íais", "ían"]
        case (indicativo, "Pretérito perfecto simple"): desinencias = ar ? ["é", "aste", "ó", "amos", "asteis", "aron"] : ["í", "iste", "ió", "imos", "isteis", "ieron"]
        case (indicativo, "Futuro simple"): return ["é", "ás", "á", "emos", "éis", "án"].map { inf + $0 }
        case (indicativo, "Condicional simple"): return ["ía", "ías", "ía", "íamos", "íais", "ían"].map { inf + $0 }
        case (subjuntivo, "Presente"): desinencias = ar ? ["e", "es", "e", "emos", "éis", "en"] : ["a", "as", "a", "amos", "áis", "an"]
        case (subjuntivo, "Pretérito imperfecto"): desinencias = ar ? ["ara", "aras", "ara", "áramos", "arais", "aran"] : ["iera", "ieras", "iera", "iéramos", "ierais", "ieran"]
        default: return nil
        }
        return desinencias.map { raiz + $0 }
    }

    static let personas = ["1.ª", "2.ª", "3.ª"]
    static let numeros = ["Singular", "Plural"]
}

// MARK: - oracionSimple

/// Oraciones simples construidas con piezas tipadas y concordancia (sujeto y verbo en número;
/// atributo en género y número). El análisis correcto se conoce por construcción y sirve para
/// `segmentar` (funciones), `clasificar` (clases de palabras) y `eleccion` (función de un sintagma).
///
/// | Dif. | Estructura |
/// |---|---|
/// | 1 | S + V intransitivo (+ 1 CC) |
/// | 2 | S + V + CD |
/// | 3 | S + V + CD + CC, o intransitivo + 2 CC |
/// | 4 | S + V copulativo + Atributo (+ CC), o S + V + CD + CI |
/// | 5 | S + V + CD + CI + CC |
/// | 6 | S + V + CD (+ CI) + 2 CC |
struct GeneradorOracionSimple: GeneradorItems {
    let tipo = "oracionSimple"
    let mecanicas: Set<Mecanica> = [.segmentar, .clasificar, .eleccion]
    let marcadores: Set<String> = ["oracion", "sintagma", "contexto"]

    static let nombres: [String: String] = [
        "SUJ": "Sujeto", "PRED": "Predicado", "NV": "Núcleo verbal", "CD": "Complemento directo", "CI": "Complemento indirecto",
        "CCL": "CC de lugar", "CCT": "CC de tiempo", "CCM": "CC de modo", "ATR": "Atributo",
    ]
    static let clases: [String: String] = [
        "det": "Determinante", "sust": "Sustantivo", "verbo": "Verbo", "adj": "Adjetivo", "prep": "Preposición", "adv": "Adverbio", "pron": "Pronombre",
    ]
    static let definiciones: [String: String] = [
        "SUJ": "El sujeto concuerda en número y persona con el verbo.",
        "CD": "El complemento directo responde a «¿qué?» y puede sustituirse por lo, la, los, las.",
        "CI": "El complemento indirecto lleva «a» o «para» y puede sustituirse por le o les.",
        "CCL": "El complemento circunstancial de lugar responde a «¿dónde?».",
        "CCT": "El complemento circunstancial de tiempo responde a «¿cuándo?».",
        "CCM": "El complemento circunstancial de modo responde a «¿cómo?».",
        "ATR": "El atributo acompaña a un verbo copulativo (ser, estar, parecer) y concuerda con el sujeto.",
    ]

    /// Oración construida: tokens `(texto, clase)` y constituyentes `(función, desde, hasta)`.
    struct Oracion: Equatable {
        var tokens: [(String, String)]
        var constituyentes: [(String, Int, Int)]
        var sujetoNumero: String
        var sujetoGenero: String
        var verbo: String
        var regimen: String
        var atributo: String?

        static func == (a: Oracion, b: Oracion) -> Bool { a.tokens.map(\.0) == b.tokens.map(\.0) }
        var texto: String { tokens.map(\.0).joined(separator: " ") }
    }

    func construir(_ d: Int, _ g: PiezasGramatica, verbos: BancoVerbos, rng: inout GeneradorConSemilla) -> Oracion? {
        guard !g.sujetos.isEmpty else { return nil }
        let regimenes: [String] = switch d {
        case 1: ["intransitivo"]
        case 2, 5, 6: ["transitivo"]
        case 3: ["transitivo", "intransitivo"]
        default: ["copulativo", "transitivo"]
        }
        let posibles = g.verbos.filter { v in regimenes.contains(v.regimen) && (v.regimen != "transitivo" || !(v.cd ?? []).isEmpty) && (d != 5 || v.ci == true) }
        guard !posibles.isEmpty else { return nil }
        let v = rng.elemento(posibles)
        let sujeto = rng.elemento(g.sujetos)
        let numero = sujeto.numero ?? "s", genero = sujeto.genero ?? "m"
        var funciones: [(String, Sintagma)] = []
        var atributo: String?
        if v.regimen == "transitivo" { funciones.append(("CD", rng.elemento(v.cd ?? []))) }
        if v.regimen == "copulativo" {
            guard let a = g.atributos.isEmpty ? nil : rng.elemento(g.atributos), let forma = a.formas[genero + numero] else { return nil }
            atributo = forma
            funciones.append(("ATR", Sintagma(tokens: [[forma, "adj"]])))
        }
        let conCI = v.ci == true && (d == 5 || (d == 4 && v.regimen == "transitivo") || (d == 6 && rng.probabilidad(0.5)))
        if conCI, let ci = g.complementos["CI"], !ci.isEmpty { funciones.append(("CI", rng.elemento(ci))) }
        let numCC = switch d {
        case 1: rng.entero(0...1)
        case 2: 0
        case 3: v.regimen == "intransitivo" ? 2 : 1
        case 4: v.regimen == "copulativo" ? rng.entero(0...1) : 0
        case 5: 1
        default: 2
        }
        let tiposCC = rng.barajar(["CCL", "CCT", "CCM"].filter { !(g.complementos[$0] ?? []).isEmpty })
        guard tiposCC.count >= numCC else { return nil }
        for t in tiposCC.prefix(numCC) { funciones.append((t, rng.elemento(g.complementos[t]!))) }
        // Tiempo verbal compatible con el CCT (si lo hay).
        let tiempos = funciones.compactMap { $0.1.tiempo }.first ?? ["Presente", "Pretérito perfecto simple", "Pretérito imperfecto", "Futuro simple"]
        let tiempo = rng.elemento(tiempos)
        guard let formas = Conjugador.formas(v.infinitivo, tiempo: tiempo, modo: Conjugador.indicativo, irregulares: verbos.irregulares) else { return nil }
        let formaVerbo = formas[numero == "p" ? 5 : 2]
        var tokens: [(String, String)] = sujeto.tokens.map { ($0[0], $0.count > 1 ? $0[1] : "sust") }
        var constituyentes: [(String, Int, Int)] = [("SUJ", 0, tokens.count - 1)]
        let inicioPred = tokens.count
        tokens.append((formaVerbo, "verbo"))
        constituyentes.append(("NV", inicioPred, inicioPred))
        for (f, s) in funciones {
            let desde = tokens.count
            tokens += s.tokens.map { ($0[0], $0.count > 1 ? $0[1] : "sust") }
            constituyentes.append((f, desde, tokens.count - 1))
        }
        constituyentes.append(("PRED", inicioPred, tokens.count - 1))
        if let primero = tokens.first?.0 { tokens[0].0 = primero.prefix(1).uppercased() + primero.dropFirst() }
        return Oracion(tokens: tokens, constituyentes: constituyentes, sujetoNumero: numero, sujetoGenero: genero,
                       verbo: v.infinitivo, regimen: v.regimen, atributo: atributo)
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        for _ in 0..<200 {
            guard let o = construir(p.dificultad, recursos.gramatica, verbos: recursos.verbos, rng: &rng) else { continue }
            let ids = o.tokens.indices.map { "t\($0 + 1)" }
            let elementos = zip(ids, o.tokens).map { ElementoTexto(id: $0, texto: $1.0) }
            let analisis = o.constituyentes.filter { $0.0 != "PRED" && $0.0 != "SUJ" }
                .map { "\(Self.nombres[$0.0]!): «\(o.tokens[$0.1...$0.2].map(\.0).joined(separator: " "))»" }
            let sujetoTexto = o.tokens[o.constituyentes[0].1...o.constituyentes[0].2].map(\.0).joined(separator: " ")
            let explicacion = "Sujeto: «\(sujetoTexto)» (concuerda con «\(o.tokens[o.constituyentes[1].1].0)»). " + analisis.joined(separator: "; ") + "."
            let complejidad = Double(o.constituyentes.count) + Double(o.tokens.count) * 0.1 + (o.regimen == "copulativo" ? 0.5 : 0)
            let datos = ["oracion": o.texto, "numero": o.sujetoNumero, "genero": o.sujetoGenero, "verbo": o.verbo, "regimen": o.regimen,
                         "funciones": o.constituyentes.map { "\($0.0):\($0.1)-\($0.2)" }.joined(separator: ";"), "atributo": o.atributo ?? ""]
            switch p.mecanica {
            case .segmentar:
                var segmentos: [Payload.Segmentar.Segmento] = []
                let pred = o.constituyentes.first { $0.0 == "PRED" }!
                segmentos.append(.init(id: "s1", desde: ids[o.constituyentes[0].1], hasta: ids[o.constituyentes[0].2], etiqueta: "SUJ", padre: nil))
                segmentos.append(.init(id: "s2", desde: ids[pred.1], hasta: ids[pred.2], etiqueta: "PRED", padre: nil))
                for c in o.constituyentes where c.0 != "SUJ" && c.0 != "PRED" {
                    segmentos.append(.init(id: "s\(segmentos.count + 1)", desde: ids[c.1], hasta: ids[c.2], etiqueta: c.0, padre: "s2"))
                }
                let usadas = Set(segmentos.map(\.etiqueta))
                let etiquetas = ["SUJ", "PRED", "NV", "CD", "CI", "ATR", "CCL", "CCT", "CCM"].filter(usadas.contains).map { ElementoNombre(id: $0, nombre: Self.nombres[$0]!) }
                return Muestra(clave: "segmentar|\(o.texto)", valores: ["oracion": o.texto, "sintagma": ""],
                               payload: .segmentar(Payload.Segmentar(tokens: elementos, etiquetas: etiquetas, segmentos: segmentos)),
                               explicacion: explicacion, pistas: ["Busca primero el verbo y pregúntale «¿quién?» para encontrar el sujeto."],
                               complejidad: complejidad, datos: datos)
            case .clasificar:
                // El validador admite 2–4 categorías: con más clases en la oración se eligen 4 al azar
                // y solo se clasifican las palabras de esas clases.
                let usadas = Array(rng.barajar(Array(Set(o.tokens.map(\.1))).sorted()).prefix(4)).sorted()
                let categorias = usadas.map { ElementoNombre(id: $0, nombre: Self.clases[$0] ?? $0) }
                let fichas = zip(ids, o.tokens).filter { usadas.contains($1.1) }.map { Payload.Clasificar.Ficha(id: $0, texto: $1.0, categoria: $1.1) }
                return Muestra(clave: "clasificar|\(o.texto)", valores: ["oracion": o.texto, "sintagma": ""],
                               payload: .clasificar(Payload.Clasificar(categorias: categorias, fichas: rng.barajar(fichas))),
                               explicacion: o.tokens.map { "\($0.0): \((Self.clases[$0.1] ?? $0.1).lowercased())" }.joined(separator: "; ") + ".",
                               pistas: ["Los determinantes acompañan al sustantivo; las preposiciones introducen complementos."],
                               complejidad: complejidad, datos: datos)
            default:
                let candidatos = o.constituyentes.filter { $0.0 != "PRED" && $0.0 != "NV" }
                let objetivo = rng.elemento(candidatos)
                let texto = o.tokens[objetivo.1...objetivo.2].map(\.0).joined(separator: " ")
                let otras = rng.barajar(["SUJ", "CD", "CI", "CCL", "CCT", "CCM", "ATR"].filter { $0 != objetivo.0 })
                let (e, errores) = Opciones.eleccion(correcta: Self.nombres[objetivo.0]!,
                                                     distractores: otras.map { (Self.nombres[$0]!, Self.definiciones[objetivo.0] ?? "") }, rng: &rng)
                return Muestra(clave: "eleccion|\(o.texto)|\(objetivo.0)", valores: ["oracion": o.texto, "sintagma": texto],
                               payload: .eleccion(e), explicacion: "«\(texto)» es \(Self.nombres[objetivo.0]!.lowercased()). \(Self.definiciones[objetivo.0] ?? "")",
                               erroresHabituales: errores, complejidad: complejidad, datos: datos.merging(["objetivo": objetivo.0]) { $1 })
            }
        }
        throw ErrorGenerador.sinRecursos(tipo)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

/// Cota inferior del espacio: claves distintas recorriendo semillas consecutivas (para espacios
/// combinatorios grandes, donde la enumeración exhaustiva no es práctica).
/// Se recorren como mucho `limiteMuestreo` claves: el resultado es una cota inferior del espacio.
let limiteMuestreo = 3_000

func enumerarPorSemillas(_ g: any GeneradorItems, _ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
    let limite = min(limite, limiteMuestreo)
    var vistos = Set<String>(), claves: [String] = []
    var semilla: UInt64 = 0
    var fallosSeguidos = 0
    while claves.count < limite && fallosSeguidos < 2000 {
        if let m = try? MotorGeneradores.muestra(p, semilla: semilla, recursos: recursos), vistos.insert(m.clave).inserted {
            claves.append(m.clave); fallosSeguidos = 0
        } else { fallosSeguidos += 1 }
        semilla += 1
    }
    return claves
}

// MARK: - analisisVerbal

/// Análisis de formas verbales con ruedas (persona, número, tiempo y modo). Solo se preguntan
/// formas que no son ambiguas dentro del paradigma que ofrecen las ruedas (p. ej., «cantaba» es
/// 1.ª y 3.ª persona, así que no se pregunta).
///
/// | Dif. | Verbos | Tiempos |
/// |---|---|---|
/// | 1 | regulares en -ar | presente, pretérito perfecto simple, futuro (indicativo) |
/// | 2 | regulares de las tres conjugaciones | + imperfecto y condicional |
/// | 3 | regulares | + presente de subjuntivo |
/// | 4 | regulares | + compuestos de indicativo |
/// | 5 | irregulares | simples de indicativo y presente de subjuntivo |
/// | 6 | irregulares | todos (con imperfecto y compuestos de subjuntivo) |
struct GeneradorAnalisisVerbal: GeneradorItems {
    let tipo = "analisisVerbal"
    let mecanicas: Set<Mecanica> = [.ruedas]
    let marcadores: Set<String> = ["forma", "infinitivo", "contexto"]

    struct Opcion: Hashable { let tiempo: String; let modo: String }

    static func nivel(_ d: Int, _ banco: BancoVerbos) -> (verbos: [String], tiempos: [Opcion]) {
        let ind = Conjugador.indicativo, sub = Conjugador.subjuntivo
        let t1 = ["Presente", "Pretérito perfecto simple", "Futuro simple"].map { Opcion(tiempo: $0, modo: ind) }
        let t2 = t1 + ["Pretérito imperfecto", "Condicional simple"].map { Opcion(tiempo: $0, modo: ind) }
        let t3 = t2 + [Opcion(tiempo: "Presente", modo: sub)]
        let t4 = t3 + Conjugador.compuestosIndicativo.map { Opcion(tiempo: $0, modo: ind) }
        let t6 = t4 + [Opcion(tiempo: "Pretérito imperfecto", modo: sub)] + Conjugador.compuestosSubjuntivo.map { Opcion(tiempo: $0, modo: sub) }
        let irregulares = banco.irregulares.map(\.infinitivo).filter { !["ser", "estar", "haber"].contains($0) }
        switch d {
        case 1: return (banco.regulares.filter { $0.hasSuffix("ar") }, t1)
        case 2: return (banco.regulares, t2)
        case 3: return (banco.regulares, t3)
        case 4: return (banco.regulares, t4)
        case 5: return (irregulares, t3)
        default: return (irregulares, t6)
        }
    }

    /// Formas no ambiguas: (verbo, tiempo, modo, persona) cuya forma solo aparece una vez en el
    /// paradigma del nivel.
    func casos(_ d: Int, _ banco: BancoVerbos) -> [(verbo: String, op: Opcion, indice: Int, forma: String)] {
        let (verbos, tiempos) = Self.nivel(d, banco)
        var out: [(String, Opcion, Int, String)] = []
        for v in verbos {
            var paradigma: [(Opcion, Int, String)] = []
            for t in tiempos { if let f = Conjugador.formas(v, tiempo: t.tiempo, modo: t.modo, irregulares: banco.irregulares) { for (i, forma) in f.enumerated() { paradigma.append((t, i, forma)) } } }
            var cuenta: [String: Int] = [:]
            for (_, _, f) in paradigma { cuenta[f, default: 0] += 1 }
            out += paradigma.filter { cuenta[$0.2] == 1 }.map { (v, $0.0, $0.1, $0.2) }
        }
        return out
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let todos = casos(p.dificultad, recursos.verbos)
        guard !todos.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let c = rng.elemento(todos)
        let (_, tiempos) = Self.nivel(p.dificultad, recursos.verbos)
        let nombresTiempo = Array(Set(tiempos.map(\.tiempo))).sorted { a, b in
            (Conjugador.simplesIndicativo + Conjugador.compuestosIndicativo).firstIndex(of: a) ?? 0 < (Conjugador.simplesIndicativo + Conjugador.compuestosIndicativo).firstIndex(of: b) ?? 0
        }
        let persona = Conjugador.personas[c.indice % 3], numero = Conjugador.numeros[c.indice / 3]
        let ruedas = [
            Payload.Ruedas.Rueda(id: "persona", nombre: "Persona", opciones: Conjugador.personas, correcta: persona),
            Payload.Ruedas.Rueda(id: "numero", nombre: "Número", opciones: Conjugador.numeros, correcta: numero),
            Payload.Ruedas.Rueda(id: "tiempo", nombre: "Tiempo", opciones: nombresTiempo, correcta: c.op.tiempo),
            Payload.Ruedas.Rueda(id: "modo", nombre: "Modo", opciones: [Conjugador.indicativo, Conjugador.subjuntivo], correcta: c.op.modo),
        ]
        let descripcion = "\(persona) persona del \(numero.lowercased()) del \(c.op.tiempo.lowercased()) de \(c.op.modo.lowercased())"
        let compuesto = c.forma.contains(" ")
        return Muestra(clave: "\(c.verbo)|\(c.op.tiempo)|\(c.op.modo)|\(c.indice)", valores: ["forma": c.forma, "infinitivo": c.verbo],
                       payload: .ruedas(Payload.Ruedas(ruedas: ruedas)),
                       explicacion: "«\(c.forma)»: \(descripcion) del verbo \(c.verbo).",
                       erroresHabituales: [ErrorHabitual(respuesta: "tiempo", feedback: compuesto ? "Las formas con «haber» + participio son tiempos compuestos." : "Fíjate en la terminación: indica el tiempo."),
                                           ErrorHabitual(respuesta: "modo", feedback: "El subjuntivo expresa deseo, duda o posibilidad («que yo cante»).")],
                       complejidad: Double(p.dificultad >= 5 ? 3 : 1) + (compuesto ? 1 : 0) + (c.op.modo == Conjugador.subjuntivo ? 1 : 0) + Double(tiempos.count) * 0.1,
                       datos: ["forma": c.forma, "verbo": c.verbo, "tiempo": c.op.tiempo, "modo": c.op.modo, "persona": persona, "numero": numero])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(casos(p.dificultad, recursos.verbos).map { "\($0.verbo)|\($0.op.tiempo)|\($0.op.modo)|\($0.indice)" }.prefix(limite))
    }
}

// MARK: - fraseHueco

/// Frases con hueco y familia de formas que se confunden (tú/tu, por qué/porque…), en `eleccion`
/// (opciones = formas de la familia) o `construir` (piezas = formas de la familia). La dificultad
/// es la de cada frase del banco (o la inferior más próxima con frases).
struct GeneradorFraseHueco: GeneradorItems {
    let tipo = "fraseHueco"
    let mecanicas: Set<Mecanica> = [.eleccion, .construir]
    let marcadores: Set<String> = ["frase", "contexto"]

    func frases(_ p: Plantilla, _ banco: BancoFrases) -> [FraseHueco] {
        let familias = Set(p.textos("familias", porDefecto: banco.familias.map(\.id)))
        let validas = banco.frases.filter { f in familias.contains(f.familia) && banco.familias.contains { $0.id == f.familia } }
        for d in stride(from: p.dificultad, through: 1, by: -1) {
            let de = validas.filter { $0.dificultad == d }
            if !de.isEmpty { return de }
        }
        return validas
    }

    /// Respeta la mayúscula inicial de la forma correcta.
    static func ajustar(_ t: String, como modelo: String) -> String {
        guard let m = modelo.first, m.isUppercase else { return t }
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let lista = frases(p, recursos.frases)
        guard !lista.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let f = rng.elemento(lista)
        let familia = recursos.frases.familias.first { $0.id == f.familia }!
        let formas = familia.formas.map { (texto: Self.ajustar($0.texto, como: f.correcta), uso: $0.uso) }
        let correcta = formas.first { $0.texto == f.correcta }
        let explicacion = "«\(f.correcta)»: \(correcta?.uso ?? "")."
        let mostrada = f.texto.replacingOccurrences(of: "___", with: "_____")
        if p.mecanica == .construir {
            let piezas = rng.barajar(formas).enumerated().map { ElementoTexto(id: "p\($0.offset + 1)", texto: $0.element.texto) }
            let idCorrecta = piezas.first { $0.texto == f.correcta }!.id
            return Muestra(clave: "\(f.id)|construir", valores: ["frase": mostrada],
                           payload: .construir(Payload.Construir(plantilla: f.texto.replacingOccurrences(of: "___", with: "{h1}"),
                                                                 huecos: [.init(id: "h1", correcta: idCorrecta)], piezas: piezas)),
                           explicacion: explicacion,
                           erroresHabituales: [ErrorHabitual(respuesta: "h1", feedback: formas.filter { $0.texto != f.correcta }.map { "«\($0.texto)»: \($0.uso)" }.joined(separator: " "))],
                           complejidad: Double(f.dificultad) + Double(formas.count) * 0.2, datos: ["frase": f.id, "correcta": f.correcta])
        }
        let (e, errores) = Opciones.eleccion(correcta: f.correcta,
                                             distractores: formas.filter { $0.texto != f.correcta }.map { ($0.texto, "«\($0.texto)» es \($0.uso). Aquí va «\(f.correcta)».") },
                                             maximo: 4, rng: &rng)
        return Muestra(clave: "\(f.id)|eleccion", valores: ["frase": mostrada], payload: .eleccion(e), explicacion: explicacion,
                       erroresHabituales: errores, complejidad: Double(f.dificultad) + Double(formas.count) * 0.2,
                       datos: ["frase": f.id, "correcta": f.correcta])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(frases(p, recursos.frases).map { "\($0.id)|\(p.mecanica == .construir ? "construir" : "eleccion")" }.prefix(limite))
    }
}
