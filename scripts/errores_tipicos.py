#!/usr/bin/env python3
"""Catálogo de errores típicos (Fase 05E parte 2, §4, D-107) → Educulter/Content/errores.json.

Cada error tiene un id `ERR.<competencia>.<n>`, una descripción en segunda persona (≤ 12 palabras),
un remedio (plantilla de la misma competencia, su dificultad y una regla breve) y los patrones que
lo detectan en el feedback de los distractores: `(generador, expresión regular)`. El generador
«estatico» se aplica a los ítems escritos a mano.

Los patrones salen de las formas reales de los distractores (arnés `errores`, 150 semillas × 6
niveles por plantilla aprobada). El test `ErroresTests` comprueba que ningún distractor de una
plantilla aprobada queda sin etiquetar. Idempotente: reescribe el archivo entero.
"""
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "Educulter/Content/errores.json"
PLANTILLAS = RAIZ / "Educulter/Content/plantillas"

DIFICULTAD = {}
for f in PLANTILLAS.glob("*.json"):
    for p in json.loads(f.read_text()):
        DIFICULTAD[p["id"]] = p["dificultad"]

ERRORES = []


def error(competencia, descripcion, remedio, explicacion, *detecta, tarjeta=None, dificultad=None, otra=False):
    n = sum(1 for e in ERRORES if e["competencia"] == competencia) + 1
    assert len(descripcion.split()) <= 12, descripcion
    assert len(explicacion) <= 140, explicacion
    assert otra or remedio.rsplit(".", 1)[0] == competencia, (remedio, competencia)
    r = {"plantilla": remedio, "dificultad": dificultad or DIFICULTAD[remedio], "explicacion": explicacion}
    if tarjeta:
        r["tarjeta"] = tarjeta
    ERRORES.append({"id": f"ERR.{competencia}.{n}", "competencia": competencia, "descripcion": descripcion,
                    "remedio": r, "detecta": [{"generador": g, "patron": p} for g, p in detecta]})


# ---------------------------------------------------------------- LENGUA

# Acentuación (LEN.ORT.AGU): sílaba tónica, clase de palabra y reglas de la tilde.
error("LEN.ORT.AGU", "Te cuesta localizar la sílaba tónica.", "LEN.ORT.AGU.G04",
      "Di la palabra despacio, como si llamaras a alguien: la sílaba que suena más fuerte es la tónica.",
      ("silabaTonica", r"^Pronuncia la palabra despacio"), ("colocarTilde", r"^La sílaba tónica es"),
      ("estatico", r"(?i)pronúncia|suena más fuerte|sílaba tónica|la tónica es"))
error("LEN.ORT.AGU", "Confundes palabras agudas, llanas y esdrújulas.", "LEN.ORT.AGU.G03",
      "Cuenta desde el final: tónica en la última, aguda; en la penúltima, llana; antes, esdrújula.",
      ("clasificarAcentuacion", r"\) es (aguda|llana|esdrújula|sobresdrújula):"),
      ("estatico", r"(?i)(aguda|llana|esdrújula) (sería|es la|tiene)"))
error("LEN.ORT.AGU", "Olvidas la tilde del hiato con vocal cerrada tónica.", "LEN.ORT.AGU.G02",
      "Si la i o la u tónica va junto a a, e, o y forman hiato, llevan tilde siempre: rí-o, ba-úl.",
      ("colocarTilde", r"con hiato: hiato"), dificultad=3)
error("LEN.ORT.AGU", "Olvidas la tilde que exige la regla.", "LEN.ORT.AGU.G01",
      "Agudas con tilde si acaban en vocal, -n o -s; llanas si no; esdrújulas, siempre.",
      ("colocarTilde", r"^«[^»]*» es (aguda|llana|esdrújula|sobresdrújula)"),
      ("estatico", r"(?i)lleva tilde|necesita tilde|falta la tilde"))
