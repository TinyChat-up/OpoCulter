import Foundation

/// Mecánicas de interacción del MVP. Ninguna usa el teclado del sistema.
enum Mecanica: String, Codable, Sendable, CaseIterable {
    case eleccion
    case verdaderoFalso
    case clasificar
    case ordenar
    case emparejar
    case marcarTexto
    case segmentar
    case ruedas
    case construir
    case numerico
    /// Colocar (o no) la tilde en una palabra (Fase 05B).
    case colocarTilde
    /// Representar una fracción coloreando una barra dividida (Fase 05B).
    case fraccionBarras
}

/// Peldaños de la escalera de dominio.
enum Peldano: Int, Codable, Sendable, CaseIterable, Comparable {
    case descubre = 1
    case practica = 2
    case sinAyudas = 3
    case justifica = 4
    case formatoExamen = 5

    static func < (a: Peldano, b: Peldano) -> Bool { a.rawValue < b.rawValue }

    /// Nombre visible del peldaño (05E parte 2 §3.5). Solo cambian las etiquetas; la lógica de la
    /// escalera es la misma.
    var nombre: String {
        switch self {
        case .descubre: "Descubrir"
        case .practica: "Practicar"
        case .sinAyudas: "Resolver"
        case .justifica: "Transferir"
        case .formatoExamen: "Dominar"
        }
    }

    /// Nombre del peldaño `n` (1…5; fuera de rango, el más cercano).
    static func nombre(_ n: Int) -> String { (Peldano(rawValue: min(max(n, 1), 5)) ?? .descubre).nombre }
}

/// Ejercicio del banco de contenido (`Content/items/<bloque>.json`).
struct Item: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var competencia: String
    /// 1 Descubre … 5 Formato examen. Se guarda como entero para que el validador
    /// pueda informar de valores fuera de rango en lugar de fallar al decodificar.
    var peldano: Int
    var dificultad: Int
    var objetivo: String
    var enunciado: String
    var payload: Payload
    var pistas: [String]
    var explicacion: String
    var erroresHabituales: [ErrorHabitual]
    var referencia: Referencia?
    var procedencia: Procedencia
    var validacion: Validacion
    var version: Int
    /// Id del texto base que se muestra junto al enunciado (comprensión, lote 03a, D-085).
    var textoRef: String?
    /// `tipo|clave` del caso para los ítems generados (D-087): dos ítems con la misma clave son la
    /// misma pregunta aunque cambie la semilla o la plantilla. `nil` en los estáticos.
    var claveGenerada: String?

    var mecanica: Mecanica { payload.mecanica }

    init(
        id: String, competencia: String, peldano: Int, dificultad: Int, objetivo: String,
        enunciado: String, payload: Payload, pistas: [String] = [], explicacion: String,
        erroresHabituales: [ErrorHabitual] = [], referencia: Referencia? = nil,
        procedencia: Procedencia, validacion: Validacion, version: Int = 1, textoRef: String? = nil,
        claveGenerada: String? = nil
    ) {
        self.id = id
        self.competencia = competencia
        self.peldano = peldano
        self.dificultad = dificultad
        self.objetivo = objetivo
        self.enunciado = enunciado
        self.payload = payload
        self.pistas = pistas
        self.explicacion = explicacion
        self.erroresHabituales = erroresHabituales
        self.referencia = referencia
        self.procedencia = procedencia
        self.validacion = validacion
        self.version = version
        self.textoRef = textoRef
        self.claveGenerada = claveGenerada
    }

    private enum CodingKeys: String, CodingKey {
        case id, competencia, peldano, dificultad, objetivo, mecanica, enunciado, payload,
             pistas, explicacion, erroresHabituales, referencia, procedencia, validacion, version, textoRef, claveGenerada
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        competencia = try c.decode(String.self, forKey: .competencia)
        peldano = try c.decode(Int.self, forKey: .peldano)
        dificultad = try c.decode(Int.self, forKey: .dificultad)
        objetivo = try c.decode(String.self, forKey: .objetivo)
        enunciado = try c.decode(String.self, forKey: .enunciado)
        let mecanica = try c.decode(Mecanica.self, forKey: .mecanica)
        payload = try Payload.decodificar(mecanica: mecanica, de: c.superDecoder(forKey: .payload))
        pistas = try c.decodeIfPresent([String].self, forKey: .pistas) ?? []
        explicacion = try c.decode(String.self, forKey: .explicacion)
        erroresHabituales = try c.decodeIfPresent([ErrorHabitual].self, forKey: .erroresHabituales) ?? []
        referencia = try c.decodeIfPresent(Referencia.self, forKey: .referencia)
        procedencia = try c.decode(Procedencia.self, forKey: .procedencia)
        validacion = try c.decode(Validacion.self, forKey: .validacion)
        version = try c.decode(Int.self, forKey: .version)
        textoRef = try c.decodeIfPresent(String.self, forKey: .textoRef)
        claveGenerada = try c.decodeIfPresent(String.self, forKey: .claveGenerada)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(competencia, forKey: .competencia)
        try c.encode(peldano, forKey: .peldano)
        try c.encode(dificultad, forKey: .dificultad)
        try c.encode(objetivo, forKey: .objetivo)
        try c.encode(mecanica, forKey: .mecanica)
        try c.encode(enunciado, forKey: .enunciado)
        try payload.codificar(en: c.superEncoder(forKey: .payload))
        try c.encode(pistas, forKey: .pistas)
        try c.encode(explicacion, forKey: .explicacion)
        try c.encode(erroresHabituales, forKey: .erroresHabituales)
        try c.encodeIfPresent(referencia, forKey: .referencia)
        try c.encode(procedencia, forKey: .procedencia)
        try c.encode(validacion, forKey: .validacion)
        try c.encode(version, forKey: .version)
        try c.encodeIfPresent(textoRef, forKey: .textoRef)
        try c.encodeIfPresent(claveGenerada, forKey: .claveGenerada)
    }
}

