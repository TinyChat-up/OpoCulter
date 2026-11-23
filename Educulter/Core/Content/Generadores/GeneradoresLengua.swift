import Foundation

// MARK: - Léxico y acentuación

/// Entrada del léxico (`Content/lexico/palabras.json`). La mínima es `{"palabra": "canción"}`:
/// el silabeo y la sílaba tónica se deducen. `tonica` (índice de sílaba desde el principio) solo
/// hace falta cuando las reglas no la deducen bien (agudas en -ns/-ts como «robots»).
/// Las palabras con tilde diacrítica se marcan con `diacritica` y quedan fuera de la comprobación.
struct EntradaLexico: Codable, Sendable, Equatable {
    var palabra: String
    var tonica: Int?
    var diacritica: Bool?
}

/// Clase de palabra según la posición de la sílaba tónica.
enum ClaseAcentual: String, Sendable, CaseIterable {
    case aguda, llana, esdrujula, sobresdrujula

    var nombre: String {
        switch self {
        case .aguda: "Aguda"
        case .llana: "Llana"
        case .esdrujula: "Esdrújula"
        case .sobresdrujula: "Sobresdrújula"
        }
    }
}

/// Análisis de una palabra: sílabas, tónica, clase y si la tilde escrita coincide con la que
/// predicen las reglas generales de acentuación de la RAE.
struct AnalisisPalabra: Sendable, Equatable {
    let palabra: String
    let silabas: [String]
    let tonica: Int
    let clase: ClaseAcentual?
    /// Índice (carácter) de la tilde escrita, si la tiene.
    let tildeEscrita: Int?
    /// Índice (carácter) donde las reglas generales ponen la tilde, o `nil` si no debe llevarla.
    let tildePredicha: Int?
    let motivo: String
    let hiato: Bool

    var coherente: Bool { tildeEscrita == tildePredicha }
    /// Palabra en minúsculas y sin tildes (para `colocarTilde`).
    var sinTilde: String { String(palabra.map { Acentuacion.quitarTilde[$0] ?? $0 }) }

    /// Nivel de dificultad (1–6) de la palabra para los generadores.
    var nivel: Int {
        let n = silabas.count
        if clase == .sobresdrujula || n >= 5 { return 6 }
        let final = palabra.last.map(String.init) ?? ""
        let penultima = palabra.count >= 2 ? Array(palabra)[palabra.count - 2] : " "
        let finalEspecial = (final == "s" || final == "n") && !Acentuacion.vocales.contains(penultima) || final == "y"
        if finalEspecial || (n >= 4 && clase != .esdrujula) { return 5 }
        if hiato { return 4 }
        if clase == .esdrujula { return 3 }
        if n >= 3 { return 2 }
        return 1
    }
}

enum Acentuacion {
    static let vocales: Set<Character> = ["a", "e", "i", "o", "u", "á", "é", "í", "ó", "ú", "ü"]
    static let abiertas: Set<Character> = ["a", "e", "o", "á", "é", "ó"]
    static let quitarTilde: [Character: Character] = ["á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u"]
    static let ponerTilde: [Character: Character] = ["a": "á", "e": "é", "i": "í", "o": "ó", "u": "ú"]

