import Foundation

// Generadores de la Fase 05E (parte 1): formas no personales del verbo (LEN.VER.NOPERS) y
// literatura sobre la base literaria del lote 05a (LEN.LIT.HIST, UNIV, INF y GEN).

// MARK: - formasNoPersonales

/// Formas no personales de verbos regulares: infinitivo, gerundio y participio, simples y
/// compuestas (haber cantado, habiendo cantado). Mecánicas: `clasificar` (fichas por forma) y
/// `eleccion` (qué forma es).
///
/// | Dif. | Verbos | Formas | Fichas (clasificar) |
/// |---|---|---|---|
/// | 1 | en -ar | simples | 4 |
/// | 2 | tres conjugaciones | simples | 5 |
/// | 3 | + participios irregulares (escrito, abierto) | simples | 6 |
/// | 4 | tres conjugaciones | + compuestas (simple o compuesta en `eleccion`) | 6 |
/// | 5–6 | + participios irregulares | + compuestas | 6 |
struct GeneradorFormasNoPersonales: GeneradorItems {
    let tipo = "formasNoPersonales"
    let mecanicas: Set<Mecanica> = [.clasificar, .eleccion]
    let marcadores: Set<String> = ["forma", "infinitivo", "contexto"]

    struct Forma: Equatable { let texto: String; let verbo: String; let clase: String; let compuesta: Bool }

    static let clases = ["INF": "Infinitivo", "GER": "Gerundio", "PART": "Participio"]

    static func gerundio(_ inf: String) -> String { String(inf.dropLast(2)) + (inf.hasSuffix("ar") ? "ando" : "iendo") }

    /// Formas del nivel. Un participio irregular (escrito, abierto) solo entra desde el nivel 3.
    static func formas(_ d: Int, _ r: RecursosGeneradores) -> [Forma] {
        let banco = GeneradorAnalisisVerbal.banco(r)
        let irregularParticipio = Set(banco.irregulares.filter { $0.participio != nil }.map(\.infinitivo))
        let verbos = banco.regulares.filter { v in
            (d >= 2 || v.hasSuffix("ar")) && (d == 3 || d >= 5 || !irregularParticipio.contains(v))
        }
        var out: [Forma] = []
        for v in verbos {
            let part = Conjugador.participio(v, irregular: banco.irregulares.first { $0.infinitivo == v })
            out += [Forma(texto: v, verbo: v, clase: "INF", compuesta: false),
                    Forma(texto: gerundio(v), verbo: v, clase: "GER", compuesta: false),
                    Forma(texto: part, verbo: v, clase: "PART", compuesta: false)]
            if d >= 4 {
                out += [Forma(texto: "haber \(part)", verbo: v, clase: "INF", compuesta: true),
                        Forma(texto: "habiendo \(part)", verbo: v, clase: "GER", compuesta: true)]
            }
        }
        return out
    }

