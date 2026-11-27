import Foundation

// MARK: - Catálogo y datos (05J §3)

/// `tribunal/originales/Catalogo-tribunal.json`: los simulacros originales escritos, con su revisión,
/// su acceso y la huella SHA-256 del archivo de datos tal como está guardado.
struct CatalogoTribunal: Codable, Sendable, Equatable {
    struct Entrada: Codable, Sendable, Equatable, Identifiable {
        var id: String
        var titulo: String
        var revision: Int
        var procedencia: String
        /// `muestra` (gratis, en los dos formatos) o `tribunal` (Premium).
        var acceso: String
        var duracionSegundos: Int
        var datos: String
        var sha256Datos: String

        var esMuestra: Bool { acceso == "muestra" }
        var minutos: Int { duracionSegundos / 60 }
    }

    var esquema: Int
    var simulacros: [Entrada]
}

/// Un simulacro escrito original (DTO propio, sin relación con el banco de ítems). Se reproduce tal
/// como lo aprobó la dirección; la app no reescribe enunciados, soluciones ni criterios.
struct SimulacroEscrito: Codable, Sendable, Equatable, Identifiable {
    struct Criterio: Codable, Sendable, Equatable {
        /// Centésimas de punto (20, 20, 10).
        var puntos: Int
        var criterio: String
    }

    struct Pregunta: Codable, Sendable, Equatable, Identifiable {
        /// Id estable dentro del simulacro: L01…L10, M01…M10.
        var id: String
        var enunciado: String
        var solucion: String
        var rubrica: [Criterio]

        var area: String { id.hasPrefix("L") ? "LEN" : "MAT" }
        var maximo: Int { rubrica.reduce(0) { $0 + $1.puntos } }
    }

    var id: String
    var titulo: String
    var texto: String
    var lengua: [Pregunta]
    var matematicas: [Pregunta]

    var preguntas: [Pregunta] { lengua + matematicas }
    func pregunta(_ id: String) -> Pregunta? { preguntas.first { $0.id == id } }
    func maximo(area: String) -> Int { preguntas.filter { $0.area == area }.reduce(0) { $0 + $1.maximo } }
}

/// Simulacro del catálogo con sus datos cargados.
struct SimulacroOriginal: Sendable, Equatable, Identifiable {
    var entrada: CatalogoTribunal.Entrada
    var datos: SimulacroEscrito

    var id: String { entrada.id }
    /// La muestra se puntúa sobre 2; el simulacro completo, sobre 10.
    var maximo: Int { datos.preguntas.reduce(0) { $0 + $1.maximo } }
    var etiqueta: String { "Simulacro original Educulter" }
}

// MARK: - Intento (05J §3)

/// Un intento de un simulacro escrito: en la app (con teclado), en papel (cuenta atrás y marcas) o
/// la corrección de una prueba hecha en papel sin tiempo (`inicio == nil`, duración desconocida).
/// Cada intento se guarda aparte; el reloj se calcula desde la hora de inicio guardada, así que no
/// se detiene al salir de la app.
struct IntentoEscrito: Codable, Sendable, Equatable, Identifiable {
    enum Formato: String, Codable, Sendable { case app, papel }
    enum EstadoPregunta: Sendable, Equatable { case sinResponder, marcada, respondida }

    var id = UUID()
    var simulacro: String
    var revision: Int
    var formato: Formato
    /// `nil`: prueba hecha en papel que se corrige sin tiempo.
    var inicio: Date?
    var duracionSegundos: Int
    var entrega: Date?
    var entregaAutomatica = false
    /// Respuesta escrita de cada pregunta (solo en la app).
    var respuestas: [String: String] = [:]
    /// Preguntas marcadas para revisar (independiente de estar respondida).
    var marcas: Set<String> = []
    /// Criterios cumplidos de cada pregunta ya corregida (en el orden de la rúbrica).
    var criterios: [String: [Bool]] = [:]
    /// Faltas de ortografía contadas por el usuario (palabras distintas) y tildes.
    var faltasPalabras = 0
    var faltasTildes = 0
    var aplicarPenalizacion = true
    /// Borrador (PencilKit) de cada pregunta.
    var borradores: [String: Data] = [:]
    var actual: String?
    var relojOculto = false

