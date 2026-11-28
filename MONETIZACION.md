# Monetización

> **Propósito:** modelo de pago, anuncios y su implementación (fase 06). Las decisiones están en [DECISIONES.md](DECISIONES.md), D-149 a D-160.
> No se crea ningún producto en App Store Connect ni en AdMob sin autorización explícita. Los pasos del propietario están en [docs/legal/PENDIENTES_PROPIETARIO.md](docs/legal/PENDIENTES_PROPIETARIO.md).

## 1. Modelo
- **Premium:** un grupo de suscripción con dos suscripciones autorrenovables, las dos con 7 días gratis (una vez por grupo).
  - `<bundleID>.premium.mensual`: 9,99 €/mes.
  - `<bundleID>.premium.anual`: 49,99 €/año.
- **Versión gratuita:** con anuncios intersticiales de Google AdMob y consentimiento de UMP.

## 2. Qué es gratis y qué es de pago (D-152)
| Función | Gratis | Premium |
|---|---|---|
| Aprendizaje: Camino, sesión diaria, Rescate, juegos, teoría y Glosario | Todo | Todo |
| Anuncios | Sí, con las reglas del §3 | No |
| Tribunal: la muestra SIM.DEMO.01 | Sí | Sí |
| Tribunal: convocatorias anteriores (los 7 exámenes oficiales) | No | Sí |
| Tribunal: simulacros, modo examen, corrección, informe y «Por bloques» | No | Sí |
| Supervivencia | 1 partida al día | Ilimitada |

## 3. Anuncios (D-157)
- **Nunca:** con Premium, los 2 primeros días naturales, al abrir la app, a mitad de ronda, en la bienvenida ni en el Tribunal.
- **Cuándo:** al dejar el resultado de una ronda terminada, uno cada 2 rondas y como mucho 4 al día.
- **Sin espera:** si no hay anuncio cargado, se sigue sin él.

## 4. Implementación
- **Acceso:**
  - `ServicioAcceso` (StoreKit 2) es lo único que consulta StoreKit.
  - Las vistas preguntan a `ServicioAcceso`, que aplica `TablaAcceso`.
- **Anuncios:**
  - `ServicioAnuncios` aplica `PoliticaAnuncios`.
  - `ProveedorGoogle` es el único archivo que importa los SDK de Google.
- **Configuración:**
  - `Educulter.storekit`: tienda local para Debug y para los tests.
  - `Config/Anuncios-*.xcconfig`: identificadores de AdMob. En Release están pendientes (marcador de ceros y `PENDIENTE`, D-161) hasta tener los reales.

## 5. Pruebas
- **Unitarias:** `Fase06Tests`.
  - Política de anuncios.
  - Servicio de anuncios con proveedor falso.
  - Tabla de acceso.
  - Identificadores.
  - StoreKitTest: compra, prueba, caducidad, reembolso, restaurar y actualizaciones.
- **Interfaz:** `TribunalUITests.testGratisSimulacroAbreHojaYPantallaPremium`.
- **Sandbox (TestFlight):** necesita la membresía de pago, el acuerdo de apps de pago y los productos creados en App Store Connect.
