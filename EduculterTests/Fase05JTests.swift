import CryptoKit
import Foundation
import PDFKit
import Testing
@testable import Educulter

// Tests de la Fase 05J: simulacros escritos originales (datos, catálogo, corrección en centésimas,
// intentos, PDF y acceso), convocatorias en modo examen y cierre del lote 06.

private let banco: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5))!
private let release: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .soloAprobados, semillaBase: 5))!
private let raiz = Bundle.main.url(forResource: "Content", withExtension: nil)!

@MainActor
private func servicio(_ repo: any RepositorioProgreso, _ ahora: Date) -> ServicioSesion {
    ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: ahora), calendario: Fx.madrid, rng: GeneradorConSemilla(semilla: 1))
}

@Suite("05J · Simulacros escritos")
struct SimulacrosEscritosTests {
    @Test("Catálogo: 4 simulacros, sin campos de PDF y con el SHA-256 de cada archivo tal como está guardado")
    func catalogo() throws {
        let url = raiz.appendingPathComponent("tribunal/originales/Catalogo-tribunal.json")
        let bruto = try Data(contentsOf: url)
        let texto = String(decoding: bruto, as: UTF8.self)
        #expect(!texto.contains("imprimirPDF") && !texto.contains("sha256PDF"))
        let cat = try JSONDecoder().decode(CatalogoTribunal.self, from: bruto)
        #expect(cat.esquema == 1 && cat.simulacros.map(\.id) == ["SIM.DEMO.01", "SIM.OR.01", "SIM.OR.02", "SIM.OR.03"])
        for e in cat.simulacros {
            let datos = try Data(contentsOf: raiz.appendingPathComponent("tribunal/originales/\(e.datos)"))
            let huella = SHA256.hash(data: datos).map { String(format: "%02x", $0) }.joined()
            #expect(huella == e.sha256Datos, "\(e.id)")
            #expect(e.procedencia == "original_educulter" && e.revision == 1)
        }
        #expect(cat.simulacros.filter(\.esMuestra).map(\.id) == ["SIM.DEMO.01"])
        #expect(cat.simulacros.map(\.duracionSegundos) == [1080, 5400, 5400, 5400])
        #expect(banco.tribunal.originales.map(\.id) == cat.simulacros.map(\.id))
        #expect(release.tribunal.originales.count == 4, "Aprobados para la beta: también en Release")
    }

