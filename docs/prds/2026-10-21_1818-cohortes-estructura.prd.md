---
status: APPROVED
created: 2026-10-21
updated: 2026-10-21
---

# Cohortes dentro de un cultivo — Etapa A «estructura» (PRD)

> De dónde sale: `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md`
> (§12 y §2), la decisión del 2026-10-21 (opción **C**, estructura primero) y
> las decisiones cerradas que se listan en D1–D11.
> Este documento **no implementa**: fija el alcance, el modelo, los cálculos y
> la verificación. El plan de tareas se escribe aparte.
> **Etapa B (atribuir cosechas) queda explícitamente fuera.**

## Objective

Que un cultivo pueda tener **varias edades** sin que la app invente números.
Hoy una siembra nueva **borra** las plantas, el área y la edad del lote viejo:
la app no distingue «un cafetal joven» de «un cafetal viejo con una parte
renovada». Esta etapa hace que cada siembra abra una **cohorte** (lote con su
fecha, sus matas y su área), que una siembra posterior pueda **reemplazar**
parte de la anterior, y que la edad se muestre **por cohorte**, sin promedios
inventados. Las cosechas no se tocan: los kilos siguen siendo del cultivo
entero.

El principio no cambia: **`null` → oculto, nunca 0 inventado**, y si un dato no
se puede calcular sin mentir, no se pinta.

## El caso (café, 5 ha y 1.000 matas)

Un cafetal de **5 ha con 1.000 matas de 7 años**. En 2026 renueva **1 ha con
300 matas** nuevas.

- Lo que el agricultor sabe: las matas viejas rinden ≈ 0,55 kg/mata; los
  plantines de 1 año todavía no producen; la hectárea renovada arranca de cero
  sin borrar la historia del resto.
- Lo que la app dice hoy: o **1.000** (si anotó el reemplazo como siembra: el
  lote viejo desaparece) o **1.300** (si lo anotó como resiembra: suma y mezcla
  edades), un **kg/planta** que divide por matas que no producen, y **una sola
  edad** que después de la siembra pasa a ser la del lote nuevo.
- Lo que debe decir: **1.000 matas y 5 ha** (700 + 300), **dos edades** (7 años
  y 0), y el kg/planta del cultivo rotulado como promedio de las dos edades.

## Success Criteria

Verificables de a uno, contra la app corriendo o contra una prueba automática.

- **SC-1 · Expansión.** Dado un cultivo de **1.000 matas / 5 ha**, WHEN se
  anota una siembra de **200 matas / 0,5 ha** con `replaces_plants = 0`, the
  system SHALL dejar el cultivo en **1.200 matas / 5,5 ha**, con **2 edades** y
  la cohorte vieja intacta en **1.000 / 5**.
- **SC-2 · Renovación parcial.** Dado **1.000 / 5 ha**, WHEN se anota una
  siembra de **300 / 1 ha** que reemplaza **300 matas y 1 ha** de la cohorte
  vieja, the system SHALL dejar la vieja en **700 matas / 4 ha** y la nueva en
  **300 / 1**, y el cultivo en **1.000 matas / 5 ha**.
- **SC-3 · Renovación total.** Dado **1.000 / 5 ha**, WHEN la siembra nueva de
  **300 / 1 ha** reemplaza **todas** las matas vivas, the system SHALL dejar la
  cohorte vieja en **0 matas**, conservarla en el historial como **«renovada»**,
  y mostrar el cultivo con **300 matas**, **1 edad** y **1,0 ha**.
- **SC-4 · Datos viejos, números quietos.** WHERE un cultivo ya existía con dos
  siembras, WHEN la app abre por primera vez después de actualizar, the system
  SHALL dejar `livePlants` y `areaHa` **exactamente** como estaban antes y
  marcar las siembras normalizadas como `pendingSync`.
- **SC-5 · La corrección manda.** WHERE el agricultor corrige un reemplazo
  normalizado a **expansión (0)**, the system SHALL NOT volver a normalizarlo en
  aperturas posteriores.
- **SC-6 · Resiembra a la cohorte vieja.** Dado un cultivo con **1.000** (vieja)
  + **300** (expansión), WHEN se anota una resiembra con **100 muertas** en la
  cohorte vieja, the system SHALL dejarla en **900** y el cultivo en **1.200**,
  y el selector de fecha de la pérdida SHALL arrancar en el **día de siembra de
  esa cohorte**, no en el de la última siembra.
- **SC-7 · Edad honesta.** WHERE el cultivo tiene **una** cohorte viva, the
  system SHALL mostrar la edad **igual que hoy**; WHERE tiene **dos o más**, the
  system SHALL mostrar **«N edades»** sin promedio y el desglose con la edad de
  cada cohorte.
- **SC-8 · Cohorte renovada.** WHERE una cohorte quedó en **0 matas**, the
  system SHALL conservarla, mostrarla como **«renovada»** en una sección de
  historial, y excluirla de los totales, del divisor de kg/planta y del conteo
  de «N edades».
- **SC-9 · Área.** WHERE **todas** las cohortes vivas tienen área, the system
  SHALL usar la **suma** como `crop.areaHa`; WHERE falta el área de alguna, the
  system SHALL conservar el área manual y avisar **sin bloquear** si las
  cohortes medidas ya la superan.
- **SC-10 · No se puede reemplazar de más.** IF el agricultor escribe más matas
  de las que la cohorte elegida tiene vivas, the system SHALL bloquear el
  guardado con un mensaje que dice cuántas hay y ofrecer **«Todas (N)»**.
- **SC-11 · Sincronización.** WHEN una siembra se empuja, the system SHALL
  enviar `replaces_plants`, `replaces_area_ha` y `cohort_sowing_id` **siempre**,
  incluido `null`; un viaje de ida y vuelta por JSON y por respaldo SHALL
  devolver los mismos valores.
