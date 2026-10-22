---
status: DRAFT
created: 2026-10-22_1813
updated: 2026-10-22_1813
---

# Cohortes dentro de un cultivo — Etapa B «atribución de kilos por lote» (PRD)

> De dónde sale: etapa A cerrada y desplegada
> (`docs/prds/2026-10-21_1818-cohortes-estructura.prd.md`,
> `docs/reports/2026-10-21_cohortes-estructura.md`,
> `docs/plans/2026-10-21-cohortes-estructura.plan.md`), las decisiones ya
> tomadas (D1–D6) y el código real de esta etapa.
> **Este documento no implementa nada**: fija el alcance, el modelo, los
> cálculos, el copy y la verificación. El plan de tareas se escribe aparte.
> Base de partida: `main` con `flutter analyze` limpio y **1238/1238** tests.

## Objective

Que los kilos que el agricultor **pesa por lote al recoger** se guarden con ese
lote y se puedan ver en la tarjeta del cultivo, sin repartir ninguna venta y sin
inventar un solo kilo: kg del lote y kg/planta del lote, y **solo si hay kilos**.
La venta, los reportes, el PDF y el Excel no cambian.

Las cosechas de la etapa A siguen siendo del cultivo entero. Esta etapa agrega
**una** atribución opcional al jornal de «Cosechar» y **una** lectura en la
tarjeta. Nada más.

## El caso (café, 5 ha y 1.000 matas, una parte renovada)

Cafetal de **1.000 matas / 5 ha** (2020). En 2026 renueva **1 ha con 300 matas**
(reemplaza 300): quedan un lote viejo de **700 matas / 4 ha** y uno nuevo de
**300 matas / 1 ha** con «2 edades» (etapa A).

En la cosecha de 2026 el agricultor pesa por separado:

| Lote | Matas vivas | Peso anotado en el jornal |
|---|---|---|
| 12/03/2020 | 700 | 250 kg |
| 2026 | 300 | 180 kg |

- Lo que la app dice hoy: el cultivo entero, **430 kg** y **0,43 kg/planta**
  (430 ÷ 1.000). No hay forma de ver que el lote viejo rinde **0,36** y el nuevo
  **0,60**.
- Lo que debe decir: en la tarjeta, al desplegar «2 edades», cada fila con sus
  kilos —`250 kg · 0,36 kg/planta` y `180 kg · 0,60 kg/planta`— sin tocar el
  total del cultivo, que sigue saliendo de los mismos kilos de siempre.

## Success Criteria

Verificables de a uno, contra la app corriendo o contra una prueba automática.
`SHALL` / `SHALL NOT` son obligatorios.

- **SC-1 · Atribución.** WHERE un jornal de labor «Cosechar» con cultivo trae
  **250 kg** y el cultivo tiene dos lotes vivos, WHEN se elige el lote del
  **12/03/2020**, the system SHALL guardar `cohort_sowing_id` con el `id` de esa
  siembra, y `toJson` SHALL devolver la misma clave y el mismo valor.
- **SC-2 · Sin lote no bloquea.** WHEN se guarda un jornal de «Cosechar» con
  kilos, cultivo con lotes vivos y **ningún** lote elegido, the system SHALL
  guardar `cohort_sowing_id = null`, SHALL mostrar un aviso visible y SHALL NOT
  impedir el guardado.
- **SC-3 · Sin lotes no hay selector.** WHERE el cultivo no tiene ningún lote
  vivo (sin siembras, o todas renovadas), the system SHALL ocultar el selector
  de lote y SHALL guardar `null` sin aviso.
- **SC-4 · Kg del lote.** WHERE el lote del 12/03/2020 tiene jornales medidos que
  suman **250 kg**, WHEN se despliega «2 edades», the system SHALL mostrar
  **`250 kg`** en la fila de ese lote y en ninguna otra.
- **SC-5 · Kg/planta del lote.** WHERE el lote tiene **700** matas vivas y
  **250 kg**, the system SHALL mostrar **`0,36 kg/planta`** (250 ÷ 700,
  redondeado a 2 decimales) y SHALL NOT usar el total del cultivo ni el de otro
  lote.
- **SC-6 · Sin kilos, oculto.** WHERE un lote vivo no tiene ningún jornal medido
  con ese lote, the system SHALL NOT mostrar `0 kg` ni `0,00 kg/planta`: SHALL
  omitir la parte de kilos de esa fila.
- **SC-7 · Una edad intacta.** WHERE el cultivo tiene **un solo** lote vivo, the
  system SHALL mostrar la tarjeta exactamente como hoy (misma edad, mismos
  widgets) y SHALL NOT agregar kg por lote.
- **SC-8 · Lote renovado.** WHERE un lote quedó en **0** matas vivas, the system
  SHALL conservar sus jornales en el dato, SHALL NOT mostrarle `kg/planta` en
  ningún sitio y SHALL NOT agregar kilos a la fila de «Lotes renovados».
- **SC-9 · La cosecha manual manda.** WHERE el cultivo tiene una cosecha guardada
  a mano, the system SHALL ocultar los kg por lote de ese cultivo (su total de
  kilos no sale de los jornales) y SHALL conservar los datos intactos.
- **SC-10 · Borrar el lote.** WHEN se borra una siembra que era lote de un
  jornal, the system SHALL dejar `cohort_sowing_id = null` y `pendingSync: true`
  en ese jornal, y los kilos del cultivo SHALL NOT cambiar (siguen saliendo de
  `cropId`).
