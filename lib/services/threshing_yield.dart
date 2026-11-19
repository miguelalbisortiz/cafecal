import '../l10n/generated/app_localizations.dart';
import '../models/categories.dart';
import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'report_harvest_metrics.dart';

/// Fase 3 · kilos vendibles (pergamino) que salen de [cherryKg].
///
/// [factor] es **kg de cereza por 1 kg de pergamino**: `5` significa que de
/// 5 kg de cereza sale 1 kg vendible.
///
/// Devuelve `null` —nunca 0— cuando no hay factor (`null`), cuando el factor
/// no puede ser real (`<= 1`: saldría más pergamino que cereza) o cuando no
/// hay kilos cosechados. Sin factor no hay cifra que mostrar, y un 0 se
/// leería como «no salió nada».
double? sellableKgFromCherry(double cherryKg, double? factor) {
  if (factor == null || factor <= 1) return null;
  if (cherryKg <= 0) return null;
  return cherryKg / factor;
}

/// «Café · factor 5,2», con el decimal del idioma.
///
/// Una sola función para pantalla, PDF y Excel: el PDF formateaba el factor
/// con `toStringAsFixed` y decía «5.20» mientras la pantalla decía «5,2».
String threshingLabel(ThreshingRow row, AppLocalizations l10n, String locale) =>
    '${row.crop.name} · ${l10n.reportThreshingFactor} '
    '${formatKg(row.crop.threshingYield!, locale)}';

/// «300 kg de cereza = 60 kg vendibles», también con el decimal del idioma.
String threshingKgLine(
        ThreshingRow row, AppLocalizations l10n, String locale) =>
    l10n.reportThreshingRow(
      formatKg(row.cherryKg, locale),
      formatKg(row.sellableKg, locale),
    );

/// Una fila de rendimiento: un cultivo con factor anotado y kilos cosechados.
class ThreshingRow {
  final Crop crop;

  /// Kilos de cereza cosechados en el período.
  final double cherryKg;

  /// Los mismos kilos pasados a café vendible con el factor del cultivo.
  final double sellableKg;

  /// Gastos de producción del cultivo ÷ kg vendibles.
  ///
  /// `null` si no hay gastos de producción o si mezclan monedas: dividir
  /// pesos y dólares entre los mismos kilos daría un costo que no significa
  /// nada.
  final double? costPerSellableKg;

  /// Moneda de [costPerSellableKg], o `null` si no hay costo.
  ///
  /// La necesita la alerta de costo real: sin saber en qué moneda está el
  /// costo no se puede comparar con el precio de una venta sin mezclar.
  final String? costCurrency;

  const ThreshingRow({
    required this.crop,
    required this.cherryKg,
    required this.sellableKg,
    required this.costPerSellableKg,
    this.costCurrency,
  });
}

/// Rendimiento de trilla de cada cultivo que lo tenga anotado.
///
/// Los cultivos sin factor no generan fila: no hay nada que calcular. Los que
/// lo tienen pero no cosecharon en el período tampoco: sin kilos no hay
/// conversión (y no se inventa un 0).
///
/// [harvests] ya debe venir filtrado al período del reporte, igual que en el
/// resto de las métricas de cosecha.
List<ThreshingRow> threshingRows({
  required Iterable<Crop> crops,
  required Iterable<Harvest> harvests,
  required Iterable<Transaction> transactions,
  required double sacoKg,
}) {
  final cherryByCrop = <String, double>{};
  for (final h in harvests) {
    final cropId = h.cropId;
    if (cropId == null) continue;
    final kg = harvestKg(h, sacoKg: sacoKg);
    if (kg <= 0) continue;
    cherryByCrop[cropId] = (cherryByCrop[cropId] ?? 0) + kg;
  }

  final out = <ThreshingRow>[];
  for (final crop in crops) {
    final cherryKg = cherryByCrop[crop.id] ?? 0;
    final sellableKg = sellableKgFromCherry(cherryKg, crop.threshingYield);
    if (sellableKg == null) continue;
    final cost = _productionCost(transactions, crop.id, sellableKg);
    out.add(ThreshingRow(
      crop: crop,
      cherryKg: cherryKg,
      sellableKg: sellableKg,
      costPerSellableKg: cost?.perKg,
      costCurrency: cost?.currency,
    ));
  }
  // El que más kilos vendibles aporta va primero, como el resto de la tarjeta.
  out.sort((a, b) => b.sellableKg.compareTo(a.sellableKg));
  return out;
}

/// Gastos de **producción** del cultivo (incluye siembra, cercas, beneficio y
/// secado de la Fase 2) repartidos sobre los kilos vendibles.
///
/// El equipo queda fuera: comprar una despulpadora no encarece el kilo de
/// esta cosecha, igual que en [ReportHarvestMetrics.totalCostPerKg]. Venta,
/// fijos e impuestos tampoco entran a un costo de producción.
({double perKg, String currency})? _productionCost(
    Iterable<Transaction> transactions, String cropId, double sellableKg) {
  if (sellableKg <= 0) return null;
  double cost = 0;
  var hay = false;
  final monedas = <String>{};
  for (final t in transactions) {
    if (t.deleted || !t.type.isExpense) continue;
    if (t.cropId != cropId) continue;
    if (expenseGroupOf(t.category) != ExpenseGroup.produccion) continue;
    cost += t.amount;
    hay = true;
    monedas.add(t.currency);
  }
  if (!hay || monedas.length > 1) return null;
  return (perKg: cost / sellableKg, currency: monedas.first);
}
