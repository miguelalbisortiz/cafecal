# Etapa B · kilos por lote (atribución)

Fecha: 2026-10-22
PRD: `docs/prds/2026-10-22_1813-cohortes-atribucion.prd.md`
Estado: **implementado y con gate verde**. Falta que el usuario aplique la
migración y autorice commit/deploy.

## Qué se construyó

Los kilos que se anotan en un jornal de «Cosechar» pueden declarar a qué lote
fueron. La tarjeta del cultivo muestra, dentro de «N edades», los kg y el
kg/planta de cada lote **solo si alguien los pesó**.

- La **venta no cambia**: sigue siendo del cultivo y no se reparte entre lotes
  (en la finca se mezcla; repartirla sería inventar).
- Sin lote elegido, los kilos siguen contando para el cultivo. El formulario
  **avisa y deja guardar**; no inventa una fila «sin lote».
- `null` → oculto, nunca 0. Lote sin kilos: la fila se ve como antes. Lote
  renovado: no se muestran sus kilos.
- Cultivo con una cosecha guardada a mano: no hay kg por lote (la manual manda
  y los kilos del jornal no se derivan; mostrarlos sería una cifra fuera de los
  totales).

## Cambios

### Datos

- `supabase/migrations/202610220001_add_transaction_cohort.sql`:
  `transactions.cohort_sowing_id uuid null` → `sowings(id) on delete set null`,
  índice `idx_transactions_cohort`. Aditiva e idempotente, sin backfill.
- `Transaction.cohortSowingId` + `copyWith` con centinela + `toJson`.
- `Transaction.fromJson` es la puerta única: limpia el puntero en ingresos, en
  otra categoría/labor, sin kilos o con lote de terreno, y marca `pendingSync`.
  Un puntero a una siembra ausente **se conserva** (el pull puede llegar en
  desorden); la lectura lo trata «sin lote».
- `SyncProvider.buildTransactionPayload` manda la clave siempre (incluida
  `null`); `remoteToTransaction` la lee.
- `deleteSowing` limpia el puntero de los jornales (igual que la FK en la nube)
  sin reasignarlo ni borrar los kilos.
- Respaldo: se exporta/importa el puntero; un puntero a una siembra ausente
  cuenta en `huerfanos`.

### Lectura y UI

- `lib/models/cohort_kilos.dart`: `cohortKilos` (suma por lote desde jornales
  medidos; solo siembras-cabeza del cultivo) y `kgPerPlantCohort` (null sin
  kilos o sin matas vivas).
- `lib/utils/format.dart`: `formatKg` (enteros desde 100, hasta dos decimales
  por debajo) y `formatKgPerPlant` (dos decimales, separador del idioma).
- Jornal: selector «Lote de la cosecha (opcional)» debajo de los kilos, con
  «Sin lote» primero, preselección cuando hay un solo lote vivo, aviso naranja
  no bloqueante si hay kilos sin lote, y limpieza al cambiar labor, categoría,
  tipo, cultivo o lote de terreno. Al editar se conserva el lote guardado,
  incluido uno ya renovado («renovado»).
- Tarjeta: `· 250 kg · 0,36 kg/planta` después del área y antes del estado, solo
  con dos o más edades y solo en lotes vivos con kilos.
- Ayuda: párrafo nuevo, sin la palabra «cohorte».
- 7 claves nuevas en ES/EN (`jornalHarvestedKgLot*`, `cohortKg*`,
  `helpCohortKg`), generadas con `gen-l10n`.

## Tests

Archivos nuevos: `test/transaction_cohort_test.dart`,
`test/cohort_kilos_test.dart`, `test/migration_transaction_cohort_test.dart`,
`test/transaction_provider_cohort_test.dart`,
`test/cohort_atribucion_sync_test.dart`,
`test/register_screen_cohort_test.dart`,
`test/crops_screen_cohort_kilos_test.dart`, `test/l10n_atribucion_test.dart`.

Rojos vistos antes del cambio (los que se pudieron ver):

- Modelo: `cohort_sowing_id` no existía (rojo de compilación) y la puerta
  `fromJson` no limpiaba.
- Lectura: el mapa de kilos por lote no existía.
- Payload: la clave no estaba (`24/26` del archivo de sync).
- Migración: el archivo no existía.
- Selector y tarjeta: no existían los widgets ni el copy.

Guardas declaradas (sin rojo posible):

- `single_cohort_parity_test` de la etapa A sigue verde sin tocarse.
- Reportes/PDF/Excel no cambian (no se tocaron).
- `deriveHarvests` no atribuye cohorte: una cosecha derivada no puede llevar
  lote.
- Un jornal puede llevar `sowing_id` (gasto de una siembra) y
  `cohort_sowing_id` a la vez: son cosas distintas.

## Gate

- `C:\flutter\bin\flutter.bat analyze` → **No issues found!**
- `C:\flutter\bin\flutter.bat test` → **1281/1281** (1120 base + 118 etapa A y
  verificaciones + 43 de esta etapa).

## Divergencias y límites declarados

- **Los kg por lote no suman el total del cultivo**: hay jornales sin lote y la
  venta no se reparte.
- Una sola edad no muestra kg por lote (paridad con la etapa A).
- Los kilos de un lote renovado no se pintan (el dato se conserva).
- Un pesaje por jornal: quien pesa dos lotes en un día anota dos jornales.
- La tarjeta usa el separador del idioma; Reportes/PDF siguen con `_numKg`.
- Reportes, PDF y Excel no muestran nada por lote.
- No hay costo por kilo ni ingreso por lote.

## Pendiente antes de publicar

1. **Aplicar la migración** `202610220001_add_transaction_cohort.sql` en
   Supabase (la aplica el usuario). Sin ella, el push responde PGRST204 y la
   fila queda `pendingSync`; no se pierden datos.
2. Verificación manual de los 9 puntos del PRD en la app publicada.
3. Commit y deploy solo con verbo del usuario.
