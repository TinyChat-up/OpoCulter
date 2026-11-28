import Foundation

/// «Capas y sólidos» (MAT.GEO.VOL, Fase 05K §1): volumen de sólidos en perspectiva isométrica.
///
/// | Nivel | Sólido |
/// |---|---|
/// | 1 | ortoedro pequeño de cubos de 1 cm (contar capas) |
/// | 2 | ortoedro con medidas enteras en cm → cm³ |
/// | 3 | ortoedro → capacidad en litros (1 dm³ = 1 l) |
/// | 4 | perfil del examen: dos ortoedros unidos, o un depósito con agua y medidas decimales en m → l |
/// | 5 | cilindro (π = 3,14 en el enunciado) |
/// | 6 | unidades mixtas, o sacar litros y calcular la nueva altura del agua |
///
/// En los peldaños 1–2, los ortoedros pequeños de medidas enteras se ven como cubos que se apilan
/// por capas. El resultado lo comprueba en los tests un oráculo independiente (fórmula del sólido a
/// partir de sus medidas rotuladas).
struct GeneradorVolumen: GeneradorItems {
    let tipo = "volumen"
    let mecanicas: Set<Mecanica> = [.figuraVolumen]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    typealias V = Payload.FiguraVolumen
    static let pi = rac(314, 100)
    static let juego = "Capas"

    static func t(_ v: Racional) -> String { FormatoNumero.numero(v) }
    static func d(_ v: Racional) -> Double { v.valorDouble }

    struct Caso {
        var solidos: [V.Solido]
        var rotulos: [V.Rotulo]
        var agua: Double?
        var admiteCubos = false
        var campos: [V.Campo]
        var camposCubos: [V.Campo] = []
        var resultado: Racional
        var unidad: String
        var unidades: [String]
        var etiqueta: String
        var descripcion: String
        var enunciado: String
        var erroneos: [String: Racional]
        var pasos: [PasoResuelto]
        var explicacion: String
        var clave: String
        /// Datos para el oráculo de los tests: forma, medidas en la unidad del resultado…
        var datos: [String: String]
    }

    static func campo(_ id: String, _ etiqueta: String, _ v: Racional) -> V.Campo { .init(id: id, etiqueta: etiqueta, valor: t(v)) }
    static func caja(_ id: String, x: Racional = rac(0), y: Racional = rac(0), _ l: Racional, _ a: Racional, _ h: Racional) -> V.Solido {
        .init(id: id, forma: .ortoedro, x: d(x), y: d(y), z: 0, largo: d(l), ancho: d(a), alto: d(h))
    }

    // MARK: Casos por nivel

    func caso(_ nivel: Int, rng: inout GeneradorConSemilla) -> Caso {
        switch nivel {
        case 1: return Self.cubos(rng: &rng)
        case 2: return Self.ortoedro(rng: &rng)
        case 3: return Self.litros(rng: &rng)
        case 4: return rng.probabilidad(0.5) ? Self.dosOrtoedros(rng: &rng) : Self.deposito(rng: &rng)
        case 5: return Self.cilindro(rng: &rng)
        default: return rng.probabilidad(0.5) ? Self.mixtas(rng: &rng) : Self.extraer(rng: &rng)
        }
    }

    /// Ortoedro de cubos de 1 cm, pasos comunes de los niveles 1 y 2.
    static func ortoedroEntero(_ l: Int, _ a: Int, _ h: Int, enunciado: String, clave: String, cubos: Bool) -> Caso {
        let (L, A, H) = (rac(l), rac(a), rac(h))
        let base = L * A, v = base * H
        return Caso(solidos: [caja("A", L, A, H)],
                    rotulos: [.init(solido: "A", arista: .largo, texto: "\(l) cm"), .init(solido: "A", arista: .ancho, texto: "\(a) cm"),
                              .init(solido: "A", arista: .alto, texto: "\(h) cm")],
                    agua: nil, admiteCubos: cubos,
                    campos: [campo("base", "Área de la base (cm²)", base), campo("altura", "Altura (cm)", H)],
                    camposCubos: [campo("base", "Cubos de la capa de la base", base), campo("capas", "Capas", H)],
                    resultado: v, unidad: "cm³", unidades: ["cm", "cm²", "cm³"], etiqueta: "Volumen",
                    descripcion: "Ortoedro de \(l) cm de largo, \(a) cm de ancho y \(h) cm de alto" + (cubos ? ", hecho con cubos de 1 cm de arista: \(h) capas de \(l) por \(a) cubos." : "."),
                    enunciado: enunciado,
                    erroneos: ["sumaDimensiones": L + A + H, "area": base],
                    pasos: [Pasos.op("Calcula el área de la base", "\(l) × \(a)", base, porque: "porque cada capa tiene tantos cubos como el área de la base"),
                            Pasos.op("Multiplica por la altura", "\(t(base)) × \(h)", v, porque: "porque hay \(h) capas iguales")],
                    explicacion: "Volumen = área de la base × altura = \(l) × \(a) × \(h) = \(t(v)) cm³.",
                    clave: clave, datos: ["forma": "ortoedros", "medidas": "\(l)×\(a)×\(h)", "factor": "1"])
    }

