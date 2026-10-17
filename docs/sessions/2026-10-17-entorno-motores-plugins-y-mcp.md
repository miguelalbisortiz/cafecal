# Sesión — sábado 17 de octubre de 2026 (la mañana: entorno)

Esta es la sesión de la **mañana** (motor, plugins, MCP y LSP). Por la tarde llegó la
siembra y el incidente del PAT: ver `LATEST.md`.

Estado al cierre de aquella sesión. Anterior: `2026-10-16-cierre-mensual-y-reparto-por-hectareas.md`.

---

## 1. ¿Dónde quedó el proyecto?

**Publicado y sin tocar.** Hoy **no se cambió ni una línea de la app** ni se desplegó
nada. Todo el trabajo fue del **entorno**: motor, plugins, MCP y LSP.

| Rama | Commit | Estado |
|---|---|---|
| `main` | `46596f5` | sincronizada con `origin/main` |
| `gh-pages` | `347b185` | sincronizada con `origin/gh-pages` |

La web en vivo y el build local **coinciden bit a bit**, re-verificado hoy descargando
el archivo publicado:

`3C3CCD3B2FD3F391A3D0FE19C3294DEAEA4EC2A1FEF6079E191312D26EA2F96C` · 4.792.536 bytes.

Es decir: los commits de la Fase 1 y la Fase 2 del registro ya estaban desplegados
antes de esta sesión, y siguen igual.

---

## 2. El hallazgo que ordena todo: hay DOS OpenCode

| | |
|---|---|
| **El motor que te ejecuta** | **`2.0.32`**, dentro de la app: `ai.opencode.desktop\cli\2.0.32-x64\opencode-cli.exe serve --service`. Es la **API V2**. |
| El `opencode` de la terminal | `opencode-ai@1.19.3` (npm global). **Otro OpenCode distinto.** |

La app **no usa el npm global**: trae su propio motor. Lo que hace la app es, en
esencia, un `opencode serve` con una ventana encima.

**Consecuencia práctica:** si algún día tecleas `opencode` en una consola dentro de
este proyecto, leerá **tu misma config** (`opencode.json` + `.opencode/`) pero con
**otro motor**, y puede darte resultados distintos. Eso fue exactamente lo que
despistó el diagnóstico de hoy: dos motores escribiendo en el mismo log con mensajes
distintos para el mismo plugin.

**Decidido por el usuario: el npm global se queda.** No afecta a la app, ni al
proyecto, ni al deploy. Es un agente OpenCode completo, instalado y parado.

---

## 3. Lo que se arregló hoy (todo del entorno)

### A · `hookify.js` — cargaba fallando; ahora carga **y actúa**

Era **CommonJS** y el motor pide **ESM** con la forma de la API V2. Tres cambios:

| Antes | Ahora |
|---|---|
| `require("node:fs")` | `import { … } from "node:fs"` |
| `module.exports = async () => ({…})` | `export default { id, setup, server }` |
| Solo V1 (y fallaba igual) | **V1 y V2 desde el mismo archivo** |

La rama V2 usa `ctx.tool.hook("execute.before", …)` y **reutiliza los mismos dos
helpers** (`secretBlocker`, `destructiveWarner`): no se duplicó ninguna regla, solo
se traduce de dónde vienen los datos (`event.tool`/`event.input` ≡ `input.tool`/`output.args`).

**Verificado en vivo**, sin reiniciar: el *watcher* de la sesión viva recarga al editar.

| Hora (UTC del log) | Qué | Resultado |
|---|---|---|
| 14:10 | versión anterior | ❌ `failed to load plugin` |
| 14:14 | versión V1+V2 | ✅ carga |
| 14:16 | tras el arreglo de rutas | ✅ carga |

Y no es que solo cargue: **el hook se dispara de verdad**. Bloqueó una escritura real
en vivo, con su mensaje `[hookify:SecretBlocker] blocked write to …`.

### B · 🔴 Agujero de seguridad en `SecretBlocker` — **corregido**

`isSecretPath` comparaba las rutas asumiendo separador `/`. En Windows, una ruta
normal con `\` **se colaba**: se podía escribir en `.env` desde la sesión, que es
justo lo que este hook existe para impedir.

Arreglo en **un solo sitio**: normalizar `\` → `/` antes de comparar. Rojo/verde con
**la misma entrada**:

| Entrada | Antes | Ahora |
|---|---|---|
| `D:\…\.env.<sonda>` | ❌ **se creaba** | ✅ **bloqueado** |

### C · `.opencode/agents/` — 11 archivos invalidaban **toda** la configuración

Once agentes tenían `write: confirm`, que **no es un valor válido** en OpenCode. El
CLI no llegaba a arrancar:

```
Expected PermissionActionConfig, got "confirm"   (permission.write)
```

Corregido a `ask` (mismo significado: preguntar antes de escribir). No era un problema
de esos once agentes: **invalidaba la configuración entera**.

### D · MCP y LSP

- **`context7`**: arreglado. En Windows `npx` a secas no resuelve → `cmd /c npx …`.
  **Probado** con una llamada real, en vivo.
- **`supabase`**: **quitado**. El paquete declarado `@supabase/mcp-server` **no existe**
  (404 en npm); el real tiene otro nombre. Es opcional en `mcp.optional.json`.
- **LSP de Dart**: **probado de verdad** con `opencode debug lsp diagnostics` →
  devuelve el error de tipo real y el lint, con `source: "dart"`. Antes no había forma
  de comprobarlo (esa orden no existía en el motor viejo). **Estaba funcionando.**

---

## 4. Deudas y avisos

🔴 **Revocar el PAT de Supabase.** `sbp_fcc730…` **ya no está en `.env`** (se limpió),
pero **el token sigue existiendo**. Solo tú puedes revocarlo: supabase.com →
Settings → Access tokens.

🟡 **`opencode-vibeguard` 0.1.0 y `opencode-pty` 0.4.0 no pueden funcionar.** Son la
**última versión publicada** de cada uno, y son V1: no existe versión V2. Se quitaron
de `opencode.json`. Reversibles el día que publiquen V2; **ningún `npm` lo arregla**.

🟡 **`docs/plans/` sin commitear** — 2 M + 5 ??. Trabajo propio del usuario; no se
tocan sin verbo explícito.

🟡 **`deploy.ps1` no lo cubre ningún test.** Punto ciego declarado, sin cambios.

🟡 **`.opencode/` está gitignorado** (`.gitignore:84`) y `opencode.json` no lo sigue git:
por eso **no hay nada que commitear** de todo lo de hoy.

---

## 5. Cómo continuar

**Nada urgente.** Como hoy no se tocó la app, no hay nada que verificar en producción.

1. **Revocar el PAT.** Sigue siendo lo único que solo tú puedes hacer.
2. Si quieres un arranque limpio: **reiniciar la app**. Hay que **salir de verdad**
   desde la bandeja del sistema o el menú — cerrar con la X puede dejarla viva.
3. Tras reiniciar, comprobar que no falla ningún plugin:

```powershell
Get-Content "$env:USERPROFILE\.local\share\opencode\log\opencode.log" -Tail 60 |
  Where-Object { $_ -match 'failed to load plugin' }
```

Si no imprime nada: **ningún plugin falla.**

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Los tres pintadores (Reportes, PDF, Excel) dicen lo mismo, en el mismo sitio.
- Una sola función para una sola regla.
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
