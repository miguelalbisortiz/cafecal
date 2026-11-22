# Auditoría visual del menú y la navegación — Mi Cafetal

**Fecha:** 2026-11-21
**Build auditada:** https://miguelalbisortiz.github.io/cafecal/ (producción)
**Cuenta:** `prueba@gmail.com` (datos de prueba, onboarding ya completado)
**Viewports:** 360×640 (compacto), 768×740 (medio), 912×670 (expandido)
**Capturas:** `docs/audits/2026-11-21-visual/`

---

## Veredicto

El menú **no está mal escrito, está mal repartido**. La app tiene 8 pantallas y un solo menú
de 7 ítems que mezcla cuatro cosas distintas: destinos de trabajo, datos maestros, ajustes y
sesión. En móvil, cinco de esas pantallas solo existen detrás del icono `⋮`.

Lo que sí está bien: la barra inferior tiene 3 destinos (el rango recomendado es 3–5), el
rail aparece en ancho, y los ítems del menú miden 48 px de alto (cumple el mínimo táctil).

---

## Cómo se midió (y qué no se puede medir)

No existe herramienta que emita un veredicto automático de "este menú está mal". Se combinaron
tres cosas:

| Nivel | Qué se hizo | Qué tan firme es |
|---|---|---|
| Medición | Capturas a 3 anchos, árbol de accesibilidad, alturas de ítem, truncado de texto | Hecho observable |
| Criterio | Contraste con Material 3 (navegación adaptativa) y heurísticas de Nielsen | Juicio razonado |
| Uso real | **No se hizo**: no hay analytics de qué pantallas se abren | Pendiente |

Sin el tercer nivel, cualquier propuesta de reparto es una hipótesis bien fundada, no un hecho.

---

## Hallazgos

| # | Hallazgo | Dónde | Severidad |
|---|---|---|---|
| 1 | **"Registrar" es una pestaña, no una acción.** `NavigationBar`/`NavigationRail` la marcan como sección seleccionada. Material 3 reserva la barra para destinos; crear va en un FAB o botón primario. | `home_screen.dart:319-338` | Alta |
| 2 | **Cinco pantallas solo viven en el menú `⋮`**: Reporte, Cultivos, Siembras, Trabajadores, Ajustes. En móvil son invisibles hasta abrir el menú. | `home_screen.dart:183-277` | Alta |
| 3 | **El menú mezcla 4 niveles** sin jerarquía: destino (Reporte) · datos maestros (Cultivos/Siembras/Trabajadores) · sistema (Ajustes/Ayuda) · sesión (Salir). | `home_screen.dart:194-276` | Alta |
| 4 | **Las tarjetas KPI se truncan a 360 px.** Tres columnas fijas: "Inco…", "Expe…", "unchang…", "went do…", "Improve…". | captura `01` | Alta |
| 5 | **El segmentado del Reporte rompe línea** a 360 px: "Year to date" ocupa dos líneas y desalinea el control. | captura `03` | Media |
| 6 | **El título del AppBar no sigue la pantalla.** En las pestañas dice siempre "Balance"; en Reporte dice "Reporte". Dos jerarquías distintas. | captura `03`, `04` | Media |
| 7 | **Las pantallas empujadas pierden la barra inferior.** Desde Reporte/Cultivos/etc. no se puede cambiar de pestaña sin volver atrás. | capturas `03`, `04` | Media |
| 8 | **Breakpoint en 900 px** en vez de 840 (estándar M3). Entre 840 y 899 se muestra barra inferior donde ya tocaba rail. | `home_screen.dart:148` | Media |
| 9 | **Etiqueta duplicada**: "Supplier / seller (optional)" aparece como label y otra vez como hint dentro del campo. | captura `04` | Baja |
| 10 | **Texto de ayuda largo dentro del formulario**: 3 líneas explicando "+ New crop…" en la pantalla de registro. | captura `04` | Baja |
| 11 | **La barra inferior no aparece en el árbol de accesibilidad web.** Solo se exponen "Sync" y "Show menu". Si se confirma en móvil, un lector de pantalla no puede navegar entre pestañas. | medición | Alta (por confirmar) |
| 12 | **Locale inconsistente**: la primera carga (navegador en `en-US`) mostró toda la app en inglés; una segunda carga mostró español. Para una app de caficultores colombianos el defecto debería ser español, no el idioma del teléfono. | observación | Media (por confirmar) |
| 13 | **"Cosechas" comentada** en el código, no eliminada. Deuda invisible. | `home_screen.dart:224-236` | Baja |

