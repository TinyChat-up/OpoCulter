# UX y UI

> **Propósito:** recoger la arquitectura de información, los flujos, el sistema visual y los criterios de accesibilidad.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§1, §3, §5 y §6). Este documento resume y enlaza; si hay discrepancia, manda el original.
> **Estado:** Fase 05D, modos de juego: Camino (prueba de nivel y Reto de bloque), Supervivencia, Rescate con pantalla propia, diagnóstico en la bienvenida, Progreso con Swift Charts, Ajustes, sonido sintetizado y recordatorio local. Tribunal muestra "Llega pronto" (05E). Estilo "Rubber Hose moderno" (05C).
> **Misión:** [docs/MISION_PREMIUM.md](docs/MISION_PREMIUM.md) (vinculante).
> **Capturas:** [docs/capturas/fase05d/](docs/capturas/fase05d/) ([HOJA.png](docs/capturas/fase05d/HOJA.png)) para los modos y [fase05c](docs/capturas/fase05c/) para el estilo y las mecánicas. Las anteriores (05A–05B) son históricas.

## 1. Principios de experiencia
Promesa (original §1): rondas de pocos minutos, casi sin escribir. Sin teclado del sistema: tocar, arrastrar, deslizar, ruedas, piezas y teclado numérico propio. **Toda interacción de arrastre tiene una alternativa de dos toques** (ficha → destino), siempre disponible y no solo con VoiceOver.

## 2. Arquitectura de información y navegación
Barra de pestañas: **Hoy** · **Camino** · **Tribunal** ("Llega pronto", 05E) · **Progreso**. Las rondas y las partidas se abren a pantalla completa (desde Hoy, Camino o Ajustes); "Ver regla" abre la tarjeta de teoría en una hoja. La **bienvenida** (avatar → diagnóstico opcional → plan) aparece a pantalla completa mientras no haya avatar. **Perfil** se abre en una hoja desde el avatar de Hoy o desde Ajustes. **Rescate** y el inicio de **Supervivencia** se abren en hojas desde sus baldosas de Hoy; el **nodo** del Camino, en una hoja.

## 3. Flujos principales (05A–05D)
0. **Primera apertura** → bienvenida (los dos compañeros y la elección de avatar) → «¿Vemos desde dónde partes?» (Empezar diagnóstico | Saltar) → diagnóstico adaptativo («x de N») → **plan** (bloques fuerte/medio/débil con anillos, «Empezamos por…» con 2 competencias y aviso de los bloques sin datos) → Hoy.
1. **Hoy** (cabecera con avatar, racha con su globo y nivel; panel protagonista con el selector Lengua | Matemáticas, la competencia, la vista previa de la mecánica y "Empezar ronda"; baldosas Rescate, Ortografía exprés, Supervivencia y Tribunal; misiones como filas) → "Empezar ronda" → (tarjetas de teoría si la competencia está en el peldaño 1) → ítem → **Comprobar** (solo activo con respuesta completa) → corrección en el sitio + panel de feedback → **Continuar** → … → **Resumen** → "Otra ronda" o "Terminar".
2. **Rescate** (baldosa de Hoy, siempre activa con el número real): lista por competencia (errores pendientes, fecha del último y área) → "Rescatar todo" o "Rescatar esta competencia" → ronda de Rescate (con variantes; los generados se reproducen por semilla). Cada error se puede **ver de nuevo** (enunciado, solución y explicación). Sin errores: estado vacío con Tilde celebrando.
2 bis. **Supervivencia** (baldosa con el récord real) → hoja de inicio (reglas, área Todo | Lengua | Matemáticas, récords) → partida (cabecera con 3 corazones, nivel y puntos en vivo; ítems uno a uno) → al perder la tercera vida, **fin de partida** (puntos, nivel máximo, aciertos, comparación con la mejor partida, récords; Cuarto o Tilde `sorprendido` si hay récord) → "Otra partida" o "Terminar". Salir a mitad pide confirmación: lo jugado se guarda, pero no cuenta para el récord.
2 ter. **Camino** → ruta por área (selector) con las competencias por bloque → nodo → hoja (peldaño, caja y próximo repaso, teoría, "Practicar" y, si procede, "Prueba de nivel") → ronda. Al final de cada bloque con contenido, **Reto de bloque** → ronda de 8 → medalla con 6 aciertos.
2 quater. **Progreso** → dominio, evolución, estadísticas, preguntas disponibles, logros → **Ajustes** (sonido, vibración, recordatorio y hora, repetir diagnóstico, cambiar avatar, créditos) y "Borrar mi progreso" (doble confirmación).
2 quinquies. **Recordatorio**: tras la primera ronda o partida completada, una alerta en contexto («¿Te aviso cada día a las 20:00…?» Sí | Ahora no), una sola vez.
3. **Ortografía exprés**: 5 ítems de Ortografía y tildes.
4. **Salir a mitad**: la ✕ pide confirmación si ya se ha respondido algo; lo respondido queda guardado y la racha no cuenta.
5. **Revisión de contenido (solo Debug)**: pulsación larga sobre el título "Hoy" (o acción de VoiceOver "Revisión de contenido"). Incluye "Plantillas" (cada plantilla con selector de semilla: ítem generado, clave, complejidad, errores habituales y "Abrir en su mecánica") y "Recuentos del catálogo de preguntas" (D-064).

