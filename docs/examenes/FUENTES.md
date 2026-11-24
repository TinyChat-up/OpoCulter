# Fuentes de los exámenes oficiales

Descargados por Claude Code el **23/11/2026** desde la web oficial de la Comunidad de Madrid. Los cuadernillos de la prueba común A1 (Lengua Castellana y Literatura + Matemáticas) del procedimiento selectivo de ingreso en el Cuerpo de Maestros. Fuente: **Comunidad de Madrid, Consejería de Educación (Dirección General de Recursos Humanos)**.

## 1. Archivos

| Archivo (`oficiales/`) | Convocatoria | URL de origen | SHA-256 |
|---|---|---|---|
| `2017_comun.pdf` | 2017 ordinaria (Resolución de 26/04/2017) | https://www.comunidad.madrid/docs/assets/2019/11/14/edu_rrhh_0371_2017_examen_comun.pdf | `037589e8…ca82e` |
| `2019_comun_ordinaria.pdf` | 2019 ordinaria | https://www.comunidad.madrid/docs/assets/2019/11/15/edu_rrhh_0371_2019_examen_prueba_comun.pdf | `8167fcd6…6309a` |
| `2019_comun_aplazada.pdf` | 2019 aplazada | https://www.comunidad.madrid/docs/assets/2019/11/15/edu_rrhh_0371_2019_examen_prueba_comun_aplazada.pdf | `582de714…c55540` |
| `2022_comun_ordinaria.pdf` | 2022 ordinaria | https://www.comunidad.madrid/docs/assets/2022/06/18/rh02_2122_prueba_comun.pdf | `91e3460d…93af85` |
| `2024_comun_ordinaria.pdf` | 2024 ordinaria | https://www.comunidad.madrid/docs/assets/2024/06/22/rh02_2324_prueba_comun.pdf | `5957853d…a87a15` |
| `2026_comun_ordinaria.pdf` | 2026 ordinaria | https://sede.comunidad.madrid/medias/examenes20261zip/download (ZIP "Exámenes 2026", archivo `Prueba Común (Parte A1)/Prueba_Comun_Maestros_2026.pdf`) | `2f6ad50f…997ad6` |
| `2026_comun_aplazada.pdf` | 2026 aplazada | https://www.comunidad.madrid/docs/2026-06/rh02_opo_prueba_comun_aplazada.pdf | `baedc582…c7c315` |
| `2026_plantillas_ordinaria.pdf` | Plantilla de corrección 2026 ordinaria | https://www.comunidad.madrid/docs/2026-08/rh02_plantillas_prueba_comun_ordinaria_26.pdf | `c68787ec…ad4f` |
| `2026_plantillas_aplazada.pdf` | Plantilla de corrección 2026 aplazada | https://www.comunidad.madrid/docs/2026-08/rh02_plantillas-prueba_comun_aplazada_26.pdf | `c38512f2…4edb481` |
| `2026_convocatoria_BOCM-20260212-7.pdf` | Convocatoria 2026: Resolución de 2 de febrero de 2026 de la Dirección General de Recursos Humanos (BOCM núm. 36, 12/02/2026, págs. 34–115) | https://www.bocm.es/boletin/CM_Orden_BOCM/2026/02/12/BOCM-20260212-7.PDF (descargado el 24/11/2026) | `d70b17f1…8e53886` |

Páginas índice consultadas: `comunidad.madrid/servicios/educacion/documentacion-procesos-selectivos-oposiciones-{2019,2022,2024}-maestros`, `comunidad.madrid/educacion/documentacion-procesos-selectivos-oposiciones-2026-maestros`, `comunidad.madrid/educacion/procesos-selectivos-oposiciones-2017-maestros` y `sede.comunidad.madrid/oferta-empleo/oposiciones-maestros-2026`.

