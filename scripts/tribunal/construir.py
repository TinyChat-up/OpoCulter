#!/usr/bin/env python3
"""Construye los datos del Modo Tribunal (borrador) a partir de los 7 exámenes oficiales.

Uso (desde la raíz del repositorio):
    python3 scripts/tribunal/construir.py

Escribe:
  - Educulter/Content/tribunal/<año>_<convocatoria>.json  (7 exámenes)
  - docs/examenes/SOLUCIONES_REVISION_<n>.md  (hoja de revisión, partes de < 40.000 caracteres)

Fuentes: docs/examenes/texto/*.txt (capa de texto y OCR), cotejados con los PDF de
docs/examenes/oficiales/ (ver docs/examenes/CORRECCIONES_OCR.md). Competencias: las de
scripts/matriz/datos.py, con los códigos del catálogo del lote 03a. Matemáticas: matematicas.py.
"""

import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ / "scripts" / "matriz"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from datos import R  # noqa: E402
from matematicas import SOLUCIONES as SOL_MAT  # noqa: E402

DESTINO = RAIZ / "Educulter" / "Content" / "pendiente" / "tribunal"
TEXTOS = RAIZ / "docs" / "examenes" / "texto"
FECHA_CONSULTA = "2026-11-23"
VALIDACION = {"estado": "aprobado", "revisor": "direccion", "fecha": "2026-11-24"}  # soluciones aprobadas por la dirección
AVISO = ("Examen oficial publicado por la Comunidad de Madrid. Reproducido sin alteraciones según sus "
         "condiciones de reutilización. Esta app no está patrocinada ni avalada por la Comunidad de Madrid.")
AVISO_PROTEGIDO = " El texto base está protegido por derechos de autor y no se reproduce. Consúltalo en el PDF oficial."
CITA_PROTEGIDA = "[Cita del texto base protegido: consúltese en el PDF oficial]"
# Códigos propuestos (†) que el lote 03a ya llevó al catálogo.
REMAPEO = {"LEN.COM.RESUMEN": "LEN.COM.RESU", "LEN.COM.SENTIDO": "LEN.COM.INFER", "LEN.COM.TIPOLOGIA": "LEN.COM.TIPO",
           "LEN.LEX.CONTEXTO": "LEN.LEX.CTX", "LEN.LEX.POLISEMIA": "LEN.LEX.POLI", "LEN.LEX.SINON": "LEN.LEX.SIN"}
# Ajustes puntuales a competencias del catálogo del lote 03a más precisas que las de la matriz.
AJUSTES = {(2026, "Ordinaria", "Lengua", 5): ["LEN.LEX.DICC"], (2026, "Aplazada", "Lengua", 5): ["LEN.LEX.CAMPO", "LEN.LEX.SIN"]}


def competencias(anio, conv, area, n):
    if (anio, conv, area, n) in AJUSTES:
        return AJUSTES[(anio, conv, area, n)]
    fila = [r for r in R if r[0] == anio and r[1] == conv and r[2] == area and r[3] == n]
    assert len(fila) == 1, (anio, conv, area, n)
    c = fila[0][6].rstrip("†")
    return [REMAPEO.get(c, c)]


def fragmento(archivo, desde, hasta):
    """Texto entre dos líneas (incluidas) del .txt, uniendo los guiones de fin de línea."""
    lineas = (TEXTOS / archivo).read_text(encoding="utf-8").splitlines()
    i = next(k for k, l in enumerate(lineas) if l.startswith(desde))
    j = next(k for k, l in enumerate(lineas) if k >= i and l.startswith(hasta))
    return lineas[i:j + 1]


def prosa(lineas):
    """Une renglones de prosa en párrafos. Un guion final es una palabra partida por el renglón. Hay fin de
    párrafo cuando el renglón termina en puntuación final y el siguiente empieza por mayúscula o raya."""
    texto, parrafo = [], ""
    for k, l in enumerate(lineas):
        if parrafo.endswith("-"):
            parrafo = parrafo[:-1] + l
        else:
            parrafo = (parrafo + " " + l).strip() if parrafo else l
        siguiente = lineas[k + 1] if k + 1 < len(lineas) else ""
        fin = ((l.rstrip()[-1:] in ".!?)…" and (siguiente[:1].isupper() or siguiente.startswith("—")))
               or (l.rstrip().endswith(":") and siguiente.startswith("—")) or l.strip() == "I")
        if fin or not siguiente:
            texto.append(parrafo)
            parrafo = ""
    return "\n".join(texto)


B = "bien"


def rub(bien, regular, mal):
    return {"bien": bien, "regular": regular, "mal": mal}


# Rúbricas de redacción propia, siguiendo el modelo de las plantillas oficiales de 2026.
def r_resumen():
    return rub("Recoge el contenido principal en orden, con palabras propias y sin detalles accesorios, e identifica el tema.",
               "Recoge solo parte del contenido principal o copia frases del texto.",
               "No identifica el tema o el resumen es incorrecto o insuficiente.")


def r_lista(que, total):
    return rub(f"{que} correctamente los {total} elementos.", f"Comete un error en uno de los {total} elementos.",
               "Comete más de un error o no completa la actividad.")


def r_formas(n):
    return rub(f"Analiza correctamente las {n} formas (persona, número, tiempo, modo e infinitivo).",
               "Comete un error en una de las formas o en uno de sus rasgos.", "Comete varios errores o no completa la actividad.")


def r_sintaxis():
    return rub("Realiza un análisis sintáctico correcto y completo de la oración (sujeto, predicado y complementos).",
               "El análisis es parcialmente correcto: identifica sujeto y predicado pero yerra en algún complemento.",
               "El análisis es incorrecto o incompleto.")


def r_calculo(que):
    return rub(f"{que}", "Plantea bien el procedimiento, pero comete un error de cálculo o en un apartado.",
               "No plantea correctamente el problema o no responde.")


def r_explica(bien):
    return rub(bien, "La explicación es correcta pero incompleta o imprecisa.", "La explicación es incorrecta o no responde.")


# Plantillas oficiales de 2026 (texto literal, reconstruido por columnas con pdftotext -layout).
OFICIAL = {
    ("O", "LEN"): [
        ("Resume correctamente el contenido y el tema del fragmento.", "Resume parcialmente el contenido principal.", "No identifica bien el tema o el resumen es incorrecto o insuficiente."),
        ("Reconoce el tipo de texto y explica los rasgos del texto con claridad.", "Identifica el texto, pero explica solo algunos rasgos del texto.", "No identifica correctamente el tipo de texto ni sus características."),
        ("Sitúa correctamente la obra, el autor y el periodo histórico.", "Menciona solo parte de los datos o los explica con imprecisión.", "No identifica correctamente autor, obra o contexto."),
        ("Escribe correctamente todos los prefijos y su significado.", "Presenta un error en los prefijos o en algún significado.", "Comete varios errores o no completa la actividad."),
        ("Explica con claridad qué es un diccionario y sus utilidades.", "Da una explicación general, pero incompleta.", "No define correctamente el diccionario ni sus usos."),
        ("Clasifica correctamente las clases de palabras.", "Comete un error en la clasificación.", "Comete más de un error o no responde."),
        ("Selecciona correctamente las opciones y justifica adecuadamente.", "Tiene un error o justificaciones poco precisas.", "Presenta varios errores o no justifica."),
        ("Define correctamente todos los términos.", "Define parcialmente los términos, con alguna imprecisión.", "No define correctamente la mayoría de los términos."),
        ("Relaciona correctamente todos los términos con sus definiciones.", "Comete un error en las relaciones.", "Comete varios errores o no completa la actividad."),
        ("Realiza un análisis sintáctico correcto de la oración.", "El análisis es parcialmente correcto.", "El análisis es incorrecto o incompleto."),
    ],
    ("O", "MAT"): [
        ("Responde correctamente y expresa también la fracción irreducible.", "Responde de forma parcialmente correcta.", "La respuesta es incorrecta o incompleta."),
        ("Expresa correctamente las tres potencias.", "Comete un error en una de las potencias.", "Comete más de un error."),
        ("Calcula correctamente la fracción restante.", "Plantea bien el problema, pero comete un error de cálculo.", "No resuelve correctamente el problema."),
        ("Completa correctamente toda la tabla.", "Comete un error en una equivalencia.", "Presenta más de un error."),
        ("Calcula correctamente la probabilidad estimada.", "Plantea bien el procedimiento, pero comete un error.", "No calcula correctamente la probabilidad."),
        ("Calcula correctamente el porcentaje pedido.", "Comete un error de cálculo.", "No resuelve correctamente."),
        ("Calcula correctamente el área exterior, el círculo y la superficie final.", "Realiza parte del procedimiento correctamente.", "No resuelve correctamente el problema."),
        ("Completa correctamente la tabla de divisibilidad.", "Comete uno o dos errores.", "Comete más de dos errores."),
        ("Completa correctamente la tabla de frecuencias.", "Comete un error en la tabla.", "No completa correctamente la tabla."),
        ("Calcula correctamente todas las medidas reales.", "Comete un error en una equivalencia.", "Presenta más de un error."),
    ],
    ("A", "LEN"): [
        ("Explica con claridad tema y contenido.", "Recoge solo parte del sentido.", "No interpreta adecuadamente el poema."),
        ("Identifica al autor y lo sitúa bien en su contexto.", "Menciona al autor con datos incompletos.", "No identifica al autor o se equivoca."),
        ("Justifica bien la idea de destino trágico con pruebas textuales.", "Aporta una justificación parcial.", "No justifica o lo hace incorrectamente."),
        ("Clasifica correctamente todas las palabras y justifica bien.", "Comete un error o una justificación insuficiente.", "Comete varios errores de clasificación."),
        ("Resuelve correctamente familia léxica, campo semántico y relaciones léxicas.", "Resuelve tres partes con precisión.", "Comete varios errores."),
        ("Identifica recursos literarios y realiza bien la medida.", "Acierta sólo parte de la cuestión.", "No identifica los recursos o mide mal ambos versos."),
        ("Selecciona y explica correctamente todas las opciones.", "Tiene uno o dos fallos menores.", "Comete varios errores."),
        ("Relaciona bien los términos con las definiciones.", "Comete un error.", "Comete más de un error."),
        ("Distingue primitivas, derivadas y compuestas con justificación.", "Comete un error de clasificación.", "Comete varios errores o no justifica."),
        ("Realiza un análisis sintáctico completo y correcto.", "Análisis parcialmente correcto.", "Análisis incorrecto o muy incompleto."),
    ],
    ("A", "MAT"): [
        ("Resuelve correctamente la secuencia de fracciones.", "Comete un error de cálculo menor.", "No resuelve el problema."),
        ("Convierte y suma bien todas las unidades de tiempo.", "Tiene una conversión o suma incorrecta.", "No completa correctamente la conversión."),
        ("Calcula correctamente a y b.", "Acierta solo uno de los valores.", "No obtiene los valores correctos."),
        ("Ordena correctamente todos los números.", "Comete un error en el orden.", "El orden es incorrecto en varios casos."),
        ("Resuelve bien la proporcionalidad.", "Comete un error aislado de cálculo.", "No mantiene la proporción."),
        ("Relaciona bien los sucesos y las probabilidades.", "Comete un error.", "Comete varios errores."),
        ("Calcula correctamente volumen y litros.", "Acierta solo una de las dos partes.", "No resuelve la cuestión."),
        ("Obtiene bien media, mediana, moda y rango.", "Comete un error.", "Comete varios errores."),
        ("Convierte correctamente los números romanos.", "Comete un error.", "Comete varios errores."),
        ("Resuelve correctamente la operación combinada.", "Comete un error de proceso o cálculo.", "No respeta la jerarquía de operaciones."),
    ],
}

# ======================================================================= EXÁMENES
EXAMENES = []

