import Foundation
@testable import Educulter

/// Datos y utilidades compartidas por los tests.
enum Fx {
    static let original = Procedencia(tipo: .original, autorTexto: nil, anioMuerteAutor: nil, fuente: nil,
                                      licencia: "propia", notas: nil)
    static let borrador = Validacion(estado: .borrador, revisor: nil, fecha: nil)
    static let aprobado = Validacion(estado: .aprobado, revisor: "Revisora", fecha: "2026-11-23")

    static let vf = Payload.verdaderoFalso(.init(afirmacion: "Afirmación", esVerdadera: true))

    static func item(_ id: String, competencia: String? = nil, peldano: Int = 2, dificultad: Int = 2,
                     payload: Payload = vf, validacion: Validacion = borrador) -> Item {
        let comp = competencia ?? String(id.split(separator: ".").prefix(3).joined(separator: "."))
        return Item(id: id, competencia: comp, peldano: peldano, dificultad: dificultad, objetivo: "Objetivo",
                    enunciado: "Enunciado", payload: payload, explicacion: "Explicación breve.",
                    procedencia: original, validacion: validacion)
    }

    /// Catálogo construido a partir de ids de competencia (`AREA.BLQ.COMP`).
    /// `prioridades` asigna prioridad por bloque (por defecto, 3).
    static func catalogo(_ competencias: [String], prioridades: [String: Int] = [:]) -> Catalogo {
        var areas: [String: [String: [String]]] = [:]
        var ordenAreas: [String] = [], ordenBloques: [String: [String]] = [:]
        for c in competencias {
            let partes = c.split(separator: ".").map(String.init)
            let area = partes[0], bloque = "\(partes[0]).\(partes[1])"
            if areas[area] == nil { areas[area] = [:]; ordenAreas.append(area) }
            if areas[area]?[bloque] == nil { areas[area]?[bloque] = []; ordenBloques[area, default: []].append(bloque) }
            areas[area]?[bloque]?.append(c)
        }
        return Catalogo(version: 1, areas: ordenAreas.map { a in
            Catalogo.Area(id: a, nombre: "Área \(a)", bloques: (ordenBloques[a] ?? []).enumerated().map { i, b in
                Catalogo.Bloque(id: b, nombre: "Bloque \(b)", prioridad: prioridades[b] ?? 3, orden: i + 1,
                                competencias: (areas[a]?[b] ?? []).enumerated().map { j, c in
                                    Catalogo.Competencia(id: c, nombre: "Competencia \(c)", orden: j + 1)
                                })
            })
        })
    }

    static func banco(_ items: [Item], extras: [String] = [], teoria: [TarjetaTeoria] = [],
                      prioridades: [String: Int] = [:]) -> BancoContenido {
        var comps: [String] = []
        for c in items.map(\.competencia) + extras where !comps.contains(c) { comps.append(c) }
        return BancoContenido(catalogo: catalogo(comps, prioridades: prioridades), items: items, teoria: teoria)
    }

    static var madrid: Calendar { calendario("Europe/Madrid") }

    static func calendario(_ zona: String) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: zona)!
        return c
    }

    static func fecha(_ a: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0, en cal: Calendar = madrid) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: d, hour: h, minute: min))!
    }

    static func dia(_ a: Int, _ m: Int, _ d: Int) -> DiaCivil { DiaCivil(anio: a, mes: m, dia: d) }

    /// Carpeta temporal con una estructura de contenido escrita desde diccionarios JSON.
    static func carpetaContenido(_ archivos: [String: String]) throws -> URL {
        let raiz = FileManager.default.temporaryDirectory.appendingPathComponent("contenido-\(UUID().uuidString)")
        for (ruta, texto) in archivos {
            let url = raiz.appendingPathComponent(ruta)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(texto.utf8).write(to: url)
        }
        return raiz
    }
}
