import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/cohort_kilos.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';

Sowing _s({
  required String id,
  String? cropId = 'cafe',
  required DateTime date,
  SowingKind kind = SowingKind.siembra,
  int plants = 700,
  int? lostPlants,
  String? cohortSowingId,
}) =>
    Sowing(
      id: id,
      cropId: cropId,
      date: date,
      kind: kind,
      plants: plants,
      lostPlants: lostPlants,
      cohortSowingId: cohortSowingId,
    );

Transaction _j({
  String id = 'j1',
  String? cropId = 'cafe',
  String? cohortSowingId,
  double? kg = 250,
  String? task = kTaskCosechar,
  String category = 'mano_obra',
  TransactionType type = TransactionType.expense,
  bool deleted = false,
  DateTime? date,
}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: type,
      category: category,
      amount: 50000,
      date: date ?? DateTime(2026, 3, 12),
      createdAt: date ?? DateTime(2026, 3, 12),
      deleted: deleted,
      task: task,
      harvestedKg: kg,
      cohortSowingId: cohortSowingId,
    );

Harvest _cosechaManual({String cropId = 'cafe'}) => Harvest(
      id: 'h1',
      cropId: cropId,
      date: DateTime(2026, 3, 12),
      amount: 100,
      unit: 'kg',
    );

void main() {
  final viejo = _s(id: 's1', date: DateTime(2020, 3, 12), plants: 700);
  final nuevo = _s(id: 's2', date: DateTime(2026, 3, 12), plants: 300);

  group('Etapa B · cohortKilos', () {
    test('suma por lote: 250 al viejo y 180 al nuevo', () {
      final kilos = cohortKilos(
        cropId: 'cafe',
        sowings: [viejo, nuevo],
        storedHarvests: const [],
        transactions: [
          _j(id: 'a', cohortSowingId: 's1', kg: 250),
          _j(id: 'b', cohortSowingId: 's2', kg: 180),
          _j(id: 'c', cohortSowingId: 's1', kg: 50, date: DateTime(2026, 4, 1)),
        ],
      );
      expect(kilos, {'s1': 300, 's2': 180});
    });

    test(
        'ignora borrados, ingresos, otras labores, kg null o 0 y otros cultivos',
        () {
      final kilos = cohortKilos(
        cropId: 'cafe',
        sowings: [viejo, nuevo],
        storedHarvests: const [],
        transactions: [
          _j(id: 'ok', cohortSowingId: 's1', kg: 250),
          _j(id: 'borrado', cohortSowingId: 's1', deleted: true),
          _j(id: 'venta', cohortSowingId: 's1', type: TransactionType.income),
          _j(id: 'abono', cohortSowingId: 's1', task: 'abonar'),
          _j(id: 'sin kg', cohortSowingId: 's1', kg: null),
          _j(id: 'cero', cohortSowingId: 's1', kg: 0),
          _j(id: 'otro cultivo', cohortSowingId: 's1', cropId: 'otro'),
        ],
      );
      expect(kilos, {'s1': 250});
    });

    test('sin puntero o con puntero roto: no entra al mapa y no se reasigna',
        () {
      final kilos = cohortKilos(
        cropId: 'cafe',
        sowings: [viejo, nuevo],
        storedHarvests: const [],
        transactions: [
          _j(id: 'sin lote', cohortSowingId: null, kg: 50),
          _j(id: 'roto', cohortSowingId: 'no-existe', kg: 80),
        ],
      );
      expect(kilos, isEmpty);
    });

    test('un puntero a una resiembra no es un lote', () {
      final resiembra = _s(
        id: 'r1',
        date: DateTime(2026, 5, 1),
        kind: SowingKind.resiembra,
        plants: 40,
        cohortSowingId: 's1',
      );
      final kilos = cohortKilos(
        cropId: 'cafe',
        sowings: [viejo, resiembra],
        storedHarvests: const [],
        transactions: [_j(cohortSowingId: 'r1', kg: 60)],
      );
      expect(kilos, isEmpty);
    });

    test('cosecha manual guardada: no hay kg por lote', () {
      final kilos = cohortKilos(
        cropId: 'cafe',
        sowings: [viejo, nuevo],
        storedHarvests: [_cosechaManual()],
        transactions: [_j(cohortSowingId: 's1', kg: 250)],
      );
      expect(kilos, isEmpty);
    });

    test('kg/planta: 250 entre 700 matas da 0,357…', () {
      final v = kgPerPlantCohort(250, 700);
      expect(v, isNotNull);
      expect(v!, closeTo(0.3571428, 0.0000001));
    });

    test('kg/planta sin kilos o sin matas vivas es null, nunca 0', () {
      expect(kgPerPlantCohort(null, 700), isNull);
      expect(kgPerPlantCohort(0, 700), isNull);
      expect(kgPerPlantCohort(250, 0), isNull);
    });
  });
}
