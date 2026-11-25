#!/usr/bin/env python3
"""Valida la base literaria (Educulter/Content/literatura/literatura.json).

Solo biblioteca estándar. Uso:
    python3 scripts/validar_literatura.py [ruta/al/literatura.json]

Errores (salida con código 1):
  - JSON inválido, campos que faltan o con tipo o valor no permitido.
  - Identificadores repetidos (movimientos y autores).
  - Movimiento de un autor que no existe.
  - Nacimiento igual o posterior a la muerte; inicio de movimiento posterior a su fin.
  - Año de una obra anterior al nacimiento o posterior a muerte + 10.
  - `dominioPublico` incoherente con la regla: muerte <= 1945, o anónimo o
    antiguo sin fechas, implica true; muerte > 1945 o autor vivo, false.
  - `fragmentosPermitidos` incoherente: true solo si `dominioPublico` es true
    y el ámbito es espanola o hispanoamericana.
  - Textos con espacios dobles o con espacios al principio o al final.

Avisos (no hacen fallar):
  - Género de una obra que no figura en los géneros del autor.
"""

import json
import sys
from pathlib import Path

RUTA_POR_DEFECTO = Path(__file__).resolve().parent.parent / "Educulter" / "Content" / "literatura" / "literatura.json"

ANIO_LIMITE_DOMINIO_PUBLICO = 1945
MARGEN_POSTUMO = 10
AMBITOS = {"espanola", "hispanoamericana", "universal", "infantil"}
GENEROS = {"poesia", "narrativa", "teatro", "ensayo"}

CAMPOS_MOVIMIENTO = {"id": str, "nombre": str, "periodo": str, "inicio": int, "fin": (int, type(None)), "rasgos": list}
CAMPOS_AUTOR = {
    "id": str, "nombre": str, "nacimiento": (int, type(None)), "muerte": (int, type(None)),
    "aproximado": bool, "ambito": str, "pais": str, "movimiento": str, "generos": list,
    "obras": list, "rasgo": str, "dominioPublico": bool, "fragmentosPermitidos": bool,
}
AMBITOS_CON_FRAGMENTOS = {"espanola", "hispanoamericana"}
CAMPOS_OBRA = {"titulo": str, "anio": (int, type(None)), "genero": str}


def es_tipo(valor, tipos):
    # bool es subclase de int: no se acepta un booleano donde se espera un año.
    if isinstance(valor, bool) and bool not in (tipos if isinstance(tipos, tuple) else (tipos,)):
        return False
    return isinstance(valor, tipos)


def comprobar_campos(obj, campos, donde, errores):
    if not isinstance(obj, dict):
        errores.append(f"{donde}: no es un objeto")
        return False
    for clave, tipos in campos.items():
        if clave not in obj:
            errores.append(f"{donde}: falta «{clave}»")
        elif not es_tipo(obj[clave], tipos):
            errores.append(f"{donde}: «{clave}» tiene un tipo no válido ({obj[clave]!r})")
    for clave in obj:
        if clave not in campos:
            errores.append(f"{donde}: campo desconocido «{clave}»")
    return all(clave in obj and es_tipo(obj[clave], t) for clave, t in campos.items())


def textos(valor, ruta):
    """Recorre todas las cadenas del documento con su ruta."""
    if isinstance(valor, str):
        yield ruta, valor
    elif isinstance(valor, list):
        for i, v in enumerate(valor):
            yield from textos(v, f"{ruta}[{i}]")
    elif isinstance(valor, dict):
        for k, v in valor.items():
            yield from textos(v, f"{ruta}.{k}")


def anio(n):
    return f"{-n} a. C." if n < 0 else str(n)


