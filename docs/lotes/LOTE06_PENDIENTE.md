# Lote 06 · Pendiente para el Mac

Conversión sin Mac del lote 06 de la dirección (27/11/2026), rama `contenido/lote-06`. El texto de la dirección no se ha cambiado. Aquí está lo que no encaja en los esquemas actuales o que requiere Swift.

## 1. Tarjetas de teoría (36, cargadas)

Las 36 están en `Content/teoria/<bloque>.json`, aprobadas (`direccion`, 2026-11-27). Cumplen las reglas de `ValidadorContenido.validar(tarjeta:)`: id `<competencia>.T01`, competencia del catálogo, bloques no vacíos y `texto`/`regla`/`truco` de 40 palabras o menos.

- **Esquemas sin «Etiqueta: valor»** (MAT.UNI.SUP.T01, MAT.UNI.TIEM.T01 y MAT.UNI.VOL.T01): son equivalencias sin etiqueta («1 km² = 100 hm²…»). Se guardan con una línea por elemento; `VistaEsquema` las muestra como filas de texto. Hay que comprobar en el Mac cómo se ven.
- **Separador de los esquemas**: «·» separa las líneas solo cuando el trozo siguiente empieza con «Etiqueta:». Así se conserva el «·» de multiplicar dentro de un valor (MAT.GEO.AREA.T01: «Rectángulo: b · h», MAT.POR.VAR.T01, MAT.POR.PROP.T01).
- **Tests que fijan recuentos y hay que actualizar** (no se toca Swift):
  - `ContenidoTests.swift:25`: `banco.teoria.count == 26` pasa a **62**.
  - `ContenidoTests.swift:67`: `release.teoria.count == 24` pasa a **60**.
  - `ContenidoTests.swift:64–66`: tarjetas de Release por prefijo. `MAT.NUM.` pasa de 2 a **5**; `LEN.LEX.`, de 4 a **8**; `LEN.COM.`, de 4 a **7** (LEN.ORT no cambia).
- **Posible efecto en los tests de interfaz**: las rondas de las 36 competencias muestran ahora la teoría previa. Algunos recorridos de interfaz (por ejemplo, de Matemáticas) pueden encontrar esa pantalla antes que el ítem.

## 2. Tilde en contexto (118 frases)

- `Content/pendiente/tildeContexto.json` tiene ahora, en cada una de las 70 palabras, `frases`: 70 frases de la palabra y 48 de sus variantes. Cada frase lleva `frase` (con `___`), `correcta` y `opciones` (primero la correcta y después las demás formas de la lista de la palabra). Todas las formas correctas del anexo B están en la lista de su palabra.
- **«rio» y «frio»**: la nota de la dirección se guarda literal en `notaDireccion`. El esquema no tiene campo de explicación por frase, así que **el generador debe construir la explicación** que diga que son monosílabos ortográficos sin tilde (RAE, *Ortografía* de 2010).
- **Plantilla `LEN.ORT.CTX.G01` (borrador)**: está en `Content/pendiente/lote06/plantillas_LEN.ORT.CTX.json`, no en `plantillas/`. Debug carga los borradores y la plantilla rompería el test «Todo el contenido del bundle pasa el validador», por tres motivos:
  1. **No existe el generador**. Su `tipo` es `tildeContexto` y hay que implementarlo en Swift: leerá `pendiente/tildeContexto.json` (o esos datos movidos fuera de `pendiente/`). `fraseHueco` no sirve tal cual: lee las familias de `gramatica/frases.json`, y añadir las 70 palabras ahí cambia los recuentos fijos de `FrasesHuecoTests` (100 frases y 28 familias).
  2. **La competencia `LEN.ORT.CTX` no está en el catálogo** (LEN.ORT tiene AGU, DIA, HIA, PQ, HOM, LET, PUNT y MAY). Hay que añadirla, o bien asignar la plantilla a otra competencia y cambiar su id.
  3. **El anexo no da el enunciado ni la dificultad de cada frase**. Se ha reutilizado el enunciado de `LEN.ORT.HOM.G01` («Elige la forma correcta: {{frase}}»), con peldaño 2 y dificultad 2. Las frases no tienen `dificultad`.
