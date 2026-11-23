# UX y UI

> **Propósito:** recoger la arquitectura de información, los flujos, el sistema visual y los criterios de accesibilidad.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§1, §3, §5 y §6). Este documento resume y enlaza; si hay discrepancia, manda el original.
> **Estado:** Fase 05A implementada (Hoy, ronda, 10 mecánicas, feedback y resumen). Bienvenida, diagnóstico, Mapa, Examen, Progreso y paywall llegan en la 05B (hoy muestran "Llega pronto").
> **Capturas:** [docs/capturas/fase05a/](docs/capturas/fase05a/) y hoja de contactos [HOJA.png](docs/capturas/fase05a/HOJA.png).

## 1. Principios de experiencia
Promesa (original §1): rondas de pocos minutos, casi sin escribir. Sin teclado del sistema: tocar, arrastrar, deslizar, ruedas, piezas y teclado numérico propio. **Toda interacción de arrastre tiene una alternativa de dos toques** (ficha → destino), siempre disponible y no solo con VoiceOver.

## 2. Arquitectura de información y navegación
Barra de pestañas (original §5): **Hoy** · Mapa · Examen · Progreso. La ronda se abre a pantalla completa desde Hoy; "Ver regla" abre la tarjeta de teoría en una hoja (media o completa).

## 3. Flujos principales (05A)
1. **Hoy** → "Empezar ronda" → (tarjetas de teoría si la competencia está en el peldaño 1) → ítem → **Comprobar** (solo activo con respuesta completa) → corrección en el sitio + panel de feedback → **Continuar** → … → **Resumen** → "Otra ronda" o "Terminar".
2. **Rescate**: ronda solo con los ítems fallados (con variantes).
3. **Ortografía exprés**: 5 ítems de Ortografía y tildes.
4. **Salir a mitad**: la ✕ pide confirmación si ya se ha respondido algo; lo respondido queda guardado y la racha no cuenta.
5. **Revisión de contenido (solo Debug)**: pulsación larga sobre el título "Hoy" (o acción de VoiceOver "Revisión de contenido").

## 4. Sistema visual ("Calma enfocada" con energía en las recompensas)
Código: [Features/Comun/Diseno](Educulter/Features/Comun/Diseno). Colores en `Assets.xcassets/Colores`.

### 4.1 Color (con contraste WCAG AA comprobado, D-038)
| Token | Claro | Oscuro | Uso | Contraste mínimo |
|---|---|---|---|---|
| Fondo | `#F7F6F3` | `#141518` | Fondo de pantalla | — |
| Superficie | `#FFFFFF` | `#1E1F24` | Tarjetas y fichas | — |
| TextoPrincipal | `#1B1C1F` | `#EDEDEF` | Texto | 15,8 / 14,1 |
| TextoSecundario | `#5F6368` | `#A3A7B0` | Texto secundario | 5,6 / 6,8 |
| Lengua (coral) | `#C73F1C`* | `#E4613F` | Acento de Lengua | 4,68 / 4,76 |
| Matemáticas (índigo) | `#4C5BD4` | `#7581DE`* | Acento de Matemáticas | 5,18 / 4,66 |
| Éxito | `#257E55`* | `#2E9E6A` | Correcto | 4,63 / 4,87 |
| Fallo | `#D13030`* | `#DC6060`* | Incorrecto | 4,65 / 4,61 |
| Recompensa (relleno) | `#F2A93B` | `#F2A93B` | XP, combo, nivel (siempre con texto `#141518`) | 9,14 |
| RecompensaTexto | `#9C620A`* | `#F2A93B` | Ámbar como texto o icono | 4,67 / 8,24 |
| TextoSobreAcento | `#FFFFFF` | `#141518` | Texto sobre acentos | ≥ 5,0 |

\* Tono ajustado respecto a la propuesta de la dirección para alcanzar 4,5:1 como texto sobre el fondo (se conserva el matiz; solo cambia la luminosidad). Contraste medido contra el peor caso (Fondo en claro y Superficie en oscuro).

### 4.2 Tipografía
SF Pro con estilos de Dynamic Type (`.body`, `.headline`, `.title3`…); **no hay tamaños fijos de texto** (salvo los iconos decorativos de 48–64 pt de los estados vacíos y del resumen). SF Rounded (`Font.redondeada`) en números, XP, combo, nivel y racha.

