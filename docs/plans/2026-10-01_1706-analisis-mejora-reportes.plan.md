---
prd: docs/prds/2026-10-01_1706-analisis-mejora-reportes.prd.md
status: COMPLETED  <!-- decision tomada 2026-10-01: Alternativa C elegida por el usuario → ver docs/plans/2026-10-01_1708-tablero-caficultor.plan.md -->
created: 2026-10-01_1706
---

# Implementation Plan: Análisis y mejora de reportes de Mi Cafetal (decisión)

> ⚠️ **Documento de DECISIÓN — no se modifica ningún código hasta que el usuario elija una alternativa.**

## Overview

Auditoría completa de los reportes actuales de `report_screen.dart`, criterios de interpretabilidad para usuarios no técnicos, problemas concretos detectados en el código, y 4 alternativas de mejora con matriz de decisión. Al elegir la alternativa, este documento se despliega en un plan de implementación por fases (ver §Roadmap).

## Requirements

- R1. Inventario preciso de reportes actuales (ankerado al código)
- R2. Criterios de "fácil interpretación para cualquier persona"
- R3. ≥3 alternativas con pros/contras/esfuerzo
- R4. Recomendación + decisión final del usuario
- R5. Cero cambios de código en esta fase

## Estado actual (Inventario — fase de análisis)

**Pantalla**: `lib/screens/report_screen.dart` — UNA sola `ListView` de ~12 bloques, período global (Semana ISO | Mes | Año | A la fecha).

| # | Tarjeta/sección | Fuente (código) | Qué muestra | Aparece siempre |
|---|---|---|---|---|
| 1 | Selector de período + título | `build()` L116-210 | SegmentedButton + navegación ←→ / dropdowns | sí |
| 2 | "Conclusión del período" (insights) | `report_insights_service.dart` | 3-6 frases: balance, vs mes anterior, mayor gasto, mejor ingreso, precio bajo, mejor/menor mes | si hay datos |
| 3 | Estado de resultados | `_statementLine`/`_categoryLine` L270-334 | Ingresos por grupo, gastos por categoría, resultado, **Margen %**, **Gastos vs ingresos %**, desglose si moneda mixta | sí |
| 4 | Top accounts | `_TopAccountsCard` L1399 | Cuentas por cobrar/pagar (top) | si hay |
| 5 | Desglose por cultivo | `_CropBreakdownTile` L1492 | Por cultivo: Gastos, Ingresos, Resultado, **ROI %** + hint de lectura de ROI | si hay datos |
| 6 | Cosechas del período | `_builtHarvestCard` L611 | Total por cultivo (unidades+kg), **cargas ☕** (solo café), por destino (vendido/almacenado/perdida), costo recogida/kg, personal y kilos por cosecha | sí (con empty-state) |
| 7 | Vendido vs cosechado | `_builtSoldVsHarvestedCard` L851 | kg vendidos vs kg cosechados por cultivo; rojo si vendido > cosechado×1.1 | si hay filas |
| 8 | Nómina del período | `_builtPayrollCard` L739 | Por proveedor: días, subtotal; total; empleados distintos | si hay |
| 9 | Caja menor | `_builtCashBoxCard` L786 | Por mes: saldo, presupuesto, mano de obra, extras, jornal total | si hay |
| 10 | Por hectárea | `widgets/per_hectare_panel.dart` | Rendimiento kg/ha, ventas/ha, gastos/ha, margen/ha, inversión establecimiento, recuperado, payback en años | si hay área |
| 11 | "Qué hacer" (recomendaciones) | `_builtRecommendationsCard` L903 ← `AlertService` → `RecommendationService` | Top 4 acciones numeradas con severidad (danger/warning/info) | sí |
| 12 | Exportaciones | `_export/_exportExcel/_exportBalance` L1049-1185 | PDF, Excel, Plantilla de balance CSV (compartir) | sí |

**Exports**: `pdf_export_service.dart` (~1000 líneas: estado de resultados, desglose por cultivo+ROI, anexo anual, cosechas, vendido vs cosechado, nómina, caja, staff, qué hacer, anexo de movimientos), `excel_export_service.dart` (similar + balance CSV).

**Ayudas de interpretación ya existentes**: glosario (`terminology_guide.dart`: ROI, balance, margen, ratio, promedio histórico — botón ⓘ solo en tarjetas 3 y 5), hints de ROI (`cropBreakdownRoiHint`), notas de cargas (`harvestCargasNote`), insights en texto llano.

