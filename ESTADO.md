# Estado del proyecto

**Fase actual:** 00 — Preparación técnica · **Terminada** (con un aviso abierto, ver "Pendiente")
**Última actualización:** 2026-11-23

## Fase 00 — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| macOS ≥ 15.6 | ✅ 27.2.1 (26B131), arm64, 8 GB de RAM, 68 GB libres | `sw_vers`, `uname -m`, `sysctl`, `df` |
| Xcode ≥ 26 | ✅ Xcode 27.2 (27B52) | `xcodebuild -version` |
| Runtime iOS ≥ 26 | ✅ iOS 27.2 | `xcrun simctl list runtimes` |
| git | ✅ 2.54.0 | `git --version` |
| Tests en simulador iPhone 16 (iOS 27.2) | ✅ 1 unitario + 1 UI, `** TEST SUCCEEDED **` | `xcodebuild test` |
| Compilación e instalación en el iPhone 16 físico | ✅ `** BUILD SUCCEEDED **`, app instalada | `xcodebuild build`, `devicectl device install app` |
| La app se abre en el iPhone | ✅ "Launched application", proceso `Educulter` en marcha | `devicectl device process launch` / `info processes` |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`, arm64, 0.0.1 (1). **No subido** | `xcodebuild archive` |

## Pendiente
1. **Tipo de cuenta de Apple.** El equipo `BG34ARBG5W` genera perfiles que caducan a los 7 días (creado el 23/11/2026, caduca el 30/11/2026), lo que corresponde a un *Personal Team* gratuito, no a una membresía de pago del Apple Developer Program. Basta para desarrollar, pero **TestFlight y el App Store requieren la membresía de pago** (Fases 08 y 09). Mientras tanto, la app instalada en el iPhone dejará de abrirse cada 7 días hasta que se vuelva a instalar desde el Mac.
2. Runtime de iOS 17 en el simulador, para probar el target mínimo: previsto en la Fase 07 (D-008).

## Próxima fase
Fase 01 — Investigación (a la espera de instrucciones de la dirección del proyecto).
