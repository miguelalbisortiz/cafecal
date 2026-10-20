# Sesión — martes 20 de octubre de 2026 (datos sin mentira)

> Estado al cierre: **sin cambios de código**. Se revisó el funcionamiento de
> la app con casos reales, se dejaron los hallazgos por escrito y quedaron
> **PRD y plan** listos para arrancar.
> Detalle del análisis: `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`6ec6a23`** (cierre documental del peso de la web).
- `gh-pages` = **`2ae35e0`**; sitio publicado con `main.dart.js` de 3.671.623 B.
- Gate vigente: `flutter analyze` limpio · **1049/1049** tests.
- Esta sesión no tocó `lib/`, ni tests, ni el sitio.

## 2. Qué se preguntó y qué se respondió

Cuatro casos reales, contestados con el código en la mano:

1. **Café de 5 años + plantines de reposición.** La resiembra ajusta plantas
   (vivas − muertas + nuevas) y no reinicia la edad. Los kilos son del cultivo,
   no de una mata. Los plantines que aún no producen **sí** entran al divisor
   del kg/planta.
2. **Venta del producto.** Si se midió en el jornal, manda esa medida; si no,
   los kg de la venta derivan la cosecha. El kg/planta es un promedio del
   cultivo, no de cada edad.
3. **8 ha con café, plátano, palta y maíz.** Se cosecha por producto y por
   pase; cada cultivo lleva su área (no las 8 ha), su cosecha y su venta. Un
   gasto compartido va al terreno y no entra al costo por kilo.
4. **Mano de obra fija y presupuesto mensual.** La caja menor arrastra el
   sobrante solo; es un solo pote (no hay presupuesto por tarea); el arrastre
   se recalcula con el aporte de hoy, no con el que regía cada mes.
5. **Finca que aún no produce / sembrar otro producto / cuándo la siembra pasa
   a ser dato del cultivo.** Al guardar la siembra se escriben plantas y área
   del cultivo; la edad se calcula; la fase pasa a producción con la primera
   cosecha posterior a la última siembra.

## 3. Lo que se encontró (y quedó en el análisis)

**Datos que hoy pueden mentir:**

- **Racimo y cajón cuentan como 1 kg.** `unitToKg` no los convierte; el peso
  del racimo (`equivalentKg`) se muestra pero no suma en ningún total, tampoco
  en ventas.
- **El arrastre de la caja se reescribe** con el aporte actual; configurarlo
  tarde inventa un sobrante pasado.
- **Las áreas no se comparan** con el terreno: si se repiten las 8 ha, el
  kg/ha sale mal sin aviso.

**Datos que confunden:**

- El kg/planta no dice que incluye plantas que aún no producen.
- La resiembra permite anotar nuevas sin muertas y diluye el promedio.
- La caja no explica que es un solo pote.
- La renovación completa no está explicada en la ayuda.

**Límites de modelo (no mentiras):** cohortes dentro de un cultivo, prorrateo
de gastos compartidos, presupuesto por tarea y asocio.

## 4. Decisiones del usuario

- Entran los puntos **1–5, 7, 8 y 9**; el **6 (cohortes) queda fuera** por
  merecer más análisis; asocio y presupuesto por tarea también quedan fuera.
- Registros viejos sin peso: **excluir y listar**, sin inventar.
- Historial del aporte: **desde que se configura**, sin reconstruir el pasado.
- Ventas en racimo/cajón: **pedir los kg**.
- Gasto compartido: **porcentaje con atajo por área**.

## 5. Artefactos de la sesión

- `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md` (hallazgos y
  cómo leer los indicadores).
- `docs/prds/2026-10-20_1426-datos-sin-mentira.prd.md` (**APPROVED**: SC-1 a
  SC-12, D1–D11, riesgos, impacto).
- `docs/plans/2026-10-20-datos-sin-mentira.plan.md` (**READY**: T1–T14 en 4
  fases, con tests, migraciones y verificación manual).

## 6. Cómo continuar

1. Arrancar por **T1** (gate y baseline, sin tocar código) y **T2** (helper
   `kgFromUnit` con rojo real).
2. Fase 1 completa: cosecha, venta, cosecha derivada, «sin peso» y paridad de
   PDF/Excel.
3. Antes del deploy, el usuario aplica las dos migraciones:
   `202610200001_add_transaction_equivalent_kg.sql` y
   `202610200002_add_settings_cash_budget_history.sql`.
4. Gate entero antes de commit y deploy; stageo explícito; LF.

## 7. Pendientes heredados

- Verificación manual del peso de la web (PDF/Excel reales y aviso sin señal).
- Revocar el PAT de Supabase (`docs/audits/2026-10-17-secretos-y-bloqueador.md`).
- Opcional: `flutter build apk`.
- Verificación manual de la tanda 2 (moneda, respaldo, banner, borrado, etc.).
