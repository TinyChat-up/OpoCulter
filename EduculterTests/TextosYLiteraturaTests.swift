import Foundation
import Testing
@testable import Educulter

// Recuperación (25/11/2026): textos base de comprensión (lote 03a, D-085) y base literaria
// (lote 05a, D-078 y D-079).

private let bancoTextos = try! CargadorContenido.desdeBundle().cargar(politica: .todos)
private let validadorTextos = ValidadorContenido(anioActual: 2026)

@Suite("Textos base de comprensión")
struct TextosBaseTests {
    @Test("Se cargan los 7 textos base con su procedencia, también en Release")
    func carga() throws {
        #expect(bancoTextos.textos.map(\.id).sorted() == ["TXT.BEC.R21", "TXT.MAC.CAM", "TXT.ORI.ABEJAS", "TXT.ORI.BICI", "TXT.ORI.DEBERES", "TXT.ORI.FARO", "TXT.ORI.SUENO"])
        for t in bancoTextos.textos {
            #expect(!t.titulo.isEmpty && !t.texto.isEmpty, "\(t.id)")
            #expect(validadorTextos.validar(texto: t).isEmpty, "\(validadorTextos.validar(texto: t))")
            switch t.procedencia.tipo {
            case .dominioPublico:
                let anio = try #require(t.procedencia.anioMuerteAutor, "\(t.id) sin año de muerte")
                #expect(2026 - anio > 80, "\(t.id): murió en \(anio)")
                #expect(t.esLiterario && t.autor == t.procedencia.autorTexto)
            case .original:
                #expect(!t.esLiterario && t.procedencia.licencia == "propia")
            }
        }
        let release = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        #expect(release.textos.count == 7, "Los 7 textos están aprobados (SUENO y BICI, de la 05G)")
    }

