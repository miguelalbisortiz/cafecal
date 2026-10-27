import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/report_period.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/period_comparison.dart';

Transaction _tx({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String currency = 'COP',
  bool deleted = false,
}) =>
    Transaction(
      id: '${type.name}-$amount-${date.toIso8601String()}-$currency-$deleted',
      type: type,
      category: type.isExpense ? 'fertilizante' : 'venta_cafe',
      amount: amount,
      currency: currency,
      date: date,
      createdAt: date,
      deleted: deleted,
    );

PeriodCurrencyTotals _totals(List<Transaction> records) =>
    PeriodCurrencyTotals.fromRecords(records);

void main() {
  group('previousPeriodWindow', () {
    test('semana: los siete días anteriores, aunque caigan en el año pasado',
        () {
      // La semana 1 de 2026 empieza el lunes 29 de diciembre de 2025.
      final window = previousPeriodWindow(
          period: ReportPeriod.week, year: 2026, month: 1);

      expect(window.start, DateTime(2025, 12, 22));
      expect(window.end.isAfter(DateTime(2025, 12, 28, 23, 59)),
          isTrue,
          reason: 'el domingo completo cuenta');
      expect(window.contains(DateTime(2025, 12, 22, 8)), isTrue);
      expect(window.contains(DateTime(2025, 12, 29)), isFalse,
          reason: 'la semana anterior no se come la semana actual');
    });

    test('mes: el mes calendario anterior, cruzando el año', () {
      final window =
          previousPeriodWindow(period: ReportPeriod.month, year: 2026, month: 1);

      expect(window.start, DateTime(2025, 12, 1));
      expect(window.contains(DateTime(2025, 12, 31, 23, 30)), isTrue);
      expect(window.contains(DateTime(2026, 1, 1)), isFalse);
    });

    test('año: el año calendario anterior completo', () {
      final window =
          previousPeriodWindow(period: ReportPeriod.year, year: 2026);

      expect(window.start, DateTime(2025, 1, 1));
      expect(window.contains(DateTime(2025, 12, 31, 23, 30)), isTrue);
      expect(window.contains(DateTime(2024, 12, 31)), isFalse);
    });

    test('año a la fecha: el mismo tramo del año anterior', () {
      final window = previousPeriodWindow(
        period: ReportPeriod.yearToDate,
        year: 2026,
        now: DateTime(2026, 8, 15, 10),
      );

      expect(window.start, DateTime(2025, 1, 1));
      expect(window.contains(DateTime(2025, 8, 15, 22)), isTrue);
      expect(window.contains(DateTime(2025, 8, 16)), isFalse,
          reason: 'solo hasta el mismo día del año anterior');
    });

    test('año a la fecha: el 29 de febrero se recorta al 28', () {
      final window = previousPeriodWindow(
        period: ReportPeriod.yearToDate,
        year: 2028,
        now: DateTime(2028, 2, 29, 12),
      );

      expect(window.start, DateTime(2027, 1, 1));
      expect(window.contains(DateTime(2027, 2, 28, 23, 50)), isTrue);
      expect(window.contains(DateTime(2027, 3, 1)), isFalse);
    });

    test('año a la fecha de un año cerrado: el año anterior completo', () {
      final window = previousPeriodWindow(
        period: ReportPeriod.yearToDate,
        year: 2025,
        now: DateTime(2026, 10, 26),
      );

      expect(window.start, DateTime(2024, 1, 1));
      expect(window.contains(DateTime(2024, 12, 31, 23)), isTrue);
    });
  });

  group('compareWithPreviousPeriod', () {
    test('mes: compara las tres cifras con el mes anterior', () {
      final previous = [
        _tx(
            type: TransactionType.income,
            amount: 2000,
            date: DateTime(2025, 12, 5)),
        _tx(
            type: TransactionType.expense,
            amount: 800,
            date: DateTime(2025, 12, 20)),
        // Fuera de la ventana: no debe colarse.
        _tx(
            type: TransactionType.income,
            amount: 9999,
            date: DateTime(2025, 11, 30)),
        // Borrado: no cuenta aunque esté en la ventana.
        _tx(
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2025, 12, 10),
            deleted: true),
      ];
      final currentRecords = [
        _tx(
            type: TransactionType.income,
            amount: 3000,
            date: DateTime(2026, 1, 10)),
        _tx(
            type: TransactionType.expense,
            amount: 1000,
            date: DateTime(2026, 1, 11)),
      ];

      final comparison = compareWithPreviousPeriod(
        current: _totals(currentRecords),
        transactions: [...previous, ...currentRecords],
        period: ReportPeriod.month,
        year: 2026,
        month: 1,
      );

      expect(comparison, isNotNull);
      expect(comparison!.period, ReportPeriod.month);
      expect(comparison.currency, 'COP');
      expect(comparison.previousIncomes, 2000);
      expect(comparison.previousExpenses, 800);
      expect(comparison.previousBalance, 1200);
      expect(comparison.incomes, 3000);
      expect(comparison.expenses, 1000);
      expect(comparison.balance, 2000);
      expect(comparison.incomeChange, 50);
      expect(comparison.expenseChange, 25);
      expect(comparison.balanceChange, closeTo(66.67, 0.01));
    });

    test('sin datos en el período anterior no se pinta nada', () {
      final currentRecords = [
        _tx(
            type: TransactionType.income,
            amount: 3000,
            date: DateTime(2026, 1, 10)),
      ];

      final comparison = compareWithPreviousPeriod(
        current: _totals(currentRecords),
        transactions: currentRecords,
        period: ReportPeriod.month,
        year: 2026,
        month: 1,
      );

      expect(comparison, isNull);
    });

    test('período anterior en otra moneda: no se compara', () {
      final previous = [
        _tx(
            type: TransactionType.income,
            amount: 2000,
            currency: 'EUR',
            date: DateTime(2025, 12, 5)),
      ];
      final currentRecords = [
        _tx(
            type: TransactionType.income,
            amount: 3000,
            date: DateTime(2026, 1, 10)),
      ];

      final comparison = compareWithPreviousPeriod(
        current: _totals(currentRecords),
        transactions: [...previous, ...currentRecords],
        period: ReportPeriod.month,
        year: 2026,
        month: 1,
      );

      expect(comparison, isNull);
    });

    test('período anterior con dos monedas: no se compara', () {
      final previous = [
        _tx(
            type: TransactionType.income,
            amount: 2000,
            date: DateTime(2025, 12, 5)),
        _tx(
            type: TransactionType.expense,
            amount: 100,
            currency: 'EUR',
            date: DateTime(2025, 12, 6)),
      ];
      final currentRecords = [
        _tx(
            type: TransactionType.income,
            amount: 3000,
            date: DateTime(2026, 1, 10)),
      ];

      final comparison = compareWithPreviousPeriod(
        current: _totals(currentRecords),
        transactions: [...previous, ...currentRecords],
        period: ReportPeriod.month,
        year: 2026,
        month: 1,
      );

      expect(comparison, isNull);
    });

    test('período actual con dos monedas: no se compara', () {
      final currentRecords = [
        _tx(
            type: TransactionType.income,
            amount: 3000,
            date: DateTime(2026, 1, 10)),
        _tx(
            type: TransactionType.expense,
            amount: 100,
            currency: 'EUR',
            date: DateTime(2026, 1, 11)),
      ];
      final previous = [
        _tx(
            type: TransactionType.income,
            amount: 2000,
            date: DateTime(2025, 12, 5)),
      ];

      final comparison = compareWithPreviousPeriod(
        current: _totals(currentRecords),
        transactions: [...previous, ...currentRecords],
        period: ReportPeriod.month,
        year: 2026,
        month: 1,
      );

      expect(comparison, isNull);
    });

    test('si el período anterior no tuvo gastos, el cambio de gastos es null',
        () {
      final previous = [
        _tx(
            type: TransactionType.income,
            amount: 2000,
            date: DateTime(2025, 12, 5)),
      ];
      final currentRecords = [
        _tx(
            type: TransactionType.income,
            amount: 3000,
            date: DateTime(2026, 1, 10)),
        _tx(
            type: TransactionType.expense,
            amount: 1000,
            date: DateTime(2026, 1, 11)),
      ];

      final comparison = compareWithPreviousPeriod(
        current: _totals(currentRecords),
        transactions: [...previous, ...currentRecords],
        period: ReportPeriod.month,
        year: 2026,
        month: 1,
      );

      expect(comparison, isNotNull);
      expect(comparison!.previousExpenses, 0);
      expect(comparison.expenseChange, isNull,
          reason: 'sin gastos anteriores no hay porcentaje honesto');
      expect(comparison.incomeChange, 50);
    });
  });

  group('changeOf', () {
    test('sin base no hay porcentaje', () {
      expect(PeriodComparison.changeOf(0, 500), isNull);
      expect(PeriodComparison.changeOf(0, 0), isNull);
    });

    test('el signo mira el valor absoluto del período anterior', () {
      expect(PeriodComparison.changeOf(100, 150), 50);
      expect(PeriodComparison.changeOf(100, 50), -50);
      expect(PeriodComparison.changeOf(-100, 100), 200,
          reason: 'de perder 100 a ganar 100 es una mejora');
      expect(PeriodComparison.changeOf(500, 500), 0);
    });
  });
}
