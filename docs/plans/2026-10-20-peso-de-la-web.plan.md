---
prd: docs/prds/2026-10-20_1016-peso-de-la-web.prd.md
status: READY
created: 2026-10-20
updated: 2026-10-20
---

# Peso de la primera carga de la web — Tanda 1 · plan de implementación

> De dónde sale: `docs/prds/2026-10-20_1016-peso-de-la-web.prd.md` (**APPROVED**,
> Q1–Q5 respondidas el 2026-10-20 y D1–D13 cerradas).
> Este documento **no implementa nada**: es el plan para ejecutar la tanda.
> Estado **READY** (misma convención que `2026-10-19-kilos-recolectados-jornal.plan.md`):
> listo para arrancar, sin cambios de código, a la espera del visto bueno del usuario.

## 1. Objetivo

Sacar del **grafo inicial** de la web (lo que se descarga antes del primer frame) la
maquinaria de exportación —`package:pdf`, `package:excel` y los dos servicios que los
usan— para que un agricultor con mala señal llegue antes a su Inicio, **sin** cambiar
píxeles, **sin** tocar datos/sync/respaldo y **sin** prometer un byte que no se haya
medido antes.

El ahorro se compra en dos pasos, y el orden no es negociable:

1. **Romper la cadena del enum** (D3). Hoy `package:pdf` entra por las **alertas**, con
   esta vuelta completa:

   ```
   alert_service.dart:16 → report_payroll_metrics.dart:4 → pdf_export_service.dart:4-5 → package:pdf
   pdf_export_service.dart:19 → alert_service.dart        (¡vuelve!)
   ```

   Es un **ciclo** de imports: `alert_service → report_payroll_metrics → pdf_export_service
   → alert_service`. Mientras exista, dart2js no puede diferir `pdf_export_service.dart`
   (la librería diferida quedaría alcanzable desde el library inicial) y `ReportPeriod`,
   declarado dentro de ese archivo, se usa como tipo fuera de él (`report_screen.dart:557`).

2. **Diferir la exportación** (D4/D5): `deferred as` + `loadLibrary()` al tocar exportar,
   con calentamiento silencioso al abrir Reportes.

## 2. Alcance

### Entra

- `lib/models/report_period.dart` (nuevo): recibe `enum ReportPeriod`.
- Reapuntar los imports del enum en `lib/`, en **11 tests** y en **4 scripts de `tool/`**
  (ver §4, T5). Sin shim de re-export.
- `deferred as` de `pdf_export_service.dart` y `excel_export_service.dart` en
  `report_screen.dart`, con `loadLibrary()` en los tres puntos de exportación
  (`_export`, `_exportExcel`, `_exportBalance`) y calentamiento en `initState`.
- Copy ES/EN `exportNeedsNetworkOnce` + `flutter gen-l10n`.
- Tests nuevos: paridad de exportación, neutro del enum, grafo de imports, contrato del
  diferido, mensaje sin red, copy.
- Reportes de medición en `docs/reports/`.

### No entra (del PRD)

- Renderer (`canvaskit` se queda), `assets/NOTICES`, `assets/fonts/`, `fl_chart`.
- Compresión propia, CDN, `--pwa-strategy`, service worker a mano, `dart2wasm`.
- `deploy.ps1` (salvo leer su log), `pubspec.yaml`, `web/index.html`.
- Datos, sync, respaldo, Supabase, modelos existentes.
- Rediseño de Reportes: botones, textos y orden no se mueven.

### Reglas de ejecución

1. **TDD real.** Cada tarea que toca `lib/` escribe primero su test y registra el **rojo**
   con el comando y la línea de fallo. El rojo se pega en
   `docs/reports/2026-10-20_peso-web-rojo.md`.
2. **No se fabrica un rojo.** Las tareas que solo miden o que solo agregan guardas sobre
   código ya existente se declaran **guarda** o **instrumento** y se dice explícitamente
   que no tienen rojo posible.
3. **Gate por fase:** `C:\flutter\bin\flutter.bat analyze` (proyecto entero, `tool/`
   incluido) + `C:\flutter\bin\flutter.bat test`. Baseline verificado hoy:
   **0 issues / 1046 pruebas en verde**.
4. **Stageo explícito**, archivo por archivo. Nunca `git add -A` ni `git add .`.
   **Ningún `commit` ni `push` sin el verbo del usuario en ese turno.**
5. **Copy ES y EN.** `lib/l10n/app_es.arb` es el template; después de tocar ARB se corre
   `C:\flutter\bin\flutter.bat gen-l10n` y se commitea `lib/l10n/generated/`.
6. **No se inventa un número.** Cada fase cierra con bytes antes / después / delta. Si una
   fase no baja bytes, se documenta y se decide si se revierte (D12).
7. **El service worker no se edita a mano** y no se precargan partes en el arranque (D5).
8. **Una sola fuente de verdad del enum.** `ReportPeriod` vive en `lib/models/` y **no**
   se re-exporta desde el PDF: un tipo de dominio no puede depender de un generador.

## 3. Evidencia verificada antes de escribir este plan

> Todo lo de esta tabla se comprobó en el árbol de trabajo el 2026-10-20, no se copió del
> PRD. Donde el PRD y el árbol discrepan, manda el árbol y se anota.

