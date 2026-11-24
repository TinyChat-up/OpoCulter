#!/usr/bin/env python3
"""Valida el contenido de Educulter/Content sin Swift (solo biblioteca estándar).

Reproduce las reglas principales de ValidadorContenido.swift (CONTENIDOS.md §2) para
poder revisar lotes sin Mac. No sustituye al test de Swift, que sigue siendo la
referencia: lo que este script no cubre se indica abajo.

Uso:
    python3 scripts/validar_items.py [--anio AAAA] [ruta/a/Content]

Qué comprueba:
  - catalogo.json: ids de área, bloque y competencia con formato y sin repetir.
  - items/*.json y pendiente/LEN.*.json (ítems):
      · id <competencia>.NNNN, único en todo el contenido; la competencia existe;
      · peldaño 1–5, dificultad 1–6, textos obligatorios, versión >= 1;
      · explicación de 1 a 280 caracteres; pistas solo en los peldaños 1–2 (D-033);
      · errores habituales coherentes con la mecánica; referencias de examen AAAA-L9/AAAA-M9;
      · payload coherente con la mecánica (§2.4);
      · procedencia (§2.7) y validación (aprobado con revisor y fecha);
      · textoRef (solo pendiente/): apunta a un texto de pendiente/textos.json.
  - teoria/*.json: id <competencia>.TNN único, competencia existente, bloques texto/regla
    con 40 palabras o menos, procedencia y validación.
  - pendiente/textos.json: ids únicos, campos obligatorios, procedencia y validación.
  - simulacros/*.json: id SIM.NN y procedencia del texto base.
No comprueba: plantillas/ (necesitan los generadores de Swift), léxico y gramática.
"""

import json
import re
import sys
from datetime import date
from pathlib import Path

RAIZ_POR_DEFECTO = Path(__file__).resolve().parent.parent / "Educulter" / "Content"
MAX_EXPLICACION = 280
MAX_PALABRAS_TEORIA = 40
ANIOS_DOMINIO_PUBLICO = 80
LICENCIAS = {"propia", "dominio publico"}
MECANICAS = {"eleccion", "verdaderoFalso", "clasificar", "ordenar", "emparejar", "marcarTexto",
             "segmentar", "ruedas", "construir", "numerico", "colocarTilde", "fraccionBarras"}
TIPOS_BLOQUE = {"texto", "regla", "ejemplo", "esquema"}
ESTADOS = {"borrador", "revisado", "aprobado"}
VOCALES = set("aeiou")


def coincide(texto, patron):
    return isinstance(texto, str) and re.fullmatch(patron, texto) is not None


def ids_unicos(lista, nombre):
    ids = [x.get("id") if isinstance(x, dict) else x for x in lista]
    m = []
    if any(not i for i in ids):
        m.append(f"hay ids vacíos en {nombre}")
    if len(set(ids)) != len(ids):
        m.append(f"hay ids repetidos en {nombre}")
    return m


# ---------------------------------------------------------------- payloads

def v_eleccion(p):
    m = ids_unicos(p["opciones"], "opciones")
    if not 2 <= len(p["opciones"]) <= 4:
        m.append(f"eleccion necesita 2–4 opciones (tiene {len(p['opciones'])})")
    if p["correcta"] not in {o["id"] for o in p["opciones"]}:
        m.append(f"la opción correcta «{p['correcta']}» no existe")
    return m


def v_verdadero_falso(p):
    m = [] if p.get("afirmacion") else ["afirmación vacía"]
    if not isinstance(p.get("esVerdadera"), bool):
        m.append("esVerdadera debe ser true o false")
    return m


def v_clasificar(p):
    m = ids_unicos(p["categorias"], "categorías") + ids_unicos(p["fichas"], "fichas")
    if not 2 <= len(p["categorias"]) <= 4:
        m.append(f"clasificar necesita 2–4 categorías (tiene {len(p['categorias'])})")
    if not p["fichas"]:
        m.append("clasificar no tiene fichas")
    cats = {c["id"] for c in p["categorias"]}
    for f in p["fichas"]:
        if f["categoria"] not in cats:
            m.append(f"la ficha «{f['id']}» tiene una categoría inexistente «{f['categoria']}»")
    return m


