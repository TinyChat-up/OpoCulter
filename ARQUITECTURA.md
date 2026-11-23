# Arquitectura

> **Propósito:** describir la estructura técnica de la app y sus límites.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) §8. Este documento detalla la implementación (Fase 04).

## 1. Base
- SwiftUI + Observation, Swift 6 con concurrencia estricta, iOS 17.0+, solo iPhone y en vertical.
- Sin backend, sin cuentas y sin SDKs de terceros.
- Tests: `EduculterTests` (Swift Testing) y `EduculterUITests` (XCTest).

## 2. Capas y módulos

```
Educulter/
  App/                Punto de entrada (pantalla de verificación hasta la Fase 05)
  Core/
    Comun/            DiaCivil, Reloj, GeneradorConSemilla, Racional
    Content/          Modelos del banco, CargadorContenido, ValidadorContenido
    Learning/         Evaluador, EstadoCompetencia (escalera + Leitner), ColaRescate,
                      ConstructorRondas, SesionDiagnostico
    Gamification/     CalculadoraXP, CurvaNiveles, EstadoRacha, GeneradorMisiones, MotorLogros
    Progress/         RepositorioProgreso (protocolo), RepositorioEnMemoria,
                      RepositorioSwiftData y modelos @Model
  Content/            JSON empaquetado (ver CONTENIDOS.md)
```

Principios:
- **El núcleo es Swift puro**: tipos valor `Sendable`, funciones deterministas, sin SwiftUI ni UIKit. Solo `Core/Progress` importa SwiftData.
- **Reloj, calendario y aleatoriedad inyectables**: `Reloj` (`RelojSistema`/`RelojFijo`), `Calendar` del usuario y cualquier `RandomNumberGenerator` (`GeneradorConSemilla` en tests).
- **Todo lo que depende del día** trabaja con `DiaCivil` (año, mes, día en calendario gregoriano y zona horaria del usuario), no con `Date` (D-021).
- **Configuración explícita**: cada regla numérica (4 de 5, intervalos de Leitner, tamaño de ronda, XP, curva, protectores) está en un `struct Configuracion…` con valores por defecto.

## 3. Modelo de datos (SwiftData)
Modelos en [ModelosSwiftData.swift](Educulter/Core/Progress/ModelosSwiftData.swift), **compatibles con CloudKit** (D-022): todas las propiedades con valor por defecto u opcionales, sin `@Attribute(.unique)` y sin relaciones. Los valores compuestos (misiones, métricas, diagnóstico) se guardan como JSON en `Data`.

| Modelo | Contenido |
|---|---|
| `IntentoRegistro` | Cada respuesta: ítem, competencia, peldaño, acierto, fracción, pista, confianza, XP, motivo |
| `EstadoCompetenciaRegistro` | Peldaño, ventana de intentos, caja, próximo y último repaso (días `AAAAMMDD`) |
| `RescateRegistro` | Cola de Rescate con su posición |
| `PerfilRegistro` | XP total, racha (actual, récord, protectores, días) y misiones/métricas (JSON) |
| `LogroRegistro` | Logros obtenidos |
| `DiagnosticoRegistro` | Último resultado del diagnóstico (JSON) |

El acceso pasa por el protocolo `RepositorioProgreso` (`@MainActor`), con dos implementaciones: SwiftData y en memoria. Los tests ejecutan el mismo contrato contra ambas. Sin `.unique`, las claves naturales se buscan con predicado y, ante duplicados (posibles al sincronizar), se toma el registro más avanzado.

## 4. Carga y validación de contenidos (JSON versionado)
- `CargadorContenido.desdeBundle()` lee la carpeta `Content` (empaquetada como carpeta explícita, D-018).
- `PoliticaCarga.porDefecto`: `todos` en Debug y `soloAprobados` en Release.
- `ValidadorContenido` devuelve errores legibles (`elemento: mensaje`). Un test exige que todo el contenido del bundle lo pase. Reglas en [CONTENIDOS.md §2](CONTENIDOS.md#2-formato-de-contenido-esquema-v1).

## 5. Concurrencia y aislamiento de actores
**No se activa el aislamiento por defecto en MainActor** (D-017, cierra D-011). El núcleo es `nonisolated` y `Sendable`, para poder cargar y validar contenido o construir rondas fuera del hilo principal y testearlo sin saltos de actor. Son `@MainActor` de forma explícita: el repositorio de progreso (por `ModelContext`) y, en la Fase 05, los modelos de vista.

## 6. Compras (StoreKit 2)
Fase 06. El acceso premium se determinará con `Transaction.currentEntitlements` (ver [MONETIZACION.md](MONETIZACION.md)).

## 7. Sincronización (CloudKit)
**Decisión (D-022):** CloudKit queda fuera del MVP, como fija el diseño aprobado, pero los modelos ya son compatibles. Activarlo requerirá la membresía de pago, el contenedor de iCloud y añadir `cloudKitDatabase: .automatic` en `EsquemaProgreso.contenedor`.

## 8. Privacidad y datos
Todo el progreso es local. No hay analítica ni seguimiento. No se recogen datos personales.
