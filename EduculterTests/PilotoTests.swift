import Foundation
import Testing
@testable import Educulter

// MARK: - Mecánicas nuevas (Fase 05B)

@Suite("Colocar la tilde")
struct ColocarTildeTests {
    let banco = try! CargadorContenido.desdeBundle().cargar(politica: .todos)

    func item(_ id: String) throws -> Item { try #require(banco.item(id: id)) }

    @Test("Evaluación: acierto, sinTilde, conTilde y posición")
    func evaluar() throws {
        let cancion = try item("LEN.ORT.AGU.0010") // índice 5
        #expect(Evaluador.evaluar(.colocarTilde(5), para: cancion).correcto)
        #expect(Evaluador.evaluar(.colocarTilde(nil), para: cancion).errores == ["sinTilde"])
        #expect(Evaluador.evaluar(.colocarTilde(1), para: cancion).errores == ["posicion"])
        #expect(Evaluador.feedback(para: Evaluador.evaluar(.colocarTilde(nil), para: cancion), item: cancion) == ["Es aguda y termina en -n: sí lleva tilde."])
        let examen = try item("LEN.ORT.AGU.0012") // sin tilde
        #expect(Evaluador.evaluar(.colocarTilde(nil), para: examen).correcto)
        #expect(Evaluador.evaluar(.colocarTilde(2), para: examen).errores == ["conTilde"])
        #expect(Evaluador.evaluar(.eleccion("x"), para: examen).errores == [Resultado.respuestaIncompatible])
    }

    @Test("Solución escrita, respuesta completa y ejemplos")
    func solucion() throws {
        let cancion = try item("LEN.ORT.AGU.0010")
        #expect(DescripcionSolucion.texto(cancion.payload) == "«canción»")
        #expect(DescripcionSolucion.texto(try item("LEN.ORT.AGU.0012").payload) == "«examen», sin tilde")
        #expect(Respuesta.colocarTilde(nil).esCompleta(para: cancion.payload))
        #expect(RespuestaEjemplo.conUnError(cancion.payload) == .colocarTilde(nil))
        #expect(RespuestaEjemplo.conUnError(try item("LEN.ORT.AGU.0012").payload) == .colocarTilde(0))
        if case .colocarTilde(let p) = cancion.payload {
            #expect(p.escrita(conTildeEn: 99) == "cancion")
            #expect(p.escrita(conTildeEn: 2) == "cancion", "Una consonante no admite tilde")
        }
    }

    @Test("Validador: minúsculas, sin tildes, solo letras e índice en una vocal")
    func validador() {
        let v = ValidadorContenido(anioActual: 2026)
        #expect(v.validar(payload: .colocarTilde(.init(palabra: "cancion", indiceTilde: 5))).isEmpty)
        #expect(v.validar(payload: .colocarTilde(.init(palabra: "reloj", indiceTilde: nil))).isEmpty)
        #expect(!v.validar(payload: .colocarTilde(.init(palabra: "Cancion", indiceTilde: 5))).isEmpty)
        #expect(!v.validar(payload: .colocarTilde(.init(palabra: "canción", indiceTilde: 5))).isEmpty)
        #expect(!v.validar(payload: .colocarTilde(.init(palabra: "can cion", indiceTilde: nil))).isEmpty)
        #expect(!v.validar(payload: .colocarTilde(.init(palabra: "", indiceTilde: nil))).isEmpty)
        #expect(v.validar(payload: .colocarTilde(.init(palabra: "cancion", indiceTilde: 9))).contains { $0.contains("fuera") })
        #expect(v.validar(payload: .colocarTilde(.init(palabra: "cancion", indiceTilde: 2))).contains { $0.contains("vocal") })
    }

    @Test("Validador: errores habituales con claves válidas")
    func erroresHabituales() throws {
        var i = try item("LEN.ORT.AGU.0010")
        i.erroresHabituales = [ErrorHabitual(respuesta: "otra", feedback: "x")]
        let errores = ValidadorContenido(anioActual: 2026).validar(item: i, competencias: ["LEN.ORT.AGU"])
        #expect(errores.contains { $0.mensaje.contains("sinTilde") })
    }
}

@Suite("Fracciones con barras")
struct FraccionBarrasTests {
    typealias F = Payload.FraccionBarras
    let banco = try! CargadorContenido.desdeBundle().cargar(politica: .todos)

