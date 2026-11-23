import Foundation
import Observation
import SwiftData

/// Opciones de arranque. **Solo se aplican en Debug** (tests de UI, capturas y revisión).
struct OpcionesArranque: Equatable {
    /// Progreso en memoria (no toca el almacén real).
    var enMemoria = false
    /// Semilla fija para la aleatoriedad (rondas reproducibles).
    var semilla: UInt64?
    /// Muestra el botón "Rellenar (pruebas)" en las rondas.
    var ayudasDePrueba = false
    /// "Empezar ronda" lanza una ronda con un ítem de cada mecánica.
    var rondaDemostracion = false
    /// Escena que se abre directamente para generar capturas.
    var captura: String?

    static func desde(_ argumentos: [String]) -> OpcionesArranque {
        #if DEBUG
        var o = OpcionesArranque()
        o.enMemoria = argumentos.contains("-enMemoria")
        o.ayudasDePrueba = argumentos.contains("-ayudasDePrueba")
        o.rondaDemostracion = argumentos.contains("-rondaDemostracion")
        if let i = argumentos.firstIndex(of: "-semilla"), i + 1 < argumentos.count { o.semilla = UInt64(argumentos[i + 1]) }
        if let i = argumentos.firstIndex(of: "-captura"), i + 1 < argumentos.count { o.captura = argumentos[i + 1] }
        return o
        #else
        return OpcionesArranque()
        #endif
    }
}

/// Composición raíz: carga el contenido, crea la persistencia y el servicio de sesión.
@MainActor
@Observable
final class EntornoApp {
    let opciones: OpcionesArranque
    let servicio: ServicioSesion?
    let errorCarga: String?

    var banco: BancoContenido? { servicio?.banco }

    init(opciones: OpcionesArranque, servicio: ServicioSesion?, errorCarga: String?) {
        self.opciones = opciones
        self.servicio = servicio
        self.errorCarga = errorCarga
    }

    static func crear(argumentos: [String] = ProcessInfo.processInfo.arguments) -> EntornoApp {
        let opciones = OpcionesArranque.desde(argumentos)
        do {
            let banco = try CargadorContenido.desdeBundle().cargar()
            let repositorio: any RepositorioProgreso
            if opciones.enMemoria {
                repositorio = RepositorioEnMemoria()
            } else {
                repositorio = RepositorioSwiftData(contenedor: try EsquemaProgreso.contenedor())
            }
            let rng = opciones.semilla.map(GeneradorConSemilla.init(semilla:)) ?? .aleatorio()
            let servicio = ServicioSesion(banco: banco, repositorio: repositorio, rng: rng)
            return EntornoApp(opciones: opciones, servicio: servicio, errorCarga: nil)
        } catch {
            return EntornoApp(opciones: opciones, servicio: nil, errorCarga: "\(error)")
        }
    }

    /// Ronda que lanza el botón principal de Hoy.
    var tipoRondaPrincipal: TipoRonda {
        guard opciones.rondaDemostracion, let banco else { return .recomendada }
        return .items(Self.itemsDemostracion(banco))
    }

    /// Ítem fijo de demostración por mecánica (estable para tests de UI y capturas).
    static let demostracionPreferida: [Mecanica: String] = [
        .eleccion: "LEN.REC.FIGURAS.0001", .verdaderoFalso: "LEN.CLA.SUSTADJ.0002", .clasificar: "LEN.CLA.SUSTADJ.0001",
        .ordenar: "LEN.LIT.CRONO.0001", .emparejar: "LEN.LEX.SINON.0001", .marcarTexto: "LEN.CLA.VERBO.0001",
        .segmentar: "LEN.SIN.COMPL.0001", .ruedas: "LEN.VER.ANALISIS.0001", .construir: "LEN.ORT.AGU.0008",
        .numerico: "MAT.NUM.FRACSUM.0001",
    ]

    /// Un ítem por mecánica, en el orden del catálogo de mecánicas: el preferido si existe y, si no,
    /// el primero de esa mecánica.
    static func itemsDemostracion(_ banco: BancoContenido) -> [String] {
        Mecanica.allCases.compactMap { m in
            if let id = demostracionPreferida[m], banco.item(id: id)?.mecanica == m { return id }
            return banco.items.first { $0.mecanica == m && $0.peldano <= 4 }?.id
        }
    }

    /// Servicio aislado (en memoria) para revisar contenido sin alterar el progreso real.
    func servicioDeRevision() -> ServicioSesion? {
        banco.map { ServicioSesion(banco: $0, repositorio: RepositorioEnMemoria(), rng: GeneradorConSemilla(semilla: 1)) }
    }
}
