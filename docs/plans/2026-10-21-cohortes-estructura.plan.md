---
prd: docs/prds/2026-10-21_1818-cohortes-estructura.prd.md
status: READY
created: 2026-10-21_1930
updated: 2026-10-21_1930
---

# Cohortes dentro de un cultivo — Etapa A «estructura» — plan de implementación

> De dónde sale: `docs/prds/2026-10-21_1818-cohortes-estructura.prd.md`
> (**APPROVED** el 2026-10-21; D1–D11 cerradas) y §12 de
> `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md`.
> Formato y estilo: `docs/plans/2026-10-20-datos-sin-mentira.plan.md` (tanda 4).
> **Este documento no implementa nada**: es el plan para ejecutar la etapa.
> Estado **READY**: 20 tareas en 10 fases, listas para arrancar.
> **Etapa B (atribuir cosechas), reportes por cohorte, recepa/socola y asocio
> quedan fuera.**

## 1. Objetivo

Que un cultivo pueda tener **varias edades** sin que la app invente números:

1. cada **siembra** abre una **cohorte** (lote) con su fecha, sus matas y su área;
2. una siembra posterior puede **reemplazar** matas y hectáreas de una cohorte
   anterior (`replaces_plants`, `replaces_area_ha`, `cohort_sowing_id`);
3. cada **resiembra** pertenece a una cohorte y le ajusta sus matas;
4. la edad se muestra **por lote**, y con dos o más el encabezado dice
   **«N edades»** (ningún promedio inventado);
5. una cohorte que llega a **0 matas** se conserva como **«renovada»** en el
   historial, fuera de totales y divisor;
6. los **kilos siguen siendo del cultivo entero**: `harvests` no se toca.

La regla de oro no cambia: **`null` → oculto, nunca 0 inventado**; si un dato no
se puede calcular sin mentir, no se pinta.

## 2. Alcance

### Entra

- Tres columnas nuevas en `sowings` + índice, en una migración aditiva.
- Modelo `Sowing` con los tres campos, JSON, `copyWith` con centinela y reglas
  de limpieza en `fromJson`.
- Funciones puras: `cropCohorts`, `recomputeCropState` (suma de cohortes),
  edad por cohorte, `lossEarliestDate` con cohorte, normalización de datos
  viejos, validadores y precarga del reemplazo.
- Provider: `addSowing`/`updateSowing`/`deleteSowing` con punteros,
  normalización al abrir, regla de área (D6) y recálculo tras el pull.
- Sync y respaldo: las tres claves viajan **siempre** (incluido `null`);
  huérfanos del puntero.
- Formulario de siembra («Amplío / Renuevo»), resiembra por lote, pérdidas con
  la fecha de la cohorte elegida.
- Tarjeta del cultivo: chip «N edades», desglose y sección «Lotes renovados».
- Rótulo «promedio de N edades» en el panel por hectárea.
- Copy ES/EN, `gen-l10n`, y las guardas de paridad y de estructura.

### No entra (del PRD, §Out of Scope)

- **Atribuir cosechas a un lote** (`harvests.sowing_id`, selector al vender o
  cosechar, lista «sin cohorte», kg/planta por lote): **etapa B**.
- Repartir los kilos de una venta mezclada por edad o por área.
- **Recepa/socola** (la mata sigue viva: no es siembra ni resiembra).
- **Asocio** (dos cultivos en la misma área) y hectáreas equivalentes.
- `SowingKind` nuevo y `closed_at`: una cohorte se cierra cuando sus matas
  vivas llegan a 0, y el estado se **deriva**.
- Cambios en `transactions.sowing_id` (ahí significa «gasto de esa siembra»).
- Editar o borrar siembras **en grupo**.
- Exportes nuevos: PDF/Excel no cambian de diseño (heredan los totales
  corregidos). Tampoco se tocan `HarvestDestination.almacenado`, la pantalla
  Cosechar, el renderer, las fuentes ni `NOTICES`.
- **Fusionar** dos cohortes: si él anotó mal la renovación, la salida es editar
  los reemplazos (deuda declarada en el PRD).
- Comparar la suma de áreas de cohortes contra el **terreno**: eso ya lo hace la
  Tanda 4 a nivel de cultivo.

### Reglas de ejecución

- Un test por arreglo; cuando no hay rojo posible, se declara **guarda**.
- Gate antes de commit y deploy: `C:\flutter\bin\flutter.bat analyze` (proyecto
  entero, `tool/` incluido) + `C:\flutter\bin\flutter.bat test`.
- **Stageo explícito**, nunca `git add -A`; `git status` antes de commitear y
  `git show --stat` después, para confirmar que no entraron miles de líneas por
  CRLF.
- LF en los archivos del repo (`lib/l10n/generated/` incluido).
- Copy ES/EN siempre; `lib/l10n/app_es.arb` es el template y `gen-l10n` corre
  después de tocar ARB.
- **Ningún commit, push ni deploy sin verbo explícito del usuario en ese
  turno** (regla del pack).
- Las migraciones las aplica **el usuario** en Supabase, antes del deploy. El
  plan da el SQL y la verificación; nunca se piden PAT ni contraseñas.
- PowerShell 5.1: sin heredoc; salidas largas de test a archivo con `*>` y
  limpieza de ANSI al leerlas.

## 3. Evidencia verificada antes de escribir el plan

Estado de partida: `main` = `origin/main` = `84ff1e1`, gate **1120/1120**,
árbol limpio salvo los docs del análisis y del PRD (sin commitear).

| Qué | Dónde | Para qué lo usa el plan |
|---|---|---|
| `Sowing` con `kind/plants/areaHa/lostPlants/reason/pendingSync` | `lib/models/sowing.dart:3-24` | punto de entrada de los tres campos |
| `copyWith` con centinela para `lostPlants`/`reason` | `lib/models/sowing.dart:26-53` | mismo patrón para los tres nuevos |
| `fromJson` como puerta única + regla `sucio` | `lib/models/sowing.dart:55-91` | dónde entran las reglas de limpieza |
| `lossEarliestDate` = siembra **más reciente** | `lib/models/sowing.dart:118-127` | pasa a ser la cohorte elegida |
| `recomputeCropState`: una **siembra reemplaza** el total | `lib/models/sowing.dart:140-182` (`:166-168`) | es exactamente lo que cambia |
| Orden por día, siembra antes que resiembra | `lib/models/sowing.dart:151-159, 193-195` | se conserva; se agrega desempate por `id` |
| `edadDeCrop` = última siembra; resiembra no reinicia | `lib/models/crop.dart:228-241` | pasa a envolver la edad por cohorte |
| `aniosCumplidos` | `lib/models/crop.dart:204-211` | se reutiliza |
| `addSowing` / `updateSowing` / `deleteSowing` | `lib/providers/transaction_provider.dart:697-747` | llevan los tres parámetros y desvinculan punteros |
| `_recomputeCropsFromSowings` con `areaHa: u.areaHa ?? c.areaHa` | `…transaction_provider.dart:751-771` (`:762`) | ahí entra la regla D6 |
| Constructor y `reloadFromCache` (punto de normalización) | `…transaction_provider.dart:43-83` | normalizar al abrir, con `unawaited(_store.save…)` como hace `_seedCashHistory` (`:914-925`) |
| Huérfanos del respaldo | `…transaction_provider.dart:1068-1084` | suma el puntero de cohorte |
| `_promotePhasesInMemory` (usa la última siembra **por fecha**) | `…transaction_provider.dart:524-560` | no se toca |
| `initialSowingCost` (aparta resiembras por `kind`) | `…transaction_provider.dart:401-421` | no se toca |
| `buildSowingPayload` sin las tres claves | `lib/providers/sync_provider.dart:450-461` | hay que agregarlas siempre |
| `_remoteToSowing` | `lib/providers/sync_provider.dart:725-737` | lee las tres claves |
| Push por fila, fallo aislado por siembra | `lib/providers/sync_provider.dart:214-220, 250-269` | una FK rota no pierde la fila |
| Pull: `sowings` después de `crops`, recálculo al final | `lib/providers/sync_provider.dart:593-615` | recálculo tras el merge |
| Formulario: estado, `_save`, sección tipo/plantas/perdidas | `lib/screens/sowing_screen.dart:199-244, 344-469, 471-614` | ahí entra la pregunta nueva |
| C6 «arranque completo» (`_restartCrop`) | `lib/screens/sowing_screen.dart:217-227, 313-324, 404-440` | interactúa con «Renuevo» (ver T14) |
| Borrado con confirmación | `lib/screens/sowing_screen.dart:152-178` | aviso antes de borrar una cohorte viva |
| Tarjeta del cultivo: edad, detalles, botones | `lib/screens/crops_screen.dart:408-541` (`:417`, `:454-462`, `:501-511`) | chip «N edades» + desglose + renovados |
| Diálogo de pérdidas con `lossEarliestDate` | `lib/widgets/crop_loss_dialog.dart:74-110` | selector de lote |
| Panel por hectárea (sin `sowings`) y su uso | `lib/widgets/per_hectare_panel.dart:17-43, 217-222`; `lib/screens/report_screen.dart:476-485` | rótulo «promedio de N edades» |
| Respaldo: `siembras` vía `toJson`/`fromJson` | `lib/services/backup_service.dart:111, 199, 245` | hereda los campos sin código nuevo |
| `formatAreaHa` y `numberLocale` | `lib/utils/format.dart:14-15` | formato de las áreas |
| `cropAge` plural (`{count, plural, =0{Menos de un año}…}`) | `lib/l10n/app_es.arb:264` | se reutiliza para los años |
| Tabla `sowings` + índice + RLS | `supabase/migrations/202609070001_add_sowings_harvests.sql:20-52` | la migración solo agrega columnas |
| Patrón del test de migración | `test/migration_harvested_kg_test.dart` | molde de T2 |
| Guarda de copy (claves en los dos ARB) | `test/l10n_tanda4_test.dart` | molde de T18 |
| Test que exige **declarar los placeholders** en orden | `test/l10n_placeholder_order_test.dart` | obliga a los bloques `@clave` |
| Test de la regla vieja «la segunda siembra reemplaza» | `test/sowing_test.dart:82-149` (`:117-125`) | hay que reescribirlo (ver §11) |
| Paridad de edad con siembra + resiembra | `test/crop_test.dart:102-114` | debe seguir verde sin tocar |
| Convención de migraciones `YYYYMMDDNNNN_nombre.sql` | `supabase/migrations/` (últimas: `202610200002_…`) | nombre final: `202610210001_add_sowings_cohorts.sql` |
| Deploy | `deploy.ps1` | cierre de la etapa |

