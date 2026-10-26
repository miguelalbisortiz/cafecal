# Prueba en producción — 2026-10-26

> Alcance: app desplegada en https://miguelalbisortiz.github.io/cafecal/
> (`gh-pages` `f8fc34a`) con la cuenta `prueba@gmail.com` y datos de una finca
> de 10 ha. Objetivo: validar la etapa B (kilos por lote) y los arreglos de la
> auditoría con datos que se parezcan a una finca real.
>
> Solo prueba: **no se tocó código** en esta sesión. Los datos de prueba quedan
> en la cuenta; se limpian con
> `C:\Users\MKY\AppData\Local\Temp\opencode\limpia_cuenta_prueba.sql`.

## 0. Método y límites

- Los datos base y los movimientos se cargaron por SQL con ids fijos; la
  **resiembra** y el **jornal sin señal** se registraron desde la app.
- La app es canvas: el agente no puede escribir en los campos. La prueba manual
  la hizo el usuario y el agente preparó los SQL y las comprobaciones.
- Verificación por pantalla (Reporte y tarjetas) y por `select` de control en
  Supabase después de cada carga.
- **No se probó**: multi-dispositivo (la cuenta se usa en un solo equipo),
  borrados que viajan al servidor, edición remota, respaldo/restauración, ni
  los archivos PDF/Excel abiertos fuera de la app.

## 1. Datos de prueba

| Cultivo | Área | Matas | Siembra | Cosecha | Venta |
|---|---|---|---|---|---|
| Café | 6 ha (5 + 1) | 30.000 | 26/10/2025 · 5 ha / 25.000<br>26/10/2026 · 1 ha / 5.000 (expansión) | 230 kg (180 + 50) | 230 kg × 2.500 = 575.000 |
| Plátano | 3 ha | 3.300 | 26/04/2026 | 240 kg | 240 kg × 1.500 = 360.000 |
| Maíz | 2 ha | 40.000 | 15/09/2026 | 3.000 kg | 3.000 kg × 1.300 = 3.900.000 |

- Terreno único **La Loma** (10 ha) para los tres cultivos.
- 4 trabajadores a **12.702,08 por día** (1.587,76/h × 8 h).
- **19 jornales**, 23 días: deshierbar, aplicar, regar, abonar, reparar
  (contra el terreno), cosechar café y maíz. Total **292.147,84**.
- Fijos: luz 85.000 y agua 40.000, contra el terreno. Se reparten 6 / 3 / 2
  de 11 ha junto con la reparación.
- Resiembra registrada desde la app: **200 nuevas y 200 bajas** en el lote del
  26/10/2025.

## 2. Resultados

### 2.1 Etapa B — kilos por lote

- La tarjeta del café muestra **«2 edades»** y, al desplegar, una línea por
  lote: **180 kg** en el del 26/10/2025 y **50 kg** en el de expansión.
- El jornal de «Cosechar» ofrece el **selector de lote** (con «Sin lote») solo
  cuando el cultivo tiene dos o más lotes vivos.
- La venta de 230 kg **no duplicó** los kilos: Reporte siguió en 230 kg
  cosechados y 230 vendidos.

### 2.2 Siembras y resiembra

- Control en Supabase tras la resiembra: **5 siembras · 1 resiembra ·
  200 plantas · 200 pérdidas**. El push funcionó, así que las columnas de
  cohorte (`replaces_plants`, `replaces_area_ha`, `cohort_sowing_id`) existen
  en la base.
- El total **no se infló**: el lote viejo siguió en 25.000 y el cultivo en
  30.000 (no 30.200). El reporte muestra 73.300 matas y **pérdidas 200**.

### 2.3 Sin señal

- Con la red apagada, el jornal se guardó, apareció en Historial y la app avisó
  con la ruta del problema y la opción de reintentar.
- Al reconectar y sincronizar a mano, el movimiento subió.

### 2.4 Reporte, PDF y Excel

| | |
|---|---|
| Movimientos | 24 |
| Ingresos | 4.835.000 |
| Gastos | 417.147,84 (mano de obra 292.147,84 · fijos 125.000) |
| **Balance** | **4.417.852,16** |
| Cosechado / vendido | 3.470 kg / 3.470 kg |
| Café | 6 ha · 30.000 matas · 38,3 kg/ha · «promedio de 2 edades» |
| Plátano | 3 ha · 80 kg/ha |
| Maíz | 2 ha · 1.500 kg/ha |

- Desglose por cultivo: café **278.344** (16 movimientos), plátano **88.363**
  (8), maíz **50.441** (6). Sin fila «sin repartir»: los tres tienen área.
- Nómina: 23 días (7 + 6 + 5 + 5) por 292.148.
- Los totales de Reporte y de las vistas de PDF/Excel coinciden, y el café no
  aparece con 460 kg.

## 3. Hallazgos

### F1 · «Por hectárea» no aplica el reparto del terreno — media

`lib/widgets/per_hectare_panel.dart:61-62` arma los movimientos del cultivo con
`t.cropId == c.id`; el desglose sí usa `repartoPorHectareas`
(`lib/services/crop_totals.dart`). Resultado: el mismo café vale **33.872/ha**
en «Por hectárea» (203.233,28 ÷ 6) y **278.344** en el desglose (46.391/ha).
La diferencia son los 75.110,23 que le tocan de luz, agua y reparación.

No es un error de suma: son dos criterios en la misma pantalla. Quien mire el
margen por hectárea va a decidir con una cifra que ignora el gasto del lote.

### F2 · «Costo de recogida por kg» no ve los jornales de Cosechar — baja

`lib/services/report_harvest_metrics.dart:69` suma solo gastos con
`harvestId != null`. Los jornales de «Cosechar» no llevan ese enlace, así que
el indicador da **COP 0** aunque la recolección costó 6 jornales. El número es
un cero calculado, no un dato faltante, y se lee como «cosechar fue gratis».

### F3 · Los kilos de un lote cerrado dejan de verse — baja

`lib/screens/crops_screen.dart:442` pasa `kg = null` cuando la cohorte no está
abierta. Al cerrar un lote (por ejemplo el maíz al terminar su ciclo), sus
kilos siguen en Reporte pero desaparecen de la tarjeta del cultivo.

### F4 · 11 ha de cultivos en un terreno de 10 — no es bug

La expansión de 1 ha del café dejó la suma de cultivos por encima del área del
terreno. El aviso de Cultivos → Terrenos aparece y es correcto. Decisión del
usuario: **dejarlo** como dato de prueba, porque prueba la guarda.

## 4. Notas operativas para la próxima prueba

- Para que se vaya el caché local hay que **cerrar sesión**: `signOut()` llama
  `clearAll()` y borra lápidas y marcas. Recargar la página no alcanza.
- El `select` de control **no ve lo pendiente de subir**: la app guarda local
  primero. Un 4 en el conteo puede ser «no se guardó» o «no subió»; se
  distingue mirando la fila en la app y el ícono de sincronización.
- Un gasto sin cultivo aparece como **«Costos comunes»** en el desglose. Es
  correcto, pero conviene elegir cultivo al registrar para que el costo no
  quede suelto.
- Las «cargas» del café salen del peso del saco de Ajustes (27,2 kg en esta
  prueba): 230 kg → 8,45 cargas.

## 5. Pendientes

- Decidir si F1 y F2 se arreglan (con test en rojo primero) o se declaran como
  criterio. F3 es presentación: decidir si el lote cerrado muestra sus kilos.
- No re-abrir la atribución por venta ni el reparto de una venta entre lotes.
