# UX y UI

> **Propósito:** recoger la arquitectura de información, los flujos, el sistema visual y los criterios de accesibilidad.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§1, §3, §5 y §6). Este documento resume y enlaza; si hay discrepancia, manda el original.
> **Estado:** Fase 05B (piloto premium): sistema de diseño v2 "Laboratorio táctil", personajes, avatares, Hoy rediseñado, bienvenida, Perfil y dos mecánicas nuevas. Camino, Tribunal y Progreso muestran "Llega pronto"; Supervivencia llega en la 05C.
> **Misión:** [docs/MISION_PREMIUM.md](docs/MISION_PREMIUM.md) (vinculante).
> **Capturas:** [docs/capturas/fase05b/](docs/capturas/fase05b/) ([HOJA.png](docs/capturas/fase05b/HOJA.png)). Las anteriores, de la 05A y la 05A.1, son históricas.

## 1. Principios de experiencia
Promesa (original §1): rondas de pocos minutos, casi sin escribir. Sin teclado del sistema: tocar, arrastrar, deslizar, ruedas, piezas y teclado numérico propio. **Toda interacción de arrastre tiene una alternativa de dos toques** (ficha → destino), siempre disponible y no solo con VoiceOver.

## 2. Arquitectura de información y navegación
Barra de pestañas: **Hoy** · **Camino** (sustituye a "Mapa") · **Tribunal** (sustituye a "Examen") · **Progreso**. La ronda se abre a pantalla completa desde Hoy; "Ver regla" abre la tarjeta de teoría en una hoja. La **bienvenida** aparece a pantalla completa mientras no haya avatar. **Perfil** se abre en una hoja desde el avatar de la cabecera de Hoy.

## 3. Flujos principales (05A–05B)
0. **Primera apertura** → bienvenida (los dos compañeros y la elección de avatar) → Hoy.
1. **Hoy** (cabecera con avatar, racha con su globo y nivel; panel protagonista con el selector Lengua | Matemáticas, la competencia, la vista previa de la mecánica y "Empezar ronda"; baldosas Rescate, Ortografía exprés, Supervivencia y Tribunal; misiones como filas) → "Empezar ronda" → (tarjetas de teoría si la competencia está en el peldaño 1) → ítem → **Comprobar** (solo activo con respuesta completa) → corrección en el sitio + panel de feedback → **Continuar** → … → **Resumen** → "Otra ronda" o "Terminar".
2. **Rescate**: ronda solo con los ítems fallados (con variantes).
3. **Ortografía exprés**: 5 ítems de Ortografía y tildes.
4. **Salir a mitad**: la ✕ pide confirmación si ya se ha respondido algo; lo respondido queda guardado y la racha no cuenta.
5. **Revisión de contenido (solo Debug)**: pulsación larga sobre el título "Hoy" (o acción de VoiceOver "Revisión de contenido").

## 4. Sistema visual v2 "Laboratorio táctil" (D-053)
Código: [Features/Comun/Diseno](Educulter/Features/Comun/Diseno). Colores en `Assets.xcassets/Colores`.

**Principio:** luminoso y geométrico. Los objetos manipulables (fichas, letras, celdas) son los protagonistas, y **el color codifica el área y el estado, nunca decora**.

### 4.1 Color (contraste WCAG AA comprobado)
| Token | Claro | Oscuro | Uso (justificación funcional) |
|---|---|---|---|
| Fondo | `#FBFBFA` | `#121316` | Fondo de pantalla; dentro del panel tintado, superficie de fichas y baldosas interiores |
| Superficie | `#F1F2F4` | `#1C1D22` | Baldosas neutras, filas y fichas fuera del panel: se separan por tinte, sin bordes ni sombras |
| TextoPrincipal | `#16181D` | `#EEF0F3` | Texto (17,2 / 16,3 sobre el fondo) |
| TextoSecundario | `#5B6170` | `#A2A8B5` | Texto secundario (≥ 5,5 / ≥ 6,5 sobre el fondo, la superficie y los tintes) |
| Borde | `#E2E4E8` | `#2E3038` | Contorno de fichas y celdas manipulables (no decorativo: delimita lo tocable) |
| MatemáticasTinte | `#EEF0FF` | `#1E2242` | Panel protagonista de Matemáticas |
| MatemáticasTinta | `#1F2A7A` | `#C3C9FF` | Texto con color de área (11,1 / 9,6 sobre su tinte) |
| Matemáticas (primario) | `#4B58D6` | `#7C88EE` | Rellenos con texto blanco (5,7), celdas coloreadas, personaje «Cuarto» |
| LenguaTinte | `#FFF1EC` | `#2E1D18` | Panel protagonista de Lengua |
| LenguaTinta | `#A8381A` | `#FFB59C` | Texto con color de área (5,9 / 9,5 sobre su tinte) |
| Lengua (primario) | **`#C94A27`*** | `#E4613F` | Rellenos con texto blanco (4,67), personaje «Tilde» |
| Éxito | `#237A52`* | `#33A872`* | Correcto (≥ 4,66 sobre fondo, superficie y tintes) |
| Fallo | `#C92D2D`* | `#E26A6A`* | Incorrecto (≥ 4,76) |
| Recompensa (relleno) | `#F2A93B` | `#F2A93B` | XP, combo y nivel, siempre con texto `#141518` (9,1) |
| RecompensaTexto | `#946007`* | `#F2A93B` | Ámbar como texto o icono (≥ 4,71) |
| TextoSobreAcento | `#FFFFFF` | `#141518` | Texto sobre primarios, éxito y fallo |

