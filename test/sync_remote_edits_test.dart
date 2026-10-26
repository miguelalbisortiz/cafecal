import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/employee.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TransactionProvider> _provider() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Crop _crop(String name, {bool pending = false}) => Crop(
      id: 'c1',
      name: name,
      pendingSync: pending,
    );

Sowing _sowing(int plants, {bool pending = false}) => Sowing(
      id: '22222222-2222-4222-8222-222222222222',
      cropId: 'c1',
      date: DateTime(2026, 3, 1),
      plants: plants,
      pendingSync: pending,
    );

Harvest _harvest(double kg, {bool pending = false}) => Harvest(
      id: '44444444-4444-4444-8444-444444444444',
      date: DateTime(2026, 3, 2),
      amount: kg,
      pendingSync: pending,
    );

Employee _employee(String name, {bool pending = false}) => Employee(
      id: '55555555-5555-4555-8555-555555555555',
      name: name,
      pendingSync: pending,
    );

Terreno _terreno(String name, {bool pending = false}) => Terreno(
      id: '66666666-6666-4666-8666-666666666666',
      name: name,
      pendingSync: pending,
    );

Transaction _tx(double amount, {bool pending = false}) => Transaction(
      id: 't1',
      type: TransactionType.expense,
      category: 'otros',
      amount: amount,
      date: DateTime(2026, 3, 3),
      createdAt: DateTime(2026, 3, 3),
      pendingSync: pending,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el pull aplica la edición remota si lo local está sincronizado',
      () async {
    final p = await _provider();
    p.mergeRemoteSowings([_sowing(300)]);
    p.mergeRemoteSowings([_sowing(500)]);
    expect(p.sowings.single.plants, 500);
  });

  test('el pull no pisa una edición local sin subir', () async {
    final p = await _provider();
    p.mergeRemoteSowings([_sowing(300, pending: true)]);
    p.mergeRemoteSowings([_sowing(500)]);
    expect(p.sowings.single.plants, 300);
  });

  test('el pull no revive lo que tiene lápida', () async {
    final p = await _provider();
    p.mergeRemoteSowings([_sowing(300)]);
    await p.deleteSowing('22222222-2222-4222-8222-222222222222');
    p.mergeRemoteSowings([_sowing(500)]);
    expect(p.sowings, isEmpty);
  });

  test('el pull aplica la edición remota del cultivo', () async {
    final p = await _provider();
    p.mergeRemoteCrops([_crop('Café viejo')]);
    p.mergeRemoteCrops([_crop('Café nuevo')]);
    expect(p.crops.single.name, 'Café nuevo');
  });

  test('el pull aplica la edición remota de la cosecha', () async {
    final p = await _provider();
    p.mergeRemoteHarvests([_harvest(10)]);
    p.mergeRemoteHarvests([_harvest(25)]);
    expect(p.storedHarvests.single.amount, 25);
  });

  test('el pull aplica la edición remota del trabajador', () async {
    final p = await _provider();
    p.mergeRemoteEmployees([_employee('Pedro')]);
    p.mergeRemoteEmployees([_employee('Pedro Ruiz')]);
    expect(p.employees.single.name, 'Pedro Ruiz');
  });

  test('el pull aplica la edición remota del terreno', () async {
    final p = await _provider();
    p.mergeRemoteTerrenos([_terreno('El Alto')]);
    p.mergeRemoteTerrenos([_terreno('El Alto de la Loma')]);
    expect(p.terrenos.single.name, 'El Alto de la Loma');
  });

  test('el pull aplica la edición remota del movimiento', () async {
    final p = await _provider();
    p.mergeRemote([_tx(50000)]);
    p.mergeRemote([_tx(70000)]);
    expect(p.transactions.single.amount, 70000);
  });

  test('el pull no pisa un movimiento local sin subir', () async {
    final p = await _provider();
    p.mergeRemote([_tx(50000, pending: true)]);
    p.mergeRemote([_tx(70000)]);
    expect(p.transactions.single.amount, 50000);
  });
}