- **SC-11 · Editar una cosecha.** WHEN se edita un jornal medido con lote, the
  system SHALL precargar su lote; IF se cambia el tipo, la categoría, la labor,
  el cultivo o se le pone un lote de terreno, the system SHALL limpiar
  `cohort_sowing_id` y SHALL NOT restaurarlo al volver a «Cosechar».
- **SC-12 · Puntero roto.** WHERE un jornal apunta a una siembra que no existe,
  que es de otro cultivo o que no es una siembra, the system SHALL contar sus
  kilos como «sin lote» y SHALL NOT reasignarlos a otro lote.
- **SC-13 · Sincronización.** WHEN un movimiento se empuja, el payload SHALL
  incluir `cohort_sowing_id` **siempre**, incluido `null`; un viaje de ida y
  vuelta por JSON y por respaldo SHALL devolver el mismo valor.
- **SC-14 · Migración.** La migración SHALL ser aditiva e idempotente
  (`add column if not exists`), con FK `references public.sowings(id) on delete
  set null` e índice, sin backfill y sin tocar `harvests` ni otras columnas de
  `transactions`.
- **SC-15 · La venta no cambia.** The system SHALL NOT agregar selector de lote
  a la venta ni a los ingresos, y `Transaction.fromJson` SHALL limpiar
  `cohort_sowing_id` en cualquier movimiento que no sea un jornal de «Cosechar»
  con kilos y cultivo.
- **SC-16 · Lenguaje.** El copy visible SHALL decir **«lote»**, nunca «cohorte»;
  SHALL existir en **ES y EN** con las mismas claves y los mismos placeholders.
- **SC-17 · Gate.** `flutter analyze` (proyecto entero, `tool/` incluido) limpio
  y `flutter test` en verde con los **1238** tests actuales más los nuevos.

## Out of Scope

- **Repartir** los kilos de una venta entre lotes, por edad, por área o por
  precio. La venta sigue apuntando a un cultivo o a ninguno.
- **Reportes, PDF y Excel**: sus columnas, fórmulas y textos no cambian; el
  kg/planta del cultivo sigue siendo del cultivo entero.
- **Presupuesto por tarea**, recepa/socola, asocio, hectáreas equivalentes.
- **`Harvest` / `harvests`**: ni columna, ni campo, ni cohorte en una cosecha
  derivada (`derived_harvests.dart` no cambia).
- **Fila «sin lote»** con los kilos no atribuidos en la tarjeta del cultivo
  (divergencia declarada; se evalúa en una etapa posterior).
- **Mostrar kg por lote con una sola edad** (SC-7: paridad con hoy).
- **Reatribuir cosechas viejas**: no hay backfill; quedan «sin lote».
- **Fusionar lotes** o mover kilos de un lote a otro en bloque.
- Tocar `Sowing`, `Crop`, la pantalla de siembras, `HarvestDestination`, el
  renderer, las fuentes o `NOTICES`.

## Assumptions

- El agricultor pesa por lote al recoger y anota ese peso en el jornal de
  «Cosechar» (`harvestedKg`); la venta mezcla lotes y no sirve para atribuir.
- Un jornal de «Cosechar» pertenece a **un** lote como máximo (un pesaje por
  jornal). Si pesó dos lotes el mismo día, anota dos jornales.
- Los datos viejos no tienen la columna nueva y no hay nada que adivinar: se
  quedan «sin lote».
- La migración la aplica el usuario en Supabase **antes** del deploy.

## Users

- **Primario**: el productor de café que renueva una parte del lote y quiere
  saber qué rinde cada edad, sin separar la venta.
- **Secundario**: quien carga los jornales por él y necesita que el formulario
  pregunte lo mínimo y no lo obligue a elegir.
- **No es para**: quien quiere contabilidad por lote ni reparto de una venta
  mixta (fuera de alcance).

## Constraints

- Local-first: todo funciona sin red y sincroniza después.
- Regla de oro: **`null` → oculto, nunca 0**; ninguna cifra fuera de los totales.
- Copy ES/EN; `lib/l10n/app_es.arb` es el template; `gen-l10n` después y
  `lib/l10n/generated/` se commitea, normalizado a **LF**.
- Cada arreglo con su test, **rojo antes**; cuando no hay rojo posible se
  declara **guarda**.
- Gate antes de commit y deploy: `flutter analyze` + `flutter test`.
- Migración aditiva, `if not exists`, sin backfill; la aplica el usuario.
- Sin `git add -A`; stageo explícito.

---

## Decisiones ya tomadas (no se reabren)

### D1 — Los kilos por lote salen del jornal, no de la venta

La atribución se guarda en la transacción con `labor = cosechar` +
`harvestedKg`, porque en la finca se pesa por lote al recoger y la venta
después mezcla. La venta no se toca: sigue apuntando a un cultivo o a ninguno.

### D2 — Selector de lote opcional; avisa, no bloquea

Si el cultivo tiene lotes vivos y no se elige ninguno, se guarda «sin lote» y la
app avisa. Nunca se impide guardar: en el campo se anota rápido y se corrige
después.

### D3 — La venta no cambia

Ni selector, ni reparto, ni columna nueva en el flujo de venta. `cohort_sowing_id`
en un ingreso no significa nada y se limpia al entrar.

### D4 — Se muestra en la tarjeta del cultivo, al desplegar «N edades»

