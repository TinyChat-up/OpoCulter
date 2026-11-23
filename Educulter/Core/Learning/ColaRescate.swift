import Foundation

/// Ítem fallado pendiente de rescatar.
struct EntradaRescate: Codable, Sendable, Equatable {
    var itemId: String
    var competencia: String
    var peldano: Int
    var fecha: Date
}

/// Cola de Rescate: los ítems fallados se rescatan acertando una variante (otro ítem de la
/// misma competencia y peldaño) o, si no hay variante, el mismo ítem.
struct ColaRescate: Codable, Sendable, Equatable {
    /// Entradas en orden de llegada (la más antigua primero).
    private(set) var entradas: [EntradaRescate] = []

    init(entradas: [EntradaRescate] = []) {
        self.entradas = entradas
    }

    var estaVacia: Bool { entradas.isEmpty }
    var cantidad: Int { entradas.count }

    /// Añade un ítem fallado (si ya estaba en la cola, no se duplica).
    mutating func registrarFallo(_ item: Item, fecha: Date) {
        guard !entradas.contains(where: { $0.itemId == item.id }) else { return }
        entradas.append(EntradaRescate(itemId: item.id, competencia: item.competencia, peldano: item.peldano, fecha: fecha))
    }

    /// Registra un acierto y rescata, como mucho, la entrada más antigua que ese acierto
    /// resuelve. Devuelve la entrada rescatada, si la hay.
    @discardableResult
    mutating func registrarAcierto(_ item: Item, banco: BancoContenido) -> EntradaRescate? {
        guard let indice = entradas.firstIndex(where: { Self.rescata(item, $0, banco: banco) }) else { return nil }
        return entradas.remove(at: indice)
    }

    /// Ítem con el que intentar rescatar una entrada: una variante no usada (preferiblemente
    /// no vista recientemente) o, si no existe ninguna variante, el propio ítem fallado.
    func itemParaRescatar(_ entrada: EntradaRescate, banco: BancoContenido, excluir: Set<String>,
                          esReciente: (String) -> Bool, rng: inout some RandomNumberGenerator) -> Item? {
        let variantes = Self.variantes(de: entrada, banco: banco)
        if variantes.isEmpty {
            guard !excluir.contains(entrada.itemId) else { return nil }
            return banco.item(id: entrada.itemId)
        }
        let disponibles = variantes.filter { !excluir.contains($0.id) }
        let frescos = disponibles.filter { !esReciente($0.id) }
        return (frescos.isEmpty ? disponibles : frescos).randomElement(using: &rng)
    }

    static func variantes(de entrada: EntradaRescate, banco: BancoContenido) -> [Item] {
        banco.items(competencia: entrada.competencia, peldano: entrada.peldano).filter { $0.id != entrada.itemId }
    }

    private static func rescata(_ item: Item, _ entrada: EntradaRescate, banco: BancoContenido) -> Bool {
        guard item.competencia == entrada.competencia, item.peldano == entrada.peldano else { return false }
        if item.id != entrada.itemId { return true }
        return variantes(de: entrada, banco: banco).isEmpty
    }
}
