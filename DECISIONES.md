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

## Fase 04 — Núcleo del producto

### D-017 · 2026-11-23 · Fase 04 · Vigente (cierra D-011)
**No se activa el aislamiento por defecto en MainActor.** El núcleo (`Core/Comun`, `Content`, `Learning`, `Gamification`) es Swift puro con tipos valor `Sendable` y `nonisolated`: así se puede cargar y validar el contenido o construir rondas fuera del hilo principal, y los tests no necesitan saltos de actor. Con el aislamiento por defecto, cada tipo del núcleo quedaría atado al MainActor y habría que marcarlo `nonisolated` uno a uno, que es justo lo que se quiere por defecto. Son `@MainActor` de forma explícita el repositorio de progreso (porque `ModelContext` no es `Sendable`) y, en la Fase 05, los modelos de vista (las vistas de SwiftUI ya lo son).

### D-018 · 2026-11-23 · Fase 04 · Vigente
**`Content/` se empaqueta como carpeta explícita** (`explicitFolders` del grupo sincronizado). Los grupos sincronizados copian los recursos aplanados en la raíz del bundle, y `items/LEN.SIN.json` y `teoria/LEN.SIN.json` colisionaban. Con la carpeta explícita el bundle conserva `Content/items`, `Content/teoria` y `Content/simulacros`, y los archivos nuevos siguen entrando sin tocar el `.pbxproj`. Se descartó excluir la carpeta del grupo (Xcode 27 no respeta la exclusión de carpetas completas) y renombrar los archivos con prefijos.

### D-019 · 2026-11-23 · Fase 04 · Vigente
**Formato de identificadores y archivos de contenido:** archivos `items/<id de bloque>.json` y `teoria/<id de bloque>.json` (p. ej. `LEN.SIN.json`); competencia `<bloque>.CODIGO` (2–16 mayúsculas o dígitos); ítem `<competencia>.NNNN`; tarjeta `<competencia>.TNN`; simulacro `SIM.NN`; referencia a examen `AAAA-L9`/`AAAA-M9`. Detalle en CONTENIDOS.md §2.1.

### D-020 · 2026-11-23 · Fase 04 · Vigente
**Extensiones compatibles del esquema v1** (ningún campo pedido cambia de nombre): `numerico.exigeIrreducible` (opcional) para pedir fracción irreducible; `pistas`, `erroresHabituales` y `referencia` opcionales en el JSON (por defecto vacíos); `textoBase` del simulacro opcional y `autor`/`obra` admiten `null`. `Resultado.errores` contiene ids de elementos del ítem (o el texto tecleado en `numerico`), y con ellos se elige el feedback de `erroresHabituales` (tabla en CONTENIDOS.md §2.5).

### D-021 · 2026-11-23 · Fase 04 · Vigente
**Días civiles (`DiaCivil`)** para todo lo que depende del día (racha, Leitner, misiones): año, mes y día del calendario gregoriano en la zona horaria del usuario, persistidos como entero `AAAAMMDD`. La aritmética de días se hace en UTC, de modo que el horario de verano y la medianoche no crean días de 23 o 25 horas. Si el usuario tiene otro calendario (budista, japonés…), se usa igualmente el gregoriano.

### D-022 · 2026-11-23 · Fase 04 · Vigente (resuelve la parte técnica de D-004)
**CloudKit: no en el MVP; modelos preparados.** Modelos SwiftData planos (sin relaciones), con valores por defecto u opcionales y sin `.unique`; los valores compuestos (misiones, métricas, diagnóstico) se guardan como JSON. El contenedor se crea con `cloudKitDatabase: .none`. El acceso pasa por el protocolo `RepositorioProgreso` con implementaciones SwiftData y en memoria; ante registros duplicados (posibles tras sincronizar), se toma el más avanzado. Activar CloudKit exigirá la membresía de pago y una decisión nueva.

