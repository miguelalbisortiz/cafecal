# Tanda 2 · kilos recolectados en el jornal «Cosechar» — rojo y verdes

> Plan: `docs/plans/2026-10-19-kilos-recolectados-jornal.plan.md`
> PRD: `docs/prds/2026-10-19_0941-kilos-recolectados-jornal.prd.md`

## T1 · Línea base (2026-10-19)

- HEAD: `5b06ed2`.
- `flutter analyze` (proyecto entero): **exit 0**, sin issues.
- `flutter test`: **975 pruebas viejas en verde**. La corrida incluyó el primer
  test nuevo de T2, que falló a propósito (rojo buscado); no hubo ninguna otra falla.
- Árbol de trabajo: limpio salvo el PRD y el plan (sin commitear).

## T2 · `Transaction.harvestedKg`

### Rojo 1 — serialización (antes del campo)

Test: `test/transaction_test.dart` · `Kilos recolectados del jornal (Tanda 2)` ·
`un JSON con harvested_kg sobrevive al round-trip`.

```
Expected: <120.5>
  Actual: <null>
```

`fromJson` ignora la clave y `toJson` no la escribe: el dato se pierde al leer.

### Verde 1

`flutter test test/transaction_test.dart` → **5/5**. La clave `harvested_kg` viaja
siempre y una clave ausente carga `null`.

### Rojo 2 — `copyWith` no puede limpiar

Tests: `copyWith permite limpiar los kilos con null`,
`copyWith sin argumento conserva los kilos`, más los de pago y planilla.

```
test/transaction_test.dart:141:25: Error: No named parameter with the name 'harvestedKg'.
test/jornal_test.dart:240:21: Error: No named parameter with the name 'harvestedKg'.
```

Sin la sentinela de `copyWith`, «dejar de ser Cosechar» no podría borrar el dato.

### Verde 2

`flutter test test/transaction_test.dart test/jornal_test.dart test/work_sheet_test.dart`
→ **39/39**. El pago sigue `días × valor día`; nómina y planilla suman igual con o
sin kilos; `quantity`, `unit` y `price_per_unit` sobreviven al round-trip.

## T3 · La tecla `kTaskCosechar`

### Rojo

```
test/tasks_test.dart:10:14: Error: Undefined name 'kTaskCosechar'.
test/tasks_test.dart:11:46: Error: Undefined name 'kTaskCosechar'.
```

### Verde

`flutter test test/tasks_test.dart test/work_sheet_test.dart` → **21/21**. La tecla
sigue valiendo `'cosechar'`, una sola vez en el catálogo y con el mismo nombre.

## T4 · La función pura `manual > jornal > venta`

### Rojo 1 — la función ignora los jornales

Test: `Jornal · lo que sí` · `un jornal de Cosechar con kilos da exactamente una cosecha`.

```
Expected: an object with length of <1>
  Actual: []
```

### Rojo 2 — faltan los símbolos de la fuente

```
test/derived_harvests_test.dart:364:30: Error: Undefined name 'kJornalDerivedPrefix'.
test/derived_harvests_test.dart:365:14: Error: Method not found: 'isJornalDerivedHarvest'.
```

### Verde

`flutter test test/derived_harvests_test.dart` → **45/45**. Cubre: una cosecha por
jornal, `unit = kg`, destino vendido, `pendingSync false`; sin kilos / 0 / negativo,
labor distinta, sin cultivo, borrado y «Otra…» no derivan; y la prioridad
`manual > jornal > venta` por cultivo, incluido el trade-off de no rellenar los
jornales sin kilos.

## T5 · El provider

### Rojo

```
test/derived_harvests_provider_test.dart:241:11: Error: No named parameter with the name 'harvestedKg'.
```

### Verde

`flutter test test/derived_harvests_provider_test.dart` → **19/19**. `harvests` deriva
la del jornal; `storedHarvests` sigue vacío; borrar, editar kilos, cambiar la labor
o borrar el cultivo se reflejan en la siguiente lectura.

## Gate de la fase 1

- `flutter analyze` (proyecto entero): **No issues found** (15,2 s).
- `flutter test`: **1013/1013** en verde (base 975 + 38 nuevas).
- Archivos tocados: solo los previstos en la fase 1 (`lib/models/tasks.dart`,
  `lib/models/transaction.dart`, `lib/providers/transaction_provider.dart`,
  `lib/services/derived_harvests.dart` y sus tests). Cero cambios en UI, sync,
  respaldo, reportes o W1-c.

## T6 · Copy ES/EN

### Rojo

