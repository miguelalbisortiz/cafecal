---
prd: docs/prds/2026-10-01_1706-analisis-mejora-reportes.prd.md
status: DRAFT
created: 2026-10-01_1708
---

# Implementation Plan: Tablero del Caficultor (Alternativa C)

## Overview

Rediseño semántico de la pantalla de reportes: lenguaje 100% llano tipo la tabla de control en papel del usuario, tarjeta-resumen con semáforos, gráfico de barras ventas-vs-gastos (reusando `fl_chart` ya presente), jerga contable eliminada de la UI, y detalle operativo colapsado. **Solo presentación**: ningún cálculo ni servicio de datos cambia, por lo que los exports PDF/Excel y los 170+ tests de lógica quedan intactos.

## Requirements

- R1. Primer pantallazo responde: ¿cuánto me quedó?, ¿cuánto vendí?, ¿cuánto gasté?, ¿qué coseché? (≤5 números)
- R2. Lenguaje llano: cero jerga contable sin traducción (margen, ratio, ROI, payback → frases)
- R3. Reglas de semáforo visibles (verde/amarillo/rojo con regla explicada)
- R4. "Qué hacer" en los primeros 3 bloques
- R5. Gráfico de barras simple ventas vs gastos por mes (sin dependencias nuevas: `fl_chart 0.69.0` ya en pubspec)
- R6. Detalle operativo (nómina, caja, top accounts, vendido-vs-cosechado, hectárea) colapsado con layout estable
- R7. Cero cambios en cálculos/exports; `flutter analyze` limpio y suite completa verde

## Architecture Changes

- `lib/widgets/report_summary_card.dart` — **nuevo**: tarjeta "Tu resultado" con 4 KPIs + semáforo + frase llano (funciones puras testables)
- `lib/services/report_health_rules.dart` — **nuevo**: reglas puras de semáforo (margen, ROI, balance, vendido-vs-cosechado) con la regla como string para mostrarla en UI
- `lib/screens/report_screen.dart` — reorden de bloques (Resumen → Qué hacer → Insights → Gráfico → Gastos top → Cultivos → Cosechas → detalle colapsado → exports) y envoltorio en secciones colapsables
- `lib/widgets/report_plain_finance_card.dart` — **nuevo** (o renombrar tarjeta existente): "¿En qué gastaste más?" con barras horizontales de las top-3 categorías
- `lib/l10n/app_es.arb` + `lib/l10n/app_en.arb` — strings llanos nuevos; se **conservan** los keys viejos que usan exports PDF/Excel (jerga formal solo ahí)
- **Sin** cambios en: `report_insights_service.dart`, `report_harvest_metrics.dart`, `report_payroll_metrics.dart`, `pdf_export_service.dart`, `excel_export_service.dart`, `alert_service.dart`, `recommendations.dart`

## Implementation Steps

### Phase 1: Motor de reglas y resumen (2 archivos nuevos)
1. **Reglas de semáforo puras** (File: `lib/services/report_health_rules.dart`)
   - Action: `enum HealthLevel { good, attention, bad }` + `evaluateMargin(double)` (≥20% good, 0-20% attention, <0 bad), `evaluateRoi(double)` (≥20/0-20/<0), `evaluateBalance(double)`, `evaluateSoldVsHarvested(sold, harvested)` (>10% excedente → bad). Cada resultado incluye `ruleText` (ej. "verde: margen ≥ 20%") para cumplir R3.
   - Why: semáforos con regla visible y testeable; único punto de verdad de las reglas (decisionó el usuario: margen/ROI ≥20% verde).
   - Dependencies: ninguna · Risk: Bajo
2. **Tarjeta Resumen** (File: `lib/widgets/report_summary_card.dart`)
   - Action: Stateless widget con 4 KPIs: "Te quedó {balance}" (frase negativa: "Este mes saliste en −$X"), "Vendiste {incomes}", "Gastaste {expenses}", "Cosechaste {kg} ({cargas} cargas si hay café)" + ícono/color de `HealthLevel` + línea de regla. Datos ya calculados en `build()` (L84-90).
   - Why: R1/R3 — el primer pantallazo responde las 4 preguntas.
   - Dependencies: paso 1 · Risk: Bajo-Medio (empty-state: sin movimientos → frase "Aún no registras movimientos este período")

### Phase 2: Reorden y acción arriba (1 archivo)
3. **Mover "Qué hacer" al puesto 2 y Resumen al 1** (File: `lib/screens/report_screen.dart`)
   - Action: insertar `ReportSummaryCard` antes de insights (L213); mover `_builtRecommendationsCard` (L424) a tras insights; el resto de tarjetas conserva orden detrás.
   - Why: R4 + P2 del análisis (acción estaba en posición 11/12).
   - Dependencies: paso 2 · Risk: Bajo — actualizar `test/report_screen_test.dart` (orden de widgets)

### Phase 3: Lenguaje llano y gráfico (3 archivos)
4. **Tarjeta "¿En qué gastaste más?" con barras** (File: `lib/widgets/report_plain_finance_card.dart`)
   - Action: reusar datos de `_categoryRows` (L1338): top-3 gastos como barras horizontales con % y monto; título en pregunta humana; línea "de cada $100 que entraron, $X se fue en gastos" (reemplaza visualmente "Gastos vs ingresos" para no contadores).
   - Why: R2/P3/P5.
   - Dependencies: paso 3 · Risk: Bajo