## 4. Mapa de fases

| Fase | Tareas | Qué deja |
|---|---|---|
| 0 | T1 | Baseline del gate y de los números |
| 1 | T2 | La migración aditiva y su contrato |
| 2 | T3–T8 | Modelo, motor de cohortes, cálculo, edad, normalización y validadores |
| 3 | T9–T10 | Provider: escrituras, punteros, normalización al abrir, área y pull |
| 4 | T11–T13 | Sync, respaldo y guardas (paridad y cosechas intactas) |
| 5 | T14–T15 | Formulario: «Amplío / Renuevo» y resiembra por lote |
| 6 | T16–T17 | Tarjeta del cultivo (N edades, renovados) y Ayuda |
| 7 | T18 | Copy ES/EN consolidado, `gen-l10n` y guardas de idioma |
| 8 | T19 | Reportes: solo el rótulo «promedio de N edades» |
| 9 | T20 | Gate, informe, migración aplicada y verificación manual |

## 5. Modelo, cálculo y contrato de funciones

### 5.1 Migración exacta (`supabase/migrations/202610210001_add_sowings_cohorts.sql`)

Aditiva, idempotente, **sin backfill**: las columnas entran en `null` y la app
normaliza al abrir (D9). No toca `harvests` ni `transactions`.

```sql
-- Mi Cafetal · Etapa A · cohortes dentro de un cultivo.
-- Aditiva y retrocompatible. No toca harvests ni transactions.
-- Sin backfill: las columnas entran en null y la app normaliza al abrir.

alter table public.sowings
  add column if not exists replaces_plants integer
    check (replaces_plants is null or replaces_plants >= 0),
  add column if not exists replaces_area_ha numeric
    check (replaces_area_ha is null or replaces_area_ha >= 0),
  add column if not exists cohort_sowing_id uuid
    references public.sowings(id) on delete set null;

create index if not exists idx_sowings_cohort
  on public.sowings (cohort_sowing_id);
```

- RLS no cambia: las políticas existentes ya cubren la fila.
- La FK es **auto-referente** al destino (una siembra **anterior**), que por el
  orden de push ya está arriba. Si no lo estuviera, el push falla y la fila
  queda `pendingSync` (no se pierde).
- La base **no** valida «no reemplazar más de lo vivo»: depende del estado de
  otras filas y se valida en la app (SC-10).
- Limitación conocida de `if not exists`: si alguien aplicara la migración a
  medias (columna creada sin FK), volver a correrla no agrega la FK. Se detecta
  con la verificación de abajo.

**Verificación en Supabase** (SQL Editor, después de aplicar):

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'sowings'
  and column_name in ('replaces_plants','replaces_area_ha','cohort_sowing_id')
order by column_name;

select conname, confdeltype
from pg_constraint
where conrelid = 'public.sowings'::regclass
  and conname = 'sowings_cohort_sowing_id_fkey';   -- confdeltype = 'n' (set null)

select indexname from pg_indexes
where schemaname = 'public' and tablename = 'sowings'
  and indexname = 'idx_sowings_cohort';

-- sin backfill: recién aplicada, ninguna fila tiene los campos
select count(*) as con_dato
from public.sowings
where replaces_plants is not null
   or replaces_area_ha is not null
   or cohort_sowing_id is not null;
```

Esperado: 3 filas, 1 FK con `confdeltype = 'n'`, 1 índice, `con_dato = 0`.

### 5.2 Motor de cohortes (`cropCohorts`)

```dart
class Cohort {
  final String sowingId;      // id de la siembra que abrió la cohorte
  final DateTime date;        // fecha de nacimiento (no se reordena al restar)
  final int livePlants;       // nunca negativo
  final double? areaHa;       // null si no se conoce
  final DateTime? closedOn;   // fecha de la siembra que la dejó en 0
  bool get open => livePlants > 0;
}

List<Cohort> cropCohorts(String cropId, List<Sowing> sowings);
```

- Mismo orden que hoy: por **día** (`_dayOf`), **siembra antes que resiembra**,
  y a igualdad de día y tipo **por `id`** (determinismo; el orden de la lista
  guardada no puede cambiar el resultado).
- Cada `siembra` **abre** cohorte con sus matas y su área.
- Si `replaces_plants > 0`, resta a la cohorte apuntada y, si las dos áreas se
  conocen, resta `replaces_area_ha` con piso en 0.
- Cada `resiembra` ajusta **su** cohorte: `vivas − muertas + nuevas`, con piso
  en 0 y **sin revivir** una cohorte ya en 0.
- **Cohorte cerrada no se revive** ni recibe restas posteriores.

**Resolución del puntero — punto que el plan fija explícitamente.** El
pseudocódigo del PRD (§Cálculo) escribe un `??` de respaldo para la resta, pero
D3, el test 7 del plan de pruebas, el caso borde «`replaces_plants > 0` sin
puntero válido → no resta» y la sección de respaldo piden lo contrario. Manda
**D3**: la resta exige un puntero que resuelva.

| Caso | Qué hace el motor |
|---|---|
| `cohort_sowing_id` presente y **resuelve** a una cohorte del cultivo con fecha ≤ la de la siembra | resta a esa |
| `cohort_sowing_id` presente y **no** resuelve (borrada, de otro cultivo, o con fecha posterior) | **no resta**; la fila se lista «sin lote» |
| `cohort_sowing_id == null` con `replaces_plants > 0` | **no resta**; «sin lote» (no hay sustituto por parecido) |
| `cohort_sowing_id == null` en una **resiembra** | cae por fecha en la **más reciente con fecha ≤ la suya** (semántica anterior, D9) |
| puntero de resiembra a una cohorte en 0 | se ignora; la fila se lista «sin lote» |

Con el puntero explícito, ningún cálculo depende del orden de la lista salvo el
desempate por `id`, que es fijo.

### 5.3 `recomputeCropState` y área (D5, D6)

Se mantiene la firma pública y se implementa **sobre `cropCohorts`** (una sola
fuente de verdad):

```dart
Map<String, ({int livePlants, double? areaHa})> recomputeCropState(List<Sowing> sowings);

// Agregados derivados para la UI y las edades
List<Cohort> openCohorts(String cropId, List<Sowing> sowings);
int nEdades(String cropId, List<Sowing> sowings);            // cohortes con vivas > 0
({double? measuredSum, bool incomplete, bool overManual})
    cohortAreaStatus(Crop crop, List<Cohort> cohorts);
```

- `livePlants` = **suma de las cohortes con vivas > 0** (las de 0 aportan 0, pero
  si **todas** están en 0 el resultado es `0`, que es un hecho y no un dato
  faltante).
- `areaHa`: todas las cohortes vivas con área → **suma redondeada a 2
  decimales**; falta el área de alguna → **`null`** (el provider conserva el
  valor manual del cultivo, `…transaction_provider.dart:762`); sin cohortes
  vivas → `null` (no se toca).
- Sin siembras, el cultivo no entra al mapa (comportamiento de hoy).

### 5.4 Edad (D7) y fecha de las pérdidas (D8)

```dart
// lib/models/crop.dart
int? edadDeCohorte(Crop crop, Cohort cohort, {DateTime? hoy});
List<int?> edadesDeCohorte(Crop crop, List<Cohort> cohorts, {DateTime? hoy});
int? edadDeCrop(Crop crop, List<Sowing> sowings, {DateTime? hoy});  // envoltorio

// lib/models/sowing.dart
DateTime lossEarliestDate(List<Sowing> sowings, String cropId,
    {String? cohortSowingId});
