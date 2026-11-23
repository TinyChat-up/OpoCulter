import Foundation

/// Contenido educativo cargado en memoria, con índices de búsqueda. Inmutable y `Sendable`.
struct BancoContenido: Sendable, Equatable {
    let catalogo: Catalogo
    let items: [Item]
    let teoria: [TarjetaTeoria]
    let simulacros: [Simulacro]

    private let indicePorId: [String: Int]
    private let indicePorCompetencia: [String: [Int]]

    init(catalogo: Catalogo, items: [Item], teoria: [TarjetaTeoria] = [], simulacros: [Simulacro] = []) {
        self.catalogo = catalogo
        self.items = items
        self.teoria = teoria
        self.simulacros = simulacros
        var porId: [String: Int] = [:]
        var porCompetencia: [String: [Int]] = [:]
        for (i, item) in items.enumerated() {
            porId[item.id] = porId[item.id] ?? i
            porCompetencia[item.competencia, default: []].append(i)
        }
        indicePorId = porId
        indicePorCompetencia = porCompetencia
    }

    func item(id: String) -> Item? {
        indicePorId[id].map { items[$0] }
    }

    func items(competencia: String) -> [Item] {
        (indicePorCompetencia[competencia] ?? []).map { items[$0] }
    }

    func items(competencia: String, peldano: Int) -> [Item] {
        items(competencia: competencia).filter { $0.peldano == peldano }
    }

    func items(bloque: String) -> [Item] {
        guard let b = catalogo.bloque(id: bloque) else { return [] }
        return b.competencias.flatMap { items(competencia: $0.id) }
    }

    func teoria(competencia: String) -> [TarjetaTeoria] {
        teoria.filter { $0.competencia == competencia }
    }

    static func == (a: BancoContenido, b: BancoContenido) -> Bool {
        a.catalogo == b.catalogo && a.items == b.items && a.teoria == b.teoria && a.simulacros == b.simulacros
    }
}
