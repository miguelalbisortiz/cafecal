# Plan: Capa productiva — Nivel 2 (siembra, cosechas y fase de vida del cultivo)

- **Fecha**: 2026-09-07
- **Tipo**: Implementación (feature nueva)
- **Objetivo**: registrar **siembra/resiembra** (plantas + área) y **cosechas** por
  cultivo, reconociendo su **etapa de vida** (establecimiento / producción /
  renovación), para que KPIs y alertas de dinero dejen de tratar a un plantío nuevo
  como "pérdida" y el reporte ayude a decidir con números reales. Retrocompatible y
  aditivo, **sin romper** la operación vía GitHub Pages + Supabase.
- **Diseño de datos compatible con Nivel 3** (panel KPI por hectárea, amortización)
  para no rehacerlo después.

---

## Decisiones de alcance (confirmadas por el usuario en la sesión)

1. **Cosechas por cultivo** (`Harvest`): fecha, cultivo, cantidad, unidad, destino
   (vendido / almacenado / pérdida). Registro opcional — no se exige al usuario.
2. **Siembra / plantación** (`Sowing`): evento con fecha, cultivo, **nº de plantas** y
   **área (ha)**; el costo queda en transacciones (única fuente de verdad del dinero).
   - **Perennes** (café/plátano): la siembra inicial se registra **una sola vez** y la
     plantación persiste años; solo se ajusta con resiembras o renovación (que inicia
     una siembra nueva). No se re-registra cada año.
   - **Anuales** (verduras): **cada gestión** es una siembra nueva (cada siembra abre
     la gestión; las cosechas son su resultado).
   - **Fase oculta para anuales**: si `cycle = anual`, no se muestran las fases
     establecimiento→producción→renovación (solo aplican a perennes de varios años).
3. **Resiembra** (`Sowing.kind = resiembra`): registro simple (fecha, plantas, motivo
   libre) que **suma/descuenta plantas vivas**. **Sin % de mortandad, sin predicción,
   sin clasificación de causas** — nada que complique; el motivo libre guarda el
   contexto. El costo de los plantines nuevos es un gasto normal del cultivo.
4. **Fase de vida por cultivo** (`phase`): `establecimiento` | `produccion` |
   `renovacion`. Resuelve "plantines de café: 2-3 años de solo costos antes de la
   primera cosecha" → en establecimiento/renovación la Regla 5 no marca pérdida.
5. **Ciclo** (`cycle`): `perenne` | `anual`. Informa guía y alimentará N3.
6. **Unidad preferida por cultivo** (`default_unit`): precarga la unidad al registrar
   venta y cosecha (café → arroba/saco, plátano → racimo, tomate → cajón/kg). La
   unidad por registro sigue siendo libre.
7. **Gasto relacionado**: un gasto de recogida se vincula a una cosecha
   (`transactions.harvest_id`) y el costo de una siembra puede crearse vinculado a ella
   (`transactions.sowing_id`). El dinero siempre vive en transactions.
8. **Cafetales con +3 años**: se pueden crear directamente en `produccion` con área y
   plantas vivas actuales (o sin plantas). El historial de siembra es opcional.
9. **Fechas retroactivas**: toda entidad (transacción, siembra, resiembra, cosecha)
   acepta fechas pasadas → se puede reconstruir el pasado y acumular hasta hoy; los
   reportes/alerta usan las fechas de cada evento, no la fecha de carga.
10. **Opción A (sin entidad "Temporada")**: los reportes agrupan por **rango de fechas**
    (mes, temporada, año) sobre los eventos reales. Cada gestión anual queda separada
    naturalmente por sus fechas. Si algún día se necesita "Temporada" como agrupador,
    se agrega sin romper nada.
11. **Sección "Qué hacer" en reportes**: recomendaciones derivadas del **mismo motor de
    reglas que las alertas** (coherencia garantizada): "número de hoy vs número
    comparado + acción sugerida". La app calcula y recomienda; **la decisión final es
    del usuario** (la app no sustituye el criterio de quién conoce la finca).

**Fuera de alcance (se planifica después)**: N3 formal — panel KPI por hectárea
(inversión COP/ha, margen/ha, comparativa entre lotes) y amortización del
establecimiento. Este PRD **solo deja el modelo listo** (área + plantas ya se registran)
y el cálculo básico de rendimiento por área para que N3 no requiera redesign.

---

## Impacto en la infraestructura actual (importante)

