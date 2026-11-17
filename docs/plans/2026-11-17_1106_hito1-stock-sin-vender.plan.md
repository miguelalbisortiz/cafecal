---
prd: docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
status: DRAFT
created: 2026-11-17_1106
milestone: 1 · Stock sin vender
source:
  - docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md
  - docs/plans/2026-11-17_0918-mejoras-cultivos-y-recomendaciones.plan.md
  - docs/analysis/2026-11-17_calculos-recomendaciones.md
repo_state: main en 2ceaba3 (Tandas 1, 2A, 2B, 2C cerradas; PRD de Tanda 3 pusheado)
---

# Plan: Hito 1 — Stock sin vender

## Recomendación (decisiones confirmadas el 2026-11-17)

Antes de cerrar el plan se preguntaron las tres decisiones con más de una opción
razonable. El usuario eligió las tres marcadas «Recomendado»:

| # | Decisión | Elección |
|---|---|---|
| D1 | Dónde vive la regla | **Servicio puro nuevo** + filas añadidas a «Qué hacer» en los tres pintadores, **sin pasar por `RecommendationService.derive`** (dedupe por `AlertRule`). El motor `evaluateAlerts` queda intacto. |
| D2 | Ventana | **Función nueva** con corte rodante exacto `now - 365 días` y `now` inyectable. No se toca `soldVsHarvested`, que corta en `DateTime(now.year, now.month - 11, 1)`. |
| D3 | Listado «sin peso» | **Solo pantalla** (donde ya vive) + test «gemelo». No se añade sección nueva en PDF/Excel en este hito: evita riesgo de página extra. |

Consecuencia de D1: la fila de stock **no** aparece en el banner de Inicio en
este hito (el banner consume `FarmAlert`, no el servicio nuevo). Queda escrito
para que nadie lo lea como olvido: el milestone 1 cubre los **tres pintadores del
reporte**, que es lo que exigen SC-G4 y el PRD.

## Objetivo

Convertir `cosechaKg − ventaKg` en un aviso por cultivo, con la cifra exacta y la
acción concreta, con el mismo texto en Reportes, PDF y Excel. Sin esquema, sin
migración, sin monedas mezcladas y sin tocar la paginación del PDF.

## Criterios de aceptación (trazabilidad)

| Criterio | Cómo se verifica en este hito |
|---|---|
| **SC-1.1** | `unsoldStockByCrop` usa `now` inyectable, corte `now.subtract(Duration(days: 365))`, bounds inclusivos, y calcula kg cosechados − kg vendidos por cultivo con `kgFromUnit` sobre registros con peso convertible. Test: registro al día 364 cuenta, al día 366 no. |
| **SC-1.2** | Resultado `> 0` → una fila por cultivo con `{kg}` formateado, `{crop}` y la acción «Define comprador o presentación antes de la próxima cosecha», en los tres pintadores. Test de paridad + test de unidad. |
| **SC-1.3** | Sin cosecha ni venta con peso en la ventana → `[]`; tampoco se emite fila con `0 kg` ni con resultado ≤ 0. Tests dedicados. |
| **SC-1.4** | Los registros con unidad variable y peso en blanco no suman; se listan aparte con `pendingWeightHarvests` / `pendingWeightSales` en la pantalla. Test «gemelo»: mismo caso con el peso en blanco da exactamente la misma cifra. |
| **SC-G1** | `quantity: null` / `equivalentKg: null` → `kgFromUnit` devuelve `null` y la fila no se emite; nunca `0` ni «sin datos». Cubierto por el test gemelo y por el caso «solo registros en blanco». |
| **SC-G2** | El aviso es de kilos: no cita dinero, no hay conversión ni suma de monedas. Test con COP + USD en la misma ventana: la fila sigue visible y el texto no contiene `$` ni código de moneda. |
| **SC-G3** | Cosecha y venta sin peso convertible entran en las listas «sin peso» de `report_screen.dart:938-940` y no alteran los kg del aviso. Test gemelo. |
| **SC-G4** | Un único ARB `stockUnsoldLine` produce el texto; los tres pintadores llaman al mismo formateador. Test de paridad compara la cadena en pantalla, PDF y Excel. |
| **SC-G5** | `export_parity_test.dart` sigue con `paginasEsperadas = 4` y sus dos vías (`/Type /Page` y `/Count`) sin cambios de comentario ni de número. |
| **SC-G6** | Claves en `app_es.arb` y `app_en.arb`, placeholders `{kg}` y `{crop}` en orden de frase, tipo `String`, y cifra con `formatKg` (separador del idioma). Sin `$` y sin `→` (U+2192). Tests `l10n_placeholder_order_test.dart`, `l10n_money_notation_test.dart` y uno nuevo de claves ES/EN. |