## 4. Sistema visual "Rubber Hose moderno" (D-059, evolución del v2 D-053)
Código: [Features/Comun/Diseno](Educulter/Features/Comun/Diseno). Colores en `Assets.xcassets/Colores`.

**Principio:** el lenguaje gráfico de la animación de los años 20–30 reinterpretado hoy: tinta gruesa, formas blandas y gomosas, y una paleta retro saturada sobre papel crema. No se copia ningún personaje, estudio ni juego (nada de guantes blancos ni ojos "de tarta"). Los objetos manipulables siguen siendo los protagonistas, y **el color codifica el área y el estado, nunca decora**.

### 4.1 Color (contraste WCAG AA comprobado)
**Regla:** los colores son rellenos y **el texto sobre un relleno va siempre en tinta**. El texto con color (de área o de estado) usa tintas oscuras propias.

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| Fondo (papel) | `#FBF3E8` | `#17130F` | Fondo de pantalla; dentro del panel tintado, superficie de fichas |
| Superficie | `#FFFBF4` | `#241E19` | Fichas, baldosas y tarjetas (siempre con contorno de tinta) |
| Tinta (contorno y sombra dura) | `#1A1714` | `#EDE3D6` | Contornos de 2,5 pt (1,5 pt en lo pequeño) y sombra dura |
| TextoPrincipal | `#1A1714` | `#F3EADF` | Texto (16,2:1 / 15,5:1 sobre el papel) |
| TextoSecundario | `#5E554B` | `#B8AC9E` | Texto secundario (≥ 5,9:1 sobre papel, superficie y tintes) |
| Borde | `#D9CCBB` | `#3C342C` | Solo para lo desactivado (contorno suave, sin sombra) |
| Lengua (relleno) | `#F2674B` | `#F2674B` | Rellenos con texto en tinta (5,8:1), «Tilde» |
| Matemáticas (relleno) | `#4AA3E8` | `#4AA3E8` | Rellenos con texto en tinta (6,5:1), «Cuarto» |
| Recompensa (mostaza) | `#F5B82E` | `#F5B82E` | XP, combo, nivel y avatar elegido (tinta: 10,0:1) |
| Turquesa / Violeta* / Oliva | `#17A3A3` / `#A77ACB` / `#A7C03A` | igual | Acentos secundarios (tinta: 5,8 / 5,4 / 8,7) |
| LenguaTinte / MatemáticasTinte | `#FDE3D9` / `#DDEEFB` | `#3A221A` / `#152A3C` | Panel protagonista |
| LenguaTinta / MatemáticasTinta | `#A8381A` / `#1F5F99` | `#FF9F88` / `#8CC8F5` | Texto con color de área (≥ 5,3:1) |
| Éxito / Fallo (texto) | `#186B43`* / `#B3261E` | `#5FC98A` / `#F28B82` | Estado como texto, icono o borde (≥ 4,5:1) |
| ExitoRelleno | `#5FC98A` | `#5FC98A` | "Continuar" tras acertar (tinta: 8,7:1) |
| TextoSobreAcento | `#1A1714` | `#1A1714` | Texto sobre cualquier relleno de color |

