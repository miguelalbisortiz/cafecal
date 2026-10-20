# Kilos recolectados en el jornal de «Cosechar» — Tanda 2

> Generado por `prd-agent` el **2026-10-19 09:41** a partir del pedido:
> «Tanda 2 de la cosecha derivada: un campo opcional de “kilos recolectados” en el jornal cuya labor es “Cosechar”.»
> Brief de subagente. **Sin implementación**: este documento es solo requisitos.

## Status
**APPROVED** — el usuario aprobó D1-D15 y resolvió Q1-Q7 el 2026-10-19. No hay plan de implementación ni cambios de código todavía.

---

## Context

La app **Mi Cafetal** es local-first, offline, con sync opcional a Supabase. El flujo central es cultivo → siembra → gastos → venta. La pantalla de **Cosechas** se ocultó del menú el 2026-09-24 porque «el pequeño agricultor produce y vende sin almacenar»; desde entonces, la única cosecha que existe es la **derivada de la venta** (`lib/services/derived_harvests.dart`), calculada al leer y nunca persistida (D1 del plan del 2026-10-15).

El **jornal** es una `Transaction` de la categoría `mano_obra` (`lib/models/categories.dart:92`): `quantity` son **días**, `unit = 'día'`, `pricePerUnit` es el valor por día, `provider` es el trabajador y `task` es la tecla de labor (`lib/models/transaction.dart:42-46,72-82`). **No hay ningún campo de kilos.** El catálogo de labores tiene `FarmTask(key: 'cosechar', name: 'Cosechar', icon: '🍒')` (`lib/models/tasks.dart:31`).

El plan de la cosecha derivada dejó anotada esta tanda en §5.1 (L138-150) y la decisión **D4** (L135): la fuente «jornal» entra **por encima de la venta** y es **un `if` más** en la función pura, no un rediseño. El comentario de `derived_harvests.dart:46-62` ya describe la prioridad `manual > jornal > venta`; la línea 55 dice: «`jornal` — [Tanda 2] kilos recolectados. Todavía no existe.». El test `test/derived_harvests_test.dart:296-308` ya **simula** una cosecha `der_jornal_v1` para comprobar que `hasIndependentHarvest` se enciende con una fuente que no es la venta.

**Lo que falta** es la fuente: que el agricultor pueda anotar, **opcionalmente**, cuántos kilos recolectó en un jornal cuya labor es «Cosechar». Ese dato es la única forma de obtener dos cosas que la venta jamás dará (§5.1):

1. **Regla 6** (vendido > cosechado) pasa de muda a activa.
2. **Pérdida en campo**: lo que se recogió y no se vendió.

La cobertura será parcial (solo quien paga por día y mide). Por eso el campo es opcional y no se le pide a nadie que lo use.

### Evidencia revisada

| Pieza | Anclaje |
|---|---|
| Categoría del jornal | `lib/models/categories.dart:92` (`mano_obra`) |
| Modelo `Transaction` | `lib/models/transaction.dart:42-46` (`quantity`, `unit`, `pricePerUnit`), `72-82` (`task`), `197-252` (`toJson`/`fromJson`) |
| Catálogo de labores | `lib/models/tasks.dart:27-40`; `cosechar` en L31; `kTaskOther` en L11 |
| Formulario del jornal | `lib/screens/register_screen.dart:104-105` (`_isJornal`), `1065-1102` (labor), `1106-1120` (días), `1124-1140` (valor día), `383-411` (guardado) |
| Cosecha derivada | `lib/services/derived_harvests.dart:68` (`kSaleDerivedPrefix`), `77-78` (`isSaleDerivedHarvest`), `96-155` (`deriveHarvests`), `46-62` (puerta D4) |
| Cableado | `lib/providers/transaction_provider.dart:96-99` (`harvests` = guardadas + derivadas), `111` (`storedHarvests`) |
| Nómina/planilla | `lib/services/report_payroll_metrics.dart:198-229` (`payroll`), `391-476` (`workSheetRows`); usan `quantity` como días |
| Menú Cosechas oculto | `lib/screens/home_screen.dart:224-236` |
| Plan §5.1 / D4 | `docs/plans/2026-10-15-cosecha-derivada-de-la-venta.plan.md:135,138-150` |
| Test que simula la tanda | `test/derived_harvests_test.dart:296-308` |

`docs/PROJECT.md` es auto-generado y no trae `Non-Negotiables` manuales; las reglas que mandan son las del pack y las del plan citado.

---

## Objective

Permitir que un jornal cuya labor es **«Cosechar»** registre **opcionalmente** los **kilos recolectados**, para que la cosecha derivada use esa medida independiente **por encima de la venta** y se activen la comparación «vendido vs cosechado» y la señal de pérdida en campo, **sin** pedir un paso nuevo, **sin** cambiar el pago del jornal y **sin** reabrir la pantalla de Cosechas.

---

## Success Criteria

> **Modal EARS:** en este documento `DEBE` = `SHALL` y `NO DEBE` = `SHALL NOT`. Cada criterio se puede responder con sí o no sobre la app corriendo.

