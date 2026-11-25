# Contenidos

> **Propósito:** recoger el inventario, el formato y la procedencia de todo el contenido educativo.
> **Regla:** solo contenido original o de dominio público, con su procedencia registrada. Nunca se copia material de academias ni editoriales.
> **Diseño de referencia:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§2.1 estructura, §3 mecánicas).

## 1. Temario de referencia (prueba A1, Madrid)
<!-- Fuente oficial citada: pendiente de la dirección -->

### Bloques y prioridad (catálogo v1)

La prioridad va de 1 (★) a 3 (★★★). Los bloques ★★★ entran en el diagnóstico. Prioridades definitivas de la dirección (D-031).

| Lengua (LEN) | Prioridad | Matemáticas (MAT) | Prioridad |
|---|---|---|---|
| SIN Sintaxis | 3 | UNI Unidades y medida | 3 |
| ORT Ortografía y tildes | 3 | GEO Geometría | 3 |
| CLA Clases de palabras | 3 | POR Porcentajes y proporcionalidad | 3 |
| VER Formas verbales | 3 | NUM Fracciones y decimales | 3 |
| LIT Autores y épocas | 3 | DIV Divisibilidad (m.c.m./m.c.d.) | 3 |
| COM Comprensión (tema y resumen) | 3 | OPE Operaciones combinadas y ecuaciones | 3 |
| REC Recursos literarios | 2 | ROM Números romanos | 2 |
| MET Métrica | 2 | EST Estadística | 2 |
| LEX Léxico y vocabulario | 2 | PRO Probabilidad | 2 |
| FOR Formación de palabras | 2 | | |

## 2. Formato de contenido (esquema v1)

Todo el contenido vive en `Educulter/Content/` y se empaqueta en la app como carpeta (D-018):

```
Content/
  catalogo.json              Áreas → bloques → competencias
  items/<bloque>.json        Array de ítems de un bloque (p. ej. items/LEN.SIN.json)
  teoria/<bloque>.json       Array de tarjetas de teoría de un bloque
  simulacros/<id>.json       Un simulacro por archivo (p. ej. simulacros/SIM.01.json)
```

Modelos Swift: [Core/Content](Educulter/Core/Content). El validador ([ValidadorContenido.swift](Educulter/Core/Content/ValidadorContenido.swift)) se ejecuta en los tests sobre todo el contenido del bundle; **un contenido que no lo pase rompe la compilación verificada**.

### 2.1 Identificadores (D-019)

| Elemento | Formato | Ejemplo |
|---|---|---|
| Área | 3 mayúsculas | `LEN`, `MAT` |
| Bloque | `<área>.XXX` | `LEN.SIN` |
| Competencia | `<bloque>.CODIGO` (2–16 mayúsculas o dígitos) | `LEN.SIN.SUJPRED` |
| Ítem | `<competencia>.NNNN` | `LEN.SIN.SUJPRED.0001` |
| Tarjeta de teoría | `<competencia>.TNN` | `LEN.SIN.SUJPRED.T01` |
| Simulacro | `SIM.NN` | `SIM.01` |
| Ids internos del payload | libres, únicos dentro del ítem | `t1`, `a`, `h1` |

### 2.2 Catálogo

```json
{ "version": 1,
  "areas": [ { "id": "LEN", "nombre": "Lengua Castellana y Literatura",
    "bloques": [ { "id": "LEN.SIN", "nombre": "Sintaxis", "prioridad": 3, "orden": 1,
      "competencias": [ { "id": "LEN.SIN.SUJPRED", "nombre": "Sujeto y predicado", "orden": 1 } ] } ] } ] }
```

### 2.3 Ítem

