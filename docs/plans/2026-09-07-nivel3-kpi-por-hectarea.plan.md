# Plan: Nivel 3 — KPI por hectárea y amortización del establecimiento

- **Fecha**: 2026-09-07
- **Tipo**: Implementación (lógica de métricas + UI + dato nuevo + guía)
- **Objetivo**: normalizar el desempeño por **superficie (hectárea)** —rendimiento, ventas,
  gastos y margen por ha— y permitir ver **cuánto se ha recuperado de la inversión del
  establecimiento** del cultivo, sin adivinar producción y sin
  tocar la regla de oro. Solo divisiones/promedios de **datos medidos** en la app.
- **Baseline**: ya existe `ReportHarvestMetrics.yieldPerArea()` (kg/ha) y `yieldPerPlant()`,
  usados hoy solo en exportación PDF/Excel. El Nivel 3 (a) los **saca a la UI** en el
  reporte, (b) agrega las versiones **financieras por ha** (ventas/ha, gastos/ha,
  margen/ha) y (c) agrega **amortización del establecimiento** con un dato nuevo
  (`establishmentCost` en el cultivo).

## Alcance

1. **Dato nuevo `establishmentCost` (double?) en `Crop`**:
   - `lib/models/crop.dart` (campo + copyWith + toJson/fromJson).
   - Migración Supabase `crops.establishment_cost` (numeric, nullable).
   - `sync_provider.dart`: enviar/ recibir `establishment_cost`.
   - `lib/widgets/crop_editor_dialog.dart`: campo opcional **"Costo del establecimiento ($)"**
     (solo informativo; no bloquea guardar; no se muestra en cultivos de ciclo anual sin que
     el usuario lo llene). Valor siempre opcional.
2. **Lógica pura — ampliar `lib/services/report_harvest_metrics.dart`** (funciones puras,
   testables):
   - `revenuePerHa(crop, areaHa, incomeTxs)`, `costPerHa(crop, areaHa, expenseTxs)`,
     `marginPerHa(...)` → solo si `areaHa > 0`; si no, `null` (nunca 0).
   - `recoveryRate(establishmentCost, margin)` → % recuperado = margen ÷ inversión
     (solo si `establishmentCost > 0`).
   - `breakevenYears(establishmentCost, marginByPeriod)` → inversión ÷ margen anual
     promedio **medido**; solo si hay ≥1 período completo con margen > 0; resultado
siempre marcado "aprox." (es un promedio de datos medidos, NO una predicción de
      rendimiento). Caso sin cosechas aún (p. ej. tiene inversión pero el cultivo no ha
      empezado a producir): muestra "La inversión sigue pendiente de recuperarse", sin
      número inventado.
3. **UI — nuevo panel `lib/widgets/per_hectare_panel.dart`** embebido en el **Reporte**
   (debajo de los insights, junto a la sección Cosechas). Muestra por cultivo con `areaHa`:
   kg/ha, ventas/ha, gastos/ha, margen/ha y la tarjeta de **amortización**
   (inversión → % recuperado → "se pagaría en N años (aprox)" si aplica). Cultivos sin
   área: se indican y se sugiere editar el cultivo (sin bloquear el reporte).
4. **Guía + i18n es/en**:
   - `help_screen.dart`: nueva sección **"¿Qué significa por hectárea?"** (qué es kg/ha,
     ventas/ha, margen/ha, por qué no comparar parcelas sin normalizar) y **"¿Cómo se
     recupera la inversión del establecimiento?"** (definición de `establishmentCost`,
     % recuperado, "no es pérdida: es inversión").
   - `docs/guides/mi-cafetal-primeros-pasos.md`: mismo contenido en markdown (fuente repo).
   - ~20 strings nuevos por idioma (`app_es.arb` / `app_en.arb`).
5. **Tests**: lógica pura (nuevas métricas + bordes area null / sin cosecha / sin margen,
   breakeven "aprox") + widget (panel renderiza/nulo) + editor (campo opcional).

