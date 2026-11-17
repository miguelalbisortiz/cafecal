---
tanda: 3
hito: 1
fecha: 2026-11-17_1129
scope: stock sin vender en 12 meses móviles por cultivo
resultado: PASS
---

# Reporte · Hito 1 — stock sin vender

## Objetivo

Convertir `cosechaKg − ventaKg` en una fila accionable de «Qué hacer» cuando
queda algo sin vender en los últimos 12 meses, por cultivo, con el mismo texto
en Reportes, PDF y Excel. Sin esquema, sin migración y sin inventar cifras.

## Trazabilidad

Cubre **SC-1.1 a SC-1.4** y **SC-G1 a SC-G6** del PRD aprobado
`docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md`, según el plan
`docs/plans/2026-11-17_1106_hito1-stock-sin-vender.plan.md`.

## Decisiones confirmadas (del plan)

1. **Servicio puro nuevo** `lib/services/unsold_stock.dart`; las filas se
   appending a «Qué hacer» en los tres pintadores **después** de `derive`,
   que deduplica por `AlertRule`. `evaluateAlerts` queda intacto.
2. **Corte rodante exacto** `now − 365 días`, con `now` inyectable. No se
   reutiliza el corte de `soldVsHarvested`.
3. **Listado «sin peso» solo en pantalla** (donde ya vivía) + test gemelo;
   sin sección nueva en PDF/Excel para no arriesgar una página extra.

Consecuencia escrita: la fila **no aparece en el banner de Inicio** en este
hito (ese banner consume `FarmAlert`, no el servicio nuevo). El milestone
cubre los tres pintadores del reporte, que es lo que exige SC-G4.

## TDD: rojo real antes del arreglo

Línea base: `flutter test test/export_parity_test.dart` → **5/5 verde**, PDF en
4 páginas, antes de tocar producción.

`flutter test` sobre los tres archivos nuevos, antes de crear
`unsold_stock.dart`, falló en **3 unidades**:

- `Error when reading 'lib/services/unsold_stock.dart': The system cannot find
  the file specified.` (test puro y test de paridad).
- `Method not found: 'unsoldStockByCrop'` / `'unsoldStockMessage'`.
- `es · falta stockUnsoldTitle` (guarda ARB).

Después de la implementación mínima: **13/13 dirigidos verdes**.

## Cambios

| Archivo | Cambio |
|---|---|
| `lib/services/unsold_stock.dart` (nuevo) | Regla única: ventana 365 d, conversión con `harvestKg`/`kgFromUnit`, filtro `> 0`, agrupación por `cropId`, orden por kg descendente, redacción con cifra y acción. Expone `UnsoldStockRow`, `unsoldStockByCrop`, `unsoldStockMessage` y `unsoldStockRecommendations`. |
| `lib/services/report_harvest_metrics.dart` | `harvestKg()` pública extraída de `_kgOf`; la tarjeta «Cosechas» y el stock usan la **misma** conversión. `_kgOf` ahora la delega. |
| `lib/models/farm_alert.dart` | Nuevo valor `AlertRule.unsoldStock`. No lo emite `evaluateAlerts`: solo identifica la fila. |
| `lib/screens/report_screen.dart` | Concatena `unsoldStockRecommendations(...)` tras `derive`. |
| `lib/services/pdf_export_service.dart` | Misma concatenación en `_recommendationsSection`. |
| `lib/services/excel_export_service.dart` | Misma concatenación en `_whatsNextBlock`. |
| `lib/l10n/app_es.arb` / `app_en.arb` | `stockUnsoldTitle` y `stockUnsoldLine` con placeholders `{kg}`, `{crop}` en orden de frase. |
| `lib/l10n/generated/` | Regenerado con `flutter gen-l10n` y normalizado a LF. |
| `test/unsold_stock_test.dart` (nuevo) | 10 casos puros: 364/365/366 días, límites inclusivos, una fila por cultivo sin dedupe, orden, 0 y negativo ocultos, gemelo sin peso, moneda mixta, `sacoKg` configurable y `cropId` nulo. |
| `test/report_parity_tanda3_hito1_test.dart` (nuevo) | 2 tests widget: misma cadena en los 3 pintadores, con un cultivo y con dos. |
| `test/l10n_stock_sin_vender_test.dart` (nuevo) | Guarda ARB y generado ES/EN, placeholders, sin `$` ni `→`. |
| `test/pdf_export_test.dart` | Ajuste de fixture (ver «Hallazgo»). Sin tocar la expectativa de páginas. |

