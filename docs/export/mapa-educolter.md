# Mapa del contenido de Educulter

Exportación de solo lectura del contenido real de la app (nombre en clave «Educulter»). Commit de `main`: `44b212994028efa16b660cd10a8b4eda56fe0ab3` (Fusiona fase-05e/identidad-sesion en main). Datos completos en [`banco-educolter.json`](banco-educolter.json). «No documentado» significa que el dato no está en el repositorio.

Estados: **enUso** = lo sirve hoy la app en Release · **prueba** = borradores de prueba de las Fases 04–05C, solo Debug y tests · **pendiente** = `Content/pendiente/`, la app no lo carga · **borrador** = otro borrador · **histórico** = en el repositorio pero no integrado (no hay ninguno).

## 1. La app y la prueba A1

- App nativa de iPhone para preparar la prueba común A1 (Lengua Castellana y Literatura + Matemáticas) de las oposiciones de Maestros de la Comunidad de Madrid (CLAUDE.md).
- La prueba tiene 10 preguntas de Lengua y 10 de Matemáticas, dura hora y media, es sin calculadora, las faltas de ortografía restan puntos y cada pregunta se corrige con 1, 0,5 o 0 (CONTEXTO.md).
- Lengua parte siempre de un texto literario (comentario) y termina siempre con un análisis sintáctico de oración simple; Matemáticas mezcla cálculo puro con problemas de contexto (docs/examenes/MATRIZ.md §4).
- La app enseña en rondas cortas de 2 a 5 minutos, táctiles y sin teclado del sistema (tocar, arrastrar, construir con piezas y teclado numérico propio), con cuatro modos sobre el mismo motor: Camino, Supervivencia, Rescate y Tribunal (CLAUDE.md, docs/MISION_PREMIUM.md).
- El Modo Tribunal reproducirá los 7 exámenes oficiales publicados (139 preguntas) con respuesta en papel y autocorrección con la rúbrica; hoy sus datos están en `Content/pendiente/tribunal/` y la baldosa dice «Próximamente» (CONTEXTO.md, CONTENIDOS §2.15, D-111).

## 2. Recuentos

Preguntas fijas exportadas: **274** = 133 ítems estáticos + 139 preguntas oficiales + 2 del simulacro de prueba. Por estado: prueba 27, enUso 108, pendiente 139. Las preguntas generadas por plantilla no se cuentan aquí (ver §5 y el catálogo en Release).

### 2.1 Por tema (bloque y competencia)

| Bloque | Nombre | enUso | borrador | pendiente | prueba | historico | Total |
|---|---|---|---|---|---|---|---|
| LEN.SIN | Sintaxis | 0 | 0 | 7 | 4 | 0 | 11 |
| LEN.ORT | Ortografía y tildes | 50 | 0 | 4 | 0 | 0 | 54 |
| LEN.CLA | Clases de palabras | 0 | 0 | 5 | 3 | 0 | 8 |
| LEN.VER | Formas verbales | 0 | 0 | 6 | 2 | 0 | 8 |
| LEN.LIT | Autores y épocas | 0 | 0 | 13 | 2 | 0 | 15 |
| LEN.COM | Comunicación y comprensión | 19 | 0 | 13 | 0 | 0 | 32 |
| LEN.REC | Recursos literarios | 0 | 0 | 6 | 1 | 0 | 7 |
| LEN.MET | Métrica | 0 | 0 | 1 | 0 | 0 | 1 |
| LEN.LEX | Léxico y vocabulario | 30 | 0 | 10 | 1 | 0 | 41 |
| LEN.FOR | Formación de palabras | 0 | 0 | 4 | 0 | 0 | 4 |
| MAT.UNI | Unidades y medida | 0 | 0 | 8 | 2 | 0 | 10 |
| MAT.GEO | Geometría | 0 | 0 | 11 | 2 | 0 | 13 |
| MAT.POR | Porcentajes y proporcionalidad | 0 | 0 | 7 | 2 | 0 | 9 |
| MAT.NUM | Fracciones y decimales | 9 | 0 | 14 | 0 | 0 | 23 |
| MAT.DIV | Divisibilidad (m.c.m./m.c.d.) | 0 | 0 | 4 | 1 | 0 | 5 |
| MAT.OPE | Operaciones combinadas y ecuaciones | 0 | 0 | 11 | 6 | 0 | 17 |
| MAT.ROM | Números romanos | 0 | 0 | 4 | 1 | 0 | 5 |
| MAT.EST | Estadística | 0 | 0 | 7 | 0 | 0 | 7 |
| MAT.PRO | Probabilidad | 0 | 0 | 4 | 0 | 0 | 4 |

Por competencia (solo las que tienen preguntas fijas; la competencia de las oficiales es la del mapa según `equivalencias.json`):

| Competencia | Nombre | enUso | borrador | pendiente | prueba | historico | Total |
|---|---|---|---|---|---|---|---|
| LEN.SIN.COMPL | Complementos del verbo | 0 | 0 | 6 | 1 | 0 | 7 |
| LEN.SIN.SUJPRED | Sujeto y predicado | 0 | 0 | 1 | 3 | 0 | 4 |
| LEN.ORT.AGU | Agudas, llanas y esdrújulas | 21 | 0 | 1 | 0 | 0 | 22 |
| LEN.ORT.DIA | Tilde diacrítica | 9 | 0 | 2 | 0 | 0 | 11 |
| LEN.ORT.HIA | Diptongo, hiato y tilde | 6 | 0 | 0 | 0 | 0 | 6 |
| LEN.ORT.HOM | Homófonos frecuentes | 8 | 0 | 1 | 0 | 0 | 9 |
| LEN.ORT.PQ | Por qué, porque, porqué y por que | 6 | 0 | 0 | 0 | 0 | 6 |
| LEN.CLA.ADJGRAD | Grados del adjetivo | 0 | 0 | 2 | 0 | 0 | 2 |
| LEN.CLA.JUST | Justificar la categoría | 0 | 0 | 1 | 0 | 0 | 1 |
| LEN.CLA.SUSTADJ | Sustantivo y adjetivo | 0 | 0 | 0 | 2 | 0 | 2 |
| LEN.CLA.VAR | Palabras variables | 0 | 0 | 2 | 0 | 0 | 2 |
| LEN.CLA.VERBO | El verbo | 0 | 0 | 0 | 1 | 0 | 1 |
| LEN.VER.ANALISIS | Análisis de formas verbales | 0 | 0 | 5 | 2 | 0 | 7 |
| LEN.VER.IRREG | Verbos irregulares | 0 | 0 | 1 | 0 | 0 | 1 |
| LEN.LIT.AUTOBRA | Autor y obra | 0 | 0 | 0 | 1 | 0 | 1 |
| LEN.LIT.CRONO | Cronología de autores | 0 | 0 | 0 | 1 | 0 | 1 |
| LEN.LIT.HIST | Historia de la literatura española | 0 | 0 | 13 | 0 | 0 | 13 |
| LEN.COM.GEN | Géneros discursivos | 1 | 0 | 0 | 0 | 0 | 1 |
| LEN.COM.INFER | Inferencias y sentido | 3 | 0 | 4 | 0 | 0 | 7 |
| LEN.COM.PROP | Coherencia, cohesión y adecuación | 2 | 0 | 0 | 0 | 0 | 2 |
| LEN.COM.RESU | El resumen | 4 | 0 | 7 | 0 | 0 | 11 |
| LEN.COM.SITU | Elementos de la comunicación | 1 | 0 | 0 | 0 | 0 | 1 |
| LEN.COM.TEMA | Tema e idea principal | 4 | 0 | 0 | 0 | 0 | 4 |
| LEN.COM.TIPO | Tipos de texto | 4 | 0 | 2 | 0 | 0 | 6 |
| LEN.REC.DEF | Definir recursos literarios | 0 | 0 | 4 | 0 | 0 | 4 |
| LEN.REC.FIG | Identificar recursos literarios | 0 | 0 | 2 | 0 | 0 | 2 |
| LEN.REC.FIGURAS | Figuras retóricas | 0 | 0 | 0 | 1 | 0 | 1 |
| LEN.MET.MED | Medida del verso | 0 | 0 | 1 | 0 | 0 | 1 |
| LEN.LEX.CAMPO | Campo semántico y familia léxica | 5 | 0 | 1 | 0 | 0 | 6 |
| LEN.LEX.CTX | Significado en contexto | 3 | 0 | 4 | 0 | 0 | 7 |
| LEN.LEX.DEN | Denotación y connotación | 1 | 0 | 0 | 0 | 0 | 1 |
| LEN.LEX.DICC | El diccionario | 5 | 0 | 2 | 0 | 0 | 7 |
| LEN.LEX.FRAS | Frases hechas | 1 | 0 | 0 | 0 | 0 | 1 |
| LEN.LEX.POLI | Polisemia, homonimia y paronimia | 6 | 0 | 1 | 0 | 0 | 7 |
| LEN.LEX.REG | Registros, préstamos y extranjerismos | 2 | 0 | 1 | 0 | 0 | 3 |
| LEN.LEX.SIN | Sinónimos y antónimos | 7 | 0 | 1 | 0 | 0 | 8 |
| LEN.LEX.SINON | Sinónimos | 0 | 0 | 0 | 1 | 0 | 1 |
| LEN.FOR.CLAS | Primitivas, derivadas, compuestas y parasintéticas | 0 | 0 | 1 | 0 | 0 | 1 |
| LEN.FOR.DER | Prefijos y sufijos | 0 | 0 | 3 | 0 | 0 | 3 |
| MAT.UNI.ESC | Escalas | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.UNI.LMC | Longitud, masa y capacidad | 0 | 0 | 4 | 0 | 0 | 4 |
| MAT.UNI.LONG | Unidades de longitud | 0 | 0 | 0 | 2 | 0 | 2 |
| MAT.UNI.TIEM | Tiempo y sistema sexagesimal | 0 | 0 | 3 | 0 | 0 | 3 |
| MAT.GEO.ANG | Ángulos | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.GEO.AREA | Áreas | 0 | 0 | 4 | 0 | 0 | 4 |
| MAT.GEO.CART | Coordenadas cartesianas | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.GEO.TRIANG | Propiedades del triángulo | 0 | 0 | 0 | 2 | 0 | 2 |
| MAT.GEO.VOL | Volúmenes | 0 | 0 | 5 | 0 | 0 | 5 |
| MAT.POR.CALC | Tanto por ciento de una cantidad | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.POR.PORCENT | Porcentajes | 0 | 0 | 0 | 2 | 0 | 2 |
| MAT.POR.PROP | Proporcionalidad directa | 0 | 0 | 4 | 0 | 0 | 4 |
| MAT.POR.VAR | Aumentos y descuentos porcentuales | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.NUM.EQUIV | Fracción, decimal y porcentaje | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.NUM.FRAEQ | Fracciones equivalentes | 5 | 0 | 1 | 0 | 0 | 6 |
| MAT.NUM.FRAOP | Operaciones con fracciones | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.NUM.FRAPROB | Problemas con fracciones | 0 | 0 | 3 | 0 | 0 | 3 |
| MAT.NUM.FRAREP | Representar fracciones | 4 | 0 | 0 | 0 | 0 | 4 |
| MAT.NUM.ORDEN | Ordenar fracciones y decimales | 0 | 0 | 6 | 0 | 0 | 6 |
| MAT.NUM.VALPOS | Valor posicional y redondeo | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.DIV.MCD | Máximo común divisor | 0 | 0 | 1 | 1 | 0 | 2 |
| MAT.DIV.MCM | Mínimo común múltiplo | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.DIV.REGLAS | Criterios de divisibilidad | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.OPE.COMB | Operaciones combinadas con paréntesis y corchetes | 0 | 0 | 4 | 0 | 0 | 4 |
| MAT.OPE.EQUIV | Fracciones y decimales equivalentes | 0 | 0 | 0 | 2 | 0 | 2 |
| MAT.OPE.FRACSUM | Suma de fracciones | 0 | 0 | 0 | 2 | 0 | 2 |
| MAT.OPE.INCOG | Término desconocido | 0 | 0 | 4 | 0 | 0 | 4 |
| MAT.OPE.JER | Jerarquía de las operaciones | 0 | 0 | 1 | 0 | 0 | 1 |
| MAT.OPE.JERARQ | Jerarquía de operaciones | 0 | 0 | 0 | 2 | 0 | 2 |
| MAT.OPE.POT | Potencias | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.ROM.ESCR | Escribir números romanos | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.ROM.LECTURA | Lectura de números romanos | 0 | 0 | 0 | 1 | 0 | 1 |
| MAT.ROM.LEER | Leer números romanos | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.EST.CENTRAL | Media, mediana, moda y rango | 0 | 0 | 5 | 0 | 0 | 5 |
| MAT.EST.FREC | Frecuencias absolutas y relativas | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.PRO.LAPLACE | Probabilidad de un suceso | 0 | 0 | 2 | 0 | 0 | 2 |
| MAT.PRO.SUCESOS | Tipos de sucesos | 0 | 0 | 2 | 0 | 0 | 2 |

### 2.2 Por formato

Mecánica de la app (ítems estáticos y simulacro):

| Mecánica | enUso | borrador | pendiente | prueba | historico | Total |
|---|---|---|---|---|---|---|
| clasificar | 9 | 0 | 0 | 2 | 0 | 11 |
| colocarTilde | 12 | 0 | 0 | 0 | 0 | 12 |
| construir | 15 | 0 | 0 | 1 | 0 | 16 |
| eleccion | 39 | 0 | 0 | 3 | 0 | 42 |
| emparejar | 11 | 0 | 0 | 3 | 0 | 14 |
| fraccionBarras | 8 | 0 | 0 | 0 | 0 | 8 |
| marcarTexto | 4 | 0 | 0 | 1 | 0 | 5 |
| numerico | 0 | 0 | 0 | 3 | 0 | 3 |
| ordenar | 4 | 0 | 0 | 3 | 0 | 7 |
| ruedas | 0 | 0 | 0 | 3 | 0 | 3 |
| segmentar | 0 | 0 | 0 | 3 | 0 | 3 |
| simulacro | 0 | 0 | 0 | 2 | 0 | 2 |
| tribunal (sin mecánica en la app) | 0 | 0 | 139 | 0 | 0 | 139 |
| verdaderoFalso | 6 | 0 | 0 | 3 | 0 | 9 |

Plantillas aprobadas por mecánica (cada una genera muchas preguntas): numerico 28, eleccion 17, ordenar 8, clasificar 8, ruedas 7, marcarTexto 4, construir 4, emparejar 3, colocarTilde 2, segmentar 2.

Formato del examen (tipo de tarea de `docs/examenes/MATRIZ.md`; las 139 preguntas oficiales están en estado `pendiente`): ver la tabla de §3.

### 2.3 Cruce con las fuentes

| Dato | Exportado | Fuente | Diferencia y causa |
|---|---|---|---|
| Ítems estáticos (todos, Debug) | 133 | 133 (`ContenidoTests`: `numeroEstaticos == 133`) | 0 |
| Ítems estáticos en Release (enUso) | 108 | 108 (`ContenidoTests`; CONTENIDOS «Recuperación»; AUDITORIA §4) | 0 |
| · LEN.ORT / LEN.LEX / LEN.COM / MAT.NUM en Release | 50 / 30 / 19 / 9 | 50 / 30 / 19 / 9 (`ContenidoTests`) | 0 |
| Ítems de comprensión con texto base | 13 | 13 de 19 (CONTENIDOS «Recuperación») | 0 |
| Mecánicas de los estáticos en Release | eleccion 39, construir 15, clasificar 9, ordenar 4, emparejar 11, marcarTexto 4, colocarTilde 12, verdaderoFalso 6, fraccionBarras 8 | AUDITORIA §1: eleccion 39, construir 15, clasificar 9, ordenar 4, emparejar 11, marcarTexto 4, colocarTilde 12, verdaderoFalso 6, fraccionBarras 8 | 0 |
| Preguntas oficiales | 139 | 139 = 69 L + 70 M (CONTENIDOS §5; MATRIZ §1; `equivalencias.json`) | 0 (69 L + 70 M; 1 anulada: 2022 O L7) |
| Preguntas del simulacro de prueba | 2 | SIM.01 (`ContenidoTests`: 1 simulacro) | 0 |
| Plantillas (todas / aprobadas / borrador) | 88 / 83 / 5 | 88 / 83 (`ContenidoTests`) / 5 (D-101). CONTENIDOS «05E parte 1» dice «Release carga 79» | **+4 frente a CONTENIDOS**: MAT.DIV.MCD.G01, MAT.EST.CENTRAL.G01, MAT.PRO.LAPLACE.G01 y MAT.OPE.INCOG.G02 se aprobaron en la parte 2 (D-101) y CONTENIDOS no actualizó la cifra; `ContenidoTests` sí |
| Tipos de generador | 24 | 23 (AUDITORIA §1) + `terminoDesconocido` (D-100) = 24 | 0 |
| Tarjetas de teoría (todas / Release) | 26 / 24 | 26 / 24 (`ContenidoTests`: «15 + las 9 del ANEXO B») | 0 (AUDITORIA §1 dice 15 aprobadas: es anterior al ANEXO B, D-102) |
| Errores típicos | 93 | 93 en 34 competencias (CONTENIDOS «05E parte 2», D-107) | 0 (34 competencias) |
| Distractores estáticos en Release etiquetados / sin etiquetar | 44 / 13 | 44 / 13 (CONTENIDOS, D-113) | 0 (mismos 13 ids) |
| Equivalencias: entrena sí / parcial / no | 56 / 40 / 43 | ESTADO y AUDITORIA §3: sí 33,1 % (46) y sí + parcial 63,3 % (88) | **+10 «sí» y +8 «sí + parcial»** (40,3 % y 69,1 %; antes, 46 / 42 / 51): el commit d082bb8 («05E parte 2 · ajustes 1b») regeneró `equivalencias.json` al aprobar MCD, CENTRAL, LAPLACE e INCOG.G02 y cambiar la sintaxis (D-098, D-100, D-101); la documentación conserva la cifra de la parte 1 |
| Anclas (total / reproducidas en el nivel 4) | 67 / 45 | 67 / 39 (ESTADO, D-096) | **+6 reproducidas**: el mismo commit d082bb8 (4 de término desconocido, D-100, y 2 de sintaxis, D-098) |
| Textos base de la app | 5 | 5 (`ContenidoTests`, D-085) | 0 |
| Competencias del catálogo | 125 | 125 (`ContenidoTests`; MAPA_CURRICULAR_A1: 111 del mapa + INCOG + 13 antiguas) | 0 |
| Catálogo de preguntas en Release | no recalculado (requiere el Mac) | ≥ 230 813 (ESTADO, 05E parte 1) | Cifra anterior a la parte 2 (no incluye las 4 plantillas aprobadas en D-101 ni D-098) |

## 3. Tipos de pregunta del examen oficial

Tipo de tarea según `docs/examenes/MATRIZ.md`. «Entrena» según `Content/tribunal/equivalencias.json`: **sí** = contenido aprobado que ejercita la misma destreza; **parcial** = hay contenido de la competencia, pero el examen pide redactar, definir o justificar y la app pide reconocer, o faltan rasgos; **no** = sin contenido aprobado o sin esa destreza. La última columna copia literalmente las notas de `equivalencias.json` de ese tipo (lo que la app no cubre y hay que seguir practicando por escrito).

| Área | Tipo de tarea | Preguntas | ¿Lo entrena? | sí/parcial/no | Notas de equivalencias.json (qué falta) |
|---|---|---|---|---|---|
| Lengua | Análisis sintáctico | 7 | en parte | 4/3/0 | S + V + CCM + CCL (nivel 5 de oracionSimple). · Complemento predicativo: no se genera. · Verbo semicopulativo con predicativo: no se genera. · Complemento del nombre: no se genera. · S + V + CD + CI (nivel 5). · S + V + CD + CCL. |
| Lengua | Resumen y tema | 7 | en parte | 0/7/0 | Redactar un resumen; la app pide reconocer el mejor resumen. · Resumir y comentar. · Tema y comentario de un poema. |
| Lengua | Análisis de formas verbales | 5 | en parte | 3/2/0 | Formas regulares. · Oí y era son irregulares (fuera del generador). · Sonrío es irregular; perdiste y hundiré, regulares. · Es, estuvieras y visto son irregulares. |
| Lengua | Definir términos | 5 | en parte | 0/1/4 | Provisional LEN.LEX.CONCEPTOS: definir neologismo, arcaísmo, eufemismo, morfema y acrónimo; no hay contenido de esos conceptos. · Definir la metáfora. · Definir metáfora, homónimas, verso libre y comparación. · Explicar qué es un diccionario. · Narrador, novela, hipérbole y adjetivo. |
| Lengua | Formación de palabras | 4 | no | 0/0/4 | Provisional LEN.FOR.DERIV. · Primitivas, derivadas y compuestas. · Prefijos y su significado. |
| Lengua | Vocabulario en contexto | 4 | en parte | 0/4/0 | Explicar el significado; la app pide elegirlo. · Explicar el significado. · Definir palabras. |
| Lengua | Autor y contexto | 3 | en parte | 0/3/0 | Autor y contexto histórico. · Autor, Generación del 27 y rasgos. · Contextualizar el fragmento y nombrar obra y autor. |
| Lengua | Citar autores de un grupo | 3 | en parte | 0/3/0 | Citar autores (recuerdo libre); la app pide relacionar y ordenar. · Citar autores. |
| Lengua | Cronología de autores | 3 | sí | 3/0/0 | Ordenar autores por época. · Ordenar autores. |
| Lengua | Sentido de una frase | 3 | en parte | 0/3/0 | Comentar el sentido de una frase. |
| Lengua | Grados del adjetivo | 2 | no | 0/0/2 | Grados del adjetivo (antes LEN.CLA.SUSTADJ). |
| Lengua | Identificar figura retórica | 2 | no | 0/0/2 | Antes LEN.REC.FIGURAS. · También métrica. |
| Lengua | Movimiento/época | 2 | en parte | 1/1/0 | Movimiento de un texto por sus rasgos; la app pregunta el movimiento de una obra por su título. · Generación del autor: la app pregunta el movimiento de sus obras. |
| Lengua | Rasgos de un movimiento | 2 | no | 0/0/2 | Provisional LEN.LIT.MOVIM: rasgos del movimiento; no hay preguntas sobre rasgos. · Corrientes del Barroco (culteranismo y conceptismo): no hay contenido. |
| Lengua | Relacionar término y definición | 2 | no | 0/0/2 | Relacionar término y definición. · Clases de palabras por su definición. |
| Lengua | Tilde diacrítica | 2 | en parte | 1/1/0 | Explicar la diferencia entre si y sí; la app pide elegir la forma. · Elegir entre dos formas con tilde diacrítica. |
| Lengua | Tipología textual | 2 | en parte | 0/2/0 | Identificar el tipo y enumerar características. |
| Lengua | Análisis morfológico | 1 | no | 0/0/1 | Análisis morfológico (antes LEN.CLA.VERBO). |
| Lengua | Clases de palabras | 1 | no | 0/0/1 | Clase de palabra con justificación (antes LEN.CLA.SUSTADJ). |
| Lengua | Colocar tildes en un texto | 1 | en parte | 0/1/0 | Tildes en un texto con contexto: la app trabaja palabras y frases sueltas. |
| Lengua | Contexto histórico | 1 | en parte | 0/1/0 | Provisional LEN.LIT.CONTEXTO: inferir la época de la historia a partir del texto. |
| Lengua | Homófonos y diacríticas | 1 | sí | 1/0/0 | Elegir la forma en frases con hueco. |
| Lengua | Léxico (familia, campo, sinónimos) | 1 | en parte | 0/1/0 | Escribir palabras de la familia y del campo; también LEN.LEX.SIN. |
| Lengua | Métrica | 1 | no | 0/0/1 | Provisional LEN.MET.MEDIDA. |
| Lengua | Palabra por definición | 1 | en parte | 0/1/0 | Provisional LEN.LEX.DEFIN: escribir la palabra de una definición. |
| Lengua | Polisemia | 1 | en parte | 0/1/0 | Explicar dos acepciones. |
| Lengua | Sinónimos y antónimos | 1 | en parte | 0/1/0 | Escribir sinónimos y antónimos; la app pide elegirlos. |
| Lengua | Uso normativo | 1 | no | 0/0/1 | Provisional LEN.VER.NORMA (anduve/andé). |
| Matemáticas | Medidas de centralización | 5 | en parte | 3/2/0 | Media, mediana y rango de 5 datos. · Media, moda y rango de 5 datos. · Tabla de frecuencias con decimales: el generador da listas de datos. · 30 datos: el generador usa de 5 a 8. · Media, mediana, moda y rango de 6 datos. |
| Matemáticas | Ordenar números | 5 | en parte | 4/1/0 | Hay que calcular expresiones antes de ordenar. |
| Matemáticas | Conversión de unidades | 4 | sí | 4/0/0 | Provisional MAT.UNI.CONV (incluye ha y dm³: SUP y VOL también aprobadas). · Suma de cantidades complejas (nivel 5). · Antes MAT.UNI.LONG. |
| Matemáticas | Operación combinada | 4 | sí | 4/0/0 | Antes MAT.OPE.JERARQ. · Con llaves (nivel 5). |
| Matemáticas | Término desconocido | 4 | sí | 4/0/0 | Provisional MAT.OPE.INCOG: término desconocido (D-100). |
| Matemáticas | Áreas compuestas | 4 | no | 0/0/4 | Provisional MAT.GEO.AREAS. |
| Matemáticas | Operaciones con fracciones | 3 | sí | 3/0/0 | Antes MAT.OPE.FRACSUM. · Combinada con corchetes (nivel 6). · Fracción del resto (antes MAT.OPE.FRACSUM). |
| Matemáticas | Sistema sexagesimal | 3 | sí | 3/0/0 | Provisional MAT.UNI.TIEMPO. |
| Matemáticas | Volumen y capacidad | 3 | no | 0/0/3 | Provisional MAT.UNI.VOLCAP: el paso a litros se practica en MAT.UNI.VOL, pero el volumen del prisma no. · El paso de m³ a litros se practica en MAT.UNI.VOL, pero el volumen del prisma no. |
| Matemáticas | Arábigo → romano | 2 | sí | 2/0/0 | Provisional MAT.ROM.ESCRITURA. |
| Matemáticas | Fracción de lo que queda | 2 | sí | 2/0/0 | Provisional MAT.NUM.FRACDE. |
| Matemáticas | Porcentaje de una cantidad | 2 | sí | 2/0/0 | — |
| Matemáticas | Probabilidad de Laplace | 2 | sí | 2/0/0 | Sucesos con 10 bolas numeradas. · Sucesos con 12 tarjetas. |
| Matemáticas | Proporcionalidad directa | 2 | sí | 2/0/0 | Provisional MAT.POR.PROPORC. |
| Matemáticas | Romano → arábigo | 2 | sí | 2/0/0 | Antes MAT.ROM.LECTURA. |
| Matemáticas | Tabla de frecuencias | 2 | no | 0/0/2 | Provisional MAT.EST.FRECUENCIAS. |
| Matemáticas | Volumen de cuerpos | 2 | no | 0/0/2 | Provisional MAT.GEO.VOLUMEN. |
| Matemáticas | m.c.m. en contexto | 2 | no | 0/0/2 | Provisional MAT.DIV.MCM: sin plantilla aprobada. |
| Matemáticas | Aumentos y descuentos | 1 | sí | 1/0/0 | Rebaja porcentual (antes MAT.POR.PORCENT). |
| Matemáticas | Comparar fracciones | 1 | sí | 1/0/0 | — |
| Matemáticas | Conceptos de probabilidad | 1 | no | 0/0/1 | Provisional MAT.PRO.CONCEPTOS. |
| Matemáticas | Coordenadas cartesianas | 1 | no | 0/0/1 | Provisional MAT.GEO.COORD. |
| Matemáticas | Criterios de divisibilidad | 1 | no | 0/0/1 | Provisional MAT.DIV.CRITERIOS. |
| Matemáticas | Decimal ↔ fracción | 1 | no | 0/0/1 | Antes MAT.OPE.EQUIV. |
| Matemáticas | Escalas | 1 | sí | 1/0/0 | Provisional MAT.POR.ESCALAS. |
| Matemáticas | Fracciones equivalentes | 1 | sí | 1/0/0 | — |
| Matemáticas | Operaciones con decimales | 1 | en parte | 0/1/0 | Jerarquía con decimales: el generador solo usa naturales. |
| Matemáticas | Potencias | 1 | no | 0/0/1 | Provisional MAT.NUM.POT10. |
| Matemáticas | Potencias de 10 | 1 | no | 0/0/1 | Provisional MAT.NUM.POT10. |
| Matemáticas | Precio unitario | 1 | sí | 1/0/0 | Reducción a la unidad con decimales. |
| Matemáticas | Probabilidad experimental | 1 | no | 0/0/1 | Probabilidad estimada por la frecuencia relativa. |
| Matemáticas | Proporcionalidad inversa / trabajo conjunto | 1 | no | 0/0/1 | Trabajo conjunto (proporcionalidad inversa): no se genera. |
| Matemáticas | Valor posicional | 1 | no | 0/0/1 | Provisional MAT.NUM.DESCOMP. |
| Matemáticas | m.c.d. en contexto | 1 | sí | 1/0/0 | m.c.d. de tres números en un reparto (plantilla aprobada en la 05E parte 2). |
| Matemáticas | Ángulos | 1 | no | 0/0/1 | Provisional MAT.GEO.ANGULOS. |

