---
tanda: 2A
fecha: 2026-11-17_1015
scope: altas cortas con contexto y descarte por cultivo
resultado: PASS
---

# Reporte · Tanda 2A — altas cortas con contexto

## Objetivo

Que Registro, Siembras y Asignar dejen de crear cultivos con solo nombre:
ofrezcan **lote, área y unidad** como opcionales en el mismo alta corta, y que
«Ahora no» del aviso de completar datos **posponga por cultivo** en vez de
silenciar la app para siempre.

## TDD: rojo real antes del arreglo

`flutter test test/quick_add_context_test.dart` antes de tocar producción falló
en compilación con 9 errores, todos esperados:

- `NewCropDialog.terrenos` no existía.
- `NewCropResult.terrenoId`, `.areaHa` y `.defaultUnit` no existían.
- `CropSetupPrompt.canAsk()` / `markDismissed()` no aceptaban `cropId` (5
  errores).

Ese fue el rojo; recién después se escribió la implementación.

## Cambios

| Archivo | Cambio |
|---|---|
| `lib/widgets/new_crop_dialog.dart` | `NewCropResult` gana `terrenoId`, `areaHa`, `defaultUnit`. El diálogo ofrece lote (si hay), área y unidad, todos opcionales; valida área positiva con `,` o `.`; elige "crear otro igual" conservando el contexto, "usar el existente" no. |
| `lib/widgets/crop_units.dart` (nuevo) | Lista y etiquetas de unidades en un solo lugar, para que alta corta y editor completo no diverjan. |
| `lib/widgets/crop_editor_dialog.dart` | Usa el helper compartido; sin cambio de comportamiento. |
| `lib/widgets/crop_setup_prompt.dart` | Descarte por `crop.id` en una lista `crop_setup_prompt_dismissed_v2`. La clave global vieja `..._v1` se deja de leer: no se migra ni se honra. |
| `lib/screens/register_screen.dart` | Pasa `tx.terrenos` al diálogo y guarda los tres campos en `addCrop`. |
| `lib/screens/sowing_screen.dart` | Igual en `_SowingForm._onCropChanged`. |
| `lib/screens/assign_crops_screen.dart` | Igual en `_onSelect`. |
| `lib/l10n/app_es.arb`, `app_en.arb` | `cropAreaInvalid`, `quickAddOptionalHelp`. |
| `lib/l10n/generated/` | Regenerado con `flutter gen-l10n` y normalizado a LF. |
| `.github/workflows/ci.yaml` (nuevo) | CI de Flutter 3.24.0: `pub get`, `analyze`, `test` en push/PR a `main` y `workflow_dispatch`. |

## Decisiones

1. **Opcionales de verdad.** Vacío → `null`, nunca `0` ni un lote inventado.
   Si no hay terrenos creados, el desplegable ni aparece.
2. **El contexto es del cultivo nuevo, no del existente.** Si el productor
   elige "usar el que ya tengo", no se le pisan sus datos con lo que escribió
   en el alta corta.
3. **"Ahora no" por cultivo.** Un id descartado no se repregunta; otro cultivo
   sí. La preferencia global vieja se ignora porque convertía un "ahora no"
   puntual en silencio permanente.
4. **Sin fricción extra en el registro.** El movimiento sigue con la regla de
   exclusividad cultivo/lote que ya tenía; el contexto se guarda en el cultivo.
5. **Unidades en una sola casa.** El alta corta y el editor muestran las mismas
   opciones y los mismos rótulos traducidos.

## Verificación

| Puerta | Resultado |
|---|---|
| `flutter analyze` (proyecto entero) | **No issues found** |
| `flutter test test/quick_add_context_test.dart` | **4/4** |
| `flutter test` targeted (duplicados + cultivos + registro + asignar + puertas cortas) | **71/71** |
| `flutter test` suite completa | **1429/1429** |
| ARB ES/EN + generado contienen las claves nuevas | Sí |
| `lib/l10n/generated/` sin CRLF | Sí (3 archivos) |

Ruido conocido y no bloqueante: `Unable to find a font to draw "☕"` en algún
test de PDF.

## Estado

- Sin commit ni push: no hubo verbo explícito en este turno.
- CI creado pero **sin validación remota** (no se ejecutó en GitHub).
- Pendiente: Tanda 2B (conclusión en PDF/Excel, PDF vacío, compradores en
  Excel), Tanda 2C (rótulos de atribución y aviso de áreas) y Tanda 3 (PRD).
