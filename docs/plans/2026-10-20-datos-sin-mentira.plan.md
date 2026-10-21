---
prd: docs/prds/2026-10-20_1426-datos-sin-mentira.prd.md
status: READY
created: 2026-10-20
updated: 2026-10-20
---

# Datos sin mentira — plan de implementación (tanda 4)

> De dónde sale: `docs/prds/2026-10-20_1426-datos-sin-mentira.prd.md`
> (**APPROVED** el 2026-10-20; D1–D11 cerradas) y
> `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md`.
> Este documento no implementa nada: es el plan para ejecutar la tanda.
> Estado **READY**: listo para arrancar, a la espera del visto bueno.

## 1. Objetivo

Que los números de la app dejen de mentir por cuatro causas concretas:

1. `racimo` y `cajon` cuentan como 1 kg.
2. El arrastre de la caja se recalcula con el aporte de hoy.
3. Las áreas de los cultivos no se comparan con el terreno.
4. El kg/planta y la resiembra no dicen qué incluyen.

Sin funciones nuevas: se corrige lo que ya se muestra y se explica mejor.

## 2. Alcance

### Entra

- Peso obligatorio en **cosecha** y **venta** cuando la unidad es racimo o
  cajón; todos los totales lo usan.
- Lista de registros **sin peso** para completarlos.
- **Historial** del aporte de caja por mes y arrastre con el monto que regía.
- Aviso de **áreas** que no cuadran (sin bloquear).
- Nota del **kg/planta** y aviso de **resiembra** sin muertas.
- **Reparto** de un gasto entre cultivos por porcentaje (atajo por área).
- Aclaración de la **planilla** (gasto por tarea, no presupuesto).
- Ayuda de **renovación** completa.
- Dos migraciones de Supabase, copy ES/EN y sus tests.

### No entra (del PRD)

- Cohortes dentro de un cultivo (`sowingId` en cosecha). Punto 6: más análisis.
- Asocio explícito entre cultivos.
- Presupuesto por tarea con arrastre propio.
- Editar/borrar en grupo un gasto repartido.
- Reconstruir presupuestos anteriores a la primera configuración.

### Reglas de ejecución

- Un test por arreglo; si no hay rojo posible, se declara **guarda**.
- Gate completo antes de commit y deploy: `flutter analyze` (proyecto entero,
  `tool/` incluido) + `flutter test`.
- Stageo explícito, nunca `git add -A`.
- Copy ES/EN; `gen-l10n` después de tocar ARB.
- LF antes de commitear (generated incluido).
- Las migraciones las aplica el usuario **antes** de desplegar.

## 3. Evidencia verificada antes de escribir el plan

- `lib/models/units.dart:12` — el `switch` no tiene `racimo` ni `cajon`:
  `_ => 1`.
- `lib/services/report_harvest_metrics.dart:33,67,111,171,188` — los cinco
  puntos que suman kilos usan `unitToKg`, nunca `equivalentKg`.
- `lib/screens/harvest_screen.dart:276` — el peso solo se pide para `racimo` y
  se guarda en `equivalentKg`; la lista lo muestra (`:114`), los totales lo
  ignoran.
- `lib/models/harvest.dart:16` — `equivalentKg` ya existe y ya se sincroniza
  (`sync_provider.dart:433`); `supabase/migrations/202609240001` agrega la
  columna a `harvests`.
- `lib/models/transaction.dart` — no tiene `equivalentKg`; la tabla
  `transactions` tampoco (`202609040001_mi_cafetal_init.sql`).
- `lib/services/report_payroll_metrics.dart` `cashCarryUpTo` — arranca en el
  primer mes con **cualquier** registro y usa `budget` (el de hoy) para todos
  los meses.
- `lib/models/settings.dart:45-60` — `cajaMenorMensual` +
  `presupuestoObraMensual` se fusionan en `cajaMensualEfectiva`; no hay
  historial.
- `public.settings` es una fila por usuario (`user_id` PK): un `jsonb` nuevo
  alcanza.
- `lib/widgets/per_hectare_panel.dart:204` — el kg/planta sale con
  `perHaYieldPlantLabel`, sin nota.
- `lib/screens/report_screen.dart:1269` — la planilla ya agrupa por tarea y
  cultivo (`workSheetRows`), con días y total.
- `lib/screens/sowing_screen.dart:340-410` — la resiembra permite nuevas sin
  muertas; no avisa.

## 4. Mapa de fases

| Fase | Tareas | Qué deja |
|---|---|---|
| 0 | T1 | Baseline del gate y de los números |
| 1 | T2–T7 | Unidades honestas (racimo/cajón) |
| 2 | T8–T9 | Historial del aporte y arrastre por mes |
| 3 | T10–T13 | Áreas, copy, resiembra y aclaraciones |
| 4 | T14 | Gate, deploy, verificación y cierre |

