# Plan: Caja menor, trabajadores y jornales (nómina de finca)

- **Fecha**: 2026-09-24
- **Tipo**: Implementación (feature nueva)
- **Objetivo**: cubrir los rubros de nómina de la planilla física
  *"RECORDS DE FINCAS DE CAFÉ U OTROS 10 HECTÁREAS O MENOS"* que la app no
  controla hoy: **caja menor mensual**, **lista de trabajadores**, **jornales
  (pago por días trabajados)**, **cantidad de empleados**, **producción semanal
  con # de empleados**, **energía/agua** y **racimos → kilos**. Retrocompatible y
  aditivo, **sin romper** la operación vía GitHub Pages + Supabase.

---

## Decisiones de alcance (confirmadas por el usuario en la sesión)

1. **Caja menor mensual** (`settings.caja_menor_mensual`): monto destinado cada
   mes a jornales y gastos extras. **Se reinicia solo cada mes (corte por fecha
   de calendario); el saldo NO se acumula al siguiente mes.** Vacío/null =
   desactivado (no hay widget ni alerta). El control anual se ve en el reporte
   (tabla por mes).
2. **Qué descuenta de la caja = Jornales + Extras** (opción elegida por el
   usuario):
   - **Jornales**: gastos de categoría `mano_obra`.
   - **Extras**: categorías `{energia, agua, otro, mantenimiento}` (misceláneos,
     imprevistos de clima, arreglos).
   - **NO descuentan**: insumos, abonos, fertilizantes, siembra, plagas, riego,
     cosecha, empaque, transporte, arriendo, impuestos (son inversión/operación
     de producción). El set de extras es una **constante ajustable**
     (`kCashBoxExtraCategories`) si el usuario quiere sumar otra categoría.
3. **Trabajadores = lista fija** (decisión del usuario): tabla `employees`
   (nombre + valor por día opcional) + pantalla tipo "Cultivos". El historial de
   jornales guarda el **nombre como snapshot** en `transactions.provider` (sin
   FK) → borrar/renombrar un trabajador **no rompe** registros pasados; como
   contrapartida, renombrar divide el conteo histórico (aceptado a escala finca;
   vincular por id queda fuera de alcance).
4. **Jornal en el formulario de gasto**: al elegir categoría **Mano de obra**
   se despliega el bloque: trabajador (dropdown de la lista, u "otro nombre"
   libre, u opción de crear), días, valor día (autocompletado del trabajador,
   editable) y **total = días × valor día** que llena el campo Monto (readonly
   mientras el bloque está activo). Escribe `provider`, `quantity` (días),
   `unit='día'`, `pricePerUnit` → **sin migración en transactions** (campos
   Nivel 1 ya existen).
5. **Cantidad de empleados = derivada**: trabajadores distintos (`provider`)
   con gasto de mano de obra **en el período del reporte**. No se anota a mano.
6. **Producción con personal**: campo opcional **N° de empleados** en la cosecha
   (`harvests.workers`) — cumple "PRODUCCION SEMANAL # DE EMPLEADOS FECHA".
7. **Racimos → kilos**: campo opcional **"¿Cuántos kilos hacen?"** en la cosecha
   (`harvests.equivalent_kg`) visible solo si la unidad es `racimo` — más fiel a
   la planilla que un peso promedio global, porque el peso del racimo varía.
   Conversiones kg ↔ arroba ya existentes no cambian.
8. **Energía y Agua**: dos categorías de gasto nuevas (cumplen los rubricos de
   la planilla y son las que definen "extras" junto a mano de obra).
9. **Alerta de caja** (regla nueva `cajaMenor`): ≥80% del mes → `warning`;
   >100% → `danger` con sugerencia *"revisa los gastos extras y considera
   reducir trabajadores este mes"*. Sin monto configurado no evalúa.
10. **Sin periodo quincenal/semanal explícito para sueldos**: como el pago es
    **por jornal según días trabajados** (no sueldo fijo), la fecha de cada
    jornal + los reportes por semana/mes cubren "sueldos semanales o
    quinsenales" de la planilla.

**Fuera de alcance (se planifica después)**: recibos de pago PDF por empleado,
cuotas/nómina legal, saldo acumulado entre meses, vínculo por `employee_id`,
multi-caja, kilos equivalentes en ventas de racimos, deducciones de nómina.

---

## Cobertura de la planilla (rubrico → feature)

