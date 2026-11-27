#!/usr/bin/env python3
"""Equivalencia de las 139 preguntas oficiales con el mapa curricular de la A1 (Fase 05E, §1.3).

Escribe `Content/tribunal/equivalencias.json` e imprime la cobertura del examen real.

- `competencia`: competencia del mapa (las 25 provisionales sin equivalencia, a su id del mapa; los
  casos dudosos, a la competencia principal).
- `entrena`: `si` si hay contenido aprobado de esa competencia en un formato que ejercita la misma
  destreza; `parcial` si hay contenido aprobado pero la destreza no es la misma (el examen pide
  redactar, definir o justificar y la app pide reconocer; o faltan rasgos como verbos irregulares);
  `no` si no hay contenido aprobado. Valoración técnica revisada a mano, pregunta a pregunta.
"""
import collections
import glob
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CONTENT = RAIZ / "Educulter/Content"

# (examen, nº de pregunta) → (competencia del mapa, entrena, nota)
P = "parcial"
EQ = {
    ("OF.2017.O", 1): ("LEN.COM.RESU", P, "Redactar un resumen; la app pide reconocer el mejor resumen."),
    ("OF.2017.O", 2): ("LEN.COM.INFER", P, "Provisional LEN.LIT.CONTEXTO: inferir la época de la historia a partir del texto."),
    ("OF.2017.O", 3): ("LEN.LEX.CTX", P, "Explicar el significado; la app pide elegirlo."),
    ("OF.2017.O", 4): ("LEN.LIT.HIST", P, "Movimiento de un texto por sus rasgos; la app pregunta el movimiento de una obra por su título."),
    ("OF.2017.O", 5): ("LEN.LIT.HIST", "no", "Provisional LEN.LIT.MOVIM: rasgos del movimiento; no hay preguntas sobre rasgos."),
    ("OF.2017.O", 6): ("LEN.VER.ANALISIS", P, "Pondré (poner) y has venido (venir) son irregulares; ignoras, regular (05G)."),
    ("OF.2017.O", 7): ("LEN.LIT.HIST", P, "Citar autores (recuerdo libre); la app pide relacionar y ordenar."),
    ("OF.2017.O", 8): ("LEN.LIT.HIST", "si", "Ordenar autores por época."),
    ("OF.2017.O", 9): ("LEN.SIN.COMPL", "si", "S + V + CCM + CCL (nivel 5 de oracionSimple)."),
    ("OF.2017.O", 10): ("MAT.OPE.INCOG", "si", "Provisional MAT.OPE.INCOG: término desconocido (D-100)."),
    ("OF.2017.O", 11): ("MAT.NUM.ORDEN", "si", ""),
    ("OF.2017.O", 12): ("MAT.NUM.FRAEQ", "si", ""),
    ("OF.2017.O", 13): ("MAT.GEO.ANG", "no", "Provisional MAT.GEO.ANGULOS."),
    ("OF.2017.O", 14): ("MAT.GEO.AREA", "no", "Provisional MAT.GEO.AREAS."),
    ("OF.2017.O", 15): ("MAT.ROM.ESCR", "si", "Provisional MAT.ROM.ESCRITURA."),
    ("OF.2017.O", 16): ("MAT.POR.VAR", "si", "Rebaja porcentual (antes MAT.POR.PORCENT)."),
    ("OF.2017.O", 17): ("MAT.DIV.MCM", "no", "Provisional MAT.DIV.MCM: sin plantilla aprobada."),
    ("OF.2017.O", 18): ("MAT.UNI.LMC", "si", "Provisional MAT.UNI.CONV (incluye ha y dm³: SUP y VOL también aprobadas)."),
    ("OF.2017.O", 19): ("MAT.OPE.COMB", "si", "Antes MAT.OPE.JERARQ."),
    ("OF.2019.A", 1): ("LEN.COM.RESU", P, "Resumir y comentar."),
    ("OF.2019.A", 2): ("LEN.COM.INFER", P, "Comentar el sentido de una frase."),
    ("OF.2019.A", 3): ("LEN.LEX.CTX", P, "Explicar el significado."),
    ("OF.2019.A", 4): ("LEN.LEX.REG", "no", "Provisional LEN.LEX.CONCEPTOS: definir neologismo, arcaísmo, eufemismo, morfema y acrónimo; no hay contenido de esos conceptos."),
    ("OF.2019.A", 5): ("LEN.FOR.DER", "no", "Provisional LEN.FOR.DERIV."),
    ("OF.2019.A", 6): ("LEN.VER.ANALISIS", P, "Oí y era son irregulares (fuera del generador)."),
    ("OF.2019.A", 7): ("LEN.CLA.ADJGRAD", "no", "Grados del adjetivo (antes LEN.CLA.SUSTADJ)."),
    ("OF.2019.A", 8): ("LEN.LIT.HIST", P, "Citar autores."),
    ("OF.2019.A", 9): ("LEN.LIT.HIST", "si", "Ordenar autores."),
    ("OF.2019.A", 10): ("LEN.SIN.COMPL", P, "Complemento predicativo: no se genera."),
    ("OF.2019.A", 11): ("MAT.NUM.FRAPROB", "si", "Provisional MAT.NUM.FRACDE."),
    ("OF.2019.A", 12): ("MAT.UNI.TIEM", "si", "Provisional MAT.UNI.TIEMPO."),
    ("OF.2019.A", 13): ("MAT.OPE.INCOG", "si", "Provisional MAT.OPE.INCOG: término desconocido (D-100)."),
    ("OF.2019.A", 14): ("MAT.NUM.ORDEN", "si", ""),
    ("OF.2019.A", 15): ("MAT.POR.PROP", "si", "Provisional MAT.POR.PROPORC."),
    ("OF.2019.A", 16): ("MAT.PRO.LAPLACE", "si", "Sucesos con 10 bolas numeradas."),
    ("OF.2019.A", 17): ("MAT.GEO.VOL", "no", "Provisional MAT.GEO.VOLUMEN."),
    ("OF.2019.A", 18): ("MAT.EST.CENTRAL", "si", "Media, mediana y rango de 5 datos."),
    ("OF.2019.A", 19): ("MAT.ROM.LEER", "si", "Antes MAT.ROM.LECTURA."),
    ("OF.2019.A", 20): ("MAT.OPE.COMB", "si", ""),
    ("OF.2019.O", 1): ("LEN.COM.RESU", P, "Tema y comentario de un poema."),
    ("OF.2019.O", 2): ("LEN.LIT.HIST", "si", "Generación del autor: la app pregunta el movimiento de sus obras."),
    ("OF.2019.O", 3): ("LEN.REC.FIG", "no", "Antes LEN.REC.FIGURAS."),
    ("OF.2019.O", 4): ("LEN.REC.DEF", "no", "Definir la metáfora."),
    ("OF.2019.O", 5): ("LEN.ORT.DIA", P, "Explicar la diferencia entre si y sí; la app pide elegir la forma."),
    ("OF.2019.O", 6): ("LEN.VER.ANALISIS", "si", "Formas regulares (llamaras, espero, llamas; revisado en la 05G)."),
    ("OF.2019.O", 7): ("LEN.CLA.ADJGRAD", "no", ""),
    ("OF.2019.O", 8): ("LEN.LIT.HIST", P, "Citar autores."),
    ("OF.2019.O", 9): ("LEN.LIT.HIST", "si", "Ordenar autores."),
    ("OF.2019.O", 10): ("LEN.SIN.COMPL", P, "Verbo semicopulativo con predicativo: no se genera."),
    ("OF.2019.O", 11): ("MAT.NUM.FRAOP", "si", "Antes MAT.OPE.FRACSUM."),
    ("OF.2019.O", 12): ("MAT.UNI.TIEM", "si", ""),
    ("OF.2019.O", 13): ("MAT.OPE.INCOG", "si", "Provisional MAT.OPE.INCOG: término desconocido (D-100)."),
    ("OF.2019.O", 14): ("MAT.NUM.ORDEN", "si", ""),
    ("OF.2019.O", 15): ("MAT.GEO.VOL", "no", "Provisional MAT.UNI.VOLCAP: el paso a litros se practica en MAT.UNI.VOL, pero el volumen del prisma no."),
    ("OF.2019.O", 16): ("MAT.EST.CENTRAL", "si", "Media, moda y rango de 5 datos."),
    ("OF.2019.O", 17): ("MAT.EST.FREC", "no", "Provisional MAT.EST.FRECUENCIAS."),
    ("OF.2019.O", 18): ("MAT.GEO.AREA", "no", ""),
    ("OF.2019.O", 19): ("MAT.ROM.ESCR", "si", ""),
    ("OF.2019.O", 20): ("MAT.OPE.COMB", "si", ""),
    ("OF.2022.O", 1): ("LEN.COM.RESU", P, ""),
    ("OF.2022.O", 2): ("LEN.COM.TIPO", P, "Identificar el tipo y enumerar características."),
    ("OF.2022.O", 3): ("LEN.LEX.CTX", P, ""),
    ("OF.2022.O", 4): ("LEN.VER.ANALISIS", P, "Sonrío (sonreír) es irregular y el generador regular no la cubre; perdiste y hundiré, regulares (05G)."),
    ("OF.2022.O", 5): ("LEN.LEX.POLI", P, "Explicar dos acepciones."),
    ("OF.2022.O", 6): ("LEN.COM.INFER", P, ""),
    ("OF.2022.O", 7): ("LEN.MET.MED", "no", "Provisional LEN.MET.MEDIDA."),
    ("OF.2022.O", 8): ("LEN.REC.DEF", "no", "Definir metáfora, homónimas, verso libre y comparación."),
    ("OF.2022.O", 9): ("LEN.ORT.DIA", "si", "Elegir entre dos formas con tilde diacrítica."),
    ("OF.2022.O", 10): ("LEN.SIN.COMPL", P, "Complemento del nombre: no se genera."),
    ("OF.2022.O", 11): ("MAT.DIV.MCD", "si", "m.c.d. de tres números en un reparto (plantilla aprobada en la 05E parte 2)."),
    ("OF.2022.O", 12): ("MAT.NUM.ORDEN", "si", ""),
    ("OF.2022.O", 13): ("MAT.OPE.JER", P, "Jerarquía con decimales: el generador solo usa naturales."),
    ("OF.2022.O", 14): ("MAT.UNI.LMC", "si", ""),
    ("OF.2022.O", 15): ("MAT.GEO.AREA", "no", ""),
    ("OF.2022.O", 16): ("MAT.POR.CALC", "si", ""),
    ("OF.2022.O", 17): ("MAT.EST.CENTRAL", "parcial", "Tabla de frecuencias con decimales: el generador da listas de datos."),
    ("OF.2022.O", 18): ("MAT.OPE.POT", "no", "Provisional MAT.NUM.POT10."),
    ("OF.2022.O", 19): ("MAT.POR.PROP", "si", "Reducción a la unidad con decimales."),
    ("OF.2022.O", 20): ("MAT.GEO.VOL", "no", ""),
    ("OF.2024.O", 1): ("LEN.COM.RESU", P, ""),
    ("OF.2024.O", 2): ("LEN.LIT.HIST", P, "Autor y contexto histórico."),
    ("OF.2024.O", 3): ("LEN.LIT.HIST", "no", "Corrientes del Barroco (culteranismo y conceptismo): no hay contenido."),
    ("OF.2024.O", 4): ("LEN.LEX.CTX", P, "Definir palabras."),
    ("OF.2024.O", 5): ("LEN.VER.ANALISIS", P, "Es, estuvieras y visto son irregulares."),
    ("OF.2024.O", 6): ("LEN.LEX.SIN", P, "Escribir sinónimos y antónimos; la app pide elegirlos."),
    ("OF.2024.O", 7): ("LEN.ORT.AGU", P, "Tildes en un texto con contexto: la app trabaja palabras y frases sueltas."),
    ("OF.2024.O", 8): ("LEN.LEX.DICC", P, "Provisional LEN.LEX.DEFIN: escribir la palabra de una definición."),
    ("OF.2024.O", 9): ("LEN.FOR.DER", "no", ""),
    ("OF.2024.O", 10): ("LEN.SIN.COMPL", "si", "S + V + CD + CI (nivel 5)."),
    ("OF.2024.O", 11): ("MAT.NUM.ORDEN", P, "Hay que calcular expresiones antes de ordenar."),
    ("OF.2024.O", 12): ("MAT.NUM.FRAOP", "si", "Combinada con corchetes (nivel 6)."),
    ("OF.2024.O", 13): ("MAT.NUM.VALPOS", "no", "Provisional MAT.NUM.DESCOMP."),
    ("OF.2024.O", 14): ("MAT.DIV.MCM", "no", ""),
    ("OF.2024.O", 15): ("MAT.POR.PROP", "no", "Trabajo conjunto (proporcionalidad inversa): no se genera."),
    ("OF.2024.O", 16): ("MAT.UNI.LMC", "si", "Suma de cantidades complejas (nivel 5)."),
    ("OF.2024.O", 17): ("MAT.GEO.VOL", "no", ""),
    ("OF.2024.O", 18): ("MAT.GEO.CART", "no", "Provisional MAT.GEO.COORD."),
    ("OF.2024.O", 19): ("MAT.PRO.SUCESOS", "no", "Provisional MAT.PRO.CONCEPTOS."),
    ("OF.2024.O", 20): ("MAT.EST.CENTRAL", "parcial", "30 datos: el generador usa de 5 a 8."),
    ("OF.2026.A", 1): ("LEN.COM.RESU", P, ""),
    ("OF.2026.A", 2): ("LEN.LIT.HIST", P, "Autor, Generación del 27 y rasgos."),
    ("OF.2026.A", 3): ("LEN.COM.INFER", P, ""),
    ("OF.2026.A", 4): ("LEN.CLA.JUST", "no", "Clase de palabra con justificación (antes LEN.CLA.SUSTADJ)."),
    ("OF.2026.A", 5): ("LEN.LEX.CAMPO", P, "Escribir palabras de la familia y del campo; también LEN.LEX.SIN."),
    ("OF.2026.A", 6): ("LEN.REC.FIG", "no", "También métrica."),
    ("OF.2026.A", 7): ("LEN.ORT.HOM", "si", "Elegir la forma en frases con hueco."),
    ("OF.2026.A", 8): ("LEN.REC.DEF", "no", "Relacionar término y definición."),
    ("OF.2026.A", 9): ("LEN.FOR.CLAS", "no", "Primitivas, derivadas y compuestas."),
    ("OF.2026.A", 10): ("LEN.SIN.SUJPRED", "si", ""),
    ("OF.2026.A", 11): ("MAT.NUM.FRAPROB", "si", ""),
    ("OF.2026.A", 12): ("MAT.UNI.TIEM", "si", ""),
    ("OF.2026.A", 13): ("MAT.OPE.INCOG", "si", "Provisional MAT.OPE.INCOG: término desconocido (D-100)."),
    ("OF.2026.A", 14): ("MAT.NUM.ORDEN", "si", ""),
    ("OF.2026.A", 15): ("MAT.POR.PROP", "si", ""),
    ("OF.2026.A", 16): ("MAT.PRO.LAPLACE", "si", "Sucesos con 12 tarjetas."),
    ("OF.2026.A", 17): ("MAT.GEO.VOL", "no", "El paso de m³ a litros se practica en MAT.UNI.VOL, pero el volumen del prisma no."),
    ("OF.2026.A", 18): ("MAT.EST.CENTRAL", "si", "Media, mediana, moda y rango de 6 datos."),
    ("OF.2026.A", 19): ("MAT.ROM.LEER", "si", ""),
    ("OF.2026.A", 20): ("MAT.OPE.COMB", "si", "Con llaves (nivel 5)."),
    ("OF.2026.O", 1): ("LEN.COM.RESU", P, ""),
    ("OF.2026.O", 2): ("LEN.COM.TIPO", P, ""),
    ("OF.2026.O", 3): ("LEN.LIT.HIST", P, "Contextualizar el fragmento y nombrar obra y autor."),
    ("OF.2026.O", 4): ("LEN.FOR.DER", "no", "Prefijos y su significado."),
    ("OF.2026.O", 5): ("LEN.LEX.DICC", P, "Explicar qué es un diccionario."),
    ("OF.2026.O", 6): ("LEN.CLA.VAR", "no", "Análisis morfológico (antes LEN.CLA.VERBO)."),
    ("OF.2026.O", 7): ("LEN.VER.IRREG", "no", "Provisional LEN.VER.NORMA (anduve/andé)."),
    ("OF.2026.O", 8): ("LEN.REC.DEF", "no", "Narrador, novela, hipérbole y adjetivo."),
    ("OF.2026.O", 9): ("LEN.CLA.VAR", "no", "Clases de palabras por su definición."),
    ("OF.2026.O", 10): ("LEN.SIN.COMPL", "si", "S + V + CD + CCL."),
    ("OF.2026.O", 11): ("MAT.NUM.EQUIV", "no", "Antes MAT.OPE.EQUIV."),
    ("OF.2026.O", 12): ("MAT.OPE.POT", "no", "Provisional MAT.NUM.POT10."),
    ("OF.2026.O", 13): ("MAT.NUM.FRAPROB", "si", "Fracción del resto (antes MAT.OPE.FRACSUM)."),
    ("OF.2026.O", 14): ("MAT.UNI.LMC", "si", "Antes MAT.UNI.LONG."),
    ("OF.2026.O", 15): ("MAT.PRO.SUCESOS", "no", "Probabilidad estimada por la frecuencia relativa."),
    ("OF.2026.O", 16): ("MAT.POR.CALC", "si", ""),
    ("OF.2026.O", 17): ("MAT.GEO.AREA", "no", ""),
    ("OF.2026.O", 18): ("MAT.DIV.REGLAS", "no", "Provisional MAT.DIV.CRITERIOS."),
    ("OF.2026.O", 19): ("MAT.EST.FREC", "no", ""),
    ("OF.2026.O", 20): ("MAT.UNI.ESC", "si", "Provisional MAT.POR.ESCALAS."),
}


