#!/usr/bin/env python3
"""Importa las 9 tarjetas de teoría del ANEXO B de la 05E parte 2 (texto de la dirección, aprobado).

El texto no se modifica. Solo se adapta al esquema de la app:
- id `TEO.<competencia>` → `<competencia>.TNN` (formato del validador);
- `esquema`: los elementos separados por « · » pasan a una fila por línea (formato de `FilaEsquema`);
- `truco` es un tipo de bloque propio (se muestra destacado).
Idempotente: sustituye las tarjetas con el mismo id.
"""
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent
TEORIA = RAIZ / "Educulter/Content/teoria"
VALIDACION = {"estado": "aprobado", "revisor": "direccion", "fecha": "2026-11-25"}
PROCEDENCIA = {"tipo": "original", "autorTexto": None, "anioMuerteAutor": None, "fuente": None, "licencia": "propia",
               "notas": "Redacción original de la dirección del proyecto (ANEXO B de la Fase 05E, parte 2)."}

TARJETAS = [
    ("LEN.SIN.SUJPRED", "T02", "Sujeto y predicado", [
        ("regla", "El sujeto es el grupo de palabras que concuerda con el verbo en número y persona. El predicado es todo lo demás: el verbo y sus complementos."),
        ("truco", "Cambia el verbo de singular a plural. La palabra que también tiene que cambiar es el núcleo del sujeto."),
        ("esquema", "Oración: Las niñas cantan una canción · Sujeto: Las niñas · Núcleo del sujeto: niñas · Predicado: cantan una canción · Núcleo del predicado: cantan"),
        ("texto", "El sujeto puede ir detrás del verbo («Llegaron los alumnos») o no aparecer («Cantamos»: sujeto omitido, nosotros)."),
    ]),
    ("LEN.SIN.COMPL", "T01", "Los complementos del verbo", [
        ("esquema", "CD: recibe la acción; se sustituye por lo, la, los, las · CI: destinatario de la acción; lleva «a» y se sustituye por le, les · CC: circunstancia de lugar, tiempo, modo, compañía, cantidad, causa, finalidad o instrumento · Atributo: con ser, estar o parecer, dice cómo es o está el sujeto; se sustituye por «lo»"),
        ("texto", "«Compró el libro» → «Lo compró» (CD). «Escribió a su abuela» → «Le escribió» (CI). «Está contenta» → «Lo está» (atributo)."),
        ("truco", "El CD de persona también lleva «a»: «Saludó a la vecina» → «La saludó». Si se sustituye por «la», es CD, no CI."),
    ]),
    ("LEN.SIN.CLASE", "T01", "Clases de oraciones", [
        ("regla", "Con ser, estar o parecer y un atributo, la oración es copulativa (o atributiva) y su predicado es nominal. Con cualquier otro verbo, es predicativa y su predicado es verbal."),
        ("esquema", "Transitiva: lleva CD («Lee un cuento») · Intransitiva: no lleva CD («Corre por el parque») · Impersonal: no tiene sujeto («Llueve», «Hay niños», «Hace frío»)"),
        ("truco", "Primero mira el verbo: ¿es ser, estar o parecer con atributo? Si no, busca el CD para saber si es transitiva."),
    ]),
    ("LEN.VER.ANALISIS", "T01", "Análisis de una forma verbal", [
        ("regla", "Analizar una forma verbal es indicar persona, número, tiempo, modo, aspecto, conjugación e infinitivo."),
        ("esquema", "Persona: 1.ª, 2.ª o 3.ª · Número: singular o plural · Modo: indicativo, subjuntivo o imperativo · Aspecto: perfecto o imperfecto · Conjugación: 1.ª (-ar), 2.ª (-er) o 3.ª (-ir)"),
        ("texto", "«habíamos cantado»: 1.ª persona del plural del pretérito pluscuamperfecto de indicativo, aspecto perfecto, 1.ª conjugación, verbo cantar."),
        ("truco", "Los tiempos compuestos (haber + participio) son siempre perfectos. De los simples, solo el pretérito perfecto simple («canté») es perfecto."),
    ]),
    ("LEN.VER.NOPERS", "T01", "Formas no personales", [
        ("regla", "Las formas no personales no indican persona ni número: infinitivo, gerundio y participio."),
        ("esquema", "Infinitivo: cantar, haber cantado; funciona como un sustantivo · Gerundio: cantando, habiendo cantado; funciona como un adverbio · Participio: cantado; funciona como un adjetivo"),
        ("truco", "Participios irregulares frecuentes: hecho, dicho, escrito, visto, puesto, roto, vuelto, abierto, muerto, cubierto."),
    ]),
    ("LEN.LIT.GEN", "T01", "Géneros literarios", [
        ("regla", "Hay tres géneros literarios clásicos: lírico (expresa sentimientos, normalmente en verso), narrativo (cuenta hechos mediante un narrador) y dramático (diálogo pensado para representarse)."),
        ("esquema", "Lírica: oda, elegía, égloga, sátira, canción · Narrativa: epopeya, cantar de gesta, cuento, fábula, novela · Dramática: tragedia, comedia, drama, entremés, auto sacramental"),
        ("truco", "¿Hay narrador? Narrativo. ¿Hay personajes que dialogan sin narrador? Dramático. ¿Habla un «yo» de lo que siente? Lírico."),
    ]),
    ("LEN.LIT.HIST", "T01", "Periodos de la literatura española", [
        ("esquema", "Edad Media (s. XII–XV): Cantar de mio Cid, Berceo, Juan Ruiz, Jorge Manrique, La Celestina · Renacimiento (s. XVI): Garcilaso, Lazarillo, fray Luis de León, san Juan de la Cruz · Barroco (s. XVII): Cervantes, Lope de Vega, Góngora, Quevedo, Calderón · Ilustración (s. XVIII): Feijoo, Moratín · Romanticismo (s. XIX): Espronceda, Zorrilla; después, Bécquer y Rosalía de Castro · Realismo (s. XIX): Galdós, Clarín, Pardo Bazán · Modernismo y Generación del 98: Rubén Darío, Unamuno, Machado, Baroja, Valle-Inclán · Novecentismo y Generación del 27: Juan Ramón Jiménez, Lorca, Alberti, Cernuda, Aleixandre"),
        ("truco", "Ancla tres fechas: 1499, La Celestina; 1605, primera parte del Quijote; 1898, fin del imperio colonial."),
    ]),
    ("LEN.LIT.UNIV", "T01", "Literatura universal", [
        ("esquema", "Antigüedad: Homero (Ilíada y Odisea), Esopo (fábulas), Virgilio (Eneida) · Edad Media: Dante (Divina comedia), Petrarca, Boccaccio (Decamerón) · Renacimiento y Barroco: Shakespeare, Molière · Siglo XIX: Goethe, Victor Hugo, Dickens, Flaubert, Tolstói, Dostoievski · Siglo XX: Kafka, Proust, Joyce"),
        ("truco", "Dante, Petrarca y Boccaccio son italianos del siglo XIV. Shakespeare y Cervantes murieron en 1616."),
    ]),
    ("LEN.LIT.INF", "T01", "Literatura infantil y juvenil", [
        ("regla", "Son las obras escritas para niños y jóvenes o adoptadas por ellos: cuento, fábula, poesía, teatro, cómic y álbum ilustrado."),
        ("esquema", "Recopiladores de cuentos populares: Perrault (s. XVII), hermanos Grimm (s. XIX) · Cuentos de autor: Andersen (s. XIX) · Clásicos del XIX: Carroll (Alicia en el país de las maravillas, 1865), Collodi (Pinocho, 1883), Stevenson (La isla del tesoro, 1883) · En España: Gloria Fuertes, Ana María Matute, Elvira Lindo"),
        ("truco", "Perrault y los Grimm recogieron cuentos de la tradición oral; Andersen inventó los suyos."),
    ]),
]


def main():
    por_archivo = {}
    for comp, n, titulo, bloques in TARJETAS:
        archivo = ".".join(comp.split(".")[:2]) + ".json"
        b = [{"tipo": t, "contenido": c.replace(" · ", "\n") if t == "esquema" else c} for t, c in bloques]
        por_archivo.setdefault(archivo, []).append({"id": f"{comp}.{n}", "competencia": comp, "titulo": titulo, "bloques": b,
                                                     "procedencia": PROCEDENCIA, "validacion": VALIDACION})
    for archivo, nuevas in por_archivo.items():
        ruta = TEORIA / archivo
        actuales = json.loads(ruta.read_text(encoding="utf-8")) if ruta.exists() else []
        ids = {t["id"] for t in nuevas}
        ruta.write_text(json.dumps([t for t in actuales if t["id"] not in ids] + nuevas, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(TARJETAS)} tarjetas importadas en {len(por_archivo)} archivos")


if __name__ == "__main__":
    main()
