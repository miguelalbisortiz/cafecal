# Plan: Capa productiva — Nivel 1 (volumen/precio + cliente/proveedor)

- **Fecha**: 2026-09-06
- **Tipo**: Implementación (feature nueva)
- **Objetivo**: enriquecer el registro de ingresos y gastos para un control más
  preciso (volumen, precio por unidad, cliente/proveedor) y mejorar la alerta de
  precio bajo, **sin romper** la operación actual vía GitHub Pages + Supabase.
- **Cambio será retrocompatible y aditivo.**

---

## Decisiones de alcance (confirmadas por el usuario)

1. **Unidad configurable**: selector kg / arroba (12,5 kg) / saco (70 kg) por registro.
2. **Alerta precio bajo**: dos modos — comparar contra **histórico propio** + **umbral
   manual opcional** (ambas).
3. **Cliente y proveedor**: incluir ambos en esta fase (texto libre, costo bajo).

**Fuera de alcance (se planifican después)**: Nivel 2 (entidad `Harvest`/cosecha),
Nivel 3 (área/rendimiento kg-ha, break-even).

---

## Impacto en la infraestructura actual (importante)

- **GitHub Pages**: sin cambios de hosting/URL/PWA. Solo un build web nuevo.
- **Supabase**: cambios **aditivos** (solo se agregan columnas). La única acción
  manual es **aplicar una migración SQL** una vez. No hay datos que migrar (la
  nube tiene 0 transacciones hoy). Si no se aplica, la app **no se rompe**: esos
  campos quedan guardados solo en el dispositivo.
- **Local**: los campos nuevos son nullable → retrocompatibles con los 44 tests.

---

## Fases de trabajo

### Fase 1 — Modelo de datos (`lib/models/transaction.dart`)
Agregar campos nullable a `Transaction`:
```dart
final double? quantity;      // cantidad vendida/comprada
final String? unit;          // 'kg' | 'arroba' | 'saco'
final double? pricePerUnit;  // derivable = amount / quantity
final String? client;        // ingreso: comprador
final String? provider;      // gasto: proveedor/vendedor
```
Actualizar `copyWith`, `toJson`, `fromJson` (null-safe):
```dart
// toJson
'quantity': quantity,
'unit': unit,
'price_per_unit': pricePerUnit,
'client': client,
'provider': provider,
// fromJson (null-safe)
quantity: (json['quantity'] as num?)?.toDouble(),
unit: json['unit'] as String?,
pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
client: json['client'] as String?,
provider: json['provider'] as String?,
```
DONE: registros viejos cargan con campos null sin error.

### Fase 2 — Persistencia local + Sync (Supabase)
- `lib/services/local_store.dart`: los campos se serializan solos (mismo mapa).
  Sin cambios de clave (`transactions_v1`).
- Migración SQL nueva en `supabase/migrations/20260906..._add_income_units.sql`:
```sql
alter table public.transactions
  add column if not exists quantity numeric,
  add column if not exists unit text,
  add column if not exists price_per_unit numeric,
  add column if not exists client text,
  add column if not exists provider text;
```
- `lib/providers/sync_provider.dart`:
  - `_upsertRemote`: añadir `quantity, unit, price_per_unit, client, provider`.
  - `_remoteToTransaction`: leer los nuevos campos.
DONE: el sync incluye los campos nuevos; si la columna no existe en la nube,
se documenta que hay que aplicar la migración.

### Fase 3 — UI de registro (`lib/screens/register_screen.dart`)
- Tipo **ingreso** + categoría venta → bloque "Datos de producción":
  - campo `Cantidad vendida` (número).
  - selector `unit` (kg/arroba/saco).
  - campo `Cliente` (opcional).
  - texto solo-lectura "Precio por kg/arroba/saco: $X" (calculado monto/cantidad).
- Tipo **gasto** → campo opcional `Proveedor`.
- Edición: precargar los campos nuevos al abrir un registro existente.
DONE: registro/edición captura y muestra los campos nuevos correctamente.

