# Análisis: cálculos financieros y recomendaciones

Fecha: 2026-11-17. Alcance: solo lectura. No se propone código; las recomendaciones de negocio son sugerencias analíticas con datos que la app ya registra.

Fuentes prioritarias: `report_insights_service.dart`, `alert_service.dart`, `recommendations.dart`, `report_harvest_metrics.dart`, `report_payroll_metrics.dart`, `currency_totals.dart`, `crop_totals.dart`, `next_step_service.dart`, `derived_harvests.dart`, `report_screen.dart`, `pdf_export_service.dart`, `excel_export_service.dart`, `app_es.arb`, tests. Auxiliares: `recommendations.dart`, `low_price_check.dart`, `product_contribution.dart`, `per_hectare_panel.dart`, `alerts_banner.dart`, `top_accounts.dart`, `metric_signal.dart`.

---

## 1. Inventario de métricas y fórmulas

| Métrica / conclusión | Fórmula o regla | Guarda | Evidencia |
|---|---|---|---|
| Balance | `ingresos - gastos` | Calla si no hay movimientos | `lib/services/report_insights_service.dart:106-111` |
| Margen sobre ventas | `balance / ingresos * 100` | `ingresos > 0`; si no, `null` | `lib/services/report_insights_service.dart:108-109` |
| Veredicto de margen | `>=20` bueno · `10-20` justo · `0-10` bajo · `<0` pérdida · `0` empate | `null` → `noSales` | `lib/services/metric_signal.dart:103-110` |
| Ratio gasto/ingreso | `gastos / ingresos * 100` | `<=70` sano · `>70-90` alto · `>90` crítico | `lib/services/metric_signal.dart:112-118` |
| Delta vs mes anterior | `(actual - anterior) / anterior * 100`; sin base → `100` si hay actual, si no `0` | Mes anterior recortado al mismo día (`sameDayWindow`) | `lib/services/period_delta.dart:16-33`; `report_insights_service.dart:130-155` |
| Mayor gasto | Suma por `t.category`; `% = top / total gastos * 100` | Moneda única; `>=50%` añade aviso de dependencia o capital | `report_insights_service.dart:162-193`, `286-303` |
| Mayor ingreso | Suma por `incomeGroupKey(category, cropId)`; `% = top / total ingresos * 100` | Moneda única; separa «Venta Café» de «Venta Plátano» | `report_insights_service.dart:197-211`, `286-303`; `lib/l10n/strings.dart:101` |
| Precio bajo | `promedio(amount/kg)` últimos 30 d vs histórico | ≥3 ventas con kg, ≥2 recientes, moneda única, histórico >0 | `lib/services/low_price_check.dart:10`, `63-106`; `report_insights_service.dart:213-227` |
| Mejor mes / menor gasto | Ranking de meses del año con ingresos/gastos | Solo año completo; ≥2 meses activos; moneda única | `report_insights_service.dart:232-277` |
| Costo/kg del período | `gastos / kg cosechados` | `kg > 0`; moneda única | `report_harvest_metrics.dart:308-320` |
| Costo/kg por cultivo | `gastos de operación / kg cosechados` del cultivo | Cultivo anual o en producción; kg>0; moneda única; excluye inversión | `report_harvest_metrics.dart:209-236` |
| Costo de recogida/kg | `(gastos con harvestId + jornal medido) / kg` | `kg>0`, hay gasto, moneda única; sin duplicar ids | `report_harvest_metrics.dart:145-173`, `179-196` |
| Precio de venta/kg | `ingresos / kg vendidos` | Solo ventas con cantidad convertible; `kg>0` | `report_harvest_metrics.dart:322-341` |
| Margen por kg | `precio/kg - costo/kg` con veredicto arriba/abajo/igual | `null` → no se puede calcular | `lib/services/metric_signal.dart:44-80`; ARB `metricCostPriceAbove:912` |
| Rendimiento por ha / planta | `kg / areaHa` · `kg / plantasVivas` | Área o plantas >0 y kg>0 | `report_harvest_metrics.dart:343-361` |
| Rendimiento histórico | `promedio(kg de años calendario cerrados) / areaHa` (y /plantas) | Años completos, `minYears=2`, moneda n/a | `report_harvest_metrics.dart:363-414` |
| Nómina y caja | Total por moneda; aporte del mes + arrastre de sobrantes | Arrastre `null` si mezcla monedas | `report_payroll_metrics.dart:14-30`, `50-60`, `309-361` |
| Mano de obra sobre gasto | `payrollTotal / gastos del período * 100` | Sin mezcla; una sola moneda de gasto; payroll>0 | `report_screen.dart:1217-1231` |
| Por cobrar | `receivablesByCurrency(records)`; severidad sube a los 30 días | Si mezcla monedas, no se cita total | `report_screen.dart:2437-2439`; `alert_service.dart:734-763` |
| Aporte por producto | `ingresos - gastos directos` por cultivo/mes/moneda | Lote y comunes van aparte, sin repartir | `product_contribution.dart:36-46`, `59-89`, `165-232` |
| Cobertura del café | `aporte acumulado de otros cultivos / inversión acumulada de siembra del café * 100` | Sin dato o moneda mixta → «No se calcula» | `product_contribution.dart:235-305`; ARB `contributionCoverageNoData:1647` |
| Totales por moneda | Suma separada por código ISO; `isMixed = byCurrency.length > 1` | Nunca suma COP+USD+CLP | `currency_totals.dart:10-21`, `48-88`, `143-151` |