---

## Lo que está bien

- 3 destinos en la barra inferior: dentro del rango recomendado.
- `NavigationRail` en ancho con `labelType: all`: correcto.
- Ítems del menú a 48 px de alto: cumplen el mínimo táctil.
- Acciones secundarias fuera de la barra: el patrón es correcto, solo está sobrecargado.
- Iconos + texto en todos los ítems: no depende solo del color.

---

## Propuesta de reparto

```
ACTUAL                                PROPUESTO
──────────────────────────────        ─────────────────────────────────────
Barra:  Resumen · Registrar ·         Barra:  Resumen · Movimientos · Reportes
        Historial                     FAB:    (+) Registrar
Menú ⋮: Reporte · Cultivos ·          Menú ⋮: Finca ▸ (Cultivos, Siembras,
        Siembras · Trabajadores ·             Trabajadores)
        Ajustes · Ayuda · Salir               Ajustes · Ayuda
                                              ─────────────
                                              Salir
```

**Por qué**

1. **Registrar sale de la barra y pasa a FAB.** Es la acción central (el README promete ~10 s),
   debe estar siempre a un toque y no competir por un slot de navegación ni quedar "seleccionada".
2. **Reportes sube a la barra.** Es la pantalla que el productor consulta para decidir; hoy está
   enterrada en el menú.
3. **Cultivos, Siembras y Trabajadores se agrupan en "Finca".** Son datos maestros: se configuran
   una vez y se tocan poco. Un submenú (`MenuAnchor` + `SubmenuButton`) o una pantalla-hub con
   tarjetas. Dejan de competir con el uso diario sin desaparecer.
4. **El menú `⋮` queda para sistema y sesión.** Eso es exactamente lo que debe vivir ahí.
5. **En ≥840 px**, `NavigationRail` con 4 destinos (Resumen, Movimientos, Reportes, Finca) y
   Ajustes/Ayuda al pie del rail.

---

## Arreglos inmediatos (sin rediseñar)

1. Tarjetas KPI a 360 px: pasar a 1 columna o a `Wrap` con ancho mínimo, para que no haya `…`.
2. Segmentado del Reporte: `SingleChildScrollView` horizontal o etiqueta corta ("YTD").
3. Quitar la etiqueta duplicada del campo "Supplier / seller".
4. Breakpoint 900 → 840.
5. Borrar el bloque comentado de Cosechas (o restaurarlo).

---

## Anexo · comportamiento de retorno (verificado en vivo)

Se probó el "volver" en la build desplegada, no solo en el código.

| # | Hallazgo | Evidencia | Severidad |
|---|---|---|---|
| R1 | **El atrás del navegador no vuelve a la pantalla anterior.** Estando en Reporte, `browser.back()` dejó la URL en `/cafecal/` y la pantalla en Reporte. No hay router: el historial nunca cambia. En la PWA instalada eso saca al usuario de la app. | prueba en vivo + `home_screen.dart:186-192` (`MaterialPageRoute`) | Alta |
| R2 | **Cambiar de pestaña borra el formulario a medias.** Monto `12345` → Overview → Record: campo vacío. `_body()` reconstruye `RegisterScreen` en cada cambio. | prueba en vivo + `home_screen.dart:345-350` | Alta |
| R3 | **No hay confirmación de descarte.** Cero `PopScope`/`WillPopScope` en `lib/`. | `grep` en `lib/` | Alta |

Lo que sí funciona: la flecha `←` de las rutas empujadas, el atrás nativo de
Android y las confirmaciones de borrado.

---

## Límites de esta auditoría

- No se probó con lector de pantalla real (NVDA/VoiceOver) ni con teclado físico.
- No hay datos de uso: no se sabe qué pantallas abre de verdad el productor.
- El hallazgo 11 (barra fuera del árbol de accesibilidad) se midió en la build web; hay que
  confirmarlo en Android/iOS antes de tratarlo como bug.
- El estado de la cuenta de prueba (`qqq` como cultivo) no refleja datos reales.