```json
{ "id": "LEN.SIN.SUJPRED.0001", "competencia": "LEN.SIN.SUJPRED",
  "peldano": 2, "dificultad": 2, "objetivo": "…", "mecanica": "segmentar",
  "enunciado": "…", "payload": { },
  "pistas": ["…"], "explicacion": "…",
  "erroresHabituales": [ { "respuesta": "<id u opción>", "feedback": "…" } ],
  "referencia": { "tipoPregunta": "…", "examenes": ["2017-L9"], "normativa": "…" },
  "procedencia": { "tipo": "original", "autorTexto": null, "anioMuerteAutor": null, "fuente": null, "licencia": "propia", "notas": "" },
  "validacion": { "estado": "borrador", "revisor": "", "fecha": "" },
  "version": 1 }
```

| Campo | Obligatorio | Reglas |
|---|---|---|
| `peldano` | sí | 1 Descubre · 2 Practica · 3 Sin ayudas · 4 Justifica · 5 Formato examen |
| `dificultad` | sí | 1–5 |
| `objetivo`, `enunciado` | sí | no vacíos |
| `explicacion` | sí | 1–280 caracteres |
| `pistas` | no (por defecto `[]`) | las rondas de peldaño ≥ 3 no las muestran |
| `erroresHabituales` | no (por defecto `[]`) | `respuesta` se compara con `Resultado.errores` (ver 2.5) |
| `referencia` | no | `examenes` con formato `AAAA-L9` / `AAAA-M9` |
| `procedencia` | sí | ver 2.7 |
| `validacion` | sí | `aprobado` exige `revisor` y `fecha` `AAAA-MM-DD` |
| `version` | sí | ≥ 1 |

### 2.4 Payload por mecánica

| Mecánica | Payload | Reglas del validador |
|---|---|---|
| `eleccion` | `{ "opciones":[{"id","texto"}], "correcta":"id" }` | 2–4 opciones; `correcta` existe; los errores habituales son opciones incorrectas |
| `verdaderoFalso` | `{ "afirmacion", "esVerdadera": bool }` | afirmación no vacía |
| `clasificar` | `{ "categorias":[{"id","nombre"}], "fichas":[{"id","texto","categoria"}] }` | 2–4 categorías; cada ficha con categoría válida |
| `ordenar` | `{ "fichas":[{"id","texto"}], "ordenCorrecto":["id"], "etiquetaInicio", "etiquetaFin" }` | ≥ 2 fichas; `ordenCorrecto` es permutación; etiquetas opcionales |
| `emparejar` | `{ "izquierda":[…], "derecha":[…], "pares":[["idI","idD"]] }` | cada par tiene 2 ids existentes; cubren cada elemento una sola vez (biyección) |
| `marcarTexto` | `{ "unidad":"palabra\|silaba", "tokens":[…], "correctos":["id"] }` | al menos 1 correcto; todos existen; sin repetidos |
| `segmentar` | `{ "tokens":[…], "etiquetas":[{"id","nombre"}], "segmentos":[{"id","desde","hasta","etiqueta","padre"}] }` | ver 2.4.1 |
| `ruedas` | `{ "ruedas":[{"id","nombre","opciones":["…"],"correcta":"…"}] }` | 1–5 ruedas; ≥ 2 opciones sin repetir; `correcta` entre las opciones |
| `construir` | `{ "plantilla":"… {h1} …", "huecos":[{"id","correcta":"pieceId"}], "piezas":[{"id","texto"}] }` | cada `{id}` de la plantilla tiene hueco y viceversa; `correcta` es una pieza existente; las piezas sobrantes actúan como distractores |
| `numerico` | `{ "respuesta":"573,75", "formato":"entero\|decimal\|fraccion", "tolerancia":0, "unidad":"€", "exigeIrreducible": true }` | ver 2.4.2 |
| `colocarTilde` (05B) | `{ "palabra":"cancion", "indiceTilde":5 }` (`null` si no lleva) | `palabra` en minúsculas, solo letras y sin tildes; el índice existe y apunta a una vocal (a, e, i, o, u) |
| `fraccionBarras` (05B) | `{ "modo":"colorear\|dividirYColorear", "partes":4, "objetivo":"3/4", "aceptarEquivalentes":false, "particionesPermitidas":[6,9] }` | objetivo `n/d` propio (denominador 2–12); en `colorear`, `partes` obligatorio (2–12), `partes × objetivo` entero y, sin equivalentes, `partes` = denominador; `particionesPermitidas` solo en `dividirYColorear` (con `partes: null`), cada una capaz de representar el objetivo |