## 4. Ejemplos oficiales por tipo

Enunciados literales de los cuadernillos oficiales de la Comunidad de Madrid (fuente y fecha de extracción en cada examen, §4.0). Todas las preguntas oficiales son «nivel examen» (dificultad 4 en la escala de D-096); cuando `anclas.json` dice que un generador necesita un nivel superior para reproducirla, se indica. Las soluciones modelo no son oficiales (`fuenteSolucion: direccion`): las redactó Claude Code y las aprobó la dirección el 24/11/2026 (CONTENIDOS §3 y §5). Las rúbricas de 2026 son las plantillas oficiales copiadas literalmente; las de 2017–2024 son de redacción propia según ese modelo.

### 4.0 Fuentes de los exámenes

| Examen | Fuente | Extracción |
|---|---|---|
| OF.2017.O | https://www.comunidad.madrid/docs/assets/2019/11/14/edu_rrhh_0371_2017_examen_comun.pdf | 2026-11-23 |
| OF.2019.A | https://www.comunidad.madrid/docs/assets/2019/11/15/edu_rrhh_0371_2019_examen_prueba_comun_aplazada.pdf | 2026-11-23 |
| OF.2019.O | https://www.comunidad.madrid/docs/assets/2019/11/15/edu_rrhh_0371_2019_examen_prueba_comun.pdf | 2026-11-23 |
| OF.2022.O | https://www.comunidad.madrid/docs/assets/2022/06/18/rh02_2122_prueba_comun.pdf | 2026-11-23 |
| OF.2024.O | https://www.comunidad.madrid/docs/assets/2024/06/22/rh02_2324_prueba_comun.pdf | 2026-11-23 |
| OF.2026.A | https://www.comunidad.madrid/docs/2026-06/rh02_opo_prueba_comun_aplazada.pdf · plantilla: https://www.comunidad.madrid/docs/2026-08/rh02_plantillas-prueba_comun_aplazada_26.pdf | 2026-11-23 |
| OF.2026.O | https://sede.comunidad.madrid/medias/examenes20261zip/download · plantilla: https://www.comunidad.madrid/docs/2026-08/rh02_plantillas_prueba_comun_ordinaria_26.pdf | 2026-11-23 |

Condiciones: reproducción sin alterar el contenido, citando la fuente y la fecha; la app no está patrocinada ni avalada por la Comunidad de Madrid (docs/examenes/FUENTES.md §2). Textos protegidos (Salinas, 2019 O; Laforet, 2019 A): no se reproducen; se remite al PDF oficial.

### 4.1 Lengua · Análisis sintáctico (7 en los exámenes)

**OF.2017.O-L9** · LEN.SIN.COMPL Complementos del verbo · entrena: si · ancla: plantilla `LEN.SIN.COMPL.G07`, nivel que la reproduce 5 (**difícil**: por encima del nivel 4) — Intransitivo con dos CC: nivel 5.

> Analice sintácticamente la siguiente oración:
> “El gato maullaba tristemente en la ventana”

- Soporte: el cuadernillo parte del texto de Gustavo Adolfo Bécquer, *El monte de las ánimas* (`textosBase` · `OF.2017.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Oración simple, enunciativa afirmativa, predicativa, intransitiva y activa. Sujeto: «El gato» (SN: Det «El» + N «gato»). Predicado verbal: «maullaba tristemente en la ventana» (SV): N «maullaba»; CCM «tristemente» (SAdv); CCL «en la ventana» (SPrep: E «en» + término SN «la ventana»).
- Criterio (propio): 1 = Realiza un análisis sintáctico correcto y completo de la oración (sujeto, predicado y complementos). · 0,5 = El análisis es parcialmente correcto: identifica sujeto y predicado pero yerra en algún complemento. · 0 = El análisis es incorrecto o incompleto.

**OF.2026.A-L10** · LEN.SIN.SUJPRED Sujeto y predicado · entrena: si · ancla: plantilla `LEN.SIN.COMPL.G07`, nivel que la reproduce 4

> Analice sintácticamente la siguiente oración, respondiendo exclusivamente a las preguntas que se realizan.
> La muerte miraba al jinete desde las torres de Córdoba.
> • Indique si es una oración simple o compuesta:
> • Señale el sujeto y el predicado:
> • Identifique el núcleo del sujeto y el núcleo del predicado:
> • Localice el complemento directo y el complemento circunstancial de lugar.

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Oración simple (un solo verbo). Sujeto: «La muerte»; predicado: «miraba al jinete desde las torres de Córdoba». Núcleo del sujeto: «muerte»; núcleo del predicado: «miraba». CD: «al jinete» (CD de persona introducido por «a», contraída con el artículo). CCL: «desde las torres de Córdoba».
- Criterio (oficial): 1 = Realiza un análisis sintáctico completo y correcto. · 0,5 = Análisis parcialmente correcto. · 0 = Análisis incorrecto o muy incompleto.

### 4.2 Lengua · Resumen y tema (7 en los exámenes)

**OF.2026.A-L1** · LEN.COM.RESU El resumen · entrena: parcial

> Explique el tema del poema y resuma su contenido principal. Procure relacionar el paisaje, el viaje y la sensación de destino que transmite el texto.

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Tema: el presentimiento de la muerte; el destino trágico que impide al jinete alcanzar su meta. Contenido: un jinete cabalga hacia Córdoba con su jaca negra y aceitunas en la alforja; aunque conoce el camino, sabe que nunca llegará, porque la muerte lo espera y lo mira desde las torres de la ciudad. El paisaje (el llano, el viento, la luna que pasa de «grande» a «roja») acompaña el viaje y anuncia la tragedia; los «¡Ay!» finales expresan su angustia, y la repetición de «Córdoba. / Lejana y sola.» cierra el poema de forma circular, como una meta inalcanzable.
- Criterio (oficial): 1 = Explica con claridad tema y contenido. · 0,5 = Recoge solo parte del sentido. · 0 = No interpreta adecuadamente el poema.

**OF.2026.O-L1** · LEN.COM.RESU El resumen · entrena: parcial

> Resuma el tema y el contenido del fragmento.

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Tema: el elogio de la libertad como el mayor bien del ser humano. Contenido: don Quijote explica a Sancho que la libertad es el don más precioso que el cielo dio a los hombres, superior a todos los tesoros, y que por ella, como por la honra, se debe arriesgar la vida, mientras que el cautiverio es el mayor mal. Lo ilustra con su experiencia: pese a la abundancia y los banquetes del castillo que acaban de dejar, se sentía hambriento porque no los disfrutaba con libertad, al no ser suyos.
- Criterio (oficial): 1 = Resume correctamente el contenido y el tema del fragmento. · 0,5 = Resume parcialmente el contenido principal. · 0 = No identifica bien el tema o el resumen es incorrecto o insuficiente.

### 4.3 Lengua · Análisis de formas verbales (5 en los exámenes)

**OF.2024.O-L5** · LEN.VER.ANALISIS Análisis de formas verbales · entrena: parcial · ancla: plantilla `LEN.VER.ANALISIS.G05`, nivel que la reproduce 4 — Las formas irregulares (es, estuvieras, visto, oí, era…) no se generan: no hay tabla de irregulares revisada.

> Analice los siguientes verbos:
> Es
> Habréis cantado
> Estuvieras
> Hayan visto
> Cantaría
> Hubiéramos hablado

- Soporte: el cuadernillo parte del texto de Lope de Vega, *Rimas (soneto «Desmayarse, atreverse, estar furioso…»)* (`textosBase` · `OF.2024.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Es: 3.ª persona del singular del presente de indicativo de ser. Habréis cantado: 2.ª persona del plural del futuro compuesto (perfecto) de indicativo de cantar. Estuvieras: 2.ª persona del singular del pretérito imperfecto de subjuntivo de estar. Hayan visto: 3.ª persona del plural del pretérito perfecto compuesto de subjuntivo de ver. Cantaría: 1.ª o 3.ª persona del singular del condicional simple de cantar. Hubiéramos hablado: 1.ª persona del plural del pretérito pluscuamperfecto de subjuntivo de hablar.
- Criterio (propio): 1 = Analiza correctamente las 6 formas (persona, número, tiempo, modo e infinitivo). · 0,5 = Comete un error en una de las formas o en uno de sus rasgos. · 0 = Comete varios errores o no completa la actividad.

**OF.2022.O-L4** · LEN.VER.ANALISIS Análisis de formas verbales · entrena: si · ancla: plantilla `LEN.VER.ANALISIS.G05`, nivel que la reproduce 4 — Las formas irregulares (es, estuvieras, visto, oí, era…) no se generan: no hay tabla de irregulares revisada.

> Analice las siguientes formas verbales que aparecen en el texto:
> sonrío
> perdiste
> hundiré

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Sonrío: 1.ª persona del singular del presente de indicativo del verbo sonreír (irregular). Perdiste: 2.ª persona del singular del pretérito perfecto simple de indicativo del verbo perder. Hundiré: 1.ª persona del singular del futuro simple de indicativo del verbo hundir.
- Criterio (propio): 1 = Analiza correctamente las 3 formas (persona, número, tiempo, modo e infinitivo). · 0,5 = Comete un error en una de las formas o en uno de sus rasgos. · 0 = Comete varios errores o no completa la actividad.

### 4.4 Lengua · Definir términos (5 en los exámenes)

**OF.2026.O-L5** · LEN.LEX.DICC El diccionario · entrena: parcial

> Explique qué es un diccionario y cuáles son sus principales utilidades.

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Un diccionario es una obra de consulta que recoge, generalmente por orden alfabético, las palabras de una lengua (o de una materia) y explica su significado (acepciones), su categoría gramatical, y a menudo su etimología, su uso y ejemplos. Utilidades: conocer el significado de las palabras, comprobar su ortografía, su categoría y su género, resolver dudas de uso y conjugación, buscar sinónimos y antónimos y traducir (diccionarios bilingües). Hay diccionarios de la lengua (DLE), de sinónimos, de dudas, etimológicos, bilingües, etc.
- Criterio (oficial): 1 = Explica con claridad qué es un diccionario y sus utilidades. · 0,5 = Da una explicación general, pero incompleta. · 0 = No define correctamente el diccionario ni sus usos.

**OF.2022.O-L8** · LEN.REC.DEF Definir recursos literarios · entrena: no

> Defina los siguientes términos: metáfora, palabras homónimas, verso libre, comparación.

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Metáfora: figura que identifica un término real con otro imaginario por su semejanza, sin nexo comparativo. Palabras homónimas: palabras que coinciden en la forma (pronunciación y, en su caso, escritura) pero tienen significados y orígenes distintos («vino» de venir / «vino», bebida); pueden ser homógrafas u homófonas. Verso libre: verso que no se ajusta a una medida ni a una rima fijas. Comparación o símil: figura que relaciona dos términos por su semejanza mediante un nexo comparativo (como, cual, igual que).
- Criterio (propio): 1 = Define correctamente los 4 términos. · 0,5 = Define bien 2 o 3 términos o con alguna imprecisión. · 0 = Define bien un término o ninguno.

### 4.5 Lengua · Formación de palabras (4 en los exámenes)

**OF.2026.A-L9** · LEN.FOR.CLAS Primitivas, derivadas, compuestas y parasintéticas · entrena: no

> Indique si las siguientes palabras son primitivas, derivadas o compuestas. Justifique brevemente su respuesta. Ejemplo: paraguas = compuesta, porque reúne dos lexemas.
> Palabra / Tipo / Justificación
> lunero
> torrecilla
> sacapuntas
> mortal
> viento
> girasol

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa; tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_aplazada.pdf, pág. 9
- Solución modelo: Lunero: derivada (lexema lun- + sufijo -ero). Torrecilla: derivada (torre + sufijo diminutivo -ecilla). Sacapuntas: compuesta (dos lexemas: saca + puntas). Mortal: derivada (lexema mort-, el de muerte, + sufijo -al). Viento: primitiva (no procede de otra palabra española; solo lexema y morfema de género). Girasol: compuesta (gira + sol).
- Criterio (oficial): 1 = Distingue primitivas, derivadas y compuestas con justificación. · 0,5 = Comete un error de clasificación. · 0 = Comete varios errores o no justifica.

**OF.2026.O-L4** · LEN.FOR.DER Prefijos y sufijos · entrena: no

> Escriba el prefijo de cada una de estas palabras derivadas, especificando a continuación el significado que aporta.
> Palabra / Prefijo / Significado del prefijo
> deshacer
> invisible
> releer
> submarino
> antinatural

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Deshacer: des- (inversión o negación de la acción). Invisible: in- (negación, «no»). Releer: re- (repetición, «de nuevo»). Submarino: sub- («debajo de»). Antinatural: anti- («contrario a, opuesto a»).
- Criterio (oficial): 1 = Escribe correctamente todos los prefijos y su significado. · 0,5 = Presenta un error en los prefijos o en algún significado. · 0 = Comete varios errores o no completa la actividad.

### 4.6 Lengua · Vocabulario en contexto (4 en los exámenes)

**OF.2024.O-L4** · LEN.LEX.CTX Significado en contexto · entrena: parcial

> Defina las siguientes palabras:
> Esquivo
> Alentado
> Paradoja
> Altivo
> Áspero
> Desengaño

- Soporte: el cuadernillo parte del texto de Lope de Vega, *Rimas (soneto «Desmayarse, atreverse, estar furioso…»)* (`textosBase` · `OF.2024.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Esquivo: que rehúye el trato o la atención; desdeñoso, arisco. Alentado: animoso, valiente. Paradoja: figura que une ideas en apariencia contradictorias que encierran una verdad («creer que un cielo en un infierno cabe»); también, idea o hecho contrario a la lógica. Altivo: orgulloso, soberbio. Áspero: desapacible y rudo en el trato (en sentido propio, de superficie rugosa). Desengaño: conocimiento de la verdad con que se sale del engaño o del error; decepción.
- Criterio (propio): 1 = Define correctamente las 6 palabras. · 0,5 = Define bien 4 o 5 palabras. · 0 = Define bien 3 palabras o menos.

**OF.2022.O-L3** · LEN.LEX.CTX Significado en contexto · entrena: parcial

> Explique el significado de las siguientes palabras, atendiendo a su sentido en el texto.
> grey
> medrar
> hueste
> orfebrería

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Grey: conjunto de personas con un carácter común; aquí, el linaje o la familia de don Mendo (en sentido propio, rebaño). Medrar: prosperar, mejorar de posición o fortuna. Hueste: ejército en campaña, tropa. Orfebrería: arte de labrar objetos de oro, plata u otros metales preciosos; aquí, un estuche labrado de ese modo.
- Criterio (propio): 1 = Explica correctamente las 4 palabras según su sentido en el texto. · 0,5 = Explica bien 2 o 3 palabras. · 0 = Explica bien una palabra o ninguna.

### 4.7 Lengua · Autor y contexto (3 en los exámenes)

**OF.2026.A-L2** · LEN.LIT.HIST Historia de la literatura española · entrena: parcial

> Cite al autor y explique brevemente quién fue, qué fue la Generación del 27 y dos rasgos característicos de su poesía.

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Federico García Lorca (Fuente Vaqueros, Granada, 1898 – Víznar, 1936), poeta y dramaturgo, asesinado al comienzo de la Guerra Civil; autor de Canciones (de donde procede el poema), Romancero gitano, Poeta en Nueva York, Bodas de sangre y La casa de Bernarda Alba. La Generación del 27 fue el grupo de poetas que se dio a conocer en los años veinte y se reunió en 1927 en el homenaje a Góngora en el tercer centenario de su muerte (Salinas, Guillén, Diego, Aleixandre, Alonso, Alberti, Cernuda…); unió tradición y vanguardia. Rasgos de su poesía: fusión de lo popular andaluz (canción, romance, copla) con lo culto y vanguardista (metáfora audaz); símbolos de muerte y destino trágico (luna, caballo, sangre, color negro) y el tema de la frustración.
- Criterio (oficial): 1 = Identifica al autor y lo sitúa bien en su contexto. · 0,5 = Menciona al autor con datos incompletos. · 0 = No identifica al autor o se equivoca.

**OF.2026.O-L3** · LEN.LIT.HIST Historia de la literatura española · entrena: parcial

> Contextualice brevemente el fragmento en su periodo histórico e indique el nombre de la obra y de su autor.

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Pertenece a la segunda parte del Quijote (El ingenioso caballero don Quijote de la Mancha, 1615), capítulo 58, de Miguel de Cervantes (1547-1616). Se sitúa en el Siglo de Oro, entre el Renacimiento y el Barroco, bajo el reinado de Felipe III, época de crisis y desengaño. Don Quijote y Sancho acaban de dejar el castillo de los duques. Cervantes estuvo cautivo en Argel (1575-1580), lo que da hondura personal a este elogio de la libertad. El Quijote, parodia de los libros de caballerías, se considera la primera novela moderna.
- Criterio (oficial): 1 = Sitúa correctamente la obra, el autor y el periodo histórico. · 0,5 = Menciona solo parte de los datos o los explica con imprecisión. · 0 = No identifica correctamente autor, obra o contexto.

### 4.8 Lengua · Citar autores de un grupo (3 en los exámenes)

**OF.2019.A-L8** · LEN.LIT.HIST Historia de la literatura española · entrena: parcial

> Cite al menos cinco poetas españoles que publicaran alguno de sus libros en el Siglo XX.

- Soporte: el cuadernillo parte del texto de Carmen Laforet, *Nada* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Por ejemplo: Antonio Machado, Juan Ramón Jiménez, Federico García Lorca, Rafael Alberti, Miguel Hernández, Blas de Otero, José Hierro, Gloria Fuertes, Ángel González o Jaime Gil de Biedma.
- Criterio (propio): 1 = Cita correctamente los 5 elementos. · 0,5 = Comete un error en uno de los 5 elementos. · 0 = Comete más de un error o no completa la actividad.

**OF.2019.O-L8** · LEN.LIT.HIST Historia de la literatura española · entrena: parcial

> Cite cuatro narradores españoles que naciesen en el Siglo XX.

- Soporte: el cuadernillo parte del texto de Pedro Salinas, *La voz a ti debida* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Por ejemplo: Camilo José Cela (1916), Miguel Delibes (1920), Carmen Laforet (1921), Ana María Matute (1925), Carmen Martín Gaite (1925), Rafael Sánchez Ferlosio (1927), Juan Marsé (1933), Eduardo Mendoza (1943), Javier Marías (1951), Antonio Muñoz Molina (1956).
- Criterio (propio): 1 = Cita correctamente los 4 elementos. · 0,5 = Comete un error en uno de los 4 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.9 Lengua · Cronología de autores (3 en los exámenes)

**OF.2019.A-L9** · LEN.LIT.HIST Historia de la literatura española · entrena: si · ancla: plantilla `LEN.LIT.HIST.G05`, nivel que la reproduce 4 — El examen ordena 5–6 autores; la plantilla, 4 (§5).

> Ordene del más antiguo al más moderno los siguientes autores:
> Miguel de Cervantes, Luis Alberto de Cuenca, Rosalía de Castro, Ramón del Valle-Inclán, Gabriela Mistral, Gaspar Melchor de Jovellanos.

- Soporte: el cuadernillo parte del texto de Carmen Laforet, *Nada* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: 1. Miguel de Cervantes (1547-1616); 2. Gaspar Melchor de Jovellanos (1744-1811); 3. Rosalía de Castro (1837-1885); 4. Ramón del Valle-Inclán (1866-1936); 5. Gabriela Mistral (1889-1957); 6. Luis Alberto de Cuenca (1950).
- Criterio (propio): 1 = Ordena correctamente los 6 elementos. · 0,5 = Comete un error en uno de los 6 elementos. · 0 = Comete más de un error o no completa la actividad.

**OF.2019.O-L9** · LEN.LIT.HIST Historia de la literatura española · entrena: si · ancla: plantilla `LEN.LIT.HIST.G05`, nivel que la reproduce 4 — El examen ordena 5–6 autores; la plantilla, 4 (§5).

> Ordene del más antiguo al más moderno a los siguientes autores:
> Gustavo Adolfo Bécquer, José de Espronceda, Francisco de Quevedo, Juan Ramón Jiménez, José Hierro, Juan Boscán.

- Soporte: el cuadernillo parte del texto de Pedro Salinas, *La voz a ti debida* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: 1. Juan Boscán (c. 1490-1542); 2. Francisco de Quevedo (1580-1645); 3. José de Espronceda (1808-1842); 4. Gustavo Adolfo Bécquer (1836-1870); 5. Juan Ramón Jiménez (1881-1958); 6. José Hierro (1922-2002).
- Criterio (propio): 1 = Ordena correctamente los 6 elementos. · 0,5 = Comete un error en uno de los 6 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.10 Lengua · Sentido de una frase (3 en los exámenes)

**OF.2026.A-L3** · LEN.COM.INFER Inferencias y sentido · entrena: parcial

> Explique por qué el poema transmite una sensación de fatalidad o destino trágico. Justifique su respuesta con, al menos, tres elementos del texto.

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Porque el jinete sabe desde el principio que no llegará a su destino: 1) «Aunque sepa los caminos / yo nunca llegaré a Córdoba» (certeza del fracaso pese a conocer el camino); 2) la personificación «La muerte me está mirando / desde las torres de Córdoba» y «¡Ay que la muerte me espera, / antes de llegar a Córdoba!»; 3) los símbolos: la jaca negra (luto), la luna que se vuelve roja (sangre, presagio de muerte); 4) Córdoba «lejana y sola», meta inalcanzable, y la estructura circular; 5) los «¡Ay!» de lamento.
- Criterio (oficial): 1 = Justifica bien la idea de destino trágico con pruebas textuales. · 0,5 = Aporta una justificación parcial. · 0 = No justifica o lo hace incorrectamente.

**OF.2022.O-L6** · LEN.COM.INFER Inferencias y sentido · entrena: parcial

> Explique el sentido de la siguiente oración en el texto:
> “¡Quien diga que yo un borrón
> eché a mi grey que alce el dedo!”

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Don Mendo afirma que no ha deshonrado a su linaje: desafía a cualquiera que sostenga que él ha manchado el honor de su familia («echar un borrón a la grey») a que lo diga levantando la mano. El hipérbaton y el tono grandilocuente parodian el sentido del honor del drama romántico.
- Criterio (propio): 1 = Explica que Mendo defiende su honra y desafía a quien lo acuse de deshonrar a su linaje. · 0,5 = La explicación es correcta pero incompleta o imprecisa. · 0 = La explicación es incorrecta o no responde.

### 4.11 Lengua · Grados del adjetivo (2 en los exámenes)

**OF.2019.A-L7** · LEN.CLA.ADJGRAD Grados del adjetivo · entrena: no

> Incluya los siguientes adjetivos en la casilla correspondiente:
> alegre, verde, amplísimo, mayor, fuerte, mínimo, dócil, paupérrimo, peor.
> POSITIVOS / COMPARATIVOS / SUPERLATIVOS

- Soporte: el cuadernillo parte del texto de Carmen Laforet, *Nada* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Positivos: alegre, verde, fuerte, dócil. Comparativos: mayor, peor. Superlativos: amplísimo, mínimo, paupérrimo.
- Criterio (propio): 1 = Clasifica correctamente los 9 elementos. · 0,5 = Comete un error en uno de los 9 elementos. · 0 = Comete más de un error o no completa la actividad.

**OF.2019.O-L7** · LEN.CLA.ADJGRAD Grados del adjetivo · entrena: no

> Incluya los siguientes adjetivos en la casilla correspondiente:
> viejos, mejor, menor, dulcísimo, peor, triste, azul, óptimo, ínfimo.
> POSITIVOS / COMPARATIVOS / SUPERLATIVOS

- Soporte: el cuadernillo parte del texto de Pedro Salinas, *La voz a ti debida* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Positivos: viejos, triste, azul. Comparativos: mejor, menor, peor (comparativos sintéticos de bueno, pequeño y malo). Superlativos: dulcísimo, óptimo, ínfimo (superlativos absolutos).
- Criterio (propio): 1 = Clasifica correctamente los 9 elementos. · 0,5 = Comete un error en uno de los 9 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.12 Lengua · Identificar figura retórica (2 en los exámenes)

**OF.2026.A-L6** · LEN.REC.FIG Identificar recursos literarios · entrena: no

> Responda a las siguientes cuestiones literarias y métricas:
> a) Cite una anáfora o repetición expresiva del poema y explique su efecto.
> b) Localice una personificación.
> c) Localice un epíteto o una combinación de palabras con fuerte valor descriptivo.
> d) Mida los versos “Por el llano, por el viento” y “jaca negra, luna roja” e indique si tienen la misma medida.

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: a) Anáfora de «¡Ay…!» al comienzo de tres versos seguidos (o «por el llano, por el viento»): intensifica el lamento y la angustia y marca el ritmo. b) «La muerte me está mirando / desde las torres de Córdoba» (también «la muerte me espera»). c) «jaca negra», «luna roja», «luna grande», «jaca valerosa». d) Por-el-lla-no-por-el-vien-to: 8 sílabas; ja-ca-ne-gra-lu-na-ro-ja: 8 sílabas. Ambos son octosílabos (terminación llana); tienen la misma medida.
- Criterio (oficial): 1 = Identifica recursos literarios y realiza bien la medida. · 0,5 = Acierta sólo parte de la cuestión. · 0 = No identifica los recursos o mide mal ambos versos.

**OF.2019.O-L3** · LEN.REC.FIG Identificar recursos literarios · entrena: no

> ¿Qué figura literaria podemos encontrarnos en estos versos? Marque la opción correcta.
> [Cita del texto base protegido: consúltese en el PDF oficial]
> Enumeración.
> Metonimia.
> Hipérbaton.
> [Cita del texto base protegido: consúltese en el PDF oficial]
> Sinécdoque.
> Anáfora.
> Comparación.

- Soporte: el cuadernillo parte del texto de Pedro Salinas, *La voz a ti debida* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa; cita protegida sustituida por la remisión al PDF
- Solución modelo: Primer fragmento: enumeración (serie de elementos que lo dejaría todo). Segundo fragmento: anáfora (repetición de «si me llamaras» al comienzo de los versos).
- Criterio (propio): 1 = Marca las dos figuras correctas. · 0,5 = Acierta una de las dos. · 0 = No acierta ninguna.

### 4.13 Lengua · Movimiento/época (2 en los exámenes)

**OF.2019.O-L2** · LEN.LIT.HIST Historia de la literatura española · entrena: si

> ¿En qué generación podemos incluir al autor?

- Soporte: el cuadernillo parte del texto de Pedro Salinas, *La voz a ti debida* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa
- Solución modelo: En la Generación del 27 (Pedro Salinas, 1891-1951).
- Criterio (propio): 1 = Indica la Generación del 27. · 0,5 = Lo sitúa en la vanguardia o en el siglo XX sin precisar la generación. · 0 = Indica otra generación o no responde.

**OF.2017.O-L4** · LEN.LIT.HIST Historia de la literatura española · entrena: parcial

> ¿A qué movimiento cultural cree que pertenece el texto?

- Soporte: el cuadernillo parte del texto de Gustavo Adolfo Bécquer, *El monte de las ánimas* (`textosBase` · `OF.2017.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Al Romanticismo (en su etapa tardía o posromántica): es una de las Leyendas de Gustavo Adolfo Bécquer (1836-1870), publicada en 1861.
- Criterio (propio): 1 = Identifica el Romanticismo (o posromanticismo) y, en su caso, al autor. · 0,5 = Lo sitúa en el siglo XIX sin precisar el movimiento. · 0 = Indica otro movimiento o no responde.

### 4.14 Lengua · Rasgos de un movimiento (2 en los exámenes)

**OF.2024.O-L3** · LEN.LIT.HIST Historia de la literatura española · entrena: no

> ¿Cuáles son las dos corrientes más importantes de la literatura barroca? Cite a los dos autores más representativos de estos movimientos.

- Soporte: el cuadernillo parte del texto de Lope de Vega, *Rimas (soneto «Desmayarse, atreverse, estar furioso…»)* (`textosBase` · `OF.2024.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: El culteranismo (o gongorismo), que cuida la forma (cultismos, hipérbaton, metáforas complejas), cuyo máximo representante es Luis de Góngora; y el conceptismo, que juega con las ideas y los significados (agudeza, dilogía, antítesis), representado por Francisco de Quevedo (también Baltasar Gracián).
- Criterio (propio): 1 = Cita las dos corrientes y sus dos autores. · 0,5 = Cita las dos corrientes sin autores, o una corriente con su autor. · 0 = No identifica las corrientes.

**OF.2017.O-L5** · LEN.LIT.HIST Historia de la literatura española · entrena: no

> ¿Cuáles son las principales características de este movimiento cultural?

- Soporte: el cuadernillo parte del texto de Gustavo Adolfo Bécquer, *El monte de las ánimas* (`textosBase` · `OF.2017.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Rechazo de las normas neoclásicas y libertad creadora; subjetivismo y exaltación de los sentimientos; gusto por lo sobrenatural, el misterio y lo legendario (presente en el texto: ánimas, campana que dobla sola); evasión hacia la Edad Media y lo exótico; ambientes nocturnos, ruinas y cementerios (capilla ruinosa, noche de difuntos); naturaleza agreste que refleja el estado de ánimo; recuperación de tradiciones populares y nacionales; mezcla de géneros, de prosa y verso.
- Criterio (propio): 1 = Explica al menos cuatro rasgos del Romanticismo y relaciona alguno con el texto. · 0,5 = Cita dos o tres rasgos o los enumera sin explicarlos. · 0 = Los rasgos son erróneos o no responde.

### 4.15 Lengua · Relacionar término y definición (2 en los exámenes)

**OF.2026.A-L8** · LEN.REC.DEF Definir recursos literarios · entrena: no

> Relacione cada término con su definición, siguiendo el ejemplo.
> A. Repetición de una o varias palabras al comienzo de versos u oraciones.
> B. Grupo de palabras que pertenecen a un mismo ámbito de significado.
> C. Palabra que sustituye al nombre.
> D. Figura que atribuye cualidades humanas a animales, cosas o ideas.
> E. Palabra invariable que modifica al verbo, a un adjetivo o a otro adverbio.
> F. Palabra que sirve de enlace entre palabras u oraciones.
> G. Exageración expresiva de la realidad.
> H. Conjunto de palabras que comparten el mismo lexema o raíz.
> I. Nombre que designa seres u objetos sin individualizarlos.
> J. Palabra que relaciona unas palabras con otras dentro de la oración.
> Términos: 1. Sustantivo común (I) · 2. Pronombre personal · 3. Adverbio · 4. Preposición · 5. Conjunción · 6. Familia léxica · 7. Campo semántico · 8. Personificación · 9. Anáfora · 10. Hipérbole

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa; tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_aplazada.pdf, pág. 8
- Solución modelo: 1 I (dado como ejemplo); 2 C; 3 E; 4 J; 5 F; 6 H; 7 B; 8 D; 9 A; 10 G. Nota de la app: es la respuesta esperada por el tribunal (4 J, 5 F), pero las definiciones J y F se solapan. Según la NGLE, la preposición es una palabra invariable que introduce un complemento (su término) y lo subordina a otra palabra; la conjunción une palabras, grupos u oraciones (coordinantes) o introduce oraciones subordinadas (subordinantes).
- Criterio (oficial): 1 = Relaciona bien los términos con las definiciones. · 0,5 = Comete un error. · 0 = Comete más de un error.

**OF.2026.O-L9** · LEN.CLA.VAR Palabras variables · entrena: no

> Una el término con la definición que le corresponda.
> Por ejemplo: 8 G, ya que la definición que corresponde al término "sustantivo" es la G.
> A. Palabra que expresa una cualidad o característica del sustantivo.
> B. Persona, animal o cosa que realiza la acción del verbo en una oración.
> C. Parte variable de la oración que puede expresar tiempo, modo, número y persona.
> D. Palabra que sustituye al nombre para evitar su repetición.
> E. Recurso literario que exagera de forma intencionada la realidad.
> F. Persona que cuenta lo que ocurre en una narración.
> G. Palabra que nombra seres, objetos, lugares, ideas o sentimientos.
> H. Conjunto formado por sujeto y predicado.
> Términos: 1. Adjetivo · 2. Sujeto · 3. Verbo · 4. Hipérbole · 5. Narrador · 6. Oración · 7. Pronombre · 8. Sustantivo (G)

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa; tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 9
- Solución modelo: 1 A (adjetivo); 2 B (sujeto); 3 C (verbo); 4 E (hipérbole); 5 F (narrador); 6 H (oración); 7 D (pronombre); 8 G (sustantivo, dado como ejemplo). Nota de la app: es la respuesta esperada por el tribunal, pero dos definiciones del enunciado son imprecisas. Según la NGLE, el sujeto es una función sintáctica: el elemento que concuerda en número y persona con el verbo, haga o no la acción (en «El ladrón fue detenido», el sujeto no detiene). Y el verbo es una clase de palabra, no una «parte de la oración»: expresa acciones, procesos o estados, se flexiona en persona, número, tiempo, aspecto y modo, y es el núcleo del predicado.
- Criterio (oficial): 1 = Relaciona correctamente todos los términos con sus definiciones. · 0,5 = Comete un error en las relaciones. · 0 = Comete varios errores o no completa la actividad.

### 4.16 Lengua · Tilde diacrítica (2 en los exámenes)

**OF.2022.O-L9** · LEN.ORT.DIA Tilde diacrítica · entrena: si · ancla: plantilla `LEN.ORT.DIA.G01`, nivel que la reproduce 4 — Sin el razonamiento que pide el examen.

> Escoja en cada apartado la opción correcta. Razone su respuesta.
> a.1) Ojalá se dé cuenta.   a.2) Ojalá se de cuenta.
> b.1) ¿Confías en mí?   b.2) ¿Confías en mi?
> c.1) Mi bebida favorita es el te verde.   c.2) Mi bebida favorita es el té verde.
> d.1) Se paciente y espera tu turno.   d.2) Sé paciente y espera tu turno.

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: a.1: «dé» es forma del verbo dar (presente de subjuntivo) y lleva tilde diacrítica frente a la preposición «de». b.1: «mí» es pronombre personal tónico tras preposición; «mi» sin tilde es determinante posesivo. c.2: «té» es el sustantivo (la bebida); «te» es pronombre. d.2: «sé» es el imperativo de ser; «se» es pronombre.
- Criterio (propio): 1 = Elige y razona correctamente los 4 elementos. · 0,5 = Comete un error en uno de los 4 elementos. · 0 = Comete más de un error o no completa la actividad.