// MARK: - Payload por mecánica

/// Elemento con id y texto (opciones, fichas, tokens, piezas…).
struct ElementoTexto: Codable, Sendable, Equatable, Hashable {
    var id: String
    var texto: String
}

/// Elemento con id y nombre (categorías, etiquetas).
struct ElementoNombre: Codable, Sendable, Equatable, Hashable {
    var id: String
    var nombre: String
}

/// Datos específicos de cada mecánica.
enum Payload: Sendable, Equatable {
    case eleccion(Eleccion)
    case verdaderoFalso(VerdaderoFalso)
    case clasificar(Clasificar)
    case ordenar(Ordenar)
    case emparejar(Emparejar)
    case marcarTexto(MarcarTexto)
    case segmentar(Segmentar)
    case ruedas(Ruedas)
    case construir(Construir)
    case numerico(Numerico)
    case colocarTilde(ColocarTilde)
    case fraccionBarras(FraccionBarras)

    var mecanica: Mecanica {
        switch self {
        case .eleccion: .eleccion
        case .verdaderoFalso: .verdaderoFalso
        case .clasificar: .clasificar
        case .ordenar: .ordenar
        case .emparejar: .emparejar
        case .marcarTexto: .marcarTexto
        case .segmentar: .segmentar
        case .ruedas: .ruedas
        case .construir: .construir
        case .numerico: .numerico
        case .colocarTilde: .colocarTilde
        case .fraccionBarras: .fraccionBarras
        }
    }

    struct Eleccion: Codable, Sendable, Equatable {
        var opciones: [ElementoTexto]
        var correcta: String
    }

    struct VerdaderoFalso: Codable, Sendable, Equatable {
        var afirmacion: String
        var esVerdadera: Bool
    }

    struct Clasificar: Codable, Sendable, Equatable {
        struct Ficha: Codable, Sendable, Equatable {
            var id: String
            var texto: String
            var categoria: String
        }
        var categorias: [ElementoNombre]
        var fichas: [Ficha]
    }

    struct Ordenar: Codable, Sendable, Equatable {
        var fichas: [ElementoTexto]
        var ordenCorrecto: [String]
        var etiquetaInicio: String?
        var etiquetaFin: String?
    }

    struct Emparejar: Codable, Sendable, Equatable {
        var izquierda: [ElementoTexto]
        var derecha: [ElementoTexto]
        /// Cada par es `[idIzquierda, idDerecha]`.
        var pares: [[String]]
    }

    struct MarcarTexto: Codable, Sendable, Equatable {
        enum Unidad: String, Codable, Sendable {
            case palabra, silaba
        }
        var unidad: Unidad
        var tokens: [ElementoTexto]
        var correctos: [String]
    }

    struct Segmentar: Codable, Sendable, Equatable {
        struct Segmento: Codable, Sendable, Equatable {
            var id: String
            var desde: String
            var hasta: String
            var etiqueta: String
            var padre: String?
        }
        var tokens: [ElementoTexto]
        var etiquetas: [ElementoNombre]
        var segmentos: [Segmento]
    }

    struct Ruedas: Codable, Sendable, Equatable {
        struct Rueda: Codable, Sendable, Equatable {
            var id: String
            var nombre: String
            var opciones: [String]
            var correcta: String
        }
        var ruedas: [Rueda]
    }

    struct Construir: Codable, Sendable, Equatable {
        struct Hueco: Codable, Sendable, Equatable {
            var id: String
            var correcta: String
        }
        var plantilla: String
        var huecos: [Hueco]
        var piezas: [ElementoTexto]

        /// Ids de hueco que aparecen en la plantilla como `{id}`, en orden de aparición.
        var huecosEnPlantilla: [String] {
            var resultado: [String] = []
            var resto = Substring(plantilla)
            while let abre = resto.firstIndex(of: "{") {
                let tras = resto[resto.index(after: abre)...]
                guard let cierra = tras.firstIndex(of: "}") else { break }
                resultado.append(String(tras[..<cierra]))
                resto = tras[tras.index(after: cierra)...]
            }
            return resultado
        }
    }

