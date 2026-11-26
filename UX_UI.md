# UX y UI

> **Propósito:** recoger la arquitectura de información, los flujos, el sistema visual y los criterios de accesibilidad.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§1, §3, §5 y §6). Este documento resume y enlaza; si hay discrepancia, manda el original.
> **Estado:** Fase 05E parte 2: identidad sobria y editorial derivada del logo v5 (D-109), sesión diaria mixta en Hoy, motor de errores en Rescate y Progreso, y ejemplos resueltos (D-111, D-112). Tribunal muestra «Próximamente».
> **Misión:** [docs/MISION_PREMIUM.md](docs/MISION_PREMIUM.md) (vinculante).
> **Capturas:** [docs/capturas/fase05e2/](docs/capturas/fase05e2/) (identidad editorial, sesión diaria, errores y ejemplos resueltos). Las anteriores (05A–05D) son históricas: muestran el estilo Rubber Hose retirado.

## 1. Principios de experiencia
Promesa (original §1): rondas de pocos minutos, casi sin escribir. Sin teclado del sistema: tocar, arrastrar, deslizar, ruedas, piezas y teclado numérico propio. **Toda interacción de arrastre tiene una alternativa de dos toques** (ficha → destino), siempre disponible y no solo con VoiceOver.

## 2. Arquitectura de información y navegación
Barra de pestañas: **Hoy** · **Camino** · **Tribunal** («Próximamente») · **Progreso**. La baldosa Camino de Hoy abre su pestaña. Las rondas y las partidas se abren a pantalla completa (desde Hoy, Camino o Ajustes); "Ver regla" abre la tarjeta de teoría en una hoja. La **bienvenida** (avatar → diagnóstico opcional → plan) aparece a pantalla completa mientras no haya avatar. **Perfil** se abre en una hoja desde el avatar de Hoy o desde Ajustes. **Rescate** y el inicio de **Supervivencia** se abren en hojas desde sus baldosas de Hoy; el **nodo** del Camino, en una hoja.

## 3. Flujos principales (05A–05D)
0. **Primera apertura** → bienvenida (los dos compañeros y la elección de avatar) → «¿Vemos desde dónde partes?» (Empezar diagnóstico | Saltar) → diagnóstico adaptativo («x de N») → **plan** (bloques fuerte/medio/débil con anillos, «Empezamos por…» con 2 competencias y aviso de los bloques sin datos) → Hoy.
1. **Hoy** (05E parte 2 §3.1, D-111): título «Hoy» y avatar; **tu semana** (7 puntos de lunes a domingo: hecho, descanso, hoy o por llegar, con «n de m días») y la racha debajo, con su globo; **Sesión de hoy** con un único botón «Empezar» y «≈ 10 min · 15 preguntas» debajo; selectores de duración (5 · 10 · 15 min) y de foco (Mixto · Lengua · Matemáticas), que se recuerdan; y las baldosas de **Modos** (Camino, Supervivencia, Rescate con su número y Tribunal «Próximamente»). «Empezar» → sesión diaria (remedios, repaso y nuevo intercalados; lo nuevo del peldaño 1 empieza con un ejemplo resuelto) → ítem → **Comprobar** → corrección + feedback → **Continuar** → … → **Resumen** (XP, dominio, error detectado) → «5 minutos más» o «Terminar».
2. **Rescate** (baldosa de Hoy con el número real: ítems por rescatar y errores activos): primero **«Errores que se repiten»** (descripción · n veces, aciertos que faltan y «Practicar el remedio»), después la lista por competencia (errores pendientes, fecha del último y área) → «Rescatar todo» o «Rescatar esta competencia». Cada ítem se puede **ver de nuevo**. Sin errores: estado vacío.
2 bis. **Supervivencia** (baldosa con el récord real) → hoja de inicio (reglas, área Todo | Lengua | Matemáticas, récords) → partida (cabecera con 3 corazones, nivel y puntos en vivo; ítems uno a uno) → al perder la tercera vida, **fin de partida** (puntos, nivel máximo, aciertos, comparación con la mejor partida, récords; Cuarto o Tilde `sorprendido` si hay récord) → "Otra partida" o "Terminar". Salir a mitad pide confirmación: lo jugado se guarda, pero no cuenta para el récord.
2 ter. **Camino** → ruta por área (selector) con las competencias por bloque → nodo → hoja (peldaño, caja y próximo repaso, teoría, "Practicar" y, si procede, "Prueba de nivel") → ronda. Al final de cada bloque con contenido, **Reto de bloque** → ronda de 8 → medalla con 6 aciertos.
2 quater. **Progreso** → errores que estás corrigiendo, nivel examen, dominio, evolución, estadísticas, preguntas disponibles, logros → **Ajustes** (sonido, vibración, tu semana: meta semanal y modo descanso, recordatorio y hora, repetir diagnóstico, cambiar avatar, créditos) y «Borrar mi progreso» (doble confirmación).
2 quinquies. **Recordatorio**: tras la primera ronda o partida completada, una alerta en contexto («¿Te aviso cada día a las 20:00…?» Sí | Ahora no), una sola vez.
3. **Ortografía exprés**: 5 ítems de Ortografía y tildes (sigue en el núcleo; desde la 05E parte 2 no tiene baldosa en Hoy).
4. **Salir a mitad**: la ✕ pide confirmación si ya se ha respondido algo; lo respondido queda guardado y la racha no cuenta.
5. **Revisión de contenido (solo Debug)**: pulsación larga sobre el título "Hoy" (o acción de VoiceOver "Revisión de contenido"). Incluye "Plantillas" (cada plantilla con selector de semilla: ítem generado, clave, complejidad, errores habituales y "Abrir en su mecánica") y "Recuentos del catálogo de preguntas" (D-064).

