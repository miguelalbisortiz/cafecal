---
status: APPROVED
created: 2026-10-20
updated: 2026-10-20
---

# Datos sin mentira — Tanda 4 (PRD)

> De dónde sale: `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md`
> y las preguntas del 2026-10-20 sobre rendimiento, terrenos asociados y caja.
> Alcance aprobado por el usuario ese día: puntos 1–5, 7, 8 y 9 del análisis.
> **El punto 6 (cohortes dentro de un cultivo) queda fuera**: merece más
> análisis. El asocio y el presupuesto por tarea también quedan fuera.

## Objective

Que ningún número de la app sea falso por una unidad mal convertida, por un
presupuesto reescrito con el monto de hoy, por áreas que no cuadran o por un
promedio que no dice qué incluye. No se agregan funciones nuevas: se corrige
lo que ya se muestra y se explica mejor.

El principio sigue siendo el mismo: **`null` → oculto, nunca 0 inventado**, y
si un dato no se puede calcular sin mentir, no se pinta.

## Success Criteria

- **SC-1.** Una cosecha de **12 racimos con 240 kg** suma **240 kg** en todos
  los totales: lista de cosechas, kg/ha, kg/planta, costo por kilo, vendido vs
  cosechado, PDF y Excel.
- **SC-2.** Una venta de **10 cajones con 200 kg** suma **200 kg** vendidos y
  el precio por kilo se calcula sobre 200 kg, no sobre 10.
- **SC-3.** Un registro en racimo o cajón **sin peso** no suma kilos, se cuenta
  como «sin peso» y se puede completar desde una lista. Con todos completos, el
  contador da 0.
- **SC-4.** Cambiar el aporte de caja de 1.000.000 a 1.200.000 en el mes M no
  altera el presupuesto de los meses anteriores a M; el arrastre usa el monto
  que regía en cada mes; los meses anteriores a la primera configuración no
  suman ni restan.
- **SC-5.** Un terreno de 8 ha con cultivos que suman 12 ha muestra un aviso
  («las áreas suman 12,0 ha») y «12,0 de 8,0 ha asignadas», sin bloquear.
- **SC-6.** El kg/planta se muestra con una nota que dice que es el promedio
  del cultivo y que incluye plantas que aún no producen (ES y EN).
- **SC-7.** Una resiembra con plantas nuevas y sin muertas anotadas muestra un
  aviso con «Guardar así»; si se anotó 0 muertas a propósito, no avisa.
- **SC-8.** Un gasto de 100.000 repartido 50/30/20 crea tres gastos que suman
  100.000, cada uno con su cultivo y dentro de su costo por kilo.
- **SC-9.** La planilla de jornales aclara que muestra **lo gastado por tarea**
  y que el presupuesto de caja es uno solo.
- **SC-10.** La ayuda explica que una renovación completa se anota como siembra
  nueva y que reinicia edad, plantas y área (ES y EN).
- **SC-11.** Las unidades con conversión fija (kg, lb, arroba, saco, carga)
  siguen dando exactamente los mismos kilos que hoy.
- **SC-12.** Gate: `flutter analyze` limpio y `flutter test` completo en verde.

## Out of Scope

- Cohortes dentro de un cultivo y cosecha atribuida a una siembra (punto 6).
- Asocio explícito entre cultivos (sombra, densidad, ha equivalentes).
- Presupuesto por tarea con su propio arrastre.
- Editar o borrar en grupo un gasto repartido (cada gasto queda independiente).
- Reconstruir presupuestos de meses anteriores a la primera configuración.
- Cambiar `sacoKg`, el renderer, las fuentes o los `NOTICES`.
- Tocar `HarvestDestination.almacenado` o el flujo de la pantalla Cosechar.

## Assumptions

- El productor acepta que los totales históricos cambien cuando había racimos
  o cajones sin peso: es la corrección, no una pérdida de datos.
- Las migraciones de Supabase las aplica el usuario antes de desplegar la app.
- No hay datos de producción que dependan de que 1 racimo valga 1 kg.

## Users

El productor que registra cosechas y ventas en racimos o cajones (plátano,
café en cereza), el que configura el aporte de caja y el que tiene varios
cultivos en un mismo terreno.

## Constraints

- Local-first: todo tiene que funcionar sin red y sincronizar después.
- Sin `git add -A`; stageo explícito.
- Copy en ES y EN; `lib/l10n/app_es.arb` es el template; `gen-l10n` después.
- Archivos con LF antes de commitear.
- Gate antes de commit y deploy: `flutter analyze` (proyecto entero) +
  `flutter test`.
- Cada arreglo con su test; cuando no hay rojo posible, se declara «guarda».

## Decisiones

### D1 — Qué unidades necesitan peso

`racimo` y `cajon` no tienen conversión fija: el peso lo pone el productor en
cada registro, como **kilos totales** de esa cosecha o venta. `unitToKg` no se
toca (sigue devolviendo 1 como último recurso para datos viejos); se agrega
`unitNeedsWeight(unit)` y un helper `kgFromUnit(amount, unit, totalKg)` que
devuelve `null` cuando falta el peso, en vez de 1.

### D2 — Registros viejos sin peso

No se inventa un peso. Se excluyen de los kilos, se cuentan como «sin peso» y
aparecen en una lista para completarlos. Hasta que se completen, los totales
históricos no los incluyen.

### D3 — Ventas en racimo o cajón

