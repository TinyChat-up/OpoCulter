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

## Fase 05B — Transformación premium: piloto vertical

### D-053 · 2026-11-23 · Fase 05B · Vigente (propietario)
**Dirección visual C, "Laboratorio táctil", con personajes y avatares originales.** La misión premium es vinculante ([docs/MISION_PREMIUM.md](docs/MISION_PREMIUM.md)).
- **Sistema de diseño v2** (sustituye la paleta de la 05A): fondo `#FBFBFA`/`#121316`, superficie neutra `#F1F2F4`/`#1C1D22`, y tinte, tinta y primario por área.
- **Solo un panel tintado por pantalla** (`PanelProtagonista`). Lo demás son baldosas neutras sin borde ni sombra, o filas.
- **Radios:** 16 en el panel, 10 en fichas y 4 en celdas.
- **Pesos:** regular y semibold.
- **Animaciones:** ≤ 0,35 s y solo para confirmar acciones. Se retiran los brillos y las sombras de la 05A.1: el pulso al acertar queda en escala, el combo en salto y el vuelo de XP pasa a 0,35 s.
- **Ajustes de contraste AA respecto a la propuesta:**
  - Lengua primario claro `#E4613F` → **`#C94A27`**: el original da 3,45:1 con texto blanco; `#E4613F` se mantiene como primario oscuro.
  - Éxito claro `#257E55` → `#237A52`, Fallo `#D13030` → `#C92D2D` y RecompensaTexto `#9C620A` → `#946007`, para que superen 4,5:1 sobre la superficie neutra y los tintes.
  - Éxito oscuro `#33A872` y Fallo oscuro `#E26A6A`.
  - El texto con color de área usa la **tinta**; el primario queda para rellenos con texto blanco y para objetos manipulables.

### D-054 · 2026-11-23 · Fase 05B · Vigente
**Personajes y avatar.**
- «Tilde» y «Cuarto» se dibujan con `Shape` (sin imágenes) y tienen 6 estados.
- Las reglas de qué estado dispara cada evento están en Core (`ReglasPersonaje`) y cubiertas por tests:
  - feedback: celebra o anima;
  - resumen: celebra si aciertas al menos la mitad;
  - estado vacío: pensando;
  - bienvenida: neutral;
  - racha en riesgo: dormido (hay racha, hoy no hay ronda y quedan menos de 4 h para medianoche);
  - récord: sorprendido.
- Uso: nunca reciben toques, miden ≤ 64 pt en la actividad y son `accessibilityHidden` (el mensaje siempre va en texto).
- Arquitectura: protocolo `RepresentacionPersonaje` con `.vectorial` e `.ilustracion(nombreAsset:)`, inyectable por el entorno.
- **Avatar:** 12 combinaciones originales de forma, tono y accesorio. Se guarda en el perfil (SwiftData, campo opcional `avatar`), se elige en la bienvenida (que aparece mientras no haya avatar) y se cambia en Perfil (desde el avatar de la cabecera de Hoy).

### D-055 · 2026-11-23 · Fase 05B · Vigente
**Rondas por área.**
- Nuevo `TipoRonda.area(String)`: usa la competencia en curso de esa área, que es la global si es de esa área o, si no, la primera sin dominar del área por prioridad.
- El panel protagonista de Hoy tiene un selector Lengua | Matemáticas. Así se pueden cumplir las misiones "Completa 1 ronda de Lengua/Matemáticas", y un test lo comprueba con el contenido del piloto durante 6 días seguidos.
- **El relleno de cualquier ronda prefiere el área de la competencia en curso** antes de recurrir a otras: sin esto, una ronda de Matemáticas con pocos ítems del peldaño se completaba con Lengua.

### D-056 · 2026-11-23 · Fase 05B · Vigente
**Contrato de las mecánicas nuevas.**
- **`colocarTilde`**
  - Respuesta: `Int?` (`nil` = «Sin tilde»). Tocar de nuevo la vocal con tilde deja el ítem sin responder.
  - Errores: `sinTilde`, `conTilde` y `posicion`.
  - Al corregir se resalta la sílaba tónica con una barra en la tinta del área. La calcula `Silabeo`, una división silábica simplificada (diptongos, hiatos, grupos inseparables y «qu»/«gu») probada con 22 palabras.
- **`fraccionBarras`**
  - Respuesta: `(partes, conjunto de celdas)`; la posición no importa y las celdas fuera de la barra no cuentan.
  - Errores: `partes` (división no válida; en ese caso no se juzga lo coloreado) y `coloreadas`.
  - Solución de referencia: en `colorear`, las partes dadas; en `dividirYColorear`, la primera partición permitida o el denominador.
  - El texto de la solución pone la equivalencia cuando difiere del objetivo ("9/12 = 3/4").
  - Partes de 2 a 12. Al cambiar la división, la barra se vacía.
- Los dos payloads codifican los nulos de forma explícita (`"indiceTilde": null`, `"partes": null`).

### D-057 · 2026-11-23 · Fase 05B · Vigente
**Borradores de MAT.NUM.** Las competencias de prueba `MAT.NUM.FRACSUM` y `MAT.NUM.EQUIV`, con sus 3 borradores, su tarjeta y la pregunta 2 de SIM.01, pasan a MAT.OPE (`MAT.OPE.FRACSUM`, `MAT.OPE.EQUIV`) en lugar de eliminarse. Son el único tercer ítem de `ordenar` y el ítem de demostración de `numerico`. Siguen siendo borradores y solo se cargan en Debug.

### D-058 · 2026-11-23 · Fase 05B · Vigente
**Opciones de arranque nuevas (solo Debug):**
- `-avatar N`: salta la bienvenida en tests y capturas.
- `-almacenPruebas NOMBRE` y `-borrarAlmacen`: almacén SwiftData en disco para el test de cierre y reapertura.
- `-politicaRelease`: carga solo el contenido aprobado.

Con `-almacenPruebas`, Hoy muestra una línea de diagnóstico (`ServicioSesion.resumenProgreso()`: peldaño y caja de Leitner por competencia, Rescate, XP y avatar) para que el test compare el progreso guardado antes y después de reabrir.

### D-059 · 2026-11-23 · Fase 05C · Vigente (dirección)
**Estilo "Rubber Hose moderno"**, evolución del sistema v2 (D-053). Toma el lenguaje gráfico general de la animación de los años 20–30 (tinta gruesa, formas gomosas, paleta retro sobre papel) sin copiar personajes, estudios ni juegos: nada de guantes blancos ni ojos "de tarta".
- **Papel** `#FBF3E8` / `#17130F`; **tinta** `#1A1714` (clara `#EDE3D6` en oscuro). Contorno de 2,5 pt (1,5 pt en lo pequeño).
- **Rellenos**: Lengua coral `#F2674B`, Matemáticas azul cielo `#4AA3E8`, recompensa mostaza `#F5B82E`, turquesa `#17A3A3`, oliva `#A7C03A` y violeta, **ajustado de `#9B6BC0` a `#A77ACB`** (tinta sobre `#9B6BC0` = 4,47:1; sobre `#A77ACB` = 5,35:1).
- **El texto sobre un relleno de color va siempre en tinta** (≥ 5,3:1 en los dos modos). El texto con color de área usa tintas oscuras propias (`#A8381A` y `#1F5F99` en claro). Éxito y fallo como texto: `#186B43` y `#B3261E` (el verde se oscurece desde `#1F7A4D` para pasar AA sobre el tinte de Lengua). Se añade `ExitoRelleno` `#5FC98A` para el botón "Continuar" tras acertar. Contrastes en UX_UI §4.1; los comprueba un script al escribir los colores.
- **Radios** 20 (paneles), 14 (fichas) y 6 (celdas).
- **Sombra dura** de 3 pt en tinta, sin desenfoque: es la única sombra y **marca lo que se puede pulsar**. `EstiloPulsable` publica el estado de pulsación en el entorno y `superficiePulsable(…)` desplaza la superficie 3 pt ("se hunde"). Así funciona también con etiquetas anidadas. Lo corregido o desactivado queda plano y sin sombra.
- **Movimiento gomoso**: muelles con rebote (`spring(duration: 0.3, bounce: 0.4)`) y `estiramiento(_:)` (*squash & stretch* 1,08 × 0,92, 0,3 s). Con "Reducir movimiento", fundidos.
- **Personajes** Tilde y Cuarto redibujados con contorno de tinta, brazos y piernas "de manguera" (curvas cuadráticas sin codos), manos redondas del color del cuerpo (no guantes) y ojos ovalados lisos con un punto de luz. Mantienen los 6 estados, los disparadores y la vía `.ilustracion`.

### D-060 · 2026-11-23 · Fase 05C · Vigente
**Fuente de exhibición: Fredoka** (SIL OFL 1.1, Google Fonts), elegida entre Fredoka, Lilita One y Baloo 2 por ser la más redondeada y legible en los tamaños de AX5. Se empaqueta la fuente variable `Resources/Fuentes/Fredoka.ttf` con su `OFL.txt` y se usa la instancia con nombre `Fredoka-SemiBold`. Se registra en tiempo de ejecución con `CTFontManagerRegisterFontsForURL` (sin tocar el Info.plist). En SwiftUI, `Font.exhibicion(_:)` usa `Font.custom(_:size:relativeTo:)`, que escala con `UIFontMetrics` del estilo de texto. Para UIKit y los tests está `FuenteExhibicion.uiFont`, que llama a `UIFontMetrics.scaledFont`. Solo se usa en títulos: el cuerpo va en SF Pro y los números en SF Pro Rounded. Créditos en CREDITOS.md.

### D-061 · 2026-11-23 · Fase 05C · Vigente
**Avatares del propietario.** Sustituyen a los 12 geométricos (D-054).
- **Recorte**: `scripts/recortar_avatares.swift` es reproducible y no tiene ajustes a mano por avatar. Para cada celda de la cuadrícula 3 × 2 toma el color dominante del disco en una corona exterior. Con los extremos izquierdo, derecho y superior de ese color calcula el centro y el radio, y aplica una máscara circular con 2 pt de margen hacia dentro. Exporta PNG a @2x (160 px) y @3x (240 px) en `Assets.xcassets/Avatares/avatar_01…06`.
- **Ids**: del 0 al 5. Los ids de la 05B del 6 al 11 se migran con `id % 6` al leer el perfil, y la migración se guarda la primera vez. Los ids fuera de 0–11 se descartan y el usuario vuelve a elegir. `elegirAvatar` solo acepta 0–5.
- **VoiceOver**: "Avatar con …" con el rasgo descriptivo de cada uno.
- **Selector**: 3 × 2. Todos llevan contorno de tinta; el elegido, además, sombra dura, fondo mostaza y una marca ✓, para que el estado no dependa solo del color.

### D-062 · 2026-11-23 · Fase 05C · Vigente (dirección)
**Motor de generadores paramétricos** (`Core/Content/Generadores`).
- **Plantillas**: una plantilla JSON (`Content/plantillas/<bloque>.json`) declara `tipo`, mecánica, peldaño, dificultad, parámetros, enunciados con marcadores `{{…}}`, contextos opcionales, procedencia y validación.
- **Generadores**: cada `tipo` es un `GeneradorItems` de código que calcula la solución, los distractores (según reglas de error típico, cada uno con su error habitual y su feedback), la clave canónica, la complejidad y los datos para el oráculo de los tests.
- **Determinismo**: `(plantilla, semilla) → Item` siempre da el mismo ítem. Se siembra con FNV-1a del id de la plantilla combinado con la semilla mediante SplitMix64, sin depender del `hashValue` de Swift. Los ids son `<plantilla>#<semilla>` y el validador acepta `<competencia>.Gnn#n`.
- **Integración**: el banco materializa 12 variantes con claves distintas por plantilla a partir de una `semillaBase` de sesión: aleatoria, o fija con `-semilla`. El constructor de rondas las usa igual que los ítems estáticos, y el progreso sigue registrándose por competencia. `BancoContenido.item(id:)` regenera cualquier `#semilla`, de modo que Rescate guarda el id y reproduce el ítem exacto. La búsqueda de variantes de Rescate encuentra las otras semillas materializadas de la misma plantilla.
- **Validación**: el validador comprueba también las plantillas: tipo conocido, mecánica admitida, marcadores que el generador rellena y 5 semillas que generan ítems válidos.
- **Release**: las plantillas de prueba están en borrador, así que Release no las carga.

### D-063 · 2026-11-23 · Fase 05C · Vigente (dirección)
**Dificultad 6 "Experto".** El validador admite dificultades de 1 a 6 en ítems y plantillas. Cada generador documenta en su código cómo escalan sus parámetros por nivel (tablas en UX_UI y CONTENIDOS) y expone una medida de complejidad: pasos, magnitud de los números, cercanía de los valores, tipo de palabra… Un test por tipo y mecánica calcula la media de 200 semillas en cada nivel. En Matemáticas exige que crezca estrictamente del 1 al 6. En los generadores de Lengua, que dependen del tamaño del léxico y del banco de prueba, exige que no decrezca y que el nivel 6 supere al 1.

