import Foundation
import Testing
@testable import Educulter

@Suite("Validador de contenido")
struct ValidadorTests {
    let validador = ValidadorContenido(anioActual: 2026)
    let competencias: Set<String> = ["LEN.SIN.SUJPRED", "MAT.NUM.FRACSUM"]

    func errores(_ item: Item) -> [String] {
        validador.validar(item: item, competencias: competencias).map(\.mensaje)
    }

    func errores(_ payload: Payload) -> [String] {
        validador.validar(payload: payload)
    }

    func contiene(_ mensajes: [String], _ texto: String) -> Bool {
        mensajes.contains { $0.contains(texto) }
    }

    @Test("Un ítem correcto no tiene errores")
    func itemCorrecto() {
        #expect(errores(Fx.item("LEN.SIN.SUJPRED.0001")).isEmpty)
    }

    @Test("Ids, competencia, rangos y longitudes")
    func reglasGenerales() {
        #expect(contiene(errores(Fx.item("LEN.SIN.SUJPRED.1", competencia: "LEN.SIN.SUJPRED")), "formato"))
        #expect(contiene(errores(Fx.item("MAT.NUM.FRACSUM.0001", competencia: "LEN.SIN.SUJPRED")), "formato"))
        #expect(contiene(errores(Fx.item("LEN.SIN.OTRA.0001")), "no existe en el catálogo"))
        #expect(contiene(errores(Fx.item("LEN.SIN.SUJPRED.0001", peldano: 6)), "peldaño 6"))
        #expect(contiene(errores(Fx.item("LEN.SIN.SUJPRED.0001", peldano: 0)), "peldaño 0"))
        #expect(contiene(errores(Fx.item("LEN.SIN.SUJPRED.0001", dificultad: 0)), "dificultad 0"))

        var item = Fx.item("LEN.SIN.SUJPRED.0001")
        item.explicacion = String(repeating: "a", count: 281)
        #expect(contiene(errores(item), "281 caracteres"))
        item.explicacion = String(repeating: "a", count: 280)
        #expect(errores(item).isEmpty)

        var conPistas = Fx.item("LEN.SIN.SUJPRED.0001", peldano: 3)
        conPistas.pistas = ["Una pista"]
        #expect(contiene(errores(conPistas), "no pueden tener pistas"))
        conPistas.peldano = 2
        #expect(errores(conPistas).isEmpty)

        item.objetivo = ""; item.enunciado = ""; item.explicacion = ""; item.version = 0
        let m = errores(item)
        #expect(contiene(m, "objetivo vacío") && contiene(m, "enunciado vacío") && contiene(m, "explicación vacía") && contiene(m, "versión"))
    }

    @Test("Ids duplicados en el banco y errores del catálogo")
    func duplicadosYCatalogo() {
        let a = Fx.item("LEN.SIN.SUJPRED.0001")
        var banco = Fx.banco([a, a])
        #expect(validador.validar(banco).contains { $0.mensaje.contains("duplicado") })

        let tarjeta = TarjetaTeoria(id: "LEN.SIN.SUJPRED.T01", competencia: "LEN.SIN.SUJPRED", titulo: "T",
                                    bloques: [.init(tipo: .texto, contenido: "Hola")], procedencia: Fx.original, validacion: Fx.borrador)
        let sim = Simulacro(id: "SIM.01", titulo: "S", duracionMin: 90, textoBase: nil, preguntas: [
            .init(numero: 1, area: "LEN", enunciado: "e", solucionModelo: "s", puntos: 1,
                  rubrica: .init(bien: "b", regular: "r", mal: "m"), competencias: ["LEN.SIN.SUJPRED"])
        ], validacion: Fx.borrador)
        banco = BancoContenido(catalogo: banco.catalogo, items: [a], teoria: [tarjeta, tarjeta], simulacros: [sim, sim])
        let m = validador.validar(banco).map(\.description)
        #expect(m.contains { $0.contains("tarjeta duplicado") })
        #expect(m.contains { $0.contains("simulacro duplicado") })

        let catalogo = Catalogo(version: 0, areas: [
            .init(id: "Lengua", nombre: "", bloques: [
                .init(id: "LEN.SINTAXIS", nombre: "", prioridad: 4, orden: 1, competencias: [
                    .init(id: "LEN.X", nombre: "", orden: 1), .init(id: "LEN.X", nombre: "n", orden: 2)
                ])
            ])
        ])
        let mc = validador.validar(catalogo: catalogo).map(\.mensaje)
        #expect(contiene(mc, "versión"))
        #expect(contiene(mc, "id de área no válido"))
        #expect(contiene(mc, "id de bloque no válido"))
        #expect(contiene(mc, "prioridad 4"))
        #expect(contiene(mc, "id de competencia no válido"))
        #expect(contiene(mc, "duplicado en el catálogo"))
        #expect(contiene(mc, "nombre vacío"))
        #expect(validador.validar(catalogo: Fx.catalogo(["LEN.SIN.SUJPRED", "MAT.NUM.FRACSUM"])).isEmpty)
    }