Solo allí: kg del lote y kg/planta del lote, **solo si tiene kilos**. Sin kilos
→ oculto, nunca 0. Reportes/PDF/Excel quedan igual.

### D5 — Modelo: una columna nullable en `transactions`

`cohort_sowing_id` uuid, nullable, FK auto-referente a `sowings(id)` con
`on delete set null`, más índice. Migración aditiva, idempotente, sin backfill.
Las cosechas viejas quedan «sin lote».

### D6 — Fuera de alcance

Reparto de una venta entre lotes, `reports` por lote, recepa/socola, asocio,
cambios en `HarvestDestination` y presupuesto por tarea.

---

## Decisiones abiertas (con recomendación y alternativa)

Se marcan como **ABIERTA** para confirmar antes de `/plan`. La recomendación va
primero y es la que el PRD adopta si no hay respuesta.

> **Cerradas el 2026-10-22: D7–D12 quedan en la opción A**, confirmadas por el
> usuario en bloque. Las alternativas quedan como registro.

### D7 · Un solo lote vivo — **ABIERTA**

- **Recomendación (A)**: con **un** lote vivo, preseleccionarlo. No hay
  ambigüedad, evita el aviso en el caso más común y el agricultor puede cambiarlo
  a «Sin lote».
- **Alternativa (B)**: arrancar siempre en «Sin lote» aunque haya uno solo. Más
  conservador, pero obliga a elegir a mano en el 90 % de los casos y llena el
  formulario de avisos.

### D8 · Kilos de un lote renovado — **ABIERTA**

- **Recomendación (A)**: no mostrar kilos en «Lotes renovados». Su `kg/planta` es
  indefinido (0 matas) y mostrar solo kg en una fila que dice «renovada» invita a
  leerlo como rendimiento actual. El dato se conserva y no se pinta.
- **Alternativa (B)**: mostrar solo `X kg` en el historial, sin `kg/planta` ni
  rendimiento. Honesto pero agrega una cifra histórica a una sección que hoy es
  solo fechas.

### D9 · Puntero a un lote que ya se renovó, al editar el jornal — **ABIERTA**

- **Recomendación (A)**: ofrecerlo en el selector marcado con la clave
  `jornalHarvestedKgLotRenewed` (`{date} · {plants} matas · renovado`) y conservar
  la atribución. Borrar la atribución de una cosecha pasada por haber renovado el
  lote sería reescribir la historia.
- **Alternativa (B)**: el selector solo ofrece lotes **vivos**; un puntero a un
  lote cerrado se muestra como «Sin lote» y se guarda `null` (pierde la
  atribución, y el dato viejo desaparece sin avisar).

### D10 · Cultivo con una cosecha guardada a mano — **ABIERTA**

- **Recomendación (A)**: ocultar los kg por lote de ese cultivo. La regla viva
  dice que la manual manda y la venta/jornal no derivan (`derived_harvests.dart`);
  mostrar aquí los kilos de los jornales sería una cifra que **no entra en los
  totales** (el error del racimo, LEARNING 2026-10-20).
- **Alternativa (B)**: mostrarlos igual, aclarando «medido en el campo». Da
  información, pero suma una cifra que el resto de la app ignora.

### D11 · Notación de los kilos — **ABIERTA**

- **Recomendación (A)**: `formatKg(valor, locale)` en `lib/utils/format.dart`, con
  la notación del idioma (`250 kg`, `0,36 kg/planta` en ES), igual que
  `formatAreaHa`. Se usa **solo** en la tarjeta; Reportes/PDF conservan su
  `_numKg` privado (deuda declarada, fuera de alcance).
- **Alternativa (B)**: replicar `toStringAsFixed` con punto (`0.36`), para no
  divergir de Reportes. Rompe la regla «la notación sigue al idioma» que ya rige
  en la app.

### D12 · Huérfanos del puntero en el respaldo — **ABIERTA**

- **Recomendación (A)**: contar el puntero de un jornal a una siembra ausente en
  el mismo bloque de huérfanos que ya existe (`:1068-1084`). Es una referencia
  rota igual que las otras y el importe no se pierde (sigue contando por cultivo).
- **Alternativa (B)**: no contarlo. El resumen de importación no cambia, pero una
  atribución rota pasa inadvertida.

---

## Modelo de datos

### Columna nueva en `transactions` (1)

| Columna | Tipo | Null | Significado |
|---|---|---|---|
| `cohort_sowing_id` | `uuid` | sí | lote (siembra-cabeza) al que se atribuyen los kilos de este jornal. `null` = sin lote |

Solo tiene sentido en un jornal de «Cosechar» con kilos y cultivo. En cualquier
otro movimiento es `null` y se limpia al entrar (D3, SC-15).

### Modelo Dart (`Transaction`)

- `final String? cohortSowingId;` en el constructor.
- `copyWith` **con centinela** (patrón de `harvestedKg`/`terrenoId`): hay que
  poder volver a `null` al cambiar de labor o de cultivo.
- `toJson`: `'cohort_sowing_id': cohortSowingId`.
- `fromJson`: lee `json['cohort_sowing_id'] as String?`.

No se toca `sowingId`: ahí significa «gasto de esta siembra» (etapa A) y son
cosas distintas. Una transacción puede tener los dos y no se estorban.

### Puerta única de entrada (`Transaction.fromJson`)

