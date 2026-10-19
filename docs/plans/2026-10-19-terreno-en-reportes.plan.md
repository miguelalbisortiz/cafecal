---
status: DONE
created: 2026-10-19
updated: 2026-10-19
prd: docs/prds/2026-10-19_0846-terreno-en-reportes.prd.md
---

# W1-c · El terreno en Reportes, PDF y Excel — plan de la tanda

> De dónde sale: `docs/prds/2026-10-19_0846-terreno-en-reportes.prd.md` (APPROVED), con
> las decisiones D1–D9 cerradas por el usuario el 2026-10-19. El plan v2 lo daba por
> descartado; el descarte perdió su motivo cuando W1-b entró (`93f37c4`).

## Qué se va a hacer

Que el desglose del período se lea como el agricultor piensa la finca: **cada terreno
primero y sus cultivos debajo**, con el total del lote y la fila «sin repartir» dentro.
Una sola función pura arma las bandas; pantalla, PDF y Excel solo formatean. Finca sin
terrenos → cero cambios (mismo camino plano de hoy).

## Reglas de la tanda

- Solo se tocan `lib/services/crop_totals.dart`, `lib/screens/report_screen.dart`,
  `lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart`,
  `lib/utils/format.dart`, `lib/screens/crops_screen.dart` (solo para compartir el
  formato de hectáreas) y `test/`. Cero cambios en modelos, sync, respaldo, supabase.
- `null` → oculto, nunca `0`. Nunca se suman monedas que se pinten; la suma cruzada
  solo ordena.
- Una sola función para una sola regla: pantalla, PDF y Excel leen la misma agrupación.
- Copy: solo se reutiliza `cropTerrenoNone` («Sin terreno» / «No plot»). Nada nuevo.
- Cada pieza con su test, **visto en rojo antes de su arreglo**.
- Gate: `flutter analyze` del proyecto entero + `flutter test`.

## Tandas

### T1 · El formato de hectáreas, compartido (A7)

- `formatAreaHa(value, locale)` en `lib/utils/format.dart` con `NumberFormat('0.###')`.
- `crops_screen.dart` deja de tener su `_ha` privado y usa el compartido (mismo
  resultado: `0,4 ha`, `2 ha`).
- **Prueba:** unitaria de ES/EN (`0,4` / `0.4`, entero sin decimales).

### T2 · La función pura de bandas (A1–A4, A8–A11 · D1, D3, D4, D6, D9)

- `CropBreakdownBand` (terreno, filas, área, totales por moneda) y
  `CropBreakdownLayout` (`hasBands`, bandas, «Costos comunes» aparte).
- `cropBreakdownLayout(rows, crops, terrenos, sinTerrenoName)`: pertenencia, visibilidad
  (`hasAnyAmount`), orden por monto con desempate por nombre e id, «Sin terreno» al
  final solo si hay bandas y huérfanos, comunes fuera.
- **Prueba G1** (`test/terreno_bandas_test.dart`): orden, totales exactos, lote dentro,
  huérfanos, sin bandas cuando ningún cultivo tiene terreno, área nula, banda vacía,
  terreno inexistente, moneda mixta, desempate.

### T3 · Reportes en pantalla (A5, A6, A10 · SC10, SC11)

- La tarjeta del desglose pinta una banda (nombre + área + gastos/ventas) y debajo sus
  cultivos; «Sin terreno» y «Costos comunes» al final.
- **Prueba G2** (grupo en `test/report_screen_test.dart`): cabeceras visibles en orden,
  «sin repartir» dentro de su banda, y finca sin terrenos sin bandas.

### T4 · PDF (SC11)

- `_cropRows` devuelve también filas de banda (nombre + área, gastos/ventas, sin
  resultado ni ROI) y la tabla las pinta en negrita con fondo suave.
- **Prueba G4:** contrato de fuente (el PDF usa la agrupación) + humo del PDF con bandas.

### T5 · Excel (SC12)

- La hoja «Por cultivo» intercala una fila de cabecera por banda (negrita, fondo gris) y
  sus cultivos debajo, mismo orden y totales.
- **Prueba G3** (`test/excel_export_service_test.dart`): cabecera por banda y orden.

### T6 · Regresión plana y gate (A3 · SC4, SC13, SC14)

- Caso explícito por pintador con finca sin terrenos: ni bandas ni «Sin terreno».
- `git diff --stat` acotado a los archivos permitidos.
- `flutter analyze` + `flutter test` completos; el conteo queda en el reporte.

## Verificación

1. Rojo de G1–G4 antes de cada arreglo, pegado en `docs/reports/2026-10-19_w1c-rojo.md`.
2. Verde y gate completo.
3. Comparación de los tres con una finca de prueba (2 terrenos, huérfano, lote sin
   repartir, común, cultivo con dos monedas).
4. Regresión plana con la misma finca sin terrenos.

## Resultado

- **T1–T6 hechas.** `formatAreaHa` compartido; `cropBreakdownLayout` en `crop_totals.dart`
  con `CropBreakdownBand`/`CropBreakdownLayout`; pantalla con banda + área + gastos/ventas;
  PDF y Excel con la misma cabecera en negrita y el mismo orden.
- **Rojo visto** en G1 (compilación), A7 (compilación), G2 (`Found 0 widgets "Lote Alto"`),
  G3 (cabecera `-1`) y G4 (el PDF no llamaba a la función). Todo en el reporte.
- **Gate:** `flutter analyze` sin issues · **975/975** tests (954 previos + 21 nuevos).
- **Diff acotado:** `crop_totals.dart`, `report_screen.dart`, `pdf_export_service.dart`,
  `excel_export_service.dart`, `utils/format.dart`, `crops_screen.dart` (solo el formato
  de hectáreas) y tests. Cero cambios en modelos, sync, respaldo o supabase.
- **Pendiente del usuario:** abrir un PDF y un Excel reales de una finca con lotes y
  mirar la banda; y la verificación manual del ciclo que ya estaba pendiente.

