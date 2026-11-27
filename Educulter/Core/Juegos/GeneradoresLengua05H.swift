import Foundation

// Generadores de la Fase 05H con los datos aprobados de la dirección (ANEXOS A y B): Fábrica de
// palabras (`formacion.json`), recursos literarios (`recursos.json`) y glosario (`glosario.json`).
// Todos configuran mecánicas existentes; el oráculo de los tests son los propios datos.

// MARK: - Datos

/// Texto acortado a `n` caracteres como mucho, por palabras, con «…».
func abreviar(_ s: String, _ n: Int) -> String {
    guard s.count > n else { return s }
    var r = ""
    for w in s.split(separator: " ") {
        guard r.count + w.count + 2 <= n else { break }
        r += (r.isEmpty ? "" : " ") + w
    }
    return r.trimmingCharacters(in: CharacterSet(charactersIn: ",;:")) + "…"
}

struct BancoFormacion: Codable, Sendable, Equatable {
    struct Pieza: Codable, Sendable, Equatable {
        /// prefijo, lexema, sufijo o morfema (de género).
        var clase: String
        var texto: String
        /// Forma de partida si la pieza cambia en la palabra (pelo → peli-).
        var base: String?
    }

    struct Palabra: Codable, Sendable, Equatable {
        var palabra: String
        /// primitiva, derivada, compuesta o parasintetica.
        var tipo: String
        var piezas: [Pieza]
        var base: String
        var definicion: String
        /// Compuestas con el primer elemento alterado o con sonidos fundidos: solo `clasificar`.
        var soloClasificar: Bool
    }

    struct Familia: Codable, Sendable, Equatable {
        var primitiva: String
        var miembros: [String]
        /// Parecido formal sin relación de significado (los únicos distractores).
        var falsas: [String]
    }

    var version: Int
    var palabras: [Palabra]
    var familias: [Familia]

    static let nombresTipo = ["primitiva": "Primitiva", "derivada": "Derivada", "compuesta": "Compuesta", "parasintetica": "Parasintética"]

    /// Texto con que se ve una pieza: «des-», «zapat», «-ero».
    static func vista(_ p: Pieza) -> String {
        switch p.clase {
        case "prefijo": p.texto + "-"
        case "sufijo", "morfema": "-" + p.texto
        default: p.texto
        }
    }

    /// Justificación tras corregir: «derivada: lexema lech- + sufijo -ero».
    static func justificacion(_ w: Palabra) -> String {
        let piezas = w.piezas.map { p -> String in
            let nombre = p.clase == "morfema" ? "morfema de género" : p.clase
            let forma: String = switch p.clase {
            case "prefijo": p.texto + "-"
            case "sufijo", "morfema": "-" + p.texto
            default: w.piezas.count > 1 && w.tipo != "compuesta" ? p.texto + "-" : p.texto
            }
            return p.base.map { "\(nombre) \($0) (\(forma)-)" } ?? "\(nombre) \(forma)"
        }
        return "\(w.palabra): \(nombresTipo[w.tipo]!.lowercased()) (\(piezas.joined(separator: " + ")))"
    }
}

struct BancoRecursos: Codable, Sendable, Equatable {
    struct Ejemplo: Codable, Sendable, Equatable {
        var texto: String
        /// Zonas donde está el recurso (en orden de aparición).
        var marcas: [String]
    }

    struct Recurso: Codable, Sendable, Equatable {
        var recurso: String
        var definicion: String
        var ejemplos: [Ejemplo]
        /// Recursos también presentes en sus ejemplos: nunca salen como distractores.
        var tambien: [String]
    }

    var version: Int
    var recursos: [Recurso]
}

struct BancoGlosario: Codable, Sendable, Equatable {
    struct Termino: Codable, Sendable, Equatable {
        var termino: String
        var grupo: String
        var definicion: String
    }

    var version: Int
    var terminos: [Termino]
}

// MARK: - Fábrica de palabras

/// Fábrica de palabras (05H §5, D-126). `parametros.modo`: `clasificar` (4 palabras por su
/// formación), `construir` (la palabra a partir de su definición; `parametros.tipos` elige derivadas
/// o compuestas), `segmentar` (límites entre morfemas, letra a letra) o `familia` (familia léxica).
struct GeneradorFormacion: GeneradorItems {
    let tipo = "formacion"
    let mecanicas: Set<Mecanica> = [.clasificar, .construir, .segmentar]
    let marcadores: Set<String> = ["definicion", "primitiva", "contexto"]

