# Lectura del rendimiento y cultivos asociados

> Notas para decidir más adelante. **No es un PRD ni una decisión tomada.**
> Nacen de dos preguntas del 2026-10-20: cómo leer el kg por planta cuando hay
> resiembra, y cómo se cosecha un terreno de 8 ha con café, plátano, palta y
> maíz. Nada de esto se implementó.

## 1. Kilos por cultivo, no por mata

Lo que la app hace hoy:

- `Harvest` tiene `cropId` y **no** tiene `sowingId`: los kilos son del cultivo.
- Si no se midió en el jornal, la venta deriva la cosecha (`deriveHarvests`).
  Prioridad: cosecha a mano > kilos del jornal > kilos de la venta.
- `yieldPerPlant` = kg totales ÷ **todas** las plantas vivas del cultivo
  (`report_harvest_metrics.dart`). `yieldPerArea` = kg ÷ `areaHa`.
- `hasResiembra` marca el indicador como aproximado.
- Una **resiembra** no reinicia la edad ni cambia el divisor si se anotan las
  muertas y las nuevas (`recomputeCropState`: vivas − muertas + nuevas).
  Una **siembra** sí reinicia edad y reemplaza plantas y área.

Cómo lo lee el agricultor (acordado en la conversación):

- «Rindo X kg por mata **en promedio en este cultivo**», no «mis matas de 5
  años rinden X».
- Reponer 20 muertas con 20 nuevas deja el divisor igual: 500 kg / 1.000 =
  0,50 kg/mata.
- Anotar las nuevas **sin** las muertas diluye (1.020 → 0,49): es un dato
  faltante, no un error de la app.
- Sumar 200 plantines a 1.000 matas (expansión, no reposición) baja el
  promedio hasta que produzcan. Es real, pero mezcla dos edades.

Huecos anotados para más adelante:

- [ ] Cohortes dentro de un cultivo (matas viejas vs. plantines nuevos).
- [ ] Atribuir una cosecha a una siembra/cohorte (`sowingId` en `Harvest`).
- [ ] Mostrar el kg/planta con y sin las plantas que aún no producen.
- [ ] Empujar a anotar muertas y nuevas juntas en la resiembra (hoy se puede
      anotar solo una de las dos y el promedio se ensucia en silencio).
- [ ] Renovación completa: hoy solo se representa como siembra nueva, y eso
      borra la historia de edad del lote viejo.

> Análisis de estos ítems (2026-10-20):
> `2026-10-20_cohortes-dentro-de-un-cultivo.md`. Recomienda partir el lote en
> dos cultivos (E); cohortes dentro del cultivo queda como alternativa.

## 2. Cultivos asociados en el mismo terreno

Caso: un terreno de 8 ha con café, plátano, palta y maíz.

En la práctica real:

- **Se cosecha por producto y por pase**, no «las 8 ha» de una vez.
  - Café: pases selectivos cada 15–20 días en pico; se mide cereza y después
    de beneficio queda pergamino seco. Unidades: kg, arroba, carga, saco.
  - Plátano: corte de racimos cada 7–15 días por planta; se vende por racimo,
    caja o kg.
  - Palta: campaña (uno o dos pases según variedad); kg o caja.
  - Maíz: ciclo anual, una cosecha; mazorca o desgranado, bulto o kg.
- El mismo día puede haber café en la mañana y plátano en la tarde: son **dos
  registros**, cada uno con su producto y su cantidad.
- La tierra y algunos costos son compartidos (limpieza, fumigación); la
  cosecha y el ingreso no.

Lo que la app permite hoy:

- Un **terreno** de 8 ha y varios cultivos apuntando a él (`Crop.terrenoId`).
- Cada cultivo con **su** `areaHa` (la que ocupa, no las 8).
- Cosecha/jornal **por cultivo**, tantas veces como pases haya.
- Unidades: kg, lb, arroba, saco, carga, racimo (con kg equivalente), cajón.
- Un gasto compartido se puede cargar al terreno sin cultivo
  (`Transaction.terrenoId` con `cropId` nulo).

Lo que **no** hace:

- No reparte automáticamente un gasto compartido entre cultivos, así que ese
  gasto no entra al costo por kilo de ningún producto.
