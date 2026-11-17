# Sesión — martes 17 de noviembre de 2026 (Tanda 3: recomendaciones de negocio)

> Estado al cierre: las tres recomendaciones nuevas —stock sin vender, margen por
> cultivo y concentración de comprador— dicen lo mismo en Reportes, PDF y Excel.
> `main` = **`dfb3994`**, alineado con `origin/main`. Árbol de trabajo limpio.
> Toda la sesión fue TDD con rojo ejecutado antes de tocar producción; los ocho
> commits del día fueron aprobados y pusheados por el usuario.

## 1. Dónde quedó el proyecto

- `main` = **`dfb3994`**; `origin/main` = **`dfb3994`** (sin diferencia).
- Gate: `flutter analyze` limpio (proyecto entero) · **1477/1477** tests · `git diff --check` limpio.
- Guardas: PDF con **4 páginas** en el fixture congelado y **1 página** en el fixture sin `cropId` ni `client`.
- PRD aprobado: `docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md` (SC-1.x … SC-6.x).

## 2. Qué se cambió

| Pieza | Antes | Después |
|---|---|---|
| Stock sin vender | no existía | `lib/services/unsold_stock.dart`: corte rodante `now − 365 días` inyectable; lista «sin peso» solo en pantalla; fila en los 3 pintadores |
| Margen por cultivo | no existía | `lib/services/crop_margin.dart`: manda el `%`; `$/ha` como segunda cifra; fila oculta si falta área u operación; rótulo «Margen por cultivo» |
| Concentración de comprador | no existía | `lib/services/buyer_concentration.dart` + `AlertRule.buyerConcentration` + ARB ES/EN y generados; `> 50 %` estricto con `≥2` compradores; fila `{pct}` + `{buyer}`, sin monto |
| Banner de Inicio | `evaluateAlerts` | intacto: ninguna de las tres reglas se emite desde ahí; la fila se concatenó después de `derive` en cada pintador |

## 3. Secuencia y gate

| Paso | Commit | Suite |
|---|---|---|
| PRD (SC-1.x … SC-6.x) | `2ceaba3` | — |
| Plan hito 1 + hito 1 | `5c1c4ab` → `31c00dd` | 1450/1450 (13 tests nuevos) |
| Plan hito 2 + hito 2 | `4a6c0db` → `74ca17c` | 1464/1464 (14 tests nuevos) |
| Plan hito 3 + hito 3 | `8317dcd` → `dfb3994` | 1477/1477 (13 tests nuevos) |

Gate del hito 3: `flutter analyze` limpio · dirigidos 13/13 · targeted 51/51 · suite 1477/1477 · `git diff --check` limpio · guardas de 4 y 1 páginas intactas · auditoría 9 PASS + SC-G3 N/A, sin FAIL ni NIT.

## 4. Decisiones que conviene recordar

- Una sola regla por hito en `lib/services/` y los tres pintadores la consumen; la lógica no se copió en pantalla, PDF ni Excel.
- `null` → oculto; nunca se inventó monto, área, peso ni comprador. El fixture de 4 páginas mezcla COP/USD y la fila de comprador calla por SC-3.4; el de 1 página no tiene `cropId` ni `client`.
- Hito 3: nombres por cadena exacta, ventas sin comprador excluidas del denominador y doble guarda de moneda mixta.
- SC-G2 no aplica al hito 3 porque el `share` se construye sumando importes: decisión documentada, no contradicción.
- Errores del plan del hito 3 corregidos en ejecución y anotados en el plan: el caso 4 usa A700/B300 + 300 sin comprador → `70 %` y `≥2`; los tests nuevos son 13 (el «caso 14» era la línea base).
- Ruido conocido no bloqueante: `Unable to find a font to draw "☕" (U+2615)` en tests de PDF.

## 5. Rastro

- PRD: `docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md`.
- Planes: `docs/plans/2026-11-17_1106_hito1-stock-sin-vender.plan.md`, `2026-11-17_1136_hito2-margen-por-cultivo.plan.md` y `2026-11-17_1205_hito3-concentracion-de-comprador.plan.md` (`status: DONE 2026-11-17_1225`).
- Reportes/auditorías: `2026-11-17_1058` (PRD), `_1108`/`_1129` (hito 1), `_1142`/`_1200` (hito 2), `_1211`/`_1223` (hito 3), bajo `docs/reports/` y `docs/audits/`.
- `/verify` y `/audit-report` no están instalados como comandos: se aplicaron skills equivalentes y dejaron artefactos en esas dos carpetas.

## 6. Queda pendiente

- Prueba manual con finca real (10 ha, 3 cultivos, 4 trabajadores), si el usuario aporta datos; anotar el ruido del umbral `50 %` y los nombres exactos en `docs/reports/`.
- Validar remotamente el CI creado en 2A.
- Solo si se pide: planificar los hitos 4, 5 y 6 del PRD (`SC-4.x`, `SC-5.x`, `SC-6.x`).
