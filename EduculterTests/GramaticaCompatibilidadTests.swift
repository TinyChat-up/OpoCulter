import Foundation
import Testing
@testable import Educulter

// Recuperación (25/11/2026), §4.2: gramática generativa con compatibilidad.json (D-086).
// Propiedades con 1000 semillas por mecánica y nivel, con un oráculo que solo usa los datos de
// compatibilidad.json y tablas escritas aquí (artículos, terminaciones verbales, restricciones
// de tiempo de los CCT), no el código del generador.

private let bancoGramatica = try! CargadorContenido.desdeBundle().cargar(politica: .todos)
private var compat: CompatibilidadGramatica { bancoGramatica.recursos.compatibilidad }

private enum OraculoGramatica {
    static let articulos: [String: String] = ["ms": "el", "fs": "la", "mp": "los", "fp": "las"]

    /// 3.ª persona (singular, plural) de un verbo regular en los tiempos que usa el generador.
    static func terceraPersona(_ inf: String, _ tiempo: String) -> (String, String)? {
        let raiz = String(inf.dropLast(2)), ar = inf.hasSuffix("ar")
        switch tiempo {
        case "Presente": return ar ? (raiz + "a", raiz + "an") : (raiz + "e", raiz + "en")
        case "Pretérito perfecto simple": return ar ? (raiz + "ó", raiz + "aron") : (raiz + "ió", raiz + "ieron")
        case "Pretérito imperfecto": return ar ? (raiz + "aba", raiz + "aban") : (raiz + "ía", raiz + "ían")
        case "Futuro simple": return (inf + "á", inf + "án")
        default: return nil
        }
    }

    /// Tiempos admitidos por cada CCT (piezas.json, D-066): el resto admite cualquiera.
    static let tiemposCCT: [String: Set<String>] = [
        "ayer": ["Pretérito perfecto simple"],
        "todos los días": ["Presente", "Pretérito imperfecto"],
    ]

    static func forma(_ a: CompatibilidadGramatica.Adjetivo, _ genero: String, _ numero: String) -> String {
        switch genero + numero {
        case "fs": a.fs
        case "mp": a.mp
        case "fp": a.fp
        default: a.ms
        }
    }
}

