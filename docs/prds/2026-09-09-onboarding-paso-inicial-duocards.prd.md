# PRD: Onboarding "primer paso" — elegir siembra o cultivo, sin resto de la app

- **Fecha**: 2026-09-09
- **Tipo**: Rediseño del onboarding de bienvenida (`home_screen.dart` + `welcome_onboarding_card.dart` + `next_step_service.dart`)
- **Base**: el onboarding actual (gate `needsOnboarding`) muestra las dos cards pero **también** el resumen/dashboard debajo; el dueño quiere que mientras no se elija un camino inicial, **nada más** sea visible (ni gastos/ingresos, ni historial, ni resumen).

---

## 1. Problema

Hoy, una finca vacía ve la card de bienvenida y, **debajo**, el resumen y el acceso a gastos/ingresos/historial (`home_screen.dart:247-260`). El dueño quiere el primer uso de la app guiado 100%:

1. Al empezar, **lo único** visible son dos cards separadas: `Registrar siembra` y `Registrar cultivo`.
2. Elegir el primer paso destraba el resto de la app (resumen, gastos/ingresos, historial).
3. No existe la opción "entrar sin configurar": las dos cards son obligatorias hasta completar una de ellas.
4. Si entra al flujo y vuelve atrás sin completar, sigue bloqueado (no aparece el dashboard).

## 2. Solución (2 cambios)

### S1 — Gate más simple en `needsOnboarding`
En `lib/services/next_step_service.dart:38-45`, el gate pasa a:

```dart
bool needsOnboarding(List<Crop> crops, List<Sowing> sowings) =>
    crops.isEmpty && sowings.isEmpty;
```

- **Desbloquea** con **≥1 cultivo O ≥1 siembra** (cualquiera de los dos caminos).
- Ya **no exige** `produccion` ni siembra de tipo `siembra`: el "primer paso" es simplemente empezar a usar la app.

### S2 — Home en modo onboarding muestra SOLO las dos cards
En `lib/screens/home_screen.dart`, mientras `needsOnboarding` **no se renderiza el dashboard** (resumen, acceso a gastos/ingresos, historial). La vista queda:

```
┌───────────────────────────────────────┐
│  ☕ Mi Cafetal                        │
│   Bienvenido                          │
│   Elegí cómo querés empezar a usar    │
│   la app:                             │
│   ┌─────────────────────────────────┐ │
│   │  🌱  REGISTRAR SIEMBRA          │ │
│   │      Empezar por la siembra     │ │
│   └─────────────────────────────────┘ │
│   ┌─────────────────────────────────┐ │
│   │  🧑🌾  REGISTRAR CULTIVO        │ │
│   │      Empezar por un cultivo     │ │
│   └─────────────────────────────────┘ │
│   (sin resumen, sin gastos, sin       │
│    historial, sin "entrar sin         │
│    configurar")                       │
└───────────────────────────────────────┘
```

- `Registrar siembra` → navega a `SowingScreen` (que crea el cultivo al vuelo con el costo de siembra opcional).
- `Registrar cultivo` → navega a `CropsScreen` (crea el primer cultivo).
- Al completar cualquiera de las dos, `needsOnboarding` vuelve `false`, las cards desaparecen y se muestra el home normal (con `NextStepCard` si aplica).

## 3. Decisiones confirmadas (con el dueño)

| Decisión | Valor |
|---|---|
| D1 — Gate | `crops.isEmpty && sowings.isEmpty`; un cultivo o una siembra destraban. |
| D2 — Sin "entrar sin configurar" | Las dos cards son obligatorias; el usuario lo confirmó explícitamente. |
| D3 — Ocultamiento | Mientras `needsOnboarding`, **no** se muestra resumen, registro de gastos/ingresos, historial, ni acceso a otras secciones. |
| D4 — Cards separadas | Dos cards grandes independientes (siembra / cultivo); se reemplaza el layout actual de la card de bienvenida integrada. |
| D5 — Desbloqueo persistente | Una vez desbloqueado no vuelve a aparecer (salvo que la finca vuelva a quedar vacía). |

## 4. Strings i18n (es/en)

- Revisar/reusar los del bloqueo actual: título "Bienvenido", subtítulos, y títulos de las dos cards (`Registrar siembra` / `Registrar cultivo`) con sus descripciones.
- Si faltan variantes (p. ej. "Elegí cómo querés empezar"), agregarlas y regenerar (`flutter gen-l10n`).

## 5. Tests (TDD, rojo→verde)

- `test/next_step_service_test.dart`: nuevo gate — `crops.isEmpty && sowings.isEmpty` → onboarding; 1 cultivo (aunque sea en producción) → off; 1 siembra sin cultivos → off; ambos vacíos con gastos → on.
- `test/onboarding_flow_test.dart` (rework):
  - Estado bloqueado: el home **no muestra** el resumen ni los accesos a gastos/ingresos/historial, solo las dos cards.
  - Camino A (cultivo): crear el primer cultivo → vuelve con dashboard completo y sin las cards.
  - Camino B (siembra): registrar siembra con costo → desbloquea dashboard; gasto `siembra` vinculado.
  - Volver atrás sin completar (BackButton) → sigue bloqueado (solo cards).
- Widget test existente de `WelcomeOnboardingCard` adaptado al nuevo diseño de dos cards.
- Regresión: home con finca desbloqueada sigue igual (incluye `NextStepCard`).

## 6. Criterios de aceptación

- **AC-1**: Con 0 cultivos y 0 siembras, el home muestra **solo** las dos cards; no hay resumen, "registrar gasto/ingreso", historial ni "entrar sin configurar".
- **AC-2**: Elegir `Registrar siembra` y completar → dashboard completo visible, cards fuera.
- **AC-3**: Elegir `Registrar cultivo` y crear el primero → dashboard completo visible, cards fuera.
- **AC-4**: Entrar a un flujo y volver atrás sin completar → sigue bloqueado (solo cards).
- **AC-5**: El gate se desactiva con **un** cultivo **o** una siembra (sin exigir `produccion`).
- **AC-6**: `flutter analyze` limpio, suite completa verde, l10n regenerada.
- **AC-7**: Deploy a GitHub Pages verificado con cuenta nueva: aparece solo la vista de las dos cards; tras seguir un camino, aparece el dashboard.

## 7. Riesgos

- **Cambio de gate**: usuarios con una siembra pero sin cultivos verán la app desbloqueada; la siembra crea el cultivo al vuelo, así que en la práctica no debería existir ese estado inconsistente.
- **Regresión del resumen**: se toca el render condicional del home; hay que verificar que con finca desbloqueada el dashboard y el `NextStepCard` siguen exactamente igual.
- **Fuera de alcance**: el bug de migración de datos legacy entre cuentas (`local_store.dart` `legacy_owner`) se trata por separado, no en este PRD.

## Firmas

- PRD aprobado por el usuario (2026-09-09): confirmó el layout textual de las dos cards y descartó la opción "entrar sin configurar".
- `docs/plans/2026-09-09-onboarding-paso-inicial-duocards.plan.md` se derivará de este PRD si se aprueba la implementación.