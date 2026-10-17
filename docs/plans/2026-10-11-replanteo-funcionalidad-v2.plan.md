---
status: ACTIVE
created: 2026-10-11
updated: 2026-10-13
supersedes: docs/plans/2026-10-08-ciclo-cultivo-siembra-cosecha.plan.md (F1-F6 CERRADAS)
---

# Plan v2 · Replanteo de la funcionalidad (modelo del asocio)

> **Documento de TRABAJO.** Conserva íntegro el análisis previo y le añade la capa
> de "cómo trabaja realmente un caficultor pequeño/mediano con tierra asociada".
> Regla de oro: el usuario **ANALIZA y decide juntos** antes de tocar código.

---

## ⚠️ ESTADO AL 2026-10-13 · lee esto antes que nada

**E0–E6 se ejecutaron completos.** El §8.5 de abajo, escrito *antes* de ejecutar,
dice "Falta: W3, W2, W5, W1-A, W4, R3" — **los seis están en producción.** No lo
uses como lista de pendientes.

| Frente | Etapa | Estado | Commit |
|---|---|---|---|
| **W3** · La venta real | E1 | ✅ desplegado | `f911858` |
| **W1-A** · Del fondo | E2 | ✅ desplegado | `bd4de00` |
| **W5** · La obra del día | E3 | ✅ desplegado | `b109b4b` · `f350c2f` |
| **W2** · El rendimiento | E4 | ✅ desplegado | `b4241f8` |
| **W4** · La vida del cultivo | E5 | ✅ desplegado | `a9bb807` |
| **R3** · La puerta | E6 | ✅ desplegado | `09797ea` · `4d496bd` |
| **W1** · El terreno (W1-a) | — | ✅ desplegado | `a360ad7` |
| **F1-F6** · ciclo | — | ✅ desplegado | `fa5e282` y anteriores |
| **H1-H9** · hallazgos | — | ✅ desplegado | `3ec1a08` · `50b7a72` |

**Lo que queda abierto de este plan:**

1. ~~**P6 · C6 — despojo y reinicio de edad**~~ ✅ **implementado 2026-10-13**
   (`test/c6_arranque_test.dart`, 9 tests) — casilla *"Esta siembra arrancó el
   cultivo de nuevo"* en la pantalla de Siembra: fase → `establecimiento` y
   `primerCosechaEsperada` → `null`. **La edad ya se reiniciaba sola.**
2. ~~**Alerta "debería estar rindiendo" en Inicio**~~ ✅ **implementado
   2026-10-13** (`test/first_harvest_alert_test.dart`, 12 tests) —
   `AlertRule.firstHarvestOverdue`, severidad `warning`, **tope de 12 meses**,
   se apaga con la primera cosecha.
3. **W1-c · el terreno en Reportes/PDF/Excel** 🟡 M — nunca diseñado. Ojo: **W1-b
   se descartó** (2026-10-12), así que no hay gasto de terreno que repartir y solo
   quedaría *agrupar cultivos por terreno*. **Solo avanza si se le encuentra un
   uso concreto.**

> Los dos primeros están **escritos y verificados** (`analyze` limpio,
> **698/698 tests**) pero **aún sin commitear ni desplegar**.

**Descartados por decisión explícita, no por falta de tiempo** — no re-abrir sin
volver a preguntar:

| Decisión | Por qué |
|---|---|
| **C14** · tablas de referencia por región/Cenicafé | `crop.dart:50` — "obligaría a adivinar la especie". La referencia es **su propia meta**. |
| **§9.3 E4** · marca roja si se queda abajo | `per_hectare_panel.dart:226` — "la meta es SU número… **tampoco se juzga**". |
| **C5** · edad por especie | Fecha suya (`primerCosechaEsperada`) + umbral de 3 años eliminado (H2). |
| **C3** · reparto de gastos entre cultivos (W1-b) | Dividirlo por hectáreas sería **inventar una cifra**. `transactions.terreno_id` queda RESERVADA. |
| **§9.3 E1** · pago *parcial* | Solo **Pagado / Por cobrar**. |

---

## 0 · TODO LO QUE SE CONSERVA (no re-analizar)

### 0.1 · Ciclo F1-F6 — CERRADO Y DESPLEGADO

`main fa5e282` · `gh-pages 55a65ee` · SHA256 local = prod (MATCH) · **529/529 tests** · analyze limpio.

| Fase | Qué | Commit |
|---|---|---|
| **F1** | Cosecha → venta + B1 (borrar cosecha borra la venta, conserva gastos) | `b895a94` |
| **F2** | Costo en la resiembra | `4df406d` |
| **F3** | Inversión total (auto-relleno, excluye resiembras) | `4df406d` |
| **F4** | Pérdida sin plantar (0 plantas + perdidas > 0) + bloqueo de área/plantas | `4df406d` |
| **F5** | `plantedAt`, fase deducida al crear (C2), edad junto a la fase | `fa5e282` |
| **F6** | Saco configurable (A2), defecto 70, en Ajustes junto al umbral | `fa5e282` |

**Migraciones aplicadas y verificadas** en Supabase (`ioyqlzhzlvkkebvenqnz`):
`crops.planted_at` (date, nullable) · `settings.saco_kg` (numeric, default 70, not null).
Ambas versionadas en `supabase/migrations/202610100001_*.sql` y `…0002_*.sql`.

### 0.2 · R3 · Puerta de entrada — Gate 0 CERRADO (2026-10-10), NO IMPLENTADO