    static func cubos(rng: inout GeneradorConSemilla) -> Caso {
        let l = rng.entero(2...4), a = rng.entero(2...3), h = rng.entero(2...5)
        return ortoedroEntero(l, a, h, enunciado: "Este ortoedro está hecho con cubos de 1 cm de arista. ¿Cuál es su volumen?",
                              clave: "cubos|\(l)|\(a)|\(h)", cubos: true)
    }

    static let objetos = ["una caja de zapatos", "un estuche", "una caja de galletas", "un ladrillo de juguete", "una caja de regalo"]

    static func ortoedro(rng: inout GeneradorConSemilla) -> Caso {
        let l = rng.entero(3...8), a = rng.entero(2...6), h = rng.entero(2...7)
        let o = rng.elemento(objetos)
        return ortoedroEntero(l, a, h, enunciado: "Calcula el volumen de \(o) con forma de ortoedro.", clave: "orto|\(l)|\(a)|\(h)|\(o)", cubos: true)
    }

    /// Capacidad en litros de un recipiente medido en centímetros.
    static func litros(rng: inout GeneradorConSemilla) -> Caso {
        let l = rng.elemento([20, 25, 30, 40, 50, 60]), a = rng.elemento([10, 15, 20, 25, 30].filter { $0 <= l }), h = rng.elemento([10, 20, 25, 30, 40])
        let (L, A, H) = (rac(l), rac(a), rac(h))
        let base = L * A, cm3 = base * H, litros = cm3 * rac(1, 1000)
        let o = rng.elemento(["una pecera", "un acuario", "una caja de almacenaje", "una jardinera"])
        return Caso(solidos: [caja("A", L, A, H)],
                    rotulos: [.init(solido: "A", arista: .largo, texto: "\(l) cm"), .init(solido: "A", arista: .ancho, texto: "\(a) cm"),
                              .init(solido: "A", arista: .alto, texto: "\(h) cm")],
                    agua: nil,
                    campos: [campo("base", "Área de la base (cm²)", base), campo("altura", "Altura (cm)", H), campo("cm3", "Volumen (cm³)", cm3)],
                    resultado: litros, unidad: "l", unidades: ["cm³", "l", "m³"], etiqueta: "Capacidad",
                    descripcion: "Recipiente con forma de ortoedro de \(l) cm de largo, \(a) cm de ancho y \(h) cm de alto.",
                    enunciado: "¿Cuántos litros caben en \(o) de \(l) cm de largo, \(a) cm de ancho y \(h) cm de alto?",
                    erroneos: ["sinLitros": cm3, "conversion100": cm3 * rac(1, 100), "conversion10": cm3 * rac(1, 10),
                               "area": base, "sumaDimensiones": L + A + H],
                    pasos: [Pasos.op("Calcula el volumen en cm³", "\(l) × \(a) × \(h)", cm3, porque: "porque el volumen es largo · ancho · alto"),
                            Pasos.op("Pásalo a litros", "\(t(cm3)) : 1000", litros, porque: "porque 1 l = 1 dm³ = 1000 cm³")],
                    explicacion: "Volumen = \(l) × \(a) × \(h) = \(t(cm3)) cm³. Como 1 l = 1 dm³ = 1000 cm³, caben \(t(cm3)) : 1000 = \(t(litros)) l.",
                    clave: "litros|\(l)|\(a)|\(h)|\(o)", datos: ["forma": "ortoedros", "medidas": "\(l)×\(a)×\(h)", "factor": "1/1000"])
    }

