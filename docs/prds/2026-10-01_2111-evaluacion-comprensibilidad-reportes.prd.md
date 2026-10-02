---
status: DRAFT
created: 2026-10-01_2111
---

# PRD: Evaluación de comprensibilidad de los reportes de Mi Cafetal + alternativas de mejora

## Contexto

Mi Cafetal es una app Flutter de control de gastos/ingresos para cafetales. La pantalla de Reportes
(`lib/screens/report_screen.dart`, ~1625 líneas) muestra insights, cosechas, nómina, caja,
"vendido vs cosechado" y recomendaciones, y exporta a PDF/Excel. El usuario pide evaluar si
los reportes son comprensibles para una persona promedio y **ver alternativas antes de decidir**
cualquier cambio.

## Problema

No se sabe si el lenguaje, la estructura y la visualización de los reportes permiten que un
usuario sin formación financiera ni agronómica interprete correctamente los datos. Se requiere
una evaluación fundamentada y 2-3 alternativas accionables con pros/contras para decidir.

## Alcance (confirmado con el usuario)

- **Incluye:**
  - Pantalla de Reportes: `lib/screens/report_screen.dart` (secciones: período, insights,
    cosechas, nómina, caja, vendido vs cosechado, "Qué hacer").
  - Exportes: `lib/services/pdf_export_service.dart`, `lib/services/excel_export_service.dart`.
  - Servicios de cálculo que alimentan etiquetas/valores: `report_insights_service.dart`,
    `report_harvest_metrics.dart`, `report_payroll_metrics.dart`, `recommendations.dart`.
  - Glosario existente: `lib/widgets/terminology_guide.dart` y sus claves en `lib/l10n/app_es.arb`.
- **Excluye:** pantalla Home y widgets de gráficos fuera del flujo de reportes; corrección de
  bugs de cálculo (salvo que se detecten como hallazgo); implementación de cambios.

## Usuario tipo / criterio de comprensibilidad

**Usuario general promedio** — adulto con uso básico de apps, sin formación financiera ni
agronómica. Un reporte "cumple" si la persona puede, sin ayuda externa:

1. Entender de qué periodo habla y qué unidad/moneda ve.
2. Saber si el resultado es bueno, malo o neutro (señal explícita, no inferida).
3. Entender qué significa cada métrica (ROI, margen, kg/ha, costo/kg) en lenguaje cotidiano.
4. Saber qué acción tomar o a quién preguntar (los "Qué hacer" deben ser concretos).
5. Interpretar los exportes PDF/Excel sin el contexto de la pantalla.

## Requisitos funcionales

- **RF1:** Entregar una evaluación de comprensibilidad de cada sección del reporte y sus
  exportes, con evidencia (código/cadenas l10n) y una escala clara (cumple / parcial / no cumple).
- **RF2:** Identificar barreras específicas: jerga financiera sin explicar, densidad de
  información, falta de señal bueno/malo, ambigüedad de período/moneda, cifras sin comparación,
  textos de recomendaciones genéricos, exportes sin leyenda.
- **RF3:** Proponer 2-3 alternativas de mejora (por ejemplo: capa de "resumen en lenguaje
  simple", rediseño de secciones con señales visuales, refuerzo del glosario contextual,
  reporte narrativo tipo "carta al dueño"), cada una con alcance estimado, esfuerzo, pros,
  contras y qué requisitos (RF2) resuelve.
- **RF4:** Entregable en documento PRD/evaluación — **sin modificar código de la app**.

## Criterios de aceptación

| # | Criterio |
|---|----------|
| AC1 | La evaluación cubre todas las secciones de la pantalla de Reportes + los dos exportes (PDF y Excel) |
| AC2 | Cada hallazgo cita evidencia concreta (archivo:línea o clave l10n) |
| AC3 | Existe al menos 3 alternativas comparadas en tabla (esfuerzo/impacto/pros/contras) |
| AC4 | Se marca una recomendación clara pero la decisión final queda en el usuario |
| AC5 | Cero cambios en `lib/` (solo documentos en `docs/`) |
| AC6 | Reporte de ejecución en `docs/reports/` (fase 4 del flujo /orchestrate) |

## Fuera de alcance

- Implementar cualquiera de las alternativas (vendrá después de la decisión del usuario).
- Tests funcionales/E2E (no hay cambio de código).
- Corrección de bugs de cálculo detectados (se listan como hallazgos, no se arreglan).

## Riesgos

- **Alcance del reporte:** `report_screen.dart` es muy grande → dividir la lectura por secciones
  entre agentes en paralelo.