\* Ajustado respecto a la propuesta para AA (D-053). El coral `#E4613F` propuesto da 3,45:1 con texto blanco en claro; se oscurece a `#C94A27` (mismo matiz) y se conserva en oscuro. Regla de uso: **texto en color de área → tinta; relleno o manipulable → primario**.

### 4.2 Formas
- Panel protagonista: radio 16 (`Radio.tarjeta`).
- Fichas y piezas: radio 10 (`Radio.ficha`).
- Celdas manipulables: radio 4 (`Radio.celda`).
- **Sin sombras**: los planos se separan por tinte y por espacio.
- **Un solo panel tintado por pantalla** (`PanelProtagonista`): la actividad principal. Lo demás son baldosas neutras compactas (`Baldosa`, `TarjetaSuperficie`) o filas. No hay listas de tarjetas idénticas: en el resumen, los tres datos comparten una baldosa y las secciones son grupos con título.

### 4.3 Tipografía, espaciado y áreas táctiles
- SF Pro con Dynamic Type; SF Pro Rounded (`Font.redondeada`) para números, XP, récords, fracciones y las letras de `colocarTilde`.
- **Pesos: regular y semibold** (se retira el bold).
- Espaciado 4/8/12/16/24/32.
- Área táctil mínima 44 pt; fichas y botones principales de 52 pt.

### 4.4 Movimiento
Las animaciones **confirman una acción** (encajar, completar, desbloquear) y duran **≤ 0,35 s**:
- caída de la tilde;
- celda que se colorea y barra que se redibuja al cambiar las partes;
- pulso de escala al acertar;
- vuelo de "+N XP" (0,35 s);
- salto del combo en los hitos;
- XP del resumen contando;
- cambio de estado del personaje.

Con "Reducir movimiento", fundidos. No hay animaciones decorativas en bucle.

### 4.5 Iconografía
SF Symbols con un único peso (semibold), un símbolo por bloque (§4.7) y los de las mecánicas en la vista previa de Hoy. Nada más.

### 4.6 Respuesta háptica (D-040)
Éxito → `.success`; fallo → `.error`; hitos de combo (×3, ×5, ×10 y cada 10 más) → impacto fuerte; selección, colocación y arrastre → `.selection`. Implementada con `sensoryFeedback` de SwiftUI.

### 4.6 bis Sonido
Protocolo `ServicioSonido` con implementación vacía `SonidoSilencioso` (D-041), para la 05B.

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

### 4.9 Personajes: «Tilde» y «Cuarto» (D-054)
Originales del proyecto (propiedad del propietario), geométricos y construidos con `Shape`. No se parecen a ningún personaje existente.

| | «Tilde» (Lengua) | «Cuarto» (Matemáticas) |
|---|---|---|
| Forma | Cuerpo redondeado coral (primario de Lengua) con una tilde (acento agudo) en la tinta de Lengua encima, como rasgo | Círculo índigo (primario de Matemáticas) con un cuarto separado, como un sector, en la tinta de Matemáticas |
| Cara | Ojos y boca en el color de texto sobre acento | Igual, desplazada hacia el cuerpo |