```

- Anual → `null`, como hoy. Fecha futura → esa cohorte no tiene edad (`null`).
- **Una** cohorte viva → `edadDeCrop` devuelve esa edad (idéntico a hoy:
  `test/crop_test.dart:94-114` sigue verde sin tocarlo).
- **Dos o más** → `edadDeCrop` devuelve `null` (no hay «una» edad: la tarjeta
  muestra «N edades»). Ningún promedio.
- Sin siembras → cae a `crop.plantedAt` (comportamiento de hoy). Con siembras y
  **ninguna** cohorte viva → `null` («sin matas vivas»).
- `lossEarliestDate` con `cohortSowingId` devuelve el **día de siembra de esa
  cohorte** (no el de la última siembra). Sin puntero, o si el puntero no
  resuelve, se mantiene el comportamiento actual (siembra más reciente) para que
  el selector nunca se rompa.

### 5.5 Normalización de datos viejos (D9)

```dart
({List<Sowing> sowings, bool changed}) normalizeLegacyCohorts(List<Sowing> sowings);
```

Por cultivo, en orden cronológico (mismo criterio que el motor):

- La **primera siembra** queda como está.
- Cada siembra **posterior** cuyos **tres** campos estén en `null` se marca como
  reemplazo de lo que quedaba vivo en ese instante:
  - `replaces_plants` = **total de matas vivas** de las cohortes abiertas en ese
    momento;
  - `cohort_sowing_id` = la **más antigua de esas cohortes con vivas > 0**;
  - `replaces_area_ha` = área de la cohorte apuntada **si se conoce** (`null` si
    no);
  - `pendingSync: true` para que suba.
- Si **no hay nada vivo** en ese instante (o no hay cohortes), queda
  `replaces_plants = 0` con puntero `null`: es la verdad («no reemplacé nada») y
  evita que la fila se vuelva a procesar en cada apertura.
- **Idempotencia sin bandera**: se considera «vieja» solo la siembra posterior a
  la primera cuyos tres campos están en `null`. Al corregir (aunque sea a `0`),
  la fila deja de tocarse (SC-5).
- Las **resiembras** no se normalizan: sin puntero se resuelven por fecha.
- Preserva los números **exactamente** cuando al momento de esa siembra había
  **una sola** cohorte viva (el caso normal, y el del fixture de SC-4). Con
  **varias** cohortes vivas no hay forma de expresar «borrá todo» con un solo
  puntero: se apunta a la más antigua y se reemplaza el total de vivas (esa queda
  en 0), las demás sobreviven y el total sube. Es la corrección documentada en
  el PRD (§Riesgos); se declara en el informe (T20) y queda un test que lo fija.

### 5.6 Puerta única de entrada (`Sowing.fromJson`)

| Regla | Efecto |
|---|---|
| `replaces_plants` o `replaces_area_ha` **negativos** | `null` + `pendingSync: true` |
| `replaces_area_ha` **sin** `replaces_plants` | `replaces_area_ha = null` + `pendingSync: true` (un área sin matas no significa nada) |
| `kind == resiembra` | `replaces_plants` y `replaces_area_ha` a `null` + `pendingSync: true`; **el puntero se conserva** |
| `kind == siembra` con `cohort_sowing_id == null` y `replaces_plants > 0` | se **conserva** tal cual (el puntero puede faltar por un borrado remoto); no se resta y la lista lo marca «sin lote». Sin `pendingSync` (no hay nada que corregir) |
| claves ausentes (cliente o respaldo viejo) | entran `null`, sin marcar sucio |

`Sowing.toJson` gana las tres claves (`replaces_plants`, `replaces_area_ha`,
`cohort_sowing_id`); el respaldo las hereda sin código nuevo.

### 5.7 Decisiones de implementación que este plan fija

No reabren ninguna decisión del PRD; resuelven huecos que el ejecutor
encontraría:

1. **La resta exige puntero** (manda D3 sobre el `??` del pseudocódigo). Ver 5.2.
2. **Una siembra nueva en un cultivo con cohortes vivas nunca se guarda con los
   tres campos en `null`**: si no hay puntero no hay resta, y la normalización
   (que solo toca las filas con los tres campos en `null`) la convertiría en una
   **renovación total** en la apertura siguiente. Por eso el formulario
   arranca con **«Amplío el cultivo» seleccionado** (respuesta explícita,
   `replaces_plants = 0`) y el usuario puede cambiarla. Con una sola validación
   dura (SC-10) y sin sorpresas al reabrir. Hay un test-guarda (T9).
3. **C6 «arranque completo» se mantiene visible cuando el cultivo tiene 0 o 1
   cohorte viva** y, al marcarlo, fuerza «Renuevo» + «Todas (N)» sobre esa
   cohorte, conservando el significado de hoy (edad 0, fase y primera cosecha
   reiniciadas). Con **2 o más** cohortes vivas la casilla se oculta: una fila
   solo puede reemplazar una cohorte, y el camino honesto es «Renuevo» por lote
   (documentado en T14 y en el informe).
4. **`closedOn`** se anota solo cuando la cohorte llega a 0 por una **siembra**
   que la reemplaza. Si llegó a 0 por pérdidas (resiembra), se muestra
   «Renovada» sin fecha: no se inventa.
5. El aviso de área (D6) se pinta en la tarjeta del cultivo (T16), con
   `cohortsAreaFallback` cuando falta un área y `cohortsAreaMismatch` cuando la
   suma medida ya supera la manual.

## 6. Fases y tareas

### Fase 0 — Baseline

#### T1 — Baseline del gate y de los números

- **Objetivo:** fotografía del punto de partida.
- **Archivos:** ninguno (solo `docs/reports/2026-10-21_cohortes-estructura.md`,
  creado vacío con el encabezado y el baseline).
- **Cambios:**
  - `C:\flutter\bin\flutter.bat analyze` → debe salir limpio.
  - `C:\flutter\bin\flutter.bat test *> docs\reports\gate-t1.txt` y anotar el
    total (esperado **1120/1120** en `84ff1e1`). Limpiar ANSI al leerlo:
    `(Get-Content docs\reports\gate-t1.txt) -replace "\e\[[0-9;]*m","" | Select-String "All tests passed|Some tests failed|[0-9]+ \+"`.
  - Anotar en el informe los números a congelar de un cultivo fixture
    (1.000 matas / 5 ha, una siembra 2020 + resiembra): kg/ha, kg/planta,
    promedio histórico, costo por kilo, filas de PDF y de Excel (insumo de la
    guarda de T13).
- **Verificación:** los dos comandos de arriba.
- **Done:** informe con baseline, total de tests y números congelados; sin
  cambios de código.

### Fase 1 — Base de datos

#### T2 — Migración `202610210001_add_sowings_cohorts.sql` + contrato

- **Objetivo:** que las tres columnas existan en la base antes del deploy.
- **Archivos:** `supabase/migrations/202610210001_add_sowings_cohorts.sql`
  (nuevo), `test/migration_sowings_cohorts_test.dart` (nuevo).
- **Cambios:** el SQL exacto de §5.1, sin backfill y sin tocar `harvests` ni
  `transactions`.
- **Tests** (molde: `test/migration_harvested_kg_test.dart`):
  - `'el archivo existe y declara las tres columnas'` → contiene
    `replaces_plants`, `replaces_area_ha`, `cohort_sowing_id` y
    `public.sowings`.
  - `'es idempotente: cada columna y el índice usan if not exists'`.
  - `'la FK es auto-referente y con on delete set null'` → contiene
    `references public.sowings(id) on delete set null`.
  - `'no hay backfill ni cambios destructivos'` → no contiene `update `,
    `alter column`, `not null`, `drop `, `harvests`, `transactions`.
  - **Rojo antes:** no existe el archivo (rojo por ausencia).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\migration_sowings_cohorts_test.dart`.
- **Done:** test verde; **el usuario aplica la migración** en Supabase y las
  cuatro consultas de verificación de §5.1 dan lo esperado (`con_dato = 0`).
  Sin migración aplicada **no** se despliega nada.

### Fase 2 — Modelo y funciones puras

#### T3 — `Sowing`: tres campos, JSON, `copyWith` con centinela y puerta de entrada

- **Objetivo:** que el dato exista y entre limpio por un solo camino.
- **Archivos:** `lib/models/sowing.dart`; `test/sowing_test.dart` (extender);
  `test/sowing_cohorts_json_test.dart` (nuevo, opcional si `sowing_test.dart`
  queda claro).
- **Cambios:**
  - `int? replacesPlants`, `double? replacesAreaHa`, `String? cohortSowingId`
    en el constructor y en los campos.
  - `copyWith` con **centinela** (patrón de `lostPlants`/`reason`,
    `sowing.dart:33-50`) para los tres: hay que poder volver a `null`.
  - `toJson`/`fromJson` con `replaces_plants`, `replaces_area_ha`,
    `cohort_sowing_id` y las cinco reglas de §5.6, sin perder la regla `sucio`
    existente.
