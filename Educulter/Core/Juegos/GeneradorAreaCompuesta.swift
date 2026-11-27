import Foundation

/// J63 «Corta y compensa» (MAT.GEO.AREA, Fase 05G §5, D-119): figuras compuestas sobre una cuadrícula.
///
/// | Nivel | Figura |
/// |---|---|
/// | 1 | forma de L con enteros pequeños (cm) |
/// | 2 | rectángulo con hueco rectangular |
/// | 3 | rectángulo + triángulo (casa) |
/// | 4 | perfil del examen: 3 partes, medidas decimales en m |
/// | 5 | rectángulo + semicírculo, π = 3,14 en el enunciado |
/// | 6 | medidas en m y cm que hay que convertir antes |
///
/// Cada figura trae todas sus descomposiciones válidas (sumar partes o restar el hueco) con sus
/// cortes; el área total la comprueba en los tests un oráculo independiente de los cortes.
struct GeneradorAreaCompuesta: GeneradorItems {
    let tipo = "areaCompuesta"
    let mecanicas: Set<Mecanica> = [.figuraArea]
    let marcadores: Set<String> = ["pregunta", "contexto"]

    typealias F = Payload.FiguraArea
    static let pi = rac(314, 100)

    static func t(_ v: Racional) -> String { FormatoNumero.numero(v) }
    static func d(_ v: Racional) -> Double { v.valorDouble }
    static func pt(_ x: Racional, _ y: Racional) -> F.Punto { .init(x: d(x), y: d(y)) }
    static func rect(_ x: Racional, _ y: Racional, _ w: Racional, _ h: Racional) -> F.Forma {
        .poligono([pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h)])
    }

    /// Figura generada: el payload sin rellenar del todo y lo que necesitan los pasos y los errores.
    struct Caso {
        var region: [F.Parte]
        var ancho: Racional, alto: Racional, paso: Racional
        var rotulos: [F.Rotulo]
        var cortes: [F.Segmento]
        var descomposiciones: [F.Descomposicion]
        var total: Racional
        var unidad: String
        var perimetro: Racional?
        var erroneos: [String: Racional]
        var descripcion: String
        var enunciado: String
        var clave: String
        var partesExamen: Int
    }

    static func parte(_ id: String, _ forma: F.Forma, _ signo: Int, _ area: Racional, _ calculo: String) -> F.Parte {
        F.Parte(id: id, forma: forma, signo: signo, area: t(area), calculo: calculo)
    }

    static func rotulo(_ a: F.Punto, _ b: F.Punto, _ texto: String) -> F.Rotulo { .init(a: a, b: b, texto: texto) }
    static func seg(_ id: String, _ a: F.Punto, _ b: F.Punto) -> F.Segmento { .init(id: id, a: a, b: b) }

    // MARK: Casos por nivel

    func caso(_ nivel: Int, rng: inout GeneradorConSemilla) -> Caso {
        switch nivel {
        case 1: return Self.ele(ancho: rac(rng.entero(5...10)), alto: rac(rng.entero(5...10)), rng: &rng, unidad: "cm", mixtas: false)
        case 2: return Self.hueco(rng: &rng)
        case 3: return Self.casa(rng: &rng)
        case 4: return Self.escalera(rng: &rng)
        case 5: return Self.semicirculo(rng: &rng)
        default: return Self.ele(ancho: rac(rng.entero(4...8)), alto: rac(rng.entero(4...8)), rng: &rng, unidad: "m", mixtas: true)
        }
    }

    /// Forma de L: un rectángulo al que le falta la esquina superior derecha.
    static func ele(ancho w: Racional, alto h: Racional, rng: inout GeneradorConSemilla, unidad u: String, mixtas: Bool) -> Caso {
        let cw = rac(rng.entero(1...(Int(w.valorDouble) - 2))), ch = rac(rng.entero(1...(Int(h.valorDouble) - 2)))
        let a = w - cw
        // Etiquetas: en el nivel 6, algunas medidas en centímetros.
        func et(_ v: Racional, cm: Bool) -> String { mixtas && cm ? "\(t(v * rac(100))) cm" : "\(t(v)) \(u)" }
        let rotulos = [rotulo(pt(rac(0), h), pt(w, h), et(w, cm: false)), rotulo(pt(rac(0), rac(0)), pt(rac(0), h), et(h, cm: true)),
                       rotulo(pt(rac(0), rac(0)), pt(a, rac(0)), et(a, cm: true)), rotulo(pt(a, ch), pt(w, ch), et(cw, cm: false)),
                       rotulo(pt(a, rac(0)), pt(a, ch), et(ch, cm: true)), rotulo(pt(w, ch), pt(w, h), et(h - ch, cm: false))]
        let v = seg("v", pt(a, ch), pt(a, h)), hz = seg("h", pt(rac(0), ch), pt(a, ch))
        let r1 = seg("r1", pt(a, rac(0)), pt(w, rac(0))), r2 = seg("r2", pt(w, rac(0)), pt(w, ch))
        let u2 = "\(u)²"
        let descs = [
            F.Descomposicion(id: "sumarV", estrategia: .sumar, cortes: ["v"], partes: [
                parte("A", rect(rac(0), rac(0), a, h), 1, a * h, "\(t(a)) × \(t(h)) = \(t(a * h))"),
                parte("B", rect(a, ch, cw, h - ch), 1, cw * (h - ch), "\(t(cw)) × \(t(h - ch)) = \(t(cw * (h - ch)))")]),
            F.Descomposicion(id: "sumarH", estrategia: .sumar, cortes: ["h"], partes: [
                parte("A", rect(rac(0), rac(0), a, ch), 1, a * ch, "\(t(a)) × \(t(ch)) = \(t(a * ch))"),
                parte("B", rect(rac(0), ch, w, h - ch), 1, w * (h - ch), "\(t(w)) × \(t(h - ch)) = \(t(w * (h - ch)))")]),
            F.Descomposicion(id: "restar", estrategia: .restar, cortes: ["r1", "r2"], partes: [
                parte("A", rect(rac(0), rac(0), w, h), 1, w * h, "\(t(w)) × \(t(h)) = \(t(w * h))"),
                parte("B", rect(a, rac(0), cw, ch), -1, cw * ch, "\(t(cw)) × \(t(ch)) = \(t(cw * ch))")]),
        ]
        let total = w * h - cw * ch
        let contorno = F.Forma.poligono([pt(rac(0), rac(0)), pt(a, rac(0)), pt(a, ch), pt(w, ch), pt(w, h), pt(rac(0), h)])
        var erroneos: [String: Racional] = ["sumaHueco": w * h + cw * ch, "perimetro": rac(2) * (w + h)]
        if mixtas {
            // Sin convertir (restando): ancho en m por alto en cm, menos el hueco igual → 100 veces el total.
            erroneos["sinConvertir"] = total * rac(100)
        }
        let lugar = u == "cm" ? "una pieza de cartulina" : "un patio"
        return Caso(region: [parte("L", contorno, 1, total, "")], ancho: w, alto: h, paso: rac(1), rotulos: rotulos,
                    cortes: [v, hz, r1, r2], descomposiciones: descs, total: total, unidad: u2, perimetro: rac(2) * (w + h),
                    erroneos: erroneos,
                    descripcion: "Figura en forma de L: un rectángulo de \(et(w, cm: false)) de ancho y \(et(h, cm: true)) de alto al que le falta, arriba a la derecha, un rectángulo de \(et(cw, cm: false)) por \(et(ch, cm: true)).",
                    enunciado: mixtas ? "Calcula el área de \(lugar) con esta forma. Algunas medidas están en centímetros y otras en metros: da el resultado en m²."
                        : "Calcula el área de \(lugar) con esta forma.",
                    clave: "L|\(t(w))|\(t(h))|\(t(cw))|\(t(ch))|\(u)|\(mixtas)", partesExamen: 2)
    }

    /// Rectángulo con un hueco rectangular dentro.
    static func hueco(rng: inout GeneradorConSemilla) -> Caso {
        let w = rac(rng.entero(6...12)), h = rac(rng.entero(5...10))
        // Hueco de al menos 2 × 2 para que se vea y sus rótulos no se monten.
        let hw = rac(rng.entero(2...(Int(w.valorDouble) - 3))), hh = rac(rng.entero(2...(Int(h.valorDouble) - 3)))
        let x0 = rac(rng.entero(1...(Int((w - hw).valorDouble) - 1))), y0 = rac(rng.entero(1...(Int((h - hh).valorDouble) - 1)))
        let total = w * h - hw * hh
        let cortes = [seg("s1", pt(rac(0), y0), pt(x0, y0)), seg("s2", pt(x0 + hw, y0), pt(w, y0)),
                      seg("s3", pt(rac(0), y0 + hh), pt(x0, y0 + hh)), seg("s4", pt(x0 + hw, y0 + hh), pt(w, y0 + hh))]
        let abajo = h - y0 - hh, derecha = w - x0 - hw
        let descs = [
            F.Descomposicion(id: "restar", estrategia: .restar, cortes: [], partes: [
                parte("A", rect(rac(0), rac(0), w, h), 1, w * h, "\(t(w)) × \(t(h)) = \(t(w * h))"),
                parte("B", rect(x0, y0, hw, hh), -1, hw * hh, "\(t(hw)) × \(t(hh)) = \(t(hw * hh))")]),
            F.Descomposicion(id: "sumar", estrategia: .sumar, cortes: ["s1", "s2", "s3", "s4"], partes: [
                parte("A", rect(rac(0), rac(0), w, y0), 1, w * y0, "\(t(w)) × \(t(y0)) = \(t(w * y0))"),
                parte("B", rect(rac(0), y0 + hh, w, abajo), 1, w * abajo, "\(t(w)) × \(t(abajo)) = \(t(w * abajo))"),
                parte("C", rect(rac(0), y0, x0, hh), 1, x0 * hh, "\(t(x0)) × \(t(hh)) = \(t(x0 * hh))"),
                parte("D", rect(x0 + hw, y0, derecha, hh), 1, derecha * hh, "\(t(derecha)) × \(t(hh)) = \(t(derecha * hh))")]),
        ]
        let rotulos = [rotulo(pt(rac(0), h), pt(w, h), "\(t(w)) cm"), rotulo(pt(rac(0), rac(0)), pt(rac(0), h), "\(t(h)) cm"),
                       rotulo(pt(x0, y0 + hh), pt(x0 + hw, y0 + hh), "\(t(hw)) cm"), rotulo(pt(x0 + hw, y0), pt(x0 + hw, y0 + hh), "\(t(hh)) cm"),
                       // Distancias del hueco a los bordes, a media altura y a media anchura del hueco (no se tapan).
                       rotulo(pt(rac(0), y0 + hh * rac(1, 2)), pt(x0, y0 + hh * rac(1, 2)), "\(t(x0)) cm"),
                       rotulo(pt(x0 + hw * rac(1, 2), rac(0)), pt(x0 + hw * rac(1, 2), y0), "\(t(y0)) cm")]
        return Caso(region: [parte("R", rect(rac(0), rac(0), w, h), 1, w * h, ""), parte("H", rect(x0, y0, hw, hh), -1, hw * hh, "")],
                    ancho: w, alto: h, paso: rac(1), rotulos: rotulos, cortes: cortes, descomposiciones: descs, total: total,
                    unidad: "cm²", perimetro: rac(2) * (w + h),
                    erroneos: ["sumaHueco": w * h + hw * hh, "perimetro": rac(2) * (w + h)],
                    descripcion: "Rectángulo de \(t(w)) cm por \(t(h)) cm con un hueco rectangular de \(t(hw)) cm por \(t(hh)) cm, a \(t(x0)) cm del borde izquierdo y a \(t(y0)) cm del borde superior.",
                    enunciado: "Un marco de fotos tiene esta forma: la parte blanca es el hueco. Calcula el área del marco.",
                    clave: "hueco|\(t(w))|\(t(h))|\(t(hw))|\(t(hh))|\(t(x0))|\(t(y0))", partesExamen: 2)
    }

    /// Casa: rectángulo con un triángulo encima.
    static func casa(rng: inout GeneradorConSemilla) -> Caso {
        let w = rac(rng.entero(3...6) * 2), h = rac(rng.entero(3...8)), tt = rac(rng.entero(2...5))
        let total = w * h + w * tt * rac(1, 2)
        let base = seg("base", pt(rac(0), tt), pt(w, tt))
        let triangulo = F.Forma.poligono([pt(rac(0), tt), pt(w * rac(1, 2), rac(0)), pt(w, tt)])
        let descs = [F.Descomposicion(id: "sumar", estrategia: .sumar, cortes: ["base"], partes: [
            parte("A", rect(rac(0), tt, w, h), 1, w * h, "\(t(w)) × \(t(h)) = \(t(w * h))"),
            parte("B", triangulo, 1, w * tt * rac(1, 2), "\(t(w)) × \(t(tt)) : 2 = \(t(w * tt * rac(1, 2)))")])]
        let rotulos = [rotulo(pt(rac(0), tt + h), pt(w, tt + h), "\(t(w)) cm"), rotulo(pt(rac(0), tt), pt(rac(0), tt + h), "\(t(h)) cm"),
                       rotulo(pt(w * rac(1, 2), rac(0)), pt(w * rac(1, 2), tt), "\(t(tt)) cm")]
        return Caso(region: [parte("A", rect(rac(0), tt, w, h), 1, w * h, ""), parte("B", triangulo, 1, w * tt * rac(1, 2), "")],
                    ancho: w, alto: tt + h, paso: rac(1), rotulos: rotulos, cortes: [base], descomposiciones: descs, total: total,
                    unidad: "cm²", perimetro: nil,
                    erroneos: ["trianguloSinMitad": w * h + w * tt, "sumaHueco": w * (h + tt)],
                    descripcion: "Figura de casa: un rectángulo de \(t(w)) cm de ancho y \(t(h)) cm de alto con un tejado triangular de \(t(tt)) cm de altura sobre todo el ancho.",
                    enunciado: "Calcula el área de la fachada de esta casa de juguete.",
                    clave: "casa|\(t(w))|\(t(h))|\(t(tt))", partesExamen: 2)
    }

    /// Perfil del examen: tres rectángulos escalonados con medidas decimales en metros.
    static func escalera(rng: inout GeneradorConSemilla) -> Caso {
        func dec() -> Racional { rac(rng.entero(3...9) * 2 + 1, 2) }   // 1,5 … 9,5
        let a = dec(), b = dec(), c = dec()
        let h3 = rac(rng.entero(2...4)), h2 = h3 + rac(rng.entero(1...3)), h1 = h2 + rac(rng.entero(1...3))
        let w = a + b + c
        // Escalones de altura decreciente de izquierda a derecha, apoyados en el suelo (y = h1).
        let total = a * h1 + b * h2 + c * h3
        let contorno = F.Forma.poligono([pt(rac(0), rac(0)), pt(a, rac(0)), pt(a, h1 - h2), pt(a + b, h1 - h2), pt(a + b, h1 - h3),
                                         pt(w, h1 - h3), pt(w, h1), pt(rac(0), h1)])
        let v1 = seg("v1", pt(a, h1 - h2), pt(a, h1)), v2 = seg("v2", pt(a + b, h1 - h3), pt(a + b, h1))
        let k1 = seg("k1", pt(rac(0), h1 - h2), pt(a, h1 - h2)), k2 = seg("k2", pt(rac(0), h1 - h3), pt(a + b, h1 - h3))
        // Restar (05H): el rectángulo que la envuelve menos los dos huecos de arriba a la derecha.
        let q1 = seg("q1", pt(a, rac(0)), pt(w, rac(0))), q2 = seg("q2", pt(w, rac(0)), pt(w, h1 - h3))
        let q3 = seg("q3", pt(a + b, h1 - h2), pt(w, h1 - h2))
        let descs = [
            F.Descomposicion(id: "vertical", estrategia: .sumar, cortes: ["v1", "v2"], partes: [
                parte("A", rect(rac(0), rac(0), a, h1), 1, a * h1, "\(t(a)) × \(t(h1)) = \(t(a * h1))"),
                parte("B", rect(a, h1 - h2, b, h2), 1, b * h2, "\(t(b)) × \(t(h2)) = \(t(b * h2))"),
                parte("C", rect(a + b, h1 - h3, c, h3), 1, c * h3, "\(t(c)) × \(t(h3)) = \(t(c * h3))")]),
            F.Descomposicion(id: "horizontal", estrategia: .sumar, cortes: ["k1", "k2"], partes: [
                parte("A", rect(rac(0), rac(0), a, h1 - h2), 1, a * (h1 - h2), "\(t(a)) × \(t(h1 - h2)) = \(t(a * (h1 - h2)))"),
                parte("B", rect(rac(0), h1 - h2, a + b, h2 - h3), 1, (a + b) * (h2 - h3), "\(t(a + b)) × \(t(h2 - h3)) = \(t((a + b) * (h2 - h3)))"),
                parte("C", rect(rac(0), h1 - h3, w, h3), 1, w * h3, "\(t(w)) × \(t(h3)) = \(t(w * h3))")]),
            F.Descomposicion(id: "restar", estrategia: .restar, cortes: ["q1", "q2", "q3"], partes: [
                parte("A", rect(rac(0), rac(0), w, h1), 1, w * h1, "\(t(w)) × \(t(h1)) = \(t(w * h1))"),
                parte("B", rect(a, rac(0), b + c, h1 - h2), -1, (b + c) * (h1 - h2), "\(t(b + c)) × \(t(h1 - h2)) = \(t((b + c) * (h1 - h2)))"),
                parte("C", rect(a + b, h1 - h2, c, h2 - h3), -1, c * (h2 - h3), "\(t(c)) × \(t(h2 - h3)) = \(t(c * (h2 - h3)))")]),
        ]
        let rotulos = [rotulo(pt(rac(0), h1), pt(a, h1), "\(t(a)) m"), rotulo(pt(a, h1), pt(a + b, h1), "\(t(b)) m"),
                       rotulo(pt(a + b, h1), pt(w, h1), "\(t(c)) m"), rotulo(pt(rac(0), rac(0)), pt(rac(0), h1), "\(t(h1)) m"),
                       rotulo(pt(a, h1 - h2), pt(a, h1), "\(t(h2)) m"), rotulo(pt(w, h1 - h3), pt(w, h1), "\(t(h3)) m")]
        let perimetro = rac(2) * (w + h1)
        return Caso(region: [parte("E", contorno, 1, total, "")], ancho: w, alto: h1, paso: rac(1, 2), rotulos: rotulos,
                    cortes: [v1, v2, k1, k2, q1, q2, q3], descomposiciones: descs, total: total, unidad: "m²", perimetro: perimetro,
                    erroneos: ["perimetro": perimetro, "sumaHueco": w * h1],
                    descripcion: "Fachada escalonada de tres tramos, de izquierda a derecha: \(t(a)) m de ancho y \(t(h1)) m de alto; \(t(b)) m de ancho y \(t(h2)) m de alto; \(t(c)) m de ancho y \(t(h3)) m de alto.",
                    enunciado: "Hay que pintar esta fachada escalonada. Calcula su área.",
                    clave: "escalera|\(t(a))|\(t(b))|\(t(c))|\(t(h1))|\(t(h2))|\(t(h3))", partesExamen: 3)
    }

    /// Rectángulo con un semicírculo en el lado derecho (π = 3,14).
    static func semicirculo(rng: inout GeneradorConSemilla) -> Caso {
        let w = rac(rng.entero(4...10)), h = rac(rng.entero(2...6) * 2)
        let r = h * rac(1, 2)
        let medio = pi * r * r * rac(1, 2)
        let total = w * h + medio
        let circulo: Racional = w * h + pi * r * r
        let contornoSemi: Racional = rac(2) * w + h + pi * r
        let corte = seg("diametro", pt(w, rac(0)), pt(w, h))
        let semi = F.Forma.semicirculo(a: pt(w, rac(0)), b: pt(w, h))
        let descs = [F.Descomposicion(id: "sumar", estrategia: .sumar, cortes: ["diametro"], partes: [
            parte("A", rect(rac(0), rac(0), w, h), 1, w * h, "\(t(w)) × \(t(h)) = \(t(w * h))"),
            parte("B", semi, 1, medio, "3,14 × \(t(r)) × \(t(r)) : 2 = \(t(medio))")])]
        let rotulos = [rotulo(pt(rac(0), h), pt(w, h), "\(t(w)) m"), rotulo(pt(rac(0), rac(0)), pt(rac(0), h), "\(t(h)) m")]
        return Caso(region: [parte("A", rect(rac(0), rac(0), w, h), 1, w * h, ""), parte("B", semi, 1, medio, "")],
                    ancho: w + r, alto: h, paso: rac(1), rotulos: rotulos, cortes: [corte], descomposiciones: descs, total: total,
                    unidad: "m²", perimetro: nil,
                    erroneos: ["circuloEntero": circulo, "perimetro": contornoSemi],
                    descripcion: "Rectángulo de \(t(w)) m de ancho y \(t(h)) m de alto con un semicírculo en el lado derecho, cuyo diámetro es ese lado de \(t(h)) m.",
                    enunciado: "Un escenario tiene esta forma. Calcula su área (toma π = 3,14).",
                    clave: "semi|\(t(w))|\(t(h))", partesExamen: 2)
    }

    // MARK: Muestra

    func muestra(_ p: Plantilla, recursos: RecursosGeneradores, rng: inout GeneradorConSemilla) throws -> Muestra {
        let nivel = min(max(p.dificultad, 1), 6)
        let c = caso(nivel, rng: &rng)
        let unidadLineal = String(c.unidad.dropLast())
        let otra = c.unidad == "cm²" ? "m²" : "cm²"
        let figura = Payload.FiguraArea(region: c.region, ancho: Self.d(c.ancho), alto: Self.d(c.alto), paso: Self.d(c.paso), rotulos: c.rotulos,
                                        cortes: c.cortes, descomposiciones: c.descomposiciones, mostrarCortes: p.peldano <= Peldano.practica.rawValue,
                                        total: Self.t(c.total), unidad: c.unidad, unidadesOpciones: [unidadLineal, c.unidad, otra],
                                        descripcion: c.descripcion, erroneos: c.erroneos.filter { $0.value != c.total }.mapValues(Self.t))
        let primera = c.descomposiciones[0]
        let sumandos = primera.partes.map { ($0.signo > 0 ? "+ " : "− ") + $0.area }.joined(separator: " ").dropFirst(2)
        let explicacion = primera.partes.map { "\($0.id): \($0.calculo)" }.joined(separator: "; ")
            + ". Total: \(sumandos) = \(Self.t(c.total)) \(c.unidad). Se \(primera.estrategia == .restar ? "resta el hueco porque no forma parte" : "suman las partes porque juntas forman") de la región pintada."
        var pasos = primera.partes.prefix(4).map { parte -> PasoResuelto in
            PasoResuelto(frase: "Calcula el área de \(parte.id)", resultado: parte.calculo, valor: parte.area)
        }
        pasos[0].porque = primera.estrategia == .restar ? "porque el hueco no forma parte de la región pintada"
            : (nivel == 6 ? "porque antes hay que pasar todas las medidas a metros" : "porque el área de un rectángulo es base por altura")
        pasos.append(PasoResuelto(frase: primera.estrategia == .restar ? "Resta el hueco" : "Suma las partes",
                                  resultado: "\(sumandos) = \(Self.t(c.total)) \(c.unidad)", valor: "\(Self.t(c.total)) \(c.unidad)"))
        var errores = [
            ErrorHabitual(respuesta: "sumaHueco", feedback: "¿Esa parte pertenece a la región pintada?"),
            ErrorHabitual(respuesta: "perimetro", feedback: "Has sumado los lados: eso es el perímetro, no el área."),
            ErrorHabitual(respuesta: "trianguloSinMitad", feedback: "El área del triángulo es base por altura entre 2."),
            ErrorHabitual(respuesta: "circuloEntero", feedback: "Es medio círculo: su área es la mitad de la del círculo."),
            ErrorHabitual(respuesta: "sinConvertir", feedback: "Pasa todas las medidas a la misma unidad antes de operar."),
        ].filter { figura.erroneos[$0.respuesta] != nil }
        // Elegir restar sin hueco (casa, semicírculo) es un primer intento fallido con pista (05H).
        if !figura.estrategiasValidas.contains(.restar) {
            errores.append(ErrorHabitual(respuesta: "sinHueco", feedback: "Aquí no hay hueco que quitar: la figura se forma sumando partes."))
        }
        errores += ["A", "B", "C", "D"].map { ErrorHabitual(respuesta: "parte_\($0)", feedback: "Revisa qué dos medidas son la base y la altura de esa parte.") }
        errores += [ErrorHabitual(respuesta: "unidadLineal", feedback: "Multiplicas metros por metros: el área va en unidades cuadradas."),
                    ErrorHabitual(respuesta: "total", feedback: "Revisa la suma (o la resta) de las áreas de las partes.")]
        return Muestra(clave: c.clave, valores: ["pregunta": c.enunciado], payload: .figuraArea(figura), explicacion: explicacion,
                       erroresHabituales: errores, pistas: ["Divide la figura en rectángulos (o triángulos) cuya área sepas calcular."],
                       complejidad: Double(nivel) + Double(c.descomposiciones[0].partes.count) * 0.5 + (c.total.esEntero ? 0 : 1) + (nivel == 6 ? 2 : 0),
                       datos: ["total": Self.t(c.total), "unidad": c.unidad, "partes": "\(c.partesExamen)", "nivel": "\(nivel)"],
                       pasos: pasos, juego: "J63")
    }

    func enumerar(_ p: Plantilla, recursos: RecursosGeneradores, limite: Int) -> [String] {
        enumerarPorSemillas(self, p, recursos: recursos, limite: limite)
    }
}
