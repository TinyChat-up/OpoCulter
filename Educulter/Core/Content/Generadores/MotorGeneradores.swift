import Foundation

/// Lo que produce un generador para una semilla: el caso concreto y todo lo que el motor necesita
/// para montar el ítem. La solución y los distractores los calcula siempre el código.
struct Muestra: Sendable, Equatable {
    /// Clave canónica del caso (sin redacción): dos muestras con la misma clave son la misma pregunta.
    var clave: String
    /// Valores de los marcadores `{{…}}` del enunciado y del contexto.
    var valores: [String: String]
    var payload: Payload
    var explicacion: String
    var erroresHabituales: [ErrorHabitual] = []
    /// Pistas propias del caso (solo se usan en peldaños 1–2; si hay pistas en la plantilla, mandan).
    var pistas: [String] = []
    /// Medida de complejidad del caso (pasos, magnitud de los números, cercanía de distractores…):
    /// el test de dificultad comprueba que su media crece con el nivel.
    var complejidad: Double
    /// Datos del caso para el oráculo independiente de los tests (no se muestran).
    var datos: [String: String] = [:]
    /// Ejemplo resuelto (05E parte 2 §5): pasos con sus resultados intermedios calculados.
    var pasos: [PasoResuelto] = []
    /// Actividad de juego (05G): «J46», «J63».
    var juego: String?
    /// Texto base que se puede abrir desde el ítem (05G, J46).
    var textoRef: String?
    /// Pregunta de origen (05H): la frase del banco en el hueco y en el Editor. Los ítems con el mismo
    /// origen comparten huella y no salen en la misma ronda.
    var origen: String?
}

/// Recursos de los generadores de Lengua (léxico, piezas de gramática, bancos de frases).
struct RecursosGeneradores: Sendable, Equatable {
    let lexico: [EntradaLexico]
    /// Formas verbales del léxico (para el nivel 6: formas verbales con hiato; lote 02).
    let formasVerbales: [String]
    var gramatica: PiezasGramatica
    var verbos: BancoVerbos
    var frases: BancoFrases
    /// Compatibilidad semántica de la gramática generativa (lote 02b, D-086).
    var compatibilidad: CompatibilidadGramatica
    /// Formas válidas que solo se distinguen por la tilde de una palabra del léxico (`ambiguas.json`, 05E §4.1).
    let ambiguas: PalabrasAmbiguas
    /// Palabras del léxico ambiguas sin contexto (término/termino/terminó): no se usan en los
    /// generadores de acentuación sin contexto.
    let palabrasAmbiguas: Set<String>
    /// Palabras utilizables del léxico, analizadas una sola vez, con su nivel (1–6), sin las ambiguas.
    let palabras: [PalabraNivelada]
    /// Base literaria del lote 05a (generador `literatura`, Fase 05E).
    var literatura: BaseLiteraria?
    /// Catálogo de errores típicos (05E parte 2 §4): etiqueta los distractores de cada muestra.
    var errores: CatalogoErrores
    /// J46 «De evidencia a resumen» (05G): datos de `resumen.json` y textos base por id.
    var resumen: BancoResumen?
    var textosBase: [String: TextoBase] = [:]
    /// Fase 05H: formación de palabras, recursos literarios y glosario (ANEXOS A y B).
    var formacion: BancoFormacion?
    var recursosLiterarios: BancoRecursos?
    var glosario: BancoGlosario?

