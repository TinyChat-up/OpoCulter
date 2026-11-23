import Foundation

/// Recuento de preguntas únicas del banco: ítems estáticos + variantes únicas de las plantillas
/// (D-064). Cada pregunta cuenta una vez: los ítems estáticos por id y las generadas por su clave
/// canónica (`tipo|clave`), sin duplicados entre plantillas. La app muestra esta cifra real.
///
/// Los espacios combinatorios muy grandes (operaciones combinadas, estadística, oraciones…) se
/// recorren hasta `limitePorPlantilla`: si se alcanza el límite, el recuento de esa plantilla es una
/// cota inferior (`exacto == false`). Nunca se calcula en el arranque: se cachea por versión de
/// contenido y política de carga.
struct RecuentoCatalogo: Sendable, Equatable {
    struct Plantillas: Sendable, Equatable {
        var id: String
        var tipo: String
        var competencia: String
        var variantes: Int
        var exacto: Bool
    }

    var estaticos = 0
    var generados = 0
    var porArea: [String: Int] = [:]
    var porBloque: [String: Int] = [:]
    var porCompetencia: [String: Int] = [:]
    var porPeldano: [Int: Int] = [:]
    var porDificultad: [Int: Int] = [:]
    var plantillas: [Plantillas] = []

    var total: Int { estaticos + generados }
    /// `true` si ninguna plantilla ha llegado al límite (recuento exacto).
    var exacto: Bool { plantillas.allSatisfy(\.exacto) }
}

enum CatalogoPreguntas {
    static let limitePorPlantilla = 20_000

    private final class Cache: @unchecked Sendable {
        let cerrojo = NSLock()
        var valores: [String: RecuentoCatalogo] = [:]
    }
    private static let cache = Cache()

    /// Recuento con caché por versión de contenido (clave: versión, número de ítems y plantillas).
    static func recuento(_ banco: BancoContenido, limitePorPlantilla: Int = limitePorPlantilla) -> RecuentoCatalogo {
        let clave = "\(banco.catalogo.version)|\(banco.numeroEstaticos)|\(banco.plantillas.map(\.id).joined(separator: ","))|\(limitePorPlantilla)"
        cache.cerrojo.lock()
        if let r = cache.valores[clave] { cache.cerrojo.unlock(); return r }
        cache.cerrojo.unlock()
        let r = contar(banco, limitePorPlantilla: limitePorPlantilla)
        cache.cerrojo.lock()
        cache.valores[clave] = r
        cache.cerrojo.unlock()
        return r
    }

    /// Recuento sin caché.
    static func contar(_ banco: BancoContenido, limitePorPlantilla: Int = limitePorPlantilla) -> RecuentoCatalogo {
        var r = RecuentoCatalogo()
        func anotar(competencia: String, peldano: Int, dificultad: Int, cantidad: Int) {
            let partes = competencia.split(separator: ".")
            r.porArea[String(partes.first ?? ""), default: 0] += cantidad
            r.porBloque[partes.prefix(2).joined(separator: "."), default: 0] += cantidad
            r.porCompetencia[competencia, default: 0] += cantidad
            r.porPeldano[peldano, default: 0] += cantidad
            r.porDificultad[dificultad, default: 0] += cantidad
        }
        var ids = Set<String>()
        for item in banco.itemsEstaticos where ids.insert(item.id).inserted {
            r.estaticos += 1
            anotar(competencia: item.competencia, peldano: item.peldano, dificultad: item.dificultad, cantidad: 1)
        }
        // Cada plantilla se enumera en paralelo; la deduplicación se hace después, en orden.
        let plantillas = banco.plantillas
        final class Listas: @unchecked Sendable { var valores: [[String]] ; init(_ n: Int) { valores = Array(repeating: [], count: n) } }
        let listas = Listas(plantillas.count)
        let cerrojo = NSLock()
        let recursos = banco.recursos
        DispatchQueue.concurrentPerform(iterations: plantillas.count) { i in
            let lista = MotorGeneradores.generador(plantillas[i].tipo)?.enumerar(plantillas[i], recursos: recursos, limite: limitePorPlantilla) ?? []
            cerrojo.lock(); listas.valores[i] = lista; cerrojo.unlock()
        }
        var claves = Set<String>()
        for (i, p) in plantillas.enumerated() {
            guard MotorGeneradores.generador(p.tipo) != nil else { continue }
            let lista = listas.valores[i]
            var nuevas = 0
            for c in lista where claves.insert("\(p.tipo)|\(c)").inserted { nuevas += 1 }
            r.generados += nuevas
            let muestreo = ["operacionesCombinadas", "estadisticaBasica", "oracionSimple"].contains(p.tipo)
            r.plantillas.append(.init(id: p.id, tipo: p.tipo, competencia: p.competencia, variantes: nuevas,
                                      exacto: !muestreo && lista.count < limitePorPlantilla))
            anotar(competencia: p.competencia, peldano: p.peldano, dificultad: p.dificultad, cantidad: nuevas)
        }
        return r
    }
}
