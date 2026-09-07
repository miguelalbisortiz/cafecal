import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';

void main() {
  group('Crop JSON — retrocompatibilidad', () {
    test('JSON antiguo {id,name} recibe defaults de fase/ciclo', () {
      final c = Crop.fromJson({'id': 'x', 'name': 'Café'});
      expect(c.phase, CropPhase.produccion);
      expect(c.cycle, CropCycle.perenne);
      expect(c.defaultUnit, isNull);
      expect(c.areaHa, isNull);
      expect(c.livePlants, isNull);
      expect(c.pendingSync, false);
    });

    test('round-trip conserva fase, ciclo, unidad, área y plantas', () {
      const c = Crop(
        id: 'cafe',
        name: 'Café',
        phase: CropPhase.establecimiento,
        cycle: CropCycle.perenne,
        defaultUnit: 'arroba',
        areaHa: 1.5,
        livePlants: 3000,
        pendingSync: true,
      );
      final fromJson = Crop.fromJson(c.toJson());
      expect(fromJson.phase, CropPhase.establecimiento);
      expect(fromJson.cycle, CropCycle.perenne);
      expect(fromJson.defaultUnit, 'arroba');
      expect(fromJson.areaHa, 1.5);
      expect(fromJson.livePlants, 3000);
      expect(fromJson.pendingSync, true);
    });
  });
}
