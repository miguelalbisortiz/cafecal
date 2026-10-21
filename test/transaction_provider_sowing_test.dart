import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TransactionProvider> _nuevo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Cohort _cohorte(TransactionProvider p, String cropId, String id) =>
    cropCohorts(cropId, p.sowings).firstWhere((c) => c.sowingId == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T9 · escrituras con cohortes', () {
    test('addSowing con reemplazo deja las cohortes y los totales correctos',
        () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);
      await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          areaHa: 1,
          replacesPlants: 300,
          replacesAreaHa: 1,
          cohortSowingId: s1.id);

      expect(p.crops.single.livePlants, 1000, reason: '700 + 300');
      expect(p.crops.single.areaHa, 5, reason: '4 + 1');
      expect(_cohorte(p, crop.id, s1.id).livePlants, 700);
      expect(_cohorte(p, crop.id, s1.id).areaHa, 4);
    });

    test('updateSowing que baja replacesPlants a 0 devuelve las matas',
        () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);
      final s2 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          areaHa: 1,
          replacesPlants: 300,
          replacesAreaHa: 1,
          cohortSowingId: s1.id);

      await p.updateSowing(
          s2.copyWith(replacesPlants: 0, replacesAreaHa: null));

      expect(p.crops.single.livePlants, 1300, reason: 'era expansión');
      expect(p.crops.single.areaHa, 6);
    });

    test('updateSowing por encima de las vivas no deja negativos', () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);
      final s2 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          areaHa: 1,
          replacesPlants: 300,
          replacesAreaHa: 1,
          cohortSowingId: s1.id);

      await p.updateSowing(s2.copyWith(replacesPlants: 5000));

      expect(_cohorte(p, crop.id, s1.id).livePlants, 0);
      expect(p.crops.single.livePlants, 300);
      expect(p.crops.single.areaHa, 1);
    });

    test('deleteSowing de la vieja deja el puntero en null y pendiente',
        () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);
      await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          areaHa: 1,
          replacesPlants: 300,
          replacesAreaHa: 1,
          cohortSowingId: s1.id);

      await p.deleteSowing(s1.id);

      final s2 = p.sowings.single;
      expect(s2.cohortSowingId, isNull);
      expect(s2.pendingSync, isTrue, reason: 'la corrección tiene que subir');
      expect(p.crops.single.livePlants, 300);
      expect(p.crops.single.areaHa, 1);
    });

    test('deleteSowing de la nueva devuelve matas y área a la vieja', () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);
      final s2 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          areaHa: 1,
          replacesPlants: 300,
          replacesAreaHa: 1,
          cohortSowingId: s1.id);

      await p.deleteSowing(s2.id);

      expect(p.sowings.single.id, s1.id);
      expect(p.crops.single.livePlants, 1000);
      expect(p.crops.single.areaHa, 5);
    });

    test('deleteSowing de la nueva no toca el puntero de las demás', () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);
      final s2 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          areaHa: 1,
          replacesPlants: 300,
          replacesAreaHa: 1,
          cohortSowingId: s1.id);
      final s3 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2028, 1, 1),
          plants: 100,
          replacesPlants: 300,
          cohortSowingId: s2.id);

      await p.deleteSowing(s3.id);

      expect(p.sowings.firstWhere((s) => s.id == s2.id).cohortSowingId, s1.id);
    });

    test('toda escritura deja pendingSync en siembras y cultivos', () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      final s1 = await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          areaHa: 5);

      expect(s1.pendingSync, isTrue);
      expect(p.crops.single.pendingSync, isTrue);
    });

    test('área con una cohorte sin área conserva la manual y no la pisa',
        () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café', areaHa: 5, livePlants: 1000);
      await p.addSowing(
          cropId: crop.id, date: DateTime(2020, 1, 1), plants: 1000);
      await p.addSowing(
          cropId: crop.id,
          date: DateTime(2027, 1, 1),
          plants: 300,
          replacesPlants: 0);

      expect(p.crops.single.areaHa, 5,
          reason: 'falta un área: no se inventa la suma ni se pisa la manual');
    });

    test('addSowing guarda el 0 explícito de la expansión', () async {
      final p = await _nuevo();
      final crop = await p.addCrop('Café');
      await p.addSowing(
          cropId: crop.id,
          date: DateTime(2020, 1, 1),
          plants: 1000,
          replacesPlants: 0);

      final s = p.sowings.single;
      expect(s.replacesPlants, 0, reason: 'nunca queda en null');
      expect(s.toJson()['replaces_plants'], 0);
    });
  });

  group('T10 · normalización al abrir y tras el pull', () {
    Future<LocalStore> sembrarViejo() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      await store.saveCrops([
        const Crop(id: 'cafe', name: 'Café', areaHa: 5, livePlants: 1000),
      ]);
      await store.saveSowings([
        Sowing(
            id: 's1',
            cropId: 'cafe',
            date: DateTime(2020, 1, 1),
            plants: 1000,
            areaHa: 5),
        Sowing(
            id: 's2',
            cropId: 'cafe',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1),
      ]);
      return store;
    }

    test('al abrir un cultivo viejo los números quedan exactamente iguales',
        () async {
      final store = await sembrarViejo();
      final p = TransactionProvider(store);
      await p.reloadFromCache();

      expect(p.crops.single.livePlants, 300, reason: 'lo mismo que antes');
      expect(p.crops.single.areaHa, 1);

      final s2 = p.sowings.firstWhere((s) => s.id == 's2');
      expect(s2.replacesPlants, 1000);
      expect(s2.replacesAreaHa, 5);
      expect(s2.cohortSowingId, 's1');
      expect(s2.pendingSync, isTrue);
    });

    test('normaliza una sola vez: la segunda apertura no cambia nada', () async {
      final store = await sembrarViejo();
      final p1 = TransactionProvider(store);
      await p1.reloadFromCache();

      final p2 = TransactionProvider(store);
      expect(normalizeLegacyCohorts(p2.sowings).changed, isFalse);
    });

    test('un puntero que llega antes que su cohorte se conserva', () async {
      final p = await _nuevo();
      await p.addCrop('Café');
      p.mergeRemoteSowings([
        Sowing(
            id: 'x',
            cropId: 'cafe',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 300,
            cohortSowingId: 'todavia-no-llego'),
      ]);

      expect(p.sowings.single.cohortSowingId, 'todavia-no-llego',
          reason: 'no se anula: puede llegar en el próximo pull');
    });

    test('tras el pull los cultivos afectados quedan recalculados', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      await store.saveCrops([const Crop(id: 'cafe', name: 'Café')]);
      final p = TransactionProvider(store);

      p.mergeRemoteSowings([
        Sowing(
            id: 's1',
            cropId: 'cafe',
            date: DateTime(2020, 1, 1),
            plants: 1000,
            areaHa: 5),
      ]);
      await pumpEventQueue();

      expect(p.crops.single.livePlants, 1000);
      expect(p.crops.single.areaHa, 5);
    });
  });
}
