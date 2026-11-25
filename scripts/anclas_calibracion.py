#!/usr/bin/env python3
"""Anclas de calibración «nivel examen» (Fase 05E, §3) → Content/calibracion/anclas.json.

Para cada pregunta oficial de una competencia con generador: su perfil estructural (pasos, tipo y
tamaño de los números, formato), la plantilla con la que se comprueba, el nivel que la reproduce y,
si es el 4, la comprobación que hace el test de anclas (1000 semillas en el nivel 4). Cuando el
perfil no se alcanza con el generador actual se dice, sin inventarlo.
"""
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "Educulter/Content/calibracion/anclas.json"


def a(pregunta, competencia, plantilla, perfil, nivel, comprobacion=None, nota="", cambio=""):
    return {"pregunta": pregunta, "competencia": competencia, "plantilla": plantilla, "perfil": perfil,
            "nivelQueLaReproduce": nivel, "reproducible": comprobacion is not None,
            "comprobacion": comprobacion, "nota": nota, "cambioEnLaTabla": cambio}


COMB = {"generador": "operacionesCombinadas", "operaciones": 7, "maximoNumero": 99, "soloNaturales": True}
ANCLAS = [
    # MAT.OPE.COMB / JER
    a("OF.2019.O-M20", "MAT.OPE.COMB", "MAT.OPE.COMB.G02",
      {"pasos": 7, "numeros": "naturales de hasta 2 cifras", "agrupacion": "paréntesis y corchetes", "formato": "calcular el resultado"},
      4, dict(COMB, profundidad=2), cambio="Nivel 4: de 4 operaciones a 7, con dos niveles de agrupación y números hasta 20."),
    a("OF.2019.A-M20", "MAT.OPE.COMB", "MAT.OPE.COMB.G02",
      {"pasos": 7, "numeros": "naturales de hasta 2 cifras", "agrupacion": "paréntesis y corchetes", "formato": "calcular el resultado"},
      4, dict(COMB, profundidad=2)),
    a("OF.2017.O-M19", "MAT.OPE.COMB", "MAT.OPE.COMB.G02",
      {"pasos": 7, "numeros": "naturales de hasta 2 cifras", "agrupacion": "paréntesis", "formato": "calcular el resultado"},
      4, COMB, nota="Mismos pasos y números; el nivel 4 añade un nivel de agrupación (corchetes)."),
    a("OF.2026.A-M20", "MAT.OPE.COMB", "MAT.OPE.COMB.G02",
      {"pasos": 7, "numeros": "naturales de 1 cifra o 2", "agrupacion": "paréntesis, corchetes y llaves", "formato": "calcular el resultado"},
      5, nota="Tres niveles de agrupación: los da el nivel 5, que además añade una potencia (lo supera)."),
    a("OF.2022.O-M13", "MAT.OPE.JER", "MAT.OPE.JER.G01",
      {"pasos": 3, "numeros": "decimales de hasta 3 cifras decimales", "agrupacion": "ninguna", "formato": "calcular el resultado"},
      None, nota="No reproducible: el generador de operaciones combinadas solo usa naturales y fracciones."),
    # MAT.NUM.ORDEN
    *[a(q, "MAT.NUM.ORDEN", "MAT.NUM.ORDEN.G02",
        {"pasos": 1, "numeros": "4 números: fracciones (denominador ≤ 24, también impropias) y decimales (1–3 cifras) mezclados",
         "formato": "ordenar"},
        4, {"generador": "ordenarNumeros", "cantidad": 4, "mezcla": True, "maximoDecimales": 3, "maximoDenominador": 24},
        cambio="Nivel 4: de 5 fracciones del mismo denominador o numerador a 4 números mezclados (fracciones y decimales)." if q == "OF.2017.O-M11" else "")
      for q in ["OF.2017.O-M11", "OF.2019.A-M14", "OF.2019.O-M14", "OF.2026.A-M14"]],
    a("OF.2022.O-M12", "MAT.NUM.ORDEN", "MAT.NUM.ORDEN.G02",
      {"pasos": 2, "numeros": "3 fracciones dadas con palabras (la mitad, tres cuartas partes…)", "formato": "problema: quién ha leído más"},
      3, nota="El nivel 3 ordena fracciones; el enunciado con palabras no se genera."),
    a("OF.2024.O-M11", "MAT.NUM.ORDEN", "MAT.NUM.ORDEN.G02",
      {"pasos": "4 cálculos y ordenar", "numeros": "expresiones con fracciones, decimales y potencias", "formato": "calcular y ordenar"},
      None, nota="No reproducible: hay que calcular expresiones antes de ordenar."),
    # MAT.NUM.FRAOP
    a("OF.2019.O-M11", "MAT.NUM.FRAOP", "MAT.NUM.FRAOP.G03",
      {"pasos": "2–3 operaciones", "numeros": "3–4 fracciones con denominadores distintos ≤ 15", "operaciones": "sumas y restas", "formato": "resultado simplificado"},
      4, {"generador": "fraccionesOperar", "fracciones": [3, 4], "operadores": ["+", "−"], "maximoDenominador": 15},
      cambio="Nivel 4: de multiplicar o dividir dos fracciones a sumar y restar 3–4 fracciones (el producto y el cociente pasan al 3)."),
    a("OF.2024.O-M12", "MAT.NUM.FRAOP", "MAT.NUM.FRAOP.G03",
      {"pasos": 6, "numeros": "fracciones y un entero", "agrupacion": "paréntesis y corchetes", "formato": "resultado simplificado"},
      6, nota="Combinada con agrupaciones: nivel 6 (con una sola agrupación)."),
    # MAT.NUM.FRAPROB
    *[a(q, "MAT.NUM.FRAPROB", "MAT.NUM.FRAPROB.G02",
        {"pasos": 3, "numeros": f"total {t}; tres fracciones, cada una sobre lo que queda", "formato": "cuánto queda"},
        4, {"generador": "problemaFraccion", "fracciones": 3, "sobreLoQueQueda": True},
        nota=n, cambio=c)
      for q, t, n, c in [("OF.2026.A-M11", "360", "", "Nivel 4: de dos gastos sobre el total a tres gastos sucesivos sobre lo que queda (antes era el nivel 6)."),
                         ("OF.2019.A-M11", "60", "Las fracciones del examen llegan a denominador 15 (2/11, 3/15); el generador, a 8.", "")]],
    a("OF.2026.O-M13", "MAT.NUM.FRAPROB", "MAT.NUM.FRAPROB.G01",
      {"pasos": 2, "numeros": "3 fracciones del total y el resto", "formato": "fracción del resto"},
      3, nota="Fracciones sobre el total (nivel 3), pero se pide la fracción, no la cantidad: perfil parcial."),
    # MAT.UNI.TIEM
    *[a(q, "MAT.UNI.TIEM", "MAT.UNI.TIEM.G01",
        {"pasos": "pasar 3 tiempos a una unidad y sumar", "numeros": "h, min y s sin normalizar («165 min 900 s»)", "formato": f"total en {u}"},
        4, {"generador": "sexagesimal", "tiempos": 3, "sinNormalizar": True},
        cambio="Nivel 4: de sumar o restar dos tiempos normalizados a sumar tres tiempos sin normalizar." if q == "OF.2026.A-M12" else "")
      for q, u in [("OF.2026.A-M12", "segundos"), ("OF.2019.A-M12", "minutos")]],
    a("OF.2019.O-M12", "MAT.UNI.TIEM", "MAT.UNI.TIEM.G01",
      {"pasos": 1, "numeros": "un tiempo sin normalizar («170′ 600″»)", "formato": "en una unidad (s, h o min)"},
      2, nota="El nivel 2 convierte h y min a segundos; el tiempo sin normalizar solo aparece en los niveles 4–5, dentro de una suma."),
    # MAT.UNI.LMC
    a("OF.2022.O-M14", "MAT.UNI.LMC", "MAT.UNI.LMC.G02",
      {"pasos": "3 conversiones y una suma", "numeros": "cantidad compleja de 3 términos (alguno de 2 cifras)", "formato": "a una unidad intermedia, resultado decimal"},
      4, {"generador": "conversionUnidades", "terminos": 3, "destinoIntermedio": True},
      cambio="Nivel 4 (lmc): de 2–3 términos a la unidad mayor a 3 términos a una unidad intermedia; el 5 suma 3 cantidades con decimales."),
    a("OF.2024.O-M16", "MAT.UNI.LMC", "MAT.UNI.LMC.G02",
      {"pasos": "sumar 3 cantidades complejas y comparar", "numeros": "kg, hg, dag y dg", "formato": "razonar si se supera un límite"},
      5, nota="Suma de cantidades: nivel 5 (sin la comparación final)."),
    a("OF.2017.O-M18", "MAT.UNI.LMC", "MAT.UNI.LMC.G02",
      {"pasos": 1, "numeros": "conversiones simples, algunas con decimales; también ha y dm³", "formato": "completar la igualdad"},
      2, nota="Una conversión por apartado: nivel 2 (lmc) y las plantillas de SUP y VOL."),
    a("OF.2026.O-M14", "MAT.UNI.LMC", "MAT.UNI.LMC.G02",
      {"pasos": "2 conversiones y una suma", "numeros": "cantidad de 2 términos", "formato": "a metros"},
      3, nota="Compleja → incompleja: nivel 3."),
    # MAT.UNI.ESC
    a("OF.2026.O-M20", "MAT.UNI.ESC", "MAT.UNI.ESC.G02",
      {"pasos": "multiplicar por la escala y pasar a metros", "numeros": "medida decimal en cm o entera en mm; escalas 1:20–1:1000", "formato": "resultado en m"},
      4, {"generador": "escala", "modo": "mrPlano", "maximaEscala": 1000},
      cambio="Nivel 4: de la realidad al mapa pasa al 5; el 4 es el plano con medida decimal o en mm y resultado en metros."),
    # MAT.POR
    a("OF.2017.O-M16", "MAT.POR.VAR", "MAT.POR.VAR.G01",
      {"pasos": "1–2", "numeros": "15 % de 675 €, resultado con 2 decimales", "formato": "precio final"},
      4, {"generador": "porcentajeDe", "porcentajeNoRedondo": True, "base": [100, 2000], "maximoDecimales": 2},
      cambio="Nivel 4: se añaden 15 % y 22 % y la base pasa a 100–2000 (antes 20–2000)."),
    a("OF.2022.O-M16", "MAT.POR.CALC", "MAT.POR.CALC.G02",
      {"pasos": 1, "numeros": "22 %, 20 %, 10 % de 1250", "formato": "cantidad"},
      4, {"generador": "porcentajeDe", "porcentajeNoRedondo": True, "base": [100, 2000], "maximoDecimales": 2}),
    a("OF.2026.O-M16", "MAT.POR.CALC", "MAT.POR.CALC.G02",
      {"pasos": 1, "numeros": "35 % de 1920 €", "formato": "cantidad"},
      4, {"generador": "porcentajeDe", "porcentajeNoRedondo": True, "base": [100, 2000], "maximoDecimales": 2}),
    a("OF.2026.A-M15", "MAT.POR.PROP", "MAT.POR.PROP.G02",
      {"pasos": 1, "numeros": "de 6 a 15 personas (factor 5/2); cantidades de 3 cifras", "formato": "receta"},
      4, {"generador": "reglaDeTres", "factorNoEntero": True, "maximoDato": 1100},
      nota="Sin cambios: el nivel 4 ya era factor fraccionario con cantidades de hasta 3 cifras. El dato decimal (1,2 l) no se genera."),
    a("OF.2019.A-M15", "MAT.POR.PROP", "MAT.POR.PROP.G02",
      {"pasos": 1, "numeros": "de 4 a 5 personas (factor 5/4); un resultado decimal (8,75 g)", "formato": "receta"},
      4, {"generador": "reglaDeTres", "factorNoEntero": True, "maximoDato": 1100},
      nota="En el nivel 4 las recetas dan resultados enteros; el examen admite decimales."),
    a("OF.2022.O-M19", "MAT.POR.PROP", "MAT.POR.PROP.G02",
      {"pasos": 2, "numeros": "precios con decimales", "formato": "precio unitario y ahorro"}, 5, nota="Reducción a la unidad con decimales: nivel 5."),
    a("OF.2024.O-M15", "MAT.POR.PROP", "MAT.POR.PROP.G02",
      {"pasos": 3, "numeros": "días de trabajo", "formato": "trabajo conjunto (proporcionalidad inversa)"}, None,
      nota="No reproducible: el generador solo hace proporcionalidad directa."),
    # MAT.ROM
    *[a(q, c, pl, {"pasos": "3 conversiones", "numeros": n, "formato": f}, 4,
        {"generador": "romanos", "rango": [300, 3999], "sustractivos": 1},
        nota="El examen pide 3 números; cada ítem, uno." + (" 1223 no tiene grupo sustractivo." if q == "OF.2019.O-M19" else ""),
        cambio="Nivel 4: de 2000–3999 a 300–3999 con al menos un grupo sustractivo; el 5 exige dos." if q == "OF.2019.A-M19" else "")
      for q, c, pl, n, f in [("OF.2019.A-M19", "MAT.ROM.LEER", "MAT.ROM.LEER.G02", "MMCCCXLV, CCCXLVII, CDXCIII", "romano → arábigo"),
                             ("OF.2026.A-M19", "MAT.ROM.LEER", "MAT.ROM.LEER.G02", "MDXLVIII, CMXCIV, MMCDLIII", "romano → arábigo"),
                             ("OF.2017.O-M15", "MAT.ROM.ESCR", "MAT.ROM.ESCR.G02", "334, 975, 2069", "arábigo → romano"),
                             ("OF.2019.O-M19", "MAT.ROM.ESCR", "MAT.ROM.ESCR.G02", "824, 1223, 793", "arábigo → romano")]],
    # MAT.OPE.ECUAC (término desconocido)
    *[a(q, "MAT.OPE.ECUAC", "MAT.OPE.ECUAC.G03", {"pasos": 1, "numeros": n, "formato": "a · x = N y N : x = M"}, None,
        nota="No reproducible en el nivel 4 (incógnita en los dos miembros). Es la estructura del nivel 2 (ax = b) con números de 4–5 cifras, decimales y la incógnita como divisor, que el generador no hace.")
      for q, n in [("OF.2017.O-M10", "1,5 · a = 300; 8888 : b = 40"), ("OF.2019.A-M13", "23 · a = 9591; 24024 : b = 88"),
                   ("OF.2019.O-M13", "44 · a = 1012; 2425 : b = 485"), ("OF.2026.A-M13", "36 · a = 10.404; 28.560 : b = 84")]],
    # Generadores con plantillas en borrador
    a("OF.2022.O-M11", "MAT.DIV.MCD", "MAT.DIV.MCD.G01", {"pasos": 1, "numeros": "24, 12 y 18", "formato": "m.c.d. en un reparto"},
      4, {"generador": "mcmMcd", "numeros": [2, 3], "maximoNumero": 99},
      nota="Plantilla en borrador: el nivel 4 (3 números de 2 a 40) reproduce el perfil, sin el contexto."),
    a("OF.2017.O-M17", "MAT.DIV.MCM", "MAT.DIV.MCD.G01", {"pasos": 1, "numeros": "36 y 48", "formato": "m.c.m. en coincidencias"},
      3, nota="Dos números con contexto: nivel 3. No hay plantilla de MAT.DIV.MCM."),
    a("OF.2024.O-M14", "MAT.DIV.MCM", "MAT.DIV.MCD.G01", {"pasos": 2, "numeros": "3, 4 y 5; entre 300 y 350", "formato": "múltiplo común entre cotas"},
      6, nota="Nivel 6."),
    *[a(q, "MAT.PRO.LAPLACE", "MAT.PRO.LAPLACE.G01", {"pasos": 1, "numeros": n, "formato": "probabilidad de sucesos"},
        4, {"generador": "probabilidadSimple", "experimento": "tarjetas"}, nota="Plantilla en borrador. Tarjetas numeradas de 1 a n (n = 8–20).")
      for q, n in [("OF.2026.A-M16", "12 tarjetas"), ("OF.2019.A-M16", "10 bolas del 0 al 9")]],
    *[a(q, "MAT.EST.CENTRAL", "MAT.EST.CENTRAL.G01", {"pasos": "1 por medida", "numeros": n, "formato": "media, mediana, moda y rango"},
        4, {"generador": "estadisticaBasica", "datos": [5, 7], "maximoValor": 99},
        nota="Plantilla en borrador. El examen pide varias medidas; cada ítem, una.")
      for q, n in [("OF.2019.A-M18", "5 datos de 4 a 9"), ("OF.2019.O-M16", "5 datos de 4 a 9"), ("OF.2026.A-M18", "6 datos de 6 a 11")]],
    a("OF.2022.O-M17", "MAT.EST.CENTRAL", "MAT.EST.CENTRAL.G01", {"pasos": 4, "numeros": "tabla de frecuencias con decimales", "formato": "4 medidas"},
      None, nota="No reproducible: el generador no usa tablas de frecuencias."),
    a("OF.2024.O-M20", "MAT.EST.CENTRAL", "MAT.EST.CENTRAL.G01", {"pasos": 3, "numeros": "30 datos", "formato": "medidas de centralización"},
      None, nota="No reproducible: 30 datos (el generador usa 5–8)."),
    # Lengua
    *[a(q, "LEN.VER.ANALISIS", "LEN.VER.ANALISIS.G05", {"pasos": "1 por forma", "numeros": n, "formato": "persona, número, tiempo, modo (y aspecto)"},
        4, {"generador": "analisisVerbal", "tiempos": ["Pretérito pluscuamperfecto|Subjuntivo", "Futuro compuesto|Indicativo", "Condicional simple|Indicativo", "Pretérito imperfecto|Subjuntivo"]},
        nota="Las formas irregulares (es, estuvieras, visto, oí, era…) no se generan: no hay tabla de irregulares revisada.",
        cambio="Nivel 4: todos los tiempos de indicativo (salvo el pretérito anterior) y de subjuntivo en -ra con sus compuestos; antes llegaba a los compuestos de indicativo." if q == "OF.2024.O-L5" else "")
      for q, n in [("OF.2024.O-L5", "habréis cantado, cantaría, hubiéramos hablado (+ irregulares)"), ("OF.2019.O-L6", "llamaras, espero, llamas"),
                   ("OF.2022.O-L4", "perdiste, hundiré (+ sonrío)"), ("OF.2017.O-L6", "ignoras, sucede, has venido…"), ("OF.2019.A-L6", "desgarrara (+ oí, era)")]],
    a("OF.2017.O-L9", "LEN.SIN.COMPL", "LEN.SIN.COMPL.G07", {"pasos": "análisis completo", "numeros": "S + V + CCM + CCL", "formato": "analizar la oración"},
      5, nota="Nivel 4 de la tabla de §4.2 = copulativa: el examen corresponde al 5 (intransitivo + dos CC)."),
    a("OF.2024.O-L10", "LEN.SIN.COMPL", "LEN.SIN.COMPL.G07", {"pasos": "análisis completo", "numeros": "S + V + CD + CI", "formato": "analizar la oración"},
      5, nota="Nivel 5 (CD + CI)."),
    *[a(q, "LEN.SIN.COMPL", "LEN.SIN.COMPL.G07", {"pasos": "análisis completo", "numeros": n, "formato": "analizar la oración"}, None, nota=nt)
      for q, n, nt in [("OF.2026.O-L10", "S + V + CD + CCL", "Ningún nivel da CD + un CC en orden canónico (el 6 lo antepone)."),
                       ("OF.2026.A-L10", "S + V + CD (a + persona) + CCL", "Igual que la anterior."),
                       ("OF.2019.A-L10", "S + V + predicativo + CCL", "No reproducible: complemento predicativo."),
                       ("OF.2019.O-L10", "S + V semicopulativo + predicativo + CCL", "No reproducible: verbo semicopulativo."),
                       ("OF.2022.O-L10", "S + V + CD con CN + CCT + CCL", "No reproducible: complemento del nombre.")]],
    *[a(q, "LEN.LIT.HIST", "LEN.LIT.HIST.G05", {"pasos": "ordenar", "numeros": n, "formato": "del más antiguo al más moderno"},
        4, {"generador": "literatura", "separacion": [30, 90], "ambito": "espanola"},
        nota="El examen ordena 5–6 autores; la plantilla, 4 (§5).")
      for q, n in [("OF.2017.O-L8", "5 autores; separación mínima 35 años"), ("OF.2019.A-L9", "5 autores; separación mínima 29 años"),
                   ("OF.2019.O-L9", "5 autores; separación mínima 28 años")]],
    *[a(q, c, pl, {"pasos": 1, "numeros": n, "formato": "elegir la forma correcta en una frase"},
        4, {"generador": "fraseHueco", "opciones": [2, 4]}, nota=nt)
      for q, c, pl, n, nt in [("OF.2022.O-L9", "LEN.ORT.DIA", "LEN.ORT.DIA.G01", "dé/de, mí/mi…", "Sin el razonamiento que pide el examen."),
                              ("OF.2026.A-L7", "LEN.ORT.HOM", "LEN.ORT.HOM.G02", "porque/por qué, hay/ahí…", "Sin el razonamiento que pide el examen.")]],
    a("OF.2024.O-L7", "LEN.ORT.AGU", "LEN.ORT.AGU.G02", {"pasos": "revisar un texto", "numeros": "tildes diacríticas e interrogativas en contexto", "formato": "texto"},
      None, nota="No reproducible: colocarTilde trabaja palabras sueltas; el texto con contexto está pendiente (tildeContexto.json)."),
]


def main():
    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    datos = {"version": 1,
             "nota": "Anclas de la calibración «nivel examen» (Fase 05E, §3). Escala: 1–2 base, 3 intermedio, 4 = examen oficial, "
                     "5–6 por encima. Las anclas con «comprobacion» las verifica el test de anclas con 1000 semillas en el nivel 4. "
                     "Generado por scripts/anclas_calibracion.py.",
             "anclas": ANCLAS}
    DESTINO.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    rep = sum(1 for x in ANCLAS if x["reproducible"])
    print(f"{len(ANCLAS)} anclas; {rep} reproducidas en el nivel 4; {len(ANCLAS) - rep} no (con su nivel o su motivo)")


if __name__ == "__main__":
    main()
