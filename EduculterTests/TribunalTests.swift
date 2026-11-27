import Foundation
import Testing
@testable import Educulter

// Tests de la Fase 05I: datos del Tribunal, plano y simulacro, corrección, penalización,
// cuenta atrás, reanudación e informe.

private let banco: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5))!

@Suite("05I · Tribunal")
struct TribunalTests {
    @Test("Datos: 7 convocatorias, 139 preguntas, la anulada de 2022 L7, 4 figuras sin imagen y 2 textos protegidos")
    func datos() throws {
        let t = banco.tribunal
        #expect(t.examenes.count == 7 && t.examenes.flatMap(\.preguntas).count == 139)
        let anuladas = t.examenes.flatMap { e in e.preguntas.filter(\.esAnulada).map { "\(e.id)·\($0.codigo)" } }
        #expect(anuladas == ["OF.2022.O·L7"])
        let figuras = t.examenes.flatMap { e in e.preguntas.filter { $0.figura != nil }.map { "\(e.id)·\($0.codigo)" } }.sorted()
        #expect(figuras == ["OF.2022.O·M10", "OF.2022.O·M5", "OF.2024.O·M7", "OF.2026.O·M7"])
        #expect(t.examenes.filter(\.textoBase.protegido).map(\.id).sorted() == ["OF.2019.A", "OF.2019.O"])
        #expect(t.examenes.allSatisfy { $0.pesos == nil }, "Ninguna convocatoria documenta pesos")
        #expect(t.reglas.palabraIncorrecta == 0.5 && t.reglas.tilde == 0.25 && t.reglas.limite == nil)
    }