#### 2.4.1 Segmentar: rangos y anidamiento

- `desde` y `hasta` son ids de token (ambos incluidos) y `desde` no va después de `hasta`.
- `padre` es el id de otro segmento (o `null`). El hijo debe quedar **dentro** del rango del padre (puede coincidir con él). No se admiten ciclos.
- Los segmentos con el mismo padre (o todos los de primer nivel) **no pueden solaparse**. Si un segmento contiene a otro, el anidamiento debe declararse con `padre`.
- La corrección compara la estructura (rango + etiqueta + estructura del padre), no los ids: el usuario puede crear segmentos con ids propios.

Ejemplo: «Vive en la casa de Ana» → `PRED[t1–t6]` ⊃ `CCL[t2–t6]` ⊃ `SN[t3–t6]` ⊃ `CN[t5–t6]`.

#### 2.4.2 Numérico

- Separador decimal: **coma** (`"573,75"`). Sin separador de miles. Signo `-` delante. Fracción: `"a/b"` con `b > 0`.
- `formato` declara cómo está escrita `respuesta`; un `decimal` admite también un entero (`"12"`).
- `tolerancia` es absoluta (0 o ausente = exacta). La comparación es exacta con números racionales: `"573,750"` = `"573,75"`.
- `exigeIrreducible` (opcional, extensión v1, D-020): con `formato: "fraccion"`, el usuario debe responder con una fracción irreducible (no vale `6/8` ni `0,75` si la respuesta es `3/4`). Sin este campo, se acepta cualquier escritura equivalente.

### 2.5 Errores habituales y `Resultado.errores`

El feedback específico se elige cruzando `erroresHabituales[].respuesta` con los errores detectados por el evaluador:

| Mecánica | Valor de `respuesta` que activa el feedback |
|---|---|
| `eleccion` | id de la opción incorrecta elegida |
| `verdaderoFalso` | `"verdadero"` o `"falso"` (lo que respondió el usuario) |
| `clasificar`, `ordenar` | id de la ficha mal colocada |
| `emparejar` | id del elemento de la izquierda mal emparejado |
| `marcarTexto` | id del token marcado de más o de menos |
| `segmentar` | id del segmento esperado que no se ha reproducido |
| `ruedas` | id de la rueda fallada |
| `construir` | id del hueco fallado |
| `numerico` | texto exacto tecleado (p. ej. `"2/6"`) |
| `colocarTilde` | `"sinTilde"` (no puso tilde y la llevaba), `"conTilde"` (la puso y no la llevaba) o `"posicion"` (en otra vocal) |
| `fraccionBarras` | `"partes"` (división no válida o no permitida) o `"coloreadas"` (cantidad incorrecta) |

### 2.6 Tarjeta de teoría

```json
{ "id": "LEN.SIN.SUJPRED.T01", "competencia": "LEN.SIN.SUJPRED", "titulo": "…",
  "bloques": [ { "tipo": "texto|regla|ejemplo|esquema", "contenido": "…" } ],
  "procedencia": { … }, "validacion": { … } }
```

Los bloques `texto` y `regla` tienen **40 palabras o menos** (se cuentan por espacios). `ejemplo` y `esquema` no tienen límite, pero deben ser breves. `contenido` es texto plano.

### 2.7 Procedencia

| `tipo` | `licencia` | Campos obligatorios |
|---|---|---|
| `original` | `"propia"` | — |
| `dominioPublico` | `"dominio publico"` | `autorTexto`, `fuente`, `anioMuerteAutor` con **año actual − año de muerte > 80** |

### 2.8 Simulacro

```json
{ "id": "SIM.01", "titulo": "…", "duracionMin": 90,
  "textoBase": { "texto": "…", "autor": null, "obra": null, "procedencia": { … } },
  "preguntas": [ { "numero": 1, "area": "LEN", "enunciado": "…", "solucionModelo": "…", "puntos": 1,
                   "rubrica": { "bien": "…", "regular": "…", "mal": "…" }, "competencias": ["LEN.SIN.SUJPRED"] } ],
  "validacion": { … } }
```

