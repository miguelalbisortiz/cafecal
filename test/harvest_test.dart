import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/harvest.dart';

void main() {
  group('Harvest JSON', () {
    test('round-trip conserva campos y destino', () {
      final h = Harvest(
        id: 'h1',
        cropId: 'cafe',
        date: DateTime(2026, 3, 1),
        amount: 120,
        unit: 'arroba',
        destination: HarvestDestination.almacenado,
      );
      final fromJson = Harvest.fromJson(h.toJson());
      expect(fromJson.id, 'h1');
      expect(fromJson.cropId, 'cafe');
      expect(fromJson.amount, 120);
      expect(fromJson.unit, 'arroba');
      expect(fromJson.destination, HarvestDestination.almacenado);
    });

    test('destino por defecto vendido si JSON no lo trae', () {
      final h = Harvest.fromJson({
        'id': 'h2',
        'crop_id': 'cafe',
        'date': DateTime(2026, 3, 1).toIso8601String(),
        'amount': 12,
        'unit': 'kg',
      });
      expect(h.destination, HarvestDestination.vendido);
      expect(h.unit, 'kg');
    });
  });

  group('Harvest workers / equivalentKg', () {
    test('round-trip conserva empleados y kilos equivalentes', () {
      final h = Harvest(
        id: 'h3',
        cropId: 'cafe',
        date: DateTime(2026, 6, 1),
        amount: 30,
        unit: 'racimo',
        workers: 3,
        equivalentKg: 420.5,
      );
      final back = Harvest.fromJson(h.toJson());
      expect(back.workers, 3);
      expect(back.equivalentKg, 420.5);
    });

    test('retrocompat: JSON sin las claves queda en null', () {
      final h = Harvest.fromJson({
        'id': 'h4',
        'crop_id': 'cafe',
        'date': DateTime(2026, 6, 1).toIso8601String(),
        'amount': 10,
        'unit': 'kg',
      });
      expect(h.workers, isNull);
      expect(h.equivalentKg, isNull);
    });

    test('toJson omite las claves cuando son null', () {
      final h = Harvest(
        id: 'h5',
        cropId: 'cafe',
        date: DateTime(2026, 6, 1),
        amount: 10,
        unit: 'kg',
      );
      final json = h.toJson();
      expect(json.containsKey('workers'), isFalse);
      expect(json.containsKey('equivalent_kg'), isFalse);
    });

    test('copyWith conserva sin args y limpia a null con sentinel', () {
      final h = Harvest(
        id: 'h6',
        cropId: 'cafe',
        date: DateTime(2026, 6, 1),
        amount: 10,
        unit: 'racimo',
        workers: 4,
        equivalentKg: 100,
      );
      expect(h.copyWith().workers, 4);
      expect(h.copyWith().equivalentKg, 100);
      expect(h.copyWith(amount: 20).workers, 4);
      final cleared = h.copyWith(workers: null, equivalentKg: null);
      expect(cleared.workers, isNull);
      expect(cleared.equivalentKg, isNull);
      expect(cleared.amount, 10, reason: 'otros campos se conservan');
    });
  });
}
