---
prd: docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
status: DONE 2026-11-17_1200
created: 2026-11-17_1136
milestone: 2 · Margen por cultivo y por hectárea
source:
  - docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
  - docs/plans/2026-11-17_1106_hito1-stock-sin-vender.plan.md
  - docs/plans/2026-11-17_0918-mejoras-cultivos-y-recomendaciones.plan.md
  - docs/analysis/2026-11-17_calculos-recomendaciones.md
repo_state: main en 31c00dd (Tandas 1, 2A, 2B, 2C y hito 1 de Tanda 3 cerradas y pusheadas)
---

# Plan: Hito 2 — Margen por cultivo y por hectárea

## Recomendación (decisiones confirmadas el 2026-11-17)

Antes de cerrar el plan se preguntaron las tres decisiones con más de una opción
razonable. El usuario eligió las tres marcadas «Recomendado»:

| # | Decisión | Elección confirmada | Por qué |
|---|---|---|---|
| D1 | Cuál de las dos cifras manda para nombrar al «mejor cultivo» | **El margen % (SC-2.1)**; el `$/ha` se muestra como segunda cifra | Concuerda con el margen que ya pintan las tarjetas del desglose; una cifra nueva no redefina la palabra «margen». |
| D2 | Si al ganador le falta el área o no hay gastos repartidos | **Ocultar la fila completa** | D3 exige una fila con DOS cifras y SC-2.3 condiciona «WHEN ambas cifras existan». SC-2.4 se aplica a los cultivos que simplemente no compiten. |
| D3 | Rotulo de la fila | **«Margen por cultivo»** en los tres pintadores | Misma voz que el desglose (`cropBreakdownMarginHint`); la frase lleva la acción de priorizar ahí la mano de obra. |

Consecuencias de D1 y D2: el servicio devuelve **como máximo una** fila
(`CropMarginRow?`), nunca una lista por cultivo; el desempate lo fija el propio
servicio. Consecuencia de D3: dos claves ARB nuevas, con el título corto y la
frase completa; el título no dice «margen por hectárea» para referirse al %.

## Objetivo

Convertir el desglose por cultivo ya existente —con su reparto por hectáreas—
en **una sola** recomendación: qué cultivo paga mejor la mano de obra, con su
margen % y su margen por hectárea en la misma fila. Sin reconstruir el reparto,
sin comparar monedas, sin inventar la cifra por hectárea y sin tocar la
paginación del PDF.

## Criterios de aceptación (trazabilidad)