| | Decisión | Estado |
|---|---|---|
| **G1** | Al tocar un producto → **ficha corta automática** (campo fecha + [Listo] / [Completar datos…]) | ✅ |
| **G2** | Tarjeta *"Tu próximo paso"* → **queda como está** | ✅ |
| **G3** | Al terminar de agregar → **quedarse en la lista** de productos | ✅ |
| **G4** | Fecha de plantación → **opcional y sin insistir, como está hoy** | ✅ |
| **G5** | Plátano → **como está** (perenne, renovaciones vía gasto) | ✅ |

**R3 completo:** reemplazar "¿siembra o cultivo?" por **"¿Qué cultivás?"** + ficha opcional.

Fases estimadas: **R3-a** lista de productos (🟡, *conservar el nombre de clase
`WelcomeOnboardingCard` para no tocar `onboarding_flow_test.dart`*) · **R3-b** ficha corta
de fecha (🟡) · **R3-c** integración en `home_screen._buildOnboarding` L313-322 (🟢) ·
**R3-d** l10n — 5 claves nuevas, 7×2 retiradas `welcomeNew*` / `welcomeExisting*` /
`welcomeHint` (🟢) · **R3-e** tests (🟡). **Total 🔴 L.**

Corte propuesto: (1) `R3-a+c+d+tests` ya desplegable · (2) `R3-b+tests`.
**Invariante: sin migración, sin tocar modelo ni sync, aditivo.**

### 0.3 · Hallazgos H1-H8 (verificados con código)

| | Hallazgo | Alcance |
|---|---|---|
| **H1** | La **fase de vida** `Establecimiento/Producción/Renovación` es vocabulario de cafetal | 🔴 |
| **H2** | **"~3 años → Producción"** está hardcodeado **para café** (`crop_editor_dialog.dart:89-91`). Palta/mango 3-5 años, mandarina 3-4, plátano 9-12 meses | 🔴 |
| **H3** | **Ciclo Anual fuerza `Producción`** y oculta el dropdown de fase (`crop_editor_dialog.dart:265-269`) — bien para tomate, mal para plátano (perenne de ciclo corto) | 🔴 |
| **H4** | **El camino corto del plátano ya existe**: *Registro → Gasto → categoría "Siembra" → cultivo*. Cuenta igual para Inversión total y costo/kg (`report_harvest_metrics.dart:153`, `transaction_provider.dart:330`). **Solo falta comunicarlo** | 🟢 copy |
| **H5** | Faltan categorías de gasto: **crédito/intereses**, **cercas/tapia/preparación** (inversión inicial), **seguros** | 🟡 |
| **H6** | El comentario de `kExpenseCategorySowing` (`categories.dart:29-32`) **dice que no se elige manualmente y sí se elige** — y eso es lo que hace que H4 funcione. Arreglar comentario, no código | 🟢 |
| **H7** | **`'otro'` está en `kCashBoxExtraCategories`** → todo lo no clasificado se come la caja menor (`categories.dart:45-54`) | 🟢 |
| **H8** | **Faltan deducciones en la venta** (impureza, humedad, comisión, flete) — en café real te pagan *descontando*. Hoy solo queda el monto neto | 🔴 |

### 0.4 · Errores del onboarding ya diagnosticados (E1-E7)

E1 pregunta categórica errónea · E2 rótulos de situación vs acciones · E3 *"no importa cuál"* **es falso** ·
E4 fecha hoy + fase Establecimiento silenciosas · E5 área/plantas duplicadas en dos formularios ·
E6 "Inversión total" nace vacía en el primer cultivo · E7 plátano modelado como perenne de una sola fecha.

### 0.5 · Fuera de alcance heredado (confirmado)

`HarvestDestination.almacenado` NO se toca · renombrar "Cultivos" retirado · separar Lote/Cultivo NO ·
Plan C "Tablero del Caficultor" **CONGELADO** · campo "lote" explícito retirado ·
**Costos compartidos → ahora es el frente central (ver §4)**.

### 0.6 · Reglas de ejecución (heredadas)

🔬 `flutter analyze` **y** `flutter test` secuenciales antes de cada commit (ref. actual **529/529**).
📦 Stageo **siempre explícito**: `git add lib test web supabase` — **jamás** `git add -A`.
🚫 Ningún commit/push sin verbo explícito ese turno. `docs/` solo si el usuario lo pide.
🚫 No commitear `docs/plans/2026-09-07-cosecha-nivel2.plan.md` ni `…-tu-proximo-paso.plan.md`.
🇪🇸 Todo en español. Aditivo/retrocompatible (GitHub Pages + Supabase).
🔑 Regla de oro: **`null` → oculto, nunca 0**. Regla nueva: **si no se va a usar, no se pide;
si se puede pedir después, no se pide ahora.**

---

## 1 · EL MODELO REAL QUE DESCUBRE EL USUARIO

**No son cultivos separados en campos separados: es UN TERRENO con asocios.**

```
UN MISMO TERRENO
├── ☕ CAFÉ          ciclo largo (20-25 años) · no da plata hasta el año 3
├── 🍌 PLÁTANO       ciclo corto (9-12 meses) · rinde YA
├── 🥭 MANGO/PALTA   ciclo medio (3-5 años) · rinde DESPUÉS
└── 🌳 SOMBRA/OTROS  servicio
```

Las **tres funciones económicas** de ese terreno, según lo que plantea:

1. **El corto plazo financia el largo**: el plátano/fruta entra a la caja cada pocos meses
   y paga los gastos operativos **y hasta la siembra del café**.
