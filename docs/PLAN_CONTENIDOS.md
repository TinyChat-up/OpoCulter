# PLAN DE CONTENIDOS — Cantidad, variedad, dificultad y legalidad

Fecha: 23/11/2026 · Autor: dirección · Estado: **aprobado**. Responde a la petición del propietario: "los ejercicios son muy iguales y hay pocos".

## 1. Diagnóstico honesto

- **Hasta ahora**: 59 ítems reales (LEN.ORT 50 y MAT.NUM 9). Es contenido de piloto: pocos ítems y con un patrón muy repetido ("Completa: «___»").
- **Problema de fondo**: escribir los ítems uno a uno no da para el volumen y la variedad que necesita una app de suscripción. Un usuario activo hace 30–60 ítems al día.
- **Solución**: tres fuentes de contenido combinadas.

## 2. Las tres fuentes

| Fuente | Qué es | Para qué | Legalidad |
|---|---|---|---|
| **A. Generadores paramétricos** | Plantillas que producen ítems con números o palabras distintos cada vez. La solución la **calcula el código**, así que nunca hay errores de solución. | Matemáticas casi entera (porcentajes, unidades, fracciones, m.c.m./m.c.d., romanos, operaciones, estadística, probabilidad, ecuaciones) y la parte "mecánica" de Lengua (tildes, sílabas, agudas/llanas/esdrújulas, a partir de un léxico validado). | Totalmente original. |
| **B. Banco curado** | Ítems redactados a mano por la dirección, en lotes. | Lo que no se puede generar: sintaxis, comprensión, literatura, recursos, léxico en contexto, justificaciones y problemas con contexto. | Original. Textos literarios solo de dominio público. |
| **C. Exámenes oficiales** | Las pruebas A1 publicadas por la Comunidad de Madrid, **reproducidas literalmente** en el Modo Tribunal. | Entrenamiento con el examen real. Además, sirven como base de la **matriz de frecuencias**. | La Comunidad de Madrid permite reutilizar los contenidos de su web si no se alteran, se cita la fuente y la fecha y no se da a entender su patrocinio. Quedan fuera los textos con derechos de terceros. |

**Por qué no "cambiar un poco" preguntas ajenas**: si el material es de una academia o una editorial, una versión retocada sigue siendo una obra derivada y está igual de protegida. Y las preguntas oficiales, por las condiciones de la Comunidad de Madrid, se pueden usar pero **sin alterarlas**. Por eso la estrategia es esta:
- **Lo oficial, literal y citado** (Tribunal).
- **Los tipos de pregunta** (que no tienen derechos) **convertidos en generadores y en ítems originales** (Camino, Supervivencia y Rescate).

Las academias, las editoriales y los resúmenes ajenos solo sirven como consulta, nunca como fuente.

## 3. Volumen objetivo: **30.000 preguntas únicas verificadas** en el lanzamiento (petición del propietario)

Una suscripción mensual necesita volumen. El referente es el de las apps de psicotécnicos, que rondan las 30.000 preguntas. Se cumple con **generación verificada**, no con relleno:
- Cada pregunta cuenta una sola vez: duplicados eliminados con una clave canónica.
- Todas tienen solución calculada o comprobada por código.
- Todas pasan el validador.

| Área | Fuente | Objetivo |
|---|---|---|
| Matemáticas | Generadores: porcentajes, unidades, fracciones, decimales, romanos (1–3999), operaciones combinadas, m.c.m./m.c.d., ecuaciones, estadística, probabilidad, proporcionalidad y geometría con figuras paramétricas | **≥ 20.000** |
| Lengua: acentuación y sílabas | Léxico de **≥ 2.500 palabras**. La sílaba tónica se deduce de la ortografía y del silabeo, con excepciones declaradas. Cada palabra da 3–4 ítems (colocar tilde, clasificar, sílaba tónica, justificar) | **≥ 6.000** |
| Lengua: sintaxis y morfología | **Gramática generativa controlada**: oraciones simples construidas a partir de piezas tipadas (sujeto, verbo, CD, CI, CC, atributo), con concordancia. El análisis correcto se conoce por construcción. Incluye conjugación de verbos regulares e irregulares (tabla) para el análisis verbal | **≥ 3.000** |
| Lengua: diacríticas, homófonos y porqués | Bancos de frases con hueco, cada una con su forma correcta y su familia de distractores | **≥ 1.000** |
| Banco curado | Literatura, comprensión, recursos, léxico en contexto, problemas con contexto y justificaciones, redactado a mano | **≥ 1.500** |
| Tribunal | Exámenes oficiales literales + simulacros originales | Todos los disponibles + 6 |