    @Test("Estructura: ids L01…/M01…, rúbrica [20, 20, 10], 500 centésimas por área (100 en la muestra) y sin enunciados repetidos")
    func estructura() {
        var enunciados = Set<String>()
        for s in banco.tribunal.originales {
            let n = s.entrada.esMuestra ? 2 : 10
            let ids = (1...n).map { String(format: "L%02d", $0) } + (1...n).map { String(format: "M%02d", $0) }
            #expect(s.datos.preguntas.map(\.id) == ids, "\(s.id)")
            #expect(s.datos.preguntas.allSatisfy { $0.rubrica.map(\.puntos) == [20, 20, 10] }, "\(s.id)")
            #expect(s.datos.maximo(area: "LEN") == n * 50 && s.datos.maximo(area: "MAT") == n * 50, "\(s.id)")
            #expect(s.maximo == (s.entrada.esMuestra ? 200 : 1000))
            #expect(!s.datos.texto.isEmpty && s.datos.preguntas.allSatisfy { !$0.solucion.isEmpty && !$0.enunciado.isEmpty })
            for p in s.datos.preguntas { #expect(enunciados.insert(p.enunciado).inserted, "\(s.id)·\(p.id) repetido") }
        }
    }

    @Test("Mapa de repaso: una competencia del catálogo para cada pregunta")
    func mapa() {
        let competencias = Set(banco.catalogo.todasLasCompetencias.map(\.id))
        let t = banco.tribunal
        #expect(t.mapaRepaso.count == 64)
        for s in t.originales {
            for p in s.datos.preguntas {
                let c = t.mapaRepaso[MapaRepaso.clave(s.id, p.id)]
                #expect(c.map(competencias.contains) == true, "\(s.id)·\(p.id): \(c ?? "sin competencia")")
                #expect(c.map { Catalogo.area(de: $0) } == p.area, "\(s.id)·\(p.id)")
            }
        }
    }

    @Test("Corrección: centésimas enteras, «revisión pendiente» sin ceros y penalización aparte")
    func correccion() throws {
        let s = try #require(banco.tribunal.original("SIM.OR.01"))
        var i = IntentoEscrito(simulacro: s.id, revision: 1, formato: .app, inicio: Fx.fecha(2026, 11, 27), duracionSegundos: 5400)
        var r = CorrectorEscrito.corregir(i, simulacro: s.datos)
        #expect(r.revisionPendiente && r.total == nil && r.pendientes.count == 20 && r.areas["LEN"] == .some(nil))
        for p in s.datos.lengua { i.criterios[p.id] = [true, true, true] }
        r = CorrectorEscrito.corregir(i, simulacro: s.datos)
        #expect(r.areas["LEN"] == .some(500) && r.areas["MAT"] == .some(nil) && r.total == nil)
        for p in s.datos.matematicas { i.criterios[p.id] = [true, false, true] }
        i.criterios["M10"] = [false, false, false]
        r = CorrectorEscrito.corregir(i, simulacro: s.datos)
        #expect(r.areas["MAT"] == .some(9 * 30) && r.total == 770 && r.maximo == 1000 && !r.revisionPendiente)
        #expect(CorrectorEscrito.texto(r.total!) == "7,70" && CorrectorEscrito.texto(5) == "0,05")
        i.faltasPalabras = 1
        i.faltasTildes = 3
        r = CorrectorEscrito.corregir(i, simulacro: s.datos)
        #expect(r.penalizacion == 125 && r.totalConPenalizacion == 645 && r.total == 770)
        i.aplicarPenalizacion = false
        #expect(CorrectorEscrito.corregir(i, simulacro: s.datos).totalConPenalizacion == 770)
        // Prioridades: como mucho 2, las de más centésimas perdidas.
        let prioridades = CorrectorEscrito.prioridades(i, simulacro: s.datos, mapa: banco.tribunal.mapaRepaso)
        #expect(prioridades.count == 2 && prioridades.first == "MAT.POR.PROP", "\(prioridades)")
        // La muestra se puntúa sobre 2.
        let demo = try #require(banco.tribunal.original("SIM.DEMO.01"))
        var d = IntentoEscrito(simulacro: demo.id, revision: 1, formato: .papel, inicio: nil, duracionSegundos: 1080)
        for p in demo.datos.preguntas { d.criterios[p.id] = [true, true, false] }
        #expect(CorrectorEscrito.corregir(d, simulacro: demo.datos).total == 160 && demo.maximo == 200)
    }

    @Test("Intentos: uno activo por simulacro, reanudación con el reloj sin pausa, fin de tiempo y entrega sin duplicados",
          arguments: ProgresoTests.Tipo.allCases)
    @MainActor
    func intentos(_ tipo: ProgresoTests.Tipo) throws {
        let repo = try ProgresoTests().repositorio(tipo)
        let t0 = Fx.fecha(2026, 11, 27, 10)
        let s0 = servicio(repo, t0)
        #expect(try s0.simulacroPrincipal()?.id == "SIM.DEMO.01", "Primero, la muestra")
        var a = try s0.empezarEscrito("SIM.OR.01", formato: .app)
        #expect(try s0.empezarEscrito("SIM.OR.01", formato: .app).id == a.id, "Un solo intento activo por simulacro")
        a.respuestas["L01"] = "Respuesta"
        a.marcas.insert("M03")
        a.criterios = [:]
        a.borradores["L01"] = Data([1, 2, 3])
        try s0.guardar(a)
        // Suspensión: 30 minutos fuera de la app; el reloj no se ha detenido.
        let s1 = servicio(repo, t0.addingTimeInterval(30 * 60))
        let reanudado = try #require(try s1.intentoActivo("SIM.OR.01"))
        #expect(reanudado == a && reanudado.restante(t0.addingTimeInterval(30 * 60)) == 60 * 60)
        #expect(reanudado.estado("L01") == .respondida && reanudado.estado("M03") == .marcada && reanudado.estado("L02") == .sinResponder)
        // Otro simulacro puede tener su propio intento activo.
        let b = try s1.empezarEscrito("SIM.DEMO.01", formato: .papel)
        #expect(b.id != a.id && b.formato == .papel)
        // Fin del tiempo con la app cerrada: entregado a la hora exacta, de forma automática.
        let s2 = servicio(repo, t0.addingTimeInterval(3 * 3600))
        let todos = try s2.intentosEscritos()
        #expect(todos.count == 2 && todos.allSatisfy(\.entregado))
        let fin = try #require(todos.first { $0.id == a.id })
        #expect(fin.entrega == t0.addingTimeInterval(5400) && fin.entregaAutomatica && fin.duracionReal == 5400)
        // Entregar otra vez no duplica ni cambia la entrega.
        let otra = try s2.entregar(fin)
        let tras = try s2.intentosEscritos()
        #expect(otra.entrega == fin.entrega && tras.count == 2)
        // Corregir en papel sin tiempo: duración desconocida, intento aparte, nunca activo.
        let papel = try s2.corregirEnPapel("SIM.OR.01")
        #expect(papel.inicio == nil && papel.duracionReal == nil && papel.entregado && !papel.activo)
        let total = try s2.intentosEscritos().count
        let ultimo = try s2.intentosEntregados().first?.id
        #expect(total == 3 && ultimo == papel.id)
        // Con la muestra hecha, la tarjeta principal pasa al siguiente simulacro sin hacer.
        #expect(try s2.simulacroPrincipal()?.id == "SIM.OR.02")
        #expect(try s2.sugerencia(tras: fin).contains("La biblioteca de las cosas"))
    }

    @Test("Entrega manual antes de tiempo y reloj desde la hora de inicio")
    func entregaManual() {
        let t0 = Fx.fecha(2026, 11, 27, 10)
        var i = IntentoEscrito(simulacro: "SIM.DEMO.01", revision: 1, formato: .app, inicio: t0, duracionSegundos: 1080)
        #expect(i.restante(t0.addingTimeInterval(80)) == 1000 && !i.comprobarTiempo(t0.addingTimeInterval(80)))
        i.entregar(t0.addingTimeInterval(600))
        #expect(i.entrega == t0.addingTimeInterval(600) && !i.entregaAutomatica && i.duracionReal == 600)
        i.entregar(t0.addingTimeInterval(900))
        #expect(i.entrega == t0.addingTimeInterval(600))
    }

    @Test("PDF A4: mismos ids en el mismo orden que la app, texto base y sin soluciones")
    @MainActor
    func pdf() throws {
        for s in banco.tribunal.originales {
            let doc = try #require(PDFDocument(data: PDFSimulacro.generar(s)))
            let pagina = try #require(doc.page(at: 0))
            #expect(abs(pagina.bounds(for: .mediaBox).width - 595.28) < 1 && abs(pagina.bounds(for: .mediaBox).height - 841.89) < 1)
            let texto = (0..<doc.pageCount).compactMap { doc.page(at: $0)?.string }.joined(separator: "\n")
            let posiciones = s.datos.preguntas.map { p in texto.range(of: "\(p.id) ·")?.lowerBound }
            #expect(posiciones.allSatisfy { $0 != nil }, "\(s.id): faltan ids")
            let orden = posiciones.compactMap { $0 }
            #expect(orden == orden.sorted(), "\(s.id): ids fuera de orden")
            #expect(texto.contains(s.entrada.titulo) && texto.contains(String(s.datos.texto.prefix(20))))
            #expect(!texto.contains(String(s.datos.preguntas[0].solucion.prefix(30))), "\(s.id): sin soluciones")
        }
    }

    @Test("Acceso: la muestra es gratis; sin Premium, un simulacro de pago no se hace ni se imprime")
    func acceso() throws {
        let demo = try #require(banco.tribunal.original("SIM.DEMO.01")).entrada
        let or1 = try #require(banco.tribunal.original("SIM.OR.01")).entrada
        #expect(AccesoTribunal.acceso(demo, premium: false) == .permitido)
        #expect(AccesoTribunal.acceso(or1, premium: false) == .soloPremium)
        #expect(AccesoTribunal.acceso(or1, premium: true) == .permitido)
        #expect(AccesoTribunal.acceso(.oficial("OF.2017.O"), premium: false) == .soloPremium)
    }
}

@Suite("05J · Convocatorias anteriores")
struct ConvocatoriasTests {
    @Test("Modo examen solo en las completas (2017 y 2026 aplazada); el resto, repaso con motivo")
    func completas() throws {
        let t = banco.tribunal
        #expect(t.examenes.filter(\.completo).map(\.id).sorted() == ["OF.2017.O", "OF.2026.A"])
        #expect(t.examenes.filter { !$0.completo }.allSatisfy { $0.motivoSoloRepaso != nil })
        // La tabla de 2026.A·M6 (pregunta 16), con los mismos valores que el texto plano.
        let q = try #require(t.examen("OF.2026.A")?.preguntas.first { $0.numero == 16 })
        let tabla = try #require(q.tabla)
        #expect(tabla.cabecera == ["Suceso", "Probabilidad"] && tabla.filas.count == 4)
        for fila in tabla.filas { #expect(q.enunciado.contains("\(fila[0]) | \(fila[1])")) }
        #expect(!q.enunciadoVisible.contains("|") && q.enunciadoVisible.hasPrefix("Tenemos 12 tarjetas"))
        #expect(t.examenes.allSatisfy { e in e.preguntas.allSatisfy { !$0.tablaSinEstructura } || !e.completo })
    }
}

@Suite("05J · Lote 06")
struct Lote06Tests {
    static let datos = banco.recursos.tildeContexto!

