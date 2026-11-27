import Foundation
import SwiftData

// Modelos SwiftData del progreso, diseñados compatibles con CloudKit aunque la
// sincronización no está activada (D-004, D-022):
// - todas las propiedades tienen valor por defecto o son opcionales;
// - no se usa `@Attribute(.unique)`;
// - no hay relaciones (si se añaden, deberán ser opcionales).
// Los valores compuestos (métricas, diagnóstico) se guardan como JSON en `Data`.

@Model
final class IntentoRegistro {
    var uuid: UUID = UUID()
    var fecha: Date = Date.distantPast
    var itemId: String = ""
    var competenciaId: String = ""
    var peldano: Int = 1
    var correcto: Bool = false
    var fraccionCorrecta: Double = 0
    var usoPista: Bool = false
    var confianza: Int?
    var xp: Int = 0
    var motivo: String?

    init(_ i: Intento) {
        uuid = i.id
        fecha = i.fecha
        itemId = i.itemId
        competenciaId = i.competenciaId
        peldano = i.peldano
        correcto = i.correcto
        fraccionCorrecta = i.fraccionCorrecta
        usoPista = i.usoPista
        confianza = i.confianza
        xp = i.xp
        motivo = i.motivo?.rawValue
    }

    var valor: Intento {
        Intento(id: uuid, fecha: fecha, itemId: itemId, competenciaId: competenciaId, peldano: peldano,
                correcto: correcto, fraccionCorrecta: fraccionCorrecta, usoPista: usoPista, confianza: confianza,
                xp: xp, motivo: motivo.flatMap(ItemRonda.Motivo.init(rawValue:)))
    }
}

@Model
final class EstadoCompetenciaRegistro {
    var competenciaId: String = ""
    var peldano: Int = 1
    /// Ventana de intentos del peldaño como texto ("1101": acierto, acierto, fallo, acierto).
    var ventana: String = ""
    var caja: Int?
    /// Días civiles como clave AAAAMMDD.
    var proximoRepaso: Int?
    var ultimoRepaso: Int?

    init(competenciaId: String) {
        self.competenciaId = competenciaId
    }

    func actualizar(con e: EstadoCompetencia) {
        competenciaId = e.competenciaId
        peldano = e.escalera.peldano
        ventana = String(e.escalera.ventana.map { $0 ? "1" : "0" })
        caja = e.leitner?.caja
        proximoRepaso = e.leitner?.proximoRepaso.clave
        ultimoRepaso = e.leitner?.ultimoRepaso?.clave
    }

    var valor: EstadoCompetencia {
        var leitner: EstadoLeitner?
        if let caja, let clave = proximoRepaso, let proximo = DiaCivil(clave: clave) {
            leitner = EstadoLeitner(caja: caja, proximoRepaso: proximo, ultimoRepaso: ultimoRepaso.flatMap(DiaCivil.init(clave:)))
        }
        return EstadoCompetencia(competenciaId: competenciaId,
                                 escalera: EstadoEscalera(peldano: peldano, ventana: ventana.map { $0 == "1" }),
                                 leitner: leitner)
    }
}

@Model
final class RescateRegistro {
    var itemId: String = ""
    var competenciaId: String = ""
    var peldano: Int = 1
    var fecha: Date = Date.distantPast
    /// Posición en la cola (orden de llegada).
    var posicion: Int = 0

    init(_ e: EntradaRescate, posicion: Int) {
        itemId = e.itemId
        competenciaId = e.competencia
        peldano = e.peldano
        fecha = e.fecha
        self.posicion = posicion
    }

    var valor: EntradaRescate {
        EntradaRescate(itemId: itemId, competencia: competenciaId, peldano: peldano, fecha: fecha)
    }
}

@Model
final class PerfilRegistro {
    var xpTotal: Int = 0
    var rachaActual: Int = 0
    var rachaRecord: Int = 0
    var protectores: Int = 2
    var ultimoDiaActivo: Int?
    var ultimoDiaProcesado: Int?
    var metricasJSON: Data?
    var competenciaEnCurso: String?
    var avatar: Int?
    /// Desbloqueos por prueba de nivel (JSON, Fase 05D).
    var desbloqueosJSON: Data?
    /// Días de sesión y periodos de descanso (JSON, 05E parte 2 §3.3).
    var diasJSON: Data?

    private struct Dias: Codable {
        var sesion: [DiaCivil]
        var descanso: [PeriodoDescanso]
    }

    init() {}

    func actualizar(con p: PerfilJugador) throws {
        xpTotal = p.xpTotal
        rachaActual = p.racha.actual
        rachaRecord = p.racha.record
        protectores = p.racha.protectores
        ultimoDiaActivo = p.racha.ultimoDiaActivo?.clave
        ultimoDiaProcesado = p.racha.ultimoDiaProcesado?.clave
        competenciaEnCurso = p.competenciaEnCurso
        avatar = p.avatar
        desbloqueosJSON = try JSONEncoder().encode(p.desbloqueos)
        diasJSON = try JSONEncoder().encode(Dias(sesion: p.diasSesion, descanso: p.racha.descanso))
        metricasJSON = try JSONEncoder().encode(Dictionary(uniqueKeysWithValues: p.metricas.map { ($0.key.rawValue, $0.value) }))
    }

