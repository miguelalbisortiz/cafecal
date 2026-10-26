---
status: READY
created: 2026-10-26_1901
updated: 2026-10-26_1901
---

# Cifras del reporte — gastos por ha, recogida por kg y lote cerrado (PRD)

> De dónde sale: prueba en producción del 2026-10-26
> (`docs/reports/2026-10-26_prueba-produccion.md`, F1–F3) y las decisiones
> **D1–D3 ya cerradas con el usuario**. Este documento no implementa: fija el
> alcance, los criterios, el copy y la verificación. El plan de tareas se
> escribe aparte.
> Base de partida: `main` con `flutter analyze` limpio y **1306/1306** tests.

## Contexto y problema

Mi Cafetal es una app Flutter local-first para llevar cultivos, gastos,
jornales, ventas y reportes. La prueba de cierre se hizo en producción con una
cuenta de prueba y una finca de **10 ha** (La Loma) con tres cultivos, cuatro
trabajadores y 24 movimientos: ingresos **4.835.000**, gastos **417.147,84**
(mano de obra 292.147,84 · fijos 125.000), balance **4.417.852,16**, cosechado
y vendido **3.470 kg**.

Tres cifras de esa misma pantalla no cuadran con las demás o desaparecen:

| # | Síntoma en la prueba | Cifra | Causa |
|---|---|---|---|
| F1 | «Por hectárea» ignora el reparto del lote; el desglose sí reparte | café **33.872/ha** en el panel frente a **278.344** (46.391/ha) en el desglose; la diferencia son **75.110,23** de luz, agua y reparación | `lib/widgets/per_hectare_panel.dart:61-62` filtra `t.cropId == c.id`; el desglose usa `repartoPorHectareas` (`lib/services/crop_totals.dart:105`) |
| F2 | «Costo de recogida por kg» da **COP 0** aunque hubo 6 jornales de cosecha (**76.212,48**) | 0 calculado, no dato faltante: se lee «cosechar fue gratis» | `lib/services/report_harvest_metrics.dart:69` suma solo gastos con `harvestId != null`; los jornales de «Cosechar» no llevan ese lazo |
| F3 | Al cerrar el lote del maíz, sus **3.000 kg** siguen en Reporte y desaparecen de la tarjeta | 3.000 kg invisibles | `lib/screens/crops_screen.dart:441-462`: `final kg = abierta ? kilosPorLote[c.sowingId] : null` |

F1 no es un error de suma: son **dos criterios** en la misma pantalla. Quien
decide con el margen por hectárea está viendo un costo que no incluye el gasto
del lote. F2 rompe la regla de oro (`null` → oculto, nunca 0). F3 es
presentación: el dato está, no se pinta.

El reparto del lote divide por la **suma de áreas de los cultivos del lote**
(6 + 3 + 2 = **11 ha**), no por el área del terreno (10 ha). Por eso F4 —11 ha
en un terreno de 10— no es un bug y no se toca: el aviso de Cultivos ya lo dice.

## Objective

Que las tres cifras del reporte digan lo mismo que el resto de la app: el gasto
por hectárea incluye la parte del lote, el costo de recogida suma la mano de
obra de «Cosechar», y el lote cerrado muestra sus kilos. Sin inventar ceros, sin
migración y sin cambiar los totales de Reporte ni el desglose del PDF/Excel.

## Decisiones cerradas (no se reabren)

- **D1 · Unificar «Gastos por ha».** El panel usa el mismo reparto que el
  desglose: gasto cargado al cultivo **más su parte** de los gastos del lote.
  Consecuencia aceptada: café 33.872 → **46.391/ha** (margen 61.961 → 49.442),
  plátano 16.936 → **29.454** (margen 90.546), maíz 12.702 → **25.220**
  (margen 1.924.780). Ninguna cifra de Reporte (ingresos, gastos, balance,
  caja) cambia.
- **D2 · La recogida por kg suma la mano de obra de «Cosechar».** Numerador =
  gastos con `harvestId != null` **+** jornales medidos
  (`isMeasuredHarvestJornal`, `lib/services/derived_harvests.dart:214`).
  Denominador = kilos de las cosechas del período. En la prueba:
  76.212,48 ÷ 3.470 kg = **21,96/kg**. La caja menor (aporte mensual) no entra:
  es un techo de plata, no un costo.
