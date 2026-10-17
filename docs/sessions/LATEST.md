# Sesión — sábado 17 de octubre de 2026 (tarde)

Estado al cierre. Anteriores: `2026-10-17-entorno-motores-plugins-y-mcp.md` (la mañana de
hoy) y `2026-10-16-cierre-mensual-y-reparto-por-hectareas.md`.

---

## 1. ¿Dónde quedó el proyecto?

La app se tocó al mediodía (siembra y pérdidas, §2) y por la tarde **solo el entorno y la
seguridad** (§3). El último despliegue es el del mediodía; después no hubo deploy.

| Rama | Commit | Estado |
|---|---|---|
| `main` | `1498e5b` | sincronizada con `origin/main` |
| `gh-pages` | `331fd56` | sincronizada (el despliegue de siembra del mediodía) |

La web en vivo **sigue sirviendo la misma huella**, re-verificada hoy descargando el archivo
publicado (HTTP 200):

`529DDF8DE3F2B4F6AFD6D46FAABA0AD6F2A30D5A5560AECAA81B1BA5B9DB81E9` · 4.792.977 bytes.

Los commits de hoy, en orden:

| Commit | Qué |
|---|---|
| `fe30be2` | siembra: el guardado en blanco que reventaba y las pérdidas pegadas a la siembra |
| `77315e8` | los planes del ciclo cultivo, el snapshot del 16 y **`docs/LEARNING.md` (nuevo)** |
| `473bd34` | el bloqueo por contenido llega a la shell, `*.env` al `.gitignore`, y la raíz suelta un build muerto (181.249 líneas) |
| `1498e5b` | el `DestructiveWarner` revive (apuntes en la auditoría y en LEARNING) |

Gate antes de los commits de la tarde: `flutter analyze` limpio y **920/920**.

---

## 2. Mediodía: siembra, resiembra y pérdidas (lo único que tocó la app)

Se revisó a fondo el ciclo siembra → resiembra → pérdidas y salieron **dos bugs de verdad**,
los dos reproducidos con un test antes de arreglarlos:

- **El guardado reventaba.** Una resiembra con "plantas nuevas" en blanco y mortandad anotada
  lanzaba `FormatException` y **no se guardaba nada** (el validador permite el campo vacío: la
  mortandad se anota aunque no se repongan plantas). Arreglo: `int.tryParse(...) ?? 0`.
- **Las pérdidas se quedaban pegadas.** Al pasar una resiembra a siembra, `Sowing.copyWith` no
  podía poner `null`, así que conservaba `lostPlants` y `reason`: la fila decía "se perdieron 50"
  y el informe inflaba las "Pérdidas acumuladas". Arreglo: centinela en `copyWith` (el mismo
  patrón que `Crop`), y la siembra manda `null` en tipo.

Y una decisión que ordenó la lectura: **una sola regla de pérdidas**. Solo las resiembras
cuentan pérdidas, y esa regla vive en **una** función, `lossOf(s)`, que usan el modelo
(`recomputeCropState`), la lista y el informe. Además, `Sowing.fromJson` —puerta única de
entrada (disco, nube y respaldo)— **limpia** los registros viejos que traían pérdidas pegadas y
los marca `pendingSync` para subir la corrección. Seis tests nuevos; **920/920** en verde.

Queda **declarado intencional** (lo dice `test/sowing_test.dart`): una resiembra sin siembra
base, o anterior a ella, se ignora. No es un bug.

> Detalle de la sesión: el deploy parecía fallar con «Exited with code 1». No era el script:
> era meter `2>&1` en la tubería, que mezcla el progreso que git y flutter escriben en stderr.
> `deploy.ps1` llegaba a su rama de éxito. Anotado en `LEARNING.md`.

---

## 3. Tarde: un PAT dentro de un archivo, y los huecos que destapó

### El incidente

Al commitear `docs/`, **GitHub rechazó el push**: su protección de secretos encontró un PAT de
Supabase a texto plano en
`docs/sessions/2026-10-16-cierre-mensual-y-reparto-por-hectareas.md:92`. **No salió nada** — el
push se rechazó y el commit era local, así que la historia publicada nunca llevó el valor.

Se sustituyó el valor por la forma enmascarada (`sbp_fcc730…`, la misma que ya usaba `LATEST.md`),
se reescribió el commit con `--amend` y el push volvió a pasar: **aceptado**, y esa aceptación es
la prueba, porque GitHub bloquea cualquier commit que lleve un secreto. Después se purgó el objeto
suelto (`git reflog expire --expire-unreachable=now --all` + `git gc --prune=now`, verificado con
`git cat-file` como inexistente).

**Cerrado del todo: el usuario revocó el PAT en Supabase.** El valor filtrado ya no sirve para
nada, aunque hubiera quedado en algún rincón.

**Lo que enseñó:** el bloqueador de secretos miraba solo el **nombre** del archivo, y exigía
empezar por `.env`. Ni un PAT dentro de un `.md` ni un `report_creds.env` habrían pasado por su red.

### A · El bloqueador reconoce el secreto por su forma