- **SC-12 · Migración.** La migración SHALL ser **aditiva**, usar
  `if not exists`, no tocar `harvests` ni `transactions`, y aplicarse sobre una
  base con filas **sin backfill**.
- **SC-13 · Un cultivo de una cohorte no cambia.** WHERE el cultivo tiene una
  sola siembra, the system SHALL devolver los mismos kg/ha, kg/planta, promedio
  histórico, costo por kilo y filas de PDF/Excel que hoy (guarda automática).
- **SC-14 · Cosechas intactas.** The system SHALL NOT agregar `sowing_id` a
  `harvests`, ni un selector de cohorte al vender o cosechar, ni kg/planta por
  cohorte.
- **SC-15 · Lenguaje.** El copy visible SHALL decir **«lote»**, nunca
  «cohorte»; SHALL existir en **ES y EN** con las mismas claves.
- **SC-16 · Gate.** `flutter analyze` (proyecto entero, `tool/` incluido) limpio
  y `flutter test` en verde, con los 1120 tests actuales de `main` (`84ff1e1`)
  más los nuevos.

## Out of Scope

- **Cosechas atribuidas a una cohorte** (`harvests.sowing_id`, selector al
  vender, lista «sin cohorte», kg/planta por cohorte): etapa B.
- **Repartir** los kilos de una venta mezclada por edad o por área.
- **Recepa/socola**: la mata sigue viva; no es siembra ni resiembra.
- **Asocio** (dos cultivos en la misma área) y hectáreas equivalentes.
- **`SowingKind` nuevo** y **`closed_at`**: una cohorte se cierra cuando sus
  matas vivas llegan a 0.
- **Migración de cosechas** y cambio alguno en `transactions.sowing_id`.
- **Editar o borrar en grupo** siembras.
- **Exportes nuevos**: PDF/Excel no cambian de diseño (solo heredan los
  totales ya corregidos).
- Tocar `HarvestDestination.almacenado`, la pantalla Cosechar, el renderer, las
  fuentes o `NOTICES`.

## Assumptions

- El agricultor sabe —o puede estimar— **cuántas matas** hay en el lote que
  renueva. Si no lo sabe, usa la precarga por área y la corrige después; el dato
  queda editable y no bloquea.
- Las migraciones de Supabase las aplica el usuario **antes** de desplegar.
- No hay datos de producción donde una siembra posterior a la primera haya sido
  una **expansión** y los números de hoy dependan de que la vieja desapareciera
  (si los hay, se corrigen a 0 y los totales suben: es la corrección).
- Un mismo cultivo no tiene dos cohortes con la misma área física (asocio queda
  fuera).

## Users

- **Primario**: el productor de café con un lote viejo y una parte renovada, que
  anota siembras y pérdidas desde el teléfono, muchas veces sin señal.
- **Secundario**: quien carga los datos por él (familiar, técnico) y necesita
  que el formulario pregunte lo mínimo.
- **No es para**: quien quiere rendimiento por lote pesado por separado
  (etapa B/C) ni quien practica recepa y espera anotarla como siembra.

## Constraints

- Local-first: todo funciona sin red y sincroniza después.
- Sin `git add -A`; stageo explícito; LF en archivos del repo.
- Copy ES/EN; `lib/l10n/app_es.arb` es el template; `gen-l10n` después y
  `lib/l10n/generated/` se commitea.
- Gate antes de commit y deploy: `flutter analyze` + `flutter test`.
- Cada cambio con su test; cuando no hay rojo posible, se declara **guarda**.
- Migración aditiva, `if not exists`, sin backfill; se aplica antes del deploy.

---

## Decisiones

### D1 — La siembra **es** la cohorte (opción C)

No se crea entidad nueva (**B**) ni se parte el cultivo en dos (**E**). En la
finca la cosecha de lotes de distinta edad **casi siempre se mezcla**: obligar a
elegir un lote en la venta (E) atribuye mal o fuerza a inventar kilos, y no hay
un total «Café» que reciba la venta mezclada.

La cohorte se identifica por el `id` de su siembra. Una **resiembra** es un
evento *dentro* de una cohorte, no una cohorte nueva. Una **siembra** posterior
abre otra cohorte y, si corresponde, resta matas a la anterior. Si algún día
hace falta la entidad de B, esos ids ya son estables y se adoptan sin migrar.

### D2 — Renovación: `replaces_plants` y `replaces_area_ha`

La siembra nueva dice **cuánto reemplaza**, no «qué porcentaje»:

| `replaces_plants` | Significado | Efecto |
|---|---|---|
| `null` | dato viejo o siembra inicial | no resta nada |
| `0` | **expansión** explícita | la cohorte vieja sigue igual |
| `> 0` y `< vivas` | **renovación parcial** | resta esa cantidad |
| `= vivas` | **renovación total** | la vieja queda en 0 (historial) |

`replaces_area_ha` (nullable) resta hectáreas a la cohorte vieja cuando las dos
áreas se conocen. Sin área en la vieja, **no se inventa**: el área de la vieja
queda `null` y el cultivo cae a la regla de D6.

`0` y `null` no son lo mismo: `0` es una respuesta del agricultor (expansión) y
se muestra como tal; `null` es «todavía no dijo». La normalización de D9 solo
toca los `null`.

### D3 — Puntero explícito a la cohorte (`cohort_sowing_id`)

> Aprobado por el usuario el 2026-10-21.

**Columna adicional, mínima e imprescindible.** Con más de una cohorte abierta,
la decisión ya tomada dice que **él elige** cuál se reemplaza y a cuál pertenece
la resiembra. Sin un puntero, esa elección no se puede guardar:

