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
            // La h intercalada no impide el hiato, ni detrás (búho) ni delante (prohíbe, ahínco, rehúso).
            let antes = v > 0 ? letras[v - 1] : nil, despues = v + 1 < letras.count ? letras[v + 1] : nil
            let previa = antes == "h" && v >= 2 ? letras[v - 2] : antes
            let tras = despues == "h" && v + 2 < letras.count ? letras[v + 2] : despues
            hiato = (previa.map { abiertas.contains($0) } ?? false) || (tras.map { abiertas.contains($0) } ?? false)
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

    /// Nivel de cada palabra utilizable (lote 02, D):
    /// 1 · dos sílabas y regla general · 2 · tres o más sílabas · 3 · hiato ·
    /// 4 · plural que cambia la tilde (canción → canciones, examen → exámenes) ·
    /// 5 · excepciones (-s tras consonante; plural que desplaza el acento: carácter → caracteres) ·
    /// 6 · formas verbales con hiato y sobresdrújulas.
    static func nivelar(_ lexico: [EntradaLexico], formasVerbales: Set<String>) -> [PalabraNivelada] {
        let todas = utilizables(lexico)
        let porForma = Dictionary(todas.map { ($0.sinTilde, $0) }, uniquingKeysWith: { a, _ in a })
        return todas.map { a in
            PalabraNivelada(analisis: a, nivel: nivel(a, singular: singular(a, porForma), verbo: formasVerbales.contains(a.palabra)))
        }
    }

    /// Singular del léxico de un plural en -es (lápices → lápiz).
    static func singular(_ a: AnalisisPalabra, _ porForma: [String: AnalisisPalabra]) -> AnalisisPalabra? {
        let s = a.sinTilde
        guard s.hasSuffix("es"), s.count > 4 else { return nil }
        let raiz = String(s.dropLast(2))
        return ([raiz] + (raiz.hasSuffix("c") ? [String(raiz.dropLast()) + "z"] : [])).compactMap { porForma[$0] }.first
    }

    static func nivel(_ a: AnalisisPalabra, singular: AnalisisPalabra?, verbo: Bool) -> Int {
        if a.clase == .sobresdrujula || (verbo && a.hiato) { return 6 }
        let letras = Array(a.palabra)
        let sTrasConsonante = letras.last == "s" && letras.count >= 2 && !vocales.contains(letras[letras.count - 2])
        if sTrasConsonante { return 5 }
        if let s = singular, s.tonica != a.tonica { return 5 }
        if let s = singular, (s.tildeEscrita != nil) != (a.tildeEscrita != nil) { return 4 }
        if a.hiato { return 3 }
        return a.silabas.count >= 3 ? 2 : 1
    }

    /// Palabras del nivel pedido (o del nivel inferior más próximo con palabras).
    static func delNivel(_ recursos: RecursosGeneradores, _ d: Int) -> [AnalisisPalabra] {
        for nivel in stride(from: d, through: 1, by: -1) {
            let deNivel = recursos.palabras.filter { $0.nivel == nivel }.map(\.analisis)
            if !deNivel.isEmpty { return deNivel }
        }
        return recursos.palabras.map(\.analisis)
    }

    static func nivelDe(_ palabra: String, _ recursos: RecursosGeneradores) -> Int { recursos.palabras.first { $0.analisis.palabra == palabra }?.nivel ?? 1 }
}

/// Palabra utilizable con su nivel de dificultad.
struct PalabraNivelada: Sendable, Equatable {
    let analisis: AnalisisPalabra
    let nivel: Int
}

private func complejidadPalabra(_ a: AnalisisPalabra, _ r: RecursosGeneradores) -> Double {
    Double(Acentuacion.nivelDe(a.palabra, r)) + Double(a.silabas.count) * 0.2
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
        let palabras = Acentuacion.delNivel(recursos, p.dificultad)
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
                       complejidad: complejidadPalabra(a, recursos), datos: ["palabra": a.palabra])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(Acentuacion.delNivel(recursos, p.dificultad).map(\.palabra).prefix(limite))
    }
}

// MARK: - clasificarAcentuacion

/// Aguda, llana, esdrújula o sobresdrújula (elección). Las palabras se muestran bien escritas.
struct GeneradorClasificarAcentuacion: GeneradorItems {
    let tipo = "clasificarAcentuacion"
    let mecanicas: Set<Mecanica> = [.clasificar]
    let marcadores: Set<String> = ["palabra", "contexto"]

