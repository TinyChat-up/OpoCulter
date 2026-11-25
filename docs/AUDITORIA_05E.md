# Auditoría de la Fase 05E (parte 1)

Fecha: 25/11/2026 · rama `fase-05e/calidad-contenido`. Todas las cifras salen de ejecutar código sobre el contenido de **Release** (solo aprobado): el arnés de los generadores vuelca los ítems estáticos y 20 variantes de cada plantilla aprobada, y `scripts/auditoria_05e.py` y `scripts/equivalencias_tribunal.py` hacen los recuentos.

## 1. Inventario

### Pantallas
Bienvenida, Hoy, Ronda (con texto base plegable), Revisión de ítems (Debug), Camino, Prueba de nivel y Reto de bloque, Supervivencia (inicio y fin de partida), Rescate, Diagnóstico y Plan, Progreso, Perfil, Ajustes y Créditos. Componentes compartidos: tarjeta de teoría con esquema, personajes (Tilde y Cuarto), avatares, teclado numérico propio y vista previa de mecánicas.

### Mecánicas (12) y uso en el contenido aprobado
Las 12 mecánicas tienen contenido aprobado.

| Mecánica | Ítems estáticos | Plantillas |
|---|---|---|
| eleccion | 39 | 17 |
| numerico | 0 | 24 |
| construir | 15 | 4 |
| clasificar | 9 | 8 |
| ordenar | 4 | 8 |
| emparejar | 11 | 3 |
| ruedas | 0 | 7 |
| marcarTexto | 4 | 4 |
| colocarTilde | 12 | 2 |
| segmentar | 0 | 2 |
| verdaderoFalso | 6 | 0 |
| fraccionBarras | 8 | 0 |

### Generadores (23 tipos)
- **Con plantillas aprobadas (19)**: porcentajeDe, reglaDeTres, conversionUnidades, sexagesimal, escala, ordenarNumeros, fraccionesOperar, problemaFraccion, operacionesCombinadas, ecuacionLineal, romanos, colocarTilde, clasificarAcentuacion, silabaTonica, fraseHueco, oracionSimple, analisisVerbal y, nuevos en la 05E, formasNoPersonales y literatura.
- **Solo en borrador (4)**: fraccionBarras, mcmMcd, estadisticaBasica y probabilidadSimple. Motivo: son plantillas de prueba de la Fase 05C; el contenido real de MAT.DIV, MAT.EST y MAT.PRO (y la plantilla de FRAREP) llega en su lote. Su nivel 4 ya tiene el perfil del examen (ver §3), así que se pueden aprobar en cuanto la dirección lo decida.
- **Otras plantillas en borrador** de generadores aprobados: LEN.CLA.SUSTADJ.G01, LEN.SIN.COMPL.G01–G02 y LEN.VER.ANALISIS.G01 (pruebas de la 05C, sustituidas por las de la 05E).

### Tarjetas de teoría
15 aprobadas: LEN.COM (TEMA, RESU, TIPO, PROP), LEN.LEX (SIN, POLI, CAMPO, DICC), LEN.ORT (AGU, DIA, HIA, PQ, HOM) y MAT.NUM (FRAREP, FRAEQ). En borrador: LEN.SIN.SUJPRED.T01 y MAT.OPE.FRACSUM.T01.

### Tests por módulo
Unitarios (Swift Testing), 213 funciones en 17 archivos: Aprendizaje 23, Generadores 23, Piloto 22, Modos 21, Gamificación 17, Validador 13, Fase 05E 12, Sesión 11, Evaluador 10, RondaViewModel 10, Común 9, Contenido 9, Textos y literatura 7, Progreso 7, Frases con hueco 4, Gramática 4 y Anclas 2 (muchas, parametrizadas: 1000 semillas por plantilla y nivel). Interfaz (XCTest), 17 en 6 archivos: Modos 5, Rendimiento 5, Piloto 3, Ronda 2, Comprensión 1 y Recorrido 1.

### Deuda técnica conocida
- No hay `TODO`, `FIXME` ni avisos suprimidos. Hay dos `@unchecked Sendable` justificados en la caché y el recuento paralelo de `CatalogoPreguntas` (protegidos con `NSLock`).
- **Código casi muerto**: la vía de `oracionSimple` sin `compatibilidad.json` (solo `piezas.json`) ya no se usa en la app; `piezas.json` solo la alimenta. Se conserva por los tests de recursos pequeños.
- **Contenido de prueba de la 05A–05C en borrador** (ítems estáticos de LEN.SIN, LEN.VER, LEN.CLA, LEN.LIT, LEN.REC, MAT.GEO, MAT.OPE…): solo se cargan en Debug. Conviene retirarlos cuando llegue su lote.
- **13 competencias antiguas** con `equivaleA`: se conservan por el progreso guardado.
- El recuento de preguntas de los espacios grandes es una cota inferior (muestreo), como desde la 05C.