- **D3 · El lote cerrado muestra sus kilos.** Sin kg/planta (con 0 matas vivas
  ese cociente no existe) y sin el «0 matas» de la línea. Solo lectura.

## Success Criteria

Verificables de a uno contra la app corriendo o contra una prueba automática.
`SHALL` / `SHALL NOT` son obligatorios.

### R1 · «Gastos por ha» con el reparto del lote

**Comportamiento.** El panel calcula el gasto de cada cultivo con **la misma
atribución** del desglose: (1) un movimiento con cultivo es de ese cultivo,
aunque traiga lote; (2) un gasto de lote sin cultivo se reparte entre los
cultivos del lote en proporción a su área; (3) si a algún cultivo del lote le
falta el área, **no se reparte** y el panel lo dice; (4) un gasto sin cultivo ni
lote («Costos comunes») no entra al panel.

**Archivos/funciones.** La atribución se extrae a **una** función pura en
`lib/services/crop_totals.dart` que consumen el desglose y el panel; no se
duplica la regla. `lib/widgets/per_hectare_panel.dart` deja de filtrar por
`cropId` para el gasto y pasa a usar esa atribución. La llamada
(`lib/screens/report_screen.dart:476-487`) entrega **todos** los cultivos.

- **R1-1.** WHERE La Loma tiene café 6 ha, plátano 3 ha y maíz 2 ha y 137.702,08
  de gastos del lote, WHEN se abre Reporte → «Por hectárea», the system SHALL
  mostrar en café **`COP 46.391`** en «Gastos por ha» (278.344 ÷ 6), y SHALL NOT
  mostrar 33.872.
- **R1-2.** WHERE los ingresos del período son 575.000 (café), 360.000 (plátano)
  y 3.900.000 (maíz), the system SHALL mostrar los márgenes **`COP 49.442`**,
  **`COP 90.546`** y **`COP 1.924.780`** por ha.
- **R1-3.** The system SHALL NOT cambiar el desglose por cultivo (**278.344**,
  **88.363**, **50.441**) ni los totales de Reporte (**4.835.000**,
  **417.147,84**, **4.417.852,16**).
- **R1-4.** WHERE un lote reparte 110.000 entre 11 ha (6 + 3 + 2), el gasto por
  ha de **cada** cultivo SHALL subir exactamente **10.000** frente al criterio
  de solo lo cargado al cultivo (la parte por hectárea es la misma para todos).
- **R1-5.** WHERE un movimiento trae cultivo **y** lote, the system SHALL
  contar su monto **entero** en ese cultivo y SHALL NOT repartirlo.
- **R1-6.** WHERE un gasto no trae cultivo ni lote, the system SHALL NOT
  incluirlo en el panel; SHALL seguir apareciendo como «Costos comunes» en el
  desglose.
- **R1-7.** IF a un cultivo del lote le falta `areaHa`, the system SHALL mostrar
  en cada cultivo con área **solo** el gasto cargado a ese cultivo, SHALL mostrar
  la nota **«El lote no se reparte: falta el área de un cultivo.»** y SHALL NOT
  repartir ni mostrar `0`.
- **R1-8.** IF los gastos atribuidos al cultivo mezclan monedas, the system
  SHALL NOT mostrar «Gastos por ha» ni «Margen por ha» y SHALL mostrar
  `currencyMixedHint` con el número de monedas; «Ventas por ha» SHALL seguir
  mostrándose con su moneda.
- **R1-9.** WHERE el período no tiene gastos del cultivo, the system SHALL NOT
  mostrar «Gastos por ha» (nunca `COP 0`) y SHALL mantener la regla vigente del
  margen (ventas − 0).
- **R1-10.** The panel SHALL calcular el reparto con **todos** los cultivos de
  la finca y SHALL pintar solo los que tienen área o matas; un cultivo del lote
  sin movimientos pero con área SHALL recibir su parte.
- **R1-11.** The system SHALL NOT cambiar el criterio ni las cifras del bloque
  de recuperación de la inversión (`_cumulativeMargin`, % recuperado, años):
  sigue siendo el margen acumulado de lo cargado al cultivo.
- **R1-12.** The system SHALL NOT agregar «Gastos por ha» al PDF ni al Excel
  (hoy no lo pintan: el rótulo `perHaCostLabel` solo existe en el panel) y el
  desglose de esos dos archivos SHALL quedar idéntico.