    /// Perfil del examen: dos ortoedros unidos (se suman sus volúmenes).
    static func dosOrtoedros(rng: inout GeneradorConSemilla) -> Caso {
        let l1 = rng.entero(4...8), a1 = rng.entero(3...6), h1 = rng.entero(4...8)
        let l2 = rng.entero(2...5), a2 = rng.entero(2...a1), h2 = rng.entero(2...(h1 - 1))
        let v1 = rac(l1 * a1 * h1), v2 = rac(l2 * a2 * h2), v = v1 + v2
        // B, pegado a la derecha de A y alineado con su cara delantera.
        let b = caja("B", x: rac(l1), y: rac(a1 - a2), rac(l2), rac(a2), rac(h2))
        return Caso(solidos: [caja("A", rac(l1), rac(a1), rac(h1)), b],
                    rotulos: [.init(solido: "A", arista: .largo, texto: "\(l1) cm"), .init(solido: "A", arista: .alto, texto: "\(h1) cm"),
                              .init(solido: "A", arista: .ancho, texto: "\(a1) cm"),
                              .init(solido: "B", arista: .largo, texto: "\(l2) cm"), .init(solido: "B", arista: .ancho, texto: "\(a2) cm"),
                              .init(solido: "B", arista: .alto, texto: "\(h2) cm")],
                    agua: nil,
                    campos: [campo("A", "Volumen de A (cm³)", v1), campo("B", "Volumen de B (cm³)", v2)],
                    resultado: v, unidad: "cm³", unidades: ["cm", "cm²", "cm³"], etiqueta: "Volumen total",
                    descripcion: "Dos ortoedros unidos. A, a la izquierda: \(l1) cm de largo, \(a1) cm de ancho y \(h1) cm de alto. B, pegado a su derecha: \(l2) cm de largo, \(a2) cm de ancho y \(h2) cm de alto.",
                    enunciado: "Este bloque está formado por dos ortoedros, A y B. Calcula su volumen total.",
                    erroneos: ["sumaDimensiones": rac(l1 + a1 + h1 + l2 + a2 + h2), "area": rac(l1 * a1 + l2 * a2)],
                    pasos: [Pasos.op("Calcula el volumen de A", "\(l1) × \(a1) × \(h1)", v1, porque: "porque el cuerpo se separa en dos ortoedros"),
                            Pasos.op("Calcula el volumen de B", "\(l2) × \(a2) × \(h2)", v2),
                            Pasos.op("Suma los dos volúmenes", "\(t(v1)) + \(t(v2))", v)],
                    explicacion: "A: \(l1) × \(a1) × \(h1) = \(t(v1)) cm³. B: \(l2) × \(a2) × \(h2) = \(t(v2)) cm³. Total: \(t(v1)) + \(t(v2)) = \(t(v)) cm³.",
                    clave: "dos|\(l1)|\(a1)|\(h1)|\(l2)|\(a2)|\(h2)",
                    datos: ["forma": "ortoedros", "medidas": "\(l1)×\(a1)×\(h1)+\(l2)×\(a2)×\(h2)", "factor": "1"])
    }

