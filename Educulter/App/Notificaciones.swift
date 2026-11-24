import Foundation
import UserNotifications

/// Centro de notificaciones real (UNUserNotificationCenter), sin servidor.
@MainActor
final class CentroNotificacionesSistema: CentroNotificaciones {
    private let centro = UNUserNotificationCenter.current()

    func solicitarPermiso() async -> Bool {
        (try? await centro.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func programar(id: String, titulo: String, cuerpo: String, fecha: DateComponents) async {
        let contenido = UNMutableNotificationContent()
        contenido.title = titulo
        contenido.body = cuerpo
        contenido.sound = .default
        let peticion = UNNotificationRequest(identifier: id, content: contenido,
                                             trigger: UNCalendarNotificationTrigger(dateMatching: fecha, repeats: false))
        try? await centro.add(peticion)
    }

    func cancelar(ids: [String]) {
        centro.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func pendientes() async -> [String] {
        await centro.pendingNotificationRequests().map(\.identifier)
    }
}
