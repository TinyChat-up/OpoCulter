import Foundation
import Testing
@testable import Educulter

// Fase 05E, parte 1: mapa curricular, palabras ambiguas, verbo (paradigmas escritos a mano),
// formas no personales, literatura y comprobaciones de las plantillas nuevas.

let banco05E: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 1))!

enum Oraculo05E {
    /// Modo de una plantilla de `oracionSimple` según sus parámetros (con los valores por defecto).
    static func modo(_ p: Plantilla) -> String {
        if let m = p.parametros["modo"]?.textos?.first { return m }
        switch p.mecanica {
        case .marcarTexto: return "sujeto"
        case .segmentar: return "completo"
        case .clasificar: return "clases"
        default: return "funcion"
        }
    }

    // MARK: Paradigmas escritos a mano (modelos regulares de la RAE: amar, temer, partir)

    static let tiemposSimples = [
        "Indicativo|Presente", "Indicativo|Pretérito imperfecto", "Indicativo|Pretérito perfecto simple", "Indicativo|Futuro simple",
        "Indicativo|Condicional simple", "Subjuntivo|Presente", "Subjuntivo|Pretérito imperfecto", "Subjuntivo|Pretérito imperfecto (-se)",
        "Subjuntivo|Futuro simple",
    ]
    static let tiemposCompuestos = [
        "Indicativo|Pretérito perfecto compuesto", "Indicativo|Pretérito pluscuamperfecto", "Indicativo|Pretérito anterior",
        "Indicativo|Futuro compuesto", "Indicativo|Condicional compuesto", "Subjuntivo|Pretérito perfecto compuesto",
        "Subjuntivo|Pretérito pluscuamperfecto", "Subjuntivo|Pretérito pluscuamperfecto (-se)", "Subjuntivo|Futuro compuesto",
    ]

    /// Formas personales: 9 tiempos simples y 9 compuestos, en el orden de las listas anteriores
    /// (cada línea, las 6 personas). Imperativo (tú, vosotros) y formas no personales aparte.
    static let paradigmas: [String: (simples: [String], compuestos: [String], imperativo: [String], noPersonales: [String])] = [
        "amar": (
            simples: [
                "amo amas ama amamos amáis aman",
                "amaba amabas amaba amábamos amabais amaban",
                "amé amaste amó amamos amasteis amaron",
                "amaré amarás amará amaremos amaréis amarán",
                "amaría amarías amaría amaríamos amaríais amarían",
                "ame ames ame amemos améis amen",
                "amara amaras amara amáramos amarais amaran",
                "amase amases amase amásemos amaseis amasen",
                "amare amares amare amáremos amareis amaren",
            ],
            compuestos: [
                "he amado,has amado,ha amado,hemos amado,habéis amado,han amado",
                "había amado,habías amado,había amado,habíamos amado,habíais amado,habían amado",
                "hube amado,hubiste amado,hubo amado,hubimos amado,hubisteis amado,hubieron amado",
                "habré amado,habrás amado,habrá amado,habremos amado,habréis amado,habrán amado",
                "habría amado,habrías amado,habría amado,habríamos amado,habríais amado,habrían amado",
                "haya amado,hayas amado,haya amado,hayamos amado,hayáis amado,hayan amado",
                "hubiera amado,hubieras amado,hubiera amado,hubiéramos amado,hubierais amado,hubieran amado",
                "hubiese amado,hubieses amado,hubiese amado,hubiésemos amado,hubieseis amado,hubiesen amado",
                "hubiere amado,hubieres amado,hubiere amado,hubiéremos amado,hubiereis amado,hubieren amado",
            ],
            imperativo: ["ama", "amad"],
            noPersonales: ["amar", "amando", "amado", "haber amado", "habiendo amado"]
        ),
        "temer": (
            simples: [
                "temo temes teme tememos teméis temen",
                "temía temías temía temíamos temíais temían",
                "temí temiste temió temimos temisteis temieron",
                "temeré temerás temerá temeremos temeréis temerán",
                "temería temerías temería temeríamos temeríais temerían",
                "tema temas tema temamos temáis teman",
                "temiera temieras temiera temiéramos temierais temieran",
                "temiese temieses temiese temiésemos temieseis temiesen",
                "temiere temieres temiere temiéremos temiereis temieren",
            ],
            compuestos: [
                "he temido,has temido,ha temido,hemos temido,habéis temido,han temido",
                "había temido,habías temido,había temido,habíamos temido,habíais temido,habían temido",
                "hube temido,hubiste temido,hubo temido,hubimos temido,hubisteis temido,hubieron temido",
                "habré temido,habrás temido,habrá temido,habremos temido,habréis temido,habrán temido",
                "habría temido,habrías temido,habría temido,habríamos temido,habríais temido,habrían temido",
                "haya temido,hayas temido,haya temido,hayamos temido,hayáis temido,hayan temido",
                "hubiera temido,hubieras temido,hubiera temido,hubiéramos temido,hubierais temido,hubieran temido",
                "hubiese temido,hubieses temido,hubiese temido,hubiésemos temido,hubieseis temido,hubiesen temido",
                "hubiere temido,hubieres temido,hubiere temido,hubiéremos temido,hubiereis temido,hubieren temido",
            ],
            imperativo: ["teme", "temed"],
            noPersonales: ["temer", "temiendo", "temido", "haber temido", "habiendo temido"]
        ),
        "partir": (
            simples: [
                "parto partes parte partimos partís parten",
                "partía partías partía partíamos partíais partían",
                "partí partiste partió partimos partisteis partieron",
                "partiré partirás partirá partiremos partiréis partirán",
                "partiría partirías partiría partiríamos partiríais partirían",
                "parta partas parta partamos partáis partan",
                "partiera partieras partiera partiéramos partierais partieran",
                "partiese partieses partiese partiésemos partieseis partiesen",
                "partiere partieres partiere partiéremos partiereis partieren",
            ],
            compuestos: [
                "he partido,has partido,ha partido,hemos partido,habéis partido,han partido",
                "había partido,habías partido,había partido,habíamos partido,habíais partido,habían partido",
                "hube partido,hubiste partido,hubo partido,hubimos partido,hubisteis partido,hubieron partido",
                "habré partido,habrás partido,habrá partido,habremos partido,habréis partido,habrán partido",
                "habría partido,habrías partido,habría partido,habríamos partido,habríais partido,habrían partido",
                "haya partido,hayas partido,haya partido,hayamos partido,hayáis partido,hayan partido",
                "hubiera partido,hubieras partido,hubiera partido,hubiéramos partido,hubierais partido,hubieran partido",
                "hubiese partido,hubieses partido,hubiese partido,hubiésemos partido,hubieseis partido,hubiesen partido",
                "hubiere partido,hubieres partido,hubiere partido,hubiéremos partido,hubiereis partido,hubieren partido",
            ],
            imperativo: ["parte", "partid"],
            noPersonales: ["partir", "partiendo", "partido", "haber partido", "habiendo partido"]
        ),
    ]

