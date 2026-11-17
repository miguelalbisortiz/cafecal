---
prd: docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
status: DONE 2026-11-17_1225
created: 2026-11-17_1205
milestone: 3 · Concentración de comprador
source:
  - docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
  - docs/analysis/2026-11-17_calculos-recomendaciones.md
  - docs/plans/2026-11-17_1106_hito1-stock-sin-vender.plan.md
  - docs/plans/2026-11-17_1136_hito2-margen-por-cultivo.plan.md
repo_state: main en 74ca17c (Tandas 1, 2A, 2B, 2C e hitos 1 y 2 de Tanda 3 cerrados y pusheados)
---

# Plan: Hito 3 — Concentración de comprador

## Recomendación (decisiones confirmadas el 2026-11-17)

Antes de cerrar el plan se preguntaron las cuatro decisiones con más de una
opción razonable. El usuario eligió las cuatro marcadas «Recomendado»:

| # | Decisión | Elección confirmada | Por qué |
|---|---|---|---|
| D1 | Umbral | **`> 50 %` estricto**; exactamente 50 % → oculto | Concuerda con D4 y SC-3.2 («supera el 50 %») y con SC-3.3 («no supera»). El caso 50 % queda fijado por test. |
| D2 | Cifra citada | **Solo `{pct}` + `{buyer}`**, sin monto | SC-3.2 pide porcentaje, nombre y acción. No cita dinero: texto corto (menos riesgo de página extra) y sin formato de moneda nuevo. |
| D3 | Nombres de comprador | **Cadena exacta** (solo el `.trim()` que ya hace el alta) | `register_screen.dart:686` ya recorta; `TopAccounts.from` agrupa por cadena exacta. No se inventa una identidad que la app no guarda; se documenta como limitación y se mide en la prueba de finca real. |
| D4 | Ventas sin comprador | **Excluidas del denominador** | SC-3.1 dice «ventas con cliente identificado» y `TopAccounts.from` ya las ignora. Nunca se inventa un comprador «Sin nombre». |

Consecuencia de D1: el aviso exige **≥2 compradores y `share > 50 %`**; con un
solo comprador **no** se emite (registro explícito de D4 del PRD).
Consecuencia de D2: la fila no necesita `formatMoneyLabel` y no depende de la
moneda para formatear —pero sí para la guarda de SC-3.4, que es distinta.

## Objetivo

Convertir las ventas ya registradas en un aviso cuando más de la mitad dependen
de un comprador, con el porcentaje, el nombre y la acción de buscar un segundo
comprador, con el mismo texto en Reportes, PDF y Excel. Sin sumar monedas, sin
normalizar nombres, sin esquema, sin migración y sin tocar la paginación del PDF.

## Criterios de aceptación (trazabilidad)

