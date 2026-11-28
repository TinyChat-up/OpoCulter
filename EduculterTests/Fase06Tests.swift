import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import Educulter

// Fase 06: monetización. La lógica de negocio (acceso y política de anuncios) con tests puros, con
// fechas inyectadas y sin red; StoreKit con StoreKitTest y `Educulter.storekit`. Solo en Debug (usa el
// Premium simulado y los IDs de prueba), para que el paquete de tests también compile en Release.

#if DEBUG

private let raizProyecto = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

private var calendarioMadrid: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Madrid")!
    return c
}

/// 1 de marzo de 2027 a la hora dada (Madrid), más `dias`.
private func fecha(dia dias: Int = 0, _ hora: Int = 12, _ minuto: Int = 0) -> Date {
    calendarioMadrid.date(from: DateComponents(year: 2027, month: 3, day: 1 + dias, hour: hora, minute: minuto))!
}

private let todoListo = EntornoAnuncio(premium: false, conectado: true, consentimiento: true, identificadores: true, cargado: true)

// MARK: - Política de anuncios (§2.2)

@Suite("06 · Política de anuncios")
struct PoliticaAnunciosTests {
    let politica = PoliticaAnuncios(calendario: calendarioMadrid)
    var registro: RegistroAnuncios { RegistroAnuncios(primeraApertura: DiaCivil(fecha(), calendario: calendarioMadrid)) }

    /// Termina `n` rondas y devuelve el registro y la última decisión (sin mostrar nada).
    func rondas(_ n: Int, _ r: RegistroAnuncios, _ ahora: Date, entorno: EntornoAnuncio = todoListo) -> (RegistroAnuncios, PoliticaAnuncios.Decision) {
        var r = r
        var d = PoliticaAnuncios.Decision.no(.faltanRondas)
        for _ in 0..<n {
            r = politica.rondaTerminada(r, premium: entorno.premium, ahora: ahora)
            d = politica.decidir(.continuarTrasRonda, registro: r, entorno: entorno, ahora: ahora)
        }
        return (r, d)
    }

    @Test("Días 1 y 2: ningún anuncio, por muchas rondas que se terminen (y no cuentan para después)")
    func diasDeGracia() {
        for dia in [0, 1] {
            for hora in [0, 12, 23] {
                let (r, d) = rondas(10, registro, fecha(dia: dia, hora, 30))
                #expect(d == .no(.diasDeGracia), "día \(dia + 1) a las \(hora)")
                #expect(r.rondasDesdeUltimo == 0)
            }
        }
        #expect(politica.diaDeUso(registro, ahora: fecha(dia: 1, 23, 59)) == 2)
        #expect(politica.diaDeUso(registro, ahora: fecha(dia: 2, 0, 1)) == 3)
    }

    @Test("Día 3: el primer anuncio aparece en la 2.ª ronda terminada")
    func diaTres() {
        let ahora = fecha(dia: 2, 0, 5)
        let (r1, d1) = rondas(1, registro, ahora)
        #expect(d1 == .no(.faltanRondas))
        let (_, d2) = rondas(1, r1, ahora)
        #expect(d2 == .mostrar)
    }

    @Test("Uno cada 2 rondas desde el último; el 5.º del día se bloquea")
    func maximoDiario() {
        let ahora = fecha(dia: 4, 10)
        var r = registro
        for i in 1...4 {
            let (r1, d1) = rondas(1, r, ahora)
            #expect(d1 == .no(.faltanRondas), "ronda impar \(i)")
            let (r2, d2) = rondas(1, r1, ahora)
            #expect(d2 == .mostrar, "anuncio \(i)")
            r = politica.anuncioMostrado(r2, ahora: ahora)
            #expect(r.rondasDesdeUltimo == 0 && politica.anunciosHoy(r, ahora: ahora) == i)
        }
        let (_, d5) = rondas(2, r, ahora)
        #expect(d5 == .no(.maximoDiario))
        let (_, d6) = rondas(6, r, fecha(dia: 4, 23, 59))
        #expect(d6 == .no(.maximoDiario))
    }

