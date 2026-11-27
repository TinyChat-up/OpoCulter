import Foundation

/// Datos de J46 «De evidencia a resumen» (`Content/resumen.json`, ANEXO A de la 05G, redactados y
/// aprobados por la dirección).
struct BancoResumen: Codable, Sendable, Equatable {
    struct Tema: Codable, Sendable, Equatable {
        var correcta: String
        var concreto: String
        var amplio: String
    }

    struct Entrada: Codable, Sendable, Equatable {
        var texto: String
        var central: [String]
        var detalle: [String]
        var tema: Tema
        var modelo: String
        var criterios: [String]
    }

    var version: Int
    var actividad: String
    var validacion: Validacion
    var textos: [Entrada]
}

/// Generador de J46 (Fase 05G §4, D-118). Cada plantilla es un paso (`parametros.paso`: `evidencia`,
/// `tema` o `resumen`); la semilla elige el texto, así que los tres pasos de una misma semilla son
/// la misma actividad y la variante sin ayudas usa otra semilla (otro texto).
struct GeneradorEvidenciaResumen: GeneradorItems {
    let tipo = "evidenciaResumen"
    let mecanicas: Set<Mecanica> = [.evidencia, .eleccion, .recuerdo]
    let marcadores: Set<String> = ["titulo", "contexto"]

    static let pistaDetalle = "Ese dato apoya una idea más amplia. ¿Por qué se cuenta?"
    static let pistaOtro = "Busca la frase que explica de qué trata todo el texto o por qué importa."
    static let pistaConcreto = "Ese tema es demasiado concreto: solo cubre una parte del texto."
    static let pistaAmplio = "Ese tema es demasiado amplio: serviría para muchos textos distintos."

    /// Texto y datos de la semilla (o `nil` si faltan los recursos).
    static func caso(_ semilla: Int, recursos: RecursosGeneradores) -> (BancoResumen.Entrada, TextoBase)? {
        guard let banco = recursos.resumen, !banco.textos.isEmpty else { return nil }
        let e = banco.textos[((semilla % banco.textos.count) + banco.textos.count) % banco.textos.count]
        guard let t = recursos.textosBase[e.texto] else { return nil }
        return (e, t)
    }

    /// Sin semilla (no lo usa el motor): un texto al azar.
    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        try muestra(p, indice: rng.entero(0...999), recursos: recursos, rng: &rng)
    }

    /// La semilla del ítem elige el texto: los tres pasos de una misma semilla son la misma actividad.
    func muestra(_ p: Plantilla, semilla: UInt64, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        try muestra(p, indice: Int(semilla % 1_000_003), recursos: recursos, rng: &rng)
    }

    /// Muestra de un paso para el índice de texto `k`.
    func muestra(_ p: Plantilla, indice k: Int, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let paso = p.textos("paso", porDefecto: ["evidencia"]).first ?? "evidencia"
        guard let (e, t) = Self.caso(k, recursos: recursos) else { throw ErrorGenerador.sinRecursos(tipo) }
        let clave = "\(paso)|\(e.texto)"
        let datos = ["texto": e.texto, "paso": paso]
        switch paso {
        case "evidencia":
            let (fragmentos, aceptados, detalles) = Self.fragmentar(t.texto, central: e.central, detalle: e.detalle)
            let payload = Payload.evidencia(.init(titulo: t.titulo, fragmentos: fragmentos, aceptados: aceptados, detalles: detalles,
                                                  pistaDetalle: Self.pistaDetalle, pistaOtro: Self.pistaOtro))
            return Muestra(clave: clave, valores: ["titulo": t.titulo], payload: payload,
                           explicacion: "La idea central es la que explica de qué trata el texto o por qué importa; los datos concretos la apoyan.",
                           erroresHabituales: [ErrorHabitual(respuesta: "detalle", feedback: Self.pistaDetalle),
                                               ErrorHabitual(respuesta: "otro", feedback: Self.pistaOtro)],
                           pistas: ["Pregúntate qué quiere decir el texto en conjunto, no qué datos da."],
                           complejidad: Double(fragmentos.count), datos: datos, juego: "J46")
        case "tema":
            let (eleccion, errores) = Opciones.eleccion(correcta: e.tema.correcta,
                                                        distractores: [(e.tema.concreto, Self.pistaConcreto), (e.tema.amplio, Self.pistaAmplio)],
                                                        rng: &rng)
            return Muestra(clave: clave, valores: ["titulo": t.titulo], payload: .eleccion(eleccion),
                           explicacion: "El tema resume todo el texto en pocas palabras: ni un solo aspecto ni algo tan general que sirva para cualquier texto.",
                           erroresHabituales: errores, pistas: ["El tema cubre todo el texto, pero solo este texto."],
                           complejidad: 2, datos: datos, juego: "J46", textoRef: e.texto)
        default:
            // Recuerdo: se resume de memoria, sin el texto delante (sí lo tiene el paso del tema).
            return Muestra(clave: clave, valores: ["titulo": t.titulo], payload: .recuerdo(.init(modelo: e.modelo, criterios: e.criterios, maximo: 400)),
                           explicacion: "Un buen resumen recoge la idea central con palabras propias y deja fuera los detalles.",
                           pistas: [], complejidad: 3, datos: datos, juego: "J46")
        }
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        let paso = p.textos("paso", porDefecto: ["evidencia"]).first ?? "evidencia"
        return (recursos.resumen?.textos ?? []).prefix(limite).map { "\(paso)|\($0.texto)" }
    }

    /// Parte el texto en oraciones tocables (por «.», «;» y «:»). La oración que contiene (o forma
    /// parte de) una idea central del ANEXO A es aceptada; si no, la que contiene un detalle es detalle.
    static func fragmentar(_ texto: String, central: [String], detalle: [String]) -> ([ElementoTexto], [String], [String]) {
        var oraciones: [String] = []
        var actual = ""
        for ch in texto {
            actual.append(ch)
            if ".;:".contains(ch) { oraciones.append(actual); actual = "" }
        }
        oraciones.append(actual)
        var limpias: [String] = []
        for o in oraciones.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !o.isEmpty {
            // Los restos sin letras (comillas, rayas) se pegan a la oración anterior.
            if !o.contains(where: \.isLetter), let ultima = limpias.popLast() { limpias.append(ultima + o) } else { limpias.append(o) }
        }
        func nucleo(_ s: String) -> String { s.trimmingCharacters(in: CharacterSet(charactersIn: ".;:,«»\" ")) }
        var elementos: [ElementoTexto] = [], aceptados: [String] = [], detalles: [String] = []
        for (k, o) in limpias.enumerated() {
            let id = "f\(k + 1)"
            elementos.append(ElementoTexto(id: id, texto: o))
            if central.contains(where: { o.contains(nucleo($0)) || $0.contains(nucleo(o)) }) { aceptados.append(id) }
            else if detalle.contains(where: { o.contains(nucleo($0)) }) { detalles.append(id) }
        }
        return (elementos, aceptados, detalles)
    }
}