- una resiembra no se puede resolver «por la cohorte más nueva» porque el caso
  central de la etapa es justamente reponer matas en la **vieja** después de la
  siembra nueva (D8);
- suponer «la más antigua» al renovar cambia los números si él eligió otra, y
  depende del orden de la lista.

Una sola columna, dos lecturas:

| Registro | `cohort_sowing_id` significa |
|---|---|
| `siembra` (renovación) | la cohorte que **reemplaza** (parcial o total) |
| `resiembra` | la cohorte **a la que pertenece** |
| cualquiera en `null` | sin puntero: expansión, siembra inicial, o dato viejo |

`on delete set null`: borrar la cohorte no borra ni reescribe la otra siembra.
Si el puntero no resuelve a una cohorte de ese cultivo, **no se resta nada** y
el registro se lista como «sin lote»; nunca se elige un sustituto por parecido.

### D4 — Sin `closed_at`: cerrada cuando las vivas llegan a 0

Una cohorte está cerrada cuando `livePlants == 0`. No hay fecha de cierre ni
estado que mantener sincronizado aparte: el estado se **deriva** de las matas.
Sus cosechas —cuando existan, etapa B— no se borran. Una cohorte cerrada **no se
puede revivir**: una resiembra no puede apuntarle (el formulario solo ofrece
cohortes abiertas) y, si un dato viejo lo hiciera, se ignora y se marca «sin
lote».

### D5 — `recomputeCropState` suma cohortes y resta reemplazos

Hoy una siembra **reemplaza** el total; una resiembra **suma**. Ahora:

1. se recorre por día (siembra antes que resiembra, igual que hoy);
2. cada **siembra** abre una cohorte con sus matas y su área;
3. si trae reemplazo, resta matas (y área) a la cohorte apuntada;
4. cada **resiembra** ajusta **su** cohorte: `vivas − muertas + nuevas`;
5. `crop.livePlants` = **suma de las cohortes abiertas** (las de 0 aportan 0);
6. el resultado es determinista: no depende del orden de la lista guardada.

Se mantiene la firma pública de `recomputeCropState` (mapa por cultivo) y se
agrega una función pura `cropCohorts(cropId, sowings)` para la UI y las edades.

### D6 — `areaHa` del cultivo: suma si se puede, manual si no

Decisión de este PRD (supera a §6 del análisis, que decía «no sumar»: eso valía
para lotes partidos en cultivos distintos, no para cohortes del mismo lote):

- **Todas** las cohortes vivas tienen área → `crop.areaHa` = **suma** (redondeada
  a 2 decimales, para no arrastrar `5,000000001`).
- **Falta** el área de alguna → se conserva el **valor manual** del cultivo y se
  avisa sin bloquear: «No todos los lotes tienen área; el área del cultivo es la
  que escribiste». Si la suma de las medidas ya supera la manual, el aviso dice
  las dos cifras.
- Sin cohortes vivas → no se toca el área.

Synth: en asocio o traslape la suma mentiría, pero el asocio está fuera de
alcance y un aviso no bloqueante ya cubre el caso raro.

### D7 — Edad por cohorte; «N edades»; ningún promedio

- La edad se calcula **desde la siembra que abrió cada cohorte**.
- **Una** cohorte viva → se muestra igual que hoy (misma clave, mismo lugar).
- **Dos o más** → el encabezado dice **«N edades»**; el desglose muestra la edad
  de cada cohorte. **No se promedia**: un promedio de edades no es la edad de
  ningún lote.
- Una **resiembra no reinicia** la edad (la cohorte sigue siendo la misma).
  Una **renovación total** sí, porque la cohorte vieja queda en 0 y la nueva
  tiene su propia fecha.
- Cultivo **anual** → la edad sigue oculta (`null`), como hoy.
- Siembra con fecha **futura** → esa cohorte no tiene edad todavía (`null`).

### D8 — Resiembra y pérdidas atadas a la cohorte

- Con **una** cohorte abierta, se asigna sola (no hay ambigüedad) y se muestra
  en texto, sin selector.
- Con **varias**, se elige. La elección se guarda en `cohort_sowing_id`.
- `lossEarliestDate` pasa a ser el **día de siembra de esa cohorte**, no el de la
  última siembra del cultivo. Es parte de esta etapa porque, con renovación
  parcial, la cohorte vieja sigue viva y puede recibir pérdidas **después** de la
  siembra nueva.
- Sin cohorte abierta (todo renovado), una resiembra **no cambia** las matas del
  cultivo, igual que hoy cuando no hay siembra previa; se avisa y se ofrece
  anotarla como siembra.

### D9 — Datos viejos: normalizar sin mover números

Al abrir por primera vez después de actualizar, cada cultivo se recorre en orden
cronológico. La **primera siembra** queda como está. Cada siembra **posterior**
se marca como reemplazo de las matas que quedaban vivas en ese momento:

- `replaces_plants` = matas vivas de las cohortes abiertas en ese instante;
- `replaces_area_ha` = área de la cohorte apuntada, si se conoce;
- `cohort_sowing_id` = la cohorte con matas vivas (si hay una sola, esa);
- todo con `pendingSync: true` para que suba.

Así los números actuales **no se mueven** (SC-4). Si alguna era expansión, él la
corrige a **0** y los totales suben: es la corrección, no una pérdida.

**Idempotencia sin bandera**: se considera «vieja» solo la siembra posterior a la
primera cuyos **tres** campos están en `null`. En cuanto él corrige (aunque sea a
`0`), la fila deja de tocarse (SC-5). No hay flag que se pueda desincronizar
entre dispositivos ni normalización doble.

