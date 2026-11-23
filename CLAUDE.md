# CLAUDE.md — Guía para Claude Code

> "Educulter" es el nombre en clave interno del proyecto, no la marca comercial.

## Propósito

App nativa de iPhone para preparar la prueba común A1 (Lengua Castellana y Literatura + Matemáticas) de las oposiciones de Maestros de la Comunidad de Madrid. Contexto completo en [CONTEXTO.md](CONTEXTO.md).

**Misión premium (vinculante):** [docs/MISION_PREMIUM.md](docs/MISION_PREMIUM.md). Nada simulado ni decorativo; cuatro modos sobre el mismo motor (Camino, Supervivencia, Rescate y Tribunal); dirección visual C "Laboratorio táctil" con personajes y avatares originales; no se reescribe lo que funciona.

## Roles

- **Dirección del proyecto:** otra instancia de Claude (web). Define fases y aprueba alcance.
- **Claude Code (técnico):** decide y ejecuta lo técnico, y registra cada decisión en [DECISIONES.md](DECISIONES.md).
- **Propietario:** intermediario entre ambas instancias. **No se le piden decisiones técnicas.** Solo se le piden acciones físicas o de credenciales (iniciar sesión, conectar el iPhone, aceptar diálogos del sistema), con instrucciones paso a paso.

## Reglas permanentes

- Nunca subas al repositorio contraseñas, tokens, certificados, claves privadas (.p8/.p12), perfiles de aprovisionamiento ni datos personales.
- No hagas gastos, compras, publicaciones, envíos a revisión de Apple ni cambios en App Store Connect sin autorización explícita transmitida por el propietario.
- No des nada por hecho sin evidencia: una tarea está terminada solo si se ha compilado o ejecutado y se ha comprobado de verdad.
- No desarrolles funciones fuera de la fase en curso.
- Tecnologías Apple nativas: Swift, SwiftUI, SwiftData, StoreKit 2, y CloudKit si se justifica. **Sin SDKs de terceros**, ni de analítica ni de seguimiento, salvo una decisión registrada.
- La accesibilidad se trabaja desde el principio: VoiceOver, Dynamic Type, Reducir movimiento, alternativas a los gestos y contraste.
- Principio de producto: **escribir lo mínimo**. En el aprendizaje diario no se usa el teclado del sistema: las respuestas son táctiles (tocar, arrastrar, deslizar, construir con piezas) y hay un teclado numérico propio para resultados.
- Contenido educativo: solo original o de dominio público, con su procedencia registrada. Nunca se copia material de academias ni editoriales.
- Idioma de la app y de la documentación: español de España.

## Forma de trabajo

1. **Ramas:** `main` es la rama estable. Cada fase se desarrolla en `fase-XX/descripcion`.
2. **Integración:** cuando la fase está verificada, se fusiona en local con `git merge --no-ff` y se sube con `git push -u origin main`.
3. **Herramientas:** solo `git` para el repositorio (no `gh`). Proyecto Xcode sin generadores externos.
4. **Verificación mínima antes de fusionar:**
   - `xcodebuild test` en simulador de iPhone 16 → todos los tests en verde.
   - Compilación Release (`xcodebuild archive`) correcta, **sin subirla**.
   - Cuando aplique: instalación y apertura en el iPhone físico.
5. **Documentación:** al cerrar cada fase se actualizan [ESTADO.md](ESTADO.md), [ROADMAP.md](ROADMAP.md) y [DECISIONES.md](DECISIONES.md).
6. **Informe de fase:** se entrega con el formato fijo (resumen, rama y commit, archivos, pruebas, resultados, errores pendientes, decisiones, acciones del propietario, próximo paso).

## Estructura del código

```
Educulter.xcodeproj        Proyecto (grupos sincronizados con carpetas)
Educulter/
  App/                     Punto de entrada y composición raíz
  Features/                Una carpeta por funcionalidad
  Core/                    Modelos, persistencia, servicios compartidos
  Content/                 Contenido educativo empaquetado (JSON versionado)
  Resources/               Assets, catálogos de cadenas
EduculterTests/            Tests unitarios (Swift Testing)
EduculterUITests/          Tests de interfaz (XCTest)
```

Los archivos que se añaden a estas carpetas entran solos en el target, sin tocar el `.pbxproj`. Los archivos de marcador `.gitkeep` están excluidos del target.

## Comandos de referencia

```sh
# Tests en simulador
xcodebuild test -project Educulter.xcodeproj -scheme Educulter \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Archive Release (no se sube)
xcodebuild archive -project Educulter.xcodeproj -scheme Educulter \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Educulter.xcarchive
```