| Criterio | Cómo se verifica en este hito |
|---|---|
| **SC-2.1** | `bestCropMargin` calcula el % como `(incomesTotal − expensesTotal) / incomesTotal × 100` sobre la fila ya atribuida de `cropBreakdownRows` (la misma lista que pinta el desglose). La fórmula se extrae a `CropBreakdownRow.margin`; `_CropRow.margin` delega en ella para que no haya dos fórmulas. Test: gasto de lote repartido 200.000 entre dos cultivos de 2 ha → 100.000 en cada margen, y cambiar un área cambia ambas cifras a la vez. |
| **SC-2.2** | `ingresoHa = incomesTotal / areaHa` y `costPerHa = Σ(gastos de operación de `row.expenseTxs`) / areaHa`; `marginPerHa = ingresoHa − costoHa`, con esa misma atribución. Test: cultivo con gasto de operación 100.000 + equipo 200.000 sobre 2 ha da `costoHa = 50.000`, no `150.000` (misma cesta que `ReportHarvestMetrics.costPerHa`). |
| **SC-2.3** | Una única recomendación con `{crop}`, `{pct}` y `{money}/ha` y la acción de priorizar ahí la mano de obra, en los tres pintadores. `cropMarginRecommendations` devuelve 0 o 1 fila; test de paridad con dos cultivos compitiendo. El ganador se elige por % (D1), con desempate por `$/ha`, nombre e id. |
| **SC-2.4** | `areaHa == null`, `<= 0` o sin gastos de operación repartidos → el cultivo no es candidato; si le pasa al ganador, no se emite nada (D2). Nunca `0`, nunca «sin datos». Tests: área `null`, área `0`, lote sin repartir. |
| **SC-2.5** | Se descarta toda fila `isMixed` y, además, si los candidatos finales tienen más de un código de moneda se devuelve `null` (no se comparan márgenes entre monedas). Tests: dos cultivos COP/USD y un cultivo con ingresos COP y gastos USD. |
| **SC-G1** | Ingresos o gastos ausentes (`incomes`/`expenses` vacíos) → el cultivo no es candidato; sin fila con `0`, guion ni «sin datos». Tests 7 y 8. |
| **SC-G2** | La fila cita dinero (`$` por hectárea) y lleva el doble guard de SC-2.5: con mezcla se oculta en los tres pintadores, sin conversión. Test de paridad con COP+USD y el fixture congelado de 4 páginas (que es mixto). |
| **SC-G3** | No aplica a esta recomendación: no suma kilos. Los registros sin peso siguen en sus listas y no alteran las cifras de dinero. |
| **SC-G4** | Un único ARB `cropMarginLine` produce la frase; los tres pintadores llaman al mismo `cropMarginMessage` y reciben `suggestion: ''` para no repetir la acción. Test de paridad compara la cadena en pantalla, PDF y Excel. |
| **SC-G5** | `export_parity_test.dart` mantiene `paginasEsperadas = 4` y sus dos vías (`/Type /Page` y `/Count`) sin cambiar número ni comentario. El fixture congelado mezcla COP y USD, así que la fila nueva no se emite ahí. |
| **SC-G6** | `cropMarginTitle` y `cropMarginLine` en ES y EN, placeholders `{crop}`, `{pct}`, `{money}` en ese orden y tipo `String`; `{money}` recibe `formatMoneyLabel` con código ISO (nunca `$`); sin `→` (U+2192). Barridos `l10n_placeholder_order_test.dart` y `l10n_money_notation_test.dart` siguen verdes sin editar. |

## Diseño concreto

### Regla única (decisión explícita)

Dos dueños, sin solapamiento:

1. **La atribución vive en `lib/services/crop_totals.dart`** — `repartoPorHectareas`
   → `splitLotExpenses` → `cropBreakdownRows`. El servicio nuevo **llama a esa
   misma función pura** con los argumentos del período; no implementa reparto
   propio ni reagrupa por `cropId`. Un gasto de lote que no se puede repartir
   sigue saliendo como fila aparte (`cropId == null`) y **nunca** entra en el
   margen de un cultivo con una proporción inventada.
2. **La selección y la redacción viven en `lib/services/crop_margin.dart`
   (nuevo)** — filtros, elección del ganador por %, las dos cifras y la frase.
   Los tres pintadores **no calculan**: solo concatenan lo que devuelve ese
   archivo después de `derive`, igual que el hito 1 con `unsold_stock.dart`.
   No se mete en `alert_service.dart` y `RecommendationService.derive` conserva
   su dedupe por `AlertRule`.

### Qué significa «margen» con los datos disponibles

Dos cifras, **una misma atribución**, pero dos cestas de gasto distintas —y el
texto las nombra por separado para que no se confundan:

- **Margen % del cultivo (SC-2.1):** `(ingresosTotal − gastosTotal) / ingresosTotal × 100`
  sobre **todos** los gastos de la fila del desglose (inversión inicial,
  equipo y operación), ya repartidos. Es exactamente la cifra que hoy pinta
  `_CropRow.marginPct` en la tarjeta. Sin ingresos o sin gastos → no se calcula.
- **Margen por hectárea (SC-2.2):** `ingresoHa − costoHa`, donde `costoHa`
  cuenta **solo la operación** de `row.expenseTxs`, igual que
  `ReportHarvestMetrics.costPerHa` (la inversión en equipo no encarece la
  hectárea de este período). Con `areaHa == null` o `<= 0` no existe.