2. **Un solo presupuesto de mano de obra** para todo el terreno, pequeño, usado según
   necesidad — *"como una pequeña planilla por jornada de trabajo"*, descontado de un
   **presupuesto mensual**.
3. **Hay que saber cuánto rinde cada cosa**: cantidad de producción y cantidad de venta
   por producto, para compararlos entre sí y con la referencia.

Y pide explícitamente registrar: **edad de la planta · reposición · tiempo hasta producir ·
gasto → ganancia cuando ya está en venta**, para **todo** lo sembrado en ese espacio.

---

## 2 · REFERENCIAS (Cenicafé + Sudamérica) — datos recogidos 2026-10-11

### Café
| Dato | Referencia |
|---|---|
| Primera cosecha | **≈ 32 meses** (Cenicafé) — la app usa "≈3 años" |
| Ciclo de producción comercial | **20-25 años**; primer ciclo 4-10 años (IICA) |
| Densidad | tradicional **2.500-3.000 plantas/ha**; Colombia pasó de **4.650 → 5.200 árboles/ha** promedio; rango 2.500-10.000 |
| Rendimiento | **1.000-3.000 kg café verde/ha/año**; tradicional **300-500 kg pergamino/ha**; intensivo hasta **2.500-4.000 kg/ha** |
| Por planta | **1,5 kg cereza/planta** · promedio Colombia **1,2 kg pergamino/planta** · óptimo **>1,7** |
| Peso en el costo | **"Más del 70% de los costos de producción son mano de obra"** (productor, Perfect Daily Grind) · ~28% de eso es mano de obra familiar |
| Sembrar 1 ha | siembra + mano de obra **$1,5-3,0 millones** (COP) |

### Plátano (el corto plazo)
| Dato | Referencia |
|---|---|
| Ciclo a primera cosecha | **9-12 meses**; luego cosechas sucesivas |
| Rendimiento | **15-40 t/ha/año** en buen manejo · promedio Colombia **≈6,1 t/ha** · histórico **8-10 t/ha** · hasta 70 t/ha manejo profesional |
| Asocio | **café + plátano + sombra** = agroforestería; el plátano da sombra/humedad y **entra a la caja mucho antes que el café** |

> **Conclusión de §2:** las referencias **no son universales** (varían por país, variedad,
> altitud y manejo). Por eso **no deben usarse como verdad**, sino como **opción por defecto
> editable** — igualito a lo que ya hicimos con el saco de 70 kg (A2). Principio reutilizado:
> **una sola fuente de verdad en Ajustes, sin números fijos en el copy.**

---

## 3 · COMPARACIÓN · lo que el modelo pide vs lo que la app tiene

| # | Lo que pide | Estado actual | Veredicto |
|---|---|---|---|
| C1 | Varios productos en un mismo terreno | ✅ varios `Crop` | Cumple |
| C2 | **Saber que comparten tierra** | ❌ **no existe noción de terreno/lote/predio** | **HUECO** — es exactamente "costos compartidos" |
| C3 | Repartir un gasto/obra entre cultivos del mismo terreno | ❌ **no se puede** | **HUECO CRÍTICO** |
| C4 | Edad de la planta | ✅ `plantedAt` + `edadDeCrop` + C2 | Cumple |
| C5 | Edad **correcta por especie** | ❌ umbral fijo de café (H2) | **HUECO** |
| C6 | **Reposición** de plantas | ⚠️ solo resiembra parcial + fase `renovación`. **No existe despojo y replante** | Hueco medio |
| C7 | Tiempo hasta producir / "ya debería rendir" | ❌ sin referencia ni alerta | Hueco |
| C8 | Gasto → ganancia en la venta | ✅ F1 (cosecha→venta), costo/kg, costo/ha, payback | Cumple |
| C9 | Presupuesto mensual de mano de obra | ⚠️ `cajaMenorMensual` **sí descuenta** mano de obra, pero es *caja*, no *obra* | Parcial |
| C10 | **Planilla por jornada** (qué labor, quién, cuántos días) | ⚠️ trabajadores + jornal (días × tarifa) **sin labor ni obra del día** | **Parcial — el más sentido** |
| C11 | Cantidad de **producción** por producto | ✅ cosecha con cantidad + unidad → kg | Cumple |
| C12 | Cantidad de **venta** por producto | ✅ venta con cantidad + unidad + precio | Cumple |
| C13 | **Rendimiento** (producción ÷ hectárea o ÷ planta) | ❌ **no se calcula ni se compara** | **HUECO** |
| C14 | Referencia Cenicafé/regiones | ❌ no hay tablas de referencia | Hueco |
| C15 | Mano de obra como % del costo | ⚠️ se registra pero **no se muestra el %** | Hueco chico |
| C16 | Deducciones en la venta | ❌ **H8** | **HUECO** |
| C17 | Gastos de **todo** lo sembrado | ✅ 16 categorías (con H5) | Cumple con reservas |
| C18 | Funcione en cualquier región de Sudamérica | ❌ todo está amarrado a café/Colombia | **HUECO** (H1-H3) |

---

## 4 · GAPS PRIORIZADOS

