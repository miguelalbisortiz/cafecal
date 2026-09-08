import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _txnJson(String id, double amount) =>
    '{"id":"$id","type":"expense","category":"fertilizante","amount":$amount,'
    '"currency":"COP","description":"","date":"2026-03-01",'
    '"created_at":"2026-03-01T00:00:00.000Z","pending_sync":false,"deleted":false,'
    '"quantity":null,"unit":null,"price_per_unit":null,"client":null,'
    '"provider":null,"harvest_id":null,"sowing_id":null}';

Transaction _txn(String id, double amount) =>
    Transaction.fromJson(
        (jsonDecode(_txnJson(id, amount)) as Map).cast<String, dynamic>());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStore — aislamiento por usuario (H1)', () {
    test('datos de un uid NO son visibles para otro uid', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final storeA = LocalStore(prefs, uid: 'user-A');
      await storeA.saveTransactions([_txn('t1', 100)]);

      final storeB = LocalStore(prefs, uid: 'user-B');
      expect(storeB.loadTransactions(), isEmpty);
      expect(storeA.loadTransactions(), isNotEmpty);
    });

    test('sin uid usa las claves legacy (compatibilidad)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final legacy = LocalStore(prefs);

      await legacy.saveTransactions([_txn('t1', 100)]);

      expect(prefs.getString('transactions_v1'), isNotNull);
      expect(prefs.getString('transactions_v1_user-A'), isNull);

      final storeA = LocalStore(prefs, uid: 'user-A');
      expect(storeA.loadTransactions(), isEmpty);
    });

    test('permanencia del namespace: volver al uid original recupera sus datos',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs, uid: 'user-A');
      await store.saveTransactions([_txn('t1', 100)]);

      await store.bindUser('user-B');
      expect(store.loadTransactions(), isEmpty);

      await store.bindUser('user-A');
      expect(store.loadTransactions(), isNotEmpty);
    });

    test('clearAll borra solo las claves del uid actual', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final storeA = LocalStore(prefs, uid: 'user-A');
      await storeA.saveTransactions([_txn('a1', 100)]);
      final storeB = LocalStore(prefs, uid: 'user-B');
      await storeB.saveTransactions([_txn('b1', 50)]);

      await storeA.clearAll();

      expect(storeA.loadTransactions(), isEmpty);
      expect(storeB.loadTransactions(), isNotEmpty);
      expect(prefs.getString('transactions_v1_user-A'), isNull);
    });

    test('migra las claves legacy al primer bind con uid y borra el legacy',
        () async {
      SharedPreferences.setMockInitialValues({
        'transactions_v1': '[${_txnJson('old', 777)}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await LocalStore.create(uid: 'user-A');

      final txns = store.loadTransactions();
      expect(txns, hasLength(1));
      expect(txns.single.id, 'old');
      expect(txns.single.amount, 777);
      expect(prefs.getString('transactions_v1_user-A'), isNotNull);
      expect(prefs.getString('transactions_v1'), isNull);
    });

    test('no migra si el uid ya tiene datos (no pisa nada)', () async {
      SharedPreferences.setMockInitialValues({
        'transactions_v1': '[${_txnJson('legacy', 1)}]',
        'transactions_v1_user-A': '[${_txnJson('namespaced', 2)}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await LocalStore.create(uid: 'user-A');

      expect(store.loadTransactions().single.amount, 2);
      expect(prefs.getString('transactions_v1'), isNotNull);
    });
  });

  group('TransactionProvider — reload tras cambio de usuario', () {
    test('reloadFromCache carga el namespace del usuario activo', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs, uid: 'user-A');
      await store.saveTransactions([_txn('t1', 100)]);

      final provider = TransactionProvider(store);
      expect(provider.transactions, hasLength(1));

      // Cambia el usuario activo (login de otra cuenta): se vacía el cache.
      await store.bindUser('user-B');
      await provider.reloadFromCache();
      expect(provider.transactions, isEmpty);

      // Vuelve A: recupera sus datos.
      await store.bindUser('user-A');
      await provider.reloadFromCache();
      expect(provider.transactions, hasLength(1));
    });
  });
}