    static func manuscrito(_ verbo: String) -> [String: [String]] {
        let p = paradigmas[verbo]!
        var r: [String: [String]] = [:]
        for (k, l) in zip(tiemposSimples, p.simples) { r[k] = l.split(separator: " ").map(String.init) }
        for (k, l) in zip(tiemposCompuestos, p.compuestos) { r[k] = l.split(separator: ",").map(String.init) }
        return r
    }

    // MARK: Tabla de conjugación por reglas (independiente del generador)

    static let haber: [String: [String]] = [
        "Indicativo|Presente": ["he", "has", "ha", "hemos", "habéis", "han"],
        "Indicativo|Pretérito imperfecto": ["había", "habías", "había", "habíamos", "habíais", "habían"],
        "Indicativo|Pretérito perfecto simple": ["hube", "hubiste", "hubo", "hubimos", "hubisteis", "hubieron"],
        "Indicativo|Futuro simple": ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"],
        "Indicativo|Condicional simple": ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"],
        "Subjuntivo|Presente": ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"],
        "Subjuntivo|Pretérito imperfecto": ["hubiera", "hubieras", "hubiera", "hubiéramos", "hubierais", "hubieran"],
        "Subjuntivo|Pretérito imperfecto (-se)": ["hubiese", "hubieses", "hubiese", "hubiésemos", "hubieseis", "hubiesen"],
        "Subjuntivo|Futuro simple": ["hubiere", "hubieres", "hubiere", "hubiéremos", "hubiereis", "hubieren"],
    ]
    static let auxiliar: [String: String] = [
        "Indicativo|Pretérito perfecto compuesto": "Indicativo|Presente", "Indicativo|Pretérito pluscuamperfecto": "Indicativo|Pretérito imperfecto",
        "Indicativo|Pretérito anterior": "Indicativo|Pretérito perfecto simple", "Indicativo|Futuro compuesto": "Indicativo|Futuro simple",
        "Indicativo|Condicional compuesto": "Indicativo|Condicional simple", "Subjuntivo|Pretérito perfecto compuesto": "Subjuntivo|Presente",
        "Subjuntivo|Pretérito pluscuamperfecto": "Subjuntivo|Pretérito imperfecto",
        "Subjuntivo|Pretérito pluscuamperfecto (-se)": "Subjuntivo|Pretérito imperfecto (-se)", "Subjuntivo|Futuro compuesto": "Subjuntivo|Futuro simple",
    ]

