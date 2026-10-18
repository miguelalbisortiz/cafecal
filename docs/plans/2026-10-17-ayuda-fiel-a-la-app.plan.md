---
status: ACTIVE
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

### T3 · Cierre

- Gate completo (analyze del proyecto entero + test), snapshot en `docs/sessions/` +
  `LATEST.md`, patrón nuevo en `docs/LEARNING.md`, PRD y plan actualizados.
- Commit + push + deploy **con verbo del usuario** en ese turno.

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
