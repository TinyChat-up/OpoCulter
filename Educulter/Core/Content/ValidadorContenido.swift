import Foundation

/// Error de validación legible: qué elemento falla y por qué.
struct ErrorValidacion: Sendable, Equatable, CustomStringConvertible {
    var elemento: String
    var mensaje: String

    var description: String { "\(elemento): \(mensaje)" }
}

/// Comprueba la coherencia del banco de contenido. No lanza: acumula todos los errores
/// para que quien redacta el contenido pueda corregirlos de una vez.
struct ValidadorContenido: Sendable {
    /// Límites editoriales.
    static let maxCaracteresExplicacion = 280
    static let maxPalabrasBloqueTeoria = 40
    /// Años desde la muerte del autor que exige la ley española para el dominio público
    /// (se exige que hayan pasado *más* de 80).
    static let aniosDominioPublico = 80

    /// Año en curso, inyectable para que los tests no dependan de la fecha.
    var anioActual: Int

    init(anioActual: Int) {
        self.anioActual = anioActual
    }

    init(reloj: Reloj = RelojSistema(), calendario: Calendar = .current) {
        self.anioActual = DiaCivil(reloj.ahora, calendario: calendario).anio
    }

    func validar(_ banco: BancoContenido) -> [ErrorValidacion] {
        var errores = validar(catalogo: banco.catalogo)
        let competencias = Set(banco.catalogo.todasLasCompetencias.map(\.id))

        var vistos = Set<String>()
        for item in banco.items {
            if !vistos.insert(item.id).inserted {
                errores.append(.init(elemento: item.id, mensaje: "id de ítem duplicado"))
            }
            errores += validar(item: item, competencias: competencias)
        }

        vistos.removeAll()
        for tarjeta in banco.teoria {
            if !vistos.insert(tarjeta.id).inserted {
                errores.append(.init(elemento: tarjeta.id, mensaje: "id de tarjeta duplicado"))
            }
            errores += validar(tarjeta: tarjeta, competencias: competencias)
        }

        vistos.removeAll()
        for simulacro in banco.simulacros {
            if !vistos.insert(simulacro.id).inserted {
                errores.append(.init(elemento: simulacro.id, mensaje: "id de simulacro duplicado"))
            }
            errores += validar(simulacro: simulacro, competencias: competencias)
        }
        return errores
    }

    // MARK: - Catálogo

    func validar(catalogo: Catalogo) -> [ErrorValidacion] {
        var errores: [ErrorValidacion] = []
        var ids = Set<String>()
        func registrar(_ id: String) {
            if !ids.insert(id).inserted {
                errores.append(.init(elemento: id, mensaje: "id duplicado en el catálogo"))
            }
        }
        if catalogo.version < 1 {
            errores.append(.init(elemento: "catalogo", mensaje: "la versión debe ser 1 o mayor"))
        }
        for area in catalogo.areas {
            registrar(area.id)
            if !Self.coincide(area.id, "[A-Z]{3}") {
                errores.append(.init(elemento: area.id, mensaje: "id de área no válido (se esperan 3 mayúsculas, p. ej. LEN)"))
            }
            if area.nombre.isEmpty { errores.append(.init(elemento: area.id, mensaje: "nombre vacío")) }
            for bloque in area.bloques {
                registrar(bloque.id)
                if !Self.coincide(bloque.id, Self.escapar(area.id) + "\\.[A-Z]{3}") {
                    errores.append(.init(elemento: bloque.id, mensaje: "id de bloque no válido (se espera \(area.id).XXX)"))
                }
                if !(1...3).contains(bloque.prioridad) {
                    errores.append(.init(elemento: bloque.id, mensaje: "prioridad \(bloque.prioridad) fuera de rango (1–3)"))
                }
                if bloque.nombre.isEmpty { errores.append(.init(elemento: bloque.id, mensaje: "nombre vacío")) }
                for competencia in bloque.competencias {
                    registrar(competencia.id)
                    if !Self.coincide(competencia.id, Self.escapar(bloque.id) + "\\.[A-Z0-9]{2,16}") {
                        errores.append(.init(elemento: competencia.id, mensaje: "id de competencia no válido (se espera \(bloque.id).CODIGO)"))
                    }
                    if competencia.nombre.isEmpty { errores.append(.init(elemento: competencia.id, mensaje: "nombre vacío")) }
                }
            }
        }
        return errores
    }

