import Foundation

/// Respuestas construidas a partir del payload: la correcta y una con un error.
/// Se usan para mostrar la solución, en la pantalla de revisión, en las capturas y en los tests.
enum RespuestaEjemplo {
    static func correcta(_ payload: Payload) -> Respuesta {
        switch payload {
        case .eleccion(let p): .eleccion(p.correcta)
        case .verdaderoFalso(let p): .verdaderoFalso(p.esVerdadera)
        case .clasificar(let p): .clasificar(Dictionary(p.fichas.map { ($0.id, $0.categoria) }, uniquingKeysWith: { a, _ in a }))
        case .ordenar(let p): .ordenar(p.ordenCorrecto)
        case .emparejar(let p): .emparejar(p.pares.filter { $0.count == 2 }.map { .init(izquierda: $0[0], derecha: $0[1]) })
        case .marcarTexto(let p): .marcarTexto(Set(p.correctos))
        case .segmentar(let p): .segmentar(p.segmentos.map { .init(id: $0.id, desde: $0.desde, hasta: $0.hasta, etiqueta: $0.etiqueta, padre: $0.padre) })
        case .ruedas(let p): .ruedas(Dictionary(p.ruedas.map { ($0.id, $0.correcta) }, uniquingKeysWith: { a, _ in a }))
        case .construir(let p): .construir(Dictionary(p.huecos.map { ($0.id, $0.correcta) }, uniquingKeysWith: { a, _ in a }))
        case .numerico(let p): .numerico(p.respuesta)
        case .colocarTilde(let p): .colocarTilde(p.indiceTilde)
        case .fraccionBarras(let p): .fraccionBarras(partes: p.solucion.partes, coloreadas: Set(0..<p.solucion.coloreadas))
        case .evidencia(let p): .evidencia(p.aceptados.first ?? "")
        case .recuerdo(let p): .recuerdo(.init(texto: "", enPapel: true, modeloVisto: true, cumplidos: Set(p.criterios.indices)))
        case .figuraArea(let p): .figura(p.respuestaCorrecta)
        case .rayosX(let p): .rayosX(p.respuestaCorrecta)
        case .editor(let p): .editor(p.respuestaCorrecta)
        }
    }

    /// Respuesta que difiere de la correcta en un elemento (si el payload lo permite).
    static func conUnError(_ payload: Payload, erroresHabituales: [ErrorHabitual] = []) -> Respuesta {
        switch payload {
        case .eleccion(let p):
            let habitual = erroresHabituales.map(\.respuesta).first { r in p.opciones.contains { $0.id == r } && r != p.correcta }
            return .eleccion(habitual ?? p.opciones.first { $0.id != p.correcta }?.id ?? p.correcta)
        case .verdaderoFalso(let p):
            return .verdaderoFalso(!p.esVerdadera)
        case .clasificar(let p):
            var r = Dictionary(p.fichas.map { ($0.id, $0.categoria) }, uniquingKeysWith: { a, _ in a })
            if let f = p.fichas.first, let otra = p.categorias.first(where: { $0.id != f.categoria }) { r[f.id] = otra.id }
            return .clasificar(r)
        case .ordenar(let p):
            var o = p.ordenCorrecto
            if o.count >= 2 { o.swapAt(0, 1) }
            return .ordenar(o)
        case .emparejar(let p):
            var pares = p.pares.filter { $0.count == 2 }.map { Respuesta.ParRespuesta(izquierda: $0[0], derecha: $0[1]) }
            if pares.count >= 2 { (pares[0].derecha, pares[1].derecha) = (pares[1].derecha, pares[0].derecha) }
            return .emparejar(pares)
        case .marcarTexto(let p):
            var marcados = Set(p.correctos)
            if let primero = p.correctos.first { marcados.remove(primero) }
            if let extra = p.tokens.first(where: { !p.correctos.contains($0.id) }) { marcados.insert(extra.id) }
            return .marcarTexto(marcados)
        case .segmentar(let p):
            let padres = Set(p.segmentos.compactMap(\.padre))
            var segmentos = p.segmentos
            if let hoja = segmentos.lastIndex(where: { !padres.contains($0.id) }) { segmentos.remove(at: hoja) }
            return .segmentar(segmentos.map { .init(id: $0.id, desde: $0.desde, hasta: $0.hasta, etiqueta: $0.etiqueta, padre: $0.padre) })
        case .ruedas(let p):
            var r = Dictionary(p.ruedas.map { ($0.id, $0.correcta) }, uniquingKeysWith: { a, _ in a })
            if let rueda = p.ruedas.first, let otra = rueda.opciones.first(where: { $0 != rueda.correcta }) { r[rueda.id] = otra }
            return .ruedas(r)
        case .construir(let p):
            var r = Dictionary(p.huecos.map { ($0.id, $0.correcta) }, uniquingKeysWith: { a, _ in a })
            if let h = p.huecos.first, let otra = p.piezas.first(where: { $0.id != h.correcta }) { r[h.id] = otra.id }
            return .construir(r)
        case .numerico(let p):
            let habitual = erroresHabituales.map(\.respuesta).first { Racional.interpretar($0) != nil && $0 != p.respuesta }
            return .numerico(habitual ?? (p.respuesta == "0" ? "1" : "0"))
        case .colocarTilde(let p):
            if p.indiceTilde != nil { return .colocarTilde(nil) }
            return .colocarTilde(p.letras.firstIndex { Payload.ColocarTilde.vocales.contains($0) })
        case .fraccionBarras(let p):
            let (partes, coloreadas) = p.solucion
            let otra = coloreadas > 1 ? coloreadas - 1 : coloreadas + 1
            return .fraccionBarras(partes: partes, coloreadas: Set(0..<otra))
        case .evidencia(let p):
            return .evidencia(p.detalles.first ?? p.fragmentos.first { !p.aceptados.contains($0.id) }?.id ?? "")
        case .recuerdo:
            return correcta(payload)
        case .figuraArea(let p):
            var r = p.respuestaCorrecta
            r.total = p.erroneos.sorted { $0.key < $1.key }.first { $0.value != p.total }?.value ?? "0"
            return .figura(r)
        case .rayosX(let p):
            // El sujeto (o el verbo) desplazado: falla la capa 2.
            var r = p.respuestaCorrecta
            if p.omitido != nil { r.omitido = p.personas.first { $0 != p.omitido } } else { r.sujeto = Set(p.verbo) }
            return .rayosX(r)
        case .editor(let p):
            var r = p.respuestaCorrecta
            if let f = p.faltas.first { r.cambios[f.token] = p.formas[f.token]?.first { $0 != f.correcta } ?? "" }
            return .editor(r)
        }
    }
}

