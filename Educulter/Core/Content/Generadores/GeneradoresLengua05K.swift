import Foundation

// Fase 05K §3 y §4: palabras variables e invariables (LEN.CLA.VAR) y el diccionario (LEN.LEX.DICC).

/// Caché de lo que un generador calcula a partir de los recursos (listas de palabras, paradigmas):
/// se calcula una vez y no en cada muestra (el recuento de Progreso genera miles de muestras).
final class CacheRecursos05K<V>: @unchecked Sendable {
    private let cerrojo = NSLock()
    private var valores: [String: V] = [:]

    func valor(_ clave: String, _ calcular: () -> V) -> V {
        cerrojo.lock()
        if let v = valores[clave] { cerrojo.unlock(); return v }
        cerrojo.unlock()
        let v = calcular()
        cerrojo.lock()
        valores[clave] = v
        cerrojo.unlock()
        return v
    }

    /// Huella barata de los recursos que usan estos generadores.
    static func huella(_ r: RecursosGeneradores) -> String {
        "\(r.lexico.count)|\(r.gramatica.verbos.count)|\(r.gramatica.atributos.count)|\(r.gramatica.sujetos.count)|\(r.verbos.regulares.count)|\(r.verbos.irregulares.count)|\(r.compatibilidad.verbos.count)"
    }
}

// MARK: - Palabras variables e invariables

/// Clasificar palabras en variables e invariables, o justificar en qué varían (LEN.CLA.VAR, 05K §3).
///
/// - Variables: los sustantivos, adjetivos y verbos de `gramatica/piezas.json` (los verbos, en formas
///   conjugadas) y sus determinantes. El léxico no tiene pronombres etiquetados, así que no salen.
/// - Invariables: la lista de la dirección (05K §3), sin las palabras que también son variables en
///   otros usos (las 9 que excluye la dirección y, con su mismo criterio, «sobre», «para» y
///   «entre», que también son sustantivo o formas verbales; D-144).
///
/// | Nivel | Palabras |
/// |---|---|
/// | 1 | sustantivos y adjetivos; preposiciones |
/// | 2 | más verbos; más conjunciones |
/// | 3 | más determinantes; más adverbios |
/// | 4 | todas las clases |
/// | 5 | todas, con al menos un verbo y un adverbio |
/// | 6 | todas, con palabras cortas (determinantes, interjecciones y conjunciones de una o dos letras) |
struct GeneradorPalabrasVariables: GeneradorItems {
    let tipo = "palabrasVariables"
    let mecanicas: Set<Mecanica> = [.clasificar]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    enum Variacion: String { case generoNumero, personaNumero, numero, ninguna }

    struct Palabra: Equatable {
        var texto: String
        var clase: String
        var variacion: Variacion
        var variable: Bool { variacion != .ninguna }
    }

    /// Lista de la dirección (05K §3), por clase.
    static let invariablesDireccion: [String: [String]] = [
        "preposición": ["a", "ante", "con", "contra", "de", "desde", "durante", "en", "entre", "hacia", "hasta", "mediante", "para", "por", "según", "sin", "sobre", "tras"],
        "conjunción": ["y", "e", "ni", "o", "u", "pero", "sino", "aunque", "porque"],
        "adverbio": ["aquí", "allí", "cerca", "lejos", "hoy", "ayer", "siempre", "nunca", "despacio", "muy", "sí", "no", "también", "tampoco", "enseguida"],
        "interjección": ["ay", "oh", "eh", "uf"],
    ]
    /// Excluidas por la dirección por ser también variables en otros usos.
    static let excluidasDireccion: Set<String> = ["bajo", "bien", "mal", "mañana", "poco", "bastante", "medio", "mucho", "demasiado"]
    /// Excluidas aquí con el mismo criterio (D-144): «el sobre», «para» (parar) y «entre» (entrar).
    static let excluidasHomografas: Set<String> = ["sobre", "para", "entre"]
    /// Sustantivos que no cambian de forma o que también son de otra clase.
    static let sustantivosFuera: Set<String> = ["lunes", "cuidado", "silencio", "leche", "alegría"]
    /// Sustantivos con variación de género (niño/niña, vecino/vecina…).
    static let sustantivosConGenero: Set<String> = ["niño", "niña", "niños", "niñas", "alumna", "alumnas", "abuela", "abuelas", "cocinero",
                                                    "cocineros", "profesora", "profesoras", "vecino", "vecinos", "médico", "médicos", "gata"]
    static let generoClase = ["sustantivo": "un", "adjetivo": "un", "verbo": "un", "determinante": "un", "adverbio": "un",
                              "preposición": "una", "conjunción": "una", "interjección": "una"]

