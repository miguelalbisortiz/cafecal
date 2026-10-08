import '../models/transaction.dart';

/// Agrupa los montos de [records] por código de moneda.
///
/// Regla de dominio: **nunca se suman monedas distintas**. Cada entrada del
/// mapa es el total de una sola moneda, así que la cifra siempre es cierta.
/// Los registros borrados no cuentan.
///
/// Función pura: misma entrada, misma salida; sin red, sin estado, sin UI.
Map<String, double> amountsByCurrency(
  Iterable<Transaction> records, {
  TransactionType? type,
}) {
  final out = <String, double>{};
  for (final t in records) {
    if (t.deleted) continue;
    if (type != null && t.type != type) continue;
    out[t.currency] = (out[t.currency] ?? 0) + t.amount;
  }
  return out;
}

/// Ingresos, gastos y resultado de un período, separados por moneda.
///
/// Es la fuente de verdad para pintar los totales del período: si hay una
/// sola moneda se puede imprimir una única cifra; si hay dos o más hay que
/// mostrar los totales por moneda (o convertirlos a la moneda de la app).
class PeriodCurrencyTotals {
  /// Total de ingresos por código de moneda.
  final Map<String, double> incomes;

  /// Total de gastos por código de moneda.
  final Map<String, double> expenses;

  const PeriodCurrencyTotals({
    required this.incomes,
    required this.expenses,
  });

  /// Construye los totales de una lista de movimientos (ya filtrada al
  /// período). Los borrados se excluyen aquí también, por si acaso.
  factory PeriodCurrencyTotals.fromRecords(Iterable<Transaction> records) =>
      PeriodCurrencyTotals(
        incomes: amountsByCurrency(records, type: TransactionType.income),
        expenses: amountsByCurrency(records, type: TransactionType.expense),
      );

  /// Monedas presentes en el período (ingresos o gastos).
  Set<String> get currencies => {...incomes.keys, ...expenses.keys};

  /// true cuando el período toca más de una moneda: hay que mostrar los
  /// totales separados en vez de una sola cifra global.
  bool get isMixed => currencies.length > 1;

  double incomeOf(String currency) => incomes[currency] ?? 0;

  double expenseOf(String currency) => expenses[currency] ?? 0;

  /// Resultado de esa moneda: ingresos − gastos.
  double resultOf(String currency) => incomeOf(currency) - expenseOf(currency);
}
