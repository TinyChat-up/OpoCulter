import Foundation
import Testing
@testable import Educulter

@Suite("Contenido empaquetado")
struct ContenidoEmpaquetadoTests {
    let cargador: CargadorContenido

    init() throws {
        cargador = try CargadorContenido.desdeBundle()
    }

    @Test("El contenido del bundle se carga completo en Debug")
    func cargaCompleta() throws {
        let banco = try cargador.cargar(politica: .todos)
        #expect(banco.items.count == 10)
        #expect(banco.teoria.count == 2)
        #expect(banco.simulacros.count == 1)
        #expect(Set(banco.items.map(\.mecanica)) == Set(Mecanica.allCases), "Debe haber un ítem por mecánica")
        #expect(banco.catalogo.areas.map(\.id) == ["LEN", "MAT"])
        #expect(banco.catalogo.areas[0].bloques.count == 10)
        #expect(banco.catalogo.areas[1].bloques.count == 9)
    }

    /// Test obligatorio: protege el contenido real en el futuro.
    @Test("Todo el contenido del bundle pasa el validador")
    func todoElContenidoPasaElValidador() throws {
        let banco = try cargador.cargar(politica: .todos)
        let errores = ValidadorContenido(anioActual: 2026).validar(banco)
        #expect(errores.isEmpty, "Errores de validación:\n\(errores.map(\.description).joined(separator: "\n"))")
        // También con el año real, para que el test detecte el paso del tiempo.
        #expect(ValidadorContenido().validar(banco).isEmpty)
    }

    @Test("En Release (solo aprobados) no se carga ningún borrador")
    func releaseNoCargaBorradores() throws {
        let todos = try cargador.cargar(politica: .todos)
        #expect(!todos.items.isEmpty, "El bundle debe tener borradores para que el test tenga sentido")
        let release = try cargador.cargar(politica: .soloAprobados)
        #expect(release.items.allSatisfy { $0.validacion.estado == .aprobado })
        #expect(release.teoria.allSatisfy { $0.validacion.estado == .aprobado })
        #expect(release.simulacros.allSatisfy { $0.validacion.estado == .aprobado })
        // Hoy todo el contenido es borrador: en Release no se carga nada.
        #expect(release.items.isEmpty && release.teoria.isEmpty && release.simulacros.isEmpty)
        #expect(release.catalogo == todos.catalogo)
    }

    @Test("La política por defecto depende de la configuración de compilación")
    func politicaPorDefecto() {
        #if DEBUG
        #expect(PoliticaCarga.porDefecto == .todos)
        #else
        #expect(PoliticaCarga.porDefecto == .soloAprobados)
        #endif
    }

    @Test("Los ítems se codifican y decodifican sin pérdidas")
    func idaYVuelta() throws {
        let banco = try cargador.cargar(politica: .todos)
        let datos = try JSONEncoder().encode(banco.items)
        #expect(try JSONDecoder().decode([Item].self, from: datos) == banco.items)
        let teoria = try JSONDecoder().decode([TarjetaTeoria].self, from: JSONEncoder().encode(banco.teoria))
        #expect(teoria == banco.teoria)
        let sim = try JSONDecoder().decode([Simulacro].self, from: JSONEncoder().encode(banco.simulacros))
        #expect(sim == banco.simulacros)
    }

    @Test("Índices del banco")
    func indices() throws {
        let banco = try cargador.cargar(politica: .todos)
        #expect(banco.item(id: "LEN.SIN.SUJPRED.0001")?.mecanica == .segmentar)
        #expect(banco.item(id: "NO.EXISTE") == nil)
        #expect(banco.items(competencia: "LEN.ORT.TILDES").count == 2)
        #expect(banco.items(competencia: "LEN.ORT.TILDES", peldano: 4).map(\.id) == ["LEN.ORT.TILDES.0002"])
        #expect(banco.items(bloque: "LEN.LIT").count == 2)
        #expect(banco.items(bloque: "XXX.YYY").isEmpty)
        #expect(banco.teoria(competencia: "MAT.NUM.FRACSUM").count == 1)
        #expect(banco.catalogo.bloque(deCompetencia: "MAT.GEO.TRIANG")?.id == "MAT.GEO")
        #expect(Catalogo.area(de: "MAT.GEO.TRIANG") == "MAT")
        #expect(banco.catalogo.todasLasCompetencias.count == 9)
    }
}