    @Test("Tilde en contexto: 118 frases, una sola opción válida y distractores de la misma palabra")
    func frases() {
        let casos = GeneradorTildeContexto.casos(Self.datos)
        #expect(Self.datos.palabras.count == 70 && casos.count == 118)
        for c in casos {
            let f = c.frase
            let formas = Set(c.palabra.formas.map(\.forma))
            #expect(f.opciones.filter { $0 == f.correcta }.count == 1, "\(c.id): una sola correcta")
            #expect(Set(f.opciones).count == f.opciones.count && f.opciones.count >= 2, "\(c.id)")
            #expect(Set(f.opciones).isSubset(of: formas), "\(c.id): distractores de otra palabra")
            #expect(f.frase.components(separatedBy: "___").count == 2, "\(c.id): un hueco")
            let e = GeneradorTildeContexto.explicacion(c)
            #expect(e.hasPrefix(GeneradorTildeContexto.tieneTilde(f.correcta) ? "Lleva tilde porque" : "No lleva tilde porque"), "\(c.id): \(e)")
        }
        #expect(Dictionary(grouping: casos, by: \.dificultad).mapValues(\.count) == [2: 70, 3: 46, 4: 2])
        let mono = casos.filter { $0.dificultad == 4 }
        #expect(Set(mono.map(\.frase.correcta)) == ["rio", "frio"])
        #expect(mono.allSatisfy { GeneradorTildeContexto.explicacion($0).contains("monosílabo ortográfico") && GeneradorTildeContexto.explicacion($0).contains("RAE, Ortografía, 2010") })
        #expect(casos.contains { $0.frase.frase == "La ___ Martínez dirigió la investigación." && $0.frase.correcta == "comisaria" })
        #expect(!casos.contains { $0.frase.frase == "La ___ dirigió la investigación." })
    }

