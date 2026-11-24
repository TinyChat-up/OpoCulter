# Correcciones del texto extraído (Modo Tribunal)

Los enunciados de `Educulter/Content/pendiente/tribunal/*.json` se copian de `docs/examenes/texto/*.txt`, que se obtuvo de la capa de texto del PDF o, si no la había, por OCR (D-067). Cada enunciado se ha cotejado con el PDF oficial de `docs/examenes/oficiales/`; donde el texto no era fiable, se ha consultado la imagen de la página (`pdftoppm`). Los `.txt` se conservan sin tocar. Abajo se registra cada diferencia entre el `.txt` y el JSON. Revisado por Claude Code el 24/11/2026.

## 1. Errores evidentes del OCR (2026 ordinaria, cuadernillo procesado entero con OCR)

| Pregunta | Texto extraído | En el PDF (y en el JSON) |
|---|---|---|
| L6 | «pronomore» | «pronombre» |
| L6 | «el numero» | «el número» |
| M7 | «Tómese T = 3,14» | «Tómese π = 3,14» |
| M8 | Columnas «2, 5, 10, 9» | Columnas **2, 3, 5, 9 y 10**: el OCR omitió la columna «3» y desordenó las demás |
| M4, M5, M9, M10 | Celdas de las tablas desordenadas | Tablas reconstruidas a partir de la imagen (ver §3) |
| M7 | Cotas sueltas («-4m-», «r=2m», «3m», «-10m»); falta «8m» | Figura descrita con todas sus cotas (ver §4) |
| M2 | Letras sueltas «A», «C» | Restos del maquetado: no forman parte del enunciado |
| Instrucción 9 | «abandonar la sala.» (renglón cortado) | No se usa: las instrucciones generales no se copian al JSON |

## 2. Capa de texto: símbolos, partición de palabras y fórmulas en imagen

| Examen | Pregunta | Texto extraído | En el JSON |
|---|---|---|---|
| 2017 O | Texto base | Palabras partidas a final de renglón («des-/de», «mag-/níficos», «bre-/ñas») | Unidas («desde», «magníficos», «breñas»). Los renglones se unen en sus párrafos originales |
| 2017 O | M9 | «m2», «dm3» | «m²», «dm³» (superíndices perdidos en la extracción) |
| 2017 O | M9 | Casillas en blanco sin marca | Se marca cada hueco con «___» |
| 2019 O | M1 | Fracciones en imagen (no se extraen) | Transcritas de la imagen: a) 4/5 + 2/10 + 2/15 − 2/5; b) 3/4 + 2/6 − 3/12; c) 4/9 + 2/6 − 2/5; d) 2/6 + 6/12 + 7/6 − 2/3 |
| 2019 O | M2 | Casillas en blanco sin marca | Se marca cada hueco con «___» |
| 2022 O | M8 | «7 × 103», «34 × 107», «29 × 10 = 290.000», «× 106», «× 105» | 7 × 10³, 34 × 10⁷, 29 × 10^___, × 10⁶, × 10⁵ (exponentes perdidos; las casillas de exponente se marcan con «^___») |
| 2022 O | M4 | Casillas en blanco sin marca | Se marca cada hueco con «___» |
| 2024 O | M1 | «2 / 3 de 29,1 1,904 · 10 22 + 42 – 0,56 58,26 / 3» | 2/3 de 29,1 · 1,904 · 10 · 2² + 4² – 0,56 · 58,26/3 (superíndices y fracciones de la imagen; «1,904 · 10» no lleva exponente en el PDF) |
| 2024 O | M2 | Operación en imagen (no se extrae) | [3/5 + 1/4 × 2/3] : [(1 + 1/5) × 16/4] |
| 2024 O | L6 y L7 | Números «6. 7.» fuera de lugar | Cada enunciado con su número |
| 2019 A | M3 | «23 a = 9591» | Igual: el PDF no lleva signo de multiplicación (producto implícito) |

## 3. Tablas transcritas en línea

Las tablas de los cuadernillos se copian como texto entre paréntesis, con todas sus celdas y en el mismo orden (filas y columnas). Afecta a: 2019 O M6 y M7; 2019 A M6 y M8; 2022 O M7; 2026 O L7, L9, M4, M5, M8, M9 y M10; 2026 A L4, L7, L8, L9 y M6. Los encabezados «Palabra / Prefijo / Significado del prefijo», «Opción con hueco / Opción correcta / Explicación», etc., se separan con « / ».

## 4. Figuras descritas

Las figuras no son texto: se describen entre corchetes con todas sus cotas, leídas en la imagen ampliada.

| Examen | Pregunta | Descripción |
|---|---|---|
| 2022 O | M5 | Fachada: rectángulo de 12 m × 8,5 m; encima, rectángulo de 4 m × 3 m rematado por un triángulo de 4 m de base y 2,5 m de altura |
| 2022 O | M10 | Tres ortoedros apilados: c = 0,1 dm, b = 2 cm, a = 80 mm; d = 0,3 dm, e = 2,5 cm, f = 0,09 m; g = 0,0012 hm, i = 11 cm, h = 30 mm. La figura no deja claro qué cota es alto y cuál fondo en cada bloque, pero el volumen no depende de ello |
| 2024 O | M7 | A: prisma de base cuadrada de 130 mm de lado y 22 cm de alto. B: prisma pentagonal de 12,5 cm de lado, 85,7 mm de apotema y 120 mm de alto |
| 2026 O | M7 | Zona en L de 10 m de ancho; parte izquierda de 8 m de alto; a la derecha, rectángulo de 4 m × 3 m; círculo sombreado de r = 2 m |

## 5. Textos protegidos (no se reproducen)

En 2019 O (Salinas) y 2019 A (Laforet), los enunciados que citan versos o frases del texto base (2019 O L3 y L5; 2019 A L2) sustituyen la cita por «[Cita del texto base protegido: consúltese en el PDF oficial]». El resto del enunciado es literal. `scripts/validar_tribunal.py` comprueba que no se cuele ninguna cita.

## 6. Pregunta anulada

2022 O L7 se copia con la nota oficial «ANULADA. Advertido error en el enunciado de la pregunta se procede a anularla, no siendo tenida en cuenta a efectos de puntuación.» y vale 0 puntos (`"anulada": true`).