@Suite("Cargador de contenido")
struct CargadorTests {
    static let catalogo = """
    { "version": 1, "areas": [ { "id": "LEN", "nombre": "Lengua", "bloques": [
      { "id": "LEN.SIN", "nombre": "Sintaxis", "prioridad": 3, "orden": 1,
        "competencias": [ { "id": "LEN.SIN.SUJPRED", "nombre": "Sujeto", "orden": 1 } ] } ] } ] }
    """

    static func itemJSON(_ id: String, estado: String) -> String {
        """
        { "id": "\(id)", "competencia": "LEN.SIN.SUJPRED", "peldano": 2, "dificultad": 1, "objetivo": "o",
          "mecanica": "verdaderoFalso", "enunciado": "e", "payload": { "afirmacion": "a", "esVerdadera": true },
          "explicacion": "x",
          "procedencia": { "tipo": "original", "licencia": "propia" },
          "validacion": { "estado": "\(estado)", "revisor": "R", "fecha": "2026-11-23" }, "version": 1 }
        """
    }

    @Test("Solo aprobados filtra borradores y revisados; todos los carga")
    func filtraPorEstado() throws {
        let raiz = try Fx.carpetaContenido([
            "catalogo.json": Self.catalogo,
            "items/LEN.SIN.json": "[\(Self.itemJSON("LEN.SIN.SUJPRED.0001", estado: "aprobado")), \(Self.itemJSON("LEN.SIN.SUJPRED.0002", estado: "borrador")), \(Self.itemJSON("LEN.SIN.SUJPRED.0003", estado: "revisado"))]",
            "items/notas.txt": "se ignora",
        ])
        let cargador = CargadorContenido(raiz: raiz)
        #expect(try cargador.cargar(politica: .soloAprobados).items.map(\.id) == ["LEN.SIN.SUJPRED.0001"])
        #expect(try cargador.cargar(politica: .todos).items.count == 3)
        // Campos opcionales ausentes: pistas y errores habituales quedan vacíos.
        let item = try #require(try cargador.cargar(politica: .todos).items.first)
        #expect(item.pistas.isEmpty && item.erroresHabituales.isEmpty && item.referencia == nil)
    }

    @Test("Errores de carga legibles")
    func erroresDeCarga() throws {
        let vacio = try Fx.carpetaContenido(["otro.json": "{}"])
        #expect(throws: ErrorCarga.self) { try CargadorContenido(raiz: vacio).cargar() }

        let roto = try Fx.carpetaContenido(["catalogo.json": Self.catalogo, "items/LEN.SIN.json": "[{ \"id\": 1 }]"])
        do {
            _ = try CargadorContenido(raiz: roto).cargar()
            Issue.record("Debería haber fallado")
        } catch let error as ErrorCarga {
            guard case .jsonInvalido(let archivo, _) = error else { Issue.record("Error inesperado \(error)"); return }
            #expect(archivo == "items/LEN.SIN.json")
            #expect(error.description.contains("items/LEN.SIN.json"))
        }

        let mecanica = Self.itemJSON("LEN.SIN.SUJPRED.0001", estado: "borrador").replacingOccurrences(of: "verdaderoFalso", with: "dibujar")
        let desconocida = try Fx.carpetaContenido(["catalogo.json": Self.catalogo, "items/LEN.SIN.json": "[\(mecanica)]"])
        #expect(throws: ErrorCarga.self) { try CargadorContenido(raiz: desconocida).cargar() }

        #expect(throws: ErrorCarga.self) { try CargadorContenido.desdeBundle(Bundle(for: MarcadorBundle.self)) }
        #expect(ErrorCarga.carpetaNoEncontrada("x").description.contains("x"))
        #expect(ErrorCarga.archivoNoEncontrado("y").description.contains("y"))
    }

    @Test("Descripción de errores de decodificación")
    func describirErrores() {
        struct S: Decodable { var a: Int; var b: [String] }
        func mensaje(_ json: String) -> String {
            let r = Result { try JSONDecoder().decode(S.self, from: Data(json.utf8)) }
            if case .failure(let e) = r { return CargadorContenido.describir(e) }
            return ""
        }
        #expect(mensaje("{\"b\": []}").contains("falta la clave «a»"))
        #expect(mensaje("{\"a\": \"x\", \"b\": []}").contains("tipo incorrecto"))
        #expect(mensaje("{\"a\": null, \"b\": []}").contains("valor nulo"))
        #expect(mensaje("{").contains("datos no válidos"))
        #expect(CargadorContenido.describir(ErrorCarga.archivoNoEncontrado("z")).contains("z"))
    }
}

/// Clase auxiliar para obtener el bundle de tests (que no contiene la carpeta Content).
private final class MarcadorBundle {}
