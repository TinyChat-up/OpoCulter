# Estado del proyecto

**Fase actual:** 05B — Transformación premium: piloto vertical · **Terminada**
**Siguiente:** Fase 05C, a la espera de instrucciones de la dirección.
**Última actualización:** 2026-11-23

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
