# PRD — Ayuda para empezar a operar

- Fecha: 2026-10-26 20:08
- Estado: **propuesta para aprobación**. Sin cambios de código.
- Reemplaza: `lib/screens/help_screen.dart` y las cadenas `help*` del ARB.
- Referencias: Alegra (Colombia), Farmbrite (EE. UU.), Auravant (Argentina).

## 1. Problema

La Ayuda actual es un manual de referencia, no una ayuda para empezar:

- 778 líneas, 170 cadenas, 10 secciones. Unas 15 pantallas de scroll.
- Ejemplos fijos de un solo país y un solo cultivo: «café 2 ha, 3.000
  plantas», «COP 500.000», «50 kg (4 arrobas)».
- La misma ruta se repite cuatro veces: «dónde está cada cosa», «flujo»,
  casos A/B/C y «lo demás».
- No lleva a la pantalla: todo es texto, sin botón a Registrar, Cultivos o
  Reporte.
- No crea hábito: no hay rutina ni «qué sigue».
- Voz mezclada: la Ayuda dice «Entra, ponles»; la Bienvenida y los textos
  nuevos dicen «cultivás, agregás, escribí».
- El glosario usa «$100», que choca con la regla de la app: siempre el
  código de la moneda, nunca el símbolo.

## 2. Objetivo

Que una persona que abre la Ayuda por primera vez sepa, en menos de dos
minutos, **qué anotar hoy y dónde**, según el estado de su finca; y que a la
semana tenga una rutina de cuatro momentos que sostenga el reporte sola.

### Criterios de aceptación

1. La primera pantalla muestra **4 casos** de finca; cada uno se entiende en
   dos líneas.
2. Cada caso tiene **máximo 4 pasos**; cada paso dice **dónde** y **qué**.
3. Cada caso tiene **un ejemplo** con números redondos y la frase «en tu
   moneda».
4. Ningún ejemplo usa símbolo de moneda, país, ni cultivo obligatorio.
5. La pestaña **Rutina** tiene 4 momentos y 3 reglas de «no lo anotes dos
   veces».
6. El **Diccionario** tiene máximo 12 términos, en lenguaje llano, y un
   botón al glosario completo.
7. **Si algo no cuadra** cubre 6 problemas reales.
8. La Ayuda **no menciona «Cosechas» como menú**: hoy está oculto.
9. La voz es **tuteo** de principio a fin; no se mezcla con voseo.
10. La Ayuda no promete datos que la app no tiene ni inventa cifras.

## 3. Decisiones

### 3.1 Casos, no datos personales

La Ayuda **no lee la finca del usuario** ni muestra sus cifras. Muestra
casos con ejemplos. El usuario elige el suyo en la portada. La adaptación
es por situación, no por datos.

### 3.2 Voz: tuteo neutral

| Referencia | Voz | Qué aporta |
|---|---|---|
| Alegra (Colombia) | Tuteo: «Configura», «Haz clic», «tu negocio» | Pasos numerados y **rutina semanal** |
| Farmbrite (EE. UU.) | «You»: «You'll see», «What should we do next?» | Índice por capítulos y **camino libre** |
| Auravant (Argentina) | Voseo: «Creá», «Hacé», «podés» | Es regional; no sirve para «cualquier región» |

Conclusión: **tuteo neutral y frases cortas en imperativo**. El voseo de la
Bienvenida y de **23 cadenas** se corrige en este mismo cambio, para que la
Ayuda y la app hablen igual. La lista está en §9.

### 3.3 Moneda global

Los ejemplos dicen «500 en tu moneda» y «50 kg por 750». Nunca «$», «COP» ni
un país. El texto explica una vez que la app muestra el **código** de la
moneda y que no suma monedas distintas. La moneda de la cuenta se elige al
empezar y no se cambia; la de los reportes sí, sin alterar lo ya registrado.

### 3.4 Reemplazar las 10 secciones

La Ayuda nueva sustituye el manual. El glosario y las unidades se integran
en «Entender». No queda una pestaña «Referencia» con el texto viejo.

## 4. Estructura

Tres pestañas:

1. **Empezar** (por defecto): «¿Cómo está tu finca hoy?» + el caso elegido.
2. **Rutina**: los cuatro momentos y las reglas para no duplicar.
3. **Entender**: diccionario, unidades y «Si algo no cuadra».

La pestaña Empezar recuerda el caso elegido. No hay barras de progreso ni
casillas: el avance lo da el hábito, no una casilla marcada.

## 5. Texto propuesto (ES)

### 5.1 Portada · Empezar

**Aprende a operar Mi Cafetal**

Elige cómo está tu finca hoy. En cinco minutos haces el primer registro.

**¿Cómo está tu finca hoy?**

- **Ya vendo lo que cosecho** — Tienes cultivos dando fruto y quieres saber
  si ganas.
