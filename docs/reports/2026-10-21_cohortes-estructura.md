# Cohortes dentro de un cultivo — Etapa A «estructura» (informe)

> PRD: `docs/prds/2026-10-21_1818-cohortes-estructura.prd.md` (APPROVED)
> Plan: `docs/plans/2026-10-21-cohortes-estructura.plan.md` (READY)
> Análisis: `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md` (§12)

## T1 · Baseline (2026-10-21)

Punto de partida congelado antes de tocar código.

- Rama: `main` = `origin/main` = `84ff1e1`.
- `flutter analyze` (proyecto entero, `tool/` incluido): **sin issues**
  (`docs/reports/gate-t1-analyze.txt`).
- `flutter test`: **1120/1120** (`docs/reports/gate-t1.txt`).
- Árbol de trabajo: solo documentación sin commitear (análisis, PRD, plan).

### Fixture congelado de la guarda de paridad (T13)

Cultivo de una sola cohorte, para probar que nada se mueve:

| Dato | Valor |
|---|---|
| Área | 5 ha |
| Matas vivas | 1.000 |
| Siembra | 2020 (1.000 matas / 5 ha) + resiembra (100 muertas, 100 nuevas) |
| Cosecha 2023 | 2.000 kg |
| Cosecha 2024 | 2.400 kg |
| Cosecha del período (2026) | 1.200 kg |
| Venta | 12.000.000 |
| Gasto | 6.000.000 |

Números que hoy produce el código con ese fixture (sonda temporal, ya borrada):

| Métrica | Valor |
|---|---|
| kg/ha (período) | `240,0` |
| kg/planta (período) | `1,2` |
| Promedio histórico | `440,0` kg/ha · `2,2` kg/planta · `2` años |
| Ingreso/ha | `2.400.000` |
| Costo/ha | `1.200.000` |
| Margen/ha | `1.200.000` |
| Costo/kg (período) | `5.000` |

T13 repetirá estos números con la guarda de paridad: un cultivo con una sola
cohorte no cambia ninguna cifra.

## T2 · Migración

`supabase/migrations/202610210001_add_sowings_cohorts.sql` — aditiva,
idempotente, sin backfill: `replaces_plants`, `replaces_area_ha` y
`cohort_sowing_id` (FK auto-referente, `on delete set null`) + índice. No toca
`harvests` ni `transactions`. La aplica el usuario en Supabase.

## T3 · Modelo `Sowing`

`lib/models/sowing.dart`:

- Campos `replacesPlants` (`int?`), `replacesAreaHa` (`double?`) y
  `cohortSowingId` (`String?`), en el constructor y en `copyWith` con centinela
  (se pueden volver a `null`).
- `toJson` gana `replaces_plants`, `replaces_area_ha` y `cohort_sowing_id`.
- `fromJson` (puerta única) aplica las cinco reglas de §5.6: negativos → `null`
  sucio; área sin matas → `null` sucio; resiembra limpia `replaces_*` y conserva
  el puntero; siembra con reemplazo y sin puntero se conserva sin marcar sucio;
  claves ausentes entran `null` sin marcar sucio.

Tests: `test/sowing_test.dart` (28 verdes) — round-trip de los tres campos,
JSON sin claves, negativos, área sin matas, resiembra, siembra sin puntero y
`copyWith` a `null`. Guarda: el round-trip de la resiembra sigue conservando
pérdidas, motivo y puntero.

## Gate tras T1–T3

- `flutter analyze` (proyecto entero): **sin issues** (`docs/reports/gate-t3-analyze.txt`).
- `flutter test`: **1133/1133** (`docs/reports/gate-t3.txt`) — 1120 de base + 5
  de la migración + 8 del modelo.

## T4–T8 · Motor puro de cohortes

Todo en `lib/models/sowing.dart` y `lib/models/crop.dart`, sin tocar todavía el
provider ni la UI.

- **T4 · `cropCohorts`** (+ `Cohort`): única fuente de verdad, determinista por
  día, tipo e `id`. La resta **exige puntero que resuelva** (D3): sin puntero, o
  si apunta a una cohorte cerrada o del futuro, no resta. `closedOn` solo se
  anota cuando la cierra un reemplazo. 15 casos.
- **T5 · `recomputeCropState`** sobre cohortes: suma las vivas (0 es un hecho,
  no un dato faltante) y el área solo si **todas** las cohortes vivas la tienen.
  Agregados `openCohorts`, `nEdades` y `cohortAreaStatus`. 8 casos. Se reescribió
  el test viejo «área usa la última siembra» (ahora: sin normalizar, suma).