    static func nombre(_ f: Forma, distinguir: Bool) -> String {
        let base = clases[f.clase]!
        guard distinguir, f.clase != "PART" else { return base }
        return base + (f.compuesta ? " compuesto" : " simple")
    }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let todas = Self.formas(p.dificultad, recursos)
        guard todas.count >= 6 else { throw ErrorGenerador.sinRecursos(tipo) }
        let complejidadBase = Double(min(p.dificultad, 6)) + (p.dificultad >= 4 ? 1 : 0)
        if p.mecanica == .eleccion {
            let f = rng.elemento(todas)
            let distinguir = p.dificultad >= 4
            let correcta = Self.nombre(f, distinguir: distinguir)
            let opciones = distinguir ? ["Infinitivo simple", "Infinitivo compuesto", "Gerundio simple", "Gerundio compuesto", "Participio"]
                                      : ["Infinitivo", "Gerundio", "Participio"]
            let regla = "El infinitivo acaba en -ar, -er o -ir; el gerundio, en -ando o -iendo; el participio, en -ado o -ido (o es irregular: escrito, abierto)."
                + (distinguir ? " Las compuestas llevan «haber» o «habiendo» + participio." : "")
            let (e, errores) = Opciones.eleccion(correcta: correcta, distractores: rng.barajar(opciones.filter { $0 != correcta }).map { ($0, regla) }, rng: &rng)
            return Muestra(clave: "eleccion|\(f.texto)", valores: ["forma": f.texto, "infinitivo": f.verbo], payload: .eleccion(e),
                           explicacion: "«\(f.texto)» es \(correcta.lowercased()) del verbo \(f.verbo). \(regla)", erroresHabituales: errores,
                           pistas: ["Mira la terminación.", "Si empieza por «haber» o «habiendo», es una forma compuesta."],
                           complejidad: complejidadBase + (f.compuesta ? 1 : 0) + (f.texto != Conjugador.participio(f.verbo, irregular: nil) && f.clase == "PART" ? 0.5 : 0),
                           datos: ["forma": f.texto, "verbo": f.verbo, "clase": f.clase, "compuesta": f.compuesta ? "1" : "0"])
        }
        // clasificar: 4–6 fichas de varios verbos, con las tres clases representadas y sin repetir forma.
        let n = p.dificultad == 1 ? 4 : (p.dificultad == 2 ? 5 : 6)
        for _ in 0..<50 {
            var elegidas: [Forma] = []
            for clase in ["INF", "GER", "PART"] { elegidas.append(rng.elemento(todas.filter { $0.clase == clase })) }
            for f in rng.barajar(todas) where elegidas.count < n && !elegidas.contains(where: { $0.texto == f.texto }) { elegidas.append(f) }
            guard Set(elegidas.map(\.texto)).count == n else { continue }
            let categorias = ["INF", "GER", "PART"].map { ElementoNombre(id: $0, nombre: Self.clases[$0]!) }
            let fichas = rng.barajar(elegidas).enumerated().map { Payload.Clasificar.Ficha(id: "f\($0.offset + 1)", texto: $0.element.texto, categoria: $0.element.clase) }
            let clave = elegidas.map(\.texto).sorted().joined(separator: ",")
            let compuestas = elegidas.filter(\.compuesta).count
            return Muestra(clave: "clasificar|\(clave)", valores: ["forma": "", "infinitivo": ""],
                           payload: .clasificar(Payload.Clasificar(categorias: categorias, fichas: fichas)),
                           explicacion: elegidas.map { "«\($0.texto)»: \(Self.nombre($0, distinguir: true).lowercased())" }.joined(separator: "; ") + ".",
                           pistas: ["Infinitivo: -ar, -er, -ir. Gerundio: -ando, -iendo. Participio: -ado, -ido."],
                           complejidad: complejidadBase + Double(n) * 0.2 + Double(compuestas) * 0.3,
                           datos: ["formas": elegidas.map { "\($0.texto)|\($0.verbo)|\($0.clase)|\($0.compuesta ? 1 : 0)" }.joined(separator: ";")])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        if p.mecanica == .eleccion { return Array(Self.formas(p.dificultad, recursos).map { "eleccion|\($0.texto)" }.prefix(limite)) }
        return enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}

// MARK: - literatura

/// Preguntas sobre la base literaria del lote 05a (D-078, D-079). Solo datos de la base; las
/// reglas de la Fase 05E (§5):
/// - autor ↔ obra (`emparejar`, 4 parejas): sin obras anónimas ni de autoría discutida (autores
///   anónimos o con fechas aproximadas);
/// - obra → movimiento o siglo (`eleccion`): solo obras con año; la de movimiento, solo si el año
///   está dentro del rango del movimiento (D-079) y con distractores de movimientos vecinos cuyo
///   rango no contiene ese año; la de siglo, sin años de cambio de siglo;
/// - línea del tiempo (`ordenar`, 4 autores por nacimiento o 4 movimientos por inicio): nunca fechas
///   aproximadas y al menos 15 años entre fechas consecutivas;
/// - género de la obra (`clasificar`): sin las greguerías (su género es una convención).
///
/// Parámetros: `ambitos` (espanola, hispanoamericana, universal, infantil), `pregunta`
/// (`movimiento` o `siglo` en `eleccion`; `autores` o `movimientos` en `ordenar`).
struct GeneradorLiteratura: GeneradorItems {
    let tipo = "literatura"
    let mecanicas: Set<Mecanica> = [.emparejar, .eleccion, .ordenar, .clasificar]
    let marcadores: Set<String> = ["obra", "autor", "contexto"]

