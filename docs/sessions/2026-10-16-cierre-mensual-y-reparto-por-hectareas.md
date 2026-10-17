# Sesión — jueves 16 de octubre de 2026

Estado al cierre de la sesión. Anterior: `2026-10-08_1800-ciclo-completo-optimizacion-reporte-financiero.md`.

---

## 1. ¿Dónde quedó el proyecto?

**Publicado.** `https://miguelalbisortiz.github.io/cafecal/`

| Rama | Commit | Estado |
|---|---|---|
| `main` | `1de7351` | sincronizada con `origin/main` |
| `gh-pages` | `41ef3b1` | sincronizada con `origin/gh-pages` |

`build/web/main.dart.js` y el archivo publicado en vivo **coinciden bit a bit**:
`d47411ce0b5b70bb620775c528b24fb629695d1947cb0912a37c2078b983784a` · 4.842.964 bytes.

Medido el 16/10 a partir de `https://miguelalbisortiz.github.io/cafecal/main.dart.js`.

---

## 2. Lo que ya está construido y publicado

El ciclo completo **cierre mensual → reparto por hectáreas** del 8 de octubre quedó
terminado y en producción. En orden de los commits:

| Commit | Qué aporta |
|---|---|
| `d7a3f6a` | caja mensual |
| `28bc224` | frontera de plantación |
| `05a08e0` | icono de Ayuda |
| `1ffdbb7` | GPS del Terreno (geolocator **^12**, no ^14: ^14 exige Flutter 3.27 y el proyecto está en 3.24.0) |
| `592a21b` | (c) costo/kg y (i) inventario |
| `93f37c4` | lote (b): **gasto compartido → reparto por hectáreas** |
| `45a045e` | alertas unificadas |
| `a20cb82` | l10n: desplegable «Cultivo o lote» + nota de costos asociados |
| `6f9979b` | Excel: sección «Qué hacer» |
| `692f058` | `deploy.ps1` paso 7: verificación de la huella publicada |
| `1de7351` | `deploy.ps1`: también verifica cuando no hay cambios que subir |

**La regla del reparto, ya en producción:** un gasto que sirve a varios cultivos del
mismo terreno va al **lote** y se reparte **por hectáreas**. Si a algún cultivo le
falta el área, esa parte no se reparte y sale como `Lote X · sin repartir`. Cultivo y
lote son mutuamente excluyentes —los dos a la vez sería contar el mismo peso dos veces—.
Orden del desglose: cultivos → lotes sin repartir → «Costos comunes».

**Modelo de negocio ya decidido:** APK + offline + gratis con corte + pago único
($4.99 USD / ~$20.000 COP). **Nunca se cobra por resumen ni por alertas.**

---

## 3. Tres fallos encontrados al revisar (16/10)

### A · Elegir un lote borraba el recordatorio — **arreglado**

`copyWith(lastCropId: _cropId)` con `_cropId` en `null` limpia el campo a propósito.
Al elegir un lote no había `lastTerrenoId`, así que el **siguiente** gasto compartido
arrancaba en «Costos comunes» y **dejaba de repartirse por hectáreas**, sin aviso.

Arreglado con `lastTerrenoId` en `FarmSettings` (campo, copyWith con centinela, JSON).
Se preselecciona **solo en gastos** —un ingreso no tiene lote— y el lote va antes que
el cultivo porque son excluyentes.

Cobertura en `test/recordatorio_lote_test.dart` (4 tests). **Verificado que el test
falla sin el arreglo**: no es decoración.

### B · Un ingreso podía acabar etiquetado «Costos comunes» — **arreglado**

El ítem nulo del desplegable se llamaba «Costos comunes» también en ingresos, y su
aviso hablaba de «cerca, camino, luz». Una venta podía quedar con ese texto.

Ahora usa `noCropLabel` («Sin cultivo» / «No crop») y `noCropHint`
(«No pertenece a ningún cultivo. Se queda en el resultado general de la finca.»).

### C · La cantidad heredada sumaba kilos fantasma — **arreglado**

`quantity` se guardaba sin comprobar que fuera venta, mientras `unit` sí lo comprobaba.
El campo de cantidad se oculta al cambiar de categoría **pero el texto se queda en el
controlador**. Una subvención heredaba la cantidad de una venta anterior con `unit = null`,
y `report_harvest_metrics` suma `quantity * unitToKg(unit)` a «kg vendidos» sin filtrar
por categoría. `unitToKg(null)` es 1.

Ahora `quantity` y `unit` se guardan con la misma condición: **o es venta, o no hay
kilos**.

---

## 4. Deudas y avisos — **ninguna resuelta todavía**

🔴 **La más urgente: revocar el PAT de Supabase.**
`sbp_fcc730…` — el valor completo se quitó de este archivo a propósito: un secreto no
se guarda en el repo. Estaba a texto plano en `.env`, que está en `.gitignore`.
**Solo tú puedes hacerlo**: supabase.com → Settings → Access tokens.
No usar ese PAT para nada; si algún día se quiere el MCP de Supabase, exportar uno nuevo
como variable de entorno.

🔴 **MCP de Supabase roto.** `opencode.json` lo sigue declarando y falla en cada turno:
`ENOENT: ...opencode\bin\mcp.exe`. El de Context7 sí funciona.

🟡 **`docs/plans/` sin commitear** — 2 M + 5 ??. Son trabajo propio del usuario; no se
tocan sin verbo explícito.

🟡 **`deploy.ps1` no lo cubre ningún test.** El gate de Flutter no lee PowerShell.
Verificado a mano (parseo + simulación de ramas), no automatizado. Punto ciego declarado.

🟡 **«Opción C» sin definir.** No aparece en ningún sitio del repositorio.

---

## 5. Cómo continuar

**Arranque de una sesión nueva** — en orden:

1. **Revocar el PAT.** Es lo único que tú puedes hacer y lo único que no puede esperar.
2. Revisar `docs/plans/` — hay 7 archivos sin commitear; decidir cuáles viven.
3. Si algo del Bug A, B o C se ve raro en producción, empezar por ahí.
4. **No arrancar nada nuevo sin antes cerrar las deudas de arriba.**

**Para publicar cualquier cosa:**

```
flutter analyze; if ($LASTEXITCODE -eq 0) { flutter test }
.\deploy.ps1
```

El paso 7 de `deploy.ps1` descarga `main.dart.js` desde el sitio, calcula su SHA256 y
**falla en rojo** si no coincide con el build local. Ese paso no se toca: es lo único
que separa «compiló» de «llegó».

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Los tres pintadores (Reportes, PDF, Excel) dicen lo mismo, en el mismo sitio.
- Una sola función para una sola regla.
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 16 de octubre de 2026.*
