#!/usr/bin/env python3
"""J46 «De evidencia a resumen» (Fase 05G, ANEXO A): genera Content/resumen.json y añade a los
textos base TXT.ORI.SUENO y TXT.ORI.BICI. Los textos son de la dirección y no se modifican.
Comprueba que cada fragmento central y de detalle aparece literalmente en su texto. Idempotente."""
import json, pathlib, sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CONTENT = RAIZ / "Educulter/Content"
VAL = {"estado": "aprobado", "revisor": "direccion", "fecha": "2026-11-26"}
PROC = {"tipo": "original", "autorTexto": None, "anioMuerteAutor": None, "fuente": None, "licencia": "propia",
        "notas": "Redacción original de la dirección del proyecto (Fase 05G, ANEXO A)."}

NUEVOS = [
    ("TXT.ORI.SUENO", "Dormir", "expositivo",
     "Dormir no es perder el tiempo. Mientras dormimos, el cerebro ordena lo que hemos aprendido durante el día y lo guarda en la memoria. También el cuerpo aprovecha esas horas para reparar los músculos y recuperar energía. Por eso, los especialistas recomiendan que un niño de Primaria duerma entre nueve y doce horas. Quien descansa poco se concentra peor, se irrita con facilidad y rinde menos en clase."),
    ("TXT.ORI.BICI", "La bicicleta en la ciudad", "argumentativo",
     "Las ciudades deberían reservar más calles para las bicicletas. La bicicleta no contamina, no hace ruido y ocupa poco espacio. Además, quien pedalea a diario hace ejercicio sin darse cuenta. Algunos comerciantes temen perder clientes si se limita el paso de coches; sin embargo, en algunas ciudades que lo han probado, los comercios de las calles tranquilas han ganado clientes. Apostar por la bicicleta es apostar por una ciudad más sana."),
]