    @Test("Cada ítem de comprensión con textoRef lo resuelve, también con la política de Release")
    func referencias() throws {
        let comprension = bancoTextos.itemsEstaticos.filter { $0.competencia.hasPrefix("LEN.COM.") }
        #expect(comprension.count == 20)
        let conTexto = comprension.filter { $0.textoRef != nil }
        #expect(conTexto.count == 13, "Los 7 restantes son conceptuales o llevan el texto en fragmentos (evidencia)")
        for item in conTexto { #expect(bancoTextos.texto(de: item) != nil, "\(item.id) → \(item.textoRef ?? "")") }
        // Todos los textos los usa algún ítem o la actividad J46 (05G).
        let deJ46 = Set(bancoTextos.recursos.resumen?.textos.map(\.texto) ?? [])
        #expect(Set(conTexto.compactMap(\.textoRef)).union(deJ46) == Set(bancoTextos.textos.map(\.id)))
        let release = try CargadorContenido.desdeBundle().cargar(politica: .soloAprobados)
        for item in release.itemsEstaticos where item.textoRef != nil { #expect(release.texto(de: item) != nil, "\(item.id)") }
        // Ida y vuelta del campo en JSON.
        let item = try #require(conTexto.first)
        #expect(try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(item)).textoRef == item.textoRef)
    }

    @Test("El validador falla con un textoRef inexistente, un texto de dominio público sin año de muerte o con menos de 80 años")
    func validador() throws {
        var item = try #require(bancoTextos.itemsEstaticos.first { $0.textoRef == "TXT.ORI.ABEJAS" })
        item.textoRef = "TXT.ORI.NOEXISTE"
        let banco = BancoContenido(catalogo: bancoTextos.catalogo, items: [item], textos: bancoTextos.textos)
        #expect(validadorTextos.validar(banco).contains { $0.elemento == item.id && $0.mensaje.contains("TXT.ORI.NOEXISTE") })
        item.textoRef = "mal"
        #expect(validadorTextos.validar(item: item, competencias: [item.competencia]).contains { $0.mensaje.contains("TXT.XXX.CLAVE") })

        var texto = try #require(bancoTextos.texto(id: "TXT.MAC.CAM"))
        texto.procedencia.anioMuerteAutor = nil
        #expect(validadorTextos.validar(texto: texto).contains { $0.mensaje.contains("sin anioMuerteAutor") })
        texto.procedencia.anioMuerteAutor = 1950
        #expect(validadorTextos.validar(texto: texto).contains { $0.mensaje.contains("no han pasado más de 80") })
        texto.procedencia.anioMuerteAutor = 1939
        #expect(validadorTextos.validar(texto: texto).isEmpty)
        texto.autor = "Otro autor"
        #expect(validadorTextos.validar(texto: texto).contains { $0.mensaje.contains("no coincide") })
        // Duplicados.
        let t = try #require(bancoTextos.textos.first)
        let duplicado = BancoContenido(catalogo: bancoTextos.catalogo, items: [], textos: [t, t])
        #expect(validadorTextos.validar(duplicado).contains { $0.mensaje.contains("duplicado") })
    }

    @Test("Autor y año de los textos literarios (año de la obra según la base literaria)")
    func referenciaLiteraria() throws {
        let becquer = try #require(bancoTextos.texto(id: "TXT.BEC.R21"))
        #expect(bancoTextos.anio(de: becquer) == 1871)
        #expect(VistaTextoBase.referencia(becquer, anio: 1871) == "Gustavo Adolfo Bécquer · Rimas (1871)")
        let machado = try #require(bancoTextos.texto(id: "TXT.MAC.CAM"))
        #expect(bancoTextos.anio(de: machado) == 1912)
        let abejas = try #require(bancoTextos.texto(id: "TXT.ORI.ABEJAS"))
        #expect(VistaTextoBase.referencia(abejas, anio: nil) == nil, "Los textos originales no llevan autor")
    }
}

@Suite("Base literaria (lote 05a)")
struct BaseLiterariaTests {
    @Test("Se carga y pasa el validador sin errores")
    func carga() throws {
        let b = try #require(bancoTextos.literatura)
        #expect(b.version == 2 && b.movimientos.count == 21 && b.autores.count == 142)
        #expect(validadorTextos.validar(literatura: b).isEmpty, "\(validadorTextos.validar(literatura: b).prefix(5))")
        #expect(ValidadorContenido().validar(literatura: b).isEmpty, "También con el año real")
    }

    @Test("Cada autor tiene obras y años; los únicos sin ningún año son anónimos o antiguos de fecha aproximada")
    func obrasYAnios() throws {
        let b = try #require(bancoTextos.literatura)
        var sinAnios: [String] = []
        for a in b.autores {
            #expect(!a.obras.isEmpty && a.obras.allSatisfy { !$0.titulo.isEmpty }, "\(a.id) sin obras")
            let anios = [a.nacimiento, a.muerte].compactMap { $0 } + a.obras.compactMap(\.anio)
            if anios.isEmpty {
                #expect(a.aproximado && a.nacimiento == nil && a.muerte == nil, "\(a.id) sin años y sin marcar como aproximado")
                sinAnios.append(a.id)
            }
        }
        print("LITERATURA autores sin ningún año (aproximados): \(sinAnios)")
        #expect(sinAnios.count <= 2, "\(sinAnios)")
    }

    @Test("fragmentosPermitidos solo en autores de dominio público y en español")
    func fragmentos() throws {
        let b = try #require(bancoTextos.literatura)
        let conFragmentos = b.autores.filter(\.fragmentosPermitidos)
        #expect(conFragmentos.count == 50)
        for a in conFragmentos {
            #expect(a.dominioPublico, "\(a.id)")
            #expect(BaseLiteraria.ambitosConFragmentos.contains(a.ambito), "\(a.id): \(a.ambito)")
            if let m = a.muerte { #expect(2026 - m > 80, "\(a.id) murió en \(m)") }
        }
        // El validador detecta un fragmento permitido de un autor extranjero o vivo.
        var mal = b
        let i = try #require(mal.autores.firstIndex { $0.ambito == "universal" && $0.dominioPublico })
        mal.autores[i].fragmentosPermitidos = true
        let j = try #require(mal.autores.firstIndex { !$0.dominioPublico && $0.ambito == "espanola" })
        mal.autores[j].fragmentosPermitidos = true
        let errores = validadorTextos.validar(literatura: mal)
        #expect(errores.contains { $0.elemento.contains(mal.autores[i].id) } && errores.contains { $0.elemento.contains(mal.autores[j].id) })
    }
}