# ----------------------------------------------------------------------- 2017
lineas = fragmento("2017_comun.txt", "La noche de difuntos", "Gustavo Adolfo Bécquer")
texto2017 = prosa(lineas[:-1])
EXAMENES.append({
    "archivo": "2017_ordinaria", "id": "OF.2017.O", "anio": 2017, "convocatoria": "ordinaria", "clave": (2017, "Ordinaria"),
    "fuente": "https://www.comunidad.madrid/docs/assets/2019/11/14/edu_rrhh_0371_2017_examen_comun.pdf",
    "textoBase": {"texto": texto2017, "autor": "Gustavo Adolfo Bécquer", "obra": "El monte de las ánimas", "protegido": False, "anioMuerteAutor": 1870},
    "puntosNota": "El cuadernillo de 2017 no indica la puntuación de cada pregunta (9 de Lengua y 10 de Matemáticas); se asigna 1 punto a cada una.",
    "avisoExtra": " Puntuación por pregunta asignada por la app; el cuadernillo no la indica.",
    "LEN": [
        ("Resuma el contenido del texto.",
         "El narrador, despertado en la noche de difuntos por el doble de las campanas, decide escribir una tradición que oyó en Soria. "
         "En ella, Alonso pide a la comitiva de caza volver a la ciudad porque es día de Todos los Santos y están en el Monte de las Ánimas; "
         "su prima Beatriz se burla de su temor y él le cuenta la leyenda: el monte perteneció a los templarios y su rivalidad con los nobles "
         "castellanos acabó en una cacería convertida en batalla sangrienta; el rey abandonó el monte y la capilla, y desde entonces, cada noche "
         "de difuntos, la campana dobla sola y las ánimas de los muertos corren por el monte. Al terminar el relato, la comitiva entra en Soria. "
         "Tema: una leyenda de misterio sobre las ánimas que vuelven en la noche de difuntos.", r_resumen()),
        ("¿En qué época cree que sucede la historia que Alonso le cuenta a Beatriz?",
         "En la Edad Media, en la época de la Reconquista (siglos XII-XIII): Soria acaba de ser conquistada a los árabes y el rey trae a la Orden "
         "del Temple (disuelta en 1312) para defenderla. Lo confirman los templarios, los condes, los pajes, los hidalgos y la autoridad del rey.",
         rub("Sitúa la historia en la Edad Media y lo justifica con indicios del texto (templarios, conquista a los árabes, condes, pajes).",
             "Indica la Edad Media sin justificarlo o con una justificación imprecisa.", "Sitúa la historia en otra época o no responde.")),
        ("Explique el significado de las siguientes palabras atendiendo a su sentido en el texto.\nDoblar\nCundió\nTañido\nBreña\nAgravio",
         "Doblar: tocar a muerto las campanas. Cundió: se extendió, se propagó (la noticia del reto). Tañido: sonido de la campana al tocarla. "
         "Breña: tierra quebrada, entre peñas, poblada de maleza. Agravio: ofensa o afrenta a la honra o a los derechos de alguien.",
         rub("Explica correctamente las 5 palabras según su sentido en el texto.", "Explica bien 3 o 4 palabras.", "Explica bien 2 palabras o menos.")),
        ("¿A qué movimiento cultural cree que pertenece el texto?",
         "Al Romanticismo (en su etapa tardía o posromántica): es una de las Leyendas de Gustavo Adolfo Bécquer (1836-1870), publicada en 1861.",
         rub("Identifica el Romanticismo (o posromanticismo) y, en su caso, al autor.", "Lo sitúa en el siglo XIX sin precisar el movimiento.",
             "Indica otro movimiento o no responde.")),
        ("¿Cuáles son las principales características de este movimiento cultural?",
         "Rechazo de las normas neoclásicas y libertad creadora; subjetivismo y exaltación de los sentimientos; gusto por lo sobrenatural, el misterio "
         "y lo legendario (presente en el texto: ánimas, campana que dobla sola); evasión hacia la Edad Media y lo exótico; ambientes nocturnos, ruinas "
         "y cementerios (capilla ruinosa, noche de difuntos); naturaleza agreste que refleja el estado de ánimo; recuperación de tradiciones populares "
         "y nacionales; mezcla de géneros, de prosa y verso.",
         rub("Explica al menos cuatro rasgos del Romanticismo y relaciona alguno con el texto.", "Cita dos o tres rasgos o los enumera sin explicarlos.",
             "Los rasgos son erróneos o no responde.")),
        ("Analice las formas verbales subrayadas del siguiente texto:\nNo, hermosa prima; tú ignoras cuanto sucede en este país, porque aún no hace un año "
         "que has venido a él desde muy lejos. Refrena tu yegua, yo también pondré la mía al paso, y mientras dure el camino te contaré esa historia.\n"
         "ignoras\nhas venido\npondré",
         "Ignoras: 2.ª persona del singular del presente de indicativo del verbo ignorar (1.ª conjugación); aspecto imperfectivo, voz activa. "
         "Has venido: 2.ª persona del singular del pretérito perfecto compuesto de indicativo del verbo venir (3.ª conjugación, irregular); aspecto perfectivo. "
         "Pondré: 1.ª persona del singular del futuro simple de indicativo del verbo poner (2.ª conjugación, irregular); aspecto imperfectivo.", r_formas(3)),
        ("Cite cuatro poetas de la Generación del 27.",
         "Por ejemplo: Pedro Salinas, Jorge Guillén, Gerardo Diego, Federico García Lorca, Vicente Aleixandre, Dámaso Alonso, Rafael Alberti, "
         "Luis Cernuda, Emilio Prados o Manuel Altolaguirre.", r_lista("Cita", 4)),
        ("Ordene del más antiguo al más moderno a los siguientes autores:\nLope de Vega • Garcilaso de la Vega • Luis Cernuda • José de Espronceda • "
         "Benito Pérez Galdós • Carmen Martín Gaite",
         "1. Garcilaso de la Vega (c. 1501-1536); 2. Lope de Vega (1562-1635); 3. José de Espronceda (1808-1842); 4. Benito Pérez Galdós (1843-1920); "
         "5. Luis Cernuda (1902-1963); 6. Carmen Martín Gaite (1925-2000).", r_lista("Ordena", 6)),
        ("Analice sintácticamente la siguiente oración:\n“El gato maullaba tristemente en la ventana”",
         "Oración simple, enunciativa afirmativa, predicativa, intransitiva y activa. Sujeto: «El gato» (SN: Det «El» + N «gato»). "
         "Predicado verbal: «maullaba tristemente en la ventana» (SV): N «maullaba»; CCM «tristemente» (SAdv); CCL «en la ventana» "
         "(SPrep: E «en» + término SN «la ventana»).", r_sintaxis()),
    ],
    "MAT": [
        ("Calcule el valor de a y b para que se cumplan estas igualdades:\n1,5 x a = 300    8888 : b = 40", r_calculo("Calcula correctamente a y b.")),
        ("Ordene de mayor a menor los siguientes números: 2/3   0,5   1/4   0,6", r_calculo("Ordena correctamente los cuatro números.")),
        ("¿Cuáles de estas fracciones son equivalentes y, por tanto, representan la misma cantidad?\n12/20   48/112   90/150",
         r_calculo("Identifica las dos fracciones equivalentes y lo justifica.")),
        ("a) ¿Cuántos grados debería tener un ángulo para ser complementario de un ángulo de 80 grados?\n"
         "b) ¿Cuántos grados debería tener un ángulo para ser suplementario de un ángulo de 25 grados?", r_calculo("Calcula correctamente los dos ángulos.")),
        ("Un Ayuntamiento dispone de una parcela cuadrada con un lado de 4 metros y una rotonda con un radio de 3 metros. ¿De cuántos metros cuadrados "
         "dispone el Ayuntamiento en total? Tómese π = 3,14.", r_calculo("Calcula correctamente las dos áreas y su suma.")),
        ("Escriba en números romanos:\n334   975   2069", r_lista("Escribe", 3)),
        ("En una tienda de electrodomésticos hay un cartel con una rebaja del 15% sobre todos los artículos. Si un ordenador cuesta 675 €, ¿cuánto pagará por él?",
         r_calculo("Calcula correctamente el precio final.")),
        ("Una abogada viaja cada 36 días a San Sebastián y un comercial cada 48 días. Hoy han coincidido los dos en la ciudad. ¿Cuántos días pasarán "
         "para que vuelvan a coincidir?", r_calculo("Calcula el m.c.m. y responde correctamente.")),
        ("Complete para que las igualdades sean ciertas, siguiendo el sistema internacional:\na) ___ kl = 1928 l   b) 0,53 hm = ___ m   c) 7 g = ___ kg\n"
         "d) ___ ha = 70.000 m2   e) 9 ml = ___ dm3   f) 54 dam = ___ mm", r_lista("Completa", 6)),
        ("Resuelva la siguiente operación combinada:\n(16 x 8 + 12) : 4 - 3 (38 - 5 x 4) =", r_calculo("Resuelve correctamente la operación respetando la jerarquía.")),
    ],
})