\* Ajustado a AA (D-059): el violeta propuesto `#9B6BC0` daba 4,47:1 con tinta; el verde `#1F7A4D` daba 4,35:1 sobre el tinte de Lengua.

### 4.2 Formas y "sombra dura"
- Paneles 20 (`Radio.tarjeta`), fichas y piezas 14 (`Radio.ficha`), celdas 6 (`Radio.celda`).
- **Contorno de tinta** de 2,5 pt (`Trazo.grueso`) en fichas, paneles, botones y celdas; 1,5 pt (`Trazo.fino`) en chips, cápsulas y celdas pequeñas.
- **Sombra dura**: desplazamiento de 3 pt en tinta, sin desenfoque (`SombraDura`). Es la única sombra y es funcional: **marca lo que se puede pulsar**. Al pulsar, la superficie se desplaza 3 pt y "se hunde" sobre su sombra (`EstiloPulsable` + `superficiePulsable`). Lo corregido o desactivado queda plano.
- **Un solo panel tintado por pantalla** (`PanelProtagonista`, con contorno y sin sombra: no se pulsa).

### 4.3 Tipografía, espaciado y áreas táctiles
- **Títulos: Fredoka SemiBold** (`Font.exhibicion`, SIL OFL, D-060), escalada con Dynamic Type mediante `UIFontMetrics`. Cuerpo en SF Pro; números, XP y letras de `colocarTilde` en SF Pro Rounded (`Font.redondeada`).
- Espaciado 4/8/12/16/24/32. Área táctil mínima 44 pt; fichas y botones principales de 52 pt.

### 4.4 Movimiento "gomoso"
Muelles con rebote (`spring(duration: 0.3, bounce: 0.4)`) y *squash & stretch* sutil (`estiramiento`: 1,08 × 0,92 y vuelta en 0,3 s) al encajar, acertar o desbloquear: celda coloreada, avatar elegido, ficha que se hunde, caída de la tilde, vuelo de "+N XP" y salto del combo. Todo ≤ 0,35 s. Con "Reducir movimiento", fundidos. No hay animaciones decorativas en bucle.

### 4.5 Iconografía
SF Symbols con un único peso (semibold), un símbolo por bloque (§4.7) y los de las mecánicas en la vista previa de Hoy. Nada más.

### 4.6 Respuesta háptica (D-040, D-073)
Éxito → `.success`; fallo → `.error`; hitos de combo (×3, ×5, ×10 y cada 10 más) → impacto fuerte; selección, colocación y arrastre → `.selection`. Implementada con `sensoryFeedback` de SwiftUI a través de `retroHaptica`, que respeta el ajuste de vibración.

### 4.6 bis Sonido (D-073)
`SonidoSintetizado`: tonos generados en tiempo real con AVAudioEngine, originales y sin archivos de terceros, de 250 ms como máximo, con envolvente suave. Sesión `.ambient` (respeta el modo silencio y no corta la música).

| Momento | Sonido |
|---|---|
| Acierto | Dos notas ascendentes (mi5 → si5) |
| Fallo | Una nota grave suave (sol3), nunca estridente |
| Hito de combo | Tres notas ascendentes rápidas |
| Récord | Arpegio de cuatro notas (do–mi–sol–do) |
| Fin de ronda | Dos notas (re5 → la5) |
| Tilde que cae / celda que se colorea | Golpe breve agudo / nota corta suave |

`SonidoConAjustes` solo reproduce con el sonido activado en Ajustes; en capturas se usa `SonidoSilencioso`.

### 4.7 Símbolo por bloque (D-050)
Junto al nombre de la competencia en la cabecera de la ronda y en "Ronda recomendada" (y en el Mapa en la 05B). Código: `SimboloBloque`.