    @Test("El contador diario vuelve a cero a medianoche (día natural del dispositivo)")
    func medianoche() {
        var r = registro
        let noche = fecha(dia: 5, 23, 50)
        for _ in 0..<4 {
            r = rondas(2, r, noche).0
            r = politica.anuncioMostrado(r, ahora: noche)
        }
        #expect(rondas(2, r, noche).1 == .no(.maximoDiario))
        let madrugada = fecha(dia: 6, 0, 10)
        #expect(politica.anunciosHoy(r, ahora: madrugada) == 0)
        #expect(rondas(2, r, madrugada).1 == .mostrar)
        // En otra zona horaria, la medianoche es otra: es la del dispositivo.
        var tokio = Calendar(identifier: .gregorian)
        tokio.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        #expect(PoliticaAnuncios(calendario: tokio).anunciosHoy(r, ahora: noche) == 0)
    }

    @Test("Premium nunca ve anuncios ni le cuentan las rondas")
    func premium() {
        var entorno = todoListo
        entorno.premium = true
        let (r, d) = rondas(10, registro, fecha(dia: 10), entorno: entorno)
        #expect(d == .no(.premium) && r.rondasDesdeUltimo == 0)
        #expect(!politica.prepararConsentimiento(registro, premium: true, ahora: fecha(dia: 10)))
    }

    @Test("Solo al continuar tras una ronda: nunca en el Tribunal, al abrir, a mitad de ronda, en la bienvenida ni en el diagnóstico")
    func momentos() {
        var r = registro
        r.rondasDesdeUltimo = 5
        for m in [MomentoAnuncio.tribunal, .aperturaApp, .mitadRonda, .bienvenida, .diagnostico] {
            #expect(politica.decidir(m, registro: r, entorno: todoListo, ahora: fecha(dia: 3)) == .no(.momento), "\(m)")
        }
        #expect(politica.decidir(.continuarTrasRonda, registro: r, entorno: todoListo, ahora: fecha(dia: 3)) == .mostrar)
    }

    @Test("Sin conexión, sin consentimiento, con identificadores pendientes o sin cargar: ninguno")
    func condiciones() {
        var r = registro
        r.rondasDesdeUltimo = 2
        let ahora = fecha(dia: 3)
        var e = todoListo
        e.conectado = false
        #expect(politica.decidir(.continuarTrasRonda, registro: r, entorno: e, ahora: ahora) == .no(.sinConexion))
        e = todoListo
        e.consentimiento = false
        #expect(politica.decidir(.continuarTrasRonda, registro: r, entorno: e, ahora: ahora) == .no(.sinConsentimiento))
        e = todoListo
        e.identificadores = false
        #expect(politica.decidir(.continuarTrasRonda, registro: r, entorno: e, ahora: ahora) == .no(.identificadores))
        e = todoListo
        e.cargado = false
        #expect(politica.decidir(.continuarTrasRonda, registro: r, entorno: e, ahora: ahora) == .no(.noCargado))
    }
}

// MARK: - Servicio de anuncios con un proveedor falso

@MainActor
final class ProveedorFalso: ProveedorAnuncios {
    var cargado = false
    var puedePedirAnuncios = true
    var opcionesPrivacidadRequeridas = false
    /// Al cargar, ¿llega un anuncio?
    var hayInventario = true
    private(set) var llamadas: [String] = []
    private var cerrarAnuncio: (@MainActor () -> Void)?

    func actualizarConsentimiento(eee: Bool) async { llamadas.append("ump") }
    func pedirPermisoSeguimiento() async { llamadas.append("att") }
    func iniciar() async { llamadas.append("sdk") }
    func cargar(_ bloque: String) async {
        llamadas.append("cargar")
        cargado = hayInventario
    }
    func presentar(alCerrar: @escaping @MainActor () -> Void) -> Bool {
        guard cargado else { return false }
        cargado = false
        llamadas.append("presentar")
        cerrarAnuncio = alCerrar
        return true
    }
    func abrirOpcionesPrivacidad() async { llamadas.append("privacidad") }