    /// Paradigma completo de un verbo regular por reglas: tema + vocal temática + desinencias.
    static func reglas(_ inf: String, participio: String? = nil) -> [String: [String]] {
        let tema = String(inf.dropLast(2)), vocal = inf.dropLast().last!
        let primera = vocal == "a"
        let personas = [0, 1, 2, 3, 4, 5]
        func pegar(_ d: [String]) -> [String] { d.map { tema + $0 } }
        var r: [String: [String]] = [:]
        let presente: [String] = vocal == "a" ? ["o", "as", "a", "amos", "áis", "an"] : (vocal == "e" ? ["o", "es", "e", "emos", "éis", "en"] : ["o", "es", "e", "imos", "ís", "en"])
        r["Indicativo|Presente"] = pegar(presente)
        r["Indicativo|Pretérito imperfecto"] = pegar(primera ? ["aba", "abas", "aba", "ábamos", "abais", "aban"] : ["ía", "ías", "ía", "íamos", "íais", "ían"])
        r["Indicativo|Pretérito perfecto simple"] = pegar(primera ? ["é", "aste", "ó", "amos", "asteis", "aron"] : ["í", "iste", "ió", "imos", "isteis", "ieron"])
        r["Indicativo|Futuro simple"] = personas.map { inf + ["é", "ás", "á", "emos", "éis", "án"][$0] }
        r["Indicativo|Condicional simple"] = personas.map { inf + ["ía", "ías", "ía", "íamos", "íais", "ían"][$0] }
        let v = primera ? "e" : "a"
        r["Subjuntivo|Presente"] = pegar([v, v + "s", v, v + "mos", (v == "e" ? "é" : "á") + "is", v + "n"])
        let pi = primera ? "a" : "ie", piT = primera ? "á" : "ié"
        r["Subjuntivo|Pretérito imperfecto"] = pegar([pi + "ra", pi + "ras", pi + "ra", piT + "ramos", pi + "rais", pi + "ran"])
        r["Subjuntivo|Pretérito imperfecto (-se)"] = pegar([pi + "se", pi + "ses", pi + "se", piT + "semos", pi + "seis", pi + "sen"])
        r["Subjuntivo|Futuro simple"] = pegar([pi + "re", pi + "res", pi + "re", piT + "remos", pi + "reis", pi + "ren"])
        let part = participio ?? tema + (primera ? "ado" : "ido")
        for (compuesto, aux) in auxiliar { r[compuesto] = haber[aux]!.map { "\($0) \(part)" } }
        return r
    }

    static func noPersonales(_ inf: String, participio: String? = nil) -> [String] {
        let tema = String(inf.dropLast(2)), primera = inf.hasSuffix("ar")
        let part = participio ?? tema + (primera ? "ado" : "ido")
        return [inf, tema + (primera ? "ando" : "iendo"), part, "haber \(part)", "habiendo \(part)"]
    }

    static func imperativo(_ inf: String) -> [String] {
        let tema = String(inf.dropLast(2)), vocal = inf.dropLast().last!
        return [tema + (vocal == "a" ? "a" : "e"), tema + String(vocal) + "d"]
    }

    static func aspecto(_ clave: String) -> String {
        clave.hasSuffix("compuesto") || clave.contains("pluscuamperfecto") || clave.hasSuffix("anterior") || clave == "Indicativo|Pretérito perfecto simple"
            ? "Perfecto" : "Imperfecto"
    }

    /// Participios irregulares de los datos (compatibilidad.json).
    static func participio(_ inf: String) -> String? { banco05E.recursos.compatibilidad.verbos.first { $0.infinitivo == inf }?.participioIrregular }

    /// Comprueba un ítem de analisisVerbal contra la tabla por reglas.
    static func comprobarAnalisis(_ m: Muestra, _ item: Item) -> [String] {
        guard case .ruedas(let rr) = item.payload else { return ["payload"] }
        let d = m.datos, forma = d["forma"]!, verbo = d["verbo"]!
        let tabla = reglas(verbo, participio: participio(verbo))
        let apariciones = tabla.flatMap { k, v in v.enumerated().filter { $0.element == forma }.map { (k, $0.offset) } }
        guard let (clave, indice) = apariciones.first(where: { $0.0 == "\(d["modo"]!)|\(d["clave"]!)" }) ?? apariciones.first else {
            return ["«\(forma)» no está en el paradigma por reglas de \(verbo)"]
        }
        let partes = clave.split(separator: "|").map(String.init)
        let esperado: [String: String] = [
            "persona": ["1.ª", "2.ª", "3.ª"][indice % 3], "numero": indice < 3 ? "Singular" : "Plural",
            "tiempo": partes[1].replacingOccurrences(of: " (-se)", with: ""), "modo": partes[0],
            "aspecto": aspecto(clave), "forma": forma.contains(" ") ? "Compuesta" : "Simple",
        ]
        var f: [String] = []
        for r in rr.ruedas where esperado[r.id] != r.correcta { f.append("«\(forma)» \(r.id): \(r.correcta) ≠ \(esperado[r.id]!)") }
        // No ambigua dentro de las opciones del nivel: ninguna otra celda con la misma forma y otros rasgos visibles.
        let tiempos = Set(rr.ruedas.first { $0.id == "tiempo" }!.opciones)
        let rivales = apariciones.filter { (k, i) in
            let p = k.split(separator: "|").map(String.init)
            return tiempos.contains(p[1].replacingOccurrences(of: " (-se)", with: "")) && (k != clave || i != indice)
        }
        if !rivales.isEmpty, apariciones.count > 1 {
            let nivel = GeneradorAnalisisVerbal.nivel(item.dificultad, GeneradorAnalisisVerbal.banco(banco05E.recursos)).tiempos
            let enNivel = rivales.filter { (k, _) in nivel.contains { "\($0.modo)|\($0.tiempo)" == k } }
            if !enNivel.isEmpty { f.append("«\(forma)» es ambigua: \(enNivel)") }
        }
        return f
    }