Las **resiembras** viejas no se normalizan: sin puntero se resuelven por fecha
(la cohorte más reciente ese día), que es exactamente la semántica anterior.

### D10 — La cohorte en 0 se conserva como «renovada»

No se borra: tiene historia (siembra, gastos vinculados, pérdidas) y borrarla
dejaría huérfanos. Se muestra en una sección **«Lotes renovados»**, colapsada,
con la fecha en que se renovó. No cuenta en totales, ni en el divisor de
kg/planta, ni en «N edades».

### D11 — Lo que no se toca

`SowingKind` (sigue habiendo solo `siembra` y `resiembra`), `closed_at`,
`harvests` (ni columna ni selector), `transactions.sowing_id` (ahí significa
«gasto de esa siembra»), la pantalla Cosechar, `HarvestDestination.almacenado`,
los exportes y el renderer.

---

## Modelo de datos

### Columnas nuevas en `sowings` (3)

| Columna | Tipo | Null | Significado |
|---|---|---|---|
| `replaces_plants` | `integer` | sí | matas de la cohorte apuntada que esta siembra reemplaza. `0` = expansión |
| `replaces_area_ha` | `numeric` | sí | hectáreas de la cohorte apuntada que reemplaza |
| `cohort_sowing_id` | `uuid` | sí | siembra-cabeza de la cohorte afectada (D3) |

En el modelo Dart (`Sowing`): `int? replacesPlants`, `double? replacesAreaHa`,
`String? cohortSowingId`, con `toJson`/`fromJson` (`replaces_plants`,
`replaces_area_ha`, `cohort_sowing_id`) y `copyWith` **con centinela** para los
tres (hay que poder volver a `null`, igual que `lostPlants` y `reason`).

**Puerta única de entrada** (`Sowing.fromJson`), en el mismo estilo que la regla
`sucio` de hoy:

- `replaces_plants` o `replaces_area_ha` negativos → `null` + `pendingSync`.
- `replaces_area_ha` sin `replaces_plants` → `null` (un área sin matas no
  significa nada).
- `kind == resiembra` → `replaces_plants` y `replaces_area_ha` se limpian; el
  puntero **sí** se conserva.
- `kind == siembra` con `cohort_sowing_id == null` y `replaces_plants > 0` →
  se conserva (el puntero puede faltar por un borrado remoto); el cálculo no
  resta nada y la lista lo marca «sin lote».

### Migración exacta propuesta

`supabase/migrations/202610210001_add_sowings_cohorts.sql`

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
- La FK es **auto-referente**: el destino es una siembra **anterior**, que por
  el orden de push ya está arriba. Si no lo estuviera, el push falla y la fila
  queda `pendingSync` (no se pierde).
- La base **no** valida «no reemplazar más de lo vivo»: eso depende del estado
  de las otras filas y se valida en la app (SC-10).

### Por qué no hay tabla nueva

Una tabla `cohorts` obligaría a migrar datos, sincronizarla, respaldarla y
mantener dos fuentes de verdad para la misma fecha. El `id` de la siembra ya es
estable y ya viaja; alcanza como identidad de cohorte.

---

## Cálculo

### Función pura de cohortes

`cropCohorts(cropId, sowings)` devuelve, por cohorte:
`{sowingId, date, livePlants, areaHa, closedOn?}`.

Algoritmo (determinista, por día, siembra antes que resiembra, y a igualdad
`date`/`kind`, por `id`):

```
para cada siembra en orden:
  si es siembra:
    abre cohorte {id: s.id, fecha: s.date, vivas: s.plants, área: s.areaHa}
    si s.replacesPlants > 0:
      t = cohorte(s.cohortSowingId) ?? la más antigua abierta anterior a s.date
      si t existe:
        t.vivas = max(0, t.vivas − s.replacesPlants)
        si s.replacesAreaHa != null y t.área != null:
          t.área = max(0, t.área − s.replacesAreaHa)
  si es resiembra:
    t = cohorte(s.cohortSowingId) ?? la más reciente con fecha ≤ s.date
    si t existe y t.vivas > 0:
      t.vivas = max(0, t.vivas − muertas + nuevas)
    si t existe y t.vivas == 0:   // no se revive una cohorte cerrada
      se ignora y se lista como «sin lote»
```

- **No hay sustitución por parecido**: si el puntero no resuelve, no se resta.
- **Sin retroactividad**: un puntero a una cohorte con fecha posterior a la
  siembra se ignora.
- La cohorte **no se reordena** al restar: conserva su fecha de nacimiento.

### Agregado del cultivo

- `livePlants` = suma de `livePlants` de las cohortes abiertas.
- `areaHa` = regla D6.
- `nEdades` = cantidad de cohortes con `livePlants > 0` (para «N edades»).
- `closedOn` de una cohorte = fecha de la siembra que la dejó en 0 (la que trae
  `cohort_sowing_id` apuntándole y `replaces_plants` igual a sus vivas previas).
  Si no se puede determinar, se muestra «Renovada» sin fecha: no se inventa.

### Ejemplos numéricos

**1 · Expansión.** Vieja 1.000 / 5 ha (2020). Siembra 200 / 0,5 ha (2026),
`replaces_plants = 0`.

| Cohorte | Matas | Área | Edad |
|---|---|---|---|
| 2020 | 1.000 | 5,0 | 6 |
| 2026 | 200 | 0,5 | 0 |
| **Cultivo** | **1.200** | **5,5** | **2 edades** |

**2 · Renovación parcial (el caso).** Vieja 1.000 / 5 ha. Siembra 300 / 1 ha,
`replaces_plants = 300`, `replaces_area_ha = 1`.

