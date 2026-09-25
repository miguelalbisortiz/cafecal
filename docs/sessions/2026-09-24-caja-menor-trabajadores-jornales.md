# 2026-09-24 — Caja menor, trabajadores y jornales (nómina de finca)

## Summary

Plan de 9 fases (aprobado fase por fase) para cubrir los rubros de nómina de
la planilla física *"RECORDS DE FINCAS DE CAFÉ U OTROS 10 HECTÁREAS O MENOS"*:

1. **Caja menor mensual**: `settings.caja_menor_mensual` + widget de barra en
   el dashboard + regla de alerta `cajaMenor` (≥80% warning, >100% danger).
2. **Lista de trabajadores**: tabla `employees` + pantalla `WorkersScreen`
   (tipo Cultivos) + diálogo editor; menú ⋮ "Trabajadores".
3. **Bloque jornal**: al elegir "Mano de obra" en el registro de gasto →
   trabajador (lista/otro/crear), días, valor día y total = días × valor día
   (Monto readonly). Escribe `provider`, `quantity`, `unit='día'`,
   `pricePerUnit` (sin migración en `transactions`).
4. **Cosecha**: opcional N° de empleados (`workers`) y, si la unidad es
   `racimo`, kilos equivalentes (`equivalent_kg`); badges 👷 y ≈ kg en la lista.
5. **Reportes** (PDF/Excel/pantalla): sección "Nómina del período" (trabajador,
   días, subtotal, total, empleados distintos) + sección "Caja menor" (una fila
   por mes del período con presupuesto, jornales, extras, total, saldo).
6. **Categorías nuevas**: ⚡ Energía y 🚿 Agua (extras de caja, junto a `otro`
   y `mantenimiento`; set ajustable `kCashBoxExtraCategories`).

## What happened

- **Fase 1**: `lib/models/employee.dart` nuevo; `settings`/`harvest` con campos
  opcionales null-safe (copyWith con `_sentinel`); `categories.dart` con
  `kCashBoxExtraCategories` + `discountsCashBox`.
- **Fase 2**: migración `supabase/migrations/202609240001_add_employees_caja_menor.sql`;
  `local_store` clave `employees_v1`; CRUD de empleados en `transaction_provider`;
  `sync_provider` push/pull de `employees` y `workers`/`equivalent_kg`.
- **Fase 3**: `workers_screen.dart`, `employee_editor_dialog.dart`, menú ⋮.
- **Fase 4**: bloque jornal en `register_screen.dart` + `addTransaction` acepta
  `pricePerUnit`.
- **Fase 5**: campo "Caja menor mensual" en Configuración + `cash_box_card.dart`
  (barra verde <80% / ámbar 80–100% / roja >100%, solo mes en curso).
- **Fase 6**: `AlertRule.cajaMenor`, `AlertService.evaluate(..., cajaMensual:)`,
  `alert_provider` lo pasa (reportes no — decisión).
- **Fase 7**: helper compartido `services/report_payroll_metrics.dart`
  (`payroll()` + `cashBoxByMonth()` con orden calendario); secciones en
  `pdf_export_service` / `excel_export_service` / `report_screen`; form de
  cosecha con workers/equivalentKg.
- **Fase 8**: i18n (18+ claves es/en; hueco corregido: `catEnergia`/`catAgua`
  no existían y la UI mostraba la key cruda) + tests nuevos
  (`employee`, `categories_cash_box`, `jornal`) y extensiones
  (`settings`, `harvest`, `pdf_export`, `excel_export`, `alert_service`).
- **Fase 9**: build release + deploy gh-pages + main, HTTP 200.

## State

| Item | Status |
|---|---|
| Tests | **214/214 verdes** |
| analyze | limpio |
| main | ver `git log` |
| gh-pages | ver `git log` (HTTP 200) |
| Migración Supabase | **aplicada y verificada** (2026-09-24, SQL Editor → `employees`, `caja_menor_mensual`, `workers`/`equivalent_kg` responden 200) |

