---
tanda: 3
hito: 2
fecha: 2026-11-17_1200
scope: margen por cultivo y por hectárea en una sola fila
resultado: PASS
---

# Reporte · Hito 2 — margen por cultivo y por hectárea

## Objetivo

Convertir el desglose por cultivo —con su reparto por hectáreas ya existente—
en **una sola** recomendación: qué cultivo paga mejor la mano de obra, con su
margen % y su margen por hectárea en la misma fila, con el mismo texto en
Reportes, PDF y Excel. Sin reconstruir el reparto, sin comparar monedas, sin
inventar la cifra por hectárea y sin tocar la paginación del PDF.

## Trazabilidad

Cubre **SC-2.1 a SC-2.5** y **SC-G1 a SC-G6** del PRD aprobado
`docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md`, según el plan
`docs/plans/2026-11-17_1136_hito2-margen-por-cultivo.plan.md`.

## Decisiones aplicadas (confirmadas en el plan)

| # | Decisión | Aplicación |
|---|---|---|
| D1 | Manda el **margen %**; el `$/ha` es la segunda cifra | El ganador se elige por `marginPct`; desempate por `marginPerHa`, nombre e id. Test 1: Café gana con 60 % aunque Plátano tenga más `$/ha`. |
| D2 | Si falta área o no hay gastos de operación repartidos, **se oculta la fila** | `bestCropMargin` devuelve `CropMarginRow?`; `areaHa <= 0` y `operacion <= 0` descartan al cultivo. Sin `0`, sin «sin datos». |
| D3 | Rotulo **«Margen por cultivo»** en los tres pintadores | `cropMarginTitle` / `cropMarginLine` en ARB; la frase lleva la acción de priorizar ahí la mano de obra, una sola vez (`suggestion: ''`). |

## Regla única (dos dueños, sin solapamiento)

1. **Atribución:** `crop_totals.dart` → `repartoPorHectareas` → `splitLotExpenses`
   → `cropBreakdownRows`. El servicio nuevo llama a esa función pura; no reparte
   por su cuenta. Un lote sin repartir sigue en fila aparte (`cropId == null`)
   y nunca entra con una proporción inventada.
2. **Selección y redacción:** `lib/services/crop_margin.dart` (nuevo). Filtros,
   elección del ganador, las dos cifras y la frase. Los tres pintadores solo
   concatenan `cropMarginRecommendations(...)` después de `derive`, igual que
   el hito 1 con `unsold_stock.dart`.

### Dos cifras, una atribución, dos cestas

- **Margen %:** `(ingresosTotal − gastosTotal) / ingresosTotal × 100` sobre
  **todos** los gastos de la fila del desglose (inversión inicial, equipo y
  operación), ya repartidos. Es la misma cifra que pintaba la tarjeta: la
  fórmula se extrajo a `CropBreakdownRow.margin` y `_CropRow.margin` delega.
- **Margen por hectárea:** `ingresoHa − costoHa`, donde `costoHa` cuenta
  **solo operación** de `row.expenseTxs`, igual que
  `ReportHarvestMetrics.costPerHa` (el equipo no encarece la hectárea del
  período). La frase nombra ambas por separado para que no se confundan.

El reparto es común; la cesta no. El test 2 lo fija: ingreso 400.000,
fertilizante 100.000 y equipo 200.000 sobre 2 ha da 25 % y `COP 50.000/ha`
de costo; con el equipo dentro daría `COP 150.000` y falla.

## TDD: rojo real antes del arreglo

Línea base: `flutter test test/export_parity_test.dart test/pdf_export_test.dart`
→ **12/12 verde**, PDF en 4 páginas y guarda de 1 página intactos, antes de
tocar producción.

`flutter test` sobre los tres archivos nuevos, antes de crear
`crop_margin.dart`, falló en **3 unidades**:

- `Error when reading 'lib/services/crop_margin.dart': The system cannot find
  the file specified.` (test puro y test de paridad).
- `Type 'CropMarginRow' not found` / `Method not found: 'bestCropMargin'` /
  `'cropMarginRecommendations'` / `'cropMarginMessage'` /
  `Member not found: 'cropMargin'`.
- `es · falta cropMarginTitle` (guarda ARB).

Después de la implementación mínima: **14/14 dirigidos verdes**.

## Cambios