    // MARK: Formas no personales

    static func claseNoPersonal(_ forma: String) -> (clase: String, compuesta: Bool) {
        if forma.hasPrefix("habiendo ") { return ("GER", true) }
        if forma.hasPrefix("haber ") { return ("INF", true) }
        if forma.hasSuffix("ar") || forma.hasSuffix("er") || forma.hasSuffix("ir") { return ("INF", false) }
        if forma.hasSuffix("ando") || forma.hasSuffix("iendo") { return ("GER", false) }
        return ("PART", false)
    }

    static func comprobarNoPersonales(_ m: Muestra, _ item: Item) -> [String] {
        var f: [String] = []
        let verbos = GeneradorAnalisisVerbal.banco(banco05E.recursos).regulares
        let validas = Set(verbos.flatMap { noPersonales($0, participio: participio($0)) })
        switch item.payload {
        case .clasificar(let c):
            for x in c.fichas {
                if !validas.contains(x.texto) { f.append("«\(x.texto)» no es forma no personal de un verbo regular") }
                if claseNoPersonal(x.texto).clase != x.categoria { f.append("«\(x.texto)» → \(x.categoria)") }
            }
            if Set(c.fichas.map(\.texto)).count != c.fichas.count { f.append("fichas repetidas") }
        case .eleccion(let e):
            let forma = m.datos["forma"]!
            if !validas.contains(forma) { f.append("«\(forma)» no válida") }
            let (clase, compuesta) = claseNoPersonal(forma)
            let base = ["INF": "Infinitivo", "GER": "Gerundio", "PART": "Participio"][clase]!
            let distingue = e.opciones.contains { $0.texto.hasSuffix("compuesto") }
            let esperado = distingue && clase != "PART" ? base + (compuesta ? " compuesto" : " simple") : base
            if e.opciones.first(where: { $0.id == e.correcta })?.texto != esperado { f.append("«\(forma)»: \(esperado)") }
        default: f.append("payload")
        }
        return f
    }

    // MARK: Literatura

    static var literatura: BaseLiteraria { banco05E.recursos.literatura! }

    static func romano(_ n: Int) -> String {
        ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI"][n]
    }

