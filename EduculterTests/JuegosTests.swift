import Foundation
import Testing
@testable import Educulter

// Tests de la Fase 05G: orden de opciones, contrato de intento, J46, J63 e integración.

private let banco: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5))!

@Suite("05G · Juegos")
struct JuegosTests {
    // MARK: §1.1 Orden de las opciones

    @Test("200 sesiones: la correcta cae en cada posición entre el 15 % y el 35 % (4 opciones), y el orden es estable en la sesión")
    func barajado() {
        let items = banco.items.compactMap { i -> (String, Payload.Eleccion)? in
            if case .eleccion(let e) = i.payload, e.opciones.count == 4 { return (i.id, e) }
            return nil
        }
        #expect(items.count >= 20)
        var posiciones = [Int](repeating: 0, count: 4)
        for sesion in UInt64(0)..<200 {
            for (id, e) in items {
                let orden = OrdenOpciones.barajar(e.opciones, sesion: sesion, item: id)
                posiciones[orden.firstIndex { $0.id == e.correcta }!] += 1
                #expect(orden.map(\.id) == OrdenOpciones.barajar(e.opciones, sesion: sesion, item: id).map(\.id))
            }
        }
        let total = Double(posiciones.reduce(0, +))
        for n in posiciones { #expect((0.15...0.35).contains(Double(n) / total), "\(posiciones)") }
    }

    // MARK: §2 Contrato de intento

    @Test("Flujo: primer intento, pista y reintento, solución; dominio solo sin ayudas y a la primera")
    func contrato() {
        var f = FlujoIntento()
        f.comprobar(correcto: true, pista: "")
        #expect(f.resultado == .dominio)

        f = FlujoIntento()
        f.comprobar(correcto: false, pista: "¿Por qué se cuenta?")
        #expect(f.fase == .reintento(pista: "¿Por qué se cuenta?") && f.ayudas == [.pista])
        f.comprobar(correcto: true, pista: "")
        #expect(f.resultado == .enProgreso)

        f = FlujoIntento()
        f.comprobar(correcto: false, pista: "p")
        f.comprobar(correcto: false, pista: "p")
        #expect(f.resultado == .fallo)

        f = FlujoIntento(ayudasIniciales: [.ejemplo])
        f.comprobar(correcto: true, pista: "")
        #expect(f.resultado == .enProgreso)

        f = FlujoIntento(autoevaluacion: true)
        f.comprobar(correcto: true, pista: "")
        #expect(f.resultado == .autoevaluacion)
        #expect(IntentoActividad.resultado(primerCorrecto: true, ayudas: [.colores], reintentoCorrecto: nil) == .enProgreso)
    }

    @Test("«En progreso» no mueve Leitner ni la escalera; el dominio sí. La variante sin ayudas vence a los 2 días")
    @MainActor
    func registroYRetencion() throws {
        let repo = RepositorioEnMemoria()
        let ahora = Fx.fecha(2026, 11, 26)
        let s = ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: ahora), calendario: Fx.madrid,
                               rng: GeneradorConSemilla(semilla: 3))
        let p = try #require(banco.plantilla(id: "MAT.GEO.AREA.G01"))
        let item = try MotorGeneradores.generar(p, semilla: 7, recursos: banco.recursos)
        func intento(_ r: IntentoActividad.ResultadoFinal, sinAyudas: Bool = false, fecha: Date = ahora) -> IntentoActividad {
            IntentoActividad(fecha: fecha, fuente: item.id, version: 1, competencia: item.competencia, destreza: item.destreza,
                             patron: .modelo, primeraRespuesta: "", primerCorrecto: r == .dominio, sinAyudas: sinAyudas, resultado: r, duracion: 10)
        }
        let acierto = Resultado(correcto: true, fraccionCorrecta: 1, errores: [])
        _ = try s.registrar(item: item, resultado: acierto, usoPista: true, combo: 1, motivo: .nuevo, actividad: intento(.enProgreso))
        #expect(try repo.estadosCompetencia()[item.competencia] == nil)
        _ = try s.registrar(item: item, resultado: acierto, usoPista: false, combo: 1, motivo: .nuevo, actividad: intento(.dominio))
        #expect(try repo.estadosCompetencia()[item.competencia] != nil)
        #expect(try repo.intentosActividad().count == 2)

