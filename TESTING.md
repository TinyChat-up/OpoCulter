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
Objetivo: cobertura de `Core/` ≥ 90 % (desde la 05A). Última medición (Fase 05B): **Core 97,1 %** (2 521 / 2 597 líneas) y **Features 87,2 %** (6 077 / 6 969; incluye los tests de UI). En la 05A.1: Core 97,2 % y Features 86,3 %. Reloj, calendario y aleatoriedad se inyectan (`RelojFijo`, `Fx.madrid`, `GeneradorConSemilla`) para que los tests sean deterministas.

## 5. Accesibilidad
- **Auditoría automática** (`XCUIApplication.performAccessibilityAudit()`, todas las categorías) en los tests de UI: Hoy (arriba y desplazado hasta el final), globo de la racha, teoría previa, cada una de las 10 mecánicas antes y después de comprobar, y resumen. Cada incidencia se registra con la pantalla en la que aparece y hace fallar el test.
- **Excepciones justificadas (D-048), todas acotadas y registradas en el log como `AUDITORIA-EXCEPCION`:**
  1. contraste de los elementos de Hoy bajo la barra de pestañas flotante o el borde superior del sistema;
  2. el texto de Hoy tras el popover modal del globo de la racha;
  3. el contraste de los elementos del contenido del scroll que quedan fuera de su área visible (ocultos o recortados por el borde).
- Si la auditoría agota su tiempo (código -56, simulador lento), se repite una sola vez; las incidencias reales nunca se reintentan.
- **Prueba manual** en el simulador con texto AX5 (`xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large`) y en modo oscuro; las capturas `30_ax_*` y `2x_oscuro_*` de [docs/capturas/fase05a](docs/capturas/fase05a/) y `3x_oscuro_*` y `4x_ax_*` de [docs/capturas/fase05a1](docs/capturas/fase05a1/) son la evidencia.
- Contraste: paleta comprobada con la fórmula WCAG 2.x (UX_UI.md §4.1).

## 6. Tests de interfaz (Fases 05A y 05B)
| Test | Qué comprueba |
|---|---|
| `testRondaRecomendadaCompleta` | Hoy (auditado arriba y al final) → globo de la racha (abrir, auditar y cerrar tocando fuera) → ronda recomendada (semilla 42, progreso en memoria) → 6–8 ítems → resumen → Hoy con la racha a 1 día |
| `testDiezMecanicasConAuditoria` | Ronda de demostración con un ítem de cada mecánica; 8 se responden con **toques reales en modo sin arrastre** (elección, V/F, clasificar, emparejar, marcar, segmentar con anidamiento, construir y teclado numérico) y 2 (ordenar y ruedas) con el botón de pruebas; todas deben dar "¡Correcto!" |

| `testTodasLasMecanicasConAuditoria` | Ronda de demostración con las **12 mecánicas** (incluidas `colocarTilde` y `fraccionBarras` con toques reales) y auditoría de cada una |
| `PilotoUITests.testBienvenidaYProgresoTrasCerrarYReabrir` | Almacén SwiftData en disco: bienvenida y avatar → ronda → **cierra la app y la vuelve a lanzar** → misma racha, nivel/XP, misiones, avatar y diagnóstico (peldaño y caja de Leitner por competencia, Rescate y XP); sin bienvenida al reabrir; cambio de avatar en Perfil. Audita la bienvenida, Hoy v2 y Perfil |
| `PilotoUITests.testRondaDeMatematicasConFraccionBarras` | Contenido de Release: Hoy → selector Matemáticas → ronda de MAT.NUM; cada `fraccionBarras` se responde **tocando celdas y −/+** (fracción leída del enunciado), sin arrastre; misión de Matemáticas cumplida si es la del día |
| `PilotoUITests.testRondaDeLenguaConColocarTilde` | Contenido de Release, semilla 10: ronda de LEN.ORT.AGU con `colocarTilde` respondida **tocando la vocal o «Sin tilde»** |
| `RendimientoUITests` | Arranque en frío (`XCTApplicationLaunchMetric`) y manipulación de `fraccionBarras` (colorear, dividir) y `colocarTilde` (`XCTHitchMetric`, `XCTCPUMetric`, `XCTClockMetric`) |

