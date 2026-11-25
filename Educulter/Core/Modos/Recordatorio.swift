import Foundation

/// Centro de notificaciones locales (en la app, `UNUserNotificationCenter`; en los tests, uno simulado).
@MainActor
protocol CentroNotificaciones: AnyObject {
    func solicitarPermiso() async -> Bool
    /// Programa una notificación única para una fecha y hora concretas.
    func programar(id: String, titulo: String, cuerpo: String, fecha: DateComponents) async
    func cancelar(ids: [String])
    /// Ids de las notificaciones pendientes de este recordatorio.
    func pendientes() async -> [String]
}

/// Recordatorio diario local, sin servidor (D-072). Se programan notificaciones sueltas para los
/// próximos días (no una repetitiva) para poder cancelar solo la de hoy cuando ya hay ronda.
@MainActor
final class ProgramadorRecordatorio {
    static let prefijo = "recordatorio-"
    static let diasProgramados = 7

    let centro: any CentroNotificaciones
    let calendario: Calendar

    init(centro: any CentroNotificaciones, calendario: Calendar) {
        self.centro = centro
        self.calendario = calendario
    }

    static func id(_ dia: DiaCivil) -> String { "\(prefijo)\(dia.clave)" }

    /// Texto útil y sin culpa. Con racha, la menciona; si no, invita a empezar.
    nonisolated static func texto(racha: Int) -> String {
        racha > 0
            ? "Tu racha de \(racha) \(racha == 1 ? "día" : "días") te espera: una ronda de 3 minutos basta."
            : "Una ronda de 3 minutos hoy y empiezas una racha nueva."
    }

    /// Reprograma los próximos 7 días a la hora de los ajustes. Hoy solo si aún no hay ronda y
    /// la hora no ha pasado. Con el recordatorio desactivado, lo cancela todo.
    func reprogramar(ajustes: Ajustes, racha: EstadoRacha, ahora: Date) async {
        let existentes = await centro.pendientes().filter { $0.hasPrefix(Self.prefijo) }
        centro.cancelar(ids: existentes)
        guard ajustes.recordatorio else { return }
        let hoy = DiaCivil(ahora, calendario: calendario)
        let rondaHoy = racha.ultimoDiaActivo == hoy
        for k in 0..<Self.diasProgramados {
            let dia = hoy.sumando(dias: k)
            var c = calendario.dateComponents([.year, .month, .day], from: dia.fecha(calendario: calendario))
            c.hour = ajustes.hora
            c.minute = ajustes.minuto
            if k == 0 {
                guard !rondaHoy, let cuando = calendario.date(from: c), cuando > ahora else { continue }
            }
            // La racha de hoy se conoce; la de días futuros depende de lo que se juegue: texto general.
            let cuerpo = k == 0 ? Self.texto(racha: racha.vigente(hoy: hoy).actual) : "Una ronda de 3 minutos basta para mantener tu racha."
            await centro.programar(id: Self.id(dia), titulo: "Tu ronda de hoy", cuerpo: cuerpo, fecha: c)
        }
    }

    /// Al completar una ronda: se cancela la notificación de hoy.
    func cancelarHoy(ahora: Date) {
        centro.cancelar(ids: [Self.id(DiaCivil(ahora, calendario: calendario))])
    }
}