    init(simulacro: String, revision: Int, formato: Formato, inicio: Date?, duracionSegundos: Int) {
        self.simulacro = simulacro
        self.revision = revision
        self.formato = formato
        self.inicio = inicio
        self.duracionSegundos = duracionSegundos
    }

    var entregado: Bool { entrega != nil }
    var cronometrado: Bool { inicio != nil }
    /// En curso: empezado, con reloj y sin entregar.
    var activo: Bool { inicio != nil && entrega == nil }

    /// Segundos que quedan, calculados desde la hora de inicio.
    func restante(_ ahora: Date) -> Int {
        guard let inicio else { return 0 }
        if let entrega { return max(0, duracionSegundos - Int(entrega.timeIntervalSince(inicio))) }
        return max(0, duracionSegundos - Int(ahora.timeIntervalSince(inicio).rounded(.down)))
    }

    /// Duración real del intento (`nil` si se corrige una prueba hecha en papel sin tiempo).
    var duracionReal: Int? {
        guard let inicio, let entrega else { return nil }
        return min(duracionSegundos, Int(entrega.timeIntervalSince(inicio)))
    }

    /// Entrega sola si el tiempo se acabó (también si la app estaba cerrada: la entrega queda en la
    /// hora exacta en que terminó el tiempo). Devuelve `true` si acaba de entregarse.
    @discardableResult
    mutating func comprobarTiempo(_ ahora: Date) -> Bool {
        guard activo, let inicio, restante(ahora) == 0 else { return false }
        entrega = inicio.addingTimeInterval(TimeInterval(duracionSegundos))
        entregaAutomatica = true
        return true
    }

    /// Entrega (una sola vez: entregar de nuevo no cambia nada).
    mutating func entregar(_ ahora: Date) {
        guard entrega == nil else { return }
        if comprobarTiempo(ahora) { return }
        entrega = ahora
    }

