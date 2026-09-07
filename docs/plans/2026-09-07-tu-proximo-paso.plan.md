# Plan: Tarjeta "Tu próximo paso" (guía de primeros pasos en la app)

- **Fecha**: 2026-09-07
- **Tipo**: Implementación (feature UI de guía)
- **Objetivo**: guiar al usuario nuevo **dentro de la app** para que cargue los
  primeros datos en el orden correcto según su caso (cultivo → siembra según aplique →
  gastos → cosecha → venta), **sin ser invasivo ni complicarse después**: la tarjeta se
  **deriva del estado actual de los datos** (no guarda ningún estado propio) y
  **desaparece sola** cuando no quedan pasos pendientes.
- **Decisiones previas ya confirmadas por el usuario (Opción 1)**:
  - Nada de wizard modal obligatorio, nada de checklist fijo de N pasos eterno.
  - La app **detecta el caso por la fase del cultivo**, no pregunta "A/B".
  - **Enlace "Ver guía completa"**: fuera de alcance por ahora; dónde y cómo se expone
    la guía de primeros pasos (markdown/PDF en `docs/`) se decide más adelante, no en
    este plan.

---

## Problema que resuelve

Hoy un usuario nuevo entra al Home (dashboard) **sin saber por dónde empezar**:
- Si entra por modo invitado, `_seedDemoData` inyecta datos demo → el dashboard se ve
  "lleno" pero no refleja su finca.
- Los estados vacíos solo dicen "Aún no hay cultivos. Agrega el primero." (texto pasivo,
  sin paso siguiente, sin acción clara).
- No hay ningún onboarding ni guía dentro de la app; la guía completa es un documento
  externo que el usuario no sabe que existe.

## Solución: tarjeta derivada del estado

En el Home, antes de los resúmenes, se muestra una **tarjeta compacta** con:
- **Un solo "próximo paso"** (el más urgente según el estado), con botón que navega
  directo a la pantalla correcta (Cultivos / Siembras / Cosechas / Registrar).

**Cálculo del próximo paso (reglas en orden de prioridad):**

| # | Condición | Paso que muestra |
|---|---|---|
| 1 | `crops.isEmpty`, **o solo los 3 cultivos por defecto sin configurar y sin ningún dato** (ni gastos, ni siembras, ni cosechas) | "Crea tu primer cultivo" / "Configura tu primer cultivo" → **Cultivos** |
| 2 | Existe cultivo en `establecimiento` (o `renovacion`) sin ninguna siembra para ese cultivo | "Registra la siembra de {cultivo}" → **Siembras** |
| 3 | Existe cultivo (cualquier fase) y `transactions` sin gastos en el año | "Registra tus primeros gastos" → **Registrar (Gasto)** |
| 4 | Existe cultivo en `produccion` con gastos pero sin cosechas | "Registra tu primera cosecha" → **Cosechas** |
| 5 | Existe cosecha registrada pero no hay ventas (ingreso categoría venta) | "Registra la venta de tu cosecha" → **Registrar (Ingreso)** |
| — | Ninguna condición aplica | La tarjeta **no se muestra** |

**Reglas de negocio (para no complicar después):**
- **Sin estado guardado**: la tarjeta se calcula en cada build a partir de
  `TransactionProvider` (crops, sowings, harvests, transactions). No hay banderas,
  no hay "primerizos marcados", no hay nada que migrar ni desincronizar.
- **Reaparece sola si se borran datos**: si el usuario borra todo, el paso 1 revive.
  Nunca queda obsoleta.
- **No bloquea**: es una tarjeta en el scroll del Home; se puede ignorar. No es modal.
- **Un solo paso a la vez**: evita el muro de "haz 6 cosas". Muestra el más urgente.
- **Fase decide la guía** (caso A/B automático):
  - Cultivo nuevo en `establecimiento` → la app te lleva a la **siembra**.
  - Cultivo ya productivo (`produccion`) sin siembra → **no sugiere siembra** (finca
    establecida), salta a gastos/cosechas. La siembra no debe exigirse.
- **Arranque por el cultivo**: `loadCrops()` siembra siempre los 3 cultivos por
  defecto (Café/Plátano/Otro, en `produccion`), así que `crops` nunca está vacío en
  una cuenta nueva. Para que la guía no salte a "gastos", la regla 1 también aplica
  cuando los cultivos son **solo los por defecto, sin tocar** y **no hay ningún dato**
  (sin gastos, siembras ni cosechas) → el primer paso es revisar/configurar el
  cultivo. En cuanto hay algún dato o un cultivo configurado, siguen las reglas 2-5.
- **Respeto al demo**: si entró por modo invitado con datos demo (que ya vienen con
  cultivos, ventas y gastos), la tarjeta **no debería aparecer** salvo que falte algo
  real (ej. no hay cosechas). La condición del paso 4/5 lo cubre naturalmente.

## Impacto en infraestructura actual

