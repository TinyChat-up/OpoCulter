# Estado del proyecto

**Fase actual:** 05E parte 2 (identidad editorial, sesión diaria, motor de errores y ejemplos resueltos) · **Terminada y fusionada en `main`**.
**Siguiente:** lo que decida la dirección tras el informe de la parte 2 (lotes de datos pendientes y Fase 05F/06).
**Última actualización:** 2026-11-26

## Fase 05E parte 2 — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Test de 1000 historiales de `ConstructorSesion` | ✅ En verde. Causa raíz en el constructor (no en el test): se corrigió la colocación pieza a pieza | D-108 |
| Identidad editorial (logo v5) | ✅ Paleta, fuentes del sistema, estilo plano, personajes recoloreados, `MarcaView` y lanzamiento | D-109, `PaletaTests`, `PersonajesV3Tests` |
| Interfaz de §3 y §4 | ✅ Hoy, resumen, Rescate por error, errores en Progreso, Ajustes (meta y descanso), peldaños | D-111, `SesionDiariaUITests` |
| §5 ejemplos resueltos | ✅ Pasos con porqué en 15 generadores y `oracionSimple`; ejemplo + gemelo; retirada de ayudas; «Nivel examen» | D-112, `PasosResueltosTests`, `EjemploResueltoTests` |
| Distractores estáticos sin etiquetar | 13, todos de competencias sin errores en el catálogo (se quedan así) | D-113 |
| Tests unitarios | ✅ **662** en verde (batería completa) | `xcodebuild test` |
| Tests de interfaz | ✅ 23 de interfaz: la batería completa dio 9 fallos (adaptación a la interfaz nueva); corregidos y repetidos hasta 0 fallos | t17, t32, t33 |
| Cobertura | ✅ Core **96,0 %** · Features 87,6 % · App 83,8 % | `xccov` |
| Auditoría de accesibilidad | ✅ Sin incidencias en claro, oscuro y texto grande (Hoy, ejemplo resuelto, resumen, Progreso, Ajustes, Rescate) | `SesionDiariaUITests` |
| Avisos del compilador | ✅ 0 (Debug, tests y archive Release) | logs |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Recorrido con capturas (`RecorridoParte2UITests`) y arranque en frío **0,86 s** de mediana (0,85–0,97) | [docs/capturas/fase05e2/](docs/capturas/fase05e2/) |

## Pendiente (05E parte 2)
1. **Arranque**: 0,86 s en frío en el iPhone; cumple < 1,5 s, pero no el objetivo de ≤ 0,7 s de §1b.7.
2. **Datos de la dirección**: verbos irregulares, 70 palabras ambiguas con contexto, predicativo y complemento del nombre, 24 tarjetas de teoría.
3. **Captura del icono en la pantalla de inicio del iPhone**: no se obtuvo (al pulsar Inicio, el iPhone volvió a otra app abierta y esa captura se descartó por privacidad).
4. Decisiones para la dirección: ver el informe (misiones sin interfaz, estado «descanso» de los personajes sin pantalla, ojos y boca de Cuarto en papel).

## Fase 05E parte 1 — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Auditoría real | ✅ Inventario, cobertura del mapa (0 completas, 48 parciales, 63 vacías), enseñanza y 20 ítems revisados | [docs/AUDITORIA_05E.md](docs/AUDITORIA_05E.md) |
| Cobertura del examen real | ✅ La app entrena el **33,1 %** de las 139 preguntas (sí + parcial: 63,3 %) | `tribunal/equivalencias.json`, D-097 |
| Mapa curricular en la app | ✅ 21 bloques, 111 competencias del mapa, ids conservados | D-091, [docs/MAPA_CURRICULAR_A1.md](docs/MAPA_CURRICULAR_A1.md) |
| Calibración «nivel examen» | ✅ 67 anclas; 39 reproducidas en el nivel 4 (1000 semillas cada una) | `calibracion/anclas.json`, `AnclasTests`, D-096 |
| Palabras ambiguas | ✅ 70 fuera de los generadores sin contexto | D-092 |
| Gramática natural (D-090) | ✅ Test de propiedades por regla y nivel | `GramaticaCompatibilidadTests` |
| LEN.SIN, LEN.VER y LEN.LIT | ✅ 37 plantillas aprobadas, 0 en borrador | D-093–D-095 |
| Progreso con texto grande y base literaria | ✅ | D-097, D-094 |
| Tests unitarios + UI | ✅ 219 en verde (202 unitarios y 17 de interfaz) y 2 omitidos a propósito, en una sola ejecución | `** TEST SUCCEEDED **` |
| Cobertura | ✅ Core **95,8 %** (generadores 94,9 %, `Core/Modos` 97,9 %) · Features 87,5 % · App 83,2 % | `xccov` |
| Auditoría de accesibilidad | ✅ Sin incidencias (también en el iPhone) | Tests de UI |
| Avisos del compilador | ✅ 0 (Debug, tests, iPhone y archive Release) | logs |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Instalada; una ronda real de LEN.SIN, LEN.VER y LEN.LIT; arranque en frío **0,87 s** (0,81–0,92) | `RondasLenguaUITests`, `RendimientoUITests` en el dispositivo |
| Catálogo de preguntas (Release) | **≥ 230 813** (LEN 76 289 · MAT 154 524) | `CatalogoPreguntas` |

