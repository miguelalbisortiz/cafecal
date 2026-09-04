import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Transaction cuenta gastos e ingresos del año', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final provider = TransactionProvider(store);

    final expense = Transaction(
      id: 't1',
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 100,
      date: DateTime(2026, 3, 1),
      createdAt: DateTime(2026, 3, 1),
    );
    final income = Transaction(
      id: 't2',
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 300,
      date: DateTime(2026, 10, 15),
      createdAt: DateTime(2026, 10, 15),
    );

    await provider.addTransaction(
      type: expense.type,
      category: expense.category,
      amount: expense.amount,
      date: expense.date,
    );
    await provider.addTransaction(
      type: income.type,
      category: income.category,
      amount: income.amount,
      date: income.date,
    );

    expect(provider.totalExpenses(year: 2026), 100);
    expect(provider.totalIncomes(year: 2026), 300);
    expect(provider.totalExpenses(year: 2025), 0);
  });

  test('delete marca la transacción y excluye del total', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final provider = TransactionProvider(store);

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'riego',
      amount: 50,
      date: DateTime(2026, 2, 1),
    );

    final id = provider.transactions.first.id;
    expect(provider.totalExpenses(year: 2026), 50);

    await provider.deleteTransaction(id);
    expect(provider.totalExpenses(year: 2026), 0);
    expect(provider.transactions.first.deleted, isTrue);
  });
}