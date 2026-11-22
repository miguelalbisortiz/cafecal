---
prd: no aplica (sale de la auditoría visual)
audit: docs/audits/2026-11-21_1912-visual-menu-navegacion.audit.md
status: IN_PROGRESS
decisions: D1-D4 confirmadas por el usuario el 2026-11-22 (las cuatro como recomienda el plan)
progress: F0 DONE · F1 DONE (2026-11-22) · F2-F6 pendientes
created: 2026-11-21_1912
---

# Plan: navegación, menú y retorno

## Estado

| Fase | Estado | Evidencia |
|---|---|---|
| 0 · Línea base | **DONE** | `analyze` limpio · 1550 tests antes de tocar nada · guarda de humo de 3 destinos |
| 1 · No perder lo escrito | **DONE** | `IndexedStack`, `didUpdateWidget` del prefijo, `PopScope` con diálogo; 5 tests nuevos |
| 2 · Reparto de navegación | pendiente | — |
| 3 · Retorno y jerarquía | pendiente | — |
| 5 · Layout a 360 px | pendiente | — |
| 6 · Accesibilidad y limpieza | pendiente | — |
| 4 · Router / PWA | pendiente (con PRD) | — |

Reporte de las fases 0 y 1: `docs/reports/2026-11-22_0851-fase0-1-navegacion.report.md`.

## Objetivo

Que el caficultor pueda **registrar un gasto sin perderlo**, **llegar a cualquier
pantalla en un toque** y **volver sin quedar atrapado**, sin tocar el modelo de
datos, sin subir el SDK y sin cambiar lo que la app calcula.

Este plan no agrega funcionalidad de negocio. Reordena lo que ya existe y
arregla tres pérdidas silenciosas de trabajo.

## De dónde sale

Auditoría con capturas en `docs/audits/2026-11-21-visual/` (360 / 768 / 912 px)
y prueba en vivo de la build desplegada. Los hallazgos se numeran **1–13** en la
auditoría; el "volver" está en el anexo como **R1–R3**.

## Decisiones que hay que tomar antes de empezar

| # | Decisión | Recomendación |
|---|---|---|
| D1 | ¿"Historial" pasa a llamarse "Movimientos"? | Sí. "Movimientos" es lo que el usuario ve en la pantalla; "Historial" suena a archivo muerto. Es el único renombre visible. |
| D2 | ¿"Finca" es pantalla-hub o submenú? | Hub en móvil, submenú solo en ≥840 si sobra tiempo. Un hub es más descubrible con el pulgar. |
| D3 | ¿Router ahora o después? | Después. Fase 4 es la única que puede romper la app entera; las fases 1–3 ya entregan el 80 % del valor. |
| D4 | ¿Se retira Cosechas o se conserva? | Conservar la pantalla, borrar el bloque comentado. Retirar la feature es otro PRD. |

## Orden y por qué

| Fase | Qué resuelve | Hallazgos | Tamaño |
|---|---|---|---|
| 0 | Línea base y red de seguridad | — | S |
| 1 | No perder lo escrito | R2, R3 | S |
| 2 | Reparto: FAB, barra, Finca, menú | 1, 2, 3 | L |
| 3 | Retorno y jerarquía | 6, 7 | M |
| 4 | Router / PWA | R1 | L |
| 5 | Layout a 360 px | 4, 5, 8, 9, 10 | M |
| 6 | Accesibilidad y limpieza | 11, 12, 13 | S |

**Regla de secuencia:** 1 → 2 → 3 → 5 → 6 → 4. La fase 4 va al final porque es
la única que exige un PRD y puede arrastrar todo lo demás.

Cada fase termina en un **gate**: `flutter analyze` limpio + `flutter test` en
verde + capturas a 360/768/912. Sin commit ni push sin verbo explícito.

---

## Fase 0 · Línea base (S)

### 0.1 Congelar el estado actual
- Qué: registrar el conteo de tests y el estado de `flutter analyze` **antes** de tocar nada.
- Cómo: `flutter analyze`, `flutter test`, anotar ambos resultados en el reporte de la fase.
- Aceptación: existe una cifra de referencia contra la que comparar.

### 0.2 Test de humo de navegación
- Qué: un widget test que monte `HomeScreen` y verifique los destinos actuales.
- Dónde: `test/home_screen_test.dart` ya monta `HomeScreen` (`:45`); `onboarding_flow_test.dart:242` ya busca `NavigationBar`.
- Aceptación: el test falla si mañana alguien quita un destino sin querer.

