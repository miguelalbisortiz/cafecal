# Sesión — lunes 26 de octubre de 2026 (prueba en producción)

> Estado al cierre: **prueba manual en producción terminada y aprobada** con
> datos de una finca de 10 ha. Etapa B (kilos por lote), siembras/resiembra,
> modo sin señal y Reporte/PDF/Excel funcionaron. **No se tocó código**: solo
> se cargaron datos de prueba y se verificó.
> Informe: `docs/reports/2026-10-26_prueba-produccion.md`.
> PRD de referencia: `docs/prds/2026-10-22_1813-cohortes-atribucion.prd.md`.

## 1. Dónde quedó el proyecto

- `main` = `origin/main` = **`7a44157`** («Auditoría §1–§7»). Sin cambios en
  esta sesión: el árbol solo tiene el informe nuevo y este snapshot.
- `gh-pages` = **`f8fc34a`** sirviendo el bundle nuevo. Deploy verificado:
  sha256 `8140E7383EA078181545B3C6B46DFFD96EE257B43492E81A94F9BB281F672BEE`.
- Gate de la última entrega: `flutter analyze` limpio · **1306/1306**.
- Migraciones **aplicadas por el usuario**: `202610250001_allow_zero_plants.sql`
  y `202610260001_indexes_and_crop_terreno_check.sql`. La `202610220001`
  (cohortes) quedó confirmada en la práctica: la resiembra subió a la nube
  con sus columnas nuevas.
- App: https://miguelalbisortiz.github.io/cafecal/ · Supabase
  `ioyqlzhzlvkkebvenqnz` · cuenta `prueba@gmail.com`.

## 2. Qué se hizo

**Datos de prueba** (por SQL, ids fijos; scripts en
`C:\Users\MKY\AppData\Local\Temp\opencode\`):

- Terreno **La Loma** 10 ha. Café 5 ha / 25.000 matas (26/10/2025) +
  expansión 1 ha / 5.000 (26/10/2026, `replaces_plants = 0`); plátano 3 ha /
  3.300 (26/04/2026); maíz 2 ha / 40.000 (15/09/2026).
- 4 trabajadores a **12.702,08/día** (1.587,76 × 8 h).
- **19 jornales** (23 días) por **292.147,84**; reparación contra el terreno.
- Fijos: luz 85.000 + agua 40.000 contra el terreno; se reparten 6 / 3 / 2
  de 11 ha junto con la reparación.
- Ventas: café 230 kg × 2.500 = 575.000 · plátano 240 × 1.500 = 360.000 ·
  maíz 3.000 × 1.300 = 3.900.000.

**Pruebas hechas desde la app** (las hizo el usuario; el agente no puede
escribir en el canvas de Flutter):

1. **Etapa B**: la tarjeta del café muestra «2 edades»; kilos por lote
   **180 / 50**; el jornal de «Cosechar» ofrece el selector de lote; la venta
   de 230 kg **no duplica** la cosecha (230 / 230).
2. **Resiembra**: 200 nuevas y 200 bajas en el lote del 26/10/2025. Control en
   Supabase **5 · 1 · 200 · 200**. El lote sigue en 25.000 y el café en 30.000
   (no 30.200). Reporte: 73.300 matas y pérdidas 200.
3. **Sin señal**: guardó, apareció en Historial, avisó con la ruta del problema
   y la opción de reintentar; al reconectar subió.
4. **Reporte, PDF y Excel**: ingresos **4.835.000**, gastos **417.147,84**
   (mano de obra 292.147,84 · fijos 125.000), balance **4.417.852,16**,
   cosechado = vendido **3.470 kg** (230 / 240 / 3.000), café sin 460 kg.
5. **Corrección de un dato**: el jornal de la prueba sin señal quedó sin
   cultivo («Costos comunes» 12.702,08); se editó en Historial y se asignó a
   Café. Café pasa a **278.344 / 16 movimientos** y «Costos comunes»
   desaparece. Totales sin cambios.

Números finales: **24 movimientos** · mano de obra 292.147,84 · fijos 125.000 ·
gastos 417.147,84 · ingresos 4.835.000 · balance 4.417.852,16. Desglose: café
278.344 (16), plátano 88.363 (8), maíz 50.441 (6); La Loma 417.148; sin «sin
repartir». Por hectárea: café 38,3 kg/ha · 33.872 gastos/ha · margen 61.961;
plátano 80 · 16.936 · 103.064; maíz 1.500 · 12.702 · 1.937.298. Nómina: T1 7 d
88.915 · T2 6 d 76.212 · T3 5 d 63.510 · T4 5 d 63.510.

## 3. Decisiones

- **Datos de prueba con una finca real de 10 ha**, no un caso mínimo: es la
  única forma de que salgan los descuadres de reparto y de áreas.
- El **descuadre de 11 ha de cultivos en un terreno de 10** se deja a
  propósito: prueba que la guarda de áreas avisa sin bloquear (F4).
- Los datos de prueba **se quedan** en la cuenta; se limpian con
  `limpia_cuenta_prueba.sql`.
- El reset de datos exige **cerrar sesión y volver a entrar**: `signOut()`
  llama `_store.clearAll()`.
- **No se arregla nada en caliente**: F1–F3 quedan como hallazgos del informe
  para decidir después, con test en rojo primero.

## 4. Hallazgos

- **F1 (media)** — «Por hectárea» no aplica el reparto del terreno:
  `lib/widgets/per_hectare_panel.dart:61-62` filtra `t.cropId == c.id`, mientras
  el desglose usa `repartoPorHectareas`. Café: **33.872/ha** en el panel frente
  a **278.344** (46.391/ha) en el desglose. Dos criterios en la misma pantalla.
- **F2 (baja)** — «Costo de recogida por kg» da **0** aunque hay 6 jornales de
  Cosechar: `lib/services/report_harvest_metrics.dart:69` solo suma gastos con
  `harvestId != null`, y los jornales no llevan ese enlace.
- **F3 (baja)** — Los kilos de un lote cerrado dejan de verse en la tarjeta del
  cultivo: `lib/screens/crops_screen.dart:442` pasa `kg = null` si la cohorte
  no está abierta. Siguen en Reporte.
- **F4 (no es bug)** — 11 ha de cultivos en un terreno de 10: el aviso sale y
  es correcto.

## 5. Pendientes

- Decidir **F1** y **F2**: arreglar (con test en rojo) o declararlos como
  criterio documentado.
- Decidir **F3**: si el lote cerrado muestra sus kilos en la tarjeta.
- No re-abrir la atribución por venta ni el reparto de una venta entre lotes.
- Limpiar los datos de prueba cuando ya no sirvan (`limpia_cuenta_prueba.sql`).

## 6. Cómo continuar

- Leer el informe `docs/reports/2026-10-26_prueba-produccion.md` para el detalle
  por sección (método, datos, resultados, notas operativas).
- Si se arregla F1 o F2: PRD corto → test en rojo → cambio → `flutter analyze` +
  `flutter test` → commit explícito. F1 toca la definición de «gasto del
  cultivo», así que la decisión es del usuario, no del agente.
- Para repetir la prueba desde cero: cerrar sesión, correr
  `limpia_cuenta_prueba.sql` y volver a cargar `datos_base_prueba.sql` +
  `jornales_prueba.sql` + `segundo_lote_cafe.sql` + `venta_prueba.sql` +
  `ventas_gastos_prueba.sql`.
