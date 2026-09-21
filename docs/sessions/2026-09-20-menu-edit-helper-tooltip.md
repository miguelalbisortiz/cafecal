# 2026-09-20 — Menú mejorado, edit visible, helper tooltip

## Summary

Tres mejoras de UX en una iteración:
1. **Menú de tres puntos** reordenado por frecuencia de uso + íconos visuales
2. **Edición visible** en historial (✏️ junto al 🗑️)
3. **Helper corto + tooltip ℹ️** en formularios de cultivo y siembra (10 campos)

## What happened

- `home_screen.dart`: Menú reordenado (Reporte → Cultivos → Siembras → Cosechas → Config → Ayuda → Salir), cada item con `ListTile` + ícono (`leading:`).
- `movements_screen.dart`: +`IconButton(edit_outlined)` en cada fila del historial. Toca ✏️ → `RegisterScreen(editing: t)`. Flujo existente (tap en fila) se mantiene.
- `crop_editor_dialog.dart`: 6 campos con helper corto + `Tooltip(info_outline)` (unidad, ciclo, fase, área, plantas, costo).
- `sowing_screen.dart`: 4 campos con helper corto + tooltip (plantas, perdidas, área, costo).
- ARB es/en: +11 strings (10 helper cortos + "edit"/"edit").

## State

| Item | Status |
|---|---|
| Tests | **170/170 verdes** |
| analyze | limpio |
| gh-pages | `ec33a67`, HTTP 200 |
| main | `9b0d747` |

## Key decisions (no revertir)

- Helper tooltip: texto corto visible + info completa en tooltip (ℹ️). No se pierde información.
- Edición en historial: ✏️ visible + tap en fila (doble vía de acceso).
- Menú: orden por frecuencia (Reporte primero, Salir último).

## Files

`lib/screens/home_screen.dart`, `lib/screens/movements_screen.dart`, `lib/widgets/crop_editor_dialog.dart`, `lib/screens/sowing_screen.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