**Tests que protegen esta superficie**: `report_screen_test.dart`, `report_insights_service_test.dart`, `report_harvest_metrics_test.dart`, `report_recommendations_test.dart`, `pdf_export_test.dart`, `excel_export_service_test.dart`, `per_hectare_panel_test.dart`, `week_utils_test.dart`.

## Problemas de interpretabilidad detectados (con ubicación)

| # | Problema | Ubicación | Impacto |
|---|---|---|---|
| P1 | **Lista larga única** de 12 bloques sin jerarquía "respuesta primero" — hay que scrollear para llegar a la acción | `build()` L113-467 | Alto — sobrecarga cognitiva |
| P2 | **"Qué hacer" es el penúltimo bloque** (posición 11/12) siendo lo más accionable | L424 | Alto |
| P3 | **Jerga contable sin traducción inline**: "Margen sobre ventas", "Gastos vs ingresos", "ROI", "payback" | L314-321, `_CropBreakdownTile` L1489, `per_hectare_panel.dart` | Alto para no técnicos (glosario exige clic) |
| P4 | **Notación contable entre paréntesis** `(1.234)` para negativos | `_accounting()` L1329-1334 | Medio — confunde a who no es contador |
| P5 | **% crudos sin semáforo ni significado** ("Margen 12%" sin decir si es bueno/malo) | `_metricLine` L1295 | Medio |
| P6 | **Duplicación**: totales de ingresos/gastos aparecen en estado de resultados, desglose por cultivo, top accounts y por hectárea con etiquetas distintas | L270-422 | Medio — "¿cuál es el número real?" |
| P7 | **Tarjetas que aparecen/desaparecen** según datos (nómina, caja, vendido-vs-cosechado) → el layout cambia entre períodos | L742, L795, L856 | Medio — desorienta |
| P8 | **"Vendido vs cosechado" no explica la anomalía**, solo pone rojo si >10% | L873 | Medio |
| P9 | Moneda mixta: totales en "moneda efectiva" + desglose aparte | L96-104, `_CurrencyBreakdown` | Bajo-Medio |
| P10 | Título de período y chip pueden expresarse distinto (`_periodLabel` vs `_periodChipLabel`) | L533-560 | Bajo |

## Criterios de interpretabilidad (estándar a aplicar)

1. **≤5 números "estrella"** visibles sin scroll en el primer pantallazo.
2. **Preguntas humanas** como títulos ("¿Cuánto te quedó?" en vez de "Estado de resultados").
3. **Comparación siempre**: vs mes anterior / vs año / vs presupuesto — un número solo no informa.
4. **Semáforo explícito** (verde/amarillo/rojo) con regla visible, no solo color.
5. **Jerga solo con traducción inline** (texto debajo del término, no solo glosario).
6. **Orden: resumen → detalle → acción**; la acción ("Qué hacer") arriba, no al final.
7. **Layout estable**: secciones fijas con empty-state, no bloques que desaparecen.

## Alternativas (para decidir)

### Alternativa A — "Resumen arriba + detalle colapsible" (evolutiva) ★ recomendada como primer paso
- **Qué cambia**: nueva tarjeta **Resumen** arriba del todo (4 KPIs con semáforo: Resultado, Ventas, Gastos, Cosechado/cargas) + frase en lenguaje llano; mover **"Qué hacer" a posición 3**; envolver tarjetas 6-10 en `ExpansionTile` (colapsadas por defecto, excepto Resumen/Estado/Qué hacer); traducción inline de margen/ratio/ROI; semáforo en ROI y margen.
- **Pros**: máxima ganancia por esfuerzo; no rompe exports; tests existentes siguen aplicando (solo se añaden); incremental.
- **Contras**: sigue siendo una pantalla larga (aunque colapsada); P6 (duplicación) queda parcialmente.
- **Esfuerzo**: **Bajo-Medio** (~1-2 días, 3-5 archivos: `report_screen.dart`, nuevo `widgets/report_summary_card.dart`, `app_es.arb`/`app_en.arb`, tests).
- **Riesgo**: **Bajo**.

### Alternativa B — "Reportes por pregunta" (navegación por secciones)
- **Qué cambia**: la pantalla se divide en 4 zonas con chips o `TabBar`: **① ¿Cómo me fue?** (resumen + insights + estado de resultados) · **② ¿Mis cultivos?** (desglose, cosechas, vendido vs cosechado, por hectárea) · **③ ¿Plata y gente?** (nómina, caja menor, top accounts) · **④ ¿Qué hago? + exports**. Cada zona conserva el selector de período global.
- **Pros**: agrupa por intención del usuario; elimina scroll masivo; escala bien si mañana se añaden reportes; P1/P2/P6 resueltos.
- **Contras**: cambia la navegación → tests de UI a refactorizar; el usuario "acostumbrado" al scroll único notará el cambio; exports quedan en zona 4 (o barra fija).
- **Esfuerzo**: **Medio** (~3-5 días; `report_screen.dart` reescrito en secciones + migración de tests + verificación de exports).
- **Riesgo**: **Medio** (regresiones de UI; mitigable con tests existentes).

