import Foundation

/// Respuesta del usuario a un ítem, con la forma que corresponde a cada mecánica.
enum Respuesta: Sendable, Equatable {
    /// Id de la opción elegida.
    case eleccion(String)
    case verdaderoFalso(Bool)
    /// Id de ficha → id de categoría.
    case clasificar([String: String])
    /// Ids de las fichas en el orden dado por el usuario.
    case ordenar([String])
    /// Pares `(idIzquierda, idDerecha)`.
    case emparejar([ParRespuesta])
    /// Ids de los tokens marcados.
    case marcarTexto(Set<String>)
    case segmentar([SegmentoRespuesta])
    /// Id de rueda → opción elegida.
    case ruedas([String: String])
    /// Id de hueco → id de pieza colocada.
    case construir([String: String])
    /// Texto tecleado en el teclado numérico propio (coma decimal, `a/b` para fracciones).
    case numerico(String)
    /// Índice de la vocal con tilde, o `nil` = «Sin tilde».
    case colocarTilde(Int?)
    /// Partes en que se ha dividido la barra y celdas coloreadas (su posición no importa).
    case fraccionBarras(partes: Int, coloreadas: Set<Int>)
    /// 05G: id del fragmento tocado, recuerdo y figura.
    case evidencia(String)
    case recuerdo(RespuestaRecuerdo)
    case figura(RespuestaFigura)
    /// 05H: capas de Rayos X y correcciones del Editor.
    case rayosX(RespuestaRayosX)
    case editor(RespuestaEditor)

    struct ParRespuesta: Sendable, Equatable, Hashable {
        var izquierda: String
        var derecha: String
    }

    /// Segmento marcado por el usuario. `padre` es el id de otro segmento de la misma respuesta.
    struct SegmentoRespuesta: Sendable, Equatable {
        var id: String
        var desde: String
        var hasta: String
        var etiqueta: String
        var padre: String?
    }
}

/// Resultado de evaluar una respuesta.
struct Resultado: Sendable, Equatable {
    var correcto: Bool
    /// Proporción de la respuesta que es correcta (0…1), para feedback parcial.
    var fraccionCorrecta: Double
    /// Ids de los elementos del ítem que el usuario ha fallado. Por mecánica:
    /// - eleccion: id de la opción elegida (si es incorrecta);
    /// - verdaderoFalso: `"verdadero"` o `"falso"` (lo que respondió el usuario);
    /// - clasificar / ordenar: ids de fichas mal colocadas;
    /// - emparejar: ids de la izquierda mal emparejados;
    /// - marcarTexto: ids de tokens marcados de más o de menos;
    /// - segmentar: ids de los segmentos esperados que no se han reproducido;
    /// - ruedas: ids de rueda; construir: ids de hueco;
    /// - numerico: el texto tecleado;
    /// - colocarTilde: `"sinTilde"`, `"conTilde"` o `"posicion"`;
    /// - fraccionBarras: `"partes"` (división incorrecta o no permitida) y/o `"coloreadas"`.
    /// Estos valores se cruzan con `erroresHabituales[].respuesta` para elegir el feedback.
    var errores: [String]

    static let respuestaIncompatible = "respuestaIncompatible"
}

/// Evalúa respuestas contra el payload de un ítem. Puro y sin estado.
enum Evaluador {
    static func evaluar(_ respuesta: Respuesta, para item: Item) -> Resultado {
        evaluar(respuesta, payload: item.payload)
    }