- [ ] **SC-1 — Fuente del jornal.** WHERE un gasto no borrado tiene `category = 'mano_obra'`, `task = 'cosechar'`, `cropId != null` y `harvestedKg > 0`, WHEN se leen las cosechas (`TransactionProvider.harvests`), el sistema DEBE incluir **exactamente una** cosecha derivada con `id = 'der_jornal_<transactionId>'`, `cropId = transaction.cropId`, `date = transaction.date`, `amount = transaction.harvestedKg`, `unit = 'kg'`, `destination = HarvestDestination.vendido` y `pendingSync = false`.
- [ ] **SC-2 — Sin kilos no hay cosecha.** IF `harvestedKg` es `null`, `0` o negativo, el sistema NO DEBE incluir una cosecha derivada de ese jornal; el jornal DEBE seguir siendo válido y conservar `amount = días × valor día`, `quantity = días`, `unit = 'día'`.
- [ ] **SC-3 — Manda lo manual.** WHERE el cultivo tiene al menos una cosecha guardada a mano (`storedHarvests`), el sistema NO DEBE derivar cosechas del jornal ni de la venta para ese cultivo; la manual DEBE ser la única fuente.
- [ ] **SC-4 — Jornal por encima de la venta.** WHERE un cultivo tiene al menos un jornal no borrado con `task = 'cosechar'` y `harvestedKg > 0`, el sistema NO DEBE derivar cosechas de la venta para ese cultivo y DEBE derivar **una cosecha por cada jornal medido**.
- [ ] **SC-5 — Borrado limpio.** WHEN un jornal con kilos se marca `deleted = true`, el sistema DEBE excluir su cosecha derivada en la siguiente lectura, sin persistir ni borrar una fila de `Harvest`.
- [ ] **SC-6 — Cambio de labor.** WHEN la labor de un jornal cambia de `'cosechar'` a otra tecla o a `null`, el sistema DEBE guardar `harvestedKg = null` y NO DEBE derivar cosecha de ese jornal.
- [ ] **SC-7 — Sin cultivo, sin campo.** WHERE el jornal no tiene cultivo (`cropId = null`) o está asignado a un terreno (`terrenoId != null`), el sistema DEBE ocultar el campo de kilos, guardar `harvestedKg = null` y NO DEBE crear una cosecha con `cropId = null`.
- [ ] **SC-8 — Validación.** IF el campo de kilos está vacío, el sistema DEBE guardar `null`; IF contiene un valor `<= 0` o no numérico, el sistema DEBE bloquear el guardado con el mensaje de validación y NO DEBE guardar el jornal.
- [ ] **SC-9 — El pago no se toca.** WHEN se guarda un jornal con kilos, el sistema DEBE mantener `amount = días × valor día`, `quantity = días`, `unit = 'día'`; `ReportPayrollMetrics.payroll()` y `workSheetRows()` DEBEN sumar exactamente los mismos días y montos que sin el campo de kilos.
- [ ] **SC-10 — Tres pintadores de acuerdo.** WHEN existe al menos un jornal con kilos en el período, el sistema DEBE mostrar la tarjeta «Vendido vs cosechado» en pantalla, PDF y Excel, y los tres DEBEN reportar el mismo `harvestedKg` para el mismo cultivo y período (diferencia = 0).
- [ ] **SC-11 — Sigue callada sin fuente independiente.** WHERE la única fuente de cosecha del período es la venta (sin jornal con kilos y sin cosecha manual), el sistema NO DEBE mostrar la tarjeta «Vendido vs cosechado» ni emitir la alerta de la regla 6.
- [ ] **SC-12 — Compatibilidad hacia atrás.** WHEN se carga una transacción o un respaldo anterior sin la clave `harvested_kg`, el sistema DEBE interpretar `harvestedKg = null` y comportarse exactamente como antes (sin cosecha derivada del jornal).
- [ ] **SC-13 — Sync conserva el dato.** WHEN un jornal con `harvestedKg = 500` se sincroniza y se vuelve a leer desde Supabase, el sistema DEBE conservar `harvestedKg = 500`; WHEN es `null`, DEBE enviar `null` y NO DEBE inventar `0`.
- [ ] **SC-14 — Nada derivado se sube.** El sistema NO DEBE subir ni respaldar ninguna cosecha con `id` que empiece por `der_jornal_`; `storedHarvests` DEBE contener solo las cosechas guardadas.
- [ ] **SC-15 — Kilos no son moneda.** El sistema NO DEBE mostrar símbolo de moneda, sumar ni convertir los kilos; el campo y la cosecha derivada DEBEN expresarse en `kg`.

---

## Out of Scope (no-alcance)