| Hecho | Cómo se verificó | Resultado |
|---|---|---|
| Commit de partida | `git rev-parse --short HEAD` | `e9c2761`, árbol limpio salvo el PRD sin trackear |
| Gate base | `flutter analyze` + `flutter test` | **0 issues**, **1046/1046**, `All tests passed!` |
| Tamaño del bundle | `(Get-Item build\web\main.dart.js).Length` | **4.818.867 B** (coincide con SC-1) |
| El ciclo que bloquea el diferido | grep de imports en `lib/` | `alert_service→report_payroll_metrics→pdf_export_service→alert_service` (confirmado) |
| Quién importa el PDF | grep `pdf_export_service` en `lib/` | solo `report_screen.dart:25` |
| Quién importa el Excel | grep `excel_export_service` en `lib/` | solo `report_screen.dart:24` |
| Usos de los servicios | grep `PdfExportService\|ExcelExportService` | 3: `report_screen.dart:1758,1809,1861` |
| Consumidores del enum | grep `ReportPeriod` en `test/` y `tool/` | **11 tests** + **4 scripts de `tool/`** (T5) |
| `--dump-info` en 3.24 | `flutter build web -h` | existe ("generates ... a .js.info.json file") |
| Renderer declarado | grep en `build\web\flutter_bootstrap.js` | `"renderer":"canvaskit"` (1 ocurrencia) |
| Origen de canvaskit | lógica `I(i,t)` + `buildConfig` del bootstrap generado | `engineRevision` presente y `useLocalCanvasKit` ausente + `--web-resources-cdn` (default on) → **se pide a `www.gstatic.com`**, no a `build/web/canvaskit` |
| `NOTICES` real | `(Get-Item build\web\assets\NOTICES).Length` | **1.842.521 B** (el PRD dice "1.831 KB": no coincide, ver T2) |
| Roboto reales | ídem | 171.676 B y 170.760 B |
| Diferido en VM/AOT | proyecto temporal: `dart run` y `dart compile exe` con `deferred as` | compila y `loadLibrary()` completa; el símbolo se usa normal → **no rompe `flutter test` ni Android** (G10) |
| `generated/` versionado | `git ls-files lib/l10n/generated` | 3 archivos trackeados |

## 4. Mapa de fases

| Fase | Tareas | Resultado verificable | PRD | Depende de |
|---|---|---|---|---|
| 0 · Punto de partida | T1 | Gate base registrado (0 / 1046) | M1 | — |
| 1 · Medición base | T2 | Tabla de bytes + reparto + paridad del export congelada | M1 · SC-1, SC-5 | T1 |
| 2 · Romper la cadena | T3–T5 | `package:pdf` fuera del grafo de las alertas; bytes intermedios | M2 · SC-4 (parcial) | T1 |
| 3 · Export bajo demanda | T6–T8 | PDF y Excel diferidos, mensaje sin red, Inicio sin partes | M3, M4 · SC-3, SC-6, SC-8 | T2, T5 |
| 4 · Después y cierre | T9–T10 | Partes reales, ≤4.336.980 B o decisión, gate y deploy | M5 · SC-2, SC-4, SC-7, SC-9–SC-14 | T1–T8 |

Orden deliberado: **medir antes de tocar**, **romper el ciclo antes de diferir**
(sin eso el `deferred as` ahorra 0 B), y **dejar los números de cierre para el final**
para no prometer un porcentaje antes de tener el reparto.

## 5. Fases y tareas

---

### Fase 0 — Punto de partida

#### T1 · Registrar el baseline

- **Archivos:** `docs/reports/2026-10-20_peso-web-rojo.md` (nuevo).
- **Cambio:** ninguno en `lib/`. Anotar `git rev-parse --short HEAD` (`e9c2761`), la salida
  de `flutter analyze` (**0 issues**) y el conteo de `flutter test` (**1046**), más
  `flutter --version` (3.24.0 / Dart 3.5.0).
- **Tests:** no aplica; el gate actual **es** la prueba.
- **Rojo esperado:** no aplica (instrumento).
- **Hecho:** baseline verde registrado y árbol limpio salvo el PRD y este plan. Si el
  conteo no es 1046 o `analyze` no está en 0, **se detiene la tanda** y se reporta.
- **Depende:** — · **Riesgo:** bajo.

---

### Fase 1 — Medición base

#### T2 · Bytes de la primera carga, reparto y paridad del export

- **Archivos:**
  - `docs/reports/2026-10-20_peso-web-base.md` (nuevo)
  - `test/export_parity_test.dart` (nuevo)
- **Cambio:** **ninguno en `lib/`**. Instrumento en cinco pasos.

  1. **Bytes en disco (exacto, reproducible).** Build limpio con el comando de
     `deploy.ps1`, **incluidos los `--dart-define`** (sin ellos el mismo código
     pesa 4.718.092 B y la comparación deja de valer):

     ```powershell
     $map = @{}; Get-Content .env | ForEach-Object {
       if ($_ -match '^\s*([^#=]+)=(.*)$') { $map[$matches[1].Trim()] = $matches[2].Trim() }
     }
     flutter build web --release --base-href=/cafecal/ `
       "--dart-define=SUPABASE_URL=$($map['SUPABASE_URL'])" `
       "--dart-define=SUPABASE_ANON_KEY=$($map['SUPABASE_ANON_KEY'])"
     (Get-Item build\web\main.dart.js).Length        # medido: 4818867
     Get-ChildItem build\web -Recurse -File |
       Select-Object FullName, Length | Sort-Object Length -Descending
     ```

     Tabla por archivo: `index.html`, `flutter_bootstrap.js`, `flutter.js`,
     `main.dart.js`, `manifest.json`, `assets/NOTICES`, `assets/assets/fonts/*`,
     `assets/fonts/MaterialIcons-Regular.otf` (aparece duplicado), y los de
     `canvaskit/` **con una columna "¿lo pide el navegador?"** (el bootstrap los pide a
     gstatic; ver §3).

  2. **Reparto por librería (D2).** `--dump-info` **no funciona en este 3.24**
     (medido en T2: el flag existe en `-h` pero no produce ningún `.info.json`, ni
     con `-v`). **Sustituido por ablación en T5:** build con la cadena del
     `enum ReportPeriod` cortada y diferencia contra `4.818.867 B`. Eso mide la
     palanca que importa, no un pastel por paquete.

     ~~Segundo build con `--dump-info` y `.info.json` en `build/analysis`.~~
     Se deja escrito para que nadie lo reintente sin saber que ya falló.

  3. **Transferido.** Dos columnas:
     - *gzip reproducible* (script, no red) como proxy:

       ```powershell
       foreach ($f in (Get-ChildItem build\web -Recurse -File)) {
         $fs=[IO.File]::OpenRead($f.FullName); $ms=[IO.MemoryStream]::new()
         $gz=[IO.Compression.GZipStream]::new($ms,[IO.Compression.CompressionLevel]::Optimal)
         $fs.CopyTo($gz); $gz.Dispose(); $fs.Dispose()
         [pscustomobject]@{ Archivo=$f.FullName; Bytes=$f.Length; Gzip=$ms.Length }
       }
       ```

     - *transferido real* (DevTools → Network, caché desactivada, perfil limpio).
       **Lo hace el usuario.** Si no se corre, la columna dice **NO MEDIDO**; no se estima.

  4. **Conciliación de los ≈0,50 MB.** Sumar la tabla real y explicar la diferencia entre
     "13,4 MB" declarado y "13,90 MB" suma. Hipótesis a comprobar (no a afirmar): la
     columna del PRD mezcla **KiB** (4706, 6593, …) con un total en **MB decimales**, y
     excluye `skwasm.*` (3,29 MB). La tabla del PRD además no coincide con el árbol en
     `NOTICES` (1.831 KB vs 1.842.521 B) y en las Roboto (168 KB vs 171.676 B). Si la
     cuenta no cierra, el reporte dice **«NO EXPLICADO»** y muestra los números.

  5. **Paridad del export (SC-5), congelada antes de tocar nada.**
     `test/export_parity_test.dart` con un fixture canónico (2 monedas, ingresos, gastos,
     mano de obra, caja menor, cultivos con y sin terreno, cosechas) que fija **4 valores**:
     - filas de la hoja de movimientos del Excel,
     - total de ingresos por moneda,
     - total de gastos por moneda,
     - **número de páginas del PDF** (contar objetos `/Type /Page` en los bytes; contrastar
       con el `/Count` del nodo `/Pages`). Los PDF de muestra de `build/sample_pdfs/` son de
       1 página y muestran ambos valores = 1; en T2 se confirma con un fixture de **≥2
       páginas** y, si los dos métodos no coinciden, manda `/Count`.

     Se escribe **con el código de hoy**: nace verde y su valor es impedir que el contenido
     cambie cuando se diferencie. Los 4 números se pegan también en el reporte.
