# 2026-09-07 — Nivel 2 Completo

## Summary

Sesión de desarrollo intensiva donde se diseñó e implementó la capa productiva Nivel 2 de Mi Cafetal: siembras, cosechas, fases de vida del cultivo y métricas agrícolas, desde cero hasta desplegado.

## What happened

1. **Diseño iterado** (múltiples rondas de preguntas con el usuario):
   - Se exploró el problema: el modelo N1 (solo dinero) no podía distinguir inversión en plantines de pérdida real.
   - Se diseñaron entidades `Sowing` y `Harvest` como tablas separadas vinculadas a transactions.
   - Se resolvió el caso plantines: fase `establecimiento` emite `info` en vez de `danger`.
   - Se descartó entidad "Temporada" (Opción A: agrupación por fechas).
   - Se definieron reglas de negocio: KPIs solo con datos medidos, nunca conversión plantines→kg, default crops no sync en nube.
   - PRD: `docs/plans/2026-09-07-cosecha-nivel2.plan.md`

2. **Implementación (F1-F7)** — commit `3005edc`:
   - F1: Modelos (`crop.dart` extendido, `units.dart`, `harvest.dart`, `sowing.dart`, `transaction.dart` con harvestId/sowingId)
   - F2: Migración SQL + `local_store.dart` + `sync_provider.dart` (push/pull sowings/harvests, crop upsert con campos nuevos)
   - F3: UI cultivos (`crops_screen.dart`, `crop_editor_dialog.dart`)
   - F4: UI siembras/cosechas (`sowing_screen.dart`, `harvest_screen.dart`) + `register_screen.dart` modificado
   - F5: Alertas (Regla 5 calibrada por fase, `harvestVsSales`, `cropRecentlyPlanted`)
   - F6: Reportes (PDF/Excel con métricas cosechas, vendido vs cosechado, "Qué hacer")
   - F7: i18n es/en, 88/88 tests verdes (30 nuevos)

3. **Revisión de calidad** — 2 revisiones con code-reviewer:
   - Fix FK ordering en migración
   - Fix PDF crop table (6 headers vs 5 columnas)
   - Fix `_isDefaultCrop` no incluía 'otro'
   - Fix `_createCrop` usaba lastWhere incorrecto

4. **Build + deploy (F8)** — commit `2c8f119` gh-pages, HTTP 200

5. **Commit de dev tools** — commit `591f3f0`:
   - `tool/demo_report_tool.dart` — PDFs con datos de ejemplo
   - `tool/generate_report_tool.dart` — PDFs desde Supabase
   - `tool/local_report_tool.dart` — PDFs desde datos.json local
   - `web/backup.html` — página de respaldo localStorage

6. **Migración SQL**: pendiente de aplicar en Supabase (SQL Editor). Archivo: `supabase/migrations/202609070001_add_sowings_harvests.sql`

## State

| Item | Status |
|---|---|
| Tests | 88/88 verdes |
| analyze | limpio |
| gh-pages | `2c8f119`, HTTP 200 |
| main | `591f3f0` (N1 + N2 + tools) |
| Migración Supabase | **pendiente de aplicar** |
| .env | gitignored, funciona local |

## Key decisions (no revertir)

- `pricePerUnit` no se persiste (derivable)
- livePlants: siembra fija, resiembra ajusta (cronológico con fechas retroactivas)
- KPIs = divisiones de datos medidos; nunca plantines→kg
- Sin entidad "Temporada" (Opción A)
- Default crops no upsert en nube (comportamiento N1 preservado)

## Pending

- [ ] Aplicar migración SQL `202609070001_add_sowings_harvests.sql` en Supabase
- [ ] Verificar sync de siembras/cosechas después de migración
- [ ] Nivel 3 formal (panel KPI por hectárea, amortización establecimiento)

## Files

`lib/models/`: crop.dart, units.dart, harvest.dart, sowing.dart, transaction.dart
`lib/services/`: alert_service.dart, recommendations.dart, report_harvest_metrics.dart, pdf_export_service.dart, excel_export_service.dart, local_store.dart
`lib/screens/`: crops_screen.dart, sowing_screen.dart, harvest_screen.dart, register_screen.dart, report_screen.dart
`lib/widgets/`: crop_editor_dialog.dart
`lib/providers/`: transaction_provider.dart, sync_provider.dart, alert_provider.dart
`supabase/migrations/202609070001_add_sowings_harvests.sql`
`docs/plans/2026-09-07-cosecha-nivel2.plan.md`
`test/`: 88 tests (crop_test, sowing_test, harvest_test, units_test, report_recommendations_test, report_harvest_metrics_test + extensiones)
