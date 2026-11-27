import Foundation
import Testing
@testable import Educulter

@Suite("Esquema de teoría (D-034)")
struct EsquemaTests {
    @Test("Pares, flechas y texto")
    func filas() {
        let filas = FilaEsquema.filas(de: "Agudas: tilde en vocal, n o s\n\n  Oración → Sujeto → Predicado \nTexto libre\nNota: A → B\n: sin etiqueta\nA →")
        #expect(filas == [
            .par(etiqueta: "Agudas", valor: "tilde en vocal, n o s"),
            .flecha(["Oración", "Sujeto", "Predicado"]),
            .texto("Texto libre"),
            .par(etiqueta: "Nota", valor: "A → B"),
            .texto(": sin etiqueta"),
            .texto("A →"),
        ])
    }
}

@Suite("Soluciones y respuestas de ejemplo")
struct SolucionesTests {
    let banco: BancoContenido

    init() throws {
        banco = try CargadorContenido.desdeBundle().cargar(politica: .todos)
    }

    @Test("La respuesta correcta acierta, la de un error falla y ambas están completas", arguments: Mecanica.allCases)
    func ejemplos(_ mecanica: Mecanica) throws {
        for item in banco.items where item.mecanica == mecanica {
            let correcta = RespuestaEjemplo.correcta(item.payload)
            #expect(correcta.esCompleta(para: item.payload), "\(item.id)")
            #expect(Evaluador.evaluar(correcta, para: item).correcto, "\(item.id)")
            let error = RespuestaEjemplo.conUnError(item.payload, erroresHabituales: item.erroresHabituales)
            // El recuerdo es autoevaluación: no tiene respuesta errónea (05G).
            if mecanica != .recuerdo { #expect(!Evaluador.evaluar(error, para: item).correcto, "\(item.id)") }
            #expect(!DescripcionSolucion.texto(item.payload).isEmpty)
        }
    }

    @Test("Respuestas incompletas")
    func incompletas() throws {
        let clasificar = try #require(banco.item(id: "LEN.CLA.SUSTADJ.0001"))
        #expect(!Respuesta.clasificar(["f1": "SUS"]).esCompleta(para: clasificar.payload))
        #expect(!Respuesta.eleccion("a").esCompleta(para: clasificar.payload), "Otra mecánica")
        let numerico = try #require(banco.item(id: "MAT.OPE.FRACSUM.0001"))
        #expect(!Respuesta.numerico("3/").esCompleta(para: numerico.payload))
        #expect(Respuesta.numerico("3/4").esCompleta(para: numerico.payload))
        let emparejar = try #require(banco.item(id: "LEN.LIT.AUTOBRA.0001"))
        #expect(!Respuesta.emparejar([.init(izquierda: "i1", derecha: "d2")]).esCompleta(para: emparejar.payload))
        let eleccion = try #require(banco.item(id: "MAT.ROM.LECTURA.0001"))
        #expect(!Respuesta.eleccion("z").esCompleta(para: eleccion.payload))
    }

    @Test("Textos de solución")
    func textos() throws {
        func texto(_ id: String) throws -> String { DescripcionSolucion.texto(try #require(banco.item(id: id)).payload) }
        #expect(try texto("MAT.ROM.LECTURA.0001") == "14")
        #expect(try texto("MAT.GEO.TRIANG.0001") == "Verdadero")
        #expect(try texto("LEN.CLA.SUSTADJ.0002") == "Falso")
        #expect(try texto("LEN.CLA.SUSTADJ.0001") == "Sustantivo: gato, mesa · Adjetivo: hermoso, feliz")
        #expect(try texto("MAT.OPE.JERARQ.0001").hasPrefix("Resolver el paréntesis"))
        #expect(try texto("LEN.LIT.AUTOBRA.0001").contains("Miguel de Cervantes — Don Quijote de la Mancha"))
        #expect(try texto("LEN.ORT.AGU.0006") == "arbol, jardin, fragiles")
        #expect(try texto("LEN.SIN.COMPL.0001") == "[Vive en la casa de Ana] Predicado · [Vive] Núcleo verbal · [en la casa de Ana] CC de lugar · [de Ana] Compl. del nombre")
        #expect(try texto("LEN.VER.ANALISIS.0001").hasPrefix("Persona: primera"))
        #expect(try texto("LEN.ORT.AGU.0009") == "«Canción» lleva tilde porque es aguda y termina en -n.")
        #expect(try texto("MAT.POR.PORCENT.0002") == "17 €")
        #expect(try texto("MAT.OPE.JERARQ.0002") == "15")
    }

    @Test("Casos límite de la respuesta con un error")
    func limites() {
        let numeroCero = Payload.numerico(.init(respuesta: "0", formato: .entero, tolerancia: nil, unidad: nil, exigeIrreducible: nil))
        #expect(RespuestaEjemplo.conUnError(numeroCero) == .numerico("1"))
        let unaOpcion = Payload.ordenar(.init(fichas: [.init(id: "a", texto: "A")], ordenCorrecto: ["a"]))
        #expect(RespuestaEjemplo.conUnError(unaOpcion) == .ordenar(["a"]))
    }
}

@MainActor
@Suite("Servicio de sesión")
struct ServicioSesionTests {
    let banco: BancoContenido
    let repo = RepositorioEnMemoria()
    var reloj = RelojFijo(ahora: Fx.fecha(2026, 11, 23, 10))

    init() throws {
        banco = try CargadorContenido.desdeBundle().cargar(politica: .todos)
    }

    func servicio(_ reloj: RelojFijo? = nil) -> ServicioSesion {
        ServicioSesion(banco: banco, repositorio: repo, reloj: reloj ?? self.reloj, calendario: Fx.madrid,
                       rng: GeneradorConSemilla(semilla: 5))
    }

    @Test("Estado de Hoy: misiones del día, competencia en curso por prioridad y contenido")
    func estadoHoy() throws {
        let s = servicio()
        let e = try s.estadoHoy()
        #expect(e.misiones.count == 3)
        // 50 ítems reales de LEN.ORT + las variantes de las plantillas de prueba de LEN.ORT (Debug, 05C).
        let generadosOrt = banco.items.dropFirst(banco.numeroEstaticos).filter { $0.competencia.hasPrefix("LEN.ORT.") && $0.peldano <= 4 }.count
        #expect(e.hayContenido && e.itemsOrtografia == 50 + generadosOrt, "Lote 01 y piloto 05B de LEN.ORT")
        // Plan de D-103 (sin diagnóstico): la competencia con contenido de más preguntas oficiales.
        let primera = PlanEstudio(banco: banco).ordenadas().first { banco.tieneItems(competencia: $0, peldanoMaximo: 4) }
        #expect(primera == "LEN.LIT.HIST")
        #expect(e.competenciaEnCurso?.id == primera, "Primera del plan")
        #expect(e.nivel == 1 && e.xpTotal == 0 && e.racha.actual == 0)
        // Las misiones no cambian el mismo día.
        #expect(try s.estadoHoy().misiones == e.misiones)
        #expect(try repo.perfil().competenciaEnCurso == primera)
    }

    @Test("Si la competencia en curso se domina, pasa a la siguiente")
    func siguienteCompetencia() throws {
        let s = servicio()
        _ = try s.competenciaEnCurso()
        let plan = PlanEstudio(banco: banco).ordenadas().filter { banco.tieneItems(competencia: $0, peldanoMaximo: 4) }
        #expect(try s.competenciaEnCurso() == plan[0])
        try repo.guardar(EstadoCompetencia(competenciaId: plan[0], escalera: .init(peldano: 5)))
        #expect(try s.competenciaEnCurso() == plan[1])
    }

    @Test("Registrar respuestas: XP, escalera, Rescate, métricas, misiones e intentos")
    func registrar() throws {
        let s = servicio()
        let item = try #require(banco.item(id: "LEN.SIN.SUJPRED.0001"))
        let mal = Evaluador.evaluar(RespuestaEjemplo.conUnError(item.payload), para: item)
        let e1 = try s.registrar(item: item, resultado: mal, usoPista: false, combo: 0, motivo: .enCurso)
        #expect(e1.xp == 0 && !e1.rescatado)
        #expect(try repo.colaRescate().cantidad == 1)

        // Acierto con variante (mismo peldaño): rescata, da bonus y cuenta como sintaxis perfecta.
        let variante = try #require(banco.item(id: "LEN.SIN.SUJPRED.0002"))
        let bien = Evaluador.evaluar(RespuestaEjemplo.correcta(variante.payload), para: variante)
        let e2 = try s.registrar(item: variante, resultado: bien, usoPista: false, combo: 1, motivo: .rescate, confianza: 2)
        #expect(e2.rescatado && e2.xp == 20)
        #expect(try repo.colaRescate().estaVacia)
        let perfil = try repo.perfil()
        #expect(perfil.xpTotal == 20)
        #expect(perfil.metricas[.rescates] == 1 && perfil.metricas[.aciertosTotales] == 1 && perfil.metricas[.sintaxisPerfectas] == 1)
        #expect(e2.logrosNuevos.map(\.id) == ["sintaxis-perfecta"])
        let intentos = try repo.intentos(desde: nil)
        #expect(intentos.count == 2 && intentos[1].confianza == 2 && intentos[1].motivo == .rescate)

        // Con pista: 0 XP.
        let e3 = try s.registrar(item: variante, resultado: bien, usoPista: true, combo: 2, motivo: .enCurso)
        #expect(e3.xp == 0)
    }

    @Test("Subida de peldaño y dominio")
    func subida() throws {
        let s = servicio()
        try repo.guardar(EstadoCompetencia(competenciaId: "LEN.ORT.AGU", escalera: .init(peldano: 4, ventana: [true, true, true])))
        let item = try #require(banco.item(id: "LEN.ORT.AGU.0009"))
        let e = try s.registrar(item: item, resultado: Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item),
                                usoPista: false, combo: 1, motivo: .enCurso)
        #expect(e.subioPeldano && e.peldanoNuevo == 5 && e.acabaDeDominarse && e.xp == 25)
        #expect(try repo.perfil().metricas[.competenciasDominadas] == 1)
    }

    @Test("Completar ronda: racha, misiones de área y logro de primera ronda")
    func completar() throws {
        let s = servicio()
        let ronda = try s.prepararRonda(.recomendada)
        #expect((6...8).contains(ronda.items.count))
        #expect(ronda.competenciaEnCurso == "LEN.LIT.HIST", "Primera del plan (D-103)")
        let e = try s.completarRonda(ronda)
        #expect(e.racha.actual == 1 && e.cambiosRacha.incrementada)
        #expect(e.logrosNuevos.map(\.id) == ["primera-ronda"])
        // Al día siguiente, la racha sube.
        let manana = servicio(RelojFijo(ahora: Fx.fecha(2026, 11, 24, 9)))
        let e2 = try manana.completarRonda(try manana.prepararRonda(.ortografiaExpres))
        #expect(e2.racha.actual == 2)
        #expect(try repo.perfil().metricas[.rondasCompletadas] == 2)
    }

    @Test("Rondas de Rescate, Ortografía exprés e ítems concretos")
    func tiposDeRonda() throws {
        let s = servicio()
        #expect(try s.prepararRonda(.rescate).items.isEmpty)
        for id in ["LEN.SIN.SUJPRED.0001", "MAT.ROM.LECTURA.0001"] {
            let item = try #require(banco.item(id: id))
            try s.registrar(item: item, resultado: Resultado(correcto: false, fraccionCorrecta: 0, errores: []), usoPista: false, combo: 0, motivo: nil)
        }
        let rescate = try s.prepararRonda(.rescate)
        #expect(rescate.items.count == 2 && rescate.items.allSatisfy { $0.motivo == .rescate })
        // Se rescata con una variante de la misma competencia y peldaño (desde la 05E, generada).
        let variante = try #require(rescate.items.first.flatMap { banco.item(id: $0.itemId) })
        let fallado = try #require(banco.item(id: "LEN.SIN.SUJPRED.0001"))
        #expect(variante.id != fallado.id && variante.competencia == fallado.competencia && variante.peldano == fallado.peldano, "Se rescata con la variante")
        let orto = try s.prepararRonda(.ortografiaExpres)
        #expect(orto.items.count == 5 && orto.items.allSatisfy { $0.itemId.hasPrefix("LEN.ORT.") })
        let fija = try s.prepararRonda(.items(["MAT.ROM.LECTURA.0001", "NO.EXISTE"]))
        #expect(fija.items.map(\.itemId) == ["MAT.ROM.LECTURA.0001"])
        #expect(try s.completarRonda(rescate).racha.actual == 1)
        #expect(s.dominio(area: "XXX", estados: [:]) == 0)
    }
}
