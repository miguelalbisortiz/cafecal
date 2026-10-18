# Sesión — sábado 17 de octubre de 2026 (las cifras con su código, y las guardas)

Estado al cierre. Archivo completo en `2026-10-17-cifras-con-su-codigo-y-guardas.md`.

Quinta tanda del día. Anteriores de hoy: `2026-10-17-alerta-moneda-signo-y-f4.md`,
`2026-10-17-campo-de-fecha-en-perdidas.md` y `2026-10-17-entorno-motores-plugins-y-mcp.md`.

---

## 1. ¿Dónde quedó el proyecto?

La tanda empezó en el `$` de una alerta y cerró la familia entera: **el monto se lee con su
código de moneda** (nunca con el símbolo) y hay guardas que lo vigilan donde antes no había
ninguna. Se cerraron además los pendientes que colgaban de esa regla y se verificó, leyendo el
código, que la cosecha derivada de la venta ya estaba terminada.

| Rama | Commit | Estado |
|---|---|---|
| `main` | `e92b07c` | sincronizada con `origin/main` |
| `gh-pages` | `9f67afd` | sincronizada |

Huella en producción:

`2C453D77472F4D6EACB49571C4CFA6DE7AC30FF31678C265B9D08F59A668B12F` · 4.794.925 bytes
(antes: `2E52BB5E…` · 4.794.805).

Los siete commits de la tanda, en orden:

| Commit | Qué |
|---|---|
| `1f8a66c` | **alertas: los montos con su código de moneda, y el déficit con cada cifra en su casilla** |
| `29a53d0` | **mensajes: el borrado de cultivo y la caja en rojo dicen sus cifras en su casilla** |
| `612cfa3` | **mensajes: el orden de los datos se declara como se lee la frase, con guarda** |
| `085f812` | **reportes: el precio por kilo se lee como lo lee la alerta** |
| `4e49792` | **pruebas: las guardas de moneda mixta hablan la notación de la app** |
| `38bc550` | **ayuda: los ejemplos citan sus cifras con el código de la moneda** |
| `e92b07c` | **monedas: el catálogo deja de llevar el símbolo** |

Gate antes de commit y deploy: `flutter analyze` limpio y **942/942** (venía de 934).

---

## 2. Lo que se tocó la app (siete cosas)

**a · Las alertas dejaron de pintar los montos con `$`.** `_money` pasa a recibir la moneda y
delega en `formatAmount` → `COP 1.500`. Los 21 sitios usan **la moneda que cada regla ya validaba**:
el exceso, la que quedó del mes; el déficit por cultivo, la del cultivo; la caja menor, la que
gastó. El idioma sale del `locale` de `AlertService` (`settings.locale`), no de `localeName`.
Bonus: los decimales son los de la moneda —una cuenta en USD conserva los centavos
(`USD 300,25`), antes redondeaba a 0—.

**b · Tres mensajes que mentían.** Los tres salían de la misma trampa (el punto **c**):
el aviso del déficit decía que `3` registros eran `3` pesos; el aviso previo a borrar un cultivo
leía «Se eliminarán las siembras (Café) y las cosechas (2) de «1»» (los datos en la casilla del
vecino); y la caja en rojo decía que lo gastado era el arrastre. Arreglados **sin tocar Dart**:
declarando los placeholders en el ARB en el orden de la frase, que es lo que fija las firmas.

**c · La trampa de los siete mensajes.** Los placeholders que el ARB **no** declara los ordena el
generador por su cuenta (alfabéticamente), así que una llamada escrita «como se lee» cae en la
casilla de al lado y el mensaje miente en silencio. Siete mensajes estaban en esa situación
(`insightVsPrev`, `insightTopExpense`, `insightTopIncome`, `insightLowPrice`, `insightBestMonth`,
`alertLowPriceManualMessage` y `alertHarvestVsSalesMessage`): se declararon en el orden de la
frase y se giraron sus siete llamadas. **Nada cambió de lo que se lee** (los placeholders van por
nombre); lo que cambió es que la regla es una sola: la llamada se escribe como se lee.

**d · El precio por kilo de Reportes.** El insight decía «promedio reciente **400.0** vs 760.0 por
kilo» mientras la alerta de Inicio, con el mismo número, dice «**COP 400** por kilo». Ahora pasa
por el mismo formateador que el resto de los insights. De paso: ya **ningún mensaje declara
`double` ni `num`**, así que ningún otro texto puede colar un número de máquina.

**e · Las guardas ciegas de moneda mixta.** Dos arneses se armaban con un formateador de mentira
(`'$' + round()`) y luego asertaban literales con `$` (`'\$1.550'`) que la **app nunca pinta**
(pinta `COP 1.550`): la guarda pasaba por culpa del falso. Ahora los dos usan el formateador de la
casa, las guardas hablan de `COP`/`EUR` y los cuatro literales vacuos se volvieron la notación
real **más** la cifra que sí se pinta por moneda (para que la guarda tenga su lado positivo).

