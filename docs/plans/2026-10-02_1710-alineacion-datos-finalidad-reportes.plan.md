---
prd: docs/prds/2026-10-02_1710-alineacion-datos-finalidad-reportes.prd.md
status: COMPLETED  <!-- entregable de análisis; decisión de reestructuración pendiente en el usuario -->
created: 2026-10-02_1710
---

# Análisis: lo que la app registra ↔ la finalidad de sus reportes

> **Documento de DECISIÓN — cero cambios de código.** Complementa (no repite) los flujos
> `2026-10-01_1706` (inventario+alternativas) y `2026-10-01_2111` (comprensibilidad H1-H12).
> Estado de UI vigente: **Alt 1 "lenguaje simple" en curso** · **Alt C "Tablero" congelada**.

## Overview

Mapeo completo de las **6 tablas/entidades que la app registra** → las **12 secciones de
`report_screen.dart` + 3 exports** que las reportan, con la **finalidad** declarada de cada
reporte, veredicto de alineación, **huecos priorizados en 3 categorías** (a: dato registrado
sin reporte / b: reporte con finalidad débil o duplicada / c: dato no registrado) y una
**propuesta de reestructuración** clasificada: compatible con Alt 1 vs requiere decisión futura.

## Execution (cómo se ejecutó)

- [x] Phase 0: PRD con Intention Map confirmado (3 ambigüedades resueltas por el usuario)
- [x] Insumos validados reutilizados: inventario 1706 (12 secciones) + H1-H12 de 2111
- [x] Esquema de datos leído: 6 migraciones `supabase/migrations/2026090*.sql`
- [x] Puntos de captura verificados: 7 pantallas (`register`, `movements`, `harvest`,
      `sowing`, `workers`, `crops`, `settings`)
- [x] Consumo por reporte verificado con grep/read dirigido (`report_*_service`,
      `pdf/excel_export_service`, `alert_service`, `report_screen`)
- [x] Candidatos a hueco verificados uno a uno (siembras, day_rate, sowing_id, cycle,
      harvest_id, description, phase, caja, umbral precio) — cada hallazgo con `archivo:línea`

---

# ENTREGABLE

## §1 Qué registra la app (fuente: migraciones SQL + pantallas de captura)

| Tabla | Campos (migración) | Pantalla de captura (evidencia) |
|---|---|---|
| `crops` | name, icon, color, phase, cycle, default_unit, area_ha, live_plants, establishment_cost, currency | `crops_screen.dart:65-125`, `widgets/crop_editor_dialog.dart:43-145` |
| `transactions` | type, category, amount, currency, description, txn_date, crop_id, quantity, unit, price_per_unit*, client, provider, harvest_id, sowing_id | `register_screen.dart:15-53` (form), bloque jornal `:38-45` (trabajador+días+tarifa), *price_per_unit autocalculado `:108,:251-263`; lista en `movements_screen.dart:12-38` |
| `sowings` | kind (siembra/resiembra), plants, area_ha, lost_plants, reason, sowing_date, crop_id | `sowing_screen.dart:252-291` |
| `harvests` | amount, unit, destination (vendido/almacenado/perdida), harvest_date, workers, equivalent_kg, crop_id | `harvest_screen.dart:162-247` |
| `employees` | name, day_rate | `workers_screen.dart` + `widgets/employee_editor_dialog.dart:24-66` |
| `settings` | farm_name, currency, locale, language, last_crop_id, caja_menor_mensual, low_price_threshold_per_kg | `settings_screen.dart:36-70,139` |

*Campos derivados/soporte de `lib/models/`: `categories` (16 gastos/5 ingresos + set de caja,
`categories.dart:45-54`), `currencies`/`units` (soporte), `farm_alert` (derivada),
`top_accounts` (derivada de transactions), `transaction`/`crop`/`harvest`/`sowing`/`employee`/
`settings` (espejo de tablas). Cobertura modelos: **11/11**.