### Alternativa C — "Tablero del caficultor" (rediseño semántico total)
- **Qué cambia**: lenguaje 100% llano tipo **tabla de control en papel** que el usuario ya usa (hallazgo `docs/sessions/2026-09-20-reporte-semanal-cargas.md`): "Gastos", "Ventas", "Lo que me quedó", "Café recogido ÷ 60 = cargas". KPIs con semáforo + **gráficos de barras simples** (ventas vs gastos por mes, top 3 gastos). ROI se presenta como "**por cada $1 que metes, vuelven $6,16**" (ya hay hint, se vuelve regla). Jerga eliminada de la UI (glosario queda como opcional).
- **Pros**: máxima interpretabilidad "para cualquiera"; alineación total con el flujo mental real del productor.
- **Contras**: esfuerzo alto; requiere gráficos (nueva dependencia liviana o CustomPainter); retoque de exports PDF para que no queden desalineados; más superficie de regresión.
- **Esfuerzo**: **Medio-Alto** (~5-8 días).
- **Riesgo**: **Medio-Alto** (mitigar con A primero y C en una segunda iteración).

### Alternativa D — "Reporte ejecutivo externo" (complementaria, no excluyente)
- **Qué cambia**: un **4.º formato de export** (PDF formal tipo estado de resultados para contador/banco/compra de finca), sin lenguaje coloquial, con pie de firma, período y moneda.
- **Pros**: responde a Q3 del PRD; añade valor sin tocar la pantalla.
- **Contras**: no resuelve los problemas de interpretación en pantalla (P1-P5).
- **Esfuerzo**: **Bajo-Medio** (~1-2 días, `pdf_export_service.dart` + tests).
- **Riesgo**: **Bajo**. Puede combinarse con A, B o C.

### Matriz de decisión

| Criterio | A (evolutiva) | B (secciones) | C (tablero) | D (PDF externo) |
|---|---|---|---|---|
| Interpretabilidad "cualquier persona" | ★★★☆ | ★★★★ | ★★★★★ | ★★☆ (solo export) |
| Esfuerzo | 1-2 d | 3-5 d | 5-8 d | 1-2 d |
| Riesgo de regresión | Bajo | Medio | Medio-Alto | Bajo |
| Rompe exports | No | No* | Hay que ajustar | No |
| Resuelve P1 (scroll largo) | Parcial | Sí | Sí | — |
| Resuelve P2 (acción al final) | Sí | Sí | Sí | — |
| Resuelve P3 (jerga) | Parcial | Parcial | Sí | — |
| Combinable | con D | con D | con D | con cualquiera |

\* si los exports quedan en barra fija.

**Recomendación**: **A primero, luego B (o C si el usuario quiere el salto)**; **D** como complemento si hay destinatario externo. A es reversible y deja la base (tarjeta Resumen + semáforos) reutilizable por B/C.

## Quick wins (independientes de la alternativa elegida)

1. Mover tarjeta "Qué hacer" a posición 3 (L424 → tras insights) — **1 línea + test**.
2. Texto llano bajo Margen/Ratio: `marginLabel` + "de cada $100 vendidos te quedan $X" (patrón ya usado en `glossaryMarginDef`).
3. Semáforo en ROI por cultivo (verde ≥20%, amarillo 0-20%, rojo <0) — regla visible en `cropBreakdownRoiHint`.
4. Reemplazar paréntesis contables por signo `−` en pantalla (mantener `()` en exports).
5. Frase explicativa en "Vendido vs cosechado" cuando marca rojo: "Vendiste 15% más de lo que cosechaste — revisa registros".
6. Unificar chip y título de período.

## Architecture Changes (solo tras decidir)

- *(Alternativa A)* Nuevo `lib/widgets/report_summary_card.dart` (KPIs+semáforo); reorden de `lib/screens/report_screen.dart`; strings nuevos en `lib/l10n/app_es.arb` + `app_en.arb`.
- *(Alternativa B)* `report_screen.dart` → `ReportScreen` con 4 secciones + navegación; posible `lib/screens/report_sections/*.dart`.
- *(Alternativa C)* + `lib/widgets/simple_bar_chart.dart` (sin dependencias nuevas) y renombrado de etiquetas en l10n.
- *(Alternativa D)* `lib/services/pdf_export_service.dart` → método `buildExecutiveReport(...)`.