**Gate 0:** analyze limpio, tests verdes, cifra anotada.

---

## Fase 1 · No perder lo escrito (S) — P0

Es la fase más barata y la que más se nota. Va primero.

### 1.1 `IndexedStack` en las pestañas
- Qué: `_body()` devuelve un widget nuevo en cada cambio de pestaña, así que el
  formulario, el scroll y los filtros se destruyen.
- Dónde: `lib/screens/home_screen.dart:345-350`.
- Cómo: cambiar el `switch` por un `IndexedStack(index: _tab, children: [...])`
  con los tres hijos construidos una vez.
- **Trampa conocida:** `RegisterScreen` lee `widget.initialType` en `initState`
  (`register_screen.dart:243`) y hoy funciona porque el widget se recrea. Con
  `IndexedStack` el `State` sobrevive: hay que aplicar el cambio en
  `didUpdateWidget` cuando `initialType` llega no nulo. El reset a `null` en
  `home_screen.dart:427-429` debe seguir funcionando.
- Test en rojo: escribir en Monto → cambiar a Resumen → volver → el valor sigue.
- Test: `_goRegister(TransactionType.income)` sigue abriendo con **Ingreso** marcado.
- Aceptación: no se pierde texto, scroll ni filtro al cambiar de pestaña.

### 1.2 `PopScope` en Registrar
- Qué: salir con el formulario a medias no avisa.
- Dónde: `register_screen.dart` (raíz del formulario; hoy no hay `PopScope` en `lib/`).
- Cómo: `PopScope(canPop: false, onPopInvokedWithResult: ...)` con un diálogo
  "¿Descartar este registro?" cuando haya monto, cultivo o categoría. Sin datos,
  `canPop: true`.
- Test: con monto escrito, atrás muestra el diálogo y "Cancelar" no sale.
- Test: sin datos, atrás sale directo, sin diálogo.
- Aceptación: ninguna salida accidental borra un registro empezado.

### 1.3 Conservar scroll y filtros
- Qué: verificar que Movimientos conserva filtro y posición con el `IndexedStack`.
- Cómo: si el scroll se reinicia, añadir `PageStorageKey` a las listas.
- Aceptación: bajar en Movimientos → cambiar de pestaña → volver → misma posición.

**Gate 1:** analyze + tests + prueba manual del formulario en 360 px.

---

## Fase 2 · Reparto de navegación (L) — P0

### 2.1 Registrar sale de la barra y pasa a FAB
- Qué: hoy es una pestaña y queda marcada como sección seleccionada.
- Dónde: destinos en `home_screen.dart:286-338`; entrada en `_goRegister:422-430`
  y `_onNextStep:432-451`.
- Cómo: `_openRegister([type])` que haga `Navigator.push` de un `Scaffold` con
  AppBar "Registrar" y `RegisterScreen` como body. `RegisterScreen` hoy no tiene
  Scaffold propio (su AppBar de `:1837` es del modo edición), así que el wrapper
  es obligatorio.
- Ojo: al guardar, `Navigator.pop` y volver a la pestaña de origen.
- Test: el FAB está en las tres pestañas y no aparece en onboarding.
- Test: `_onNextStep(expenses)` abre la ruta con **Gasto** preseleccionado.
- Aceptación: registrar es 1 toque desde cualquier pestaña; nada queda "seleccionado".

### 2.2 Barra: Resumen · Movimientos · Reportes
- Qué: Reportes está enterrado en el menú y además pierde la barra al abrirse.
- Dónde: `report_screen.dart:182` (AppBar propia), `home_screen.dart:317-338`.
- Cómo: Reportes pasa a pestaña. Hay que **extraer el body** de `ReportScreen` o
  parametrizar `showAppBar`, porque hoy trae su propio `Scaffold`.
- Test: cambiar a Reportes conserva mes/año seleccionados; la barra sigue visible.
- Aceptación: Reportes a 1 toque y sin perder el estado al volver.

### 2.3 Finca: pantalla-hub
- Qué: Cultivos, Siembras y Trabajadores son datos maestros que hoy compiten con
  el uso diario dentro del menú.
- Cómo: `FincaScreen` con tres tarjetas (`menuCrops`, `menuSowings`, `menuWorkers`)
  que hacen push de las pantallas existentes.
- Dónde: nueva `lib/screens/finca_screen.dart`; rutas en `home_screen.dart`.
- Test: desde Finca se llega a las tres; `←` vuelve a Finca, no a Resumen.
- Aceptación: las tres pantallas dejan de estar en el menú y siguen alcanzables.

