import Foundation
import SwiftData
import Testing
@testable import Educulter

// Tests de la 05E parte 2: motor de errores (§4) y sesión diaria (§3).

private let bancoTodo: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5))!
private let bancoAprobado: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .soloAprobados, semillaBase: 5))!

@MainActor
private func servicio(_ repo: any RepositorioProgreso, _ ahora: Date, banco: BancoContenido = bancoTodo) -> ServicioSesion {
    ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: ahora), calendario: Fx.madrid,
                   rng: GeneradorConSemilla(semilla: 11))
}

private func evento(_ error: String, _ tipo: EventoError.Tipo, _ fecha: Date) -> EventoError {
    EventoError(fecha: fecha, errorId: error, tipo: tipo, itemId: "x")
}

// MARK: - Motor de errores

@Suite("Motor de errores: catálogo y etiquetado (05E parte 2 §4)")
struct CatalogoErroresTests {
    @Test("El catálogo carga, cumple el validador y cada error tiene un remedio que se puede generar")
    func catalogo() throws {
        for banco in [bancoTodo, bancoAprobado] {
            let c = banco.recursos.errores
            #expect(c.errores.count >= 80)
            #expect(ValidadorContenido(anioActual: 2026).validar(errores: c, banco: banco).isEmpty)
            for e in c.errores {
                if e.remedio.esEstatico {
                    // Remedio estático (lote 06, 05J): tarjeta e ítems aprobados de la competencia.
                    var rng = GeneradorConSemilla(semilla: 1)
                    #expect(!ConstructorSesion.itemsRemedioEstatico(e, banco: banco, rng: &rng).isEmpty, "\(e.id)")
                    #expect(e.remedio.tarjeta.flatMap { t in banco.teoria.first { $0.id == t } } != nil, "\(e.id)")
                    continue
                }
                let p = try #require(banco.plantilla(id: e.remedio.plantilla ?? ""), "\(e.id)")
                let ajustada = MotorGeneradores.ajustada(p, dificultad: max(1, (e.remedio.dificultad ?? 2) - 1))
                #expect((try? MotorGeneradores.generar(ajustada, semilla: 1, recursos: banco.recursos)) != nil, "\(e.id)")
            }
        }
    }

    @Test("El validador detecta ids, textos, remedios, patrones y errores de ítems inexistentes")
    func validador() {
        let malo = ErrorTipico(id: "ERR.X.1", competencia: "LEN.NO", descripcion: (1...13).map { "p\($0)" }.joined(separator: " "),
                               remedio: .init(plantilla: "NO.EXISTE", dificultad: 9, explicacion: ""),
                               detecta: [.init(generador: "romanos", patron: "([")])
        let mensajes = ValidadorContenido(anioActual: 2026).validar(errores: CatalogoErrores(errores: [malo, malo]), banco: bancoTodo).map(\.mensaje)
        for texto in ["id duplicado", "competencia desconocida", "ERR.<competencia>.<n>", "13 palabras", "regla del remedio",
                      "no existe o no está cargada", "dificultad del remedio", "expresión regular no válida"] {
            #expect(mensajes.contains { $0.contains(texto) }, "\(texto)")
        }
    }

    @Test("Ningún distractor de una plantilla aprobada queda sin etiquetar (6 niveles × 20 semillas)")
    func todosEtiquetados() {
        var sin: [String] = []
        var total = 0
        for p in bancoAprobado.plantillas {
            for d in 1...6 {
                for s in UInt64(0)..<20 {
                    guard let i = try? MotorGeneradores.generar(MotorGeneradores.ajustada(p, dificultad: d), semilla: s, recursos: bancoAprobado.recursos) else { continue }
                    for e in i.erroresHabituales {
                        total += 1
                        if e.error == nil { sin.append("\(p.id) d\(d): \(e.feedback.prefix(60))") }
                    }
                }
            }
        }
        #expect(total > 10_000)
        #expect(sin.isEmpty, "\(sin.prefix(5))")
    }

