#!/usr/bin/env python3
"""Palabras del léxico ambiguas sin contexto (Fase 05E, §4.1).

Una palabra es ambigua si otra acentuación (incluida la ausencia de tilde) da una forma válida
del español: término/termino/terminó, pasó/paso, está/esta…

- `Content/ambiguas.json`: lista revisada a mano de formas válidas que no están en el léxico,
  con su categoría (se escribe desde `REVISADAS`).
- Detección determinista (la misma que hace `Acentuacion.ambigua` en Swift): se generan las
  variantes de tilde de cada palabra (sin tilde y con tilde en cada vocal) y se buscan en el
  léxico y en las formas de `ambiguas.json`.
- `Content/pendiente/tildeContexto.json`: palabra, variantes válidas y categoría de cada una, para
  que la dirección redacte frases con contexto.

No se consideran las formas del voseo (cantá, comé): la app es de español de España.
"""
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CONTENT = RAIZ / "Educulter/Content"

PRET3 = "verbo: pretérito perfecto simple, 3.ª persona del singular"
PRES1 = "verbo: presente de indicativo, 1.ª persona del singular"
PRET1 = "verbo: pretérito perfecto simple, 1.ª persona del singular"
SUST = "sustantivo"
ADJ = "adjetivo"

# Palabra del léxico → {forma válida: categoría}. La categoría de la propia palabra va en "_".
REVISADAS = {
    "mamá": {"_": SUST, "mama": "sustantivo (glándula) / verbo mamar: presente, 3.ª persona del singular"},
    "papá": {"_": SUST, "papa": "sustantivo (patata; pontífice)"},
    "bebé": {"_": SUST, "bebe": "verbo beber: presente, 3.ª persona del singular"},
    "dominó": {"_": SUST, "domino": PRES1 + " (dominar)"},
    "inglés": {"_": "adjetivo / sustantivo", "ingles": "sustantivo (plural de ingle)"},
    "cortés": {"_": ADJ, "cortes": "sustantivo (plural de corte) / verbo cortar: presente de subjuntivo, 2.ª persona del singular"},
    "marqués": {"_": SUST, "marques": "verbo marcar: presente de subjuntivo, 2.ª persona del singular"},
    "compás": {"_": SUST, "compas": "sustantivo coloquial (plural de compa)"},
    "llegó": {"_": PRET3, "llego": PRES1},
    "cantó": {"_": PRET3, "canto": PRES1 + " / sustantivo"},
    "habló": {"_": PRET3, "hablo": PRES1},
    "miró": {"_": PRET3, "miro": PRES1},
    "jugó": {"_": PRET3, "jugo": SUST},
    "pasó": {"_": PRET3, "paso": PRES1 + " / sustantivo"},
    "dejó": {"_": PRET3, "dejo": PRES1 + " / sustantivo"},
    "terminó": {"_": PRET3, "termino": PRES1, "término": SUST},
    "estudió": {"_": PRET3, "estudio": PRES1 + " / sustantivo"},
    "cerró": {"_": PRET3, "cerro": SUST},
    "llamó": {"_": PRET3, "llamo": PRES1},
    "cantará": {"_": "verbo: futuro simple, 3.ª persona del singular",
                "cantara": "verbo: pretérito imperfecto de subjuntivo, 1.ª y 3.ª persona del singular",
                "cántara": "sustantivo"},
    "cantarán": {"_": "verbo: futuro simple, 3.ª persona del plural",
                 "cantaran": "verbo: pretérito imperfecto de subjuntivo, 3.ª persona del plural"},
    "será": {"_": "verbo ser: futuro simple, 3.ª persona del singular", "sera": "sustantivo (espuerta grande)"},
    "está": {"_": "verbo estar: presente, 3.ª persona del singular", "esta": "determinante / pronombre demostrativo"},
    "estás": {"_": "verbo estar: presente, 2.ª persona del singular", "estas": "determinante / pronombre demostrativo"},
    "esté": {"_": "verbo estar: presente de subjuntivo, 1.ª y 3.ª persona del singular", "este": "determinante / pronombre demostrativo / sustantivo (punto cardinal)"},
    "libro": {"_": SUST + " / " + PRES1 + " (librar)", "libró": PRET3 + " (librar)"},
    "mano": {"_": SUST, "manó": PRET3 + " (manar)"},
    "camino": {"_": SUST + " / " + PRES1 + " (caminar)", "caminó": PRET3 + " (caminar)"},
    "aire": {"_": SUST, "airé": PRET1 + " (airar)"},
    "abrigo": {"_": SUST + " / " + PRES1 + " (abrigar)", "abrigó": PRET3 + " (abrigar)"},
    "recreo": {"_": SUST + " / " + PRES1 + " (recrear)", "recreó": PRET3 + " (recrear)"},
    "primo": {"_": SUST + " / " + PRES1 + " (primar)", "primó": PRET3 + " (primar)"},
    "verso": {"_": SUST + " / " + PRES1 + " (versar)", "versó": PRET3 + " (versar)"},
    "sujeto": {"_": SUST + " / " + PRES1 + " (sujetar)", "sujetó": PRET3 + " (sujetar)"},
    "tilde": {"_": SUST + " / verbo tildar: presente de subjuntivo", "tildé": PRET1 + " (tildar)"},
    "entero": {"_": ADJ + " / " + PRES1 + " (enterar)", "enteró": PRET3 + " (enterar)"},
    "nombre": {"_": SUST + " / verbo nombrar: presente de subjuntivo", "nombré": PRET1 + " (nombrar)"},
    "segundo": {"_": "sustantivo / adjetivo ordinal", "segundó": PRET3 + " (segundar)"},
    "canto": {"_": SUST + " / " + PRES1 + " (cantar)", "cantó": PRET3 + " (cantar)"},
    "paseo": {"_": SUST + " / " + PRES1 + " (pasear)", "paseó": PRET3 + " (pasear)"},
    "deseo": {"_": SUST + " / " + PRES1 + " (desear)", "deseó": PRET3 + " (desear)"},
    "reino": {"_": SUST + " / " + PRES1 + " (reinar)", "reinó": PRET3 + " (reinar)"},
    "peine": {"_": SUST + " / verbo peinar: presente de subjuntivo", "peiné": PRET1 + " (peinar)"},
    "aceite": {"_": SUST + " / verbo aceitar: presente de subjuntivo", "aceité": PRET1 + " (aceitar)"},
    "revólver": {"_": SUST, "revolver": "verbo (infinitivo)"},
    "médico": {"_": SUST, "medico": PRES1 + " (medicar)", "medicó": PRET3 + " (medicar)"},
    "número": {"_": SUST, "numero": PRES1 + " (numerar)", "numeró": PRET3 + " (numerar)"},
    "último": {"_": ADJ, "ultimo": PRES1 + " (ultimar)", "ultimó": PRET3 + " (ultimar)"},
    "máquina": {"_": SUST, "maquina": "verbo maquinar: presente, 3.ª persona del singular"},
    "página": {"_": SUST, "pagina": "verbo paginar: presente, 3.ª persona del singular"},
    "público": {"_": "adjetivo / sustantivo", "publico": PRES1 + " (publicar)", "publicó": PRET3 + " (publicar)"},
    "sílaba": {"_": SUST, "silaba": "verbo silabar: presente, 3.ª persona del singular"},
    "órdenes": {"_": "sustantivo (plural)", "ordenes": "verbo ordenar: presente de subjuntivo, 2.ª persona del singular"},
    "azúcares": {"_": "sustantivo (plural)", "azucares": "verbo azucarar: presente de subjuntivo, 2.ª persona del singular"},
    "triángulo": {"_": SUST, "triangulo": PRES1 + " (triangular)"},
    "círculo": {"_": SUST, "circulo": PRES1 + " (circular)", "circuló": PRET3 + " (circular)"},
    "término": {"_": SUST, "termino": PRES1 + " (terminar)", "terminó": PRET3 + " (terminar)"},
    "sábana": {"_": "sustantivo (ropa de cama)", "sabana": "sustantivo (llanura)"},
    "práctico": {"_": ADJ, "practico": PRES1 + " (practicar)", "practicó": PRET3 + " (practicar)"},
    "líquido": {"_": "sustantivo / adjetivo", "liquido": PRES1 + " (liquidar)", "liquidó": PRET3 + " (liquidar)"},
    "artículo": {"_": SUST, "articulo": PRES1 + " (articular)", "articuló": PRET3 + " (articular)"},
    "río": {"_": SUST, "rio": "verbo reír: pretérito perfecto simple, 3.ª persona del singular"},
    "frío": {"_": "adjetivo / sustantivo", "frio": "verbo freír: pretérito perfecto simple, 3.ª persona del singular"},
    "tenía": {"_": "verbo tener: pretérito imperfecto, 1.ª y 3.ª persona del singular", "tenia": "sustantivo (gusano)"},
    "hacía": {"_": "verbo hacer: pretérito imperfecto, 1.ª y 3.ª persona del singular", "hacia": "preposición"},
    "sabía": {"_": "verbo saber: pretérito imperfecto, 1.ª y 3.ª persona del singular", "sabia": ADJ + " (femenino de sabio)"},
    "venía": {"_": "verbo venir: pretérito imperfecto, 1.ª y 3.ª persona del singular", "venia": "sustantivo (permiso)"},
    "sería": {"_": "verbo ser: condicional, 1.ª y 3.ª persona del singular", "seria": ADJ + " (femenino de serio)"},
    "continúa": {"_": "verbo continuar: presente, 3.ª persona del singular", "continua": ADJ + " (femenino de continuo)"},
    "comisaría": {"_": "sustantivo (oficina)", "comisaria": "sustantivo (mujer comisario)"},
}

