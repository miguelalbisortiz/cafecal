---
prd: docs/prds/2026-10-01_2111-evaluacion-comprensibilidad-reportes.prd.md
status: IN_PROGRESS
created: 2026-10-01_2111
---

# Implementation Plan: Evaluación de comprensibilidad de reportes + alternativas

## Overview
Auditar la pantalla de Reportes y los exportes PDF/Excel de Mi Cafetal contra el criterio
"usuario general promedio sin formación financiera", con evidencia de código, y presentar
3 alternativas comparadas. Sin tocar `lib/`.

## Requirements
- Ver PRD: `docs/prds/2026-10-01_2111-evaluacion-comprensibilidad-reportes.prd.md`

## Implementation Steps

### Fase 2A: Análisis en paralelo (3 agentes)
1. **Inventario de secciones y copy** — agente `code-explorer`
   - Archivos: `lib/screens/report_screen.dart`, `lib/services/report_*.dart`,
     `lib/l10n/app_es.arb`, `lib/widgets/terminology_guide.dart`
   - Output: mapa de secciones, métricas, términos técnicos, texto literal de cada sección
   - Dependencias: PRD
2. **Crítica de comprensibilidad UI** — agente `expert-frontend` (a11y/UX)
   - Mismo archivo: jerarquía, señal bueno/malo, densidad, affordance del glosario
   - Dependencias: PRD (paralelo con 1)
3. **Evaluación de exportes** — agente `doc-updater`/`general`
   - Archivos: `lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart`
   - Dependencias: PRD (paralelo con 1-2)

### Fase 3: Síntesis (orquestador)
4. **Evaluación consolidada** → `docs/prds/...evaluacion...prd.md` (sección Evaluación)
   - Escala cumple/parcial/no cumple por sección + hallazgos con `archivo:línea`
5. **3 alternativas comparadas** → misma sección, tabla esfuerzo/impacto/pros/contras + recomendación

### Fase 4: Reporte de ejecución
6. `docs/reports/2026-10-01_2111-evaluacion-comprensibilidad-reportes.report.md`

## Testing Strategy
- N/A (sin cambio de código). Verificación: cobertura de todas las secciones listadas
  en el PRD y presencia de evidencia `archivo:línea` en cada hallazgo (AC1-AC2).

## Risks & Mitigations
- report_screen.dart grande (1625 líneas) → agentes leen por secciones en paralelo
- Sesgo elogista → exigir escala con "no cumple" y evidencia

## Success Criteria
- [ ] Todas las secciones + PDF/Excel evaluados
- [ ] Hallazgos con evidencia
- [ ] ≥3 alternativas comparadas
- [ ] Cero cambios en lib/
- [ ] Reporte de ejecución escrito
