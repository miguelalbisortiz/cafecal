# Auditoría — Tanda 1: confianza y acción

> Fecha: 2026-11-17 09:43 · Reporte auditado:
> `docs/reports/2026-11-17_0943_tanda1-cultivos-y-recomendaciones.md`.
> Veredicto: **PASS** (con nits documentados).

## 1. Criterios del plan

| Criterio | Evidencia | Resultado |
|---|---|---|
| «Qué hacer» muestra diagnóstico **y** acción en los 3 pintadores | `report_screen.dart`, `excel_export_service.dart`, `pdf_export_service.dart`; tests de recomendación, Excel y PDF | PASS |
| Cultivo creado con terreno lo conserva | `crops_screen.dart` pasa `terrenoId`; `test/crops_screen_test.dart` «crear desde Cultivos guarda el terreno elegido» | PASS |
| Ningún texto contradice el código (ES/EN) | `test/cultivos_copy_test.dart` sobre ambos ARB; `test/register_screen_test.dart` usa la clave viva | PASS |
| Sin commit ni push sin verbo explícito | `git status --short`: cambios sin commitear; ningún push en esta sesión | PASS |
| Rojo antes del arreglo | 5 fallos capturados antes de tocar `lib/` (compilación, copy, Excel, PDF, `terrenoId`) | PASS |
| Gate analyze + suite completa | `No issues found!`; `1425/1425` | PASS |

## 2. Revisión de cambios

- `Recommendation.suggestion` es `final` y obligatoria en el constructor: no
  puede volver a perderse por omisión al crear recomendaciones.
- Los tres pintadores comprueban `suggestion.isNotEmpty`: una alerta sin acción
  no deja una fila vacía.
- El PDF usa un único `RichText`; el guarda de páginas sigue en 1 para el caso
  sin anexo y en 2 con anexo.
- `terrenoId` viaja en la misma llamada que ya guardaba fase, área y unidad; no
  hay segunda escritura ni backfill.
- Copy: «variedad» desaparece de las cinco claves vigiladas en ES y EN;
  «transitorio» → «anual»; el subtítulo del aporte describe el reparto por área.
- Los generados `lib/l10n/generated/` quedaron en LF, como el resto del árbol;
  el diff de `recommendations.dart` y su test se normalizó a 7 líneas añadidas
  cada uno (antes parecía un reemplazo completo por CRLF).

## 3. Nits (no bloquean)

1. El test del PDF compara la sugerencia **sin espacios**: el espaciado del
   documento sale de ajustes `TJ`, no de glifos. La comprobación sigue siendo
   conductual (el texto está en el PDF), pero no valida la posición tipográfica.
2. `docs/PROJECT.md` sigue con metadata de julio y build instructions genéricas
   (`npm install`) que no corresponden a este proyecto Flutter. Fuera de alcance.
3. Los avisos de fuente faltante para `☕`/`👷` aparecen en la salida del test de
   PDF; son conocidos y no afectan al contenido ni al número de páginas.

## 4. Veredicto

**PASS.** La Tanda 1 cumple sus criterios y el gate está limpio. Quedan abiertas
la Tanda 2 (altas cortas y paridad de exportes) y la Tanda 3 (recomendaciones de
negocio, PRD obligatorio). No se marca como entregable: esa marca corresponde al
flujo con `audit-orchestrator`, que no se ejecutó en esta tanda.