VOCALES = "aeiou"
CON_TILDE = dict(zip("aeiou", "áéíóú"))
SIN_TILDE = {v: k for k, v in CON_TILDE.items()}


def sin_tilde(p: str) -> str:
    return "".join(SIN_TILDE.get(c, c) for c in p)


def variantes(p: str) -> set[str]:
    """Otras acentuaciones de la palabra: sin tilde y con tilde en cada vocal."""
    base = sin_tilde(p)
    v = {base} | {base[:i] + CON_TILDE[c] + base[i + 1:] for i, c in enumerate(base) if c in VOCALES}
    v.discard(p)
    return v


def main() -> None:
    lexico = [e["palabra"] for e in json.loads((CONTENT / "lexico/palabras.json").read_text(encoding="utf-8"))]
    conjunto = set(lexico)
    for palabra, formas in REVISADAS.items():
        assert palabra in conjunto, f"{palabra} no está en el léxico"
        for forma in formas:
            assert forma == "_" or forma in variantes(palabra), f"{forma} no es una variante de tilde de {palabra}"
    ambiguas = {
        "version": 1,
        "nota": "Formas válidas del español que solo se distinguen por la tilde de una palabra del léxico (Fase 05E, §4.1). "
                "Revisadas a mano; las formas del voseo no se consideran. La app las usa para sacar del léxico de los "
                "generadores de acentuación sin contexto las palabras ambiguas.",
        "palabras": [{"palabra": p, "categoria": f["_"],
                      "variantes": [{"forma": k, "categoria": v} for k, v in f.items() if k != "_"]}
                     for p, f in REVISADAS.items()],
    }
    (CONTENT / "ambiguas.json").write_text(json.dumps(ambiguas, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Detección determinista: léxico ∪ formas de ambiguas.json.
    formas_validas = conjunto | {v["forma"] for e in ambiguas["palabras"] for v in e["variantes"]}
    categorias = {e["palabra"]: e["categoria"] for e in ambiguas["palabras"]}
    for e in ambiguas["palabras"]:
        for v in e["variantes"]:
            categorias.setdefault(v["forma"], v["categoria"])
    detectadas = []
    for p in lexico:
        otras = sorted(variantes(p) & formas_validas)
        if otras:
            detectadas.append({
                "palabra": p,
                "categoria": categorias.get(p, "(sin categoría registrada)"),
                "variantes": [{"forma": o, "categoria": categorias.get(o, "(sin categoría registrada)")} for o in otras],
            })
    sin_cat = [d["palabra"] for d in detectadas if d["categoria"].startswith("(")] + \
              [v["forma"] for d in detectadas for v in d["variantes"] if v["categoria"].startswith("(")]
    assert not sin_cat, f"Faltan categorías: {sin_cat}"
    pendiente = {
        "version": 1,
        "nota": "Palabras del léxico que no se pueden preguntar sin contexto (Fase 05E, §4.1). Pendiente: la dirección "
                "redactará frases con contexto para cada una. Generado por scripts/ambiguas_tilde.py.",
        "palabras": detectadas,
    }
    (CONTENT / "pendiente/tildeContexto.json").write_text(json.dumps(pendiente, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(REVISADAS)} revisadas a mano; {len(detectadas)} palabras del léxico ambiguas de {len(lexico)}")


if __name__ == "__main__":
    main()