    @Test("Los errores puestos a mano en los estáticos existen y los ítems sin plantilla quedan como «no clasificados»")
    func estaticos() {
        let etiquetados = bancoTodo.itemsEstaticos.flatMap(\.erroresHabituales).filter { $0.error != nil }
        #expect(etiquetados.count >= 40)
        #expect(etiquetados.allSatisfy { bancoTodo.recursos.errores[$0.error!] != nil })
        // D-113: los 8 distractores estáticos aprobados que quedaban sin etiquetar (LEN.COM.INFER,
        // LEN.LEX.SIN, LEN.LEX.DICC y MAT.NUM.FRAEQ) tienen ya su error con remedio estático (lote 06, 05J):
        // ninguno queda sin etiquetar.
        let sin = bancoAprobado.itemsEstaticos.flatMap { i in i.erroresHabituales.filter { $0.error == nil }.map { (i.id, $0.respuesta) } }
        #expect(sin.isEmpty, "\(sin)")
        let estaticos = bancoAprobado.recursos.errores.errores.filter(\.remedio.esEstatico)
        #expect(bancoAprobado.recursos.errores.errores.count == 120 && estaticos.count == 8)
        #expect(estaticos.allSatisfy { e in bancoAprobado.itemsEstaticos.contains { i in i.erroresHabituales.contains { $0.error == e.id } } })
    }

    @Test("Detección por distractor y por valor numérico")
    func deteccion() throws {
        let p = try #require(bancoTodo.plantilla(id: "MAT.POR.CALC.G01"))
        let item = try MotorGeneradores.generar(p, semilla: 3, recursos: bancoTodo.recursos)
        let h = try #require(item.erroresHabituales.first)
        let id = try #require(h.error)
        let directo = Evaluador.evaluar(.numerico(h.respuesta), para: item)
        #expect(EstadoErrores.errores(de: directo, item: item) == [id])
        // El mismo valor escrito de otra forma (cero decimal de más) delata el mismo error.
        let otraForma = h.respuesta.contains(",") ? h.respuesta + "0" : h.respuesta + ",0"
        let r = Evaluador.evaluar(.numerico(otraForma), para: item)
        #expect(!r.correcto && EstadoErrores.errores(de: r, item: item) == [id])
        // Una respuesta errónea que no es ningún distractor no se clasifica.
        #expect(EstadoErrores.errores(de: Evaluador.evaluar(.numerico("123456789"), para: item), item: item).isEmpty)
        // Elección: el id de la opción.
        let rom = try MotorGeneradores.generar(try #require(bancoTodo.plantilla(id: "LEN.ORT.DIA.G01")), semilla: 2, recursos: bancoTodo.recursos)
        let fallo = Evaluador.evaluar(RespuestaEjemplo.conUnError(rom.payload, erroresHabituales: rom.erroresHabituales), para: rom)
        #expect(EstadoErrores.errores(de: fallo, item: rom).first?.hasPrefix("ERR.LEN.ORT.DIA.") == true)
        #expect(EstadoErrores.errores(de: Evaluador.evaluar(RespuestaEjemplo.correcta(rom.payload), para: rom), item: rom).isEmpty)
    }
}

@Suite("Motor de errores: activación, corrección y persistencia")
struct EstadoErroresTests {
    let e = "ERR.MAT.POR.CALC.1"

    @Test("Se activa con 2 apariciones en 7 días; no con 8 días de separación")
    func activacion() {
        var s = EstadoErrores()
        #expect(!s.aplicar(evento(e, .fallo, Fx.fecha(2026, 11, 1))).activo)
        #expect(!s.aplicar(evento(e, .fallo, Fx.fecha(2026, 11, 9, 13))).activo)
        #expect(s.aplicar(evento(e, .fallo, Fx.fecha(2026, 11, 16))).activo)
        #expect(s.activos.map(\.errorId) == [e])
        #expect(EstadoErrores(eventos: [evento(e, .fallo, Fx.fecha(2026, 11, 1)), evento(e, .fallo, Fx.fecha(2026, 11, 8, 12))]).activo(e))
    }

    @Test("Se corrige con 3 aciertos seguidos en el remedio; un fallo reinicia la cuenta; puede reactivarse")
    func correccion() {
        var s = EstadoErrores(eventos: [evento(e, .fallo, Fx.fecha(2026, 11, 1)), evento(e, .fallo, Fx.fecha(2026, 11, 2))])
        s.aplicar(evento(e, .remedioAcierto, Fx.fecha(2026, 11, 3, 10)))
        s.aplicar(evento(e, .remedioAcierto, Fx.fecha(2026, 11, 3, 11)))
        s.aplicar(evento(e, .remedioFallo, Fx.fecha(2026, 11, 3, 12)))
        #expect(s.activo(e))
        s.aplicar(evento(e, .remedioAcierto, Fx.fecha(2026, 11, 3, 13)))
        s.aplicar(evento(e, .fallo, Fx.fecha(2026, 11, 3, 14)))
        #expect(s.seguimientos[e]?.aciertosSeguidos == 0)
        for h in 15...17 { s.aplicar(evento(e, .remedioAcierto, Fx.fecha(2026, 11, 3, h))) }
        #expect(!s.activo(e) && s.corregidos.map(\.errorId) == [e] && s.seguimientos[e]?.correcciones == 1)
        // Un acierto de remedio sin error activo no cambia nada; hacen falta 2 fallos nuevos para reactivarlo.
        s.aplicar(evento(e, .remedioAcierto, Fx.fecha(2026, 11, 4)))
        #expect(!s.aplicar(evento(e, .fallo, Fx.fecha(2026, 11, 5))).activo)
        #expect(s.aplicar(evento(e, .fallo, Fx.fecha(2026, 11, 6))).activo)
        #expect(s.corregidos.isEmpty)
    }