- **R1-13.** `helpPerHaCost` SHALL actualizarse en ES y EN para decir que el
  gasto incluye la parte del lote (hoy dice solo «divide tus gastos entre las
  hectáreas»).

### R2 · Costo de recogida por kg

**Comportamiento.** Numerador = gastos no borrados que (a) tienen
`harvestId != null` **o** (b) cumplen `isMeasuredHarvestJornal`; cada gasto
cuenta **una vez**. Denominador = kilos de las cosechas del período (regla
vigente). Si el numerador no tiene **ningún** componente, la cifra es `null`
(oculta), nunca 0.

**Archivos/funciones.** `lib/services/report_harvest_metrics.dart`
(`pickupCostPerKg`, `pickupCostCurrencies`; reutiliza `isMeasuredHarvestJornal`,
no crea otro predicado). Los tres pintadores:
`lib/screens/report_screen.dart:912` (hoy pasa `tx.transactions`: se corrige al
período), `lib/services/pdf_export_service.dart:821,857-864` y
`lib/services/excel_export_service.dart:1309-1319`.

- **R2-1.** WHERE el período tiene 6 jornales medidos de «Cosechar» que suman
  **76.212,48** y cosechas por **3.470 kg**, the system SHALL mostrar **21,96**
  en los tres pintadores (hoy: 0): `COP 21,96` en pantalla y PDF, y `21,96` en
  la celda numérica del Excel (la moneda va donde ya la declara la hoja).
- **R2-2.** The system SHALL contar un gasto **una sola vez** aunque tenga
  `harvestId` y además cumpla el predicado del jornal medido.
- **R2-3.** WHERE ningún gasto entra al numerador, the system SHALL devolver
  `null` y SHALL NOT mostrar `COP 0` en ninguno de los tres pintadores.
- **R2-4.** The system SHALL NOT contar jornales borrados, ingresos, otras
  categorías, otras labores, jornales sin cultivo ni jornales con
  `harvestedKg` nulo o ≤ 0.
- **R2-5.** IF el numerador mezcla monedas, the system SHALL NOT mostrar cifra y
  los tres pintadores SHALL mostrar el **mismo** `currencyMixedHint` con el
  mismo número de monedas (hoy la pantalla oculta la fila sin explicar).
- **R2-6.** The three painters SHALL calcular sobre el **mismo período**: la
  pantalla SHALL dejar de pasar `tx.transactions` y pasar el período (hoy un
  gasto enlazado fuera del período cambia la cifra de la pantalla y no la del
  PDF/Excel).
- **R2-7.** The system SHALL formatear esta cifra con **2 decimales**:
  `COP 21,96` en pantalla y PDF, y `21,96` en la celda numérica del Excel. Es
  un precio unitario, no un total: con los decimales naturales de COP se lee 22.
- **R2-8.** WHERE no hay kilos cosechados en el período, the system SHALL
  devolver `null` (sin fila), como hoy.
- **R2-9.** The system SHALL NOT incluir la caja menor ni el aporte mensual en
  el numerador: `pickupCostPerKg` no lee ajustes.
- **R2-10.** The system SHALL mantener el rótulo, el sitio (sección «Cosechas»)
  y el resto de cifras de esa sección sin cambios (costo total por kg,
  inversión, ventas vs cosechado).

### R3 · Kilos del lote cerrado en la tarjeta

**Comportamiento.** En «Lotes renovados», un lote cerrado pinta sus kilos
medidos, sin kg/planta y sin el «0 matas» de la línea. Solo lectura.
`cohortKilos` ya devuelve los lotes cerrados: **no se toca**.

**Archivos/funciones.** `lib/screens/crops_screen.dart:441-462` (`cohorteLinea`)
y el copy ES/EN.

- **R3-1.** WHERE el lote del maíz (15/09/2026) está cerrado y tiene **3.000 kg**
  medidos en jornales de «Cosechar», WHEN se despliega «Lotes renovados», the
  system SHALL mostrar **`3.000 kg`** en esa línea (hoy no aparece).
- **R3-2.** WHERE el lote está cerrado, the system SHALL NOT mostrar
  `kg/planta`, aunque el lote tuviera matas vivas.
