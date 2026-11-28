import Foundation
import Testing
@testable import Educulter

// Fase 05K: volúmenes, sucesos, palabras variables y diccionario (las 4 competencias del plano sin
// contenido), y las decisiones del anexo sobre la 05J.

private let banco: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5))!
private let release: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .soloAprobados, semillaBase: 5))!

// MARK: - Oráculos independientes (no usan el código de los generadores)

enum Oraculo05K {
    static func comprobar(_ tipo: String, _ m: Muestra, _ item: Item) -> [String] {
        switch tipo {
        case "volumen": volumen(item)
        case "sucesos": sucesos(m, item)
        case "palabrasVariables": variables(m, item)
        case "lema": lema(m, item)
        case "ordenAlfabetico": orden(item)
        default: ["sin oráculo"]
        }
    }

    static func numero(_ t: String) -> Double? { Double(t.replacingOccurrences(of: ",", with: ".")) }

    // MARK: Volumen: fórmula del sólido a partir de sus medidas rotuladas

    static let aCm: [String: Double] = ["mm": 0.1, "cm": 1, "dm": 10, "m": 100]
    static let deCm3: [String: Double] = ["cm³": 1, "ml": 1, "dm³": 1000, "l": 1000, "m³": 1_000_000]

    static func cm(_ texto: String) -> Double? {
        let p = texto.split(separator: " ")
        guard p.count == 2, let v = numero(String(p[0])), let f = aCm[String(p[1])] else { return nil }
        return v * f
    }

