import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/metric_signal.dart';
import 'package:mi_cafetal/services/period_delta.dart';

AppLocalizations get _es => stringsFor('es');

Transaction _txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String currency = 'COP',
}) =>
    Transaction(
      id: '${type.name}_${date.millisecondsSinceEpoch}_$amount',
      type: type,
      category: 'otro',
      amount: amount,
      date: date,
      currency: currency,
      createdAt: DateTime(2026, 1, 1),
    );

PeriodCurrencyTotals _totals(List<Transaction> txs) =>
    PeriodCurrencyTotals.fromRecords(txs);

void main() {
  group('B1 · mismo tramo de días', () {
    test('el mes anterior se recorta al día de hoy', () {
      final now = DateTime(2026, 10, 13);
      final records = [
        _txn(
            type: TransactionType.expense,
            amount: 100,
            date: DateTime(2026, 9, 5)),
        _txn(
            type: TransactionType.expense,
            amount: 100,
            date: DateTime(2026, 9, 13)),
        _txn(
            type: TransactionType.expense,
            amount: 100,
            date: DateTime(2026, 9, 20)),
      ];

      final window = sameDayWindow(records, now);

      expect(window.map((t) => t.date.day), [5, 13]);
    });

    test('solo el mes en curso se considera incompleto', () {
      final now = DateTime(2026, 10, 13);
      expect(isCurrentMonth(2026, 10, now), isTrue);
      expect(isCurrentMonth(2026, 9, now), isFalse);
      expect(isCurrentMonth(2025, 10, now), isFalse);
    });
  });

  group('percentChange', () {
    test('subida y bajada', () {
      expect(percentChange(120, 100), closeTo(20, 0.001));
      expect(percentChange(80, 100), closeTo(-20, 0.001));
    });

    test('sin base no divide entre cero', () {
      expect(percentChange(500, 0), 100);
      expect(percentChange(0, 0), 0);
    });
  });

  group('changeText', () {
    test('plano, subida y bajada con el mismo umbral', () {
      expect(changeText(0, _es), _es.insightChangeFlat);
      expect(changeText(0.2, _es), _es.insightChangeFlat);
      expect(changeText(12.4, _es), _es.insightChangeUp('12%'));
      expect(changeText(-18.7, _es), _es.insightChangeDown('19%'));
    });
  });

  group('buildMonthComparison', () {
    MonthComparison? build(PeriodCurrencyTotals current,
            PeriodCurrencyTotals previous) =>
        buildMonthComparison(
          current: current,
          previous: previous,
          locale: 'es_CO',
          monthName: 'septiembre',
          l10n: _es,
        );

    test('moneda única: las tres líneas y el gasto con la señal invertida',
        () {
      final current = _totals([
        _txn(
            type: TransactionType.income,
            amount: 1120,
            date: DateTime(2026, 10, 2)),
        _txn(
            type: TransactionType.expense,
            amount: 820,
            date: DateTime(2026, 10, 3)),
      ]);
      final previous = _totals([
        _txn(
            type: TransactionType.income,
            amount: 1000,
            date: DateTime(2026, 9, 2)),
        _txn(
            type: TransactionType.expense,
            amount: 1000,
            date: DateTime(2026, 9, 3)),
      ]);

      final c = build(current, previous)!;

      expect(c.incomeText, _es.insightChangeUp('12%'));
      expect(c.incomeSignal, MetricSignal.positive);
      // Los gastos bajaron: es buena señal aunque el % sea negativo.
      expect(c.expenseText, _es.insightChangeDown('18%'));
      expect(c.expenseSignal, MetricSignal.positive);
      expect(c.resultText, startsWith('mejor'));
      expect(c.resultSignal, MetricSignal.positive);
      expect(c.vsLabel, 'vs. septiembre');
      expect(c.note, contains('mismos días'));
    });

    test('resultado igual → sin cambios', () {
      final current = _totals([
        _txn(
            type: TransactionType.income,
            amount: 1000,
            date: DateTime(2026, 10, 2)),
        _txn(
            type: TransactionType.expense,
            amount: 500,
            date: DateTime(2026, 10, 3)),
      ]);
      final previous = _totals([
        _txn(
            type: TransactionType.income,
            amount: 1000,
            date: DateTime(2026, 9, 2)),
        _txn(
            type: TransactionType.expense,
            amount: 500,
            date: DateTime(2026, 9, 3)),
      ]);

      final c = build(current, previous)!;

      expect(c.incomeText, _es.insightChangeFlat);
      expect(c.incomeSignal, MetricSignal.neutral);
      expect(c.resultText, _es.insightChangeFlat);
      expect(c.resultSignal, MetricSignal.neutral);
    });

    test('sin datos en un mes → null, nunca cero', () {
      final current = _totals([
        _txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 10, 2)),
      ]);
      expect(build(current, _totals([])), isNull);
    });

    test('moneda mixta en el mes → null: no se cruzan monedas', () {
      final current = _totals([
        _txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 10, 2)),
        _txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 10, 3),
            currency: 'USD'),
      ]);
      final previous = _totals([
        _txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 9, 2)),
      ]);

      expect(build(current, previous), isNull);
    });

    test('monedas distintas entre los dos meses → null', () {
      final current = _totals([
        _txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 10, 2)),
      ]);
      final previous = _totals([
        _txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 9, 2),
            currency: 'USD'),
      ]);

      expect(build(current, previous), isNull);
    });
  });
}
