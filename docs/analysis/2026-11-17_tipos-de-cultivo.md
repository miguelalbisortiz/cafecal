# Tipos de cultivo: registro, gastos, kilos y métricas

> Análisis de solo lectura. Sin cambios de código. Evidencia `archivo:línea`.
> Fuentes priorizadas: modelos, provider, pantallas/widgets, servicios, `app_es.arb`, DR/PRD de cohortes.

## 1 · ¿Catálogo o texto libre?

**Texto libre.** `Crop.name` es `String` obligatorio (`lib/models/crop.dart:10-11,67-70`). No hay tabla de especies ni variedades.

- Único listado en código: `defaultCrops = Café, Plátano, Otro` (`lib/models/crop.dart:357-361`), **ya no se siembra**; solo adopta ids viejos (`lib/models/crop.dart:363-370`, `lib/providers/transaction_provider.dart:1376-1388`).
- En la práctica documentada se mencionan café, plátano, palta, maíz (`docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md:49-60`), pero no son entidades: son ejemplos de copy/análisis.
- Nombres repetidos permitidos en altas cortas (`lib/widgets/new_crop_dialog.dart:65-80`); el editor completo sí bloquea duplicados (`lib/widgets/crop_editor_dialog.dart:252-259`). La identidad es el id, no el nombre (`lib/screens/crops_screen.dart:497-509`).

Campos que sí existen por cultivo:

| Dato | Dónde | Alcance |
|---|---|---|
| `phase`: `establecimiento / produccion / renovacion` | `lib/models/crop.dart:3,15`; rótulos `Sin dar / Dando / Para renovar` en `lib/l10n/app_es.arb:163-166` | Fase gruesa, no fenología fina. La promueve la primera cosecha real (`lib/providers/transaction_provider.dart:581-613`). |
| `cycle`: `perenne / anual` | `lib/models/crop.dart:5,16`; `lib/l10n/app_es.arb:161-162` | Solo perenne/anual. |
| `defaultUnit` | `lib/models/crop.dart:17`; opciones `kg, lb, arroba, saco, carga, racimo, cajon` (`lib/widgets/crop_editor_dialog.dart:103,475-497`) | Preferencia de registro; fallback `kg` (`lib/screens/register_screen.dart:879-889`). |
| `areaHa`, `livePlants` | `lib/models/crop.dart:18-19` | Área que ocupa y matas vivas; no hay campo `densidad`. |
| `plantedAt`, `primerCosechaEsperada` | `lib/models/crop.dart:37-55` | Fecha de arranque y estimación de primera cosecha; ambas opcionales y borrables. |
| `expectedYieldPerHa` | `lib/models/crop.dart:22-31` | Meta del productor, no tabla de referencia. |
| `terrenoId`, `currency` | `lib/models/crop.dart:33-35,57-65` | Tierra y moneda declarada del cultivo. |

**No existe**: entidad «variedad», sombra/sol, densidad explícita, fase fenológica fina (floración, grano, maduración). La edad sale de la cohorte viva, de `plantedAt`, o es `null` con 2+ lotes (`lib/models/crop.dart:229-261`). Una resiembra no reinicia edad (`lib/models/crop.dart:241-244`).

El rótulo engaña: «+ Nueva variedad…» (`lib/l10n/app_es.arb:508-509`) y «Nueva variedad» (`:617`) abren un campo que dice «Nombre del cultivo» (`:620`).

## 2 · Alta, edición y vínculos

**Alta completa (Cultivos).** Editor con nombre obligatorio, icono/color, fase, ciclo, unidad, terreno, área, plantas, inversión inicial, meta y fechas (`lib/widgets/crop_editor_dialog.dart:245-288,465-525`; `lib/screens/crops_screen.dart:271-302`). El terreno solo se ofrece si ya existe (`lib/widgets/crop_editor_dialog.dart:498-525`). `addCrop` acepta `terrenoId` (`lib/providers/transaction_provider.dart:409-440`).

