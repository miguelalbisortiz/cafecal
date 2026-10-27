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

/// Ingresos del período que todavía **no se han cobrado**.
///
/// El estado de resultados las cuenta como ingreso porque la venta ya
/// ocurrió, pero la plata no está en la caja. Pintarlas aparte es lo que
/// permite responder "¿cuánto puedo gastar de verdad?" sin restarle nada al
/// resultado ni inventar una cifra.
///
/// Mismas reglas que [amountsByCurrency]: nunca se suman monedas distintas y
/// los registros borrados no cuentan. Función pura: sin red, sin estado, sin UI.
Map<String, double> receivablesByCurrency(Iterable<Transaction> records) {
  final out = <String, double>{};
  for (final t in records) {
    if (t.deleted) continue;
    if (t.type != TransactionType.income) continue;
    if (t.paid) continue;
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

  /// Resultado de cada moneda por separado (ingresos − gastos de esa
  /// moneda). Con una sola moneda es la cifra de siempre; con varias es el
  /// único resultado honesto: nunca hay un "resultado global".
  Map<String, double> get results => {
        for (final c in currencies) c: resultOf(c),
      };
}

/// Agrupa los montos por una clave arbitraria (categoría, categoría ×
/// cultivo…) y, dentro de cada clave, **por moneda**.
///
/// Es el mismo criterio que [amountsByCurrency]: cada celda del mapa anidado
/// suma una sola moneda, así que la cifra siempre es cierta. Los borrados no
/// cuentan.
///
/// El orden de las claves es de mayor a menor usando la suma aritmética de
/// todas las monedas. **Esa suma solo sirve para ordenar la lista**: nunca se
/// muestra, porque cruzaría monedas distintas.
///
/// [keyOf] recibe cada movimiento y devuelve la clave del grupo.
Map<String, Map<String, double>> groupAmountsByCurrency(
  Iterable<Transaction> records, {
  required String Function(Transaction t) keyOf,
}) {
  final out = <String, Map<String, double>>{};
  for (final t in records) {
    if (t.deleted) continue;
    final bucket = out.putIfAbsent(keyOf(t), () => <String, double>{});
    bucket[t.currency] = (bucket[t.currency] ?? 0) + t.amount;
  }
  final entries = out.entries.toList()
    ..sort((a, b) => amountsTotal(b.value).compareTo(amountsTotal(a.value)));
  return {for (final e in entries) e.key: e.value};
}

/// Suma aritmética de un mapa `moneda → monto`.
///
/// **Solo** para ordenar o filtrar listas: con más de una moneda no es una
/// cifra que se pueda mostrar (sería cruzar monedas distintas).
double amountsTotal(Map<String, double> amounts) =>
    amounts.values.fold<double>(0, (a, b) => a + b);

/// ¿Se puede restar este gasto a un presupuesto que está en [budgetCurrency]?
///
/// Solo si el mes gastó en **una** moneda —o no gastó nada— y esa moneda es
/// además la del presupuesto. Con dos monedas, o con una sola pero ajena a la
/// del presupuesto, restarlos sería cruzar monedas: no hay saldo posible y lo
/// correcto es no imprimir ninguno.
///
/// Esta es la ÚNICA casa donde se decide esto. Reportes, PDF y Excel pasan
/// por aquí: antes la pantalla comprobaba la moneda y los dos exportadores no,
/// así que con presupuesto en pesos y un solo gasto en euros el exportador
/// imprimía `800.000 − 100 = 799.900` mientras la pantalla se callaba.
bool comparableToBudget(Set<String> currencies, String budgetCurrency) =>
    currencies.isEmpty ||
    (currencies.length == 1 && currencies.first == budgetCurrency);

/// true si los montos dados tocan más de una moneda.
///
/// Es la pregunta que decide si una cifra agregada (costo por kilo, margen,
/// % sobre el total, total del período…) es imprimible o sería mentira.
bool isMixedCurrency(Iterable<Transaction> records) {
  final currencies = <String>{};
  for (final t in records) {
    if (t.deleted) continue;
    currencies.add(t.currency);
    if (currencies.length > 1) return true;
  }
  return false;
}