| Estado | Rasgos | Qué hace la figura | Cuándo aparece (evento real) |
|---|---|---|---|
| `neutral` | Ojos redondos y sonrisa leve | En reposo | Bienvenida |
| `pensando` | Ojos desplazados hacia arriba y boca recta | El cuarto de «Cuarto» gira 12° | Estados vacíos (Camino, Tribunal, Progreso, ronda vacía) |
| `celebra` | Ojos en arco (∩) y sonrisa amplia | La tilde sube y el cuarto se separa más | Feedback correcto; resumen con al menos la mitad de aciertos |
| `anima` | Ojos suaves (∪) y sonrisa leve | La tilde se inclina hacia delante | Feedback tras un fallo (nunca burla); resumen con menos de la mitad |
| `sorprendido` | Ojos grandes y boca en «O» | El cuarto se separa | Récord de Supervivencia (05C) |
| `dormido` | Ojos cerrados (líneas) y boca pequeña | La tilde cae tumbada y el cuarto encaja | Aviso de racha en riesgo en Hoy: hay racha, hoy no hay ronda y quedan menos de 4 h para medianoche |

Reglas: nunca bloquean la interacción (`allowsHitTesting(false)`); miden 44 pt en el feedback y el aviso (≤ 64 en la actividad) y 80 pt en el resumen; son `accessibilityHidden`, porque el mensaje siempre está en el texto de al lado.

### 4.10 Cómo entregar ilustraciones propias de los personajes
La arquitectura (`RepresentacionPersonaje`) permite sustituir los vectoriales sin tocar las vistas: `.environment(\.representacionPersonaje, .ilustracion(nombreAsset: "personaje"))`. Para entregarlas:
1. **Formato:** PDF o SVG vectorial, **un archivo por estado y personaje** (12 archivos), con **fondo transparente** y lienzo cuadrado, con la figura centrada y un margen del 8 %.
2. **Nombres:** `personaje_tilde_neutral`, `personaje_tilde_pensando`, `personaje_tilde_celebra`, `personaje_tilde_anima`, `personaje_tilde_sorprendido`, `personaje_tilde_dormido`, y lo mismo con `cuarto`.
3. **Colores:** los de la paleta v2 (§4.1). Si hay variante oscura, se entrega aparte con el sufijo `_oscuro`.
4. **Legibilidad:** la figura debe leerse a 44 pt. Sin texto dentro de la ilustración.

### 4.11 Avatares del usuario (D-054)
12 combinaciones originales de **forma** (círculo, cuadrado, triángulo, hexágono), **tono** (índigo, coral, verde, ámbar) y **accesorio** (gafas, gorro, auriculares). Cada forma y cada tono aparecen 3 veces y cada accesorio 4, sin repeticiones:

| # | Avatar | # | Avatar | # | Avatar |
|---|---|---|---|---|---|
| 0 | Círculo índigo con gafas | 4 | Cuadrado índigo con gorro | 8 | Triángulo índigo con auriculares |
| 1 | Círculo coral con gorro | 5 | Cuadrado coral con auriculares | 9 | Hexágono coral con gafas |
| 2 | Círculo verde con auriculares | 6 | Triángulo verde con gafas | 10 | Hexágono verde con gorro |
| 3 | Cuadrado ámbar con gafas | 7 | Triángulo ámbar con gorro | 11 | Hexágono ámbar con auriculares |

Los accesorios se dibujan en el color de texto sobre el relleno, para que contrasten. El avatar se elige en la bienvenida y en Perfil, se guarda en el perfil (SwiftData) y aparece en la cabecera de Hoy; en los récords de Supervivencia aparecerá en la 05C. El editor de personalización queda para después del MVP (ROADMAP).

## 5. Componentes
| Componente | Descripción |
|---|---|
| `PanelProtagonista` | El único elemento tintado de la pantalla (radio 16). Dentro, las superficies usan el fondo claro (`enPanelTintado`) |
| `Baldosa` | Baldosa neutra compacta de Hoy. Desactivada: sin aspecto de botón y con su motivo ("Llega en 05C") |
| `VistaPreviaMecanica` | Dibujo estático de la mecánica que toca, con su nombre, en el panel de Hoy |
| `VistaPersonaje` | «Tilde» o «Cuarto» en un estado (§4.9), con representación intercambiable |
| `VistaAvatar` / `SelectorAvatar` | Avatar geométrico y cuadrícula de los 12 (bienvenida y Perfil) |
| `BotonPrincipal` / `EstiloBotonPrincipal` | Relleno de acento, 52 pt, texto que se adapta; desactivado en gris |
| `EstiloBotonSecundario` | Contorno del color de acento |
| `TarjetaSuperficie` | Superficie, borde fino, radio 16 |
| `Ficha` | Estados normal, seleccionada (relleno de acento), correcta (borde e icono ✓ verdes), incorrecta (borde e icono ✗ rojos), faltante (borde discontinuo verde y +) y desactivada. El texto conserva el color principal para mantener el contraste, y el estado nunca depende solo del color |
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
