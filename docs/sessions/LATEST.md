# Sesión — sábado 17 de octubre de 2026 (la alerta, la moneda, el signo y F4)

Estado al cierre. Archivo completo en `2026-10-17-alerta-moneda-signo-y-f4.md`.
Anteriores de hoy: `2026-10-17-campo-de-fecha-en-perdidas.md`, `2026-10-17-entorno-motores-plugins-y-mcp.md`
y `2026-10-16-cierre-mensual-y-reparto-por-hectareas.md`.

---

## 1. ¿Dónde quedó el proyecto?

Cuarta tanda del día, y la web ya sirve lo nuevo (verificado descargando el archivo publicado,
HTTP 200): la alerta que mandaba a una puerta que no existe, el `$` del desplegable de moneda, el
negativo con paréntesis contables en pantalla, y el cierre de F4 con su test.

| Rama | Commit | Estado |
|---|---|---|
| `main` | `4efd6bc` | sincronizada con `origin/main` |
| `gh-pages` | `6c16772` | sincronizada |

Huella en producción:

`F8CC64C7F04CC66240DCF3FA9ED276570F08F2F9FC4DD20564168527DB080FBC` · 4.794.508 bytes
(antes: `71AA45E8…` · 4.794.542).

Los commits de hoy, en orden:

| Commit | Qué |
|---|---|
| `fe30be2` | siembra: el guardado en blanco que reventaba y las pérdidas pegadas a la siembra |
| `77315e8` | los planes del ciclo, el snapshot del 16 y **`docs/LEARNING.md` (nuevo)** |
| `473bd34` | el bloqueo de secretos por contenido, y la raíz deja de llevar un build muerto |
| `1498e5b` | el `DestructiveWarner` revive |
| `0069222` | el cierre de la sesión de la tarde (siembra, el PAT y los huecos que destapó) |
| `83fd9d1` | perdidas: el dia se anota, y la del mismo dia deja de perderse |
| `9f86b95` | docs: el PRD del campo de fecha y el informe de su revision |
| `355831b` | docs: el cierre de la sesión del campo de fecha en las pérdidas |
| `9bf595c` | **alerta: la salida manda a la venta, que es la puerta que existe** |
| `79917b5` | **moneda: el desplegable nombra la moneda por su código, no por el símbolo** |
| `3f1c952` | **informe: el negativo en pantalla lleva su signo, no paréntesis contables** |
| `4efd6bc` | **F4: el bloqueo queda con su test de cableado, y el plan lo marca hecho** |

Gate antes de commit y deploy: `flutter analyze` limpio y **934/934**.

---

## 2. Lo que se tocó la app (cuatro cosas)

**a · La alerta dejó de mandar a una puerta que no existe.** Decía *«Si ya cosechaste, registrá esa
cosecha y este aviso desaparece»* y no había dónde: Cosechas salió del menú el 2026-09-24. Ahora
manda a la puerta real —**anotar la venta con sus kilos**, de donde la app deriva la cosecha— con
el idioma que ya usa la Ayuda. El mensaje se quedó igual (decisión del usuario).

**b · El desplegable de moneda ya no usa el `$`.** `currency_setup_gate.dart:80` pintaba
`$ Peso colombiano (COP)`; ahora dice `Peso colombiano (COP)`, igual que el botón que lo confirma y
que el texto bajo Monto. El **código** es el único indicador.

**c · El negativo en pantalla lleva su signo.** El `_accounting()` del informe (9 usos) pintaba
`(COP 1.500)` en pantalla mientras el resto de la app usaba `-COP 1.500`. Ahora es `_signed(tx, …)`
y delega en `formatAmount`. Los **exportadores** conservan el paréntesis contable
(`formatMoneyLabel`), porque el PDF y el Excel los lee un contador, y el porqué quedó escrito ahí.

**d · F4 estaba hecho; le faltaba el test del cableado.** El diálogo ya tenía la bandera
`sowingsLocked`, los campos bloqueados con «Calculado desde tus siembras» y la salida (Registrar
pérdida → `CropLossDialog`), y `crops_screen.dart:282` ya la encendía. Lo que no tenía era la
prueba de que la pantalla la enciende: se añadió, **verificada en rojo** apagando la bandera a
mano. El plan queda `[x] F4`.

---

## 3. Tests y rojo/verde

Rojo medido en los cuatro: el texto viejo de la alerta · `Found 0 widgets with text "Peso colombiano
(COP)"` · **4** widgets `(COP 5.000)` en pantalla · y 0 widgets con «Calculado desde tus siembras»
al apagar la bandera de F4.

Ojo con el finder del signo: busca el monto exacto `(COP 5.000)`, no «cualquier paréntesis con
COP», porque el resumen tiene uno legítimo en prosa («Tu mayor gasto fue Fertilizante (COP 5.000,
el 100% del total)»).

---

## 4. Deudas y avisos

🟢 **El PAT quedó revocado** (el usuario lo hizo en Supabase): la deuda del 16 está cerrada.

🟡 **`report_creds.env` no se borra**: lo leen `tool/generate_report_tool.dart` y
`tool/verify_auth_write_tool.dart` (EMAIL y PASSWORD de un usuario de prueba). Está gitignored,
nunca salió del equipo y lo cubre el bloqueador. Rota esa contraseña solo si la reutilizas.

🟡 **El bloqueador es un guardián, no una jaula.** Atrapa un secreto escrito de una pieza, no uno
armado en tiempo de ejecución (`"sbp_" + …`). Es lo razonable para un hook.

🟡 **`deploy.ps1` no lo cubre ningún test** — punto ciego declarado, sin cambios.

🟡 **La clave en `argv`** (`deploy.ps1:116-117`) se decidió **no tocar**: es la publishable
—pública y ya dentro del bundle—, así que verla en la lista de procesos no expone nada.

🟡 **`opencode-vibeguard` 0.1.0 y `opencode-pty` 0.4.0 no pueden funcionar**: son la última versión
publicada y son V1. Siguen fuera de `opencode.json`.

---

## 5. Hallazgos que NO se abrieron

1. **Las alertas pintan los montos con `$` y sin código** (`alert_service.dart:785`), contra la
   regla del código único. Es la misma familia que la moneda y el signo.
2. **`CurrencyInfo.symbol` ya no lo pinta nadie**: solo lo usan su definición y su propio test.
3. **F5 podría estar hecho en parte**: `crops_screen_test.dart` ya trae dos tests de la edad junto
   a la fase, y el plan lo da por pendiente.

---

## 6. Pendientes de producto

1. **F5 · Fecha, fase y edad** (plan del ciclo): comprobar qué falta de verdad. Incluye la
   migración de Supabase (`crops.planted_at`), que **aplica el usuario**.
2. **F6 · Saco configurable**: dimensionar antes de comprometerlo.
3. **Fase 5 y 6** del plan de la cosecha derivada (la guía y sus textos).
4. **El `$` de las alertas** (§5.1).

---

## 7. Cómo continuar

**Nada urgente y nada roto.** La web y la app están como quedaron.

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Una sola función para una sola regla.
- Cada arreglo con su test, **verificado fallando sin su arreglo** (y si el código ya está, se apaga
  la pieza a mano para verlo caer).
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
