# Cohortes dentro de un cultivo

> Notas para decidir más adelante. **No es un PRD ni una decisión tomada.**
> Nace del ítem 6 del análisis anterior
> (`2026-10-20_rendimiento-y-cultivos-asociados.md`, §1) y de la pregunta del
> 2026-10-20: cómo representar varias edades dentro del mismo cultivo.
> Nada de esto está implementado.
>
> **Actualización 2026-10-21.** En su finca la cosecha de lotes distintos
> **casi siempre se mezcla**. E obligaría a elegir un lote en la venta (o a
> inventar kilos), así que queda descartada. La recomendación vigente está en
> §12: **C**, con la estructura de cohortes primero y la atribución de cosechas
> después.

## 1. El caso

Un cafetal de 5 ha con 1.000 matas de 7 años. En 2026 se siembran 200 plantines
en 0,5 ha (expansión) y en 2027 se renueva 1 ha con 300 matas nuevas.

Lo que el agricultor sabe:

- Las matas de 7 años rinden ≈ 0,55 kg por mata.
- Los plantines de 1 año todavía no producen.
- La hectárea renovada arranca de cero, sin borrar la historia del resto.

Lo que la app puede decir hoy:

- «El cultivo tiene 1.200 plantas» o «1.000», según cómo se haya anotado.
- «Rinde 0,42 kg/planta», mezclando matas que producen con plantines que no.
- «Tiene 1 año», si la expansión se anotó como siembra: la edad del lote viejo
  desaparece.

Eso último no es un detalle de presentación: es un dato falso. La app no puede
distinguir «un cultivo joven» de «un cultivo viejo con plantas nuevas».

## 2. Lo que la app hace hoy (verificado en código)

| Pieza | Qué hace | Dónde |
|---|---|---|
| `Harvest` | Tiene `cropId` y **no** tiene `sowingId`: los kilos son del cultivo entero | `lib/models/harvest.dart:1-28` |
| `Sowing` | `kind` (`siembra`/`resiembra`), `plants`, `areaHa`, `lostPlants`, `date` | `lib/models/sowing.dart:3-24` |
| `recomputeCropState` | Una **siembra** *reemplaza* `livePlants` y `areaHa`; una **resiembra** suma `plants − lost` | `lib/models/sowing.dart:140-182` |
| `edadDeCrop` | Toma la **última siembra**; una resiembra no reinicia la edad | `lib/models/crop.dart:228-241` |
| `lossEarliestDate` | Las pérdidas solo se pueden fechar desde la **siembra más reciente** | `lib/models/sowing.dart:118-127` |
| `yieldPerPlant` | kg totales ÷ **todas** las plantas vivas del cultivo | `lib/services/report_harvest_metrics.dart:215-222` |
| `historicalYield` | Promedio anual ÷ área y plantas **actuales**, no las de cada año | `lib/services/report_harvest_metrics.dart:246-276` |
| Panel por hectárea | Una fila por **cultivo**, con kg/planta y promedio histórico | `lib/widgets/per_hectare_panel.dart:82-92` |
| Cosecha derivada | De la venta sale con `cropId`, sin siembra; prioridad manual > jornal > venta | `lib/services/derived_harvests.dart:113-207` |
| BD | `transactions.sowing_id` existe; `harvests` **no** tiene `sowing_id` | `supabase/migrations/202609070001_add_sowings_harvests.sql:88-90` |

La asimetría de la última fila es la que más pesa: **un gasto sabe a qué
siembra pertenece; una cosecha no**. Por eso el costo por kilo se puede
atribuir y el rendimiento no.

### Consecuencias

1. **Expansión**: anotarla como `siembra` borra plantas, área y edad del lote
   viejo (`livePlants = s.plants`, no suma). Anotarla como `resiembra` conserva
   el total, pero mezcla edades sin decirlo y diluye el kg/planta.
2. **Renovación por partes**: no hay forma de cerrar 1 ha y dejar 4 ha
   intactas. O se reinicia el cultivo entero, o se crea un cultivo aparte: es
   lo que el agricultor hace en la práctica, pero la app no lo facilita y el
   reporte lo muestra como dos filas sin explicar por qué.
