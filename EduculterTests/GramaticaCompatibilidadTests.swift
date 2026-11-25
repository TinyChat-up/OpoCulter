import Foundation
import Testing
@testable import Educulter

// Gramática generativa con compatibilidad.json (D-086) y reglas de naturalidad de la Fase 05E
// (D-090). Propiedades con 1000 semillas por plantilla y nivel, con un oráculo independiente: el
// análisis se deduce de la estructura elegida (lemas, número, determinantes, CC y orden) y de los
// datos de compatibilidad.json, con tablas escritas aquí (artículos, terminaciones, ser y estar),
// nunca leyendo el texto generado ni usando el código del generador.

private let bancoGramatica = try! CargadorContenido.desdeBundle().cargar(politica: .todos)
private var compat: CompatibilidadGramatica { bancoGramatica.recursos.compatibilidad }

enum OraculoOracion {
    static let articulos: [String: String] = ["ms": "el", "fs": "la", "mp": "los", "fp": "las"]
    static let nombres: [String: String] = [
        "SUJ": "Sujeto", "CD": "Complemento directo", "CI": "Complemento indirecto", "CCL": "CC de lugar", "CCT": "CC de tiempo",
        "CCM": "CC de modo", "CCC": "CC de compañía", "ATR": "Atributo",
    ]
    /// 3.ª persona de ser y estar (escrita a mano).
    static let copulativos: [String: [String: (String, String)]] = [
        "ser": ["Presente": ("es", "son"), "Pretérito imperfecto": ("era", "eran"), "Pretérito perfecto simple": ("fue", "fueron"), "Futuro simple": ("será", "serán")],
        "estar": ["Presente": ("está", "están"), "Pretérito imperfecto": ("estaba", "estaban"), "Pretérito perfecto simple": ("estuvo", "estuvieron"), "Futuro simple": ("estará", "estarán")],
    ]

    /// 3.ª persona (singular, plural) en los tiempos que usa el generador.
    static func terceraPersona(_ inf: String, _ tiempo: String) -> (String, String)? {
        if let c = copulativos[inf] { return c[tiempo] }
        let raiz = String(inf.dropLast(2)), ar = inf.hasSuffix("ar")
        switch tiempo {
        case "Presente": return ar ? (raiz + "a", raiz + "an") : (raiz + "e", raiz + "en")
        case "Pretérito perfecto simple": return ar ? (raiz + "ó", raiz + "aron") : (raiz + "ió", raiz + "ieron")
        case "Pretérito imperfecto": return ar ? (raiz + "aba", raiz + "aban") : (raiz + "ía", raiz + "ían")
        case "Futuro simple": return (inf + "á", inf + "án")
        default: return nil
        }
    }

    static func forma(_ a: CompatibilidadGramatica.Adjetivo, _ genero: String, _ numero: String) -> String {
        switch genero + numero {
        case "fs": a.fs
        case "mp": a.mp
        case "fp": a.fp
        default: a.ms
        }
    }

    /// Oración y análisis esperados a partir de la estructura.
    struct Esperado {
        var texto: String
        /// (función, texto) en el orden de la oración (NV incluido, sin PRED).
        var constituyentes: [(String, String)]
        var sujeto: String
        var clase: String
        var verbo: String
        var otraForma: String
    }

