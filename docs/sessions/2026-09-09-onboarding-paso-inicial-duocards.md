# 2026-09-09 — Onboarding de primer paso (solo dos cards; app bloqueada hasta elegir)

## Summary

La cuenta nueva ya no ve el dashboard detrás de la bienvenida. Mientras no haya **ningún cultivo ni siembra**, lo único visible son dos cards grandes: **Registrar siembra** y **Registrar cultivo**. Elegir y completar cualquiera de las dos desbloquea el resto de la app (resumen, gastos/ingresos, historial). Gate simplificado a `crops.isEmpty && sowings.isEmpty`. PRD + plan + implementación TDD + deploy a GitHub Pages.

## State

| Item | Status |
|---|---|
| Tests | **162/162 verdes** (4 nuevos de gate, widget redesigned, 4 casos E2E) |
| analyze | limpio |
| main | `24696d9` (pusheado) |
| gh-pages | `b713a0d` (pusheado; base href `/cafecal/` verificado en producción) |

## Key decisions (no revertir)

- `needsOnboarding` = `crops.isEmpty && sowings.isEmpty` (antes exigía un cultivo en producción o siembra inicial). Ahora cualquier cultivo o siembra desbloquea.
- En modo onboarding el home **no** renderiza NavigationRail/BottomNavigationBar ni el dashboard: solo `WelcomeOnboardingCard` rediseñada (2 cards tappable → `CropsScreen` / `SowingScreen`).
- El menú del AppBar en modo onboarding solo muestra Ayuda / Configuración / Cerrar sesión (sin Reporte/Cultivos/Siembras/Cosechas). No existe opción "entrar sin configurar" (decisión del dueño).
- i18n: valores de `welcomeTitle/Subtitle/Existing*/New*` reescritos; regenerado con `gen-l10n`.
- Test de SummaryCard en dashboard usa sólo controles estructurales (`NavigationBar`/`NextStepCard`): el dashboard es un ListView lazy y las summary cards pueden quedar fuera del viewport.

## Pending

- [ ] Verificación manual en producción con cuenta vacía (recarga forzada; la PWA guarda la versión anterior).
- [ ] Bug pendiente separado: migración de datos legacy entre cuentas (`local_store.dart`): los datos del primer usuario se regalan a cualquier usuario nuevo que entre (`_migrateLegacyIfNeeded`). Pendiente `legacy_owner_v1` + test.
- [ ] Commit de este snapshot + LATEST en `main` (requiere consentimiento del usuario).

---

## Sesiones anteriores

- **2026-09-08 — Guía + pantalla de Ayuda claras**: gh-pages `671b66e`, main `1ac071d`.
- **2026-09-08 — Onboarding de bienvenida (cards con dos caminos) + fix deploy base href**: main `defdfb0`, gh-pages `88c9eb8` (roto) → `e4a3a93` (corregido).
- **2026-09-08 — Alertas A1/C/B + Fixes H1/H5/H3/H2**: gh-pages `6802f27`, main `dd7279c`.