---
status: DONE  <!-- F1-F6 hechas · F5 y F6 verificadas 2026-10-17 -->
created: 2026-10-08
last_updated: 2026-10-17
start_date: 2026-10-09  <!-- "mañana empezamos" (usuario, 2026-10-08) -->
---

# Plan: coherencia del ciclo cultivo → siembra → cosecha → venta

> **Documento de TRABAJO.** Guardado para arrancar el 2026-10-09.
> Regla de oro del proyecto: el usuario **ANALIZA y decide juntos** antes de tocar código
> en toda decisión de UI o comportamiento.

## Objetivo

Dejar el ciclo **cultivo → siembra → cosecha → venta** coherente con la práctica real de
caficultores pequeños que **venden todo lo que cosechan y no almacenan nada**, cerrando
cuatro trampas de doble registro descubiertas en el análisis y agregando edad del café.

Base empírica: el usuario compartió **su sistema de papel real** (menú de 17 líneas +
hoja semanal L-M-M-J-V-S-D). Ese papel marca el eje contable: **producto y categoría de
gasto, con ritmo semanal** — no lote con nombre.

## Estado

- [x] Análisis del flujo cultivo↔siembra → hallazgos **A–G**
- [x] Opinión "como caficultor" contrastada con su sistema de papel
- [x] Análisis de **0-A, 0-B, C1, C2** desde la práctica
- [x] Plan de trabajo elaborado y entregado
- [x] **Plan guardado en disco** (2026-10-08)
- [x] **Gate 0** — confirmado 2026-10-09: 0-A ✔ · 0-B ✔ · C1 ✔ · C2 ✔ (las 4 recomendaciones)
- [x] **F1** — cosecha → venta + B1 (2026-10-09) · analyze limpio · **470/470** (12 nuevos)
- [x] **F2** — costo en la resiembra (2026-10-09) · analyze limpio · **473/473** (3 nuevos)
- [x] **F3** — Inversión total (2026-10-09) · analyze limpio · **482/482** (9 nuevos)
- [x] **F4** — Pérdida sin plantar (2026-10-17) · analyze limpio · **934/934** (1 nuevo: el cableado)
- [x] **F5** — Fecha, fase y edad (commit `fa5e282`) · verificado 2026-10-17
- [x] **F6** — Saco configurable (commit `fa5e282`) · verificado 2026-10-17

---

## Gate 0 · Decisiones pendientes del usuario

| | Decisión | Recomendación del asistente | Estado |
|---|---|---|---|
| **0-A** | Bloquear área/plantas en el editor cuando hay siembras | ✅ Sí, **pero antes** habilitar *registrar pérdida sin plantar* (hoy `plants > 0` es obligatorio) y ofrecer un **ajuste** de salida | ✅ |
| **0-B** | Los dos "costos de establecimiento" | ✅ **B1 mejorado**: auto-rellenar desde los gastos de siembra inicial y **dejarlo editable**; renombrar a *"Inversión total"* | ✅ |
| **C1** | Fecha de siembra en el editor de cultivo | ✅ Sí — opcional, guarda **fecha**, muestra **años**; no se pide si el cultivo ya viene de una siembra | ✅ |
| **C2** | Ruta "ya está plantado" nace en producción | ✅ Sí, pero **derivado de la fecha** (no a mano). P3 intacto para el editor normal | ✅ |

### Ya confirmadas por el usuario

- **A2** · saco configurable en Ajustes (defecto 70 → él usa 60)
- **B1** · al borrar la cosecha se borra **también** la venta que creó la app
- Atacar en este orden las propuestas **1, 2 y 5** (elegidas sobre el análisis A–G)

---

## Las 6 fases

| # | Fase | Trae | Esfuerzo | Depende de |
|---|---|---|---|---|
| **F1** | Cosecha → venta | **1** + B1 | 🟡 M | — |
| **F2** | Costo en la resiembra | **2** | 🟢 S | — |
| **F3** | Inversión total | **0-B** | 🟢 S | F2 |
| **F4** | Pérdida sin plantar | **0-A** | 🟡 M | — |
| **F5** | Fecha, fase y edad | **C1 + C2 + 5** | 🟡 M | migración Supabase |
| **F6** | Saco configurable | **A2** | ❓ **dimensionar** | — |

