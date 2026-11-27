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
        // 25 borradores de prueba + LEN.ORT (50 ítems y 5 tarjetas) + MAT.NUM (9 ítems y 2 tarjetas)
        // + lote 03a: LEN.LEX (30 ítems y 4 tarjetas) y LEN.COM (19 ítems y 4 tarjetas).
        // + 05G: LEN.COM.INFER.0004 (evidencia) y MAT.GEO.AREA.0001 (figura, borrador).
        #expect(banco.numeroEstaticos == 135)
        // Fase 05C: 8 plantillas de prueba (borrador) que siguen + 38 del lote 02 + 4 del lote 02b.
        // + 05G: 3 pasos de J46 y 6 niveles de J63.
        // + 05H: 24 de Editor, Fábrica, recursos y glosario.
        // + 05I: 3 de redactar con el patrón recuerdo (simulacros). + 05J: LEN.ORT.CTX.G01 (lote 06).
        #expect(banco.plantillas.count == 125)
        #expect(banco.items.count > 133)
        #expect(banco.teoria.count == 62, "17 + las 9 del ANEXO B (05E parte 2) + las 36 del lote 06")
        #expect(banco.textos.count == 7 && banco.literatura?.autores.count == 142)
        #expect(banco.simulacros.count == 1)
        #expect(Set(banco.items.map(\.mecanica)) == Set(Mecanica.allCases), "Debe haber ítems de todas las mecánicas")
        for m in Mecanica.allCases { #expect(banco.items.filter { $0.mecanica == m }.count >= 3, "Al menos 3 ítems de \(m)") }
        #expect(banco.catalogo.areas.map(\.id) == ["LEN", "MAT"])
        // Mapa curricular de la A1 (Fase 05E): 11 bloques de Lengua (con LEN.HAB) y 10 de Matemáticas (con MAT.ALG).
        #expect(banco.catalogo.areas[0].bloques.count == 11)
        #expect(banco.catalogo.areas[1].bloques.count == 10)
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
        #expect(release.plantillas.allSatisfy { $0.validacion.estado == .aprobado } && release.plantillas.count == 120)
        #expect(release.teoria.allSatisfy { $0.validacion.estado == .aprobado })
        #expect(release.simulacros.allSatisfy { $0.validacion.estado == .aprobado })
        // Aprobado: LEN.ORT (50 ítems y 5 tarjetas), MAT.NUM (9 y 2), LEN.LEX (30 y 4) y LEN.COM (19 y 4,
        // lote 03a; + LEN.COM.INFER.0004 en la 05G); ningún borrador. Lote 02: además, variantes de las plantillas aprobadas.
        #expect(release.itemsEstaticos.count == 109)
        #expect(release.itemsEstaticos.filter { $0.competencia.hasPrefix("LEN.ORT.") }.count == 50)
        #expect(release.itemsEstaticos.filter { $0.competencia.hasPrefix("MAT.NUM.") }.count == 9)
        #expect(release.itemsEstaticos.filter { $0.competencia.hasPrefix("LEN.LEX.") }.count == 30)
        #expect(release.itemsEstaticos.filter { $0.competencia.hasPrefix("LEN.COM.") }.count == 20)
        #expect(release.items.count > 108)
        #expect(release.teoria.filter { $0.competencia.hasPrefix("LEN.ORT.") }.count == 5)
        #expect(release.teoria.filter { $0.competencia.hasPrefix("MAT.NUM.") }.count == 5)
        #expect(release.teoria.filter { $0.competencia.hasPrefix("LEN.LEX.") }.count == 8)
        #expect(release.teoria.filter { $0.competencia.hasPrefix("LEN.COM.") }.count == 7)
        #expect(release.teoria.count == 60, "15 + las 9 del ANEXO B (05E parte 2) + las 36 del lote 06")
        #expect(release.textos.count == 7)
        #expect(release.items.allSatisfy { $0.validacion.revisor == "direccion" })
        #expect(release.simulacros.isEmpty)
        #expect(todos.items.contains { $0.validacion.estado == .borrador })
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
        // Índices sobre los ítems estáticos (las variantes generadas se prueban en GeneradoresTests).
        let completo = try cargador.cargar(politica: .todos)
        let banco = BancoContenido(catalogo: completo.catalogo, items: Array(completo.itemsEstaticos), teoria: completo.teoria)
        #expect(banco.item(id: "LEN.SIN.SUJPRED.0001")?.mecanica == .rayosX, "Migrado a Rayos X (05H)")
        #expect(banco.item(id: "NO.EXISTE") == nil)
        #expect(banco.items(competencia: "LEN.ORT.AGU").count == 21)
        #expect(banco.items(competencia: "LEN.ORT.AGU", peldano: 4).map(\.id) == ["LEN.ORT.AGU.0008", "LEN.ORT.AGU.0009"])
        #expect(banco.items(bloque: "LEN.ORT").count == 50)
        #expect(banco.items(bloque: "MAT.NUM").count == 9)
        #expect(banco.items(bloque: "LEN.LIT").count == 2)
        #expect(banco.items(bloque: "XXX.YYY").isEmpty)
        #expect(banco.teoria(competencia: "MAT.OPE.FRACSUM").count == 1)
        #expect(banco.catalogo.bloque(deCompetencia: "MAT.GEO.TRIANG")?.id == "MAT.GEO")
        #expect(Catalogo.area(de: "MAT.GEO.TRIANG") == "MAT")
        // 24 + MAT.OPE.ECUAC, MAT.EST.CENTRAL y MAT.PRO.LAPLACE (Fase 05C) + 16 del lote 02 + 15 del lote 03a.
        #expect(banco.catalogo.todasLasCompetencias.count == 126, "58 anteriores + las del mapa de la A1 + MAT.OPE.INCOG (Fase 05E) + LEN.ORT.CTX (05J)")
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
