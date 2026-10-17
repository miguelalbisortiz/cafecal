# Plan · Cosecha derivada de la venta

**Fecha:** 2026-10-15
**Estado:** PROPUESTO — pendiente de visto bueno antes de tocar código
**Decisión del usuario:** Opción B (recomendación del análisis)

---

## 1. El problema, en una frase

La pantalla de **Cosechas se ocultó del menú el 2026-09-24** («el pequeño agricultor
produce y vende sin almacenar»), pero **cinco cosas seguían dependiendo de ella**.
Resultado: en la app que corre es imposible crear una cosecha, y todo lo que depende
de ella queda apagado o, peor, en contradicción.

Evidencia verificada:

- `HarvestScreen` solo se abre desde `home_screen.dart:189` (ítem de menú **comentado**
  en 228-236) y `:445` (raza `NextStepType.harvest`).
- `nextStepFor()` jamás devuelve `harvest` ni `sale` → la segunda puerta está muerta.
- `addHarvest` solo lo llama `harvest_screen.dart:300`; `reconcileHarvestSale` solo `:314`.
- Los 752 tests pasan porque `harvest_screen_test.dart:40` monta `HarvestScreen()`
  como `home:` — **nunca atraviesa la navegación real**.

---

## 2. Daño actual (lo que este plan cura)

| # | Síntoma | Causa |
|---|---|---|
| 1 | **Alerta sin salida**: regla 13 en `warning`, no descartable, que dice *«registrá esa cosecha y este aviso desaparece»* — y no hay dónde. Único callado: borrar la fecha que la app pidió. | `_checkFirstHarvestOverdue` exige `yaCosecho`, que solo `addHarvest` puede poner en `true`. |
| 2 | **Fase congelada** en `establecimiento` → el déficit >30% se reporta `info` en vez de `danger` (`alert_service.dart:336-351`). | `_promotePhaseOnHarvest` solo corre dentro de `addHarvest`. |
| 3 | **Reporte a medias**: «Sin datos de cosechas», rendimiento kg/ha y kg/planta en `null`, costo por kilo en `null`. | No hay `Harvest` que sumar. |
| 4 | **Regla 6 (vendido > cosechado) muerta**: `harvestedKg == 0` → `continue`. | Ídem. |
| 5 | **La Ayuda miente**: tabla «¿Dónde entro cada dato?» lista *Cosechas*; ejemplo A dice «entra a Cosechas»; flujo de 5 pasos con el paso 4 sin puerta. | Texto no revisado al ocultar la pantalla. |

**Fuera de alcance:** lo que sí funciona hoy — gastos, ingresos, margen, caja con
sobrante, por cobrar, mes contra mes, alertas 1-5 y 7-12 — **no se toca.**

---

## 3. El diseño

### 3.1 Principio

> **La cosecha se deduce de la venta que él ya anotó.**

No se le pide un paso más. No se inventa ningún número: los kilos son los que
escribió en la venta. Es coherente con la regla de dominio *«todo lo que se cosecha
se vende»* y con *«si el dato no se usa para algo, no se pide»*.

### 3.2 La regla (una sola)

> Para cada **venta no borrada** que tenga **cultivo**, **kilos** y **`harvestId == null`**,
> y cuyo cultivo **no tenga ninguna cosecha guardada a mano**, se calcula una cosecha.

- `date` = `t.date` · `amount` = `t.quantity` (bruto) · `unit` = `t.unit`
- `destination` = `vendido` · `cropId` = `t.cropId`
- `id` = sintético (`der_<t.id>`), `pendingSync` = `false`

**Se calcula al leer. No se guarda. No viaja en sync.**

### 3.3 Por qué computada y no persistida

| Si se persiste | Si se computa |
|---|---|
| Hace falta migración de Supabase | **Sin migración** |
| Hace falta ruta de borrado remoto o se zombifica: `mergeRemoteHarvests` (`:555`) re-agrega lo remoto que falte localmente | **No existe nada que revivir** |
| Hay que definir qué pasa al editar/borrar la venta | **Se corrige solo**, porque se recalcula en cada lectura |
| Hay que distinguir «derivada» de «manual» de forma persistente | La distinción es *«la venta tiene `harvestId` o no»* |

Costo asumido: `HarvestScreen`, si algún día se reabre, tendría que saber que esas
filas son computadas. **Hoy esa pantalla no tiene puerta**, así que el riesgo está
contenido y queda anotado en §6.

