import Foundation

/// El Tribunal en el servicio (05I): empezar, reanudar, corregir, historial y «Repasar ahora».
extension ServicioSesion {
    var plano: PlanoExamen { PlanoExamen.calcular(banco.tribunal) }

    /// Empieza un examen y lo guarda. El simulacro evita los ítems vistos en los últimos 7 días.
    func empezarExamen(_ modo: SesionExamen.Modo) throws -> SesionExamen {
        let ahora = reloj.ahora
        let examen: SesionExamen
        switch modo {
        case .oficial(let id):
            guard let e = banco.tribunal.examen(id) else { throw ErrorTribunal.sinExamen(id) }
            examen = SesionExamen(modo: modo, preguntas: e.preguntas.map { .oficial(examen: id, numero: $0.numero) }, duracionMin: e.duracionMin, inicio: ahora)
        case .medio(let id, let area):
            guard let e = banco.tribunal.examen(id) else { throw ErrorTribunal.sinExamen(id) }
            examen = SesionExamen(modo: modo, preguntas: e.preguntas.filter { $0.area == area }.map { .oficial(examen: id, numero: $0.numero) },
                                  duracionMin: e.duracionMin / 2, inicio: ahora)
        case .simulacro(let semilla):
            let vistos = Set(try repositorio.vistos(desde: ahora.addingTimeInterval(-7 * 24 * 3600)).keys)
            let s = GeneradorSimulacro(banco: banco).generar(semilla: semilla, plano: plano, vistos: vistos)
            examen = SesionExamen(modo: modo, preguntas: s.preguntas, duracionMin: plano.duracionMin, inicio: ahora, noIncluye: s.noIncluye)
        }
        try repositorio.guardar(examen)
        return examen
    }

    /// Examen sin entregar (se reanuda en la misma pregunta y con el tiempo que quedaba).
    func examenEnCurso() throws -> SesionExamen? {
        try repositorio.examenesTribunal().last { $0.estado != .corregido }
    }

    /// Exámenes corregidos, del más reciente al más antiguo.
    func historialExamenes() throws -> [SesionExamen] {
        try repositorio.examenesTribunal().filter { $0.estado == .corregido }.reversed()
    }

    func guardarExamen(_ examen: SesionExamen) throws { try repositorio.guardar(examen) }

    /// Corrige un examen entregado con sus autoevaluaciones. Los errores de los ítems del simulacro
    /// entran en el catálogo de errores como siempre.
    func corregir(_ examen: SesionExamen) throws -> SesionExamen {
        var e = examen
        if e.estado == .enCurso { e.entregar(ahora: reloj.ahora) }
        let resultado = CorrectorExamen.corregir(e, banco: banco, fecha: reloj.ahora)
        for p in resultado.preguntas where p.automatica && (p.puntuacion ?? 1) < 1 {
            guard case .item(let id, _) = e.preguntas[p.indice], let item = banco.item(id: id), let r = e.respuestas[p.indice]?.item else { continue }
            var efecto = EfectoRespuesta()
            try registrarErrores(item: item, resultado: Evaluador.evaluar(r, para: item), errorRemedio: nil, fecha: reloj.ahora, efecto: &efecto)
        }
        e.resultado = resultado
        e.estado = .corregido
        try repositorio.guardar(e)
        return e
    }

    /// «Repasar ahora»: cada competencia floja entra en Rescate con un ítem aprobado (y su remedio
    /// sale en la sesión diaria si el error se activa). Devuelve las competencias enviadas.
    @discardableResult
    func repasarAhora(_ resultado: ResultadoExamen) throws -> [String] {
        var cola = try repositorio.colaRescate()
        let estados = try repositorio.estadosCompetencia()
        let rondas = ConstructorRondas(banco: banco, config: configRonda)
        var enviadas: [String] = []
        for c in resultado.debiles {
            let peldano = estados[c]?.escalera.peldano ?? 1
            guard let item = rondas.candidatos(competencia: c, peldano: peldano).first(where: { $0.validacion.estado == .aprobado }) else { continue }
            cola.registrarFallo(item, fecha: reloj.ahora)
            enviadas.append(c)
        }
        try repositorio.guardar(cola)
        return enviadas
    }
}

enum ErrorTribunal: Error, Equatable {
    case sinExamen(String)
}
