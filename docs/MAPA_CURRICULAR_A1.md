# Mapa curricular de la A1

Copia del ANEXO A del prompt de la Fase 05E (parte 1), tal como lo dio la dirección. La app lo carga como catálogo con `scripts/cargar_mapa_a1.py` (D-091). Las marcas de estado (✅ 🟦 ⚙️ ⬜) son las del anexo; el estado real tras la 05E está en [AUDITORIA_05E.md](AUDITORIA_05E.md).

## Cómo se ha cargado (D-091)

- **Ids**: se conservan todos los existentes y solo se añaden bloques y competencias. Los nombres existentes no se cambian.
- **Recuento real**: el anexo habla de 22 bloques, pero sus tablas tienen **21** (11 de Lengua y 10 de Matemáticas), y **111** competencias. El catálogo tiene 124: las 111 del mapa y 13 antiguas sustituidas.
- **LEN.VER.ANAL** es la competencia existente **LEN.VER.ANALISIS** (se conserva ese id; no se crea un duplicado).
- **Prioridad**: ★ = 1, ★★ = 2, ★★★ = 3. Cambian LEN.LEX (2 → 3) y MAT.EST (2 → 3).
- **Competencias antiguas sustituidas** (`equivaleA` en `catalogo.json`): conservan su id y su progreso; el Camino no las muestra mientras no tengan contenido ni progreso.

| Id antiguo | Competencia del mapa |
|---|---|
| LEN.LIT.CRONO, LEN.LIT.AUTOBRA | LEN.LIT.HIST |
| LEN.REC.FIGURAS | LEN.REC.FIG |
| LEN.CLA.SUSTADJ, LEN.CLA.VERBO | LEN.CLA.VAR |
| LEN.LEX.SINON | LEN.LEX.SIN |
| MAT.UNI.LONG | MAT.UNI.LMC |
| MAT.GEO.TRIANG | MAT.GEO.CLAS |
| MAT.POR.PORCENT | MAT.POR.CALC |
| MAT.OPE.JERARQ | MAT.OPE.JER |
| MAT.OPE.FRACSUM | MAT.NUM.FRAOP |
| MAT.OPE.EQUIV | MAT.NUM.EQUIV |
| MAT.ROM.LECTURA | MAT.ROM.LEER |

## 2. Mapa completo (bloque → competencias)

Leyenda de estado: ✅ contenido aprobado · 🟦 lote 02 en curso · ⚙️ generador ya hecho, falta contenido · ⬜ pendiente. La prioridad combina la frecuencia en la matriz de exámenes y su peso en el decreto.

### LENGUA

| Bloque | Competencias (id: nombre) | Estado | Prio. |
|---|---|---|---|
| **LEN.HAB** Las lenguas y sus hablantes *(nuevo)* | ORIG: origen y evolución del español (latín, etapas, expansión) · RAE: la RAE y la norma · LENESP: lenguas y variedades de España · SIGNOS: lenguas de signos y comunicación accesible · NODISC: lenguaje no discriminatorio | ⬜ | ★★ |
| **LEN.COM** Comunicación y comprensión | SITU: elementos de la comunicación · TEMA: tema e idea principal · RESU: resumen (ideas principales y secundarias) · INFER: inferencias y sentido de una frase · TIPO: tipos de texto (narración, descripción, diálogo, exposición, argumentación) · PROP: coherencia, cohesión y adecuación · GEN: géneros discursivos (noticia, carta, instrucciones, anuncio…) | ⬜ | ★★★ |
| **LEN.LIT** Educación literaria | GEN: géneros y subgéneros · OBRA: elementos de la obra (tema, personajes, argumento, espacio, narrador) · HIST: historia de la literatura española por periodos · UNIV: literatura universal · INF: literatura infantil y juvenil · POP: refranes, greguerías y literatura popular | ⬜ | ★★★ |
| **LEN.REC** Recursos literarios | FIG: identificar recursos (símil, metáfora, personificación, hipérbole, anáfora, epíteto, aliteración, hipérbaton, antítesis, onomatopeya) · DEF: definir recursos | ⬜ | ★★ |
| **LEN.MET** Métrica | MED: medida del verso (sinalefa, final agudo o esdrújulo) · RIMA: rima consonante y asonante · ESTR: estrofas | ⬜ | ★★ |
| **LEN.CLA** Clases de palabras | VAR: palabras variables (sustantivo, determinante, pronombre, adjetivo) · INV: palabras invariables (adverbio, preposición, conjunción, interjección) · ADJGRAD: grados del adjetivo · JUST: justificar la categoría | ⚙️ | ★★★ |
| **LEN.VER** El verbo | ANAL: análisis de formas verbales · NOPERS: formas no personales · IRREG: verbos irregulares · VOZ: voz activa y pasiva | ⚙️ | ★★★ |
| **LEN.SIN** Sintaxis | SUJPRED: sujeto y predicado ✅ (piloto) · SINT: sintagmas y núcleo · COMPL: complementos (CD, CI, CC, atributo, complemento agente) · MODAL: tipos de oración por la intención · CLASE: oraciones atributivas y predicativas, transitivas e intransitivas, impersonales · COMP: oración compuesta (nociones) | ⚙️ | ★★★ |
| **LEN.ORT** Ortografía | AGU ✅🟦 · DIA ✅ · HIA ✅ · PQ ✅ · HOM ✅ · LET: uso de letras (b/v, g/j, h, ll/y, c/z/q/k, r/rr, x) · PUNT: signos de puntuación · MAY: mayúsculas | ✅/⬜ | ★★★ |
| **LEN.LEX** Léxico y semántica | SIN: sinónimos y antónimos · POLI: polisemia, homonimia y paronimia · CAMPO: campo semántico y familia léxica · CTX: significado en contexto y término desconocido · DICC: el diccionario (orden, acepciones, abreviaturas) · REG: registros, préstamos y extranjerismos · DEN: denotación y connotación · FRAS: frases hechas | ⚙️ | ★★★ |
| **LEN.FOR** Formación de palabras | ESTR: lexema y morfemas · DER: prefijos y sufijos · COMP: composición · CLAS: primitivas, derivadas, compuestas y parasintéticas · SIGL: siglas, acrónimos y abreviaturas | ⬜ | ★★ |