| Rubro de la imagen | Cobertura |
|---|---|
| Caja menor para sueldos designada para meses | `settings.caja_menor_mensual` + widget + alerta |
| Sueldos semanales o quinsenales | Jornales fechados (fecha + días); reportes por semana/mes |
| Cantidad de empleados | Derivada de `provider` distinct en el período |
| Gastos extras o misceláneos | Categoría `otro` (+ extras de caja) |
| Gastos de abonos e insumos (venenos, herramienta) | Categorías existentes (ya cubierto) |
| Producción semanal # de empleados + fecha | `harvests.workers` + fecha de cosecha |
| Colinos/plantados por ha + fecha (café, plátano, frutas, cacao, aguacate, maíz) | Ya cubierto (siembras + cultivos libres) |
| Racimos recojidos y cuántos kilos hacen | `harvests.equivalent_kg` (solo unidad `racimo`) |
| Café en kilos y arrobas | Ya cubierto (unidades + conversión) |
| Venta de café / plátano / frutas + fecha | Ya cubierto (categorías de ingreso) |
| Gastos de energía mensual | Categoría `energia` (nueva) + fecha |
| Gastos de agua trimestral/cada 6 meses | Categoría `agua` (nueva) + fecha (corte por período del reporte) |
| Gastos de compra de colinos de plátano / colinos | Ya cubierto (siembra con costo) |
| Gastos de árboles frutales | Ya cubierto (gasto por cultivo) |

---

## Impacto en la infraestructura actual (importante)

- **GitHub Pages**: sin cambios de hosting/URL/PWA. Solo un build web nuevo.
- **Supabase**: cambios **aditivos** (tabla `employees` + columnas en
  `settings`/`harvests` + RLS). Una migración SQL manual. Si no se aplica, la
  app **no se rompe**: lo nuevo queda solo en local.
- **Local**: campos nuevos nullable / defaults → retrocompatibles con los tests
  actuales.

---

## Fases de trabajo

### Fase 1 — Modelo de datos (`lib/models/`)

- `employee.dart` (nuevo):
  ```dart
  class Employee {
    final String id;
    final String name;
    final double? dayRate;     // valor por día (opcional)
    final bool pendingSync;
    // copyWith / toJson / fromJson (null-safe)
  }
  ```
- `settings.dart`: agregar `final double? cajaMenorMensual;`
  → `copyWith`, `toJson` (`caja_menor_mensual`), `fromJson` null-safe.
- `harvest.dart`: agregar `final int? workers;` y `final double? equivalentKg;`
  → `copyWith`, `toJson` (`workers`, `equivalent_kg`), `fromJson` null-safe.
- `categories.dart`:
  - 2 categorías nuevas: `energia` (⚡) y `agua` (🚿).
  - Helper de caja:
    ```dart
    /// Extras que descuentan de la caja menor (además de mano de obra).
    const Set<String> kCashBoxExtraCategories = {
      'energia', 'agua', 'otro', 'mantenimiento',
    };

    /// ¿Este gasto descuenta de la caja menor? Jornales + extras.
    bool discountsCashBox(String category) =>
        category == 'mano_obra' || kCashBoxExtraCategories.contains(category);
    ```
- `transaction.dart`: **sin cambios** (el jornal usa `provider`, `quantity`,
  `unit`, `pricePerUnit` existentes).
DONE: modelos compilan, serialización retrocompatible con tests.

### Fase 2 — Migración SQL + persistencia local + sync

- Migración `supabase/migrations/202609240001_add_employees_caja_menor.sql`:
  ```sql
  create table if not exists public.employees (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    day_rate numeric,
    created_at timestamptz not null default now()
  );
  -- + RLS select/insert/update/delete propias (mismo patrón que crops)
  -- + índice idx_employees_user

  alter table public.settings
    add column if not exists caja_menor_mensual numeric;

  alter table public.harvests
    add column if not exists workers integer,
    add column if not exists equivalent_kg numeric;
  ```
- `lib/services/local_store.dart`: persistir `employees` (clave
  `employees_v1`); cargar `caja_menor_mensual` en settings y
  `workers`/`equivalent_kg` en harvests.
- `lib/providers/sync_provider.dart`: upsert/select de `employees` (pending
  correspondiente); `settings` incluye `caja_menor_mensual` (si el sync de
  settings ya existe; si no, queda local como el resto de settings);
  `harvests` incluye `workers`/`equivalent_kg`.
- `lib/providers/transaction_provider.dart`: lista `employees` +
  `addEmployee`/`updateEmployee`/`deleteEmployee` (patrón de crops).
DONE: trabajadores sincronizan; sin migración en la nube todo queda local.

### Fase 3 — Pantalla Trabajadores + menú

- `lib/screens/workers_screen.dart` (nuevo): lista de trabajadores
  (nombre, valor por día, edit/eliminar), FAB "Agregar", diálogo editor
  (patrón `CropEditorDialog`). Estados vacíos con ayuda corta.
- `lib/screens/home_screen.dart`: nuevo `PopupMenuItem` "Trabajadores" →
  `WorkersScreen` (junto a Cultivos/Siembras/Cosechas).
DONE: CRUD de trabajadores funcional y persistente.

