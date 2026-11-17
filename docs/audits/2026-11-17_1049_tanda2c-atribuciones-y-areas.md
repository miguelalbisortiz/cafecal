---
tanda: 2C
fecha: 2026-11-17_1049
veredicto: PASS
reporte: docs/reports/2026-11-17_1049_tanda2c-atribuciones-y-areas.md
---

# Auditoría · Tanda 2C

| Criterio aprobado | Evidencia | Resultado |
|---|---|---|
| Copy del aporte dice la verdad | `contributionSubtitle` ES «este aporte no reparte» / EN «does not split them»; `cultivos_copy_test.dart` exige el texto nuevo y prohíbe el viejo | PASS |
| Desglose rotulado como reparto en los 3 | `cropBreakdownSplitNote` en pantalla, PDF y Excel; `attribution_labels_test.dart` comprueba los tres | PASS |
| Las dos reglas no se confunden | «se reparte por hectáreas» vs «no reparte» en el mismo reporte, sin tocar el cálculo | PASS |
| Cálculo intacto | `crop_totals.dart` y `product_contribution.dart` sin cambios; las copias prorrateadas y el aporte aparte siguen como estaban | PASS |
| Sin cifras inventadas | solo se añade texto de aclaración; el `null` sigue oculto | PASS |
| 2.4 aviso no bloqueante verificado | `terreno_area.dart:25` calcula `over` solo si ambas áreas existen; banner ámbar en `crops_screen.dart:217-254`; no muta `areaHa`; 63/63 tests | PASS |
| Guardas de páginas revisadas con motivo escrito | 4 páginas sin cambio; plantilla de 1 página sin anexo sin cambio; comentario en el reporte | PASS |
| Sin regresión | analyze limpio; 20/20 targeted; 1437/1437 suite completa | PASS |
| TDD | 6/6 tests en rojo antes de la implementación (getter ausente + copy viejo) | PASS |

## Seguridad y disciplina

- Sin secretos ni credenciales en los archivos tocados.
- Sin `DROP`/`DELETE` sin WHERE, sin `rm -rf`, sin cambios de `package.json`
  ni `.env`.
- Sin commit ni push: no se pidió en este turno.
- No se agregaron dependencias ni permisos.
- Se tocaron ARB y archivos generados: todos los cambios son copy; el
  regenerado de `gen-l10n` se normalizó a LF para no introducir CRLF.

## Observaciones (no bloqueantes)

1. El texto nuevo del desglose solo aparece cuando hay cultivos asociados,
   porque vive junto a esa nota en los tres pintadores. Fuera de ese caso no hay
   reparto que aclarar.
2. `Crop.copyWith(areaHa: null)` no borra el área (a diferencia de `Terreno`);
   un aviso basado en estado guardado puede quedarse con dato viejo. Queda
   fuera de alcance de 2C.
3. `crop_editor_dialog.dart` convierte un área inválida en `null` sin error;
   el banner no aparecerá aunque el usuario creyera escribir área. `new_crop_dialog`
   sí valida > 0. Tampoco se arregla en caliente.
4. La prueba manual del gate de Tanda 2 (10 ha, 3 cultivos, 4 trabajadores)
   sigue sin ejecutarse: no hay datos de finca real en esta sesión.
5. La ejecución remota del CI creado en 2A sigue sin validarse en GitHub.
6. Tanda 3 sigue pendiente y exige PRD aprobado.

**Veredicto: PASS.**