**Total ≥ 31.500.** La app muestra la cifra real, nunca una inventada: el contador sale del catálogo.

### Dificultad ampliada

Hay 6 niveles:
- **1–5**: de un paso a examen real.
- **6 "Experto"**: por encima del examen. Más pasos, números más grandes y trampas combinadas.

El nivel 6 aparece en Supervivencia avanzada y en los retos semanales. Cada generador declara cómo escalan sus parámetros con la dificultad, y un test comprueba que la complejidad crece de verdad con el nivel: número de pasos, magnitud de los números, distractores más cercanos a la solución.

## 4. Dificultad y niveles (ya implementado en el motor; aquí se fija cómo se usa)

- **Peldaño (1–5)**: el grado de autonomía (Descubre → Practica → Sin ayudas → Justifica → Formato examen). Cada competencia necesita ítems en los peldaños 1 a 4, y el 5 vive en Tribunal y en los Retos de bloque.
- **Dificultad (1–5)**: la complejidad dentro del peldaño, que los generadores controlan con parámetros:
  - 1: números pequeños, un solo paso.
  - 3: dos pasos o un distractor fuerte.
  - 5: varios pasos, contexto de problema y trampas típicas de examen.
- **Supervivencia**: la dificultad sube de 1 a 5 durante la partida, mezclando bloques.
- **Nivel del usuario (XP)**: es solo motivacional y no cambia la dificultad. La dificultad la decide el dominio real.
- **Reparto en una competencia**: 20 % peldaños 1–2 fáciles, 50 % dificultad media, 30 % difícil o tipo examen.

## 5. Variedad: reglas de redacción para la dirección

- No más de un 30 % de `eleccion` por bloque.
- Al menos un 25 % de mecánicas manipulativas (colocar, construir, segmentar, fracciones, cuadrícula…).
- Contextos variados en los problemas: compras, recetas, viajes, aula, deporte, mapas, horarios.
- Distractores basados en **errores reales**, documentados en `erroresHabituales`.
- Los "clásicos" que se repiten en los exámenes (por ejemplo, "el 20 % de un número es 12") se convierten en plantillas de generador.

## 6. Matriz de exámenes oficiales

La prepara Claude Code: descarga los PDF oficiales, extrae el texto (OCR) y clasifica cada pregunta (año, número, bloque, competencia y tipo). La dirección la usa para fijar las prioridades y el orden de los lotes. Se actualiza con cada convocatoria nueva.

## 7. Orden de producción de lotes

| Lote | Contenido |
|---|---|
| 02 | Léxico (primeras 800 palabras) + plantillas reales de MAT.POR, MAT.UNI, MAT.ROM, MAT.OPE, MAT.NUM |
| 02b | Léxico hasta 2.500 palabras + piezas de la gramática generativa (sustantivos, verbos con su régimen, complementos) + bancos de frases de diacríticas y homófonos |
| 03 | LEN.SIN (sintaxis) curado |
| 04 | MAT.GEO + MAT.DIV + MAT.EST + MAT.PRO |
| 05 | LEN.LIT + LEN.COM (textos de dominio público) |
| 06 | LEN.CLA + LEN.VER + LEN.LEX + LEN.FOR + LEN.REC + LEN.MET |
| 07 | Simulacros originales y exámenes oficiales del Tribunal |

Revisión de contenido: validador automático + tests de propiedades de los generadores (1.000 semillas por plantilla) + revisión de la dirección. El propietario puede revisar muestras si quiere.
