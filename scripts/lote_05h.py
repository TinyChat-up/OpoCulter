#!/usr/bin/env python3
"""Datos de la Fase 05H (ANEXOS A y B de la dirección, aprobados) → Content/formacion.json,
Content/recursos.json y Content/glosario.json. Idempotente.

Comprobaciones: las piezas de cada palabra (salvo las compuestas con el primer elemento alterado)
concatenadas dan la palabra; cada marca [..] está en su ejemplo; los recursos «también presentes»
existen en la lista.
"""
import json
import pathlib
import re
import unicodedata

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CONTENT = RAIZ / "Educulter/Content"
VALIDACION = {"estado": "aprobado", "revisor": "direccion", "fecha": "2026-11-27"}
PROCEDENCIA = {"tipo": "original", "licencia": "propia", "notas": "Fase 05H: datos y ejemplos originales de la dirección (ANEXOS A y B)."}

FORMACION = """
mar | P | l:mar | mar | masa de agua salada
sol | P | l:sol | sol | estrella que nos da luz
pan | P | l:pan | pan | alimento de harina cocida
flor | P | l:flor | flor | parte de la planta con pétalos
casa | P | l:cas + m:a | casa | edificio para vivir
árbol | P | l:árbol | árbol | planta de tronco leñoso
libro | P | l:libr + m:o | libro | conjunto de hojas encuadernadas
luz | P | l:luz | luz | lo que permite ver
tierra | P | l:tierr + m:a | tierra | suelo, planeta
leche | P | l:lech + m:e | leche | líquido blanco de las hembras de los mamíferos
zapatero | D | l:zapat + s:ero | zapato | persona que hace o arregla zapatos
florista | D | l:flor + s:ista | flor | persona que vende flores
librería | D | l:libr + s:ería | libro | tienda de libros
lechero | D | l:lech + s:ero | leche | persona que vende leche
arboleda | D | l:arbol + s:eda | árbol | lugar con muchos árboles
casita | D | l:cas + s:ita | casa | casa pequeña
perrazo | D | l:perr + s:azo | perro | perro grande
felizmente | D | l:feliz + s:mente | feliz | de manera feliz
belleza | D | l:bell + s:eza | bello | cualidad de bello
jardinero | D | l:jardin + s:ero | jardín | persona que cuida un jardín
cantante | D | l:cant + s:ante | cantar | persona que canta
dentista | D | l:dent + s:ista | diente | médico de los dientes
peligroso | D | l:peligr + s:oso | peligro | que tiene peligro
amable | D | l:am + s:able | amar | digno de ser amado; afectuoso
deshacer | D | p:des + l:hacer | hacer | quitar lo que estaba hecho
imposible | D | p:im + l:posible | posible | que no es posible
releer | D | p:re + l:leer | leer | volver a leer
prehistoria | D | p:pre + l:historia | historia | época anterior a la historia escrita
inútil | D | p:in + l:útil | útil | que no sirve
antinatural | D | p:anti + l:natural | natural | contrario a lo natural
contraataque | D | p:contra + l:ataque | ataque | ataque que responde a otro
bicolor | D | p:bi + l:color | color | de dos colores
deslealtad | D | p:des + l:leal + s:tad | leal | falta de lealtad
enrojecer | PS | p:en + l:roj + s:ecer | rojo | poner rojo
aterrizar | PS | p:a + l:terr + s:izar | tierra | posarse en tierra
embarcar | PS | p:em + l:barc + s:ar | barco | subir a un barco
encarcelar | PS | p:en + l:carcel + s:ar | cárcel | meter en la cárcel
quinceañero | PS | l:quince + l:añ + s:ero | quince años | que tiene unos quince años
sacapuntas | C | l:saca + l:puntas | sacar + puntas | utensilio para afilar lápices
girasol | C | l:gira + l:sol | girar + sol | planta cuya flor se orienta al sol
abrelatas | C | l:abre + l:latas | abrir + latas | utensilio para abrir latas
paraguas | C | l:para + l:aguas | parar + aguas | utensilio contra la lluvia
cumpleaños | C | l:cumple + l:años | cumplir + años | aniversario del nacimiento
bocacalle | C | l:boca + l:calle | boca + calle | entrada de una calle
pelirrojo | C | l:pelo(peli-) + l:rojo | pelo + rojo | de pelo rojo
agridulce | C | l:agrio(agri-) + l:dulce | agrio + dulce | entre agrio y dulce
mediodía | C | l:medio + l:día | medio + día | mitad del día
rompecabezas | C | l:rompe + l:cabezas | romper + cabezas | juego de piezas para encajar
guardabosques | C | l:guarda + l:bosques | guardar + bosques | persona que vigila los bosques
salvavidas | C | l:salva + l:vidas | salvar + vidas | objeto para no hundirse en el agua
altavoz | C | l:alta + l:voz | alto + voz | aparato que amplifica el sonido
"""