| Criterio | Cómo se verifica en este hito |
|---|---|
| **SC-3.1** | `buyerConcentration` filtra ventas del período: `!deleted`, `type == income`, `isSaleCategory(category)` (`categories.dart:86`: `venta` y legadas `venta_*`), `client != null && client!.isNotEmpty`. Suma por comprador con `amountsByCurrency` (`currency_totals.dart:10`), sin cruzar monedas, y `share = ventas del principal / total de ventas identificadas × 100`. Test: A 700 + B 300 → `share == 70`. |
| **SC-3.2** | Con ≥2 compradores y `share > 50`: **una sola** fila con `{pct}`, `{buyer}` y la acción de buscar un segundo comprador, en los tres pintadores. Test de unidad + test de paridad. |
| **SC-3.3** | `buyers < 2` o `share <= 50` → `null` / `[]` en los tres pintadores, sin `0 %`, sin guion y sin «sin datos». Tests: exactamente 50 %, un comprador, sin comprador, sin ventas y montos 0. |
| **SC-3.4** | `isMixedCurrency(ventasIdentificadas)` (`currency_totals.dart:143`) → `null`. Guarda adicional: si el comprador principal tiene `currencies.length > 1`, tampoco se emite. Sin conversión y sin suma COP+USD. Tests de unidad y de paridad; el fixture congelado de 4 páginas es mixto, así que allí calla la fila. |
| **SC-G1** | `client` ausente o vacío → se excluye; todas las ventas sin comprador → `[]`. Nunca se sustituye por `0`, «Sin nombre» ni «sin datos». |
| **SC-G2** | Aunque la fila solo cita un porcentaje, SC-3.4 (regla específica de este hito) manda ocultarla con moneda mixta: el `share` se construye sumando montos y sin guarda sería falso. No se aplica aquí la excepción general de «porcentajes siguen visibles». Sin monto en el texto, sin `$` y sin conversión. |
| **SC-G3** | No aplica: esta recomendación no suma kilos y no consulta peso. Los listados «sin peso» siguen intactos y no alteran la cifra. |
| **SC-G4** | Una sola clave ARB `buyerConcentrationLine` y una sola función `buyerConcentrationMessage`; los tres pintadores concatenan la misma `Recommendation` **después** de `derive`. Test de paridad compara la cadena idéntica en pantalla, PDF y Excel. |
| **SC-G5** | `export_parity_test.dart` mantiene `paginasEsperadas = 4`, sus dos vías (`/Type /Page` y `/Count`) y su comentario congelado. El `pdf_export_test.dart` sigue en 1 página con el fixture sin `cropId`. |
| **SC-G6** | `buyerConcentrationTitle` y `buyerConcentrationLine` en ES y EN; placeholders `{pct}` y `{buyer}` en ese orden y tipo `String`; `{pct}` pasa por `formatPct` (`format.dart:36`) y el texto no contiene `$` ni `→` (U+2192). Barridos `l10n_placeholder_order_test.dart` y `l10n_money_notation_test.dart` siguen verdes sin editar. |

## Diseño concreto

### Regla única (decisión explícita)

La regla vive en **un solo archivo nuevo**, `lib/services/buyer_concentration.dart`:
filtro de ventas, guarda de moneda, agrupación por nombre exacto, umbral
estricto, selección del principal y redacción. Los tres pintadores **no
calculan**: añaden una línea que concatena lo que ese servicio devuelve.

La moneda **no se reimplementa**: el servicio llama a `amountsByCurrency` e
`isMixedCurrency` de `lib/services/currency_totals.dart`, la casa donde ya se
decide eso (el mismo patrón que `crop_totals.dart:66-70` con `isMixed` /
`singleCurrency` y `report_harvest_metrics.dart` con sus guardas). No se tocan
`crop_totals.dart`, `report_harvest_metrics.dart` ni `top_accounts.dart`.

`TopAccounts.from` (`models/top_accounts.dart:14-31`) **no se usa como fuente
directa**: agrupa cualquier ingreso con `client` (incluye `subvenciones`) y no
descarta borrados. El servicio nuevo aplica él mismo el filtro de venta; sí
reutiliza su criterio de agrupar por cadena exacta y su guarda
`AccountTotal.isMixed` como referencia de comportamiento.

`RecommendationService.derive` conserva su dedupe por `AlertRule`. La fila se
appenda **después** de `derive`, al igual que en los hitos 1 y 2;
`evaluateAlerts` no emite esta regla.

### Mapa del código leído (evidencia)

