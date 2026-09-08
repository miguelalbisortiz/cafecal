# 2026-09-08 — Fixes de auditoría: H1, H5, H3, H2

## Summary

Cierre de los 4 fixes de seguridad aprobados. H1 (aislamiento local por usuario) se desplegó primero en su propia iteración (`4a8c125`/`d8a1716`, 144/144). Esta sesión añadió y desplegó H5 (CSV anti-inyección de fórmulas), H3 (validación mínima de credenciales) y H2 (init de AuthProvider cableado). Suite final **150/150**, analyze limpio, HTTP 200.

## What happened

- **H5 CSV injection**: `_neutralizeFormula()` antepone `'` a celdas que arrancan con `=`, `+`, `@` o `-` no numérico (OWASP). El `line()` del balance template acepta `formulaCols` para preservar las fórmulas internas (`=SUM(B5:B10)`, `=B11-B17-B23`). Los números negativos (`-1000,00`) no se tocan.
- **H3 validación cliente**: `AuthProvider._validateCredentials` (regex email + mínimo 6 chars) antes de llamar a Supabase en `signIn`/`signUp`; error amigable sin viaje de red.
- **H2 init cableado**: `auth.init()` invocado al crear el provider en `MiCafetalApp` (restaura namespace persistido + reload).
- Tests: +3 en `test/excel_export_service_test.dart` (H5), nuevo `test/auth_provider_test.dart` (3, H3).

## State

| Item | Status |
|---|---|
| Tests | **150/150 verdes** |
| analyze | limpio |
| gh-pages | `6802f27`, HTTP 200 |
| main | `dd7279c` (0600f37 código + dd7279c docs) |

## Key decisions (no revertir)

- La neutralización H5 es selectiva: NO neutraliza fórmulas internas del template ni números negativos — solo celdas de entrada no numérica con prefijos peligrosos.
- H3 es validación de UX, no defensa de seguridad: la auth real sigue en Supabase.
- H2: `init()` ya no es no-op y se llama en el arranque de la app.

## Pending

- [ ] Verificación manual en producción: cuenta real → migración legacy → datos intactos; cuenta B no ve nada de A.
- [ ] H4 (cifrado) descartado por decisión previa.

## Files

`lib/services/excel_export_service.dart`, `lib/providers/auth_provider.dart`, `lib/main.dart`, `test/excel_export_service_test.dart`, `test/auth_provider_test.dart`, `docs/plans/2026-09-08-fix-h1-aislamiento-local.plan.md`