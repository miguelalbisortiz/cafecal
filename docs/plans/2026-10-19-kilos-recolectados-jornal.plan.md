---
prd: docs/prds/2026-10-19_0941-kilos-recolectados-jornal.prd.md
status: READY
created: 2026-10-19_0941
updated: 2026-10-19
---

# Kilos recolectados en el jornal de «Cosechar» — Tanda 2 · plan de implementación

> De dónde sale: `docs/prds/2026-10-19_0941-kilos-recolectados-jornal.prd.md`
> (**APPROVED**, D1–D15 y Q1–Q7 cerradas por el usuario el 2026-10-19).
> Este documento **no implementa nada**: es el plan para ejecutar la tanda.
> Estado **READY**: listo para arrancar, todavía sin cambios de código.

## 1. Objetivo

Que un jornal cuya labor es **«Cosechar»** pueda anotar **opcionalmente** los kilos
recolectados, y que la cosecha derivada use esa medida **independiente de la venta**.
Con eso se encienden la comparación «vendido vs cosechado» y la señal de pérdida en
campo, **sin** un paso nuevo, **sin** tocar el pago del jornal (`días × valor día`) y
**sin** reabrir la pantalla de Cosechas.

La regla completa vive en una sola función pura:

```
manual  >  jornal  >  venta        (por cultivo, nunca sumando fuentes)
```

## 2. Alcance

### Entra

- Campo nullable `harvestedKg` en `Transaction`, serializado como `harvested_kg`.
- Segunda fuente en `deriveHarvests` con prefijo propio `der_jornal_`.
- Prioridad `manual > jornal > venta` **por cultivo**.
- Campo de kilos en `RegisterScreen`, visible solo con:
  categoría `mano_obra` + labor `cosechar` (tecla del catálogo) + cultivo + sin lote.
- Copy ES/EN de D13 y `flutter gen-l10n`.
- Payload y lectura remota en `SyncProvider`.
- Migración Supabase idempotente `transactions.harvested_kg`, aplicada **antes** del deploy.
- Tests de modelo, función pura, provider, UI, sync, respaldo y reportes.

### No entra (del PRD)

- `HarvestScreen`, ítem de menú «Cosechas», `HarvestDestination.almacenado`.
- Pago por kilo/destajo, planilla con columna de kg, tarjeta nueva de «pérdida en campo».
- W1-c, moneda, caja, por cobrar, arquitectura de sync.
- Backfill de jornales viejos, unidades distintas de kg.
- Categoría `cosecha` (el campo vive solo en `mano_obra`).
- Copy con bodega/almacenamiento.

### Reglas de ejecución

1. **TDD real.** Toda tarea que toque `lib/` o `supabase/` escribe primero su test y
   registra el rojo **antes** del arreglo, con el comando y la línea de fallo.
   El rojo se guarda en `docs/reports/2026-10-19_kilos-jornal-rojo.md`.
2. **No se fabrica un rojo.** Las tareas que solo agregan guardas sobre código ya
   existente (respaldo y pintadores) se declaran **guarda**: se ejecutan antes y después,
   y su valor es impedir la regresión. No se inventa un fallo artificial.
3. **Gate por fase y al cierre:** `flutter analyze` del proyecto entero (incluye `tool/`)
   y `flutter test`. Nada se declara terminado con un test rojo o un warning nuevo.
4. **Stageo explícito.** Nunca `git add -A` ni `git add .`. Se enumeran los archivos.
   Ningún `commit` ni `push` sin el verbo del usuario en ese turno.
5. **Una sola regla, un solo lugar.** La prioridad no se reparte entre pantalla y provider.
6. **`null` = oculto, nunca `0`.** Sin kilos no hay cosecha; sin cultivo no hay campo.
7. **Los kilos no son moneda.** No se suman con dinero ni llevan símbolo de moneda.

## 3. Mapa de fases

| Fase | Tareas | Resultado verificable | Depende de |
|---|---|---|---|
| 0 · Línea base | T1 | Gate actual registrado (975/975, analyze limpio) | — |
| 1 · Núcleo sin UI | T2–T5 | Modelo + función pura + provider en verde | T1 |
| 2 · Copy y pantalla | T6–T7 | El agricultor anota kilos y se guardan/limpian bien | T1–T5 |
| 3 · Sync y migración | T8–T10 | El dato viaja y vuelve; respaldo viejo no rompe | T2, T5 |
| 4 · Reportes y cierre | T11–T12 | Tarjeta en pantalla/PDF/Excel + verificación manual + deploy | T1–T10 |

Orden deliberado: **modelo/serialización y función pura antes de la UI**; la migración
se escribe en la fase 3 y se **aplica antes** de desplegar la app que la envía.

## 4. Fases y tareas

---

### Fase 0 — Línea base

#### T1 · Registrar el punto de partida

- **Archivos:** `docs/reports/2026-10-19_kilos-jornal-rojo.md` (nuevo).
- **Cambio:** ninguno en `lib/`. Anotar `git rev-parse --short HEAD`, la salida de
  `flutter analyze` y el conteo de `flutter test` (hoy: 975 en verde).
- **Tests:** no aplica; el gate actual es la prueba.
- **Rojo esperado:** no aplica.
- **Hecho:** baseline registrado y árbol limpio salvo el PRD/plan. Si el baseline no
  está verde, **se detiene la tanda** y se reporta.
- **Depende:** — · **Riesgo:** bajo.

---

### Fase 1 — Núcleo sin UI

#### T2 · `Transaction.harvestedKg` y `harvested_kg`

- **Archivos:**
  - `lib/models/transaction.dart`
  - `test/transaction_test.dart`
  - `test/jornal_test.dart` (payroll)
  - `test/work_sheet_test.dart` (workSheetRows)