- **Comprador**: `Transaction.client` en `models/transaction.dart:47` (ctor `:127`, `copyWith :210`, `toJson :261`, `fromJson :317`). Alta/edición en `register_screen.dart:686` (`client = isSale ? _clientController.text.trim() : null`; carga previa en `:255`; campo en `:1289`). Persistencia en `transaction_provider.dart:346` y `sync_provider.dart:384`. **No hay normalización de mayúsculas ni de espacios interiores**: solo `.trim()`.
- **Ventas**: categoría `venta` / legadas `venta_*` (`categories.dart:82-87`); `isSaleCategory` es el filtro usado por `unsold_stock.dart:67`, `derived_harvests.dart:162` y `alert_service.dart:522`. Período compartido por `recordsForPeriod` (`report_period_records.dart:12-39`), que ya excluye borrados.
- **Moneda**: `amountsByCurrency` (`currency_totals.dart:10-21`), `isMixedCurrency` (`:143-151`) y `AccountTotal.byCurrency/isMixed/amount` (`top_accounts.dart:57-75`): ninguno suma COP con USD. `formatMoneyLabel` (`currencies.dart:69`) queda fuera de este hito por D2.
- **Pintadores**: `report_screen.dart:1951-1985` (`_builtRecommendationsCard`), `pdf_export_service.dart:1830-1871` (`_recommendationsSection`), `excel_export_service.dart:2032-2077` (`_whatsNextBlock`). Los tres ya reciben el período: pantalla `_recordsFor(tx)`, PDF y Excel el parámetro `periodRecords` (que usan para el margen del hito 2). No hace falta añadir parámetros nuevos.

### Archivos a tocar

| Archivo | Cambio | Riesgo |
|---|---|---|
| `lib/services/buyer_concentration.dart` (**nuevo**) | `BuyerConcentrationRow` + `buyerConcentration` + `buyerConcentrationMessage` + `buyerConcentrationRecommendations` | Medio |
| `lib/models/farm_alert.dart` | Valor `buyerConcentration` en `AlertRule`, después de `cropMargin` (identidad de la fila; **`evaluateAlerts` no lo emite**) | Bajo |
| `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` | `buyerConcentrationTitle`, `buyerConcentrationLine` con `{pct}` y `{buyer}` en ese orden | Bajo |
| `lib/l10n/generated/*.dart` | Regenerados con `flutter gen-l10n` y normalizados a LF | Medio (CRLF) |
| `lib/screens/report_screen.dart` | En `_builtRecommendationsCard`, después del bloque de margen (`:1984`), una línea con `records: _recordsFor(tx)` y `locale: tx.settings.numberLocale` | Bajo |
| `lib/services/pdf_export_service.dart` | En `_recommendationsSection`, después del bloque de margen (`:1870`), una línea con `records: periodRecords` y `locale: settings.numberLocale` | Medio (páginas) |
| `lib/services/excel_export_service.dart` | En `_whatsNextBlock`, después del bloque de margen (`:2076`), una línea con `records: periodRecords` y `locale: settings.numberLocale` | Bajo |
| `test/buyer_concentration_test.dart` (**nuevo**) | Casos SC-3.1..3.4 y SC-G1/G2 (incluye 50 %, 1 comprador, sin comprador, mixta, nombres) | — |
| `test/report_parity_tanda3_hito3_test.dart` (**nuevo**) | SC-G4: misma cadena en los tres pintadores; SC-3.3/SC-3.4: oculto en los tres | — |
| `test/l10n_buyer_concentration_test.dart` (**nuevo**) | SC-G6: ES/EN, placeholders, sin `$` ni `→`, acción presente en ambos idiomas | — |
| `test/export_parity_test.dart` | **No tocar** los cuatro números congelados ni su comentario (`paginasEsperadas = 4`) | Alto si se rompe |
| `test/pdf_export_test.dart` | **No tocar**: su fixture de 1 página lleva la venta y la cosecha sin `cropId` y sin `client` a propósito (`:133-168`) | Alto si se rompe |
| `test/report_parity_tanda3_hito1_test.dart`, `...hito2_test.dart`, `test/top_accounts_test.dart`, `test/currency_totals_test.dart` | **No tocar**; se ejecutan como regresión | — |

### Firma de datos

