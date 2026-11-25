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
    /// Variante en -se del pretérito imperfecto de subjuntivo (amase) y su compuesto (hubiese amado):
    /// la clave lleva el sufijo, pero el nombre del tiempo es el mismo (`nombreTiempo`).
    static let sufijoSe = " (-se)"

    /// Nombre del tiempo que se muestra (sin la marca de la variante en -se).
    static func nombreTiempo(_ clave: String) -> String { clave.replacingOccurrences(of: sufijoSe, with: "") }

    /// Tiempos compuestos (haber + participio).
    static func esCompuesto(_ clave: String) -> Bool { auxiliarDe[clave] != nil }

    /// Aspecto (Fase 05E): perfecto en los tiempos compuestos y en el pretérito perfecto simple;
    /// imperfecto en el resto de los simples.
    static func aspecto(_ clave: String, modo: String) -> String {
        esCompuesto(clave) || (modo == indicativo && clave == "Pretérito perfecto simple") ? "Perfecto" : "Imperfecto"
    }

    private static let haber: [String: [String]] = [
        "Indicativo|Presente": ["he", "has", "ha", "hemos", "habéis", "han"],
        "Indicativo|Pretérito imperfecto": ["había", "habías", "había", "habíamos", "habíais", "habían"],
        "Indicativo|Futuro simple": ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"],
        "Indicativo|Condicional simple": ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"],
        "Subjuntivo|Presente": ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"],
        "Subjuntivo|Pretérito imperfecto": ["hubiera", "hubieras", "hubiera", "hubiéramos", "hubierais", "hubieran"],
        "Indicativo|Pretérito perfecto simple": ["hube", "hubiste", "hubo", "hubimos", "hubisteis", "hubieron"],
        "Subjuntivo|Pretérito imperfecto (-se)": ["hubiese", "hubieses", "hubiese", "hubiésemos", "hubieseis", "hubiesen"],
        "Subjuntivo|Futuro simple": ["hubiere", "hubieres", "hubiere", "hubiéremos", "hubiereis", "hubieren"],
    ]
    private static let auxiliarDe: [String: String] = [
        "Pretérito perfecto compuesto": "Presente", "Pretérito pluscuamperfecto": "Pretérito imperfecto",
        "Futuro compuesto": "Futuro simple", "Condicional compuesto": "Condicional simple",
        "Pretérito anterior": "Pretérito perfecto simple", "Pretérito pluscuamperfecto (-se)": "Pretérito imperfecto (-se)",
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
        case (subjuntivo, "Pretérito imperfecto (-se)"): desinencias = ar ? ["ase", "ases", "ase", "ásemos", "aseis", "asen"] : ["iese", "ieses", "iese", "iésemos", "ieseis", "iesen"]
        case (subjuntivo, "Futuro simple"): desinencias = ar ? ["are", "ares", "are", "áremos", "areis", "aren"] : ["iere", "ieres", "iere", "iéremos", "iereis", "ieren"]
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
/// Con `compatibilidad.json` (lote 02b, D-086) las oraciones salen de sus etiquetas semánticas:
/// ver `construirCompatible`. Sin ese archivo se usan las piezas de `piezas.json`.
///
/// Con `compatibilidad.json`, la estructura de cada nivel es la de D-090 (`Estructura.nivel`):
/// 1 S + V intransitivo · 2 S + V + CD · 3 S + V + CC · 4 copulativa · 5 S + V + CD + CI o dos CC ·
/// 6 CC delante con coma y sujeto pospuesto. Sin ese archivo (solo `piezas.json`):
///
/// | Dif. | Estructura |
/// |---|---|
/// | 1 | S + V intransitivo (+ 1 CC) |
/// | 2 | S + V + CD |
/// | 3 | S + V + CD + CC, o intransitivo + 2 CC |
/// | 4 | S + V copulativo + Atributo (+ CC), o S + V + CD + CI |
/// | 5 | S + V + CD (+ adj) + CI + CC |
/// | 6 | S + V + CD (+ CI) + 2 CC |
struct GeneradorOracionSimple: GeneradorItems {
    let tipo = "oracionSimple"
    let mecanicas: Set<Mecanica> = [.segmentar, .clasificar, .eleccion, .marcarTexto]
    let marcadores: Set<String> = ["oracion", "sintagma", "forma", "otraForma", "contexto"]

    static let nombres: [String: String] = [
        "SUJ": "Sujeto", "PRED": "Predicado", "NV": "Núcleo verbal", "CD": "Complemento directo", "CI": "Complemento indirecto",
        "CCL": "CC de lugar", "CCT": "CC de tiempo", "CCM": "CC de modo", "CCC": "CC de compañía", "ATR": "Atributo",
    ]
    static let clases: [String: String] = [
        "det": "Determinante", "sust": "Sustantivo", "verbo": "Verbo", "adj": "Adjetivo", "prep": "Preposición", "adv": "Adverbio", "pron": "Pronombre",
        "contr": "Contracción (preposición + artículo)", "num": "Numeral",
    ]
    static let definiciones: [String: String] = [
        "SUJ": "El sujeto concuerda en número y persona con el verbo.",
        "CD": "El complemento directo responde a «¿qué?» y puede sustituirse por lo, la, los, las.",
        "CI": "El complemento indirecto lleva «a» o «para» y puede sustituirse por le o les.",
        "CCL": "El complemento circunstancial de lugar responde a «¿dónde?».",
        "CCT": "El complemento circunstancial de tiempo responde a «¿cuándo?».",
        "CCM": "El complemento circunstancial de modo responde a «¿cómo?».",
        "CCC": "El complemento circunstancial de compañía responde a «¿con quién?».",
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
        /// Índice del token tras el que va una coma (CCT antepuesto).
        var comaTras: Int? = nil

        static func == (a: Oracion, b: Oracion) -> Bool { a.tokens.map(\.0) == b.tokens.map(\.0) && a.comaTras == b.comaTras }
        var texto: String { tokens.enumerated().map { $0.offset == comaTras ? $0.element.0 + "," : $0.element.0 }.joined(separator: " ") }
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

    /// Modo de la plantilla (`parametros.modo`): `sujeto` (marcarTexto), `sujetoPredicado` o
    /// `completo` (segmentar), `clases` o `funciones` (clasificar), `funcion`, `clase`,
    /// `concordancia` o `pronombre` (eleccion).
    static func modo(_ p: Plantilla) -> String {
        let porDefecto: String = switch p.mecanica {
        case .marcarTexto: "sujeto"
        case .segmentar: "completo"
        case .clasificar: "clases"
        default: "funcion"
        }
        return p.textos("modo", porDefecto: [porDefecto]).first ?? porDefecto
    }

    /// Nivel estructural de la oración (D-090) según la dificultad pedida y el modo. Las preguntas que
    /// comparan oraciones (clase, función, concordancia, pronombre) mezclan niveles: con uno solo,
    /// la respuesta sería siempre la misma.
    static func nivelEstructural(_ d: Int, modo: String, rng: inout GeneradorConSemilla) -> Int {
        let i = min(max(d, 1), 6) - 1
        let mezclas: [[Int]]? = switch modo {
        case "clase": [[1, 2], [1, 2, 3], [1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6], [4, 5, 6]]
        case "funcion": [[2, 3], [2, 3, 4], [3, 4, 5], [3, 4, 5, 6], [4, 5, 6], [5, 6]]
        case "concordancia": [[2, 3], [2, 3], [3, 5], [5, 6], [5, 6], [6]]
        case "pronombre": [[2], [2], [2, 5], [2, 5, 6], [5, 6], [5, 6]]
        default: nil
        }
        return mezclas.map { rng.elemento($0[i]) } ?? (i + 1)
    }

    /// Peso de cada función en la medida de complejidad.
    static let pesos: [String: Double] = ["SUJ": 1, "NV": 1, "CD": 1, "CI": 1.5, "ATR": 1, "CCL": 1.2, "CCT": 1.2, "CCM": 1.2, "CCC": 1.2]

    static func nombre(_ f: String, copulativa: Bool) -> String {
        switch f {
        case "PRED": copulativa ? "Predicado nominal" : "Predicado verbal"
        case "NV": copulativa ? "Núcleo (verbo copulativo)" : "Núcleo verbal"
        default: nombres[f] ?? f
        }
    }

    /// Clase de oración por su estructura (CLASE).
    static func claseOracion(regimen: String) -> String {
        switch regimen {
        case "copulativo": "Copulativa (atributiva)"
        case "transitivo": "Predicativa transitiva"
        default: "Predicativa intransitiva"
        }
    }

    static func pronombre(_ funcion: String, genero: String, numero: String) -> String {
        if funcion == "CI" { return numero == "p" ? "les" : "le" }
        return (genero == "f" ? "la" : "lo") + (numero == "p" ? "s" : "")
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let modo = Self.modo(p)
        for _ in 0..<200 {
            let o: Oracion
            var concordancia: Concordancia?
            let nivel = Self.nivelEstructural(p.dificultad, modo: modo, rng: &rng)
            if !recursos.compatibilidad.vacia {
                guard let (oracion, datos) = construirCompatible(nivel, recursos.compatibilidad, piezas: recursos.gramatica, verbos: recursos.verbos,
                                                                 permitirDesorden: p.mecanica != .segmentar, rng: &rng) else { continue }
                o = oracion
                concordancia = datos
            } else {
                guard let oracion = construir(p.dificultad, recursos.gramatica, verbos: recursos.verbos, rng: &rng) else { continue }
                o = oracion
            }
            let copulativa = o.regimen == "copulativo"
            let ids = o.tokens.indices.map { "t\($0 + 1)" }
            /// Texto de un token tal como se ve (con la coma del CC antepuesto).
            func visto(_ i: Int) -> String { i == o.comaTras ? o.tokens[i].0 + "," : o.tokens[i].0 }
            let elementos = o.tokens.indices.map { ElementoTexto(id: ids[$0], texto: visto($0)) }
            func texto(_ c: (String, Int, Int)) -> String { o.tokens[c.1...c.2].map(\.0).joined(separator: " ") }
            let suj = o.constituyentes.first { $0.0 == "SUJ" }!
            let nv = o.constituyentes.first { $0.0 == "NV" }!
            let grupos = o.constituyentes.filter { $0.0 != "PRED" && $0.0 != "NV" }
            let analisis = o.constituyentes.filter { $0.0 != "PRED" && $0.0 != "SUJ" && $0.0 != "NV" }
                .map { "\(Self.nombres[$0.0]!): «\(texto($0))»" }
            var explicacion = "Sujeto: «\(texto(suj))» (concuerda con «\(texto(nv))»)."
            if copulativa {
                explicacion += " Predicado nominal: el núcleo es el verbo copulativo «\(texto(nv))» y «\(o.atributo ?? "")» es el atributo (concuerda con el sujeto)."
            } else {
                explicacion += " Predicado verbal, con núcleo «\(texto(nv))»."
            }
            if !analisis.isEmpty, !copulativa { explicacion += " " + analisis.joined(separator: "; ") + "." }
            let peso = o.constituyentes.filter { $0.0 != "PRED" }.map { Self.pesos[$0.0] ?? 1 }.reduce(0, +)
            let orden = concordancia?.orden ?? .canonico
            let complejidad = peso + (copulativa ? 1 : 0) + (orden != .canonico ? 1.5 : 0) + (orden == .sujetoPospuesto ? 0.5 : 0)
                + Double(o.tokens.count) * 0.05
            var datos = ["oracion": o.texto, "numero": o.sujetoNumero, "genero": o.sujetoGenero, "verbo": o.verbo, "regimen": o.regimen,
                         "funciones": o.constituyentes.map { "\($0.0):\($0.1)-\($0.2)" }.joined(separator: ";"), "atributo": o.atributo ?? "",
                         "tokens": o.tokens.map { "\($0.0)/\($0.1)" }.joined(separator: " "), "coma": o.comaTras.map(String.init) ?? "",
                         "modo": modo, "nivel": String(nivel)]
            if let c = concordancia {
                datos.merge(["sujetoLema": c.sujetoLema, "cdLema": c.cdLema ?? "", "ciLema": c.ciLema ?? "", "adjetivos": c.adjetivos.joined(separator: ";"),
                             "circunstanciales": c.circunstanciales.joined(separator: ";"), "tiempo": c.tiempo, "textosCC": c.textosCC.joined(separator: ";"),
                             "cdDet": c.cdDeterminante ?? "", "ciDet": c.ciDeterminante ?? "", "cdNumero": c.cdNumero ?? "", "ciNumero": c.ciNumero ?? "",
                             "atributoLema": c.atributoLema ?? "", "orden": c.orden.rawValue]) { $1 }
            }
            let pistaConcordancia = "El sujeto concuerda con el verbo: cambia el número del verbo y mira qué cambia."
            switch p.mecanica {
            case .marcarTexto:
                let correctos = Array(ids[suj.1...suj.2])
                return Muestra(clave: "marcar|\(o.texto)", valores: ["oracion": o.texto, "sintagma": ""],
                               payload: .marcarTexto(Payload.MarcarTexto(unidad: .palabra, tokens: elementos, correctos: correctos)),
                               explicacion: explicacion, pistas: [pistaConcordancia], complejidad: complejidad, datos: datos)
            case .segmentar:
                guard let pred = o.constituyentes.first(where: { $0.0 == "PRED" }) else { continue }
                var segmentos: [Payload.Segmentar.Segmento] = []
                segmentos.append(.init(id: "s1", desde: ids[suj.1], hasta: ids[suj.2], etiqueta: "SUJ", padre: nil))
                segmentos.append(.init(id: "s2", desde: ids[pred.1], hasta: ids[pred.2], etiqueta: "PRED", padre: nil))
                if modo != "sujetoPredicado" {
                    for c in o.constituyentes where c.0 != "SUJ" && c.0 != "PRED" {
                        segmentos.append(.init(id: "s\(segmentos.count + 1)", desde: ids[c.1], hasta: ids[c.2], etiqueta: c.0, padre: "s2"))
                    }
                }
                let usadas = Set(segmentos.map(\.etiqueta))
                let etiquetas = ["SUJ", "PRED", "NV", "CD", "CI", "ATR", "CCL", "CCT", "CCM", "CCC"].filter(usadas.contains)
                    .map { ElementoNombre(id: $0, nombre: Self.nombre($0, copulativa: copulativa)) }
                return Muestra(clave: "segmentar|\(modo)|\(o.texto)", valores: ["oracion": o.texto, "sintagma": ""],
                               payload: .segmentar(Payload.Segmentar(tokens: elementos, etiquetas: etiquetas, segmentos: segmentos)),
                               explicacion: explicacion, pistas: [pistaConcordancia, "Busca primero el verbo y pregúntale «¿quién?» para encontrar el sujeto."],
                               complejidad: complejidad, datos: datos)
            case .clasificar where modo == "funciones":
                // Fichas = grupos (y el verbo); categorías = sus funciones (2–4: si hay más, se eligen 4).
                let conVerbo = grupos + [nv]
                let funciones = Array(Set(conVerbo.map(\.0)))
                guard funciones.count >= 2 else { continue }
                let usadas = Set(rng.barajar(funciones.sorted()).prefix(4))
                let orden = ["SUJ", "NV", "CD", "CI", "ATR", "CCL", "CCT", "CCM", "CCC"]
                let categorias = orden.filter(usadas.contains).map { ElementoNombre(id: $0, nombre: Self.nombre($0, copulativa: copulativa)) }
                let fichas = conVerbo.sorted { $0.1 < $1.1 }.filter { usadas.contains($0.0) }.enumerated()
                    .map { Payload.Clasificar.Ficha(id: "g\($0.offset + 1)", texto: texto($0.element), categoria: $0.element.0) }
                return Muestra(clave: "funciones|\(o.texto)|\(usadas.sorted().joined(separator: ","))", valores: ["oracion": o.texto, "sintagma": ""],
                               payload: .clasificar(Payload.Clasificar(categorias: categorias, fichas: rng.barajar(fichas))),
                               explicacion: explicacion, pistas: [pistaConcordancia, "Pregunta al verbo: «¿qué?» (CD), «¿a quién?» (CI), «¿dónde?», «¿cuándo?», «¿cómo?», «¿con quién?» (CC)."],
                               complejidad: complejidad, datos: datos)
            case .clasificar:
                // El validador admite 2–4 categorías: con más clases en la oración se eligen 4 al azar
                // y solo se clasifican las palabras de esas clases. Las contracciones («al») y los
                // numerales no se clasifican (no tienen una sola clase inequívoca).
                let clasificables = Array(Set(o.tokens.map(\.1)).subtracting(["contr", "num"])).sorted()
                let usadas = Array(rng.barajar(clasificables).prefix(4)).sorted()
                guard usadas.count >= 2 else { continue }
                let categorias = usadas.map { ElementoNombre(id: $0, nombre: Self.clases[$0] ?? $0) }
                let fichas = zip(ids, o.tokens).filter { usadas.contains($1.1) }.map { Payload.Clasificar.Ficha(id: $0, texto: $1.0, categoria: $1.1) }
                return Muestra(clave: "clasificar|\(o.texto)", valores: ["oracion": o.texto, "sintagma": ""],
                               payload: .clasificar(Payload.Clasificar(categorias: categorias, fichas: rng.barajar(fichas))),
                               explicacion: o.tokens.map { "\($0.0): \((Self.clases[$0.1] ?? $0.1).lowercased())" }.joined(separator: "; ") + ".",
                               pistas: ["Los determinantes acompañan al sustantivo; las preposiciones introducen complementos."],
                               complejidad: complejidad, datos: datos)
            default:
                switch modo {
                case "clase":
                    let correcta = Self.claseOracion(regimen: o.regimen)
                    let porque = switch o.regimen {
                    case "copulativo": "«\(texto(nv))» es un verbo copulativo y «\(o.atributo ?? "")» es el atributo: predicado nominal."
                    case "transitivo": "Tiene complemento directo («\(grupos.first { $0.0 == "CD" }.map(texto) ?? "")»): predicado verbal con CD."
                    default: "El verbo no lleva complemento directo ni atributo: predicado verbal sin CD."
                    }
                    let otras = ["Copulativa (atributiva)", "Predicativa transitiva", "Predicativa intransitiva"].filter { $0 != correcta }
                    let (e, errores) = Opciones.eleccion(correcta: correcta, distractores: otras.map { ($0, porque) }, rng: &rng)
                    return Muestra(clave: "clase|\(o.texto)", valores: ["oracion": o.texto, "sintagma": ""], payload: .eleccion(e),
                                   explicacion: "\(correcta). \(porque)", erroresHabituales: errores,
                                   pistas: ["¿El verbo es ser, estar o parecer con un adjetivo? ¿Lleva complemento directo?"],
                                   complejidad: complejidad, datos: datos.merging(["clase": correcta]) { $1 })
                case "concordancia":
                    // Prueba de la concordancia: si el verbo cambia de número, solo el sujeto tiene que cambiar.
                    guard !copulativa, grupos.count >= 2,
                          let formas = Conjugador.formas(o.verbo, tiempo: concordancia?.tiempo ?? "Presente", modo: Conjugador.indicativo, irregulares: recursos.verbos.irregulares)
                    else { continue }
                    let otraForma = formas[o.sujetoNumero == "p" ? 2 : 5]
                    let correcta = texto(suj)
                    let otras = grupos.filter { $0.0 != "SUJ" }.map(texto)
                    guard Set(otras + [correcta]).count == otras.count + 1 else { continue }
                    let (e, errores) = Opciones.eleccion(correcta: correcta,
                                                         distractores: otras.map { ($0, "«\($0)» no concuerda con el verbo: puede quedarse igual.") }, rng: &rng)
                    return Muestra(clave: "concordancia|\(o.texto)", valores: ["oracion": o.texto, "sintagma": "", "forma": texto(nv), "otraForma": otraForma],
                                   payload: .eleccion(e),
                                   explicacion: "Si «\(texto(nv))» pasa a «\(otraForma)», «\(correcta)» tiene que cambiar de número: es el sujeto, porque concuerda con el verbo.",
                                   erroresHabituales: errores, pistas: [pistaConcordancia], complejidad: complejidad,
                                   datos: datos.merging(["otraForma": otraForma]) { $1 })
                case "pronombre":
                    // CD de cosa (lo, la, los, las) o CI (le, les). El CD de persona no se pregunta: «le»
                    // para el masculino singular es leísmo admitido y habría dos respuestas.
                    var objetivos: [(String, Int, Int)] = []
                    if let cd = grupos.first(where: { $0.0 == "CD" }), let lema = concordancia?.cdLema,
                       let s = recursos.compatibilidad.sustantivos.first(where: { $0.lema == lema }), !s.animado { objetivos.append(cd) }
                    if let ci = grupos.first(where: { $0.0 == "CI" }) { objetivos.append(ci) }
                    guard !objetivos.isEmpty, let c = concordancia else { continue }
                    let objetivo = rng.elemento(objetivos)
                    let lema = objetivo.0 == "CD" ? c.cdLema : c.ciLema
                    guard let s = recursos.compatibilidad.sustantivos.first(where: { $0.lema == lema }) else { continue }
                    let n = (objetivo.0 == "CD" ? c.cdNumero : c.ciNumero) ?? "s"
                    let correcta = Self.pronombre(objetivo.0, genero: s.genero, numero: n)
                    let regla = objetivo.0 == "CI" ? "El complemento indirecto se sustituye por «le» o «les»."
                        : "El complemento directo se sustituye por «lo», «la», «los» o «las», según su género y número."
                    let otras = rng.barajar(["lo", "la", "los", "las", "le", "les"].filter { $0 != correcta })
                    let (e, errores) = Opciones.eleccion(correcta: correcta, distractores: otras.map { ($0, regla) }, rng: &rng)
                    return Muestra(clave: "pronombre|\(o.texto)|\(objetivo.0)", valores: ["oracion": o.texto, "sintagma": texto(objetivo)],
                                   payload: .eleccion(e),
                                   explicacion: "«\(texto(objetivo))» es \(Self.nombres[objetivo.0]!.lowercased()): se sustituye por «\(correcta)». \(regla)",
                                   erroresHabituales: errores, pistas: [regla], complejidad: complejidad,
                                   datos: datos.merging(["objetivo": objetivo.0, "pronombre": correcta]) { $1 })
                default:
                    let candidatos = grupos
                    guard candidatos.count >= 2 || candidatos.first?.0 != "SUJ" else { continue }
                    let objetivo = rng.elemento(candidatos)
                    let t = texto(objetivo)
                    let otras = rng.barajar(["SUJ", "CD", "CI", "CCL", "CCT", "CCM", "CCC", "ATR"].filter { $0 != objetivo.0 })
                    let (e, errores) = Opciones.eleccion(correcta: Self.nombres[objetivo.0]!,
                                                         distractores: otras.map { (Self.nombres[$0]!, Self.definiciones[objetivo.0] ?? "") }, rng: &rng)
                    return Muestra(clave: "eleccion|\(o.texto)|\(objetivo.0)", valores: ["oracion": o.texto, "sintagma": t],
                                   payload: .eleccion(e), explicacion: "«\(t)» es \(Self.nombres[objetivo.0]!.lowercased()). \(Self.definiciones[objetivo.0] ?? "")",
                                   erroresHabituales: errores, pistas: [Self.definiciones[objetivo.0] ?? pistaConcordancia],
                                   complejidad: complejidad, datos: datos.merging(["objetivo": objetivo.0]) { $1 })
                }
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

/// Análisis de formas verbales con ruedas: persona, número, tiempo y modo y, con el parámetro
/// `rasgos = completo` (Fase 05E), también aspecto (perfecto o imperfecto) y forma (simple o
/// compuesta). Solo se preguntan formas que no son ambiguas dentro del paradigma del nivel (p. ej.,
/// «cantaba» es 1.ª y 3.ª persona, así que no se pregunta).
///
/// Solo verbos regulares de las tres conjugaciones: los irregulares de `verbos.json` no tienen una
/// tabla completa revisada (Fase 05E, §5) y los copulativos solo sirven a las oraciones.
///
/// | Dif. | Verbos | Tiempos |
/// |---|---|---|
/// | 1 | en -ar | presente, pretérito perfecto simple y futuro (indicativo) |
/// | 2 | tres conjugaciones | + imperfecto y condicional |
/// | 3 | tres conjugaciones | + presente de subjuntivo y pretérito perfecto compuesto |
/// | 4 (examen) | tres conjugaciones | todos los de indicativo (salvo el pretérito anterior) y de subjuntivo en -ra con sus compuestos |
/// | 5 | tres conjugaciones | + imperfecto en -se, pluscuamperfecto con «hubiese» y pretérito anterior |
/// | 6 | tres conjugaciones | + futuro simple y compuesto de subjuntivo |
struct GeneradorAnalisisVerbal: GeneradorItems {
    let tipo = "analisisVerbal"
    let mecanicas: Set<Mecanica> = [.ruedas]
    let marcadores: Set<String> = ["forma", "infinitivo", "contexto"]

    /// `tiempo` es la clave de conjugación (con la marca « (-se)» en esa variante).
    struct Opcion: Hashable { let tiempo: String; let modo: String }

    /// Verbos regulares efectivos: los de `verbos.json` y, si hay `compatibilidad.json` (D-086), sus
    /// verbos no copulativos, con su participio irregular (escrito, abierto) para los compuestos.
    static func banco(_ r: RecursosGeneradores) -> BancoVerbos {
        var b = r.verbos
        for v in r.compatibilidad.verbos where v.regimen != "copulativo" {
            if !b.regulares.contains(v.infinitivo) { b.regulares.append(v.infinitivo) }
            guard let p = v.participioIrregular else { continue }
            if let i = b.irregulares.firstIndex(where: { $0.infinitivo == v.infinitivo }) {
                if b.irregulares[i].participio == nil { b.irregulares[i].participio = p }
            } else {
                b.irregulares.append(VerboIrregular(infinitivo: v.infinitivo, participio: p, formas: [:]))
            }
        }
        // Un regular con participio irregular conserva sus formas simples regulares.
        b.regulares = b.regulares.filter { inf in b.irregulares.first { $0.infinitivo == inf }?.formas.isEmpty ?? true }
        return b
    }

    static func nivel(_ d: Int, _ banco: BancoVerbos) -> (verbos: [String], tiempos: [Opcion]) {
        let ind = Conjugador.indicativo, sub = Conjugador.subjuntivo
        let t1 = ["Presente", "Pretérito perfecto simple", "Futuro simple"].map { Opcion(tiempo: $0, modo: ind) }
        let t2 = t1 + ["Pretérito imperfecto", "Condicional simple"].map { Opcion(tiempo: $0, modo: ind) }
        let t3 = t2 + [Opcion(tiempo: "Presente", modo: sub), Opcion(tiempo: "Pretérito perfecto compuesto", modo: ind)]
        let t4 = t3 + ["Pretérito pluscuamperfecto", "Futuro compuesto", "Condicional compuesto"].map { Opcion(tiempo: $0, modo: ind) }
            + ["Pretérito imperfecto", "Pretérito perfecto compuesto", "Pretérito pluscuamperfecto"].map { Opcion(tiempo: $0, modo: sub) }
        let t5 = t4 + [Opcion(tiempo: "Pretérito anterior", modo: ind), Opcion(tiempo: "Pretérito imperfecto" + Conjugador.sufijoSe, modo: sub),
                       Opcion(tiempo: "Pretérito pluscuamperfecto" + Conjugador.sufijoSe, modo: sub)]
        let t6 = t5 + [Opcion(tiempo: "Futuro simple", modo: sub), Opcion(tiempo: "Futuro compuesto", modo: sub)]
        let regulares = banco.regulares
        switch d {
        case 1: return (regulares.filter { $0.hasSuffix("ar") }, t1)
        case 2: return (regulares, t2)
        case 3: return (regulares, t3)
        case 4: return (regulares, t4)
        case 5: return (regulares, t5)
        default: return (regulares, t6)
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
        let verbos = Self.banco(recursos)
        let todos = casos(p.dificultad, verbos)
        guard !todos.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let c = rng.elemento(todos)
        let (_, tiempos) = Self.nivel(p.dificultad, verbos)
        let ordenTiempos = Conjugador.simplesIndicativo + ["Pretérito perfecto compuesto", "Pretérito pluscuamperfecto", "Pretérito anterior", "Futuro compuesto", "Condicional compuesto"]
        let nombresTiempo = Array(Set(tiempos.map { Conjugador.nombreTiempo($0.tiempo) })).sorted { a, b in
            (ordenTiempos.firstIndex(of: a) ?? 99, a) < (ordenTiempos.firstIndex(of: b) ?? 99, b)
        }
        let tiempo = Conjugador.nombreTiempo(c.op.tiempo)
        let persona = Conjugador.personas[c.indice % 3], numero = Conjugador.numeros[c.indice / 3]
        let compuesto = Conjugador.esCompuesto(c.op.tiempo)
        let aspecto = Conjugador.aspecto(c.op.tiempo, modo: c.op.modo)
        let forma = compuesto ? "Compuesta" : "Simple"
        let completo = p.textos("rasgos", porDefecto: ["basico"]).first == "completo"
        var ruedas = [
            Payload.Ruedas.Rueda(id: "persona", nombre: "Persona", opciones: Conjugador.personas, correcta: persona),
            Payload.Ruedas.Rueda(id: "numero", nombre: "Número", opciones: Conjugador.numeros, correcta: numero),
            Payload.Ruedas.Rueda(id: "tiempo", nombre: "Tiempo", opciones: nombresTiempo, correcta: tiempo),
            Payload.Ruedas.Rueda(id: "modo", nombre: "Modo", opciones: [Conjugador.indicativo, Conjugador.subjuntivo], correcta: c.op.modo),
        ]
        if completo {
            ruedas.append(.init(id: "aspecto", nombre: "Aspecto", opciones: ["Perfecto", "Imperfecto"], correcta: aspecto))
            ruedas.append(.init(id: "forma", nombre: "Forma", opciones: ["Simple", "Compuesta"], correcta: forma))
        }
        let descripcion = "\(persona) persona del \(numero.lowercased()) del \(tiempo.lowercased()) de \(c.op.modo.lowercased())"
        var explicacion = "«\(c.forma)»: \(descripcion) del verbo \(c.verbo)."
        if completo {
            explicacion += compuesto ? " Forma compuesta (haber + participio), de aspecto perfecto: la acción se presenta acabada."
                : (aspecto == "Perfecto" ? " Forma simple de aspecto perfecto: el pretérito perfecto simple presenta la acción acabada."
                   : " Forma simple de aspecto imperfecto: la acción no se presenta acabada.")
        }
        var errores = [ErrorHabitual(respuesta: "tiempo", feedback: compuesto ? "Las formas con «haber» + participio son tiempos compuestos." : "Fíjate en la terminación: indica el tiempo."),
                       ErrorHabitual(respuesta: "modo", feedback: "El subjuntivo expresa deseo, duda o posibilidad («que yo cante»).")]
        if completo {
            errores.append(ErrorHabitual(respuesta: "aspecto", feedback: "Son perfectos los tiempos compuestos y el pretérito perfecto simple; el resto de los simples son imperfectos."))
            errores.append(ErrorHabitual(respuesta: "forma", feedback: "Es compuesta si lleva el auxiliar «haber» y un participio."))
        }
        return Muestra(clave: "\(c.verbo)|\(c.op.tiempo)|\(c.op.modo)|\(c.indice)", valores: ["forma": c.forma, "infinitivo": c.verbo],
                       payload: .ruedas(Payload.Ruedas(ruedas: ruedas)),
                       explicacion: explicacion, erroresHabituales: errores,
                       pistas: ["Empieza por la terminación: te dice la persona y el número.", "Si lleva «haber» + participio, es una forma compuesta."],
                       complejidad: Double(tiempos.count) * 0.3 + (compuesto ? 1 : 0) + (c.op.modo == Conjugador.subjuntivo ? 1 : 0)
                           + (c.op.tiempo.hasSuffix(Conjugador.sufijoSe) || c.op.tiempo == "Pretérito anterior" ? 0.5 : 0),
                       datos: ["forma": c.forma, "verbo": c.verbo, "tiempo": tiempo, "clave": c.op.tiempo, "modo": c.op.modo, "persona": persona,
                               "numero": numero, "aspecto": aspecto, "compuesta": compuesto ? "1" : "0"])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(casos(p.dificultad, Self.banco(recursos)).map { "\($0.verbo)|\($0.op.tiempo)|\($0.op.modo)|\($0.indice)" }.prefix(limite))
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
        // Sin frases de ese nivel ni de los inferiores: las del nivel más fácil que haya (no todas,
        // para que la dificultad no decrezca con el nivel pedido).
        guard let minimo = validas.map(\.dificultad).min() else { return [] }
        return validas.filter { $0.dificultad == minimo }
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
