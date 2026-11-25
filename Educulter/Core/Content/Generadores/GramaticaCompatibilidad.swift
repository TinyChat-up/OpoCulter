import Foundation

// MARK: - Compatibilidad semántica (gramatica/compatibilidad.json, lote 02b, D-086, D-090)

/// Formato neutro de la dirección (lote 02b): sustantivos y adjetivos con etiquetas semánticas
/// (las finas para el CD: `abrible`, `comprable`, `prestable`, `lavable`…), verbos con el sujeto y
/// el objeto que admiten, y complementos circunstanciales por tipo. La gramática generativa lo
/// usa para que ninguna oración sea absurda (D-086) y para que suene natural (D-090).
struct CompatibilidadGramatica: Codable, Sendable, Equatable {
    struct Sustantivo: Codable, Sendable, Equatable {
        var lema: String
        var genero: String
        var plural: String
        var etiquetas: [String]

        func forma(_ numero: String) -> String { numero == "p" ? plural : lema }
        /// Persona o animal: como CD o CI va con «a» («a la vecina», «al perro», «a su abuela»).
        var animado: Bool { etiquetas.contains("persona") || etiquetas.contains("animal") }
        /// Leche, café, sopa, zumo (D-090): nunca en plural.
        var incontable: Bool { etiquetas.contains("incontable") }
    }

    struct Adjetivo: Codable, Sendable, Equatable {
        var ms: String
        var fs: String
        var mp: String
        var fp: String
        var etiquetas: [String]
        /// `cualidad` (ser y parecer) o `estado` (estar y parecer) (D-090).
        var tipo: String?

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
        /// Copulativos: tipos de adjetivo que admite como atributo (`cualidad`, `estado`).
        var atributo: [String]?
    }

    var version: Int = 0
    var sustantivos: [Sustantivo] = []
    var adjetivos: [Adjetivo] = []
    var verbos: [Verbo] = []
    /// CCL, CCT, CCM y CCC.
    var complementosCircunstanciales: [String: [String]] = [:]
    /// Aspecto de cada CCT (D-090): `puntual`, `habitual` o `neutro`.
    var aspectoCCT: [String: String] = [:]
    /// Verbos que nunca van con un CCT habitual (comprar, regalar, prestar).
    var sinHabitual: [String] = []
    /// CC que no casan con ciertos verbos («nadar en la biblioteca», «descansar deprisa») (D-090).
    var ccExcluye: [String: [String]] = [:]
    /// CC de compañía que solo van con sujeto de persona («con su hermana»).
    var ccSoloPersona: [String] = []
    /// Sustantivos que como CD o CI solo llevan artículo, nunca posesivo (niño, niña, cocinero).
    var sinPosesivo: [String] = ["niño", "niña"]
    /// Tiempos de cada verbo copulativo («El libro será grande» suena forzado).
    var tiemposCopulativos: [String: [String]] = [:]
    /// Tipos de CC que pueden ir delante del sujeto (CCT y CCL).
    var ccDelante: [String] = ["CCT", "CCL"]

    var vacia: Bool { verbos.isEmpty || sustantivos.isEmpty }

    /// Complementos que no se usan en la generación: «junto al río» (locución con contracción, sin
    /// clase de palabra inequívoca para `clasificar`, D-081).
    static let complementosExcluidos: Set<String> = ["junto al río"]
    static let preposiciones: Set<String> = ["a", "en", "por", "con", "para", "de", "desde", "hasta"]
    static let tiempos = ["Presente", "Pretérito perfecto simple", "Pretérito imperfecto", "Futuro simple"]

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

