import Foundation
import Testing
@testable import Educulter

@MainActor
@Suite("Flujo de ronda (view models)")
struct RondaViewModelTests {
    let banco: BancoContenido
    let repo = RepositorioEnMemoria()

    init() throws {
        banco = try CargadorContenido.desdeBundle().cargar(politica: .todos)
    }

    func servicio(dia: Int = 23) -> ServicioSesion {
        ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, dia, 10)),
                       calendario: Fx.madrid, rng: GeneradorConSemilla(semilla: 11))
    }

    /// Juega la ronda entera: acierta todo salvo los índices de `fallos`.
    func jugar(_ m: RondaViewModel, fallos: Set<Int> = []) {
        if m.fase == .teoria { m.empezarTrasTeoria() }
        var i = 0
        while m.fase == .respondiendo, i < 20 {
            #expect(!m.puedeComprobar, "Sin respuesta no se puede comprobar")
            m.rellenarParaPruebas(correcta: !fallos.contains(i))
            #expect(m.puedeComprobar)
            m.comprobar()
            #expect(m.fase == .corregido)
            m.continuar()
            i += 1
        }
    }

    @Test("Ronda completa: resumen, XP, combo y racha guardados")
    func rondaCompleta() throws {
        let m = RondaViewModel(servicio: servicio(), tipo: .items(EntornoApp.itemsDemostracion(banco)))
        #expect(m.total == 10 && m.fase == .respondiendo)
        jugar(m, fallos: [4])
        let r = try #require(m.resumen)
        #expect(m.fase == .resumen)
        #expect(r.aciertos == 9 && r.total == 10)
        #expect(r.comboMaximo == 5)
        let xpGuardado = try repo.perfil().xpTotal
        #expect(r.xp > 0 && r.xp == xpGuardado)
        #expect(r.racha.actual == 1 && r.cambiosRacha.incrementada)
        #expect(r.logros.contains { $0.id == "primera-ronda" })
        #expect(try repo.intentos(desde: nil).count == 10)
        #expect(try repo.colaRescate().cantidad == 1)
    }

    @Test("Racha tras completar rondas en días seguidos")
    func rachaTrasCompletar() throws {
        jugar(RondaViewModel(servicio: servicio(dia: 23), tipo: .ortografiaExpres))
        let segunda = RondaViewModel(servicio: servicio(dia: 24), tipo: .ortografiaExpres)
        jugar(segunda)
        #expect(segunda.resumen?.racha.actual == 2)
        #expect(segunda.resumen?.racha.record == 2)
        let misiones = try repo.perfil().misiones
        if let orto = misiones.first(where: { $0.tipo == .ortografiaExpres }) { #expect(orto.completada) }
    }

    @Test("La pista se muestra, solo en peldaños 1–2, y deja el XP del ítem a 0")
    func pista() throws {
        let m = RondaViewModel(servicio: servicio(), tipo: .items(["LEN.SIN.SUJPRED.0001", "MAT.NUM.FRACSUM.0001"]))
        #expect(m.puedePedirPista)
        m.pedirPista()
        #expect(m.pistasMostradas == ["Pregunta al verbo: ¿quién duerme?"])
        #expect(!m.puedePedirPista, "Solo tenía una pista")
        m.rellenarParaPruebas()
        m.comprobar()
        #expect(m.resultado?.correcto == true && m.efecto?.xp == 0)
        m.continuar()
        #expect(!m.puedePedirPista, "Peldaño 3: sin pistas")
        m.pedirPista()
        #expect(m.pistasMostradas.isEmpty)
    }

    @Test("Salir a mitad: lo respondido queda guardado y la racha no cambia")
    func salirAMitad() throws {
        let m = RondaViewModel(servicio: servicio(), tipo: .recomendada)
        if m.fase == .teoria { m.empezarTrasTeoria() }
        for _ in 0..<2 {
            m.rellenarParaPruebas()
            m.comprobar()
            m.continuar()
        }
        // El usuario cierra la ronda: no se llama a nada más.
        #expect(try repo.intentos(desde: nil).count == 2)
        #expect(try repo.perfil().racha.actual == 0)
        #expect(try repo.perfil().xpTotal == m.xpRonda)
        #expect(m.resumen == nil)
    }

    @Test("Feedback específico, solución, Ver regla y otra ronda")
    func feedbackYOtraRonda() throws {
        let m = RondaViewModel(servicio: servicio(), tipo: .items(["MAT.ROM.LECTURA.0001", "LEN.ORT.TILDES.0001"]))
        #expect(m.feedbackEspecifico.isEmpty && m.teoriaDelItem == nil)
        m.comprobar()
        #expect(m.fase == .respondiendo, "Sin respuesta no se comprueba")
        m.respuesta = .eleccion("b")
        m.comprobar()
        #expect(m.feedbackEspecifico.first?.contains("XVI") == true)
        #expect(m.solucion == "14")
        m.continuar()
        m.rellenarParaPruebas()
        m.comprobar()
        #expect(m.teoriaDelItem?.id == "LEN.ORT.TILDES.T01")
        m.verRegla()
        #expect(m.teoriaAbierta?.id == "LEN.ORT.TILDES.T01")
        m.continuar()
        #expect(m.fase == .resumen && m.nombreCompetencia("MAT.ROM.LECTURA") == "Lectura de números romanos")
        m.otraRonda()
        #expect(m.fase == .respondiendo || m.fase == .teoria)
        #expect(m.ronda.tipo == .recomendada && m.respondidos == 0)
    }

    @Test("Teoría previa en el peldaño 1 y ronda vacía")
    func teoriaYVacia() throws {
        try repo.guardar(PerfilJugador(competenciaEnCurso: "LEN.ORT.TILDES"))
        let m = RondaViewModel(servicio: servicio(), tipo: .recomendada)
        #expect(m.fase == .teoria)
        #expect(m.tarjetasPrevias.map(\.id) == ["LEN.ORT.TILDES.T01"])
        m.empezarTrasTeoria()
        #expect(m.fase == .respondiendo)
        let vacia = RondaViewModel(servicio: servicio(), tipo: .rescate)
        #expect(vacia.fase == .vacia && vacia.itemActual == nil && !vacia.puedePedirPista)
        vacia.continuar()
        vacia.empezarTrasTeoria()
        #expect(vacia.fase == .vacia)
    }

    @Test("Hoy: carga, empezar y cerrar ronda")
    func hoy() throws {
        let hoy = HoyViewModel(servicio: servicio())
        hoy.cargar()
        #expect(hoy.estado?.misiones.count == 3 && hoy.mensajeError == nil)
        hoy.empezar(.ortografiaExpres)
        let ronda = try #require(hoy.rondaActiva)
        jugar(ronda)
        hoy.cerrarRonda()
        #expect(hoy.rondaActiva == nil && hoy.estado?.racha.actual == 1)
    }

    @Test("Opciones de arranque y entorno")
    func opcionesArranque() {
        let o = OpcionesArranque.desde(["app", "-enMemoria", "-semilla", "42", "-ayudasDePrueba", "-rondaDemostracion", "-captura", "item:X:antes"])
        #expect(o == OpcionesArranque(enMemoria: true, semilla: 42, ayudasDePrueba: true, rondaDemostracion: true, captura: "item:X:antes"))
        #expect(OpcionesArranque.desde(["app"]) == OpcionesArranque())
        let entorno = EntornoApp.crear(argumentos: ["app", "-enMemoria", "-rondaDemostracion"])
        #expect(entorno.servicio != nil && entorno.errorCarga == nil)
        if case .items(let ids) = entorno.tipoRondaPrincipal { #expect(ids.count == 10) } else { Issue.record("Debería ser la ronda de demostración") }
        #expect(EntornoApp.crear(argumentos: ["app", "-enMemoria"]).tipoRondaPrincipal == .recomendada)
        #expect(entorno.servicioDeRevision() != nil)
    }
}
