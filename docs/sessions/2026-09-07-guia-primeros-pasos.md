# 2026-09-07 — Guía de primeros pasos + tarjeta "Tu próximo paso" + Sección Ayuda + Plan Nivel 3

## Summary

Sesión de pulido de la experiencia de usuario nueva: migración N2 aplicada y verificada, fix de duplicados, tarjeta "Tu próximo paso", fix de cuenta nueva, guía markdown commiteada, verificación end-to-end de escritura autenticada en Supabase, **sección Ayuda interna** dentro de la app (implementada y desplegada) y al final se **diseñó y aprobó el plan del Nivel 3** (KPI por hectárea + amortización del establecimiento) para implementar en la próxima sesión. También se hizo un análisis de precios de la competencia (FincaData, Agroptima) con recomendación freemium (sin decidir).

## What happened

1. **Migración SQL N2 aplicada y verificada**:
   - Archivo: `supabase/migrations/202609070001_add_sowings_harvests.sql`.
   - Verificación vía REST con anon key: `sowings`/`harvests` responden; columnas nuevas de `crops` consultables; RLS funcional (insert sin sesión → 401 PGRST42501).

2. **Bug cultivos duplicados — corregido** (commit `e8d8340`):
   - Causa: trigger `handle_new_user()` crea Café/Plátano con ids uuid vs ids fijos locales; `_pullRemote`/`mergeRemoteCrops` deduplicaba solo por id.
   - Fix: dedup por **nombre** (case-insensitive) en `mergeRemoteCrops` y `loadCrops()`. 3 tests de regresión.

3. **Tarjeta "Tu próximo paso"** (PRD `docs/plans/2026-09-07-tu-proximo-paso.plan.md` → implementado y desplegado):
   - `lib/services/next_step_service.dart` (reglas 1-5), `lib/widgets/next_step_card.dart`, integración en `home_screen.dart`, `register_screen.dart` con `initialType`.
   - Commit `219414f` main, `7eb271a` gh-pages, HTTP 200.

4. **Fix bug cuenta nueva** (`eea0c9f` main, `118fa83` gh-pages, HTTP 200):
   - Reportado por el usuario: cuenta vacía sugería "registra tus primeros gastos" en vez de arrancar la guía.
   - Causa: `loadCrops()` siempre siembra `defaultCrops` (Café/Plátano/Otro en `produccion`) → regla 1 nunca aplicaba.
   - Fix: regla 1 = cultivos vacíos **o solo 3 defaults sin tocar** (`_onlyUntouchedDefaults`: phase `produccion`, cycle `perenne`, defaultUnit/areaHa/livePlants null) **y** sin datos (`!hasAnyData`). Título dinámico "Configura tu primer cultivo". Fix tilde en `{'café','plátano','otro'}`. 3 tests servicio + 1 widget. **109/109 tests**.

5. **Guía markdown commiteada** (`8d5fb0e`): `docs/guides/mi-cafetal-primeros-pasos.md` (conceptos, "¿Dónde entro cada dato?", casos A/B, ejemplos por cultivo con arroba 12.5 kg / saco 70 kg verificados en `units.dart`, glosario, sincronización).

6. **Verificación de escritura autenticada end-to-end** (`53bec0f`):
   - `tool/verify_auth_write_tool.dart`: password grant → INSERT → SELECT → DELETE con RLS (round-trip real).
   - Usuario creó `report_creds.env` (gitignored) con `EMAIL=miguelalbisortiz@gmail.com`.
   - Fix del script: `crops.id` es uuid → la BD genera el id (`created['id']`).
   - **Verificado OK** para el usuario real `8d56ae22…` (registro de prueba limpiado). Ya NO es pendiente.

7. **Sección Ayuda interna** (PRD `docs/plans/2026-09-07-seccion-ayuda.plan.md`):
   - `lib/screens/help_screen.dart`: guía completa en es/en (intro, "¿Dónde entro cada dato?" con pantallas reales, casos A/B, unidades, glosario agrícola + botón al glosario financiero `showTerminologyGuide`).
   - Menú ⋮ → "Ayuda" (`menuHelp`); link "Ver guía completa" (`nextStepGuideLink`) en la tarjeta → `HelpScreen`.
   - ~32 strings nuevos por idioma; `test/help_screen_test.dart` (usa `tester.view.physicalSize`). **111/111 tests**, analyze limpio.
   - Commit `abb5b69` main, `3334d90` gh-pages, **HTTP 200**.

8. **Plan Nivel 3 diseñado y aprobado** (sin implementar — para la próxima sesión):
   - PRD: `docs/plans/2026-09-07-nivel3-kpi-por-hectarea.plan.md`.
   - Contexto técnico: `ReportHarvestMetrics.yieldPerArea()`/`yieldPerPlant()` ya existen y solo se usan en exportación PDF/Excel; N3 los saca a la UI y agrega versiones financieras por ha.
   - **Decisiones confirmadas por el usuario**: D1 panel **en el Reporte** (widget reutilizable `per_hectare_panel.dart`); D2 inversión del establecimiento = **campo manual opcional** `establishmentCost`; D3 punto de equilibrio **sí, con "aprox."** (inversión ÷ margen anual promedio medido, solo ≥1 período completo).
   - Alcance: dato nuevo + migración `crops.establishment_cost` + sync + editor; lógica pura; UI en reporte; Ayuda/guía; tests. Regla de oro intacta; todo opcional (null → oculto, nunca 0).