- **GitHub Pages / Supabase**: sin cambios (es UI pura + texto i18n).
- **Local**: sin cambios de formato. Solo un widget nuevo + strings es/en.
- **Tests existentes**: intactos; se agregan tests del nuevo servicio de "próximo paso".

## Fases de trabajo

### Fase 1 — Lógica pura (`lib/services/next_step_service.dart`, nuevo)
- `enum NextStepType { crop, sowing, expenses, harvest, sale }`
- `class NextStep { NextStepType type; String? cropId; }` — el widget localiza títulos
  y etiquetas vía i18n según el tipo (y el nombre del cultivo para la siembra).
- `NextStep? nextStepFor({required List<Crop> crops, required List<Sowing> sowings,
  required List<Harvest> harvests, required List<Transaction> transactions,
  required int year})`
  implementa las reglas de prioridad de la tabla (pura, testeable, sin Flutter).
- Criterio de siembra: existe al menos un cultivo con `phase == establecimiento ||
  renovacion` que no tenga una `Sowing` propia (incluye `kind == siembra`; una
  `resiembra` sola no cubre).
- Criterio de gastos: `transactions` no contiene ningún gasto (`type == expense`) del año.
- Criterio de cosecha: hay gastos del año y `harvests` está vacío.
- Criterio de venta: hay ≥1 cosecha y ningún ingreso de categoría `venta_*` en el año.

### Fase 2 — Widget (`lib/widgets/next_step_card.dart`, nuevo)
- Tarjeta Material con ícono + título del paso + botón acción (CTA).
- `onPressed` navega a la pantalla correcta según `NextStepType`:
  - `crop` → `CropsScreen`, `sowing` → `SowingScreen`, `harvest` → `HarvestScreen`,
    `expenses` / `sale` → `RegisterScreen` (prefija tipo Gasto/Ingreso).
- Solo se renderiza si `nextStepFor(...)` retorna no-null.

### Fase 3 — Integración en Home (`lib/screens/home_screen.dart`)
- En `_buildDashboard`, `nextStep` computado desde el `TransactionProvider` del watch,
  renderizado **arriba** de `AlertsBanner` (el usuario ve la guía antes de los resúmenes).
- Estilo no invasivo (fondo de contenedor, sin bloquear scroll).

### Fase 4 — i18n + tests
- Strings es/en en `app_es.arb` / `app_en.arb` (+ regen).
- Tests de `next_step_service` (reglas en orden, caso A/B, reaparece al borrar, demo
  data no dispara siembra; 100% de casos de la tabla).
- Widget test de `NextStepCard` (render, navegación, oculto si no aplica).

## Criterios de aceptación (observables)

- **AC-1**: Cuenta nueva (sin cultivos, o solo los 3 por defecto sin datos) → la
  tarjeta muestra el paso de **cultivo** ("Crea tu primer cultivo" si está vacío,
  "Configura tu primer cultivo" si son los defaults) y navega a Cultivos.
- **AC-2**: Con un cultivo nuevo en `establecimiento` y sin siembras → la tarjeta
  muestra **"Registra la siembra de {cultivo}"** (no salta a gastos).
- **AC-3**: Con un cultivo en `produccion` y sin siembras → **no sugiere siembra**;
  si tampoco hay gastos del año, sugiere registrar gastos.
- **AC-4**: Con cultivo, gastos del año y `harvests` vacío → sugiere **"Registra tu
  primera cosecha"**.
- **AC-5**: Con cosecha y sin ventas → sugiere **"Registra la venta de tu cosecha"**.
- **AC-6**: Con cultivo, gastos, cosechas y ventas → la tarjeta **no se muestra**.
- **AC-7**: Al borrar todos los datos, la tarjeta revive con el paso 1 (sin estado
  guardado: derivada, no persistida).
- **AC-8**: La tarjeta muestra **un solo paso** a la vez, no un checklist.
- **AC-9**: El modo invitado con datos demo no genera pasos siembra falsos (los demo no
  tienen sowings pero el cultivo default está en `produccion` → regla 2 no aplica).
- **AC-10**: La tarjeta muestra **un solo paso a la vez** y navega a la pantalla
  correcta al pulsar el CTA (verificación por widget test).
- **AC-11**: `flutter analyze` sin issues; `flutter test` verde (91 actuales + nuevos).
- **AC-12**: Desplegado en GitHub Pages, HTTP 200, con i18n es/en correctos.

## Fuera de alcance (futuro)

- **Enlace "Ver guía completa"** dentro de la tarjeta: se decide más adelante dónde y
  cómo exponer la guía de primeros pasos — no forma parte de este plan.
- Wizard modal de bienvenida de 3-4 pasos (Opción 3) — no se hace hoy.
- Checklist "Primeros pasos" de 5 ítems (Opción 2) — riesgo de volverse obsoleta.
- Onboarding multi-pantalla tocando auth/signup. La tarjeta es 100 % UI derivada.