- **R3-3.** WHERE el lote está cerrado, the system SHALL NOT mostrar
  «0 matas»: la línea SHALL usar solo la fecha donde el lote abierto usa
  `{fecha} · {matas} matas`.
- **R3-4.** WHERE el lote cerrado no tiene kilos medidos, the system SHALL NOT
  mostrar `0 kg` ni `0,00 kg/planta`: SHALL omitir la parte de kilos.
- **R3-5.** WHERE el lote está abierto, the system SHALL mostrar exactamente lo
  de hoy (kilos y kg/planta si los hay).
- **R3-6.** WHERE el cultivo tiene una sola edad, la tarjeta SHALL verse como
  hoy (sin sección de edades).
- **R3-7.** The línea del lote cerrado SHALL ser de solo lectura: SHALL NOT
  agregar toques, acciones ni un kg/planta calculado.
- **R3-8.** The system SHALL NOT cambiar el total de kilos del cultivo ni las
  cifras de Reporte, PDF o Excel.
- **R3-9.** El copy nuevo SHALL existir en ES y EN con las mismas claves y los
  mismos placeholders, en el orden en que se leen.

### Copy, formato y gate

- **SC-C1.** `lib/l10n/app_es.arb` es la plantilla; después `gen-l10n` y se
  commitea `lib/l10n/generated/`. Archivos en **LF**. No se corre `dart format`.
- **SC-C2.** Claves nuevas: `perHaLotNotSplit` (sin placeholders) y
  `sowingCohortDateOnly` (`date` String). Clave modificada: `helpPerHaCost`.
  Cero «cohorte»/«cohort» en el copy visible.
- **SC-C3.** Gate antes de commit: `C:\flutter\bin\flutter.bat analyze`
  (proyecto entero) limpio y `flutter test` en verde con los **1306** tests
  actuales más los nuevos.

## Copy ES/EN

Claves nuevas en `lib/l10n/app_es.arb` (plantilla) y `app_en.arb`, cada una con
su bloque `@clave`. Los placeholders se declaran en el orden en que se leen
(`test/l10n_placeholder_order_test.dart`).

| Clave | ES | EN | Placeholders |
|---|---|---|---|
| `perHaLotNotSplit` | El lote no se reparte: falta el área de un cultivo. | The lot isn't split: a crop is missing its area. | — |
| `sowingCohortDateOnly` | {date} | {date} | `date` String |
| `helpPerHaCost` (modificada) | Cuánto cuesta producir en cada hectárea. Suma los gastos del cultivo y su parte de los gastos del lote, y divide entre sus hectáreas. | How much each hectare costs to produce. It adds the crop's expenses plus its share of the lot's expenses, and divides by its hectares. | — |

Reglas de copy: **«lote»**, no «cohorte»; **«matas»** para café; nunca «0» para
un dato ausente; la cifra de dinero siempre con su código de moneda.

## Casos límite

| Caso | R | Qué debe pasar |
|---|---|---|
| Cultivo sin área, solo en su lote | R1 | Sin «Gastos por ha» (null). Sin nota: no hay nada que repartir con otros |
| Terreno con un cultivo sin área | R1 | No se reparte: cada cultivo con área muestra solo lo cargado + la nota; nunca 0 |
| Gasto con cultivo **y** lote | R1 | Manda el cultivo: 100 % a ese cultivo, sin repartir |
| Gasto sin cultivo ni lote | R1 | «Costos comunes» del desglose; no entra al panel |
| Monedas mezcladas en el panel | R1 | Gastos/ha y margen ocultos + `currencyMixedHint(N)`; ventas/ha con su moneda |
| Período sin gastos | R1 | Sin «Gastos por ha»; margen = ventas (regla vigente) |
| Cultivo del lote sin movimientos pero con área | R1 | Recibe su parte del lote y muestra gastos/ha (el lote le sirve) |
| Lote con un solo cultivo | R1 | Fracción 1: igual que hoy |
| F4 · 11 ha en un terreno de 10 | R1 | El reparto divide por 11; el aviso de Cultivos → Terrenos no cambia |
| Período sin gastos de recogida | R2 | Sin fila; nunca `COP 0` |
| Jornal de «Cosechar» sin kilos | R2 | No entra al numerador |
| Jornal que ya tuviera `harvestId` | R2 | Cuenta una sola vez |
| Monedas mezcladas en la recogida | R2 | Sin cifra; mismo aviso en pantalla, PDF y Excel |
| Período sin cosechas | R2 | `null` (denominador 0), sin fila |
| Lote cerrado con kilos | R3 | Muestra `3.000 kg`; sin kg/planta; sin «0 matas» |
| Lote cerrado sin kilos medidos | R3 | Sin kilos; nunca `0 kg` |
| Lote cerrado con cosecha manual del cultivo | R3 | Sin kilos (`cohortKilos` vacío por D10-A de la etapa B) |
| Cultivo con una sola edad | R3 | Tarjeta igual que hoy |

