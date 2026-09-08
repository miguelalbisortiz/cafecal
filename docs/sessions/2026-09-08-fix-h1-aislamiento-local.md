# 2026-09-08 — Fix H1: aislamiento de datos locales por usuario

## Summary

Implementación del hallazgo **H1 (MEDIA)** de la auditoría de seguridad: los datos locales dejaban de cruzarse entre cuentas. Antes, `LocalStore` usaba claves fijas (`transactions_v1`, …) y si la sesión expiraba sin logout o entraba otra cuenta en el mismo dispositivo, la cuenta B veía los datos de A (incluso cambios sin sincronizar). Ahora cada usuario tiene su namespace y al hacer login la app recarga SOLO sus datos.

## What happened

- `LocalStore` acepta `uid` → claves `transactions_v1_<uid>`, etc. Sin uid usa las legacy (compatibilidad con tests).
- **Migración idempotente** en `create(uid:)` y `bindUser()`: copia la clave legacy a su namespace solo si no existe la namespaced; borra la legacy. No pisa nada.
- `clearAll()` (logout) borra solo las claves del uid activo.
- `SupabaseService.currentUserId` nuevo; `main()` crea el store con el uid de la sesión persistida.
- `AuthProvider.signIn/signUp` → `bindUser(uid)` + `reloadFromCache()` (vía callback `onUserChanged` en `MiCafetalApp`); `signOut` → clearAll + `bindUser(null)`.
- `TransactionProvider.reloadFromCache()` recarga txn/crops/settings/harvests/sowings del namespace activo.

## State

| Item | Status |
|---|---|
| Tests | **144/144 verdes** (7 nuevos en `test/local_store_test.dart`) |
| analyze | limpio |
| gh-pages | `d8a1716`, HTTP 200 |
| main | `4a8c125` |

## Key decisions (no revertir)

- Aislamiento por **namespace** (no "clear on uid change"): no pierde el cache local de cada cuenta; migración legacy automática preserva datos existentes.
- `bindUser(null)` después del `signOut` para que la siguiente sesión arranque limpia.
- H5 (CSV anti-fórmula), H3 (validación cliente) y H2 (init muerto): NO incluidos (fuera del alcance aprobado).

## Pending

- [ ] H5 (prefijo `'` en CSV), H3 (validación email/password), H2 (init) si el usuario los pide en otra iteración.
- [ ] Verificación manual en producción: entrar con la cuenta real → migrar claves legacy → ver datos intactos; confirmar que una segunda cuenta no ve nada.

## Files

`lib/services/local_store.dart`, `lib/services/supabase_service.dart`, `lib/providers/auth_provider.dart`, `lib/providers/transaction_provider.dart`, `lib/main.dart`, `test/local_store_test.dart`, `docs/plans/2026-09-08-fix-h1-aislamiento-local.plan.md`