Mismas reglas que ya aplica a `harvestedKg`, para que disco, nube y respaldo
entren por un solo camino:

| Regla | Efecto |
|---|---|
| clave ausente (dato, cliente o respaldo viejo) | `null`, **sin** marcar sucio |
| `type == income` | `null` + `pendingSync: true` |
| `category != 'mano_obra'` | `null` + `pendingSync: true` |
| `task != kTaskCosechar` (incluye `null` y texto libre de «Otra…») | `null` + `pendingSync: true` |
| `harvestedKg == null` o `<= 0` | `null` + `pendingSync: true` |
| `cropId == null` | `null` + `pendingSync: true` |
| `terrenoId != null` | `null` + `pendingSync: true` (el campo de kilos ni se muestra con lote de terreno) |
| puntero a una siembra de otro cultivo o inexistente | **se conserva** el valor; la regla de lectura lo trata «sin lote» (SC-12) |

**Por qué el último caso no se limpia al entrar**: `fromJson` no conoce las
siembras; limpiar ahí perdería la elección del agricultor cuando el pull llega en
desorden. La **regla de lectura** (una sola, pura) es la que decide.

**Idempotencia sin bandera**: como la clave no existe en ningún dato viejo, la
limpieza no dispara una subida masiva; solo marca sucio un registro que llegó con
la columna puesta y estructuralmente imposible.

### Migración exacta

`supabase/migrations/202610220001_add_transaction_cohort.sql`

```sql
-- =============================================
-- Etapa B · kilos de un jornal atribuidos a un lote (cohorte de siembra).
--
--   transactions.cohort_sowing_id  lote al que se atribuyen los kilos
--                                  anotados en un jornal de «Cosechar».
--                                  null = sin lote (dato viejo o no elegido).
--
-- Solo tiene sentido junto a `harvested_kg` (Tanda 2): es una MEDIDA, no un
-- reparto de la venta. La venta sigue siendo del cultivo entero.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía esta
-- columna. `buildTransactionPayload` la manda siempre; si no existe,
-- PostgREST responde PGRST204 y se cae el subido COMPLETO (el mismo caso que
-- `harvested_kg` 202610190001, `equiv_kg` 202610200001 y `task` 202610110002).
--
-- Aditiva, nullable, sin backfill. La FK apunta a una siembra (destino ya
-- subido: los `sowings` se empujan antes que las `transactions`).
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.transactions
  add column if not exists cohort_sowing_id uuid
    references public.sowings(id) on delete set null;

create index if not exists idx_transactions_cohort
  on public.transactions (cohort_sowing_id);

comment on column public.transactions.cohort_sowing_id is
  'Lote (siembra) al que se atribuyen los kilos de un jornal de Cosechar. Null = sin lote. No reparte la venta.';
```

- RLS no cambia: las políticas existentes ya cubren la fila.
- Sin backfill: todas las filas entran en `null` y se leen «sin lote».
- La base **no** valida que el lote pertenezca al cultivo ni que esté vivo: eso
  depende de otras filas y se resuelve en la regla de lectura (SC-12).
- Limitación conocida de `if not exists`: si alguien aplicara la migración a
  medias (columna sin FK), volver a correrla no agrega la FK. Se detecta con la
  verificación de abajo.

**Verificación en Supabase (SQL Editor, después de aplicar):**

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'transactions'
  and column_name = 'cohort_sowing_id';

select conname, confdeltype
from pg_constraint
where conrelid = 'public.transactions'::regclass
  and conname = 'transactions_cohort_sowing_id_fkey';   -- confdeltype = 'n'

select indexname from pg_indexes
where schemaname = 'public' and tablename = 'transactions'
  and indexname = 'idx_transactions_cohort';

-- sin backfill: recién aplicada, ninguna fila tiene el campo
select count(*) as con_dato
from public.transactions
where cohort_sowing_id is not null;
```

Esperado: 1 fila, 1 FK con `confdeltype = 'n'`, 1 índice, `con_dato = 0`.

---

## Cálculo

### Regla de lectura (función pura)

`lib/models/cohort_kilos.dart`:

```dart
/// Kg anotados por lote en jornales de «Cosechar».
///
/// - Solo gastos no borrados, categoría `mano_obra`, labor `kTaskCosechar`,
///   `harvestedKg > 0` y del cultivo pedido.
/// - El puntero se resuelve contra las cohortes **de ese cultivo**, abiertas o
///   cerradas. Un puntero que no resuelve NO se reasigna: esos kilos quedan
///   «sin lote» y no entran al mapa.
/// - Si el cultivo tiene una cosecha guardada a mano, devuelve `{}` (D10-A).
/// - No redondea: suma los números que él escribió.
Map<String, double> cohortKilos({
  required String cropId,
  required List<Transaction> transactions,
  required List<Harvest> storedHarvests,
});