# ----------------------------------------------------------------------- 2019 O
EXAMENES.append({
    "archivo": "2019_ordinaria", "id": "OF.2019.O", "anio": 2019, "convocatoria": "ordinaria", "clave": (2019, "Ordinaria"),
    "fuente": "https://www.comunidad.madrid/docs/assets/2019/11/15/edu_rrhh_0371_2019_examen_prueba_comun.pdf",
    "textoBase": {"texto": None, "autor": "Pedro Salinas", "obra": "La voz a ti debida", "protegido": True, "anioMuerteAutor": 1951},
    "LEN": [
        ("Explique la temática del poema y coméntelo brevemente.",
         "Tema: el anhelo amoroso; el yo poético espera la llamada de la amada y estaría dispuesto a abandonarlo todo por ella. Comentario: poema de "
         "La voz a ti debida (1933), de Pedro Salinas, cumbre de su poesía amorosa. El amor se presenta como algo que trasciende lo material: el yo "
         "lo dejaría todo (enumeración de objetos y recuerdos) y espera que la voz llegue «desde un milagro», no desde lo cotidiano. Verso libre de "
         "arte menor, tono conversacional e íntimo, exclamaciones y anáforas que expresan el deseo, y juegos conceptuales (paradojas) característicos "
         "del autor.", rub("Explica el tema y comenta con acierto la forma y el sentido del poema.", "Explica el tema, pero el comentario es pobre o impreciso.",
                           "No identifica el tema o no comenta el poema.")),
        ("¿En qué generación podemos incluir al autor?", "En la Generación del 27 (Pedro Salinas, 1891-1951).",
         rub("Indica la Generación del 27.", "Lo sitúa en la vanguardia o en el siglo XX sin precisar la generación.", "Indica otra generación o no responde.")),
        ("¿Qué figura literaria podemos encontrarnos en estos versos? Marque la opción correcta.\n" + CITA_PROTEGIDA +
         "\nEnumeración.\nMetonimia.\nHipérbaton.\n" + CITA_PROTEGIDA + "\nSinécdoque.\nAnáfora.\nComparación.",
         "Primer fragmento: enumeración (serie de elementos que lo dejaría todo). Segundo fragmento: anáfora (repetición de «si me llamaras» al comienzo de los versos).",
         rub("Marca las dos figuras correctas.", "Acierta una de las dos.", "No acierta ninguna.")),
        ("Explique brevemente qué es una metáfora.",
         "Figura retórica que identifica un término real con otro imaginario con el que guarda alguna semejanza, sin nexo comparativo "
         "(«tus dientes son perlas»; metáfora pura: «las perlas de tu boca»).",
         r_explica("Define la metáfora con precisión (identificación por semejanza, sin nexo) y, si acaso, pone un ejemplo.")),
        ("En los siguientes versos, aparece la palabra “si” con tilde y sin tilde, explique la diferencia.\n" + CITA_PROTEGIDA,
         "Es un caso de tilde diacrítica. «Si» sin tilde es una conjunción (aquí introduce una exclamación de deseo, con valor condicional: «¡si me llamaras!»). "
         "«Sí» con tilde es un adverbio de afirmación (también puede ser pronombre reflexivo: «para sí»).",
         r_explica("Identifica la conjunción «si» y el adverbio de afirmación «sí» como tilde diacrítica.")),
        ("Analice las siguientes formas verbales del texto:\nllamaras\nespero\nllamas",
         "Llamaras: 2.ª persona del singular del pretérito imperfecto de subjuntivo del verbo llamar. Espero: 1.ª persona del singular del presente "
         "de indicativo del verbo esperar. Llamas: 2.ª persona del singular del presente de indicativo del verbo llamar.", r_formas(3)),
        ("Incluya los siguientes adjetivos en la casilla correspondiente:\nviejos, mejor, menor, dulcísimo, peor, triste, azul, óptimo, ínfimo.\n"
         "POSITIVOS / COMPARATIVOS / SUPERLATIVOS",
         "Positivos: viejos, triste, azul. Comparativos: mejor, menor, peor (comparativos sintéticos de bueno, pequeño y malo). "
         "Superlativos: dulcísimo, óptimo, ínfimo (superlativos absolutos).", r_lista("Clasifica", 9)),
        ("Cite cuatro narradores españoles que naciesen en el Siglo XX.",
         "Por ejemplo: Camilo José Cela (1916), Miguel Delibes (1920), Carmen Laforet (1921), Ana María Matute (1925), Carmen Martín Gaite (1925), "
         "Rafael Sánchez Ferlosio (1927), Juan Marsé (1933), Eduardo Mendoza (1943), Javier Marías (1951), Antonio Muñoz Molina (1956).", r_lista("Cita", 4)),
        ("Ordene del más antiguo al más moderno a los siguientes autores:\nGustavo Adolfo Bécquer, José de Espronceda, Francisco de Quevedo, "
         "Juan Ramón Jiménez, José Hierro, Juan Boscán.",
         "1. Juan Boscán (c. 1490-1542); 2. Francisco de Quevedo (1580-1645); 3. José de Espronceda (1808-1842); 4. Gustavo Adolfo Bécquer (1836-1870); "
         "5. Juan Ramón Jiménez (1881-1958); 6. José Hierro (1922-2002).", r_lista("Ordena", 6)),
        ("Analice sintácticamente la siguiente oración:\nEl hombre permaneció quieto sobre la acera.",
         "Oración simple, enunciativa afirmativa. Sujeto: «El hombre» (SN: Det + N). Predicado: «permaneció quieto sobre la acera»: N «permaneció» "
         "(verbo semicopulativo); «quieto» (SAdj), complemento predicativo del sujeto (concuerda con «hombre»; la NGLE lo trata como atributo de un verbo "
         "semicopulativo); CCL «sobre la acera» (SPrep: E «sobre» + término SN «la acera»).", r_sintaxis()),
    ],
    "MAT": [
        ("Resuelva las siguientes operaciones y, si es posible, simplifique la fracción resultante:\na) 4/5 + 2/10 + 2/15 − 2/5 =\nb) 3/4 + 2/6 − 3/12 =\n"
         "c) 4/9 + 2/6 − 2/5 =\nd) 2/6 + 6/12 + 7/6 − 2/3 =", r_lista("Resuelve y simplifica", 4)),
        ("Exprese las siguientes cantidades en lo que se indica:\na) 10h 10’ = ___ segundos\nb) 170’ 600’’ = ___ horas\nc) 110’ 300’’ = ___ minutos",
         r_lista("Convierte", 3)),
        ("Calcule el valor de a y b para que se cumplan estas igualdades:\n44 x a = 1012\n2425 : b = 485", r_calculo("Calcula correctamente a y b.")),
        ("Ordene de mayor a menor los siguientes números:\n4/7; 0,4; 1/2; 3,3", r_calculo("Ordena correctamente los cuatro números.")),
        ("Queremos llenar de agua una piscina que tiene las siguientes dimensiones:\n• 7 metros de largo.\n• 50 decímetros de ancho.\n"
         "• 300 centímetros de profundidad.\n¿Cuántos litros de agua necesitaremos?\na) 10500\nb) 105000\nc) 52500",
         r_calculo("Elige la opción correcta (b) y la justifica con el cálculo.")),
        ("En una clase, tras finalizar la entrega de un trabajo, los diferentes grupos obtienen los siguientes resultados.\n"
         "Resultados: Grupo 1: 6; Grupo 2: 4; Grupo 3: 7; Grupo 4: 9; Grupo 5: 9.\nHalle la media aritmética, la moda y el rango de los resultados.",
         r_lista("Calcula", 3)),
        ("En las elecciones para delegado de una clase, los candidatos obtienen los siguientes votos:\nJuan: 5 votos • María: 15 votos • Luisa: 3 votos • "
         "Roberto: 2 votos\nRellene esta tabla con la frecuencia absoluta, la frecuencia relativa y el porcentaje.\n"
         "(Tabla: Candidatos | Frecuencia absoluta | Frecuencia relativa | %)", rub("Completa correctamente toda la tabla.", "Comete un error en la tabla.",
                                                                                  "Comete más de un error.")),
        ("Un colegio dispone de varios espacios para diseñar su patio. Necesita hacer pistas para dos zonas rectangulares de 3 decámetros por 10 metros y "
         "de 0,5 hectómetros por 30 metros. También dispone de una zona circular de 1000 centímetros de radio, donde se planea colocar una canasta de "
         "baloncesto. Si se quieren pavimentar todas esas secciones del patio ¿cuántos metros cuadrados será necesario pavimentar? Entiéndase π=3,14",
         r_calculo("Convierte las unidades y calcula correctamente las tres áreas y su suma.")),
        ("Escriba en números romanos:\n824   1223   793", r_lista("Escribe", 3)),
        ("Resuelva la siguiente operación combinada:\n[(16 x 8 + 12) : 4] + [3 (38 - 5 x 4)] =", r_calculo("Resuelve correctamente la operación respetando la jerarquía.")),
    ],
})

# ----------------------------------------------------------------------- 2019 A
EXAMENES.append({
    "archivo": "2019_aplazada", "id": "OF.2019.A", "anio": 2019, "convocatoria": "aplazada", "clave": (2019, "Aplazada"),
    "fuente": "https://www.comunidad.madrid/docs/assets/2019/11/15/edu_rrhh_0371_2019_examen_prueba_comun_aplazada.pdf",
    "textoBase": {"texto": None, "autor": "Carmen Laforet", "obra": "Nada", "protegido": True, "anioMuerteAutor": 2004},
    "LEN": [
        ("Resuma el contenido del texto y coméntelo brevemente.",
         "Resumen: de noche, la narradora llega al ábside de la catedral (de Barcelona); oye una tos ronca y se asusta al ver salir de la oscuridad a un "
         "viejo de aspecto miserable; llevada por un impulso, lo sigue, le da dos pesetas y él las guarda con ironía, sin hablar. Ya más calmada, llega a "
         "la fachada principal y la contemplación de la catedral le transmite paz y cumple el deseo que la había llevado hasta allí. Comentario: fragmento "
         "de Nada (1945), de Carmen Laforet, novela de la primera posguerra narrada en primera persona por Andrea. Contrasta la sordidez y el miedo de las "
         "callejuelas con la armonía y la paz de la catedral; abundan las impresiones sensoriales (luces, sonidos), la adjetivación expresiva y las "
         "comparaciones y personificaciones, que reflejan el estado de ánimo de la protagonista.", r_resumen()),
        ("Comente brevemente esta frase explicando lo que la narradora quiere decir.\n" + CITA_PROTEGIDA,
         "Mediante una comparación (símil), la narradora juzga su propia conducta: se considera insensata porque actúa por impulsos, sin control ni "
         "voluntad, arrastrada por las emociones de la noche (el vino, la música, el miedo), igual que una hoja de papel que el viento lleva de un lado "
         "a otro. Expresa su desorientación y su pasividad.",
         r_explica("Explica la comparación y su sentido: la narradora actúa sin voluntad, a merced de sus impulsos.")),
        ("Explique el significado de las siguientes palabras atendiendo a su sentido en el texto.\nÁbside:\nCarraspeo:\nInusitada:\nBronca:\nArmonía:",
         "Ábside: parte de la iglesia, abovedada y por lo general semicircular, que sobresale en la fachada posterior, tras el altar mayor. "
         "Carraspeo: ruido que se hace con la garganta al aclararla; tos ronca. Inusitada: no habitual, extraordinaria. Bronca: áspera, ronca (dicho de "
         "la tos o la voz). Armonía: proporción y equilibrio agradable entre las partes de un conjunto.",
         rub("Explica correctamente las 5 palabras según su sentido en el texto.", "Explica bien 3 o 4 palabras.", "Explica bien 2 palabras o menos.")),
        ("Defina los siguientes términos:\nNeologismo:\nArcaísmo:\nEufemismo:\nMorfema:\nAcrónimo:",
         "Neologismo: palabra o acepción nueva en una lengua (por ejemplo, «tuitear»). Arcaísmo: palabra, expresión o construcción anticuada, en desuso "
         "(«fermoso»). Eufemismo: palabra o expresión que sustituye a otra considerada malsonante, dura o tabú («pasar a mejor vida»). Morfema: unidad "
         "mínima de la palabra con significado gramatical, que se une al lexema (flexivos, como el plural -s, y derivativos, como el sufijo -ero). "
         "Acrónimo: palabra formada con letras o segmentos de varias palabras que se lee como una palabra («ovni», «Renfe», «Mercosur»).",
         rub("Define correctamente los 5 términos.", "Define bien 3 o 4 términos o con alguna imprecisión.", "Define bien 2 términos o menos.")),
        ("Agrupe las siguientes palabras derivadas según si están creadas mediante sufijación o prefijación:\nfloral, rosaleda, reformar, imposible, "
         "mesonero, inmaduro, multicolor, motorizar.\nSUFIJACIÓN / PREFIJACIÓN",
         "Sufijación: floral, rosaleda, mesonero, motorizar. Prefijación: reformar, imposible, inmaduro, multicolor.", r_lista("Clasifica", 8)),
        ("Analice las siguientes formas verbales:\nOí:\nDesgarrara:\nEra:",
         "Oí: 1.ª persona del singular del pretérito perfecto simple de indicativo del verbo oír. Desgarrara: 1.ª o 3.ª persona del singular del "
         "pretérito imperfecto de subjuntivo del verbo desgarrar (en el texto, 3.ª persona). Era: 1.ª o 3.ª persona del singular del pretérito "
         "imperfecto de indicativo del verbo ser (en el texto, 3.ª persona).", r_formas(3)),
        ("Incluya los siguientes adjetivos en la casilla correspondiente:\nalegre, verde, amplísimo, mayor, fuerte, mínimo, dócil, paupérrimo, peor.\n"
         "POSITIVOS / COMPARATIVOS / SUPERLATIVOS",
         "Positivos: alegre, verde, fuerte, dócil. Comparativos: mayor, peor. Superlativos: amplísimo, mínimo, paupérrimo.", r_lista("Clasifica", 9)),
        ("Cite al menos cinco poetas españoles que publicaran alguno de sus libros en el Siglo XX.",
         "Por ejemplo: Antonio Machado, Juan Ramón Jiménez, Federico García Lorca, Rafael Alberti, Miguel Hernández, Blas de Otero, José Hierro, "
         "Gloria Fuertes, Ángel González o Jaime Gil de Biedma.", r_lista("Cita", 5)),
        ("Ordene del más antiguo al más moderno los siguientes autores:\nMiguel de Cervantes, Luis Alberto de Cuenca, Rosalía de Castro, Ramón del "
         "Valle-Inclán, Gabriela Mistral, Gaspar Melchor de Jovellanos.",
         "1. Miguel de Cervantes (1547-1616); 2. Gaspar Melchor de Jovellanos (1744-1811); 3. Rosalía de Castro (1837-1885); 4. Ramón del Valle-Inclán "
         "(1866-1936); 5. Gabriela Mistral (1889-1957); 6. Luis Alberto de Cuenca (1950).", r_lista("Ordena", 6)),
        ("Analice sintácticamente la siguiente oración:\nEl deportista llegó muy cansado a su casa.",
         "Oración simple, enunciativa afirmativa, predicativa e intransitiva. Sujeto: «El deportista» (SN). Predicado verbal: N «llegó»; complemento "
         "predicativo del sujeto «muy cansado» (SAdj: Mod «muy» + N «cansado», concuerda con «deportista»); CCL «a su casa» (SPrep: E «a» + término "
         "SN «su casa»; algunos análisis lo consideran complemento de régimen o argumental de dirección).", r_sintaxis()),
    ],
    "MAT": [
        ("En una fiesta de cumpleaños debemos hinchar 60 globos. Juan, que ha sido el primero en llegar, ha hinchado 1/12 de los globos. A continuación, "
         "María ha hinchado 2/11 de los globos que quedaban y, por último, Ana ha hinchado 3/15 de los globos que restaban. ¿Cuántos globos han quedado "
         "sin hinchar?", r_calculo("Calcula correctamente las fracciones sucesivas sobre lo que queda.")),
        ("En un laboratorio se está experimentando con tres baterías diferentes. Estas baterías son intercambiables y se quiere investigar cuánto tiempo "
         "podrá funcionar un motor conectado a las mismas. En las pruebas independientes cada una de las baterías ha dado la siguiente duración:\n"
         "A. 3h 10’   B. 210’ 600’’   C. 190’ 2400’’\n¿Cuántos minutos funcionará el motor si las tres baterías se conectan al mismo de forma sucesiva?",
         r_calculo("Convierte y suma correctamente las tres duraciones.")),
        ("Calcule el valor de a y b para que se cumplan estas igualdades:\n23 a = 9591\n24024 : b = 88", r_calculo("Calcula correctamente a y b.")),
        ("Ordene de mayor a menor los siguientes números:\n2,1; 23/24; 8/4; 0,8", r_calculo("Ordena correctamente los cuatro números.")),
        ("Queremos hacer bizcocho de zanahoria para cinco personas y encontramos esta receta para cuatro personas. ¿Cuáles son las cantidades que "
         "deberemos utilizar para preparar ese bizcocho para cinco personas siguiendo las proporciones de la receta?\nBizcocho de zanahoria para cuatro "
         "personas:\n• 250 g de zanahorias crudas.\n• 200 g de harina.\n• 7 g de levadura en polvo o polvo de hornear.\n• 120 ml de aceite de girasol.\n"
         "• 4 huevos.\n• 200 g de azúcar.", r_calculo("Calcula correctamente las seis cantidades manteniendo la proporción.")),
        ("Tenemos en una caja 10 bolas numeradas del 0 al 9. Si sacamos una bola de la caja ¿qué posibilidades tendremos de que se cumplan los siguientes "
         "sucesos?\nRelacione con flechas suceso y probabilidad.\nSacar un número impar · Sacar un número mayor que 6 · Sacar el número 8 · Sacar un número "
         "menor que 10\n3/10 · 10/10 · 5/10 · 1/10", r_lista("Relaciona", 4)),
        ("Halle el volumen de las siguientes figuras geométricas.\na) Una pirámide, cuya base es un cuadrado con cuatro metros de lado y cuya distancia al "
         "vértice superior (altura) son 8 metros.\nb) Un cilindro cuya base es un círculo con 2 metros de radio y cuya altura es de 8 metros.\n"
         "Entiéndase π=3,14.", r_calculo("Calcula correctamente los dos volúmenes.")),
        ("Tras valorarse, del uno al diez, cinco propuestas de actividades complementarias que se han llevado a cabo en un colegio, se obtienen los "
         "siguientes resultados.\nResultados: Propuesta 1: 4; Propuesta 2: 5; Propuesta 3: 7; Propuesta 4: 8; Propuesta 5: 9.\n"
         "Halle la media aritmética, la mediana y el rango de los resultados.", r_lista("Calcula", 3)),
        ("Convierta estos números romanos en números arábigos:\nMMCCCXLV   CCCXLVII   CDXCIII", r_lista("Convierte", 3)),
        ("Resuelva la siguiente operación combinada:\n[(12 x 4 - 8) : 4] + [2 (23 - 2 x 3)] =", r_calculo("Resuelve correctamente la operación respetando la jerarquía.")),
    ],
})

