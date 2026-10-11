import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/units.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';

/// E4 · El rendimiento.
///
/// La referencia de este módulo **no es una tabla de Cenicafé** — es la finca
/// del productor. Por eso vive dentro de este archivo la regla que más
/// importa: lo que no se puede calcular sale `null` y la UI lo oculta.
///
/// Un número de referencia precargado serviría para café en Colombia, y para
/// nada más: no sabría si ese "Café" crece a 1.800 m bajo sombra o a 400 m
/// a pleno sol. Su propio histórico, en cambio, es cierto en cualquier
/// región, para cualquier cultivo, y no hay que configurarlo.
Harvest _h(int year, double amount,
        {String unit = 'kg', String cropId = 'cafe'}) =>
    Harvest(
      id: 'h${year}_$amount',
      cropId: cropId,
      date: DateTime(year, 8, 10),
      amount: amount,
      unit: unit,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Se calculan contra el reloj para que el test no envejezca: "año pasado"
  // sigue siendo el año pasado el día que se ejecute.
  final anioEnCurso = DateTime.now().year;
  final anioPasado = anioEnCurso - 1;
  final dosAniosAtras = anioEnCurso - 2;

  const metrics = ReportHarvestMetrics();

  group('historicalYield — lo que da su propia tierra', () {
    test('pide dos años cerrados: con uno no hay promedio', () {
      final uno = metrics.historicalYield(
        harvests: [_h(anioPasado, 500)],
        areaHa: 0.5,
        livePlants: 300,
      );
      expect(uno.years, 0);
      expect(uno.kgPerHa, isNull,
          reason: 'un año no es un promedio, es ese año');
      expect(uno.kgPerPlant, isNull);

      final dos = metrics.historicalYield(
        harvests: [_h(anioPasado, 500), _h(dosAniosAtras, 700)],
        areaHa: 0.5,
        livePlants: 300,
      );
      expect(dos.years, 2);
      // (500 + 700) / 2 = 600 kg por año → 600/0,5 ha = 1.200 kg/ha
      expect(dos.kgPerHa, closeTo(1200, 0.001));
      // 600 kg / 300 matas = 2 kg por mata
      expect(dos.kgPerPlant, closeTo(2, 0.001));
    });

    test('el año en curso queda fuera: está a medio camino', () {
      final r = metrics.historicalYield(
        harvests: [
          _h(anioPasado, 500),
          _h(dosAniosAtras, 700),
          // Si entrara, tiraría el promedio para abajo solo por ser tarde.
          _h(anioEnCurso, 99999),
        ],
        areaHa: 0.5,
        livePlants: 300,
      );

      expect(r.years, 2, reason: 'solo cuentan años calendario cerrados');
      expect(r.kgPerHa, closeTo(1200, 0.001),
          reason: 'el año a medio camino no puede competir con años enteros');
    });

    test('sin área no hay kg/ha, pero kg/planta sí sale', () {
      // Un productor que contó las matas pero nunca midió el terreno
      // igual tiene rendimiento que ver. Antes no lo podía.
      final r = metrics.historicalYield(
        harvests: [_h(anioPasado, 600), _h(dosAniosAtras, 600)],
        areaHa: null,
        livePlants: 300,
      );

      expect(r.kgPerHa, isNull, reason: 'no se divide por un área que no hay');
      expect(r.kgPerPlant, closeTo(2, 0.001));
      expect(r.years, 2);
    });

    test('sin matas contadas no hay kg/planta, pero kg/ha sí sale', () {
      final r = metrics.historicalYield(
        harvests: [_h(anioPasado, 600), _h(dosAniosAtras, 600)],
        areaHa: 2,
        livePlants: null,
      );

      expect(r.kgPerPlant, isNull);
      expect(r.kgPerHa, closeTo(300, 0.001));
    });

    test('área en cero no divide: sería infinito, y el infinito no se pinta',
        () {
      final r = metrics.historicalYield(
        harvests: [_h(anioPasado, 600), _h(dosAniosAtras, 600)],
        areaHa: 0,
        livePlants: 0,
      );

      expect(r.kgPerHa, isNull);
      expect(r.kgPerPlant, isNull);
    });

    test('las unidades se convierten a kg (saco de la finca)', () {
      final r = metrics.historicalYield(
        harvests: [
          _h(anioPasado, 2, unit: 'saco'),
          _h(dosAniosAtras, 2, unit: 'saco'),
        ],
        areaHa: 1,
        livePlants: 100,
      );

      expect(r.kgPerHa, closeTo(2 * kSacoKgPorDefecto, 0.001));
      expect(r.kgPerPlant, closeTo(2 * kSacoKgPorDefecto / 100, 0.001));
    });

    test('un cultivo nuevo no tiene promedio que enseñar', () {
      final r = metrics.historicalYield(
        harvests: [],
        areaHa: 1,
        livePlants: 100,
      );

      expect(r.kgPerHa, isNull);
      expect(r.kgPerPlant, isNull);
      expect(r.years, 0);
    });

    test('cada cultivo promedia lo suyo, no lo del vecino', () {
      // Así lo llaman las tres vistas: filtran por cultivo ANTES de promediar.
      const cropId = 'cafe';
      final todas = [
        _h(anioPasado, 600),
        _h(dosAniosAtras, 600),
        _h(anioPasado, 99999, cropId: 'platano'),
        _h(dosAniosAtras, 99999, cropId: 'platano'),
      ];

      final r = metrics.historicalYield(
        harvests: todas.where((h) => h.cropId == cropId).toList(),
        areaHa: 2,
        livePlants: null,
      );

      expect(r.years, 2);
      expect(r.kgPerHa, closeTo(300, 0.001),
          reason: 'los kilos del plátano no entran al café');
    });
  });

  group('La meta es SU número', () {
    test('vive en el cultivo y sobrevive a guardar y cargar', () {
      const c = Crop(id: 'c1', name: 'Café', expectedYieldPerHa: 1200);

      expect(c.toJson()['expected_yield_kg_ha'], 1200);
      expect(Crop.fromJson(c.toJson()).expectedYieldPerHa, 1200);
    });

    test('un respaldo anterior a E4 nace sin meta', () {
      final map = Map<String, dynamic>.from(
          const Crop(id: 'c1', name: 'Café', expectedYieldPerHa: 1200)
              .toJson())
        ..remove('expected_yield_kg_ha');

      expect(Crop.fromJson(map).expectedYieldPerHa, isNull,
          reason: 'dato viejo: sin meta → la app no pinta nada, nunca un 0');
    });

    test('copyWith puede BORRAR la meta', () {
      const c = Crop(id: 'c1', name: 'Café', expectedYieldPerHa: 1200);

      // Sentinela: sin ella, `copyWith(expectedYieldPerHa: null)` se leería
      // como "conserva la anterior" y quitar la meta sería imposible.
      expect(c.copyWith(expectedYieldPerHa: null).expectedYieldPerHa, isNull);
      expect(c.expectedYieldPerHa, 1200, reason: 'el original no cambia');
      expect(c.copyWith(expectedYieldPerHa: 900).expectedYieldPerHa, 900);
    });

    test('copyWith tolera un entero escrito a mano', () {
      // Bug ya visto en presupuestoObraMensual: `as double?` revienta con
      // literales enteros, y en Dart 1200 sin .0 es un int.
      const base = Crop(id: 'c1', name: 'Café');
      expect(base.copyWith(expectedYieldPerHa: 1200).expectedYieldPerHa, 1200);
    });

    test('sin meta la app no inventa una', () {
      expect(const Crop(id: 'c1', name: 'Café').expectedYieldPerHa, isNull);
    });
  });
}
