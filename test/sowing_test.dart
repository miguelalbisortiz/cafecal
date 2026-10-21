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
      // La resiembra es de un día anterior a la siembra base → no suma.
      // El descarte es por DÍA calendario: la del mismo día sí cuenta (abajo).
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

    test('pérdida del MISMO DÍA que la siembra base SÍ aplica', () {
      // La siembra se selló a las 10:00 y la pérdida del selector llega a las
      // 00:00: comparando instantes quedaba «antes» y se perdía en silencio.
      final result = recomputeCropState([
        _s(id: 's1', date: DateTime(2026, 1, 1, 10), plants: 100, areaHa: 0.5),
        _s(
          id: 'r1',
          date: DateTime(2026, 1, 1),
          kind: SowingKind.resiembra,
          plants: 0,
          lostPlants: 40,
        ),
      ]);
      final state = result['cafe']!;
      expect(state.livePlants, 60, reason: '100 − 40: el mismo día cuenta');
      expect(state.areaHa, 0.5);
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

  // Hasta dónde se puede fechar una pérdida. Lo lee el selector del diálogo
  // rápido: el mínimo es la siembra más reciente, porque una pérdida anterior
  // no la cuenta el contador y sí subiría «Pérdidas acumuladas» del informe.
  group('lossEarliestDate — hasta dónde se puede fechar', () {
    test('sin siembras arranca en el año 2000', () {
      expect(lossEarliestDate(const [], 'cafe'), DateTime(2000));
    });

    test('manda la siembra más reciente, y sin la hora', () {
      final dia = lossEarliestDate([
        _s(id: 's1', date: DateTime(2026, 1, 1, 10), plants: 100),
        _s(id: 's2', date: DateTime(2026, 4, 1, 18), plants: 120),
      ], 'cafe');
      expect(dia, DateTime(2026, 4, 1));
    });

    test('una resiembra no mueve el mínimo', () {
      final dia = lossEarliestDate([
        _s(id: 's1', date: DateTime(2026, 1, 1), plants: 100),
        _s(
          id: 'r1',
          date: DateTime(2026, 6, 1),
          kind: SowingKind.resiembra,
          plants: 10,
        ),
      ], 'cafe');
      expect(dia, DateTime(2026, 1, 1));
    });

    test('solo mira el cultivo que se le pide', () {
      final dia = lossEarliestDate([
        _s(id: 's1', date: DateTime(2026, 1, 1), plants: 100),
        _s(id: 's2', cropId: 'otro', date: DateTime(2026, 8, 1), plants: 50),
      ], 'cafe');
      expect(dia, DateTime(2026, 1, 1));
    });
  });

  group('T12 · resiembra sin muertas anotadas', () {
    test('resiembra con plantas y sin muertas avisa', () {
      expect(
        resiembraMissingLosses(SowingKind.resiembra, 50, null),
        isTrue,
        reason: 'hay plantas nuevas pero no se sabe cuántas se perdieron',
      );
    });

    test('una siembra inicial no pregunta por muertas', () {
      expect(resiembraMissingLosses(SowingKind.siembra, 50, null), isFalse);
    });

    test('sin plantas nuevas no hay nada que reponer', () {
      expect(resiembraMissingLosses(SowingKind.resiembra, 0, null), isFalse);
    });

    test('0 explícito es una respuesta: no vuelve a preguntar', () {
      expect(resiembraMissingLosses(SowingKind.resiembra, 50, 0), isFalse);
      expect(resiembraMissingLosses(SowingKind.resiembra, 50, 5), isFalse);
    });
  });
}
