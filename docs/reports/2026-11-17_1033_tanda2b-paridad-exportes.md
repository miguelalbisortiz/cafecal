---
tanda: 2B
fecha: 2026-11-17_1033
scope: paridad de conclusión, recomendaciones y compradores en pantalla/PDF/Excel
resultado: PASS
---

# Reporte · Tanda 2B — paridad de los tres pintadores

## Objetivo

Que el PDF y el Excel digan **exactamente lo mismo** que la pantalla de
Reportes en tres secciones: la conclusión del período, «Qué hacer» (incluido
su estado vacío) y «Principales compradores / proveedores». Ninguna cifra se
inventa: las tres fuentes leen los mismos registros y el mismo motor.

## Decisiones aprobadas por el usuario

1. **Extraer un helper compartido** para la selección de registros del período,
   en vez de derivarla en cada exportador o de pasar texto ya formateado.
2. **Conclusión en Resumen (Excel) y cuerpo del PDF**, entre la nota de moneda
   mixta y «Principales compradores», antes del anexo de nómina.
3. **Compradores y proveedores top 3 como bloque en el Resumen** del Excel,
   con los mismos títulos que el PDF.

## TDD: rojo real antes del arreglo

`flutter test test/report_parity_tanda2b_test.dart` antes de tocar producción
falló en **4/4 tests**:

- Helper de período sin implementar (`UnimplementedError`) — 2 tests.
- Excel Resumen sin `topClientsTitle` / `topProvidersTitle` ni nombres reales.
- PDF sin `reportNoRecommendations`: el texto decía «Qué hacer» con lista
  vacía, sin avisar de que no hay recomendaciones.

El stub de `report_period_records.dart` se escribió solo para que el rojo
fuera de aserción y no de compilación; se sustituyó por la regla real después.

## Cambios

| Archivo | Cambio |
|---|---|
| `lib/services/report_period_records.dart` (nuevo) | `recordsForPeriod` y `previousMonthRecordsForPeriod`. Misma regla que la pantalla: semana ISO (con salto de diciembre), mes, año y año a la fecha; borrados excluidos. |
| `lib/screens/report_screen.dart` | `_recordsFor` / `_previousMonthRecords` delegan en el helper. Desaparecen los switches privados duplicados (66 → 40 líneas en esos métodos). |
| `lib/services/pdf_export_service.dart` | Usa el helper para `periodTx`; calcula la conclusión con `ReportInsightsService`; nuevo `_insightsSection` entre la nota mixta y `_topAccounts`; `_recommendationsSection` pinta `reportNoRecommendations` cuando no hay avisos. |
| `lib/services/excel_export_service.dart` | Usa el helper para `periodTx`; calcula la misma conclusión; `_summarySheet` recibe `insights` y los pinta tras los formatos de moneda; bloque de compradores/proveedores top 3 tras el aporte por producto y antes del anexo de ubicación. |
| `test/report_parity_tanda2b_test.dart` (nuevo) | 4 guardas: regla compartida con borrados, conclusión idéntica en PDF y Excel, compradores reales en Resumen, vacío de recomendaciones en PDF. |

## Reglas respetadas

- **Moneda:** los insights con dinero usan la moneda efectiva del período, la
  misma que la pantalla; con mezcla, el motor ya calla esas frases. Los montos
  de compradores/proveedores se imprimen por moneda cuando una cuenta mezcla,
  nunca como suma cruzada.
- **Guardas:** la conclusión y el bloque de cuentas se ocultan si no hay datos,
  igual que en pantalla. `null` sigue siendo oculto, nunca un cero inventado.
- **Textos:** solo claves ARB existentes (`insightsTitle`,
  `reportNoRecommendations`, `topClientsTitle`, `topProvidersTitle`). No se
  tocó ningún ARB ni archivo generado.

## Paginación del PDF

Se revisó el conteo congelado el 2026-11-17 10:33. **No cambia: 4 páginas** en
el fixture de `export_parity_test.dart`; las secciones nuevas caben en la
paginación actual y no se añade ningún salto. Tampoco cambia la guarda de 1
página sin anexo de `pdf_export_test.dart`. Al no cambiar el número, no se
modificaron los comentarios de fecha/motivo de esas constantes.

## Verificación

| Puerta | Resultado |
|---|---|
| `flutter analyze` (proyecto entero) | **No issues found** |
| `flutter test test/report_parity_tanda2b_test.dart` | **4/4** |
| Targeted: `export_parity_test` + `pdf_export_test` + `excel_export_service_test` + `evaluacion_unificada_export_test` | **47/47** |
| `flutter test` suite completa | **1433/1433** (1429 anteriores + 4 nuevos) |
| `git diff --check` | limpio |
| Fin de línea de los archivos tocados | LF en todos (sin CRLF nuevo) |

Ruido conocido y no bloqueante: `Unable to find a font to draw "☕"` en tests
de PDF.

## Estado

- Sin commit ni push: no hubo verbo explícito en este turno.
- Plan actualizado con `tanda2b: DONE 2026-11-17_1033`.
- Pendiente: Tanda 2C (rótulos de atribución y aviso no bloqueante de áreas) y
  Tanda 3 (PRD antes de stock, margen, comprador, descuento, caja y brecha de
  rendimiento).