| Bloque | Símbolo SF | Bloque | Símbolo SF |
|---|---|---|---|
| LEN.SIN Sintaxis | `point.3.connected.trianglepath.dotted` | MAT.UNI Unidades y medida | `ruler` |
| LEN.ORT Ortografía y tildes | `character.cursor.ibeam` | MAT.GEO Geometría | `triangle` |
| LEN.CLA Clases de palabras | `tag` | MAT.POR Porcentajes | `percent` |
| LEN.VER Formas verbales | `clock.arrow.circlepath` | MAT.NUM Fracciones y decimales | `divide.circle` |
| LEN.LIT Autores y épocas | `books.vertical` | MAT.DIV Divisibilidad | `square.grid.3x3` |
| LEN.COM Comprensión | `text.magnifyingglass` | MAT.OPE Operaciones y ecuaciones | `plus.forwardslash.minus` |
| LEN.REC Recursos literarios | `theatermasks` | MAT.ROM Números romanos | `building.columns` |
| LEN.MET Métrica | `music.quarternote.3` | MAT.EST Estadística | `chart.bar` |
| LEN.LEX Léxico | `character.book.closed` | MAT.PRO Probabilidad | `dice` |
| LEN.FOR Formación de palabras | `puzzlepiece` | | |

### 4.8 Recompensas al acertar (D-049)
| Momento | Animación | Con "Reducir movimiento" |
|---|---|---|
| Acierto | Pulso de escala (1,03) sobre el panel de la actividad | Fundido breve |
| XP ganada | La cápsula "+N XP" vuela del panel al contador ✨ de la cabecera, que sube al aterrizar | El contador cambia con un fundido |
| Hito de combo (×3, ×5, ×10…) | La cápsula del combo salta (1,3) y el rayo rebota; impacto fuerte | Fundido breve y vibración |
| Resumen | El XP sube contando | Aparece con un fundido |

**Fallar no castiga:** el panel dice "No es correcto"; el rojo queda solo en el icono, el título y el borde, y "Continuar" y "Ver regla" usan el color del área.

### 4.9 Personajes: «Tilde» y «Cuarto» (D-054, redibujados en D-059)
Originales del proyecto, construidos con `Shape` en el lenguaje Rubber Hose: contorno de tinta grueso, **brazos y piernas "de manguera"** (curvas suaves sin codos), manos redondas del color del cuerpo (no guantes), zapatos ovalados en tinta y **ojos ovalados** lisos con un punto de luz.

| | «Tilde» (Lengua) | «Cuarto» (Matemáticas) |
|---|---|---|
| Cuerpo | Bloque redondeado coral con contorno de tinta y una tilde mostaza en la cabeza | Círculo azul cielo de tres cuartos con el cuarto restante, en mostaza, separado como un sector |
| Cara | Ojos ovalados, boca en tinta | Igual, desplazada hacia el cuerpo |

| Estado | Rasgos y pose | Cuándo aparece (evento real) |
|---|---|---|
| `neutral` | Ojos ovalados, sonrisa leve; brazos relajados | Bienvenida |
| `pensando` | Mirada arriba, boca torcida; mano en la barbilla (el cuarto gira 12°) | Estados vacíos |
| `celebra` | Ojos ∩ y sonrisa abierta; brazos arriba y piernas abiertas (la tilde salta, el cuarto se aleja) | Feedback correcto; resumen con ≥ 50 % |
| `anima` | Ojos con párpado suave; un brazo en alto («¡vamos!») | Feedback tras un fallo; resumen con < 50 % |
| `sorprendido` | Ojos grandes y boca en «O»; brazos abiertos | Récord de Supervivencia (05D) |
| `dormido` | Ojos cerrados (∪); brazos caídos, cuerpo ladeado; la tilde cae y el cuarto encaja | Racha en riesgo |

Reglas: nunca bloquean la interacción, ≤ 64 pt en la actividad (44 en el feedback y 80 en el resumen) y `accessibilityHidden`.

