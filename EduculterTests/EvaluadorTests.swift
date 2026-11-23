import Foundation
import Testing
@testable import Educulter

@Suite("Evaluadores por mecánica")
struct EvaluadorTests {
    let banco: BancoContenido

    init() throws {
        banco = try CargadorContenido.desdeBundle().cargar(politica: .todos)
    }

    func item(_ id: String) throws -> Item {
        try #require(banco.item(id: id))
    }

    @Test("Elección y feedback de error habitual")
    func eleccion() throws {
        let i = try item("MAT.ROM.LECTURA.0001")
        #expect(Evaluador.evaluar(.eleccion("a"), para: i) == Resultado(correcto: true, fraccionCorrecta: 1, errores: []))
        let mal = Evaluador.evaluar(.eleccion("b"), para: i)
        #expect(!mal.correcto && mal.errores == ["b"] && mal.fraccionCorrecta == 0)
        #expect(Evaluador.feedback(para: mal, item: i).first?.contains("XVI") == true)
        #expect(Evaluador.feedback(para: Evaluador.evaluar(.eleccion("c"), para: i), item: i).isEmpty)
        #expect(Evaluador.feedback(para: Evaluador.evaluar(.eleccion("a"), para: i), item: i).isEmpty)
    }

    @Test("Verdadero o falso")
    func verdaderoFalso() throws {
        let i = try item("MAT.GEO.TRIANG.0001")
        #expect(Evaluador.evaluar(.verdaderoFalso(true), para: i).correcto)
        let mal = Evaluador.evaluar(.verdaderoFalso(false), para: i)
        #expect(mal.errores == ["falso"])
        #expect(Evaluador.feedback(para: mal, item: i).count == 1)
        let falsa = Payload.verdaderoFalso(.init(afirmacion: "x", esVerdadera: false))
        #expect(Evaluador.evaluar(.verdaderoFalso(true), payload: falsa).errores == ["verdadero"])
    }

    @Test("Clasificar con acierto parcial")
    func clasificar() throws {
        let i = try item("LEN.CLA.SUSTADJ.0001")
        #expect(Evaluador.evaluar(.clasificar(["f1": "SUS", "f2": "SUS", "f3": "ADJ", "f4": "ADJ"]), para: i).correcto)
        let parcial = Evaluador.evaluar(.clasificar(["f1": "SUS", "f2": "ADJ", "f3": "ADJ"]), para: i)
        #expect(!parcial.correcto)
        #expect(parcial.errores == ["f2", "f4"])
        #expect(parcial.fraccionCorrecta == 0.5)
    }

    @Test("Ordenar")
    func ordenar() throws {
        let i = try item("LEN.LIT.CRONO.0001")
        #expect(Evaluador.evaluar(.ordenar(["a2", "a4", "a1", "a3"]), para: i).correcto)
        let mal = Evaluador.evaluar(.ordenar(["a4", "a2", "a1", "a3"]), para: i)
        #expect(!mal.correcto && mal.errores == ["a2", "a4"] && mal.fraccionCorrecta == 0.5)
        let corto = Evaluador.evaluar(.ordenar(["a2"]), para: i)
        #expect(!corto.correcto && corto.fraccionCorrecta == 0.25)
        let largo = Evaluador.evaluar(.ordenar(["a2", "a4", "a1", "a3", "a9"]), para: i)
        #expect(!largo.correcto && largo.errores == [Resultado.respuestaIncompatible])
    }

    @Test("Emparejar")
    func emparejar() throws {
        let i = try item("LEN.LIT.AUTOBRA.0001")
        typealias P = Respuesta.ParRespuesta
        let bien = [P(izquierda: "i1", derecha: "d2"), P(izquierda: "i2", derecha: "d3"), P(izquierda: "i3", derecha: "d1")]
        #expect(Evaluador.evaluar(.emparejar(bien), para: i).correcto)
        let cruzado = [P(izquierda: "i1", derecha: "d2"), P(izquierda: "i2", derecha: "d1"), P(izquierda: "i3", derecha: "d3")]
        let r = Evaluador.evaluar(.emparejar(cruzado), para: i)
        #expect(!r.correcto && r.errores == ["i2", "i3"] && abs(r.fraccionCorrecta - 1.0 / 3) < 1e-9)
        let incompleto = Evaluador.evaluar(.emparejar(Array(bien.prefix(2))), para: i)
        #expect(!incompleto.correcto && incompleto.errores == ["i3"])
        let sobrante = Evaluador.evaluar(.emparejar(bien + [P(izquierda: "iX", derecha: "d1")]), para: i)
        #expect(!sobrante.correcto && sobrante.errores == [Resultado.respuestaIncompatible])
    }

    @Test("Marcar texto")
    func marcarTexto() throws {
        let i = try item("LEN.CLA.VERBO.0001")
        #expect(Evaluador.evaluar(.marcarTexto(["t2", "t5"]), para: i).correcto)
        let mal = Evaluador.evaluar(.marcarTexto(["t2", "t8", "tZ"]), para: i)
        #expect(!mal.correcto)
        #expect(Set(mal.errores) == ["t5", "t8", "tZ"])
        #expect(abs(mal.fraccionCorrecta - 0.25) < 1e-9)
        #expect(Evaluador.feedback(para: mal, item: i).count == 1)
        #expect(Evaluador.evaluar(.marcarTexto([]), para: i).fraccionCorrecta == 0)
    }