## §2 Matriz de trazabilidad dato → reporte (SC1)

| Entidad / campo | Dónde se reporta (evidencia) | Estado |
|---|---|---|
| `crops.name/icon/color` | desglose por cultivo `report_screen.dart:1492` ( `_CropBreakdownTile`), etiquetas en exports | ✅ |
| `crops.area_ha` | PerHectarePanel `report_screen.dart:417` | ✅ |
| `crops.live_plants` | kg/planta en exports `pdf_export_service.dart:695`, `excel_export_service.dart:851` | ✅ |
| `crops.phase` | contexto per-ha exports `pdf:669-670`, `excel:828-829`; alerta regla 5 `alert_service.dart:296-298` | ✅ (solo exports+alertas, no en pantalla — nota menor) |
| `crops.cycle` | ajuste de rendimiento `report_harvest_metrics.dart:69` | ✅ |
| `crops.establishment_cost` | inversión establecimiento + payback (per-ha, inventario 1706 fila 10) | ✅ |
| `crops.currency` | moneda efectiva `report_screen.dart:67-71` | ✅ |
| `transactions.type/category/amount/currency/date` | Estado de resultados `report_screen.dart:270-334`; insights `report_insights_service.dart:38-66`; caja `report_payroll_metrics.dart:119-129`; exports | ✅ |
| `transactions.crop_id` | desglose por cultivo/ROI `report_screen.dart:1492` | ✅ |
| `transactions.quantity/unit` | días de nómina `report_payroll_metrics.dart:79-81`; anexo Excel `excel_export_service.dart:704` | ✅ |
| `transactions.price_per_unit` | alerta precio bajo `alert_service.dart:208-263`; columna Excel `excel:704`; insights | ✅ |
| `transactions.client/provider` | TopAccounts `top_accounts.dart:12-29` → tarjeta `report_screen.dart:1399-1412` + `pdf:441-443` | ✅ |
| `transactions.harvest_id` | costo recolección/kg `report_harvest_metrics.dart:59` | ✅ |
| `transactions.sowing_id` | — (grep: solo model/provider/register/sowing_screen) | ⚠️ **0 usos en reportes** → hueco A3 |
| `transactions.description` | solo anexo movimientos Excel `excel_export_service.dart:727` (sin agregación) | ⚠️ uso mínimo → hueco A4 |
| `sowings.kind` | marca "aproximado" per-ha por resiembra `pdf:666-667`, `excel:825-826` | ⚠️ indirecto |
| `sowings.sowing_date` | alerta "siembra reciente" regla 7 `alert_service.dart:413-432` → "Qué hacer" `report_screen.dart:905-911` | ⚠️ indirecto |
| `sowings.plants/area_ha/lost_plants/reason` | — (0 usos fuera de `sowing_screen`) | ⚠️ **sin reporte** → hueco A1 |
| `harvests.amount/unit/date` | tarjeta Cosechas `report_screen.dart:611-737` | ✅ |
| `harvests.destination` | destino en Cosechas + Vendido-vs-cosechado `report_screen.dart:851-874` | ✅ (ver B3) |
| `harvests.workers/equivalent_kg` | detalle Cosechas `report_screen.dart:619,722-723`; `pdf:911-926`; `excel:864-885` | ✅ |
| `employees.name` | catálogo para prefijar jornal `register_screen.dart:13,216` (nómina reporta snapshot `provider` de transactions) | ✅ solo como catálogo |
| `employees.day_rate` | prefill de tarifa `register_screen.dart:221-222`; grep `dayRate` = 0 usos en reportes | ⚠️ **sin reporte** → hueco A2 |
| `settings.farm_name/currency` | encabezado exports + moneda efectiva | ✅ |
| `settings.caja_menor_mensual` | tarjeta Caja `report_screen.dart:790` + alerta regla 10 `alert_service.dart:469-510` | ✅ |
| `settings.low_price_threshold_per_kg` | alerta regla 4 `alert_service.dart:208-263` + insight precio bajo | ✅ |
| `settings.language/last_crop_id/locale` | — (prefs de UX; correctamente fuera de reportes) | N/A |

