import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/currency_totals.dart';

Transaction _tx({
  required TransactionType type,
  required double amount,
  String currency = 'COP',
  String category = 'otro',
  bool deleted = false,
}) =>
    Transaction(
      id: '$type-$currency-$amount-$deleted',
      type: type,
      category: category,
      amount: amount,
      currency: currency,
      date: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
      deleted: deleted,
    );

void main() {
  group('amountsByCurrency', () {
    test('una sola moneda devuelve un único total', () {
      final totals = amountsByCurrency([
        _tx(type: TransactionType.income, amount: 5000),
        _tx(type: TransactionType.income, amount: 300),
        _tx(type: TransactionType.expense, amount: 1000),
      ]);

      expect(totals, {'COP': 6300.0},
          reason: 'una sola moneda = una única entrada (5.000 + 300 + 1.000)');
    });

    test('mezcla monedas: un total por código, nunca sumadas entre sí', () {
      final totals = amountsByCurrency([
        _tx(type: TransactionType.income, amount: 5000),
        _tx(type: TransactionType.income, amount: 200, currency: 'EUR'),
        _tx(type: TransactionType.income, amount: 7, currency: 'BRL'),
      ]);

      expect(totals.keys.toSet(), {'COP', 'EUR', 'BRL'});
      expect(totals['COP'], 5000);
      expect(totals['EUR'], 200);
      expect(totals['BRL'], 7);
      expect(totals.values.fold<double>(0, (a, b) => a + b), 5207,
          reason: 'la suma total existe, pero cada entrada sigue separada');
    });

    test('los registros borrados no cuentan', () {
      final totals = amountsByCurrency([
        _tx(type: TransactionType.income, amount: 1000),
        _tx(type: TransactionType.income, amount: 999, deleted: true),
        _tx(type: TransactionType.expense, amount: 500, currency: 'EUR'),
        _tx(type: TransactionType.expense, amount: 888,
            currency: 'EUR', deleted: true),
      ]);

      expect(totals, {'COP': 1000.0, 'EUR': 500.0});
    });

    test('se puede pedir solo un tipo de movimiento', () {
      final records = [
        _tx(type: TransactionType.income, amount: 400),
        _tx(type: TransactionType.expense, amount: 150),
      ];

      expect(amountsByCurrency(records, type: TransactionType.income),
          {'COP': 400.0});
      expect(amountsByCurrency(records, type: TransactionType.expense),
          {'COP': 150.0});
    });
  });

  group('PeriodCurrencyTotals', () {
    test('una moneda no se considera mezcla', () {
      final totals = PeriodCurrencyTotals.fromRecords([
        _tx(type: TransactionType.income, amount: 5000),
        _tx(type: TransactionType.expense, amount: 1000),
        _tx(type: TransactionType.expense, amount: 500, deleted: true),
      ]);

      expect(totals.isMixed, isFalse);
      expect(totals.currencies, {'COP'});
      expect(totals.incomeOf('COP'), 5000);
      expect(totals.expenseOf('COP'), 1000);
      expect(totals.resultOf('COP'), 4000);
    });

    test('dos monedas sí es mezcla y cada resultado es suyo', () {
      final totals = PeriodCurrencyTotals.fromRecords([
        _tx(type: TransactionType.income, amount: 5000),
        _tx(type: TransactionType.expense, amount: 1000),
        _tx(type: TransactionType.income, amount: 200, currency: 'EUR'),
        _tx(type: TransactionType.expense, amount: 50, currency: 'EUR'),
        _tx(type: TransactionType.income, amount: 777, currency: 'USD',
            deleted: true),
      ]);

      expect(totals.isMixed, isTrue);
      expect(totals.currencies, {'COP', 'EUR'},
          reason: 'la moneda borrada no debe abrir una tercera columna');
      expect(totals.resultOf('COP'), 4000);
      expect(totals.resultOf('EUR'), 150);
      expect(totals.incomeOf('USD'), 0);
    });

    test('período vacío: sin monedas y sin mezcla', () {
      final totals = PeriodCurrencyTotals.fromRecords(const []);

      expect(totals.currencies, isEmpty);
      expect(totals.isMixed, isFalse);
      expect(totals.incomes, isEmpty);
      expect(totals.expenses, isEmpty);
    });
  });
}
