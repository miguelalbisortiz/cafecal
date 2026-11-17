---
prd: pendiente (solo Tanda 3)
status: IN_PROGRESS
tanda1: DONE 2026-11-17_0943
tanda2a: DONE 2026-11-17_1015
tanda2b: DONE 2026-11-17_1033
tanda2c: DONE 2026-11-17_1049
created: 2026-11-17_0918
source:
  - docs/analysis/2026-11-17_tipos-de-cultivo.md
  - docs/analysis/2026-11-17_calculos-recomendaciones.md
---

# Plan: mejoras en cultivos y recomendaciones financieras

## Objetivo

Convertir los cálculos que la app ya hace en **acciones claras** para el pequeño
cafetero, y corregir los datos que hoy se pierden o se rotulan mal, sin inventar
cifras ni modelar entidades que la práctica no pida.

## Recomendación

Tres tandas en este orden. La primera es barata y recupera confianza; la segunda
completa los datos; la tercera es la que ayuda a **crecer** y exige PRD.

| Tanda | Qué | Por qué primero | Riesgo |
|---|---|---|---|
| 1 | Acción en «Qué hacer», terreno al crear, copy que miente | Corrige decisiones y confianza con cambios mínimos y sin esquema | Bajo |
| 2 | Altas cortas completas y paridad pantalla/PDF/Excel | Sin área y terreno, kg/ha y costo/kg no existen o se tuercen | Medio |
| 3 | Recomendaciones de negocio (stock, margen, comprador, caja) | Es el valor que hoy no se entrega; requiere PRD y decisiones | Medio |

**No hacer todavía:** catálogo de variedades, sombra/sol, densidad, recepa o
asocio como entidades. La regla del pack es validar contra la práctica antes de
modelar; hoy no hay evidencia de que haga falta.

## Impacto esperado

No se prometen porcentajes de mejora: no hay datos de una finca real en esta
sesión. El impacto se mide por **mecanismo** y por criterios observables.

| Cambio | Mecanismo | Cómo se comprueba |
|---|---|---|
| `suggestion` restaurada | El agricultor ve qué hacer, no solo qué está mal | Cada fila de «Qué hacer» lleva acción en pantalla, PDF y Excel |
| `terrenoId` al crear | El gasto del lote cae donde debe; costo/kg por cultivo deja de torcerse | Test: cultivo creado con terreno conserva `terrenoId` |
| Copy corregido | La app nombra lo que el agricultor ve en el campo | «variedad» → «cultivo»; «transitorio» → «Anual»; subtítulo del aporte dice la verdad |
| Altas cortas completas | Más cultivos con área y unidad → kg/ha y costo/kg calculables | Conteo de cultivos sin área/terreno antes y después |
| Paridad de exportes | La decisión viaja fuera del teléfono con la misma información | `export_parity_test` + conclusión y compradores presentes |
| Recomendaciones nuevas | Stock, margen por cultivo, comprador y caja se vuelven decisión | Adopción: reportes con al menos una recomendación accionable |

Límite honesto: la app mejora la **calidad de la decisión** y evita errores
silenciosos; no garantiza más ingreso por sí sola.

## Tanda 1 · Confianza y acción (sin PRD)

> Ejecutada y verificada el 2026-11-17 09:43. Evidencia:
> `docs/reports/2026-11-17_0943_tanda1-cultivos-y-recomendaciones.md` y
> `docs/audits/2026-11-17_0943_tanda1-cultivos-y-recomendaciones.md`.

### 1.1 Devolver la acción a «Qué hacer» — P0
- Qué: `RecommendationService.derive` copia `title` y `message`, descarta
  `suggestion` (`lib/services/recommendations.dart:47-52`).
- Cómo: propagar `suggestion`; los tres pintadores ya reciben la recomendación
  (`report_screen.dart:1971-1996`, `pdf_export_service.dart:1779-1789`,
  `excel_export_service.dart:1969-1982`).
- Test en rojo: una recomendación derivada conserva la sugerencia; el texto
  aparece en pantalla, PDF y Excel.
- Aceptación: diagnóstico + acción en la misma fila, sin desbordes con el texto
  más largo del ARB.