### Fase 4 — Bloque jornal en el registro de gasto

- `lib/screens/register_screen.dart`: si `type == expense` y
  `category == 'mano_obra'`, desplegar bloque "Jornal":
  - **Trabajador**: `DropdownButton` con la lista + opción *"Otro nombre…"*
    (texto libre, no guarda en la lista) + opción *"Crear trabajador"* (abre el
    diálogo). Lista vacía → hint "Crea tus trabajadores en el menú".
  - **Días** (entero > 0) y **Valor día** (autocompletado con
    `employee.dayRate`, editable).
  - **Total = días × valor día** → escribe el campo Monto (readonly con el
    bloque activo; al salir de la categoría se libera).
  - Al guardar: `provider`, `quantity`, `unit='día'`, `pricePerUnit`, `amount`.
  - Si el trabajador elegido tiene `dayRate` y no cambió, no pedir nada extra.
DONE: un jornal se registra en ~10 s con total correcto, sin migración.

### Fase 5 — Caja menor: Configuración + widget de dashboard

- `lib/screens/settings_screen.dart`: campo **"Caja menor mensual"** (numérico,
  vacío = desactivado) con help: *"Monto de cada mes para jornales y extras. Se
  reinicia solo cada 1 de mes; lo que sobre no se acumula."*
- `lib/widgets/cash_box_card.dart` (nuevo) en `home_screen` (bajo los resúmenes):
  solo si `cajaMenorMensual != null`:
  ```
  💵 Caja menor — {Mes Año}
  [████████████████░░░░] $430.000 de $600.000   (72%)
  Restante: $170.000 · Jornales: $290.000 · Extras: $140.000
  ```
  - Barra verde <80% · ámbar 80–100% · roja >100%.
  - Suma gastos del **mes en curso** con `discountsCashBox(category)`.
DONE: la barra refleja el mes en curso y se "reinicia" sola al cambiar de mes.

### Fase 6 — Alerta de caja (`alert_service.dart`)

- `AlertRule.cajaMenor` (nueva) en `farm_alert.dart`.
- `AlertService.evaluate(...)` recibe `double? cajaMensual`
  (`alert_provider.dart` pasa `settings.cajaMenorMensual`):
  - null o ≤0 → no evalúa.
  - Gastos del mes con `discountsCashBox` ≥ **80%** → `warning` con cifras
    (usado / monto / %).
  - > **100%** → `danger`: *"Caja menor agotada en {mes}: ${usado} de
    ${monto}. Sugerencia: revisa los gastos extras y considera reducir
    trabajadores este mes."*
DONE: las dos severidades disparan con datos de prueba (con tests).

### Fase 7 — Cosecha: N° empleados + racimos→kilos + reportes

- `lib/screens/harvest_screen.dart` (formulario):
  - Campo opcional **"N° de empleados"** (`workers`, entero ≥ 0).
  - Si unidad == `racimo`: campo opcional **"¿Cuántos kilos hacen?"**
    (`equivalentKg`).
- `lib/services/pdf_export_service.dart` / `excel_export_service.dart` /
  `report_screen.dart`:
  - **Sección "Nómina del período"**: tabla por trabajador (días totales,
    subtotal), total nómina, **empleados distintos del período**; solo si hay
    gastos de mano de obra.
  - **Sección "Caja menor"** (solo si hay monto configurado): una fila por mes
    dentro del período → presupuesto, jornales, extras, total, saldo
    (positivo/negativo). Un reporte mensual = 1 fila; anual = hasta 12.
  - **Cosechas**: junto a cada cosecha mostrar 👷 n empleados (si `workers`)
    y los kilos equivalentes (si `equivalentKg`).
DONE: el PDF muestra nómina, caja por mes y cosechas con personal/kilos.

### Fase 8 — i18n + Tests + validación

- `lib/l10n/app_es.arb` / `app_en.arb`: pantalla y editor de trabajadores,
  bloque jornal (días, valor día, total), caja menor (campo, widget, help),
  alerta de caja, secciones de reporte (nómina, caja), N° empleados, kilos
  equivalentes, categorías Energía/Agua.
- Tests:
  - `test/employee_test.dart`: serialización + retrocompat.
  - `test/categories_cash_box_test.dart`: `discountsCashBox` (mano de obra y
    extras sí; insumos/fertilizantes no).
  - `test/settings_test.dart`: `cajaMenorMensual` (extender).
  - `test/harvest_test.dart`: `workers` + `equivalentKg` (extender).
  - `test/alert_service_test.dart`: regla caja ≥80% warning, >100% danger, sin
    monto no evalúa, extras descuentan e insumos no.
  - `test/jornal_test.dart`: total días × valor, campos escritos en la
    transacción, empleados distintos del período.
  - `test/pdf_export_test.dart`: secciones nómina/caja presentes (extender).
  - Ajustar tests existentes si cambian constructores.
