# Sesión — martes 20 de octubre de 2026 (datos sin mentira)

> Estado al cierre: **sin cambios de código**. Se revisó la app con casos
> reales, se dejaron los hallazgos y quedaron **PRD y plan** listos.
> Detalle: `docs/sessions/2026-10-20-datos-sin-mentira.md`.
> Análisis: `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md`.
> La vuelta anterior (el peso de la web) quedó en
> `docs/sessions/2026-10-20-peso-de-la-web.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`6ec6a23`**; `gh-pages` = **`2ae35e0`**.
- Gate: `flutter analyze` limpio · **1049/1049** tests.
- Sitio: https://miguelalbisortiz.github.io/cafecal/

## 2. Qué se hizo

Nada de código: cuatro preguntas de funcionamiento contestadas con el código y
una revisión que encontró **tres datos que hoy pueden mentir**:

- racimo y cajón cuentan como 1 kg (el peso se muestra pero no suma);
- el arrastre de la caja se recalcula con el aporte de hoy;
- las áreas de los cultivos no se comparan con el terreno.

Más cuatro cosas que confunden: kg/planta sin decir qué incluye, resiembra sin
muertas, caja como un solo pote y renovación sin explicar.

## 3. Lo que quedó listo

- **PRD APPROVED**: `docs/prds/2026-10-20_1426-datos-sin-mentira.prd.md`
  (puntos 1–5, 7, 8 y 9; el 6 queda fuera).
- **Plan READY**: `docs/plans/2026-10-20-datos-sin-mentira.plan.md`
  (T1–T14 en 4 fases, con tests, migraciones y verificación manual).

## 4. Decisiones

- Registros viejos sin peso: **excluir y listar**, sin inventar.
- Historial del aporte: **desde que se configura**.
- Ventas en racimo/cajón: **pedir los kg**.
- Gasto compartido: **porcentaje con atajo por área**.

## 5. Cómo continuar

1. **T1**: gate y baseline (sin tocar código). **T2**: helper `kgFromUnit` con
   rojo real.
2. Antes del deploy, aplicar las dos migraciones:
   `202610200001_add_transaction_equivalent_kg.sql` y
   `202610200002_add_settings_cash_budget_history.sql`.
3. Gate entero; stageo explícito; LF antes de commitear.

## 6. Pendientes heredados

- Verificación manual del peso de la web y de la tanda 2.
- Revocar el **PAT de Supabase**.
- Opcional: `flutter build apk`.
