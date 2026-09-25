import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/employee.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regresiones del fallo de subida del 2026-09-25: ninguna cuenta logueada
/// llegaba a escribir filas en Supabase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uid = 'f409b97c-2abf-4fa7-af50-eec416e50fff';
  const cropUuid = '5df76f69-06ee-4b42-8dfd-5b676100109d';
  const harvestUuid = '11111111-2222-4333-8444-555555555555';
  const sowingUuid = '99999999-8888-4777-8666-555555555555';

  Future<TransactionProvider> newProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  /// Solo construye payloads y etapas: nunca toca la red, así que basta
  /// con el singleton (sus closures no se ejecutan).
  Future<SyncProvider> newSync() async => SyncProvider(await newProvider());

  Transaction txn({required String id, String? cropId}) => Transaction(
        id: id,
        cropId: cropId,
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 10000,
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

  group('Orden de subida (clave foránea)', () {
    test('settings y cultivos van antes que las transacciones', () async {
      final tx = await newProvider();
      tx.mergeRemoteCrops([const Crop(id: cropUuid, name: 'Café')]);
      tx.mergeRemote([txn(id: 't1', cropId: cropUuid)]);

      final tables = SyncProvider(tx)
          .buildPushStages(SupabaseService.instance)
          .map((s) => s.table)
          .toList();

      expect(tables.first, 'settings');
      expect(tables.last, 'transactions');
      expect(tables.indexOf('crops'), lessThan(tables.indexOf('transactions')));
      expect(tables.indexOf('settings'), lessThan(tables.indexOf('crops')));
    });

    test('siembras, cosechas y trabajadores van antes que las transacciones',
        () async {
      final tx = await newProvider();
      tx.mergeRemoteCrops([const Crop(id: cropUuid, name: 'Café')]);
      tx.mergeRemoteSowings([
        Sowing(
            id: sowingUuid,
            cropId: cropUuid,
            date: DateTime(2026, 3, 1),
            plants: 100),
      ]);
      tx.mergeRemoteHarvests([
        Harvest(
            id: harvestUuid,
            cropId: cropUuid,
            date: DateTime(2026, 9, 1),
            amount: 120),
      ]);
      tx.mergeRemoteEmployees([
        const Employee(id: 'e1', name: 'Luis', dayRate: 50000),
      ]);
      tx.mergeRemote([txn(id: 't1', cropId: cropUuid)]);

      final sync = SyncProvider(tx);
      final tables = sync
          .buildPushStages(SupabaseService.instance)
          .map((s) => s.table)
          .toList();

      expect(tables.indexOf('crops'), lessThan(tables.indexOf('sowings')));
      expect(tables.indexOf('crops'), lessThan(tables.indexOf('harvests')));
      expect(
          tables.indexOf('employees'), lessThan(tables.indexOf('transactions')));
      expect(tables.indexOf('sowings'), lessThan(tables.indexOf('transactions')));
      expect(
          tables.indexOf('harvests'), lessThan(tables.indexOf('transactions')));
    });

    test('un cultivo con id legado no se convierte en etapa de subida',
        () async {
      final tx = await newProvider();
      tx.mergeRemoteCrops([
        const Crop(id: 'cafe', name: 'Café'),
        const Crop(id: cropUuid, name: 'Plátano'),
      ]);

      final cropIds = SyncProvider(tx)
          .buildPushStages(SupabaseService.instance)
          .where((s) => s.table == 'crops')
          .map((s) => s.id)
          .toList();

      expect(cropIds, [cropUuid]);
    });
  });

  group('Payload: ids referenciados', () {
    test('crop_id legado se envía como null, nunca como texto', () async {
      final payload =
          (await newSync()).buildTransactionPayload(txn(id: 't1', cropId: 'cafe'), uid);

      expect(payload['crop_id'], isNull);
      expect(payload['id'], 't1');
      expect(payload['user_id'], uid);
    });

    test('crop_id uuid válido se conserva tal cual', () async {
      final payload = (await newSync())
          .buildTransactionPayload(txn(id: 't1', cropId: cropUuid), uid);

      expect(payload['crop_id'], cropUuid);
    });

    test('los tres ids referenciados se validan', () async {
      final sync = await newSync();

      final txnPayload = sync.buildTransactionPayload(txn(id: 't1'), uid);
      expect(txnPayload['crop_id'], isNull);

      final sowing = sync.buildSowingPayload(
        Sowing(
            id: 's1',
            cropId: 'platano',
            date: DateTime(2026, 3, 1),
            plants: 10),
        uid,
      );
      expect(sowing['crop_id'], isNull);

      final harvest = sync.buildHarvestPayload(
        Harvest(
            id: 'h1', cropId: 'cafe', date: DateTime(2026, 9, 1), amount: 120),
        uid,
      );
      expect(harvest['crop_id'], isNull);
    });

    test('el payload de cultivo incluye currency', () async {
      final payload = (await newSync()).buildCropPayload(
          const Crop(id: cropUuid, name: 'Café', currency: 'COP'), uid);

      expect(payload.containsKey('currency'), isTrue);
      expect(payload['currency'], 'COP');
    });
  });

  group('markAllSynced(selectivo)', () {
    test('lo que falló sigue pendiente y lo demás se limpia', () async {
      final tx = await newProvider();
      await tx.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 100,
        date: DateTime(2026, 9, 1),
      );
      await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 300,
        date: DateTime(2026, 9, 2),
      );
      final first = tx.transactions.first.id;

      await tx.markAllSynced(skip: {first});

      expect(tx.transactions.first.pendingSync, isTrue);
      expect(tx.transactions.last.pendingSync, isFalse);
    });

    test('un borrado que no subió no se descarta (volvería en el pull)',
        () async {
      final tx = await newProvider();
      await tx.addTransaction(
        type: TransactionType.expense,
        category: 'riego',
        amount: 50,
        date: DateTime(2026, 9, 1),
      );
      final id = tx.transactions.first.id;
      await tx.deleteTransaction(id);

      await tx.markAllSynced(skip: {id});

      expect(tx.transactions.any((t) => t.id == id && t.deleted), isTrue);
    });
  });

  group('Ajustes: sucio / limpio', () {
    test('editar marca pendiente y subirlo lo limpia', () async {
      final tx = await newProvider();
      expect(tx.settingsDirty, isFalse);

      await tx.updateSettings(tx.settings.copyWith(cajaMenorMensual: 300000.0));
      expect(tx.settingsDirty, isTrue);

      await tx.markSettingsSynced();
      expect(tx.settingsDirty, isFalse);
    });

    test('sin cambios locales, lo remoto se aplica', () async {
      final tx = await newProvider();
      tx.applyRemoteSettings(const FarmSettings(farmName: 'Finca Remota'));
      expect(tx.settings.farmName, 'Finca Remota');
    });

    test('con cambios locales, lo remoto NO pisa la caja menor', () async {
      final tx = await newProvider();
      await tx.updateSettings(
          const FarmSettings(farmName: 'La mía', cajaMenorMensual: 300000));

      tx.applyRemoteSettings(const FarmSettings(farmName: 'Otra'));

      expect(tx.settings.farmName, 'La mía');
      expect(tx.settings.cajaMenorMensual, 300000);
    });
  });

  group('LocalStore: marca de ajustes sucios', () {
    test('persiste y se aísla por usuario', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final storeA = LocalStore(prefs, uid: 'user-A');
      final storeB = LocalStore(prefs, uid: 'user-B');

      await storeA.saveSettingsDirty(true);

      expect(storeA.loadSettingsDirty(), isTrue);
      expect(storeB.loadSettingsDirty(), isFalse);
    });
  });
}