def v_ordenar(p):
    m = ids_unicos(p["fichas"], "fichas")
    if len(p["fichas"]) < 2:
        m.append("ordenar necesita al menos 2 fichas")
    ids = [f["id"] for f in p["fichas"]]
    if len(p["ordenCorrecto"]) != len(ids) or set(p["ordenCorrecto"]) != set(ids):
        m.append("ordenCorrecto no es una permutación de las fichas")
    return m


def v_emparejar(p):
    m = ids_unicos(p["izquierda"], "izquierda") + ids_unicos(p["derecha"], "derecha")
    izq, der = {x["id"] for x in p["izquierda"]}, {x["id"] for x in p["derecha"]}
    if any(len(par) != 2 for par in p["pares"]):
        return m + ["cada par debe tener exactamente 2 ids"]
    for a, b in p["pares"]:
        if a not in izq:
            m.append(f"el par usa «{a}», que no está a la izquierda")
        if b not in der:
            m.append(f"el par usa «{b}», que no está a la derecha")
    ui, ud = [a for a, _ in p["pares"]], [b for _, b in p["pares"]]
    if set(ui) != izq or len(ui) != len(izq) or set(ud) != der or len(ud) != len(der):
        m.append("los pares deben cubrir todos los elementos de cada lado exactamente una vez")
    return m


def v_marcar_texto(p):
    m = ids_unicos(p["tokens"], "tokens")
    if p.get("unidad") not in ("palabra", "silaba"):
        m.append(f"unidad «{p.get('unidad')}» no válida (palabra | silaba)")
    tokens = {t["id"] for t in p["tokens"]}
    if not p["correctos"]:
        m.append("marcarTexto no tiene tokens correctos")
    for i in p["correctos"]:
        if i not in tokens:
            m.append(f"el token correcto «{i}» no existe")
    if len(set(p["correctos"])) != len(p["correctos"]):
        m.append("tokens correctos repetidos")
    return m


def v_segmentar(p):
    m = ids_unicos(p["tokens"], "tokens") + ids_unicos(p["etiquetas"], "etiquetas") + ids_unicos(p["segmentos"], "segmentos")
    if not p["segmentos"]:
        m.append("segmentar no tiene segmentos")
    pos = {}
    for i, t in enumerate(p["tokens"]):
        pos.setdefault(t["id"], i)
    etiquetas = {e["id"] for e in p["etiquetas"]}
    por_id = {}
    for s in p["segmentos"]:
        por_id.setdefault(s["id"], s)
    rango = {}
    for s in p["segmentos"]:
        if s["etiqueta"] not in etiquetas:
            m.append(f"el segmento «{s['id']}» usa una etiqueta inexistente «{s['etiqueta']}»")
        if s["desde"] not in pos or s["hasta"] not in pos:
            m.append(f"el segmento «{s['id']}» usa tokens inexistentes")
            continue
        a, b = pos[s["desde"]], pos[s["hasta"]]
        if a > b:
            m.append(f"el segmento «{s['id']}» empieza después de terminar")
        else:
            rango[s["id"]] = (a, b)
    for s in p["segmentos"]:
        padre = s.get("padre")
        if padre is None:
            continue
        if padre not in por_id or padre == s["id"]:
            m.append(f"el segmento «{s['id']}» tiene un padre inexistente «{padre}»")
            continue
        visitados, actual = {s["id"]}, padre
        while actual is not None:
            if actual in visitados:
                m.append(f"el segmento «{s['id']}» forma un ciclo de padres")
                break
            visitados.add(actual)
            actual = por_id.get(actual, {}).get("padre")
        r, rp = rango.get(s["id"]), rango.get(padre)
        if r and rp and not (rp[0] <= r[0] and r[1] <= rp[1]):
            m.append(f"el segmento «{s['id']}» no está dentro de su padre «{padre}»")
    grupos = {}
    for s in p["segmentos"]:
        grupos.setdefault(s.get("padre") or "", []).append(s)
    for hermanos in grupos.values():
        ords = sorted(((s["id"], rango[s["id"]]) for s in hermanos if s["id"] in rango), key=lambda x: x[1][0])
        for (xi, xr), (yi, yr) in zip(ords, ords[1:]):
            if xr[0] <= yr[1] and yr[0] <= xr[1]:
                m.append(f"los segmentos «{xi}» y «{yi}» se solapan sin estar anidados con «padre»")
    return m


