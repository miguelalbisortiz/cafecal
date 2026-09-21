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

  group('kgToCargas', () {
    test('convierte kg a cargas (1 carga = 60 lbs ≈ 27.2155 kg)', () {
      // 27.2155 kg = 1 carga exacta
      expect(kgToCargas(27.2155), closeTo(1.0, 0.001));
    });

    test('0 kg = 0 cargas', () {
      expect(kgToCargas(0), 0);
    });

    test('redondea a 2 decimales', () {
      // 54.431 kg ≈ 2 cargas
      expect(kgToCargas(54.431), closeTo(2.0, 0.01));
    });

    test('valores negativos devuelven 0', () {
      expect(kgToCargas(-10), 0);
    });
  });
}
