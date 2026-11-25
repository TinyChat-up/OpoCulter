import Foundation

/// Contenido educativo cargado en memoria, con índices de búsqueda. Inmutable y `Sendable`.
///
/// Además de los ítems estáticos, materializa `variantesPorPlantilla` ítems de cada plantilla de
/// generador (D-062) a partir de `semillaBase` (distinta en cada sesión; fija con `-semilla`).
/// El constructor de rondas los usa igual que los estáticos. `item(id:)` regenera cualquier
/// `<plantilla>#<semilla>` (Rescate reproduce el ítem exacto aunque no esté materializado).
struct BancoContenido: Sendable, Equatable {
    let catalogo: Catalogo
    /// Ítems estáticos + variantes materializadas de las plantillas.
    let items: [Item]
    let teoria: [TarjetaTeoria]
    let simulacros: [Simulacro]
    let plantillas: [Plantilla]
    let recursos: RecursosGeneradores
    /// Textos base de comprensión (D-085).
    let textos: [TextoBase]
    /// Base literaria del lote 05a (datos para la Fase 05F; fecha los textos literarios).
    let literatura: BaseLiteraria?
    /// Número de ítems estáticos (los primeros de `items`).
    let numeroEstaticos: Int

    private let indicePorId: [String: Int]
    private let indicePorCompetencia: [String: [Int]]
    private let plantillaPorId: [String: Plantilla]
    private let textoPorId: [String: TextoBase]

    static let variantesPorPlantilla = 12

    init(catalogo: Catalogo, items: [Item], teoria: [TarjetaTeoria] = [], simulacros: [Simulacro] = [],
         plantillas: [Plantilla] = [], recursos: RecursosGeneradores = .vacios, textos: [TextoBase] = [],
         literatura: BaseLiteraria? = nil,
         variantesPorPlantilla: Int = BancoContenido.variantesPorPlantilla, semillaBase: UInt64 = 1) {
        self.catalogo = catalogo
        self.numeroEstaticos = items.count
        self.items = items + plantillas.flatMap {
            MotorGeneradores.variantes($0, cantidad: variantesPorPlantilla, semillaBase: semillaBase, recursos: recursos)
        }
        self.teoria = teoria
        self.simulacros = simulacros
        self.plantillas = plantillas
        self.recursos = recursos
        self.textos = textos
        self.literatura = literatura
        self.textoPorId = Dictionary(textos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        self.plantillaPorId = Dictionary(plantillas.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let items = self.items
        var porId: [String: Int] = [:]
        var porCompetencia: [String: [Int]] = [:]
        for (i, item) in items.enumerated() {
            porId[item.id] = porId[item.id] ?? i
            porCompetencia[item.competencia, default: []].append(i)
        }
        indicePorId = porId
        indicePorCompetencia = porCompetencia
    }

    /// Huella de la pregunta (D-087).
    func huella(_ item: Item) -> String { item.huella }

    func item(id: String) -> Item? {
        if let i = indicePorId[id] { return items[i] }
        guard let (pid, semilla) = MotorGeneradores.partes(de: id) else { return nil }
        if let p = plantillaPorId[pid] { return try? MotorGeneradores.generar(p, semilla: semilla, recursos: recursos) }
        // Plantilla con dificultad (y peldaño) ajustados: `<id>@d5p3#semilla` (Fase 05D).
        guard let ajuste = MotorGeneradores.ajuste(de: pid), let base = plantillaPorId[ajuste.base],
              ValidadorContenido.rangoDificultad.contains(ajuste.dificultad) else { return nil }
        let p = MotorGeneradores.ajustada(base, dificultad: ajuste.dificultad, peldano: ajuste.peldano)
        return try? MotorGeneradores.generar(p, semilla: semilla, recursos: recursos)
    }

    func plantilla(id: String) -> Plantilla? { plantillaPorId[id] }

    func texto(id: String) -> TextoBase? { textoPorId[id] }

    /// Texto base del ítem (si lo cita con `textoRef` y está cargado).
    func texto(de item: Item) -> TextoBase? { item.textoRef.flatMap { textoPorId[$0] } }

    /// Año de la obra de un texto literario según la base literaria (si consta).
    func anio(de texto: TextoBase) -> Int? { literatura?.anio(autor: texto.autor, obra: texto.obra) }

    /// Ítems estáticos (sin las variantes generadas).
    var itemsEstaticos: ArraySlice<Item> { items.prefix(numeroEstaticos) }

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
            && a.plantillas == b.plantillas && a.recursos == b.recursos && a.textos == b.textos && a.literatura == b.literatura
    }
}