3. **Edad**: un solo número. Después de una siembra, el cultivo entero
   «rejuvenece».
4. **Área**: `areaHa` es la de la última siembra, no la suma de lo vivo. Con
   renovación parcial, el kg/ha también miente.
5. **Pérdidas**: `lossEarliestDate` ancla el selector a la última siembra. Si
   hay una cohorte vieja y una nueva, no se pueden anotar muertes de la vieja.
6. **Atribución**: no se puede responder «esta cosecha, ¿de qué matas salió?».
   Sin eso no hay kg/planta por edad ni costo por kilo por cohorte.

## 3. La decisión de fondo

No es «agregar un campo». Son tres preguntas separadas:

1. **Unidad de atribución**: ¿la cosecha se cuelga de una *siembra*, o de una
   entidad nueva (*cohorte*/*planting*) con vida propia?
2. **Divisor**: ¿qué plantas se usan para kg/planta? ¿Todas las vivas, solo las
   de la cohorte, o solo las que ya producen?
3. **Ciclo de vida**: ¿cómo se representa «esta parte se renovó» sin borrar la
   historia y sin inflar el total de plantas?

Una cohorte **no es** una siembra cualquiera: una resiembra es un evento
*dentro* de una cohorte, no una cohorte nueva. Y una renovación **cierra** una
cohorte y **abre** otra. La siembra, en cambio, ya significa «arrancó un lote»,
que es justo el nacimiento de una cohorte.

### Lo que hace el agricultor en la práctica

- No dice «cohorte»: dice **lote**, **tablón** o **parcela**, y cada uno tiene
  su edad. «El tablón de arriba tiene 7 años; el de abajo lo sembré el año
  pasado».
- Renueva **por lote**, no por cultivo entero. Una renovación parcial es, en su
  cabeza, un lote nuevo al lado del viejo.
- Cosecha por **pase**. A veces sabe de qué lote salió cada saco; a veces se
  mezcla todo y no hay forma honesta de atribuirlo.
- La **recepa/socola** no es siembra nueva: la mata sigue, se poda y rebrota.
  Ni «siembra» ni «resiembra» la representan bien.

La app ya tiene **terreno** («la unidad de tierra en la que el productor
piensa», `lib/models/terreno.dart:1-9`) y permite varios cultivos en el mismo
terreno. Es decir: la estructura para partir el lote ya existe. Lo que falta es
que la app lo guíe y no lo haga sentir que duplica el cultivo.

## 4. Opciones

### A. `sowingId` en `Harvest`, sin tocar el resto

Se agrega `sowing_id` (nullable) a `harvests` y un selector al registrar.
Las siembras existentes pasan a hacer de cohortes de facto.

- **A favor**: migración pequeña, sin entidad nueva, sin cambiar
  `recomputeCropState`, alineado con `transactions.sowing_id`.
- **En contra**: no resuelve el ciclo de vida (cerrar/renovar), ni la edad por
  cohorte, ni el divisor. La siembra queda sobrecargada: «arranque de lote» y
  «cohorte» a la vez. Una resiembra sigue sin pertenecer a nadie.
- **Cuándo alcanza**: si lo único que se quiere es saber de dónde salieron los
  kilos, sin cambiar reportes ni edades.

### B. Cohorte como entidad propia

```
Crop 1─* Cohort (plantedAt, plants, areaHa, closedAt?)
Cohort 1─* Sowing (siembra | resiembra)
Cohort 1─* Harvest
```

- **A favor**: el modelo dice la verdad. Expansión, renovación parcial y
  cierre se representan sin trucos. Los reportes por edad salen limpios.
- **En contra**: tabla nueva, migración de datos, sync, backup, formularios,
  reportes y tests. Es la opción más cara y la que más tarda en llegar.
- **Riesgo**: invita a «migrar» cosechas viejas a cohortes inventadas, que es
  exactamente lo que la regla de oro prohíbe.

### C. La siembra **es** la cohorte (híbrido)

Sin tabla nueva en la fase 1: la cohorte se identifica por el `id` de su
siembra. Una resiembra pertenece a la cohorte cuya siembra sea la más reciente
en su fecha. Una cosecha puede llevar `sowing_id` (nullable). Si algún día hace
falta la entidad de B, esos ids ya son estables y se pueden adoptar.

```
Crop
 └─ Sowing(kind=siembra, id=S1)  ← cohorte 2020
     ├─ Sowing(kind=resiembra)   ← repone plantas de S1
     └─ Harvest(sowing_id=S1)
 └─ Sowing(kind=siembra, id=S2)  ← cohorte 2026 (expansión o renovación)
     ├─ Sowing(kind=resiembra)
     └─ Harvest(sowing_id=S2)
```

- **A favor**: camino incremental; la fase 1 es casi la opción A; las métricas
  por cohorte se pueden agregar después sin migrar datos; el vocabulario que ya
  existe («siembra») se reutiliza.
- **En contra**: hay que definir el cierre (fase 3) para que una renovación no
  infle el total de plantas. La resiembra se asigna por fecha, no por un
  puntero explícito; con dos siembras el mismo día hay que desempatar con una
  regla fija.

### D. No hacer nada (solo copy)

Dejar el número actual y decir «aproximado» cuando haya resiembra, como ya
hace `hasResiembra` en PDF/Excel.

- **A favor**: cero riesgo, cero migración.
- **En contra**: no arregla la expansión (sigue borrando la edad), ni la
  renovación parcial, ni el kg/planta mezclado. El agricultor que sí tiene dos
  edades sigue viendo un promedio que no es el de ninguna de las dos.

### E. Partir el lote en dos cultivos (lo que ya hace)

No se agrega nada al modelo. Se usa lo que existe: un **terreno** con dos
cultivos, cada uno con su fecha, sus plantas y su área.

```
Terreno «Finca»
 ├─ Cultivo «Café viejo»  4 ha · 1.000 plantas · 2020
 └─ Cultivo «Café nuevo»  1 ha ·   300 plantas · 2026
```

- **A favor**: es la práctica real; cero migración; la edad, el kg/planta y el
  costo por kilo salen bien por lote; las cosechas viejas no se tocan; el
  reparto de gastos de la Tanda 4 ya permite cargar una fumigación compartida
  por porcentaje.
- **En contra**: el reporte muestra dos filas de café en vez de una; hay que
  crear el segundo cultivo a mano (no hay «duplicar»); el nombre tiene que
  llevar la edad o el lote, o se confunden; no hay un total «Café» que sume los
  dos.
- **Costo real**: casi todo es copy y flujo, no datos. Lo que hay que construir
  es una forma de **dividir** sin fricción: al crear un cultivo, ofrecer «es
  otra parte de un lote que ya tengo», copiar terreno y variedad, y pedir
  solo lo nuevo (área, plantas, fecha).
- **Lo que no resuelve**: la recepa/socola y la venta mezclada. Tampoco el
  asocio (dos cultivos en la misma área), que ya está fuera de alcance.

### Comparación

| | Atribuir cosecha | Edad por cohorte | Renovación parcial | Migración | Esfuerzo |
|---|---|---|---|---|---|
| A | Sí | No | No | Chica | Bajo |
| B | Sí | Sí | Sí | Grande | Alto |
| C | Sí | Sí (fase 2) | Sí (fase 3) | Chica → media | Medio |
| D | No | No | No | Ninguna | Nulo |
| **E** | **Sí, por lote** | **Sí, por lote** | **Sí** | **Ninguna** | **Bajo (UX)** |

## 5. Recomendación

> Superada por §12 (2026-10-21): con venta mezclada, la recomendación vigente es
> C con la estructura primero. Se conserva el razonamiento de E.

**E primero.** Es lo que el agricultor ya hace, no toca datos y resuelve la
expansión, la renovación parcial y la edad por lote sin migración. La app ya
tiene el terreno y los cultivos; lo que falta es que dividir sea fácil y que
el reporte no parezca una duplicación.

### Qué haría falta para que E funcione bien

- Copy en el formulario: al crear un cultivo en un terreno que ya tiene otro,
  ofrecer «es otra parte del mismo lote» y precargar terreno y variedad.
- Acción **«dividir cultivo»**: pide área, plantas y fecha de la parte nueva,
  crea el segundo cultivo y deja el viejo intacto.
- Nombre: sugerir «Café viejo / Café nuevo» o el nombre del lote; avisar (sin
  bloquear) si dos cultivos del mismo terreno se llaman igual.
- Reporte: dos filas con su nombre completo; no sumar áreas ni plantas.
- Gastos compartidos: usar el reparto por % que ya existe (T15). No hace falta
  nada nuevo.
- Nada de mover cosechas: las del lote viejo se quedan ahí.

Lo que E **no** resuelve: la recepa/socola (no es siembra nueva) y la venta
mezclada (no se puede atribuir). Ahí la respuesta sigue siendo `null`.

### Si se prefiere una sola fila «Café»: C, por fases

La fase 1 se puede hacer sola y no cambia ningún número existente; las fases 2
y 3 agregan lo que falta sin reescribir datos viejos.

#### Fase 1 · atribución (opcional)

- `harvests.sowing_id uuid null references sowings(id) on delete set null`.
- `Harvest.sowingId` + JSON + `copyWith` con centinela.
- Selector solo cuando el cultivo tiene **2 o más** cohortes abiertas.
  - Con una sola cohorte, se asigna sola (no hay ambigüedad) y se muestra en
    el resumen.
  - Con varias, la opción por defecto es **«No sé / todo el cultivo»**
    (`null`). Elegir por el usuario sería inventar.
- Las cosechas derivadas (venta y jornal) **nunca** llevan cohorte: se calculan
  al leer y una cohorte creada después las reatribuiría hacia atrás. Ver §6.
- Vista por cohorte: los kg sin cohorte se **listan aparte**, no se reparten.
- Sin backfill: las cosechas viejas quedan en `null`.

#### Fase 2 · métricas por cohorte

- `yieldPerPlant` por cohorte = kg de esa cohorte ÷ plantas vivas de esa
  cohorte. Si el divisor es `null` o ≤ 0 → `null` (oculto, nunca 0).
- La cohorte sin cosechas en el período muestra «—», no «0».
- La fila del panel sigue siendo por cultivo. Se despliega el desglose solo si
  hay más de una cohorte.
- Copy ES/EN: «promedio de 2 edades» en el número del cultivo; el desglose
  dice la edad de cada una. El promedio histórico (`historicalYield`) sigue
  usando área y plantas actuales, con su nota de aproximado.
- PDF/Excel: columna de cohorte solo cuando hay más de una; el diseño por
  defecto no cambia.

#### Fase 3 · ciclo de vida

- Cerrar una cohorte con fecha (`closedAt`), sin borrar sus siembras ni sus
  cosechas. Sus plantas salen del divisor desde esa fecha; sus kilos históricos
  se conservan.
- Al anotar una `siembra` en un cultivo que ya tiene cohortes abiertas,
  preguntar: **expansión** (abre cohorte, no cierra nada) o **renovación**
  (abre y cierra la anterior). Sin esa pregunta, sumar cohortes infla las
  plantas.
- Área: la del cultivo sigue siendo la que él escribió. Si la suma de áreas de
  las cohortes abiertas no coincide, **avisar sin bloquear** (misma regla que
  la Tanda 4).
- `lossEarliestDate` pasa a depender de la cohorte elegida, no de la última
  siembra del cultivo.
- Renovación completa: cerrar la cohorte vieja y abrir una nueva; la edad del
  lote nuevo empieza en su siembra, la historia vieja no se borra.

## 6. Reglas que no se negocian

- **`null` → oculto, nunca 0.** Una cohorte o un lote sin plantas, sin área o
  sin cosechas no inventa un divisor.
- **Dividir no duplica datos.** Cada lote es un cultivo con su propia historia;
  el viejo no pierde plantas, área ni cosechas.
- **No mover cosechas viejas al lote nuevo.** Una cosecha pertenece al lote
  donde se anotó; dividir no reescribe el pasado.
- **No sumar los lotes en un total «Café».** El reporte muestra una fila por
  lote. Un total agrupado sería otra función, no un efecto automático.
- **La recepa/socola no se anota como siembra nueva.** La mata sigue viva; hoy
  no hay campo que la represente. No inventarlo con una siembra falsa.
- **Sin backfill ni inferencia retroactiva.** Ni por fecha, ni «la más
  probable», ni «la única que había». Los datos viejos quedan `null` y se
  listan como «sin cohorte».
- **Derivadas sin cohorte.** `deriveHarvests` corre en cada lectura; si se
  asignara la cohorte «vigente», crear una cohorte nueva cambiaría el pasado.
- **Un cultivo con una sola cohorte se comporta igual que hoy.** Los números
  no se mueven.
- **No sumar áreas de cohortes al área del cultivo.** En asocio o traslape,
  sumar miente. Solo avisar.
- **No tocar `transactions.sowing_id`.** Ahí significa «gasto de esa siembra»;
  es otra cosa.
- **No tocar `HarvestDestination.almacenado`** ni la regla «todo lo que se
  cosecha se vende».

## 7. Casos borde

Las filas de «cohorte» son de C; las de «lote», de E.

| Caso | Qué debería pasar |
|---|---|
| Venta sin cohorte en un cultivo con 2 cohortes | Cosecha derivada sin cohorte; sus kg entran al total del cultivo y se listan como «sin cohorte» |
| Jornal medido, igual | Igual: sin cohorte (el jornal no sabe de matas) |
| Cosecha fechada antes de la siembra de la cohorte | No asignar; dejar `null` y avisar |
| Dos siembras el mismo día | Desempate fijo: la siembra manda sobre la resiembra (igual que `recomputeCropState`); la resiembra se cuelga de la siembra de ese día |
| Resiembra anterior a toda siembra | Sin cohorte; solo cuenta al total del cultivo |
| Resiembra sin `lostPlants` | Se suma igual (comportamiento actual); el kg/planta queda diluido y el copy lo advierte |
| Cohorte cerrada y cosecha posterior | Se registra y se atribuye si él la elige; el kg/planta de esa cohorte puede quedar `null` si ya no tiene plantas |
| Borrar una siembra con cosechas | `on delete set null`; las cosechas no se borran, quedan «sin cohorte». Avisar antes |
| Borrar el cultivo | Se borran siembras y cosechas como hoy; las transacciones se desvinculan |
| Renovación parcial (E) | Crear un cultivo nuevo en el mismo terreno, con su fecha, su área y sus plantas; el viejo no se toca. El gasto compartido se reparte con T15 |
| Recepa/socola (E y C) | Hoy no se representa; no anotarla como siembra ni como resiembra. Queda como hueco aparte |
| Dos cultivos del mismo terreno con el mismo nombre (E) | Avisar sin bloquear: el reporte no podría distinguirlos |
| Cultivo anual | Cohortes válidas (una por ciclo); la edad sigue oculta (`edadDeCrop` devuelve `null` para anuales) |
| Asocio / área compartida | La cohorte puede tener área propia, pero no se suma al cultivo ni se usa para repartir costos |
| Offline: la siembra no subió y la cosecha sí intenta | La FK falla, la cosecha queda pendiente y se reintenta; el orden de push ya pone `sowings` antes de `harvests` |
| Sync baja una cosecha con `sowing_id` de una siembra borrada | El remoto ya la dejó en `null`; el merge no debe resucitar el vínculo |

## 8. Impacto técnico

**Si se elige E** — sin migración ni modelo nuevo:

- Flujo **«dividir cultivo»**: copiar terreno y variedad, pedir área, plantas y
  fecha de la parte nueva.
- Copy ES/EN y aviso (sin bloqueo) de nombres repetidos en el mismo terreno.
- El reporte **no cambia**: ya muestra una fila por cultivo.
- Tests: el flujo crea el cultivo nuevo con los datos pedidos y deja intacto el
  viejo; el reporte muestra dos filas.

**Si se elige C**:

- **Migración**: una columna + índice en `harvests` (fase 1); `closed_at` en
  `sowings` (fase 3). Aditiva, `if not exists`, sin backfill.
- **Modelos**: `Harvest.sowingId`, `Sowing.closedAt`; JSON y `copyWith` con
  centinela (el patrón que ya usan `plantedAt`, `lostPlants` y `reason`).
- **Provider**: `recomputeCropState` deja de *reemplazar* cuando la siembra es
  una cohorte nueva; pasa a sumar cohortes abiertas (fase 3). Borrado de
  siembra: desvincular cosechas en local, igual que hoy hace con
  `transactions.sowingId` (`transaction_provider.dart:740-741`).
- **Huérfanos**: el chequeo de referencias (`transaction_provider.dart:1071`)
  y el resumen de respaldo (`backup_service.dart:144`) tienen que conocer la
  nueva referencia.
- **Sync**: `buildHarvestPayload` + parseo del pull; el orden de stages ya es
  correcto. Si la siembra falla, la cosecha queda pendiente (no se pierde).
- **Métricas**: función pura por cohorte; reutilizar `yieldPerPlant` con
  `livePlants` de la cohorte. `historicalYield` no cambia en fase 1.
- **UI**: selector en el registro de cosecha (hoy la pantalla está oculta; el
  camino real es el jornal), desglose en el panel por hectárea, formulario de
  siembra con la pregunta expansión/renovación (fase 3).
- **Exportes**: PDF/Excel solo si hay más de una cohorte.
- **Tests**: asignación por fecha (incluido el empate del mismo día), métricas
  por cohorte, edad por cohorte, selector, payload de sync, migración presente
  (como `test/migration_harvested_kg_test.dart`), y un test de que un cultivo
  con una sola cohorte no cambia ningún número.

## 9. Preguntas para decidir

1. ¿Vamos con **E** (partir el lote en dos cultivos) o con **C** (una sola
   fila «Café» con cohortes adentro)?
2. Si E: ¿alcanza con copy que explique crear el segundo cultivo, o hace falta
   un flujo **«dividir cultivo»**?
3. Si E: ¿el nombre lo sugiere la app («Café viejo / Café nuevo») o lo escribe
   él?
4. Si C: ¿la siembra es la cohorte (C) o una entidad propia (B)?
5. Si C: la cosecha pide cohorte **solo cuando hay varias**, o siempre.
6. Si C: con varias edades, ¿la edad del cultivo se **oculta** y se muestra
   solo por cohorte, o se muestra la más vieja con «y N más»?
7. Si C: renovar por partes, ¿**cerrar** la cohorte con fecha o una siembra
   nueva que reemplace el total (lo de hoy)?

## 10. Esfuerzo relativo

| Fase | Alcance | Tamaño |
|---|---|---|
| E · dividir el lote | flujo + copy ES/EN; sin migración | chico |
| C · 1 · atribución | migración, modelo, sync, selector, lista «sin cohorte» | chico-medio |
| C · 2 · métricas | kg/planta y edad por cohorte, panel, copy ES/EN, exportes | medio |
| C · 3 · ciclo de vida | cierre, expansión vs renovación, áreas, `lossEarliestDate` | medio-grande |

Sin fechas: E se puede cerrar en una sesión; C · 1 también. C · 3 toca
siembras, reportes y copy, y conviene hacerla con su propio PRD.

## 11. Qué falta para un PRD

- [ ] Elegir E o C.
- [ ] Si E: definir si hay flujo de división o solo copy, y quién pone el
      nombre.
- [ ] Si C: elegir si la siembra es la cohorte o una entidad propia.
- [ ] Si C: definir el default del selector (recomiendo «No sé»).
- [ ] Si C: definir si el cierre es `closedAt` o un `SowingKind` nuevo.
- [ ] Si C: decidir qué pasa con `crop.livePlants` y `crop.areaHa` cuando hay
      cohortes (suma de abiertas vs. valor manual).
- [ ] Nombrar el copy de «sin cohorte» en ES y EN (solo si C).
- [ ] Enumerar los criterios de aceptación (SC) y las migraciones exactas.

## 12. Decisión del 2026-10-21: C, estructura primero

Hecho que manda: la cosecha de lotes de distinta edad **casi siempre se mezcla**
en un solo saco y una sola venta.

### Por qué E no

- Los ingresos no tienen reparto (el reparto de T15 es solo para gastos): una
  venta apunta a un cultivo o a ninguno.
- Con dos cultivos, elegir uno atribuye mal; registrar dos ventas obliga a
  inventar kilos.
- No hay un total «Café» que reciba la venta mezclada.

### Qué es C para este caso

- Un cultivo «Café»; cada siembra abre una cohorte con su edad, plantas y área.
- La venta mezclada se queda en el cultivo. No se atribuye a una cohorte.
- El kg/planta del cultivo sigue siendo el promedio de todas las plantas, y el
  copy dice «promedio de N edades».
- El kg/planta por cohorte **solo aparece si se pesó por lote** (jornal con
  kilos por cohorte). Si no, se oculta: no se reparte por área ni por plantas.

### Orden de construcción

#### A · estructura (lo que sí resuelve su caso)

- Siembra = cohorte. Resiembra = evento de la cohorte vigente.
- La siembra nueva lleva **`replaces_plants`** y, opcional,
  **`replaces_area_ha`**: cuántas matas y hectáreas del lote viejo reemplaza.
- **`cohort_sowing_id`** (nullable) guarda a qué cohorte se refiere: la que
  reemplaza (siembra) o a la que pertenece (resiembra). Sin puntero, con dos
  cohortes abiertas la fecha no alcanza para saberlo.
- `recomputeCropState` **suma** las cohortes abiertas y resta los reemplazos
  (hoy reemplaza todo).
- Edad por cohorte; el cultivo muestra «N edades», sin inventar un promedio.
- Al anotar una siembra con cohortes abiertas, preguntar **expansión** (no
  reemplaza nada) o **renovación** (reemplaza).
- Sin `closed_at`: una cohorte está cerrada cuando sus matas vivas llegan a 0.
- Sin tocar `harvests`. Sin selector. Sin migración de cosechas.
- Datos viejos: al abrir por primera vez, cada siembra posterior a la primera
  se marca como reemplazo de las matas que quedaban. Así los números de hoy no
  se mueven; si alguna era expansión, él la corrige a 0.

##### Renovación parcial (decidido 2026-10-21)

Caso: 1.000 matas en 5 ha; se renuevan 1 ha con 300 matas.

- `replaces_plants = 0` → expansión: la cohorte vieja sigue con 1.000.
- `replaces_plants = 300` con `replaces_area_ha = 1` → la vieja baja a 700
  matas y 4 ha; la nueva suma 300 y 1 ha. Total: 1.000 matas y 5 ha.
- `replaces_plants = 1.000` → renovación completa: la vieja queda en 0.
- Se precarga por área (300 de 1.000) y él lo corrige.
- Validación: no puede reemplazar más matas de las que la cohorte vieja tiene
  vivas. Si hay más de una cohorte abierta, se elige cuál se reemplaza.

#### B · atribución (solo si algún día pesa por lote)

- `harvests.sowing_id` + selector opcional.
- Lista «sin cohorte» para lo mezclado.
- kg/planta por cohorte cuando hay medida.

#### C · reportes por cohorte

- Desglose en el panel/PDF/Excel solo cuando hay más de una cohorte y datos
  atribuidos.

### Lo que no se resuelve

- Repartir los kg de una venta mezclada por edad: no hay dato. Se listan como
  «sin cohorte» a nivel de cultivo.
- La recepa/socola: la mata sigue; no es siembra. Queda aparte.

### Costo

A: una migración (`replaces_plants`, `replaces_area_ha` y
`cohort_sowing_id`), el cálculo, el formulario y el copy. No toca la tabla de
cosechas ni la sincronización de cosechas.

### Pendiente para el PRD

- Cómo se precarga el reemplazo por área cuando él no mide el área renovada.
- Qué pasa con `crop.areaHa`: ¿suma de cohortes abiertas o valor manual?
- Cómo se muestra una cohorte con 0 matas pero con historia (¿se oculta de la
  lista o se muestra como «renovada»?).