    static func evaluar(_ respuesta: Respuesta, payload: Payload) -> Resultado {
        switch (payload, respuesta) {
        case (.eleccion(let p), .eleccion(let r)):
            return r == p.correcta ? .acierto : .fallo([r])
        case (.verdaderoFalso(let p), .verdaderoFalso(let r)):
            return r == p.esVerdadera ? .acierto : .fallo([r ? "verdadero" : "falso"])
        case (.clasificar(let p), .clasificar(let r)):
            let mal = p.fichas.filter { r[$0.id] != $0.categoria }.map(\.id)
            return .parcial(total: p.fichas.count, errores: mal)
        case (.ordenar(let p), .ordenar(let r)):
            let mal = p.ordenCorrecto.enumerated().filter { i, id in i >= r.count || r[i] != id }.map(\.element)
            let correcto = r == p.ordenCorrecto
            return Resultado(correcto: correcto, fraccionCorrecta: proporcion(p.ordenCorrecto.count - mal.count, p.ordenCorrecto.count),
                             errores: correcto ? [] : (mal.isEmpty ? [Resultado.respuestaIncompatible] : mal))
        case (.emparejar(let p), .emparejar(let r)):
            return evaluarEmparejar(p, r)
        case (.marcarTexto(let p), .marcarTexto(let r)):
            let correctos = Set(p.correctos)
            let aciertos = correctos.intersection(r).count
            let erroneos = correctos.symmetricDifference(r)
            let ordenTokens = p.tokens.map(\.id).filter { erroneos.contains($0) }
            let desconocidos = erroneos.subtracting(ordenTokens).sorted()
            return Resultado(correcto: erroneos.isEmpty, fraccionCorrecta: proporcion(aciertos, correctos.union(r).count),
                             errores: ordenTokens + desconocidos)
        case (.segmentar(let p), .segmentar(let r)):
            return evaluarSegmentar(p, r)
        case (.ruedas(let p), .ruedas(let r)):
            let mal = p.ruedas.filter { r[$0.id] != $0.correcta }.map(\.id)
            return .parcial(total: p.ruedas.count, errores: mal)
        case (.construir(let p), .construir(let r)):
            let mal = p.huecos.filter { r[$0.id] != $0.correcta }.map(\.id)
            return .parcial(total: p.huecos.count, errores: mal)
        case (.numerico(let p), .numerico(let r)):
            return evaluarNumerico(p, r)
        case (.colocarTilde(let p), .colocarTilde(let r)):
            if r == p.indiceTilde { return .acierto }
            switch (p.indiceTilde, r) {
            case (.some, nil): return .fallo(["sinTilde"])
            case (nil, .some): return .fallo(["conTilde"])
            default: return .fallo(["posicion"])
            }
        case (.fraccionBarras(let p), .fraccionBarras(let partes, let coloreadas)):
            return evaluarFraccionBarras(p, partes: partes, coloreadas: coloreadas.filter { (0..<partes).contains($0) }.count)
        case (.evidencia(let p), .evidencia(let r)):
            if p.aceptados.contains(r) { return .acierto }
            return .fallo([p.detalles.contains(r) ? "detalle" : "otro"])
        case (.recuerdo(let p), .recuerdo(let r)):
            // Autoevaluación: se completa siempre; la proporción es la de criterios marcados.
            return Resultado(correcto: true, fraccionCorrecta: proporcion(r.cumplidos.count, max(p.criterios.count, 1)), errores: [])
        case (.figuraArea(let p), .figura(let r)):
            return evaluarFigura(p, r)
        case (.rayosX(let p), .rayosX(let r)):
            let errores = (1...p.capas).flatMap { p.errores(capa: $0, r) }
            let total = 2 + (p.capas >= 4 ? p.grupos.count : 0)
            let bien = total - min(total, errores.count)
            return errores.isEmpty ? .acierto : Resultado(correcto: false, fraccionCorrecta: proporcion(bien, total), errores: errores)
        case (.editor(let p), .editor(let r)):
            let faltas = Set(p.faltas.map(\.token))
            var errores = r.marcadas.subtracting(faltas).sorted().map { "sobra_\($0)" }
            for f in p.faltas {
                if !r.marcadas.contains(f.token) { errores.append("falta_\(f.token)") }
                else if r.cambios[f.token] != f.correcta { errores.append("forma_\(f.token)") }
            }
            return errores.isEmpty ? .acierto
                : Resultado(correcto: false, fraccionCorrecta: proporcion(p.faltas.count - errores.filter { !$0.hasPrefix("sobra_") }.count, max(p.faltas.count, 1)), errores: errores)
        default:
            return .fallo([Resultado.respuestaIncompatible])
        }
    }

