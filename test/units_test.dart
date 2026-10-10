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
}