**Altas cortas (Registro / Siembras).** `NewCropDialog` devuelve solo nombre (`lib/widgets/new_crop_dialog.dart:59-80`); se crea con `addCrop(res.name, currency: ...)` (`lib/screens/register_screen.dart:401-433`, `lib/screens/sowing_screen.dart:325-359`). Después se ofrece completar datos con banner; «Ahora no» guarda `crop_setup_prompt_dismissed_v1` y **nunca vuelve a preguntar** (`lib/widgets/crop_setup_prompt.dart:22-33,38-68`). Ese editor no recibe terrenos, así que no puede asignar lote (`lib/widgets/crop_setup_prompt.dart:78-87`, `lib/widgets/crop_editor_dialog.dart:64-66,498-501`).

**Hallazgo concreto:** al crear desde Cultivos, el editor entrega `form.terrenoId` (`lib/widgets/crop_editor_dialog.dart:287`) pero `crops_screen` no lo pasa a `addCrop` (`lib/screens/crops_screen.dart:287-302`). Sí lo pasa la edición (`lib/screens/crops_screen.dart:340-363`). Resultado: el cultivo nace sin terreno aunque se eligió uno.

**Vínculos.** `Crop.terrenoId` es opcional (`lib/models/crop.dart:57-65`). `Transaction.cropId` y `Transaction.terrenoId` son mutuamente excluyentes por modelo y UI (`lib/models/transaction.dart:16-32`, `lib/screens/register_screen.dart:1019-1027,1086-1097`). `Sowing` pertenece a un cultivo y abre cohorte (`lib/models/sowing.dart:242-268`). Los kilos por lote se enlazan con `Transaction.cohortSowingId`, **solo en jornal de cosecha con kilos** (`lib/models/transaction.dart:103-109`, `lib/screens/register_screen.dart:644-653`). Las transacciones no tienen `harvests.sowing_id`; la venta sigue siendo del cultivo (`docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md:408-428`).

Tras crear/editar siembras se recalculan `livePlants` y `areaHa` desde cohortes (`lib/providers/transaction_provider.dart:847-874`); datos viejos se normalizan una vez (`lib/models/sowing.dart:376-399`, `lib/providers/transaction_provider.dart:876-889`).

## 3 · Gastos compartidos y sueltos

Tres caminos, sin doble conteo:

1. **Gasto con cultivo**: va íntegro a ese cultivo, aunque traiga lote (`lib/services/crop_totals.dart:183-185,242-245`).
2. **Gasto de lote sin cultivo**: se reparte por `areaHa` solo si **todos** los cultivos del terreno tienen área > 0 (`lib/services/crop_totals.dart:104-113,131-178`). Si falta un área, no se reparte y sale `Lote X · sin repartir` (`lib/services/crop_totals.dart:314-328`; `lib/l10n/app_es.arb:541`). Nunca se pone 0 ha inventado (`:93-97`).
3. **Sin cultivo ni lote**: `Costos comunes`, fila final (`lib/services/crop_totals.dart:86-88,272-274,339-344`; `lib/l10n/app_es.arb:510-511`). Afecta al total de la finca, no al costo/kg de ningún cultivo (`lib/l10n/app_es.arb:511`).

Reparto manual T15: N gastos independientes, no padre/hijos; cada parte entra al costo/kg de su cultivo y la suma cuadra hasta centavos (`lib/widgets/expense_split_dialog.dart:8-13`; `lib/services/expense_split.dart:6-26`; `lib/screens/register_screen.dart:749-773`). Se ofrece solo en gastos normales, no en jornal, venta ni edición (`lib/screens/register_screen.dart:1123-1131`). Atajo «Usar áreas» exige dos cultivos medidos (`lib/services/expense_split.dart:29-52`, `lib/widgets/expense_split_dialog.dart:51-59,116-125`).

Sin doble conteo en el reparto automático: se guardan copias con monto prorrateado (`lib/services/crop_totals.dart:169-173`) y `cropExpenseShares` excluye comunes (`lib/services/crop_totals.dart:204-229`). Los ingresos nunca se reparten por hectáreas (`lib/services/crop_totals.dart:254-257`).

**Copy mal alineado:** `contributionSubtitle` dice que lo del lote va «aparte, sin repartirlo» (`lib/l10n/app_es.arb:1606`), pero el código sí lo reparte cuando hay áreas (`lib/services/crop_totals.dart:104-113,246-252`). El hint del desplegable sí dice que se reparte (`lib/l10n/app_es.arb:1600`).

## 4 · Unidades, pesos y métricas