- **Reabrir `HarvestScreen`** ni el ítem de menú «Cosechas» (`home_screen.dart:224-236`). La cosecha sigue siendo derivada y sin pantalla propia.
- **Cambiar el pago del jornal**: sigue siendo `días × valor día`. No hay destajo ni pago por kilo en esta tanda.
- **Agregar una tarjeta o sección nueva de «pérdida en campo»**: el renglón de mismatch de la tarjeta existente y la regla 6 ya la insinúan.
- **Agregar una columna de kilos a la planilla/nómina**: la planilla sigue en días y montos.
- **Tocar W1-c** (terreno en reportes/PDF/Excel), moneda, caja, por cobrar o la arquitectura de sync.
- **Tocar `HarvestDestination.almacenado`** o cualquier copy que mencione bodega/almacenamiento. El dominio es «todo lo que se cosecha se vende».
- **Editar cosechas a mano** o reabrir el flujo manual de cosecha.
- **Unidades distintas de kg** (arrobas, sacos, racimos) para el jornal. En esta tanda el campo es fijo en kilos.
- **Cambiar el copy o el umbral de la alerta de la regla 6** sin decisión explícita del usuario (ver Q5).
- **Rellenar jornales viejos con kilos**: no hay backfill; los datos anteriores quedan en `null`.
- **Repartir kilos entre cultivos de un lote por hectáreas**: no se inventa la proporción. Sin cultivo, no hay campo.
- **Categoría «Cosecha y recolección»** (`cosecha`): el campo vive solo en el jornal de `mano_obra`, no en esa categoría.

---

## Assumptions

- El usuario que paga jornal y mide kilos **elige el cultivo** en el jornal. Si no lo elige, el campo se oculta y no se deriva nada. **Aprobado en Q3; falta validar con uso real.**
- «Kilos recolectados» significa **kilogramos**, no arrobas ni sacos. **Aprobado en Q6.**
- El usuario acepta que la medición del jornal **suprime la cosecha derivada de la venta** para ese cultivo (prioridad conservadora, sin doble conteo). **Aprobado en Q2.**
- El usuario acepta que la **regla 6 pueda saltar** si solo mide una parte de la cosecha. **Aprobado en Q5.**
- El usuario acepta una **migración de Supabase** para que el campo sobreviva al sync. **Aprobado en Q1.**
- Solo cuenta la tecla **`'cosechar'` del catálogo**. Texto libre de «Otra…» que diga «cosechar» **no** enciende el campo. **Aprobado en Q4; guarda G12.**
- La cosecha derivada del jornal usa `destination = vendido` porque el dominio asume que todo lo cosechado se vende; la diferencia con la venta es la pérdida en campo, no un destino distinto.

---

## Users

- **Primary:** pequeño caficultor que paga jornales por día y anota la labor en Registrar. Quiere saber si lo que dice que cosechó coincide con lo que vendió.
- **Secondary:** la misma persona (o su contador) cuando lee Reportes, PDF o Excel y compara «vendido vs cosechado».
- **Not for:** quien solo registra ventas — su comportamiento actual no cambia; quien mide en arrobas/sacos sin convertir — esta tanda no lo cubre; quien lleva cosechas a mano — esas siguen mandando (D2).

---

## Constraints

- **Idioma:** todo el copy en **ES y EN**; `lib/l10n/app_es.arb` es el template. Placeholders en el orden de la frase. Después de tocar ARB: `flutter gen-l10n`.
- **`null` = oculto, nunca 0.** No se inventan cifras ni hechos. Sin kilos, no hay cosecha; sin cultivo, no hay campo.
- **Una sola función para una sola regla:** la prioridad y la derivación viven en `deriveHarvests`, no repartidas entre pantalla y provider.
- **Moneda:** el código es el único indicador (`COP 1.500`), nunca `$`; moneda única → una cifra; dos o más → una línea por moneda, sin sumar ni convertir. Los kilos no llevan moneda.
- **Dominio:** todo lo que se cosecha se vende; ningún copy menciona bodega; `HarvestDestination.almacenado` no se toca.
- **No reabrir:** `HarvestScreen`, el ítem de menú «Cosechas», ni el pago del jornal.
- **Migración:** la columna nueva debe aplicarse **antes** de desplegar la app que la envía; si no, PostgREST responde `PGRST204` y se cae el subido completo (mismo caso que `task` en `202610110002`). Debe ser idempotente (`add column if not exists`).
- **Gates:** cada fase termina con `flutter analyze` + `flutter test` limpios. Ningún commit/push sin verbo explícito del usuario.
- **El usuario decide cada cosa:** ningún cambio de UI/texto se da por aprobado sin decisión explícita suya.

---

## Decisiones

### D1 — Dónde vive el campo: en `Transaction`, no en `Harvest`

- **Decisión:** agregar un campo nullable `double? harvestedKg` a `Transaction`, serializado como `harvested_kg`. El jornal sigue siendo **una sola fila**; la cosecha se sigue **derivando al leer**.
- **Alternativa descartada:** crear una fila `Harvest` guardada al vuelo y enlazarla al jornal con `harvestId`.
- **Por qué:** una sola fila; editar o borrar el jornal corrige la cosecha sola, sin zombies en `mergeRemoteHarvests`; y **no** se toca `pickupCostPerKg`, que suma los **gastos con `harvest_id`** (`report_harvest_metrics.dart:62-76`). Enlazar el jornal a una cosecha lo convertiría en «gasto de recogida» y podría duplicar el costo. Costo aceptado: una columna nueva en Supabase y su payload.