    /// Clase de palabra de un token de complemento circunstancial (det, prep, adv, sust o num).
    static func clase(_ palabra: String, tras anterior: String?) -> String {
        let determinantes: Set<String> = ["el", "la", "los", "las", "su", "sus", "todos", "todas", "un", "una"]
        let adverbios: Set<String> = ["ayer", "hoy", "deprisa", "despacio", "tranquilamente", "mañana", "siempre", "pronto", "tarde"]
        let numerales: Set<String> = ["una", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez"]
        if preposiciones.contains(palabra) { return "prep" }
        // «a las cinco»: tras un determinante, el numeral (no se clasifica).
        if let anterior, determinantes.contains(anterior), numerales.contains(palabra) { return "num" }
        if determinantes.contains(palabra) { return "det" }
        // «por la mañana»: tras un determinante, «mañana» es sustantivo.
        if let anterior, determinantes.contains(anterior) { return "sust" }
        return adverbios.contains(palabra) ? "adv" : "sust"
    }

    /// Preposición inicial de un complemento («en el parque» → «en»), si la tiene.
    static func preposicionInicial(_ texto: String) -> String? {
        guard let primera = texto.split(separator: " ").first.map(String.init), preposiciones.contains(primera) else { return nil }
        return primera
    }

    /// Tiempos verbales compatibles con un CCT según su aspecto (D-090): «ayer», solo pretérito
    /// perfecto simple; puntual, presente, pretérito perfecto simple o futuro; habitual, presente o
    /// imperfecto; neutro, los cuatro.
    func tiempos(paraCCT texto: String) -> [String] {
        if texto == "ayer" { return ["Pretérito perfecto simple"] }
        switch aspectoCCT[texto] {
        case "puntual": return ["Presente", "Pretérito perfecto simple", "Futuro simple"]
        case "habitual": return ["Presente", "Pretérito imperfecto"]
        default: return Self.tiempos
        }
    }
}

// MARK: - Oración con compatibilidad

extension GeneradorOracionSimple {
    /// Orden de los constituyentes (D-090).
    enum OrdenOracion: String, Sendable {
        /// S V [CD] [CI] [ATR] [CC…]
        case canonico
        /// CC, S V [CD] [CI] [CC…]
        case ccDelante
        /// CC, V S [CC…] (sujeto pospuesto)
        case sujetoPospuesto
    }

    /// Estructura de la oración por nivel (D-090).
    ///
    /// | Nivel | Estructura |
    /// |---|---|
    /// | 1 | S + V intransitivo |
    /// | 2 | S + V + CD |
    /// | 3 | S + V + CC |
    /// | 4 | Copulativa: S + V copulativo + atributo |
    /// | 5 | S + V + CD + CI, o S + V + dos CC |
    /// | 6 | Orden alterado: CC delante con coma (y sujeto pospuesto con verbo intransitivo) |
    struct Estructura: Equatable, Sendable {
        var regimen: String
        var conCI = false
        var numeroCC = 0
        var orden: OrdenOracion = .canonico

        static func nivel(_ n: Int, permitirDesorden: Bool, rng: inout GeneradorConSemilla) -> Estructura {
            switch n {
            case 1: return Estructura(regimen: "intransitivo")
            case 2: return Estructura(regimen: "transitivo")
            case 3: return Estructura(regimen: "intransitivo", numeroCC: 1)
            case 4: return Estructura(regimen: "copulativo")
            case 5: return rng.probabilidad(0.5) ? Estructura(regimen: "transitivo", conCI: true)
                                                 : Estructura(regimen: "intransitivo", numeroCC: 2)
            default:
                // `segmentar` necesita el predicado seguido: allí el nivel 6 es la estructura más
                // larga en orden canónico (S + V + CD + CI + CC).
                guard permitirDesorden else { return Estructura(regimen: "transitivo", conCI: true, numeroCC: 1) }
                return rng.probabilidad(0.5) ? Estructura(regimen: "intransitivo", numeroCC: rng.entero(1...2), orden: .sujetoPospuesto)
                                             : Estructura(regimen: "transitivo", conCI: rng.probabilidad(0.5), numeroCC: 1, orden: .ccDelante)
            }
        }
    }