| Archivo | Cambio |
|---|---|
| `lib/services/crop_margin.dart` (nuevo) | `CropMarginRow`, `bestCropMargin`, `cropMarginMessage`, `cropMarginRecommendations`. Filtros, doble guard de moneda, orden determinista y redacción única. |
| `lib/services/crop_totals.dart` | `margin` / `marginPct` extraídos a `CropBreakdownRow`; ningún valor existente cambia. |
| `lib/models/farm_alert.dart` | Valor `AlertRule.cropMargin`. **`evaluateAlerts` no lo emite**: solo identifica la fila. |
| `lib/screens/report_screen.dart` | Concatenación tras `derive` + stock, con `records: _recordsFor(tx)` y `terrenos: tx.terrenos`. `_CropRow.margin` delega en el getter nuevo. |
| `lib/services/pdf_export_service.dart` | `_recommendationsSection` recibe `periodRecords`/`terrenos`; la llamada pasa `periodTx`. |
| `lib/services/excel_export_service.dart` | `_whatsNextBlock` y `_harvestSheet` reciben `periodRecords`/`terrenos`; las dos call sites pasan `periodTx`. |
| `lib/l10n/app_es.arb` / `app_en.arb` | `cropMarginTitle`, `cropMarginLine` con `{crop}`, `{pct}`, `{money}` declarados `String` en ese orden; sin `$` ni `→`. |
| `lib/l10n/generated/` | Regenerado con `flutter gen-l10n` y normalizado a LF. |
| `test/crop_margin_test.dart` (nuevo) | 10 casos puros: D1, dos cestas, fila con dos cifras, área nula/0, lote sin repartir, moneda mixta (dos guardas), dato ausente, sin 100 % inventado, desempate sin reloj y reparto compartido. |
| `test/report_parity_tanda3_hito2_test.dart` (nuevo) | 3 tests widget: mismos tres pintadores, una sola fila con dos cultivos y silencio con COP+USD. El escenario mixto inyecta un servicio de conversión sin red para no dejar timers pendientes. |
| `test/l10n_crop_margin_test.dart` (nuevo) | Guarda ARB/generado ES/EN, placeholders, sin `$` ni `→`, sin prácticas no registradas, acción en los dos idiomas. |

## Reglas respetadas

- **Los tres pintadores dicen lo mismo:** una sola clave ARB y una sola
  función `cropMarginMessage`; el test de paridad compara la cadena exacta en
  pantalla, PDF y Excel, con dos cultivos compitiendo.
- **`null` → oculto:** sin área, sin gastos de operación, sin ingreso, sin
  gasto o con moneda mixta no hay fila. Ni `0`, ni guion, ni «sin datos».
- **Moneda mixta:** doble guard — `row.isMixed` dentro de un cultivo y
  unicidad de `singleCurrency` entre los candidatos finales. Sin conversión.
- **Sin cifras inventadas:** el lote sin repartir no se prorratea; el equipo
  no entra al `$/ha`; el margen no se calcula sin ingreso **y** gasto.
- **Sin dedupe indeseado:** la fila va después de `derive`; `evaluateAlerts` y
  el banner de Inicio quedan intactos.
- **Sin esquema, migración, sync ni entidades nuevas:** solo `Crop.areaHa`,
  `Transaction`, `CropBreakdownRow.expenseTxs` e `isOperationExpense`.

## Paginación del PDF

El fixture congelado de 4 páginas de `export_parity_test.dart` sigue en
**4 páginas** (por `/Type /Page` y `/Count`), con número y comentario intactos.
El guarda de 1 página de `pdf_export_test.dart` sigue en **1 página**; su
fixture mantiene venta y cosecha sin `cropId` a propósito desde el hito 1.
Ninguno de los dos se tocó. El escenario congelado de 4 páginas mezcla COP y
USD, así que SC-2.5 calla la fila nueva por diseño.

## Nota de fidelidad al plan

El plan traía dos ejemplos numéricos internamente inconsistentes (caso 1:
reparto 50/50 exigía 2 ha + 2 ha pero el texto decía 0,5 ha; caso 2: la suma
de gastos no daba 25 %). Los tests usan equivalentes **internamente
coherentes** que conservan la intención de cada criterio: el caso 1 separa D1
del reparto (0,5 ha sí se usa, pero con gastos directos), y el caso 2 usa
400.000 / 100.000 / 200.000 / 2 ha para fijar 25 % y 50.000 de costo/ha.

## Verificación

| Puerta | Resultado |
|---|---|
| `flutter analyze` (proyecto entero) | **No issues found!** |
| Rojo previo | 3 unidades en rojo antes del servicio |
| Línea base (4 y 1 páginas) | **12/12** verde antes de tocar producción |
| Dirigidos (3 archivos nuevos) | **14/14** |
| Targeted (12 archivos, con guardas) | **61/61** |
| `flutter test` suite completa | **1464/1464** (1450 anteriores + 14 nuevos) |
| Guardas `export_parity_test.dart` / `pdf_export_test.dart` | 4 páginas / 1 página, intactas |
| `git diff --check` | limpio |
| Fin de línea de `lib/l10n/generated/` | LF en los 3 archivos, 0 CRLF |

Ruido conocido y no bloqueante: `Unable to find a font to draw "☕" (U+2615)`
en tests de PDF.

Nota de herramienta: `/verify` y `/audit-report` no están instalados como
comandos en este repo. Se aplicaron sus reglas con la skill `verification-loop`
y el agente `report-auditor`; el rastro queda en `docs/reports/` y
`docs/audits/`.

## Estado

- Sin commit ni push: el último verbo cubre solo la ejecución con TDD.
- Siguiente: hito 3 (concentración de comprador), según el PRD.
- Pendiente no bloqueante: contrastar los umbrales del PRD con datos de finca
  real (10 ha, 3 cultivos, 4 trabajadores).