    func evaluar(_ p: F, _ partes: Int, _ coloreadas: Int) -> Resultado {
        Evaluador.evaluar(.fraccionBarras(partes: partes, coloreadas: Set(0..<coloreadas)), payload: .fraccionBarras(p))
    }

    @Test("Colorear sin equivalentes: partes fijas y numerador exacto")
    func colorear() {
        let p = F(modo: .colorear, partes: 4, objetivo: "3/4", aceptarEquivalentes: false)
        #expect(evaluar(p, 4, 3).correcto)
        #expect(evaluar(p, 4, 2).errores == ["coloreadas"])
        #expect(evaluar(p, 8, 6).errores.contains("partes"), "En colorear no se puede cambiar la división")
        // La posición de las celdas no importa.
        #expect(Evaluador.evaluar(.fraccionBarras(partes: 4, coloreadas: [0, 2, 3]), payload: .fraccionBarras(p)).correcto)
        // Celdas fuera de la barra no cuentan.
        #expect(!Evaluador.evaluar(.fraccionBarras(partes: 4, coloreadas: [0, 1, 9]), payload: .fraccionBarras(p)).correcto)
    }

    @Test("Equivalentes: se compara el valor racional")
    func equivalentes() {
        let mitad = F(modo: .colorear, partes: 6, objetivo: "1/2", aceptarEquivalentes: true)
        #expect(evaluar(mitad, 6, 3).correcto)
        #expect(!evaluar(mitad, 6, 2).correcto)
        let tercio = F(modo: .dividirYColorear, partes: nil, objetivo: "1/3", aceptarEquivalentes: true, particionesPermitidas: [6, 9])
        #expect(evaluar(tercio, 6, 2).correcto)
        #expect(evaluar(tercio, 9, 3).correcto)
        #expect(evaluar(tercio, 3, 1).errores == ["partes"], "3 partes no está permitido")
        #expect(evaluar(tercio, 6, 3).errores == ["coloreadas"])
        let libre = F(modo: .dividirYColorear, partes: nil, objetivo: "2/3", aceptarEquivalentes: true)
        #expect(evaluar(libre, 6, 4).correcto)
    }

    @Test("Dividir sin equivalentes: partes = denominador")
    func dividir() {
        let p = F(modo: .dividirYColorear, partes: nil, objetivo: "2/3", aceptarEquivalentes: false)
        #expect(evaluar(p, 3, 2).correcto)
        #expect(evaluar(p, 6, 4).errores == ["partes"])
        #expect(evaluar(p, 3, 1).errores == ["coloreadas"])
        #expect(evaluar(p, 0, 0).errores == [Resultado.respuestaIncompatible])
    }

    @Test("Solución, texto y respuesta completa")
    func solucion() {
        let doce = F(modo: .colorear, partes: 12, objetivo: "3/4", aceptarEquivalentes: true)
        #expect(doce.solucion.partes == 12 && doce.solucion.coloreadas == 9)
        #expect(DescripcionSolucion.texto(.fraccionBarras(doce)) == "9/12 = 3/4")
        #expect(DescripcionSolucion.texto(.fraccionBarras(F(modo: .colorear, partes: 4, objetivo: "3/4", aceptarEquivalentes: false))) == "3/4")
        let tercio = F(modo: .dividirYColorear, partes: nil, objetivo: "1/3", aceptarEquivalentes: true, particionesPermitidas: [6, 9])
        #expect(tercio.solucion.partes == 6 && tercio.solucion.coloreadas == 2)
        #expect(!Respuesta.fraccionBarras(partes: 4, coloreadas: []).esCompleta(para: .fraccionBarras(doce)))
        #expect(!Respuesta.fraccionBarras(partes: 13, coloreadas: [1]).esCompleta(para: .fraccionBarras(doce)))
        #expect(Respuesta.fraccionBarras(partes: 4, coloreadas: [1]).esCompleta(para: .fraccionBarras(doce)))
        #expect(RespuestaEjemplo.conUnError(.fraccionBarras(F(modo: .colorear, partes: 4, objetivo: "1/4", aceptarEquivalentes: false)))
                == .fraccionBarras(partes: 4, coloreadas: [0, 1]))
        #expect(F(modo: .colorear, partes: 4, objetivo: "x", aceptarEquivalentes: false).solucion.coloreadas == 0)
    }

