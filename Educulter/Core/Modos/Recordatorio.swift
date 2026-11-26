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
/// próximos días (no una repetitiva) para poder cancelar solo la de hoy cuando ya se ha completado
/// la sesión diaria (05E parte 2 §3.3): como mucho uno al día y nunca después de la sesión.
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

    /// Texto positivo y sin culpa, con la duración elegida.
    nonisolated static func texto(minutos: Int) -> String {
        "Tienes \(minutos) minutos para un repaso rápido."
    }

    /// Reprograma los próximos 7 días a la hora de los ajustes. Hoy solo si aún no se ha completado
    /// la sesión y la hora no ha pasado. Con el recordatorio desactivado, lo cancela todo.
    func reprogramar(ajustes: Ajustes, sesionHoy: Bool, ahora: Date) async {
        let existentes = await centro.pendientes().filter { $0.hasPrefix(Self.prefijo) }
        centro.cancelar(ids: existentes)
        guard ajustes.recordatorio else { return }
        let hoy = DiaCivil(ahora, calendario: calendario)
        for k in 0..<Self.diasProgramados {
            let dia = hoy.sumando(dias: k)
            var c = calendario.dateComponents([.year, .month, .day], from: dia.fecha(calendario: calendario))
            c.hour = ajustes.hora
            c.minute = ajustes.minuto
            if k == 0 {
                guard !sesionHoy, let cuando = calendario.date(from: c), cuando > ahora else { continue }
            }
            await centro.programar(id: Self.id(dia), titulo: "Tu sesión de hoy", cuerpo: Self.texto(minutos: ajustes.duracion.rawValue), fecha: c)
        }
    }

    /// Al completar la sesión diaria: se cancela la notificación de hoy.
    func cancelarHoy(ahora: Date) {
        centro.cancelar(ids: [Self.id(DiaCivil(ahora, calendario: calendario))])
    }
}