### D2 — La derivación vive en la función pura `deriveHarvests`

- **Decisión:** extender `deriveHarvests` con una **segunda fuente** y un prefijo propio `der_jornal_`; la prioridad `manual > jornal > venta` se resuelve ahí, en un solo lugar.
- **Alternativa descartada:** una función separada para el jornal y concatenar en `TransactionProvider`.
- **Por qué:** la regla es una sola; partirla invita al doble conteo y a que un pintador vea una cosa y otro vea otra. `isSaleDerivedHarvest` sigue distinguiendo la fuente y `hasIndependentHarvest` se enciende con el jornal **sin tocarlo**.

### D3 — Convivencia: manual > jornal > venta, **por cultivo**

- **Decisión:** si el cultivo tiene una cosecha manual, no se deriva ni jornal ni venta. Si no tiene manual pero tiene al menos un jornal **no borrado** con kilos, **no se derivan cosechas de la venta para ese cultivo** y se derivan las del jornal. Si no tiene ninguna de las dos, se deriva de la venta como hoy.
- **Alternativa descartada:** sumar jornal + venta (doble conteo); priorizar por fecha (una venta unos días después del jornal duplicaría); priorizar por mes (una venta que cruza de mes duplicaría).
- **Por qué:** nunca inventar ni duplicar. El costo aceptado es explícito: si el agricultor mide solo **algunos** jornales, la venta ya no rellena los días no medidos. Es el mismo trade-off conservador de D2, y es preferible a inflar la cosecha. **Aprobado en Q2 (2026-10-19).**

### D4 — Visibilidad: solo jornal, labor exacta «Cosechar» y cultivo elegido

- **Decisión:** el campo se muestra **solo** cuando `_isJornal` (`mano_obra`), la labor elegida es la tecla `'cosechar'` del catálogo y hay **cultivo** (`cropId != null`, no lote). En cualquier otro caso se oculta y se guarda `null`.
- **Alternativa descartada:** mostrarlo siempre en el jornal (invita a anotar kilos en «Abonar»); mostrarlo sin cultivo y derivar una cosecha «Sin cultivo» (no alimenta rendimiento/ha ni kg/planta y rompe la atribución); mostrarlo para «Otra…» con texto libre (no es agrupable ni confiable).
- **Por qué:** `null` → oculto; sin cultivo no hay a quién atribuir. Si la labor es «Otra…» y el texto dice «cosechar», **no** cuenta: solo la tecla del catálogo. **Aprobado en Q3 y Q4 (2026-10-19).**

### D5 — Opcional y validado: vacío = `null`; si se escribe, `> 0`

- **Decisión:** el campo es opcional. Vacío → `null`. Si tiene texto, debe ser un número `> 0` (decimales permitidos; coma o punto). `0`, negativos o texto no numérico bloquean el guardado con mensaje.
- **Alternativa descartada:** exigir kilos para toda labor «Cosechar» (rompe el flujo actual y la regla «si se puede pedir después, no se pide ahora»); aceptar `0` como `null` (tapa un error de tipeo).
- **Por qué:** el dato es opt-in; un jornal sin kilos sigue siendo un jornal válido. `0` no es una cosecha.

### D6 — Unidad: kilos fijos

- **Decisión:** un solo campo numérico en **kg**; la cosecha derivada usa `unit = 'kg'`. No hay selector de unidad en el jornal.
- **Alternativa descartada:** `harvestedQty` + `harvestUnit` como en la venta (dos campos y UI extra, no pedido en Tanda 2); convertir arrobas/sacos automáticamente (inventaría un factor).
- **Por qué:** el pedido es «kilos recolectados»; la comparación con la venta ya se hace en kg vía `unitToKg`. Si el usuario mide en otra unidad, se decide después (Q6).

### D7 — El pago no cambia

- **Decisión:** los kilos **no** tocan `amount`, `quantity`, `unit` ni la nómina. Sigue `amount = días × valor día`, `quantity = días`, `unit = 'día'`.
- **Alternativa descartada:** pagar por kilo (destajo), que reabriría el jornal y la nómina.
- **Por qué:** el campo es una **medida de cosecha**, no una forma de pago. La planilla sigue en días y montos.

### D8 — Reportes/PDF/Excel: sin código nuevo; se encienden solos

- **Decisión:** no se agrega tarjeta, sección ni columna. El getter `harvests` ya alimenta pantalla, PDF y Excel; la tarjeta «Vendido vs cosechado» se enciende porque `hasIndependentHarvest` ve una cosecha que **no** empieza por `der_venta_`. La regla 6 se activa sola. No se toca W1-c ni la planilla.
- **Alternativa descartada:** una tarjeta nueva de «pérdida en campo» (el renglón de mismatch ya la insinúa); una columna de kg en la planilla (mezcla nómina con cosecha y no se pidió).
- **Por qué:** el dato ya tiene destino y una sola fuente de verdad. **Efecto esperado, no bug:** el costo/kg y el rendimiento cambian porque el denominador de kg cosechados ahora incluye el jornal; el costo de recogida por kg también, porque el denominador crece. Se documenta en G10.

