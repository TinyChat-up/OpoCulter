# DISEÑO DE PRODUCTO v1 — Educulter (prueba común A1, Maestros de Madrid)

Fecha: 23/11/2026 · Autor: dirección del proyecto · Estado: **aprobado por la dirección**. Es la base de las Fases 04 y 05.

## 1. Promesa al usuario

"Domina la prueba de cultura general jugando: teoría y práctica de Lengua y Matemáticas en rondas de pocos minutos, casi sin escribir, y simulacros reales para llegar al examen seguro."

## 2. Modelo pedagógico

### 2.1 Estructura del contenido

Área (Lengua / Matemáticas) → Bloque (p. ej. Sintaxis) → **Competencia** (p. ej. "Identificar sujeto y predicado") → **Ítems** (ejercicios) + **Tarjetas de teoría**.

La competencia es la unidad de progreso, de repaso y de diagnóstico.

### 2.2 Escalera de dominio por competencia (regla fundamental)

| Peldaño | Qué hace el usuario | Ayudas |
|---|---|---|
| 1. Descubre | Tarjeta visual de teoría (máx. ~40 palabras, esquema y ejemplo) + 1–2 ítems guiados | Ejemplo resuelto, pistas |
| 2. Practica | Ítems táctiles de dificultad creciente | Pista disponible (cuesta XP) |
| 3. Sin ayudas | Ítems equivalentes sin pistas ni apoyos visuales | Ninguna |
| 4. Justifica | Construir la justificación con piezas (regla, categoría, motivo) | Ninguna |
| 5. Formato examen | Enunciado tal como en el examen; se resuelve en papel y se autocorrige con la rúbrica | Ninguna |

Se sube de peldaño con **4 aciertos en los 5 últimos intentos** del peldaño (configurable). Una competencia está **dominada** cuando supera los peldaños 3 y 4. El peldaño 5 se entrena en los simulacros.

### 2.3 Metodologías aplicadas

- **Práctica de recuperación**: casi todo es responder, no releer. La teoría es breve y va seguida de inmediato de ítems.
- **Repetición espaciada**: cajas de Leitner por competencia, con intervalos de 1, 3, 7, 14 y 30 días. Un fallo hace bajar dos cajas.
- **Práctica intercalada**: desde el peldaño 3, las rondas mezclan 2–3 competencias.
- **Ejemplos resueltos y retirada de ayudas**: los peldaños 1 → 3.
- **Retroalimentación explicativa**: cada distractor tiene su feedback específico (error habitual → por qué → regla), en una o dos líneas.
- **Aprendizaje a partir de errores**: los ítems fallados van a la cola de **Rescate**, que reaparece con variantes.
- **Metacognición**: antes de algunos ítems, "¿Cuánto de seguro estás?" con un toque (3 niveles). El panel de calibración enseña "te confías en X".
- **Transferencia**: peldaños 4–5 y simulacros con la rúbrica oficial 1/0,5/0.

Medición de utilidad: tasa de acierto en el peldaño 3 frente al 2, retención en los repasos (acierto en la caja ≥ 3), mejora entre el diagnóstico y el simulacro, y calibración de la confianza.

### 2.4 Diagnóstico inicial

Unos 20 ítems adaptativos (10 de Lengua y 10 de Matemáticas, uno por bloque prioritario), en unos 8 minutos. El resultado es un mapa de fortalezas y debilidades y un plan inicial que prioriza los bloques débiles con prioridad ★★★ (ver CONTENIDOS).

### 2.5 Sesiones

- **Ronda**: 6–8 ítems, 2–5 minutos. La compone el motor: repasos pendientes, competencia en curso, Rescate y un ítem intercalado.
- El usuario puede encadenar rondas (sesión larga) o hacer solo una.
- **Microentrenamiento de ortografía**: un bloque de 5 ítems de tildes y homófonos disponible siempre ("Ortografía exprés").

## 3. Catálogo de mecánicas (MVP: 10)

Ninguna usa el teclado del sistema.