- **Tests:**
  - `'round-trip conserva los tres campos nuevos'` (extiende el de
    `test/sowing_test.dart:50-68`).
  - `'JSON sin las claves: los tres entran null y no marcan sucio'`.
  - `'copyWith puede volver a null los tres campos'` y
    `'no pasarlos los conserva'`.
  - `'negativos se limpian y marcan pendingSync'`.
  - `'replaces_area_ha sin replaces_plants se limpia'`.
  - `'una resiembra limpia replaces_* y conserva el puntero'`.
  - `'siembra con replaces_plants > 0 y sin puntero se conserva tal cual (sin pendiente)'`.
  - **Rojo antes:** los campos no existen (rojo por compilación).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\sowing_test.dart`.
- **Done:** rojo→verde y ningún test existente de `sowing_test.dart` roto salvo
  los que §11 manda actualizar.

#### T4 — `cropCohorts`: el motor determinista

- **Objetivo:** una sola función que diga las cohortes de un cultivo.
- **Archivos:** `lib/models/sowing.dart`; `test/sowing_cohorts_test.dart`
  (nuevo).
- **Cambios:** clase `Cohort` + `cropCohorts` según §5.2, con el orden por día,
  tipo e `id`, la tabla de resolución de puntero, el piso en 0, la no
  resurrección de cohortes cerradas y `closedOn` (§5.7.4).
- **Tests** (cada uno con su caso concreto):
  - `'una siembra abre una cohorte con sus matas y su área'`.
  - `'expansión (replaces 0): la vieja queda intacta y la nueva suma'` (SC-1).
  - `'renovación parcial 300/1 sobre 1.000/5 → vieja 700/4 y nueva 300/1'` (SC-2).
  - `'renovación total: la vieja queda en 0 y el cultivo en 300/1'` (SC-3).
  - `'reemplazo mayor a las vivas se recorta a 0'`.
  - `'el puntero manda: resta a esa cohorte y no a la más antigua'`.
  - `'puntero que no resuelve: no resta y queda «sin lote»'`.
  - `'puntero con fecha posterior: se ignora'`.
  - `'resiembra por puntero a la vieja después de una siembra nueva: 900 + 300'` (SC-6).
  - `'resiembra sin puntero cae en la cohorte más reciente del día'`.
  - `'resiembra sobre una cohorte en 0 no la revive'`.
  - `'dos siembras el mismo día: determinista y con puntero explícito'`.
  - `'área: resta con piso en 0; la vieja sin área sigue sin área'`.
  - `'nEdades cuenta solo las cohortes con vivas > 0'` (SC-8).
  - `'closedOn: la siembra que la dejó en 0; sin dato no se inventa'` (SC-8).
  - **Rojo antes:** `cropCohorts` no existe (rojo por compilación); en cuanto
    exista, el rojo real es cualquier valor distinto del esperado en los casos
    de expansión, parcial y resiembra a la vieja.
- **Verificación:** `C:\flutter\bin\flutter.bat test test\sowing_cohorts_test.dart`.
- **Done:** los 15 casos verdes; `cropCohorts` no toca `crop.livePlants` (es
  puro).

#### T5 — `recomputeCropState` sobre cohortes + regla de área (D5, D6)

- **Objetivo:** que el total del cultivo salga de las cohortes.
- **Archivos:** `lib/models/sowing.dart`; `test/sowing_cohorts_test.dart`
  (extender); `test/sowing_test.dart` (actualizar, §11).
- **Cambios:** reimplementar `recomputeCropState` sobre `cropCohorts` según §5.3
  (misma firma pública) + `openCohorts`, `nEdades`, `cohortAreaStatus` y el
  redondeo a 2 decimales de la suma de áreas.
- **Tests:**
  - `'una siembra posterior con replaces_plants = 0 no borra la vieja: 1.300 / 5,5'`
    (**rojo real**: hoy devuelve 300/1) (SC-1).
  - `'renovación parcial: 700/4 + 300/1 = 1.000/5'` (**rojo real**) (SC-2).
  - `'renovación total deja el cultivo en 300/1'` (guarda: hoy también da 300/1).
  - `'todas las cohortes en 0: livePlants = 0, no «sin datos»'`.
  - `'área: todas conocidas → suma redondeada a 2 decimales'` (SC-9).
  - `'área: una cohorte sin área → areaHa null (el cultivo conserva la manual)'`
    (D6, SC-9).
  - `'sin cohortes vivas no se toca el área'`.
  - `'sin siembras el cultivo no entra al mapa'` (guarda: hoy igual).
- **Verificación:** `C:\flutter\bin\flutter.bat test test\sowing_cohorts_test.dart test\sowing_test.dart`.
- **Done:** verdes; `test/sowing_test.dart:117-125` reescrito según §11 con su
  nota de por qué cambió.

#### T6 — Edad por cohorte y fecha de las pérdidas (D7, D8)

- **Objetivo:** «N edades» sin promedios y pérdidas fechadas desde el lote.
- **Archivos:** `lib/models/crop.dart`, `lib/models/sowing.dart`;
  `test/crop_test.dart` (extender), `test/sowing_cohorts_test.dart` (extender).
- **Cambios:** `edadDeCohorte`, `edadesDeCohorte`, `edadDeCrop` como envoltorio
  (§5.4) y `lossEarliestDate` con `cohortSowingId` opcional.
- **Tests:**
  - `'una cohorte viva: la edad es la de siempre'` (guarda:
    `test/crop_test.dart:94-114` **no se toca** y sigue verde).
  - `'dos cohortes vivas: edadDeCrop es null (hay «N edades»)'` (**rojo real**:
    hoy devuelve la edad de la última siembra).
  - `'la edad sale de la siembra que abrió la cohorte; la resiembra no la reinicia'`.
  - `'cohorte con fecha futura: edad null'`.
  - `'cultivo anual: edad null'` (guarda).
  - `'todas las cohortes en 0 con siembras: edad null'`.
  - `'lossEarliestDate con cohorte usa el 2020 y no el 2026'` (**rojo real**:
    hoy devuelve 2026) (SC-6).
  - `'lossEarliestDate sin cohorte: comportamiento de hoy'` (guarda).
- **Verificación:** `C:\flutter\bin\flutter.bat test test\crop_test.dart test\sowing_cohorts_test.dart`.
- **Done:** verdes; ningún llamador de `edadDeCrop` cambia de firma.

#### T7 — `normalizeLegacyCohorts` (D9)

- **Objetivo:** que los datos viejos no muevan un número.
- **Archivos:** `lib/models/sowing.dart`;
  `test/sowing_legacy_normalization_test.dart` (nuevo).
- **Cambios:** la función pura de §5.5 (sin tocar disco; el provider la usa).
- **Tests** (`test/sowing_legacy_normalization_test.dart`):
  - `'S1 1.000/5 + S2 300/1 → S2 reemplaza 1.000/5 y el total queda 300/1'`
    (**rojo real** con el cálculo nuevo sin normalizar: daría 1.300/6) (SC-4).
  - `'S1 + resiembra + S2 → total igual al de hoy'`.
  - `'tres siembras: cadena S1→S2→S3 con total igual'`.
  - `'ya normalizada no se vuelve a tocar'` (SC-5).
  - `'corrección a 0 se respeta en la pasada siguiente'` (SC-5).
  - `'resiembra vieja sin puntero no se normaliza y resuelve por fecha'`.
  - `'sin nada vivo en ese instante queda replaces_plants = 0 y no vuelve a procesarse'`.
  - `'es idempotente: dos pasadas devuelven lo mismo'`.
  - `'varias cohortes vivas: apunta a la más antigua, reemplaza el total y el resto sobrevive (caso documentado)'` (el riesgo declarado del PRD).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\sowing_legacy_normalization_test.dart`.
- **Done:** los nueve casos verdes y el caso «varias cohortes vivas» anotado en
  el informe como corrección declarada.

#### T8 — Validadores y precarga del reemplazo (SC-10, UX 1)

- **Objetivo:** que el formulario tenga una regla clara y probable.
- **Archivos:** `lib/models/sowing.dart`;
  `test/sowing_replacement_input_test.dart` (nuevo).
- **Cambios:**
  ```dart
  enum ReplacementError { none, empty, notPositive, tooMany, noTarget }

  ReplacementError validateReplacement({
    required bool renew, int? replacesPlants, Cohort? target,
  });

  int? replacementPrefill(Cohort target, double? newAreaHa); // round(vivas × áreaNueva / áreaVieja)
  int maxReplacement(Cohort target);                          // vivas, para «Todas (N)»
  ```
  - `renew == false` → `none` (expansión).
  - `renew == true` y sin cohorte destino → `noTarget`.
  - vacío → `empty`; `<= 0` → `notPositive`; `> vivas` → `tooMany`.
  - Precarga solo si **las dos** áreas existen y la vieja es > 0; si no, `null`.
- **Tests:**
  - `'precarga por área: 1.000 matas en 5 ha y 1 ha nueva → 200'`.
  - `'sin área en la vieja no hay precarga'` y `'área nueva vacía tampoco'`.
  - `'vacío, 0, negativo, mayor a las vivas y sin lote'` (5 casos).
  - `'«Todas (N)» es exactamente las vivas'`.
  - **Rojo antes:** las funciones no existen.
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\sowing_replacement_input_test.dart`.
- **Done:** verdes; ninguna función devuelve texto de UI (los mensajes los pone
  el widget con l10n).

### Fase 3 — Provider

#### T9 — Escrituras con cohortes y punteros

- **Objetivo:** que guardar, editar y borrar dejen el estado coherente.
- **Archivos:** `lib/providers/transaction_provider.dart`;
  `test/transaction_provider_sowing_test.dart` (nuevo).
- **Cambios:**
  - `addSowing` gana `int? replacesPlants`, `double? replacesAreaHa`,
    `String? cohortSowingId` (se pasan al `Sowing`, con `pendingSync: true`).
  - `updateSowing` no cambia de firma (recibe el `Sowing` completo).
  - `deleteSowing`: antes de quitarla, limpia el puntero de las siembras que le
    apuntaban (`cohortSowingId: null`, `pendingSync: true`) — hoy solo desvincula
    `transactions.sowingId` (`:738-744`), eso **se mantiene**.
  - `_recomputeCropsFromSowings` sigue igual en forma; el cambio de área entra
    por `recomputeCropState` (T5): `u.areaHa ?? c.areaHa` conserva la manual.
- **Tests** (`test/transaction_provider_sowing_test.dart`):
  - `'addSowing con reemplazo deja las cohortes y los totales correctos'` (SC-2).
  - `'updateSowing que baja replacesPlants a 0 devuelve las matas a la vieja'` (SC-5).
  - `'updateSowing que sube por encima de las vivas no se guarda'` (la validación
    es del formulario; aquí se prueba que el guardado normalizado no deja
    negativos).
  - `'deleteSowing de la vieja deja el puntero en null y pendingSync en las afectadas'`.
  - `'deleteSowing de la nueva devuelve matas y área a la vieja'`.
  - `'deleteSowing de la nueva no toca el puntero de las demás'`.
  - `'toda escritura deja pendingSync en siembras y cultivos'` (guarda).
  - `'área con una cohorte sin área conserva la manual y no la pisa'` (SC-9).
  - `'una siembra nueva en un cultivo con cohortes nunca queda con los tres campos en null'`
    (**guarda del plan**, §5.7.2).
- **Rojo antes:** `addSowing` no acepta los parámetros (rojo por compilación);
  el caso del borrado de la vieja da totales distintos hoy.
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\transaction_provider_sowing_test.dart`.
- **Done:** verdes; `test/transaction_provider_test.dart` sigue verde (usa
  `addSowing` sin los campos nuevos: `null` es válido).

#### T10 — Normalización al abrir, área y recálculo tras el pull

- **Objetivo:** que los datos viejos se arreglen solos, una vez, y que el pull
  recalcule.
- **Archivos:** `lib/providers/transaction_provider.dart`;
  `test/transaction_provider_sowing_test.dart` (extender).
- **Cambios:**
  - En el constructor (después de `_sowings = _store.loadSowings()`, `:48`) y en
    `reloadFromCache` (`:71`): correr `normalizeLegacyCohorts`; si `changed`,
    guardar con `unawaited(_store.saveSowings(_sowings))` y llamar
    `_recomputeCropsFromSowings()` con el mismo patrón `unawaited` que usa
    `_seedCashHistory` (`:914-925`). Idempotente: a la segunda apertura no
    cambia nada.
  - Al terminar `importBackup` (antes de `reconcilePhaseFromHarvests`,
    `:1086-1088`): normalizar lo importado y recalcular cultivos.
  - El pull ya recalcula al final por los `mergeRemote*`; verificar que
    `mergeRemoteSowings` (`:1282+`) recalcula el estado del cultivo afectado y
    **no** anula un `cohort_sowing_id` que todavía no llegó.