### 3.4 Los tres puntos de cableado

1. **Función pura nueva** `lib/services/derived_harvests.dart` — recibe transacciones
   + cosechas guardadas, devuelve las derivadas. Sin estado, sin I/O, testeable sola.
2. **`TransactionProvider`** — el getter `harvests` pasa a devolver
   `guardadas + derivadas`. **Nuevo getter `storedHarvests`** con solo las guardadas.
3. **`sync_provider.dart:221`** — hoy hace `for (final h in _txProvider.harvests…)`,
   es decir, **empuja el getter**. Debe pasar a `storedHarvests`. Sin esto, la
   derivada se subiría a Supabase.

### 3.5 Por qué NO hace falta migración

`transactions.harvest_id` **ya existe** (migración `202609070001`, línea 89), ya se
empuja (`sync_provider:335`) y ya se lee (`:604`). Y `pickupCostPerKg` solo mira
**gastos** con `harvest_id` (`report_harvest_metrics.dart:70,82`) — es decir, enlazar
una **venta** a su cosecha **no altera ninguna cifra existente**.

⇒ **Ninguna migración de Supabase. Nada que correr en supabase.com.**

### 3.6 Por qué los tres pintadores quedan de acuerdo

`report_screen`, `pdf_export_service` y `excel_export_service` **los tres reciben
`tx.harvests` como parámetro** (verificado: `report_screen:369,556,1387,1575,1625`;
PDF `:58` y Excel `:46` son argumentos). Al cambiar el getter, **los tres se
alinean solos** — sin tocar un solo `if` de copiado.

---

## 4. Efectos en cascada esperados

Ninguno requiere código aparte: caen del cableado.

| Efecto | Cómo |
|---|---|
| Fase → `produccion` | `_promotePhaseOnHarvest` se dispara al contar la cosecha derivada |
| **Alerta 13 se apaga sola** | `yaCosecho: harvests.any(...)` pasa a `true` |
| Regla 5 sube `info` → `danger` | La fase ya no es `establecimiento` |
| Rendimiento kg/ha, kg/planta, promedio histórico | `yieldPerArea` / `yieldPerPlant` / `historicalYield` encuentran kilos |
| Costo por kilo (P2) | `periodCostPerKg` encuentra kilos |
| Sección «cosechas» del reporte | `totalsByCrop` encuentra filas |
| Regla 6 | Sigue **callada** — correcto: compara `soldKg` contra `harvestedKg` que ahora son iguales. No hay cifra independiente que confrontar, y `null` → oculto. |

### ⚠️ Efecto colateral que SÍ requiere código

**`_builtSoldVsHarvestedCard`** (`report_screen:1316`) pasaría a comparar un número
consigo mismo → mostraría «vendido = cosechado» como si fuera un hallazgo.
**Regla aplicable:** si **todas** las cosechas del período son derivadas, esa tarjeta
**se oculta** (misma lógica de la regla de oro: sin medición independiente, no hay
comparación que mostrar).

---

## 5. Decisiones — APROBADAS 2026-10-15

| # | Pregunta | Decisión |
|---|---|---|
| **D1** | ¿Computada o persistida? | **Computada** (§3.3). Ahorra migración, sync y semántica de borrado. |
| **D2** | ¿Derivar también en cultivos que **sí** tienen cosechas guardadas a mano? | **No.** Regla conservadora: *«si ya llevas cosechas anotadas a mano, esas mandan»*. Cero riesgo de doble conteo en cuentas legadas. Costo aceptado: un cultivo con cosecha manual de 2024 no ganará rendimiento con ventas de 2026 — se prefiere no inventar antes que arriesgar. |
| **D3** | ¿Arreglamos también el **hueco 2**? | **Sí, incluido** — es lo que hoy impide invitarlo a registrar la venta. Corte: de `hasTransactions` a `tiene gasto && tiene ingreso`. |
| **D4** | Regla de derivación | **Por-prioridad y extensible desde la Fase 1**: hoy `venta`; mañana, si se aprueba, `jornal-cosecha`. Es un `if` en la función pura, no un rediseño. **La puerta queda abierta sin pedirle nada al agricultor.** |
| **D5** | Tarjeta «vendido vs cosechado» | **Se oculta** mientras la única fuente sea la venta (sería comparar un número consigo mismo) y **se enciende sola** al aparecer una fuente independiente. Se toca una vez, no dos. |

