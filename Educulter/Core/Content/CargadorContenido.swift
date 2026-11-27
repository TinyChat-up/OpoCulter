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
/// plantillas/<bloque>.json   (array de plantillas de generador, Fase 05C)
/// lexico/palabras.json       (léxico de los generadores de Lengua)
/// lexico/formas_verbales.json (formas verbales del léxico, para su nivel)
/// gramatica/piezas.json · verbos.json · frases.json · compatibilidad.json
/// textos/<archivo>.json      (array de textos base de comprensión, D-085)
/// literatura/literatura.json (base literaria del lote 05a, D-078)
/// ambiguas.json              (formas que solo se distinguen por la tilde, 05E §4.1)
/// errores.json               (errores típicos y su detección en los distractores, 05E parte 2 §4)
/// ```
/// `pendiente/` (contenido aprobado que el motor aún no muestra, p. ej. el Tribunal) no se lee.
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
    /// `semillaBase` fija las variantes materializadas de las plantillas.
    func cargar(politica: PoliticaCarga = .porDefecto, semillaBase: UInt64 = 1) throws -> BancoContenido {
        let catalogo: Catalogo = try decodificar(raiz.appendingPathComponent("catalogo.json"))
        let items: [Item] = try archivosJSON(en: "items").flatMap { try decodificar($0) as [Item] }
        let teoria: [TarjetaTeoria] = try archivosJSON(en: "teoria").flatMap { try decodificar($0) as [TarjetaTeoria] }
        let simulacros: [Simulacro] = try archivosJSON(en: "simulacros").map { try decodificar($0) }
        let plantillas: [Plantilla] = try archivosJSON(en: "plantillas").flatMap { try decodificar($0) as [Plantilla] }
        let textos: [TextoBase] = try archivosJSON(en: "textos").flatMap { try decodificar($0) as [TextoBase] }
        let literaturaURL = raiz.appendingPathComponent("literatura/literatura.json")
        var literatura: BaseLiteraria?
        if FileManager.default.fileExists(atPath: literaturaURL.path) { literatura = try decodificar(literaturaURL) as BaseLiteraria }
        // Preguntas oficiales por competencia (equivalencias del Tribunal, D-097): ordenan el plan (D-103).
        struct Equivalencias: Decodable { var preguntas: [EquivalenciaOficial] }
        let equivalenciasURL = raiz.appendingPathComponent("tribunal/equivalencias.json")
        var preguntasOficiales: [String: Int] = [:]
        var tribunal = DatosTribunal()
        if FileManager.default.fileExists(atPath: equivalenciasURL.path) {
            tribunal.equivalencias = (try decodificar(equivalenciasURL) as Equivalencias).preguntas
            for p in tribunal.equivalencias { preguntasOficiales[p.competencia, default: 0] += 1 }
        }
        // Exámenes oficiales del Tribunal (05I): `tribunal/<año>_<convocatoria>.json` y las reglas.
        tribunal.examenes = try archivosJSON(en: "tribunal").filter { $0.lastPathComponent.first?.isNumber == true }
            .map { try decodificar($0) as ExamenOficial }.filter { politica.admite($0.validacion) }
        let reglasURL = raiz.appendingPathComponent("tribunal/reglas.json")
        if FileManager.default.fileExists(atPath: reglasURL.path) { tribunal.reglas = try decodificar(reglasURL) }

        let recursos = try recursos()
        // Los distractores de los ítems estáticos también se etiquetan con su error típico (generador «estatico»).
        let etiquetados = items.filter { politica.admite($0.validacion) }.map { i in
            var i = i
            i.erroresHabituales = recursos.errores.etiquetar(i.erroresHabituales, competencia: i.competencia, generador: "estatico")
            return i
        }
        return BancoContenido(
            catalogo: catalogo,
            items: etiquetados,
            teoria: teoria.filter { politica.admite($0.validacion) },
            simulacros: simulacros.filter { politica.admite($0.validacion) },
            plantillas: plantillas.filter { politica.admite($0.validacion) },
            recursos: recursos,
            textos: textos.filter { politica.admite($0.validacion) },
            literatura: literatura,
            preguntasOficiales: preguntasOficiales,
            tribunal: tribunal,
            semillaBase: semillaBase
        )
    }

    /// Recursos de los generadores (opcionales: si falta un archivo, ese recurso queda vacío).
    func recursos() throws -> RecursosGeneradores {
        func opcional<T: Decodable>(_ ruta: String) throws -> T? {
            let url = raiz.appendingPathComponent(ruta)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return try decodificar(url) as T
        }
        return RecursosGeneradores(
            lexico: try opcional("lexico/palabras.json") ?? [],
            formasVerbales: try opcional("lexico/formas_verbales.json") ?? [],
            gramatica: try opcional("gramatica/piezas.json") ?? PiezasGramatica(),
            verbos: try opcional("gramatica/verbos.json") ?? BancoVerbos(),
            frases: try opcional("gramatica/frases.json") ?? BancoFrases(),
            compatibilidad: try opcional("gramatica/compatibilidad.json") ?? CompatibilidadGramatica(),
            ambiguas: try opcional("ambiguas.json") ?? PalabrasAmbiguas(),
            literatura: try opcional("literatura/literatura.json"),
            errores: try opcional("errores.json") ?? CatalogoErrores(),
            resumen: try opcional("resumen.json"),
            textosBase: try archivosJSON(en: "textos").flatMap { try decodificar($0) as [TextoBase] },
            formacion: try opcional("formacion.json"),
            recursosLiterarios: try opcional("recursos.json"),
            glosario: try opcional("glosario.json")
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