    @Test("Validador de fraccionBarras")
    func validador() {
        let v = ValidadorContenido(anioActual: 2026)
        func errores(_ p: F) -> [String] { v.validar(payload: .fraccionBarras(p)) }
        #expect(errores(F(modo: .colorear, partes: 4, objetivo: "3/4", aceptarEquivalentes: false)).isEmpty)
        #expect(errores(F(modo: .dividirYColorear, partes: nil, objetivo: "1/3", aceptarEquivalentes: true, particionesPermitidas: [6, 9])).isEmpty)
        #expect(errores(F(modo: .colorear, partes: 4, objetivo: "tres cuartos", aceptarEquivalentes: false)).contains { $0.contains("n/d") })
        #expect(errores(F(modo: .colorear, partes: 4, objetivo: "5/4", aceptarEquivalentes: false)).contains { $0.contains("propia") })
        #expect(errores(F(modo: .colorear, partes: nil, objetivo: "1/2", aceptarEquivalentes: true)).contains { $0.contains("obligatorio") })
        #expect(errores(F(modo: .colorear, partes: 5, objetivo: "1/2", aceptarEquivalentes: true)).contains { $0.contains("exactamente") })
        #expect(errores(F(modo: .colorear, partes: 8, objetivo: "1/2", aceptarEquivalentes: false)).contains { $0.contains("denominador") })
        #expect(errores(F(modo: .colorear, partes: 6, objetivo: "1/2", aceptarEquivalentes: true, particionesPermitidas: [6])).contains { $0.contains("solo es válido") })
        #expect(errores(F(modo: .colorear, partes: 20, objetivo: "1/2", aceptarEquivalentes: true)).contains { $0.contains("entre 2 y 12") })
        #expect(errores(F(modo: .dividirYColorear, partes: 3, objetivo: "1/3", aceptarEquivalentes: false)).contains { $0.contains("null") })
        #expect(errores(F(modo: .dividirYColorear, partes: nil, objetivo: "1/3", aceptarEquivalentes: true, particionesPermitidas: [4])).contains { $0.contains("partición 4") })
        #expect(errores(F(modo: .dividirYColorear, partes: nil, objetivo: "1/3", aceptarEquivalentes: true, particionesPermitidas: [])).contains { $0.contains("vacío") })
        #expect(errores(F(modo: .dividirYColorear, partes: nil, objetivo: "1/3", aceptarEquivalentes: false, particionesPermitidas: [6])).contains { $0.contains("única") })
    }

    @Test("Codificación JSON con nulos explícitos")
    func codificacion() throws {
        let item = try #require(banco.item(id: "MAT.NUM.FRAREP.0003"))
        let datos = try JSONEncoder().encode(item)
        #expect(try JSONDecoder().decode(Item.self, from: datos) == item)
        #expect(String(decoding: datos, as: UTF8.self).contains("\"partes\":null"))
    }
}

@Suite("Silabeo y sílaba tónica")
struct SilabeoTests {
    func separar(_ p: String) -> String {
        let l = Array(p)
        return Silabeo.silabas(p).map { String(l[$0]) }.joined(separator: "-")
    }

    @Test("División silábica", arguments: [
        ("canción", "can-ción"), ("árbol", "ár-bol"), ("examen", "e-xa-men"), ("música", "mú-si-ca"),
        ("café", "ca-fé"), ("reloj", "re-loj"), ("lápiz", "lá-piz"), ("teléfono", "te-lé-fo-no"),
        ("robots", "ro-bots"), ("jóvenes", "jó-ve-nes"), ("joven", "jo-ven"), ("fácil", "fá-cil"),
        ("país", "pa-ís"), ("poeta", "po-e-ta"), ("ciudad", "ciu-dad"), ("aire", "ai-re"), ("hombre", "hom-bre"),
        ("instante", "ins-tan-te"), ("queso", "que-so"), ("guerra", "gue-rra"), ("sol", "sol"), ("pfff", "pfff"),
    ])
    func silabas(_ caso: (String, String)) {
        #expect(separar(caso.0) == caso.1)
    }

