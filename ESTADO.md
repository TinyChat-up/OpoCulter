# Estado del proyecto

**Fase actual:** 00 — Preparación técnica · **En curso (bloqueada por acciones del propietario)**
**Última actualización:** 2026-11-23

## Fase 00 — Resultado provisional

| Verificación | Resultado | Evidencia |
|---|---|---|
| macOS ≥ 15.6 | ✅ 27.2.1 (26B131), arm64 | `sw_vers`, `uname -m` |
| Xcode ≥ 26 | ✅ Xcode 27.2 (27B52) | `xcodebuild -version` |
| Runtime iOS ≥ 26 | ✅ iOS 27.2 | `xcrun simctl list runtimes` |
| git | ✅ 2.54.0 | `git --version` |
| Tests en simulador iPhone 16 | ✅ 1 unitario + 1 UI, `** TEST SUCCEEDED **` | `xcodebuild test` |
| Compilación Release para dispositivo (sin firmar) | ✅ `** BUILD SUCCEEDED **` | `xcodebuild build CODE_SIGNING_ALLOWED=NO` |
| Archive Release firmado | ⏳ Falta el equipo de firma | `Signing for "Educulter" requires a development team` |
| App en el iPhone 16 físico | ⏳ Falta la cuenta en Xcode y el dispositivo | `devicectl list devices` → sin dispositivos |

## Bloqueos
1. Cuenta de Apple Developer no añadida en Xcode (0 identidades de firma).
2. iPhone 16 no conectado ni con el Modo Desarrollador activado.
3. Identidad de autor de git sin configurar.
