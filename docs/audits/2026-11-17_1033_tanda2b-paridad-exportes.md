---
tanda: 2B
fecha: 2026-11-17_1033
veredicto: PASS
reporte: docs/reports/2026-11-17_1033_tanda2b-paridad-exportes.md
---

# Auditoría · Tanda 2B

| Criterio aprobado | Evidencia | Resultado |
|---|---|---|
| Helper compartido para la regla del período | `report_period_records.dart` lo usan `report_screen.dart`, `pdf_export_service.dart` y `excel_export_service.dart`; test de borrados y mes anterior | PASS |
| Misma conclusión en los tres pintadores | Un solo `ReportInsightsService` en los tres; test compara cada frase (y sus cifras) en PDF y Excel | PASS |
| Conclusión en Resumen de Excel y cuerpo del PDF | `_summarySheet` tras los formatos de moneda; `_insightsSection` entre nota mixta y compradores | PASS |
| «Qué hacer» vacío visible en el PDF | `_recommendationsSection` pinta `reportNoRecommendations` con el título; test del PDF sin datos | PASS |
| Compradores y proveedores top 3 en Resumen | `TopAccounts.from(periodTx)` con `topClients(3)` / `topProviders(3)`; test con nombres reales y fila borrada ausente | PASS |
| Sin cifras inventadas con moneda mixta | `mixedTotals` se pasa al motor; cuentas mixtas se listan moneda por moneda; effective currency es la del período | PASS |
| Guardas de páginas revisadas con motivo escrito | 4 páginas sin cambio; plantilla `pdf_export_test.dart` de 1 página sin anexo sin cambio; comentario en el plan | PASS |
| Sin regresión | analyze limpio; 47/47 targeted; 1433/1433 suite completa | PASS |
| TDD | 4/4 tests en rojo antes de la implementación (stub + 3 aserciones) | PASS |

## Seguridad y disciplina

- Sin secretos ni credenciales en los archivos tocados.
- Sin `DROP`/`DELETE` sin WHERE, sin `rm -rf`, sin cambios de `package.json`
  ni `.env`.
- Sin commit ni push: no se pidió en este turno.
- No se agregaron dependencias ni permisos.
- No se modificaron ARB ni archivos generados: solo se reutilizaron claves ya
  existentes.

## Observaciones (no bloqueantes)

1. El PDF vuelve a pintar el título «Qué hacer» aun sin recomendaciones; es
   necesario para que `reportNoRecommendations` tenga contexto y coincide con
   pantalla y Excel.
2. `previousMonthRecordsForPeriod` reproduce la regla vieja de la pantalla
   (semana 52 del año anterior) en vez de la de `previousPeriodWindow` (restar
   7 días). Se eligió la de la pantalla para no cambiar la conclusión que ya
   veía el usuario; ambas coinciden salvo en años con semana 53.
3. La moneda efectiva se calcula aparte para la conclusión; el resto de los
   totales del exporte conserva su moneda histórica. Con mezcla el motor no
   emite frases de dinero, así que no hay contradicción.
4. Tanda 2C y Tanda 3 siguen pendientes; Tanda 3 exige PRD aprobado.

**Veredicto: PASS.**
