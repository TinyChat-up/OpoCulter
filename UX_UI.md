# UX y UI

> **Propósito:** recoger la arquitectura de información, los flujos, el sistema visual y los criterios de accesibilidad.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) (§1, §3, §5 y §6). Este documento resume y enlaza; si hay discrepancia, manda el original.
> **Estado:** la interfaz de producto se construye en la Fase 05. En la Fase 04 solo existe la pantalla de verificación.

## 1. Principios de experiencia
Promesa (original §1): rondas de pocos minutos, casi sin escribir, y simulacros reales. Sin teclado del sistema en el aprendizaje diario.

## 2. Arquitectura de información y navegación
Barra de pestañas con 4 entradas (original §5): **Hoy**, **Mapa**, **Examen** y **Progreso**.

## 3. Flujos principales
Bienvenida (3 pantallas) → diagnóstico → plan; ronda (ítem + progreso + combo) → feedback → resumen; tarjeta de teoría; simulacro con cronómetro y rúbrica; paywall (original §5).

## 4. Sistema visual
Dirección **C "Calma enfocada" con toques de B en las recompensas** (original §6): fondos neutros, Lengua en coral y Matemáticas en índigo/turquesa, SF Pro / SF Rounded, modo claro y oscuro. Marca y logotipo: Fase 09.

## 5. Componentes de interacción
Las 10 mecánicas del original §3 (tocar, arrastrar, deslizar, ruedas, piezas y teclado numérico propio con dígitos, coma, signo y fracción). El teclado numérico produce el texto que interpreta el núcleo ([CONTENIDOS.md §2.4.2](CONTENIDOS.md#242-numérico)).

## 6. Accesibilidad
VoiceOver con acciones personalizadas y botones como alternativa a arrastrar y deslizar en todas las mecánicas; Dynamic Type hasta tamaños de accesibilidad; Reducir movimiento; contraste.

## 7. Microcopias y tono
Español de España. Los títulos de misiones ya están en el núcleo ([Misiones.swift](Educulter/Core/Gamification/Misiones.swift)) y se extraerán al String Catalog en la Fase 05.
