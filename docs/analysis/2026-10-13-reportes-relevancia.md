# Reportes · análisis de relevancia (2026-10-13)

> Estado: **ANÁLISIS, sin implementar.** Queda pendiente de decisión.
> Manda sobre todo lo demás lo que diga el usuario al retomar.

## Encargo

Analizar la información que muestran los Reportes y ver cuál es **realmente
relevante** mostrar, teniendo en cuenta la funcionalidad y finalidad de la app
y lo que espera un agricultor con experiencia en el manejo real de su
producción, ventas y gastos.

## Qué se revisó

Los tres pintadores (pantalla, PDF, Excel) y los servicios de métricas:
`lib/screens/report_screen.dart`, `lib/services/report_harvest_metrics.dart`,
`lib/services/report_insights_service.dart`,
`lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart`.

---

## 1. Qué muestran hoy

Selector de periodo (Semana / Mes / Año a la fecha) y ocho bloques:

| Bloque | Contenido |
|---|---|
| Conclusión del periodo | utilidad, margen %, comparación con el mes anterior, mayor gasto, mejor ingreso, precio bajo vs histórico, mejor mes |
| Siembras | ¿qué tengo plantado hoy?, total plantado, pérdidas acumuladas, siembras del periodo, resiembras |
| Cosechas | kg por cultivo (normalizado), por destino, costo de recogida/kg, costo total/kg, inversión acumulada, kg/ha, kg/planta, personal y kilos |
| Nómina | trabajador, días, subtotal, total, empleados distintos |
| Caja | saldo vs presupuesto |
| Vendido vs cosechado | kg vendidos y cosechados por cultivo, con alerta si lo vendido supera lo cosechado |
| Qué hacer | recomendaciones |

### Lo que ya está bien y el productor lo usa

- La **utilidad y el margen del periodo** — el número que manda.
- El **costo total por kg** — la métrica clásica del café.
- El **veredicto precio vs costo** (`costPriceVerdict`).
- El rendimiento **kg/ha**.
- **"Vendido vs cosechado"** con su alerta: detecta registros mal anotados,
  que en la finca pasan seguido.

---

## 2. Hallazgo importante: métricas calculadas que nadie ve

En `report_harvest_metrics.dart` existen cinco funciones que **no se pintan en
ningún sitio** — ni pantalla, ni PDF, ni Excel:

| Métrica | Qué responde |
|---|---|
| `revenuePerHa` | ingreso por hectárea |
| `costPerHa` | costo por hectárea |
| `marginPerHa` | **margen por hectárea** |
| `recoveryRate` | cuánto de la inversión ya recuperaste |
| `breakevenYears` | en cuántos años se paga |

Son justamente las cifras que responden *"¿este lote me conviene?"*. El código
ya existe; solo falta **decidir** pintarlo o borrarlo. Hoy es código muerto que
promete.

---

## 3. Lo que falta y vale la pena

1. **Margen bruto por kg = precio − costo/kg.** Hoy se muestran por separado y
   hay un veredicto en palabras, pero no el número. En el campo se piensa así:
   *"me lo pagaron a 4.500 y me costó 3.200 → 1.300 de margen"*. Es el
   indicador que decide si el lote conviene.
2. **Precio promedio de venta por kg, como cifra principal.** Ya se calcula
   (`avgSalePricePerKg`) pero no aparece como titular; solo alimenta el
   veredicto. Es el precio que el productor cotiza con el comprador.
3. **Mano de obra como porcentaje del gasto.** Se muestra el total de la
   nómina, no su peso relativo. Ver *"nómina = 46% de tus gastos"* es lo que
   hace decidir si se contrata o no.
4. **Gasto, ingreso y utilidad por lote.** Hoy el mayor gasto sale por
   **categoría** (fertilizante, transporte), no por **lote**. Quien maneja
   varios lotes necesita compararlos para decidir dónde invertir.
5. **Ventas por cobrar.** E1 ya registra si la plata entró o no, y eso **no
   aparece en Reportes**. "Vendido pero sin cobrar" es caja que falta.