    init(lexico: [EntradaLexico] = [], formasVerbales: [String] = [], gramatica: PiezasGramatica = PiezasGramatica(),
         verbos: BancoVerbos = BancoVerbos(), frases: BancoFrases = BancoFrases(),
         compatibilidad: CompatibilidadGramatica = CompatibilidadGramatica(), ambiguas: PalabrasAmbiguas = PalabrasAmbiguas(),
         literatura: BaseLiteraria? = nil, errores: CatalogoErrores = CatalogoErrores(),
         resumen: BancoResumen? = nil, textosBase: [TextoBase] = [],
         formacion: BancoFormacion? = nil, recursosLiterarios: BancoRecursos? = nil, glosario: BancoGlosario? = nil) {
        self.formacion = formacion
        self.recursosLiterarios = recursosLiterarios
        self.glosario = glosario
        self.resumen = resumen
        self.textosBase = Dictionary(textosBase.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        self.literatura = literatura
        self.errores = errores
        self.lexico = lexico
        self.formasVerbales = formasVerbales
        self.gramatica = gramatica
        self.verbos = verbos
        self.frases = frases
        self.compatibilidad = compatibilidad
        self.ambiguas = ambiguas
        let ambiguasLexico = Acentuacion.ambiguas(lexico.map(\.palabra), formasValidas: ambiguas.formas)
        self.palabrasAmbiguas = ambiguasLexico
        self.palabras = Acentuacion.nivelar(lexico, formasVerbales: Set(formasVerbales)).filter { !ambiguasLexico.contains($0.analisis.palabra) }
    }

    static let vacios = RecursosGeneradores()
}

/// Generador de código de un `tipo` de plantilla.
protocol GeneradorItems: Sendable {
    /// Nombre que usan las plantillas en `tipo`.
    var tipo: String { get }
    var mecanicas: Set<Mecanica> { get }
    /// Marcadores que el generador rellena (los enunciados y contextos solo pueden usar estos).
    var marcadores: Set<String> { get }
    /// Un caso para la semilla (`rng` ya está sembrado por el motor).
    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra
    /// Claves canónicas únicas del espacio finito de parámetros de la plantilla (hasta `limite`).
    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String]
    /// Variante que recibe además la semilla del ítem (J46: los pasos de una misma semilla comparten
    /// el texto aunque sean plantillas distintas). Por defecto, la de arriba.
    func muestra(_ p: Plantilla, semilla: UInt64, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra
}

extension GeneradorItems {
    func muestra(_ p: Plantilla, semilla: UInt64, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        try muestra(p, recursos: recursos, rng: &rng)
    }
}

enum ErrorGenerador: Error, Equatable, CustomStringConvertible {
    case tipoDesconocido(String)
    case mecanicaNoAdmitida(tipo: String, mecanica: Mecanica)
    case sinRecursos(String)
    case sinCaso(String)

    var description: String {
        switch self {
        case .tipoDesconocido(let t): "No hay generador para el tipo «\(t)»"
        case .mecanicaNoAdmitida(let t, let m): "El generador «\(t)» no admite la mecánica \(m.rawValue)"
        case .sinRecursos(let t): "Faltan recursos para el generador «\(t)»"
        case .sinCaso(let t): "El generador «\(t)» no encuentra un caso válido con estos parámetros"
        }
    }
}

/// Motor: `(plantilla, semilla) → Item`, determinista. El id del ítem es `<plantilla.id>#<semilla>`.
enum MotorGeneradores {
    static let generadores: [String: any GeneradorItems] = {
        let todos: [any GeneradorItems] = [
            GeneradorPorcentaje(), GeneradorConversionUnidades(), GeneradorFraccionBarras(), GeneradorOrdenarNumeros(),
            GeneradorRomanos(), GeneradorOperacionesCombinadas(), GeneradorMcmMcd(), GeneradorEstadistica(),
            GeneradorProbabilidad(), GeneradorEcuacionLineal(),
            // Lote 02 (D-077).
            GeneradorReglaDeTres(), GeneradorSexagesimal(), GeneradorEscala(), GeneradorFraccionesOperar(), GeneradorProblemaFraccion(),
            GeneradorColocarTilde(), GeneradorClasificarAcentuacion(), GeneradorSilabaTonica(),
            GeneradorOracionSimple(), GeneradorAnalisisVerbal(), GeneradorFraseHueco(),
            // Fase 05E.
            GeneradorFormasNoPersonales(), GeneradorLiteratura(),
            // Fase 05E parte 2 (D-100).
            GeneradorTerminoDesconocido(),
            // Fase 05G: juegos J46 y J63.
            GeneradorEvidenciaResumen(), GeneradorAreaCompuesta(),
            // Fase 05H: Editor, Fábrica de palabras, recursos literarios y glosario.
            GeneradorEditor(), GeneradorFormacion(), GeneradorRecursos(), GeneradorGlosario(),
        ]
        return Dictionary(uniqueKeysWithValues: todos.map { ($0.tipo, $0) })
    }()

    static let separadorSemilla: Character = "#"

    static func generador(_ tipo: String) -> (any GeneradorItems)? { generadores[tipo] }

    /// Generador sembrado de forma estable a partir del id de la plantilla y la semilla
    /// (FNV-1a sobre el id: no depende del `hashValue` aleatorio de Swift).
    static func rng(_ plantilla: Plantilla, semilla: UInt64) -> GeneradorConSemilla {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in plantilla.id.utf8 { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01B3 }
        return GeneradorConSemilla(semilla: h ^ (semilla &* 0x9E37_79B9_7F4A_7C15))
    }

