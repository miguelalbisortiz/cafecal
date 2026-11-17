import '../l10n/generated/app_localizations.dart';
import '../models/categories.dart';
import '../models/crop.dart';
import '../models/farm_alert.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import '../models/units.dart';
import '../utils/format.dart';
import 'recommendations.dart';
import 'report_harvest_metrics.dart';

/// Tanda 3 · hito 1 — lo que se cosechó y no se vendió en los últimos 12 meses.
///
/// Regla única de esta recomendación: ventana rodante de 365 días, kilos
/// convertidos con la MISMA función que el resto del reporte, una fila por
/// cultivo con excedente y una frase con la cifra y la acción. Los tres
/// pintadores no calculan: solo appendan lo que devuelve este archivo.

class UnsoldStockRow {
  final String? cropId;
  final String cropName;
  final double harvestedKg;
  final double soldKg;
  final double unsoldKg;

  const UnsoldStockRow({
    required this.cropId,
    required this.cropName,
    required this.harvestedKg,
    required this.soldKg,
    required this.unsoldKg,
  });
}

/// Cosechado menos vendido por cultivo, solo si queda algo sin vender.
///
/// [now] es obligatorio: la ventana es `now − 365 días … now`, inclusive, y
/// un reporte no puede depender de la hora en que se ejecute el test.
/// Los registros sin peso convertible se omiten (nunca 1 kg por unidad) y los
/// de cosecha sin cultivo no generan fila: no hay a quién dirigir la acción.
List<UnsoldStockRow> unsoldStockByCrop({
  required Iterable<Transaction> transactions,
  required Iterable<Harvest> harvests,
  required Iterable<Crop> crops,
  required double sacoKg,
  required DateTime now,
}) {
  final desde = now.subtract(const Duration(days: 365));
  final nombres = <String, String>{
    for (final c in crops) c.id: c.name,
  };

  final cosechado = <String, double>{};
  for (final h in harvests) {
    final cropId = h.cropId;
    if (cropId == null) continue;
    if (h.date.isBefore(desde) || h.date.isAfter(now)) continue;
    final kg = harvestKg(h, sacoKg: sacoKg);
    if (kg <= 0) continue;
    cosechado[cropId] = (cosechado[cropId] ?? 0) + kg;
  }

  final vendido = <String, double>{};
  for (final t in transactions) {
    final cropId = t.cropId;
    if (cropId == null) continue;
    if (t.deleted || t.type.isExpense || !isSaleCategory(t.category)) continue;
    if (t.date.isBefore(desde) || t.date.isAfter(now)) continue;
    final cantidad = t.quantity;
    if (cantidad == null || cantidad <= 0) continue;
    final kg = kgFromUnit(cantidad, t.unit, t.equivalentKg, sacoKg: sacoKg);
    if (kg == null || kg <= 0) continue;
    vendido[cropId] = (vendido[cropId] ?? 0) + kg;
  }

  final filas = <UnsoldStockRow>[];
  for (final entry in cosechado.entries) {
    final cropId = entry.key;
    final vendidoKg = vendido[cropId] ?? 0;
    const epsilon = 1e-9;
    final restante = entry.value - vendidoKg;
    if (restante <= epsilon) continue;
    filas.add(UnsoldStockRow(
      cropId: cropId,
      cropName: nombres[cropId] ?? cropId,
      harvestedKg: entry.value,
      soldKg: vendidoKg,
      unsoldKg: restante,
    ));
  }
  filas.sort((a, b) => b.unsoldKg.compareTo(a.unsoldKg));
  return filas;
}

/// La misma frase en los tres pintadores: cifra formateada y acción.
String unsoldStockMessage(
        UnsoldStockRow row, AppLocalizations l10n, String locale) =>
    l10n.stockUnsoldLine(formatKg(row.unsoldKg, locale), row.cropName);

/// Filas listas para «Qué hacer». Se concatenan DESPUÉS de `derive`, que
/// deduplica por regla: dos cultivos con stock deben dar dos filas.
List<Recommendation> unsoldStockRecommendations({
  required Iterable<Transaction> transactions,
  required Iterable<Harvest> harvests,
  required Iterable<Crop> crops,
  required double sacoKg,
  required DateTime now,
  required AppLocalizations l10n,
  required String locale,
}) =>
    unsoldStockByCrop(
      transactions: transactions,
      harvests: harvests,
      crops: crops,
      sacoKg: sacoKg,
      now: now,
    ).map((row) => Recommendation(
          rule: AlertRule.unsoldStock,
          severity: AlertSeverity.warning,
          title: l10n.stockUnsoldTitle,
          message: unsoldStockMessage(row, l10n, locale),
          suggestion: '',
        )).toList();
