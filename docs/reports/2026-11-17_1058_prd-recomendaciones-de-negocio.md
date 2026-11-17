---
tanda: 3
fecha: 2026-11-17_1058
scope: PRD de recomendaciones de negocio (Tanda 3)
resultado: PASS
---

# Reporte · PRD de recomendaciones de negocio

## Objetivo

Dejar aprobado, antes de tocar código, el PRD de la Tanda 3: convertir seis
datos que la app ya registra en recomendaciones accionables visibles con el
mismo texto en Reportes, PDF y Excel.

## Entregable

`docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md` → **APROBADO**.

- 31 criterios EARS con modal `SHALL` / `SHALL NOT`: 6 comunes (SC-G) y 25 de
  las seis recomendaciones (SC-1.x a SC-6.x).
- 8 decisiones confirmadas explícitamente por el usuario, una por una, con la
  recomendación delante. Las 8 eligieron la opción «Recomendado».
- Alternativas descartadas con motivo, fuera de alcance explícito, supuestos,
  riesgos con mitigación, dependencias y 6 hitos con orden de entrega.

## Decisiones confirmadas

| # | Decisión |
|---|---|
| D1 | Las 6 recomendaciones en el PRD, hitos 1→2→3 y luego 4→5→6 |
| D2 | Stock: 12 meses móviles, por cultivo |
| D3 | Margen: una sola fila con dos cifras, mismo reparto del desglose |
| D4 | Comprador: aviso si el principal > 50 % con ≥2 compradores |
| D5 | Descuento: sí, solo si hay kg descontados > 0 |
| D6 | Brecha: Δ ≥ 10 % vs ≥2 años cerrados, texto sin densidad |
| D7 | Caja: días integrados en la alerta existente, sin fila duplicada |
| D8 | Tipo de cultivo: fuera de alcance, PRD aparte solo con error real |

## Reglas heredadas que quedan blindadas en el PRD

Moneda única o se oculta; `null` → oculto; kilos sin peso se listan, no se
suman; cada fila dice la acción y la cifra; los tres pintadores dicen lo mismo;
sin esquema ni migración; PDF sigue en 4 páginas con el fixture congelado.

## Validación

| Puerta | Resultado |
|---|---|
| Auto-lint del PRD (reglas de `/spec-lint` aplicadas a mano) | **PASS** — 0 FAIL |
| Criterios con modal EARS | **31/31** |
| `TBD` / palabras prohibidas | **0** |
| Alcance explícito no vacío | **sí** |
| Código tocado | **ninguno** |
| Commit / push | **ninguno** |

El comando `/spec-lint` no está instalado en el repo; se aplicaron sus reglas
manualmente sobre el artefacto.

## Estado

- Sin commit ni push: el PRD quedó sin commitear.
- Siguiente: `/plan` sobre el PRD, tomando el hito 1 (stock sin vender).
- Validación no bloqueante pendiente: contrastar los umbrales 50 % y 10 % con
  datos de finca real y anotar el conteo en `docs/reports/`.