### Fase 4 — Alerta de precio bajo (`lib/services/alert_service.dart`)
- Nueva regla: `_checkLowPriceReal`.
  - Modo A (histórico): compara `pricePerUnit` de la venta contra el promedio
    previo de ventas con unidad; alerta si cae >X% (default 20%).
  - Modo B (umbral manual): se fija un precio mínimo por unidad en configuración;
    alerta si la venta queda por debajo.
  - Si no hay histórico ni umbral → no dispara.
- Umbral configurable en `lib/screens/settings_screen.dart` y `models/settings.dart`.
DONE: alerta dispara/no dispara según histórico y/o umbral, con tests.

### Fase 5 — Reportes (PDF/Excel)
- `pdf_export_service.dart` y `excel_export_service.dart`: mostrar precio por kilo,
  top clientes (ingresos) y top proveedores (gastos) del período.
- `report_screen.dart`: sección "Productividad" ligera (precio por unidad).
DONE: el reporte muestra el nuevo dato.

### Fase 6 — i18n + Tests + validación
- `lib/l10n/app_es.arb` y `app_en.arb`: claves nuevas (unidad kg/arroba/saco,
  cantidad, cliente, proveedor, precio por unidad, regla de alerta, umbral).
- Tests nuevos:
  - `test/transaction_test.dart`: serialización retrocompatible (con/sin campos).
  - `test/alert_service_test.dart`: regla precio bajo (histórico + umbral).
  - Ajustar tests existentes si el modelo cambió constructores.
DONE: `flutter analyze` limpio, `flutter test` 100% verde.

### Fase 7 — Build + deploy
- `flutter build web --release --base-href=/cafecal/ --dart-define=...`.
- Deploy gh-pages + main (robocopy a worktree `_deploy`), verificar HTTP 200.
- Recordatorio: aplicar migración SQL en Supabase antes de que el sync use los
  campos nuevos en la nube.
DONE: sitio accesible (HTTP 200), Ctrl+F5, app funciona igual + nuevos campos.

---

## Criterios de aceptación (observables)

- **AC-1**: Al registrar un ingreso de venta con cantidad+unidad se guardan
  `quantity`, `unit` y `pricePerUnit` = monto/cantidad.
- **AC-2**: Gasto guarda `provider` opcional; vacío → `null`.
- **AC-3**: Registros viejos (sin campos) cargan sin error y conservan valor
  (retrocompatible, probado por test).
- **AC-4**: Alerta precio bajo dispara con histórico (caída >X%) o con umbral
  manual, y no dispara si falta contexto.
- **AC-5**: Export PDF/Excel muestra precio por unidad y top cliente/proveedor.
- **AC-6**: `flutter analyze` sin issues; `flutter test` verde.
- **AC-7**: Desplegado en GitHub Pages, HTTP 200, sigue funcionando con Supabase.

---

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Columna nueva ausente en la nube rompe el `upsert` | La migración es obligatoria y está en Fase 2; es aditiva. Si no se aplica, documentar que el sync local sigue funcionando y esos campos quedan en local. |
| Fricción en el registro de 10 s | Los campos nuevos son opcionales y solo aparecen cuando aplican (venta / proveedor). |
| Tests existentes dependen del constructor de `Transaction` | Los campos nuevos tienen default null → `copyWith`/fromJson compatibles; ajustar solo si algún test construye con todos los parámetros posicionales. |

---

## Archivos a tocar

`lib/models/transaction.dart`, `lib/models/settings.dart`,
`lib/services/local_store.dart`, `lib/services/supabase_service.dart`,
`lib/providers/sync_provider.dart`, `lib/screens/register_screen.dart`,
`lib/screens/settings_screen.dart`, `lib/services/alert_service.dart`,
`lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart`,
`lib/screens/report_screen.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`,
`supabase/migrations/20260906..._add_income_units.sql`, tests.

---

## Orden recomendado

```
F1 modelo → F2 persistencia+sync → F3 UI → F4 alerta → F5 reportes → F6 i18n+tests → F7 deploy
```
Cada fase termina con un DONE verificable.
