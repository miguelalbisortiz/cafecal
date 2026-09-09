# Plan: Onboarding "primer paso" — elegir siembra o cultivo, sin resto de la app

- **Fecha**: 2026-09-09
- **Fuente**: `docs/prds/2026-09-09-onboarding-paso-inicial-duocards.prd.md`

## Tareas (orden)

1. [T1] Cambiar gate en `lib/services/next_step_service.dart` → `needsOnboarding = crops.isEmpty && sowings.isEmpty`.
2. [T2] Rediseñar `lib/widgets/welcome_onboarding_card.dart` → dos cards grandes (`Registrar siembra` / `Registrar cultivo`), cada una navegable completa.
3. [T3] i18n: strings nuevos (heading + títulos/subtítulos de las dos cards) en `lib/l10n/strings.dart` (es/en) y `flutter gen-l10n`.
4. [T4] `lib/screens/home_screen.dart`: en modo onboarding → sin NavigationRail/NavigationBar, body = solo la vista de bienvenida (dos cards); menú del AppBar sin items de datos (report/crops/sowings/harvests), conservando help/settings/logout. Con finca desbloqueada → comportamiento actual intacto (incl. `NextStepCard`).
5. [T5] Tests (rojo→verde): `next_step_service_test.dart` (nuevo gate), `welcome_onboarding_card_test.dart` (nuevo diseño), `onboarding_flow_test.dart` (bloqueado sin resumen/nav; caminos A y B; volver sin completar sigue bloqueado).
6. [T6] Verificar: `flutter analyze`, suite completa verde, build web.

## Verificación
- `flutter analyze` y `flutter test` (suite completa).
- `flutter build web --release --base-href=/cafecal/` + deploy a `gh-pages` (receta en `docs/sessions/LATEST.md`).
- Smoke manual con cuenta vacía en `https://miguelalbisortiz.github.io/cafecal/`.