def v_ruedas(p):
    m = ids_unicos(p["ruedas"], "ruedas")
    if not 1 <= len(p["ruedas"]) <= 5:
        m.append(f"ruedas necesita 1–5 selectores (tiene {len(p['ruedas'])})")
    for r in p["ruedas"]:
        if len(r["opciones"]) < 2:
            m.append(f"la rueda «{r['id']}» necesita al menos 2 opciones")
        if len(set(r["opciones"])) != len(r["opciones"]):
            m.append(f"la rueda «{r['id']}» tiene opciones repetidas")
        if r["correcta"] not in r["opciones"]:
            m.append(f"la rueda «{r['id']}» no incluye su opción correcta «{r['correcta']}»")
    return m


def v_construir(p):
    m = ids_unicos(p["huecos"], "huecos") + ids_unicos(p["piezas"], "piezas")
    piezas = {x["id"] for x in p["piezas"]}
    for h in p["huecos"]:
        if h["correcta"] not in piezas:
            m.append(f"el hueco «{h['id']}» apunta a una pieza inexistente «{h['correcta']}»")
    en_plantilla = re.findall(r"\{([^{}]+)\}", p["plantilla"])
    ids = [h["id"] for h in p["huecos"]]
    if set(en_plantilla) != set(ids) or len(en_plantilla) != len(ids):
        m.append("los huecos de la plantilla ({…}) no coinciden con la lista de huecos")
    if not p["huecos"]:
        m.append("construir no tiene huecos")
    return m


def interpretar_numero(texto):
    """Devuelve (formato, irreducible) o None, como Racional.interpretar."""
    t = texto.strip()
    if re.fullmatch(r"-?\d+/\d+", t):
        n, d = (int(x) for x in t.split("/"))
        if d == 0:
            return None
        a, b = abs(n), d
        while b:
            a, b = b, a % b
        return ("fraccion", max(a, 1) == 1)
    if re.fullmatch(r"-?\d+,\d{1,9}", t):
        return ("decimal", True)
    if re.fullmatch(r"-?\d+", t):
        return ("entero", True)
    return None


def v_numerico(p):
    r = interpretar_numero(str(p.get("respuesta", "")))
    if r is None:
        return [f"la respuesta numérica «{p.get('respuesta')}» no se puede interpretar (usa coma decimal o a/b)"]
    m = []
    formato, irreducible = r
    if not (formato == p["formato"] or (p["formato"] == "decimal" and formato == "entero")):
        m.append(f"la respuesta «{p['respuesta']}» no tiene el formato «{p['formato']}»")
    if p["formato"] == "fraccion" and p.get("exigeIrreducible") is True and not irreducible:
        m.append(f"la respuesta «{p['respuesta']}» no es una fracción irreducible")
    t = p.get("tolerancia")
    if t is not None and (not isinstance(t, (int, float)) or t < 0):
        m.append("tolerancia no válida")
    return m


