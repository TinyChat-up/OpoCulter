import Foundation
import SwiftData

/// Repositorio de progreso sobre SwiftData.
///
/// Como no se usa `.unique` (requisito de CloudKit), los "singletons" (perfil, diagnóstico) y
/// las claves naturales (competencia, logro) se buscan con un predicado y se reutiliza el
/// primer registro. Si una futura sincronización crea duplicados, se toma el más avanzado.
@MainActor
final class RepositorioSwiftData: RepositorioProgreso {
    /// Se retiene el contenedor: si se libera, su `mainContext` deja de ser válido.
    let contenedor: ModelContainer
    let contexto: ModelContext

    init(contenedor: ModelContainer) {
        self.contenedor = contenedor
        contexto = contenedor.mainContext
    }

    func registrarIntento(_ intento: Intento) throws {
        contexto.insert(IntentoRegistro(intento))
        try contexto.save()
    }

    func intentos(desde: Date?) throws -> [Intento] {
        var descriptor = FetchDescriptor<IntentoRegistro>(sortBy: [SortDescriptor(\.fecha)])
        if let desde {
            descriptor.predicate = #Predicate { $0.fecha >= desde }
        }
        return try contexto.fetch(descriptor).map(\.valor)
    }

    func estadosCompetencia() throws -> [String: EstadoCompetencia] {
        let registros = try contexto.fetch(FetchDescriptor<EstadoCompetenciaRegistro>())
        var resultado: [String: EstadoCompetencia] = [:]
        for r in registros {
            let valor = r.valor
            if let previo = resultado[valor.competenciaId], previo.escalera.peldano >= valor.escalera.peldano { continue }
            resultado[valor.competenciaId] = valor
        }
        return resultado
    }

