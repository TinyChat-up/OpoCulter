import Testing
@testable import Educulter

@Suite("Estado de la pantalla de verificación")
struct EstadoVerificacionTests {
    @Test("Registrar una pulsación incrementa el contador")
    func registrarPulsacionIncrementaContador() {
        var estado = EstadoVerificacion()
        #expect(estado.pulsaciones == 0)
        estado.registrarPulsacion()
        #expect(estado.pulsaciones == 1)
    }
}
