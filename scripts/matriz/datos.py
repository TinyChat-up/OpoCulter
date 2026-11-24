# (año, convocatoria, área, nº, resumen, bloque, competencia, tipo, mecánica)
# Competencias con † no existen en el catálogo: propuesta.
O,A="Ordinaria","Aplazada"
L,M="Lengua","Matemáticas"
R=[]
def add(y,c,a,rows):
    for i,r in enumerate(rows,1): R.append((y,c,a,i)+r)
# ---------------- 2017 ----------------
add(2017,O,L,[
("Resumir un relato romántico en prosa (leyenda)","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Situar en el tiempo la historia narrada","LEN.LIT","LEN.LIT.CONTEXTO†","Contexto histórico","eleccion"),
("Significado en contexto de 5 palabras","LEN.LEX","LEN.LEX.CTX","Vocabulario en contexto","emparejar"),
("Identificar el movimiento literario del texto","LEN.LIT","LEN.LIT.AUTOBRA","Movimiento/época","eleccion"),
("Rasgos del movimiento (Romanticismo)","LEN.LIT","LEN.LIT.MOVIM†","Rasgos de un movimiento","clasificar"),
("Análisis de 3 formas verbales","LEN.VER","LEN.VER.ANALISIS","Análisis de formas verbales","ruedas"),
("Citar 4 poetas de la Generación del 27","LEN.LIT","LEN.LIT.AUTOBRA","Citar autores de un grupo","clasificar"),
("Ordenar 6 autores cronológicamente","LEN.LIT","LEN.LIT.CRONO","Cronología de autores","ordenar"),
("Análisis sintáctico de oración simple intransitiva con CCM y CCL","LEN.SIN","LEN.SIN.COMPL","Análisis sintáctico","segmentar"),
])
add(2017,O,M,[
("Hallar el factor y el divisor desconocidos (decimal y entero)","MAT.OPE","MAT.OPE.INCOG†","Término desconocido","numerico"),
("Ordenar de mayor a menor fracciones y decimales","MAT.NUM","MAT.NUM.ORDEN†","Ordenar números","ordenar"),
("Detectar fracciones equivalentes","MAT.NUM","MAT.NUM.FRAEQ","Fracciones equivalentes","eleccion"),
("Ángulo complementario y suplementario","MAT.GEO","MAT.GEO.ANGULOS†","Ángulos","numerico"),
("Área de un cuadrado más un círculo","MAT.GEO","MAT.GEO.AREAS†","Áreas compuestas","numerico"),
("Escribir 3 números en romanos","MAT.ROM","MAT.ROM.ESCRITURA†","Arábigo → romano","construir"),
("Precio final con descuento porcentual","MAT.POR","MAT.POR.PORCENT","Aumentos y descuentos","numerico"),
("Coincidencia periódica (m.c.m.)","MAT.DIV","MAT.DIV.MCM†","m.c.m. en contexto","numerico"),
("Completar 6 equivalencias del SI (capacidad, longitud, masa, superficie, volumen)","MAT.UNI","MAT.UNI.CONV†","Conversión de unidades","numerico"),
("Operación combinada con paréntesis","MAT.OPE","MAT.OPE.JERARQ","Operación combinada","numerico"),
])
# ---------------- 2019 ordinaria ----------------
add(2019,O,L,[
("Tema y comentario de un poema amoroso (autor no de dominio público)","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Generación del autor","LEN.LIT","LEN.LIT.AUTOBRA","Movimiento/época","eleccion"),
("Reconocer la figura en dos fragmentos (enumeración, anáfora)","LEN.REC","LEN.REC.FIGURAS","Identificar figura retórica","eleccion"),
("Definir metáfora","LEN.REC","LEN.REC.FIGURAS","Definir términos","emparejar"),
("Diferencia entre si y sí","LEN.ORT","LEN.ORT.DIA","Tilde diacrítica","eleccion"),
("Análisis de 3 formas verbales","LEN.VER","LEN.VER.ANALISIS","Análisis de formas verbales","ruedas"),
("Clasificar adjetivos en positivo, comparativo y superlativo","LEN.CLA","LEN.CLA.SUSTADJ","Grados del adjetivo","clasificar"),
("Citar 4 narradores del siglo XX","LEN.LIT","LEN.LIT.AUTOBRA","Citar autores de un grupo","clasificar"),
("Ordenar 6 autores cronológicamente","LEN.LIT","LEN.LIT.CRONO","Cronología de autores","ordenar"),
("Análisis sintáctico de oración copulativa/predicativa con CCL","LEN.SIN","LEN.SIN.COMPL","Análisis sintáctico","segmentar"),
])
add(2019,O,M,[
("Cuatro operaciones con fracciones y simplificación (enunciado en imagen)","MAT.OPE","MAT.OPE.FRACSUM","Operaciones con fracciones","numerico"),
("Pasar tiempos en h, min y s a una unidad","MAT.UNI","MAT.UNI.TIEMPO†","Sistema sexagesimal","numerico"),
("Hallar factor y divisor desconocidos","MAT.OPE","MAT.OPE.INCOG†","Término desconocido","numerico"),
("Ordenar fracciones y decimales","MAT.NUM","MAT.NUM.ORDEN†","Ordenar números","ordenar"),
("Litros de una piscina con medidas en m, dm y cm (elección)","MAT.UNI","MAT.UNI.VOLCAP†","Volumen y capacidad","eleccion"),
("Media, moda y rango de 5 datos","MAT.EST","MAT.EST.CENTRAL†","Medidas de centralización","numerico"),
("Tabla de frecuencias absoluta, relativa y %","MAT.EST","MAT.EST.FRECUENCIAS†","Tabla de frecuencias","numerico"),
("Superficie total: dos rectángulos y un círculo con unidades mixtas","MAT.GEO","MAT.GEO.AREAS†","Áreas compuestas","numerico"),
("Escribir 3 números en romanos","MAT.ROM","MAT.ROM.ESCRITURA†","Arábigo → romano","construir"),
("Operación combinada con corchetes","MAT.OPE","MAT.OPE.JERARQ","Operación combinada","numerico"),
])
# ---------------- 2019 aplazada ----------------
add(2019,A,L,[
("Resumen y comentario de un fragmento narrativo (autora no de dominio público)","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Interpretar una frase con comparación","LEN.COM","LEN.COM.INFER","Sentido de una frase","eleccion"),
("Significado en contexto de 5 palabras","LEN.LEX","LEN.LEX.CTX","Vocabulario en contexto","emparejar"),
("Definir neologismo, arcaísmo, eufemismo, morfema y acrónimo","LEN.LEX","LEN.LEX.CONCEPTOS†","Definir términos","emparejar"),
("Clasificar derivadas por sufijación o prefijación","LEN.FOR","LEN.FOR.DERIV†","Formación de palabras","clasificar"),
("Análisis de 3 formas verbales","LEN.VER","LEN.VER.ANALISIS","Análisis de formas verbales","ruedas"),
("Clasificar adjetivos en positivo, comparativo y superlativo","LEN.CLA","LEN.CLA.SUSTADJ","Grados del adjetivo","clasificar"),
("Citar 5 poetas del siglo XX","LEN.LIT","LEN.LIT.AUTOBRA","Citar autores de un grupo","clasificar"),
("Ordenar 6 autores cronológicamente","LEN.LIT","LEN.LIT.CRONO","Cronología de autores","ordenar"),
("Análisis sintáctico de oración con predicativo y CCL","LEN.SIN","LEN.SIN.COMPL","Análisis sintáctico","segmentar"),
])
add(2019,A,M,[
("Fracciones sucesivas sobre lo que queda (globos)","MAT.NUM","MAT.NUM.FRACDE†","Fracción de lo que queda","numerico"),
("Sumar duraciones en h, min y s","MAT.UNI","MAT.UNI.TIEMPO†","Sistema sexagesimal","numerico"),
("Hallar factor y divisor desconocidos","MAT.OPE","MAT.OPE.INCOG†","Término desconocido","numerico"),
("Ordenar fracciones y decimales","MAT.NUM","MAT.NUM.ORDEN†","Ordenar números","ordenar"),
("Escalar una receta de 4 a 5 personas","MAT.POR","MAT.POR.PROPORC†","Proporcionalidad directa","numerico"),
("Relacionar sucesos con su probabilidad (bolas 0–9)","MAT.PRO","MAT.PRO.LAPLACE†","Probabilidad de Laplace","emparejar"),
("Volumen de pirámide y cilindro","MAT.GEO","MAT.GEO.VOLUMEN†","Volumen de cuerpos","numerico"),
("Media, mediana y rango de 5 datos","MAT.EST","MAT.EST.CENTRAL†","Medidas de centralización","numerico"),
("Pasar 3 romanos a arábigos","MAT.ROM","MAT.ROM.LECTURA","Romano → arábigo","numerico"),
("Operación combinada con corchetes","MAT.OPE","MAT.OPE.JERARQ","Operación combinada","numerico"),
])
# ---------------- 2022 ----------------
add(2022,O,L,[
("Resumir un fragmento teatral en verso","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Tipo de texto y 3 rasgos (teatro)","LEN.COM","LEN.COM.TIPO","Tipología textual","clasificar"),
("Significado en contexto de 4 palabras","LEN.LEX","LEN.LEX.CTX","Vocabulario en contexto","emparejar"),
("Análisis de 3 formas verbales","LEN.VER","LEN.VER.ANALISIS","Análisis de formas verbales","ruedas"),
("Dos acepciones de una palabra polisémica","LEN.LEX","LEN.LEX.POLI","Polisemia","eleccion"),
("Explicar el sentido de dos versos","LEN.COM","LEN.COM.INFER","Sentido de una frase","eleccion"),
("Métrica de 4 versos (anulada por error en el enunciado)","LEN.MET","LEN.MET.MEDIDA†","Métrica","numerico"),
("Definir metáfora, homónimas, verso libre y comparación","LEN.REC","LEN.REC.FIGURAS","Definir términos","emparejar"),
("Elegir la forma correcta (dé/de, mí/mi, té/te, sé/se) y razonar","LEN.ORT","LEN.ORT.DIA","Tilde diacrítica","eleccion"),
("Análisis sintáctico de oración transitiva con CCT y CCL","LEN.SIN","LEN.SIN.COMPL","Análisis sintáctico","segmentar"),
])
add(2022,O,M,[
("Repartir abalorios de 3 colores en collares iguales (m.c.d.)","MAT.DIV","MAT.DIV.MCD","m.c.d. en contexto","numerico"),
("Comparar fracciones leídas de una revista","MAT.NUM","MAT.NUM.ORDEN†","Comparar fracciones","ordenar"),
("Dos operaciones combinadas con decimales","MAT.OPE","MAT.OPE.JERARQ","Operaciones con decimales","numerico"),
("Expresar medidas complejas en una unidad (longitud, masa, capacidad)","MAT.UNI","MAT.UNI.CONV†","Conversión de unidades","numerico"),
("Coste de pintar una fachada a partir de su área (figura)","MAT.GEO","MAT.GEO.AREAS†","Áreas compuestas","numerico"),
("Cantidades de cada tipo a partir de porcentajes","MAT.POR","MAT.POR.PORCENT","Porcentaje de una cantidad","numerico"),
("Media, moda, mediana y rango desde tabla de frecuencias","MAT.EST","MAT.EST.CENTRAL†","Medidas de centralización","numerico"),
("Completar igualdades con potencias de 10","MAT.NUM","MAT.NUM.POT10†","Potencias de 10","numerico"),
("Precio por viaje con abono y ahorro","MAT.POR","MAT.POR.PROPORC†","Precio unitario","numerico"),
("Volumen de una figura de bloques (figura)","MAT.GEO","MAT.GEO.VOLUMEN†","Volumen de cuerpos","numerico"),
])
# ---------------- 2024 ----------------
add(2024,O,L,[
("Tema y contenido de un soneto barroco","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Autor del poema y su contexto","LEN.LIT","LEN.LIT.AUTOBRA","Autor y contexto","eleccion"),
("Dos corrientes del Barroco y sus autores","LEN.LIT","LEN.LIT.MOVIM†","Rasgos de un movimiento","emparejar"),
("Definir 6 palabras (incluye paradoja)","LEN.LEX","LEN.LEX.CTX","Vocabulario en contexto","emparejar"),
("Análisis de 6 formas verbales (simples y compuestas)","LEN.VER","LEN.VER.ANALISIS","Análisis de formas verbales","ruedas"),
("Sinónimo y antónimo de 11 palabras","LEN.LEX","LEN.LEX.SINON","Sinónimos y antónimos","eleccion"),
("Poner las tildes que faltan en un texto","LEN.ORT","LEN.ORT.AGU","Colocar tildes en un texto","colocarTilde"),
("Escribir la palabra a partir de su definición e iniciales","LEN.LEX","LEN.LEX.DEFIN†","Palabra por definición","construir"),
("Tres derivadas de 4 palabras","LEN.FOR","LEN.FOR.DERIV†","Formación de palabras","construir"),
("Análisis sintáctico de oración con CD y CI","LEN.SIN","LEN.SIN.COMPL","Análisis sintáctico","segmentar"),
])
add(2024,O,M,[
("Ordenar cantidades con potencias, notación científica y decimales","MAT.NUM","MAT.NUM.ORDEN†","Ordenar números","ordenar"),
("Operación combinada con fracciones y simplificación (enunciado en imagen)","MAT.OPE","MAT.OPE.FRACSUM","Operaciones con fracciones","numerico"),
("Descomposición polinómica de 3 números","MAT.NUM","MAT.NUM.DESCOMP†","Valor posicional","construir"),
("Número entre dos cotas múltiplo de 3, 4 y 7 (m.c.m.)","MAT.DIV","MAT.DIV.MCM†","m.c.m. en contexto","numerico"),
("Trabajo conjunto de dos pintores","MAT.POR","MAT.POR.PROPORC†","Proporcionalidad inversa / trabajo conjunto","numerico"),
("Sumar pesos en kg, hg, dag y dg y comparar con un máximo","MAT.UNI","MAT.UNI.CONV†","Conversión de unidades","numerico"),
("Capacidad de un recipiente y comparación con otro (figura)","MAT.GEO","MAT.GEO.VOLUMEN†","Volumen y capacidad","numerico"),
("Situar 4 puntos y su cuadrante","MAT.GEO","MAT.GEO.COORD†","Coordenadas cartesianas","eleccion"),
("Definir experiencia aleatoria y tipos de suceso","MAT.PRO","MAT.PRO.CONCEPTOS†","Conceptos de probabilidad","emparejar"),
("Medidas de centralización de 30 datos","MAT.EST","MAT.EST.CENTRAL†","Medidas de centralización","numerico"),
])
# ---------------- 2026 ordinaria ----------------
add(2026,O,L,[
("Tema y contenido de un fragmento narrativo clásico","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Tipo de texto y 3 rasgos","LEN.COM","LEN.COM.TIPO","Tipología textual","clasificar"),
("Época, obra y autor del fragmento","LEN.LIT","LEN.LIT.AUTOBRA","Autor y contexto","eleccion"),
("Prefijo y significado de 5 derivadas","LEN.FOR","LEN.FOR.DERIV†","Formación de palabras","emparejar"),
("Qué es un diccionario y para qué sirve","LEN.LEX","LEN.LEX.CONCEPTOS†","Definir términos","eleccion"),
("Análisis morfológico de 4 palabras","LEN.CLA","LEN.CLA.VERBO","Análisis morfológico","ruedas"),
("Elegir la forma normativa (verbos, haber, concordancia) y razonar","LEN.VER","LEN.VER.NORMA†","Uso normativo","eleccion"),
("Definir narrador, novela, hipérbole y adjetivo","LEN.REC","LEN.REC.FIGURAS","Definir términos","emparejar"),
("Relacionar 8 términos gramaticales y literarios con su definición","LEN.CLA","LEN.CLA.SUSTADJ","Relacionar término y definición","emparejar"),
("Análisis sintáctico de oración con CD y CCL","LEN.SIN","LEN.SIN.COMPL","Análisis sintáctico","segmentar"),
])
add(2026,O,M,[
("Decidir si un decimal es exacto y pasarlo a fracción irreducible","MAT.NUM","MAT.OPE.EQUIV","Decimal ↔ fracción","numerico"),
("Expresar situaciones como potencias","MAT.NUM","MAT.NUM.POT10†","Potencias","numerico"),
("Fracción restante tras sumar varias partes","MAT.OPE","MAT.OPE.FRACSUM","Operaciones con fracciones","numerico"),
("Pasar a metros y sumar cantidades en varias unidades (tabla)","MAT.UNI","MAT.UNI.LONG","Conversión de unidades","numerico"),
("Probabilidad estimada a partir de una tabla de tiros","MAT.PRO","MAT.PRO.LAPLACE†","Probabilidad experimental","numerico"),
("Porcentaje de una recaudación","MAT.POR","MAT.POR.PORCENT","Porcentaje de una cantidad","numerico"),
("Área de un jardín menos un círculo (figura)","MAT.GEO","MAT.GEO.AREAS†","Áreas compuestas","numerico"),
("Tabla de divisibilidad SÍ/NO","MAT.DIV","MAT.DIV.CRITERIOS†","Criterios de divisibilidad","clasificar"),
("Completar una tabla de frecuencias","MAT.EST","MAT.EST.FRECUENCIAS†","Tabla de frecuencias","numerico"),
("Medidas reales a partir de escalas","MAT.POR","MAT.POR.ESCALAS†","Escalas","numerico"),
])
# ---------------- 2026 aplazada ----------------
add(2026,A,L,[
("Tema y contenido de un poema (Generación del 27)","LEN.COM","LEN.COM.RESU","Resumen y tema","eleccion"),
("Autor, Generación del 27 y dos rasgos","LEN.LIT","LEN.LIT.AUTOBRA","Autor y contexto","eleccion"),
("Justificar la sensación de fatalidad con elementos del texto","LEN.COM","LEN.COM.INFER","Sentido de una frase","marcarTexto"),
("Clase de palabra y justificación de 7 palabras","LEN.CLA","LEN.CLA.SUSTADJ","Clases de palabras","clasificar"),
("Familia léxica, campo semántico, sinónimo/antónimo, propio/común","LEN.LEX","LEN.LEX.SINON","Léxico (familia, campo, sinónimos)","clasificar"),
("Anáfora, personificación, epíteto y medida de dos versos","LEN.REC","LEN.REC.FIGURAS","Identificar figura retórica","marcarTexto"),
("Elegir la forma correcta (porque/por qué, aún/aun, tuvo/tubo, ay/hay/ahí…) y razonar","LEN.ORT","LEN.ORT.HOM","Homófonos y diacríticas","eleccion"),
("Relacionar 10 términos con su definición","LEN.REC","LEN.REC.FIGURAS","Relacionar término y definición","emparejar"),
("Primitivas, derivadas o compuestas","LEN.FOR","LEN.FOR.DERIV†","Formación de palabras","clasificar"),
("Análisis sintáctico guiado (sujeto, núcleos, CD, CCL)","LEN.SIN","LEN.SIN.SUJPRED","Análisis sintáctico","segmentar"),
])
add(2026,A,M,[
("Fracciones sucesivas sobre lo que queda (libros)","MAT.NUM","MAT.NUM.FRACDE†","Fracción de lo que queda","numerico"),
("Sumar duraciones y expresarlas en segundos","MAT.UNI","MAT.UNI.TIEMPO†","Sistema sexagesimal","numerico"),
("Hallar factor y divisor desconocidos","MAT.OPE","MAT.OPE.INCOG†","Término desconocido","numerico"),
("Ordenar fracciones y decimales","MAT.NUM","MAT.NUM.ORDEN†","Ordenar números","ordenar"),
("Escalar una receta de 6 a 15 personas","MAT.POR","MAT.POR.PROPORC†","Proporcionalidad directa","numerico"),
("Relacionar sucesos con su probabilidad (tarjetas 1–12)","MAT.PRO","MAT.PRO.LAPLACE†","Probabilidad de Laplace","emparejar"),
("Volumen de un prisma en m³ y en litros","MAT.GEO","MAT.GEO.VOLUMEN†","Volumen y capacidad","numerico"),
("Media, mediana, moda y rango de 6 datos","MAT.EST","MAT.EST.CENTRAL†","Medidas de centralización","numerico"),
("Pasar 3 romanos a arábigos","MAT.ROM","MAT.ROM.LECTURA","Romano → arábigo","numerico"),
("Operación combinada con llaves y corchetes","MAT.OPE","MAT.OPE.JERARQ","Operación combinada","numerico"),
])