- **T6 · edad y pérdidas**: `edadDeCohorte`, `edadesDeCohorte`, `edadDeCrop`
  (una cohorte viva = la edad de siempre; dos o más = `null`, «N edades») y
  `lossEarliestDate` con `cohortSowingId`. 5 casos en `crop_test.dart` + 3 en el
  motor.
- **T7 · `normalizeLegacyCohorts`**: interpreta los datos viejos como reemplazo
  sin mover números; idempotente sin bandera. 9 casos, incluido el declarado del
  PRD (§Riesgos): con varias cohortes vivas, un solo puntero no puede expresar
  «borrá todo» → apunta a la más antigua y el total sube (se declara aquí).
- **T8 · validadores**: `validateReplacement`, `replacementPrefill`,
  `maxReplacement`. 11 casos.

### Gate tras T4–T8

- `flutter analyze`: **sin issues** (`docs/reports/gate-t8-analyze.txt`).
- `flutter test`: **1183/1184** (`docs/reports/t8-full.txt`). El único rojo es
  `c6_arranque_test.dart` «la edad se reinicia sola con la siembra nueva»,
  **esperado**: el formulario todavía guarda la siembra nueva con los tres
  campos en `null` (la etapa T14 lo cambia a «Amplío / Renuevo» explícito). El
  plan §11 ya lo anticipa. Vuelve verde con T14.

## T9–T10 · Provider

- `addSowing` acepta `replacesPlants`, `replacesAreaHa` y `cohortSowingId`.
- `deleteSowing` deja sin puntero a las siembras que apuntaban a la borrada
  (`cohortSowingId: null`, `pendingSync: true`), además de desvincular los
  movimientos como ya hacía.
- Al abrir (constructor y `reloadFromCache`), al importar un respaldo y tras un
  pull (`mergeRemoteSowings`) se normalizan los datos viejos y se recalculan los
  cultivos. Un puntero que todavía no llegó no se anula.
- 13 casos en `test/transaction_provider_sowing_test.dart`.

## T14 · Formulario «Amplío / Renuevo»

`lib/screens/sowing_screen.dart` + 13 claves nuevas en ES/EN (`gen-l10n`,
generados normalizados a LF):

- La pregunta «¿Qué pasa con las matas que ya tenés?» aparece **solo** en una
  siembra sobre un cultivo con lotes vivos; sin cohortes el formulario queda
  exactamente como antes.
- Por defecto «Amplío el cultivo» y guarda **`0` explícito** (nunca `null`).
- «Renuevo una parte» despliega el lote (selector si hay varios), las matas que
  reemplaza (obligatorias y > 0, con precarga por área y «Todas (N)») y el área
  que reemplaza.
- El arranque completo (C6) fuerza Renuevo + Todas y se oculta con dos o más
  lotes vivos.
- 10 casos en `test/sowing_screen_cohorts_test.dart`.

## Gate tras T9–T14

- `flutter analyze`: **sin issues** (`docs/reports/gate-t14-analyze.txt`).
- `flutter test`: **1207/1207** (`docs/reports/gate-t14.txt`). El rojo esperado
  de `c6_arranque_test` volvió a verde: el arranque completo ahora reemplaza las
  matas del lote viejo.

## T15 · Resiembra por lote y pérdidas con la fecha del lote

- El formulario de resiembra dice a qué lote le entran las matas: con una edad
  lo escribe, con varias lo elige (la más vieja viva por defecto). Sin lotes
  vivos avisa y ofrece **«Anotar como siembra»**; la resiembra no cambia nada.
- El diálogo de pérdidas usa el mismo selector y `lossEarliestDate` con la
  cohorte elegida: no se puede fechar antes de esa siembra.
- Borrar un lote avisa con el total que queda; una siembra con puntero roto se
  lista **«sin lote»** (no se adivina por fecha).
- 5 casos en `test/sowing_screen_cohorts_test.dart` y 3 en
  `test/crop_loss_dialog_test.dart`.

## T16 · Tarjeta del cultivo

- **Una** cohorte viva: la tarjeta se ve exactamente como hoy.
- **Dos o más:** «2 edades» desplegable, una fila por lote con fecha, edad,
  matas, área y **Abierta**; nunca un promedio.
- **«Lotes renovados»** al pie, con el día en que el reemplazo la dejó en 0.
- Sin matas vivas se dice. Avisos de área (falta la de algún lote / los lotes
  superan el área escrita) sin bloquear.
- 7 casos en `test/crops_screen_cohorts_test.dart`.

## Gate tras T15–T16

