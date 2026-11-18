import '../models/product_state.dart';
import '../models/transaction.dart';
import '../models/units.dart';

/// Totales de venta de un estado del café.
class SalesStateTotals {
  final ProductState state;
  final double amount;
  final double kg;

  const SalesStateTotals({
    required this.state,
    required this.amount,
    required this.kg,
  });

  /// Precio medio por kilo de lo vendido en este estado, o `null` si no hay
  /// kilos — nunca un 0 que parezca «gratis».
  double? get pricePerKg => kg > 0 ? amount / kg : null;
}

/// Agrupa las ventas por estado del café, **en una sola moneda**.
///
/// Mezclar monedas produciría un total que no significa nada; el llamador pide
/// la moneda que muestra (igual que `currency_totals`). Las ventas sin estado
/// no entran: son plátano, otros cultivos o datos viejos.
///
/// Los kilos usan la misma puerta que el resto de la app ([kgFromUnit]): un
/// racimo o un cajón sin peso anotado no suman kilos inventados.
List<SalesStateTotals> salesByState(
  List<Transaction> transactions, {
  required String currency,
  double sacoKg = kSacoKgPorDefecto,
}) {
  final amounts = <ProductState, double>{};
  final kilos = <ProductState, double>{};

  for (final t in transactions) {
    if (t.deleted) continue;
    if (t.type != TransactionType.income) continue;
    final state = t.productState;
    if (state == null) continue;
    if (t.currency != currency) continue;

    amounts[state] = (amounts[state] ?? 0) + t.amount;
    final kg = kgFromUnit(
      t.netQuantity ?? 0,
      t.unit,
      t.equivalentKg,
      sacoKg: sacoKg,
    );
    if (kg != null) kilos[state] = (kilos[state] ?? 0) + kg;
  }

  return [
    for (final s in ProductState.values)
      if (amounts.containsKey(s))
        SalesStateTotals(
          state: s,
          amount: amounts[s] ?? 0,
          kg: kilos[s] ?? 0,
        ),
  ];
}