| P | Gap | Por qué primero | Estado 2026-10-13 |
|---|---|---|---|
| **P1** | 🔴 **C3 · Costos compartidos / mismo terreno** | Es **el centro** de lo que él plantea. Un obrero atiende café y plátano: ¿a quién le cargo la plata? Hoy no hay respuesta. | ✅ **W1-a** `a360ad7` (terreno como entidad). **C3 · reparto → DESCARTADO** (W1-b): partirlo por hectáreas sería inventar una cifra. |
| **P2** | 🔴 **C13 + C14 · Rendimiento y referencias** | Es lo que le permite decir *"esta hectárea rinde y esta no"*. Y es lo que hace comparable café vs plátano en el mismo terreno. | ✅ **C13** — E4 `b4241f8` (kg/ha, kg/planta, meta propia). **C14 → RECHAZADA**: la referencia es su propia tierra, no una tabla de región. |
| **P3** | 🔴 **H8 · Deducciones de venta** | Le está **ocultando plata** en cada venta de café. | ✅ **E1** `f911858` (cantidad, motivo, Pagado/Por cobrar, cuentas por cobrar). |
| **P4** | 🔴 **H2 + C5 · Edad/fase por especie** | Sin esto, mango y plátano se comportan mal. Condiciona a R3. | ✅ **H1-H3** `3ec1a08` + **E5** `a9bb807`. **C5 · tabla por especie → RECHAZADA**: fecha suya, umbral de 3 años eliminado. |
| **P5** | 🟡 **C10 · Planilla por jornada** | Es su forma de trabajar. Ya hay trabajadores y caja menor: falta el enlace *día → labor → cultivo*. | ✅ **E3-b** `f350c2f` (planilla por labor→cultivo con personas y días). |
| **P6** | 🟡 **C6 · Reposición / despojo y replante** | El ciclo real del plátano y la renovación del cafetal. | ✅ **2026-10-13.** *El plan decía "no existe" y era falso:* `edadDeCrop` ya reiniciaba la edad con una siembra nueva. **Faltaba solo la fase y la fecha** → casilla *"Esta siembra arrancó el cultivo de nuevo"*. |
| **P7** | 🟡 **C9 · Presupuesto mensual de mano de obra** | Diferenciar "caja menor" de "presupuesto de obra". | ✅ **E3-a** `b109b4b` (`presupuestoObraMensual`, tarjeta y alertas propias). |
| **P8** | 🟢 H4 copy · H5 categorías · H6 comentario · H7 `otro` en caja | Arreglos chicos de alto retorno. | ✅ **E0** `7533d94`. |
| **P9** | ⬜ **R3 · Puerta de entrada** | Ya decidido (Gate 0). Sigue vigente. | ✅ **E6** `09797ea` · `4d496bd`. |

> **Lectura:** **P1 es el que abre todo lo demás.** El "mismo terreno" es la pieza que
> falta para que los gastos, la obra y el rendimiento tengan dónde apoyarse.

---

## 5 · FRENTES DE TRABAJO PROPUESTOS (W1-W5)

| | Frente | Aborda | Tamaño | Estado 2026-10-13 |
|---|---|---|---|---|
| **W1** | **El terreno** — noción de espacio compartido y **reparto de costos** entre cultivos del mismo suelo | C2, C3, P1 | 🔴 XL · requiere su propio Gate | 🟡 **W1-a hecho** `a360ad7` (tabla, CRUD, sección, selector). **W1-b/d descartados** (sin reparto). **W1-c sin diseñar.** |
| **W2** | **Rendimiento y referencias** — producción ÷ ha / ÷ planta, con tablas **editables por región** (mismo patrón que A2) | C7, C13, C14, C15, P2 | 🔴 L | ✅ **E4** `b4241f8`. **Sin tabla de región (C14 rechazada)**; la referencia es su meta anual. C15 ya se pinta en el estado de resultados. |
| **W3** | **La venta real** — deducciones, comisión, estado de pago | H8, C16, P3 | 🟡 M | ✅ **E1** `f911858`. Motivo de deducción libre (no lista cerrada); estado **Pagado / Por cobrar**. |
| **W4** | **La vida del cultivo** — edad por especie, reposición/despojo, "debería estar rindiendo" | H1-H3, C5, C6, P4, P6 | 🔴 L | 🟡 **H1-H3** `3ec1a08` + **E5** `a9bb807` hechos. **"Debería estar rindiendo" existe como rótulo pero NO como alerta.** **C6 despojo/reinicio: ABIERTO.** C5 rechazada. |
| **W5** | **La obra del día** — planilla por jornada ligada al presupuesto mensual | C9, C10, P5, P7 | 🟡 M | ✅ **E3-a/b** `b109b4b` · `f350c2f` — planilla por labor→cultivo, en Reporte/PDF/Excel. |
| **—** | **R3 · puerta de entrada** | E1-E7, P9 | 🔴 L · ya con Gate 0 | ✅ **E6** `09797ea` · `4d496bd`. |
| **—** | **H4-H7 · ajustes chicos** | P8 | 🟢 S | ✅ **E0** `7533d94`. |

---

## 6 · GATE 1 · DECISIONES PENDIENTES

1. **¿Por cuál frente empezamos?** (mi lectura: **W1 primero**, porque todo lo demás se
   apoya en "qué terreno es").
2. **W1 · ¿cómo se reparte?** — ¿proporcional a hectáreas? ¿lo elige él cada vez? ¿regla
   fija por cultivo? *Esto es decisión de UI/comportamiento → se analiza antes de código.*
3. **W2 · ¿las referencias se usan cómo?** — propongo: **tabla editable en Ajustes**
   (patrón A2), **nunca números duros en el copy**, y **nunca alertas duras** contra la
   referencia (solo "tu producción vs la de tu propia finca").
4. **W4 · ¿el umbral de edad deja de ser fijo?** — por ciclo, por especie, o a mano.
5. **¿R3 corre en paralelo o espera?** (R3 no depende de W1-W5).
6. **¿Guardo/actualizo este plan en disco?** — este archivo.

---