    func valor() throws -> PerfilJugador {
        let crudas = try metricasJSON.map { try JSONDecoder().decode([String: Int].self, from: $0) } ?? [:]
        let metricas = Dictionary(uniqueKeysWithValues: crudas.compactMap { k, v in Metrica(rawValue: k).map { ($0, v) } })
        let dias = try diasJSON.map { try JSONDecoder().decode(Dias.self, from: $0) }
        var racha = EstadoRacha(actual: rachaActual, record: rachaRecord, protectores: protectores,
                                ultimoDiaActivo: ultimoDiaActivo.flatMap(DiaCivil.init(clave:)),
                                ultimoDiaProcesado: ultimoDiaProcesado.flatMap(DiaCivil.init(clave:)))
        racha.descanso = dias?.descanso ?? []
        return PerfilJugador(xpTotal: xpTotal, racha: racha, metricas: metricas,
                             competenciaEnCurso: competenciaEnCurso, avatar: Avatar.migrar(avatar),
                             desbloqueos: try desbloqueosJSON.map { try JSONDecoder().decode([Desbloqueo].self, from: $0) } ?? [],
                             diasSesion: dias?.sesion ?? [])
    }
}

@Model
final class LogroRegistro {
    var logroId: String = ""
    var fecha: Date = Date.distantPast

    init(_ l: LogroObtenido) {
        logroId = l.logroId
        fecha = l.fecha
    }
}

@Model
final class DiagnosticoRegistro {
    var fecha: Date = Date.distantPast
    var datos: Data?

    init(fecha: Date, datos: Data?) {
        self.fecha = fecha
        self.datos = datos
    }
}

/// Partida de Supervivencia (Fase 05D): el valor completo en JSON y la fecha para ordenar.
@Model
final class PartidaRegistro {
    var uuid: UUID = UUID()
    var inicio: Date = Date.distantPast
    var datos: Data?

    init(uuid: UUID, inicio: Date, datos: Data?) {
        self.uuid = uuid
        self.inicio = inicio
        self.datos = datos
    }
}

/// Ajustes del usuario (Fase 05D), en JSON.
@Model
final class AjustesRegistro {
    var datos: Data?

    init(datos: Data?) {
        self.datos = datos
    }
}

/// Suceso del motor de errores (05E parte 2 §4): solo se añaden, nunca se modifican.
@Model
final class EventoErrorRegistro {
    var uuid: UUID = UUID()
    var fecha: Date = Date.distantPast
    var errorId: String = ""
    var tipo: String = EventoError.Tipo.fallo.rawValue
    var itemId: String = ""

    init(_ e: EventoError) {
        uuid = e.id
        fecha = e.fecha
        errorId = e.errorId
        tipo = e.tipo.rawValue
        itemId = e.itemId
    }

    var valor: EventoError? {
        EventoError.Tipo(rawValue: tipo).map { EventoError(id: uuid, fecha: fecha, errorId: errorId, tipo: $0, itemId: itemId) }
    }
}

/// Intento de un juego (contrato de intento, 05G §2): el valor codificado en JSON. Sin relaciones y
/// con valores por defecto (compatible con CloudKit); solo se añaden, nunca se modifican.
@Model
final class IntentoActividadRegistro {
    var uuid: UUID = UUID()
    var fecha: Date = Date.distantPast
    var datos: Data?

    init(uuid: UUID, fecha: Date, datos: Data?) {
        self.uuid = uuid
        self.fecha = fecha
        self.datos = datos
    }
}

/// Examen del Tribunal (05I): la sesión entera en JSON (compatible con CloudKit).
@Model
final class ExamenTribunalRegistro {
    var uuid: UUID = UUID()
    var inicio: Date = Date.distantPast
    var datos: Data?

    init(uuid: UUID, inicio: Date, datos: Data?) {
        self.uuid = uuid
        self.inicio = inicio
        self.datos = datos
    }
}

/// Esquema y contenedor del progreso.
enum EsquemaProgreso {
    static var modelos: [any PersistentModel.Type] {
        [IntentoRegistro.self, EstadoCompetenciaRegistro.self, RescateRegistro.self,
         PerfilRegistro.self, LogroRegistro.self, DiagnosticoRegistro.self, PartidaRegistro.self, AjustesRegistro.self,
         EventoErrorRegistro.self, IntentoActividadRegistro.self, ExamenTribunalRegistro.self]
    }

    /// Contenedor local (sin CloudKit). `enMemoria` para tests.
    static func contenedor(enMemoria: Bool = false) throws -> ModelContainer {
        let configuracion = ModelConfiguration(
            "Progreso", schema: Schema(modelos), isStoredInMemoryOnly: enMemoria, cloudKitDatabase: .none
        )
        return try ModelContainer(for: Schema(modelos), configurations: configuracion)
    }

    /// Contenedor en un archivo concreto (tests de persistencia en disco).
    static func contenedor(url: URL) throws -> ModelContainer {
        let configuracion = ModelConfiguration("Progreso", schema: Schema(modelos), url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: Schema(modelos), configurations: configuracion)
    }
}