## Verificación manual (con los datos de la prueba)

Cuenta `prueba@gmail.com`, finca La Loma, período que cubre los 24 movimientos.
Cifras mostradas, redondeadas al peso (COP 0 decimales).

1. **Por hectárea.** Debe verse:

   | Cultivo | ha | Gastos/ha antes | **Gastos/ha** | Margen/ha antes | **Margen/ha** |
   |---|---|---|---|---|---|
   | Café | 6 | 33.872 | **COP 46.391** | 61.961 | **COP 49.442** |
   | Plátano | 3 | 16.936 | **COP 29.454** | 103.064 | **COP 90.546** |
   | Maíz | 2 | 12.702 | **COP 25.220** | 1.937.298 | **COP 1.924.780** |

   Control: la subida por hectárea es la misma en los tres (≈ 12.518 =
   137.702,08 ÷ 11, con el residuo de centavos en el último cultivo). «Ventas
   por ha», kg/ha y kg/planta no cambian.
2. **Desglose por cultivo.** Café **278.344**, plátano **88.363**, maíz
   **50.441**; sin fila «sin repartir». Ingresos **4.835.000**, gastos
   **417.147,84**, balance **4.417.852,16**, caja igual.
3. **Cosechas.** «Costo de recogida por kg» **`COP 21,96`** (antes `COP 0`).
   Mismo valor en el PDF y en el Excel.
4. **PDF y Excel.** El desglose y los totales salen idénticos. **No** aparece
   «Gastos por ha» en ninguno de los dos (verificado en el código: el rótulo
   solo lo usa el panel).
5. **Tarjeta del cultivo.** En «Lotes renovados» del maíz:
   `15/09/2026 · 2 ha · 3.000 kg · Renovada en MM/AAAA`. Sin «0 matas», sin
   kg/planta. Los lotes abiertos del café siguen con `180 kg` / `50 kg` y su
   kg/planta.
6. **Nota del reparto.** Quitar el área del plátano (Cultivos) y volver a
   Reporte: café y maíz muestran solo su gasto cargado y la nota «El lote no se
   reparte: falta el área de un cultivo.». Restaurar el área.
7. **Moneda mixta.** Anotar un gasto de 10 USD contra La Loma: los tres
   cultivos ocultan gastos/ha y margen y muestran «Se muestra en 2 monedas»;
   ventas/ha sigue en COP. Borrar el gasto.
8. **Sin migración.** No hay columna ni SQL nuevo: el sync y el respaldo no
   cambian. Guardar un jornal sin señal y comprobar que sube igual que antes.

## Plan de pruebas

Cada arreglo entra con **test en rojo primero**: falla por la razón correcta
antes del cambio. Donde no exista rojo posible se declara **guarda**.

### R1

| Test | Archivo | Rojo porque | Verde |
|---|---|---|---|
| café 240.000 propios + 60.000 del lote (110.000 entre 6/3/2 ha) → 300.000 ÷ 6 = 50.000/ha; margen 50.000 | `test/per_hectare_panel_reparto_test.dart` (nuevo) | hoy muestra 40.000/ha (solo lo cargado) | panel con el reparto |
| los tres cultivos suben 10.000/ha con la misma parte | ídem | ídem | R1-4 |
| falta el área de un cultivo → solo lo cargado + nota | ídem | hoy no existe la nota | R1-7 |
| gasto con cultivo y lote → 100 % al cultivo | ídem | guarda: hoy el panel ya lo cuenta así | R1-5 |
| «Costos comunes» no entran al panel | ídem | guarda del criterio | R1-6 |
| moneda mixta por el reparto → sin gastos/ha ni margen + aviso | ídem | hoy la moneda del lote no entra al conjunto | R1-8 |
| período sin gastos → sin línea | ídem | guarda | R1-9 |
| el panel y el desglose dan el mismo gasto por cultivo | `test/crop_totals_test.dart` (ampliar) | guarda cruzada | R1-1/R1-10 |
| el bloque de recuperación no cambia | `test/per_hectare_panel_test.dart` (ampliar) | guarda | R1-11 |
| `perHaCostLabel` solo se usa en el panel (no hay cuarto pintador) | `test/per_ha_single_criterion_test.dart` (nuevo, barrido de fuente) | guarda | R1-12 |

