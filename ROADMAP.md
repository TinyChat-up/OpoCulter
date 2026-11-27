# Hoja de ruta

| Fase | Nombre | Estado | Objetivo resumido |
|---|---|---|---|
| 00 | Preparación técnica | Terminada | Entorno verificado, repositorio y app mínima que compila, pasa tests y se ejecuta |
| 01 | Investigación | Completadas (integradas en el diseño v1) | Prueba A1 de Madrid, competencia y usuarios |
| 02 | Definición | Completadas (integradas en el diseño v1) | Alcance del MVP, requisitos y métricas de éxito |
| 03 | Diseño pedagógico y UX | Completadas (integradas en el diseño v1) | Modelo de aprendizaje, tipos de ejercicio y flujos |
| 04 | Arquitectura y núcleo | Terminada | Núcleo Swift testeado: contenido, validador, motor de aprendizaje, gamificación y persistencia |
| 05A | Sistema de diseño, mecánicas y ronda | Terminada | App jugable: Hoy, ronda, 10 mecánicas, feedback y resumen |
| 05A.1 | Pulido visual y lote 01 de contenido | Terminada | Recompensas y más peso táctil; 38 ítems y 5 tarjetas reales de LEN.ORT |
| 05B | Transformación premium: piloto vertical | Terminada | Sistema de diseño v2 "Laboratorio táctil", personajes «Tilde» y «Cuarto», 12 avatares, bienvenida, Hoy rediseñado, rondas por área, `colocarTilde` y `fraccionBarras`, contenido del piloto |
| 05C | Estilo Rubber Hose, avatares del propietario, generadores y matriz de exámenes | Terminada (estilo sustituido en la 05E parte 2, D-109) | Estilo "Rubber Hose moderno" con Fredoka; 6 avatares del propietario con migración; motor de 16 generadores paramétricos con dificultad 1–6, léxico y gramática generativa; catálogo de preguntas únicas; matriz de los exámenes oficiales A1 |
| 05D | Modos de juego | Terminada (fusionada en `main` en la recuperación, 25/11/2026) | Camino (prueba de nivel y Reto de bloque), Supervivencia, Rescate con pantalla propia, diagnóstico en la bienvenida, Progreso con Swift Charts, ajustes, sonido sintetizado y recordatorio local |
| Recuperación | Lote 02 e integración de las ramas de datos | Terminada (fusionada en `main`, 25/11/2026) | Lote 02 verificado con la 05D; base literaria, lote 03a (léxico y comprensión con textos base), lote 02b (frases y gramática con `compatibilidad.json`) y datos del Tribunal integrados y conectados |
| 05E parte 1 | Calidad y contenido | Terminada (fusionada en `main`, 25/11/2026) | Auditoría, mapa curricular de la A1 (21 bloques, 111 competencias), calibración «nivel examen» con 67 anclas, palabras ambiguas, naturalidad de la gramática y LEN.SIN, LEN.VER y LEN.LIT con 37 plantillas aprobadas |
| 05E parte 2 | Identidad, sesión diaria, errores y ejemplos resueltos | Terminada (fusionada en `main`, 26/11/2026) | Identidad sobria y editorial desde el logo v5; sesión diaria mixta (remedios, repaso y nuevo intercalados), meta semanal, modo descanso y racha sin culpa; motor de errores (93 errores) en la sesión, Rescate y Progreso; ejemplos resueltos con pasos y porqué en 15 generadores, gemelo, retirada de ayudas y «Nivel examen» |
| 05F | Motor literario | Adelantado en parte en la 05E (generador `literatura`, D-094) | Preguntas de literatura a partir de la base literaria; queda lo que la dirección decida (fragmentos, rasgos de los movimientos…) |
| 05G | Juegos: patrones y contrato de intento | Terminada (fusionada en `main`, 27/11/2026) | Orden de opciones barajado por sesión; 9 patrones configurados con datos; contrato de intento (pista, reintento, solución; dominio solo a la primera y sin ayudas) y variante sin ayudas a los 2 días; J46 «De evidencia a resumen» y J63 «Corta y compensa» en la sesión, Camino y Rescate |
| 05H | Lengua manipulativa sobre los patrones | Terminada (fusionada en `main`, 27/11/2026) | Rayos X (sintaxis por capas), Editor (detecta y corrige), Fábrica de palabras, recursos literarios con Detective y glosario; misiones retiradas; descanso en Hoy; «Hacer el diagnóstico»; inventario del lote 06 |
| 05I | Modo Tribunal y borrador táctil | Terminada (fusionada en `main`, 27/11/2026) | Exámenes oficiales completos, medio examen, simulacros según el plano y repaso; sala con cuenta atrás, mapa y borrador PencilKit; autoevaluación con rúbrica, nota orientativa, sello «Apto», informe y «Repasar ahora»; `AccesoTribunal` para la fase 06 |
| 05J | Tribunal v2 y cierre del lote 06 | Terminada (fusionada en `main`, 27/11/2026) | Examen escrito aparte de los juegos: muestra gratuita y 3 simulacros originales, en la app (reloj sin pausa, mapa, símbolos, borrador) o en PDF A4 (papel); corrección con 3 criterios en centésimas y penalización aparte; convocatorias anteriores (modo examen en 2017 y 2026 A); «Por bloques»; lote 06: 36 tarjetas, LEN.ORT.CTX y remedio estático |
| 05K | Siguiente fase | Pendiente | La define la dirección |
| Post-MVP | Editor de personalización del avatar | Pendiente | Hoy hay 12 avatares cerrados; el editor completo queda para después del MVP (D-054) |
| 06 | Monetización | Pendiente | Suscripción con StoreKit 2 y muro de pago |
| 07 | Calidad | Pendiente | Tests, accesibilidad, rendimiento, iOS 17 |
| 08 | TestFlight | Pendiente | Beta con usuarios reales |
| 09 | App Store | Pendiente | Bundle ID definitivo, ficha, privacidad y revisión |
| 10 | Lanzamiento y cobros | Pendiente | Publicación y acuerdos de pago |
| 11 | Optimización | Pendiente | Mejoras con datos de uso y opiniones |
| 12 | Expansión futura | Pendiente | Otras comunidades o pruebas |

**Después del MVP:** modo contrarreloj de Supervivencia (D-069), editor de avatar.

Estados posibles: Pendiente · En curso · Bloqueada · Terminada.

Las Fases 01–03 están integradas en [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md), aprobado por la dirección.