    /// Muestra (caso) de una plantilla para una semilla.
    static func muestra(_ p: Plantilla, semilla: UInt64, recursos: RecursosGeneradores) throws -> Muestra {
        guard let g = generadores[p.tipo] else { throw ErrorGenerador.tipoDesconocido(p.tipo) }
        guard g.mecanicas.contains(p.mecanica) else { throw ErrorGenerador.mecanicaNoAdmitida(tipo: p.tipo, mecanica: p.mecanica) }
        var r = rng(p, semilla: semilla)
        var m = try g.muestra(p, semilla: semilla, recursos: recursos, rng: &r)
        m.erroresHabituales = recursos.errores.etiquetar(m.erroresHabituales, competencia: p.competencia, generador: p.tipo)
        return m
    }

    /// Genera el ítem `<plantilla.id>#<semilla>`.
    static func generar(_ p: Plantilla, semilla: UInt64, recursos: RecursosGeneradores) throws -> Item {
        try item(p, semilla: semilla, muestra: muestra(p, semilla: semilla, recursos: recursos))
    }

    /// Monta el ítem a partir de una muestra: elige redacción y contexto con la semilla.
    static func item(_ p: Plantilla, semilla: UInt64, muestra m: Muestra) -> Item {
        var r = rng(p, semilla: semilla ^ 0xA5A5_A5A5)
        var valores = m.valores
        if let contextos = p.contextos, !contextos.isEmpty {
            valores["contexto"] = Marcadores.rellenar(contextos[Int(r.next() % UInt64(contextos.count))], con: m.valores)
        }
        let redaccion = p.enunciados.isEmpty ? "" : p.enunciados[Int(r.next() % UInt64(p.enunciados.count))]
        let pistas = p.peldano >= Peldano.sinAyudas.rawValue ? [] : (p.pistas ?? m.pistas)
        return Item(id: "\(p.id)\(separadorSemilla)\(semilla)", competencia: p.competencia, peldano: p.peldano,
                    dificultad: p.dificultad, objetivo: p.objetivo ?? "Practicar \(p.tipo)",
                    enunciado: Marcadores.rellenar(redaccion, con: valores), payload: m.payload, pistas: pistas,
                    explicacion: m.explicacion, erroresHabituales: m.erroresHabituales,
                    procedencia: p.procedencia, validacion: p.validacion, version: p.version, textoRef: m.textoRef,
                    claveGenerada: "\(p.tipo)|\(m.clave)", pasos: m.pasos, juego: m.juego, origen: m.origen)
    }

    /// Copia de una plantilla con otra dificultad (y, opcionalmente, otro peldaño) para Supervivencia
    /// y los Retos de bloque (Fase 05D). Su id lleva el ajuste (`<id>@d5` o `<id>@d5p3`), así que
    /// los ítems generados (`<id>@d5p3#semilla`) se reproducen exactamente desde su id.
    static func ajustada(_ p: Plantilla, dificultad: Int, peldano: Int? = nil) -> Plantilla {
        var copia = p
        copia.dificultad = dificultad
        if let peldano { copia.peldano = peldano }
        copia.id = "\(p.id)@d\(dificultad)" + (peldano.map { "p\($0)" } ?? "")
        return copia
    }

    /// Separa `<id>@d5p3` en `(id, dificultad, peldaño)`.
    static func ajuste(de id: String) -> (base: String, dificultad: Int, peldano: Int?)? {
        guard let arroba = id.lastIndex(of: "@") else { return nil }
        let resto = id[id.index(after: arroba)...]
        guard resto.first == "d" else { return nil }
        let cuerpo = resto.dropFirst()
        let partes = cuerpo.split(separator: "p", maxSplits: 1)
        guard let d = partes.first.flatMap({ Int($0) }) else { return nil }
        let pel = partes.count > 1 ? Int(partes[1]) : nil
        if partes.count > 1 && pel == nil { return nil }
        return (String(id[..<arroba]), d, pel)
    }

    /// Separa un id generado en `(plantilla, semilla)`; `nil` si es un id de ítem estático.
    static func partes(de id: String) -> (plantilla: String, semilla: UInt64)? {
        guard let i = id.lastIndex(of: separadorSemilla), let s = UInt64(id[id.index(after: i)...]) else { return nil }
        return (String(id[..<i]), s)
    }