    /// Depósito con agua hasta una altura, medidas decimales en metros → litros.
    static func deposito(rng: inout GeneradorConSemilla) -> Caso {
        let L = rng.elemento([rac(6, 5), rac(3, 2), rac(2), rac(12, 5), rac(5, 2), rac(3)])
        let A = rng.elemento([rac(4, 5), rac(1), rac(6, 5), rac(3, 2)])
        let H = rng.elemento([rac(1), rac(6, 5), rac(3, 2)])
        let h = rng.elemento([rac(2, 5), rac(1, 2), rac(3, 5), rac(3, 4), rac(4, 5)])
        let base = L * A, m3 = base * h, litros = m3 * rac(1000)
        return Caso(solidos: [caja("A", L, A, H)],
                    rotulos: [.init(solido: "A", arista: .largo, texto: "\(t(L)) m"), .init(solido: "A", arista: .ancho, texto: "\(t(A)) m"),
                              .init(solido: "A", arista: .alto, texto: "\(t(H)) m"), .init(solido: "A", arista: .agua, texto: "\(t(h)) m")],
                    agua: d(h),
                    campos: [campo("base", "Área de la base (m²)", base), campo("agua", "Altura del agua (m)", h), campo("m3", "Volumen del agua (m³)", m3)],
                    resultado: litros, unidad: "l", unidades: ["m²", "m³", "l"], etiqueta: "Litros de agua",
                    descripcion: "Depósito con forma de ortoedro de \(t(L)) m de largo, \(t(A)) m de ancho y \(t(H)) m de alto. El agua llega a \(t(h)) m de altura.",
                    enunciado: "Un depósito de \(t(L)) m de largo, \(t(A)) m de ancho y \(t(H)) m de alto tiene agua hasta \(t(h)) m de altura. ¿Cuántos litros de agua hay?",
                    erroneos: ["sinLitros": m3, "conversion10": m3 * rac(10), "conversion100": m3 * rac(100),
                               "lleno": base * H * rac(1000), "area": base],
                    pasos: [Pasos.op("Calcula el volumen del agua", "\(t(L)) × \(t(A)) × \(t(h))", m3, porque: "porque el agua ocupa un ortoedro de altura \(t(h)) m"),
                            Pasos.op("Pásalo a litros", "\(t(m3)) × 1000", litros, porque: "porque 1 m³ = 1000 dm³ = 1000 l")],
                    explicacion: "El agua ocupa \(t(L)) × \(t(A)) × \(t(h)) = \(t(m3)) m³. Como 1 m³ = 1000 l, hay \(t(m3)) × 1000 = \(t(litros)) l.",
                    clave: "deposito|\(t(L))|\(t(A))|\(t(H))|\(t(h))",
                    datos: ["forma": "ortoedros", "medidas": "\(t(L))×\(t(A))×\(t(h))", "factor": "1000"])
    }

    /// Cilindro con π = 3,14; a veces se da el diámetro.
    static func cilindro(rng: inout GeneradorConSemilla) -> Caso {
        let r = rng.entero(2...10), h = rng.entero(5...30)
        let conDiametro = rng.probabilidad(0.5)
        let R = rac(r), Hh = rac(h)
        let base = pi * R * R, v = base * Hh
        var erroneos: [String: Racional] = ["area": base, "sumaDimensiones": R + Hh]
        if conDiametro { erroneos["diametroRadio"] = pi * rac(2 * r) * rac(2 * r) * Hh }
        let medida = conDiametro ? V.Rotulo(solido: "A", arista: .diametro, texto: "\(2 * r) cm") : V.Rotulo(solido: "A", arista: .radio, texto: "\(r) cm")
        let o = rng.elemento(["un bote", "una lata", "un vaso", "una hucha"])
        var pasos: [PasoResuelto] = []
        if conDiametro { pasos.append(Pasos.op("Calcula el radio", "\(2 * r) : 2", R, porque: "porque el radio es la mitad del diámetro")) }
        pasos += [Pasos.op("Calcula el área de la base", "3,14 × \(r) × \(r)", base, porque: conDiametro ? nil : "porque la base es un círculo: π · r²"),
                  Pasos.op("Multiplica por la altura", "\(t(base)) × \(h)", v)]
        return Caso(solidos: [.init(id: "A", forma: .cilindro, largo: Double(2 * r), ancho: Double(2 * r), alto: Double(h))],
                    rotulos: [medida, .init(solido: "A", arista: .alto, texto: "\(h) cm")],
                    agua: nil,
                    campos: [campo("base", "Área de la base (cm²)", base), campo("altura", "Altura (cm)", Hh)],
                    resultado: v, unidad: "cm³", unidades: ["cm²", "cm³", "l"], etiqueta: "Volumen",
                    descripcion: "Cilindro de \(conDiametro ? "\(2 * r) cm de diámetro" : "\(r) cm de radio") y \(h) cm de altura.",
                    enunciado: "Calcula el volumen de \(o) con forma de cilindro (toma π = 3,14).",
                    erroneos: erroneos, pasos: pasos,
                    explicacion: (conDiametro ? "El radio es \(2 * r) : 2 = \(r) cm. " : "") + "Volumen = π · r² · h = 3,14 × \(r) × \(r) × \(h) = \(t(v)) cm³.",
                    clave: "cilindro|\(r)|\(h)|\(conDiametro)|\(o)",
                    datos: ["forma": "cilindro", "medidas": "\(r)×\(h)", "factor": "1"])
    }