## Diseño concreto

### Regla única (decisión explícita)

La regla vive en **un solo archivo nuevo**, `lib/services/unsold_stock.dart`:
ventana, conversión, filtro `> 0`, agrupación por cultivo y redacción. Los tres
pintadores **no calculan**: solo appendan las filas que ese servicio devuelve a
la lista que ya pintan en «Qué hacer». No se duplica la fórmula en ningún
pintador y no se mete en `alert_service.dart` (D1).

`RecommendationService.derive` conserva su dedupe por `AlertRule` y sus tests
intactos: las filas de stock se concatenan **después** de `derive`, en cada
pintador, por lo que dos cultivos con stock generan dos filas.

### Archivos a tocar

| Archivo | Cambio | Riesgo |
|---|---|---|
| `lib/services/unsold_stock.dart` (**nuevo**) | `UnsoldStockRow` + `unsoldStockByCrop(...)` + `unsoldStockMessage(...)` | Medio |
| `lib/models/farm_alert.dart` | Añadir el valor `unsoldStock` al enum `AlertRule` (identidad de la fila; **no** se emite `FarmAlert` desde `evaluateAlerts`) | Bajo |
| `lib/services/report_harvest_metrics.dart` | Hacer pública la conversión de cosecha a kg: `double harvestKg(Harvest h, {double sacoKg = kSacoKgPorDefecto})`; `_kgOf` delega en ella. Misma fórmula para la tarjeta existente y para el servicio nuevo | Bajo |
| `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` | `stockUnsoldTitle`, `stockUnsoldLine` con `{kg}` y `{crop}` en ese orden | Bajo |
| `lib/l10n/generated/*.dart` | Regenerados con `flutter gen-l10n` y normalizados a LF | Medio (CRLF) |
| `lib/screens/report_screen.dart` | En `_builtRecommendationsCard` (`:1949-2010`), después del loop de `recommendations`, añadir las filas de stock con el mismo estilo de fila | Bajo |
| `lib/services/pdf_export_service.dart` | En `_recommendationsSection` (`:1828-1874`), después del loop, añadir las filas de stock con `_statementRow` | Medio (páginas) |
| `lib/services/excel_export_service.dart` | En `_whatsNextBlock` (`:2024-2068`), después del loop, añadir las filas de stock con `row([TextCellValue(...)])` | Bajo |
| `test/unsold_stock_test.dart` (**nuevo**) | Casos SC-1.1..1.4 y SC-G1/G2/G3 | — |
| `test/report_parity_tanda3_hito1_test.dart` (**nuevo**) | SC-G4: misma cadena en los tres pintadores | — |
| `test/l10n_stock_sin_vender_test.dart` (**nuevo**) | SC-G6: ES/EN, placeholders, sin `$` ni `→` | — |
| `test/export_parity_test.dart` | **No tocar** los cuatro números congelados; solo puede ganar un test nuevo que reutilice `_fixture()` para comprobar la fila de stock sin alterar `paginasEsperadas = 4` | Alto si se rompe |

### Firma de datos

```dart
// lib/services/unsold_stock.dart
class UnsoldStockRow {
  final String? cropId;
  final String cropName;
  final double harvestedKg;
  final double soldKg;
  final double unsoldKg;
  const UnsoldStockRow({...});
}

List<UnsoldStockRow> unsoldStockByCrop({
  required Iterable<Transaction> transactions,
  required Iterable<Harvest> harvests,
  required Iterable<Crop> crops,
  required double sacoKg,
  required DateTime now,
}); // filtra ahora − 365 d … ahora, devuelve solo unsoldKg > 0, ordenado desc

String unsoldStockMessage(UnsoldStockRow row, AppLocalizations l10n, String locale);
// l10n.stockUnsoldLine(formatKg(row.unsoldKg, locale), row.cropName)
```