    /// El usuario cierra el intersticial.
    func cerrar() {
        cerrarAnuncio?()
        cerrarAnuncio = nil
    }
}

final class ConexionFalsa: MonitorConexion, @unchecked Sendable {
    var conectado = true
}

final class RelojMovil: Reloj, @unchecked Sendable {
    var ahora: Date
    init(_ ahora: Date) { self.ahora = ahora }
}

@Suite("06 · Servicio de anuncios")
@MainActor
struct ServicioAnunciosTests {
    let reloj = RelojMovil(fecha())
    let proveedor = ProveedorFalso()
    let conexion = ConexionFalsa()
    let acceso = ServicioAcceso(almacen: AlmacenEnMemoria(), productos: [])

    func servicio() -> ServicioAnuncios {
        acceso.simulacion = false
        return ServicioAnuncios(acceso: acceso, proveedor: proveedor, almacen: AlmacenEnMemoria(), reloj: reloj, conexion: conexion,
                                identificadores: IdentificadoresAnuncios(app: "a", intersticial: "i", validos: true),
                                politica: PoliticaAnuncios(calendario: calendarioMadrid))
    }

    /// Termina una ronda y pulsa «Continuar»: devuelve si se ha seguido en el acto.
    func continuar(_ s: ServicioAnuncios, _ momento: MomentoAnuncio = .continuarTrasRonda) -> Bool {
        var seguido = false
        s.continuar(momento) { seguido = true }
        return seguido
    }

    @Test("Días 1 y 2: ni UMP ni SDK; desde el día 3, en orden UMP → ATT → SDK → precarga")
    func consentimientoDesdeElDiaTres() async {
        let s = servicio()
        await s.prepararEnInicio()
        reloj.ahora = fecha(dia: 1, 23)
        await s.prepararEnInicio()
        #expect(proveedor.llamadas.isEmpty)
        reloj.ahora = fecha(dia: 2, 9)
        await s.prepararEnInicio()
        #expect(proveedor.llamadas == ["ump", "att", "sdk", "cargar"])
        // Una sola vez por arranque.
        await s.prepararEnInicio()
        #expect(proveedor.llamadas.count == 4)
    }

