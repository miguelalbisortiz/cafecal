# Sesión — sábado 17 de octubre de 2026 (la alerta, la moneda, el signo y F4)

Estado al cierre. Anteriores de hoy: `2026-10-17-campo-de-fecha-en-perdidas.md` (el campo de
fecha de las pérdidas), `2026-10-17-entorno-motores-plugins-y-mcp.md` (la mañana) y
`2026-10-16-cierre-mensual-y-reparto-por-hectareas.md`.

---

## 1. Qué se hizo (cuatro cosas, en este orden)

### a · La alerta dejó de mandar a una puerta que no existe

La regla 13 (`alertFirstHarvestSuggestion`) decía *«Si ya cosechaste, registrá esa cosecha y este
aviso desaparece»* y **no había dónde**: la pantalla de Cosechas salió del menú el 2026-09-24. La
puerta que sí existe —y que la Ayuda ya enseñaba— es **anotar la venta con sus kilos**: de ahí la
app deriva la cosecha (`derived_harvests.dart`) y el aviso se apaga solo. Texto nuevo (ES y EN):

> Revisá el cultivo: si cambió algo o la fecha ya no va, editala. Si ya vendiste, anotá esa venta
> con los kilos y el dinero que te pagaron: con esos kilos la app ya sabe que cosechaste y este
> aviso desaparece.

El **mensaje** se quedó como estaba: «no registraste ninguna cosecha» es lo que él estimó contra lo
que la app sabe, y «cosecha registrada» ya es el idioma de la Ayuda (§2, D2).

### b · El desplegable de moneda ya no usa el `$`

`currency_setup_gate.dart:80` pintaba `'${c.symbol} ${c.name} (${c.code})'` → `$ Peso colombiano
(COP)`. Ahora dice **`Peso colombiano (COP)`**, igual que el botón que lo confirma y que el texto
bajo Monto: el **código** es el único indicador, porque `$` lo comparten COP, USD y CLP.

### c · El negativo en pantalla lleva su signo

El informe tenía un `_accounting()` propio (9 usos) que pintaba `(COP 1.500)` **en pantalla**,
mientras el resto de la app usaba `-COP 1.500`. Ahora ese helper es `_signed(tx, …)` (el `context`
sobraba) y delega en `formatAmount`: **en pantalla, signo**. Los **exportadores** conservan el
paréntesis contable de `formatMoneyLabel`, porque el PDF y el Excel los lee un contador — y el
porqué quedó escrito junto a esa función, para que nadie vuelva a mezclarlos. Lo pedían el PRD del
2026-10-01 (el paréntesis confunde a quien no es contador) y el P4 del plan de mejoras.

### d · F4 ya estaba hecho; le faltaba el test del cableado

Ver §3.

---

## 2. Las decisiones (las cuatro, del usuario)

| # | Pregunta | Decisión |
|---|---|---|
| D1 | ¿Cómo queda la sugerencia de la alerta? | Con el **idioma de la Ayuda**: manda a la venta con sus kilos |
| D2 | ¿Se toca también el mensaje? | **No**, solo la sugerencia |
| D3 | ¿Qué etiqueta en el desplegable de moneda? | `Peso colombiano (COP)` |
| D4 | ¿Cómo queda el negativo? | **Signo en pantalla**, paréntesis en los exportadores |

Y el criterio con el que se escribió el texto de la alerta: *«de acuerdo a lo que se da en la
práctica real del agricultor»* — el agricultor no registra cosechas, **vende**.

---

## 3. F4: lo que ya estaba y lo que faltaba

F4 (plan del ciclo, **0-A**) no estaba pendiente de código: estaba puesto y cableado.

- `crop_editor_dialog.dart`: bandera `sowingsLocked` (24) con `enabled: false` en área y plantas,
  `cropLockedHint` («Calculado desde tus siembras») y la **salida** (527-537): botón *Registrar
  pérdida* → `CropLossDialog` → refresca el contador.