```dart
// lib/services/buyer_concentration.dart
class BuyerConcentrationRow {
  final String buyer;        // cadena exacta, ya recortada al registrar
  final String currency;     // código ISO de la única moneda del período
  final double sharePct;     // ventas del principal / total identificado * 100
  final double buyerAmount;  // monto del principal en esa única moneda
  final double salesTotal;   // total de ventas identificadas
  final int buyerCount;      // número de compradores distintos (>= 2)
  const BuyerConcentrationRow({...});
}

/// null → no se emite nada. [records] llega ya filtrado al período.
BuyerConcentrationRow? buyerConcentration({
  required Iterable<Transaction> records,
});

/// La misma frase en los tres pintadores.
String buyerConcentrationMessage(
  BuyerConcentrationRow row,
  AppLocalizations l10n,
  String locale,
) => l10n.buyerConcentrationLine(formatPct(row.sharePct), row.buyer);

/// 0 o 1 fila lista para «Qué hacer», concatenada DESPUÉS de `derive`.
List<Recommendation> buyerConcentrationRecommendations({
  required Iterable<Transaction> records,
  required AppLocalizations l10n,
  required String locale,
});
```

Detalles que fijan el comportamiento:

- **Filtro**: dentro del servicio, `!t.deleted && t.type == income && isSaleCategory(t.category) && t.client != null && t.client!.isNotEmpty`. Las ventas sin comprador quedan fuera del denominador (D4). Los ingresos no-venta con `client` (p. ej. `subvenciones`) no cuentan.
- **Moneda**: `isMixedCurrency(identificadas)` decide; con mezcla → `null` antes de sumar. Después, cada comprador acumula con `amountsByCurrency([...], type: income)` y se exige `byCurrency.length == 1`. `salesTotal` es la suma de esos totales de un solo código; nunca `amountsTotal` de un mapa mixto.
- **Identidad**: clave = `t.client!` tal cual (D3). `'Café S.A.'` y `'café  s.a.'` son dos compradores; el nombre pintado es el del registro ganador.
- **Umbral**: `buyerCount >= 2` **y** `sharePct > 50` (D1). Con `sharePct == 50` → `null`. Con `salesTotal <= 0` → `null` (nunca `0 %`).
- **Orden**: por `buyerAmount` descendente, desempate por `buyer` ascendente; sin `DateTime.now()` dentro del servicio (la ventana la decide el período). Con `> 50 %` el principal es único, así que el desempate solo fija determinismo.
- **Texto**: `buyerConcentrationLine` = «El {pct}% de tus ventas del período vienen de {buyer}. Busca un segundo comprador antes de depender de uno solo.»; `buyerConcentrationTitle` = «Concentración de comprador». `severity: info`, `suggestion: ''` para no repetir la acción. EN: «{pct}% of your sales for the period come from {buyer}. Find a second buyer before relying on just one.»

### Flujo fuente → tres pintadores

```
transactions del período (recordsForPeriod / _recordsFor)
         │
         ▼  currency_totals.dart · amountsByCurrency + isMixedCurrency (ÚNICA regla de moneda)
         ▼  lib/services/buyer_concentration.dart (ÚNICA regla: ventas, ≥2, >50 %, texto)
    BuyerConcentrationRow? → 0 o 1 Recommendation (rule = AlertRule.buyerConcentration)
         │
         ├── report_screen.dart  _builtRecommendationsCard  (after derive + stock + margen)
         ├── pdf_export_service.dart  _recommendationsSection (after derive + stock + margen)
         └── excel_export_service.dart  _whatsNextBlock       (after derive + stock + margen)
```

Cada pintador conserva sus `derive(alerts)`, stock y margen y añade una sola
línea: `...buyerConcentrationRecommendations(records: ..., l10n: l10n, locale: ...)`.
El render de la fila no se reescribe. En PDF y Excel se pasa `periodRecords`
(el mismo que el margen), **no** `history`/`active`, para que el porcentaje
corresponda al período exportado.

## Secuencia TDD

Regla: **rojo → implementación mínima → verde → verify**. No se escribe código
de producción hasta que los tests nuevos fallan por la razón esperada (import o
símbolo inexistente cuenta como rojo; se anota el mensaje en el reporte).
`now` no interviene: las transacciones se construyen con fechas dentro del
período, igual que en el hito 2.

### Paso 1 · ROJO — `test/buyer_concentration_test.dart` (nuevo, puro)