    static let feedback: [ClaseAcentual: String] = [
        .aguda: "Aguda es la que tiene la sílaba tónica en la última sílaba.",
        .llana: "Llana es la que tiene la sílaba tónica en la penúltima sílaba.",
        .esdrujula: "Esdrújula es la que tiene la sílaba tónica en la antepenúltima sílaba.",
        .sobresdrujula: "Sobresdrújula es la que tiene la sílaba tónica antes de la antepenúltima.",
    ]

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let palabras = Acentuacion.delNivel(recursos, p.dificultad).filter { $0.clase != nil }
        guard !palabras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        if p.mecanica == .clasificar { return try clasificar(p, palabras, recursos: recursos, rng: &rng) }
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
                       complejidad: complejidadPalabra(a, recursos), datos: ["palabra": a.palabra, "clase": clase.rawValue])
    }

    /// Clasificar de 4 a 6 palabras (lote 02): clases mezcladas, con palabras del nivel y de los
    /// inferiores para que haya al menos dos clases.
    private func clasificar(_ p: Plantilla, _ delNivel: [AnalisisPalabra], recursos: RecursosGeneradores,
                            rng: inout GeneradorConSemilla) throws -> Muestra {
        let todas = recursos.palabras.filter { $0.nivel <= p.dificultad && $0.analisis.clase != nil }.map(\.analisis)
        for _ in 0..<200 {
            let n = rng.entero(4...6)
            let base = rng.elemento(delNivel)
            var elegidas = [base]
            for a in rng.barajar(todas) where elegidas.count < n && !elegidas.contains(where: { $0.palabra == a.palabra }) { elegidas.append(a) }
            let clases = Set(elegidas.compactMap(\.clase))
            guard elegidas.count == n, clases.count >= 2 else { continue }
            var categorias: [ClaseAcentual] = [.aguda, .llana, .esdrujula]
            if clases.contains(.sobresdrujula) { categorias.append(.sobresdrujula) }
            let fichas = elegidas.enumerated().map { Payload.Clasificar.Ficha(id: "w\($0.offset + 1)", texto: $0.element.palabra, categoria: $0.element.clase!.rawValue) }
            let errores = elegidas.enumerated().map { i, a in
                ErrorHabitual(respuesta: "w\(i + 1)", feedback: "«\(a.palabra)» (\(a.silabas.enumerated().map { $0.offset == a.tonica ? $0.element.uppercased() : $0.element }.joined(separator: "-"))) es \(a.clase!.nombre.lowercased()): \(Self.feedback[a.clase!]!)")
            }
            let complejidad = elegidas.map { Double(Acentuacion.nivelDe($0.palabra, recursos)) }.reduce(0, +) / Double(n) + Double(n) * 0.2 + Double(clases.count) * 0.3
            return Muestra(clave: elegidas.map(\.palabra).sorted().joined(separator: ","), valores: [:],
                           payload: .clasificar(Payload.Clasificar(categorias: categorias.map { ElementoNombre(id: $0.rawValue, nombre: $0.nombre) }, fichas: fichas)),
                           explicacion: elegidas.map { "\($0.palabra): \($0.clase!.nombre.lowercased())" }.joined(separator: "; ") + ".",
                           erroresHabituales: errores, pistas: ["Separa en sílabas y busca la que suena más fuerte."],
                           complejidad: complejidad,
                           datos: ["palabras": elegidas.map(\.palabra).joined(separator: ","), "clases": elegidas.map { $0.clase!.rawValue }.joined(separator: ",")])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        if p.mecanica == .clasificar {
            var vistos = Set<String>()
            for semilla in UInt64(0)..<UInt64(min(limite, 3000)) { if let m = try? MotorGeneradores.muestra(p, semilla: semilla, recursos: recursos) { vistos.insert(m.clave) } }
            return Array(vistos)
        }
        return Array(Acentuacion.delNivel(recursos, p.dificultad).filter { $0.clase != nil }.map(\.palabra).prefix(limite))
    }
}

// MARK: - silabaTonica

/// Marcar la sílaba tónica (marcarTexto por sílabas). En la dificultad 1 la palabra puede llevar
/// tilde (que delata la tónica); desde la 2 solo se usan palabras sin tilde.
struct GeneradorSilabaTonica: GeneradorItems {
    let tipo = "silabaTonica"
    let mecanicas: Set<Mecanica> = [.marcarTexto]
    let marcadores: Set<String> = ["palabra", "contexto"]

    private func candidatas(_ p: Plantilla, _ recursos: RecursosGeneradores) -> [AnalisisPalabra] {
        let delNivel = Acentuacion.delNivel(recursos, p.dificultad)
        let sinTilde = delNivel.filter { $0.tildeEscrita == nil }
        return p.dificultad >= 2 && !sinTilde.isEmpty ? sinTilde : delNivel
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let palabras = candidatas(p, recursos)
        guard !palabras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let a = rng.elemento(palabras)
        let tokens = a.silabas.enumerated().map { ElementoTexto(id: "s\($0.offset + 1)", texto: $0.element) }
        return Muestra(clave: a.palabra, valores: ["palabra": a.palabra],
                       payload: .marcarTexto(Payload.MarcarTexto(unidad: .silaba, tokens: tokens, correctos: ["s\(a.tonica + 1)"])),
                       explicacion: "\(a.silabas.enumerated().map { $0.offset == a.tonica ? $0.element.uppercased() : $0.element }.joined(separator: "-")): la tónica es la \(a.tonica + 1)ª sílaba.",
                       erroresHabituales: tokens.enumerated().filter { $0.offset != a.tonica }.map { ErrorHabitual(respuesta: $0.element.id, feedback: "Pronuncia la palabra despacio: «\(a.silabas[a.tonica])» es la que suena más fuerte.") },
                       pistas: ["Pronuncia la palabra y escucha qué sílaba suena más fuerte."],
                       complejidad: complejidadPalabra(a, recursos) + (a.tildeEscrita == nil ? 0.5 : 0), datos: ["palabra": a.palabra, "tonica": "\(a.tonica)"])
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        Array(candidatas(p, recursos).map(\.palabra).prefix(limite))
    }
}