## 4. Sistema visual editorial (D-109, sustituye a Rubber Hose D-059)
Código: [Features/Comun/Diseno](Educulter/Features/Comun/Diseno). Colores en `Assets.xcassets/Colores`.

**Principio:** la identidad sale del logo v5 (la cuadrícula de cuatro módulos): sobria, limpia y editorial. Superficies planas, mucho espacio, bordes finos y ninguna sombra. **El color codifica el área y el estado, nunca decora.**

### 4.1 Color (contraste WCAG AA comprobado por `PaletaTests` en claro y oscuro)
**Regla:** el texto sobre un relleno usa `Paleta.textoSobre(relleno)`: tinta sobre salvia y ámbar; papel (o tinta en oscuro) sobre bosque y sobre el relleno de acierto.

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| Tinta | `#16241F` | `#E7F0E0` | Marca, iconos, texto principal (14,9:1 / 14,4:1 sobre el papel) |
| Fondo (papel) | `#F4F8F0` | `#142019` | Fondo de pantalla |
| Superficie (papel2) | `#E7F0E0` | `#1E302A` | Baldosas, tarjetas, fichas |
| TextoSecundario | `#545F5A` | `#9BA598` | Texto secundario (≥ 5,1:1 sobre papel, superficie y tintes) |
| Borde | `#C5D3BD` | `#34493F` | Línea fina de 1 pt de las superficies |
| Lengua (salvia) | `#A9BD9F` | `#8FA685` | Relleno de Lengua y de la banda de rayas (tinta encima: 8,0:1) |
| Matemáticas (bosque) | `#2F4A40` | `#A9BD9F` | Relleno de Matemáticas y de los botones primarios (texto encima: 9,0:1 / 8,4:1) |
| Recompensa (ámbar) | `#C98A2E` | `#E0A84F` | XP, racha (tinta encima: 5,5:1) |
| ExitoRelleno (correcto) | `#3F7A55` | `#7FBF93` | Relleno de acierto (texto encima: 4,7:1 / 7,8:1) |
| LenguaTinte / MatemáticasTinte | `#DFE8D9` / `#DDE4DE` | `#22342B` / `#1B2D29` | Panel de la sesión y de la actividad |
| LenguaTinta / MatemáticasTinta* | `#536948` / `#2F4A40` | `#8FA685` / `#A9BD9F` | Texto con color de área |
| RecompensaTexto* | `#855B1E` | `#E0A84F` | Ámbar como texto |
| Éxito* / Fallo* (texto) | `#396E4C` / `#A14935` | `#7FBF93` / `#E8846E` | Estado como texto, icono o borde |
| TextoSobreAcento / TextoSobreBosque | `#16241F` / `#F4F8F0` | `#16241F` / `#142019` | Texto sobre los rellenos |