## Pendiente
1. **Decisiones para la dirección**: ver el informe de la 05E parte 1 (sintaxis en el nivel 4, ecuaciones del examen, 33 tarjetas de teoría, plantillas en borrador de MAT.DIV, MAT.EST y MAT.PRO, frases con contexto de las 70 palabras ambiguas).
2. Arranque 0,87 s frente a 0,67 s: generar bajo demanda las variantes de las plantillas (mejora propuesta).
3. **Cuenta de Apple:** Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
4. Runtime de iOS 17 en el simulador: Fase 07 (D-008).

## Recuperación — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Lote 02 terminado | ✅ Las 38 plantillas superan los tests de propiedades; léxico con 0 discrepancias | D-077, TESTING §12 |
| Verificación conjunta 05D + lote 02 | ✅ Suite completa, archive Release sin avisos, arranque y recorrido en el iPhone | D-077, TESTING §11–12 |
| Integración (6 fusiones en orden) | ✅ Compilación y tests unitarios en verde tras cada fusión (con 2 commits de ajuste) | DECISIONES «Renumeración de la recuperación» |
| Textos base, gramática con compatibilidad, frases y base literaria | ✅ | D-085–D-089 |
| Tests unitarios + UI | ✅ 189 unitarios (41 suites) y 17 de interfaz (1 omitido a propósito, solo para Instruments), en verde | TESTING §13 |
| Cobertura | ✅ Core **95,3 %** (generadores 93,6 %, `Core/Modos` 98,1 %) · Features 87,6 % · App 83,2 % | `xccov` |
| Auditoría de accesibilidad | ✅ Sin incidencias, también en las pantallas nuevas (texto base desplegado, plegado y corregido) | Tests de UI |
| Avisos del compilador | ✅ 0 (Debug desde cero en el iPhone y archive Release) | logs |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Instalada con todo integrado; arranque en frío **0,67 s** de media (0,63–0,71); recorrido completo (bienvenida → … → Ajustes, comprensión y frases) en verde | `xcodebuild test` en el dispositivo |
| Catálogo de preguntas (Release) | **≥ 146 933** preguntas distintas: LEN 3849 (LEN.ORT 3800, LEN.LEX 30, LEN.COM 19) y MAT 143 084 | `CatalogoPreguntas` |

## Pendiente (recuperación, histórico)
1. **Decisiones para la dirección** (informe de la recuperación; resueltas en la 05E salvo la redacción de frases con contexto): palabras del léxico que sin tilde son otra palabra válida (`colocarTilde` no da contexto), oraciones forzadas de la gramática generativa, «5 %» partido en dos líneas en la cabecera de Lengua de Progreso con texto grande, y la correspondencia entre las competencias del Tribunal y las del catálogo (25 propuestas no existen con ese nombre).
2. Revisar las 28 competencias que propone la matriz en el lote de contenido correspondiente (no se añaden todavía). El lote 03a resolvió 5 de las 33 iniciales.
3. **Cuenta de Apple:** Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
4. Runtime de iOS 17 en el simulador: Fase 07 (D-008).
5. Ramas temporales locales `wip/seccion4` y `wip/seccion4b` (solo en este Mac, no subidas): copias de trabajo de la recuperación, sin uso.