    /// Feedback específico de los errores habituales que coinciden con el resultado.
    static func feedback(para resultado: Resultado, item: Item) -> [String] {
        guard !resultado.correcto else { return [] }
        let errores = Set(resultado.errores)
        return item.erroresHabituales.filter { errores.contains($0.respuesta) }.map(\.feedback)
    }

    // MARK: - Mecánicas con lógica propia

    /// Figura: vale cualquier descomposición; manda el total (por valor) con su unidad cuadrada. Los
    /// errores dicen qué falla: cada parte mal calculada (`parte_<id>`), el total, la unidad y los
    /// errores típicos cuyo valor coincide con el total tecleado.
    private static func evaluarFigura(_ p: Payload.FiguraArea, _ r: Respuesta.RespuestaFigura) -> Resultado {
        // «Restar el hueco» se ofrece siempre; en una figura sin hueco es un error de estrategia (05H).
        if let e = r.estrategia, !p.estrategiasValidas.contains(e) {
            return Resultado(correcto: false, fraccionCorrecta: 0, errores: e == .restar ? ["sinHueco"] : ["estrategia"])
        }
        func valor(_ t: String) -> Racional? { Racional.interpretar(t)?.valor }
        let totalBien = valor(r.total) != nil && valor(r.total) == valor(p.total)
        let unidadBien = r.unidad == p.unidad
        var errores: [String] = []
        if let d = p.descomposicion(estrategia: r.estrategia, cortes: r.cortes) {
            for parte in d.partes where r.areas[parte.id].flatMap(valor) != valor(parte.area) { errores.append("parte_\(parte.id)") }
        }
        if !totalBien {
            // El error típico reconocido va primero (su pista es la del reintento); si no hay, «total».
            let tipicos = p.erroneos.sorted(by: { $0.key < $1.key }).filter { valor($0.value) == valor(r.total) }.map(\.key)
            errores.insert(contentsOf: tipicos.isEmpty ? ["total"] : tipicos, at: 0)
        }
        if !unidadBien { errores.append(r.unidad.map { $0.contains("²") ? "unidad" : "unidadLineal" } ?? "unidad") }
        let correcto = totalBien && unidadBien
        return Resultado(correcto: correcto, fraccionCorrecta: correcto ? 1 : (totalBien || unidadBien ? 0.5 : 0), errores: correcto ? [] : errores)
    }

    private static func evaluarEmparejar(_ p: Payload.Emparejar, _ r: [Respuesta.ParRespuesta]) -> Resultado {
        let esperado = Dictionary(p.pares.compactMap { $0.count == 2 ? ($0[0], $0[1]) : nil }, uniquingKeysWith: { a, _ in a })
        var dado: [String: [String]] = [:]
        for par in r { dado[par.izquierda, default: []].append(par.derecha) }
        let mal = p.izquierda.map(\.id).filter { id in
            guard let correcta = esperado[id] else { return dado[id] != nil }
            return dado[id] != [correcta]
        }
        let paresCorrectos = esperado.filter { dado[$0.key] == [$0.value] }.count
        let correcto = mal.isEmpty && r.count == esperado.count
        return Resultado(correcto: correcto, fraccionCorrecta: proporcion(paresCorrectos, max(esperado.count, r.count)),
                         errores: correcto ? [] : (mal.isEmpty ? [Resultado.respuestaIncompatible] : mal))
    }

