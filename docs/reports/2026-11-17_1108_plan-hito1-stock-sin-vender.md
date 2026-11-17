---
tanda: 3
fecha: 2026-11-17_1108
scope: plan del hito 1 (stock sin vender)
resultado: PASS
---

# Reporte · `/plan` del hito 1 — stock sin vender

## Objetivo

Convertir el hito 1 del PRD aprobado en un plan ejecutable con secuencia TDD,
sin escribir código de producción ni commitear.

## Entregable

`docs/plans/2026-11-17_1106_hito1-stock-sin-vender.plan.md` — **DRAFT**,
listo para ejecución. Trazabilidad explícita de SC-1.1..SC-1.4 y SC-G1..SC-G6.

## Decisiones confirmadas por el usuario

Las tres opciones con más de una alternativa razonable se preguntaron con la
recomendación delante; el usuario eligió las tres «Recomendado»:

| # | Decisión | Elección |
|---|---|---|
| D1 | Dónde vive la regla | Servicio puro nuevo `unsold_stock.dart`; filas appendadas a «Qué hacer» en los tres pintadores, **sin pasar por `derive`** (que deduplica por `AlertRule`). `evaluateAlerts` intacto. |
| D2 | Ventana | Función nueva con corte rodante exacto `now − 365 días`, `now` inyectable. No reutilizar el corte de `soldVsHarvested`. |
| D3 | Listado «sin peso» | Solo en pantalla (donde ya vive) + test gemelo. Sin sección nueva en PDF/Excel para no arriesgar una página extra. |

Consecuencia escrita: la fila no aparece en el banner de Inicio en este hito;
el milestone cubre los tres pintadores del reporte, que es lo que exige SC-G4.

## Diseño

- **Regla única** en `lib/services/unsold_stock.dart`: ventana, conversión,
  filtro `> 0`, agrupación por cultivo y redacción. Los pintadores solo appendan.
- **Fuentes**: cosechas de `effectiveHarvests` (incluye las derivadas de venta y
  de jornal medido, que `storedHarvests` perdería); ventas `income` no borradas
  de categoría de venta; conversión con `kgFromUnit` y `harvestKg` pública nueva.
- **Sin peso**: `kgFromUnit` devuelve `null`, la fila se omite y el registro
  sigue en las listas `pendingWeight*` de la pantalla.
- **Cultivo**: agrupación por `cropId`; filas sin cultivo se omiten; orden por
  `unsoldKg` descendente sin tope.

## Secuencia TDD

1. **Rojo** — 3 archivos nuevos: `unsold_stock_test.dart` (10 casos: 364/365/366
   días, una fila por cultivo, 0 y negativo ocultos, gemelo sin peso, moneda
   mixta, `sacoKg` configurable, `cropId` nulo), `report_parity_tanda3_hito1_test.dart`
   (misma cadena en 3 pintadores, dos cultivos sin dedupe) y
   `l10n_stock_sin_vender_test.dart` (ES/EN, placeholders, sin `$` ni `→`).
2. **Línea base** — `export_parity_test.dart` verde en 4 páginas antes de tocar.
3. **Implementación mínima** — `harvestKg` pública, valor `AlertRule.unsoldStock`,
   servicio nuevo, ARB + `gen-l10n`/LF, una línea de concatenación por pintador.
4. **Verify** — analyze → targeted → suite completa → gate ARB/LF → reporte y
   auditoría → `/verify` y `/audit-report`.

## Guardas que no se tocan

- PDF en **4 páginas** (`paginasEsperadas`, comprobado por `/Type /Page` y
  `/Count`, con su comentario de motivo intacto).
- `derive` conserva su dedupe y sus tests; las filas van después.
- Sin esquema, migración, sync ni backfill.
- Generados `lib/l10n/generated/` normalizados a LF tras `gen-l10n`.

## Estado

- Sin código, commit ni push: `git status` muestra solo el plan nuevo.
- Siguiente: ejecutar el plan con TDD; el propio plan exige verbo explícito para
  cualquier commit o push.
