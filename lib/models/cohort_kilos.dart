import '../models/harvest.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../services/derived_harvests.dart';

/// Etapa B · kilos por lote, leídos de los jornales de «Cosechar».
///
/// En la finca se pesa por lote al recogerlo y después la venta mezcla lotes:
/// por eso la atribución sale de la **medida del jornal** y no de la venta.
/// Repartir una venta entre lotes sería inventar un número que nadie pesó.
///
/// ## Qué entra
///
/// Solo jornales **medidos** ([isMeasuredHarvestJornal]): gasto no borrado,
/// mano de obra, labor «Cosechar» del catálogo, con cultivo y kilos > 0.
/// El puntero tiene que ser una **siembra-cabeza de ese cultivo**: un puntero
/// a una resiembra, a otro cultivo o a una fila que ya no está **no se
/// reasigna** — esos kilos quedan «sin lote» y no entran al mapa.
///
/// ## Qué no entra
///
/// - Un cultivo con **cosecha guardada a mano**: la manual manda y los kilos
///   del jornal no se derivan en el resto de la app, así que mostrarlos aquí
///   sería una cifra que no suma (regla de oro). Devuelve vacío.
/// - Jornales sin lote: suman al cultivo, no a un lote. La tarjeta no inventa
///   una fila «sin lote» (divergencia declarada en el PRD).
///
/// No redondea ni guarda nada: suma los números que él escribió.
Map<String, double> cohortKilos({
  required String cropId,
  required List<Transaction> transactions,
  required List<Harvest> storedHarvests,
  required List<Sowing> sowings,
}) {
  // D10-A · la cosecha manual manda: los kilos del jornal no se derivan.
  if (storedHarvests.any((h) => h.cropId == cropId)) return const {};

  // Solo las siembras-cabeza del cultivo son lotes: una resiembra ajusta su
  // lote, no abre uno.
  final lotes = <String>{
    for (final s in sowings)
      if (s.cropId == cropId && s.kind == SowingKind.siembra) s.id,
  };

  final out = <String, double>{};
  for (final t in transactions) {
    if (!isMeasuredHarvestJornal(t)) continue;
    if (t.cropId != cropId) continue;
    if (t.terrenoId != null) continue;
    final lote = t.cohortSowingId;
    if (lote == null || !lotes.contains(lote)) continue;
    out[lote] = (out[lote] ?? 0) + t.harvestedKg!;
  }
  return out;
}

/// Kg/planta de un lote.
///
/// `null` si no hay kilos medidos o si el lote no tiene matas vivas: sin un
/// dato no se pinta un 0, y dividir entre 0 no es un rendimiento.
double? kgPerPlantCohort(double? kg, int livePlants) {
  if (kg == null || kg <= 0) return null;
  if (livePlants <= 0) return null;
  return kg / livePlants;
}
