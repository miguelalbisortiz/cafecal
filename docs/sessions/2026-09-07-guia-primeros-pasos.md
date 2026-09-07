# 2026-09-07 — Guía de primeros pasos + tarjeta "Tu próximo paso"

## Summary

Sesión de pulido de la experiencia de usuario nueva: migración N2 aplicada y verificada, fix del bug de cultivos duplicados, guía de primeros pasos (markdown, casos A/B) y la tarjeta "Tu próximo paso" dentro del Home — de PRD a implementado y desplegado.

## What happened

1. **Migración SQL N2 aplicada y verificada**:
   - Archivo: `supabase/migrations/202609070001_add_sowings_harvests.sql`.
   - Usuario la pegó en el SQL Editor de Supabase y confirmó.
   - Verificación vía REST con anon key: `sowings` y `harvests` responden; columnas nuevas de `crops` (`phase`, `cycle`, `default_unit`, `area_ha`, `live_plants`) consultables; `transactions` con `harvest_id`/`sowing_id`; RLS funcional (insert sin sesión → 401 PGRST42501).

2. **Bug cultivos duplicados — corregido** (commit `e8d8340`):
   - Causa raíz: el trigger `handle_new_user()` crea Café/Plátano con ids **uuid** en Supabase; localmente los default crops usan ids fijos (`cafe`,`platano`,`otro`); `_pullRemote`/`mergeRemoteCrops` deduplicaba solo por id → duplicados visibles en Cultivos.
   - Fix: `mergeRemoteCrops` y `loadCrops()` deduplican por **nombre** (case-insensitive).
   - 3 tests de regresión añadidos; 91/91 tests verdes. gh-pages `c0c2a6b`, HTTP 200.

3. **Guía "Mi Cafetal — Guía de primeros pasos"** (iterada con el usuario, aún sin commit):
   - Conceptos (fase/ciclo/siembra/resiembra/cosecha), tabla "¿Dónde entro cada dato?", casos A/B (¿ya los tengo sembrados? vs ¿voy a sembrar algo nuevo?), ejemplos por cultivo, glosario (plantines, arroba 12.5 kg, saco 70 kg, ROI, balance).

4. **Tarjeta "Tu próximo paso"** — PRD → implementación → deploy:
   - PRD aprobado: `docs/plans/2026-09-07-tu-proximo-paso.plan.md` (12 ACs). Enlace "Ver guía completa" **fuera de alcance** (decisión del usuario; se decide más adelante).
   - **Fase 1**: `lib/services/next_step_service.dart` — `NextStepType { crop, sowing, expenses, harvest, sale }`, `NextStep { type, cropId }`, `nextStepFor({crops, sowings, harvests, transactions, year})` con reglas de prioridad: cultivos vacíos → crop; cultivo `establecimiento`/`renovacion` sin siembra inicial propia → sowing (resiembra sola no cubre); sin gastos del año → expenses; con gastos y sin cosechas → harvest; con cosecha y sin ventas `venta_*` → sale; si no, null (oculta).
   - **Fase 2**: `lib/widgets/next_step_card.dart` — tarjeta minimal que ve `TransactionProvider`, `SizedBox.shrink` si no hay paso, CTA vía `onAction(type)`.
   - **Fase 3**: `home_screen.dart` — tarjeta arriba de `AlertsBanner`; `_onNextStep` navega: crop→CropsScreen, sowing→SowingScreen, harvest→HarvestScreen, expenses/sale→`RegisterScreen(initialType: ...)` vía `_goRegister`.
   - `register_screen.dart`: nuevo parámetro `initialType` (Gasto/Ingreso prefijado; solo cuando no se edita).
   - **Fase 4**: strings es/en en `app_es.arb`/`app_en.arb` (+ `@nextStepSowingTitle` con placeholder `crop`), regen con `flutter gen-l10n`. 15 tests nuevos (12 servicio + 3 widget).
   - Commit `219414f` main, `7eb271a` gh-pages, **HTTP 200**.

## State

| Item | Status |
|---|---|
| Tests | 106/106 verdes (91 previos + 15 nuevos) |
| analyze | limpio |
| gh-pages | `7eb271a`, HTTP 200 |
| main | `219414f` |
| Migración Supabase | **aplicada y verificada** |
| Prueba de escritura end-to-end | pendiente (falta token de usuario autenticado en `report_creds.env`) |
| Guía primeros pasos (md) | existente, aún no commiteada |

## Key decisions (no revertir)

- Dedup de cultivos por **nombre** (case-insensitive), no solo por id (el trigger de Supabase usa uuids).
- Tarjeta **derivada del estado, sin estado guardado**: se recalcula en cada build, reaparece al borrar, nunca desincroniza, un solo paso a la vez, no bloqueante.
- La **fase decide la guía** (A/B automático): `establecimiento`/`renovacion` → sugiere siembra; `produccion` → no exige siembra (salta a gastos).
- Demo no genera pasos falsos (default crops en `produccion` → regla 2 no aplica).
- Enlace "Ver guía completa": **fuera de alcance** de este plan; se decide más adelante.

## Pending

- [ ] Committear la guía markdown de primeros pasos
- [ ] Prueba de escritura autenticada end-to-end en Supabase (requiere token de un usuario real)
- [ ] Decidir dónde/cómo exponer la guía completa en la app ("Ver guía completa")
- [ ] Nivel 3 formal (panel KPI por hectárea, amortización establecimiento)

## Files

`lib/services/next_step_service.dart` (nuevo), `lib/widgets/next_step_card.dart` (nuevo)
`lib/screens/home_screen.dart`, `lib/screens/register_screen.dart`
`lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/l10n/generated/*`
`test/next_step_service_test.dart` (12), `test/next_step_card_test.dart` (3), `test/transaction_provider_test.dart` (+3 dedup)
`docs/plans/2026-09-07-tu-proximo-paso.plan.md`