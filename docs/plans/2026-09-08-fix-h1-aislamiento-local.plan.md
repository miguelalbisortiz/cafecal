# Plan 2026-09-08 — Fixes de auditoría de seguridad (H1, H5, H3, H2)

## H1 — Aislamiento de datos locales por usuario (MEDIA, desplegado)

### Problema

`LocalStore` guarda todo en claves fijas (`transactions_v1`, `crops_v1`, …). Si la sesión expira sin logout o en el mismo dispositivo entra otra cuenta, la cuenta B lee los datos locales de la cuenta A (que podían incluir cambios sin sincronizar). Hallazgo **H1 (MEDIA)** de la auditoría de seguridad del ingreso.

## Solución (aprobada por el usuario: solo H1)

1. **Namespace por uid**: `LocalStore` recibe un `uid`; cada clave pasa a ser `transactions_v1_<uid>`, etc. Sin uid (arranque sin sesión) usa las claves legacy.
2. **Migración legacy→namespaced**: al primer bind con uid, si existe la clave legacy y no existe la namespaced, se copia y se borra la legacy. No pisa datos namespaced existentes.
3. **`clearAll()` selectivo**: al cerrar sesión solo se borran las claves del uid activo.
4. **Bind en arranque**: `main()` crea el store con `SupabaseService.currentUserId` (sesión persistida).
5. **Bind en login**: `AuthProvider.signIn/signUp` hace `store.bindUser(uid)` + `TransactionProvider.reloadFromCache()` (la app nunca muestra datos de la cuenta anterior).
6. **`signOut`** limpia el namespace actual y desvincula (`bindUser(null)`).

## Archivos

- `lib/services/local_store.dart` — namespace, migración, clearAll selectivo (H1)
- `lib/services/supabase_service.dart` — getter `currentUserId` (H1)
- `lib/services/excel_export_service.dart` — `_neutralizeFormula` + formulaCols (H5)
- `lib/providers/auth_provider.dart` — bind (H1), `_validateCredentials` (H3)
- `lib/providers/transaction_provider.dart` — `reloadFromCache()` (H1)
- `lib/main.dart` — bind al arranque + `auth.init()` (H1/H2)
- `test/local_store_test.dart` (7), `test/auth_provider_test.dart` (3), `test/excel_export_service_test.dart` (+3)

## Verificación

- `flutter analyze` limpio
- `flutter test` **150/150**
- Build web release → gh-pages → HTTP 200

## H5 — CSV anti-inyección de fórmulas (BAJA)

Las celdas del CSV de balance que empezaban con `=`/`+`/`-`/`@` son ejecutadas por Excel. El `farmName` (campo del usuario) va al inicio de la celda. Fix: `_neutralizeFormula()` antepone `'` a celdas que arrancan con `=`, `+`, `@` o con `-` no numérico; las fórmulas internas del template (`=SUM(B5:B10)`, `=B11-B17-B23`) se marcan `formula: true` y se preservan; los números negativos (`-1000,00`) no se tocan. 3 tests nuevos.

Archivo: `lib/services/excel_export_service.dart` (linea `cell()` del balance template).

## H3 — Validación mínima de credenciales en el cliente (BAJA)

`AuthProvider.signIn/signUp` validan formato de email (regex simple) y mínimo 6 caracteres de contraseña antes de llamar a Supabase; evita viajes inútiles y da error inmediato. 3 tests nuevos (`test/auth_provider_test.dart`). Nota: no es defensa de seguridad — la auth real sigue en Supabase.

## H2 — init() de AuthProvider cableado

`AuthProvider.init()` ya no es no-op: restaura el namespace de la sesión persistida (bind + reload) y se invoca al crear el provider en `MiCafetalApp`.

## Riesgos

- Migración H1 idempotente y no destructiva (no pisa datos namespaced).
- La neutralización H5 no altera las fórmulas internas del template ni los números negativos (tests de regresión del CSV intactos).
- Compatibilidad: `LocalStore(prefs)` sin uid conserva el comportamiento de los tests existentes.
- En un dispositivo compartido cada cuenta conserva su propio cache local (comportamiento nuevo); las cuentas nunca se mezclan.