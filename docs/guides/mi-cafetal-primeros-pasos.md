# Mi Cafetal — Guía de primeros pasos

Bienvenido a **Mi Cafetal App**, la aplicación para llevar las cuentas de tu finca:
cuánto inviertes, cuánto produces y cuánto vendes — por cultivo, por mes y por año.

Esta guía te lleva de cero a tus primeros registros en 10 minutos.

---

## 1. ¿Para qué sirve la app?

- **Saber si ganas o pierdes** con cada cultivo (ROI y balance).
- **Ver tus gastos y ventas** por mes y por año.
- **Llevar tu producción**: siembras (plantines/plantas) y cosechas (kg, arrobas…).
- **Detectar problemas a tiempo** con alertas: sin ventas, precios bajos, pérdidas
  repetidas, gastos sin cultivo asignado, ventas que no cuadran con lo cosechado.

La app nunca adivina tu producción: **los números salen de lo que tú registras.**
Cuanto más completo sea tu registro, más útiles son los resultados.

---

## 2. Conceptos clave

| Concepto | Qué significa |
|---|---|
| **Cultivo** | Cada actividad de tu finca: Café, Plátano, Verduras… Cada uno con su fase de vida, ciclo y unidad preferida. |
| **Fase de vida** | `Establecimiento` (plantío joven que aún no produce), `Producción` (ya cosecha) o `Renovación` (lo replantaste). |
| **Ciclo** | `Perenne` (café, plátano: producen varios años) o `Anual` (hortalizas: un ciclo por siembra). |
| **Siembra** | Registro de plantas puestas (y su área). |
| **Resiembra** | Remplazo de plantas perdidas (bajas) de un plantío ya sembrado. |
| **Cosecha** | Registro de lo que recogiste, con su cantidad, unidad y destino. |
| **Destino de la cosecha** | `Vendido`, `Almacenado` o `Pérdida`. |

💡 **Fase = caso A o B.** En `Establecimiento`/`Renovación` la app te lleva a registrar
la **siembra**. En `Producción` no te exige siembra: la finca ya está establecida y
solo registras gastos, cosechas y ventas.

---

## 3. ¿Dónde entro cada dato?

| Situación | Pantalla | Qué pide |
|---|---|---|
| Quiero definir los cultivos de mi finca | **Cultivos** (menú ⋮ arriba a la derecha) | Nombre, fase, ciclo, unidad preferida, área (ha), plantas vivas |
| Voy a sembrar o resembrar | **Siembras** (menú ⋮) | Tipo (siembra/resiembra), plantas, área, bajas y motivo |
| Recogí producción | **Cosechas** (menú ⋮) | Cantidad, unidad, destino de la cosecha |
| Compré insumos, pagué mano de obra… | **Registrar** (pestaña central) | Gasto → categoría, cultivo, monto, fecha (opcional: cantidad, proveedor) |
| Vendí café/plátano… | **Registrar** | Ingreso → categoría de venta, cultivo, monto, fecha (opcional: cantidad y precio por kg) |
| Quiero ver el resumen | **Resumen** (primera pestaña) | Autocompletado: ingresos, gastos, balance e indicadores |

El orden recomendado por la app es siempre: **cultivo → siembra (si aplica) → gastos →
cosecha → venta**. La tarjeta **"Tu próximo paso"** del Resumen te dice cuál registrar.

---

## 4. Primeros pasos según tu caso

### Caso A — Ya tengo los cultivos sembrados (finca establecida)

1. En **Cultivos**, revisa Café y Plátano: ajústales la **fase a "Producción"** y,
   si conoces el dato, el **área (ha)** y las **plantas vivas**.
2. En **Registrar**, anota los **gastos** del mes (insumos, mano de obra).
3. Cuando recojas, registra la **cosecha** con su destino.
4. Cuando vendas, registra el **ingreso** de la venta.
5. Revisa el **Resumen**: balance e indicadores empiezan a cobrar sentido.

### Caso B — Voy a sembrar algo nuevo (plantío joven)

1. En **Cultivos**, crea tu cultivo (o edita el default) con fase
   **"Establecimiento"** y ciclo **"Anual"** o **"Perenne"**.
2. En **Siembras**, registra la **siembra inicial**: cantidad de plantas y área.
3. Registra los **gastos** de la siembra e insumos (puedes vincular su costo en la
   misma pantalla de Siembras).
4. Mientras el cultivo está en establecimiento, la app **no** te marcará pérdidas:
   es inversión, no producción aún.
5. Cuando esté en producción, sigue el flujo de cosechas y ventas (Caso A).

---

## 5. Ejemplos por cultivo

- **Café (perenne, producción):** vendes por arrobas o sacos. Una cosecha de
  "2 arrobas" equivale a **25 kg** (1 arroba = 12.5 kg); un saco = **70 kg**.
- **Plátano (perenne, producción):** cosechas en racimos. Registra cantidad en
  "racimos" y la venta con cantidad en racimos o kg.
- **Verduras (anual, establecimiento):** cada siembra es un ciclo propio: siembra
  → gastos → cosecha → venta → nueva siembra.

💡 Usa la **unidad preferida** del cultivo para cosechas y ventas; la app convierte
todo a kg para comparar.

---

## 6. Glosario

- **Plantines**: plantas jóvenes del cultivo en establecimiento.
- **Área (hectáreas)**: superficie del cultivo; se usa para indicadores por hectárea.
- **Plantas vivas**: total de plantas vigentes (siembra − bajas + resiembras).
- **Arroba**: unidad de café = **12.5 kg**.
- **Saco**: unidad = **70 kg**.
- **Destino de cosecha**: vendido / almacenado / pérdida.
- **ROI**: cuánto recuperas por peso invertido: `(Ingresos − Gastos) ÷ Gastos`.
  Negativo = el cultivo gasta más de lo que recupera.
- **Balance**: `Ingresos − Gastos` del período. Positivo = ganancia; negativo = pérdida.
- **Sincronizar**: guarda tus datos en la nube (Supabase) para que estén en cualquier
  dispositivo y con respaldo.
- **Alerta**: aviso automático en el Resumen (sin ventas, precios bajos, pérdidas…).
- **Tu próximo paso**: tarjeta derivada de tus datos que te dice qué registrar primero.

---

## 7. Sincronización y respaldo

- Tu información se guarda **localmente** en el dispositivo y se **sincroniza con la
  nube** al entrar (botón de sincronizar en la barra superior).
- Modo invitado (demo): puedes explorar la app con datos de ejemplo; no se
  sincronizan con tu cuenta.
- Respaldos: desde **Configuración** puedes exportar reportes (PDF/Excel).

## 8. Consejo final

Empieza pequeño: un cultivo, un gasto, una venta. La app aprende de tu registro.
Registrar 5 minutos por semana vale más que un mes perfecto que no llegaste a empezar.