## Fase 05D — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Camino, Supervivencia, Rescate, diagnóstico y plan, Progreso, ajustes, sonido y recordatorio | ✅ | D-069–D-074, UX_UI §4.12 |
| Tests unitarios | ✅ 173 (37 suites), en verde en 4 ejecuciones | `xcodebuild test` |
| Tests de interfaz nuevos (5) | ✅ Los 5 en verde en la suite completa del 24/11 | `ModosUITests` |
| Tests de interfaz anteriores (9) | ✅ Cada uno ha pasado tras las correcciones, pero no todos en la misma ejecución. La última suite completa se cortó porque el Mac entró en reposo (batería) | TESTING §11 |
| Auditoría de accesibilidad | ✅ Sin incidencias en las pantallas nuevas. El contraste se audita en una pasada aparte (D-075) | Tests de UI |
| Cobertura | ✅ Core **96,2 %** (`Core/Modos` 98,0 %) · App 82,1 % · Features 73,3 % (ejecución cortada) | `xccov` |
| Avisos del compilador | ✅ 0 (app y tests, tras corregir 3) | logs |
| iPhone físico | ✅ Instalada y abierta (Debug) | `devicectl` |
| Archive Release y arranque medido en el iPhone | ✅ En la recuperación (D-077) | `xcodebuild archive`, `RendimientoUITests` |
| Capturas | Omitidas por decisión del propietario | — |

## Pendiente (05D, histórico)
Resuelto en la recuperación: suite completa en verde, archive Release, arranque medido en el iPhone y `testCaminoNodoYPruebaDeNivel` en verde.

## Fase 05C — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Plan de contenidos (anexo A) | ✅ | [docs/PLAN_CONTENIDOS.md](docs/PLAN_CONTENIDOS.md) |
| Matriz de exámenes | ✅ 7 cuadernillos, 139 preguntas; condiciones de reutilización y textos protegidos señalados | [MATRIZ.md](docs/examenes/MATRIZ.md), [FUENTES.md](docs/examenes/FUENTES.md), D-067 |
| Estilo Rubber Hose, Fredoka y personajes | ✅ AA comprobado (ajustes registrados) | UX_UI §4, D-059, D-060 |
| Avatares del propietario | ✅ 6, migración `id % 6` guardada | D-061 |
| Generadores, dificultad 1–6, léxico, gramática y catálogo | ✅ 16 tipos y 23 plantillas de prueba (borrador) | D-062–D-066 |
| Tests unitarios + UI | ✅ 152 unitarios (33 suites) y 9 de UI, 0 fallos | `** TEST SUCCEEDED **` |
| Auditoría de accesibilidad | ✅ Sin incidencias nuevas | `RondaUITests`, `PilotoUITests` |
| Cobertura | ✅ Core **96,2 %** (generadores 95,2 %) · Features 83,4 % | `xccov` |
| Avisos del compilador | ✅ 0 | logs |
| Rendimiento | ✅ Arranque en el iPhone 0,70 s; 0 tirones en las 3 medidas de fluidez en el dispositivo; ronda de 8 ítems en < 50 ms | [TESTING.md §10](TESTING.md) |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Instalada y medida | `xcodebuild test` en el dispositivo |
| Capturas | ✅ [docs/capturas/fase05c](docs/capturas/fase05c/) (48 + HOJA.png: claro, oscuro, AX5) | `scripts/capturas.sh … 05c` |
| Catálogo de preguntas | Release **59** (contenido aprobado); Debug **≥ 55 943** con las plantillas de prueba | `CatalogoPreguntas` |

## Pendiente (05C, histórico)
Las competencias propuestas por la matriz y la cuenta de Apple siguen en el «Pendiente» de arriba. Los «pendientes con Mac» de las ramas de datos (literatura, lote 03a, lote 02b y Tribunal) se resolvieron en la recuperación (D-085–D-089).

