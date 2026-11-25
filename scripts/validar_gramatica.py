#!/usr/bin/env python3
"""Valida los recursos de gramática (Educulter/Content/gramatica/) sin Swift.

Solo biblioteca estándar. Uso:
    python3 scripts/validar_gramatica.py [ruta/a/Content]

Errores (código de salida 1):
  Frases (frases.json y frases_lote02b.json):
    - ids de frase y de familia únicos; la familia existe y no repite formas;
    - exactamente un «___» por frase;
    - la forma correcta está en su familia sin distinguir mayúsculas y coincide exactamente
      con una forma tras poner su inicial en mayúscula (GeneradorFraseHueco.ajustar; si no,
      `construir` falla);
    - mayúscula solo si el hueco abre la frase (tras ¿ o ¡);
    - la competencia (si la hay) existe en el catálogo.
  Formato neutro (compatibilidad.json):
    - lemas, adjetivos e infinitivos únicos; género m/f;
    - adjetivos con sus 4 formas;
    - cada verbo transitivo tiene al menos un sustantivo compatible (etiquetas de `objeto`);
      los intransitivos no tienen objeto;
    - `conjugacion` coherente con la terminación; etiquetas de sujeto existentes.
  Esquema de Swift (piezas.json y verbos.json):
    - clases de palabra válidas; sujetos con género y número;
    - verbos transitivos con CD; si algún verbo admite CI, hay complementos CI;
    - solo complementos CI, CCL, CCT y CCM; tiempos de CCT válidos;
    - atributos con ms, fs, mp y fp;
    - verbos regulares en -ar, -er o -ir y sin repetir; irregulares con 6 formas por tiempo.
Avisos (no hacen fallar): campos obligatorios en Swift que faltan en frases_lote02b.json y
familias de las plantillas fraseHueco que no existen en el banco de frases.
"""

import json
import re
import sys
from pathlib import Path

RAIZ_POR_DEFECTO = Path(__file__).resolve().parent.parent / "Educulter" / "Content"
CLASES = {"det", "sust", "verbo", "adj", "prep", "adv", "pron"}
REGIMENES = {"intransitivo", "transitivo", "copulativo"}
COMPLEMENTOS = {"CI", "CCL", "CCT", "CCM"}
TIEMPOS = {"Presente", "Pretérito imperfecto", "Pretérito perfecto simple", "Futuro simple", "Condicional simple",
           "Pretérito perfecto compuesto", "Pretérito pluscuamperfecto", "Futuro compuesto", "Condicional compuesto"}


def ajustar(t, modelo):
    return t[:1].upper() + t[1:] if modelo[:1].isupper() else t


def repetidos(valores):
    vistos, rep = set(), set()
    for v in valores:
        (rep if v in vistos else vistos).add(v)
    return sorted(rep)


def validar_frases(nombre, banco, competencias, errores, avisos):
    familias, sin_uso_total, familias_sin_uso = {}, 0, 0
    for i in repetidos([f["id"] for f in banco.get("familias", [])]):
        errores.append(f"{nombre}: familia repetida {i}")
    for fam in banco.get("familias", []):
        formas = [f["texto"] for f in fam["formas"]]
        familias[fam["id"]] = formas
        if len(formas) < 2:
            errores.append(f"{nombre} · familia {fam['id']}: necesita al menos 2 formas")
        if len(set(formas)) != len(formas):
            errores.append(f"{nombre} · familia {fam['id']}: formas repetidas")
        sin_uso = [f["texto"] for f in fam["formas"] if not f.get("uso")]
        if sin_uso:
            sin_uso_total += len(sin_uso)
            familias_sin_uso += 1
    if sin_uso_total:
        avisos.append(f"{nombre}: {sin_uso_total} formas de {familias_sin_uso} familias sin «uso» (obligatorio en Swift)")
    for i in repetidos([f["id"] for f in banco.get("frases", [])]):
        errores.append(f"{nombre}: frase repetida {i}")
    sin_dificultad = 0
    for f in banco.get("frases", []):
        d = f"{nombre} · {f['id']}"
        texto, correcta = f["texto"], f["correcta"]
        if "dificultad" not in f:
            sin_dificultad += 1
        if texto.count("___") != 1:
            errores.append(f"{d}: debe tener exactamente un «___» (tiene {texto.count('___')})")
        formas = familias.get(f["familia"])
        if formas is None:
            errores.append(f"{d}: la familia {f['familia']} no existe")
        else:
            if correcta.lower() not in {x.lower() for x in formas}:
                errores.append(f"{d}: «{correcta}» no está en la familia {f['familia']} {formas}")
            elif correcta not in {ajustar(x, correcta) for x in formas}:
                errores.append(f"{d}: «{correcta}» solo coincide cambiando mayúsculas en mitad de la palabra")
        al_inicio = re.match(r"^[¿¡]?___", texto) is not None
        if al_inicio != correcta[:1].isupper():
            errores.append(f"{d}: «{correcta}» {'debería' if al_inicio else 'no debería'} ir con mayúscula en «{texto}»")
        comp = f.get("competencia")
        if comp is not None and comp not in competencias:
            errores.append(f"{d}: la competencia {comp} no existe en el catálogo")
    if sin_dificultad:
        avisos.append(f"{nombre}: {sin_dificultad} frases sin «dificultad» (obligatoria en Swift)")
    return set(familias)