## Reglas respetadas

- **Los tres pintadores dicen lo mismo**: una sola función redacta la frase;
  el test de paridad la compara en pantalla, PDF y Excel, con dos cultivos.
- **`null` → oculto**: sin stock no hay fila; `cropId` nulo se omite; ni un
  `0 kg` ni un texto de «sin datos».
- **Kilos sin peso se listan, no se suman**: `kgFromUnit` devuelve `null` y la
  fila se omite; el registro sigue en `pendingWeight*` de pantalla (test gemelo).
- **Sin cifras inventadas**: la frase cita solo el kg calculado y la acción;
  es de kilos, así que moneda mixta no cambia nada y nunca cita `$`, `COP` ni `USD`.
- **Sin dedupe indeseado**: las filas van después de `derive`, para no perder
  dos cultivos con excedente.

## Hallazgo y arreglo del guarda de 1 página

La primera suite completa terminó **1449 pasaron, 1 falló**:
`pdf_export_test.dart → «Nómina y caja va en anexo con salto de página solo si
hay contenido»`, esperaba 1 página y dio 2.

Diagnóstico con un test temporal de instrumentación (borrado después):

- El fixture tenía cosecha con `cropId: 'cafe'` y venta sin `cropId`. La regla
  nueva no puede atribuir esa venta, así que ve 100 kg sin vender y añade una
  fila a «Qué hacer» → segunda página.
- Al atribuir la venta al cultivo desaparece esa fila (0 filas de stock), pero
  aparece `deficitCrop` → también segunda página.
- Con **venta y cosecha sin cultivo** (fixture aislado): 0 filas de stock,
  0 alertas, **1 página**. Es el estado que el guarda quería medir: solo el
  anexo de nómina, sin «Qué hacer» de por medio.

Arreglo: el fixture deja ambos registros sin `cropId` y lleva un comentario que
explica por qué. **No se cambió la expectativa de 1 página**, ni se tocó la
regla de negocio, ni se debilitó el guarda: el stock y el déficit tienen sus
propios tests. El debug temporal se eliminó.

## Paginación del PDF

El fixture congelado de 4 páginas de `export_parity_test.dart` sigue en
**4 páginas** (5/5 verde en la línea base y en la suite final). No se cambió
`paginasEsperadas` ni su comentario de motivo. La fila nueva es una línea en
«Qué hacer»; el único desborde observado fue el fixture de 1 página descrito
arriba y se corrigió en el fixture, no en el motor.

## Verificación

| Puerta | Resultado |
|---|---|
| `flutter analyze` (proyecto entero) | **No issues found!** |
| Rojo previo | 3 unidades en rojo antes del arreglo |
| Línea base `export_parity_test.dart` | **5/5**, 4 páginas |
| Dirigidos (3 archivos nuevos) | **13/13** |
| Guardas de regresión (7 archivos) | **90/90** |
| `pdf_export_test.dart` tras el arreglo | **7/7** |
| `flutter test` suite completa | **1450/1450** (1437 anteriores + 13 nuevos) |
| `git diff --check` | limpio (tras normalizar `farm_alert.dart` a LF) |
| Fin de línea de `lib/l10n/generated/` | LF en los 3 archivos, 0 CRLF |
| Archivo temporal de debug | eliminado |

Ruido conocido y no bloqueante: `Unable to find a font to draw "☕" (U+2615)`
y `"👷" (U+1f477)` en tests de PDF.

Nota de herramienta: `/verify` y `/audit-report` no están instalados como comandos en
este repo (igual que `/spec-lint`). Se aplicaron sus reglas con la skill
`verification-loop` y el agente `report-auditor`; el rastro queda en
`docs/reports/` y `docs/audits/`.

## Estado

- Sin commit ni push: no hubo verbo explícito en este turno.
- Siguiente: hito 2 (margen por cultivo y por hectárea), según el PRD.
- Pendiente de validación no bloqueante: contrastar los umbrales del PRD con
  datos de finca real (gate de la Tanda 2 y decisiones D4/D6).
