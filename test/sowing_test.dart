import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/sowing.dart';

Sowing _s({
  required String id,
  required DateTime date,
  SowingKind kind = SowingKind.siembra,
  required int plants,
  double? areaHa,
  int? lostPlants,
  String? reason,
  String? cropId = 'cafe',
}) {
  return Sowing(
    id: id,
    cropId: cropId,
    date: date,
    kind: kind,
    plants: plants,
    areaHa: areaHa,
    lostPlants: lostPlants,
    reason: reason,
  );
}

void main() {
  group('Sowing JSON', () {
    test('una siembra con pérdidas pegadas entra limpia y para subir', () {
      // Así quedaba el registro viejo al pasar una resiembra a siembra.
      final json = Sowing(
        id: 's1',
        cropId: 'cafe',
        date: DateTime(2026, 3, 1),
        plants: 1000,
        lostPlants: 50,
        reason: 'plaga',
      ).toJson();

      final limpia = Sowing.fromJson(json);

      expect(limpia.plants, 1000);
      expect(limpia.lostPlants, isNull,
          reason: 'una siembra no pierde: el -50 viejo se limpia al entrar');
      expect(limpia.reason, isNull,
          reason: 'el motivo era de la resiembra');
      expect(limpia.pendingSync, isTrue,
          reason: 'la corrección tiene que subir a la nube');
    });

    test('round-trip conserva todos los campos', () {
      final s = _s(
        id: 's1',
        date: DateTime(2026, 3, 1),
        kind: SowingKind.resiembra,
        plants: 80,
        areaHa: 0.4,
        lostPlants: 10,
        reason: 'plagas',
      );
      final fromJson = Sowing.fromJson(s.toJson());
      expect(fromJson.id, 's1');
      expect(fromJson.kind, SowingKind.resiembra);
      expect(fromJson.plants, 80);
      expect(fromJson.areaHa, 0.4);
      expect(fromJson.lostPlants, 10);
      expect(fromJson.reason, 'plagas');
      expect(fromJson.cropId, 'cafe');
    });

    test('lostPlants por defecto 0 ante JSON sin el campo', () {
      final s = Sowing.fromJson({
        'id': 's2',
        'crop_id': 'cafe',
        'date': DateTime(2026, 3, 1).toIso8601String(),
        'kind': 'resiembra',
        'plants': 50,
      });
      expect(s.lostPlants, isNull);
    });
  });

  group('recomputeCropState — regla muerte/resiembra', () {
    test('siembra base + resiembra POSTERIOR aplica', () {
      final result = recomputeCropState([
        _s(id: 's1', date: DateTime(2026, 1, 1), plants: 100, areaHa: 0.5),
        _s(
          id: 's2',
          date: DateTime(2026, 6, 1),
          kind: SowingKind.resiembra,
          plants: 30,
          lostPlants: 10,
        ),
      ]);
      final state = result['cafe']!;
      expect(state.livePlants, 120); // 100 - 10 + 30
      expect(state.areaHa, 0.5); // área viene de la siembra base
    });

    test('resiembra ANTERIOR a la siembra base NO aplica', () {
      final result = recomputeCropState([
        _s(
          id: 'r1',
          date: DateTime(2026, 1, 1),
          kind: SowingKind.resiembra,
          plants: 30,
          lostPlants: 80,
        ),
        _s(id: 's1', date: DateTime(2026, 5, 1), plants: 100, areaHa: 0.5),
      ]);
      final state = result['cafe']!;
      // La resiembra es previa a la siembra base → no suma.
      expect(state.livePlants, 100);
      expect(state.areaHa, 0.5);
    });

    test('área usa la última siembra que la aportó', () {
      final result = recomputeCropState([
        _s(id: 's1', date: DateTime(2026, 1, 1), plants: 100, areaHa: 0.5),
        _s(id: 's2', date: DateTime(2026, 4, 1), plants: 120, areaHa: 0.8),
      ]);
      final state = result['cafe']!;
      expect(state.livePlants, 120);
      expect(state.areaHa, 0.8);
    });

    test('sin siembras no genera estado (no sobreescribe manual)', () {
      final result = recomputeCropState(const []);
      expect(result, isEmpty);
    });
  });

  // El formulario manda `null` en los campos que no aplican al tipo elegido
  // (una siembra no tiene pérdidas ni motivo). Con `?? this.x` el valor viejo
  // sobrevivía y quedaba una siembra con `-50 · plaga` encima.
  group('copyWith — los campos opcionales se pueden borrar', () {
    test('pasar null borra lostPlants y reason', () {
      final r = _s(
        id: 'r1',
        date: DateTime(2026, 3, 1),
        kind: SowingKind.resiembra,
        plants: 0,
        lostPlants: 50,
        reason: 'plaga',
      );

      final asSiembra = r.copyWith(
        kind: SowingKind.siembra,
        lostPlants: null,
        reason: null,
      );

      expect(asSiembra.kind, SowingKind.siembra);
      expect(asSiembra.lostPlants, isNull,
          reason: 'era el -50 de cuando era resiembra; una siembra no pierde');
      expect(asSiembra.reason, isNull,
          reason: 'el motivo era de la resiembra; no puede quedarse pegado');
    });

    test('no pasarlos los conserva (nadie se borra solo)', () {
      final r = _s(
        id: 'r1',
        date: DateTime(2026, 3, 1),
        kind: SowingKind.resiembra,
        plants: 0,
        lostPlants: 50,
        reason: 'plaga',
      );

      final copia = r.copyWith(plants: 10);

      expect(copia.plants, 10);
      expect(copia.lostPlants, 50);
      expect(copia.reason, 'plaga');
    });
  });

  // Las pérdidas son cosa de la resiembra: una siembra no pierde plantas ni
  // tiene motivo. Si un registro viejo las lleva pegadas, no cuentan ni se
  // pintan — esta es la única regla que leen la lista y los informes.
  group('lossOf — solo la resiembra pierde', () {
    test('una siembra devuelve 0 pérdidas y ningún motivo', () {
      final s = _s(
        id: 's1',
        date: DateTime(2026, 1, 1),
        plants: 1000,
        lostPlants: 50,
        reason: 'plaga',
      );

      final loss = lossOf(s);

      expect(loss.lost, 0,
          reason: 'una siembra no pierde: el -50 pegado no cuenta');
      expect(loss.reason, isNull);
    });

    test('una resiembra devuelve sus pérdidas y su motivo', () {
      final r = _s(
        id: 'r1',
        date: DateTime(2026, 3, 1),
        kind: SowingKind.resiembra,
        plants: 0,
        lostPlants: 50,
        reason: 'plaga',
      );

      final loss = lossOf(r);

      expect(loss.lost, 50);
      expect(loss.reason, 'plaga');
    });
  });
}