El reparto es común; la cesta no. Eso no contradice D3: D3 fija la atribución,
no la cesta. Se documenta en el reporte y se fija con el test 2.

### Archivos a tocar

| Archivo | Cambio | Riesgo |
|---|---|---|
| `lib/services/crop_margin.dart` (**nuevo**) | `CropMarginRow` + `bestCropMargin` + `cropMarginMessage` + `cropMarginRecommendations` | Medio |
| `lib/services/crop_totals.dart` | Getter `margin` / `marginPct` en `CropBreakdownRow` (extraer la fórmula de `_CropRow.margin` sin cambiar su valor) | Bajo |
| `lib/models/farm_alert.dart` | Valor `cropMargin` en `AlertRule` (identidad de la fila; **`evaluateAlerts` no lo emite**) | Bajo |
| `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` | `cropMarginTitle`, `cropMarginLine` con `{crop}`, `{pct}`, `{money}` en ese orden | Bajo |
| `lib/l10n/generated/*.dart` | Regenerados con `flutter gen-l10n` y normalizados a LF | Medio (CRLF) |
| `lib/screens/report_screen.dart` | En `_builtRecommendationsCard` (`:1962-1973`), después del loop de `derive`/stock, concatenar la fila con `records: _recordsFor(tx)` y `terrenos: tx.terrenos` | Bajo |
| `lib/services/pdf_export_service.dart` | En `_recommendationsSection` (`:1846-1857`), añadir el parámetro `periodRecords` (la llamada de `:537` pasa `periodTx`) y concatenar la fila con `small: true` en el render ya existente | Medio (páginas) |
| `lib/services/excel_export_service.dart` | En `_whatsNextBlock` (`:2047-2058`), añadir los parámetros `periodRecords`/`terrenos`; las dos call sites (`:1765` y `:1987`) ya tienen `periodTx` y `terrenos` en su ámbito | Bajo |
| `test/crop_margin_test.dart` (**nuevo**) | Casos SC-2.1..2.5 y SC-G1/G2 | — |
| `test/report_parity_tanda3_hito2_test.dart` (**nuevo**) | SC-G4: misma cadena en los tres pintadores; SC-2.5 con mezcla | — |
| `test/l10n_crop_margin_test.dart` (**nuevo**) | SC-G6: ES/EN, placeholders, sin `$` ni `→`, sin prácticas no registradas | — |
| `test/export_parity_test.dart` | **No tocar** los cuatro números congelados ni su comentario | Alto si se rompe |
| `test/pdf_export_test.dart` | **No tocar**: su fixture de 1 página lleva venta y cosecha sin `cropId` a propósito (`:133-168`) | Alto si se rompe |

### Firma de datos

```dart
// lib/services/crop_margin.dart
class CropMarginRow {
  final String cropId;
  final String cropName;
  final String currency;      // código ISO, validado como único
  final double marginPct;     // (ingresos − gastos) / ingresos * 100
  final double incomePerHa;
  final double costPerHa;     // solo operación
  final double marginPerHa;   // incomePerHa − costPerHa
  const CropMarginRow({...});
}

/// Como máximo UNA fila: el mayor marginPct entre los cultivos que también
/// tengan área y gastos de operación repartidos. null → no se emite nada.
CropMarginRow? bestCropMargin({
  required Iterable<Transaction> records,       // ya filtrado al período
  required List<Crop> crops,
  required List<Terreno> terrenos,
  required String unspecifiedName,
  required String loteNoRepartidoName,
});

/// La misma frase en los tres pintadores.
String cropMarginMessage(CropMarginRow row, AppLocalizations l10n, String locale);

/// 0 o 1 fila lista para «Qué hacer», concatenada DESPUÉS de `derive`.
List<Recommendation> cropMarginRecommendations({
  required Iterable<Transaction> records,
  required List<Crop> crops,
  required List<Terreno> terrenos,
  required String unspecifiedName,
  required String loteNoRepartidoName,
  required AppLocalizations l10n,
  required String locale,
});
```

