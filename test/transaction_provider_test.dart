import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
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

  group('Crops — dedup por nombre', () {
    test('merge remote no duplica cultivos con el mismo nombre', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      final provider = TransactionProvider(store);

      // El trigger de Supabase crea "Café"/"Plátano" con uuid, mientras
      // localmente viven con ids fijos ('cafe', 'platano').
      provider.mergeRemoteCrops(const [
        Crop(id: 'uuid-cafe', name: 'Café'),
        Crop(id: 'uuid-platano', name: 'Plátano'),
      ]);

      final names = provider.crops.map((c) => c.name).toList();
      expect(names.where((n) => n == 'Café').length, 1);
      expect(names.where((n) => n == 'Plátano').length, 1);
    });

    test('merge remote ignora solo id, no nombre', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      final provider = TransactionProvider(store);

      provider.mergeRemoteCrops(const [
        Crop(id: 'a', name: 'Café'),
        Crop(id: 'b', name: 'Caña'),
      ]);

      expect(provider.crops.map((c) => c.name).toSet(),
          containsAll(['Café', 'Plátano', 'Otro', 'Caña']));
    });

    test('loadCrops deduplica registrarizados preexistentes', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.crops_v1': '['
            '{"id":"cafe","name":"Café","phase":"produccion","cycle":"perenne"},'
            '{"id":"uuid-cafe","name":"Café","phase":"produccion","cycle":"perenne"}'
            ']',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      expect(store.loadCrops().length, 1);
      expect(store.loadCrops().single.id, 'cafe');
    });
  });
}