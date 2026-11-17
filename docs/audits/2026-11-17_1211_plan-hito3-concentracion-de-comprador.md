---
timestamp: 2026-11-17_1211
target: docs/plans/2026-11-17_1205_hito3-concentracion-de-comprador.plan.md
reporte: docs/reports/2026-11-17_1211_plan-hito3-concentracion-de-comprador.md
prd: docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
resultado: PASS
---

# Auditoría · plan del hito 3 — concentración de comprador

> Auditado: 2026-11-17_1211
> Auditor: report-auditor
> Veredicto global: PASS
> Criterios evaluados: 13 (13 PASS, 0 FAIL, 0 NIT)
> Alcance: artefacto de planeación (DRAFT), no implementación. No se auditó código nuevo porque no existe aún.

## Criterios

| # | Criterio | Evidencia (archivo:línea) | Resultado |
|---|----------|---------------------------|-----------|
| 1 | Trazabilidad al PRD aprobado (SC-3.1..3.4 + SC-G1..G6) | plan:40-53 tabla completa con los 10 criterios; `prd:` en plan:2; reporte:18-20 | PASS |
| 2 | 4 decisiones preguntadas con recomendación delante y confirmadas | plan:16-31 (D1 `>50%`, D2 `{pct}`+`{buyer}`, D3 cadena exacta, D4 sin comprador excluido); reporte:22-36; consistente con PRD:114 (D4) | PASS |
| 3 | Regla única; moneda no reimplementada; `TopAccounts.from` no fuente directa; fila tras `derive`; `evaluateAlerts` mudo | plan:57-78, 148-166; `currency_totals.dart:10,143` y `crop_totals.dart:66-70` verificados; `categories.dart:86` verificado; `buyer_concentration.dart` aún no existe | PASS |
| 4 | SC-3.1/3.2: filtro de ventas, denominador identificado, `share = principal/total×100`, ≥2 y >50 %, una fila con % + nombre + acción | plan:44-45, 141-146, 178 (A700/B300 → 70 %); `isSaleCategory` cubre `venta` y `venta_*` (`categories.dart:82-87`) | PASS |
| 5 | SC-3.3: 50 % exacto, 1 comprador, sin comprador, sin ventas y montos 0 → `null`/`[]`, sin `0 %`/guion/«sin datos» | plan:46, 144, 179-186; `salesTotal <= 0 → null` y `sharePct == 50 → null` explícitos | PASS |
| 6 | SC-3.4 + SC-G2: mixta oculta aunque el texto solo cite `%`; doble guarda global + por comprador; sin conversión | plan:47, 49, 142, 182, 192; reporte:62-68 documenta la decisión deliberada; `isMixedCurrency` (`currency_totals.dart:143-151`) verificado | PASS |
| 7 | SC-G1: `client` ausente/vacío excluido; ningún «Sin nombre» | plan:48, 141, 181, 221; filtro `client != null && isNotEmpty`, sin fallback de nombre | PASS |
| 8 | SC-G3: N/A (no suma kilos) | plan:50; reporte declara SC-G3 como N/A; ninguna lectura de peso | PASS |
| 9 | SC-G4: una clave ARB y una función de mensaje; misma cadena en 3 pintadores | plan:51, 59-62, 91-100, 190; `buyerConcentrationMessage` única; `formatPct` en `format.dart:36` verificado | PASS |
| 10 | SC-G5: PDF 4 páginas y guarda de 1 intactas; fixtures sin tocar (4 mixto calla, 1 sin `client` calla) | plan:52, 101-102, 198-200, 219-220; `export_parity_test.dart:223` `paginasEsperadas = 4`, vías `:231` (`/Type /Page`) y `:234` (`/Count`); `pdf_export_test.dart:133-168,190-193` marcado «no tocar» | PASS |
| 11 | SC-G6: ES/EN con `{pct}`/`{buyer}` ordenados y `String`; `formatPct`; sin `$` ni `→`; barridos sin editar; LF en generados | plan:53, 93-94, 196, 226; `format.dart:36` verificado; `l10n_placeholder_order_test.dart` y `l10n_money_notation_test.dart` existen y se ejecutan, no se editan | PASS |
| 12 | TDD: 14 casos en 3 archivos nuevos, rojo anotado, línea base antes de pintores, verify ordenado con base 1464 | plan:168-213 (casos 1-13, línea base 14), 231-249; reporte:70-89; pintores ya reciben período (`pdf_export_service.dart:1837`, `excel_export_service.dart:2041`, `report_screen.dart:1951`) | PASS |
| 13 | Disciplina: sin esquema/migración/sync/backfill, sin secretos ni destructivos, consentimiento explícito para commit/push, sin código/commit/push ahora | plan:227, 248-249, 251-258; reporte:105-112; `buyer_concentration.dart` no existe; solo el plan nuevo sin seguimiento, `main` en `74ca17c` | PASS |

Nota de evidencia: los puntos 3, 4, 6, 9, 10, 11 y 12 se contrastaron contra archivos reales, no solo contra el reporte. Ninguna ancla citada está ausente o desalineada. No hay `NOT-VERIFIED`.

## Disciplina (resumen)

Sin SQL, migración, sync, backfill ni campo nuevo: se usan `client`, `amount`, `currency`, `category`, `deleted` y `date` ya existentes. Sin secretos ni comandos destructivos. Sin código de producción, commit ni push en esta tarea; el plan exige verbo explícito en el turno en que se haga. Estado de git coherente con lo declarado.

## Observaciones no bloqueantes

- La fila queda **fuera del banner de Inicio** por diseño: `evaluateAlerts` no emite la regla; `FarmAlert` solo gana un valor de enum (plan:92, 228, 257). Igual que hitos 1 y 2.
- El plan está en **DRAFT** a propósito: es un artefacto de planeación listo para ejecución, no un plan cerrado en progreso.
- La **prueba con finca real** (10 ha, 3 cultivos, 4 trabajadores) sigue pendiente; es validación no bloqueante del PRD (`Open Questions`), para medir el ruido del umbral de 50 % y los nombres exactos (plan:229, reporte:111-112).
- **Nota SC-G2**: la excepción general «porcentajes siguen visibles con moneda mixta» no se aplica aquí porque el `share` se construye sumando importes; está documentada como decisión deliberada (reporte:62-68), no como contradicción del PRD.

**Veredicto: PASS**