### 4.10 Cómo entregar ilustraciones propias de los personajes
Con el mismo estilo que los avatares del propietario (Rubber Hose: contorno de tinta grueso, ojos ovalados, paleta de §4.1).
La arquitectura (`RepresentacionPersonaje`) permite sustituir los vectoriales sin tocar las vistas: `.environment(\.representacionPersonaje, .ilustracion(nombreAsset: "personaje"))`. Para entregarlas:
1. **Formato:** PDF o SVG vectorial, **un archivo por estado y personaje** (12 archivos), con **fondo transparente** y lienzo cuadrado, con la figura centrada y un margen del 8 %.
2. **Nombres:** `personaje_tilde_neutral`, `personaje_tilde_pensando`, `personaje_tilde_celebra`, `personaje_tilde_anima`, `personaje_tilde_sorprendido`, `personaje_tilde_dormido`, y lo mismo con `cuarto`.
3. **Colores:** los de la paleta v2 (§4.1). Si hay variante oscura, se entrega aparte con el sufijo `_oscuro`.
4. **Legibilidad:** la figura debe leerse a 44 pt. Sin texto dentro de la ilustración.

### 4.11 Avatares del usuario (D-061)
Las **6 ilustraciones del propietario** (`Assets.xcassets/Avatares/avatar_01…06`), recortadas en círculo con `scripts/recortar_avatares.swift` y mostradas con contorno de tinta:

| Id | Recurso | VoiceOver |
|---|---|---|
| 0 | avatar_01 | Avatar con gorra roja y blanca |
| 1 | avatar_02 | Avatar con pelo rizado y gafas redondas |
| 2 | avatar_03 | Avatar con cinta deportiva |
| 3 | avatar_04 | Avatar con pañuelo rojo y aros |
| 4 | avatar_05 | Avatar con boina y pelo naranja |
| 5 | avatar_06 | Avatar con gafas de aviador |

Se eligen en la bienvenida y en Perfil (cuadrícula 3 × 2; el elegido lleva sombra dura, fondo mostaza y ✓) y aparecen en la cabecera de Hoy. Los ids 6–11 de la 05B se migran a `id % 6`. El editor de personalización queda para después del MVP.

### 4.12 Pantallas de la Fase 05D
| Pantalla | Contenido |
|---|---|
| **Camino** (`PantallaCamino`) | Título, selector Lengua/Matemáticas y la ruta: por bloque, su símbolo y nombre (con medalla si se ha ganado). Cada competencia es un nodo circular de 56 pt con contorno y sombra dura: anillo de dominio si está en curso, relleno del área si está dominada, candado si va después de la recomendada, y trazo discontinuo gris con "En preparación" (no pulsable) si no tiene contenido. Línea vertical entre nodos. Al final del bloque, el nodo mostaza "Reto de bloque". |
| **Hoja del nodo** (`HojaNodo`) | Nombre, tarjeta con peldaño (n de 5 y su nombre), caja de repaso y próximo repaso, aviso del candado, "Prueba de nivel" (mostaza, con su explicación), "Practicar" y las tarjetas de teoría. |
| **Inicio de Supervivencia** | Cuarto y el título, las cinco reglas en una tarjeta, selector de área y récords (global y del área). Botón mostaza "Jugar". |
| **Partida** | La ronda de siempre con otra cabecera: ✕, tres corazones (rojos los que quedan), cápsula "Nivel n" ("· Experto" en el 6) y cápsula mostaza con los puntos, que cuentan en vivo. |
| **Fin de partida** | Personaje a 80 pt (`sorprendido` si hay récord), "¡Nuevo récord!" o "Fin de la partida", tarjeta con puntos, nivel máximo y aciertos, comparación con la mejor partida y récords, logros nuevos. "Otra partida" y "Terminar". |
| **Rescate** | Cabecera propia con "Cerrar", "Rescatar todo (n)" en mostaza y una tarjeta por competencia: nombre y símbolo, chip del área, "n errores pendientes · último el …", cada error como fila con 👁 para verlo de nuevo y "Rescatar esta competencia". |
| **Oferta de diagnóstico y plan** | Cuarto pensando, «¿Vemos desde dónde partes?» y la explicación; "Empezar diagnóstico" / "Saltar". El diagnóstico usa la pantalla de ronda con «x de N». Plan: Tilde celebrando, «Tu plan», cada bloque con su anillo y fuerte/medio/débil (aciertos de respondidos), «Empezamos por…» en una tarjeta y el aviso de bloques sin datos. "Ir a Hoy". |
| **Progreso** | Dominio por área y bloque (anillos; los bloques sin contenido, en discontinuo y "En preparación"), evolución de 4 semanas (barras de aciertos o XP, con gráfico de audio), estadísticas, preguntas disponibles (cifra real del contenido aprobado), logros conseguidos y pendientes con su condición, "Ajustes" y "Borrar mi progreso". |
| **Ajustes** | Diseño propio por grupos con contorno: sonido y vibración; recordatorio y hora (selector de hora del sistema, sin teclado); repetir diagnóstico, cambiar avatar y créditos. |