### 1.2 Terreno al crear desde Cultivos — P0
- Qué: el editor entrega `form.terrenoId` (`crop_editor_dialog.dart:287`) y
  `crops_screen.dart:287-302` no lo pasa a `addCrop`.
- Cómo: pasar `terrenoId` en esa llamada. Sin esquema, sin backfill.
- Test: crear con terreno elegido → `crop.terrenoId` igual al elegido.
- Aceptación: cultivo nuevo conserva el lote; los viejos se corrigen editando.

### 1.3 Copy que contradice el código — P1
- `Nueva variedad` / `+ Nueva variedad…` → «cultivo» (`app_es.arb:508-509,617`).
- `transitorio` → «Anual» (`app_es.arb:70`).
- `contributionSubtitle` dice que el lote no se reparte, pero sí se reparte por
  área (`app_es.arb:1606`; `crop_totals.dart:104-113`).
- Test: coherencia de Ayuda y orden de placeholders; ES y EN.
- Aceptación: ningún texto promete lo que el código no hace.

**Gate Tanda 1:** `flutter analyze` del proyecto entero + `flutter test`
(línea base 1365) + tests de l10n. Sin commit ni push sin verbo explícito.

## Tanda 2 · Datos completos y paridad (sin PRD, sí decisiones de UI)

> 2.1 ejecutada y verificada el 2026-11-17 10:15 (Tanda 2A). Evidencia:
> `docs/reports/2026-11-17_1015_tanda2a-altas-cortas-contexto.md` y
> `docs/audits/2026-11-17_1015_tanda2a-altas-cortas-contexto.md`.
> 2.2 ejecutada y verificada el 2026-11-17 10:33 (Tanda 2B). Evidencia:
> `docs/reports/2026-11-17_1033_tanda2b-paridad-exportes.md` y
> `docs/audits/2026-11-17_1033_tanda2b-paridad-exportes.md`.
> 2.3 y 2.4 siguen pendientes.

### 2.1 Altas cortas con contexto — P1 ✅ DONE
- Qué: Registro y Siembras crean solo nombre + moneda; el banner para completar
  se descarta para siempre (`register_screen.dart:401-433`,
  `sowing_screen.dart:325-359`, `crop_setup_prompt.dart:22-33`).
- Cómo: ofrecer terreno, área y unidad como opcionales en el alta corta; que
  «Ahora no» posponga, no bloquee futuros cultivos; el prompt debe recibir
  terrenos (`crop_setup_prompt.dart:78-87`).
- Riesgo: más fricción en el registro rápido. Mitigación: opcionales y un solo
  paso, con «completar luego» visible por cultivo.
- Aceptación: se puede crear rápido y completar después sin perder el aviso.

### 2.2 Paridad de los tres pintadores — P1 ✅ DONE
- «Conclusión del período» solo vivía en pantalla (`report_screen.dart:285-307`).
- PDF callaba cuando «Qué hacer» estaba vacío (`pdf_export_service.dart:1779-1789`).
- Excel no traía «Principales compradores».
- Cómo: helper compartido `report_period_records.dart` para la selección del
  período; el mismo `ReportInsightsService` en los tres pintadores; conclusión
  en Resumen y cuerpo del PDF; compradores y proveedores top 3 en Resumen;
  `reportNoRecommendations` en el PDF.
- Guarda de páginas: revisada el 2026-11-17 10:33. Sigue en **4** en el fixture
  congelado: las secciones nuevas entran en la paginación actual y no añaden
  página. Sin cambio de número, sin cambio de comentario.
- Aceptación: 4 tests nuevos de paridad + `export_parity_test` verde + suite
  completa 1433/1433.

### 2.3 Rotular las dos atribuciones — P1 — DONE 2026-11-17_1049
- Reparto por hectáreas (desglose y costo/kg) vs aporte sin reparto (producto).
  No es bug; el riesgo es comparar cifras de distinta regla.
- Cómo: copy de tarjeta/ayuda que diga qué regla usa cada cifra.
- Aceptación: dos tarjetas no pueden confundirse leyendo su etiqueta.
- Cierre: `contributionSubtitle` corregido (el aporte **no** reparte) y clave
  corta `cropBreakdownSplitNote` en pantalla, PDF y Excel. Rojo 6/6 → 4 nuevos
  guardas → 1437/1437. Sin tocar el cálculo.