/// Comprueba todas las reglas de la 4.2 sobre una muestra; devuelve los fallos (vacío si cumple).
private func reglas(_ m: Muestra) -> [String] {
    let d = m.datos
    var fallos: [String] = []
    let oracion = d["oracion"]!
    let tokens = d["tokens"]!.split(separator: " ").map { $0.split(separator: "/").map(String.init) }
    let funciones = d["funciones"]!.split(separator: ";").map { f -> (String, Int, Int) in
        let p = f.split(separator: ":"), r = p[1].split(separator: "-")
        return (String(p[0]), Int(r[0])!, Int(r[1])!)
    }
    func texto(_ f: (String, Int, Int)) -> [[String]] { Array(tokens[f.1...f.2]) }
    guard let verbo = compat.verbos.first(where: { $0.infinitivo == d["verbo"] }) else { return ["verbo fuera de compatibilidad: \(d["verbo"] ?? "")"] }
    guard let sujeto = compat.sustantivos.first(where: { $0.lema == d["sujetoLema"] }) else { return ["sujeto fuera de compatibilidad"] }
    let numero = d["numero"]!

    // Sujeto compatible con el verbo y concordancia artículo-sustantivo.
    if Set(sujeto.etiquetas).isDisjoint(with: verbo.sujeto) { fallos.append("sujeto «\(sujeto.lema)» no admitido por «\(verbo.infinitivo)»") }
    let suj = funciones.first { $0.0 == "SUJ" }!
    let sujTokens = texto(suj)
    if sujTokens[0][0].lowercased() != OraculoGramatica.articulos[sujeto.genero + numero] { fallos.append("artículo del sujeto: \(sujTokens[0][0])") }
    if sujTokens[1][0] != (numero == "p" ? sujeto.plural : sujeto.lema) { fallos.append("número del sujeto: \(sujTokens[1][0])") }

    // Concordancia sujeto-verbo (terminaciones escritas aquí).
    let nv = funciones.first { $0.0 == "NV" }!
    if nv.1 != suj.2 + 1 { fallos.append("el verbo no sigue al sujeto") }
    if let (s, p) = OraculoGramatica.terceraPersona(verbo.infinitivo, d["tiempo"]!) {
        if tokens[nv.1][0] != (numero == "p" ? p : s) { fallos.append("concordancia sujeto-verbo: \(tokens[nv.1][0]) (\(numero), \(d["tiempo"]!))") }
    } else { fallos.append("tiempo inesperado \(d["tiempo"]!)") }

    // CD: etiqueta fina compatible con el verbo; nunca el sujeto.
    let cd = funciones.first { $0.0 == "CD" }
    if verbo.regimen == "transitivo" {
        if let cd, let o = compat.sustantivos.first(where: { $0.lema == d["cdLema"] }) {
            if Set(o.etiquetas).isDisjoint(with: verbo.objeto ?? []) { fallos.append("CD absurdo: «\(verbo.infinitivo)» + «\(o.lema)»") }
            if o.lema == sujeto.lema { fallos.append("CD = sujeto") }
            let t = texto(cd)
            if o.animado {
                if t.map(\.[0]) != ["a", "su", o.lema] { fallos.append("CD de persona: \(t.map(\.[0]))") }
            } else {
                let n = t[1][0] == o.plural ? "p" : "s"
                if t[1][0] != o.lema && t[1][0] != o.plural { fallos.append("forma del CD: \(t[1][0])") }
                if t[0][0] != OraculoGramatica.articulos[o.genero + n] { fallos.append("artículo del CD: \(t[0][0]) \(t[1][0])") }
            }
        } else { fallos.append("transitivo sin CD") }
    } else if cd != nil { fallos.append("intransitivo con CD") }

    // CI: persona, nunca el mismo referente que el sujeto.
    if funciones.contains(where: { $0.0 == "CI" }) {
        guard let ci = compat.sustantivos.first(where: { $0.lema == d["ciLema"] }) else { return fallos + ["CI sin lema"] }
        if !verbo.admiteCI { fallos.append("«\(verbo.infinitivo)» no admite CI") }
        if ci.lema == sujeto.lema { fallos.append("CI = sujeto («\(ci.lema)»)") }
        if !ci.etiquetas.contains("persona") { fallos.append("CI que no es persona") }
    }

    // Complementos circunstanciales: como mucho 2, de tipos distintos, de la lista de cada tipo.
    let ccs = funciones.filter { $0.0.hasPrefix("CC") }
    if ccs.count > 2 { fallos.append("\(ccs.count) CC") }
    if Set(ccs.map(\.0)).count != ccs.count { fallos.append("CC repetidos: \(ccs.map(\.0))") }
    var tiempos: Set<String>? = nil
    for cc in ccs {
        let t = texto(cc).map(\.[0]).joined(separator: " ").lowercased()
        if !(compat.complementosCircunstanciales[cc.0] ?? []).contains(t) { fallos.append("\(cc.0) «\(t)» no está en compatibilidad.json") }
        if cc.0 == "CCT", let r = OraculoGramatica.tiemposCCT[t] { tiempos = r }
    }
    if let tiempos, !tiempos.contains(d["tiempo"]!) { fallos.append("tiempo \(d["tiempo"]!) incompatible con el CCT") }

    // CCT antepuesto: primer constituyente y seguido de coma. Ningún otro constituyente va delante del sujeto.
    let primero = funciones.filter { $0.0 != "PRED" }.min { $0.1 < $1.1 }!
    if primero.0 != "SUJ" {
        if primero.0 != "CCT" { fallos.append("\(primero.0) delante del sujeto") }
        if d["coma"] != "\(primero.2)" { fallos.append("CCT antepuesto sin coma") }
        let palabras = texto(primero).map(\.[0]).joined(separator: " ")
        if !oracion.hasPrefix(palabras + ",") { fallos.append("la coma no sigue al CCT: \(oracion)") }
    } else if !(d["coma"] ?? "").isEmpty || oracion.contains(",") { fallos.append("coma sin CCT antepuesto") }
    if oracion.first?.isUppercase != true { fallos.append("sin mayúscula inicial") }
    if oracion.contains(" a el ") || oracion.contains(" de el ") { fallos.append("contracción sin hacer") }

    // Adjetivos: compatibles, concordados y solo con las cuatro formas de los datos.
    let adjetivos = (d["adjetivos"] ?? "").split(separator: ";").map { $0.split(separator: "|").map(String.init) }
    if adjetivos.count != tokens.filter({ $0[1] == "adj" }).count { fallos.append("adjetivos sin registrar") }
    for a in adjetivos {
        let (forma, lema, genero, n) = (a[0], a[1], a[2], a[3])
        guard let s = compat.sustantivos.first(where: { $0.lema == lema }) else { fallos.append("adjetivo de «\(lema)»"); continue }
        let posibles = compat.adjetivos.filter { OraculoGramatica.forma($0, genero, n) == forma }
        if posibles.isEmpty { fallos.append("forma inexistente o sin concordar: «\(forma)» (\(genero)\(n))") }
        if !posibles.contains(where: { !Set($0.etiquetas).isDisjoint(with: s.etiquetas) }) { fallos.append("«\(forma)» no califica a «\(lema)»") }
        for adj in posibles where adj.invariableEnGenero && forma != (n == "p" ? adj.mp : adj.ms) { fallos.append("invariable mal formada: \(forma)") }
        if !tokens.contains(where: { $0[0] == forma && $0[1] == "adj" }) { fallos.append("adjetivo «\(forma)» no está en la oración") }
    }
    return fallos
}