Detalles de la firma que fijan el comportamiento:

- **Fuente de cosechas**: `tx.harvests` (getter `effectiveHarvests`, `transaction_provider.dart:165-168`), filtrado a la ventana. Incluye cosechas derivadas de la venta (cancelan los kg vendidos: no inflan el stock) y las derivadas de jornal medido (kg reales de recogida). Usar `storedHarvests` perdería esos kilos medidos.
- **Fuente de ventas**: transacciones `!deleted`, `type == income`, `isSaleCategory(category)`, en la ventana.
- **Conversión**: `kgFromUnit(cantidad, unidad, equivalentKg, sacoKg: sacoKg)` para ventas; `harvestKg(h, sacoKg: sacoKg)` (nueva función pública en `report_harvest_metrics.dart`) para cosechas. `null` → no suma.
- **Cultivo**: se agrupa por `cropId`; filas con `cropId == null` se omiten (no hay cultivo al que dirigir la acción). Nombre desde `crops`, con `cropId` como fallback.
- **Orden**: por `unsoldKg` descendente, sin tope (como el resto de «Qué hacer»).
- **Texto**: `stockUnsoldLine` contiene cifra y acción en la misma frase. `stockUnsoldTitle` es la etiqueta corta. `suggestion` queda vacía para no repetir la acción. Los tres pintadores reciben `Recommendation(rule: AlertRule.unsoldStock, severity: warning, title: l10n.stockUnsoldTitle, message: unsoldStockMessage(...), suggestion: '')`.

### Flujo fuente → tres pintadores

```
TransactionProvider.transactions / harvests / crops / settings.sacoKg
        │
        ▼  lib/services/unsold_stock.dart  (ÚNICA regla: 365 d, kg, > 0, texto)
   List<UnsoldStockRow> → List<Recommendation> (rule = AlertRule.unsoldStock)
        │
        ├── report_screen.dart  _builtRecommendationsCard  (after derive loop)
        ├── pdf_export_service.dart  _recommendationsSection (after derive loop)
        └── excel_export_service.dart  _whatsNextBlock       (after derive loop)
```

Cada pintador conserva su `derive(alerts)` actual y hace una sola línea nueva:
`final recs = [...derive(alerts), ...unsoldStockRecommendations(...)];`
El pintado de la fila (avatar/número en pantalla, `_statementRow` en PDF,
`row([TextCellValue])` en Excel) **no se reescribe**.

## Secuencia TDD

Regla: **rojo → implementación mínima → verde → verify**. No se escribe código de
producción hasta que los tests nuevos fallan por la razón esperada (import o
símbolo inexistente cuenta como rojo; se anota el mensaje en el reporte).

### Paso 1 · ROJO — `test/unsold_stock_test.dart` (nuevo, puro)

`now = DateTime(2026, 11, 17)` fijo en todos los casos.

1. **SC-1.1 · ventana rodante**: cosecha 100 kg al día 364 + venta 40 kg al día
   364 → `unsoldKg == 60`; cosecha 500 kg al día 366 → no cuenta.
2. **SC-1.1 · límites inclusivos**: registro exactamente en `now - 365 d` y en
   `now` → cuentan; `now - 366 d` → no.
3. **SC-1.2 · una fila por cultivo**: Café 60 kg y Plátano 20 kg → 2 filas en
   ese orden; `unsoldStockMessage` contiene los kg formateados, el cultivo y la
   acción de definir comprador/presentación.
4. **SC-1.2 / SC-1.3 · no avisa sin excedente**: cosecha 50 / venta 50 → `[]`;
   cosecha 40 / venta 50 → `[]`.
5. **SC-1.3 · ventana vacía**: sin registros con peso → `[]` (ni `0 kg`, ni
   «sin datos»).