- **Voy a empezar** — Vas a sembrar y quieres ver cuánto inviertes antes de
  cosechar.
- **Voy a renovar o ampliar** — Vas a reemplazar matas o sumar área a un
  cultivo.
- **Tengo trabajadores** — Pagas jornales y quieres que el costo quede en el
  cultivo correcto.

> Los ejemplos usan números redondos y «tu moneda». Sirven igual para
> cualquier país y cualquier cultivo.

### 5.2 Caso 1 · Ya vendo lo que cosecho

No anotes lo que ya pasó. Empieza desde hoy: lo que gastes y lo que vendas.

1. **Revisa tus cultivos** — Cultivos › tu cultivo. Que la fase sea «Dando»
   y, si los sabes, el área y las matas. Si no los sabes, déjalos vacíos: la
   app no inventa.
2. **Anota el primer gasto** — Registrar › Gasto. Elige el cultivo y la
   categoría: fertilizante, mano de obra, transporte. Si el gasto es de
   varios cultivos, repártelo por área o por porcentaje.
3. **Anota la primera venta** — Registrar › Ingreso. Escribe los kilos y lo
   que te pagaron. Con esos kilos, la cosecha de ese cultivo queda
   registrada sola. No la anotes dos veces.
4. **Mira el mes** — Resumen o Reporte. Ahí ves ingresos, gastos, balance y
   costo por kilo. El reporte sale en PDF o Excel.

**Ejemplo con café, 2 ha y 3.000 matas**

- Gasto: 500 en fertilizante, asignado a café.
- Venta: 50 kg por 750.
- Resultado: ingresos 750 · gastos 500 · balance 250 · costo por kilo 10.

> Números de ejemplo, en tu moneda.

Lo que vendiste antes de usar la app no hace falta: el reporte empieza con
lo que anotes.

**Si tienes varios cultivos en el mismo terreno**, asígnalos al registrar el
gasto; la app reparte por área o por porcentaje.

### 5.3 Caso 2 · Voy a empezar

Mientras el cultivo no da fruto, la app no te dice que pierdes: te muestra
cuánto llevas invertido. Es una inversión, no un mal mes.

1. **Crea el cultivo** — Cultivos › Nuevo cultivo. Nombre, fase «Sin dar» y
   si es perenne o transitorio. El área y las matas pueden quedar vacías.
2. **Anota la siembra** — Siembras › Nueva siembra. Cuántas matas, en qué
   área y la fecha. Si anotas el costo, la app crea el gasto vinculado sola:
   no lo repitas en Registrar.
3. **Anota lo que inviertes** — Registrar › Gasto, con el cultivo.
   Fertilizante, mano de obra, herramientas. Todo lo de antes de la primera
   cosecha se ve como inversión.
4. **Cuando coseches, cambia la fase** — Cultivos › tu cultivo › fase
   «Dando». Desde ahí, la venta registra la cosecha.

**Ejemplo con maíz, 1 ha y 20.000 matas**

- Siembra: 20.000 matas en 1 ha.
- Inversión: 300 en semilla + 200 en preparación = 500.
- Antes de cosechar: inversión 500, sin pérdida.
- Primera venta: 1.000 kg por 800. La cosecha queda registrada.

> Números de ejemplo, en tu moneda.

### 5.4 Caso 3 · Voy a renovar o ampliar

No borres el cultivo viejo. La app guarda su historia y suma la parte nueva.

1. **Elige qué pasa con las matas viejas** — Siembras › Nueva siembra. Si
   reemplazas una parte, elige «Renuevo una parte» y el lote que renuevas.
   Las matas viejas bajan y las nuevas suman: el total no se infla.
2. **Si amplías, no reemplaces** — Elige «Amplío el cultivo». Sumas área y
   matas sin tocar lo que ya estaba.
3. **Mira la edad nueva** — El lote renovado arranca su propia edad. Las
   cosechas viejas siguen en el historial y en el reporte.

**Ejemplo con café de 3.000 matas; renuevas 1.000**

- Siembra: 1.000 matas nuevas, «Renuevo una parte», lote viejo.
- Total: sigue en 3.000, no en 4.000.
- El lote nuevo tiene su fecha; el viejo conserva la suya.

### 5.5 Caso 4 · Tengo trabajadores

El jornal no es un gasto suelto: va al cultivo donde trabajaron. Así el
costo por kilo dice la verdad.

1. **Guarda al trabajador** — Trabajadores › Nuevo. Nombre y pago por día.
   Si cambia el jornal, lo actualizas ahí.
2. **Anota el pago** — Registrar › Gasto › Mano de obra. Elige el
   trabajador, los días y el cultivo. La app calcula el monto; si pagaste
   otra cosa, lo ajustas.
