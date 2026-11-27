import Foundation

/// Contenido educativo cargado en memoria, con índices de búsqueda. Inmutable y `Sendable`.
///
/// Además de los ítems estáticos, ofrece `variantesPorPlantilla` ítems de cada plantilla de
/// generador (D-062) a partir de `semillaBase` (distinta en cada sesión; fija con `-semilla`).
/// El constructor de rondas los usa igual que los estáticos. `item(id:)` regenera cualquier
/// `<plantilla>#<semilla>` (Rescate reproduce el ítem exacto aunque no esté materializado).
///
/// Las variantes se generan **de forma perezosa** (05E parte 2, D-102): al pedir los ítems de una
/// competencia o todos, con caché por plantilla. Al arrancar solo se cargan los estáticos.
struct BancoContenido: Sendable, Equatable {
    let catalogo: Catalogo
    /// Ítems estáticos (sin variantes).
    private let estaticos: [Item]
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
    /// Preguntas oficiales por competencia del mapa (`tribunal/equivalencias.json`, D-097, D-103).
    let preguntasOficiales: [String: Int]

    private let indicePorId: [String: Int]
    private let indicePorCompetencia: [String: [Int]]
    private let plantillasPorCompetencia: [String: [Plantilla]]
    private let variantesPorPlantilla: Int
    private let semillaBase: UInt64
    private let cache = CacheVariantes()

    /// Variantes ya generadas, por plantilla y en conjunto (protegidas con cerrojo).
    private final class CacheVariantes: @unchecked Sendable {
        let cerrojo = NSLock()
        var porPlantilla: [String: [Item]] = [:]
        var todos: [Item]?
    }
    private let plantillaPorId: [String: Plantilla]
    /// Huellas de las preguntas que tienen variante de mecánica (05H): no salen en días seguidos.
    let huellasConVariantes: Set<String>
    private let textoPorId: [String: TextoBase]

    static let variantesPorPlantilla = 12

    init(catalogo: Catalogo, items: [Item], teoria: [TarjetaTeoria] = [], simulacros: [Simulacro] = [],
         plantillas: [Plantilla] = [], recursos: RecursosGeneradores = .vacios, textos: [TextoBase] = [],
         literatura: BaseLiteraria? = nil, preguntasOficiales: [String: Int] = [:],
         variantesPorPlantilla: Int = BancoContenido.variantesPorPlantilla, semillaBase: UInt64 = 1) {
        self.preguntasOficiales = preguntasOficiales
        self.catalogo = catalogo
        self.numeroEstaticos = items.count
        self.estaticos = items
        self.huellasConVariantes = Set(items.compactMap { $0.origen.map { "id|" + $0 } })
        self.variantesPorPlantilla = variantesPorPlantilla
        self.semillaBase = semillaBase
        self.plantillasPorCompetencia = Dictionary(grouping: plantillas, by: \.competencia)
        self.teoria = teoria
        self.simulacros = simulacros
        self.plantillas = plantillas
        self.recursos = recursos
        self.textos = textos
        self.literatura = literatura
        self.textoPorId = Dictionary(textos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        self.plantillaPorId = Dictionary(plantillas.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
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

    /// Plantillas cuyas variantes ya se han generado (para los tests del arranque perezoso).
    var plantillasGeneradas: Int { cache.cerrojo.lock(); defer { cache.cerrojo.unlock() }; return cache.porPlantilla.count }

    /// Variantes de una plantilla (generadas la primera vez que se piden).
    func variantes(de p: Plantilla) -> [Item] {
        cache.cerrojo.lock()
        if let v = cache.porPlantilla[p.id] { cache.cerrojo.unlock(); return v }
        cache.cerrojo.unlock()
        let v = MotorGeneradores.variantes(p, cantidad: variantesPorPlantilla, semillaBase: semillaBase, recursos: recursos)
        cache.cerrojo.lock()
        cache.porPlantilla[p.id] = v
        cache.cerrojo.unlock()
        return v
    }

    /// Ítems estáticos + variantes de las plantillas (en este orden). Genera las que falten.
    var items: [Item] {
        cache.cerrojo.lock()
        if let t = cache.todos { cache.cerrojo.unlock(); return t }
        cache.cerrojo.unlock()
        let t = estaticos + plantillas.flatMap(variantes(de:))
        cache.cerrojo.lock()
        cache.todos = t
        cache.cerrojo.unlock()
        return t
    }

    func item(id: String) -> Item? {
        if let i = indicePorId[id] { return estaticos[i] }
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
    var itemsEstaticos: ArraySlice<Item> { estaticos[...] }

    func items(competencia: String) -> [Item] {
        (indicePorCompetencia[competencia] ?? []).map { estaticos[$0] } + (plantillasPorCompetencia[competencia] ?? []).flatMap(variantes(de:))
    }

    /// Número de ítems hasta ese peldaño contando `variantesPorPlantilla` por plantilla, sin generarlas.
    func cuentaSinGenerar(peldanoMaximo: Int) -> Int {
        estaticos.filter { $0.peldano <= peldanoMaximo }.count + plantillas.filter { $0.peldano <= peldanoMaximo }.count * variantesPorPlantilla
    }

    /// Hay algún ítem de la competencia hasta ese peldaño (estático o de plantilla), sin generar nada.
    func tieneItems(competencia: String, peldanoMaximo: Int = 5) -> Bool {
        (indicePorCompetencia[competencia] ?? []).contains { estaticos[$0].peldano <= peldanoMaximo }
            || (plantillasPorCompetencia[competencia] ?? []).contains { $0.peldano <= peldanoMaximo }
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
        a.catalogo == b.catalogo && a.estaticos == b.estaticos && a.semillaBase == b.semillaBase
            && a.variantesPorPlantilla == b.variantesPorPlantilla && a.teoria == b.teoria && a.simulacros == b.simulacros
            && a.plantillas == b.plantillas && a.recursos == b.recursos && a.textos == b.textos && a.literatura == b.literatura
    }
}
