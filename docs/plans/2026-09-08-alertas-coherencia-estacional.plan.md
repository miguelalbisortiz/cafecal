# Plan: Alertas coherentes con la estacionalidad — A1 + C + B

- **Fecha**: 2026-09-08
- **PRD origen**: `docs/prds/2026-09-08-alertas-coherencia-estacional.prd.md`
- **Objetivo**: ajustar `AlertService` para eliminar falsas alarmas estacionales (R1),
  precisar el respaldo de R6 (excluir pérdidas) y cerrar el ciego de ventas sin
  cantidad con una alerta INFO nueva.

## Cambios

### F1 — A1: R6 excluye `pérdida`
- `lib/services/alert_service.dart` `_checkHarvestVsSales` (~l.355-361): al acumular
  `harvestedByCrop`, `continue` si `h.destination == HarvestDestination.perdida`.
- Sin cambios de strings.
- Tests: `test/alert_service_test.dart` (rojo→verde).

### F2 — C: R1 compara mismo mes calendario histórico
- `_checkExcessiveSpending` (~l.56-78):
  - `history` = gastos de la categoría con `t.date.month == currentMonth && t.date.year != now.year`.
  - `months` = conjunto de `(año,mes)` distintos; si `< 2`, **fallback** al promedio
    global actual (todos los meses históricos).
  - Umbral `current > 2 × avg` sin cambios.
- Sin cambios de strings.
- Tests: mismo mes recurrente no dispara; pico estacional puntual del mes histórico
  dispara según umbral; fallback con < 2 años mantiene la regla.

### F3 — B: regla INFO `missingQuantity`
- `lib/models/farm_alert.dart`: añadir `missingQuantity` al enum `AlertRule`.
- `alert_service.dart`: nueva `_checkMissingQuantity(active, now, l10n, out)`:
  ventas (`!type.isExpense && category.startsWith('venta_')`) en últimos 90 días con
  `quantity == null || quantity <= 0`; si `>= 3` → alerta INFO
  `id: 'missing_quantity'`, strings nuevos.
- Llamar desde `evaluate()`.
- i18n es/en: `alertMissingQtyTitle`, `alertMissingQtyMessage({count})`,
  `alertMissingQtySuggestion`.

## Verificación
- `flutter gen-l10n`, `flutter analyze`, `flutter test` (suite completa).
- Build release + deploy gh-pages (mismos pasos de siempre, HTTP 200).
- Snapshot `docs/sessions/` al cerrar la sesión.

## ACs (del PRD)
AC-1 pérdidas no respaldan ventas · AC-2 R1 mismo-mes + fallback · AC-3 alerta INFO
con contador · AC-4 enum serializa/renderiza INFO · AC-5 i18n+analyzer+suite verdes.

## Firmas
- Aprobado por el usuario (2026-09-08): alcance A1 + C + B.