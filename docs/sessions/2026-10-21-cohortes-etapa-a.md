# Sesión — miércoles 21 de octubre de 2026 (etapa A: cohortes por siembra)

> Estado al cierre: **etapa A implementada, commiteada, pusheada y
> desplegada**; la verificación manual de §12 quedó sin hacer por decisión
> del usuario (no es un fallo: no se probó). El lote ya puede tener varias
> edades sin que una siembra nueva borre plantas, área ni edad de la vieja.
> Informe: `docs/reports/2026-10-21_cohortes-estructura.md`.
> Plan: `docs/plans/2026-10-21-cohortes-estructura.plan.md`.
> PRD: `docs/prds/2026-10-21_1818-cohortes-estructura.prd.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`4448a19`** (0 commits adelante).
- `gh-pages` = **`72e0b45`** («deploy: etapa A, cohortes por siembra y
  renovación parcial»).
- Gate: `flutter analyze` limpio · **1230/1230** tests (110 nuevos sobre los
  1120 del baseline `84ff1e1`).
- Deploy verificado en producción: sha256
  `7A05D63651AB3754C1AD80B63EF1A200B8AA366110504522DA7410390171C8E6`,
  `main.dart.js` de 3.776.845 B / 130.838 líneas.
- Migración aplicada por el usuario:
  `202610210001_add_sowings_cohorts.sql` (tres columnas aditivas en
  `sowings`, checks ≥ 0, FK auto-referente, índice `idx_sowings_cohort`).

## 2. Qué se hizo (T1–T20)

**Motor** (`lib/models/sowing.dart`, `lib/models/crop.dart`): `Cohort`,
`cropCohorts`, `openCohorts`, `nEdades`, `edadDeCohorte`, `edadesDeCohorte`,
`edadDeCrop` (una sola edad o `null`), `recomputeCropState` que **suma**
cohortes abiertas en vez de reemplazar, `normalizeLegacyCohorts`,
`validateReplacement`/`replacementPrefill`/`maxReplacement`, y
`lossEarliestDate(..., cohortSowingId)`.

**Datos**: `Sowing` gana `replacesPlants`, `replacesAreaHa` (nullable) y
`cohortSowingId` (uuid auto-referente, `on delete set null`). `fromJson` con
flags de pérdidas y reemplazo separados; `pendingSync` cuando el registro
llega sucio. Normalización idempotente al abrir, sin mover números.

**Provider**: `addSowing`/`deleteSowing` con cohortes y limpieza de punteros;
normalización en constructor, `reloadFromCache` e `importBackup`;
`mergeRemoteSowings` recalcula y conserva punteros aún no llegados.

**Pantallas**: formulario «Amplío / Renuevo» (solo con cohortes vivas; matas
obligatorias, precarga por área y «Todas (N)»; guarda `0` explícito), resiembra
con lote y pérdidas por cohorte, tarjeta del cultivo con «N edades», fila por
cohorte y «Lotes renovados», aviso antes de borrar un lote con el total que
queda, tag «sin lote» para punteros rotos, bloque de Ayuda «Renovar una parte
del lote» y rótulo «promedio de N edades» junto al kg/planta.

**Copy**: 30 claves nuevas en ES/EN con placeholders en el orden en que se
leen, `gen-l10n` corrido y generados normalizados a LF.

## 3. Decisiones que no se reabren sin verbo

- **Cohortes: C** (la siembra ES la cohorte). **E** (partir el lote en dos
  cultivos) quedó descartada: en la finca la cosecha de lotes de distinta edad
  **casi siempre se mezcla**, y sin reparto de ingresos partir el lote obligaría
  a elegir un cultivo o inventar kilos.
- **Renovación parcial**: la siembra nueva declara cuánto reemplaza
  (`replacesPlants` / `replacesAreaHa`); sin eso, el que reemplaza es un dato
  viejo y se normaliza una sola vez.
- **Sin `closed_at`**: cohorte cerrada = 0 matas vivas; no se revive.
- **Área**: si falta el área de alguna cohorte abierta, `areaHa` = `null` y el
  provider conserva la manual.
- **Etapa B (atribución de kilos por cohorte) no se empezó**: solo si se
  empieza a pesar por lote. Fuera por ahora: `harvests.sowing_id`, selector de
  cohorte al vender, reportes por cohorte, recepa/socola, asocio.

## 4. Pendientes

- **Verificación manual §12** del informe (10 puntos): no se hizo. El usuario
  eligió cerrar la sesión sin probarla.
- Etapa B, solo si se pesa por lote.
- Recepa/socola y asocio: descartados por ahora.

## 5. Cómo continuar

1. Probar en producción los 10 puntos de §12; si algo falla, test en rojo
   primero.
2. Revisar en la nube que los registros viejos queden sanos (consultas de §5.1
   del informe).
3. No re-abrir la decisión C/E ni la etapa B sin verbo.
4. Después de un deploy, recordar que `flutter build web` reescribe
   `lib/l10n/generated/*` con CRLF: se normaliza a LF y `git status` queda
   limpio.