error("LEN.ORT.AGU", "Pones tilde donde la regla no la pide.", "LEN.ORT.AGU.G01",
      "Las llanas en vocal, -n o -s y las agudas en otra consonante no llevan tilde.",
      ("colocarTilde", r"^«[^»]*»: "), ("estatico", r"(?i)no lleva tilde|sin tilde"))

# Hiatos (LEN.ORT.HIA): solo ítems estáticos; el remedio es la colocación de tildes del nivel 3 (hiatos).
error("LEN.ORT.HIA", "Confundes hiato y diptongo.", "LEN.ORT.AGU.G02",
      "Vocal cerrada tónica junto a una abierta forma hiato y lleva tilde: rí-o, pa-ís, ba-úl.",
      ("estatico", r"."), dificultad=3, otra=True)

# Diacríticas (LEN.ORT.DIA).
error("LEN.ORT.DIA", "Confundes interrogativos con tilde y relativos sin ella.", "LEN.ORT.DIA.G01",
      "Qué, cómo, cuándo y dónde llevan tilde cuando preguntan o exclaman, también en preguntas indirectas.",
      ("fraseHueco", r"es (interrogativo|relativo o conjunción|comparativo o de modo|adverbio relativo)"),
      ("estatico", r"(?i)interrogativ|exclamativ|relativo"))
error("LEN.ORT.DIA", "Confundes monosílabos con y sin tilde diacrítica.", "LEN.ORT.DIA.G01",
      "La tilde distingue funciones: tú pronombre / tu posesivo; él / el artículo; sí afirmación / si condición.",
      ("fraseHueco", r"Aquí va «"), ("estatico", r"."))

# Por qué, porque, porqué, por que (LEN.ORT.PQ).
error("LEN.ORT.PQ", "Confundes porque, por qué, porqué y por que.", "LEN.ORT.PQ.G01",
      "Por qué pregunta; porque responde (causa); el porqué es un sustantivo; por que es preposición + que.",
      ("fraseHueco", r"."), ("estatico", r"."))

# Homófonos (LEN.ORT.HOM).
error("LEN.ORT.HOM", "Confundes homófonos con h y sin h.", "LEN.ORT.HOM.G01",
      "Hay es de haber, ahí es lugar, ay es queja; hecho es de hacer, echo de echar; a ver es mirar.",
      ("fraseHueco", r"es (verbo haber|adverbio de lugar|interjección|preposición \+ verbo ver|verbo echar|verbo hacer|verbo hallar|verbo haber o árbol|saludo|onda del mar|preposición de límite|palo de la bandera)"),
      ("estatico", r"(?i)\bh|hay|ahí|ay\b|haber|hecho|echo"))
error("LEN.ORT.HOM", "Confundes homófonos con b y con v.", "LEN.ORT.HOM.G01",
      "Mira el significado: tubo es pieza hueca y tuvo es de tener; votar es elegir y botar es saltar.",
      ("fraseHueco", r"Aquí va «"), ("estatico", r"."))

