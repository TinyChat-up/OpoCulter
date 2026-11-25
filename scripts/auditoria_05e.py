#!/usr/bin/env python3
"""Cifras de la auditoría de la Fase 05E (§1.2 y §1.4) a partir del volcado de Release.

Uso: python3 scripts/auditoria_05e.py <volcado.json>
El volcado lo genera el arnés de los generadores (estáticos aprobados y 20 variantes de cada
plantilla aprobada, con el recuento del catálogo). Imprime tablas en Markdown.
"""
import collections
import json
import pathlib
import random
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CONTENT = RAIZ / "Educulter/Content"

# Marcas de una explicación que da el porqué (regla, causa o definición), no solo la solución.
PORQUE = re.compile(r"porque|ya que|pues |significa|se (multiplica|divide|resta|suma|busca|lleva|sustituye|calcula|pasa|opera|escribe)|"
                    r"lleva tilde|no lleva|regla|concuerda|responde a|es (un|una|el|la) |son |cada |primero|equivale|=", re.I)


def main():
    volcado = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    catalogo = json.loads((CONTENT / "catalogo.json").read_text(encoding="utf-8"))
    equivale = {c["id"]: c.get("equivaleA", c["id"]) for a in catalogo["areas"] for b in a["bloques"] for c in b["competencias"]}
    mapa = [(b["id"], c["id"]) for a in catalogo["areas"] for b in a["bloques"] for c in b["competencias"] if "equivaleA" not in c]
    filas = volcado["filas"]
    teoria = {equivale.get(c, c) for c in volcado["teoria"]}
    # Peldaños y dificultades: de los estáticos y de las plantillas (su peldaño y dificultad declarados).
    pel, dif, n, pistas = collections.defaultdict(set), collections.defaultdict(set), collections.Counter(), collections.defaultdict(bool)
    for f in filas:
        c = equivale.get(f["competencia"], f["competencia"])
        if f["origen"] == "estatico":
            n[c] += 1
        pel[c].add(int(f["peldano"])); dif[c].add(int(f["dificultad"]))
        if int(f["peldano"]) <= 2 and int(f["pistas"]) > 0:
            pistas[c] = True
    plantillas = collections.Counter(equivale.get(p["competencia"], p["competencia"]) for p in volcado["plantillas"])
    estado = {}
    for _, c in mapa:
        if n[c] + plantillas[c] == 0:
            estado[c] = "vacía"
        elif len(pel[c]) == 5 and len(dif[c]) >= 3 and c in teoria:
            estado[c] = "completa"
        else:
            estado[c] = "parcial"
    print("## Cobertura por bloque\n\n| Bloque | Completas | Parciales | Vacías |\n|---|---|---|---|")
    tot = collections.Counter()
    for b in [b["id"] for a in catalogo["areas"] for b in a["bloques"]]:
        cs = [c for bb, c in mapa if bb == b]
        k = collections.Counter(estado[c] for c in cs)
        tot.update(k)
        print(f"| {b} | {k['completa']} | {k['parcial']} | {k['vacía']} |")
    print(f"| **Total** | **{tot['completa']}** | **{tot['parcial']}** | **{tot['vacía']}** |\n")
    print("## Detalle de las competencias con contenido\n\n| Competencia | Estáticos | Plantillas | Peldaños | Dificultades | Teoría | Pistas (1–2) | Estado |\n|---|---|---|---|---|---|---|---|")
    for _, c in mapa:
        if estado[c] == "vacía":
            continue
        print(f"| {c} | {n[c]} | {plantillas[c]} | {','.join(map(str, sorted(pel[c])))} | {','.join(map(str, sorted(dif[c])))} | "
              f"{'sí' if c in teoria else 'no'} | {'sí' if pistas[c] else 'no'} | {estado[c]} |")
    print("\nVacías:", ", ".join(c for _, c in mapa if estado[c] == "vacía"))
    print("\nCon contenido y sin tarjeta de teoría:", ", ".join(c for _, c in mapa if estado[c] != "vacía" and c not in teoria))

    # Enseñanza (§1.4): estáticos aprobados y 20 variantes de cada plantilla aprobada.
    def pct(lista, cond):
        return 100 * sum(1 for x in lista if cond(x)) / max(len(lista), 1)
    for nombre, lista in [("Estáticos", [f for f in filas if f["origen"] == "estatico"]), ("Generados (muestra)", [f for f in filas if f["origen"] == "generado"]), ("Todos", filas)]:
        p12 = [f for f in lista if int(f["peldano"]) <= 2]
        print(f"\n{nombre}: {len(lista)} ítems · explicación {pct(lista, lambda f: f['explicacion'].strip() != ''):.0f} % · "
              f"errores habituales {pct(lista, lambda f: int(f['errores']) > 0):.0f} % · pistas en peldaños 1–2 {pct(p12, lambda f: int(f['pistas']) > 0):.0f} % "
              f"({len(p12)}) · porqué (marcas) {pct(lista, lambda f: bool(PORQUE.search(f['explicacion']))):.0f} %")
    rng = random.Random(2026)
    muestra = rng.sample(filas, 20)
    print("\n## 20 ítems al azar (semilla 2026)\n")
    for f in muestra:
        print(f"- {f['id']} [{f['mecanica']}, p{f['peldano']}, d{f['dificultad']}, pistas {f['pistas']}, errores {f['errores']}] "
              f"{f['enunciado'][:90]} → {f['explicacion'][:160]}")
    print(f"\nRecuento del catálogo (Release): total {volcado['total']} (estáticos {volcado['estaticos']}, generados {volcado['generados']})")
    for b, k in sorted(volcado["porBloque"].items()):
        print(f"  {b}: {k}")


if __name__ == "__main__":
    main()