3. **Si fue cosecha, márcalo** — En la labor elige «Cosechar», anota los
   kilos y el lote. Con eso sale el costo de recogida por kilo.
4. **Mira la nómina** — Reporte › Nómina del período. Ahí está cuántos días
   y cuánto pagaste a cada uno.

**Ejemplo con dos trabajadores a 20 por día**

- Juan: 3 días en café = 60.
- Pedro: 2 días en café = 40.
- Nómina: 5 días y 100. Si fue cosecha, los kilos van al lote.

> Números de ejemplo, en tu moneda.

### 5.6 Rutina

**La rutina que hace que la app sirva**

No necesitas llenar todo. Con estos cuatro momentos, el reporte se arma
solo.

| Cuándo | Qué anotas | Dónde |
|---|---|---|
| Cada gasto | Lo que pagaste, con su cultivo | Registrar › Gasto |
| Cada venta | Kilos y lo que te pagaron | Registrar › Ingreso |
| Cada pago | Trabajador, días y labor | Registrar › Gasto › Mano de obra |
| Fin de mes | Revisas el balance y guardas el respaldo | Reporte · Configuración › Respaldo |

**La regla de oro:** si no lo anotas, la app no lo sabe. No inventa cifras:
lo que falta, lo dice.

**Tres cosas que no se anotan dos veces**

- **La cosecha:** se registra con la venta (kilos) o con el jornal de
  cosecha, no en los dos.
- **El pago del trabajador:** va en Mano de obra, no en la categoría de la
  labor.
- **El costo de la siembra:** va en la siembra y crea su gasto vinculado; no
  se repite en Registrar.

### 5.7 Entender · Diccionario

- **Ingreso** — Lo que te pagaron por lo que vendiste. No es lo mismo que
  cosechar: puedes cosechar y no vender.
- **Gasto** — Lo que pagaste para producir o mantener la finca. Si es de un
  cultivo, asígnalo.
- **Balance** — Ingresos menos gastos del período. Positivo: ganancia.
  Negativo: pérdida.
- **Costo por kilo** — Todo lo que costó producir un kilo: inversión de
  siembra + gastos del período, dividido entre los kilos cosechados. Si
  vendes por debajo, pierdes.
- **Margen** — De cada 100 que vendes, cuánto queda después de los gastos.
  Margen 20% = quedan 20.
- **Por hectárea** — El gasto o el ingreso repartido entre las hectáreas.
  Sirve para comparar lotes de distinto tamaño.
- **Por planta** — El gasto o el ingreso dividido entre las matas vivas.
  Dice si el problema es la densidad o el cuidado.
- **ROI** — (Ingresos − Gastos) ÷ Gastos. Por cada 100 invertidos, cuánto
  vuelve además del capital. ROI −70% = vuelven 30 de cada 100.
- **Recuperación** — Cuánto de la inversión inicial ya volvió con las
  ventas. 100% = ya la pagaste.
- **Caja menor** — El dinero que apartas cada mes para gastos chicos. Lo que
  no gastas pasa al mes siguiente.
- **Unidades** — kg, lb, arroba (12,5 kg), saco (el peso que defines en
  Configuración), carga (60 lb = 27,2 kg), racimo, cajón. La app convierte
  todo a kg para comparar.
- **Moneda** — La app muestra siempre el código de la moneda, nunca un
  símbolo. No suma monedas distintas: cada una sale por separado, con su
  código. La moneda de la cuenta se elige al empezar y no se cambia.

Botón: **Ver todos los términos** (abre el glosario actual).

### 5.8 Entender · Si algo no cuadra

- **El gasto no aparece en el cultivo** — Revisa que lo hayas asignado. Si
  quedó «Sin especificar», cae en «Costos comunes».
- **La venta no coincide con la cosecha** — La venta registra la cosecha con
  los kilos que anotes. Si ya la anotaste en el jornal, no la repitas.
- **Hay dos monedas y no veo un total** — Es a propósito: no se suman
  monedas distintas. Cada una sale con su código.
- **El área no cuadra** — La suma de cultivos puede superar el área del
  terreno. La app avisa, no bloquea. Corrige el área o el reparto.
- **No subió a la nube** — La app guarda primero en tu equipo. Sin señal
  queda pendiente y sube al reconectar. Puedes reintentar.
- **Borré sin querer** — Mira Historial. Si no está, restaura el respaldo:
  lo que ya tenías se conserva y lo del archivo se suma.

**¿No encuentras tu caso?** Anota lo que pasó y el reporte se ajusta. La app
no inventa cifras: si falta un dato, lo dice.

## 6. Personalización por caso

| Caso | Qué asume | Qué muestra primero |
|---|---|---|
| Ya vendo | Cultivo en producción | Gasto → venta → reporte |
| Voy a empezar | Sin primera cosecha | Cultivo → siembra → inversión |
| Renovar o ampliar | Cultivo con historia | Resiembra → lote → edad |
| Trabajadores | Pago de jornales | Trabajador → pago → nómina |