1. **SC-3.1 / SC-3.2 · dos compradores con >50 %**: A 700 COP + B 300 COP → `buyerCount == 2`, `sharePct == 70`, `buyer == 'A'`, `salesTotal == 1000`; el mensaje contiene `70%`, el nombre y «Busca un segundo comprador».
2. **D1 / SC-3.3 · exactamente 50 %**: A 500 + B 500 → `null` y `[]`. Es el caso límite del umbral estricto.
3. **SC-3.3 / D4 del PRD · un solo comprador**: A 1000 → `null` y `[]`, aunque el share sea 100 %.
4. **SC-G1 / D4 · sin comprador**: ventas con `client: null` y `client: ''` → `[]`. Variante mixta: A 700 con cliente + 300 sin cliente → `sharePct == 100` (el denominador excluye la venta sin comprador).
5. **SC-3.4 · moneda mixta**: A COP 700 + B USD 300 → `null`/`[]`. Variante defensiva: un mismo comprador con 700 COP + 300 USD → `null`. Sin conversión.
6. **D3 · nombres con mayúsculas/espacios**: `'Café S.A.'` 700 y `'café  s.a.'` 300 → **dos** compradores; gana el primero con su cadena exacta en el mensaje. Ningún test debe esperar que se unifiquen.
7. **SC-3.1 · solo ventas**: ingreso `subvenciones` con `client: 'A'` 900 + venta `venta` con B 100 → no hay aviso; la venta legada `venta_cafe` sí cuenta; una venta con `deleted: true` no cuenta.
8. **SC-G1 · sin datos**: sin ventas, o ventas con `amount: 0` → `[]`; nunca `0 %`, `null` convertido en cero ni texto «sin datos».
9. **Determinismo**: A 600 + B 300 + C 100 → `sharePct == 60`; dos llamadas con la misma entrada devuelven el mismo `buyer` y la misma cifra.

### Paso 2 · ROJO — `test/report_parity_tanda3_hito3_test.dart` (nuevo)

10. **SC-G4 · tres pintadores**: escenario de una moneda con dos compradores (A 700 / B 300); construir pantalla (`ReportScreen`), PDF (`PdfExportService.buildReport`) y Excel (`ExcelExportService.buildReport`) con el mismo `l10n`; la cadena de `buyerConcentrationMessage` aparece **idéntica** en los tres y es la única fila nueva.
11. **SC-3.3 · oculto en los tres**: exactamente 50 % y un solo comprador → ningún pintador añade la fila; las recomendaciones previas siguen intactas.
12. **SC-3.4 / SC-G2 · mezcla en los tres**: COP + USD → la fila nueva no aparece en ninguno; se reutiliza el patrón de escenario `mezcla` del test de paridad del hito 2.

### Paso 3 · ROJO — `test/l10n_buyer_concentration_test.dart` (nuevo)

13. **SC-G6**: ambas claves en ES y EN; `{pct}` y `{buyer}` en ese orden y declaradas `String` en los dos idiomas; el generado expone los getters; la frase no contiene `$` ni `→`; la acción de buscar un segundo comprador está en los dos idiomas. Los barridos existentes se ejecutan sin editar.

### Paso 4 · Línea base de las guardas de paginación

14. `flutter test test/export_parity_test.dart` **antes** de tocar los pintadores: verde con 4 páginas por `/Type /Page` **y** `/Count`. `flutter test test/pdf_export_test.dart`: verde con 1 página en el caso sin anexo. No se tocan fixtures ni expectativas; el fixture de 4 páginas es mixto (COP+USD) y el de 1 página lleva la venta sin `client`, así que la fila nueva no debe aparecer en ninguno.

### Paso 5 · Implementación mínima

1. `lib/models/farm_alert.dart`: valor `buyerConcentration` en `AlertRule`.
2. `lib/services/buyer_concentration.dart`: las cuatro unidades de la firma, con `amountsByCurrency` e `isMixedCurrency` importados de `currency_totals.dart`.
3. ARB ES/EN + `flutter gen-l10n` + normalización LF de `lib/l10n/generated/`.
4. Los tres pintadores: una línea de concatenación cada uno, después del margen; sin reescribir el render de fila ni añadir parámetros.
5. Tests en verde; guardas de 4 y 1 páginas intactas.

