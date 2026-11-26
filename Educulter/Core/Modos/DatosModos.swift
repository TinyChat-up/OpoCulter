import Foundation

/// Ajustes del usuario (Progreso → Ajustes). Se guardan en SwiftData (`AjustesRegistro`).
struct Ajustes: Codable, Sendable, Equatable {
    var sonido = true
    var vibracion = true
    var recordatorio = false
    /// Hora del recordatorio en minutos desde medianoche (20:00 por defecto).
    var minutoRecordatorio = 20 * 60
    /// Ya se ha preguntado por el recordatorio tras la primera ronda (se pregunta una sola vez).
    var recordatorioPreguntado = false
    /// Sesión diaria (05E parte 2 §3): duración y foco recordados, y meta semanal (3–7 días).
    var duracion = DuracionSesion.diez
    var foco = FocoSesion.mixto
    var metaSemanal = MetaSemanal.porDefecto

    init(sonido: Bool = true, vibracion: Bool = true, recordatorio: Bool = false, minutoRecordatorio: Int = 20 * 60,
         recordatorioPreguntado: Bool = false, duracion: DuracionSesion = .diez, foco: FocoSesion = .mixto,
         metaSemanal: Int = MetaSemanal.porDefecto) {
        self.sonido = sonido
        self.vibracion = vibracion
        self.recordatorio = recordatorio
        self.minutoRecordatorio = minutoRecordatorio
        self.recordatorioPreguntado = recordatorioPreguntado
        self.duracion = duracion
        self.foco = foco
        self.metaSemanal = metaSemanal
    }

    private enum CodingKeys: String, CodingKey {
        case sonido, vibracion, recordatorio, minutoRecordatorio, recordatorioPreguntado, duracion, foco, metaSemanal
    }

    /// Los ajustes guardados por versiones anteriores no tienen las claves nuevas: se leen con su valor por defecto.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Ajustes()
        sonido = try c.decodeIfPresent(Bool.self, forKey: .sonido) ?? d.sonido
        vibracion = try c.decodeIfPresent(Bool.self, forKey: .vibracion) ?? d.vibracion
        recordatorio = try c.decodeIfPresent(Bool.self, forKey: .recordatorio) ?? d.recordatorio
        minutoRecordatorio = try c.decodeIfPresent(Int.self, forKey: .minutoRecordatorio) ?? d.minutoRecordatorio
        recordatorioPreguntado = try c.decodeIfPresent(Bool.self, forKey: .recordatorioPreguntado) ?? d.recordatorioPreguntado
        duracion = try c.decodeIfPresent(DuracionSesion.self, forKey: .duracion) ?? d.duracion
        foco = try c.decodeIfPresent(FocoSesion.self, forKey: .foco) ?? d.foco
        metaSemanal = try c.decodeIfPresent(Int.self, forKey: .metaSemanal) ?? d.metaSemanal
    }

    var hora: Int { minutoRecordatorio / 60 }
    var minuto: Int { minutoRecordatorio % 60 }
    var horaTexto: String { String(format: "%02d:%02d", hora, minuto) }
}

/// Competencia abierta con una prueba de nivel (peldaños 1–2 superados). Queda registrado.
struct Desbloqueo: Codable, Sendable, Equatable {
    var competenciaId: String
    var fecha: Date
    var aciertos: Int
    var total: Int
}

/// Partida de Supervivencia guardada con su historial.
struct PartidaSupervivencia: Codable, Sendable, Equatable, Identifiable {
    struct Jugada: Codable, Sendable, Equatable {
        var itemId: String
        var bloqueId: String
        var dificultad: Int
        var correcto: Bool
        var puntos: Int
    }

    var id = UUID()
    var inicio: Date
    var fin: Date?
    /// `LEN`, `MAT` o `nil` (mixta).
    var area: String?
    var puntos = 0
    var nivelMaximo = 1
    var aciertos = 0
    var fallos = 0
    var abandonada = false
    var jugadas: [Jugada] = []

    /// Las partidas abandonadas guardan lo jugado pero no cuentan para el récord.
    var cuentaParaRecord: Bool { !abandonada && fin != nil }
}

/// Récords de Supervivencia (solo partidas terminadas, no abandonadas).
struct RecordsSupervivencia: Sendable, Equatable {
    var global: PartidaSupervivencia?
    var porArea: [String: PartidaSupervivencia] = [:]

    init(partidas: [PartidaSupervivencia]) {
        let validas = partidas.filter(\.cuentaParaRecord)
        global = validas.max { ($0.puntos, $1.inicio) < ($1.puntos, $0.inicio) }
        for clave in ["LEN", "MAT", "MIX"] {
            porArea[clave] = validas.filter { ($0.area ?? "MIX") == clave }.max { ($0.puntos, $1.inicio) < ($1.puntos, $0.inicio) }
        }
    }
}