Preguntas numeradas 1, 2, 3… en orden; `area` es `LEN` o `MAT`; las competencias existen en el catálogo; `puntos` > 0; rúbrica completa (1 / 0,5 / 0). `textoBase` es opcional; si existe, su procedencia se valida igual que la de un ítem.

### 2.9 Carga según la configuración

- **Debug**: se carga todo el contenido.
- **Release**: solo los elementos con `validacion.estado == "aprobado"`. Un test comprueba que en Release no se carga ningún borrador.

### 2.10 Plantillas de generador (Fase 05C, D-062)
Plan de volumen y fuentes: [docs/PLAN_CONTENIDOS.md](docs/PLAN_CONTENIDOS.md). Matriz de exámenes oficiales: [docs/examenes/MATRIZ.md](docs/examenes/MATRIZ.md).

`Content/plantillas/<bloque>.json` (array). Campos:

| Campo | Descripción |
|---|---|
| `id` | `<competencia>.Gnn` (p. ej. `MAT.POR.PORCENT.G01`). Los ítems generados son `<id>#<semilla>` |
| `competencia`, `peldano` (1–5), `dificultad` (1–6) | Como en los ítems; 6 = "Experto" (D-063) |
| `mecanica`, `tipo` | Mecánica y generador de código que la implementa (tabla siguiente) |
| `parametros` | Opcional. Restringe lo que el generador usa por defecto: listas (`["a","b"]`), números o rangos (`{"min":1,"max":9}`) |
| `enunciados` | Varias redacciones con marcadores `{{…}}` del generador; se elige una con la semilla |
| `contextos` | Opcional. Redacciones de problema; la elegida se inserta como `{{contexto}}` |
| `objetivo`, `pistas` | Opcionales (pistas solo en peldaños 1–2) |
| `procedencia`, `validacion`, `version` | Como en los ítems; `borrador` no se carga en Release |

| `tipo` | Mecánicas | Marcadores | Parámetros |
|---|---|---|---|
| `porcentajeDe` | numerico, eleccion | pregunta, p, p2, base, parte, unidad | `variantes` (porcentajeDe, aumento, descuento, cantidadDesde, sucesivos), `unidad` |
| `conversionUnidades` | numerico, ruedas | cantidad, desde, hasta, resultado, magnitud | `magnitudes` (longitud, masa, capacidad, superficie, volumen) |
| `fraccionBarras` | fraccionBarras | fraccion, partes, particiones | — |
| `ordenarNumeros` | ordenar | orden, numeros | `orden` (mayorAMenor, menorAMayor) |
| `romanos` | numerico (romano → arábigo), construir (arábigo → romano) | numero, romano | — |
| `operacionesCombinadas` | ordenar (pasos), numerico (resultado) | expresion | — |
| `mcmMcd` | numerico | a, b, c, numeros, operacion, min, max | `operacion` (mcm, mcd) |
| `estadisticaBasica` | numerico | medida, datos, n | `medidas` (media, mediana, moda, rango) |
| `probabilidadSimple` | numerico (fracción) | experimento, suceso | — |
| `ecuacionLineal` | numerico | ecuacion | — |
| `colocarTilde` | colocarTilde | — | (léxico) |
| `clasificarAcentuacion` | eleccion | palabra | (léxico) |
| `silabaTonica` | marcarTexto (sílabas) | palabra | (léxico) |
| `oracionSimple` | segmentar, clasificar, eleccion | oracion, sintagma | (piezas de gramática) |
| `analisisVerbal` | ruedas | forma, infinitivo | (verbos) |
| `fraseHueco` | eleccion, construir | frase | `familias` |

La tabla de cómo escala cada generador con la dificultad (1–6) y sus reglas de error está documentada en su código (`Core/Content/Generadores`). La solución y los distractores los calcula siempre el código. Cada distractor sale de una regla de error típico y lleva su `erroresHabituales` con el feedback de esa regla.