Opciones de arranque (solo Debug): `-enMemoria -semilla N -ayudasDePrueba -avatar N [-rondaDemostracion] [-politicaRelease] [-almacenPruebas NOMBRE -borrarAlmacen] [-captura ESCENA]` (D-044, D-058).

`RondaViewModelTests` usa ayudas que solo existen en Debug y va dentro de `#if DEBUG`; así el paquete de tests también compila en Release (para medir el arranque con la app optimizada).

## 7. Capturas
```sh
scripts/capturas.sh build/DD/Build/Products/Debug-iphonesimulator/Educulter.app docs/capturas/fase05a        # 05A
scripts/capturas.sh build/DD/Build/Products/Debug-iphonesimulator/Educulter.app docs/capturas/fase05a1 05a1  # lo que cambia en la 05A.1
scripts/capturas.sh build/DD/Build/Products/Debug-iphonesimulator/Educulter.app /tmp/lote01 lote01         # los 38 ítems del lote 01 (revisión)
swift scripts/hoja_contactos.swift <carpeta> <carpeta>/HOJA.png
```

## 8. Criterios de terminado
Una tarea está terminada solo si se ha compilado o ejecutado y se ha comprobado de verdad.

## 9. Rendimiento (Fase 05B, simulador iPhone 16, iOS 27.2)
| Medida | Herramienta | Resultado |
|---|---|---|
| Arranque en frío, del inicio del proceso a la primera vista (Release) | Marcas temporales (instrumentación temporal, retirada) | **0,58–0,76 s** en 3 de 4 arranques; un valor atípico de 1,54 s. El primer arranque tras instalar tarda 3,8 s (el sistema prepara el binario) |
| Arranque en frío, del inicio del proceso a la primera vista (Debug) | Ídem | 0,58–0,60 s |
| `XCTApplicationLaunchMetric` (hasta que responde) | XCTest, 5 iteraciones | Debug 3,46 s de media (3,33–3,65); Release 4,65 s (3,44–6,77). Incluye el lanzamiento del proceso por XCTest en el simulador |
| App Launch (Instruments) | `xctrace --template "App Launch"` | El simulador no registra la tabla de ciclo de vida (sale vacía) |
| Tirones de fotogramas | `XCTHitchMetric` e Instruments «Animation Hitches»/«SwiftUI» | **No disponible en el simulador**: Instruments indica "Hitches is not supported on this platform" y la métrica de XCTest no genera datos. Hay que medirlo en el iPhone (test `RendimientoUITests`, listo para ejecutarse en el dispositivo desbloqueado) |
| CPU de la app al manipular (aproximación) | `XCTCPUMetric` y `XCTClockMetric`, 5 iteraciones | Colorear y descolorear 12 celdas (24 toques): 1,28 s de CPU (≈ 53 ms por toque). Dividir de 2 a 12 partes y volver (20 toques): 1,31 s (≈ 66 ms por toque). `colocarTilde` (7 toques): 0,41 s (≈ 58 ms por toque). Incluye las consultas de accesibilidad de XCTest en cada toque, por lo que no equivale al coste de un fotograma |

**Medición complementaria en el iPhone 16 físico** (estaba conectado y desbloqueado al final de la fase):

| Medida | Resultado |
|---|---|
| `XCTApplicationLaunchMetric` (Debug, 5 iteraciones) | **0,60 s** de media (0,57–0,68) |
| `fraccionBarras`: dividir de 2 a 12 partes y volver (`XCTHitchMetric`, 5 iteraciones) | **0 tirones** (Hitch Time Ratio 0 ms/s). CPU 2,0 s para 20 toques, incluidas las consultas de XCTest |
| `fraccionBarras` (colorear 12 celdas) y `colocarTilde` en el dispositivo | No se completaron: el test no encontró `celda_8` ni `letra_7` en el iPhone, aunque en el simulador pasan. Probable causa: el tamaño de texto del dispositivo. Pendiente para la 05C |

Conclusión: el arranque (≈ 0,6 s en el simulador desde el inicio del proceso y 0,60 s en el iPhone) cumple el objetivo de < 1,5 s. En el dispositivo no hay tirones al redibujar la barra; los otros dos gestos quedan pendientes de medir en el dispositivo (05C).