El caso se guarda en preferencias. No se lee ningún dato de la finca.

## 7. Fuera de alcance

- No se cambia el flujo del onboarding ni de la Bienvenida; solo su voz.
- No se agregan videos, tutoriales interactivos ni tour sobre la pantalla.
- No se cambia el glosario existente; se enlaza.
- No se toca el reporte, los cálculos ni los datos.

## 8. Decisiones cerradas

1. **Tres pestañas:** Empezar, Rutina y Entender.
2. **Se recuerda el caso elegido** en una preferencia local (`help_case`).
3. **«Varios cultivos en el mismo terreno»** queda como nota dentro del caso
   1, no como quinto caso.
4. **La voz se unifica en este cambio:** la Bienvenida y 23 cadenas pasan a
   tuteo.

## 9. Implementación

### Pantalla

- `lib/screens/help_screen.dart` reescrita como pantalla con estado y tres
  pestañas.
- La pestaña Empezar muestra las 4 tarjetas y el caso elegido; al tocar una
  tarjeta se guarda `help_case_v1` y se muestra su camino.
- La pestaña Rutina muestra los cuatro momentos y las tres reglas.
- La pestaña Entender muestra diccionario (10 términos), unidades, moneda,
  problemas y el botón al glosario.
- Sin barras de progreso ni casillas.

### Memoria del caso

- `LocalStore.loadHelpCase()` / `saveHelpCase()` sobre `help_case_v1`, con el
  mismo namespace por usuario que el resto de las claves.
- `TransactionProvider.helpCase` / `setHelpCase()` es la puerta que usa la
  pantalla; el `store` sigue siendo solo para tests.
- Un valor guardado que ya no es un caso válido abre la portada.

### Copy

- Nuevas claves `helpStart*`, `helpCase*`, `helpSelling*`, `helpStarting*`,
  `helpRenew*`, `helpWorkers*`, `helpRoutine*`, `helpDict*`, `helpTrouble*`,
  `helpTabStart`, `helpTabRoutine`, `helpTabUnderstand` y
  `helpDictCurrencyTitle/Body` en `app_es.arb` y `app_en.arb`.
- Retiradas 141 claves de la Ayuda vieja que quedaron sin uso.
- Conservadas las claves de ayuda en línea de los formularios (`helpArea`,
  `helpPlants`, `helpExpectedYield`, `helpSowingKind`, `helpSowingPlants`…).
- Glosario: `glossaryIncome*` y `glossaryExpense*` nuevos; ROI, margen y
  ratio ya no citan `$100`; `glossaryYieldAreaDef` en inglés dice «lots»,
  como el resto de la app.

### Voz: 23 cadenas a tuteo

`welcomeTitle`, `welcomeSubtitle`, `helpArea`, `helpPlants`,
`helpExpectedYield`, `helpSowingKind`, `helpSowingPlants`,
`sowingMissingLossesBody`, `reportPendingWeightHint`, `expenseSplitFew`,
`expenseSplitNeedAmount`, `deductionQtyInvalid`, `deductionOverQuantity`,
`sowingWhatHappensOldPlants`, `sowingReplacePlantsRequired`,
`sowingReplaceNoArea`, `sowingReplaceTooMany`, `sowingDeleteCohortBody`,
`jornalHarvestedKgNoCrop`, `workSheetNoTasks`, `exportNeedsNetworkOnce`,
`alertFirstHarvestSuggestion`, `alertUnpaidSuggestion`.

Además, por la regla de «cualquier región»: `helpExpectedYield` ya no cita a
Cenicafé, y `metricReceivablesNote` y `chartCumulativeTitle` dicen «dinero»
en vez de «plata».

### Tests

- `test/help_screen_test.dart`: tres pestañas, cuatro casos, cambio de caso,
  rutina, diccionario, glosario y memoria del caso.
- `test/help_l10n_test.dart`: claves en ES y EN; cero `$`, códigos de moneda y
  países en la Ayuda; «tu moneda» en los ejemplos; sin «Cosechas».
- `test/voz_tuteo_test.dart`: guarda que el ARB no vuelva a meter voseo ni
  regionalismos (`tenés`, `hacé`, `anotá`, `vos`, `plata`, `Cenicafé`).
- `test/help_coherencia_test.dart`: cada caso tiene 4 pasos como máximo y un
  tamaño de letra por papel.
- `test/help_menu_map_test.dart`: cada puerta del menú queda nombrada.
- `test/help_no_orphan_keys_test.dart`: ninguna clave `help*` sin pintar.
- Ajustados los tests que afirmaban textos viejos.

### Gate

`flutter analyze` limpio · `flutter test` 1335/1335. Sin commit ni deploy sin
verbo explícito.