- **Cambio:**
  - Campo `final double? harvestedKg;` en la sección del jornal, documentado como
    **medida de cosecha**, no forma de pago.
  - Constructor `this.harvestedKg`.
  - `copyWith({Object? harvestedKg = _keep})` con la **misma sentinela** que `task` y
    los ids, para poder limpiarlo con `null`; castear `(harvestedKg as num?)?.toDouble()`
    para aceptar literales enteros.
  - `toJson`: `'harvested_kg': harvestedKg` **siempre**, incluso `null` (igual que
    `task`; así el payload distingue “no medido” de “0”).
  - `fromJson`: `(json['harvested_kg'] as num?)?.toDouble()`; clave ausente → `null`.
  - No tocar `amount`, `quantity`, `unit`, `pricePerUnit`.
- **Tests** — `test/transaction_test.dart`, grupo
  `'Kilos recolectados del jornal (Tanda 2)'`:
  - `un JSON con harvested_kg sobrevive al round-trip` (entra por `fromJson` y sale
    por `toJson`; es el primer test, no referencia el getter)
  - `toJson deja la clave en null, nunca en 0`
  - `fromJson sin la clave carga null (respaldo viejo)`
  - `round-trip con kilos conserva 120.5`
  - `round-trip sin kilos conserva null`
  - `copyWith permite limpiar los kilos con null`
  - `copyWith sin argumento conserva los kilos`

  `test/jornal_test.dart`, grupo `'Kilos no tocan el pago'`:
  - `amount sigue siendo días × valor día`
  - `payroll suma los mismos días y montos con o sin kilos`

  `test/work_sheet_test.dart`, grupo `'Kilos no tocan la planilla'`:
  - `workSheetRows suma los mismos días y montos con o sin kilos`
  - `la serialización conserva quantity, unit y price_per_unit intactos`
- **Rojo esperado:**
  1. Primero se escribe solo `un JSON con harvested_kg sobrevive al round-trip`, que
     construye desde un mapa (`Transaction.fromJson`) y comprueba
     `toJson()['harvested_kg']`: falla por aserción
     `Expected: <120.5> Actual: <null>` porque hoy `fromJson` ignora la clave.
  2. Se agrega el campo, el constructor, `toJson` y `fromJson`; ese test queda verde.
  3. Se escriben `copyWith` y los tests de pago/planilla: rojo de compilación
     `The getter 'harvestedKg' isn't defined for the class 'Transaction'`.
  4. Se implementa `copyWith` con sentinela y se corre el gate del subconjunto; verde.
- **Hecho:** `flutter test test/transaction_test.dart test/jornal_test.dart
  test/work_sheet_test.dart` en verde; el JSON de un jornal sin kilos contiene
  `"harvested_kg": null`.
- **Depende:** T1 · **Riesgo:** medio (la sentinela de `copyWith` es fácil de olvidar).

#### T3 · La tecla `kTaskCosechar`

- **Archivos:** `lib/models/tasks.dart`, `test/tasks_test.dart` (nuevo).
- **Cambio:** `const String kTaskCosechar = 'cosechar';`; el catálogo usa la constante
  en la entrada `FarmTask(key: kTaskCosechar, …)` (mismo valor y mismo orden).
- **Tests** — `test/tasks_test.dart`, grupo `'La tecla de «Cosechar»'`:
  - `kTaskCosechar vale 'cosechar' y aparece una sola vez en el catálogo`
  - `taskByKey(kTaskCosechar) devuelve la labor «Cosechar»`
- **Rojo esperado:** compilación `Undefined name 'kTaskCosechar'`.
- **Hecho:** test en verde y `test/work_sheet_test.dart` sigue en verde (la tecla no cambió).
- **Depende:** T1 · **Riesgo:** bajo.

#### T4 · La función pura: `manual > jornal > venta`

- **Archivos:** `lib/services/derived_harvests.dart`,
  `test/derived_harvests_test.dart`.
- **Cambio:**
  - `const String kJornalDerivedPrefix = 'der_jornal_';`
  - `bool isJornalDerivedHarvest(Harvest h) => h.id.startsWith(kJornalDerivedPrefix);`
  - `isSaleDerivedHarvest` **no cambia** (sigue devolviendo `false` para el jornal).
  - `hasIndependentHarvest` **no cambia** (el jornal ya lo enciende solo).
  - Actualizar el bloque de diseño D4: la Tanda 2 ya no es “todavía no existe”.
  - `deriveHarvests`:
    1. `manualCrops` como hoy.
    2. `jornalCrops`: cultivos con al menos un gasto **no borrado**,
       `category == 'mano_obra'`, `task == kTaskCosechar`, `cropId != null`,
       `harvestedKg != null && harvestedKg > 0`, y sin cosecha manual.
    3. Emitir una `Harvest` por cada jornal medido:
       `id = 'der_jornal_<transactionId>'`, `cropId = t.cropId`, `date = t.date`,
       `amount = t.harvestedKg`, `unit = 'kg'`,
       `destination = HarvestDestination.vendido`, `pendingSync = false`.
    4. El bucle de ventas de hoy agrega una condición:
       `if (jornalCrops.contains(cropId)) continue;` (la venta no deriva para ese cultivo).
    5. Orden determinista: primero las del jornal, después las de la venta, cada grupo
       en el orden de `transactions`.
  - No se exige `terrenoId == null` en la función: la UI garantiza que no se guarde
    cultivo + lote; si un dato legado trae ambos, manda `cropId` (SC-1).
