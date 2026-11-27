import Foundation

/// Orden de presentación de las opciones de elección (05G §1.1). En el orden guardado, la correcta
/// iba casi siempre la primera en los ítems estáticos: se barajan con la semilla de la sesión y el
/// id del ítem. El orden es reproducible dentro de la sesión y cambia entre sesiones; la corrección
/// es siempre por id de opción, nunca por posición.
enum OrdenOpciones {
    static func semilla(sesion: UInt64, item: String) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in item.utf8 { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01B3 }
        return h ^ (sesion &* 0x9E37_79B9_7F4A_7C15)
    }

    static func barajar<T>(_ opciones: [T], sesion: UInt64, item: String) -> [T] {
        var rng = GeneradorConSemilla(semilla: semilla(sesion: sesion, item: item))
        return opciones.shuffled(using: &rng)
    }
}