### D-064 · 2026-11-23 · Fase 05C · Vigente
**`CatalogoPreguntas`: cifra real de preguntas únicas.**
- **Qué se cuenta**: los ítems estáticos (por id) más las claves canónicas únicas de cada plantilla (`tipo|clave`). Dos plantillas que comparten caso no cuentan doble. La mecánica no forma parte de la clave, por prudencia: el mismo caso en dos mecánicas cuenta una vez.
- **Exacto o cota inferior**: los espacios finitos y abarcables se enumeran enteros (porcentajes, unidades, romanos, m.c.m./m.c.d., probabilidad, ecuaciones, fracciones, léxico, verbos y frases). Los combinatorios enormes (operaciones combinadas, estadística y oraciones) se recorren con semillas consecutivas hasta 3000 claves, y el resultado se marca como cota inferior ("≥"). La enumeración por plantilla se corta en 20 000 claves.
- **Rendimiento**: el recuento completo tarda menos de 2 s en la pasada sin cobertura; con cobertura el test solo registra el tiempo (resolución de la dirección). Las plantillas se enumeran en paralelo y la deduplicación se hace después, en orden; un test comprueba que el resultado es idéntico al secuencial. Se cachea por versión de contenido y nunca se calcula al arrancar: solo en Revisión.
- **`ordenarNumeros` no cuenta para el objetivo de 30 000** (resolución de la dirección): su espacio combinatorio (millones de combinaciones) inflaría la cifra. Aporta como mucho 2000 variantes representativas, marcadas con "≥" y una nota. La generación en las rondas no cambia.

### D-065 · 2026-11-23 · Fase 05C · Vigente (dirección)
**Léxico con acentuación deducida.**
- **Entrada mínima**: `{"palabra": …}`. El silabeo sale de `Silabeo.swift` y la sílaba tónica, de la tilde escrita o de las reglas generales. Para los casos que las reglas no resuelven (agudas en -ts/-ns como «robots») se declara `tonica` explícita.
- **Comprobación de coherencia**: se aplican las reglas generales de la RAE (agudas, llanas, esdrújulas y sobresdrújulas; -n/-s tras consonante; hiato con vocal cerrada tónica; monosílabos) y se compara la tilde predicha con la escrita.
- **Discrepancias**: aparecen como errores del validador (elemento "léxico", visibles en Revisión y en el test de contenido), con la forma que predicen las reglas. Además, la palabra queda fuera de los generadores. Las diacríticas (`"diacritica": true`) no se comprueban.
- **Nivel de cada palabra** (1–6): bisílabas regulares; trisílabas; esdrújulas; hiatos; finales especiales o 4+ sílabas; sobresdrújulas o 5+ sílabas.

### D-066 · 2026-11-23 · Fase 05C · Vigente
**Gramática generativa controlada y conjugación.**
- **Sentido de las oraciones**: cada verbo transitivo trae sus propios complementos directos compatibles («preparar la cena»), los sujetos son de persona y un CCT con tiempo («ayer», «mañana») restringe el tiempo verbal.
- **Concordancia**: el verbo en 3.ª persona concuerda en número con el sujeto y el atributo, en género y número.
- **Análisis**: se conoce por construcción y alimenta `segmentar`, `clasificar` y `eleccion`.
- **Conjugador**: regular para -ar, -er e -ir (tiempos simples y compuestos de indicativo, y presente, imperfecto y compuestos de subjuntivo, con vosotros) más una tabla de irregulares en JSON por `modo|tiempo`.
- **Análisis verbal**: no pregunta formas ambiguas dentro del paradigma que ofrecen las ruedas («cantaba», «cantamos»).

### D-067 · 2026-11-23 · Fase 05C · Vigente
**Matriz de exámenes oficiales.**
- **Fuentes**: los PDF se descargan de comunidad.madrid y sede.comunidad.madrid. Las URL, las fechas y los SHA-256 están en `docs/examenes/FUENTES.md`.
- **En el repositorio**: los PDF se guardan, porque el aviso legal permite reutilizarlos sin alterarlos y citando la fuente y la fecha, y los cuadernillos no traen aviso propio de derechos.
- **Extracción**: `scripts/extraer_examenes.swift` usa la capa de texto de PDFKit y, en las páginas que no la tienen, OCR con Vision (es-ES).
- **La matriz**: `docs/examenes/MATRIZ.md` se genera con `scripts/matriz/gen.py`; la clasificación está en `datos.py`. Los resúmenes están redactados con nuestras palabras.
- **Textos con derechos vigentes**: Salinas y Laforet quedan marcados como no mostrables.
- **Tribunal**: no se crea contenido; decide la dirección.

### D-068 · 2026-11-23 · Fase 05C · Vigente
**Competencias nuevas en el catálogo** para las plantillas de prueba que no tenían competencia: `MAT.OPE.ECUAC` (ecuaciones), `MAT.EST.CENTRAL` (media, mediana, moda y rango) y `MAT.PRO.LAPLACE` (probabilidad de un suceso). El catálogo pasa a la versión 2 con 27 competencias. Las demás competencias que propone la matriz (marcadas con † en MATRIZ.md) se dejan a la dirección. En Release estas competencias no tienen ítems todavía y `ServicioSesion` las salta (`valida` exige ítems).

### D-069 · 2026-11-23 · Fase 05D · Vigente (dirección)
**Supervivencia.**
- **Reglas**: 3 vidas y sin cronómetro, por accesibilidad. La dificultad empieza en 1, sube un nivel cada 4 aciertos seguidos hasta el 6 «Experto» y un fallo resta una vida y baja un nivel (mínimo 1).
- **Puntuación**: 10 × dificultad con un multiplicador de combo de +0,25 por acierto seguido a partir del segundo, con tope ×2 (desde el 5.º acierto seguido). Todo está en `ReglasSupervivencia`.
- **Selección de bloque**: por el peso del bloque en los exámenes oficiales (`PesosSupervivencia`, derivado de la MATRIZ: preguntas del bloque entre las de su área), multiplicado por `0,5 + debilidad`. La debilidad sale del peldaño medio de sus competencias, del último diagnóstico o, si no hay ninguno de los dos, vale 0,5.
- **Selección de ítem**: dentro del bloque, un ítem de la dificultad exacta, que puede ser estático (peldaño ≥ 2) o generado con `MotorGeneradores.ajustada` (`<plantilla>@dN#semilla`, reproducible por id, de modo que Rescate funciona). Si no hay ninguno de esa dificultad, se usa el estático más cercano.
- **Efectos reales**: cada respuesta pasa por `ServicioSesion.registrar`, así que hay escalera, Leitner, Rescate y XP sin bonificaciones. La partida terminada cuenta como ronda para la racha y las misiones y se guarda con su historial (`PartidaRegistro`).
- **Récords**: global y por área (Lengua, Matemáticas o mezcla). Se marca récord solo cuando se bate una partida anterior terminada: la primera no cuenta como récord. Las partidas abandonadas se guardan, pero no cuentan.
- **Logros**: Superviviente, Nuevo récord y Nivel Experto. El modo contrarreloj se apunta en el ROADMAP para después del MVP.

### D-070 · 2026-11-23 · Fase 05D · Vigente (dirección)
**Camino, prueba de nivel y Reto de bloque.**
- **Nodos**: `sinContenido` (trazo discontinuo, "En preparación", no se puede pulsar), `disponible`, `enCurso` (con anillo de dominio) y `dominada`.
- **Candado orientativo**: lo llevan las competencias sin empezar que van después de la primera sin dominar del área. Es una recomendación, no un muro: se pueden practicar igualmente o abrir con la prueba de nivel.
- **Prueba de nivel**: 5 ítems del peldaño 3. Con 4 aciertos o más, la competencia pasa al peldaño 3 y queda registrada en `PerfilJugador.desbloqueos`; se concede el logro «Salto de nivel». Solo se ofrece si hay al menos 5 ítems del peldaño 3.
- **Reto de bloque**: 8 ítems sin ayudas (peldaño ≥ 3) de dificultad 4–5, estáticos o generados a esa dificultad. Con 6 aciertos o más se gana la medalla del bloque (`medalla-<bloque>`) y el logro «Primera medalla». Solo aparece si el bloque tiene 8 estáticos válidos o alguna plantilla.

### D-071 · 2026-11-23 · Fase 05D · Vigente
**Diagnóstico en la bienvenida.**
- **Flujo**: avatar → oferta, con "Saltar" → diagnóstico adaptativo (motor de la Fase 04, ítem a ítem en la pantalla de ronda, con «x de N») → plan → Hoy.
- **Contenido**: el diagnóstico usa solo bloques con contenido cargado (en Release, el aprobado) y prefiere los generados de dificultad 2–3 cuando el bloque tiene al menos 2.
- **Plan**: cada bloque como fuerte, medio o débil, «Empezamos por…» con 2 competencias según el orden de debilidad × prioridad, y un aviso honesto de los bloques sin contenido.
- **Historial**: el repositorio conserva todos los diagnósticos; `diagnostico()` devuelve el último. Desde Ajustes se puede repetir.

### D-072 · 2026-11-23 · Fase 05D · Vigente (dirección)
**Recordatorio diario local**, con `UNUserNotificationCenter` y sin servidor.
- **Programación**: notificaciones sueltas para los próximos 7 días (no una repetitiva), de modo que se pueda cancelar solo la de hoy cuando ya se ha hecho una ronda. Se reprograman al abrir la app y al cambiar los ajustes.
- **Permiso en contexto**: se pide tras la primera ronda (o partida) completada, con una explicación previa ("¿Te aviso cada día a las 20:00…?") y los botones "Sí" / "Ahora no". Se pregunta una sola vez.
- **Texto**: útil y sin culpa. Para hoy menciona la racha; para los días siguientes es general, porque esa racha aún no se conoce.
- **Ajustes**: activación y hora.
- **Tests**: el centro de notificaciones se inyecta (`CentroNotificaciones`), y los tests usan uno simulado.

### D-073 · 2026-11-23 · Fase 05D · Vigente (dirección)
**Sonido sintetizado y vibración.**
- **Sonido**: `SonidoSintetizado` genera tonos con AVAudioEngine (seno con un armónico suave y envolvente sin clics), sin archivos de audio de terceros. Cada sonido dura como mucho 250 ms y el de fallo es una nota grave suave.
- **Sesión de audio**: categoría `.ambient` con `mixWithOthers`, así que respeta el interruptor de silencio y no interrumpe la música del usuario.
- **Ajustes**: `SonidoConAjustes` solo reproduce si el sonido está activado. El modificador `retroHaptica` aplica `sensoryFeedback` solo con la vibración activada; sustituye a los 17 usos anteriores.
- **Momentos con sonido**: acierto, fallo, hito de combo, fin de ronda, récord, tilde que cae y celda que se colorea.

### D-074 · 2026-11-23 · Fase 05D · Vigente
**Progreso y persistencia nueva.**
- **Progreso**: dominio (peldaño medio por área y bloque, con la misma medida en los dos), evolución de 4 semanas con Swift Charts (aciertos o XP por día, con `AXChartDescriptor` para el gráfico de audio de VoiceOver), estadísticas, preguntas disponibles (solo contenido aprobado, con `CatalogoPreguntas`), logros obtenidos y pendientes con su condición, ajustes y créditos.
- **Créditos**: se leen de `Resources/Creditos.md`, una copia de CREDITOS.md; un test comprueba que son idénticos.
- **"Borrar mi progreso"**: doble confirmación. Conserva los ajustes.
- **Modelos SwiftData nuevos** (migración ligera: entidades nuevas y atributos opcionales): `PartidaRegistro`, `AjustesRegistro` y `PerfilRegistro.desbloqueosJSON`.
- **Opciones de arranque nuevas (solo Debug)**:
  - `-sinAvisoRecordatorio`: tests de UI y capturas.
  - `-forzarBienvenida`.
  - `-progresoDemo`: capturas. Juega rondas y una partida reales con el motor antes de mostrar la escena.
  - Además, un botón de pruebas "Con error".

### D-075 · 2026-11-24 · Fase 05D · Vigente
**El contraste se audita en una pasada propia, antes que el resto de comprobaciones.**
- **Problema**: con Hoy desplazado hasta el final, la comprobación de Dynamic Type de `performAccessibilityAudit` cambia el tamaño del texto y desplaza el contenido. En una sola pasada, el contraste llegaba a medirse con el marco del elemento ya movido (unos 42 pt más abajo que el texto visible), sobre píxeles que no eran suyos. El elemento afectado cambiaba de una ejecución a otra («Empezar ronda», «5 ítems de ortografía y tildes»), aunque el contraste real del texto es de unos 7:1.
- **Solución**: `CasoUI.auditarUnaVez` ejecuta primero `.contrast` y después todos los demás tipos, con el mismo filtro de excepciones (D-048). No se relaja ninguna regla.
- **Baldosas de Hoy**: se quita el chevrón y el título se parte en dos líneas si no cabe (antes, `lineLimit(1)` + `minimumScaleFactor` recortaban «Supervivencia» y «Ortografía exprés»).

### D-076 · 2026-11-24 · Fase 05D · Vigente (propietario)
**Cierre de la 05D sin capturas y con la fusión aplazada.**
- **Capturas**: el propietario pide no hacerlas en esta fase porque retrasan mucho el trabajo. `scripts/capturas.sh … 05d` queda preparado por si se piden.
- **Tests**: el propietario pide no seguir ejecutándolos. La 05D se guarda con un commit en su rama, pero **no se fusiona en `main`** hasta tener una suite completa en verde y el archive Release, como exige CLAUDE.md. Se puede hacer junto con el cierre de la siguiente fase.
- **Suites largas**: se ejecutan con `caffeinate` y con el Mac enchufado.