    static func volumen(_ item: Item) -> [String] {
        guard case .figuraVolumen(let f) = item.payload, let res = numero(f.resultado) else { return ["payload"] }
        var fallos: [String] = []
        func medida(_ s: String, _ a: Payload.FiguraVolumen.Arista) -> Double? {
            f.rotulos.first { $0.solido == s && $0.arista == a }.flatMap { cm($0.texto) }
        }
        let esperado: Double
        if let r = item.enunciado.range(of: "se sacan ") {
            // Nueva altura del agua (cm): la de antes menos litros (dm³) entre el área de la base.
            let litros = numero(String(item.enunciado[r.upperBound...].prefix { $0 != " " })) ?? .nan
            guard let l = medida("A", .largo), let a = medida("A", .ancho), let h = medida("A", .agua) else { return ["medidas"] }
            esperado = h - litros * 1000 / (l * a)
        } else {
            var total = 0.0
            for s in f.solidos {
                switch s.forma {
                case .ortoedro:
                    guard let l = medida(s.id, .largo), let a = medida(s.id, .ancho), let h = medida(s.id, .agua) ?? medida(s.id, .alto) else {
                        fallos.append("medidas de \(s.id)"); continue
                    }
                    total += l * a * h
                case .cilindro:
                    guard let r = medida(s.id, .radio) ?? medida(s.id, .diametro).map({ $0 / 2 }), let h = medida(s.id, .alto) else {
                        fallos.append("medidas del cilindro"); continue
                    }
                    total += 3.14 * r * r * h
                }
            }
            guard let factor = deCm3[f.unidad] else { return ["unidad \(f.unidad)"] }
            esperado = total / factor
        }
        if abs(esperado - res) > 1e-6 * max(1, abs(esperado)) { fallos.append("resultado \(res) ≠ \(esperado)") }
        // La respuesta correcta y una con un error típico.
        if !Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item).correcto { fallos.append("la correcta no es correcta") }
        if Evaluador.evaluar(RespuestaEjemplo.conUnError(item.payload), para: item).correcto { fallos.append("la errónea es correcta") }
        for (codigo, v) in f.erroneos {
            if numero(v) == res { fallos.append("\(codigo) da el resultado") }
            if !item.erroresHabituales.contains(where: { $0.respuesta == codigo }) { fallos.append("\(codigo) sin feedback") }
        }
        if f.cubos && item.peldano > 2 { fallos.append("cubos fuera de los peldaños 1–2") }
        if f.descripcion.contains("×") || f.descripcion.contains("=") { fallos.append("la descripción lleva la operación") }
        if !f.unidadesOpciones.contains(f.unidad) { fallos.append("unidad fuera de las opciones") }
        if f.unidad == "l" && f.unidadesOpciones.contains("dm³") { fallos.append("dm³ y l a la vez (son la misma cantidad)") }
        return fallos
    }

    // MARK: Sucesos: espacio muestral y conjuntos propios

    static let palos = ["oros", "copas", "espadas", "bastos"]
    static let valores = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]

    static func omega(_ id: String) -> [String] {
        if id == "dado" { return (1...6).map(String.init) }
        if id.hasPrefix("ruleta:"), let n = Int(id.dropFirst(7)) { return (1...n).map(String.init) }
        if id.hasPrefix("urna:") { return id.dropFirst(5).split(separator: ",").map(String.init) }
        if id == "baraja" { return palos.flatMap { p in valores.map { "\($0) \(p)" } } }
        if id == "baraja:palo" { return palos }
        if id == "baraja:valor" { return ["as", "2", "3", "4", "5", "6", "7", "sota", "caballo", "rey"] }
        if id == "monedas" { return ["cara-cara", "cara-cruz", "cruz-cara", "cruz-cruz"] }
        return []
    }

    static func ocurre(_ spec: String, _ r: String) -> Bool {
        spec.components(separatedBy: "|").contains { alternativa in
            alternativa.components(separatedBy: "&").allSatisfy { c in
                c.hasPrefix("!") ? !atomo(String(c.dropFirst()), r) : atomo(c, r)
            }
        }
    }

    static func atomo(_ a: String, _ r: String) -> Bool {
        let p = a.components(separatedBy: ":")
        let carta = r.components(separatedBy: " ")
        if carta.count == 2, let v = Int(carta[0]) {
            switch p[0] {
            case "palo": return carta[1] == p[1]
            case "valor": return v == Int(p[1])
            case "figura": return [10, 11, 12].contains(v)
            case "entre": return (Int(p[1])!...Int(p[2])!).contains(v)
            default: return false     // comodín y cualquier otra cosa: no existe
            }
        }
        if let n = Int(r) {
            switch p[0] {
            case "par": return n.isMultiple(of: 2)
            case "impar": return !n.isMultiple(of: 2)
            case "mayor": return n > Int(p[1])!
            case "menor": return n < Int(p[1])!
            case "igual": return n == Int(p[1])!
            case "mult": return n.isMultiple(of: Int(p[1])!)
            case "entre": return (Int(p[1])!...Int(p[2])!).contains(n)
            default: return false
            }
        }
        return p == ["color", r]
    }

    static func sucesos(_ m: Muestra, _ item: Item) -> [String] {
        let d = m.datos
        let o = omega(d["experimento"] ?? "")
        guard !o.isEmpty else { return ["experimento desconocido \(d["experimento"] ?? "")"] }
        func casos(_ s: String) -> Set<String> { Set(o.filter { ocurre(s, $0) }) }
        switch item.payload {
        case .marcarTexto(let mt):
            let marcados = Set(mt.tokens.filter { mt.correctos.contains($0.id) }.map(\.texto))
            let resto = mt.tokens.filter { !mt.correctos.contains($0.id) }.map(\.texto)
            var f: [String] = []
            if marcados != Set(o) { f.append("espacio \(marcados) ≠ \(o)") }
            if resto.isEmpty || resto.contains(where: o.contains) { f.append("distractores \(resto)") }
            return f
        case .clasificar(let c):
            let specs = (d["sucesos"] ?? "").components(separatedBy: ";")
            guard specs.count == c.fichas.count else { return ["sucesos"] }
            var f: [String] = []
            for (s, ficha) in zip(specs, c.fichas) {
                let n = casos(s).count
                let tipo = n == 0 ? "imposible" : (n == o.count ? "seguro" : "posible")
                if tipo != ficha.categoria { f.append("«\(ficha.texto)» (\(s)) es \(tipo), no \(ficha.categoria)") }
            }
            if !c.fichas.contains(where: { $0.categoria == "posible" }) { f.append("sin posibles") }
            return f
        case .eleccion(let e):
            guard let a = d["A"] else { return ["datos"] }
            if let b = d["B"] {
                let compatibles = !casos(a).isDisjoint(with: casos(b))
                let texto = e.opciones.first { $0.id == e.correcta }?.texto ?? ""
                return texto.hasPrefix(compatibles ? "Compatibles" : "Incompatibles") ? [] : ["compatibilidad mal: \(a) / \(b)"]
            }
            let specs = (d["opciones"] ?? "").components(separatedBy: ";")
            guard specs.count == e.opciones.count else { return ["opciones"] }
            let contrario = Set(o).subtracting(casos(a))
            let iguales = zip(e.opciones, specs).filter { casos($0.1) == contrario }.map(\.0.id)
            return iguales == [e.correcta] ? [] : ["contrario de \(a): opciones iguales al contrario \(iguales), correcta \(e.correcta)"]
        default:
            return ["payload"]
        }
    }

    // MARK: Palabras variables: la lista de la dirección y la clase de cada palabra

    static let invariablesDireccion: Set<String> = [
        "a", "ante", "con", "contra", "de", "desde", "durante", "en", "entre", "hacia", "hasta", "mediante", "para", "por", "según", "sin", "sobre", "tras",
        "y", "e", "ni", "o", "u", "pero", "sino", "aunque", "porque",
        "aquí", "allí", "cerca", "lejos", "hoy", "ayer", "siempre", "nunca", "despacio", "muy", "sí", "no", "también", "tampoco", "enseguida",
        "ay", "oh", "eh", "uf",
    ]
    static let excluidas: Set<String> = ["bajo", "bien", "mal", "mañana", "poco", "bastante", "medio", "mucho", "demasiado", "sobre", "para", "entre",
                                         // Pronombres excluidos a propósito por la dirección (fase 06 §0.4).
                                         "alguien", "nadie", "algo", "nada", "lo", "se", "me", "te"]
    /// Pronombres de la dirección (fase 06 §0.4): variables, en género y número.
    static let pronombres: Set<String> = ["él", "ella", "ellos", "ellas", "mío", "mía", "tuyo", "tuya", "suyo", "suya",
                                          "alguno", "alguna", "ninguno", "ninguna", "otro", "otra", "otros", "otras"]

    static func variables(_ m: Muestra, _ item: Item) -> [String] {
        guard case .clasificar(let c) = item.payload else { return ["payload"] }
        let palabras = (m.datos["palabras"] ?? "").components(separatedBy: ";").map { $0.components(separatedBy: ":") }
        guard palabras.count == c.fichas.count else { return ["palabras"] }
        let justificar = c.categorias.count == 3
        var f: [String] = []
        for (w, ficha) in zip(palabras, c.fichas) {
            let (texto, clase) = (w[0], w[1])
            if texto != ficha.texto { f.append("texto") }
            if excluidas.contains(texto) { f.append("«\(texto)» está excluida") }
            let variable = ["sustantivo", "adjetivo", "verbo", "determinante", "pronombre"].contains(clase)
            if variable == invariablesDireccion.contains(texto) { f.append("«\(texto)» (\(clase)) no casa con la lista de la dirección") }
            if clase == "pronombre" && !pronombres.contains(texto) { f.append("«\(texto)» no es un pronombre de la lista de la dirección") }
            let esperada = justificar ? (clase == "verbo" ? "personaNumero" : (variable ? "generoNumero" : "ninguna")) : (variable ? "variable" : "invariable")
            if ficha.categoria != esperada { f.append("«\(texto)»: \(ficha.categoria) ≠ \(esperada)") }
        }
        if !c.fichas.contains(where: { ["variable", "generoNumero", "personaNumero"].contains($0.categoria) }) { f.append("sin variables") }
        if !c.fichas.contains(where: { ["invariable", "ninguna"].contains($0.categoria) }) { f.append("sin invariables") }
        return f
    }

    // MARK: Lema: reglas inversas propias y los datos

    /// Conjugación regular propia (presente, imperfecto, pretérito, futuro, condicional e imperfecto y
    /// presente de subjuntivo) para comprobar que la forma es del infinitivo.
    static func formasRegulares(_ inf: String) -> Set<String> {
        let raiz = String(inf.dropLast(2)), t = inf.suffix(2)
        var d: [String]
        if t == "ar" {
            d = ["o", "as", "a", "amos", "áis", "an", "aba", "abas", "ábamos", "abais", "aban", "é", "aste", "ó", "asteis", "aron",
                 "e", "es", "emos", "éis", "en", "ara", "aras", "áramos", "arais", "aran"]
        } else {
            d = ["o", "es", "e", "en", "ía", "ías", "íamos", "íais", "ían", "í", "iste", "ió", "imos", "isteis", "ieron",
                 "a", "as", "amos", "áis", "an", "iera", "ieras", "iéramos", "ierais", "ieran"]
            d += t == "er" ? ["emos", "éis"] : ["imos", "ís"]
        }
        var s = Set(d.map { raiz + $0 })
        for e in ["é", "ás", "á", "emos", "éis", "án", "ía", "ías", "íamos", "íais", "ían"] { s.insert(inf + e) }
        return s
    }

    static func lema(_ m: Muestra, _ item: Item) -> [String] {
        guard case .eleccion(let e) = item.payload, let forma = m.datos["forma"], let lema = m.datos["lema"] else { return ["payload"] }
        var f: [String] = []
        if e.opciones.first(where: { $0.id == e.correcta })?.texto != lema { f.append("la correcta no es el lema") }
        if !e.opciones.contains(where: { $0.texto == forma }) { f.append("falta la forma tal como aparece") }
        let r = banco.recursos
        switch m.datos["clase"] {
        case "sustantivo":
            let ok = forma.hasSuffix("iones") ? lema == String(forma.dropLast(5)) + "ión"
                : (lema + "s" == forma && "aeiouáéó".contains(lema.last!)) || (lema + "es" == forma && "lrd".contains(lema.last!))
            if !ok { f.append("plural «\(forma)» de «\(lema)»") }
        case "adjetivo":
            let a = r.gramatica.atributos.first { $0.formas.values.contains(forma) }
            if a?.formas["ms"] != lema { f.append("adjetivo «\(forma)» → «\(a?.formas["ms"] ?? "?")»") }
        case "verbo":
            let irregular = r.verbos.irregulares.first { $0.infinitivo == lema && !$0.formas.isEmpty }
            let formas = irregular.map { Set($0.formas.values.flatMap { $0 }) } ?? formasRegulares(lema)
            if !formas.contains(forma) { f.append("«\(forma)» no es una forma de «\(lema)»") }
            // Ninguna otra forma de las opciones es el lema de otro verbo, y la forma es de un solo verbo.
            let otros = r.verbos.irregulares.filter { $0.infinitivo != lema && $0.formas.values.flatMap { $0 }.contains(forma) }
            if !otros.isEmpty { f.append("«\(forma)» también es de \(otros.map(\.infinitivo))") }
        default: f.append("clase")
        }
        return f
    }

    // MARK: Orden alfabético: la intercalación del sistema en español

    static let es = Locale(identifier: "es_ES")

    static func plegar(_ w: String) -> String {
        String(w.map { c -> Character in ["á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u"][c] ?? c })
    }

    static func orden(_ item: Item) -> [String] {
        guard case .ordenar(let o) = item.payload else { return ["payload"] }
        let textos = o.ordenCorrecto.compactMap { id in o.fichas.first { $0.id == id }?.texto }
        var f: [String] = []
        for (a, b) in zip(textos, textos.dropFirst()) where a.compare(b, locale: es) != .orderedAscending {
            f.append("«\(a)» no va antes de «\(b)»")
        }
        let comparten = textos.contains { a in textos.contains { b in a != b && plegar(a).prefix(2) == plegar(b).prefix(2) } }
        if !comparten { f.append("ninguna pareja comparte las 2 primeras letras: \(textos)") }
        return f
    }
}