**OF.2019.O-L5** · LEN.ORT.DIA Tilde diacrítica · entrena: parcial

> En los siguientes versos, aparece la palabra “si” con tilde y sin tilde, explique la diferencia.
> [Cita del texto base protegido: consúltese en el PDF oficial]

- Soporte: el cuadernillo parte del texto de Pedro Salinas, *La voz a ti debida* (**protegido, no se reproduce**: consúltese en el PDF oficial); el repositorio no indica si esta pregunta lo usa; cita protegida sustituida por la remisión al PDF
- Solución modelo: Es un caso de tilde diacrítica. «Si» sin tilde es una conjunción (aquí introduce una exclamación de deseo, con valor condicional: «¡si me llamaras!»). «Sí» con tilde es un adverbio de afirmación (también puede ser pronombre reflexivo: «para sí»).
- Criterio (propio): 1 = Identifica la conjunción «si» y el adverbio de afirmación «sí» como tilde diacrítica. · 0,5 = La explicación es correcta pero incompleta o imprecisa. · 0 = La explicación es incorrecta o no responde.

### 4.17 Lengua · Tipología textual (2 en los exámenes)

**OF.2026.O-L2** · LEN.COM.TIPO Tipos de texto · entrena: parcial

> Explique qué tipo de texto es y cite al menos tres características o ideas principales del texto.

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Es un texto literario narrativo (fragmento de novela) que reproduce, en estilo directo, un parlamento de don Quijote de carácter argumentativo: defiende una tesis con argumentos. Características e ideas: tesis inicial (la libertad es el mayor don); comparaciones que la refuerzan (vale más que los tesoros de la tierra y del mar; se equipara a la honra); antítesis libertad / cautiverio; ejemplo de la propia experiencia (los banquetes del castillo); vocativo dirigido a Sancho; lengua culta del Siglo de Oro con periodos amplios e hipérbatos.
- Criterio (oficial): 1 = Reconoce el tipo de texto y explica los rasgos del texto con claridad. · 0,5 = Identifica el texto, pero explica solo algunos rasgos del texto. · 0 = No identifica correctamente el tipo de texto ni sus características.

**OF.2022.O-L2** · LEN.COM.TIPO Tipos de texto · entrena: parcial

> ¿De qué tipo de texto se trata? Enumere al menos tres características de este tipo de textos.

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Es un texto teatral (género dramático), en verso: un fragmento de La venganza de Don Mendo (1918), astracanada que parodia el drama histórico romántico. Características: diálogo entre personajes, con el nombre de cada uno ante su intervención; acotaciones entre paréntesis que indican gestos y acciones («Se seca una lágrima de cada ojo»); ausencia de narrador; escrito para ser representado; versificación (versos de distintas medidas, sobre todo octosílabos, con rima consonante); y, en este caso, humor por exageración, rimas forzadas y lenguaje arcaizante.
- Criterio (propio): 1 = Identifica el texto teatral y explica al menos tres características. · 0,5 = Identifica el tipo de texto pero explica solo una o dos características. · 0 = No identifica el tipo de texto ni sus características.

### 4.18 Lengua · Análisis morfológico (1 en los exámenes)

**OF.2026.O-L6** · LEN.CLA.VAR Palabras variables · entrena: no

> Analice morfológicamente las siguientes palabras del fragmento: libertad, hombres, aquellos, gozaba.
> En cada caso debe indicar: el tipo de palabra; el género y el número, si se trata de un nombre, adjetivo, determinante o pronombre; y, si es un verbo, la persona, el número, el tiempo, el modo y el infinitivo. Añada también cualquier otra observación relevante, por ejemplo si el sustantivo es común o abstracto, o si una palabra puede funcionar como determinante o como pronombre según el contexto.

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Libertad: sustantivo común, abstracto, femenino, singular. Hombres: sustantivo común, concreto, masculino, plural (aquí con valor genérico, «los seres humanos»). Aquellos: determinante demostrativo de lejanía, masculino plural (acompaña a «banquetes»); sin sustantivo funcionaría como pronombre. Gozaba: verbo gozar, 1.ª persona del singular (la forma coincide con la 3.ª), pretérito imperfecto de indicativo, 1.ª conjugación, aspecto imperfectivo, voz activa.
- Criterio (oficial): 1 = Clasifica correctamente las clases de palabras. · 0,5 = Comete un error en la clasificación. · 0 = Comete más de un error o no responde. · Nota: La rúbrica oficial habla de «clases de palabras», pero la pregunta pide el análisis morfológico completo. La app aplica: Bien, las 4 palabras con su clase y todos sus rasgos correctos; Regular, un error (en la clase o en un rasgo); Mal, más de un error.

### 4.19 Lengua · Clases de palabras (1 en los exámenes)

**OF.2026.A-L4** · LEN.CLA.JUST Justificar la categoría · entrena: no

> Clasifique las siguientes palabras del poema indicando su clase de palabra y una breve justificación gramatical. Fíjese en el ejemplo.
> Palabra / Clase de palabra / Justificación gramatical
> Córdoba / Sustantivo propio / Nombra de manera individual una ciudad concreta.
> negra
> aunque
> yo
> nunca
> desde
> mi
> llegaré

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa; tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_aplazada.pdf, pág. 5
- Solución modelo: Negra: adjetivo calificativo; acompaña a «jaca», con la que concuerda (femenino singular), y expresa una cualidad. Aunque: conjunción subordinante concesiva; introduce «aunque sepa los caminos». Yo: pronombre personal tónico de 1.ª persona del singular; es el sujeto de «llegaré». Nunca: adverbio de negación (y tiempo); invariable, modifica al verbo «llegaré». Desde: preposición; introduce el complemento «las torres de Córdoba» (origen). Mi: determinante posesivo de 1.ª persona, un poseedor, singular; acompaña a «alforja» y a «jaca». Llegaré: verbo llegar, 1.ª persona del singular del futuro simple de indicativo.
- Criterio (oficial): 1 = Clasifica correctamente todas las palabras y justifica bien. · 0,5 = Comete un error o una justificación insuficiente. · 0 = Comete varios errores de clasificación.

### 4.20 Lengua · Colocar tildes en un texto (1 en los exámenes)

**OF.2024.O-L7** · LEN.ORT.AGU Agudas, llanas y esdrújulas · entrena: parcial · ancla: plantilla `LEN.ORT.AGU.G02`, nivel que la reproduce ninguno — No reproducible: colocarTilde trabaja palabras sueltas; el texto con contexto está pendiente (tildeContexto.json).

> Escriba adecuadamente las tildes que falten en este texto.
> ¿Como se hace para que una idea se convierta en realidad? ¿A veces sientes que, por mas que lo intentas, no logras ver el camino claro hacia tus metas? ¿No es acaso frustrante cuando, a pesar de todos tus esfuerzos, parece que no avanzas ni un paso? Trabajar duro, dia tras dia, sin obtener los resultados que esperas, puede ser realmente desalentador. ¿Que piensas que hace falta para superar estos obstaculos? Se dice que la clave esta en no rendirse, pero, ¿realmente es solamente eso? ¿O acaso hay algo mas, algun secreto o estrategia que nos este eludiendo? Me pregunto, ¿sera que estamos enfocando mal nuestros esfuerzos o que simplemente no hemos encontrado aun el metodo correcto? En la busqueda del exito, ¿cuantas veces debemos caer antes de poder levantarnos? ¿Y que pasa con aquellos momentos en los que sentimos que todo lo que hemos construido se derrumba ante nuestros ojos? ¿Como encontramos la fuerza para empezar de nuevo, para creer una vez mas en la posibilidad de alcanzar esos sueños que parecen tan esquivos?

- Soporte: el cuadernillo parte del texto de Lope de Vega, *Rimas (soneto «Desmayarse, atreverse, estar furioso…»)* (`textosBase` · `OF.2024.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Llevan tilde (19 palabras): ¿Cómo… (inicio), más (por más que), día tras día (2), ¿Qué piensas…?, obstáculos, está (la clave está), algo más, algún, esté (nos esté eludiendo), ¿será…?, aún (todavía), método, búsqueda, éxito, ¿cuántas…?, ¿Y qué…?, ¿Cómo encontramos…?, una vez más. Motivos: interrogativos con tilde diacrítica (cómo, qué, cuántas); «más» adverbio; «aún» equivale a «todavía»; agudas en vocal (está, esté, será) o en -n (algún); esdrújulas (obstáculos, método, éxito, búsqueda); «día», hiato con vocal cerrada tónica.
- Criterio (propio): 1 = Coloca todas las tildes que faltan sin añadir ninguna incorrecta. · 0,5 = Comete uno o dos errores (omisión o tilde de más). · 0 = Comete más de dos errores.

### 4.21 Lengua · Contexto histórico (1 en los exámenes)

**OF.2017.O-L2** · LEN.COM.INFER Inferencias y sentido · entrena: parcial

> ¿En qué época cree que sucede la historia que Alonso le cuenta a Beatriz?

- Soporte: el cuadernillo parte del texto de Gustavo Adolfo Bécquer, *El monte de las ánimas* (`textosBase` · `OF.2017.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: En la Edad Media, en la época de la Reconquista (siglos XII-XIII): Soria acaba de ser conquistada a los árabes y el rey trae a la Orden del Temple (disuelta en 1312) para defenderla. Lo confirman los templarios, los condes, los pajes, los hidalgos y la autoridad del rey.
- Criterio (propio): 1 = Sitúa la historia en la Edad Media y lo justifica con indicios del texto (templarios, conquista a los árabes, condes, pajes). · 0,5 = Indica la Edad Media sin justificarlo o con una justificación imprecisa. · 0 = Sitúa la historia en otra época o no responde.

### 4.22 Lengua · Homófonos y diacríticas (1 en los exámenes)

**OF.2026.A-L7** · LEN.ORT.HOM Homófonos frecuentes · entrena: si · ancla: plantilla `LEN.ORT.HOM.G02`, nivel que la reproduce 4 — Sin el razonamiento que pide el examen.

> Seleccione la opción correcta en cada caso y justifique brevemente su elección.
> Opción con hueco / Opción correcta / Explicación
> ¿(Porque / Por qué) aparece la luna con tanta fuerza en el poema?
> El jinete no llegó (aun / aún) sabiendo el camino.
> No (tubo / tuvo) tiempo de detenerse.
> ¡(Ay / Hay / Ahí) qué camino tan largo!
> Quizá me (de / dé) una respuesta mañana.
> (Tu / Tú) conoces bien ese lugar.
> El mensajero dejó el paquete (ahí / hay).
> Debes (prever / preveer) los problemas antes de actuar.

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa; tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_aplazada.pdf, pág. 7
- Solución modelo: Por qué: interrogativa directa (preposición + interrogativo tónico). Aun: equivale a «incluso» («incluso sabiendo el camino»). Tuvo: verbo tener («tubo» es una pieza cilíndrica hueca). Ay: interjección de dolor o lamento. Dé: forma del verbo dar (presente de subjuntivo), con tilde diacrítica frente a la preposición «de». Tú: pronombre personal, sujeto de «conoces». Ahí: adverbio de lugar («hay» es del verbo haber). Prever: «ver con anticipación», se conjuga como ver; «preveer» es incorrecto.
- Criterio (oficial): 1 = Selecciona y explica correctamente todas las opciones. · 0,5 = Tiene uno o dos fallos menores. · 0 = Comete varios errores.

### 4.23 Lengua · Léxico (familia, campo, sinónimos) (1 en los exámenes)

**OF.2026.A-L5** · LEN.LEX.CAMPO Campo semántico y familia léxica · entrena: parcial

> Trabaje con el vocabulario del poema.
> a) Escriba dos palabras de la misma familia léxica de camino.
> b) Escriba dos palabras del campo semántico de viaje o desplazamiento.
> c) Proponga un sinónimo contextual de lejana y un antónimo contextual de largo.
> d) Explique la diferencia entre Córdoba (nombre propio) y camino (nombre común).