| Cohorte | Matas | Área | Edad |
|---|---|---|---|
| 2020 | 700 | 4,0 | 6 |
| 2026 | 300 | 1,0 | 0 |
| **Cultivo** | **1.000** | **5,0** | **2 edades** |

Precarga por área: `round(1000 × 1 / 5) = 200`; él escribe **300** porque el lote
nuevo es más denso. Por eso el campo es editable y no una regla.

**3 · Renovación total.** Vieja 1.000 / 5 ha. Siembra 300 / 1 ha,
`replaces_plants = 1.000`, `replaces_area_ha = 5`.

| Cohorte | Matas | Área | Estado |
|---|---|---|---|
| 2020 | 0 | 0,0 | renovada (historial) |
| 2026 | 300 | 1,0 | abierta |
| **Cultivo** | **300** | **1,0** | **1 edad** |

**4 · Resiembra en la cohorte vieja.** 1.000 (2020) + 300 (2026, expansión).
Resiembra en la de 2020 con 100 muertas y 0 nuevas → vieja **900**, cultivo
**1.200**. El selector de fecha de la pérdida arranca el **2020**, no el 2026.

**5 · Datos viejos.** S1 2020: 1.000 / 5 ha. S2 2026: 300 / 1 ha. Hoy:
`livePlants = 300`, `areaHa = 1`. Normalizado: S2 con
`replaces_plants = 1.000`, `replaces_area_ha = 5`, `cohort_sowing_id = S1` →
vieja 0, nueva 300 → **300 / 1,0 ha**. Idéntico a hoy (SC-4).

**6 · Área incompleta.** Vieja 1.000 **sin área** + nueva 300 / 1 ha. La vieja
queda sin área → no se suma; el cultivo conserva su área manual (5,0) y avisa
«Los lotes con área suman 1,0 ha; el cultivo dice 5,0 ha».

### Qué NO cambia en los cálculos

`yieldPerPlant` sigue siendo kg del cultivo ÷ `crop.livePlants` (ahora la suma de
cohortes), `yieldPerArea` usa `crop.areaHa`, `historicalYield` sigue con área y
plantas **actuales**, y los exportes leen los mismos campos. En el panel por
hectárea solo se agrega el rótulo «promedio de N edades».

---

## UX

### 1 · Formulario de siembra (`sowing_screen.dart`)

Al elegir **Siembra** en un cultivo que ya tiene cohortes vivas, aparece una
sección nueva (plegable, cerrada por defecto cuando el cultivo no tiene
cohortes):

> **¿Qué pasa con las matas que ya tenés?**
> ( ) Amplío el cultivo — no reemplazo nada
> (•) Renuevo una parte

- **Amplío** → `replaces_plants = 0`, `cohort_sowing_id = null`. No se pide nada
  más.
- **Renuevo** → se despliega:
  - **Lote que renuevo** (selector) solo si hay **más de una** cohorte viva; con
    una, se muestra como texto.
  - **Matas que reemplaza** (numérico, obligatorio, > 0). Debajo, la precarga:
    «Calculado por área: 200 de 1.000» cuando las dos áreas existen; si no,
    «Sin área en el lote viejo: decime cuántas matas».
  - Atajo **«Todas (1.000)»** que pone exactamente las vivas.
  - **Área que reemplaza (ha)** (opcional; se precarga con el área nueva si la
    vieja la tiene).
- Si elige **«Renuevo»** y no escribe matas, no se puede guardar: es la única
  validación dura de la etapa.
- Editar una siembra existente muestra los mismos campos precargados; cambiar a
  «Amplío» guarda **0** explícito (nunca `null`).
- El aviso de resiembra sin muertas (T12 existente) no cambia.

### 2 · Resiembra

- Con **una** cohorte viva: texto «Lote del 12/03/2020 · 6 años · 1.000 matas».
- Con **varias**: selector **«Lote»**; por defecto, la **más antigua viva** (la
  que se repone en la práctica), no la más nueva. La elección se recuerda en el
  formulario mientras esté abierto.
- Sin cohortes vivas: aviso «No hay un lote vivo donde reponer; esto no cambia
  las matas del cultivo» + botón **«Anotar como siembra»**.
- El selector de fecha de la pérdida (`lossEarliestDate`) usa la fecha de la
  cohorte elegida. Al cambiar de lote, la fecha mínima se mueve y una pérdida
  anterior se marca y se corrige **antes** de guardar (aviso, no bloqueo duro).
- `crop_loss_dialog.dart` (pérdidas fuera de la pantalla de siembras) reutiliza
  el mismo selector.

### 3 · Lista de cohortes en el cultivo (`crops_screen.dart`)

En la tarjeta del cultivo, cuando hay **más de una** cohorte:

- Encabezado: chip **«2 edades»** (o N) en lugar de la edad única. Al tocarlo,
  se despliega la lista.
- Cada fila: `12/03/2020 · 6 años · 700 matas · 4,0 ha` y el estado
  (**Abierta** / **Renovada**).
- Sección **«Lotes renovados»** al final, colapsada, con las cohortes de 0
  matas: `12/03/2020 · renovada en 05/2026`.
- Con **una** cohorte, la tarjeta se ve **exactamente** como hoy.

### 4 · Reportes (`per_hectare_panel.dart`)

- La fila sigue siendo **por cultivo**.
- Si hay más de una edad, junto a `yieldPerPlant` se agrega
  **«promedio de N edades»** (el número no cambia de fórmula).
- El kg/planta por cohorte **no aparece**: no hay kilos atribuidos.

### 5 · Ayuda

Párrafo nuevo en `help_screen.dart`: qué es «renovar una parte», por qué se
preguntan las matas y por qué la edad del cultivo pasa a ser «N edades». Sin la
palabra «cohorte».

