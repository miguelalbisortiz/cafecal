# PRD: Alertas coherentes con la estacionalidad — A1 + C + B

- **Fecha**: 2026-09-08
- **Tipo**: Mejora del motor de alertas (`lib/services/alert_service.dart`)
- **Base**: análisis del motor actual (7 reglas) + decisión del dueño sobre el alcance
- **Alcance aprobado**: **A1** (R6 excluye pérdidas), **C** (R1 compara mismo mes del año previo), **B** (nueva alerta de ventas sin cantidad).

---

## 1. Problema

1. **R1 — gasto excesivo por mes**: comparar "este mes" contra el promedio de *todos los meses históricos* produce falsas alarmas en meses estacionales de café (fertilización, mano de obra). El café no gasta parejo todo el año.
2. **R6 — vendiste más de lo cosechado**: hoy `harvestedKg` suma **todas** las cosechas (vendido + almacenado + **pérdida**). Los kg perdidos respaldan ventas que no ocurrieron: inflan el "respaldo" y hacen la regla menos precisa.
3. **Ventas sin cantidad (ciego de R4 y R6)**: si una venta se registra sin `quantity`, aporta **0 kg**. R4 (precio bajo) y R6 (desfase) no tienen datos para evaluarla → falsos negativos silenciosos. No hay ninguna alerta que avise de este problema de registro.

## 2. Solución (3 cambios)

### A1 — R6: excluir cosechas con destino `pérdida`
En `_checkHarvestVsSales` (`alert_service.dart:355-361`), al acumular `harvestedByCrop`, **saltar** los registros con `destination == HarvestDestination.perdida`. Solo `vendido` + `almacenado` respaldan ventas. El umbral sigue siendo `soldKg > harvestedKg × 1.1` con ventana rolling de 12 meses.

### C — R1: comparar contra el mismo mes de años anteriores
En `_checkExcessiveSpending` (`alert_service.dart:56-78`), separar la historia así:
- **Baseline principal**: gastos de la misma categoría en el **mismo mes calendario** de años anteriores (`t.date.month == currentMonth && t.date.year != now.year`).
- Promedio mensual = total del mes-histórico ÷ nº de (año,mes) distintos (semántica vigente, restringida al mismo mes).
- **Fallback**: si el baseline del mismo mes tiene **< 2 meses-dato**, usar el promedio global actual (comportamiento de hoy) para no eliminar la regla en cuentas con < 2 años de datos.
- Umbral sin cambios: `current > 2 × avg`.

### B — Nueva regla INFO: ventas sin cantidad registrada
Nueva regla `_checkMissingQuantity` (nivel INFO, evalúa al abrir/registrar):
- Cuenta **ventas** (categoría `venta_*`, no eliminadas) en los **últimos 90 días** con `quantity == null || quantity <= 0`.
- Se dispara si hay **≥ 3** ventas así (umbral anti-ruido para cuentas donde el usuario llena kg a veces).
- Mensaje: cuántas ventas sin kg hay en el período + recordatorio de que sin cantidad no se puede verificar precio por kg ni desfases.
- Nuevo valor en enum `AlertRule` (`lib/models/farm_alert.dart:15-23`): `missingQuantity`.
- Respeta la regla de oro: **no** adivina la cantidad; solo avisa del dato faltante.

## 3. Decisiones confirmadas (con el dueño)

| Decisión | Valor |
|---|---|
| D4 — Alcance | Solo **A1 + C + B** (el trio recomendado). **A2** (ventana 24m/stock de campaña) y **D** (pérdida >10%) quedan fuera para otra iteración. |
| D5 — Umbral R1 | Se mantiene `2×`; cambia solo la base de comparación (mismo mes histórico + fallback). |
| D6 — Umbral B | ≥ 3 ventas sin cantidad en 90 días (INFO). Evita molestar por un olvido puntual. |
| D7 — A1 severidad | R6 sigue en `warning`; solo cambia qué cosechas respaldan ventas. Sin cambio de mensajes. |

## 4. Strings i18n (es/en)

- Nuevas: `alertMissingQtyTitle`, `alertMissingQtyMessage({count})`, `alertMissingQtySuggestion`.
- El resto de reglas **no cambia mensajes** (A1 y C son de lógica pura; se conservan títulos/mensajes actuales).

## 5. Tests

En `test/alert_service_test.dart` (TDD, rojo→verde):
- **A1**: cosechas `pérdida` no cuentan como respaldo; con solo pérdidas la R6 no dispara aunque haya ventas (sin inventario real); `vendido`+`almacenado` sí respaldan.
- **C**: mes con pico estacional recurrente (mismo mes 2 años) **no** dispara; gasto puntual 2× el mismo-mes-histórico sí dispara; fallback global si hay < 2 meses-dato del mismo mes.
- **B**: 3+ ventas sin cantidad en 90 días → alerta INFO `missingQuantity`; < 3 → no; ventas con cantidad → no; fuera de 90 días → no.
- Widget de alertas existente debe seguir pasando (regresión).

## 6. Criterios de aceptación

- **AC-1**: Una cosecha `pérdida` deja de sumar kg de respaldo en R6 (`soldKg` > `harvestedKg` de `vendido+almacenado` × 1.1 es la única condición).
- **AC-2**: R1 usa el mismo mes-calendario histórico como baseline y no dispara por estacionalidad recurrente; el fallback global mantiene la regla activa en cuentas con < 2 años.
- **AC-3**: Aparece la alerta INFO "ventas sin cantidad" cuando hay ≥ 3 ventas sin kg en 90 días, con contador en el mensaje.
- **AC-4**: `AlertRule` nuevo serializa correctamente y las alertas se renderizan con la severidad INFO en el Resumen.
- **AC-5**: i18n es/en regenerada (`flutter gen-l10n`), analyzer limpio, suite completa verde.

## 7. Riesgos

- **C cambia la sensibilidad**: con < 2 años de datos el fallback replica el comportamiento actual (bajo riesgo); con ≥ 2 años el mismo-mes es conservador por diseño. Revisable con los números en producción.
- **B puede enfocar a un problema de registro**: es INFO, no bloquea; umbral ≥3 evita ruido.
- **A1 reduce el "respaldo"** en cuentas con pérdidas: la alerta R6 puede sonar un poco más seguido, ahora con mayor precisión (las pérdidas no deben respaldar ventas).

## Firmas

- PRD aprobado por el usuario (2026-09-08): alcance A1 + C + B.
- `docs/plans/2026-09-08-alertas-coherencia-estacional.plan.md` se derivará de este PRD si se aprueba la implementación (ver regla PRD-first).