    // MARK: - Ítems

    func validar(item: Item, competencias: Set<String>) -> [ErrorValidacion] {
        var mensajes: [String] = []
        if !Self.coincide(item.id, Self.escapar(item.competencia) + "\\.[0-9]{4}") {
            mensajes.append("el id debe tener el formato <competencia>.NNNN y empezar por su competencia")
        }
        if !competencias.contains(item.competencia) {
            mensajes.append("la competencia \(item.competencia) no existe en el catálogo")
        }
        if !(1...5).contains(item.peldano) { mensajes.append("peldaño \(item.peldano) fuera de rango (1–5)") }
        if !(1...5).contains(item.dificultad) { mensajes.append("dificultad \(item.dificultad) fuera de rango (1–5)") }
        if item.objetivo.isEmpty { mensajes.append("objetivo vacío") }
        if item.enunciado.isEmpty { mensajes.append("enunciado vacío") }
        if item.explicacion.isEmpty { mensajes.append("explicación vacía") }
        if item.explicacion.count > Self.maxCaracteresExplicacion {
            mensajes.append("la explicación tiene \(item.explicacion.count) caracteres (máximo \(Self.maxCaracteresExplicacion))")
        }
        if item.version < 1 { mensajes.append("la versión debe ser 1 o mayor") }
        if item.peldano >= Peldano.sinAyudas.rawValue, !item.pistas.isEmpty {
            mensajes.append("los ítems de peldaño 3 o superior no pueden tener pistas (D-033)")
        }
        for error in item.erroresHabituales where error.respuesta.isEmpty || error.feedback.isEmpty {
            mensajes.append("error habitual con respuesta o feedback vacíos")
        }
        if case .eleccion(let p) = item.payload {
            let opciones = Set(p.opciones.map(\.id))
            for error in item.erroresHabituales where !error.respuesta.isEmpty {
                if !opciones.contains(error.respuesta) {
                    mensajes.append("el error habitual «\(error.respuesta)» no es una opción")
                } else if error.respuesta == p.correcta {
                    mensajes.append("el error habitual «\(error.respuesta)» es la opción correcta")
                }
            }
        }
        for examen in item.referencia?.examenes ?? [] where !Self.coincide(examen, "[0-9]{4}-[LM][0-9]{1,2}") {
            mensajes.append("referencia de examen «\(examen)» no válida (formato AAAA-L9 o AAAA-M9)")
        }
        mensajes += validar(payload: item.payload)
        mensajes += validar(procedencia: item.procedencia)
        mensajes += validar(validacion: item.validacion)
        return mensajes.map { ErrorValidacion(elemento: item.id, mensaje: $0) }
    }

    func validar(payload: Payload) -> [String] {
        switch payload {
        case .eleccion(let p): validarEleccion(p)
        case .verdaderoFalso(let p): p.afirmacion.isEmpty ? ["afirmación vacía"] : []
        case .clasificar(let p): validarClasificar(p)
        case .ordenar(let p): validarOrdenar(p)
        case .emparejar(let p): validarEmparejar(p)
        case .marcarTexto(let p): validarMarcarTexto(p)
        case .segmentar(let p): validarSegmentar(p)
        case .ruedas(let p): validarRuedas(p)
        case .construir(let p): validarConstruir(p)
        case .numerico(let p): validarNumerico(p)
        }
    }

    private func validarEleccion(_ p: Payload.Eleccion) -> [String] {
        var m = Self.idsUnicos(p.opciones.map(\.id), "opciones")
        if !(2...4).contains(p.opciones.count) { m.append("eleccion necesita 2–4 opciones (tiene \(p.opciones.count))") }
        if !p.opciones.contains(where: { $0.id == p.correcta }) { m.append("la opción correcta «\(p.correcta)» no existe") }
        return m
    }

    private func validarClasificar(_ p: Payload.Clasificar) -> [String] {
        var m = Self.idsUnicos(p.categorias.map(\.id), "categorías") + Self.idsUnicos(p.fichas.map(\.id), "fichas")
        if !(2...4).contains(p.categorias.count) { m.append("clasificar necesita 2–4 categorías (tiene \(p.categorias.count))") }
        if p.fichas.isEmpty { m.append("clasificar no tiene fichas") }
        let categorias = Set(p.categorias.map(\.id))
        for ficha in p.fichas where !categorias.contains(ficha.categoria) {
            m.append("la ficha «\(ficha.id)» tiene una categoría inexistente «\(ficha.categoria)»")
        }
        return m
    }