    static let listaInvariables: [Palabra] = invariables()

    static func invariables() -> [Palabra] {
        invariablesDireccion.flatMap { clase, ws in
            ws.filter { !excluidasDireccion.contains($0) && !excluidasHomografas.contains($0) }.map { Palabra(texto: $0, clase: clase, variacion: .ninguna) }
        }.sorted { $0.texto < $1.texto }
    }

    private static let cacheVariables = CacheRecursos05K<[Palabra]>()

    static func variables(_ r: RecursosGeneradores) -> [Palabra] {
        cacheVariables.valor(CacheRecursos05K<[Palabra]>.huella(r)) { calcularVariables(r) }
    }

    private static func calcularVariables(_ r: RecursosGeneradores) -> [Palabra] {
        var out: [Palabra] = []
        let invariablesTexto = Set(invariablesDireccion.values.flatMap { $0 }).union(excluidasDireccion).union(["como", "cuando", "donde", "mientras", "pues"])
        var sustantivos = Set<String>(), determinantes = Set<String>()
        func recorrer(_ s: Sintagma) {
            for tk in s.tokens where tk.count == 2 {
                if tk[1] == "sust" { sustantivos.insert(tk[0]) }
                if tk[1] == "det" { determinantes.insert(tk[0]) }
            }
        }
        r.gramatica.sujetos.forEach(recorrer)
        r.gramatica.verbos.forEach { v in v.cd?.forEach(recorrer) }
        r.gramatica.complementos.values.forEach { $0.forEach(recorrer) }
        for s in sustantivos.sorted() where !sustantivosFuera.contains(s) && !invariablesTexto.contains(s) {
            out.append(Palabra(texto: s, clase: "sustantivo", variacion: sustantivosConGenero.contains(s) ? .generoNumero : .numero))
        }
        for a in r.gramatica.atributos {
            let genero = a.formas["ms"] != a.formas["fs"]
            for f in Set(a.formas.values).sorted() { out.append(Palabra(texto: f, clase: "adjetivo", variacion: genero ? .generoNumero : .numero)) }
        }
        for d in determinantes.sorted() {
            out.append(Palabra(texto: d, clase: "determinante", variacion: d == "su" ? .numero : .generoNumero))
        }
        // Formas conjugadas (presente, pretérito perfecto simple y futuro de indicativo).
        var vistas = Set(out.map(\.texto))
        for v in r.gramatica.verbos.map(\.infinitivo) {
            for t in ["Presente", "Pretérito perfecto simple", "Futuro simple"] {
                for f in Conjugador.formas(v, tiempo: t, modo: Conjugador.indicativo, irregulares: r.verbos.irregulares) ?? []
                where !f.contains(" ") && !invariablesTexto.contains(f) && vistas.insert(f).inserted {
                    out.append(Palabra(texto: f, clase: "verbo", variacion: .personaNumero))
                }
            }
        }
        return out
    }

    /// Clases que pueden salir en cada nivel.
    static func clases(_ nivel: Int) -> (variables: Set<String>, invariables: Set<String>) {
        switch nivel {
        case 1: return (["sustantivo", "adjetivo"], ["preposición"])
        case 2: return (["sustantivo", "adjetivo", "verbo"], ["preposición", "conjunción"])
        case 3: return (["sustantivo", "adjetivo", "verbo", "determinante"], ["preposición", "conjunción", "adverbio"])
        default: return (["sustantivo", "adjetivo", "verbo", "determinante"], ["preposición", "conjunción", "adverbio", "interjección"])
        }
    }