- **Tests** — `test/derived_harvests_test.dart`:
  - Grupo `'Jornal · lo que sí'`:
    - `un jornal de Cosechar con kilos da exactamente una cosecha`
      (id, cropId, amount, `unit == 'kg'`, destino vendido, fecha, `pendingSync false`)
    - `varios jornales medidos dan una cosecha por jornal`
    - `el id lleva el prefijo der_jornal_ y no es de venta`
      (`isJornalDerivedHarvest true`, `isSaleDerivedHarvest false`)
    - `la cosecha del jornal enciende hasIndependentHarvest`
  - Grupo `'Jornal · lo que no'`:
    - `sin kilos no deriva`
    - `kilos 0 o negativos no derivan`
    - `labor distinta de Cosechar no deriva`
    - `sin cultivo no deriva`
    - `un jornal borrado no deriva`
    - `«Otra…» con texto «cosechar» no deriva`
    - `un ingreso con categoría mano_obra no deriva`
  - Grupo `'Prioridad manual > jornal > venta'`:
    - `la cosecha manual manda sobre el jornal`
    - `la cosecha manual de otro cultivo no frena el jornal`
    - `el jornal suprime la venta del mismo cultivo` (venta 480 + jornal 500 → solo 500)
    - `un jornal medido no suprime la venta de otro cultivo`
    - `un jornal sin kilos no suprime la venta`
    - `con un jornal medido, la venta no rellena los jornales sin kilos`
      (jornal 500 + jornal sin kilos + venta 480 → solo 500; trade-off D3)
    - `un jornal borrado no suprime la venta`
  - Grupo `'D4 / D5 · la fuente se distingue sin mirar adentro'`:
    - reemplazar el `Harvest(id: 'der_jornal_v1')` sintético por la salida real de
      `deriveHarvests`; conservar las tres aserciones (`isSaleDerivedHarvest false`,
      `hasIndependentHarvest true`, `pendingSync false`).
- **Rojo esperado:** el primer test
  `un jornal de Cosechar con kilos da exactamente una cosecha` falla por aserción
  `Expected: <1> Actual: <0>` (la función todavía ignora los gastos). Después, los
  tests que usan `kJornalDerivedPrefix` dan rojo de compilación hasta agregar la constante.
- **Hecho:** el grupo entero en verde; los tests de venta existentes siguen verdes
  (G2); la lista de entrada no se muta (D1).
- **Depende:** T2, T3 · **Riesgo:** **alto** — es la regla central y el doble conteo.

#### T5 · El provider escribe el dato y deriva

- **Archivos:** `lib/providers/transaction_provider.dart`,
  `test/derived_harvests_provider_test.dart`.
- **Cambio:** agregar `double? harvestedKg` al final de la firma de `addTransaction` y
  pasarlo al `Transaction`. `updateTransaction` no cambia (recibe el objeto completo).
  `harvests` y `storedHarvests` **no cambian de forma**.
- **Tests** — `test/derived_harvests_provider_test.dart`, grupo
  `'Tanda 2 · el jornal medido'`:
  - `addTransaction conserva los kilos y harvests deriva la cosecha del jornal`
  - `storedHarvests sigue conteniendo solo lo guardado` (sin `der_jornal_`)
  - `borrar el jornal apaga su cosecha en la siguiente lectura`
  - `editar los kilos corrige la cosecha`
  - `cambiar la labor y limpiar los kilos apaga la cosecha`
  - `un jornal con kilos de un cultivo borrado no rompe la lectura` (G14)
  - `varios jornales del mismo cultivo dan una cosecha cada uno`
- **Rojo esperado:** compilación
  `No named parameter with the name 'harvestedKg'` al escribir la primera llamada.
- **Hecho:** grupo en verde; `harvests` incluye la derivada y `storedHarvests` no.
- **Depende:** T4 · **Riesgo:** medio (única puerta de escritura del jornal).
- **Efecto colateral documentado:** `reconcilePhaseFromHarvests()` lee `harvests`, así
  que un jornal medido **también promueve** el cultivo de `establecimiento` a
  `produccion`, igual que una venta. No se cambia en esta tanda; si no se quisiera,
  sería una decisión aparte.

---

### Fase 2 — Copy y pantalla

#### T6 · Copy ES/EN y `gen-l10n`

- **Archivos:**
  - `lib/l10n/app_es.arb` (template)
  - `lib/l10n/app_en.arb`
  - `lib/l10n/generated/app_localizations.dart`,
    `app_localizations_es.dart`, `app_localizations_en.dart` (generados)
  - `test/l10n_jornal_keys_test.dart` (nuevo)
- **Cambio:** agregar exactamente las cuatro claves de D13:
  - `jornalHarvestedKgLabel`: «Kilos recolectados (opcional)» /
    “Harvested kilos (optional)”
  - `jornalHarvestedKgHint`: «Para comparar lo cosechado con lo vendido.» /
    “To compare what you harvested with what you sold.”
  - `jornalHarvestedKgInvalid`: «Ingresa los kilos recolectados (mayor que 0).» /
    “Enter the harvested kilos (greater than 0).”
  - `jornalHarvestedKgNeedsCrop`: «Elegí el cultivo para anotar los kilos.» /
    “Select the crop to record the kilos.”
  - Después: `flutter gen-l10n` (no editar los generados a mano).
- **Tests** — `test/l10n_jornal_keys_test.dart`, grupo
  `'Claves del jornal medido'`:
  - `las cuatro claves existen y no están vacías en ES y EN`
  - `la etiqueta habla de kilos, no de dinero` (ES contiene «Kilos», EN “kilos”)
  - `ningún texto nuevo menciona bodega o almacenamiento` (G7)
  - `la validación pide un valor mayor que 0`
- **Rojo esperado:** `Expected: <true> Actual: <false>` en
  `arb.containsKey('jornalHarvestedKgLabel')`.