@Suite("Gramática generativa con compatibilidad.json (1000 semillas)")
struct GramaticaCompatibilidadTests {
    static let plantillas = bancoGramatica.plantillas.filter { $0.tipo == "oracionSimple" }

    @Test("La compatibilidad se carga y pasa el validador")
    func carga() {
        #expect(!compat.vacia && compat.sustantivos.count == 39 && compat.adjetivos.count == 17 && compat.verbos.count == 27)
        #expect(ValidadorContenido(anioActual: 2026).validar(compatibilidad: compat).isEmpty)
        #expect(compat.adjetivos.filter(\.invariableEnGenero).map(\.ms).sorted() == ["amable", "azul", "caliente", "difícil", "fácil", "grande"])
    }

    @Test("CD compatible, CI ≠ sujeto, ≤ 2 CC de tipos distintos, CCT antepuesto con coma, adjetivos y concordancias",
          arguments: plantillas, 1...6)
    func reglasDeLaOracion(_ base: Plantilla, _ dificultad: Int) throws {
        var p = base
        p.dificultad = dificultad
        var fallos: [String] = []
        var vistas = Set<String>()
        var antepuestos = 0, conCI = 0, conAdjetivo = 0
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGramatica.recursos)
            let f = reglas(m)
            if !f.isEmpty { fallos.append("\(m.datos["oracion"]!): \(f.joined(separator: "; "))") }
            if !(m.datos["coma"] ?? "").isEmpty { antepuestos += 1 }
            if !(m.datos["ciLema"] ?? "").isEmpty { conCI += 1 }
            if !(m.datos["adjetivos"] ?? "").isEmpty { conAdjetivo += 1 }
            if vistas.insert(m.datos["oracion"]!).inserted && vistas.count <= 12 && dificultad >= 4 {
                print("ORACION \(p.id) d\(dificultad): \(m.datos["oracion"]!)")
            }
            if fallos.count >= 5 { break }
        }
        #expect(fallos.isEmpty, "\(fallos)")
        // Las reglas se ejercitan de verdad.
        if dificultad >= 5 { #expect(conCI > 0 && conAdjetivo > 0, "d\(dificultad): CI \(conCI), adjetivos \(conAdjetivo)") }
        if dificultad >= 3 && p.mecanica != .segmentar { #expect(antepuestos > 0, "d\(dificultad): ningún CCT antepuesto") }
        if p.mecanica == .segmentar { #expect(antepuestos == 0, "En segmentar el CCT no se antepone") }
    }

    @Test("Con compatibilidad, analisisVerbal usa sus verbos y participios irregulares (escrito, abierto)", arguments: 1...6)
    func verbos(_ dificultad: Int) throws {
        let base = try #require(bancoGramatica.plantillas.first { $0.tipo == "analisisVerbal" })
        var p = base
        p.dificultad = dificultad
        let banco = GeneradorAnalisisVerbal.banco(bancoGramatica.recursos)
        #expect(Set(compat.verbos.map(\.infinitivo)).isSubset(of: Set(banco.regulares)))
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoGramatica.recursos)
            let forma = m.datos["forma"]!, verbo = m.datos["verbo"]!
            #expect(!forma.hasSuffix("escribido") && !forma.hasSuffix("abrido") && !forma.hasSuffix("ponido") && !forma.hasSuffix("decido") && !forma.hasSuffix("hacido"), "\(forma)")
            if forma.contains(" ") {
                let participio = String(forma.split(separator: " ").last!)
                let esperado = ["escribir": "escrito", "abrir": "abierto", "poner": "puesto", "decir": "dicho", "hacer": "hecho"][verbo]
                    ?? String(verbo.dropLast(2)) + (verbo.hasSuffix("ar") ? "ado" : "ido")
                if verbo != "tener" { #expect(participio == esperado, "\(verbo): \(forma)") }
            }
            if let v = compat.verbos.first(where: { $0.infinitivo == verbo }) {
                #expect(["ar": 1, "er": 2, "ir": 3][String(verbo.suffix(2))] == v.conjugacion)
            }
        }
    }
}
