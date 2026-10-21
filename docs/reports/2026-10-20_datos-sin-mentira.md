---
status: done
created: 2026-10-20
---

# Datos sin mentira — Tanda 4 (informe)

> PRD: `docs/prds/2026-10-20_1426-datos-sin-mentira.prd.md` (APPROVED)
> Plan: `docs/plans/2026-10-20-datos-sin-mentira.plan.md`
> Análisis: `docs/analysis/2026-10-20_rendimiento-y-cultivos-asociados.md`

## Qué se corrigió

| # | Antes | Después |
|---|-------|---------|
| **T2–T3** | `racimo` y `cajón` no tenían conversión: `unitToKg` los trataba como 1 kg. Una cosecha de **12 racimos con 240 kg** sumaba **12 kg** en todos los totales; una venta de **10 cajones con 200 kg** sumaba **10 kg** vendidos y el precio por kilo se calculaba sobre 10. | Los 12 racimos suman **240 kg** y los 10 cajones **200 kg**. El precio por kilo de la venta se calcula sobre 200. Un total que necesite kilos pasa por `kgFromUnit`; sin peso devuelve `null` (oculto), nunca un número inventado. |
| **T4** | El peso de una cosecha en racimo/cajón era opcional. | Es obligatorio: el formulario no deja guardar sin kg. Copy ES/EN. |
| **T5** | La venta no guardaba su peso, así que la cosecha derivada nacía sin kilos. | `transactions.equivalent_kg` guarda los kg de la venta, viaja en el JSON y en Supabase, y la cosecha derivada los hereda. El formulario de venta pide kg con el mismo texto que el de cosecha. |
| **T6** | Un registro viejo sin peso desaparecía de los promedios sin explicación. | Tarjeta «sin peso» en el reporte: cuenta las cosechas y ventas que faltan, las lista con fecha/cultivo/cantidad y abre el editor al tocarlas. Al completarlas el contador baja. |
| **T7** | PDF y Excel podían quedarse atrás de la pantalla. | Paridad congelada con Yuca: cosecha 12 racimos / 240 kg, venta 10 cajones / 200 kg (COP 200.000). PDF 2 páginas; Excel con 240 kg en la hoja de cosechas; precio/kg 1000. |
| **T8** | No había historial: cambiar el aporte de caja reescribía el pasado. | `settings.cash_budget_history` (`YYYY-MM` → monto). Al guardar Ajustes se anota el mes en curso; al abrir por primera vez con aporte > 0 se siembra una vez. El aporte rige desde su mes, no hacia atrás. `0` explícito = ese mes sin aporte. |
| **T9** | El arrastre y la tabla mensual usaban el aporte actual para todos los meses. | Cada mes usa el monto que regía. Los meses anteriores a la primera entrada no se listan ni suman/restan. Sin historial se cae al aporte único de siempre (datos viejos siguen igual). |
| **T10** | No se veía si las áreas de los cultivos se pasaban del terreno. | La tarjeta del terreno dice «5,00 de 8,00 ha asignadas»; si se pasa, aviso en ámbar («Las áreas suman 12,00 ha y el terreno tiene 8,00») y cuenta los cultivos sin área. **No bloquea.** El editor de cultivo muestra cuánto del terreno ya está asignado. |
| **T11** | El kg/planta se leía como si todo el cultivo produjera. | Nota al pie: «kg/planta es el promedio del cultivo; incluye plantas que aún no producen». Sin cambio de cálculo. |
| **T12** | Una resiembra con plantas nuevas y sin muertas dejaba el contador a medias en silencio. | Aviso «Anotaste plantas nuevas sin muertas» con **Anotar muertas** (enfoca el campo) y **Guardar así**. `0` explícito no vuelve a preguntar. |
| **T13** | La planilla podía leerse como un presupuesto por tarea; la ayuda no explicaba la renovación. | La planilla aclara «Esto es lo gastado por tarea; el presupuesto de caja es uno solo». La ayuda agrega la renovación completa (se anota como siembra nueva; reinicia edad, plantas y área; las cosechas viejas quedan) y el camino de «cultivo aparte» para lotes que conviven. |
| **T15** | Un gasto que sirve a varios cultivos solo podía ir al lote entero (reparto automático por hectáreas) o a uno solo. | Botón «Repartir entre cultivos» en el gasto: porcentajes por cultivo con atajo «usar áreas», suma visible y validación de 100 %. Se guardan **N gastos independientes** (mismo día, categoría y descripción; el último absorbe el redondeo) y cada uno entra al costo por kilo de su cultivo. No hay gasto padre, así que nada se cuenta dos veces. |

## Código y datos

- Helper único de kilos: `lib/models/units.dart` (`kgFromUnit`, `unitNeedsWeight`,
  `kUnitsNeedingWeight`). `unitToKg` queda prohibido fuera de ese archivo por la
  guarda `test/unit_weight_guard_test.dart`.
- Reparto de gasto: `lib/services/expense_split.dart` (`splitAmounts`,
  `areaShares`) y `lib/widgets/expense_split_dialog.dart`. N gastos
  independientes, sin registro padre; el remanente de redondeo va al último.
- `equivalent_kg` en `transactions` (modelo, JSON, payload de sync, cosecha
  derivada). `harvests.equivalent_kg` ya existía desde la tanda 2.
- Historial de caja en `FarmSettings`, `report_payroll_metrics`, tarjeta de caja,
  alertas y exportadores. Respaldo: un respaldo con historial manda; uno sin
  historial no borra el que ya existe.
- Migraciones (las aplica el usuario **antes** del deploy):
  - `supabase/migrations/202610200001_add_transaction_equivalent_kg.sql`
  - `supabase/migrations/202610200002_add_settings_cash_budget_history.sql`
- Copy nueva en ES y EN, con `flutter gen-l10n` y
  `test/l10n_tanda4_test.dart` como guarda.

## Gate

| | Antes (T1) | Después |
|---|---|---|
| `flutter analyze` | limpio | limpio |
| `flutter test` | 1049/1049 | **1119/1119** |

Archivos normalizados a LF antes de commitear (el repo guarda LF).

## Pendiente

- El usuario aplica las dos migraciones en Supabase.
- Deploy (`.\deploy.ps1`) y verificación manual (8 puntos al final del plan).
