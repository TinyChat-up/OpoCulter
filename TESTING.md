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
Objetivo: cobertura de `Core/` ≥ 90 % (desde la 05A). Última medición (Fase 05C): **Core 96,2 %** (4 561 / 4 739 líneas; generadores 95,2 %, 1 954 / 2 053), **Features 83,4 %** (6 307 / 7 558; incluye los tests de UI) y App 94,7 %. En la 05B: Core 97,1 % y Features 87,2 %. Reloj, calendario y aleatoriedad se inyectan (`RelojFijo`, `Fx.madrid`, `GeneradorConSemilla`) para que los tests sean deterministas.

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

Opciones de arranque (solo Debug): `-enMemoria -semilla N -ayudasDePrueba -avatar N [-rondaDemostracion] [-rondaItems ID1,ID2…] [-politicaRelease] [-almacenPruebas NOMBRE -borrarAlmacen] [-captura ESCENA]` (D-044, D-058, D-077). `-rondaItems` hace que «Empezar ronda» lance esos ítems en orden (también ids generados `<plantilla>#<semilla>`).

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



## 10. Fase 05C: generadores y verificación

**Tests nuevos** (`EduculterTests/GeneradoresTests.swift`, 152 tests unitarios en total, 33 suites):
- **Propiedades**: 1000 semillas por cada una de las 23 plantillas de prueba. En cada ítem se comprueba:
  - que pasa el validador y no deja marcadores sin rellenar;
  - el **oráculo independiente** de su tipo (fórmulas propias, parser de romanos, evaluador de expresiones, fuerza bruta para ecuaciones, m.c.m./m.c.d. y probabilidad, tablas escritas a mano para el léxico y las formas verbales, y concordancia de las oraciones);
  - que los distractores no se repiten ni coinciden con la solución;
  - el determinismo;
  - que la clave pertenece al espacio enumerado.
- **Dificultad 1–6**: la complejidad media de 200 semillas crece con el nivel para cada tipo y mecánica.
- **Motor, validador y conjugación**: ids `#semilla` y regeneración, Release sin plantillas en borrador, plantillas mal formadas, dificultad 6 y formas ambiguas.
- **Léxico**: coherencia con la RAE, informe de discrepancias y deducción de sílabas y tónica.
- **Catálogo**:
  - Recuento completo en menos de 2 s sin cobertura; con cobertura solo se registra (0,99 s).
  - Igualdad entre el recuento paralelo y el secuencial.
  - Duplicados entre plantillas.
  - `ordenarNumeros` limitado a 2000.
- **Ronda y Rescate**: una ronda de 8 ítems con plantillas se genera en **menos de 50 ms**, y Rescate reproduce el ítem por id y encuentra variantes con otras semillas.
- **Avatares y fuente**: 6 avatares, migración `id % 6` en SwiftData guardada en el perfil, y Fredoka registrada y escalada con Dynamic Type.
- **Opcional** (`TEST_RUNNER_ESTIMAR=1`): estimación del espacio de cada generador y recuento del catálogo para el informe.

**Resultado del cierre (23/11/2026, iPhone 16, iOS 27.2):**
- `** TEST SUCCEEDED **`: 152 tests unitarios y 9 de interfaz. El de Instruments se omite a propósito.
- Auditoría de accesibilidad sin incidencias nuevas (`testTodasLasMecanicasConAuditoria` y Piloto).
- Archive Release correcto y sin avisos.

**Rendimiento:**

| Medida | Resultado |
|---|---|
| Arranque en frío en el iPhone 16 físico (`XCTApplicationLaunchMetric`, 5 iteraciones) | **0,70 s** de media (0,59–0,94) |
| Arranque en el simulador (incluye el lanzamiento de XCTest) | 3,32 s de media |
| Fluidez en el iPhone (`XCTHitchMetric`, 5 iteraciones): colorear todas las celdas, dividir la barra de 2 a 12 y volver, y `colocarTilde` | **0 tirones** en las tres (Hitch Time Ratio 0 ms/s) |
| Generar una ronda de 8 ítems con plantillas | < 50 ms (test) |

Los tests de fluidez localizan ahora celdas y vocales **por su posición en pantalla** (ordenadas de arriba abajo y de izquierda a derecha), no por un índice fijo. El primer intento en el dispositivo falló porque el iPhone se bloqueó durante el test; con el bloqueo automático desactivado, pasaron los tres.

## 11. Fase 05D: modos de juego

**Tests unitarios nuevos** (`EduculterTests/ModosTests.swift`; 173 en total, 37 suites):
- **Supervivencia**:
  - sube un nivel cada 4 aciertos seguidos, hasta el 6, y un fallo quita una vida y baja un nivel;
  - puntos: 10 × dificultad × combo, hasta ×2;
  - récords: las partidas abandonadas no cuentan;
  - pesos por bloque de la MATRIZ;
  - el selector da ítems de la dificultad exacta, reproducibles por id;
  - partida completa con efectos reales.
