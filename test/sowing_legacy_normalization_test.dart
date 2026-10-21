import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/sowing.dart';

Sowing _s({
  required String id,
  required DateTime date,
  SowingKind kind = SowingKind.siembra,
  required int plants,
  double? areaHa,
  int? lostPlants,
  int? replacesPlants,
  String? cohortSowingId,
  String? cropId = 'cafe',
}) =>
    Sowing(
      id: id,
      cropId: cropId,
      date: date,
      kind: kind,
      plants: plants,
      areaHa: areaHa,
      lostPlants: lostPlants,
      replacesPlants: replacesPlants,
      cohortSowingId: cohortSowingId,
    );

Sowing _byId(List<Sowing> ss, String id) =>
    ss.firstWhere((s) => s.id == id);

void main() {
  group('T7 · normalizeLegacyCohorts', () {
    test('S1 1.000/5 + S2 300/1 → S2 reemplaza 1.000/5 y el total queda 300/1',
        () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(id: 's2', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ];

      final r = normalizeLegacyCohorts(original);

      expect(r.changed, isTrue);
      final s2 = _byId(r.sowings, 's2');
      expect(s2.replacesPlants, 1000);
      expect(s2.replacesAreaHa, 5);
      expect(s2.cohortSowingId, 's1');
      expect(s2.pendingSync, isTrue, reason: 'la corrección tiene que subir');

      final total = recomputeCropState(r.sowings)['cafe']!;
      expect(total.livePlants, 300);
      expect(total.areaHa, 1);
    });

    test('S1 + resiembra + S2 → total igual al de hoy', () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 'r1',
            date: DateTime(2021, 1, 1),
            kind: SowingKind.resiembra,
            plants: 100,
            lostPlants: 100),
        _s(id: 's2', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ];

      final r = normalizeLegacyCohorts(original);
      final s2 = _byId(r.sowings, 's2');
      expect(s2.replacesPlants, 1000, reason: '1000 − 100 + 100');
      expect(s2.cohortSowingId, 's1');
      expect(recomputeCropState(r.sowings)['cafe']!.livePlants, 300);
    });

    test('tres siembras: cadena S1→S2→S3 con total igual', () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(id: 's2', date: DateTime(2023, 1, 1), plants: 500, areaHa: 2),
        _s(id: 's3', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ];

      final r = normalizeLegacyCohorts(original);
      expect(_byId(r.sowings, 's2').cohortSowingId, 's1');
      expect(_byId(r.sowings, 's2').replacesPlants, 1000);
      expect(_byId(r.sowings, 's3').cohortSowingId, 's2');
      expect(_byId(r.sowings, 's3').replacesPlants, 500);
      expect(recomputeCropState(r.sowings)['cafe']!.livePlants, 300);
    });

    test('ya normalizada no se vuelve a tocar', () {
      final primera = normalizeLegacyCohorts([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(id: 's2', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ]).sowings;

      final segunda = normalizeLegacyCohorts(primera);

      expect(segunda.changed, isFalse);
      expect(segunda.sowings, same(primera));
    });

    test('corrección a 0 se respeta en la pasada siguiente', () {
      final corregida = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 0),
      ];

      final r = normalizeLegacyCohorts(corregida);

      expect(r.changed, isFalse, reason: 'él ya respondió: era expansión');
      expect(recomputeCropState(r.sowings)['cafe']!.livePlants, 1300);
    });

    test('resiembra vieja sin puntero no se normaliza y resuelve por fecha',
        () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 'r1',
            date: DateTime(2021, 1, 1),
            kind: SowingKind.resiembra,
            plants: 100,
            lostPlants: 100),
        _s(id: 's2', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ];

      final r = normalizeLegacyCohorts(original);
      final r1 = _byId(r.sowings, 'r1');
      expect(r1.cohortSowingId, isNull, reason: 'las resiembras no se tocan');
      expect(recomputeCropState(r.sowings)['cafe']!.livePlants, 300);
    });

    test('sin nada vivo en ese instante queda replaces_plants = 0', () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 'r1',
            date: DateTime(2021, 1, 1),
            kind: SowingKind.resiembra,
            plants: 0,
            lostPlants: 1000),
        _s(id: 's2', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ];

      final r = normalizeLegacyCohorts(original);
      final s2 = _byId(r.sowings, 's2');
      expect(s2.replacesPlants, 0);
      expect(s2.cohortSowingId, isNull);
      expect(s2.replacesAreaHa, isNull);
      expect(s2.pendingSync, isTrue);

      expect(normalizeLegacyCohorts(r.sowings).changed, isFalse,
          reason: 'no se vuelve a procesar');
    });

    test('es idempotente: dos pasadas devuelven lo mismo', () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(id: 's2', date: DateTime(2023, 1, 1), plants: 500, areaHa: 2),
        _s(id: 's3', date: DateTime(2027, 1, 1), plants: 300, areaHa: 1),
      ];

      final a = normalizeLegacyCohorts(original).sowings;
      final b = normalizeLegacyCohorts(a).sowings;

      expect([for (final s in b) s.toJson()], [for (final s in a) s.toJson()]);
    });

    test('varias cohortes vivas: apunta a la más antigua y el resto sobrevive',
        () {
      final original = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2023, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 0),
        _s(id: 's3', date: DateTime(2027, 1, 1), plants: 400, areaHa: 2),
      ];

      final r = normalizeLegacyCohorts(original);
      final s3 = _byId(r.sowings, 's3');
      expect(s3.replacesPlants, 1300, reason: 'total vivo: 1000 + 300');
      expect(s3.cohortSowingId, 's1', reason: 'la más antigua de las vivas');
      // Declarado en el PRD (§Riesgos): un solo puntero no puede expresar
      // «borrá todo» cuando hay varias cohortes vivas. s1 queda en 0, s2
      // sobrevive y el total sube: 300 + 400 = 700 (hoy daría 400).
      expect(recomputeCropState(r.sowings)['cafe']!.livePlants, 700);
    });
  });
}