---

## Copy ES/EN (propuesto)

Claves nuevas en `lib/l10n/app_es.arb` (template) y `app_en.arb`. Se reutiliza
la clave de edad existente para los años.

| Clave | ES | EN |
|---|---|---|
| `sowingWhatHappensOldPlants` | ¿Qué pasa con las matas que ya tenés? | What happens to the plants you already have? |
| `sowingExpandOption` | Amplío el cultivo: no reemplazo nada | I'm expanding: nothing is replaced |
| `sowingRenewOption` | Renuevo una parte | I'm renewing part of it |
| `sowingRenewHint` | Las matas del lote viejo bajan y las nuevas suman. El total no se infla. | The old lot's plants go down and the new ones add up. The total doesn't inflate. |
| `sowingReplaceCohortLabel` | Lote que renuevo | Lot I'm renewing |
| `sowingReplacePlantsLabel` | Matas que reemplaza | Plants being replaced |
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
| `cohortsCount` | {count} edades | {count} ages |
| `cohortOpen` | Abierta | Open |
| `cohortRenewed` | Renovada | Renewed |
| `cohortRenewedOn` | Renovada en {date} | Renewed on {date} |
| `cohortsHistoryTitle` | Lotes renovados | Renewed lots |
| `cohortsAreaFallback` | No todos los lotes tienen área: el área del cultivo es la que escribiste. | Not every lot has an area: the crop area is the one you entered. |
| `cohortsAreaMismatch` | Los lotes con área suman {sum} ha; el cultivo dice {manual} ha. | The lots with an area add up to {sum} ha; the crop says {manual} ha. |
| `perHaAgesAverage` | promedio de {count} edades | average of {count} ages |
| `helpCohortsRenew` | Renovar una parte resta esas matas del lote viejo y abre uno nuevo con su propia edad. La historia del viejo no se borra. | Renewing part of a lot subtracts those plants from the old lot and opens a new one with its own age. The old history isn't erased. |

Reglas de copy: **«lote»**, no «cohorte»; **«matas»** para café (el resto de la
app ya usa «plantas»); nunca «0» para un dato ausente.

---

## Sincronización y respaldo

### Push (`sync_provider.dart`)

`buildSowingPayload` agrega **siempre** las tres claves, incluido `null`:

```dart
'replaces_plants': s.replacesPlants,
'replaces_area_ha': s.replacesAreaHa,
'cohort_sowing_id': _uuidOrNull(s.cohortSowingId),
```

- El orden de push ya pone `sowings` antes de `harvests`; dentro de `sowings` no
  hay orden explícito, pero el destino de la FK es una siembra **anterior**.
  Si el destino todavía no subió, el push falla y la fila queda `pendingSync`:
  se reintenta y no se pierde.
- Un cliente viejo (sin las claves) sube `null`: se lee como expansión/dato
  viejo; no rompe.

### Pull

- `Sowing.fromJson` acepta las tres claves ausentes (`null`).
- Si llega un `cohort_sowing_id` que aún no está en local (push/pull en
  desorden), **se conserva** y el cálculo lo ignora hasta que la cohorte llegue.
  No se anula: anularlo perdería la elección del agricultor.
- Al terminar un pull se recalcula el estado de los cultivos afectados (mismo
  camino que hoy tras editar siembras).

### Respaldo (`backup_service.dart`)

- `Sowing.toJson`/`fromJson` ya son la puerta única: el respaldo hereda las tres
  claves.
- Respaldo **viejo** (sin claves) → entran en `null` → la normalización de D9 las
  trata como viejas y no mueve números.
- Referencia huérfana (`cohort_sowing_id` a una siembra que no vino) → se importa
  igual, el conteo de huérfanos la incluye, y se trata como «sin lote». **No** se
  convierte en reemplazo de otra cohorte.
- `replaces_plants > 0` sin puntero válido → no resta (D3); se lista «sin lote».

---

## Casos borde

| Caso | Qué debe pasar |
|---|---|
| Resiembra sin muertas anotadas | Se suma igual (comportamiento actual); el aviso T12 sigue; el kg/planta queda diluido y el copy lo dice |
| Dos siembras el mismo día | Orden fijo: por día, siembra antes que resiembra, y a igualdad por `id`. El puntero explícito manda: no se adivina |
| Siembra con fecha futura | Abre cohorte; su edad es `null` (oculta); el reemplazo se aplica igual porque es un dato, no un pronóstico |
| Reemplazo mayor a las vivas | Se bloquea el guardado (SC-10); «Todas (N)» pone exactamente las vivas |
| Editar `replaces_plants` | Recalcula; 0 = expansión (la vieja recupera lo que se le había restado); subir por encima de las vivas se bloquea |
| Borrar la siembra **nueva** | Su reemplazo deja de aplicar: la vieja recupera matas y área. Sus gastos se desvinculan (ya pasa) |
| Borrar la siembra **vieja** | Las siembras que le apuntaban quedan con puntero `null` (local, `pendingSync`); dejan de restar. **Avisar antes**: los totales cambian |
| Borrar el cultivo | Se borran siembras y cosechas como hoy; las transacciones se desvinculan |
| Cohorte en 0 con historia | Se conserva como «renovada»; fuera de totales, divisor y «N edades» (SC-8) |
| Resiembra apuntando a una cohorte en 0 | No se revive: se ignora y se lista «sin lote» (D4) |
| Todas las cohortes en 0 | `livePlants = 0` es un hecho, no un dato faltante: se muestra «sin matas vivas»; no se oculta |
| Cultivo anual | Cohortes válidas (una por ciclo); la edad sigue oculta |
| Área faltante en una cohorte | Se conserva el área manual y se avisa (D6, SC-9) |
| Datos viejos con dos siembras | Normalización que deja los números iguales (SC-4) |
| Datos viejos donde la segunda era expansión | Se normaliza como reemplazo; él la corrige a 0 y los totales suben (corrección, no pérdida) |
| Resiembra vieja antes de toda siembra | No cuenta (igual que hoy: sin contador previo no hay nada que ajustar) |
| Sync sin la migración aplicada | El push falla con columna inexistente; la fila queda `pendingSync`. La migración va **antes** del deploy |
| Respaldo viejo | Las claves entran `null`; normalización; sin cambio de números |
| Asocio / área compartida | La cohorte puede tener área propia; no se usa para repartir costos ni se suma dos veces |

