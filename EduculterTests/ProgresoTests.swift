import Foundation
import SwiftData
import Testing
@testable import Educulter

/// Mismo contrato para las dos implementaciones del repositorio.
@MainActor
@Suite("Repositorio de progreso")
struct ProgresoTests {
    enum Tipo: String, CaseIterable { case memoria, swiftData }

    func repositorio(_ tipo: Tipo) throws -> any RepositorioProgreso {
        switch tipo {
        case .memoria: RepositorioEnMemoria()
        case .swiftData: RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(enMemoria: true))
        }
    }

    @Test("Intentos", arguments: Tipo.allCases)
    func intentos(_ tipo: Tipo) throws {
        let repo = try repositorio(tipo)
        let t0 = Fx.fecha(2026, 11, 20), t1 = Fx.fecha(2026, 11, 22), t2 = Fx.fecha(2026, 11, 23)
        let a = Intento(fecha: t1, itemId: "A", competenciaId: "C", peldano: 2, correcto: true, fraccionCorrecta: 1,
                        usoPista: true, confianza: 3, xp: 15, motivo: .rescate)
        let b = Intento(fecha: t0, itemId: "B", competenciaId: "C", peldano: 2, correcto: false, fraccionCorrecta: 0.5)
        let c = Intento(fecha: t2, itemId: "A", competenciaId: "C", peldano: 3, correcto: true, fraccionCorrecta: 1)
        for i in [a, b, c] { try repo.registrarIntento(i) }
        #expect(try repo.intentos(desde: nil) == [b, a, c])
        #expect(try repo.intentos(desde: t1) == [a, c])
        #expect(try repo.vistos(desde: t1) == ["A": t2])
    }

    @Test("Estado por competencia", arguments: Tipo.allCases)
    func estados(_ tipo: Tipo) throws {
        let repo = try repositorio(tipo)
        #expect(try repo.estadosCompetencia().isEmpty)
        var e = EstadoCompetencia(competenciaId: "LEN.SIN.SUJPRED", escalera: .init(peldano: 3, ventana: [true, false, true]),
                                  leitner: .init(caja: 2, proximoRepaso: Fx.dia(2026, 11, 26), ultimoRepaso: Fx.dia(2026, 11, 23)))
        try repo.guardar(e)
        try repo.guardar(EstadoCompetencia(competenciaId: "MAT.NUM.FRACSUM"))
        e.escalera.peldano = 4
        e.leitner?.ultimoRepaso = nil
        try repo.guardar(e)
        let todos = try repo.estadosCompetencia()
        #expect(todos.count == 2)
        #expect(todos["LEN.SIN.SUJPRED"] == e)
        #expect(todos["MAT.NUM.FRACSUM"] == EstadoCompetencia(competenciaId: "MAT.NUM.FRACSUM"))
    }

    @Test("Cola de Rescate conserva el orden", arguments: Tipo.allCases)
    func rescate(_ tipo: Tipo) throws {
        let repo = try repositorio(tipo)
        let f = Fx.fecha(2026, 11, 23)
        let cola = ColaRescate(entradas: [EntradaRescate(itemId: "B", competencia: "C", peldano: 2, fecha: f),
                                          EntradaRescate(itemId: "A", competencia: "C", peldano: 2, fecha: f)])
        try repo.guardar(cola)
        #expect(try repo.colaRescate() == cola)
        try repo.guardar(ColaRescate(entradas: [cola.entradas[1]]))
        #expect(try repo.colaRescate().entradas.map(\.itemId) == ["A"])
    }

    @Test("Perfil: XP, racha y métricas", arguments: Tipo.allCases)
    func perfil(_ tipo: Tipo) throws {
        let repo = try repositorio(tipo)
        #expect(try repo.perfil() == PerfilJugador())
        var p = PerfilJugador()
        p.xpTotal = 345
        p.racha = EstadoRacha(actual: 4, record: 9, protectores: 1, ultimoDiaActivo: Fx.dia(2026, 11, 23), ultimoDiaProcesado: Fx.dia(2026, 11, 22))
        p.metricas = [.rescates: 3, .rondasCompletadas: 7]
        try repo.guardar(p)
        p.xpTotal = 400
        try repo.guardar(p)
        #expect(try repo.perfil() == p)
    }

    @Test("Logros sin duplicados", arguments: Tipo.allCases)
    func logros(_ tipo: Tipo) throws {
        let repo = try repositorio(tipo)
        let l = LogroObtenido(logroId: "primera-ronda", fecha: Fx.fecha(2026, 11, 23))
        try repo.registrarLogro(l)
        try repo.registrarLogro(l)
        try repo.registrarLogro(LogroObtenido(logroId: "rescatador", fecha: Fx.fecha(2026, 11, 24)))
        #expect(try repo.logros().map(\.logroId) == ["primera-ronda", "rescatador"])
    }

    @Test("Resultado del diagnóstico", arguments: Tipo.allCases)
    func diagnostico(_ tipo: Tipo) throws {
        let repo = try repositorio(tipo)
        #expect(try repo.diagnostico() == nil)
        let d = ResultadoDiagnostico(fecha: Fx.fecha(2026, 11, 23),
                                     niveles: [NivelBloque(bloqueId: "LEN.SIN", nivel: 0.5, respondidos: 2, aciertos: 1)],
                                     plan: [EntradaPlan(bloqueId: "LEN.SIN", prioridad: 3, debilidad: 0.5, puntuacion: 1.5)])
        try repo.guardar(d)
        var otro = d
        otro.fecha = Fx.fecha(2026, 12, 1)
        try repo.guardar(otro)
        #expect(try repo.diagnostico() == otro)
    }

    @Test("Modelos compatibles con CloudKit: se crean con valores por defecto y sin CloudKit activo")
    func compatibilidadCloudKit() throws {
        let contenedor = try EsquemaProgreso.contenedor(enMemoria: true)
        #expect(contenedor.configurations.allSatisfy { $0.cloudKitContainerIdentifier == nil })
        #expect(EsquemaProgreso.modelos.count == 11)  // + EventoErrorRegistro (05E parte 2 §4), IntentoActividadRegistro (05G) y ExamenTribunalRegistro (05I)
        // Registros con duplicados (como los que podría crear una sincronización): se toma el más avanzado.
        let repo = RepositorioSwiftData(contenedor: contenedor)
        let a = EstadoCompetenciaRegistro(competenciaId: "C"); a.peldano = 2
        let b = EstadoCompetenciaRegistro(competenciaId: "C"); b.peldano = 4
        repo.contexto.insert(a); repo.contexto.insert(b)
        let c = EstadoCompetenciaRegistro(competenciaId: "C"); c.peldano = 3
        repo.contexto.insert(c)
        try repo.contexto.save()
        #expect(try repo.estadosCompetencia()["C"]?.escalera.peldano == 4)
        repo.contexto.insert(LogroRegistro(LogroObtenido(logroId: "x", fecha: .now)))
        repo.contexto.insert(LogroRegistro(LogroObtenido(logroId: "x", fecha: .now)))
        #expect(try repo.logros().count == 1)
    }
}
