#!/usr/bin/env python3
"""Plantillas nuevas de la Fase 05E, parte 1 (§5): LEN.SIN, LEN.VER y LEN.LIT.

Se escriben en borrador. `--aprobar ID…` las pasa a `aprobado` (revisor «direccion», hoy) solo cuando
han superado los tests de propiedades (1000 semillas, oráculo, sin ambigüedad, distractores
distintos); `--borrador ID…` las devuelve a borrador. Idempotente: sustituye las plantillas con el
mismo id y conserva el resto del archivo.
"""
import json
import pathlib
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
PLANTILLAS = RAIZ / "Educulter/Content/plantillas"
NOTA = "Fase 05E (parte 1): plantilla nueva; se aprueba si supera los tests de propiedades."
FECHA = "2026-11-25"

CONCORDANCIA = "El sujeto concuerda con el verbo: cambia el número del verbo y mira qué cambia."


def p(id_, peldano, dificultad, mecanica, tipo, enunciado, objetivo, parametros=None, pistas=None):
    d = {"id": id_, "competencia": id_.rsplit(".", 1)[0], "peldano": peldano, "dificultad": dificultad,
         "mecanica": mecanica, "tipo": tipo, "enunciados": [enunciado], "objetivo": objetivo}
    if parametros:
        d["parametros"] = parametros
    if pistas:
        d["pistas"] = pistas
    d["procedencia"] = {"tipo": "original", "licencia": "propia", "notas": NOTA}
    d["validacion"] = {"estado": "borrador"}
    d["version"] = 1
    return d


SIN = [
    p("LEN.SIN.SUJPRED.G01", 1, 1, "marcarTexto", "oracionSimple", "Toca las palabras que forman el sujeto.",
      "Reconocer el sujeto por la concordancia", {"modo": "sujeto"}, [CONCORDANCIA, "Pregunta al verbo «¿quién?»."]),
    p("LEN.SIN.SUJPRED.G02", 2, 2, "segmentar", "oracionSimple", "Separa el sujeto y el predicado.",
      "Separar sujeto y predicado", {"modo": "sujetoPredicado"}, [CONCORDANCIA, "Todo lo que no es sujeto forma el predicado."]),
    p("LEN.SIN.SUJPRED.G03", 3, 5, "marcarTexto", "oracionSimple", "Toca las palabras que forman el sujeto.",
      "Reconocer el sujeto en oraciones más largas", {"modo": "sujeto"}),
    p("LEN.SIN.SUJPRED.G04", 4, 4, "eleccion", "oracionSimple",
      "En «{{oracion}}», si «{{forma}}» pasa a «{{otraForma}}», ¿qué grupo tiene que cambiar para que la oración siga siendo correcta?",
      "Justificar el sujeto con la prueba de la concordancia", {"modo": "concordancia"}),
    p("LEN.SIN.SUJPRED.G05", 5, 6, "marcarTexto", "oracionSimple", "Toca las palabras que forman el sujeto.",
      "Reconocer el sujeto con el orden alterado", {"modo": "sujeto"}),
    p("LEN.SIN.COMPL.G03", 1, 2, "eleccion", "oracionSimple", "¿Qué función cumple «{{sintagma}}» en «{{oracion}}»?",
      "Identificar la función de un grupo", {"modo": "funcion"}),
    p("LEN.SIN.COMPL.G04", 2, 3, "clasificar", "oracionSimple", "Clasifica cada grupo de «{{oracion}}» según su función.",
      "Clasificar los grupos de una oración por su función", {"modo": "funciones"}),
    p("LEN.SIN.COMPL.G05", 3, 4, "eleccion", "oracionSimple", "¿Qué función cumple «{{sintagma}}» en «{{oracion}}»?",
      "Identificar la función de un grupo sin ayudas", {"modo": "funcion"}),
    p("LEN.SIN.COMPL.G06", 4, 4, "eleccion", "oracionSimple", "¿Por qué pronombre se sustituye «{{sintagma}}» en «{{oracion}}»?",
      "Justificar el CD y el CI con la sustitución por pronombres", {"modo": "pronombre"}),
    p("LEN.SIN.COMPL.G07", 5, 4, "segmentar", "oracionSimple", "Analiza la oración: sujeto, predicado y complementos.",
      "Analizar sintácticamente una oración simple", {"modo": "completo"}),
    p("LEN.SIN.CLASE.G01", 2, 2, "eleccion", "oracionSimple", "¿Qué clase de oración es «{{oracion}}»?",
      "Distinguir oraciones copulativas y predicativas", {"modo": "clase"}),
    p("LEN.SIN.CLASE.G02", 3, 4, "eleccion", "oracionSimple", "¿Qué clase de oración es «{{oracion}}»?",
      "Clasificar oraciones por su predicado", {"modo": "clase"}),
    p("LEN.SIN.CLASE.G03", 5, 5, "eleccion", "oracionSimple", "¿Qué clase de oración es «{{oracion}}»?",
      "Clasificar oraciones por su predicado en formato de examen", {"modo": "clase"}),
]

