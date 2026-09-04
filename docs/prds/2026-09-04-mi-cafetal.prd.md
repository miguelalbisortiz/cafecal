# PRD: Mi Cafetal — Control de Gastos e Ingresos

- **Fecha**: 2026-09-04
- **Ubicación**: raíz de `D:\proyecto\calcafe` (coexiste con carpetas del pack `.opencode/`, `.agents/`)
- **Base de la idea**: análisis de `CafeClimate` en `C:\Users\MKY\Documents\newcafe` (servicios `cost_service.dart`, `economic_service.dart`, `seedling_service.dart`)

---

## 1. Problema

El caficultor necesita saber **cuánto gasta, en qué gasta, cuánto ingresa y si está ganando o perdiendo** — por lote y por cultivo — para tomar decisiones durante el ciclo y al final del año. CafeClimate es demasiado complejo (233 archivos, 7 módulos, ML, clima) para esa necesidad puntual.

## 2. Solución

App **"Mi Cafetal"** — Flutter (web PWA + móvil), solo 4 pantallas, registro en 10 segundos, offline-first, 100% gratis de hosting.

## 3. Decisiones confirmadas (con el dueño)

| Decisión | Valor |
|---|---|
| Ubicación | Raíz `D:\proyecto\calcafe` (pack coexiste) |
| Usuarios | Dueño registra + contador/socio consulta |
| Conectividad | Offline first (SQLite) + sync nube |
| Plataforma | Flutter web PWA + Android (mismo código) |
| Escala | 1 parcela; multi-cultivo (café, plátano, otros) |
| Registro | Gastos + ingresos + balance |
| Decisiones | Alertas en tiempo real |
| Moneda | Configurable (default COP) |
| Auth | Email + contraseña (Supabase Auth) |
| Sync | Supabase Free (500 MB, 2 proyectos) |
| Hosting | GitHub Pages o Netlify ($0) |
| Dominio | `usuario.github.io/mi-cafetal` o `mi-cafetal.netlify.app` |

## 4. Funcionalidades (MVP)

### P1 — Obligatorio
1. **Registro de transacción** (gasto/ingreso): cultivo, categoría, monto, descripción, fecha. 10 segundos.
2. **Dashboard**: totales mensual/año, balance, gastos por categoría (barras/fl_chart), gastos por cultivo.
3. **Alertas en tiempo real** (16 reglas, ver §6).
4. **Reporte exportable**: resumen período, por cultivo, PDF + compartir.
5. **Auth** email/password (Supabase).
6. **Sync** nube automático + funcionamiento offline (SQLite local).

### P2 — Segunda iteración
7. Gráfica de tendencia mensual (gastos vs ingresos).
8. Comparativa con año anterior.
9. Multi-lote (varias parcelas por usuario).
10. Recordatorios de registro.

### P3 — Futuro
11. Aviso de precio del café (lógico, sin API de bolsa).
12. Cálculo de rendimiento esperado (importar servicio de CafeClimate).
13. Exportar/importar respaldo completo.

## 5. Pantallas de la app

```
1. REGISTRAR     2. DASHBOARD      3. TENDENCIA     4. REPORTE
   rápido          una mirada        mes a mes        para socio
```

## 6. Motor de alertas

| Alerta | Trigger | Acción |
|---|---|---|
| Gasto excesivo | Categoría > 2× promedio histórico | "Revisar gasto en X" |
| Sin ingresos | 60 días sin registrar venta | "Registrar última cosecha" |
| Balance negativo | Gastos > Ingresos 3+ meses seguidos | "Revisar costos operativos" |
| Precio bajo | Precio venta < promedio histórico | "Considerar vender después" |
| Cultivo deficitario | ROI < -30% en algún cultivo | "Evaluar continuar con X" |

## 7. Stack

| Componente | Tecnología |
|---|---|
| UI | Flutter (^3.24) |
| Estado | Provider |
| Charts | fl_chart |
| DB local | sqflite / drift (offline) |
| Backend | Supabase (auth + Postgres + RLS) |
| Sync | supabase_flutter realtime (cuando hay conexión) |
| Export | pdf + share_plus |
| Hosting | GitHub Pages / Netlify (gratis) |

## 8. Modelo de datos

```sql
-- Cultivos (café, plátano, otro)
crops (id uuid pk, user_id uuid fk, name text, icon text, color text)

-- Transacciones (gastos e ingresos)
transactions (
  id uuid pk,
  user_id uuid fk,
  crop_id uuid fk null,
  type text check ('expense','income'),
  category text,          -- enum libre con autocomplete
  amount numeric,
  currency text default 'COP',
  description text,
  txn_date date,
  created_at timestamptz default now()
)

-- Config
settings (user_id uuid pk, farm_name text, currency text, base_currency text)
```

RLS: cada usuario solo ve sus filas. El socio comparte mediante un segundo usuario (invitación opcional en P2).

## 9. Alertas de no-alcance (MVP)

- Sin dashboard de clima, sin ML de rendimiento, sin mapas.
- Sin multi-lote en v1 (solo categorías por cultivo).
- Sin invitaciones a socios en v1 (el socio usa su propia cuenta; el dueño comparte el PDF).

## 10. Éxito / criterios de aceptación

1. Registrar un gasto toma ≤10 segundos.
2. Dashboard suma correctamente por categoría, cultivo y mes.
3. Las 5 reglas de alerta disparan con datos de prueba.
4. Funciona offline (sin internet) y sincroniza al reconectar.
5. El reporte PDF sale con resumen y desglose.
6. `flutter build web --release` compila sin errores.
7. Desplegado gratis en GitHub Pages/Netlify con enlace accesible desde celular.