### D9 — Persistencia y sync: columna nueva + payload + lectura remota

- **Decisión:** `transactions.harvested_kg numeric` en Supabase; `buildTransactionPayload` la envía; `_rowToTransaction` la lee; `Transaction.toJson/fromJson` la serializa para LocalStore y respaldo. Migración idempotente, aplicar **antes** de desplegar. Sin backfill.
- **Alternativa descartada:** guardar solo local (el pull/merge pisaría el dato en otro equipo); reutilizar `description` o `deductionQty` (semántica falsa).
- **Por qué:** el dato debe sobrevivir sync y respaldo. Los respaldos viejos sin la clave cargan `null` y se comportan como siempre.

### D10 — Identidad de la fuente: prefijo propio

- **Decisión:** `kJornalDerivedPrefix = 'der_jornal_'`, helper `isJornalDerivedHarvest()`. `isSaleDerivedHarvest` sigue devolviendo `false` para el jornal; `hasIndependentHarvest` no cambia.
- **Alternativa descartada:** un prefijo genérico `der_` (pierde la fuente y la prioridad); marcar la derivada como «manual» (rompería D2 y el conteo).
- **Por qué:** D4 del plan lo dejó así a propósito; el test `der_jornal_v1` ya simula este contrato (`derived_harvests_test.dart:296-308`).

### D11 — Un jornal medido, una cosecha derivada

- **Decisión:** una fila `der_jornal_<transactionId>` por cada jornal con kilos, no una suma por cultivo/día.
- **Alternativa descartada:** agregar por cultivo y fecha (pierde trazabilidad; borrar un jornal no se refleja con precisión).
- **Por qué:** la suma la hacen los reportes; cada fila conserva su fecha y su origen, y editar/borrar un jornal solo afecta su fila.

### D12 — Edición: lo oculto no se guarda

- **Decisión:** al abrir un jornal con kilos, el campo se restaura. Si se cambia la labor fuera de «Cosechar» o se quita el cultivo, el valor se limpia y se guarda `null`.
- **Alternativa descartada:** conservar el valor oculto para restaurarlo si vuelve a «Cosechar» (el agricultor no ve lo que se guarda; riesgo de dato viejo).
- **Por qué:** mismo patrón que `task`/`quantity` en la venta: si el campo se oculta, no se guarda.

### D13 — Copy ES/EN (aprobado en Q4)

- **Decisión:** nuevas claves en `app_es.arb` y `app_en.arb`:
  - `jornalHarvestedKgLabel`: «Kilos recolectados (opcional)» / “Harvested kilos (optional)”.
  - `jornalHarvestedKgHint`: «Para comparar lo cosechado con lo vendido.» / “To compare what you harvested with what you sold.”
  - `jornalHarvestedKgInvalid`: «Ingresa los kilos recolectados (mayor que 0).» / “Enter the harvested kilos (greater than 0).”
  - `jornalHarvestedKgNeedsCrop`: «Elegí el cultivo para anotar los kilos.» / “Select the crop to record the kilos.”
  - Después: `flutter gen-l10n`.
- **Alternativa descartada:** reutilizar la etiqueta de cantidad de la venta (habla de kilos vendidos, no recolectados); texto solo en español (rompe EN).
- **Por qué:** copy específico, bilingüe y sin bodega.

### D14 — Constante para la tecla de labor

- **Decisión:** agregar `const String kTaskCosechar = 'cosechar';` en `tasks.dart` y usarla en el catálogo y en la condición del campo.
- **Alternativa descartada:** repetir el literal `'cosechar'` en `register_screen.dart` y `derived_harvests.dart`.
- **Por qué:** una sola tecla, un solo lugar; evita que un cambio de tecla deje la derivación muda.

### D15 — Destino de la cosecha derivada: `vendido`

- **Decisión:** `destination = HarvestDestination.vendido`.
- **Alternativa descartada:** `perdida` (la regla 6 la ignora y la tarjeta no la sumaría); `almacenado` (viola el dominio y el copy).
- **Por qué:** el dominio asume que todo lo cosechado se vende; la diferencia con la venta es la **pérdida en campo**, que se lee como delta, no como destino. No se toca el enum ni el copy de bodega.

---

## Criterios de aceptación (A)

> Verificables a mano o con test. Los números son ejemplos concretos.