Guardas que deben seguir verdes sin tocarse: `test/gasto_de_lote_test.dart`,
`test/crop_totals_test.dart` (desglose), tests de Reportes/PDF/Excel.

### R2

| Test | Archivo | Rojo porque | Verde |
|---|---|---|---|
| 6 jornales 76.212,48 ÷ 3.470 kg = 21,96 | `test/report_harvest_metrics_test.dart` (**reescribir el de la línea 481**, que hoy fija el 0) | hoy da 0 | R2-1 |
| sin ningún gasto de recogida → `null`, no 0 | ídem | hoy da 0 | R2-3 |
| jornal sin kilos, borrado, ingreso, otra labor/categoría, sin cultivo → no entra | ídem | guarda | R2-4 |
| jornal con `harvestId` cuenta una vez | ídem | guarda: el numerador no puede duplicar | R2-2 |
| monedas mezcladas por un jornal de «Cosechar» en otra moneda → `null` y las dos monedas | ídem | hoy el jornal no entra al conjunto de monedas | R2-5 |
| sin kilos → `null` | ídem | guarda | R2-8 |
| pantalla, PDF y Excel dicen 21,96 en el mismo sitio | `test/report_pickup_parity_test.dart` (nuevo) | pantalla da 0 y formatea COP 22 | R2-1/R2-7 |
| gasto enlazado fuera del período no cuenta en la pantalla | ídem | hoy la pantalla pasa todo el histórico | R2-6 |
| monedas mezcladas: los tres sin cifra y con el mismo aviso | ídem | hoy la pantalla oculta sin aviso | R2-5 |
| la caja menor no entra | ídem | guarda | R2-9 |

Guardas: `test/mixed_currency_gap_test.dart` (Excel numérico 500 y `—` con
mezcla) y las filas de costo total por kg siguen iguales.

### R3

| Test | Archivo | Rojo porque | Verde |
|---|---|---|---|
| lote cerrado con 3.000 kg muestra `3.000 kg` | `test/crops_screen_cohort_kilos_test.dart` (ampliar) | hoy pasa `kg = null` al cerrar | R3-1 |
| lote cerrado sin kg/planta | ídem | guarda: al mostrar kilos no se cuela el cociente | R3-2 |
| lote cerrado sin «0 matas» | ídem | hoy la línea dice «0 matas» | R3-3 |
| lote cerrado sin kilos → sin kg, sin 0 | ídem | guarda | R3-4 |
| lote abierto igual que hoy | ídem | guarda | R3-5 |
| una sola edad: tarjeta igual | `test/crops_screen_cohorts_test.dart` | guarda | R3-6 |
| total del cultivo y Reporte no cambian | `test/crops_screen_cohort_kilos_test.dart` | guarda | R3-8 |

### Copy

`test/l10n_cifras_reporte_test.dart` (nuevo): `perHaLotNotSplit` y
`sowingCohortDateOnly` en ES y EN, mismos placeholders y en orden de lectura;
`helpPerHaCost` actualizado en los dos; sin «cohorte»; cifras como `String`.
`test/l10n_placeholder_order_test.dart` sigue verde.

Total previsto: **~15 rojos nuevos + 14 guardas**.

## Fuera de alcance

- **F4** (11 ha de cultivos en un terreno de 10): no es bug; el aviso de
  Cultivos → Terrenos ya lo dice y no se toca.
- **Atribución por venta**: la venta sigue apuntando a un cultivo o a ninguno.
- **Repartir una venta entre lotes**, por edad, por área o por precio.
- **Caja menor / aporte mensual como costo**: es un techo de plata.
- **El bloque de recuperación de la inversión** (`_cumulativeMargin`): sigue
  con el criterio de lo cargado al cultivo; unificarlo es otra tanda.