def validar_neutro(neutro, errores):
    sust, adjs, verbos = neutro["sustantivos"], neutro["adjetivos"], neutro["verbos"]
    for i in repetidos([s["lema"] for s in sust]):
        errores.append(f"compatibilidad.json: sustantivo repetido {i}")
    for i in repetidos([a["ms"] for a in adjs]):
        errores.append(f"compatibilidad.json: adjetivo repetido {i}")
    for i in repetidos([v["infinitivo"] for v in verbos]):
        errores.append(f"compatibilidad.json: verbo repetido {i}")
    etiquetas = set()
    for s in sust:
        etiquetas |= set(s["etiquetas"])
        if s["genero"] not in ("m", "f"):
            errores.append(f"compatibilidad.json · {s['lema']}: género «{s['genero']}» no válido")
        if not s.get("plural"):
            errores.append(f"compatibilidad.json · {s['lema']}: sin plural")
    for a in adjs:
        faltan = [k for k in ("ms", "fs", "mp", "fp") if not a.get(k)]
        if faltan:
            errores.append(f"compatibilidad.json · adjetivo {a.get('ms')}: faltan las formas {faltan}")
        for e in set(a["etiquetas"]) - etiquetas:
            errores.append(f"compatibilidad.json · adjetivo {a['ms']}: la etiqueta «{e}» no la tiene ningún sustantivo")
    for v in verbos:
        d = f"compatibilidad.json · {v['infinitivo']}"
        esperada = {"ar": 1, "er": 2, "ir": 3}.get(v["infinitivo"][-2:])
        if v["conjugacion"] != esperada:
            errores.append(f"{d}: conjugación {v['conjugacion']} no coincide con la terminación")
        if v["regimen"] == "transitivo":
            compatibles = [s["lema"] for s in sust if set(v["objeto"] or []) & set(s["etiquetas"])]
            if not compatibles:
                errores.append(f"{d}: verbo transitivo sin ningún sustantivo compatible como CD")
        elif v.get("objeto"):
            errores.append(f"{d}: verbo {v['regimen']} con objeto")
        for e in set(v["sujeto"]) - etiquetas:
            errores.append(f"{d}: la etiqueta de sujeto «{e}» no la tiene ningún sustantivo")


def validar_sintagma(s, d, errores):
    for t in s.get("tokens", []):
        if len(t) != 2 or not t[0] or t[1] not in CLASES:
            errores.append(f"{d}: token no válido {t}")
    for t in s.get("tiempo") or []:
        if t not in TIEMPOS:
            errores.append(f"{d}: tiempo «{t}» no válido")


