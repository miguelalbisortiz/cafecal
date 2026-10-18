---
status: DONE
created: 2026-10-17
updated: 2026-10-17
prd: docs/prds/2026-10-17_2038-ayuda-fiel-a-la-app.prd.md
---

# La Ayuda fiel a la app de hoy — plan de la tanda

> De dónde sale: `docs/prds/2026-10-17_2038-ayuda-fiel-a-la-app.prd.md` (APPROVED), con
> las 8 decisiones D1–D8 cerradas por el usuario el 2026-10-17.

## Qué se va a hacer

Que la sección **Ayuda** (`lib/screens/help_screen.dart`) represente y muestre la app
como está hoy: los arreglos de lo que hoy miente (A1–A3), el mapa completo y seis bloques
nuevos más «¿Y por planta?». Nada de comportamiento nuevo: solo copy, bloques y dos guardas.

## Reglas de la tanda

- Solo se toca `lib/screens/help_screen.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
  y `test/` (SC17). Nada de Cosechas, nada de features nuevas (SC18).
- ES es la plantilla; el EN se escribe a mano, sin inventar términos. Placeholders en el
  orden de la frase; `& C:\flutter\bin\flutter.bat gen-l10n` tras tocar los ARB.
- `null` → oculto, nunca `0`; ninguna cifra nueva (solo las que ya produce la app).
- El código de moneda es el único indicador (`COP 1.500`), nunca `$`.
- Cada pieza con su test, **visto en rojo antes de su arreglo**.
- Gate antes de commit/deploy: `flutter analyze` sobre el proyecto entero (`tool/`
  incluido) + `flutter test`.

## Tandas

### T1 · Lo que hoy miente (A1–A3 · D2, D3, D4)

- **A1 · unidades (D2).** En `help_screen.dart`, la tabla sube a **7 filas** en el orden
  de la app (kg, lb, arroba, saco, carga, racimo, cajón) usando `helpUnitsLbRow(+Desc)` y
  `helpUnitsCargaRow(+Desc)` (ya escritas en el ARB, hoy sin pintar); los **chips** pasan a
  7 añadiendo `_UnitChip(l10n.unitLb)` y `_UnitChip(l10n.unitCarga)` — ojo: los chips usan
  las claves `unit*`, no las `helpUnits*Row`.
- **A2 · título huérfano (D3).** Se **borra** `helpExampleTitle` de los dos ARB.
- **A3 · glosario (D4).** En `helpGlossaryBody` (ES y EN): fuera «Destino: vendido o
  pérdida.»; entra «Vendido vs cosechado: cuánto de la cosecha ya salió como venta.»
- **Prueba T1:** la guarda **G2** en rojo antes de pintar/borrar (cae listando las 7
  huérfanas) y verde después.

### T2 · El mapa y lo que la app es hoy (SC1 · D1)

- **Mapa (SC1).** +6 filas a «¿Dónde entro cada dato?»: Reporte, Trabajadores, Jornal,
  Lote, Configuración e Historial (claves `helpRow*` nuevas), nombrando cada pantalla con
  su etiqueta real (`menuReport`, `menuWorkers`, `menuCrops`, `menuSettings`,
  `tabHistory`, `tabRegister`).
- **Sección «Lo demás que hace la app» (D1).** Una sección con 6 tarjetas: terrenos (9.1),
  trabajadores (9.2), caja del mes (9.3), reporte y sus archivos (9.4), respaldo (9.5) e
  idioma y números (9.6). El copy es el del PRD (§Bloques nuevos), ES y EN tal cual.
- **Bloque «¿Y por planta? ¿Cuándo empieza a rendir?» (SC10).** Tarjeta nueva con
  `helpPerPlant*` (§7 del PRD), después de «Por hectárea».
- **Prueba T2:** la guarda **G1** (menú ↔ mapa) y una prueba de pantalla que monta
  `HelpScreen` y exige los 8 destinos y los títulos de los 6 bloques nuevos.

### T3 · Cierre — hecho

- Gate completo (analyze del proyecto entero + test) ✅ y publicado ✅: `gh-pages` en
  `441db97`, huella `EFC05ADC15E5B0D09FCB1906C35274CDD1A8E847294A34842D8107E29378173A`
  · 4.806.917 bytes.
- Snapshot en `docs/sessions/2026-10-17-la-ayuda-fiel-a-la-app.md` + `LATEST.md`,
  cinco patrones y cinco bugs en `docs/LEARNING.md`, PRD y plan al día.
- Commits: `81ccc0c` (T1), `59db9fc` (docs PRD y plan), `a47bdc2` (T2), más el papeleo.

### T4 · La revisión del usuario — hecho

El usuario revisó la Ayuda publicada y trajo cuatro observaciones (2026-10-17, después de
T3). Las cuatro quedaron cerradas, publicadas y con guarda.

- **A4 · el orden de la app eran cinco pasos, y contradecían a la app.** La Ayuda ponía
  «La cosecha» como paso 4, *antes* de «Registrar venta» (paso 5), cuando su propio texto
  decía que la cosecha sale de los kilos de la venta. `lib/services/next_step_service.dart`
  (líneas 7-21) deriva **cuatro** pasos (`crop → sowing → expenses → sale`) y anota que no
  hay un «registrar cosecha» aparte. Ahora: 4 pasos, el cuarto es la venta («A quién
  vendiste, cuánto y los kilos: de ahí sale tu cosecha»), con el icono de venta; las claves
  `helpFlowStep5*` se borraron de los dos ARB y del código.
- **A5 · a la finca vacía se la llamaba «cultivo».** El caso B pasa a «No tengo nada
  todavía y voy a empezar»; su paso 1 dice «Dile a la app qué vas a sembrar» y el paso 2
  nombra la puerta que existe (`sowingNewCropOption` = «+ Crear nuevo cultivo.», el
  desplegable de Siembras). El ejemplo pasa a «plátano recién sembrado» y `helpCaseB4`
  deja de decir «cosechas y ventas».
- **A6 · tipografía y sangría desparejas.** La pantalla mezclaba seis tamaños (11, 12,
  12.5, 13, 13.5, 14). Queda **un tamaño por papel**: 11 el número del paso, 12.5 las
  celdas de tabla y los chips, 13 la prosa y las etiquetas, 13.5 los títulos de bloque y
  14 solo el párrafo de arranque del resumen. Las flechas y las tablas se conservan.
- **A7 · el arranque no representaba la app (lo más importante para el usuario).** La
  tarjeta de «Guía para empezar» pasa a un párrafo de arranque («Mi Cafetal es el cuaderno
  de cuentas de tu finca…») y **tres filas**: «Para qué te sirve» (finalidad), «Qué hace»
  (funcionalidad) y «Tus datos son tuyos» (confianza y control: «nada se inventa: si un
  dato falta, lo deja en blanco en vez de poner un cero»). `helpIntroPromesa` queda
  absorbida por la fila 3 y se borra de los dos ARB.
- **Defecto de paso encontrado:** el `helpIntro` en inglés decía **otra cosa** que el
  español (invertía, cultivo/mes/año). Los dos idiomas dicen ya lo mismo.
- **Cierre T4:** gate completo ✅ y publicado ✅ — `gh-pages` en `0b5a1de`, huella
  `D3E4CA3754E8079C30378F151D50DAA0C9F880FD9AB7EE2EFFBDEA0CDD3945C7` · 4.808.752 bytes
  (producido y verificado en producción). `flutter analyze` sin issues · **954/954** tests
  (950 previos + las 4 guardas nuevas).

## Guardas

- **G1 · menú ↔ mapa** (`test/help_menu_map_test.dart`). Extrae los `value: '<string>'`
  del `PopupMenuButton` de `home_screen.dart`, los cruza con un mapa declarado
  `{report: menuReport, crops: menuCrops, sowings: menuSowings, workers: menuWorkers,
  settings: menuSettings}` más allowlist explícita `{help: menuHelp, logout: menuLogout}`
  (los dos se exigen pintados, pero no son destinos de datos), falla si el conjunto del
  código ≠ mapa ∪ allowlist, y monta `HelpScreen` exigiendo cada etiqueta mapeada.
- **G2 · huérfanas** (`test/help_no_orphan_keys_test.dart`). Lee `lib/l10n/app_es.arb`,
  junta las claves que empiezan por `help`, busca `l10n.<clave>` en `lib/screens/` y
  `lib/widgets/` (solo producción, nunca el generado ni los tests) y falla listando las
  que nadie pinta.
- **G3 · el orden de la app son cuatro pasos** (`test/help_coherencia_test.dart`, ES y EN).
  Cuenta las claves `helpFlowStep\d+(Title|Body)` de los dos ARB (tienen que ser 8) y exige
  que ningún título de paso mencione la cosecha.
- **G4 · a la finca vacía no se la llama «cultivo»** (mismo archivo). El título del caso B
  no dice «cultivo»; y si el paso de la siembra cita «Crear nuevo cultivo», esa opción
  tiene que existir de verdad en el ARB (`sowingNewCropOption`).
- **G5 · un tamaño de letra por papel** (mismo archivo). Barre los `fontSize:` de
  `help_screen.dart`: todos dentro de `{11, 12.5, 13, 13.5, 14}` y el 14 exactamente una
  vez (el párrafo de arranque).
- **G6 · el arranque dice finalidad, funcionalidad y datos** (mismo archivo). Monta
  `HelpScreen` y exige pintados los tres rótulos del resumen.
  G3–G5 se vieron **caer** contra los archivos de `HEAD` (copiados a `%TEMP%` con
  `git show`, sin tocar el árbol de trabajo) antes del arreglo: 10 claves de paso en vez de
  8, «estoy empezando un cultivo nuevo desde cero», y el tamaño `12.0` colado en la lista.
- **Ajuste de una guarda vieja:** `test/help_screen_test.dart` montaba la pantalla en una
  ventana de 900x6000 y, al crecer el arranque, el Glosario quedaba fuera del viewport
  (`find.text` no lo veía). La ventana sube a 900x12000 —lo que verifica no cambia—.

## Criterios de aceptación

Los 18 del PRD (§Success Criteria). Cada tanda cierra los suyos, con su prueba vista en rojo.

## Riesgos (del PRD, vigentes)

- G1 es guarda de **contrato**, no de verdad semántica: vigila que el destino esté
  nombrado, no que esté bien explicado (eso queda en revisión humana).
- Si alguna clave `help*` pasara a usarse dinámicamente, G2 daría falso positivo (hoy no
  ocurre: el escaneo da exactamente los 7 reales).

## Fuera de alcance

Lo del PRD: comportamiento nuevo, re-habilitar Cosechas, features o alertas nuevas,
rediseño de la Ayuda (sin acordeones, imágenes ni capturas), `terminology_guide.dart`,
`backup.html` y la nube. El papeleo (`docs/sessions/`, `docs/LEARNING.md`) va en T3, no
antes.