    @Test("Los sucesos se guardan en SwiftData, se leen en orden y se borran con el progreso")
    @MainActor
    func persistencia() throws {
        let repo = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(enMemoria: true))
        try repo.registrar(evento(e, .fallo, Fx.fecha(2026, 11, 2)))
        try repo.registrar(evento(e, .fallo, Fx.fecha(2026, 11, 1)))
        try repo.registrar(evento(e, .remedioAcierto, Fx.fecha(2026, 11, 3)))
        let leidos = try repo.eventosError()
        #expect(leidos.map(\.fecha) == [Fx.fecha(2026, 11, 1), Fx.fecha(2026, 11, 2), Fx.fecha(2026, 11, 3)])
        #expect(leidos.last?.tipo == .remedioAcierto && leidos.first?.errorId == e)
        try repo.borrarProgreso()
        #expect(try repo.eventosError().isEmpty)
    }
}

// MARK: - Sesión diaria

@Suite("Sesión diaria: ConstructorSesion (05E parte 2 §3.2)")
struct ConstructorSesionTests {
    /// Historial sintético: competencias empezadas al azar, algunas vencidas, y errores activos.
    static func historial(_ semilla: UInt64, banco: BancoContenido) -> ([String: EstadoCompetencia], [RemedioPendiente], [String]) {
        var rng = GeneradorConSemilla(semilla: semilla &* 2_654_435_761)
        let hoy = Fx.dia(2026, 11, 23)
        let conContenido = banco.catalogo.todasLasCompetencias.map(\.id).filter { banco.tieneItems(competencia: $0, peldanoMaximo: 4) }
        var estados: [String: EstadoCompetencia] = [:]
        for c in conContenido.shuffled(using: &rng).prefix(Int.random(in: 0...12, using: &rng)) {
            var e = EstadoCompetencia(competenciaId: c, escalera: EstadoEscalera(peldano: Int.random(in: 1...4, using: &rng)))
            if Bool.random(using: &rng) {
                e.leitner = EstadoLeitner(caja: 2, proximoRepaso: hoy.sumando(dias: Int.random(in: -9...3, using: &rng)), ultimoRepaso: nil)
            }
            estados[c] = e
        }
        let remedios = banco.recursos.errores.errores.shuffled(using: &rng).prefix(Int.random(in: 0...3, using: &rng))
            .map { RemedioPendiente(error: $0, dificultad: Int.random(in: 1...5, using: &rng)) }
        let plan = PlanEstudio(banco: banco).mixto(conContenido.filter { !(estados[$0]?.escalera.peldano ?? 0 >= 5) })
        return (estados, Array(remedios), plan)
    }