- **Tests:** `test/export_parity_test.dart` (verde de entrada).
- **Rojo esperado:** **no aplica — guarda declarada.** No hay arreglo pendiente: el test
  fotografía el comportamiento actual. Se dice explícitamente para que nadie invente un
  rojo artificial.
- **Hecho:** `docs/reports/2026-10-20_peso-web-base.md` existe con disco + gzip +
  transferido (medido o NO MEDIDO), el reparto por librería, la conciliación (o el
  «NO EXPLICADO») y los 4 valores de SC-5. **Sin este archivo la tanda no empieza (SC-1).**
- **Depende:** T1 · **Riesgo:** medio (el `.info.json` publicado por error).

---

### Fase 2 — Romper la cadena del enum

#### T3 · El enum neutro

- **Archivos:**
  - `lib/models/report_period.dart` (nuevo)
  - `test/report_period_test.dart` (nuevo)
- **Cambio:** crear el archivo con **exactamente** el enum de hoy, sin imports:

  ```dart
  /// Período de un reporte. Tipo de dominio: no depende del PDF ni del Excel.
  enum ReportPeriod { week, month, year, yearToDate }
  ```

  En esta tarea **no se borra** la declaración de `pdf_export_service.dart:29`: el enum
  existe dos veces de forma transitoria (T5 borra el duplicado). Nada importa los dos, así
  que no hay ambigüedad y el árbol queda verde.
- **Tests** — `test/report_period_test.dart`, grupo `'El enum neutro'`:
  - `conserva los cuatro valores y su orden` (`ReportPeriod.values` == week, month, year, yearToDate)
  - `el archivo no importa nada` (ninguna línea empieza con `import`)
  - `el archivo no menciona pdf, excel ni services`
- **Rojo esperado:** compilación del test nuevo:
  `Error: Couldn't resolve the package 'mi_cafetal' ... models/report_period.dart`.
- **Hecho:** test en verde, `flutter analyze` 0 issues, ningún otro archivo tocado.
- **Depende:** T1 · **Riesgo:** bajo (duplicado transitorio documentado).

#### T4 · El test que demuestra que `pdf` entra por las alertas (rojo)

- **Archivos:** `test/pdf_out_of_initial_graph_test.dart` (nuevo).
- **Cambio:** test estático de grafo, sin tocar `lib/`:
  - lee `lib/services/alert_service.dart` y resuelve `import`/`export` **relativos** en
    BFS; los `package:` se usan solo para detectar `package:pdf/`;
  - **A1** ninguna ruta llega a `package:pdf` (el `reason` imprime la ruta completa);
  - **A2** `lib/services/report_payroll_metrics.dart` no menciona `pdf_export_service.dart`;
  - **A3** *control positivo*: el BFS **sí** alcanza `lib/services/report_payroll_metrics.dart`
    (si alguien rompe el parser o el import, el test no puede pasar por vacío).
- **Tests:** los 3 del archivo.
- **Rojo esperado:** **es el rojo de la tanda** y se ve hoy:
  `Expected: sin ruta a package:pdf / Actual: alert_service.dart → report_payroll_metrics.dart → pdf_export_service.dart → package:pdf`.
  Se pega la salida en `docs/reports/2026-10-20_peso-web-rojo.md`. `flutter analyze` sigue
  en 0 (el rojo es de test, no de compilación).
- **Hecho:** rojo registrado. **No se arregla acá**: el suite queda con 1 test rojo a
  propósito y el gate de la fase se cierra en T5.
- **Depende:** T1 · **Riesgo:** bajo (parser ingenuo; el estilo del repo es comillas simples).

#### T5 · Cortar la cadena y reapuntar los imports