- **Migración de base o columna nueva**: ninguno de los tres arreglos la
  necesita; la cuenta se usa en un solo equipo.
- Cambiar el desglose, el PDF o el Excel más allá del costo de recogida; tocar
  `_numKg`; recepa/socola; asocio; presupuesto por tarea; rediseñar el panel.

## Assumptions

- Los 6 jornales de «Cosechar» de la prueba tienen kilos (> 0) y cultivo; si
  alguno no, no entra y la cifra baja: es el mismo criterio, no un error.
- El período del reporte en la prueba cubre los 24 movimientos.
- El reparto divide por la suma de áreas de los cultivos del lote (11 ha), no
  por el área del terreno (10 ha): es la regla vigente del desglose.
- Los 3.000 kg del maíz salen de jornales de «Cosechar», no de una cosecha
  guardada a mano (si fuera manual, `cohortKilos` devuelve vacío por D10-A).

## Users

- **Primario**: el productor dueño de la finca, que decide con el margen por
  hectárea y con el costo de recogida.
- **Secundario**: quien lee el PDF o el Excel (contador o socio) y espera las
  mismas cifras que la pantalla.
- **No es para**: contabilidad por lote ni reparto de una venta mixta.

## Constraints

- Local-first: todo funciona sin red; no se toca sync ni respaldo.
- Regla de oro: `null` → oculto con su motivo, nunca 0; nunca inventar cifras.
- Un solo criterio por cifra: pantalla, PDF y Excel dicen lo mismo.
- Moneda única: código (COP/USD/CLP), nunca `$`; con mezcla, la cifra se oculta
  o se lista por moneda con `currencyMixedHint`.
- Test en rojo primero; sin rojo posible se declara guarda.
- Copy ES/EN; `app_es.arb` plantilla; `gen-l10n` y `generated/` commiteado en
  LF; no `dart format`.
- Gate: `C:\flutter\bin\flutter.bat analyze` + `flutter test` (1306/1306).

## Riesgos y cómo se mitigan

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| El margen por ha baja (≈ 12.518/ha en los tres) y se lee como que la finca empeoró | alta | medio | Es la cifra correcta: incluye el gasto del lote. Se actualiza `helpPerHaCost` ES/EN y el informe de cierre lo explica; los totales y el desglose no cambian |
| El bloque de recuperación sigue sin repartir y convive con el gasto/ha ya repartido | cierta | bajo | Divergencia declarada (fuera de alcance): es un margen acumulado histórico, no una cifra por hectárea. Si se pide, se unifica en otra tanda |
| La pantalla cambia de cifra al pasar la recogida al período | media | bajo | Es la corrección: los tres pintadores quedan iguales. Test con un gasto enlazado fuera del período |
| Los 2 decimales del costo de recogida rompen la convención de COP 0 | cierta | bajo | Es un precio unitario, no un total: sin decimales, 21,96 se lee 22. Solo esa fila; documentado en el copy del informe |
| Un gasto de lote en otra moneda apaga el margen de un cultivo | baja | medio | Regla vigente: no se restan monedas. Se muestra el aviso con el número de monedas |
| Alguien pasa al panel solo los cultivos con área y cambia el reparto | media | alto | R1-10: el panel recibe todos los cultivos; test con un cultivo sin movimientos en el lote |
| El Excel y el PDF divergen en formato o en presencia de la fila | media | medio | Test de paridad de los tres pintadores (R2-1, R2-5, R2-7) |
| Se toca `cohortKilos` «para arreglar» F3 y se mueve la atribución | baja | alto | R3: el arreglo es solo de presentación; `cohortKilos` ya devuelve los lotes cerrados |

## Milestones

1. **R1 · reparto.** Atribución única en `crop_totals.dart`, panel, nota, Ayuda
   y tests (rojo primero + guardas del desglose).
2. **R2 · recogida.** Predicado compartido, numerador, tres pintadores, 2
   decimales y paridad.
3. **R3 · lote cerrado.** Línea del lote, copy y tests de la tarjeta.
4. **Cierre.** ARB ES/EN + `gen-l10n`, guardas, `analyze` + `test`, informe de
   cierre con la verificación manual de arriba.

## Status

**READY** — D1–D3 cerradas por el usuario; sin preguntas abiertas. Listo para
`/plan`.