    static let pistaClasificar = "Busca el lexema y mira qué lleva alrededor: solo, primitiva; con prefijo o sufijo, derivada; dos lexemas, compuesta; prefijo y sufijo a la vez, parasintética."
    static let pistaFamilia = "Se parece por la forma, pero ¿comparte el lexema y el significado?"

    static func sinTildes(_ s: String) -> String { s.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES")).lowercased() }

    /// Palabras reales conocidas: las del anexo, las familias y el léxico.
    static func conocidas(_ b: BancoFormacion, lexico: [EntradaLexico]) -> Set<String> {
        var s = Set(b.palabras.map { sinTildes($0.palabra) })
        for f in b.familias { s.formUnion(([f.primitiva] + f.miembros + f.falsas).map(sinTildes)) }
        s.formUnion(lexico.map { sinTildes($0.palabra) })
        return s
    }

    /// Ninguna ordenación de `n` piezas del conjunto, salvo la de la palabra, forma una palabra conocida.
    static func sinPalabraReal(_ piezas: [String], n: Int, objetivo: String, conocidas: Set<String>) -> Bool {
        var vistos = Set<String>()
        func recorrer(_ usadas: [Int]) -> Bool {
            if usadas.count == n {
                let w = sinTildes(usadas.map { piezas[$0] }.joined())
                guard vistos.insert(w).inserted else { return true }
                return w == sinTildes(objetivo) || !conocidas.contains(w)
            }
            for i in piezas.indices where !usadas.contains(i) { if !recorrer(usadas + [i]) { return false } }
            return true
        }
        return recorrer([])
    }

    func banco(_ r: RecursosGeneradores) throws -> BancoFormacion {
        guard let b = r.formacion, !b.palabras.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        return b
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let b = try banco(recursos)
        let modo = p.textos("modo", porDefecto: ["clasificar"]).first ?? "clasificar"
        switch modo {
        case "construir": return try construir(p, b, recursos: recursos, rng: &rng)
        case "segmentar": return try segmentar(p, b, rng: &rng)
        case "familia": return try familia(p, b, rng: &rng)
        default: return try clasificar(p, b, rng: &rng)
        }
    }

    private func clasificar(_ p: Plantilla, _ b: BancoFormacion, rng: inout GeneradorConSemilla) throws -> Muestra {
        // 4 palabras de al menos tantos tipos como diga la dificultad (2–4).
        let tipos = min(4, max(2, p.dificultad))
        let elegidosTipos = Array(rng.barajar(Array(BancoFormacion.nombresTipo.keys).sorted()).prefix(tipos))
        var palabras: [BancoFormacion.Palabra] = elegidosTipos.map { t in rng.elemento(b.palabras.filter { $0.tipo == t }) }
        for w in rng.barajar(b.palabras.filter { elegidosTipos.contains($0.tipo) }) where palabras.count < 4 && !palabras.contains(w) { palabras.append(w) }
        guard palabras.count == 4 else { throw ErrorGenerador.sinRecursos(tipo) }
        let categorias = ["primitiva", "derivada", "compuesta", "parasintetica"].map { ElementoNombre(id: $0, nombre: BancoFormacion.nombresTipo[$0]!) }
        let fichas = palabras.enumerated().map { Payload.Clasificar.Ficha(id: "f\($0.offset + 1)", texto: $0.element.palabra, categoria: $0.element.tipo) }
        return Muestra(clave: "clasificar|" + palabras.map(\.palabra).sorted().joined(separator: ","), valores: [:],
                       payload: .clasificar(Payload.Clasificar(categorias: categorias, fichas: rng.barajar(fichas))),
                       explicacion: palabras.map(BancoFormacion.justificacion).joined(separator: "; ") + ".",
                       erroresHabituales: fichas.map { ErrorHabitual(respuesta: $0.id, feedback: Self.pistaClasificar) },
                       pistas: [Self.pistaClasificar], complejidad: Double(Set(palabras.map(\.tipo)).count) + Double(p.dificultad) * 0.5,
                       datos: ["palabras": palabras.map { "\($0.palabra)=\($0.tipo)" }.joined(separator: ";")], juego: "Fabrica")
    }

    private func construir(_ p: Plantilla, _ b: BancoFormacion, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let tipos = Set(p.textos("tipos", porDefecto: ["derivada", "parasintetica"]))
        let candidatas = b.palabras.filter { tipos.contains($0.tipo) && !$0.soloClasificar && $0.piezas.count >= 2 }
        guard !candidatas.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let conocidas = Self.conocidas(b, lexico: recursos.lexico)
        for _ in 0..<40 {
            let w = rng.elemento(candidatas)
            let clases = Set(w.piezas.map(\.clase))
            let todas = b.palabras.filter { $0.palabra != w.palabra && !$0.soloClasificar }.flatMap(\.piezas)
            // Primero, piezas de una clase que la palabra no tiene (no encajan en sus huecos).
            let ajenas = todas.filter { !clases.contains($0.clase) && $0.clase != "morfema" }
            let mismas = todas.filter { clases.contains($0.clase) && $0.clase != "morfema" }
            var pool: [BancoFormacion.Pieza] = []
            for x in rng.barajar(ajenas) + rng.barajar(mismas) where !pool.contains(where: { $0.texto == x.texto }) && !w.piezas.contains(where: { $0.texto == x.texto }) {
                pool.append(x)
            }
            var distractores: [BancoFormacion.Pieza] = []
            for d in pool where distractores.count < 2 {
                let prueba = (w.piezas + distractores + [d]).map(\.texto)
                if Self.sinPalabraReal(prueba, n: w.piezas.count, objetivo: w.palabra, conocidas: conocidas) { distractores.append(d) }
            }
            guard distractores.count == 2 else { continue }
            let todasPiezas = rng.barajar(w.piezas + distractores).enumerated().map { ElementoTexto(id: "p\($0.offset + 1)", texto: BancoFormacion.vista($0.element)) }
            var libres = todasPiezas
            var huecos: [Payload.Construir.Hueco] = []
            for (k, pz) in w.piezas.enumerated() {
                guard let i = libres.firstIndex(where: { $0.texto == BancoFormacion.vista(pz) }) else { break }
                huecos.append(.init(id: "h\(k + 1)", correcta: libres.remove(at: i).id))
            }
            guard huecos.count == w.piezas.count else { continue }
            let plantilla = huecos.map { "{\($0.id)}" }.joined(separator: " + ")
            return Muestra(clave: "construir|\(w.palabra)|" + distractores.map(\.texto).sorted().joined(separator: ","),
                           valores: ["definicion": w.definicion],
                           payload: .construir(Payload.Construir(plantilla: plantilla, huecos: huecos, piezas: todasPiezas)),
                           explicacion: "«\(w.palabra)» (\(w.definicion)): " + BancoFormacion.justificacion(w).components(separatedBy: ": ").dropFirst().joined(separator: ": ") + ".",
                           pistas: ["Piensa primero en la palabra de la que viene: «\(w.base)»."],
                           complejidad: Double(w.piezas.count) + Double(p.dificultad) * 0.5,
                           datos: ["palabra": w.palabra, "distractores": distractores.map(\.texto).joined(separator: ",")], juego: "Fabrica")
        }
        throw ErrorGenerador.sinRecursos(tipo)
    }

    private func segmentar(_ p: Plantilla, _ b: BancoFormacion, rng: inout GeneradorConSemilla) throws -> Muestra {
        let candidatas = b.palabras.filter { w in
            !w.soloClasificar && w.piezas.count >= 2 && w.tipo != "compuesta" && w.piezas.map(\.texto).joined() == w.palabra
        }
        guard !candidatas.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let w = rng.elemento(candidatas)
        let letras = Array(w.palabra).enumerated().map { ElementoTexto(id: "l\($0.offset + 1)", texto: String($0.element)) }
        let nombres = ["prefijo": "Prefijo", "lexema": "Lexema", "sufijo": "Sufijo", "morfema": "Morfema de género"]
        let usadas = ["prefijo", "lexema", "sufijo", "morfema"].filter { c in w.piezas.contains { $0.clase == c } }
        var segmentos: [Payload.Segmentar.Segmento] = []
        var i = 0
        for (k, pz) in w.piezas.enumerated() {
            let n = pz.texto.count
            segmentos.append(.init(id: "s\(k + 1)", desde: letras[i].id, hasta: letras[i + n - 1].id, etiqueta: pz.clase, padre: nil))
            i += n
        }
        return Muestra(clave: "segmentar|\(w.palabra)", valores: [:],
                       payload: .segmentar(Payload.Segmentar(tokens: letras, etiquetas: usadas.map { ElementoNombre(id: $0, nombre: nombres[$0]!) }, segmentos: segmentos)),
                       explicacion: w.piezas.map { "\(nombres[$0.clase]!.lowercased()) «\($0.texto)»" }.joined(separator: " | ") + ".",
                       pistas: ["Busca primero el lexema, la parte que comparte con «\(w.base)»."],
                       complejidad: Double(w.piezas.count) + Double(w.palabra.count) * 0.1 + Double(p.dificultad) * 0.5,
                       datos: ["palabra": w.palabra], juego: "Fabrica")
    }

    private func familia(_ p: Plantilla, _ b: BancoFormacion, rng: inout GeneradorConSemilla) throws -> Muestra {
        let familias = b.familias.filter { $0.miembros.count >= 2 && !$0.falsas.isEmpty }
        guard !familias.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let f = rng.elemento(familias)
        let miembros = Array(rng.barajar(f.miembros).prefix(3))
        let fichas = (miembros.map { ($0, "si") } + f.falsas.prefix(1).map { ($0, "no") }).enumerated()
            .map { Payload.Clasificar.Ficha(id: "f\($0.offset + 1)", texto: $0.element.0, categoria: $0.element.1) }
        let falsa = f.falsas[0]
        return Muestra(clave: "familia|\(f.primitiva)|" + miembros.sorted().joined(separator: ","), valores: ["primitiva": f.primitiva],
                       payload: .clasificar(Payload.Clasificar(categorias: [ElementoNombre(id: "si", nombre: "De la familia de «\(f.primitiva)»"),
                                                                            ElementoNombre(id: "no", nombre: "No es de la familia")],
                                                               fichas: rng.barajar(fichas))),
                       explicacion: "\(miembros.map { "«\($0)»" }.joined(separator: ", ")) comparten el lexema y el significado de «\(f.primitiva)»; «\(falsa)» solo se le parece por la forma.",
                       erroresHabituales: fichas.filter { $0.categoria == "no" }.map { ErrorHabitual(respuesta: $0.id, feedback: Self.pistaFamilia) },
                       pistas: [Self.pistaFamilia], complejidad: Double(miembros.count) + Double(p.dificultad) * 0.5,
                       datos: ["primitiva": f.primitiva], juego: "Fabrica")
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

// MARK: - Recursos literarios

/// Recursos literarios (05H §6, D-127). `parametros.modo`: `emparejar` (recurso ↔ definición, 4),
/// `eleccion` («¿Qué recurso hay?») o `detective` (tocar las palabras donde está el recurso). Los
/// recursos que también están en un ejemplo nunca salen como distractores.
struct GeneradorRecursos: GeneradorItems {
    let tipo = "recursos"
    let mecanicas: Set<Mecanica> = [.emparejar, .eleccion, .marcarTexto, .recuerdo]
    let marcadores: Set<String> = ["ejemplo", "recurso", "contexto"]

    /// Criterios de autoevaluación de una definición (propios de la app, 05I).
    static let criteriosDefinicion = ["Dice qué es: su tipo o su clase", "Explica su rasgo propio (qué hace o cómo es)",
                                      "Se entiende sin repetir el nombre del término"]

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let b = recursos.recursosLiterarios, b.recursos.count >= 4 else { throw ErrorGenerador.sinRecursos(tipo) }
        let modo = p.textos("modo", porDefecto: ["eleccion"]).first ?? "eleccion"
        switch modo {
        case "definir":
            // Simulacro (05I): definir con palabras propias y autoevaluarse con la definición del anexo.
            let r = rng.elemento(b.recursos)
            return Muestra(clave: "definir|\(r.recurso)", valores: ["recurso": r.recurso],
                           payload: .recuerdo(Payload.Recuerdo(modelo: "\(r.recurso.prefix(1).uppercased() + r.recurso.dropFirst()): \(r.definicion). Ejemplo: «\(r.ejemplos[0].texto)»",
                                                              criterios: Self.criteriosDefinicion, maximo: 300)),
                           explicacion: "\(r.recurso.prefix(1).uppercased() + r.recurso.dropFirst()): \(abreviar(r.definicion, 200)).",
                           complejidad: 3 + Double(p.dificultad), datos: ["recurso": r.recurso], juego: "Recursos")
        case "emparejar":
            let elegidos = Array(rng.barajar(b.recursos).prefix(4))
            let izq = elegidos.enumerated().map { ElementoTexto(id: "i\($0.offset + 1)", texto: $0.element.recurso) }
            let der = elegidos.enumerated().map { ElementoTexto(id: "d\($0.offset + 1)", texto: $0.element.definicion) }
            return Muestra(clave: "emparejar|" + elegidos.map(\.recurso).sorted().joined(separator: ","), valores: [:],
                           payload: .emparejar(Payload.Emparejar(izquierda: izq, derecha: rng.barajar(der), pares: izq.indices.map { [izq[$0].id, der[$0].id] })),
                           explicacion: elegidos.map { "\($0.recurso.prefix(1).uppercased() + $0.recurso.dropFirst()): \(abreviar($0.definicion, 50))." }.joined(separator: " "),
                           complejidad: 2 + Double(p.dificultad) * 0.5, datos: ["recursos": elegidos.map(\.recurso).joined(separator: ";")], juego: "Recursos")
        case "detective":
            let casos = b.recursos.flatMap { r in r.ejemplos.map { (r, $0) } }.compactMap { r, e -> (BancoRecursos.Recurso, [ElementoTexto], [String])? in
                guard let (tokens, correctos) = Self.tokens(e), !correctos.isEmpty, correctos.count < tokens.count else { return nil }
                return (r, tokens, correctos)
            }
            guard !casos.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
            let (r, tokens, correctos) = rng.elemento(casos)
            return Muestra(clave: "detective|\(tokens.map(\.texto).joined(separator: " "))", valores: ["recurso": r.recurso],
                           payload: .marcarTexto(Payload.MarcarTexto(unidad: .palabra, tokens: tokens, correctos: correctos)),
                           explicacion: "\(r.recurso.prefix(1).uppercased() + r.recurso.dropFirst()): \(r.definicion). Está en «\(tokens.filter { correctos.contains($0.id) }.map(\.texto).joined(separator: " "))».",
                           pistas: ["Recuerda: «\(r.recurso)» \(r.definicion)."], complejidad: Double(tokens.count) * 0.2 + Double(p.dificultad),
                           datos: ["recurso": r.recurso, "marcas": correctos.joined(separator: ",")], juego: "Detective")
        default:
            let casos = b.recursos.flatMap { r in r.ejemplos.map { (r, $0) } }
            let (r, e) = rng.elemento(casos)
            let excluidos = Set(r.tambien + [r.recurso])
            let distractores = rng.barajar(b.recursos.filter { !excluidos.contains($0.recurso) }).prefix(3)
                .map { ($0.recurso, "«\($0.recurso.prefix(1).uppercased() + $0.recurso.dropFirst())»: \($0.definicion).") }
            let (eleccion, errores) = Opciones.eleccion(correcta: r.recurso, distractores: Array(distractores), maximo: 4, rng: &rng)
            return Muestra(clave: "eleccion|\(e.texto)", valores: ["ejemplo": e.texto], payload: .eleccion(eleccion),
                           explicacion: "\(r.recurso.prefix(1).uppercased() + r.recurso.dropFirst()): \(r.definicion). Está en «\(e.marcas.joined(separator: "… "))».",
                           erroresHabituales: errores, pistas: ["Fíjate en lo que se repite, se compara o se exagera."],
                           complejidad: 2 + Double(p.dificultad) * 0.5, datos: ["recurso": r.recurso, "tambien": r.tambien.joined(separator: ";")], juego: "Recursos")
        }
    }

    /// Palabras del ejemplo y las que caen dentro de sus marcas (en orden de aparición).
    static func tokens(_ e: BancoRecursos.Ejemplo) -> ([ElementoTexto], [String])? {
        let texto = e.texto
        var rangos: [Range<String.Index>] = []
        var desde = texto.startIndex
        for m in e.marcas {
            guard let r = texto.range(of: m, range: desde..<texto.endIndex) else { return nil }
            rangos.append(r)
            desde = r.upperBound
        }
        var tokens: [ElementoTexto] = [], correctos: [String] = []
        var i = texto.startIndex
        var k = 0
        while i < texto.endIndex {
            guard texto[i] != " " else { i = texto.index(after: i); continue }
            let fin = texto[i...].firstIndex(of: " ") ?? texto.endIndex
            k += 1
            let id = "t\(k)"
            tokens.append(ElementoTexto(id: id, texto: String(texto[i..<fin])))
            // Dentro de una marca si alguna de sus letras lo está.
            let letras = texto.indices.filter { $0 >= i && $0 < fin && texto[$0].isLetter }
            if letras.contains(where: { l in rangos.contains { $0.contains(l) } }) { correctos.append(id) }
            i = fin
        }
        return (tokens, correctos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

// MARK: - Glosario

/// Glosario de términos lingüísticos (05H §6, D-127): término ↔ definición (`emparejar`, hasta 4) y
/// «¿A qué término corresponde esta definición?» (`eleccion`). `parametros.grupo` elige el grupo; los
/// distractores son siempre del mismo grupo.
struct GeneradorGlosario: GeneradorItems {
    let tipo = "glosario"
    let mecanicas: Set<Mecanica> = [.emparejar, .eleccion, .recuerdo]
    let marcadores: Set<String> = ["definicion", "termino", "contexto"]

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let b = recursos.glosario else { throw ErrorGenerador.sinRecursos(tipo) }
        let grupo = p.textos("grupo", porDefecto: ["clases de palabras"]).first ?? ""
        let terminos = b.terminos.filter { $0.grupo == grupo }
        guard terminos.count >= 3 else { throw ErrorGenerador.sinRecursos(tipo) }
        if p.mecanica == .recuerdo {
            // Simulacro (05I): definir el término y autoevaluarse con la definición del anexo.
            let t = rng.elemento(terminos)
            return Muestra(clave: "definir|\(t.termino)", valores: ["termino": t.termino],
                           payload: .recuerdo(Payload.Recuerdo(modelo: "\(t.termino.prefix(1).uppercased() + t.termino.dropFirst()): \(t.definicion).",
                                                              criterios: GeneradorRecursos.criteriosDefinicion, maximo: 300)),
                           explicacion: "\(t.termino.prefix(1).uppercased() + t.termino.dropFirst()): \(t.definicion).",
                           complejidad: 3 + Double(p.dificultad), datos: ["termino": t.termino, "grupo": grupo], juego: "Glosario")
        }
        if p.mecanica == .emparejar {
            let elegidos = Array(rng.barajar(terminos).prefix(4))
            let izq = elegidos.enumerated().map { ElementoTexto(id: "i\($0.offset + 1)", texto: $0.element.termino) }
            let der = elegidos.enumerated().map { ElementoTexto(id: "d\($0.offset + 1)", texto: $0.element.definicion) }
            return Muestra(clave: "emparejar|" + elegidos.map(\.termino).sorted().joined(separator: ","), valores: [:],
                           payload: .emparejar(Payload.Emparejar(izquierda: izq, derecha: rng.barajar(der), pares: izq.indices.map { [izq[$0].id, der[$0].id] })),
                           explicacion: elegidos.map { "\($0.termino.prefix(1).uppercased() + $0.termino.dropFirst()): \(abreviar($0.definicion, 50))." }.joined(separator: " "),
                           complejidad: Double(elegidos.count) * 0.5 + Double(p.dificultad) * 0.5, datos: ["grupo": grupo], juego: "Glosario")
        }
        let t = rng.elemento(terminos)
        let distractores = rng.barajar(terminos.filter { $0.termino != t.termino }).prefix(3)
            .map { ($0.termino, "«\($0.termino.prefix(1).uppercased() + $0.termino.dropFirst())»: \($0.definicion).") }
        let (eleccion, errores) = Opciones.eleccion(correcta: t.termino, distractores: Array(distractores), maximo: 4, rng: &rng)
        return Muestra(clave: "eleccion|\(t.termino)", valores: ["definicion": t.definicion], payload: .eleccion(eleccion),
                       explicacion: "\(t.termino.prefix(1).uppercased() + t.termino.dropFirst()): \(t.definicion).",
                       erroresHabituales: errores, complejidad: 2 + Double(p.dificultad) * 0.5, datos: ["termino": t.termino, "grupo": grupo], juego: "Glosario")
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
