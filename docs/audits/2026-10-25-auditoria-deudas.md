# Auditoría de deudas — 2026-10-25

> Alcance: superficie tocada en octubre (cohortes/atribución, sync, respaldo,
> reportes) más el esquema de Supabase. Solo lectura: no se cambió código.
> Los hallazgos marcados **[verificado]** los comprobé leyendo el código en
> esta sesión; los demás vienen del revisor de base de datos y quedan como
> «por confirmar» antes de tocarlos.
>
> **Estado al 2026-10-26:** §1, §2, §3, §4, §5, §6 y §7 arreglados (25 tests
> nuevos, gate **1306/1306**). §2, §3 y §4 con la regla de **un solo equipo**:
> lápida local para el borrado, «el remoto reemplaza solo si lo local no tiene
> cambios sin subir» y recálculo que solo marca el cultivo cuando los números
> cambian; sin `updated_at` ni migración. §8 queda como límite declarado: el
> respaldo ya avisa cuántos registros omitió. Falta que el usuario aplique
> `202610250001_allow_zero_plants.sql` y
> `202610260001_indexes_and_crop_terreno_check.sql` antes del deploy.

## 0. Método y límites

- Frente de base de datos y sync: completo.
- Frentes de calidad y seguridad: **no se ejecutaron**. Los dos subagentes
  fallaron por límite de uso del proveedor. Lo único de seguridad que quedó
  revisado es RLS: las 7 tablas tienen sus 4 políticas con `auth.uid() =
  user_id` y el pull filtra por usuario. **Sin hallazgos de RLS.**
- No se probó nada contra la base real ni contra producción.

## 1. Crítica — las cohortes no se sincronizan **[verificado]**

`lib/providers/sync_provider.dart:455-465` (`buildSowingPayload`) y
`:731-743` (`_remoteToSowing`).

El payload de `sowings` no manda `replaces_plants`, `replaces_area_ha` ni
`cohort_sowing_id`, y el pull no los lee. El PRD de estructura los exigía.

Qué pasa: la cohorte vive solo en el equipo que la creó. El otro recibe dos
siembras «vírgenes», no resta el reemplazo y el cultivo queda con más matas y
área de las que tiene. Al reiniciar, la normalización de datos viejos
(`transaction_provider.dart:55`) interpreta esas filas como legado e inventa un
reemplazo. `transactions.cohort_sowing_id` sí sube, pero apunta a una siembra
que remotamente no tiene cohorte: en el otro equipo se ve «sin lote».

Arreglo: las 3 claves en el payload y en `_remoteToSowing`. Después hace falta
**un re-push completo de siembras** (las que ya subieron sin campos quedaron
`pendingSync: false` y no se reenvían solas).

## 2. Crítica — borrar siembras, cosechas, trabajadores o terrenos no viaja **[verificado]**

`transaction_provider.dart:755` (`deleteSowing`), `:694` (`deleteHarvest`),
`:851` (`deleteEmployee`), `:917` (`deleteTerreno`) · `sync_provider.dart:207-246`.

Solo hay lápida para cultivos (`deletedCrops`) y para movimientos
(`deleted: true`). `mergeRemoteSowings` (`:1345-1357`) reinserta toda siembra
remota que no esté local, así que lo borrado reaparece en el siguiente pull.
En terrenos es peor: el terreno vuelve, pero sus cultivos ya subieron con
`terreno_id = null`.

Arreglo: mismo patrón que `deletedCrops` para las 4 entidades (lista persistida
+ stage de DELETE + exclusión en el merge), o `deleted_at` con borrado lógico.

## 3. Alta — el pull nunca aplica una edición remota **[verificado]**

`sync_provider.dart:553-557, 566-570, 575-579, 587-592, 597-601, 606-610`.

Todas las entidades se filtran con `where((x) => !localIds.contains(x.id))`: un
id que ya existe no se actualiza nunca. `transactions.updated_at` existe
(`202609040001:45`) pero no hay trigger y el payload no la manda.

Qué pasa: editar en el equipo B no llega al A. Si B borra y A edita, el upsert
de A resucita la fila. No hay «gana el más nuevo»: gana siempre el local.