---

## Impacto por archivo (previsto)

- `lib/models/sowing.dart`: tres campos + JSON + `copyWith` con centinela;
  `cropCohorts`; `recomputeCropState` con la nueva regla; `lossEarliestDate` con
  cohorte; normalización de datos viejos; validadores puros.
- `lib/models/crop.dart`: `edadesDeCohorte` (y `edadDeCrop` como envoltorio para
  no romper llamadas); la edad única se mantiene para una cohorte.
- `lib/providers/transaction_provider.dart`: `addSowing`/`updateSowing` con los
  tres parámetros; `deleteSowing` desvincula `cohort_sowing_id` en local;
  `_recomputeCropsFromSowings` con la regla de área (D6); normalización al
  cargar; recálculo tras pull.
- `lib/providers/sync_provider.dart`: `buildSowingPayload` + lectura remota.
- `lib/screens/sowing_screen.dart`: sección expansión/renovación, selectores,
  precarga, validación, resiembra por lote.
- `lib/screens/crops_screen.dart`: chip «N edades», lista de cohortes, historial.
- `lib/widgets/crop_loss_dialog.dart`: selector de lote (pérdidas).
- `lib/widgets/per_hectare_panel.dart`: rótulo «promedio de N edades».
- `lib/screens/help_screen.dart`: párrafo de renovación por partes.
- `lib/services/backup_service.dart`: sin código nuevo si el JSON alcanza; solo
  el conteo de huérfanos para el puntero.
- `lib/l10n/app_es.arb` / `app_en.arb` + `C:\flutter\bin\flutter.bat gen-l10n`
  + `lib/l10n/generated/*`.
- `supabase/migrations/202610210001_add_sowings_cohorts.sql`.
- `test/*`: ver plan de pruebas.

**No se toca**: `lib/models/harvest.dart`, `lib/screens/harvest_screen.dart`,
`lib/screens/register_screen.dart` (venta), `harvests` en la base,
`transactions.sowing_id`, `lib/services/derived_harvests.dart`.

---

## Plan de pruebas

### Unitarias puras (sin widgets, sin base)

`test/sowing_cohorts_test.dart`

1. Una siembra → una cohorte con sus matas y área.
2. Expansión (0) → vieja intacta, total suma.
3. Parcial 300/1 sobre 1.000/5 → 700/4 + 300/1 (SC-2).
4. Total 1.000 → vieja 0, cultivo 300 (SC-3).
5. `replaces_plants` mayor a las vivas → se recorta a 0 y no queda negativo.
6. Puntero a otra cohorte → resta a esa, no a la más antigua.
7. Puntero inexistente → no resta y queda «sin lote».
8. Puntero con fecha posterior → se ignora.
9. Resiembra por puntero a la vieja después de una siembra nueva → 900 + 300.
10. Resiembra sin puntero → cae en la más reciente del día.
11. Resiembra sobre cohorte en 0 → no la revive.
12. Dos siembras el mismo día → determinista y con puntero explícito.
13. Área: todas conocidas → suma; una `null` → `null` (D6).
14. Área: resta con piso en 0; vieja sin área → sigue `null`.
15. `nEdades` cuenta solo abiertas.
16. Edad por cohorte: 2020 y 2026; futura → `null`; anual → `null`.
17. `lossEarliestDate` con cohorte → fecha de esa cohorte.

`test/sowing_legacy_normalization_test.dart`

18. S1 1.000/5 + S2 300/1 → normaliza y el total queda **300/1** (SC-4).
19. S1 + resiembra + S2 → total igual al de hoy.
20. Tres siembras → cadena S1→S2→S3 con total igual.
21. Ya normalizada (valores no nulos) → no se vuelve a tocar.
22. Corrección a 0 → sigue en 0 tras otra pasada (SC-5).
23. Resiembra vieja sin puntero → no se normaliza y resuelve por fecha.

### Provider

`test/transaction_provider_sowing_test.dart`

24. `addSowing` con reemplazo → cohortes y `crop.livePlants`/`areaHa` correctos.
25. `updateSowing` cambiando `replacesPlants` a 0 → la vieja recupera.
26. `deleteSowing` de la vieja → punteros `null` y `pendingSync` en las
    afectadas.
27. `deleteSowing` de la nueva → la vieja recupera matas.
28. Toda escritura deja `pendingSync: true` (siembras y cultivos).
29. Área con una cohorte sin área → conserva la manual y **no** la pisa.

### Widget

30. Formulario: cultivo con cohortes → aparece la pregunta; «Amplío» guarda 0.
31. «Renuevo» sin matas → no guarda; con matas → guarda el valor.
32. Precarga por área visible con las dos áreas; ausente sin área.
33. «Todas (N)» pone exactamente N.
34. Resiembra con dos cohortes → selector; con una → texto.
35. Tarjeta del cultivo: 2 cohortes → «2 edades» y desglose; 1 → igual que hoy.
36. Historial: cohorte en 0 aparece como «renovada» y no en los totales.