```
F1 ──┐
F2 ──┼─► F3
F4 ──┤
F5 ──┤   (incluye la propuesta 5 · edad)
F6 ──┘   (independiente)
```

### F1 · Cosecha → venta 🟡 ✅ **HECHO 2026-10-09** · 470/470

> Implementado. `reconcileHarvestSale()` en `transaction_provider.dart`; campo de precio
> + vista previa en `harvest_screen.dart`; 4 claves l10n (es/en); regla B1 en `deleteHarvest`.
> 12 tests nuevos (9 provider + 3 widget).
> **DESPLEGADO 2026-10-09** — `main b895a94` / `gh-pages 14a59db` ·
> SHA256 prod `6675E66D59900DBE15B20874CE6680A74B1A5FCD4A81919B0EC0171442354205` (MATCH) ·
> home y `/backup.html` HTTP 200.

Formulario de cosecha nuevo:

```
Nueva cosecha
  Cultivo [ Café ▾ ] · Fecha · Cantidad [ 8 ] [ Costales ▾ ]
  Destino  ● Vendido   ○ Pérdida
  Precio por costal  [ 300.000 ]        ← NUEVO, opcional
  ─────────────────────────────
  Venta:  $2.400.000  ·  480 kg
```

| Situación | Resultado |
|---|---|
| Vendido + precio | Crea **venta** con `harvestId` |
| Vendido sin precio | Nada + *"¿Te pagaron? Regístrala cuando cobres"* |
| Pérdida | **Nunca** crea venta |
| Editas el precio | La venta ligada **se actualiza** |
| **Borras la cosecha** | Se borra la **venta**; los **gastos** de recolección **se quedan** (dinero ya gastado) |

- **Archivos**: `lib/screens/harvest_screen.dart` (`_save` ~L211-252) ·
  `lib/providers/transaction_provider.dart` (`addHarvest` ~L349, `deleteHarvest` L409-410) ·
  `lib/models/harvest.dart` · l10n es/en
- **Regla de borrado (B1)**: `type == income && harvestId == id`. Segura — ver hallazgo 10.
- **No se toca**: la alerta `harvestVsSales` (`alert_service.dart` ~L405). Sonará mucho menos.
- **Tests**: crea venta ligada · sin precio no crea · pérdida no crea · editar cosecha
  actualiza la venta · borrar cosecha borra venta y conserva el gasto · alerta sigue presente

### F2 · Costo en la resiembra 🟢 ✅ **HECHO 2026-10-09** · 473/473

> Implementado. El campo de costo salió de la rama `siembra` y ahora se muestra
> en los dos tipos de registro; `_save` ya no filtra por `SowingKind`. El gasto
> guarda su `sowingId` → entra a **costo/kg**, y **no** cuenta para *Inversión
> total* (F3 lo sigue respetando). Nuevo validador `sowingCostInvalid` y copia
> que nombra la resiembra (es/en). 3 tests nuevos en `sowing_screen_test.dart`.
> **No commiteado a la espera del verbo.**

- **Archivo**: `lib/screens/sowing_screen.dart:354` — `if (_kind == SowingKind.siembra)`
  pasa a cubrir también `resiembra`.
- El gasto se guarda con su `sowingId` → entra a **costo/kg**
  (`report_harvest_metrics.dart:148` ya cuenta `sowingId != null`).
- **No** entra a *Inversión total* (solo siembras iniciales) — lo respeta F3.
- Validar `cost > 0`.
- **Tests**: resiembra con costo crea gasto vinculado · sin costo no crea ·
  el costo de la siembra inicial sigue contando igual.

### F3 · Inversión total 🟢 *(requiere F2)* ✅ **HECHO 2026-10-09** · 482/482