- **Sesgo de "decir sí":** se exige escala con "no cumple" y evidencia, no solo elogios.
- **Idioma:** la app es ES/EN (l10n); evaluar principalmente el español (`app_es.arb`).

---

# EVALUACIÓN DE COMPRENSIBILIDAD (Fase 3 — entregable)

> Criterio: **usuario general promedio sin formación financiera ni agronómica.**
> Escala: ✅ cumple / ⚠️ parcial / ❌ no cumple.
> Alcance: pantalla de Reportes + exportes PDF, Excel y balance CSV.

## A. Rúbrica por dimensión

| # | Dimensión | Puntaje | Veredicto | Evidencia clave |
|---|-----------|---------|-----------|-----------------|
| 1 | Período y moneda claros | 4/5 | ✅ | Título grande de período (`report_screen.dart:204`), chip por tarjeta (`:294`), moneda efectiva detectada (`:67-71`), desglose de moneda mixta (`:322-330`). **Pero:** el nombre del archivo exportado siempre asume mes `(_month+1)` aunque el modo sea semana/año (`:1073-1074`, `:1123-1124`) → un PDF de "Semana 5" se llama `..._2026-03.pdf`. |
| 2 | Señal bueno/malo/neutro | 3/5 | ⚠️ | Insights con ícono+color por tono (`:235-262`; `report_insights_service.dart:84-93`), resultado con color de fondo (`:1250-1262`), ROI en rojo si < −30% (`:1535`). **Pero:** "Margen sobre ventas" y "Gastos vs ingresos" se muestran sin ninguna señal ni interpretación (`:314-321`); "Vendido vs cosechado" se pinta en rojo cuando vendiste >10% de lo cosechado (`:873-874`) **sin texto explícito** que diga qué está mal; nómina/caja solo por color. |
| 3 | Lenguaje sin jerga / glosario | 3.5/5 | ⚠️ | Glosario con definiciones muy buenas y con ejemplo en pesos (`app_es.arb:322-331`), 2 botones ⓘ con highlight contextual (`report_screen.dart:287-293`, `:359-366`), hint "Cómo leer el ROI" con ejemplo (`:384-402`, `app_es.arb:509`), "1 carga ≈ 60 lbs ≈ 27.2 kg" (`app_es.arb:494`). **Pero:** el glosario es un diálogo aparte con solo 5 términos; métricas como kg/ha, kg/planta, "costo total por kg", "inversión (establecimiento)", "subtotal", "a la fecha (YTD)", "por hectárea / payback" **no tienen definición en el punto donde aparecen**; los negativos se muestran entre paréntesis contables `(1.500)` sin aviso (`:1329-1334`) — un no-financiero puede leerlo como número normal. |
| 4 | Jerarquía y densidad | 2.5/5 | ❌ | La pantalla apila **~10 bloques** en un ListView: conclusión, estado de resultados, compradores/proveedores, desglose por cultivo, cosechas, vendido vs cosechado, nómina, caja menor, por hectárea, qué hacer, + 3 botones de exportación (`:213-466`). Textos de 11-13px en casi todo (`:257`, `:1018`, `:1233`). El orden no distingue "resumen" de "detalle": no hay forma de saber qué es lo importante sin leer todo. |
| 5 | Comparaciones e interpretabilidad de cifras | 3/5 | ⚠️ | Buena: comparación vs mes anterior y "mejor mes" en los insights (`report_insights_service.dart:96-116`, `:183-220`). **Pero:** las tarjetas numéricas (cosechas, nómina, caja, por hectárea) son cifras absolutas **sin comparación** con período anterior ni con un referente ("¿es mucho?"), y el "resultado" no lleva marca de tendencia (▲▼) en la tarjeta principal. |
| 6 | Accionabilidad ("Qué hacer") | 4/5 | ✅ | Priorizado 1-4 con severidad y colores (`:933-988`), mensajes concretos con "El problema: …" y montos reales (`alert_service.dart:108-513`, ej. `app_es.arb:627,847`). **Pero:** son solo 4 ítems sin indicar período, y "No hay recomendaciones" (`app_es.arb:243`) sin decir si eso es bueno o no hay datos. |
| 7 | Accesibilidad y señales duales | 2.5/5 | ❌ | Los insights sí combinan ícono+color+texto ✅. **Pero:** "resultado" depende del color de fondo (`:1267`), rojo de "vendido vs cosechado" solo color (`:874`), ROI rojo/verde solo color (`:1531-1537`), y tamaños de 11px (`:1025`, `:1233`) quedan por debajo de lo cómodo en móvil. Sin modo "solo color" se pierde información (daltonismo / pantalla al sol — relevante para el campo). |