- **A1 — Deriva una cosecha.** Dado un gasto `mano_obra`, labor `cosechar`, cultivo `c1`, fecha 2026-10-19, 2 días × COP 50.000 y 120 kg, cuando se lee `harvests`, entonces existe una fila `der_jornal_<id>` con `cropId = c1`, `amount = 120`, `unit = 'kg'`, `destination = vendido`, `pendingSync = false`, `date = 2026-10-19`.
- **A2 — Sin kilos no deriva.** Dado el mismo jornal con `harvestedKg = null`, entonces no hay fila `der_jornal_*`; el jornal sigue con `amount = 100.000`, `quantity = 2`, `unit = 'día'`.
- **A3 — Labor distinta no deriva.** Dado un jornal con labor `abonar` y `harvestedKg = 120` (dato importado o legado), entonces no hay fila `der_jornal_*`.
- **A4 — Sin cultivo no hay campo ni cosecha.** Dado un jornal con `cropId = null` o con un terreno seleccionado, en la pantalla no aparece el campo; al guardar, `harvestedKg = null`; no hay fila `der_jornal_*`.
- **A5 — Manda lo manual.** Dado un cultivo con una cosecha guardada a mano y un jornal con kilos, entonces `harvests` contiene la manual y **no** la del jornal ni la de la venta.
- **A6 — Jornal por encima de la venta.** Dado un cultivo sin cosecha manual, con una venta de 480 kg y un jornal de 500 kg, entonces `harvests` contiene la del jornal (500) y **no** la de la venta; `soldVsHarvested` devuelve `soldKg = 480`, `harvestedKg = 500`; la tarjeta se muestra.
- **A7 — Borrado.** Dado un jornal con kilos, cuando se marca `deleted = true`, entonces la siguiente lectura no incluye su cosecha derivada; no queda fila que borrar en `_harvests` ni en sync.
- **A8 — Cambio de labor limpia.** Dado un jornal con kilos, cuando se cambia la labor a `abonar` y se guarda, entonces `harvestedKg = null` y no se deriva.
- **A9 — Validación.** Dado el formulario con `0`, `-5` o texto no numérico, cuando se intenta guardar, entonces se muestra `jornalHarvestedKgInvalid` y no se guarda el jornal. Con vacío, se guarda `null` y el jornal es válido.
- **A10 — Pago intacto.** Dado un jornal de 2 días × COP 50.000 con 120 kg, entonces `amount = COP 100.000`, `quantity = 2`, `unit = 'día'`; `payroll()` suma 2 días y COP 100.000; `workSheetRows()` suma 2 días y COP 100.000.
- **A11 — Tres pintadores.** Dado un jornal con kilos en el período, entonces la tarjeta se ve en pantalla, PDF y Excel; los tres muestran `harvestedKg = 500` y `soldKg = 480`; la diferencia entre los tres es 0.
- **A12 — Solo venta sigue oculta.** Dado un cultivo sin jornal con kilos ni cosecha manual, con una venta de 480 kg, entonces la tarjeta no se muestra y la regla 6 no emite alerta (`harvestedKg` independiente = 0).
- **A13 — Serialización y respaldo.** Dado un JSON de transacción sin `harvested_kg`, cuando se carga, entonces `harvestedKg = null`; dado un JSON con `harvested_kg: 120.5`, entonces se conserva 120.5; el round-trip `toJson`/`fromJson` es idéntico.
- **A14 — Sync.** Dado un jornal con 500 kg, cuando se sube y se baja de Supabase (con la migración aplicada), entonces `harvestedKg = 500`; la fila `der_jornal_*` no se sube (`storedHarvests` no la contiene).
- **A15 — Efecto en métricas.** Dado un cultivo de 1 ha con un jornal de 500 kg, cuando se calcula `yieldPerArea`, entonces el denominador incluye 500 kg y `totalCostPerKg` baja en consecuencia. Es cálculo esperado, no regresión.

---

## Guardas y regresiones (G)

- **G1 — Gate base:** `flutter analyze` sin issues y `flutter test` en verde.
- **G2 — Venta intacta:** para cultivos sin jornal con kilos, las cosechas derivadas de la venta son idénticas a las de antes (tests existentes de `derived_harvests`).
- **G3 — D2 intacta:** una cosecha manual sigue mandando sobre jornal y venta.
- **G4 — Nada derivado se persiste:** `storedHarvests` sigue siendo solo `_harvests`; sync y respaldo nunca suben `der_jornal_*`.
- **G5 — Sin zombies:** `mergeRemoteHarvests` no puede revivir una `der_jornal_*` porque no existe en disco.
- **G6 — Nómina intacta:** `payroll()` y `workSheetRows()` siguen sumando `quantity` como días y el mismo `amount` para todos los jornales existentes.
- **G7 — Pantallas cerradas:** `HarvestScreen`, el menú «Cosechas» y `HarvestDestination.almacenado` no se tocan; ningún copy nuevo menciona bodega.
- **G8 — D5 intacta:** la tarjeta «Vendido vs cosechado» sigue oculta cuando la única fuente es la venta y se enciende con jornal o manual.
- **G9 — Moneda intacta:** los kilos no llevan moneda ni se suman con dinero; los tests de moneda mixta no cambian.
- **G10 — Costo de recogida:** el numerador de `pickupCostPerKg` no cambia; el denominador crece solo por los kg añadidos. El jornal **no** se enlaza con `harvestId`, así que no se duplica como gasto de recogida.
- **G11 — Datos viejos:** transacciones y respaldos sin `harvested_kg` cargan `null` sin crash.
- **G12 — «Otra…» no enciende el campo:** texto libre que diga «cosechar» no muestra el campo ni deriva.
- **G13 — Lote no enciende el campo:** cambiar el cultivo a un terreno oculta el campo y guarda `null`.
- **G14 — Cultivo borrado:** un jornal con kilos de un cultivo borrado no rompe la lectura; se comporta como hoy con las ventas de cultivos borrados.

