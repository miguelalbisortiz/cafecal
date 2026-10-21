import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/sowing.dart';

Cohort _c({int live = 1000, double? area = 5}) => Cohort(
      sowingId: 's1',
      date: DateTime(2020, 1, 1),
      livePlants: live,
      areaHa: area,
    );

void main() {
  group('T8 · replacementPrefill', () {
    test('precarga por área: 1.000 matas en 5 ha y 1 ha nueva → 200', () {
      expect(replacementPrefill(_c(), 1), 200);
    });

    test('sin área en la vieja no hay precarga', () {
      expect(replacementPrefill(_c(area: null), 1), isNull);
    });

    test('área nueva vacía tampoco', () {
      expect(replacementPrefill(_c(), null), isNull);
    });

    test('área vieja en 0 no divide por cero', () {
      expect(replacementPrefill(_c(area: 0), 1), isNull);
    });
  });

  group('T8 · maxReplacement', () {
    test('«Todas (N)» es exactamente las vivas', () {
      expect(maxReplacement(_c(live: 700)), 700);
    });
  });

  group('T8 · validateReplacement', () {
    test('expansión: no hay nada que validar', () {
      expect(validateReplacement(renew: false), ReplacementError.none);
      expect(validateReplacement(renew: false, replacesPlants: 999),
          ReplacementError.none);
    });

    test('renovación sin cohorte destino', () {
      expect(validateReplacement(renew: true, replacesPlants: 10),
          ReplacementError.noTarget);
    });

    test('vacío', () {
      expect(validateReplacement(renew: true, target: _c()),
          ReplacementError.empty);
    });

    test('0 y negativo', () {
      expect(validateReplacement(renew: true, target: _c(), replacesPlants: 0),
          ReplacementError.notPositive);
      expect(validateReplacement(renew: true, target: _c(), replacesPlants: -5),
          ReplacementError.notPositive);
    });

    test('mayor a las vivas', () {
      expect(
          validateReplacement(
              renew: true, target: _c(live: 700), replacesPlants: 701),
          ReplacementError.tooMany);
    });

    test('un valor válido pasa', () {
      expect(
          validateReplacement(
              renew: true, target: _c(live: 700), replacesPlants: 700),
          ReplacementError.none);
      expect(
          validateReplacement(
              renew: true, target: _c(live: 700), replacesPlants: 1),
          ReplacementError.none);
    });
  });
}