    @Test("Sílaba tónica con tilde y por las reglas generales")
    func tonica() {
        #expect(Silabeo.silabaTonica("canción", indiceTilde: 5) == 1)
        #expect(Silabeo.silabaTonica("examen", indiceTilde: nil) == 1)
        #expect(Silabeo.silabaTonica("reloj", indiceTilde: nil) == 1)
        #expect(Silabeo.silabaTonica("robots", indiceTilde: nil) == 1)
        #expect(Silabeo.silabaTonica("joven", indiceTilde: nil) == 0)
        #expect(Silabeo.silabaTonica("casas", indiceTilde: nil) == 0)
        #expect(Silabeo.silabaTonica("sol", indiceTilde: nil) == 0)
        #expect(Silabeo.silabas("").isEmpty)
    }
}

// MARK: - Personajes y avatar

@Suite("Personajes")
struct PersonajesTests {
    @Test("Seis estados y tres personajes (las reglas de la v3 están en PersonajesV3Tests)")
    func estados() {
        #expect(Set(EstadoPersonaje.allCases.map(\.rawValue)) == ["neutro", "alegre", "pensando", "animo", "guino", "descanso"])
        #expect(Companero.allCases.map(\.nombre) == ["Tilde", "Cuarto", "Mimo"])
    }

    @Test("Compañero por área")
    func companeros() {
        #expect(Companero.de(area: "LEN") == .tilde && Companero.de(area: "MAT") == .cuarto)
        #expect(Companero.tilde.nombre == "Tilde" && Companero.cuarto.nombre == "Cuarto")
    }

    @Test("Racha en riesgo: menos de 4 h para medianoche y sin ronda hoy")
    func rachaEnRiesgo() {
        let hoy = DiaCivil(anio: 2026, mes: 11, dia: 23)
        let ayer = DiaCivil(anio: 2026, mes: 11, dia: 22)
        let conRacha = EstadoRacha(actual: 3, record: 3, ultimoDiaActivo: ayer)
        #expect(ReglasPersonaje.rachaEnRiesgo(conRacha, ahora: Fx.fecha(2026, 11, 23, 21), calendario: Fx.madrid))
        #expect(!ReglasPersonaje.rachaEnRiesgo(conRacha, ahora: Fx.fecha(2026, 11, 23, 19), calendario: Fx.madrid))
        #expect(!ReglasPersonaje.rachaEnRiesgo(EstadoRacha(actual: 3, ultimoDiaActivo: hoy), ahora: Fx.fecha(2026, 11, 23, 22), calendario: Fx.madrid))
        #expect(!ReglasPersonaje.rachaEnRiesgo(EstadoRacha(), ahora: Fx.fecha(2026, 11, 23, 22), calendario: Fx.madrid))
        #expect(ReglasPersonaje.horasHastaMedianoche(ahora: Fx.fecha(2026, 11, 23, 21), calendario: Fx.madrid) == 3)
    }
}

@Suite("Avatares")
struct AvatarTests {
    @Test("6 avatares del propietario, distintos (05C sustituye a los 12 geométricos)")
    func catalogo() {
        let todos = Avatar.todos
        #expect(todos.count == 6 && Set(todos.map(\.id)) == Set(0..<6))
        #expect(Set(todos.map(\.nombre)).count == 6 && Set(todos.map(\.recurso)).count == 6)
        #expect(Avatar.con(id: 2)?.nombre == "cinta deportiva")
        #expect(Avatar.con(id: 12) == nil && Avatar.con(id: nil) == nil)
    }

    @MainActor
    @Test("El avatar se guarda en el perfil y sobrevive a reabrir el almacén en disco")
    func persistido() throws {
        let banco = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        let url = URL.temporaryDirectory.appending(path: "avatar-\(UUID().uuidString).store")
        defer { for s in ["", "-shm", "-wal"] { try? FileManager.default.removeItem(at: URL(filePath: url.path(percentEncoded: false) + s)) } }
        do {
            let servicio = ServicioSesion(banco: banco, repositorio: RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(url: url)))
            #expect(try servicio.estadoHoy().avatar == nil)
            try servicio.elegirAvatar(4)
            try servicio.elegirAvatar(7) // ids de 05B (6–11): ya no se pueden elegir
            try servicio.elegirAvatar(99) // fuera de rango: se ignora
        }
        let reabierto = ServicioSesion(banco: banco, repositorio: RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(url: url)))
        #expect(try reabierto.estadoHoy().avatar == 4)
        #expect(try reabierto.resumenProgreso() == "rescate:0;xp:0;avatar:4")
    }
}