- **Archivos:**
  - `lib/services/pdf_export_service.dart` (borra `enum ReportPeriod` de `:29`, importa el modelo)
  - `lib/services/report_payroll_metrics.dart` (`:4` → modelo) ← **aquí se gana la tanda**
  - `lib/services/excel_export_service.dart` (`:21` → modelo)
  - `lib/screens/report_screen.dart` (importa el modelo; el import del PDF sigue normal hasta T7)
  - Tests (11): `test/associated_crops_cost_note_test.dart`,
    `test/cash_box_carry_test.dart`, `test/categories_cash_box_test.dart`,
    `test/derived_harvests_report_test.dart`, `test/evaluacion_unificada_export_test.dart`,
    `test/excel_export_service_test.dart`, `test/mixed_currency_export_test.dart`,
    `test/mixed_currency_gap_test.dart`, `test/moneda_caja_export_test.dart`,
    `test/pdf_export_test.dart`, `test/terreno_location_report_test.dart`
  - `tool/` (4): `tool/demo_report_tool.dart`, `tool/generate_report_tool.dart`,
    `tool/generate_sample_pdf.dart`, `tool/local_report_tool.dart`
- **Cambio:** **solo líneas de import.** Se agrega
  `import 'package:mi_cafetal/models/report_period.dart';` (relativo dentro de `lib/`) y se
  quita el `show ReportPeriod` que apuntaba a `pdf_export_service.dart`. No se tocan firmas,
  ni `buildReport`, ni `buildBalanceTemplate`, ni un solo cálculo.
  `test/currencies_test.dart` **no cambia** (importa el PDF por el servicio, no por el enum).
- **Tests:** pasa a verde `test/pdf_out_of_initial_graph_test.dart` (T4) + suite completa.
- **Rojo esperado:** al empezar, el test de T4 sigue rojo. Al quitar la declaración,
  `flutter analyze` lista `Undefined name 'ReportPeriod'` en los archivos que aún no se
  reapuntaron (se pega el primero); se corrige import por import hasta 0 issues.
- **Hecho:** T4 en verde, `flutter analyze` 0, `flutter test` 1046 + los nuevos en verde.
  **Medición intermedia (D12):** build limpio y bytes de `main.dart.js` anotados en
  `docs/reports/2026-10-20_peso-web-medicion.md`. No se declara ahorro hasta verlo.
  Si el delta es **0**, el diagnóstico es que el enum no era la única vía: se revisa el
  grafo antes de seguir a la fase 3.
- **Depende:** T4 · **Riesgo:** medio (churn mecánico en 20 archivos; un import olvidado lo
  delata `analyze`, un `show` mal copiado lo delata el compilador).

---

### Fase 3 — Exportación bajo demanda

#### T6 · Copy ES/EN y `gen-l10n`

- **Archivos:**
  - `lib/l10n/app_es.arb` (template)
  - `lib/l10n/app_en.arb`
  - `lib/l10n/generated/app_localizations.dart`, `app_localizations_es.dart`,
    `app_localizations_en.dart` (generados)
  - `test/l10n_export_offline_test.dart` (nuevo)
- **Cambio:** una clave **sin placeholders** (no lleva bloque `@`), junto a `exportError`:
  - `exportNeedsNetworkOnce`: «La primera vez hay que conectarse para preparar la
    exportación. Probá de nuevo con señal.» / “The first export needs a connection. Try
    again when you have signal.”
  - Después: `C:\flutter\bin\flutter.bat gen-l10n`. Los generados **no** se editan a mano.
- **Tests** — `test/l10n_export_offline_test.dart`, grupo `'Export sin red · copy'`:
  - `la frase está en ES con el texto aprobado`
  - `la frase está en EN con el texto aprobado`
  - `la clave no tiene placeholders` (ningún `{` en el valor)
  - `el generado expone exportNeedsNetworkOnce` (lectura de los tres `app_localizations*.dart`)
- **Rojo esperado:** `Expected: 'La primera vez hay que conectarse…' Actual: null` en ES
  (y lo mismo en EN).
- **Hecho:** `gen-l10n` corrido, 3 generados con la clave, test verde.
- **Depende:** T1 · **Riesgo:** bajo (orden: ARB → generar → UI).

#### T7 · PDF diferido + el mensaje sin red

- **Archivos:**
  - `lib/screens/report_screen.dart`
  - `test/report_export_deferred_test.dart` (nuevo)
  - `test/report_export_offline_test.dart` (nuevo)
- **Cambio:**
  - `import '../services/pdf_export_service.dart' deferred as pdf;`
  - Comprobación previa (una línea de análisis, no de código): después de T5 el PDF
    **no vuelve** al library inicial (`pdf → alert_service → report_payroll_metrics →
    models/report_period`), así que no hay ciclo que impida diferirlo. Si `analyze` o el
    build se quejan de ciclos, es que T5 quedó incompleto: se vuelve a T5, no se parchea acá.
  - Seam de test en el widget (no cambia el uso normal):
    `const ReportScreen({super.key, this.loadPdfLibrary});` +
    `final Future<void> Function()? loadPdfLibrary;`
  - Estado `bool _pdfLibraryReady = false;`
  - `import 'dart:async';` en el archivo (para `unawaited`).
  - Carga y helper:

    ```dart
    Future<void> _loadPdf() async {
      final custom = widget.loadPdfLibrary;
      if (custom != null) return custom();
      await pdf.loadLibrary();
    }

    Future<bool> _ensurePdf(AppLocalizations l10n) async {
      if (_pdfLibraryReady) return true;
      try {
        // 4 s, no 5: el PRD exige el mensaje en ≤5 s y hay que dejar margen al frame.
        await _loadPdf().timeout(const Duration(seconds: 4));
        _pdfLibraryReady = true;
        return true;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.exportNeedsNetworkOnce)));
        }
        return false;
      }
    }
    ```

  - `_export`: **antes** de crear el servicio,
    `if (!await _ensurePdf(l10n)) return;` dentro del `try` y con el `finally` que ya apaga
    `_exporting`. Así **nunca** se genera un archivo vacío (SC-6): sin librería no hay PDF.
  - `initState`: calentamiento silencioso, **sin** `setState`, **sin** spinner, **sin**
    `timeout` (para no dejar timers pendientes en `testWidgets`):
    `unawaited(_warmUpPdf());`, donde `_warmUpPdf` hace
    `try { await _loadPdf(); _pdfLibraryReady = true; } catch (_) {}`.
  - El calentamiento **no** se pone en `main.dart` (D5): eso anularía el ahorro.
