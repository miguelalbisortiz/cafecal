---
tanda: 3
hito: 3
fecha: 2026-11-17_1223
scope: ejecución del hito 3 (concentración de comprador)
resultado: PASS
---

# Reporte · Hito 3 — concentración de comprador

## Objetivo

Convertir las ventas ya registradas del período en **una sola** recomendación
cuando más de la mitad dependen de un comprador, con el porcentaje, el nombre y
la acción de buscar un segundo comprador, con el mismo texto en Reportes, PDF y
Excel. Sin sumar monedas, sin normalizar nombres, sin monto en el texto, sin
esquema y sin tocar la paginación del PDF.

## Trazabilidad

Cubre **SC-3.1 a SC-3.4** y **SC-G1 a SC-G6** del PRD aprobado
`docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md`, según el plan
`docs/plans/2026-11-17_1205_hito3-concentracion-de-comprador.plan.md`.

## Decisiones aplicadas (confirmadas en el plan)

| # | Decisión | Aplicación |
|---|---|---|
| D1 | Umbral **`> 50 %` estricto**, con **≥2 compradores** | `if (byBuyer.length < 2) return null` y `if (sharePct <= 50) return null`. Exactamente 50 % y un solo comprador → `null`/`[]`, fijado por tests. |
| D2 | Fila con **solo `{pct}` + `{buyer}`**, sin monto | `buyerConcentrationLine` no declara `{money}` ni `{amount}`; `suggestion: ''`. No se usa `formatMoneyLabel`; el texto es corto (menos riesgo de página extra). |
| D3 | Nombres por **cadena exacta** | Clave = `t.client!` tal cual; el alta ya aplica `.trim()` (`register_screen.dart:686`). `'Café S.A.'` y `'café  s.a.'` cuentan como dos compradores y se pinta la cadena ganadora. |
| D4 | Ventas **sin comprador excluidas del denominador** | Filtro `client != null && client!.isNotEmpty` antes de sumar. Nunca se inventa «Sin nombre». Los ingresos no-venta con `client` (p. ej. `subvenciones`) tampoco cuentan. |

## Regla única

`lib/services/buyer_concentration.dart` (nuevo) posee el filtro de ventas, la
guarda de moneda, la agrupación, el umbral, la selección del principal y la
redacción. Devuelve `BuyerConcentrationRow?` (0 o 1 fila), así que los tres
pintadores solo concatenan `buyerConcentrationRecommendations(...)` **después**
de `derive`, stock y margen —el mismo patrón de los hitos 1 y 2—.

La moneda **no se reimplementa**: se llaman a `amountsByCurrency` (`:10`) e
`isMixedCurrency` (`:143`) de `currency_totals.dart`, la casa de la regla.
`TopAccounts.from` no se usa como fuente (agrupa cualquier ingreso y no descarta
borrados). No se tocaron `crop_totals.dart`, `report_harvest_metrics.dart` ni
`top_accounts.dart`.

### Doble guarda de moneda

1. `isMixedCurrency(identificadas)` → `null` antes de cualquier suma.
2. Unicidad de `codes` en el período **y** de `byCurrency.length == 1` por
   comprador → `null`. El total se suma solo dentro de un código ISO.

Aunque D2 hace que el texto no cite dinero, SC-3.4 (regla específica del hito)
manda ocultar la fila: el `share` se construye sumando importes y sin la guarda
sería falso con COP+USD. Es una decisión deliberada del plan, documentada en el
reporte del `/plan`, no una contradicción de SC-G2.

## TDD: rojo real antes del arreglo

**Línea base:** `flutter test test/export_parity_test.dart test/pdf_export_test.dart`
→ **12/12 verde**, PDF en 4 páginas y guarda de 1 página intactos, antes de
tocar producción.

`flutter test` sobre los tres archivos nuevos, antes de crear el servicio,
falló en **3 unidades**:

- `Error when reading 'lib/services/buyer_concentration.dart': The system
  cannot find the file specified.` (tests de unidad y de paridad).
- `Type 'BuyerConcentrationRow' not found` / `Method not found:
  'buyerConcentration'` / `'buyerConcentrationMessage'` /
  `'buyerConcentrationRecommendations'` / `Member not found:
  'buyerConcentration'` en `AlertRule`.
- `es · falta buyerConcentrationTitle` (guarda ARB).

Después de la implementación mínima: **13/13 dirigidos verdes**.

## Cambios