- **Tests:**
  - `'al abrir un cultivo viejo con dos siembras los números quedan exactamente iguales'`
    (SC-4) — con `pendingSync` en las siembras normalizadas.
  - `'normaliza una sola vez (segunda apertura no cambia nada)'` (SC-5).
  - `'un puntero que llega antes que su cohorte se conserva y no se anula'` (SC-11).
  - `'tras el pull los cultivos afectados quedan recalculados'`.
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\transaction_provider_sowing_test.dart`.
- **Done:** verdes; `docs/reports` con la nota de que la normalización es la
  única subida masiva de `pendingSync` y ocurre una vez por fila.

### Fase 4 — Sync, respaldo y guardas

#### T11 — Payload, lectura remota y orden de push

- **Objetivo:** que las tres claves viajen siempre, incluido `null`.
- **Archivos:** `lib/providers/sync_provider.dart`;
  `test/sync_sowing_cohorts_test.dart` (nuevo).
- **Cambios:**
  - `buildSowingPayload` (`:450-461`) agrega:
    ```dart
    'replaces_plants': s.replacesPlants,
    'replaces_area_ha': s.replacesAreaHa,
    'cohort_sowing_id': _uuidOrNull(s.cohortSowingId),
    ```
    **Siempre**, aunque sean `null`: omitir una columna que existe en la BD
    responde PGRST204 y tumba la subida (`:482-489` documenta el mismo caso).
  - `_remoteToSowing` (`:725-737`) lee las tres claves.
  - Nota en el orden de push: el destino de la FK es una siembra **anterior**;
    si todavía no subió, el push falla y la fila queda `pendingSync` (los stages
    son por fila, `:214-220`, `:250-269`): se reintenta y no se pierde.
- **Tests** (`test/sync_sowing_cohorts_test.dart`):
  - `'el payload trae las tres claves aunque sean null'` (**rojo real**: hoy no
    las trae) (SC-11).
  - `'el payload trae los valores cuando existen'` (SC-11).
  - `'round-trip JSON con y sin los tres campos'` (SC-11).
  - `'un cohort_sowing_id que no es uuid sube como null'` (guarda, patrón
    `_uuidOrNull`).
  - `'el push de sowings sigue antes que harvests y transactions'` (guarda).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\sync_sowing_cohorts_test.dart`.
- **Done:** verdes; `test/sync_push_test.dart` sigue verde.

#### T12 — Respaldo y huérfanos del puntero

- **Objetivo:** que exportar/importar conserve los tres campos y cuente los
  punteros que no resuelven.
- **Archivos:** `lib/providers/transaction_provider.dart`,
  `lib/services/backup_service.dart` (solo si hace falta);
  `test/backup_cohorts_test.dart` (nuevo).
- **Cambios:**
  - El respaldo ya usa `Sowing.toJson`/`fromJson` (`backup_service.dart:199,
    245`): **no hay código nuevo** para los campos; se verifica con tests.
  - En el bloque de huérfanos (`:1068-1084`): sumar
    `if (s.cohortSowingId != null && !sowingIds.contains(s.cohortSowingId)) huerfanos++`.
  - Un puntero huérfano **no** se convierte en reemplazo de otra cohorte: se
    importa igual, cuenta como huérfano y se trata como «sin lote».
- **Tests** (`test/backup_cohorts_test.dart`):
  - `'exportar e importar conserva los tres valores'` (**rojo real** hasta que
    `toJson` los incluya).
  - `'respaldo viejo (sin las claves) entra null y no mueve números'` (SC-4).
  - `'el conteo de huérfanos incluye un puntero a una siembra ausente'`.
  - `'un puntero huérfano no se reasigna a otra cohorte'`.
  - `'replaces_plants > 0 sin puntero válido no resta y se lista «sin lote»'`.
- **Verificación:** `C:\flutter\bin\flutter.bat test test\backup_cohorts_test.dart`.
- **Done:** verdes; `test/backup_import_test.dart` y `test/settings_backup_test.dart`
  siguen verdes.

#### T13 — Guardas: paridad de una cohorte y cosechas intactas

- **Objetivo:** congelar lo que **no** puede cambiar (SC-13, SC-14).
- **Archivos:** `test/single_cohort_parity_test.dart` (nuevo),
  `test/harvests_intactos_test.dart` (nuevo).
- **Cambios:** solo tests. El fixture es un cultivo con **una** siembra
  (1.000 matas / 5 ha, 2020) + una resiembra, más ventas y gastos.
- **Tests:**
  - `single_cohort_parity_test.dart` con expectations **congeladas** (los
    números anotados en T1): kg/ha, kg/planta, promedio histórico, costo por
    kilo, filas y totales del PDF y del Excel, y `edadDeCrop` = 6. **Declarada
    guarda**: verde antes y después (no hay rojo posible); su valor es que el
    día que alguien rompa la paridad, avisa.
  - `harvests_intactos_test.dart`: `Harvest` no gana campos y su JSON no cambia
    de claves; la migración de la etapa no menciona `harvests` (SC-14).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\single_cohort_parity_test.dart test\harvests_intactos_test.dart`.
- **Done:** verdes en verde; anotado en el informe que son guardas.

### Fase 5 — Formulario de siembra

#### T14 — «Amplío / Renuevo» en el formulario de siembra

- **Objetivo:** que anotar una siembra no borre el lote viejo ni infle el total.
- **Archivos:** `lib/screens/sowing_screen.dart`; `lib/l10n/app_es.arb`,
  `lib/l10n/app_en.arb` + `gen-l10n` (claves de §7);
  `test/sowing_screen_cohorts_test.dart` (nuevo).
- **Cambios:**
  - Sección nueva, visible **solo** cuando `kind == siembra` y el cultivo tiene
    al menos una cohorte viva (excluyendo la siembra que se está editando; con
    ninguna cohorte, el formulario queda **exactamente** como hoy).
  - Radios desde `sowingWhatHappensOldPlants`: **«Amplío el cultivo»**
    (por defecto, §5.7.2) y **«Renuevo una parte»**; al elegir Renuevo se
    despliegan:
    - **Lote que renuevo**: selector si hay **más de una** cohorte viva; con una,
      texto (`sowingCohortOption`).
    - **Matas que reemplaza**: obligatorio y > 0 (`sowingReplacePlantsLabel`),
      con la precarga (`sowingReplacePlantsPrefill` / `sowingReplaceNoArea`) y el
      atajo **«Todas (N)»**.
    - **Área que reemplaza (ha)**: opcional; precargada con el área nueva si la
      vieja la tiene.
  - Guardado: `Amplío` → `replacesPlants = 0`, `cohortSowingId = null`; `Renuevo`
    → los tres campos con el lote elegido. **Nunca** los tres en `null` (§5.7.2).
  - Única validación dura: `Renuevo` sin matas → no guarda
    (`sowingReplacePlantsRequired`); `> vivas` → bloquea con
    `sowingReplaceTooMany(live)` y ofrece «Todas (N)» (SC-10).
  - Edición: mismos campos precargados; cambiar a «Amplío» guarda **0**
    explícito (nunca `null`).
  - **C6** (§5.7.3): la casilla de arranque completo se mantiene con 0 o 1
    cohorte viva y, al marcarla, fuerza Renuevo + «Todas (N)» sobre esa cohorte;
    con 2 o más cohortes vivas se oculta.
  - El aviso de resiembra sin muertas (T12 de la tanda 4) no cambia.
- **Tests** (`test/sowing_screen_cohorts_test.dart`, harness de
  `test/sowing_screen_test.dart` con `agrandar`):
  - `'un cultivo sin cohortes muestra el formulario de siempre'` (guarda:
    mismo número de campos) (SC-13).
  - `'un cultivo con cohortes muestra la pregunta'` (**rojo real**: hoy no
    existe).
  - `'«Amplío» guarda 0 explícito (never null)'` (SC-1 y guarda §5.7.2).
  - `'«Renuevo» sin matas no guarda; con matas guarda el valor'` (SC-10).
  - `'escribir más matas de las que hay bloquea y ofrece «Todas (N)»'` (SC-10).
  - `'la precarga por área se ve con las dos áreas y falta sin área vieja'`.
  - `'editar una siembra vieja y pasar a «Amplío» guarda 0'` (SC-5).
  - `'marcar el arranque completo guarda las vivas de la cohorte'` (mantiene
    `test/c6_arranque_test.dart:133-156` verde).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\sowing_screen_cohorts_test.dart test\sowing_screen_test.dart test\c6_arranque_test.dart`.
- **Done:** verdes; claves nuevas en los dos ARB y `gen-l10n` corrido.

#### T15 — Resiembra por lote y pérdidas con la fecha del lote

- **Objetivo:** reponer matas en la cohorte elegida, con la fecha correcta.
- **Archivos:** `lib/screens/sowing_screen.dart`; `lib/widgets/crop_loss_dialog.dart`;
  ARB + `gen-l10n`; `test/sowing_screen_cohorts_test.dart` (extender),
  `test/crop_loss_dialog_test.dart` (extender).
- **Cambios:**
  - Con **una** cohorte viva: texto «Lote del 12/03/2020 · 6 años · 1.000 matas»
    (`sowingCohortOption`) y el puntero se asigna solo.
  - Con **varias**: selector **«Lote»** (`sowingCohortLabel`) con la **más
    antigua viva** por defecto; la elección se recuerda mientras el formulario
    está abierto.
  - Sin cohortes vivas: aviso (`sowingCohortNoneTitle` / `sowingCohortNoneBody`)
    + botón **«Anotar como siembra»** (`sowingCohortNoneSaveAs`); la resiembra no
    cambia las matas del cultivo (D8).
  - El selector de fecha de la pérdida usa `lossEarliestDate(..., cohortSowingId:
    elegido)`: al cambiar de lote, el mínimo se mueve y una pérdida anterior se
    marca y se corrige **antes** de guardar (aviso, no bloqueo).
  - `crop_loss_dialog.dart` reutiliza el mismo selector de lote y pasa
    `cohortSowingId` a `addSowing`.
  - La lista de siembras marca **«sin lote»** (`sowingNoCohortTag`) cuando una
    siembra tiene `replacesPlants > 0` y el puntero no resuelve.
  - Borrar una siembra que otras apuntan: el diálogo existente
    (`sowing_screen.dart:152-178`) suma un cuerpo con el antes/después de matas
    (`sowingDeleteCohortBody`), porque los totales cambian.
