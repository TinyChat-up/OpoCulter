import Foundation

struct ConfiguracionRonda: Sendable, Equatable {
    var minimo = 6
    var maximo = 8
    /// Tamaño buscado cuando hay contenido suficiente.
    var objetivo = 7
    /// Tope de repasos vencidos por ronda, para no desplazar la competencia en curso.
    var maxRepasos = 3
    var maxRescate = 2
    /// Peldaño mínimo de una competencia para usarla como ítem intercalado.
    var peldanoMinimoIntercalado = 3
    /// Peldaño máximo que se practica en rondas (el 5, formato examen, va a simulacros y retos).
    var peldanoMaximoEnRonda = 4
    /// Ventana en la que no se repite un ítem visto si hay alternativa.
    var segundosSinRepetir: TimeInterval = 24 * 3600

    static let estandar = ConfiguracionRonda()
}

/// Ítem elegido para una ronda y motivo por el que entra.
struct ItemRonda: Sendable, Equatable {
    enum Motivo: String, Sendable, Codable {
        case repaso, rescate, enCurso, intercalado, relleno
        /// Modos de la Fase 05D.
        case pruebaNivel, reto, supervivencia, diagnostico, practica
    }
    var itemId: String
    var motivo: Motivo
}

struct Ronda: Sendable, Equatable {
    var items: [ItemRonda]
    var competenciaEnCurso: String?
    /// Tarjetas de teoría que se muestran antes de la ronda (competencia en el peldaño 1).
    var teoriaPrevia: [String]
}

/// Compone rondas de 6–8 ítems con esta prioridad:
/// 1. repasos vencidos; 2. Rescate (máx. 2); 3. competencia en curso en su peldaño;
/// 4. un ítem intercalado de otra competencia en el peldaño 3 o superior.
/// Evita ítems vistos en las últimas 24 h si hay alternativa y nunca repite una pregunta en la
/// misma ronda, aunque cambie el id (huella, D-087).
struct ConstructorRondas: Sendable {
    let banco: BancoContenido
    var config = ConfiguracionRonda.estandar

    init(banco: BancoContenido, config: ConfiguracionRonda = .estandar) {
        self.banco = banco
        self.config = config
    }

    func construir(
        estados: [String: EstadoCompetencia],
        rescate: ColaRescate,
        enCurso: String?,
        vistos: [String: Date],
        ahora: Date,
        calendario: Calendar,
        rng: inout some RandomNumberGenerator
    ) -> Ronda {
        let hoy = DiaCivil(ahora, calendario: calendario)
        let esReciente: (String) -> Bool = { id in
            guard let fecha = vistos[id] else { return false }
            return ahora.timeIntervalSince(fecha) < config.segundosSinRepetir
        }
        var elegidos: [ItemRonda] = []
        var usados = Set<String>()
        var huellas = Set<String>()

        func anadir(_ item: Item?, _ motivo: ItemRonda.Motivo) -> Bool {
            guard let item, !usados.contains(item.id), elegidos.count < config.maximo else { return false }
            usados.insert(item.id)
            guard huellas.insert(banco.huella(item)).inserted else { return false }
            elegidos.append(ItemRonda(itemId: item.id, motivo: motivo))
            return true
        }

        // 1. Repasos vencidos, del más atrasado al más reciente.
        let vencidas = estados.values
            .filter { $0.competenciaId != enCurso && $0.vencida(hoy: hoy) }
            .sorted { ($0.leitner?.proximoRepaso ?? hoy, $0.competenciaId) < ($1.leitner?.proximoRepaso ?? hoy, $1.competenciaId) }
        var repasos = 0
        for estado in vencidas where repasos < config.maxRepasos {
            let candidatos = candidatos(competencia: estado.competenciaId, peldano: estado.escalera.peldano)
            if anadir(elegir(candidatos, usados: usados, huellas: huellas, esReciente: esReciente, rng: &rng), .repaso) { repasos += 1 }
        }

        // 2. Rescate.
        var rescates = 0
        for entrada in rescate.entradas where rescates < config.maxRescate {
            let item = rescate.itemParaRescatar(entrada, banco: banco, excluir: usados, esReciente: esReciente, rng: &rng)
            if anadir(item, .rescate) { rescates += 1 }
        }

        // 4 (se reserva el hueco antes de llenar con la competencia en curso).
        let intercalable = competenciaIntercalable(estados: estados, enCurso: enCurso, usados: usados, huellas: huellas,
                                                   esReciente: esReciente, rng: &rng)
        let reserva = intercalable == nil ? 0 : 1

        // 3. Competencia en curso, en su peldaño, por dificultad creciente. Solo ítems no vistos
        //    recientemente: si se agotan, se rellena con otras competencias antes de repetir.
        var enCursoElegidos: [Item] = []
        if let enCurso {
            let peldano = estados[enCurso]?.escalera.peldano ?? 1
            let candidatos = candidatos(competencia: enCurso, peldano: peldano)
            while elegidos.count + enCursoElegidos.count + reserva < config.objetivo,
                  let item = elegir(candidatos, usados: usados.union(enCursoElegidos.map(\.id)),
                                    huellas: huellas.union(enCursoElegidos.map(banco.huella)
                                        + (intercalable.map { [banco.huella($0)] } ?? [])), esReciente: esReciente,
                                    permitirRecientes: false, rng: &rng) {
                enCursoElegidos.append(item)
            }
            for item in enCursoElegidos.sorted(by: { ($0.dificultad, $0.id) < ($1.dificultad, $1.id) }) {
                _ = anadir(item, .enCurso)
            }
        }

        // 4. Intercalado.
        if let intercalable {
            _ = anadir(intercalable, .intercalado)
        }

        // Relleno hasta el mínimo: competencias empezadas y, después, cualquier ítem. Primero
        // sin repetir ítems recientes; solo si no basta, se admiten.
        // Se prefiere el área de la competencia en curso (D-055): una ronda de Matemáticas se
        // completa con Matemáticas mientras haya contenido.
        let area = enCurso.map(Catalogo.area(de:))
        let empezadas = estados.values.sorted {
            ($0.competenciaId.hasPrefix(area ?? "") ? 0 : 1, $0.competenciaId) < ($1.competenciaId.hasPrefix(area ?? "") ? 0 : 1, $1.competenciaId)
        }
        let resto = banco.items.filter { $0.peldano <= config.peldanoMaximoEnRonda }
        let restoArea = area.map { a in resto.filter { Catalogo.area(de: $0.competencia) == a } } ?? []
        for permitirRecientes in [false, true] where elegidos.count < config.minimo {
            for estado in empezadas where elegidos.count < config.minimo {
                let candidatos = candidatos(competencia: estado.competenciaId, peldano: estado.escalera.peldano)
                _ = anadir(elegir(candidatos, usados: usados, huellas: huellas, esReciente: esReciente,
                                  permitirRecientes: permitirRecientes, rng: &rng), .relleno)
            }
            for grupo in [restoArea, resto] {
                while elegidos.count < config.minimo,
                      let item = elegir(grupo, usados: usados, huellas: huellas, esReciente: esReciente, permitirRecientes: permitirRecientes, rng: &rng) {
                    _ = anadir(item, .relleno)
                }
            }
        }

        var teoria: [String] = []
        if let enCurso, (estados[enCurso]?.escalera.peldano ?? 1) == Peldano.descubre.rawValue {
            teoria = banco.teoria(competencia: enCurso).map(\.id)
        }
        return Ronda(items: elegidos, competenciaEnCurso: enCurso, teoriaPrevia: teoria)
    }