**Veredicto general: ⚠️ PARCIAL.** El reporte es *bueno para quien ya entendió la app*, pero un
usuario promedio se topa con 3 barreras reales: (a) cifras sin señal "¿bueno o malo?",
(b) jerga que solo se explica en un diálogo aparte que pocos abrirán, (c) densidad — diez
tarjetas sin jerarquía de "lee esto primero".

## B. Hallazgos priorizados (top 12)

| # | Sev. | Hallazgo | Evidencia | Qué le pasa al usuario promedio |
|---|------|----------|-----------|--------------------------------|
| H1 | Alta | "Margen sobre ventas" y "Gastos vs ingresos" sin señal ni ejemplo | `report_screen.dart:314-321` | Ve "23%" y no sabe si está bien o mal |
| H2 | Alta | PDF y Excel **no incluyen** los insights ("Conclusión del período") — grep `insight` en servicios de exporte: 0 matches | `pdf_export_service.dart` (secciones :168-972), `excel_export_service.dart` (:290-596) | El documento compartido pierde justo la parte explicada en lenguaje humano |
| H3 | Alta | Rojo de "Vendido vs cosechado" sin texto que lo explique | `report_screen.dart:873-874` | "¿Por qué está en rojo? ¿qué hago?" |
| H4 | Alta | Negativos en notación contable `(1.500)` sin leyenda | `report_screen.dart:1329-1334` | Puede leer la pérdida como cifra normal |
| H5 | Media | Jerga sin definición in-situ: kg/ha, kg/planta, costo total por kg, inversión establecimiento, payback, subtotal, YTD | `app_es.arb:234-237,280-283,479`, `report_screen.dart:698,770` | Cada término es una puerta cerrada; el glosario (5 términos) no los cubre |
| H6 | Media | ~10 tarjetas apiladas sin pestañas/acordeones ni orden "resumen → detalle" | `report_screen.dart:213-466` | Se siente abrumador; abandona antes de llegar a "Qué hacer" |
| H7 | Media | Nombre de archivo de exporte siempre con `(_month+1)` aunque el modo sea semana/año | `report_screen.dart:1073-1074`, `:1123-1124` | Archivos mal etiquetados al compartir → confusión de período |
| H8 | Media | Cifras absolutas sin comparación en tarjetas de detalle (cosecha, nómina, caja, per-ha) | `_builtHarvestCard` :611-737, `_builtCashBoxCard` :786-849 | No puede interpretar "¿es mucho?" |
| H9 | Media | ROI se explica bien en la tarjeta de cultivo, pero "ROI" en la tabla PDF solo tiene pie de página | `pdf_export_service.dart:308-310` vs `:488-491` | En el PDF la columna ROI se ve sin contexto inmediato |
| H10 | Media | Dependencia del color en resultado / ROI / vendido-cosechado / caja (sin símbolo + o texto) | `:1267`, `:1531-1537`, `:874`, `:828` | Pérdida de significado con daltonismo o luz solar |
| H11 | Baja | Textos de 11-13px y density-first (filas de 11-12px) | `:257`, `:1018-1035`, `:1233` | Lectura incómoda, sobre todo en campo |
| H12 | Baja | "No hay recomendaciones para este período" no distingue "todo bien" de "sin datos" | `app_es.arb:243` + `recommendations.dart:27` | ¿Celebro o me preocupo? |

## C. Fortalezas existentes (que hay que conservar)

1. **"Conclusión del período"**: frases cortas con montos reales y tono (positivo/negativo/info)
   con ícono — exactamente el patrón que un usuario promedio necesita
   (`report_insights_service.dart:25-66`).
2. **Glosario con definiciones y ejemplos en pesos** ("ROI −70% → de $100 solo vuelven $30",
   `app_es.arb:323`) y hints contextuales de ROI en pantalla.
3. **"Qué hacer"**: priorizado con severidad, mensajes "El problema: …" con cifras concretas.

## D. Alternativas (para que decidas)

### Alternativa 1 — "Primer pantallazo": capa de lenguaje simple sobre lo existente
*Sin reestructurar; toca copy, tooltips y señales.*

- Etiqueta junto a cada métrica clave: margen, gastos vs ingresos, ROI, kg/ha, payback →
  texto corto tipo "qué significa" (bottom-sheet con el glosario ya existente, `terminology_guide.dart`,
  ampliado de 5 a ~10 términos y abierto con un toque en la métrica, no solo 2 botones ⓘ).
