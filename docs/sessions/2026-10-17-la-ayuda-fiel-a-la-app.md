# Sesión — sábado 17 de octubre de 2026 (la Ayuda fiel a la app)

Séptima tanda del día. Anteriores de hoy: `2026-10-17-la-notacion-sigue-al-idioma.md`,
`2026-10-17-cifras-con-su-codigo-y-guardas.md`, `2026-10-17-alerta-moneda-signo-y-f4.md`,
`2026-10-17-campo-de-fecha-en-perdidas.md` y `2026-10-17-entorno-motores-plugins-y-mcp.md`.

---

## 1. ¿Dónde quedó el proyecto?

La tanda empezó con una pregunta del usuario: **¿la Ayuda del menú representa y muestra la
funcionalidad y la finalidad de la app ya actualizada?** La auditoría respondió: **el propósito sí,
la funcionalidad a medias** — el flujo, los casos con sus cifras y las equivalencias seguían
exactos, pero la app había crecido por fuera de la guía (terrenos, trabajadores, caja, reporte,
respaldo, idioma y rendimiento por planta no estaban).

Se hizo PRD (con las 8 decisiones del usuario registradas), plan de tres tandas y la
implementación de las dos primeras. La Ayuda pasó de 9 a 16 bloques, con el mapa completo y dos
guardas nuevas.

| Rama | Commit | Estado |
|---|---|---|
| `main` | `a47bdc2` | sincronizada con `origin/main` (más el papeleo de esta sesión) |
| `gh-pages` | `441db97` | sincronizada |

Huella en producción:

`EFC05ADC15E5B0D09FCB1906C35274CDD1A8E847294A34842D8107E29378173A` · 4.806.917 bytes
(antes: `584C22F42DBAE545B5EF5CD8AC92E11F0422BB32ACC76695843E89B953E6E17D` · 4.796.882).

Cuatro commits:

| Commit | Qué |
|---|---|
| `81ccc0c` | **ayuda: unidades completas, sin el título huérfano y con el glosario honesto** (T1) |
| `59db9fc` | **docs: PRD y plan de la ayuda fiel a la app** |
| `a47bdc2` | **ayuda: el mapa completo, seis bloques nuevos y el rendimiento por planta** (T2) |
| (este papeleo) | docs: cierre de la tanda de la Ayuda fiel a la app |

Gate antes de commit y deploy: `flutter analyze` limpio (proyecto entero, `tool/` incluido) y
**950/950** (venía de 946).

---

## 2. Lo que se tocó la app

**a · Las unidades, completas.** La tabla pintaba 5 de las 7 unidades que la app ofrece, y el
cuerpo del texto sí nombraba libras y cargas: entran **libra y carga** a la tabla y los chips suben
a los mismos 7 (kg, lb, arroba, saco, carga, racimo, cajón), en el orden del desplegable. Las dos
filas **ya estaban escritas** en el ARB: solo faltaba pintarlas.

**b · Fuera el copy huérfano.** Se borran `helpExampleTitle` («¿Cómo se ve en la práctica?») y
`helpCropCurrency`/`helpCropCurrencyShort`: nadie las pintaba, y la moneda por cultivo ya no existe
(una sola moneda, decidida al empezar). Pintar el título de los ejemplos se descartó: habría dejado
dos títulos seguidos y el hueco ya lo llenan el título de la sección y el de cada caso.

**c · El glosario deja de prometer lo que no se puede elegir.** «Destino: vendido o pérdida» salió:
el único sitio que registraba un destino (Cosechas) está fuera del menú y la cosecha se deriva de
la venta, así que Reporte solo muestra «vendido». En su lugar, el término que sí se ve:
**«Vendido vs cosechado: cuánto de la cosecha ya salió como venta.»**

**d · El mapa, completo.** «¿Dónde entro cada dato?» pasa de 5 a 11 filas: entran Reporte,
Trabajadores, Jornal, Lote, Configuración e Historial, cada uno con el rótulo real de su pantalla.

**e · Sección nueva «Lo demás que hace la app»** con seis bloques: tus terrenos (lotes) y la
ubicación que **nunca se vuelve a medir sola**, trabajadores y jornales (con su nómina y planilla),
la caja del mes que **se arrastra**, el reporte con sus archivos, el respaldo que **no borra nada**
al restaurar, y el idioma con la notación de las cifras.

**f · Bloque nuevo «¿Y por planta? ¿Cuándo empieza a rendir?»**: los kilos por planta, el promedio
propio de años anteriores (la app mide contra su propia tierra) y la alerta de la primera cosecha
esperada.