- **Tests de propiedades al aprobarla** (los pide la dirección): una sola opción válida por frase y distractores de la misma palabra. Hay un caso para revisar a mano: en «La ___ dirigió la investigación.» (correcta: comisaria), «comisaría» podría leerse por metonimia.
- **Scripts**:
  - `scripts/ambiguas_tilde.py` reescribe `pendiente/tildeContexto.json` y **borraría las `frases`**: hay que conservarlas si se vuelve a ejecutar.
  - `scripts/validar_items.py` ya fallaba en `main`: trata cada `pendiente/*.json` como lista de ítems y se rompe con `tildeContexto.json`, que es un objeto. Por eso los archivos nuevos van en la subcarpeta `pendiente/lote06/`, que el script no recorre.

## 3. Errores de los 8 distractores (no cargados todavía)

Los 8 errores del anexo C están en `Content/pendiente/lote06/errores_remedioEstatico.json`. Cada uno lleva su descripción literal, el distractor que lo delata (`distractores`: ítem y respuesta) y un remedio nuevo:

```json
"remedio": { "tipo": "remedioEstatico", "tarjeta": "<competencia>.T01", "items": ["<ítems aprobados de la competencia>"] }
```

Las tarjetas del remedio existen todas: LEN.COM.INFER.T01 (nueva en este lote), LEN.LEX.SIN.T01, LEN.LEX.DICC.T01 y MAT.NUM.FRAEQ.T01.

No se han añadido a `Content/errores.json` ni se han etiquetado los distractores, por cuatro motivos:

- **La app dejaría de cargar el contenido**: `ErrorTipico.Remedio` decodifica `plantilla` como obligatoria, y un error sin plantilla haría fallar la carga de todo `errores.json`.
- `ValidadorContenido.validar(errores:)` exige además:
  - que `remedio.plantilla` exista y esté cargada (estas competencias no tienen plantilla);
  - `remedio.explicacion` de 1 a 140 caracteres (**el anexo C no la da**);
  - y al menos un patrón en `detecta`.
- **Etiquetar ahora rompería el validador**: el etiquetado sería con el campo `error` del distractor en `items/*.json`, y el validador rechaza un `error` que no esté en `errores.json`.

Qué tiene que hacer el Mac:
1. Admitir `remedio.tipo = "remedioEstatico"` (plantilla opcional; tarjeta e ítems) en `ErrorTipico.Remedio`, en el validador y en el motor de errores (Rescate y sesión con ítems estáticos).
2. Que el validador no exija `detecta` cuando el error solo se asigna a mano con `error` en los ítems estáticos.
3. Mover los 8 errores a `errores.json` y poner `"error": "<id>"` en los 8 distractores:

   | Ítem | Respuesta | Error |
   |---|---|---|
   | LEN.COM.INFER.0001 | falso | ERR.LEN.COM.INFER.1 |
   | LEN.COM.INFER.0004 | detalle | ERR.LEN.COM.INFER.2 |
   | LEN.COM.INFER.0004 | otro | ERR.LEN.COM.INFER.3 |
   | LEN.LEX.SIN.0003 | o2 | ERR.LEN.LEX.SIN.1 |
   | LEN.LEX.SIN.0005 | o2 | ERR.LEN.LEX.SIN.2 |
   | LEN.LEX.SIN.0007 | h2 | ERR.LEN.LEX.SIN.3 |
   | LEN.LEX.DICC.0002 | o3 | ERR.LEN.LEX.DICC.1 |
   | MAT.NUM.FRAEQ.0005 | h1 | ERR.MAT.NUM.FRAEQ.1 |

4. Que la dirección redacte la regla breve del remedio (`explicacion`, como mucho 140 caracteres) de cada error, o que el validador la haga opcional en el remedio estático.
5. Actualizar los tests:
   - D-113: hoy esos 8 son los únicos distractores estáticos aprobados sin etiquetar (comprobado sobre `main`).
   - El recuento del catálogo de errores pasa de 112 a 120.
