import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/cohort_kilos.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/backup_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uuidLote = '11111111-1111-4111-8111-111111111111';

Future<TransactionProvider> _nuevo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Transaction _jornal({
  String id = 't1',
  String? cohortSowingId = _uuidLote,
  String? cropId = 'c1',
}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 50000,
      date: DateTime(2026, 3, 12),
      createdAt: DateTime(2026, 3, 12),
      task: kTaskCosechar,
      harvestedKg: 250,
      cohortSowingId: cohortSowingId,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el payload trae cohort_sowing_id aunque sea null', () async {
    final sync = SyncProvider(await _nuevo());
    final con = sync.buildTransactionPayload(_jornal(), 'u1');
    final sin = sync.buildTransactionPayload(
        _jornal(id: 't2', cohortSowingId: null), 'u1');

    expect(con.containsKey('cohort_sowing_id'), isTrue);
    expect(con['cohort_sowing_id'], _uuidLote);
    expect(sin.containsKey('cohort_sowing_id'), isTrue);
    expect(sin['cohort_sowing_id'], isNull);
  });

  test('un id que no es uuid sube como null', () async {
    final sync = SyncProvider(await _nuevo());
    final row = sync.buildTransactionPayload(
        _jornal(cohortSowingId: 'no-es-uuid'), 'u1');
    expect(row['cohort_sowing_id'], isNull);
  });

  test('round-trip JSON con y sin la clave', () {
    expect(Transaction.fromJson(_jornal().toJson()).cohortSowingId, _uuidLote);
    expect(
        Transaction.fromJson(_jornal(cohortSowingId: null).toJson())
            .cohortSowingId,
        isNull);
  });

  test('exportar e importar conserva el puntero; respaldo viejo → null', () {
    final cosecha = _jornal(id: 't1');
    final payload = decodeBackup(encodeBackup(
      crops: const [Crop(id: 'c1', name: 'Café')],
      sowings: [
        Sowing(
          id: _uuidLote,
          cropId: 'c1',
          date: DateTime(2020, 1, 1),
          plants: 700,
        ),
      ],
      harvests: const [],
      employees: const [],
      transactions: [cosecha],
      settings: const FarmSettings(),
      now: DateTime(2026, 10, 22),
    ));
    expect(payload.transactions.single.cohortSowingId, _uuidLote);

    // Respaldo anterior a la etapa: sin la clave, entra null.
    final viejo = _jornal().toJson()..remove('cohort_sowing_id');
    expect(Transaction.fromJson(viejo).cohortSowingId, isNull);
  });

  test('el puntero huérfano cuenta como huérfano y no se reasigna', () async {
    final p = await _nuevo();
    final payload = decodeBackup(encodeBackup(
      crops: const [Crop(id: 'c1', name: 'Café')],
      sowings: const [],
      harvests: const [],
      employees: const [],
      transactions: [_jornal(id: 't1', cropId: 'c1')],
      settings: const FarmSettings(),
      now: DateTime(2026, 10, 22),
    ));

    final summary = await p.importBackup(payload);

    expect(summary.huerfanos, 1, reason: 'la siembra no está');
    final t = p.transactions.single;
    expect(t.cohortSowingId, _uuidLote,
        reason: 'la referencia no se reasigna ni se borra');
    expect(t.harvestedKg, 250, reason: 'los kilos no se pierden');
    expect(
      cohortKilos(
        cropId: 'c1',
        sowings: p.sowings,
        storedHarvests: p.storedHarvests,
        transactions: p.transactions,
      ),
      isEmpty,
      reason: 'la lectura la trata como «sin lote»',
    );
  });
}