    @Test("LEN.ORT.CTX: competencia del bloque de Ortografía y plantilla aprobada que genera en todos los niveles")
    func plantilla() throws {
        #expect(banco.catalogo.bloque(deCompetencia: "LEN.ORT.CTX")?.id == "LEN.ORT")
        #expect(banco.catalogo.todasLasCompetencias.first { $0.id == "LEN.ORT.CTX" }?.nombre == "Tilde que cambia el significado")
        let p = try #require(release.plantilla(id: "LEN.ORT.CTX.G01"))
        #expect(p.validacion.estado == .aprobado && p.tipo == "tildeContexto")
        for d in 1...6 {
            let item = try MotorGeneradores.generar(MotorGeneradores.ajustada(p, dificultad: d), semilla: 7, recursos: release.recursos)
            #expect(item.competencia == "LEN.ORT.CTX" && !item.explicacion.isEmpty)
        }
    }

    @Test("Remedio estático: 8 errores, distractores etiquetados y Rescate con la tarjeta y sus ítems")
    @MainActor
    func remedioEstatico() throws {
        let errores = release.recursos.errores
        #expect(errores.errores.count == 144, "112 + 8 estáticos del lote 06 + ERR.LEN.ORT.CTX.1 + 23 de la 05K")
        let estaticos = errores.errores.filter(\.remedio.esEstatico)
        #expect(estaticos.map(\.id) == ["ERR.LEN.COM.INFER.1", "ERR.LEN.COM.INFER.2", "ERR.LEN.COM.INFER.3", "ERR.LEN.LEX.SIN.1",
                                        "ERR.LEN.LEX.SIN.2", "ERR.LEN.LEX.SIN.3", "ERR.LEN.LEX.DICC.1", "ERR.MAT.NUM.FRAEQ.1"])
        #expect(estaticos.allSatisfy { $0.remedio.plantilla == nil && $0.detecta.isEmpty && $0.remedio.explicacion.count <= 140 })
        #expect(ValidadorContenido(anioActual: 2026).validar(errores: errores, banco: release).isEmpty)
        let etiquetas = release.itemsEstaticos.flatMap { i in i.erroresHabituales.compactMap { h in h.error.map { "\(i.id)|\(h.respuesta)|\($0)" } } }
        for e in ["LEN.COM.INFER.0001|falso|ERR.LEN.COM.INFER.1", "LEN.COM.INFER.0004|detalle|ERR.LEN.COM.INFER.2", "LEN.COM.INFER.0004|otro|ERR.LEN.COM.INFER.3",
                  "LEN.LEX.SIN.0003|o2|ERR.LEN.LEX.SIN.1", "LEN.LEX.SIN.0005|o2|ERR.LEN.LEX.SIN.2", "LEN.LEX.SIN.0007|h2|ERR.LEN.LEX.SIN.3",
                  "LEN.LEX.DICC.0002|o3|ERR.LEN.LEX.DICC.1", "MAT.NUM.FRAEQ.0005|h1|ERR.MAT.NUM.FRAEQ.1"] {
            #expect(etiquetas.contains(e), "\(e)")
        }
        // Rescate de un error estático activo: su tarjeta antes y hasta 3 de sus ítems.
        let repo = RepositorioEnMemoria()
        let s = ServicioSesion(banco: release, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, 27)), calendario: Fx.madrid, rng: GeneradorConSemilla(semilla: 3))
        let item = try #require(release.item(id: "LEN.LEX.SIN.0005"))
        for dia in [25, 26] {
            let r = Evaluador.evaluar(.eleccion("o2"), para: item)
            var efecto = EfectoRespuesta()
            try s.registrarErrores(item: item, resultado: r, errorRemedio: nil, fecha: Fx.fecha(2026, 11, dia), efecto: &efecto)
        }
        let ronda = try #require(try s.prepararRescateError("ERR.LEN.LEX.SIN.2"))
        #expect(ronda.teoriaPrevia == ["LEN.LEX.SIN.T01"])
        #expect(!ronda.items.isEmpty && ronda.items.count <= 3 && ronda.items.allSatisfy { $0.itemId.hasPrefix("LEN.LEX.SIN.") && $0.errorId == "ERR.LEN.LEX.SIN.2" })
    }

    @Test("Esquemas sin «Etiqueta: valor» (SUP, TIEM, VOL): una fila de texto por equivalencia, sin cambiar el texto")
    func esquemas() throws {
        for id in ["MAT.UNI.SUP.T01", "MAT.UNI.TIEM.T01", "MAT.UNI.VOL.T01"] {
            let t = try #require(release.teoria.first { $0.id == id })
            let esquema = try #require(t.bloques.first { $0.tipo == .esquema })
            let filas = FilaEsquema.filas(de: esquema.contenido)
            let lineas = esquema.contenido.split(separator: "\n").map(String.init)
            #expect(filas == lineas.map { .texto($0) }, "\(id)")
        }
    }
}