### D-077 · 2026-11-24 · Lote 02 · Vigente
**Lote 02: generadores de Matemáticas y de acentuación, y criterio de aprobación.**
- **Alcance**: 11 generadores de Matemáticas (5 nuevos y 6 reescritos con las tablas de dificultad 1–6 de la dirección) y 3 de acentuación (`colocarTilde`, `clasificarAcentuacion`, `silabaTonica`) sobre el léxico de 818 palabras con niveles 1–6. 38 plantillas y 16 competencias nuevas (catálogo v2).
- **Redacciones**: las literales de la dirección viven en el generador (`{{pregunta}}`) para que cada contexto solo se use con datos que tengan sentido; las propias se marcan «A.2» en el código.
- **Aprobación**: una plantilla del lote solo queda `aprobada` si supera los tests de propiedades (1000 semillas, oráculo independiente, dificultad no decreciente 1→6, distractores distintos de la solución y entre sí también por valor, ids únicos). Las 38 los superan.
- **Correcciones al terminar el lote** (el código se adapta; ningún dato cambia):
  - `conversionUnidades`, volumen con dos saltos (×1.000.000, dificultad 2): con valores de 1 a 999 solo valía ~1 % de los casos y una de cada tres semillas no encontraba caso. Ahora se usan cantidades de una cifra al bajar y millones exactos al subir.
  - La medida de complejidad de `conversionUnidades` suma 1 por cada término adicional que hay que convertir y sumar, y mide el número por sus cifras significativas. Sin esto, «cantidad compleja → unidad mayor» (nivel 4) salía menos compleja que «volumen ↔ capacidad» (nivel 3), al revés que la tabla de la dirección.
  - `enumerar` aplica exactamente los mismos filtros que `muestra` en `conversionUnidades` (resultado entero hasta la dificultad 3) y `reglaDeTres` (factor no entero en 3–4): el recuento del catálogo solo cuenta casos que se pueden generar.
  - **Silabeador**: la *h* intercalada delante de la vocal cerrada tónica no impide el hiato («prohíbe», «ahínco», «rehúso»). Eran las 3 discrepancias del informe del léxico; el dato era correcto. El test del léxico exige ahora 0 discrepancias.
- **Tests adaptados al contenido real**: con el lote 02 en Release, la competencia de Matemáticas en curso es `MAT.UNI.LMC` (primera por prioridad de bloque y orden del catálogo), no `MAT.NUM.FRAREP`. `PilotoTests` comprueba la propuesta real y `fraccionBarras` se prueba al practicar «Representar fracciones»; el test de interfaz llega a ella por Camino → nodo → Practicar.
- **Verificación conjunta con la 05D** (tests de interfaz):
  - El peldaño 1 de LEN.ORT.AGU se practica ahora con `silabaTonica` (G04) y las palabras de `colocarTilde` generadas salen del léxico de 818, que el test no conoce. `testRondaDeLenguaConColocarTilde` juega 4 ítems aprobados concretos con la opción nueva `-rondaItems` (solo Debug) y los responde todos con toques reales.
  - En `testRescatePorCompetencia`, con casi toda la ronda en LEN.ORT.AGU peldaño 1, cada acierto posterior rescataba los fallos anteriores de la misma competencia y peldaño (comportamiento de la Fase 04). El test falla ahora todos los ítems y comprueba ese número.
  - `RecorridoUITests`: recorrido de extremo a extremo con una captura de cada pantalla, para revisar en el iPhone lo que ve el usuario.
### D-078 · 2026-11-24 · Lote 05a · Vigente
**Base literaria como datos aparte, sin código.**
- **Ubicación**: `Educulter/Content/literatura/literatura.json`, que en la documentación se cita como `Content/literatura/`, igual que el resto del contenido. `Content` es una carpeta explícita del target, así que el archivo se copiará al bundle sin tocar el `.pbxproj`. `CargadorContenido` solo lee `items`, `teoria`, `simulacros`, `plantillas`, `lexico` y `gramatica`, de modo que la app lo ignora hasta que exista el motor literario (Fase 05F).
- **Validación**: `scripts/validar_literatura.py` (Python 3, solo biblioteca estándar) para validar sin Mac. Cuando exista el motor, sus tests de Swift deberán repetir estas comprobaciones.
- **Dominio público**: regla de la dirección. Muerte en 1945 o antes, o autor anónimo o antiguo sin fechas. Un autor con nacimiento y sin muerte cuenta como vivo.

### D-079 · 2026-11-24 · Lote 05a · errata 1 · Vigente (dirección)
**Base literaria, versión 2.**
- **Géneros**: se añade `ensayo` a Fray Luis y a Lope. Santa Teresa pasa a tener `narrativa` y `ensayo`, y «Las moradas» pasa a `ensayo`. Las greguerías siguen siendo `ensayo` por convención.
- **Clasificación**: dos movimientos nuevos, `TEATRO1900` (Benavente, Arniches y Muñoz Seca) y `G36` (Miguel Hernández). Marsé pasa a `POSGUERRA`, REALISMO termina en 1905 y se corrigen los rasgos de Goethe y de los hermanos Grimm.
- **Fechas**: la obra de Hierro pasa a ser «Quinta del 42» (1952), la de Gil de Biedma, «Moralidades» (1966), y «La casa de Bernarda Alba» lleva el año de escritura (1936).
- **Motor 05F**: las preguntas de movimiento se hacen sobre el autor. Sobre una obra, solo si su año está dentro del rango del movimiento.
- **País**: «Reino Unido» unifica Inglaterra y Escocia, y «Roma» pasa a «Italia».
- **Fragmentos**: se añade el campo `fragmentosPermitidos`, que es `dominioPublico` y además ámbito español o hispanoamericano. De los extranjeros de dominio público solo se admite una traducción propia de la dirección. El validador comprueba esta regla.
### D-080 · 2026-11-24 · Lote 03a · Vigente
**Carpeta `pendiente/` y validador de contenido en Python.**
- **`Content/pendiente/`**: guarda contenido aprobado que necesita algo que el motor aún no tiene (aquí, los textos base de comprensión con `textoRef`). Va dentro de la carpeta `Content`, así que se empaqueta, pero `CargadorContenido` no la lee: no afecta a la app ni a los tests hasta que el motor la admita y los ítems pasen a `items/`.
- **`scripts/validar_items.py`**: reproduce sin Swift las reglas principales de `ValidadorContenido` (CONTENIDOS §2.14) para revisar lotes sin Mac. Cuando el motor admita `textoRef`, el validador de Swift deberá comprobar también que el texto existe.
### D-081 · 2026-11-24 · Lote 02b · Vigente
**Conversión del formato neutro de gramática al esquema de Swift.**
- **Sin inventar contenido**: `FraseHueco.dificultad` y `FamiliaFormas.Forma.uso` son obligatorios y el formato neutro no los trae. Escribir `frases.json` sin ellos haría fallar la decodificación y, con ella, la carga de todo el contenido. Por eso las frases reales quedan en `gramatica/frases_lote02b.json` (que la app no lee) y `frases.json` mantiene los datos de prueba.
- **Derivación gramatical**: sujetos = sustantivos de persona (singular y plural, con artículo). CD = sustantivos compatibles con `objeto` (con artículo; personas y animales con «a» + posesivo, para evitar «al»). CI = «a» + posesivo + persona. «ayer» y «todos los días» restringen el tiempo verbal, como en D-066. Se excluyen de `piezas.json` «junto al río» y «a las cinco», que no tienen una clase de palabra inequívoca.
- **Lo que el esquema no admite** (etiquetas, `admiteCI` completo, CCC…) va a `gramatica/compatibilidad.json`, en formato neutro.
- **Validación**: `scripts/validar_gramatica.py`. El conversor (`scripts/convertir_gramatica_02b.py`) se conserva para regenerar los archivos.

### D-082 · 2026-11-24 · Lote 02b · errata 1 · Vigente (dirección)
**Frases reales y etiquetas finas.**
- `frases.json` pasa a tener las 100 frases y 28 familias reales, ya con `dificultad` y `uso` (deja sin efecto la reserva de D-081).
- `piezas.json` usa las etiquetas finas del CD.
- `verbos.json` conserva tener, decir, poner y hacer (formas de prueba de la Fase 05C) para `analisisVerbal` 5–6 y para el test de conjugación.
- **Plantilla HOM**: el esquema de plantilla admite un solo peldaño, así que «peldaños 2 y 3» se cubre con dos plantillas, `LEN.ORT.HOM.G01` (peldaño 2, dificultad 2) y `LEN.ORT.HOM.G02` (peldaño 3, dificultad 3).
- Las 4 plantillas de `fraseHueco` siguen en borrador hasta pasar los tests de propiedades.
### D-083 · 2026-11-24 · Datos del Tribunal · Vigente
**Exámenes oficiales literales para el Modo Tribunal (borrador).**
- **Ubicación**: `Content/pendiente/tribunal/`, un JSON por examen (esquema en CONTENIDOS §2.15). No lo lee la app; lo hará el motor de la Fase 05E.
- **Literalidad**: los enunciados se copian del texto extraído y se cotejan con el PDF. Cada corrección de OCR, cada tabla transcrita en línea y cada figura descrita se registra en `docs/examenes/CORRECCIONES_OCR.md`.
- **Derechos**: no se reproducen los textos de Salinas (2019 O) y Laforet (2019 A), ni las citas de esos textos dentro de los enunciados. Cada examen lleva fuente, fecha de consulta y aviso de no patrocinio (aviso legal de comunidad.madrid).
- **Soluciones**: las de Matemáticas se calculan con código (`scripts/tribunal/matematicas.py`, aritmética exacta). Las de Lengua y las rúbricas de 2017–2024 son de redacción propia; las rúbricas de 2026 son las plantillas oficiales literales. Todo queda en borrador.
- **Validación**: `scripts/validar_tribunal.py` es un script aparte (no amplía `validar_items.py`, que solo existe en la rama `contenido/lote-03a`), para no crear conflictos al fusionar.
- **Convocatoria 2026**: se descarga la disposición BOCM-20260212-7 para citar la penalización ortográfica (FUENTES §4). Para ello se crea el entorno personal «OpoCulter», con acceso a www.bocm.es y a comunidad.madrid.

### D-084 · 2026-11-24 · Datos del Tribunal · Vigente (dirección)
**Decisiones sobre los datos del Tribunal.**
- **Enunciados oficiales**: no se alteran, ni siquiera con erratas (2024 L8, 2017 M1, 2024 M7).
- **Notas de la app**: la «Nota de la app» al final de `solucionModelo` resuelve las erratas, las ambigüedades (2022 M1, 2026 O L7, 2026 A M6, donde «relacione» se lee como «escriba la probabilidad») y las definiciones imprecisas (2026 O L9 y 2026 A L8, con la definición de la NGLE).
- **Fuentes**: `fuenteSolucion` es `direccion` en todos los exámenes; `fuenteRubrica` es `oficial` en 2026 y `direccion` en el resto. `notaRubrica` explica cómo se aplica la rúbrica oficial en 2026 O L6 y 2026 A L5 (2 de 4 apartados = Regular).
- **Textos protegidos**: sus citas dentro de los enunciados se siguen sustituyendo por la remisión al PDF. No se usa el derecho de cita, por prudencia ante la revisión de Apple.
- **2017**: 1 punto por pregunta, con aviso de que la puntuación la asigna la app.
- **Penalización ortográfica**: `pendiente/tribunal/reglas.json` guarda la regla como datos, sin límite.

### D-085 · 2026-11-25 · Recuperación · Vigente
**Textos base de comprensión (`textoRef`) en el motor y en la ronda.**
- **Datos**: los textos pasan de `pendiente/textos.json` a `textos/textos.json` (carpeta de arrays, como `items/`). Los ítems de `pendiente/LEN.COM.json` pasan a `items/LEN.COM.json` y su teoría a `teoria/LEN.COM.json`. `pendiente/tribunal/` sigue donde está hasta la Fase 05E. `scripts/validar_items.py` lee las rutas nuevas.
- **Modelo**: `Item.textoRef` (opcional) y `TextoBase` (`id`, `titulo`, `autor`, `obra`, `tipo`, `texto`, `procedencia`, `validacion`). El banco filtra los textos con la misma política que el resto (Release: solo aprobados).
- **Validador**: id `TXT.XXX.CLAVE`; título, tipo y texto no vacíos; procedencia (§2.7: un texto de dominio público exige `anioMuerteAutor` y que hayan pasado más de 80 años); en dominio público, `autor` = `procedencia.autorTexto`; un texto original no lleva autor; cada `textoRef` apunta a un texto cargado con la misma política.
- **Vista**: panel superior plegable (`VistaTextoBase`) en una superficie neutra (el panel tintado sigue siendo el de la mecánica), con título y, si es literario, «Autor · Obra (año)». El año sale de la base literaria (Rimas, 1871; Campos de Castilla, 1912), porque `textos.json` no lo trae. Desplegado ocupa como mucho el 30 % del alto de la pantalla (22 % con texto de accesibilidad) y el texto se desplaza dentro si no cabe; el ítem y el pie con «Comprobar» caben siempre debajo (con un alto fijo de 260 pt, la auditoría detectaba texto recortado en el pie con texto grande). Plegado queda la pestaña «Ver texto». Se despliega solo al llegar un texto distinto. Tipo dinámico, VoiceOver (cabecera, botones con etiqueta) y Reducir movimiento. En «Ver de nuevo» de Rescate el texto va entero encima del enunciado.

