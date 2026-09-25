# 2026-09-24 — Caja menor, trabajadores y jornales (nómina)

## Resumen ejecutivo
- **Caja menor mensual**: settings + widget de barra + alerta (≥80% warning, >100% danger); saldo no acumula entre meses
- **Trabajadores**: tabla `employees` + pantalla CRUD + bloque jornal en el registro (días × valor día)
- **Reportes**: secciones Nómina y Caja (PDF/Excel/pantalla); cosecha con N° empleados y kilos equivalentes
- **214/214 tests verdes**, analyze limpio, HTTP 200
- **Migración SQL aplicada** en Supabase el 2026-09-24 (`employees`, `caja_menor_mensual`, `workers`/`equivalent_kg` — verificado HTTP 200)
- **Prueba manual en producción pasada** por el usuario ("ya esta bien lo probe")

## Post-plan (mismo día)
- **Desgloses de Excel** en la hoja Resumen (commit `main d8d0ba2` / `gh-pages 756ebab`, hash prod verificado):
  - **Ingresos y gastos por mes**: tabla 12 filas + Total, solo en períodos año / año hasta hoy; Balance en verde/rojo
  - **Gastos por categoría y cultivo**: cruce categoría × cultivo ordenado por monto, con "Sin especificar" para gastos sin cultivo; solo si hay gastos
  - 3 claves l10n nuevas (es/en) + 4 tests nuevos → **218/218 tests**, analyze limpio

## Incidente 25 sep — onboarding reaparece (cuenta vacía)
- Cuenta `prueba@gmail.com` vacía en local Y remoto; BD/RLS sanos (sonda 201/200). Causas: `_pushLocal` con return temprano (entidades no pendientes nunca subidas + `markAllSynced` falso) y sesión muerta silenciosa (sin listener de auth).
- **Fix desplegado** `main 0c0b050` / `gh-pages 2526615`: push completo idempotente + `onAuthStateChange` → reenlace. Recuperación: cualquier dispositivo con copia local sube todo en el próximo sync. Detalle en el doc de sesión.

## Archivos
- `docs/sessions/2026-09-24-caja-menor-trabajadores-jornales.md` — detalle completo