- **Hecho:** `flutter gen-l10n` corrido; test en verde; los cuatro textos visibles en ES.
- **Depende:** T1 · **Riesgo:** bajo (orden: ARB → generar → UI).

#### T7 · El campo en `RegisterScreen`

- **Archivos:** `lib/screens/register_screen.dart`, `test/register_screen_test.dart`.
- **Cambio:**
  - `final _jornalHarvestedKgController = TextEditingController();` + `dispose()`.
  - Getter de visibilidad:
    `_isJornal && _jornalTaskValue == kTaskCosechar && _cropId != null && _terrenoId == null`.
  - `initState`: restaurar el jornal primero (labor, cultivo, lote) y, si al terminar
    el campo es visible y `e.harvestedKg != null`, cargarlo en el controlador con el
    mismo formato entero/decimal que días y valor día. Si está oculto, se deja vacío
    (D12: lo oculto no se restaura).
  - UI **después del bloque de labor** y antes de los días:
    - Si es visible: `TextFormField` numérico decimal, etiqueta
      `jornalHarvestedKgLabel`, `helperText: jornalHarvestedKgHint`, `suffixText: 'kg'`,
      prefijo de balanza. Sin símbolo de moneda.
    - Si la labor es `cosechar` pero **no** hay cultivo (o hay lote): mostrar solo el
      aviso `jornalHarvestedKgNeedsCrop`, sin campo.
  - Validación (solo si el campo está visible): vacío → `null`; con texto, parsear con
    `replaceAll(',', '.')`; si no es número o es `<= 0` → `jornalHarvestedKgInvalid`
    y no se guarda.
  - Al cambiar labor, cultivo, lote, tipo o categoría: si el campo deja de ser visible,
    **limpiar el controlador** (D12: lo oculto no se guarda ni se restaura).
  - En `_save`: calcular `harvestedKg` **solo** si es visible (visible + vacío → `null`;
    oculto → `null`) y pasarlo:
    - edición: al `Transaction(...)` que ya se construye directamente;
    - alta: a `tx.addTransaction(..., harvestedKg: ...)`.
  - No tocar `amount`, `quantity`, `unit`, `pricePerUnit`: el pago sigue
    `días × valor día`, `unit = 'día'`.
  - Limpiar el controlador al terminar de guardar.
- **Tests** — `test/register_screen_test.dart`, grupo
  `'Kilos recolectados en el jornal (Tanda 2)'`:
  - `con Mano de obra, Cosechar y cultivo aparece el campo`
  - `con otra labor el campo no aparece`
  - `sin cultivo no aparece y muestra «Elegí el cultivo…»`
  - `con lote no aparece, muestra el aviso y guarda null` (G13)
  - `«Otra…» con texto «cosechar» no enciende el campo` (G12)
  - `vacío guarda null y el jornal es válido` (SC-8)
  - `cero bloquea el guardado con el mensaje` (A9)
  - `negativo bloquea el guardado con el mensaje` (A9)
  - `texto no numérico bloquea el guardado con el mensaje` (A9)
  - `coma decimal se guarda como 120,5`
  - `editar un jornal restaura los kilos en el campo` (D12)
  - `cambiar la labor a Abonar guarda null` (A8)
  - `quitar el cultivo guarda null` (A4)
  - `el pago sigue siendo días × valor día` (2 × 50.000 = 100.000, quantity 2, unit día)
  - `el campo se expresa en kg y no lleva símbolo de moneda` (SC-15/G9)
- **Rojo esperado:** el primer test de visibilidad falla por aserción
  `Expected: one widget … Actual: zero widgets` para la etiqueta. Los tests de
  validación/guardado fallan después por `harvestedKg` nulo o por el mensaje ausente.
- **Hecho:** grupo en verde; el campo no aparece en ningún caso fuera de la combinación
  permitida; el controlador queda limpio al ocultar y al guardar.
- **Depende:** T2–T6 · **Riesgo:** medio-alto (estado oculto, controlador obsoleto,
  validación que no debe bloquear un jornal sin kilos).

---

### Fase 3 — Sync, migración y respaldo

#### T8 · Payload y lectura remota

- **Archivos:** `lib/providers/sync_provider.dart`, `test/sync_push_test.dart`.
- **Cambio:**
  - `buildTransactionPayload`: `'harvested_kg': t.harvestedKg` **siempre**, incluido
    `null` (igual que `task`; nunca `0`).
  - `_remoteToTransaction`: `'harvested_kg': (row['harvested_kg'] as num?)?.toDouble()`.
  - Para poder probar la lectura, renombrar `_remoteToTransaction` a
    `remoteToTransaction` con `@visibleForTesting` (mismo patrón que `remoteToCrop` y
    `remoteToTerreno`) y actualizar su único llamador del pull. El PRD lo llama
    `_rowToTransaction`; en el código actual el nombre es `_remoteToTransaction`.
  - No tocar el uso de `storedHarvests`.
- **Tests** — `test/sync_push_test.dart`, grupo
  `'Payload: kilos recolectados (Tanda 2)'`:
  - `harvested_kg sale siempre, incluido cuando es null`
  - `un valor decimal viaja sin redondear`
  - `enviar null no inventa 0`
  - `lo que baja de Supabase conserva harvested_kg`
  - `una fila vieja sin harvested_kg carga null`
- **Rojo esperado:** `Expected: <true> Actual: <false>` en
  `payload.containsKey('harvested_kg')`. La prueba de lectura da rojo de compilación
  hasta hacer público `remoteToTransaction`.
- **Hecho:** grupo en verde; el payload de un jornal sin kilos lleva `null`.
- **Depende:** T2 · **Riesgo:** **alto** si se olvida la lectura: el pull perdería el dato.