// MARK: - Propiedades con 200 semillas en los 6 niveles

@Suite("Fase 05K · Propiedades de los generadores (200 semillas × 6 niveles)")
struct Fase05KPropiedadesTests {
    static let plantillas = banco.plantillas.filter { $0.procedencia.notas?.hasPrefix("Fase 05K") == true }
    static let validador = ValidadorContenido(anioActual: 2026)
    static let competencias = Set(banco.catalogo.todasLasCompetencias.map(\.id))

    @Test("14 plantillas aprobadas de las 4 competencias, con su tarjeta de teoría")
    func catalogoDePlantillas() {
        #expect(Self.plantillas.count == 14)
        #expect(Set(Self.plantillas.map(\.competencia)) == ["MAT.GEO.VOL", "MAT.PRO.SUCESOS", "LEN.CLA.VAR", "LEN.LEX.DICC"])
        #expect(Self.plantillas.allSatisfy { $0.validacion == Validacion(estado: .aprobado, revisor: "direccion", fecha: "2026-11-27") })
        for c in ["MAT.GEO.VOL", "MAT.PRO.SUCESOS", "LEN.CLA.VAR", "LEN.LEX.DICC"] {
            #expect(release.teoria.contains { $0.id == "\(c).T01" }, "\(c)")
            #expect(release.plantillas.contains { $0.competencia == c }, "\(c)")
        }
    }