    func guardar(_ estado: EstadoCompetencia) throws {
        let id = estado.competenciaId
        let existente = try contexto.fetch(FetchDescriptor<EstadoCompetenciaRegistro>(predicate: #Predicate { $0.competenciaId == id })).first
        let registro = existente ?? EstadoCompetenciaRegistro(competenciaId: id)
        if existente == nil { contexto.insert(registro) }
        registro.actualizar(con: estado)
        try contexto.save()
    }

    func colaRescate() throws -> ColaRescate {
        let registros = try contexto.fetch(FetchDescriptor<RescateRegistro>(sortBy: [SortDescriptor(\.posicion), SortDescriptor(\.fecha)]))
        return ColaRescate(entradas: registros.map(\.valor))
    }

    func guardar(_ cola: ColaRescate) throws {
        try contexto.delete(model: RescateRegistro.self)
        for (i, entrada) in cola.entradas.enumerated() {
            contexto.insert(RescateRegistro(entrada, posicion: i))
        }
        try contexto.save()
    }

    func perfil() throws -> PerfilJugador {
        let registros = try contexto.fetch(FetchDescriptor<PerfilRegistro>(sortBy: [SortDescriptor(\.xpTotal, order: .reverse)]))
        // Migración de avatares 05B → 05C (D-061): ids 6–11 → 0–5, persistida la primera vez.
        if let registro = registros.first, registro.avatar != Avatar.migrar(registro.avatar) {
            registro.avatar = Avatar.migrar(registro.avatar)
            try contexto.save()
        }
        return try registros.first?.valor() ?? PerfilJugador()
    }

    func guardar(_ perfil: PerfilJugador) throws {
        let registro = try contexto.fetch(FetchDescriptor<PerfilRegistro>(sortBy: [SortDescriptor(\.xpTotal, order: .reverse)])).first
            ?? { let nuevo = PerfilRegistro(); contexto.insert(nuevo); return nuevo }()
        try registro.actualizar(con: perfil)
        try contexto.save()
    }

    func logros() throws -> [LogroObtenido] {
        let registros = try contexto.fetch(FetchDescriptor<LogroRegistro>(sortBy: [SortDescriptor(\.fecha)]))
        var vistos = Set<String>()
        return registros.filter { vistos.insert($0.logroId).inserted }.map { LogroObtenido(logroId: $0.logroId, fecha: $0.fecha) }
    }

    func registrarLogro(_ logro: LogroObtenido) throws {
        let id = logro.logroId
        let existe = try contexto.fetchCount(FetchDescriptor<LogroRegistro>(predicate: #Predicate { $0.logroId == id })) > 0
        guard !existe else { return }
        contexto.insert(LogroRegistro(logro))
        try contexto.save()
    }

    func diagnostico() throws -> ResultadoDiagnostico? {
        var descriptor = FetchDescriptor<DiagnosticoRegistro>(sortBy: [SortDescriptor(\.fecha, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let datos = try contexto.fetch(descriptor).first?.datos else { return nil }
        return try JSONDecoder().decode(ResultadoDiagnostico.self, from: datos)
    }

    func guardar(_ diagnostico: ResultadoDiagnostico) throws {
        // Desde la 05D se conserva el historial (repetir el diagnóstico desde Progreso).
        contexto.insert(DiagnosticoRegistro(fecha: diagnostico.fecha, datos: try JSONEncoder().encode(diagnostico)))
        try contexto.save()
    }

    func diagnosticos() throws -> [ResultadoDiagnostico] {
        try contexto.fetch(FetchDescriptor<DiagnosticoRegistro>(sortBy: [SortDescriptor(\.fecha)]))
            .compactMap { $0.datos }.map { try JSONDecoder().decode(ResultadoDiagnostico.self, from: $0) }
    }

    func partidas() throws -> [PartidaSupervivencia] {
        try contexto.fetch(FetchDescriptor<PartidaRegistro>(sortBy: [SortDescriptor(\.inicio)]))
            .compactMap { $0.datos }.map { try JSONDecoder().decode(PartidaSupervivencia.self, from: $0) }
    }

    func guardar(_ partida: PartidaSupervivencia) throws {
        let id = partida.id
        let registro = try contexto.fetch(FetchDescriptor<PartidaRegistro>(predicate: #Predicate { $0.uuid == id })).first
            ?? { let nuevo = PartidaRegistro(uuid: id, inicio: partida.inicio, datos: nil); contexto.insert(nuevo); return nuevo }()
        registro.datos = try JSONEncoder().encode(partida)
        try contexto.save()
    }

    func eventosError() throws -> [EventoError] {
        try contexto.fetch(FetchDescriptor<EventoErrorRegistro>(sortBy: [SortDescriptor(\.fecha)])).compactMap(\.valor)
    }

    func registrar(_ evento: EventoError) throws {
        contexto.insert(EventoErrorRegistro(evento))
        try contexto.save()
    }

    func intentosActividad() throws -> [IntentoActividad] {
        try contexto.fetch(FetchDescriptor<IntentoActividadRegistro>(sortBy: [SortDescriptor(\.fecha)])).compactMap { r in
            r.datos.flatMap { try? JSONDecoder().decode(IntentoActividad.self, from: $0) }
        }
    }

    func registrar(_ intento: IntentoActividad) throws {
        contexto.insert(IntentoActividadRegistro(uuid: intento.id, fecha: intento.fecha, datos: try JSONEncoder().encode(intento)))
        try contexto.save()
    }

    func ajustes() throws -> Ajustes {
        guard let datos = try contexto.fetch(FetchDescriptor<AjustesRegistro>()).first?.datos else { return Ajustes() }
        return try JSONDecoder().decode(Ajustes.self, from: datos)
    }

    func guardar(_ ajustes: Ajustes) throws {
        let registro = try contexto.fetch(FetchDescriptor<AjustesRegistro>()).first
            ?? { let nuevo = AjustesRegistro(datos: nil); contexto.insert(nuevo); return nuevo }()
        registro.datos = try JSONEncoder().encode(ajustes)
        try contexto.save()
    }

    func borrarProgreso() throws {
        try contexto.delete(model: IntentoRegistro.self)
        try contexto.delete(model: EstadoCompetenciaRegistro.self)
        try contexto.delete(model: RescateRegistro.self)
        try contexto.delete(model: PerfilRegistro.self)
        try contexto.delete(model: LogroRegistro.self)
        try contexto.delete(model: DiagnosticoRegistro.self)
        try contexto.delete(model: PartidaRegistro.self)
        try contexto.delete(model: EventoErrorRegistro.self)
        try contexto.delete(model: IntentoActividadRegistro.self)
        try contexto.save()
    }
}