> Implementado. `TransactionProvider.initialSowingCost(cropId)` suma los gastos
> de siembra **iniciales** del cultivo (por categoría `siembra` o por `sowingId`)
> y **aparta los de resiembra**; devuelve `null` si no hay. El editor lo recibe
> como `suggestedEstablishmentCost` y lo usa **solo si el campo viene vacío** —
> nunca pisa lo ya anotado, y sigue siendo editable. Los dos caminos que abren
> el editor (`crops_screen._editCrop` y `crop_setup_prompt._openEditor`) lo
> pasan. Copy renombrado a *"Inversión total"* (es/en), incluida
> `helpPaybackIntro` que nombraba el campo viejo.
> 9 tests nuevos (6 provider + 3 diálogo). **No commiteado a la espera del verbo.**

- **Archivo**: `lib/widgets/crop_editor_dialog.dart` (~L270) + l10n
- Al **abrir** el editor, si el campo está vacío → **auto-rellenar** con la suma de los
  gastos de siembra **iniciales** del cultivo (excluir resiembras).
- **Queda editable** por si falta preparación de tierra, cercas, mano de obra.
- Renombrar a *"Inversión total"* + ayuda *"Lo que invertiste en dejar este cultivo listo.
  Sirve para saber cuándo se paga."*
- `per_hectare_panel.dart:75,177,188` **no cambia** — sigue leyendo `establishmentCost`.
- **Tests**: se auto-rellena · excluye resiembras · edición manual persiste ·
  `null` → sigue oculto (regla de oro: null → oculto, nunca 0).

### F4 · Pérdida sin plantar 🟡 ✅ **HECHO 2026-10-17**

**Este es el que habilita el bloqueo del 0-A.**

> Las cuatro partes estaban puestas: la bandera `sowingsLocked` y el bloqueo de los dos campos
> en `crop_editor_dialog.dart` (`enabled: !sowingsLocked` + `cropLockedHint`), los textos
> *«Calculado desde tus siembras»* y *«Registrar pérdida»*, y la **salida** (`_registerLoss` abre
> el `CropLossDialog`). El cableado también: `crops_screen.dart:282` pasa
> `sowingsLocked: _hasInitialSowing(tx, crop)` (`:347`, «siembra inicial de ese cultivo»).
> Lo que faltaba era lo que ata las dos piezas: el **test de cableado**
> (`test/crops_screen_test.dart`), verificado en **rojo** apagando la bandera. La parte **a**
> (mortandad sin reponer) había quedado hecha con la tanda de siembra.

| Parte | Archivo | Cambio |
|---|---|---|
| a | `lib/screens/sowing_screen.dart:461-465` | En resiembra permitir `plants == 0` **si** `lostPlants > 0`; exigir al menos uno de los dos. En siembra inicial sigue `> 0` |
| b | `lib/models/sowing.dart` | `recomputeCropState` ya hace `livePlants − perdidas + 0` ✅ **no cambia** |
| c | `lib/screens/crops_screen.dart` | Si el cultivo **tiene siembras** → área y plantas en **solo lectura** con *"Calculado desde tus siembras"* + botón **"Registrar pérdida"** |
| d | `lib/widgets/crop_editor_dialog.dart` | Mismo bloqueo al editar |

- **⚠️ Salida de emergencia**: el botón debe permitir también un **ajuste**
  ("tenía X, ahora quedan Y"). Sin eso el caficultor queda encerrado.
- **Tests**: resiembra con 0 plantas y pérdidas guarda · siembra inicial sigue exigiendo > 0 ·
  ambos vacíos → error · cultivo **con** siembras no deja editar área/plantas ·
  cultivo **sin** siembras sí lo deja (ruta "ya está plantado").

### F5 · Fecha, fase y edad 🟡 ✅ **HECHO** (`fa5e282`, verificado 2026-10-17)

**Bloque de modelo — incluye la migración. Va al final de F1-F4 para no mezclar.**