#### T9 · Migración `transactions.harvested_kg`

- **Archivos:**
  - `supabase/migrations/202610190001_add_transaction_harvested_kg.sql` (nuevo)
  - `test/migration_harvested_kg_test.dart` (nuevo, contrato estático)
- **Cambio:** migración aditiva, nullable, idempotente, **sin backfill** y sin índice:

  ```sql
  -- Tanda 2 · kilos recolectados en el jornal de «Cosechar».
  -- Aplicar ANTES de desplegar la app que envía harvested_kg:
  -- si la columna no existe, PostgREST responde PGRST204 y se cae el push completo.
  -- Aditiva y nullable: los jornales viejos quedan en null y se comportan como antes.
  alter table public.transactions
    add column if not exists harvested_kg numeric;

  comment on column public.transactions.harvested_kg is
    'Kilos recolectados anotados en un jornal de labor Cosechar. Null = no medido. No afecta el pago (días × valor día).';
  ```

  No cambian RLS, políticas ni otras columnas.
- **Tests** — `test/migration_harvested_kg_test.dart`, grupo
  `'Migración harvested_kg'`:
  - `el archivo existe y declara la columna harvested_kg`
  - `es idempotente: usa if not exists`
  - `no hace backfill ni toca otras columnas`
- **Rojo esperado:** el primer test falla porque el archivo no existe
  (`Expected: true Actual: false`). Es un contrato estático: **no sustituye** la
  aplicación real en Supabase.
- **Hecho:** test en verde; migración revisada contra
  `202610110002_add_work_budget_and_task.sql` (mismo estilo aditivo).
- **Depende:** T1 · **Riesgo:** **alto** (PGRST204 si se despliega antes).

#### T10 · Respaldo y datos viejos

- **Archivos:** `test/backup_import_test.dart`, `test/backup_service_test.dart`.
  **Sin cambios en `lib/`**: `encodeBackup`/`decodeBackup` ya pasan por
  `toJson`/`fromJson`.
- **Tests** — `test/backup_import_test.dart`, grupo
  `'Kilos recolectados (Tanda 2)'`:
  - `un respaldo anterior sin harvested_kg carga null y no deriva cosecha`
  - `el respaldo conserva 120.5 en un jornal medido`
  - `el respaldo de un jornal medido no contiene der_jornal_`
  - `importar un respaldo viejo no cambia amount, quantity ni unit`

  `test/backup_service_test.dart`, grupo `'Kilos recolectados (Tanda 2)'`:
  - `encodeBackup escribe harvested_kg en el JSON`
  - `un respaldo sin la clave decodifica sin error`
- **Rojo esperado:** **guarda**. El caso “sin la clave” se escribe en el lote de rojo de
  T2 y se ve fallar por la clave ausente; el caso de derivación se apoya en T4/T5. Al
  llegar a T10 el grupo queda verde y no se fuerza un rojo artificial: su valor es la
  regresión de punta a punta del respaldo, no un arreglo nuevo.
- **Hecho:** grupo en verde; queda demostrado que G11/SC-12/G4 se cumplen de punta a punta.
- **Depende:** T2, T5 · **Riesgo:** medio (si alguien cambia el mapeo del respaldo).

---

### Fase 4 — Reportes, verificación y cierre

#### T11 · Guardas de los pintadores y de las métricas

- **Archivos:** `test/derived_harvests_report_test.dart`,
  `test/report_harvest_metrics_test.dart`.
  **Sin cambios en `lib/`** (D8): pantalla, PDF y Excel ya leen `provider.harvests` y
  `hasIndependentHarvest`.
- **Tests** — `test/derived_harvests_report_test.dart`, grupo
  `'Los tres pintadores dicen lo mismo'` (extensión):
  - `la tarjeta «Vendido vs cosechado» se enciende con el jornal`
  - `la tarjeta sigue oculta cuando la única fuente es la venta` (regresión D5)
  - `el Excel pinta 500 cosechados y 480 vendidos para el jornal`
  - `el PDF se construye con el jornal medido y sigue siendo un PDF válido`
  - `pantalla y Excel usan el mismo harvestedKg` (el mismo `p.harvests` de entrada)

  `test/report_harvest_metrics_test.dart`, grupo `'Jornal medido · efecto esperado'`:
  - `yieldPerArea incluye los kilos del jornal en el denominador` (500 kg / 1 ha)
  - `totalCostPerKg baja porque el denominador crece` (A15: efecto esperado; crear el
    cultivo en `produccion` o dejar que el jornal lo promueva, para que la métrica no
    devuelva `null` por fase)
  - `pickupCostPerKg no cuenta el jornal como gasto de recogida` (G10: no tiene
    `harvestId`; el numerador no cambia)
- **Rojo esperado:** **guarda**. El rojo de la tarjeta se registra en T5 (el test se
  escribe antes de que `addTransaction` acepte `harvestedKg` y falla por compilación:
  `No named parameter with the name 'harvestedKg'`); en T11 solo se comprueba que
  sigue verde. No se fabrica un fallo.
- **Hecho:** los tres pintadores reciben la misma lista y los mismos números; el PDF y
  el Excel se generan sin excepción; la tarjeta sigue oculta con solo venta.
- **Depende:** T5, T7 · **Riesgo:** bajo-medio (un pintador que lea `_harvests` directo
  en vez de `harvests` no vería el jornal; el test lo delata).

#### T12 · Gate, verificación manual y orden de despliegue

- **Archivos:** `docs/reports/2026-10-19_kilos-jornal.md` (nuevo).
- **Cambio:** ninguno en `lib/`. Ejecutar el gate completo, la verificación manual del
  usuario y el despliegue en el orden de §6.
