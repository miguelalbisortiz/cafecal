import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart' show ReportPeriod;
import 'package:mi_cafetal/services/report_payroll_metrics.dart';

Transaction _expense({
  required double amount,
  required DateTime date,
  String category = 'mano_obra',
  bool deleted = false,
}) =>
    Transaction(
      id: 't_${category}_${date.millisecondsSinceEpoch}_$amount',
      type: TransactionType.expense,
      category: category,
      amount: amount,
      date: date,
      createdAt: date,
      deleted: deleted,
    );

List<CashBoxMonthRow> _cash(
  Iterable<Transaction> periodTx, {
  required double? budget,
  ReportPeriod period = ReportPeriod.month,
  int year = 2026,
  int? month = 6,
}) =>
    const ReportPayrollMetrics().cashBoxByMonth(
      periodTx: periodTx,
      budget: budget,
      period: period,
      year: year,
      month: month,
    );

void main() {
  group('discountsCashBox', () {
    test('jornales (mano de obra) descuentan de caja', () {
      expect(discountsCashBox('mano_obra'), isTrue);
    });

    test('extras de caja descuentan: energía, agua, otro, mantenimiento', () {
      for (final key in kCashBoxExtraCategories) {
        expect(discountsCashBox(key), isTrue,
            reason: '$key debe descontar de la caja');
      }
      expect(discountsCashBox('energia'), isTrue);
      expect(discountsCashBox('agua'), isTrue);
    });

    test('insumos, fertilizantes y producción NO descuentan', () {
      const noDescuentan = [
        'fertilizante',
        'semillas_insumos',
        'riego',
        'plagas',
        'siembra',
        'cosecha',
        'transporte',
        'arriendo',
        'impuestos',
        'empaque',
        'equipo',
      ];
      for (final key in noDescuentan) {
        expect(discountsCashBox(key), isFalse,
            reason: '$key es inversión de producción, no gasto de caja');
      }
    });

    test('categorías Energía y Agua existen y se localizan', () {
      expect(expenseCategories.any((c) => c.key == 'energia'), isTrue);
      expect(expenseCategories.any((c) => c.key == 'agua'), isTrue);
      final es = stringsFor('es');
      expect(es.expenseCategory('energia'), 'Energía');
      expect(es.expenseCategory('agua'), 'Agua');
      final en = stringsFor('en');
      expect(en.expenseCategory('energia'), 'Energy');
      expect(en.expenseCategory('agua'), 'Water');
    });
  });

  group('cashBoxByMonth', () {
    test('sin presupuesto (null, 0 o negativo) devuelve vacío', () {
      final txns = [_expense(amount: 500, date: DateTime(2026, 6, 5))];
      expect(_cash(txns, budget: null), isEmpty);
      expect(_cash(txns, budget: 0), isEmpty);
      expect(_cash(txns, budget: -100), isEmpty);
    });

    test('mensual: 1 fila con jornales, extras y saldo (no acumula)', () {
      final txns = [
        _expense(amount: 400, date: DateTime(2026, 6, 5)),
        _expense(
            amount: 100, date: DateTime(2026, 6, 10), category: 'energia'),
        _expense(
            amount: 9999, date: DateTime(2026, 6, 6), category: 'fertilizante'),
        _expense(
            amount: 500000,
            date: DateTime(2026, 6, 20),
            category: 'otro'),
      ];
      // 'otro' es extra de caja: 100 + 500000.
      final rows = _cash(txns, budget: 600000);
      expect(rows, hasLength(1));
      final r = rows.single;
      expect(r.year, 2026);
      expect(r.month, 6);
      expect(r.budget, 600000);
      expect(r.labor, 400, reason: 'solo mano de obra');
      expect(r.extras, 100 + 500000, reason: 'energía + otro');
      expect(r.total, 400 + 100 + 500000);
      expect(r.balance, 99500,
          reason: '600000 − 500500; el fertilizante no descuenta');
    });

    test('cada mes reinicia su saldo: no se acumula entre meses', () {
      final txns = [
        _expense(amount: 500, date: DateTime(2026, 5, 20)),
        _expense(amount: 700, date: DateTime(2026, 6, 5)),
      ];
      final rows =
          _cash(txns, budget: 600, period: ReportPeriod.year, month: null);
      expect(rows, hasLength(12), reason: 'anual = 12 filas');
      final may = rows.firstWhere((r) => r.month == 5);
      final jun = rows.firstWhere((r) => r.month == 6);
      expect(may.total, 500);
      expect(may.balance, 100, reason: 'mayo con su propio saldo');
      expect(jun.total, 700);
      expect(jun.balance, -100,
          reason: 'junio no hereda el saldo de mayo');
      // Meses sin gastos: saldo completo.
      final jul = rows.firstWhere((r) => r.month == 7);
      expect(jul.total, 0);
      expect(jul.balance, 600);
    });

    test('anual: 12 filas en orden calendario (regresión del orden de texto)',
        () {
      final txns = [
        _expense(amount: 100, date: DateTime(2026, 10, 5),
            category: 'agua'),
        _expense(amount: 200, date: DateTime(2026, 2, 5),
            category: 'energia'),
      ];
      final rows =
          _cash(txns, budget: 600, period: ReportPeriod.year, month: null);
      expect(rows, hasLength(12));
      for (var i = 0; i < 12; i++) {
        expect(rows[i].month, i + 1,
            reason: 'las filas siguen el calendario, no el texto');
      }
      expect(rows[1].extras, 200, reason: 'febrero');
      expect(rows[9].extras, 100, reason: 'octubre');
    });

    test('ingresos y gastos que no descuentan se ignoran', () {
      final txns = [
        _expense(amount: 500, date: DateTime(2026, 6, 5),
            category: 'fertilizante'),
        _expense(amount: 300, date: DateTime(2026, 6, 6),
            category: 'semillas_insumos'),
        _expense(amount: 999, date: DateTime(2026, 6, 7), deleted: true),
        Transaction(
          id: 'ing',
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 800000,
          date: DateTime(2026, 6, 20),
          createdAt: DateTime(2026, 6, 20),
        ),
      ];
      final rows = _cash(txns, budget: 600);
      expect(rows, hasLength(1));
      expect(rows.single.total, 0);
      expect(rows.single.balance, 600);
    });

    test('semana: siembra los meses que toca la semana', () {
      // La semana 53 de 2026 va del lun 28/12/2026 al dom 03/01/2027:
      // deben aparecer ambos meses con saldo propio (sin acumular).
      final rows = _cash(
        const [],
        budget: 600,
        period: ReportPeriod.week,
        year: 2026,
        month: 53,
      );
      expect(rows, hasLength(2));
      expect(rows[0].year, 2026);
      expect(rows[0].month, 12);
      expect(rows[1].year, 2027);
      expect(rows[1].month, 1);
      expect(rows.every((r) => r.balance == 600), isTrue);
    });
  });
}
