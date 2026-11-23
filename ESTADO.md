# Estado del proyecto

**Fase actual:** 05A — Sistema de diseño, mecánicas y flujo de ronda · **Terminada**
**Siguiente:** Fase 05B — Resto del MVP (bienvenida, diagnóstico, Mapa, Examen, Progreso, sonido y contenido real), a la espera de instrucciones de la dirección.
**Última actualización:** 2026-11-23

## Fase 05A — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| App jugable: Hoy → ronda → 10 mecánicas → corrección → feedback → resumen | ✅ XP, combo, racha, misiones y progreso guardados en SwiftData | `testRondaRecomendadaCompleta`, `RondaViewModelTests` |
| Sistema de diseño (`Features/Comun/Diseno`) | ✅ Colores claro/oscuro AA, tipografía Dynamic Type, espaciado, radios, movimiento, hápticos, 10 componentes | [UX_UI.md](UX_UI.md) |
| Tests unitarios + UI en simulador iPhone 16 (iOS 27.2) | ✅ 122 casos unitarios + 2 tests de UI, 0 fallos | `xcodebuild test` → `** TEST SUCCEEDED **` |
| Auditoría de accesibilidad (Hoy, teoría, 10 mecánicas antes/después, resumen) | ✅ 0 incidencias; 1 excepción justificada (contraste bajo la barra de pestañas, D-048) | `RondaUITests` |
| Prueba manual AX5 y modo oscuro | ✅ | capturas `2x_oscuro_*` y `3x_ax_*` |
| Cobertura | ✅ Core **97,2 %** · Features 85,2 % · App 95,6 % | `xccov` |
| Avisos del compilador | ✅ 0 (tests y archive) | logs |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, **no subido** | `xcodebuild archive` |
| iPhone físico | ✅ Instalada (v0.0.1). ⏳ Apertura pendiente: el iPhone estaba bloqueado | `devicectl` |
| Capturas | ✅ 37 escenas + [HOJA.png](docs/capturas/fase05a/HOJA.png) | `scripts/capturas.sh` |

Mapa, Examen y Progreso muestran "Llega pronto" (fuera de alcance de la 05A).

## Pendiente
1. **Apertura en el iPhone:** desbloquearlo y abrir Educulter (instalada; perfil del Personal Team vigente hasta el 30/11/2026).
2. **Cuenta de Apple:** se mantiene el Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
3. Runtime de iOS 17 en el simulador: Fase 07 (D-008).
4. Contenido de prueba: 30 ítems (3 por mecánica) y 3 tarjetas de teoría, pendientes de aprobación por la dirección; el contenido real llega en la 05B.