    @Test("Segmentar, incluido el anidamiento y los ids distintos")
    func segmentar() throws {
        typealias S = Respuesta.SegmentoRespuesta
        let i = try item("LEN.SIN.SUJPRED.0001")
        let bien = [S(id: "x", desde: "t1", hasta: "t2", etiqueta: "SUJ"), S(id: "y", desde: "t3", hasta: "t3", etiqueta: "PRED")]
        #expect(Evaluador.evaluar(.segmentar(bien), para: i).correcto)
        let mal = [S(id: "x", desde: "t1", hasta: "t1", etiqueta: "SUJ"), S(id: "y", desde: "t3", hasta: "t3", etiqueta: "PRED")]
        let r = Evaluador.evaluar(.segmentar(mal), para: i)
        #expect(!r.correcto && r.errores == ["s1"] && abs(r.fraccionCorrecta - 1.0 / 3) < 1e-9)
        let sobra = Evaluador.evaluar(.segmentar(bien + [S(id: "z", desde: "t2", hasta: "t2", etiqueta: "SUJ", padre: "x")]), para: i)
        #expect(!sobra.correcto && sobra.errores == [Resultado.respuestaIncompatible])

        // Anidamiento: el padre se compara por estructura, no por id.
        let payload = Payload.segmentar(.init(
            tokens: [.init(id: "t1", texto: "de"), .init(id: "t2", texto: "Ana")],
            etiquetas: [.init(id: "SPREP", nombre: "SPrep"), .init(id: "SN", nombre: "SN")],
            segmentos: [.init(id: "a", desde: "t1", hasta: "t2", etiqueta: "SPREP", padre: nil),
                        .init(id: "b", desde: "t2", hasta: "t2", etiqueta: "SN", padre: "a")]))
        let anidada = [S(id: "1", desde: "t1", hasta: "t2", etiqueta: "SPREP"), S(id: "2", desde: "t2", hasta: "t2", etiqueta: "SN", padre: "1")]
        #expect(Evaluador.evaluar(.segmentar(anidada), payload: payload).correcto)
        let plana = [S(id: "1", desde: "t1", hasta: "t2", etiqueta: "SPREP"), S(id: "2", desde: "t2", hasta: "t2", etiqueta: "SN")]
        #expect(Evaluador.evaluar(.segmentar(plana), payload: payload).errores == ["b"])
    }

    @Test("Ruedas y construir")
    func ruedasYConstruir() throws {
        let v = try item("LEN.VER.ANALISIS.0001")
        let bien = ["persona": "primera", "numero": "plural", "tiempo": "pretérito imperfecto", "modo": "indicativo"]
        #expect(Evaluador.evaluar(.ruedas(bien), para: v).correcto)
        var mal = bien
        mal["tiempo"] = "pretérito perfecto simple"
        let r = Evaluador.evaluar(.ruedas(mal), para: v)
        #expect(r.errores == ["tiempo"] && r.fraccionCorrecta == 0.75)
        #expect(Evaluador.feedback(para: r, item: v).count == 1)

        let c = try item("LEN.ORT.AGU.0009")
        #expect(Evaluador.evaluar(.construir(["h1": "p1", "h2": "p3"]), para: c).correcto)
        #expect(Evaluador.evaluar(.construir(["h1": "p2", "h2": "p3"]), para: c).errores == ["h1"])
        #expect(Evaluador.evaluar(.construir([:]), para: c).fraccionCorrecta == 0)
    }

    @Test("Numérico: fracciones, decimales, tolerancia y formato")
    func numerico() throws {
        let i = try item("MAT.OPE.FRACSUM.0001")
        #expect(Evaluador.evaluar(.numerico("3/4"), para: i).correcto)
        #expect(!Evaluador.evaluar(.numerico("6/8"), para: i).correcto, "Se exige fracción irreducible")
        #expect(!Evaluador.evaluar(.numerico("0,75"), para: i).correcto, "Se pide una fracción, no un decimal")
        let mal = Evaluador.evaluar(.numerico("2/6"), para: i)
        #expect(mal.errores == ["2/6"] && Evaluador.feedback(para: mal, item: i).count == 1)
        #expect(!Evaluador.evaluar(.numerico("tres cuartos"), para: i).correcto)

        func n(_ r: String, _ f: Payload.Numerico.Formato, tol: Double? = nil) -> Payload {
            .numerico(.init(respuesta: r, formato: f, tolerancia: tol, unidad: "€", exigeIrreducible: nil))
        }
        #expect(Evaluador.evaluar(.numerico("573,75"), payload: n("573,75", .decimal)).correcto)
        #expect(Evaluador.evaluar(.numerico("573,750"), payload: n("573,75", .decimal)).correcto)
        #expect(!Evaluador.evaluar(.numerico("573,7"), payload: n("573,75", .decimal)).correcto)
        #expect(Evaluador.evaluar(.numerico("573,7"), payload: n("573,75", .decimal, tol: 0.05)).correcto)
        #expect(!Evaluador.evaluar(.numerico("573,6"), payload: n("573,75", .decimal, tol: 0.05)).correcto)
        #expect(Evaluador.evaluar(.numerico("6/8"), payload: n("3/4", .fraccion)).correcto, "Sin exigencia, vale la equivalente")
        #expect(Evaluador.evaluar(.numerico("-12"), payload: n("-12", .entero)).correcto)
        #expect(!Evaluador.evaluar(.numerico("1"), payload: n("x", .entero)).correcto)
    }

    @Test("Respuesta de otra mecánica: incorrecta e incompatible")
    func incompatible() throws {
        let i = try item("MAT.ROM.LECTURA.0001")
        let r = Evaluador.evaluar(.verdaderoFalso(true), para: i)
        #expect(!r.correcto && r.errores == [Resultado.respuestaIncompatible])
    }
}