    static func comprobarLiteratura(_ m: Muestra, _ item: Item) -> [String] {
        let base = literatura
        var f: [String] = []
        func autor(nombre: String) -> BaseLiteraria.Autor? { base.autores.first { $0.nombre == nombre } }
        switch item.payload {
        case .emparejar(let e):
            let autores = e.izquierda.compactMap { autor(nombre: $0.texto) }
            if autores.count != 4 { f.append("autores fuera de la base") }
            for a in autores where a.aproximado || a.nombre.hasPrefix("Anónimo") { f.append("autoría dudosa o anónima: \(a.nombre)") }
            for par in e.pares {
                let a = autor(nombre: e.izquierda.first { $0.id == par[0] }!.texto)
                let obra = e.derecha.first { $0.id == par[1] }!.texto
                if a?.obras.contains(where: { $0.titulo == obra }) != true { f.append("«\(obra)» no es de \(a?.nombre ?? "?")") }
                // Sin ambigüedad: ninguna otra obra mostrada es también de este autor.
                let otras = e.derecha.map(\.texto).filter { $0 != obra }
                if a?.obras.contains(where: { otras.contains($0.titulo) }) == true { f.append("dos obras de \(a!.nombre)") }
            }
        case .ordenar(let o):
            let textos = o.ordenCorrecto.map { id in o.fichas.first { $0.id == id }!.texto }
            let fechas: [Int]
            if m.datos["tipo"] == "movimientos" {
                fechas = textos.compactMap { t in base.movimientos.first { $0.nombre == t }?.inicio }
            } else {
                let autores = textos.compactMap { autor(nombre: $0) }
                for a in autores where a.aproximado || a.nacimiento == nil { f.append("fecha aproximada: \(a.nombre)") }
                fechas = autores.compactMap(\.nacimiento)
            }
            if fechas.count != 4 { f.append("elementos fuera de la base"); break }
            if fechas != fechas.sorted() { f.append("orden \(fechas)") }
            if zip(fechas.dropFirst(), fechas).contains(where: { $0 - $1 < 15 }) { f.append("menos de 15 años entre fechas: \(fechas)") }
        case .clasificar(let c):
            for x in c.fichas {
                // «Título (Autor)», o «Título (anónimo)» en las obras anónimas.
                let obras = base.autores.flatMap { a in a.obras.filter { o in
                    x.texto == "\(o.titulo) (\(a.nombre))" || (a.nombre.hasPrefix("Anónimo") && x.texto == "\(o.titulo) (anónimo)")
                } }
                guard let o = obras.first else { f.append("obra fuera de la base: \(x.texto)"); continue }
                if Set(obras.map(\.genero)).count > 1 { f.append("«\(x.texto)» con dos géneros") }
                if o.genero != x.categoria { f.append("«\(o.titulo)» es \(o.genero), no \(x.categoria)") }
                if o.titulo.lowercased().contains("greguer") { f.append("greguerías en género") }
            }
        case .eleccion(let e):
            let correcta = e.opciones.first { $0.id == e.correcta }!.texto
            guard let a = base.autores.first(where: { $0.id == m.datos["autor"] }), let o = a.obras.first(where: { $0.titulo == m.datos["obra"] }),
                  let anio = o.anio else { f.append("obra sin año"); break }
            if a.aproximado || a.nombre.hasPrefix("Anónimo") { f.append("autoría dudosa: \(a.nombre)") }
            if correcta.hasPrefix("Siglo") {
                let s = (anio - 1) / 100 + 1
                if correcta != "Siglo \(romano(s))" { f.append("\(anio): \(correcta)") }
                if anio % 100 <= 1 { f.append("año de cambio de siglo: \(anio)") }
            } else {
                guard let mov = base.movimientos.first(where: { $0.id == a.movimiento }) else { f.append("movimiento"); break }
                if correcta != mov.nombre { f.append("movimiento \(correcta) ≠ \(mov.nombre)") }
                if anio < mov.inicio || anio > (mov.fin ?? 9999) { f.append("año \(anio) fuera de \(mov.nombre) (D-079)") }
                for op in e.opciones where op.id != e.correcta {
                    guard let x = base.movimientos.first(where: { $0.nombre == op.texto }) else { f.append("distractor fuera de la base"); continue }
                    if anio >= x.inicio && anio <= (x.fin ?? 9999) { f.append("distractor «\(x.nombre)» contiene \(anio)") }
                }
            }
        default: f.append("payload")
        }
        return f
    }
}

// MARK: - Suites

@Suite("Fase 05E · Mapa curricular de la A1")
struct MapaCurricularTests {
    static let catalogo = banco05E.catalogo