## 2. Cobertura del mapa curricular

Criterio: **completa** = 5 peldaños, al menos 3 dificultades y tarjeta de teoría; **parcial** = algo de contenido; **vacía** = nada. Las antiguas con `equivaleA` suman a su competencia del mapa. Peldaños y dificultades son los declarados por los ítems y las plantillas (Supervivencia y los Retos generan además los niveles 1–6 de cada plantilla).

| Bloque | Completas | Parciales | Vacías |
|---|---|---|---|
| LEN.SIN | 0 | 3 | 3 |
| LEN.ORT | 0 | 5 | 3 |
| LEN.CLA | 0 | 0 | 4 |
| LEN.VER | 0 | 2 | 2 |
| LEN.LIT | 0 | 4 | 2 |
| LEN.COM | 0 | 7 | 0 |
| LEN.REC | 0 | 0 | 2 |
| LEN.MET | 0 | 0 | 3 |
| LEN.LEX | 0 | 8 | 0 |
| LEN.FOR | 0 | 0 | 5 |
| LEN.HAB | 0 | 0 | 5 |
| MAT.UNI | 0 | 5 | 2 |
| MAT.GEO | 0 | 0 | 9 |
| MAT.POR | 0 | 4 | 1 |
| MAT.NUM | 0 | 5 | 4 |
| MAT.DIV | 0 | 0 | 5 |
| MAT.OPE | 0 | 3 | 3 |
| MAT.ROM | 0 | 2 | 0 |
| MAT.EST | 0 | 0 | 4 |
| MAT.PRO | 0 | 0 | 3 |
| MAT.ALG | 0 | 0 | 3 |
| **Total** | **0** | **48** | **63** |

**Ninguna competencia está completa**: LEN.SIN.SUJPRED, LEN.VER.ANALISIS y LEN.VER.NOPERS tienen los 5 peldaños y 5 dificultades, pero no tienen tarjeta de teoría aprobada.