- **Tests:**
  - `'resiembra con una cohorte: texto y sin selector'`.
  - `'resiembra con dos cohortes: selector con la más antigua por defecto'` (SC-6).
  - `'la pérdida arranca en el día de siembra de la cohorte elegida'` (SC-6,
    rojo real: hoy arranca en la última siembra).
  - `'sin cohortes vivas avisa y ofrece anotar como siembra'`.
  - `'borrar la cohorte vieja avisa que los totales cambian'`.
  - `'una siembra con puntero roto se lista «sin lote»'`.
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\sowing_screen_cohorts_test.dart test\crop_loss_dialog_test.dart`.
- **Done:** verdes; `test/recordatorio_lote_test.dart` sin cambios.

### Fase 6 — Cultivo y edad en pantalla

#### T16 — Tarjeta del cultivo: «N edades», desglose y «Lotes renovados»

- **Objetivo:** ver las edades sin promediar y la historia del lote renovado.
- **Archivos:** `lib/screens/crops_screen.dart`; ARB + `gen-l10n`;
  `test/crops_screen_cohorts_test.dart` (nuevo).
- **Cambios:**
  - Con **una** cohorte viva: la tarjeta se ve **exactamente** como hoy
    (`edadDeCrop` sigue devolviendo esa edad; `crops_screen.dart:501-511`).
  - Con **dos o más**: el lugar de la edad muestra un chip **«2 edades»**
    (`cohortsCount`); al tocarlo se despliega la lista, una fila por cohorte:
    `12/03/2020 · 6 años · 700 matas · 4,0 ha` con estado **Abierta**
    (`cohortOpen`) o **Renovada** (`cohortRenewed`). Fechas con
    `MaterialLocalizations.formatShortDate`, áreas con `formatAreaHa`.
  - Sección **«Lotes renovados»** (`cohortsHistoryTitle`), colapsada al final,
    con las cohortes en 0: `12/03/2020 · renovada en 05/2026`
    (`cohortRenewedOn`); si no se puede determinar la fecha, dice «Renovada»
    sin fecha.
  - Aviso de área (D6, §5.7.5): cuando falta el área de alguna cohorte viva,
    `cohortsAreaFallback`; cuando la suma de las medidas supera la manual,
    `cohortsAreaMismatch(sum, manual)`. Sin bloquear.
  - Todas las cohortes en 0 → «sin matas vivas» (no se oculta el hecho).
- **Tests** (`test/crops_screen_cohorts_test.dart`):
  - `'una cohorte: la tarjeta es la de siempre'` (guarda; incluye el número de
    widgets para que no aparezca nada nuevo) (SC-13).
  - `'dos cohortes: dice «2 edades» y no una edad'` (**rojo real**) (SC-7).
  - `'el desglose lista cada lote con su edad, matas y área'` (SC-7).
  - `'una cohorte en 0 aparece en «Lotes renovados» y no en los totales'` (SC-3, SC-8).
  - `'nEdades no cuenta las renovadas'` (SC-8).
  - `'avisa cuando falta el área de un lote, sin bloquear'` (SC-9).
  - `'avisa cuando las áreas de los lotes ya superan la del cultivo'` (SC-9).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\crops_screen_cohorts_test.dart test\crops_screen_test.dart`.
- **Done:** verdes; `test/crops_screen_test.dart` sin cambios (una sola siembra
  en todos sus casos).

#### T17 — Ayuda: qué es renovar una parte

- **Objetivo:** explicarlo sin la palabra «cohorte».
- **Archivos:** `lib/screens/help_screen.dart`; ARB + `gen-l10n`.
- **Cambios:** bloque nuevo (o párrafo dentro del bloque de renovación) con
  `helpCohortsRenewTitle` y `helpCohortsRenew`, junto a `helpCaseC*`
  (`help_screen.dart:164-170`); texto de §7, en «lote» y «matas».
- **Tests:** `'las claves de ayuda existen en los dos ARB'` (guarda; se
  consolida en T18).
- **Verificación:** `C:\flutter\bin\flutter.bat analyze`.
- **Done:** el párrafo se ve en Ayuda; nada promete kilos por lote.

### Fase 7 — Copy

#### T18 — Copy ES/EN consolidado, `gen-l10n` y guardas de idioma

- **Objetivo:** que ninguna clave quede a medias y que el copy diga «lote».
- **Archivos:** `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`,
  `lib/l10n/generated/*` (commiteado), `test/l10n_cohortes_test.dart` (nuevo).
- **Cambios:**
  - Verificar que **todas** las claves de §7 estén en los dos ARB con los mismos
    `placeholders` (las que agregaron T14–T17 ya están; acá se auditan y se
    completan las que falten).
  - Cada clave con argumentos lleva su bloque `@clave` con `placeholders`
    **declarados en el orden en que se leen**, porque
    `test/l10n_placeholder_order_test.dart` compara ARB contra la firma generada.
  - `C:\flutter\bin\flutter.bat gen-l10n`.