    @Test("Errores habituales y referencias")
    func erroresHabitualesYReferencia() {
        var item = Fx.item("LEN.SIN.SUJPRED.0001", payload: .eleccion(.init(
            opciones: [.init(id: "a", texto: "A"), .init(id: "b", texto: "B")], correcta: "a")))
        item.erroresHabituales = [.init(respuesta: "a", feedback: "f"), .init(respuesta: "z", feedback: "f"),
                                  .init(respuesta: "", feedback: "")]
        item.referencia = Referencia(tipoPregunta: "t", examenes: ["2017-L9", "2017-9", "examen"], normativa: nil)
        let m = errores(item)
        #expect(contiene(m, "es la opción correcta"))
        #expect(contiene(m, "«z» no es una opción"))
        #expect(contiene(m, "respuesta o feedback vacíos"))
        #expect(contiene(m, "«2017-9»") && contiene(m, "«examen»") && !contiene(m, "«2017-L9»"))
    }

    @Test("Payload: elección, verdadero/falso, clasificar, ordenar")
    func payloadsSimples() {
        #expect(contiene(errores(.eleccion(.init(opciones: [.init(id: "a", texto: "A")], correcta: "z"))), "2–4 opciones"))
        #expect(contiene(errores(.eleccion(.init(opciones: [.init(id: "a", texto: "A"), .init(id: "a", texto: "B")], correcta: "z"))), "no existe"))
        #expect(contiene(errores(.eleccion(.init(opciones: [.init(id: "a", texto: "A"), .init(id: "a", texto: "B")], correcta: "a"))), "repetidos"))
        #expect(contiene(errores(.verdaderoFalso(.init(afirmacion: "", esVerdadera: true))), "afirmación vacía"))

        let clasificar = Payload.clasificar(.init(categorias: [.init(id: "A", nombre: "A")],
                                                  fichas: [.init(id: "f", texto: "x", categoria: "B")]))
        #expect(contiene(errores(clasificar), "2–4 categorías"))
        #expect(contiene(errores(clasificar), "categoría inexistente"))
        #expect(contiene(errores(.clasificar(.init(categorias: [.init(id: "A", nombre: "A"), .init(id: "B", nombre: "B")], fichas: []))), "no tiene fichas"))

        let fichas: [ElementoTexto] = [.init(id: "a", texto: "A"), .init(id: "b", texto: "B")]
        #expect(errores(.ordenar(.init(fichas: fichas, ordenCorrecto: ["b", "a"]))).isEmpty)
        #expect(contiene(errores(.ordenar(.init(fichas: fichas, ordenCorrecto: ["a", "a"]))), "permutación"))
        #expect(contiene(errores(.ordenar(.init(fichas: fichas, ordenCorrecto: ["a"]))), "permutación"))
        #expect(contiene(errores(.ordenar(.init(fichas: [fichas[0]], ordenCorrecto: ["a"]))), "al menos 2"))
    }