| Archivo | Cambio |
|---|---|
| `lib/services/buyer_concentration.dart` (nuevo) | `BuyerConcentrationRow`, `buyerConcentration`, `buyerConcentrationMessage`, `buyerConcentrationRecommendations`. Filtro, doble guarda de moneda, umbral estricto, orden determinista y redacción única. |
| `lib/models/farm_alert.dart` | Valor `buyerConcentration` en `AlertRule`. **`evaluateAlerts` no lo emite**: solo identifica la fila. |
| `lib/screens/report_screen.dart` | Concatenación tras el margen con `records: _recordsFor(tx)`. |
| `lib/services/pdf_export_service.dart` | Concatenación en `_recommendationsSection` con `records: periodRecords`. |
| `lib/services/excel_export_service.dart` | Concatenación en `_whatsNextBlock` con `records: periodRecords`. |
| `lib/l10n/app_es.arb` / `app_en.arb` | `buyerConcentrationTitle`, `buyerConcentrationLine` con `{pct}` y `{buyer}` declarados `String` en ese orden; sin `$` ni `→`. |
| `lib/l10n/generated/` | Regenerado con `flutter gen-l10n` y normalizado a LF. |
| `test/buyer_concentration_test.dart` (nuevo) | 9 casos puros: 70 %, 50 %, un comprador, sin comprador con denominador recortado, moneda mixta (dos guardas), nombres exactos, solo ventas con `deleted`/`subvenciones`, dato ausente y determinismo. |
| `test/report_parity_tanda3_hito3_test.dart` (nuevo) | 3 tests widget: misma cadena en los tres pintadores, oculto con 50 %/un comprador, mezcla callada. El escenario mixto inyecta conversión sin red para no dejar timers pendientes. |
| `test/l10n_buyer_concentration_test.dart` (nuevo) | Guarda ARB/generado ES/EN, placeholders, sin `$` ni `→`, sin monto en el texto, acción en ambos idiomas. |

## Nota de fidelidad al plan

El plan traía dos detalles internamente inconsistentes, resueltos con
equivalentes coherentes y documentados aquí:

1. **Caso 4 del plan** proponía «A 700 con cliente + 300 sin cliente →
   `sharePct == 100`». Con D1 eso daría **un solo comprador** y, por tanto,
   `null`: no se puede afirmar un `sharePct` desde la API pública. El test usa
   **A 700 + B 300 + 300 sin comprador** → `sharePct == 70` y
   `salesTotal == 1000`, que demuestra lo mismo (si la venta sin comprador
   entrara en el denominador sería 700/1300 ≈ 53,8) respetando `≥2`.
2. El plan enumeraba 14 casos, pero el caso 14 es la **línea base de paginación**,
   no un test nuevo. Los tests nuevos son **13** (9 + 3 + 1); la suite sube de
   1464 a **1477**.

## Reglas respetadas

- **Los tres pintadores dicen lo mismo:** una clave ARB y una función
  `buyerConcentrationMessage`; el test de paridad compara la cadena exacta en
  pantalla, PDF y Excel.
- **`null` → oculto:** sin compradores, con un comprador, con 50 % exacto, con
  moneda mixta o con total 0 no hay fila. Ni `0 %`, ni guion, ni «sin datos».
- **Sin cifras inventadas:** el denominador excluye ventas sin comprador y
  subvenciones; no se suman COP con USD; el texto no cita un monto que no se
  calculó.
- **Sin dedupe indeseado:** la fila va después de `derive`; `evaluateAlerts` y
  el banner de Inicio quedan intactos.
- **Sin esquema, migración, sync ni backfill:** solo `Transaction.client`,
  `amount`, `currency`, `category`, `deleted` y `date`, ya existentes.

## Paginación del PDF

`export_parity_test.dart:223` mantiene `paginasEsperadas = 4` con sus dos vías
(`/Type /Page` en `:231` y `/Count` en `:234`) y su comentario congelado. El
fixture de 1 página de `pdf_export_test.dart:133-168` sigue con la venta y la
cosecha **sin `cropId` y sin `client`**, y el guarda en `:190-193` sigue midiendo
solo el anexo. Ninguno de los dos se tocó. El fixture de 4 páginas es mixto
(COP+USD), así que SC-3.4 calla la fila nueva por diseño.

## Verificación

| Puerta | Resultado |
|---|---|
| `flutter analyze` (proyecto entero) | **No issues found!** |
| Rojo previo | 3 unidades antes del servicio |
| Línea base (4 y 1 páginas) | **12/12** verde antes de tocar producción |
| Dirigidos (3 archivos nuevos) | **13/13** |
| Targeted (12 archivos, con guardas) | **51/51** |
| `flutter test` suite completa | **1477/1477** (1464 anteriores + 13 nuevos) |
| Guardas `export_parity_test.dart` / `pdf_export_test.dart` | 4 páginas / 1 página, intactas |
| `git diff --check` | limpio |
| Fin de línea de `lib/l10n/generated/` | LF en los 3 archivos, 0 CRLF |

Ruido conocido y no bloqueante: `Unable to find a font to draw "☕" (U+2615)`
en tests de PDF.

Nota de herramienta: `/verify` y `/audit-report` no están instalados como
comandos en este repo. Se aplicaron sus reglas con la skill `verification-loop`
y el agente `report-auditor`; el rastro queda en `docs/reports/` y
`docs/audits/`.

## Estado

- Sin commit ni push: el último verbo cubrió la ejecución con TDD, no un commit.
- Hitos 1, 2 y 3 de la Tanda 3, completos.
- Pendiente no bloqueante: contrastar el umbral de 50 % y los nombres exactos
  con datos de finca real (10 ha, 3 cultivos, 4 trabajadores).