- Factores: `lb 0,453592`, `arroba 12,5`, `saco` configurable (default 70), `carga 27,2155`, resto 1 (`lib/models/units.dart:1-20`).
- `racimo` y `cajon` exigen `equivalentKg` escrito; sin peso devuelven `null`, nunca 1 kg (`lib/models/units.dart:22-55`). El llamador los cuenta como «sin peso» (`:43-44`) y el reporte usa `kgFromUnit` (`lib/services/report_harvest_metrics.dart:98-103`).
- La venta guarda `equivalentKg` (`lib/models/transaction.dart:94-101`) y la cosecha derivada lo hereda (`lib/services/derived_harvests.dart:197-199`).
- Unidad por cultivo: `defaultUnit` (`lib/widgets/crop_editor_dialog.dart:475-497`) con fallback `kg` (`lib/screens/register_screen.dart:879-889`).

Métricas, todas con guardas `null` (oculto, nunca 0):

| Métrica | Fórmula | Evidencia |
|---|---|---|
| kg/ha | kg cosechados ÷ `crop.areaHa` | `lib/services/report_harvest_metrics.dart:345-352` |
| kg/planta | kg ÷ `crop.livePlants` | `lib/services/report_harvest_metrics.dart:354-361` |
| costo/kg | gastos de operación del cultivo ÷ kg; `null` si fase no producción, kg 0 o monedas mezcladas | `lib/services/report_harvest_metrics.dart:209-236` |
| costo/ha, ingreso/ha | monto ÷ área; `null` si área 0 o monedas mezcladas | `lib/services/report_harvest_metrics.dart:417-450` |
| panel por hectárea | usa las mismas reglas + reparto de lote + aviso de moneda mixta | `lib/widgets/per_hectare_panel.dart:60-119,243-247,301` |
| kg por lote | suma de jornales **medidos**, nunca de la venta | `lib/models/cohort_kilos.dart:6-28,29-55` |

Con 2+ cohortes vivas, `kg/planta` del cultivo sigue siendo el promedio de todas las matas y el panel añade «promedio de N edades» (`docs/prds/2026-10-21_1818-cohortes-estructura.prd.md:470-473`; `lib/widgets/per_hectare_panel.dart:243-247`). El kg/planta por lote solo aparece si se pesó en jornal (`lib/models/cohort_kilos.dart:57-65`; `lib/screens/crops_screen.dart:431-461`).

## 5 · Comportamiento fuerte y acorde a la finca

- **Cosecha derivada**:Prioridad manual > jornal medido > venta (`lib/services/derived_harvests.dart:55-57,113-207`). Si hay jornal medido, la venta no deriva: evita contar dos veces (`:64-68,129-135,171-172`). Manual bloquea derivar (`:117-123,139-145`).
- **Jornal como medida**: gasto no borrado, `mano_obra`, tarea «Cosechar» del catálogo, con cultivo y kg > 0 (`lib/services/derived_harvests.dart:231-245`). El jornal se paga por días; los kilos solo alimentan cosecha (`lib/models/transaction.dart:86-92`).
- **Venta mezclada**: se queda en el cultivo; no se reparte entre lotes (`docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md:410-428`). Deriva kg brutos, no netos tras descuento (`lib/services/derived_harvests.dart:191-199`).
- **Lotes de distinta edad**: siembra = cohorte; resiembra ajusta `vivas − muertas + nuevas` y no revive cerradas (`lib/models/sowing.dart:242-268,514-534`).

- Renovación parcial: `replaces_plants / replaces_area_ha / cohort_sowing_id` restan del lote viejo sin inflar totales (`lib/models/sowing.dart:495-512`; `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md:451-459`). Con 2+ vivas, edad única = `null` → chip «N edades» (`lib/models/crop.dart:247-261`; `lib/screens/crops_screen.dart:571-587`).
- **Null → oculto**: metas, fechas, área, plantas, kilos por lote y ratios sin base se callan (`lib/models/crop.dart:30,54,63-64`; `lib/models/cohort_kilos.dart:59-64`; `lib/services/report_harvest_metrics.dart:345-361`).
- **Monedas**:mezcla oculta ratios; la cifra válida se muestra con su moneda (`lib/services/report_harvest_metrics.dart:212-233,420-450`; `lib/widgets/per_hectare_panel.dart:74-110`).
- **Sync/respaldo coherente**: las tres claves de cohorte se envían siempre, incluso `null` (`lib/providers/sync_provider.dart:518-520`; PRD SC-11 `docs/prds/2026-10-21_1818-cohortes-estructura.prd.md:88-91`), y se leen en JSON (`lib/providers/sync_provider.dart:789-791`).
- **Reparto honesto**: sin área no se inventa proporción; comunes no torcen costo/kg; T15 cuadra céntimos (`lib/services/crop_totals.dart:93-113`; `lib/services/expense_split.dart:6-26`).

