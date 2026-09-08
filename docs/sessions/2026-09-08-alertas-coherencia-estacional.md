# 2026-09-08 — Alertas de coherencia estacional (A1 + C + B)

## Summary

Sesión enfocada en robustecer las alertas financieras de Mi Cafetal: se concluyó y desplegó el Nivel 3 (KPI por hectárea), se auditó la seguridad del ingreso de datos, y se diseñó e implementó la mejora de alertas aprobada (A1 + C + B) sobre la ventana de conciliación y la estacionalidad del gasto. Todo validado, desplegado y con HTTP 200.

## What happened

1. **Cierre Nivel 3 (KPI por hectárea)** — commit main `9c06ec7`, gh-pages `e2c0e89`, HTTP 200, 127/127 tests:
   - `establishmentCost` en `Crop` + migración `supabase/migrations/202609080001_add_establishment_cost.sql` (**aplicada por el usuario en Supabase**)
   - Funciones per-hectárea y amortización en `report_harvest_metrics.dart`
   - `lib/widgets/per_hectare_panel.dart` + integración en Reporte
   - HelpScreen con secciones per-ha/payback + guía markdown (secciones 8-9, sin modo invitado)
2. **Auditoría de seguridad del ingreso** (security-reviewer, informe íntegro en `C:\Users\MKY\.local\share\opencode\tool-output\tool_0811ee498001HjKEKZ6NDmEr6s`):
   - Sin vulnerabilidades CRITICAL/HIGH. H1 MEDIA: claves de LocalStore no ligadas a user_id → datos mezclables entre cuentas (`local_store.dart:140-147`, `sync_provider.dart:173-208`); H5 BAJA: CSV sin prefijo anti-fórmulas Excel (`excel_export_service.dart:144`). Pendiente decisión del usuario si implementa.
3. **PRD + Plan aprobados** (alcance A1+C+B; A2/D/E fuera):
   - `docs/prds/2026-09-08-alertas-coherencia-estacional.prd.md`
   - `docs/plans/2026-09-08-alertas-coherencia-estacional.plan.md`
4. **Implementación TDD (rojos→verdes)** — commit main `27beabd`, gh-pages `d5d5476`, HTTP 200, 137/137 tests:
   - **A1**: R6 `_checkHarvestVsSales` excluye `HarvestDestination.perdida` del respaldo cosechado (solo `vendido` + `almacenado` respaldan ventas).
   - **C**: R1 `_checkExcessiveSpending` compara contra el mismo mes calendario de años anteriores (baseline estacional); fallback al promedio global si < 2 meses-dato del mes. Fix de bug al implementar: `expenses` ahora filtra también por `year == now.year` (si no, los junios históricos inflaban el "gasto actual" y disparaban falsas alarmas).
   - **B**: nueva regla `AlertRule.missingQuantity` — alerta INFO `missing_quantity` si ≥3 ventas (`venta_*`) sin kilos en los últimos 90 días. Strings nuevos `alertMissingQtyTitle`/`Message({count})`/`Suggestion`.

## State

| Item | Status |
|---|---|
| Tests | 137/137 verdes (35 en alert_service, 10 nuevos A1/C/B) |
| analyze | limpio |
| gh-pages | `d5d5476`, HTTP 200 |
| main | `27beabd` |
| Migración N3 | aplicada (usuario) |
| .env | gitignored, funciona local |

## Key decisions (no revertir)

- Alcance alertas: solo A1 + C + B; A2 (ventana 24m/stock campaña), D (pérdida >10%) y E (higiene) son iteración futura.
- R1 baseline: mismo mes calendario histórico; requiere ≥2 meses-dato o cae a la media global. Umbral sigue `2×`.
- R6: la pérdida no respalda ventas; mensajes de R6 intactos (D7).
- B es `info`, no adivina cantidad, no cuenta fuera de 90 días.
- Regla de oro intacta: alertas solo con datos medidos.

## Pending

- [ ] Decidir si implementar H1 (prefijo uid en LocalStore) y H5 (prefijo `'` en CSV) de la auditoría; opcional guardar informe en `docs/reports/`.
- [ ] Sesión futura: A2/D/E si el usuario las pide.

## Files

`lib/services/alert_service.dart` (Regla 1 y Regla 6 modificadas, `_checkMissingQuantity` nueva)
`lib/models/farm_alert.dart` (enum `AlertRule.missingQuantity`)
`lib/l10n/app_es.arb`, `app_en.arb` + generados (claves `alertMissingQty*`)
`test/alert_service_test.dart` (grupos A1, C, B — 10 tests)
`docs/prds/2026-09-08-alertas-coherencia-estacional.prd.md`
`docs/plans/2026-09-08-alertas-coherencia-estacional.plan.md`