/// Texto legible de la solución de un ítem (se muestra tras corregir).
enum DescripcionSolucion {
    static func texto(_ payload: Payload) -> String {
        switch payload {
        case .eleccion(let p):
            return p.opciones.first { $0.id == p.correcta }?.texto ?? p.correcta
        case .verdaderoFalso(let p):
            return p.esVerdadera ? "Verdadero" : "Falso"
        case .clasificar(let p):
            return p.categorias.map { c in
                "\(c.nombre): " + p.fichas.filter { $0.categoria == c.id }.map(\.texto).joined(separator: ", ")
            }.joined(separator: " · ")
        case .ordenar(let p):
            let textos = Dictionary(p.fichas.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
            return p.ordenCorrecto.map { textos[$0] ?? $0 }.joined(separator: " → ")
        case .emparejar(let p):
            let izq = Dictionary(p.izquierda.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
            let der = Dictionary(p.derecha.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
            return p.pares.filter { $0.count == 2 }.map { "\(izq[$0[0]] ?? $0[0]) — \(der[$0[1]] ?? $0[1])" }.joined(separator: " · ")
        case .marcarTexto(let p):
            let correctos = Set(p.correctos)
            return p.tokens.filter { correctos.contains($0.id) }.map(\.texto).joined(separator: ", ")
        case .segmentar(let p):
            let posicion = Dictionary(p.tokens.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
            let nombres = Dictionary(p.etiquetas.map { ($0.id, $0.nombre) }, uniquingKeysWith: { a, _ in a })
            return p.segmentos.sorted {
                (posicion[$0.desde] ?? 0, -(posicion[$0.hasta] ?? 0)) < (posicion[$1.desde] ?? 0, -(posicion[$1.hasta] ?? 0))
            }.map { s in
                let a = posicion[s.desde] ?? 0, b = posicion[s.hasta] ?? a
                let texto = a <= b && b < p.tokens.count ? p.tokens[a...b].map(\.texto).joined(separator: " ") : "?"
                return "[\(texto)] \(nombres[s.etiqueta] ?? s.etiqueta)"
            }.joined(separator: " · ")
        case .ruedas(let p):
            return p.ruedas.map { "\($0.nombre): \($0.correcta)" }.joined(separator: " · ")
        case .construir(let p):
            let piezas = Dictionary(p.piezas.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
            var texto = p.plantilla
            for h in p.huecos { texto = texto.replacingOccurrences(of: "{\(h.id)}", with: piezas[h.correcta] ?? h.correcta) }
            return texto
        case .numerico(let p):
            return [p.respuesta, p.unidad].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        case .colocarTilde(let p):
            return p.indiceTilde == nil ? "«\(p.palabra)», sin tilde" : "«\(p.correcta)»"
        case .fraccionBarras(let p):
            let (partes, coloreadas) = p.solucion
            let escrita = "\(coloreadas)/\(partes)"
            return escrita == p.objetivo ? p.objetivo : "\(escrita) = \(p.objetivo)"
        case .evidencia(let p):
            let textos = Dictionary(p.fragmentos.map { ($0.id, $0.texto) }, uniquingKeysWith: { a, _ in a })
            return p.aceptados.compactMap { textos[$0] }.map { "«\($0)»" }.joined(separator: " o ")
        case .recuerdo(let p):
            return p.modelo
        case .figuraArea(let p):
            return "\(p.total) \(p.unidad)"
        case .rayosX(let p):
            let limpio = { (ids: [String]) in p.texto(ids).trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            let sujeto = p.omitido.map { "sujeto omitido (\($0))" } ?? "sujeto «\(limpio(p.sujeto))»"
            var t = "Verbo «\(limpio(p.verbo))»; \(sujeto)"
            if p.capas >= 4 {
                let nombres = Dictionary(p.funciones.map { ($0.id, $0.nombre) }, uniquingKeysWith: { a, _ in a })
                t += "; " + p.grupos.map { "\(nombres[$0.funcion] ?? $0.funcion): «\(limpio($0.tokens))»" }.joined(separator: "; ")
            }
            return t
        case .editor(let p):
            return p.faltas.map { "«\($0.correcta.trimmingCharacters(in: .punctuationCharacters))»: \($0.uso)" }.joined(separator: "; ")
        }
    }
}

extension Respuesta {
    /// Indica si una respuesta (que la interfaz va construyendo) está completa y se puede comprobar.
    func esCompleta(para payload: Payload) -> Bool {
        switch (payload, self) {
        case (.eleccion(let p), .eleccion(let id)): p.opciones.contains { $0.id == id }
        case (.verdaderoFalso, .verdaderoFalso): true
        case (.clasificar(let p), .clasificar(let r)): p.fichas.allSatisfy { r[$0.id] != nil }
        case (.ordenar(let p), .ordenar(let r)): r.count == p.fichas.count
        case (.emparejar(let p), .emparejar(let r)): Set(r.map(\.izquierda)).count == p.izquierda.count && r.count == p.izquierda.count
        case (.marcarTexto, .marcarTexto(let r)): !r.isEmpty
        case (.segmentar, .segmentar(let r)): !r.isEmpty
        case (.ruedas(let p), .ruedas(let r)): p.ruedas.allSatisfy { r[$0.id] != nil }
        case (.construir(let p), .construir(let r)): p.huecos.allSatisfy { r[$0.id] != nil }
        case (.numerico, .numerico(let t)): Racional.interpretar(t) != nil
        case (.colocarTilde, .colocarTilde): true
        case (.fraccionBarras, .fraccionBarras(let partes, let coloreadas)):
            Payload.FraccionBarras.rangoPartes.contains(partes) && !coloreadas.isEmpty
        case (.evidencia(let p), .evidencia(let id)): p.fragmentos.contains { $0.id == id }
        case (.recuerdo, .recuerdo(let r)): r.modeloVisto && (r.enPapel || !r.texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case (.figuraArea, .figura(let r)): r.unidad != nil && Racional.interpretar(r.total) != nil
        case (.rayosX(let p), .rayosX(let r)): r.capa > p.capas
        case (.editor, .editor(let r)): !r.marcadas.isEmpty && r.marcadas.allSatisfy { r.cambios[$0] != nil }
        default: false
        }
    }
}

extension Payload.FraccionBarras {
    /// Solución de referencia: partes de la barra y número de celdas coloreadas. En
    /// `colorear`, las partes son las dadas; en `dividirYColorear`, la primera partición
    /// permitida o el denominador del objetivo.
    var solucion: (partes: Int, coloreadas: Int) {
        guard let (n, d) = fraccionObjetivo else { return (partes ?? 1, 0) }
        let total = modo == .colorear ? (partes ?? d) : (particionesPermitidas?.first ?? d)
        return (total, total * n / d)
    }
}

extension Item {
    /// Huella de la pregunta (D-087): la clave canónica del caso en los ítems generados (dos
    /// semillas, o dos plantillas del mismo tipo, pueden dar la misma pregunta) y el id en los
    /// estáticos. Ninguna ronda repite una huella.
    var huella: String {
        if let origen { return "id|" + origen }
        return claveGenerada.map { "gen|" + $0 } ?? "id|" + id
    }
}

extension Array where Element == Item {
    /// Los ítems sin repetir huella, en su orden (se queda el primero de cada pregunta).
    func sinPreguntasRepetidas(excluyendo previas: Set<String> = []) -> [Item] {
        var vistas = previas
        return filter { vistas.insert($0.huella).inserted }
    }
}