- **Tests** — `test/report_export_deferred_test.dart`:
  - `report_screen declara el PDF como deferred` (`deferred as pdf`)
  - `_export carga la librería antes de construir el servicio` (orden textual
    `loadLibrary`/`_ensurePdf` antes de `PdfExportService`)
  - `ningún archivo de lib/ importa el PDF de forma no diferida` (recorre `lib/`)
  - `el grafo desde main.dart no alcanza el PDF` — BFS desde `lib/main.dart` **ignorando
    las aristas `deferred`**: no puede llegar a `pdf_export_service.dart` ni a `package:pdf`
  - `el calentamiento vive en initState y no en main.dart`

  `test/report_export_offline_test.dart` (widget, con los providers que ya usan los tests
  de Reportes):
  - `sin red la primera vez muestra exportNeedsNetworkOnce y no exporta`
    (`loadPdfLibrary: () async => throw Exception('sin red')`, tap en «Exportar PDF y
    compartir» → aparece la frase, `_exporting` vuelve a false, no hay excepción de
    plataforma porque no se llegó a compartir)
  - `el error se puede reintentar` (segundo tap vuelve a mostrar el mensaje, no queda trabado)
- **Rojo esperado:**
  1. compilación del test de widget: `No named parameter with the name 'loadPdfLibrary'`;
  2. el test de grafo: `Expected: sin ruta / Actual: main.dart → … → home_screen.dart →
     report_screen.dart → pdf_export_service.dart`.
- **Hecho:** `deferred` compilando, los **cinco + dos** tests nuevos en verde, `flutter analyze` 0,
  `test/report_screen_test.dart` sigue verde (el calentamiento no rompe el `pump`).
- **Depende:** T5, T6 · **Riesgo:** **alto** — async en `initState`, timers en
  `testWidgets`, y un `catch` incompleto dejaría una excepción sin capturar (SC-6).

#### T8 · Excel diferido

- **Archivos:**
  - `lib/screens/report_screen.dart`
  - `test/report_export_deferred_test.dart` (extensión)
  - `test/report_export_offline_test.dart` (extensión)
- **Cambio:** `deferred as excel`; seam `loadExcelLibrary`; `_excelLibraryReady`;
  `_ensureExcel` (mismo patrón que `_ensurePdf`); `if (!await _ensureExcel(l10n)) return;`
  en `_exportExcel` (`:1805`) **y** en `_exportBalance` (`:1857`); `excel.ExcelExportService()`
  en ambos; calentamiento en `initState`.
- **Tests:**
  - `el Excel está diferido y se carga antes de construir el servicio` (los dos métodos)
  - `el grafo desde main.dart no alcanza el Excel`
  - widget: `sin red el Excel avisa y no genera un archivo vacío`
- **Rojo esperado:** `Expected: true Actual: false` en
  `source.contains("deferred as excel")`; y compilación por `loadExcelLibrary`.
- **Hecho:** los dos imports diferidos, analyze 0, suite verde. Los tres puntos de
  exportación (`_export`, `_exportExcel`, `_exportBalance`) cargan su librería antes de usarla.
- **Depende:** T7 · **Riesgo:** medio (dos métodos, mismo patrón).

---

### Fase 4 — El después y el cierre

#### T9 · Build final, partes y reparto

- **Archivos:** `docs/reports/2026-10-20_peso-web-medicion.md` (se completa).
- **Cambio:** ninguno en `lib/`.
- **Verificaciones (instrumento, no hay rojo):**
  - Build limpio + `main.dart.js` vs 4.818.867 B → **SC-2** (≤ **4.336.980 B**). Se anota el
    % real. Si no llega al piso, **no se declara cumplido**: se documenta y se abre la
    decisión §12-B.
  - `Get-ChildItem build\web\main.dart.js_*.part.js` → **≥1 archivo y > 0 B** (SC-4, A3).
  - Build con `--dump-info` (y el `.info.json` **fuera** de `build/web`):
    `lib/services/pdf_export_service.dart` y `lib/services/excel_export_service.dart`
    **fuera** del library inicial (SC-4). Si no aparecen las partes, el `deferred` no
    funcionó: **FAIL**, se vuelve a T7/T8 (D3).
  - `assets/NOTICES` sigue en `build/web` con ~1.842.521 B (SC-10, segunda mitad).
  - `assets/assets/fonts/Roboto-Regular.ttf` y `Roboto-Bold.ttf` presentes (SC-11,
    segunda mitad); las descargas a `fonts.gstatic.com` se comparan contra la base (la
    primera mitad de SC-10/SC-11 es manual, en T10).
  - `build\web\flutter_bootstrap.js` sigue con `"renderer":"canvaskit"` (SC-8).
  - **G11:** `.\deploy.ps1 -VerifyOnly` debe terminar OK, o sea que el `projectRef` y la
    `anon key` de Supabase **siguen dentro de `main.dart.js`**. Si falla: **parar**, no
    tocar `deploy.ps1` a escondidas; se decide con el usuario (§12-B).
- **Hecho:** tabla antes/después/delta/% y las partes listadas con su tamaño.
- **Depende:** T8 · **Riesgo:** **alto** si G11 falla o si el piso −10% no se alcanza.

#### T10 · Manual, gate y cierre

- **Archivos:** `docs/reports/2026-10-20_peso-web.md` (nuevo). Este plan pasa a `DONE` al
  final.
- **Cambio:** ninguno en `lib/`.
- **Gate:**
  - `C:\flutter\bin\flutter.bat analyze` → **0 issues** (incluye `tool/`).
  - `C:\flutter\bin\flutter.bat test` → 1046 + los nuevos, **0 fallos**.
  - `C:\flutter\bin\flutter.bat build apk --release` → compila (G10/A11). El `deferred`
    en AOT se comporta como import normal (verificado en §3).
  - `git diff --name-only` → **no** aparecen `sync_provider.dart`, `local_store.dart`,
    `backup*`, `derived_harvests.dart`, `deploy.ps1` (SC-9/A10).
