# Project Learnings

Last updated: 2026-10-17

## Code Patterns
- Pattern: una sola función por regla, y separar la regla de LECTURA de la de GUARDADO | `lossOf(s)` decide qué es una pérdida (solo las resiembras) y lo leen el modelo (`recomputeCropState`), la lista y el informe; `Sowing.fromJson` es la puerta única de entrada (disco, nube y respaldo) y limpia el registro viejo al entrar | lib/models/sowing.dart | 2026-10-17
- Pattern: `copyWith` con centinela (`Object? x = _sentinel`) para campos opcionales que se deben poder BORRAR | Con `int?`/`String?` a secas, `copyWith(x: null)` conserva el valor viejo. Ya lo usan `Crop.copyWith` y `Sowing.copyWith` | lib/models/crop.dart, lib/models/sowing.dart | 2026-10-17
- Pattern: arreglar datos viejos del disco al abrir, sin migración nueva | `if (_promotePhasesInMemory()) _store.saveCrops(_crops)` en el constructor; la limpieza de siembras va en `fromJson`, que cubre las cuatro puertas | lib/providers/transaction_provider.dart | 2026-10-17
- Pattern: el código de moneda (COP/USD/CLP) es el ÚNICO indicador; nunca el símbolo (los tres comparten `$`) | dentro de los formateadores | lib/utils/format.dart | 2026-10-17
- Pattern: `null` → oculto, nunca `0`; nunca inventar cifras ni hechos | informes, alertas y listas | varios | 2026-10-17
- Pattern: la app de escritorio trae su PROPIO motor (`2.0.32`, API V2). El npm global `opencode-ai` es otro OpenCode: actualizarlo no toca la app | Los plugins V2 exportan `{ id, setup, server }`; los publicados para V1 no cargan | .opencode/plugins/hookify.js | 2026-10-17
- Pattern (test): el "gemelo". Junto a un test verde se escribe el mismo caso con un solo dato cambiado —el campo en blanco en vez de `0`— y ahí aparece el fallo que el verde tapaba | test/sowing_screen_test.dart | 2026-10-17
- Pattern (plugin): el bloqueador de secretos mira por NOMBRE y por CONTENIDO, y reconoce los secretos por su FORMA (`sbp_` + 20 alfanuméricos, JWT de tres segmentos) y no por palabras sueltas — así la documentación que habla de secretos sigue pasando | .opencode/plugins/hookify.js | 2026-10-17
- Pattern (probar un plugin de `.opencode/`): con Node y sin tocar el original. Se copia el `.js` a un `.mjs` temporal (`.opencode/package.json` no declara `type: module`), se llama a `setup()` con un `ctx` falso que captura el hook y se pasan casos rojo/verde | .opencode/plugins/hookify.js | 2026-10-17
- Pattern: el motor V2 recarga los plugins **en caliente**: al reescribir `hookify.js`, las reglas nuevas ya bloqueaban en la misma sesión (dos sondas bloqueadas, sin crear archivo) | .opencode/plugins/ | 2026-10-17

