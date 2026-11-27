import Foundation

/// Integración de los juegos en las sesiones (Fase 05G §6, D-120).
///
/// - J46 es una actividad de tres pasos sobre el mismo texto: en la sesión diaria, un bloque nuevo
///   de su competencia que contiene un paso de J46 pasa a ser la actividad completa (los tres pasos
///   con la misma semilla).
/// - La variante sin ayudas de cada competencia de juego se programa a los 2 días
///   (`RetencionJuegos`): misma plantilla, otra semilla; en J46, otro texto y solo los pasos 2–3.
enum ActividadesJuego {
    static let j46 = "J46"

    /// Plantillas de los pasos de J46 de una competencia, en orden (evidencia, tema, resumen).
    static func pasosJ46(competencia: String, banco: BancoContenido) -> [Plantilla] {
        banco.plantillas.filter { $0.competencia == competencia && $0.tipo == GeneradorEvidenciaResumen().tipo }
            .sorted { ($0.peldano, $0.id) < ($1.peldano, $1.id) }
    }

    static func id(_ p: Plantilla, semilla: UInt64) -> String { "\(p.id)\(MotorGeneradores.separadorSemilla)\(semilla)" }

    /// Si el bloque tiene un paso de J46, devuelve la actividad completa con esa semilla (tantos
    /// pasos como ítems tenía el bloque, empezando por el primero). Si no, el bloque tal cual.
    static func agrupar(_ bloque: [ItemRonda], competencia: String, banco: BancoContenido) -> [ItemRonda] {
        guard let primero = bloque.first(where: { banco.item(id: $0.itemId)?.juego == j46 }),
              let semilla = MotorGeneradores.partes(de: primero.itemId)?.semilla else { return bloque }
        let pasos = pasosJ46(competencia: competencia, banco: banco)
        guard pasos.count >= 2, bloque.count >= 2 else {
            // Sin sitio para la actividad: fuera los pasos sueltos que no sean el primero.
            return bloque.filter { banco.item(id: $0.itemId)?.juego != j46 || $0.itemId.hasPrefix(pasos.first?.id ?? "") }
        }
        return pasos.prefix(bloque.count).map { ItemRonda(itemId: id($0, semilla: semilla), motivo: primero.motivo) }
    }

    /// Variante sin ayudas de `competencia` a partir de su último intento de juego (o vacío si no
    /// se puede generar).
    static func variante(competencia: String, intentos: [IntentoActividad], banco: BancoContenido,
                         rng: inout GeneradorConSemilla) -> [ItemRonda] {
        guard let ultimo = intentos.filter({ $0.competencia == competencia && !$0.sinAyudas }).max(by: { $0.fecha < $1.fecha }),
              let (pid, anterior) = MotorGeneradores.partes(de: ultimo.fuente) else { return [] }
        let pasos = pasosJ46(competencia: competencia, banco: banco)
        if pasos.contains(where: { pid.hasPrefix($0.id) }) {
            // J46: otro texto (otro índice en el banco) y solo los pasos 2–3.
            let textos = max(banco.recursos.resumen?.textos.count ?? 1, 1)
            let indice: (UInt64) -> Int = { Int($0 % 1_000_003) % textos }
            var s = rng.next() % 1_000_000
            for _ in 0..<50 where textos > 1 && indice(s) == indice(anterior) { s = rng.next() % 1_000_000 }
            return pasos.dropFirst().map { ItemRonda(itemId: id($0, semilla: s), motivo: .variante, sinAyudas: true) }
        }
        var s = rng.next() % 1_000_000
        if s == anterior { s += 1 }
        let itemId = "\(pid)\(MotorGeneradores.separadorSemilla)\(s)"
        guard banco.item(id: itemId) != nil else { return [] }
        return [ItemRonda(itemId: itemId, motivo: .variante, sinAyudas: true)]
    }
}

extension Item {
    /// El ítem sigue el contrato de intento (pista y reintento) de los juegos.
    var conReintento: Bool { juego != nil || mecanica.conReintento }

    /// Destreza que registra el contrato de intento.
    var destreza: String {
        switch juego {
        case "J46": "idea central y resumen"
        case "J63": "área de figuras compuestas"
        default: objetivo
        }
    }
}

extension Respuesta {
    /// Respuesta en texto breve para el registro del contrato de intento.
    var registro: String {
        switch self {
        case .eleccion(let id), .evidencia(let id): id
        case .numerico(let v): v
        case .recuerdo(let r): r.enPapel ? "(en papel)" : String(r.texto.prefix(400))
        case .figura(let f):
            ([f.estrategia?.rawValue ?? "-", f.cortes.sorted().joined(separator: "+")]
             + f.areas.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" } + ["total=\(f.total)", f.unidad ?? "-"])
                .joined(separator: " ")
        default: String(describing: self)
        }
    }
}