> Verificado el 2026-10-17: `plantedAt` está en `Crop` con `copyWith`/JSON y sus cuatro tests
> (`test/crop_test.dart:50`); el sync lo envía y lo recibe (`sync_provider.dart:400,674`); el editor
> pide la fecha **solo** en perenne, **opcional**, y **no la pregunta si el cultivo ya tiene
> siembras**; la **edad** vive en `edadDeCrop` con todos los casos probados (la última siembra gana
> sobre `plantedAt`, una resiembra **no** reinicia la edad, sin datos → nada, anual → nada, menos de
> un año → `0`, no «sin datos»), y `crops_screen` la pinta junto a la fase.
>
> **La parte (e) cambió a propósito**: la fase de un cultivo nuevo **no** se deduce de la edad. Un
> umbral de años sería el del café puesto en boca de todos (hallazgo H2, ver `crop.dart:300-335`):
> se deduce de la **primera cosecha estimada** que él anota (E5) y, sin ese dato, nace en
> `establecimiento` (P3 intacto). Al editar no se re-deduce.
>
> Migración `crops.planted_at` **aplicada y verificada** en Supabase — lo registra el plan del
> replanteo v2 (2026-10-11, §0.1) y el archivo está versionado en
> `supabase/migrations/202610100001_add_crops_planted_at.sql`.

| Parte | Archivo | Cambio |
|---|---|---|
| a | `lib/models/crop.dart` | Nuevo `plantedAt` (`DateTime?`) + `copyWith` / `toJson` / `fromJson` |
| b | **migración Supabase** | `alter table crops add column if not exists planted_at date;` → **la aplica el usuario** en Supabase (precedente: `supabase/migrations/202609080001_add_establishment_cost.sql`) |
| c | `lib/providers/sync_provider.dart:349,532` | Enviar / recibir `planted_at` |
| d | `lib/widgets/crop_editor_dialog.dart` | Campo *"¿Desde cuándo está plantado?"* · **solo** `perenne` · **opcional** · no se pide si ya viene de una siembra |
| e | **C2** | Cultivo **nuevo** con fecha → fase **deducida** de la edad (2019 → producción; 2026 → establecimiento). Sin fecha → `establecimiento` (**P3 intacto**). Al **editar** **no** se re-deduces |
| f | **5 · edad** | `lib/screens/crops_screen.dart`: *"7 años"* junto a la fase. Regla: **última** siembra/resiembra → si no `plantedAt` → si no **no se muestra nada** |
| g | | Ciclo **anual** → sin edad |

- **Tests**: `plantedAt` sobrevive JSON · sync lo envía/recibe · fase derivada al crear ·
  no se re-deduces al editar · fecha de siembra reciente gana sobre `plantedAt` ·
  sin datos → nada · anual → nada · JSON antiguo sin el campo → `null`

### F6 · Saco configurable ❓ ✅ **HECHO** (`fa5e282`, verificado 2026-10-17)

> Se dimensionó y salió **S**: no hubo que pasar ajustes por todos los caminos. El peso del saco es
> un ajuste (`settings.sacoKg`, defecto 70, en Ajustes junto al umbral) y `unitToKg` lo **recibe por
> parámetro** donde se usa: alertas (`alert_service.dart:55`), ventas y cosechas, informes y
> exportadores. Migración `settings.saco_kg` **aplicada y verificada** en Supabase (plan del
> replanteo v2, §0.1) y versionada en
> `supabase/migrations/202610100002_add_settings_saco_kg.sql`.
> Tests: `alert_service_test.dart:192` (el peso del saco decide si la alerta dispara) ·
> `evaluate_alerts_test.dart:96` (el precio por kg con el peso real) · `backup_service_test.dart:207`
> (el respaldo conserva el que él eligió).

- **⚠️ Dimensionar antes de comprometer fecha.** Parece un número en Ajustes, pero
  `unitToKg('saco')` es una **función pura** llamada desde cosechas, reportes, PDF y Excel.
  Hacerla configurable puede pasar settings por todos esos caminos → quizás **M**, no **S**.
- **Acuerdo**: medirlo en ~15 min antes de meterlo al plan. Si es **M**, va **al final**.

---