def v_colocar_tilde(p):
    m, pal = [], p["palabra"]
    if not pal:
        m.append("palabra vacía")
    if pal != pal.lower():
        m.append(f"la palabra «{pal}» debe ir en minúsculas")
    if any(c in "áéíóúÁÉÍÓÚ" for c in pal):
        m.append(f"la palabra «{pal}» no debe llevar tildes")
    if not all(c.isalpha() for c in pal):
        m.append(f"la palabra «{pal}» solo puede tener letras")
    i = p.get("indiceTilde")
    if i is not None:
        if not 0 <= i < len(pal):
            m.append(f"indiceTilde {i} fuera de la palabra")
        elif pal[i] not in VOCALES:
            m.append(f"indiceTilde {i} no apunta a una vocal (a, e, i, o, u)")
    return m


def v_fraccion_barras(p):
    mt = re.fullmatch(r"(\d+)/(\d+)", str(p.get("objetivo", "")))
    if not mt:
        return [f"el objetivo «{p.get('objetivo')}» no tiene la forma n/d"]
    n, d = int(mt[1]), int(mt[2])
    m = []
    if not 0 < n < d:
        m.append(f"el objetivo «{p['objetivo']}» no es una fracción propia")
    if not 2 <= d <= 12:
        m.append("el denominador del objetivo debe estar entre 2 y 12")
    eq, partes, perm = p.get("aceptarEquivalentes", False), p.get("partes"), p.get("particionesPermitidas")
    if p["modo"] == "colorear":
        if partes is not None:
            if not 2 <= partes <= 12:
                m.append("partes debe estar entre 2 y 12")
            if partes * n % d:
                m.append(f"con {partes} partes no se puede colorear exactamente {p['objetivo']}")
            if not eq and partes != d:
                m.append("sin aceptar equivalentes, partes debe ser el denominador del objetivo")
        else:
            m.append("en el modo colorear, partes es obligatorio")
        if perm is not None:
            m.append("particionesPermitidas solo es válido en dividirYColorear")
    elif p["modo"] == "dividirYColorear":
        if partes is not None:
            m.append("en el modo dividirYColorear, partes debe ser null")
        if perm is not None:
            if not perm:
                m.append("particionesPermitidas está vacío")
            for k in perm:
                if not 2 <= k <= 12 or k * n % d:
                    m.append(f"la partición {k} no permite representar {p['objetivo']}")
            if not eq and perm != [d]:
                m.append(f"sin aceptar equivalentes, la única partición válida es {d}")
    else:
        m.append(f"modo «{p['modo']}» no válido")
    return m


VALIDADORES = {
    "eleccion": v_eleccion, "verdaderoFalso": v_verdadero_falso, "clasificar": v_clasificar,
    "ordenar": v_ordenar, "emparejar": v_emparejar, "marcarTexto": v_marcar_texto,
    "segmentar": v_segmentar, "ruedas": v_ruedas, "construir": v_construir,
    "numerico": v_numerico, "colocarTilde": v_colocar_tilde, "fraccionBarras": v_fraccion_barras,
}


def validar_payload(mecanica, payload):
    try:
        return VALIDADORES[mecanica](payload)
    except (KeyError, TypeError, AttributeError) as e:
        return [f"payload de {mecanica} mal formado ({type(e).__name__}: {e})"]


# ---------------------------------------------------------------- metadatos

def validar_procedencia(p, anio_actual):
    if not isinstance(p, dict):
        return ["falta la procedencia"]
    m = []
    if p.get("licencia") not in LICENCIAS:
        m.append(f"licencia «{p.get('licencia')}» no válida (propia | dominio publico)")
    tipo = p.get("tipo")
    if tipo == "original":
        if p.get("licencia") != "propia":
            m.append("el contenido original debe tener licencia «propia»")
    elif tipo == "dominioPublico":
        if not p.get("autorTexto"):
            m.append("dominio público sin autorTexto")
        if not p.get("fuente"):
            m.append("dominio público sin fuente")
        if p.get("licencia") != "dominio publico":
            m.append("el dominio público debe tener licencia «dominio publico»")
        anio = p.get("anioMuerteAutor")
        if not isinstance(anio, int):
            m.append("dominio público sin anioMuerteAutor")
        elif anio_actual - anio <= ANIOS_DOMINIO_PUBLICO:
            m.append(f"el autor murió en {anio}: no han pasado más de {ANIOS_DOMINIO_PUBLICO} años")
    else:
        m.append(f"tipo de procedencia «{tipo}» no válido (original | dominioPublico)")
    return m


