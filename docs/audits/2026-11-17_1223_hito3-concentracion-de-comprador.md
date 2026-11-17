# Auditoría · Hito 3 — Concentración de comprador

> **Auditado:** 2026-11-17_1223
> **Auditor:** report-auditor
> **PRD:** `docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md` (APROBADO; D4)
> **Plan:** `docs/plans/2026-11-17_1205_hito3-concentracion-de-comprador.plan.md`
> **Reporte:** `docs/reports/2026-11-17_1223_hito3-concentracion-de-comprador.md`
> **Veredicto global:** PASS
> **Criterios evaluados:** 10 (9 PASS, 1 N/A, 0 NIT, 0 FAIL, 0 NOT-VERIFIED)
> **Skills cruzadas:** `verification-loop` (reglas de `/verify` aplicadas; comando no instalado en el repo)

Método: lectura directa de fuentes y tests. Las cifras de ejecución (analyze, test, diff-check, LF) son las registradas en el reporte y confirmadas por el agente principal; esta auditoría no re-ejecutó comandos.

## Criterios PRD

| # | Criterio | Estado | Evidencia verificada |
|---|----------|--------|----------------------|
| SC-3.1 | Filtro de ventas del período y `share` | PASS | `buyer_concentration.dart:52-59` (`!deleted`, `income`, `isSaleCategory`, `client` identificado); `:87-98` denominador y `share`. `isSaleCategory` en `categories.dart:86-87` (`venta` + `venta_*`). Test `buyer_concentration_test.dart:42-62,117-133`. |
| SC-3.2 | ≥2 compradores, >50 % → una fila con %, nombre y acción en 3 pintadores | PASS | `buyer_concentration.dart:77,101,132-141` (una `Recommendation`, `severity: info`); pintadores `report_screen.dart:1988`, `pdf_export_service.dart:1873`, `excel_export_service.dart:2079`; paridad `report_parity_tanda3_hito3_test.dart:195-212`. |
| SC-3.3 | 50 % exacto, 1 comprador, sin comprador, sin ventas, montos 0 → `null`/`[]` | PASS | Guardas `buyer_concentration.dart:60,77,88,101`; tests `buyer_concentration_test.dart:64-87,135-141`; oculto en pantalla/PDF/Excel `report_parity_tanda3_hito3_test.dart:214-237`. Sin `0 %`, guion ni «sin datos». |
| SC-3.4 | Moneda mixta → oculto, sin conversión ni suma cruzada | PASS | Doble guarda `buyer_concentration.dart:63` (`isMixedCurrency` antes de sumar) y `:65-70,81-84` (unicidad de `codes` y de `byCurrency` por comprador), reutilizando `currency_totals.dart:10-21,143-151`. Tests `buyer_concentration_test.dart:89-103` y paridad `:239-265`. |
| SC-G1 | Dato ausente → oculto, nunca «Sin nombre» ni `0` | PASS | `buyer_concentration.dart:57-58` excluye `client` nulo/vacío del denominador; test `:76-87`. Ningún fallback de nombre en ARB ni en el servicio. |
| SC-G2 | Mezcla oculta aunque el texto solo cite % | PASS | Decisión deliberada documentada (reporte `:54-57`, plan `:49`); `buyer_concentration.dart:63,98` computa el `share` sumando importes, luego calla con mezcla; test `report_parity_tanda3_hito3_test.dart:239-265`. No es contradicción: la excepción de «porcentajes visibles» se dejó sin efecto por la regla específica SC-3.4. |
| SC-G3 | Registros sin peso no entran en sumas de kilos | N/A | `buyer_concentration.dart` no consulta `quantity`, `unit` ni peso; la recomendación es de porcentaje sobre importes. Nada que listar ni sumar. |
| SC-G4 | Misma cifra y acción en los 3 pintadores | PASS | Una clave ARB `buyerConcentrationLine` y una función `buyerConcentrationMessage` (`buyer_concentration.dart:116-121`); los 3 pintadores concatenan tras `derive`+margen, con `records` del período; test `report_parity_tanda3_hito3_test.dart:195-212` compara la cadena exacta en pantalla, PDF y Excel. |
| SC-G5 | PDF en 4 páginas y guarda de 1 página intactos | PASS | `export_parity_test.dart:220-235` mantiene `paginasEsperadas = 4` con `/Type /Page` (:231) y `/Count` (:234) y su comentario; `pdf_export_test.dart:139-169` fixture sin `cropId` ni `client`, guarda `:190-193`. Sin tocar. El fixture de 4 páginas es mixto → la fila calla por SC-3.4. |
| SC-G6 | ARB ES/EN, placeholders `{pct}`/`{buyer}` en orden y `String`, sin `$` ni `→`, generados en LF, barridos sin editar | PASS | `app_es.arb:347-358`, `app_en.arb:341-349` (mismo orden y tipo); test `l10n_buyer_concentration_test.dart:17-59` (incluye ausencia de `{money}`/`{amount}`); getters en `generated/app_localizations{,_es,_en}.dart:917,920,1764,1770`. Barridos `l10n_placeholder_order_test.dart` y `l10n_money_notation_test.dart` sin referencias al hito → no editados. LF y 0 CRLF según verificación del principal. |

## Disciplina (verificación corta)

| Puerta | Resultado |
|---|---|
| TDD rojo antes del servicio | 3 unidades (`buyer_concentration.dart` ausente; símbolos y `AlertRule.buyerConcentration` inexistentes; ARB sin título) |
| Línea base antes de tocar producción | 12/12 (4 y 1 páginas) |
| `flutter analyze` / dirigidos / targeted / suite | No issues found / 13/13 / 51/51 / 1477/1477 (1464 + 13) |
| `git diff --check`; `lib/l10n/generated/` | limpio; LF, 0 CRLF |
| Esquema, migración, sync, secretos, destructivas, commit/push | sin cambios; solo campos ya existentes de `Transaction` |

Sin desvíos del plan: el reporte documenta `## Desvios / Incidentes` equivalentes y el contraste confirma que los tests reales los implementan.

## Observaciones no bloqueantes

1. **Banner de Inicio:** `evaluateAlerts` no emite `buyerConcentration` (`alert_service.dart` sin referencia; el enum solo gana un valor en `farm_alert.dart:37-39`). Coherente con hitos 1 y 2; la fila vive solo en «Qué hacer».
2. **Detalles del plan corregidos:** el caso 4 (A700 + 300 sin cliente → 100 %) era incompatible con ≥2 compradores; el test real usa A 700 + B 300 + 300 sin cliente → 70 % y `salesTotal == 1000` (`buyer_concentration_test.dart:82-86`). El conteo 14 → 13 tests nuevos (el 14 es la línea base) y la suite 1477 coinciden con los archivos (`reporte:93-106`).
3. **Prueba con finca real pendiente:** validación no bloqueante del PRD (`Open Questions`), ya registrada en el reporte (`:158-159`) y en el plan (`:229`).
4. **Timer de conversión inyectado:** el escenario mixto de paridad usa `CurrencyConversionService` con `MockClient` sin red y agota reintentos para no dejar timers pendientes al dispose (`report_parity_tanda3_hito3_test.dart:246-256`).
5. **Texto sin monto (D2):** decisión deliberada; la guarda de moneda se conserva porque el `share` se construye sumando importes y sin ella sería falso con COP+USD.

## Acción requerida

Nada. Reporte completo, criterios cumplidos y desvíos del plan documentados y contrastados.

---

**Veredicto: PASS**