## §3 Finalidad y veredicto por sección (SC2)

| # | Sección (report_screen.dart) | Finalidad — qué decisión soporta | Dato fuente | Veredicto |
|---|---|---|---|---|
| 1 | Selector de período `:116-210` | Acotar el contexto temporal de todo lo demás | — (UI) | ✅ alineado |
| 2 | Conclusión del período (insights) `:213-268` | "¿Cómo me fue?" en frases — resumen ejecutivo | transactions + crops (`report_insights_service.dart:38-47`) | ✅ alineado (nota: solo dinero, no producción) |
| 3 | Estado de resultados `:270-334` | "¿Me quedó plata?" resultado e impulsores | transactions por grupo/categoría | ✅ alineado (nota: ver B2/B4) |
| 4 | Top accounts `:1399-1412` | "¿Con quién negocio más?" (compradores/proveedores) | transactions.client/provider | ⚠️ **parcial** — ver B1 (nombre sugiere deuda; no hay pendientes) |
| 5 | Desglose por cultivo `:1492` | "¿Qué cultivo conviene?" (ROI por cultivo) | transactions×crop + crops | ✅ alineado |
| 6 | Cosechas `:611-737` | "¿Cuánto coseché y a dónde fue?" | harvests (+workers/equivalent_kg) | ✅ alineado |
| 7 | Vendido vs cosechado `:851-874` | "¿Vendí en coherencia con lo cosechado?" (control de datos) | harvests vs transactions de venta | ✅ alineado (nota: ver B3) |
| 8 | Nómina `:739-784` | "¿Cuánto pagué en mano de obra?" | transactions categoría `mano_obra` (`report_payroll_metrics.dart:68-99`) | ✅ alineado (nota: no compara con `day_rate` → A2) |
| 9 | Caja menor `:786-849` | "¿Alcanza la caja del mes?" | settings budget + gastos `discountsCashBox` (`report_payroll_metrics.dart:105-173`) | ✅ alineado |
| 10 | Por hectárea `:417` + `per_hectare_panel.dart` | "¿Rinde mi tierra?" (kg/ha, payback) | crops (area/plants/establishment) + harvests + transactions | ✅ alineado |
| 11 | Qué hacer `:903-913` | "¿Qué hago ahora?" (acciones priorizadas) | derivado: transactions, crops, harvests, sowings (10 reglas, `alert_service.dart`) | ✅ alineado |
| 12 | Exportaciones `:1049-1185` | Compartir/consolidar fuera de la app | mismo dataset | ⚠️ **parcial** — ver B5/H2, H7 |
| E1 | PDF `pdf_export_service.dart` | Documento compartido autoexplicativo | mismo dataset | ⚠️ parcial — sin insights (H2), ROI con solo pie (H9) |
| E2 | Excel `excel_export_service.dart` | Análisis tabular / detalle | mismo dataset | ⚠️ parcial — sin insights (H2); único lugar con `description` |
| E3 | Balance CSV | Plantilla de contabilidad externa | transactions | ✅ alineado (formato neutro para contador) |

## §4 Huecos priorizados (SC3)

### (a) Dato registrado sin reporte — todo ya se captura, solo falta mostrarlo

| ID | Pri. | Dato | Evidencia | Finalidad no soportada |
|---|---|---|---|---|
| A1 | **Alta** | `sowings` completo (plants, kind, lost_plants, reason) | inventario 1706 sin fila de siembras; grep: solo `alert_service.dart:413-432` + marca aprox per-ha | "¿Cómo va mi plantación? ¿Qué plantas perdí y por qué?" — hoy invisible salvo alerta de 15 días |
| A2 | Media | `employees.day_rate` | `register_screen.dart:221-222` (solo prefill); grep `dayRate` sin usos en reportes | "¿Pagué la tarifa acordada?" (tarifa esperada vs pagada) |
| A3 | Media | `transactions.sowing_id` | grep: 0 usos en servicios de reporte | "¿Cuánto costó plantar cada lote?" (entra por categoría 'siembra' en total, no por siembra) |
| A4 | Baja | `transactions.description` | solo `excel_export_service.dart:727` | Contexto cualitativo de movimientos sin ninguna agregación |

