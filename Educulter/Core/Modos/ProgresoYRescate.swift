import Foundation

/// Errores pendientes de una competencia (pantalla de Rescate).
struct GrupoRescate: Sendable, Equatable, Identifiable {
    var competencia: Catalogo.Competencia
    var area: String
    var entradas: [EntradaRescate]
    var ultimo: Date

    var id: String { competencia.id }
    var cantidad: Int { entradas.count }

    /// Agrupa la cola por competencia (la del error más reciente primero).
    static func agrupar(_ cola: ColaRescate, catalogo: Catalogo) -> [GrupoRescate] {
        Dictionary(grouping: cola.entradas, by: \.competencia).compactMap { id, entradas in
            guard let c = catalogo.todasLasCompetencias.first(where: { $0.id == id }) else { return nil }
            return GrupoRescate(competencia: c, area: Catalogo.area(de: id), entradas: entradas,
                                ultimo: entradas.map(\.fecha).max() ?? .distantPast)
        }
        .sorted { ($0.ultimo, $0.id) > ($1.ultimo, $1.id) }
    }
}

/// Estadísticas de la pestaña Progreso, calculadas solo a partir del historial real.
struct EstadisticasProgreso: Sendable, Equatable {
    struct Dia: Sendable, Equatable, Identifiable {
        var dia: DiaCivil
        var fecha: Date
        var aciertos: Int
        var respondidos: Int
        var xp: Int
        var id: Int { dia.clave }
    }

    struct Area: Sendable, Equatable {
        var respondidos: Int
        var aciertos: Int
        var porcentaje: Double? { respondidos == 0 ? nil : Double(aciertos) / Double(respondidos) }
    }

    /// Últimos `dias` días (28 por defecto), del más antiguo a hoy, incluidos los días sin actividad.
    var evolucion: [Dia]
    var porArea: [String: Area]
    var respondidos: Int
    var aciertos: Int
    var rachaActual: Int
    var rachaRecord: Int
    var recordSupervivencia: Int?

    init(intentos: [Intento], perfil: PerfilJugador, partidas: [PartidaSupervivencia], hoy: DiaCivil,
         calendario: Calendar, dias: Int = 28) {
        var porDia: [Int: (Int, Int, Int)] = [:]
        for i in intentos {
            let k = DiaCivil(i.fecha, calendario: calendario).clave
            let v = porDia[k] ?? (0, 0, 0)
            porDia[k] = (v.0 + (i.correcto ? 1 : 0), v.1 + 1, v.2 + i.xp)
        }
        evolucion = (0..<dias).reversed().map { atras in
            let d = hoy.sumando(dias: -atras)
            let v = porDia[d.clave] ?? (0, 0, 0)
            return Dia(dia: d, fecha: d.fecha(calendario: calendario), aciertos: v.0, respondidos: v.1, xp: v.2)
        }
        var areas: [String: Area] = ["LEN": Area(respondidos: 0, aciertos: 0), "MAT": Area(respondidos: 0, aciertos: 0)]
        for i in intentos {
            let a = Catalogo.area(de: i.competenciaId)
            var v = areas[a] ?? Area(respondidos: 0, aciertos: 0)
            v.respondidos += 1
            if i.correcto { v.aciertos += 1 }
            areas[a] = v
        }
        porArea = areas
        respondidos = intentos.count
        aciertos = intentos.filter(\.correcto).count
        let racha = perfil.racha.vigente(hoy: hoy)
        rachaActual = racha.actual
        rachaRecord = max(racha.record, perfil.racha.record)
        recordSupervivencia = RecordsSupervivencia(partidas: partidas).global?.puntos
    }
}