def validar_piezas(p, errores):
    for i, s in enumerate(p.get("sujetos", [])):
        d = f"piezas.json · sujeto {i + 1}"
        validar_sintagma(s, d, errores)
        if s.get("genero") not in ("m", "f") or s.get("numero") not in ("s", "p"):
            errores.append(f"{d}: falta género (m/f) o número (s/p)")
    for i in repetidos([v["infinitivo"] for v in p.get("verbos", [])]):
        errores.append(f"piezas.json: verbo repetido {i}")
    for v in p.get("verbos", []):
        d = f"piezas.json · {v['infinitivo']}"
        if v["regimen"] not in REGIMENES:
            errores.append(f"{d}: régimen «{v['regimen']}» no válido")
        if v["regimen"] == "transitivo" and not v.get("cd"):
            errores.append(f"{d}: verbo transitivo sin CD")
        for s in v.get("cd") or []:
            validar_sintagma(s, d, errores)
    comps = p.get("complementos", {})
    for k in set(comps) - COMPLEMENTOS:
        errores.append(f"piezas.json: el generador no usa el complemento «{k}»")
    if any(v.get("ci") for v in p.get("verbos", [])) and not comps.get("CI"):
        errores.append("piezas.json: hay verbos con CI pero ningún complemento CI")
    for k, lista in comps.items():
        for s in lista:
            validar_sintagma(s, f"piezas.json · {k}", errores)
    for a in p.get("atributos", []):
        if set(a.get("formas", {})) != {"ms", "fs", "mp", "fp"}:
            errores.append(f"piezas.json: atributo sin las 4 formas {a}")


def validar_verbos(b, errores):
    for i in repetidos(b.get("regulares", [])):
        errores.append(f"verbos.json: regular repetido {i}")
    for v in b.get("regulares", []):
        if v[-2:] not in ("ar", "er", "ir"):
            errores.append(f"verbos.json: «{v}» no termina en -ar, -er ni -ir")
    for v in b.get("irregulares", []):
        for t, formas in v.get("formas", {}).items():
            if len(formas) != 6:
                errores.append(f"verbos.json · {v['infinitivo']}: {t} no tiene 6 formas")


def main(argv):
    raiz = Path(argv[0]) if argv else RAIZ_POR_DEFECTO
    g = raiz / "gramatica"
    errores, avisos, resumen = [], [], []
    cat = json.loads((raiz / "catalogo.json").read_text(encoding="utf-8"))
    competencias = {c["id"] for a in cat["areas"] for b in a["bloques"] for c in b["competencias"]}

    familias_por_archivo = {}
    for nombre in ("frases.json", "frases_lote02b.json"):
        ruta = g / nombre
        if ruta.exists():
            banco = json.loads(ruta.read_text(encoding="utf-8"))
            familias_por_archivo[nombre] = validar_frases(nombre, banco, competencias, errores, avisos)
            resumen.append(f"{nombre}: {len(banco.get('familias', []))} familias, {len(banco.get('frases', []))} frases")

    if (g / "compatibilidad.json").exists():
        neutro = json.loads((g / "compatibilidad.json").read_text(encoding="utf-8"))
        validar_neutro(neutro, errores)
        resumen.append(f"compatibilidad.json: {len(neutro['sustantivos'])} sustantivos, {len(neutro['adjetivos'])} adjetivos, "
                       f"{len(neutro['verbos'])} verbos, {sum(len(v) for v in neutro['complementosCircunstanciales'].values())} CC")
    piezas = json.loads((g / "piezas.json").read_text(encoding="utf-8"))
    validar_piezas(piezas, errores)
    resumen.append(f"piezas.json: {len(piezas['sujetos'])} sujetos, {len(piezas['verbos'])} verbos, "
                   + ", ".join(f"{k} {len(v)}" for k, v in piezas["complementos"].items()) + f", {len(piezas['atributos'])} atributos")
    verbos = json.loads((g / "verbos.json").read_text(encoding="utf-8"))
    validar_verbos(verbos, errores)
    resumen.append(f"verbos.json: {len(verbos['regulares'])} regulares, {len(verbos['irregulares'])} irregulares")

    for ruta in sorted((raiz / "plantillas").glob("*.json")):
        for p in json.loads(ruta.read_text(encoding="utf-8")):
            if p.get("tipo") != "fraseHueco":
                continue
            pedidas = set((p.get("parametros") or {}).get("familias") or [])
            for nombre, existentes in familias_por_archivo.items():
                faltan = sorted(pedidas - existentes)
                if faltan:
                    avisos.append(f"plantilla {p['id']}: familias que no existen en {nombre}: {', '.join(faltan)}")

    print(f"Gramática: {g}")
    for r in resumen:
        print(f"  {r}")
    for a in avisos:
        print(f"AVISO: {a}")
    for e in errores:
        print(f"ERROR: {e}")
    print(f"Resultado: {len(errores)} errores, {len(avisos)} avisos")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