ANALIZA = "Analiza la forma verbal «{{forma}}» (verbo {{infinitivo}})."
VER = [
    p("LEN.VER.ANALISIS.G02", 1, 1, "ruedas", "analisisVerbal", ANALIZA, "Analizar formas verbales regulares", {"rasgos": "basico"},
      ["Empieza por la terminación: te dice la persona y el número.", "Si lleva «haber» + participio, es una forma compuesta."]),
    p("LEN.VER.ANALISIS.G03", 2, 2, "ruedas", "analisisVerbal", ANALIZA, "Analizar formas verbales de las tres conjugaciones", {"rasgos": "basico"}),
    p("LEN.VER.ANALISIS.G04", 3, 3, "ruedas", "analisisVerbal", ANALIZA, "Analizar formas verbales con aspecto y forma", {"rasgos": "completo"}),
    p("LEN.VER.ANALISIS.G05", 4, 4, "ruedas", "analisisVerbal", ANALIZA, "Analizar formas verbales simples y compuestas", {"rasgos": "completo"}),
    p("LEN.VER.ANALISIS.G06", 5, 5, "ruedas", "analisisVerbal", ANALIZA, "Analizar formas verbales en formato de examen", {"rasgos": "completo"}),
    p("LEN.VER.NOPERS.G01", 1, 1, "clasificar", "formasNoPersonales", "Clasifica cada forma: infinitivo, gerundio o participio.",
      "Reconocer las formas no personales", None, ["Infinitivo: -ar, -er, -ir. Gerundio: -ando, -iendo. Participio: -ado, -ido."]),
    p("LEN.VER.NOPERS.G02", 2, 2, "clasificar", "formasNoPersonales", "Clasifica cada forma: infinitivo, gerundio o participio.",
      "Reconocer las formas no personales de las tres conjugaciones"),
    p("LEN.VER.NOPERS.G03", 3, 3, "eleccion", "formasNoPersonales", "¿Qué forma no personal es «{{forma}}»?",
      "Identificar una forma no personal"),
    p("LEN.VER.NOPERS.G04", 4, 4, "eleccion", "formasNoPersonales", "¿Qué forma no personal es «{{forma}}»?",
      "Distinguir formas no personales simples y compuestas"),
    p("LEN.VER.NOPERS.G05", 5, 5, "clasificar", "formasNoPersonales", "Clasifica cada forma: infinitivo, gerundio o participio.",
      "Clasificar formas no personales simples y compuestas"),
]