### 5.1 Pendiente en el tiempo — Tanda 2 (no entra aquí)

**Campo «kilos recolectados» en el jornal de labor «Cosechar»** (`register_screen:985-1034`
hoy pide trabajador · labor · **días** · valor día — `quantity` es **días**, no producto).

Si se aprueba, es **la única forma de obtener dos datos que la venta jamás dará**:

- **regla 6** (*vendido > cosechado*) pasa de muda a activa;
- **pérdida en campo**: lo que se recogió y no se vendió.

Queda fuera por la regla propia *«si se puede pedir después, no se pide ahora»* y porque
la cobertura sería parcial (solo quien paga por día y mide). **D4 deja la puerta lista**
para que sea un `if` y no un rediseño. A decidir cuando haya evidencia de uso real.

**Ni pantalla de cosechas de solo lectura**: `Reportes` ya es esa pantalla, y duplicar la
misma cifra no aporta. Si el dato llega, se refleja en Reportes y en las alertas.

---

## 6. Orden de ejecución

Cada fase termina en **gate**: `flutter analyze` + `flutter test` limpios.
Ningún commit sin verbo explícito del usuario.

### Fase 1 — el corazón, aislado
`lib/services/derived_harvests.dart` (función pura) + `test/derived_harvests_test.dart`.
- Cubre: sin kilos → nada · sin cultivo → nada · venta ya ligada → nada · cultivo con
  cosecha manual → nada · borrada → nada · venta normal → una cosecha · dos ventas → dos.
- **Por qué primero:** es lógica pura, se prueba sin UI y todo lo demás cuelga de ella.
- ⬜ gate

### Fase 2 — cableado
Getter `harvests` = guardadas + derivadas · nuevo `storedHarvests` ·
`sync_provider:221` → `storedHarvests`.
- Tests: el sync **no** sube derivadas · el respaldo **no** las exporta
  (usa `_harvests`, `transaction_provider:821` — verificar) · merge no las revive.
- **Punto de no retorno:** a partir de aquí las cosechas existen para todo el resto.
- ⬜ gate

### Fase 3 — la cascada
Tests de regresión de los tres efectos: fase promovida · alerta 13 apagada ·
regla 5 en `danger`.
- ⬜ gate

### Fase 4 — reportes
Rendimiento/ha, costo/kg, sección cosechas encendidos.
- **Obligatorio:** ocultar `_builtSoldVsHarvestedCard` si no hay cosecha manual (§4).
- Verificar que **pantalla, PDF y Excel** dan el mismo número.
- ⬜ gate

### Fase 5 — la guía *(solo si D3 = sí)*
`nextStepService`: cambiar el corte a `tiene gasto && tiene ingreso` ·
borrar la rama muerta `NextStepType.harvest`.
- ⬜ gate

### Fase 6 — textos que hoy mienten
Ayuda: fila «¿Dónde entro cada dato?» de *Cosechas* · paso 4 del flujo · ejemplo A ·
hint de la tarjeta de guía (depende de si la Fase 5 se hizo).
- `app_es.arb` + `app_en.arb` + regenerar `lib/l10n/generated/*`.
- Atención: `help_screen_test.dart` y `terminology_guide_test.dart` referencian el
  texto viejo y habrá que ajustarlos.
- ⬜ gate

### Fase 7 — publicar
Stageo explícito → `flutter analyze` + `flutter test` → `.\deploy.ps1`
(ya verificado: `--base-href=/cafecal/`, claves desde `.env`, verificación en producción).
- ⬜ gate final

---

## 7. Fuera de alcance (no reabrir sin preguntar)

- **W1-c** — terreno en reportes/PDF/Excel: **descartado (2026-10-15)** — sin W1-b
  no hay costo de terreno que repartir, así que agrupar por terreno no movería
  ningún número; entra en la regla «si no se usa para algo concreto, no se pide».
- **Reabrir `HarvestScreen`**: no entra en este plan. Si algún día se hace, hay que
  resolver que las derivadas son computadas (§3.3).
- **Regla 6 con cifra independiente**: solo tendría sentido si el agricultor empieza a
  anotar cosechas a mano. Hoy se queda callada, que es el comportamiento correcto.
- Moneda, caja, por cobrar, sync: **intactos.**