---

## 2. Inventario de recomendaciones / alertas y conclusiones

Motor: 12 llamadas de regla en `lib/services/alert_service.dart:105-120`; contrato `AlertRule` en `lib/models/farm_alert.dart:15-30`. Todas llevan `title`, `message` y `suggestion`.

| Regla | Clave ARB (título / mensaje / sugerencia) | Texto español (extracto) | Accionabilidad |
|---|---|---|---|
| Gasto excesivo | `alertExcessTitle:1161`, `alertExcessMessage:1169`, `alertExcessSuggestion:1170` | «Tu gasto en {category} casi se duplicó» · «Revisa qué generó ese aumento…» | Alta en banner; baja en «Qué hacer» |
| Gastos sin ventas | `alertNoIncome*:1171-1176` | «Hay gastos registrados, pero cero ventas» · «Regístrala como ingreso…» | Alta |
| Sin ventas recientes | `alertNoSales*:1180-1185` | «Hace {days} días que no registras ventas» | Alta |
| Pérdidas consecutivas | `alertLosses*:1189-1194` | «{count} meses seguidos con pérdidas» · «Revisa tus costos fijos…» | Media (genérica) |
| Precio bajo histórico | `alertLowPrice*:1195-1203` | «Vendes a {recentAvg} por kilo, por debajo de {histAvg}» | Alta |
| Precio mínimo manual | `alertLowPriceManual*:1204-1212` | «Vendiste café por debajo de tu precio mínimo» | Alta |
| Déficit sin cultivo | `alertDeficitNoCrop*:1213-1224` | «{count} registros sin cultivo… solo has recuperado el {recovery}» | Alta |
| Déficit por cultivo | `alertDeficit*:1230-1243` | «{crop} está perdiendo dinero» | Alta |
| Establecimiento | `alertCropEstablishment*:1361-1369` | «{crop} todavía no da: es inversión, no pérdida» | Media (esperar) |
| Vendido > cosechado | `alertHarvestVsSales*:1373-1381` | «Vendiste más de lo que cosechaste en {crop}» | Alta |
| Siembra reciente | `alertRecentlyPlanted*:1382-1387` | «Verifica que el número de plantas vivas…» | Alta |
| Primera cosecha vencida | `alertFirstHarvest*:1391-1396` | «{crop} ya debería estar rindiendo» | Alta |
| Ventas sin kilos | `alertMissingQty*:1397-1402` | «{count} ventas sin la cantidad vendida» | Alta |
| Por cobrar | `alertUnpaid*:1411-1413` | «{count} ventas suman {amount}… la más vieja con {days} días» | Alta |
| Caja menor | `alertCashBoxWarning*:1415-1427`, `alertCashBoxDanger*:1428-1440`, `alertCashBoxDebtMessage:1448` | «Te quedan {remaining} antes de agotarla» · «Caja menor agotada» | Alta |