    typealias Autor = BaseLiteraria.Autor
    typealias Obra = BaseLiteraria.Obra

    /// Movimientos de la literatura española (los de la periodización por épocas).
    static let periodosEspanoles: Set<String> = ["medieval", "siglo_de_oro", "siglo_xviii", "siglo_xix", "siglo_xx", "actual"]
    /// Separación mínima entre fechas consecutivas de la línea del tiempo, por nivel (siempre ≥ 15).
    static let separacionMinima = [150, 100, 60, 30, 20, 15]

    static func autores(_ base: BaseLiteraria, _ p: Plantilla) -> [Autor] {
        let ambitos = Set(p.textos("ambitos", porDefecto: Array(BaseLiteraria.ambitos)))
        return base.autores.filter { ambitos.contains($0.ambito) }
    }

    /// Autor de atribución segura: ni anónimo ni con fechas aproximadas.
    static func atribucionSegura(_ a: Autor) -> Bool { !a.aproximado && !a.nombre.hasPrefix("Anónimo") }

    static func siglo(_ anio: Int) -> Int { (anio - 1) / 100 + 1 }

    static func romano(_ n: Int) -> String {
        let tabla: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var r = "", x = n
        for (v, s) in tabla { while x >= v { r += s; x -= v } }
        return r
    }

    static func nombreSiglo(_ s: Int) -> String { "Siglo \(romano(s))" }

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        guard let base = recursos.literatura else { throw ErrorGenerador.sinRecursos(tipo) }
        let d = min(max(p.dificultad, 1), 6)
        switch p.mecanica {
        case .emparejar: return try autorObra(p, base, d, &rng)
        case .ordenar: return try lineaTiempo(p, base, d, &rng)
        case .clasificar: return try genero(p, base, d, &rng)
        default: return p.textos("pregunta", porDefecto: ["movimiento"]).first == "siglo" ? try siglo(p, base, d, &rng) : try movimiento(p, base, d, &rng)
        }
    }

    // MARK: autor ↔ obra