### 2.4 Menú `⋮`: 4 entradas
- Qué: hoy mezcla destino, datos maestros, sistema y sesión en 7 ítems.
- Dónde: `home_screen.dart:183-277`.
- Cómo: dejar **Finca · Ajustes · Ayuda · Salir** con los divisores actuales.
- Test: el menú tiene 4 entradas; ninguna pantalla queda inalcanzable (test de
  cobertura de rutas: toda pantalla de `lib/screens` se abre desde algún sitio).
- Aceptación: 3 ítems + Salir, sin huérfanos.

### 2.5 l10n ES/EN
- Qué: claves nuevas y un renombre.
- Dónde: `lib/l10n/app_es.arb` y `app_en.arb`.
- Claves: `tabMovements`, `tabReports`, `menuFinca`, `registerTitle`,
  `discardTitle`, `discardBody`, `discardConfirm`, `discardCancel`,
  `fincaHubTitle`, `fincaHubSubtitle`.
- Reutilizar: `menuCrops`, `menuSowings`, `menuWorkers` en las tarjetas de Finca.
- Test: paridad ES/EN (el pack ya tiene tests de l10n).
- Aceptación: `flutter gen-l10n` sin warnings y ninguna clave huérfana.

**Gate 2:** analyze + tests + recorrido completo en 360 px (las 8 pantallas
alcanzables en ≤2 toques).

---

## Fase 3 · Retorno y jerarquía (M) — P1

### 3.1 Una sola regla de título
- Qué: en las pestañas el AppBar dice siempre "Balance"; en Reporte dice "Report".
- Regla: **AppBar = "Balance" en pestañas; = nombre de la pantalla en rutas de
  salida.** Reportes, al volverse pestaña, gana su encabezado en el body como
  Resumen y Movimientos.
- Aceptación: no hay dos títulos distintos para la misma pantalla.

### 3.2 `←` solo donde es salida
- Qué: la flecha debe existir solo en Ajustes, Ayuda, Registrar y las tres de Finca.
- Cómo: las pestañas no llevan `leading`; las rutas empujadas lo heredan del `AppBar`.
- Aceptación: ninguna pestaña muestra flecha; ninguna ruta de salida carece de ella.

### 3.3 La barra no desaparece
- Qué: consecuencia de 2.2 y 2.3. Verificar que Reportes y Finca conservan la barra.
- Test: en Reportes, tocar Historial cambia de pestaña sin volver atrás.
- Aceptación: desde cualquier pestaña se llega a otra en 1 toque.

**Gate 3:** capturas de las 3 pestañas y del menú; comparación con
`docs/audits/2026-11-21-visual/`.

---

## Fase 4 · Router / PWA (L) — P2, con PRD

> **No empezar sin decidir D3.** Esta fase toca la raíz de la app y puede romper
> deep links, recargas y el atrás. Va al final a propósito.

- Qué: R1. Sin router, el atrás del navegador no vuelve y la PWA se cierra.
- Cómo: `go_router` con rutas `/`, `/movimientos`, `/reportes`, `/finca`,
  `/finca/cultivos`, `/finca/siembras`, `/finca/trabajadores`, `/registrar`,
  `/ajustes`, `/ayuda`.
- Restricción: **no subir el SDK** en este plan (Flutter 3.24 / Dart 3.5).
  Fijar la versión de `go_router` que resuelva con esa restricción y anotarla.
- Test: atrás del navegador vuelve a la pantalla anterior.
- Test: recargar en `/reportes` no rompe y abre Reportes.
- Test: link directo a `/finca/cultivos` funciona con sesión y sin sesión.
- Aceptación: R1 deja de reproducirse en la PWA instalada.

**Si no se hace:** documentar en `README.md` que el atrás del navegador no
funciona y que la app debe usarse instalada.

---

## Fase 5 · Layout a 360 px (M) — P1

### 5.1 Tarjetas KPI
- Qué: tres columnas fijas truncan "Inco…", "Expe…", "unchang…".
- Cómo: `LayoutBuilder` → 1 columna < 400, 2 columnas 400–720, 3 columnas ≥ 720.
- Test: a 360 px ninguna etiqueta usa `…` (o `TextOverflow` deja de dispararse).
- Aceptación: las tres cifras se leen completas en un teléfono de 360.

### 5.2 Segmentado del Reporte
- Qué: "Year to date" rompe línea y desalinea el control.
- Cómo: etiqueta corta ("YTD") o scroll horizontal del segmentado.
- Test: a 360 px el control mide una sola línea.