    @Test("Validador, oráculo, determinismo y errores etiquetados", arguments: plantillas.map(\.id))
    func propiedades(_ id: String) throws {
        let base = try #require(Self.plantillas.first { $0.id == id })
        var fallos: [String] = []
        for d in 1...6 {
            let p = MotorGeneradores.ajustada(base, dificultad: d)
            for semilla in UInt64(0)..<200 {
                let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: banco.recursos)
                let item = MotorGeneradores.item(p, semilla: semilla, muestra: m)
                let errores = Self.validador.validar(item: item, competencias: Self.competencias)
                if !errores.isEmpty { fallos.append("\(item.id): \(errores)") }
                fallos += Oraculo05K.comprobar(p.tipo, m, item).map { "\(item.id): \($0)" }
                if case .eleccion(let e) = item.payload, Set(e.opciones.map(\.texto)).count != e.opciones.count { fallos.append("\(item.id): opciones repetidas") }
                if item.erroresHabituales.contains(where: { $0.error == nil }) {
                    fallos.append("\(item.id): error sin etiquetar «\(item.erroresHabituales.first { $0.error == nil }!.feedback)»")
                }
                if !Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item).correcto { fallos.append("\(item.id): la solución no es correcta") }
                if semilla.isMultiple(of: 50), try MotorGeneradores.generar(p, semilla: semilla, recursos: banco.recursos) != item { fallos.append("\(item.id): no determinista") }
                if fallos.count > 5 { break }
            }
        }
        #expect(fallos.isEmpty, "\(fallos.prefix(6))")
    }
}