Se agrega `equivalent_kg` (nullable) a la transacción. El formulario pide los
kilos totales cuando la unidad es racimo o cajón, igual que la cosecha. El
precio por unidad sigue siendo el que escribió el productor; el precio por kilo
sale de los kilos reales. La cosecha derivada de una venta hereda esos kilos.

### D4 — Historial del aporte de caja

El aporte se guarda por mes. Rige **desde el mes en que se configura**; los
meses anteriores no cuentan (ni a favor ni en contra). Cambiarlo en el mes M
solo afecta a M y a los siguientes. El arrastre se sigue recalculando en cada
lectura, pero con el monto que regía en cada mes.

### D5 — Áreas que no cuadran

Se avisa, nunca se bloquea: el productor puede tener medidas imprecisas. El
aviso aparece en la tarjeta del terreno y en el editor de cultivo. Si el
terreno no tiene área, no se compara.

### D6 — kg por planta

No se excluyen plantas por edad (sería adivinar). Se etiqueta como promedio
del cultivo e incluye plantas que aún no producen. La ayuda existente se
mantiene.

### D7 — Resiembra sin muertas

Se avisa una vez, sin bloquear, cuando hay plantas nuevas y `lostPlants` es
`null` (no cuando es 0 explícito). El productor puede guardar así: una
resiembra de expansión es legítima.

### D8 — Gasto compartido

Reparto por porcentaje, con un atajo «usar áreas» que propone el porcentaje de
cada cultivo según `areaHa`. Se crean **N gastos independientes** (sin grupo)
con la misma fecha, categoría y descripción, y el remanente de redondeo va al
último. Cada uno entra al costo por kilo de su cultivo.

### D9 — Gastado por tarea

La planilla de jornales ya agrupa por tarea y cultivo. Solo se agrega la
aclaración de que es gasto, no presupuesto. No se crea un presupuesto por tarea.

### D10 — Renovación completa

No hay cambio de lógica: reiniciar edad, plantas y área es lo correcto cuando
la renovación es total. Se explica en la ayuda, junto con el camino de «cultivo
aparte» para lotes que conviven.

### D11 — Lo que no se toca

`unitToKg` para las unidades con conversión fija, `sacoKg`, el renderer, las
fuentes, `NOTICES`, la pantalla Cosechar (salvo el peso obligatorio del racimo
y el cajón) y el destino `almacenado`.

## Impacto por archivo (previsto)

- `lib/models/units.dart`: `unitNeedsWeight`, `kgFromUnit`.
- `lib/models/harvest.dart`: sin cambios de campos (ya tiene `equivalentKg`).
- `lib/models/transaction.dart`: `equivalentKg` + JSON + `copyWith`.
- `lib/providers/transaction_provider.dart`: `addTransaction`/`updateTransaction`
  con `equivalentKg`; `deriveHarvests` lo hereda.
- `lib/services/report_harvest_metrics.dart`: los cinco puntos que suman kg.
- `lib/services/alert_service.dart` y `lib/services/low_price_check.dart`:
  precio por kilo y ventas por cultivo con el helper.
- `lib/screens/harvest_screen.dart`: peso obligatorio para racimo y cajón.
- `lib/screens/register_screen.dart`: peso obligatorio en ventas + reparto de
  gasto entre cultivos.
- `lib/screens/report_screen.dart`: aviso de «sin peso» + copy de la planilla.
- `lib/widgets/per_hectare_panel.dart`: nota del kg/planta.
- `lib/screens/crops_screen.dart` / `lib/widgets/terreno_editor_dialog.dart`:
  áreas y aviso.
- `lib/screens/sowing_screen.dart`: aviso de resiembra.
- `lib/models/settings.dart` + `lib/services/settings_store.dart` +
  `lib/providers/sync_provider.dart`: historial del aporte.
- `lib/l10n/app_es.arb` / `app_en.arb` + `gen-l10n`.
- `supabase/migrations/202610200001_add_transaction_equivalent_kg.sql`
- `supabase/migrations/202610200002_add_settings_cash_budget_history.sql`

## Riesgos

- **Migraciones**: si la app empuja `equivalent_kg` antes de que exista la
  columna, el push falla. Se aplican antes de desplegar.
- **Histórico**: los totales con racimos/cajones viejos cambian. Se comunica en
  el informe y en la lista de «sin peso».
- **Cosecha derivada**: si `deriveHarvests` no hereda el peso, la venta corrige
  el ingreso pero la cosecha sigue mintiendo. Es el punto más fácil de olvidar.
- **Doble descuento**: al repartir un gasto no se debe guardar además el gasto
  original. El formulario crea solo los N hijos.
- **Redondeo**: porcentajes con decimales; el último hijo absorbe el remanente.
- **CRLF**: `flutter build` y el editor pueden reescribir generated; normalizar
  a LF antes de commitear.
- **Sync**: un cliente viejo puede subir transacciones sin `equivalent_kg`;
  el modelo lo tolera como `null` y el registro queda «sin peso».

## Milestones

1. Unidades honestas (racimo/cajón) en cosecha, venta y todos los totales.
2. Historial del aporte y arrastre por mes.
3. Áreas, copy de kg/planta, aviso de resiembra y aclaraciones.
4. Gate, deploy y verificación manual.

## Status

**APPROVED** el 2026-10-20: alcance 1–5, 7, 8 y 9; punto 6 fuera. Las cuatro
decisiones abiertas (D2, D4, D3, D8) las eligió el usuario ese mismo día.