### (b) Reporte con finalidad débil o duplicada

| ID | Pri. | Hallazgo | Evidencia | Riesgo para el usuario |
|---|---|---|---|---|
| B1 | **Alta** | "Top accounts" ≠ deudas: modelo = concentración de clientes/proveedores, sin estado de pendiente | `top_accounts.dart:3-5,12-29`; etiqueta "cuentas por cobrar/pagar" en inventario 1706 fila 4 | Lee flujo acumulado como "me deben/debo" → decisión financiera equivocada |
| B5 | **Alta** | PDF/Excel sin "Conclusión del período" (la parte en lenguaje humano) | H2 verificado (grep `insight` = 0 en servicios de export) | El documento que circula fuera pierde la única sección autoexplicativa |
| B2 | Media | Totales duplicados con etiquetas distintas (estado de resultados vs desglose vs top accounts vs per-ha) | 1706 P6, `report_screen.dart:270-422` | "¿Cuál es el número real?" |
| B3 | Media | Cosechas (fila 6) y Vendido-vs-cosechado (fila 7) cuentan el mismo destino dos veces | `:611-737` vs `:851-874` | Duplicidad percibida sin jerarquía |
| B4 | Media | "Gastos vs ingresos %" sin señal, solapado con Margen | H1 verificado, `report_screen.dart:314-321` | Ve "23%" sin saber si está bien o mal |

### (c) Dato NO registrado necesario para la finalidad (requiere nueva captura)

| ID | Pri. | Dato faltante | Finalidad no soportable hoy | Esfuerzo implícito |
|---|---|---|---|---|
| C1 | **Alta** | Estado pendiente/cobrado de ventas y compras (no hay flag en `transactions`, `migrations/20260904:34-46`) | "¿Quién me debe y qué no me han pagado?" — los "top accounts" no lo responden | Campo nuevo + migración + UI |
| C2 | **Alta** | Valor ($) del café `almacenado` (destination registra kg sin monto, `migrations/20260907:70-71`) | "¿Cuánto vale lo que tengo guardado en bodega?" | Campo opcional en captura de cosecha |
| C3 | Media | Presupuesto por categoría (solo existe caja: `migrations/20260924:143`) | "¿Gasté de más en fertilizantes?" (hoy solo proxy 2× promedio, regla 1 `alert_service.dart:50`) | settings + UI |
| C4 | Media | Meta/objetivo del período (settings sin campo de meta; umbral de precio = única meta parcial) | "¿Voy bien contra mi meta?" | settings + UI |
| C5 | Baja | Cobertura "ventas con precio/kg registrado" (la regla 9 `alert_service.dart:444-460` ya detecta el hueco, pero el reporte no muestra el %) | "¿Qué tan confiable es mi precio promedio?" | Derivable de datos existentes (sin nuevo campo) |

## §5 Propuesta de reestructuración (SC4)

**Principio**: agrupar los reportes por la **decisión que soportan** (estructura conceptual de
4 zonas — el orden final NO se implementa aquí):

1. **"¿Cómo me fue?"** (dinero): insights + estado de resultados (+ margen)
2. **"¿Qué produce mi finca?"** (tierra): cosechas, desglose por cultivo, por hectárea, **siembras*** 
3. **"¿Con quién y con qué pagos?"** (gente): top accounts**, nómina, caja menor, vendido vs cosechado
4. **"¿Qué hago?"** (acción): Qué hacer + exportaciones

\* nueva · \** con nombre corregido