\* Variantes oscurecidas lo justo para ≥ 4,5:1 sobre papel, superficie y tintes: salvia → `#536948` (4,66:1), ámbar → `#855B1E` (4,62:1), error → `#A14935` (4,61:1) y `#E8846E` en oscuro (el `#E07A62` de la tabla daba 4,47:1 sobre el tinte oscuro), correcto → `#396E4C` (4,62:1).

### 4.2 Formas
- Paneles y botones 24 (`Radio.tarjeta`), fichas 20 (`Radio.ficha`), celdas 8 (`Radio.celda`).
- **Bordes de 1 pt** en el color `Borde` (`Trazo.fino`); 2 pt (`Trazo.estado`) solo para marcar un estado (seleccionada, correcta, incorrecta).
- **Sin sombras.** Lo pulsable se atenúa al pulsar (`superficiePulsable`, `EstiloPulsable`).
- **Banda de rayas** verticales salvia y bosque (`BandaRayas`): solo como textura, en la pantalla de lanzamiento y en la bienvenida.

### 4.3 Tipografía, espaciado y áreas táctiles
- **Fuentes del sistema** con Dynamic Type: SF Pro en la interfaz; títulos (`Font.exhibicion`, estilos de título) y números de resultado (`Font.resultado`) en la **serif del sistema** (New York); números y datos con cifras tabulares (`Font.numerica`). Ninguna fuente empaquetada.
- Espaciado 4/8/12/16/24/32. Área táctil mínima 44 pt; botones principales de 52 pt.

### 4.4 Movimiento
Curvas suaves sin rebote (`smooth`, ≤ 0,35 s): transiciones, pasos que aparecen, contador de XP. La marca entra módulo a módulo en la bienvenida (0,6 s). Con «Reducir movimiento», fundidos o nada.

### 4.5 Iconografía
SF Symbols con un único peso (semibold) y un símbolo por bloque (§4.7). Nada más.

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

### 4.9 Personajes: Tilde, Cuarto y Mimo (D-105, recoloreados en D-109)
Creados por el propietario y redibujados en SVG por la dirección (`docs/arte/v3/`); cada pieza es un grupo con nombre que se anima. Con la paleta editorial: **Tilde**, cuerpo salvia, lupa y brote ámbar (Lengua); **Cuarto**, cuerpo bosque, barriga menta y brote salvia (Matemáticas); **Mimo**, cuerpo menta, brote bosque y corazón ámbar.

Estados: neutro (parpadeo cada 4–6 s), alegre, pensando, ánimo (Mimo aprieta el corazón), guiño (Cuarto) y descanso (ojos cerrados, brote caído). **Presencia reducida**: solo en la bienvenida (Mimo neutro), en el resumen (el del área predominante, alegre) y en el feedback ante un error repetido (Mimo, ánimo). Como mucho uno por pantalla, nunca mientras se resuelve un ítem, decorativos para VoiceOver salvo cuando transmiten un estado («Mimo te anima»).

