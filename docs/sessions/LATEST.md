# 2026-09-08 — Alertas A1/C/B + Fixes de auditoría (H1, H5, H3, H2)

## Summary

La sesión de cierre técnico (Nivel 3 + alertas A1/C/B + auditoría) culminó con los **4 fixes de la auditoría de seguridad desplegados**: H1 (aislamiento local por usuario), H5 (CSV anti-inyección de fórmulas), H3 (validación mínima de credenciales) y H2 (init cableado). Suite final **150/150 tests**, analyze limpio, HTTP 200.

## What happened

1. **Nivel 3 completo y desplegado** (main `9c06ec7`, gh-pages `e2c0e89`, HTTP 200, 127/127 tests).
2. **Auditoría de seguridad del ingreso**: ninguna CRITICAL/HIGH; hallazgos remediados en esta sesión.
3. **PRD + Plan alertas aprobados** — A1 + C + B (A2/D/E → iteración futura).
4. **Alertas A1 + C + B desplegadas** (main `27beabd`, gh-pages `d5d5476`, HTTP 200, 137/137 tests).
5. **Fix H1 — aislamiento local por usuario** (main `4a8c125`, gh-pages `d8a1716`, HTTP 200, 144/144 tests): namespace por uid, migración legacy idempotente, `reloadFromCache()`, bind en login/logout.
6. **Fixes H5 + H3 + H2** (main `dd7279c = 0600f37 + dd7279c`, gh-pages `6802f27`, HTTP 200, **150/150 tests**):
   - **H5 CSV**: `_neutralizeFormula()` antepone `'` a celdas que arrancan con `=`, `+`, `@` o `-` no numérico; fórmulas internas del template preservadas (`formulaCols`); negativos intactos. (`excel_export_service.dart`)
   - **H3**: validación email (regex) + password ≥6 en `AuthProvider.signIn/signUp` antes de llamar a Supabase; error amigable. (`test/auth_provider_test.dart`)
   - **H2**: `AuthProvider.init()` ya no es no-op y se invoca al arrancar la app. (`main.dart`)

## State

| Item | Status |
|---|---|
| Tests | **150/150 verdes** |
| analyze | limpio |
| gh-pages | `6802f27`, HTTP 200 |
| main | `dd7279c` |
| Migración N3 | aplicada (usuario) |
| .env | gitignored, funciona local |

## Key decisions (no revertir)

- R1 baseline estacional (mismo mes calendario), umbral intacto `2×`; R6: pérdida no respalda ventas; B es `info`, nunca adivina cantidad.
- Fixes de auditoría: H1 (aísla por namespace, migración no destructiva), H5 (neutralización selectiva — no toca fórmulas internas ni negativos), H3 (validación de UX, la auth real sigue en Supabase), H2 (init cableado al arranque).

## Pending

- [ ] Verificación manual en producción: login con cuenta real → migración de claves legacy → datos intactos; segunda cuenta no ve nada.
- [ ] Iteración futura de alertas: A2, D, E.
- [ ] H4 (cifrado) descartado por decisión previa.