- **Tests:** el gate completo:
  - `flutter analyze` → 0 issues (proyecto entero, `tool/` incluido).
  - `flutter test` → todo verde; anotar el conteo final (base 975 + nuevos).
  - `flutter gen-l10n` ya corrido; sin diffs pendientes en generados.
- **Rojo esperado:** no aplica.
- **Hecho:** reporte de cierre con comandos, conteo, evidencia manual y checklist de
  despliegue. El plan pasa a `DONE` **solo después** de que el usuario valide la
  verificación manual; hasta entonces queda `READY`.
- **Depende:** T1–T11 · **Riesgo:** alto en el orden de despliegue, no en el código.

## 5. Tests existentes que pueden romperse (y cómo se ajustan)

Ningún test actual combina **una venta y un jornal medido** (`mano_obra` +
`task: 'cosechar'` + `harvestedKg > 0`) en el mismo cultivo. Por eso la nueva
supresión de la venta no cambia los fixtures existentes: los casos que hoy afirman
«una venta con cultivo y kilos deriva» siguen siendo válidos porque su fixture no
tiene jornal medido. Lo que **no** se hace es borrar ni debilitar esos tests; la
convivencia se cubre con casos nuevos en T4.

| Test / grupo | Por qué podría romperse | Ajuste (sin aflojar la regla) |
|---|---|---|
| `test/derived_harvests_test.dart` · `'una derivada de OTRA fuente también cuenta como independiente'` | Hoy usa un `Harvest(id: 'der_jornal_v1')` sintético. Al existir la fuente real, el test simulado deja de probar la derivación. | Reemplazarlo por la salida real de `deriveHarvests`; conservar `isSaleDerivedHarvest == false`, `hasIndependentHarvest == true` y `pendingSync == false`. No borrar el caso. |
| `test/derived_harvests_provider_test.dart` · conteos `hasLength(1/2)` | Si el fixture compartido `vender()` empieza a incluir un jornal medido, cambian los conteos. | Mantener `vender()` solo-venta; crear un helper separado `jornal(...)` para los casos nuevos. No cambiar los `hasLength` existentes. |
| `test/derived_harvests_report_test.dart` · `build()` y `'D5 queda OCULTA'` | Si `build()` agrega un jornal, la tarjeta se enciende y el test de D5 falla con razón. | Dejar `build()` solo-venta; agregar `buildConJornal()` para los casos nuevos. El test de D5 no se toca. |
| `test/transaction_provider_test.dart` · `'la primera cosecha promueve…'` (`harvests` `hasLength(1)`) | Un jornal medido agregaría una derivada. | El fixture no tiene jornal; no se toca. Si se amplía, ajustar el fixture, no la aserción. |
| `test/backup_import_test.dart` · `expect(harvests, hasLength(1))` | Un jornal medido en el respaldo compartido agregaría otra cosecha. | Dejar el respaldo compartido sin jornal; los casos nuevos usan su propio payload. |
| `test/register_screen_test.dart` · conteos/posición de campos | El campo nuevo solo aparece con `mano_obra + cosechar + cultivo`; ningún test actual combina las tres. El aviso `jornalHarvestedKgNeedsCrop` solo aparece con `cosechar`. | No cambiar aserciones existentes. Si algún test futuro elige `Cosechar`, agregar la expectativa explícita del aviso/campo. |
| `test/jornal_test.dart` y `test/work_sheet_test.dart` | `kTaskCosechar` conserva el valor `'cosechar'`; la nómina ignora el campo nuevo. | Sin cambios: son la guarda de que el pago y la tecla no se movieron. |
| `test/sync_push_test.dart` · payloads | El payload gana una clave. Si algún test compara el mapa completo, falla. | Agregar `'harvested_kg': null` al mapa esperado; **no** quitar la comparación ni la clave. |
| `test/transaction_test.dart` · `'toJson de registro sin campos no incluye claves problemáticas'` | La clave nueva **sí** está siempre (en `null`), a diferencia de `quantity` ausente. | No agregarla a la lista de “no incluye”; el caso correcto es un test aparte que exija `containsKey('harvested_kg')` con valor `null`. |
| `test/help_no_orphan_keys_test.dart` y `test/l10n_placeholder_order_test.dart` | Solo miran claves `help*` y placeholders. Las cuatro claves nuevas no son `help*` ni tienen placeholders. | Sin cambios. |
| `test/pdf_export_test.dart` | Sus jornales de `mano_obra` no tienen `task` ni kilos. | Sin cambios; sigue siendo el humo de que un jornal sin kilos no altera el PDF. |

## 6. Migración y orden de despliegue

**Regla dura:** la columna existe en Supabase **antes** de que la app nueva la envíe.
Si no, PostgREST devuelve `PGRST204` y se cae el push completo (mismo caso que `task`
en `202610110002`).

1. **Congelar** el despliegue de la app nueva.
2. Aplicar `202610190001_add_transaction_harvested_kg.sql` en **staging**.
3. Verificar en staging:

   ```sql
   select column_name, data_type, is_nullable
   from information_schema.columns
   where table_schema = 'public'
     and table_name = 'transactions'
     and column_name = 'harvested_kg';
   -- esperado: harvested_kg | numeric | YES
   ```

4. Aplicar la misma migración en **producción** y repetir la consulta.
5. **Recién entonces** desplegar la app (build web/mobile).
6. Smoke de producción: crear un jornal con 120 kg, sincronizar y comprobar
   `select id, task, harvested_kg from public.transactions where id = '<id>';`
   → `task = 'cosechar'`, `harvested_kg = 120`.
7. Segundo equipo / segundo login: pull y comprobar que el jornal conserva 120 y que
   **no** aparece ninguna fila `der_jornal_*` en `harvests`.
