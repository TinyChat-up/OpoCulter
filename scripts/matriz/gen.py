import sys, collections
sys.path.insert(0,'.')
from datos import R
out=[]
p=out.append
p("# Matriz de exámenes oficiales · Prueba común A1 de Maestros (Comunidad de Madrid)\n")
p("Elaborada por Claude Code el 23/11/2026 a partir de los cuadernillos publicados en comunidad.madrid y sede.comunidad.madrid (ver [FUENTES.md](FUENTES.md)). Los resúmenes están redactados con nuestras palabras y **no** reproducen los enunciados. Texto extraído con `scripts/extraer_examenes.swift` (PDFKit + OCR de Vision) en `docs/examenes/texto/`, revisado a mano.\n")
p("**Leyenda:** † = competencia que no existe en el catálogo actual (propuesta). La mecánica es una sugerencia para convertir el *tipo* de tarea en ítems originales o en generadores; el Modo Tribunal reproducirá los enunciados oficiales literalmente.\n")
exs=sorted(set((r[0],r[1]) for r in R))
p(f"## 1. Exámenes analizados ({len(exs)} cuadernillos, {len(R)} preguntas)\n")
p("| Año | Convocatoria | Preguntas Lengua | Preguntas Matemáticas |\n|---|---|---|---|")
for y,c in exs:
    nl=sum(1 for r in R if r[:3]==(y,c,'Lengua')); nm=sum(1 for r in R if r[:3]==(y,c,'Matemáticas'))
    p(f"| {y} | {c} | {nl} | {nm} |")
p("\nNo se han encontrado publicados en la web oficial los cuadernillos de 2014, 2015, 2016, 2018, 2020, 2021, 2023 ni 2025, ni las aplazadas de 2017, 2022 y 2024 (en esos años no hubo convocatoria de Maestros o la web no los conserva). Plantillas de corrección publicadas: solo 2026 (ordinaria y aplazada), que puntúan cada pregunta con 1, 0,5 o 0 puntos.\n")
p("## 2. Matriz\n")
p("| Año | Conv. | Área | Nº | Resumen | Bloque | Competencia | Tipo de tarea | Mecánica sugerida |\n|---|---|---|---|---|---|---|---|---|")
for r in R:
    p("| "+" | ".join(str(x) for x in r)+" |")
p("\n## 3. Frecuencias\n")
p("### 3.1 Por bloque\n")
cb=collections.Counter((r[2],r[5]) for r in R)
p("| Área | Bloque | Preguntas | % del área |\n|---|---|---|---|")
for area in ['Lengua','Matemáticas']:
    tot=sum(v for (a,_),v in cb.items() if a==area)
    for (a,b),v in sorted(cb.items(), key=lambda kv:-kv[1]):
        if a==area: p(f"| {a} | {b} | {v} | {100*v/tot:.0f} % |")
p("\n### 3.2 Por tipo de tarea (los más frecuentes)\n")
ct=collections.Counter((r[2],r[7]) for r in R)
p("| Área | Tipo de tarea | Preguntas | Exámenes en que aparece |\n|---|---|---|---|")
for (a,t),v in ct.most_common():
    n=len(set((r[0],r[1]) for r in R if r[2]==a and r[7]==t))
    if v>=2: p(f"| {a} | {t} | {v} | {n} de {len(exs)} |")
p("\n### 3.3 Por mecánica sugerida\n")
cm=collections.Counter(r[8] for r in R)
p("| Mecánica | Preguntas |\n|---|---|")
for m,v in cm.most_common(): p(f"| `{m}` | {v} |")
p("\n## 4. Clásicos repetidos entre años\n")
p("Tipos de tarea que aparecen en 3 o más cuadernillos (candidatos prioritarios a plantilla de generador o a banco curado):\n")
p("| Área | Tipo de tarea | Cuadernillos | Años |\n|---|---|---|---|")
for (a,t),v in ct.most_common():
    ex=sorted(set((r[0],r[1][0]) for r in R if r[2]==a and r[7]==t))
    if len(ex)>=3: p(f"| {a} | {t} | {len(ex)} | {', '.join(f'{y}{c}' for y,c in ex)} |")
p("\n(O = ordinaria, A = aplazada.) Estructura fija observada en todos los cuadernillos: 10 preguntas por área (9 en Lengua en 2017), 1 punto por pregunta y 1 h 30 min sin calculadora. Lengua parte siempre de un **texto literario** (comentario) y termina siempre con un **análisis sintáctico** de oración simple. Matemáticas mezcla cálculo puro (término desconocido, ordenar, romanos, operación combinada) con problemas de contexto.\n")
p("\n## 5. Competencias propuestas (†)\n")
nuevas=sorted(set(r[6] for r in R if r[6].endswith('†')))
p("| Competencia | Bloque | Preguntas | Ejemplo de tarea |\n|---|---|---|---|")
for c in nuevas:
    rs=[r for r in R if r[6]==c]
    p(f"| {c[:-1]} | {rs[0][5]} | {len(rs)} | {rs[0][4]} |")
open(sys.argv[1],'w').write("\n".join(out)+"\n")
print(len(R), "preguntas;", len(nuevas), "competencias propuestas")