Conclusiones del período (no son recomendaciones; no llevan `suggestion`): balance, vs mes anterior, mayor gasto (+ dependencia/capital), mayor ingreso, precio bajo, mejor mes. Claves `insightBalance*:1080-1082`, `insightVsPrev*:1090-1100`, `insightTopExpense*:1110-1120`, `insightTopIncome:1120`, `insightLowPrice:1127`, `insightBestMonth:1136`.

**Hallazgo crítico.** `RecommendationService.derive` copia solo `title` y `message`; descarta `suggestion` (`lib/services/recommendations.dart:47-52`). El banner de Inicio sí pinta `a.suggestion` (`lib/widgets/alerts_banner.dart:90-100`). Resultado: «Qué hacer» queda como diagnóstico («El problema:…») sin la acción concreta que el motor ya redactó. El orden por severidad, dedupe por regla y sin tope sí están cubiertos (`test/report_recommendations_test.dart:19-59`).

---

## 3. Por cultivo vs agregado; gasto repartido vs total

- **Agregado:** balance, margen, ratio, delta mensual, mejor mes y mayor gasto son del período completo. El mayor gasto es por **categoría**, no por cultivo (`report_insights_service.dart:162-193`, `286-303`).
- **Por cultivo:** el mayor ingreso usa `incomeGroupKey`, que separa ventas por `cropId` (`strings.dart:101`; `report_insights_service.dart:294-295`). Las alertas de déficit, establecimiento, cosecha vs venta y primera cosecha filtran por `cropId` (`alert_service.dart:377-502`, `506-567`, `786-818`). El desglose y el costo/kg por cultivo también son por `cropId` (`crop_totals.dart:262-345`; `report_harvest_metrics.dart:209-236`).
- **Dos modelos de atribución conviven (no es un bug):**
  1. *Reparto*: gasto de lote dividido entre cultivos por hectáreas (`repartoPorHectareas`, `crop_totals.dart:104-113`; `splitLotExpenses`, `131-177`; alertas usan la misma regla en `alert_service.dart:404-419`). Si un cultivo no tiene área, no se reparte y aparece como fila «sin repartir».
  2. *Sin reparto*: «Aporte por producto» deja gastos de lote y comunes en bloques aparte (`product_contribution.dart:165-232`; ARB `contributionSubtitle:1606`, `contributionUnassigned:1624`, `contributionCommon:1625`).
- Consecuencia práctica: el mismo gasto puede verse **repartido** en el desglose/costo por kg y **aparte** en aporte por producto. Hay que leer la etiqueta de la tarjeta antes de comparar cifras.
- Con tasa de conversión el agregado se muestra convertido; sin tasa, el desglose por moneda manda y no hay balance global (`report_screen.dart:2410-2435`, `2500-2533`; tests `test/report_screen_test.dart:725-812`).

---

## 4. Moneda mixta COP / USD / CLP y guarda

- El código usa códigos ISO (`COP`, `USD`, `CLP` en tests) y nunca suma monedas: `isMixedCurrency`, `totalsByCurrency`, `ConvertedPeriodTotals` (`currency_totals.dart:10-21`, `48-88`, `143-151`). El símbolo `$` es compartido, por eso los avisos escriben el código: «COP 1.500» (`alert_service.dart:125-129`).
- Guardas por regla: gasto excesivo, sin ingresos, pérdidas, déficit, cosecha vs venta, caja, por cobrar y primera cosecha (`alert_service.dart:183-185`, `321-323`, `426-427`, `652-653`, `746-747`, `826-829`).
- Precio bajo se calla con mezcla (`low_price_check.dart:78-79`); mejor mes y mayor gasto/ingreso también (`report_insights_service.dart:169`, `202`, `243`).
- Nómina y caja se agrupan por moneda; el arrastre de caja devuelve `null` si mezcla (`report_payroll_metrics.dart:14-30`, `50-60`, `309-361`).
- Pantalla: con tasa → total convertido + aviso; sin tasa → desglose por moneda y sin resultado global (`test/report_screen_test.dart:725-812`). Costo/kg y precio/kg se ocultan aunque haya tasa si el período es mixto (`report_screen.dart:2572-2599`).

---

## 5. Regla null → oculto

