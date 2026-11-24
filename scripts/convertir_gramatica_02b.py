#!/usr/bin/env python3
"""Lote 02b (parte 1): convierte el formato neutro de la dirección al esquema de Swift.

Uso (desde la raíz del repositorio):
    python3 scripts/convertir_gramatica_02b.py <anexo1_frases.json> <anexo2_piezas.json>

Escribe en Educulter/Content/gramatica/:
  - piezas.json        PiezasGramatica (sujetos, verbos con CD/CI, complementos, atributos)
  - verbos.json        BancoVerbos (regulares; irregulares = participios irregulares)
  - compatibilidad.json  el ANEXO 2 completo en formato neutro (etiquetas, admiteCI,
                       participioIrregular, CC por tipo…), que el esquema no admite entero
  - frases_lote02b.json  BancoFrases convertido, SIN `dificultad` ni `uso` (el formato neutro
                       no los trae y no se inventan). No lo lee la app: frases.json sigue con
                       los datos de prueba hasta que la dirección aporte esos campos.

Reglas de conversión (solo se deduce lo gramatical, nunca contenido):
  - Sujetos: sustantivos con la etiqueta `persona` (todos los verbos la admiten como sujeto),
    en singular y en plural, con artículo determinado (el/la/los/las). Los animales no se usan
    como sujeto porque el generador no comprueba qué verbo admite qué sujeto.
  - CD de cada verbo transitivo: sustantivos que comparten etiqueta con `objeto`. Cosas:
    artículo determinado («la manzana»). Personas y animales: «a» + posesivo («a su vecino»),
    para evitar la contracción «al», que no encaja en las clases de palabra del generador.
  - CI: «a» + posesivo + sustantivo de persona («a su abuela»); `ci` = admiteCI.
  - Complementos: CCL, CCT y CCM con sus clases de palabra. Se excluyen de piezas.json
    (siguen en compatibilidad.json) los que no tienen una clase de palabra inequívoca:
    «junto al río» (locución y contracción) y «a las cinco» (numeral). CCC no lo usa el
    generador. Restricción de tiempo verbal como en los datos de prueba (D-066): «ayer» →
    pretérito perfecto simple; «todos los días» → presente o imperfecto.
  - Atributos: los 17 adjetivos con sus 4 formas (no hay verbos copulativos en el lote, así
    que el generador todavía no los usa).
"""

import json
import sys
from pathlib import Path

DESTINO = Path("Educulter/Content/gramatica")
PREPOSICIONES = {"a", "en", "por", "con", "para", "de"}
DETERMINANTES = {"el", "la", "los", "las", "todos", "su", "sus"}
ADVERBIOS = {"ayer", "deprisa", "tranquilamente", "despacio", "mañana"}
CC_EXCLUIDOS = {"junto al río", "a las cinco"}
TIEMPO_CCT = {
    "ayer": ["Pretérito perfecto simple"],
    "todos los días": ["Presente", "Pretérito imperfecto"],
}
ANIMADOS = {"persona", "animal"}


def articulo(genero, numero):
    return {("m", "s"): "el", ("f", "s"): "la", ("m", "p"): "los", ("f", "p"): "las"}[(genero, numero)]


def sintagma_nominal(s, numero="s"):
    texto = s["lema"] if numero == "s" else s["plural"]
    return {"tokens": [[articulo(s["genero"], numero), "det"], [texto, "sust"]], "genero": s["genero"], "numero": numero}


def sintagma_animado(s):
    return {"tokens": [["a", "prep"], ["su", "det"], [s["lema"], "sust"]], "genero": s["genero"], "numero": "s"}


def clase(palabra):
    if palabra in PREPOSICIONES:
        return "prep"
    if palabra in DETERMINANTES:
        return "det"
    if palabra in ADVERBIOS:
        return "adv"
    return "sust"


def complemento(texto, tipo):
    s = {"tokens": [[p, clase(p)] for p in texto.split()]}
    if tipo == "CCT" and texto in TIEMPO_CCT:
        s["tiempo"] = TIEMPO_CCT[texto]
    return s


def dump(nombre, obj):
    (DESTINO / nombre).write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main(ruta_frases, ruta_piezas):
    frases = json.loads(Path(ruta_frases).read_text(encoding="utf-8"))
    neutro = json.loads(Path(ruta_piezas).read_text(encoding="utf-8"))
    sust = neutro["sustantivos"]

    personas = [s for s in sust if "persona" in s["etiquetas"]]
    sujetos = [sintagma_nominal(s, n) for n in ("s", "p") for s in personas]

    verbos = []
    for v in neutro["verbos"]:
        pieza = {"infinitivo": v["infinitivo"], "regimen": v["regimen"]}
        if v["regimen"] == "transitivo":
            objeto = set(v["objeto"] or [])
            cd = []
            for s in sust:
                comunes = objeto & set(s["etiquetas"])
                if comunes:
                    cd.append(sintagma_animado(s) if comunes <= ANIMADOS else sintagma_nominal(s))
            pieza["cd"] = cd
        if v["admiteCI"]:
            pieza["ci"] = True
        verbos.append(pieza)

    complementos = {"CI": [sintagma_animado(s) for s in personas]}
    for tipo in ("CCL", "CCT", "CCM"):
        complementos[tipo] = [complemento(t, tipo) for t in neutro["complementosCircunstanciales"][tipo] if t not in CC_EXCLUIDOS]

    atributos = [{"formas": {k: a[k] for k in ("ms", "fs", "mp", "fp")}} for a in neutro["adjetivos"]]
    dump("piezas.json", {"sujetos": sujetos, "verbos": verbos, "complementos": complementos, "atributos": atributos})

    irregulares = [{"infinitivo": v["infinitivo"], "participio": v["participioIrregular"], "formas": {}}
                   for v in neutro["verbos"] if v["participioIrregular"]]
    dump("verbos.json", {"regulares": [v["infinitivo"] for v in neutro["verbos"]], "irregulares": irregulares})

    dump("compatibilidad.json", {
        "version": 1,
        "origen": "Lote 02b (parte 1), formato neutro de la dirección. Pendiente de conectar al generador oracionSimple.",
        **neutro,
    })

    familias, vistas = [], {}
    for f in frases:
        if f["familia"] not in vistas:
            vistas[f["familia"]] = f["formas"]
            familias.append({"id": f["familia"], "formas": [{"texto": t} for t in f["formas"]]})
    dump("frases_lote02b.json", {
        "pendiente": "Faltan `dificultad` (cada frase) y `uso` (cada forma), obligatorios en FraseHueco y FamiliaFormas.",
        "familias": familias,
        "frases": [{"id": f["id"], "familia": f["familia"], "competencia": f["competencia"],
                    "texto": f["frase"], "correcta": f["correcta"]} for f in frases],
    })
    print(f"piezas.json: {len(sujetos)} sujetos, {len(verbos)} verbos, "
          + ", ".join(f"{k} {len(v)}" for k, v in complementos.items()) + f", {len(atributos)} atributos")
    print(f"verbos.json: {len(neutro['verbos'])} regulares, {len(irregulares)} con participio irregular")
    print(f"frases_lote02b.json: {len(familias)} familias, {len(frases)} frases")


if __name__ == "__main__":
    main(*sys.argv[1:3])