6. **SC-G3 / SC-1.4 · GEMELOS**: caso base (cosecha 100 kg + venta 40 kg → 60);
   gemelo idéntico añadiendo una cosecha `racimo` con `equivalentKg: null` y una
   venta `cajon` con `equivalentKg: null` → sigue dando **60**, y
   `pendingWeightHarvests` / `pendingWeightSales` devuelven 1 cada uno.
7. **SC-G1 · dato ausente**: solo registros sin peso en la ventana → `[]`;
   ninguna fila con `0`.
8. **SC-G2 · moneda mixta**: venta COP + venta USD con kg → fila visible, sin
   `$` ni `COP`/`USD` en el mensaje (es recomendación de kilos).
9. **Regla compartida de peso**: 1 `saco` con `sacoKg: 60` → 60 kg (no 70),
   comprobando que el servicio usa la misma conversión que
   `ReportHarvestMetrics`.
10. **Borde**: cosecha con `cropId: null` → sin fila.

### Paso 2 · ROJO — `test/report_parity_tanda3_hito1_test.dart` (nuevo)

11. **SC-G4 · tres pintadores**: un cultivo con cosecha 100 kg y venta 40 kg;
    construir pantalla (`ReportScreen`), PDF (`PdfExportService.buildReport`) y
    Excel (`ExcelExportService.buildReport`) con el mismo `l10n`; la cadena
    `unsoldStockMessage` aparece **idéntica** en los tres (mismo número, mismo
    orden de palabras).
12. **SC-1.2 · dos cultivos**: dos filas de stock en los tres pintadores, sin
    dedupe por regla.

### Paso 3 · ROJO — `test/l10n_stock_sin_vender_test.dart` (nuevo)

13. **SC-G6**: ambas claves existen en ES y EN; placeholders `{kg}` y `{crop}`
    en ese orden en los dos idiomas; el generado expone los getters; el mensaje
    no contiene `$` ni `→`; la acción aparece en los dos idiomas.
    Los barridos existentes `l10n_placeholder_order_test.dart` y
    `l10n_money_notation_test.dart` se ejecutan sin editar: deben seguir verdes
    con las claves nuevas.

### Paso 4 · ROJO confirmado en la guarda de páginas

14. Ejecutar `flutter test test/export_parity_test.dart` **antes** de tocar los
    pintadores: verde con 4 páginas. Es la línea base. Si tras añadir la fila
    pasa a 5, se reparte el contenido en el espacio existente del PDF (fuentes
    pequeñas / `_statementRow(small: true)`), **nunca** cambiando
    `paginasEsperadas`.

### Paso 5 · Implementación mínima

1. `lib/services/report_harvest_metrics.dart`: extraer `harvestKg(...)` pública;
   `_kgOf` delega. Sin cambiar ningún resultado existente.
2. `lib/models/farm_alert.dart`: valor `unsoldStock` en `AlertRule`.
3. `lib/services/unsold_stock.dart`: las tres funciones de la firma de datos.
4. ARB ES/EN + `flutter gen-l10n` + normalización LF de `lib/l10n/generated/`.
5. Los tres pintadores: una línea de concatenación cada uno; sin reescribir el
   render de fila.
6. tests en verde; `export_parity_test.dart` sigue en 4.

### Paso 6 · Verify

Orden: `flutter analyze` → tests targeted → suite completa → gate de ARB/LF →
reporte y auditoría (ver §5).

## Riesgos y guardas

