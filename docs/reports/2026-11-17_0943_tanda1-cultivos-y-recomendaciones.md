# Reporte — Tanda 1: confianza y acción

> Fecha: 2026-11-17 09:43 · Alcance aprobado por el usuario con «aprobado dale».
> Plan: `docs/plans/2026-11-17_0918-mejoras-cultivos-y-recomendaciones.plan.md`.
> Sin PRD (la tanda no lo exige). **Sin commit ni push.**

## 1. Quién pidió qué

El usuario pidió primero solo análisis; tras leer los informes y el plan, aprobó
**únicamente la Tanda 1**. Quedan fuera la Tanda 2 (datos completos/paridad) y la
Tanda 3 (recomendaciones de negocio, con PRD).

## 2. Rojo real antes del arreglo

Se ejecutaron los tests nuevos contra el código sin cambiar. Los cinco frentes
fallaron por la razón que persiguen:

| Frente | Fallo observado |
|---|---|
| Recomendación | `The getter 'suggestion' isn't defined for the class 'Recommendation'` |
| Copy ES | «Nueva variedad» y «transitorio» seguían en el ARB |
| Excel | no aparecía `alertLowPriceSuggestion` en la hoja Cosechas |
| PDF | no aparecía la acción; además el CMap imprime glifos, no ASCII |
| Terreno | cultivo creado desde Cultivos con `terrenoId` = `<null>` |

Guardas nuevas: `test/report_recommendations_test.dart`,
`test/evaluacion_unificada_export_test.dart`, `test/cultivos_copy_test.dart`,
`test/crops_screen_test.dart` y `test/pdf_export_test.dart`.

## 3. Cambios entregados

| Pieza | Antes | Después |
|---|---|---|
| `lib/services/recommendations.dart` | `derive` copiaba `title`/`message` y tiraba la acción | `Recommendation.suggestion` se propaga desde `FarmAlert` |
| `lib/screens/report_screen.dart` | tarjeta «Qué hacer» con diagnóstico | misma fila con diagnóstico + acción en gris |
| `lib/services/excel_export_service.dart` | fila de mensaje | fila adicional con la acción |
| `lib/services/pdf_export_service.dart` | dos `pw.Text` | un solo `pw.RichText` con dos `TextSpan` |
| `lib/screens/crops_screen.dart` | descartaba `form.terrenoId` | pasa `terrenoId` a `addCrop` |
| `lib/l10n/app_es.arb`, `app_en.arb` | «variedad», «transitorio», reparto negado | «cultivo», «anual», reparto por área explicado |
| `lib/l10n/generated/` | — | regenerado con `flutter gen-l10n` y normalizado a LF |

Además se ajustó `test/register_screen_test.dart`: fijaba el literal viejo
`'+ Nueva variedad…'`; ahora comprueba la clave viva `_es.cropNewOption`, para
que el test siga al copy en vez de contradecirlo.

## 4. Decisiones

- **D1 — un solo `TextSpan` en el PDF.** Dos `pw.Text` separados añadían una
  página; `pw.RichText` con un `TextSpan` hijo conserva el anexo en una página
  cuando no hay contenido nuevo.
- **D2 — el helper del test decodifica el CMap.** El `pdf` 3.11.3 comprime con
  `zlib.encode` y escribe glifos `<0001>…` con `beginbfchar`. `_pdfStreams`
  infla los streams; `_pdfText` traduce cada CMap a UTF-16BE y lee los operadores
  `Tj`/`TJ`. El espaciado vive en los ajustes `TJ`, no en glifos: la aserción
  compara sin espacios.
- **D3 — guarda de páginas sin ruido.** El caso «sin anexo» lleva venta y cosecha
  fechadas `DateTime.now()` para que ninguna alerta ajena al anexo sizing el PDF.
- **D4 — ARB es la fuente.** El copy se corrigió en los ARB y se regeneró; no se
  editó el generado a mano.

## 5. Gate

| Comando | Resultado |
|---|---|
| `flutter analyze` | **No issues found!** (20,4 s) |
| `flutter test` | **1425/1425** |
| 6 archivos de la tanda + regresión de copy | **68/68** tras la normalización final de fin de línea |

Primera pasada completa: 1424/1425; el único fallo era el test que fijaba el
copy viejo. Se corrigió ese test y la segunda pasada quedó limpia. Los avisos
`Unable to find a font to draw "☕"/"👷"` son ruido conocido del generador de PDF
en tests, no fallos.

## 6. Límites y estado

- No se hicieron commit ni push. Hay cambios preexistentes del usuario
  (`product_contribution.dart`, `strings.dart`, `income_sale_labels_test.dart`,
  `product_contribution_test.dart`, clave `contributionCommonIncome`) que se
  conservaron tal cual.
- Tanda 2 y Tanda 3 siguen pendientes; la Tanda 3 requiere PRD aprobado.
- No se probó en dispositivo: la comprobación es automática sobre pantallas,
  Excel y PDF reales generados por el servicio de exportación.