### D-086 · 2026-11-25 · Recuperación · Vigente
**`compatibilidad.json` conectada a la gramática generativa.**
- `oracionSimple` construye las oraciones con las etiquetas de `compatibilidad.json` (si el archivo existe; si no, con `piezas.json`):
  - **Sujeto** de un sustantivo cuyas etiquetas admite el verbo (`sujeto`): ahora también animales con los verbos que los admiten.
  - **CD** de un sustantivo con una etiqueta de `objeto` del verbo (las finas incluidas: `abrible`, `comprable`, `prestable`, `lavable`…), distinto del sujeto. Personas y animales, con «a su…» como en `piezas.json` (sin la contracción «al», D-081).
  - **CI** de persona, solo con verbos `admiteCI`, nunca el mismo referente que el sujeto (ni que el CD).
  - **Complementos circunstanciales**: como mucho 2, de tipos distintos, de CCL, CCT, CCM y **CCC** (compañía, nuevo en las funciones y en las opciones). «junto al río» y «a las cinco» se siguen excluyendo, como en la conversión de 02b. Un **CCT puede ir delante** (desde el nivel 3, salvo en `segmentar`, donde el predicado quedaría partido): entonces es el primer constituyente y va seguido de coma. Las restricciones de tiempo de los CCT («ayer» → pretérito perfecto simple) salen de `piezas.json`.
  - **Adjetivos** de etiqueta compatible con el sustantivo (sujeto desde el nivel 4; CD desde el 5), concordados con las cuatro formas de los datos: nunca se deriva una forma, así que los invariables en género (amable, azul, caliente, difícil, fácil, grande) solo cambian en número.
  - **Concordancia** artículo-sustantivo (género y número) y sujeto-verbo (número).
  - **Nivel 4**: no hay verbos copulativos en los datos, así que pasa a S (+ adjetivo) + V + CD + CI (+ 0–1 CC) con verbos que admiten CI (si no, el nivel 4 quedaba por debajo del 3 tras fusionar el lote 02b).
- `analisisVerbal` usa los verbos de `compatibilidad.json` y su `participioIrregular` en los tiempos compuestos (escrito, abierto).
- **Validador**: conjugación según el infinitivo, etiquetas de sujeto y objeto que existen en algún sustantivo, formas completas y tipos de complemento válidos.

### D-087 · 2026-11-25 · Recuperación · Vigente
**Ninguna ronda repite una pregunta, aunque cambie el id.** Dos semillas, o dos plantillas del mismo tipo que recurren al mismo nivel de frases (HOM.G01 y HOM.G02 a dificultad 4–5), pueden generar la misma pregunta con ids distintos.
- **Huella** (`Item.huella`): en los ítems generados, la clave canónica del caso (`tipo|clave`, que el motor guarda en `Item.claveGenerada`; en las frases incluye el id de la frase); en los estáticos, su id. Una primera versión por enunciado y solución se descartó: confundía ítems estáticos distintos con enunciado genérico y la misma respuesta.
- La usan el constructor de rondas, la práctica del Camino, la prueba de nivel, el Reto de bloque y Supervivencia (que recibe las huellas de la partida).
- **Frases con hueco**: si no hay frases del nivel pedido ni de los inferiores, el generador usa las del nivel más fácil que haya (antes, todas), para que la dificultad no decrezca (la familia «porque» no tiene frases de dificultad 1).

### D-088 · 2026-11-25 · Recuperación · Vigente
**Base literaria cargada y validada en Swift.** `CargadorContenido` lee `literatura/literatura.json` (`BaseLiteraria`) y el validador repite las reglas de `scripts/validar_literatura.py`: ids únicos, movimiento existente, dos rasgos por movimiento, nacimiento anterior a la muerte, año de cada obra entre el nacimiento y la muerte + 10, géneros y ámbitos válidos, `dominioPublico` coherente con la regla de la dirección y `fragmentosPermitidos` solo en dominio público y en ámbito español o hispanoamericano. Todavía no se generan preguntas (Fase 05F); la app solo la usa para fechar los textos base literarios.

### D-089 · 2026-11-25 · Recuperación · Vigente
**Las 4 plantillas de frases con hueco del lote 02b quedan aprobadas** (`LEN.ORT.DIA.G01`, `LEN.ORT.PQ.G01`, `LEN.ORT.HOM.G01` y `LEN.ORT.HOM.G02`; revisor «direccion», 25/11/2026), porque superan las condiciones de la dirección (`FrasesHuecoTests`, 1000 semillas por plantilla y nivel): una sola opción correcta por frase y distractores = las otras formas de su familia; explicación con el `uso` de la forma correcta; dificultad de la frase 1–6, no decreciente con el nivel pedido; ninguna frase repetida en una práctica, una ronda del motor, un Reto ni una partida de Supervivencia (D-087). Ninguna queda en borrador. Release carga ahora 42 plantillas.

## Renumeración de la recuperación

Al integrar las ramas en `integracion/recuperacion` (25/11/2026), varias ramas habían usado los mismos números. Se conservan los de la primera rama fusionada (`fase-05d/modos`: D-069–D-076) y las decisiones de las ramas siguientes reciben números nuevos consecutivos; sus referencias en CONTENIDOS, ESTADO y el resto de documentos se han actualizado.

| Rama | Número antiguo | Número nuevo |
|---|---|---|
| `fase-05d/modos` | D-069–D-076 | sin cambios |
| `contenido/lote-02` | D-077 | sin cambios |
| `contenido/literatura-05a` | D-069 | D-078 |
| `contenido/literatura-05a` | D-070 | D-079 |
| `contenido/lote-03a` | D-071 | D-080 |
| `contenido/lote-02b` | D-072 | D-081 |
| `contenido/lote-02b` | D-073 | D-082 |
| `contenido/tribunal-datos` | D-074 | D-083 |
| `contenido/tribunal-datos` | D-075 | D-084 |

### D-090 · 2026-11-25 · Fase 05E · Vigente (dirección)
**Gramática generativa: naturalidad.** Reglas de la dirección (§4.2 de la 05E), con test de propiedades de 1000 semillas por plantilla y nivel (`GramaticaCompatibilidadTests`, oráculo que deduce el análisis de la estructura elegida y de los datos, sin leer el texto).
- **Datos** (`compatibilidad.json` v2): `incontable` en leche, café, sopa y zumo (nunca en plural); `preparar` sin CI; adjetivos con `tipo` (`cualidad` o `estado`) y 10 adjetivos de estado nuevos; verbos copulativos `ser`, `estar` y `parecer` con `atributo`; `aspectoCCT` (puntual, habitual, neutro) y `sinHabitual` (comprar, regalar, prestar).
- **CD y CI de persona o animal**: «a» + artículo definido (con «al») o posesivo; niño y niña, solo artículo. El CI siempre es persona.
- **CC**: dos CC de una oración no empiezan por la misma preposición. «Ayer», solo con pretérito perfecto simple; puntual, sin imperfecto; habitual, solo presente o imperfecto.
- **Copulativas**: ser + cualidad, estar + estado, parecer + ambas; predicado **nominal** (núcleo, el verbo copulativo; el adjetivo, atributo). En `segmentar`, la etiqueta del predicado dice «Predicado nominal» o «Predicado verbal».
- **Niveles**: 1 S + V intransitivo · 2 S + V + CD · 3 S + V + CC · 4 copulativa · 5 S + V + CD + CI, o dos CC · 6 CC delante con coma (y sujeto pospuesto con verbo intransitivo). En `segmentar` el predicado tiene que ir seguido: su nivel 6 es S + V + CD + CI + CC en orden canónico. Las preguntas que comparan oraciones (clase, función, concordancia, pronombre) mezclan niveles, porque con uno solo la respuesta sería siempre la misma.
- **Decisiones técnicas añadidas** al leer 50 oraciones por nivel (no las pedía la dirección; se pueden quitar): `ccExcluye` (CC que no casan con un verbo: «nadar en la biblioteca», «descansar deprisa»), `ccSoloPersona` («con su hermana» solo con sujeto de persona), `sinPosesivo` (cocinero, además de niño y niña), `tiemposCopulativos` (ser y parecer solo en presente e imperfecto: «El libro será grande» sonaba forzado) y `ccDelante` (solo CCT o CCL van delante).
- **«a las cinco»** vuelve a usarse: el numeral se marca `num` y, como la contracción «al» (`contr`), no se pregunta en `clasificar`. «junto al río» sigue excluido.
- `ser` y `estar` llevan en `verbos.json` la 3.ª persona de los 4 tiempos que usan las oraciones; `analisisVerbal` no los usa (D-093).

### D-091 · 2026-11-25 · Fase 05E · Vigente
**Mapa curricular de la A1 en el catálogo** (`scripts/cargar_mapa_a1.py`, idempotente; copia en `docs/MAPA_CURRICULAR_A1.md`).
- Se conservan todos los ids y nombres existentes y solo se añaden bloques (LEN.HAB, MAT.ALG) y competencias: 21 bloques (el anexo dice 22, pero sus tablas tienen 21) y 124 competencias (111 del mapa + 13 antiguas). LEN.VER.ANAL del mapa es la existente LEN.VER.ANALISIS.
- **`equivaleA`** (campo nuevo y opcional de la competencia): las 13 antiguas sustituidas por otra del mapa conservan su id y su progreso, pero el Camino no las muestra mientras no tengan contenido ni progreso (si no, saldrían duplicadas «En preparación»). El validador exige que apunte a otra competencia del catálogo.
- **Prioridad del mapa**: LEN.LEX y MAT.EST pasan a ★★★ (entran en el diagnóstico); LEN.HAB ★★, MAT.ALG ★.
- **Supervivencia**: LEN.HAB y MAT.ALG con peso 0 (no se sortean) mientras no tengan contenido. Símbolos de bloque nuevos: `globe.europe.africa` y `arrow.triangle.branch`.
- **Hoy**: como LEN.SIN (primer bloque de Lengua) ya tiene contenido aprobado, la propuesta de Lengua pasa a ser «Sujeto y predicado» en lugar de «Agudas, llanas y esdrújulas». Es la consecuencia directa del orden del catálogo; los tests se adaptan.

### D-092 · 2026-11-25 · Fase 05E · Vigente
**Palabras ambiguas sin contexto** (§4.1).
- **Detección determinista** (`Acentuacion.ambiguas`, igual en `scripts/ambiguas_tilde.py`): las variantes de tilde de la palabra (sin tilde y con tilde en cada vocal) se buscan en el léxico y en `Content/ambiguas.json`. Esa lista se ha revisado a mano palabra por palabra sobre las 818 del léxico (70 con otra forma válida, cada variante con su categoría). **Sin voseo** (cantá, comé): la app es de español de España. Se incluyen formas poco frecuentes del DLE (airé, segundó, compas) por prudencia: sacar una palabra de más solo reduce el léxico.
- Salen de `colocarTilde`, `clasificarAcentuacion` y `silabaTonica` (las 70 de 818). Un test falla si alguna aparece en ellos, en sus enumeraciones o en los ítems estáticos de `colocarTilde`.
- `Content/pendiente/tildeContexto.json`: palabra, variantes válidas y categoría, para que la dirección redacte frases con contexto.

### D-093 · 2026-11-25 · Fase 05E · Vigente
**El verbo: análisis completo y formas no personales.**
- `analisisVerbal` con `rasgos = completo`: 6 ruedas (persona, número, tiempo, modo, aspecto y forma). El validador admite ahora de 1 a 6 selectores (la mecánica las muestra en vertical).
- **Aspecto**: perfecto en los compuestos y en el pretérito perfecto simple; imperfecto en el resto.
- **Conjugador**: añade pretérito anterior, imperfecto en -se, pluscuamperfecto con «hubiese» y futuro de subjuntivo simple y compuesto.
- **Solo regulares** de las tres conjugaciones (con participios irregulares de los datos: escrito, abierto). Los irregulares de `verbos.json` (tener, hacer, poner, decir y ahora ser y estar) no tienen tabla completa revisada: quedan fuera. Los copulativos tampoco se analizan.
- **Niveles**: 1 -ar, presente, pretérito perfecto simple y futuro · 2 tres conjugaciones + imperfecto y condicional · 3 + presente de subjuntivo y pretérito perfecto compuesto · 4 todo el indicativo (sin el anterior) y el subjuntivo en -ra con sus compuestos · 5 + -se, «hubiese» y pretérito anterior · 6 + futuro de subjuntivo.
- **Oráculo**: tabla de conjugación por reglas escrita en el test, comprobada contra los paradigmas completos de amar, temer y partir escritos a mano (18 tiempos, imperativo y formas no personales).
- **`formasNoPersonales`** (nuevo, LEN.VER.NOPERS): infinitivo, gerundio y participio, simples y compuestos, en `clasificar` y `eleccion`.