### 2.11 Recursos de los generadores de Lengua
- **`lexico/palabras.json`**: `[{"palabra": "canción"}, {"palabra": "robots", "tonica": 1}, {"palabra": "él", "diacritica": true}]`. Solo `palabra` es obligatoria. `tonica` es el índice de la sílaba (desde 0) cuando las reglas no lo deducen. Las palabras incoherentes con las reglas de la RAE salen como errores del validador (D-065).
- **`gramatica/piezas.json`**: `sujetos` (tokens `[texto, clase]`, `genero`, `numero`); `verbos` (`infinitivo`, `regimen`: intransitivo, transitivo o copulativo; `cd` compatibles; `ci`); `complementos` (`CI`, `CCL`, `CCT` (con `tiempo` opcional), `CCM`); `atributos` (formas `ms`, `fs`, `mp`, `fp`). Clases: det, sust, verbo, adj, prep, adv, pron.
- **`gramatica/verbos.json`**: `regulares` (infinitivos) e `irregulares` (`infinitivo`, `participio`, `formas` por `"Modo|Tiempo"` con 6 personas).
- **`gramatica/frases.json`**: `familias` (formas con su uso) y `frases` (`id`, `familia`, `texto` con `___`, `correcta`, `dificultad`).

### 2.12 Catálogo de preguntas (D-064)
`CatalogoPreguntas` suma los ítems estáticos y las variantes únicas de las plantillas (sin duplicados, por clave canónica). Lo hace por área, bloque, competencia, peldaño y dificultad, y marca como cota inferior ("≥") los espacios que se muestrean. La tabla está en Revisión → "Recuentos del catálogo de preguntas".

### 2.13 Base literaria (Lote 05a, D-078 y D-079)
Archivo `Content/literatura/literatura.json` (en el repositorio, `Educulter/Content/literatura/`): `{"version": 2, "movimientos": […], "autores": […]}`. Todavía no lo lee la app: lo usará el motor literario de la Fase 05F.

- **Movimiento**: `{id, nombre, periodo, inicio, fin|null, rasgos[2]}`. `rasgos` lleva exactamente dos textos. `fin: null` indica que el movimiento sigue abierto.
- **Autor**: `{id, nombre, nacimiento|null, muerte|null, aproximado, ambito, pais, movimiento, generos[], obras[{titulo, anio|null, genero}], rasgo, dominioPublico, fragmentosPermitidos}`.
  - `ambito`: `espanola`, `hispanoamericana`, `universal` o `infantil`.
  - `movimiento`: `id` de un movimiento existente.
  - `generos` y `obras[].genero`: `poesia`, `narrativa`, `teatro` o `ensayo`. Cada género de una obra figura también en los géneros del autor.
  - Los años negativos son a. C. `aproximado: true` indica fechas aproximadas.
  - `pais`: nombre del Estado actual («Reino Unido», no «Inglaterra» ni «Escocia»; «Italia», no «Roma»).
  - `dominioPublico`: si la obra original del autor es de dominio público en España. Es `true` si el autor murió en 1945 o antes, o si es anónimo o antiguo (sin fechas).
  - `fragmentosPermitidos` (versión 2): si se pueden reproducir fragmentos del autor. Es `true` solo si `dominioPublico` es `true` y el ámbito es `espanola` o `hispanoamericana`. Una traducción publicada tiene sus propios derechos, así que de un autor extranjero de dominio público solo se pueden usar fragmentos traducidos por la dirección (traducción propia), nunca tomados de traducciones publicadas.
- **Convenciones**:
  - **Géneros**: las greguerías se clasifican como `ensayo`, por ser prosa breve, y la prosa mística doctrinal también («Las moradas»).
  - **Año de una obra**: el de publicación o estreno. Si la obra se publicó mucho después de escribirse, se usa el año de escritura («La casa de Bernarda Alba», 1936).