| Id | Mecánica | Usos principales |
|---|---|---|
| `eleccion` | Elegir 1 de 2–4 tarjetas | Tema del texto, recurso literario, regla aplicada |
| `verdaderoFalso` | Deslizar izquierda/derecha (alternativa con botones) | Rapidez: definiciones, autores, propiedades |
| `clasificar` | Arrastrar fichas a 2–4 cajas | Clases de palabras, primitivas/derivadas/compuestas, agudas/llanas/esdrújulas |
| `ordenar` | Reordenar fichas (lista o línea del tiempo) | Autores cronológicamente, fracciones y decimales, pasos de una operación combinada |
| `emparejar` | Unir pares (término ↔ definición) | Terminología, autor ↔ obra, unidad ↔ equivalencia |
| `marcarTexto` | Tocar palabras o sílabas de un texto | Sílaba tónica, palabra con tilde, verbo, recurso |
| `segmentar` | Agrupar tramos de una oración o un verso y etiquetarlos | Sintaxis (sujeto, predicado, CD, CC, atributo), sílabas métricas, sinalefas |
| `ruedas` | 2–5 selectores giratorios | Análisis verbal (persona, número, tiempo, modo, voz), conversiones de unidades |
| `construir` | Encajar piezas en huecos | Formación de palabras, justificación ("lleva tilde porque…"), resumen con ideas clave |
| `numerico` | Teclado numérico propio (dígitos, coma, signo, fracción) | Resultados de Matemáticas |

Todas las mecánicas tienen alternativa accesible: VoiceOver con acciones personalizadas, y botones en lugar de arrastrar y deslizar.

## 4. Gamificación

Cada elemento justifica qué habilidad desarrolla, qué aprende el usuario y cómo detecta errores.

| Elemento | Regla | Justificación |
|---|---|---|
| XP | 10 por acierto, +5 sin ayuda, +10 en Justifica, 0 si se usa pista | Premia la autonomía y la justificación, no el tiempo en pantalla |
| Combo | Racha de aciertos dentro de la ronda (efecto visual, háptico y sonoro). Multiplicador máximo ×1,5 | Ritmo y atención sostenida |
| Niveles de usuario | Curva de XP suave | Sensación de progreso a largo plazo |
| Racha diaria 🔥 | Se mantiene con 1 ronda al día. **2 protectores al mes** automáticos y 1 extra por cada semana completa. Al romperla: "racha récord" + reto de recuperación de 3 días | Hábito sin castigo desproporcionado |
| Misiones diarias (3) | P. ej. "Rescata 3 errores", "1 ronda de Matemáticas", "Ortografía exprés" | Orientan hacia lo que más se necesita |
| Mapa de progreso | Dos rutas (Lengua y Matemáticas). Cada nodo es una competencia con un anillo de dominio. Al final de cada bloque hay un "Reto de bloque" (8 ítems en formato examen, sin ayudas) | Visión clara de lo que falta |
| Desbloqueo | Los nodos se abren en orden recomendado, pero el usuario puede saltar a cualquiera haciendo una "prueba de nivel" | Respeta a quien ya domina contenidos |
| Logros | ~20 logros educativos (primera sintaxis perfecta, 10 rescates, simulacro aprobado…) | Reconocen comportamientos útiles |
| Rescate de errores | Cola de ítems fallados con variantes. Rescatar da XP extra | Convierte los errores en aprendizaje |
| Modo supervivencia (v1.1) | Ítems mezclados de dificultad creciente, 3 vidas. Al terminar, los errores van a Rescate y se conserva el XP obtenido | Tensión lúdica sin perder progreso |
| Rankings (post-lanzamiento, opcionales) | Game Center | Solo para quien lo active |

## 5. Navegación y pantallas

Barra de pestañas con 4 entradas:

1. **Hoy**: botón grande "Empezar ronda" (recomendada), racha, misiones, Rescate pendiente y Ortografía exprés.
2. **Mapa**: selector Lengua/Matemáticas, ruta de nodos con anillos de dominio y Retos de bloque.
3. **Examen**: simulacros (10 + 10, 90 min). Muestra el enunciado y el cronómetro; el usuario responde en papel; al terminar ve la solución modelo y marca la rúbrica (Bien/Regular/Mal por pregunta); recibe una nota estimada y los errores se envían a Rescate.
4. **Progreso**: dominio por bloque, evolución, calibración, logros, ajustes, accesibilidad y suscripción.

Pantallas transversales: bienvenida (3 pantallas) → diagnóstico → plan; pantalla de ronda (ítem + barra de progreso + combo); feedback (correcto o incorrecto con explicación corta y "Ver regla"); resumen de ronda; tarjeta de teoría; paywall.

## 6. Dirección visual (decidida por la dirección)

Se han considerado tres direcciones:
- (A) "Cuaderno premium": papel cálido, tinta y acentos de rotulador.
- (B) "Arcade limpio": colores saturados y formas redondeadas.
- (C) "Calma enfocada": fondos neutros, un color por área y microanimaciones precisas.

**Elegida: C con toques de B en los momentos de recompensa.** Es adulta y legible para sesiones largas, y la energía se concentra en los combos y logros. Lengua usa tonos cálidos (coral) y Matemáticas tonos fríos (índigo/turquesa). Tipografía del sistema (SF Pro / SF Rounded en números y recompensas). Modo claro y oscuro. Se respetan "Reducir movimiento" y Dynamic Type hasta los tamaños de accesibilidad. El nombre comercial, el logotipo y la marca se deciden en la Fase 09.

## 7. Alcance del MVP

### Entra

- Bienvenida, diagnóstico y plan.
- Motor de aprendizaje: escalera, Leitner, intercalado y Rescate.
- Las 10 mecánicas.
- Tarjetas de teoría.
- Mapa con Retos de bloque.
- Hoy: misiones, racha con protectores, XP, niveles y ~20 logros.
- 3 simulacros completos originales con autocorrección por rúbrica.
- Ortografía exprés.
- Accesibilidad completa.
- Suscripción (StoreKit 2) con paywall.
- Contenido: bloques ★★★ completos y ★★ parciales (objetivo: ~350 ítems y ~60 tarjetas de teoría).

### Queda fuera (v1.1 o posterior)

Supervivencia, rankings y Game Center, widgets, notificaciones avanzadas (en el MVP solo hay un recordatorio diario opcional), iPad, sincronización con CloudKit (los modelos se diseñan ya compatibles con CloudKit) y otras comunidades.

## 8. Arquitectura (resumen)

- SwiftUI + Observation. **Núcleo en Swift puro y testable**, sin dependencias de UI:
  - `Core/Content`: modelos del banco, cargador de JSON y validador.
  - `Core/Learning`: dominio, escalera, Leitner, constructor de rondas y diagnóstico.
  - `Core/Progress`: persistencia SwiftData, con modelos compatibles con CloudKit: propiedades opcionales o con valor por defecto, sin `@Attribute(.unique)` y relaciones opcionales.
  - `Core/Gamification`: XP, racha, misiones y logros.
- Contenido empaquetado en `Content/` como JSON versionado (un archivo por bloque). **Solo se cargan en Release los ítems con `validacion.estado == "aprobado"`.**
- Sin backend, sin cuentas y sin SDKs de terceros. El acceso premium se determina con `Transaction.currentEntitlements`.

## 9. Monetización (hipótesis; la decisión final se toma en la Fase 06 tras estudiar precios)

- **Gratis**: diagnóstico, el primer bloque completo de Lengua y de Matemáticas, Ortografía exprés limitada (1 al día) y la racha.
- **Premium**: todo el contenido, Rescate ilimitado, simulacros, plan personalizado y estadísticas.
- Suscripción mensual con prueba gratuita de 7 días. Rango de precio a validar: 7,99–12,99 €/mes.
- Requisito previo: activar la membresía de pago de Apple Developer antes de la Fase 06, que necesita sandbox y App Store Connect.