- **Camino**:
  - estados de nodo y candado orientativo;
  - prueba de nivel: 4 de 5 supera, 3 de 5 no;
  - Reto de bloque con ítems fijos y con plantillas: 8 ítems de dificultad 4–5, y 6 aciertos dan la medalla;
  - Practicar.
- **Diagnóstico, Rescate y estadísticas**:
  - plan con bloques fuerte, medio y débil y con 2 recomendaciones;
  - historial de diagnósticos;
  - Rescate por competencia: el contador baja de verdad;
  - estadísticas contra un historial sintético.
- **Recordatorio**, con `CentroNotificaciones` simulado:
  - programa 7 días;
  - no avisa hoy si ya se ha jugado.
- **Sonido**: un espía comprueba que no suena con el sonido desactivado, y cada sonido dura ≤ 250 ms y no satura.
- **Persistencia y contenido**:
  - ajustes, partidas, desbloqueos y diagnósticos se guardan en disco;
  - borrar el progreso conserva los ajustes;
  - los créditos coinciden con CREDITOS.md;
  - las preguntas disponibles son solo las del contenido aprobado.

**Tests de interfaz nuevos** (`EduculterUITests/ModosUITests.swift`, todos con auditoría de accesibilidad):

| Test | Qué comprueba |
|---|---|
| `testBienvenidaDiagnosticoYPlan` | Avatar → diagnóstico → plan → Hoy |
| `testSupervivenciaHastaPerderLasTresVidas` | Semilla fija; partida hasta perder las 3 vidas, con la puntuación exacta en la pantalla final |
| `testCaminoNodoYPruebaDeNivel` | Camino → hoja del nodo → prueba de nivel superada → nodo actualizado |
| `testRescatePorCompetencia` | Estado vacío → errores reales → rescate de una competencia → ver un ítem de nuevo |
| `testRecordYAjustesTrasCerrarYReabrir` | El récord y los ajustes siguen ahí tras cerrar y reabrir la app (almacén en disco) |

**Auditoría (D-075):** `CasoUI.auditarUnaVez` audita primero `.contrast` y después el resto de tipos. En una sola pasada, la comprobación de Dynamic Type desplazaba Hoy cuando estaba al final del scroll, y el contraste se medía fuera del texto.

**Cobertura (05D):**
- Core **96,2 %** (5 252 / 5 457); `Core/Modos` 98,0 %.
- App 82,1 %.
- Features 73,3 %: en esa ejecución, el Mac entró en reposo y 6 tests de interfaz se cortaron antes de recorrer sus pantallas.

**Lección:** la suite completa se lanza con `caffeinate -dims` y el Mac enchufado. En reposo, `testmanagerd` pierde el simulador y los tests fallan por tiempo de espera, no por la app.

## 12. Lote 02: propiedades de las plantillas aprobadas

`EduculterTests/GeneradoresTests.swift`, sobre las 38 plantillas del lote 02 (y las 10 de prueba de la 05C que quedan):
- **1000 semillas por plantilla** (`GeneradoresPropiedadesTests.propiedades`): cada ítem pasa el validador, no deja marcadores sin rellenar, es determinista y su clave pertenece al espacio enumerado (cuando se enumera entero).
- **Oráculo independiente por tipo**: recalcula la solución sin usar el código del generador (fórmulas propias de porcentajes, regla de tres, unidades con su tabla de factores, sexagesimal, escalas, fracciones con un evaluador de expresiones propio, romanos con su propio parser, ecuaciones por fuerza bruta y acentuación con un contador de núcleos vocálicos y las reglas generales).
- **Distractores**: distintos de la solución y entre sí, por texto y **por valor** (0,5 y 1/2 cuentan como el mismo).
- **Dificultad 1→6** (`dificultadCreciente`): la complejidad media de 200 semillas crece de un nivel al siguiente en las de Matemáticas y no decrece en las de Lengua; el nivel 6 siempre supera al 1.
- **Aprobación**: `cobertura` exige que las 38 plantillas del lote estén aprobadas por la dirección y que el resto siga en borrador; `release` comprueba que Release carga exactamente esas 38.
- **Léxico** (`LexicoTests.coherente`): 818 palabras, **0 discrepancias** entre la tilde escrita y el silabeador con las reglas de la RAE, ninguna palabra apartada de los generadores y el oráculo independiente coincide en sílabas, tónica y clase de todas. `deduccion` comprueba el hiato con *h* intercalada (prohíbe, ahínco, rehúso, búho).
- **Recuento del catálogo**: `enumerar` aplica los mismos filtros que `muestra`, de modo que solo se cuentan casos que se pueden generar.