## 7 · NOTAS PARA RETOMAR

- Tests patrón: `onboarding_flow_test.dart` (usa `find.byType(WelcomeOnboardingCard)` —
  **si se conserva el nombre de clase no se toca**), `next_step_service_test.dart`
  (gate, no cambia), `settings_backup_test.dart` (patrón de pantalla con `pumpAndSettle`).
- Índices de campos: diálogo cultivo = [0] nombre · [1] área · [2] plantas · [3] inversión ·
  siembra = [0] plantas · [1] área · [2] costo · resiembra = [0] plantas · [1] perdidas ·
  [2] motivo · [3] costo · pérdida = [0] quedan · [1] motivo · cosecha = [0] cantidad · [1] precio.
- `report_screen.dart` tiene **BOM UTF-8** — no romperlo.
- Site https://miguelalbisortiz.github.io/cafecal/ · ref `ioyqlzhzlvkkebvenqnz` ·
  UID `prueba` = `f409b97c-2abf-4fa7-af50-eec416e50fff`.
- Clave publicable: `sb_publishable_jUbUcE-06TanMm-pQkY2ag_f5LsWgwI`.
- **El PAT del usuario (`sbp_…`) se usó para las 2 migraciones → DEBE REVOCARSE.**
- Su papel: menú de 17 líneas + hoja semanal L-M-M-J-V-S-D · eje = **producto y categoría de
  gasto** · costal = **60 kg** · líneas 15/16 "colinos de plátano" · línea 7 con FECHA ·
  frutas mango/palta/mandarina · 4 jornales + caja menor mensual · el plátano tapa la caja.

---

# 8 · EL FLUJO COMPLETO (Gate 1 · respuesta del usuario, 2026-10-11)

> Aprobado por el usuario: *"ok estoy de acuerdo agregalo"*.
> Este es el **flujo de uso** que debe soportar la app. Cada paso marca 🟢 (ya existe),
> 🟡 (falta, chico) o 🔴 (falta, grande).

## 8.0 · Los 5 principios que gobiernan todo

1. **Todo empieza en la planta y termina en el dinero.**
2. **Si el dato no existe, se oculta — nunca "0".** Caso B: no *"ingresos: $0"* sino
   *"tu café llega en 8 meses"*.
3. **Dos tipos de costo:** **directo** (con cultivo) y **común** (sin cultivo — cerca,
   camino, obrero de toda la finca). Es literalmente la clasificación de Cenicafé y
   la app ya la soporta a medias (`"Cultivo (opcional)"` → Excel *"Sin especificar"*).
4. **Un solo presupuesto de obra para toda la finca**, que baja con cada jornal.
5. **Clasificar es lo que vale.** `$50.000` no sirve; `$50.000 · mano de obra ·
   descolgar · café` sí.

## 8.1 · Los 3 casos de uso

| Caso | Situación | Flujo |
|---|---|---|
| **A · 🟢 Ya produzco** | Café con edad, cobra cosechas | Los 6 pasos completos |
| **B · 🟡 Siembré y aún no produce** | Plátano 7 meses, café nuevo | Pasos 1-3; el **paso 6** cambia: en vez de ganancia, **inversión acumulada + fecha estimada de primer cosecha** |
| **C · 🟡 Todavía no siembro** | Solo inversión/preparación | Pasos 1-2; el reporte dice *"llevas $X de inversión y no hay producción"* |

> ⚪ **Gate 2-a abierto:** ¿al adoptar la app a mitad de año se **carga el histórico**
> o **se empieza desde hoy**? Ambas sirven, dan reportes distintos.

## 8.2 · Los 6 pasos

### Paso 1 · Montar el terreno — *una sola vez* 🟢 (+ 🟡 R3)
Puerta **"¿Qué cultivás?"** → ☕ Café · 🍌 Plátano · 🌱 Otro · **+ Agregar otro** →
**ficha corta** (solo fecha, opcional) → **[ Listo ]** / **[ Completar datos… ]**.
Resultado:

```
MI FINCA
├── ☕ Café     0,5 ha · 300 matas · 2019 · EN PRODUCCIÓN
├── 🍌 Plátano  0,2 ha · 03/2026 · ESTABLECIMIENTO
└── 🥭 Mango    área  · 2022    · ESTABLECIMIENTO (no rinde)
```

### Paso 2 · Gastos operativos e insumos — *cada semana* 🟢
`Registro → Gasto` con: **Categoría** (16) · **Cultivo (opcional)** · Trabajador ·
Fecha · Valor.

**Regla práctica (directo vs común):**

| ¿Le pertenece a un cultivo? | Acción | Se ve como |
|---|---|---|
| ✅ Abono del café | poner **Café** | costo directo del café |
| ✅ Colinos de plátano | poner **Plátano** | costo directo del plátano |
| ❌ Cerca, camino, luz | **dejar vacío** | **costo común ("del fondo")** |

### Paso 3 · Personal por días + presupuesto mensual 🟡 — **la pieza que más falta**
Hoy: **Trabajadores** + **Gasto → Mano de obra → trabajador → días × tarifa** = jornal.
**Falta (W5):** decir **QUÉ labor** y en **qué cultivo**.

```
JORNADA — 14/oct
Qué se hizo:   Descolgar café
Cuadrilla:     4 hombres × 1 día × $50.000 = $200.000
A qué cultivo: Café
Presupuesto de obra: $1.000.000 → quedan $800.000

PRESUPUESTO DE OBRA · OCTUBRE   $1.000.000
 Usado                          $800.000
 ████████████████████░░░░░░░░    80%  ⚠️
```

