# Estado del proyecto

**Fase actual:** 04 — Arquitectura y núcleo del producto · **Terminada**
**Siguiente:** Fase 05 — Desarrollo (interfaz del MVP), a la espera de instrucciones de la dirección.
**Última actualización:** 2026-11-23

## Fase 04 — Resultado

| Verificación | Resultado | Evidencia |
|---|---|---|
| Diseño aprobado en el repositorio | ✅ [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md), integrado en DISENO_PEDAGOGICO, UX_UI, ARQUITECTURA y MONETIZACION | — |
| Esquema de contenido v1 | ✅ Modelos `Codable`/`Sendable` en `Core/Content`; documentado en [CONTENIDOS.md](CONTENIDOS.md) | — |
| Tests unitarios en simulador iPhone 16 (iOS 27.2) | ✅ 89 tests (95 casos con argumentos), 0 fallos | `xcodebuild test` → `** TEST SUCCEEDED **` |
| Test de interfaz (pantalla de verificación) | ✅ 1 test, 0 fallos | mismo comando |
| Todo el contenido del bundle pasa el validador | ✅ | `ContenidoEmpaquetadoTests` |
| En Release no se carga ningún borrador | ✅ | `releaseNoCargaBorradores` |
| Cobertura de `Core/` | ✅ **97,8 %** (1 734 / 1 773 líneas) | `-enableCodeCoverage YES` + `xccov` |
| Avisos del compilador Swift 6 estricto | ✅ 0 en app y tests | logs de build, test y archive |
| Archive Release | ✅ `** ARCHIVE SUCCEEDED **`; el `.app` contiene `Content/{catalogo.json, items, teoria, simulacros}`. **No subido** | `xcodebuild archive` |

Fuera de alcance en esta fase (por indicación de la dirección): interfaz de producto y contenido real. La app sigue mostrando la pantalla de verificación, por lo que no se ha reinstalado en el iPhone.

## Pendiente
1. **Cuenta de Apple:** se mantiene el Personal Team hasta que el propietario active la membresía de pago (antes de la Fase 06). Los perfiles caducan cada 7 días.
2. **Prioridades de bloque provisionales** (D-029): debe confirmarlas la dirección.
3. Runtime de iOS 17 en el simulador: Fase 07 (D-008).