    static func esperado(_ d: [String: String]) -> Esperado? {
        guard let s = compat.sustantivos.first(where: { $0.lema == d["sujetoLema"] }), let n = d["numero"], let tiempo = d["tiempo"],
              let inf = d["verbo"], let (v3s, v3p) = terceraPersona(inf, tiempo) else { return nil }
        let adjetivos = (d["adjetivos"] ?? "").split(separator: ";").map { $0.split(separator: "|").map(String.init) }
        func adj(_ lema: String) -> String { adjetivos.first { $0[1] == lema }.map { " " + $0[0] } ?? "" }
        func nominal(_ x: CompatibilidadGramatica.Sustantivo, _ num: String) -> String {
            "\(articulos[x.genero + num]!) \(num == "p" ? x.plural : x.lema)\(adj(x.lema))"
        }
        func animado(_ x: CompatibilidadGramatica.Sustantivo, _ num: String, _ det: String) -> String {
            let nombre = num == "p" ? x.plural : x.lema
            if det == "pos" { return "a \(num == "p" ? "sus" : "su") \(nombre)" }
            let art = articulos[x.genero + num]!
            return art == "el" ? "al \(nombre)" : "a \(art) \(nombre)"
        }
        let sujeto = nominal(s, n)
        let verbo = n == "p" ? v3p : v3s
        var tras: [(String, String)] = []
        var clase = "Predicativa intransitiva"
        if let lema = d["cdLema"], !lema.isEmpty, let o = compat.sustantivos.first(where: { $0.lema == lema }) {
            let num = d["cdNumero"] ?? "s"
            tras.append(("CD", (d["cdDet"] ?? "").isEmpty ? nominal(o, num) : animado(o, num, d["cdDet"]!)))
            clase = "Predicativa transitiva"
        }
        if let lema = d["atributoLema"], !lema.isEmpty, let a = compat.adjetivos.first(where: { $0.ms == lema }) {
            tras.append(("ATR", forma(a, s.genero, n)))
            clase = "Copulativa (atributiva)"
        }
        if let lema = d["ciLema"], !lema.isEmpty, let c = compat.sustantivos.first(where: { $0.lema == lema }) {
            tras.append(("CI", animado(c, d["ciNumero"] ?? "s", d["ciDet"] ?? "art")))
        }
        var ccs = (d["textosCC"] ?? "").split(separator: ";").map { $0.split(separator: "=").map(String.init) }.map { ($0[0], $0[1]) }
        let orden = d["orden"] ?? "canonico"
        var partes: [(String, String)] = []
        var delante: (String, String)?
        if orden != "canonico", !ccs.isEmpty { delante = ccs.removeFirst() }
        if let delante { partes.append(delante) }
        if orden == "sujetoPospuesto" { partes += [("NV", verbo), ("SUJ", sujeto)] } else { partes += [("SUJ", sujeto), ("NV", verbo)] }
        partes += tras + ccs
        var texto = partes.enumerated().map { $0.offset == 0 && delante != nil ? $0.element.1 + "," : $0.element.1 }.joined(separator: " ")
        texto = texto.prefix(1).uppercased() + texto.dropFirst()
        return Esperado(texto: texto, constituyentes: partes, sujeto: sujeto, clase: clase, verbo: verbo, otraForma: n == "p" ? v3s : v3p)
    }

    static func iguales(_ a: String, _ b: String) -> Bool { a.lowercased() == b.lowercased() }