### D-023 · 2026-11-23 · Fase 04 · Vigente
**Leitner por competencia:** el primer intento de una competencia la coloca en la caja 1 con repaso al día siguiente. Después, solo el **primer intento de un día en que está vencida** mueve la caja (acierto +1, fallo −2, mínimo 1); los demás intentos de ese día no la mueven. Sin esta regla, una sola ronda subiría una competencia hasta la caja 5.

### D-024 · 2026-11-23 · Fase 04 · Vigente (matizada por D-032 y D-037)
**Escalera:** solo cuentan los intentos con ítems del peldaño actual (los repasos de peldaños inferiores no hacen subir). Con 4 aciertos entre los 5 últimos intentos (o 4 de 4) se sube y la ventana se vacía. "Dominada" = peldaño 5 alcanzado. La regla es configurable en general y por peldaño (p. ej. el peldaño 1, que solo tiene 1–2 ítems guiados).

### D-025 · 2026-11-23 · Fase 04 · Vigente
**Rondas:** objetivo de 7 ítems (mínimo 6, máximo 8); como mucho 3 repasos, para no desplazar la competencia en curso; el peldaño 5 no entra en rondas (va a simulacros y Retos de bloque); si una competencia no tiene ítems de su peldaño, se usa el inferior más cercano. La competencia en curso solo usa ítems no vistos en 24 h; si faltan, se rellena con otras competencias empezadas y, solo como último recurso, se repiten ítems recientes. En el peldaño 1 la ronda incluye las tarjetas de teoría de la competencia.

### D-026 · 2026-11-23 · Fase 04 · Vigente
**Racha:** los días se cierran de uno en uno, así que el resultado no depende de cuántas veces se consulte. Un día cerrado sin ronda consume un protector; si no quedan, la racha se rompe (se conserva el récord). Los días protegidos mantienen la racha pero no la aumentan. El día 1 de cada mes los protectores se **rellenan hasta 2** (no se suman). "Semana completa" = cada 7 días activos de racha, +1 protector; máximo 3 acumulados. Se empieza con 2.

### D-027 · 2026-11-23 · Fase 04 · Vigente
**XP y niveles:** acierto sin pista = 10 + 5; +10 en el peldaño 4; +5 al rescatar un error ("Rescatar da XP extra"); 0 si se usó pista o si se falla. Multiplicador de combo ×(1 + 0,1·(n − 1)), hasta ×1,5 desde el 6.º acierto seguido; se redondea al entero más cercano. Curva de niveles: XP acumulada del nivel n = 100·(n − 1)^1,5 (nivel 2 = 100, nivel 10 = 2 700), con un máximo de 100 niveles.

### D-028 · 2026-11-23 · Fase 04 · Vigente
**Diagnóstico:** primer ítem de cada bloque ★★★ con dificultad lo más cercana posible a 2, de los peldaños 2–4, alternando Lengua y Matemáticas. Nivel por bloque: 0, 0,5 o 1 (ver DISENO_PEDAGOGICO.md §2). El plan incluye solo los bloques con contenido; los no evaluados cuentan con debilidad 0,5. Empates: mayor prioridad y después el orden del catálogo.

### D-029 · 2026-11-23 · Fase 04 · Sustituida por D-031
**Prioridades de bloque provisionales**, a la espera de la dirección: ★★★ LEN SIN, ORT, CLA, VER, LIT, COM y MAT UNI, GEO, POR, NUM, DIV, OPE (12 bloques, unos 12–24 ítems de diagnóstico); ★★ el resto. El catálogo incluye solo las competencias que necesita el contenido de prueba.

### D-030 · 2026-11-23 · Fase 04 · Vigente
**Reglas del validador además de las pedidas:** 2–4 opciones en `eleccion` y 2–4 categorías en `clasificar` (según el catálogo de mecánicas); 1–5 ruedas; la licencia debe ser coherente con el tipo (`original` → `propia`, `dominioPublico` → `dominio publico`); un elemento `aprobado` exige `revisor` y `fecha` `AAAA-MM-DD`; los errores habituales de `eleccion` deben ser opciones incorrectas; formato de las referencias a exámenes.

## Fase 05A — Sistema de diseño, mecánicas y flujo de ronda