// MARK: - Casos fijos

@Suite("Fase 05K · Casos fijos")
struct Fase05KCasosTests {
    @Test("Orden alfabético (RAE, Ortografía 2010): ch y ll no son letras aparte, la ñ tras la n y las tildes no cuentan")
    func ordenRAE() {
        let antes = GeneradorOrdenAlfabetico.antes
        #expect(antes("cesta", "chocolate") && antes("chocolate", "cielo"))
        #expect(antes("lista", "llama") && antes("llama", "lobo"))
        #expect(antes("nuez", "ñu") && antes("ñu", "oso"))
        #expect(antes("caña", "cana") == false && antes("cana", "caña"))
        #expect(antes("cámara", "camino") && antes("camión", "campo"))
        // El oráculo (intercalación del sistema en español) dice lo mismo.
        for (a, b) in [("cesta", "chocolate"), ("chocolate", "cielo"), ("lista", "llama"), ("nuez", "ñu"), ("cana", "caña"), ("cámara", "camino")] {
            #expect(a.compare(b, locale: Oraculo05K.es) == .orderedAscending, "\(a) < \(b)")
        }
    }

    @Test("Plurales: el lema es el singular")
    func plurales() {
        #expect(GeneradorLema.plural("canción") == "canciones" && GeneradorLema.plural("ciudad") == "ciudades")
        #expect(GeneradorLema.plural("pastel") == "pasteles" && GeneradorLema.plural("café") == "cafés" && GeneradorLema.plural("mesa") == "mesas")
        #expect(GeneradorLema.plural("lunes") == nil)
        let casos = GeneradorLema().casos(1, banco.recursos)
        #expect(casos.contains { $0.forma == "canciones" && $0.lema == "canción" } && !casos.contains { $0.lema == "lunes" })
    }