    /// Datos de la oración para el oráculo de los tests (no se muestran): la estructura elegida,
    /// de la que el oráculo deduce el análisis sin leer el texto.
    struct Concordancia: Equatable {
        var sujetoLema: String
        var cdLema: String?
        var ciLema: String?
        /// `forma|lema|genero|numero` de cada adjetivo con el sustantivo al que califica.
        var adjetivos: [String]
        /// Tipos de CC en orden de aparición.
        var circunstanciales: [String]
        var tiempo: String
        /// `funcion=texto` de cada CC, en el orden en que se eligieron (el primero va delante si el orden lo pide).
        var textosCC: [String] = []
        /// Determinante del CD y del CI animados: `art` o `pos`.
        var cdDeterminante: String?
        var ciDeterminante: String?
        var cdNumero: String?
        var ciNumero: String?
        /// Atributo de las copulativas: forma masculina singular del adjetivo (su lema).
        var atributoLema: String?
        var orden: OrdenOracion = .canonico
    }

    /// Construye una oración con `compatibilidad.json` (D-086, D-090):
    /// - sujeto y CD de etiquetas compatibles con el verbo (`sujeto`, `objeto`); incontables en singular;
    /// - CD y CI de persona o animal con «a» + artículo definido («a la vecina», «al médico») o
    ///   posesivo («a su abuela»); niño y niña, solo con artículo; el CI siempre es una persona, nunca
    ///   el mismo referente que el sujeto (ni que el CD);
    /// - CC de tipos distintos y que no empiezan por la misma preposición; el CCT impone el tiempo
    ///   según su aspecto y el habitual no va con comprar, regalar ni prestar;
    /// - copulativas con ser (cualidad), estar (estado) y parecer (ambos): predicado nominal;
    /// - concordancia artículo-sustantivo-adjetivo (género y número) y sujeto-verbo (número).
    func construirCompatible(_ nivel: Int, _ c: CompatibilidadGramatica, piezas g: PiezasGramatica, verbos banco: BancoVerbos,
                             permitirDesorden: Bool, rng: inout GeneradorConSemilla) -> (Oracion, Concordancia)? {
        let e = Estructura.nivel(nivel, permitirDesorden: permitirDesorden, rng: &rng)
        let posibles = c.verbos.filter { v in
            v.regimen == e.regimen
                && (!e.conCI || v.admiteCI)
                && (e.regimen == "copulativo" || c.sustantivos.contains { c.comparten($0.etiquetas, v.sujeto) })
                && (v.regimen != "transitivo" || c.sustantivos.contains { c.comparten($0.etiquetas, v.objeto) })
        }
        guard !posibles.isEmpty else { return nil }
        let v = rng.elemento(posibles)
        var adjetivos: [String] = []

        // Sujeto (y atributo en las copulativas).
        var atributo: CompatibilidadGramatica.Adjetivo?
        let sujeto: CompatibilidadGramatica.Sustantivo
        if v.regimen == "copulativo" {
            let tipos = Set(v.atributo ?? [])
            let candidatos = c.adjetivos.filter { a in tipos.contains(a.tipo ?? "") && c.sustantivos.contains { c.comparten(a.etiquetas, $0.etiquetas) } }
            guard !candidatos.isEmpty else { return nil }
            let a = rng.elemento(candidatos)
            atributo = a
            sujeto = rng.elemento(c.sustantivos.filter { c.comparten(a.etiquetas, $0.etiquetas) })
        } else {
            sujeto = rng.elemento(c.sustantivos.filter { c.comparten($0.etiquetas, v.sujeto) })
        }
        let numero = sujeto.incontable ? "s" : (rng.probabilidad(0.5) ? "p" : "s")

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
        /// Persona o animal como CD o CI: «a» + artículo («al médico», «a las vecinas») o posesivo
        /// («a su abuela», «a sus vecinos»); niño y niña, solo con artículo (D-090).
        func animado(_ s: CompatibilidadGramatica.Sustantivo, numero n: String) -> (tokens: [(String, String)], determinante: String) {
            let posesivo = !c.sinPosesivo.contains(s.lema) && rng.probabilidad(0.4)
            if posesivo { return ([("a", "prep"), (n == "p" ? "sus" : "su", "det"), (s.forma(n), "sust")], "pos") }
            let art = CompatibilidadGramatica.articulo(genero: s.genero, numero: n)
            if art == "el" { return ([("al", "contr"), (s.forma(n), "sust")], "art") }
            return ([("a", "prep"), (art, "det"), (s.forma(n), "sust")], "art")
        }

        var concordancia = Concordancia(sujetoLema: sujeto.lema, adjetivos: [], circunstanciales: [], tiempo: "")
        var funciones: [(String, [(String, String)])] = []
        var cd: CompatibilidadGramatica.Sustantivo?
        if v.regimen == "transitivo" {
            let candidatos = c.sustantivos.filter { c.comparten($0.etiquetas, v.objeto) && $0.lema != sujeto.lema }
            guard !candidatos.isEmpty else { return nil }
            let o = rng.elemento(candidatos)
            cd = o
            let n = o.incontable ? "s" : (rng.probabilidad(0.3) ? "p" : "s")
            concordancia.cdNumero = n
            if o.animado {
                let (t, det) = animado(o, numero: n)
                concordancia.cdDeterminante = det
                funciones.append(("CD", t))
            } else {
                funciones.append(("CD", nominal(o, numero: n, conAdjetivo: nivel >= 5 && rng.probabilidad(0.4))))
            }
        }
        if let a = atributo {
            let forma = a.forma(genero: sujeto.genero, numero: numero)
            concordancia.atributoLema = a.ms
            funciones.append(("ATR", [(forma, "adj")]))
        }
        var ci: CompatibilidadGramatica.Sustantivo?
        if e.conCI {
            // CI de persona, ≠ sujeto (y ≠ CD): nunca el mismo referente.
            let candidatos = c.sustantivos.filter { $0.etiquetas.contains("persona") && $0.lema != sujeto.lema && $0.lema != cd?.lema }
            guard !candidatos.isEmpty else { return nil }
            let p = rng.elemento(candidatos)
            ci = p
            let n = rng.probabilidad(0.3) ? "p" : "s"
            let (t, det) = animado(p, numero: n)
            concordancia.ciNumero = n
            concordancia.ciDeterminante = det
            funciones.append(("CI", t))
        }

        // Complementos circunstanciales: tipos distintos y sin repetir la preposición inicial.
        var circunstanciales: [(String, String)] = []
        var preposicionesUsadas = Set<String>()
        var tiempos = v.regimen == "copulativo" ? (c.tiemposCopulativos[v.infinitivo] ?? CompatibilidadGramatica.tiempos) : CompatibilidadGramatica.tiempos
        // Con el orden alterado, el CC que va delante (el primero) es de tiempo o de lugar.
        var tipos = rng.barajar(["CCL", "CCT", "CCM", "CCC"])
        if e.orden != .canonico, let i = tipos.firstIndex(where: c.ccDelante.contains) { tipos.insert(tipos.remove(at: i), at: 0) }
        for t in tipos where circunstanciales.count < e.numeroCC {
            let opciones = (c.complementosCircunstanciales[t] ?? []).filter { texto in
                !CompatibilidadGramatica.complementosExcluidos.contains(texto)
                    && !(c.ccExcluye[texto] ?? []).contains(v.infinitivo)
                    && !(c.ccSoloPersona.contains(texto) && !sujeto.etiquetas.contains("persona"))
                    && !(CompatibilidadGramatica.preposicionInicial(texto).map(preposicionesUsadas.contains) ?? false)
                    && !(t == "CCT" && c.aspectoCCT[texto] == "habitual" && c.sinHabitual.contains(v.infinitivo))
                    && !(t == "CCT" && Set(tiempos).isDisjoint(with: c.tiempos(paraCCT: texto)))
            }
            guard !opciones.isEmpty else { continue }
            let texto = rng.elemento(opciones)
            if let p = CompatibilidadGramatica.preposicionInicial(texto) { preposicionesUsadas.insert(p) }
            if t == "CCT" { tiempos = tiempos.filter(c.tiempos(paraCCT: texto).contains) }
            circunstanciales.append((t, texto))
        }
        guard circunstanciales.count == e.numeroCC, !tiempos.isEmpty,
              e.orden == .canonico || circunstanciales.first.map({ c.ccDelante.contains($0.0) }) == true else { return nil }
        let tiempo = rng.elemento(tiempos)
        guard let formas = Conjugador.formas(v.infinitivo, tiempo: tiempo, modo: Conjugador.indicativo, irregulares: banco.irregulares) else { return nil }
        let formaVerbo = formas[numero == "p" ? 5 : 2]

        func tokensCC(_ texto: String) -> [(String, String)] {
            let palabras = texto.split(separator: " ").map(String.init)
            return palabras.enumerated().map { (i, p) in (p, CompatibilidadGramatica.clase(p, tras: i > 0 ? palabras[i - 1] : nil)) }
        }

        // Montaje según el orden.
        var tokens: [(String, String)] = []
        var constituyentes: [(String, Int, Int)] = []
        var comaTras: Int?
        func anadir(_ f: String, _ t: [(String, String)]) {
            let desde = tokens.count
            tokens += t
            constituyentes.append((f, desde, tokens.count - 1))
        }
        let sujetoTokens = nominal(sujeto, numero: numero, conAdjetivo: v.regimen != "copulativo" && nivel >= 5 && rng.probabilidad(0.3))
        var restoCC = circunstanciales
        if e.orden != .canonico, !restoCC.isEmpty {
            let primero = restoCC.removeFirst()
            anadir(primero.0, tokensCC(primero.1))
            comaTras = tokens.count - 1
        }
        if e.orden == .sujetoPospuesto {
            anadir("NV", [(formaVerbo, "verbo")])
            anadir("SUJ", sujetoTokens)
        } else {
            anadir("SUJ", sujetoTokens)
            anadir("NV", [(formaVerbo, "verbo")])
        }
        for (f, t) in funciones { anadir(f, t) }
        for cc in restoCC { anadir(cc.0, tokensCC(cc.1)) }
        // El predicado solo es un segmento cuando va seguido (orden canónico).
        if e.orden == .canonico, let nv = constituyentes.first(where: { $0.0 == "NV" }) {
            constituyentes.append(("PRED", nv.1, tokens.count - 1))
        }
        if let primero = tokens.first?.0 { tokens[0].0 = primero.prefix(1).uppercased() + primero.dropFirst() }
        // El sujeto y el NV van primero en la lista de constituyentes (lo esperan las mecánicas).
        constituyentes.sort { a, b in
            let orden = ["SUJ": 0, "NV": 1]
            return (orden[a.0] ?? 2, a.1) < (orden[b.0] ?? 2, b.1)
        }
        var o = Oracion(tokens: tokens, constituyentes: constituyentes, sujetoNumero: numero, sujetoGenero: sujeto.genero,
                        verbo: v.infinitivo, regimen: v.regimen, atributo: atributo.map { $0.forma(genero: sujeto.genero, numero: numero) })
        o.comaTras = comaTras
        concordancia.cdLema = cd?.lema
        concordancia.ciLema = ci?.lema
        concordancia.adjetivos = adjetivos
        concordancia.circunstanciales = constituyentes.filter { $0.0.hasPrefix("CC") }.sorted { $0.1 < $1.1 }.map(\.0)
        concordancia.textosCC = circunstanciales.map { "\($0.0)=\($0.1)" }
        concordancia.tiempo = tiempo
        concordancia.orden = e.orden
        return (o, concordancia)
    }
}