ESP = ["espanola"]
UNI = ["universal", "hispanoamericana"]
INF = ["infantil"]
SIGLO = "¿De qué siglo es «{{obra}}», de {{autor}}?"
UNE = "Une cada autor con su obra."
ORDENA = "Ordena a estos autores del más antiguo al más moderno."
GENERO = "Clasifica cada obra según su género literario."
LIT = [
    p("LEN.LIT.HIST.G01", 1, 1, "eleccion", "literatura", SIGLO, "Situar obras de la literatura española en su siglo",
      {"ambitos": ESP, "pregunta": "siglo"}, ["El siglo XVII va de 1601 a 1700: suma uno a las centenas del año."]),
    p("LEN.LIT.HIST.G02", 2, 2, "emparejar", "literatura", UNE, "Relacionar autores y obras de la literatura española", {"ambitos": ESP}),
    p("LEN.LIT.HIST.G03", 2, 2, "ordenar", "literatura", "Ordena estos movimientos literarios del más antiguo al más moderno.",
      "Ordenar los periodos de la literatura española", {"ambitos": ESP, "pregunta": "movimientos"}),
    p("LEN.LIT.HIST.G04", 3, 3, "eleccion", "literatura", "¿A qué movimiento o época pertenece «{{obra}}», de {{autor}}?",
      "Situar obras en su movimiento", {"ambitos": ESP, "pregunta": "movimiento"}),
    p("LEN.LIT.HIST.G05", 5, 4, "ordenar", "literatura", ORDENA, "Ordenar autores de la literatura española por época",
      {"ambitos": ESP, "pregunta": "autores"}),
    p("LEN.LIT.UNIV.G01", 2, 2, "emparejar", "literatura", UNE, "Relacionar autores y obras de la literatura universal e hispanoamericana", {"ambitos": UNI}),
    p("LEN.LIT.UNIV.G02", 3, 3, "eleccion", "literatura", SIGLO, "Situar obras de la literatura universal en su siglo", {"ambitos": UNI, "pregunta": "siglo"}),
    p("LEN.LIT.UNIV.G03", 5, 4, "ordenar", "literatura", ORDENA, "Ordenar autores de la literatura universal por época", {"ambitos": UNI, "pregunta": "autores"}),
    p("LEN.LIT.INF.G01", 2, 2, "emparejar", "literatura", UNE, "Relacionar autores y obras de la literatura infantil y juvenil", {"ambitos": INF}),
    p("LEN.LIT.INF.G02", 3, 3, "eleccion", "literatura", SIGLO, "Situar obras de la literatura infantil en su siglo", {"ambitos": INF, "pregunta": "siglo"}),
    p("LEN.LIT.INF.G03", 4, 4, "ordenar", "literatura", ORDENA, "Ordenar autores de la literatura infantil por época", {"ambitos": INF, "pregunta": "autores"}),
    p("LEN.LIT.GEN.G01", 1, 1, "clasificar", "literatura", GENERO, "Reconocer el género de una obra", None,
      ["El teatro se escribe para representarse; la narrativa cuenta una historia; la lírica expresa sentimientos."]),
    p("LEN.LIT.GEN.G02", 3, 3, "clasificar", "literatura", GENERO, "Clasificar obras por su género"),
    p("LEN.LIT.GEN.G03", 5, 5, "clasificar", "literatura", GENERO, "Clasificar obras por su género, con ensayo"),
]


def escribir(archivo, nuevas):
    ruta = PLANTILLAS / archivo
    actuales = json.loads(ruta.read_text(encoding="utf-8")) if ruta.exists() else []
    ids = {x["id"] for x in nuevas}
    previas = {x["id"]: x for x in actuales}
    # Conserva la validación ya concedida.
    for x in nuevas:
        if x["id"] in previas:
            x["validacion"] = previas[x["id"]]["validacion"]
    resultado = [x for x in actuales if x["id"] not in ids] + nuevas
    ruta.write_text(json.dumps(resultado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def cambiar_estado(ids, estado):
    for ruta in sorted(PLANTILLAS.glob("*.json")):
        datos = json.loads(ruta.read_text(encoding="utf-8"))
        cambio = False
        for x in datos:
            if x["id"] in ids:
                x["validacion"] = {"estado": "aprobado", "revisor": "direccion", "fecha": FECHA} if estado == "aprobado" else {"estado": "borrador"}
                cambio = True
        if cambio:
            ruta.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ("--aprobar", "--borrador"):
        cambiar_estado(set(sys.argv[2:]), "aprobado" if sys.argv[1] == "--aprobar" else "borrador")
    else:
        escribir("LEN.SIN.json", SIN)
        escribir("LEN.VER.json", VER)
        escribir("LEN.LIT.json", LIT)
        print(f"{len(SIN) + len(VER) + len(LIT)} plantillas nuevas en borrador")