6. **Inversión acumulada contra utilidad acumulada del lote.** Hoy hay
   "inversión acumulada" pero no se le enfrenta a lo que el lote ya devolvió.

---

## 4. Lo que sobra o debería aminorarse

- **"Mejor mes del año y menor gasto mensual"** en un reporte de periodo
  concreto: mezcla dos conclusiones en una frase que no es accionable. Tiene
  más sentido solo en *Año a la fecha*.
- **Rendimiento por planta**: ruidoso si el número de plantas es aproximado —
  la propia app ya lo marca *"(aproximado)"*. Con kg/ha basta.
- **Demasiadas cifras apiladas sin jerarquía**: todo sale como texto en
  tarjetas, y lo que decide se pierde entre lo que solo informa.

---

## 5. Advertencia sobre `breakevenYears`

Calcula **años** a partir de un margen promedio anual. Eso es anualizar y choca
con la regla del proyecto de no inventar proyecciones. Si se pinta, mejor como
**"recuperación de la inversión"** (porcentaje ya recuperado) sin prometer
cuándo se termina de pagar.

---

## 6. Efecto de la moneda única (commit `4518971`)

Con la moneda única, todos estos cálculos dejan de tener los huecos de
*"se muestra en 2 monedas"* y los insights del periodo ya no se apagan. Es la
base para que todo lo anterior funcione siempre.

**Deuda abierta**: los tres pintadores tienen huecos **distintos** entre sí —
hay métricas que van en Excel y no en PDF, y las de rentabilidad no van en
ninguno. La regla del proyecto es que los tres digan lo mismo.

---

## 7. Estructura propuesta (de lo que decide a lo que informa)

1. **El veredicto** — utilidad y margen %, precio/kg vs costo/kg → **margen por
   kg**, comparación con el periodo anterior.
2. **Producción** (si hay cosecha) — kg cosechado y vendido por lote, vendido
   vs cosechado, costo total/kg, kg/ha.
3. **Costos** — mano de obra con su % del gasto, mayor gasto por categoría,
   **gasto por lote**, caja vs presupuesto.
4. **El lote como negocio** (nuevo, solo con datos) — inversión acumulada,
   ingreso acumulado, utilidad acumulada, recuperación de la inversión.
5. **Pendiente por cobrar** (si hay).

---

---

# Segunda parte · impacto en decisiones y diferenciación

## 8. El principio que ordena el reporte

Un reporte no es información: es **apoyo a una decisión**. Si un dato no cambia
ninguna decisión de este mes, no va arriba — va al detalle. Esa regla explica
por sí sola la mayor parte de lo que hoy sobra y de lo que falta.

## 9. Decisiones reales del caficultor y el dato que las resuelve

| Decisión que toma | Dato que la resuelve | Estado hoy |
|---|---|---|
| ¿Sigo con este lote o lo arraso? | utilidad acumulada del lote · costo/kg vs precio/kg | falta |
| ¿Vendo ahora o espero? | su precio promedio/kg contra **su propio histórico** | existe pero no como cifra principal |
| ¿Contrato recolección o con la familia? | mano de obra como **% del gasto** · costo recogida/kg | total sí, proporción no |
| ¿Cuánto puedo gastar este mes? | caja vs presupuesto · **ventas por cobrar** | falta el por cobrar |
| ¿Dónde invierto el próximo ciclo? | gasto, ingreso y utilidad **por lote** · kg/ha por lote | falta |
| ¿Ya recuperé lo que metí? | recuperación de la inversión (% ya recuperado) | calculado y **no pintado** |
| ¿Están bien mis números? | vendido vs cosechado | está |

Solo una de las siete decisiones está bien servida hoy.

## 10. El veredicto, no el tablero

Lo primero que debe verse son **tres cifras y una frase**:

```
Precio promedio      Costo total        MARGEN
   $4.500/kg           $3.200/kg        $1.300/kg

Cada kilo te dejó $1.300. Frente a septiembre (mismos días): mejoró $200.
```

Por qué así:

- El **margen por kg es el número que decide**: *"me lo pagaron a 4.500 y me
  costó 3.200"*. Hoy esas dos cifras existen y se enfrentan solo con palabras.