    /// Unidades mixtas: largo en m, ancho en cm y alto en dm → litros.
    static func mixtas(rng: inout GeneradorConSemilla) -> Caso {
        let Lm = rng.elemento([rac(1), rac(6, 5), rac(3, 2), rac(2)]), Acm = rac(rng.elemento([40, 50, 60, 80])), Hdm = rac(rng.elemento([3, 4, 5, 6]))
        let L = Lm * rac(10), A = Acm * rac(1, 10)
        let base = L * A, v = base * Hdm
        return Caso(solidos: [caja("A", L, A, Hdm)],
                    rotulos: [.init(solido: "A", arista: .largo, texto: "\(t(Lm)) m"), .init(solido: "A", arista: .ancho, texto: "\(t(Acm)) cm"),
                              .init(solido: "A", arista: .alto, texto: "\(t(Hdm)) dm")],
                    agua: nil,
                    campos: [campo("largo", "Largo (dm)", L), campo("ancho", "Ancho (dm)", A), campo("base", "Área de la base (dm²)", base)],
                    resultado: v, unidad: "l", unidades: ["dm²", "m³", "l"], etiqueta: "Capacidad",
                    descripcion: "Caja con forma de ortoedro de \(t(Lm)) m de largo, \(t(Acm)) cm de ancho y \(t(Hdm)) dm de alto.",
                    enunciado: "Una caja mide \(t(Lm)) m de largo, \(t(Acm)) cm de ancho y \(t(Hdm)) dm de alto. ¿Cuántos litros caben?",
                    erroneos: ["sinConvertir": Lm * Acm * Hdm, "sumaDimensiones": L + A + Hdm, "area": base],
                    pasos: [Pasos.op("Pasa el largo a dm", "\(t(Lm)) × 10", L, porque: "porque 1 dm³ = 1 l: todo en decímetros"),
                            Pasos.op("Pasa el ancho a dm", "\(t(Acm)) : 10", A),
                            Pasos.op("Multiplica las tres medidas", "\(t(L)) × \(t(A)) × \(t(Hdm))", v)],
                    explicacion: "En decímetros: \(t(L)) × \(t(A)) × \(t(Hdm)) = \(t(v)) dm³ = \(t(v)) l.",
                    clave: "mixtas|\(t(Lm))|\(t(Acm))|\(t(Hdm))",
                    datos: ["forma": "ortoedros", "medidas": "\(t(L))×\(t(A))×\(t(Hdm))", "factor": "1"])
    }

    /// Se sacan litros de un depósito: nueva altura del agua en centímetros.
    static func extraer(rng: inout GeneradorConSemilla) -> Caso {
        let l = rng.elemento([4, 5, 6, 8, 10]), a = rng.elemento([3, 4, 5, 6]), hcm = rng.elemento([40, 50, 60, 70, 80])
        let bajadaCm = rng.elemento([10, 15, 20, 25, 30])
        let base = rac(l * a)                                 // dm²
        let litros = base * rac(bajadaCm, 10)                 // dm³
        let alturaDm = rac(hcm / 10 + 2)
        let nueva = rac(hcm - bajadaCm)
        return Caso(solidos: [caja("A", rac(l), rac(a), alturaDm)],
                    rotulos: [.init(solido: "A", arista: .largo, texto: "\(l) dm"), .init(solido: "A", arista: .ancho, texto: "\(a) dm"),
                              .init(solido: "A", arista: .agua, texto: "\(hcm) cm")],
                    agua: Double(hcm) / 10,
                    campos: [campo("base", "Área de la base (dm²)", base), campo("bajada", "Lo que baja el agua (cm)", rac(bajadaCm))],
                    resultado: nueva, unidad: "cm", unidades: ["cm", "cm²", "l"], etiqueta: "Altura del agua",
                    descripcion: "Depósito con forma de ortoedro de \(l) dm de largo y \(a) dm de ancho. El agua llega a \(hcm) cm de altura.",
                    enunciado: "Del depósito se sacan \(t(litros)) litros de agua. ¿A qué altura queda el agua? Da el resultado en cm.",
                    erroneos: ["bajada": rac(bajadaCm), "sinConvertir": rac(hcm) - rac(bajadaCm, 10)],
                    pasos: [Pasos.op("Calcula el área de la base", "\(l) × \(a)", base, porque: "porque los litros son dm³: se dividen entre el área en dm²"),
                            Pasos.op("Calcula cuánto baja (dm)", "\(t(litros)) : \(t(base))", rac(bajadaCm, 10)),
                            Pasos.op("Resta lo que baja (cm)", "\(hcm) − \(bajadaCm)", nueva)],
                    explicacion: "\(t(litros)) l = \(t(litros)) dm³. Baja \(t(litros)) : \(t(base)) = \(t(rac(bajadaCm, 10))) dm = \(bajadaCm) cm, así que queda a \(hcm) − \(bajadaCm) = \(t(nueva)) cm.",
                    clave: "extraer|\(l)|\(a)|\(hcm)|\(bajadaCm)",
                    datos: ["forma": "extraer", "medidas": "\(l)×\(a)×\(hcm)×\(t(litros))", "factor": "1"])
    }

