---
tanda: 3
hito: 1
fecha: 2026-11-17_1129
report: docs/reports/2026-11-17_1129_hito1-stock-sin-vender.md
prd: docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
plan: docs/plans/2026-11-17_1106_hito1-stock-sin-vender.plan.md
resultado: PASS
---

## Auditoria

> **Auditado:** 2026-11-17_1129
> **Auditor:** report-auditor
> **Veredicto global:** PASS
> **Criterios PRD evaluados:** 10 (10 PASS, 0 NIT, 0 FAIL)
> **Skills cruzadas:** verification-loop (reglas aplicadas: `/verify` y `/audit-report` no instalados como comandos)

### Criterios PRD

| # | Criterio | Estado | Evidencia (archivo : línea) |
|---|----------|--------|------------------------------|
| SC-1.1 | Ventana 365 d móviles, `now` inyectable, casos 364/365/366 y límites | PASS | `lib/services/unsold_stock.dart:48,57,68` (`desde = now − 365 d`; `isBefore/isAfter`); `test/unsold_stock_test.dart:77-126` (364 cuenta, 366 no, límites `now−365`/`now`); `:228-235` (`sacoKg`) |
| SC-1.2 | Una fila por cultivo, sin dedupe, orden por kg, cifra + acción | PASS | `unsold_stock.dart:76-92` (grupo por `cropId`, `sort` desc), `:96-98` (mensaje); `test/unsold_stock_test.dart:128-164` (2 filas `[60,20]`, recs=2, `Define comprador`); ARB `app_es.arb:333`; `test/report_parity_tanda3_hito1_test.dart:186-209` |
| SC-1.3 | Cero/negativo ocultos; sin fila vacía | PASS | `unsold_stock.dart:82` (`restante <= epsilon → continue`); `test/unsold_stock_test.dart:166-182` (50/50 y 40/50 → `[]`; ventana vacía → `[]`) |
| SC-1.4 | Conversión configurable (`sacoKg`) | PASS | `unsold_stock.dart:45,58,71` (`harvestKg`/`kgFromUnit` con `sacoKg`); `test/unsold_stock_test.dart:228-235` (1 saco a 60 → 60, no 70); `report_harvest_metrics.dart:93,110` (función pública, `_kgOf` la delega) |
| SC-G1 | `null` → oculto, nunca `0` | PASS | `unsold_stock.dart:56,66,70-72,82` (`cropId`/kg nulo omite fila); `test/unsold_stock_test.dart:203-211`, `:237-243` |
| SC-G2 | Moneda mixta sin citar moneda | PASS | `unsold_stock.dart:96-98` (mensaje solo de kg); `test/unsold_stock_test.dart:213-226` (COP+USD, sin `$`/`COP`/`USD`) |
| SC-G3 | Kilos sin peso listados y nunca sumados (test gemelo) | PASS | `test/unsold_stock_test.dart:184-201` (gemelo 60 → 60; `pendingWeight*` = 1/1); `lib/screens/report_screen.dart:939-941` (listado «sin peso»; decisión D3: solo pantalla) |
| SC-G4 | Mismos tres pintadores, mismo texto y cifra | PASS | Única redacción `unsold_stock.dart:96-98`; concatenación en `report_screen.dart:1964`, `pdf_export_service.dart:1848`, `excel_export_service.dart:2049`; `test/report_parity_tanda3_hito1_test.dart:166-209` (1 y 2 cultivos, cadena idéntica en los tres) |
| SC-G5 | PDF en 4 páginas intacto | PASS | `test/export_parity_test.dart:223` (`paginasEsperadas = 4`), `:231-234` (`/Type /Page` y `/Count`); `test/pdf_export_test.dart:190` (`expect(…, 1)` sin cambio), fixture `:150-168` sin `cropId` + comentario `:133-137` (arreglo en fixture, no en expectativa ni regla) |
| SC-G6 | ARB ES/EN, placeholders en orden, LF | PASS | `app_es.arb:322-333`, `app_en.arb:322-330` (`{kg}` antes de `{crop}`, tipo `String`, sin `$` ni `→`); getters generados `app_localizations.dart:1740,1746`, `_es.dart:901,904`, `_en.dart:901,904`; `test/l10n_stock_sin_vender_test.dart:17-40`; LF de generados documentado en reporte (no re-verificable a nivel byte en esta sesión) |

> No hay criterios `NOT-VERIFIED` heredados: el reporte no incluyó tabla `Success Criteria del PRD`, pero los 10 criterios del hito están evaluados con evidencia de archivo concreta. Los criterios SC-2.x…SC-6.x son de hitos posteriores y no aplican a este hito (plan §Fuera de alcance).

### Disciplina (no bloqueante)

- **TDD:** rojo real documentado en 3 unidades (servicio ausente, `method not found`, ARB sin `stockUnsoldTitle`) antes de crear `unsold_stock.dart`; 13/13 dirigidos tras el arreglo. Coherente con que los 3 archivos nuevos y el enum no existían antes. No re-ejecutable en esta sesión de auditoría (sin herramienta de shell).
- **Sin esquema/migración/sync:** el servicio lee solo campos existentes de `Harvest`/`Transaction`; cero SQL y cero backfill. Verificado por lectura de `unsold_stock.dart:41-93`.
- **Sin secretos / sin comandos destructivos / sin commit ni push:** reporte lo declara (`docs/reports/...:135-140`); sin evidencia en contrario en los archivos leídos. Estado de git no re-verificable aquí (sin shell).
- **LF y `git diff --check`:** reporte los declara limpios (`:123-124`); no re-verificables a nivel byte en esta subagent. Ninguna contradicción con el contenido leído.

### Observaciones no bloqueantes

1. `evaluateAlerts` **no emite** `unsoldStock`: el valor del enum (`farm_alert.dart:33`) solo identifica la fila. Decisión D1 del plan, respetada.
2. La fila **no aparece en el banner de Inicio** en este hito: el banner consume `FarmAlert`, no el servicio nuevo. Documentado en plan y reporte; el milestone cubre los tres pintadores del reporte.
3. **Prueba manual con finca real pendiente** para contrastar umbrales (PRD Open Questions, decisiones D4/D6): no bloquea este hito, que es solo SC-1.x/SC-G.
4. `verification-loop` cargada como sustituto de `/verify` y `/audit-report` (comandos no instalados); su rastro está en `docs/reports/` y este `docs/audits/`. Sin veredicto de skill ignorado.

### Accion requerida

Nada. Reporte completo; criterios del hito cumplidos con evidencia verificable. Sin FAIL ni NIT.

**Veredicto: PASS**