# Sintaxis (oracionSimple): las mismas confusiones en las cuatro competencias que lo usan.
SINTAXIS = [
    ("No localizas el sujeto por la concordancia con el verbo.", "SUJ",
     "El sujeto concuerda con el verbo: cambia el número del verbo y mira qué palabras cambian con él.",
     [r"^El sujeto concuerda", r"no concuerda con el verbo"]),
    ("Confundes los pronombres de CD (lo, la) y CI (le).", "PRON",
     "El CD se sustituye por lo, la, los, las; el CI, por le o les (se ante lo, la).",
     [r"se sustituye por"]),
    ("Confundes el complemento directo con otra función.", "CD",
     "El CD responde a «¿qué?» o «¿a quién?» y se sustituye por lo, la, los, las.",
     [r"^El complemento directo responde"]),
    ("Confundes el complemento indirecto con otra función.", "CI",
     "El CI lleva «a» o «para» y se sustituye por le o les.",
     [r"^El complemento indirecto lleva"]),
    ("Confundes los complementos circunstanciales.", "CC",
     "Pregunta al verbo: ¿dónde? (lugar), ¿cuándo? (tiempo), ¿cómo? (modo), ¿con quién? (compañía)…",
     [r"^El complemento circunstancial"]),
    ("No reconoces el atributo de los verbos copulativos.", "ATR",
     "Con ser, estar o parecer, lo que se dice del sujeto es el atributo: predicado nominal.",
     [r"atributo"]),
    ("Confundes oraciones transitivas e intransitivas.", "CLASE",
     "Si el verbo lleva CD, la oración es transitiva; si no lo lleva ni tiene atributo, intransitiva.",
     [r"predicado verbal (con|sin) CD"]),
]
REMEDIO_SIN = {
    "LEN.SIN.SUJPRED": {"*": "LEN.SIN.SUJPRED.G01"},
    "LEN.SIN.COMPL": {"PRON": "LEN.SIN.COMPL.G06", "*": "LEN.SIN.COMPL.G03"},
    "LEN.SIN.CLASE": {"*": "LEN.SIN.CLASE.G01"},
    "LEN.CLA.SUSTADJ": {"*": "LEN.CLA.SUSTADJ.G01"},
}
USADOS_SIN = {  # qué confusiones aparecen en cada competencia (comprobado con el arnés `etiquetas`)
    "LEN.SIN.SUJPRED": ["SUJ"],
    "LEN.SIN.COMPL": ["SUJ", "PRON", "CD", "CI", "CC", "ATR"],
    "LEN.SIN.CLASE": ["ATR", "CLASE"],
}
for comp, usados in USADOS_SIN.items():
    for desc, clave, expl, patrones in SINTAXIS:
        if clave not in usados:
            continue
        rem = REMEDIO_SIN[comp].get(clave, REMEDIO_SIN[comp]["*"])
        error(comp, desc, rem, expl, *[("oracionSimple", p) for p in patrones])

# Análisis verbal y formas no personales.
error("LEN.VER.ANALISIS", "Confundes el tiempo verbal.", "LEN.VER.ANALISIS.G02",
      "La terminación marca el tiempo (-aba, pretérito imperfecto); haber + participio forma los compuestos.",
      ("analisisVerbal", r"^(Fíjate en la terminación|Las formas con)"), ("estatico", r"(?i)pretérito|presente|futuro|condicional"))
error("LEN.VER.ANALISIS", "Confundes indicativo y subjuntivo.", "LEN.VER.ANALISIS.G04",
      "El indicativo presenta hechos; el subjuntivo, deseos, dudas o posibilidades: «que yo cante».",
      ("analisisVerbal", r"^El subjuntivo"), ("estatico", r"(?i)subjuntivo|indicativo"))
error("LEN.VER.ANALISIS", "Confundes el aspecto perfecto y el imperfecto.", "LEN.VER.ANALISIS.G04",
      "Son perfectos los tiempos compuestos y el pretérito perfecto simple; el resto de simples, imperfectos.",
      ("analisisVerbal", r"^Son perfectos"))
error("LEN.VER.ANALISIS", "Confundes formas simples y compuestas.", "LEN.VER.ANALISIS.G04",
      "Es compuesta si lleva el auxiliar haber y un participio: he cantado, habrás comido.",
      ("analisisVerbal", r"^Es compuesta"))
error("LEN.VER.NOPERS", "Confundes formas simples y compuestas no personales.", "LEN.VER.NOPERS.G03",
      "Las compuestas llevan haber: haber cantado (infinitivo), habiendo cantado (gerundio).",
      ("formasNoPersonales", r"Las compuestas"))
error("LEN.VER.NOPERS", "Confundes infinitivo, gerundio y participio.", "LEN.VER.NOPERS.G01",
      "Infinitivo en -ar, -er, -ir; gerundio en -ando, -iendo; participio en -ado, -ido (o irregular).",
      ("formasNoPersonales", r"^El infinitivo acaba"))