    @Test("Plano: 10 y 10 preguntas, como mucho 2 por competencia, 90 minutos")
    func plano() {
        let p = PlanoExamen.calcular(banco.tribunal)
        #expect(p.preguntasPorArea == ["LEN": 10, "MAT": 10] && p.duracionMin == 90)
        for area in ["LEN", "MAT"] { #expect(p.entradas(area: area).reduce(0) { $0 + $1.preguntas } == 10) }
        #expect(p.entradas.allSatisfy { $0.preguntas <= PlanoExamen.maximoPorCompetencia })
    }

    @Test("Simulacro: 200 semillas; 20 preguntas, fiel al plano (±1), sin borradores ni 3 de una competencia, reproducible")
    func simulacro() throws {
        let plano = PlanoExamen.calcular(banco.tribunal)
        let g = GeneradorSimulacro(banco: banco)
        let conContenido = Set(plano.entradas.map(\.competencia).filter { !g.candidatos($0).isEmpty })
        for semilla in UInt64(0)..<200 {
            let s = g.generar(semilla: semilla, plano: plano)
            #expect(s.preguntas.count == 20, "semilla \(semilla)")
            let items = s.preguntas.compactMap { p -> Item? in if case .item(let id, _) = p { banco.item(id: id) } else { nil } }
            #expect(items.count == 20 && items.allSatisfy { $0.validacion.estado == .aprobado && (4...5).contains($0.dificultad) })
            #expect(s.preguntas.filter { $0.area == "LEN" }.count == 10)
            for e in plano.entradas where conContenido.contains(e.competencia) {
                #expect(abs((s.porCompetencia[e.competencia] ?? 0) - e.preguntas) <= 1, "\(semilla): \(e.competencia)")
            }
            #expect(s.porCompetencia.values.allSatisfy { $0 <= 2 })
            #expect(Set(s.noIncluye) == Set(plano.entradas.filter { $0.preguntas > 0 && !conContenido.contains($0.competencia) }.map(\.competencia)))
            if semilla % 50 == 0 { #expect(g.generar(semilla: semilla, plano: plano) == s, "Reproducible") }
        }
    }

    @Test("Corrección: valor y unidad, fracciones equivalentes salvo irreducible, anulada excluida y reparto igual sin pesos")
    func correccion() throws {
        // Fracciones: equivalentes aceptadas salvo que se pida irreducible.
        let libre = Fx.item("MAT.NUM.FRAOP.9001", payload: .numerico(.init(respuesta: "1/2", formato: .fraccion, tolerancia: nil, unidad: nil, exigeIrreducible: false)))
        let irreducible = Fx.item("MAT.NUM.FRAOP.9002", payload: .numerico(.init(respuesta: "1/2", formato: .fraccion, tolerancia: nil, unidad: nil, exigeIrreducible: true)))
        #expect(Evaluador.evaluar(.numerico("2/4"), para: libre).correcto && !Evaluador.evaluar(.numerico("2/4"), para: irreducible).correcto)
        #expect(Evaluador.evaluar(.numerico("0,5"), para: libre).correcto, "Coma decimal")
        // Valor y unidad por separado: el valor bien con otra unidad no vale.
        let figura = try MotorGeneradores.generar(try #require(banco.plantilla(id: "MAT.GEO.AREA.G01")), semilla: 3, recursos: banco.recursos)
        guard case .figuraArea(let f) = figura.payload else { Issue.record("payload"); return }
        var r = f.respuestaCorrecta
        #expect(Evaluador.evaluar(.figura(r), para: figura).correcto)
        r.unidad = "m²"
        #expect(!Evaluador.evaluar(.figura(r), para: figura).correcto)

        // 2022: la L7 anulada no puntúa y los pesos se reparten por igual (9 de Lengua, 10 de Matemáticas).
        var s = SesionExamen(modo: .oficial("OF.2022.O"), preguntas: banco.tribunal.examen("OF.2022.O")!.preguntas.map { .oficial(examen: "OF.2022.O", numero: $0.numero) },
                             duracionMin: 90, inicio: Fx.fecha(2026, 11, 27))
        for i in s.preguntas.indices {
            s.respuestas[i] = .init(enPapel: true)
            s.autoevaluaciones[i] = .init(nivel: .bien)
        }
        let res = CorrectorExamen.corregir(s, banco: banco, fecha: Fx.fecha(2026, 11, 27))
        let anulada = try #require(res.preguntas.first { $0.puntuacion == nil })
        #expect(anulada.area == "LEN" && anulada.peso == 0)
        #expect(!res.ponderacionDocumentada && CorrectorExamen.sinPonderacion == "Ponderación no documentada: reparto igual")
        #expect(res.preguntas.filter { $0.area == "LEN" && $0.puntuacion != nil }.allSatisfy { abs($0.peso - 1.0 / 9) < 1e-9 })
        #expect(res.preguntas.filter { $0.area == "MAT" }.allSatisfy { abs($0.peso - 0.1) < 1e-9 })
        #expect(abs(res.nota - 10) < 1e-9 && res.apto && res.etiquetaPenalizacion == "orientativa (bases de 2026)")
    }

    @Test("Penalización: −0,5 por palabra y −0,25 por tilde, sin límite; el mismo error en la misma palabra cuenta una vez")
    func penalizacion() {
        let errores = [ErrorOrtografico(palabra: "haber", tilde: false), ErrorOrtografico(palabra: "Haber", tilde: false),
                       ErrorOrtografico(palabra: "está", tilde: true), ErrorOrtografico(palabra: "dió", tilde: true)]
        #expect(Penalizacion.calcular(errores) == 1.0)
        #expect(Penalizacion.calcular(palabras: 30, tildes: 4) == 16, "Sin límite")
        var s = SesionExamen(modo: .medio("OF.2026.O", area: "LEN"), preguntas: [.oficial(examen: "OF.2026.O", numero: 1)], duracionMin: 45, inicio: .now)
        s.respuestas[0] = .init(texto: "Resumen")
        s.autoevaluaciones[0] = .init(nivel: .regular, palabras: 2, tildes: 1)
        let r = CorrectorExamen.corregir(s, banco: banco, fecha: .now)
        #expect(r.nota == 5 && r.penalizacion == 1.25 && r.notaFinal == 3.75 && !r.apto && r.etiquetaPenalizacion == "según las bases de 2026")
    }

    @Test("Cuenta atrás: avisos a los 15 y 5 minutos, entrega automática a 0 y reanudación con el tiempo correcto")
    @MainActor
    func tiempo() throws {
        let repo = RepositorioEnMemoria()
        let servicio = ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, 27)), calendario: Fx.madrid,
                                      rng: GeneradorConSemilla(semilla: 1))
        var s = try servicio.empezarExamen(.oficial("OF.2017.O"))
        #expect(s.restante == 90 * 60 && s.preguntas.count == 19)
        s.actual = 4
        let aviso15 = s.avanzar(75 * 60, ahora: .now) ?? -1
        #expect(aviso15 == 900, "Aviso de los 15 minutos")
        try servicio.guardarExamen(s)
        // Se cierra la app: al volver, la misma pregunta y el tiempo que quedaba.
        let reanudado = try #require(try servicio.examenEnCurso())
        #expect(reanudado.actual == 4 && reanudado.restante == 900 && reanudado.estado == .enCurso)
        let json = try JSONDecoder().decode(SesionExamen.self, from: JSONEncoder().encode(reanudado))
        #expect(json == reanudado, "Se guarda tal cual")
        var r = reanudado
        let aviso5 = r.avanzar(10 * 60, ahora: .now) ?? -1
        #expect(aviso5 == 300, "Aviso de los 5 minutos")
        r.avanzar(10 * 60, ahora: .now)
        #expect(r.restante == 0 && r.estado == .entregado && r.entregaAutomatica)
    }

    @Test("Informe: «Repasar ahora» envía al Rescate las competencias flojas")
    @MainActor
    func informe() throws {
        let repo = RepositorioEnMemoria()
        let servicio = ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, 27)), calendario: Fx.madrid,
                                      rng: GeneradorConSemilla(semilla: 1))
        var s = try servicio.empezarExamen(.medio("OF.2024.O", area: "MAT"))
        for i in s.preguntas.indices {
            s.respuestas[i] = .init(valor: "1")
            s.autoevaluaciones[i] = .init(nivel: i < 3 ? .bien : .mal)
        }
        let corregido = try servicio.corregir(s)
        let r = try #require(corregido.resultado)
        #expect(corregido.estado == .corregido && !r.debiles.isEmpty)
        let enviadas = try servicio.repasarAhora(r)
        #expect(!enviadas.isEmpty && Set(enviadas).isSubset(of: Set(r.debiles)))
        let cola = try repo.colaRescate()
        #expect(Set(cola.entradas.map(\.competencia)) == Set(enviadas))
        #expect(try servicio.historialExamenes().first?.id == corregido.id)
        #expect(AccesoTribunal.acceso(.oficial("OF.2017.O")) == .permitido)
    }
}