> ⚠️ **Gate 2-b:** hoy **caja menor mensual** ya descuenta mano de obra y ya alerta
> al 80 %. Con W5 hay que **separar "caja menor" de "presupuesto de obra"** o
> renombrarlos — si no, **dos barras con significados distintos**.

### Paso 4 · Cosecha — *lo que sale de la tierra* 🟢 (+ 🟡 W3)
`Cosecha → producto → cantidad + unidad → destino → VENDIDO` → **la venta nace sola** (F1).
**Falta (W3 / H8):** en café **te descuentan**.

```
Cosecha:    480 kg   (lo que salió de la tierra)
Venta:      400 kg   (lo que te pagaron)
Descuentos:  80 kg   impureza        ← NUEVO
Estado:     Pagado / Por cobrar      ← NUEVO
```

### Paso 5 · Venta — *lo que entra a la caja* 🟢 (+ 🟡 W3)
`Ingreso → cultivo → categoría → cantidad + unidad → cliente → monto →
precio/unit (calculado) → moneda → fecha`. **Ya está.** Falta ver **pagado vs por
cobrar** y el desglose de deducciones.

### Paso 6 · La lectura — *el reporte* 🔴 — **la pieza que más falta**
Ver §8.3.

## 8.3 · Cómo se lee el reporte (ejemplo con la finca de octubre)

### Bloque 1 · ¿Qué pasó con el dinero? 🟢
```
INGRESOS DE OCTUBRE       $2.120.000
GASTOS DE OCTUBRE         $1.740.000
RESULTADO DEL MES       + $380.000  ✅
```
> **Dice:** entraron $2.120.000, salieron $1.740.000.
> **Significa:** la finca **dejó** $380.000. Si da **negativo**, la finca te costó.
> **Hacé:** mirá Bloque 2 para ver qué se comió la plata.

### Bloque 2 · ¿Dónde se fue la plata? 🟡 (falta destacar "Del fondo")
```
Mano de obra ....... $700.000  40%   ← en café, >70% del costo es normal
Fertilizantes ...... $350.000  20%
Transporte ......... $150.000   9%
Fitosanitarios ..... $120.000   7%
Siembra (colinos) .. $90.000    5%
Reparaciones ....... $100.000   6%
Varios ............. $180.000  10%
DEL FONDO (común) .. $250.000  14%
```
> **Significa:** la **mano de obra es tu gasto #1** (esperable según Cenicafé).
> **"Del fondo"** es lo que sirve para **todos** — no hay que atribuirlo a nadie.
> **Hacé:** si "Varios"/"Del fondo" crecen, hay algo sin clasificar.

### Bloque 3 · ¿Quién te da de comer? (por cultivo) 🔴 (falta rendimiento + referencia)
```
☕ CAFÉ    0,5 ha · 300 matas · 7 años
   Cosechado ........ 480 kg (8 sacos)      Vendido ... 400 kg
   Costo/kg .......... $2.150    Costo/ha ... $1.240.000
   Rendimiento ....... 960 kg/ha  [ref: 1.200]  ⚠️

🍌 PLÁTANO 0,2 ha · 7 meses
   Cosechado ........ 1.200 kg (40 racimos)  Vendido ... 1.200 kg
   Costo/kg .......... $625
   Rendimiento ....... 6.000 kg/ha [ref: 15.000]  🔴

🥭 MANGO   4 años · sin producción  → (oculto, no "0")
```
> **Significa:**
> - **Costo/kg = precio mínimo al que no perdés.** Por debajo de $2.150/kg de café, perdés.
> - **Rendimiento = lo que la tierra te da.** Por debajo de la referencia → mal manejo
>   **o la referencia no sirve en tu región** (por eso es **editable en Ajustes**, como A2).
> - **Comparar café vs plátano en el mismo terreno** es exactamente lo pedido.
> - **El mango no aparece → `null` → oculto.** Y está bien.

### Bloque 4 · La obra del mes 🟡 (falta presupuesto separado + planilla)
```
PRESUPUESTO DE OBRA · OCTUBRE  $1.000.000
 Usado                         $800.000   80% ⚠️

PLANILLA DEL MES
 Descolgar café    4 hombres × 2 días = $400.000  ☕
 Abonar café       4 hombres × 1 día  = $200.000  ☕
 Cosechar plátano  2 hombres × 1 día  = $100.000  🍌
 Cerca y camino    1 hombre  × 2 días = $100.000  —
```
> **Hacé:** 80 % con el mes a la mitad → **ajustás el resto o subís el presupuesto**.

### Bloque 5 · Estado de tus plantas 🟡 (falta umbral por especie + reposición)
```
☕ Café     7 años  EN PRODUCCIÓN   plantado 03/2019
🍌 Plátano  7 meses ESTABLECIMIENTO primer cosecha est.: ABRIL 2027
🥭 Mango    4 años  ESTABLECIMIENTO primer cosecha est.: 2027-2028
```
> **Significa:** **Establecimiento** = invirtiendo, no va a dar · **Producción** = ya
> rinde · **Renovación** = se va a reemplazar. La **fecha estimada** es lo que resuelve
> el Caso B: *no es $0, es una fecha*. **Reposición** = al reponer plantas, **la edad de
> esa sección se reinicia** (hoy solo a medias).

### Bloque 6 · Lo que quedó pendiente 🟡 (falta "por cobrar")
```
⚠️ Cosechaste 480 kg y vendiste 400 kg → quedan 80 kg
⚠️ Presupuesto de obra: 80% usado
⚠️ Plátano: primer cosecha en 6 meses
⚠️ Por cobrar: $300.000 a Don Pedro     ← NUEVO
```