FAMILIAS = {
    "pan": ["panadero", "panadería", "panecillo", "empanada"],
    "mar": ["marino", "marinero", "submarino", "marea"],
    "tierra": ["terreno", "terrestre", "enterrar", "aterrizar", "terremoto"],
    "flor": ["florero", "florista", "floración", "florecer"],
    "libro": ["librería", "librero", "libreta"],
    "leche": ["lechero", "lechería", "lechoso"],
    "luz": ["lucero", "lucecita", "luminoso"],
}
FALSAS = {"mar": ["marrón"], "pan": ["panel"], "leche": ["lecho"], "sol": ["solapa"], "libro": ["librar"],
          "tierra": ["terco"], "flor": ["flotar"], "luz": ["lucha"]}

RECURSOS = """
metáfora | identifica un elemento real con otro imaginario por su semejanza, sin nexo comparativo | Su risa era [una cascada de cristales]. | El río, [serpiente de plata], cruzaba el valle. | —
comparación o símil | relaciona dos elementos por su semejanza mediante un nexo (como, igual que, cual) | Corría [como el viento]. | Su voz sonaba [igual que una campana]. | —
personificación | atribuye cualidades o acciones humanas a animales u objetos | La ciudad [dormía] bajo la lluvia. | El viento [susurraba secretos] a las ventanas. | —
hipérbole | exagera de forma desmesurada | Te lo he dicho [un millón de veces]. | Tengo tanta hambre que [me comería una montaña]. | —
anáfora | repite una o varias palabras al comienzo de varios versos o frases | [Quiero] el mar tranquilo, [quiero] la tarde lenta, [quiero] tu voz cercana. | [Sin] prisa, [sin] miedo, [sin] mirar atrás. | paralelismo
aliteración | repite un mismo sonido en palabras próximas | [Rueda el carro por la roca roja]. | [Silba el siseo suave de la seda]. | —
onomatopeya | palabra que imita un sonido | El [tictac] del reloj llenaba el salón. | Se oyó el [crac] de la rama. | —
epíteto | adjetivo que expresa una cualidad propia del sustantivo | Pisábamos la [blanca] nieve. | Bebió el [dulce] almíbar. | —
antítesis | contrapone dos ideas o palabras de significado opuesto | Unos [ríen] y otros [lloran]. | Era [joven] en años y [viejo] en tristezas. | paralelismo
hipérbaton | altera el orden habitual de las palabras en la oración | [De la montaña en lo alto] el sol brillaba. | [Verdes los campos estaban]. | —
paralelismo | repite una misma estructura sintáctica en frases o versos seguidos | [El niño corre por el patio; la niña salta junto al muro]. | [Los perros ladraban en la calle; los gatos dormían en el tejado]. | —
enumeración | acumula elementos de una misma serie | Había [libros, cuadernos, lápices, mapas y relojes]. | Compró [pan, fruta, queso y flores]. | —
metonimia | nombra una cosa con el nombre de otra con la que guarda relación (autor por obra, continente por contenido…) | Este verano leí [un Galdós]. | Después de cenar se tomaron [unas copas]. | —
interrogación retórica | pregunta que no espera respuesta porque la respuesta es evidente | [¿Quién no ha soñado alguna vez con volar?] | [¿Acaso no merece la pena intentarlo?] | —
polisíndeton | repite conjunciones más de lo necesario | [Y] llegó, [y] miró, [y] se fue sin decir nada. | Comimos [y] bebimos [y] reímos [y] cantamos. | —
asíndeton | suprime las conjunciones entre elementos | [Entró, saludó, se sentó, calló]. | [Corre, salta, grita, ríe]. | enumeración
sinestesia | une sensaciones de sentidos distintos | Llevaba un [verde chillón]. | Le habló con una [voz dulce]. | —
oxímoron | une en un mismo grupo dos palabras de significado contrario | Se hizo un [silencio atronador]. | Sentía una [dulce amargura]. | —
apóstrofe | se dirige con emoción a un ser presente o ausente, real o imaginario | [¡Oh, mar, guárdame tus secretos!] | [¡Luna, acompáñame esta noche!] | personificación
elipsis | omite palabras que se sobreentienden | Yo tomo café; [ella, té]. | Él fue al cine; [yo, al teatro]. | paralelismo
"""