- `crops_screen.dart:282`: al editar pasa `sowingsLocked: _hasInitialSowing(tx, crop)` (`:347`).
  Al **crear** y en «Completar cultivo» no lo pasa, y hace bien: ahí todavía no hay siembras.
- Textos: `cropLockedHint` = «Calculado desde tus siembras», `cropLossRegister` = «Registrar
  pérdida».
- Dos tests ya probaban **el diálogo** (`crop_editor_dialog_test.dart:423,459`).

Lo que faltaba era la pieza que ata las dos mitades: **que la pantalla encienda la bandera**. Se
añadió ese test en `crops_screen_test.dart` — y se comprobó en **rojo** apagando la bandera a
mano. El plan queda marcado `[x] F4 … HECHO 2026-10-17`.

---

## 4. Tests y rojo/verde de verdad

| Arreglo | Test | Rojo medido |
|---|---|---|
| a · la alerta | `first_harvest_alert_test.dart` (+1) | Con el texto viejo: `Expected` la frase nueva vs `Actual` «Si ya cosechaste, registrá esa cosecha…» |
| b · la moneda | `onboarding_flow_test.dart` (+1) | `Found 0 widgets with text "Peso colombiano (COP)"` |
| c · el signo | `report_screen_test.dart` (+1) | **4** widgets `(COP 5.000)` en pantalla |
| d · F4 | `crops_screen_test.dart` (+1) | Con la bandera apagada: 0 widgets con «Calculado desde tus siembras» |

Ojo con el finder del signo: la guarda busca **el monto exacto** `(COP 5.000)`, no «cualquier
paréntesis con COP», porque el resumen tiene uno legítimo en prosa (*«Tu mayor gasto fue
Fertilizante (COP 5.000, el 100% del total)»*). Ese texto no es notación contable y se queda.

Gate: `flutter analyze` limpio · **934/934** (la tanda empezó con 933).

---

## 5. Git y despliegue

| Rama | Commit | Estado |
|---|---|---|
| `main` | `4efd6bc` | sincronizada con `origin/main` |
| `gh-pages` | `6c16772` | sincronizada |

| Commit | Qué |
|---|---|
| `9bf595c` | alerta: la salida manda a la venta, que es la puerta que existe |
| `79917b5` | moneda: el desplegable nombra la moneda por su código, no por el símbolo |
| `3f1c952` | informe: el negativo en pantalla lleva su signo, no paréntesis contables |
| `4efd6bc` | F4: el bloqueo queda con su test de cableado, y el plan lo marca hecho |

Producción verificada descargando el archivo publicado (HTTP 200):

`F8CC64C7F04CC66240DCF3FA9ED276570F08F2F9FC4DD20564168527DB080FBC` · 4.794.508 bytes
(el build anterior, de esta misma tarde: `71AA45E8…` · 4.794.542).

---

## 6. Hallazgos que NO se abrieron

1. **Las alertas pintan los montos con `$` y sin código** (`alert_service.dart:785`: `-$5.000`),
   contra la regla del código único. Es la misma familia que la moneda y el signo.
2. **`CurrencyInfo.symbol` ya no lo pinta nadie**: solo lo usan su definición y su propio test.
3. **F5 podría estar hecho en parte**: `crops_screen_test.dart` ya trae dos tests de la edad junto
   a la fase, y el plan lo da por pendiente.

---

## 7. Pendientes

- **F5 · Fecha, fase y edad** (plan del ciclo): comprobar qué falta de verdad. Incluye la
  migración de Supabase (`crops.planted_at`), que **aplica el usuario**.
- **F6 · Saco configurable**: dimensionar antes de comprometerlo.
- **Fase 5 y 6** del plan de la cosecha derivada (la guía y sus textos).
- El **`$` de las alertas** (§6.1).

---

## 8. Reglas de la casa que no se negocian

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Una sola función para una sola regla.
- Cada arreglo con su test, **verificado fallando sin su arreglo** (y si el código ya está, se
  apaga la pieza a mano para verlo caer).
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
