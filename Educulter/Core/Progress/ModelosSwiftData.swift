import Foundation
import SwiftData

// Modelos SwiftData del progreso, diseñados compatibles con CloudKit aunque la
// sincronización no está activada (D-004, D-022):
// - todas las propiedades tienen valor por defecto o son opcionales;
// - no se usa `@Attribute(.unique)`;
// - no hay relaciones (si se añaden, deberán ser opcionales).
// Los valores compuestos (misiones, métricas, diagnóstico) se guardan como JSON en `Data`.

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
    var diaMisiones: Int?
    var misionesJSON: Data?
    var metricasJSON: Data?
    var competenciaEnCurso: String?
    var avatar: Int?
    /// Desbloqueos por prueba de nivel (JSON, Fase 05D).
    var desbloqueosJSON: Data?

    init() {}

    func actualizar(con p: PerfilJugador) throws {
        xpTotal = p.xpTotal
        rachaActual = p.racha.actual
        rachaRecord = p.racha.record
        protectores = p.racha.protectores
        ultimoDiaActivo = p.racha.ultimoDiaActivo?.clave
        ultimoDiaProcesado = p.racha.ultimoDiaProcesado?.clave
        diaMisiones = p.diaMisiones?.clave
        competenciaEnCurso = p.competenciaEnCurso
        avatar = p.avatar
        misionesJSON = try JSONEncoder().encode(p.misiones)
        desbloqueosJSON = try JSONEncoder().encode(p.desbloqueos)
        metricasJSON = try JSONEncoder().encode(Dictionary(uniqueKeysWithValues: p.metricas.map { ($0.key.rawValue, $0.value) }))
    }

    func valor() throws -> PerfilJugador {
        let misiones = try misionesJSON.map { try JSONDecoder().decode([Mision].self, from: $0) } ?? []
        let crudas = try metricasJSON.map { try JSONDecoder().decode([String: Int].self, from: $0) } ?? [:]
        let metricas = Dictionary(uniqueKeysWithValues: crudas.compactMap { k, v in Metrica(rawValue: k).map { ($0, v) } })
        let racha = EstadoRacha(actual: rachaActual, record: rachaRecord, protectores: protectores,
                                ultimoDiaActivo: ultimoDiaActivo.flatMap(DiaCivil.init(clave:)),
                                ultimoDiaProcesado: ultimoDiaProcesado.flatMap(DiaCivil.init(clave:)))
        return PerfilJugador(xpTotal: xpTotal, racha: racha, misiones: misiones,
                             diaMisiones: diaMisiones.flatMap(DiaCivil.init(clave:)), metricas: metricas,
                             competenciaEnCurso: competenciaEnCurso, avatar: Avatar.migrar(avatar),
                             desbloqueos: try desbloqueosJSON.map { try JSONDecoder().decode([Desbloqueo].self, from: $0) } ?? [])
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

/// Esquema y contenedor del progreso.
enum EsquemaProgreso {
    static var modelos: [any PersistentModel.Type] {
        [IntentoRegistro.self, EstadoCompetenciaRegistro.self, RescateRegistro.self,
         PerfilRegistro.self, LogroRegistro.self, DiagnosticoRegistro.self, PartidaRegistro.self, AjustesRegistro.self]
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
