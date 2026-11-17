# Auditoría · Hito 2 — margen por cultivo y por hectárea

> **Auditado:** 2026-11-17_1200
> **Auditor:** report-auditor
> **PRD:** `docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md` (APROBADO)
> **Plan:** `docs/plans/2026-11-17_1136_hito2-margen-por-cultivo.plan.md`
> **Reporte:** `docs/reports/2026-11-17_1200_hito2-margen-por-cultivo.md` (Status: PASS)
> **Método:** contraste directo de símbolos, ARB, pintadores y tests con `read`/`grep`. Sin re-ejecución de comandos.

## Criterios PRD contrastados

| # | Criterio | Estado | Evidencia (archivo:línea / test) |
|---|----------|--------|----------------------------------|
| SC-2.1 | Margen % = (ingresos−gastos)/ingresos×100 sobre fila atribuida; delega, reparto compartido | PASS | `crop_totals.dart:88-95` getter `margin`/`marginPct` único; `report_screen.dart:3426` `_CropRow.margin => totals.margin`; `crop_margin.dart:76` usa `row.marginPct`; test `crop_margin_test.dart:79-98,297-325` (60 % y reparto común del desglose) |
| SC-2.2 | Margen $/ha con la misma atribución; cesta solo operación | PASS | `crop_margin.dart:82-96` filtra `isOperationExpense`, `costoHa=operacion/areaHa`; test `crop_margin_test.dart:101-119` (equipo 200.000 excluido → `costPerHa 50.000`, no 150.000) |
| SC-2.3 | Una sola fila con dos cifras y acción; `suggestion: ''`; paridad en 3 pintadores | PASS | `crop_margin.dart:132-158` devuelve `0..1` `Recommendation`, `suggestion: ''`, `rule: AlertRule.cropMargin`; winner por % + desempate `:105-114`; paridad `report_parity_tanda3_hito2_test.dart:202+`, 3 pintadores en `report_screen.dart:1976`, `pdf_export_service.dart:1862`, `excel_export_service.dart:2068` |
| SC-2.4 | Área nula/0 o lote sin repartir → oculto, sin proporción inventada | PASS | `crop_margin.dart:79-85` descarta `areaHa==null/<=0` y `operacion<=0`; `crop_totals.dart:106-116` `repartoPorHectareas` devuelve null sin proporción; tests `crop_margin_test.dart:155-198` (nula, 0, lote sin repartir) |
| SC-2.5 | Moneda mixta: doble guard | PASS | `crop_margin.dart:72` descarta `row.isMixed`; `:102` unicidad de `singleCurrency` entre candidatos; tests `crop_margin_test.dart:200-238` (COP/USD entre cultivos y dentro de un cultivo) y paridad `:242` |
| SC-G1 | Dato ausente sin 0 | PASS | `crop_margin.dart:73-77` descarta `singleCurrency==null` y `marginPct==null`; `:103` sin candidatos → `null`/`[]`; tests `crop_margin_test.dart:240-268` (sin ingreso/gasto → `[]`, sin 100 % ni 0 inventados) |
| SC-G2 | Sin conversión; fixture mixto 4 páginas calla | PASS | Sin llamada a tasa en `crop_margin.dart`; guard `:72,102`; `export_parity_test.dart:223` `paginasEsperadas=4` intacto; paridad mixta `report_parity_tanda3_hito2_test.dart:242-269` verifica silencio en 3 pintadores; `pdf_export_test.dart:190` guarda 1 página intacta |
| SC-G3 | No aplica (no suma kilos) | N/A | `crop_margin.dart` solo maneja importes (`incomesTotal`, `expenseTxs`) y área; ninguna suma de kg |
| SC-G4 | Acción + cifra en una fila, mismo texto en 3 pintadores | PASS | Única clave `cropMarginLine` (`app_es.arb:346`, `app_en.arb:340`) y única `cropMarginMessage` (`crop_margin.dart:119-128`); los 3 pintadores llaman a `cropMarginRecommendations`; test `crop_margin_test.dart:122-153` y paridad `:202+` comparan cadena exacta |
| SC-G5 | PDF 4 páginas y guarda anexo 1 página intactos | PASS | `export_parity_test.dart:223,231-234` (`paginasEsperadas=4`, `/Type /Page` + `/Count`, comentario `:218` intacto); `pdf_export_test.dart:133` fixture sin `cropId`, `:190` espera 1; reporte `:109-116` confirma fixtures y expectativas sin tocar |
| SC-G6 | ARB ES/EN, placeholders `{crop},{pct},{money}` en orden, sin `$` ni `→`, ISO en generados LF | PASS | `app_es.arb:338-346` y `app_en.arb:332-340` declaran los 3 como `String` en orden; frase sin `$` ni `→`; `crop_margin.dart:127` `formatMoneyLabel(..., row.currency, locale:)` (ISO, no símbolo); generados `app_localizations*.dart:1758/912` exponen `cropMarginLine(crop,pct,money)`; test `l10n_crop_margin_test.dart:17-56` |

## Disciplina

- **TDD rojo real:** 3 unidades fallidas antes del servicio (import ausente + símbolos inexistentes + ARB sin `cropMarginTitle`), documentado en reporte `:59-75`. Coherente con el código nuevo verificado.
- **Línea base 12/12 y verdes:** dirigidos 14/14, targeted 61/61, suite 1464/1464; `flutter analyze` limpio — según reporte `:129-139` (no re-ejecutado).
- **Sin esquema/migración/sync:** solo campos existentes (`Crop.areaHa`, `Transaction`, `expenseTxs`, `isOperationExpense`); `farm_alert.dart:36` añade valor de enum, sin columnas.
- **Sin secretos ni comandos destructivos:** sin indicios en los archivos auditados; esta auditoría no ejecutó ninguno.
- **Sin commit/push:** reporte `:149-152` lo declara; la auditoría es solo lectura + escritura del artefacto.
- **LF / diff-check:** `lib/l10n/generated/` en LF con 0 CRLF y `git diff --check` limpio, según reporte `:138-139` (confirmado por decisión del principal: verificación con read/grep).

## Observaciones no bloqueantes

- **Banner de Inicio:** `evaluateAlerts` (`alert_service.dart:37`) no emite `cropMargin`; `farm_alert.dart:34-36` lo confirma. Comportamiento previsto por el plan (`riesgos`, línea 295), no regresión.
- **Plan con dos ejemplos numéricos inconsistentes:** documentado y corregido con equivalentes coherentes en `reporte:118-125`; los tests fijan la intención de cada criterio, no los números erróneos.
- **Prueba con finca real pendiente:** PRD `Open Questions:170` y reporte `:153`; sigue como validación no bloqueante de umbrales.
- **Timer de conversión inyectado en el test de mezcla:** `report_parity_tanda3_hito2_test.dart:251-261` usa `CurrencyConversionService` con `MockClient` sin red + `pumpAndSettle` para no dejar timers pendientes. Técnica correcta, sin red.

**Veredicto: PASS**
