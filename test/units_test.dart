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

  group('A2 · peso del saco configurable', () {
    test('por defecto sigue siendo 70, el de la norma', () {
      expect(kSacoKgPorDefecto, 70);
      expect(unitToKg('saco'), 70);
    });

    test('el peso configurado manda para el saco', () {
      // En la finca el costal pesa 60, no 70.
      expect(unitToKg('saco', sacoKg: 60), 60);
      expect(unitToKg('saco', sacoKg: 75.5), 75.5);
    });

    test('el peso no toca ninguna otra unidad', () {
      expect(unitToKg('kg', sacoKg: 60), 1);
      expect(unitToKg('lb', sacoKg: 60), 0.453592);
      expect(unitToKg('arroba', sacoKg: 60), 12.5);
      expect(unitToKg('carga', sacoKg: 60), 27.2155);
      expect(unitToKg(null, sacoKg: 60), 1);
      expect(unitToKg('racimo', sacoKg: 60), 1);
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

  group('kgFromUnit · unidades que necesitan peso', () {
    test('racimo y cajón necesitan peso; las demás no', () {
      expect(unitNeedsWeight('racimo'), isTrue);
      expect(unitNeedsWeight('cajon'), isTrue);
      expect(unitNeedsWeight('kg'), isFalse);
      expect(unitNeedsWeight('lb'), isFalse);
      expect(unitNeedsWeight('arroba'), isFalse);
      expect(unitNeedsWeight('saco'), isFalse);
      expect(unitNeedsWeight('carga'), isFalse);
      expect(unitNeedsWeight(null), isFalse);
    });

    test('el peso total manda sobre la cantidad', () {
      // 12 racimos que pesaron 240 kg: los kilos son 240, no 12.
      expect(kgFromUnit(12, 'racimo', 240), 240);
      expect(kgFromUnit(10, 'cajon', 200), 200);
    });

    test('sin peso devuelve null, nunca 1 por unidad', () {
      expect(kgFromUnit(12, 'racimo', null), isNull);
      expect(kgFromUnit(10, 'cajon', null), isNull);
      expect(kgFromUnit(12, 'racimo', 0), isNull);
      expect(kgFromUnit(12, 'racimo', -5), isNull);
    });

    test('las unidades con factor siguen igual que unitToKg', () {
      expect(kgFromUnit(1, 'kg', null), 1);
      expect(kgFromUnit(3, 'saco', null), 210);
      expect(kgFromUnit(2, 'lb', null), closeTo(0.907184, 0.000001));
      expect(kgFromUnit(1, 'arroba', null), 12.5);
      expect(kgFromUnit(1, 'carga', null), 27.2155);
    });

    test('el peso del saco configurado se respeta', () {
      expect(kgFromUnit(3, 'saco', null, sacoKg: 60), 180);
    });
  });
}