# Historia de la literatura: siglo y movimiento.
for comp, rem in [("LEN.LIT.HIST", "LEN.LIT.HIST.G01"), ("LEN.LIT.UNIV", "LEN.LIT.UNIV.G02"), ("LEN.LIT.INF", "LEN.LIT.INF.G02")]:
    error(comp, "Sitúas la obra en el siglo equivocado.", rem,
          "El siglo XVI va de 1501 a 1600: el siglo es la centena siguiente al año (1605 → siglo XVII).",
          ("literatura", r"^El siglo [IVXL]+ va de"))
    if comp != "LEN.LIT.HIST":
        continue  # los movimientos solo se preguntan en la literatura española
    error(comp, "Confundes el movimiento literario de la obra.", "LEN.LIT.HIST.G03" if comp == "LEN.LIT.HIST" else rem,
          "Asocia cada obra a su periodo y comprueba que el año cae dentro de sus fechas.",
          ("literatura", r"^[A-ZÁÉÍÓÚ][^«]*: \d{3,4}–"))

# ---------------------------------------------------------------- MATEMÁTICAS

error("MAT.DIV.MCD", "Das el número menor como m.c.d. sin comprobarlo.", "MAT.DIV.MCD.G01",
      "El m.c.d. divide a todos los números: comprueba la división antes de darlo por bueno.",
      ("mcmMcd", r"^El menor número no siempre divide"))
error("MAT.DIV.MCD", "Confundes el m.c.d. con el m.c.m.", "MAT.DIV.MCD.G01",
      "m.c.d.: factores comunes con el menor exponente. m.c.m.: comunes y no comunes con el mayor.",
      ("mcmMcd", r"mínimo común múltiplo|Multiplicar los números"), ("estatico", r"."))

error("MAT.EST.CENTRAL", "Calculas mal el rango.", "MAT.EST.CENTRAL.G01",
      "El rango es el dato mayor menos el dato menor.", ("estadisticaBasica", r"^El rango es"))
error("MAT.EST.CENTRAL", "Confundes la moda con el valor mayor.", "MAT.EST.CENTRAL.G01",
      "La moda es el dato que más se repite, sea grande o pequeño.", ("estadisticaBasica", r"^La moda es"))
error("MAT.EST.CENTRAL", "Buscas la mediana sin ordenar los datos.", "MAT.EST.CENTRAL.G01",
      "Ordena los datos de menor a mayor; la mediana es el del centro (o la media de los dos centrales).",
      ("estadisticaBasica", r"ordenar los datos"))
error("MAT.EST.CENTRAL", "Divides mal al calcular la media.", "MAT.EST.CENTRAL.G01",
      "La media es la suma de los datos dividida entre cuántos datos hay.",
      ("estadisticaBasica", r"^(La media se divide|Falta dividir)"))

error("MAT.NUM.ORDEN", "Comparas decimales sin igualar las cifras decimales.", "MAT.NUM.ORDEN.G01",
      "Iguala las cifras decimales (0,5 = 0,50) y pasa las fracciones a decimal antes de comparar.",
      ("ordenarNumeros", r"^Iguala las cifras decimales"))

error("MAT.NUM.FRAOP", "Sumas fracciones sin buscar un denominador común.", "MAT.NUM.FRAOP.G01",
      "Para sumar o restar fracciones, primero se reducen a común denominador.",
      ("fraccionesOperar", r"^Para sumar fracciones"))
error("MAT.NUM.FRAOP", "Divides fracciones sin invertir la segunda.", "MAT.NUM.FRAOP.G03",
      "Dividir entre una fracción es multiplicar por su inversa: a/b : c/d = (a·d)/(b·c).",
      ("fraccionesOperar", r"^Para dividir fracciones"))