    /// Ítems de una competencia para practicar en un peldaño. Si no hay ítems de ese peldaño,
    /// se usa el peldaño inferior más cercano que tenga y, si tampoco hay, el superior más
    /// cercano (D-037). Nunca se usa el peldaño 5 en rondas.
    func candidatos(competencia: String, peldano: Int) -> [Item] {
        let tope = config.peldanoMaximoEnRonda
        let inicial = min(peldano, tope)
        for p in stride(from: inicial, through: 1, by: -1) {
            let items = banco.items(competencia: competencia, peldano: p)
            if !items.isEmpty { return items }
        }
        for p in stride(from: inicial + 1, through: tope, by: 1) {
            let items = banco.items(competencia: competencia, peldano: p)
            if !items.isEmpty { return items }
        }
        return []
    }

    private func competenciaIntercalable(estados: [String: EstadoCompetencia], enCurso: String?, usados: Set<String>,
                                         huellas: Set<String>, esReciente: (String) -> Bool,
                                         rng: inout some RandomNumberGenerator) -> Item? {
        let usadasEnRonda = Set(usados.compactMap { banco.item(id: $0)?.competencia })
        let opciones = estados.values
            .filter { $0.competenciaId != enCurso && $0.escalera.peldano >= config.peldanoMinimoIntercalado }
            .sorted { $0.competenciaId < $1.competenciaId }
        let preferidas = opciones.filter { !usadasEnRonda.contains($0.competenciaId) }
        for estado in (preferidas.isEmpty ? opciones : preferidas).shuffled(using: &rng) {
            let items = candidatos(competencia: estado.competenciaId, peldano: estado.escalera.peldano)
            if let item = elegir(items, usados: usados, huellas: huellas, esReciente: esReciente, rng: &rng) { return item }
        }
        return nil
    }

    /// Elige un ítem no usado y cuya pregunta no esté ya en la ronda, prefiriendo los no vistos
    /// recientemente. Con `permitirRecientes == false` nunca devuelve un ítem reciente.
    private func elegir(_ candidatos: [Item], usados: Set<String>, huellas: Set<String>, esReciente: (String) -> Bool,
                        permitirRecientes: Bool = true, rng: inout some RandomNumberGenerator) -> Item? {
        let libres = candidatos.filter { !usados.contains($0.id) && !huellas.contains(banco.huella($0)) }
        let frescos = libres.filter { !esReciente($0.id) }
        return (frescos.isEmpty && permitirRecientes ? libres : frescos).randomElement(using: &rng)
    }
}
