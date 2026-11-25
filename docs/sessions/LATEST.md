# Sesión — martes 24 de noviembre de 2026 (cierre de navegación: fases 2, 3, 5 y 6)

> Cierre del plan `docs/plans/2026-11-21_1912-navegacion-menu-y-volver.plan.md`.
> El usuario pidió seguir el orden recomendado (snapshot → commit/push → prueba
> manual), **excepto la puerta de Cosechas: no se hace**. Fase 4 (router/PWA)
> queda fuera salvo petición expresa.

## 1. Dónde quedó el proyecto

- Plan: fases 0, 1, 2, 3, 5 y 6 **DONE**; fase 4 **NO SE HACE** (D5).
- Gate: `flutter analyze` limpio (proyecto entero) · **1581/1581** tests ·
  `git diff --check` limpio.
- Reporte: `docs/reports/2026-11-24_0923-fases-2-3-5-6-navegacion.report.md`.
- Auditorías: `docs/audits/2026-11-24_0923-…audit.md` (FAIL corregido) y
  `docs/audits/2026-11-24_0941-…audit.md` (PASS-WITH-NITS, 0 FAIL; NIT cerrados).
- `main` estaba en `2ddd38e`, **1 commit adelante** de `origin/main` desde la
  sesión anterior. Commit/push de esta tanda: ver §6.

## 2. Qué se cambió

| Pieza | Antes | Después |
|---|---|---|
| Registrar | pestaña que se quedaba «seleccionada» | ruta desde FAB, prefijo Gasto/Ingreso, `PopScope` al descartar, vuelta a la pestaña de origen |
| Barra / rail | Resumen · Registrar · Historial | Resumen · Movimientos · Reportes (3 destinos); rail desde 840 px |
| Reportes | ítem del menú con `Scaffold` propio | pestaña embebida `ReportScreen(embedded: true)`, mes/año vivos |
| Datos maestros | 3 ítems sueltos | hub `FincaScreen` → Cultivos · Siembras · Trabajadores |
| Menú `?` | 7 ítems mezclados | Finca · Ajustes · Ayuda · Salir |
| l10n | `tabHistory` y claves viejas | ES/EN con claves nuevas y paridad estricta; español por defecto |
| D5 | atrás del navegador sin solución | salida documentada en `README.md`: usar la app instalada |

## 3. Guardas nuevas

31 tests desde la fase 0 (5 de la fase 1 + 26 de estas fases), entre ellos:
- `test/navigation_reachability_test.dart`: barre **todas** las pantallas de
  `lib/screens` y exige **instanciación real** desde otro archivo; excepciones
  explícitas y vigentes.
- `test/navigation_l10n_parity_test.dart`: paridad ES/EN completa de los ARB y
  desaparición de `tabHistory`.
- `test/navigation_hierarchy_test.dart`: FAB en las 3 pestañas, jerarquía de
  flechas, KPI a 360 px, segmentado de una línea, breakpoint 840, arranque en
  español con el sistema en inglés y respeto si el usuario eligió inglés.
- 5.5: test que **mide** el scroll restante del formulario a 360×640.

## 4. Decisiones que conviene recordar

- **Cosechas (D4):** la pantalla se conserva, pero no tiene puerta desde el
  2026-09-24 (decisión de producto). El usuario confirmó el 2026-11-24 que **no**
  se le devuelve. Es el único huérfano permitido por el test.
- **5.5 no cumplida:** a 360×640 el formulario sigue scrolleando 164 px. Se
  resolvió la parte accionable (3 líneas → 1 + tooltip); caber del todo exige
  rediseño y otro plan. Está medido, no declarado como logrado.
- **D5 (router/PWA):** no se hace. El atrás del navegador no cambia de pantalla;
  la salida es usar la app instalada y los controles internos.
- El barrido de cobertura no cuenta menciones ni imports: una puerta es una
  instanciación `Clase(`. Un import suelto daba falso verde.
- La auditoría se corrigió con evidencia, no con palabras: los 4 NIT de la
  segunda pasada se cerraron con tests o con texto verificado en el código.

## 5. Rastro

- Plan: `docs/plans/2026-11-21_1912-navegacion-menu-y-volver.plan.md`.
- Reporte fases 0/1: `docs/reports/2026-11-22_0851-fase0-1-navegacion.report.md`.
- Reporte y auditorías: ver §1.
- Código: `lib/screens/home_screen.dart`, `finca_screen.dart` (nuevo),
  `movements_screen.dart`, `register_screen.dart`, `report_screen.dart`,
  `lib/l10n/*` (ARB y generados).

## 6. Commit y push

Ejecutados en esta sesión; hashes:

- _por completar al terminar el push_

## 7. Queda pendiente

- **Prueba manual (bloqueada aquí):** recorrido visual a 360/768/912 y
  confirmación en Android/iOS con TalkBack/VoiceOver de la semántica de la
  barra. No hay dispositivo ni sesión autenticada en navegador en este entorno.
- Fase 4 (router/PWA): solo si se pide, con PRD propio y `go_router` compatible
  con Flutter 3.24.
- Rediseño del formulario para cumplir 5.5 «sin scroll», si se decide.
- Cosechas: **descartado por el usuario** en esta sesión.