def competencias_con_contenido():
    """Competencias con contenido aprobado (ítems o plantillas), tras esta fase."""
    con = set()
    for ruta in glob.glob(str(CONTENT / "items/*.json")) + glob.glob(str(CONTENT / "plantillas/*.json")):
        for x in json.loads(pathlib.Path(ruta).read_text(encoding="utf-8")):
            if x["validacion"]["estado"] == "aprobado":
                con.add(x["competencia"])
    return con


def main():
    catalogo = json.loads((CONTENT / "catalogo.json").read_text(encoding="utf-8"))
    ids = {c["id"] for a in catalogo["areas"] for b in a["bloques"] for c in b["competencias"]}
    legado = {c["id"] for a in catalogo["areas"] for b in a["bloques"] for c in b["competencias"] if "equivaleA" in c}
    con = competencias_con_contenido()
    preguntas = []
    for ruta in sorted((CONTENT / "pendiente/tribunal").glob("*_*.json")):
        examen = json.loads(ruta.read_text(encoding="utf-8"))
        for p in examen["preguntas"]:
            comp, entrena, nota = EQ[(examen["id"], p["numero"])]
            assert comp in ids and comp not in legado, comp
            # Coherencia con el contenido real: «sí» o «parcial» exigen contenido aprobado; «no», que no lo haya
            # (salvo cuando la destreza no está: rasgos del movimiento, corrientes del Barroco, inversa).
            if entrena != "no":
                assert comp in con, (examen["id"], p["numero"], comp)
            preguntas.append({"examen": examen["id"], "numero": p["numero"], "area": p["area"],
                              "competenciaOriginal": p["competencias"], "competencia": comp, "entrena": entrena, "nota": nota})
    assert len(preguntas) == 139
    salida = {"version": 1,
              "nota": "Equivalencia de las preguntas oficiales con el mapa curricular de la A1 y valoración de si la app las entrena hoy "
                      "(Fase 05E, §1.3). «si»: contenido aprobado en un formato que ejercita la misma destreza; «parcial»: hay contenido "
                      "aprobado de la competencia, pero la destreza no es la misma; «no»: sin contenido aprobado o sin esa destreza. "
                      "Generado por scripts/equivalencias_tribunal.py.",
              "preguntas": preguntas}
    (CONTENT / "tribunal").mkdir(exist_ok=True)
    (CONTENT / "tribunal/equivalencias.json").write_text(json.dumps(salida, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def pct(lista, valores=("si",)):
        return 100 * sum(1 for x in lista if x["entrena"] in valores) / len(lista)
    print(f"Total: sí {pct(preguntas):.1f} % · sí + parcial {pct(preguntas, ('si', 'parcial')):.1f} % ({len(preguntas)} preguntas)")
    for area in ("LEN", "MAT"):
        l = [x for x in preguntas if x["area"] == area]
        print(f"  {area}: sí {pct(l):.1f} % · sí + parcial {pct(l, ('si', 'parcial')):.1f} % ({len(l)})")
    for ex in sorted({x["examen"] for x in preguntas}):
        l = [x for x in preguntas if x["examen"] == ex]
        print(f"  {ex}: sí {pct(l):.0f} % · sí + parcial {pct(l, ('si', 'parcial')):.0f} % ({len(l)})")
    vacias = collections.Counter(x["competencia"] for x in preguntas if x["competencia"] not in con)
    print("Competencias vacías con más preguntas oficiales:", vacias.most_common(12))


if __name__ == "__main__":
    main()