    @Test("21 bloques y las 111 competencias del mapa, sin perder ningún id; equivalencias válidas")
    func mapa() throws {
        let bloques = Self.catalogo.todosLosBloques
        #expect(bloques.count == 21)
        #expect(Set(bloques.map(\.id)).isSuperset(of: ["LEN.HAB", "MAT.ALG", "LEN.MET", "LEN.FOR", "MAT.GEO"]))
        let ids = Set(Self.catalogo.todasLasCompetencias.map(\.id))
        let anteriores = ["LEN.SIN.SUJPRED", "LEN.SIN.COMPL", "LEN.ORT.AGU", "LEN.ORT.DIA", "LEN.ORT.HIA", "LEN.ORT.PQ", "LEN.ORT.HOM", "LEN.CLA.SUSTADJ",
                          "LEN.CLA.VERBO", "LEN.VER.ANALISIS", "LEN.LIT.CRONO", "LEN.LIT.AUTOBRA", "LEN.COM.SITU", "LEN.COM.TEMA", "LEN.COM.RESU",
                          "LEN.COM.INFER", "LEN.COM.TIPO", "LEN.COM.PROP", "LEN.COM.GEN", "LEN.REC.FIGURAS", "LEN.LEX.SINON", "LEN.LEX.SIN",
                          "LEN.LEX.POLI", "LEN.LEX.CAMPO", "LEN.LEX.CTX", "LEN.LEX.DICC", "LEN.LEX.REG", "LEN.LEX.DEN", "LEN.LEX.FRAS",
                          "MAT.UNI.LONG", "MAT.UNI.LMC", "MAT.UNI.SUP", "MAT.UNI.VOL", "MAT.UNI.TIEM", "MAT.UNI.ESC", "MAT.GEO.TRIANG",
                          "MAT.POR.PORCENT", "MAT.POR.CALC", "MAT.POR.TOTAL", "MAT.POR.VAR", "MAT.POR.PROP", "MAT.NUM.FRAREP", "MAT.NUM.FRAEQ",
                          "MAT.NUM.ORDEN", "MAT.NUM.FRAOP", "MAT.NUM.FRAPROB", "MAT.DIV.MCD", "MAT.OPE.JERARQ", "MAT.OPE.FRACSUM", "MAT.OPE.EQUIV",
                          "MAT.OPE.ECUAC", "MAT.OPE.JER", "MAT.OPE.COMB", "MAT.ROM.LECTURA", "MAT.ROM.LEER", "MAT.ROM.ESCR", "MAT.EST.CENTRAL",
                          "MAT.PRO.LAPLACE"]
        #expect(Set(anteriores).isSubset(of: ids), "\(Set(anteriores).subtracting(ids))")
        let delMapa = ["LEN.HAB.ORIG", "LEN.HAB.NODISC", "LEN.LIT.GEN", "LEN.LIT.OBRA", "LEN.LIT.HIST", "LEN.LIT.UNIV", "LEN.LIT.INF", "LEN.LIT.POP",
                       "LEN.REC.FIG", "LEN.REC.DEF", "LEN.MET.MED", "LEN.MET.RIMA", "LEN.MET.ESTR", "LEN.CLA.VAR", "LEN.CLA.INV", "LEN.CLA.ADJGRAD",
                       "LEN.CLA.JUST", "LEN.VER.NOPERS", "LEN.VER.IRREG", "LEN.VER.VOZ", "LEN.SIN.SINT", "LEN.SIN.MODAL", "LEN.SIN.CLASE", "LEN.SIN.COMP",
                       "LEN.ORT.LET", "LEN.ORT.PUNT", "LEN.ORT.MAY", "LEN.FOR.ESTR", "LEN.FOR.SIGL", "MAT.NUM.TIPOS", "MAT.NUM.VALPOS", "MAT.NUM.EQUIV",
                       "MAT.NUM.ENT", "MAT.OPE.POT", "MAT.OPE.RAIZ", "MAT.OPE.MENTAL", "MAT.DIV.REGLAS", "MAT.DIV.MULDIV", "MAT.DIV.PRIMOS", "MAT.DIV.MCM",
                       "MAT.POR.FIN", "MAT.UNI.ANG", "MAT.UNI.ESTIM", "MAT.GEO.CLAS", "MAT.GEO.SEMEJ", "MAT.ALG.PATR", "MAT.ALG.ALGO", "MAT.EST.FREC",
                       "MAT.EST.POBL", "MAT.PRO.SUCESOS", "MAT.PRO.RECUENTO"]
        #expect(Set(delMapa).isSubset(of: ids), "\(Set(delMapa).subtracting(ids))")
        #expect(ids.count == 126, "124 + MAT.OPE.INCOG (D-100) + LEN.ORT.CTX (05J)")
        let equivalentes = Self.catalogo.todasLasCompetencias.filter { $0.equivaleA != nil }
        #expect(equivalentes.count == 13)
        #expect(equivalentes.allSatisfy { ids.contains($0.equivaleA!) && $0.equivaleA != $0.id })
        #expect(ValidadorContenido(anioActual: 2026).validar(catalogo: Self.catalogo).isEmpty)
        // Prioridades del mapa.
        #expect(Self.catalogo.bloque(id: "LEN.HAB")?.prioridad == 2 && Self.catalogo.bloque(id: "MAT.ALG")?.prioridad == 1)
        #expect(Self.catalogo.bloque(id: "LEN.LEX")?.prioridad == 3 && Self.catalogo.bloque(id: "MAT.EST")?.prioridad == 3)
    }

    @Test("En el Camino, las competencias sin contenido salen «En preparación» y las antiguas sustituidas sin contenido no salen")
    func camino() throws {
        let release = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        let tramos = ConstructorCamino(banco: release).tramos(area: "LEN", estados: [:], enCurso: nil, medallas: [])
        let nodos = tramos.flatMap(\.nodos)
        #expect(nodos.contains { $0.id == "LEN.HAB.ORIG" && $0.estado == .sinContenido })
        #expect(nodos.contains { $0.id == "LEN.MET.MED" && $0.estado == .sinContenido })
        #expect(!nodos.contains { $0.id == "LEN.LIT.CRONO" || $0.id == "LEN.LEX.SINON" || $0.id == "LEN.REC.FIGURAS" })
        #expect(nodos.contains { $0.id == "LEN.SIN.SUJPRED" && $0.estado != .sinContenido })
        // Con progreso guardado, una antigua sigue apareciendo.
        let conProgreso = ConstructorCamino(banco: release).tramos(area: "LEN", estados: ["LEN.LIT.CRONO": EstadoCompetencia(competenciaId: "LEN.LIT.CRONO")],
                                                                    enCurso: nil, medallas: [])
        #expect(conProgreso.flatMap(\.nodos).contains { $0.id == "LEN.LIT.CRONO" })
    }

