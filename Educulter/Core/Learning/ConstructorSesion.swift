import Foundation

/// Foco de la sesión diaria (05E parte 2 §3.1).
enum FocoSesion: String, Codable, Sendable, CaseIterable {
    case mixto, lengua, matematicas

    /// Área del catálogo (`nil` en Mixto).
    var area: String? {
        switch self {
        case .mixto: nil
        case .lengua: "LEN"
        case .matematicas: "MAT"
        }
    }

    var nombre: String {
        switch self {
        case .mixto: "Mixto"
        case .lengua: "Lengua"
        case .matematicas: "Matemáticas"
        }
    }
}

/// Duración de la sesión diaria: 5, 10 o 15 minutos.
enum DuracionSesion: Int, Codable, Sendable, CaseIterable {
    case cinco = 5, diez = 10, quince = 15

    /// Ítems por defecto (sin historial): 8, 15 y 22.
    var itemsPorDefecto: Int {
        switch self {
        case .cinco: 8
        case .diez: 15
        case .quince: 22
        }
    }
}

/// Remedio pendiente de un error activo: el error y la dificultad de sus ítems (un punto por debajo
/// de la del último fallo, mínimo 1).
struct RemedioPendiente: Sendable, Equatable {
    var error: ErrorTipico
    var dificultad: Int
}

/// Sesión diaria compuesta.
struct SesionDiaria: Sendable, Equatable {
    var items: [ItemRonda]
    /// Competencia del primer bloque nuevo (la competencia en curso).
    var competenciaEnCurso: String?
    var teoriaPrevia: [String]
    /// No hay nada que repasar ni plan: se lanza el diagnóstico.
    var requiereDiagnostico: Bool { items.isEmpty }
}

/// Composición de la sesión diaria (05E parte 2 §3.2, D-104). Determinista: el mismo estado y la
/// misma semilla dan la misma sesión.
///
/// Cupos sobre `n` ítems, por prioridad:
/// 1. **Remedios** de errores activos: como mucho `round(0,2·n)` ítems, en bloques de hasta 3 por error.
/// 2. **Repaso vencido** (Leitner), de lo más atrasado a lo más reciente: como mucho `⌊n/2⌋`, y
///    dejando sitio a lo nuevo.
/// 3. **Nuevo** según el plan: al menos `max(3, ⌈n/4⌉)` si hay plan, en bloques de 3 ítems seguidos
///    de la misma competencia. El hueco que sobra se rellena con más nuevo.
///
/// Orden: los bloques (remedio y nuevo) van seguidos; el resto se intercala sin más de 2 ítems
/// seguidos de la misma competencia ni, en Mixto, más de 3 seguidos de la misma área.
struct ConstructorSesion: Sendable {
    let banco: BancoContenido
    var config = ConfiguracionRonda.estandar
    static let tamanoBloque = 3
    static let maxSeguidosCompetencia = 2
    static let maxSeguidosArea = 3
    static let rangoItems = 6...30

    /// Ítems de una sesión: los de la duración o, con historial (al menos 10 intervalos entre
    /// respuestas seguidas de menos de 5 minutos), los minutos entre la mediana de los últimos 50
    /// intervalos, entre 6 y 30.
    static func numeroItems(_ duracion: DuracionSesion, intentos: [Intento]) -> Int {
        let fechas = intentos.map(\.fecha).sorted()
        let intervalos = zip(fechas, fechas.dropFirst()).map { $1.timeIntervalSince($0) }.filter { $0 > 0 && $0 < 300 }.suffix(50)
        guard intervalos.count >= 10 else { return duracion.itemsPorDefecto }
        let ordenados = intervalos.sorted()
        let mediana = ordenados.count % 2 == 1 ? ordenados[ordenados.count / 2]
            : (ordenados[ordenados.count / 2 - 1] + ordenados[ordenados.count / 2]) / 2
        let n = Int((Double(duracion.rawValue * 60) / mediana).rounded())
        return min(max(n, rangoItems.lowerBound), rangoItems.upperBound)
    }

    static func cupoRemedios(_ n: Int) -> Int { Int((Double(n) * 0.2).rounded()) }
    static func cupoRepaso(_ n: Int) -> Int { n / 2 }
    static func minimoNuevo(_ n: Int) -> Int { max(tamanoBloque, Int((Double(n) / 4).rounded(.up))) }