### Resoluciones de la dirección

### D-031 · 2026-11-23 · Fase 05A · Vigente (dirección)
**Prioridades de bloque definitivas.** ★★★: LEN.SIN, LEN.COM, LEN.LIT, LEN.CLA, LEN.ORT, LEN.VER · MAT.UNI, MAT.GEO, MAT.POR, MAT.NUM, MAT.DIV, MAT.OPE. ★★: LEN.LEX, LEN.REC, LEN.MET, LEN.FOR · MAT.ROM, MAT.EST, MAT.PRO. El diagnóstico usa los 6 + 6 bloques ★★★, con un máximo de 2 ítems por bloque. Coinciden con las provisionales (D-029), así que el catálogo no cambia.

### D-032 · 2026-11-23 · Fase 05A · Vigente (dirección)
**Peldaño 1:** se supera con 2 aciertos en los 2 últimos intentos; se pueden repetir los ítems guiados. Implementado como regla por defecto en `ConfiguracionEscalera.estandar`.

### D-033 · 2026-11-23 · Fase 05A · Vigente (dirección)
**Pistas solo en los peldaños 1 y 2.** El validador rechaza ítems de peldaño ≥ 3 con pistas, y la interfaz solo ofrece el botón "Pista" en los peldaños 1–2.

### D-034 · 2026-11-23 · Fase 05A · Vigente (dirección)
**Teoría tipo `esquema`:** una fila por línea; `Etiqueta: valor` en dos columnas y `A → B` como flecha. Si los dos puntos aparecen antes de la primera flecha, la línea es un par. Lo interpreta `FilaEsquema` (núcleo) y lo maqueta `VistaEsquema`.

### D-035 · 2026-11-23 · Fase 05A · Vigente (dirección)
**Aprobación de contenido:** `revisor = "direccion"` cuando aprueba la dirección; fecha `AAAA-MM-DD`.

### D-036 · 2026-11-23 · Fase 05A · Vigente (dirección)
**ROADMAP:** las Fases 01–03 figuran como "Completadas (integradas en el diseño v1)".

### Decisiones técnicas

### D-037 · 2026-11-23 · Fase 05A · Vigente
**Contenido escaso por peldaño.** Si una competencia no tiene ítems de su peldaño ni de los inferiores, la ronda usa el peldaño superior más cercano (hasta el 4), y la escalera cuenta los intentos con ítems del peldaño actual **o superior** (antes, solo del actual). Sin esto, una competencia nueva (peldaño 1) sin ítems de peldaño 1 no podría avanzar nunca.

### D-038 · 2026-11-23 · Fase 05A · Vigente
**Paleta ajustada a AA.** Se conserva el matiz de cada color de la dirección y se ajusta la luminosidad hasta ≥ 4,5:1 como texto en el peor fondo: Lengua claro `#C73F1C`, Matemáticas oscuro `#7581DE`, Éxito claro `#257E55`, Fallo `#D13030`/`#DC6060`, y ámbar como texto en claro `#9C620A`. El ámbar `#F2A93B` se mantiene como relleno de recompensa, siempre con texto `#141518` (9,1:1). Sobre los acentos, texto blanco en claro y `#141518` en oscuro. Tabla completa en UX_UI.md §4.1.

### D-039 · 2026-11-23 · Fase 05A · Vigente
**Feedback como panel inferior**, no como hoja modal: así la corrección en el sitio (verde/rojo) sigue visible y desplazable mientras se lee la explicación. "Ver regla" sí abre una hoja (media o completa).

### D-040 · 2026-11-23 · Fase 05A · Vigente
**Hápticos con `sensoryFeedback` de SwiftUI** (iOS 17): `.success`, `.error`, impacto medio cada 3 aciertos y `.selection` al seleccionar, colocar o arrastrar. Sin generadores de UIKit ni servicio propio.

### D-041 · 2026-11-23 · Fase 05A · Vigente
**Sonido:** protocolo `ServicioSonido` con la implementación vacía `SonidoSilencioso`; la implementación real llega en la 05B.