def validar_validacion(v):
    if not isinstance(v, dict) or v.get("estado") not in ESTADOS:
        return ["validación ausente o con estado no válido"]
    if v["estado"] != "aprobado":
        return []
    m = []
    if not v.get("revisor"):
        m.append("aprobado sin revisor")
    if not coincide(v.get("fecha") or "", r"\d{4}-\d{2}-\d{2}"):
        m.append("aprobado sin fecha AAAA-MM-DD")
    return m


# ---------------------------------------------------------------- elementos

def validar_item(it, competencias, anio, textos=None):
    m = []
    comp = it.get("competencia", "")
    if not coincide(it.get("id"), re.escape(comp) + r"\.[0-9]{4}"):
        m.append("el id debe tener el formato <competencia>.NNNN y empezar por su competencia")
    if comp not in competencias:
        m.append(f"la competencia {comp} no existe en el catálogo")
    if it.get("peldano") not in range(1, 6):
        m.append(f"peldaño {it.get('peldano')} fuera de rango (1–5)")
    if it.get("dificultad") not in range(1, 7):
        m.append(f"dificultad {it.get('dificultad')} fuera de rango (1–6)")
    for campo in ("objetivo", "enunciado", "explicacion"):
        if not it.get(campo):
            m.append(f"{campo} vacío")
    exp = it.get("explicacion") or ""
    if len(exp) > MAX_EXPLICACION:
        m.append(f"la explicación tiene {len(exp)} caracteres (máximo {MAX_EXPLICACION})")
    if not isinstance(it.get("version"), int) or it["version"] < 1:
        m.append("la versión debe ser 1 o mayor")
    pistas = it.get("pistas") or []
    if pistas and isinstance(it.get("peldano"), int) and it["peldano"] >= 3:
        m.append("los ítems de peldaño 3 o superior no pueden tener pistas (D-033)")
    mec = it.get("mecanica")
    if mec not in MECANICAS:
        m.append(f"mecánica «{mec}» desconocida")
    errores = it.get("erroresHabituales") or []
    for e in errores:
        if not e.get("respuesta") or not e.get("feedback"):
            m.append("error habitual con respuesta o feedback vacíos")
    p = it.get("payload") or {}
    if mec == "eleccion" and isinstance(p.get("opciones"), list):
        ops = {o.get("id") for o in p["opciones"]}
        for e in errores:
            r = e.get("respuesta")
            if r and r not in ops:
                m.append(f"el error habitual «{r}» no es una opción")
            elif r and r == p.get("correcta"):
                m.append(f"el error habitual «{r}» es la opción correcta")
    if mec == "colocarTilde":
        for e in errores:
            if e.get("respuesta") not in ("sinTilde", "conTilde", "posicion"):
                m.append(f"el error habitual «{e.get('respuesta')}» no es sinTilde, conTilde ni posicion")
    if mec == "fraccionBarras":
        for e in errores:
            if e.get("respuesta") not in ("partes", "coloreadas"):
                m.append(f"el error habitual «{e.get('respuesta')}» no es partes ni coloreadas")
    for ex in (it.get("referencia") or {}).get("examenes") or []:
        if not coincide(ex, r"[0-9]{4}-[LM][0-9]{1,2}"):
            m.append(f"referencia de examen «{ex}» no válida (formato AAAA-L9 o AAAA-M9)")
    if mec in MECANICAS:
        m += validar_payload(mec, p)
    m += validar_procedencia(it.get("procedencia"), anio)
    m += validar_validacion(it.get("validacion"))
    if "textoRef" in it:
        if textos is None:
            m.append("textoRef solo se admite en pendiente/ (el motor aún no lo soporta)")
        elif it["textoRef"] not in textos:
            m.append(f"textoRef «{it['textoRef']}» no existe en pendiente/textos.json")
    return m