- Devuelven `null` y la UI omite la línea: `pickupCostPerKg` (`report_harvest_metrics.dart:156-173`), `totalCostPerKg` (`215-236`), `periodCostPerKg` (`314-320`), `avgSalePricePerKg` (`327-341`), `yieldPerArea` / `yieldPerPlant` (`345-361`), `historicalYield` (`385-414`), arrastre de caja (`report_payroll_metrics.dart:309-361`). La derivación de cosecha omite cantidades `null` (`derived_harvests.dart:174-176`) y las métricas ausentes no se pintan (`report_screen.dart:2574-2599`).
- Excepción documentada: `_kgOf` usa `?? 0` para cosechas sin peso (`report_harvest_metrics.dart:98-103`) y `_checkHarvestVsSales` usa `qty ?? 0` (`alert_service.dart:520-528`). Se compensa con:
  - listas de «Sin peso» / pesos pendientes (`report_harvest_metrics.dart:607-626`; `report_screen.dart:1086-1119`; tests `test/report_screen_test.dart:1288-1296`, `1332-1334`);
  - alerta de ventas sin kilos, que sí convierte el dato faltante en recomendación (`alert_service.dart:602-623`).
- Matiz: cuando el costo existe pero está en moneda mixta, la app no solo oculta: usa `pickupCostCurrencies` para decidir si pinta guion en vez de borrar la fila (`report_harvest_metrics.dart:151-155`, `189-196`).

---

## 6. Recomendaciones de negocio faltantes (8, con dato ya registrado)

Textos **nuevos**, propuestos para análisis; aún no tienen clave ARB. No requieren inventar datos ni cambiar cálculos existentes.

| # | Dato existente | Cálculo | Texto propuesto (es) | Evidencia | Beneficio |
|---|---|---|---|---|---|
| 1 | Kg cosechados y kg vendidos por cultivo en 12 meses | `stockKg = cosechaKg - ventaKg`, solo si >0 | «Te quedan {kg} kg de {cultivo} cosechados y no vendidos en los últimos 12 meses. Define comprador o presentación antes de la próxima cosecha.» | `report_harvest_metrics.dart:308-341`; `derived_harvests.dart:174-176`; regla inversa solo avisa vendido>cosechado en `alert_service.dart:520-528` | Convierte stock en caja; evita cosechar de más |
| 2 | Rendimiento del período y rendimiento histórico propio | `delta = (actual - hist) / hist * 100` si `hist>0` y `years>=2` | «Este período rindes {actual} kg/ha, {delta}% {más/menos} que tu promedio de {years} años ({hist} kg/ha). Revisa densidad, riego o recogida antes de la próxima siembra.» | `report_harvest_metrics.dart:345-352`, `385-414`; `per_hectare_panel.dart:95-101` | Diagnostica brecha contra su propia finca, no contra tabla externa |
| 3 | Comprador principal y total de ventas del período | `share = cliente / ingresos * 100`, moneda única | «El {pct}% de tus ventas del período vienen de {cliente}. Busca un segundo comprador antes de depender de uno solo.» | `top_accounts.dart:14-40`, `57-75`; `report_screen.dart:346`, `3242-3294`; `pdf_export_service.dart:700-706` | Reduce riesgo de precio y de impago concentrado |
| 4 | Descuento del comprador (kg, motivo, entrega ligada) | `pctDesc = deductionQty / kgEntregados * 100` | «El comprador descontó {kg} kg ({pct}%) por {motivo}. Compara con otros compradores y negocia el límite de impureza o humedad.» | `transaction.dart:147-155`; `transaction_provider.dart:704-707`; ARB `deductionSwitchLabel:1401-1428` | Recupera valor hoy desapercibido en el pesaje |
| 5 | Uso de caja del mes y límite con arrastre | `diario = used / díasTranscurridos`; `días = (limit - used) / diario` | «A este ritmo, la caja menor te alcanza para {días} días más. Deja solo los gastos necesarios hasta cerrar el mes.» | `report_payroll_metrics.dart:309-361`; `alert_service.dart:642-654`, `667-690` | Anticipa recorte antes de agotar la caja (hoy solo dice «te quedan X») |
| 6 | Ingresos y gastos por cultivo en el desglose | `margen = (ingresos - gastos) / ingresos * 100` por cultivo | «En el período {cultivoA} deja {mA}% de margen y {cultivoB} {mB}%. Con el mismo peso de trabajo, prioriza {cultivoA}.» | `crop_totals.dart:262-345`; `report_screen.dart:411`; ARB `cropBreakdownMarginHint:949` | Asigna mano de obra al cultivo que mejor paga |
| 7 | Gasto repartido y área por cultivo; ingreso por hectárea | `costoHa`, `ingresoHa`, `margenHa = ingresoHa - costoHa` | «En {cultivo} gastas {costoHa}/ha y recibes {ingresoHa}/ha: {margenHa}/ha. Revisa ese lote antes de seguir invirtiendo.» | `crop_totals.dart:104-113`, `131-177`; `report_harvest_metrics.dart:417-419` | Enfoca la decisión por lote, no por total finca |
| 8 | Jornales por cultivo y gastos de operación del cultivo | `pct = jornalesCultivo / gastosOperaciónCultivo * 100` | «La mano de obra es el {pct}% del costo de {cultivo}. Si sube el jornal, sube el costo por kilo de ese cultivo.» | `report_payroll_metrics.dart:14-30`, `50-60`; `report_harvest_metrics.dart:215-233`; `report_screen.dart:1226-1231` | Prevé el impacto del jornal en el costo por kilo |

