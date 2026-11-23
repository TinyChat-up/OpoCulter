import Foundation

/// División silábica ortográfica simplificada del español y sílaba tónica. Se usa para
/// resaltar la sílaba tónica al corregir `colocarTilde`.
///
/// Reglas: los grupos de vocales forman diptongo salvo dos abiertas (a, e, o) juntas o una
/// cerrada con tilde (í, ú) junto a otra vocal (hiato). Entre vocales, una consonante va con
/// la siguiente; dos se separan salvo los grupos inseparables (pr, bl, ch, ll, rr…); con tres
/// o más, las dos últimas van juntas solo si forman grupo inseparable. «qu» y «gu» + e/i
/// cuentan como consonante.
enum Silabeo {
    private static let abiertas: Set<Character> = ["a", "e", "o", "á", "é", "ó", "í", "ú"]
    private static let vocales: Set<Character> = ["a", "e", "i", "o", "u", "á", "é", "í", "ó", "ú", "ü"]
    private static let inseparables: Set<String> = [
        "pr", "br", "tr", "dr", "cr", "gr", "fr", "pl", "bl", "cl", "gl", "fl", "kl", "kr", "ch", "ll", "rr",
    ]

    /// Rangos (índices de carácter) de cada sílaba.
    static func silabas(_ palabra: String) -> [Range<Int>] {
        let l = Array(palabra.lowercased())
        guard !l.isEmpty else { return [] }
        // ¿Es vocal (núcleo) el carácter i? La «u» de «qu»/«gu»+e/i es muda.
        func esVocal(_ i: Int) -> Bool {
            guard vocales.contains(l[i]) else { return false }
            if l[i] == "u", i > 0, l[i - 1] == "q" || (l[i - 1] == "g" && i + 1 < l.count && "eiéí".contains(l[i + 1])) { return false }
            return true
        }
        // Núcleos: grupos de vocales, separados por hiato.
        var nucleos: [Range<Int>] = []
        var i = 0
        while i < l.count {
            guard esVocal(i) else { i += 1; continue }
            var fin = i + 1
            while fin < l.count, esVocal(fin), !hiato(l[fin - 1], l[fin]) { fin += 1 }
            nucleos.append(i..<fin)
            i = fin
        }
        guard !nucleos.isEmpty else { return [0..<l.count] }
        // Cortes entre núcleos consecutivos.
        var cortes: [Int] = []
        for k in 0..<(nucleos.count - 1) {
            let a = nucleos[k].upperBound, b = nucleos[k + 1].lowerBound
            let consonantes = b - a
            switch consonantes {
            case 0, 1: cortes.append(a)
            case 2: cortes.append(inseparables.contains(String(l[a..<b])) ? a : a + 1)
            default: cortes.append(inseparables.contains(String(l[(b - 2)..<b])) ? b - 2 : b - 1)
            }
        }
        var rangos: [Range<Int>] = []
        var inicio = 0
        for c in cortes { rangos.append(inicio..<c); inicio = c }
        rangos.append(inicio..<l.count)
        return rangos
    }

    /// Índice de la sílaba tónica. Con tilde, la que la contiene; sin tilde, por las reglas
    /// generales: llana si acaba en vocal, -n o -s tras vocal; aguda en el resto.
    static func silabaTonica(_ palabra: String, indiceTilde: Int?) -> Int {
        let s = silabas(palabra)
        guard s.count > 1 else { return 0 }
        if let i = indiceTilde, let k = s.firstIndex(where: { $0.contains(i) }) { return k }
        let l = Array(palabra.lowercased())
        guard let ultima = l.last else { return 0 }
        let penultima: Character? = l.count >= 2 ? l[l.count - 2] : nil
        let llana = vocales.contains(ultima) || ultima == "n" || (ultima == "s" && penultima.map { vocales.contains($0) } == true)
        return llana ? s.count - 2 : s.count - 1
    }

    private static func hiato(_ a: Character, _ b: Character) -> Bool {
        (abiertas.contains(a) && abiertas.contains(b)) || "íú".contains(a) || "íú".contains(b)
    }
}
