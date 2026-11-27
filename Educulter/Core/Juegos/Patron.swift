import Foundation

/// Patrones de interacción de los juegos (Fase 05G, D-115): 9 patrones implementados una sola vez y
/// configurados con datos. El usuario no ve los patrones: ve actividades dentro de las sesiones, el
/// Camino y Rescate.
enum Patron: String, Codable, Sendable, CaseIterable {
    /// Tocar partes de un texto o de una oración (palabras, límites, la tilde, una opción).
    case marcar
    /// Tocar en un texto base los fragmentos que sostienen lo que pide la consigna (nuevo, J46).
    case evidencia
    /// Modelizar con números, barras o figuras; el valor y la unidad, por separado (J63).
    case modelo
    /// Construir con piezas editables.
    case construir
    /// Ordenar fichas.
    case ordenar
    /// Llevar fichas a bandejas.
    case clasificar
    /// Unir los elementos de dos columnas.
    case emparejar
    /// Elegir los rasgos pertinentes de una forma (análisis verbal).
    case rasgos
    /// Formular la respuesta sin opciones y autoevaluarse con un modelo y unos criterios (nuevo, J46).
    case recuerdo
}

extension Mecanica {
    /// Patrón que implementa cada mecánica (asignación de la 05G; no se duplica interfaz).
    var patron: Patron {
        switch self {
        case .marcarTexto, .segmentar, .colocarTilde, .eleccion, .rayosX, .editor: .marcar
        case .evidencia: .evidencia
        case .numerico, .fraccionBarras, .figuraArea: .modelo
        case .construir: .construir
        case .ordenar: .ordenar
        case .clasificar, .verdaderoFalso: .clasificar
        case .emparejar: .emparejar
        case .ruedas: .rasgos
        case .recuerdo: .recuerdo
        }
    }

    /// Las mecánicas de los juegos usan el flujo con pista y reintento del contrato de intento.
    var conReintento: Bool { [.evidencia, .figuraArea, .rayosX, .editor].contains(self) }
}
