#!/usr/bin/env python3
"""Carga el mapa curricular de la A1 (ANEXO A del prompt de la Fase 05E) en Content/catalogo.json.

Reglas (Fase 05E, §2):
- Se conservan todos los ids existentes; solo se añaden bloques y competencias.
- No se renombra nada que ya exista (ni ids ni nombres).
- La prioridad de cada bloque es la del mapa (★ = 1, ★★ = 2, ★★★ = 3).
- Las competencias antiguas que el mapa sustituye por otra con otro id llevan `equivaleA`
  (la app las oculta del Camino mientras no tengan contenido; su progreso se conserva).

Idempotente: se puede ejecutar varias veces.
"""
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CATALOGO = RAIZ / "Educulter/Content/catalogo.json"

# Bloque → (nombre en el mapa, prioridad, [(sufijo, nombre)]). Orden del ANEXO A.
MAPA = {
    "LEN": [
        ("LEN.HAB", "Las lenguas y sus hablantes", 2, [
            ("ORIG", "Origen y evolución del español"), ("RAE", "La RAE y la norma"),
            ("LENESP", "Lenguas y variedades de España"), ("SIGNOS", "Lenguas de signos y comunicación accesible"),
            ("NODISC", "Lenguaje no discriminatorio")]),
        ("LEN.COM", "Comunicación y comprensión", 3, [
            ("SITU", "Elementos de la comunicación"), ("TEMA", "Tema e idea principal"), ("RESU", "El resumen"),
            ("INFER", "Inferencias y sentido"), ("TIPO", "Tipos de texto"), ("PROP", "Coherencia, cohesión y adecuación"),
            ("GEN", "Géneros discursivos")]),
        ("LEN.LIT", "Educación literaria", 3, [
            ("GEN", "Géneros y subgéneros literarios"), ("OBRA", "Elementos de la obra literaria"),
            ("HIST", "Historia de la literatura española"), ("UNIV", "Literatura universal"),
            ("INF", "Literatura infantil y juvenil"), ("POP", "Refranes, greguerías y literatura popular")]),
        ("LEN.REC", "Recursos literarios", 2, [
            ("FIG", "Identificar recursos literarios"), ("DEF", "Definir recursos literarios")]),
        ("LEN.MET", "Métrica", 2, [
            ("MED", "Medida del verso"), ("RIMA", "Rima consonante y asonante"), ("ESTR", "Estrofas")]),
        ("LEN.CLA", "Clases de palabras", 3, [
            ("VAR", "Palabras variables"), ("INV", "Palabras invariables"), ("ADJGRAD", "Grados del adjetivo"),
            ("JUST", "Justificar la categoría")]),
        ("LEN.VER", "El verbo", 3, [
            # ANAL = LEN.VER.ANALISIS (id existente, se conserva como canónico).
            ("NOPERS", "Formas no personales"), ("IRREG", "Verbos irregulares"), ("VOZ", "Voz activa y pasiva")]),
        ("LEN.SIN", "Sintaxis", 3, [
            ("SUJPRED", "Sujeto y predicado"), ("SINT", "Sintagmas y núcleo"), ("COMPL", "Complementos"),
            ("MODAL", "Tipos de oración por la intención"), ("CLASE", "Clases de oración"),
            ("COMP", "La oración compuesta")]),
        ("LEN.ORT", "Ortografía", 3, [
            ("AGU", ""), ("DIA", ""), ("HIA", ""), ("PQ", ""), ("HOM", ""),
            ("LET", "Uso de letras"), ("PUNT", "Signos de puntuación"), ("MAY", "Mayúsculas")]),
        ("LEN.LEX", "Léxico y semántica", 3, [
            ("SIN", ""), ("POLI", ""), ("CAMPO", ""), ("CTX", ""), ("DICC", ""), ("REG", ""), ("DEN", ""), ("FRAS", "")]),
        ("LEN.FOR", "Formación de palabras", 2, [
            ("ESTR", "Lexema y morfemas"), ("DER", "Prefijos y sufijos"), ("COMP", "Composición"),
            ("CLAS", "Primitivas, derivadas, compuestas y parasintéticas"), ("SIGL", "Siglas, acrónimos y abreviaturas")]),
    ],
    "MAT": [
        ("MAT.NUM", "Números", 3, [
            ("TIPOS", "Tipos de números"), ("VALPOS", "Valor posicional y redondeo"), ("ORDEN", ""), ("FRAREP", ""),
            ("FRAEQ", ""), ("FRAOP", ""), ("FRAPROB", ""), ("EQUIV", "Fracción, decimal y porcentaje"),
            ("ENT", "Números enteros en contexto")]),
        ("MAT.OPE", "Operaciones", 3, [
            ("JER", ""), ("COMB", ""), ("ECUAC", ""), ("POT", "Potencias"), ("RAIZ", "Raíz cuadrada exacta"),
            ("MENTAL", "Cálculo mental y estimación")]),
        ("MAT.DIV", "Divisibilidad", 3, [
            ("REGLAS", "Criterios de divisibilidad"), ("MULDIV", "Múltiplos y divisores"),
            ("PRIMOS", "Primos, compuestos y factorización"), ("MCM", "Mínimo común múltiplo"), ("MCD", "")]),
        ("MAT.POR", "Proporcionalidad y finanzas", 3, [
            ("CALC", ""), ("TOTAL", ""), ("VAR", ""), ("PROP", ""), ("FIN", "Educación financiera")]),
        ("MAT.UNI", "Medida", 3, [
            ("LMC", ""), ("SUP", ""), ("VOL", ""), ("TIEM", ""), ("ESC", ""), ("ANG", "Medida de ángulos"),
            ("ESTIM", "Estimación de medidas")]),
        ("MAT.GEO", "Geometría", 3, [
            ("CLAS", "Figuras planas"), ("CUER", "Cuerpos geométricos"), ("ANG", "Ángulos"), ("PER", "Perímetros"),
            ("AREA", "Áreas"), ("VOL", "Volúmenes"), ("CART", "Coordenadas cartesianas"),
            ("MOV", "Giros, traslaciones y simetrías"), ("SEMEJ", "Semejanza")]),
        ("MAT.ALG", "Álgebra y pensamiento computacional", 1, [
            ("PATR", "Patrones y series"), ("IGUAL", "Igualdades y desigualdades"), ("ALGO", "Algoritmos sencillos")]),
        ("MAT.EST", "Estadística", 3, [
            ("CENTRAL", ""), ("FREC", "Frecuencias absolutas y relativas"), ("GRAF", "Gráficos estadísticos"),
            ("POBL", "Muestra y población")]),
        ("MAT.PRO", "Probabilidad", 2, [
            ("LAPLACE", ""), ("SUCESOS", "Tipos de sucesos"), ("RECUENTO", "Diagramas de árbol y recuento")]),
        ("MAT.ROM", "Numeración romana", 2, [("LEER", ""), ("ESCR", "")]),
    ],
}