### 4.10 Cómo entregar ilustraciones propias de los personajes
Con el estilo de los personajes actuales: formas blandas, ojos ovalados y la paleta editorial de §4.1, sin contornos gruesos.
La arquitectura (`RepresentacionPersonaje`) permite sustituir los vectoriales sin tocar las vistas: `.environment(\.representacionPersonaje, .ilustracion(nombreAsset: "personaje"))`. Para entregarlas:
1. **Formato:** PDF o SVG vectorial, **un archivo por estado y personaje** (12 archivos), con **fondo transparente** y lienzo cuadrado, con la figura centrada y un margen del 8 %.
2. **Nombres:** `personaje_tilde_neutral`, `personaje_tilde_pensando`, `personaje_tilde_celebra`, `personaje_tilde_anima`, `personaje_tilde_sorprendido`, `personaje_tilde_dormido`, y lo mismo con `cuarto`.
3. **Colores:** los de la paleta editorial (§4.1). Si hay variante oscura, se entrega aparte con el sufijo `_oscuro`.
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

Se eligen en la bienvenida y en Perfil (cuadrícula 3 × 2; el elegido lleva fondo salvia claro, borde bosque y ✓) y aparecen en la cabecera de Hoy. Los ids 6–11 de la 05B se migran a `id % 6`. El editor de personalización queda para después del MVP.

### 4.12 Pantallas de la Fase 05D
| Pantalla | Contenido |
|---|---|
| **Camino** (`PantallaCamino`) | Título, selector Lengua/Matemáticas y la ruta: por bloque, su símbolo y nombre (con medalla si se ha ganado). Cada competencia es un nodo circular de 56 pt con borde fino: anillo de dominio si está en curso, relleno del área si está dominada, candado si va después de la recomendada, y trazo discontinuo gris con "En preparación" (no pulsable) si no tiene contenido. Línea vertical entre nodos. Al final del bloque, el nodo mostaza "Reto de bloque". |
| **Hoja del nodo** (`HojaNodo`) | Nombre, tarjeta con peldaño (n de 5 y su nombre), caja de repaso y próximo repaso, aviso del candado, "Prueba de nivel" (mostaza, con su explicación), "Practicar" y las tarjetas de teoría. |
| **Inicio de Supervivencia** | Cuarto y el título, las cinco reglas en una tarjeta, selector de área y récords (global y del área). Botón mostaza "Jugar". |
| **Partida** | La ronda de siempre con otra cabecera: ✕, tres corazones (rojos los que quedan), cápsula "Nivel n" ("· Experto" en el 6) y cápsula mostaza con los puntos, que cuentan en vivo. |
| **Fin de partida** | Personaje a 80 pt (`sorprendido` si hay récord), "¡Nuevo récord!" o "Fin de la partida", tarjeta con puntos, nivel máximo y aciertos, comparación con la mejor partida y récords, logros nuevos. "Otra partida" y "Terminar". |
| **Rescate** | Cabecera propia con "Cerrar", "Rescatar todo (n)" en mostaza y una tarjeta por competencia: nombre y símbolo, chip del área, "n errores pendientes · último el …", cada error como fila con 👁 para verlo de nuevo y "Rescatar esta competencia". |
| **Oferta de diagnóstico y plan** | Cuarto pensando, «¿Vemos desde dónde partes?» y la explicación; "Empezar diagnóstico" / "Saltar". El diagnóstico usa la pantalla de ronda con «x de N». Plan: Tilde celebrando, «Tu plan», cada bloque con su anillo y fuerte/medio/débil (aciertos de respondidos), «Empezamos por…» en una tarjeta y el aviso de bloques sin datos. "Ir a Hoy". |
| **Progreso** | Dominio por área y bloque (anillos; los bloques sin contenido, en discontinuo y "En preparación"), evolución de 4 semanas (barras de aciertos o XP, con gráfico de audio), estadísticas, preguntas disponibles (cifra real del contenido aprobado), logros conseguidos y pendientes con su condición, "Ajustes" y "Borrar mi progreso". |
| **Ajustes** | Diseño propio por grupos con contorno: sonido y vibración; recordatorio y hora (selector de hora del sistema, sin teclado); repetir diagnóstico, cambiar avatar y créditos. |