    static let categoriasVariable = [ElementoNombre(id: "variable", nombre: "Variable"), ElementoNombre(id: "invariable", nombre: "Invariable")]
    static let categoriasJustificar = [ElementoNombre(id: "generoNumero", nombre: "Varía en género y número"),
                                       ElementoNombre(id: "personaNumero", nombre: "Varía en persona y número"),
                                       ElementoNombre(id: "ninguna", nombre: "No admite cambios de forma")]

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nivel = min(max(p.dificultad, 1), 6)
        let justificar = p.textos("pregunta", porDefecto: ["variable"]).first == "justificar"
        let (cv, ci) = Self.clases(nivel)
        // Justificar necesita siempre verbos (la casilla «persona y número») y adjetivos o determinantes.
        var vars = Self.variables(recursos).filter { cv.contains($0.clase) || (justificar && $0.clase == "verbo") }
        var invs = Self.listaInvariables.filter { ci.contains($0.clase) }
        if justificar { vars = vars.filter { $0.variacion != .numero } }
        guard !vars.isEmpty, !invs.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        if nivel == 6 {
            // Palabras cortas, las que más confunden.
            let cortasV = vars.filter { $0.texto.count <= 3 }, cortasI = invs.filter { $0.texto.count <= 2 }
            if !cortasV.isEmpty { vars = cortasV + Array(rng.barajar(vars).prefix(6)) }
            if !cortasI.isEmpty { invs = cortasI }
        }
        // 4 palabras: de 1 a 3 variables (en justificar, al menos una de cada casilla).
        var elegidas: [Palabra] = []
        func tomar(_ lista: [Palabra]) {
            if let w = rng.barajar(lista).first(where: { w in !elegidas.contains { $0.texto == w.texto } }) { elegidas.append(w) }
        }
        if justificar {
            tomar(vars.filter { $0.variacion == .generoNumero })
            tomar(vars.filter { $0.variacion == .personaNumero })
            tomar(invs)
            tomar(rng.probabilidad(0.5) ? vars : invs)
        } else {
            let nVar = rng.entero(1...3)
            for _ in 0..<nVar { tomar(nivel == 5 && !elegidas.contains { $0.clase == "verbo" } ? vars.filter { $0.clase == "verbo" } : vars) }
            for _ in nVar..<4 { tomar(nivel == 5 && !elegidas.contains { $0.clase == "adverbio" } ? invs.filter { $0.clase == "adverbio" } : invs) }
        }
        guard elegidas.count == 4 else { throw ErrorGenerador.sinCaso(tipo) }
        elegidas = rng.barajar(elegidas)
        let fichas = elegidas.enumerated().map { i, w in
            Payload.Clasificar.Ficha(id: "p\(i + 1)", texto: w.texto, categoria: justificar ? w.variacion.rawValue : (w.variable ? "variable" : "invariable"))
        }
        let payload = Payload.Clasificar(categorias: justificar ? Self.categoriasJustificar : Self.categoriasVariable, fichas: fichas)
        let errores = zip(fichas, elegidas).map { f, w -> ErrorHabitual in
            let art = Self.generoClase[w.clase] ?? "un"
            if justificar {
                let como = switch w.variacion {
                case .generoNumero: "varía en género y número"
                case .personaNumero: "varía en persona y número"
                default: "no admite cambios de forma"
                }
                return ErrorHabitual(respuesta: f.id, feedback: "«\(w.texto)» es \(art) \(w.clase): \(como).")
            }
            return ErrorHabitual(respuesta: f.id, feedback: w.variable ? "«\(w.texto)» es variable: es \(art) \(w.clase) y cambia de forma."
                                 : "«\(w.texto)» es invariable: es \(art) \(w.clase) y no cambia de forma.")
        }
        let pregunta = justificar ? "Lleva cada palabra a la casilla que explica cómo cambia de forma."
            : "Clasifica cada palabra en variable o invariable."
        return Muestra(clave: "\(justificar ? "just" : "var")|" + elegidas.map(\.texto).sorted().joined(separator: ","),
                       valores: ["pregunta": pregunta], payload: .clasificar(payload),
                       explicacion: "Son variables el sustantivo, el adjetivo, el determinante, el pronombre y el verbo; son invariables el adverbio, la preposición, la conjunción y la interjección.",
                       erroresHabituales: errores, pistas: ["Prueba a ponerla en plural o en femenino: si no admite ningún cambio, es invariable."],
                       complejidad: Double(nivel) + Double(elegidas.filter { $0.texto.count <= 2 }.count) * 0.05,
                       datos: ["palabras": elegidas.map { "\($0.texto):\($0.clase)" }.joined(separator: ";")])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

// MARK: - Lema: la entrada del diccionario

/// Dada una forma, elegir su entrada en el diccionario (LEN.LEX.DICC, 05K §4): verbos → infinitivo,
/// sustantivos en plural → singular, adjetivos → masculino singular. Distractores: otras formas de
/// la misma palabra (entre ellas, la forma tal como aparece).
///
/// | Nivel | Formas |
/// |---|---|
/// | 1 | sustantivos en plural |
/// | 2 | adjetivos en femenino o en plural |
/// | 3 | verbos en -ar: presente, pretérito perfecto simple y futuro |
/// | 4 | verbos regulares en más tiempos (también subjuntivo) |
/// | 5 | verbos irregulares |
/// | 6 | verbos irregulares y regulares en cualquier tiempo simple |
struct GeneradorLema: GeneradorItems {
    let tipo = "lema"
    let mecanicas: Set<Mecanica> = [.eleccion]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    struct Caso { var forma: String; var lema: String; var clase: String; var otras: [String] }