    private func validarOrdenar(_ p: Payload.Ordenar) -> [String] {
        var m = Self.idsUnicos(p.fichas.map(\.id), "fichas")
        if p.fichas.count < 2 { m.append("ordenar necesita al menos 2 fichas") }
        if p.ordenCorrecto.count != p.fichas.count || Set(p.ordenCorrecto) != Set(p.fichas.map(\.id)) {
            m.append("ordenCorrecto no es una permutación de las fichas")
        }
        return m
    }

    private func validarEmparejar(_ p: Payload.Emparejar) -> [String] {
        var m = Self.idsUnicos(p.izquierda.map(\.id), "izquierda") + Self.idsUnicos(p.derecha.map(\.id), "derecha")
        let izq = Set(p.izquierda.map(\.id)), der = Set(p.derecha.map(\.id))
        if p.pares.contains(where: { $0.count != 2 }) {
            m.append("cada par debe tener exactamente 2 ids")
            return m
        }
        for par in p.pares {
            if !izq.contains(par[0]) { m.append("el par usa «\(par[0])», que no está a la izquierda") }
            if !der.contains(par[1]) { m.append("el par usa «\(par[1])», que no está a la derecha") }
        }
        let usadosI = p.pares.map { $0[0] }, usadosD = p.pares.map { $0[1] }
        if Set(usadosI) != izq || usadosI.count != izq.count || Set(usadosD) != der || usadosD.count != der.count {
            m.append("los pares deben cubrir todos los elementos de cada lado exactamente una vez")
        }
        return m
    }

    private func validarMarcarTexto(_ p: Payload.MarcarTexto) -> [String] {
        var m = Self.idsUnicos(p.tokens.map(\.id), "tokens")
        let tokens = Set(p.tokens.map(\.id))
        if p.correctos.isEmpty { m.append("marcarTexto no tiene tokens correctos") }
        for id in p.correctos where !tokens.contains(id) { m.append("el token correcto «\(id)» no existe") }
        if Set(p.correctos).count != p.correctos.count { m.append("tokens correctos repetidos") }
        return m
    }