- **GitHub Pages**: sin cambios de hosting/URL/PWA. Solo un build web nuevo.
- **Supabase**: cambios **aditivos** (columnas nuevas + tablas `sowings` y `harvests` +
  RLS). Una migración SQL manual. Si no se aplica, la app **no se rompe**: las entidades
  nuevas y los campos extra quedan solo en local.
- **Local**: nuevos campos nullable / nuevos defaults → retrocompatibles con los 58 tests.

## Problema que resuelve (por qué `phase` existe)

Hoy la **Regla 5** (`_checkDeficitCrop`, `lib/services/alert_service.dart:253`) calcula
(Ingresos − Gastos) / Gastos por cultivo y alerta "danger" si cae por debajo de −30 %.
Un cafetal en establecimiento tiene gastos ($1.5M de vivero y tierra) y cero ingresos →
la app gritaría "pérdida de −100 %". Financieramente cierto, pero **engañoso**: es
inversión, no pérdida operativa. Con `phase`:

- En `establecimiento` / `renovacion`, Regla 5 **no dispara danger**: emite una alerta
  `info` de guía ("inversión de $1.500.000 en café; es normal no tener ingresos en esta
  etapa, primera cosecha esperada al llegar a producción").
- En `produccion`, Regla 5 se comporta como hoy.
- **Conciliación**: si vendés más kg de los que cosechaste (+10 % de margen, últimos 12
  meses) → alerta `warning` "vendiste más de lo que cosechaste: revisá inventario
  almacenado o un error de registro".

**Regla de oro (adoptada en la sesión)**: el modelo **no convierte plantines a kg ni
predice rendimientos**. El kg solo aparece donde se mide (cosecha/venta); los KPIs
(kgs por área, por planta) son **divisiones de datos medidos** acumulados a hoy, nunca
una estimación. Nada asume que las gestiones se repiten: cada año es distinto y el
sistema lo refleja en acumular lo real.

---

## Fases de trabajo

### Fase 1 — Modelo de datos (`lib/models/`)
- `crop.dart`: agregar campos (retrocompatible, con defaults):
  ```dart
  enum CropPhase { establecimiento, produccion, renovacion }   // default produccion
  enum CropCycle { perenne, anual }                            // default perenne
  final CropPhase phase;         // si cycle==anual la UI no la muestra
  final CropCycle cycle;
  final String? defaultUnit;     // 'kg' | 'arroba' | 'saco' | 'racimo' | 'cajon'...
  final double? areaHa;          // estado actual del cultivo (área)
  final int? livePlants;         // estado actual (plantas vivas)
  ```
  `fromJson` de registros viejos (sin claves) → defaults; `pending_sync` se conserva.
- `units.dart` (nuevo, compartido): extraer `_unitToKg` de `alert_service.dart`:
  ```dart
  double unitToKg(String? unit) => switch (unit) {
    'arroba' => 12.5, 'saco' => 70, _ => 1 };
  ```
  Lo usan alert_service, harvest, sowing y reportes (evita duplicados → desync).
- `harvest.dart` (nuevo): `Harvest` { id, cropId, date, amount, unit, destination,
  pendingSync } con `copyWith`, `toJson`, `fromJson` (null-safe). `destination`:
  `'vendido' | 'almacenado' | 'perdida'` (enum `HarvestDestination`).
- `sowing.dart` (nuevo): `Sowing` { id, cropId, date, kind, plants, areaHa?, reason?,
  pendingSync } con `copyWith`, `toJson`, `fromJson` (null-safe). `kind`:
  `'siembra' | 'resiembra'` (enum `SowingKind`). Al guardar, actualiza
  `crop.livePlants` (y `crop.areaHa` si es `siembra` con área); los eventos previos
  con fecha retroactiva se acumulan en orden.
- `transaction.dart`: agregar `final String? harvestId;` y `final String? sowingId;`
  nullable → `copyWith`/`toJson` (`harvest_id`, `sowing_id`)/`fromJson` null-safe.
  Default null → retrocompatible.
DONE: modelos compilan, serialización retrocompatible con tests.

### Fase 2 — Migración SQL + persistencia local + sync
- Migración `supabase/migrations/20260907..._add_sowings_harvests.sql`:
  ```sql
  alter table public.crops
    add column if not exists phase text not null default 'produccion'
      check (phase in ('establecimiento','produccion','renovacion')),
    add column if not exists cycle text not null default 'perenne'
      check (cycle in ('perenne','anual')),
    add column if not exists default_unit text,
    add column if not exists area_ha numeric,
    add column if not exists live_plants integer;

  create table if not exists public.sowings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    crop_id uuid null references public.crops(id) on delete set null,
    kind text not null default 'siembra'
      check (kind in ('siembra','resiembra')),
    plants integer not null check (plants > 0),
    area_ha numeric,
    reason text,
    sowing_date date not null,
    created_at timestamptz not null default now()
  );
  -- + RLS select/insert/update/delete propias (mismo patrón que crops/transactions)
  -- + índice idx_sowings_user_date

  create table if not exists public.harvests (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    crop_id uuid null references public.crops(id) on delete set null,
    amount numeric not null check (amount > 0),
    unit text not null default 'kg',
    destination text not null default 'vendido'
      check (destination in ('vendido','almacenado','perdida')),
    harvest_date date not null,
    created_at timestamptz not null default now()
  );
  -- + RLS select/insert/update/delete propias + índice idx_harvests_user_date

  alter table public.transactions
    add column if not exists harvest_id uuid references public.harvests(id) on delete set null,
    add column if not exists sowing_id uuid references public.sowings(id) on delete set null;
  ```
  Nota: `crops.id` y `transactions.crop_id` son `uuid` en la nube → sowings/harvests
  referencian `crops(id)` con el mismo id que ya usa el sync de transactions.
- `lib/services/local_store.dart`: persistir `harvests` (clave `harvests_v1`) y
  `sowings` (clave `sowings_v1`); cargar los campos nuevos de crops/transactions.
- `lib/providers/sync_provider.dart`: upsert/select de `harvests` y `sowings` (pending
  correspondiente), `crops` incluye `phase/cycle/default_unit/area_ha/live_plants`,
  `transactions` incluye `harvest_id/sowing_id`.
DONE: cosechas/siembras/fase sincronizan; si la nube no tiene la migración, todo queda local.

### Fase 3 — UI de cultivos (fase/ciclo/unidad/área/plantas)
- Editor de cultivo (crear/editar, `lib/screens/` + `transaction_provider.dart`):
  - **Fase** en 3 pasos (selector segmentado): Establecimiento → Producción →
    Renovación. **Oculta si `cycle = anual`**.
  - **Ciclo**: Perenne / Anual.
  - **Unidad preferida**: selector de unidades (mismo catálogo que Nivel 1) o "sin
    preferencia".
  - **Área (ha)** y **plantas vivas** editables (estado actual) — permite cargar un
    cafetal ya establecido directamente en producción, o corregir un conteo.
  - Tooltip de ayuda: "Establecimiento = plantío joven que aún no produce (plantines).
    La app no te marcará pérdidas en esta etapa."
DONE: se puede cambiar fase/ciclo/unidad/área/plantas y esto se refleja en alertas/KPIs.

### Fase 4 — UI de siembra + cosechas + vínculo de gasto
- Pantalla `SowingScreen` (nueva): lista de siembras/resiembras con editar/eliminar.
- Registro de siembra: fecha, cultivo, tipo (inicial/resiembra), plantas, área (solo
  inicial), motivo (solo resiembra, libre), costo opcional → **crea un gasto vinculado**
  (`transaction.sowingId`). Admite **fechas pasadas** (reconstrucción retroactiva).
  Al guardar, recalcula `crop.livePlants` y `crop.areaHa` acumulando los eventos en
  orden cronológico.
- Pantalla `HarvestScreen` (nueva): lista de cosechas del período con editar/eliminar.
- Registro de cosecha: fecha, cultivo, cantidad, unidad (precargada con
  `crop.defaultUnit`), destino (vendido/almacenado/pérdida). Validación: cantidad > 0.
  Admite fechas pasadas.
- `register_screen.dart` (gasto): selector opcional "Vincular a cosecha" — precargado
  con las cosechas recientes del mismo cultivo; al seleccionarlo escribe
  `transaction.harvestId`. (La recogida se paga como gasto normal; la cosecha es quien
  "recibe" el costo.)
DONE: se registran siembras/resiembras y cosechas (incl. retroactivo), se asocia el
    pago de recogida, todo en local.

### Fase 5 — Alertas de N2 (`lib/services/alert_service.dart`)
- Refactor: `_unitToKg` → `units.dart`; `evaluate` recibe `List<Harvest>` (vacío OK).
- **Regla 5 calibrada por fase**: `_checkDeficitCrop` consulta `crop.phase`; si es
  `establecimiento`/`renovacion` → en lugar del danger emite `info` `cropEstablishment`
  (regla nueva `AlertRule.cropEstablishment`): inversión actual del cultivo + "es normal
  no tener ingresos en esta etapa". En `produccion` → comportamiento actual.
- **Regla nueva: conciliación venta vs cosecha** (`AlertRule.harvestVsSales`,
  `warning`): por cultivo, últimos 12 meses,
  `kgVendidos` (qty de ventas `venta_*` normalizado con `unitToKg`) vs
  `kgCosechados` (suma de amount de cosechas normalizado); si `kgVendidos >
  kgCosechados * 1.1` y ambos > 0 → alerta con ambos números y acción sugerida.
- **Regla nueva (info): siembra/resiembra reciente** (`AlertRule.cropRecentlyPlanted`):
  si se registró una siembra/resiembra en los últimos 15 días → recordatorio de
  actualizar plantas vivas si el conteo no coincide. Leve, informativa.
DONE: un plantío en establecimiento ya no dispara "pérdida"; la conciliación avisa
    cuando se vende más de lo cosechado (con tests).

### Fase 6 — Reportes (PDF/Excel) + "Qué hacer"
- `pdf_export_service.dart` / `excel_export_service.dart` / `report_screen.dart`:
  - **Agrupación por rango de fechas** (opción A): mes, temporada, año — sin entidad
    "Temporada".
  - Sección "Cosechas": cantidad total por cultivo en su unidad y normalizada a kg, y
    por destino.
  - **Costo de recogida por kg**: gastos vinculados (`harvest_id != null`) ÷ kg
    cosechados.
  - **Costo total por kg**: gastos del cultivo ÷ kg cosechados (solo fase producción;
    en establecimiento se muestra inversión acumulada, no costo por kg).
  - **Rendimiento básico por área y por planta**: `kg cosechados ÷ areaHa` y
    `kg cosechados ÷ livePlants` (etiquetado "aproximado" si hubo resiembras). Solo en
    fase producción o con datos medidos.
  - Tarjeta "Vendido vs cosechado" por cultivo (misma lógica de la Regla de conciliación).
  - **Sección "Qué hacer"**: recomendar 2-4 acciones derivadas de las reglas de alerta
    (numeradas, con la cifra actual vs comparada y la acción sugerida). Si no aplica
    ninguna, se omite. Front: mismo motor que alertas → coherencia garantizada.
DONE: el reporte muestra kg, destinos, costo por kg, rendimiento por área/planta y
    recomendaciones accionables.

### Fase 7 — i18n + Tests + validación
- `lib/l10n/app_es.arb` / `app_en.arb`: fase, ciclo, unidad preferida, área, plantas
  vivas, registrar siembra/resiembra, motivo, cosecha, destino, vincular a cosecha,
  costo por kg, conciliación, rendimiento por área/planta, "Qué hacer",
  guía de establecimiento.
- Tests:
  - `test/harvest_test.dart`: serialización + destino + fecha retroactiva.
  - `test/sowing_test.dart`: serialización, kind, actualización de `livePlants` y
    `areaHa` acumulando eventos retroactivos en orden.
  - `test/crop_test.dart`: fase/ciclo/unidad/área/plantas con JSON viejo (retrocompat).
  - `test/alert_service_test.dart`: Regla 5 en establecimiento (info, no danger),
    conciliación venta vs cosecha (dispara / no dispara), aviso de siembra reciente.
  - `test/units_test.dart`: `unitToKg`.
  - `test/report_recommendations_test.dart`: la sección "Qué hacer" coincide con las
    alertas activas (misma regla de derivación).
  - Ajustar tests existentes si cambian constructores.
DONE: `flutter analyze` limpio, `flutter test` verde (58 + nuevos).

### Fase 8 — Build + deploy
- `flutter build web --release --base-href=/cafecal/ --dart-define=...`.
- Deploy gh-pages (robocopy a worktree `_deploy`) + main, verificar HTTP 200.
- Recordatorio: aplicar la migración SQL antes de que el sync use `sowings`/`harvests`.
DONE: sitio accesible (HTTP 200), Ctrl+F5, app funciona + siembras/cosechas/fases.

---

## Criterios de aceptación (observables)

- **AC-1**: Un cultivo en `establecimiento` con solo gastos emite alerta `info` de guía y
  **no** la "danger" de pérdida de la Regla 5.
- **AC-2**: Un cultivo en `produccion` conserva el comportamiento actual de la Regla 5;
  un cultivo `anual` no muestra fases en la UI.
- **AC-3**: Se registra una cosecha (fecha, cultivo, cantidad, unidad, destino) y persiste
  localmente; al recargar sigue lista. Las **fechas pasadas** se acumulan correctamente.
- **AC-4**: Un gasto de recogida se vincula a una cosecha (`harvest_id`) y ese gasto se
  mueve con la cosecha al eliminarla (on delete set null).
- **AC-5**: Una **siembra inicial** fija plantas/área y una **resiembra** ajusta
  `livePlants`; el orden cronológico define el resultado aunque se carguen retroactivo.
- **AC-6**: Un cafetal existente (+3 años) se crea en `produccion` con área y plantas
  actuales, sin requerir siembras históricas.
- **AC-7**: La Regla de conciliación dispara cuando los kg vendidos superan los kg
  cosechados +10 % (12 meses) y no dispara en el resto.
- **AC-8**: El reporte PDF/Excel muestra, por rango de fechas: cosechas (kg y destino),
  costo de recogida por kg, costo total por kg (producción), rendimiento kg/ha y kg/planta
  (con corte "aproximado" si hubo resiembras).
- **AC-9**: La sección "Qué hacer" del reporte es coherente con las alertas activas
  (misma regla de derivación, cubierta por test).
- **AC-10**: Registros y cultivos viejos (JSON sin los campos nuevos) cargan sin error y
  con defaults correctos.
- **AC-11**: `flutter analyze` sin issues; `flutter test` verde.
- **AC-12**: Desplegado en GitHub Pages, HTTP 200, sigue funcionando con Supabase.

---

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Migración no aplicada en la nube rompe el sync de `sowings`/`harvests` | Migración aditiva y obligatoria (Fase 2). Si no se aplica, todo queda local; la app no se rompe. |
| Amortiguar Regla 5 en establecimiento oculta una pérdida real | Al pasar a producción la Regla 5 vuelve completa; la alerta `info` muestra la inversión acumulada para que el usuario juzgue. |
| Dato de cosecha inexacto (kg no pesados) | Unidad por cultivo + registro libre; los KPIs de kg son aproximados y se documentan así en reportes. |
| Kg/planta engañoso si hubo resiembras | Usa `livePlants` actuales y etiqueta "aproximado" ante resiembras; no simula mortalidad ni mezcla ratios. |
| Conciliación con falsos positivos por inventario inicial | Margen +10 % y solo si ambos totales > 0; severidad `warning` reversible. |
| Datos retroactivos con memoria parcial | La app no inventa valores; el rendimiento por área (con área + cosechas) es confiable; el de planta depende de la precisión de `livePlants`. |
| Over-scope (entidad Temporada, simulación, % mortandad) | Descartados explícitamente (decisión 10 y regla de oro); opción A agrupa por fechas sin entidad nueva. |
| `crops.id` uuid vs id local de texto | Se reutiliza el mapeo ya existente del sync de transactions; sowings/harvests usan el mismo id remoto. |

---

## Archivos a tocar

`lib/models/crop.dart`, `lib/models/units.dart` (nuevo), `lib/models/harvest.dart`
(nuevo), `lib/models/sowing.dart` (nuevo), `lib/models/transaction.dart`,
`lib/models/farm_alert.dart` (3 reglas nuevas), `lib/services/alert_service.dart`,
`lib/services/local_store.dart`, `lib/providers/transaction_provider.dart`,
`lib/providers/sync_provider.dart`, `lib/screens/sowing_screen.dart` (nuevo),
`lib/screens/harvest_screen.dart` (nuevo), `lib/screens/register_screen.dart`,
`lib/screens/*_crop*.dart` (editor de cultivo), `lib/services/pdf_export_service.dart`,
`lib/services/excel_export_service.dart`, `lib/screens/report_screen.dart`,
`lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`,
`supabase/migrations/20260907..._add_sowings_harvests.sql`, tests.

---

## Orden recomendado

```
F1 modelo → F2 migración+sync → F3 UI cultivos → F4 UI siembras+cosechas → F5 alertas → F6 reportes+Qué hacer → F7 i18n+tests → F8 deploy
```
Cada fase termina con un DONE verificable. Frente al N1 se agregan las entidades
`Sowing` y `Harvest`, la fase/regla de conciliación, la sección "Qué hacer" y la
reconstrucción retroactiva; el tamaño estimado es ligeramente superior al del Nivel 1
(una entidad extra).