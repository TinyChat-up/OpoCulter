import Foundation
import Observation
import StoreKit

/// Servicio único de acceso (fase 06 §1.3): sustituye a `AccesoTribunal` y es lo único que consulta
/// StoreKit. Ninguna vista lee StoreKit: todas preguntan aquí.
///
/// - Fuente de verdad: `Transaction.currentEntitlements` verificadas de los productos Premium.
/// - Escucha `Transaction.updates` desde el arranque (compras en otro dispositivo, renovaciones,
///   reembolsos y revocaciones).
/// - Guarda el último estado conocido para funcionar sin conexión (y para no ver la app bloqueada
///   un instante al abrirla).
/// - Un reembolso o una revocación (`revocationDate`) quitan el acceso.
/// - En Release nadie recibe Premium gratis (D-137 sustituida). Solo en Debug se puede simular
///   sí/no desde Ajustes.
@MainActor
@Observable
final class ServicioAcceso {
    private static let claveEstado = "acceso.estado"
    #if DEBUG
    private static let claveSimulacion = "acceso.simulacion"
    #endif

    private(set) var estado: EstadoPremium
    @ObservationIgnored private let almacen: any AlmacenClaves
    @ObservationIgnored private let reloj: any Reloj
    @ObservationIgnored private let productos: [String]
    @ObservationIgnored private var escucha: Task<Void, Never>?

    #if DEBUG
    /// Solo Debug: `true`/`false` fuerza el Premium; `nil` usa StoreKit (el archivo
    /// `Educulter.storekit` del esquema).
    var simulacion: Bool? {
        didSet { almacen.guardar(valor: simulacion, Self.claveSimulacion) }
    }
    #endif

    init(almacen: any AlmacenClaves, reloj: any Reloj = RelojSistema(), productos: [String] = ProductosPremium.todos) {
        self.almacen = almacen
        self.reloj = reloj
        self.productos = productos
        estado = almacen.valor(EstadoPremium.self, Self.claveEstado) ?? .gratis
        #if DEBUG
        simulacion = almacen.valor(Bool.self, Self.claveSimulacion)
        #endif
    }

    /// ¿Hay Premium ahora?
    var premium: Bool {
        #if DEBUG
        if let simulacion { return simulacion }
        #endif
        return estado.activo(reloj.ahora)
    }

    // MARK: Preguntas de las vistas

    func acceso(_ funcion: FuncionApp, partidasSupervivenciaHoy: Int = 0) -> Acceso {
        TablaAcceso.acceso(funcion, premium: premium, partidasSupervivenciaHoy: partidasSupervivenciaHoy)
    }

    func acceso(_ entrada: CatalogoTribunal.Entrada) -> Acceso { TablaAcceso.acceso(entrada, premium: premium) }
    func acceso(_ modo: SesionExamen.Modo) -> Acceso { TablaAcceso.acceso(modo, premium: premium) }
    func permitido(_ funcion: FuncionApp) -> Bool { acceso(funcion) == .permitido }

    // MARK: StoreKit

    /// Empieza a escuchar `Transaction.updates` (una vez) y lee los derechos actuales.
    func empezar() {
        guard escucha == nil else { return }
        escucha = Task { [weak self] in
            for await resultado in Transaction.updates {
                if case .verified(let t) = resultado { await t.finish() }
                await self?.actualizar()
            }
        }
        Task { await actualizar() }
    }

    func detener() {
        escucha?.cancel()
        escucha = nil
    }

    /// Recalcula el estado con los derechos verificados vigentes y lo guarda.
    func actualizar() async {
        var nuevo = EstadoPremium.gratis
        for await resultado in Transaction.currentEntitlements {
            guard case .verified(let t) = resultado else { continue }
            aplicar(t, a: &nuevo)
        }
        nuevo.actualizado = reloj.ahora
        guardar(nuevo)
    }

    /// Después de una compra (la hoja de StoreKit ya la ha completado): se acaba la transacción y
    /// se recalcula.
    func registrar(_ resultado: VerificationResult<Transaction>) async {
        if case .verified(let t) = resultado { await t.finish() }
        await actualizar()
    }

    /// «Restaurar compras»: sincroniza con el App Store y recalcula.
    func restaurar() async throws {
        try await AppStore.sync()
        await actualizar()
    }

    /// Precio, periodo y prueba gratuita de cada plan, leídos de StoreKit (nunca escritos a mano).
    /// La prueba solo aparece si el usuario aún tiene derecho a ella (una vez por grupo).
    func ofertas() async -> [OfertaPremium] {
        guard let productos = try? await Product.products(for: productos) else { return [] }
        var out: [OfertaPremium] = []
        for p in productos.sorted(by: { $0.price < $1.price }) {
            guard let s = p.subscription, let periodo = OfertaPremium.periodo(s.subscriptionPeriod.unit, s.subscriptionPeriod.value) else { continue }
            var dias: Int?
            if let o = s.introductoryOffer, o.paymentMode == .freeTrial, await s.isEligibleForIntroOffer {
                dias = OfertaPremium.dias(o.period.unit, o.period.value)
            }
            out.append(OfertaPremium(id: p.id, nombre: p.displayName, precio: p.displayPrice, periodo: periodo, diasPrueba: dias))
        }
        return out
    }

    /// Un derecho cuenta si es de un producto Premium, no está revocado (reembolso) y no ha caducado.
    private func aplicar(_ t: Transaction, a estado: inout EstadoPremium) {
        guard productos.contains(t.productID), t.revocationDate == nil else { return }
        if let fin = t.expirationDate, fin <= reloj.ahora { return }
        // Con dos derechos (cambio de plan), el que dura más.
        if estado.producto == nil || (t.expirationDate ?? .distantFuture) > (estado.caducidad ?? .distantPast) {
            estado.producto = t.productID
            estado.caducidad = t.expirationDate
            if #available(iOS 17.2, *) {
                estado.enPrueba = t.offer?.type == .introductory
            } else {
                estado.enPrueba = t.offerType == .introductory
            }
        }
    }

    private func guardar(_ nuevo: EstadoPremium) {
        estado = nuevo
        almacen.guardar(valor: nuevo, Self.claveEstado)
    }
}
