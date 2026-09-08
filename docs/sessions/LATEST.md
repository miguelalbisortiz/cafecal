# 2026-09-08 — Nivel 3 + Alertas A1/C/B + Fix H1 (aislamiento local por usuario)

## Summary

Sesión de cierre técnico: se implementó y desplegó el **Nivel 3 (KPI por hectárea + amortización del establecimiento)** firmado el día anterior, se ejecutó la **auditoría de seguridad del ingreso** (sin CRITICAL/HIGH; pendiente decisión de remediar H1), y se diseñó e implementó la mejora de **alertas A1 + C + B** (coherencia estacional R6/R1 + aviso de ventas sin cantidad). Todo validado (analyze limpio, **137/137 tests**) y desplegado (HTTP 200).

## What happened

1. **Nivel 3 completo y desplegado** (commit main `9c06ec7`, gh-pages `e2c0e89`, HTTP 200, 127/127 tests):
   - `establishmentCost` en `Crop` + `supabase/migrations/202609080001_add_establishment_cost.sql` (**aplicada por el usuario**).
   - Lógica per-ha/amortización en `report_harvest_metrics.dart`; `lib/widgets/per_hectare_panel.dart` en el Reporte.
   - HelpScreen (per-ha/payback) + guía `docs/guides/mi-cafetal-primeros-pasos.md` (secciones 8-9, sin modo invitado).

2. **Auditoría de seguridad del ingreso** (informe íntegro: `C:\Users\MKY\.local\share\opencode\tool-output\tool_0811ee498001HjKEKZ6NDmEr6s`):
   - Ninguna CRITICAL/HIGH. **H1 MEDIA**: LocalStore sin ligar a user_id → datos mezclables entre cuentas (`local_store.dart:140-147`, `sync_provider.dart:173-208`). H5 BAJA: CSV sin prefijo anti-fórmulas (`excel_export_service.dart:144`).
   - Decisión pendiente del usuario: implementar H1 (+H5) y guardar informe en `docs/reports/`.

3. **PRD + Plan alertas aprobados** — `docs/prds/` y `docs/plans/2026-09-08-alertas-coherencia-estacional.{prd,plan}.md`. Alcance: **A1 + C + B** (A2/D/E → iteración futura).

4. **Implementación TDD + deploy** (main `27beabd`, gh-pages `d5d5476`, HTTP 200, **137/137 tests**, +10 tests en `alert_service_test.dart`):
   - **A1**: R6 excluye `HarvestDestination.perdida` del respaldo cosechado.
   - **C**: R1 usa baseline del mismo mes calendario de años anteriores (fallback a la media global si < 2 meses-dato). Bug descubierto y corregido: `expenses` ahora filtra `year == now.year` (antes contaba los junios históricos como gasto actual → falsa alarma).
   - **B**: `AlertRule.missingQuantity` — INFO `missing_quantity` si ≥3 ventas sin kilos en 90 días. Strings `alertMissingQty*` (es/en).

5. **Fix H1 — aislamiento de datos locales por usuario** (commit main `4a8c125`, gh-pages `d8a1716`, HTTP 200, **144/144 tests**):
   - `LocalStore` con namespace por uid (`transactions_v1_<uid>`, …), migración legacy idempotente y no destructiva, `clearAll()` selectivo por usuario, `SupabaseService.currentUserId`, `AuthProvider` bindea en login/logout, `TransactionProvider.reloadFromCache()`. Detalle: `docs/plans/2026-09-08-fix-h1-aislamiento-local.plan.md` + `docs/sessions/2026-09-08-fix-h1-aislamiento-local.md`.

## State

| Item | Status |
|---|---|
| Tests | **144/144 verdes** |
| analyze | limpio |
| gh-pages | `d8a1716`, HTTP 200 |
| main | `4a8c125` |
| Migración N3 | aplicada (usuario) |
| .env | gitignored, funciona local |

## Key decisions (no revertir)

- R1 baseline estacional (mismo mes calendario), umbral intacto `2×`.
- R6: la pérdida no respalda ventas; mensajes R6 intactos.
- B es `info`, nunca adivina cantidad, ventana de 90 días.
- Regla de oro intacta: alertas solo con datos medidos.

## Pending

- [ ] Decidir e implementar el fix H5 (prefijo `'` anti-fórmulas en CSV) y, si se quiere, H3 (validación email/password cliente) y H2 (init muerto); opcional guardar el informe de auditoría en `docs/reports/`.
- [ ] Iteración futura de alertas: A2 (ventana 24m/stock campaña), D (pérdida >10% anual), E (higiene: max alertas, silenciar).
- [ ] Verificación manual en producción del fix H1: login con la cuenta real → migración automática de claves legacy → datos intactos; segunda cuenta no ve nada.