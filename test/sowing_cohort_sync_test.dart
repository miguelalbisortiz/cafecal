import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uuidSiembra = '22222222-2222-4222-8222-222222222222';
const _uuidVieja = '11111111-1111-4111-8111-111111111111';

Future<TransactionProvider> _provider([List<Sowing> siembras = const []]) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  if (siembras.isNotEmpty) await store.saveSowings(siembras);
  return TransactionProvider(store);
}

Sowing _renovacion({
  String id = _uuidSiembra,
  String cropId = 'c1',
  int? replacesPlants = 700,
  double? replacesAreaHa = 2.0,
  String? cohortSowingId = _uuidVieja,
  bool pendingSync = false,
}) =>
    Sowing(
      id: id,
      cropId: cropId,
      date: DateTime(2026, 3, 1),
      plants: 300,
      areaHa: 1.5,
      replacesPlants: replacesPlants,
      replacesAreaHa: replacesAreaHa,
      cohortSowingId: cohortSowingId,
      pendingSync: pendingSync,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el payload de la siembra trae el reemplazo y el puntero', () async {
    final sync = SyncProvider(await _provider());
    final row = sync.buildSowingPayload(_renovacion(), 'u1');

    expect(row['replaces_plants'], 700);
    expect(row['replaces_area_ha'], 2.0);
    expect(row['cohort_sowing_id'], _uuidVieja);

    final vacia = sync.buildSowingPayload(
        _renovacion(replacesPlants: null, replacesAreaHa: null,
            cohortSowingId: null), 'u1');
    // Las claves van aunque sean null: un upsert tiene que poder limpiarlas.
    expect(vacia.containsKey('replaces_plants'), isTrue);
    expect(vacia.containsKey('replaces_area_ha'), isTrue);
    expect(vacia.containsKey('cohort_sowing_id'), isTrue);
    expect(vacia['replaces_plants'], isNull);
    expect(vacia['cohort_sowing_id'], isNull);
  });

  test('un puntero que no es uuid sube como null', () async {
    final sync = SyncProvider(await _provider());
    final row = sync.buildSowingPayload(
        _renovacion(cohortSowingId: 'no-es-uuid'), 'u1');
    expect(row['cohort_sowing_id'], isNull);
  });

  test('el pull lee el reemplazo y el puntero', () async {
    final sync = SyncProvider(await _provider());
    final original = _renovacion();
    final row = sync.buildSowingPayload(original, 'u1');
    final vuelta = sync.remoteToSowing(row);

    expect(vuelta.replacesPlants, 700);
    expect(vuelta.replacesAreaHa, 2.0);
    expect(vuelta.cohortSowingId, _uuidVieja);
    expect(vuelta.plants, 300);
    expect(vuelta.pendingSync, isFalse);
  });

  test('una siembra vieja sin las claves entra null y sin marcarse sucia',
      () async {
    final sync = SyncProvider(await _provider());
    final row = sync.buildSowingPayload(_renovacion(), 'u1')
      ..remove('replaces_plants')
      ..remove('replaces_area_ha')
      ..remove('cohort_sowing_id');
    final vuelta = sync.remoteToSowing(row);

    expect(vuelta.replacesPlants, isNull);
    expect(vuelta.cohortSowingId, isNull);
    expect(vuelta.pendingSync, isFalse);
  });

  test('la reparación re-sube una vez las siembras con cohorte', () async {
    final p = await _provider([
      _renovacion(pendingSync: false),
      // Otro cultivo: una siembra sola, sin datos de cohorte. (Dos en el
      // mismo cultivo serían «datos viejos» y la normalización los tocaría.)
      _renovacion(
          id: '33333333-3333-4333-8333-333333333333',
          cropId: 'c2',
          replacesPlants: null,
          replacesAreaHa: null,
          cohortSowingId: null),
    ]);

    await p.repairCohortUpload();

    final porId = {for (final s in p.sowings) s.id: s};
    expect(porId[_uuidSiembra]!.pendingSync, isTrue,
        reason: 'ya subió sin los campos y no se reenviaría sola');
    expect(
        porId['33333333-3333-4333-8333-333333333333']!.pendingSync, isFalse,
        reason: 'sin cohorte no hay nada que reparar');
    expect(p.store.cohortSyncRepairDone(), isTrue);
  });

  test('la reparación no se repite en el siguiente arranque', () async {
    final p = await _provider([_renovacion(pendingSync: false)]);
    await p.repairCohortUpload();

    // Simula que el push ya la dejó limpia.
    final store = p.store;
    await store.saveSowings([
      for (final s in p.sowings) s.copyWith(pendingSync: false),
    ]);

    final otra = TransactionProvider(store);
    await otra.repairCohortUpload();

    expect(otra.sowings.single.pendingSync, isFalse,
        reason: 'la marca de reparación ya está puesta');
  });
}
