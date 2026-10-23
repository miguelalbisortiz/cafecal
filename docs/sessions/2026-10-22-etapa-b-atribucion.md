# Sesión — jueves 22 de octubre de 2026 (etapa B: kilos por lote)

> Estado al cierre: **etapa B implementada, migrada, commiteada, pusheada y
> desplegada**; falta la prueba manual del usuario en producción. Los kilos de
> cada lote salen del jornal de «Cosechar», no de la venta.
> Informe: `docs/reports/2026-10-22_cohortes-atribucion.md`.
> PRD: `docs/prds/2026-10-22_1813-cohortes-atribucion.prd.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`98bd9b9`** («Etapa B: kilos por lote en el jornal»).
- `gh-pages` = **`b133dab`** («deploy: etapa B kilos por lote»).
- Gate: `flutter analyze` limpio · **1281/1281** (43 nuevos sobre los 1238 de
  la verificación de §12).
- Deploy verificado en producción: sha256
  `789043E41489B289E151C0C63513ED10426477AA76D3770A5BA1B0091BFD4A8F`,
  `main.dart.js` de 3.783.464 B / 131.010 líneas.
- Migración `202610220001_add_transaction_cohort.sql` **aplicada por el
  usuario** y verificada: `base=postgres · columna=true · fk=n · indice=true`.

## 2. Qué se hizo

**Datos**: `transactions.cohort_sowing_id` (uuid nullable, FK a `sowings(id)`
`on delete set null`, índice `idx_transactions_cohort`). `Transaction` gana
`cohortSowingId` con `copyWith` de centinela y una puerta en `fromJson` que
limpia y marca `pendingSync` cuando el puntero no existe (no borra un puntero
huérfano que aún no llegó de la nube).

**Motor**: `cohortKilos` y `kgPerPlantCohort` en `lib/models/cohort_kilos.dart`,
calculados sobre `storedHarvests` (no `harvests`, que incluye derivadas) para
respetar D10-A.

**Pantallas**: selector de lote opcional en el jornal de «Cosechar», con «Sin
lote», preselección cuando hay una sola cohorte, aviso que no bloquea y
limpieza del puntero al cambiar de labor. La tarjeta del cultivo muestra
`· 250 kg · 0,36 kg/planta` por cohorte al desplegar «N edades». Ayuda nueva.
Reportes, PDF y Excel sin cambios.

**Copy**: 7 claves ES/EN, `gen-l10n` corrido, generados normalizados a LF.

**Sync y respaldo**: `cohort_sowing_id` en el payload y en el pull; los
punteros huérfanos cuentan en el respaldo; `deleteSowing` limpia el puntero sin
reasignar kilos.

## 3. Decisiones que no se reabren sin verbo

- Los kilos por lote salen del **jornal de cosecha**, no de la venta: en la
  finca se pesa al recoger y la venta mezcla lotes.
- El selector de lote es **opcional con aviso**; la venta no cambia ni se
  reparte.
- Los kg por lote se ven solo en la tarjeta del cultivo; Reportes/PDF/Excel
  siguen con `_numKg`.
- D7–D12 cerradas en A: preselección de lote único, lote renovado sin kilos,
  puntero conservado al editar, ocultar kg por lote si hay cosecha manual,
  notación con `formatKg` del idioma, huérfano contado en el respaldo.
- Descartados sin verbo: asocio, presupuesto por tarea, repartir una venta
  entre lotes, fila «sin lote», recepa/socola, `reports` por lote.

## 4. Hallazgos

- `cohortKilos` tiene que leer `storedHarvests`; con `harvests` la cosecha
  derivada de una venta se contaría dos veces y rompería D10-A.
- La migración va **antes** del deploy: sin la columna, Supabase devuelve
  PGRST204 al sincronizar.
- `flutter build web` vuelve a dejar `lib/l10n/generated/*` en CRLF; se
  normaliza a LF tras cada deploy y el árbol queda limpio.
- Divergencias declaradas en el informe: los kg por lote no suman el total del
  cultivo, una edad no muestra kg, lote renovado sin kilos, un pesaje por
  jornal, Reportes/PDF con `_numKg`.

## 5. Pendientes

- **Prueba manual en producción** (9 puntos del PRD): 250 kg al lote viejo →
  `250 kg · 0,36 kg/planta`; jornal sin lote → aviso y total sube; cambiar
  labor limpia; borrar siembra; renovado sin kilos; una edad igual; reportes
  iguales; offline.
- Agregar el resultado del deploy al informe, si lo pide.
- No re-abrir D1–D12 ni la atribución por venta sin verbo.

## 6. Cómo continuar

1. Probar https://miguelalbisortiz.github.io/cafecal/ con los 9 puntos.
2. Si algo falla: test en rojo primero, luego arreglo.
3. Recordar: migración antes del deploy y generados a LF después del build.