- **Verificación manual (la hace el usuario, §7):** SC-3, SC-5, SC-6, SC-7, SC-8, SC-14.
- **Deploy:** `.\deploy.ps1 -VerifyOnly` como gate (imprime bytes y sha256, SC-13). El
  deploy real —`.\deploy.ps1 -Message "…"`— **solo con el verbo del usuario**.
- **Rojo esperado:** no aplica.
- **Hecho:** reporte de cierre con SC-1…SC-14 en sí/no y su evidencia, el % real y el
  checklist de deploy. El plan se marca `DONE` **después** de que el usuario valide la
  verificación manual.
- **Depende:** T1–T9 · **Riesgo:** medio (la verificación manual depende del usuario).

## 6. Tests existentes que pueden romperse (y cómo se ajustan)

| Test / archivo | Por qué podría romperse | Ajuste (sin aflojar nada) |
|---|---|---|
| `test/report_screen_test.dart` (20+ `pumpWidget`) | `initState` ahora dispara `loadLibrary()` | En VM/AOT completa al instante (verificado). El calentamiento **no** usa `timeout`, para no dejar timers pendientes. Si algún `pumpAndSettle` se queja, se inyecta `loadPdfLibrary`/`loadExcelLibrary` que completen sin hacer nada; **no** se borra la aserción. |
| 11 tests que importan el enum desde el PDF | `ReportPeriod` deja de estar declarado ahí | T5 cambia **solo la línea de import**; ninguna aserción se toca. |
| `test/currencies_test.dart` | Importa el PDF por el servicio | Sin cambios (no usa el enum). |
| `test/terreno_reportes_contrato_test.dart` | Lee el source del PDF y del Excel buscando `cropBreakdownLayout(` | No se toca: los servicios siguen agrupando con la función única. Si alguien mueve esa llamada, el test debe fallar. |
| `test/pdf_export_test.dart`, `excel_export_service_test.dart`, `mixed_currency_*`, `terreno_location_report_test.dart`, `associated_crops_cost_note_test.dart` | Cambia el import del enum | Solo el import (T5). Los fixtures no cambian. |
| `test/help_no_orphan_keys_test.dart`, `test/l10n_placeholder_order_test.dart` | Clave nueva en los ARB | La clave no es `help*` ni tiene placeholders → sin cambios. |
| `tool/*.dart` (4 scripts) | `flutter analyze` los cubre y usan el enum | T5 agrega el import del modelo. |
| `test/alert_service_test.dart` | Nada: las alertas no cambian | Guarda de que la nómina y las reglas siguen iguales después de cortar la cadena. |

## 7. Verificación manual del usuario (después del gate, sobre el sitio desplegado)

Con un perfil de navegador limpio y DevTools abierto:

1. **SC-3 / G8 / A4.** Abrir la app con caché vacía y quedarse en Inicio: **0** peticiones
   a `*.part.js` y **0** a `assets/NOTICES` *hasta ese momento*. Anotar las peticiones de
   `main.dart.js` y del motor.
   *(Al abrir Reportes sí baja una parte: eso es D5 y es lo que habilita SC-7. Ver §12-A.)*
2. **SC-8 / A9.** Inicio se pinta con la tarjeta de tendencia mensual visible, sin spinner
   ni hueco.
3. **SC-5 / A5 / A6.** Exportar PDF del mismo período con los mismos datos: mismo número
   de páginas. Exportar Excel: mismas filas y mismos totales por moneda. Diferencia **0**
   contra `test/export_parity_test.dart` y contra el reporte base.
4. **SC-6 / A7.** Perfil que **nunca** abrió Reportes con red + DevTools «Offline»:
   tocar «Exportar PDF y compartir» → aparece **una** vez `exportNeedsNetworkOnce`, **sin**
   archivo vacío, **sin** pantalla roja, **sin** excepción.
5. **SC-7 / A8.** Con red, abrir Reportes una vez (calentamiento) → cortar la red →
   exportar: el archivo sale **> 0 B**.
6. **SC-14.** DevTools «Slow 3G», 3 corridas, mediana del primer frame con contenido,
   contra la base de T2. Si el método no es repetible, **se retira el criterio** y se
   documenta (no se promete un tiempo).
7. **Android (A11).** Instalar el APK release y exportar una vez.

## 8. Cómo se mide y qué se archiva

| Artefacto | Cuándo | Contenido |
|---|---|---|
| `docs/reports/2026-10-20_peso-web-base.md` | T2 | Disco, gzip, transferido (o NO MEDIDO), reparto por librería, conciliación 13,4 vs 13,90, los 4 valores de SC-5 |
| `docs/reports/2026-10-20_peso-web-rojo.md` | T1–T8 | Baseline + cada rojo con comando y salida |
| `docs/reports/2026-10-20_peso-web-medicion.md` | T5, T9 | Bytes antes / después / delta por fase |
| `docs/reports/2026-10-20_peso-web.md` | T10 | Cierre: SC-1…SC-14 en sí/no, % real, deploy |

**Regla de honestidad:** cualquier casilla sin instrumento se escribe **NO MEDIDO** o
**NO EXPLICADO**. Un ahorro no medido no se declara, ni en el reporte ni en el mensaje del
deploy.

## 9. Gate, stageo y despliegue

### Gate (por fase y al cierre)

```powershell
C:\flutter\bin\flutter.bat analyze     # proyecto entero, tool/ incluido → 0 issues
C:\flutter\bin\flutter.bat test        # base 1046 + nuevos, 0 fallos
```

Además, por fase, el subconjunto que toca esa fase (p. ej.
`flutter test test/pdf_out_of_initial_graph_test.dart`). El rojo y el verde se pegan en
`docs/reports/2026-10-20_peso-web-rojo.md`.

### Stageo explícito (nunca `-A`)

