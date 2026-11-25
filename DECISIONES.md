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