## 8.4 · El ciclo que se repite

```
 MONTAR     ¿Qué cultivás? → ficha corta                 1 vez
 ANOTAR     Gasto → categoría → ¿cultivo o fondo?        cada semana
            Trabajador → jornal → labor → obra
 COSECHAR   cantidad + unidad → Vendido └→ crea venta    cuando toca
 VENTA      deducciones + estado de pago └→ entra $$     cuando toca
 LEER       6 bloques → sabés qué hacer                  1×/mes
```

## 8.5 · Diagnóstico honesto

**Ya cierra el círculo (🟢):** montar cultivos con edad/fase · 16 categorías con
directo o "del fondo" · trabajadores con jornal · cosecha→venta automática ·
costo/kg y costo/ha · barra de caja con alerta · alertas cosecha vs venta.

**Hecho desde que se escribió este diagnóstico (todos desplegados):**

| Pieza | Commit |
|---|---|
| **W1-A · "Del fondo" visible** (E2) — "Costos comunes", pintado al final de cada cultivo (`report_screen.dart:541`) | `bd4de00` |
| **W3 · deducciones + por cobrar** (E1) — cantidad, motivo, Pagado/Por cobrar, alerta de ventas por cobrar | `f911858` |
| **W5 · planilla + presupuesto de obra** (E3) — obra separada de caja menor + planilla por labor→cultivo en Reporte/PDF/Excel | `b109b4b` · `f350c2f` |
| **W2 · rendimiento** (E4) — kg/ha y kg/planta del período, meta anual propia por cultivo | `b4241f8` |
| **W4 · vida del cultivo** (E5) — fecha de primera cosecha suya + "debería estar rindiendo desde…" | `a9bb807` |
| **R3 · la puerta** (E6) — "¿Qué cultivás?" + ficha corta | `09797ea` · `4d496bd` |

**Lo que SÍ seguía faltando cuando se escribió esto:**

| # | Pieza | Tamaño | Estado 2026-10-13 |
|---|---|---|---|
| 1 | 🟡 **P6 · C6 — despojo y reinicio de edad** | 🟡 M | ✅ **implementado.** El plan decía *"no existe despojo y replante"* y era **falso**: `edadDeCrop` ya reiniciaba la edad con una siembra nueva. Faltaban **la fase y la fecha**, y eso es lo que hace la casilla *"Esta siembra arrancó el cultivo de nuevo"*. |
| 2 | 🟢 **Alerta "debería estar rindiendo" en Inicio** | 🟢 S | ✅ **implementado.** `AlertRule.firstHarvestOverdue`, severidad `warning`, **tope de 12 meses**, se apaga con la primera cosecha. |
| 3 | 🟡 **W1-c · terreno en Reportes/PDF/Excel** | 🟡 M | ✅ **Descartado (2026-10-15).** **Sin W1-b no hay gasto de terreno**, así que solo agruparía sin mover ningún número — cae en la regla "si no se usa para algo concreto, no se pide". |

> **Conclusión (ACTUALIZADA 2026-10-13):** el **esqueleto ya es el correcto y ya
> tiene carne.** **No falta ninguna pieza grande** de las que este documento pedía.
> Lo único sin resolver es **W1-c**, y solo debe avanzar si se le encuentra un
> uso concreto.
> Los 3 casos (A, B, C) cierran con el mismo flujo: una sola forma de trabajar
> que sirve **tanto si ya producís como si recién sembrás**.

---

# 9 · ORDEN DE EJECUCIÓN PROPUESTO (Gate 2)

> ✅ **EJECUTADO INTEGRO (2026-10-11 → 2026-10-13).** Esta sección se conserva
> como registro de lo que se decidió y en qué orden. **No es una lista de tareas.**

| Etapa | Frente | Commit | Tamaño real vs estimado |
|---|---|---|---|
| **E0** | Ajustes chicos (H4-H7) | `7533d94` | 🟢 S · como se estimó |
| **E1** | La venta real (W3) | `f911858` | 🟡 M · como se estimó |
| **E2** | El fondo (W1-A) | `bd4de00` | 🟢 S-M · como se estimó |
| **E3** | La obra del día (W5) | `b109b4b` · `f350c2f` | 🟡 M · como se estimó |
| **E4** | El rendimiento (W2) | `b4241f8` | 🟡 M · **no 🔴 L**: la tabla de referencia se rechazó |
| **E5** | La vida del cultivo (W4) | `a9bb807` | 🟡 M · **no 🔴 L**: la tabla de especies se rechazó |
| **E6** | La puerta (R3) | `09797ea` · `4d496bd` | 🟡 M · **no 🔴 L** |

> Los Gate de §9.3 se resolvieron **en el código**, no en acta. La columna
> "Decisión tomada" de cada uno está en el **§0.3 de arriba** (sección
> "Descartados por decisión explícita").

> Regla por etapa: **decidir → implementar → `flutter analyze` + `flutter test` →
> commit (stageo explícito) → migración (si aplica) → deploy → verificar SHA256.**
> Las migraciones **SIEMPRE antes del deploy correspondiente**.
> *(Sigue vigente para lo que venga: se aplicó en W1-a.)*

## 9.1 · La secuencia