Detalles que fijan el comportamiento:

- **Fuente:** `cropBreakdownRows(records: records, ...)` dentro del servicio,
  con los mismos rótulos que usan los tres pintadores (`commonCosts` /
  `loteNoRepartido`). Es la única puerta al reparto.
- **Candidatos:** filas con `cropId != null`, `!isMixed`, `singleCurrency != null`,
  `incomesTotal > 0`, `expensesTotal > 0` y `areaHa > 0` (desde `crops` por id).
  Se omiten los lotes sin repartir y «Costos comunes» por no tener cultivo.
- **Moneda entre candidatos:** si el conjunto de `singleCurrency` tiene más de
  un código → `null` (SC-2.5). Sin conversión.
- **`costoHa`:** `row.expenseTxs.where(isOperationExpense)` sumado y dividido
  entre `areaHa`; si da `<= 0` el cultivo no es candidato (SC-2.4: no hay
  gastos repartidos que meter en la cifra por hectárea).
- **Orden:** `marginPct` descendente (D1), desempate por `marginPerHa`
  descendente, luego `cropName`, luego `cropId`. Sin `DateTime.now()`:
  la ventana es la del reporte, no una rodante como en el hito 1.
- **Texto:** `cropMarginLine` con cifra y acción en la misma frase;
  `formatPct(row.marginPct)` y
  `formatMoneyLabel(row.marginPerHa, row.currency, locale: locale)`.
  `cropMarginTitle` es «Margen por cultivo». `suggestion: ''`.

### Flujo fuente → tres pintadores

```
transactions del período / crops (areaHa) / terrenos
        │
        ▼  crop_totals.dart · cropBreakdownRows  (ÚNICA atribución; reparte por ha)
        ▼  lib/services/crop_margin.dart  (ÚNICA regla: filtros, % + $/ha, texto)
   CropMarginRow? → 0 o 1 Recommendation (rule = AlertRule.cropMargin)
        │
        ├── report_screen.dart  _builtRecommendationsCard  (after derive + stock)
        ├── pdf_export_service.dart  _recommendationsSection (after derive + stock)
        └── excel_export_service.dart  _whatsNextBlock       (after derive + stock)
```

Cada pintador conserva su `derive(alerts)` y su stock del hito 1 y añade una
sola línea: `...cropMarginRecommendations(...)`. El render de la fila
(avatar/número, `_statementRow(small: true)`, `row([TextCellValue])`) **no se
reescribe**. En PDF y Excel se pasa `periodTx` —no `history`/`active`— para que
el margen use exactamente el desglose del período que se está exportando.

## Secuencia TDD

Regla: **rojo → implementación mínima → verde → verify**. No se escribe código
de producción hasta que los tests nuevos fallan por la razón esperada (import o
símbolo inexistente cuenta como rojo; se anota el mensaje en el reporte).
`now` no interviene: se construyen transacciones con fechas dentro del período.

### Paso 1 · ROJO — `test/crop_margin_test.dart` (nuevo, puro)

1. **SC-2.1 / D1 · dos cifras en una fila y el % manda**: gasto de lote 200.000
   COP repartido entre Café (2 ha) y Plátano (2 ha) → 100.000 cada uno; Café
   ingreso 500.000 + gasto directo 100.000 → 60 % y 150.000 COP/ha; Plátano
   ingreso 300.000 + gasto directo 50.000 sobre 0,5 ha → 50 % pero 300.000
   COP/ha. `bestCropMargin` elige **Café** por el % aunque Plátano gane en
   `$/ha`.
2. **SC-2.2 · la cesta del `$/ha` es solo operación**: un cultivo con ingreso
   400.000, gasto de operación 100.000, inversión inicial 100.000 y equipo
   50.000 sobre 2 ha → `marginPct == 25`, `costPerHa == 50.000`,
   `marginPerHa == 150.000`. Si se sumara el equipo, el test da 50.000 y falla.
