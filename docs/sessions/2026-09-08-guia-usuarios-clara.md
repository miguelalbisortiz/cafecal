# 2026-09-08 — Guía + pantalla de Ayuda claras para usuarios sin experiencia

## Summary

Se reescribió la guía de primeros pasos y la pantalla "Ayuda" dentro de la app con lenguaje simple para usuarios que no saben de cosecha, siembra ni cultivo. Todo desplegado y verificado.

## What happened

1. **Guía markdown reescrita** (`docs/guides/mi-cafetal-primeros-pasos.md`): mapa de la app, glosario con términos de la vida real (arroba, saco, ROI, balance...), flujo de 5 pasos, casos A/B con ejemplos con números, unidades, panel por hectárea, alertas, errores comunes, glosario rápido.
2. **Pantalla de Ayuda de la app** (`lib/screens/help_screen.dart` + `lib/l10n/app_es.arb`, `app_en.arb`):
   - Textos reescritos en lenguaje claro.
   - Nueva sección "El orden de la app" (flujo visual con iconos).
   - Nueva sección "Errores comunes" con parejas problema → solución correctas (se corrigió emparejamiento roto + typo "Miseria en el monto").
   - Ejemplos con números en los casos A y B (widget `_CaseExample`).
   - Tabla de equivalencias de unidades (widget `_MiniTable`).
3. **Despliegues**:
   - `main`: `80a51ea` (reescritura), `3955f3e` (tablas markdown + errores emparejados), `1ac071d` (ejemplos/equivalencias en pantalla).
   - `gh-pages`: `b4a3d17`, `b3faee6`, `671b66e`.
4. **Verificación**: `flutter analyze` limpio, **150/150 tests**, build web release con credenciales de `.env`.

## State

| Item | Status |
|---|---|
| Tests | **150/150 verdes** |
| analyze | limpio |
| gh-pages | `671b66e` |
| main | `1ac071d` |

## Key decisions (no revertir)

- La pantalla de Ayuda es Flutter (no renderiza markdown): mantiene el contenido en strings l10n, no duplicar contenido en markdown.
- Los widgets `_CaseExample` y `_MiniTable` de `help_screen.dart` reutilizan el patrón `_DefList` (título bold + cuerpo muted).
- Worktree de deploy roto (`_deploy` sin `.git`): se despliega con worktree temporal en temp (`--base-href=/cafecal/`), no usar `_deploy`.

## Pending

- [ ] Verificación manual en producción: abrir Ayuda, recarga forzada (PWA cachea versión anterior).