| Riesgo | Guarda concreta |
|---|---|
| El PDF gana una página | `export_parity_test.dart:223` `paginasEsperadas = 4`, verificado por `/Type /Page` **y** `/Count`. Si cambia, se recompacta el contenido; no se actualiza el número a ciegas. Comentario de las líneas 214-219 intacto. |
| `null` se convierte en `0` | `kgFromUnit` devuelve `null` para `racimo`/`cajon` sin peso; el servicio omite la fila. Casos 5, 6 y 7 en rojo. |
| Kilos sin peso entran en la suma | Test gemelo (caso 6): con y sin el peso en blanco la cifra es idéntica; las listas `pendingWeight*` siguen en `report_screen.dart:938-940`. |
| Ventana de 365 días móviles | `now` es parámetro obligatorio; casos 1 y 2 fijan día 364 / 365 / 366. No se reutiliza el corte de `soldVsHarvested` (`report_harvest_metrics.dart:487`). |
| Moneda mixta | El aviso es de kilos: no consulta `isMixedCurrency` porque no cita dinero; caso 8 comprueba que no aparece símbolo ni código de moneda. Las recomendaciones que sí citan dinero siguen rigiéndose por SC-G2 en sus propios hitos. |
| Sin esquema / migración / sync | No se añade ningún campo: se usan `Harvest.amount/unit/equivalentKg` y `Transaction.quantity/unit/equivalentKg/paid/deleted`, ya existentes. Cero SQL, cero backfill, cero `pendingSync`. |
| CRLF en generados | `flutter gen-l10n` escribe CRLF; normalizar los 3 archivos de `lib/l10n/generated/` a LF con `[IO.File]::ReadAllText` / `WriteAllText` y confirmar que `git diff --ignore-cr-at-eol` no muestra ruido (patrón documentado en `docs/LEARNING.md:77,123,134`). |
| `derive` deduplica dos cultivos | Las filas se appendan después de `derive` (D1); caso 12 lo verifica en los tres pintadores. No se relaja el dedupe ni se toca `report_recommendations_test.dart`. |
| Banner de Inicio no muestra la fila | Decisión D1 explícita: `evaluateAlerts` no emite esta regla. `FarmAlert` no cambia de contenido; solo gana un valor de enum. Documentado en el reporte.

## Orden de ejecución y definición de done

1. **Rojo**: crear los tres tests nuevos, ejecutarlos, anotar los fallos esperados.
2. **Línea base**: `flutter test test/export_parity_test.dart` en 4 páginas.
3. **Implementación mínima** del §Paso 5, en ese orden.
4. **Verify**:
   - `flutter analyze` (proyecto entero) sin errores;
   - `flutter test test/unsold_stock_test.dart test/report_parity_tanda3_hito1_test.dart test/l10n_stock_sin_vender_test.dart test/export_parity_test.dart test/report_recommendations_test.dart test/l10n_placeholder_order_test.dart test/l10n_money_notation_test.dart`;
   - suite completa `flutter test` (línea base 1437/1437 de la Tanda 2C; el total sube con los tests nuevos);
   - `git diff --stat` y revisión de fin de línea de `lib/l10n/generated/`.
5. **Artefactos** (sin commit ni push): reporte en
   `docs/reports/2026-11-17_HHMM_hito1-stock-sin-vender.md` con la tabla de
   criterios SC-1.1..1.4 y SC-G1..G6, el registro rojo→verde, el conteo de
   páginas y el diff de generados; auditoría en
   `docs/audits/2026-11-17_HHMM_hito1-stock-sin-vender.md`; después `/verify` y
   `/audit-report`.

**Done** cuando: analyze limpio; los tests nuevos y los targeted verdes; suite
completa verde; PDF en 4 páginas con el fixture congelado; la misma cadena en
los tres pintadores; ARB ES/EN con placeholders ordenados y generados en LF;
reporte y auditoría escritos. **No se hace commit ni push** sin verbo explícito
del usuario en el turno correspondiente.

## Fuera de alcance

- Los otros cinco hitos del PRD: margen por cultivo/hectárea (SC-2.x),
  concentración de comprador (SC-3.x), descuento del comprador (SC-4.x),
  brecha de rendimiento propio (SC-5.x) y días de caja restantes (SC-6.x).
- El campo `tipo` de cultivo, su migración y su backfill (decisión D8 del PRD,
  plan 3.3): sin evidencia de clasificación errónea.
- Catálogo de variedades, sombra/sol, densidad, recepa o asocio como entidades.
- Cambios de esquema, columnas nuevas, sync nuevo, cotizaciones o tablas
  externas.
- Añadir la sección «sin peso» a PDF y Excel (decisión D3 de este plan).
- Tocar los cuatro números congelados de `export_parity_test.dart`.
- Cualquier cambio en `evaluateAlerts` / `alert_service.dart` (aparte del valor
  nuevo del enum) y en el banner de Inicio.