DONE: `flutter analyze` limpio, `flutter test` verde.

### Fase 9 — Build + deploy

- `flutter build web --release --base-href=/cafecal/ --dart-define=...`.
- Deploy gh-pages (robocopy a worktree `_deploy`) + main, verificar HTTP 200.
- Recordatorio: aplicar la migración SQL antes de que el sync use `employees`.
DONE: sitio accesible (HTTP 200), Ctrl+F5, trabajadores + caja + jornales vivos.

---

## Criterios de aceptación (observables)

- **AC-1**: Se crean/editan/borran trabajadores; persisten local y sincronizan;
  el historial de jornales no se afecta al borrar un trabajador.
- **AC-2**: Elegir "Mano de obra" despliega el bloque jornal; el Monto queda en
  días × valor día; la transacción guarda `provider`/`quantity`/`unit='día'`/
  `pricePerUnit`.
- **AC-3**: El widget de caja muestra el mes en curso con barra y desglose
  jornales/extras; **desaparece si no hay monto configurado**; al cambiar de mes
  el conteo arranca solo (saldo de enero no suma a febrero).
- **AC-4**: Solo `mano_obra` + `kCashBoxExtraCategories` descuentan de la caja;
  un gasto de fertilizante/insumos **no** baja la barra.
- **AC-5**: Alerta `cajaMenor` dispara `warning` a ≥80% y `danger` a >100% con
  la sugerencia de reducir trabajadores; sin monto no dispara.
- **AC-6**: El reporte muestra la tabla de caja por mes del período y la nómina
  por trabajador con el conteo de empleados distintos.
- **AC-7**: La cosecha guarda N° de empleados opcional y, si la unidad es
  `racimo`, los kilos equivalentes; el PDF los muestra.
- **AC-8**: Registros viejos (JSON sin campos nuevos) cargan sin error y con
  defaults correctos.
- **AC-9**: Las 17 categorías de gasto/ingreso disponibles incluyen Energía y
  Agua.
- **AC-10**: `flutter analyze` sin issues; `flutter test` verde.
- **AC-11**: Desplegado en GitHub Pages, HTTP 200, sigue funcionando con
  Supabase.

---

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Migración no aplicada rompe sync de `employees` | Migración aditiva y obligatoria (Fase 2). Sin ella, todo queda local; la app no se rompe. |
| Renombrar un trabajador divide el conteo histórico | Historial guarda nombre snapshot; documentado en help. Vínculo por id = futuro. |
| Set de "extras" no cubre algún imprevisto | `kCashBoxExtraCategories` es una constante de una línea; el usuario puede ampliarla. |
| Usuario edita el Monto a mano y se desincroniza del total | Monto readonly mientras el bloque jornal está activo. |
| Barra de caja confunde si el mes no está completo | Muestra siempre monto del mes calendario + help "se reinicia cada mes"; alertas solo evalúan mes en curso. |
| `equivalent_kg` no cubre ventas en racimos | Declarado fuera de alcance; se agrega después si se necesita. |
| Over-scope (recibos, cuotas legales, saldo acumulado) | Explícitamente fuera de alcance (decisión 10). |

---

## Archivos a tocar

`lib/models/employee.dart` (nuevo), `lib/models/settings.dart`,
`lib/models/harvest.dart`, `lib/models/categories.dart`,
`lib/models/farm_alert.dart` (+1 regla), `lib/services/alert_service.dart`,
`lib/services/local_store.dart`, `lib/providers/transaction_provider.dart`,
`lib/providers/sync_provider.dart`, `lib/providers/alert_provider.dart`,
`lib/screens/workers_screen.dart` (nuevo), `lib/screens/home_screen.dart`
(widget + menú), `lib/screens/settings_screen.dart`,
`lib/screens/register_screen.dart`, `lib/screens/harvest_screen.dart`,
`lib/widgets/cash_box_card.dart` (nuevo), `lib/services/pdf_export_service.dart`,
`lib/services/excel_export_service.dart`, `lib/screens/report_screen.dart`,
`lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`,
`supabase/migrations/202609240001_add_employees_caja_menor.sql`, tests.

---

## Orden recomendado

```
F1 modelo → F2 migración+sync → F3 pantalla trabajadores → F4 bloque jornal
→ F5 caja (settings+widget) → F6 alerta caja → F7 cosecha+reportes
→ F8 i18n+tests → F9 deploy
```

Cada fase termina con un DONE verificable. Respecto a los planes previos,
agrega la entidad `Employee`, 2 columnas en `harvests`, 1 campo en `settings`,
2 categorías, 1 regla de alerta, 1 widget y 2 secciones de reporte; el resto
reutiliza estructura existente (Nivel 1/2).