### D-042 · 2026-11-23 · Fase 05A · Vigente
**Competencia en curso:** se guarda en el perfil y se mantiene hasta que se domina o se queda sin ítems. La siguiente es la primera sin dominar por prioridad de bloque (★★★ primero) y orden del catálogo. En la 05B la sustituirá el plan del diagnóstico.

### D-043 · 2026-11-23 · Fase 05A · Vigente
**`ServicioSesion` (Core/Sesion, `@MainActor`)** orquesta el núcleo: prepara rondas (recomendada, Rescate, Ortografía exprés, ítems concretos), registra cada respuesta (escalera, Leitner, Rescate, XP, métricas, misiones, logros e intento) y cierra la ronda (racha, misiones y logros). Los view models solo gestionan la secuencia en pantalla, y la lógica queda cubierta por tests del núcleo. Cada respuesta se guarda al comprobar; salir a mitad no pierde nada y no cuenta para la racha.

### D-044 · 2026-11-23 · Fase 05A · Vigente
**Opciones de arranque solo en Debug:** `-enMemoria`, `-semilla N`, `-ayudasDePrueba` (botón "Rellenar (pruebas)"), `-rondaDemostracion` (un ítem por mecánica) y `-captura <escena>`. En Release se ignoran (`#if DEBUG`). La pantalla de revisión usa un progreso en memoria aparte, para no alterar el real.

### D-045 · 2026-11-23 · Fase 05A · Vigente
**Contrato de las mecánicas:** cada vista escribe el borrador en un único `Binding<Respuesta?>`, y `Respuesta.esCompleta(para:)` (núcleo) decide si se activa "Comprobar". El modo sin arrastre (tocar y luego el destino) está siempre disponible. Ordenar empieza en el orden del archivo (rotado si coincide con el correcto). Emparejar identifica cada par por color **y** número. Ruedas usa un control segmentado con ≤ 3 opciones cortas y un menú en el resto. Segmentar anida automáticamente y rechaza los tramos que se cruzan (UX_UI.md §6).

### D-046 · 2026-11-23 · Fase 05A · Vigente
**Se retira la pantalla de verificación** de la Fase 00 y sus dos tests; los sustituyen la raíz con pestañas y los tests de la 05A.

### D-047 · 2026-11-23 · Fase 05A · Vigente
**Capturas reproducibles sin dependencias:** `scripts/capturas.sh` lanza cada escena en el simulador con `-captura` (claro, oscuro y texto AX5) y `scripts/hoja_contactos.swift` compone `HOJA.png` con AppKit.

### D-048 · 2026-11-23 · Fase 05A · Vigente
**Auditoría de accesibilidad sin incidencias.** `performAccessibilityAudit()` se ejecuta en Hoy, la teoría previa, cada mecánica (antes y después de comprobar) y el resumen, y el test falla si queda alguna incidencia. Para lograrlo: los cambios de disposición por Dynamic Type usan `AnyLayout` (no `ViewThatFits`, que la auditoría marca); no se limita `dynamicTypeSize`; los controles inactivos no se atenúan (`allowsHitTesting` en lugar de `.disabled`, y botón desactivado con contorno y texto secundario); las fichas corregidas conservan el texto en color principal y llevan borde e icono de color. **Única excepción justificada:** en Hoy se ignoran las incidencias de contraste de los elementos que el scroll deja bajo la barra de pestañas translúcida, porque dependen de la posición del scroll y del material del sistema, no de nuestros colores.

