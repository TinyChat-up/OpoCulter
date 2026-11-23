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
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

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
Objetivo: cobertura de `Core/` ≥ 80 %. Reloj, calendario y aleatoriedad se inyectan (`RelojFijo`, `Fx.madrid`, `GeneradorConSemilla`) para que los tests sean deterministas.

## 5. Accesibilidad
<!-- Auditorías de VoiceOver, Dynamic Type y contraste -->

## 6. Criterios de terminado
Una tarea está terminada solo si se ha compilado o ejecutado y se ha comprobado de verdad.