def validar(doc):
    errores, avisos = [], []

    if not isinstance(doc, dict) or set(doc) != {"version", "movimientos", "autores"}:
        errores.append("raíz: se esperan exactamente las claves version, movimientos y autores")
        return errores, avisos, 0, 0
    if not es_tipo(doc["version"], int):
        errores.append("raíz: «version» debe ser un entero")
    movimientos, autores = doc["movimientos"], doc["autores"]
    if not isinstance(movimientos, list) or not isinstance(autores, list):
        errores.append("raíz: «movimientos» y «autores» deben ser listas")
        return errores, avisos, 0, 0

    # Movimientos
    ids_mov = {}
    for i, m in enumerate(movimientos):
        donde = f"movimientos[{i}]"
        if not comprobar_campos(m, CAMPOS_MOVIMIENTO, donde, errores):
            continue
        donde = f"movimiento {m['id']}"
        if m["id"] in ids_mov:
            errores.append(f"{donde}: id repetido")
        ids_mov[m["id"]] = m
        if len(m["rasgos"]) != 2 or not all(isinstance(r, str) and r for r in m["rasgos"]):
            errores.append(f"{donde}: «rasgos» debe tener exactamente 2 textos")
        if m["fin"] is not None and m["inicio"] >= m["fin"]:
            errores.append(f"{donde}: inicio {anio(m['inicio'])} no es anterior a fin {anio(m['fin'])}")

    # Autores
    ids_aut = set()
    for i, a in enumerate(autores):
        donde = f"autores[{i}]"
        if not comprobar_campos(a, CAMPOS_AUTOR, donde, errores):
            continue
        donde = f"autor {a['id']}"
        if a["id"] in ids_aut:
            errores.append(f"{donde}: id repetido")
        if a["id"] in ids_mov:
            errores.append(f"{donde}: el id coincide con el de un movimiento")
        ids_aut.add(a["id"])

        if a["movimiento"] not in ids_mov:
            errores.append(f"{donde}: el movimiento «{a['movimiento']}» no existe")
        if a["ambito"] not in AMBITOS:
            errores.append(f"{donde}: ámbito «{a['ambito']}» no permitido")
        if not a["generos"] or any(g not in GENEROS for g in a["generos"]):
            errores.append(f"{donde}: géneros no válidos {a['generos']}")
        if len(set(a["generos"])) != len(a["generos"]):
            errores.append(f"{donde}: géneros repetidos")
        if not a["obras"]:
            errores.append(f"{donde}: no tiene obras")

        nac, mue = a["nacimiento"], a["muerte"]
        if nac is not None and mue is not None and nac >= mue:
            errores.append(f"{donde}: nacimiento {anio(nac)} no es anterior a muerte {anio(mue)}")
        if nac is None and mue is not None:
            errores.append(f"{donde}: tiene muerte pero no nacimiento")

        # Regla de dominio público (España): fallecido en 1945 o antes, o anónimo/antiguo sin fechas.
        if mue is not None:
            esperado = mue <= ANIO_LIMITE_DOMINIO_PUBLICO
        else:
            esperado = nac is None  # sin fechas: anónimo o antiguo; con nacimiento y sin muerte: vivo
        if a["dominioPublico"] != esperado:
            motivo = (f"muerte en {anio(mue)}" if mue is not None
                      else "sin fechas (anónimo o antiguo)" if nac is None else "autor vivo")
            errores.append(f"{donde}: dominioPublico={str(a['dominioPublico']).lower()} pero la regla da "
                           f"{str(esperado).lower()} ({motivo})")

        # Fragmentos (versión 2): solo de dominio público y en lengua original española.
        # Los extranjeros de dominio público solo admiten traducción propia de la dirección.
        frag_esperado = a["dominioPublico"] and a["ambito"] in AMBITOS_CON_FRAGMENTOS
        if a["fragmentosPermitidos"] != frag_esperado:
            errores.append(f"{donde}: fragmentosPermitidos={str(a['fragmentosPermitidos']).lower()} pero la regla da "
                           f"{str(frag_esperado).lower()} (dominioPublico={str(a['dominioPublico']).lower()}, "
                           f"ámbito {a['ambito']})")

        for j, o in enumerate(a["obras"]):
            od = f"{donde}, obras[{j}]"
            if not comprobar_campos(o, CAMPOS_OBRA, od, errores):
                continue
            od = f"{donde}, «{o['titulo']}»"
            if o["genero"] not in GENEROS:
                errores.append(f"{od}: género «{o['genero']}» no permitido")
            elif o["genero"] not in a["generos"]:
                avisos.append(f"{od}: el género «{o['genero']}» no figura en los géneros del autor {a['generos']}")
            y = o["anio"]
            if y is None:
                continue
            if nac is not None and y < nac:
                errores.append(f"{od}: año {anio(y)} anterior al nacimiento ({anio(nac)})")
            if mue is not None and y > mue + MARGEN_POSTUMO:
                errores.append(f"{od}: año {anio(y)} posterior a muerte + {MARGEN_POSTUMO} ({anio(mue + MARGEN_POSTUMO)})")

    # Espacios en todos los textos
    for ruta, t in textos(doc, "raíz"):
        if "  " in t:
            errores.append(f"{ruta}: espacios dobles en «{t}»")
        if t != t.strip():
            errores.append(f"{ruta}: espacios al principio o al final en «{t}»")

    return errores, avisos, len(movimientos), len(autores)


def main():
    ruta = Path(sys.argv[1]) if len(sys.argv) > 1 else RUTA_POR_DEFECTO
    try:
        with open(ruta, encoding="utf-8") as f:
            doc = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR: no se puede leer {ruta}: {e}")
        return 1

    errores, avisos, n_mov, n_aut = validar(doc)
    print(f"Archivo: {ruta}")
    print(f"JSON válido · versión {doc.get('version')} · {n_mov} movimientos · {n_aut} autores")
    if isinstance(doc.get("autores"), list):
        autores = [a for a in doc["autores"] if isinstance(a, dict)]
        dp = sum(1 for a in autores if a.get("dominioPublico") is True)
        frag = sum(1 for a in autores if a.get("fragmentosPermitidos") is True)
        obras = sum(len(a.get("obras", [])) for a in autores)
        por_ambito = {}
        for a in autores:
            por_ambito[a.get("ambito")] = por_ambito.get(a.get("ambito"), 0) + 1
        print(f"Obras: {obras} · dominio público: {dp} de {len(autores)} autores · fragmentos permitidos: {frag}")
        print("Ámbitos: " + ", ".join(f"{k} {v}" for k, v in sorted(por_ambito.items(), key=lambda kv: str(kv[0]))))
    for a in avisos:
        print(f"AVISO: {a}")
    for e in errores:
        print(f"ERROR: {e}")
    print(f"Resultado: {len(errores)} errores, {len(avisos)} avisos")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
