---
tanda: 2A
fecha: 2026-11-17_1015
veredicto: PASS
reporte: docs/reports/2026-11-17_1015_tanda2a-altas-cortas-contexto.md
---

# Auditoría · Tanda 2A

| Criterio del plan 2.1 | Evidencia | Resultado |
|---|---|---|
| Ofrecer terreno, área y unidad como opcionales en el alta corta | `NewCropDialog` + tests de Registro y Siembras | PASS |
| «Ahora no» pospone, no bloquea futuros cultivos | `CropSetupPrompt.canAsk(cropId)` + test de ids distintos y preferencia legacy | PASS |
| El prompt recibe terrenos | Se pasa `tx.terrenos` en las tres puertas cortas | PASS |
| Se puede crear rápido y completar después sin perder el aviso | Test `(b)` de `l2_5_quick_doors_test.dart` ajustado a la nueva semántica | PASS |
| Sin fricción cuando no hay terrenos | El desplegable condicionado a `terrenos.isNotEmpty` | PASS |
| Copy ES/EN coherente | `cropAreaInvalid` y `quickAddOptionalHelp` en ambos ARB + generado | PASS |
| Sin regresión | analyze limpio; 1429/1429 | PASS |

## Seguridad y discipline

- Sin secretos ni credenciales en los archivos tocados.
- Sin `DROP`/`DELETE` sin WHERE, sin `rm -rf`, sin cambios de `package.json`
  ni `.env`.
- Sin commit ni push: no se pidió en este turno.
- CI nuevo sin permisos elevados, sin secrets, sin deploy: solo `checkout`,
  `flutter-action`, `pub get`, `analyze`, `test`.

## Observaciones (no bloqueantes)

1. El workflow de CI no se validó en GitHub Actions; la sintaxis se revisó
   localmente y las mismas tres órdenes pasan en la máquina de desarrollo.
2. El conteo de "más cultivos con área/terreno" del plan requiere datos de una
   finca real; el mecanismo está listo, la medición queda para la prueba manual.
3. La clave `crop_setup_prompt_dismissed_v1` queda huérfana a propósito. No se
   borra el valor guardado para no tocar preferencias del usuario sin pedirlo.
4. Tanda 2B, 2C y Tanda 3 siguen pendientes; Tanda 3 exige PRD aprobado.

**Veredicto: PASS.**