## Implementation Steps (post-decisión — prellenados para A)

### Phase 1: Tarjeta Resumen + quick wins
1. **Quick win: mover "Qué hacer"** (File: `lib/screens/report_screen.dart`)
   - Action: mover `_builtRecommendationsCard` (L424) a tras el bloque de insights (L268); ajustar `test/report_screen_test.dart`.
   - Why: P2 — la acción es lo más valioso y hoy está al final.
   - Dependencies: ninguna · Risk: Bajo
2. **Tarjeta Resumen con semáforo** (File: `lib/widgets/report_summary_card.dart` — nuevo)
   - Action: 4 KPIs (Resultado, Ventas, Gastos, Cosechado) + frase llano + colores por regla; consumir datos ya calculados en `build()`.
   - Why: R2/AC2 — primer pantallazo interpretable (criterios 1-4).
   - Dependencies: paso 1 · Risk: Medio (reglas de semáforo a definir en test)
3. **Traducción inline de jerga** (Files: `lib/screens/report_screen.dart`, `app_es.arb`, `app_en.arb`)
   - Action: bajo `_metricLine` margen/ratio añadir frase tipo `glossaryMarginDef`; `_CropBreakdownTile` mostrar "por cada $1 vuelven $X".
   - Why: P3 · Dependencies: ninguna · Risk: Bajo

### Phase 2: Colapsado de detalle
4. **Envolver tarjetas 6-10 en ExpansionTile** (File: `lib/screens/report_screen.dart`)
   - Action: cosechas/vendido-vs/nómina/caja/hectárea colapsadas por defecto con resumen de 1 línea en el encabezado; estado expandido persistente en sesión.
   - Why: P1/P7 — reduce scroll y layout estable.
   - Dependencies: 1-3 · Risk: Medio (tests de scroll)

### Phase 3: Verificación
5. **Tests** (Files: `test/report_screen_test.dart`, nuevo `test/report_summary_card_test.dart`)
   - Action: cubrir reglas de semáforo, orden de tarjetas, empty-states.
   - Why: AC2 · Dependencies: 1-4 · Risk: Bajo
6. **`flutter analyze` + `flutter test`** — 170+ tests verdes (baseline de sesión 2026-09-20).

## Testing Strategy

- Unit tests: reglas de semáforo (nuevo servicio `report_health_rules` si aplica), traducciones inline (l10n), quick wins de orden.
- Integration tests: `report_screen_test.dart` (orden de tarjetas, colapsado, períodos semana/mes/año/YTD).
- Export tests: `pdf_export_test.dart`, `excel_export_service_test.dart` no deben romperse (A/D no tocan datos, solo presentación).
- E2E/manual: abrir reporte en 3 estados (sin datos, mes con datos, moneda mixta) — checklist en sesión.

## Risks & Mitigations

- **Risk**: Cambios en `report_screen.dart` (archivo de 1700 líneas) rompen tests de UI · **Mitigación**: extraer widgets nuevos en archivos propios; correr suite completa en cada fase.
- **Risk**: Reglas de semáforo subjetivas/confusas · **Mitigación**: definir reglas con números redondos visibles en el hint y testearlas.
- **Risk**: Usuario elige B/C y pierde lo invertido en A · **Mitigación**: A deja componentes (Resumen, semáforos) reutilizables por B/C.
- **Risk**: Desalineación pantalla vs exports PDF/Excel · **Mitigación**: exports consumen los mismos services; no cambiar cálculos, solo presentación.

## Success Criteria (PRD)

- [x] AC1: inventario de las 12 secciones + 3 exports documentado
- [x] AC2: alternativas viables con infraestructura existente
- [x] AC3: matriz de decisión alternativa × interpretabilidad × esfuerzo × riesgo
- [x] AC4: problemas de interpretabilidad con ubicación en código (P1-P10)
- [x] AC5: cero archivos de `lib/`/`test/` modificados
- [x] AC6: **usuario elige alternativa** → **C — Tablero del Caficultor** (2026-10-01)

## Open Questions para el usuario

1. ¿Qué alternativa eliges? (A, B, C, D o combinación A+D / B+D)?
2. ¿Mantener la pantalla única o te abre bien navegar por secciones?
3. ¿Hay destinatario externo del reporte (contador/banco)? → alterna D.
4. ¿Las reglas del semáforo? (propuesta: margen ≥20% verde, 0-20% amarillo, <0 rojo; ROI ≥20% verde, 0-20% amarillo, <0 rojo).
