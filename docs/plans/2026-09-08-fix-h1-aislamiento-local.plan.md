# Plan 2026-09-08 — Fix H1: aislamiento de datos locales por usuario

## Problema

`LocalStore` guarda todo en claves fijas (`transactions_v1`, `crops_v1`, …). Si la sesión expira sin logout o en el mismo dispositivo entra otra cuenta, la cuenta B lee los datos locales de la cuenta A (que podían incluir cambios sin sincronizar). Hallazgo **H1 (MEDIA)** de la auditoría de seguridad del ingreso.

## Solución (aprobada por el usuario: solo H1)

1. **Namespace por uid**: `LocalStore` recibe un `uid`; cada clave pasa a ser `transactions_v1_<uid>`, etc. Sin uid (arranque sin sesión) usa las claves legacy.
2. **Migración legacy→namespaced**: al primer bind con uid, si existe la clave legacy y no existe la namespaced, se copia y se borra la legacy. No pisa datos namespaced existentes.
3. **`clearAll()` selectivo**: al cerrar sesión solo se borran las claves del uid activo.
4. **Bind en arranque**: `main()` crea el store con `SupabaseService.currentUserId` (sesión persistida).
5. **Bind en login**: `AuthProvider.signIn/signUp` hace `store.bindUser(uid)` + `TransactionProvider.reloadFromCache()` (la app nunca muestra datos de la cuenta anterior).
6. **`signOut`** limpia el namespace actual y desvincula (`bindUser(null)`).

## Archivos

- `lib/services/local_store.dart` — namespace, migración, clearAll selectivo
- `lib/services/supabase_service.dart` — getter `currentUserId`
- `lib/providers/auth_provider.dart` — bind + callback `onUserChanged`
- `lib/providers/transaction_provider.dart` — `reloadFromCache()`
- `lib/main.dart` — bind al arranque + cableado del callback
- `test/local_store_test.dart` — 7 tests nuevos (aislamiento, migración, clearAll, reload)

## Verificación

- `flutter analyze` limpio
- `flutter test` **144/144** (7 nuevos)
- Build web release → gh-pages → HTTP 200

## Riesgos

- Migración idempotente y no destructiva (no pisa datos namespaced).
- Compatibilidad: `LocalStore(prefs)` sin uid conserva el comportamiento de los tests existentes.
- En un dispositivo compartido cada cuenta conserva su propio cache local (comportamiento nuevo); las cuentas nunca se mezclan.