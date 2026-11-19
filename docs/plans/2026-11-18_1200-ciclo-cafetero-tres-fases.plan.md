---
prd: (sin PRD — nace de la revisión del ciclo cafetero pedida por el dueño)
status: FASE 1 DONE 2026-11-18 · FASES 2 y 3 PENDIENTES
created: 2026-11-18_1200
source:
  - D:\proyecto\calcafe (código real en main, commit 8ce9558)
repo_state: main en 8ce9558 con Fase 1 sin commitear al escribir este plan
---

# Plan: ciclo cafetero en tres fases

## Contexto

La app ya cubre buena parte del ciclo: siembras/cohortes con edad, kilos
atribuidos al lote, cosechas con destino, cosecha derivada de la venta, kg/ha,
margen por cultivo y por hectárea, stock sin vender y concentración de
comprador. Lo que faltaba era el **punto de la cadena en que se vende el café**
y el **costo de beneficiarlo**.

La propuesta inicial de tres mejoras se corrigió tras leer el código:

| Propuesta inicial | Realidad del repo | Decisión |
|---|---|---|
| Rendimiento por lote | Ya existe: `cohort_kilos`, `per_hectare_panel`, `expectedYieldPerHa` | **Descartada**; se reemplaza por rendimiento de trilla (Fase 3) |
| Ingresos diferenciados por estado | No existe: todas las ventas de café caen en la misma fila | **Fase 1** |
| Costos de beneficio/procesamiento | Existía el hueco: las categorías no tenían beneficio | **Fase 2 (DONE)** |

## Decisiones de diseño

| # | Decisión | Por qué |
|---|---|---|
| D1 | El estado vive en `Transaction.productState`, no en una categoría de ingreso nueva | Una categoría por estado multiplicaría las claves (`venta_cafe_cereza`, …) y no serviría para otros cultivos. El estado es un atributo de la venta, no una categoría contable. |
| D2 | `null` = no anotado; no hay valor «otro» | Ni el plátano ni los datos viejos tienen estado de café. Un «otro» inventado ensuciaría los promedios. |
| D3 | El estado solo se guarda en una venta | Es propiedad de lo vendido. Un estado colgado de un gasto se limpia en `fromJson` y se marca `pendingSync` para que la corrección suba. |
| D4 | El precio medio se calcula por moneda, nunca cruzando COP y USD | Misma regla que `currency_totals`: sumar monedas daría un precio que no significa nada. |
| D5 | Rendimiento de trilla como factor por cultivo, no una tabla precargada | Igual que `expectedYieldPerHa`: una tabla Café→rendimiento pondría un número que no aplica a otra altitud ni a otra variedad. Lo escribe el productor. |

## Fase 1 — Estado del café en la venta (DONE)

**Alcance entregado**

- `lib/models/product_state.dart`: enum `cereza · pergamino · verde · tueste`
  con `serialize` y `parse` tolerante.
- `Transaction.productState` con sentinela en `copyWith`, JSON
  (`product_state`) y limpieza en `fromJson` fuera de ventas.
- `addTransaction(productState:)` y payload/pull en `sync_provider`.
- Migración aditiva `202611180001_add_transaction_product_state.sql`.
- Desplegable opcional «Estado del producto» en el bloque de venta de
  `register_screen` (se restaura al editar, se limpia al guardar).
- `lib/services/sales_by_state.dart`: monto, kg, ventas y precio medio/kg por
  estado, en una moneda.
- Tarjeta «Ventas por estado» en Reportes (una sección por moneda).
- 7 claves ARB nuevas en ES/EN.

**Tests**: `test/product_state_test.dart` (13 casos) y
`test/report_sales_by_state_test.dart` (2 de widget).

**Orden de despliegue**: aplicar la migración **antes** de publicar la app;
`buildTransactionPayload` manda la columna a mano y sin ella PostgREST
responde PGRST204 y se cae el subido completo.

## Fase 2 — Beneficio y procesamiento (DONE)

**Objetivo**: registrar lo que cuesta pasar de cereza a pergamino/verde y
saber el costo de beneficio por kilo.

**Alcance entregado**

- `beneficio` («Beneficio y procesamiento») y `secado` («Secado y
  clasificación») en `expenseCategories` y en `_productionKeys` → 21
  categorías; entran al costo de producción y no al bloque de inversión.
- `kBenefitCategoryKeys` / `isBenefitCategory` en `categories.dart`.
- Ambas en `_harvestLinkCategories` de `register_screen`: el gasto se puede
  ligar a la cosecha que benefició.