error("MAT.NUM.FRAOP", "Multiplicas fracciones de forma incorrecta.", "MAT.NUM.FRAOP.G02",
      "Se multiplican numerador por numerador y denominador por denominador.",
      ("fraccionesOperar", r"^Para multiplicar fracciones"))

error("MAT.NUM.FRAPROB", "Das lo gastado en vez de lo que queda.", "MAT.NUM.FRAPROB.G01",
      "Lee la pregunta: si piden lo que queda, resta lo gastado del total.",
      ("problemaFraccion", r"^Eso es lo que gasta"))
error("MAT.NUM.FRAPROB", "Olvidas restar uno de los gastos.", "MAT.NUM.FRAPROB.G01",
      "Resta cada gasto, uno detrás de otro, antes de dar el resultado.",
      ("problemaFraccion", r"^Te falta restar"))
error("MAT.NUM.FRAPROB", "Aplicas la segunda fracción al total, no al resto.", "MAT.NUM.FRAPROB.G02",
      "«De lo que queda» significa que la segunda fracción se calcula sobre el resto, no sobre el total.",
      ("problemaFraccion", r"^La segunda fracción se aplica"))

for comp, rem in [("MAT.OPE.JER", "MAT.OPE.JER.G01"), ("MAT.OPE.COMB", "MAT.OPE.COMB.G01")]:
    error(comp, "No respetas la jerarquía de las operaciones.", rem,
          "Primero paréntesis, después multiplicaciones y divisiones, y por último sumas y restas.",
          ("operacionesCombinadas", r"^Primero paréntesis"))
    error(comp, "Sumas fracciones sin buscar un denominador común.", rem,
          "Para sumar o restar fracciones, primero se reducen a común denominador.",
          ("operacionesCombinadas", r"^Para sumar fracciones"))

error("MAT.OPE.ECUAC", "Al pasar un término no le cambias el signo.", "MAT.OPE.ECUAC.G01",
      "Lo que suma pasa restando y lo que resta pasa sumando al otro miembro.",
      ("ecuacionLineal", r"cambia de signo"))
error("MAT.OPE.ECUAC", "Despejas mal el número que multiplica a la x.", "MAT.OPE.ECUAC.G01",
      "Si 3x = 12, el 3 que multiplica pasa dividiendo: x = 12 : 3.",
      ("ecuacionLineal", r"^Lo que multiplica"))
error("MAT.OPE.ECUAC", "Agrupas mal los términos con x.", "MAT.OPE.ECUAC.G02",
      "x es 1x: al agrupar, x + 2x = 3x.", ("ecuacionLineal", r"^El número también cuenta"))
error("MAT.OPE.ECUAC", "No multiplicas por todos los términos del paréntesis.", "MAT.OPE.ECUAC.G03",
      "El número de fuera multiplica a cada término de dentro: 2(x + 3) = 2x + 6.",
      ("ecuacionLineal", r"^Multiplica .* paréntesis"))

error("MAT.OPE.INCOG", "Te quedas en el primer paso de dos.", "MAT.OPE.INCOG.G02",
      "Cuando hay dos igualdades, el valor de la primera se usa en la segunda.",
      ("terminoDesconocido", r"^Ese es el valor de a"))
error("MAT.OPE.INCOG", "No usas la operación contraria para despejar.", "MAT.OPE.INCOG.G02",
      "La resta deshace la suma y la división deshace la multiplicación.",
      ("terminoDesconocido", r"^Para despejar"))

