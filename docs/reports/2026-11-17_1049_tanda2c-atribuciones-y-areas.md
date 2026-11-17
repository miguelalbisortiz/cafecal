---
tanda: 2C
fecha: 2026-11-17_1049
scope: rotular las dos atribuciones y verificar el aviso de áreas
resultado: PASS
---

# Reporte · Tanda 2C — atribuciones y áreas

## Objetivo

Que agricultor no compare dos cifras con reglas distintas como si fueran la
misma. El desglose por cultivo y el costo por kilo **sí reparten** por hectáreas
cuando todas las áreas están medidas; el «Aporte por producto» **no reparte**:
deja el gasto de lote y el común aparte. Además, verificar que el aviso de áreas
que se pasan del terreno existe, es no bloqueante y no corrige el dato.

## Decisiones aprobadas por el usuario

1. **Corregir el copy** de `contributionSubtitle`: decir que el aporte *no*
   reparte, en vez de afirmar lo contrario. La guarda `cultivos_copy_test.dart`
   defendía el texto viejo y se actualizó al verdadero.
2. **Clave corta nueva en los tres pintadores** para rotular el desglose:
   `cropBreakdownSplitNote`, pintada en pantalla, PDF y Excel junto a la nota de
   cultivos asociados. Texto corto a propósito para no mover la paginación.
3. **Verificar 2.4 sin código nuevo**: `terreno_area.dart` + banner ámbar ya
   cumplen la aceptación. Cero código nuevo, solo documentación y tests de guarda.

## TDD: rojo real antes del arreglo

`flutter test test/attribution_labels_test.dart test/cultivos_copy_test.dart`
antes de tocar producción falló en **6/6 tests**:

- `NoSuchMethodError: Class 'AppLocalizationsEs' has no instance getter
  'cropBreakdownSplitNote'` en la aserción dinámica y en los tres pintadores.
- `cultivos_copy_test.dart` ES/EN fallaban porque el subtítulo decía
  «se reparte» / «are split», justo lo contrario de lo que hace el código.

El acceso a la clave nueva se hizo con `(l10n as dynamic)` para que el rojo
fuera de aserción y no de compilación de los demás tests.

## Cambios

| Archivo | Cambio |
|---|---|
| `lib/l10n/app_es.arb` | `contributionSubtitle` corregido a «este aporte no reparte»; `cropBreakdownSplitNote` nueva: «Aquí se reparte por hectáreas; si falta un área, ese gasto sale aparte.» |
| `lib/l10n/app_en.arb` | `contributionSubtitle` corregido a «does not split them»; `cropBreakdownSplitNote` nueva: «Here costs are split by hectares; if an area is missing, that cost shows separately.» |
| `lib/l10n/generated/app_localizations*.dart` | Regenerados con `flutter gen-l10n` y normalizados de CRLF a LF. |
| `lib/screens/report_screen.dart` | Pinta `cropBreakdownSplitNote` tras la nota de cultivos asociados en el desglose. |
| `lib/services/pdf_export_service.dart` | Misma clave en el bloque de desglose del PDF, con estilo y tamaño corto. |
| `lib/services/excel_export_service.dart` | Misma clave en la hoja «Por cultivo» del Excel. |
| `test/attribution_labels_test.dart` (nuevo) | 4 guardas: ARB y generado, pantalla, Excel y PDF. |
| `test/cultivos_copy_test.dart` | Guarda del subtítulo invertida: exige «no reparte» / «does not split» y prohíbe el texto viejo. |

**No se tocó** `crop_totals.dart` ni `product_contribution.dart`: el cálculo ya
era correcto y distinto. Esta tanda es solo copy y rotulado.

## Reglas respetadas

- **Los tres pintadores dicen lo mismo**: la clave nueva se pinta en pantalla,
  PDF y Excel; el test lo comprueba en los tres.
- **`null` → oculto**: no se inventa área ni gasto; la nota solo aclara la regla.
- **Sin cifras nuevas**: no se calcula nada, solo se nombra la regla ya vigente.
- **Sin bloquear**: el aviso de áreas sigue siendo ámbar e informativo.

## Paginación del PDF

Se revisó el conteo congelado el 2026-11-17 10:49. **No cambia: 4 páginas** en
el fixture de `export_parity_test.dart`. La clave nueva es una línea corta dentro
del bloque existente, así que no se añadió salto de página ni se tocó la guarda
de 1 página sin anexo de `pdf_export_test.dart`. Al no cambiar el número, no se
modificaron los comentarios de fecha/motivo de esas constantes.

## Verificación

| Puerta | Resultado |
|---|---|
| `flutter analyze` (proyecto entero) | **No issues found** |
| Rojo previo | **6/6 tests fallaron** antes del arreglo |
| Targeted: `attribution_labels_test` + `cultivos_copy_test` + `associated_crops_cost_note_test` | **20/20** |
| `flutter test` suite completa | **1437/1437** (1433 anteriores + 4 nuevos) |
| 2.4: `terreno_area_test` + `l10n_tanda4_test` + `terrenos_test` | **63/63** |
| `git diff --check` | limpio |
| Fin de línea de `lib/l10n/generated/` | LF en los 3 archivos (CRLF de `gen-l10n` normalizado) |

Ruido conocido y no bloqueante: `Unable to find a font to draw "☕"` / `"👷"` en
tests de PDF.

## Estado

- Sin commit ni push: no hubo verbo explícito en este turno.
- Plan actualizado con `tanda2c: DONE 2026-11-17_1049`.
- **Tanda 2 cerrada en código**. Queda pendiente la prueba manual con datos de
  finca real (10 ha, 3 cultivos, 4 trabajadores) del gate de la Tanda 2.
- Siguiente: Tanda 3, con PRD obligatorio antes de tocar stock, margen,
  comprador, descuento, caja y brecha de rendimiento.