/// Kg/planta de un lote. `null` si no hay kilos o no hay matas vivas.
double? kgPerPlantCohort(double? kg, int livePlants);
```

### Agregado por lote

- `kg` del lote = suma de `harvestedKg` de sus jornales (sin redondear). Si no
  hay ninguno → el lote **no tiene** kg (`null`), no `0`.
- `kg/planta` = `kg ÷ livePlants` de **esa cohorte** (`Cohort.livePlants`), con
  `livePlants > 0`. Sin matas vivas no hay cifra (SC-8), nunca infinito ni 0.
- El total del cultivo **no cambia**: sigue saliendo de `harvestProvider` /
  `crop.livePlants` con la fórmula de siempre.

### Redondeo y notación

- **kg del lote**: `formatKg(valor, locale)` — `>= 100` sin decimales; si no,
  0 o 2 decimales; separador del idioma. `250 kg`, `1.240 kg`.
- **kg/planta del lote**: 2 decimales siempre, con el separador del idioma:
  `0,36 kg/planta` (ES) / `0.36 kg/plant` (EN).
- El redondeo es **solo de presentación**: no se guarda ni se recalcula nada.
- `250 ÷ 700 = 0,357142…` → **`0,36`**. `180 ÷ 300 = 0,6` → **`0,60`**.

### Ejemplo numérico (el caso)

Cultivo: viejo 700 / 4 ha (2020) + nuevo 300 / 1 ha (2026). Jornales: 250 kg al
viejo, 180 kg al nuevo.

| Fila al desplegar «2 edades» | Texto |
|---|---|
| Lote 2020 | `12/03/2020 · 700 matas · 6 años · 4,0 ha · 250 kg · 0,36 kg/planta · Abierta` |
| Lote 2026 | `12/03/2026 · 300 matas · Menos de un año · 1,0 ha · 180 kg · 0,60 kg/planta · Abierta` |
| Total del cultivo (sin cambios) | `430 kg` y `0,43 kg/planta` (430 ÷ 1.000) |

Un tercer jornal de 50 kg **sin lote** no aparece en ninguna fila: el total del
cultivo lo cuenta (480 kg) y la tarjeta no inventa un lote. Es la divergencia
declarada.

### Qué NO cambia en los cálculos

`yieldPerPlant`, `yieldPerArea`, `historicalYield`, costo por kilo, los
pintadores de Reportes, el PDF y el Excel. `deriveHarvests` no gana cohorte (una
cosecha derivada no puede llevar lote: se reatribuiría el pasado). El único
consumidor nuevo es la tarjeta del cultivo.

---

## UX

### 1 · Jornal de «Cosechar» (`register_screen.dart`)

El selector se dibuja **debajo** del campo de kilos y usa su misma puerta:

- **Aparece** solo si: gasto, categoría `mano_obra`, labor **«Cosechar»** del
  catálogo (no texto libre), cultivo elegido, sin lote de terreno, y el cultivo
  tiene **al menos un lote vivo**.
- **No aparece** si: falta el cultivo (ya existe `jornalHarvestedKgNoCrop`), hay
  lote de terreno, la labor no es «Cosechar», o el cultivo no tiene lotes vivos.
  En esos casos `cohort_sowing_id` viaja `null` y no se avisa (no hay nada que
  atribuir).
- **Opciones**: «Sin lote» (primera) + una por lote **vivo**, con
  `sowingCohortOption` (`{date} · {plants} matas`). Si el jornal ya tenía un
  puntero a un lote **cerrado** y se está editando, ese lote se agrega con
  `jornalHarvestedKgLotRenewed` (D9-A).
- **Por defecto**: un lote vivo → ese (D7-A); dos o más → «Sin lote».
- **Aviso, no bloqueo**: si hay kilos escritos y el selector está en «Sin lote»,
  se pinta en naranja `jornalHarvestedKgLotMissing` debajo del campo. Guardar
  funciona igual (SC-2).
- **Limpieza (D12 del formulario)**: al cambiar labor, categoría, tipo, cultivo o
  al elegir un lote de terreno, se limpia la elección y **no se restaura** al
  volver a «Cosechar». Lo oculto no guarda un valor escondido.
- **Editar**: precarga el lote guardado (o «Sin lote»); guardar sin tocarlo deja
  el mismo valor.

### 2 · Tarjeta del cultivo (`crops_screen.dart`)

- Con **una** cohorte viva: nada nuevo (paridad, SC-7).
- Con **dos o más**: dentro de `cohorteLinea` (que ya pinta fecha, matas, edad,
  área y estado), se agregan `kg` y `kg/planta` **después del área y antes del
  estado**, solo si `cohortKilos` devuelve un valor para ese `sowingId`:
  `· 250 kg · 0,36 kg/planta`.
- Los kilos **no** se suman a la cabecera, no cambian el chip «N edades» y no
  tocan los totales del cultivo.
- «Lotes renovados» no gana kilos (D8-A).
- Sin ningún jornal medido en ningún lote: la lista de edades se ve como hoy.

### 3 · Estados vacíos (tabla de comportamiento)

| Estado | Qué se pinta |
|---|---|
| Cultivo sin siembras / sin lotes vivos | Selector de lote oculto. Kilos del cultivo como hoy |
| Lote vivo sin jornales medidos | Fila de la edad **sin** `kg` ni `kg/planta` |
| Lote con kg pero 0 matas vivas (renovado) | Sin `kg/planta`; sin kilos en el historial |
| Una sola edad | Tarjeta idéntica a hoy; sin kg por lote |
| Cultivo con cosecha manual | Sin kg por lote (D10-A) |
| Jornal sin lote | Aviso en el formulario; nada en la tarjeta |
| Cultivo con todos los jornales sin lote | Ninguna fila gana kilos; la tarjeta se ve como hoy |
| Cultivo anual con lotes | Igual: los lotes existen; la edad sigue oculta |

### 4 · Ayuda

Párrafo corto en `help_screen.dart` (recomendado, ver copy): qué significa
elegir el lote en un jornal y por qué los kilos por lote no se suman a la venta.
Sin la palabra «cohorte».

---

## Copy ES/EN (propuesto)

Claves nuevas en `lib/l10n/app_es.arb` (template) y `app_en.arb`. Cada una con
su bloque `@clave` y los `placeholders` **declarados en el orden en que se leen**
(`test/l10n_placeholder_order_test.dart` lo exige). Las cifras viajan como
`String` ya formateadas.

| Clave | ES | EN | Placeholders (orden de lectura) |
|---|---|---|---|
| `jornalHarvestedKgLotLabel` | Lote de la cosecha (opcional) | Harvest lot (optional) | — |
| `jornalHarvestedKgLotNone` | Sin lote | No lot | — |
| `jornalHarvestedKgLotRenewed` | {date} · {plants} matas · renovado | {date} · {plants} plants · renewed | `date` String, `plants` int |
| `jornalHarvestedKgLotMissing` | No elegiste lote: estos kilos quedan del cultivo y no se ven por lote. Puedes guardar así. | You didn't choose a lot: these kilos stay with the crop and won't show per lot. You can save anyway. | — |
| `cohortKgLabel` | {kg} kg | {kg} kg | `kg` String |
| `cohortKgPerPlantLabel` | {value} kg/planta | {value} kg/plant | `value` String |
| `helpCohortKg` | Los kilos del jornal pueden ir a un lote: es lo que pesaste de ese lote. La venta no se reparte; el total del cultivo no cambia. | The kilos in a work log can go to a lot: that's what you weighed from that lot. The sale isn't split; the crop total doesn't change. | — |

**Reutilizadas, sin duplicar**: `sowingCohortOption` (`{date} · {plants} matas`)
para las opciones del selector, `sowingNoCohortTag` («Sin lote») si hace falta
una etiqueta, `cropAge` para los años y `cohortRenewed` para el estado.

Reglas de copy: **«lote»**, no «cohorte»; **«matas»** para café; nunca «0» para un
dato ausente; no se promete reparto de la venta.

---

## Sincronización y respaldo

### Push (`sync_provider.dart`)

`buildTransactionPayload` agrega **siempre** la clave, incluido `null`:

```dart
'cohort_sowing_id': _uuidOrNull(t.cohortSowingId),
```

- El orden de push ya pone `sowings` antes que `transactions` (`:154-155`,
  `:214-239`), así que el destino de la FK existe.
- Si la siembra no subió, el push de esa fila falla y queda `pendingSync`: se
  reintenta y no se pierde (stages por fila).
- Un cliente viejo (sin la clave) sube `null`: se lee como «sin lote».

### Pull

- `_remoteToTransaction` (`:662-670`) lee `cohort_sowing_id`.
- Si llega el puntero antes que la siembra, **se conserva** y la lectura lo trata
  «sin lote» hasta que llegue; no se anula (anular perdería la elección).
- Al terminar el pull no hay recálculo especial: los kilos por lote se derivan al
  leer la tarjeta.

### Respaldo (`backup_service.dart`)

- `Transaction.toJson`/`fromJson` ya son la puerta única: el respaldo hereda la
  clave sin código nuevo.
- Respaldo **viejo** (sin la clave) → `null` → «sin lote».
- Puntero huérfano → se importa igual y cuenta como huérfano en el resumen
  (D12-A). No se convierte en otro lote.
- Borrar un cultivo borra sus siembras y deja los jornales sin cultivo: el
  puntero puede quedar apuntando a una siembra borrada; la lectura lo ignora.

---

## Casos borde

| Caso | Qué debe pasar |
|---|---|
| Jornal con kilos y dos lotes vivos, sin elegir | Guarda `null`; aviso naranja; no bloquea (SC-2) |
| Jornal con kilos, un solo lote vivo | Lote preseleccionado (D7-A); se puede pasar a «Sin lote» |
| Cambia la labor de «Cosechar» a otra | El puntero se limpia al guardar; si vuelve a «Cosechar», arranca en «Sin lote» |
| Cambia el cultivo | El puntero se limpia (el lote era de otro cultivo) |
| Cambia a gasto compartido (lote de terreno) | Kilos y puntero se limpian (el campo de kilos ni se muestra) |
| Borra la siembra del lote | El jornal queda con `cohort_sowing_id = null` y `pendingSync`; los kilos del cultivo no cambian (SC-10) |
| Lote renovado en el historial | Sin kilos en esa fila; `kg/planta` no se calcula (0 matas) |
| Puntero a una siembra de otro cultivo | Se conserva el dato, se lee «sin lote», no se reasigna (SC-12) |
| Puntero a una `resiembra` | No es un lote: se lee «sin lote» (el lote es la siembra-cabeza) |
| Dos jornales medidos el mismo día, mismo lote | Se suman al lote |
| Jornal medido con `harvestedKg` pero sin cultivo | No hay selector ni atribución (ya pasa hoy) |
| Cosecha manual guardada en el cultivo | Sin kg por lote (D10-A) |
| Todos los kilos sin lote | La tarjeta no gana ninguna cifra; el total del cultivo sí los cuenta |
| Datos viejos | `null` en todas las filas; ninguna tarjeta cambia |
| Sync sin la migración aplicada | Push falla con PGRST204; la fila queda `pendingSync`; la migración va antes |
| Respaldo viejo / huérfano | Entra `null` / se cuenta huérfano; no se reasigna |
| Venta con `cohort_sowing_id` en el JSON | Se limpia al entrar y se re-marca `pendingSync` (SC-15) |

---

## Impacto por archivo (previsto)

- `lib/models/transaction.dart`: campo, `copyWith` con centinela, JSON y las
  reglas de `fromJson`.
- `lib/models/cohort_kilos.dart` (nuevo): `cohortKilos` y `kgPerPlantCohort`.
- `lib/providers/transaction_provider.dart`: `addTransaction` gana
  `cohortSowingId`; `deleteSowing` limpia el puntero de los jornales; huérfanos
  del respaldo.
- `lib/providers/sync_provider.dart`: payload y lectura remota.
- `lib/screens/register_screen.dart`: selector, preselección, aviso y limpieza.
- `lib/screens/crops_screen.dart`: kg y kg/planta en la fila del lote.
- `lib/utils/format.dart`: `formatKg` (D11-A).
- `lib/screens/help_screen.dart`: párrafo `helpCohortKg`.
- `lib/l10n/app_es.arb`, `app_en.arb`, `gen-l10n` y `lib/l10n/generated/*`.
- `supabase/migrations/202610220001_add_transaction_cohort.sql`.
- `test/*`: ver plan de pruebas.

**No se tocan**: `lib/models/harvest.dart`, `lib/services/derived_harvests.dart`,
`lib/models/sowing.dart`, `lib/models/crop.dart`, `lib/screens/sowing_screen.dart`,
`lib/widgets/per_hectare_panel.dart`, Reportes, PDF, Excel, `tests` de etapa A.

---

## Plan de pruebas

### Rojos esperados (cada uno falla antes del cambio)

**Modelo — `test/transaction_test.dart`**

1. `'round-trip conserva cohort_sowing_id'` → el campo no existe (rojo por
   compilación).
2. `'JSON sin la clave entra null y no marca sucio'`.
3. `'copyWith puede volver el puntero a null y no lo pierde si no se pasa'`.
4. `'un ingreso con cohort_sowing_id se limpia y queda pendingSync'` (SC-15).
5. `'categoría distinta de mano_obra, labor distinta de cosechar, sin kilos, sin
   cultivo o con lote de terreno: el puntero se limpia'` (SC-11, SC-15).
6. `'un puntero a una siembra que no está se conserva (no se limpia en
   fromJson)'` (SC-12).

**Lectura — `test/cohort_kilos_test.dart` (nuevo)**

7. `'suma por lote: 250 al viejo y 180 al nuevo'` (SC-4).
8. `'ignora borrados, ingresos, otras labores, kg null o 0 y otros cultivos'`.
9. `'sin puntero o con puntero roto: no entra al mapa y no se reasigna'` (SC-12).
10. `'un puntero a una resiembra no es un lote'`.
11. `'cosecha manual guardada: el mapa queda vacío'` (SC-9).
12. `'kg/planta = kg ÷ vivas con 2 decimales; 0 vivas o sin kg → null'`
    (SC-5, SC-6, SC-8).
13. `'lote cerrado: el kg existe en el dato pero no se pinta'` (D8-A).

**Provider — `test/transaction_provider_cohort_test.dart` (nuevo)**

14. `'addTransaction guarda el puntero y pendingSync'` (SC-1).
15. `'updateTransaction cambia el lote y puede limpiarlo'` (SC-11).
16. `'deleteSowing limpia el puntero de los jornales y los kilos del cultivo no
    cambian'` (SC-10).
17. `'deleteSowing no toca jornales de otras siembras'` (guarda).

**Sync y respaldo — `test/sync_transaction_cohort_test.dart`,
`test/backup_transaction_cohort_test.dart`**

18. `'el payload trae cohort_sowing_id aunque sea null'` (SC-13) — **rojo real**:
    hoy no la trae.
19. `'un id que no es uuid sube como null'` (guarda `_uuidOrNull`).
20. `'round-trip JSON con y sin la clave'` (SC-13).
21. `'exportar e importar conserva el puntero; respaldo viejo → null'` (SC-13).
22. `'el puntero huérfano cuenta como huérfano y no se reasigna'` (D12-A).

**Migración — `test/migration_transaction_cohort_test.dart` (nuevo)**

23. `'el archivo existe y declara la columna en public.transactions'` (SC-14).
24. `'es idempotente: add column if not exists y create index if not exists'`.
25. `'la FK es a public.sowings(id) con on delete set null'`.
26. `'no hay backfill, ni update, ni drop, ni not null, ni harvests'`
    (rojo por ausencia del archivo).

**Formulario — `test/register_screen_cohort_test.dart` (nuevo)**

27. `'jornal Cosechar con dos lotes vivos muestra el selector con Sin lote'` —
    **rojo real**: hoy no existe.
28. `'con un lote vivo lo preselecciona y guarda su id'` (D7-A).
29. `'sin lotes vivos el selector no aparece y guarda null'` (SC-3).
30. `'con kilos y sin lote muestra el aviso y guarda igual'` (SC-2).
31. `'cambiar la labor limpia el lote y no lo restaura'` (SC-11).
32. `'editar un jornal precarga su lote; un lote cerrado se ofrece como
    renovado'` (D9-A).

**Tarjeta — `test/crops_screen_cohort_kilos_test.dart` (nuevo)**

33. `'el lote con 250 kg y 700 matas dice 250 kg y 0,36 kg/planta'` (SC-4, SC-5).
34. `'el lote sin kilos no muestra kg ni 0'` (SC-6).
35. `'una sola edad: la tarjeta es la de siempre'` (guarda de paridad, SC-7 —
    mismo número de widgets que hoy).
36. `'el lote renovado no muestra kg/planta ni kilos en el historial'` (SC-8).
37. `'con cosecha manual no hay kg por lote'` (SC-9).
38. `'los kg por lote no cambian el total del cultivo ni el chip de edades'`.

**Copy y guardas**

39. `test/l10n_atribucion_test.dart`: claves en ES/EN, mismos placeholders y en
    orden, sin «cohorte»/«cohort», cifras como `String` (SC-16).
40. **Guarda**: `harvests_intactos_test` y el kg/planta de Reportes/PDF/Excel
    siguen iguales (SC-15 y out of scope). Sin rojo posible: se declara guarda.
41. **Guarda**: `single_cohort_parity_test` de la etapa A sigue verde sin
    tocarse (SC-7).

Total previsto: **~35 rojos nuevos + 3 guardas**.

---

## Verificación manual (después del deploy)

1. Cultivo con 700/4 y 300/1 («2 edades»). Anotar un jornal de «Cosechar» con
   250 kg: aparece el selector con los dos lotes; elegir el viejo y guardar.
2. Repetir con 180 kg en el nuevo. Abrir la tarjeta y desplegar «2 edades»:
   `250 kg · 0,36 kg/planta` y `180 kg · 0,60 kg/planta`.
3. Anotar un tercer jornal de 50 kg **sin** lote: aviso visible y guarda; el lote
   de la tarjeta no cambia y el total del cultivo sube 50 kg.
4. Editar el jornal de 180 kg y cambiar la labor a «Abonar»: el selector
   desaparece; volver a «Cosechar» deja «Sin lote».
5. Borrar la siembra del lote viejo: el jornal queda sin lote y el total del
   cultivo no cambia.
6. Renovar todas las matas del lote viejo: en «Lotes renovados» no aparecen
   kilos.
7. Cultivo con una sola edad: la tarjeta se ve como antes.
8. Reportes, PDF y Excel: mismos números que antes de la etapa.
9. Sin señal: guardar un jornal con lote; queda `pendingSync` y al volver la red
   sube con el mismo puntero.

---

## Riesgos y divergencias declaradas

| Riesgo / divergencia | Prob. | Impacto | Decisión / mitigación |
|---|---|---|---|
| **Los kg por lote no suman el total del cultivo** (hay jornales sin lote y la venta no se reparte) | cierta | medio | Declarado: es «lo pesado por lote», no un reparto. El total no se toca y no se inventa una fila «sin lote» (fuera de alcance). El copy no promete sumas |
| **Una cosecha guardada a mano apaga los kg por lote** | baja | medio | D10-A: se ocultan para no mostrar una cifra fuera de los totales. Se conserva el dato |
| **Una sola edad no muestra kg por lote** | cierta | bajo | Paridad con la etapa A (SC-7). Se revisa en una etapa posterior si se pide |
| Los kilos de un lote renovado quedan invisibles | media | bajo | D8-A. El dato se conserva y el historial no gana columnas |
| El puntero a un lote cerrado se pierde al editar | baja | alto | D9-A: se ofrece la opción «renovado» y se conserva |
| **Un jornal por pesaje**: quien pesa dos lotes en un solo jornal no puede atribuirlos | media | bajo | Se documenta: dos pesajes, dos jornales. No se parte un `harvestedKg` |
| Migración sin aplicar en producción | media | alto | Se aplica **antes** del deploy; sin ella el push falla pero no se pierden datos |
| Divergencia de notación: la tarjeta usa el separador del idioma y Reportes/PDF siguen con `_numKg` (punto) | cierta | bajo | D11-A. Deuda declarada; unificar `_numKg` es otra tarea |
| El selector agrega un paso al jornal | media | bajo | Opcional, preseleccionado cuando hay un solo lote, aviso no bloqueante |
| Los tests de etapa A (paridad de una cohorte, copy sin kg) se rompen | baja | medio | `single_cohort_parity_test` no se toca; `l10n_cohortes_test` no incluye las claves nuevas (su lista es explícita) |

**Deuda explícita que queda abierta**

- Una venta mezclada sigue sin repartirse: no hay kg por lote «de la venta».
- No hay fila «sin lote» con los kilos no atribuidos.
- No hay costo por kilo ni ingreso por lote.
- Reportes, PDF y Excel no muestran nada por lote.
- Recepa/socola y asocio siguen sin representación.
- `_numKg` duplicado en Reportes y PDF (notación con punto) frente a `formatKg`
  de la tarjeta.

---

## Milestones

1. **Contrato y migración**: columna, `Transaction` + `fromJson`, SQL y su test
   de contrato.
2. **Lectura pura**: `cohortKilos`, `kgPerPlantCohort`, `formatKg` y sus tests.
3. **Jornal**: selector, preselección, aviso, limpieza, provider y `deleteSowing`.
4. **Tarjeta y copy**: fila del lote, Ayuda, ARB ES/EN, `gen-l10n`.
5. **Sync, respaldo y cierre**: payload, pull, huérfanos, guardas, gate, informe.

## Status

**READY** — D1–D6 cerradas del encargo; **D7–D12 cerradas en A** el 2026-10-22.
Listo para implementar.
