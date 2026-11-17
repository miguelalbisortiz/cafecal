---
tanda: 3
hito: 2
fecha: 2026-11-17_1142
scope: plan del hito 2 (margen por cultivo y por hectárea)
resultado: PASS
---

# Reporte · `/plan` del hito 2 — margen por cultivo

## Objetivo

Convertir el hito 2 del PRD aprobado en un plan ejecutable con secuencia TDD,
sin escribir código de producción ni commitear.

## Entregable

`docs/plans/2026-11-17_1136_hito2-margen-por-cultivo.plan.md` — **DRAFT**,
listo para ejecución. 15 casos concretos, trazabilidad de SC-2.1..2.5 y
SC-G1..SC-G6, y 10 riesgos con guarda nombrada.

## Decisiones confirmadas por el usuario

Las tres opciones con más de una alternativa razonable se preguntaron con la
recomendación delante; el usuario eligió las tres «Recomendado»:

| # | Decisión | Elección |
|---|---|---|
| D1 | Qué cifra manda para nombrar al «mejor cultivo» | El **margen %** (SC-2.1); el `$/ha` va como segunda cifra. No se redefine la palabra «margen». |
| D2 | Si al ganador le falta área o no hay gastos repartidos | **Ocultar la fila completa**. D3 exige dos cifras y SC-2.3 condiciona «WHEN ambas cifras existan». |
| D3 | Rotulo de la fila | **«Margen por cultivo»** en los tres pintadores, con la acción de priorizar ahí la mano de obra. |

Consecuencias: el servicio devuelve **como máximo una** fila (`CropMarginRow?`),
no una lista; el desempate lo fija el propio servicio; dos claves ARB nuevas.

## Diseño

- **Atribución (dueño único):** `crop_totals.dart` (`repartoPorHectareas` →
  `splitLotExpenses` → `cropBreakdownRows`). El servicio nuevo llama a esa
  misma función pura; no implementa reparto propio. Un lote sin repartir sigue
  en fila aparte y nunca entra con una proporción inventada.
- **Selección y redacción (dueño único):** `lib/services/crop_margin.dart`
  (nuevo). Filtros, elección del ganador por %, las dos cifras y la frase.
  Los tres pintadores solo concatenan después de `derive`, igual que en el hito 1.
- **Dos cifras, una atribución, dos cestas:** el `%` usa todos los gastos del
  desglose (es la cifra que ya pinta la tarjeta); el `$/ha` cuenta **solo
  operación**, igual que `ReportHarvestMetrics.costPerHa`. El texto las nombra
  por separado para que no se confundan. Se fija con el caso 2.
- **Sin reloj:** la ventana es la del reporte (`periodTx`), no una rodante.
  Determinismo comprobado en el caso 9.

## Secuencia TDD

1. **Rojo** — 3 archivos nuevos: `crop_margin_test.dart` (10 casos puros:
   D1, dos cestas, una fila con dos cifras, área nula/0, lote sin repartir,
   moneda mixta, dato ausente, sin 100 % inventado, desempate y reparto
   compartido), `report_parity_tanda3_hito2_test.dart` (3 casos: mismos tres
   pintadores, una sola fila y mezcla callada) y `l10n_crop_margin_test.dart`
   (ES/EN, placeholders `{crop}`/`{pct}`/`{money}`, sin `$` ni `→`).
2. **Línea base** — 4 páginas en `export_parity_test.dart` **y** 1 página en
   `pdf_export_test.dart`, verdes antes de tocar los pintadores. No se tocan
   fixtures ni expectativas.
3. **Implementación mínima** — extraer `margin`/`marginPct` a
   `CropBreakdownRow` (sin cambiar valores), valor `cropMargin` en `AlertRule`,
   servicio nuevo, ARB + `gen-l10n`/LF, una línea de concatenación por pintador
   con `periodTx`/`terrenos` en PDF y Excel.
4. **Verify** — analyze → targeted (9 archivos) → suite completa (base 1450) →
   gate ARB/LF → reporte y auditoría → `/verify` y `/audit-report`.

## Guardas que no se tocan

- `paginasEsperadas = 4` y sus dos vías de conteo, con comentario intacto. El
  fixture congelado es mixto (COP+USD), así que SC-2.5 calla la fila.
- El fixture de 1 página de `pdf_export_test.dart`: venta y cosecha siguen sin
  `cropId` a propósito desde el hito 1, para aislar el anexo.
- `derive` y su dedupe; `evaluateAlerts`; el banner de Inicio.
- Sin esquema, migración, sync ni backfill: solo campos existentes.

## Estado

- Sin código, commit ni push: `git status` muestra solo el plan nuevo.
- Siguiente: ejecutar el plan con TDD; cualquier commit o push exige verbo
  explícito en ese turno.
