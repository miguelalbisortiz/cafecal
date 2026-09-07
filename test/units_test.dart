import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/units.dart';

void main() {
  group('unitToKg', () {
    test('arroba equivale a 12.5 kg', () {
      expect(unitToKg('arroba'), 12.5);
    });

    test('saco equivale a 70 kg', () {
      expect(unitToKg('saco'), 70);
    });

    test('kg y unidades sin factor mapean a 1', () {
      expect(unitToKg('kg'), 1);
      expect(unitToKg('racimo'), 1);
      expect(unitToKg('cajon'), 1);
      expect(unitToKg(null), 1);
      expect(unitToKg('unidad-desconocida'), 1);
    });
  });
}
