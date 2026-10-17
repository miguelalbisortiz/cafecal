# Code review — campo de fecha en pérdidas

- **Fecha:** 2026-10-17 17:37
- **Alcance:** working tree (nada commiteado). `git diff` de `lib/models/sowing.dart`,
  `lib/widgets/crop_loss_dialog.dart`, `test/sowing_test.dart`,
  `test/crop_loss_dialog_test.dart`, `test/report_screen_test.dart`.
- **Contrato:** `docs/prds/2026-10-17_1652-campo-de-fecha-en-perdidas.prd.md` (Q1–Q4 = las cuatro
  recomendaciones).
- **Modo:** review de solo lectura. No se tocó el código del proyecto.

## Veredicto

**PASS-CON-NITS.** El comportamiento pedido está implementado y es correcto: no hay
`CRITICAL` ni `HIGH`. El único hallazgo con peso es que **dos de los tests nuevos no fallan
sin el arreglo** (la regla de la casa no se cumple en ellos) y el PRD los declara rojos.

## Evidencia (cómo se comprobó)

No se revisó «a ojo». Se ejecutó:

1. `flutter test` de los 3 archivos tocados **en el working tree** (con el arreglo):
   `41 tests, All tests passed`.
2. Los mismos 3 archivos copiados a un **worktree limpio en `HEAD`** (lib SÍ vieja), para
   medir el rojo real: `3 fallos` (ver H1, H2).
3. En ese worktree, con `sowing.dart` nuevo pero **revirtiendo solo el comparador del sort**
   a `a.date.compareTo(b.date)`: el test del mismo día falla con `Expected: <60> Actual: <100>`.
   Confirma que ese test es rojo de verdad por comportamiento, no por compilación.
4. Asserts del selector contra el SDK instalado
   (`C:\flutter\packages\flutter\lib\src\material\date_picker.dart`).

## Hallazgos

### H1 — MEDIUM — los dos tests nuevos del informe no fallan sin el arreglo

`test/report_screen_test.dart:854` («una pérdida fechada este mes se lista en el período») y
`test/report_screen_test.dart:899` («una pérdida vieja no entra en el período de este mes»).

- **Hecho verificado:** en el worktree con la lib vieja, los **dos pasan**. No tocan ni el
  diálogo ni `recomputeCropState`: llaman a `provider.addSowing(date: ...)` (intacto) y montan
  `ReportScreen` (intacto). `_periodSowings` ya filtraba por `s.date`.
- **Contradicción:** el PRD (`docs/prds/...:206`, fila T6) los declara «ROJO hoy» porque «el
  diálogo fuerza la fecha de hoy»; el test no usa el diálogo. El rojo razonado no existe.
- **Impacto:** rompe la regla «cada arreglo con su test, verificado fallando sin el arreglo».
  Un cambio futuro en el filtrado por período pasaría igualmente estos dos; lo que sí cubren es
  el informe (valor de guarda), no el arreglo.
- **Corrección concreta:** que el test abra el diálogo de pérdidas de verdad (F4: abrir
  `CropLossDialog`, elegir el 15 del mes pasado en el selector, guardar) y **después** comprobar
  el período del informe. Así es rojo sin el arreglo y verde con él. Alternativa: si se prefieren
  como guardas, corregir el PRD (quitar «ROJO hoy» de T6) y dejar escrito qué test cubre el cambio.

### H2 — LOW — «sin tocar la fecha, la pérdida queda de hoy» no es rojo/verde

`test/crop_loss_dialog_test.dart:163`.

- **Hecho verificado:** pasó en el worktree con la lib vieja (antes `date: DateTime.now()`
  también caía hoy). Es una **guarda legítima** de SC6 (impide que alguien rompa el default),
  no un test del arreglo.
- **Corrección:** dejarlo como guarda y no contarlo entre los tests del arreglo; el «default =
  hoy» ya lo fija, además, `crop_loss_dialog_test.dart:150`.

### H3 — LOW — bomba de tiempo a medianoche en el test del diálogo

`test/crop_loss_dialog_test.dart:159` compara `formatShortDate(DateTime.now())` con la fecha que
el diálogo capturó al abrirse (`_date = DateTime.now()`, `crop_loss_dialog.dart:52`), y
`test/crop_loss_dialog_test.dart:186-209` captura `ahora` antes de `pumpLoss`.

- **Impacto:** si la suite cruza la medianoche entre la apertura del diálogo y la aserción, el
  test falla. Ventana de milisegundos: probabilidad ínfima, pero es real, y es exactamente lo que
  la propia regla del PRD pide evitar (`:211`, «fechas fijas, no `DateTime.now()`»).
- **Corrección:** sin exponer `_date` no hay forma limpia; se acepta como riesgo documentado
  (o se inyecta un reloj). No justifica tocar el código de producción.

### H4 — LOW — el orden por día cambia la semántica del test intencional en el caso del *mismo día*

`lib/models/sowing.dart:152-158` (`_kindOrder`) junto al test intencional
`test/sowing_test.dart:99` («resiembra ANTERIOR a la siembra base NO aplica»).