| Competencia | Estáticos | Plantillas | Peldaños | Dificultades | Teoría | Pistas (1–2) | Estado |
|---|---|---|---|---|---|---|---|
| LEN.SIN.SUJPRED | 0 | 5 | 1,2,3,4,5 | 1,2,4,5,6 | no | sí | parcial |
| LEN.SIN.COMPL | 0 | 5 | 1,2,3,4,5 | 2,3,4 | no | sí | parcial |
| LEN.SIN.CLASE | 0 | 3 | 2,3,5 | 2,4,5 | no | sí | parcial |
| LEN.ORT.AGU | 21 | 4 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.ORT.DIA | 9 | 1 | 1,2,3,4 | 1,2,3,4 | sí | sí | parcial |
| LEN.ORT.HIA | 6 | 0 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.ORT.PQ | 6 | 1 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.ORT.HOM | 8 | 2 | 1,2,3,4 | 1,2,3,4 | sí | sí | parcial |
| LEN.VER.ANALISIS | 0 | 5 | 1,2,3,4,5 | 1,2,3,4,5 | no | sí | parcial |
| LEN.VER.NOPERS | 0 | 5 | 1,2,3,4,5 | 1,2,3,4,5 | no | sí | parcial |
| LEN.LIT.GEN | 0 | 3 | 1,3,5 | 1,3,5 | no | sí | parcial |
| LEN.LIT.HIST | 0 | 5 | 1,2,3,5 | 1,2,3,4 | no | sí | parcial |
| LEN.LIT.UNIV | 0 | 3 | 2,3,5 | 2,3,4 | no | sí | parcial |
| LEN.LIT.INF | 0 | 3 | 2,3,4 | 2,3,4 | no | sí | parcial |
| LEN.COM.SITU | 1 | 0 | 1 | 1 | no | sí | parcial |
| LEN.COM.TEMA | 4 | 0 | 1,2,3 | 1,2,3 | sí | sí | parcial |
| LEN.COM.RESU | 4 | 0 | 2,3,4 | 2,3 | sí | sí | parcial |
| LEN.COM.INFER | 3 | 0 | 2,3 | 2,3,4 | no | no | parcial |
| LEN.COM.TIPO | 4 | 0 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.COM.PROP | 2 | 0 | 3 | 2,3 | sí | no | parcial |
| LEN.COM.GEN | 1 | 0 | 2 | 2 | no | no | parcial |
| LEN.LEX.SIN | 7 | 0 | 1,2,3,4 | 1,2,3,4 | sí | sí | parcial |
| LEN.LEX.POLI | 6 | 0 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.LEX.CAMPO | 5 | 0 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.LEX.CTX | 3 | 0 | 2,3 | 2,3,4 | no | sí | parcial |
| LEN.LEX.DICC | 5 | 0 | 1,2,3,4 | 1,2,3 | sí | sí | parcial |
| LEN.LEX.REG | 2 | 0 | 2,3 | 2 | no | no | parcial |
| LEN.LEX.DEN | 1 | 0 | 3 | 3 | no | no | parcial |
| LEN.LEX.FRAS | 1 | 0 | 2 | 2 | no | no | parcial |
| MAT.UNI.LMC | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |
| MAT.UNI.SUP | 0 | 1 | 3 | 3 | no | no | parcial |
| MAT.UNI.VOL | 0 | 1 | 3 | 3 | no | no | parcial |
| MAT.UNI.TIEM | 0 | 3 | 2,3,4 | 2,3,4 | no | sí | parcial |
| MAT.UNI.ESC | 0 | 2 | 3,4 | 3,4 | no | no | parcial |
| MAT.POR.CALC | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |
| MAT.POR.TOTAL | 0 | 1 | 3 | 3 | no | no | parcial |
| MAT.POR.VAR | 0 | 2 | 3,4 | 3,4 | no | no | parcial |
| MAT.POR.PROP | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |
| MAT.NUM.FRAREP | 4 | 0 | 1,2,3 | 1,2 | sí | sí | parcial |
| MAT.NUM.FRAEQ | 5 | 0 | 2,3,4 | 2,3 | sí | sí | parcial |
| MAT.NUM.ORDEN | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |
| MAT.NUM.FRAOP | 0 | 3 | 2,3,4 | 2,3,4 | no | sí | parcial |
| MAT.NUM.FRAPROB | 0 | 2 | 3,4 | 3,4 | no | no | parcial |
| MAT.OPE.ECUAC | 0 | 3 | 2,3,4 | 2,3,4 | no | sí | parcial |
| MAT.OPE.JER | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |
| MAT.OPE.COMB | 0 | 2 | 3,4 | 3,4 | no | no | parcial |
| MAT.ROM.LEER | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |
| MAT.ROM.ESCR | 0 | 2 | 2,3 | 2,3 | no | sí | parcial |

**Vacías (63)**: LEN.SIN.SINT, LEN.SIN.MODAL, LEN.SIN.COMP, LEN.ORT.LET, LEN.ORT.PUNT, LEN.ORT.MAY, LEN.CLA.VAR, LEN.CLA.INV, LEN.CLA.ADJGRAD, LEN.CLA.JUST, LEN.VER.IRREG, LEN.VER.VOZ, LEN.LIT.OBRA, LEN.LIT.POP, LEN.REC.FIG, LEN.REC.DEF, LEN.MET.MED, LEN.MET.RIMA, LEN.MET.ESTR, LEN.FOR.ESTR, LEN.FOR.DER, LEN.FOR.COMP, LEN.FOR.CLAS, LEN.FOR.SIGL, LEN.HAB.ORIG, LEN.HAB.RAE, LEN.HAB.LENESP, LEN.HAB.SIGNOS, LEN.HAB.NODISC, MAT.UNI.ANG, MAT.UNI.ESTIM, MAT.GEO.CLAS, MAT.GEO.CUER, MAT.GEO.ANG, MAT.GEO.PER, MAT.GEO.AREA, MAT.GEO.VOL, MAT.GEO.CART, MAT.GEO.MOV, MAT.GEO.SEMEJ, MAT.POR.FIN, MAT.NUM.TIPOS, MAT.NUM.VALPOS, MAT.NUM.EQUIV, MAT.NUM.ENT, MAT.DIV.MCD, MAT.DIV.REGLAS, MAT.DIV.MULDIV, MAT.DIV.PRIMOS, MAT.DIV.MCM, MAT.OPE.POT, MAT.OPE.RAIZ, MAT.OPE.MENTAL, MAT.EST.CENTRAL, MAT.EST.FREC, MAT.EST.GRAF, MAT.EST.POBL, MAT.PRO.LAPLACE, MAT.PRO.SUCESOS, MAT.PRO.RECUENTO, MAT.ALG.PATR, MAT.ALG.IGUAL, MAT.ALG.ALGO.

