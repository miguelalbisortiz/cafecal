import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/report_insights_service.dart';

AppLocalizations get _es => stringsFor('es');

String _money(double v) => '\$${v.round()}';

Transaction _txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String category = 'otro',
}) {
  return Transaction(
    id: '${type.name}_${amount}_${date.millisecondsSinceEpoch}',
    type: type,
    category: category,
    amount: amount,
    date: date,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final now = DateTime(2026, 6, 15);
  const service = ReportInsightsService();

  group('Bloque A — Balance y tendencia', () {
    test('mes con pérdida emite resultado negativo con margen', () {
      final current = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 6, 2)),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 5)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: [],
        yearRecords: current,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final bal = insights.firstWhere((i) => i.text.contains('Resultado negativo'));
      expect(bal.tone, InsightTone.negative);
      expect(bal.text, contains(r'$600'));
      expect(bal.text, contains('-150%'));
    });

    test('compara contra el mes anterior cuando hay datos', () {
      final current = [
        _txn(type: TransactionType.income, amount: 5000, date: DateTime(2026, 6, 2)),
      ];
      final previous = [
        _txn(type: TransactionType.income, amount: 4000, date: DateTime(2026, 5, 2)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: previous,
        yearRecords: [...current, ...previous],
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final vs = insights.firstWhere((i) => i.text.contains('Frente a Junio'));
      expect(vs.text, contains('subieron 25%'));
    });

    test('sin ventas pero con gastos avisa', () {
      final current = [
        _txn(type: TransactionType.expense, amount: 700, date: DateTime(2026, 6, 2)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: [],
        yearRecords: current,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(insights.any((i) => i.text.contains('no hay ventas')), isTrue);
    });
  });

  group('Bloque B — Mayor gasto', () {
    test('cita la categoría tope con porcentaje y dependencia > 50%', () {
      final current = [
        _txn(type: TransactionType.expense, amount: 600, date: DateTime(2026, 6, 1), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 2), category: 'transporte'),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: [],
        yearRecords: current,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final top = insights.firstWhere((i) => i.text.contains('Tu mayor gasto'));
      expect(top.text, contains('Mano de obra'));
      expect(top.text, contains('67%'));
      expect(
        insights.any((i) => i.text.contains('Concentras más de la mitad')),
        isTrue,
      );
    });
  });

  group('Bloque C — Ventas', () {
    test('detecta venta promedio reciente menor al histórico', () {
      final year = [
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final insights = service.build(
        now: now,
        current: year.where((t) => t.date.month == 6).toList(),
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(
        insights.any((i) => i.text.contains('Vendes por montos menores')),
        isTrue,
      );
    });
  });

  group('Bloque D — Comparación temporal', () {
    test('cita el mejor mes de ventas y el de menor gasto', () {
      final year = [
        _txn(type: TransactionType.income, amount: 9000, date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 3, 11)),
        _txn(type: TransactionType.income, amount: 3000, date: DateTime(2026, 5, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.expense, amount: 4000, date: DateTime(2026, 5, 11)),
      ];
      final insights = service.build(
        now: now,
        current: year,
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final best = insights.firstWhere((i) => i.text.contains('Tu mejor mes'));
      expect(best.text, contains('Marzo'));
      expect(best.text, contains(r'$9000'));
      expect(best.text, contains(r'$1000'));
    });
  });

  test('sin actividad emite un solo aviso informativo', () {
    final insights = service.build(
      now: now,
      current: const [],
      previousMonth: const [],
      yearRecords: const [],
      year: 2026,
      month: 6,
      l10n: _es,
      money: _money,
    );
    expect(insights.single.tone, InsightTone.info);
    expect(insights.single.text, contains('No hay movimientos'));
  });
}