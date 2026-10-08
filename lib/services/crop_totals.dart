import '../models/crop.dart';
import '../models/transaction.dart';

/// Fila del desglose por cultivo con los montos **separados por moneda**.
///
/// Regla de dominio: todo lo que se cosecha se vende (no hay bodega) y
/// **nunca se suman monedas distintas**. Cada mapa guarda el total de una
/// sola moneda, así que la cifra siempre es cierta.
///
/// - Moneda única → `incomes`/`expenses` tienen una entrada: la cifra de
///   siempre, con su código, es válida.
/// - Dos o más monedas (`isMixed`) → hay que listar moneda por moneda; el
///   neto, el ROI y cualquier % que cruce monedas serían mentira.
class CropBreakdownRow {
  /// Id del cultivo (`null` = movimientos sin cultivo asignado).
  final String? cropId;

  /// Nombre ya resuelto para mostrar (nombre del cultivo o el rótulo de
  /// "sin cultivo").
  final String name;

  /// Movimientos del cultivo en el período (sin borrados).
  int count;

  /// Ingresos por código de moneda.
  final Map<String, double> incomes;

  /// Gastos por código de moneda.
  final Map<String, double> expenses;

  CropBreakdownRow({
    required this.cropId,
    required this.name,
    this.count = 0,
    Map<String, double>? incomes,
    Map<String, double>? expenses,
  })  : incomes = incomes ?? <String, double>{},
        expenses = expenses ?? <String, double>{};

  /// Monedas presentes en el cultivo (ingresos o gastos).
  Set<String> get currencies => {...incomes.keys, ...expenses.keys};

  /// true cuando el cultivo toca más de una moneda.
  bool get isMixed => currencies.length > 1;

  /// Moneda de la fila si es una sola; con más de una no hay cifra única
  /// que mostrar y el caller debe desglosar.
  String? get singleCurrency => currencies.length == 1 ? currencies.first : null;

  /// Suma aritmética de los gastos. **Solo** para ordenar o filtrar filas:
  /// con moneda mixta no es una cifra que se pueda mostrar.
  double get expensesTotal => _sum(expenses.values);

  /// Ídem para los ingresos.
  double get incomesTotal => _sum(incomes.values);

  /// true si la fila tiene algún monto que mostrar.
  bool get hasAnyAmount => expensesTotal > 0 || incomesTotal > 0;

  static double _sum(Iterable<double> values) =>
      values.fold<double>(0, (a, b) => a + b);
}

/// Agrupa los movimientos del período por cultivo y, dentro de cada cultivo,
/// por moneda.
///
/// [records] llega ya filtrado al período (los borrados se ignoran igual
/// por si acaso). Los cultivos sin movimientos también salen, con los mapas
/// vacíos, para que el caller decida si los pinta.
///
/// Función pura: misma entrada, misma salida; sin red, sin estado, sin UI.
/// Es la misma fuente que usan la pantalla, el PDF y el Excel, para que los
/// tres apliquen exactamente el mismo criterio.
List<CropBreakdownRow> cropBreakdownRows({
  required Iterable<Transaction> records,
  required List<Crop> crops,
  required String unspecifiedName,
}) {
  final nameById = {for (final c in crops) c.id: c.name};
  final rows = <String?, CropBreakdownRow>{
    null: CropBreakdownRow(cropId: null, name: unspecifiedName),
  };
  for (final c in crops) {
    rows.putIfAbsent(c.id, () => CropBreakdownRow(cropId: c.id, name: c.name));
  }

  for (final t in records) {
    if (t.deleted) continue;
    final row = rows.putIfAbsent(
      t.cropId,
      () => CropBreakdownRow(
        cropId: t.cropId,
        name: t.cropId == null
            ? unspecifiedName
            : (nameById[t.cropId] ?? t.cropId!),
      ),
    );
    row.count++;
    final target = t.type.isExpense ? row.expenses : row.incomes;
    target[t.currency] = (target[t.currency] ?? 0) + t.amount;
  }
  return rows.values.toList();
}

/// Montos de un mapa `moneda → monto` en una sola línea, cada moneda con su
/// cifra y su código: `$5.000 COP · €200 EUR`. Nunca se suman entre sí.
///
/// [format] recibe el monto y el código (para que cada render use su
/// formato: pantalla, PDF o Excel).
String byCurrencyText(
  Map<String, double> amounts,
  String Function(double amount, String currency) format, {
  String separator = ' · ',
}) {
  final entries = amounts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${format(e.value, e.key)} ${e.key}').join(separator);
}