**f · La Ayuda.** Los ocho ejemplos con cifras concretas (casos A y B, el panel «Por hectárea» y
el payback) citaban el símbolo y el separador de otro idioma («$500,000», «vende $9M»): ahora usan
«COP 500.000», con el separador del idioma (`. ` en es, `,` en en). Las **razones** en prosa («por
cada `$100` vendidos», el glosario y las tarjetas de margen y ratio) se quedan: ahí el símbolo no
cita un monto, cita una proporción.

**g · El catálogo de monedas.** `CurrencyInfo.symbol` no lo pintaba nadie: se va, con su bloque de
test, que pasa a vigilar que cada moneda tenga nombre y decimales válidos.

**h · La cosecha derivada estaba terminada.** Las **Fases 5 y 6** del plan del 2026-10-15 se
verificaron pieza por pieza: `NextStepType` ya no tiene `harvest` y el corte de la guía es
`tieneGasto && tieneIngreso`; la tabla de la Ayuda tiene cinco filas (sin Cosechas), el paso 4 dice
«La cosecha · Se anota sola con los kilos de tu venta», el caso A manda a Registrar el ingreso y la
tarjeta dice «Al registrarla se anotan solos los kilos cosechados de ese cultivo», en ES y EN.
**No había nada que implementar.**

### Las guardas nuevas (tres)

| Guarda | Qué vigila |
|---|---|
| `test/l10n_placeholder_order_test.dart` | el orden de los placeholders del texto es el de la firma que los recibe, para los 35 mensajes con dos o más datos |
| `test/l10n_money_notation_test.dart` | ningún texto cita un monto con el símbolo (salvo las razones) y los ocho ejemplos de la Ayuda usan el código, leído del material generado |
| `test/report_insights_service_test.dart` + `test/mixed_currency_gap2_test.dart` | la notación se prueba con el formateador **real**, no con uno de mentira |

---

## 3. Tests y rojo/verde

Todo verificado **fallando primero** (o apagando la pieza a mano):

- el `$` de las alertas: `Actual: '…llevas $300…'`; y `USD 300,25` conserva los centavos.
- el aviso del déficit: «tienes 7% registros … suman 3 en gastos … el COP 100 de lo invertido».
- el aviso de borrar cultivo: widget en rojo con el texto literal completo.
- el orden declarado: al devolver `@insightVsPrev` a su orden viejo, cae nombrando
  `texto: month, incChange, expChange` / `firma: expChange, incChange, month`.
- el precio por kilo: `Actual: '…promedio reciente 400.0 vs 760.0 por kilo…'`.
- las guardas ciegas: **forzando el cruce de monedas** a propósito en `amountsByCurrency`,
  `groupAmountsByCurrency` y `isMixedCurrency` caen cuatro tests, incluidos los dos que se
  blindaron; la inyección se revirtió y el archivo de producción quedó limpio.
- la Ayuda: `Actual: Set:['helpCaseAEx2']` y `Actual: 'Gasto de $500,000 en Fertilizante'`.

---

## 4. Deudas y avisos

🟡 **`deploy.ps1` no lo cubre ningún test** — punto ciego declarado, sin cambios.

🟡 **Las razones en prosa conservan el `$`** («por cada $100 vendidos»), a propósito: es una
proporción, no un monto. La excepción está escrita y acotada en `l10n_money_notation_test`.

🟡 **El ítem de menú de Cosechas y la rama `if (v == 'harvests')`** (`home_screen.dart:189,228-236`)
siguen vivos a propósito: son el «descomentar y volver» que documenta el plan (§7).

🟢 **Las ~28 llamadas cuyo orden ya coincidía** no hubo que leerlas a mano: la guarda de orden las
cubre por construcción (si el texto y la firma concuerdan, la llamada escrita como se lee es
correcta).

---

## 5. Hallazgos que NO se abrieron

1. **El campo «kilos recolectados» en el jornal de labor «Cosechar»** (plan de la cosecha derivada,
   §5.1, Tanda 2): es la única forma de que la regla 6 (vendido > cosechado) reviva y de medir la
   pérdida en campo. Fuera por la regla propia «si se puede pedir después, no se pide ahora».
2. **Una pantalla de cosechas de solo lectura**: no. Reportes ya es esa pantalla y duplicar la
   misma cifra no aporta.

---

## 6. Pendientes de producto

1. **La verificación manual del usuario** que lista el plan del ciclo (§Verificación manual):
   moneda con y sin internet, respaldo P1, banner L2.5b, PDF y Excel de período mezclado, borrado
   real, `/backup.html` y la cosecha con precio → venta.
2. **Tanda 2 de la cosecha derivada**, solo si hay evidencia de uso real (punto 1 de §5).

Nada urgente y nada roto.

---

## 7. Cómo continuar

Leer este archivo y `docs/LEARNING.md`; el estado de la app es el de la tabla de §1.

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Una sola función para una sola regla.
- El **código** de moneda es el único indicador (`COP 1.500`), nunca el símbolo.
- Cada arreglo con su test, **verificado fallando sin su arreglo** (y si el código ya está, se apaga
  la pieza a mano para verlo caer).
- Un test que no atraviesa el camino real es una **guarda**, no una prueba.
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