- Soporte: el cuadernillo parte del texto de Federico García Lorca, *Canciones («Canción de jinete»)* (`textosBase` · `OF.2026.A.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: a) Caminar, caminante (también caminata, encaminar). b) Cabalgar, trayecto (también ruta, jinete, alforja, viajero). c) Lejana: distante, remota; largo: corto, breve. d) «Córdoba» es nombre propio: designa un ser único (una ciudad concreta), se escribe con mayúscula y normalmente no lleva determinante; «camino» es nombre común: designa cualquier elemento de una clase, se escribe con minúscula y admite determinantes.
- Criterio (oficial): 1 = Resuelve correctamente familia léxica, campo semántico y relaciones léxicas. · 0,5 = Resuelve tres partes con precisión. · 0 = Comete varios errores. · Nota: La pregunta tiene 4 apartados (a–d). La app aplica: Bien, los 4 correctos; Regular, 2 o 3 correctos; Mal, 0 o 1.

### 4.24 Lengua · Métrica (1 en los exámenes)

**OF.2022.O-L7** · LEN.MET.MED Medida del verso · entrena: no · **ANULADA**

> Analice la métrica de los siguientes versos del texto:
> “¿Cómo? Si ya tuya
> soy y lo mío tuyo es...
> este collar que te doy
> has de aceptarlo, Marqués”.
> ANULADA
> Advertido error en el enunciado de la pregunta se procede a anularla, no siendo tenida en cuenta a efectos de puntuación.

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Pregunta anulada por el tribunal (el enunciado no reproduce bien los versos del texto: en él son «¿Cómo? / Si ya tuya soy / y lo mío tuyo es...»). No puntúa.
- Criterio (propio): 1 = Pregunta anulada: no puntúa. · 0,5 = Pregunta anulada: no puntúa. · 0 = Pregunta anulada: no puntúa.

### 4.25 Lengua · Palabra por definición (1 en los exámenes)

**OF.2024.O-L8** · LEN.LEX.DICC El diccionario · entrena: parcial

> Escriba la palabra correcta para la definición propuesta, atendiendo a las indicaciones dadas sobre la primera y última letra de cada término.
> Acción y efecto de redimir o redimirse. R*******N
> Que tiene la capacidad de volver a su forma original
> después de ser doblado, comprimido o deformado. E******O
> Arte de proyectar y construir edificios. A*********A
> Ciencia que trata de la composición y las
> propiedades de las sustancias materiales. Q*****A
> Sustancia que se encuentra en la naturaleza y que,
> al combinarse con el oxígeno, produce óxido. M****L
> Especialista en teología. T*****O
> Que implica o denota contradicción. P********O
> Momento o situación en que algo llega a su máximo
> grado de perfección, intensidad o grandeza. A****O
> Método de razonamiento deductivo que consiste
> en obtener una conclusión a partir de dos
> proposiciones llamadas premisas.
> S*******O
> Instrumento musical de viento, formado por un
> tubo generalmente de madera, que tiene agujeros
> laterales que se tapan con los dedos o con llaves.

- Soporte: el cuadernillo parte del texto de Lope de Vega, *Rimas (soneto «Desmayarse, atreverse, estar furioso…»)* (`textosBase` · `OF.2024.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Redención (R*******N); elástico (E******O); arquitectura (A*********A); química (Q*****A); metal (M****L); teólogo (T*****O); paradójico (P********O); apogeo (A****O); silogismo (S*******O); oboe (O**E). Nota de la app: la pista A*********A indica 11 letras, pero ARQUITECTURA tiene 12, y la pista M****L indica 6, pero METAL tiene 5. Se aceptan ARQUITECTURA y METAL.
- Criterio (propio): 1 = Escribe correctamente las 10 palabras. · 0,5 = Comete uno o dos errores. · 0 = Comete más de dos errores.

### 4.26 Lengua · Polisemia (1 en los exámenes)

**OF.2022.O-L5** · LEN.LEX.POLI Polisemia, homonimia y paronimia · entrena: parcial

> En el texto aparece la palabra polisémica “sancionar”. Explique dos de sus acepciones.
> Acepción en el texto / Otra acepción

- Soporte: el cuadernillo parte del texto de Pedro Muñoz Seca, *La venganza de Don Mendo* (`textosBase` · `OF.2022.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Acepción en el texto: autorizar, aprobar o dar validez a algo (el Conde aprobaría su unión). Otra acepción: aplicar una sanción o un castigo («sancionar a un conductor»).
- Criterio (propio): 1 = Explica correctamente las dos acepciones. · 0,5 = Explica bien una de las dos. · 0 = No explica correctamente ninguna.

### 4.27 Lengua · Sinónimos y antónimos (1 en los exámenes)

**OF.2024.O-L6** · LEN.LEX.SIN Sinónimos y antónimos · entrena: parcial

> Escriba un sinónimo y un antónimo para cada una de estas palabras.
> Amor, Centro, Veneno, Desengaño, Sabiduría, Fortaleza, Inefable, Perenne, Opíparo, Ubérrimo, Taciturno

- Soporte: el cuadernillo parte del texto de Lope de Vega, *Rimas (soneto «Desmayarse, atreverse, estar furioso…»)* (`textosBase` · `OF.2024.O.texto`); el repositorio no indica si esta pregunta lo usa
- Solución modelo: Amor: cariño / odio. Centro: medio / periferia (borde). Veneno: ponzoña, tóxico / antídoto. Desengaño: decepción / ilusión. Sabiduría: conocimiento, sapiencia / ignorancia. Fortaleza: fuerza, vigor / debilidad. Inefable: indecible, inexpresable / expresable. Perenne: perpetuo, permanente / efímero, caduco. Opíparo: copioso, abundante / frugal, escaso. Ubérrimo: muy fértil, abundantísimo / estéril, yermo. Taciturno: callado, silencioso / hablador, locuaz.
- Criterio (propio): 1 = Escribe correctamente los 22 sinónimos y antónimos. · 0,5 = Comete uno o dos errores. · 0 = Comete más de dos errores o no completa la actividad.

### 4.28 Lengua · Uso normativo (1 en los exámenes)

**OF.2026.O-L7** · LEN.VER.IRREG Verbos irregulares · entrena: no

> Seleccione la opción correcta de las dos facilitadas y razone su elección.
> Oración con opciones / Opción correcta / Explicación
> Ayer (anduve / andé) mucho por el campo.
> No (había / habían habido) suficientes sillas.
> El capitán dijo que quizá (vendría / vendrá) mañana.
> Había (demasiado / demasiados) ruido en la plaza.
> Mis primos y yo (fuimos / fuemos) al museo.
> Ojalá (haya / haiga) tiempo para terminar.
> Ese libro es (de él / suyo).

- Soporte: el cuadernillo parte del texto de Miguel de Cervantes, *Don Quijote de la Mancha, segunda parte, capítulo LVIII* (`textosBase` · `OF.2026.O.texto`); el repositorio no indica si esta pregunta lo usa; tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 7
- Solución modelo: Anduve: pretérito perfecto simple irregular de andar («andé» es incorrecto). Había: «haber» impersonal (existencial) solo se usa en 3.ª persona del singular; «habían habido» es incorrecto. Vendría: en estilo indirecto con verbo de lengua en pasado («dijo»), el futuro del enunciado original pasa a condicional (concordancia de tiempos); «vendrá» se admite si el hecho sigue siendo futuro respecto al momento en que se habla. Demasiado: concuerda en masculino singular con «ruido». Fuimos: pretérito perfecto simple de ir («fuemos» es un vulgarismo). Haya: presente de subjuntivo de haber («haiga» es un vulgarismo). Suyo: el posesivo es la opción esperada en registro culto. Nota de la app: se aceptan las dos opciones en dos casos. «Vendría» es la esperada (estilo indirecto en pasado), pero «vendrá» es correcta si el hecho sigue siendo futuro cuando se habla. «Suyo» es la esperada, pero «de él» también es gramatical y evita la ambigüedad de «suyo».
- Criterio (oficial): 1 = Selecciona correctamente las opciones y justifica adecuadamente. · 0,5 = Tiene un error o justificaciones poco precisas. · 0 = Presenta varios errores o no justifica.

### 4.29 Matemáticas · Medidas de centralización (5 en los exámenes)

**OF.2026.A-M18** · MAT.EST.CENTRAL Media, mediana, moda y rango · entrena: si · ancla: plantilla `MAT.EST.CENTRAL.G01`, nivel que la reproduce 4 — Plantilla en borrador. El examen pide varias medidas; cada ítem, una.

> Las puntuaciones de un concurso son: 6, 7, 7, 8, 9 y 11. Halle la media aritmética, la mediana, la moda y el rango.

- Soporte: —
- Solución modelo: 1) Media: 48 : 6 = 8. 2) Mediana: número par de datos → (7 + 8) : 2 = 7,5. 3) Moda: 7. Rango: 11 − 6 = 5. Resultado: Media 8; mediana 7,5; moda 7; rango 5.
- Criterio (oficial): 1 = Obtiene bien media, mediana, moda y rango. · 0,5 = Comete un error. · 0 = Comete varios errores.

**OF.2024.O-M20** · MAT.EST.CENTRAL Media, mediana, moda y rango · entrena: parcial · ancla: plantilla `MAT.EST.CENTRAL.G01`, nivel que la reproduce ninguno — No reproducible: 30 datos (el generador usa 5–8).

> Un grupo de alumnos de 5º de Primaria han dedicado el último mes a recaudar fondos para una causa benéfica. Estas son las cantidades de dinero recogidas cada día:
> 21 30 22 21 13 20 24
> 30 20 27 17 21 17 20
> 20 30 19 24 20 26 17
> 30 19 17 23 20 25 24
> 19 30
> Calcule las medidas de tendencia central (o medidas de centralización).

- Soporte: —
- Solución modelo: 1) N = 30 datos; suma = 666. 2) Media: 666 : 30 = 22,2. 3) Mediana: con los datos ordenados, el 15.º y el 16.º valen 21 → 21. 4) Moda: 20 (aparece 6 veces). Resultado: Media 22,2 €; mediana 21 €; moda 20 €.
- Criterio (propio): 1 = Calcula correctamente los 3 elementos. · 0,5 = Comete un error en uno de los 3 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.30 Matemáticas · Ordenar números (5 en los exámenes)

**OF.2026.A-M14** · MAT.NUM.ORDEN Ordenar fracciones y decimales · entrena: si · ancla: plantilla `MAT.NUM.ORDEN.G02`, nivel que la reproduce 4

> Ordene de mayor a menor los siguientes números: 5/4; 1,18; 7/6; 1,205.

- Soporte: —
- Solución modelo: 1) 5/4 = 1,25; 7/6 = 1,1666… 2) Se comparan: 1,25 > 1,205 > 1,18 > 1,166… Resultado: 5/4 > 1,205 > 1,18 > 7/6.
- Criterio (oficial): 1 = Ordena correctamente todos los números. · 0,5 = Comete un error en el orden. · 0 = El orden es incorrecto en varios casos.

**OF.2024.O-M11** · MAT.NUM.ORDEN Ordenar fracciones y decimales · entrena: parcial · ancla: plantilla `MAT.NUM.ORDEN.G02`, nivel que la reproduce ninguno — No reproducible: hay que calcular expresiones antes de ordenar.

> Ordene las siguientes cantidades de menor a mayor:
> 2/3 de 29,1   1,904 · 10   2² + 4² – 0,56   58,26/3

- Soporte: formulaEnImagen: Superíndices y fracciones de la imagen restituidos (CORRECCIONES_OCR.md §2) — docs/examenes/oficiales/2024_comun_ordinaria.pdf, pág. 9
- Solución modelo: 1) 2/3 de 29,1 = 19,4; 1,904 · 10 = 19,04. 2) 2² + 4² − 0,56 = 20 − 0,56 = 19,44; 58,26 : 3 = 19,42. Resultado: 1,904 · 10 < 2/3 de 29,1 < 58,26/3 < 2² + 4² − 0,56.
- Criterio (propio): 1 = Ordena correctamente las cuatro cantidades. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.31 Matemáticas · Conversión de unidades (4 en los exámenes)

**OF.2024.O-M16** · MAT.UNI.LMC Longitud, masa y capacidad · entrena: si · ancla: plantilla `MAT.UNI.LMC.G02`, nivel que la reproduce 5 (**difícil**: por encima del nivel 4) — Suma de cantidades: nivel 5 (sin la comparación final).

> Héctor ha hecho la compra, y ha metido los productos en tres bolsas. Una pesa 2 kg y 6 hg; otra pesa 1 kg y 8 dag, y la tercera pesa 1 kg y 70 dg. Va a cargarlas en un carrito que soporta un peso total de 4,5 kg. Responda razonadamente ¿podrá el carrito soportar el peso de las tres bolsas?

- Soporte: —
- Solución modelo: 1) Bolsa 1: 2 kg 6 hg = 2,6 kg. Bolsa 2: 1 kg 8 dag = 1,08 kg. Bolsa 3: 1 kg 70 dg = 1 kg 7 g = 1,007 kg. 2) Total: 2,6 + 1,08 + 1,007 = 4,687 kg. 3) 4,687 kg > 4,5 kg. Resultado: No: las bolsas pesan 4,687 kg y el carrito soporta 4,5 kg.
- Criterio (propio): 1 = Convierte, suma y razona correctamente la respuesta. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

**OF.2026.O-M14** · MAT.UNI.LMC Longitud, masa y capacidad · entrena: si · ancla: plantilla `MAT.UNI.LMC.G02`, nivel que la reproduce 3 — Compleja → incompleja: nivel 3.

> Complete la siguiente tabla según el ejemplo.
> En cada fila, convierta a metros las cantidades que aparecen en las distintas columnas y escriba en la última columna el resultado total.
> Recuerde: cada número vale según la unidad de la columna en la que está escrito. Después hay que pasarlo a metros y sumar.
> Ejemplo: 3 km + 2 hm = 3200 m.
> (Tabla con columnas km | hm | dam | m | dm | cm | Resultado. Filas: 3 km, 2 hm → 3200 m; 5 dam, 4 m; 7 hm, 6 cm; 8 m, 5 dm; 6 km.)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 12
- Solución modelo: 1) Fila 2: 5 dam = 50 m; 4 m → 54 m. 2) Fila 3: 7 hm = 700 m; 6 cm = 0,06 m → 700,06 m. 3) Fila 4: 8 m; 5 dm = 0,5 m → 8,5 m. Fila 5: 6 km = 6000 m. Resultado: 54 m; 700,06 m; 8,5 m; 6000 m.
- Criterio (oficial): 1 = Completa correctamente toda la tabla. · 0,5 = Comete un error en una equivalencia. · 0 = Presenta más de un error.

### 4.32 Matemáticas · Operación combinada (4 en los exámenes)

**OF.2026.A-M20** · MAT.OPE.COMB Operaciones combinadas con paréntesis y corchetes · entrena: si · ancla: plantilla `MAT.OPE.COMB.G02`, nivel que la reproduce 5 (**difícil**: por encima del nivel 4) — Tres niveles de agrupación: los da el nivel 5, que además añade una potencia (lo supera).

> Resuelva la siguiente operación combinada: {[(24 : 3) + 5] × 2} − {3 × [7 − (9 − 5)]}.

- Soporte: —
- Solución modelo: 1) Paréntesis interiores: 24 : 3 = 8; 9 − 5 = 4. 2) Corchetes: 8 + 5 = 13; 7 − 4 = 3. 3) Llaves: 13 × 2 = 26; 3 × 3 = 9; 26 − 9. Resultado: 17.
- Criterio (oficial): 1 = Resuelve correctamente la operación combinada. · 0,5 = Comete un error de proceso o cálculo. · 0 = No respeta la jerarquía de operaciones.

**OF.2019.A-M20** · MAT.OPE.COMB Operaciones combinadas con paréntesis y corchetes · entrena: si · ancla: plantilla `MAT.OPE.COMB.G02`, nivel que la reproduce 4

> Resuelva la siguiente operación combinada:
> [(12 x 4 - 8) : 4] + [2 (23 - 2 x 3)] =

- Soporte: —
- Solución modelo: 1) (12 × 4 − 8) : 4 = 40 : 4 = 10. 2) 2 × (23 − 6) = 2 × 17 = 34. 3) 10 + 34. Resultado: 44.
- Criterio (propio): 1 = Resuelve correctamente la operación respetando la jerarquía. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.33 Matemáticas · Término desconocido (4 en los exámenes)

**OF.2026.A-M13** · MAT.OPE.INCOG Término desconocido · entrena: si · ancla: plantilla `MAT.OPE.INCOG.G02`, nivel que la reproduce 4 — El examen pide dos igualdades sueltas; cada ítem, una (los niveles 5–6 las encadenan).

> Calcule el valor de a y b para que se cumplan estas igualdades:
> 36 × a = 10.404
> 28.560 : b = 84.

- Soporte: —
- Solución modelo: 1) a = 10.404 : 36 = 289 (36 × 289 = 10.404). 2) b = 28.560 : 84 = 340 (84 × 340 = 28.560). Resultado: a = 289; b = 340.
- Criterio (oficial): 1 = Calcula correctamente a y b. · 0,5 = Acierta solo uno de los valores. · 0 = No obtiene los valores correctos.

**OF.2019.A-M13** · MAT.OPE.INCOG Término desconocido · entrena: si · ancla: plantilla `MAT.OPE.INCOG.G02`, nivel que la reproduce 4 — El examen pide dos igualdades sueltas; cada ítem, una (los niveles 5–6 las encadenan).

> Calcule el valor de a y b para que se cumplan estas igualdades:
> 23 a = 9591
> 24024 : b = 88

- Soporte: —
- Solución modelo: 1) a = 9591 : 23 = 417 (23 × 417 = 9591). 2) b = 24024 : 88 = 273 (88 × 273 = 24.024). Resultado: a = 417; b = 273.
- Criterio (propio): 1 = Calcula correctamente a y b. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.34 Matemáticas · Áreas compuestas (4 en los exámenes)

**OF.2026.O-M17** · MAT.GEO.AREA Áreas · entrena: no

> En esta zona ajardinada se plantarán margaritas en la parte sombreada y césped en el resto. Calcule el área exacta de la superficie destinada al césped. Tómese π = 3,14.
> [Figura: zona en forma de L de 10 m de ancho total; parte izquierda de 8 m de alto; a la derecha, un rectángulo de 4 m de ancho y 3 m de alto; dentro de la parte izquierda, un círculo sombreado de r = 2 m.]

- Soporte: figura: Zona en L de 10 m de ancho; parte izquierda de 8 m de alto; a la derecha, rectángulo de 4 m × 3 m; círculo sombreado de r = 2 m (CORRECCIONES_OCR.md §4; la misma descripción va entre corchetes en el enunciado) — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 14
- Solución modelo: 1) Zona en L: rectángulo de (10 − 4) × 8 = 48 m² más rectángulo de 4 × 3 = 12 m² → 60 m². 2) Círculo (margaritas): 3,14 × 2² = 12,56 m². 3) Césped: 60 − 12,56. Resultado: 47,44 m².
- Criterio (oficial): 1 = Calcula correctamente el área exterior, el círculo y la superficie final. · 0,5 = Realiza parte del procedimiento correctamente. · 0 = No resuelve correctamente el problema.

**OF.2022.O-M15** · MAT.GEO.AREA Áreas · entrena: no

> Calcule cuánto costaría pintar la fachada del siguiente edificio, teniendo en cuenta que el precio por pintar un metro cuadrado es de 3,5 €.
> [Figura: fachada formada por un rectángulo de 12 m de base y 8,5 m de altura; encima, un rectángulo de 4 m de ancho y 3 m de alto rematado por un triángulo de 4 m de base y 2,5 m de altura.]

- Soporte: figura: Fachada: rectángulo de 12 m × 8,5 m; encima, rectángulo de 4 m × 3 m rematado por un triángulo de 4 m de base y 2,5 m de altura (CORRECCIONES_OCR.md §4; la misma descripción va entre corchetes en el enunciado) — docs/examenes/oficiales/2022_comun_ordinaria.pdf, pág. 11
- Solución modelo: 1) Planta baja: 12 × 8,5 = 102 m². Torre: 4 × 3 = 12 m². 2) Triángulo: (4 × 2,5) : 2 = 5 m². 3) Fachada: 102 + 12 + 5 = 119 m²; coste 119 × 3,5. Resultado: 416,50 €.
- Criterio (propio): 1 = Calcula correctamente el área de la fachada y su coste. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.35 Matemáticas · Operaciones con fracciones (3 en los exámenes)

**OF.2024.O-M12** · MAT.NUM.FRAOP Operaciones con fracciones · entrena: si · ancla: plantilla `MAT.NUM.FRAOP.G03`, nivel que la reproduce 6 (**difícil**: por encima del nivel 4) — Combinada con agrupaciones: nivel 6 (con una sola agrupación).

> Resuelva la siguiente operación combinada, simplificando las fracciones siempre que sea posible:
> [3/5 + 1/4 × 2/3] : [(1 + 1/5) × 16/4] =

- Soporte: formulaEnImagen: Operación en imagen, transcrita de la imagen (CORRECCIONES_OCR.md §2) — docs/examenes/oficiales/2024_comun_ordinaria.pdf, pág. 9
- Solución modelo: 1) Primer corchete: 1/4 × 2/3 = 1/6; 3/5 + 1/6 = 23/30. 2) Segundo corchete: 1 + 1/5 = 6/5; 6/5 × 16/4 = 6/5 × 4 = 24/5. 3) División: 23/30 : 24/5 = 23/30 × 5/24 = 115/720 = 23/144. Resultado: 23/144.
- Criterio (propio): 1 = Resuelve correctamente la operación y simplifica el resultado. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

**OF.2026.O-M13** · MAT.NUM.FRAPROB Problemas con fracciones · entrena: si · ancla: plantilla `MAT.NUM.FRAPROB.G01`, nivel que la reproduce 3 — Fracciones sobre el total (nivel 3), pero se pide la fracción, no la cantidad: perfil parcial.

> En una biblioteca escolar, 1/4 de los libros son de aventuras, 1/5 son de ciencia, 1/10 son de poesía y el resto son de historia. Calcule la fracción de libros de historia.

- Soporte: —
- Solución modelo: 1) m.c.m.(4, 5, 10) = 20: 1/4 + 1/5 + 1/10 = 5/20 + 4/20 + 2/20 = 11/20. 2) Historia: 1 − 11/20. Resultado: 9/20 de los libros.
- Criterio (oficial): 1 = Calcula correctamente la fracción restante. · 0,5 = Plantea bien el problema, pero comete un error de cálculo. · 0 = No resuelve correctamente el problema.

### 4.36 Matemáticas · Sistema sexagesimal (3 en los exámenes)

**OF.2026.A-M12** · MAT.UNI.TIEM Tiempo y sistema sexagesimal · entrena: si · ancla: plantilla `MAT.UNI.TIEM.G01`, nivel que la reproduce 4

> Tres aparatos funcionan consecutivamente durante estos tiempos: A) 2 h 45 min 30 s; B) 165 min 900 s; C) 1 h 95 min 120 s. Exprese la duración total del tiempo de funcionamiento en segundos.

- Soporte: —
- Solución modelo: 1) A: 7200 + 2700 + 30 = 9930 s. 2) B: 9900 + 900 = 10.800 s. C: 3600 + 5700 + 120 = 9420 s. 3) Total: 9930 + 10.800 + 9420. Resultado: 30.150 segundos (8 h 22 min 30 s).
- Criterio (oficial): 1 = Convierte y suma bien todas las unidades de tiempo. · 0,5 = Tiene una conversión o suma incorrecta. · 0 = No completa correctamente la conversión.

**OF.2019.A-M12** · MAT.UNI.TIEM Tiempo y sistema sexagesimal · entrena: si · ancla: plantilla `MAT.UNI.TIEM.G01`, nivel que la reproduce 4

> En un laboratorio se está experimentando con tres baterías diferentes. Estas baterías son intercambiables y se quiere investigar cuánto tiempo podrá funcionar un motor conectado a las mismas. En las pruebas independientes cada una de las baterías ha dado la siguiente duración:
> A. 3h 10’   B. 210’ 600’’   C. 190’ 2400’’
> ¿Cuántos minutos funcionará el motor si las tres baterías se conectan al mismo de forma sucesiva?

- Soporte: —
- Solución modelo: 1) A: 3 h 10′ = 190 min. 2) B: 600″ = 10′ → 220 min. C: 2400″ = 40′ → 230 min. 3) Sucesivas: 190 + 220 + 230. Resultado: 640 minutos.
- Criterio (propio): 1 = Convierte y suma correctamente las tres duraciones. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.37 Matemáticas · Volumen y capacidad (3 en los exámenes)

**OF.2026.A-M17** · MAT.GEO.VOL Volúmenes · entrena: no

> Un depósito con forma de prisma rectangular mide 2,5 m de largo, 1,2 m de ancho y 0,8 m de alto. Calcule su volumen en m³ y exprese después esa capacidad en litros.

- Soporte: —
- Solución modelo: 1) V = largo × ancho × alto = 2,5 × 1,2 × 0,8. 2) 1 m³ = 1000 l. Resultado: 2,4 m³ = 2400 litros.
- Criterio (oficial): 1 = Calcula correctamente volumen y litros. · 0,5 = Acierta solo una de las dos partes. · 0 = No resuelve la cuestión.

**OF.2024.O-M17** · MAT.GEO.VOL Volúmenes · entrena: no

> Verónica tiene el recipiente A lleno de agua, y quiere trasvasarla al recipiente B.
> Responda razonadamente:
> a) ¿Cuántos litros de agua tiene en el recipiente A?
> b) ¿Le faltará, le sobrará, o tendrá el agua justa para llenar el recipiente B?
> Téngase en cuenta que las bases de los recipientes son regulares.
> [Figura: recipiente A, prisma de base cuadrada de 130 mm de lado y 22 cm de altura; recipiente B, prisma de base pentagonal de 12,5 cm de lado, 85,7 mm de apotema y 120 mm de altura.]

- Soporte: figura: A: prisma de base cuadrada de 130 mm de lado y 22 cm de alto. B: prisma pentagonal de 12,5 cm de lado, 85,7 mm de apotema y 120 mm de alto (CORRECCIONES_OCR.md §4; la misma descripción va entre corchetes en el enunciado) — docs/examenes/oficiales/2024_comun_ordinaria.pdf, pág. 12
- Solución modelo: 1) A (prisma de base cuadrada): 13 cm × 13 cm × 22 cm = 3718 cm³ = 3,718 l. 2) B (prisma pentagonal): área de la base = perímetro × apotema : 2 = (5 × 12,5) × 8,57 : 2 = 267,8125 cm². 3) Volumen de B: 267,8125 × 12 = 3213,75 cm³ = 3,21375 l. 4) 3,718 − 3,21375 = 0,50425 l. Resultado: a) 3,718 litros; b) le sobrará agua: unos 0,504 l (504,25 cm³). Nota de la app: en un pentágono regular de 12,5 cm de lado la apotema mide unos 8,60 cm, no 8,57 cm. Se usa el dato del enunciado; con 8,60 cm, B tendría unos 3,225 l y la conclusión (sobra agua) no cambia.
- Criterio (propio): 1 = Responde correctamente los 2 elementos. · 0,5 = Comete un error en uno de los 2 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.38 Matemáticas · Arábigo → romano (2 en los exámenes)

**OF.2019.O-M19** · MAT.ROM.ESCR Escribir números romanos · entrena: si · ancla: plantilla `MAT.ROM.ESCR.G02`, nivel que la reproduce 4 — El examen pide 3 números; cada ítem, uno. 1223 no tiene grupo sustractivo.

> Escriba en números romanos:
> 824   1223   793

- Soporte: —
- Solución modelo: 1) 824 = DCCC + XX + IV. 2) 1223 = M + CC + XX + III. 3) 793 = DCC + XC + III. Resultado: DCCCXXIV; MCCXXIII; DCCXCIII.
- Criterio (propio): 1 = Escribe correctamente los 3 elementos. · 0,5 = Comete un error en uno de los 3 elementos. · 0 = Comete más de un error o no completa la actividad.

**OF.2017.O-M15** · MAT.ROM.ESCR Escribir números romanos · entrena: si · ancla: plantilla `MAT.ROM.ESCR.G02`, nivel que la reproduce 4 — El examen pide 3 números; cada ítem, uno.

> Escriba en números romanos:
> 334   975   2069

- Soporte: —
- Solución modelo: 1) 334 = 300 + 30 + 4 = CCC + XXX + IV. 2) 975 = 900 + 70 + 5 = CM + LXX + V. 3) 2069 = 2000 + 60 + 9 = MM + LX + IX. Resultado: CCCXXXIV; CMLXXV; MMLXIX.
- Criterio (propio): 1 = Escribe correctamente los 3 elementos. · 0,5 = Comete un error en uno de los 3 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.39 Matemáticas · Fracción de lo que queda (2 en los exámenes)

**OF.2026.A-M11** · MAT.NUM.FRAPROB Problemas con fracciones · entrena: si · ancla: plantilla `MAT.NUM.FRAPROB.G02`, nivel que la reproduce 4

> En una biblioteca hay 360 libros pendientes de catalogación. El lunes se ordena 1/6 del total. El martes se ordena 1/5 de los que quedan. El miércoles se ordena 1/4 de los restantes. ¿Cuántos libros quedan todavía sin catalogar?

- Soporte: —
- Solución modelo: 1) Lunes: 1/6 de 360 = 60; quedan 300. 2) Martes: 1/5 de 300 = 60; quedan 240. 3) Miércoles: 1/4 de 240 = 60; quedan 180. Resultado: 180 libros.
- Criterio (oficial): 1 = Resuelve correctamente la secuencia de fracciones. · 0,5 = Comete un error de cálculo menor. · 0 = No resuelve el problema.

**OF.2019.A-M11** · MAT.NUM.FRAPROB Problemas con fracciones · entrena: si · ancla: plantilla `MAT.NUM.FRAPROB.G02`, nivel que la reproduce 4 — Las fracciones del examen llegan a denominador 15 (2/11, 3/15); el generador, a 8.

> En una fiesta de cumpleaños debemos hinchar 60 globos. Juan, que ha sido el primero en llegar, ha hinchado 1/12 de los globos. A continuación, María ha hinchado 2/11 de los globos que quedaban y, por último, Ana ha hinchado 3/15 de los globos que restaban. ¿Cuántos globos han quedado sin hinchar?

- Soporte: —
- Solución modelo: 1) Juan: 1/12 de 60 = 5; quedan 55. 2) María: 2/11 de 55 = 10; quedan 45. 3) Ana: 3/15 de 45 = 9; quedan 36. Resultado: Quedan 36 globos sin hinchar.
- Criterio (propio): 1 = Calcula correctamente las fracciones sucesivas sobre lo que queda. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.40 Matemáticas · Porcentaje de una cantidad (2 en los exámenes)

**OF.2026.O-M16** · MAT.POR.CALC Tanto por ciento de una cantidad · entrena: si · ancla: plantilla `MAT.POR.CALC.G02`, nivel que la reproduce 4

> Una asociación vende 240 entradas para una actividad solidaria. El 35 % de lo recaudado se destina a material escolar. Si se han obtenido 1.920 euros, calcule cuánto dinero se dedica a material escolar.

- Soporte: —
- Solución modelo: 1) 35 % de 1920 = 1920 × 0,35. 2) (El número de entradas, 240, no es necesario.) Resultado: 672 €.
- Criterio (oficial): 1 = Calcula correctamente el porcentaje pedido. · 0,5 = Comete un error de cálculo. · 0 = No resuelve correctamente.

**OF.2022.O-M16** · MAT.POR.CALC Tanto por ciento de una cantidad · entrena: si · ancla: plantilla `MAT.POR.CALC.G02`, nivel que la reproduce 4

> En una librería tienen a la venta 1250 libros. El 22% son novelas, el 20% son libros de poesía, el 10% son libros de historia, el 22% son libros de ciencias y el 26% son enciclopedias. Calcule cuántos libros de cada tipo hay en la librería.

- Soporte: —
- Solución modelo: 1) El 1 % de 1250 es 12,5. 2) Cada tipo: porcentaje × 12,5. Resultado: Novelas: 275; Poesía: 250; Historia: 125; Ciencias: 275; Enciclopedias: 325 (suman 1250).
- Criterio (propio): 1 = Calcula correctamente los 5 elementos. · 0,5 = Comete un error en uno de los 5 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.41 Matemáticas · Probabilidad de Laplace (2 en los exámenes)

**OF.2026.A-M16** · MAT.PRO.LAPLACE Probabilidad de un suceso · entrena: si · ancla: plantilla `MAT.PRO.LAPLACE.G01`, nivel que la reproduce 4 — Plantilla en borrador. Tarjetas numeradas de 1 a n (n = 8–20).

> Tenemos 12 tarjetas numeradas del 1 al 12. Relacione cada suceso con su probabilidad.
> (Suceso | Probabilidad: Sacar un número par | __; Sacar un número primo | __; Sacar un número mayor que 10 | __; Sacar un número menor que 13 | __.)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_aplazada.pdf, pág. 13
- Solución modelo: 1) 12 casos posibles; regla de Laplace. 2) Par: 6/12 = 1/2. Primo (2, 3, 5, 7, 11): 5/12. Mayor que 10 (11, 12): 2/12 = 1/6. Menor que 13: 12/12 = 1 (suceso seguro). Resultado: Par 1/2; primo 5/12; mayor que 10 1/6; menor que 13 1. Nota de la app: la columna de probabilidades del cuadernillo está vacía, así que «Relacione» se interpreta como «escriba la probabilidad» de cada suceso.
- Criterio (oficial): 1 = Relaciona bien los sucesos y las probabilidades. · 0,5 = Comete un error. · 0 = Comete varios errores.

**OF.2019.A-M16** · MAT.PRO.LAPLACE Probabilidad de un suceso · entrena: si · ancla: plantilla `MAT.PRO.LAPLACE.G01`, nivel que la reproduce 4 — Plantilla en borrador. Tarjetas numeradas de 1 a n (n = 8–20).

> Tenemos en una caja 10 bolas numeradas del 0 al 9. Si sacamos una bola de la caja ¿qué posibilidades tendremos de que se cumplan los siguientes sucesos?
> Relacione con flechas suceso y probabilidad.
> Sacar un número impar · Sacar un número mayor que 6 · Sacar el número 8 · Sacar un número menor que 10
> 3/10 · 10/10 · 5/10 · 1/10

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2019_comun_aplazada.pdf, pág. 9
- Solución modelo: 1) Casos posibles: 10 (bolas 0–9). Regla de Laplace: favorables / posibles. 2) Impares (1, 3, 5, 7, 9): 5/10. Mayor que 6 (7, 8, 9): 3/10. El 8: 1/10. Menor que 10: todas, 10/10 (suceso seguro). Resultado: Impar → 5/10; mayor que 6 → 3/10; el 8 → 1/10; menor que 10 → 10/10.
- Criterio (propio): 1 = Relaciona correctamente los 4 elementos. · 0,5 = Comete un error en uno de los 4 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.42 Matemáticas · Proporcionalidad directa (2 en los exámenes)

**OF.2026.A-M15** · MAT.POR.PROP Proporcionalidad directa · entrena: si · ancla: plantilla `MAT.POR.PROP.G02`, nivel que la reproduce 4 — Sin cambios: el nivel 4 ya era factor fraccionario con cantidades de hasta 3 cifras. El dato decimal (1,2 l) no se genera.

> Para preparar limonada para 6 personas se necesitan 450 ml de zumo de limón, 1,2 l de agua y 180 g de azúcar. ¿Qué cantidades harán falta para 15 personas si se mantiene la misma proporción?

- Soporte: —
- Solución modelo: 1) Razón: 15 : 6 = 2,5. 2) Se multiplica cada cantidad por 2,5. Resultado: 1125 ml (1,125 l) de zumo de limón; 3 l de agua; 450 g de azúcar.
- Criterio (oficial): 1 = Resuelve bien la proporcionalidad. · 0,5 = Comete un error aislado de cálculo. · 0 = No mantiene la proporción.

**OF.2019.A-M15** · MAT.POR.PROP Proporcionalidad directa · entrena: si · ancla: plantilla `MAT.POR.PROP.G02`, nivel que la reproduce 4 — En el nivel 4 las recetas dan resultados enteros; el examen admite decimales.

> Queremos hacer bizcocho de zanahoria para cinco personas y encontramos esta receta para cuatro personas. ¿Cuáles son las cantidades que deberemos utilizar para preparar ese bizcocho para cinco personas siguiendo las proporciones de la receta?
> Bizcocho de zanahoria para cuatro personas:
> • 250 g de zanahorias crudas.
> • 200 g de harina.
> • 7 g de levadura en polvo o polvo de hornear.
> • 120 ml de aceite de girasol.
> • 4 huevos.
> • 200 g de azúcar.

- Soporte: —
- Solución modelo: 1) Razón de proporcionalidad: 5/4 = 1,25. 2) Cada cantidad se multiplica por 1,25. Resultado: 312,5 g de zanahorias; 250 g de harina; 8,75 g de levadura; 150 ml de aceite; 5 huevos; 250 g de azúcar.
- Criterio (propio): 1 = Calcula correctamente las seis cantidades manteniendo la proporción. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.43 Matemáticas · Romano → arábigo (2 en los exámenes)

**OF.2026.A-M19** · MAT.ROM.LEER Leer números romanos · entrena: si · ancla: plantilla `MAT.ROM.LEER.G02`, nivel que la reproduce 4 — El examen pide 3 números; cada ítem, uno.

> Convierta estos números romanos en números arábigos: MDXLVIII, CMXCIV, MMCDLIII.

- Soporte: —
- Solución modelo: 1) MDXLVIII = 1000 + 500 + 40 + 8. 2) CMXCIV = 900 + 90 + 4. 3) MMCDLIII = 2000 + 400 + 50 + 3. Resultado: 1548; 994; 2453.
- Criterio (oficial): 1 = Convierte correctamente los números romanos. · 0,5 = Comete un error. · 0 = Comete varios errores.

**OF.2019.A-M19** · MAT.ROM.LEER Leer números romanos · entrena: si · ancla: plantilla `MAT.ROM.LEER.G02`, nivel que la reproduce 4 — El examen pide 3 números; cada ítem, uno.

> Convierta estos números romanos en números arábigos:
> MMCCCXLV   CCCXLVII   CDXCIII

- Soporte: —
- Solución modelo: 1) MM CCC XL V = 2000 + 300 + 40 + 5. 2) CCC XL VII = 300 + 40 + 7. 3) CD XC III = 400 + 90 + 3. Resultado: 2345; 347; 493.
- Criterio (propio): 1 = Convierte correctamente los 3 elementos. · 0,5 = Comete un error en uno de los 3 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.44 Matemáticas · Tabla de frecuencias (2 en los exámenes)

**OF.2026.O-M19** · MAT.EST.FREC Frecuencias absolutas y relativas · entrena: no

> En una encuesta sobre actividades extraescolares, complete la tabla de frecuencias.
> (Actividad | Frecuencia absoluta | Frecuencia relativa: Ajedrez 5 | 0,25; Teatro 4 | __; Baloncesto __ | 0,30; Música 5 | __; Total 20 | 1.)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 15
- Solución modelo: 1) Frecuencia relativa = absoluta / 20. 2) Teatro: 4/20 = 0,20. Baloncesto: 0,30 × 20 = 6. Música: 5/20 = 0,25. 3) Comprobación: 5 + 4 + 6 + 5 = 20; 0,25 + 0,20 + 0,30 + 0,25 = 1. Resultado: Teatro 0,20; Baloncesto 6; Música 0,25.
- Criterio (oficial): 1 = Completa correctamente la tabla de frecuencias. · 0,5 = Comete un error en la tabla. · 0 = No completa correctamente la tabla.

**OF.2019.O-M17** · MAT.EST.FREC Frecuencias absolutas y relativas · entrena: no

> En las elecciones para delegado de una clase, los candidatos obtienen los siguientes votos:
> Juan: 5 votos • María: 15 votos • Luisa: 3 votos • Roberto: 2 votos
> Rellene esta tabla con la frecuencia absoluta, la frecuencia relativa y el porcentaje.
> (Tabla: Candidatos | Frecuencia absoluta | Frecuencia relativa | %)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2019_comun_ordinaria.pdf, pág. 10
- Solución modelo: 1) Total de votos: 25. 2) Frecuencia relativa = votos : 25; porcentaje = relativa × 100. Resultado: Juan: 5, 0,2, 20 %; María: 15, 0,6, 60 %; Luisa: 3, 0,12, 12 %; Roberto: 2, 0,08, 8 % (suman 25, 1 y 100 %).
- Criterio (propio): 1 = Completa correctamente toda la tabla. · 0,5 = Comete un error en la tabla. · 0 = Comete más de un error.

### 4.45 Matemáticas · Volumen de cuerpos (2 en los exámenes)

**OF.2022.O-M20** · MAT.GEO.VOL Volúmenes · entrena: no

> Ana ha estado jugando a las construcciones. Calcule el volumen total de la figura que ha creado, expresado en cm³.
> [Figura: tres ortoedros apilados. Superior: c = 0,1 dm, b = 2 cm, a = 80 mm. Central: d = 0,3 dm, e = 2,5 cm, f = 0,09 m. Inferior: g = 0,0012 hm, i = 11 cm, h = 30 mm.]

- Soporte: figura: Tres ortoedros apilados: c = 0,1 dm, b = 2 cm, a = 80 mm; d = 0,3 dm, e = 2,5 cm, f = 0,09 m; g = 0,0012 hm, i = 11 cm, h = 30 mm. La figura no deja claro qué cota es alto y cuál fondo en cada bloque, pero el volumen no depende de ello (CORRECCIONES_OCR.md §4; la misma descripción va entre corchetes en el enunciado) — docs/examenes/oficiales/2022_comun_ordinaria.pdf, pág. 13
- Solución modelo: 1) Todo en cm: c = 0,1 dm = 1 cm; a = 80 mm = 8 cm; d = 0,3 dm = 3 cm; f = 0,09 m = 9 cm; h = 30 mm = 3 cm; g = 0,0012 hm = 12 cm. 2) Bloque superior: 1 × 2 × 8 = 16 cm³. Bloque central: 3 × 2,5 × 9 = 67,5 cm³. 3) Bloque inferior: 12 × 11 × 3 = 396 cm³. Resultado: 479,5 cm³.
- Criterio (propio): 1 = Convierte las medidas y calcula correctamente el volumen total. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

**OF.2019.A-M17** · MAT.GEO.VOL Volúmenes · entrena: no

> Halle el volumen de las siguientes figuras geométricas.
> a) Una pirámide, cuya base es un cuadrado con cuatro metros de lado y cuya distancia al vértice superior (altura) son 8 metros.
> b) Un cilindro cuya base es un círculo con 2 metros de radio y cuya altura es de 8 metros.
> Entiéndase π=3,14.

- Soporte: —
- Solución modelo: 1) Pirámide: V = (área de la base × altura) : 3 = (4² × 8) : 3 = 128/3. 2) Cilindro: V = π · r² · h = 3,14 × 2² × 8. Resultado: a) 128/3 ≈ 42,67 m³; b) 100,48 m³.
- Criterio (propio): 1 = Calcula correctamente los dos volúmenes. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.46 Matemáticas · m.c.m. en contexto (2 en los exámenes)

**OF.2024.O-M14** · MAT.DIV.MCM Mínimo común múltiplo · entrena: no · ancla: plantilla `MAT.DIV.MCD.G01`, nivel que la reproduce 6 (**difícil**: por encima del nivel 4) — Nivel 6.

> Un incunable tiene entre 300 y 350 páginas. Si las contamos de 3 en 3, no sobra ninguna. Si las contamos de 4 en 4, tampoco sobra ninguna. Y, si las contamos de 7 en 7, tampoco sobra ninguna. ¿Cuántas páginas tiene el incunable?

- Soporte: —
- Solución modelo: 1) El número es múltiplo común de 3, 4 y 7: m.c.m.(3, 4, 7) = 84. 2) Múltiplos de 84: 84, 168, 252, 336, 420… 3) El único entre 300 y 350 es 336. Resultado: 336 páginas.
- Criterio (propio): 1 = Aplica el m.c.m. y da el número correcto. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

**OF.2017.O-M17** · MAT.DIV.MCM Mínimo común múltiplo · entrena: no · ancla: plantilla `MAT.DIV.MCD.G01`, nivel que la reproduce 3 — Dos números con contexto: nivel 3. No hay plantilla de MAT.DIV.MCM.

> Una abogada viaja cada 36 días a San Sebastián y un comercial cada 48 días. Hoy han coincidido los dos en la ciudad. ¿Cuántos días pasarán para que vuelvan a coincidir?

- Soporte: —
- Solución modelo: 1) 36 = 2² · 3²; 48 = 2⁴ · 3. 2) m.c.m. = 2⁴ · 3² = 144 (factores comunes y no comunes con el mayor exponente). Resultado: Volverán a coincidir dentro de 144 días.
- Criterio (propio): 1 = Calcula el m.c.m. y responde correctamente. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.47 Matemáticas · Aumentos y descuentos (1 en los exámenes)

**OF.2017.O-M16** · MAT.POR.VAR Aumentos y descuentos porcentuales · entrena: si · ancla: plantilla `MAT.POR.VAR.G01`, nivel que la reproduce 4

> En una tienda de electrodomésticos hay un cartel con una rebaja del 15% sobre todos los artículos. Si un ordenador cuesta 675 €, ¿cuánto pagará por él?

- Soporte: —
- Solución modelo: 1) Descuento: 15 % de 675 = 675 × 0,15 = 101,25 €. 2) Precio final: 675 − 101,25 (o 675 × 0,85). Resultado: 573,75 €.
- Criterio (propio): 1 = Calcula correctamente el precio final. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.48 Matemáticas · Comparar fracciones (1 en los exámenes)

**OF.2022.O-M12** · MAT.NUM.ORDEN Ordenar fracciones y decimales · entrena: si · ancla: plantilla `MAT.NUM.ORDEN.G02`, nivel que la reproduce 3 — El nivel 3 ordena fracciones; el enunciado con palabras no se genera.

> Ainara, Lucas y Berta están leyendo la misma revista. Ainara ha leído la mitad, Lucas las tres cuartas partes, y Berta lleva leídas dos quintas partes. Calcule quién de los tres ha leído más páginas.

- Soporte: —
- Solución modelo: 1) Denominador común 20: 1/2 = 10/20; 3/4 = 15/20; 2/5 = 8/20. 2) Como la revista es la misma, más fracción = más páginas. Resultado: Lucas ha leído más: Lucas (3/4) > Ainara (1/2) > Berta (2/5).
- Criterio (propio): 1 = Compara correctamente las tres fracciones y responde. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.49 Matemáticas · Conceptos de probabilidad (1 en los exámenes)

**OF.2024.O-M19** · MAT.PRO.SUCESOS Tipos de sucesos · entrena: no

> Experiencias aleatorias y sucesos:
> a) Defina “experiencia aleatoria” y ponga un ejemplo.
> b) Defina “suceso” y explique los tipos que existen, con un ejemplo de cada uno.

- Soporte: —
- Solución modelo: a) Experiencia aleatoria: experimento cuyo resultado no se puede predecir aunque se repita en las mismas condiciones, aunque se conocen sus resultados posibles (lanzar un dado). b) Suceso: cada uno de los resultados posibles o conjunto de resultados de una experiencia aleatoria (subconjunto del espacio muestral). Tipos: elemental, con un solo resultado (sacar un 3); compuesto, con varios (sacar par); seguro, que siempre ocurre (sacar menos de 7); imposible, que nunca ocurre (sacar un 8); contrario de A, el que ocurre cuando no ocurre A (par / impar). También se distinguen sucesos compatibles e incompatibles.
- Criterio (propio): 1 = Define con precisión experiencia aleatoria y suceso, y explica los tipos de suceso con ejemplos. · 0,5 = Define bien uno de los dos conceptos o explica los tipos de forma incompleta. · 0 = Las definiciones son incorrectas o no responde.

### 4.50 Matemáticas · Coordenadas cartesianas (1 en los exámenes)

**OF.2024.O-M18** · MAT.GEO.CART Coordenadas cartesianas · entrena: no

> Localice los siguientes puntos en el eje de coordenadas, e indique en qué cuadrante se sitúa cada uno:
> A = (- 4, +2)
> B = (-1, - 4)
> C= (+3, +5)
> D = (+2, -3)

- Soporte: —
- Solución modelo: 1) Cuadrantes: I (+, +); II (−, +); III (−, −); IV (+, −). Resultado: A (−4, +2): II; B (−1, −4): III; C (+3, +5): I; D (+2, −3): IV.
- Criterio (propio): 1 = Sitúa correctamente los 4 elementos. · 0,5 = Comete un error en uno de los 4 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.51 Matemáticas · Criterios de divisibilidad (1 en los exámenes)

**OF.2026.O-M18** · MAT.DIV.REGLAS Criterios de divisibilidad · entrena: no

> Escriba SÍ/NO en las celdas correspondientes según los divisores de cada número.
> (Divisible entre 2 | 3 | 5 | 9 | 10. Números: 246, 315, 540, 913, 720.)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 15
- Solución modelo: 1) Criterios: 2 (termina en cifra par); 3 y 9 (la suma de cifras es múltiplo de 3 o de 9); 5 (termina en 0 o 5); 10 (termina en 0). 2) Sumas de cifras: 246 → 12; 315 → 9; 540 → 9; 913 → 13; 720 → 9. Resultado: 246: 2 SÍ, 3 SÍ, 5 NO, 9 NO, 10 NO · 315: 2 NO, 3 SÍ, 5 SÍ, 9 SÍ, 10 NO · 540: 2 SÍ, 3 SÍ, 5 SÍ, 9 SÍ, 10 SÍ · 913: 2 NO, 3 NO, 5 NO, 9 NO, 10 NO · 720: 2 SÍ, 3 SÍ, 5 SÍ, 9 SÍ, 10 SÍ.
- Criterio (oficial): 1 = Completa correctamente la tabla de divisibilidad. · 0,5 = Comete uno o dos errores. · 0 = Comete más de dos errores.

### 4.52 Matemáticas · Decimal ↔ fracción (1 en los exámenes)

**OF.2026.O-M11** · MAT.NUM.EQUIV Fracción, decimal y porcentaje · entrena: no

> Responda razonadamente: ¿Es 1,25 un número decimal exacto? Expréselo además en forma de fracción irreducible.

- Soporte: —
- Solución modelo: 1) 1,25 tiene un número finito de cifras decimales: es un decimal exacto. 2) 1,25 = 125/100; m.c.d.(125, 100) = 25 → 5/4. Resultado: Sí, es decimal exacto; 1,25 = 5/4.
- Criterio (oficial): 1 = Responde correctamente y expresa también la fracción irreducible. · 0,5 = Responde de forma parcialmente correcta. · 0 = La respuesta es incorrecta o incompleta.

### 4.53 Matemáticas · Escalas (1 en los exámenes)

**OF.2026.O-M20** · MAT.UNI.ESC Escalas · entrena: si · ancla: plantilla `MAT.UNI.ESC.G02`, nivel que la reproduce 4

> Calcule cuánto miden en la realidad las siguientes medidas tomadas en un plano con la escala que se indica. Realice las conversiones necesarias y escriba siempre el resultado final en metros.
> (Medida en el plano | Escala utilizada: 2,5 cm | 1:200; 8 cm | 1:50; 4,2 cm | 1:1.000; 35 mm | 1:20.)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 16
- Solución modelo: 1) Medida real = medida en el plano × denominador de la escala. 2) 2,5 × 200 = 500 cm; 8 × 50 = 400 cm; 4,2 × 1000 = 4200 cm; 35 × 20 = 700 mm. 3) En metros: ÷100 (cm) o ÷1000 (mm). Resultado: 5 m; 4 m; 42 m; 0,7 m.
- Criterio (oficial): 1 = Calcula correctamente todas las medidas reales. · 0,5 = Comete un error en una equivalencia. · 0 = Presenta más de un error.

### 4.54 Matemáticas · Fracciones equivalentes (1 en los exámenes)

**OF.2017.O-M12** · MAT.NUM.FRAEQ Fracciones equivalentes · entrena: si

> ¿Cuáles de estas fracciones son equivalentes y, por tanto, representan la misma cantidad?
> 12/20   48/112   90/150

- Soporte: —
- Solución modelo: 1) Se simplifican: 12/20 = 3/5 (÷4); 48/112 = 3/7 (÷16); 90/150 = 3/5 (÷30). 2) Son equivalentes las que dan la misma fracción irreducible (o productos cruzados iguales: 12 · 150 = 20 · 90 = 1800). Resultado: 12/20 y 90/150 son equivalentes (ambas valen 3/5); 48/112 no.
- Criterio (propio): 1 = Identifica las dos fracciones equivalentes y lo justifica. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.55 Matemáticas · Operaciones con decimales (1 en los exámenes)

**OF.2022.O-M13** · MAT.OPE.JER Jerarquía de las operaciones · entrena: parcial · ancla: plantilla `MAT.OPE.JER.G01`, nivel que la reproduce ninguno — No reproducible: el generador de operaciones combinadas solo usa naturales y fracciones.

> Resuelva las siguientes operaciones:
> a) 71,46 – 14,7 × 5,32 + 13,051 =
> b) 2,45 + 146,9 : 5 =

- Soporte: —
- Solución modelo: 1) a) Primero el producto: 14,7 × 5,32 = 78,204. 2) a) 71,46 − 78,204 + 13,051 = 6,307. 3) b) Primero la división: 146,9 : 5 = 29,38; después 2,45 + 29,38. Resultado: a) 6,307; b) 31,83.
- Criterio (propio): 1 = Resuelve correctamente los 2 elementos. · 0,5 = Comete un error en uno de los 2 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.56 Matemáticas · Potencias (1 en los exámenes)

**OF.2026.O-M12** · MAT.OPE.POT Potencias · entrena: no

> Exprese mediante una potencia cada una de las siguientes afirmaciones:
> a. Un teatro tiene cuatro filas con cuatro asientos en cada una.
> b. En una exposición hay tres vitrinas; en cada vitrina hay tres baldas y en cada balda tres maquetas.
> c. Una pastelería vende seis cajas con seis galletas en cada una.

- Soporte: —
- Solución modelo: 1) a) 4 filas × 4 asientos = 4 × 4. 2) b) 3 vitrinas × 3 baldas × 3 maquetas = 3 × 3 × 3. 3) c) 6 cajas × 6 galletas = 6 × 6. Resultado: a) 4² (= 16); b) 3³ (= 27); c) 6² (= 36).
- Criterio (oficial): 1 = Expresa correctamente las tres potencias. · 0,5 = Comete un error en una de las potencias. · 0 = Comete más de un error.

### 4.57 Matemáticas · Potencias de 10 (1 en los exámenes)

**OF.2022.O-M18** · MAT.OPE.POT Potencias · entrena: no

> Complete las siguientes igualdades:
> a) 7 × 10³ = ___   c) 29 × 10^___ = 290.000   e) ___ × 10⁶ = 53.000.000
> b) 34 × 10⁷ = ___   d) 3 × 10^___ = 3.000.000   f) ___ × 10⁵ = 57.200.000

- Soporte: formulaEnImagen: Exponentes perdidos en la capa de texto, restituidos; casillas de exponente marcadas con «^___» (CORRECCIONES_OCR.md §2) — docs/examenes/oficiales/2022_comun_ordinaria.pdf, pág. 12
- Solución modelo: 1) Multiplicar por 10ⁿ añade n ceros (o desplaza la coma n lugares). 2) c) 290.000 : 29 = 10⁴; d) 3.000.000 : 3 = 10⁶. 3) e) 53.000.000 : 10⁶ = 53; f) 57.200.000 : 10⁵ = 572. Resultado: a) 7000; b) 340.000.000; c) 10⁴; d) 10⁶; e) 53; f) 572.
- Criterio (propio): 1 = Completa correctamente los 6 elementos. · 0,5 = Comete un error en uno de los 6 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.58 Matemáticas · Precio unitario (1 en los exámenes)

**OF.2022.O-M19** · MAT.POR.PROP Proporcionalidad directa · entrena: si · ancla: plantilla `MAT.POR.PROP.G02`, nivel que la reproduce 5 (**difícil**: por encima del nivel 4) — Reducción a la unidad con decimales: nivel 5.

> Un viaje en tranvía cuesta 0,85 € y un abono de 10 viajes 6,80 €.
> a) ¿Cuánto cuesta cada viaje comprando un abono?
> b) ¿Cuánto nos ahorramos comprando abonos?

- Soporte: —
- Solución modelo: 1) a) 6,80 : 10 = 0,68 € por viaje. 2) b) Ahorro por viaje: 0,85 − 0,68 = 0,17 €; en un abono de 10 viajes: 8,50 − 6,80 = 1,70 €. Resultado: a) 0,68 €; b) 0,17 € por viaje (1,70 € por cada abono de 10 viajes).
- Criterio (propio): 1 = Responde correctamente los 2 elementos. · 0,5 = Comete un error en uno de los 2 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.59 Matemáticas · Probabilidad experimental (1 en los exámenes)

**OF.2026.O-M15** · MAT.PRO.SUCESOS Tipos de sucesos · entrena: no

> La siguiente tabla representa los tiros libres encestados por un jugador de baloncesto en cinco partidos. Calcule la probabilidad estimada de que, en su próximo lanzamiento, enceste un tiro libre. No es necesario hallar el porcentaje, puede responder con una fracción.
> (Partidos 1.º a 5.º. Tiros libres lanzados: 12, 10, 8, 14, 16. Tiros libres encestados: 9, 7, 5, 10, 12.)

- Soporte: tabla: Tabla transcrita en línea dentro del enunciado, con todas sus celdas en orden (CORRECCIONES_OCR.md §3). — docs/examenes/oficiales/2026_comun_ordinaria.pdf, pág. 13
- Solución modelo: 1) Tiros lanzados: 12 + 10 + 8 + 14 + 16 = 60. Encestados: 9 + 7 + 5 + 10 + 12 = 43. 2) Probabilidad estimada = frecuencia relativa = encestados / lanzados. Resultado: 43/60 (≈ 0,72).
- Criterio (oficial): 1 = Calcula correctamente la probabilidad estimada. · 0,5 = Plantea bien el procedimiento, pero comete un error. · 0 = No calcula correctamente la probabilidad.

### 4.60 Matemáticas · Proporcionalidad inversa / trabajo conjunto (1 en los exámenes)

**OF.2024.O-M15** · MAT.POR.PROP Proporcionalidad directa · entrena: no · ancla: plantilla `MAT.POR.PROP.G02`, nivel que la reproduce ninguno — No reproducible: el generador solo hace proporcionalidad directa.

> Alonso tarda 15 días en pintar la fachada de un edificio. Alberto tarda 30 días en pintar la misma fachada. Si la pintasen juntos, ¿cuántos días tardarían en terminar el trabajo?

- Soporte: —
- Solución modelo: 1) En un día, Alonso pinta 1/15 de la fachada y Alberto 1/30. 2) Juntos: 1/15 + 1/30 = 3/30 = 1/10 al día. 3) Tardan 1 : (1/10) días. Resultado: 10 días.
- Criterio (propio): 1 = Suma las fracciones de trabajo diario y responde correctamente. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.61 Matemáticas · Valor posicional (1 en los exámenes)

**OF.2024.O-M13** · MAT.NUM.VALPOS Valor posicional y redondeo · entrena: no

> Descomponga de forma polinómica las siguientes cantidades:
> a) 90.670.304 =
> b) 40.500 =
> c) 809.705 =

- Soporte: —
- Solución modelo: 1) Se multiplica cada cifra por la potencia de 10 de su posición. Resultado: a) 9 · 10⁷ + 6 · 10⁵ + 7 · 10⁴ + 3 · 10² + 4; b) 4 · 10⁴ + 5 · 10²; c) 8 · 10⁵ + 9 · 10³ + 7 · 10² + 5.
- Criterio (propio): 1 = Descompone correctamente los 3 elementos. · 0,5 = Comete un error en uno de los 3 elementos. · 0 = Comete más de un error o no completa la actividad.

### 4.62 Matemáticas · m.c.d. en contexto (1 en los exámenes)

**OF.2022.O-M11** · MAT.DIV.MCD Máximo común divisor · entrena: si · ancla: plantilla `MAT.DIV.MCD.G01`, nivel que la reproduce 4 — Plantilla en borrador: el nivel 4 (3 números de 2 a 40) reproduce el perfil, sin el contexto.

> María quiere hacer varios collares. Tiene 24 abalorios blancos, 12 rojos y 18 azules. Si quiere poner la misma cantidad de abalorios de cada color en cada collar, ¿de qué forma pondrá más abalorios en cada uno?

- Soporte: —
- Solución modelo: 1) Para repartir por igual cada color en los collares, el número de collares debe dividir a 24, 12 y 18. 2) m.c.d.(24, 12, 18) = 6. 3) 24 : 6 = 4 blancos; 12 : 6 = 2 rojos; 18 : 6 = 3 azules. Resultado: 6 collares, cada uno con 4 blancos, 2 rojos y 3 azules (9 abalorios). Nota de la app: el enunciado pide «más abalorios en cada uno», pero repartir cada color por igual entre los collares lleva al m.c.d. (6 collares de 9 abalorios). Se aceptan también, si se justifican, los otros repartos en collares iguales (3 collares de 18, 2 de 27) y un solo collar con los 54 abalorios, que es literalmente el que más lleva.
- Criterio (propio): 1 = Aplica el m.c.d. y da el reparto correcto. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

### 4.63 Matemáticas · Ángulos (1 en los exámenes)

**OF.2017.O-M13** · MAT.GEO.ANG Ángulos · entrena: no

> a) ¿Cuántos grados debería tener un ángulo para ser complementario de un ángulo de 80 grados?
> b) ¿Cuántos grados debería tener un ángulo para ser suplementario de un ángulo de 25 grados?

- Soporte: —
- Solución modelo: 1) Complementarios suman 90°: 90° − 80° = 10°. 2) Suplementarios suman 180°: 180° − 25° = 155°. Resultado: a) 10°; b) 155°.
- Criterio (propio): 1 = Calcula correctamente los dos ángulos. · 0,5 = Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado. · 0 = No plantea correctamente el problema o no responde.

## 5. Generadores y plantillas

24 generadores de código y 88 plantillas (83 aprobadas, 5 en borrador). Cada plantilla genera `<id>#<semilla>` de forma determinista. Propiedades comunes a todas: 1000 semillas por plantilla: cada ítem pasa el validador, no deja marcadores sin rellenar, es determinista y su clave pertenece al espacio enumerado; distractores distintos de la solución y entre sí, por texto y por valor; dificultad creciente 1→6 (complejidad media de 200 semillas). TESTING.md §10 y §12; criterio de aprobación D-095.

**Ejemplos:** este entorno no puede compilar Swift, así que no se ha generado ningún ítem. Los únicos ejemplos con semilla fija documentados son los 20 de la muestra de `docs/AUDITORIA_05E.md` §4, que `EjemplosResueltosTests.muestraAuditoria` usa con esas semillas: se dan con su resumen de una línea. El enunciado, las opciones, la solución y los pasos completos requieren ejecutar en el Mac. La auditoría es de la parte 1 de la 05E: la parte 2 cambió alguna tabla (D-098), así que el ítem actual puede diferir.

### analisisVerbal

Código: `Educulter/Core/Content/Generadores/GeneradoresGramatica.swift:567` · mecánicas: ruedas · estado: mixto (ver plantillas)

Plantillas: `LEN.VER.ANALISIS.G01` (ruedas, d2, peldaño 2, borrador); `LEN.VER.ANALISIS.G02` (ruedas, d1, peldaño 1, aprobada); `LEN.VER.ANALISIS.G03` (ruedas, d2, peldaño 2, aprobada); `LEN.VER.ANALISIS.G04` (ruedas, d3, peldaño 3, aprobada); `LEN.VER.ANALISIS.G05` (ruedas, d4, peldaño 4, aprobada); `LEN.VER.ANALISIS.G06` (ruedas, d5, peldaño 5, aprobada).

**Qué cambia:**

Análisis de formas verbales con ruedas: persona, número, tiempo y modo y, con el parámetro
`rasgos = completo` (Fase 05E), también aspecto (perfecto o imperfecto) y forma (simple o
compuesta). Solo se preguntan formas que no son ambiguas dentro del paradigma del nivel (p. ej.,
«cantaba» es 1.ª y 3.ª persona, así que no se pregunta).

Solo verbos regulares de las tres conjugaciones: los irregulares de `verbos.json` no tienen una
tabla completa revisada (Fase 05E, §5) y los copulativos solo sirven a las oraciones.

| Dif. | Verbos | Tiempos |
|---|---|---|
| 1 | en -ar | presente, pretérito perfecto simple y futuro (indicativo) |
| 2 | tres conjugaciones | + imperfecto y condicional |
| 3 | tres conjugaciones | + presente de subjuntivo y pretérito perfecto compuesto |
| 4 (examen) | tres conjugaciones | todos los de indicativo (salvo el pretérito anterior) y de subjuntivo en -ra con sus compuestos |
| 5 | tres conjugaciones | + imperfecto en -se, pluscuamperfecto con «hubiese» y pretérito anterior |
| 6 | tres conjugaciones | + futuro simple y compuesto de subjuntivo |

Parámetros de las plantillas: `LEN.VER.ANALISIS.G02` {"rasgos": "basico"}; `LEN.VER.ANALISIS.G03` {"rasgos": "basico"}; `LEN.VER.ANALISIS.G04` {"rasgos": "completo"}; `LEN.VER.ANALISIS.G05` {"rasgos": "completo"}; `LEN.VER.ANALISIS.G06` {"rasgos": "completo"}.

**Cómo se valida:**
- Oráculo: Oráculo: tabla de conjugación por reglas escrita en el test, contrastada con los paradigmas de amar, temer y partir escritos a mano; 1000 semillas × 6 niveles (D-093, TESTING §14).
- Ambigüedad: Solo formas no ambiguas dentro del paradigma del nivel («cantaba» no se pregunta); solo verbos regulares (D-093).
- Pasos resueltos: sin pasos resueltos (D-112)
- Anclas al examen: OF.2024.O-L5 → nivel 4; OF.2019.O-L6 → nivel 4; OF.2022.O-L4 → nivel 4; OF.2017.O-L6 → nivel 4; OF.2019.A-L6 → nivel 4.

**Errores que modelan sus distractores:** ERR.LEN.VER.ANALISIS.1, ERR.LEN.VER.ANALISIS.2, ERR.LEN.VER.ANALISIS.3, ERR.LEN.VER.ANALISIS.4.

**Ejemplos (origen: test):**
- `LEN.VER.ANALISIS.G04#13` · dificultad 3 · peldaño 3: «dibujasteis»: análisis completo y explica el aspecto (porqué).

### clasificarAcentuacion

Código: `Educulter/Core/Content/Generadores/GeneradoresLengua.swift:248` · mecánicas: clasificar · estado: aprobado

Plantillas: `LEN.ORT.AGU.G03` (clasificar, d2, peldaño 2, aprobada).

**Qué cambia:**

Aguda, llana, esdrújula o sobresdrújula (elección). Las palabras se muestran bien escritas.

**Cómo se valida:**
- Oráculo: Oráculo independiente: contador de núcleos vocálicos y reglas generales de acentuación (TESTING §12).
- Ambigüedad: Excluye las 70 palabras ambiguas (D-092).
- Pasos resueltos: sin pasos resueltos (D-112)

**Errores que modelan sus distractores:** ERR.LEN.ORT.AGU.2.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### colocarTilde

Código: `Educulter/Core/Content/Generadores/GeneradoresLengua.swift:217` · mecánicas: colocarTilde · estado: aprobado

Plantillas: `LEN.ORT.AGU.G01` (colocarTilde, d2, peldaño 2, aprobada); `LEN.ORT.AGU.G02` (colocarTilde, d3, peldaño 3, aprobada).

**Qué cambia:**

Colocar (o no) la tilde en palabras del léxico. Dificultad: nivel de la palabra
(1 bisílabas regulares · 2 trisílabas · 3 esdrújulas · 4 hiatos · 5 finales especiales o
4+ sílabas · 6 sobresdrújulas o 5+ sílabas).

**Cómo se valida:**
- Oráculo: Oráculo independiente: contador de núcleos vocálicos y reglas generales de acentuación; léxico con 0 discrepancias (TESTING §12, LexicoTests).
- Ambigüedad: Excluye las 70 palabras ambiguas (otra forma válida con otra tilde; Content/ambiguas.json, D-092).
- Pasos resueltos: sin pasos resueltos (D-112)
- Anclas al examen: OF.2024.O-L7 → nivel — (no reproducible).

**Errores que modelan sus distractores:** ERR.LEN.ORT.AGU.1, ERR.LEN.ORT.AGU.3, ERR.LEN.ORT.AGU.4, ERR.LEN.ORT.AGU.5.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### conversionUnidades

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02B.swift:21` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.UNI.LMC.G01` (numerico, d2, peldaño 2, aprobada); `MAT.UNI.LMC.G02` (numerico, d3, peldaño 3, aprobada); `MAT.UNI.SUP.G01` (numerico, d3, peldaño 3, aprobada); `MAT.UNI.VOL.G01` (numerico, d3, peldaño 3, aprobada).

**Qué cambia:**

Conversión de unidades por familia (`parametros.familia`): `lmc` (longitud, masa y capacidad,
MAT.UNI.LMC), `sup` (superficie, MAT.UNI.SUP) y `vol` (volumen y capacidad, MAT.UNI.VOL).

| Dif. | lmc | sup | vol |
|---|---|---|---|
| 1 | 1 cambio habitual (m → cm, kg → g, l → ml) | 1 salto (×100) | 1 salto (×1000) |
| 2 | 2–3 saltos, en los dos sentidos | 2 saltos | 2 saltos |
| 3 | compleja → incompleja («3 km 25 m = ? m») | compleja → incompleja | volumen ↔ capacidad (1 dm³ = 1 l) |
| 4 | examen: compleja de 3 términos → unidad intermedia (2022 M14) | compleja → unidad mayor | compleja → unidad mayor |
| 5 | suma de 3 cantidades con decimales | suma con decimales | volumen ↔ capacidad con saltos y decimales |
| 6 | capacidad → masa de agua (1 l = 1 kg) | unidades agrarias (ha, a, ca) | volumen → capacidad → masa de agua |

Parámetros de las plantillas: `MAT.UNI.LMC.G01` {"familia": "lmc"}; `MAT.UNI.LMC.G02` {"familia": "lmc"}; `MAT.UNI.SUP.G01` {"familia": "sup"}; `MAT.UNI.VOL.G01` {"familia": "vol"}.

**Cómo se valida:**
- Oráculo: Oráculo independiente: unidades con su tabla de factores (TESTING §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2022.O-M14 → nivel 4; OF.2024.O-M16 → nivel 5 (no reproducible); OF.2017.O-M18 → nivel 2 (no reproducible); OF.2026.O-M14 → nivel 3 (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.UNI.LMC.1, ERR.MAT.UNI.LMC.2, ERR.MAT.UNI.LMC.3, ERR.MAT.UNI.LMC.4, ERR.MAT.UNI.SUP.1, ERR.MAT.UNI.SUP.2, ERR.MAT.UNI.SUP.3, ERR.MAT.UNI.SUP.4, ERR.MAT.UNI.VOL.1, ERR.MAT.UNI.VOL.2, ERR.MAT.UNI.VOL.3, ERR.MAT.UNI.VOL.4, ERR.MAT.UNI.VOL.5.

**Ejemplos (origen: test):**
- `MAT.UNI.LMC.G02#10` · dificultad 3 · peldaño 3: 2 kl 93 dl en cl: conversión de cada término (procedimiento).
- `MAT.UNI.VOL.G01#5` · dificultad 3 · peldaño 3: 32 dal en cm³: da la equivalencia 1 dm³ = 1 l, pero no la cadena dal → l → cm³; solo solución en la práctica.
- `MAT.UNI.VOL.G01#15` · dificultad 3 · peldaño 3: 51 dm³ en litros: correcto pero trivial para su dificultad 3 (un solo paso, 1 dm³ = 1 l).

### ecuacionLineal

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02C.swift:522` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.OPE.ECUAC.G01` (numerico, d2, peldaño 2, aprobada); `MAT.OPE.ECUAC.G02` (numerico, d3, peldaño 3, aprobada); `MAT.OPE.ECUAC.G03` (numerico, d4, peldaño 4, aprobada).

**Qué cambia:**

Ecuaciones de primer grado con solución entera (MAT.OPE.ECUAC).

| Dif. | Ecuación |
|---|---|
| 1 | x + a = b |
| 2 | ax = b |
| 3 | ax + b = c (o ax − b = c) |
| 4 | incógnita en los dos miembros |
| 5 | paréntesis |
| 6 | problema con enunciado («el triple de un número menos 7 es 20») |

**Cómo se valida:**
- Oráculo: Oráculo independiente: fuerza bruta (TESTING §10 y §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)

**Errores que modelan sus distractores:** ERR.MAT.OPE.ECUAC.1, ERR.MAT.OPE.ECUAC.2, ERR.MAT.OPE.ECUAC.3, ERR.MAT.OPE.ECUAC.4.

**Ejemplos (origen: test):**
- `MAT.OPE.ECUAC.G01#2` · dificultad 2 · peldaño 2: 9x = 45: solución y comprobación, sin el paso (dividir entre 9).
- `MAT.OPE.ECUAC.G03#4` · dificultad 4 · peldaño 4: 8x + 4 = x + 109: igual, sin la transposición; no tiene errores habituales.

### escala

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02B.swift:559` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.UNI.ESC.G01` (numerico, d3, peldaño 3, aprobada); `MAT.UNI.ESC.G02` (numerico, d4, peldaño 4, aprobada).

**Qué cambia:**

Escalas de mapas y planos (MAT.UNI.ESC).

| Dif. | Caso |
|---|---|
| 1 | plano 1:100, de cm a m |
| 2 | plano 1:1000 o 1:10 000, de cm a m |
| 3 | mapa 1:10 000 a 1:100 000, de cm a km |
| 4 (examen) | plano 1:20 a 1:1000 con la medida decimal en cm o en mm, resultado en m (2026 O M20) |
| 5 | de la realidad (km) al mapa (cm) |
| 6 | averiguar la escala (distancias enteras o decimales) |

**Cómo se valida:**
- Oráculo: Oráculo independiente: escalas (TESTING §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2026.O-M20 → nivel 4.

**Errores que modelan sus distractores:** ERR.MAT.UNI.ESC.1, ERR.MAT.UNI.ESC.2, ERR.MAT.UNI.ESC.3.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### estadisticaBasica

Código: `Educulter/Core/Content/Generadores/GeneradoresMatematicas.swift:266` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.EST.CENTRAL.G01` (numerico, d2, peldaño 2, aprobada).

**Qué cambia:**

Media, mediana, moda y rango de 5–8 datos.

| Dif. | Datos | Valores | Medidas |
|---|---|---|---|
| 1 | 5 | 1–10 | moda, rango |
| 2 | 5 | 1–10 | + media (entera) |
| 3 | 6 | 1–20 | + mediana (puede ser x,5) |
| 4 | 7 | 1–50 | media con una cifra decimal |
| 5 | 8 | 10–100 | media con hasta dos decimales |
| 6 | 8 | decimales con una cifra (0,5–20) | todas |

Errores: dividir entre n − 1, calcular la mediana sin ordenar, dar el máximo como rango, dar
el valor mayor como moda.

**Cómo se valida:**
- Oráculo: no documentado (oráculo específico); propiedades generales y anclas (D-101).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2019.A-M18 → nivel 4; OF.2019.O-M16 → nivel 4; OF.2026.A-M18 → nivel 4; OF.2022.O-M17 → nivel — (no reproducible); OF.2024.O-M20 → nivel — (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.EST.CENTRAL.1, ERR.MAT.EST.CENTRAL.2, ERR.MAT.EST.CENTRAL.3, ERR.MAT.EST.CENTRAL.4.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### formasNoPersonales

Código: `Educulter/Core/Content/Generadores/GeneradoresLote05E.swift:21` · mecánicas: clasificar, eleccion · estado: aprobado

Plantillas: `LEN.VER.NOPERS.G01` (clasificar, d1, peldaño 1, aprobada); `LEN.VER.NOPERS.G02` (clasificar, d2, peldaño 2, aprobada); `LEN.VER.NOPERS.G03` (eleccion, d3, peldaño 3, aprobada); `LEN.VER.NOPERS.G04` (eleccion, d4, peldaño 4, aprobada); `LEN.VER.NOPERS.G05` (clasificar, d5, peldaño 5, aprobada).

**Qué cambia:**

Formas no personales de verbos regulares: infinitivo, gerundio y participio, simples y
compuestas (haber cantado, habiendo cantado). Mecánicas: `clasificar` (fichas por forma) y
`eleccion` (qué forma es).

| Dif. | Verbos | Formas | Fichas (clasificar) |
|---|---|---|---|
| 1 | en -ar | simples | 4 |
| 2 | tres conjugaciones | simples | 5 |
| 3 | + participios irregulares (escrito, abierto) | simples | 6 |
| 4 | tres conjugaciones | + compuestas (simple o compuesta en `eleccion`) | 6 |
| 5–6 | + participios irregulares | + compuestas | 6 |

**Cómo se valida:**
- Oráculo: Oráculo propio de formasNoPersonales (Fase05ETests, TESTING §14).
- Ambigüedad: no documentado
- Pasos resueltos: sin pasos resueltos (D-112)

**Errores que modelan sus distractores:** ERR.LEN.VER.NOPERS.1, ERR.LEN.VER.NOPERS.2.

**Ejemplos (origen: test):**
- `LEN.VER.NOPERS.G05#17` · dificultad 5 · peldaño 5: clasificar 6 formas: clasifica cada una; la regla está en la pista, no en la explicación; sin errores habituales.

### fraccionBarras

Código: `Educulter/Core/Content/Generadores/GeneradoresMatematicas.swift:56` · mecánicas: fraccionBarras · estado: borrador

Plantillas: `MAT.NUM.FRAREP.G01` (fraccionBarras, d4, peldaño 2, borrador).

**Qué cambia:**

Representar fracciones en una barra.

| Dif. | Modo | Fracción |
|---|---|---|
| 1 | colorear, barra en d partes | d = 2–4 |
| 2 | colorear | d = 2–8 |
| 3 | colorear con equivalentes (barra en k·d partes) | d = 2–6 |
| 4 | dividir y colorear (cualquier partición válida) | d = 2–6 |
| 5 | dividir y colorear en particiones concretas («en 6 o en 9 partes») | d = 2–4 |
| 6 | dividir y colorear; la fracción se da como decimal o porcentaje | d = 2, 4, 5, 10 |

**Cómo se valida:**
- Oráculo: no documentado (oráculo específico); propiedades generales (plantilla en borrador).
- Ambigüedad: no documentado
- Pasos resueltos: sin pasos resueltos (D-112)

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### fraccionesOperar

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02C.swift:772` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.NUM.FRAOP.G01` (numerico, d2, peldaño 2, aprobada); `MAT.NUM.FRAOP.G02` (numerico, d3, peldaño 3, aprobada); `MAT.NUM.FRAOP.G03` (numerico, d4, peldaño 4, aprobada).

**Qué cambia:**

Operar con fracciones; resultado irreducible (MAT.NUM.FRAOP).

| Dif. | Caso |
|---|---|
| 1 | suma o resta con el mismo denominador |
| 2 | denominadores múltiplos |
| 3 | m.c.m. de dos denominadores ≤ 12, o multiplicación y división |
| 4 (examen) | tres o cuatro fracciones con sumas y restas y denominadores distintos (2019 M11) |
| 5 | combinadas sin paréntesis (sumas, productos y cocientes) |
| 6 | combinadas con paréntesis |

**Cómo se valida:**
- Oráculo: Oráculo independiente: evaluador de expresiones propio (TESTING §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2019.O-M11 → nivel 4; OF.2024.O-M12 → nivel 6 (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.NUM.FRAOP.1, ERR.MAT.NUM.FRAOP.2, ERR.MAT.NUM.FRAOP.3.

**Ejemplos (origen: test):**
- `MAT.NUM.FRAOP.G01#0` · dificultad 2 · peldaño 2: 1/2 + 5/6: solo la solución; no muestra el denominador común.

### fraseHueco

Código: `Educulter/Core/Content/Generadores/GeneradoresGramatica.swift:710` · mecánicas: construir, eleccion · estado: aprobado

Plantillas: `LEN.ORT.DIA.G01` (eleccion, d2, peldaño 2, aprobada); `LEN.ORT.PQ.G01` (construir, d3, peldaño 2, aprobada); `LEN.ORT.HOM.G01` (eleccion, d2, peldaño 2, aprobada); `LEN.ORT.HOM.G02` (eleccion, d3, peldaño 3, aprobada).

**Qué cambia:**

Frases con hueco y familia de formas que se confunden (tú/tu, por qué/porque…), en `eleccion`
(opciones = formas de la familia) o `construir` (piezas = formas de la familia). La dificultad
es la de cada frase del banco (o la inferior más próxima con frases).

Parámetros de las plantillas: `LEN.ORT.DIA.G01` {"familias": ["tu_tú", "el_él", "mi_mí", "si_sí", "te_té", "de_dé", "se_sé", "mas_más", "aun_aún", "que_qué", "como_cómo", "cuando_cuándo", "donde_dónde"]}; `LEN.ORT.PQ.G01` {"familias": ["porque"]}; `LEN.ORT.HOM.G01` {"familias": ["hay_ahí_ay", "haber_aver", "echo_hecho", "vaya_valla_baya", "tuvo_tubo", "hola_ola", "botar_votar", "grabar_gravar", "sabia_savia", "revelar_rebelar", "hasta_asta", "halla_haya", "hierba_hierva", "bello_vello"]}; `LEN.ORT.HOM.G02` {"familias": ["hay_ahí_ay", "haber_aver", "echo_hecho", "vaya_valla_baya", "tuvo_tubo", "hola_ola", "botar_votar", "grabar_gravar", "sabia_savia", "revelar_rebelar", "hasta_asta", "halla_haya", "hierba_hierva", "bello_vello"]}.

**Cómo se valida:**
- Oráculo: FrasesHuecoTests: 1000 semillas por plantilla y nivel; opciones o piezas = formas de la familia, la correcta una sola vez, explicación con el uso, frase del nivel pedido; sin frases repetidas en una práctica, ronda, Reto o partida (D-087, D-089, TESTING §13).
- Ambigüedad: Una sola forma correcta por frase (FrasesHuecoTests).
- Pasos resueltos: sin pasos resueltos (D-112)
- Anclas al examen: OF.2022.O-L9 → nivel 4; OF.2026.A-L7 → nivel 4.

**Errores que modelan sus distractores:** ERR.LEN.ORT.DIA.1, ERR.LEN.ORT.DIA.2, ERR.LEN.ORT.HOM.1, ERR.LEN.ORT.HOM.2, ERR.LEN.ORT.PQ.1.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### literatura

Código: `Educulter/Core/Content/Generadores/GeneradoresLote05E.swift:120` · mecánicas: clasificar, eleccion, emparejar, ordenar · estado: aprobado

Plantillas: `LEN.LIT.HIST.G01` (eleccion, d1, peldaño 1, aprobada); `LEN.LIT.HIST.G02` (emparejar, d2, peldaño 2, aprobada); `LEN.LIT.HIST.G03` (ordenar, d2, peldaño 2, aprobada); `LEN.LIT.HIST.G04` (eleccion, d3, peldaño 3, aprobada); `LEN.LIT.HIST.G05` (ordenar, d4, peldaño 5, aprobada); `LEN.LIT.UNIV.G01` (emparejar, d2, peldaño 2, aprobada); `LEN.LIT.UNIV.G02` (eleccion, d3, peldaño 3, aprobada); `LEN.LIT.UNIV.G03` (ordenar, d4, peldaño 5, aprobada); `LEN.LIT.INF.G01` (emparejar, d2, peldaño 2, aprobada); `LEN.LIT.INF.G02` (eleccion, d3, peldaño 3, aprobada); `LEN.LIT.INF.G03` (ordenar, d4, peldaño 4, aprobada); `LEN.LIT.GEN.G01` (clasificar, d1, peldaño 1, aprobada); `LEN.LIT.GEN.G02` (clasificar, d3, peldaño 3, aprobada); `LEN.LIT.GEN.G03` (clasificar, d5, peldaño 5, aprobada).

**Qué cambia:**

Preguntas sobre la base literaria del lote 05a (D-078, D-079). Solo datos de la base; las
reglas de la Fase 05E (§5):
- autor ↔ obra (`emparejar`, 4 parejas): sin obras anónimas ni de autoría discutida (autores
anónimos o con fechas aproximadas);
- obra → movimiento o siglo (`eleccion`): solo obras con año; la de movimiento, solo si el año
está dentro del rango del movimiento (D-079) y con distractores de movimientos vecinos cuyo
rango no contiene ese año; la de siglo, sin años de cambio de siglo;
- línea del tiempo (`ordenar`, 4 autores por nacimiento o 4 movimientos por inicio): nunca fechas
aproximadas y al menos 15 años entre fechas consecutivas;
- género de la obra (`clasificar`): sin las greguerías (su género es una convención).

Parámetros: `ambitos` (espanola, hispanoamericana, universal, infantil), `pregunta`
(`movimiento` o `siglo` en `eleccion`; `autores` o `movimientos` en `ordenar`).

Parámetros de las plantillas: `LEN.LIT.HIST.G01` {"ambitos": ["espanola"], "pregunta": "siglo"}; `LEN.LIT.HIST.G02` {"ambitos": ["espanola"]}; `LEN.LIT.HIST.G03` {"ambitos": ["espanola"], "pregunta": "movimientos"}; `LEN.LIT.HIST.G04` {"ambitos": ["espanola"], "pregunta": "movimiento"}; `LEN.LIT.HIST.G05` {"ambitos": ["espanola"], "pregunta": "autores"}; `LEN.LIT.UNIV.G01` {"ambitos": ["universal", "hispanoamericana"]}; `LEN.LIT.UNIV.G02` {"ambitos": ["universal", "hispanoamericana"], "pregunta": "siglo"}; `LEN.LIT.UNIV.G03` {"ambitos": ["universal", "hispanoamericana"], "pregunta": "autores"}; `LEN.LIT.INF.G01` {"ambitos": ["infantil"]}; `LEN.LIT.INF.G02` {"ambitos": ["infantil"], "pregunta": "siglo"}; `LEN.LIT.INF.G03` {"ambitos": ["infantil"], "pregunta": "autores"}.

**Cómo se valida:**
- Oráculo: Oráculo propio de literatura sobre la base literaria (Fase05ETests, TESTING §14; reglas de D-094).
- Ambigüedad: Sin autores anónimos ni con fechas aproximadas en autor ↔ obra; ningún título compartido entre autores («Soledades»); movimiento solo si el año está en su rango; siglo sin años …00 y …01; ≥ 15 años entre fechas al ordenar; sin greguerías (D-094).
- Pasos resueltos: sin pasos resueltos (D-112)
- Anclas al examen: OF.2017.O-L8 → nivel 4; OF.2019.A-L9 → nivel 4; OF.2019.O-L9 → nivel 4.

**Errores que modelan sus distractores:** ERR.LEN.LIT.HIST.1, ERR.LEN.LIT.HIST.2, ERR.LEN.LIT.INF.1, ERR.LEN.LIT.UNIV.1.

**Ejemplos (origen: test):**
- `LEN.LIT.UNIV.G01#2` · dificultad 2 · peldaño 2: autor ↔ obra: correcto; la explicación es el dato con su año (no hay porqué que dar).
- `LEN.LIT.UNIV.G02#15` · dificultad 3 · peldaño 3: siglo de «Crimen y castigo»: correcto; explica el rango del siglo (porqué).

### mcmMcd

Código: `Educulter/Core/Content/Generadores/GeneradoresMatematicas.swift:132` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.DIV.MCD.G01` (numerico, d3, peldaño 2, aprobada).

**Qué cambia:**

Mínimo común múltiplo y máximo común divisor, con y sin contexto.

| Dif. | Números | Contexto |
|---|---|---|
| 1 | 2 números de 2 a 12 | no |
| 2 | 2 números de 4 a 30 | no |
| 3 | 2 números de 6 a 60 | coincidencias (m.c.m.) o repartos (m.c.d.) |
| 4 | 3 números de 2 a 40 | no |
| 5 | 3 números de 6 a 100 | sí |
| 6 | 3 números de 2 a 12; múltiplo común entre dos cotas («entre 300 y 350») | sí |

Errores: multiplicar los números; confundir m.c.m. y m.c.d.; dar el mayor (o el menor) número.

Parámetros de las plantillas: `MAT.DIV.MCD.G01` {"operacion": "mcd"}.

**Cómo se valida:**
- Oráculo: Oráculo independiente: m.c.m./m.c.d. propios (TESTING §10); anclas (D-101).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2022.O-M11 → nivel 4; OF.2017.O-M17 → nivel 3 (no reproducible); OF.2024.O-M14 → nivel 6 (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.DIV.MCD.1, ERR.MAT.DIV.MCD.2.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### operacionesCombinadas

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02C.swift:401` · mecánicas: numerico, ordenar · estado: aprobado

Plantillas: `MAT.OPE.JER.G01` (numerico, d2, peldaño 2, aprobada); `MAT.OPE.JER.G02` (ordenar, d3, peldaño 3, aprobada); `MAT.OPE.COMB.G01` (ordenar, d3, peldaño 3, aprobada); `MAT.OPE.COMB.G02` (numerico, d4, peldaño 4, aprobada).

**Qué cambia:**

Operaciones combinadas. `parametros.agrupaciones` = false (MAT.OPE.JER, solo jerarquía) o
true (MAT.OPE.COMB). Con `ordenar` se ordenan los pasos; con `numerico`, se da el resultado.

| Dif. | JER (sin agrupaciones) | COMB |
|---|---|---|
| 1 | 3 números, + y × | 3 números con paréntesis |
| 2 | 4 números, + − × : (división exacta) | 4 números con paréntesis |
| 3 | 5 números | paréntesis (uno o dos) |
| 4 (examen) | 6 números | paréntesis y corchetes, 7 operaciones con números de hasta dos cifras (2019 M20) |
| 5 | 5 números y una potencia | llaves y potencias |
| 6 | 4 fracciones | fracciones con paréntesis |

Parámetros de las plantillas: `MAT.OPE.JER.G01` {"agrupaciones": false}; `MAT.OPE.JER.G02` {"agrupaciones": false}; `MAT.OPE.COMB.G01` {"agrupaciones": true}; `MAT.OPE.COMB.G02` {"agrupaciones": true}.

**Cómo se valida:**
- Oráculo: Oráculo independiente: evaluador de expresiones propio (TESTING §10 y §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2022.O-M13 → nivel — (no reproducible); OF.2019.O-M20 → nivel 4; OF.2019.A-M20 → nivel 4; OF.2017.O-M19 → nivel 4; OF.2026.A-M20 → nivel 5 (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.OPE.COMB.1, ERR.MAT.OPE.COMB.2, ERR.MAT.OPE.JER.1, ERR.MAT.OPE.JER.2.

**Ejemplos (origen: test):**
- `MAT.OPE.JER.G02#4` · dificultad 3 · peldaño 3: ordenar los pasos: regla de la jerarquía y pasos (porqué).

### oracionSimple

Código: `Educulter/Core/Content/Generadores/GeneradoresGramatica.swift:174` · mecánicas: clasificar, eleccion, marcarTexto, segmentar · estado: mixto (ver plantillas)

Plantillas: `LEN.CLA.SUSTADJ.G01` (clasificar, d2, peldaño 2, borrador); `LEN.SIN.COMPL.G01` (segmentar, d3, peldaño 2, borrador); `LEN.SIN.COMPL.G02` (eleccion, d4, peldaño 2, borrador); `LEN.SIN.SUJPRED.G01` (marcarTexto, d1, peldaño 1, aprobada); `LEN.SIN.SUJPRED.G02` (segmentar, d2, peldaño 2, aprobada); `LEN.SIN.SUJPRED.G03` (marcarTexto, d5, peldaño 3, aprobada); `LEN.SIN.SUJPRED.G04` (eleccion, d4, peldaño 4, aprobada); `LEN.SIN.SUJPRED.G05` (marcarTexto, d6, peldaño 5, aprobada); `LEN.SIN.COMPL.G03` (eleccion, d2, peldaño 1, aprobada); `LEN.SIN.COMPL.G04` (clasificar, d3, peldaño 2, aprobada); `LEN.SIN.COMPL.G05` (eleccion, d4, peldaño 3, aprobada); `LEN.SIN.COMPL.G06` (eleccion, d4, peldaño 4, aprobada); `LEN.SIN.COMPL.G07` (segmentar, d4, peldaño 5, aprobada); `LEN.SIN.CLASE.G01` (eleccion, d2, peldaño 2, aprobada); `LEN.SIN.CLASE.G02` (eleccion, d4, peldaño 3, aprobada); `LEN.SIN.CLASE.G03` (eleccion, d5, peldaño 5, aprobada).

**Qué cambia:**

Oraciones simples construidas con piezas tipadas y concordancia (sujeto y verbo en número;
atributo en género y número). El análisis correcto se conoce por construcción y sirve para
`segmentar` (funciones), `clasificar` (clases de palabras) y `eleccion` (función de un sintagma).
Con `compatibilidad.json` (lote 02b, D-086) las oraciones salen de sus etiquetas semánticas:
ver `construirCompatible`. Sin ese archivo se usan las piezas de `piezas.json`.

Con `compatibilidad.json`, la estructura de cada nivel es la de D-090 (`Estructura.nivel`):
1 S + V intransitivo · 2 S + V + CD · 3 S + V + CC · 4 copulativa · 5 S + V + CD + CI o dos CC ·
6 CC delante con coma y sujeto pospuesto. Sin ese archivo (solo `piezas.json`):

| Dif. | Estructura |
|---|---|
| 1 | S + V intransitivo (+ 1 CC) |
| 2 | S + V + CD |
| 3 | S + V + CD + CC, o intransitivo + 2 CC |
| 4 | S + V copulativo + Atributo (+ CC), o S + V + CD + CI |
| 5 | S + V + CD (+ adj) + CI + CC |
| 6 | S + V + CD (+ CI) + 2 CC |

Parámetros de las plantillas: `LEN.SIN.SUJPRED.G01` {"modo": "sujeto"}; `LEN.SIN.SUJPRED.G02` {"modo": "sujetoPredicado"}; `LEN.SIN.SUJPRED.G03` {"modo": "sujeto"}; `LEN.SIN.SUJPRED.G04` {"modo": "concordancia"}; `LEN.SIN.SUJPRED.G05` {"modo": "sujeto"}; `LEN.SIN.COMPL.G03` {"modo": "funcion"}; `LEN.SIN.COMPL.G04` {"modo": "funciones"}; `LEN.SIN.COMPL.G05` {"modo": "funcion"}; `LEN.SIN.COMPL.G06` {"modo": "pronombre"}; `LEN.SIN.COMPL.G07` {"modo": "completo"}; `LEN.SIN.CLASE.G01` {"modo": "clase"}; `LEN.SIN.CLASE.G02` {"modo": "clase"}; `LEN.SIN.CLASE.G03` {"modo": "clase"}.

**Cómo se valida:**
- Oráculo: Oráculo de GramaticaCompatibilidadTests: reconstruye la oración y su análisis a partir de la estructura y de compatibilidad.json, sin leer el texto; 1000 semillas por plantilla y nivel (D-090, D-099, TESTING §13–14).
- Ambigüedad: Reglas de naturalidad y concordancia de D-090 y D-099 (revisión de 300 oraciones: 3 forzadas, 1 %).
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2026.O-L10 → nivel 4; OF.2026.A-L10 → nivel 4; OF.2017.O-L9 → nivel 5 (no reproducible); OF.2024.O-L10 → nivel 5 (no reproducible); OF.2019.A-L10 → nivel — (no reproducible); OF.2019.O-L10 → nivel — (no reproducible); OF.2022.O-L10 → nivel — (no reproducible).

**Errores que modelan sus distractores:** ERR.LEN.SIN.CLASE.1, ERR.LEN.SIN.CLASE.2, ERR.LEN.SIN.COMPL.1, ERR.LEN.SIN.COMPL.2, ERR.LEN.SIN.COMPL.3, ERR.LEN.SIN.COMPL.4, ERR.LEN.SIN.COMPL.5, ERR.LEN.SIN.COMPL.6, ERR.LEN.SIN.SUJPRED.1.

**Ejemplos (origen: test):**
- `LEN.SIN.COMPL.G03#6` · dificultad 2 · peldaño 1: función de «La alumna»: correcto; da la regla de la concordancia (porqué). Muy fácil en el nivel 1 (sujeto al principio).

### ordenarNumeros

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02C.swift:662` · mecánicas: ordenar · estado: aprobado

Plantillas: `MAT.NUM.ORDEN.G01` (ordenar, d2, peldaño 2, aprobada); `MAT.NUM.ORDEN.G02` (ordenar, d3, peldaño 3, aprobada).

**Qué cambia:**

Ordenar de menor a mayor (MAT.NUM.ORDEN).

| Dif. | Cantidad | Números |
|---|---|---|
| 1 | 4 | decimales con una cifra decimal |
| 2 | 4 | decimales con dos cifras decimales |
| 3 | 5 | decimales con distinto número de cifras (0,5 frente a 0,45), o fracciones con el mismo denominador o numerador |
| 4 (examen) | 4 | fracciones (denominador ≤ 24, también impropias) y decimales (1–3 cifras) mezclados |
| 5 | 5 | mezclados, todos entre dos enteros consecutivos (valores muy cercanos) |
| 6 | 6 | con negativos y fracciones impropias |

Calibración de la Fase 05E (`Content/calibracion/anclas.json`): el nivel 4 reproduce el perfil
de las preguntas oficiales de ordenar (2017 M11, 2019 M14, 2026 A M14).

**Cómo se valida:**
- Oráculo: no documentado (oráculo específico); se aplican las propiedades generales; espacio limitado a 2000 (TESTING §10).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2017.O-M11 → nivel 4; OF.2019.A-M14 → nivel 4; OF.2019.O-M14 → nivel 4; OF.2026.A-M14 → nivel 4; OF.2022.O-M12 → nivel 3 (no reproducible); OF.2024.O-M11 → nivel — (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.NUM.ORDEN.1.

**Ejemplos (origen: test):**
- `MAT.NUM.ORDEN.G02#1` · dificultad 3 · peldaño 3: ordenar 5 decimales: solo la solución; cómo comparar está en el error habitual, no en la explicación.

### porcentajeDe

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02A.swift:23` · mecánicas: construir, numerico · estado: aprobado

Plantillas: `MAT.POR.CALC.G01` (numerico, d2, peldaño 2, aprobada); `MAT.POR.CALC.G02` (numerico, d3, peldaño 3, aprobada); `MAT.POR.TOTAL.G01` (numerico, d3, peldaño 3, aprobada); `MAT.POR.VAR.G01` (numerico, d3, peldaño 3, aprobada); `MAT.POR.VAR.G02` (construir, d4, peldaño 4, aprobada).

**Qué cambia:**

Porcentajes por competencia (`parametros.variante`): `calc` (MAT.POR.CALC), `total`
(MAT.POR.TOTAL) y `var` (MAT.POR.VAR).

| Dif. | Porcentajes | Base | Pasos |
|---|---|---|---|
| 1 | 10, 50 | múltiplos de 10 hasta 200 | 1 |
| 2 | 25, 20, 5 | múltiplos de 20 hasta 400 | 1 |
| 3 | 15, 30, 40, 75 | hasta 1000, resultado entero | 1 |
| 4 (examen) | 12, 15, 22, 35, 60, 12,5 | de 100 a 2000, ≤ 2 decimales | 1–2 |
| 5 | 1–99 | hasta 5000 | 2 |
| 6 | `var`: dos variaciones encadenadas; `total`: precio original tras una rebaja; `calc`: % con medios | hasta 10 000 | 2–3 |

Parámetros de las plantillas: `MAT.POR.CALC.G01` {"variante": "calc"}; `MAT.POR.CALC.G02` {"variante": "calc"}; `MAT.POR.TOTAL.G01` {"variante": "total"}; `MAT.POR.VAR.G01` {"variante": "var"}; `MAT.POR.VAR.G02` {"variante": "var"}.

**Cómo se valida:**
- Oráculo: Oráculo independiente: fórmulas propias de porcentajes (TESTING §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2022.O-M16 → nivel 4; OF.2026.O-M16 → nivel 4; OF.2017.O-M16 → nivel 4.

**Errores que modelan sus distractores:** ERR.MAT.POR.CALC.1, ERR.MAT.POR.CALC.2, ERR.MAT.POR.TOTAL.1, ERR.MAT.POR.TOTAL.2, ERR.MAT.POR.TOTAL.3, ERR.MAT.POR.TOTAL.4, ERR.MAT.POR.VAR.1, ERR.MAT.POR.VAR.2, ERR.MAT.POR.VAR.3, ERR.MAT.POR.VAR.4, ERR.MAT.POR.VAR.5.

**Ejemplos (origen: test):**
- `MAT.POR.CALC.G02#17` · dificultad 3 · peldaño 3: 40 % de 155: procedimiento (155 × 40 : 100) sin decir por qué.

### probabilidadSimple

Código: `Educulter/Core/Content/Generadores/GeneradoresMatematicas.swift:384` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.PRO.LAPLACE.G01` (numerico, d3, peldaño 2, aprobada).

**Qué cambia:**

Probabilidad de Laplace en fracción: dados, bolsas y tarjetas.

| Dif. | Experimento |
|---|---|
| 1 | un dado: par, impar, mayor que k, igual a k |
| 2 | bolsa con bolas de 2 colores |
| 3 | bolsa de 3 colores; también «no sacar» un color (contrario) |
| 4 | tarjetas numeradas de 1 a n (n = 8–20): par, primo, múltiplo de k |
| 5 | dos dados: suma igual a s (fracción irreducible) |
| 6 | dos dados: suma mayor que s o dobles (fracción irreducible) |

Errores: favorables entre desfavorables; restar uno a los casos posibles; dar el suceso contrario.

**Cómo se valida:**
- Oráculo: Oráculo independiente: probabilidad propia (TESTING §10); anclas (D-101).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2026.A-M16 → nivel 4; OF.2019.A-M16 → nivel 4.

**Errores que modelan sus distractores:** ERR.MAT.PRO.LAPLACE.1, ERR.MAT.PRO.LAPLACE.2.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### problemaFraccion

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02C.swift:898` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.NUM.FRAPROB.G01` (numerico, d3, peldaño 3, aprobada); `MAT.NUM.FRAPROB.G02` (numerico, d4, peldaño 4, aprobada).

**Qué cambia:**

Problemas de partes de una cantidad (MAT.NUM.FRAPROB): lo que queda tras gastos sucesivos.

| Dif. | Caso |
|---|---|
| 1 | un gasto de fracción unitaria |
| 2 | un gasto de fracción no unitaria |
| 3 | dos gastos: sobre el total, o el segundo sobre lo que queda |
| 4 (examen) | tres gastos, cada uno sobre lo que queda (2019 A M11, 2026 A M11) |
| 5 | tres gastos sobre lo que queda, con fracciones no unitarias y cantidades mayores |
| 6 | cuatro gastos, cada uno sobre lo que queda |

**Cómo se valida:**
- Oráculo: Oráculo independiente: evaluador de expresiones propio (TESTING §12); test de anclas recalcula lo que queda (AnclasTests).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2026.O-M13 → nivel 3 (no reproducible); OF.2026.A-M11 → nivel 4; OF.2019.A-M11 → nivel 4.

**Errores que modelan sus distractores:** ERR.MAT.NUM.FRAPROB.1, ERR.MAT.NUM.FRAPROB.2, ERR.MAT.NUM.FRAPROB.3.

**Ejemplos (origen: test):**
- `MAT.NUM.FRAPROB.G01#13` · dificultad 3 · peldaño 3: dos gastos: procedimiento paso a paso.
- `MAT.NUM.FRAPROB.G02#11` · dificultad 4 · peldaño 4: tres gastos sucesivos: procedimiento paso a paso, claro.

### reglaDeTres

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02A.swift:278` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.POR.PROP.G01` (numerico, d2, peldaño 2, aprobada); `MAT.POR.PROP.G02` (numerico, d3, peldaño 3, aprobada).

**Qué cambia:**

Proporcionalidad directa (MAT.POR.PROP).

| Dif. | Caso |
|---|---|
| 1 | factor ×2 (recetas y precios) |
| 2 | factor ×3 o ×4, cantidades mayores |
| 3 | factor fraccionario con números pequeños (de 4 a 6 personas) |
| 4 | factor fraccionario con números mayores; también velocidad y distancia |
| 5 | reducción a la unidad con decimales (precios y consumo) |
| 6 | dos magnitudes encadenadas (consumo y precio del litro) |

**Cómo se valida:**
- Oráculo: Oráculo independiente: regla de tres propia (TESTING §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2026.A-M15 → nivel 4; OF.2019.A-M15 → nivel 4; OF.2022.O-M19 → nivel 5 (no reproducible); OF.2024.O-M15 → nivel — (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.POR.PROP.1, ERR.MAT.POR.PROP.2, ERR.MAT.POR.PROP.3.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

### romanos

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02C.swift:233` · mecánicas: construir, eleccion, numerico · estado: aprobado

Plantillas: `MAT.ROM.LEER.G01` (numerico, d2, peldaño 2, aprobada); `MAT.ROM.LEER.G02` (eleccion, d3, peldaño 3, aprobada); `MAT.ROM.ESCR.G01` (construir, d2, peldaño 2, aprobada); `MAT.ROM.ESCR.G02` (construir, d3, peldaño 3, aprobada).

**Qué cambia:**

Leer (`numerico`, `eleccion`) y escribir (`construir`) números romanos.

| Dif. | Números |
|---|---|
| 1 | 1–39 |
| 2 | 40–399 (XL, XC) |
| 3 | 400–1999 (CD, CM) |
| 4 (examen) | 300–3999 con al menos un grupo sustractivo (2019 A M19, 2026 A M19) |
| 5 | 1000–3999 con al menos dos grupos sustractivos y, al escribir, siglos |
| 6 | `eleccion`: detectar el romano mal escrito; `numerico` y `construir`: 3 o más grupos sustractivos |

**Cómo se valida:**
- Oráculo: Oráculo independiente: parser de romanos propio (TESTING §10 y §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2019.A-M19 → nivel 4; OF.2026.A-M19 → nivel 4; OF.2017.O-M15 → nivel 4; OF.2019.O-M19 → nivel 4.

**Errores que modelan sus distractores:** ERR.MAT.ROM.ESCR.1, ERR.MAT.ROM.LEER.1, ERR.MAT.ROM.LEER.2, ERR.MAT.ROM.LEER.3.

**Ejemplos (origen: test):**
- `MAT.ROM.ESCR.G02#8` · dificultad 3 · peldaño 3: 613 en romanos: descomposición por órdenes (porqué).

### sexagesimal

Código: `Educulter/Core/Content/Generadores/GeneradoresLote02B.swift:263` · mecánicas: numerico, ruedas · estado: aprobado

Plantillas: `MAT.UNI.TIEM.G01` (numerico, d2, peldaño 2, aprobada); `MAT.UNI.TIEM.G02` (ruedas, d3, peldaño 3, aprobada); `MAT.UNI.TIEM.G03` (ruedas, d4, peldaño 4, aprobada).

**Qué cambia:**

Tiempo en el sistema sexagesimal (MAT.UNI.TIEM). Con `numerico`, el resultado se pide en una
sola unidad; con `ruedas`, en horas, minutos y segundos.

| Dif. | Caso |
|---|---|
| 1 | h → min o min → s (ruedas: min → h y min) |
| 2 | h y min → s (ruedas: s → h, min y s) |
| 3 | sumar dos tiempos (h, min) con llevada, o duración en el mismo día |
| 4 (examen) | sumar tres tiempos escritos sin normalizar («165 min 900 s») y expresarlo en una unidad (2019 A M12, 2026 A M12) |
| 5 | sumar cuatro tiempos sin normalizar |
| 6 | multiplicar un tiempo (h, min, s) por un número, o duración que cruza la medianoche |

**Cómo se valida:**
- Oráculo: Oráculo independiente: cálculo sexagesimal propio (TESTING §12).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2026.A-M12 → nivel 4; OF.2019.A-M12 → nivel 4; OF.2019.O-M12 → nivel 2 (no reproducible).

**Errores que modelan sus distractores:** ERR.MAT.UNI.TIEM.1, ERR.MAT.UNI.TIEM.2, ERR.MAT.UNI.TIEM.3, ERR.MAT.UNI.TIEM.4.

**Ejemplos (origen: test):**
- `MAT.UNI.TIEM.G01#16` · dificultad 2 · peldaño 2: 3 h 11 min en segundos: da las equivalencias (porqué), pero no la cuenta (3 × 3600 + 11 × 60).
- `MAT.UNI.TIEM.G01#2` · dificultad 2 · peldaño 2: 2 h 9 min en segundos: como el 12.

### silabaTonica

Código: `Educulter/Core/Content/Generadores/GeneradoresLengua.swift:323` · mecánicas: marcarTexto · estado: aprobado

Plantillas: `LEN.ORT.AGU.G04` (marcarTexto, d1, peldaño 1, aprobada).

**Qué cambia:**

Marcar la sílaba tónica (marcarTexto por sílabas). En la dificultad 1 la palabra puede llevar
tilde (que delata la tónica); desde la 2 solo se usan palabras sin tilde.

**Cómo se valida:**
- Oráculo: Oráculo independiente: contador de núcleos vocálicos y reglas generales de acentuación (TESTING §12).
- Ambigüedad: Excluye las 70 palabras ambiguas (D-092).
- Pasos resueltos: sin pasos resueltos (D-112)

**Errores que modelan sus distractores:** ERR.LEN.ORT.AGU.1.

**Ejemplos (origen: test):**
- `LEN.ORT.AGU.G04#9` · dificultad 1 · peldaño 1: sílaba tónica de «jugar»: correcto; indica la tónica (porqué), podría añadir por qué no lleva tilde.

### terminoDesconocido

Código: `Educulter/Core/Content/Generadores/GeneradoresLote05E.swift:380` · mecánicas: numerico · estado: aprobado

Plantillas: `MAT.OPE.INCOG.G02` (numerico, d4, peldaño 3, aprobada).

**Qué cambia:**

Término desconocido de una igualdad con una sola operación inversa: «a × x = N», «N : x = a»,
«x + a = N» y «x − a = N». Perfil de las 4 preguntas oficiales «Calcule a y b» (2017 M10, 2019 A
M13, 2019 O M13, 2026 A M13).

| Dif. | Caso |
|---|---|
| 1 | x + a = N y a × x = N con números de 1–2 cifras (tablas) |
| 2 | x − a = N y a × x = N con N de 2–3 cifras |
| 3 | las cuatro formas con N de 3–4 cifras |
| 4 (examen) | las cuatro formas con N de 4–5 cifras |
| 5 | dos igualdades encadenadas: se halla x y con ella y |
| 6 | dos igualdades encadenadas con un factor decimal («1,5 × x = 300») |

**Cómo se valida:**
- Oráculo: Con oráculo y 4 anclas (D-100).
- Ambigüedad: no documentado
- Pasos resueltos: PasosResueltosTests: 1000 semillas, 2–5 pasos, frase ≤ 60, porqué ≤ 70, último paso = solución (D-112)
- Anclas al examen: OF.2017.O-M10 → nivel 4; OF.2019.A-M13 → nivel 4; OF.2019.O-M13 → nivel 4; OF.2026.A-M13 → nivel 4.

**Errores que modelan sus distractores:** ERR.MAT.OPE.INCOG.1, ERR.MAT.OPE.INCOG.2.

**Ejemplos:** no documentado (requiere ejecutar en Mac).

## 6. Teoría

Elementos exportados: tarjeta 26, usoDeLasFormas 28, remedioDeError 93, ejemploResuelto 16. Las tarjetas tienen bloques `texto`, `regla`, `ejemplo`, `esquema` y `truco`; `usoDeLasFormas` es el uso de cada forma de las 28 familias de frases con hueco; `remedioDeError` es la regla breve que se muestra antes del remedio de cada error típico; `ejemploResuelto` es la plantilla de pasos de cada generador (D-112).

### 6.1 Tarjetas y ejemplos resueltos por competencia

| Competencia | Nombre | Tarjetas | Ejemplo resuelto (generador) |
|---|---|---|---|
| LEN.COM.PROP | Coherencia, cohesión y adecuación | LEN.COM.PROP.T01 «Propiedades del texto» (enUso) | — |
| LEN.COM.RESU | El resumen | LEN.COM.RESU.T01 «El resumen» (enUso) | — |
| LEN.COM.TEMA | Tema e idea principal | LEN.COM.TEMA.T01 «El tema» (enUso) | — |
| LEN.COM.TIPO | Tipos de texto | LEN.COM.TIPO.T01 «Tipos de texto» (enUso) | — |
| LEN.LEX.CAMPO | Campo semántico y familia léxica | LEN.LEX.CAMPO.T01 «Campo semántico y familia léxica» (enUso) | — |
| LEN.LEX.DICC | El diccionario | LEN.LEX.DICC.T01 «El diccionario» (enUso) | — |
| LEN.LEX.POLI | Polisemia, homonimia y paronimia | LEN.LEX.POLI.T01 «Polisemia, homonimia y paronimia» (enUso) | — |
| LEN.LEX.SIN | Sinónimos y antónimos | LEN.LEX.SIN.T01 «Sinónimos y antónimos» (enUso) | — |
| LEN.LIT.GEN | Géneros y subgéneros literarios | LEN.LIT.GEN.T01 «Géneros literarios» (enUso) | — |
| LEN.LIT.HIST | Historia de la literatura española | LEN.LIT.HIST.T01 «Periodos de la literatura española» (enUso) | — |
| LEN.LIT.INF | Literatura infantil y juvenil | LEN.LIT.INF.T01 «Literatura infantil y juvenil» (enUso) | — |
| LEN.LIT.UNIV | Literatura universal | LEN.LIT.UNIV.T01 «Literatura universal» (enUso) | — |
| LEN.ORT.AGU | Agudas, llanas y esdrújulas | LEN.ORT.AGU.T01 «Agudas, llanas y esdrújulas» (enUso) | — |
| LEN.ORT.DIA | Tilde diacrítica | LEN.ORT.DIA.T01 «Tilde diacrítica» (enUso) | — |
| LEN.ORT.HIA | Diptongo, hiato y tilde | LEN.ORT.HIA.T01 «Diptongo, hiato y tilde» (enUso) | — |
| LEN.ORT.HOM | Homófonos frecuentes | LEN.ORT.HOM.T01 «Homófonos frecuentes» (enUso) | — |
| LEN.ORT.PQ | Por qué, porque, porqué y por que | LEN.ORT.PQ.T01 «Por qué, porque, porqué y por que» (enUso) | — |
| LEN.SIN.CLASE | Clases de oración | LEN.SIN.CLASE.T01 «Clases de oraciones» (enUso) | oracionSimple |
| LEN.SIN.COMPL | Complementos del verbo | LEN.SIN.COMPL.T01 «Los complementos del verbo» (enUso) | oracionSimple |
| LEN.SIN.SUJPRED | Sujeto y predicado | LEN.SIN.SUJPRED.T01 «Sujeto y predicado» (prueba); LEN.SIN.SUJPRED.T02 «Sujeto y predicado» (enUso) | oracionSimple |
| LEN.VER.ANALISIS | Análisis de formas verbales | LEN.VER.ANALISIS.T01 «Análisis de una forma verbal» (enUso) | — |
| LEN.VER.NOPERS | Formas no personales | LEN.VER.NOPERS.T01 «Formas no personales» (enUso) | — |
| MAT.DIV.MCD | Máximo común divisor | — | mcmMcd |
| MAT.EST.CENTRAL | Media, mediana, moda y rango | — | estadisticaBasica |
| MAT.NUM.FRAEQ | Fracciones equivalentes | MAT.NUM.FRAEQ.T01 «Fracciones equivalentes» (enUso) | — |
| MAT.NUM.FRAOP | Operaciones con fracciones | — | fraccionesOperar |
| MAT.NUM.FRAPROB | Problemas con fracciones | — | problemaFraccion |
| MAT.NUM.FRAREP | Representar fracciones | MAT.NUM.FRAREP.T01 «Qué es una fracción» (enUso) | — |
| MAT.NUM.ORDEN | Ordenar fracciones y decimales | — | ordenarNumeros |
| MAT.OPE.COMB | Operaciones combinadas con paréntesis y corchetes | — | operacionesCombinadas |
| MAT.OPE.ECUAC | Ecuaciones de primer grado | — | ecuacionLineal |
| MAT.OPE.FRACSUM | Suma de fracciones | MAT.OPE.FRACSUM.T01 «Suma de fracciones» (prueba) | — |
| MAT.OPE.INCOG | Término desconocido | — | terminoDesconocido |
| MAT.OPE.JER | Jerarquía de las operaciones | — | operacionesCombinadas |
| MAT.POR.CALC | Tanto por ciento de una cantidad | — | porcentajeDe |
| MAT.POR.PROP | Proporcionalidad directa | — | reglaDeTres |
| MAT.POR.TOTAL | Total a partir de una parte y su porcentaje | — | porcentajeDe |
| MAT.POR.VAR | Aumentos y descuentos porcentuales | — | porcentajeDe |
| MAT.PRO.LAPLACE | Probabilidad de un suceso | — | probabilidadSimple |
| MAT.ROM.ESCR | Escribir números romanos | — | romanos |
| MAT.ROM.LEER | Leer números romanos | — | romanos |
| MAT.UNI.ESC | Escalas | — | escala |
| MAT.UNI.LMC | Longitud, masa y capacidad | — | conversionUnidades |
| MAT.UNI.SUP | Unidades de superficie | — | conversionUnidades |
| MAT.UNI.TIEM | Tiempo y sistema sexagesimal | — | sexagesimal |
| MAT.UNI.VOL | Volumen y capacidad | — | conversionUnidades |

### 6.2 Competencias del mapa sin tarjeta en Release (88 de 112)

LEN.SIN.SINT, LEN.SIN.MODAL, LEN.SIN.COMP, LEN.ORT.LET, LEN.ORT.PUNT, LEN.ORT.MAY, LEN.CLA.VAR, LEN.CLA.INV, LEN.CLA.ADJGRAD, LEN.CLA.JUST, LEN.VER.IRREG, LEN.VER.VOZ, LEN.LIT.OBRA, LEN.LIT.POP, LEN.COM.SITU, LEN.COM.INFER, LEN.COM.GEN, LEN.REC.FIG, LEN.REC.DEF, LEN.MET.MED, LEN.MET.RIMA, LEN.MET.ESTR, LEN.LEX.CTX, LEN.LEX.REG, LEN.LEX.DEN, LEN.LEX.FRAS, LEN.FOR.ESTR, LEN.FOR.DER, LEN.FOR.COMP, LEN.FOR.CLAS, LEN.FOR.SIGL, LEN.HAB.ORIG, LEN.HAB.RAE, LEN.HAB.LENESP, LEN.HAB.SIGNOS, LEN.HAB.NODISC, MAT.UNI.LMC, MAT.UNI.SUP, MAT.UNI.VOL, MAT.UNI.TIEM, MAT.UNI.ESC, MAT.UNI.ANG, MAT.UNI.ESTIM, MAT.GEO.CLAS, MAT.GEO.CUER, MAT.GEO.ANG, MAT.GEO.PER, MAT.GEO.AREA, MAT.GEO.VOL, MAT.GEO.CART, MAT.GEO.MOV, MAT.GEO.SEMEJ, MAT.POR.CALC, MAT.POR.TOTAL, MAT.POR.VAR, MAT.POR.PROP, MAT.POR.FIN, MAT.NUM.ORDEN, MAT.NUM.FRAOP, MAT.NUM.FRAPROB, MAT.NUM.TIPOS, MAT.NUM.VALPOS, MAT.NUM.EQUIV, MAT.NUM.ENT, MAT.DIV.MCD, MAT.DIV.REGLAS, MAT.DIV.MULDIV, MAT.DIV.PRIMOS, MAT.DIV.MCM, MAT.OPE.ECUAC, MAT.OPE.JER, MAT.OPE.COMB, MAT.OPE.POT, MAT.OPE.RAIZ, MAT.OPE.MENTAL, MAT.OPE.INCOG, MAT.ROM.LEER, MAT.ROM.ESCR, MAT.EST.CENTRAL, MAT.EST.FREC, MAT.EST.GRAF, MAT.EST.POBL, MAT.PRO.LAPLACE, MAT.PRO.SUCESOS, MAT.PRO.RECUENTO, MAT.ALG.PATR, MAT.ALG.IGUAL, MAT.ALG.ALGO.

## 7. Huecos

Cobertura recalculada sobre el contenido de Release de este commit con el criterio de `docs/AUDITORIA_05E.md` §2: **completa** = 5 peldaños, al menos 3 dificultades y tarjeta; **parcial** = algo de contenido; **vacía** = nada. Las competencias antiguas con `equivaleA` suman a la del mapa. Peldaños y dificultades son los declarados por ítems y plantillas.

| Bloque | Completas | Parciales | Vacías |
|---|---|---|---|
| LEN.SIN | 2 | 1 | 3 |
| LEN.ORT | 0 | 5 | 3 |
| LEN.CLA | 0 | 0 | 4 |
| LEN.VER | 2 | 0 | 2 |
| LEN.LIT | 0 | 4 | 2 |
| LEN.COM | 0 | 7 | 0 |
| LEN.REC | 0 | 0 | 2 |
| LEN.MET | 0 | 0 | 3 |
| LEN.LEX | 0 | 8 | 0 |
| LEN.FOR | 0 | 0 | 5 |
| LEN.HAB | 0 | 0 | 5 |
| MAT.UNI | 0 | 5 | 2 |
| MAT.GEO | 0 | 0 | 9 |
| MAT.POR | 0 | 4 | 1 |
| MAT.NUM | 0 | 5 | 4 |
| MAT.DIV | 0 | 1 | 4 |
| MAT.OPE | 0 | 4 | 3 |
| MAT.ROM | 0 | 2 | 0 |
| MAT.EST | 0 | 1 | 3 |
| MAT.PRO | 0 | 1 | 2 |
| MAT.ALG | 0 | 0 | 3 |
| **Total** | 4 | 48 | 60 |

Parciales (ítems estáticos · plantillas aprobadas · peldaños · dificultades · tarjeta):

| Competencia | Estáticos | Plantillas | Peldaños | Dificultades | Tarjeta |
|---|---|---|---|---|---|
| LEN.SIN.CLASE | 0 | 3 | 2,3,5 | 2,4,5 | sí |
| LEN.ORT.AGU | 21 | 4 | 1,2,3,4 | 1,2,3 | sí |
| LEN.ORT.DIA | 9 | 1 | 1,2,3,4 | 1,2,3,4 | sí |
| LEN.ORT.HIA | 6 | 0 | 1,2,3,4 | 1,2,3 | sí |
| LEN.ORT.PQ | 6 | 1 | 1,2,3,4 | 1,2,3 | sí |
| LEN.ORT.HOM | 8 | 2 | 1,2,3,4 | 1,2,3,4 | sí |
| LEN.LIT.GEN | 0 | 3 | 1,3,5 | 1,3,5 | sí |
| LEN.LIT.HIST | 0 | 5 | 1,2,3,5 | 1,2,3,4 | sí |
| LEN.LIT.UNIV | 0 | 3 | 2,3,5 | 2,3,4 | sí |
| LEN.LIT.INF | 0 | 3 | 2,3,4 | 2,3,4 | sí |
| LEN.COM.SITU | 1 | 0 | 1 | 1 | no |
| LEN.COM.TEMA | 4 | 0 | 1,2,3 | 1,2,3 | sí |
| LEN.COM.RESU | 4 | 0 | 2,3,4 | 2,3 | sí |
| LEN.COM.INFER | 3 | 0 | 2,3 | 2,3,4 | no |
| LEN.COM.TIPO | 4 | 0 | 1,2,3,4 | 1,2,3 | sí |
| LEN.COM.PROP | 2 | 0 | 3 | 2,3 | sí |
| LEN.COM.GEN | 1 | 0 | 2 | 2 | no |
| LEN.LEX.SIN | 7 | 0 | 1,2,3,4 | 1,2,3,4 | sí |
| LEN.LEX.POLI | 6 | 0 | 1,2,3,4 | 1,2,3 | sí |
| LEN.LEX.CAMPO | 5 | 0 | 1,2,3,4 | 1,2,3 | sí |
| LEN.LEX.CTX | 3 | 0 | 2,3 | 2,3,4 | no |
| LEN.LEX.DICC | 5 | 0 | 1,2,3,4 | 1,2,3 | sí |
| LEN.LEX.REG | 2 | 0 | 2,3 | 2 | no |
| LEN.LEX.DEN | 1 | 0 | 3 | 3 | no |
| LEN.LEX.FRAS | 1 | 0 | 2 | 2 | no |
| MAT.UNI.LMC | 0 | 2 | 2,3 | 2,3 | no |
| MAT.UNI.SUP | 0 | 1 | 3 | 3 | no |
| MAT.UNI.VOL | 0 | 1 | 3 | 3 | no |
| MAT.UNI.TIEM | 0 | 3 | 2,3,4 | 2,3,4 | no |
| MAT.UNI.ESC | 0 | 2 | 3,4 | 3,4 | no |
| MAT.POR.CALC | 0 | 2 | 2,3 | 2,3 | no |
| MAT.POR.TOTAL | 0 | 1 | 3 | 3 | no |
| MAT.POR.VAR | 0 | 2 | 3,4 | 3,4 | no |
| MAT.POR.PROP | 0 | 2 | 2,3 | 2,3 | no |
| MAT.NUM.FRAREP | 4 | 0 | 1,2,3 | 1,2 | sí |
| MAT.NUM.FRAEQ | 5 | 0 | 2,3,4 | 2,3 | sí |
| MAT.NUM.ORDEN | 0 | 2 | 2,3 | 2,3 | no |
| MAT.NUM.FRAOP | 0 | 3 | 2,3,4 | 2,3,4 | no |
| MAT.NUM.FRAPROB | 0 | 2 | 3,4 | 3,4 | no |
| MAT.DIV.MCD | 0 | 1 | 2 | 3 | no |
| MAT.OPE.ECUAC | 0 | 3 | 2,3,4 | 2,3,4 | no |
| MAT.OPE.JER | 0 | 2 | 2,3 | 2,3 | no |
| MAT.OPE.COMB | 0 | 2 | 3,4 | 3,4 | no |
| MAT.OPE.INCOG | 0 | 1 | 3 | 4 | no |
| MAT.ROM.LEER | 0 | 2 | 2,3 | 2,3 | no |
| MAT.ROM.ESCR | 0 | 2 | 2,3 | 2,3 | no |
| MAT.EST.CENTRAL | 0 | 1 | 2 | 2 | no |
| MAT.PRO.LAPLACE | 0 | 1 | 2 | 3 | no |

Vacías (60): LEN.SIN.SINT, LEN.SIN.MODAL, LEN.SIN.COMP, LEN.ORT.LET, LEN.ORT.PUNT, LEN.ORT.MAY, LEN.CLA.VAR (**2 oficiales**), LEN.CLA.INV, LEN.CLA.ADJGRAD (**2 oficiales**), LEN.CLA.JUST (**1 oficial**), LEN.VER.IRREG (**1 oficial**), LEN.VER.VOZ, LEN.LIT.OBRA, LEN.LIT.POP, LEN.REC.FIG (**2 oficiales**), LEN.REC.DEF (**4 oficiales**), LEN.MET.MED (**1 oficial**), LEN.MET.RIMA, LEN.MET.ESTR, LEN.FOR.ESTR, LEN.FOR.DER (**3 oficiales**), LEN.FOR.COMP, LEN.FOR.CLAS (**1 oficial**), LEN.FOR.SIGL, LEN.HAB.ORIG, LEN.HAB.RAE, LEN.HAB.LENESP, LEN.HAB.SIGNOS, LEN.HAB.NODISC, MAT.UNI.ANG, MAT.UNI.ESTIM, MAT.GEO.CLAS, MAT.GEO.CUER, MAT.GEO.ANG (**1 oficial**), MAT.GEO.PER, MAT.GEO.AREA (**4 oficiales**), MAT.GEO.VOL (**5 oficiales**), MAT.GEO.CART (**1 oficial**), MAT.GEO.MOV, MAT.GEO.SEMEJ, MAT.POR.FIN, MAT.NUM.TIPOS, MAT.NUM.VALPOS (**1 oficial**), MAT.NUM.EQUIV (**1 oficial**), MAT.NUM.ENT, MAT.DIV.REGLAS (**1 oficial**), MAT.DIV.MULDIV, MAT.DIV.PRIMOS, MAT.DIV.MCM (**2 oficiales**), MAT.OPE.POT (**2 oficiales**), MAT.OPE.RAIZ, MAT.OPE.MENTAL, MAT.EST.FREC (**2 oficiales**), MAT.EST.GRAF, MAT.EST.POBL, MAT.PRO.SUCESOS (**2 oficiales**), MAT.PRO.RECUENTO, MAT.ALG.PATR, MAT.ALG.IGUAL, MAT.ALG.ALGO.

Completas (4): LEN.SIN.SUJPRED, LEN.SIN.COMPL, LEN.VER.ANALISIS, LEN.VER.NOPERS.

Diferencia con `docs/AUDITORIA_05E.md` §2 (parte 1: 0 completas, 48 parciales y 63 vacías, sobre 111 competencias): LEN.SIN.SUJPRED, LEN.SIN.COMPL, LEN.VER.ANALISIS y LEN.VER.NOPERS pasan a completas al llegar sus tarjetas del ANEXO B (D-102); MAT.DIV.MCD, MAT.EST.CENTRAL y MAT.PRO.LAPLACE dejan de estar vacías (plantillas aprobadas en D-101); MAT.OPE.INCOG es una competencia nueva de la parte 2 (D-100), con plantilla aprobada, y eleva el total a 112.

### 7.1 Tipos oficiales sin contenido que los entrene («no» en todas sus preguntas)

| Área | Tipo de tarea | Preguntas |
|---|---|---|
| Lengua | Formación de palabras | 4 |
| Lengua | Rasgos de un movimiento | 2 |
| Lengua | Grados del adjetivo | 2 |
| Lengua | Identificar figura retórica | 2 |
| Lengua | Relacionar término y definición | 2 |
| Lengua | Métrica | 1 |
| Lengua | Clases de palabras | 1 |
| Lengua | Análisis morfológico | 1 |
| Lengua | Uso normativo | 1 |
| Matemáticas | Áreas compuestas | 4 |
| Matemáticas | Volumen y capacidad | 3 |
| Matemáticas | m.c.m. en contexto | 2 |
| Matemáticas | Volumen de cuerpos | 2 |
| Matemáticas | Tabla de frecuencias | 2 |
| Matemáticas | Ángulos | 1 |
| Matemáticas | Potencias de 10 | 1 |
| Matemáticas | Valor posicional | 1 |
| Matemáticas | Proporcionalidad inversa / trabajo conjunto | 1 |
| Matemáticas | Coordenadas cartesianas | 1 |
| Matemáticas | Conceptos de probabilidad | 1 |
| Matemáticas | Decimal ↔ fracción | 1 |
| Matemáticas | Potencias | 1 |
| Matemáticas | Probabilidad experimental | 1 |
| Matemáticas | Criterios de divisibilidad | 1 |

### 7.2 Tipos no localizados

- Las 139 preguntas de los 7 cuadernillos están en el repositorio con su tipo de tarea; no falta ninguna.
- No hay en la web oficial (y por tanto tampoco en el repositorio) cuadernillos de 2014, 2015, 2016, 2018, 2020, 2021, 2023 ni 2025, ni las aplazadas de 2017, 2022 y 2024 (FUENTES.md §1).
- Plantillas de corrección oficiales: solo las de 2026; el resto de rúbricas son de redacción propia.
- Pendiente de la dirección (CONTENIDOS «05E parte 2»): verbos irregulares, las 70 palabras ambiguas con contexto (`pendiente/tildeContexto.json`), el predicativo y el complemento del nombre, y tarjetas de teoría.

## 8. No exportado

- **Textos protegidos**: Pedro Salinas, *La voz a ti debida* (2019 O) y Carmen Laforet, *Nada* (2019 A). Van con la remisión que usa la app: «[Cita del texto base protegido: consúltese en el PDF oficial]» y el archivo del PDF.
- **Figuras**: no se incluyen imágenes. Las 4 figuras (2022 O M15 y M20, 2024 O M17, 2026 O M17) van con su descripción de `CORRECCIONES_OCR.md` §4, el PDF y la página; las tablas, transcritas en el enunciado.
- **Ítems generados**: no se han generado (Linux sin Swift; la descarga del compilador está bloqueada por la red del entorno). De cada plantilla se exportan su tabla, parámetros, validación, errores y anclas; los ejemplos son los 20 ids con semilla fija de la muestra de auditoría, con su resumen documentado. Enunciado, opciones, solución y pasos de esos ejemplos, y los pasos de los ejemplos resueltos: «no documentado (requiere ejecutar en Mac)».
- **Catálogo de preguntas en Release actualizado**: no recalculado; la última cifra documentada (≥ 230 813) es de la parte 1.
- **Recursos de los generadores en bruto** (léxico de 818 palabras, `gramatica/*.json`, 100 frases con hueco, base literaria de 142 autores, `ambiguas.json`, `pendiente/tildeContexto.json`): no son preguntas; se citan y se cuentan, pero no se copian.
- **Fuera por las reglas**: claves, firma, datos de usuarios, progreso, registros de actividad y capturas. No se ha exportado nada de eso.
