import '../l10n/generated/app_localizations.dart';
import '../models/categories.dart';
import '../models/farm_alert.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'currency_totals.dart';
import 'recommendations.dart';

/// Tanda 3 · hito 3 — un solo aviso cuando más de la mitad de las ventas
/// identificadas del período dependen de un comprador.
///
/// La moneda no se reimplementa: [amountsByCurrency] e [isMixedCurrency] de
/// `currency_totals.dart` siguen siendo la única regla de la casa. La identidad
/// del comprador es la cadena exacta guardada en `Transaction.client` (D3):
/// no se normalizan mayúsculas ni espacios interiores.
class BuyerConcentrationRow {
  final String buyer;

  /// Código ISO de la única moneda del período (nunca un símbolo `$`).
  final String currency;

  /// Ventas del principal / total de ventas identificadas × 100.
  final double sharePct;

  final double buyerAmount;
  final double salesTotal;

  /// Compradores distintos (>= 2 por el umbral D1).
  final int buyerCount;

  const BuyerConcentrationRow({
    required this.buyer,
    required this.currency,
    required this.sharePct,
    required this.buyerAmount,
    required this.salesTotal,
    required this.buyerCount,
  });
}

/// Como máximo UNA fila: con menos de dos compradores, moneda mixta o
/// `share <= 50 %` devuelve `null` y los pintadores no añaden nada.
///
/// [records] llega ya filtrado al período, igual que el desglose. No hay
/// reloj: la ventana la decide el período.
BuyerConcentrationRow? buyerConcentration({
  required Iterable<Transaction> records,
}) {
  // SC-3.1 / D4: solo ventas con cliente identificado. Las ventas sin
  // comprador quedan FUERA del denominador; los ingresos no-venta con
  // `client` (p. ej. subvenciones) no cuentan como comprador.
  final identificadas = records
      .where((t) =>
          !t.deleted &&
          t.type == TransactionType.income &&
          isSaleCategory(t.category) &&
          t.client != null &&
          t.client!.isNotEmpty)
      .toList();
  if (identificadas.isEmpty) return null;

  // SC-3.4: guarda ANTES de sumar. Sin conversión, sin netos inventados.
  if (isMixedCurrency(identificadas)) return null;

  final codes = <String>{};
  for (final t in identificadas) {
    codes.add(t.currency);
  }
  if (codes.length != 1) return null;
  final currency = codes.single;

  // D3: clave = cadena exacta, sin normalizar.
  final byBuyer = <String, List<Transaction>>{};
  for (final t in identificadas) {
    byBuyer.putIfAbsent(t.client!, () => <Transaction>[]).add(t);
  }
  if (byBuyer.length < 2) return null;

  final totales = <String, double>{};
  for (final entry in byBuyer.entries) {
    final byCurrency =
        amountsByCurrency(entry.value, type: TransactionType.income);
    if (byCurrency.length != 1) return null;
    totales[entry.key] = byCurrency[currency] ?? 0;
  }

  final salesTotal = totales.values.fold<double>(0, (a, b) => a + b);
  if (salesTotal <= 0) return null;

  final orden = totales.keys.toList()
    ..sort((a, b) {
      final porMonto = totales[b]!.compareTo(totales[a]!);
      if (porMonto != 0) return porMonto;
      return a.compareTo(b);
    });
  final buyer = orden.first;
  final buyerAmount = totales[buyer]!;
  final sharePct = buyerAmount / salesTotal * 100;

  // D1: umbral ESTRICTO. Exactamente 50 % no se emite.
  if (sharePct <= 50) return null;

  return BuyerConcentrationRow(
    buyer: buyer,
    currency: currency,
    sharePct: sharePct,
    buyerAmount: buyerAmount,
    salesTotal: salesTotal,
    buyerCount: byBuyer.length,
  );
}

/// La MISMA frase en Reportes, PDF y Excel: una sola clave ARB, una sola
/// redacción. [locale] se conserva por simetría con las otras filas; D2 hace
/// que esta no cite monto, así que no interviene en el formato.
String buyerConcentrationMessage(
  BuyerConcentrationRow row,
  AppLocalizations l10n,
  String locale,
) =>
    l10n.buyerConcentrationLine(formatPct(row.sharePct), row.buyer);

/// 0 o 1 fila lista para «Qué hacer», concatenada DESPUÉS de `derive` para
/// que el dedupe por regla no se coma la fila.
List<Recommendation> buyerConcentrationRecommendations({
  required Iterable<Transaction> records,
  required AppLocalizations l10n,
  required String locale,
}) {
  final row = buyerConcentration(records: records);
  if (row == null) return const [];
  return [
    Recommendation(
      rule: AlertRule.buyerConcentration,
      severity: AlertSeverity.info,
      title: l10n.buyerConcentrationTitle,
      message: buyerConcentrationMessage(row, l10n, locale),
      // La acción ya está en el mensaje: repetirla en dos líneas sería ruido.
      suggestion: '',
    ),
  ];
}
