#!/usr/bin/env python3
"""Valida los datos del Modo Tribunal (Educulter/Content/tribunal/) y que todo JSON de Content/ es válido.

Solo biblioteca estándar. Uso:
    python3 scripts/validar_tribunal.py [--anio AAAA] [ruta/a/Content]

Errores:
  - Cualquier .json de Content/ que no sea JSON válido.
  - Campos obligatorios del examen y de cada pregunta (esquema de CONTENIDOS §2.15), id OF.AAAA.O|A,
    convocatoria, duración, fecha de consulta, numeración 1..n sin huecos, área LEN/MAT, puntos,
    rúbrica con «bien», «regular» y «mal», fuenteSolucion oficial|direccion, validación.
  - Texto base: si está protegido, sin texto y con el aviso de protección; si no, con texto y con
    autor fallecido hace más de 80 años (o el texto es de dominio público).
  - Enunciados que reproducen versos o frases del texto base protegido (no deben aparecer).
Avisos: competencias que no están en el catálogo de esta rama (las del lote 03a se indican aparte).
"""

import json
import re
import sys
from datetime import date
from pathlib import Path

RAIZ_POR_DEFECTO = Path(__file__).resolve().parent.parent / "Educulter" / "Content"
LOTE_03A = {"LEN.LEX.SIN", "LEN.LEX.POLI", "LEN.LEX.CAMPO", "LEN.LEX.CTX", "LEN.LEX.DICC", "LEN.LEX.REG", "LEN.LEX.DEN",
            "LEN.LEX.FRAS", "LEN.COM.SITU", "LEN.COM.TEMA", "LEN.COM.RESU", "LEN.COM.INFER", "LEN.COM.TIPO", "LEN.COM.PROP", "LEN.COM.GEN"}
CAMPOS_EXAMEN = ("id", "anio", "convocatoria", "duracionMin", "fuente", "fechaConsulta", "aviso", "textoBase", "preguntas", "validacion")
CAMPOS_PREGUNTA = ("numero", "area", "enunciado", "competencias", "solucionModelo", "rubrica", "fuenteSolucion", "puntos")
AVISO_PROTEGIDO = "El texto base está protegido por derechos de autor y no se reproduce. Consúltalo en el PDF oficial"