    /// Comprueba análisis, mecánica y reglas de naturalidad (D-090). Devuelve los fallos.
    static func comprobar(_ m: Muestra, _ item: Item, _ p: Plantilla) -> [String] {
        let d = m.datos
        guard let e = esperado(d) else { return ["sin estructura: \(d)"] }
        var fallos: [String] = []
        if e.texto != d["oracion"] { fallos.append("texto «\(d["oracion"]!)» ≠ estructura «\(e.texto)»") }
        // Constituyentes generados (por posición) frente a los deducidos de la estructura.
        let tokens = d["tokens"]!.split(separator: " ").map { $0.split(separator: "/").map(String.init) }
        let generados = d["funciones"]!.split(separator: ";").map { f -> (String, String) in
            let x = f.split(separator: ":"), r = x[1].split(separator: "-")
            return (String(x[0]), tokens[Int(r[0])!...Int(r[1])!].map(\.[0]).joined(separator: " "))
        }.filter { $0.0 != "PRED" }
        let a = Set(generados.map { "\($0.0)=\($0.1.lowercased())" }), b = Set(e.constituyentes.map { "\($0.0)=\($0.1.lowercased())" })
        if a != b { fallos.append("análisis \(a.sorted()) ≠ \(b.sorted())") }
        let funcionDe = Dictionary(e.constituyentes.map { ($0.1.lowercased(), $0.0) }, uniquingKeysWith: { x, _ in x })

        switch item.payload {
        case .marcarTexto(let mt):
            let marcado = mt.tokens.filter { mt.correctos.contains($0.id) }.map { $0.texto.replacingOccurrences(of: ",", with: "") }.joined(separator: " ")
            if !iguales(marcado, e.sujeto) { fallos.append("sujeto marcado «\(marcado)» ≠ «\(e.sujeto)»") }
        case .segmentar(let sg):
            let pos = Dictionary(uniqueKeysWithValues: sg.tokens.enumerated().map { ($1.id, $0) })
            func t(_ s: Payload.Segmentar.Segmento) -> String { sg.tokens[pos[s.desde]!...pos[s.hasta]!].map(\.texto).joined(separator: " ") }
            let suj = sg.segmentos.first { $0.etiqueta == "SUJ" }.map(t) ?? ""
            if !iguales(suj, e.sujeto) { fallos.append("segmento sujeto «\(suj)»") }
            let resto = e.constituyentes.filter { $0.0 != "SUJ" }.map(\.1).joined(separator: " ")
            if !iguales(sg.segmentos.first { $0.etiqueta == "PRED" }.map(t) ?? "", resto) { fallos.append("predicado") }
            let nombrePred = sg.etiquetas.first { $0.id == "PRED" }?.nombre
            if nombrePred != (e.clase.hasPrefix("Copulativa") ? "Predicado nominal" : "Predicado verbal") { fallos.append("nombre del predicado: \(nombrePred ?? "")") }
            for s in sg.segmentos where s.padre != nil {
                if funcionDe[t(s).lowercased()] != s.etiqueta { fallos.append("segmento \(s.etiqueta) «\(t(s))»") }
            }
            if Oraculo05E.modo(p) == "completo" && sg.segmentos.count != e.constituyentes.count + 1 { fallos.append("faltan segmentos") }
        case .clasificar(let c) where Oraculo05E.modo(p) == "funciones":
            for f in c.fichas where funcionDe[f.texto.lowercased()] != f.categoria { fallos.append("ficha «\(f.texto)» → \(f.categoria)") }
        case .clasificar(let c):
            for f in c.fichas where claseDePalabra(f.texto, d) != f.categoria { fallos.append("clase de «\(f.texto)»: \(f.categoria) ≠ \(claseDePalabra(f.texto, d))") }
        case .eleccion(let el):
            let correcta = el.opciones.first { $0.id == el.correcta }?.texto ?? ""
            switch Oraculo05E.modo(p) {
            case "clase": if correcta != e.clase { fallos.append("clase \(correcta) ≠ \(e.clase)") }
            case "concordancia":
                if !iguales(correcta, e.sujeto) { fallos.append("concordancia: \(correcta)") }
                if d["otraForma"] != e.otraForma { fallos.append("otra forma \(d["otraForma"] ?? "") ≠ \(e.otraForma)") }
                if e.clase.hasPrefix("Copulativa") { fallos.append("concordancia con copulativa (el atributo también cambiaría)") }
            case "pronombre":
                let f = d["objetivo"] ?? ""
                let lema = f == "CD" ? d["cdLema"] : d["ciLema"]
                let num = (f == "CD" ? d["cdNumero"] : d["ciNumero"]) ?? "s"
                guard let s = compat.sustantivos.first(where: { $0.lema == lema }) else { fallos.append("pronombre sin lema"); break }
                let esperado = f == "CI" ? (num == "p" ? "les" : "le") : (s.genero == "f" ? "la" : "lo") + (num == "p" ? "s" : "")
                if correcta != esperado { fallos.append("pronombre \(correcta) ≠ \(esperado)") }
                if f == "CD" && s.animado { fallos.append("CD de persona o animal en la pregunta de pronombre (leísmo admitido)") }
            default:
                let sintagma = item.enunciado.components(separatedBy: "«").dropFirst().first?.components(separatedBy: "»").first ?? ""
                if correcta != nombres[funcionDe[sintagma.lowercased()] ?? ""] { fallos.append("función de «\(sintagma)»: \(correcta)") }
            }
        default: fallos.append("mecánica inesperada")
        }
        return fallos + reglas(d, e)
    }

    /// Clase de palabra deducida de los datos (no del generador).
    static func claseDePalabra(_ palabra: String, _ d: [String: String]) -> String {
        let w = palabra.lowercased().replacingOccurrences(of: ",", with: "")
        if ["el", "la", "los", "las", "su", "sus", "todos", "un", "una"].contains(w) { return "det" }
        if ["a", "en", "por", "con", "para", "de"].contains(w) { return "prep" }
        if ["ayer", "deprisa", "despacio", "tranquilamente"].contains(w) { return "adv" }
        if w == d["verbo"].flatMap({ v in terceraPersona(v, d["tiempo"]!).map { d["numero"] == "p" ? $0.1 : $0.0 } }) { return "verbo" }
        if compat.adjetivos.contains(where: { $0.formas.contains(w) }) { return "adj" }
        return "sust"
    }