---

## Impacto por archivo

| Archivo | Cambio esperado | Riesgo |
|---|---|---|
| `lib/models/transaction.dart` | Campo `double? harvestedKg`; constructor; `copyWith` con centinela para poder limpiar; `toJson` (`harvested_kg`); `fromJson` (clave ausente → `null`). | Medio |
| `lib/models/tasks.dart` | `const String kTaskCosechar = 'cosechar'`; el catálogo usa la constante. | Bajo |
| `lib/services/derived_harvests.dart` | `kJornalDerivedPrefix = 'der_jornal_'`; `isJornalDerivedHarvest()`; segunda fuente en `deriveHarvests`; prioridad manual > jornal > venta; actualizar el comentario de diseño (L46-62). | **Alto** (regla central) |
| `lib/providers/transaction_provider.dart` | Nuevo parámetro opcional `harvestedKg` en `addTransaction`; pasarlo al `Transaction`. `harvests`/`storedHarvests` no cambian de forma. | Medio |
| `lib/screens/register_screen.dart` | Controlador de kilos; restaurar en `initState`; campo condicional después de la labor; limpiar al ocultar; guardar `null` fuera del caso; validación `> 0`; pasar el valor en alta y edición. | Medio-alto |
| `lib/providers/sync_provider.dart` | `buildTransactionPayload` envía `harvested_kg`; `_rowToTransaction` lo lee. No tocar el uso de `storedHarvests`. | **Alto** si se olvida (pérdida en pull) |
| `supabase/migrations/{timestamp}_add_transaction_harvested_kg.sql` | `alter table public.transactions add column if not exists harvested_kg numeric;` con aviso de orden (aplicar antes de desplegar). | **Alto** (PGRST204) |
| `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/l10n/generated/*` | Claves nuevas de D13; `flutter gen-l10n`. | Bajo |
| `test/derived_harvests_test.dart` | Reemplazar la simulación `der_jornal_v1` por casos reales: con kilos, sin kilos, labor distinta, sin cultivo, borrado, manual manda, jornal suprime venta, varios jornales, prefijo/independencia. | **Alto valor** |
| `test/register_screen_test.dart` | Visibilidad por labor/cultivo, validación, guardado `null`, restauración al editar. | Medio |
| `test/transaction_test.dart` | Round-trip `toJson`/`fromJson` con y sin `harvested_kg`. | Bajo |
| `test/backup_*`, `test/transaction_provider_test.dart` | Respaldo viejo sin clave; fase promovida por jornal; `storedHarvests` sin derivadas. | Medio |
| `lib/services/report_harvest_metrics.dart` | **Sin cambio de código.** El denominador de kg cosechados incluye el jornal; costo/kg y rendimiento cambian por datos. | Bajo (efecto esperado) |
| `lib/screens/report_screen.dart`, `lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart` | **Sin cambio de código.** La tarjeta se enciende por `hasIndependentHarvest`; verificar que los tres den el mismo número. | Bajo |
| `lib/services/alert_service.dart` | **Sin cambio de código.** La regla 6 se activa cuando hay jornal con kilos; no se cambia copy ni umbral sin Q5. | Bajo |
| `lib/services/report_payroll_metrics.dart` | **Sin cambio de código.** Sigue usando `quantity` como días; ignora `harvestedKg`. | Bajo |
| `lib/screens/harvest_screen.dart`, `lib/screens/home_screen.dart` | **No se tocan.** | — |

---

## Preguntas resueltas (2026-10-19)

> Las siete se resolvieron con la recomendación del PRD. Se conserva el razonamiento de cada una.

| # | Pregunta | Decisión |
|---|---|---|
| Q1 | ¿Dónde vive el dato? | Campo `harvestedKg` en `Transaction` + columna `harvested_kg` en Supabase. |
| Q2 | ¿Cómo conviven jornal y venta? | `manual > jornal > venta`, por cultivo. |
| Q3 | ¿Jornal sin cultivo? | Ocultar el campo, guardar `null`, no derivar. |
| Q4 | ¿Copy? | Aprobados los cuatro textos ES/EN de D13. |
| Q5 | ¿Regla 6? | Sin cambios: mismo umbral (10%) y mismo copy. |
| Q6 | ¿Unidad? | Solo kg. |
| Q7 | ¿Planilla? | No se toca; sigue en días y montos. |

1. **¿Dónde vive el dato?**
   - **Recomendación:** campo nullable `harvestedKg` en `Transaction` + columna `harvested_kg` en Supabase.
   - **Por qué:** una sola fila; editar/borrar el jornal corrige la cosecha sola; no hay cosecha zombi ni doble costo de recogida. **Costo:** una migración y su payload.
   - **Alternativa:** guardar una fila `Harvest` y enlazarla con `harvestId` (más piezas, riesgo de zombie y de duplicar `pickupCostPerKg`).