**g · La copy cita rótulos que existen.** El texto que traía el PRD citaba dos etiquetas inglesas
que no coinciden con la app: la caja es **«Monthly cash contribution»** (no «amount») y la planilla
**«Monthly timesheet»** (no «the month's work sheet»). En español sí cuadraban («Aporte mensual de
caja», «Planilla del mes»).

**h · Dos guardas nuevas** (ver §3).

### Las pruebas nuevas (dos)

| Prueba | Qué vigila |
|---|---|
| `test/help_no_orphan_keys_test.dart` | ninguna clave `help*` declarada queda sin pintar; y el glosario no vuelve a prometer un destino que no se puede registrar |
| `test/help_menu_map_test.dart` | el menú y la Ayuda hablan de las mismas puertas (si el menú gana una entrada, hay que pasar por la Ayuda o declararla en la lista de permiso: hoy Ayuda y Cerrar sesión), y cada destino de datos aparece **nombrado** |

---

## 3. Tests y rojo/verde

Las dos guardas se vieron **caer antes de su arreglo**:

- **G2 · huérfanas.** Caía listando las 7 reales: `helpCropCurrency`, `helpCropCurrencyShort`,
  `helpExampleTitle`, `helpUnitsCargaRow(+Desc)`, `helpUnitsLbRow(+Desc)`; y con la frase vieja del
  glosario («Destino: vendido o pérdida»). Verde tras los arreglos.
- **G1 · menú ↔ mapa.** Caía con `Found 0 widgets with text "Reporte"` — el destino del menú que la
  Ayuda no nombraba. Verde tras el mapa nuevo.
- La igualdad menú ↔ mapa pasó desde el primer momento: el escaneo ignora la línea comentada de
  «Cosechas» (el camino de restauración).

---

## 4. Deudas y avisos

🟡 **G1 es guarda de contrato, no de verdad semántica**: vigila que el destino esté **nombrado**, no
que esté **bien explicado**. Eso último queda en revisión humana.

🟡 **G2 solo mira las claves `help*`.** Un barrido de todas las claves daría hoy ~96 falsos
positivos (claves usadas con otro receptor o dentro de un `switch`, p. ej. `strings.dart:49`), así
que el alcance se dejó deliberadamente corto y documentado.

🟢 **El barrido de huérfanas es una misión útil**: encontró 5 claves muertas que nadie había visto
(dos de la moneda por cultivo, un título y las dos filas de unidades).

---

## 5. Hallazgos que NO se abrieron

1. **Re-habilitar Cosechas** (que se pueda volver a registrar un destino): otro PRD. La Ayuda ahora
   describe lo que hay, no lo que podría haber.
2. **`backup.html`** (la página web de exportar datos locales, de la versión anterior): fuera de la
   Ayuda, a propósito; se enseña solo el respaldo en archivo de Configuración.
3. **La notación de las cifras dentro de la Ayuda** (que el ejemplo de unidades use la notación del
   idioma): hoy el panel de unidades no cita montos, así que no aplica.

---

## 6. Pendientes de producto

1. **La verificación manual del usuario** que lista el plan del ciclo (§Verificación manual):
   moneda con y sin internet, respaldo P1, banner L2.5b, PDF y Excel de período mezclado, borrado
   real, `/backup.html` y la cosecha con precio → venta.
2. **El PAT de Supabase sin revocar** (punto 1 de la auditoría de secretos del 2026-10-17).
3. **Tanda 2 de la cosecha derivada**, solo si hay evidencia de uso real.
4. **W1-c · agrupar cultivos por terreno en Reportes**, solo con un uso concreto.

Nada urgente y nada roto.

---

## 7. Cómo continuar

Leer este archivo y `docs/LEARNING.md`; el estado de la app es el de la tabla de §1. La Ayuda ahora
se vigila sola: si el menú crece o una clave `help*` queda a medias, la suite cae.

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Una sola función para una sola regla.
- El **código** de moneda es el único indicador (`COP 1.500`), nunca el símbolo.
- La **notación** de las cifras sigue al **idioma** del usuario (2026-10-17).
- La copy que cita un rótulo de la app **cita el que existe** (2026-10-17, nuevo): se verifica
  contra el ARB antes de escribirlo.
- Cada arreglo con su test, **verificado fallando sin su arreglo** (y si el código ya está, se apaga
  la pieza a mano para verlo caer).
- Un test que no atraviesa el camino real es una **guarda**, no una prueba.
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