    @Test("Payload: emparejar y marcar texto")
    func emparejarYMarcar() {
        let izq: [ElementoTexto] = [.init(id: "i1", texto: "1"), .init(id: "i2", texto: "2")]
        let der: [ElementoTexto] = [.init(id: "d1", texto: "1"), .init(id: "d2", texto: "2")]
        #expect(errores(.emparejar(.init(izquierda: izq, derecha: der, pares: [["i1", "d1"], ["i2", "d2"]]))).isEmpty)
        #expect(contiene(errores(.emparejar(.init(izquierda: izq, derecha: der, pares: [["i1", "d1"]]))), "cubrir todos"))
        #expect(contiene(errores(.emparejar(.init(izquierda: izq, derecha: der, pares: [["i1", "d1"], ["i1", "d2"]]))), "cubrir todos"))
        #expect(contiene(errores(.emparejar(.init(izquierda: izq, derecha: der, pares: [["i1", "dX"], ["iX", "d2"]]))), "no está a la"))
        #expect(contiene(errores(.emparejar(.init(izquierda: izq, derecha: der, pares: [["i1"]]))), "exactamente 2"))

        let tokens: [ElementoTexto] = [.init(id: "t1", texto: "a"), .init(id: "t2", texto: "b")]
        #expect(errores(.marcarTexto(.init(unidad: .silaba, tokens: tokens, correctos: ["t1"]))).isEmpty)
        #expect(contiene(errores(.marcarTexto(.init(unidad: .palabra, tokens: tokens, correctos: []))), "no tiene tokens correctos"))
        #expect(contiene(errores(.marcarTexto(.init(unidad: .palabra, tokens: tokens, correctos: ["t9"]))), "no existe"))
        #expect(contiene(errores(.marcarTexto(.init(unidad: .palabra, tokens: tokens, correctos: ["t1", "t1"]))), "repetidos"))
    }

    static let tokens: [ElementoTexto] = ["Vive", "en", "la", "casa", "de", "Ana"].enumerated().map { .init(id: "t\($0 + 1)", texto: $1) }
    static let etiquetas: [ElementoNombre] = [.init(id: "PRED", nombre: "Predicado"), .init(id: "CCL", nombre: "CC de lugar"),
                                              .init(id: "SN", nombre: "SN"), .init(id: "CN", nombre: "CN")]

    func segmentar(_ s: [Payload.Segmentar.Segmento]) -> [String] {
        errores(.segmentar(.init(tokens: Self.tokens, etiquetas: Self.etiquetas, segmentos: s)))
    }