> **Revisión en la Fase 05A.1.** Se añadió el margen inferior que pedía la dirección (`contentMargins` de 64 pt): ahora todo el contenido de Hoy se puede desplazar hasta quedar por encima de la barra, y se audita también desplazado hasta el final. **La excepción no desaparece**: la barra de pestañas flotante y el efecto de borde superior del sistema se dibujan *sobre* el contenido del scroll por diseño, y la auditoría mide los elementos por su marco en pantalla aunque estén recortados (se probó `.clipped()` sin efecto). Por eso, en Hoy, solo se ignoran las incidencias de contraste de los elementos que tocan la franja de la barra inferior (90 pt) o la del borde superior (130 pt). Se añade una segunda excepción acotada: con el globo de la racha abierto, el contenido de Hoy queda visible tras el popover modal y VoiceOver lo ignora (es lo correcto), lo que la auditoría marca como "texto potencialmente inaccesible" sin elemento asociado. Tercera excepción acotada, para cualquier pantalla: se ignora el contraste de un elemento **del contenido del scroll que queda fuera de su área visible** (oculto o recortado por el borde; p. ej. la fila "Modo" de ruedas cuando aparece el panel de feedback), porque la auditoría lo mide sobre píxeles que no son suyos. En cuanto se desplaza y queda entero a la vista, vuelve a contar. Los elementos de fuera del scroll (cabecera, pie y botones) nunca se excusan. Cualquier otra incidencia hace fallar el test.

## Fase 05A.1 — Pulido visual y lote 01 de contenido

### D-049 · 2026-11-23 · Fase 05A.1 · Vigente
**Más "juego" y menos "formulario".**
- **Tamaño:** fichas y opciones de al menos 52 pt (`Medidas.fichaMinima`), con texto `.body` y relleno 16 × 12. La mecánica se reparte en el espacio libre: el contenido del ítem ocupa como mínimo el alto visible y la mecánica queda centrada entre dos espaciadores.
- **Fallar no castiga:** tras un fallo, el rojo queda solo en el icono, el título ("No es correcto") y el borde del panel. "Continuar" y "Ver regla" usan el color del área.
- **Recompensa al acertar:**
  - un pulso de escala (1,03) y brillo verde sobre la mecánica;
  - la cápsula "+N XP" vuela desde el panel hasta un nuevo contador de XP en la cabecera, unidos con `anchorPreference`;
  - hitos de combo en ×3, ×5, ×10 y cada 10 más: salto con destello de la cápsula, rebote del rayo e impacto fuerte;
  - el XP del resumen sube contando.
  - Con "Reducir movimiento", todo se queda en fundidos y vibración.
- **Pista y Comprobar** se apilan a todo el ancho con texto de accesibilidad.
- **Construir:** la puntuación pegada a un hueco («{h2}.») viaja con él y no queda sola en una línea.

### D-050 · 2026-11-23 · Fase 05A.1 · Vigente
**Símbolo SF por bloque** (`SimboloBloque`, tabla en UX_UI.md §4.7). Se usa junto al nombre de la competencia en la cabecera de la ronda, en la tarjeta "Ronda recomendada" y, en la 05B, en el Mapa. Un test comprueba que cada bloque del catálogo tiene un símbolo propio y distinto.

### D-051 · 2026-11-23 · Fase 05A.1 · Vigente
**Segmentar:**
- Las etiquetas pasan a una fila de chips justo encima de las palabras.
- El árbol "Tu análisis (n)" se puede plegar; tras corregir, siempre está desplegado.
- **Iluminación en vivo:** tras el primer toque, al pulsar la palabra final el tramo completo se tiñe (estado de ficha `enTramo`) antes de soltar, mediante un `ButtonStyle` que informa de la pulsación. Se descarta seleccionar el tramo arrastrando: competiría con el desplazamiento vertical del `ScrollView` y no tendría alternativa accesible equivalente.

### D-052 · 2026-11-23 · Fase 05A.1 · Vigente
**Lote 01 (LEN.ORT):**
- Las 5 competencias del bloque sustituyen a `LEN.ORT.TILDES`. Sus 5 borradores y su tarjeta se eliminan porque el lote real cubre las mismas mecánicas (en Debug sigue habiendo al menos 3 ítems por mecánica).
- Los ítems de demostración por mecánica (`-rondaDemostracion`, capturas y test de UI) pasan a ser una lista fija (`EntornoApp.demostracionPreferida`); `construir` usa `LEN.ORT.AGU.0008`.
- "Ortografía exprés" toma ya sus 5 ítems del lote real.