5. **Gráfico ventas vs gastos por mes** (File: `lib/screens/report_screen.dart` + reusar `lib/widgets/monthly_trend_chart.dart`)
   - Action: debajo de la tarjeta de gastos, insertar gráfico de barras mensual del año (ventas verdes vs gastos rojos) reusando `MonthlyTrendChart` si su API encaja; si no, variante mínima en `report_plain_finance_card.dart`. Solo en modo Mes/Año/YTD (en semana mostrar comparación vs semana anterior en vez de gráfico).
   - Why: R5 — tendencia visible de un vistazo.
   - Dependencies: paso 4 · Risk: Medio (barras de 0-12 meses; validar empty-state y modo semana)
6. **Traducción de jerga restante en UI** (Files: `lib/screens/report_screen.dart`, `lib/widgets/per_hectare_panel.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`)
   - Action: `_metricLine` margen → "De cada $100 vendidos, te quedaron $X"; ratio → mantener pero con frase; `_CropBreakdownTile` ROI → "Por cada $1 que metiste, volvieron $6,16" (dato ya calculado: `1 + roi`); `perHaPaybackLabel` ya es llano, solo verificar. **No renombrar keys usados por exports** (p. ej. `marginLabel` se duplica como `marginPlainLabel`).
   - Why: R2/P3/P4 (conservar notación contable solo en exports, signo `−` en pantalla).
   - Dependencies: paso 4 · Risk: Bajo — ojo con duplicar keys, no romper `pdf_export_service.dart`

### Phase 4: Detalle colapsado y layout estable (1 archivo)
7. **Secciones colapsables para detalle operativo** (File: `lib/screens/report_screen.dart`)
   - Action: envolver en `ExpansionTile` (expandido por defecto solo si hay datos) las tarjetas: Cosechas (con encabezado resumen "X kg · Y cargas"), Vendido vs cosechado, Nómina, Caja menor, Top accounts, Por hectárea, Desglose por cultivo; encabezado con 1 línea resumen para que el layout nunca "desaparezca" (P7). Estado de expansión persistido en memoria del `State` (no entre sesiones).
   - Why: R6/P1/P7.
   - Dependencies: 1-6 · Risk: Medio — `report_screen_test.dart` busca widgets por texto; ExpansionTile puede necesitar `tester.tap` extra

### Phase 5: Verificación
8. **Tests nuevos** (Files: `test/report_health_rules_test.dart`, `test/report_summary_card_test.dart`)
   - Action: tabla parametrizada de las 4 reglas (bordes 20%, −1%, excedente 10%); render de Resumen con datos vacíos, positivos y negativos.
   - Why: R7 · Dependencies: 1-2 · Risk: Bajo
9. **Suite completa** (Files: todos)
   - Action: `flutter analyze` (limpio) + `flutter test` (baseline 170+ verdes); actualizar `test/report_screen_test.dart` por el reorden; smoke manual de los 3 estados (sin datos / mes con datos / moneda mixta) y verificación de que PDF/Excel exportan idéntico.
   - Why: R7 + AC5 del PRD original · Dependencies: 1-8 · Risk: Bajo

## Testing Strategy

- Unit tests: `report_health_rules_test.dart` (bordes de reglas), `report_summary_card_test.dart` (estados de datos).
- Integration tests: `report_screen_test.dart` — orden de bloques (Resumen primero, Qué hacer ≤ puesto 3), ExpansionTile expand/collapse, períodos semana/mes/año/YTD.
- Export regression: `pdf_export_test.dart` + `excel_export_service_test.dart` deben pasar **sin modificaciones** (garantía de que solo cambió presentación).
- E2E manual: checklist en sesión (3 estados × 4 períodos × 3 exports).

## Risks & Mitigations

- **Risk**: `report_screen.dart` (1700 líneas) crece más → **Mitigación**: tarjetas nuevas en archivos propios (`report_summary_card.dart`, `report_plain_finance_card.dart`); no tocar helpers existentes salvo el reorden.
- **Risk**: Romper claves l10n usadas por exports → **Mitigación**: agregar keys nuevos (`*PlainLabel`), jamás renombrar existentes; los exports consumen los keys formales.
- **Risk**: Tests de UI fallan por orden/ExpansionTile → **Mitigación**: actualizar expectativas en el mismo PR; correr suite completa en cada fase (commits separados por fase).
- **Risk**: Reglas de semáforo percibidas como arbitrarias → **Mitigación**: la regla se muestra en la UI (`ruleText`) y fue definida/aceptada por el usuario (20%).
- **Risk**: Gráfico con pocos meses o datos vacíos → **Mitigación**: empty-state "Aún no hay meses comparables" y ocultar gráfico en modo semana.

## Success Criteria

- [ ] Primer pantallazo: 4 KPIs llanos + semáforo con regla visible
- [ ] "Qué hacer" aparece en los 3 primeros bloques
- [ ] Cero términos "Margen/Ratio/ROI/payback" sin frase llana en la UI
- [ ] Gráfico ventas-vs-gastos visible en modo mes/año
- [ ] Detalle operativo colapsado con encabezado-resumen estable
- [ ] `flutter analyze` limpio · `flutter test` ≥170 verdes · exports sin cambios
- [ ] Cero cambios en `lib/services/*metrics*`, `pdf_export_service`, `excel_export_service`

## Sizing

- **Phase 1-2** (mergeable): tarjeta Resumen + reorden → valor inmediato, 1 día
- **Phase 3**: lenguaje llano + gráfico → 2-3 días
- **Phase 4**: colapsado → 1 día
- **Phase 5**: hardening → continuo

Total estimado: **5-8 días** (Alternativa C, aprobada por el usuario el 2026-10-01).
