# Registro de decisiones

Formato: `D-NNN · fecha · fase · estado`. Las decisiones no se borran; si cambian, se añade una nueva que sustituye a la anterior.

## Decisiones técnicas ya tomadas (dirección del proyecto)

### D-001 · 2026-11-23 · Fase 00 · Vigente
App nativa con SwiftUI y Swift 6. Solo iPhone y en vertical para el MVP.

### D-002 · 2026-11-23 · Fase 00 · Vigente
Target mínimo iOS 17.0, por SwiftData, Observation y una amplia cobertura de dispositivos. Se compila con el SDK de iOS 26 o superior (Xcode 26+), que es lo que exige Apple desde el 28/04/2026.

### D-003 · 2026-11-23 · Fase 00 · Vigente
Contenido empaquetado en la app (JSON versionado validado por tests), sin generación con IA en tiempo de ejecución.

### D-004 · 2026-11-23 · Fase 00 · Vigente
Progreso local con SwiftData. La sincronización con CloudKit se decide en la Fase 04.

### D-005 · 2026-11-23 · Fase 00 · Vigente
Sin cuentas de usuario propias. La identidad de compra la gestiona Apple (StoreKit 2).

### D-006 · 2026-11-23 · Fase 00 · Vigente
Sin SDKs de terceros.

### D-007 · 2026-11-23 · Fase 00 · Vigente
Bundle ID provisional `com.educulter.dev`; el definitivo, en la Fase 09. No se registra en App Store Connect.

## Decisiones tomadas por Claude Code

### D-008 · 2026-11-23 · Fase 00 · Vigente
**Toolchain real: Xcode 27.2 (27B52), SDK y runtime de simulador iOS 27.2, macOS 27.2.1.**
El requisito es "SDK de iOS 26 o superior"; 27.2 lo cumple. No se instala el runtime de iOS 26: no aporta nada para compilar y ocupa disco. El runtime de iOS 17 (target mínimo) se instalará en la Fase 07 (Calidad) para probar la compatibilidad hacia atrás.

### D-009 · 2026-11-23 · Fase 00 · Vigente
**Simulador de referencia: "iPhone 16" con iOS 27.2**, creado con `simctl` porque Xcode 27 no incluye ese modelo por defecto. Es el mismo modelo que el dispositivo físico del propietario.

### D-010 · 2026-11-23 · Fase 00 · Vigente
**Proyecto Xcode sin generadores** (ni XcodeGen ni Tuist, por D-006). Formato de proyecto 77 con grupos sincronizados con carpetas: los archivos nuevos entran en el target sin editar el `.pbxproj`, lo que reduce conflictos. Los marcadores `.gitkeep` se excluyen explícitamente del target.

### D-011 · 2026-11-23 · Fase 00 · Vigente
**Concurrencia:** `SWIFT_VERSION = 6.0` y `SWIFT_STRICT_CONCURRENCY = complete` en todos los targets. No se activa el aislamiento por defecto en MainActor en el ámbito del módulo, para que la arquitectura (Fase 04) decida explícitamente qué tipos son `@MainActor`.

### D-012 · 2026-11-23 · Fase 00 · Vigente
**Tests:** Swift Testing para los unitarios y XCTest para los de interfaz. Esquema `Educulter` compartido (`xcshareddata`) para que `xcodebuild` funcione igual en cualquier Mac.

### D-013 · 2026-11-23 · Fase 00 · Vigente
**Localización:** región de desarrollo `es`; las cadenas se escriben en español en el código y se extraen a String Catalogs (`LOCALIZATION_PREFERS_STRING_CATALOGS`).

### D-014 · 2026-11-23 · Fase 00 · Vigente
**Versionado:** `MARKETING_VERSION = 0.0.1`, `CURRENT_PROJECT_VERSION = 1` hasta TestFlight. Categoría de la app: Educación.

### D-015 · 2026-11-23 · Fase 00 · Vigente
**Ubicación del repositorio:** `~/Desktop/OpoCulter`, elegida por el propietario al conectar el remoto. El prompt de la fase menciona `~/OpoCulter`; prevalece la ubicación real.

### D-016 · 2026-11-23 · Fase 00 · Vigente
**Firma:** firma automática con el equipo personal del propietario. El `DEVELOPMENT_TEAM` (Team ID) es un identificador público, no un secreto, y se guarda en el proyecto. Los certificados y perfiles los gestiona Xcode en el llavero y nunca entran en el repositorio (`.gitignore`).