- **Regla para el motor 05F**: las preguntas «¿a qué movimiento pertenece?» se hacen sobre el autor. Sobre una obra, solo si su año está dentro del rango (`inicio`–`fin`) del movimiento del autor.
- **Validación**: `python3 scripts/validar_literatura.py` (solo biblioteca estándar) comprueba:
  - que el JSON es válido y los ids son únicos;
  - que existe el movimiento de cada autor;
  - que el nacimiento es anterior a la muerte;
  - que el año de cada obra está entre el nacimiento y la muerte + 10 (ediciones póstumas);
  - que `dominioPublico` y `fragmentosPermitidos` son coherentes con sus reglas;
  - que no hay espacios dobles.

  Avisa, sin fallar, si el género de una obra no figura en los géneros del autor.
- **Errata**: `scripts/errata_literatura_05a.py` reescribió la versión 1 como versión 2 (errata 1). Se conserva como registro, pero no debe volver a ejecutarse.

## 3. Registro de procedencia

| ID | Tipo | Autoría u origen | Licencia | Fecha |
|---|---|---|---|---|
| Ítems, tarjetas y SIM.01 de prueba (Fases 04 y 05A) | original | Claude Code, solo para tests y desarrollo (estado `borrador`, solo Debug) | propia | 2026-11-23 |
| Lote 01 · `LEN.ORT.*` (38 ítems y 5 tarjetas) | original | Redacción original de la dirección del proyecto | propia | 2026-11-23 |
| Lote 02 · 38 plantillas (MAT y LEN.ORT.AGU), léxico de 818 palabras y formas verbales | original | Especificación de la dirección del proyecto; redacciones literales de la dirección en los generadores y redacciones propias marcadas «A.2» | propia | 2026-11-24 |
| Lote 05a · Base literaria (`literatura/literatura.json`) | original | Datos biográficos y bibliográficos de conocimiento general, con rasgos redactados por la dirección del proyecto. No incluye fragmentos de obras | propia | 2026-11-24 |
| Fragmentos literarios (regla del lote 05a · errata 1) | original o dominio público | Solo de autores con `fragmentosPermitidos: true` (dominio público y en lengua original española). De un autor extranjero de dominio público solo se usa una traducción propia de la dirección, registrada aquí con el autor y la obra; nunca una traducción publicada | propia (traducciones) o dominio público (originales) | 2026-11-24 |

## 4. Proceso de revisión y calidad

`borrador` → `revisado` → `aprobado` (con revisor y fecha). Solo lo aprobado llega a Release. El test «Todo el contenido del bundle pasa el validador» se ejecuta en cada verificación de fase.

## 5. Registro de lotes

| Lote | Bloque | Ítems | Tarjetas | Estado | Archivos |
|---|---|---|---|---|---|
| Lote 01 | LEN.ORT (Ortografía y tildes) | 38 | 5 | Aprobado por la dirección 23/11/2026 | `items/LEN.ORT.json`, `teoria/LEN.ORT.json` |
| Lote 01 · errata 1 | LEN.ORT | 3 (versión 2) | — | Aprobada por la dirección 23/11/2026 | `items/LEN.ORT.json` |
| Lote 02 · piloto 05B | LEN.ORT (`colocarTilde`) y MAT.NUM (Fracciones) | 12 + 9 | 2 (MAT.NUM) | Aprobado por la dirección 23/11/2026 | `items/LEN.ORT.json`, `items/MAT.NUM.json`, `teoria/MAT.NUM.json` |
| Lote 02 | MAT (5 bloques) y LEN.ORT.AGU | 38 plantillas | — | Aprobado por la dirección 24/11/2026; las 38 superan los tests de propiedades (24/11/2026) | `plantillas/MAT.*.json`, `plantillas/LEN.ORT.json`, `lexico/palabras.json`, `lexico/formas_verbales.json`, `catalogo.json` |
| Lote 05a · Base literaria | Literatura (142 autores · 19 movimientos) | — | — | Aprobado por la dirección 24/11/2026 · pendiente del motor literario (Fase 05F) | `literatura/literatura.json` |
| Lote 05a · errata 1 · versión 2 | Literatura (142 autores · 21 movimientos · 50 con fragmentos permitidos) | — | — | Aprobada por la dirección 24/11/2026 | `literatura/literatura.json` |

