# 2026-09-20 — Reporte semanal ISO + métrica de cargas

## Summary

Análisis de tabla de control de gastos/ingresos del usuario (papel) vs. la app. La tabla cubre: gastos diarios (EE por día L-V), ventas de café/plátano, salarios, balance semanal y métrica "CAFÉ RECOJIDO ÷ 60". La app cubre ~95% de la tabla. Se implementaron los 2 gaps:

1. **Métrica de cargas** — conversión kg → cargas (1 carga ≈ 60 lbs ≈ 27.2 kg). Se muestra en la tarjeta de cosechas del reporte solo cuando hay café.
2. **Reporte semanal ISO** — nuevo período "Semana" (Lun-Dom) con navegación ← →, filtrado de datos, y soporte en exportación PDF/CSV.

## What happened

- `kgToCargas(kg)` en `lib/models/units.dart` — 1 carga = 60 lbs = 27.2155 kg, redondeo 2 decimales.
- `weekRange(year, week)`, `currentWeekNumber(date)`, `currentWeekRange()` en `lib/services/week_utils.dart` — algoritmo ISO 8601.
- `_PeriodMode.week` agregado a `report_screen.dart` — selector Semana|Mes|Año|A la fecha, navegación ← →, filtrado `_recordsFor`/`_periodHarvests`/`_previousMonthRecords` por semana.
- Cargas en `_builtHarvestCard`: si algún cultivo contiene "café"/"cafe", muestra "☕ cargas: X kg → Y cargas" con nota explicativa.
- `ReportPeriod.week` en `pdf_export_service.dart` y `excel_export_service.dart` — exportación con período semanal.
- Strings en `app_es.arb` y `app_en.arb`: `segWeek`, `reportPeriodWeek`, `reportChipWeek`, `harvestCargasLabel`, `harvestCargasNote`.
- Tests: `test/units_test.dart` (+4 kgToCargas), `test/week_utils_test.dart` (4 tests ISO week).

## State

| Item | Status |
|---|---|
| Tests | **170/170 verdes** |
| analyze | limpio (No issues found) |
| gh-pages | `91495b8`, HTTP 200 |
| main | `91495b8` |

## Key decisions (no revertir)

- 1 carga = 60 lbs = 27.2155 kg (convención cafetera colombiana).
- Semana ISO: Lun-Dom (no Lun-Vie como la tabla impresa).
- Cargas solo se muestran para cultivos con "café" en el nombre.
- Semana anterior (para comparación de tendencia) se calcula retrocediendo 1 semana.

## Pending

- [ ] Verificación manual: abrir reporte → seleccionar "Semana" → verificar que muestra la semana actual con datos correctos → exportar PDF/CSV con período semanal.
- [ ] Iteración futura: navegación por mes en semana (semana X de mes Y).

## Files

`lib/models/units.dart`, `lib/services/week_utils.dart`, `lib/screens/report_screen.dart`, `lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `test/units_test.dart`, `test/week_utils_test.dart`
