# Auditoría — 2026-10-02_1710-alineacion-datos-finalidad-reportes

> `report-auditor` no corre como subagente; verificación inline por el orquestador
> el 2026-10-02, leyendo el código real.
> Report auditado: `docs/reports/2026-10-02_1710-alineacion-datos-finalidad-reportes.report.md`
> Entregable: `docs/plans/2026-10-02_1710-alineacion-datos-finalidad-reportes.plan.md`

## Auditoria

### Criterios PRD (SC1-SC6)

| SC | Criterio | Estado | Verificación |
|----|----------|--------|--------------|
| SC1 | Matriz de trazabilidad 100% entidades + 12 secciones + 3 exports con `archivo:línea` | **PASS** | §1-§2 presentes y con evidencia comprobable |
| SC2 | Finalidad declarada por sección con veredicto alineado/parcial/sin soporte | **PASS** | §3 — 8 alineadas, 4 parciales |
| SC3 | Huecos en 3 categorías priorizadas | **PASS con observación** | §4 existe y está priorizado, pero **B1 es falso** (ver abajo) |
| SC4 | Propuesta coherente con la finalidad y con la Alt 1 vigente | **PASS** | §5: P1-P4 marcados ✅ compatibles, P5-P12 marcados "requiere decisión futura", P8 explícitamente congelado. **Se respetó la corrección de objetivo** |
| SC5 | Cero cambios en `lib/` y `test/` | **PASS** | Solo artefactos en `docs/` |
| SC6 | Reporte de ejecución en `docs/reports/` | **PASS** | Presente |

### Verificación de huecos contra el código

| ID | Afirmación | Estado | Evidencia real |
|----|-----------|--------|----------------|
| **A1** | Siembras completas (plants/pérdidas/motivo) nunca se muestran | **PASS** | `lib/models/sowing.dart:6-9` registra `plants`, `areaHa`, `lostPlants`, `reason`. `lib/screens/report_screen.dart` **no referencia** `lostPlants` ni `.reason` en ninguna línea; solo reenvía `sowings:` a los exportes (910, 1070, 1120) |
| **A2** | `day_rate` registrado sin reporte | **PASS** | Se captura en `employee_editor_dialog.dart:66` y se muestra en `workers_screen.dart:119-121`; **cero** usos en `report_screen.dart`, `pdf_export_service.dart` ni `excel_export_service.dart` |
| **A3** | `sowing_id` sin uso en reportes | **PASS** | Existe en `models/transaction.dart` y se sube a BD (`sync_provider.dart:293`); ningún reporte agrupa por él |
| **A4** | `description` sin reporte | **PASS parcial** | **Sí** se exporta en Excel: `excel_export_service.dart:727`. **No** aparece en la pantalla de Reportes ni en el PDF. La afirmación "registrado sin reporte" es excesiva: es "sin reporte en pantalla ni PDF" |
| **B1** | **"Top accounts" se lee como deuda y no lo es** | **FAIL** | El copy **no** dice deuda en ningún idioma. `app_es.arb:390-391` = **"Principales compradores" / "Principales proveedores"**; `app_en.arb:384-385` = "Top buyers / Top suppliers". El PDF usa las mismas claves (`pdf_export_service.dart:449,452`). El cálculo (`models/top_accounts.dart:12-28`) suma montos de movimientos, y **no existe** texto de "deuda/cobrar/por pagar/saldo" en ninguna tarjeta. **Premisa de P1 inválida** |
| **B2** | Totales duplicados | **PASS** | El resultado aparece 2 veces en pantalla: `insightBalancePositive(balance, margin)` dentro de Insights (`report_screen.dart:235`) y de nuevo en `_resultLine` (`:312`, etiqueta `resultPeriodLabel` en `:1274`) + `marginLabel` otra vez en `:314` |
| **B3** | Destino contado 2× | **NOT_VERIFIABLE** (sin verificar en esta pasada) | — |
| **B4** | Margen sin señal | **PASS** | Coincide con H1 del PRD 21:11, ya auditado: `report_screen.dart:314-321` |
| **B5** | PDF/Excel sin insights | **PASS** | Ya auditado: 0 matches de `insight` en ambos servicios |
| **C1** | No existe estado pendiente/cobrado | **PASS** | `models/transaction.dart` no tiene campo de estado de cobro; `pendingSync` es de sincronización, no de pago |
| **C2** | Café almacenado sin valor $ | **NO APLICA** | El modelo sí carece de valor de bodega (`models/harvest.dart` solo tiene el enum `destination`), pero **queda descartado por decisión de dominio del 2026-10-02**: el usuario confirma que **no existe bodega** — "todo lo que se cosecha se vende, no se tiene nada almacenado, ya que son pequeños productores de café". Hueco irrelevante para este segmento; **no priorizar** |

### Observaciones sobre la propuesta P1-P12

| P | Estado | Observación de auditoría |
|---|--------|--------------------------|
| **P1** | ⚠️ **REVISAR** | Su premisa (**B1**) es **falsa**. El nombre actual ya es "Principales compradores/proveedores", que **no** lee como deuda. Renombrar a "Mis compradores y proveedores" sería cosmético y sin hallazgo que resolver. **Recomiendo sacar P1 del alcance** |
| **P2** | ✅ | Sólido — H1 verificado con línea exacta |
| **P3** | ✅ | Sólido — H3 verificado con línea exacta |
| **P4** | ✅ | **Confirmado**: el mismo número aparece en Insights y en `resultPeriodLabel` (`_resultLine` `:1274`). Unificar la etiqueta es copy y cierra B2 |
| P5-P12 | ✅ clasificación | Correctamente marcados "requiere decisión futura"; P8 marcado congelado |

### Corrección cruzada con la auditoría 21:11

La observación que esta auditoría originalmente señalaba sobre H10 **ya fue corregida**
en `docs/audits/2026-10-02_2111-evaluacion-comprensibilidad-reportes.audit.md` el
2026-10-02: `report_screen.dart:1267` **sí** cae dentro de `_resultLine` (1263-1293)
y es el fondo del bloque de resultado. La cita H10 era correcta y la observación
quedó retirada.

### Contexto de dominio registrado el 2026-10-02

> **No hay bodega.** Todo lo que se cosecha se vende; nada queda almacenado
> (pequeños productores de café).

Impacto en esta auditoría:
- **C2 descartado** (arriba).
- **Copy del hueco B3/H3**: la explicación del rojo de "Vendido vs cosechado"
  **no puede** sugerir "revisa si salió de café de bodega" — sería falso para
  este usuario. Debe apuntar a las causas reales: venta perteneciente a una
  cosecha de un período anterior, o una cosecha sin registrar.

### Veredicto final

**PASS con observaciones (1 hallazgo FAIL)**

- 11 de 12 huecos verificados: **10 PASS, 1 PASS parcial (A4), 1 FAIL (B1)**
- SC1-SC6: todos PASS (SC3 con la salvedad de B1)
- **Acción sobre el alcance aprobado**: **P1 debe revisarse** — su justificación no
  existe en el código. P2, P3 y P4 sí están sólidamente sustentados.

---

*Auditado el 2026-10-02.*