### D-094 · 2026-11-25 · Fase 05E · Vigente
**Generador `literatura`** sobre la base del lote 05a (LEN.LIT.HIST, UNIV, INF y GEN).
- **Ámbitos**: HIST = literatura española; UNIV = universal e hispanoamericana; INF = infantil y juvenil; GEN = todas.
- **Autor ↔ obra** (`emparejar`, 4 parejas): sin autores anónimos ni con fechas aproximadas (autoría discutida: Homero, Esopo…). Ningún título mostrado puede ser también obra de otro de los autores: el oráculo encontró «Soledades» (Góngora y Machado). Dificultad por la cercanía de los nacimientos.
- **Obra → movimiento** (`eleccion`): solo si el año de la obra está dentro del rango del movimiento (D-079); los distractores son movimientos de la periodización española cuyo rango no contiene ese año (sin ambigüedad), más cercanos cuanto más alto el nivel. **Obra → siglo**: sin años de cambio de siglo (…00 y …01).
- **Línea del tiempo** (`ordenar`, 4 autores por nacimiento o 4 movimientos por inicio): nunca fechas aproximadas y al menos 15 años entre fechas consecutivas. La separación mínima de cada nivel es proporcional al intervalo de fechas disponible (la literatura infantil abarca menos siglos), nunca por debajo de 15.
- **Género** (`clasificar`): sin las greguerías (su género es una convención); las obras anónimas se muestran «(anónimo)».
- **Homero y Esopo**: campo opcional `epoca` («s. VIII a. C.», «s. VI a. C.»), con `aproximado` y sin fragmentos (§4.4). Lo comprueban los dos validadores.

### D-095 · 2026-11-25 · Fase 05E · Vigente (criterio de la dirección)
**37 plantillas nuevas aprobadas** (LEN.SIN 13, LEN.VER 10, LEN.LIT 14; revisor «direccion», 25/11/2026), porque superan las condiciones de §5: 1000 semillas por plantilla con validador, oráculo independiente, sin ambigüedad, distractores distintos de la solución y entre sí, determinismo y dificultad creciente 1→6. Ninguna queda en borrador. Release carga ahora 79 plantillas. `scripts/plantillas_05e.py` las escribe y cambia su estado.

### D-096 · 2026-11-25 · Fase 05E · Vigente
**Calibración «nivel examen»** (§3). Escala común: 1–2 base, 3 intermedio, **4 = examen oficial**, 5–6 por encima.
- **Anclas** (`Content/calibracion/anclas.json`, `scripts/anclas_calibracion.py`): perfil estructural de las 67 preguntas oficiales de competencias con generador; 39 se reproducen en el nivel 4 y `AnclasTests` lo comprueba con 1000 semillas cada una. El resto lleva el nivel que las reproduce o el motivo por el que no se puede.
- **Tablas ajustadas** (nivel 4 = perfil del examen; 5–6 lo superan en al menos un rasgo): ordenar (4 números, fracciones y decimales mezclados), operar con fracciones (3–4 fracciones con sumas y restas), problemas de fracciones (tres gastos sobre lo que queda; antes era el nivel 6), operaciones combinadas (7 operaciones con paréntesis y corchetes), romanos (300–3999 con grupo sustractivo), porcentajes (15 % y 22 %, base de 3–4 cifras), conversiones (3 términos a una unidad intermedia), tiempo (suma de tres tiempos sin normalizar) y escalas (plano con medida decimal o en mm, resultado en metros; de la realidad al mapa pasa al 5). Las tablas siguen siendo crecientes (test de complejidad).
- **Sin cambios**: proporcionalidad (el 4 ya era el examen), probabilidad, estadística y m.c.m./m.c.d. (el 4 ya tiene el perfil; sus plantillas siguen en borrador). Ecuaciones: el examen pide «a · x = N» con números grandes (estructura del nivel 2), así que no se ha forzado; lo decide la dirección.
- **Sintaxis**: el nivel 4 de la tabla de D-090 es la copulativa; las oraciones del examen corresponden al nivel 5. Se señala a la dirección.
- **Ítems curados de Lengua**: 6 pasan a dificultad 4 por tener el perfil de la pregunta oficial de su competencia (elegir y justificar la tilde diacrítica o el homófono, palabra culta en contexto, sentido de un verso). El resto mantiene su dificultad.
- **Corrección**: la explicación de las operaciones combinadas y de las fracciones perdía la división al quitar el nombre del paso («3 = 1» en lugar de «3 : 3 = 1»).

### D-097 · 2026-11-25 · Fase 05E · Vigente
**Auditoría y equivalencias del Tribunal** (§1).
- `Content/tribunal/equivalencias.json` (`scripts/equivalencias_tribunal.py`): cada una de las 139 preguntas oficiales con su competencia del mapa (las 25 provisionales, a su id del mapa; las dudosas, a la principal) y si la app la entrena: «si» (contenido aprobado que ejercita la misma destreza), «parcial» (hay contenido aprobado, pero el examen pide redactar, definir o justificar y la app pide reconocer, o faltan rasgos como los irregulares) o «no». El script comprueba la coherencia con el contenido aprobado real.
- **Progreso (§4.3)**: se probó `ViewThatFits`, pero la auditoría daba «Dynamic Type font sizes are partially unsupported» sobre el nombre del área y el porcentaje (los textos de la variante no mostrada siguen en el árbol de accesibilidad, aun ocultos). La cabecera elige la disposición por el tamaño de texto (`AnyLayout`): en horizontal con el porcentaje con prioridad de diseño (nunca se parte) y, con texto de accesibilidad, el porcentaje debajo del nombre. Pasa la auditoría completa.
- **Arranque**: `analisisVerbal` guarda en caché el paradigma de cada nivel (se calculaba en cada muestra y, al materializar 12 variantes por plantilla, el arranque en el iPhone subió a 0,95 s). Con la caché: 0,87 s (objetivo < 1,5 s; 0,67 s en la recuperación, por las 37 plantillas nuevas que se materializan al cargar).
- **Auditoría en las rondas**: se audita con la pantalla quieta; durante la transición de entrada el contraste da falsos positivos en el iPhone.

## Fase 05E parte 2 — Identidad, sesión diaria, errores y ejemplos resueltos

### D-098 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Sintaxis: el nivel 4 es la oración del examen** (§1b.1). Nueva tabla de `oracionSimple`: 1 S + V intransitivo · 2 S + V + CD · 3 copulativa o S + V + CC · 4 S + V + CD o CI + CC (perfil del examen) · 5 S + V + CD + CI + CC o dos CC · 6 CC o CCT delante con coma, sujeto pospuesto o CI. El test de anclas se actualiza. El predicativo y el complemento del nombre quedan como perfil pendiente (lote de datos de la dirección).

### D-099 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Naturalidad de la gramática generativa** (§1b.2): `regalar` y `vender` solo con objetos `comprable`; etiqueta nueva `pintable` para `pintar`; `subir` solo con CCL de destino; CI con posesivo solo en singular; se mantienen las restricciones de D-090. Revisión de 300 oraciones: 3 forzadas (1 %; objetivo < 2 %).

### D-100 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Término desconocido con números grandes** (`MAT.OPE.INCOG.G02`, generador `terminoDesconocido`, §1b.3): «a · x = N», «N : x = a», «x + a = N» y «x − a = N». Nivel 4: 4–5 cifras y una sola operación inversa (perfil de las 4 preguntas oficiales); 5–6: dos igualdades encadenadas. Con oráculo y 4 anclas.

### D-101 · 2026-11-25 · Fase 05E parte 2 · Vigente (criterio de la dirección)
**Plantillas aprobadas** (§1b.4): MCD, CENTRAL y LAPLACE (y la nueva INCOG.G02) superan los tests de propiedades y de anclas. Las otras 5 plantillas de prueba de la 05C siguen en borrador.

### D-102 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Catálogo perezoso y tarjetas del ANEXO B** (§1b.6–7). Al arrancar no se genera ninguna variante: el catálogo de una plantilla se genera al pedir una ronda de su competencia y se guarda en caché. Las 9 tarjetas del ANEXO B se importan sin cambiar el texto (`scripts/teoria_anexo_b.py`), con el bloque `truco` (texto destacado).

### D-103 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Orden de lo nuevo** (§1b.5, `PlanEstudio`): prioridad del bloque (★) × debilidad del diagnóstico × preguntas oficiales de la competencia (`equivalencias.json`); sin diagnóstico, debilidad 0,5. En Mixto se alternan Lengua y Matemáticas.

### D-104 · 2026-11-25 · Fase 05E parte 2 · Sustituida por D-109
Paleta v3 (tinta marina, coral, amarillo y azul) con variantes de texto AA y test de contraste WCAG. El test de contraste se conserva con la paleta editorial.

### D-105 · 2026-11-25 · Fase 05E parte 2 · Vigente (modificada por D-109)
**Personajes del propietario** (Tilde, Cuarto y Mimo) dibujados pieza a pieza desde los SVG de la dirección (`docs/arte/v3/`), con 6 estados (neutro, alegre, pensando, ánimo, guiño, descanso), cada uno con su evento real, sin movimiento con «Reducir movimiento» y prueba instantánea del estado neutro. Avatares por datos (`Content/avatares.json`, `AvatarCatalogo`).

### D-106 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Sesión diaria, meta semanal y modo descanso** (§3.2–3.3). `ConstructorSesion` (determinista con la semilla del día y las respuestas de hoy): 8, 15 o 22 ítems (o los minutos entre la mediana de los últimos 50 intervalos, entre 6 y 30); remedios ≤ 20 %, repaso vencido ≤ 50 %, nuevo ≥ 25 % (máx(3, ⌈n/4⌉)) en bloques de 3. Meta semanal 3–7 días (por defecto 4) de lunes a domingo. Modo descanso: hasta 7 días por mes natural; congela racha y meta. Recordatorio: uno al día y nunca si ya hay sesión completada.

### D-107 · 2026-11-25 · Fase 05E parte 2 · Vigente
**Motor de errores** (§4). `Content/errores.json` (`scripts/errores_tipicos.py`): 93 errores en 34 competencias, con remedio generable. Todos los distractores de las plantillas aprobadas se etiquetan (por patrón del feedback); los estáticos, con el generador «estatico». Sucesos en SwiftData (`EventoErrorRegistro`, sin relaciones obligatorias, compatible con CloudKit). Activo con 2 apariciones en 7 días; corregido con 3 aciertos seguidos en su remedio. Remedio en la sesión: 3 ítems de su plantilla, un punto por debajo de la dificultad del último fallo.

### D-108 · 2026-11-26 · Fase 05E parte 2 · Vigente
**Causa raíz del test de 1000 historiales y corrección del constructor.** El constructor componía la sesión sin mirar el intercalado (repasos sueltos de una sola competencia sin tope; remedios y repasos concentrados en un área) y el ordenador, al no poder separarlos, relajaba las reglas. Las proporciones del test ya eran las de la dirección (máximos para remedios y repaso, mínimo para lo nuevo): **el fallo era del constructor, no del test**. Ahora la sesión se coloca pieza a pieza: en cada hueco va la primera pieza por prioridad (remedio, repaso, nuevo) que no rompe el intercalado, y lo que no cabe se sustituye por nuevo de otra competencia o área. Solo se relaja si no cabe nada (contenido de una sola competencia). 1000 historiales en verde y 0 relajaciones.

### D-109 · 2026-11-26 · Fase 05E parte 2 · Vigente (cambio de identidad del propietario)
**Identidad sobria y editorial**, derivada del logo v5 (`docs/arte/v5/`). Sustituye a D-104 y a la estética Rubber Hose de D-059.
- **Paleta**: tinta, papel, papel2, salvia (Lengua), bosque (Matemáticas y botones primarios), ámbar (recompensa), error y correcto, con los valores claro/oscuro de la dirección. Variantes de texto AA: `LenguaTinta` #536948 (salvia oscurecida), `RecompensaTexto` #855B1E, `Fallo` #A14935 / #E8846E, `Exito` #396E4C, `TextoSecundario` #545F5A / #9BA598. `TextoSobreBosque` (#F4F8F0 / #142019) para el texto sobre bosque y sobre el relleno de acierto; `Paleta.textoSobre(_:)` elige el color del texto de cada relleno. Retirados turquesa, violeta y oliva (sin uso).
- **Tipografía**: SF Pro con Dynamic Type; títulos (`largeTitle`–`title3`) y números de resultado en la serif del sistema (New York). Fredoka sale del paquete, de los créditos y del registro de derechos.
- **Estilo**: superficies planas, bordes de 1 pt en el color suave `Borde` (2 pt solo para marcar un estado), sin sombra dura, esquinas de 20–24 pt, pulsación por atenuado y animaciones suaves sin rebote.
- **Personajes**: mismas formas y estados, recoloreados (Tilde salvia con brote ámbar; Cuarto bosque con barriga menta y brote salvia; Mimo menta con brote bosque y corazón ámbar). Ojos y boca en tinta, salvo la boca y el guiño de Cuarto, que van en papel porque en tinta no se verían sobre el cuerpo bosque. Solo aparecen en la bienvenida, el resumen y el ánimo tras un error repetido. El estado «descanso» se conserva, pero ninguna de esas tres pantallas lo usa (se informa a la dirección).
- **Marca**: `MarcaView` dibuja la cuadrícula v5 en Path (módulos de tinta con el token `Tinta`, que se aclara en oscuro); en la bienvenida los cuatro módulos entran uno a uno en 0,6 s. La pantalla de lanzamiento usa la marca v5 con una banda de rayas salvia y bosque (`scripts/marca_lanzamiento.swift`, variante clara y oscura). El «libro vivo» queda retirado.

### D-110 · 2026-11-26 · Fase 05E parte 2 · Vigente
**El diagnóstico saltado se respeta.** Antes, sin progreso ni diagnóstico, «Empezar» lanzaba el diagnóstico aunque el usuario lo hubiera saltado en la bienvenida. Como el plan (D-103) existe sin diagnóstico, la sesión solo lanza el diagnóstico si no hay nada que componer. El diagnóstico sigue ofreciéndose en la bienvenida y en Ajustes.