# Competencias existentes que el mapa sustituye por otra (id antiguo → id del mapa).
EQUIVALENCIAS = {
    "LEN.LIT.CRONO": "LEN.LIT.HIST",
    "LEN.LIT.AUTOBRA": "LEN.LIT.HIST",
    "LEN.REC.FIGURAS": "LEN.REC.FIG",
    "LEN.CLA.SUSTADJ": "LEN.CLA.VAR",
    "LEN.CLA.VERBO": "LEN.CLA.VAR",
    "LEN.LEX.SINON": "LEN.LEX.SIN",
    "MAT.UNI.LONG": "MAT.UNI.LMC",
    "MAT.GEO.TRIANG": "MAT.GEO.CLAS",
    "MAT.POR.PORCENT": "MAT.POR.CALC",
    "MAT.OPE.JERARQ": "MAT.OPE.JER",
    "MAT.OPE.FRACSUM": "MAT.NUM.FRAOP",
    "MAT.OPE.EQUIV": "MAT.NUM.EQUIV",
    "MAT.ROM.LECTURA": "MAT.ROM.LEER",
}


def main() -> None:
    cat = json.loads(CATALOGO.read_text(encoding="utf-8"))
    ids_previos = {c["id"] for a in cat["areas"] for b in a["bloques"] for c in b["competencias"]}
    for area in cat["areas"]:
        bloques = {b["id"]: b for b in area["bloques"]}
        for bloque_id, nombre, prioridad, comps in MAPA[area["id"]]:
            b = bloques.get(bloque_id)
            if b is None:
                b = {"id": bloque_id, "nombre": nombre, "prioridad": prioridad,
                     "orden": max(x["orden"] for x in area["bloques"]) + 1, "competencias": []}
                area["bloques"].append(b)
                bloques[bloque_id] = b
            b["prioridad"] = prioridad
            existentes = {c["id"] for c in b["competencias"]}
            for sufijo, nombre_c in comps:
                cid = f"{bloque_id}.{sufijo}"
                if cid in existentes:
                    continue
                if not nombre_c:
                    raise SystemExit(f"{cid} no existe y no tiene nombre en el mapa")
                orden = max([c["orden"] for c in b["competencias"] if c["orden"] < 99] or [0]) + 1
                b["competencias"].append({"id": cid, "nombre": nombre_c, "orden": orden})
        for b in area["bloques"]:
            for c in b["competencias"]:
                if c["id"] in EQUIVALENCIAS:
                    c["equivaleA"] = EQUIVALENCIAS[c["id"]]
    cat["version"] = max(cat["version"], 3)
    ids = {c["id"] for a in cat["areas"] for b in a["bloques"] for c in b["competencias"]}
    assert ids_previos <= ids, "Se ha perdido un id existente"
    for antiguo, nuevo in EQUIVALENCIAS.items():
        assert antiguo in ids and nuevo in ids, (antiguo, nuevo)
    CATALOGO.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    bloques = [b for a in cat["areas"] for b in a["bloques"]]
    mapa = sum(len(c) for a in MAPA.values() for *_, c in a) + 1  # + LEN.VER.ANALISIS (ANAL)
    print(f"{len(bloques)} bloques, {len(ids)} competencias en el catálogo ({mapa} del mapa, "
          f"{len(EQUIVALENCIAS)} antiguas con equivalencia)")


if __name__ == "__main__":
    main()