2. **¿Cómo conviven jornal y venta?**
   - **Recomendación:** `manual > jornal > venta`, **por cultivo**. Si hay al menos un jornal medido, la venta no deriva para ese cultivo.
   - **Por qué:** evita el doble conteo. **Costo:** si solo mide algunos jornales, la venta no rellena los días no medidos.
   - **Alternativas:** sumar jornal + venta (infla la cosecha); priorizar por fecha (una venta días después duplica); priorizar por mes (una venta que cruza de mes duplica).

3. **¿Y si el jornal no tiene cultivo?**
   - **Recomendación:** ocultar el campo y guardar `null`; no derivar una cosecha «Sin cultivo».
   - **Por qué:** sin atribución no hay rendimiento/ha, kg/planta ni comparación por cultivo; nunca inventar.
   - **Alternativa:** derivar con `cropId = null` (aparece en «Sin cultivo» y no alimenta las métricas del cultivo).

4. **¿Copy y visibilidad?**
   - **Recomendación:** etiqueta «Kilos recolectados (opcional)»; hint «Para comparar lo cosechado con lo vendido.»; y cuando la labor es «Cosechar» pero no hay cultivo, «Elegí el cultivo para anotar los kilos.» (ES/EN, D13).
   - **Por qué:** sin el hint, el campo no aparece y el agricultor no sabe por qué. **¿Aprobás estos textos?**
   - **Alternativa:** ocultar sin explicación (menos copy, menos descubrible).

5. **¿Qué hacemos con la regla 6?**
   - **Recomendación:** dejarla activarse **sin cambiar copy ni umbral** (10%).
   - **Por qué:** es el objetivo de la medida independiente. **Riesgo:** si el jornal mide solo una parte de la cosecha, la alerta puede saltar; el texto ya sugiere revisar si faltó registrar una cosecha.
   - **Alternativa:** ajustar el umbral o el copy ahora (pediría otra decisión y otro PRD de textos).

6. **¿La unidad es siempre kg?**
   - **Recomendación:** sí, solo kg en Tanda 2.
   - **Por qué:** el pedido es «kilos recolectados»; agregar arrobas/sacos requiere otro campo, otro selector y otra validación.
   - **Alternativa:** `cantidad + unidad` como en la venta (más UI y más superficie de error). **¿Medís en otra unidad?**

7. **¿Tocamos la planilla?**
   - **Recomendación:** no. La planilla sigue en días y montos; los kg se ven en la tarjeta y en el reporte.
   - **Por qué:** no reabrir el jornal ni mezclar nómina con cosecha.
   - **Alternativa:** agregar una columna de kg a la planilla (sería otro alcance y otro copy).

---

## Risks

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Doble conteo jornal + venta | Media | Alto | D3: prioridad por cultivo; tests A6 y G2. |
| Subconteo si solo se miden algunos jornales | Media | Medio | Copy/hint; el usuario decide; nunca se inventa el resto. |
| Alerta de regla 6 salta por medición parcial | Media | Medio | Aviso en Q5; el usuario decide umbral/copy. |
| Migración no aplicada antes del deploy | Media | Alto | Archivo de migración idempotente + orden documentado + gate de deploy. |
| Pérdida del dato en pull/merge | Baja | Alto | Payload + `_rowToTransaction` + test A14. |
| Valor oculto guardado por cambio de labor/cultivo | Media | Medio | Limpiar al ocultar y guardar `null`; tests A4/A8/G12/G13. |
| Usuario mide en arrobas/sacos y escribe ese número como kg | Media | Medio | Etiqueta «Kilos»; Q6; no se convierte nada. |
| Métricas de costo/kg y rendimiento cambian | Alta | Medio | Es el efecto esperado; documentarlo en A15/G10 y no fijar tests con valores viejos donde haya jornal medido. |
| «Otra…» con texto «cosechar» no enciende el campo | Baja | Bajo | D4/G12; el hint puede decirlo si se aprueba Q4. |
| Cultivo borrado con jornal medido | Baja | Bajo | G14; mismo comportamiento que las ventas de cultivos borrados. |

---

## Delivery Milestones

| # | Milestone | Outcome | Status | Plan |
|---|---|---|---|---|
| 1 | Campo y modelo | El agricultor puede anotar kilos en un jornal de «Cosechar» y el dato sobrevive guardar, reabrir y respaldo. Reportes todavía no cambian. | pending | — |
| 2 | Derivación y prioridad | `harvests` incluye la fuente del jornal; la venta deja de derivar para ese cultivo; manual sigue mandando. Tests puros en verde. | pending | — |
| 3 | Reportes y alertas | La tarjeta «Vendido vs cosechado» y la regla 6 se encienden con la fuente del jornal, y pantalla/PDF/Excel coinciden. | pending | — |
| 4 | Sync y migración | El dato viaja a Supabase y vuelve; las derivadas no se suben; respaldos viejos cargan `null`. | pending | — |

---

## Status

**APPROVED — requirements only.** El usuario aprobó D1-D15 y resolvió Q1-Q7 el 2026-10-19. Siguiente paso: plan de implementación. No hay cambios de código hasta que ese plan exista y pase el gate.