8. **Rollback:** revertir solo la app. **No** borrar la columna: la app vieja la ignora
   y borrarla perdería los datos ya medidos. La migración es idempotente; reintentarla
   es seguro.

## 7. Verificación manual del usuario (después del gate)

Con una finca de prueba, en el orden indicado:

1. Crear el cultivo **Café** (con 1 ha si se quiere ver el rendimiento).
2. Registrar un jornal: trabajador, labor **Cosechar**, cultivo **Café**,
   **2 días × COP 50.000**, **120 kg**. Guardar.
3. Comprobar en el historial: monto **COP 100.000**, días 2, unidad día; reabrir y ver
   que el campo muestra **120**.
4. Registrar una venta de **100 kg** del mismo cultivo en el mismo mes.
5. Abrir **Reportes**: la tarjeta «Vendido vs cosechado» debe verse con
   **cosechado 120** y **vendido 100**. (Con 140 vendidos se ve además el aviso de la
   regla 6; el umbral y el copy no cambian en esta tanda.)
6. Exportar **PDF** y **Excel** del mismo período: los tres deben mostrar 120/100.
   El PDF y el Excel no llevan código nuevo; se encienden solos.
7. Abrir la **planilla/nómina**: 2 días y COP 100.000; **no** debe aparecer una columna
   de kilos.
8. Casos que deben quedar ocultos:
   - jornal con labor **Abonar** → sin campo; al guardar, `harvestedKg = null`;
   - jornal **sin cultivo** → sin campo y con el aviso «Elegí el cultivo…»;
   - jornal **con lote** → sin campo y `null`;
   - jornal con labor **«Otra…»** y texto «cosechar» → sin campo y sin cosecha.
9. Jornal sin kilos: la app se comporta como antes; con solo ventas, la tarjeta sigue
   oculta.
10. Importar un respaldo viejo (sin `harvested_kg`): carga sin error, el jornal queda
    en `null` y no aparece cosecha derivada.
11. Con la migración ya aplicada, sincronizar y revisar Supabase; luego pull en otro
    equipo. Confirmar que `der_jornal_*` nunca se sube.

## 8. Gate, stageo y artefactos

### Gate

```bash
flutter analyze          # proyecto entero, tool/ incluido
flutter test             # todo verde
```

Por fase, además, el subconjunto que toca esa fase (por ejemplo
`flutter test test/derived_harvests_test.dart`). El rojo y el verde se pegan en
`docs/reports/2026-10-19_kilos-jornal-rojo.md`; el cierre va en
`docs/reports/2026-10-19_kilos-jornal.md`.

### Stageo explícito (nunca `-A`)

| Fase | `git add` |
|---|---|
| 1 | `git add lib/models/transaction.dart lib/models/tasks.dart lib/services/derived_harvests.dart lib/providers/transaction_provider.dart test/transaction_test.dart test/jornal_test.dart test/work_sheet_test.dart test/tasks_test.dart test/derived_harvests_test.dart test/derived_harvests_provider_test.dart` |
| 2 | `git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_es.dart lib/l10n/generated/app_localizations_en.dart lib/screens/register_screen.dart test/l10n_jornal_keys_test.dart test/register_screen_test.dart` |
| 3 | `git add lib/providers/sync_provider.dart supabase/migrations/202610190001_add_transaction_harvested_kg.sql test/sync_push_test.dart test/migration_harvested_kg_test.dart test/backup_import_test.dart test/backup_service_test.dart` |
| 4 | `git add test/derived_harvests_report_test.dart test/report_harvest_metrics_test.dart docs/reports/2026-10-19_kilos-jornal-rojo.md docs/reports/2026-10-19_kilos-jornal.md` |

Antes de cada stageo: `git status --short` y confirmar que solo están los archivos
previstos. **Ningún commit ni push** hasta que el usuario lo pida explícitamente.

## 9. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Doble conteo jornal + venta | Media | Alto | D3 por cultivo; `jornalCrops` suprime la venta; tests A6 y G2. |
| Subconteo si solo se miden algunos jornales | Media | Medio | Decisión Q2 aceptada; hint en pantalla; nunca se inventa el resto. |
| La regla 6 salta por medición parcial | Media | Medio | Q5: mismo umbral y copy; el usuario decide. |
| Migración no aplicada antes del deploy | Media | **Alto** | `if not exists` + orden §6 + consulta a `information_schema` + gate de deploy. |
| Pérdida del dato en pull/merge | Baja | **Alto** | Payload y `remoteToTransaction`; test A14 con ida y vuelta. |
| Valor oculto guardado por cambio de labor/cultivo | Media | Medio | Limpiar al ocultar y guardar `null`; tests A4/A8/G12/G13. |
| `copyWith` sin sentinela no permite limpiar | Media | Medio | Misma sentinela que `task`; test `copyWith permite limpiar…`. |
| «Otra…» con texto «cosechar» no enciende el campo | Baja | Bajo | D4/G12; solo la tecla del catálogo. |
| Lote con cultivo por dato legado | Baja | Bajo | La UI exige cultivo y no lote; la función prioriza `cropId`; test G13. |
| Cultivo borrado con jornal medido | Baja | Bajo | `deleteCrop` deja `cropId = null`; la derivada desaparece sin crash; G14. |
| Métricas de costo/kg y rendimiento cambian | Alta | Medio | Efecto esperado (A15/G10); no fijar valores viejos en fixtures con jornal. |
| Un pintador lee `_harvests` y no ve el jornal | Baja | Medio | T11 verifica pantalla/PDF/Excel con la misma entrada `harvests`. |
| El jornal medido promueve la fase del cultivo | Media | Bajo | Efecto de `reconcilePhaseFromHarvests`; se documenta en T5; no se cambia sin decisión. |
| ARB sin `gen-l10n` rompe la compilación de la UI | Media | Bajo | T6 corre `flutter gen-l10n` antes de T7. |