### D-111 · 2026-11-26 · Fase 05E parte 2 · Vigente
**Interfaz de la sesión diaria y del motor de errores.**
- **Hoy**: la semana (7 puntos, con los días de descanso) y la racha debajo; un único «Empezar» con «≈ N min · M preguntas» debajo; selectores de duración y de foco (se recuerdan); baldosas Camino, Supervivencia, Rescate (con su número: ítems más errores activos) y Tribunal («Próximamente»). Sin nivel ni misiones ni aviso de racha en riesgo (sin culpa). El motor de misiones sigue en el núcleo, pero ya no se muestra (se informa a la dirección).
- **Resumen**: XP en ámbar con la serif de los resultados; dominio (competencias que suben, con el nombre del peldaño); errores detectados (activos: «Volverá el <día>», la siguiente sesión; no activos: «lo vigilamos»); «5 minutos más» (otra sesión de 5 minutos con el mismo foco) y «Terminar». Racha sin culpa («Empiezas una racha nueva»).
- **Rescate**: primero los errores activos («descripción · N veces», con «Practicar el remedio») y después por competencia.
- **Progreso**: «Errores que estás corrigiendo» (activos y corregidos en el último mes) y «Nivel examen».
- **Ajustes**: meta semanal (3–7) y modo descanso, con los días que quedan.
- **Peldaños**: Descubrir · Practicar · Resolver · Transferir · Dominar (solo las etiquetas).
- Debug: `-errorDemo` (dos fallos reales del mismo error de porcentajes) y `-modoOscuro` para las auditorías (el texto grande, con el argumento del sistema `-UIPreferredContentSizeCategoryName`).

### D-112 · 2026-11-26 · Fase 05E parte 2 · Vigente
**Ejemplos resueltos** (§5).
- **Pasos**: `PasoResuelto` (frase ≤ 60, operación con su resultado intermedio, valor y porqué ≤ 70) en `Muestra` e `Item`, calculados por los 15 generadores aprobados de Matemáticas con los datos del caso y por `oracionSimple` desde la estructura de la oración. Con mecánicas no numéricas (ordenar, construir, ruedas, elección), el último paso es la solución tal como la describe la app. Las explicaciones de Matemáticas terminan con la frase de porqué. `oracionSimple` en el modo de clases de palabras no tiene pasos (no se resuelve con sujeto y predicado).
- **Mecánica `ejemploResuelto`**: un `ItemRonda` marcado como ejemplo enseña los pasos uno a uno («Siguiente paso»), el último lo completa el usuario con la mecánica del ítem y el siguiente ítem es un gemelo (misma plantilla, otra semilla). Se aplica a lo nuevo de la sesión y a las rondas de Camino y Practicar cuando la competencia está en el peldaño 1.
- **Retirada de ayudas**: peldaño 1, ejemplo + gemelo (y las pistas de siempre en el resto); peldaño 2, la pista es solo el primer paso; desde el 3, sin pistas; los pasos se ven en el feedback tras un fallo («Cómo se resuelve»).
- **Nivel examen**: distintivo «Nivel examen» (dificultad 4) y «Por encima del examen» (5–6) en la ronda; en Progreso, «Nivel examen alcanzado» con ≥ 8 aciertos en los últimos 10 ítems de dificultad ≥ 4 de la competencia.

### D-113 · 2026-11-26 · Fase 05E parte 2 · Vigente
**Los 13 distractores estáticos sin etiquetar se quedan así.** Son de 7 competencias sin plantilla (LEN.COM.TEMA, LEN.COM.INFER, LEN.LEX.SIN, LEN.LEX.POLI, LEN.LEX.CAMPO, LEN.LEX.DICC y MAT.NUM.FRAEQ), que no tienen ningún error en el catálogo porque un error exige un remedio generable. Un test fija que solo pueden quedar sin etiquetar distractores de competencias sin errores catalogados.

### D-114 · 2026-11-26 · Fase 05E parte 2 · Vigente
**Rendimiento de una ronda medido en tiempo de CPU del hilo**: < 50 ms en caliente y < 200 ms en frío (la primera ronda de una competencia genera su catálogo, D-102). Con los tests en paralelo, el reloj contaba la espera por la CPU (121 ms de reloj en la batería completa frente a 95 ms para cuatro rondas en frío con el test solo); y en frío, con la batería en paralelo, el tiempo de CPU llegó a 83 ms.

### D-115 · 2026-11-27 · Fase 05G · Vigente
**Nueve patrones de interacción configurados con datos** (`Core/Juegos/Patron.swift`). Cada mecánica implementa un patrón y no se duplica interfaz: `marcar` (marcarTexto, segmentar, colocarTilde, eleccion), `evidencia` (nuevo), `modelo` (numerico, fraccionBarras, figuraArea), `construir`, `ordenar`, `clasificar` (clasificar, verdaderoFalso), `emparejar`, `rasgos` (ruedas) y `recuerdo` (nuevo). Los patrones nuevos son casos de `Mecanica`/`Payload`, así que rondas, sesión, Camino y Rescate los usan sin código propio. Reglas comunes: botón inferior estable («Comprobar» / «Volver a comprobar»), alternativa por toque a todo arrastre (cortes con botones y flechas), error marcado en la propia pieza con icono y texto, y el texto base se abre y se cierra sin perder lo marcado.

### D-116 · 2026-11-27 · Fase 05G · Vigente
**Contrato de intento** (`IntentoActividad`, `FlujoIntento`). Primer intento → si falla, una pista de razonamiento (no la solución) y un reintento editando la misma respuesta → si vuelve a fallar, la solución con su porqué. Solo cuenta para el dominio el acierto al primer intento sin ayudas (pista, colores o ejemplo); el acierto con pista o en el reintento es «en progreso» y no mueve la escalera ni Leitner; el recuerdo es autoevaluación. Los errores se detectan en el primer intento. XP aparte (con pista, menos XP, como antes). Se guarda en SwiftData (`IntentoActividadRegistro`: uuid, fecha y el intento en JSON; compatible con CloudKit). El flujo se aplica a los ítems de juego (`Item.juego`) y a las mecánicas `evidencia` y `figuraArea`; el resto de mecánicas sigue con un solo intento.

### D-117 · 2026-11-27 · Fase 05G · Vigente
**Retención y variante sin ayudas.** La variante sin ayudas de cada competencia de juego vence a los 2 días de su primera actividad (`RetencionJuegos`) y entra en la sesión diaria como bloque, tras los remedios: misma plantilla y otra semilla; en J46, otro texto y solo los pasos 2–3. Sin ayudas = sin pistas ni cortes candidatos. Una variante hecha después de la primera actividad la cierra.

### D-118 · 2026-11-27 · Fase 05G · Vigente
**J46 «De evidencia a resumen»** (LEN.COM.TEMA): tres plantillas, una por paso (`evidencia`, `tema`, `resumen`), y la semilla elige el texto, así que los tres pasos de una semilla son la misma actividad. Datos del ANEXO A en `Content/resumen.json` (5 textos) y dos textos originales nuevos (TXT.ORI.SUENO y TXT.ORI.BICI). El texto se toca por **oraciones completas**: la que contiene una idea central es la aceptada y la que contiene un detalle, el detalle (con fragmentos más cortos quedaban piezas sueltas como «y»). El tema enlaza el texto; el resumen se hace de memoria (sin el texto delante), con «Lo he escrito en papel» y el modelo y los criterios solo después.

### D-119 · 2026-11-27 · Fase 05G · Vigente
**J63 «Corta y compensa»** (MAT.GEO.AREA): `GeneradorAreaCompuesta`, seis plantillas (G01–G06, niveles 1–6) con racionales exactos. Cada figura trae todas sus descomposiciones válidas (sumar partes o restar el hueco) con sus cortes; cualquiera vale. Errores típicos por valor del total: sumar el hueco, perímetro, triángulo sin ÷2, semicírculo como círculo entero y no convertir (nivel 6); los totales erróneos que coinciden con el correcto se descartan. Región en el color de Matemáticas, hueco en blanco. El perfil del nivel 4 sigue la MATRIZ (fachada de 3 partes con decimales en m): `anclas.json` no tiene ancla de MAT.GEO.AREA. El oráculo de los tests calcula el área con la fórmula del polígono, independiente de los cortes.

### D-120 · 2026-11-27 · Fase 05G · Vigente
**Integración.** En la sesión diaria, un bloque nuevo de LEN.COM.TEMA que contiene un paso de J46 pasa a ser la actividad completa (`ActividadesJuego.agrupar`); en Camino y Practicar los pasos salen sueltos según el peldaño (1 evidencia, 2 tema, 3 resumen). J63 entra como cualquier plantilla (en el peldaño 1, ejemplo resuelto y gemelo). Rescate regenera los ítems por su id; el acierto «en progreso» no rescata. Reutilización por datos sin interfaz nueva: `LEN.COM.INFER.0004` (evidencia con el texto de las abejas, misma pregunta que la 0003) y `MAT.GEO.AREA.0001` (rectángulo con hueco, práctica de Tribunal, **borrador**: no entra en Release). Las mecánicas nuevas no entran en la ronda de demostración.

### D-121 · 2026-11-27 · Fase 05G · Vigente
**Errores típicos de los juegos**: 3 de LEN.COM.TEMA (dato por idea central, tema demasiado concreto, tema demasiado general) y 6 de MAT.GEO.AREA (sumar el hueco, perímetro, falta ÷2 en triángulo o semicírculo, unidad lineal, medidas sin convertir y área de una parte). El catálogo pasa de 93 a 102. Con LEN.COM.TEMA en el catálogo, sus distractores estáticos ya se etiquetan; quedan 12 sin etiquetar (D-113), todos de competencias sin errores.

### D-122 · 2026-11-27 · Fase 05G · Vigente
**Orden de las opciones** (§1.1): las opciones de elección se barajan con la semilla de la ronda y el id del ítem (`OrdenOpciones`), estables dentro de la ronda; la corrección va por id. En 200 sesiones, la correcta cae en cada posición entre el 15 % y el 35 %. **Tribunal** (§1.3): OF.2017.O-6 y OF.2022.O-4 (L4) pasan a «parcial» por contener formas irregulares (pondré, has venido; sonrío).

### D-123 · 2026-11-27 · Fase 05H · Vigente
**Decisiones de la dirección sobre la 05G.** INFER.0004 se aprueba como variante de mecánica de la 0003: un campo `origen` hace que compartan huella (nunca en la misma ronda o sesión) y la sesión, el Camino y Practicar excluyen las preguntas con variante vistas hoy o ayer (`huellasBloqueadas`). OF.2022.O-15 pasa a «parcial». J63 ofrece siempre «Restar el hueco»: la figura declara sus descomposiciones (la escalera admite ahora la resta) y, si no tiene hueco (casa, semicírculo), elegir restar es un primer intento fallido con la pista «Aquí no hay hueco que quitar…» (error nuevo ERR.MAT.GEO.AREA.7). Las opciones de los 6 ítems de comprensión son las de la dirección; se conservan los feedbacks etiquetados que siguen valiendo (TEMA.0001, .0003 y .0004).

### D-124 · 2026-11-27 · Fase 05H · Vigente
**Rayos X** (`rayosX`, patrón `marcar` con una capa de `clasificar`): 1) el verbo, 2) el sujeto o «Sujeto omitido» con su persona, 3) el predicado, que se forma solo, 4) la función de cada grupo (tocar o arrastrar). Andamiaje: peldaños 1–2, colores por función y pregunta guía; 3, solo colores; 4–5, nada y comprobación solo al final. Una capa fallada se marca, se explica en una línea, se repite y cuenta como primer intento con pista. Al final, el esquema con corchetes de colores (se reutiliza la vista de segmentar). Sustituye a `marcarTexto` y `segmentar` en SUJPRED y COMPL: las 6 plantillas cambian de mecánica (mismos ids, peldaños y dificultad) y los 3 ítems estáticos se migran; `oracionSimple` ya no genera esas dos mecánicas. Sujeto omitido con dificultad ≥ 3 (1 de cada 3): se quita el sujeto y el verbo pasa a 1.ª o 2.ª persona, que su terminación delata sin ambigüedad. Error nuevo: «No localizas el verbo» en SUJPRED y COMPL. **UI propia**: un contenedor con varias capas sobre la misma oración (fichas, flujo y vista de segmentar existentes).

### D-125 · 2026-11-27 · Fase 05H · Vigente
**Editor** (`editor`, patrón `marcar` con elección de forma): se toca la palabra mal escrita y se elige su forma entre las de la familia; tras corregir, el uso de cada forma. 1–3: una falta en una frase; 4: dos frases de familias distintas, una falta, sin decir cuántas; 5–6: tres frases, dos faltas y la penalización del examen. La forma errónea es siempre de la misma familia. `frases.json` no tiene marca de ambigüedad: sus frases son las del hueco del lote 02b, de respuesta única entre las formas de su familia, así que cualquier otra forma es incorrecta. El hueco y el Editor declaran la frase de origen y no comparten ronda. Plantillas en DIA (3), HOM (3) y PQ (1). **UI propia**: marcar y elegir forma sobre el mismo párrafo.