GLOSARIO = """
sustantivo | clases de palabras | palabra variable que nombra personas, animales, cosas, lugares o ideas
adjetivo | clases de palabras | palabra variable que expresa cualidades o estados del sustantivo y concuerda con él
determinante | clases de palabras | palabra que acompaña al sustantivo y concreta su significado (artículos, posesivos, demostrativos…)
pronombre | clases de palabras | palabra que sustituye al sustantivo o se refiere a personas o cosas sin nombrarlas
verbo | clases de palabras | palabra que expresa acciones, estados o procesos y varía en persona, número, tiempo y modo
adverbio | clases de palabras | palabra invariable que modifica al verbo, al adjetivo o a otro adverbio (lugar, tiempo, modo, cantidad…)
preposición | clases de palabras | palabra invariable que introduce un complemento y lo une a otra palabra (a, ante, bajo, con, de…)
conjunción | clases de palabras | palabra invariable que une palabras, grupos u oraciones (y, ni, o, pero, porque, que…)
interjección | clases de palabras | palabra invariable que expresa emociones o llama la atención (¡ay!, ¡oh!, ¡eh!)
sinónimos | relaciones de significado | palabras con significado igual o muy parecido
antónimos | relaciones de significado | palabras con significado opuesto
polisemia | relaciones de significado | propiedad de una palabra que tiene varios significados relacionados
homonimia | relaciones de significado | coincidencia en la forma de palabras de significados y orígenes distintos
hiperónimo | relaciones de significado | palabra de significado general que incluye a otras (flor respecto de rosa)
hipónimo | relaciones de significado | palabra de significado concreto incluida en otra más general (rosa respecto de flor)
campo semántico | relaciones de significado | conjunto de palabras de la misma categoría que comparten un rasgo de significado
familia léxica | formación de palabras | conjunto de palabras que comparten el mismo lexema
lexema | formación de palabras | parte de la palabra que aporta el significado principal
morfema | formación de palabras | parte de la palabra que aporta información gramatical o forma palabras nuevas
diptongo | sílabas y acentuación | dos vocales seguidas pronunciadas en la misma sílaba
hiato | sílabas y acentuación | dos vocales seguidas pronunciadas en sílabas distintas
palabra aguda | sílabas y acentuación | palabra con el acento en la última sílaba
palabra llana | sílabas y acentuación | palabra con el acento en la penúltima sílaba
palabra esdrújula | sílabas y acentuación | palabra con el acento en la antepenúltima sílaba
"""

TIPOS = {"P": "primitiva", "D": "derivada", "C": "compuesta", "PS": "parasintetica"}
CLASE_PIEZA = {"p": "prefijo", "l": "lexema", "s": "sufijo", "m": "morfema"}


def sin_tildes(s):
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def formacion():
    palabras = []
    for linea in FORMACION.strip().splitlines():
        palabra, tipo, piezas, base, definicion = [x.strip() for x in linea.split("|")]
        lista, alterada = [], False
        for pz in piezas.split("+"):
            clase, texto = pz.strip().split(":", 1)
            m = re.match(r"^(.*)\((.*)-\)$", texto)
            if m:  # pelo(peli-): forma base y forma que aparece en la palabra
                alterada = True
                lista.append({"clase": CLASE_PIEZA[clase], "texto": m.group(2), "base": m.group(1)})
            else:
                lista.append({"clase": CLASE_PIEZA[clase], "texto": texto})
        unida = "".join(p["texto"] for p in lista)
        # Las piezas dan la palabra (se admite la tilde de la palabra que la pieza no lleva: árbol/arbol).
        # Las compuestas pueden fundir sonidos (para + aguas → paraguas): como pelirrojo, solo se clasifican.
        assert tipo == "C" or sin_tildes(unida) == sin_tildes(palabra), (palabra, unida)
        palabras.append({"palabra": palabra, "tipo": TIPOS[tipo], "piezas": lista, "base": base, "definicion": definicion,
                         "soloClasificar": alterada or sin_tildes(unida) != sin_tildes(palabra)})
    familias = [{"primitiva": k, "miembros": v, "falsas": FALSAS.get(k, [])} for k, v in FAMILIAS.items()]
    for k, v in FALSAS.items():
        if k not in FAMILIAS:
            familias.append({"primitiva": k, "miembros": [], "falsas": v})
    return {"version": 1, "validacion": VALIDACION, "procedencia": PROCEDENCIA, "palabras": palabras, "familias": familias}


def recursos():
    lista = []
    for linea in RECURSOS.strip().splitlines():
        nombre, definicion, e1, e2, tambien = [x.strip() for x in linea.split("|")]
        ejemplos = []
        for e in (e1, e2):
            marcas = re.findall(r"\[([^\]]+)\]", e)
            assert marcas, e
            ejemplos.append({"texto": e.replace("[", "").replace("]", ""), "marcas": marcas})
        lista.append({"recurso": nombre, "definicion": definicion, "ejemplos": ejemplos,
                      "tambien": [] if tambien == "—" else [t.strip() for t in tambien.split(",")]})
    nombres = {r["recurso"] for r in lista}
    for r in lista:
        assert all(t in nombres for t in r["tambien"]), r
    return {"version": 1, "validacion": VALIDACION, "procedencia": PROCEDENCIA, "recursos": lista}


def glosario():
    lista = []
    for linea in GLOSARIO.strip().splitlines():
        termino, grupo, definicion = [x.strip() for x in linea.split("|")]
        lista.append({"termino": termino, "grupo": grupo, "definicion": definicion})
    return {"version": 1, "validacion": VALIDACION, "procedencia": PROCEDENCIA, "terminos": lista}


for nombre, datos in [("formacion.json", formacion()), ("recursos.json", recursos()), ("glosario.json", glosario())]:
    (CONTENT / nombre).write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n")
    print(nombre, {k: len(v) for k, v in datos.items() if isinstance(v, list)})
