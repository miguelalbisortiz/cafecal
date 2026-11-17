---
tanda: 3
hito: 3
fecha: 2026-11-17_1211
scope: plan del hito 3 (concentración de comprador)
resultado: PASS
---

# Reporte · `/plan` del hito 3 — concentración de comprador

## Objetivo

Convertir el hito 3 del PRD aprobado en un plan ejecutable con secuencia TDD,
sin escribir código de producción ni commitear.

## Entregable

`docs/plans/2026-11-17_1205_hito3-concentracion-de-comprador.plan.md` —
**DRAFT**, listo para ejecución. 14 casos concretos, trazabilidad de
SC-3.1..SC-3.4 y SC-G1..SC-G6, firma de datos y 10 riesgos con guarda nombrada.

## Decisiones confirmadas por el usuario

Las cuatro opciones con más de una alternativa razonable se preguntaron con la
recomendación delante; el usuario eligió las cuatro «Recomendado»:

| # | Decisión | Elección |
|---|---|---|
| D1 | Umbral | **`> 50 %` estricto**; exactamente 50 % → oculto. Concuerda con «supera el 50 %» de D4/SC-3.2 y con «no supera» de SC-3.3. |
| D2 | Cifra citada | **Solo `{pct}` + `{buyer}`**, sin monto. SC-3.2 pide porcentaje, nombre y acción; texto corto y sin formato de moneda nuevo. |
| D3 | Nombres de comprador | **Cadena exacta** (solo el `.trim()` que ya hace el alta en `register_screen.dart:686`). No se inventa una identidad que la app no guarda; se mide en la prueba de finca real. |
| D4 | Ventas sin comprador | **Excluidas del denominador**. SC-3.1 dice «ventas con cliente identificado» y `TopAccounts.from` ya las ignora; nunca se inventa un comprador «Sin nombre». |

Consecuencias: el aviso exige **≥2 compradores y `share > 50 %`**; con un solo
comprador no se emite (registro explícito de D4 del PRD). La fila no necesita
`formatMoneyLabel`, pero sí la guarda de moneda mixta de SC-3.4, que es distinta.

## Diseño

- **Regla única** en `lib/services/buyer_concentration.dart` (nuevo): filtro de
  ventas, guarda de moneda, agrupación por nombre exacto, umbral estricto,
  selección del principal y redacción. Devuelve `BuyerConcentrationRow?`
  (0 o 1 fila). Los tres pintadores no calculan: concatenan el resultado.
- **Moneda no reimplementada**: el servicio llama a `amountsByCurrency`
  (`currency_totals.dart:10`) e `isMixedCurrency` (`:143`), la casa donde ya se
  decide eso. No se tocan `crop_totals.dart`, `report_harvest_metrics.dart` ni
  `top_accounts.dart`.
- **`TopAccounts.from` no es la fuente directa**: agrupa cualquier ingreso con
  `client` (incluye `subvenciones`) y no descarta borrados. El servicio aplica
  él mismo el filtro de venta (`isSaleCategory`, `categories.dart:86`) y solo
  reutiliza el criterio de cadena exacta como referencia de comportamiento.
- **Flujo:** transacciones del período (`recordsForPeriod` / `_recordsFor`) →
  guarda de moneda → servicio → 0 o 1 `Recommendation`
  (`rule = AlertRule.buyerConcentration`) → pantalla, PDF y Excel **después**
  de `derive`, stock y margen. `evaluateAlerts` no emite esta regla.
- **Sin reloj**: la ventana la decide el período; el orden es por `buyerAmount`
  descendente y desempate por `buyer` ascendente, sin `DateTime.now()`.
- **Texto**: una sola clave ARB por idioma; `{pct}` pasa por `formatPct`
  (`format.dart:36`); `severity: info` y `suggestion: ''` para no repetir la
  acción.

### Nota sobre SC-G2

El criterio general SC-G2 permite seguir visibles las recomendaciones que solo
citan porcentajes. Aquí **no aplica esa excepción**: el plan lo documenta
explícitamente porque el `share` se construye sumando importes; sin la guarda
de SC-3.4 el porcentaje sería falso con COP+USD. Es una decisión deliberada y
trazada, no una contradicción con el PRD.

## Secuencia TDD

1. **Rojo** — 3 archivos nuevos: `buyer_concentration_test.dart` (9 casos puros:
   A700/B300 → 70 %, exactamente 50 %, un comprador, sin comprador y variante
   con denominador recortado, moneda mixta con doble guarda, nombres con
   mayúsculas/espacios, solo ventas con `deleted` y `subvenciones`, dato ausente
   y montos 0, determinismo), `report_parity_tanda3_hito3_test.dart` (3 casos:
   cadena idéntica en los tres pintadores, oculto con 50 %/un comprador, mezcla
   callada) y `l10n_buyer_concentration_test.dart` (SC-G6: ES/EN, `{pct}` y
   `{buyer}` en orden, sin `$` ni `→`, acción en ambos idiomas).
2. **Línea base** — 4 páginas en `export_parity_test.dart` **y** 1 página en
   `pdf_export_test.dart`, verdes antes de tocar los pintadores. No se tocan
   fixtures ni expectativas: el fixture de 4 páginas es mixto (COP+USD) y el de
   1 página lleva la venta sin `client`, así que la fila nueva no debe aparecer.
3. **Implementación mínima** — valor `buyerConcentration` en `AlertRule`,
   servicio nuevo con `amountsByCurrency`/`isMixedCurrency`, ARB + `gen-l10n`/
   LF, y una línea de concatenación por pintador con `records` del período
   (`periodRecords` en PDF y Excel; sin parámetros nuevos).
4. **Verify** — analyze → targeted (12 archivos) → suite completa (base 1464) →
   gate ARB/LF → reporte y auditoría → `/verify` y `/audit-report` equivalentes.

## Guardas que no se tocan

- `paginasEsperadas = 4` (`export_parity_test.dart:223`), sus dos vías de
  conteo (`/Type /Page` y `/Count`) y su comentario congelado. Si sube a 5, se
  comprueba primero si la guarda de moneda mixta falló; **nunca** se actualiza
  el número a ciegas.
- `pdf_export_test.dart`: su fixture de 1 página sigue con venta y cosecha sin
  `cropId` **y sin `client`** a propósito (`:133-168`), para aislar el anexo.
- `derive` y su dedupe; `evaluateAlerts`; el banner de Inicio. No se relaja
  `report_recommendations_test.dart`.
- Sin esquema, migración, sync ni backfill: solo `Transaction.client`, `amount`,
  `currency`, `category`, `deleted` y `date`, ya existentes y sincronizados.
- Generados `lib/l10n/generated/` normalizados a LF tras `gen-l10n`.

## Estado

- Sin código, commit ni push: `git status` muestra solo el plan nuevo; `main`
  sigue en `74ca17c`.
- Siguiente: ejecutar el plan con TDD; cualquier commit o push exige verbo
  explícito en ese turno.
- La prueba con finca real (10 ha, 3 cultivos, 4 trabajadores) sigue pendiente
  y no bloquea: mide el ruido del umbral de 50 % y los nombres exactos.
