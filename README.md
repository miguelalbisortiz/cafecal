# Mi Cafetal App

Control de gastos e ingresos para el cafetal. Registro rápido (~10 s), alertas en tiempo real, reportes PDF y sincronización en la nube. Offline-first: funciona sin conexión y sincroniza cuando hay internet.

## En producción

**Web (PWA instalable):** https://miguelalbisortiz.github.io/cafecal/

Instálala desde el navegador del celular (menú → "Agregar a pantalla de inicio" / "Instalar app") para usarla como app nativa, incluso sin conexión.

## Funcionalidades

- Registro de gastos e ingresos por cultivo (café, plátano, otros) y categoría
- Dashboard: gastos/ingresos del mes, balance anual, tendencia por mes, desglose por categoría
- 5 alertas automáticas: gasto excesivo, sin ventas en 60 días, balance negativo 3+ meses, precio bajo, cultivo con ROI < -30%
- Reporte mensual exportable a PDF y compartible
- Configuración: moneda (COP/USD/EUR) y nombre de la finca
- Sincronización con Supabase (cuenta email+contraseña)

## Requisitos

- Flutter 3.24+ (Dart 3.5+)
- Proyecto Supabase con el esquema de `supabase/migrations/`
- Variables de entorno (ver `.env.example`): `SUPABASE_URL` y `SUPABASE_ANON_KEY`

## Desarrollo

```sh
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Build web

```sh
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Deploy GitHub Pages

El sitio se sirve desde la rama `gh-pages` (con los archivos de `build/web` en la raíz y base href `/cafecal/`):

```sh
flutter build web --release --base-href=/cafecal/ --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# copiar build/web/* a la rama gh-pages y pushear
```

## Tests y análisis

```sh
flutter analyze
flutter test
```

## Stack

Flutter + Provider + Supabase (Postgres + Auth + RLS). Offline: shared_preferences. PDF: `pdf` + `share_plus`.