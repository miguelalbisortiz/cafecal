# 2026-09-09 — Onboarding de primer paso (solo dos cards; app bloqueada hasta elegir)

## Summary

Con la finca vacía (0 cultivos y 0 siembras), lo único visible son dos cards (**Registrar siembra** / **Registrar cultivo**); completar cualquiera desbloquea el resto. Gate = `crops.isEmpty && sowings.isEmpty`. PRD + plan + TDD (162/162) + deploy.

| Item | Status |
|---|---|
| Tests | **162/162 verdes** |
| analyze | limpio |
| main | `24696d9` |
| gh-pages | `b713a0d` (base href `/cafecal/` verificado) |

## Pending

- [ ] Verificación manual con cuenta vacía en producción.
- [ ] Bug separado: migración de datos legacy entre cuentas (`local_store.dart` `_migrateLegacyIfNeeded`). Pendiente `legacy_owner_v1` + test.
- [ ] Commit de este snapshot + LATEST en `main` (requiere consentimiento).

Detalle completo: `docs/sessions/2026-09-09-onboarding-paso-inicial-duocards.md`.

---

## Sesiones anteriores

- **2026-09-08 — Guía + pantalla de Ayuda claras para usuarios sin experiencia**: se reescribió la guía de primeros pasos y la pantalla "Ayuda" dentro de la app con lenguaje simple. Desplegado en `gh-pages` (`671b66e`), commiteado en `main` (`1ac071d`). Suite **150/150 tests**, analyze limpio.
- **2026-09-08 — Onboarding de bienvenida (cards con dos caminos) + fix deploy base href**: main `defdfb0`, gh-pages `88c9eb8` (roto `<base href="/">`) → `e4a3a93` (corregido con `--base-href=/cafecal/`).
- **2026-09-08 — Alertas A1/C/B + Fixes H1/H5/H3/H2**: 4 fixes de auditoría desplegados, 150/150 tests, gh-pages `6802f27`, main `dd7279c`.