# ----------------------------------------------------------------------- 2022 O
texto2022 = "\n".join(l for l in fragmento("2022_comun_ordinaria.txt", "Mendo.— ¿Te haces cargo", "has de aceptarlo, Marqués."))
EXAMENES.append({
    "archivo": "2022_ordinaria", "id": "OF.2022.O", "anio": 2022, "convocatoria": "ordinaria", "clave": (2022, "Ordinaria"),
    "fuente": "https://www.comunidad.madrid/docs/assets/2022/06/18/rh02_2122_prueba_comun.pdf",
    "textoBase": {"texto": texto2022, "autor": "Pedro Muñoz Seca", "obra": "La venganza de Don Mendo", "protegido": False, "anioMuerteAutor": 1936},
    "LEN": [
        ("Resuma el contenido del texto.",
         "Don Mendo, arruinado y sin poder pagar sus deudas al Barón, anuncia a Magdalena que piensa huir a otras tierras y llevarla consigo, y amenaza "
         "con matarlos a ambos con un puñal si ella se niega. Magdalena, que oculta primero su alegría y luego su miedo, le propone que pague con dinero "
         "prestado y parta a la cruzada con la hueste del Melgar mientras ella lo espera. Como Mendo no sabe cómo pagar, ella le entrega un collar para "
         "que salde sus deudas. Tema: el conflicto entre el honor y el dinero, tratado en clave de parodia del drama romántico.", r_resumen()),
        ("¿De qué tipo de texto se trata? Enumere al menos tres características de este tipo de textos.",
         "Es un texto teatral (género dramático), en verso: un fragmento de La venganza de Don Mendo (1918), astracanada que parodia el drama histórico "
         "romántico. Características: diálogo entre personajes, con el nombre de cada uno ante su intervención; acotaciones entre paréntesis que indican "
         "gestos y acciones («Se seca una lágrima de cada ojo»); ausencia de narrador; escrito para ser representado; versificación (versos de distintas medidas, sobre todo "
         "octosílabos, con rima consonante); y, en este caso, humor por exageración, rimas forzadas y lenguaje arcaizante.",
         rub("Identifica el texto teatral y explica al menos tres características.", "Identifica el tipo de texto pero explica solo una o dos características.",
             "No identifica el tipo de texto ni sus características.")),
        ("Explique el significado de las siguientes palabras, atendiendo a su sentido en el texto.\ngrey\nmedrar\nhueste\norfebrería",
         "Grey: conjunto de personas con un carácter común; aquí, el linaje o la familia de don Mendo (en sentido propio, rebaño). Medrar: prosperar, "
         "mejorar de posición o fortuna. Hueste: ejército en campaña, tropa. Orfebrería: arte de labrar objetos de oro, plata u otros metales preciosos; "
         "aquí, un estuche labrado de ese modo.", rub("Explica correctamente las 4 palabras según su sentido en el texto.", "Explica bien 2 o 3 palabras.",
                                                      "Explica bien una palabra o ninguna.")),
        ("Analice las siguientes formas verbales que aparecen en el texto:\nsonrío\nperdiste\nhundiré",
         "Sonrío: 1.ª persona del singular del presente de indicativo del verbo sonreír (irregular). Perdiste: 2.ª persona del singular del pretérito "
         "perfecto simple de indicativo del verbo perder. Hundiré: 1.ª persona del singular del futuro simple de indicativo del verbo hundir.", r_formas(3)),
        ("En el texto aparece la palabra polisémica “sancionar”. Explique dos de sus acepciones.\nAcepción en el texto / Otra acepción",
         "Acepción en el texto: autorizar, aprobar o dar validez a algo (el Conde aprobaría su unión). Otra acepción: aplicar una sanción o un castigo "
         "(«sancionar a un conductor»).", rub("Explica correctamente las dos acepciones.", "Explica bien una de las dos.", "No explica correctamente ninguna.")),
        ("Explique el sentido de la siguiente oración en el texto:\n“¡Quien diga que yo un borrón\neché a mi grey que alce el dedo!”",
         "Don Mendo afirma que no ha deshonrado a su linaje: desafía a cualquiera que sostenga que él ha manchado el honor de su familia («echar un borrón "
         "a la grey») a que lo diga levantando la mano. El hipérbaton y el tono grandilocuente parodian el sentido del honor del drama romántico.",
         r_explica("Explica que Mendo defiende su honra y desafía a quien lo acuse de deshonrar a su linaje.")),
        ("Analice la métrica de los siguientes versos del texto:\n“¿Cómo? Si ya tuya\nsoy y lo mío tuyo es...\neste collar que te doy\nhas de aceptarlo, Marqués”.\n"
         "ANULADA\nAdvertido error en el enunciado de la pregunta se procede a anularla, no siendo tenida en cuenta a efectos de puntuación.",
         "Pregunta anulada por el tribunal (el enunciado no reproduce bien los versos del texto: en él son «¿Cómo? / Si ya tuya soy / y lo mío tuyo es...»). "
         "No puntúa.", rub("Pregunta anulada: no puntúa.", "Pregunta anulada: no puntúa.", "Pregunta anulada: no puntúa."), {"anulada": True, "puntos": 0}),
        ("Defina los siguientes términos: metáfora, palabras homónimas, verso libre, comparación.",
         "Metáfora: figura que identifica un término real con otro imaginario por su semejanza, sin nexo comparativo. Palabras homónimas: palabras que "
         "coinciden en la forma (pronunciación y, en su caso, escritura) pero tienen significados y orígenes distintos («vino» de venir / «vino», bebida); "
         "pueden ser homógrafas u homófonas. Verso libre: verso que no se ajusta a una medida ni a una rima fijas. Comparación o símil: figura que "
         "relaciona dos términos por su semejanza mediante un nexo comparativo (como, cual, igual que).",
         rub("Define correctamente los 4 términos.", "Define bien 2 o 3 términos o con alguna imprecisión.", "Define bien un término o ninguno.")),
        ("Escoja en cada apartado la opción correcta. Razone su respuesta.\na.1) Ojalá se dé cuenta.   a.2) Ojalá se de cuenta.\n"
         "b.1) ¿Confías en mí?   b.2) ¿Confías en mi?\nc.1) Mi bebida favorita es el te verde.   c.2) Mi bebida favorita es el té verde.\n"
         "d.1) Se paciente y espera tu turno.   d.2) Sé paciente y espera tu turno.",
         "a.1: «dé» es forma del verbo dar (presente de subjuntivo) y lleva tilde diacrítica frente a la preposición «de». b.1: «mí» es pronombre "
         "personal tónico tras preposición; «mi» sin tilde es determinante posesivo. c.2: «té» es el sustantivo (la bebida); «te» es pronombre. "
         "d.2: «sé» es el imperativo de ser; «se» es pronombre.", r_lista("Elige y razona", 4)),
        ("Analice sintácticamente la siguiente oración:\nMaría tiene clase de teatro mañana en el centro cultural.",
         "Oración simple, enunciativa afirmativa, predicativa, transitiva y activa. Sujeto: «María» (SN). Predicado verbal: N «tiene»; CD «clase de teatro» "
         "(SN: N «clase» + CN «de teatro», SPrep); CCT «mañana» (SAdv); CCL «en el centro cultural» (SPrep: E «en» + término SN «el centro cultural», "
         "con Det «el», N «centro» y Adj «cultural»).", r_sintaxis()),
    ],
    "MAT": [
        ("María quiere hacer varios collares. Tiene 24 abalorios blancos, 12 rojos y 18 azules. Si quiere poner la misma cantidad de abalorios de cada "
         "color en cada collar, ¿de qué forma pondrá más abalorios en cada uno?", r_calculo("Aplica el m.c.d. y da el reparto correcto.")),
        ("Ainara, Lucas y Berta están leyendo la misma revista. Ainara ha leído la mitad, Lucas las tres cuartas partes, y Berta lleva leídas dos quintas "
         "partes. Calcule quién de los tres ha leído más páginas.", r_calculo("Compara correctamente las tres fracciones y responde.")),
        ("Resuelva las siguientes operaciones:\na) 71,46 – 14,7 × 5,32 + 13,051 =\nb) 2,45 + 146,9 : 5 =", r_lista("Resuelve", 2)),
        ("Exprese las siguientes medidas en la unidad que se indica:\na) 3 km 4 hm 3 dam = ___ m\nb) 2 kg 24 hg 16 dag = ___ hg\nc) 8 dal 9 cl 15 ml = ___ l",
         r_lista("Expresa", 3)),
        ("Calcule cuánto costaría pintar la fachada del siguiente edificio, teniendo en cuenta que el precio por pintar un metro cuadrado es de 3,5 €.\n"
         "[Figura: fachada formada por un rectángulo de 12 m de base y 8,5 m de altura; encima, un rectángulo de 4 m de ancho y 3 m de alto rematado por "
         "un triángulo de 4 m de base y 2,5 m de altura.]", r_calculo("Calcula correctamente el área de la fachada y su coste.")),
        ("En una librería tienen a la venta 1250 libros. El 22% son novelas, el 20% son libros de poesía, el 10% son libros de historia, el 22% son libros "
         "de ciencias y el 26% son enciclopedias. Calcule cuántos libros de cada tipo hay en la librería.", r_lista("Calcula", 5)),
        ("Una estación meteorológica registra la temperatura ambiente todos los días a la misma hora. Observe los datos y calcule la temperatura media y "
         "la moda, mediana y rango de las temperaturas registradas en abril.\nTEMPERATURAS REGISTRADAS EN ABRIL (temperatura en °C: frecuencia): 16: 3; "
         "17: 3; 18: 5; 19: 6; 20,5: 4; 21: 4; 22: 3; 23,5: 2.", r_lista("Calcula", 4)),
        ("Complete las siguientes igualdades:\na) 7 × 10³ = ___   c) 29 × 10^___ = 290.000   e) ___ × 10⁶ = 53.000.000\n"
         "b) 34 × 10⁷ = ___   d) 3 × 10^___ = 3.000.000   f) ___ × 10⁵ = 57.200.000", r_lista("Completa", 6)),
        ("Un viaje en tranvía cuesta 0,85 € y un abono de 10 viajes 6,80 €.\na) ¿Cuánto cuesta cada viaje comprando un abono?\n"
         "b) ¿Cuánto nos ahorramos comprando abonos?", r_lista("Responde", 2)),
        ("Ana ha estado jugando a las construcciones. Calcule el volumen total de la figura que ha creado, expresado en cm³.\n[Figura: tres ortoedros "
         "apilados. Superior: c = 0,1 dm, b = 2 cm, a = 80 mm. Central: d = 0,3 dm, e = 2,5 cm, f = 0,09 m. Inferior: g = 0,0012 hm, i = 11 cm, h = 30 mm.]",
         r_calculo("Convierte las medidas y calcula correctamente el volumen total.")),
    ],
})