- `flutter analyze`: **sin issues** (`docs/reports/gate-t16-analyze.txt`).
- `flutter test`: **1222/1222** (`docs/reports/gate-t16.txt`).

## T17 · Ayuda: qué es renovar una parte

- Bloque **«Renovar una parte del lote»** en Ayuda, en «lote» y «matas», junto a
  los casos. Nada de «cohorte» ni de kilos por lote.
- Claves `helpCohortsRenewTitle` / `helpCohortsRenew` en ES y EN.

## T18 · Copy consolidado y guardas de idioma

- Las 30 claves de §7 están en los dos ARB, con los mismos argumentos y los
  `placeholders` declarados en el orden en que se leen.
- `test/l10n_cohortes_test.dart`: presentes en ES/EN, mismos argumentos, sin
  «cohorte»/«cohort», sin prometer kg por lote.
- `lib/l10n/generated/` regenerado y normalizado a **LF** (el diff solo suma
  líneas).

## T19 · Rótulo «promedio de N edades»

- `PerHectarePanel` recibe `sowings` (vacío por defecto, no rompe llamadas) y,
  junto al kg/planta, aclara `promedio de N edades` cuando el cultivo tiene dos
  o más cohortes vivas.
- La fórmula no cambia, la fila sigue siendo por cultivo y no hay columnas
  nuevas en PDF/Excel.
- 4 casos en `test/per_hectare_panel_ages_test.dart`.

## Gate tras T17–T19

- `flutter analyze`: **sin issues** (`docs/reports/gate-t18-analyze.txt`).
- `flutter test`: **1230/1230** (`docs/reports/gate-t18.txt`).

## T20 · Gate final

- `flutter analyze`: **sin issues** (`docs/reports/gate-t20-analyze.txt`).
- `flutter test`: **1230/1230** (`docs/reports/gate-t20.txt`). Baseline de
  `main`: 1120; la etapa sumó **110** tests.

## Gate del 2026-10-22

- `flutter analyze`: **sin issues**.
- `flutter test`: **1232/1232** con los 2 tests de
  `test/cohortes_puntos_1_2_test.dart` (verificación automática de §12.1–2).

## Antes / después (SC-1, SC-2, SC-3)

Cultivo base: 1.000 matas / 5 ha.

| Caso | Antes (`main`) | Ahora |
|---|---|---|
| Expansión: 300 matas / 1 ha, «Amplío» | la siembra nueva **borraba** el lote: 300 matas / 1 ha | 1.300 matas / 6 ha; dos edades |
| Renovación parcial: 300 matas / 1 ha, «Renuevo» 300 | no existía: o borraba (siembra) o sumaba y mezclaba edades (resiembra) | vieja **700 / 4 ha** + nueva **300 / 1 ha** = 1.000 / 5 ha; dos edades |
| Renovación total: 300 matas / 1 ha, «Todas» | 300 / 1 ha y la edad se reiniciaba: el lote viejo desaparecía | nueva **300 / 1 ha**; la vieja en **«Lotes renovados»**, una sola edad |

Los kilos no cambian en ninguno de los tres: las cosechas siguen siendo del
cultivo entero (SC-14).

## Datos viejos: la corrección declarada

S1 1.000/5 + S2 300/1 + S3 400/2 (las tres viejas, sin puntero): al abrir, S3 se
marca como reemplazo de S1 (la más antigua viva) con 1.300 matas. S1 queda en 0,
**S2 sobrevive** y el total sube a **700**, no a 400. Un solo puntero no puede
expresar «borrá todo» cuando hay varias cohortes vivas; quedó declarado en el
PRD (§Riesgos) y fijado por test. Lo que sí se sostiene: los números de una sola
pasada, la idempotencia y que una fila corregida no se vuelve a tocar.

## Guardas que quedaron

- **Una cohorte:** formulario, tarjeta, reportes y exportes como hoy
  (`single_cohort_parity_test` y los widgets de T14/T16).
- **Cosechas intactas:** sin campos ni columnas nuevas en `harvests`
  (`harvests_intactos_test`).
- **Lenguaje:** claves en los dos ARB, mismos placeholders, sin «cohorte» y sin
  kilos por lote (`test/l10n_cohortes_test.dart`).
- **Migración aditiva:** contrato estático en
  `test/migration_sowings_cohorts_test.dart`.
- **`null` → oculto:** sin área o sin dato no se pinta 0 (sin cambios).

## Migración

`supabase/migrations/202610210001_add_sowings_cohorts.sql` — **aplicada por el
usuario** el 2026-10-21. Va **antes** del deploy: si falta una columna,
PostgREST responde PGRST204 y el push falla.

