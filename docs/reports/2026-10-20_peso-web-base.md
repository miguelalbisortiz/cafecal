# Peso de la primera carga — medición base (Tanda 3, T1–T2)

> **Fecha:** 2026-10-20 · **Commit:** `e9c2761` (sin cambios en `lib/`) ·
> **PRD:** `docs/prds/2026-10-20_1016-peso-de-la-web.prd.md` (APPROVED) ·
> **Plan:** `docs/plans/2026-10-20-peso-de-la-web.plan.md` (READY).
> Este documento fija la línea base de SC-1, SC-2 y SC-5. **Sin este archivo la
> tanda no empieza.**

## 0. Punto de partida (T1)

| Qué | Valor |
|---|---|
| `HEAD` | `e9c2761` |
| Árbol | limpio salvo el PRD y el plan (nuevos) |
| `flutter analyze` | 0 issues |
| `flutter test` | **1046/1046** |
| Gate al cerrar T2 | **1047/1047** (entra `export_parity_test.dart`) · analyze 0 |

## 1. El comando importa: hay que pasar los `--dart-define`

`deploy.ps1` compila con dos definiciones que salen de `.env`:

```powershell
flutter build web --release --base-href=/cafecal/ `
  "--dart-define=SUPABASE_URL=$url" "--dart-define=SUPABASE_ANON_KEY=$key"