    /// Analiza una entrada del léxico (tal como está escrita, con su tilde si la lleva).
    static func analizar(_ e: EntradaLexico) -> AnalisisPalabra {
        let palabra = e.palabra.lowercased()
        let letras = Array(palabra)
        let rangos = Silabeo.silabas(palabra)
        let silabas = rangos.map { String(letras[$0]) }
        let escrita = letras.firstIndex { quitarTilde[$0] != nil }
        let tonica = e.tonica ?? Silabeo.silabaTonica(palabra, indiceTilde: escrita)
        let n = rangos.count
        let desdeFinal = n - 1 - tonica
        let clase: ClaseAcentual? = n < 2 ? nil : [ClaseAcentual.aguda, .llana, .esdrujula, .sobresdrujula][min(max(desdeFinal, 0), 3)]
        // Vocal tónica de la sílaba: la abierta si hay diptongo; con dos cerradas, la segunda.
        let rango = rangos.indices.contains(tonica) ? rangos[tonica] : 0..<0
        let vocalesSilaba = rango.filter { vocales.contains(letras[$0]) && !(letras[$0] == "u" && $0 > 0 && (letras[$0 - 1] == "q" || letras[$0 - 1] == "g")) }
        let conTilde = vocalesSilaba.first { quitarTilde[letras[$0]] != nil }
        let vocalTonica = conTilde ?? vocalesSilaba.first { abiertas.contains(letras[$0]) } ?? vocalesSilaba.last
        // Hiato con vocal cerrada tónica (í, ú) junto a una abierta: siempre lleva tilde.
        var hiato = false
        if let v = vocalTonica, "iuíú".contains(letras[v]), vocalesSilaba.count == 1 {
            let antes = v > 0 ? letras[v - 1] : nil, despues = v + 1 < letras.count ? letras[v + 1] : nil
            let tras = despues == "h" && v + 2 < letras.count ? letras[v + 2] : despues
            hiato = (antes.map { abiertas.contains($0) } ?? false) || (tras.map { abiertas.contains($0) } ?? false)
        }
        let ultima = letras.last ?? " "
        let penultima = letras.count >= 2 ? letras[letras.count - 2] : " "
        let terminaVocalNS = vocales.contains(ultima) || ((ultima == "n" || ultima == "s") && vocales.contains(penultima))
        let debe: Bool
        let motivo: String
        if n < 2 {
            debe = false; motivo = "monosílaba: no lleva tilde (salvo la diacrítica)"
        } else if hiato {
            debe = true; motivo = "hiato con vocal cerrada tónica: lleva tilde siempre"
        } else {
            switch clase {
            case .aguda: debe = terminaVocalNS; motivo = terminaVocalNS ? "aguda terminada en vocal, -n o -s: lleva tilde" : "aguda que no termina en vocal, -n ni -s (tras vocal): no lleva tilde"
            case .llana: debe = !terminaVocalNS; motivo = terminaVocalNS ? "llana terminada en vocal, -n o -s: no lleva tilde" : "llana que no termina en vocal, -n ni -s (tras vocal): lleva tilde"
            default: debe = true; motivo = "\(clase == .sobresdrujula ? "sobresdrújula" : "esdrújula"): lleva tilde siempre"
            }
        }
        return AnalisisPalabra(palabra: palabra, silabas: silabas, tonica: tonica, clase: clase, tildeEscrita: escrita,
                               tildePredicha: debe ? vocalTonica : nil, motivo: motivo, hiato: hiato)
    }

    /// Informe de coherencia del léxico: palabras cuya tilde escrita no coincide con la predicha
    /// por las reglas generales (las diacríticas se excluyen). No falla en silencio.
    static func informe(_ lexico: [EntradaLexico]) -> [String] {
        lexico.filter { $0.diacritica != true }.compactMap { e in
            let a = analizar(e)
            guard !a.coherente else { return nil }
            let esperado = a.tildePredicha.map { i in
                "«" + String(Array(a.sinTilde).enumerated().map { $0.offset == i ? (ponerTilde[$0.element] ?? $0.element) : $0.element }) + "»"
            } ?? "«\(a.sinTilde)» (sin tilde)"
            return "«\(e.palabra)»: sílabas \(a.silabas.joined(separator: "-")), tónica \(a.tonica + 1)ª; las reglas generales la escriben \(esperado) (\(a.motivo))."
        }
    }