## 5. Componentes
| Componente | Descripción |
|---|---|
| `PanelProtagonista` | El único elemento tintado de la pantalla (radio 20, contorno de tinta, sin sombra). Dentro, las superficies usan el papel (`enPanelTintado`) |
| `Baldosa` | Baldosa compacta de Hoy: contorno de tinta y sombra dura. Desactivada: plana, borde suave y su motivo ("Llega en 05D") |
| `VistaPreviaMecanica` | Dibujo estático de la mecánica que toca, con su nombre, en el panel de Hoy |
| `VistaPersonaje` | «Tilde» o «Cuarto» en un estado (§4.9), con representación intercambiable |
| `VistaAvatar` / `SelectorAvatar` | Avatar geométrico y cuadrícula de los 12 (bienvenida y Perfil) |
| `BotonPrincipal` / `EstiloBotonPrincipal` | Relleno del área con texto en tinta, contorno y sombra dura; se hunde al pulsar; 52 pt. Desactivado: plano |
| `EstiloBotonSecundario` | Papel con texto en tinta, contorno y sombra dura |
| `TarjetaSuperficie` | Papel con contorno de tinta, radio 20, sin sombra |
| `EstiloPulsable` / `superficiePulsable` | Relleno + contorno + sombra dura de 3 pt; al pulsar la superficie se hunde 3 pt (D-059) |
| `Ficha` | Contorno de tinta y sombra dura mientras se puede tocar; estados normal, seleccionada (relleno de acento), correcta (borde e icono ✓ verdes), incorrecta (borde e icono ✗ rojos), faltante (borde discontinuo verde y +) y desactivada. El texto conserva el color principal para mantener el contraste, y el estado nunca depende solo del color |
| `BarraProgresoRonda` | Segmentos por ítem en el color del área |
| `IndicadorCombo` | Cápsula ámbar "⚡ ×n" desde 2 aciertos seguidos; salto y destello en los hitos (×3, ×5, ×10…) |
| `ContadorXP` | Cápsula "✨ n" con el XP de la ronda, en la cabecera (destino del vuelo de "+N XP") |
| `AnilloDominio` | Anillo de progreso (se usará en el Mapa) |
| `ChipRacha` | 🔥 días · 🛡 protectores · 🏆 récord. Al tocarlo abre un globo (`GloboRacha`) que explica cada icono |
| `HojaFeedback` | Panel inferior: "¡Correcto!" / "No es correcto", +XP, subida de peldaño, solución, feedback del error habitual, explicación, "Ver regla" y "Continuar" (D-039). Tras un fallo, los botones usan el color del área (D-049) |
| `TecladoNumerico` | 7-8-9-⌫ / 4-5-6-− / 1-2-3-/ / 0-, ; el signo alterna; coma y barra no se repiten |
| `VistaTarjetaTeoria` | Texto, regla (barra de acento), ejemplo (recuadro) y esquema maquetado: `Etiqueta: valor` en dos columnas y `A → B` como píldoras con flechas (D-034) |
| `DisposicionFlujo` | Layout que reparte tokens y piezas en líneas |

