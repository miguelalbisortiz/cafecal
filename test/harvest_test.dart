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
}