```

**Sin** los defines el mismo código pesa **4.718.092 B**; **con** los defines,
**4.818.867 B**. Cualquier medición que se compare tiene que usar los defines.
Comando reproducible (no imprime secretos):

```powershell
$map = @{}; Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([^#=]+)=(.*)$') { $map[$matches[1].Trim()] = $matches[2].Trim() }
}
flutter build web --release --base-href=/cafecal/ `
  "--dart-define=SUPABASE_URL=$($map['SUPABASE_URL'])" `
  "--dart-define=SUPABASE_ANON_KEY=$($map['SUPABASE_ANON_KEY'])"
(Get-Item build\web\main.dart.js).Length   # 4818867
```

> El plan (T2, paso 1) traía el comando sin defines. Corregido: la línea base es
> **4.818.867 B**, la del sitio publicado.

## 2. Bytes en disco del primer arranque (SC-1)

Los archivos que el navegador necesita para pintar la primera pantalla:

| Archivo | Disco (B) | gzip (B) |
|---|---:|---:|
| `main.dart.js` | 4.818.867 | 1.400.383 |
| `assets/NOTICES` | 1.842.521 | 102.484 |
| `canvaskit/canvaskit.wasm` | 6.751.354 | 2.718.269 |
| `canvaskit/canvaskit.js` | 93.469 | 29.393 |
| `assets/assets/fonts/Roboto-Regular.ttf` | 171.676 | 90.416 |
| `assets/assets/fonts/Roboto-Bold.ttf` | 170.760 | 90.954 |
| `assets/fonts/MaterialIcons-Regular.otf` | 19.808 | 11.151 |
| `flutter_bootstrap.js` | 8.469 | 3.296 |
| `flutter.js` | 8.143 | 3.149 |
| `index.html` | 1.339 | 690 |
| `manifest.json` | 988 | 326 |
| **Total del arranque** | **13.887.394** | **4.450.511** |

El build completo en disco pesa **26.723.624 B** (35 archivos): el resto son
`skwasm.*` (3,2 MB + símbolos), `canvaskit.js.symbols` (1,3 MB), `sample_pdfs/`
y `backup.html`, que **no** entran al arranque.

Notas:
- `flutter.js` figura en el build pero **no se pide**: `flutter_bootstrap.js` es
  autosuficiente.
- Los `canvaskit/*` locales existen para el service worker; en la primera visita
  el motor se baja de **gstatic** con el `engineRevision` del bootstrap
  (`b8800d8…`), no de GitHub Pages.
- `main.dart.js` es el 34,7% del peso en disco y el 31,5% del gzip.

## 3. Transferido real (compresión del servidor)

Medido con cabeceras del sitio publicado, `Accept-Encoding: gzip, br`
(`curl -sI`), que es lo que recibe un teléfono:

| Recurso | Servido | Comprimido (B) |
|---|---|---:|
| `main.dart.js` (Pages, gzip) | gzip | 1.420.811 |
| `assets/NOTICES` (Pages, gzip) | gzip | 105.009 |
| `Roboto-Regular.ttf` (Pages, gzip) | gzip | 91.002 |
| `Roboto-Bold.ttf` (Pages, gzip) | gzip | 91.581 |
| `MaterialIcons-Regular.otf` (Pages, gzip) | gzip | 11.159 |
| `index.html` | gzip | 690 |
| `flutter_bootstrap.js` | gzip | 3.298 |
| `manifest.json` | gzip | 326 |
| `canvaskit.js` (gstatic, br) | br | 26.094 |
| `canvaskit.wasm` (gstatic, br) | br | 2.140.642 |
| `flutter_service_worker.js` (solo 1ª visita) | gzip | 3.058 |
| **Total real de la primera visita** | | **≈ 3.893.670 (3,89 MB)** |

Es decir: **13,89 MB en disco, 4,45 MB con gzip propio y 3,89 MB por la red**
(el wasm se sirve en Brotli). El número que le importa al agricultor es el
tercero; el que se puede medir sin red es el primero.

## 4. Tiempo al primer arranque (SC-14, informativo)

**No hay `first-contentful-paint`:** Flutter pinta en canvas y el navegador no
emite entrada de paint. Se usa un proxy honesto y repetible: **cuándo termina de
llegar el último recurso del arranque** (`PerformanceResourceTiming.responseEnd`),
sirviendo el build a **200 KB/s (1,6 Mbps, «Fast 3G»)**.

Método (reproducible): servidor Node local en `127.0.0.1:8123` que entrega
`build/web` a 200 KB/s, `Cache-Control: no-store`; antes de cada corrida se
desregistra el service worker y se borran los caches; se mide con
`performance.getEntriesByType('resource')`.

| Corrida | `main.dart.js` termina | Último recurso |
|---|---:|---:|
| 2 | 36.988 ms | 38.466 ms |
| 3 | 37.011 ms | 37.762 ms |
| 4 | 37.023 ms | 37.784 ms |
| **Mediana** | **≈ 37,0 s** | **≈ 37,8 s** |

La primera visita (con instalación del service worker) dio 42,9 s; no se usa
para comparar. **El servidor local no comprime** (sirve 4,82 MB en vez de
1,42 MB), así que el número es pesimista frente a producción; sirve para
comparar antes/después con el mismo método, no como promesa de segundos.

## 5. Reparto por librería (D2): **NO DISPONIBLE**

`--dump-info` existe en `flutter build web -h` de 3.24, pero **no produce
nada**: se intentó dos veces (una con `-v`) y el flag nunca llega al compilador.
No queda `main.dart.js*.info.json` ni en `build/web` ni en `.dart_tool/`.

Consecuencia: no hay pastel por paquete. **Se sustituye por la medición directa
de la palanca** en T5: build de ablación con la cadena del `enum ReportPeriod`
cortada, y la diferencia contra `4.818.867 B` es exactamente lo que aporta
`package:pdf` (más lo que arrastre). Se documenta en el reporte de T5.

## 6. Conciliación con el PRD (13,4 MB vs 13,89 MB)

El «≈13,4 MB» del PRD mezclaba unidades y redondeos. La cuenta real, con bytes:

- El PRD usaba **KiB** para `main.dart.js` (4.706 KiB) y para `canvaskit.wasm`
  (6.593 KiB) y luego sumaba en **MB decimales**.
- `NOTICES`: el PRD decía 1.831 KB; el archivo real mide **1.842.521 B**
  (1.799 KiB).
- Roboto: 168 KB en el PRD; **171.676 B** el real (167,7 KiB).
- El total de 13,90 MB (suma de la tabla) **sí** coincide con los 13.887.394 B
  de esta medición: la diferencia era de presentación, no de contenido.
- `skwasm.*` (3,29 MB) queda fuera del arranque y no se suma.

## 7. Paridad del export congelada (SC-5)

`test/export_parity_test.dart` (nuevo, **verde de entrada**, guarda declarada)
con un fixture canónico: dos monedas (COP/USD), venta en cada una, inversión,
mano de obra con `harvestedKg: 60` y un cultivo sin terreno.

| Valor congelado | Hoy |
|---|---|
| Filas de la hoja de movimientos | **5** |
| Ingresos por moneda | **`COP 150.000 · USD 30,00`** |
| Gastos por moneda | **`(COP 150.000) · (USD 20,00)`** |
| Páginas del PDF | **2** (`/Type /Page` = 2 y `/Count` = 2, coinciden) |

Tamaños de referencia del fixture: PDF 19.931 B, Excel 9.066 B. No se congelan
(son dependientes del compresor); las páginas y los totales sí.

## 8. Lo que cambia el plan

1. **T2, paso 1:** el build de referencia lleva los `--dart-define` de
   `deploy.ps1`. Sin ellos se mide otro programa (4.718.092 B).
2. **T2, paso 2:** `--dump-info` no sirve en 3.24. El reparto se obtiene por
   ablación en T5; no se pierde ningún criterio del PRD.
3. **T9:** la comparación final se hace contra **4.818.867 B** (disco) y
   **37,8 s** (último recurso, 200 KB/s), no contra el 13,4 MB del PRD.

## 9. Después: la exportación se fue a su propio trozo (T5–T8)

### 9.1 El enum solo no ahorra nada (T5)

Mover `ReportPeriod` a `lib/models/report_period.dart` y cortar la cadena de
las alertas dejó `main.dart.js` **exactamente igual: 4.818.867 B (±0)**. Tiene
sentido: el enum no genera código distinto y `package:pdf` seguía entrando por
`report_screen.dart`. Es la prueba de que el ahorro no estaba en el enum sino
en **diferir**; el enum era la condición para poder hacerlo.

### 9.2 Diferir pdf y excel (T7–T8)

`report_screen.dart` ahora importa los dos servicios con `deferred as`:

- `_warmExports()` en `initState`: calienta los trozos al abrir Reportes; si
  falla, no molesta (Q2: el aviso sale al exportar).
- `_ensurePdf()` / `_ensureExcel()`: al tocar exportar reintentan; si no hay
  red, SnackBar con `exportNeedsNetworkOnce` + acción **Reintentar**. Nunca se
  genera un archivo vacío.
- `ReportPeriod` se importa del modelo, no del servicio.

| Archivo | Bytes | gzip |
|---|---:|---:|
| `main.dart.js` | **3.671.623** | 1.059.682 |
| `main.dart.js_1.part.js` | 911.664 | 259.833 |
| `main.dart.js_2.part.js` | 31.269 | 11.526 |
| `main.dart.js_3.part.js` | 217.985 | 72.924 |

**`main.dart.js`: −1.147.244 B = −23,81%** (gzip: −340.701 B = −24,3%).
El piso aprobado era −10% (≤4.336.980 B) y la aspiración −20%: **las dos se
cumplen**. Los tres trozos suman 1.160.918 B y **no se piden al arrancar**
(medido: 0 `.part.js` en la primera carga de Inicio).

Costo aceptado (D5/Q1): la primera vez que se abre Reportes se baja el trozo
(≈1,16 MB en disco, ≈344 KB gzip), una sola vez por dispositivo; después queda
en caché y la exportación funciona sin señal.

### 9.3 Primer arranque, mismo método (200 KB/s)

| | `main.dart.js` termina | Último recurso |
|---|---:|---:|
| Antes (mediana de 3) | 37.011 ms | 37.784 ms |
| Después (mediana de 3) | **28.289 ms** | **28.905 ms** |
| Diferencia | −8.722 ms (−23,6%) | −8.879 ms (−23,5%) |

Medido igual que §4: service worker desregistrado y caches borrados antes de
cada corrida, 3 corridas, mediana. El servidor local no comprime, así que los
segundos son pesimistas; la proporción es la que importa.

### 9.4 Guardas nuevas

- `test/no_pdf_in_alert_chain_test.dart` (**T4**): rojo real el 2026-10-20
  (`package:pdf/pdf.dart ← pdf_export_service.dart`), verde al mover el enum.
- `test/deferred_exports_test.dart` (**T7**): desde `lib/main.dart` no se llega
  a pdf/excel por un import normal. Su rojo es el estado anterior: el build de
  T5 todavía los tenía en el arranque.
- `test/export_parity_test.dart` (**T2**): sigue verde con los trozos; el
  contenido del PDF y del Excel no cambió.

### 9.5 Lo que falta (manual, sobre el sitio desplegado)

1. Exportar un PDF y un Excel reales y abrirlos.
2. Abrir Reportes sin señal en un dispositivo que nunca los abrió: debe salir
   el aviso con Reintentar, nunca un archivo vacío.
3. Abrir Reportes con señal y después intentar exportar sin señal: debe salir.

