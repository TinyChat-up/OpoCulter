# Monetización

> **Propósito:** recoger el modelo de suscripción, los precios, la prueba gratuita y su implementación con StoreKit 2.
> **Fuente aprobada:** [docs/DISENO_PRODUCTO_v1.md](docs/DISENO_PRODUCTO_v1.md) §9 (**hipótesis**; la decisión final se toma en la Fase 06).
> No se crea ningún producto en App Store Connect sin autorización explícita.

## 1. Modelo
Suscripción mensual autorrenovable con prueba gratuita de 7 días.

## 2. Qué es gratis y qué es de pago
- **Gratis:** diagnóstico, el primer bloque completo de Lengua y de Matemáticas, Ortografía exprés (1 al día) y la racha.
- **Premium:** todo el contenido, Rescate ilimitado, simulacros, plan personalizado y estadísticas.

## 3. Precios y prueba gratuita
Rango a validar: 7,99–12,99 €/mes (Fase 06).

## 4. Implementación técnica (StoreKit 2)
El acceso premium se determinará con `Transaction.currentEntitlements`, sin backend ni cuentas (D-005). El núcleo de la Fase 04 no depende de StoreKit: la restricción de contenido se aplicará como un filtro sobre el banco en la Fase 06.

## 5. Pruebas (StoreKit Configuration y sandbox)
Requisito previo: membresía de pago de Apple Developer antes de la Fase 06.