# ----------------------------------------------------------------------- 2024 O
texto2024 = "\n".join(fragmento("2024_comun_ordinaria.txt", "Desmayarse, atreverse", "esto es amor, quien lo probó lo sabe."))
tildes = fragmento("2024_comun_ordinaria.txt", "¿Como se hace para que", "esos sueños que parecen tan esquivos?")
lin8 = fragmento("2024_comun_ordinaria.txt", "Acción y efecto de redimir", "laterales que se tapan con los dedos o con llaves.")
EXAMENES.append({
    "archivo": "2024_ordinaria", "id": "OF.2024.O", "anio": 2024, "convocatoria": "ordinaria", "clave": (2024, "Ordinaria"),
    "fuente": "https://www.comunidad.madrid/docs/assets/2024/06/22/rh02_2324_prueba_comun.pdf",
    "textoBase": {"texto": texto2024, "autor": "Lope de Vega", "obra": "Rimas (soneto «Desmayarse, atreverse, estar furioso…»)", "protegido": False,
                  "anioMuerteAutor": 1635},
    "LEN": [
        ("Resuma el tema y el contenido del poema.",
         "Tema: el amor como experiencia contradictoria, que solo comprende quien la ha vivido. Contenido: en los cuartetos y el primer terceto, una larga "
         "enumeración de infinitivos y adjetivos opuestos (desmayarse / atreverse, tierno / áspero, alegre / triste…) describe los estados cambiantes del "
         "enamorado; el último terceto culmina con paradojas («creer que un cielo en un infierno cabe») y el verso final define todo lo anterior: «esto es "
         "amor, quien lo probó lo sabe». Es un soneto (endecasílabos, ABBA ABBA CDC DCD).", r_resumen()),
        ("Cite al autor del poema, ofreciendo información sobre su figura y su contexto histórico.",
         "Lope de Vega (Madrid, 1562-1635), el «Fénix de los ingenios», figura central del Barroco español. Creó la comedia nueva (Arte nuevo de hacer "
         "comedias, 1609; Fuenteovejuna, El caballero de Olmedo), fue un gran poeta lírico (Rimas, Rimas sacras) y escribió novela (La Dorotea). Su vida "
         "fue agitada (amores, destierro, la Armada Invencible) y se ordenó sacerdote en 1614. Contexto: Siglo de Oro, reinados de Felipe III y Felipe IV; "
         "crisis económica y decadencia política de España, Contrarreforma y desengaño barroco.",
         rub("Identifica a Lope de Vega y lo sitúa con datos precisos en su figura y en el Barroco.", "Identifica al autor con datos incompletos o imprecisos.",
             "No identifica al autor o se equivoca.")),
        ("¿Cuáles son las dos corrientes más importantes de la literatura barroca? Cite a los dos autores más representativos de estos movimientos.",
         "El culteranismo (o gongorismo), que cuida la forma (cultismos, hipérbaton, metáforas complejas), cuyo máximo representante es Luis de Góngora; y "
         "el conceptismo, que juega con las ideas y los significados (agudeza, dilogía, antítesis), representado por Francisco de Quevedo (también "
         "Baltasar Gracián).", rub("Cita las dos corrientes y sus dos autores.", "Cita las dos corrientes sin autores, o una corriente con su autor.",
                                   "No identifica las corrientes.")),
        ("Defina las siguientes palabras:\nEsquivo\nAlentado\nParadoja\nAltivo\nÁspero\nDesengaño",
         "Esquivo: que rehúye el trato o la atención; desdeñoso, arisco. Alentado: animoso, valiente. Paradoja: figura que une ideas en apariencia "
         "contradictorias que encierran una verdad («creer que un cielo en un infierno cabe»); también, idea o hecho contrario a la lógica. Altivo: orgulloso, "
         "soberbio. Áspero: desapacible y rudo en el trato (en sentido propio, de superficie rugosa). Desengaño: conocimiento de la verdad con que se sale "
         "del engaño o del error; decepción.", rub("Define correctamente las 6 palabras.", "Define bien 4 o 5 palabras.", "Define bien 3 palabras o menos.")),
        ("Analice los siguientes verbos:\nEs\nHabréis cantado\nEstuvieras\nHayan visto\nCantaría\nHubiéramos hablado",
         "Es: 3.ª persona del singular del presente de indicativo de ser. Habréis cantado: 2.ª persona del plural del futuro compuesto (perfecto) de "
         "indicativo de cantar. Estuvieras: 2.ª persona del singular del pretérito imperfecto de subjuntivo de estar. Hayan visto: 3.ª persona del plural "
         "del pretérito perfecto compuesto de subjuntivo de ver. Cantaría: 1.ª o 3.ª persona del singular del condicional simple de cantar. Hubiéramos "
         "hablado: 1.ª persona del plural del pretérito pluscuamperfecto de subjuntivo de hablar.", r_formas(6)),
        ("Escriba un sinónimo y un antónimo para cada una de estas palabras.\nAmor, Centro, Veneno, Desengaño, Sabiduría, Fortaleza, Inefable, Perenne, "
         "Opíparo, Ubérrimo, Taciturno",
         "Amor: cariño / odio. Centro: medio / periferia (borde). Veneno: ponzoña, tóxico / antídoto. Desengaño: decepción / ilusión. Sabiduría: "
         "conocimiento, sapiencia / ignorancia. Fortaleza: fuerza, vigor / debilidad. Inefable: indecible, inexpresable / expresable. Perenne: perpetuo, "
         "permanente / efímero, caduco. Opíparo: copioso, abundante / frugal, escaso. Ubérrimo: muy fértil, abundantísimo / estéril, yermo. Taciturno: "
         "callado, silencioso / hablador, locuaz.", rub("Escribe correctamente los 22 sinónimos y antónimos.", "Comete uno o dos errores.",
                                                         "Comete más de dos errores o no completa la actividad.")),
        ("Escriba adecuadamente las tildes que falten en este texto.\n" + " ".join(tildes),
         "Llevan tilde (19 palabras): ¿Cómo… (inicio), más (por más que), día tras día (2), ¿Qué piensas…?, obstáculos, está (la clave está), algo más, "
         "algún, esté (nos esté eludiendo), ¿será…?, aún (todavía), método, búsqueda, éxito, ¿cuántas…?, ¿Y qué…?, ¿Cómo encontramos…?, una vez más. "
         "Motivos: interrogativos con tilde diacrítica (cómo, qué, cuántas); «más» adverbio; «aún» equivale a «todavía»; agudas en vocal (está, esté, será) "
         "o en -n (algún); esdrújulas (obstáculos, método, éxito, búsqueda); «día», hiato con vocal cerrada tónica.",
         rub("Coloca todas las tildes que faltan sin añadir ninguna incorrecta.", "Comete uno o dos errores (omisión o tilde de más).",
             "Comete más de dos errores.")),
        ("Escriba la palabra correcta para la definición propuesta, atendiendo a las indicaciones dadas sobre la primera y última letra de cada término.\n"
         + "\n".join(lin8),
         "Redención (R*******N); elástico (E******O); arquitectura (A*********A); química (Q*****A); "
         "metal (M****L); teólogo (T*****O); paradójico (P********O); apogeo (A****O); silogismo "
         "(S*******O); oboe (O**E).", rub("Escribe correctamente las 10 palabras.", "Comete uno o dos errores.", "Comete más de dos errores.")),
        ("Escriba tres palabras derivadas para cada uno de los términos propuestos.\nÁrbol, Agua, Pan, Moneda",
         "Árbol: arboleda, arbolado, arbolito. Agua: aguacero, aguado, aguador (aguar). Pan: panadero, panadería, panecillo (empanada). Moneda: monedero, "
         "monedita, amonedar.", rub("Escribe correctamente las 12 derivadas.", "Comete uno o dos errores.", "Comete más de dos errores.")),
        ("Analice sintácticamente la siguiente oración:\nMaría contó el cuento a sus compañeras.",
         "Oración simple, enunciativa afirmativa, predicativa, transitiva y activa. Sujeto: «María» (SN). Predicado verbal: N «contó»; CD «el cuento» "
         "(SN); CI «a sus compañeras» (SPrep: E «a» + término SN «sus compañeras»).", r_sintaxis()),
    ],
    "MAT": [
        ("Ordene las siguientes cantidades de menor a mayor:\n2/3 de 29,1   1,904 · 10   2² + 4² – 0,56   58,26/3", r_calculo("Ordena correctamente las cuatro cantidades.")),
        ("Resuelva la siguiente operación combinada, simplificando las fracciones siempre que sea posible:\n[3/5 + 1/4 × 2/3] : [(1 + 1/5) × 16/4] =",
         r_calculo("Resuelve correctamente la operación y simplifica el resultado.")),
        ("Descomponga de forma polinómica las siguientes cantidades:\na) 90.670.304 =\nb) 40.500 =\nc) 809.705 =", r_lista("Descompone", 3)),
        ("Un incunable tiene entre 300 y 350 páginas. Si las contamos de 3 en 3, no sobra ninguna. Si las contamos de 4 en 4, tampoco sobra ninguna. Y, si "
         "las contamos de 7 en 7, tampoco sobra ninguna. ¿Cuántas páginas tiene el incunable?", r_calculo("Aplica el m.c.m. y da el número correcto.")),
        ("Alonso tarda 15 días en pintar la fachada de un edificio. Alberto tarda 30 días en pintar la misma fachada. Si la pintasen juntos, ¿cuántos días "
         "tardarían en terminar el trabajo?", r_calculo("Suma las fracciones de trabajo diario y responde correctamente.")),
        ("Héctor ha hecho la compra, y ha metido los productos en tres bolsas. Una pesa 2 kg y 6 hg; otra pesa 1 kg y 8 dag, y la tercera pesa 1 kg y 70 dg. "
         "Va a cargarlas en un carrito que soporta un peso total de 4,5 kg. Responda razonadamente ¿podrá el carrito soportar el peso de las tres bolsas?",
         r_calculo("Convierte, suma y razona correctamente la respuesta.")),
        ("Verónica tiene el recipiente A lleno de agua, y quiere trasvasarla al recipiente B.\nResponda razonadamente:\na) ¿Cuántos litros de agua tiene en "
         "el recipiente A?\nb) ¿Le faltará, le sobrará, o tendrá el agua justa para llenar el recipiente B?\nTéngase en cuenta que las bases de los "
         "recipientes son regulares.\n[Figura: recipiente A, prisma de base cuadrada de 130 mm de lado y 22 cm de altura; recipiente B, prisma de base "
         "pentagonal de 12,5 cm de lado, 85,7 mm de apotema y 120 mm de altura.]", r_lista("Responde", 2)),
        ("Localice los siguientes puntos en el eje de coordenadas, e indique en qué cuadrante se sitúa cada uno:\nA = (- 4, +2)\nB = (-1, - 4)\n"
         "C= (+3, +5)\nD = (+2, -3)", r_lista("Sitúa", 4)),
        ("Experiencias aleatorias y sucesos:\na) Defina “experiencia aleatoria” y ponga un ejemplo.\nb) Defina “suceso” y explique los tipos que existen, "
         "con un ejemplo de cada uno.",
         rub("Define con precisión experiencia aleatoria y suceso, y explica los tipos de suceso con ejemplos.",
             "Define bien uno de los dos conceptos o explica los tipos de forma incompleta.", "Las definiciones son incorrectas o no responde.")),
        ("Un grupo de alumnos de 5º de Primaria han dedicado el último mes a recaudar fondos para una causa benéfica. Estas son las cantidades de dinero "
         "recogidas cada día:\n21 30 22 21 13 20 24\n30 20 27 17 21 17 20\n20 30 19 24 20 26 17\n30 19 17 23 20 25 24\n19 30\n"
         "Calcule las medidas de tendencia central (o medidas de centralización).", r_lista("Calcula", 3)),
    ],
})
SOL_MAT[("OF.2024.O", 9)] = (
    "a) Experiencia aleatoria: experimento cuyo resultado no se puede predecir aunque se repita en las mismas condiciones, aunque se conocen sus "
    "resultados posibles (lanzar un dado). b) Suceso: cada uno de los resultados posibles o conjunto de resultados de una experiencia aleatoria "
    "(subconjunto del espacio muestral). Tipos: elemental, con un solo resultado (sacar un 3); compuesto, con varios (sacar par); seguro, que siempre "
    "ocurre (sacar menos de 7); imposible, que nunca ocurre (sacar un 8); contrario de A, el que ocurre cuando no ocurre A (par / impar). También se "
    "distinguen sucesos compatibles e incompatibles.")