## Key decisions (no revertir)

- **Caja**: solo descuentan jornales (`mano_obra`) + extras
  `{energia, agua, otro, mantenimiento}`; saldo **NO** se acumula entre meses
  (reinicio por calendario). Sin monto → sin widget ni alerta.
- **Empleados distintos**: derivado de `provider` no vacío con gasto de mano de
  obra en el período (sin nombre entra al total de nómina pero no al conteo).
- **Trabajadores = lista fija**: historial guarda nombre snapshot en
  `transactions.provider` (sin FK); borrar/renombrar no rompe registros pasados.
- **Extras es una constante ajustable** (`kCashBoxExtraCategories`).
- Recibos PDF, cuotas/nómina legal, saldo acumulado y vínculo `employee_id`
  quedan **fuera de alcance**.
- **Post-plan (mismo día)**: ítem "Cosechas" **oculto del menú ⋮** (bloque
  comentado en `home_screen.dart`) — el pequeño agricultor produce y vende sin
  almacenar. Nada más cambia: reportes/alertas/sync de cosechas siguen activos
  y la pantalla se restaura descomentando el bloque.
- **Post-plan (mismo día)**: **desgloses de Excel** en la hoja Resumen
  (`main d8d0ba2` / `gh-pages 756ebab`): tabla **Ingresos y gastos por mes**
  (12 filas + Total, solo período año/año-hasta-hoy; Balance verde/rojo) y
  cruce **Gastos por categoría y cultivo** (ordenado por monto, gastos sin
  cultivo van a "Sin especificar"; solo si hay gastos). 3 claves l10n nuevas
  (es/en) + 4 tests → **218/218**, hash de prod verificado.

## Incidente 25 sep — onboarding reaparece / cuenta vacía

- **Síntoma**: al reentrar pide elegir cultivo/siembra y el reporte mostraba
  datos anteriores.
- **Diagnóstico en vivo**: sesión `prueba@gmail.com` (uid `f409b97c…`) con
  localStorage en `[]` **y** Supabase en 0 filas (crops/sowings/transactions/
  employees/harvests). Sonda insert+delete con su token → 201/200: BD y RLS
  sanos. `settings` solo tiene la fila del trigger (21 sep), nunca empujada.
- **Causas de código confirmadas**:
  1. `_pushLocal` con `return` temprano cuando no hay transacciones
     pendientes → cosechas/siembras/trabajadores jamás se subían y
     `markAllSynced` los marcaba como sincronizados (cuenta remota vacía
     con "sync sin error").
  2. Sin listener de `onAuthStateChange` → con sesión muerta el sync volvía
     temprano sin subir nada y la app seguía en pantalla principal.
- **Fix** (`main 0c0b050` / `gh-pages 2526615`, 218/218 + hash prod OK):
  push COMPLETO idempotente en cada sync + reenlace de sesión/AuthGate al
  cambiar el estado de auth.
- **Migración legacy solo-settings es diseño H1** (test
  `local_store_test.dart` lo exige: cada usuario arranca limpio) — no es bug.
- **Pendientes conocidos**: `settings` nunca se sincroniza; borrado de
  trabajadores/cosechas no se propaga (sin tumba → el pull los resucita);
  recuperación depende de que algún dispositivo conserve copia local (prueba
  del usuario en curso).

## Files

`lib/models/employee.dart`, `lib/models/{settings,harvest,categories,farm_alert}.dart`,
`lib/services/{alert_service,local_store,report_payroll_metrics,pdf_export_service,excel_export_service}.dart`,
`lib/providers/{transaction_provider,sync_provider,alert_provider}.dart`,
`lib/screens/{workers_screen,home_screen,settings_screen,register_screen,harvest_screen,report_screen}.dart`,
`lib/widgets/{cash_box_card,employee_editor_dialog}.dart`, `lib/l10n/*`,
`supabases/migrations/202609240001_add_employees_caja_menor.sql`,
`test/{employee,categories_cash_box,jornal}_test.dart` + extensiones.
