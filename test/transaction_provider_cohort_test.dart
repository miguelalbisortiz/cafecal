import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/cohort_kilos.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TransactionProvider> _nuevo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addTransaction guarda el puntero y pendingSync', () async {
    final p = await _nuevo();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final lote = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 1000);

    final t = await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      cropId: crop.id,
      task: kTaskCosechar,
      harvestedKg: 250,
      cohortSowingId: lote.id,
    );

    expect(t.cohortSowingId, lote.id);
    expect(t.pendingSync, isTrue);
    expect(p.transactions.single.cohortSowingId, lote.id);
  });

  test('updateTransaction cambia el lote y puede limpiarlo', () async {
    final p = await _nuevo();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final a = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700);
    final b = await p.addSowing(
        cropId: crop.id, date: DateTime(2026, 3, 12), plants: 300);
    final t = await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      cropId: crop.id,
      task: kTaskCosechar,
      harvestedKg: 250,
      cohortSowingId: a.id,
    );

    await p.updateTransaction(t.copyWith(cohortSowingId: b.id));
    expect(p.transactions.single.cohortSowingId, b.id);

    await p.updateTransaction(
        p.transactions.single.copyWith(cohortSowingId: null));
    expect(p.transactions.single.cohortSowingId, isNull);
  });

  test(
      'deleteSowing limpia el puntero de los jornales y los kilos del cultivo '
      'no cambian', () async {
    final p = await _nuevo();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final viejo = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700);
    await p.addSowing(
        cropId: crop.id, date: DateTime(2026, 3, 12), plants: 300);
    await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      cropId: crop.id,
      task: kTaskCosechar,
      harvestedKg: 250,
      cohortSowingId: viejo.id,
    );

    final antes = p.transactions
        .where((t) => t.harvestedKg != null)
        .fold<double>(0, (s, t) => s + t.harvestedKg!);

    await p.deleteSowing(viejo.id);

    final t = p.transactions.single;
    expect(t.cohortSowingId, isNull, reason: 'el dato no se reasigna');
    expect(t.pendingSync, isTrue, reason: 'la corrección tiene que subir');
    expect(t.harvestedKg, 250, reason: 'los kilos no se borran');
    final despues = p.transactions
        .where((x) => x.harvestedKg != null)
        .fold<double>(0, (s, x) => s + x.harvestedKg!);
    expect(despues, antes);
    expect(
      cohortKilos(
        cropId: crop.id,
        sowings: p.sowings,
        storedHarvests: p.storedHarvests,
        transactions: p.transactions,
      ),
      isEmpty,
    );
  });

  test('deleteSowing no toca jornales de otras siembras', () async {
    final p = await _nuevo();
    final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
    final a = await p.addSowing(
        cropId: crop.id, date: DateTime(2020, 3, 12), plants: 700);
    final b = await p.addSowing(
        cropId: crop.id, date: DateTime(2026, 3, 12), plants: 300);
    final ta = await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      cropId: crop.id,
      task: kTaskCosechar,
      harvestedKg: 250,
      cohortSowingId: a.id,
    );
    final tb = await p.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 40000,
      cropId: crop.id,
      task: kTaskCosechar,
      harvestedKg: 180,
      cohortSowingId: b.id,
    );

    final antesB = p.transactions.firstWhere((t) => t.id == tb.id).pendingSync;

    await p.deleteSowing(a.id);

    final quedoA = p.transactions.firstWhere((t) => t.id == ta.id);
    final quedoB = p.transactions.firstWhere((t) => t.id == tb.id);
    expect(quedoA.cohortSowingId, isNull);
    expect(quedoA.pendingSync, isTrue);
    expect(quedoB.cohortSowingId, b.id);
    expect(quedoB.pendingSync, antesB, reason: 'no se marcó de más');
  });
}