def validar_examen(nombre, d, competencias, anio_actual, errores, avisos, fuera):
    for c in CAMPOS_EXAMEN:
        if c not in d:
            errores.append(f"{nombre}: falta «{c}»")
    if errores and any(e.startswith(nombre) for e in errores):
        return
    conv = {"ordinaria": "O", "aplazada": "A"}.get(d["convocatoria"])
    if conv is None:
        errores.append(f"{nombre}: convocatoria «{d['convocatoria']}» no válida")
    elif d["id"] != f"OF.{d['anio']}.{conv}":
        errores.append(f"{nombre}: el id {d['id']} no coincide con OF.{d['anio']}.{conv}")
    if not isinstance(d["duracionMin"], int) or d["duracionMin"] <= 0:
        errores.append(f"{nombre}: duración no válida")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", d["fechaConsulta"]):
        errores.append(f"{nombre}: fechaConsulta no tiene el formato AAAA-MM-DD")
    if not d["fuente"].startswith("https://"):
        errores.append(f"{nombre}: la fuente debe ser una URL https")
    if "no está patrocinada ni avalada por la Comunidad de Madrid" not in d["aviso"]:
        errores.append(f"{nombre}: falta el aviso de no patrocinio")

    tb = d["textoBase"]
    for c in ("texto", "autor", "obra", "protegido", "anioMuerteAutor"):
        if c not in tb:
            errores.append(f"{nombre}: textoBase sin «{c}»")
    if tb.get("protegido"):
        if tb.get("texto"):
            errores.append(f"{nombre}: texto base protegido que incluye el texto")
        if AVISO_PROTEGIDO not in d["aviso"]:
            errores.append(f"{nombre}: texto protegido sin el aviso de protección")
    else:
        if not tb.get("texto"):
            errores.append(f"{nombre}: texto base no protegido sin texto")
        muerte = tb.get("anioMuerteAutor")
        if not isinstance(muerte, int) or anio_actual - muerte <= 80:
            errores.append(f"{nombre}: el autor ({muerte}) no lleva más de 80 años fallecido; debería ser protegido")
        if "  " in (tb.get("texto") or ""):
            errores.append(f"{nombre}: espacios dobles en el texto base")

    v = d["validacion"]
    if v.get("estado") not in ("borrador", "revisado", "aprobado"):
        errores.append(f"{nombre}: estado de validación no válido")
    if v.get("estado") == "aprobado" and (not v.get("revisor") or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", v.get("fecha") or "")):
        errores.append(f"{nombre}: aprobado sin revisor o fecha")

    preguntas = d["preguntas"]
    if [p.get("numero") for p in preguntas] != list(range(1, len(preguntas) + 1)):
        errores.append(f"{nombre}: las preguntas deben numerarse 1, 2, 3… en orden")
    for p in preguntas:
        pd = f"{nombre} · pregunta {p.get('numero')}"
        for c in CAMPOS_PREGUNTA:
            if c not in p or p[c] in ("", None, []):
                errores.append(f"{pd}: falta o está vacío «{c}»")
        if p.get("area") not in ("LEN", "MAT"):
            errores.append(f"{pd}: área «{p.get('area')}» no válida")
        if p.get("fuenteSolucion") not in ("oficial", "direccion"):
            errores.append(f"{pd}: fuenteSolucion no válida")
        if p.get("fuenteRubrica") not in ("oficial", "direccion"):
            errores.append(f"{pd}: fuenteRubrica no válida")
        if (p.get("fuenteRubrica") == "oficial") != (d["anio"] == 2026):
            errores.append(f"{pd}: solo las rúbricas de 2026 son oficiales")
        if not isinstance(p.get("puntos"), (int, float)) or p["puntos"] < 0 or (p["puntos"] == 0 and not p.get("anulada")):
            errores.append(f"{pd}: puntos no válidos")
        r = p.get("rubrica") or {}
        if set(r) != {"bien", "regular", "mal"} or not all(r.values()):
            errores.append(f"{pd}: la rúbrica debe tener «bien», «regular» y «mal»")
        for c in p.get("competencias") or []:
            if c not in competencias:
                fuera.setdefault(c, []).append(f"{d['id']}·{p['area'][0]}{p.get('numeroEnArea', p['numero'])}")
        if tb.get("protegido"):
            for verso in protegidos(tb):
                if verso.lower() in p.get("enunciado", "").lower():
                    errores.append(f"{pd}: el enunciado reproduce texto protegido («{verso}»)")


def protegidos(tb):
    """Fragmentos característicos de los textos protegidos que no deben aparecer en los enunciados."""
    return {"La voz a ti debida": ["si me llamaras", "los telegramas viejos", "los precios, los catálogos"],
            "Nada": ["como una hoja de papel en el viento", "obraba como una necia"]}.get(tb.get("obra"), [])


def main(argv):
    anio = date.today().year
    args = list(argv)
    if "--anio" in args:
        i = args.index("--anio")
        anio = int(args[i + 1])
        del args[i:i + 2]
    raiz = Path(args[0]) if args else RAIZ_POR_DEFECTO
    errores, avisos, fuera = [], [], {}

    total = 0
    for ruta in sorted(raiz.rglob("*.json")):
        total += 1
        try:
            json.loads(ruta.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as e:
            errores.append(f"{ruta.relative_to(raiz)}: JSON no válido ({e})")

    cat = json.loads((raiz / "catalogo.json").read_text(encoding="utf-8"))
    competencias = {c["id"] for a in cat["areas"] for b in a["bloques"] for c in b["competencias"]}

    print(f"Contenido: {raiz} · año de referencia {anio}")
    print(f"  JSON de Content/ comprobados: {total}")
    dir_trib = raiz / "tribunal"
    n_preg = 0
    ruta_reglas = dir_trib / "reglas.json"
    if ruta_reglas.exists():
        try:
            rg = json.loads(ruta_reglas.read_text(encoding="utf-8"))
            for c in ("palabraIncorrecta", "tilde", "unirSepararPalabras", "abreviatura"):
                if not isinstance(rg.get(c), (int, float)) or rg[c] <= 0:
                    errores.append(f"reglas.json: «{c}» debe ser un número positivo")
            if "limite" not in rg or (rg["limite"] is not None and not isinstance(rg["limite"], (int, float))):
                errores.append("reglas.json: «limite» debe ser null (sin límite) o un número")
            if not rg.get("fuente") or not rg.get("notas"):
                errores.append("reglas.json: faltan «fuente» o «notas»")
            print(f"  tribunal/reglas.json: palabra {rg.get('palabraIncorrecta')}, tilde {rg.get('tilde')}, "
                  f"unir/separar {rg.get('unirSepararPalabras')}, abreviatura {rg.get('abreviatura')}, límite {rg.get('limite')}")
        except json.JSONDecodeError:
            pass
    for ruta in sorted(dir_trib.glob("*.json")):
        if ruta.name in ("reglas.json", "equivalencias.json", "plano.json"):
            continue
        try:
            d = json.loads(ruta.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue  # ya se ha informado como JSON no válido
        validar_examen(ruta.name, d, competencias, anio, errores, avisos, fuera)
        len_l = sum(p.get("area") == "LEN" for p in d.get("preguntas", []))
        n_preg += len(d.get("preguntas", []))
        print(f"  tribunal/{ruta.name}: {len(d.get('preguntas', []))} preguntas ({len_l} L + {len(d.get('preguntas', [])) - len_l} M) · "
              f"texto base {'protegido' if d['textoBase']['protegido'] else 'de dominio público'} · {d['validacion']['estado']}")
    print(f"  Total: {n_preg} preguntas")
    de03a = sorted(c for c in fuera if c in LOTE_03A)
    propuestas = sorted(c for c in fuera if c not in LOTE_03A)
    if de03a:
        avisos.append(f"{len(de03a)} competencias del lote 03a (rama contenido/lote-03a, aún no en main): {', '.join(de03a)}")
    if propuestas:
        avisos.append(f"{len(propuestas)} competencias propuestas que no están en el catálogo: " +
                      "; ".join(f"{c} ({', '.join(fuera[c])})" for c in propuestas))
    for a in avisos:
        print(f"AVISO: {a}")
    for e in errores:
        print(f"ERROR: {e}")
    print(f"Resultado: {len(errores)} errores, {len(avisos)} avisos")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
