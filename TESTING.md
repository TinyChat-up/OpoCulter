# Testing

> **Propósito:** definir la estrategia de pruebas y dejar registro de cómo se verifica cada fase.

## 1. Tipos de prueba
| Tipo | Framework | Target |
|---|---|---|
| Unitarias | Swift Testing | `EduculterTests` |
| Interfaz | XCTest (XCUITest) | `EduculterUITests` |

## 2. Dispositivos de referencia
- Simulador: iPhone 16, iOS 27.2 (D-009).
- Físico: iPhone 16 del propietario.
- iOS 17 (target mínimo): Fase 07.

## 3. Comandos
```sh
xcodebuild test -project Educulter.xcodeproj -scheme Educulter \
  -destination 'platform=iOS Simulator,name=iPhone 16' -parallel-testing-enabled NO
```
Desde la 05A.1 los tests se ejecutan **en serie** (`-parallel-testing-enabled NO`): con los clones paralelos del simulador, el ejecutor de los tests de UI fallaba a veces al iniciar ("Timed out waiting for AX loaded notification"). Si el simulador queda bloqueado: `xcrun simctl shutdown all` y, si hace falta, `xcrun simctl erase` del iPhone 16.

## 4. Validación de contenidos
- `ContenidoEmpaquetadoTests.todoElContenidoPasaElValidador`: **todo el contenido del bundle debe pasar el validador**. Protege el contenido real.
- `ContenidoEmpaquetadoTests.releaseNoCargaBorradores`: con la política de Release no se carga ningún elemento que no esté aprobado.
- Reglas del validador: [CONTENIDOS.md §2](CONTENIDOS.md#2-formato-de-contenido-esquema-v1).

## 4 bis. Cobertura
```sh
xcodebuild test -project Educulter.xcodeproj -scheme Educulter \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES -resultBundlePath build/Tests.xcresult
xcrun xccov view --report --json build/Tests.xcresult   # se agrega por archivo de Core/
```
Objetivo: cobertura de `Core/` ≥ 90 % (desde la 05A). Última medición (Fase 05A.1): **Core 97,2 %** (2 183 / 2 247 líneas), **Features 86,3 %** (4 718 / 5 464; incluye los tests de UI) y App 91,9 % (68 / 74). Reloj, calendario y aleatoriedad se inyectan (`RelojFijo`, `Fx.madrid`, `GeneradorConSemilla`) para que los tests sean deterministas.

## 5. Accesibilidad
- **Auditoría automática** (`XCUIApplication.performAccessibilityAudit()`, todas las categorías) en los tests de UI: Hoy (arriba y desplazado hasta el final), globo de la racha, teoría previa, cada una de las 10 mecánicas antes y después de comprobar, y resumen. Cada incidencia se registra con la pantalla en la que aparece y hace fallar el test.
- **Excepciones justificadas (D-048), todas acotadas y registradas en el log como `AUDITORIA-EXCEPCION`:**
  1. contraste de los elementos de Hoy bajo la barra de pestañas flotante o el borde superior del sistema;
  2. el texto de Hoy tras el popover modal del globo de la racha;
  3. el contraste de los elementos del contenido del scroll que quedan fuera de su área visible (ocultos o recortados por el borde).
- Si la auditoría agota su tiempo (código -56, simulador lento), se repite una sola vez; las incidencias reales nunca se reintentan.
- **Prueba manual** en el simulador con texto AX5 (`xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large`) y en modo oscuro; las capturas `30_ax_*` y `2x_oscuro_*` de [docs/capturas/fase05a](docs/capturas/fase05a/) y `3x_oscuro_*` y `4x_ax_*` de [docs/capturas/fase05a1](docs/capturas/fase05a1/) son la evidencia.
- Contraste: paleta comprobada con la fórmula WCAG 2.x (UX_UI.md §4.1).

## 6. Tests de interfaz (Fase 05A)
| Test | Qué comprueba |
|---|---|
| `testRondaRecomendadaCompleta` | Hoy (auditado arriba y al final) → globo de la racha (abrir, auditar y cerrar tocando fuera) → ronda recomendada (semilla 42, progreso en memoria) → 6–8 ítems → resumen → Hoy con la racha a 1 día |
| `testDiezMecanicasConAuditoria` | Ronda de demostración con un ítem de cada mecánica; 8 se responden con **toques reales en modo sin arrastre** (elección, V/F, clasificar, emparejar, marcar, segmentar con anidamiento, construir y teclado numérico) y 2 (ordenar y ruedas) con el botón de pruebas; todas deben dar "¡Correcto!" |

Opciones de arranque (solo Debug): `-enMemoria -semilla 42 -ayudasDePrueba [-rondaDemostracion]`.

## 7. Capturas
```sh
scripts/capturas.sh build/DD/Build/Products/Debug-iphonesimulator/Educulter.app docs/capturas/fase05a        # 05A
scripts/capturas.sh build/DD/Build/Products/Debug-iphonesimulator/Educulter.app docs/capturas/fase05a1 05a1  # lo que cambia en la 05A.1
scripts/capturas.sh build/DD/Build/Products/Debug-iphonesimulator/Educulter.app /tmp/lote01 lote01         # los 38 ítems del lote 01 (revisión)
swift scripts/hoja_contactos.swift <carpeta> <carpeta>/HOJA.png
```

## 8. Criterios de terminado
Una tarea está terminada solo si se ha compilado o ejecutado y se ha comprobado de verdad.