    @Test("1000 historiales: proporciones (±1), bloques, intercalado, sin repetir y determinista")
    func propiedades() throws {
        let banco = bancoAprobado
        let ahora = Fx.fecha(2026, 11, 23, 10)
        let constructor = ConstructorSesion(banco: banco)
        var fallos: [String] = []
        for semilla in UInt64(0)..<1000 {
            let (estados, remedios, plan) = Self.historial(semilla, banco: banco)
            let n = [8, 15, 22][Int(semilla % 3)]
            let foco: FocoSesion = semilla % 5 == 4 ? (semilla % 2 == 0 ? .lengua : .matematicas) : .mixto
            func construir() -> SesionDiaria {
                constructor.construir(n: n, foco: foco, estados: estados, remedios: remedios, plan: plan, vistos: [:],
                                      ahora: ahora, calendario: Fx.madrid, semilla: semilla)
            }
            let s = construir()
            let items = s.items
            func cuenta(_ m: ItemRonda.Motivo) -> Int { items.filter { $0.motivo == m }.count }
            let comp: (ItemRonda) -> String = { banco.item(id: $0.itemId)?.competencia ?? "?" }
            if items.count != n { fallos.append("\(semilla): \(items.count) de \(n)") }
            if cuenta(.remedio) > ConstructorSesion.cupoRemedios(n) { fallos.append("\(semilla): \(cuenta(.remedio)) remedios") }
            if cuenta(.repaso) > ConstructorSesion.cupoRepaso(n) { fallos.append("\(semilla): \(cuenta(.repaso)) repasos") }
            if cuenta(.nuevo) < ConstructorSesion.minimoNuevo(n) - 1 { fallos.append("\(semilla): \(cuenta(.nuevo)) nuevos de \(n)") }
            if Set(items.map(\.itemId)).count != items.count { fallos.append("\(semilla): ítem repetido") }
            let huellas = items.compactMap { banco.item(id: $0.itemId).map(banco.huella) }
            if Set(huellas).count != huellas.count { fallos.append("\(semilla): pregunta repetida") }
            if let a = foco.area, items.contains(where: { Catalogo.area(de: comp($0)) != a }) { fallos.append("\(semilla): fuera del foco") }
            // Remedios: solo de errores activos, de su plantilla y en bloques seguidos de hasta 3.
            for r in remedios {
                let pos = items.indices.filter { items[$0].errorId == r.error.id }
                if let f = pos.first, pos != Array(f..<(f + pos.count)) || pos.count > 3 { fallos.append("\(semilla): remedio partido") }
                let delRemedio: (String) -> Bool = { id in
                    r.error.remedio.esEstatico ? (r.error.remedio.items ?? []).contains(id) : id.hasPrefix((r.error.remedio.plantilla ?? "") + "@d")
                }
                if pos.contains(where: { !delRemedio(items[$0].itemId) }) { fallos.append("\(semilla): remedio de otra plantilla") }
            }
            // Lo nuevo, en bloques de la misma competencia (el primero, de 3 si hay ítems).
            let incumple = ConstructorSesion.incumplimientos(items, competencia: comp, mixto: foco == .mixto)
            if !incumple.isEmpty { fallos.append("\(semilla): \(incumple)") }
            if construir() != s { fallos.append("\(semilla): no determinista") }
        }
        #expect(fallos.isEmpty, "\(fallos.count) fallos: \(fallos.prefix(8))")
    }

    @Test("Sin progreso, remedios ni plan, la sesión pide el diagnóstico")
    func vacia() {
        let s = ConstructorSesion(banco: bancoTodo).construir(n: 8, foco: .mixto, estados: [:], remedios: [], plan: [], vistos: [:],
                                                             ahora: Fx.fecha(2026, 11, 23), calendario: Fx.madrid, semilla: 1)
        #expect(s.requiereDiagnostico)
    }

    @Test("Ítems por duración: 8, 15 y 22; con historial, minutos entre la mediana de los intervalos (6–30)")
    func numeroItems() {
        #expect(DuracionSesion.allCases.map { ConstructorSesion.numeroItems($0, intentos: []) } == [8, 15, 22])
        func intentos(cada segundos: Double, _ n: Int = 60) -> [Intento] {
            (0..<n).map { Intento(fecha: Fx.fecha(2026, 11, 20).addingTimeInterval(Double($0) * segundos), itemId: "i\($0)",
                                  competenciaId: "C", peldano: 1, correcto: true, fraccionCorrecta: 1) }
        }
        #expect(ConstructorSesion.numeroItems(.diez, intentos: intentos(cada: 30)) == 20)
        #expect(ConstructorSesion.numeroItems(.quince, intentos: intentos(cada: 10)) == 30)
        #expect(ConstructorSesion.numeroItems(.cinco, intentos: intentos(cada: 120)) == 6)
        #expect(ConstructorSesion.numeroItems(.cinco, intentos: intentos(cada: 30, 5)) == 8)
        // Pausas largas (más de 5 minutos) no cuentan.
        #expect(ConstructorSesion.numeroItems(.diez, intentos: intentos(cada: 600)) == 15)
    }
}