- `ReportHarvestMetrics.benefitCostPerKg` + `benefitCostCurrencies`: gastos de
  beneficio **con `harvestId`** ÷ kg cosechados. Sin lazo no inventa un costo
  por kg (el gasto sigue en su categoría y en el total del período).
- `_pickupCosts` excluye las categorías de beneficio: beneficiar no es
  recoger, y antes cualquier gasto con `harvestId` subía el costo de recogida.
- Línea «Beneficio y secado por kg» en Reportes, PDF y Excel, todas desde la
  misma función; con monedas mezcladas sale guion y la nota de moneda.
- 5 claves ARB nuevas en ES/EN + ayuda de categoría para cada una.

**Tests**: `test/benefit_cost_test.dart` (9 casos: grupo, catálogo, división,
null sin vínculo / sin gastos / sin kg, borrados, moneda mixta y la exclusión
mutua con recogida).

**Alcance previsto**

1. Categorías de gasto nuevas en `lib/models/categories.dart`:
   - `beneficio` — «Beneficio y procesamiento» (pelado, fermentación, lavado).
   - `secado` — «Secado y clasificación».
   Agregarlas a `_productionKeys` para que entren al costo de producción.
2. Vínculo opcional del gasto de beneficio a una cosecha o cohorte, con la
   misma guarda que hoy tienen `cosecha`, `empaque` y `transporte`
   (`_harvestLinkCategories`), para que el monto entre al costo por kg de la
   cosecha correcta.
3. `report_harvest_metrics`: costo de beneficio por kg, en línea aparte del
   costo de recogida. Sin cosecha vinculada, se muestra como costo del período
   y **no** se reparte a ciegas.
4. l10n ES/EN y textos de ayuda de categoría (`categoryHint`).

**Criterios**

- Un gasto de beneficio sin vínculo no inventa un costo por kg.
- Las cifras de pantalla, PDF y Excel salen de la misma función.
- Migración: ninguna (son categorías, no columnas). Los datos viejos no cambian.

## Fase 3 — Rendimiento de trilla (DONE salvo la alerta)

**Alcance entregado**

- `Crop.threshingYield`: **kg de cereza por 1 kg de pergamino** (5 = de 5 kg
  de cereza sale 1 kg vendible). Se anota por cultivo, no por lote.
- Migración aditiva `202611190001_add_crop_threshing_yield.sql`; payload y pull
  del sync; campo «Rendimiento de trilla» en la ficha del cultivo, con
  validación (un factor ≤ 1 diría que sale más pergamino que cereza).
- `lib/services/threshing_yield.dart`: `sellableKgFromCherry` y
  `threshingRows` con «costo real por kg vendible» = gastos de producción ÷
  kg vendibles. Sin factor, sin cosecha o con monedas mezcladas no hay cifra.
- Bloque «Rendimiento de trilla» en Reportes, PDF y Excel, desde la misma
  función; la fila usa una frase traducida porque la fuente del PDF no tiene
  glifo para «→».
- 15 tests: 12 del servicio y el modelo, 3 de paridad en los exportadores.

**Pendiente**: la alerta de costo real > precio logrado (ítem 4). Se dejó para
cuando haya números reales con los que elegir el umbral.

**Objetivo**: saber cuánto café vendible sale de un kilo de cereza y cuál es el
costo real por kilo vendible.

**Alcance previsto**

1. `Crop`/`Cohort`: factor de rendimiento de trilla opcional
   (`kg pergamino por kg cereza`), escrito por el productor. `null` = no se
   calcula nada.
2. `unsold_stock` y `report_harvest_metrics`: convertir kilos de cereza a
   equivalente vendible solo cuando el factor existe.
3. Indicador «costo real por kg vendible» = (producción + beneficio) /
   kg vendibles, comparado con el precio medio logrado por estado (Fase 1).
4. Alerta cuando el costo real supera el precio logrado en el estado en que
   se vende.
5. l10n ES/EN y tests de que sin factor no se muestra ninguna cifra.

**Depende de**: Fase 1 (precio por estado) y Fase 2 (costo de beneficio).

## Riesgos y límites conocidos

- El estado del café no se deduce de la categoría ni del cultivo: es una
  elección del productor. Sin ella, la tarjeta no aparece.
- El rendimiento de trilla varía por lote y por año; se guarda lo que él anota
  y no se promedia entre lotes sin decirlo.
- Nada de esto requiere cambios de esquema salvo la columna de Fase 1.
