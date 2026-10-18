# Sesión — sábado 17 de octubre de 2026 (la notación sigue al idioma)

Estado al cierre. Archivo completo en `2026-10-17-la-notacion-sigue-al-idioma.md`.

Sexta tanda del día. Anteriores de hoy: `2026-10-17-cifras-con-su-codigo-y-guardas.md`,
`2026-10-17-alerta-moneda-signo-y-f4.md`, `2026-10-17-campo-de-fecha-en-perdidas.md` y
`2026-10-17-entorno-motores-plugins-y-mcp.md`.

---

## 1. ¿Dónde quedó el proyecto?

La tanda empezó como un barrido de la familia que se cerró ayer —«¿alguien pinta dinero por su
cuenta?»— y terminó en la regla que faltaba: **la notación de las cifras sigue al idioma**.
`settings.locale` era un campo que nadie editaba (Ajustes solo toca el idioma), así que se quedaba
clavado en `es_CO`: con la app en inglés salían las fechas y los conteos del generador l10n en
inglés, pero la plata y los kilos con la notación del español.

| Rama | Commit | Estado |
|---|---|---|
| `main` | `3a5c970` | sincronizada con `origin/main` |
| `gh-pages` | `3b49a79` | sincronizada |

Huella en producción:

`584C22F42DBAE545B5EF5CD8AC92E11F0422BB32ACC76695843E89B953E6E17D` · 4.796.882 bytes
(antes: `2C453D77…` · 4.794.925).

Un solo commit de código:

| Commit | Qué |
|---|---|
| `3a5c970` | **cifras: la notación de los números sigue al idioma, y el kg con ella** |

Gate antes de commit y deploy: `flutter analyze` limpio (esta vez sobre el proyecto entero,
`tool/` incluido) y **946/946** (venía de 943).

---

## 2. Lo que se tocó la app

**a · El barrido: nadie pinta dinero fuera de `formatAmount`.** Los cinco helpers de número que se
revisaron —`_num` y `_numKg` de Reportes y PDF, `_pctOf` de Excel, `_decimal`— son de cantidades,
conteos, hectáreas, días y porcentajes; el `_num(e.value)` que parecía un monto es el **conteo** de
cosechas por destino. Los `$` que quedan en `lib/` son los diez de las razones en prosa («por cada
$100 vendidos»), la excepción acordada que ya vigila `l10n_money_notation_test`. **Nada que
arreglar ahí.**

**b · El `kg` del motor de alertas.** `_kg` formateaba con `es_CO` clavado, así que un aviso en
inglés decía «you sold 1.200,0 kg». Ahora recibe el locale del servicio, igual que `_money`.

**c · La regla: la notación sigue al idioma.** `FarmSettings.numberLocale` se deduce del idioma
(`en` → `en_US`, resto → `es_CO`) y **el campo `locale` desaparece del modelo**. Todo lo que
formatea cifras pasa por ahí: pantallas, widgets, alertas, PDF, Excel y HTML (≈20 sitios). Para el
español no cambia un número: la salida es idéntica.

**d · La nube no cambia de forma.** El payload de sincronización sigue mandando su columna
`locale`, ahora con el valor deducido, así que la tabla no necesita migración.

**e · Los ajustes viejos se curan al leerse.** `fromJson` ya no lee la clave `locale` guardada:
quien tenía `language: 'en'` con `locale: 'es_CO'` queda en inglés al abrir, sin migración y sin
tocar nada. `mergeBackupSettings` deja de fusionar el campo viejo. Mismo patrón de la casa que la
limpieza de siembras: **los datos viejos se arreglan al entrar, no con una migración nueva**.

**f · Los dos tools de desarrollo** construían un `FarmSettings` con `locale:`
(`generate_report_tool`, `demo_report_tool`): el primero pasa a leer `language` de la fila y el
segundo deja el idioma por defecto (misma salida). Sin esto, `flutter analyze` sobre el proyecto
entero se cae — de ahí que el gate se corra **sin acotar a `lib test`**.

### Las pruebas nuevas (tres)

