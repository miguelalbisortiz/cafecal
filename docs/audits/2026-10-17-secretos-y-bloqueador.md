# Auditoría: secretos y bloqueador de secretos

Fecha: 2026-10-17
Ámbito: secretos en el árbol, rutas de fuga hacia el repo o el bundle publicado, `.opencode/plugins/hookify.js`, `opencode.json` y `deploy.ps1`.
Método: barrido con el agente `security-reviewer` (solo lectura) y **comprobación propia** de cada hallazgo (`git ls-files`, `git check-ignore`, lectura del plugin). Sin cambios de código. Ningún valor de secreto aparece en este informe.

## Origen
Hoy un push fue rechazado por la protección de secretos de GitHub: `docs/sessions/2026-10-16-cierre-mensual-y-reparto-por-hectareas.md:92` tenía un PAT de Supabase a texto plano. Ya se sustituyó por `sbp_fcc730…`, el commit se reescribió y el push pasó. El PAT sigue **sin revocar** en la web de Supabase (acción del usuario).

## 1. Secretos en el árbol — PASS con reservas
- Ningún JWT, `service_role`, PAT ni clave privada en `lib/`, `test/`, `supabase/`, `tool/`, `docs/`, `opencode.json` ni en los `.ps1`.
- `git log --all -S 'sbp_'` solo devuelve el commit ya enmascarado: el valor completo **no está en la historia alcanzable**.
- **MEDIA — `report_creds.env`**: 2 líneas (correo y contraseña a texto plano). Comprobado: `git ls-files` → 0 (no rastreado), `git check-ignore` → `.gitignore:51` (ignorado), 0 commits lo tocan, no está en el índice. **No sale del equipo**, pero es una credencial real en disco. → Borrarlo o rotar esa contraseña si es real.
- BAJA — `docs/sessions/*.md` conservan el PAT enmascarado (`sbp_fcc730…`), que sirve para identificar cuál revocar; no es reconstruible.

## 2. Rutas de fuga al repo o al bundle — FAIL (medio)
- PASS: ignorados `.env` (`.gitignore:49`), `.env.*` (`:64`), `report_creds.env` (`:51`), `build/` (`:41`) y `_deploy/` (`:55`). **Cero archivos `*env` rastreados.**
- FAIL (verificado): los nombres genéricos no están cubiertos — `git check-ignore creds.env prod.env supabase.env config.env` sale con código 1, ninguno coincide. Falta `*.env` en `.gitignore`.
- MEDIA (verificado): hay artefactos de build **rastreados en la raíz**: `main.dart.js`, `flutter.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `manifest.json`, `version.json`, más `canvaskit/` y `assets/` (22 entradas). Van al repo público, pero solo llevan la clave publishable, nunca `service_role`: es higiene y riesgo de quedar viejos, no filtración. **Antes de destrackear hay que confirmar de dónde publica GitHub Pages**: si sirviera de `main`, quitarlos rompería la web.
- BAJA — `deploy.ps1:116-117` pasa la clave por `--dart-define` en `argv` (visible en la lista de procesos).

## 3. Bloqueador de secretos (`hookify.js`) — FAIL (alto)
- PASS: cubre `.env`/`.env.*`, `*.pem|key|pfx|p12`, `id_*`, `.npmrc/.netrc`, `credentials`, `.ssh/config`, `secrets/` y `.kube/config`; normaliza `\` → `/` (`:65-67`).
- ALTA (verificado, `:84`): solo actúa en `edit`/`write` y **solo por nombre de archivo**, nunca por contenido → un PAT escrito dentro de un `.md` no se habría bloqueado. Aunque el plugin ya carga bien desde hoy, sigue sin ser la red que debería ser.
- MEDIA (verificado, `:33`): el patrón exige que el nombre empiece por `.env` → `report_creds.env`, `creds.env` o `prod.env` **se cuelan**.
- MEDIA: el bloqueo no cubre la shell; un `echo … >` escribiría el secreto sin freno (el `DestructiveWarner` sí engancha bash, pero es otra comprobación).

## 4. `deploy.ps1` — PASS
- No imprime ni registra claves: solo `--dart-define`, `sha256` y bytes.

## Arreglos, por prioridad
1. ALTA (usuario) — Revocar el PAT en supabase.com → Settings → Access tokens.
2. ALTA — `report_creds.env`: borrarlo del disco o rotar esa contraseña.
3. ALTA — `hookify.js`: detectar por **contenido** (`eyJ`, `sbp_`, `service_role`, `ghp_`, `AKIA…`, `sk_live…`, `PRIVATE KEY`) y ampliar el patrón a `(^|/)[^/]*\.?env(\.[^/]+)?$`.
4. MEDIA — `.gitignore`: añadir `*.env`, `*.env.local`, `creds*.env`.
5. MEDIA — Confirmar el origen de Pages y, si no cuelga de `main`, `git rm --cached` de los artefactos de build de la raíz.
6. BAJA — Sacar la clave de `argv` en `deploy.ps1`.

## Estado (cerrado el 2026-10-17)
- PAT enmascarado en los dos snapshots, commit reescrito y push aceptado por GitHub; objeto suelto `451020a` purgado (`git reflog expire` + `git gc --prune=now`), verificado como inexistente.
- **Punto 3 aplicado** (`.opencode/plugins/hookify.js`, que está gitignorado): el bloqueador mira ahora también el **contenido** de `edit`/`write` (JWT, `sbp_`, tokens de GitHub, AWS, Stripe, Google y Slack, y bloques de clave privada) y el patrón de nombre cubre `.env`, `env` y `*.env` —o sea `report_creds.env`, `creds.env` y `prod.env`—, dejando pasar los ejemplos (`*.env.example`). Verificado en dos pasos: 8 casos con Node **en rojo antes** del arreglo (fallaban 4) y en verde después, y **dos sondas en vivo** bloqueadas por el plugin que corre en la app, una por nombre y otra por contenido, sin crear ningún archivo.
- **Punto 4 aplicado** (`.gitignore`): `*.env`, `*.env.local` y `creds*.env`. `git check-ignore` confirma que ahora se ignoran `creds.env`, `prod.env`, `supabase.env`, `config.env` y `docs/x.env.local`. No hay ningún archivo `*env` rastreado, así que el cambio no destrackea nada.
- **Punto 5 resuelto**: la API de GitHub confirma que Pages publica desde la rama `gh-pages` (`build_type: legacy`) y `deploy.ps1` lo dice él mismo ("main queda intacto"). Los artefactos de la raíz llevaban sin tocarse desde septiembre y no publican nada: se destrackearon y se añadieron al `.gitignore`. **`assets/` no se tocó**, porque ahí vive `assets/fonts/` que declara `pubspec.yaml`.
- **Hueco de la shell, cerrado**: el bloqueador mira también el contenido de los comandos de bash, con los mismos patrones de forma. Probado en vivo con un `echo` que llevaba un `sbp_` falso: bloqueado, sin ejecutarse.
- **Punto 2 revisado a la baja**: `report_creds.env` **no se borra**. Lo leen `tool/generate_report_tool.dart` y `tool/verify_auth_write_tool.dart`; está gitignored, nunca salió del equipo y ahora lo cubre el bloqueador. Decisión: dejarlo tal cual (rotar esa contraseña solo si se reutiliza en otro sitio).
- **Pendiente**: punto 1 (revocar el PAT — usuario) y punto 6 (sacar la clave de `argv` en `deploy.ps1`).