## Bugs & Solutions
- Bug: resiembra con "plantas nuevas" en blanco y mortandad anotada → `FormatException` al guardar y no se registraba nada (el validador sí permite el campo vacío: la mortandad se anota sin reponer plantas) | `int.tryParse(...) ?? 0` | lib/screens/sowing_screen.dart | 2026-10-17
- Bug: al pasar una resiembra a siembra se le quedaban pegados `lostPlants` y `reason` (el selector siembra/resiembra está activo también al editar), la fila decía "se perdieron 50" y el informe inflaba las "Pérdidas acumuladas" | centinela en `Sowing.copyWith`; pérdidas solo vía `lossOf`; `fromJson` limpia y marca `pendingSync` para subir la corrección | lib/models/sowing.dart, lib/screens/sowing_screen.dart, lib/screens/report_screen.dart | 2026-10-17
- Bug: `write: confirm` en la config de los agentes es un valor inválido (`Expected PermissionActionConfig, got "confirm"`) e invalidaba TODA la config: el CLI no arrancaba | `ask` | .opencode/agents/*.md | 2026-10-17
- Bug: `npx` pelado no resuelve en Windows, así que el MCP `context7` no arrancaba | anteponer `cmd /c` | opencode.json | 2026-10-17
- Bug: `isSecretPath` comparaba la ruta sin normalizarla, así que `D:\...\.env.<algo>` se escribía igual | normalizar `\` → `/` antes de comparar | .opencode/plugins/hookify.js | 2026-10-17
- Bug (falso): correr `deploy.ps1` con `2>&1` dentro de una tubería reporta código de salida 1 aunque el deploy salga bien. No es el script: es mezclar el stderr de git/flutter (`Invoke-WebRequest` y el progreso escriben ahí) en la tubería | no meter `2>&1`; fiarse de la huella del paso 7 | deploy.ps1 | 2026-10-17

## Performance
- Sin registros todavía.

## Security
- Issue: `.opencode/plugins/hookify.js` era CommonJS y el motor V2 no lo cargaba, así que el `SecretBlocker` no protegía nada (fallaba en silencio) | `export default { id, setup, server }` y hooks vía `ctx.tool.hook("execute.before", ...)`; probado en vivo con una escritura real bloqueada | .opencode/plugins/hookify.js | 2026-10-17
- Issue: los tokens de acceso personal de Supabase viven fuera del repo y se revocan desde la web (Settings → Access tokens), nunca desde el código | .env solo con `SUPABASE_URL` / `SUPABASE_ANON_KEY` | .env, deploy.ps1 | 2026-10-17
- Issue: el bloqueador de secretos miraba solo el NOMBRE del archivo en `edit`/`write`, así que un PAT dentro de un `.md` pasaba libre (por ahí llegó a `docs/sessions/`) y nombres como `report_creds.env` ni siquiera coincidían (el patrón exigía empezar por `.env`) | mirar también el contenido y ampliar el patrón a `(^|/)(\.?env|[^/]*\.env)(\.[^/]+)?$`, dejando pasar solo los ejemplos | .opencode/plugins/hookify.js | 2026-10-17
- Issue: el `.gitignore` solo listaba `.env`, `.env.local` y `report_creds.env`, así que un `creds.env` o un `prod.env` habrían entrado al repositorio | añadir `*.env`, `*.env.local` y `creds*.env` (ningún archivo `*env` está rastreado: el cambio no destrackea nada) | .gitignore | 2026-10-17
- Issue: el bloqueador no inspeccionaba el contenido de los comandos de shell, así que un `echo <secreto> > archivo` pasaba | ahora usa los mismos patrones de forma, también en bash; probado en vivo con un `echo` que llevaba un `sbp_` falso | .opencode/plugins/hookify.js | 2026-10-17
- Issue: la raíz del repositorio llevaba desde septiembre una copia muerta del build web (`main.dart.js`, `flutter*.js`, `canvaskit/`, `index.html`, `favicon.png`, `icons/`, `manifest.json`, `version.json`) que no publicaba nada: Pages sale de `gh-pages` y `deploy.ps1` solo escribe en `_deploy` | destrackear con `git rm --cached` e ignorar; **`assets/` no se toca**, porque ahí vive `assets/fonts/` que declara `pubspec.yaml` | .gitignore | 2026-10-17
- Issue: el `DestructiveWarner` del pack no había escrito nunca su registro (`.opencode/logs/destructive.log` no existía). Dos causas: esperaba la herramienta `bash` —aquí el motor la llama `shell`, y lo confirma el propio registro— y resolvía la ruta del log desde `process.cwd()` | atar la regla a que la llamada traiga un comando, sacar la ruta de la ubicación del propio plugin (con respaldo en la carpeta temporal) y buscar el comando por nombre o, si no, por tamaño; verificado en vivo | .opencode/plugins/hookify.js | 2026-10-17
- Issue: `report_creds.env` parece una fuga y **no lo es**: lo leen `tool/generate_report_tool.dart` y `tool/verify_auth_write_tool.dart` (EMAIL y PASSWORD de un usuario de prueba). Está gitignored y nunca salió del equipo | dejarlo donde está; rotar esa contraseña solo si se reutiliza en otro sitio | .gitignore | 2026-10-17
- Pattern (plugin de `.opencode/`): **`process.cwd()` no es el proyecto**. Para una ruta propia, `import.meta.url` con `fileURLToPath` y `dirname`; y un fallo de escritura que se traga el `catch` es un rastro que desaparece en silencio | .opencode/plugins/hookify.js | 2026-10-17

## User Preferences
- Preference: cada bug se arregla con su test y **verificado fallando antes** (rojo real ejecutado, nunca razonado) | siempre | 2026-10-17
- Preference: el usuario analiza y decide junto. No aplicar cambios de UI, comportamiento o texto sin preguntar; decidir con la opción recomendada marcada | siempre | 2026-10-17
- Preference: stageo explícito, nunca `git add -A`; `docs/plans/` y `docs/` solo si lo pide. Única excepción: `git -C _deploy add .` | al commitear | 2026-10-17
- Preference: los tres pintadores (Reportes, PDF y Excel) deben decir lo mismo: mismo texto, mismo sitio, mismos ajustes | al tocar informes | 2026-10-17
- Preference: respuestas y mensajes de commit cortos, en español, sin adornos | siempre | 2026-10-17