    /// Palabras analizadas y válidas para generar (no diacríticas, coherentes y de 2+ sílabas).
    static func utilizables(_ lexico: [EntradaLexico]) -> [AnalisisPalabra] {
        lexico.filter { $0.diacritica != true }.map(analizar).filter { $0.coherente && $0.silabas.count >= 2 && $0.palabra.allSatisfy(\.isLetter) }
    }

    /// Palabras del nivel de la plantilla (o del nivel inferior más próximo con palabras).
    static func delNivel(_ lexico: [EntradaLexico], _ d: Int) -> [AnalisisPalabra] {
        let todas = utilizables(lexico)
        for nivel in stride(from: d, through: 1, by: -1) {
            let deNivel = todas.filter { $0.nivel == nivel }
            if !deNivel.isEmpty { return deNivel }
        }
        return todas
    }
}

private func complejidadPalabra(_ a: AnalisisPalabra) -> Double {
    Double(a.nivel) + Double(a.silabas.count) * 0.2
}

// MARK: - colocarTilde

/// Colocar (o no) la tilde en palabras del léxico. Dificultad: nivel de la palabra
/// (1 bisílabas regulares · 2 trisílabas · 3 esdrújulas · 4 hiatos · 5 finales especiales o
/// 4+ sílabas · 6 sobresdrújulas o 5+ sílabas).
struct GeneradorColocarTilde: GeneradorItems {
    let tipo = "colocarTilde"
    let mecanicas: Set<Mecanica> = [.colocarTilde]
    let marcadores: Set<String> = ["contexto"]

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let palabras = Acentuacion.delNivel(recursos.lexico, p.dificultad)
        guard !palabras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let a = rng.elemento(palabras)
        let tonica = a.silabas[a.tonica].uppercased()
        let separada = a.silabas.enumerated().map { $0.offset == a.tonica ? $0.element.uppercased() : $0.element }.joined(separator: "-")
        return Muestra(clave: a.palabra, valores: [:],
                       payload: .colocarTilde(Payload.ColocarTilde(palabra: a.sinTilde, indiceTilde: a.tildePredicha)),
                       explicacion: "\(separada): \(a.motivo).",
                       erroresHabituales: [
                        ErrorHabitual(respuesta: "sinTilde", feedback: "«\(a.palabra)» es \(a.clase?.nombre.lowercased() ?? "")\(a.hiato ? " con hiato" : ""): \(a.motivo)."),
                        ErrorHabitual(respuesta: "conTilde", feedback: "«\(a.palabra)»: \(a.motivo)."),
                        ErrorHabitual(respuesta: "posicion", feedback: "La sílaba tónica es «\(tonica)»: la tilde va en su vocal."),
                       ].filter { e in a.tildePredicha == nil ? e.respuesta == "conTilde" : e.respuesta != "conTilde" },
                       pistas: ["Busca la sílaba que suena más fuerte."],
                       complejidad: complejidadPalabra(a), datos: ["palabra": a.palabra])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(Acentuacion.delNivel(recursos.lexico, p.dificultad).map(\.palabra).prefix(limite))
    }
}

// MARK: - clasificarAcentuacion

/// Aguda, llana, esdrújula o sobresdrújula (elección). Las palabras se muestran bien escritas.
struct GeneradorClasificarAcentuacion: GeneradorItems {
    let tipo = "clasificarAcentuacion"
    let mecanicas: Set<Mecanica> = [.eleccion]
    let marcadores: Set<String> = ["palabra", "contexto"]