### 4.13 Pantallas de la Fase 05E parte 2
| Pantalla | Contenido |
|---|---|
| **Lanzamiento** | La marca v5 y una banda de rayas sobre el papel (claro y oscuro). |
| **Bienvenida** | Banda de rayas arriba, la marca (entra módulo a módulo) y Mimo pequeño, «Te damos la bienvenida» en serif, el texto de la sesión diaria y los avatares. |
| **Hoy** | Ver §3.1. |
| **Ejemplo resuelto** | Encima del panel de la actividad, «Ejemplo resuelto» con los pasos numerados: frase, resultado intermedio resaltado y el porqué en cursiva. «Siguiente paso» en lugar de «Comprobar» hasta llegar al último, que dice «Este paso lo completas tú»; entonces aparece la mecánica. |
| **Ítem de nivel examen** | Distintivo discreto «Nivel examen» (dificultad 4) o «Por encima del examen» (5–6) bajo el nombre de la competencia. |
| **Feedback tras un fallo** | Con pasos, «Cómo se resuelve» con la lista numerada. |
| **Resumen** | «Sesión completada» en serif y el personaje alegre; aciertos; «+N XP» en ámbar; Dominio (competencias que suben, con el nombre del peldaño); Error detectado («Volverá el viernes 27»); la racha en una línea sin culpa; «5 minutos más» y «Terminar». |
| **Progreso** | «Errores que estás corrigiendo» y «Nivel examen» antes del dominio. |
| **Ajustes** | Grupo «Tu semana»: meta semanal (3–7) y modo descanso con los días que quedan. |

## 5. Componentes
| Componente | Descripción |
|---|---|
| `PanelProtagonista` | El único elemento tintado de la pantalla (radio 24, plano, sin borde). Dentro, las superficies usan el papel (`enPanelTintado`) |
| `Baldosa` | Baldosa de modo en Hoy: superficie con borde fino y, si hace falta, un contador. Desactivada: sobre el papel y con su motivo («Próximamente») |
| `PuntosSemana` | Los 7 días de la meta semanal; un solo elemento de VoiceOver con la lectura completa |
| `VistaEjemploResuelto` / `FilaPaso` | Pasos del ejemplo resuelto; cada paso es un elemento de VoiceOver y se anuncia al aparecer |
| `DistintivoNivel` | «Nivel examen» / «Por encima del examen» |
| `BandaRayas` / `MarcaView` | Textura de rayas y la marca v5 |
| `VistaPersonaje` | Tilde, Cuarto o Mimo en un estado (§4.9), con representación intercambiable |
| `VistaAvatar` / `SelectorAvatar` | Avatar geométrico y cuadrícula de los 12 (bienvenida y Perfil) |
| `BotonPrincipal` / `EstiloBotonPrincipal` | Relleno bosque (o del área) sin borde, con `textoSobre`; se atenúa al pulsar; 52 pt. Desactivado: superficie con borde |
| `EstiloBotonSecundario` | Superficie con texto en tinta y borde fino |
| `TarjetaSuperficie` | Superficie con borde fino, radio 24 |
| `EstiloPulsable` / `superficiePulsable` | Relleno y borde fino; al pulsar se atenúa (D-109) |
| `Ficha` | Superficie con borde fino; estados normal, seleccionada (relleno de acento), correcta (borde e icono ✓ verdes), incorrecta (borde e icono ✗ rojos), faltante (borde discontinuo verde y +) y desactivada. El texto conserva el color principal para mantener el contraste, y el estado nunca depende solo del color |
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
Español de España, tuteo, frases cortas: «¡Correcto!», «No es correcto», «Ver regla», «Continuar», «Empezar», «Siguiente paso», «Este paso lo completas tú», «Sesión completada», «5 minutos más», «Volverá el viernes 27», «Próximamente». **Sin culpa**: si se pierde la racha, «Empiezas una racha nueva», sin números rojos ni animación triste.
