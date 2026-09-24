import '../models/categories.dart';
import '../models/transaction.dart';
import 'pdf_export_service.dart' show ReportPeriod;
import 'week_utils.dart';

/// Fila de nómina: un trabajador (nombre snapshot en `provider`) con sus
/// días totales y el subtotal pagado en el período.
class PayrollRow {
  final String provider; // '' = gasto sin nombre de trabajador
  final double days;
  final double subtotal;

  const PayrollRow({
    required this.provider,
    required this.days,
    required this.subtotal,
  });
}

/// Resumen de nómina del período.
class PayrollSummary {
  final List<PayrollRow> rows;
  final double total;

  /// Cantidad de empleados: trabajadores distintos (nombres no vacíos en
  /// `provider`) con gasto de mano de obra en el período. No se anota a mano.
  final int distinctEmployees;

  const PayrollSummary({
    required this.rows,
    required this.total,
    required this.distinctEmployees,
  });

  bool get isEmpty => rows.isEmpty;
}

/// Consumo de caja menor de un mes calendario dentro del período.
class CashBoxMonthRow {
  final int year;
  final int month; // 1-12
  final double budget;
  final double labor; // jornales (mano de obra)
  final double extras; // kCashBoxExtraCategories

  const CashBoxMonthRow({
    required this.year,
    required this.month,
    required this.budget,
    required this.labor,
    required this.extras,
  });

  double get total => labor + extras;

  /// Positivo = lo que queda; negativo = caja agotada.
  double get balance => budget - total;
}

/// Métricas de nómina y caja menor para los reportes (PDF, Excel y pantalla).
/// Lógica única compartida por los tres renderers.
class ReportPayrollMetrics {
  const ReportPayrollMetrics();

  /// Agrupa los gastos de mano de obra del período por trabajador (snapshot
  /// en `provider`). El total incluye todos los gastos; los empleados
  /// distintos solo cuentan nombres no vacíos.
  PayrollSummary payroll(Iterable<Transaction> periodTx) {
    final days = <String, double>{};
    final amounts = <String, double>{};
    final employees = <String>{};

    for (final t in periodTx) {
      if (t.deleted || !t.type.isExpense || t.category != 'mano_obra') {
        continue;
      }
      final key = (t.provider ?? '').trim();
      amounts[key] = (amounts[key] ?? 0) + t.amount;
      if (t.quantity != null) {
        days[key] = (days[key] ?? 0) + t.quantity!;
      }
      if (key.isNotEmpty) employees.add(key);
    }

    final rows = amounts.entries
        .map((e) => PayrollRow(
              provider: e.key,
              days: days[e.key] ?? 0,
              subtotal: e.value,
            ))
        .toList()
      ..sort((a, b) => b.subtotal.compareTo(a.subtotal));

    return PayrollSummary(
      rows: rows,
      total: rows.fold<double>(0, (a, r) => a + r.subtotal),
      distinctEmployees: employees.length,
    );
  }

  /// Una fila por mes del período con el presupuesto de caja configurado.
  /// Los meses sin gastos también aparecen (control anual mes a mes); el
  /// saldo NO se acumula entre meses: cada fila se reinicia con su presupuesto.
  /// Devuelve vacío si no hay presupuesto (caja desactivada).
  List<CashBoxMonthRow> cashBoxByMonth({
    required Iterable<Transaction> periodTx,
    required double? budget,
    required ReportPeriod period,
    required int year,
    int? month,
    DateTime? now,
  }) {
    final b = budget;
    if (b == null || b <= 0) return const [];
    final ref = now ?? DateTime.now();

    final labor = <String, double>{};
    final extras = <String, double>{};
    for (final t in periodTx) {
      if (t.deleted || !t.type.isExpense || !discountsCashBox(t.category)) {
        continue;
      }
      final key = '${t.date.year}-${t.date.month}';
      if (t.category == 'mano_obra') {
        labor[key] = (labor[key] ?? 0) + t.amount;
      } else {
        extras[key] = (extras[key] ?? 0) + t.amount;
      }
    }

    final keys = <String>{...labor.keys, ...extras.keys};
    void seed(int y, int m) => keys.add('$y-$m');

    switch (period) {
      case ReportPeriod.week:
        final range = weekRange(year, month ?? 1);
        seed(range.start.year, range.start.month);
        seed(range.end.year, range.end.month);
      case ReportPeriod.month:
        seed(year, month ?? ref.month);
      case ReportPeriod.year:
        for (var m = 1; m <= 12; m++) {
          seed(year, m);
        }
      case ReportPeriod.yearToDate:
        final last = year < ref.year ? 12 : ref.month;
        for (var m = 1; m <= last; m++) {
          seed(year, m);
        }
    }

    // Orden numérico (año, mes); el orden lexicográfico pondría "10" antes
    // que "2".
    final sorted = keys.toList()
      ..sort((a, b) {
        final pa = a.split('-');
        final pb = b.split('-');
        final cmp = int.parse(pa[0]).compareTo(int.parse(pb[0]));
        return cmp != 0 ? cmp : int.parse(pa[1]).compareTo(int.parse(pb[1]));
      });
    final out = <CashBoxMonthRow>[];
    for (final key in sorted) {
      final parts = key.split('-');
      out.add(CashBoxMonthRow(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        budget: b,
        labor: labor[key] ?? 0,
        extras: extras[key] ?? 0,
      ));
    }
    return out;
  }
}
