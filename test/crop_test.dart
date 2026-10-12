import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/sowing.dart';

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
        establishmentCost: 8000000,
      );
      final fromJson = Crop.fromJson(c.toJson());
      expect(fromJson.phase, CropPhase.establecimiento);
      expect(fromJson.cycle, CropCycle.perenne);
      expect(fromJson.defaultUnit, 'arroba');
      expect(fromJson.areaHa, 1.5);
      expect(fromJson.livePlants, 3000);
      expect(fromJson.pendingSync, true);
      expect(fromJson.establishmentCost, 8000000);
    });

    test('establece key establishment_cost en populate', () {
      const c = Crop(id: 'cafe', name: 'Café', establishmentCost: 12000000);
      expect(c.toJson()['establishment_cost'], 12000000);
    });

    test('establishmentCost null cuando JSON antiguo no lo trae', () {
      final c = Crop.fromJson({'id': 'x', 'name': 'Café'});
      expect(c.establishmentCost, isNull);
    });
  });

  group('C1 · plantedAt', () {
    test('plantedAt sobrevive el round-trip JSON', () {
      final original =
          Crop(id: 'cafe', name: 'Café', plantedAt: DateTime(2019, 3, 1));
      final back = Crop.fromJson(original.toJson());
      expect(back.plantedAt, isNotNull);
      expect(back.plantedAt!.year, 2019);
      expect(back.plantedAt!.month, 3);
      expect(back.plantedAt!.day, 1);
    });

    test('JSON antiguo sin el campo queda en null', () {
      final c = Crop.fromJson({'id': 'x', 'name': 'Café'});
      expect(c.plantedAt, isNull);
    });

    test('copyWith puede borrar la fecha (el campo es opcional)', () {
      final c = Crop(id: 'x', name: 'Café', plantedAt: DateTime(2020, 1, 1));
      expect(c.copyWith(plantedAt: null).plantedAt, isNull,
          reason: 'sin sentinela el null habría conservado la fecha vieja');
      expect(c.copyWith(name: 'Otro').plantedAt, isNotNull,
          reason: 'y al no tocarla se conserva igual que la moneda');
    });

    test('acepta la fecha corta que manda Supabase', () {
      final c = Crop.fromJson({'id': 'x', 'name': 'Café', 'planted_at': '2019-03-01'});
      expect(c.plantedAt!.year, 2019);
      expect(c.plantedAt!.month, 3);
      expect(c.plantedAt!.day, 1);
    });
  });

  group('F5 · edad del cultivo', () {
    final hoy = DateTime(2026, 10, 10);

    Sowing siembra(DateTime d,
            {String cropId = 'cafe', SowingKind kind = SowingKind.siembra}) =>
        Sowing(
            id: 's${d.microsecondsSinceEpoch}',
            cropId: cropId,
            date: d,
            kind: kind,
            plants: 10);

    test('la última siembra gana sobre plantedAt', () {
      final crop =
          Crop(id: 'cafe', name: 'Café', plantedAt: DateTime(2019, 1, 1));
      final edad = edadDeCrop(crop, [siembra(DateTime(2024, 1, 1))], hoy: hoy);
      expect(edad, 2,
          reason: 'manda lo que pasó en la finca, no lo que escribió en el editor');
    });

    test('una resiembra NO reinicia la edad: repone plantas, no arranca de nuevo',
        () {
      final crop =
          Crop(id: 'cafe', name: 'Café', plantedAt: DateTime(2019, 1, 1));
      final edad = edadDeCrop(crop, [
        siembra(DateTime(2020, 1, 1)),
        siembra(DateTime(2025, 6, 1), kind: SowingKind.resiembra),
      ], hoy: hoy);
      expect(edad, 6,
          reason: 'un cafetal de 6 años con matas reponidas sigue teniendo 6 '
              'años; la propia aritmética de la app dice vivas − muertas + '
              'nuevas, que es un tope y no un reinicio');
    });

    test('sin siembras se usa plantedAt', () {
      final crop =
          Crop(id: 'cafe', name: 'Café', plantedAt: DateTime(2019, 3, 1));
      expect(edadDeCrop(crop, [], hoy: hoy), 7);
    });

    test('sin datos no se muestra nada (nunca un 0 inventado)', () {
      expect(edadDeCrop(const Crop(id: 'cafe', name: 'Café'), [], hoy: hoy),
          isNull);
    });

    test('un cultivo anual no tiene edad', () {
      final crop = Crop(
          id: 'maiz',
          name: 'Maíz',
          cycle: CropCycle.anual,
          plantedAt: DateTime(2019, 1, 1));
      expect(edadDeCrop(crop, [], hoy: hoy), isNull);
    });

    test('todavía no cumple un año se cuenta como 0, no como "sin datos"', () {
      const crop = Crop(id: 'cafe', name: 'Café');
      expect(edadDeCrop(crop, [siembra(DateTime(2026, 5, 1))], hoy: hoy), 0);
    });

    test('una fecha futura no produce edad', () {
      final crop =
          Crop(id: 'cafe', name: 'Café', plantedAt: DateTime(2030, 1, 1));
      expect(edadDeCrop(crop, [], hoy: hoy), isNull);
    });

    test('los años cumplidos se cuentan por aniversario, no por año natural',
        () {
      expect(aniosCumplidos(DateTime(2023, 10, 11), hoy), 2,
          reason: 'falta un día para el tercer aniversario');
      expect(aniosCumplidos(DateTime(2023, 10, 10), hoy), 3);
      expect(aniosCumplidos(DateTime(2023, 10, 9), hoy), 3);
    });
  });

  // H2 · la fase de un cultivo nuevo no la decide ningún umbral de años.
  //
  // Plátano rinde a los 9-12 meses, mango a los 3-5, café a los 3-5: la app
  // no tiene tabla de especies (y no va a inventar una), y tampoco adivina
  // por edad — `plantedAt` ni siquiera es parámetro de esta función. Lo único
  // que manda es lo que **él** estimó, y si no estimó nada, se calla.
  group('deducePhaseOnCreate — manda lo que él estimó', () {
    final hoy = DateTime(2026, 10, 11);

    test('un anual nace en "Dando": se siembra y se cosecha en el año', () {
      expect(deducePhaseOnCreate(cycle: CropCycle.anual, hoy: hoy),
          CropPhase.produccion);
      // Aunque él estime una cosecha tardía, el ciclo manda.
      expect(
          deducePhaseOnCreate(
              cycle: CropCycle.anual,
              primerCosechaEsperada: DateTime(2028, 1, 1),
              hoy: hoy),
          CropPhase.produccion);
    });

    test('sin fecha que lo diga, la app no adivina: nace en "Sin dar"',
        () {
      expect(deducePhaseOnCreate(cycle: CropCycle.perenne, hoy: hoy),
          CropPhase.establecimiento,
          reason: 'regla de oro: sin dato, se calla en vez de inventar. '
              'La primera cosecha registrada es la que lo promueve sola');
    });

    test('lo que él estimó manda sobre cualquier cálculo de la app', () {
      expect(
          deducePhaseOnCreate(
              cycle: CropCycle.perenne,
              primerCosechaEsperada: DateTime(2026, 11, 1),
              hoy: hoy),
          CropPhase.establecimiento,
          reason: 'su primera cosecha todavía no llegó');
      expect(
          deducePhaseOnCreate(
              cycle: CropCycle.perenne,
              primerCosechaEsperada: DateTime(2026, 9, 1),
              hoy: hoy),
          CropPhase.produccion,
          reason: 'ya pasó la fecha que él estimó');
    });

    test('la fecha de hoy cuenta como "todavía no": es el día en que anota',
        () {
      expect(
          deducePhaseOnCreate(
              cycle: CropCycle.perenne,
              primerCosechaEsperada: hoy,
              hoy: hoy),
          CropPhase.establecimiento);
    });
  });
}
