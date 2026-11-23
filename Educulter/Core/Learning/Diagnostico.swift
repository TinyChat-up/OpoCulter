import Foundation

struct ConfiguracionDiagnostico: Sendable, Equatable {
    /// Prioridad de los bloques que entran en el diagnóstico (★★★).
    var prioridadDiagnostico = 3
    /// Dificultad buscada para el primer ítem de cada bloque.
    var dificultadInicial = 2
    var maxItemsPorBloque = 2
    /// Debilidad asumida para los bloques que no se han evaluado.
    var debilidadSinDatos = 0.5

    static let estandar = ConfiguracionDiagnostico()
}

/// Nivel estimado en un bloque: 0 (falla el primer ítem), 0,5 (acierta el primero y falla
/// el más difícil) o 1 (acierta todo lo que se le ha planteado).
struct NivelBloque: Codable, Sendable, Equatable {
    var bloqueId: String
    var nivel: Double
    var respondidos: Int
    var aciertos: Int
}

struct EntradaPlan: Codable, Sendable, Equatable {
    var bloqueId: String
    var prioridad: Int
    var debilidad: Double
    /// debilidad × prioridad: cuanto mayor, antes se trabaja.
    var puntuacion: Double
}

struct ResultadoDiagnostico: Codable, Sendable, Equatable {
    var fecha: Date
    var niveles: [NivelBloque]
    var plan: [EntradaPlan]
}

/// Sesión de diagnóstico adaptativa: 1 ítem por bloque prioritario y, si se acierta, otro
/// de mayor dificultad (máximo 2 por bloque).
struct SesionDiagnostico: Sendable {
    let banco: BancoContenido
    let config: ConfiguracionDiagnostico
    private(set) var pendientes: [String] = []
    private(set) var respuestas: [String: [(itemId: String, dificultad: Int, correcto: Bool)]] = [:]
    private var rng: GeneradorConSemilla

    init(banco: BancoContenido, config: ConfiguracionDiagnostico = .estandar, rng: GeneradorConSemilla) {
        self.banco = banco
        self.config = config
        self.rng = rng
        // Se alternan las áreas (L, M, L, M…) para variar el ritmo.
        let porArea = banco.catalogo.areas.map { area in
            area.bloques.filter { $0.prioridad == config.prioridadDiagnostico }.sorted { $0.orden < $1.orden }
        }
        let maximo = porArea.map(\.count).max() ?? 0
        for i in 0..<maximo {
            for bloques in porArea where i < bloques.count {
                if let item = primerItem(bloque: bloques[i].id) { pendientes.append(item.id) }
            }
        }
    }

    var terminado: Bool { pendientes.isEmpty }

    /// Siguiente ítem que debe responderse (no lo saca de la cola hasta que se registra).
    var siguienteItem: Item? {
        pendientes.first.flatMap { banco.item(id: $0) }
    }

    /// Registra la respuesta al ítem en curso y, si procede, encola uno más difícil del mismo bloque.
    mutating func registrar(itemId: String, correcto: Bool) {
        guard let indice = pendientes.firstIndex(of: itemId), let item = banco.item(id: itemId),
              let bloque = banco.catalogo.bloque(deCompetencia: item.competencia) else { return }
        pendientes.remove(at: indice)
        respuestas[bloque.id, default: []].append((itemId, item.dificultad, correcto))
        let delBloque = respuestas[bloque.id] ?? []
        guard correcto, delBloque.count < config.maxItemsPorBloque else { return }
        let usados = Set(delBloque.map(\.itemId))
        let masDificiles = itemsDiagnosticables(bloque: bloque.id).filter { $0.dificultad > item.dificultad && !usados.contains($0.id) }
        if let minima = masDificiles.map(\.dificultad).min(),
           let siguiente = masDificiles.filter({ $0.dificultad == minima }).randomElement(using: &rng) {
            pendientes.append(siguiente.id)
        }
    }

    func resultado(fecha: Date) -> ResultadoDiagnostico {
        let niveles = banco.catalogo.todosLosBloques.compactMap { bloque -> NivelBloque? in
            guard let r = respuestas[bloque.id], let primero = r.first else { return nil }
            let aciertos = r.filter(\.correcto).count
            let nivel: Double = !primero.correcto ? 0 : (aciertos == r.count ? 1 : 0.5)
            return NivelBloque(bloqueId: bloque.id, nivel: nivel, respondidos: r.count, aciertos: aciertos)
        }
        return ResultadoDiagnostico(fecha: fecha, niveles: niveles, plan: Self.plan(niveles: niveles, banco: banco, config: config))
    }

    /// Plan inicial: bloques con contenido ordenados por debilidad × prioridad (desc.).
    static func plan(niveles: [NivelBloque], banco: BancoContenido, config: ConfiguracionDiagnostico) -> [EntradaPlan] {
        let nivelPorBloque = Dictionary(niveles.map { ($0.bloqueId, $0.nivel) }, uniquingKeysWith: { a, _ in a })
        let bloques = banco.catalogo.todosLosBloques
        let posicion = Dictionary(bloques.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
        return bloques
            .filter { !banco.items(bloque: $0.id).isEmpty }
            .map { b in
                let debilidad = nivelPorBloque[b.id].map { 1 - $0 } ?? config.debilidadSinDatos
                return EntradaPlan(bloqueId: b.id, prioridad: b.prioridad, debilidad: debilidad,
                                   puntuacion: debilidad * Double(b.prioridad))
            }
            .sorted {
                ($1.puntuacion, $1.prioridad, -(posicion[$1.bloqueId] ?? 0)) < ($0.puntuacion, $0.prioridad, -(posicion[$0.bloqueId] ?? 0))
            }
    }

    // MARK: - Selección

    private mutating func primerItem(bloque: String) -> Item? {
        let candidatos = itemsDiagnosticables(bloque: bloque)
        guard let mejor = candidatos.map({ abs($0.dificultad - config.dificultadInicial) }).min() else { return nil }
        return candidatos.filter { abs($0.dificultad - config.dificultadInicial) == mejor }.randomElement(using: &rng)
    }

    /// Ítems de peldaños 2–4 del bloque (si no hay, cualquiera salvo el peldaño 5).
    private func itemsDiagnosticables(bloque: String) -> [Item] {
        let todos = banco.items(bloque: bloque)
        let preferidos = todos.filter { (2...4).contains($0.peldano) }
        return preferidos.isEmpty ? todos.filter { $0.peldano < 5 } : preferidos
    }
}