- No modela el asocio (sombra, densidad, ha equivalentes).
- No valida que la suma de áreas de los cultivos quepa en el terreno: si se
  ponen 8 ha en cada uno, el kg/ha sale cuatro veces mal.
- `cajón` **y `racimo`** no tienen conversión: `unitToKg` los trata como 1 kg.
  En el racimo, el peso se guarda en `equivalentKg` y se muestra («12 racimos
  ≈ 240 kg»), pero **no entra a ningún total**: kg/ha, kg/planta, costo por
  kilo y PDF/Excel suman 12 kg. En la venta pasa lo mismo: 10 cajones = 10 kg.
  Un cajón de cereza tampoco pesa 1 kg.

Ejemplo concreto del caso de 8 ha:

- Terreno «Finca» = 8 ha. Café 5 ha · plátano 1,5 ha · palta 1 ha · maíz 0,5 ha.
- Un martes se recogen 300 kg de café en la mañana y 12 racimos de plátano en
  la tarde: **dos registros**, uno por cultivo.
- La fumigación de todo el terreno va como gasto del terreno (sin cultivo), o
  se reparte a mano si se quiere ver en el costo por kilo.

Ideas para más adelante (sin orden ni compromiso):

- [ ] Prorratear gastos del terreno por área o por cultivo, con opción manual.
- [ ] Advertir si la suma de `areaHa` de los cultivos supera el área del
      terreno.
- [ ] Conversión configurable para `cajón` (y revisar si `racimo` necesita
      peso por defecto además del `equivalentKg` por cosecha).
- [ ] Relación explícita de asocio entre cultivos (para no contarlos como
      áreas independientes).
- [ ] Cosecha por pase con fecha y responsable, sin mezclar productos.

## 3. Caja menor: presupuesto mensual y arrastre

Cómo funciona hoy (verificado en `cash_box_card.dart` y
`report_payroll_metrics.dart`):

- Ajustes tiene **un** aporte mensual de caja (`cajaMensualEfectiva`, que suma
  `cajaMenorMensual` y el viejo `presupuestoObraMensual`). Un solo pote.
- Descuentan del pote los gastos de **mano de obra** y los extras: energía,
  agua, otro, mantenimiento (`kCashBoxExtraCategories`).
- El límite del mes es **aporte + arrastre**. El arrastre se recalcula solo:
  desde el primer mes con registros hasta el mes anterior, suma
  `aporte − gastado` de cada mes.
- Un mes **sin registros** arrastra el aporte entero (no se pierde).
- Si un mes se pasó, el arrastre es negativo: el mes siguiente arranca con
  menos presupuesto (deuda), no con cero.
- Se ve en Inicio (tarjeta «Caja menor»): barra, restante y la línea
  «Lo arrastrado de meses anteriores».
- Si en un mes pasado hubo gastos en otra moneda, el arrastre no se puede
  calcular y se oculta (no se inventa un número); el límite queda en el aporte.

Límites y huecos anotados:

- [ ] **No hay presupuesto por tarea.** Las tareas se reparten según la
      necesidad y cada jornal se registra contra el cultivo que corresponda,
      pero el presupuesto es un solo pote; no se puede asignar «tanto para
      deshierbe, tanto para recolección» y vigilar cada bolsa.
- [ ] **No hay historial de aportes.** El arrastre usa el aporte **actual**
      para todos los meses pasados: si se cambia el aporte, la historia se
      recalcula con el monto nuevo. No queda registro de cuánto se asignó
      cada mes.
- [ ] El arrastre no se guarda: se recalcula en cada lectura. Es consistente,
      pero cualquier cambio de aporte reescribe el pasado.
- [ ] Los jornales se pueden repartir por cultivo (cada gasto lleva su
      cultivo), pero eso no separa el pote: todo descuenta del mismo saldo.
- [ ] Si se quiere presupuesto por tarea, hoy habría que llevarlo fuera de la
      app o usar varios «aportes» manualmente, y eso desordena el arrastre.

## 4. Lo que hay que cuidar al registrar (hoy)

- No repetir las 8 ha en cada cultivo: va el área que ocupa cada uno.
- Una cosecha por producto y por pase; nunca una cosecha «mezclada».
- Si una venta mezcla productos, partirla por cultivo para no torcer kilos ni
  ingresos.
- Un gasto compartido va al terreno (honesto, pero no entra al costo/kg) o se
  reparte a mano entre cultivos.