| Fase | `git add` |
|---|---|
| 1 | `git add docs/reports/2026-10-20_peso-web-rojo.md docs/reports/2026-10-20_peso-web-base.md test/export_parity_test.dart` |
| 2 | `git add lib/models/report_period.dart lib/services/pdf_export_service.dart lib/services/report_payroll_metrics.dart lib/services/excel_export_service.dart lib/screens/report_screen.dart test/report_period_test.dart test/pdf_out_of_initial_graph_test.dart test/associated_crops_cost_note_test.dart test/cash_box_carry_test.dart test/categories_cash_box_test.dart test/derived_harvests_report_test.dart test/evaluacion_unificada_export_test.dart test/excel_export_service_test.dart test/mixed_currency_export_test.dart test/mixed_currency_gap_test.dart test/moneda_caja_export_test.dart test/pdf_export_test.dart test/terreno_location_report_test.dart tool/demo_report_tool.dart tool/generate_report_tool.dart tool/generate_sample_pdf.dart tool/local_report_tool.dart` |
| 3 | `git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_es.dart lib/l10n/generated/app_localizations_en.dart lib/screens/report_screen.dart test/l10n_export_offline_test.dart test/report_export_deferred_test.dart test/report_export_offline_test.dart` |
| 4 | `git add docs/reports/2026-10-20_peso-web-medicion.md docs/reports/2026-10-20_peso-web.md docs/plans/2026-10-20-peso-de-la-web.plan.md` |

Antes de cada stageo: `git status --short` y confirmar que solo están los archivos
previstos. **Ningún commit ni push** sin el verbo del usuario.

### Deploy

```powershell
.\deploy.ps1 -VerifyOnly                 # gate: base href, claves de Supabase, bytes, sha256
.\deploy.ps1 -Message "…"                # SOLO con el verbo del usuario
```

`--base-href=/cafecal/` no cambia. `deploy.ps1` ya corre sus propios pasos 1/7 y 2/7
(`flutter analyze` + `flutter test`) y compila con el mismo comando que T2/T9, así que es
un tercer gate gratis. Copia con `Copy-Item -Path 'build\web\*' -Destination '_deploy'
-Recurse -Force`: **todo** lo que quede en `build\web` se publica (de ahí el cuidado con el
`.info.json` de `--dump-info`). Si `-VerifyOnly` falla por las claves de Supabase (G11),
**se detiene el deploy**: no se publica un build que dejaría el login en modo local.

## 10. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Se salta D3 y el `deferred as` ahorra **0 B** (pdf sigue entrando por las alertas) | Alta si no se revisa | **Alto** | T4 deja el rojo por escrito; T5 corta la cadena; SC-4 exige partes reales |
| El enum usado como tipo fuera de la librería diferida rompe la compilación | Alta sin T3/T5 | Medio | T3 lo saca a `lib/models/`; `analyze` lo delata al instante |
| El piso −10% no se alcanza con pdf+excel | Media | **Alto** | T2 mide el reparto **antes**; T9 decide con números; §12-B (no se inventa un % ni se toca el renderer) |
| `deploy.ps1` falla porque las claves de Supabase ya no están en `main.dart.js` | Baja | **Alto** | T9 corre `-VerifyOnly` antes de publicar; si falla, se decide (§12-B), no se parchea a escondidas |
| El `.info.json` de `--dump-info` se publica | Media | Medio | T2 lo mueve a `build/analysis/`; el build que se despliega es el limpio |
| Exportar sin red la primera vez deja al agricultor sin reporte | Media | **Alto** | `_ensureX` + `exportNeedsNetworkOnce` + `timeout(4s)` + retorno antes de generar (SC-6) |
| La parte diferida no se cachea y el offline se degrada en silencio | Media | **Alto** | D5 (calentar al abrir Reportes) y SC-7 con la red cortada; el SW no se toca |
| `loadLibrary()` en `initState` rompe `testWidgets` (timers/excepciones) | Media | Medio | Sin `timeout` en el calentamiento, `catch` total, seam inyectable; `report_screen_test` es la guarda |
| PDF/Excel salen con distinto contenido y nadie lo nota | Baja | **Alto** | `test/export_parity_test.dart` congela los 4 valores **antes** (T2) |
| Se borran las Roboto «porque no se usan» y se rompe el PDF | Media | **Alto** | D9; SC-11; no se toca `assets/fonts/` |
| Se edita el service worker a mano | Baja | Alto | D10/G7: se genera, no se toca |
| SC-14 no es repetible y se promete un tiempo | Alta | Bajo | T2/T10: 3 corridas, mediana; si no es repetible, **se retira** y se documenta |
| Cambia el aspecto por tocar renderer/fuentes/gráfica | Baja | **Alto** | D6/D7/D9; SC-8 y SC-11 lo fijan |
| El calentamiento se «arregla» precargando en `main.dart` | Media | Alto | D5 explícito + test `el calentamiento vive en initState y no en main.dart` |

## 11. Trazabilidad PRD

### Success Criteria