Arreglo (hecho el 2026-10-26, con una sola cuenta en un solo equipo): el pull
ya no filtra por ids nuevos; cada merge reemplaza la fila remota **solo si la
local está sincronizada** (`pendingSync == false`) y respeta las lápidas. Con
un equipo no hace falta `updated_at`: el remoto nunca es más viejo que lo ya
subido. Si algún día hay dos equipos, entra el `updated_at` de punta a punta.

## 4. Alta — un pull marca todos los cultivos como pendientes **[verificado]**

`transaction_provider.dart:787-807`.

`_recomputeCropsFromSowings` pone `pendingSync: true` a todo cultivo con
siembras, aunque los números no cambien. Como el push manda el cultivo completo,
un pull puede pisar en la nube una edición del otro equipo (nombre, fase,
`terreno_id`).

Arreglo (hecho el 2026-10-26): se marca `pendingSync` solo si `livePlants` o
`areaHa` cambian de verdad. El `update` parcial queda para cuando haya dos
equipos; con uno, el upsert completo ya no se dispara por un pull.

## 5. Alta — la base rechaza una resiembra de solo mortandad **[verificado]**

`supabase/migrations/202609070001_add_sowings_harvests.sql:26`
(`plants > 0`) frente a `lib/screens/sowing_screen.dart:721-727` y
`lib/widgets/crop_loss_dialog.dart:128`.

La app permite anotar mortandad sin reponer plantas (`plants: 0`) y guarda la
fila. La base la rechaza con `23514`, que además no está mapeado en
`_PushOutcome._describe` (`sync_provider.dart:31-39`).

Qué pasa: esa siembra queda `pendingSync` para siempre, falla en cada sync y la
mortandad nunca llega a la nube.

Arreglo: migración `check (plants >= 0)` + mensaje legible para `23514`.

## 6. Media — FKs sin índice **[verificado por lectura de migraciones]**

No hay índice para `crops.user_id`, `crops.terreno_id`, `sowings.crop_id`,
`harvests.crop_id`, `transactions.crop_id`, `transactions.harvest_id` ni
`transactions.sowing_id`. Los `idx_*_user_date` cubren `user_id` en
transactions, sowings y harvests, pero no las FK ni `crops`.

Impacto: borrar un cultivo dispara `on delete set null` con scan completo, y
cada pull sobre `crops` es un seq scan.

## 7. Media — `crop_id` y `terreno_id` pueden venir juntos **[verificado]**

`202610160002_add_transaction_terreno.sql:9-12` lo declara en un comentario,
pero no hay `CHECK`. El formulario lo respeta; `importBackup` mete la fila tal
cual. Un gasto con los dos ids se contaría en el ROI del cultivo y del terreno.

## 8. Media — restaurar un respaldo descarta la versión buena **[verificado]**

`transaction_provider.dart:1163-1184` (`_fuse`): conserva lo local y tira lo
entrante por id, sin comparar nada. Restaurar un respaldo más nuevo sobre un
equipo viejo no corrige nada; solo sube el contador de «omitidos».

## 9. Nota (no es hallazgo)

El pull trae el histórico completo de 7 tablas en cada pasada, sin
`updated_at > last_sync` ni paginación. Con `transactions` creciendo, el sync se
vuelve lento. El filtro por usuario sí está.

## 10. Orden propuesto

| Orden | Hallazgo | Por qué | Costo |
|---|---|---|---|
| 1 | §1 cohortes en sync | corrompe matas y área entre equipos; deja la etapa A a medias | bajo |
| 2 | §5 `plants >= 0` | una fila envenenada reintenta para siempre | bajo (migración) |
| 3 | §2 borrados | lo borrado reaparece; finca partida | medio |
| 4 | §3 ediciones remotas | requiere `updated_at` de punta a punta | alto |
| 5 | §4 push de cultivos | depende de §3 para no pisar | bajo |
| 6 | §6, §7 índices y CHECK | higiene de base, no se ve en pantalla | bajo |
| 7 | §8 respaldo | depende de `updated_at` | medio |

Los frentes de calidad y seguridad quedan pendientes de correr cuando el
proveedor lo permita.