### Paso 6 · Verify

Orden: `flutter analyze` → tests targeted → suite completa → gate de ARB/LF →
reporte y auditoría (ver §Orden de ejecución).

## Riesgos y guardas

| Riesgo | Guarda concreta |
|---|---|
| El PDF gana una página (SC-G5) | `export_parity_test.dart:223` `paginasEsperadas = 4`, verificado por `/Type /Page` **y** `/Count`, con comentario intacto. Si sube a 5, antes de recompactar se comprueba si la guarda de moneda mixta falló (el fixture es mixto). **Nunca** se actualiza el número a ciegas. |
| El guarda de 1 página deja de medir solo el anexo | `pdf_export_test.dart:190-193`: no se añaden `cropId` ni `client` al fixture (`:133-168`); la fila no puede emitirse. No se toca el fixture. |
| `null` se convierte en `0` o en «Sin nombre» | Sin `?? 0` y sin fallback de nombre: `client` ausente/vacío se filtra antes de sumar. Casos 4 y 8 en rojo. |
| Aparecen dos filas o se dedupe la nueva | El servicio devuelve `BuyerConcentrationRow?` (0 o 1) y la fila se concatena después de `derive`; caso 10 comprueba una sola fila nueva en los tres. No se relaja `report_recommendations_test.dart`. |
| Se suman COP con USD | `isMixedCurrency` antes de cualquier suma + unicidad de `byCurrency` por comprador. Caso 5 y paridad con mezcla (caso 12). No se usa `amountsTotal` para la cifra, solo `amountsByCurrency`. |
| Se normalizan nombres sin decisión | D3: clave = cadena exacta. Caso 6 fija que `'Café S.A.'` y `'café  s.a.'` cuentan como dos compradores. Sin cambios en `register_screen.dart`. |
| El umbral se interpreta como inclusivo | D1: `> 50` estricto; caso 2 fija 50 % → `null` en los tres pintadores (caso 11). |
| CRLF en generados | `flutter gen-l10n` escribe CRLF; normalizar los 3 archivos de `lib/l10n/generated/` con `ReadAllText`/`WriteAllText` y confirmar `git diff --ignore-cr-at-eol` vacío (patrón en `docs/LEARNING.md:77,123,134`). |
| Sin esquema / migración / sync | No se añade campo: se usan `Transaction.client`, `amount`, `currency`, `category`, `deleted` y `date`, ya existentes y ya sincronizados. Cero SQL, cero backfill, cero `pendingSync` nuevo. |
| Banner de Inicio no muestra la fila | Igual que hitos 1 y 2: `evaluateAlerts` no emite esta regla; `FarmAlert` solo gana un valor de enum. Documentado en el reporte. |
| Prueba con finca real pendiente | Validación **no bloqueante** del PRD (`Open Questions`): contar cuántos avisos genera el umbral de 50 % y anotar los casos límite en `docs/reports/`. Si el ruido es alto, se ajusta en un PRD posterior, nunca en caliente. |

## Orden de ejecución y definición de done

1. **Rojo**: crear los tres tests nuevos, ejecutarlos y anotar los fallos esperados.
2. **Línea base**: `flutter test test/export_parity_test.dart` (4 páginas) y `flutter test test/pdf_export_test.dart` (1 página), verdes.
3. **Implementación mínima** del §Paso 5, en ese orden.
4. **Verify**:
   - `flutter analyze` (proyecto entero) sin errores;
   - `flutter test test/buyer_concentration_test.dart test/report_parity_tanda3_hito3_test.dart test/l10n_buyer_concentration_test.dart test/export_parity_test.dart test/pdf_export_test.dart test/report_parity_tanda3_hito1_test.dart test/report_parity_tanda3_hito2_test.dart test/top_accounts_test.dart test/currency_totals_test.dart test/report_recommendations_test.dart test/l10n_placeholder_order_test.dart test/l10n_money_notation_test.dart`;
   - suite completa `flutter test` (línea base **1464/1464** del cierre del hito 2; el total sube con los tests nuevos);
   - `git diff --stat`, `git diff --check` y revisión de fin de línea de `lib/l10n/generated/`.