- **Tests** (`test/l10n_cohortes_test.dart`, molde de `test/l10n_tanda4_test.dart`):
  - `'las claves de cohortes están en los dos ARB'` (SC-15).
  - `'los placeholders coinciden en nombre y cantidad entre ES y EN'` (SC-15).
  - `'el copy visible no usa «cohorte» ni «cohort»'` (SC-15) — recorre los
    **valores** de las claves nuevas y falla si aparece la palabra.
  - `'ninguna clave nueva promete kilos por lote'` (guarda: no aparece «kg» en
    los textos nuevos; el diseño no cambió).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\l10n_cohortes_test.dart test\l10n_placeholder_order_test.dart test\l10n_tanda4_test.dart`.
- **Done:** verdes; `lib/l10n/generated/` commiteado con LF (revisar
  `git show --stat` para descartar una reescritura masiva por CRLF).

### Fase 8 — Reportes

#### T19 — Rótulo «promedio de N edades»

- **Objetivo:** decir que el kg/planta del cultivo mezcla edades, sin cambiar la
  fórmula.
- **Archivos:** `lib/widgets/per_hectare_panel.dart`,
  `lib/screens/report_screen.dart`; ARB + `gen-l10n`;
  `test/per_hectare_panel_ages_test.dart` (nuevo).
- **Cambios:**
  - `PerHectarePanel` gana `final List<Sowing> sowings` (por defecto `const []`,
    para no romper llamadas ni tests).
  - `report_screen.dart:476-485` pasa `sowings: tx.sowings`.
  - Junto a `yieldPerPlant` (`per_hectare_panel.dart:217-222`), cuando el
    cultivo tiene **2 o más** cohortes vivas, se agrega el rótulo
    `perHaAgesAverage(count)` en tono apagado (es una aclaración, no un
    veredicto).
  - La fila sigue siendo **por cultivo**; no aparece kg/planta por lote.
  - El mismo rótulo sirve al PDF/Excel sin tocar el diseño (heredan el panel
    cuando corresponda); si el exporte no lo imprime, **no** se agrega nada (fuera
    de alcance).
- **Tests** (`test/per_hectare_panel_ages_test.dart`):
  - `'con dos edades agrega «promedio de 2 edades»'` (**rojo real**).
  - `'con una sola edad no agrega nada'` (guarda; `test/per_hectare_panel_test.dart`
    sigue verde con la lista por defecto vacía).
  - `'el número de kg/planta no cambia de fórmula'` (guarda: mismo valor con una
    y con dos cohortes vivas).
- **Verificación:**
  `C:\flutter\bin\flutter.bat test test\per_hectare_panel_ages_test.dart test\per_hectare_panel_test.dart`.
- **Done:** verdes; ninguna columna nueva en los exportes.

### Fase 9 — Cierre

#### T20 — Gate, informe, migración aplicada y verificación manual

- **Objetivo:** entregar la etapa con evidencia.
- **Archivos:** `docs/reports/2026-10-21_cohortes-estructura.md`.
- **Cambios / pasos:**
  1. `C:\flutter\bin\flutter.bat analyze` limpio (proyecto entero, `tool/`
     incluido).
  2. `C:\flutter\bin\flutter.bat test *> docs\reports\gate-t20.txt`; anotar el
     total (1120 de `main` + los nuevos) y limpiar ANSI al leerlo.
  3. Informe con: baseline de T1, el caso de varias cohortes vivas normalizadas
     (corrección declarada), la lista de guardas (T13, T18), el antes/después de
     los números de SC-1/SC-2/SC-3 y el resultado de la verificación manual.
  4. Confirmar con el usuario que la **migración está aplicada** (consultas de
     §5.1) **antes** de desplegar.
  5. Commit explícito (stageo archivo por archivo, LF verificado), push y
     `.\deploy.ps1 -Message "…"` — **solo con verbo explícito del usuario en ese
     turno**.
  6. Verificación manual de §12 y cierre documental (sesión + `LEARNING.md`).
- **Verificación:** los dos comandos del gate + §12 completa.
- **Done:** gate verde, migración aplicada, deploy verificado, informe y
  verificación manual cerrados; diagramas (opcional) después de la
  implementación.

## 7. Copy ES/EN (claves y textos)

Claves nuevas. **`lib/l10n/app_es.arb` es el template**; ambas llevan los
mismos `placeholders`, **declarados en el orden en que se leen** (bloque
`@clave`) por `test/l10n_placeholder_order_test.dart`. Cada tarea agrega las
claves que usa y corre `gen-l10n` (el código no compila sin ellas); T18 las
audita todas juntas. Los años se arman con la clave existente `cropAge`
(`app_es.arb:264`).

| Clave | ES | EN |
|---|---|---|
| `sowingWhatHappensOldPlants` | ¿Qué pasa con las matas que ya tenés? | What happens to the plants you already have? |
| `sowingExpandOption` | Amplío el cultivo: no reemplazo nada | I'm expanding: nothing is replaced |
| `sowingRenewOption` | Renuevo una parte | I'm renewing part of it |
| `sowingRenewHint` | Las matas del lote viejo bajan y las nuevas suman. El total no se infla. | The old lot's plants go down and the new ones add up. The total doesn't inflate. |
| `sowingReplaceCohortLabel` | Lote que renuevo | Lot I'm renewing |
| `sowingReplacePlantsLabel` | Matas que reemplaza | Plants being replaced |
| `sowingReplacePlantsRequired` | Escribí cuántas matas reemplazás. | Enter how many plants you're replacing. |
| `sowingReplacePlantsPrefill` | Calculado por área: {plants} de {live} | Estimated by area: {plants} of {live} |
| `sowingReplaceNoArea` | El lote viejo no tiene área: decime cuántas matas reemplazás. | The old lot has no area: tell me how many plants you're replacing. |
| `sowingReplaceAll` | Todas ({live}) | All ({live}) |
| `sowingReplaceTooMany` | Ese lote tiene {live} matas vivas: no podés reemplazar más. | That lot has {live} living plants: you can't replace more. |
| `sowingReplaceAreaLabel` | Área que reemplaza (ha) | Area being replaced (ha) |
| `sowingCohortLabel` | Lote | Lot |
| `sowingCohortOption` | {date} · {plants} matas | {date} · {plants} plants |
| `sowingCohortNoneTitle` | No hay un lote vivo | There's no living lot |
| `sowingCohortNoneBody` | Este cultivo no tiene matas vivas donde reponer. Si estás arrancando de nuevo, anotalo como siembra. | This crop has no living plants to replant into. If you're starting over, record it as a sowing. |
| `sowingCohortNoneSaveAs` | Anotar como siembra | Record as sowing |
| `sowingNoCohortTag` | Sin lote | No lot |
| `sowingDeleteCohortBody` | Otra siembra le resta matas a este lote. Si lo borrás, esos reemplazos dejan de aplicar y el total del cultivo queda en {total} matas. | Another sowing takes plants away from this lot. If you delete it, those replacements stop applying and the crop total becomes {total} plants. |
| `cohortsCount` | {count} edades | {count} ages |
| `cohortOpen` | Abierta | Open |
| `cohortRenewed` | Renovada | Renewed |
| `cohortRenewedOn` | Renovada en {date} | Renewed on {date} |
| `cohortsHistoryTitle` | Lotes renovados | Renewed lots |
| `cohortsAreaFallback` | No todos los lotes tienen área: el área del cultivo es la que escribiste. | Not every lot has an area: the crop area is the one you entered. |
| `cohortsAreaMismatch` | Los lotes con área suman {sum} ha; el cultivo dice {manual} ha. | The lots with an area add up to {sum} ha; the crop says {manual} ha. |
| `cohortsNoLivingPlants` | Este cultivo no tiene matas vivas. | This crop has no living plants. |
| `helpCohortsRenewTitle` | Renovar una parte del lote | Renewing part of a lot |
| `helpCohortsRenew` | Renovar una parte resta esas matas del lote viejo y abre uno nuevo con su propia edad. La historia del viejo no se borra. | Renewing part of a lot subtracts those plants from the old lot and opens a new one with its own age. The old history isn't erased. |
| `perHaAgesAverage` | promedio de {count} edades | average of {count} ages |

Reglas de copy: **«lote»**, nunca «cohorte»; **«matas»** en los textos de café;
nunca «0» para un dato ausente.

`placeholders` a declarar: `sowingReplacePlantsPrefill` (`plants`, `live`),
`sowingReplaceAll`, `sowingReplaceTooMany` (`live`), `sowingCohortOption`
(`date`, `plants`), `sowingDeleteCohortBody` (`total`), `cohortsCount` (`count`),
`cohortRenewedOn` (`date`), `cohortsAreaMismatch` (`sum`, `manual`),
`perHaAgesAverage` (`count`). Los `sum`/`manual`/`plants`/`live`/`total`/`count`
van como `int` o `String` según lo que pase el widget (declararlo en el ARB).

## 8. SC → tarea y test

| SC | Tarea | Test / evidencia |
|---|---|---|
| SC-1 Expansión | T4, T5, T14 | `sowing_cohorts_test`: 'expansión (0)…'; `'una siembra posterior con replaces_plants = 0 no borra la vieja'`; widget `'«Amplío» guarda 0 explícito'` |
| SC-2 Renovación parcial | T4, T5, T9 | `'renovación parcial 300/1 sobre 1.000/5 → 700/4 + 300/1'`; `addSowing` con reemplazo |
| SC-3 Renovación total | T4, T5, T16 | `'renovación total: la vieja queda en 0'`; widget `'una cohorte en 0 → «Lotes renovados»'` |
| SC-4 Datos viejos quietos | T7, T10, T12 | `sowing_legacy_normalization_test`: 'S1 1.000/5 + S2 300/1…'; provider `'al abrir… quedan exactamente iguales'` |
| SC-5 La corrección manda | T7, T9, T14 | `'corrección a 0 se respeta en la pasada siguiente'`; `'updateSowing a 0 devuelve las matas'` |
| SC-6 Resiembra a la cohorte vieja | T4, T6, T15 | `'resiembra por puntero a la vieja: 900 + 300'`; `'la pérdida arranca en el día de esa cohorte'` |
| SC-7 Edad honesta | T6, T16 | `'dos cohortes vivas: edadDeCrop es null'`; widget `'dice «2 edades» y no una edad'` |
| SC-8 Cohorte renovada | T4, T5, T16 | `'nEdades cuenta solo las abiertas'`; `'aparece en «Lotes renovados» y no en los totales'` |
| SC-9 Área | T5, T9, T16 | `'todas conocidas suma; una sin área → null'`; `'conserva la manual y no la pisa'`; avisos widget |
| SC-10 No reemplazar de más | T8, T14 | `validateReplacement` (5 casos); widget `'bloquea y ofrece «Todas (N)»'` |
| SC-11 Sincronización | T11, T12 | `'el payload trae las tres claves aunque sean null'`; round-trips; `'un puntero que llega antes que su cohorte se conserva'` |
| SC-12 Migración aditiva | T2, T20 | `migration_sowings_cohorts_test`; consultas de §5.1 |
| SC-13 Un cultivo de una cohorte no cambia | T13, T14, T16, T19 | `single_cohort_parity_test` (guarda); widget `'el formulario de siempre'` / `'la tarjeta es la de siempre'` |
| SC-14 Cosechas intactas | T13 | `harvests_intactos_test`: sin campos ni columnas nuevas |
| SC-15 Lenguaje | T18 | `'las claves están en los dos ARB'`; `'no usa «cohorte»'` |
| SC-16 Gate | T1, T20 | `analyze` limpio + suite completa en verde |

## 9. Casos borde del PRD → test concreto

| Caso borde (PRD) | Test |
|---|---|
| Resiembra sin muertas anotadas | `sowing_cohorts_test`: resiembra con nuevas y sin muertas suma igual; el aviso T12 sigue en `test/sowing_screen_test.dart` (guarda) |
| Dos siembras el mismo día | `'dos siembras el mismo día: determinista y con puntero explícito'` |
| Siembra con fecha futura | `'cohorte con fecha futura: edad null'` + el reemplazo se aplica igual (mismo test, dos expects) |
| Reemplazo mayor a las vivas | `validateReplacement` → `tooMany` + widget `'bloquea y ofrece «Todas (N)»'` |
| Editar `replaces_plants` | `'updateSowing que baja a 0 devuelve las matas'` + widget `'editar y pasar a «Amplío» guarda 0'` |
| Borrar la siembra **nueva** | `'deleteSowing de la nueva devuelve matas y área a la vieja'` |
| Borrar la siembra **vieja** | `'deleteSowing de la vieja deja el puntero en null y pendingSync'` + widget `'avisa que los totales cambian'` |
| Borrar el cultivo | Guarda: `test/transaction_provider_test.dart` (borrado de cultivo) sigue verde |
| Cohorte en 0 con historia | `'nEdades cuenta solo las abiertas'` + `'aparece en «Lotes renovados»'` |
| Resiembra apuntando a una cohorte en 0 | `'resiembra sobre una cohorte en 0 no la revive'` (la fila queda «sin lote») |
| Todas las cohortes en 0 | `'todas las cohortes en 0: livePlants = 0'` + widget `cohortsNoLivingPlants` |
| Cultivo anual | `'cultivo anual: edad null'` con cohortes válidas |
| Área faltante en una cohorte | `'una cohorte sin área → areaHa null'` + widget `'avisa cuando falta el área'` |
| Datos viejos con dos siembras | `sowing_legacy_normalization_test` (SC-4) |
| Datos viejos donde la segunda era expansión | `'corrección a 0 se respeta'` + caso documentado de varias cohortes vivas |
| Resiembra vieja antes de toda siembra | `'resiembra vieja sin puntero no se normaliza y resuelve por fecha'` + `'resiembra anterior a la siembra base no aplica'` (guarda de `sowing_test.dart:99`) |
| Sync sin la migración aplicada | §14 (riesgo PGRST204); no hay test de red, se cubre con la verificación de §5.1 antes del deploy |
| Respaldo viejo | `'respaldo viejo (sin las claves) entra null y no mueve números'` (SC-4) |
| Asocio / área compartida | Fuera de alcance: la suma no se compara con el terreno; guarda `test/terreno_area_test.dart` sigue verde |

## 10. Guardas (lo que no puede moverse)

1. **Paridad de una cohorte** (`test/single_cohort_parity_test.dart`, T13): con
   un cultivo de **una** siembra y su resiembra, kg/ha, kg/planta, promedio
   histórico, costo por kilo, filas de PDF y de Excel quedan congelados al valor
   de T1 (SC-13). Verde antes y después: **guarda**.
2. **Cosechas intactas** (`test/harvests_intactos_test.dart`, T13): `Harvest` no
   gana campos, su JSON no cambia y la migración no menciona `harvests` (SC-14).
3. **Copy** (T18): todas las claves en los dos ARB, mismos `placeholders`, y
   «cohorte» prohibido en el copy visible (SC-15).
4. **Los tres campos nunca en `null` en una siembra nueva sobre un cultivo con
   cohortes** (T9): evita que la normalización la convierta en renovación total
   al reabrir (§5.7.2).
5. **`test/crop_test.dart:94-114`** (edad con siembra + resiembra) y
   **`test/sowing_test.dart:99-148`** (resiembra anterior y del mismo día) son
   guardas implícitas: deben quedar verdes **sin editar** sus expectativas.

## 11. Tests existentes que hay que tocar (o vigilar)

| Test | Qué pasa | Qué hacer |
|---|---|---|
| `test/sowing_test.dart:117-125` `'área usa la última siembra que la aportó'` | Con la regla nueva, dos **siembras** con `replaces_plants` `null` **suman** (220 matas / 1,3 ha) en vez de reemplazar | Reescribirlo en T5: `'sin normalizar, una siembra posterior suma; el provider normaliza antes de calcular'`, con los dos expects nuevos y el caso de paridad en `sowing_legacy_normalization_test` |
| `test/sowing_test.dart:50-68` round-trip | No se rompe (verifica campo por campo) | Extenderlo con los tres campos (T3) |
| `test/sowing_test.dart:99-115, 132-148` | Resiembra anterior / del mismo día | Deben quedar **verdes sin tocar** (guarda) |
| `test/crop_test.dart:94-145` | `edadDeCrop` | Deben quedar **verdes sin tocar** (guarda); se agregan casos nuevos al lado |
| `test/c6_arranque_test.dart:133-156` | «La edad se reinicia sola con la siembra nueva» | Debe seguir verde: la casilla fuerza Renuevo + «Todas (N)» (T14, §5.7.3) |
| `test/crops_screen_test.dart`, `test/report_screen_test.dart`, `test/l2_3_phase_visibility_test.dart` | Cultivos con una sola siembra (o siembra + resiembra) | Sin cambios; verificar en el gate de cada fase |
| `test/transaction_provider_test.dart` | `addSowing` sin los campos nuevos | Sin cambios: `null` es válido |
| `test/per_hectare_panel_test.dart` | Panel sin `sowings` | Sin cambios: el parámetro nuevo tiene default `const []` |
| `test/export_parity_test.dart`, `test/pdf_export_test.dart` | Números de PDF/Excel | Sin cambios (misma fórmula); si alguno usa dos **siembras** en el mismo cultivo, pasar el `replacesPlants` explícito |
| `test/backup_import_test.dart`, `test/settings_backup_test.dart` | Respaldo | Sin cambios; el blob suma tres claves (los round-trips no comparan el blob completo) |
| `test/l10n_placeholder_order_test.dart` | Orden de `placeholders` | Se cumple declarándolos en el ARB (§7) |
| `test/derived_harvests_cascade_test.dart`, `test/crop_loss_dialog_test.dart`, `test/recordatorio_lote_test.dart` | Cosechas derivadas y pérdidas | Solo se tocan si algún caso agrega dos **siembras** al mismo cultivo: ahí se agrega `replacesPlants` explícito |

Instrucción de ejecución: en T5 y en cada fase, correr la suite completa y
**actualizar solo los tests cuyo sentido era «la segunda siembra reemplaza el
total»**, agregando los parámetros nuevos; cualquier otro rojo es un bug de la
implementación, no del test.

## 12. Verificación manual (después del deploy)

Los 10 pasos del PRD, ajustados al plan:

1. **Datos viejos quietos.** Antes de actualizar, anotar `livePlants` y `areaHa`
   de un cultivo existente con dos siembras. Abrir la versión nueva → los dos
   números **idénticos** (SC-4, T10).
2. **La corrección manda.** En ese cultivo, editar la segunda siembra y elegir
   **«Amplío el cultivo»** → las matas suben y la tarjeta dice **«2 edades»**;
   cerrar y reabrir la app → sigue en 0, no se vuelve a normalizar (SC-5, T7/T14).
3. **Renovación parcial (el caso).** Cultivo de 5 ha / 1.000 matas: anotar una
   siembra de 1 ha con 300 matas y «Renuevo» → **Matas que reemplaza = 300**
   (precarga sugerida ≈200) → la tarjeta queda **700/4,0 + 300/1,0 = 1.000/5,0**
   con «2 edades» (SC-1, SC-2).
4. **Renovación total.** Otra siembra, «Renuevo» → **«Todas (N)»** → el lote
   viejo aparece en **«Lotes renovados»** con su fecha y el cultivo queda en
   **300 matas / 1,0 ha / 1 edad**, fuera de totales (SC-3, SC-8).
5. **Resiembra en el lote viejo.** Resiembra con **100 muertas** elegida la
   cohorte vieja → la vieja baja a 900 y el total a 1.200; el selector de fecha
   de la pérdida **arranca en el día de siembra de esa cohorte**, no en la última
   siembra (SC-6, T15).
6. **No se puede reemplazar de más.** Intentar reemplazar **1.200** matas de una
   cohorte de 1.000 → bloquea, dice cuántas hay y ofrece **«Todas (1.000)»**
   (SC-10, T8/T14).
7. **Área incompleta.** Cultivo con un lote sin área → conserva el área manual y
   muestra el aviso «No todos los lotes tienen área…», sin bloquear; si la suma
   medida ya supera la manual, el aviso dice las dos cifras (SC-9, T16).
8. **Reportes.** Abrir Reportes con un cultivo de dos edades → el kg/planta del
   cultivo **no cambió de fórmula** y al lado dice **«promedio de 2 edades»**;
   ninguna fila nueva por lote; el PDF/Excel sale con los mismos totales (SC-7,
   T19).
9. **Una sola cohorte.** Un cultivo de **una** siembra → lista, Reportes, PDF y
   Excel **idénticos** a la versión anterior; el formulario de siembra no muestra
   la pregunta de renovación (SC-13, T13/T14/T16).
10. **Sin señal.** En modo avión, anotar una siembra con reemplazo → queda
    `pendingSync`; al volver la red, sube y otra instalación la ve con **los
    mismos** matas, área y puntero (SC-11, T11/T12).

## 13. Gate, stageo y despliegue

### Gate (por fase y al cierre)

```
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test *> docs\reports\gate-t20.txt
(Get-Content docs\reports\gate-t20.txt) -replace "\e\[[0-9;]*m","" | Select-String "All tests passed|tests failed|\+\d+ -"
```

### Stageo explícito (nunca `-A`)

Los archivos de cada tarea, uno por uno. Antes de commitear: `git status` y
`git diff --check` (espacios/CRLF). Después: `git show --stat` para confirmar que
no entraron miles de líneas por CRLF (sobre todo en `lib/l10n/generated/`).

### Orden de despliegue

1. El usuario aplica `202610210001_add_sowings_cohorts.sql` en Supabase y corre
   las cuatro consultas de §5.1 (esperado: 3 columnas, FK `set null`, índice,
   `con_dato = 0`).
2. Gate verde sobre `main`.
3. Commit explícito, push y `.\deploy.ps1 -Message "…"`.
4. Verificar que Pages sirvió el build nuevo y que la app abre y sincroniza
   (`docs/reports` con el resultado).

## 14. Riesgos, rollback y deuda

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **Migración sin aplicar en producción** | media | alto | Va **antes** del deploy. Sin ella el push devuelve **PGRST204** («Could not find the 'replaces_plants' column of 'sowings' in the schema cache»): los stages de `sowings` fallan uno por uno, las filas quedan `pendingSync` y **no se pierde nada**. Se detecta en `docs/reports` del cierre |
| La normalización mueve números con **varias** cohortes vivas al momento de una siembra vieja | baja | alto | Se apunta a la más antigua y se reemplaza el total de vivas; el resto sobrevive y el total sube. Caso documentado + test + nota en el informe (§5.5) |
| Borrar la cohorte vieja cambia los totales sin avisar | media | medio | Diálogo con el antes/después de matas (`sowingDeleteCohortBody`, T15) |
| El push falla por la FK auto-referente (destino aún no subido) | baja | medio | El orden de push ya pone `sowings` antes que `harvests`/`transactions` y el destino es una siembra anterior; si falla, `pendingSync` y se reintenta |
| El área sumada miente en asocio | baja | medio | Fuera de alcance; aviso no bloqueante y valor manual si falta un área |
| Una siembra nueva guardada con los tres campos en `null` se normalizaría como renovación total | media | alto | Se elimina por diseño: «Amplío» por defecto escribe `0` explícito (§5.7.2) + guarda en T9 |
| Lluvia de `pendingSync` tras normalizar | media | bajo | Es la primera subida de las tres columnas: una vez por fila |
| CRLF en `lib/l10n/generated/` | media | bajo | LF antes del commit y `git show --stat` |
| El agricultor no sabe cuántas matas hay | alta | bajo | Precarga por área + «Todas (N)» + editable; no bloquea |
| Un cliente viejo sube `null` en las tres claves | baja | bajo | Se lee como dato viejo; la normalización lo resuelve sin mover números |
| Deuda: los kilos siguen mezclados | cierta | alto | Etapa B; el copy no promete kg por lote |
| Deuda detectada (fuera de alcance): la tabla exige `plants > 0` y una resiembra con **0 plantas** no sincroniza | baja | bajo | No se toca en esta etapa; se anota en el informe para tratarla aparte |

### Rollback

- **Antes del deploy** (lo más seguro): revertir el commit de la app deja la base
  con tres columnas `null` que nadie usa. No hay que hacer nada en Supabase.
- **Después del deploy, si hay que volver atrás:** primero desplegar el build
  anterior (el cliente viejo ignora las columnas) y **después**:

  ```sql
  drop index if exists public.idx_sowings_cohort;
  alter table public.sowings drop column if exists cohort_sowing_id;
  alter table public.sowings drop column if exists replaces_area_ha;
  alter table public.sowings drop column if exists replaces_plants;
  ```

  Borrar las columnas con la app nueva en producción produce el mismo PGRST204
  del riesgo 1: las filas quedan `pendingSync` y no se pierden. Se pierden los
  reemplazos ya anotados (los números vuelven a «la siembra nueva reemplaza
  todo»), por eso el orden es deploy viejo → drop.
- Reaplicar la migración siempre es seguro: es idempotente (`if not exists`).

### Deuda explícita que queda abierta

- `harvests` no sabe de lotes: no hay kg/planta por edad ni costo por kilo por
  cohorte (etapa B).
- Recepa/socola sin representación.
- Asocio y hectáreas equivalentes.
- No hay forma de **fusionar** dos cohortes: la salida es editar los reemplazos.
- Un «arranque completo» con **varias** cohortes vivas no se expresa en una sola
  siembra: se resuelve lote por lote (T14, §5.7.3).

## 15. Definition of done

- [ ] Migración aplicada en Supabase, verificada con las cuatro consultas, sin
      backfill.
- [ ] `flutter analyze` limpio (proyecto entero) y `flutter test` en verde, con
      los **1120** de `main` (`84ff1e1`) más los nuevos.
- [ ] SC-1 … SC-16 con su test o su evidencia manual.
- [ ] Los diez pasos de §12 hechos y anotados en el informe.
- [ ] Guardas de §10 verdes.
- [ ] Claves de §7 en los dos ARB, `gen-l10n` corrido y `lib/l10n/generated/`
      commiteado con LF.
- [ ] Copy visible con «lote», nunca «cohorte»; ES y EN con las mismas claves.
- [ ] `harvests`, `transactions`, la pantalla Cosechar, `HarvestDestination.almacenado`,
      los exportes y el renderer **sin tocar**.
- [ ] Informe en `docs/reports/2026-10-21_cohortes-estructura.md` con baseline,
      antes/después de los números y el caso de normalización documentado.
- [ ] Commit explícito (stageo archivo por archivo, LF), push y deploy
      verificados, con el verbo del usuario en ese turno.