    /// `plan`: competencias para lo nuevo, en orden (la en curso primero; en Mixto, áreas alternadas).
    func construir(n: Int, foco: FocoSesion, estados: [String: EstadoCompetencia], remedios: [RemedioPendiente],
                   plan: [String], vistos: [String: Date], ahora: Date, calendario: Calendar, semilla: UInt64) -> SesionDiaria {
        var rng = GeneradorConSemilla(semilla: semilla)
        let hoy = DiaCivil(ahora, calendario: calendario)
        let enFoco: (String) -> Bool = { c in foco.area.map { Catalogo.area(de: c) == $0 } ?? true }
        let esReciente: (String) -> Bool = { id in vistos[id].map { ahora.timeIntervalSince($0) < config.segundosSinRepetir } ?? false }
        var usados = Set<String>(), huellas = Set<String>()
        func tomar(_ candidatos: [Item], _ cuantos: Int) -> [Item] {
            var r: [Item] = []
            let ordenados = candidatos.sorted { $0.id < $1.id }.shuffled(using: &rng)
            for permitirRecientes in [false, true] {
                for i in ordenados where r.count < cuantos && (permitirRecientes || !esReciente(i.id)) {
                    guard !usados.contains(i.id), !huellas.contains(banco.huella(i)) else { continue }
                    usados.insert(i.id)
                    huellas.insert(banco.huella(i))
                    r.append(i)
                }
            }
            return r
        }
        let rondas = ConstructorRondas(banco: banco, config: config)
        var unidades: [Unidad] = []

        // 1. Remedios.
        var cupo = Self.cupoRemedios(n)
        for r in remedios where cupo > 0 && enFoco(r.error.competencia) {
            guard let p = banco.plantilla(id: r.error.remedio.plantilla) else { continue }
            let ajustada = MotorGeneradores.ajustada(p, dificultad: min(max(r.dificultad, 1), 6))
            let items = tomar(banco.variantes(de: ajustada), min(Self.tamanoBloque, cupo))
            guard !items.isEmpty else { continue }
            cupo -= items.count
            unidades.append(Unidad(items.map { ItemRonda(itemId: $0.id, motivo: .remedio, errorId: r.error.id) },
                                   competencia: p.competencia, tipo: .remedio))
        }
        let ocupadoRemedios = unidades.reduce(0) { $0 + $1.items.count }

        // 3 (se reserva antes del repaso). Plan de lo nuevo con contenido.
        let planValido = plan.filter { enFoco($0) && banco.tieneItems(competencia: $0, peldanoMaximo: config.peldanoMaximoEnRonda) }
        let reservaNuevo = planValido.isEmpty ? 0 : min(Self.minimoNuevo(n), n - ocupadoRemedios)

        // 2. Repaso vencido, por turnos entre competencias (de la más atrasada a la más reciente).
        let vencidas = estados.values.filter { enFoco($0.competenciaId) && $0.vencida(hoy: hoy) }
            .sorted { ($0.leitner?.proximoRepaso ?? hoy, $0.competenciaId) < ($1.leitner?.proximoRepaso ?? hoy, $1.competenciaId) }
        let cupoRepaso = min(Self.cupoRepaso(n), max(0, n - ocupadoRemedios - reservaNuevo))
        var repasos: [Unidad] = []
        var agotadas = Set<String>()
        while repasos.count < cupoRepaso, agotadas.count < vencidas.count {
            for e in vencidas where repasos.count < cupoRepaso && !agotadas.contains(e.competenciaId) {
                let candidatos = rondas.candidatos(competencia: e.competenciaId, peldano: e.escalera.peldano)
                if let i = tomar(candidatos, 1).first {
                    repasos.append(Unidad([ItemRonda(itemId: i.id, motivo: .repaso)], competencia: e.competenciaId, tipo: .repaso))
                } else {
                    agotadas.insert(e.competenciaId)
                }
            }
        }
        unidades += repasos

        // 3. Nuevo: bloques de 3 de las competencias del plan, hasta llenar la sesión.
        var restante = n - unidades.reduce(0) { $0 + $1.items.count }
        var enCurso: String?
        var vueltas = 0
        while restante > 0, !planValido.isEmpty, vueltas < 3 {
            var anadido = false
            for c in planValido where restante > 0 {
                let peldano = estados[c]?.escalera.peldano ?? 1
                let items = tomar(rondas.candidatos(competencia: c, peldano: peldano), min(Self.tamanoBloque, restante))
                guard !items.isEmpty else { continue }
                enCurso = enCurso ?? c
                restante -= items.count
                anadido = true
                unidades.append(Unidad(items.sorted { ($0.dificultad, $0.id) < ($1.dificultad, $1.id) }
                                        .map { ItemRonda(itemId: $0.id, motivo: .nuevo) }, competencia: c, tipo: .nuevo))
            }
            vueltas += 1
            if !anadido { break }
        }

        let ordenadas = Self.ordenar(unidades, mixto: foco == .mixto, rng: &rng)
        var teoria: [String] = []
        if let enCurso, (estados[enCurso]?.escalera.peldano ?? 1) == Peldano.descubre.rawValue {
            teoria = banco.teoria(competencia: enCurso).map(\.id)
        }
        return SesionDiaria(items: ordenadas.flatMap(\.items), competenciaEnCurso: enCurso, teoriaPrevia: teoria)
    }