### 4.3 Espaciado, radios y áreas táctiles
Espaciado 4/8/12/16/24/32 (`Espacio`). Radio 16 en tarjetas y 12 en fichas (`Radio`). Área táctil mínima 44 × 44 (`Medidas.tactilMinimo`); el botón principal mide 52 pt de alto.

### 4.4 Movimiento
Muelle de 0,3 s (`Movimiento.animacion`). Con "Reducir movimiento": fundido de 0,2 s, sin rotación de la tarjeta de verdadero/falso y sin escalados.

### 4.5 Respuesta háptica (D-040)
Éxito → `.success`; fallo → `.error`; cada 3 aciertos seguidos → impacto medio; selección, colocación y arrastre → `.selection`. Implementada con `sensoryFeedback` de SwiftUI.

### 4.6 Sonido
Protocolo `ServicioSonido` con implementación vacía `SonidoSilencioso` (D-041), para la 05B.

## 5. Componentes
| Componente | Descripción |
|---|---|
| `BotonPrincipal` / `EstiloBotonPrincipal` | Relleno de acento, 52 pt, texto que se adapta; desactivado en gris |
| `EstiloBotonSecundario` | Contorno del color de acento |
| `TarjetaSuperficie` | Superficie, borde fino, radio 16 |
| `Ficha` | Estados normal, seleccionada (relleno de acento), correcta (borde e icono ✓ verdes), incorrecta (borde e icono ✗ rojos), faltante (borde discontinuo verde y +) y desactivada. El texto conserva el color principal para mantener el contraste, y el estado nunca depende solo del color |
| `BarraProgresoRonda` | Segmentos por ítem en el color del área |
| `IndicadorCombo` | Cápsula ámbar "⚡ ×n" desde 2 aciertos seguidos; pulso cada 3 |
| `AnilloDominio` | Anillo de progreso (se usará en el Mapa) |
| `ChipRacha` | 🔥 días · 🛡 protectores · 🏆 récord |
| `HojaFeedback` | Panel inferior: Correcto/Incorrecto, +XP, subida de peldaño, solución, feedback del error habitual, explicación, "Ver regla" y "Continuar" (D-039) |
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
| `segmentar` | Tocar inicio, tocar fin, elegir etiqueta | Igual (todo son toques); borrar tramos desde el árbol | Corchetes y árbol en verde/rojo + solución |
| `ruedas` | Segmentado (≤ 3 opciones cortas) o menú | Controles nativos | Fila ✓/✗ con la correcta; la caja fuerte se abre al acertar |
| `construir` | Tocar pieza (o arrastrar al hueco) | Acciones "Colocar en el hueco n"; tocar un hueco lleno lo vacía | Huecos ✓/✗ |
| `numerico` | Teclado numérico propio | Teclas con nombre accesible | Resultado en verde/rojo |

**Segmentar** (D-045): las instrucciones cambian en tres pasos (inicio → fin → etiqueta). Un tramo dentro de otro se anida solo; si envuelve tramos existentes, estos pasan a ser sus hijos; si se cruza con otro, se rechaza con aviso y vibración de error. Bajo cada palabra se dibujan barras por nivel (la más interna arriba) en el **color de su etiqueta**. Las etiquetas se muestran como píldoras con su color, nombre y abreviatura ("Predicado · PRED"), y debajo aparece el análisis en árbol con sangría por nivel, barra de color y nombre. Tras corregir, el árbol marca cada tramo con ✓/✗ en verde o rojo, y el panel muestra la solución completa. No se escribe texto dentro de las barras: la auditoría exige que todo texto visible sea accesible y escale, y en barras de una palabra no cabría (D-045).

## 7. Accesibilidad
- VoiceOver: todos los controles tienen etiqueta, valor de estado (seleccionada, correcta, incorrecta, emparejado con…) y acciones personalizadas para sustituir el arrastre.
- Dynamic Type hasta AX5: textos con estilos, `fixedSize` vertical para que no se corten, y disposiciones que cambian a vertical (Hoy, emparejar, esquema).
- Reducir movimiento (4.4). Contraste AA (4.1). El estado nunca se comunica solo con color.
- Auditoría automática `performAccessibilityAudit()` en Hoy, teoría previa, cada mecánica (antes y después de comprobar) y resumen: ver [TESTING.md](TESTING.md).

## 8. Microcopias y tono
Español de España, tuteo, frases cortas: "¡Correcto!", "Incorrecto", "Ver regla", "Continuar", "¡Ronda completada!", "Llega pronto".