## 6. Mecánicas (Features/Ronda/Mecanicas)
| Mecánica | Interacción | Sin arrastre / VoiceOver | Corrección en el sitio |
|---|---|---|---|
| `eleccion` | Tarjetas grandes | Botones con rasgo "seleccionado" | Correcta ✓ verde, elegida errónea ✗ roja |
| `verdaderoFalso` | Deslizar la tarjeta (±80 pt) | Botones Falso/Verdadero siempre visibles | Borde y botón en verde/rojo |
| `clasificar` | Arrastrar ficha a caja | Tocar ficha y después caja; acciones "Mover a…" | Fichas ✓/✗ dentro de las cajas |
| `ordenar` | Arrastrar fila sobre otra | Tocar ficha y después el puesto; acciones "Subir/Bajar" | Puestos ✓/✗ |
| `emparejar` | Tocar uno de cada columna | Acciones "Emparejar con…"; par con color **y número** compartidos; en tamaños de accesibilidad las columnas se apilan | Izquierda ✓/✗ |
| `marcarTexto` | Tocar palabras o sílabas | Botones con rasgo "seleccionado" | Marcadas ✓/✗; las que faltaban, discontinuas con + |
| `segmentar` | Tocar inicio, tocar fin, elegir etiqueta (chips encima de las palabras) | Igual (todo son toques); borrar tramos desde el árbol | Corchetes y árbol en verde/rojo + solución |
| `ruedas` | Segmentado (≤ 3 opciones cortas) o menú | Controles nativos | Fila ✓/✗ con la correcta; la caja fuerte se abre al acertar |
| `construir` | Tocar pieza (o arrastrar al hueco); la puntuación pegada a un hueco viaja con él | Acciones "Colocar en el hueco n"; tocar un hueco lleno lo vacía | Huecos ✓/✗ |
| `numerico` | Teclado numérico propio | Teclas con nombre accesible | Resultado en verde/rojo |
| `colocarTilde` | La palabra en letras grandes (una fila); tocar una vocal deja caer la tilde y tocarla otra vez la quita; botón «Sin tilde» | Cada vocal es un botón ("Vocal o", valor "con/sin tilde") | Palabra correcta con la tilde en verde, barra en la tinta del área bajo la sílaba tónica, «Sílaba tónica: can-CIÓN» y «Tu respuesta: …» |
| `fraccionBarras` | Tocar celdas para colorear o descolorear; en `dividirYColorear`, control −/+ (2–12) con la barra redibujándose en vivo; lectura "3/8" debajo | Celdas "celda 3 de 8, coloreada"; el control de partes es ajustable (deslizar arriba o abajo) | Barra en verde/rojo y, si falla, segunda barra con la solución y "9/12 = 3/4" |

**Segmentar** (D-045, D-051): las instrucciones cambian en tres pasos (inicio → fin → etiqueta). Las etiquetas son una fila de chips justo encima de las palabras. Tras el primer toque, al pulsar la palabra final todo el tramo se ilumina en vivo (tinte suave del acento) antes de soltar. El árbol "Tu análisis (n)" se puede plegar. Un tramo dentro de otro se anida solo; si envuelve tramos existentes, estos pasan a ser sus hijos; si se cruza con otro, se rechaza con aviso y vibración de error. Bajo cada palabra se dibujan barras por nivel (la más interna arriba) en el **color de su etiqueta**. Las etiquetas se muestran como píldoras con su color, nombre y abreviatura ("Predicado · PRED"), y debajo aparece el análisis en árbol con sangría por nivel, barra de color y nombre. Tras corregir, el árbol marca cada tramo con ✓/✗ en verde o rojo, y el panel muestra la solución completa. No se escribe texto dentro de las barras: la auditoría exige que todo texto visible sea accesible y escale, y en barras de una palabra no cabría (D-045).

## 7. Accesibilidad
- VoiceOver: todos los controles tienen etiqueta, valor de estado (seleccionada, correcta, incorrecta, emparejado con…) y acciones personalizadas para sustituir el arrastre.
- Dynamic Type hasta AX5: textos con estilos, `fixedSize` vertical para que no se corten, y disposiciones que cambian a vertical (Hoy, emparejar, esquema, Pista/Comprobar; en la cabecera de la ronda, la barra de progreso pasa a una segunda línea).
- Hoy tiene un margen inferior extra para que la barra de pestañas flotante no tape el final del contenido.
- Reducir movimiento (4.4). Contraste AA (4.1). El estado nunca se comunica solo con color.
- Auditoría automática `performAccessibilityAudit()` en Hoy, teoría previa, cada mecánica (antes y después de comprobar) y resumen: ver [TESTING.md](TESTING.md).

## 8. Microcopias y tono
Español de España, tuteo, frases cortas: "¡Correcto!", "No es correcto", "Ver regla", "Continuar", "¡Ronda completada!", "Llega pronto".