### D-126 · 2026-11-27 · Fase 05H · Vigente
**Fábrica de palabras** (ANEXO A → `formacion.json`): `clasificar` (LEN.FOR.CLAS, con la justificación tras corregir), `construir` (LEN.FOR.DER con derivadas y parasintéticas; LEN.FOR.COMP con compuestas), `segmentar` letra a letra (LEN.FOR.ESTR) y familia léxica con `clasificar` (LEN.LEX.CAMPO, solo los distractores formales del anexo). Paraguas, como pelirrojo y agridulce, solo se clasifica (para + aguas funde una *a*). Distractores de `construir`: primero piezas de una clase que la palabra no tiene; ninguna ordenación de las piezas forma una palabra conocida (anexo, familias y léxico).

### D-127 · 2026-11-27 · Fase 05H · Vigente
**Recursos literarios y glosario** (ANEXO B → `recursos.json` y `glosario.json`). Recursos: `emparejar` (LEN.REC.DEF), «¿Qué recurso hay?» (`eleccion`, LEN.REC.FIG) y Detective (`marcarTexto`, LEN.REC.FIG; se excluyen los ejemplos marcados enteros). Los recursos «también presentes» nunca salen como distractores. Glosario por grupos: clases de palabras → LEN.CLA.JUST; relaciones de significado → LEN.LEX.POLI; formación → LEN.FOR.ESTR; sílabas y acentuación → LEN.ORT.HIA. Distractores siempre del mismo grupo. Detective usa `marcarTexto` (§6) y no `evidencia`: hay que tocar todas las palabras de la marca.

### D-128 · 2026-11-27 · Fase 05H · Vigente
**Catálogo de errores**: 103 → 112 (verbo en SUJPRED y COMPL; LEN.FOR.CLAS, LEN.LEX.CAMPO, LEN.REC.FIG, LEN.CLA.JUST, LEN.LEX.POLI, LEN.FOR.ESTR y LEN.ORT.HIA; patrones del Editor en DIA, HOM y PQ). Los ids existentes no cambian (los errores nuevos van al final de su competencia). Distractores estáticos sin etiquetar: 12 → 8.

### D-129 · 2026-11-27 · Fase 05H · Vigente
**Pendientes de la 05E**: arranque de 0,86 s aceptado (se optimiza en la 07). **Misiones retiradas** del todo: motor, datos del perfil (y sus campos en SwiftData), efectos y tests. Con el modo descanso activo, Hoy muestra el personaje del área descansando junto al aviso de días congelados. Se acepta la boca de Cuarto en papel. Ajustes ofrece «Hacer el diagnóstico», que rehace el plan (la competencia en curso sale del diagnóstico nuevo).

### D-130 · 2026-11-27 · Fase 05I · Vigente
**Datos del Tribunal en uso.** Los 7 exámenes (139 preguntas, aprobados el 24/11) pasan de `pendiente/tribunal/` a `Content/tribunal/` y se cargan con sus equivalencias y `reglas.json`. Se respetan las remisiones de los textos protegidos (2019 A y O: Salinas y Laforet), las notas de la app y la anulada (2022 L7: se ve y no puntúa). Las 4 preguntas con figura (2022 M5 y M10, 2024 M7, 2026 O M7) muestran la descripción de la dirección y el enlace al cuadernillo; la página no consta en los datos (`paginaFigura` queda vacía). No se redibuja ninguna figura oficial. La rama `contenido/tribunal-ampliacion` no existe: no se incorpora nada más.

### D-131 · 2026-11-27 · Fase 05I · Vigente
**Puntuación.** Ninguna convocatoria documenta pesos (el `puntos: 1` de los datos lo pone el script por defecto y el cuadernillo de 2017 lo dice expresamente): se reparte por igual dentro de cada área, la nota del área va sobre 10, el total es la media de las áreas y se muestra «Ponderación no documentada: reparto igual». El modelo admite `pesos` por convocatoria para cuando consten. Penalización de las bases de 2026 (−0,5 palabra, −0,25 tilde, sin límite; una palabra repetida cuenta una vez): «según las bases de 2026» en 2026 y en los simulacros, «orientativa» en el resto. Nota orientativa, nunca oficial; «Apto» con 5 después de la penalización.

### D-132 · 2026-11-27 · Fase 05I · Vigente
**Corrección.** Las preguntas oficiales no traen clave estructurada (solo la solución modelo en texto), así que todas se autoevalúan con el modelo y la rúbrica (B 1, R 0,5, M 0), también las de Matemáticas y las cerradas de Lengua: no se inventa una clave. Matemáticas pide el valor (teclado propio, coma decimal) y la unidad por separado; Lengua, respuesta breve o «Lo he respondido en papel». En los simulacros la corrección de los ítems cerrados es automática (fracciones equivalentes salvo irreducible; en las figuras, valor y unidad) y los errores entran en el catálogo; los de redactar (`recuerdo`) se autoevalúan con sus criterios. Rúbrica etiquetada: oficial (plantillas de 2026) o propia de la app.

### D-133 · 2026-11-27 · Fase 05I · Vigente
**Plano y simulacro.** Sin `plano.json`, el plano se calcula de las 139 preguntas (`PlanoExamen`): 10 por área (la media), peso por convocatoria = año − 2016, reparto de mayores restos con tope de 2 por competencia y formato mayoritario (redactar, cerrada o cálculo). `GeneradorSimulacro`: contenido aprobado de dificultad 4–5 (variantes de las plantillas ajustadas a 4 y 5 y estáticos de dificultad ≥ 4), sin repetir pregunta, sin ítems vistos en 7 días si hay alternativa; lo que pide redactar usa `recuerdo` si lo hay (3 plantillas nuevas con datos ya aprobados: resumen, definir un recurso, definir una clase de palabra); una competencia sin contenido se sustituye de una en una por la siguiente más frecuente y se anota («Este simulacro no incluye: …»).

### D-134 · 2026-11-27 · Fase 05I · Vigente
**Sala de examen y borrador.** Tribunal sustituye a «Próximamente» (pestaña y baldosa de Hoy): examen oficial, medio examen (45 min), simulacro y repaso sin cronómetro; continuar el examen en curso; historial. Cuadernillo: papel, serif del sistema, cita de la convocatoria, sin personajes, XP ni colores de acierto; cuenta atrás con avisos a 15 y 5 min y entrega automática a 0; mapa de preguntas, «Marcar para revisar», «Entregar» con confirmación. El reloj solo corre con la app activa y el examen se guarda (SwiftData, JSON) para reanudarlo en la misma pregunta. Borrador: PencilKit en hoja de dos alturas con cuadrícula, lápiz, goma, deshacer y borrar todo, y el enunciado arriba; uno por pregunta en el Tribunal; en las rondas, solo en Matemáticas y se borra al pasar de ítem. No cuenta como pista. `AccesoTribunal` es el punto único que la fase 06 sustituirá (hoy, «permitido»).

### D-135 · 2026-11-27 · Fase 05I · Vigente
**Decisiones de la 05H.** `frases.json` lleva `ambigua`: marcadas FR.0088 y FR.0089 (familia sabia/savia: «sabia» es variante de «sabía», una de las 70); el hueco y el Editor no las usan. El esquema final de Rayos X se titula «Esquema del análisis».

### D-136 · 2026-11-27 · Lote 06 (sin Mac) · Vigente (numerada D-130 en la rama `contenido/lote-06`)
**Lote 06 de la dirección convertido sin tocar Swift.** Las 36 tarjetas entran en `teoria/` (aprobadas): un esquema separado por «·» pasa a una línea por «Etiqueta: valor», conservando el «·» de multiplicar dentro de un valor. Las 118 frases de tilde en contexto se añaden en `pendiente/tildeContexto.json`, con `frase`, `correcta` y `opciones`. Lo que no cabe en los esquemas actuales queda en `pendiente/lote06/`, fuera de la carga: la plantilla `LEN.ORT.CTX.G01` (borrador; falta el generador `tildeContexto` y la competencia `LEN.ORT.CTX`) y los 8 errores con `remedio.tipo = "remedioEstatico"` (el decodificador y el validador exigen hoy una plantilla de remedio). El detalle y lo que debe hacer el Mac está en `docs/lotes/LOTE06_PENDIENTE.md`.

### D-137 · 2026-11-27 · Fase 05J · Vigente
**Premium en la beta.** Hasta que llegue StoreKit, la beta concede el Premium. La lógica de bloqueo existe y se prueba con el Premium desactivado (`AccesoTribunal`: la muestra SIM.DEMO.01 es gratis en los dos formatos; sin derecho, un simulacro de pago no se hace, ni se imprime ni se comparte).

### D-138 · 2026-11-27 · Fase 05J · Vigente
**Contenido pendiente fuera de `Content/`.** El contenido pendiente ya no vive en `Content/`, porque esa carpeta se empaqueta entera en la app (el archive de la 05I llevaba `pendiente/`). Al cerrar el lote 06, `pendiente/` desaparece de `Content/`: `tildeContexto.json` pasa a `Content/`, la plantilla a `plantillas/` y los 8 errores a `errores.json`.

### D-139 · 2026-11-27 · Fase 05J · Vigente
**«Por bloques».** La práctica «Por bloques» del Tribunal funciona con las rondas normales de ítems de juego (los simulacros generados de la 05I). Las pistas solo aparecen en los ítems de los peldaños 1–2. Su puntuación no se compara con la del examen.

### D-140 · 2026-11-27 · Fase 05K · Vigente
**LEN.ORT.CTX con 3 niveles.** La competencia se queda con los niveles 2, 3 y 4 de la dirección. Se acepta el ajuste del test de complejidad para los bancos fijos de frases (como `fraseHueco`): la complejidad media no decrece con el nivel y la del 6 supera a la del 1.

### D-141 · 2026-11-27 · Fase 05K · Vigente
**Pasada corta de accesibilidad.** Un test de interfaz (`AccesibilidadUITests`) ejecuta `performAccessibilityAudit()` en Inicio, Camino, la sesión diaria, una ronda, Tribunal y las pantallas nuevas de la 05K (cubos en capas, volumen de nivel 4, espacio muestral con baraja, palabras variables y orden alfabético). Se corrige lo que sale y no se amplía el alcance: la auditoría completa sigue en la fase 07.

**Resultado:** cada pantalla se audita arriba del todo y, tras desplazarla y esperar a que se detenga, otra vez. Solo dio avisos de contraste en textos tapados a medias por la barra de pestañas flotante, la barra de acciones de la ronda o el difuminado superior (el auditor mide contra el material translúcido). Esos mismos textos pasan en la otra pasada, así que no hubo nada que corregir en la app. El test descarta solo ese caso, que queda documentado.

### D-142 · 2026-11-27 · Fase 05K · Vigente
**Pistas en «Por bloques».** Se mantiene la D-139: las pistas solo salen en los ítems de los peldaños 1–2. Los ítems de dificultad 4 y 5 van sin pistas.

### D-143 · 2026-11-27 · Fase 05K · Vigente
**Los textos literales de la dirección no se recortan.** ERR.LEN.ORT.CTX.1 lleva el texto de la dirección sin cambios: descripción «Eliges la palabra por cómo suena, sin comprobar qué significa en la frase.» y explicación «Hay palabras que suenan igual pero significan cosas distintas. Lee la frase entera, piensa qué quiere decir y elige la forma cuyo significado encaja.». Pasa de los límites del validador (13 palabras frente a 12; 149 caracteres frente a 140), así que el validador lo admite por su id (`textosDeLaDireccion`) y el script lo marca con `direccion=True`. Para el resto de errores, los límites siguen igual.

### D-144 · 2026-11-27 · Fase 05K · Vigente
**Palabras variables e invariables (LEN.CLA.VAR).**
- **Variables:** los sustantivos, adjetivos, determinantes y verbos de `gramatica/piezas.json`; los verbos, en formas conjugadas de presente, pretérito perfecto simple y futuro. El léxico no tiene pronombres etiquetados, así que no salen.
- **Invariables:** la lista de la dirección, sin sus 9 exclusiones. Con su mismo criterio («también variables en otros usos») se quitan además «sobre» (el sobre), «para» (parar) y «entre» (entrar).
- **Sustantivos que no salen:** los que no cambian de forma o tienen otro uso frecuente (lunes, cuidado, silencio, leche, alegría).
- **Justificar:** solo usa palabras que caben en una única casilla, así que no salen las que varían solo en número (mesa, amable, su).

### D-145 · 2026-11-27 · Fase 05K · Vigente
**«Capas y sólidos» (MAT.GEO.VOL).** Es una mecánica nueva, `figuraVolumen` (patrón `modelo`, juego «Capas», contrato de intento con pista, reintento y variante sin ayudas).
- **Dibujo:** sólidos en perspectiva isométrica con `Path`. En los peldaños 1–2, los ortoedros de medidas enteras se ven como cubos y las capas se apilan al indicarlas (solo un fundido si Reducir movimiento está activo).
- **Corrección:** manda el resultado, por su valor, junto con la unidad, que se elige aparte. Los pasos intermedios ayudan y, si tienen un error, se señalan.
- **Unidades:** las opciones nunca incluyen dos unidades equivalentes (dm³ no aparece junto a l).
- **Errores:** a los 6 de la dirección se suman 4 que necesitan los distractores: la altura del depósito en lugar de la del agua, dar lo que baja el agua, un paso mal calculado y la unidad. Son 10 errores en total.
- **VoiceOver:** el sólido se describe con sus medidas y sin la operación.