### 5.3 Etiqueta duplicada
- Qué: "Supplier / seller (optional)" aparece como label y como hint.
- Dónde: `register_screen.dart`, campo de proveedor.
- Cómo: dejar uno de los dos.

### 5.4 Breakpoint 840
- Qué: `wide` se decide en 900.
- Dónde: `home_screen.dart:148`.
- Cómo: `>= 840` (M3: compact < 600, medium 600–839, expanded ≥ 840).
- Test: a 850 px aparece el rail, no la barra inferior.

### 5.5 Texto de ayuda del formulario
- Qué: tres líneas explicando "+ New crop…" dentro del formulario.
- Cómo: mover a un `Tooltip` o a la Ayuda contextual; dejar una línea.
- Aceptación: el formulario cabe sin scroll en un teléfono de 640 px de alto.

**Gate 5:** capturas 360/768/912 + test de overflow con `setSurfaceSize`.

---

## Fase 6 · Accesibilidad y limpieza (S) — P2

### 6.1 Semántica de la barra
- Qué: en la build web el árbol de accesibilidad no expone los destinos de la
  barra inferior; solo "Sync" y "Show menu".
- Cómo: confirmar primero en Android/iOS real. Si se reproduce, envolver los
  destinos en `Semantics(button: true, selected: ..., label: ...)`.
- Test: `SemanticsTester` encuentra los tres destinos.
- Aceptación: un lector de pantalla puede cambiar de pestaña.

### 6.2 Idioma por defecto
- Qué: con el teléfono en inglés la app arranca en inglés; el público es colombiano.
- Cómo: `locale: const Locale('es')` por defecto, con selector en Ajustes y
  respeto a la elección guardada.
- Test: con `Locale('en')` del sistema, la app arranca en español salvo que el
  usuario haya elegido inglés.

### 6.3 Limpieza de Cosechas
- Qué: bloque comentado en `home_screen.dart:224-236`.
- Cómo: borrar el bloque; la pantalla y la ruta se conservan (decisión D4).

**Gate 6:** analyze + tests + revisión de que no quedan claves ni imports huérfanos.

---

## Verificación final

| Check | Cómo |
|---|---|
| Estático | `flutter analyze` sin issues nuevos |
| Tests | `flutter test` con conteo ≥ línea base de la fase 0 |
| Móvil | Recorrido de las 8 pantallas a 360 px: ≤ 2 toques cada una |
| Tablet | 768 px: rail o barra, sin desbordes |
| Escritorio | 912 px y 1200 px: rail, sin menús cortados |
| Pérdida de datos | Formulario a medias → cambiar de pestaña → volver: sigue ahí |
| Retorno | `←` en cada ruta de salida; atrás del sistema en Android |
| PWA | Instalada: atrás, recarga, sin conexión (solo si se hizo la fase 4) |
| Capturas | Antes/después en `docs/audits/2026-11-21-visual/` |

## Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| `IndexedStack` rompe `initialType` | Alta | Medio | `didUpdateWidget` + test explícito (1.1) |
| `ReportScreen` embebido trae su propio `Scaffold` | Alta | Medio | Extraer body antes de moverlo a pestaña (2.2) |
| Tests existentes asumen 3 destinos | Media | Bajo | Actualizar `onboarding_flow_test.dart` en la misma tanda |
| `go_router` incompatible con 3.24 | Media | Alto | Gate + versión fijada + no subir SDK (4) |
| El renombre Historial→Movimientos confunde | Media | Bajo | Único renombre, avisado en la Ayuda |
| Usuarios ya acostumbrados al menú actual | Media | Medio | No hay telemetría; validar con 2–3 usuarios antes de publicar |
| El hub Finca agrega un toque a Cultivos | Alta | Bajo | Aceptable: es pantalla de configuración, no de uso diario |

## Fuera de alcance

- Subir Flutter/Dart o `geolocator` (va con otro plan).
- Cambiar el modelo de datos o los cálculos.
- Retirar la feature de Cosechas.
- Rediseño visual de las tarjetas más allá del ancho (colores, tipografía).
- MCP de Dart/Flutter (exige SDK 3.9+).

## Estimación

| Fase | Tamaño | Sesiones |
|---|---|---|
| 0 + 1 | S | 1 |
| 2 | L | 2–3 |
| 3 | M | 1 |
| 5 | M | 1 |
| 6 | S | 1 |
| 4 | L | 1–2 (con PRD) |

Total sin fase 4: **6–7 sesiones**. Con fase 4: **8–9**.
