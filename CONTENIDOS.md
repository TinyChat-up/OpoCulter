# Contenidos

> **Propósito:** recoger el inventario, el formato y la procedencia de todo el contenido educativo.
> **Regla:** solo contenido original o de dominio público, con su procedencia registrada. Nunca se copia material de academias ni editoriales.
> **Diseño de referencia:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§2.1 estructura, §3 mecánicas).

## 1. Temario de referencia (prueba A1, Madrid)
<!-- Fuente oficial citada: pendiente de la dirección -->

### Bloques y prioridad (catálogo v1)

La prioridad va de 1 (★) a 3 (★★★). Los bloques ★★★ entran en el diagnóstico. **Las prioridades actuales son provisionales (D-029)** y debe confirmarlas la dirección.

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

## 3. Registro de procedencia

| ID | Tipo | Autoría u origen | Licencia | Fecha |
|---|---|---|---|---|
| 10 ítems, 2 tarjetas y SIM.01 de prueba (Fase 04) | original | Claude Code, solo para tests (estado `borrador`) | propia | 2026-11-23 |

## 4. Proceso de revisión y calidad

`borrador` → `revisado` → `aprobado` (con revisor y fecha). Solo lo aprobado llega a Release. El test «Todo el contenido del bundle pasa el validador» se ejecuta en cada verificación de fase.