// MARK: - Piloto: Hoy, rondas por área y misión alcanzable

@MainActor
@Suite("Piloto 05B")
struct PilotoTests {
    let banco = try! CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
    let repo = RepositorioEnMemoria()

    func servicio(_ dia: Int = 23, hora: Int = 10) -> ServicioSesion {
        ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, dia, hora)),
                       calendario: Fx.madrid, rng: GeneradorConSemilla(semilla: 5))
    }

    /// Primera competencia de Matemáticas con contenido aprobado, por prioridad de bloque y orden
    /// del catálogo hasta la 05E; desde la 05E parte 2, la primera del plan (D-103): MAT.NUM.ORDEN.
    static let primeraMAT = "MAT.NUM.ORDEN"

    @Test("Hoy con el contenido de Release: propuestas de Lengua y Matemáticas con su mecánica")
    func propuestas() throws {
        let e = try servicio().estadoHoy()
        #expect(e.propuestas.map(\.area) == ["LEN", "MAT"])
        // Plan de D-103: la competencia de Lengua con más preguntas oficiales (Historia de la literatura).
        #expect(e.propuestas.first?.competencia.id == "LEN.LIT.HIST")
        #expect(e.propuestas.last?.competencia.id == Self.primeraMAT)
        // La mecánica propuesta es la más frecuente entre los candidatos de la competencia.
        #expect(e.propuestas.last?.mecanica == .ordenar)
        #expect(!e.rachaEnRiesgo && e.horasHastaMedianoche == 14)
    }

    @Test("Ronda de Matemáticas: la competencia en curso del área, con el orden del catálogo")
    func rondaMatematicas() throws {
        let s = servicio()
        let ronda = try s.prepararRonda(.area("MAT"))
        #expect(ronda.competenciaEnCurso == Self.primeraMAT)
        let items = ronda.items.compactMap { banco.item(id: $0.itemId) }
        #expect(items.count == ronda.items.count && !items.isEmpty)
        // El motor puede intercalar repasos de otras competencias, pero la mayoría son de la competencia en curso.
        #expect(items.filter { $0.competencia == Self.primeraMAT }.count * 2 > items.count)
        #expect(try s.competenciaEnCurso(area: "LEN") == "LEN.LIT.HIST")
    }

    @Test("Practicar MAT.NUM.FRAREP (Camino) con el contenido de Release: ronda con fraccionBarras")
    func practicarFracciones() throws {
        let s = servicio()
        let ronda = try s.prepararRonda(.competencia("MAT.NUM.FRAREP"))
        let items = ronda.items.compactMap { banco.item(id: $0.itemId) }
        #expect(items.contains { $0.mecanica == .fraccionBarras })
        #expect(!items.isEmpty && items.allSatisfy { $0.competencia == "MAT.NUM.FRAREP" }, "\(items.map(\.competencia))")
    }

    @Test("La misión de área del día se puede cumplir con el contenido del piloto", arguments: 23...28)
    func misionAlcanzable(dia: Int) throws {
        let s = servicio(dia)
        let misiones = try s.estadoHoy().misiones
        let deArea = try #require(misiones.first { $0.tipo == .rondaLengua || $0.tipo == .rondaMatematicas })
        let area = deArea.tipo == .rondaMatematicas ? "MAT" : "LEN"
        let ronda = try s.prepararRonda(.area(area))
        #expect(!ronda.items.isEmpty)
        for r in ronda.items {
            let item = try #require(banco.item(id: r.itemId))
            try s.registrar(item: item, resultado: Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item),
                            usoPista: false, combo: 1, motivo: r.motivo)
        }
        let efecto = try s.completarRonda(ronda)
        #expect(efecto.misionesCompletadas.contains { $0.id == deArea.id })
    }

    @Test("Racha en riesgo en el estado de Hoy")
    func avisoRacha() throws {
        // Ronda el día 22 y, el 23 a las 21:00, sin ronda: en riesgo.
        let ayer = servicio(22)
        _ = try ayer.completarRonda(try ayer.prepararRonda(.area("LEN")))
        #expect(try servicio(23, hora: 21).estadoHoy().rachaEnRiesgo)
        #expect(try !servicio(23, hora: 12).estadoHoy().rachaEnRiesgo)
    }
}