        let intentos = try repo.intentosActividad()
        let hoy = DiaCivil(ahora, calendario: Fx.madrid)
        #expect(RetencionJuegos.variantesPendientes(intentos, hoy: hoy.sumando(dias: 1), calendario: Fx.madrid).isEmpty)
        #expect(RetencionJuegos.variantesPendientes(intentos, hoy: hoy.sumando(dias: 2), calendario: Fx.madrid) == ["MAT.GEO.AREA"])
        let hecha = intentos + [intento(.dominio, sinAyudas: true, fecha: Fx.fecha(2026, 11, 28))]
        #expect(RetencionJuegos.variantesPendientes(hecha, hoy: hoy.sumando(dias: 3), calendario: Fx.madrid).isEmpty)

        var rng = GeneradorConSemilla(semilla: 1)
        let v = ActividadesJuego.variante(competencia: "MAT.GEO.AREA", intentos: intentos, banco: banco, rng: &rng)
        #expect(v.count == 1 && v[0].sinAyudas && v[0].motivo == .variante && v[0].itemId != item.id)
        #expect(banco.item(id: v[0].itemId)?.competencia == "MAT.GEO.AREA")
    }

    // MARK: §4 J46

    @Test("J46: los tres pasos de una semilla comparten texto; detalle y otro dan su pista; la variante cambia de texto")
    func j46() throws {
        let pasos = ActividadesJuego.pasosJ46(competencia: "LEN.COM.TEMA", banco: banco)
        #expect(pasos.map(\.id) == ["LEN.COM.TEMA.G01", "LEN.COM.TEMA.G02", "LEN.COM.TEMA.G03"])
        let resumen = try #require(banco.recursos.resumen)
        #expect(resumen.textos.count == 5)
        for semilla in UInt64(0)..<10 {
            let items = try pasos.map { try MotorGeneradores.generar($0, semilla: semilla, recursos: banco.recursos) }
            #expect(Set(items.compactMap { $0.claveGenerada?.split(separator: "|").last }).count == 1)
            guard case .evidencia(let e) = items[0].payload else { Issue.record("paso 1"); continue }
            #expect(!e.aceptados.isEmpty && !e.detalles.isEmpty)
            #expect(Evaluador.evaluar(.evidencia(e.aceptados[0]), para: items[0]).correcto)
            let detalle = Evaluador.evaluar(.evidencia(e.detalles[0]), para: items[0])
            #expect(Evaluador.feedback(para: detalle, item: items[0]).first == GeneradorEvidenciaResumen.pistaDetalle)
            guard case .eleccion(let t) = items[1].payload else { Issue.record("paso 2"); continue }
            #expect(t.opciones.count == 3)
            guard case .recuerdo = items[2].payload else { Issue.record("paso 3"); continue }
            #expect(items[1].textoRef != nil && items[0].textoRef == nil)
        }
        // Todos los fragmentos de los datos están en su texto.
        for e in resumen.textos {
            let texto = try #require(banco.recursos.textosBase[e.texto]?.texto)
            for f in e.central + e.detalle { #expect(texto.contains(f), "\(e.texto): \(f)") }
        }
        // La variante: otro texto y solo los pasos 2–3.
        let fuente = "LEN.COM.TEMA.G01#4"
        let previo = IntentoActividad(fecha: .now, fuente: fuente, version: 1, competencia: "LEN.COM.TEMA", destreza: "",
                                      patron: .evidencia, primeraRespuesta: "", primerCorrecto: true, resultado: .dominio, duracion: 1)
        var rng = GeneradorConSemilla(semilla: 9)
        let v = ActividadesJuego.variante(competencia: "LEN.COM.TEMA", intentos: [previo], banco: banco, rng: &rng)
        #expect(v.map { MotorGeneradores.partes(de: $0.itemId)!.plantilla } == ["LEN.COM.TEMA.G02", "LEN.COM.TEMA.G03"])
        let textoDe: (String) -> Substring? = { banco.item(id: $0)?.claveGenerada?.split(separator: "|").last }
        #expect(textoDe(v[0].itemId) != textoDe("LEN.COM.TEMA.G02#4"))
        // En la sesión, un bloque con un paso de J46 pasa a ser la actividad entera.
        let bloque = [ItemRonda(itemId: "LEN.COM.TEMA.G01#4", motivo: .nuevo), ItemRonda(itemId: "LEN.COM.TEMA.0001", motivo: .nuevo),
                      ItemRonda(itemId: "LEN.COM.TEMA.G01#5", motivo: .nuevo)]
        #expect(ActividadesJuego.agrupar(bloque, competencia: "LEN.COM.TEMA", banco: banco).map(\.itemId)
                == ["LEN.COM.TEMA.G01#4", "LEN.COM.TEMA.G02#4", "LEN.COM.TEMA.G03#4"])
    }

    // MARK: §5 J63

    /// Oráculo independiente de los cortes: área de la región pintada con la fórmula del polígono
    /// (y π = 3,14 en el semicírculo).
    static func oraculo(_ f: Payload.FiguraArea) -> Double {
        f.region.reduce(0) { s, parte in
            let a: Double
            switch parte.forma {
            case .poligono(let p):
                a = abs(zip(p, p.dropFirst() + [p[0]]).reduce(0) { $0 + $1.0.x * $1.1.y - $1.1.x * $1.0.y }) / 2
            case .semicirculo(let x, let y):
                let r = hypot(x.x - y.x, x.y - y.y) / 2
                a = 3.14 * r * r / 2
            }
            return s + Double(parte.signo) * a
        }
    }

    @Test("J63: 200 semillas por nivel; área positiva = oráculo, toda descomposición suma el total, sin medidas nulas; nivel 4 con el perfil del examen")
    func j63() throws {
        for nivel in 1...6 {
            let p = try #require(banco.plantilla(id: "MAT.GEO.AREA.G0\(nivel)"))
            for semilla in UInt64(0)..<200 {
                let item = try MotorGeneradores.generar(p, semilla: semilla, recursos: banco.recursos)
                guard case .figuraArea(let f) = item.payload else { Issue.record("\(item.id)"); continue }
                let total = try #require(Racional.interpretar(f.total)?.valor)
                #expect(total.valorDouble > 0)
                #expect(abs(Self.oraculo(f) - total.valorDouble) < 1e-6, "\(item.id): \(Self.oraculo(f)) ≠ \(f.total)")
                for d in f.descomposiciones {
                    let suma = d.partes.reduce(Racional.entero(0)) { $0 + Racional.entero($1.signo) * Racional.interpretar($1.area)!.valor }
                    #expect(suma == total, "\(item.id) \(d.id)")
                    #expect(d.partes.allSatisfy { Racional.interpretar($0.area)!.valor.valorDouble > 0 }, "\(item.id) \(d.id)")
                    #expect(Set(d.cortes).isSubset(of: Set(f.cortes.map(\.id))))
                    // La respuesta con esta descomposición es correcta.
                    let r = Respuesta.RespuestaFigura(estrategia: d.estrategia, cortes: Set(d.cortes),
                                                     areas: Dictionary(uniqueKeysWithValues: d.partes.map { ($0.id, $0.area) }),
                                                     total: f.total, unidad: f.unidad)
                    #expect(Evaluador.evaluar(.figura(r), para: item).correcto, "\(item.id) \(d.id)")
                }
                #expect(f.cortes.allSatisfy { $0.a != $0.b })
                #expect(!f.descripcion.isEmpty && !f.descripcion.contains("×"))
                // Los errores típicos se reconocen.
                for (codigo, valor) in f.erroneos where valor != f.total {
                    var r = f.respuestaCorrecta
                    r.total = valor
                    #expect(Evaluador.evaluar(.figura(r), para: item).errores.contains(codigo), "\(item.id) \(codigo)")
                }
                var lineal = f.respuestaCorrecta
                lineal.unidad = String(f.unidad.dropLast())
                #expect(!Evaluador.evaluar(.figura(lineal), para: item).correcto)
                if nivel == 4 {
                    #expect(f.descomposiciones.allSatisfy { $0.partes.count == 3 } && f.unidad == "m²")
                    #expect(f.rotulos.contains { $0.texto.contains(",") })
                }
            }
        }
    }
}