## 5. Fases y tareas

### Fase 1 — Unidades honestas

#### T1 — Baseline

- `flutter analyze` y `flutter test`; anotar el total (hoy 1049/1049).
- Guardar en el informe la lista de tests que tocan kilos, caja y settings:
  `report_harvest_metrics_test`, `export_parity_test`, `cash_box_*`,
  `settings_*`, `sync_*`.
- Sin cambios de código.

#### T2 — El helper de kilos (rojo primero)

**Archivo:** `lib/models/units.dart` (nuevo código), `test/units_test.dart`.

```dart
const Set<String> kUnitsNeedingWeight = {'racimo', 'cajon'};
bool unitNeedsWeight(String? unit) => kUnitsNeedingWeight.contains(unit);
double? kgFromUnit(double amount, String? unit, double? totalKg,
    {double sacoKg = kSacoKgPorDefecto});
```

- Si la unidad necesita peso: `totalKg` si es > 0, si no `null`.
- Si no: `amount * unitToKg(unit, sacoKg: sacoKg)` (como hoy).
- Tests (rojo): `kgFromUnit(12, 'racimo', 240) == 240`;
  `kgFromUnit(12, 'racimo', null) == null`;
  `kgFromUnit(10, 'cajon', 200) == 200`;
  `kgFromUnit(10, 'cajon', null) == null`;
  `kgFromUnit(3, 'saco', null, sacoKg: 70) == 210`;
  `kgFromUnit(1, 'kg', null) == 1`.
- `unitToKg` no se toca.

#### T3 — Todos los totales usan el helper

**Archivos:** `lib/services/report_harvest_metrics.dart`,
`lib/services/alert_service.dart`, `lib/services/low_price_check.dart`.

- Reemplazar las cinco sumas de `report_harvest_metrics` por `kgFromUnit`.
  Cuando devuelve `null`, el registro **no suma** (y se cuenta aparte, T6).
- `yieldPerArea` / `yieldPerPlant` / `historicalYield`: solo suman kg
  conocidos; si no queda ninguno, `null` (oculto).
- `alert_service`: `harvestedByCrop` y `salesByCrop` con el helper; el precio
  por kilo (línea 322) se calcula solo si los kg son conocidos.
- `low_price_check`: ídem.
- Test rojo real: 12 racimos con 240 kg → `totalsByCrop().kg == 240`
  (hoy da 12).
- Guarda: `test/unit_weight_guard_test.dart` — ningún archivo de `lib/` fuera
  de `units.dart` llama `unitToKg` directamente (fuerza a pasar por el helper).

#### T4 — Cosecha: el peso es obligatorio

**Archivo:** `lib/screens/harvest_screen.dart`.

- Mostrar el campo «Peso total (kg)» cuando `_unit == 'racimo' || 'cajon'`.
- Validador: requerido y > 0 en esas unidades; se guarda en `equivalentKg`.
- Al editar, se precarga (ya se hace para racimo).
- Test: validador puro (`validateEquivalentKg`) + widget de la hoja si el
  harness lo permite.
- Guarda de copy: el texto dice «peso total», no «por racimo».

#### T5 — Ventas: peso, modelo y cosecha derivada

**Archivos:** `lib/models/transaction.dart`,
`lib/providers/transaction_provider.dart`, `lib/providers/sync_provider.dart`,
`lib/screens/register_screen.dart`, `lib/services/derived_harvests.dart`,
`supabase/migrations/202610200001_add_transaction_equivalent_kg.sql`.

- `Transaction.equivalentKg` (nullable) + `copyWith` con centinela + JSON
  `equivalent_kg` + payload de sync.
- Migración:
  `alter table public.transactions add column if not exists equivalent_kg numeric;`
- Formulario de venta: si la unidad es racimo o cajón, pedir «Peso total (kg)»
  (obligatorio, > 0) y guardarlo. El precio por unidad no cambia.
- `deriveHarvests`: la cosecha derivada hereda `equivalentKg` de la venta.
- Tests:
  - JSON roundtrip con y sin `equivalent_kg`.
  - 10 cajones / 200 kg → cosecha derivada de 200 kg.
  - Precio por kilo = importe / 200.
  - Venta sin peso → no suma kg y entra a «sin peso».
- Riesgo: sin migración aplicada, el push falla. Va antes del deploy.

#### T6 — «Sin peso»: contador y lista

**Archivos:** `lib/services/report_harvest_metrics.dart` (helpers puros),
`lib/screens/report_screen.dart`, `lib/screens/harvest_screen.dart`
(extraer el editor), tests.

- Helpers: `pendingWeightHarvests(...)` y `pendingWeightSales(...)`.
- Tarjeta en Reportes: «N cosechas y M ventas sin peso no entran en los kilos»,
  con la lista (fecha, cultivo, cantidad + unidad).