| Prueba | Qué vigila |
|---|---|
| `test/number_locale_follows_language_test.dart` | la pantalla de verdad (`MovementsScreen`) con los ajustes en español (`COP 1.500`) y en inglés (`COP 1,500`), cada uno con la notación contraria **prohibida** |
| (mismo archivo) | la cura de un ajuste viejo: `fromJson` con `language: 'en'` y `locale: 'es_CO'` guardado sale en `en_US` |
| `test/alert_service_test.dart` | el aviso del vendido, en los dos idiomas |

---

## 3. Tests y rojo/verde

Todo verificado **fallando primero** (apagando la pieza a mano, que es la regla cuando el arreglo ya
está puesto):

- **el `kg`**: con el `es_CO` devuelto a `_kg`, el aviso en inglés cae con
  `Actual: 'The problem: … you sold 1.200,0 kg of Cafe, but only recorded 500,0 kg…'`.
- **la notación**: con `numberLocale` fijo en `es_CO`, el caso inglés cae con
  `Found 0 widgets with text "COP 1,500"` — la app en inglés pintaba `COP 1.500`. **El caso español
  sigue pasando con la pieza apagada**, que es la prueba de que el arreglo es aditivo.
- **los tests que armaban su texto esperado con `settings.locale`** (reporte, planilla, cosecha,
  curva mensual) pasaron a la regla nueva. Sin eso el proyecto no compilaba, así que la deuda
  quedó a la vista sola: cuatro archivos de test leían el campo viejo.

---

## 4. Deudas y avisos

🟡 **`deploy.ps1` no lo cubre ningún test** — punto ciego declarado, sin cambios.

🟡 **Las razones en prosa conservan el `$`** («por cada $100 vendidos»), a propósito: es una
proporción, no un monto. La excepción está escrita y acotada en `l10n_money_notation_test`.

🟡 **`settings.locale` sobrevive en la base y en los respaldos viejos** como dato muerto: ya nadie
lo lee, y escribirlo no hace daño. Limpiarlo sería una migración para nada.

🟢 **El barrido dejó escrito qué NO es dinero**: `_num`, `_numKg`, `_pctOf` y `_decimal` son de
cantidades, conteos, hectáreas, días y porcentajes. Si algún día uno empieza a recibir un monto, la
revisión está hecha y a mano.

---

## 5. Hallazgos que NO se abrieron

1. **Un selector de notación aparte en Ajustes** (app en inglés con números en español): se
   descartó al decidir la regla. Si alguna vez hace falta, el sitio único es `numberLocale`.
2. **El campo «kilos recolectados» del jornal «Cosechar»** (Tanda 2 de la cosecha derivada): sigue
   esperando evidencia de uso real.
3. **W1-c · agrupar cultivos por terreno en Reportes**: sigue esperando un uso concreto.

---

## 6. Pendientes de producto

1. **La verificación manual del usuario** que lista el plan del ciclo (§Verificación manual):
   moneda con y sin internet, respaldo P1, banner L2.5b, PDF y Excel de período mezclado, borrado
   real, `/backup.html` y la cosecha con precio → venta.
2. **El PAT de Supabase sin revocar** (punto 1 de la auditoría de secretos del 2026-10-17).
3. **Tanda 2 de la cosecha derivada**, solo si hay evidencia de uso real.

Nada urgente y nada roto.

---

## 7. Cómo continuar

Leer este archivo y `docs/LEARNING.md`; el estado de la app es el de la tabla de §1.

**Reglas de la casa que no se negocian:**

- `null` → oculto, nunca 0. Nunca inventar cifras ni hechos.
- Una sola función para una sola regla.
- El **código** de moneda es el único indicador (`COP 1.500`), nunca el símbolo.
- La **notación** de las cifras sigue al **idioma** del usuario (nuevo, 2026-10-17).
- Cada arreglo con su test, **verificado fallando sin su arreglo** (y si el código ya está, se apaga
  la pieza a mano para verlo caer).
- Un test que no atraviesa el camino real es una **guarda**, no una prueba.
- Stageo explícito; **nunca** `git add -A`.
- `docs/plans/` no se commitea sin verbo.

---

*Última actualización: 17 de octubre de 2026.*