9. **Análisis de precios / competencia** (opinión + investigación, sin implementar):
   - FincaData (CO): desde $39.900 COP/mes (2 ha + 5 usuarios) + ~$11.900–18.900 COP/ha + sensores.
   - Agroptima (ES): precio por ha + usuarios, a cotizar (~€40+/mes comercial).
   - Recomendación: **freemium** — gratis lo actual (N1+N2+guía), "Mi Cafetal Pro" ~$9.900–14.900 COP/mes desbloqueando N3 + exportaciones + sync pro + soporte. Posicionamiento: paridad en kg/ha, ventaja en amortización del establecimiento, por debajo del precio base de FincaData. Decisión de negocio **pendiente**.

10. **Modo invitado eliminado** (decisión del usuario: la opción "explorar la app sin cuenta" ya no debe estar disponible ni visible):
    - `lib/screens/auth_screen.dart`: removidos botón "Explorar la app sin cuenta" + hint + `_enterGuestMode()` + `_seedDemoData()` + imports no usados.
    - `lib/providers/auth_provider.dart`: removidos `signInAsGuest`, `isGuest`, `_guestMode`, `_exitGuestMode`; `isLoggedIn` = solo sesión Supabase.
    - `lib/services/local_store.dart`: removida clave `guest_mode_v1` + `loadGuestMode`/`saveGuestMode`.
    - Keys l10n `authGuest`/`authGuestHint` eliminadas de `.arb` es/en + `gen-l10n`.
    - Efecto colateral deseado: un dispositivo que estaba en modo visita vuelve a la pantalla de login.
    - Verificado: analyze limpio, **111/111 tests verdes**.

## State

| Item | Status |
|---|---|
| Tests | **111/111 verdes** |
| analyze | limpio |
| gh-pages | `3334d90`, HTTP 200 |
| main | `abb5b69` |
| Migración Supabase | aplicada y verificada |
| Escritura autenticada end-to-end | **verificada** (usuario real, round-trip) |
| Sección Ayuda | implementada y desplegada en la app |
| Plan Nivel 3 | **diseñado y firmado, sin implementar** (para mañana) |
| Precio/paywall Pro | análisis hecho, decisión de negocio pendiente |

## Key decisions (no revertir)

- Dedup de cultivos por **nombre** (case-insensitive), no solo por id.
- Tarjeta **derivada del estado, sin estado guardado**; un solo paso a la vez; no bloqueante.
- La **fase decide la guía** (A/B): `establecimiento`/`renovacion` → siembra; `produccion` → gastos.
- Cuenta totalmente nueva (solo 3 defaults sin tocar + sin datos) → paso "Configura tu primer cultivo"; con datos se vuelve al flujo normal.
- Guía completa = **sección Ayuda interna** en la app (no enlace externo); el markdown de `docs/guides/` queda como fuente del repo; glosario financiero no se duplica (reutiliza `showTerminologyGuide`).
- **Nivel 3**: D1 panel en Reporte (widget reutilizable); D2 `establishmentCost` campo manual opcional; D3 breakeven con etiqueta "aprox." y solo datos medidos. Regla de oro intacta (null → oculto).

## Pending

- [ ] **Implementar Nivel 3** (mañana): F1 dato/migración/sync/editor → F2 lógica+test → F3 panel reporte → F4 Ayuda/guía → deploy. Plan firmado en `docs/plans/2026-09-07-nivel3-kpi-por-hectarea.plan.md`.
- [ ] Decidir paywall/precio freemium ("Mi Cafetal Pro") y qué desbloquea (N3, exportaciones, sync pro).
- [ ] Nivel 3+ (futuro): comparar entre cultivos y por año (dashboard por finca).

## Files

- Tarjeta: `lib/services/next_step_service.dart`, `lib/widgets/next_step_card.dart`, `lib/screens/home_screen.dart`, `lib/screens/register_screen.dart`
- Ayuda: `lib/screens/help_screen.dart`, `lib/widgets/terminology_guide.dart` (reutilizado)
- Sin modo invitado: `lib/screens/auth_screen.dart`, `lib/providers/auth_provider.dart`, `lib/services/local_store.dart`
- i18n: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/l10n/generated/*`
- `tool/verify_auth_write_tool.dart` + `report_creds.env` (gitignored)
- Docs: `docs/guides/mi-cafetal-primeros-pasos.md`, `docs/plans/2026-09-07-tu-proximo-paso.plan.md`, `docs/plans/2026-09-07-seccion-ayuda.plan.md`, `docs/plans/2026-09-07-nivel3-kpi-por-hectarea.plan.md`
- Tests: `test/next_step_service_test.dart` (15), `test/next_step_card_test.dart` (4), `test/help_screen_test.dart` (1), `test/transaction_provider_test.dart` (+3 dedup)