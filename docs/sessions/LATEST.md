# 2026-09-08 — Guía + pantalla de Ayuda claras para usuarios sin experiencia

## Summary

Se reescribió la guía de primeros pasos y la pantalla "Ayuda" dentro de la app con lenguaje simple para usuarios que no saben de cosecha, siembra ni cultivo. Desplegado en `gh-pages` (`671b66e`), commiteado en `main` (`1ac071d`). Suite **150/150 tests**, analyze limpio.

## State

| Item | Status |
|---|---|
| Tests | **150/150 verdes** |
| analyze | limpio |
| gh-pages | `671b66e` |
| main | `1ac071d` |

## Key decisions (no revertir)

- La pantalla de Ayuda es Flutter (no renderiza markdown): el contenido vive en strings l10n, no en markdown.
- Worktree de deploy roto (`_deploy` sin `.git`): desplegar con worktree temporal en temp, `--base-href=/cafecal/`.

## Pending

- [ ] Verificación manual en producción: abrir Ayuda, recarga forzada (PWA cachea versión anterior).

---

## Sesiones anteriores

- **2026-09-08 — Alertas A1/C/B + Fixes H1/H5/H3/H2**: 4 fixes de auditoría desplegados, 150/150 tests, gh-pages `6802f27`, main `dd7279c`.