**Lote 01 · LEN.ORT · 38 ítems · 5 tarjetas · aprobado por la dirección 23/11/2026.** Competencias (sustituyen a la de prueba `LEN.ORT.TILDES`, cuyos 5 borradores y su tarjeta se eliminaron):

| Competencia | Ítems | Peldaños 1/2/3/4 | Mecánicas |
|---|---|---|---|
| LEN.ORT.AGU Agudas, llanas y esdrújulas | 9 | 2/3/2/2 | elección, clasificar, marcar texto (sílabas y palabras), verdadero/falso, construir |
| LEN.ORT.DIA Tilde diacrítica | 9 | 2/2/3/2 | elección, emparejar, verdadero/falso, marcar texto, construir |
| LEN.ORT.HIA Diptongo, hiato y tilde | 6 | 1/2/2/1 | elección, clasificar, verdadero/falso, construir |
| LEN.ORT.PQ Por qué, porque, porqué y por que | 6 | 1/2/2/1 | elección, construir |
| LEN.ORT.HOM Homófonos frecuentes | 8 | 1/3/3/1 | elección, marcar texto, construir |

Validación técnica: el lote pasa el validador sin cambios; en Release se cargan exactamente estos 38 ítems y 5 tarjetas y ningún borrador (`ContenidoEmpaquetadoTests.releaseNoCargaBorradores`). Las observaciones de contenido para la dirección figuran en el informe de la Fase 05A.1.

**Errata 1 del lote 01 (23/11/2026, versión 2 de 3 ítems)**, a partir de las observaciones de la 05A.1:
- `LEN.ORT.HIA.0003`: el ejemplo «reloj» (termina en -j) pasa a ser «nariz».
- `LEN.ORT.DIA.0003`: se emparejan las palabras con frases donde encajan («___ canta muy bien.», «A ___ me encanta.»…), de modo que cada frase admite una sola palabra (se elimina la ambigüedad él/mí).
- `LEN.ORT.DIA.0008`: se adopta la terminología de la NGLE, «determinante posesivo».

**Lote 02 · piloto 05B (23/11/2026).**
- LEN.ORT.AGU.0010–0021: 12 ítems de `colocarTilde`, peldaños 2–3.
- MAT.NUM: sus competencias se sustituyen por MAT.NUM.FRAREP («Representar fracciones», 4 ítems) y MAT.NUM.FRAEQ («Fracciones equivalentes», 5 ítems: 4 de `fraccionBarras` y 1 de `construir`), con una tarjeta de teoría cada una.
- Los borradores de prueba de MAT.NUM (FRACSUM y EQUIV) pasan a MAT.OPE (D-057).
- Pasa el validador sin cambios. En Release se cargan 50 ítems de LEN.ORT, 9 de MAT.NUM, 5 tarjetas de LEN.ORT y 2 de MAT.NUM, y ningún borrador.


### Fase 05C · Plantillas de prueba (borrador)
23 plantillas en borrador (`Content/plantillas/*.json`) que cubren los 16 tipos y todas sus mecánicas, más un léxico de 15 palabras, piezas de gramática, 14 verbos regulares y 6 irregulares, y 19 frases de 10 familias. Todo es original y **no se carga en Release**: sirve para probar el motor hasta que llegue el contenido real del lote 02. Se añaden las competencias `MAT.OPE.ECUAC`, `MAT.EST.CENTRAL` y `MAT.PRO.LAPLACE` (catálogo v2, D-068).

### Lote 02 · Matemáticas y acentuación (24/11/2026, verificado en el Mac el mismo día)
38 plantillas aprobadas por la dirección (`validacion.estado = aprobado`, revisor `direccion`, 24/11/2026) y 16 competencias nuevas en el catálogo (v2). **Una plantilla solo queda aprobada si supera los tests de propiedades** (TESTING §12): las 38 los superan, ninguna vuelve a borrador.