**Con contenido y sin tarjeta de teoría (33; las redacta la dirección)**: LEN.SIN.SUJPRED, LEN.SIN.COMPL, LEN.SIN.CLASE, LEN.VER.ANALISIS, LEN.VER.NOPERS, LEN.LIT.GEN, LEN.LIT.HIST, LEN.LIT.UNIV, LEN.LIT.INF, LEN.COM.SITU, LEN.COM.INFER, LEN.COM.GEN, LEN.LEX.CTX, LEN.LEX.REG, LEN.LEX.DEN, LEN.LEX.FRAS, MAT.UNI.LMC, MAT.UNI.SUP, MAT.UNI.VOL, MAT.UNI.TIEM, MAT.UNI.ESC, MAT.POR.CALC, MAT.POR.TOTAL, MAT.POR.VAR, MAT.POR.PROP, MAT.NUM.ORDEN, MAT.NUM.FRAOP, MAT.NUM.FRAPROB, MAT.OPE.ECUAC, MAT.OPE.JER, MAT.OPE.COMB, MAT.ROM.LEER, MAT.ROM.ESCR.

## 3. Cobertura del examen real

Equivalencia completa en `Content/tribunal/equivalencias.json`. «Sí»: contenido aprobado que ejercita la misma destreza; «parcial»: hay contenido de la competencia, pero el examen pide redactar, definir o justificar y la app pide reconocer, o faltan rasgos (verbos irregulares, complemento predicativo…).

| | Sí | Sí + parcial | Preguntas |
|---|---|---|---|
| **Total** | **33,1 %** | **63,3 %** | 139 |
| Lengua | 18,8 % | 71,0 % | 69 |
| Matemáticas | 47,1 % | 55,7 % | 70 |
| 2017 ordinaria | 47 % | 79 % | 19 |
| 2019 aplazada | 35 % | 70 % | 20 |
| 2019 ordinaria | 40 % | 65 % | 20 |
| 2022 ordinaria | 30 % | 65 % | 20 |
| 2024 ordinaria | 15 % | 55 % | 20 |
| 2026 aplazada | 40 % | 65 % | 20 |
| 2026 ordinaria | 25 % | 45 % | 20 |

Competencias vacías con más preguntas oficiales: MAT.GEO.VOL 5, MAT.EST.CENTRAL 5 (plantilla en borrador), MAT.GEO.AREA 4, LEN.REC.DEF 4, LEN.FOR.DER 3, y con 2: MAT.DIV.MCM, LEN.CLA.ADJGRAD, MAT.PRO.LAPLACE (borrador), LEN.REC.FIG y MAT.EST.FREC (empatadas con MAT.OPE.POT y MAT.PRO.SUCESOS).

## 4. Enseñanza

Sobre Release: 108 ítems estáticos y una muestra de 1580 generados (20 por plantilla aprobada).

| | Estáticos | Generados | Todos |
|---|---|---|---|
| Con explicación | 100 % | 100 % | 100 % |
| Con errores habituales | 45 % | 73 % | 71 % |
| Con pistas (peldaños 1–2) | 69 % | 90 % | 89 % |
| Explicación con el porqué (marcas de regla o causa) | 63 % | 59 % | 59 % |

El porqué se mide con marcas en el texto (regla, causa, definición o equivalencia); es una aproximación, y la revisión a mano de 20 ítems (abajo) la confirma en líneas generales: las explicaciones de Matemáticas muestran los pasos, pero pocas dicen **por qué** se hace así.

### 20 ítems al azar (semilla 2026), una línea cada uno
Los 20 son correctos (respuesta y explicación). 8 explican el porqué, 8 muestran el procedimiento sin justificarlo y 4 dan solo la solución.

