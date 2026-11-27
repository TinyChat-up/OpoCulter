import Foundation

/// Editor (Fase 05H §4, D-125): se toma una frase correcta de `frases.json` y se sustituye la forma
/// correcta por otra de su misma familia («Dime por qué lloras» → «Dime porque lloras»). El usuario
/// toca la palabra mal escrita, elige la forma correcta y ve el uso que la justifica.
///
/// | Dificultad | Texto |
/// |---|---|
/// | 1–3 | una frase con una falta |
/// | 4 | dos frases de familias distintas, una falta (sin decir cuántas hay) |
/// | 5–6 | tres frases, dos faltas, con la penalización del examen al final |
///
/// Las frases del banco son de respuesta única entre las formas de su familia (son las del hueco del
/// lote 02b, D-089): cualquier otra forma de la familia es incorrecta en ese contexto. Las faltas
/// salen de las familias de la plantilla; las frases sin falta, de cualquier familia.
struct GeneradorEditor: GeneradorItems {
    let tipo = "editor"
    let mecanicas: Set<Mecanica> = [.editor]
    let marcadores: Set<String> = ["contexto"]

    static func sinTildes(_ s: String) -> String { s.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES")) }

    /// Frases y faltas por dificultad.
    static func forma(_ d: Int) -> (frases: Int, faltas: Int) {
        switch d {
        case ...3: (1, 1)
        case 4: (2, 1)
        default: (3, 2)
        }
    }

    /// Pista de razonamiento: los usos de todas las formas de la familia (no dice cuál va).
    static func pista(_ f: FamiliaFormas) -> String {
        "Piensa en el uso de cada forma: " + f.formas.map { "«\($0.texto)» es \($0.uso)" }.joined(separator: "; ") + "."
    }

    struct Pieza { var texto: String; var familia: FamiliaFormas?; var falta: (correcta: String, uso: String, tilde: Bool)? }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let banco = recursos.frases
        let propias = Set(p.textos("familias", porDefecto: banco.familias.map(\.id)))
        let tope = min(max(p.dificultad, 1), 3)
        let familia: (String) -> FamiliaFormas? = { id in banco.familias.first { $0.id == id } }
        let (nFrases, nFaltas) = Self.forma(p.dificultad)
        let conFalta = rng.barajar(banco.frases.filter { propias.contains($0.familia) && $0.dificultad <= tope })
        guard conFalta.count >= nFaltas else { throw ErrorGenerador.sinRecursos(tipo) }
        // Faltas de familias distintas cuando la plantilla tiene varias.
        var elegidas: [FraseHueco] = []
        for f in conFalta where elegidas.count < nFaltas && (propias.count == 1 || !elegidas.contains { $0.familia == f.familia }) { elegidas.append(f) }
        guard elegidas.count == nFaltas else { throw ErrorGenerador.sinRecursos(tipo) }
        var sinFalta: [FraseHueco] = []
        for f in rng.barajar(banco.frases.filter { $0.dificultad <= tope }) where sinFalta.count < nFrases - nFaltas {
            guard !(elegidas + sinFalta).contains(where: { $0.familia == f.familia || $0.id == f.id }) else { continue }
            sinFalta.append(f)
        }
        guard sinFalta.count == nFrases - nFaltas else { throw ErrorGenerador.sinRecursos(tipo) }
        let frases = rng.barajar(elegidas.map { ($0, true) } + sinFalta.map { ($0, false) })

        // Palabras de cada frase; el hueco se rellena con la forma correcta o con la errónea.
        var piezas: [Pieza] = []
        for (f, conError) in frases {
            guard let fam = familia(f.familia) else { throw ErrorGenerador.sinRecursos(tipo) }
            let partes = f.texto.components(separatedBy: "___")
            guard partes.count == 2 else { throw ErrorGenerador.sinRecursos(tipo) }
            var izquierda = partes[0].components(separatedBy: " ")
            var derecha = partes[1].components(separatedBy: " ")
            let lead = izquierda.removeLast()          // «¿» pegado al hueco, o vacío
            let trail = derecha.removeFirst()          // «?», «,» o «.» pegados, o vacío
            var escrita = f.correcta
            var falta: (String, String, Bool)?
            if conError {
                let otras = fam.formas.filter { $0.texto.lowercased() != f.correcta.lowercased() }
                guard !otras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
                escrita = GeneradorFraseHueco.ajustar(rng.elemento(otras).texto, como: f.correcta)
                let uso = fam.formas.first { $0.texto.lowercased() == f.correcta.lowercased() }?.uso ?? ""
                falta = (lead + f.correcta + trail, uso, Self.sinTildes(escrita.lowercased()) == Self.sinTildes(f.correcta.lowercased()))
            }
            for w in izquierda where !w.isEmpty { piezas.append(Pieza(texto: w, familia: nil, falta: nil)) }
            piezas.append(Pieza(texto: lead + escrita + trail, familia: fam, falta: falta))
            for w in derecha where !w.isEmpty { piezas.append(Pieza(texto: w, familia: nil, falta: nil)) }
        }
        // Las demás palabras de una familia (de una sola palabra) también ofrecen sus formas al tocarlas.
        let simples = banco.familias.flatMap { fam in fam.formas.filter { !$0.texto.contains(" ") }.map { ($0.texto.lowercased(), fam) } }
        let porForma = Dictionary(simples, uniquingKeysWith: { a, _ in a })
        var tokens: [ElementoTexto] = [], formas: [String: [String]] = [:], faltas: [Payload.Editor.Falta] = []
        var usadas: [FamiliaFormas] = []
        for (k, pz) in piezas.enumerated() {
            let id = "w\(k + 1)"
            tokens.append(ElementoTexto(id: id, texto: pz.texto))
            let nucleo = pz.texto.trimmingCharacters(in: CharacterSet(charactersIn: "¿¡?!.,;:«»"))
            guard !nucleo.isEmpty, let fam = pz.familia ?? porForma[nucleo.lowercased()], let rango = pz.texto.range(of: nucleo) else { continue }
            let lead = String(pz.texto[..<rango.lowerBound]), trail = String(pz.texto[rango.upperBound...])
            let modelo = pz.falta?.correcta.trimmingCharacters(in: CharacterSet(charactersIn: "¿¡?!.,;:«»")) ?? nucleo
            formas[id] = fam.formas.map { lead + GeneradorFraseHueco.ajustar($0.texto, como: modelo) + trail }
            if let f = pz.falta {
                faltas.append(.init(token: id, correcta: f.correcta, uso: f.uso, tilde: f.tilde))
                usadas.append(fam)
            }
        }
        let penalizacion = p.dificultad >= 5
        let puntos = faltas.reduce(0.0) { $0 + ($1.tilde ? 0.25 : 0.5) }
        var explicacion = faltas.map { "«\($0.correcta.trimmingCharacters(in: CharacterSet(charactersIn: "¿¡?!.,;:")))»: \($0.uso)." }.joined(separator: " ")
        if penalizacion {
            explicacion += " En el examen, cada palabra mal escrita resta 0,5 y cada tilde, 0,25: sin corregir, −\(FormatoNumero.numero(Racional(numerador: Int(puntos * 100), denominador: 100)!))."
        }
        var errores: [ErrorHabitual] = []
        for (f, fam) in zip(faltas, usadas) {
            errores.append(ErrorHabitual(respuesta: "falta_\(f.token)", feedback: Self.pista(fam)))
            errores.append(ErrorHabitual(respuesta: "forma_\(f.token)", feedback: Self.pista(fam)))
        }
        let texto = tokens.map(\.texto).joined(separator: " ")
        return Muestra(clave: "editor|\(frases.map { "\($0.0.id)\($0.1 ? "*" : "")" }.joined(separator: "+"))|\(tokens.first { faltas.map(\.token).contains($0.id) }?.texto ?? "")",
                       valores: [:], payload: .editor(Payload.Editor(tokens: tokens, formas: formas, faltas: faltas, penalizacion: penalizacion)),
                       explicacion: explicacion, erroresHabituales: errores,
                       pistas: ["Lee cada frase despacio: solo cambia la palabra cuyo uso no encaja."],
                       complejidad: Double(p.dificultad) + Double(nFrases) + Double(nFaltas) + Double(tokens.count) * 0.02,
                       datos: ["texto": texto, "frases": frases.map(\.0.id).joined(separator: ","),
                               "originales": frases.map { $0.0.texto.replacingOccurrences(of: "___", with: $0.0.correcta) }.joined(separator: " ")],
                       juego: "Editor", origen: elegidas.first?.id)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