5. **Artefactos** (sin commit ni push): reporte en `docs/reports/2026-11-17_HHMM_hito3-concentracion-de-comprador.md` con la tabla de criterios SC-3.1..3.4 y SC-G1..G6 (SC-G3 como N/A), el registro rojo→verde, las cuatro decisiones D1..D4, el conteo de páginas (4 y 1) y la nota sobre nombres exactos y ventas sin comprador; auditoría en `docs/audits/2026-11-17_HHMM_hito3-concentracion-de-comprador.md`; después `/verify` y `/audit-report`.

**Done** cuando: analyze limpio; los tests nuevos y los targeted verdes; suite
completa verde; PDF en 4 páginas con el fixture congelado y 1 en el guarda del
anexo; una sola fila con `%`, nombre y acción idénticos en los tres pintadores;
umbral estricto, nombres exactos y ventas sin comprador fijados por test;
ARB ES/EN con placeholders ordenados y generados en LF; reporte y auditoría
escritos. **No se hace commit ni push** sin verbo explícito del usuario en el
turno correspondiente.

## Fuera de alcance

- Los otros hitos del PRD: descuento del comprador (SC-4.x), brecha de rendimiento propio (SC-5.x) y días de caja restantes (SC-6.x). Los hitos 1 (SC-1.x) y 2 (SC-2.x) ya están cerrados.
- El campo `tipo` de cultivo, su migración y su backfill (decisión D8 del PRD, plan 3.3): sin evidencia de clasificación errónea.
- Normalización de nombres de comprador, catálogo de compradores o cambio en el alta (`register_screen.dart`): D3 fija cadena exacta.
- Cambios de esquema, columnas nuevas, sync nuevo, backfill automático, cotizaciones, tasas de cambio y comparaciones con fincas externas.
- Añadir la fila al banner de Inicio, modificar `evaluateAlerts` / `alert_service.dart` o tocar los cuatro números congelados de `export_parity_test.dart` y el fixture sin `cropId` de `pdf_export_test.dart`.
- Citar el monto del comprador en el texto (D2) o mostrar un comprador «Sin nombre» para las ventas no atribuidas (D4).

## Cierre — 2026-11-17_1225

**DONE.** Ejecutado con TDD: rojo de 3 unidades antes del servicio, línea base
de 4 y 1 páginas verde, 13/13 dirigidos, 51/51 targeted, 1477/1477 suite
completa, analyze limpio, `diff --check` limpio y generados en LF.

- Reporte: `docs/reports/2026-11-17_1223_hito3-concentracion-de-comprador.md`.
- Auditoría: `docs/audits/2026-11-17_1223_hito3-concentracion-de-comprador.md` →
  **PASS** (SC-3.1..3.4 y SC-G1..G6; SC-G3 N/A por no sumar kilos), sin FAIL
  ni NIT.
- Decisiones aplicadas: D1 `>50 %` estricto con ≥2 compradores; D2 solo `%` y
  nombre sin monto; D3 cadena exacta; D4 ventas sin comprador fuera del
  denominador.
- Doble guarda de moneda (global y por comprador) reutilizando
  `amountsByCurrency` e `isMixedCurrency`; una sola redacción en los tres
  pintadores, concatenada después de `derive`.
- Guardas intactas: `paginasEsperadas = 4` y el fixture de 1 página sin
  `cropId` ni `client`; `evaluateAlerts` y el banner de Inicio sin cambios.
- Dos detalles del plan ajustados en la ejecución y documentados en el reporte:
  el caso 4 usa A700/B300 + 300 sin comprador (→ 70 %) para cumplir `≥2`; y
  los tests nuevos son 13 (el caso 14 del plan era la línea base), con suite
  1477/1477.
- Sin commit ni push: requiere verbo explícito.
- Tanda 3 completa (hitos 1, 2 y 3). Prueba con finca real pendiente no
  bloqueante.