1. LEN.LIT.UNIV.G02#15 · siglo de «Crimen y castigo»: correcto; explica el rango del siglo (porqué).
2. LEN.SIN.COMPL.G03#6 · función de «La alumna»: correcto; da la regla de la concordancia (porqué). Muy fácil en el nivel 1 (sujeto al principio).
3. MAT.NUM.ORDEN.G02#1 · ordenar 5 decimales: solo la solución; cómo comparar está en el error habitual, no en la explicación.
4. MAT.NUM.FRAOP.G01#0 · 1/2 + 5/6: solo la solución; no muestra el denominador común.
5. MAT.POR.CALC.G02#17 · 40 % de 155: procedimiento (155 × 40 : 100) sin decir por qué.
6. LEN.LIT.UNIV.G01#2 · autor ↔ obra: correcto; la explicación es el dato con su año (no hay porqué que dar).
7. LEN.ORT.AGU.G04#9 · sílaba tónica de «jugar»: correcto; indica la tónica (porqué), podría añadir por qué no lleva tilde.
8. MAT.OPE.ECUAC.G01#2 · 9x = 45: solución y comprobación, sin el paso (dividir entre 9).
9. MAT.OPE.ECUAC.G03#4 · 8x + 4 = x + 109: igual, sin la transposición; no tiene errores habituales.
10. MAT.NUM.FRAPROB.G02#11 · tres gastos sucesivos: procedimiento paso a paso, claro.
11. LEN.VER.ANALISIS.G04#13 · «dibujasteis»: análisis completo y explica el aspecto (porqué).
12. MAT.UNI.TIEM.G01#16 · 3 h 11 min en segundos: da las equivalencias (porqué), pero no la cuenta (3 × 3600 + 11 × 60).
13. MAT.OPE.JER.G02#4 · ordenar los pasos: regla de la jerarquía y pasos (porqué).
14. MAT.NUM.FRAPROB.G01#13 · dos gastos: procedimiento paso a paso.
15. MAT.ROM.ESCR.G02#8 · 613 en romanos: descomposición por órdenes (porqué).
16. MAT.UNI.TIEM.G01#2 · 2 h 9 min en segundos: como el 12.
17. MAT.UNI.VOL.G01#5 · 32 dal en cm³: da la equivalencia 1 dm³ = 1 l, pero no la cadena dal → l → cm³; solo solución en la práctica.
18. LEN.VER.NOPERS.G05#17 · clasificar 6 formas: clasifica cada una; la regla está en la pista, no en la explicación; sin errores habituales.
19. MAT.UNI.LMC.G02#10 · 2 kl 93 dl en cl: conversión de cada término (procedimiento).
20. MAT.UNI.VOL.G01#15 · 51 dm³ en litros: correcto pero trivial para su dificultad 3 (un solo paso, 1 dm³ = 1 l).

**Conclusión**: la app explica siempre, pero en Matemáticas explica «cómo» más que «por qué», y hay generadores sin errores habituales en algunos casos (ecuaciones del nivel 4, formas no personales). Es materia de la parte 2 (ejemplos resueltos).

## 5. Accesibilidad y rendimiento

Solo lo nuevo respecto al informe de la recuperación.

- **Auditoría de accesibilidad** (`performAccessibilityAudit`, todas las categorías): sin incidencias en las pantallas auditadas, también en las rondas nuevas de LEN.SIN, LEN.VER y LEN.LIT (simulador y **iPhone físico**).
  - En el iPhone, la primera ejecución marcó contraste en la cabecera de la ronda (contador de XP, combo y nombre de la competencia) porque se auditó durante la transición de entrada; auditando con la pantalla quieta no hay incidencias.
  - **Progreso (§4.3)**: con `ViewThatFits`, la auditoría daba **«Dynamic Type font sizes are partially unsupported»** sobre el **nombre del área** («Matemáticas», StaticText) y su **porcentaje** («1 %»): son los textos de la variante que no se muestra, y no desaparecían del árbol ni ocultándolos a VoiceOver. Se usa la disposición según el tamaño de texto (horizontal, con el porcentaje con prioridad de diseño para que no se parta; con texto de accesibilidad, el porcentaje debajo). Así pasa la auditoría, incluida la comprobación de Dynamic Type.
- **Ruedas**: el análisis verbal completo muestra 6 selectores en vertical (antes, como mucho 5).
- **Rendimiento**:
  - Arranque en frío en el iPhone (Debug, 5 iteraciones): **0,87 s** de media (0,81–0,92), por debajo del objetivo de 1,5 s, pero por encima de los 0,67 s de la recuperación. La causa: al cargar el banco se generan 12 variantes de cada plantilla, y ahora hay 79 en lugar de 42.
  - La primera medida dio 0,95 s porque `analisisVerbal` recalculaba el paradigma entero en cada muestra; con la caché por nivel, la carga del banco en Debug (Mac) bajó de 0,96 s a 0,26 s.
  - Mejora propuesta para una fase posterior: generar esas variantes bajo demanda.
  - Fluidez en el simulador: colocarTilde 2,1 s y dividir la barra 7,4 s por iteración de la medida (con la instrumentación de cobertura); sin cambios en esas mecánicas.
