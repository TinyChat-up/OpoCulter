import Foundation

/// «Nivel examen alcanzado» de una competencia (05E parte 2 §5): acierta al menos el 80 % de sus
/// últimos 10 ítems de dificultad 4 o más (4 = nivel del examen oficial, D-096).
struct NivelExamen: Sendable, Equatable, Identifiable {
    static let dificultadExamen = 4
    static let ventana = 10
    static let aciertosNecesarios = 8

    var competencia: String
    /// Ítems de nivel examen en la ventana (como mucho 10) y aciertos entre ellos.
    var respondidos: Int
    var aciertos: Int
    var alcanzado: Bool { respondidos == Self.ventana && aciertos >= Self.aciertosNecesarios }
    var id: String { competencia }

    /// Una entrada por competencia con algún ítem de nivel examen respondido. `dificultad` da la
    /// dificultad de un ítem por su id (los generados se reproducen desde el id).
    static func calcular(_ intentos: [Intento], dificultad: (String) -> Int?) -> [NivelExamen] {
        let deExamen = intentos.filter { (dificultad($0.itemId) ?? 0) >= dificultadExamen }
        return Dictionary(grouping: deExamen, by: \.competenciaId).map { c, lista in
            let ultimos = lista.sorted { $0.fecha < $1.fecha }.suffix(ventana)
            return NivelExamen(competencia: c, respondidos: ultimos.count, aciertos: ultimos.filter(\.correcto).count)
        }.sorted { ($0.alcanzado ? 0 : 1, $0.competencia) < ($1.alcanzado ? 0 : 1, $1.competencia) }
    }
}

extension ServicioSesion {
    /// Nivel examen de las competencias con ítems de dificultad ≥ 4 respondidos (Progreso).
    func nivelesExamen() throws -> [NivelExamen] {
        NivelExamen.calcular(try repositorio.intentos(desde: nil)) { banco.item(id: $0)?.dificultad }
    }
}
