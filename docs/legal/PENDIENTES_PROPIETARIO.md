# Lo que tiene que hacer el propietario para cobrar y mostrar anuncios

> Fase 06. Nada de esto lo puede hacer Claude Code: son cuentas, contratos y datos bancarios a tu nombre.
> Hazlo en este orden. Cuando termines cada paso, díselo a la dirección. **No hace falta para seguir probando la app**: hasta entonces, Debug usa una tienda de prueba y anuncios de prueba, y Release no muestra ningún anuncio.

## 1. Membresía de Apple Developer

1. Entra en <https://developer.apple.com/programs/enroll/> con tu Apple ID.
2. Elige inscribirte como **persona física** (o como empresa, si la tienes; necesitarás el número D-U-N-S).
3. Paga la cuota anual (99 USD, unos 99 € en España).
4. Espera el correo de confirmación (de unas horas a dos días).

## 2. Acuerdo de apps de pago, datos bancarios e impuestos

1. Entra en <https://appstoreconnect.apple.com> > **Negocio** (Business).
2. En **Acuerdos**, acepta el **Acuerdo de apps de pago** (Paid Apps Agreement).
3. En **Banca**, añade la cuenta donde quieres cobrar (titular, IBAN y SWIFT/BIC del banco).
4. En **Impuestos**, rellena los formularios:
   - **W-8BEN** de Estados Unidos (como residente en España, para no pagar la retención completa).
   - Los datos fiscales de España que pida (NIF y domicilio fiscal).
5. Espera a que el acuerdo pase a **Activo**. Sin eso, las suscripciones no se pueden probar en TestFlight ni vender.

## 3. Programa para pequeñas empresas (comisión del 15 %)

1. Con el acuerdo de pago activo, entra en <https://developer.apple.com/app-store/small-business-program/>.
2. Pulsa **Inscribirse** y rellena el formulario (declaras que facturas menos de 1 millón de dólares al año).
3. Apple te confirma la inscripción por correo. Desde entonces, la comisión es del 15 % en lugar del 30 %.

## 4. Crear la app y los 2 productos en App Store Connect

**Antes de crear nada, avisa a la dirección**: el identificador de la app es hoy `com.educulter.dev` y los productos se llaman como él. Si se cambia en la fase 08, hay que cambiar también los productos.

1. **Apps** > **+** > **Nueva app**.
   - Plataforma: iOS.
   - Nombre: el comercial que decida la dirección.
   - Idioma principal: Español (España).
   - Identificador del paquete: `com.educulter.dev` (o el definitivo que diga la dirección).
   - SKU: `educulter-ios`.
2. Dentro de la app > **Suscripciones** > **Crear** un grupo de suscripción:
   - Nombre de referencia: `Premium`.
   - Nombre visible (es-ES): `Premium`.
3. En ese grupo, crea **dos** suscripciones autorrenovables con exactamente estos datos:

| Dato | Mensual | Anual |
|---|---|---|
| Nombre de referencia | Premium mensual | Premium anual |
| ID del producto | `com.educulter.dev.premium.mensual` | `com.educulter.dev.premium.anual` |
| Duración | 1 mes | 1 año |
| Precio (España) | 9,99 € | 49,99 € |
| Nivel en el grupo | 2 | 1 (el más alto) |
| Nombre visible (es-ES) | Premium mensual | Premium anual |
| Descripción (es-ES) | Simulacros, exámenes oficiales y sin anuncios. | Simulacros, exámenes oficiales y sin anuncios. |

4. En **cada una**: **Precios de suscripción** > **Ver todos los precios** > **Oferta introductoria**:
   - Tipo: **Gratis**.
   - Duración: **1 semana** (7 días).
   - Países: todos.
   - Apple solo deja usar la prueba una vez por grupo; no hay que configurar nada más.
5. Sube la captura de revisión de cada suscripción (la pantalla Premium: `docs/capturas/06/premium.png`).
6. **No envíes nada a revisión.** Ese paso lo autoriza la dirección (fase 08).

## 5. Cuenta de AdMob

1. Entra en <https://admob.google.com> con una cuenta de Google y acepta las condiciones.
2. Rellena los datos de pago de AdMob (cuenta bancaria y datos fiscales para Google).
3. **Apps** > **Añadir app** > iOS. Si la app aún no está en el App Store, elige **No** («¿Está publicada?») y ponle el nombre comercial.
4. Copia el **ID de la app**: tiene la forma `ca-app-pub-1234567890123456~1234567890`.
5. **Bloques de anuncios** > **Añadir bloque** > **Intersticial**.
   - Nombre: `Fin de ronda`.
   - Copia el **ID del bloque**: tiene la forma `ca-app-pub-1234567890123456/1234567890`.
6. **Privacidad y mensajes** (Privacy & messaging):
   1. **RGPD** (Europa): crea un mensaje para la app, en español, y publícalo.
   2. **Mensaje explicativo de IDFA** (iOS): créalo y publícalo. Sale justo antes del permiso de seguimiento de Apple. El texto del permiso ya está en la app: «Solo lo usamos para que los anuncios de la versión gratuita te resulten más útiles. Si dices que no, la app funciona exactamente igual.»
7. En **Configuración de la app** > **app-ads.txt**, AdMob te pedirá una web. Apúntalo como pendiente para la fase 08 (va junto con la política de privacidad).

## 6. Dónde se pegan los identificadores reales

En el archivo `Config/Anuncios-Release.xcconfig` del proyecto. Hoy pone esto:

```
ADMOB_APP_ID = PENDIENTE
ADMOB_INTERSTICIAL_ID = PENDIENTE
```

1. Sustituye `PENDIENTE` por tus dos identificadores, así (con los tuyos):

```
ADMOB_APP_ID = ca-app-pub-1234567890123456~1234567890
ADMOB_INTERSTICIAL_ID = ca-app-pub-1234567890123456/1234567890
```

2. No pongas comillas ni espacios de más. No toques `Config/Anuncios-Debug.xcconfig`: Debug usa siempre los de prueba de Google.
3. Si lo prefieres, mándale los dos identificadores a la dirección y Claude Code los pega.
4. Mientras alguno valga `PENDIENTE`, tenga otro formato o sea de prueba, la versión de Release no muestra anuncios ni da error.

## Otros pendientes para la fase 08

- **Política de privacidad**: hace falta una web pública con la política. La app enlaza hoy a una dirección provisional (`https://example.com/educulter/privacidad`, en `EnlacesLegales.privacidad`).
- **Cuestionario de privacidad de App Store Connect**: la propuesta de respuestas está en `docs/legal/ETIQUETAS_PRIVACIDAD.md`.
