import Foundation

/// Día del calendario civil del usuario (año, mes, día), sin hora.
///
/// Todo lo que depende de "qué día es" (racha, repasos de Leitner, misiones) trabaja con
/// `DiaCivil` en lugar de con `Date`. Así los cambios de horario de verano y la medianoche
/// no producen días de 23 o 25 horas, y la aritmética de días es exacta.
/// El día se obtiene siempre con el calendario gregoriano y la zona horaria del usuario.
struct DiaCivil: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    let anio: Int
    let mes: Int
    let dia: Int

    init(anio: Int, mes: Int, dia: Int) {
        self.anio = anio
        self.mes = mes
        self.dia = dia
    }

    /// Día civil al que corresponde `fecha` en la zona horaria de `calendario`.
    /// Se fuerza el calendario gregoriano aunque el usuario tenga otro configurado.
    init(_ fecha: Date, calendario: Calendar) {
        var gregoriano = Calendar(identifier: .gregorian)
        gregoriano.timeZone = calendario.timeZone
        let c = gregoriano.dateComponents([.year, .month, .day], from: fecha)
        self.init(anio: c.year ?? 1970, mes: c.month ?? 1, dia: c.day ?? 1)
    }

    /// Clave entera `AAAAMMDD`, cómoda para persistir y comparar.
    var clave: Int { anio * 10_000 + mes * 100 + dia }

    init?(clave: Int) {
        let anio = clave / 10_000
        let mes = (clave / 100) % 100
        let dia = clave % 100
        guard (1...12).contains(mes), (1...31).contains(dia) else { return nil }
        self.init(anio: anio, mes: mes, dia: dia)
    }

    var description: String {
        String(format: "%04d-%02d-%02d", anio, mes, dia)
    }

    static func < (a: DiaCivil, b: DiaCivil) -> Bool { a.clave < b.clave }

    /// Día civil desplazado `n` días (n puede ser negativo).
    func sumando(dias n: Int) -> DiaCivil {
        let cal = Self.calendarioAritmetico
        guard let base = cal.date(from: DateComponents(year: anio, month: mes, day: dia, hour: 12)),
              let destino = cal.date(byAdding: .day, value: n, to: base) else { return self }
        return DiaCivil(destino, calendario: cal)
    }

    /// Número de días desde `self` hasta `otro` (positivo si `otro` es posterior).
    func dias(hasta otro: DiaCivil) -> Int {
        let cal = Self.calendarioAritmetico
        guard let a = cal.date(from: DateComponents(year: anio, month: mes, day: dia, hour: 12)),
              let b = cal.date(from: DateComponents(year: otro.anio, month: otro.mes, day: otro.dia, hour: 12))
        else { return 0 }
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Instante de inicio de este día en la zona horaria del calendario dado.
    func inicio(en calendario: Calendar) -> Date? {
        var gregoriano = Calendar(identifier: .gregorian)
        gregoriano.timeZone = calendario.timeZone
        guard let mediodia = gregoriano.date(from: DateComponents(year: anio, month: mes, day: dia, hour: 12))
        else { return nil }
        return gregoriano.startOfDay(for: mediodia)
    }

    /// Calendario gregoriano en UTC: la aritmética de días civiles no depende de la zona.
    private static var calendarioAritmetico: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return cal
    }
}
