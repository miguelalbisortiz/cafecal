import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/sowing.dart';

Sowing _s({
  required String id,
  String? cropId = 'cafe',
  required DateTime date,
  SowingKind kind = SowingKind.siembra,
  required int plants,
  double? areaHa,
  int? lostPlants,
  String? reason,
  int? replacesPlants,
  double? replacesAreaHa,
  String? cohortSowingId,
  bool pendingSync = false,
}) =>
    Sowing(
      id: id,
      cropId: cropId,
      date: date,
      kind: kind,
      plants: plants,
      areaHa: areaHa,
      lostPlants: lostPlants,
      reason: reason,
      replacesPlants: replacesPlants,
      replacesAreaHa: replacesAreaHa,
      cohortSowingId: cohortSowingId,
      pendingSync: pendingSync,
    );

Cohort _c(List<Sowing> ss, String id) =>
    cropCohorts('cafe', ss).firstWhere((c) => c.sowingId == id);

void main() {
  group('T4 · cropCohorts', () {
    test('una siembra abre una cohorte con sus matas y su área', () {
      final ss = [_s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5)];
      final cs = cropCohorts('cafe', ss);
      expect(cs, hasLength(1));
      expect(cs.single.sowingId, 's1');
      expect(cs.single.date, DateTime(2020, 1, 1));
      expect(cs.single.livePlants, 1000);
      expect(cs.single.areaHa, 5);
      expect(cs.single.open, isTrue);
      expect(cs.single.closedOn, isNull);
    });

    test('expansión (replaces 0): la vieja queda intacta y la nueva suma', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 0),
      ];
      expect(_c(ss, 's1').livePlants, 1000);
      expect(_c(ss, 's2').livePlants, 300);
      expect(_c(ss, 's1').areaHa, 5);
    });

    test('renovación parcial 300/1 sobre 1.000/5 → vieja 700/4 y nueva 300/1',
        () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 300,
            replacesAreaHa: 1,
            cohortSowingId: 's1'),
      ];
      final vieja = _c(ss, 's1');
      expect(vieja.livePlants, 700);
      expect(vieja.areaHa, 4);
      expect(vieja.open, isTrue);
      expect(_c(ss, 's2').livePlants, 300);
      expect(_c(ss, 's2').areaHa, 1);
    });

    test('renovación total: la vieja queda en 0 y con fecha de cierre', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 1000,
            replacesAreaHa: 5,
            cohortSowingId: 's1'),
      ];
      final vieja = _c(ss, 's1');
      expect(vieja.livePlants, 0);
      expect(vieja.open, isFalse);
      expect(vieja.closedOn, DateTime(2027, 1, 1),
          reason: 'la cerró una siembra: hay fecha');
    });

    test('reemplazo mayor a las vivas se recorta a 0', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 1500,
            cohortSowingId: 's1'),
      ];
      expect(_c(ss, 's1').livePlants, 0, reason: 'no queda negativo');
      expect(_c(ss, 's2').livePlants, 300);
    });

    test('el puntero manda: resta a esa cohorte y no a la más antigua', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2023, 1, 1),
            plants: 200,
            areaHa: 1,
            replacesPlants: 0),
        _s(
            id: 's3',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 200,
            cohortSowingId: 's2'),
      ];
      expect(_c(ss, 's2').livePlants, 0, reason: 'el puntero era s2');
      expect(_c(ss, 's1').livePlants, 1000, reason: 's1 no se toca');
    });

    test('puntero que no resuelve: no resta y queda «sin lote»', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 300,
            cohortSowingId: 'borrada'),
      ];
      expect(_c(ss, 's1').livePlants, 1000, reason: 'sin puntero no se resta');
      expect(_c(ss, 's2').livePlants, 300);
    });

    test('puntero con fecha posterior: se ignora', () {
      final ss = [
        _s(
            id: 's2',
            date: DateTime(2020, 5, 1),
            plants: 300,
            replacesPlants: 300,
            cohortSowingId: 's1'),
        _s(id: 's1', date: DateTime(2026, 1, 1), plants: 1000, areaHa: 5),
      ];
      expect(_c(ss, 's1').livePlants, 1000, reason: 'el futuro no reemplaza');
      expect(_c(ss, 's2').livePlants, 300);
    });

    test('resiembra por puntero a la vieja después de una siembra nueva', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 0),
        _s(
            id: 'r1',
            date: DateTime(2028, 1, 1),
            kind: SowingKind.resiembra,
            plants: 200,
            lostPlants: 300,
            cohortSowingId: 's1'),
      ];
      expect(_c(ss, 's1').livePlants, 900, reason: '1000 − 300 + 200');
      expect(_c(ss, 's2').livePlants, 300, reason: 'la nueva no se toca');
    });

    test('resiembra sin puntero cae en la cohorte más reciente', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 0),
        _s(
            id: 'r1',
            date: DateTime(2028, 1, 1),
            kind: SowingKind.resiembra,
            plants: 50,
            lostPlants: 0),
      ];
      expect(_c(ss, 's2').livePlants, 350);
      expect(_c(ss, 's1').livePlants, 1000);
    });

    test('resiembra sobre una cohorte en 0 no la revive', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 1000,
            cohortSowingId: 's1'),
        _s(
            id: 'r1',
            date: DateTime(2028, 1, 1),
            kind: SowingKind.resiembra,
            plants: 100,
            lostPlants: 0,
            cohortSowingId: 's1'),
      ];
      expect(_c(ss, 's1').livePlants, 0, reason: 'no se revive una cerrada');
    });

    test('dos siembras el mismo día: determinista y con puntero explícito', () {
      final base = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 'b',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 200,
            replacesAreaHa: 1,
            cohortSowingId: 's1'),
        _s(
            id: 'c',
            date: DateTime(2027, 1, 1),
            plants: 100,
            areaHa: 0.5,
            replacesPlants: 0),
      ];
      final a = cropCohorts('cafe', base);
      final b = cropCohorts('cafe', base.reversed.toList());
      expect([for (final c in a) c.sowingId], ['s1', 'b', 'c']);
      expect([for (final c in b) c.sowingId], ['s1', 'b', 'c'],
          reason: 'el orden de la lista guardada no cambia el resultado');
      expect(_c(base, 's1').livePlants, 800);
    });

    test('área: resta con piso en 0; la vieja sin área sigue sin área', () {
      final conArea = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 1000,
            replacesAreaHa: 6,
            cohortSowingId: 's1'),
      ];
      expect(_c(conArea, 's1').areaHa, 0, reason: 'no queda negativa');

      final sinArea = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 300,
            replacesAreaHa: 1,
            cohortSowingId: 's1'),
      ];
      expect(_c(sinArea, 's1').areaHa, isNull,
          reason: 'sin área vieja no se inventa una resta');
    });

    test('nEdades cuenta solo las cohortes con vivas > 0', () {
      final dos = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 300,
            cohortSowingId: 's1'),
      ];
      expect(nEdades('cafe', dos), 2);

      final una = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 1000,
            cohortSowingId: 's1'),
      ];
      expect(nEdades('cafe', una), 1);
    });

    test('closedOn: la siembra que la dejó en 0; sin dato no se inventa', () {
      final porSiembra = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 1000,
            cohortSowingId: 's1'),
      ];
      expect(_c(porSiembra, 's1').closedOn, DateTime(2027, 1, 1));

      final porPerdidas = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 'r1',
            date: DateTime(2023, 1, 1),
            kind: SowingKind.resiembra,
            plants: 0,
            lostPlants: 1000),
      ];
      final c = _c(porPerdidas, 's1');
      expect(c.livePlants, 0);
      expect(c.closedOn, isNull,
          reason: 'la dejó en 0 una pérdida: no hay fecha de cierre');
    });
  });

  group('T5 · recomputeCropState sobre cohortes', () {
    test('una siembra posterior con replaces_plants = 0 no borra la vieja',
        () {
      final r = recomputeCropState([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 0.5,
            replacesPlants: 0),
      ]);
      expect(r['cafe']!.livePlants, 1300);
      expect(r['cafe']!.areaHa, 5.5);
    });

    test('renovación parcial: 700/4 + 300/1 = 1.000/5', () {
      final r = recomputeCropState([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 300,
            replacesAreaHa: 1,
            cohortSowingId: 's1'),
      ]);
      expect(r['cafe']!.livePlants, 1000);
      expect(r['cafe']!.areaHa, 5);
    });

    test('renovación total deja el cultivo en 300/1', () {
      final r = recomputeCropState([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 1000,
            replacesAreaHa: 5,
            cohortSowingId: 's1'),
      ]);
      expect(r['cafe']!.livePlants, 300);
      expect(r['cafe']!.areaHa, 1);
    });

    test('todas las cohortes en 0: livePlants = 0, no «sin datos»', () {
      final r = recomputeCropState([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 'r1',
            date: DateTime(2023, 1, 1),
            kind: SowingKind.resiembra,
            plants: 0,
            lostPlants: 1000),
      ]);
      expect(r['cafe']!.livePlants, 0);
      expect(r['cafe']!.areaHa, isNull, reason: 'sin cohortes vivas no hay área');
    });

    test('área: todas conocidas → suma redondeada a 2 decimales', () {
      final r = recomputeCropState([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 100, areaHa: 0.333),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 100,
            areaHa: 0.667,
            replacesPlants: 0),
      ]);
      expect(r['cafe']!.areaHa, 1.0);
    });

    test('área: una cohorte sin área → areaHa null (conserva la manual)', () {
      final r = recomputeCropState([
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 100, areaHa: 0.5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 100,
            replacesPlants: 0),
      ]);
      expect(r['cafe']!.areaHa, isNull,
          reason: 'falta un área: no se inventa la suma');
    });

    test('sin siembras el cultivo no entra al mapa', () {
      expect(recomputeCropState(const []), isEmpty);
      final soloResiembra = recomputeCropState([
        _s(
            id: 'r1',
            date: DateTime(2023, 1, 1),
            kind: SowingKind.resiembra,
            plants: 10,
            lostPlants: 0),
      ]);
      expect(soloResiembra, isEmpty);
    });

    test('cohortAreaStatus: suma completa, incompleta y que supera la manual',
        () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            areaHa: 1,
            replacesPlants: 0),
      ];
      final completo = cohortAreaStatus(5, cropCohorts('cafe', ss));
      expect(completo.measuredSum, 6);
      expect(completo.incomplete, isFalse);
      expect(completo.overManual, isTrue, reason: '6 > 5 manual');

      final faltaArea = [
        _s(id: 's1', date: DateTime(2020, 1, 1), plants: 1000, areaHa: 5),
        _s(
            id: 's2',
            date: DateTime(2027, 1, 1),
            plants: 300,
            replacesPlants: 0),
      ];
      final incompleto = cohortAreaStatus(5, cropCohorts('cafe', faltaArea));
      expect(incompleto.incomplete, isTrue);
      expect(incompleto.measuredSum, isNull,
          reason: 'falta un área: no se inventa la suma');
      expect(incompleto.overManual, isFalse);
    });
  });

  group('T6 · lossEarliestDate con cohorte', () {
    test('con cohorte usa el 2020 y no el 2026', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 3, 10, 15), plants: 1000),
        _s(
            id: 's2',
            date: DateTime(2026, 3, 10),
            plants: 300,
            replacesPlants: 300,
            cohortSowingId: 's1'),
      ];
      expect(lossEarliestDate(ss, 'cafe', cohortSowingId: 's1'),
          DateTime(2020, 3, 10));
    });

    test('sin cohorte: comportamiento de hoy (la siembra más reciente)', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 3, 10), plants: 1000),
        _s(id: 's2', date: DateTime(2026, 3, 10), plants: 300),
      ];
      expect(lossEarliestDate(ss, 'cafe'), DateTime(2026, 3, 10));
    });

    test('puntero que no resuelve cae al comportamiento de hoy', () {
      final ss = [
        _s(id: 's1', date: DateTime(2020, 3, 10), plants: 1000),
        _s(id: 's2', date: DateTime(2026, 3, 10), plants: 300),
      ];
      expect(lossEarliestDate(ss, 'cafe', cohortSowingId: 'nada'),
          DateTime(2026, 3, 10));
    });
  });
}
