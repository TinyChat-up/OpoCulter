import Foundation

/// Qué elementos del banco se cargan según su estado de validación.
enum PoliticaCarga: Sendable, Equatable {
    /// Todos los elementos, sea cual sea su estado (Debug).
    case todos
    /// Solo los elementos con `validacion.estado == "aprobado"` (Release).
    case soloAprobados

    /// Política de la configuración de compilación actual: `todos` en Debug y
    /// `soloAprobados` en Release.
    static var porDefecto: PoliticaCarga {
        #if DEBUG
        .todos
        #else
        .soloAprobados
        #endif
    }

    func admite(_ validacion: Validacion) -> Bool {
        switch self {
        case .todos: true
        case .soloAprobados: validacion.estado == .aprobado
        }
    }
}

enum ErrorCarga: Error, Equatable, CustomStringConvertible {
    case carpetaNoEncontrada(String)
    case archivoNoEncontrado(String)
    case jsonInvalido(archivo: String, detalle: String)

    var description: String {
        switch self {
        case .carpetaNoEncontrada(let ruta): "No se encuentra la carpeta de contenido: \(ruta)"
        case .archivoNoEncontrado(let ruta): "No se encuentra el archivo: \(ruta)"
        case .jsonInvalido(let archivo, let detalle): "JSON no válido en \(archivo): \(detalle)"
        }
    }
}

/// Carga el contenido JSON desde una carpeta con esta estructura:
/// ```
/// catalogo.json
/// items/<bloque>.json        (array de ítems)
/// teoria/<bloque>.json       (array de tarjetas)
/// simulacros/<id>.json       (un simulacro por archivo)
/// ```
struct CargadorContenido: Sendable {
    /// Nombre de la carpeta de contenido dentro del bundle de la app.
    static let carpetaEnBundle = "Content"

    let raiz: URL

    init(raiz: URL) {
        self.raiz = raiz
    }

    /// Cargador que lee la carpeta `Content` empaquetada en el bundle.
    static func desdeBundle(_ bundle: Bundle = .main) throws -> CargadorContenido {
        guard let url = bundle.url(forResource: carpetaEnBundle, withExtension: nil) else {
            throw ErrorCarga.carpetaNoEncontrada("\(bundle.bundlePath)/\(carpetaEnBundle)")
        }
        return CargadorContenido(raiz: url)
    }

    /// Carga el banco aplicando la política indicada (por defecto, la de la configuración).
    func cargar(politica: PoliticaCarga = .porDefecto) throws -> BancoContenido {
        let catalogo: Catalogo = try decodificar(raiz.appendingPathComponent("catalogo.json"))
        let items: [Item] = try archivosJSON(en: "items").flatMap { try decodificar($0) as [Item] }
        let teoria: [TarjetaTeoria] = try archivosJSON(en: "teoria").flatMap { try decodificar($0) as [TarjetaTeoria] }
        let simulacros: [Simulacro] = try archivosJSON(en: "simulacros").map { try decodificar($0) }

        return BancoContenido(
            catalogo: catalogo,
            items: items.filter { politica.admite($0.validacion) },
            teoria: teoria.filter { politica.admite($0.validacion) },
            simulacros: simulacros.filter { politica.admite($0.validacion) }
        )
    }

    /// Archivos `.json` de una subcarpeta, ordenados por nombre. Si no existe, lista vacía.
    private func archivosJSON(en subcarpeta: String) throws -> [URL] {
        let carpeta = raiz.appendingPathComponent(subcarpeta, isDirectory: true)
        guard FileManager.default.fileExists(atPath: carpeta.path) else { return [] }
        return try FileManager.default
            .contentsOfDirectory(at: carpeta, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func decodificar<T: Decodable>(_ url: URL) throws -> T {
        let nombre = url.pathComponents.suffix(2).joined(separator: "/")
        guard let datos = FileManager.default.contents(atPath: url.path) else {
            throw ErrorCarga.archivoNoEncontrado(nombre)
        }
        do {
            return try JSONDecoder().decode(T.self, from: datos)
        } catch {
            throw ErrorCarga.jsonInvalido(archivo: nombre, detalle: Self.describir(error))
        }
    }

    /// Mensaje legible de un error de decodificación, con la ruta del campo.
    static func describir(_ error: Error) -> String {
        guard let e = error as? DecodingError else { return "\(error)" }
        func ruta(_ c: [CodingKey]) -> String {
            c.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
        }
        switch e {
        case .keyNotFound(let clave, let ctx): return "falta la clave «\(clave.stringValue)» en \(ruta(ctx.codingPath))"
        case .typeMismatch(_, let ctx): return "tipo incorrecto en \(ruta(ctx.codingPath)): \(ctx.debugDescription)"
        case .valueNotFound(_, let ctx): return "valor nulo en \(ruta(ctx.codingPath))"
        case .dataCorrupted(let ctx): return "datos no válidos en \(ruta(ctx.codingPath)): \(ctx.debugDescription)"
        @unknown default: return "\(e)"
        }
    }
}