    /// Hasta `cantidad` ítems con claves distintas a partir de `semillaBase` (variantes de una plantilla).
    static func variantes(_ p: Plantilla, cantidad: Int, semillaBase: UInt64, recursos: RecursosGeneradores) -> [Item] {
        var vistos = Set<String>()
        var items: [Item] = []
        var k: UInt64 = 0
        while items.count < cantidad && k < UInt64(cantidad * 8) {
            let semilla = semillaBase &+ k
            k += 1
            guard let m = try? muestra(p, semilla: semilla, recursos: recursos), vistos.insert(m.clave).inserted else { continue }
            items.append(item(p, semilla: semilla, muestra: m))
        }
        return items
    }
}

// MARK: - Utilidades comunes de los generadores

extension GeneradorConSemilla {
    /// Entero uniforme en el rango cerrado.
    mutating func entero(_ r: ClosedRange<Int>) -> Int { Int.random(in: r, using: &self) }
    mutating func elemento<T>(_ a: [T]) -> T { a[Int.random(in: 0..<a.count, using: &self)] }
    mutating func barajar<T>(_ a: [T]) -> [T] { a.shuffled(using: &self) }
    mutating func probabilidad(_ p: Double) -> Bool { Double.random(in: 0..<1, using: &self) < p }
}

enum FormatoNumero {
    /// Número racional como texto español: entero, decimal exacto con coma o fracción.
    static func numero(_ r: Racional) -> String {
        if r.denominador == 1 { return "\(r.numerador)" }
        if let d = decimal(r) { return d }
        return "\(r.numerador)/\(r.denominador)"
    }

    /// Decimal exacto con coma si el denominador solo tiene factores 2 y 5 (hasta 6 decimales).
    static func decimal(_ r: Racional) -> String? {
        var d = r.denominador, dos = 0, cinco = 0
        while d % 2 == 0 { d /= 2; dos += 1 }
        while d % 5 == 0 { d /= 5; cinco += 1 }
        guard d == 1 else { return nil }
        let cifras = max(dos, cinco)
        guard cifras <= 6 else { return nil }
        var escala = 1
        for _ in 0..<cifras { escala *= 10 }
        let total = r.numerador * (escala / r.denominador)
        let entero = abs(total) / escala, resto = abs(total) % escala
        var dec = String(resto)
        while dec.count < cifras { dec = "0" + dec }
        while dec.hasSuffix("0") { dec.removeLast() }
        let signo = total < 0 ? "-" : ""
        return dec.isEmpty ? "\(signo)\(entero)" : "\(signo)\(entero),\(dec)"
    }

    /// Entero con separador de miles español (punto) a partir de 10 000 (RAE: 4 cifras sin punto).
    static func miles(_ n: Int) -> String {
        let s = String(abs(n))
        guard s.count > 4 else { return n < 0 ? "-\(s)" : s }
        var out = ""
        for (i, c) in s.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { out.append(".") }
            out.append(c)
        }
        return (n < 0 ? "-" : "") + String(out.reversed())
    }
}

extension Racional {
    static func entero(_ n: Int) -> Racional { Racional(numerador: n, denominador: 1)! }
    static func + (a: Racional, b: Racional) -> Racional { Racional(numerador: a.numerador * b.denominador + b.numerador * a.denominador, denominador: a.denominador * b.denominador)! }
    static func - (a: Racional, b: Racional) -> Racional { Racional(numerador: a.numerador * b.denominador - b.numerador * a.denominador, denominador: a.denominador * b.denominador)! }
    static func * (a: Racional, b: Racional) -> Racional { Racional(numerador: a.numerador * b.numerador, denominador: a.denominador * b.denominador)! }
    static func / (a: Racional, b: Racional) -> Racional? { Racional(numerador: a.numerador * b.denominador, denominador: a.denominador * b.numerador) }
    var esEntero: Bool { denominador == 1 }
}

/// Opciones de elección a partir de la correcta y de distractores con su regla de error:
/// sin duplicados ni iguales a la correcta, barajadas con la semilla. Cada distractor lleva su
/// error habitual con el feedback de la regla que lo produce.
enum Opciones {
    static func eleccion(correcta: String, distractores: [(texto: String, feedback: String)], maximo: Int = 4,
                         rng: inout GeneradorConSemilla) -> (Payload.Eleccion, [ErrorHabitual]) {
        var vistos: Set<String> = [correcta]
        var elegidos: [(texto: String, feedback: String)] = []
        for d in distractores where !d.texto.isEmpty && vistos.insert(d.texto).inserted && elegidos.count < maximo - 1 {
            elegidos.append(d)
        }
        var opciones = [(id: "", texto: correcta, feedback: "")] + elegidos.map { (id: "", texto: $0.texto, feedback: $0.feedback) }
        opciones = rng.barajar(opciones)
        var elementos: [ElementoTexto] = []
        var errores: [ErrorHabitual] = []
        var idCorrecta = ""
        for (i, o) in opciones.enumerated() {
            let id = String(UnicodeScalar(UInt8(97 + i)))
            elementos.append(ElementoTexto(id: id, texto: o.texto))
            if o.texto == correcta { idCorrecta = id } else { errores.append(ErrorHabitual(respuesta: id, feedback: o.feedback)) }
        }
        return (Payload.Eleccion(opciones: elementos, correcta: idCorrecta), errores)
    }
}