    // MARK: - Intercalado

    struct Unidad: Sendable, Equatable {
        enum Tipo: Int, Sendable { case remedio, repaso, nuevo }
        var items: [ItemRonda]
        var competencia: String
        var tipo: Tipo
        var area: String { Catalogo.area(de: competencia) }
        var esBloque: Bool { tipo != .repaso }

        init(_ items: [ItemRonda], competencia: String, tipo: Tipo) {
            self.items = items
            self.competencia = competencia
            self.tipo = tipo
        }
    }

    /// Ordena las unidades: en cada paso, la primera (remedios, después repasos y nuevo) que no rompe
    /// las reglas de intercalado, prefiriendo el área con más ítems por colocar para no quedarse al
    /// final con una sola. Si ninguna cabe (contenido de una sola área o competencia), se relaja.
    static func ordenar(_ unidades: [Unidad], mixto: Bool, rng: inout GeneradorConSemilla) -> [Unidad] {
        var pendientes = unidades.enumerated().map { ($0.offset, $0.element) }.shuffled(using: &rng)
        pendientes.sort { ($0.1.tipo.rawValue, $0.0) < ($1.1.tipo.rawValue, $1.0) }
        var secuencia: [Unidad] = []
        while !pendientes.isEmpty {
            let porArea = Dictionary(grouping: pendientes, by: { $0.1.area }).mapValues { $0.reduce(0) { $0 + $1.1.items.count } }
            let validas = pendientes.indices.filter { cabe(pendientes[$0].1, tras: secuencia, mixto: mixto) }
            let elegido = (validas.isEmpty ? Array(pendientes.indices) : validas)
                .min { (-(porArea[pendientes[$0].1.area] ?? 0), $0) < (-(porArea[pendientes[$1].1.area] ?? 0), $1) }!
            secuencia.append(pendientes.remove(at: elegido).1)
        }
        return secuencia
    }

    /// ¿Se puede poner la unidad a continuación sin romper las reglas?
    static func cabe(_ u: Unidad, tras secuencia: [Unidad], mixto: Bool) -> Bool {
        guard let ultima = secuencia.last else { return true }
        // Competencia: un bloque no se pega a la misma competencia; dos sueltos seguidos como mucho.
        if u.competencia == ultima.competencia {
            if u.esBloque || ultima.esBloque { return false }
            let suelto = secuencia.reversed().prefix { !$0.esBloque && $0.competencia == u.competencia }.count
            if suelto + 1 > maxSeguidosCompetencia { return false }
        }
        if mixto {
            let mismaArea = secuencia.reversed().prefix { $0.area == u.area }.reduce(0) { $0 + $1.items.count }
            if mismaArea + u.items.count > maxSeguidosArea { return false }
        }
        return true
    }

    /// Comprueba las reglas de intercalado sobre una sesión ya compuesta (para los tests).
    static func incumplimientos(_ items: [ItemRonda], competencia: (ItemRonda) -> String, mixto: Bool) -> [String] {
        var fallos: [String] = []
        var i = 0
        while i < items.count {
            var j = i
            while j + 1 < items.count, competencia(items[j + 1]) == competencia(items[i]) { j += 1 }
            let run = items[i...j]
            let bloque = run.allSatisfy { $0.motivo == .nuevo || $0.motivo == .remedio } && run.count <= tamanoBloque
            if run.count > maxSeguidosCompetencia && !bloque { fallos.append("\(run.count) seguidos de \(competencia(items[i])) en \(i)") }
            i = j + 1
        }
        if mixto {
            var k = 0
            while k < items.count {
                var j = k
                while j + 1 < items.count, Catalogo.area(de: competencia(items[j + 1])) == Catalogo.area(de: competencia(items[k])) { j += 1 }
                if j - k + 1 > maxSeguidosArea { fallos.append("\(j - k + 1) seguidos del área \(Catalogo.area(de: competencia(items[k]))) en \(k)") }
                k = j + 1
            }
        }
        return fallos
    }
}