Nota: la cobertura del café y el margen por kilo **ya existen** como panel/caption (`product_contribution.dart:235-305`; `metric_signal.dart:44-80`; ARB `contributionCoverageLine:1637`, `metricCostPriceAbove:912`), por eso no se repiten como faltantes.

---

## 7. Pantalla vs PDF vs Excel

| Contenido | Pantalla | PDF | Excel |
|---|---|---|---|
| «Conclusión del período» (insights) | Sí: `build` y tarjeta en `report_screen.dart:159`, `285-307` | No: sin llamada a `ReportInsightsService` | No: sin llamada a `ReportInsightsService` |
| «Qué hacer» | Sí, con «No hay recomendaciones…» si está vacío (`report_screen.dart:1971-1996`; ARB `reportNoRecommendations:321`) | Sí, pero `SizedBox.shrink()` si está vacío: la sección desaparece sin explicación (`pdf_export_service.dart:1779-1789`) | Sí, con «No hay recomendaciones…» (`excel_export_service.dart:1969-1982`) |
| Motor de recomendaciones | `evaluateAlerts` + `derive` (`report_screen.dart:1971-1979`) | Igual con `history` (`pdf_export_service.dart:1779-1788`) | Igual con `active` (`excel_export_service.dart:1971-1979`; `active` filtra borrados en `:64`) |
| Métricas / costo por kg / rendimiento | Sí (`report_screen.dart:2434-2451`, `2574-2599`) | Sí (`pdf_export_service.dart:1226-1249`) | Sí (`excel_export_service.dart:1807-1830`) |
| Desglose por cultivo | Sí (`:411`) | Sí (`:1226-1249`) | Sí (`:1807-1830`) |
| Principales compradores | Sí (`report_screen.dart:346`, `3242-3294`) | Sí (`pdf_export_service.dart:698-706`) | No: sin uso de `TopAccounts` en el archivo |
| Texto de la acción sugerida | Se pierde en «Qué hacer» (`recommendations.dart:47-52`), pero el banner de Inicio sí la muestra (`alerts_banner.dart:90-100`) | Se pierde igual | Se pierde igual |

Divergencias a tener en cuenta al leer un reporte exportado: la conclusión del período solo vive en pantalla; el PDF calla cuando no hay recomendaciones; Excel omite «Principales compradores»; y en los tres exportadores «Qué hacer» pierde la sugerencia que el motor sí redactó.

---

## Hallazgos priorizados (solo análisis)

1. **Acción perdida:** `derive` descarta `suggestion`; los tres pintadores muestran solo el diagnóstico (`recommendations.dart:47-52`).
2. **Conclusión no exportada:** el texto más leído de Reportes no aparece en PDF ni Excel.
3. **Cobertura desigual:** PDF silencia el caso vacío; Excel no trae compradores; pantalla es la fuente más completa.
4. **Dos atribuciones válidas:** reparto por hectáreas vs aporte sin reparto; conviene rotularlo bien antes de comparar.
5. **Datos ya disponibles sin usar como recomendación:** stock sin vender, brecha de rendimiento propio, concentración de comprador y descuento del comprador son las cuatro oportunidades más inmediatas (sección 6).
