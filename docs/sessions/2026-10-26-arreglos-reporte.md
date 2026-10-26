# Sesión — lunes 26 de octubre de 2026 (arreglos del reporte)

> Estado al cierre: la prueba en producción cerró con sus cuatro hallazgos
> resueltos y verificados en la app pública. F1–F3 en un commit; F5 en otro.
> Informe: `docs/reports/2026-10-26_prueba-produccion.md` (§6).
> PRD: `docs/prds/2026-10-26_1901-cifras-del-reporte.prd.md`.
> Sesión previa (solo la prueba): `docs/sessions/2026-10-26-prueba-produccion.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`bdf27e9`** («los textos del reporte salen del
  tema»).
- `gh-pages` = **`109e77b`** sirviendo el bundle con F1–F5. Deploy verificado:
  sha256 `735175D6…41C7`, confirmado contra el bundle que sirve Pages.
- Gate de la entrega: `flutter analyze` limpio · **1323/1323** tests.
- Commits: `d033a30` (F1–F3, 20 archivos, +1037/−96) y `bdf27e9` (F5,
  2 archivos, +163/−11).
- App: https://miguelalbisortiz.github.io/cafecal/ · Supabase
  `ioyqlzhzlvkkebvenqnz` · cuenta `prueba@gmail.com`.

## 2. Qué se arregló

| # | Antes | Después |
|---|---|---|
| F1 | «Gastos por ha» filtraba por cultivo: café 33.872/ha | reparto del terreno: café 46.391 · plátano 29.454 · maíz 25.220 |
| F2 | Recogida por kg = COP 0 | jornales de Cosechar + lazo a cosecha: **COP 21,96/kg** (76.212,48 ÷ 3.470) |
| F3 | El lote cerrado perdía sus kilos en la tarjeta | muestra **3.000 kg** (maíz), sin kg/planta ni «0 matas» |
| F5 | Valores en `black87` y etiquetas en `grey.shade700`: ilegibles en oscuro | `scheme.onSurface` / `scheme.onSurfaceVariant` en todo el reporte |

Ninguna cifra del Reporte se movió: ingresos **4.835.000**, gastos
**417.147,84** (mano de obra 292.147,84 · fijos 125.000), balance
**4.417.852,16**, desglose café 278.344 (16 mov.) · plátano 88.363 (8) · maíz
50.441 (6). Márgenes por ha tras F1: 49.442 · 90.546 · 1.924.780.

**Tests nuevos:** `test/per_hectare_panel_reparto_test.dart` (3),
`test/report_pickup_parity_test.dart` (2),
`test/l10n_cifras_reporte_test.dart` (3),
`test/report_screen_contraste_test.dart` (3). Ampliados:
`crops_screen_cohort_kilos_test.dart`, `mixed_currency_gap_test.dart`,
`report_harvest_metrics_test.dart`.

## 3. Decisiones

- **D1 — un solo criterio de gasto/ha.** El panel usa el mismo reparto del
  terreno que el desglose (`cropExpenseShares`). El lote sin repartir se avisa
  (`lotNotSplit`) en vez de inventar una cifra.
- **D2 — la recogida suma la mano de obra de Cosechar** con los kilos medidos.
  La caja menor **no** es costo. Con moneda mixta, cada una sale con su código.
- **D3 — el lote cerrado muestra sus kilos**, sin kg/planta ni «0 matas».
- **F5 — alcance «todo el reporte»**, no solo las dos tarjetas vistas. Los tres
  colores fijos pasaron al tema; en claro la jerarquía no cambia.
- **F4 (11 ha de cultivos en terreno de 10) no es bug** y quedó fuera: prueba
  que la guarda de áreas avisa sin bloquear.
- Derivados confirmados por el usuario: **2 decimales** en recogida
  (`COP 21,96`) y la pantalla usa el **período**.

## 4. Pendientes

- Limpiar los datos de prueba cuando ya no sirvan
  (`limpia_cuenta_prueba.sql`).
- No re-abrir la atribución por venta ni el reparto de una venta entre lotes.
- No hay migraciones nuevas en esta entrega.

## 5. Cómo continuar

- Leer el informe §6 para la verificación en producción y el PRD para R1–R3.
- Si se toca el formato de una cifra: test en rojo → cambio → ARB en ES y EN →
  `gen-l10n` (commitear `lib/l10n/generated/`) → `flutter analyze` +
  `flutter test` → commit explícito.
- **`flutter build web` (y por tanto `deploy.ps1`) reescribe
  `lib/l10n/generated/` en CRLF**, igual que `gen-l10n`. Reconvertir a LF
  después de cada build o el diff salta a ~12.000 líneas.
- Para repetir la prueba desde cero: cerrar sesión, correr
  `limpia_cuenta_prueba.sql` y volver a cargar los scripts de datos.