    /// Nivel por la cercanía en el tiempo de los cuatro autores (año de nacimiento): cuanto más
    /// cerca, más fácil confundirlos. Separación mínima entre dos de ellos: 1 ≥ 60 años, 2 ≥ 40,
    /// 3 ≥ 25, 4 ≥ 15; 5, los cuatro en 100 años; 6, en 60 años y con obras del mismo género si se puede.
    private func autorObra(_ p: Plantilla, _ base: BaseLiteraria, _ d: Int, _ rng: inout GeneradorConSemilla) throws -> Muestra {
        let candidatos = Self.autores(base, p).filter { Self.atribucionSegura($0) && !$0.obras.isEmpty && $0.nacimiento != nil }
        let separacion = [60, 40, 25, 15, 0, 0][d - 1]
        let amplitudMaxima = [Int.max, Int.max, Int.max, Int.max, 100, 60][d - 1]
        for _ in 0..<300 {
            var elegidos: [Autor] = []
            let ancla = rng.elemento(candidatos)
            elegidos.append(ancla)
            for a in rng.barajar(candidatos) where elegidos.count < 4 && a.id != ancla.id {
                let fechas = elegidos.map { $0.nacimiento! } + [a.nacimiento!]
                if elegidos.allSatisfy({ abs($0.nacimiento! - a.nacimiento!) >= separacion }), fechas.max()! - fechas.min()! <= amplitudMaxima {
                    elegidos.append(a)
                }
            }
            guard elegidos.count == 4 else { continue }
            // Una obra por autor, con títulos distintos (en el nivel 6, del mismo género si se puede).
            var obras: [Obra] = []
            let generoComun = d == 6 ? rng.elemento(["poesia", "narrativa", "teatro"]) : nil
            for a in elegidos {
                let lista = a.obras.filter { o in !obras.contains { $0.titulo == o.titulo } }
                let preferidas = generoComun.map { g in lista.filter { $0.genero == g } } ?? []
                guard let o = (preferidas.isEmpty ? lista : preferidas).randomElement(using: &rng) else { break }
                obras.append(o)
            }
            // Sin ambigüedad: ningún título mostrado es también obra de otro de los autores
            // («Soledades» es de Góngora y de Machado).
            guard obras.count == 4, !zip(elegidos, obras).contains(where: { a, o in
                elegidos.contains { $0.id != a.id && $0.obras.contains { $0.titulo == o.titulo } }
            }) else { continue }
            let izquierda = elegidos.enumerated().map { ElementoTexto(id: "a\($0.offset + 1)", texto: $0.element.nombre) }
            let orden = rng.barajar(Array(0..<4))
            let derecha = orden.enumerated().map { ElementoTexto(id: "o\($0.offset + 1)", texto: obras[$0.element].titulo) }
            let pares = (0..<4).map { i in ["a\(i + 1)", "o\(orden.firstIndex(of: i)! + 1)"] }
            let nacimientos = elegidos.map { $0.nacimiento! }.sorted()
            let menor = zip(nacimientos.dropFirst(), nacimientos).map { $0 - $1 }.min()!
            let mismoGenero = Set(obras.map(\.genero)).count == 1
            return Muestra(clave: "autorObra|" + zip(elegidos, obras).map { "\($0.id)>\($1.titulo)" }.sorted().joined(separator: ";"),
                           valores: ["obra": "", "autor": ""],
                           payload: .emparejar(Payload.Emparejar(izquierda: izquierda, derecha: derecha, pares: pares)),
                           explicacion: zip(elegidos, obras).map { "\($0.nombre): «\($1.titulo)»\($1.anio.map { " (\($0))" } ?? "")" }.joined(separator: "; ") + ".",
                           pistas: ["Empieza por la pareja que tengas más clara y descarta."],
                           complejidad: 10 - log2(Double(menor + 2)) + (nacimientos.last! - nacimientos.first! <= 100 ? 1 : 0) + (mismoGenero ? 0.5 : 0),
                           datos: ["pares": zip(elegidos, obras).map { "\($0.id)|\($1.titulo)" }.joined(separator: ";")])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    // MARK: obra → movimiento

    /// Distractores: movimientos de la misma periodización cuyo rango no contiene el año de la obra;
    /// cuanto más alto el nivel, más cercanos (1–2 lejanos, 3–4 de los cercanos, 5–6 los más cercanos).
    private func movimiento(_ p: Plantilla, _ base: BaseLiteraria, _ d: Int, _ rng: inout GeneradorConSemilla) throws -> Muestra {
        let movimientos = Dictionary(uniqueKeysWithValues: base.movimientos.map { ($0.id, $0) })
        let espanoles = base.movimientos.filter { Self.periodosEspanoles.contains($0.periodo) && $0.id != "HISPANO" }
        var casos: [(Autor, Obra, BaseLiteraria.Movimiento)] = []
        for a in Self.autores(base, p) where Self.atribucionSegura(a) {
            guard let m = movimientos[a.movimiento], espanoles.contains(where: { $0.id == m.id }) else { continue }
            for o in a.obras { if let anio = o.anio, anio >= m.inicio, anio <= (m.fin ?? 9999) { casos.append((a, o, m)) } }
        }
        guard !casos.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        for _ in 0..<100 {
            let (a, o, m) = rng.elemento(casos)
            let anio = o.anio!
            let validos = espanoles.filter { $0.id != m.id && !(anio >= $0.inicio && anio <= ($0.fin ?? 9999)) }
            let porDistancia = validos.sorted { abs($0.inicio - m.inicio) < abs($1.inicio - m.inicio) }
            // Cuanto más alto el nivel, más cercanos los distractores al movimiento correcto.
            let candidatos: [BaseLiteraria.Movimiento] = switch d {
            case 1: Array(porDistancia.dropFirst(6))
            case 2: Array(porDistancia.dropFirst(3).prefix(6))
            case 3: Array(porDistancia.prefix(8))
            case 4: Array(porDistancia.prefix(6))
            case 5: Array(porDistancia.prefix(4))
            default: Array(porDistancia.prefix(3))
            }
            let distractores = Array(candidatos.shuffled(using: &rng).prefix(3))
            guard distractores.count == 3 else { continue }
            let (e, errores) = Opciones.eleccion(correcta: m.nombre, distractores: distractores.map {
                ($0.nombre, "\($0.nombre): \($0.inicio)–\($0.fin.map(String.init) ?? "hoy"). «\(o.titulo)» es de \(anio).")
            }, rng: &rng)
            let distancia = Double(distractores.map { abs($0.inicio - m.inicio) }.reduce(0, +)) / 3
            return Muestra(clave: "movimiento|\(a.id)|\(o.titulo)|\(distractores.map(\.id).sorted().joined(separator: ","))",
                           valores: ["obra": o.titulo, "autor": a.nombre], payload: .eleccion(e),
                           explicacion: "«\(o.titulo)», de \(a.nombre), es de \(anio): pertenece a «\(m.nombre)» (\(m.inicio)–\(m.fin.map(String.init) ?? "hoy")). \(m.rasgos[0]).",
                           erroresHabituales: errores, pistas: ["Sitúa primero el año de la obra en su siglo."],
                           complejidad: 10 - min(distancia, 400) / 50,
                           datos: ["autor": a.id, "obra": o.titulo, "anio": String(anio), "movimiento": m.id,
                                   "distractores": distractores.map(\.id).joined(separator: ",")])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    // MARK: obra → siglo

    private func siglo(_ p: Plantilla, _ base: BaseLiteraria, _ d: Int, _ rng: inout GeneradorConSemilla) throws -> Muestra {
        var casos: [(Autor, Obra, Int)] = []
        for a in Self.autores(base, p) where Self.atribucionSegura(a) {
            for o in a.obras { if let anio = o.anio, anio > 0, anio % 100 > 1, anio % 100 != 0 { casos.append((a, o, anio)) } }
        }
        guard !casos.isEmpty else { throw ErrorGenerador.sinRecursos(tipo) }
        let (a, o, anio) = rng.elemento(casos)
        let s = Self.siglo(anio)
        // Distractores: siglos vecinos (más cercanos cuanto más alto el nivel).
        let desplazamientos: [Int] = d <= 2 ? [-3, -2, 2, 3] : (d <= 4 ? [-2, -1, 1, 2] : [-1, 1, -2, 2])
        let candidatos = desplazamientos.map { s + $0 }.filter { $0 >= 1 && $0 <= 21 }
        let distractores = d <= 4 ? Array(rng.barajar(candidatos).prefix(3)) : Array(candidatos.prefix(3))
        let (e, errores) = Opciones.eleccion(correcta: Self.nombreSiglo(s), distractores: distractores.map {
            (Self.nombreSiglo($0), "El siglo \(Self.romano($0)) va de \(($0 - 1) * 100 + 1) a \($0 * 100). «\(o.titulo)» es de \(anio).")
        }, rng: &rng)
        let distancia = Double(distractores.map { abs($0 - s) }.reduce(0, +)) / Double(max(distractores.count, 1))
        return Muestra(clave: "siglo|\(a.id)|\(o.titulo)", valores: ["obra": o.titulo, "autor": a.nombre], payload: .eleccion(e),
                       explicacion: "«\(o.titulo)», de \(a.nombre), es de \(anio): siglo \(Self.romano(s)) (de \((s - 1) * 100 + 1) a \(s * 100)).",
                       erroresHabituales: errores, pistas: ["El siglo XVII va de 1601 a 1700: suma uno a las centenas del año."],
                       complejidad: Double(d) * 0.5 + 4 - distancia,
                       datos: ["autor": a.id, "obra": o.titulo, "anio": String(anio), "siglo": String(s)])
    }

    // MARK: línea del tiempo

    private func lineaTiempo(_ p: Plantilla, _ base: BaseLiteraria, _ d: Int, _ rng: inout GeneradorConSemilla) throws -> Muestra {
        let deMovimientos = p.textos("pregunta", porDefecto: ["autores"]).first == "movimientos"
        // Nunca fechas aproximadas: autores con nacimiento y sin «aproximado»; movimientos por su inicio.
        let elementos: [(id: String, texto: String, fecha: Int)] = deMovimientos
            ? base.movimientos.filter { Self.periodosEspanoles.contains($0.periodo) && $0.id != "HISPANO" }.map { ($0.id, $0.nombre, $0.inicio) }
            : Self.autores(base, p).filter { !$0.aproximado && $0.nacimiento != nil }.map { ($0.id, $0.nombre, $0.nacimiento!) }
        // Separación mínima del nivel, proporcional al intervalo de fechas disponible (la literatura
        // infantil abarca menos siglos que la española) y nunca por debajo de 15 años.
        let fechas = elementos.map(\.fecha)
        let amplitud = (fechas.max() ?? 0) - (fechas.min() ?? 0)
        let separacion = max(15, min(Self.separacionMinima[d - 1], Int(Double(amplitud) * [0.2, 0.14, 0.09, 0.06, 0.04, 0.02][d - 1])))
        for _ in 0..<400 {
            var elegidos: [(id: String, texto: String, fecha: Int)] = []
            for x in rng.barajar(elementos) where elegidos.count < 4 {
                if elegidos.allSatisfy({ abs($0.fecha - x.fecha) >= separacion }) { elegidos.append(x) }
            }
            guard elegidos.count == 4 else { continue }
            let ordenados = elegidos.sorted { $0.fecha < $1.fecha }
            let huecos = zip(ordenados.dropFirst(), ordenados).map { $0.fecha - $1.fecha }
            // En los niveles altos, la separación mínima también es la máxima de la pareja más cercana.
            if d >= 4, let menor = huecos.min(), menor > separacion * 3 { continue }
            // En el nivel 6, la pareja más cercana está a menos de 10 años de la separación mínima.
            if d == 6, let menor = huecos.min(), menor > separacion + 10 { continue }
            let fichas = rng.barajar(elegidos).enumerated().map { (i, x) in ElementoTexto(id: "f\(i + 1)", texto: x.texto) }
            let ids = Dictionary(uniqueKeysWithValues: zip(fichas.map(\.texto), fichas.map(\.id)))
            let fechaTexto = deMovimientos ? "desde" : "nace en"
            return Muestra(clave: "linea|\(deMovimientos ? "m" : "a")|" + elegidos.map(\.id).sorted().joined(separator: ","),
                           valores: ["obra": "", "autor": ""],
                           payload: .ordenar(Payload.Ordenar(fichas: fichas, ordenCorrecto: ordenados.map { ids[$0.texto]! },
                                                             etiquetaInicio: "Más antiguo", etiquetaFin: "Más moderno")),
                           explicacion: ordenados.map { "\($0.texto) (\(fechaTexto) \($0.fecha))" }.joined(separator: " → ") + ".",
                           pistas: ["Sitúa cada uno en su siglo antes de ordenar."],
                           complejidad: 10 - log2(Double(huecos.min()!)),
                           datos: ["fechas": ordenados.map { "\($0.id)=\($0.fecha)" }.joined(separator: ";"), "tipo": deMovimientos ? "movimientos" : "autores"])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    // MARK: género

    /// 1: 4 obras de poesía y narrativa; 2: 5; 3: 5 obras con teatro; 4: 6; 5: 6 con ensayo;
    /// 6: 6 con los cuatro géneros a la vez.
    private func genero(_ p: Plantilla, _ base: BaseLiteraria, _ d: Int, _ rng: inout GeneradorConSemilla) throws -> Muestra {
        let generos = d <= 2 ? ["poesia", "narrativa"] : (d <= 4 ? ["poesia", "narrativa", "teatro"] : ["poesia", "narrativa", "teatro", "ensayo"])
        let n = [4, 5, 5, 6, 6, 6][d - 1]
        let obras = Self.autores(base, p).flatMap { a in a.obras.map { (a, $0) } }
            .filter { generos.contains($0.1.genero) && !$0.1.titulo.lowercased().contains("greguer") }
        let nombres = ["poesia": "Poesía (lírica)", "narrativa": "Narrativa", "teatro": "Teatro (dramática)", "ensayo": "Ensayo"]
        for _ in 0..<100 {
            var elegidas: [(Autor, Obra)] = []
            // Una obra de cada género (en el nivel 5, el ensayo puede faltar; en el 6, están los cuatro).
            for g in generos where d != 5 || g != "ensayo" { if let x = rng.barajar(obras.filter { $0.1.genero == g }).first { elegidas.append(x) } }
            for x in rng.barajar(obras) where elegidas.count < n && !elegidas.contains(where: { $0.1.titulo == x.1.titulo }) { elegidas.append(x) }
            guard elegidas.count == n, Set(elegidas.map(\.1.titulo)).count == n else { continue }
            let presentes = generos.filter { g in elegidas.contains { $0.1.genero == g } }
            guard presentes.count == generos.count || (d < 6 && presentes.count >= 2) else { continue }
            let categorias = presentes.map { ElementoNombre(id: $0, nombre: nombres[$0]!) }
            let fichas = rng.barajar(elegidas).enumerated().map { (i, x) in
                Payload.Clasificar.Ficha(id: "f\(i + 1)", texto: "\(x.1.titulo) (\(Self.atribucionSegura(x.0) || !x.0.nombre.hasPrefix("Anónimo") ? x.0.nombre : "anónimo"))",
                                         categoria: x.1.genero)
            }
            let explicacion = presentes.map { g in
                (nombres[g]!.components(separatedBy: " (").first ?? g) + ": " + elegidas.filter { $0.1.genero == g }.map { "«\($0.1.titulo)»" }.joined(separator: ", ")
            }.joined(separator: ". ") + "."
            guard explicacion.count <= 280 else { continue }
            return Muestra(clave: "genero|" + elegidas.map(\.1.titulo).sorted().joined(separator: ";"), valores: ["obra": "", "autor": ""],
                           payload: .clasificar(Payload.Clasificar(categorias: categorias, fichas: fichas)),
                           explicacion: explicacion,
                           pistas: ["El teatro se escribe para representarse; la narrativa cuenta una historia; la lírica expresa sentimientos."],
                           complejidad: Double(n) + Double(presentes.count),
                           datos: ["obras": elegidas.map { "\($0.0.id)|\($0.1.titulo)|\($0.1.genero)" }.joined(separator: ";")])
        }
        throw ErrorGenerador.sinCaso(tipo)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