    struct Numerico: Codable, Sendable, Equatable {
        enum Formato: String, Codable, Sendable {
            case entero, decimal, fraccion
        }
        /// Respuesta correcta como texto, con coma decimal (`"573,75"`, `"3/4"`).
        var respuesta: String
        var formato: Formato
        /// Tolerancia absoluta (0 = exacta).
        var tolerancia: Double?
        var unidad: String?
        /// Extensión v1 (opcional): si es `true`, una fracción solo es correcta en forma irreducible.
        var exigeIrreducible: Bool?
    }

    /// `palabra` en minúsculas y sin tildes; `indiceTilde` es el índice (base 0) del carácter
    /// vocal que lleva la tilde, o `nil` si la palabra no la lleva.
    struct ColocarTilde: Codable, Sendable, Equatable {
        var palabra: String
        var indiceTilde: Int?

        static let vocales: Set<Character> = ["a", "e", "i", "o", "u"]
        static let conTilde: [Character: Character] = ["a": "á", "e": "é", "i": "í", "o": "ó", "u": "ú"]

        var letras: [Character] { Array(palabra) }

        /// La palabra escrita con la tilde en `indice` (o sin tilde si es `nil`).
        func escrita(conTildeEn indice: Int?) -> String {
            var l = letras
            if let i = indice, l.indices.contains(i), let c = Self.conTilde[l[i]] { l[i] = c }
            return String(l)
        }

        /// Forma correcta de la palabra.
        var correcta: String { escrita(conTildeEn: indiceTilde) }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(palabra, forKey: .palabra)
            try c.encode(indiceTilde, forKey: .indiceTilde)
        }
    }

    /// Barra que se colorea para representar `objetivo` (`"n/d"`).
    struct FraccionBarras: Codable, Sendable, Equatable {
        enum Modo: String, Codable, Sendable {
            /// La barra viene dividida en `partes`; solo se colorea.
            case colorear
            /// El usuario elige primero en cuántas partes dividir (2–12) y después colorea.
            case dividirYColorear
        }
        static let rangoPartes = 2...12

        var modo: Modo
        var partes: Int?
        var objetivo: String
        var aceptarEquivalentes: Bool
        var particionesPermitidas: [Int]?

        /// Numerador y denominador tal como están escritos en `objetivo` (sin simplificar).
        var fraccionObjetivo: (numerador: Int, denominador: Int)? {
            let trozos = objetivo.split(separator: "/", omittingEmptySubsequences: false)
            guard trozos.count == 2, let n = Int(trozos[0]), let d = Int(trozos[1]), d > 0 else { return nil }
            return (n, d)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(modo, forKey: .modo)
            try c.encode(partes, forKey: .partes)
            try c.encode(objetivo, forKey: .objetivo)
            try c.encode(aceptarEquivalentes, forKey: .aceptarEquivalentes)
            try c.encodeIfPresent(particionesPermitidas, forKey: .particionesPermitidas)
        }
    }

    static func decodificar(mecanica: Mecanica, de decoder: Decoder) throws -> Payload {
        switch mecanica {
        case .eleccion: .eleccion(try Eleccion(from: decoder))
        case .verdaderoFalso: .verdaderoFalso(try VerdaderoFalso(from: decoder))
        case .clasificar: .clasificar(try Clasificar(from: decoder))
        case .ordenar: .ordenar(try Ordenar(from: decoder))
        case .emparejar: .emparejar(try Emparejar(from: decoder))
        case .marcarTexto: .marcarTexto(try MarcarTexto(from: decoder))
        case .segmentar: .segmentar(try Segmentar(from: decoder))
        case .ruedas: .ruedas(try Ruedas(from: decoder))
        case .construir: .construir(try Construir(from: decoder))
        case .numerico: .numerico(try Numerico(from: decoder))
        case .colocarTilde: .colocarTilde(try ColocarTilde(from: decoder))
        case .fraccionBarras: .fraccionBarras(try FraccionBarras(from: decoder))
        }
    }

    func codificar(en encoder: Encoder) throws {
        switch self {
        case .eleccion(let p): try p.encode(to: encoder)
        case .verdaderoFalso(let p): try p.encode(to: encoder)
        case .clasificar(let p): try p.encode(to: encoder)
        case .ordenar(let p): try p.encode(to: encoder)
        case .emparejar(let p): try p.encode(to: encoder)
        case .marcarTexto(let p): try p.encode(to: encoder)
        case .segmentar(let p): try p.encode(to: encoder)
        case .ruedas(let p): try p.encode(to: encoder)
        case .construir(let p): try p.encode(to: encoder)
        case .numerico(let p): try p.encode(to: encoder)
        case .colocarTilde(let p): try p.encode(to: encoder)
        case .fraccionBarras(let p): try p.encode(to: encoder)
        }
    }
}