    @Test("Palabras variables: la lista de la dirección sin las excluidas; las 4 casillas tienen palabras")
    func invariables() {
        let inv = GeneradorPalabrasVariables.invariables().map(\.texto)
        #expect(Set(inv) == Oraculo05K.invariablesDireccion.subtracting(Oraculo05K.excluidas))
        let vars = GeneradorPalabrasVariables.variables(banco.recursos)
        #expect(vars.allSatisfy { !Oraculo05K.invariablesDireccion.contains($0.texto) && !Oraculo05K.excluidas.contains($0.texto) })
        for clase in ["sustantivo", "adjetivo", "verbo", "determinante"] { #expect(vars.contains { $0.clase == clase }, "\(clase)") }
        #expect(!vars.contains { $0.texto == "lunes" || $0.texto == "como" })
    }

    @Test("Pronombres de la dirección (fase 06 §0.4): variables en género y número; ninguno entre las invariables")
    func pronombres() {
        let inv = Set(GeneradorPalabrasVariables.invariables().map(\.texto))
        #expect(inv.isDisjoint(with: Oraculo05K.pronombres))
        let vars = GeneradorPalabrasVariables.variables(banco.recursos)
        let pron = vars.filter { $0.clase == "pronombre" }
        #expect(!pron.isEmpty && pron.allSatisfy { Oraculo05K.pronombres.contains($0.texto) && $0.variacion == .generoNumero })
        // Cada pronombre de la lista sale como variable (como pronombre o, si el léxico ya lo tiene, como determinante).
        #expect(Oraculo05K.pronombres.allSatisfy { p in vars.contains { $0.texto == p } })
        for w in ["alguien", "nadie", "algo", "nada", "lo", "se", "me", "te"] {
            #expect(!inv.contains(w) && !vars.contains { $0.texto == w }, "\(w)")
        }
    }

    @Test("Volumen: evaluación del resultado, la unidad aparte, los pasos y los errores típicos")
    func evaluarVolumen() throws {
        let p = try #require(banco.plantilla(id: "MAT.GEO.VOL.G03"))
        let item = try MotorGeneradores.generar(p, semilla: 7, recursos: banco.recursos)
        guard case .figuraVolumen(let f) = item.payload else { Issue.record("payload"); return }
        var r = f.respuestaCorrecta
        #expect(f.evaluar(r).correcto && f.unidad == "l" && !f.cubos)
        r.unidad = "cm³"
        #expect(f.evaluar(r).errores == ["unidad"])
        r = f.respuestaCorrecta
        r.resultado = try #require(f.erroneos["sinLitros"])
        #expect(f.evaluar(r).errores.first == "sinLitros")
        r = f.respuestaCorrecta
        r.valores["base"] = "1"
        #expect(f.evaluar(r).correcto, "Los pasos ayudan; manda el resultado")
        #expect(f.evaluar(r).errores.isEmpty)
        r.resultado = "1"
        #expect(f.evaluar(r).errores.contains("campo_base") && f.evaluar(r).errores.contains("resultado"))
        // Cubos: solo en los peldaños 1–2 y con tantas capas como altura.
        let g1 = try #require(banco.plantilla(id: "MAT.GEO.VOL.G01"))
        let cubos = try MotorGeneradores.generar(g1, semilla: 3, recursos: banco.recursos)
        guard case .figuraVolumen(let fc) = cubos.payload else { Issue.record("payload"); return }
        #expect(fc.cubos && fc.capas == Int(fc.solidos[0].alto) && fc.campos.map(\.id) == ["base", "capas"])
        #expect(cubos.pasos.count >= 2 && cubos.pasos.contains { $0.porque != nil } && cubos.juego == "Capas" && cubos.conReintento)
        let sinCubos = try MotorGeneradores.generar(MotorGeneradores.ajustada(g1, dificultad: 1, peldano: 3), semilla: 3, recursos: banco.recursos)
        if case .figuraVolumen(let fs) = sinCubos.payload { #expect(!fs.cubos && fs.campos.map(\.id) == ["base", "altura"]) }
        // El nivel 4 y el 6 cubren sus dos variantes.
        let g4 = try #require(banco.plantilla(id: "MAT.GEO.VOL.G04")), g6 = try #require(banco.plantilla(id: "MAT.GEO.VOL.G06"))
        let c4 = Set((0..<40).compactMap { try? MotorGeneradores.muestra(g4, semilla: $0, recursos: banco.recursos).clave.components(separatedBy: "|")[0] })
        let c6 = Set((0..<40).compactMap { try? MotorGeneradores.muestra(g6, semilla: $0, recursos: banco.recursos).clave.components(separatedBy: "|")[0] })
        #expect(c4 == ["dos", "deposito"] && c6 == ["mixtas", "extraer"])
    }

    @Test("Sucesos: la baraja española tiene 40 cartas, sin 8 ni 9; el espacio muestral con baraja")
    func baraja() throws {
        let e = GeneradorSucesos.baraja(compuestos: true)
        #expect(e.omega.count == 40 && GeneradorSucesos.conjunto("valor:8", e).isEmpty && GeneradorSucesos.conjunto("comodin", e).isEmpty)
        #expect(GeneradorSucesos.conjunto("figura", e).count == 12 && GeneradorSucesos.conjunto("palo:oros&!figura", e).count == 7)
        let p = try #require(banco.plantilla(id: "MAT.PRO.SUCESOS.G01"))
        let item = try MotorGeneradores.generar(MotorGeneradores.ajustada(p, dificultad: 4), semilla: 1, recursos: banco.recursos)
        guard case .marcarTexto(let m) = item.payload else { Issue.record("payload"); return }
        #expect(Set(m.tokens.filter { m.correctos.contains($0.id) }.map(\.texto)) == Set(["oros", "copas", "espadas", "bastos"]))
    }
}

// MARK: - Integración: Camino, sesión diaria y plano del simulacro

@Suite("Fase 05K · Integración y anexo de la 05J")
struct Fase05KIntegracionTests {
    static let nuevas = ["MAT.GEO.VOL", "MAT.PRO.SUCESOS", "LEN.CLA.VAR", "LEN.LEX.DICC"]

    @Test("«Por bloques»: las 4 competencias tienen candidatos y ya no se anotan como «no incluye»")
    func plano() {
        let g = GeneradorSimulacro(banco: release)
        for c in Self.nuevas { #expect(!g.candidatos(c).isEmpty, "\(c)") }
        let plano = PlanoExamen.calcular(release.tribunal)
        for s in UInt64(1)...5 {
            let sim = g.generar(semilla: s, plano: plano)
            #expect(Set(sim.noIncluye).isDisjoint(with: Self.nuevas), "\(sim.noIncluye)")
        }
    }

    @Test("Camino y sesión diaria: sus ítems se generan y se resuelven con la solución de referencia")
    func caminoYSesion() throws {
        for c in Self.nuevas {
            let ps = release.plantillas.filter { $0.competencia == c }
            #expect(!ps.isEmpty && !Set(ps.map(\.peldano)).isDisjoint(with: [1, 2]), "\(c): hay plantilla para los primeros peldaños")
            for p in ps {
                let i = try MotorGeneradores.generar(p, semilla: 11, recursos: release.recursos)
                #expect(release.item(id: i.id) == i, "\(i.id)")
            }
        }
    }

    @Test("Tarjetas de teoría con el texto de la dirección (05K §5)")
    func teoria() throws {
        func bloque(_ id: String, _ tipo: TarjetaTeoria.BloqueTeoria.Tipo) -> String? {
            release.teoria.first { $0.id == id }?.bloques.first { $0.tipo == tipo }?.contenido
        }
        #expect(bloque("MAT.GEO.VOL.T01", .regla) == "El volumen de un prisma es el área de la base por la altura. En un ortoedro: largo · ancho · alto.")
        #expect(bloque("MAT.GEO.VOL.T01", .truco) == "Piensa en capas: el área de la base es una capa y la altura dice cuántas capas hay.")
        #expect(bloque("MAT.PRO.SUCESOS.T01", .truco) == "Escribe primero el espacio muestral completo; después marca los resultados de cada suceso.")
        #expect(bloque("LEN.CLA.VAR.T01", .truco) == "Prueba a ponerla en plural o en femenino: si no admite ningún cambio, es invariable.")
        #expect(bloque("LEN.LEX.DICC.T01", .regla) == "En el diccionario, los verbos aparecen en infinitivo; los sustantivos, en singular; y los adjetivos, en masculino singular.")
        #expect(bloque("LEN.LEX.DICC.T01", .truco) == "Desde 2010, «ch» y «ll» no son letras aparte: «chocolate» va entre «cesta» y «cielo».")
        // LEN.LEX.DICC.T01 conserva sus bloques anteriores.
        #expect(release.teoria.first { $0.id == "LEN.LEX.DICC.T01" }?.bloques.count == 4)
    }

    @Test("Anexo de la 05J: texto de ERR.LEN.ORT.CTX.1, FR.0088/0089 y páginas de las figuras")
    func anexo() throws {
        let e = try #require(release.recursos.errores.errores.first { $0.id == "ERR.LEN.ORT.CTX.1" })
        #expect(e.descripcion == "Eliges la palabra por cómo suena, sin comprobar qué significa en la frase.")
        #expect(e.remedio.explicacion == "Hay palabras que suenan igual pero significan cosas distintas. Lee la frase entera, piensa qué quiere decir y elige la forma cuyo significado encaja.")
        #expect(ValidadorContenido(anioActual: 2026).validar(errores: release.recursos.errores, banco: release).isEmpty)
        let frases = release.recursos.frases.frases.filter { ["FR.0088", "FR.0089"].contains($0.id) }
        #expect(frases.count == 2 && frases.allSatisfy { $0.ambigua == false })
        let paginas = [("OF.2022.O", 15, 11), ("OF.2022.O", 20, 13), ("OF.2024.O", 17, 12), ("OF.2026.O", 17, 14)]
        for (examen, n, pagina) in paginas {
            let q = release.tribunal.examenes.first { $0.id == examen }?.preguntas.first { $0.numero == n }
            #expect(q?.paginaFigura == pagina && q?.figura != nil, "\(examen) \(n)")
        }
    }
}