## 10. Trazabilidad PRD

### Success Criteria (SC)

| Criterio | Tarea(s) | Evidencia |
|---|---|---|
| SC-1 · Una cosecha `der_jornal_<id>` por jornal medido | T4, T5 | `un jornal de Cosechar con kilos da exactamente una cosecha`; test de provider |
| SC-2 · Sin kilos (`null`/0/negativo) no deriva | T4 | `sin kilos no deriva`, `kilos 0 o negativos no derivan` |
| SC-3 · Manda lo manual | T4 | `la cosecha manual manda sobre el jornal` |
| SC-4 · Jornal por encima de la venta | T4 | `el jornal suprime la venta del mismo cultivo` |
| SC-5 · Borrado limpio | T4, T5 | `un jornal borrado no deriva`; `borrar el jornal apaga su cosecha` |
| SC-6 · Cambio de labor limpia | T4, T7 | `labor distinta de Cosechar no deriva`; `cambiar la labor a Abonar guarda null` |
| SC-7 · Sin cultivo/lote no hay campo | T7 | `sin cultivo no aparece…`; `con lote no aparece…` |
| SC-8 · Validación vacío/≤0/texto | T7 | `vacío guarda null`; `cero/negativo/texto bloquean…` |
| SC-9 · El pago no se toca | T2, T7 | `Kilos no tocan el pago`; `el pago sigue siendo días × valor día` |
| SC-10 · Tres pintadores de acuerdo | T11, T12 | Grupo `'Los tres pintadores dicen lo mismo'`; verificación manual §7 |
| SC-11 · Sigue callada sin fuente independiente | T4, T11 | Test de venta existente; `la tarjeta sigue oculta…` |
| SC-12 · Compatibilidad hacia atrás | T2, T10 | `fromJson sin la clave carga null`; respaldo viejo |
| SC-13 · Sync conserva el dato | T8 | Payload + lectura remota + `enviar null no inventa 0` |
| SC-14 · Nada derivado se sube | T5, T10 | `storedHarvests sigue conteniendo solo lo guardado`; respaldo sin `der_jornal_` |
| SC-15 · Kilos no son moneda | T4, T6, T7 | `unit == 'kg'`; copy; `el campo se expresa en kg…` |

### Acceptance (A)

| Criterio | Tarea(s) | Evidencia |
|---|---|---|
| A1 · Deriva una cosecha | T4, T5 | Caso base 2 días × 50.000 + 120 kg |
| A2 · Sin kilos no deriva | T4 | `sin kilos no deriva`; pago intacto |
| A3 · Labor distinta no deriva | T4 | `labor distinta de Cosechar no deriva` |
| A4 · Sin cultivo no hay campo ni cosecha | T7 | Visibilidad + guardado `null` |
| A5 · Manda lo manual | T4 | Prioridad manual |
| A6 · Jornal por encima de la venta | T4, T11 | 480 vendidos / 500 cosechados |
| A7 · Borrado | T4, T5 | Jornal `deleted = true` |
| A8 · Cambio de labor limpia | T7 | `cambiar la labor a Abonar guarda null` |
| A9 · Validación | T7 | Tres casos de bloqueo |
| A10 · Pago intacto | T2, T7 | Amount/días/unidad + payroll/workSheetRows (`Kilos no tocan el pago` y `Kilos no tocan la planilla`) |
| A11 · Tres pintadores | T11, T12 | Pantalla, PDF, Excel; verificación manual |
| A12 · Solo venta sigue oculta | T4, T11 | Regresión D5 |
| A13 · Serialización y respaldo | T2, T10 | Round-trip con/sin clave |
| A14 · Sync | T5, T8 | Ida y vuelta; `storedHarvests` sin derivadas |
| A15 · Efecto en métricas | T11 | `yieldPerArea` y `totalCostPerKg` con denominador 500 |

### Guardas (G)

| Guarda | Tarea(s) | Evidencia |
|---|---|---|
| G1 · Gate base | T1, T12 | Analyze + test |
| G2 · Venta intacta | T4 | Tests existentes de `derived_harvests` |
| G3 · D2 intacta | T4 | Manual > jornal |
| G4 · Nada derivado se persiste | T5, T10 | `storedHarvests`; respaldo |
| G5 · Sin zombies | T5 | No hay fila en disco; `mergeRemoteHarvests` no la revive |
| G6 · Nómina intacta | T2 | `payroll` (`test/jornal_test.dart`) y `workSheetRows` (`test/work_sheet_test.dart`) |
| G7 · Pantallas cerradas | T6, T12 | Copy sin bodega; diff sin `HarvestScreen`/`home_screen` |
| G8 · D5 intacta | T4, T11 | Tarjeta oculta con solo venta |
| G9 · Moneda intacta | T7, T11 | Campo en kg; tests de moneda sin cambios |
| G10 · Costo de recogida | T11 | `pickupCostPerKg no cuenta el jornal…` |
| G11 · Datos viejos | T2, T10 | `fromJson` sin clave / respaldo viejo |
| G12 · «Otra…» no enciende | T4, T7 | Labor libre «cosechar» |
| G13 · Lote no enciende | T7 | Visibilidad + `null` |
| G14 · Cultivo borrado | T4, T5 | `un jornal con kilos de un cultivo borrado…` |

---

**Estado final de este plan: `READY`.** No se ha modificado código ni datos.
El `DONE` se marca únicamente después del gate completo, la verificación manual del
usuario y el despliegue en el orden de §6.
