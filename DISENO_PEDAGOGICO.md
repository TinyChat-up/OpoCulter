# Diseño pedagógico

> **Propósito:** definir cómo aprende el usuario: diagnóstico, progresión, repaso y evaluación.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§2 y §4). Este documento resume y enlaza; si hay discrepancia, manda el original.
> **Implementación:** [Core/Learning](Educulter/Core/Learning) y [Core/Gamification](Educulter/Core/Gamification) (Fase 04).

## 1. Objetivos de aprendizaje
Área → Bloque → **Competencia** → Ítems + Tarjetas de teoría. La competencia es la unidad de progreso, repaso y diagnóstico (original §2.1). Catálogo de bloques en [CONTENIDOS.md](CONTENIDOS.md#1-temario-de-referencia-prueba-a1-madrid).

## 2. Diagnóstico inicial
Unos 20 ítems adaptativos, uno por bloque ★★★ (original §2.4). Reglas implementadas ([Diagnostico.swift](Educulter/Core/Learning/Diagnostico.swift), D-028):
- Primer ítem de cada bloque con dificultad cercana a 2, de los peldaños 2–4; las áreas se alternan.
- Si se acierta, se añade uno de mayor dificultad (máximo 2 por bloque).
- Nivel del bloque: 0 (falla el primero), 0,5 (acierta el primero y falla el difícil) o 1.
- Plan inicial: bloques con contenido ordenados por **debilidad × prioridad**; los no evaluados cuentan con debilidad 0,5.

## 3. Modelo de personalización
- **Escalera de dominio** (original §2.2): se sube con 4 aciertos en los 5 últimos intentos *del peldaño actual* (configurable, también por peldaño). Dominada = superados los peldaños 3 y 4 (peldaño 5 alcanzado). D-024.
- **Leitner por competencia**: cajas 1–5 con intervalos de 1, 3, 7, 14 y 30 días; acierto +1 caja, fallo −2 (mínimo 1). Cuenta el primer intento de un día en que la competencia está vencida. D-023.
- **Rescate**: un fallo se rescata acertando otro ítem de la misma competencia y peldaño (o el mismo si no hay variante).
- Las fechas son días civiles del usuario (D-021).

## 4. Tipos de ejercicio
Las 10 mecánicas del original §3, sin teclado del sistema. Esquema de datos y corrección en [CONTENIDOS.md §2.4](CONTENIDOS.md#24-payload-por-mecánica); evaluadores en [Evaluador.swift](Educulter/Core/Learning/Evaluador.swift), con acierto parcial (`fraccionCorrecta`) para el feedback.

## 5. Rondas y sesiones
Ronda de 6–8 ítems (original §2.5). Prioridad: repasos vencidos (máx. 3) → Rescate (máx. 2) → competencia en curso en su peldaño, por dificultad creciente → 1 ítem intercalado de otra competencia en peldaño ≥ 3. No se repiten ítems vistos en 24 h si hay alternativa. El peldaño 5 no entra en rondas: se entrena en simulacros y Retos de bloque. D-025.

## 6. Gamificación y motivación
Original §4. Valores implementados (D-026, D-027):
- XP: 10 por acierto, +5 sin pista, +10 en Justifica, +5 al rescatar; 0 con pista. Combo ×(1 + 0,1·(n−1)) hasta ×1,5.
- Niveles: XP acumulada para el nivel n = 100·(n−1)^1,5.
- Racha: 1 ronda al día; 2 protectores que se reponen el día 1 de cada mes y +1 por cada 7 días activos seguidos (máximo 3). Se guarda el récord.
- 3 misiones diarias según el estado (Rescate o repasos, área más débil, variedad) y motor de logros por reglas (5 de ejemplo; ~20 en la Fase 05).

## 7. Modo simulacro
10 + 10 preguntas, 90 minutos, en papel y autocorrección con la rúbrica 1/0,5/0 (original §5.3). Formato de datos en [CONTENIDOS.md §2.8](CONTENIDOS.md#28-simulacro).

## 8. Retroalimentación y errores
Cada distractor tiene su feedback (error habitual → por qué → regla) en `erroresHabituales`; la explicación general tiene 280 caracteres como máximo. Correspondencia entre errores y feedback en [CONTENIDOS.md §2.5](CONTENIDOS.md#25-errores-habituales-y-resultadoerrores).