@Suite("Racha sin culpa: meta semanal y modo descanso (05E parte 2 §3.3)")
struct MetaYDescansoTests {
    @Test("El modo descanso dura como mucho 7 días por mes natural y congela la racha")
    func limite() {
        var periodos: [PeriodoDescanso] = []
        #expect(ModoDescanso.activar(&periodos, hoy: Fx.dia(2026, 11, 20)))
        #expect(ModoDescanso.activo(periodos, hoy: Fx.dia(2026, 11, 26)))
        #expect(!ModoDescanso.activo(periodos, hoy: Fx.dia(2026, 11, 27)))  // 8.º día: agotado
        #expect(ModoDescanso.dias(periodos, hasta: Fx.dia(2026, 12, 31)).count == 7)  // no revive en diciembre
        #expect(ModoDescanso.disponibles(periodos, hoy: Fx.dia(2026, 11, 28)) == 0)
        #expect(!ModoDescanso.activar(&periodos, hoy: Fx.dia(2026, 11, 28)))
        #expect(ModoDescanso.activar(&periodos, hoy: Fx.dia(2026, 12, 1)))
        ModoDescanso.desactivar(&periodos, hoy: Fx.dia(2026, 12, 3))
        #expect(ModoDescanso.usados(periodos, mesDe: Fx.dia(2026, 12, 20)) == 2)
        #expect(!ModoDescanso.activo(periodos, hoy: Fx.dia(2026, 12, 3)))
        // Desactivar el mismo día que se activa no gasta días.
        var otro: [PeriodoDescanso] = []
        _ = ModoDescanso.activar(&otro, hoy: Fx.dia(2026, 11, 5))
        ModoDescanso.desactivar(&otro, hoy: Fx.dia(2026, 11, 5))
        #expect(otro.isEmpty)

        var racha = EstadoRacha(actual: 10, record: 10, protectores: 0, ultimoDiaActivo: Fx.dia(2026, 11, 19), ultimoDiaProcesado: Fx.dia(2026, 11, 19))
        racha.descanso = periodos
        #expect(racha.vigente(hoy: Fx.dia(2026, 11, 27)).actual == 10)  // 20–26 de descanso: intacta
        #expect(racha.vigente(hoy: Fx.dia(2026, 11, 28)).actual == 0)   // el 27 ya no es descanso
    }

    @Test("Meta semanal de lunes a domingo, con días hechos, de descanso y pendientes")
    func meta() {
        let hoy = Fx.dia(2026, 11, 26)  // jueves
        let m = MetaSemanal(meta: 4, hoy: hoy, diasSesion: [Fx.dia(2026, 11, 23), Fx.dia(2026, 11, 25), Fx.dia(2026, 11, 22)],
                            descanso: [Fx.dia(2026, 11, 24)], calendario: Fx.madrid)
        #expect(m.dias.first?.dia == Fx.dia(2026, 11, 23) && m.dias.last?.dia == Fx.dia(2026, 11, 29))
        #expect(m.dias.map(\.estado) == [.hecho, .descanso, .hecho, .pendiente, .futuro, .futuro, .futuro])
        #expect(m.hechos == 2 && m.metaEfectiva == 4 && !m.cumplida)
        #expect(MetaSemanal(meta: 9, hoy: hoy, diasSesion: [], descanso: [], calendario: Fx.madrid).meta == 7)
        let conDescanso = MetaSemanal(meta: 7, hoy: hoy, diasSesion: [Fx.dia(2026, 11, 23)], descanso: Set((24...29).map { Fx.dia(2026, 11, $0) }), calendario: Fx.madrid)
        #expect(conDescanso.metaEfectiva == 1 && conDescanso.cumplida)
    }

    @Test("Los ajustes de versiones anteriores se leen con los valores nuevos por defecto")
    func ajustesAntiguos() throws {
        let viejo = #"{"sonido":false,"vibracion":true,"recordatorio":true,"minutoRecordatorio":1140,"recordatorioPreguntado":true}"#
        let a = try JSONDecoder().decode(Ajustes.self, from: Data(viejo.utf8))
        #expect(!a.sonido && a.minutoRecordatorio == 1140 && a.duracion == .diez && a.foco == .mixto && a.metaSemanal == 4)
        let nuevo = Ajustes(duracion: .quince, foco: .lengua, metaSemanal: 6)
        #expect(try JSONDecoder().decode(Ajustes.self, from: JSONEncoder().encode(nuevo)) == nuevo)
    }