| Criterio | Tarea(s) | Evidencia |
|---|---|---|
| **SC-1** · Base reproducible y conciliada | T2 | `main.dart.js` = 4.818.867 B; reporte base con disco+gzip+transferido y la conciliación (o «NO EXPLICADO») |
| **SC-2** · `main.dart.js` ≤ 4.336.980 B (−10%) | T2, T5, T9 | Bytes de T2 vs T9, delta y % en `peso-web-medicion.md` |
| **SC-3** · Al abrir no baja ninguna parte | T7, T8, T10 | Test de grafo desde `main.dart` (aristas diferidas ignoradas) + Network con caché limpia (manual). *Ver §12-A* |
| **SC-4** · Las partes existen y las dos librerías están fuera del inicial | T9 | `main.dart.js_*.part.js` > 0 B + `.info.json` sin los dos servicios |
| **SC-5** · La exportación da lo mismo | T2 (congela), T7, T8, T10 | `test/export_parity_test.dart`: 4 valores, diferencia 0 |
| **SC-6** · Sin red la primera vez avisa y no rompe | T6, T7, T8 | `exportNeedsNetworkOnce` (1 mensaje, ≤4 s), sin archivo vacío, sin excepción |
| **SC-7** · Abrir Reportes con red habilita el export sin red | T7, T8 (calentamiento), T10 | Manual: abrir Reportes → cortar red → exportar > 0 B |
| **SC-8** · El aspecto no cambia | T9, T10 | `"renderer":"canvaskit"` (1 ocurrencia) + Inicio con la gráfica en el primer frame |
| **SC-9** · Cero cambios en datos, sync y respaldo | T10 | `git diff --name-only` sin `sync_provider`, `local_store`, `backup*`, `derived_harvests`, `deploy.ps1` |
| **SC-10** · `NOTICES` no se baja al abrir pero sigue publicado | T9, T10 | Reporte base (bytes) + Network 0 B al abrir + archivo en `build/web` |
| **SC-11** · Fuentes sin tocar | T9, T10 | Roboto presentes con sus bytes + mismas descargas a gstatic |
| **SC-12** · Gates | T1, T5, T7, T8, T10 | `analyze` 0 / `test` 1046 + nuevos; rojos registrados |
| **SC-13** · Deploy verificado | T10 | `deploy.ps1 -VerifyOnly` OK con bytes ≤ 4.336.980 y sha256 |
| **SC-14** · Se llega antes al Inicio | T2, T10 | Slow 3G, 3 corridas, mediana; si no es repetible, se retira |

### Acceptance (A)

| Criterio | Tarea(s) |
|---|---|
| A1 · analyze 0 / test verde ≥1046 | T1, T10 |
| A2 · `-VerifyOnly` con bytes ≤ 4.336.980 | T9, T10 |
| A3 · hay al menos una parte > 0 B | T9 |
| A4 · al abrir, 0 partes y 0 `NOTICES` | T10 |
| A5 · exportar PDF baja ≥1 parte y sale el mismo nº de páginas | T2, T10 |
| A6 · Excel con las mismas filas y totales | T2, T10 |
| A7 · offline la primera vez avisa, sin archivo vacío | T7, T10 |
| A8 · Reportes con red → export offline | T7, T8, T10 |
| A9 · Inicio sin spinner ni saltos | T10 |
| A10 · diff sin datos/sync/respaldo/deploy | T10 |
| A11 · APK release compila y exporta | T10 |

### Guardas (G)

| Guarda | Tarea(s) | Evidencia |
|---|---|---|
| G1 · Gate base | T1, T10 | analyze/test |
| G2 · Exportación intacta | T2 | `export_parity_test` |
| G3 · Sync intacto | T10 | diff (nada de `sync_provider`) |
| G4 · Respaldo intacto | T10 | diff (nada de `backup*`) |
| G5 · Offline base intacto | T10 | manual: abrir sin red tras una carga |
| G6 · Offline del export | T10 | SC-7 |
| G7 · SW no se edita a mano | T9, T10 | diff sin `flutter_service_worker.js` |
| G8 · Nada de red nuevo en el arranque | T7, T10 | test de grafo + Network |
| G9 · ARB ES/EN + `gen-l10n` | T6 | 4 tests de copy |
| G10 · Android | T10 | `build apk --release` |
| G11 · `deploy.ps1` sigue encontrando las claves | T9 | `-VerifyOnly` OK |

## 12. Decisiones que necesitan al usuario

- **A · SC-3 vs D5 (conflicto literal).** SC-3 dice «al abrir la app … **0** descargas de
  `*.part.js` antes de tocar exportar», pero D5 calienta la parte al **abrir Reportes**
  (necesario para SC-7: exportar sin red). Leído al pie de la letra, D5 incumpliría SC-3.
  **Recomendación:** interpretar SC-3 como «en el arranque y en Inicio»; abrir Reportes
  descarga exactamente una parte, a propósito, y eso es lo que compra SC-7. Se documenta
  así en el reporte de cierre. *Si preferís lo literal, hay que quitar el calentamiento y
  **SC-7 deja de cumplirse** — son incompatibles.*
- **B · Si el piso −10% no se alcanza (o si G11 falla).** T9 puede terminar con partes
  reales y aun así por encima de 4.336.980 B. No se va a inventar el número ni a tocar el
  renderer/fuentes. Opciones a decidir **con los datos de T2/T9 en la mano**: (a) aceptar
  el % real y corregir SC-2 con una enmienda al PRD; (b) abrir una Tanda 2 con otra palanca
  (p. ej. `share_plus`/`file_picker`, fuera de este alcance); (c) revertir. Lo mismo aplica
  si `-VerifyOnly` falla por las claves de Supabase.
- **C · SC-14 (tiempo al primer frame).** Solo se promete si T2 logra un método repetible
  (3 corridas, mediana, Slow 3G). Si no, **se retira** y se dice en el reporte. Confirmá si
  preferís que lo mida yo con el navegador o lo hacés vos en tu equipo.
- **D · Conteo de páginas del PDF (SC-5).** Se cuenta `/Type /Page` y se contrasta con
  `/Count`. En los PDF de muestra (1 página) ambos dan 1; T2 lo confirma con un fixture de
  ≥2 páginas. Si el conteo no resulta estable, SC-5 se verifica con las otras tres cifras +
  revisión visual del PDF, y se documenta; no se declara un número que no se pueda reproducir.

**Respondidas el 2026-10-20:** **A** → SC-3 se lee como «arranque e Inicio» (abrir Reportes
baja una parte a propósito). **C** → la medición del primer frame la hace el agente con un
servidor local limitado a velocidad 3G; el comando reproducible queda en el reporte. **D** →
conteo de páginas contrastado con `/Count`, y si no es estable, las otras tres cifras más
revisión visual. **B** sigue abierta hasta tener el número de T9.

---

**Estado final de este plan: `READY`.** No se ha modificado código, tests, ARB ni datos.
El `DONE` se marca solo después del gate completo, la medición final y la verificación
manual del usuario.