# Porcentajes: los mismos errores en las tres competencias, con su remedio.
PORCENTAJES = [  # (descripción, competencias donde aparece, regla, patrones)
    ("Te equivocas con la coma al calcular un porcentaje.", "CALC TOTAL VAR",
     "El 15 % son 15 de cada 100: multiplica por 15 y divide entre 100.",
     [r"^Revisa la coma decimal", r"^Has dividido entre el porcentaje", r"^Aquí .* ya es el"]),
    ("Calculas lo que queda en lugar del porcentaje pedido.", "CALC TOTAL",
     "Lee qué se pide: el 20 % de algo no es lo que queda tras quitar el 20 %.",
     [r"^Has calculado lo que queda", r"^Has usado el porcentaje que falta", r"^El precio rebajado es el"]),
    ("Sumas o restas los puntos del porcentaje como si fueran euros.", "TOTAL VAR",
     "Un 10 % no son 10 €: calcula primero cuánto es ese porcentaje de la cantidad.",
     [r"puntos del porcentaje"]),
    ("Confundes subir y bajar un porcentaje.", "VAR",
     "Una rebaja se resta del precio; un aumento se suma.",
     [r"^Has sumado la rebaja", r"^Has restado el aumento"]),
    ("Te quedas en la variación y no das el precio final.", "VAR",
     "Calcula la rebaja o el aumento y después réstalo o súmalo al precio inicial.",
     [r"^Esa es la rebaja", r"^Ese es solo el aumento"]),
    ("Aplicas el porcentaje sobre la cantidad equivocada.", "TOTAL",
     "El porcentaje se calcula sobre la cantidad inicial, no sobre el resultado.",
     [r"sobre el resultado, no sobre la cantidad inicial"]),
    ("Sumas los porcentajes sucesivos en lugar de encadenarlos.", "VAR",
     "La segunda variación se aplica sobre el precio ya modificado: multiplica los factores.",
     [r"sucesiv", r"segunda variación", r"^Quitar el .* es multiplicar"]),
]
for comp in ["MAT.POR.CALC", "MAT.POR.TOTAL", "MAT.POR.VAR"]:
    rem = comp + ".G01"
    for desc, donde, expl, patrones in PORCENTAJES:
        if comp.rsplit(".", 1)[1] not in donde.split():
            continue
        error(comp, desc, rem, expl, *[("porcentajeDe", p) for p in patrones])

error("MAT.POR.PROP", "Sumas la diferencia en lugar de multiplicar.", "MAT.POR.PROP.G01",
      "En la proporcionalidad se multiplica por la razón; no se suma ni se resta la diferencia.",
      ("reglaDeTres", r"(No se suma la diferencia|pero no se (suma|resta))"))
error("MAT.POR.PROP", "Confundes la proporcionalidad directa con la inversa.", "MAT.POR.PROP.G02",
      "Directa: si una cantidad aumenta, la otra también. Inversa: si una aumenta, la otra disminuye.",
      ("reglaDeTres", r"^Es proporcionalidad (directa|inversa)"))
error("MAT.POR.PROP", "Dejas la regla de tres a medias.", "MAT.POR.PROP.G01",
      "Multiplica en cruz y divide entre el tercer dato; si hay dos pasos, haz los dos.",
      ("reglaDeTres", r"^(Has multiplicado|Ese es el coste|Eso son los litros)"))

error("MAT.PRO.LAPLACE", "Das la probabilidad del suceso contrario.", "MAT.PRO.LAPLACE.G01",
      "Cuenta los casos favorables al suceso que se pregunta, no los del contrario.",
      ("probabilidadSimple", r"suceso contrario"))
error("MAT.PRO.LAPLACE", "Cuentas mal los casos posibles.", "MAT.PRO.LAPLACE.G01",
      "Probabilidad = casos favorables : casos posibles (todos los resultados).",
      ("probabilidadSimple", r"^Los casos posibles|no entre desfavorables"))

