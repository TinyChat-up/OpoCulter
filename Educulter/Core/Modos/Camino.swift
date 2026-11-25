import Foundation

/// Estado de un nodo (competencia) del Camino.
enum EstadoNodo: String, Sendable, Equatable {
    /// Sin ítems aprobados: trazo discontinuo, "En preparación", no se puede pulsar.
    case sinContenido
    case disponible
    /// Con progreso o competencia en curso: anillo de dominio según el peldaño.
    case enCurso
    case dominada
}

struct NodoCamino: Sendable, Equatable, Identifiable {
    var competencia: Catalogo.Competencia
    var estado: EstadoNodo
    /// Peldaño actual (1–5) y fracción de dominio para el anillo.
    var peldano: Int
    var dominio: Double
    /// El orden recomendado aún no llega aquí: se muestra un candado, pero se puede abrir con
    /// una prueba de nivel (el orden es una recomendación, no un muro).
    var bloqueadoPorOrden: Bool
    var pruebaNivelDisponible: Bool
    var esEnCurso: Bool

    var id: String { competencia.id }
}

struct TramoCamino: Sendable, Equatable, Identifiable {
    var bloque: Catalogo.Bloque
    var nodos: [NodoCamino]
    /// El bloque tiene contenido suficiente para su Reto (8 ítems sin ayudas, dificultad 4–5).
    var retoDisponible: Bool
    var medallaObtenida: Bool

    var id: String { bloque.id }
}

/// Configuración de la prueba de nivel y del Reto de bloque (D-070).
struct ConfiguracionCamino: Sendable, Equatable {
    var itemsPruebaNivel = 5
    var peldanoPruebaNivel = 3
    var aciertosPruebaNivel = 4
    var itemsReto = 8
    var aciertosReto = 6
    var dificultadesReto = 4...5

    static let estandar = ConfiguracionCamino()
}

/// Construye el Camino y las rondas especiales a partir del banco y del progreso. Puro.
struct ConstructorCamino: Sendable {
    let banco: BancoContenido
    var config = ConfiguracionCamino.estandar
    var escalera = ConfiguracionEscalera.estandar
    var peldanoMaximoEnRonda = 4

    func tieneContenido(_ competencia: String) -> Bool {
        banco.items(competencia: competencia).contains { $0.peldano <= peldanoMaximoEnRonda }
    }

    /// Ítems del peldaño de la prueba de nivel (estáticos y variantes materializadas).
    func itemsPruebaNivel(_ competencia: String) -> [Item] {
        banco.items(competencia: competencia).filter { $0.peldano == config.peldanoPruebaNivel }
    }

    func tramos(area: String, estados: [String: EstadoCompetencia], enCurso: String?, medallas: Set<String>) -> [TramoCamino] {
        let bloques = banco.catalogo.areas.first { $0.id == area }?.bloques.sorted { $0.orden < $1.orden } ?? []
        // El candado aparece a partir de la primera competencia con contenido sin dominar (la
        // recomendada) para las que aún no se han empezado.
        var recomendadaAlcanzada = false
        var tramos: [TramoCamino] = []
        for b in bloques {
            var nodos: [NodoCamino] = []
            for c in b.competencias.sorted(by: { $0.orden < $1.orden }) {
                let estado = estados[c.id]
                let peldano = estado?.escalera.peldano ?? 1
                let contenido = tieneContenido(c.id)
                // Una competencia antigua sustituida por otra del mapa (D-091) solo aparece si tiene
                // contenido o progreso: si no, sería un duplicado «En preparación» de la nueva.
                if c.equivaleA != nil && !contenido && estado == nil { continue }
                let dominada = estado?.escalera.dominada(escalera) ?? false
                let empezada = estado?.leitner != nil || peldano > 1
                let e: EstadoNodo = !contenido ? .sinContenido : (dominada ? .dominada : ((empezada || c.id == enCurso) ? .enCurso : .disponible))
                let bloqueado = contenido && !dominada && !empezada && c.id != enCurso && recomendadaAlcanzada
                if contenido && !dominada && !recomendadaAlcanzada { recomendadaAlcanzada = true }
                nodos.append(NodoCamino(competencia: c, estado: e, peldano: peldano,
                                        dominio: Double(min(peldano - 1, 4)) / 4,
                                        bloqueadoPorOrden: bloqueado,
                                        pruebaNivelDisponible: contenido && peldano < config.peldanoPruebaNivel
                                            && itemsPruebaNivel(c.id).count >= config.itemsPruebaNivel,
                                        esEnCurso: c.id == enCurso))
            }
            tramos.append(TramoCamino(bloque: b, nodos: nodos, retoDisponible: retoDisponible(b.id),
                                      medallaObtenida: medallas.contains(Self.medalla(b.id))))
        }
        return tramos
    }

    static func medalla(_ bloque: String) -> String { "medalla-\(bloque)" }

    // MARK: Reto de bloque

    /// Ítems estáticos del bloque válidos para el Reto: sin ayudas (peldaño ≥ 3) y dificultad 4–5.
    func estaticosReto(_ bloque: String) -> [Item] {
        banco.items(bloque: bloque).filter { !$0.id.contains("#") && $0.peldano >= 3 && $0.peldano <= 5 && config.dificultadesReto.contains($0.dificultad) }
    }

    func plantillasReto(_ bloque: String) -> [Plantilla] {
        banco.plantillas.filter { banco.catalogo.bloque(deCompetencia: $0.competencia)?.id == bloque }
    }

    /// Hay Reto si el bloque tiene 8 estáticos válidos o alguna plantilla (que genera los que faltan).
    func retoDisponible(_ bloque: String) -> Bool {
        estaticosReto(bloque).count >= config.itemsReto || !plantillasReto(bloque).isEmpty
    }

    /// Los 8 ítems del Reto: estáticos válidos y, si faltan, generados a dificultad 4–5 y peldaño ≥ 3.
    func itemsReto(_ bloque: String, rng: inout GeneradorConSemilla) -> [Item] {
        var items = Array(estaticosReto(bloque).shuffled(using: &rng).sinPreguntasRepetidas().prefix(config.itemsReto))
        let plantillas = plantillasReto(bloque)
        var intentos = 0
        while items.count < config.itemsReto, !plantillas.isEmpty, intentos < 200 {
            intentos += 1
            let base = plantillas.randomElement(using: &rng)!
            let p = MotorGeneradores.ajustada(base, dificultad: config.dificultadesReto.randomElement(using: &rng)!, peldano: max(3, base.peldano))
            // Sin preguntas repetidas aunque cambie el id (D-087).
            if let item = try? MotorGeneradores.generar(p, semilla: UInt64.random(in: 0...999_999, using: &rng), recursos: banco.recursos),
               !items.contains(where: { $0.id == item.id || $0.huella == item.huella }) {
                items.append(item)
            }
        }
        return items.count >= config.itemsReto ? items.shuffled(using: &rng) : []
    }
}
