# Plan: Mi Cafetal — Desarrollo

- **Fecha**: 2026-09-04
- **PRD**: `docs/prds/2026-09-04-mi-cafetal.prd.md`
- **Objetivo**: MVP funcional desplegado gratis en ≤ 4 fases de trabajo

---

## Fase 0 — Setup (pre-requisitos, manual + agente)

| # | Tarea | Detalle |
|---|---|---|
| 0.1 | Confirmar Flutter SDK instalado | `flutter --version` (≥ 3.24) |
| 0.2 | Crear estructura Flutter en raíz | `flutter create . --project-name mi_cafetal --platforms web,android,ios` |
| 0.3 | Verificar que pack coexiste | `.opencode/`, `.agents/`, `docs/` intactos |
| 0.4 | Init git para la app (un solo repo) | ✅ **DECIDIDO (2026-09-04)**: monorepo. Repo existente; `origin` apunta a `https://github.com/miguelalbisortiz/cafecal.git`; el pack quedó como `pack-upstream` (`marchelero/open`). |
| 0.5 | Cuentas gratis listas | ✅ Dueño ya tiene GitHub y Supabase. Supabase URL + anon key van en `.env` (fuera de git) al arrancar Fase 1. |

**Decisión 0.4 (registrada)**: monorepo simple. Commits del pack y la app viven en `miguelalbisortiz/cafecal`. Deploy a GitHub Pages desde ese repo.

## Fase 1 — Esqueleto + Auth + Base de datos

Tareas:
1. `pubspec.yaml`: agregar `supabase_flutter`, `provider`, `fl_chart`, `intl`, `sqflite`, `pdf`, `share_plus`, `path_provider`.
2. `lib/main.dart`: inicializa Supabase (URL + anon key desde `.env`/`--dart-define`), `MultiProvider`.
3. Pantalla `AuthScreen`: email + contraseña (login/registro).
4. `lib/services/supabase_service.dart`: Singleton (patrón de CafeClimate).
5. Migraciones SQL iniciales: tablas `crops`, `transactions`, `settings` + RLS.
6. `lib/providers/transaction_provider.dart`: CRUD local (SQLite) + modelo `Transaction`.
7. `lib/providers/sync_provider.dart`: sincroniza SQLite ↔ Supabase cuando hay conexión.
8. `lib/models/transaction.dart`, `crop.dart`, `settings.dart`.

**DONE cuando**: usuario se registra/entra, crea un lote, registra un gasto y aparece en lista local y en Supabase.

## Fase 2 — Núcleo de registro + Dashboard

Tareas:
1. `RegisterScreen`: form de 10 segundos (tipo, cultivo, categoría, monto, descripción, fecha).
2. Categorías predefinidas con autocomplete (Siembra, Fertilizante, Mano de obra, Plagas, Riego, Transporte, Equipo, Venta café, Venta plátano, Otro).
3. `DashboardScreen`:
   - Tarjetas: gasto mes, gasto año, ingreso año, balance.
   - Barras por categoría (fl_chart).
   - Barras por cultivo.
4. Selector de período (mes/año).

**DONE cuando**: registro guarda local+remoto y dashboard suma correcto con datos de prueba.

## Fase 3 — Alertas en tiempo real

Tareas:
1. `lib/services/alert_service.dart`: 5 reglas del PRD.
2. `AlertProvider`: evalúa reglas al registrar y cada apertura.
3. Banner de alertas en Dashboard (color según severidad).
4. Pruebas unitarias del motor de alertas con datos de prueba.

**DONE cuando**: las 5 reglas disparan/NO disparan correctamente con datasets de prueba.

## Fase 4 — Reporte + Exportación + Deploy

Tareas:
1. `ReportScreen`: resumen período (gastos, ingresos, balance, % gasto/ingreso) + desglose por cultivo + ROI por cultivo.
2. Exportación PDF (`pdf` package) + botón compartir (`share_plus`).
3. `PaymentScreen`/`SettingsScreen`: moneda configurable, nombre de finca.
4. PWA: manifiesto + service worker (flutter build web ya lo genera), icono instalable.
5. Deploy gratis:
   - GitHub Pages: `flutter build web --release`, subir `build/web` a `gh-pages`.
   - O Netlify (`mi-cafetal.netlify.app`): build + deploy automático desde GitHub.
6. Verificación final: acceder desde celular, instalar como PWA, probar offline.

**DONE cuando**: enlace accesible, PWA instalable, reporte PDF funciona, offline funcional.

---

## Orden de trabajo recomendado

```
Fase 0 → Fase 1 → Fase 2 → Fase 3 → Fase 4
 (setup)  (base)   (núcleo) (alertas) (reporte+deploy)
```

Cada fase termina con un **DONE** verificable. Las fases 1-4 son 100% automatizables por agentes.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Supabase free se pausa con 1 semana inactiva | App offline-first: se usa el local mientras; al entrar se "despierta" con realtime. Documentar en README. |
| Repo raíz del pack vs app mezclados | Mantener `.opencode/` y `.agents/` intactos; la app usa raíz `lib/`, `pubspec.yaml`; decidir monorepo en Fase 0. |
| sqflite no aplica en web | En web usar `shared_preferences`/`IndexedDB` (drift soporta web; evaluar en Fase 1). |
| RLS mal configurada filtra datos entre usuarios | Pruebas de RLS explícitas en Supabase (2 usuarios, datos aislados). |

## Tiempo estimado (agentes)

- Fase 1: 1 sesión
- Fase 2: 1 sesión
- Fase 3: 1 sesión
- Fase 4: 1-2 sesiones

Total: **4-5 sesiones de trabajo** para MVP desplegado.