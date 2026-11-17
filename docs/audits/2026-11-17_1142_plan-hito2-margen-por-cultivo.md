---
tanda: 3
hito: 2
fecha: 2026-11-17_1142
veredicto: PASS
reporte: docs/reports/2026-11-17_1142_plan-hito2-margen-por-cultivo.md
---

# Auditoría · `/plan` del hito 2

| Criterio | Evidencia | Resultado |
|---|---|---|
| Plan trazado al PRD aprobado | `docs/plans/2026-11-17_1136_hito2-margen-por-cultivo.plan.md` referencia `docs/prds/2026-11-17_1050-recomendaciones-de-negocio.prd.md` y mapea SC-2.1..2.5 + SC-G1..G6 | PASS |
| Decisiones de diseño confirmadas | D1, D2 y D3 preguntadas con la recomendación delante; el usuario eligió las tres «Recomendado» | PASS |
| Regla única sin duplicar | Atribución en `crop_totals.dart`; selección y texto en `crop_margin.dart`; los tres pintadores solo concatenan | PASS |
| Una fila con dos cifras | Firma `CropMarginRow?` (no lista), D2 oculta si falta el área, D1 fija el %, caso 3 comprueba la frase con ambas cifras | PASS |
| Dos cestas de gasto sin confusión | `%` sobre todos los gastos del desglose; `$/ha` solo operación; caso 2 falla si se suma el equipo | PASS |
| TDD con rojo antes del código | 15 casos concretos en 3 archivos nuevos; se anota el mensaje de fallo esperado antes de implementar | PASS |
| Guardas de paginación intactas | 4 páginas en `export_parity_test.dart` (dos vías de conteo) y 1 en `pdf_export_test.dart`; prohibido tocar números, comentarios ni el fixture sin `cropId` | PASS |
| Moneda mixta y nulo | Doble guard (`isMixed` + unicidad de `singleCurrency`); sin `?? 0`; casos 4, 6, 7, 8 y 13 | PASS |
| Sin reloj ni dedupe indeseado | El servicio no recibe `now` y usa `periodTx`; caso 9 verifica determinismo; fila concatenada después de `derive` | PASS |
| Sin esquema ni migración | Solo `Crop.areaHa`, `Transaction`, `CropBreakdownRow.expenseTxs` e `isOperationExpense`, ya existentes | PASS |
| ARB y LF | Claves ES/EN con placeholders declarados en orden; `gen-l10n` y normalización LF; barridos existentes sin editar | PASS |
| Sin código, commit ni push | `git status` solo muestra el plan nuevo | PASS |

## Seguridad y disciplina

- Sin secretos ni credenciales.
- Sin comandos destructivos, dependencias nuevas ni permisos nuevos.
- El plan respeta el consentimiento para commit/push: lo exige explícitamente
  en el turno correspondiente.

## Observaciones (no bloqueantes)

1. El plan queda en `status: DRAFT`: las decisiones están confirmadas, pero el
   plan completo no se ha aprobado como artefacto aparte de este rastro.
2. Igual que en el hito 1, la fila no aparece en el banner de Inicio:
   `evaluateAlerts` no emite esta regla. Está escrito en el plan.
3. La definición de done incluye `/verify` y `/audit-report`, además del
   reporte y la auditoría de este `/plan`.

**Veredicto: PASS.**
