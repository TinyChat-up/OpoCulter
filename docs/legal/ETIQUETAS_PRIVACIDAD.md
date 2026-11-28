# Propuesta para el cuestionario de privacidad de App Store Connect

> Fase 06. Se usa en la fase 08 («Privacidad de la app» en App Store Connect). La revisa la dirección antes de rellenarla.
> Fuentes:
> - El código de la app, revisado el 28/11/2026 (ver «Comprobación del código»).
> - El manifiesto `PrivacyInfo.xcprivacy` de Google Mobile Ads 13.13.0 y de UMP 3.1.0.
> - La página de Google «Data disclosure» (<https://developers.google.com/admob/ios/privacy/data-disclosure>, que describe el SDK 13.12.0).

## Comprobación del código

- **Sin servidor ni cuentas.** La app no tiene inicio de sesión, ni servidor propio, ni CloudKit. El progreso (SwiftData) y los ajustes (`UserDefaults`) se guardan solo en el iPhone.
- **Sin conexiones propias.** La app no usa `URLSession` ni ninguna otra conexión de red. Solo hay enlaces que abre el usuario en Safari: los cuadernillos oficiales, los Términos de uso de Apple y la política de privacidad.
- **Lo único que sale a la red:**
  - **StoreKit:** lo gestiona Apple. El desarrollador no recibe datos de compra en un servidor propio.
  - **Google Mobile Ads y UMP:** solo en la versión gratuita y desde el tercer día de uso. Nunca con Premium, y tampoco en Release mientras los identificadores de AdMob valgan `PENDIENTE`.

## ¿Se recogen datos?

**Sí.** Los recoge el SDK de anuncios de Google, un socio externo que cuenta como recogida de la app.

## ¿Se usan para rastrear (tracking)?

**Sí: el identificador del dispositivo (IDFA).** Solo si el usuario acepta el permiso de seguimiento (ATT). Por eso `NSPrivacyTracking` es `true` en el manifiesto de la app.

## Tipos de datos

| Categoría en App Store Connect | Tipo | Finalidades | ¿Vinculado al usuario? | ¿Rastreo? |
|---|---|---|---|---|
| Identificadores | ID del dispositivo | Publicidad de terceros, publicidad o marketing del desarrollador, analítica | Sí | **Sí** |
| Ubicación | Ubicación aproximada (por la IP) | Publicidad de terceros, publicidad o marketing del desarrollador, analítica | Sí | No |
| Uso | Interacción con el producto | Publicidad de terceros, publicidad o marketing del desarrollador, analítica | Sí | No |
| Uso | Datos de publicidad | Publicidad de terceros, publicidad o marketing del desarrollador, analítica | Sí | No |
| Diagnóstico | Datos de fallos | Analítica | No | No |
| Diagnóstico | Datos de rendimiento | Publicidad de terceros, publicidad o marketing del desarrollador, analítica | No | No |
| Diagnóstico | Otros datos de diagnóstico | Publicidad de terceros, publicidad o marketing del desarrollador, analítica | No | No |

UMP declara además la ubicación aproximada, el rendimiento y la interacción con el producto, para «funcionalidad de la app», sin vincular y sin rastreo. Si el cuestionario lo pide por finalidad, añade **Funcionalidad de la app** a esos tres tipos.

## Lo que no se recoge

- Datos de contacto, salud, finanzas, ubicación precisa, contactos, historial de navegación y de búsqueda.
- Contenido del usuario: las respuestas y el borrador se quedan en el iPhone.
- Información confidencial.
- Historial de compras: lo gestiona Apple y la app no lo envía a ninguna parte.

## Para decidir en la fase 08

- **Versión sin anuncios:** si la dirección quitara los anuncios, todo lo anterior pasaría a «No se recogen datos».
- **Comprobación final:** antes de enviar, compara la tabla con el informe de privacidad que genera Xcode (*Product > Archive > Generate Privacy Report*).