- **Qué cambia:** antes, una resiembra a las 08:00 y una siembra a las 10:00 del **mismo día**
  ordenaban resiembra→siembra: la resiembra no aplicaba. Ahora `_kindOrder` fuerza
  siembra→resiembra dentro del día, así que **esa resiembra sí aplica**. La regla pasa de «no
  antes de la siembra base» a «no antes del *día* de la siembra base».
- **Es la decisión Q3 del usuario** y está documentada en el comentario (`sowing.dart:129-135`).
  En la práctica no es alcanzable con datos reales: el selector devuelve las 00:00 y su mínimo es
  el día de la siembra. El test de la línea 99 sigue verde (usa días distintos).
- **Corrección:** añadir un test que fije la nueva semántica (resiembra con hora anterior a la
  siembra, mismo día → **sí** aplica) o ampliar el comentario del test de la línea 99 para que
  diga que el descarte es por día, no por instante.

### H5 — LOW — comentario en inglés pegado al bloque nuevo en español

`lib/models/sowing.dart:137` — `/// Returns a list of crop update candidates...` queda justo
debajo del doc nuevo en español (el diff reescribió la primera línea del mismo doc comment).

- **Impacto:** la regla del proyecto pide español en comentarios; el bloque queda mezclado.
- **Corrección:** traducir esa línea de paso (la línea es pre-existente, pero el diff edita ese
  mismo comentario).

## Lo que está bien (una línea cada uno)

- **P1 — rango del selector:** sin inversión ni assert. `lib/widgets/crop_loss_dialog.dart:79`
  (`primera = min(minimo, hoy)` ⇒ `firstDate ≤ lastDate` siempre) y `:81-83` (clamp de `inicial`
  a `[primera, hoy]`). Con siembra futura queda `firstDate == lastDate == hoy`, permitido
  (`firstDate must be on or before lastDate`, `date_picker.dart:1804`); `initialDate` cumple
  `:196-203` y `:309-320`. Enero, mes pasado y hoy == día de la siembra: correctos (Dart normaliza
  `month - 1` y la comparación es a medianoche).
- **P2 — `lossEarliestDate`:** coincide con quien fija el contador: `recomputeCropState` ordena
  por día y la siembra de día máximo manda, que es la que devuelve la función (`sowing.dart:118-127`).
  `cropId` nulo se ignora igual que en `:146`; sin siembras → `DateTime(2000)`, rama hoy
  inalcanzable desde el diálogo (exige `livePlants != null`, `crop_editor_dialog.dart:216-227`).
- **P3 — orden nuevo:** los únicos consumidores son `transaction_provider.dart:742` y
  `report_screen.dart:639`, y ninguno depende del orden previo; los cultivos se agrupan por
  `cropId` y dos resiembras del mismo día conmutan (mismo resultado). PDF/Excel leen
  `crop.livePlants`, así que heredan el número correcto.
- **P4 — la fecha en el resto del sistema:** el sync trunca a día y `date` no cambió de tipo;
  el respaldo ya la llevaba; el informe usa `s.date` en `_periodSowings` (`report_screen.dart:614`).
  La alerta «recién sembrado» compara instantes (`alert_service.dart:541,544`): una pérdida a las
  00:00 solo corre el límite de 15 días <24 h. Nada se descoloca.
- **P5 — tests:** el del «mismo día» (`sowing_test.dart:131`) es rojo real por comportamiento
  (verificado, H0 punto 3); los del diálogo son rojos reales (con lib vieja: `Found 0 widgets with
  text "Fecha"`); los 4 tests viejos de `crop_loss_dialog_test.dart` siguen verdes porque el campo
  nuevo es `InputDecorator` y no corre los índices de `TextFormField` (como pedía el PRD).

## Qué NO miré

- **PDF y Excel como pintadores de pérdidas:** confirmé que leen `crop.livePlants` y que **no**
  tienen sección de pérdidas (fuera de alcance del PRD, Q7). La regla «los tres pintadores dicen lo
  mismo» sobre pérdidas sigue sin cumplirse (solo Reportes las pinta): es deuda declarada, no la
  introduce este cambio.
- **Suite completa:** no corrí los 930 tests; corrí los 3 archivos del cambio (41 en verde) y los
  mismos en un worktree en `HEAD` para medir el rojo.
- **`sowing_screen.dart` (la otra puerta):** sigue sin bloquear fechas anteriores a la siembra
  base. Es la asimetría que el PRD acepta en Q4.
- **Respaldo y sync línea a línea:** me apoyé en el PRD (E15/E16) y en que `date` no cambió de tipo
  ni de serialización.
- **Accesibilidad del nuevo `InkWell`/`InputDecorator`** (semántica, área táctil, foco por teclado)
  y la l10n más allá de confirmar que reutiliza `dateFieldLabel` sin claves nuevas.

## Resumen

| Severidad | Nº | Estado |
|-----------|----|--------|
| CRITICAL  | 0  | pass   |
| HIGH      | 0  | pass   |
| MEDIUM    | 1  | info   |
| LOW       | 4  | note   |

**Veredicto: PASS-CON-NITS** — el código está listo; el único nits que yo arreglaría antes de
cerrar es H1 (reclasificar o reescribir los dos tests del informe, y corregir lo que el PRD
afirma de ellos).