```
Expected: 'Kilos recolectados (opcional)'
  Actual: <null>
Expected: 'Harvested kilos (optional)'
  Actual: <null>
```

Las cuatro claves no existían en ninguno de los dos ARB.

### Verde

`flutter gen-l10n` + `flutter test test/l10n_jornal_kg_test.dart` → **3/3**.
Las cuatro frases están en ES y EN, sin «bodega» ni `$`.

## T7 · El campo en Registrar

### Rojo

```
Found 0 widgets with text "Kilos recolectados (opcional)": []
Found 0 widgets with text "Elegí el cultivo para anotar los kilos.": []
Found 0 widgets with text "123.5": []
```

### Verde

`flutter test test/register_screen_test.dart --plain-name "Kilos recolectados en el jornal"`
→ **9/9**: aparece con Cosechar + cultivo; no con otra labor, sin cultivo ni con
lote (y ahí explica por qué); restaura lo guardado; guarda 120; vacío guarda
`null`; 0 no pasa; y al cambiar de labor se limpia y no reaparece.

## Gate de la fase 2

- `flutter analyze` (proyecto entero): **No issues found** (52,5 s).
- `flutter test`: **1025/1025** en verde (1013 de la fase 1 + 12 nuevas).
- Archivos tocados: los dos ARB, los tres generados de `lib/l10n/generated/`,
  `register_screen.dart` y `register_screen_test.dart`, más el test nuevo de copy.
- Sigue **sin commit**.

## T8 · Payload y lectura remota

### Rojo 1 — el payload no lleva la clave

```
Expected: true
  Actual: <false>
Expected: <120.5>
  Actual: <null>
```

### Rojo 2 — la lectura no existe como pública

```
test/sync_push_test.dart:742:19: Error: The method 'remoteToTransaction' isn't defined for the class 'SyncProvider'.
```

### Verde

`flutter test test/sync_push_test.dart` → **47/47**. `harvested_kg` sale siempre
(incluido `null`, nunca 0), viaja decimal, y la fila que baja de Supabase lo
conserva; una fila vieja carga `null`.

## T9 · Migración `harvested_kg`

### Rojo

```
Expected: true
  Actual: <false>
PathNotFoundException: Cannot open file 'supabase/migrations/202610190001_add_transaction_harvested_kg.sql'
```

### Verde

`flutter test test/migration_harvested_kg_test.dart` → **3/3**. Contrato estático:
existe, es `add column if not exists`, sin backfill ni `not null`. **No sustituye
aplicarla en Supabase.**

## T10 · Respaldo y datos viejos

- **Guarda, sin rojo artificial** (así lo declara el plan): el mapeo del respaldo
  ya pasa por `toJson`/`fromJson`, y el rojo de la clave ausente se vio en T2.
- `flutter test test/backup_import_test.dart test/backup_service_test.dart`
  → **30/30**. Un respaldo sin kilos importa igual y no deriva; conserva 120.5;
  el archivo de un jornal medido no contiene `der_jornal_`; y la clave ausente
  decodifica sin error.

## Gate de la fase 3

- `flutter analyze` (proyecto entero): **No issues found** (86,2 s).
- `flutter test`: **1039/1039** en verde.
- Archivos tocados: `sync_provider.dart`, la migración nueva y cuatro archivos de
  tests (sync, migración, respaldo ×2).
- **La migración no se aplicó** en Supabase: eso se hace antes del deploy, con tu OK.
- Sigue **sin commit**.

## T11 · Guardas de los tres pintadores y de las métricas

- **Guardas, sin rojo artificial** (D8): pantalla, PDF y Excel ya leen
  `provider.harvests`; no se tocó `lib/`.
- `flutter test test/derived_harvests_report_test.dart test/report_harvest_metrics_test.dart`
  → **44/44**.
- Comprobado con una venta de 480 kg y un jornal que midió 500:
  - la tarjeta «Vendido vs cosechado» se enciende sola;
  - el Excel pinta 480 vendidos y 500 cosechados;
  - el PDF se construye y sigue siendo `%PDF-`;
  - pantalla y Excel salen del mismo `p.harvests`;
  - `yieldPerArea` = 500 kg/ha; `totalCostPerKg` = 200 (100.000 ÷ 500) y baja
    frente a dividir por 480; `pickupCostPerKg` no suma el jornal.
- La regresión D5 («oculta cuando la única fuente es la venta») sigue verde.

## Gate de la fase 4 (T11)

- `flutter analyze`: **No issues found** (6,9 s).
- `flutter test`: **1046/1046** en verde.
- Sigue **sin commit** y **sin deploy**.

