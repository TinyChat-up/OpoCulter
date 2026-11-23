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
<!-- Tests que validan el JSON empaquetado (D-003) -->

## 5. Accesibilidad
<!-- Auditorías de VoiceOver, Dynamic Type y contraste -->

## 6. Criterios de terminado
Una tarea está terminada solo si se ha compilado o ejecutado y se ha comprobado de verdad.