def contar_palabras(texto):
    return len(texto.split())


def validar_tarjeta(t, competencias, anio):
    m = []
    comp = t.get("competencia", "")
    if not coincide(t.get("id"), re.escape(comp) + r"\.T[0-9]{2}"):
        m.append("el id debe tener el formato <competencia>.TNN")
    if comp not in competencias:
        m.append(f"la competencia {comp} no existe en el catálogo")
    if not t.get("titulo"):
        m.append("título vacío")
    bloques = t.get("bloques") or []
    if not bloques:
        m.append("la tarjeta no tiene bloques")
    for i, b in enumerate(bloques, 1):
        if b.get("tipo") not in TIPOS_BLOQUE:
            m.append(f"bloque {i}: tipo «{b.get('tipo')}» no válido")
        if not b.get("contenido"):
            m.append(f"bloque {i} vacío")
        elif b.get("tipo") in ("texto", "regla"):
            n = contar_palabras(b["contenido"])
            if n > MAX_PALABRAS_TEORIA:
                m.append(f"el bloque {i} ({b['tipo']}) tiene {n} palabras (máximo {MAX_PALABRAS_TEORIA})")
    m += validar_procedencia(t.get("procedencia"), anio)
    m += validar_validacion(t.get("validacion"))
    return m


def validar_texto_base(t, anio):
    m = []
    if not coincide(t.get("id"), r"TXT\.[A-Z0-9]+\.[A-Z0-9]+"):
        m.append("el id debe tener el formato TXT.XXX.YYY")
    for campo in ("titulo", "tipo", "texto"):
        if not t.get(campo):
            m.append(f"{campo} vacío")
    for campo in ("autor", "obra"):
        if campo not in t:
            m.append(f"falta «{campo}» (puede ser null)")
    proc = t.get("procedencia") or {}
    m += validar_procedencia(proc, anio)
    if proc.get("tipo") == "dominioPublico" and t.get("autor") != proc.get("autorTexto"):
        m.append("el autor no coincide con procedencia.autorTexto")
    m += validar_validacion(t.get("validacion"))
    return m


def validar_catalogo(cat):
    m, vistos, competencias = [], set(), set()

    def registrar(i):
        if i in vistos:
            m.append(f"{i}: id duplicado en el catálogo")
        vistos.add(i)

    if not isinstance(cat.get("version"), int) or cat["version"] < 1:
        m.append("catalogo: la versión debe ser 1 o mayor")
    for area in cat.get("areas", []):
        registrar(area["id"])
        if not coincide(area["id"], r"[A-Z]{3}"):
            m.append(f"{area['id']}: id de área no válido")
        for bloque in area.get("bloques", []):
            registrar(bloque["id"])
            if not coincide(bloque["id"], re.escape(area["id"]) + r"\.[A-Z]{3}"):
                m.append(f"{bloque['id']}: id de bloque no válido")
            if bloque.get("prioridad") not in (1, 2, 3):
                m.append(f"{bloque['id']}: prioridad fuera de rango (1–3)")
            for c in bloque.get("competencias", []):
                registrar(c["id"])
                if not coincide(c["id"], re.escape(bloque["id"]) + r"\.[A-Z0-9]{2,16}"):
                    m.append(f"{c['id']}: id de competencia no válido")
                if not c.get("nombre"):
                    m.append(f"{c['id']}: nombre vacío")
                competencias.add(c["id"])
    return m, competencias


# ---------------------------------------------------------------- principal