    /// Reglas de naturalidad (D-090) sobre la estructura.
    static func reglas(_ d: [String: String], _ e: Esperado) -> [String] {
        var f: [String] = []
        guard let v = compat.verbos.first(where: { $0.infinitivo == d["verbo"] }),
              let s = compat.sustantivos.first(where: { $0.lema == d["sujetoLema"] }) else { return ["verbo o sujeto fuera de compatibilidad"] }
        let tiempo = d["tiempo"]!
        // Incontables: nunca en plural.
        if s.incontable && d["numero"] == "p" { f.append("incontable en plural: \(s.lema)") }
        if let o = compat.sustantivos.first(where: { $0.lema == d["cdLema"] }), o.incontable, d["cdNumero"] == "p" { f.append("CD incontable en plural") }
        for lema in ["leche", "café", "sopa", "zumo"] where !(compat.sustantivos.first { $0.lema == lema }?.incontable ?? false) { f.append("\(lema) sin «incontable»") }
        // Sujeto y CD compatibles con el verbo; CD ≠ sujeto.
        if v.regimen != "copulativo" && Set(s.etiquetas).isDisjoint(with: v.sujeto) { f.append("sujeto no admitido") }
        if let o = compat.sustantivos.first(where: { $0.lema == d["cdLema"] }) {
            if Set(o.etiquetas).isDisjoint(with: v.objeto ?? []) { f.append("CD absurdo: \(v.infinitivo) + \(o.lema)") }
            if o.lema == s.lema { f.append("CD = sujeto") }
            if o.animado == (d["cdDet"] ?? "").isEmpty { f.append("determinante del CD") }
            if !o.animado && d["cdDet"] == "pos" { f.append("CD de cosa con posesivo") }
            if ["niño", "niña", "cocinero"].contains(o.lema) && d["cdDet"] == "pos" { f.append("\(o.lema) con posesivo") }
        }
        // CI: persona, ≠ sujeto, ≠ CD, artículo o posesivo (niño, niña y cocinero solo artículo).
        if let lema = d["ciLema"], !lema.isEmpty, let c = compat.sustantivos.first(where: { $0.lema == lema }) {
            if !v.admiteCI { f.append("\(v.infinitivo) no admite CI") }
            if !c.etiquetas.contains("persona") { f.append("CI que no es persona") }
            if c.lema == s.lema || c.lema == d["cdLema"] { f.append("CI = sujeto o CD") }
            if !["art", "pos"].contains(d["ciDet"] ?? "") { f.append("CI sin determinante") }
            if ["niño", "niña", "cocinero"].contains(c.lema) && d["ciDet"] == "pos" { f.append("\(c.lema) con posesivo") }
        }
        if v.infinitivo == "preparar" && v.admiteCI { f.append("preparar admite CI") }
        // CC: tipos distintos, sin repetir preposición inicial, compatibles con el verbo y el sujeto.
        let ccs = (d["textosCC"] ?? "").split(separator: ";").map { $0.split(separator: "=").map(String.init) }
        if Set(ccs.map(\.[0])).count != ccs.count { f.append("CC repetidos") }
        let preps = ccs.compactMap { c -> String? in
            let p = String(c[1].split(separator: " ").first ?? "")
            return ["a", "en", "por", "con", "para", "de"].contains(p) ? p : nil
        }
        if Set(preps).count != preps.count { f.append("dos CC con la misma preposición: \(ccs.map(\.[1]))") }
        let aspecto: [String: String] = ["ayer": "puntual", "el lunes": "puntual", "a las cinco": "puntual", "todos los días": "habitual",
                                         "por la mañana": "neutro", "en verano": "neutro"]
        for c in ccs {
            if c[1] == "junto al río" { f.append("«junto al río» excluido") }
            if (compat.ccExcluye[c[1]] ?? []).contains(v.infinitivo) { f.append("«\(v.infinitivo) \(c[1])»") }
            if c[1].hasPrefix("con su") && !s.etiquetas.contains("persona") { f.append("CCC con sujeto que no es persona") }
            guard c[0] == "CCT" else { continue }
            if c[1] == "ayer" && tiempo != "Pretérito perfecto simple" { f.append("«ayer» con \(tiempo)") }
            switch aspecto[c[1]] {
            case "puntual": if tiempo == "Pretérito imperfecto" { f.append("CCT puntual con imperfecto") }
            case "habitual":
                if !["Presente", "Pretérito imperfecto"].contains(tiempo) { f.append("habitual con \(tiempo)") }
                if ["comprar", "regalar", "prestar"].contains(v.infinitivo) { f.append("habitual con \(v.infinitivo)") }
            default: break
            }
        }
        // Copulativas: ser (cualidad), estar (estado), parecer (ambas); predicado nominal.
        if v.regimen == "copulativo" {
            guard let a = compat.adjetivos.first(where: { $0.ms == d["atributoLema"] }) else { return f + ["copulativa sin atributo"] }
            let admitidos: [String: Set<String>] = ["ser": ["cualidad"], "estar": ["estado"], "parecer": ["cualidad", "estado"]]
            if !(admitidos[v.infinitivo] ?? []).contains(a.tipo ?? "") { f.append("\(v.infinitivo) + \(a.ms) (\(a.tipo ?? ""))") }
            if Set(a.etiquetas).isDisjoint(with: s.etiquetas) { f.append("«\(a.ms)» no califica a «\(s.lema)»") }
            if v.infinitivo != "estar" && !["Presente", "Pretérito imperfecto"].contains(tiempo) { f.append("\(v.infinitivo) en \(tiempo)") }
            if !ccs.isEmpty || !(d["cdLema"] ?? "").isEmpty { f.append("copulativa con CD o CC") }
        }
        // Orden: el CC antepuesto es de tiempo o de lugar y va seguido de coma.
        if d["orden"] != "canonico", let primero = ccs.first, !["CCT", "CCL"].contains(primero[0]) { f.append("\(primero[0]) antepuesto") }
        if (d["orden"] == "canonico") == (d["oracion"]!.contains(",")) { f.append("coma y orden no coinciden") }
        // Estructura del nivel.
        let nivel = Int(d["nivel"]!)!
        let tieneCD = !(d["cdLema"] ?? "").isEmpty, tieneCI = !(d["ciLema"] ?? "").isEmpty
        let ok: Bool = switch nivel {
        case 1: v.regimen == "intransitivo" && ccs.isEmpty
        case 2: v.regimen == "transitivo" && tieneCD && !tieneCI && ccs.isEmpty
        case 3: v.regimen == "intransitivo" && ccs.count == 1
        case 4: v.regimen == "copulativo"
        case 5: (v.regimen == "transitivo" && tieneCD && tieneCI && ccs.isEmpty) || (v.regimen == "intransitivo" && ccs.count == 2)
        default: d["orden"] != "canonico" || (tieneCD && tieneCI && ccs.count == 1)
        }
        if !ok { f.append("estructura del nivel \(nivel): \(d["oracion"]!)") }
        if d["orden"] == "sujetoPospuesto" && v.regimen != "intransitivo" { f.append("sujeto pospuesto con verbo no intransitivo") }
        return f
    }
}