3. **SC-2.3 · una fila con dos cifras y la acción**: `cropMarginRecommendations`
   devuelve `length == 1`; el mensaje contiene el cultivo, `60%`, `COP 150.000`
   con `/ha` y la acción de priorizar mano de obra; `suggestion.isEmpty`.
4. **SC-2.4 / D2 · sin área → oculto**: mismos datos del caso 1 con
   `areaHa: null` en Café → `null` y `[]`. Variante con `areaHa: 0` → igual.
5. **SC-2.4 · gasto de lote sin repartir → línea aparte, sin proporción
   inventada**: lote con un cultivo sin área; `repartoPorHectareas` devuelve
   `null` y la fila del lote tiene `cropId == null`; el cultivo con área compite
   solo con sus gastos directos y su margen **no incluye** el gasto del lote.
6. **SC-2.5 / SC-G2 · moneda mixta**: Dos cultivos, Café en COP y Plátano en
   USD, ambos con área → `null`/`[]`. Variante: un mismo cultivo con ingresos
   COP y gastos USD (`isMixed`) → `null`/`[]`.
7. **SC-G1 · dato ausente**: cultivo con ingresos vacíos o gastos vacíos no es
   candidato; sin ningún candidato → `[]` (ni `0`, ni «sin datos»).
8. **SC-2.1 · no inventar el 100 % ni el margen sin ingreso**: ingreso 500.000
   y gastos 0 → `[]`; gastos 100.000 e ingresos 0 → `[]`.
9. **Determinismo y desempate**: dos cultivos con el mismo % → gana el de mayor
   `$/ha`, luego el de nombre menor; dos llamadas con la misma entrada dan el
   mismo `cropId` (sin reloj dentro del servicio).
10. **Regla compartida de reparto**: el gasto que entra al margen coincide con
    `cropExpenseShares(records: ..., crops: ...)` y con la fila del desglose;
    al cambiar el área de uno de los dos cultivos cambian juntas la fila del
    desglose y la cifra del margen.

### Paso 2 · ROJO — `test/report_parity_tanda3_hito2_test.dart` (nuevo)

11. **SC-G4 · tres pintadores**: un escenario de una sola moneda con dos
    cultivos con área; construir pantalla (`ReportScreen`), PDF
    (`PdfExportService.buildReport`) y Excel (`ExcelExportService.buildReport`)
    con el mismo `l10n`; la cadena `cropMarginMessage` aparece **idéntica** en
    los tres (mismo cultivo, mismo %, mismo `COP .../ha`, mismo orden).
12. **SC-2.3 · una sola fila**: exactamente una fila nueva en los tres, aunque
    los dos cultivos tengan margen; el dedupe de `derive` no se relaja.
13. **SC-G2 / SC-2.5 · mezcla en los tres**: con COP + USD la fila nueva no
    aparece en ninguno de los tres; el PDF sigue en 4 páginas con el fixture
    congelado.

### Paso 3 · ROJO — `test/l10n_crop_margin_test.dart` (nuevo)

14. **SC-G6**: ambas claves en ES y EN; `{crop}`, `{pct}`, `{money}` en ese
    orden y declarados `String` en los dos idiomas; el generado expone los
    getters; la frase no contiene `$` ni `→`; no nombra densidad, variedad,
    sombra/sol ni prácticas que la app no registra; la acción de priorizar la
    mano de obra está en los dos idiomas. Los barridos existentes se ejecutan
    sin editar.

### Paso 4 · Línea base de las guardas de paginación

15. `flutter test test/export_parity_test.dart` **antes** de tocar los
    pintadores: verde con 4 páginas por `/Type /Page` **y** `/Count`.
    `flutter test test/pdf_export_test.dart`: verde con 1 página en el caso sin
    anexo. El fixture de ese test tiene venta y cosecha sin `cropId` desde el
    hito 1 (`:133-168`) para aislar la paginación; la fila de margen tampoco
    debe aparecer allí. No se tocan fixtures ni expectativas.

### Paso 5 · Implementación mínima