## Hallazgos verificados (no re-analizar mañana)

1. **`Crop` NO tiene campo de fecha** — `lib/models/crop.dart:7-37`. De ahí la necesidad de C1.
2. **Resiembra exige `plants > 0`** — `lib/screens/sowing_screen.dart:461-465`
   (`if (n == null || n <= 0) return l10n.plantsInvalid`). **No se puede registrar
   mortandad sin resiembra.** → base del F4.
3. **`recomputeCropState`** — `lib/models/sowing.dart:104-114`:
   `siembra → livePlants = plants`; `resiembra → livePlants − perdidas + nuevas`.
   Si un cultivo **no** tiene siembra inicial, **no** se toca (`:116`).
4. **`_recomputeCropsFromSowings` pisa `livePlants`** — `transaction_provider.dart:482-486`,
   llamado en add/update/delete siembra (`:441, :453, :467`). → **Trampa A**.
5. **Dos fuentes que pueden divergir**: `crops_screen.dart:188` lee `crop.livePlants`
   (guardado) vs `report_screen.dart:584` llama a `recomputeCropState` (derivado).
6. **Costo solo en `kind == siembra`** — `sowing_screen.dart:354`. → base del F2.
7. **Dos "costos de establecimiento" distintos**: gasto con categoría
   `kExpenseCategorySowing` (`models/categories.dart:33`) vs campo `Crop.establishmentCost`
   (`models/crop.dart:18`) — este último alimenta solo `per_hectare_panel.dart:75,177,188`
   y `report_harvest_metrics.dart:248-261`. → **Trampa B**.
8. **`_promotePhaseOnHarvest`** — `transaction_provider.dart:381-392`: P3, promueve
   `establecimiento → producción` en la **primera cosecha**. Nunca al revés, nunca toca
   `renovacion`. Idempotente. ⇒ C2 corrige solo la **ventana previa** a la 1ª cosecha.
9. **Cultivo nuevo nace en `establecimiento`** — `crop_editor_dialog.dart:23-26` (decisión P3).
10. **`harvestId` HOY solo lo usan GASTOS**: `register_screen.dart:285` lo anula si no es
    expense; `report_harvest_metrics.dart:65,77` filtran `!isExpense`. ⇒ meter **ingresos**
    con `harvestId` **no rompe** el costo/kg, y toda venta con `harvestId` será de la app.
11. **`deleteHarvest` hoy desvincula, no borra** — `transaction_provider.dart:409-410`.
    (también `:333-337` desvincula al borrar cultivo; `:663-674` contabilidad de huérfanos)
12. **Onboarding**: `needsOnboarding` = sin crops y sin sowings (`next_step_service.dart:36-37`).
    Tarjeta de 2 opciones en `welcome_onboarding_card.dart`; **sin bottom nav** durante
    onboarding (`home_screen.dart:277`). ⇒ **A2 y B1 no lo tocan.**
13. **Unidades**: `arroba = 12.5` ✅ · `saco = 70` ❌ (el usuario usa **costal = 60 kg**)
    en `lib/models/units.dart`. El ÷60 de su papel son **costales**, no arrobas.
14. **`addTransaction` acepta `harvestId` sin restricción de tipo** — `transaction_provider.dart:199,218`.
15. **Migración previa aplicada por el usuario** — `supabase/migrations/202609080001_add_establishment_cost.sql`.
16. **`nextStepFor`** (`next_step_service.dart:54-85`): regla 2 manda a sembrar todo cultivo
    en `establecimiento`/`renovacion` sin siembra propia. ⇒ origen de la contradicción de C2.

### Su sistema de papel (base empírica del plan)

- Eje contable = **producto y categoría de gasto**, con **ritmo semanal** (L-M-M-J-V-S-D),
  **no** lote con nombre ⇒ se **retiró** la propuesta de renombrar "Cultivos" por "Lotes".
- **4 empleados** de jornal salen de la **caja menor mensual**; si baja el monto, reduce
  cuadrilla — la app ya lo modela con `cajaMenorMensual`.