## Fase 05B — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Misión premium y dirección C "Laboratorio táctil" | ✅ Documento vinculante enlazado desde CLAUDE.md | [docs/MISION_PREMIUM.md](docs/MISION_PREMIUM.md), D-053 |
| Sistema de diseño v2 | ✅ Colores AA (ajustes registrados), radios 16/10/4, sin sombras, un panel tintado por pantalla, animaciones ≤ 0,35 s con fundido en Reducir movimiento | [UX_UI.md §4](UX_UI.md), D-054 |
| Personajes Tilde y Cuarto | ✅ `Shape`, 6 estados con disparadores reales, ≤ 64 pt, ocultos a VoiceOver, `RepresentacionPersonaje` (.vectorial / .ilustracion) | UX_UI §4.9–4.10, D-056 |
| 12 avatares | ✅ Bienvenida, Perfil, cabecera de Hoy; persistidos en SwiftData | UX_UI §4.11, D-057 |
| Mecánicas `colocarTilde` y `fraccionBarras` | ✅ Payload, validador, evaluador, errores y corrección con solución | `PilotoTests` |
| Piloto: Hoy rediseñado, rondas de Lengua y Matemáticas, misión completable | ✅ | `PilotoUITests` |
| Contenido (anexos 1–4) | ✅ Pasa el validador sin cambios. Release: 50 ítems y 5 tarjetas LEN.ORT, 9 ítems y 2 tarjetas MAT.NUM | [CONTENIDOS.md](CONTENIDOS.md) |
| Tests unitarios + UI (iPhone 16, iOS 27.2) | ✅ 130 tests unitarios en 27 suites y 10 de UI (1 omitido a propósito: solo para xctrace), 0 fallos | `** TEST SUCCEEDED **` |
| Persistencia tras cerrar y reabrir | ✅ | `testBienvenidaYProgresoTrasCerrarYReabrir` |
| Auditoría de accesibilidad | ✅ 0 incidencias; excepciones acotadas de D-048 | `CasoUI.auditar` |
| Cobertura | ✅ Core **97,1 %** (2 521 / 2 597) · Features 87,2 % (6 077 / 6 969) | `xccov` |
| Avisos del compilador | ✅ 0 | logs |
| Rendimiento | ✅ Arranque en el dispositivo: 0,60 s; dividir la barra, 0 tirones. Simulador: 0,58–0,76 s desde el inicio del proceso | [TESTING.md §9](TESTING.md) |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Instalada y abierta | `devicectl` |
| Capturas | ✅ [docs/capturas/fase05b](docs/capturas/fase05b/) (37 + HOJA.png: claro, oscuro, AX5) | `scripts/capturas.sh … 05b` |

## Pendiente (05B)
1. En el dispositivo, las medidas de fluidez de colorear y colocarTilde no localizaron `celda_8` ni `letra_7`. Se revisan en la 05C. Dividir la barra sí se midió: 0 tirones.
2. **Cuenta de Apple:** Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
3. Runtime de iOS 17 en el simulador: Fase 07 (D-008).

## Fase 05A.1 — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Pulido visual (A1–A8) | ✅ Margen inferior en Hoy, "No es correcto" con "Continuar" del color del área, fichas de 52 pt y mecánica repartida, recompensas (pulso, vuelo de XP, hitos de combo, XP animado), símbolo por bloque, globo de la racha, "Otra ronda" del área predominante y segmentar mejorado | [UX_UI.md](UX_UI.md), D-049–D-051 |
| Lote 01 · LEN.ORT | ✅ 5 competencias, 38 ítems y 5 tarjetas; pasa el validador sin cambios; Ortografía exprés lo usa | [CONTENIDOS.md §5](CONTENIDOS.md), D-052 |
| Release carga exactamente 38 ítems y 5 tarjetas de LEN.ORT y ningún borrador | ✅ | `releaseNoCargaBorradores` |
| Revisión visual de los 38 ítems en su mecánica | ✅ | capturas del conjunto `lote01` |
| Tests unitarios + UI (iPhone 16, iOS 27.2) | ✅ 109 tests unitarios (Swift Testing) y 2 de UI, 0 fallos | `xcodebuild test` → `** TEST SUCCEEDED **` |
| Auditoría de accesibilidad | ✅ 0 incidencias; 3 excepciones acotadas y justificadas (D-048) | `RondaUITests` |
| Cobertura | ✅ Core **97,2 %** · Features 86,3 % · App 91,9 % | `xccov` |
| Avisos del compilador | ✅ 0 (tests y archive) | logs |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Instalada y abierta (`com.educulter.dev`) | `devicectl` |
| Capturas | ✅ [docs/capturas/fase05a1](docs/capturas/fase05a1/) + HOJA.png | `scripts/capturas.sh … 05a1` |

## Pendiente (05A.1, histórico)
1. **Observaciones de contenido del lote 01** para la dirección (no se ha cambiado nada): LEN.ORT.HIA.0003 («reloj» como aguda en -z), LEN.ORT.DIA.0003 (ambigüedad él/mí) y LEN.ORT.DIA.0008 (terminología «adjetivo posesivo»). Detalle en el informe de la 05A.1.
2. **Cuenta de Apple:** Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
3. Runtime de iOS 17 en el simulador: Fase 07 (D-008).