    func respondida(_ id: String) -> Bool { !(respuestas[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func estado(_ id: String) -> EstadoPregunta {
        if marcas.contains(id) { return .marcada }
        return respondida(id) ? .respondida : .sinResponder
    }

    func corregida(_ id: String) -> Bool { criterios[id] != nil }
}

// MARK: - Corrección en centésimas (05J §1)

/// Resultado de un intento: centésimas enteras; solo se redondea al mostrar.
struct ResultadoEscrito: Sendable, Equatable {
    /// Centésimas por área («LEN», «MAT»); `nil` si alguna pregunta del área está sin corregir.
    var areas: [String: Int?]
    var maximoArea: [String: Int]
    /// Total sin penalización; `nil` = revisión pendiente.
    var total: Int?
    var maximo: Int
    /// Penalización ortográfica en centésimas (según las bases de 2026), aparte.
    var penalizacion: Int
    var aplicarPenalizacion: Bool
    var pendientes: [String]

    var revisionPendiente: Bool { total == nil }
    var totalConPenalizacion: Int? { total.map { aplicarPenalizacion ? max(0, $0 - penalizacion) : $0 } }

    static let etiquetaPenalizacion = "Según las bases de 2026 (BOCM nº 36, 12/02/2026)"
}

enum CorrectorEscrito {
    static func puntos(_ p: SimulacroEscrito.Pregunta, criterios: [Bool]?) -> Int? {
        guard let criterios else { return nil }
        return zip(p.rubrica, criterios).reduce(0) { $0 + ($1.1 ? $1.0.puntos : 0) }
    }

    /// Penalización en centésimas: −0,50 por palabra y −0,25 por tilde (bases de 2026).
    static func penalizacion(palabras: Int, tildes: Int, reglas: ReglasOrtografia = .bases2026) -> Int {
        let total = palabras * Int((reglas.palabraIncorrecta * 100).rounded()) + tildes * Int((reglas.tilde * 100).rounded())
        return reglas.limite.map { min(Int(($0 * 100).rounded()), total) } ?? total
    }

    static func corregir(_ i: IntentoEscrito, simulacro s: SimulacroEscrito, reglas: ReglasOrtografia = .bases2026) -> ResultadoEscrito {
        var areas: [String: Int?] = [:]
        var maximos: [String: Int] = [:]
        var pendientes: [String] = []
        for area in ["LEN", "MAT"] {
            let ps = s.preguntas.filter { $0.area == area }
            guard !ps.isEmpty else { continue }
            maximos[area] = ps.reduce(0) { $0 + $1.maximo }
            var suma: Int? = 0
            for p in ps {
                if let v = puntos(p, criterios: i.criterios[p.id]) { suma = suma.map { $0 + v } } else { suma = nil; pendientes.append(p.id) }
            }
            areas[area] = suma
        }
        let total: Int? = areas.values.contains { $0 == nil } ? nil : areas.values.reduce(0) { $0 + ($1 ?? 0) }
        return ResultadoEscrito(areas: areas, maximoArea: maximos, total: total, maximo: maximos.values.reduce(0, +),
                                penalizacion: penalizacion(palabras: i.faltasPalabras, tildes: i.faltasTildes, reglas: reglas),
                                aplicarPenalizacion: i.aplicarPenalizacion, pendientes: pendientes)
    }

    /// «12,50»: centésimas como puntos con dos decimales y coma (solo al mostrar).
    static func texto(_ centesimas: Int) -> String {
        let signo = centesimas < 0 ? "−" : ""
        let v = abs(centesimas)
        return "\(signo)\(v / 100),\(String(format: "%02d", v % 100))"
    }

    /// Hasta 2 prioridades: las competencias del mapa de repaso con más centésimas perdidas en las
    /// preguntas corregidas (a igualdad, la primera del examen).
    static func prioridades(_ i: IntentoEscrito, simulacro s: SimulacroEscrito, mapa: [String: String]) -> [String] {
        var perdidas: [String: Int] = [:]
        var orden: [String] = []
        for p in s.preguntas {
            guard let v = puntos(p, criterios: i.criterios[p.id]), v < p.maximo, let c = mapa[MapaRepaso.clave(s.id, p.id)] else { continue }
            if perdidas[c] == nil { orden.append(c) }
            perdidas[c, default: 0] += p.maximo - v
        }
        return orden.enumerated().sorted { (perdidas[$0.element]!, -$0.offset) > (perdidas[$1.element]!, -$1.offset) }.prefix(2).map(\.element)
    }
}

/// `tribunal/originales/Mapa-de-repaso.csv`: competencia principal de cada pregunta (ANEXO C).
enum MapaRepaso {
    static func clave(_ simulacro: String, _ pregunta: String) -> String { "\(simulacro)/\(pregunta)" }

    static func leer(_ csv: String) -> [String: String] {
        var mapa: [String: String] = [:]
        for linea in csv.split(whereSeparator: \.isNewline).dropFirst() {
            let c = linea.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard c.count == 3 else { continue }
            mapa[clave(c[0], c[1])] = c[2]
        }
        return mapa
    }
}

// MARK: - Acceso (05J §1)

/// Punto único de decisión del acceso al Tribunal: un solo Premium (sin anuncios y Tribunal
/// completo). La muestra (SIM.DEMO.01) es gratis en los dos formatos; sin derecho, un simulacro de
/// pago no se hace, ni se imprime ni se comparte. El Tribunal nunca muestra anuncios.
enum AccesoTribunal {
    enum Acceso: Sendable, Equatable { case permitido, soloPremium }

    /// Derecho Premium. Hasta la fase de compras (StoreKit 2), la beta lo concede (D-137).
    static let premium = true

    static func acceso(_ entrada: CatalogoTribunal.Entrada, premium: Bool = AccesoTribunal.premium) -> Acceso {
        entrada.esMuestra || premium ? .permitido : .soloPremium
    }

    /// Exámenes oficiales (modo examen) y bloques: con el Premium.
    static func acceso(_ modo: SesionExamen.Modo, premium: Bool = AccesoTribunal.premium) -> Acceso {
        premium ? .permitido : .soloPremium
    }
}