DATOS = [
    {"texto": "TXT.ORI.ABEJAS",
     "central": ["al pasar de flor en flor transportan el polen y permiten que muchas plantas den frutos",
                 "su desaparición pondría en peligro buena parte de los alimentos que consumimos"],
     "detalle": ["una reina, que pone los huevos", "recogen néctar, fabrican la cera y cuidan de las crías", "cuya función es fecundar a la reina"],
     "tema": {"correcta": "La importancia de las abejas para las plantas y nuestra alimentación",
              "concreto": "La función de la reina en la colmena", "amplio": "Los insectos"},
     "modelo": "Las abejas viven en colmenas organizadas y, además de producir miel, polinizan las plantas, por lo que su desaparición amenazaría muchos de nuestros alimentos.",
     "criterios": ["menciona la polinización", "menciona la consecuencia para la alimentación", "no enumera las tareas de reina, obreras y zánganos",
                   "usa palabras propias, sin copiar frases enteras", "ocupa como máximo un tercio del texto"]},
    {"texto": "TXT.ORI.DEBERES",
     "central": ["Creo que en vacaciones los alumnos de Primaria no deberían tener deberes", "En definitiva, unas vacaciones sin tareas obligatorias también educan"],
     "detalle": ["leer por placer, jugar al aire libre o compartir tiempo con la familia", "En primer lugar", "En segundo lugar"],
     "tema": {"correcta": "La conveniencia de eliminar los deberes en vacaciones",
              "concreto": "Leer por placer en verano", "amplio": "La educación en Primaria"},
     "modelo": "El autor defiende que en Primaria no haya deberes en vacaciones, porque el descanso es necesario y se puede aprender de otras formas; admite que repasar ayuda, pero propone sustituirlo por lecturas recomendadas.",
     "criterios": ["recoge la tesis", "incluye al menos un argumento", "recoge la objeción y la alternativa (lecturas)",
                   "no enumera los ejemplos (leer, jugar, familia)", "usa palabras propias"]},
    {"texto": "TXT.ORI.FARO",
     "central": ["Encendió la lámpara de reserva justo cuando un pesquero aparecía entre las olas"],
     "detalle": ["los ciento veinte escalones", "el viento golpeaba los cristales", "con una linterna temblando entre las manos"],
     "tema": {"correcta": "El valor de una joven que salva a unos marineros durante una tormenta",
              "concreto": "Una noche de viento en el faro", "amplio": "La vida en los pueblos costeros"},
     "modelo": "Durante una tormenta que dejó el pueblo a oscuras, Lucía, la hija del farero, subió al faro y encendió la lámpara de reserva a tiempo para guiar a un pesquero, cuyos marineros se lo agradecieron al amanecer.",
     "criterios": ["dice quién actúa y en qué situación", "recoge la acción decisiva y su consecuencia", "respeta el orden de los hechos",
                   "no incluye detalles descriptivos (escalones, cristales)", "usa palabras propias"]},
    {"texto": "TXT.ORI.SUENO",
     "central": ["Dormir no es perder el tiempo", "el cerebro ordena lo que hemos aprendido durante el día y lo guarda en la memoria"],
     "detalle": ["entre nueve y doce horas", "se irrita con facilidad", "reparar los músculos"],
     "tema": {"correcta": "La importancia del sueño para aprender y recuperarse",
              "concreto": "Las horas que debe dormir un niño", "amplio": "La salud"},
     "modelo": "Dormir es necesario: durante el sueño el cerebro fija lo aprendido y el cuerpo se recupera, por eso los niños deben descansar lo suficiente para rendir bien.",
     "criterios": ["dice que dormir es necesario", "menciona el aprendizaje o la memoria", "menciona la recuperación del cuerpo o la consecuencia de dormir poco",
                   "no copia las cifras", "usa palabras propias"]},
    {"texto": "TXT.ORI.BICI",
     "central": ["Las ciudades deberían reservar más calles para las bicicletas", "Apostar por la bicicleta es apostar por una ciudad más sana"],
     "detalle": ["no hace ruido", "ocupa poco espacio", "hace ejercicio sin darse cuenta"],
     "tema": {"correcta": "La conveniencia de dar más espacio a la bicicleta en las ciudades",
              "concreto": "El ruido de los coches", "amplio": "El transporte"},
     "modelo": "El autor defiende dar más espacio a la bicicleta en las ciudades porque no contamina, ocupa poco y es saludable, y responde a quienes temen por el comercio con ciudades donde las calles tranquilas han ganado clientes.",
     "criterios": ["recoge la tesis", "incluye al menos un argumento", "recoge la objeción de los comerciantes y la respuesta",
                   "no enumera todas las ventajas", "usa palabras propias"]},
]


def main():
    ruta = CONTENT / "textos/textos.json"
    archivo = json.loads(ruta.read_text(encoding="utf-8"))
    lista = archivo if isinstance(archivo, list) else archivo["textos"]
    ids = {t["id"] for t in lista}
    for tid, titulo, tipo, texto in NUEVOS:
        if tid not in ids:
            lista.append({"id": tid, "titulo": titulo, "autor": None, "obra": None, "tipo": tipo,
                          "procedencia": PROC, "validacion": VAL, "texto": texto})
    ruta.write_text(json.dumps(archivo, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    textos = {t["id"]: t["texto"] for t in lista}
    fallos = [f"{d['texto']}: «{f}»" for d in DATOS for f in d["central"] + d["detalle"] if f not in textos[d["texto"]]]
    if fallos:
        sys.exit("Fragmentos que no están en su texto:\n" + "\n".join(fallos))
    salida = {"version": 1, "actividad": "J46", "validacion": VAL,
              "procedencia": {"tipo": "original", "licencia": "propia", "notas": "Redactado y aprobado por la dirección (Fase 05G, ANEXO A)."},
              "textos": DATOS}
    (CONTENT / "resumen.json").write_text(json.dumps(salida, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"resumen.json: {len(DATOS)} textos; textos base: {len(lista)}")


if __name__ == "__main__":
    main()