    private static func evaluarSegmentar(_ p: Payload.Segmentar, _ r: [Respuesta.SegmentoRespuesta]) -> Resultado {
        let esperados = Dictionary(p.segmentos.map { ($0.id, ($0.desde, $0.hasta, $0.etiqueta, $0.padre)) }, uniquingKeysWith: { a, _ in a })
        let dados = Dictionary(r.map { ($0.id, ($0.desde, $0.hasta, $0.etiqueta, $0.padre)) }, uniquingKeysWith: { a, _ in a })
        let clavesEsperadas = Dictionary(p.segmentos.map { ($0.id, claveSegmento($0.id, esperados)) }, uniquingKeysWith: { a, _ in a })
        let clavesDadas = Set(r.map { claveSegmento($0.id, dados) })
        let faltan = p.segmentos.map(\.id).filter { !clavesDadas.contains(clavesEsperadas[$0] ?? "") }
        let conjuntoEsperado = Set(clavesEsperadas.values)
        let sobrantes = clavesDadas.subtracting(conjuntoEsperado).count
        let aciertos = p.segmentos.count - faltan.count
        let correcto = faltan.isEmpty && sobrantes == 0
        return Resultado(correcto: correcto, fraccionCorrecta: proporcion(aciertos, p.segmentos.count + sobrantes),
                         errores: correcto ? [] : (faltan.isEmpty ? [Resultado.respuestaIncompatible] : faltan))
    }

    /// Clave canónica de un segmento: rango, etiqueta y, recursivamente, la de su padre.
    /// Así dos segmentaciones con ids distintos pero la misma estructura se consideran iguales.
    private static func claveSegmento(_ id: String, _ todos: [String: (String, String, String, String?)], profundidad: Int = 0) -> String {
        guard let (desde, hasta, etiqueta, padre) = todos[id], profundidad < 32 else { return "?" }
        let clavePadre = padre.map { claveSegmento($0, todos, profundidad: profundidad + 1) } ?? "-"
        return "\(desde)…\(hasta):\(etiqueta)<\(clavePadre)>"
    }

    private static func evaluarNumerico(_ p: Payload.Numerico, _ texto: String) -> Resultado {
        guard let dado = Racional.interpretar(texto), let esperado = Racional.interpretar(p.respuesta) else {
            return .fallo([texto])
        }
        // Si se pide fracción irreducible, no vale un decimal ni una fracción sin simplificar.
        if p.formato == .fraccion, p.exigeIrreducible == true,
           dado.formato == .decimal || (dado.formato == .fraccion && !dado.irreducible) {
            return .fallo([texto])
        }
        let tolerancia = p.tolerancia ?? 0
        let correcto = tolerancia > 0
            ? abs(dado.valor.valorDouble - esperado.valor.valorDouble) <= tolerancia + 1e-9
            : dado.valor == esperado.valor
        return correcto ? .acierto : .fallo([texto])
    }

    private static func evaluarFraccionBarras(_ p: Payload.FraccionBarras, partes: Int, coloreadas: Int) -> Resultado {
        guard let (n, d) = p.fraccionObjetivo, partes > 0 else { return .fallo([Resultado.respuestaIncompatible]) }
        var errores: [String] = []
        let particionValida: Bool = {
            if p.modo == .colorear, let fijas = p.partes { return partes == fijas }
            if let permitidas = p.particionesPermitidas { return permitidas.contains(partes) }
            return p.aceptarEquivalentes || partes == d
        }()
        if !particionValida { errores.append("partes") }
        let cantidadCorrecta = p.aceptarEquivalentes
            ? Racional(numerador: coloreadas, denominador: partes) == Racional(numerador: n, denominador: d)
            : partes == d && coloreadas == n
        // Con una división no válida solo se informa de la división (lo coloreado no se puede juzgar).
        if !cantidadCorrecta, particionValida { errores.append("coloreadas") }
        return errores.isEmpty ? .acierto : Resultado(correcto: false, fraccionCorrecta: particionValida ? 0.5 : 0, errores: errores)
    }

    private static func proporcion(_ a: Int, _ b: Int) -> Double {
        b == 0 ? 0 : Double(a) / Double(b)
    }
}

private extension Resultado {
    static let acierto = Resultado(correcto: true, fraccionCorrecta: 1, errores: [])

    static func fallo(_ errores: [String]) -> Resultado {
        Resultado(correcto: false, fraccionCorrecta: 0, errores: errores)
    }

    static func parcial(total: Int, errores: [String]) -> Resultado {
        Resultado(correcto: errores.isEmpty && total > 0,
                  fraccionCorrecta: total == 0 ? 0 : Double(total - errores.count) / Double(total),
                  errores: errores)
    }
}