| # | Acción propuesta | Huecos | Clasificación |
|---|---|---|---|
| P1 | Renombrar "Top accounts" → **"Mis compradores y proveedores"** y eliminar lectura de "deuda" (copy l10n) | B1 | ✅ **Compatible con Alt 1** (es lenguaje simple, sin reorden) |
| P2 | Señal bueno/malo + frase bajo Margen/"Gastos vs ingresos" | B4 | ✅ Ya aprobado en curso (Alt 1) |
| P3 | Texto explicando el rojo de "Vendido vs cosechado" | B3 | ✅ Ya en Alt 1 (H3) |
| P4 | Etiqueta canónica única para "el resultado del período" en los bloques duplicados | B2 | ✅ **Compatible con Alt 1** (copy); suprimir duplicados = decisión futura |
| P5 | Nueva sección **"Plantación/Siembras"** (plantadas, pérdidas y razón) | A1, A3 | ⚠️ **Requiere decisión futura** (estructura nueva) |
| P6 | Fila "tarifa esperada vs pagada" en nómina | A2 | ⚠️ **Requiere decisión futura** (contenido nuevo de tarjeta) |
| P7 | Insights como primera sección de PDF/Excel | B5 | ⚠️ **Requiere decisión futura** (territorio Alt 3) |
| P8 | Reorden en 4 zonas / colapsado de detalle | estructura | ⚠️ **Requiere decisión futura** (Alt 2 / Tablero **congelado**) |
| P9 | Campo "pendiente/cobrado" + tarjeta "Me deben" | C1 | ⚠️ **Requiere decisión futura + migración BD** (fuera de alcance de este flujo) |
| P10 | Café almacenado valorado ($) | C2 | ⚠️ **Requiere decisión futura + campo de captura** |
| P11 | Presupuesto por categoría / metas del período | C3, C4 | ⚠️ **Requiere decisión futura** |
| P12 | % de ventas con precio/kg registrado (cobertura) | C5 | ⚠️ Derivable hoy; **Requiere decisión futura** (contenido) |

## §6 Recomendación y roadmap de decisión

**Orden sugerido (tu decisión):**

1. **Seguir con Alt 1** (en curso) **+ incorporar P1 y P4** — son copy, mismo esfuerzo de la
   Alt 1, y cierran los 2 hallazgos de finalidad más peligrosos (B1, B2) sin tocar estructura.
2. **Decidir P5 (sección Siembras)** — mejor relación valor/esfuerzo de todos los huecos:
   el dato YA se registra completo (A1 no necesita migración ni campos nuevos), solo falta
   mostrarlo. Candidato a siguiente hito después de Alt 1.
3. **P7 (insights en exports)** — decidir junto con la Alternativa 3 del flujo 2111.
4. **P9/P10 (deudas y bodega valorada)** — mayor impacto de negocio (C1/C2), pero requieren
   nuevos campos + migración → plan propio, después de validar que el caficultor los necesita.
5. **P8 (reorden/zonas)** — territorio de Alt 2/Tablero; **congelado** hasta nueva decisión.
   Cualquier propuesta de reorden en este documento queda marcada como decisión futura (SC4).

## Success Criteria (PRD)

- [x] SC1: matriz de trazabilidad 100% entidades (6 tablas + 11 modelos) + 12 secciones + 3 exports, con `archivo:línea` → §1-§2
- [x] SC2: finalidad + veredicto alineado/parcial/sin soporte por sección → §3 (12 filas + 3 exports)
- [x] SC3: huecos en 3 categorías con prioridad y evidencia → §4 (A1-A4, B1-B5, C1-C5)
- [x] SC4: propuesta compatible con Alt 1; reordenamientos marcados "requiere decisión futura" → §5 (P1-P4 ✅ / P5-P12 ⚠️)
- [x] SC5: cero cambios en `lib/` y `test/` — solo documentos en `docs/`
- [x] SC6: reporte de ejecución en `docs/reports/` → Phase 4