- **Frutas** = mango, palta, mandarina → cada una su propio cultivo.
- **El plátano tapa la caja cuando el café no entra** → su puente de flujo de caja.
- Líneas 15/16 de su papel: *compra de colinos de plátano* → **valida F2** (resiembra de
  plátano cada 1-2 años y hoy no puede ponerle costo).
- Línea 7 con **FECHA** y la ficha técnica de Cenicafé (año de siembra) → **validan C1**.

---

## Fuera de alcance (confirmado, NO se toca)

| Tema | Motivo |
|---|---|
| 🔴 **Costos compartidos** (un obrero atiende café y plátano) | El problema más grande — necesita su **propio** análisis. Cenicafé: directos vs comunes |
| Campo *"lote"* explícito | Su papel dice que el eje es el **producto**, no el lote |
| Separar Lote / Cultivo como entidades | Modelo grande, no resuelto por copy |
| `HarvestDestination.almacenado` | Regla de dominio: **nada almacenado**; el enum solo histórico |
| Renombrar *"Cultivos"* | Retirado — su papel lo contradijo |
| Plan C "Tablero del Caficultor" | **CONGELADO**; flujo 1710 cerrado con Alt 1 + P4 |

---

## Reglas de ejecución

- 🔬 `flutter analyze` **y** `flutter test` **secuenciales antes de cada commit**.
  Si algo falla, se arregla antes de continuar. Estado de referencia al guardar el plan:
  **analyze sin issues · 458/458 tests**.
- 📦 Stageo **siempre explícito**: `git add lib test web` — **jamás** `git add -A`.
  (`docs/` solo si el usuario lo pide.)
- 🚫 **Ningún commit sin verbo explícito ese turno** del usuario
  (*comitea / comit pus / push / deploy*). Una opción numérica o de letra **no** cuenta.
- 🌐 Deploy solo con su orden: `flutter build web --release --base-href=/cafecal/
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` →
  `robocopy build\web _deploy /MIR /XD .git /XF .git /NFL /NDL /NJH /NJS` (exit 1-3 = ok)
  → push main + commit/push `_deploy` (gh-pages) → verificar SHA256 de `main.dart.js`.
- 🇪🇸 Todo en español. Cambios **aditivos/retrocompatibles**: no romper GitHub Pages + Supabase.
- 🚫 No commitear los 2 archivos ajenos pendientes:
  `docs/plans/2026-09-07-cosecha-nivel2.plan.md` y `docs/plans/2026-09-07-tu-proximo-paso.plan.md`.

---

## Verificación manual (solo el usuario, después del deploy)

1. 🪙 Moneda con y sin internet
2. 💾 Respaldo P1 (`file_picker`)
3. 🔗 Banner L2.5b
4. 📄 PDF y Excel de período **mezclado**
5. 🗑️ Borrado real de Opción A
6. 🌐 `/backup.html` con sesión iniciada
7. 🆕 **Nuevo**: cosecha con precio → aparece la venta · borrar la cosecha → se va la venta
   y **queda** el gasto de recolección

---

## Notas para retomar

- **Arranque previsto: 2026-10-09.** Primer paso: leer este archivo, mostrar el estado del
  Gate 0 y esperar el sí de **0-A, 0-B, C1, C2**. Luego **F1**.
- Tests con patrón en: `test/sowing_screen_test.dart`, `test/harvest_screen_test.dart`,
  `test/crop_editor_dialog_test.dart`, `test/transaction_provider_test.dart`,
  `test/report_harvest_metrics_test.dart`, `test/per_hectare_panel_test.dart`.
- Tests de pantalla: `tester.view.physicalSize = Size(900,3000)` +
  `addTearDown(tester.view.reset)`.
- `report_screen.dart` tiene **BOM UTF-8** — no romperlo.
- SQL vía Management API: `C:\Users\MKY\AppData\Local\Temp\opencode\supa-query.ps1`.
- Contexto de sitio: https://miguelalbisortiz.github.io/cafecal/ · ref `ioyqlzhzlvkkebvenqnz`.