# ----------------------------------------------------------------------- 2026 O
texto2026o = (TEXTOS / "2026_comun_ordinaria.txt").read_text(encoding="utf-8")
m = re.search(r'"La libertad, Sancho.*?si fueran míos\."', texto2026o, re.S)
texto2026o = re.sub(r"\s*\n\s*", " ", m.group(0))[:-2] + ".”"
EXAMENES.append({
    "archivo": "2026_ordinaria", "id": "OF.2026.O", "anio": 2026, "convocatoria": "ordinaria", "clave": (2026, "Ordinaria"),
    "fuente": "https://sede.comunidad.madrid/medias/examenes20261zip/download",
    "fuentePlantilla": "https://www.comunidad.madrid/docs/2026-08/rh02_plantillas_prueba_comun_ordinaria_26.pdf",
    "textoBase": {"texto": texto2026o, "autor": "Miguel de Cervantes", "obra": "Don Quijote de la Mancha, segunda parte, capítulo LVIII", "protegido": False,
                  "anioMuerteAutor": 1616},
    "LEN": [
        ("Resuma el tema y el contenido del fragmento.",
         "Tema: el elogio de la libertad como el mayor bien del ser humano. Contenido: don Quijote explica a Sancho que la libertad es el don más precioso "
         "que el cielo dio a los hombres, superior a todos los tesoros, y que por ella, como por la honra, se debe arriesgar la vida, mientras que el "
         "cautiverio es el mayor mal. Lo ilustra con su experiencia: pese a la abundancia y los banquetes del castillo que acaban de dejar, se sentía "
         "hambriento porque no los disfrutaba con libertad, al no ser suyos."),
        ("Explique qué tipo de texto es y cite al menos tres características o ideas principales del texto.",
         "Es un texto literario narrativo (fragmento de novela) que reproduce, en estilo directo, un parlamento de don Quijote de carácter argumentativo: "
         "defiende una tesis con argumentos. Características e ideas: tesis inicial (la libertad es el mayor don); comparaciones que la refuerzan (vale "
         "más que los tesoros de la tierra y del mar; se equipara a la honra); antítesis libertad / cautiverio; ejemplo de la propia experiencia (los "
         "banquetes del castillo); vocativo dirigido a Sancho; lengua culta del Siglo de Oro con periodos amplios e hipérbatos."),
        ("Contextualice brevemente el fragmento en su periodo histórico e indique el nombre de la obra y de su autor.",
         "Pertenece a la segunda parte del Quijote (El ingenioso caballero don Quijote de la Mancha, 1615), capítulo 58, de Miguel de Cervantes "
         "(1547-1616). Se sitúa en el Siglo de Oro, entre el Renacimiento y el Barroco, bajo el reinado de Felipe III, época de crisis y desengaño. "
         "Don Quijote y Sancho acaban de dejar el castillo de los duques. Cervantes estuvo cautivo en Argel (1575-1580), lo que da hondura personal a este "
         "elogio de la libertad. El Quijote, parodia de los libros de caballerías, se considera la primera novela moderna."),
        ("Escriba el prefijo de cada una de estas palabras derivadas, especificando a continuación el significado que aporta.\n"
         "Palabra / Prefijo / Significado del prefijo\ndeshacer\ninvisible\nreleer\nsubmarino\nantinatural",
         "Deshacer: des- (inversión o negación de la acción). Invisible: in- (negación, «no»). Releer: re- (repetición, «de nuevo»). Submarino: sub- "
         "(«debajo de»). Antinatural: anti- («contrario a, opuesto a»)."),
        ("Explique qué es un diccionario y cuáles son sus principales utilidades.",
         "Un diccionario es una obra de consulta que recoge, generalmente por orden alfabético, las palabras de una lengua (o de una materia) y explica su "
         "significado (acepciones), su categoría gramatical, y a menudo su etimología, su uso y ejemplos. Utilidades: conocer el significado de las palabras, "
         "comprobar su ortografía, su categoría y su género, resolver dudas de uso y conjugación, buscar sinónimos y antónimos y traducir (diccionarios "
         "bilingües). Hay diccionarios de la lengua (DLE), de sinónimos, de dudas, etimológicos, bilingües, etc."),
        ("Analice morfológicamente las siguientes palabras del fragmento: libertad, hombres, aquellos, gozaba.\nEn cada caso debe indicar: el tipo de "
         "palabra; el género y el número, si se trata de un nombre, adjetivo, determinante o pronombre; y, si es un verbo, la persona, el número, el tiempo, "
         "el modo y el infinitivo. Añada también cualquier otra observación relevante, por ejemplo si el sustantivo es común o abstracto, o si una palabra "
         "puede funcionar como determinante o como pronombre según el contexto.",
         "Libertad: sustantivo común, abstracto, femenino, singular. Hombres: sustantivo común, concreto, masculino, plural (aquí con valor genérico, «los "
         "seres humanos»). Aquellos: determinante demostrativo de lejanía, masculino plural (acompaña a «banquetes»); sin sustantivo funcionaría como "
         "pronombre. Gozaba: verbo gozar, 1.ª persona del singular (la forma coincide con la 3.ª), pretérito imperfecto de indicativo, 1.ª conjugación, "
         "aspecto imperfectivo, voz activa."),
        ("Seleccione la opción correcta de las dos facilitadas y razone su elección.\nOración con opciones / Opción correcta / Explicación\n"
         "Ayer (anduve / andé) mucho por el campo.\nNo (había / habían habido) suficientes sillas.\nEl capitán dijo que quizá (vendría / vendrá) mañana.\n"
         "Había (demasiado / demasiados) ruido en la plaza.\nMis primos y yo (fuimos / fuemos) al museo.\nOjalá (haya / haiga) tiempo para terminar.\n"
         "Ese libro es (de él / suyo).",
         "Anduve: pretérito perfecto simple irregular de andar («andé» es incorrecto). Había: «haber» impersonal (existencial) solo se usa en 3.ª persona del "
         "singular; «habían habido» es incorrecto. Vendría: en estilo indirecto con verbo de lengua en pasado («dijo»), el futuro del enunciado original pasa "
         "a condicional (concordancia de tiempos); «vendrá» se admite si el hecho sigue siendo futuro respecto al momento en que se habla. Demasiado: "
         "concuerda en masculino singular con «ruido». Fuimos: pretérito perfecto simple de ir («fuemos» es un vulgarismo). Haya: presente de subjuntivo "
         "de haber («haiga» es un vulgarismo). Suyo: el posesivo es la opción esperada en registro culto."),
        ("Defina los siguientes términos.\nTérmino / Definición\nNarrador\nNovela\nHipérbole\nAdjetivo",
         "Narrador: voz que cuenta los hechos en un texto narrativo; puede ser interno (en 1.ª persona, protagonista o testigo) o externo (en 3.ª persona, "
         "omnisciente u observador). Novela: obra literaria narrativa extensa, en prosa y de ficción, con una trama compleja, personajes, tiempo y espacio "
         "desarrollados. Hipérbole: figura retórica que exagera intencionadamente la realidad. Adjetivo: clase de palabra variable que acompaña al "
         "sustantivo o se predica de él para expresar cualidades o propiedades, y concuerda con él en género y número."),
        ("Una el término con la definición que le corresponda.\nPor ejemplo: 8 G, ya que la definición que corresponde al término \"sustantivo\" es la G.\n"
         "A. Palabra que expresa una cualidad o característica del sustantivo.\nB. Persona, animal o cosa que realiza la acción del verbo en una oración.\n"
         "C. Parte variable de la oración que puede expresar tiempo, modo, número y persona.\nD. Palabra que sustituye al nombre para evitar su repetición.\n"
         "E. Recurso literario que exagera de forma intencionada la realidad.\nF. Persona que cuenta lo que ocurre en una narración.\n"
         "G. Palabra que nombra seres, objetos, lugares, ideas o sentimientos.\nH. Conjunto formado por sujeto y predicado.\n"
         "Términos: 1. Adjetivo · 2. Sujeto · 3. Verbo · 4. Hipérbole · 5. Narrador · 6. Oración · 7. Pronombre · 8. Sustantivo (G)",
         "1 A (adjetivo); 2 B (sujeto); 3 C (verbo); 4 E (hipérbole); 5 F (narrador); 6 H (oración); 7 D (pronombre); 8 G (sustantivo, dado como ejemplo)."),
        ("Analice sintácticamente la siguiente oración: Los viajeros encontraron refugio en la venta.",
         "Oración simple, enunciativa afirmativa, predicativa, transitiva y activa. Sujeto: «Los viajeros» (SN: Det «Los» + N «viajeros»). Predicado verbal: "
         "N «encontraron»; CD «refugio» (SN); CCL «en la venta» (SPrep: E «en» + término SN «la venta»)."),
    ],
    "MAT": [
        "Responda razonadamente: ¿Es 1,25 un número decimal exacto? Expréselo además en forma de fracción irreducible.",
        "Exprese mediante una potencia cada una de las siguientes afirmaciones:\na. Un teatro tiene cuatro filas con cuatro asientos en cada una.\n"
        "b. En una exposición hay tres vitrinas; en cada vitrina hay tres baldas y en cada balda tres maquetas.\nc. Una pastelería vende seis cajas con "
        "seis galletas en cada una.",
        "En una biblioteca escolar, 1/4 de los libros son de aventuras, 1/5 son de ciencia, 1/10 son de poesía y el resto son de historia. Calcule la "
        "fracción de libros de historia.",
        "Complete la siguiente tabla según el ejemplo.\nEn cada fila, convierta a metros las cantidades que aparecen en las distintas columnas y escriba en "
        "la última columna el resultado total.\nRecuerde: cada número vale según la unidad de la columna en la que está escrito. Después hay que pasarlo a "
        "metros y sumar.\nEjemplo: 3 km + 2 hm = 3200 m.\n(Tabla con columnas km | hm | dam | m | dm | cm | Resultado. Filas: 3 km, 2 hm → 3200 m; "
        "5 dam, 4 m; 7 hm, 6 cm; 8 m, 5 dm; 6 km.)",
        "La siguiente tabla representa los tiros libres encestados por un jugador de baloncesto en cinco partidos. Calcule la probabilidad estimada de que, "
        "en su próximo lanzamiento, enceste un tiro libre. No es necesario hallar el porcentaje, puede responder con una fracción.\n(Partidos 1.º a 5.º. "
        "Tiros libres lanzados: 12, 10, 8, 14, 16. Tiros libres encestados: 9, 7, 5, 10, 12.)",
        "Una asociación vende 240 entradas para una actividad solidaria. El 35 % de lo recaudado se destina a material escolar. Si se han obtenido 1.920 "
        "euros, calcule cuánto dinero se dedica a material escolar.",
        "En esta zona ajardinada se plantarán margaritas en la parte sombreada y césped en el resto. Calcule el área exacta de la superficie destinada al "
        "césped. Tómese π = 3,14.\n[Figura: zona en forma de L de 10 m de ancho total; parte izquierda de 8 m de alto; a la derecha, un rectángulo de 4 m "
        "de ancho y 3 m de alto; dentro de la parte izquierda, un círculo sombreado de r = 2 m.]",
        "Escriba SÍ/NO en las celdas correspondientes según los divisores de cada número.\n(Divisible entre 2 | 3 | 5 | 9 | 10. Números: 246, 315, 540, "
        "913, 720.)",
        "En una encuesta sobre actividades extraescolares, complete la tabla de frecuencias.\n(Actividad | Frecuencia absoluta | Frecuencia relativa: "
        "Ajedrez 5 | 0,25; Teatro 4 | __; Baloncesto __ | 0,30; Música 5 | __; Total 20 | 1.)",
        "Calcule cuánto miden en la realidad las siguientes medidas tomadas en un plano con la escala que se indica. Realice las conversiones necesarias y "
        "escriba siempre el resultado final en metros.\n(Medida en el plano | Escala utilizada: 2,5 cm | 1:200; 8 cm | 1:50; 4,2 cm | 1:1.000; 35 mm | 1:20.)",
    ],
})