@Suite("Gramática generativa con compatibilidad.json y naturalidad (D-090, 1000 semillas)")
struct GramaticaCompatibilidadTests {
    static let plantillas = bancoGramatica.plantillas.filter { $0.tipo == "oracionSimple" }

    @Test("La compatibilidad se carga y pasa el validador; datos de D-090")
    func carga() {
        #expect(!compat.vacia && compat.sustantivos.count == 39 && compat.adjetivos.count == 27 && compat.verbos.count == 30)
        #expect(ValidadorContenido(anioActual: 2026).validar(compatibilidad: compat).isEmpty)
        #expect(Set(compat.sustantivos.filter(\.incontable).map(\.lema)) == ["leche", "café", "sopa", "zumo"])
        #expect(compat.verbos.first { $0.infinitivo == "preparar" }?.admiteCI == false)
        #expect(Set(compat.verbos.filter { $0.regimen == "copulativo" }.map(\.infinitivo)) == ["ser", "estar", "parecer"])
        let estado = Set(compat.adjetivos.filter { $0.tipo == "estado" }.map(\.ms))
        #expect(estado == ["caliente", "cansado", "contento", "nervioso", "tranquilo", "enfadado", "limpio", "sucio", "abierto", "cerrado", "frío"])
        #expect(compat.adjetivos.filter { $0.tipo == "cualidad" }.count == 16)
        #expect(compat.aspectoCCT["ayer"] == "puntual" && compat.aspectoCCT["todos los días"] == "habitual" && compat.aspectoCCT["en verano"] == "neutro")
    }