- Tocar una cosecha abre el editor existente (extraer `showHarvestForm` del
  `_HarvestForm` privado); tocar una venta abre
  `RegisterScreen(editing: t)`.
- Al completar el peso, la tarjeta baja el contador (mismo provider).
- Tests: los helpers; con todos completos el contador da 0.

#### T7 — Paridad de exportación con racimo y cajón

**Archivo:** `test/export_parity_test.dart`.

- Extender el fixture: una cosecha de 12 racimos / 240 kg y una venta de
  10 cajones / 200 kg.
- Congelar: kg totales 240, vendidos 200, precio por kilo correcto, PDF con
  2 páginas y los mismos totales que la pantalla.
- Es la guarda de que PDF/Excel no se quedaron atrás.

### Fase 2 — Caja honesta

#### T8 — Historial del aporte

**Archivos:** `lib/models/settings.dart`, `lib/services/settings_store.dart`,
`lib/providers/sync_provider.dart`, `lib/screens/settings_screen.dart`,
`supabase/migrations/202610200002_add_settings_cash_budget_history.sql`.

- `FarmSettings.cashBudgetHistory: Map<String, double>` (clave `YYYY-MM`) +
  JSON + `copyWith`.
- Migración:
  `alter table public.settings add column if not exists cash_budget_history jsonb not null default '{}'::jsonb;`
  (RLS ya cubre la fila).
- Al guardar Ajustes: si el aporte efectivo cambió, escribir
  `history[mes actual] = aporte` (solo ese mes).
- Al cargar por primera vez sin historial y con aporte > 0: sembrar
  `history[mes actual] = aporte` (una vez; se persiste).
- `budgetForMonth(history, year, month)`: el último monto con clave ≤ mes;
  `null` si no hay ninguno.
- Tests: resolución por mes; cambiar el aporte no toca claves anteriores;
  historial vacío → sin presupuesto.

#### T9 — Arrastre y tabla por mes

**Archivos:** `lib/services/report_payroll_metrics.dart`,
`lib/widgets/cash_box_card.dart`, `lib/screens/report_screen.dart`.

- `cashCarryUpTo`: recorrer desde el primer mes **con entrada** hasta el mes
  anterior; cada mes usa `budgetForMonth`; si un mes no tiene (antes de la
  primera configuración), no suma ni resta.
- `cashBoxByMonth`: presupuesto por mes con el mismo resolvedor; los meses
  anteriores a la primera entrada **no se listan** (no había caja).
- La tarjeta de Inicio usa el aporte del mes en curso + arrastre calculado.
- Copy en Ajustes: «El aporte rige desde este mes; los meses anteriores no se
  recalculan» (ES/EN).
- Tests:
  - 1.000.000 en enero, 1.200.000 en marzo: febrero usa 1.000.000 y el
    arrastre de abril refleja cada mes.
  - Cambiar el aporte en el mes actual no reescribe el pasado.
  - Meses previos a la primera entrada no cuentan.
  - Deuda (arrastre negativo) sigue funcionando.
  - Moneda mezclada sigue devolviendo `null`.

### Fase 3 — Claridad

#### T10 — Áreas que no cuadran

**Archivos:** `lib/models/terreno.dart` (o
`lib/services/terreno_areas.dart`), `lib/screens/crops_screen.dart`,
`lib/widgets/crop_editor_dialog.dart`, tests.

- Función pura `terrenoAreaStatus(terreno, crops)` →
  `({double assigned, bool over, int withoutArea})`.
- Tarjeta del terreno: «5,0 de 8,0 ha asignadas»; si se pasa:
  «Las áreas suman 12,0 ha y el terreno tiene 8,0» en ámbar, sin bloquear.
- Editor de cultivo: si el cultivo tiene terreno y área, mostrar el total
  asignado del terreno como ayuda.
- Tests: suma, exceso, cultivo sin área, terreno sin área (no compara).

#### T11 — Nota del kg/planta

**Archivos:** `lib/widgets/per_hectare_panel.dart`, ARB ES/EN, `gen-l10n`.

- Nota al pie del panel cuando hay algún kg/planta:
  «kg/planta es el promedio del cultivo; incluye plantas que aún no producen».
- Sin cambio de cálculo.
- Test: la clave existe en los dos ARB y el panel la pinta con datos mínimos.

#### T12 — Aviso de resiembra

**Archivos:** `lib/screens/sowing_screen.dart`, ARB ES/EN, tests.

- Función pura `resiembraMissingLosses(kind, plants, lostPlants)` → true solo
  si `kind == resiembra && plants > 0 && lostPlants == null`.