    @Test("Payload: segmentar con anidamiento válido e inválido")
    func segmentarAnidado() {
        typealias S = Payload.Segmentar.Segmento
        // Predicado [Vive [en [la casa [de Ana]CN]SN]CCL]
        let validos = [S(id: "p", desde: "t1", hasta: "t6", etiqueta: "PRED"),
                       S(id: "cc", desde: "t2", hasta: "t6", etiqueta: "CCL", padre: "p"),
                       S(id: "sn", desde: "t3", hasta: "t6", etiqueta: "SN", padre: "cc"),
                       S(id: "cn", desde: "t5", hasta: "t6", etiqueta: "CN", padre: "sn")]
        #expect(segmentar(validos).isEmpty)

        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t3", etiqueta: "SN"),
                                    S(id: "b", desde: "t3", hasta: "t5", etiqueta: "SN")]), "se solapan"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t6", etiqueta: "PRED"),
                                    S(id: "b", desde: "t2", hasta: "t3", etiqueta: "SN")]), "se solapan"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t3", etiqueta: "PRED"),
                                    S(id: "b", desde: "t2", hasta: "t5", etiqueta: "SN", padre: "a")]), "no está dentro"))
        #expect(contiene(segmentar([S(id: "a", desde: "t4", hasta: "t2", etiqueta: "SN")]), "empieza después"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t9", etiqueta: "SN")]), "tokens inexistentes"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t2", etiqueta: "XX")]), "etiqueta inexistente"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t2", etiqueta: "SN", padre: "zz")]), "padre inexistente"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t2", etiqueta: "SN", padre: "a")]), "padre inexistente"))
        #expect(contiene(segmentar([S(id: "a", desde: "t1", hasta: "t2", etiqueta: "SN", padre: "b"),
                                    S(id: "b", desde: "t1", hasta: "t2", etiqueta: "SN", padre: "a")]), "ciclo"))
        #expect(contiene(segmentar([]), "no tiene segmentos"))
    }

    @Test("Payload: ruedas y construir")
    func ruedasYConstruir() {
        typealias R = Payload.Ruedas.Rueda
        #expect(errores(.ruedas(.init(ruedas: [R(id: "r", nombre: "n", opciones: ["a", "b"], correcta: "a")]))).isEmpty)
        #expect(contiene(errores(.ruedas(.init(ruedas: [R(id: "r", nombre: "n", opciones: ["a", "b"], correcta: "c")]))), "no incluye"))
        #expect(contiene(errores(.ruedas(.init(ruedas: [R(id: "r", nombre: "n", opciones: ["a"], correcta: "a")]))), "al menos 2"))
        #expect(contiene(errores(.ruedas(.init(ruedas: [R(id: "r", nombre: "n", opciones: ["a", "a"], correcta: "a")]))), "repetidas"))
        #expect(contiene(errores(.ruedas(.init(ruedas: []))), "1–6"))

        let piezas: [ElementoTexto] = [.init(id: "p1", texto: "aguda"), .init(id: "p2", texto: "llana")]
        let ok = Payload.Construir(plantilla: "Es {h1}.", huecos: [.init(id: "h1", correcta: "p1")], piezas: piezas)
        #expect(errores(.construir(ok)).isEmpty)
        #expect(ok.huecosEnPlantilla == ["h1"])
        #expect(contiene(errores(.construir(.init(plantilla: "Es {h1}.", huecos: [.init(id: "h1", correcta: "p9")], piezas: piezas))), "pieza inexistente"))
        #expect(contiene(errores(.construir(.init(plantilla: "Es {h1} y {h2}.", huecos: [.init(id: "h1", correcta: "p1")], piezas: piezas))), "no coinciden"))
        #expect(contiene(errores(.construir(.init(plantilla: "Sin huecos", huecos: [], piezas: piezas))), "no tiene huecos"))
        #expect(Payload.Construir(plantilla: "a {x", huecos: [], piezas: []).huecosEnPlantilla.isEmpty)
    }

    @Test("Payload: respuesta numérica")
    func numerico() {
        func n(_ r: String, _ f: Payload.Numerico.Formato, irreducible: Bool? = nil, tol: Double? = 0) -> [String] {
            errores(.numerico(.init(respuesta: r, formato: f, tolerancia: tol, unidad: nil, exigeIrreducible: irreducible)))
        }
        #expect(n("573,75", .decimal).isEmpty)
        #expect(n("12", .decimal).isEmpty)
        #expect(n("-12", .entero).isEmpty)
        #expect(n("3/4", .fraccion, irreducible: true).isEmpty)
        #expect(contiene(n("573.75", .decimal), "no se puede interpretar"))
        #expect(contiene(n("abc", .entero), "no se puede interpretar"))
        #expect(contiene(n("5,5", .entero), "no tiene el formato"))
        #expect(contiene(n("6/8", .fraccion, irreducible: true), "irreducible"))
        #expect(n("6/8", .fraccion, irreducible: false).isEmpty)
        #expect(contiene(n("1", .entero, tol: -1), "tolerancia"))
    }

    @Test("Procedencia: original y dominio público (regla de los 80 años)")
    func procedencia() {
        func dp(_ anio: Int?, autor: String? = "Autor", fuente: String? = "Fuente", licencia: String = "dominio publico") -> [String] {
            validador.validar(procedencia: Procedencia(tipo: .dominioPublico, autorTexto: autor, anioMuerteAutor: anio,
                                                       fuente: fuente, licencia: licencia, notas: nil))
        }
        #expect(dp(1945).isEmpty, "2026 − 1945 = 81 > 80")
        #expect(contiene(dp(1946), "no han pasado más de 80"), "2026 − 1946 = 80, no basta")
        #expect(contiene(dp(nil), "sin anioMuerteAutor"))
        #expect(contiene(dp(1900, autor: nil), "sin autorTexto"))
        #expect(contiene(dp(1900, fuente: ""), "sin fuente"))
        #expect(contiene(dp(1900, licencia: "propia"), "debe tener licencia «dominio publico»"))
        #expect(contiene(dp(1900, licencia: "CC-BY"), "no válida"))
        let original = Procedencia(tipo: .original, autorTexto: nil, anioMuerteAutor: nil, fuente: nil, licencia: "dominio publico", notas: nil)
        #expect(contiene(validador.validar(procedencia: original), "licencia «propia»"))
        #expect(ValidadorContenido(reloj: RelojFijo(ahora: Fx.fecha(2030, 6, 1)), calendario: Fx.madrid).anioActual == 2030)
    }

    @Test("Validación: aprobado exige revisor y fecha")
    func estadoAprobado() {
        #expect(validador.validar(validacion: Fx.aprobado).isEmpty)
        #expect(validador.validar(validacion: Fx.borrador).isEmpty)
        let m = validador.validar(validacion: Validacion(estado: .aprobado, revisor: "", fecha: "ayer"))
        #expect(contiene(m, "sin revisor") && contiene(m, "sin fecha"))
    }

    @Test("Tarjetas de teoría: límite de 40 palabras en texto y regla")
    func teoria() {
        let cuarenta = Array(repeating: "palabra", count: 40).joined(separator: " ")
        let cuarentaYUna = cuarenta + " más"
        func tarjeta(_ bloques: [TarjetaTeoria.BloqueTeoria], id: String = "LEN.SIN.SUJPRED.T01", comp: String = "LEN.SIN.SUJPRED") -> [String] {
            validador.validar(tarjeta: TarjetaTeoria(id: id, competencia: comp, titulo: "T", bloques: bloques,
                                                     procedencia: Fx.original, validacion: Fx.borrador), competencias: competencias).map(\.mensaje)
        }
        #expect(tarjeta([.init(tipo: .texto, contenido: cuarenta), .init(tipo: .regla, contenido: cuarenta)]).isEmpty)
        #expect(contiene(tarjeta([.init(tipo: .texto, contenido: cuarentaYUna)]), "41 palabras"))
        #expect(contiene(tarjeta([.init(tipo: .regla, contenido: cuarentaYUna)]), "41 palabras"))
        #expect(tarjeta([.init(tipo: .ejemplo, contenido: cuarentaYUna), .init(tipo: .esquema, contenido: cuarentaYUna)]).isEmpty)
        #expect(contiene(tarjeta([]), "no tiene bloques"))
        #expect(contiene(tarjeta([.init(tipo: .ejemplo, contenido: "")]), "vacío"))
        #expect(contiene(tarjeta([.init(tipo: .texto, contenido: "a")], id: "LEN.SIN.SUJPRED.1"), "TNN"))
        #expect(contiene(tarjeta([.init(tipo: .texto, contenido: "a")], id: "LEN.SIN.OTRA.T01", comp: "LEN.SIN.OTRA"), "no existe"))
        #expect(ValidadorContenido.contarPalabras("  uno\ndos   tres ") == 3)
    }

    @Test("Simulacros")
    func simulacros() {
        typealias P = Simulacro.Pregunta
        func pregunta(_ n: Int, area: String = "LEN", comp: String = "LEN.SIN.SUJPRED", puntos: Double = 1, rubrica: String = "r") -> P {
            P(numero: n, area: area, enunciado: "e", solucionModelo: "s", puntos: puntos,
              rubrica: .init(bien: rubrica, regular: rubrica, mal: rubrica), competencias: [comp])
        }
        func sim(_ preguntas: [P], id: String = "SIM.01", duracion: Int = 90, texto: Simulacro.TextoBase? = nil) -> [String] {
            validador.validar(simulacro: Simulacro(id: id, titulo: "T", duracionMin: duracion, textoBase: texto,
                                                   preguntas: preguntas, validacion: Fx.borrador), competencias: competencias).map(\.mensaje)
        }
        #expect(sim([pregunta(1), pregunta(2, area: "MAT", comp: "MAT.NUM.FRACSUM")]).isEmpty)
        #expect(contiene(sim([pregunta(1)], id: "SIM1"), "SIM.NN"))
        #expect(contiene(sim([pregunta(1)], duracion: 0), "duración"))
        #expect(contiene(sim([]), "no tiene preguntas"))
        #expect(contiene(sim([pregunta(2), pregunta(1)]), "numerarse"))
        #expect(contiene(sim([pregunta(1, area: "HIS")]), "área"))
        #expect(contiene(sim([pregunta(1, comp: "LEN.XXX.YYY")]), "no existe"))
        #expect(contiene(sim([pregunta(1, puntos: 0)]), "puntos"))
        #expect(contiene(sim([pregunta(1, rubrica: "")]), "rúbrica incompleta"))
        let dp = Procedencia(tipo: .dominioPublico, autorTexto: "A", anioMuerteAutor: 2000, fuente: "F", licencia: "dominio publico", notas: nil)
        let m = sim([pregunta(1)], texto: .init(texto: "", autor: "A", obra: "O", procedencia: dp))
        #expect(contiene(m, "texto base vacío") && contiene(m, "texto base: el autor murió en 2000"))
    }
}