    @Test("Análisis deducido de la estructura, mecánica y reglas de naturalidad", arguments: plantillas, 1...6)
    func reglasDeLaOracion(_ base: Plantilla, _ dificultad: Int) throws {
        var p = base
        p.dificultad = dificultad
        var fallos: [String] = []
        var antepuestos = 0, pospuestos = 0, conCI = 0, copulativas = 0
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGramatica.recursos)
            let item = MotorGeneradores.item(p, semilla: semilla, muestra: m)
            let f = OraculoOracion.comprobar(m, item, p)
            if !f.isEmpty { fallos.append("\(m.datos["oracion"]!): \(f.joined(separator: "; "))") }
            if m.datos["orden"] != "canonico" { antepuestos += 1 }
            if m.datos["orden"] == "sujetoPospuesto" { pospuestos += 1 }
            if !(m.datos["ciLema"] ?? "").isEmpty { conCI += 1 }
            if m.datos["regimen"] == "copulativo" { copulativas += 1 }
            if fallos.count >= 5 { break }
        }
        #expect(fallos.isEmpty, "\(fallos)")
        // Las reglas se ejercitan de verdad en los niveles que las piden.
        let modo = Oraculo05E.modo(p)
        if ["sujeto", "completo", "sujetoPredicado", "funciones", "clases"].contains(modo) {
            if dificultad == 4 { #expect(copulativas == 1000) }
            if dificultad == 5 { #expect(conCI > 0) }
            if dificultad == 6 && p.mecanica != .segmentar { #expect(antepuestos == 1000 && pospuestos > 0) }
        }
        if p.mecanica == .segmentar { #expect(antepuestos == 0, "En segmentar no hay orden alterado") }
    }

    @Test("50 oraciones distintas por nivel, para revisar (se imprimen 3)", arguments: 1...6)
    func cincuentaPorNivel(_ nivel: Int) throws {
        let p = Plantilla(id: "LEN.SIN.SUJPRED.GX", competencia: "LEN.SIN.SUJPRED", peldano: 3, dificultad: nivel, mecanica: .marcarTexto,
                          tipo: "oracionSimple", parametros: ["modo": .texto("sujeto")], enunciados: ["{{oracion}}"])
        var vistas: [String] = []
        for semilla in UInt64(0)..<2000 where vistas.count < 50 {
            let o = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGramatica.recursos).datos["oracion"]!
            if !vistas.contains(o) { vistas.append(o) }
        }
        #expect(vistas.count == 50)
        for o in vistas.prefix(3) { print("ORACION nivel \(nivel): \(o).") }
    }

    @Test("Con compatibilidad, analisisVerbal usa sus verbos no copulativos y participios irregulares (escrito, abierto)", arguments: 1...6)
    func verbos(_ dificultad: Int) throws {
        let base = try #require(bancoGramatica.plantillas.first { $0.tipo == "analisisVerbal" })
        var p = base
        p.dificultad = dificultad
        let banco = GeneradorAnalisisVerbal.banco(bancoGramatica.recursos)
        #expect(Set(compat.verbos.filter { $0.regimen != "copulativo" }.map(\.infinitivo)).isSubset(of: Set(banco.regulares)))
        #expect(banco.regulares.allSatisfy { !["ser", "estar", "parecer", "tener", "hacer", "poner", "decir"].contains($0) })
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGramatica.recursos)
            let forma = m.datos["forma"]!, verbo = m.datos["verbo"]!
            #expect(!forma.hasSuffix("escribido") && !forma.hasSuffix("abrido"), "\(forma)")
            if forma.contains(" ") {
                let participio = String(forma.split(separator: " ").last!)
                let esperado = ["escribir": "escrito", "abrir": "abierto"][verbo] ?? String(verbo.dropLast(2)) + (verbo.hasSuffix("ar") ? "ado" : "ido")
                #expect(participio == esperado, "\(verbo): \(forma)")
            }
            if let v = compat.verbos.first(where: { $0.infinitivo == verbo }) {
                #expect(["ar": 1, "er": 2, "ir": 3][String(verbo.suffix(2))] == v.conjugacion)
            }
        }
    }
}