1. `lib/services/crop_totals.dart`: extraer `margin`/`marginPct` a
   `CropBreakdownRow`; `_CropRow.margin` delega. Ningún valor existente cambia.
2. `lib/models/farm_alert.dart`: valor `cropMargin` en `AlertRule`.
3. `lib/services/crop_margin.dart`: las cuatro unidades de la firma.
4. ARB ES/EN + `flutter gen-l10n` + normalización LF de
   `lib/l10n/generated/`.
5. Los tres pintadores: una línea de concatenación cada uno; PDF y Excel
   reciben `periodTx`/`terrenos` en los helpers; sin reescribir el render.
6. Tests en verde; guardas de 4 y 1 páginas intactas.

### Paso 6 · Verify

Orden: `flutter analyze` → tests targeted → suite completa → gate de ARB/LF →
reporte y auditoría (ver § siguiente).

## Riesgos y guardas

| Riesgo | Guarda concreta |
|---|---|
| El PDF gana una página (SC-G5) | `export_parity_test.dart:223` `paginasEsperadas = 4`, por `/Type /Page` **y** `/Count`, con comentario intacto. El fixture congelado es mixto (COP+USD), así que SC-2.5 calla la fila; si el test sube a 5, antes de recompactar se comprueba si el guard de moneda mixta falló. Nunca se actualiza el número a ciegas. |
| El guarda de 1 página deja de medir solo el anexo | `pdf_export_test.dart:190-193`: no se añade `cropId` al fixture (venta y cosecha quedan sin cultivo a propósito); el margen no puede emitirse. No se toca el fixture. |
| `null` se convierte en `0` | Sin `?? 0` en el servicio: `incomesTotal`, `expensesTotal`, `areaHa` y los gastos de operación se filtran antes de dividir. Casos 4, 7 y 8 en rojo. |
| Una fila con **dos** cifras se rompe en dos avisos o en una sola cifra | `bestCropMargin` devuelve `CropMarginRow?`, no `List`; D2 oculta la fila si falta el área; D1 fija el %. Casos 1, 3, 4 y 12. |
| Se confunden las dos reglas de margen | El % usa todos los gastos del desglose; el `$/ha` solo operación. El ARB nombra «% de margen» y «/ha» por separado; caso 2 fija la cesta. |
| Moneda mixta se compara o se suma | Doble guard: `row.isMixed` y unicidad de `singleCurrency` entre candidatos. Casos 6 y 13; el fixture de 4 páginas es la guarda de integración. |
| CRLF en generados | `flutter gen-l10n` escribe CRLF; normalizar los 3 archivos de `lib/l10n/generated/` con `ReadAllText`/`WriteAllText` y confirmar `git diff --ignore-cr-at-eol` vacío (patrón en `docs/LEARNING.md:77,123,134`). |
| Sin esquema / migración / sync | No se añade campo: se usan `Crop.areaHa`, `Transaction`, `CropBreakdownRow.expenseTxs` e `isOperationExpense`, ya existentes. Cero SQL y cero backfill. |
| `derive` deduplica o el reloj hace el test frágil | La fila se concatena después de `derive` y el servicio no recibe `now`; caso 9 comprueba determinismo. No se toca `report_recommendations_test.dart`. |
| Banner de Inicio no muestra la fila | Igual que el hito 1: `evaluateAlerts` no emite esta regla; `FarmAlert` solo gana un valor de enum. Documentado en el reporte. |

## Orden de ejecución y definición de done

1. **Rojo**: crear los tres tests nuevos, ejecutarlos y anotar los fallos
   esperados.
2. **Línea base**: `flutter test test/export_parity_test.dart` (4 páginas) y
   `flutter test test/pdf_export_test.dart` (1 página), verdes.
