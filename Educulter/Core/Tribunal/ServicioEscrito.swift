import Foundation

/// Simulacros escritos en el servicio (05J): un intento activo por simulacro, cada intento guardado
/// aparte, entrega única y reloj que no se detiene al salir de la app.
extension ServicioSesion {
    var originales: [SimulacroOriginal] { banco.tribunal.originales }

    /// Intentos escritos; los que agotaron el tiempo con la app cerrada quedan entregados (y guardados).
    func intentosEscritos() throws -> [IntentoEscrito] {
        let ahora = reloj.ahora
        return try repositorio.intentosEscritos().map { i in
            var i = i
            if i.comprobarTiempo(ahora) { try repositorio.guardar(i) }
            return i
        }
    }

    func intentoActivo(_ simulacro: String) throws -> IntentoEscrito? {
        try intentosEscritos().last { $0.simulacro == simulacro && $0.activo }
    }

    /// Intento en curso de cualquier simulacro (el más reciente).
    func intentoActivo() throws -> IntentoEscrito? { try intentosEscritos().last { $0.activo } }

    /// Intentos entregados, del más reciente al más antiguo.
    func intentosEntregados() throws -> [IntentoEscrito] { try intentosEscritos().filter(\.entregado).reversed() }

    /// Tarjeta principal: primero la muestra; después, el siguiente simulacro sin hacer; si están
    /// todos hechos, el que se hizo hace más tiempo.
    func simulacroPrincipal() throws -> SimulacroOriginal? {
        let hechos = try intentosEscritos().filter(\.entregado)
        if let s = originales.first(where: { o in !hechos.contains { $0.simulacro == o.id } }) { return s }
        let ultimo = Dictionary(hechos.map { ($0.simulacro, $0.entrega ?? .distantPast) }, uniquingKeysWith: max)
        return originales.min { (ultimo[$0.id] ?? .distantPast) < (ultimo[$1.id] ?? .distantPast) }
    }

    /// Empieza un intento con reloj (en la app o en papel). Si el simulacro ya tiene uno activo, lo
    /// devuelve: nunca hay dos intentos activos del mismo simulacro.
    func empezarEscrito(_ id: String, formato: IntentoEscrito.Formato) throws -> IntentoEscrito {
        guard let s = banco.tribunal.original(id) else { throw ErrorTribunal.sinExamen(id) }
        if let activo = try intentoActivo(id) { return activo }
        var i = IntentoEscrito(simulacro: id, revision: s.entrada.revision, formato: formato, inicio: reloj.ahora,
                               duracionSegundos: s.entrada.duracionSegundos)
        i.actual = s.datos.preguntas.first?.id
        try repositorio.guardar(i)
        return i
    }

    /// Corrige una prueba hecha en papel sin tiempo: sin inicio (duración desconocida), ya entregada.
    func corregirEnPapel(_ id: String) throws -> IntentoEscrito {
        guard let s = banco.tribunal.original(id) else { throw ErrorTribunal.sinExamen(id) }
        var i = IntentoEscrito(simulacro: id, revision: s.entrada.revision, formato: .papel, inicio: nil,
                               duracionSegundos: s.entrada.duracionSegundos)
        i.entrega = reloj.ahora
        try repositorio.guardar(i)
        return i
    }

    func guardar(_ intento: IntentoEscrito) throws { try repositorio.guardar(intento) }

    /// Entrega (idempotente: el mismo intento, sin duplicados).
    func entregar(_ intento: IntentoEscrito) throws -> IntentoEscrito {
        var i = intento
        i.entregar(reloj.ahora)
        try repositorio.guardar(i)
        return i
    }

    func resultado(_ i: IntentoEscrito) -> ResultadoEscrito? {
        banco.tribunal.original(i.simulacro).map { CorrectorEscrito.corregir(i, simulacro: $0.datos, reglas: banco.tribunal.reglas) }
    }

    /// Prioridades (máximo 2) del informe; `practicable` dice si hay contenido aprobado para
    /// practicarla ya, y si no, se remite a su bloque.
    func prioridades(_ i: IntentoEscrito) -> [(competencia: String, nombre: String, bloque: String, practicable: Bool)] {
        guard let s = banco.tribunal.original(i.simulacro) else { return [] }
        let todas = banco.catalogo.todasLasCompetencias
        return CorrectorEscrito.prioridades(i, simulacro: s.datos, mapa: banco.tribunal.mapaRepaso).map { c in
            (c, todas.first { $0.id == c }?.nombre ?? c, banco.catalogo.bloque(deCompetencia: c)?.nombre ?? "", tieneContenido(c))
        }
    }

    /// Siguiente paso tras corregir: otro simulacro no visto o repetir este en 2–7 días.
    func sugerencia(tras i: IntentoEscrito) throws -> String {
        let hechos = Set(try intentosEscritos().filter(\.entregado).map(\.simulacro))
        if let otro = originales.first(where: { !hechos.contains($0.id) && !$0.entrada.esMuestra }) {
            return "Siguiente: «\(otro.entrada.titulo)», un simulacro que aún no has hecho."
        }
        let base = i.entrega ?? reloj.ahora
        let desde = Calendar.current.date(byAdding: .day, value: 2, to: base) ?? base
        let hasta = Calendar.current.date(byAdding: .day, value: 7, to: base) ?? base
        return "Repite este simulacro entre el \(desde.formatted(.dateTime.day().month(.wide))) y el \(hasta.formatted(.dateTime.day().month(.wide)))."
    }

    /// «Por bloques» (05J): práctica de un área con ítems de juego según el plano del examen
    /// (unos 10 ítems, 12–20 min). Su nota no se compara con la del examen.
    func bloquePractica(area: String) throws -> [String] {
        let ahora = reloj.ahora
        let vistos = Set(try repositorio.vistos(desde: ahora.addingTimeInterval(-7 * 24 * 3600)).keys)
        let s = GeneradorSimulacro(banco: banco).generar(semilla: UInt64(ahora.timeIntervalSince1970), plano: plano, vistos: vistos)
        return s.preguntas.compactMap { if case .item(let id, let a) = $0, a == area { id } else { nil } }
    }
}