- **Tres cifras compiten; veinte no compiten.** La pantalla actual apila todo
  con el mismo peso y lo que decide se pierde.
- **Si falta un lado, no se pinta** (null → oculto, nunca 0): sin ventas o sin
  costo del periodo la tarjeta no aparece.
- **Compara contra su propio historial, nunca contra un promedio externo.**

## 11. El "plus" frente a apps similares

Mercado revisado: **A · ERP de operación** (Agrivi, Granular, Agrinco) —
inventarios, tratamientos, certificaciones, pensados para operaciones medianas
y grandes. **B · libro de gastos** (Farmslip, AgriCost, MoneyAgro) — registran
muy bien pero son contables, no de decisión.

Honestidad de partida: **MoneyAgro ya anuncia costos por lote y cuentas por
cobrar**, así que esos dos indicadores no son exclusivos de esta app y no
conviene venderlos como innovación.

El plus real no es un indicador, es la **estructura**:

1. **Atado al ciclo real del café** (siembra → fase → cosecha → destino →
   venta). Un libro de gastos no calcula costo/kg ni margen/kg porque no tiene
   kilos; aquí están enlazados. Ahí nace la métrica más fuerte.
2. **La regla de no inventar cifras.** Nadie de la lista compara contra el
   historial propio con esa disciplina: el resto mete rendimiento potencial,
   benchmarks o promedios de institución. Decir *"vendiste 12% menos caro que
   tu propio promedio"* en vez de *"estás bajo el promedio nacional"* es más
   ético **y** más útil: la finca de él no es la finca promedio.
3. **Integridad de datos como funcionalidad.** El aviso de *"me anotaste más
   kilos de los que cosechaste"* no lo da ningún competidor de la lista.
4. **Mismo reporte en pantalla, PDF y Excel.** Vale para pedir crédito en el
   banco o negociar con el comprador.
5. **Moneda única y sin conexión**: los totales suman exacto en la finca.

## 12. Lo que NO hacer para "ser mejor"

- No copiar el ERP: inventario, tratamientos, trazabilidad de certificación —
  no es el usuario.
- No meter benchmarks institucionales: rompe la regla de oro y desacredita el
  resto del reporte.
- No anualizar ni proyectar: `breakevenYears` es exactamente eso.
- No añadir indicadores porque la competencia los tenga. Cada cifra nueva
  compite por la atención en una pantalla ya llena; es lo que convierte un
  reporte de decisión en un reporte de almacén.

## 13. Orden de ejecución recomendado

1. **El veredicto** (margen/kg + precio/kg + comparación) — impacto inmediato,
   riesgo bajo, los datos ya están.
2. **Gasto, ingreso y utilidad por lote** — el diferenciador real frente a
   ambos campamentos.
3. **Por cobrar + mano de obra como %** — flujo de caja.
4. **Recuperación de la inversión** en % recuperado, sin anualizar.
5. **Los cinco metrics sin pintar**: pintar los que encajen, borrar los que no.

## 14. Lo que sobra hoy, confirmado con la regla del 1

- *"Tu mejor mes fue X; tu menor gasto mensual fue Y"* — dos conclusiones en
  una frase, ninguna accionable; solo tiene sentido en *Año a la fecha*.
- **Rendimiento por planta** cuando la app misma lo marca *"(aproximado)"*.
- El reporte debería **encogerse** cuando no hay datos, no rellenarse con
  vacíos.

**Recomendación en una frase:** no competir en cantidad de indicadores, sino
en que el reporte responda en cinco segundos si un lote conviene, con cifras
que el agricultor ya sabe leer y sin decirle nunca cómo debería irle.

---

## Decisiones pendientes del usuario

- [ ] Los cinco metrics sin pintar (`marginPerHa`, `recoveryRate`,
      `breakevenYears`, `revenuePerHa`, `costPerHa`): **¿pintar o borrar?**
- [ ] **Por dónde empezar**: ¿Nivel 1 (el veredicto: margen/kg + precio/kg
      + comparación) o Nivel 4 (el lote como negocio: gasto/ingreso/utilidad
      por lote)?