    static let feedback: [ClaseAcentual: String] = [
        .aguda: "Aguda es la que tiene la sílaba tónica en la última sílaba.",
        .llana: "Llana es la que tiene la sílaba tónica en la penúltima sílaba.",
        .esdrujula: "Esdrújula es la que tiene la sílaba tónica en la antepenúltima sílaba.",
        .sobresdrujula: "Sobresdrújula es la que tiene la sílaba tónica antes de la antepenúltima.",
    ]

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let palabras = Acentuacion.delNivel(recursos.lexico, p.dificultad).filter { $0.clase != nil }
        guard !palabras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let a = rng.elemento(palabras)
        let clase = a.clase!
        let incluirSobre = p.dificultad >= 5 || clase == .sobresdrujula
        let opciones: [ClaseAcentual] = incluirSobre ? ClaseAcentual.allCases : [.aguda, .llana, .esdrujula]
        let elementos = opciones.enumerated().map { ElementoTexto(id: String(UnicodeScalar(UInt8(97 + $0.offset))), texto: $0.element.nombre) }
        let correcta = elementos[opciones.firstIndex(of: clase)!].id
        let errores = opciones.enumerated().filter { $0.element != clase }.map { i, c in
            ErrorHabitual(respuesta: elementos[i].id, feedback: "\(Self.feedback[c]!) En «\(a.palabra)» la tónica es «\(a.silabas[a.tonica])» (\(a.silabas.joined(separator: "-"))).")
        }
        return Muestra(clave: a.palabra, valores: ["palabra": a.palabra],
                       payload: .eleccion(Payload.Eleccion(opciones: elementos, correcta: correcta)),
                       explicacion: "\(a.silabas.enumerated().map { $0.offset == a.tonica ? $0.element.uppercased() : $0.element }.joined(separator: "-")): \(clase.nombre.lowercased()).",
                       erroresHabituales: errores, pistas: ["Separa en sílabas y busca la que suena más fuerte."],
                       complejidad: complejidadPalabra(a), datos: ["palabra": a.palabra, "clase": clase.rawValue])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(Acentuacion.delNivel(recursos.lexico, p.dificultad).filter { $0.clase != nil }.map(\.palabra).prefix(limite))
    }
}

// MARK: - silabaTonica

/// Marcar la sílaba tónica (marcarTexto por sílabas). En la dificultad 1 la palabra puede llevar
/// tilde (que delata la tónica); desde la 2 solo se usan palabras sin tilde.
struct GeneradorSilabaTonica: GeneradorItems {
    let tipo = "silabaTonica"
    let mecanicas: Set<Mecanica> = [.marcarTexto]
    let marcadores: Set<String> = ["palabra", "contexto"]

    private func candidatas(_ p: Plantilla, _ lexico: [EntradaLexico]) -> [AnalisisPalabra] {
        let delNivel = Acentuacion.delNivel(lexico, p.dificultad)
        let sinTilde = delNivel.filter { $0.tildeEscrita == nil }
        return p.dificultad >= 2 && !sinTilde.isEmpty ? sinTilde : delNivel
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let palabras = candidatas(p, recursos.lexico)
        guard !palabras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let a = rng.elemento(palabras)
        let tokens = a.silabas.enumerated().map { ElementoTexto(id: "s\($0.offset + 1)", texto: $0.element) }
        return Muestra(clave: a.palabra, valores: ["palabra": a.palabra],
                       payload: .marcarTexto(Payload.MarcarTexto(unidad: .silaba, tokens: tokens, correctos: ["s\(a.tonica + 1)"])),
                       explicacion: "\(a.silabas.enumerated().map { $0.offset == a.tonica ? $0.element.uppercased() : $0.element }.joined(separator: "-")): la tónica es la \(a.tonica + 1)ª sílaba.",
                       erroresHabituales: tokens.enumerated().filter { $0.offset != a.tonica }.map { ErrorHabitual(respuesta: $0.element.id, feedback: "Pronuncia la palabra despacio: «\(a.silabas[a.tonica])» es la que suena más fuerte.") },
                       pistas: ["Pronuncia la palabra y escucha qué sílaba suena más fuerte."],
                       complejidad: complejidadPalabra(a) + (a.tildeEscrita == nil ? 0.5 : 0), datos: ["palabra": a.palabra, "tonica": "\(a.tonica)"])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(candidatas(p, recursos.lexico).map(\.palabra).prefix(limite))
    }
}