    @Test("LEN.HAB y MAT.ALG tienen peso 0 en Supervivencia mientras no tengan contenido")
    func pesos() throws {
        #expect(PesosSupervivencia.pesoExamen("LEN.HAB") == 0 && PesosSupervivencia.pesoExamen("MAT.ALG") == 0)
        let release = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        let bloques = SelectorSupervivencia(banco: release).bloques(area: nil)
        #expect(!bloques.contains("LEN.HAB") && !bloques.contains("MAT.ALG"))
        #expect(bloques.contains("LEN.SIN") && bloques.contains("LEN.VER") && bloques.contains("LEN.LIT"))
    }

    @Test("Homero y Esopo: época escrita, aproximados y sin fragmentos")
    func clasicos() {
        let l = Oraculo05E.literatura
        let homero = l.autores.first { $0.id == "homero" }!, esopo = l.autores.first { $0.id == "esopo" }!
        #expect(homero.epoca == "s. VIII a. C." && esopo.epoca == "s. VI a. C.")
        #expect(homero.aproximado && esopo.aproximado && !homero.fragmentosPermitidos && !esopo.fragmentosPermitidos)
        #expect(ValidadorContenido(anioActual: 2026).validar(literatura: l).isEmpty)
    }
}

@Suite("Fase 05E · Palabras ambiguas sin contexto")
struct AmbiguasTests {
    static let recursos = banco05E.recursos

