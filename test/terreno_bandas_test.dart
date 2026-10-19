import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/crop_totals.dart';

/// W1-c · el desglose por terreno.
///
/// La agrupación es una sola función pura: pantalla, PDF y Excel leen esto y
/// solo formatean. Aquí se fija la regla — pertenencia, orden, totales por
/// moneda, «sin repartir» dentro de su lote, huérfanos y comunes al final.
void main() {
  const loteAlto = Terreno(id: 'l1', name: 'Lote Alto', areaHa: 2);
  // Sin hectáreas anotadas: si cae un gasto de lote, no se puede repartir.
  const loteBajo = Terreno(id: 'l2', name: 'Lote Bajo');

  const cafe = Crop(
    id: 'cafe',
    name: 'Café',
    icon: '☕',
    color: '#6D4C41',
    areaHa: 1.2,
    terrenoId: 'l1',
  );
  const platano = Crop(
    id: 'plat',
    name: 'Plátano',
    icon: '🍌',
    color: '#8BC34A',
    areaHa: 0.8,
    terrenoId: 'l1',
  );
  const maiz = Crop(
    id: 'maiz',
    name: 'Maíz',
    icon: '🌽',
    color: '#FBC02D',
    terrenoId: 'l2',
  );
  const huerto = Crop(
    id: 'huerto',
    name: 'Huerto',
    icon: '🥬',
    color: '#66BB6A',
  );

  final dia = DateTime(2026, 6, 5);

  Transaction mov({
    required TransactionType type,
    required double amount,
    String category = 'jornal',
    String currency = 'COP',
    String? cropId,
    String? terrenoId,
  }) =>
      Transaction(
        id: '${type.name}_${currency}_$amount',
        type: type,
        category: category,
        amount: amount,
        currency: currency,
        cropId: cropId,
        terrenoId: terrenoId,
        date: dia,
        createdAt: dia,
      );

  Transaction gastoDeLote(double amount, [String lote = 'l1']) =>
      mov(type: TransactionType.expense, amount: amount, terrenoId: lote);

  Transaction gastoComun(double amount) =>
      mov(type: TransactionType.expense, amount: amount, category: 'luz');

  CropBreakdownLayout layout(
    List<Transaction> records, {
    List<Crop> crops = const [cafe, platano, maiz, huerto],
    List<Terreno> terrenos = const [loteAlto, loteBajo],
  }) =>
      cropBreakdownLayout(
        rows: cropBreakdownRows(
          records: records,
          crops: crops,
          terrenos: terrenos,
          unspecifiedName: 'Costos comunes',
          loteNoRepartidoName: (n) => '$n · sin repartir',
        ),
        crops: crops,
        terrenos: terrenos,
        sinTerrenoName: 'Sin terreno',
      );

  CropBreakdownBand banda(CropBreakdownLayout l, String id) =>
      l.bands.firstWhere((b) => b.terrenoId == id);

  group('W1-c · bandas por terreno', () {
    test('cada terreno es una banda con sus cultivos dentro', () {
      final l = layout([
        mov(type: TransactionType.expense, amount: 30000, cropId: 'cafe'),
        mov(type: TransactionType.expense, amount: 10000, cropId: 'maiz'),
        mov(type: TransactionType.income, amount: 50000, cropId: 'plat'),
      ]);

      expect(l.hasBands, isTrue);
      expect(l.bands.map((b) => b.name), ['Lote Alto', 'Lote Bajo']);
      expect(banda(l, 'l1').rows.map((r) => r.cropId), ['plat', 'cafe']);
      expect(banda(l, 'l2').rows.map((r) => r.cropId), ['maiz']);
      expect(l.commonCosts, isNull);
    });

    test('el total de la banda es la suma exacta de sus filas', () {
      final l = layout([
        mov(type: TransactionType.expense, amount: 30000, cropId: 'cafe'),
        mov(type: TransactionType.income, amount: 50000, cropId: 'plat'),
      ]);

      final alto = banda(l, 'l1');
      expect(alto.expenses['COP'], 30000);
      expect(alto.incomes['COP'], 50000);
      expect(
        alto.expenses['COP'],
        alto.rows.fold<double>(0, (a, r) => a + (r.expenses['COP'] ?? 0)),
      );
      expect(
        alto.incomes['COP'],
        alto.rows.fold<double>(0, (a, r) => a + (r.incomes['COP'] ?? 0)),
      );
    });

    test('el gasto de lote repartido queda dentro de cada cultivo del lote', () {
      final l = layout([gastoDeLote(100000)]);

      final alto = banda(l, 'l1');
      expect(alto.rows.map((r) => r.cropId), containsAll(['cafe', 'plat']));
      expect(alto.rows.any((r) => r.terrenoId != null), isFalse,
          reason: 'repartido no debe dejar fila de lote');
      expect(alto.expenses['COP'], 100000);
    });

    test('«Lote X · sin repartir» va DENTRO de la banda de su terreno', () {
      final l = layout([gastoDeLote(70000, 'l2')]);

      final bajo = banda(l, 'l2');
      expect(bajo.rows, hasLength(1));
      expect(bajo.rows.single.terrenoId, 'l2');
      expect(bajo.rows.single.cropId, isNull);
      expect(bajo.rows.single.name, 'Lote Bajo · sin repartir');
      expect(bajo.expenses['COP'], 70000);
    });

    test('los cultivos sin terreno van en la banda «Sin terreno», al final', () {
      final l = layout([
        mov(type: TransactionType.expense, amount: 5000, cropId: 'huerto'),
        mov(type: TransactionType.expense, amount: 9000, cropId: 'cafe'),
      ]);

      expect(l.bands.last.name, 'Sin terreno');
      expect(l.bands.last.terrenoId, isNull);
      expect(l.bands.last.rows.map((r) => r.cropId), ['huerto']);
      expect(l.bands.last.areaHa, isNull);
    });

    test('sin cultivos huérfanos no existe la banda «Sin terreno»', () {
      final l = layout([
        mov(type: TransactionType.expense, amount: 9000, cropId: 'cafe'),
      ]);

      expect(l.bands.every((b) => b.terrenoId != null), isTrue);
    });

    test('sin ningún cultivo con terreno no hay bandas: camino plano intacto', () {
      final l = layout(
        [mov(type: TransactionType.expense, amount: 5000, cropId: 'huerto')],
        crops: const [huerto],
        terrenos: const [],
      );

      expect(l.hasBands, isFalse);
      expect(l.bands, isEmpty);
    });

    test('«Costos comunes» queda fuera de toda banda', () {
      final l = layout([
        gastoComun(4000),
        mov(type: TransactionType.expense, amount: 9000, cropId: 'cafe'),
      ]);

      expect(l.commonCosts, isNotNull);
      expect(l.commonCosts!.expenses['COP'], 4000);
      for (final b in l.bands) {
        expect(b.rows.contains(l.commonCosts), isFalse);
      }
    });

    test('banda vacía no existe; el área solo aparece si está anotada', () {
      final l = layout([
        mov(type: TransactionType.expense, amount: 9000, cropId: 'cafe'),
      ]);

      expect(l.bands.map((b) => b.terrenoId), ['l1']);
      expect(banda(l, 'l1').areaHa, 2);
    });

    test('un terreno inexistente cae en «Sin terreno», no crea banda con UUID', () {
      const perdido = Crop(
        id: 'perdido',
        name: 'Yuca',
        icon: '🍠',
        color: '#8D6E63',
        terrenoId: 'borrado',
      );
      final l = layout(
        [
          mov(type: TransactionType.expense, amount: 200, cropId: 'cafe'),
          mov(type: TransactionType.expense, amount: 100, cropId: 'perdido'),
        ],
        crops: const [cafe, perdido],
      );

      expect(l.bands.every((b) => b.terrenoId != 'borrado'), isTrue);
      expect(l.bands.last.name, 'Sin terreno');
      expect(l.bands.last.rows.single.cropId, 'perdido');
    });

    test('moneda mixta: totales por moneda, sin convertir ni sumar', () {
      final l = layout([
        mov(type: TransactionType.expense, amount: 30000, cropId: 'cafe'),
        mov(
          type: TransactionType.income,
          amount: 10,
          currency: 'USD',
          cropId: 'cafe',
        ),
      ]);

      final alto = banda(l, 'l1');
      expect(alto.isMixed, isTrue);
      expect(alto.expenses.keys, ['COP']);
      expect(alto.incomes.keys, ['USD']);
      expect(alto.expenses['COP'], 30000);
      expect(alto.incomes['USD'], 10);
    });

    test('desempates: monto, luego nombre, luego id', () {
      const b = Crop(
          id: 'b', name: 'B', icon: '🌱', color: '#000000', terrenoId: 'l1');
      const a = Crop(
          id: 'a', name: 'A', icon: '🌱', color: '#000000', terrenoId: 'l1');
      final l = layout(
        [
          mov(type: TransactionType.expense, amount: 100, cropId: 'b'),
          mov(type: TransactionType.expense, amount: 100, cropId: 'a'),
        ],
        crops: const [b, a],
      );

      expect(banda(l, 'l1').rows.map((r) => r.name), ['A', 'B']);
    });
  });
}