    @Test("Sesiones y descanso se guardan en el perfil (SwiftData) y la sesión cuenta para la meta")
    @MainActor
    func servicioMeta() throws {
        let repo = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(enMemoria: true))
        try repo.guardar(EstadoCompetencia(competenciaId: "LEN.ORT.AGU"))
        let s = servicio(repo, Fx.fecha(2026, 11, 26, 10))
        let ronda = try s.prepararRonda(.sesion(duracion: .cinco, foco: .mixto))
        #expect(ronda.tipo == .sesion(duracion: .cinco, foco: .mixto) && ronda.items.count == 8)
        #expect(try !s.sesionCompletadaHoy())
        _ = try s.completarRonda(ronda)
        #expect(try s.sesionCompletadaHoy())
        #expect(try s.metaSemanal().hechos == 1)
        #expect(try s.cambiarDescanso(true) && s.descansoActivo())
        #expect(try servicio(repo, Fx.fecha(2026, 11, 27, 10)).descansoActivo())
        try s.cambiarDescanso(false)
        #expect(try !s.descansoActivo() && s.diasDescansoDisponibles() == 7)
    }
}

// MARK: - Extremo a extremo

@Suite("Motor de errores de extremo a extremo")
struct ErroresExtremoTests {
    @Test("Falla 2 veces el mismo porcentaje: la sesión trae el remedio y Rescate y Progreso lo muestran; 3 aciertos lo corrigen")
    @MainActor
    func extremo() throws {
        let repo = RepositorioEnMemoria()
        try repo.guardar(EstadoCompetencia(competenciaId: "MAT.POR.CALC"))
        let p = try #require(bancoTodo.plantilla(id: "MAT.POR.CALC.G02"))
        var errorId: String?
        var dificultadFallo = 0
        for (dia, semilla) in [(20, UInt64(4)), (22, UInt64(4))] {
            let s = servicio(repo, Fx.fecha(2026, 11, dia, 18))
            let item = try MotorGeneradores.generar(p, semilla: semilla, recursos: bancoTodo.recursos)
            // El primer distractor del error «coma decimal» (el más frecuente del generador).
            let h = try #require(item.erroresHabituales.first { $0.error == errorId ?? $0.error })
            errorId = h.error
            dificultadFallo = item.dificultad
            let efecto = try s.registrar(item: item, resultado: Evaluador.evaluar(.numerico(h.respuesta), para: item),
                                         usoPista: false, combo: 0, motivo: .nuevo)
            #expect((efecto.errorRepetido != nil) == (dia == 22), "día \(dia)")
        }
        let id = try #require(errorId)
        let s = servicio(repo, Fx.fecha(2026, 11, 23, 9))
        // La siguiente sesión trae el remedio: 3 ítems seguidos de la plantilla del remedio, un punto más fácil.
        let sesion = try s.prepararRonda(.sesion(duracion: .diez, foco: .mixto))
        let remedio = sesion.items.filter { $0.errorId == id }
        let error = try #require(bancoTodo.recursos.errores[id])
        #expect(remedio.count == 3 && remedio.allSatisfy { $0.motivo == .remedio })
        #expect(remedio.allSatisfy { $0.itemId.hasPrefix("\(error.remedio.plantilla ?? "")@d\(max(1, dificultadFallo - 1))#") })
        // Rescate y Progreso.
        let seguidos = try s.erroresSeguidos()
        #expect(seguidos.activos.map(\.id) == [id] && seguidos.activos.first?.apariciones == 2)
        let rescate = try #require(try s.prepararRescateError(id))
        #expect(rescate.items.count == 3 && rescate.items.allSatisfy { $0.errorId == id })
        // Tres aciertos seguidos en el remedio lo corrigen.
        for ir in remedio {
            let item = try #require(bancoTodo.item(id: ir.itemId))
            try s.registrar(item: item, resultado: Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item),
                            usoPista: false, combo: 1, motivo: .remedio, errorRemedio: id)
        }
        let despues = try s.erroresSeguidos()
        #expect(despues.activos.isEmpty && despues.corregidos.map(\.id) == [id])
        #expect(try s.prepararRonda(.sesion(duracion: .diez, foco: .mixto)).items.allSatisfy { $0.motivo != .remedio })
    }
}

@Suite("Sesión diaria sin diagnóstico (D-110)")
struct SesionSinDiagnosticoTests {
    @Test("Sin progreso ni diagnóstico (se saltó en la bienvenida), la sesión es de lo nuevo del plan, no el diagnóstico")
    @MainActor
    func saltarDiagnostico() throws {
        let repo = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor(enMemoria: true))
        let s = servicio(repo, Fx.fecha(2026, 11, 26, 10))
        let r = try s.prepararRonda(.sesion(duracion: .cinco, foco: .mixto))
        #expect(r.tipo == .sesion(duracion: .cinco, foco: .mixto) && r.items.count == 8 && r.items.allSatisfy { $0.motivo == .nuevo })
    }
}