## 6 · Mejoras priorizadas (6-10)

Regla aplicada: no crear entidades nuevas sin validar contra la práctica. Las propuestas reutilizan `Crop`, `Sowing`, `Transaction` y copy.

| # | Prioridad | Qué hoy | Qué propones | Evidencia | Riesgo / migración | Tipo |
|---|---|---|---|---|---|---|
| 1 | P0 | Alta desde Cultivos ofrece terreno, pero `addCrop` descarta `form.terrenoId`. | Pasar `terrenoId` en esa única llamada. | `lib/widgets/crop_editor_dialog.dart:287`; `lib/screens/crops_screen.dart:287-302`; `lib/providers/transaction_provider.dart:423-440` | Bajo. Sin esquema. Cultivos ya creados se corrigen editando; no backfill automático sin consentimiento. | Modelo/UI (1 línea) |
| 2 | P0 | «Variedad» nombra un campo que es solo nombre de cultivo; ayuda dice «transitorio» donde la app dice «Anual». | Cambiar copy a «cultivo» y «Anual» en ES/EN; conservar nombres libres. | `lib/l10n/app_es.arb:508-509,617,620,70`; `:161-162` | Nulo. No toca datos. | Solo copy |
| 3 | P1 | Altas cortas crean solo nombre + moneda; banner para completar se descarta para siempre. | En alta corta ofrecer al menos terreno, área y unidad; «Ahora no» posponer, no bloquear futuros cultivos. | `lib/screens/register_screen.dart:401-433`; `lib/screens/sowing_screen.dart:325-359`; `lib/widgets/crop_setup_prompt.dart:22-33,43,65` | Bajo-medio: más fricción en registro rápido. Sin esquema; `addCrop` ya acepta los campos. | UI + provider |
| 4 | P1 | `contributionSubtitle` afirma que lo del lote no se reparte; el código sí lo reparte por área. | Reescribir el subtítulo: «lo del lote se reparte por área cuando todas están medidas; si falta una, va aparte». | `lib/l10n/app_es.arb:1606`; `lib/services/crop_totals.dart:104-113,246-252` | Nulo. Afecta pantalla, PDF y Excel. | Solo copy |
| 5 | P1 | No se avisa si las áreas de cultivos de un terreno se traslapan o superan el terreno. | Aviso no bloqueante cuando ambas áreas existen; texto «revisa si es asocio o el área está repetida». No crear entidad de asocio aún. | `lib/models/terreno.dart:26-28`; `lib/models/crop.dart:18`; `lib/services/crop_totals.dart:104-112`; `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md:78-80,98-99` | Medio: en asocio la suma puede superar legítimamente; por eso aviso, nunca bloqueo ni corrección automática. | UI/copy |
| 6 | P1 | «Crear otro igual» permite dos cultivos con el mismo nombre, pero no ayuda a decir «es otra parte del mismo lote». | En el diálogo de duplicado, al crear otro, ofrecer copiar terreno y mostrar «otra parte del mismo lote»; pedir el área nueva. | `lib/widgets/new_crop_dialog.dart:65-80`; `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md:192,220` | Medio: si se copia el terreno sin ajustar área, el reparto se tuerce. Sin entidad nueva; reutiliza `terrenoId`. | UI + copy (+ parámetro ya existente) |
| 7 | P2 | Recepa/socola no se representa; el productor puede disfrazarla como siembra y rejuvenecer edad. | Copy en Siembras/Ayuda: «si la mata sigue viva, no registres siembra nueva; anota el manejo como gasto del cultivo». No modelar recepa sin validar. | `docs/prds/2026-10-21_1818-cohortes-estructura.prd.md:112`; `docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md:98,292,324` | Nulo si es copy. Alto si se modela sin práctica validada: se descarta. | Solo copy |
| 8 | P2 | El jornal de cosecha permite kg sin lote y el copy solo dice «para comparar con lo vendido». | Copy: «por pase y producto; si pesaste por lote, elige el lote; café por la mañana y plátano por la tarde son dos registros». | `lib/screens/register_screen.dart:644-653`; `lib/l10n/app_es.arb:761-771`; `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md:53-63` | Nulo. No cambia esquema; refuerza aviso existente. | Solo copy |
| 9 | P2 | `Crop.currency` comenta que gastos/ingresos heredan moneda, pero registro usa la de Ajustes. | Decidir una regla: copy/modelo «la moneda la fija Ajustes; `Crop.currency` es legado» o implementar herencia explícita con override por movimiento. | `lib/models/crop.dart:33-35`; `lib/screens/register_screen.dart:1083-1085`; `lib/providers/transaction_provider.dart:338` | Bajo si solo se corrige comentario/copy. Medio si cambia comportamiento: históricos mixtos seguirán ocultando ratios. | Modelo/copy |