- Señal bueno/malo textual en margen/ratio: chip "👍 sano" / "⚠️ revisar" junto al valor (`:314-321`).
- Texto explicando el rojo de "Vendido vs cosechado" y del resultado negativo.
- Leyenda para la notación `(1.500)` = negativo.
- Quitar el rojo/verde solo-color: añadir `+/−` o ícono donde solo hay color.

| | |
|---|---|
| **Resuelve** | H1, H3, H4, H5, H10, (parcial H6, H12) |
| **Esfuerzo** | Bajo (1-2 días): solo `report_screen.dart`, `terminology_guide.dart`, `app_es.arb` |
| **Pros** | Riesgo mínimo, no cambia la estructura que ya conocen los usuarios actuales, reutiliza el glosario |
| **Contras** | No ataca la densidad; el usuario sigue viendo 10 tarjetas |

### Alternativa 2 — "Primero lo primero": rediseño de jerarquía del reporte
*Reorganiza la pantalla en 3 zonas: Resumen (3 frases + 4 KPIs con señal) → Secciones colapsables → Acciones.*

- Zona 1: período + "Conclusión del período" + 4 KPIs grandes (Resultado, Margen, Kg cosechados, Gastos) cada uno con señal bueno/malo y comparación ▲▼ vs período anterior.
- Zona 2: tarjetas colapsables (por defecto: estado de resultados y "Qué hacer" abiertos; resto plegado con preview de 1 línea).
- Zona 3: exportes agrupados en un solo botón con menú.
- Incluye todo lo de Alternativa 1.

| | |
|---|---|
| **Resuelve** | H1-H8, H10-H12 (los 12, en distinto grado) |
| **Esfuerzo** | Medio-alto (4-6 días): refactor mayor de `report_screen.dart` (1625 líneas), tests `test/report_screen_test.dart` |
| **Pros** | Ataca la causa raíz (densidad + jerarquía); el usuario ve lo importante en 3 segundos |
| **Contras** | Cambia una pantalla que ya está en producción; más riesgo visual/regresión; usuarios actuales deben re-acostumbrarse |

### Alternativa 3 — "El reporte que se lee solo": narrativa en los exportes
*La pantalla queda como está; el valor se va al PDF/Excel que se comparte con otras personas.*

- Incluir "Conclusión del período" (los insights ya calculados) como primera sección del PDF y del Excel "Resumen".
- PDF: glosario corto en anexo (o pie con las 5 definiciones ya escritas), leyenda de notación contable, texto del rojo "vendido vs cosechado".
- Excel "Resumen": fila de notas al pie con la definición de margen/ratio/ROI.
- Corregir el nombre de archivo según el período real (H7).

| | |
|---|---|
| **Resuelve** | H2, H4, H7, H9, (parcial H1, H3, H5) |
| **Esfuerzo** | Medio (2-3 días): `pdf_export_service.dart`, `excel_export_service.dart` |
| **Pros** | Impacto directo en el documento que circula fuera de la app; poca riesgo en la UI |
| **Contras** | No mejora lo que se ve en la pantalla; requiere aún 1-2 toques de la Alternativa 1 para las señales |

### Tabla comparativa

| Criterio | Alt. 1 (lenguaje simple) | Alt. 2 (jerarquía) | Alt. 3 (exportes) |
|---|---|---|---|
| Hallazgos resueltos | 6/12 | 12/12 | 5/12 |
| Esfuerzo | Bajo (1-2 d) | Alto (4-6 d) | Medio (2-3 d) |
| Riesgo en producción | Bajo | Medio-alto | Bajo |
| Impacto en "¿lo entiende cualquiera?" | Alto | Muy alto | Alto (para el PDF compartido) |
| ¿Mejora la pantalla? | Sí (parcial) | Sí (total) | No |
| ¿Mejora el PDF/Excel? | No | No | Sí |

### Recomendación (tu decisión pendiente)

**Combinación escalonada 1 → 3, con la 2 como segundo año:** empezar por la Alternativa 1
(bajo esfuerzo, resuelve las 4 barreras más duras: H1-H5) y enseguida la Alternativa 3
(para que el PDF/Excel compartido también se entienda solo). La Alternativa 2 es la única
que resuelve la densidad, pero es la más costosa y la dejaría para cuando valides con
usuarios reales que la densidad efectivamente es el problema (H6 es un juicio de código,
no una observación de uso).
