# Sesión — martes 20 de octubre de 2026 (tanda 4 cerrada y cohortes)

> Estado al cierre: **tanda 4 implementada, commiteada, pusheada y
> desplegada**; falta la verificación manual del usuario. El análisis de
> cohortes quedó terminado y recomienda **partir el lote en dos cultivos**.
> Informe: `docs/reports/2026-10-20_datos-sin-mentira.md`.
> Plan: `docs/plans/2026-10-20-datos-sin-mentira.plan.md`.
> Análisis: `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`84ff1e1`** (0 commits adelante).
- `gh-pages` = **`62ace8d`** («deploy: tanda 4, datos sin mentira»).
- Gate: `flutter analyze` limpio · **1120/1120** tests.
- Deploy verificado en producción: sha256
  `0E1611367F9775F08EFD8FE7763260DFCF787FFB9B2637E689005CD465453D35`,
  `main.dart.js` de 3.698.077 B.
- Migraciones aplicadas por el usuario:
  `202610200001_add_transaction_equivalent_kg.sql` y
  `202610200002_add_settings_cash_budget_history.sql`.

## 2. Qué se hizo

Tanda 4 completa: **T1–T13 + T15**, más el arreglo del duplicado de T6.

- **Racimo/cajón**: el peso viaja en la cosecha y en la venta
  (`equivalent_kg`); un registro viejo sin peso se excluye y se lista.
- **Caja**: el aporte rige desde que se configura; el arrastre no se
  reconstruye hacia atrás.
- **Áreas**: avisan sin bloquear contra el terreno.
- **kg/planta**: se explica qué incluye; resiembra avisa sin bloquear.
- **Reparto de gasto** (T15): por porcentaje, con atajo por área; N gastos
  independientes, remanente al último.
- **Planilla**: solo aclara gasto vs presupuesto. **Renovación**: solo copy.
- **Arreglo T6**: `pendingHarvests` sale de `storedHarvests` filtrado con
  `_inPeriod`; una venta sin peso no se cuenta dos veces. Rojo verificado
  antes del arreglo.

Commits en `origin/main`: `f4cb524` (tanda 4), `91a3d22` (reparto de gasto),
`84ff1e1` (arreglo «sin peso»).

## 3. Análisis de cohortes (sin código)

Documento: `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md`.
También quedó el puntero desde el análisis anterior
(`2026-10-20_rendimiento-y-cultivos-asociados.md`).

Lo verificado:

- `Harvest` solo tiene `cropId`; `transactions` sí tiene `sowing_id`.
- Una **siembra reemplaza** plantas y área (`livePlants = s.plants`), así que
  una expansión borra el estado del lote viejo; una resiembra conserva el total
  pero mezcla edades.
- `edadDeCrop` toma la última siembra; `lossEarliestDate` ancla las pérdidas a
  esa misma siembra.
- `yieldPerPlant` divide todos los kg por todas las plantas vivas del cultivo.

Opciones A–E. **Recomendación: E, partir el lote en dos cultivos** (la práctica
real: lote/tablón con edad propia), porque la app ya tiene terreno y varios
cultivos; casi todo es copy y un flujo «dividir cultivo», sin migración.
**C** (la siembra es la cohorte) queda solo si se quiere una sola fila «Café»
con dos edades adentro.

Reglas fijadas en el análisis: sin backfill ni inferencia retroactiva; las
cosechas derivadas nunca llevan cohorte (se calculan al leer); `null` → oculto;
la recepa/socola no se disfraza de siembra; no se suman áreas ni lotes.

## 4. Pendientes

- **Verificación manual** de los 8 puntos de la tanda 4; corregir lo que falle.
- Revocar el **PAT de Supabase**.
- Opcional: `flutter build apk`.
- Verificación manual de la tanda 2 si quedó a medias.
- Decidir **E o C**; si es E, PRD del flujo de división (copy solo vs.
  «dividir cultivo»).
- Dos documentos sin commitear (no hubo verbo): el análisis nuevo y el puntero
  en el análisis anterior.

## 5. Cómo continuar

1. Probar la tanda 4 en producción; si algo falla, arreglo con test en rojo.
2. Después, decidir E o C y escribir el PRD correspondiente.
3. No re-abrir sin verbo: cohortes dentro del cultivo (si se elige E), asocio,
   presupuesto por tarea, edición en grupo de un reparto.