### MATEMÁTICAS

| Bloque | Competencias | Estado | Prio. |
|---|---|---|---|
| **MAT.NUM** Números | TIPOS: naturales, enteros, racionales, reales y π · VALPOS: valor posicional y redondeo hasta las milésimas · ORDEN 🟦 · FRAREP ✅ · FRAEQ ✅ · FRAOP 🟦 · FRAPROB 🟦 · EQUIV: equivalencias fracción ↔ decimal ↔ % · ENT: números enteros en contexto | mixto | ★★★ |
| **MAT.OPE** Operaciones | JER 🟦 · COMB 🟦 · ECUAC 🟦 · POT: potencias, cuadrados, cubos y potencias de 10 · RAIZ: raíz cuadrada exacta · MENTAL: cálculo mental y estimación | mixto | ★★★ |
| **MAT.DIV** Divisibilidad | REGLAS: criterios del 2, 3, 5 y 10 · MULDIV: múltiplos y divisores · PRIMOS: primos, compuestos y factorización · MCM: m.c.m. y problemas · MCD: m.c.d. y problemas | ⚙️ | ★★★ |
| **MAT.POR** Proporcionalidad y finanzas | CALC 🟦 · TOTAL 🟦 · VAR 🟦 · PROP 🟦 · FIN: educación financiera (interés simple, IVA, préstamos y depósitos) | mixto | ★★★ |
| **MAT.UNI** Medida | LMC 🟦 · SUP 🟦 · VOL 🟦 · TIEM 🟦 · ESC 🟦 · ANG: medida de ángulos (grados, minutos y segundos) · ESTIM: estimación y verosimilitud de medidas | mixto | ★★★ |
| **MAT.GEO** Geometría | CLAS: figuras planas (polígonos, triángulos, cuadriláteros, circunferencia y círculo) · CUER: cuerpos geométricos (poliedros, prismas, pirámides, cuerpos redondos; caras, aristas y vértices) · ANG: ángulos (tipos, complementarios y suplementarios, suma interior) · PER: perímetros · AREA: áreas, también compuestas y con círculos · VOL: volúmenes · CART: coordenadas en el primer cuadrante · MOV: giros, traslaciones y simetrías · SEMEJ: semejanza | ⬜ | ★★★ |
| **MAT.ALG** Álgebra y pensamiento computacional *(nuevo)* | PATR: patrones y series · IGUAL: igualdades y desigualdades · ALGO: algoritmos sencillos | ⬜ | ★ |
| **MAT.EST** Estadística | CENTRAL ⚙️ (media, mediana, moda, rango) · FREC: frecuencias absolutas y relativas · GRAF: gráficos de barras, sectores e histograma · POBL: muestra y población | mixto | ★★★ |
| **MAT.PRO** Probabilidad | LAPLACE ⚙️ · SUCESOS: seguro, posible e imposible; frecuencia relativa · RECUENTO: diagramas de árbol y recuento sencillo | mixto | ★★ |
| **MAT.ROM** Numeración romana | LEER 🟦 · ESCR 🟦 | 🟦 | ★★ |

**Total: 22 bloques y unas 100 competencias** (texto del anexo; ver el recuento real arriba). Con el lote 02, unas 26 competencias tienen contenido. El resto llega en los lotes 02b a 07 (ver PLAN_CONTENIDOS §7), siempre por prioridad.