# ----------------------------------------------------------------------- 2026 A
texto2026a = "\n".join(fragmento("2026_comun_aplazada.txt", "Córdoba.", "antes de llegar a Córdoba!") + ["Córdoba.", "Lejana y sola."])
EXAMENES.append({
    "archivo": "2026_aplazada", "id": "OF.2026.A", "anio": 2026, "convocatoria": "aplazada", "clave": (2026, "Aplazada"),
    "fuente": "https://www.comunidad.madrid/docs/2026-06/rh02_opo_prueba_comun_aplazada.pdf",
    "fuentePlantilla": "https://www.comunidad.madrid/docs/2026-08/rh02_plantillas-prueba_comun_aplazada_26.pdf",
    "textoBase": {"texto": texto2026a, "autor": "Federico García Lorca", "obra": "Canciones («Canción de jinete»)", "protegido": False, "anioMuerteAutor": 1936},
    "LEN": [
        ("Explique el tema del poema y resuma su contenido principal. Procure relacionar el paisaje, el viaje y la sensación de destino que transmite el texto.",
         "Tema: el presentimiento de la muerte; el destino trágico que impide al jinete alcanzar su meta. Contenido: un jinete cabalga hacia Córdoba con su "
         "jaca negra y aceitunas en la alforja; aunque conoce el camino, sabe que nunca llegará, porque la muerte lo espera y lo mira desde las torres de la "
         "ciudad. El paisaje (el llano, el viento, la luna que pasa de «grande» a «roja») acompaña el viaje y anuncia la tragedia; los «¡Ay!» finales "
         "expresan su angustia, y la repetición de «Córdoba. / Lejana y sola.» cierra el poema de forma circular, como una meta inalcanzable."),
        ("Cite al autor y explique brevemente quién fue, qué fue la Generación del 27 y dos rasgos característicos de su poesía.",
         "Federico García Lorca (Fuente Vaqueros, Granada, 1898 – Víznar, 1936), poeta y dramaturgo, asesinado al comienzo de la Guerra Civil; autor de "
         "Canciones (de donde procede el poema), Romancero gitano, Poeta en Nueva York, Bodas de sangre y La casa de Bernarda Alba. La Generación del 27 "
         "fue el grupo de poetas que se dio a conocer en los años veinte y se reunió en 1927 en el homenaje a Góngora en el tercer centenario de su muerte "
         "(Salinas, Guillén, Diego, Aleixandre, Alonso, Alberti, Cernuda…); unió tradición y vanguardia. Rasgos de su poesía: fusión de lo popular andaluz "
         "(canción, romance, copla) con lo culto y vanguardista (metáfora audaz); símbolos de muerte y destino trágico (luna, caballo, sangre, color negro) "
         "y el tema de la frustración."),
        ("Explique por qué el poema transmite una sensación de fatalidad o destino trágico. Justifique su respuesta con, al menos, tres elementos del texto.",
         "Porque el jinete sabe desde el principio que no llegará a su destino: 1) «Aunque sepa los caminos / yo nunca llegaré a Córdoba» (certeza del "
         "fracaso pese a conocer el camino); 2) la personificación «La muerte me está mirando / desde las torres de Córdoba» y «¡Ay que la muerte me "
         "espera, / antes de llegar a Córdoba!»; 3) los símbolos: la jaca negra (luto), la luna que se vuelve roja (sangre, presagio de muerte); "
         "4) Córdoba «lejana y sola», meta inalcanzable, y la estructura circular; 5) los «¡Ay!» de lamento."),
        ("Clasifique las siguientes palabras del poema indicando su clase de palabra y una breve justificación gramatical. Fíjese en el ejemplo.\n"
         "Palabra / Clase de palabra / Justificación gramatical\nCórdoba / Sustantivo propio / Nombra de manera individual una ciudad concreta.\n"
         "negra\naunque\nyo\nnunca\ndesde\nmi\nllegaré",
         "Negra: adjetivo calificativo; acompaña a «jaca», con la que concuerda (femenino singular), y expresa una cualidad. Aunque: conjunción subordinante "
         "concesiva; introduce «aunque sepa los caminos». Yo: pronombre personal tónico de 1.ª persona del singular; es el sujeto de «llegaré». Nunca: "
         "adverbio de negación (y tiempo); invariable, modifica al verbo «llegaré». Desde: preposición; introduce el complemento «las torres de Córdoba» "
         "(origen). Mi: determinante posesivo de 1.ª persona, un poseedor, singular; acompaña a «alforja» y a «jaca». Llegaré: verbo llegar, 1.ª persona del "
         "singular del futuro simple de indicativo."),
        ("Trabaje con el vocabulario del poema.\na) Escriba dos palabras de la misma familia léxica de camino.\nb) Escriba dos palabras del campo "
         "semántico de viaje o desplazamiento.\nc) Proponga un sinónimo contextual de lejana y un antónimo contextual de largo.\nd) Explique la diferencia "
         "entre Córdoba (nombre propio) y camino (nombre común).",
         "a) Caminar, caminante (también caminata, encaminar). b) Cabalgar, trayecto (también ruta, jinete, alforja, viajero). c) Lejana: distante, remota; "
         "largo: corto, breve. d) «Córdoba» es nombre propio: designa un ser único (una ciudad concreta), se escribe con mayúscula y normalmente no lleva "
         "determinante; «camino» es nombre común: designa cualquier elemento de una clase, se escribe con minúscula y admite determinantes."),
        ("Responda a las siguientes cuestiones literarias y métricas:\na) Cite una anáfora o repetición expresiva del poema y explique su efecto.\n"
         "b) Localice una personificación.\nc) Localice un epíteto o una combinación de palabras con fuerte valor descriptivo.\nd) Mida los versos “Por el "
         "llano, por el viento” y “jaca negra, luna roja” e indique si tienen la misma medida.",
         "a) Anáfora de «¡Ay…!» al comienzo de tres versos seguidos (o «por el llano, por el viento»): intensifica el lamento y la angustia y marca el ritmo. "
         "b) «La muerte me está mirando / desde las torres de Córdoba» (también «la muerte me espera»). c) «jaca negra», «luna roja», «luna grande», «jaca "
         "valerosa». d) Por-el-lla-no-por-el-vien-to: 8 sílabas; ja-ca-ne-gra-lu-na-ro-ja: 8 sílabas. Ambos son octosílabos (terminación llana); tienen la "
         "misma medida."),
        ("Seleccione la opción correcta en cada caso y justifique brevemente su elección.\nOpción con hueco / Opción correcta / Explicación\n"
         "¿(Porque / Por qué) aparece la luna con tanta fuerza en el poema?\nEl jinete no llegó (aun / aún) sabiendo el camino.\n"
         "No (tubo / tuvo) tiempo de detenerse.\n¡(Ay / Hay / Ahí) qué camino tan largo!\nQuizá me (de / dé) una respuesta mañana.\n"
         "(Tu / Tú) conoces bien ese lugar.\nEl mensajero dejó el paquete (ahí / hay).\nDebes (prever / preveer) los problemas antes de actuar.",
         "Por qué: interrogativa directa (preposición + interrogativo tónico). Aun: equivale a «incluso» («incluso sabiendo el camino»). Tuvo: verbo tener "
         "(«tubo» es una pieza cilíndrica hueca). Ay: interjección de dolor o lamento. Dé: forma del verbo dar (presente de subjuntivo), con tilde diacrítica "
         "frente a la preposición «de». Tú: pronombre personal, sujeto de «conoces». Ahí: adverbio de lugar («hay» es del verbo haber). Prever: «ver con "
         "anticipación», se conjuga como ver; «preveer» es incorrecto."),
        ("Relacione cada término con su definición, siguiendo el ejemplo.\nA. Repetición de una o varias palabras al comienzo de versos u oraciones.\n"
         "B. Grupo de palabras que pertenecen a un mismo ámbito de significado.\nC. Palabra que sustituye al nombre.\nD. Figura que atribuye cualidades "
         "humanas a animales, cosas o ideas.\nE. Palabra invariable que modifica al verbo, a un adjetivo o a otro adverbio.\nF. Palabra que sirve de enlace "
         "entre palabras u oraciones.\nG. Exageración expresiva de la realidad.\nH. Conjunto de palabras que comparten el mismo lexema o raíz.\nI. Nombre "
         "que designa seres u objetos sin individualizarlos.\nJ. Palabra que relaciona unas palabras con otras dentro de la oración.\nTérminos: 1. Sustantivo "
         "común (I) · 2. Pronombre personal · 3. Adverbio · 4. Preposición · 5. Conjunción · 6. Familia léxica · 7. Campo semántico · 8. Personificación · "
         "9. Anáfora · 10. Hipérbole",
         "1 I (dado como ejemplo); 2 C; 3 E; 4 J; 5 F; 6 H; 7 B; 8 D; 9 A; 10 G."),
        ("Indique si las siguientes palabras son primitivas, derivadas o compuestas. Justifique brevemente su respuesta. Ejemplo: paraguas = compuesta, "
         "porque reúne dos lexemas.\nPalabra / Tipo / Justificación\nlunero\ntorrecilla\nsacapuntas\nmortal\nviento\ngirasol",
         "Lunero: derivada (lexema lun- + sufijo -ero). Torrecilla: derivada (torre + sufijo diminutivo -ecilla). Sacapuntas: compuesta (dos lexemas: saca + "
         "puntas). Mortal: derivada (lexema mort-, el de muerte, + sufijo -al). Viento: primitiva (no procede de otra palabra española; solo lexema y morfema "
         "de género). Girasol: compuesta (gira + sol)."),
        ("Analice sintácticamente la siguiente oración, respondiendo exclusivamente a las preguntas que se realizan.\nLa muerte miraba al jinete desde las "
         "torres de Córdoba.\n• Indique si es una oración simple o compuesta:\n• Señale el sujeto y el predicado:\n• Identifique el núcleo del sujeto y el "
         "núcleo del predicado:\n• Localice el complemento directo y el complemento circunstancial de lugar.",
         "Oración simple (un solo verbo). Sujeto: «La muerte»; predicado: «miraba al jinete desde las torres de Córdoba». Núcleo del sujeto: «muerte»; núcleo "
         "del predicado: «miraba». CD: «al jinete» (CD de persona introducido por «a», contraída con el artículo). CCL: «desde las torres de Córdoba»."),
    ],
    "MAT": [
        "En una biblioteca hay 360 libros pendientes de catalogación. El lunes se ordena 1/6 del total. El martes se ordena 1/5 de los que quedan. El "
        "miércoles se ordena 1/4 de los restantes. ¿Cuántos libros quedan todavía sin catalogar?",
        "Tres aparatos funcionan consecutivamente durante estos tiempos: A) 2 h 45 min 30 s; B) 165 min 900 s; C) 1 h 95 min 120 s. Exprese la duración "
        "total del tiempo de funcionamiento en segundos.",
        "Calcule el valor de a y b para que se cumplan estas igualdades:\n36 × a = 10.404\n28.560 : b = 84.",
        "Ordene de mayor a menor los siguientes números: 5/4; 1,18; 7/6; 1,205.",
        "Para preparar limonada para 6 personas se necesitan 450 ml de zumo de limón, 1,2 l de agua y 180 g de azúcar. ¿Qué cantidades harán falta para 15 "
        "personas si se mantiene la misma proporción?",
        "Tenemos 12 tarjetas numeradas del 1 al 12. Relacione cada suceso con su probabilidad.\n(Suceso | Probabilidad: Sacar un número par | __; Sacar un "
        "número primo | __; Sacar un número mayor que 10 | __; Sacar un número menor que 13 | __.)",
        "Un depósito con forma de prisma rectangular mide 2,5 m de largo, 1,2 m de ancho y 0,8 m de alto. Calcule su volumen en m³ y exprese después esa "
        "capacidad en litros.",
        "Las puntuaciones de un concurso son: 6, 7, 7, 8, 9 y 11. Halle la media aritmética, la mediana, la moda y el rango.",
        "Convierta estos números romanos en números arábigos: MDXLVIII, CMXCIV, MMCDLIII.",
        "Resuelva la siguiente operación combinada: {[(24 : 3) + 5] × 2} − {3 × [7 − (9 − 5)]}.",
    ],
})