## Reglas

- **Regla de oro intacta**: NADA de predecir rendimiento ni convertir plantines a kg.
  `breakevenYears` es un promedio de margen medido, nunca estimación de cosecha futura.
  Los KPIs regresan `null` cuando falta el dato necesario (área, kg, margen, inversión);
  la UI oculta en vez de mostrar 0.
- **Sin carga obligatoria**: `establishmentCost` y `areaHa` son opcionales. Sin área →
  el panel lo dice y sugiere editarlo; no rompe el reporte ni el flujo actual.
- **Compatibilidad**: campos nuevos nullable → viejas filas Hive/Supabase sin problema;
  sync idempotente; reporte existente intacto (todas las funciones viejas se conservan).
- **Deploy**: mismos pasos de siempre (build web → `_deploy` → commit gh-pages + main).

## Criterios de aceptación

- **AC-1**: Un cultivo con `areaHa > 0` y cosechas muestra **kg/ha** en el reporte
  (valor coincide con `yieldPerArea` existente → consistencia con PDF/Excel).
- **AC-2**: Con transacciones de ingreso/gasto asociadas al cultivo, el panel muestra
  ventas/ha, gastos/ha y margen/ha (y `null` → oculto si no aplica).
- **AC-3**: Con `establishmentCost > 0` se muestra % de inversión recuperada; con margen
  de ≥1 período completo, "se pagaría en N años (aprox)". Sin cosechas → mensaje de
  inversión pendiente, sin número inventado.
- **AC-4**: El campo "Costo del establecimiento" es opcional en el editor de cultivos,
  persiste en Hive y sync a Supabase (`establishment_cost`), y un cultivo anual o en
  producción lo puede guardar sin validación obligatoria.
- **AC-5**: La sección Ayuda y la guía markdown explican por hectárea y amortización
  (es/en), reutilizando strings ya existentes de la app.
- **AC-6**: `flutter analyze` limpio y todos los tests verdes (nuevos + existentes).

## Pasos

1. F1 — Dato: modelo + migración + sync + editor (campo opcional).
2. F2 — Lógica: ampliar `ReportHarvestMetrics` + tests unitarios (TDD: rojo→verde).
3. F3 — UI: `per_hectare_panel.dart` + integración en `report_screen.dart` + widget test.
4. F4 — Ayuda/guía + i18n (`gen-l10n`).
5. Verificación: `flutter analyze`, `flutter test`, build release, deploy gh-pages HTTP 200.

## Decisiones confirmadas (2026-09-07)

- **D1 — Ubicación del panel**: **A. En el Reporte** (`report_screen.dart`, debajo de
  insights junto a la sección Cosechas). El widget `per_hectare_panel.dart` queda
  reutilizable para evolucionar a "ambos" (reporte + ficha de cultivo) sin rediseño.
- **D2 — Inversión del establecimiento**: **A. Campo manual opcional** en el editor de
  cultivos ("Costo del establecimiento ($)"). Se descarta calcularlo de gastos (mezcla
  producción/inversión y engaña si no se registró el efectivo) y la suma manual+gastos
  (confusa de explicar).
- **D3 — Punto de equilibrio**: **Sí, con "aprox."**. Inversión ÷ margen anual promedio
  **medido** (solo ≥1 período completo con margen > 0), etiqueta "aprox." explícita,
  caso sin cosechas → mensaje "pendiente de recuperarse" sin número.

## Riesgos

- **Incremental y opcional**: no añade pasos obligatorios al flujo actual. El usuario
  decide si llena área/inversión.
- **`breakevenYears` es "aprox."** aunque deriva de datos medidos; etiqueta explícita
  para no engañar (regla de oro intacta).
- **Sin dashboard por finca** en esta iteración: solo panel por cultivo dentro del
  reporte. Comparar entre cultivos y por año es un Nivel 3+ (futuro) si los datos lo
  permiten.

## Firmas

- Plan revisado y aprobado por el usuario (decisiones D1/D2/D3 arriba).