3. **Implementación mínima** del §Paso 5, en ese orden.
4. **Verify**:
   - `flutter analyze` (proyecto entero) sin errores;
   - `flutter test test/crop_margin_test.dart test/report_parity_tanda3_hito2_test.dart test/l10n_crop_margin_test.dart test/export_parity_test.dart test/pdf_export_test.dart test/crop_totals_test.dart test/report_recommendations_test.dart test/l10n_placeholder_order_test.dart test/l10n_money_notation_test.dart`;
   - suite completa `flutter test` (línea base 1450/1450 del hito 1; el total
     sube con los tests nuevos);
   - `git diff --stat`, `git diff --check` y revisión de fin de línea de
     `lib/l10n/generated/`.
5. **Artefactos** (sin commit ni push): reporte en
   `docs/reports/2026-11-17_HHMM_hito2-margen-por-cultivo.md` con la tabla de
   criterios SC-2.1..2.5 y SC-G1..G6, el registro rojo→verde, el conteo de
   páginas (4 y 1), las decisiones D1/D2/D3 y la nota sobre las dos cestas de
   gasto; auditoría en
   `docs/audits/2026-11-17_HHMM_hito2-margen-por-cultivo.md`; después `/verify`
   y `/audit-report`.

**Done** cuando: analyze limpio; los tests nuevos y los targeted verdes; suite
completa verde; PDF en 4 páginas con el fixture congelado y 1 en el guarda del
anexo; una sola fila con las dos cifras y la misma cadena en los tres
pintadores; ARB ES/EN con placeholders ordenados y generados en LF; reporte y
auditoría escritos. **No se hace commit ni push** sin verbo explícito del
usuario en el turno correspondiente.

## Fuera de alcance

- Los otros cuatro hitos del PRD: concentración de comprador (SC-3.x),
  descuento del comprador (SC-4.x), brecha de rendimiento propio (SC-5.x) y
  días de caja restantes (SC-6.x). El hito 1 (SC-1.x) ya está cerrado.
- El campo `tipo` de cultivo, su migración y su backfill (D8 del PRD, plan
  3.3): sin evidencia de clasificación errónea.
- Catálogo de variedades, sombra/sol, densidad, recepa o asocio como entidades;
  cotizaciones, tasas de cambio y comparaciones con fincas externas.
- Cambios de esquema, columnas nuevas, sync nuevo ni backfill automático.
- Tocar los cuatro números congelados de `export_parity_test.dart`, el fixture
  sin `cropId` de `pdf_export_test.dart`, `evaluateAlerts` ni el banner de
  Inicio (aparte del valor nuevo del enum).
- Añadir una segunda fila para el margen por hectárea o convertir la fila en un
  panel nuevo dentro del desglose (D3 del PRD y D1/D2 de este plan).

## Cierre — 2026-11-17_1200

**DONE.** Ejecutado con TDD: rojo de 3 unidades antes del servicio, línea base
de 4 y 1 páginas verde, 14/14 dirigidos, 61/61 targeted, 1464/1464 suite
completa, analyze limpio, `diff --check` limpio y generados en LF.

- Reporte: `docs/reports/2026-11-17_1200_hito2-margen-por-cultivo.md`.
- Auditoría: `docs/audits/2026-11-17_1200_hito2-margen-por-cultivo.md` →
  **PASS** (SC-2.1..2.5 y SC-G1..G6; SC-G3 N/A por no sumar kilos), sin FAIL
  ni NIT.
- Decisión D1 aplicada: gana el mayor margen %, con `$/ha` como segunda cifra;
  D2 oculta la fila sin área u operación; D3 rotula «Margen por cultivo».
- Dos cestas documentadas y fijadas por test: el % usa todos los gastos del
  desglose y el `$/ha` solo operación (sin equipo).
- Guardas intactas: `paginasEsperadas = 4` y el fixture de 1 página sin
  `cropId`; `evaluateAlerts` y el banner de Inicio sin cambios.
- Nota: los ejemplos numéricos inconsistentes del plan se sustituyeron por
  equivalentes coherentes en los tests, conservando la intención de cada SC.
- Sin commit ni push: requiere verbo explícito.
- Siguiente: hito 3 (concentración de comprador).