for comp, rem in [("MAT.ROM.LEER", "MAT.ROM.LEER.G01"), ("MAT.ROM.ESCR", "MAT.ROM.ESCR.G01")]:
    if comp == "MAT.ROM.LEER":
        error(comp, "Sumas el símbolo menor que va delante del mayor.", rem,
          "Un símbolo menor delante de uno mayor se resta: IV = 4, IX = 9, XL = 40, CM = 900.",
          ("romanos", r"^Un símbolo menor delante"))
        error(comp, "Te equivocas en el valor de una parte del número.", rem,
          "Lee por partes: millares, centenas, decenas y unidades (MCMXC = 1000 + 900 + 90).",
          ("romanos", r"^Revisa [IVXLCDM]+: vale"))
    error(comp, "Repites o restas símbolos de forma no permitida.", "MAT.ROM.ESCR.G01" if comp == "MAT.ROM.ESCR" else rem,
          "V, L y D no se repiten; I, X y C, como mucho tres veces; solo se resta I, X o C.",
          ("romanos", r"^V, L y D no se repiten|está bien escrito"))

for comp in ["MAT.UNI.LMC", "MAT.UNI.SUP", "MAT.UNI.VOL"]:
    rem = comp + ".G01"
    error(comp, "Operas con medidas sin pasarlas a la misma unidad.", rem,
          "Antes de sumar o comparar, pasa todas las medidas a la misma unidad.",
          ("conversionUnidades", r"^Has sumado los números sin pasarlos"))
    error(comp, "Das un salto de unidad de más o de menos.", rem,
          "Cuenta los escalones entre las dos unidades: cada uno multiplica o divide por 10 (100 o 1000 en superficie y volumen).",
          ("conversionUnidades", r"salto de (más|menos)"))
    error(comp, "Multiplicas cuando hay que dividir, o al revés.", rem,
          "Al pasar a una unidad menor se multiplica; a una mayor, se divide.",
          ("conversionUnidades", r"^Al pasar a una unidad menor"))
    if comp != "MAT.UNI.LMC":
        error(comp, "Usas saltos de 10 en superficie o volumen.", rem,
              "En superficie cada escalón es ×100; en volumen, ×1000.",
              ("conversionUnidades", r"^En (volumen|superficie), cada salto"))
    if comp != "MAT.UNI.SUP":
        error(comp, "Confundes las equivalencias de capacidad, volumen y masa.", rem,
              "1 dm³ = 1 l y 1 cm³ = 1 ml; 1 l de agua pesa 1 kg.",
              ("conversionUnidades", r"l de agua pesa|tienen unidades distintas|Revisa la equivalencia"))

error("MAT.UNI.TIEM", "No haces las llevadas de 60 en 60.", "MAT.UNI.TIEM.G01",
      "Cada 60 segundos son 1 minuto y cada 60 minutos, 1 hora.", ("sexagesimal", r"^Revisa las llevadas"))
error("MAT.UNI.TIEM", "Tratas horas y minutos como números decimales.", "MAT.UNI.TIEM.G01",
      "1 h 30 min no es 1,30 h sino 1,5 h: el tiempo va de 60 en 60.", ("sexagesimal", r"^El tiempo no es decimal"))
error("MAT.UNI.TIEM", "Dejas la conversión de tiempo a medias.", "MAT.UNI.TIEM.G02",
      "Pasa todo a la unidad más pequeña (minutos o segundos) y suma.", ("sexagesimal", r"^Te has quedado a medias"))
error("MAT.UNI.TIEM", "Calculas mal los intervalos que pasan la medianoche.", "MAT.UNI.TIEM.G03",
      "Cuenta hasta las 24:00 y suma lo que falta desde las 0:00.", ("sexagesimal", r"medianoche"))

error("MAT.UNI.ESC", "Olvidas pasar el resultado a la unidad pedida.", "MAT.UNI.ESC.G01",
      "La escala da centímetros: pásalos a metros o kilómetros si lo pide el enunciado.",
      ("escala", r"^Has dejado el resultado"))
error("MAT.UNI.ESC", "No pasas las distancias a la misma unidad.", "MAT.UNI.ESC.G02",
      "Mapa y realidad deben estar en la misma unidad (normalmente centímetros) antes de dividir.",
      ("escala", r"^(Revisa|Pasa|Las dos distancias)"))