    /// Plural de un sustantivo en singular (reglas generales; las palabras que no las siguen quedan fuera).
    static func plural(_ s: String) -> String? {
        let vocales = "aeiouáéó"
        guard let ultima = s.last else { return nil }
        if s.hasSuffix("ión") { return String(s.dropLast(3)) + "iones" }
        if vocales.contains(ultima) { return s + "s" }
        if "lrd".contains(ultima) { return s + "es" }
        return nil
    }

    static let sustantivosFuera: Set<String> = ["lunes", "cuidado", "silencio", "leche", "alegría"]
    /// Pares de género de los sustantivos (otra forma de la misma palabra).
    static let parejas = ["niño": "niña", "niña": "niño", "vecino": "vecina", "médico": "médica", "cocinero": "cocinera",
                          "profesora": "profesor", "alumna": "alumno", "abuela": "abuelo", "gata": "gato", "perro": "perra"]

    private static let cacheCasos = CacheRecursos05K<[Caso]>()

    func casos(_ nivel: Int, _ r: RecursosGeneradores) -> [Caso] {
        Self.cacheCasos.valor("\(nivel)|" + CacheRecursos05K<[Caso]>.huella(r)) { calcularCasos(nivel, r) }
    }

    private func calcularCasos(_ nivel: Int, _ r: RecursosGeneradores) -> [Caso] {
        switch nivel {
        case 1:
            var singulares = Set<String>()
            for s in r.gramatica.sujetos + r.gramatica.verbos.flatMap({ $0.cd ?? [] }) + r.gramatica.complementos.values.flatMap({ $0 }) {
                for tk in s.tokens where tk.count == 2 && tk[1] == "sust" && !tk[0].hasSuffix("s") { singulares.insert(tk[0]) }
            }
            return singulares.subtracting(Self.sustantivosFuera).sorted().compactMap { s in
                guard let pl = Self.plural(s) else { return nil }
                var otras = [pl]
                if let f = Self.parejas[s], let fp = Self.plural(f) { otras += [f, fp] }
                return Caso(forma: pl, lema: s, clase: "sustantivo", otras: otras)
            }
        case 2:
            return r.gramatica.atributos.filter { $0.formas["ms"] != $0.formas["fs"] }.flatMap { a -> [Caso] in
                guard let ms = a.formas["ms"] else { return [] }
                let otras = ["fs", "mp", "fp"].compactMap { a.formas[$0] }
                return otras.map { Caso(forma: $0, lema: ms, clase: "adjetivo", otras: otras) }
            }
        default:
            let banco = GeneradorAnalisisVerbal.banco(r)
            var paradigmas: [String: [String]] = [:]          // infinitivo → formas simples
            let ind = Conjugador.indicativo, sub = Conjugador.subjuntivo
            let tiempos: [(String, String)] = switch nivel {
            case 3: [("Presente", ind), ("Pretérito perfecto simple", ind), ("Futuro simple", ind)]
            case 4: [("Presente", ind), ("Pretérito imperfecto", ind), ("Pretérito perfecto simple", ind), ("Futuro simple", ind),
                     ("Condicional simple", ind), ("Presente", sub)]
            default: [("Presente", ind), ("Pretérito imperfecto", ind), ("Pretérito perfecto simple", ind), ("Futuro simple", ind),
                      ("Condicional simple", ind), ("Presente", sub), ("Pretérito imperfecto", sub)]
            }
            let verbos: [String] = switch nivel {
            case 3: banco.regulares.filter { $0.hasSuffix("ar") }
            case 4: banco.regulares
            case 5: banco.irregulares.filter { !$0.formas.isEmpty }.map(\.infinitivo)
            default: banco.irregulares.filter { !$0.formas.isEmpty }.map(\.infinitivo) + banco.regulares
            }
            for v in verbos {
                var fs: [String] = []
                // Los irregulares, solo en los tiempos escritos en `verbos.json` (los demás no se conjugan por regla).
                if let irr = banco.irregulares.first(where: { $0.infinitivo == v && !$0.formas.isEmpty }) {
                    fs = irr.formas.values.flatMap { $0 }.filter { !$0.contains(" ") }
                } else {
                    for (t, m) in tiempos { fs += (Conjugador.formas(v, tiempo: t, modo: m, irregulares: banco.irregulares) ?? []).filter { !$0.contains(" ") } }
                }
                paradigmas[v] = Array(Set(fs)).sorted()
            }
            // Formas de un solo verbo (fui es de ser y de ir: fuera).
            var duenos: [String: Set<String>] = [:]
            for (v, fs) in paradigmas { for f in fs { duenos[f, default: []].insert(v) } }
            return paradigmas.keys.sorted().flatMap { v in
                paradigmas[v]!.filter { duenos[$0]?.count == 1 && $0 != v }.map { f in
                    Caso(forma: f, lema: v, clase: "verbo", otras: paradigmas[v]!.filter { $0 != f && $0 != v })
                }
            }
        }
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nivel = min(max(p.dificultad, 1), 6)
        let todos = casos(nivel, recursos)
        guard !todos.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let c = rng.elemento(todos)
        let regla = switch c.clase {
        case "verbo": "los verbos se buscan en infinitivo"
        case "sustantivo": "los sustantivos se buscan en singular"
        default: "los adjetivos se buscan en masculino singular"
        }
        var distractores: [(texto: String, feedback: String)] = [(c.forma, "No se busca la forma tal como aparece: \(regla).")]
        for o in rng.barajar(c.otras) where o != c.forma && o != c.lema {
            distractores.append((o, "«\(o)» es otra forma de la misma palabra: \(regla)."))
        }
        let (eleccion, errores) = Opciones.eleccion(correcta: c.lema, distractores: distractores, rng: &rng)
        return Muestra(clave: "lema|\(c.forma)", valores: ["pregunta": "¿Qué palabra buscarías en el diccionario para encontrar «\(c.forma)»?"],
                       payload: .eleccion(eleccion),
                       explicacion: "En el diccionario, \(regla): «\(c.forma)» está en «\(c.lema)».",
                       erroresHabituales: errores, pistas: ["Piensa en la forma que encabeza la entrada: infinitivo, singular o masculino singular."],
                       complejidad: Double(nivel) + Double(c.forma.count) * 0.01,
                       datos: ["forma": c.forma, "lema": c.lema, "clase": c.clase])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

// MARK: - Orden alfabético

/// Ordenar 4 palabras como en el diccionario (LEN.LEX.DICC, 05K §4), con al menos 2 que comparten
/// las primeras letras. Regla de la RAE (*Ortografía*, 2010): «ch» y «ll» no son letras aparte (se
/// ordenan como c + h y l + l), la ñ va después de la n y las tildes no cambian el orden.
///
/// | Nivel | Palabras |
/// |---|---|
/// | 1 | 2 comparten las 2 primeras letras |
/// | 2 | dos parejas que comparten las 2 primeras letras |
/// | 3 | 2 comparten las 3 primeras letras |
/// | 4 | 3 comparten las 2 primeras letras |
/// | 5 | con una palabra con ch, ll, ñ o tilde entre otras de su misma letra |
/// | 6 | 3 comparten las 3 primeras letras, con ch, ll, ñ o tilde si se puede |
struct GeneradorOrdenAlfabetico: GeneradorItems {
    let tipo = "ordenAlfabetico"
    let mecanicas: Set<Mecanica> = [.ordenar]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    static let alfabeto = Array("abcdefghijklmnñopqrstuvwxyz")
    static let sinTilde: [Character: Character] = ["á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u"]

    /// Clave de orden: cada letra por su posición en el alfabeto (ñ entre n y o; sin tildes).
    static func clave(_ w: String) -> [Int] {
        w.lowercased().map { c in alfabeto.firstIndex(of: sinTilde[c] ?? c) ?? 99 }
    }

    static func antes(_ a: String, _ b: String) -> Bool { clave(a).lexicographicallyPrecedes(clave(b)) }

    /// Léxico preparado una sola vez: palabras utilizables (al menos 3 letras, solo letras y sin dos
    /// con la misma clave), su clave y los grupos por prefijo de 1, 2 y 3 letras.
    struct Lexico {
        var palabras: [String]
        var clave: [String: [Int]]
        /// n → prefijo → palabras (ordenadas).
        var grupos: [Int: [[Int]: [String]]]
        var trampas: [String]

        func prefijo(_ w: String, _ n: Int) -> [Int] { Array((clave[w] ?? []).prefix(n)) }
        func mismos(_ w: String, _ n: Int) -> [String] { (grupos[n]?[prefijo(w, n)] ?? []).filter { $0 != w } }
    }

    private static let cacheLexico = CacheRecursos05K<Lexico>()

    static func lexico(_ r: RecursosGeneradores) -> Lexico {
        cacheLexico.valor(CacheRecursos05K<Lexico>.huella(r)) {
            var vistas: [[Int]: String] = [:], descartadas = Set<[Int]>()
            for e in r.lexico {
                let w = e.palabra.lowercased()
                guard w.count >= 3, w.count <= 11, w.allSatisfy({ alfabeto.contains(sinTilde[$0] ?? $0) }) else { continue }
                let k = clave(w)
                if vistas[k] != nil { descartadas.insert(k) } else { vistas[k] = w }
            }
            let palabras = vistas.filter { !descartadas.contains($0.key) }.map(\.value).sorted()
            let claves = Dictionary(uniqueKeysWithValues: palabras.map { ($0, clave($0)) })
            var grupos: [Int: [[Int]: [String]]] = [:]
            for n in 1...3 { grupos[n] = Dictionary(grouping: palabras, by: { Array(claves[$0]!.prefix(n)) }).mapValues { $0.sorted() } }
            return Lexico(palabras: palabras, clave: claves, grupos: grupos, trampas: palabras.filter(trampa))
        }
    }

    /// Palabras utilizables del léxico.
    static func palabras(_ r: RecursosGeneradores) -> [String] { lexico(r).palabras }

    static func trampa(_ w: String) -> Bool { w.contains("ch") || w.contains("ll") || w.contains("ñ") || w.contains { sinTilde[$0] != nil } }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nivel = min(max(p.dificultad, 1), 6)
        let lx = Self.lexico(recursos)
        let pool = lx.palabras
        guard pool.count >= 20 else { throw ErrorGenerador.sinRecursos(tipo) }
        func grupo(_ n: Int, _ k: Int, alrededor de: String? = nil) -> [String]? {
            let semilla = de ?? rng.elemento(pool)
            let mismos = lx.mismos(semilla, n)
            guard mismos.count >= k - 1 else { return nil }
            return [semilla] + Array(rng.barajar(mismos).prefix(k - 1))
        }
        var elegidas: [String] = []
        for _ in 0..<300 {
            var g: [String]?
            switch nivel {
            case 1: g = grupo(2, 2)
            case 2: if let a = grupo(2, 2), let b = grupo(2, 2), Set(a).isDisjoint(with: b), lx.prefijo(a[0], 1) != lx.prefijo(b[0], 1) { g = a + b }
            case 3: g = grupo(3, 2)
            case 4: g = grupo(2, 3)
            case 5:
                // La trampa (ch, ll, ñ o tilde) junto a una pareja de su misma letra que comparte las 2 primeras.
                let t = rng.elemento(lx.trampas)
                let parejas = (lx.grupos[2] ?? [:]).filter { $0.key.first == lx.prefijo(t, 1).first && $0.value.filter { $0 != t }.count >= 2 }
                    .sorted { $0.key.lexicographicallyPrecedes($1.key) }.map { $0.value.filter { $0 != t } }
                if !parejas.isEmpty { g = [t] + Array(rng.barajar(rng.elemento(parejas)).prefix(2)) }
            default:
                let t = rng.elemento(lx.trampas)
                g = grupo(3, 3, alrededor: t) ?? grupo(2, 3, alrededor: t)
            }
            guard var lista = g else { continue }
            // Completa hasta 4 con palabras de otras letras.
            var iniciales = Set(lista.map { lx.prefijo($0, 1) })
            var intentos = 0
            while lista.count < 4 && intentos < 200 {
                let w = rng.elemento(pool)
                intentos += 1
                if !iniciales.contains(lx.prefijo(w, 1)) && !lista.contains(w) { lista.append(w); iniciales.insert(lx.prefijo(w, 1)) }
            }
            if lista.count == 4 { elegidas = lista; break }
        }
        guard elegidas.count == 4 else { throw ErrorGenerador.sinCaso(tipo) }
        let fichas = rng.barajar(elegidas).enumerated().map { ElementoTexto(id: "w\($0.offset + 1)", texto: $0.element) }
        let orden = fichas.sorted { Self.antes($0.texto, $1.texto) }.map(\.id)
        let payload = Payload.Ordenar(fichas: fichas, ordenCorrecto: orden, etiquetaInicio: "Primera", etiquetaFin: "Última")
        let errores = fichas.map { f -> ErrorHabitual in
            let w = f.texto
            let feedback = if w.contains("ch") || w.contains("ll") { "«\(w)»: ch y ll no son letras aparte; se ordenan como c + h y l + l." }
                else if w.contains("ñ") { "«\(w)»: la ñ va después de la n." }
                else if w.contains(where: { Self.sinTilde[$0] != nil }) { "«\(w)»: las tildes no cambian el orden alfabético." }
                else { "«\(w)»: compara letra a letra hasta la primera que cambie." }
            return ErrorHabitual(respuesta: f.id, feedback: feedback)
        }
        let ordenadas = orden.compactMap { id in fichas.first { $0.id == id }?.texto }
        let comun = (1...4).last { n in elegidas.contains { a in elegidas.contains { b in a != b && lx.prefijo(a, n) == lx.prefijo(b, n) } } } ?? 1
        return Muestra(clave: "orden|" + elegidas.sorted().joined(separator: ","), valores: ["pregunta": "Ordena estas palabras como aparecerían en el diccionario."],
                       payload: .ordenar(payload),
                       explicacion: "Orden: \(ordenadas.joined(separator: ", ")). Se compara letra a letra; ch y ll no son letras aparte, la ñ va después de la n y las tildes no cuentan.",
                       erroresHabituales: errores, pistas: ["Compara las palabras letra a letra hasta la primera letra distinta."],
                       complejidad: Double(nivel) + Double(comun) * 0.05,
                       datos: ["orden": ordenadas.joined(separator: ";")])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