### D-146 · 2026-11-27 · Fase 05K · Vigente
**Tipos de sucesos y diccionario.**
- **Sucesos:** cada suceso lleva una especificación (`par`, `mayor:3`, `palo:oros&!figura`…) con la que se calcula su conjunto. El oráculo de los tests la interpreta con su propio código.
  - Espacio muestral de la baraja: por palo (nivel 4) y por valor (nivel 5).
  - Nivel 6: dos monedas.
  - «Compatibles o incompatibles» es una elección entre dos opciones.
  - Seis errores típicos nuevos.
- **Diccionario:**
  - **Lema:** sustantivos en plural, adjetivos con variación de género y verbos. Los irregulares, solo en los tiempos escritos en `verbos.json`, y sin las formas de dos verbos.
  - **Orden alfabético:** palabras del léxico, con la clave de la RAE (*Ortografía*, 2010): ch y ll no son letras aparte, la ñ va después de la n y las tildes no cuentan. Comprobado con la intercalación del sistema en español y con los casos fijos de la dirección.
  - Cinco errores típicos nuevos; en total el catálogo tiene 144.

### D-147 · 2026-11-27 · Fase 05K · Vigente
**Decisiones sobre la 05I.**
- **Convocatorias anteriores:** son material de contraste autoevaluado, sin claves automáticas.
- **Figuras:** las 4 tienen su página del cuadernillo oficial, comprobada en los PDF de `docs/examenes/oficiales/` (SHA-256 iguales a los de `FUENTES.md`). Son 2022 M5 en la página 11, 2022 M10 en la 13, 2024 M7 en la 12 y 2026 O M7 en la 14.
- **FR.0088 y FR.0089:** vuelven a `ambigua: false`, porque dentro de la familia sabia/savia solo hay una respuesta válida. Sustituye a esa parte de la D-135. El Editor ya solo cambia una forma por otra de su misma familia.

### D-148 · 2026-11-27 · Fase 05K · Vigente
**Cobertura del examen real.** Las 4 competencias entran en el Camino, en la sesión diaria y en el plano de «Por bloques», que ya no las anota como «no incluye». En `equivalencias.json`, la valoración se ha revisado pregunta a pregunta:
- **Pasan a «sí»:** 2019 O 15, 2022 O 20 y 2026 A 17.
- **Pasan a «parcial»:** 2019 A 17 (pirámide), 2024 O 17 (prisma pentagonal), 2024 O 19 (definir), 2026 O 6 (análisis morfológico) y 2026 O 9 (definiciones).
- **Sigue en «no»:** 2026 O 15 (frecuencia relativa).

Resultado: «sí» pasa de 40,3 % a **42,4 %** y «sí + parcial», de 77,7 % a **83,5 %**.

## Fase 06 — Monetización

> El prompt pedía numerar desde la D-145, pero la D-145–D-148 ya existen (fase 05K). Se sigue desde la D-149.

### D-149 · 2026-11-28 · Fase 06 · Vigente
**Decisiones sobre la 05K.** La dirección confirma con su texto literal la D-137, la D-138 y la D-139 (la D-137 queda sustituida por la D-155), la D-143 (excepción por id en el validador) y la D-144 (sobre, para y entre fuera de las invariables). Los 23 errores típicos de la 05K se recogen en `docs/revision/ERRORES_05K.md` para que los revise la dirección; no se cambian hasta entonces.

### D-150 · 2026-11-28 · Fase 06 · Vigente
**Pronombres en LEN.CLA.VAR.**
- **Lista de la dirección:** él, ella, ellos, ellas, mío, mía, tuyo, tuya, suyo, suya, alguno, alguna, ninguno, ninguna, otro, otra, otros, otras.
- **Etiqueta:** variable. En «justificar» van a la casilla «Varía en género y número».
- **Niveles:** salen desde el nivel 4, el de todas las clases.
- **Excluidos a propósito:** alguien, nadie, algo y nada, que no cambian de forma, y lo, se, me y te. No salen en ninguna lista, tampoco como formas verbales («nada», de nadar).
- **Test:** ningún pronombre de la lista aparece entre las invariables, y el oráculo comprueba la clase de cada uno.

### D-151 · 2026-11-28 · Fase 06 · Vigente
**Recuento precalculado.** «Preguntas disponibles» ya no se calcula en la app: se lee de `Content/recuento.json`, que da total, exacto, estáticos, generados, por área y la versión del catálogo. El test `DebugYRecuentoTests/recuento` lo compara con el recuento real del contenido aprobado, que tarda unos 56 s. Con `TEST_RUNNER_REGENERAR_RECUENTO=1 xcodebuild test …` lo reescribe. Hoy son 297 613 preguntas, «al menos», porque algunas plantillas se cuentan por muestreo. `PantallaRevision` (Debug) conserva el recuento completo.

### D-152 · 2026-11-28 · Fase 06 · Vigente
**Qué incluye cada versión** (tabla de la 06 §1.2, con la corrección de la dirección).

| Función | Gratis | Premium |
|---|---|---|
| Aprendizaje: Camino, sesión diaria, Rescate, juegos, teoría y Glosario | Todo | Todo |
| Anuncios | Sí (D-157) | No |
| Tribunal: la muestra SIM.DEMO.01 (hacerla, imprimirla y corregirla) | Sí | Sí |
| Tribunal: convocatorias anteriores (los 7 exámenes oficiales, también para consultar sus enunciados) | **No** | Sí |
| Tribunal: simulacros, modo examen, corrección, informe y «Por bloques» | No | Sí |
| Supervivencia | 1 partida al día (empezada, terminada o abandonada) | Ilimitada |

La tabla es un tipo puro, `TablaAcceso`, con `FuncionApp`. En la versión gratuita, las convocatorias, los simulacros de pago y «Por bloques» se ven con candado y, al tocarlos, abren la hoja de bloqueo. El modo Supervivencia ya existía: sin la partida del día, su pantalla lo explica con «Ver Premium» y el fin de partida no ofrece «Otra partida». Un intento de pago hecho durante la beta se puede ver en la lista, pero abrirlo pide Premium.

### D-153 · 2026-11-28 · Fase 06 · Vigente
**Servicio de acceso con StoreKit 2.** `ServicioAcceso` (`@MainActor`, `@Observable`) sustituye a `AccesoTribunal` y es lo único que consulta StoreKit.
- **Fuente de verdad:** `Transaction.currentEntitlements` verificadas de los dos productos. Cuenta el derecho que dura más, y no cuenta uno revocado (reembolso) ni caducado.
- **Escucha y caché:** escucha `Transaction.updates` desde el arranque. Guarda el último estado (`EstadoPremium`, con su caducidad) para funcionar sin conexión y no ver un instante la app bloqueada.
- **Productos:** grupo «Premium», con `<bundleID>.premium.mensual` a 9,99 €/mes y `.anual` a 49,99 €/año, los dos con 7 días gratis (StoreKit la ofrece una vez por grupo). Están en `Educulter.storekit` (es-ES, tienda ESP), que usa el esquema en la acción Ejecutar y los tests con `SKTestSession`. Hoy el bundle es `com.educulter.dev`.
- **Datos de prueba aislados:** con `-enMemoria` o `-almacenPruebas`, el estado se guarda en memoria.

### D-154 · 2026-11-28 · Fase 06 · Vigente
**Pantalla Premium y puntos de entrada.**
- **Pantalla:** `SubscriptionStoreView` (por ids de producto, porque el id del grupo lo asigna App Store Connect) con estilo de botones, para que no haya ningún plan preseleccionado. Lleva una cabecera propia (marca v5, «Educulter Premium» y lo que incluye en 3 líneas).
- **Precios:** las condiciones salen del servicio con precio y periodo de StoreKit: «Premium mensual: 7 días gratis. Después, 9,99 € al mes.», más «Se renueva sola. Puedes cancelar…». La prueba solo se menciona si el usuario aún tiene derecho a ella.
- **Pie:** Restaurar compras, Términos de uso (EULA estándar de Apple) y Política de privacidad, siempre visibles en un pie propio. La URL de privacidad es provisional (`EnlacesLegales.privacidad`, en `example.com`) y queda pendiente para la fase 08.
- **Entradas:** Ajustes > Premium, y la hoja de bloqueo al tocar algo bloqueado. Ajustes ofrece además «Gestionar suscripción» (`.manageSubscriptionsSheet`).
- **Nunca sola:** ninguna pantalla de venta salta sola, ni al abrir la app ni en una ronda.
- **Textos:** un test comprueba que no hay urgencias («solo hoy», «oferta», «quedan»…).

### D-155 · 2026-11-28 · Fase 06 · Vigente (sustituye a la D-137)
**Beta sin Premium gratis.** En Release (TestFlight y App Store) nadie recibe Premium gratis: los probadores compran en sandbox, que para ellos es gratis. En Debug, Ajustes > Desarrollador tiene «Premium simulado: StoreKit / Sí / No», y los argumentos `-premium` y `-gratis` hacen lo mismo en los tests de interfaz. Todo eso está dentro de `#if DEBUG`. Lo comprueban un test que recorre el código fuente y la búsqueda de cadenas en el binario del archive de Release.

### D-156 · 2026-11-28 · Fase 06 · Vigente
**SDK de terceros: Google Mobile Ads y UMP** (excepción a «sin SDKs de terceros» de CLAUDE.md, autorizada por la dirección en la fase 06).
- **Versiones:** Google Mobile Ads 13.13.0 y User Messaging Platform 3.1.0, por Swift Package Manager, con **versión exacta** en el `.pbxproj`. Así no hace falta subir `Package.resolved`, que vive en `project.xcworkspace/` y no se sube.
- **Un solo archivo con los SDK:** solo `ProveedorGoogle.swift` los importa. El resto habla con el protocolo `ProveedorAnuncios`, que en los tests es falso.
- **Formato:** solo intersticiales, sin banners ni anuncios recompensados.

### D-157 · 2026-11-28 · Fase 06 · Vigente
**Política de anuncios** (`PoliticaAnuncios`, pura, con fecha, calendario y estado inyectados).
- **Quién:** nunca con Premium.
- **Desde cuándo:** nunca los días naturales 1 y 2 desde la primera apertura. Las rondas de esos días no cuentan.
- **Cuándo:** solo al dejar el resultado de una ronda terminada. En la app no hay un botón «Continuar»: cuentan «Otra ronda», «5 minutos más», «Otra partida» y «Terminar». Nunca al abrir la app, a mitad de ronda, en la bienvenida, en el diagnóstico ni en el Tribunal, tampoco en sus rondas de «Por bloques».
- **Cuántos:** uno cada 2 rondas terminadas desde el último, y como mucho 4 por día natural (zona horaria del dispositivo).
- **Si no se puede:** sin conexión, sin consentimiento de UMP o con identificadores pendientes, ninguno. Si no está cargado, se sigue en el acto y se vuelve a cargar.
- **Recarga:** después de cada anuncio se precarga el siguiente.

### D-158 · 2026-11-28 · Fase 06 · Vigente
**Consentimiento.**
- **Cuándo:** desde el día 3 y sin Premium, con Hoy ya visible y fuera de la bienvenida y de las rondas. Se hace una vez por arranque, como pide Google.
- **Orden:** `requestConsentInfoUpdate` y `loadAndPresentIfRequired` de UMP; después, si `canRequestAds` y el ATT no se ha pedido, el permiso de seguimiento con el texto de la dirección; después, `MobileAds.shared.start()` y la precarga.
- **Sin permiso de UMP:** no se inicializa el SDK ni sale ningún anuncio.
- **Ajustes > «Privacidad y anuncios»:** explica cuándo hay anuncios y quién los sirve. Muestra «Opciones de privacidad» cuando UMP lo exige (`privacyOptionsRequirementStatus == .required`).
- **Debug:** geografía de depuración del EEE. Para la captura, `-diaUso 3` simula el día de uso y `-rondasAnuncio 1` las rondas ya hechas.

### D-159 · 2026-11-28 · Fase 06 · Vigente
**Identificadores que fallan en seguro.**
- **Debug:** usa siempre los de prueba de Google para iOS; las constantes solo existen dentro de `#if DEBUG`.
- **Release:** lee `ADMOB_APP_ID` y `ADMOB_INTERSTICIAL_ID` de `Config/Anuncios-Release.xcconfig` a través del Info.plist (`GADApplicationIdentifier` y `EduculterAdMobIntersticial`). Hoy valen `PENDIENTE`.
- **Validación en Release:** los ids deben tener el formato de AdMob y el mismo editor, y no pueden ser del editor de prueba. Ese editor se compara por su SHA-256, para que su número no viaje en el binario. Si no pasan la validación, no hay UMP ni anuncios, y la app no se cierra ni avisa.
- **Info.plist:** lleva además `NSUserTrackingUsageDescription` y los 50 `SKAdNetworkItems` de la lista oficial de Google (actualizada el 30/01/2026).

### D-160 · 2026-11-28 · Fase 06 · Vigente
**Privacidad y rendimiento.**
- **Manifiesto:** `Resources/PrivacyInfo.xcprivacy` declara `UserDefaults` (CA92.1), `NSPrivacyTracking = true` y los tipos que recoge el SDK de anuncios según el manifiesto de Google: ID del dispositivo (con rastreo), datos de publicidad, interacción, ubicación aproximada, rendimiento, fallos y otros diagnósticos.
- **Cuestionario:** la propuesta está en `docs/legal/ETIQUETAS_PRIVACIDAD.md`. El código confirma que la app no tiene servidor ni cuentas y que no abre conexiones propias.
- **Arranque:** el SDK nunca se inicializa en el arranque; lo hace después de UMP, desde la pantalla de inicio ya visible y de forma asíncrona.
