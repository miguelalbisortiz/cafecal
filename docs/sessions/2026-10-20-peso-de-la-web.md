# Sesión — martes 20 de octubre de 2026 (el peso de la web)

> Estado al cierre. Detalle completo en
> `docs/sessions/2026-10-20-peso-de-la-web.md`.
> La vuelta anterior (los kilos del jornal) quedó en
> `docs/sessions/2026-10-20-kilos-recolectados-en-el-jornal.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`060fbde`** (la tanda del peso, 16 archivos).
- `gh-pages` = **`2ae35e0`**; huella `6AE39C9095C37D64D36FB983C48364C27C47A16E451EF2847A2A27D69FD7740E`,
  `main.dart.js` **3.671.623 B** / 127.989 líneas. Pages sirvió el build nuevo
  **al primer intento**.
- Gate: `flutter analyze` limpio · **1049/1049** tests.
- Primer despliegue con el bloque de git arreglado de `deploy.ps1`: pasó entero.

## 2. Qué se hizo

Se bajó el peso del arranque **sin tocar el renderer, las fuentes ni `NOTICES`**:

- `ReportPeriod` se mudó de `pdf_export_service.dart` a
  `lib/models/report_period.dart` (el servicio lo reexporta).
- Las alertas y el Excel dejaron de pasar por el servicio de PDF.
- `ReportScreen` importa pdf y excel con `deferred as`, calienta los trozos al
  abrir Reportes y, sin red, avisa con **Reintentar** (nunca archivo vacío).
- Copy nueva ES/EN `exportNeedsNetworkOnce`.

**`main.dart.js`: 4.818.867 → 3.671.623 B (−23,81%)**; gzip 1.400.383 →
1.059.682. Tres trozos (911.664 + 31.269 + 217.985) que **no se piden al
arrancar**. A 200 KB/s el primer arranque pasó de **37,8 s a 28,9 s** (−23,5%).

## 3. Lo que se aprendió (y quedó escrito)

- **El enum solo ahorra 0 B**: mientras `pdf` entre por otro import normal
  (aquí `report_screen.dart`), diferir no descuenta nada. Primero se corta la
  cadena, después se difiere.
- **`--dump-info` no funciona en Flutter 3.24**: existe en `-h` y no produce
  ningún `.info.json` (probado dos veces, una con `-v`).
- **El build sin `--dart-define` es otro programa**: 4.718.092 B frente a
  4.818.867 B. La línea base se toma con el comando de `deploy.ps1`.
- **La medición honesta del primer frame**: no hay FCP (canvas), así que se mide
  el último recurso con un servidor Node a 200 KB/s, SW desregistrado y caches
  borrados; 3 corridas, mediana.
- **El service worker precachea los `.part.js`**: no frenan el primer frame
  (0 partes antes de pintar), pero el total de la primera visita no baja.

## 4. Pendientes (del lado del usuario)

1. PDF y Excel reales en el sitio publicado.
2. Reportes sin señal en un equipo que nunca los abrió: aviso + Reintentar.
3. Reportes con señal y después exportar sin señal.
4. Revocar el **PAT de Supabase** (`docs/audits/2026-10-17-secretos-y-bloqueador.md`,
   punto 1).
5. Opcional: `flutter build apk` para descartar Android (no se compiló).

## 5. Cómo continuar

- Medición base y después: `docs/reports/2026-10-20_peso-web-base.md` (§1–§9).
- Contrato: `docs/prds/2026-10-20_1016-peso-de-la-web.prd.md` (APPROVED).
- Tareas: `docs/plans/2026-10-20-peso-de-la-web.plan.md` (T1–T8 hechas; T9/T10
  son el deploy y la verificación manual, ya publicados).
- Guardas: `test/no_pdf_in_alert_chain_test.dart`,
  `test/deferred_exports_test.dart`, `test/export_parity_test.dart`.
- Gate obligatorio: `flutter analyze` (proyecto entero) + `flutter test`;
  publicar con `.\deploy.ps1 -Message "…"`.
- **Antes de commitear tras un build**: `lib/l10n/generated/*` puede quedar con
  otro fin de línea. Convertir a LF y confirmar con `git show --stat`.