error("MAT.UNI.ESC", "Multiplicas o divides por la escala al revés.", "MAT.UNI.ESC.G01",
      "Del mapa a la realidad se multiplica por la escala; de la realidad al mapa, se divide.",
      ("escala", r"^(En el mapa|En el plano|Para pasar de la realidad)"))

# ---------------------------------------------------------------- JUEGOS (Fase 05G, D-121)

# J46 «De evidencia a resumen» (LEN.COM.TEMA): las pistas del generador y los distractores estáticos.
error("LEN.COM.TEMA", "Confundes un dato concreto con la idea central.", "LEN.COM.TEMA.G01",
      "Un dato apoya la idea central; la idea central explica de qué trata el texto o por qué importa.",
      ("evidenciaResumen", r"^(Ese dato apoya|Busca la frase)"),
      ("estatico", r"(?i)es un detalle|contraargumento|símbolos"))
error("LEN.COM.TEMA", "Eliges un tema demasiado concreto.", "LEN.COM.TEMA.G02",
      "El tema cubre todo el texto: si solo nombra una parte, es demasiado concreto.",
      ("evidenciaResumen", r"^Ese tema es demasiado concreto"))
error("LEN.COM.TEMA", "Eliges un tema demasiado general.", "LEN.COM.TEMA.G02",
      "Si el tema serviría para muchos textos distintos, es demasiado amplio.",
      ("evidenciaResumen", r"^Ese tema es demasiado amplio"))

# J63 «Corta y compensa» (MAT.GEO.AREA).
error("MAT.GEO.AREA", "Sumas el hueco en vez de restarlo.", "MAT.GEO.AREA.G02",
      "El hueco no forma parte de la región pintada: su área se resta.",
      ("areaCompuesta", r"^¿Esa parte pertenece a la región pintada"), ("estatico", r"^¿Esa parte pertenece a la región pintada"))
error("MAT.GEO.AREA", "Calculas el perímetro en vez del área.", "MAT.GEO.AREA.G01",
      "El perímetro suma los lados; el área mide la superficie: base por altura en cada rectángulo.",
      ("areaCompuesta", r"^Has sumado los lados"), ("estatico", r"^Has sumado los lados"))
error("MAT.GEO.AREA", "Olvidas dividir entre 2 en triángulos y semicírculos.", "MAT.GEO.AREA.G03",
      "Triángulo: base × altura : 2. Semicírculo: la mitad de π × radio × radio.",
      ("areaCompuesta", r"^(El área del triángulo es|Es medio círculo)"), ("estatico", r"^(El área del triángulo es|Es medio círculo)"))
error("MAT.GEO.AREA", "Das el área en unidades lineales.", "MAT.GEO.AREA.G01",
      "Metros por metros dan metros cuadrados: el área va en m² o cm².",
      ("areaCompuesta", r"^Multiplicas metros por metros"), ("estatico", r"^Multiplicas metros por metros"))
error("MAT.GEO.AREA", "No conviertes las medidas mixtas a la misma unidad.", "MAT.GEO.AREA.G06",
      "Antes de multiplicar, pasa todas las medidas a metros (o todas a centímetros).",
      ("areaCompuesta", r"^Pasa todas las medidas a la misma unidad"), ("estatico", r"^Pasa todas las medidas a la misma unidad"))
error("MAT.GEO.AREA", "Calculas mal el área de alguna parte.", "MAT.GEO.AREA.G01",
      "En cada parte, toma la base y la altura de esa parte, no las de la figura entera.",
      ("areaCompuesta", r"^Revisa (qué dos medidas|la suma)"), ("estatico", r"^Revisa (qué dos medidas|la suma)"))

SALIDA.write_text(json.dumps({"version": 1, "errores": ERRORES}, ensure_ascii=False, indent=1) + "\n")
print(f"{len(ERRORES)} errores en {len({e['competencia'] for e in ERRORES})} competencias → {SALIDA.relative_to(RAIZ)}")
