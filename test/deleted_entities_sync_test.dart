import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/employee.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uuidSiembra = '22222222-2222-4222-8222-222222222222';
const _uuidCosecha = '44444444-4444-4444-8444-444444444444';
const _uuidTrabajador = '55555555-5555-4555-8555-555555555555';
const _uuidTerreno = '66666666-6666-4666-8666-666666666666';

Future<TransactionProvider> _provider() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  await store.saveSowings([
    Sowing(
      id: _uuidSiembra,
      cropId: 'c1',
      date: DateTime(2026, 3, 1),
      plants: 300,
    ),
  ]);
  await store.saveHarvests([
    Harvest(id: _uuidCosecha, date: DateTime(2026, 3, 2), amount: 10),
  ]);
  await store.saveEmployees([
    const Employee(id: _uuidTrabajador, name: 'Pedro'),
  ]);
  await store.saveTerrenos([
    const Terreno(id: _uuidTerreno, name: 'El Alto'),
  ]);
  return TransactionProvider(store);
}

Sowing _siembra() => Sowing(
      id: _uuidSiembra,
      cropId: 'c1',
      date: DateTime(2026, 3, 1),
      plants: 300,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('borrar deja lápida y el pull no revive la siembra', () async {
    final p = await _provider();
    await p.deleteSowing(_uuidSiembra);

    expect(p.deletedSowings, contains(_uuidSiembra));
    p.mergeRemoteSowings([_siembra()]);
    expect(p.sowings.where((s) => s.id == _uuidSiembra), isEmpty);
  });

  test('borrar deja lápida y el pull no revive la cosecha', () async {
    final p = await _provider();
    await p.deleteHarvest(_uuidCosecha);

    expect(p.deletedHarvests, contains(_uuidCosecha));
    p.mergeRemoteHarvests([
      Harvest(id: _uuidCosecha, date: DateTime(2026, 3, 2), amount: 10),
    ]);
    expect(p.storedHarvests.where((h) => h.id == _uuidCosecha), isEmpty);
  });

  test('borrar deja lápida y el pull no revive el trabajador', () async {
    final p = await _provider();
    await p.deleteEmployee(_uuidTrabajador);

    expect(p.deletedEmployees, contains(_uuidTrabajador));
    p.mergeRemoteEmployees([
      const Employee(id: _uuidTrabajador, name: 'Pedro'),
    ]);
    expect(p.employees.where((e) => e.id == _uuidTrabajador), isEmpty);
  });

  test('borrar deja lápida y el pull no revive el terreno', () async {
    final p = await _provider();
    await p.deleteTerreno(_uuidTerreno);

    expect(p.deletedTerrenos, contains(_uuidTerreno));
    p.mergeRemoteTerrenos([
      const Terreno(id: _uuidTerreno, name: 'El Alto'),
    ]);
    expect(p.terrenos.where((t) => t.id == _uuidTerreno), isEmpty);
  });

  test('las lápidas se suben como borrado', () async {
    final p = await _provider();
    await p.deleteSowing(_uuidSiembra);
    await p.deleteHarvest(_uuidCosecha);
    await p.deleteEmployee(_uuidTrabajador);
    await p.deleteTerreno(_uuidTerreno);

    final stages = SyncProvider(p).buildPushStages(SupabaseService.instance);
    final borrados = {
      for (final s in stages.where((s) => s.label.startsWith('Borrado de ')))
        '${s.table}:${s.id}',
    };

    expect(borrados, containsAll([
      'sowings:$_uuidSiembra',
      'harvests:$_uuidCosecha',
      'employees:$_uuidTrabajador',
      'terrenos:$_uuidTerreno',
    ]));
  });

  test('la lápida sobrevive al reabrir', () async {
    final p = await _provider();
    await p.deleteSowing(_uuidSiembra);

    final otra = TransactionProvider(p.store);
    expect(otra.deletedSowings, contains(_uuidSiembra));
  });
}