| Competencia | Plantillas (tipo · mecánica · dificultad) |
|---|---|
| LEN.ORT.AGU Agudas, llanas y esdrújulas | G01 `colocarTilde` d2 · G02 `colocarTilde` d3 · G03 `clasificarAcentuacion` (clasificar) d2 · G04 `silabaTonica` (marcar texto) d1 |
| MAT.NUM.ORDEN Ordenar fracciones y decimales | G01 `ordenarNumeros` d2 · G02 d3 |
| MAT.NUM.FRAOP Operaciones con fracciones | G01 `fraccionesOperar` d2 · G02 d3 · G03 d4 |
| MAT.NUM.FRAPROB Problemas con fracciones | G01 `problemaFraccion` d3 · G02 d4 |
| MAT.OPE.JER Jerarquía de las operaciones | G01 `operacionesCombinadas` (numérico) d2 · G02 (ordenar) d3 |
| MAT.OPE.COMB Operaciones combinadas con paréntesis y corchetes | G01 `operacionesCombinadas` (ordenar) d3 · G02 (numérico) d4 |
| MAT.OPE.ECUAC Ecuaciones de primer grado | G01 `ecuacionLineal` d2 · G02 d3 · G03 d4 |
| MAT.POR.CALC Tanto por ciento de una cantidad | G01 `porcentajeDe` d2 · G02 d3 |
| MAT.POR.TOTAL Total a partir de una parte | G01 `porcentajeDe` d3 |
| MAT.POR.VAR Aumentos y descuentos | G01 `porcentajeDe` d3 · G02 (construir, «Justifica») d4 |
| MAT.POR.PROP Proporcionalidad directa | G01 `reglaDeTres` d2 · G02 d3 |
| MAT.ROM.LEER / MAT.ROM.ESCR Números romanos | LEER G01 `romanos` (numérico) d2 · G02 (elección) d3 · ESCR G01 (construir) d2 · G02 d3 |
| MAT.UNI.LMC / SUP / VOL Unidades | LMC G01 `conversionUnidades` d2 · G02 d3 · SUP G01 d3 · VOL G01 d3 |
| MAT.UNI.TIEM Tiempo sexagesimal | G01 `sexagesimal` (numérico) d2 · G02 (ruedas) d3 · G03 (ruedas) d4 |
| MAT.UNI.ESC Escalas | G01 `escala` d3 · G02 d4 |

- **Generadores**: 5 nuevos (`reglaDeTres`, `sexagesimal`, `escala`, `fraccionesOperar`, `problemaFraccion`) y 6 reescritos con las tablas de dificultad 1–6 de la dirección (`porcentajeDe`, `conversionUnidades`, `romanos`, `operacionesCombinadas`, `ecuacionLineal`, `ordenarNumeros`). Las tablas están documentadas en cada generador (`Core/Content/Generadores/GeneradoresLote02*.swift`).
- **Redacciones**: las literales de la especificación viven en el generador (la plantilla usa `{{pregunta}}`), para que cada contexto solo se use con datos que tengan sentido (alumnos enteros, euros con dos decimales…). Las redacciones propias van marcadas con «A.2» en el código. Nombres propios de los enunciados: los 12 de la lista A.6.
- **Léxico**: `lexico/palabras.json` con 818 palabras y `lexico/formas_verbales.json`. Niveles de palabra 1–6 (D-077): 322 · 319 · 65 · 58 · 8 · 46. **0 discrepancias** entre la tilde escrita y el silabeador con las reglas de la RAE (las 3 que señalaba el informe WIP —«prohíbe», «ahínco», «rehúso»— eran un fallo del código con la *h* intercalada, no del dato).
- **Release**: carga las 38 plantillas y ninguna de las 10 de prueba de la 05C que quedan (siguen en borrador: LEN.CLA, LEN.ORT.DIA/PQ, LEN.SIN, LEN.VER, MAT.DIV, MAT.EST, MAT.NUM.FRAREP y MAT.PRO).