- Al guardar: diálogo «Anotaste plantas nuevas sin muertas» con
  **Anotar muertas** (enfoca el campo) y **Guardar así**.
- Con `lostPlants == 0` explícito no avisa.
- Tests: la función (4 casos) + widget del diálogo si se puede.

#### T13 — Planilla y renovación

**Archivos:** `lib/screens/report_screen.dart`, `lib/screens/help_screen.dart`,
ARB ES/EN, `gen-l10n`.

- Planilla: línea «Esto es lo gastado por tarea; el presupuesto de caja es uno
  solo».
- Ayuda: párrafo de renovación completa (se anota como siembra nueva; reinicia
  edad, plantas y área; las cosechas viejas quedan en el historial) y el camino
  de «cultivo aparte» para lotes que conviven.
- Tests: claves en ambos ARB (guarda).

### Fase 4 — Cierre

#### T15 — Reparto del gasto entre cultivos

Se agregó al detectar que el PRD (SC-8) y la lista «Entra» lo pedían, pero el
plan no le había asignado tarea.

**Archivos:** `lib/services/expense_split.dart`,
`lib/widgets/expense_split_dialog.dart`, `lib/screens/register_screen.dart`,
ARB ES/EN, `gen-l10n`.

- Reparto por porcentaje con atajo «usar áreas» (`areaHa`): solo entran los
  cultivos con área y hacen falta al menos dos medidos.
- Se guardan **N gastos independientes** con el mismo día, categoría y
  descripción; el último absorbe el remanente del redondeo. No hay gasto padre.
- Solo en gastos normales: no jornal (duplicaría trabajador y labor), no venta,
  no edición y sin cosecha vinculada.
- Validación: al menos dos cultivos, cada uno con porcentaje > 0, y suma 100 %.
- Tests: `test/expense_split_test.dart` (suma exacta, redondeo, atajo por áreas)
  y 3 widget en `test/register_screen_test.dart` (50/30/20 de 100.000, suma
  inválida, cultivo en 0).

#### T14 — Gate, deploy y verificación

- `flutter analyze` + `flutter test`.
- Informe `docs/reports/2026-10-20_datos-sin-mentira.md` con el antes/después
  de los números (12 racimos, 10 cajones, arrastre).
- El usuario aplica las **dos migraciones** en Supabase.
- Commit explícito (LF normalizado), push y `.\deploy.ps1 -Message "…"`.
- Verificación manual (abajo) y cierre documental (sesión + LEARNING).

## 6. Tests existentes que pueden romperse

- `test/export_parity_test.dart`: cambia el fixture; se actualiza en T7.
- `test/report_harvest_metrics_test.dart`: los kg de racimo/cajón cambian a
  propósito; se ajustan con el peso.
- `test/settings_*` / `test/sync_*`: el JSON de settings y transactions suma
  claves; los roundtrips deben seguir pasando.
- `test/cash_box_*`: el arrastre arranca en la primera entrada, no en el primer
  registro; se ajustan los casos.
- Widget tests de `per_hectare_panel` / `sowing_screen` / `register_screen`:
  copy y campo nuevo.

## 7. Verificación manual del usuario (después del deploy)

1. Cosecha de 12 racimos con 240 kg → los totales dicen 240 kg.
2. Venta de 10 cajones con 200 kg → precio por kilo sobre 200.
3. Un registro viejo sin peso → aparece en «sin peso»; al completarlo, baja el
   contador y suben los kilos.
4. Cambiar el aporte de caja → los meses anteriores no cambian.
5. Terreno de 8 ha con cultivos que suman 12 → aviso, sin bloqueo.
6. Resiembra con nuevas y sin muertas → aviso con «Guardar así».
7. Gasto repartido 50/30/20 → tres gastos que suman el total.
8. PDF y Excel con el racimo y el cajón → mismos kilos que la pantalla.

## 8. Gate, stageo y despliegue

### Gate (por fase y al cierre)

```
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```

### Stageo explícito (nunca `-A`)

Los archivos de cada tarea, uno por uno; `git status` antes de commitear;
`git show --stat` para confirmar que no entraron miles de líneas por CRLF.

### Deploy

1. El usuario aplica `202610200001` y `202610200002` en Supabase.
2. `.\deploy.ps1 -Message "…"`.
3. Verificar que Pages sirvió el build nuevo y que la app abre.

## 9. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Push falla por columna faltante | Migraciones antes del deploy |
| Cosecha derivada sin peso | Test explícito en T5 |
| Gasto repartido duplicado | El formulario crea solo los hijos; test de suma |
| Redondeo de porcentajes | El último hijo absorbe el remanente; test |
| Histórico cambia | Aviso en «sin peso» + informe |
| CRLF en generated | Normalizar y `git show --stat` |
| Cliente viejo sin peso | `null` tolerado; queda «sin peso» |