```
E0  Ajustes chicos  (H4 H5 H6 H7)   🟢 S      sin migración    1 commit
E1  La venta real   (W3)            🟡 M      1 migración      1-2 commits
E2  El fondo        (W1-A)          🟡 S-M    sin migración    1 commit
E3  La obra del día (W5)            🟡 M-L    1-2 migraciones  1-2 commits
E4  El rendimiento  (W2)            🔴 L      1 migración      1-2 commits
E5  La vida del cultivo (W4)        🔴 L      1 migración      1-2 commits
E6  La puerta       (R3)            🔴 L      sin migración    2 commits
```

## 9.2 · Por qué EN ESTE ORDEN

1. **E0 primero — lo gratis.** Cuatro arreglos chicos, bajo riesgo, suben la confianza
   y desbloquean H4 (que ya funciona pero no se comunica).
2. **E1 después — cerrar la fuga de plata.** Es **lo que más dinero le está escondiendo
   al usuario hoy**, y es **mediano**. Además, **deja los kg correctos** (producido vs
   pagado) de los que **depende E4**.
3. **E2 después — hacer visible lo que ya existe.** **Casi sin migración**, y **es el
   suelo sobre el que se apoya E3** (la planilla necesita saber si un jornal es directo
   a un cultivo o "del fondo").
4. **E3 después — el flujo de trabajo real.** Ya con E2 claro, **separamos presupuesto
   de obra de caja menor** y agregamos la planilla por jornada.
5. **E4 después — la inteligencia.** Con los kg limpios de E1, **kg/ha y kg/planta**
   salen bien, y recién ahí tiene sentido la tabla de referencia editable.
6. **E5 después — el ciclo de vida.** Umbral por especie y reposición. **Independiente**,
   se deja para el final porque **no bloquea a nadie**.
7. **E6 al final — la puerta.** Es **lo único que ve un usuario nuevo**, pero **no afecta
   a los existentes** (`needsOnboarding` = 0 crops y 0 sowings). Al último, **ya con el
   producto sano**, y porque **W4 (E5) deja el terreno listo** para que al tocar
   "Mango" la app sepa que mango tarda 3-5 años.

**Dependencias explícitas:**
```
E1 ──→ E4     (rendimiento usa kg producidos, no kg pagados)
E2 ──→ E3     (la planilla necesita directo vs "del fondo")
E5 ──→ E6     (al tocar la especie en la puerta, ya conoce su umbral)
```

## 9.3 · Qué decide el usuario ANTES de cada etapa

| Etapa | Decisión pendiente (Gate) |
|---|---|
| **E0** | **H7:** ¿`'otro'` sigue descontando de caja menor, o deja de hacerlo? · **H5:** ¿qué categorías nuevas exactamente? (crédito/intereses, cercas/inversión, seguros) |
| **E1** | ¿Qué deducciones se nombran? (impureza, humedad, comisión, flete) · ¿el estado de pago es solo **pagado/por cobrar** o también **parcial**? |
| **E2** | ¿Cómo se llama en pantalla: *"Del fondo"*, *"Costos comunes"*, *"Sin cultivo"*? · ¿se ve en Inicio o solo en Reportes? |
| **E3** | ¿**Presupuesto de obra separado** de caja menor, o **renombrar** lo actual? · ¿La planilla es **por jornal** o **por día completo de cuadrilla**? |
| **E4** | ¿La referencia se usa **solo informativa** (sin alertas duras) o **marca roja** si se queda muy abajo? · ¿rendimiento por **hectárea**, por **planta**, o ambos? |
| **E5** | ¿El umbral de edad deja de ser fijo? (por ciclo / por especie / a mano) · ¿**despojo y replante** reinicia la edad de todo el cultivo o solo de la sección? |
| **E6** | *(Gate 0 ya cerrado)* — solo falta **corte 1 (puerta) y luego corte 2 (ficha)**, o **todo en un commit**. |
| **Global** | **Gate 2-a:** ¿se carga el **histórico** al empezar, o se empieza **desde hoy**? |

## 9.4 · Rutas alternativas

- **Ruta "rápida"** (si quiere valor en 3 etapas): **E0 → E1 → E2** y ahí **parar a
  re-evaluar**. Son las tres más baratas y de mayor retorno.
- **Ruta "puerta primero"**: **E0 → E6 → E1 …** si prioriza la primera impresión de
  usuarios nuevos por sobre el control de dinero. *No la recomiendo: al usuario actual
  no le cambia nada y retrasa la fuga de plata.*
- **R3 en paralelo:** técnicamente es independiente y podría correrse al lado de
  cualquier etapa. *Lo desaconsejo mientras el usuario decida solo una etapa a la vez.*

## 9.5 · Tamaño total estimado

| Etapa | Tamaño | Migración | Commits |
|---|---|---|---|
| E0 | 🟢 S | no | 1 |
| E1 | 🟡 M | 1 | 1-2 |
| E2 | 🟡 S-M | no | 1 |
| E3 | 🟡 M-L | 1-2 | 1-2 |
| E4 | 🔴 L | 1 | 1-2 |
| E5 | 🔴 L | 1 | 1-2 |
| E6 | 🔴 L | no | 2 |
| **Total** | — | **4-5** | **8-11** |

## 9.6 · Gate 2 · lista de decisiones para arrancar

1. **¿Aprobamos la secuencia E0 → E6?**
2. **¿Empezamos por E0?** (H5, H6, H7 — chiquito, sin migración)
3. **¿O preferimos la ruta "rápida" E0 → E1 → E2 y parar?**
4. Responder las decisiones de la tabla §9.3 de la etapa elegida.
5. **Gate 2-a (histórico)** — conviene resolverlo **antes de E1**, porque define si
   el reporte del primer mes es "del mes" o "acumulado desde el inicio".