Consulta de control corrida el 2026-10-22 en el SQL Editor, sin
observaciones: 3 columnas (`replaces_plants` integer, `replaces_area_ha`
numeric, `cohort_sowing_id` uuid, las tres nullable),
`sowings_cohort_sowing_id_fkey` con `confdeltype = 'n'`, índice
`idx_sowings_cohort` presente y `con_dato = 0` (ninguna fila con los campos
nuevos).

Consultas de control (§5.1). Esperado: 3 columnas, FK con `confdeltype = 'n'`,
índice `idx_sowings_cohort`, `con_dato = 0`.

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'sowings'
  and column_name in ('replaces_plants','replaces_area_ha','cohort_sowing_id')
order by column_name;

select conname, confdeltype
from pg_constraint
where conrelid = 'public.sowings'::regclass and contype = 'f';

select indexname from pg_indexes
where schemaname = 'public' and tablename = 'sowings'
  and indexname = 'idx_sowings_cohort';

select count(*) as con_dato
from public.sowings
where replaces_plants is not null
   or replaces_area_ha is not null
   or cohort_sowing_id is not null;
```

## Verificación manual (§12)

Se hace **después** del deploy, con la migración aplicada.

> Los puntos 1 y 2 quedaron cubiertos por prueba automática, no por una
> prueba manual en producción: el navegador no puede manejar esta app (se
> pinta en canvas y no expone referencias) y no se usó la cuenta del usuario.
> El 3 al 10 siguen pendientes de la prueba manual.

- [x] 1. Datos viejos quietos: los números de un cultivo con dos siembras no
      cambian al abrir la versión nueva.
      **Automático** (`test/cohortes_puntos_1_2_test.dart`): se siembran dos
      siembras sin las tres claves nuevas; abrir deja 300 matas en 1 ha —lo
      mismo que veía la app vieja— con una sola cohorte abierta, y reabrir no
      reescribe ni una fila. Rojo verificado apagando la normalización (daba
      1.300).
- [x] 2. La corrección manda: editar la segunda siembra a «Amplío» sube las
      matas, dice «2 edades» y no se vuelve a normalizar al reabrir.
      **Automático**: el formulario guarda `0` explícito, el cultivo pasa a
      1.300 matas / 6 ha y al reabrir sigue en 1.300. Rojo verificado guardando
      `null` en vez de `0`.
- [ ] 3. Renovación parcial: 300/1 sobre 1.000/5 queda 700/4 + 300/1 = 1.000/5
      con «2 edades».
- [ ] 4. Renovación total: el lote viejo pasa a «Lotes renovados» y el cultivo
      queda en 300/1 con una edad.
- [ ] 5. Resiembra en el lote viejo: 100 muertas bajan la vieja a 900 (total
      1.200) y la fecha de la pérdida arranca en esa siembra.
- [ ] 6. No se puede reemplazar de más: bloquea y ofrece «Todas (1.000)».
- [ ] 7. Área incompleta: conserva la manual, avisa sin bloquear; si la suma
      supera la manual, muestra las dos cifras.
- [ ] 8. Reportes: el kg/planta no cambia de fórmula, dice «promedio de 2
      edades», sin filas por lote y con los mismos totales en PDF/Excel.
- [ ] 9. Una sola cohorte: lista, reportes y exportes idénticos; el formulario
      no muestra la pregunta de renovación.
- [ ] 10. Sin señal: la siembra con reemplazo queda `pendingSync` y al volver
      la red sube con las mismas matas, área y puntero.

## Deploy

Publicado el 2026-10-21, con la migración ya aplicada.

| Qué | Valor |
| --- | --- |
| `main` | `c76d293` (gate + informe) |
| `gh-pages` | `72e0b45` |
| `main.dart.js` | 3.776.845 bytes / 130.838 líneas |
| sha256 | `7A05D63651AB3754C1AD80B63EF1A200B8AA366110504522DA7410390171C8E6` |

`deploy.ps1` verificó el mismo sha256 en producción; el build de la web
reescribe `lib/l10n/generated/*.dart` con CRLF y se devolvió a LF.

## Definition of done

- [x] Gate verde: `analyze` limpio + 1232/1232.
- [x] Informe T1–T20 con números, guardas y la corrección declarada.
- [x] Commit de la etapa (`6e7a3a1`).
- [x] Migración aplicada por el usuario (2026-10-21).
- [x] Push (`c76d293`), deploy (`72e0b45`) y Pages sirviendo el build nuevo.
- [ ] Verificación manual de §12.
- [ ] Cierre de sesión y `LEARNING.md`.