# ======================================================================= NOTAS DE LA APP (decisiones de la dirección, 24/11/2026)
# Erratas y ambigüedades de los enunciados oficiales: el enunciado no se toca; la nota explica cómo se resuelve.
NOTAS = {
    ("OF.2017.O", "MAT", 1): "la división 8888 : 40 no es exacta (b = 222,2). Así figura en el cuadernillo oficial; se acepta b = 222,2.",
    ("OF.2024.O", "LEN", 8): "la pista A*********A indica 11 letras, pero ARQUITECTURA tiene 12, y la pista M****L indica 6, pero METAL tiene 5. "
                            "Se aceptan ARQUITECTURA y METAL.",
    ("OF.2024.O", "MAT", 7): "en un pentágono regular de 12,5 cm de lado la apotema mide unos 8,60 cm, no 8,57 cm. Se usa el dato del enunciado; "
                            "con 8,60 cm, B tendría unos 3,225 l y la conclusión (sobra agua) no cambia.",
    ("OF.2022.O", "MAT", 1): "el enunciado pide «más abalorios en cada uno», pero repartir cada color por igual entre los collares lleva al m.c.d. "
                            "(6 collares de 9 abalorios). Se aceptan también, si se justifican, los otros repartos en collares iguales "
                            "(3 collares de 18, 2 de 27) y un solo collar con los 54 abalorios, que es literalmente el que más lleva.",
    ("OF.2026.O", "LEN", 7): "se aceptan las dos opciones en dos casos. «Vendría» es la esperada (estilo indirecto en pasado), pero «vendrá» es "
                            "correcta si el hecho sigue siendo futuro cuando se habla. «Suyo» es la esperada, pero «de él» también es gramatical "
                            "y evita la ambigüedad de «suyo».",
    ("OF.2026.A", "MAT", 6): "la columna de probabilidades del cuadernillo está vacía, así que «Relacione» se interpreta como «escriba la "
                            "probabilidad» de cada suceso.",
    ("OF.2026.O", "LEN", 9): "es la respuesta esperada por el tribunal, pero dos definiciones del enunciado son imprecisas. Según la NGLE, el "
                            "sujeto es una función sintáctica: el elemento que concuerda en número y persona con el verbo, haga o no la acción "
                            "(en «El ladrón fue detenido», el sujeto no detiene). Y el verbo es una clase de palabra, no una «parte de la "
                            "oración»: expresa acciones, procesos o estados, se flexiona en persona, número, tiempo, aspecto y modo, y es el "
                            "núcleo del predicado.",
    ("OF.2026.A", "LEN", 8): "es la respuesta esperada por el tribunal (4 J, 5 F), pero las definiciones J y F se solapan. Según la NGLE, la "
                            "preposición es una palabra invariable que introduce un complemento (su término) y lo subordina a otra palabra; la "
                            "conjunción une palabras, grupos u oraciones (coordinantes) o introduce oraciones subordinadas (subordinantes).",
}
# Cómo aplica la app las rúbricas oficiales que no casan del todo con la pregunta (la rúbrica se copia tal cual).
NOTAS_RUBRICA = {
    ("OF.2026.O", "LEN", 6): "La rúbrica oficial habla de «clases de palabras», pero la pregunta pide el análisis morfológico completo. La app "
                            "aplica: Bien, las 4 palabras con su clase y todos sus rasgos correctos; Regular, un error (en la clase o en un "
                            "rasgo); Mal, más de un error.",
    ("OF.2026.A", "LEN", 5): "La pregunta tiene 4 apartados (a–d). La app aplica: Bien, los 4 correctos; Regular, 2 o 3 correctos; Mal, 0 o 1.",
}

# ======================================================================= SALIDA


def construir(ex):
    anio, conv = ex["clave"]
    letra = "O" if conv == "Ordinaria" else "A"
    preguntas, n_global = [], 0
    for area in ("LEN", "MAT"):
        nombre_area = "Lengua" if area == "LEN" else "Matemáticas"
        for i, entrada in enumerate(ex[area], 1):
            extra = {}
            oficial = anio == 2026
            if area == "MAT":
                enunciado = entrada if oficial else entrada[0]
                solucion = SOL_MAT[(ex["id"], i)]
                rubrica = None if oficial else entrada[1]
            else:
                enunciado, solucion = entrada[0], entrada[1]
                rubrica = None if oficial else entrada[2]
                if len(entrada) > 3:
                    extra = entrada[3]
            if oficial:
                b, r, m = OFICIAL[(letra, area)][i - 1]
                rubrica = {"bien": b, "regular": r, "mal": m}
            n_global += 1
            nota = NOTAS.get((ex["id"], area, i))
            if nota:
                solucion = solucion.rstrip() + " Nota de la app: " + nota
            p = {"numero": n_global, "numeroEnArea": i, "area": area, "enunciado": enunciado,
                 "competencias": competencias(anio, conv, nombre_area, i), "solucionModelo": solucion, "rubrica": rubrica,
                 "fuenteSolucion": "direccion", "fuenteRubrica": "oficial" if oficial else "direccion", "puntos": extra.get("puntos", 1)}
            if (ex["id"], area, i) in NOTAS_RUBRICA:
                p["notaRubrica"] = NOTAS_RUBRICA[(ex["id"], area, i)]
            p["validacion"] = dict(VALIDACION)
            if extra.get("anulada"):
                p["anulada"] = True
            preguntas.append(p)
    aviso = AVISO + (AVISO_PROTEGIDO if ex["textoBase"]["protegido"] else "") + ex.get("avisoExtra", "")
    doc = {"id": ex["id"], "anio": anio, "convocatoria": ex["convocatoria"], "duracionMin": 90, "fuente": ex["fuente"]}
    if "fuentePlantilla" in ex:
        doc["fuentePlantilla"] = ex["fuentePlantilla"]
    doc.update({"fechaConsulta": FECHA_CONSULTA, "aviso": aviso, "textoBase": ex["textoBase"], "preguntas": preguntas,
                "validacion": dict(VALIDACION)})
    if "puntosNota" in ex:
        doc["notas"] = ex["puntosNota"]
    return doc


def hoja(docs, limite=40_000):
    bloques = []
    for d in docs:
        tb = d["textoBase"]
        bloques.append(f"\n## {d['id']} · {d['anio']} {d['convocatoria']} · texto base: {tb['autor']}, {tb['obra']}"
                       f"{' (protegido, no se reproduce)' if tb['protegido'] else ''}\n")
        for p in d["preguntas"]:
            letra = "L" if p["area"] == "LEN" else "M"
            primera = p["enunciado"].split("\n")[0]
            resumen = primera if len(primera) <= 150 else primera[:147].rstrip() + "…"
            r = p["rubrica"]
            fuente = "oficial 2026" if p["fuenteRubrica"] == "oficial" else "propia"
            nr = f"\nNota sobre la rúbrica: {p['notaRubrica']}" if p.get("notaRubrica") else ""
            bloques.append(
                f"```\n{d['id']} · {letra}{p['numeroEnArea']} · {', '.join(p['competencias'])}{' · ANULADA' if p.get('anulada') else ''}\n"
                f"{resumen}\nSolución: {p['solucionModelo']}\nRúbrica ({fuente}): B {r['bien']} / R {r['regular']} / M {r['mal']}{nr}\n```\n")
    cabecera = ("# Soluciones del Modo Tribunal · hoja de revisión (parte {n} de {t})\n\n"
                "Aprobado por la dirección el 24/11/2026. Generado por `scripts/tribunal/construir.py` a partir de los datos de "
                "`Educulter/Content/tribunal/`. Las soluciones de Matemáticas se calculan en `scripts/tribunal/matematicas.py`. "
                "Rúbricas: las de 2026 son las plantillas oficiales literales; las demás son de redacción propia, según su modelo. "
                "Las soluciones son siempre de redacción propia. Las «Notas de la app» explican cómo se resuelven las erratas y "
                "ambigüedades de los enunciados oficiales, que no se alteran.\n")
    partes, actual = [], ""
    for b in bloques:
        if len(cabecera) + len(actual) + len(b) > limite - 200:
            partes.append(actual)
            actual = ""
        actual += b
    partes.append(actual)
    return [cabecera.format(n=i, t=len(partes)) + p for i, p in enumerate(partes, 1)]


def main():
    DESTINO.mkdir(parents=True, exist_ok=True)
    docs = []
    for ex in EXAMENES:
        d = construir(ex)
        (DESTINO / f"{ex['archivo']}.json").write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        docs.append(d)
        print(f"{ex['archivo']}.json: {len(d['preguntas'])} preguntas ({sum(p['area'] == 'LEN' for p in d['preguntas'])} L + "
              f"{sum(p['area'] == 'MAT' for p in d['preguntas'])} M)")
    for viejo in (RAIZ / "docs" / "examenes").glob("SOLUCIONES_REVISION_*.md"):
        viejo.unlink()
    for i, parte in enumerate(hoja(docs), 1):
        ruta = RAIZ / "docs" / "examenes" / f"SOLUCIONES_REVISION_{i}.md"
        ruta.write_text(parte, encoding="utf-8")
        print(f"{ruta.name}: {len(parte)} caracteres")


if __name__ == "__main__":
    main()