    @Test("Detección determinista: ≥ 30 revisadas, todas detectadas y fuera de los generadores sin contexto")
    func ambiguas() throws {
        #expect(Self.recursos.ambiguas.palabras.count >= 30)
        #expect(Self.recursos.palabrasAmbiguas.count >= 30)
        for e in Self.recursos.ambiguas.palabras {
            #expect(Self.recursos.palabrasAmbiguas.contains(e.palabra), "\(e.palabra)")
            for v in e.variantes { #expect(Acentuacion.variantes(e.palabra).contains(v.forma), "\(v.forma) no es variante de \(e.palabra)") }
        }
        for w in ["terminó", "término", "pasó", "está", "papá", "médico", "público", "estudió", "jugó", "río", "sabía"] {
            #expect(Self.recursos.palabrasAmbiguas.contains(w), "\(w)")
        }
        #expect(!Self.recursos.palabrasAmbiguas.contains("canción") && !Self.recursos.palabrasAmbiguas.contains("árbol"))
        let usadas = Set(Self.recursos.palabras.map(\.analisis.palabra))
        #expect(usadas.isDisjoint(with: Self.recursos.palabrasAmbiguas))
        // `tildeContexto.json` (antes en `pendiente/`) lista exactamente las detectadas.
        let url = try #require(Bundle.main.url(forResource: "Content", withExtension: nil)?.appendingPathComponent("tildeContexto.json"))
        struct Pendiente: Decodable { struct P: Decodable { var palabra: String; var variantes: [PalabrasAmbiguas.Variante] }; var palabras: [P] }
        let pendiente = try JSONDecoder().decode(Pendiente.self, from: Data(contentsOf: url))
        #expect(Set(pendiente.palabras.map(\.palabra)) == Self.recursos.palabrasAmbiguas)
        #expect(pendiente.palabras.allSatisfy { !$0.variantes.isEmpty && $0.variantes.allSatisfy { !$0.categoria.isEmpty } })
        // Los ítems estáticos de colocarTilde tampoco usan palabras ambiguas.
        let ambiguasSinTilde = Set(Self.recursos.palabrasAmbiguas.map { String($0.map { Acentuacion.quitarTilde[$0] ?? $0 }) })
        for item in banco05E.itemsEstaticos {
            if case .colocarTilde(let c) = item.payload { #expect(!ambiguasSinTilde.contains(c.palabra), "\(item.id): «\(c.palabra)»") }
        }
    }

    @Test("Ninguna palabra ambigua sale en colocarTilde, clasificarAcentuacion ni silabaTonica (1000 semillas × 6 niveles)",
          arguments: banco05E.plantillas.filter { ["colocarTilde", "clasificarAcentuacion", "silabaTonica"].contains($0.tipo) })
    func fueraDeLosGeneradores(_ base: Plantilla) throws {
        for d in 1...6 {
            var p = base
            p.dificultad = d
            for semilla in UInt64(0)..<1000 {
                let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: Self.recursos)
                var palabras = [m.datos["palabra"]].compactMap { $0 }
                if case .clasificar(let c) = m.payload { palabras += c.fichas.map(\.texto) }
                for w in palabras { #expect(!Self.recursos.palabrasAmbiguas.contains(w.lowercased()), "\(p.id) d\(d): «\(w)»") }
            }
            let enumeradas = MotorGeneradores.generador(p.tipo)!.enumerar(p, recursos: Self.recursos, limite: 10_000)
            #expect(enumeradas.allSatisfy { !Self.recursos.palabrasAmbiguas.contains($0) })
        }
    }
}

@Suite("Fase 05E · Verbo: paradigmas de amar, temer y partir")
struct VerboTests {
    @Test("La tabla por reglas coincide con los paradigmas escritos a mano (todas las formas)", arguments: ["amar", "temer", "partir"])
    func reglasContraManuscrito(_ verbo: String) {
        let manuscrito = Oraculo05E.manuscrito(verbo), reglas = Oraculo05E.reglas(verbo)
        #expect(manuscrito.count == 18)
        for (k, v) in manuscrito { #expect(reglas[k] == v, "\(verbo) \(k): \(reglas[k] ?? []) ≠ \(v)") }
        #expect(Oraculo05E.imperativo(verbo) == Oraculo05E.paradigmas[verbo]!.imperativo)
        #expect(Oraculo05E.noPersonales(verbo) == Oraculo05E.paradigmas[verbo]!.noPersonales)
    }

    @Test("El conjugador de la app coincide con los paradigmas escritos a mano en todos sus tiempos", arguments: ["amar", "temer", "partir"])
    func conjugadorContraManuscrito(_ verbo: String) {
        for (k, v) in Oraculo05E.manuscrito(verbo) {
            let p = k.split(separator: "|").map(String.init)
            #expect(Conjugador.formas(verbo, tiempo: p[1], modo: p[0], irregulares: []) == v, "\(verbo) \(k)")
        }
        // Formas no personales del generador.
        let gerundio = GeneradorFormasNoPersonales.gerundio(verbo)
        #expect([verbo, gerundio, Conjugador.participio(verbo, irregular: nil)] == Array(Oraculo05E.paradigmas[verbo]!.noPersonales.prefix(3)))
    }

    @Test("Aspecto y forma: perfectos los compuestos y el pretérito perfecto simple")
    func aspecto() {
        #expect(Conjugador.aspecto("Pretérito perfecto simple", modo: "Indicativo") == "Perfecto")
        #expect(Conjugador.aspecto("Pretérito imperfecto", modo: "Subjuntivo") == "Imperfecto")
        #expect(Conjugador.aspecto("Pretérito pluscuamperfecto (-se)", modo: "Subjuntivo") == "Perfecto")
        #expect(Conjugador.esCompuesto("Pretérito anterior") && !Conjugador.esCompuesto("Futuro simple"))
    }

    @Test("analisisVerbal: solo regulares; cada ítem coincide con la tabla por reglas (1000 semillas × 6 niveles)", arguments: 1...6)
    func analisis(_ d: Int) throws {
        let base = try #require(banco05E.plantillas.first { $0.id == "LEN.VER.ANALISIS.G05" })
        var p = base
        p.dificultad = d
        var fallos: [String] = []
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: banco05E.recursos)
            let item = MotorGeneradores.item(p, semilla: semilla, muestra: m)
            fallos += Oraculo05E.comprobarAnalisis(m, item)
            if case .ruedas(let r) = item.payload { #expect(r.ruedas.count == 6) }
            if fallos.count > 5 { break }
        }
        #expect(fallos.isEmpty, "\(fallos)")
    }
}

@Suite("Fase 05E · Formas no personales y literatura (oráculos)")
struct NoPersonalesYLiteraturaTests {
    @Test("formasNoPersonales y literatura: 1000 semillas × 6 niveles con su oráculo",
          arguments: banco05E.plantillas.filter { ["formasNoPersonales", "literatura"].contains($0.tipo) })
    func oraculo(_ base: Plantilla) throws {
        var fallos: [String] = []
        for d in 1...6 {
            var p = base
            p.dificultad = d
            for semilla in UInt64(0)..<1000 {
                let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: banco05E.recursos)
                let item = MotorGeneradores.item(p, semilla: semilla, muestra: m)
                fallos += (p.tipo == "literatura" ? Oraculo05E.comprobarLiteratura(m, item) : Oraculo05E.comprobarNoPersonales(m, item)).map { "d\(d): \($0)" }
                if fallos.count > 5 { break }
            }
        }
        #expect(fallos.isEmpty, "\(base.id): \(fallos)")
    }
}