    private func validarSegmentar(_ p: Payload.Segmentar) -> [String] {
        var m = Self.idsUnicos(p.tokens.map(\.id), "tokens")
            + Self.idsUnicos(p.etiquetas.map(\.id), "etiquetas")
            + Self.idsUnicos(p.segmentos.map(\.id), "segmentos")
        if p.segmentos.isEmpty { m.append("segmentar no tiene segmentos") }
        let posicion = Dictionary(p.tokens.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
        let etiquetas = Set(p.etiquetas.map(\.id))
        let porId = Dictionary(p.segmentos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var rango: [String: ClosedRange<Int>] = [:]

        for s in p.segmentos {
            if !etiquetas.contains(s.etiqueta) { m.append("el segmento «\(s.id)» usa una etiqueta inexistente «\(s.etiqueta)»") }
            guard let a = posicion[s.desde], let b = posicion[s.hasta] else {
                m.append("el segmento «\(s.id)» usa tokens inexistentes")
                continue
            }
            if a > b { m.append("el segmento «\(s.id)» empieza después de terminar") } else { rango[s.id] = a...b }
        }

        for s in p.segmentos {
            guard let padre = s.padre else { continue }
            guard porId[padre] != nil, padre != s.id else {
                m.append("el segmento «\(s.id)» tiene un padre inexistente «\(padre)»")
                continue
            }
            // Ciclos en la cadena de padres.
            var visitados: Set<String> = [s.id]
            var actual: String? = padre
            while let id = actual {
                if !visitados.insert(id).inserted {
                    m.append("el segmento «\(s.id)» forma un ciclo de padres")
                    break
                }
                actual = porId[id]?.padre
            }
            if let r = rango[s.id], let rp = rango[padre], !(rp.lowerBound <= r.lowerBound && r.upperBound <= rp.upperBound) {
                m.append("el segmento «\(s.id)» no está dentro de su padre «\(padre)»")
            }
        }

        // Los hermanos (mismo padre) no pueden solaparse: los anidamientos deben declararse con `padre`.
        let grupos = Dictionary(grouping: p.segmentos, by: { $0.padre ?? "" })
        for (_, hermanos) in grupos {
            let ordenados = hermanos.compactMap { s in rango[s.id].map { (s.id, $0) } }.sorted { $0.1.lowerBound < $1.1.lowerBound }
            for (x, y) in zip(ordenados, ordenados.dropFirst()) where x.1.overlaps(y.1) {
                m.append("los segmentos «\(x.0)» y «\(y.0)» se solapan sin estar anidados con «padre»")
            }
        }
        return m
    }

    private func validarRuedas(_ p: Payload.Ruedas) -> [String] {
        var m = Self.idsUnicos(p.ruedas.map(\.id), "ruedas")
        if !(1...5).contains(p.ruedas.count) { m.append("ruedas necesita 1–5 selectores (tiene \(p.ruedas.count))") }
        for r in p.ruedas {
            if r.opciones.count < 2 { m.append("la rueda «\(r.id)» necesita al menos 2 opciones") }
            if Set(r.opciones).count != r.opciones.count { m.append("la rueda «\(r.id)» tiene opciones repetidas") }
            if !r.opciones.contains(r.correcta) { m.append("la rueda «\(r.id)» no incluye su opción correcta «\(r.correcta)»") }
        }
        return m
    }

    private func validarConstruir(_ p: Payload.Construir) -> [String] {
        var m = Self.idsUnicos(p.huecos.map(\.id), "huecos") + Self.idsUnicos(p.piezas.map(\.id), "piezas")
        let piezas = Set(p.piezas.map(\.id))
        for h in p.huecos where !piezas.contains(h.correcta) {
            m.append("el hueco «\(h.id)» apunta a una pieza inexistente «\(h.correcta)»")
        }
        let enPlantilla = p.huecosEnPlantilla
        if Set(enPlantilla) != Set(p.huecos.map(\.id)) || enPlantilla.count != p.huecos.count {
            m.append("los huecos de la plantilla ({…}) no coinciden con la lista de huecos")
        }
        if p.huecos.isEmpty { m.append("construir no tiene huecos") }
        return m
    }

    private func validarNumerico(_ p: Payload.Numerico) -> [String] {
        guard let r = Racional.interpretar(p.respuesta) else {
            return ["la respuesta numérica «\(p.respuesta)» no se puede interpretar (usa coma decimal o a/b)"]
        }
        var m: [String] = []
        switch (p.formato, r.formato) {
        case (.entero, .entero), (.decimal, .decimal), (.decimal, .entero), (.fraccion, .fraccion): break
        default: m.append("la respuesta «\(p.respuesta)» no tiene el formato «\(p.formato.rawValue)»")
        }
        if p.formato == .fraccion, p.exigeIrreducible == true, !r.irreducible {
            m.append("la respuesta «\(p.respuesta)» no es una fracción irreducible")
        }
        if let t = p.tolerancia, t < 0 || !t.isFinite { m.append("tolerancia no válida") }
        return m
    }

    // MARK: - Teoría y simulacros

    func validar(tarjeta: TarjetaTeoria, competencias: Set<String>) -> [ErrorValidacion] {
        var m: [String] = []
        if !Self.coincide(tarjeta.id, Self.escapar(tarjeta.competencia) + "\\.T[0-9]{2}") {
            m.append("el id debe tener el formato <competencia>.TNN")
        }
        if !competencias.contains(tarjeta.competencia) { m.append("la competencia \(tarjeta.competencia) no existe en el catálogo") }
        if tarjeta.titulo.isEmpty { m.append("título vacío") }
        if tarjeta.bloques.isEmpty { m.append("la tarjeta no tiene bloques") }
        for (i, b) in tarjeta.bloques.enumerated() {
            if b.contenido.isEmpty { m.append("bloque \(i + 1) vacío") }
            if b.tipo == .texto || b.tipo == .regla {
                let palabras = Self.contarPalabras(b.contenido)
                if palabras > Self.maxPalabrasBloqueTeoria {
                    m.append("el bloque \(i + 1) (\(b.tipo.rawValue)) tiene \(palabras) palabras (máximo \(Self.maxPalabrasBloqueTeoria))")
                }
            }
        }
        m += validar(procedencia: tarjeta.procedencia) + validar(validacion: tarjeta.validacion)
        return m.map { ErrorValidacion(elemento: tarjeta.id, mensaje: $0) }
    }

    func validar(simulacro: Simulacro, competencias: Set<String>) -> [ErrorValidacion] {
        var m: [String] = []
        if !Self.coincide(simulacro.id, "SIM\\.[0-9]{2}") { m.append("el id debe tener el formato SIM.NN") }
        if simulacro.titulo.isEmpty { m.append("título vacío") }
        if simulacro.duracionMin <= 0 { m.append("duración no válida") }
        if simulacro.preguntas.isEmpty { m.append("el simulacro no tiene preguntas") }
        let numeros = simulacro.preguntas.map(\.numero)
        if numeros != Array(stride(from: 1, through: numeros.count, by: 1)) {
            m.append("las preguntas deben numerarse 1, 2, 3… en orden")
        }
        for p in simulacro.preguntas {
            if !["LEN", "MAT"].contains(p.area) { m.append("pregunta \(p.numero): área «\(p.area)» no válida") }
            if p.enunciado.isEmpty || p.solucionModelo.isEmpty { m.append("pregunta \(p.numero): enunciado o solución vacíos") }
            if p.puntos <= 0 { m.append("pregunta \(p.numero): puntos no válidos") }
            if p.rubrica.bien.isEmpty || p.rubrica.regular.isEmpty || p.rubrica.mal.isEmpty {
                m.append("pregunta \(p.numero): rúbrica incompleta")
            }
            for c in p.competencias where !competencias.contains(c) {
                m.append("pregunta \(p.numero): la competencia \(c) no existe en el catálogo")
            }
        }
        if let base = simulacro.textoBase {
            if base.texto.isEmpty { m.append("texto base vacío") }
            m += validar(procedencia: base.procedencia).map { "texto base: \($0)" }
        }
        m += validar(validacion: simulacro.validacion)
        return m.map { ErrorValidacion(elemento: simulacro.id, mensaje: $0) }
    }

    // MARK: - Metadatos

    func validar(procedencia p: Procedencia) -> [String] {
        var m: [String] = []
        if !Procedencia.licenciasValidas.contains(p.licencia) {
            m.append("licencia «\(p.licencia)» no válida (propia | dominio publico)")
        }
        switch p.tipo {
        case .original:
            if p.licencia != "propia" { m.append("el contenido original debe tener licencia «propia»") }
        case .dominioPublico:
            if (p.autorTexto ?? "").isEmpty { m.append("dominio público sin autorTexto") }
            if (p.fuente ?? "").isEmpty { m.append("dominio público sin fuente") }
            if p.licencia != "dominio publico" { m.append("el dominio público debe tener licencia «dominio publico»") }
            if let anio = p.anioMuerteAutor {
                if anioActual - anio <= Self.aniosDominioPublico {
                    m.append("el autor murió en \(anio): no han pasado más de \(Self.aniosDominioPublico) años")
                }
            } else {
                m.append("dominio público sin anioMuerteAutor")
            }
        }
        return m
    }

    func validar(validacion v: Validacion) -> [String] {
        guard v.estado == .aprobado else { return [] }
        var m: [String] = []
        if (v.revisor ?? "").isEmpty { m.append("aprobado sin revisor") }
        if !Self.coincide(v.fecha ?? "", "[0-9]{4}-[0-9]{2}-[0-9]{2}") { m.append("aprobado sin fecha AAAA-MM-DD") }
        return m
    }

    // MARK: - Auxiliares

    static func contarPalabras(_ texto: String) -> Int {
        texto.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    static func coincide(_ texto: String, _ patron: String) -> Bool {
        texto.range(of: "^" + patron + "$", options: .regularExpression) != nil
    }

    static func escapar(_ texto: String) -> String {
        NSRegularExpression.escapedPattern(for: texto)
    }

    private static func idsUnicos(_ ids: [String], _ nombre: String) -> [String] {
        var m: [String] = []
        if ids.contains(where: \.isEmpty) { m.append("hay ids vacíos en \(nombre)") }
        if Set(ids).count != ids.count { m.append("hay ids repetidos en \(nombre)") }
        return m
    }
}