### Migración

37. `test/migration_sowings_cohorts_test.dart` (mismo patrón que
    `test/migration_harvested_kg_test.dart`): el archivo existe, usa
    `add column if not exists`, no contiene `update`/`backfill` sobre `sowings`,
    no menciona `harvests` ni `transactions`.

### Sync y respaldo

38. `buildSowingPayload` incluye las tres claves **siempre**, con `null`.
39. Roundtrip JSON con y sin las claves.
40. Respaldo: exportar/importar conserva los valores; respaldo viejo → `null`.
41. Huérfano: puntero a siembra ausente → se importa «sin lote», no se reasigna.

### Guardas

42. **Paridad de una cohorte** (`test/single_cohort_parity_test.dart`): fixture
    con un cultivo de una siembra y su resiembra; congelar kg/ha, kg/planta,
    promedio histórico, costo por kilo, PDF y Excel (SC-13).
43. **Cosechas intactas**: el esquema de `harvests` no gana columnas y
    `Harvest` no gana campos (SC-14) — test de estructura/JSON.
44. **Copy**: todas las claves nuevas existen en `app_es.arb` y `app_en.arb` con
    los mismos placeholders (SC-15).

---

## Verificación manual (después del deploy)

1. **Antes de actualizar**: anotar en un cultivo existente `livePlants` y
   `areaHa`. Abrir la versión nueva → los números **no cambian**.
2. Ese cultivo, si la segunda siembra era expansión, editarla a **«Amplío»** →
   las matas suben y aparecen **2 edades**.
3. Cultivo de 5 ha / 1.000 matas: renovar 1 ha con 300 matas, reemplazando 300 →
   queda **700/4 + 300/1 = 1.000/5** y «2 edades».
4. Renovar **todas** las matas → la vieja aparece en **«Lotes renovados»**, el
   cultivo queda con **300 matas / 1 ha / 1 edad**.
5. Resiembra en la cohorte vieja con 100 muertas → la vieja baja a 900 y el
   total a 1.200; el selector de fecha arranca en 2020.
6. Intentar reemplazar **1.200** matas de una cohorte de 1.000 → bloquea y
   ofrece «Todas (1.000)».
7. Cultivo sin área en la cohorte vieja → conserva el área manual y muestra el
   aviso, sin bloquear.
8. Abrir Reportes y el PDF/Excel → el kg/planta del cultivo no cambió de
   fórmula y dice «promedio de 2 edades».
9. Cultivo de **una** siembra → idéntico a la versión anterior en lista,
   reportes, PDF y Excel.
10. Sin señal: anotar una siembra con reemplazo; al volver la red, sube y otra
    instalación la ve igual (mismos valores).

---

## Riesgos y deuda

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| El puntero explícito (D3) no estaba en el encargo y se considera alcance extra | media | medio | Es una columna nullable; sin ella no se puede cumplir «si hay varias, se elige». Confirmar antes de /plan |
| La normalización mueve números en casos raros (varias cohortes vivas al momento de una siembra vieja) | baja | alto | Se normaliza apuntando a la cohorte con vivas; SC-4 con batería de fixtures; si un fixture no se puede preservar, se documenta y se deja `null` (no se inventa) |
| Borrar la cohorte vieja cambia los totales sin que él lo espere | media | medio | Aviso antes de borrar, con el antes/después de matas |
| El área sumada miente en asocio | baja | medio | Fuera de alcance; aviso no bloqueante y valor manual si falta un área |
| El push falla por la FK auto-referente | baja | medio | Destino anterior ya sincronizado; si falla, queda `pendingSync` y se reintenta |
| Migración sin aplicar en producción | media | alto | Se aplica **antes** del deploy; sin ella el push falla pero no se pierden datos |
| El agricultor no sabe cuántas matas hay | alta | bajo | Precarga por área + editable + «Todas»; no bloquea |
| «N edades» confunde en cultivos anuales | baja | bajo | Anuales no muestran edad, como hoy |
| Lluvia de `pendingSync` tras normalizar | media | bajo | Es la primera subida de las tres columnas; se hace una sola vez por fila |
| Deuda: los kilos siguen mezclados | cierta | alto | Etapa B; el copy no promete kg por lote |

**Deuda explícita que queda abierta**

- `harvests` no sabe de cohortes: no hay kg/planta por edad ni costo por kilo
  por cohorte (etapa B).
- Recepa/socola sin representación.
- Asocio y hectáreas equivalentes.
- La suma de áreas de cohortes no se compara contra el **terreno** (eso ya lo
  hace la Tanda 4 a nivel de cultivo).
- No hay forma de **fusionar** dos cohortes si él anotó mal la renovación; la
  salida es editar los reemplazos.

---

## Milestones

1. **Modelo y cálculo**: migración, campos, `cropCohorts`, `recomputeCropState`,
   `lossEarliestDate`, normalización y sus tests puros.
2. **Formulario**: expansión/renovación, precarga por área, validación, edición.
3. **Resiembra por lote**: selector, pérdidas con la fecha correcta, diálogo de
   pérdidas.
4. **UI y copy**: lista de cohortes, «N edades», historial de renovadas, rótulo
   del panel, ayuda, ARB ES/EN y `gen-l10n`.
5. **Sync y respaldo**: payload, pull, huérfanos, roundtrips.
6. **Cierre**: gate completo, migración aplicada, verificación manual, informe.

## Status

**DRAFT** — listo para revisión. Las decisiones D1, D2, D4–D11 vienen cerradas
del 2026-10-21; **D3 (puntero `cohort_sowing_id`)** es la única pieza que este
PRD agrega al encargo y conviene confirmarla antes de pasar a `/plan`.
