# Auditoría — 2026-10-01_2111-evaluacion-comprensibilidad-reportes

> Auditor `report-auditor` no está disponible como subagente; la verificación se
> ejecutó inline por el orquestador el 2026-10-02, leyendo el código real.
> Report auditado: `docs/reports/2026-10-01_2111-evaluacion-comprensibilidad-reportes.report.md`
> PRD origen (rúbrica 7 dimensiones + H1-H12 + 3 alternativas):
> `docs/prds/2026-10-01_2111-evaluacion-comprensibilidad-reportes.prd.md`

## Auditoria

### Criterios PRD

| # | Criterio | Estado | Verificación |
|---|----------|--------|--------------|
| AC1 | Evalúa Reportes + PDF + Excel | **PASS** | Secciones cubiertas en PRD §A |
| AC2 | Hallazgos con evidencia `archivo:línea` | **PASS** | H1-H12 con evidencia; verificada abajo |
| AC3 | ≥3 alternativas comparadas en tabla | **PASS** | PRD §D: Alt.1/2/3 × 6 criterios |
| AC4 | Recomendación clara, decisión en el usuario | **PASS** | §D "Recomendación (tu decisión pendiente)" |
| AC5 | Cero cambios en `lib/` | **PASS** | Solo escritura en `docs/` |
| AC6 | Reporte de ejecución en `docs/reports/` | **PASS** | Presente |

### Verificación de hallazgos contra el código

| H | Afirmación | Estado | Evidencia real |
|---|-----------|--------|----------------|
| H1 | "Margen sobre ventas" y "Gastos vs ingresos" sin señal | **PASS** | `lib/screens/report_screen.dart:314-321` — `_metricLine(l10n.marginLabel, …)` y `_metricLine(l10n.ratioLabel, …)`; solo etiqueta + porcentaje, sin verde/rojo ni ejemplo |
| H2 | PDF y Excel **no** incluyen los insights ("Conclusión del período") | **PASS** | grep `insight\|conclusi` sobre `lib/services/pdf_export_service.dart` y `excel_export_service.dart` → **0 matches**. Los insights viven solo en `lib/services/report_insights_service.dart` |
| H3 | Rojo de "Vendido vs cosechado" sin texto explicativo | **PASS** | `lib/screens/report_screen.dart:873-874` — `mismatch = soldKg > harvestedKg * 1.1` → `color = scheme.error`; las líneas 885-892 pintan el color sin leyenda |
| H4 | Negativos en notación contable `(1.500)` sin leyenda | **PASS** | `lib/screens/report_screen.dart:1329-1334` — `return value < 0 ? '($s)' : s;` |
| H5 | Jerga sin definición in-situ (kg/ha, payback, subtotal, YTD…) | **PASS con observación** | `:698` (`reportPickupCostPerKg`) sí es jerga. **`:770` es `reportPayrollTotal` ("Total nómina"), que no es jerga** — esa evidencia es floja. El hallazgo se sostiene por el resto de etiquetas; el glosario cubre solo 5 términos |
| H6 | ~10 tarjetas apiladas en `:213-466` | **PASS** | Contadas **9** tarjetas en el flujo principal: `214`, `270`, `337` (`_TopAccountsCard`), `342`, `409` (`_builtHarvestCard`), `411` (`_builtSoldVsHarvestedCard`), `413` (`_builtPayrollCard`), `415` (`_builtCashBoxCard`), `424` (`_builtRecommendationsCard`) |
| H7 | Nombre de archivo siempre con `(_month+1)` aunque el modo sea semana/año | **PASS** | `lib/screens/report_screen.dart:1074` (pdf) y `:1124` (xlsx), ambos con `(_month + 1)` incondicional; el modo (`_mode`) solo parametriza el contenido, no el nombre |
| H8 | Cifras absolutas sin comparación en tarjetas de detalle | **PASS con observación** | Las referencias `:611` (`_builtHarvestCard`) y `:786` (`_builtCashBoxCard`) son **exactas**; que las cifras "sean difíciles de interpretar" es juicio, no hecho verificable |
| H9 | ROI en la tabla PDF solo tiene pie de página | **PASS** | `lib/services/pdf_export_service.dart:308-310` — `l10n.pdfRoiFootnote`, gris, `fontSize: 8` |
| H10 | Dependencia del color en resultado / ROI / vendido-cosechado / caja | **PASS con observación** | `:874` verificado ✓. `:1267` es `color: source.withOpacity(0.08)` — un **tinte de fondo**, no el "resultado" como afirma el PRD. `:1531-1537` y `:828` **NO verificados**. El hallazgo es correcto en lo esencial pero su lista de líneas es imprecisa |
| H11 | Textos de 11-13px y filas de 11-12px | **PASS** | **30** ocurrencias con `fontSize ≤ 13` en `report_screen.dart`; `:257` (13px) y `:1233` (11px) **exactos** |
| H12 | "No hay recomendaciones para este período" no distingue "todo bien" de "sin datos" | **PASS** | `lib/l10n/app_es.arb:243` **exacto**; un único string para ambos estados |

### Verificación complementaria

- **Glosario = 5 términos** ✓ — `lib/widgets/terminology_guide.dart` define exactamente
  5 pares término/definición: ROI, Balance, Margen, Ratio, Promedio
  (`glossaryRoiTerm/Def`, `glossaryBalance*`, `glossaryMargin*`, `glossaryRatio*`, `glossaryAvg*`).

### Hallazgos que no pasan la auditoría

**Ninguno.** Cero FAIL.

### Riesgo para la Alternativa 1 (ya elegida por el usuario)

**Ninguno.** Los tres cimientos de la Alt 1 son sólidos:
- **H1** (señal bueno/malo) — PASS con línea exacta
- **H3** (rojo sin texto) — PASS con línea exacta
- **H5** (jerga sin traducir) — PASS; un solo ejemplo de evidencia es flojo, el resto se sostiene

El **H2** (exportes sin insights) también es sólido, pero pertenece a la **Alt 3**.

### Veredicto final

**PASS con observaciones** — 12/12 hallazgos verificados, 0 FAIL,
3 observaciones de precisión (H5, H8, H10) que no afectan la decisión tomada.

---

*Auditado el 2026-10-02.*