## 7 · DR/PRD vs código vigente

| Documento | Código actual | Lectura |
|---|---|---|
| SC-14 de Etapa A prohíbe `harvests.sowing_id`, selector al vender y kg/planta por cohorte (`docs/prds/2026-10-21_1818-cohortes-estructura.prd.md:98-100,109-111`). | Etapa B muestra kg/planta por lote desde jornal medido (`lib/models/cohort_kilos.dart:57-65`; `lib/screens/crops_screen.dart:431-461`). | **No contradicción de modelo**: PRD B lo habilita sin tocar `harvests` (`docs/prds/2026-10-22_1813-cohortes-atribucion.prd.md:20-27,475-483`). El PRD A quedó viejo como texto único; leerlo solo induce a error. |
| `contributionSubtitle`:-lo del lote «sin repartirlo» (`lib/l10n/app_es.arb:1606`). | Reparto por hectáreas (`lib/services/crop_totals.dart:104-113`). | **Inconsistencia de copy**, no de cálculo. Ver mejoras #4. |
| `Crop.currency`: «todos los gastos/ingresos vinculados heredan esta moneda» (`lib/models/crop.dart:33-35`). | Registro usa `settings.currency` (`lib/providers/transaction_provider.dart:338`) y no cambia moneda al elegir cultivo (`lib/screens/register_screen.dart:1083-1085`). | **Inconsistencia de comentario/contrato**. Ver #9. |
| «Nueva variedad» y «+ Nueva variedad…» (`lib/l10n/app_es.arb:508,617`). | Campo «Nombre del cultivo» (`lib/l10n/app_es.arb:620`). | **Inconsistencia de copy**. Ver #2. |
| Ayuda: «perenne o transitorio» (`lib/l10n/app_es.arb:70`). | Selector «Perenne / Anual» (`lib/l10n/app_es.arb:161-162`). | **Copy viejo**. Ver #2. |
| Nota de 2026-10-20: `racimo` y `cajon` valdrían 1 kg y no entrarían a totales (`docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md:81-85`). | `kgFromUnit` exige `equivalentKg`; métricas lo usan (`lib/models/units.dart:27-55`; `lib/services/report_harvest_metrics.dart:98-103`). | **Nota superada**, ya implementado. No reabrir. |
| Tabla pre-Etapa A de cohortes (`docs/analysis/2026-10-20_cohortes-dentro-de-un-cultivo.md:36-52`). | Decisión C y Etapa A (`:408-449`); recompute por cohortes (`lib/models/sowing.dart:242-268`). | **Documento con dos capas**: la tabla es histórica; manda §12. No usar la tabla como estado actual. |
| SC-11: enviar tres claves siempre, incluso `null` (`docs/prds/2026-10-21_1818-cohortes-estructura.prd.md:88-91`). | Push y lectura lo cumplen (`lib/providers/sync_provider.dart:518-520,789-791`). | **Alineado**. Sin acción. |

## Cierre

El modelo es deliberadamente liviano: cultivo = nombre libre + datos de finca; lote = `Sowing`; kilos por lote = jornal medido; gastos = cultivo, terreno o comunes. Esa simplicidad evita datos falsos. Lo que más estorba hoy al productor no es falta de entidades: es copy que nombra mal el cultivo, altas cortas sin contexto, y un `terrenoId` que se pierde al crear desde Cultivos.
