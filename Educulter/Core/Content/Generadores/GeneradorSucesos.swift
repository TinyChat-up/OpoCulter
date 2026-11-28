import Foundation

/// Tipos de sucesos (MAT.PRO.SUCESOS, Fase 05K §2). Experimentos: dado de 6 caras, ruleta de n
/// sectores (4–10), urna de bolas de colores y baraja española de 40 cartas.
///
/// Plantillas (parámetro `pregunta`):
/// - `espacio` (marcarTexto): tocar todos los resultados posibles;
/// - `clasificar` (clasificar): 4 sucesos en seguro, posible o imposible;
/// - `contrario` (eleccion): el contrario de un suceso; distractores, subconjuntos del contrario y
///   sucesos que comparten resultados con el dado;
/// - `compatibles` (eleccion): si dos sucesos pueden ocurrir a la vez.
///
/// Cada suceso lleva una especificación (`par`, `mayor:3`, `palo:oros&!figura`…) con la que se
/// calcula su conjunto de resultados; el oráculo de los tests la interpreta por su cuenta.
///
/// | Nivel | Experimento |
/// |---|---|
/// | 1 | dado |
/// | 2 | ruleta de 4 a 10 sectores |
/// | 3 | urna de bolas de colores |
/// | 4 | baraja española (sucesos simples) |
/// | 5 | baraja o ruleta con sucesos compuestos (y, o, que no sea) |
/// | 6 | sucesos compuestos de cualquier experimento; espacio muestral de dos monedas |
struct GeneradorSucesos: GeneradorItems {
    let tipo = "sucesos"
    let mecanicas: Set<Mecanica> = [.marcarTexto, .clasificar, .eleccion]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    static let palos = ["oros", "copas", "espadas", "bastos"]
    static let valores = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]
    static let nombresValor = [1: "as", 10: "sota", 11: "caballo", 12: "rey"]

    struct Suceso: Equatable {
        var spec: String
        var texto: String
    }

    struct Experimento {
        /// `dado`, `ruleta:8`, `urna:roja,azul`, `baraja`.
        var id: String
        var enunciado: String
        var verbo: String
        var omega: [String]
        var sucesos: [Suceso]
        /// Contrario natural de algunos sucesos (spec → texto).
        var contrarios: [String: Suceso]
    }

    // MARK: Experimentos

    static func numerico(n: Int, compuestos: Bool) -> Experimento {
        let id = n == 6 ? "dado" : "ruleta:\(n)"
        let enunciado = n == 6 ? "Se lanza un dado de seis caras." : "Se gira una ruleta de \(n) sectores iguales numerados del 1 al \(n)."
        var s = [Suceso(spec: "par", texto: "un número par"), Suceso(spec: "impar", texto: "un número impar")]
        var contrarios: [String: Suceso] = ["par": Suceso(spec: "impar", texto: "un número impar"), "impar": Suceso(spec: "par", texto: "un número par")]
        for k in 2..<n {
            s.append(Suceso(spec: "mayor:\(k)", texto: "un número mayor que \(k)"))
            s.append(Suceso(spec: "menor:\(k)", texto: "un número menor que \(k)"))
            contrarios["mayor:\(k)"] = Suceso(spec: "menor:\(k + 1)", texto: "un número menor o igual que \(k)")
            contrarios["menor:\(k)"] = Suceso(spec: "mayor:\(k - 1)", texto: "un número mayor o igual que \(k)")
        }
        for k in 1...n {
            s.append(Suceso(spec: "igual:\(k)", texto: "un \(k)"))
            contrarios["igual:\(k)"] = Suceso(spec: "!igual:\(k)", texto: "un número distinto de \(k)")
        }
        s.append(Suceso(spec: "mult:3", texto: "un múltiplo de 3"))
        contrarios["mult:3"] = Suceso(spec: "!mult:3", texto: "un número que no sea múltiplo de 3")
        // Seguros e imposibles.
        s += [Suceso(spec: "entre:1:\(n)", texto: "un número del 1 al \(n)"), Suceso(spec: "menor:\(n + 1)", texto: "un número menor que \(n + 1)"),
              Suceso(spec: "igual:0", texto: "un 0"), Suceso(spec: "mayor:\(n)", texto: "un número mayor que \(n)"),
              Suceso(spec: "igual:\(n + 1)", texto: "un \(n + 1)")]
        if compuestos {
            for k in 2..<(n - 1) {
                s.append(Suceso(spec: "par&mayor:\(k)", texto: "un número par mayor que \(k)"))
                s.append(Suceso(spec: "impar&menor:\(k + 1)", texto: "un número impar menor que \(k + 1)"))
                s.append(Suceso(spec: "igual:1|mayor:\(k)", texto: "un 1 o un número mayor que \(k)"))
            }
        }
        return Experimento(id: id, enunciado: enunciado, verbo: "Salir", omega: (1...n).map(String.init), sucesos: s, contrarios: contrarios)
    }

    static let colores = ["roja", "azul", "verde", "amarilla"]
    static let ausentes = ["negra", "blanca", "morada"]

    static func lista(_ xs: [String]) -> String {
        xs.count <= 1 ? (xs.first ?? "") : xs.dropLast().joined(separator: ", ") + " o " + xs.last!
    }

    static func urna(rng: inout GeneradorConSemilla, compuestos: Bool) -> Experimento {
        let k = rng.entero(2...3)
        let presentes = Array(rng.barajar(colores).prefix(k)).sorted { colores.firstIndex(of: $0)! < colores.firstIndex(of: $1)! }
        let cuentas = presentes.map { _ in rng.entero(1...5) }
        let desc = zip(cuentas, presentes).map { n, c in n == 1 ? "1 bola \(c)" : "\(n) bolas \(plural(c))" }
        let enunciado = "En una urna hay \(desc.dropLast().joined(separator: ", ")) y \(desc.last!). Se saca una bola sin mirar."
        var s: [Suceso] = presentes.map { Suceso(spec: "color:\($0)", texto: "una bola \($0)") }
        var contrarios: [String: Suceso] = [:]
        for c in presentes {
            let otros = presentes.filter { $0 != c }
            contrarios["color:\(c)"] = Suceso(spec: otros.map { "color:\($0)" }.joined(separator: "|"), texto: "una bola " + lista(otros))
            s.append(Suceso(spec: "!color:\(c)", texto: "una bola que no sea \(c)"))
            contrarios["!color:\(c)"] = Suceso(spec: "color:\(c)", texto: "una bola \(c)")
        }
        if presentes.count == 3 {
            for i in 0..<3 { for j in (i + 1)..<3 {
                s.append(Suceso(spec: "color:\(presentes[i])|color:\(presentes[j])", texto: "una bola \(presentes[i]) o \(presentes[j])"))
            } }
        }
        s.append(Suceso(spec: presentes.map { "color:\($0)" }.joined(separator: "|"), texto: "una bola " + lista(presentes)))
        for a in ausentes { s.append(Suceso(spec: "color:\(a)", texto: "una bola \(a)")) }
        if compuestos { s.append(Suceso(spec: "!color:\(ausentes[0])", texto: "una bola que no sea \(ausentes[0])")) }
        return Experimento(id: "urna:" + presentes.joined(separator: ","), enunciado: enunciado, verbo: "Sacar", omega: presentes, sucesos: s, contrarios: contrarios)
    }

    static func plural(_ c: String) -> String { c == "azul" ? "azules" : c + "s" }

    static func carta(_ v: Int, _ p: String) -> String { "\(v)-\(p)" }

    static func baraja(compuestos: Bool) -> Experimento {
        var s: [Suceso] = palos.map { Suceso(spec: "palo:\($0)", texto: "una carta de \($0)") }
        var contrarios: [String: Suceso] = [:]
        for p in palos {
            let otros = palos.filter { $0 != p }
            contrarios["palo:\(p)"] = Suceso(spec: otros.map { "palo:\($0)" }.joined(separator: "|"), texto: "una carta de " + lista(otros))
        }
        s += [Suceso(spec: "valor:1", texto: "un as"), Suceso(spec: "valor:10", texto: "una sota"), Suceso(spec: "valor:11", texto: "un caballo"),
              Suceso(spec: "valor:12", texto: "un rey"), Suceso(spec: "figura", texto: "una figura (sota, caballo o rey)"),
              Suceso(spec: "entre:1:7", texto: "una carta del 1 al 7")]
        for v in 2...7 { s.append(Suceso(spec: "valor:\(v)", texto: "un \(v)")) }
        contrarios["figura"] = Suceso(spec: "entre:1:7", texto: "una carta del 1 al 7")
        contrarios["entre:1:7"] = Suceso(spec: "figura", texto: "una figura (sota, caballo o rey)")
        contrarios["valor:1"] = Suceso(spec: "!valor:1", texto: "una carta que no sea un as")
        contrarios["valor:12"] = Suceso(spec: "!valor:12", texto: "una carta que no sea un rey")
        // Seguros e imposibles (la baraja española de 40 cartas no tiene 8, 9 ni comodines).
        s += [Suceso(spec: palos.map { "palo:\($0)" }.joined(separator: "|"), texto: "una carta de oros, copas, espadas o bastos"),
              Suceso(spec: "entre:1:7|figura", texto: "una carta del 1 al 7 o una figura"),
              Suceso(spec: "valor:8", texto: "un 8"), Suceso(spec: "valor:9", texto: "un 9"), Suceso(spec: "comodin", texto: "un comodín"),
              Suceso(spec: "palo:corazones", texto: "una carta de corazones")]
        if compuestos {
            s += [Suceso(spec: "valor:1|palo:copas", texto: "un as o una carta de copas"),
                  Suceso(spec: "figura&palo:espadas", texto: "una figura de espadas"),
                  Suceso(spec: "palo:oros&!figura", texto: "una carta de oros que no sea figura"),
                  Suceso(spec: "valor:1&palo:oros", texto: "el as de oros"),
                  Suceso(spec: "valor:12|valor:1", texto: "un rey o un as"),
                  Suceso(spec: "palo:bastos&valor:8", texto: "un 8 de bastos")]
            contrarios["palo:oros&!figura"] = Suceso(spec: "palo:copas|palo:espadas|palo:bastos|figura", texto: "una figura o una carta de copas, espadas o bastos")
        }
        let omega = palos.flatMap { p in valores.map { carta($0, p) } }
        return Experimento(id: "baraja", enunciado: "Se saca una carta de una baraja española de 40 cartas (oros, copas, espadas y bastos; del 1 al 7, sota, caballo y rey).",
                           verbo: "Sacar", omega: omega, sucesos: s, contrarios: contrarios)
    }

    func experimento(_ nivel: Int, rng: inout GeneradorConSemilla) -> Experimento {
        switch nivel {
        case 1: return Self.numerico(n: 6, compuestos: false)
        case 2: return Self.numerico(n: rng.entero(4...10), compuestos: false)
        case 3: return Self.urna(rng: &rng, compuestos: false)
        case 4: return Self.baraja(compuestos: false)
        case 5: return rng.probabilidad(0.5) ? Self.baraja(compuestos: true) : Self.numerico(n: rng.entero(6...10), compuestos: true)
        default:
            switch rng.entero(0...2) {
            case 0: return Self.baraja(compuestos: true)
            case 1: return Self.urna(rng: &rng, compuestos: true)
            default: return Self.numerico(n: rng.entero(8...10), compuestos: true)
            }
        }
    }

    // MARK: Conjuntos

    /// Resultados en que ocurre el suceso. `|` separa alternativas; `&`, condiciones; `!`, negación.
    static func conjunto(_ spec: String, _ e: Experimento) -> Set<String> {
        var total = Set<String>()
        for alternativa in spec.split(separator: "|") {
            var parte = Set(e.omega)
            for condicion in alternativa.split(separator: "&") {
                let negada = condicion.hasPrefix("!")
                let atomo = negada ? String(condicion.dropFirst()) : String(condicion)
                let cumple = Set(e.omega.filter { cumpleAtomo(atomo, $0) })
                parte = parte.intersection(negada ? Set(e.omega).subtracting(cumple) : cumple)
            }
            total.formUnion(parte)
        }
        return total
    }

    static func cumpleAtomo(_ a: String, _ r: String) -> Bool {
        let p = a.split(separator: ":").map(String.init)
        if r.contains("-") {
            let partes = r.split(separator: "-").map(String.init)
            let v = Int(partes[0]) ?? 0, palo = partes[1]
            switch p[0] {
            case "palo": return palo == p[1]
            case "valor": return v == Int(p[1])
            case "figura": return v >= 10
            case "entre": return v >= Int(p[1])! && v <= Int(p[2])!
            default: return false
            }
        }
        if let n = Int(r) {
            switch p[0] {
            case "par": return n % 2 == 0
            case "impar": return n % 2 == 1
            case "mayor": return n > Int(p[1])!
            case "menor": return n < Int(p[1])!
            case "igual": return n == Int(p[1])!
            case "mult": return n % Int(p[1])! == 0
            case "entre": return n >= Int(p[1])! && n <= Int(p[2])!
            default: return false
            }
        }
        return p[0] == "color" && p[1] == r
    }

    enum Tipo: String { case seguro, posible, imposible }

    static func tipo(_ s: Set<String>, _ e: Experimento) -> Tipo {
        s.isEmpty ? .imposible : (s.count == e.omega.count ? .seguro : .posible)
    }

    /// Nombre legible de un resultado («3», «roja», «as de oros»).
    static func nombre(_ r: String) -> String {
        guard r.contains("-") else { return r }
        let partes = r.split(separator: "-").map(String.init)
        let v = Int(partes[0]) ?? 0
        return "\(nombresValor[v] ?? "\(v)") de \(partes[1])"
    }

    /// Conjunto en texto: los resultados si son pocos; si no, cuántos son.
    static func texto(_ s: Set<String>, _ e: Experimento) -> String {
        if s.isEmpty { return "ninguno" }
        let orden = e.omega.filter { s.contains($0) }
        return orden.count <= 10 ? "{" + orden.map(nombre).joined(separator: ", ") + "}" : "\(orden.count) cartas"
    }

    // MARK: Muestra

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nivel = min(max(p.dificultad, 1), 6)
        switch p.textos("pregunta", porDefecto: ["clasificar"]).first ?? "clasificar" {
        case "espacio": return espacio(nivel, rng: &rng)
        case "contrario": return try contrario(nivel, rng: &rng)
        case "compatibles": return try compatibles(nivel, rng: &rng)
        default: return try clasificar(nivel, rng: &rng)
        }
    }

    /// Espacio muestral (marcar): los resultados posibles entre otros que no pueden salir.
    func espacio(_ nivel: Int, rng: inout GeneradorConSemilla) -> Muestra {
        var enunciado: String, posibles: [String], imposibles: [String], id: String
        // Los distractores (resultados que no pueden salir) se eligen con la semilla: dan variantes
        // del mismo experimento (el ejemplo resuelto necesita un gemelo distinto).
        func algunos(_ xs: [String], _ k: Int) -> [String] { Array(rng.barajar(xs).prefix(k)) }
        switch nivel {
        case 1:
            (id, enunciado, posibles, imposibles) = ("dado", "Se lanza un dado de seis caras.", (1...6).map(String.init),
                                                     algunos(["0", "7", "8", "9", "10", "12"], rng.entero(2...3)))
        case 2:
            let n = rng.entero(4...10)
            (id, enunciado, posibles, imposibles) = ("ruleta:\(n)", "Se gira una ruleta de \(n) sectores iguales numerados del 1 al \(n).",
                                                     (1...n).map(String.init), algunos(["0"] + (1...4).map { "\(n + $0)" }, 3))
        case 3:
            let e = Self.urna(rng: &rng, compuestos: false)
            (id, enunciado, posibles, imposibles) = (e.id, e.enunciado + " Se anota su color.", e.omega, algunos(Self.ausentes, 2))
        case 4:
            (id, enunciado, posibles, imposibles) = ("baraja:palo", "Se saca una carta de una baraja española de 40 cartas y se anota su palo.",
                                                     Self.palos, algunos(["corazones", "picas", "tréboles", "diamantes"], rng.entero(2...3)))
        case 5:
            (id, enunciado, posibles, imposibles) = ("baraja:valor", "Se saca una carta de una baraja española de 40 cartas y se anota su valor, sin el palo.",
                                                     ["as", "2", "3", "4", "5", "6", "7", "sota", "caballo", "rey"], algunos(["8", "9", "comodín", "0"], rng.entero(2...3)))
        default:
            let (a, b) = rng.elemento([("1 €", "2 €"), ("10 céntimos", "50 céntimos"), ("5 céntimos", "20 céntimos")])
            (id, enunciado, posibles, imposibles) = ("monedas", "Se lanzan dos monedas, una de \(a) y otra de \(b), y se anota qué sale en cada una (primero la de \(a)).",
                                                     ["cara-cara", "cara-cruz", "cruz-cara", "cruz-cruz"], algunos(["cara", "cruz"], 2))
        }
        // Los números, en orden; el resto, mezclados.
        let juntas = posibles + imposibles
        let todas = juntas.allSatisfy { Int($0) != nil } ? juntas.sorted { Int($0)! < Int($1)! } : rng.barajar(juntas)
        let tokens = todas.enumerated().map { ElementoTexto(id: "r\($0.offset + 1)", texto: $0.element) }
        let correctos = tokens.filter { posibles.contains($0.texto) }.map(\.id)
        let payload = Payload.MarcarTexto(unidad: .palabra, tokens: tokens, correctos: correctos)
        let errores = tokens.map { t in
            posibles.contains(t.texto) ? ErrorHabitual(respuesta: t.id, feedback: "Falta «\(t.texto)»: también puede salir.")
                : ErrorHabitual(respuesta: t.id, feedback: "«\(t.texto)» no puede salir en este experimento.")
        }
        let pasos = [Pasos.dato("Piensa en todo lo que puede salir", "\(posibles.count) resultados",
                                porque: "porque el espacio muestral reúne todos los resultados posibles"),
                     Pasos.solucion("Marca solo esos resultados", payload: .marcarTexto(payload))]
        return Muestra(clave: "espacio|\(id)|" + imposibles.sorted().joined(separator: ",") + (nivel == 6 ? "|" + enunciado : ""), valores: ["pregunta": enunciado + " Toca todos los resultados posibles."],
                       payload: .marcarTexto(payload), explicacion: "El espacio muestral es {\(posibles.joined(separator: ", "))}: todos los resultados que pueden salir.",
                       erroresHabituales: errores, pistas: ["Pregúntate, ficha a ficha: ¿puede salir esto?"],
                       complejidad: Double(nivel) + Double(tokens.count) * 0.01,
                       datos: ["experimento": id, "correctos": posibles.joined(separator: "|")]).conPasos(pasos)
    }

    /// Sucesos no triviales (posibles) del experimento.
    static func posibles(_ e: Experimento, compuestos: Bool) -> [Suceso] {
        e.sucesos.filter { tipo(conjunto($0.spec, e), e) == .posible && (compuestos || (!$0.spec.contains("&") && !$0.spec.contains("|"))) }
    }

    /// Clasificar 4 sucesos en seguro, posible o imposible: al menos uno posible y, en total, los
    /// tres tipos cuando se puede.
    func clasificar(_ nivel: Int, rng: inout GeneradorConSemilla) throws -> Muestra {
        let e = experimento(nivel, rng: &rng)
        let compuestos = nivel >= 5
        var porTipo: [Tipo: [Suceso]] = [:]
        for s in e.sucesos { porTipo[Self.tipo(Self.conjunto(s.spec, e), e), default: []].append(s) }
        let posibles = Self.posibles(e, compuestos: compuestos)
        guard let seguro = porTipo[.seguro].map({ rng.elemento($0) }), let imposible = porTipo[.imposible].map({ rng.elemento($0) }),
              posibles.count >= 2 else { throw ErrorGenerador.sinCaso(tipo) }
        var elegidos = [seguro, imposible]
        // Uno o dos posibles (en los compuestos, al menos uno compuesto si lo hay).
        let compuestosPosibles = posibles.filter { $0.spec.contains("&") || $0.spec.contains("|") }
        var candidatos = rng.barajar(posibles)
        if compuestos, let c = compuestosPosibles.first.map({ _ in rng.elemento(compuestosPosibles) }) { candidatos.insert(c, at: 0) }
        for s in candidatos where elegidos.count < 4 && !elegidos.contains(where: { $0.texto == s.texto }) { elegidos.append(s) }
        elegidos = rng.barajar(elegidos)
        let categorias = [ElementoNombre(id: "seguro", nombre: "Seguro"), ElementoNombre(id: "posible", nombre: "Posible"),
                          ElementoNombre(id: "imposible", nombre: "Imposible")]
        let fichas = elegidos.enumerated().map { i, s in
            Payload.Clasificar.Ficha(id: "s\(i + 1)", texto: "\(e.verbo) \(s.texto)", categoria: Self.tipo(Self.conjunto(s.spec, e), e).rawValue)
        }
        let payload = Payload.Clasificar(categorias: categorias, fichas: fichas)
        let errores = zip(fichas, elegidos).map { f, s -> ErrorHabitual in
            let c = Self.conjunto(s.spec, e)
            let porque = switch Self.tipo(c, e) {
            case .seguro: "ocurre con cualquier resultado"
            case .imposible: "no ocurre con ningún resultado posible"
            case .posible: "ocurre con algunos resultados, pero no con todos"
            }
            return ErrorHabitual(respuesta: f.id, feedback: "«\(f.texto)» es \(f.categoria): \(porque).")
        }
        let pasos = [Pasos.dato("Escribe los resultados posibles", Self.texto(Set(e.omega), e),
                                porque: "porque cada suceso se mira dentro de los resultados posibles"),
                     Pasos.solucion("Clasifica cada suceso", payload: .clasificar(payload))]
        return Muestra(clave: "clasificar|\(e.id)|" + elegidos.map(\.spec).joined(separator: ";"),
                       valores: ["pregunta": e.enunciado + " Clasifica cada suceso en seguro, posible o imposible."],
                       payload: .clasificar(payload),
                       explicacion: "Un suceso es seguro si ocurre siempre, imposible si no ocurre nunca y posible si ocurre solo con algunos resultados.",
                       erroresHabituales: errores, pistas: ["Para cada suceso, busca un resultado en que ocurra y otro en que no."],
                       complejidad: Double(nivel) + Double(elegidos.filter { $0.spec.contains("&") || $0.spec.contains("|") }.count) * 0.1,
                       datos: ["experimento": e.id, "sucesos": elegidos.map(\.spec).joined(separator: ";"),
                               "categorias": fichas.map(\.categoria).joined(separator: ";")]).conPasos(pasos)
    }

    /// Suceso contrario (elección).
    func contrario(_ nivel: Int, rng: inout GeneradorConSemilla) throws -> Muestra {
        // Una urna de 2 colores no da distractores suficientes: se prueba con otro experimento.
        for _ in 0..<30 {
            let e = experimento(nivel, rng: &rng)
            let candidatosA = Self.posibles(e, compuestos: nivel >= 5).filter { e.contrarios[$0.spec] != nil }
            guard !candidatosA.isEmpty else { continue }
            let a = rng.elemento(candidatosA)
            let d = distractoresContrario(e, a, rng: &rng)
            if d.count >= 2 { return contrario(nivel, e, a, d, rng: &rng) }
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    /// Distractores: subconjuntos propios del contrario y sucesos que comparten resultados con A.
    func distractoresContrario(_ e: Experimento, _ a: Suceso, rng: inout GeneradorConSemilla) -> [(texto: String, feedback: String, spec: String)] {
        let correcto = e.contrarios[a.spec]!
        let conjA = Self.conjunto(a.spec, e), complemento = Set(e.omega).subtracting(conjA)
        var parciales: [(texto: String, feedback: String, spec: String)] = []
        var solapados: [(texto: String, feedback: String, spec: String)] = []
        for s in rng.barajar(Self.posibles(e, compuestos: true)) where s.texto != correcto.texto && s.texto != a.texto {
            let c = Self.conjunto(s.spec, e)
            guard c != complemento, !c.isEmpty else { continue }
            if c.isSubset(of: complemento) {
                parciales.append(("\(e.verbo) \(s.texto)", "«\(e.verbo) \(s.texto)» no cubre todos los resultados en que no ocurre A.", s.spec))
            } else if !c.isDisjoint(with: conjA) {
                solapados.append(("\(e.verbo) \(s.texto)", "«\(e.verbo) \(s.texto)» puede ocurrir a la vez que A: no es su contrario.", s.spec))
            }
        }
        return Array(parciales.prefix(2)) + Array(solapados.prefix(3 - min(parciales.count, 2)))
    }

    func contrario(_ nivel: Int, _ e: Experimento, _ a: Suceso, _ distractores: [(texto: String, feedback: String, spec: String)],
                   rng: inout GeneradorConSemilla) -> Muestra {
        let correcto = e.contrarios[a.spec]!
        let conjA = Self.conjunto(a.spec, e), complemento = Set(e.omega).subtracting(conjA)
        let textoCorrecto = "\(e.verbo) \(correcto.texto)"
        let (eleccion, errores) = Opciones.eleccion(correcta: textoCorrecto, distractores: distractores.map { ($0.texto, $0.feedback) }, rng: &rng)
        let specs = eleccion.opciones.map { o in o.texto == textoCorrecto ? correcto.spec : distractores.first { $0.texto == o.texto }!.spec }
        let pasos = [Pasos.dato("Busca los resultados de A", Self.texto(conjA, e)),
                     Pasos.dato("Quédate con los que faltan", Self.texto(complemento, e),
                                porque: "porque el contrario ocurre justo cuando no ocurre A"),
                     Pasos.solucion("Elige el suceso con esos resultados", payload: .eleccion(eleccion))]
        return Muestra(clave: "contrario|\(e.id)|\(a.spec)|" + distractores.map(\.spec).sorted().joined(separator: ";"),
                       valores: ["pregunta": e.enunciado + " A: «\(e.verbo) \(a.texto)». ¿Cuál es el suceso contrario de A?"],
                       payload: .eleccion(eleccion),
                       explicacion: "El contrario de A ocurre exactamente cuando A no ocurre: \(textoCorrecto.prefix(1).lowercased() + textoCorrecto.dropFirst()).",
                       erroresHabituales: errores, pistas: ["El contrario reúne todos los resultados que no están en A, y solo esos."],
                       complejidad: Double(nivel) + (a.spec.contains("&") || a.spec.contains("|") ? 0.2 : 0),
                       datos: ["experimento": e.id, "A": a.spec, "opciones": specs.joined(separator: ";"), "correcta": eleccion.correcta]).conPasos(pasos)
    }

    /// Compatibles o incompatibles (elección entre dos).
    func compatibles(_ nivel: Int, rng: inout GeneradorConSemilla) throws -> Muestra {
        let e = experimento(nivel, rng: &rng)
        let lista = Self.posibles(e, compuestos: nivel >= 5)
        let quiere = rng.probabilidad(0.5)
        var par: (Suceso, Suceso)?
        for _ in 0..<200 {
            let a = rng.elemento(lista), b = rng.elemento(lista)
            guard a.texto != b.texto else { continue }
            let comun = !Self.conjunto(a.spec, e).isDisjoint(with: Self.conjunto(b.spec, e))
            if comun == quiere { par = (a, b); break }
        }
        guard let (a, b) = par else { throw ErrorGenerador.sinCaso(tipo) }
        let comun = Self.conjunto(a.spec, e).intersection(Self.conjunto(b.spec, e))
        let si = "Compatibles: pueden ocurrir a la vez", no = "Incompatibles: no pueden ocurrir a la vez"
        let correcta = comun.isEmpty ? no : si
        let ejemplo = e.omega.first { comun.contains($0) }.map(Self.nombre)
        let feedback = comun.isEmpty ? "No hay ningún resultado en que ocurran los dos: son incompatibles."
            : "Con «\(ejemplo ?? "")» ocurren los dos a la vez: son compatibles."
        // Las dos opciones, siempre en el mismo orden.
        let opciones = [ElementoTexto(id: "a", texto: si), ElementoTexto(id: "b", texto: no)]
        let eleccion = Payload.Eleccion(opciones: opciones, correcta: correcta == si ? "a" : "b")
        let errores = [ErrorHabitual(respuesta: correcta == si ? "b" : "a", feedback: feedback)]
        let pasos = [Pasos.dato("Resultados de A", Self.texto(Self.conjunto(a.spec, e), e)),
                     Pasos.dato("Resultados de B", Self.texto(Self.conjunto(b.spec, e), e)),
                     Pasos.dato("Busca resultados comunes", Self.texto(comun, e), porque: "porque son compatibles si comparten algún resultado"),
                     Pasos.solucion("Decide", payload: .eleccion(eleccion))]
        return Muestra(clave: "compatibles|\(e.id)|\([a.spec, b.spec].sorted().joined(separator: ";"))",
                       valores: ["pregunta": e.enunciado + " A: «\(e.verbo) \(a.texto)». B: «\(e.verbo) \(b.texto)». ¿Cómo son A y B?"],
                       payload: .eleccion(eleccion),
                       explicacion: comun.isEmpty ? "A y B no tienen ningún resultado en común, así que no pueden ocurrir a la vez: son incompatibles."
                           : "A y B comparten resultados (\(Self.texto(comun, e))), así que pueden ocurrir a la vez: son compatibles.",
                       erroresHabituales: errores, pistas: ["Busca un resultado en que ocurran los dos sucesos."],
                       complejidad: Double(nivel) + (a.spec.contains("&") || b.spec.contains("|") ? 0.2 : 0),
                       datos: ["experimento": e.id, "A": a.spec, "B": b.spec, "compatibles": comun.isEmpty ? "no" : "si"]).conPasos(pasos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