### 2.4 Aviso de áreas que no cuadran — P2 — DONE 2026-11-17_1049
- Si la suma de áreas de un terreno supera el terreno, avisar sin bloquear
  (puede ser asocio legítimo). Nunca corregir automáticamente.
- Aceptación: aviso solo cuando ambas áreas existen; no aparece sin datos.
- Cierre: verificado, sin código nuevo. `terreno_area.dart:25` calcula `over`
  solo si ambas áreas existen; banner ámbar en `crops_screen.dart:217-254` y
  ayuda en el editor. No muta `areaHa`. 63/63 tests de áreas y terrenos.

**Gate Tanda 2:** analyze + test + prueba manual con datos de finca real
(10 ha, 3 cultivos, 4 trabajadores), sin arreglar hallazgos en caliente.
- Cierre en código: analyze limpio, 1437/1437 suite, 2.4 en 63/63. La prueba
  manual con finca real sigue pendiente: no hay datos reales en esta sesión.

## Tanda 3 · Crecer con los datos que ya existen (PRD obligatorio)

### 3.1 PRD primero
Crear `docs/prds/{fecha}-recomendaciones-de-negocio.prd.md` y decidir una por
una, con recomendación delante. Orden propuesto por fuerza del dato:

1. **Stock sin vender** — `cosechaKg − ventaKg` en 12 meses; si > 0, avisar.
2. **Margen por cultivo y por hectárea** — ya existe el desglose; convertirlo en
   «dónde poner la mano de obra».
3. **Concentración de comprador** — `%` de ventas del principal cliente.
4. **Descuento del comprador** — `kg descontados / kg entregados`.
5. **Brecha de rendimiento propio** — actual vs promedio de ≥2 años.
6. **Días de caja restantes** — al ritmo de gasto actual.

Reglas para todas: moneda única o se oculta; `null` → oculto; kilos sin peso se
listan, no se suman; el texto dice qué hacer y con qué cifra.

### 3.2 Implementación por recomendación
- Clave ARB ES/EN, placeholders en el orden de la frase.
- Misma regla en pantalla, PDF y Excel.
- Test en rojo por recomendación y guarda de que no inventa datos.
- Prioridad de entrega: 1 → 2 → 3; luego 4 → 5 → 6.

### 3.3 Tipo de cultivo explícito (opcional, solo si hay error real)
- Hoy el café se detecta por el nombre (`product_contribution.dart:307-315`).
- Solo si aparecen cultivos mal clasificados: PRD + campo `tipo` + migración
  aplicada **antes** del deploy + sync que envíe el campo siempre, incluido
  `null` (evitar PGRST204).
- No hacer backfill automático sin consentimiento.

**Gate Tanda 3:** PRD aprobado, analyze + test, prueba con datos reales y
reporte en `docs/reports/`. Solo entonces `/verify` y `/audit-report`.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| `suggestion` larga desborda PDF/Excel | Probar con el texto más largo del ARB |
| Cambios de ARB rompen generado | Regenerar, normalizar CRLF a LF, comparar generados |
| `Ahora no` sigue bloqueando | Cambiar a posposición por cultivo, no global |
| Copiar terreno sin ajustar área tuercen el reparto | Pedir área nueva y avisar; nunca repartir sin áreas completas |
| Recomendación nueva con dato faltante | `null` → oculto; lista de pendientes cuando toca |
| Migración de tipo de cultivo antes del deploy | SQL primero, verificar columna/FK, después publicar |

## Dependencias

- Tanda 3: PRD aprobado por el usuario.
- Tanda 3.3: migración de Supabase aplicada por el usuario antes del deploy.
- Sin dependencias externas para Tandas 1 y 2.

## Criterios de éxito del plan

- [x] «Qué hacer» muestra diagnóstico **y** acción en los tres pintadores.
- [x] Cultivo creado con terreno lo conserva.
- [x] Ningún texto contradice el código (ES/EN).
- [ ] Más cultivos con área/terreno y métricas calculables. Mecanismo listo en
  2.1; el conteo real requiere prueba con datos de finca.
- [ ] Pantalla, PDF y Excel dicen lo mismo.
- [ ] Al menos una recomendación de negocio aprobada e implementada con test.
- [ ] Sin commit ni push sin verbo explícito del usuario.