**Sin publicar en la web oficial:** 2014, 2015, 2016, 2018, 2020, 2021, 2023 y 2025, y las aplazadas de 2017, 2022 y 2024. Para esos años no aparecen enlaces a cuadernillos. Las páginas de 2014–2016 ya no existen (404) y la de 2024 en la sede solo enlaza los informes de prácticas.

Extracción de texto: `swift scripts/extraer_examenes.swift` → `texto/*.txt`. Se usa la capa de texto del PDF y, en las páginas sin ella, OCR con Vision (es-ES). El cuadernillo de 2026 ordinaria se procesó entero con OCR (16 páginas). Hay errores de OCR evidentes ("pronomore", "T = 3,14" por π, números de página sueltos); se han corregido a mano en la matriz, no en los `.txt`, que se conservan tal cual. Algunos enunciados de Matemáticas son imágenes y no se extraen (2019 O nº 1 y 2024 O nº 2, ambos con fracciones; figuras de 2022 nº 5 y 10, 2024 nº 7 y 2026 O nº 7). La matriz lo indica.

## 2. Condiciones de reutilización

Texto literal del apartado «Propiedad intelectual y reproducción de contenidos» del aviso legal de comunidad.madrid (https://www.comunidad.madrid/atencion-ciudadano/aviso-legal-privacidad), consultado el **23/11/2026**:

> Los derechos de propiedad intelectual de este canal de Internet, el dominio www.comunidad.madrid, todos los subdominios, su diseño gráfico y los elementos de identidad que contiene, son titularidad de la Comunidad de Madrid. La Comunidad de Madrid permitirá la reutilización de todos los contenidos y datos difundidos por medio de este sitio, siempre que no se indique lo contrario, a condición de que no se altere el contenido de la información, no se modifique o desnaturalice el sentido de la información, se mencione la fuente, se indique la fecha de extracción o uso de la información, y no se pueda deducir que la Comunidad de Madrid patrocina o apoya la actividad en la que se reutiliza la información. Quedarán excluidos del derecho de reutilización aquellos contenidos que estén sujetos a propiedad intelectual o industrial, al régimen de protección de los datos personales o a otros derechos, bienes o intereses de acuerdo con lo que la legislación vigente establece.

**Avisos propios en los cuadernillos:** ninguno de los 9 PDF contiene un aviso de derechos reservados, "©" ni una prohibición de reproducción. Se ha buscado en el texto extraído de todas las páginas. Solo llevan el logotipo de la Comunidad de Madrid y, en 2026, la marca "EJEMPLAR PARA EL TRIBUNAL".

Consecuencias para el Modo Tribunal (a decidir por la dirección):
- **Reproducción literal**, sin alterar los enunciados. Hay que indicar la fuente ("Comunidad de Madrid, prueba común de Maestros AAAA, convocatoria …") y la fecha de extracción (23/11/2026).
- **Sin dar a entender patrocinio**: no se usarán el logotipo ni la identidad gráfica de la Comunidad de Madrid.
- **Quedan excluidos los textos de terceros con derechos vigentes** (tabla siguiente).

## 3. Textos literarios de los cuadernillos

Plazo de protección en España: 70 años tras la muerte del autor. Para autores fallecidos antes del 7/12/1987 rigen 80 años (disposición transitoria de la Ley de Propiedad Intelectual). La obra pasa al dominio público el 1 de enero siguiente.

| Cuadernillo | Texto | Autor (fallecimiento) | Situación en 2026 | ¿Se puede mostrar en la app? |
|---|---|---|---|---|
| 2017 O | *El monte de las ánimas* (fragmento) | Gustavo Adolfo Bécquer (1870) | Dominio público | Sí |
| 2019 O | *La voz a ti debida* («¡Si me llamaras, sí…!») | Pedro Salinas (1951) | **Protegido hasta el 31/12/2031** | **No** |
| 2019 A | *Nada* (fragmento) | Carmen Laforet (2004) | **Protegido hasta el 31/12/2074** | **No** |
| 2022 O | *La venganza de Don Mendo* (fragmento) | Pedro Muñoz Seca (1936) | Dominio público desde 2017 | Sí |
| 2024 O | Soneto «Desmayarse, atreverse, estar furioso…» | Lope de Vega (1635) | Dominio público | Sí |
| 2026 O | *Don Quijote*, II, cap. 58 (fragmento) | Miguel de Cervantes (1616) | Dominio público | Sí |
| 2026 A | «Canción de jinete» | Federico García Lorca (1936) | Dominio público desde 2017 | Sí |

Con 2019 O y 2019 A en Tribunal se podrían mostrar las preguntas que no dependen del texto, o el examen sin el texto citando dónde leerlo. Lo decide la dirección.

## 4. Penalización ortográfica en la prueba común A1 (convocatoria 2026)

Fuente: Resolución de 2 de febrero de 2026, de la Dirección General de Recursos Humanos, por la que se convoca proceso selectivo para ingreso en el Cuerpo de Maestros (BOCM núm. 36, de 12 de febrero de 2026; disposición BOCM-20260212-7). Se consultó el boletín completo (https://www.bocm.es/boletin/CM_Boletin_BOCM/2026/02/12/03600.PDF) y la disposición suelta, que se guarda en `oficiales/2026_convocatoria_BOCM-20260212-7.pdf`.

**Regla general**: Anexo V, apartado C) «Criterios generales de valoración de las pruebas de la fase de oposición», punto 1, «Criterios de valoración generales para las pruebas escritas en castellano». El epígrafe «ORTOGRAFÍA.» está al pie de la **pág. 96** y el texto, en la **pág. 97**. Texto literal:

> ORTOGRAFÍA.
>
> En todos los ejercicios escritos se aplicarán los siguientes criterios:
>
> — La escritura incorrecta de una palabra supone la disminución de la nota en 0,5 puntos.
>
> — Si la incorrección se debe a una tilde, la disminución será de 0,25 puntos.
>
> — La escritura de dos palabras como una sola supone una disminución de 0,25 puntos.
>
> — La división de una palabra en dos dentro de un renglón supone una disminución de 0,25 puntos.
>
> — La separación incorrecta de dos vocales de una palabra al cambiar de renglón supone la disminución de 0,25 puntos.
>
> — La utilización de abreviaturas para expresar palabras, nexos, pronombres, terminaciones de adverbios, del tipo "tb" por también, "pq" en vez de porque o por qué, "q" en lugar de que o qué, adverbios que terminan en mente y se utiliza la "barra inclinada" (/), etc., se penalizará con la disminución de 0,10 puntos.
>
> — Las faltas cometidas en palabras que se repiten se contabilizarán una sola vez.
>
> — Se detraerá puntuación por incorrecciones ortográficas, sin límite de ningún tipo, de la calificación obtenida por el aspirante en el correspondiente ejercicio calificado.
>
> — Estos criterios de corrección serán aplicados en todos los ejercicios escritos que realice el aspirante.

**Criterio específico de la A1** (pág. 102, especialidades de Educación Primaria, Audición y Lenguaje, Educación Física, Música y Pedagogía Terapéutica; el mismo texto figura en la pág. 109 para las de Lengua Extranjera): «PARTE A1. PRUEBA COMÚN. Esta prueba tiene una plantilla de corrección específica. Se valorará el rigor y exactitud en las respuestas.» No fija otra cifra de penalización ortográfica para la A1, así que **se aplica la regla general**: la convocatoria sí fija cifras (0,5 por palabra mal escrita, 0,25 por tilde, etc.) y sin límite.

**Ponderación de la A1** (pág. 52): «La calificación ponderada de esta parte se calculará multiplicando la nota obtenida en la parte A1 por 0,3». La parte A2 se multiplica por 0,7. Los cuadernillos de 2017 a 2026 recuerdan en su instrucción 8 o 9: «Las faltas de ortografía y las incorrecciones de acentuación restarán puntuación.»

