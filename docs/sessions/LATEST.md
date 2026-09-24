# 2026-09-24 — Caja menor, trabajadores y jornales (nómina)

## Resumen ejecutivo
- **Caja menor mensual**: settings + widget de barra + alerta (≥80% warning, >100% danger); saldo no acumula entre meses
- **Trabajadores**: tabla `employees` + pantalla CRUD + bloque jornal en el registro (días × valor día)
- **Reportes**: secciones Nómina y Caja (PDF/Excel/pantalla); cosecha con N° empleados y kilos equivalentes
- **214/214 tests verdes**, analyze limpio, HTTP 200
- **Migración SQL aplicada** en Supabase el 2026-09-24 (`employees`, `caja_menor_mensual`, `workers`/`equivalent_kg` — verificado HTTP 200)

## Archivos
- `docs/sessions/2026-09-24-caja-menor-trabajadores-jornales.md` — detalle completo