    // MARK: Muestra

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nivel = min(max(p.dificultad, 1), 6)
        let c = caso(nivel, rng: &rng)
        let cubos = c.admiteCubos && p.peldano <= Peldano.practica.rawValue
        let erroneos = c.erroneos.filter { $0.value != c.resultado && $0.value.numerador > 0 }
        let figura = V(solidos: c.solidos, rotulos: c.rotulos, agua: c.agua, cubos: cubos, campos: cubos ? c.camposCubos : c.campos,
                       resultado: Self.t(c.resultado), unidad: c.unidad, unidadesOpciones: c.unidades, etiquetaResultado: c.etiqueta,
                       descripcion: c.descripcion, erroneos: erroneos.mapValues(Self.t))
        var errores = [
            ErrorHabitual(respuesta: "sumaDimensiones", feedback: "Has sumado las medidas: el volumen se obtiene multiplicándolas."),
            ErrorHabitual(respuesta: "area", feedback: "Eso es el área de la base: falta multiplicar por la altura."),
            ErrorHabitual(respuesta: "conversion10", feedback: "Entre unidades cúbicas se multiplica o se divide por 1000, no por 10."),
            ErrorHabitual(respuesta: "conversion100", feedback: "Entre unidades cúbicas se multiplica o se divide por 1000, no por 100."),
            ErrorHabitual(respuesta: "sinLitros", feedback: "Te falta pasar el volumen a litros: 1 l = 1 dm³."),
            ErrorHabitual(respuesta: "diametroRadio", feedback: "Has usado el diámetro como radio: el radio es la mitad del diámetro."),
            ErrorHabitual(respuesta: "sinConvertir", feedback: "Pasa todas las medidas a la misma unidad antes de operar."),
            ErrorHabitual(respuesta: "lleno", feedback: "Usa la altura del agua, no la del depósito."),
            ErrorHabitual(respuesta: "bajada", feedback: "Eso es lo que baja el agua: réstalo de la altura que tenía."),
        ].filter { figura.erroneos[$0.respuesta] != nil }
        errores += figura.campos.map { ErrorHabitual(respuesta: "campo_\($0.id)", feedback: "Revisa ese paso con las medidas del dibujo.") }
        errores += [ErrorHabitual(respuesta: "resultado", feedback: "Revisa la operación: el volumen es el área de la base por la altura."),
                    ErrorHabitual(respuesta: "unidad", feedback: "Revisa la unidad: el volumen va en unidades cúbicas o en litros.")]
        let pistas = cubos ? ["Cuenta los cubos de una capa y cuántas capas hay."] : ["Piensa en capas: el área de la base es una capa y la altura dice cuántas hay."]
        var datos = c.datos
        datos["resultado"] = Self.t(c.resultado)
        datos["unidad"] = c.unidad
        datos["nivel"] = "\(nivel)"
        // El último paso da la solución tal como la describe la app (valor y unidad).
        var pasos = c.pasos
        pasos[pasos.count - 1].valor = DescripcionSolucion.texto(.figuraVolumen(figura))
        return Muestra(clave: c.clave, valores: ["pregunta": c.enunciado], payload: .figuraVolumen(figura), explicacion: c.explicacion,
                       erroresHabituales: errores, pistas: pistas,
                       complejidad: Double(nivel) + Double(c.pasos.count) * 0.1 + (c.resultado.esEntero ? 0 : 0.2),
                       datos: datos, juego: Self.juego).conPasos(pasos)
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
