# Estado del proyecto

**Fase actual:** 05A.1 — Pulido visual y lote 01 de contenido (LEN.ORT) · **Terminada**
**Siguiente:** Fase 05B — Resto del MVP (bienvenida, diagnóstico, Mapa, Examen, Progreso, sonido y más contenido real), a la espera de instrucciones de la dirección.
**Última actualización:** 2026-11-23

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

## Pendiente
1. **Observaciones de contenido del lote 01** para la dirección (no se ha cambiado nada): LEN.ORT.HIA.0003 («reloj» como aguda en -z), LEN.ORT.DIA.0003 (ambigüedad él/mí) y LEN.ORT.DIA.0008 (terminología «adjetivo posesivo»). Detalle en el informe de la 05A.1.
2. **Cuenta de Apple:** Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
3. Runtime de iOS 17 en el simulador: Fase 07 (D-008).