`hookify.js` (gitignored) mira ahora el **contenido** en `edit`/`write`: JWT, `sbp_`, tokens de
GitHub/AWS/Stripe/Google/Slack y bloques de `PRIVATE KEY`. El patrón de nombre cubre `.env`, `env`
y `*.env` —o sea `report_creds.env`, `creds.env` y `prod.env`—, dejando pasar los ejemplos
(`*.env.example`).

Rojo/verde de verdad: **8 casos con Node, 4 en rojo antes** del arreglo y **11/11 en verde**
después (los 3 últimos son de la shell, ver abajo). Y **dos sondas en vivo** bloqueadas por el
plugin que corre en la app, una por nombre y otra por contenido, sin crear ningún archivo.

### B · El bloqueo llega a la shell (y apareció un guardián que no disparaba)

Un `echo <secreto> > archivo` se colaba. Al escribir la regla salió algo mejor: se llamaba en
`bash`, y **en esta superficie el motor llama a la herramienta `shell`**. Ahora la regla se ata a
que la llamada **traiga un comando**, no al nombre. Sonda en vivo: **bloqueada**.

### C · El `DestructiveWarner` estaba muerto

Su registro (`.opencode/logs/destructive.log`) **no había escrito nunca nada**. Dos fallos:
esperaba `bash` —otra vez— y resolvía la ruta desde `process.cwd()`, que en el motor **no es el
proyecto**, con el error tragado por un `catch` silencioso.

Arreglado: la ruta sale de la ubicación del propio plugin (`import.meta.url`), con respaldo en la
carpeta temporal; el comando se busca por nombre y, si no, por tamaño. **Verificado en vivo**: el
registro vuelve a escribirse, y de paso confirma que la herramienta se llama `shell`.

### D · `.gitignore` y la raíz

- `.gitignore`: `*.env`, `*.env.local` y `creds*.env`.
- **La raíz soltó 181.249 líneas**: `main.dart.js`, `flutter*.js`, `canvaskit/`, `icons/`,
  `index.html`, `favicon.png`, `manifest.json` y `version.json` eran una copia muerta de un build
  de septiembre; se destrackearon y se ignoran. Comprobado antes: la API de GitHub confirma que
  Pages publica desde **`gh-pages`** y `deploy.ps1` lo dice él mismo («main queda intacto»), así
  que esos archivos no publicaban nada. **`assets/` no se tocó**: ahí vive `assets/fonts/` que
  declara `pubspec.yaml`.

Informe completo: `docs/audits/2026-10-17-secretos-y-bloqueador.md`.

---

## 4. Deudas y avisos

🟢 **El PAT quedó revocado.** La deuda del 16 está cerrada.

🟡 **`report_creds.env` no se borra**: lo leen `tool/generate_report_tool.dart` y
`tool/verify_auth_write_tool.dart` (EMAIL y PASSWORD de un usuario de prueba). Está gitignored,
nunca salió del equipo y ahora además lo cubre el bloqueador. Rota esa contraseña solo si la
reutilizas en otro sitio.

🟡 **El bloqueador es un guardián, no una jaula.** Atrapa un secreto escrito de una pieza, pero no
uno armado en tiempo de ejecución (`"sbp_" + …`). Es lo razonable para un hook.

🟡 **`deploy.ps1` no lo cubre ningún test** — punto ciego declarado, sin cambios.

🟡 **La clave en `argv`** (`deploy.ps1:116-117`) se decidió **no tocar**: es la publishable
—pública y ya dentro del bundle—, así que verla en la lista de procesos no expone nada.

🟡 **`opencode-vibeguard` 0.1.0 y `opencode-pty` 0.4.0 no pueden funcionar**: son la última
versión publicada y son V1. Siguen fuera de `opencode.json`. Ningún `npm` lo arregla.

🟢 **Los plugins cargan bien**: el log muestra *loading plugin* en cada recarga, y el bloqueador y
el warner actúan en vivo. El «reiniciar y comprobar» que quedaba de ayer quedó resuelto por otro
camino.

---

## 5. Pendientes de producto (de la tanda de siembra)

Señalados y **sin arreglar**, a la espera de verbo:

1. **El diálogo de pérdidas** (`lib/widgets/crop_loss_dialog.dart`) fecha la resiembra con
   `DateTime.now()` y **no tiene campo de fecha**: no deja corregir cuándo se perdió.
2. **El desplegable de moneda** todavía enseña `$ Peso colombiano (COP)`, y el código de moneda es
   el único indicador (ya decidido). Falta rematarlo ahí.
3. **El signo negativo**: en pantalla o en los exportadores, sin decidir.

---

## 6. Cómo continuar

**Nada urgente y nada roto.** La web y la app están como estaban.

- Lo primero, si se retoma el ciclo: **decidir los tres pendientes de producto** de §5.
- El árbol quedó limpio tras `1498e5b`; lo único que este mismo cierre deja pendiente de commit
  son estos dos archivos de sesión.

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Los tres pintadores (Reportes, PDF, Excel) dicen lo mismo, en el mismo sitio.
- Una sola función para una sola regla.
- Cada bug con su test, **verificado fallando sin su arreglo**.
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