def cargar(ruta, errores):
    try:
        return json.loads(ruta.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        errores.append(f"{ruta.name}: JSON no válido ({e})")
        return None


def main(argv):
    anio = date.today().year
    args = list(argv)
    if "--anio" in args:
        i = args.index("--anio")
        anio = int(args[i + 1])
        del args[i:i + 2]
    raiz = Path(args[0]) if args else RAIZ_POR_DEFECTO
    errores, resumen = [], []

    cat = cargar(raiz / "catalogo.json", errores)
    if cat is None:
        print("\n".join(f"ERROR: {e}" for e in errores))
        return 1
    errores_cat, competencias = validar_catalogo(cat)
    errores += [f"catalogo.json · {e}" for e in errores_cat]
    resumen.append(f"catalogo.json: {len(competencias)} competencias")

    textos = {}
    ruta_textos = raiz / "pendiente" / "textos.json"
    if ruta_textos.exists():
        lista = cargar(ruta_textos, errores) or []
        for t in lista:
            if t.get("id") in textos:
                errores.append(f"pendiente/textos.json · {t.get('id')}: id de texto duplicado")
            textos[t.get("id")] = t
            errores += [f"pendiente/textos.json · {t.get('id')}: {e}" for e in validar_texto_base(t, anio)]
        resumen.append(f"pendiente/textos.json: {len(lista)} textos")

    ids_items, usados = set(), set()
    estados = {}
    archivos_items = [(p, None) for p in sorted((raiz / "items").glob("*.json"))]
    archivos_items += [(p, textos) for p in sorted((raiz / "pendiente").glob("*.json")) if p.name != "textos.json"]
    for ruta, refs in archivos_items:
        nombre = f"{ruta.parent.name}/{ruta.name}"
        lista = cargar(ruta, errores) or []
        for it in lista:
            iid = it.get("id")
            if iid in ids_items:
                errores.append(f"{nombre} · {iid}: id de ítem duplicado")
            ids_items.add(iid)
            estado = (it.get("validacion") or {}).get("estado")
            estados[estado] = estados.get(estado, 0) + 1
            if "textoRef" in it:
                usados.add(it["textoRef"])
            errores += [f"{nombre} · {iid}: {e}" for e in validar_item(it, competencias, anio, refs)]
        resumen.append(f"{nombre}: {len(lista)} ítems")
    for tid in sorted(set(textos) - usados):
        resumen.append(f"aviso: el texto {tid} no lo usa ningún ítem")

    ids_tarjetas = set()
    for ruta in sorted((raiz / "teoria").glob("*.json")):
        lista = cargar(ruta, errores) or []
        for t in lista:
            if t.get("id") in ids_tarjetas:
                errores.append(f"teoria/{ruta.name} · {t.get('id')}: id de tarjeta duplicado")
            ids_tarjetas.add(t.get("id"))
            errores += [f"teoria/{ruta.name} · {t.get('id')}: {e}" for e in validar_tarjeta(t, competencias, anio)]
        resumen.append(f"teoria/{ruta.name}: {len(lista)} tarjetas")

    for ruta in sorted((raiz / "simulacros").glob("*.json")):
        s = cargar(ruta, errores) or {}
        if not coincide(s.get("id"), r"SIM\.[0-9]{2}"):
            errores.append(f"simulacros/{ruta.name}: el id debe tener el formato SIM.NN")
        base = s.get("textoBase")
        if base:
            errores += [f"simulacros/{ruta.name} · texto base: {e}" for e in validar_procedencia(base.get("procedencia"), anio)]
        errores += [f"simulacros/{ruta.name}: {e}" for e in validar_validacion(s.get("validacion"))]
        resumen.append(f"simulacros/{ruta.name}: 1 simulacro")

    print(f"Contenido: {raiz} · año de referencia {anio}")
    for r in resumen:
        print(f"  {r}")
    print(f"Ítems por estado: " + ", ".join(f"{k} {v}" for k, v in sorted(estados.items(), key=lambda kv: str(kv[0]))))
    print("No validado aquí: plantillas/ (requieren los generadores de Swift), lexico/ y gramatica/.")
    for e in errores:
        print(f"ERROR: {e}")
    print(f"Resultado: {len(errores)} errores")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
