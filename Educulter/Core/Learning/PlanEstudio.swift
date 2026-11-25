import Foundation

/// Orden de lo nuevo (05E parte 2, §1b.5, D-103): cada competencia con contenido recibe la puntuación
/// **prioridad del bloque (★) × debilidad del diagnóstico × preguntas oficiales de su competencia**
/// (`tribunal/equivalencias.json`). En modo Mixto se alternan Lengua y Matemáticas.
/// Empates: más preguntas oficiales, después más prioridad y después el orden del catálogo.
struct PlanEstudio: Sendable {
    let banco: BancoContenido
    var diagnostico: ResultadoDiagnostico?
    var debilidadSinDatos = ConfiguracionDiagnostico.estandar.debilidadSinDatos

    /// Debilidad del bloque (0 fuerte … 1 débil) según el último diagnóstico.
    func debilidad(bloque: String) -> Double {
        guard let n = diagnostico?.niveles.first(where: { $0.bloqueId == bloque }) else { return debilidadSinDatos }
        return min(max(1 - n.nivel, 0), 1)
    }

    /// Preguntas oficiales de la competencia. Las equivalencias ya usan los ids del mapa: una
    /// competencia antigua sustituida (`equivaleA`) no puntúa, para que no adelante a la nueva.
    func preguntasOficiales(_ competencia: String) -> Int { banco.preguntasOficiales[competencia] ?? 0 }

    func puntuacion(_ competencia: String) -> Double {
        guard let b = banco.catalogo.bloque(deCompetencia: competencia) else { return 0 }
        return Double(b.prioridad) * debilidad(bloque: b.id) * Double(preguntasOficiales(competencia))
    }

    /// Competencias ordenadas por puntuación (todas, o las de un área).
    func ordenadas(area: String? = nil) -> [String] {
        let todas = banco.catalogo.todasLasCompetencias.enumerated().filter { area == nil || Catalogo.area(de: $0.element.id) == area }
        return todas.sorted { a, b in
            let pa = puntuacion(a.element.id), pb = puntuacion(b.element.id)
            if pa != pb { return pa > pb }
            let qa = preguntasOficiales(a.element.id), qb = preguntasOficiales(b.element.id)
            if qa != qb { return qa > qb }
            let ra = banco.catalogo.bloque(deCompetencia: a.element.id)?.prioridad ?? 0, rb = banco.catalogo.bloque(deCompetencia: b.element.id)?.prioridad ?? 0
            if ra != rb { return ra > rb }
            return a.offset < b.offset
        }.map(\.element.id)
    }

    /// Modo Mixto: Lengua y Matemáticas alternadas, empezando por el área de la mejor puntuación.
    func mixto(_ candidatas: [String]) -> [String] {
        let len = candidatas.filter { Catalogo.area(de: $0) == "LEN" }, mat = candidatas.filter { Catalogo.area(de: $0) == "MAT" }
        let primeroLEN = (len.first.map(puntuacion) ?? -1) >= (mat.first.map(puntuacion) ?? -1)
        var (a, b) = primeroLEN ? (len, mat) : (mat, len)
        var r: [String] = []
        while !a.isEmpty || !b.isEmpty {
            if !a.isEmpty { r.append(a.removeFirst()) }
            if !b.isEmpty { r.append(b.removeFirst()) }
        }
        return r
    }
}
