import '../l10n/generated/app_localizations.dart';
import '../models/currencies.dart';
import '../models/crop.dart';
import '../models/farm_alert.dart';
import '../models/terreno.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'crop_totals.dart';
import 'recommendations.dart';
import 'report_harvest_metrics.dart';

/// Tanda 3 · hito 2 — una sola recomendación: qué cultivo paga mejor la mano
/// de obra, con su margen % y su margen por hectárea en la MISMA fila.
///
/// La atribución la hace [cropBreakdownRows] (el desglose de siempre, con su
/// reparto por hectáreas). Este archivo solo elige al ganador y redacta; los
/// tres pintadores no calculan nada.
class CropMarginRow {
  final String cropId;
  final String cropName;

  /// Código ISO de la única moneda de la fila (nunca un símbolo `$`).
  final String currency;

  /// (ingresos − gastos) / ingresos × 100, sobre todos los gastos atribuidos.
  final double marginPct;

  final double incomePerHa;

  /// Solo gastos de operación: la inversión en equipo no encarece la hectárea
  /// de este período (misma cesta que `ReportHarvestMetrics.costPerHa`).
  final double costPerHa;

  final double marginPerHa;

  const CropMarginRow({
    required this.cropId,
    required this.cropName,
    required this.currency,
    required this.marginPct,
    required this.incomePerHa,
    required this.costPerHa,
    required this.marginPerHa,
  });
}

/// Como máximo UNA fila: el mayor margen % entre los cultivos que también
/// tengan área y gastos de operación repartidos. `null` → no se emite nada.
///
/// [records] llega ya filtrado al período, igual que el desglose que pintan
/// Reportes, el PDF y el Excel. No hay reloj: la ventana la decide el período.
CropMarginRow? bestCropMargin({
  required Iterable<Transaction> records,
  required List<Crop> crops,
  required List<Terreno> terrenos,
  required String unspecifiedName,
  required String Function(String terrenoName) loteNoRepartidoName,
}) {
  final rows = cropBreakdownRows(
    records: records,
    crops: crops,
    terrenos: terrenos,
    unspecifiedName: unspecifiedName,
    loteNoRepartidoName: loteNoRepartidoName,
  );
  final areaById = {for (final c in crops) c.id: c.areaHa};

  final candidatos = <CropMarginRow>[];
  for (final row in rows) {
    // Los lotes sin repartir y «Costos comunes» no son cultivos: nunca se
    // les inventa una proporción ni un margen.
    if (row.cropId == null || row.isMixed) continue;
    final currency = row.singleCurrency;
    if (currency == null) continue;

    final pct = row.marginPct;
    if (pct == null) continue; // sin ingresos o sin gastos → no hay margen

    final areaHa = areaById[row.cropId];
    if (areaHa == null || areaHa <= 0) continue;

    final operacion = row.expenseTxs
        .where((t) => !t.deleted && t.type.isExpense && isOperationExpense(t))
        .fold<double>(0, (a, t) => a + t.amount);
    if (operacion <= 0) continue; // SC-2.4: sin gasto repartido, sin cifra /ha

    final ingresoHa = row.incomesTotal / areaHa;
    final costoHa = operacion / areaHa;
    candidatos.add(CropMarginRow(
      cropId: row.cropId!,
      cropName: row.name,
      currency: currency,
      marginPct: pct,
      incomePerHa: ingresoHa,
      costPerHa: costoHa,
      marginPerHa: ingresoHa - costoHa,
    ));
  }

  // Doble guard de moneda: ni una fila mezcla monedas, ni se comparan
  // márgenes de dos monedas distintas. Sin conversión, sin inventar.
  if ({for (final c in candidatos) c.currency}.length > 1) return null;
  if (candidatos.isEmpty) return null;

  candidatos.sort((a, b) {
    final pct = b.marginPct.compareTo(a.marginPct);
    if (pct != 0) return pct;
    final porHa = b.marginPerHa.compareTo(a.marginPerHa);
    if (porHa != 0) return porHa;
    final nombre = a.cropName.compareTo(b.cropName);
    if (nombre != 0) return nombre;
    return a.cropId.compareTo(b.cropId);
  });
  return candidatos.first;
}

/// La MISMA frase en Reportes, PDF y Excel: una sola clave ARB, una sola
/// redacción. [locale] solo decide el separador de miles del monto.
String cropMarginMessage(
  CropMarginRow row,
  AppLocalizations l10n,
  String locale,
) =>
    l10n.cropMarginLine(
      row.cropName,
      formatPct(row.marginPct),
      formatMoneyLabel(row.marginPerHa, row.currency, locale: locale),
    );

/// 0 o 1 fila lista para «Qué hacer», concatenada DESPUÉS de `derive` para
/// que el dedupe por regla no se coma la fila.
List<Recommendation> cropMarginRecommendations({
  required Iterable<Transaction> records,
  required List<Crop> crops,
  required List<Terreno> terrenos,
  required String unspecifiedName,
  required String Function(String terrenoName) loteNoRepartidoName,
  required AppLocalizations l10n,
  required String locale,
}) {
  final row = bestCropMargin(
    records: records,
    crops: crops,
    terrenos: terrenos,
    unspecifiedName: unspecifiedName,
    loteNoRepartidoName: loteNoRepartidoName,
  );
  if (row == null) return const [];
  return [
    Recommendation(
      rule: AlertRule.cropMargin,
      severity: AlertSeverity.info,
      title: l10n.cropMarginTitle,
      message: cropMarginMessage(row, l10n, locale),
      // La acción ya está en el mensaje: repetirla en dos líneas sería ruido.
      suggestion: '',
    ),
  ];
}