    @Test("Si UMP no permite pedir anuncios: ni ATT, ni SDK, ni anuncios")
    func sinConsentimiento() async {
        let s = servicio()
        proveedor.puedePedirAnuncios = false
        reloj.ahora = fecha(dia: 3)
        await s.prepararEnInicio()
        #expect(proveedor.llamadas == ["ump"])
        for _ in 0..<4 { #expect(continuar(s)) }
        #expect(!proveedor.llamadas.contains("presentar"))
    }

    @Test("Premium: nada de UMP, SDK ni anuncios")
    func premium() async {
        let s = servicio()
        acceso.simulacion = true
        reloj.ahora = fecha(dia: 5)
        await s.prepararEnInicio()
        for _ in 0..<6 { #expect(continuar(s)) }
        #expect(proveedor.llamadas.isEmpty)
    }

    @Test("Un anuncio sin cargar no bloquea: se sigue en el acto y se vuelve a cargar")
    func sinCargarNoBloquea() async throws {
        let s = servicio()
        proveedor.hayInventario = false
        reloj.ahora = fecha(dia: 3)
        await s.prepararEnInicio()
        #expect(continuar(s) && continuar(s), "sin anuncio, se sigue sin esperar")
        try await Task.sleep(for: .milliseconds(50))
        #expect(proveedor.llamadas.filter { $0 == "cargar" }.count >= 2, "se reintenta la carga")
        // Cuando ya hay anuncio, sale en la siguiente ronda (las anteriores siguen contando).
        proveedor.hayInventario = true
        await s.precargar()
        #expect(!continuar(s), "con anuncio, se sigue al cerrarlo")
    }

    @Test("Con anuncio: se sigue al cerrarlo y se precarga el siguiente; el Tribunal nunca muestra")
    func conAnuncio() async throws {
        let s = servicio()
        reloj.ahora = fecha(dia: 3)
        await s.prepararEnInicio()
        for _ in 0..<6 { #expect(continuar(s, .tribunal)) }
        #expect(!proveedor.llamadas.contains("presentar"), "Tribunal: nunca")
        #expect(continuar(s))
        var seguido = false
        s.continuar(.continuarTrasRonda) { seguido = true }
        #expect(!seguido && proveedor.llamadas.last == "presentar")
        proveedor.cerrar()
        #expect(seguido)
        try await Task.sleep(for: .milliseconds(50))
        #expect(proveedor.llamadas.last == "cargar" && proveedor.cargado, "precarga tras el anuncio")
        #expect(s.registro.rondasDesdeUltimo == 0 && s.registro.anunciosDia == 1)
    }

    @Test("Sin conexión, ninguno")
    func sinConexion() async {
        let s = servicio()
        reloj.ahora = fecha(dia: 3)
        await s.prepararEnInicio()
        conexion.conectado = false
        for _ in 0..<4 { #expect(continuar(s)) }
        #expect(!proveedor.llamadas.contains("presentar"))
    }

    @Test("Identificadores pendientes (Release sin IDs reales): ni UMP ni anuncios")
    func identificadoresPendientes() async {
        acceso.simulacion = false
        let s = ServicioAnuncios(acceso: acceso, proveedor: proveedor, almacen: AlmacenEnMemoria(), reloj: reloj, conexion: conexion,
                                 identificadores: IdentificadoresAnuncios(app: "PENDIENTE", intersticial: "PENDIENTE", validos: false),
                                 politica: PoliticaAnuncios(calendario: calendarioMadrid))
        reloj.ahora = fecha(dia: 8)
        await s.prepararEnInicio()
        for _ in 0..<4 { #expect(continuar(s)) }
        #expect(proveedor.llamadas.isEmpty)
    }
}

// MARK: - Identificadores (§2.4)

@Suite("06 · Identificadores de AdMob")
struct IdentificadoresTests {
    @Test("Release: PENDIENTE, formatos raros, editores distintos o el editor de prueba de Google fallan en seguro")
    func validacion() {
        let prueba = "ca-app-pub-" + "3940256099942544"
        #expect(!IdentificadoresAnuncios.validosParaProduccion(app: "PENDIENTE", intersticial: "PENDIENTE"))
        #expect(!IdentificadoresAnuncios.validosParaProduccion(app: "", intersticial: ""))
        #expect(!IdentificadoresAnuncios.validosParaProduccion(app: prueba + "~1458002511", intersticial: prueba + "/4411468910"))
        #expect(!IdentificadoresAnuncios.validosParaProduccion(app: "ca-app-pub-1111111111111111~22", intersticial: "ca-app-pub-9999999999999999/33"))
        #expect(!IdentificadoresAnuncios.validosParaProduccion(app: "ca-app-pub-1111111111111111/22", intersticial: "ca-app-pub-1111111111111111/33"))
        #expect(IdentificadoresAnuncios.validosParaProduccion(app: "ca-app-pub-1111111111111111~2222222222", intersticial: "ca-app-pub-1111111111111111/3333333333"))
        #expect(IdentificadoresAnuncios.huella("3940256099942544") == IdentificadoresAnuncios.huellaEditorPrueba)
    }

    @Test("Debug usa siempre los IDs de prueba de Google para iOS")
    func debug() {
        let ids = IdentificadoresAnuncios.actuales()
        #expect(ids.app == "ca-app-pub-3940256099942544~1458002511" && ids.intersticial == "ca-app-pub-3940256099942544/4411468910" && ids.validos)
    }

    @Test("El xcconfig de Release vale PENDIENTE y nunca lleva IDs de prueba; el Info.plist los toma de ahí")
    func configuracion() throws {
        let release = try String(contentsOf: raizProyecto.appending(path: "Config/Anuncios-Release.xcconfig"), encoding: .utf8)
        #expect(release.contains("ADMOB_APP_ID = PENDIENTE") && release.contains("ADMOB_INTERSTICIAL_ID = PENDIENTE"))
        #expect(!release.contains("3940256099942544"))
        let plist = try String(contentsOf: raizProyecto.appending(path: "Educulter-Info.plist"), encoding: .utf8)
        #expect(plist.contains("<string>$(ADMOB_APP_ID)</string>") && plist.contains("<string>$(ADMOB_INTERSTICIAL_ID)</string>"))
        #expect(plist.contains("NSUserTrackingUsageDescription") && plist.components(separatedBy: "<key>SKAdNetworkIdentifier</key>").count - 1 == 50)
        #expect(plist.contains("Solo lo usamos para que los anuncios de la versión gratuita te resulten más útiles. Si dices que no, la app funciona exactamente igual."))
        // La app compilada (Debug) lleva el identificador de prueba de la app.
        #expect(Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String == "ca-app-pub-3940256099942544~1458002511")
    }
}

// MARK: - Tabla de acceso (§1.2, con la corrección de la dirección)

@Suite("06 · Tabla de acceso")
struct TablaAccesoTests {
    @Test("Cada función, permitida o bloqueada según la versión")
    func tabla() {
        let gratis: [FuncionApp: Acceso] = [
            .camino: .permitido, .sesionDiaria: .permitido, .rescate: .permitido, .juegos: .permitido, .teoria: .permitido, .glosario: .permitido,
            .sinAnuncios: .soloPremium,
            .tribunalMuestra: .permitido,
            // Corrección de la dirección: las convocatorias anteriores (también consultarlas) son Premium.
            .convocatoriasAnteriores: .soloPremium,
            .simulacros: .soloPremium, .modoExamen: .soloPremium, .correccion: .soloPremium, .informe: .soloPremium, .porBloques: .soloPremium,
            .supervivencia: .permitido,
        ]
        #expect(Set(gratis.keys) == Set(FuncionApp.allCases))
        for f in FuncionApp.allCases {
            #expect(TablaAcceso.acceso(f, premium: false) == gratis[f], "gratis: \(f)")
            #expect(TablaAcceso.acceso(f, premium: true) == .permitido, "Premium: \(f)")
        }
    }

    @Test("Supervivencia: 1 partida al día gratis; ilimitada con Premium")
    func supervivencia() {
        #expect(TablaAcceso.acceso(.supervivencia, premium: false, partidasSupervivenciaHoy: 0) == .permitido)
        #expect(TablaAcceso.acceso(.supervivencia, premium: false, partidasSupervivenciaHoy: 1) == .soloPremium)
        #expect(TablaAcceso.acceso(.supervivencia, premium: true, partidasSupervivenciaHoy: 50) == .permitido)
    }

    @Test("Del Tribunal, lo único gratis es la muestra SIM.DEMO.01")
    func tribunal() throws {
        let banco = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        for s in banco.tribunal.originales {
            #expect(TablaAcceso.acceso(s.entrada, premium: false) == (s.id == "SIM.DEMO.01" ? .permitido : .soloPremium), "\(s.id)")
            #expect(TablaAcceso.acceso(s.entrada, premium: true) == .permitido)
        }
        for e in banco.tribunal.examenes {
            #expect(TablaAcceso.acceso(.oficial(e.id), premium: false) == .soloPremium, "\(e.id)")
            #expect(TablaAcceso.acceso(.medio(e.id, area: "LEN"), premium: false) == .soloPremium)
            #expect(TablaAcceso.acceso(.oficial(e.id), premium: true) == .permitido)
        }
        #expect(TablaAcceso.acceso(.simulacro(semilla: 1), premium: false) == .soloPremium)
        #expect(banco.tribunal.examenes.count == 7)
    }

    @Test("El estado guardado funciona sin conexión y caduca a su hora")
    @MainActor
    func estadoGuardado() {
        let almacen = AlmacenEnMemoria()
        let fin = fecha(dia: 30)
        almacen.guardar(valor: EstadoPremium(producto: "x", caducidad: fin), "acceso.estado")
        let antes = ServicioAcceso(almacen: almacen, reloj: RelojFijo(ahora: fecha(dia: 29)), productos: ["x"])
        antes.simulacion = nil
        #expect(antes.premium && antes.acceso(.simulacros) == .permitido)
        let despues = ServicioAcceso(almacen: almacen, reloj: RelojFijo(ahora: fecha(dia: 31)), productos: ["x"])
        despues.simulacion = nil
        #expect(!despues.premium && despues.acceso(.simulacros) == .soloPremium && despues.acceso(.camino) == .permitido)
    }

    @Test("Textos de venta: precio y periodo de StoreKit, la prueba y qué pasa después")
    func textos() {
        let mensual = OfertaPremium(id: "m", nombre: "Premium mensual", precio: "9,99 €", periodo: "mes", diasPrueba: 7)
        #expect(mensual.condiciones == "Premium mensual: 7 días gratis. Después, 9,99 € al mes.")
        let anual = OfertaPremium(id: "a", nombre: "Premium anual", precio: "49,99 €", periodo: "año", diasPrueba: nil)
        #expect(anual.condiciones == "Premium anual: 49,99 € al año.")
        #expect(TextosPremium.renovacion == "Se renueva sola. Puedes cancelar cuando quieras en Ajustes > tu nombre > Suscripciones.")
        #expect(TextosPremium.incluye.count == 3)
        // Sin urgencias ni cuentas atrás.
        let todo = (TextosPremium.incluye + [TextosPremium.renovacion, TextosPremium.gratis]).joined(separator: " ").lowercased()
        for prohibido in ["solo hoy", "oferta", "últim", "quedan", "ahora o nunca"] { #expect(!todo.contains(prohibido), "\(prohibido)") }
        #expect(OfertaPremium.dias(.week, 1) == 7 && OfertaPremium.periodo(.year, 1) == "año" && OfertaPremium.periodo(.month, 3) == "3 meses")
    }
}

// MARK: - StoreKit (StoreKitTest y Educulter.storekit)

@Suite("06 · Servicio de acceso con StoreKitTest", .serialized)
@MainActor
struct ServicioAccesoStoreKitTests {
    /// Una sola sesión para toda la suite: al liberarse, una sesión deja la tienda como estaba, y
    /// eso podía borrar a destiempo la compra del test siguiente.
    nonisolated(unsafe) private static var compartida: SKTestSession?
    let sesion: SKTestSession

    init() async throws {
        if Self.compartida == nil { Self.compartida = try SKTestSession(contentsOf: try Self.copiaLocal()) }
        sesion = Self.compartida!
        sesion.resetToDefaultState()
        sesion.clearTransactions()
        sesion.disableDialogs = true
        // Limpiar también es asíncrono: se espera a que no quede ningún derecho de un test anterior.
        for _ in 0..<50 {
            var quedan = false
            for await _ in Transaction.currentEntitlements { quedan = true }
            if !quedan { break }
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Copia de `Educulter.storekit` dentro del contenedor del simulador: `storekitd` no puede leer
    /// la carpeta del proyecto (está en el Escritorio del Mac) y la sesión se quedaba esperando.
    static func copiaLocal() throws -> URL {
        let destino = FileManager.default.temporaryDirectory.appending(path: "Educulter.storekit")
        try? FileManager.default.removeItem(at: destino)
        try Data(contentsOf: raizProyecto.appending(path: "Educulter.storekit")).write(to: destino)
        return destino
    }

    /// La caducidad y el reembolso de `SKTestSession` llegan a StoreKit un instante después: se
    /// recalcula hasta que se cumple la condición (como mucho 10 s).
    func actualizarHasta(_ s: ServicioAcceso, _ condicion: () -> Bool) async throws {
        for _ in 0..<100 {
            await s.actualizar()
            if condicion() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    func servicio() -> ServicioAcceso {
        let s = ServicioAcceso(almacen: AlmacenEnMemoria())
        s.simulacion = nil
        return s
    }

    @Test("Productos: un grupo con mensual 9,99 € y anual 49,99 €, los dos con 7 días gratis")
    func productos() async throws {
        let productos = try await Product.products(for: ProductosPremium.todos)
        #expect(Set(productos.map(\.id)) == ["com.educulter.dev.premium.mensual", "com.educulter.dev.premium.anual"])
        let grupo = Set(productos.compactMap(\.subscription?.subscriptionGroupID))
        #expect(grupo.count == 1)
        let ofertas = await servicio().ofertas()
        #expect(ofertas.map(\.periodo) == ["mes", "año"])
        #expect(ofertas.allSatisfy { $0.diasPrueba == 7 })
        #expect(ofertas.map(\.precio).allSatisfy { $0.contains("9,99") && $0.contains("€") })
    }

    @Test("Comprar la mensual → Premium")
    func mensual() async throws {
        let s = servicio()
        await s.actualizar()
        #expect(!s.premium && s.acceso(.simulacros) == .soloPremium)
        _ = try await sesion.buyProduct(identifier: ProductosPremium.mensual)
        try await actualizarHasta(s) { s.premium }
        #expect(s.premium && s.estado.producto == ProductosPremium.mensual)
        #expect(s.acceso(.simulacros) == .permitido && s.acceso(.convocatoriasAnteriores) == .permitido && s.permitido(.sinAnuncios))
    }

    @Test("Anual con la prueba de 7 días → Premium (en prueba)")
    func anualConPrueba() async throws {
        let s = servicio()
        let t = try await sesion.buyProduct(identifier: ProductosPremium.anual)
        try await actualizarHasta(s) { s.premium }
        if #available(iOS 17.2, *) { #expect(t.offer?.type == .introductory && t.offer?.paymentMode == .freeTrial) }
        await s.actualizar()
        #expect(s.premium && s.estado.enPrueba && s.estado.producto == ProductosPremium.anual)
        // La prueba es una vez por grupo: ya no se ofrece.
        #expect(await s.ofertas().allSatisfy { $0.diasPrueba == nil })
    }

    @Test("Suscripción caducada → gratis")
    func caducada() async throws {
        let s = servicio()
        _ = try await sesion.buyProduct(identifier: ProductosPremium.mensual)
        try await actualizarHasta(s) { s.premium }
        #expect(s.premium)
        try sesion.expireSubscription(productIdentifier: ProductosPremium.mensual)
        try await actualizarHasta(s) { !s.premium }
        #expect(!s.premium && s.acceso(.simulacros) == .soloPremium, "Queda el derecho de \(s.estado.producto ?? "-") hasta \(String(describing: s.estado.caducidad))")
    }

    @Test("Reembolso → gratis")
    func reembolso() async throws {
        let s = servicio()
        let t = try await sesion.buyProduct(identifier: ProductosPremium.mensual)
        try await actualizarHasta(s) { s.premium }
        #expect(s.premium)
        try sesion.refundTransaction(identifier: UInt(t.id))
        try await actualizarHasta(s) { !s.premium }
        #expect(!s.premium && s.estado.producto == nil)
    }

    @Test("Restaurar compras: un servicio sin estado guardado recupera el Premium")
    func restaurar() async throws {
        _ = try await sesion.buyProduct(identifier: ProductosPremium.anual)
        let nuevo = servicio()
        #expect(!nuevo.premium)
        try await nuevo.restaurar()
        #expect(nuevo.premium)
    }

    @Test("Transaction.updates: una compra hecha fuera de la app llega al servicio que escucha")
    func actualizaciones() async throws {
        let s = servicio()
        s.empezar()
        defer { s.detener() }
        _ = try await sesion.buyProduct(identifier: ProductosPremium.mensual)
        for _ in 0..<50 where !s.premium { try await Task.sleep(for: .milliseconds(100)) }
        #expect(s.premium)
    }
}

// MARK: - Solo Debug (§1.6) y recuento (§0.5)

@Suite("06 · Interruptor de Debug y recuento precalculado")
struct DebugYRecuentoTests {
    /// Líneas de `archivo` que contienen `texto` y están fuera de un bloque `#if DEBUG` (o en su `#else`).
    static func fueraDeDebug(_ archivo: String, _ texto: String) throws -> [Int] {
        let lineas = try String(contentsOf: raizProyecto.appending(path: archivo), encoding: .utf8).components(separatedBy: "\n")
        var pila: [Bool] = []  // true = la rama actual solo existe en Debug
        var fuera: [Int] = []
        for (i, l) in lineas.enumerated() {
            let t = l.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("#if") { pila.append(t == "#if DEBUG"); continue }
            if t.hasPrefix("#else"), !pila.isEmpty { pila[pila.count - 1] = false; continue }
            if t.hasPrefix("#endif") { _ = pila.popLast(); continue }
            if l.contains(texto), !pila.contains(true) { fuera.append(i + 1) }
        }
        return fuera
    }

    @Test("En Release el interruptor de Premium simulado no existe: todo está dentro de #if DEBUG")
    func interruptorSoloDebug() throws {
        for (archivo, texto) in [("Educulter/Features/Progreso/PantallaProgreso.swift", "ajusteSimularPremium"),
                                 ("Educulter/Features/Progreso/PantallaProgreso.swift", "Desarrollador"),
                                 ("Educulter/Features/Progreso/PantallaProgreso.swift", "simulacion"),
                                 ("Educulter/Core/Compras/ServicioAcceso.swift", "simulacion"),
                                 ("Educulter/App/EntornoApp.swift", "simulacion"),
                                 ("Educulter/App/EntornoApp.swift", "simular("),
                                 ("Educulter/Core/Anuncios/ServicioAnuncios.swift", "func simular"),
                                 ("Educulter/Core/Anuncios/IdentificadoresAnuncios.swift", "3940256099942544")] {
            let fuera = try Self.fueraDeDebug(archivo, texto)
            #expect(fuera.isEmpty, "\(archivo): «\(texto)» fuera de #if DEBUG en las líneas \(fuera)")
        }
        // Y la regla del recorrido de bloques funciona: el `#else` de un `#if DEBUG` es de Release.
        #expect(try Self.fueraDeDebug("Educulter/Core/Anuncios/IdentificadoresAnuncios.swift", "bundle.object(forInfoDictionaryKey: claveApp)") == [35])
    }

    @Test("Content/recuento.json coincide con el recuento real de preguntas disponibles (REGENERAR_RECUENTO=1 lo reescribe)",
          .timeLimit(.minutes(30)))
    func recuento() throws {
        let banco = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        let real = RecuentoPrecalculado(version: banco.catalogo.version, recuento: ServicioSesion.preguntasDisponibles(banco: banco))
        let carpeta = raizProyecto.appending(path: "Educulter/Content")
        if ProcessInfo.processInfo.environment["REGENERAR_RECUENTO"] == "1" {
            try real.codificado().write(to: carpeta.appending(path: RecuentoPrecalculado.archivo))
        }
        let guardado = try #require(RecuentoPrecalculado.cargar(raiz: carpeta), "Falta Content/recuento.json")
        #expect(guardado == real, "recuento.json está desfasado: regenéralo con TEST_RUNNER_REGENERAR_RECUENTO=1")
        #expect(real.total > 10_000)
        if ProcessInfo.processInfo.environment["REGENERAR_RECUENTO"] != "1" {
            // La app lee la copia del bundle: es la misma.
            #expect(RecuentoPrecalculado.cargar() == guardado)
        }
    }
}

#endif
