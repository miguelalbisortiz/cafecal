import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/threshing_yield.dart';

Crop _crop({String id = 'c1', double? factor}) =>
    Crop(id: id, name: 'Café', threshingYield: factor);

Harvest _h({
  String id = 'h1',
  String cropId = 'c1',
  double kg = 300,
}) =>
    Harvest(id: id, cropId: cropId, date: DateTime(2026, 11, 1), amount: kg);

Transaction _tx({
  required String id,
  String category = kExpenseCategoryBenefit,
  double amount = 150000,
  String cropId = 'c1',
  String currency = 'COP',
  bool deleted = false,
}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: TransactionType.expense,
      category: category,
      amount: amount,
      currency: currency,
      date: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 11, 1),
      deleted: deleted,
    );

void main() {
  group('conversión de cereza a vendible', () {
    test('5 kg de cereza por kg de pergamino: 300 kg → 60 kg', () {
      expect(sellableKgFromCherry(300, 5), 60);
    });

    test('sin factor no hay cifra', () {
      expect(sellableKgFromCherry(300, null), isNull);
    });

    test('un factor ≤ 1 es imposible y no se usa', () {
      expect(sellableKgFromCherry(300, 1), isNull);
      expect(sellableKgFromCherry(300, 0.9), isNull);
      expect(sellableKgFromCherry(300, 0), isNull);
    });

    test('sin kilos cosechados no hay conversión (nunca 0)', () {
      expect(sellableKgFromCherry(0, 5), isNull);
    });
  });

  group('Crop · threshing_yield', () {
    test('va y vuelve en JSON', () {
      final vuelta = Crop.fromJson(_crop(factor: 5.2).toJson());
      expect(vuelta.threshingYield, 5.2);
    });

    test('un respaldo viejo sin la clave queda en null', () {
      final json = _crop().toJson()..remove('threshing_yield');
      expect(Crop.fromJson(json).threshingYield, isNull);
    });

    test('copyWith puede borrarlo (sentinela, no `??`)', () {
      final con = _crop(factor: 5);
      expect(con.copyWith(threshingYield: null).threshingYield, isNull);
      // Y sin tocarlo, conserva el valor.
      expect(con.copyWith(name: 'Café 2').threshingYield, 5);
    });
  });

  group('filas de rendimiento', () {
    test('convierte los kilos del cultivo y cobra solo producción', () {
      final rows = threshingRows(
        crops: [_crop(factor: 5)],
        harvests: [_h(kg: 300)],
        transactions: [
          // Producción: 150.000 de beneficio + 90.000 de recogida.
          _tx(id: 'b1'),
          _tx(id: 'c1', category: kExpenseCategoryHarvest, amount: 90000),
          // Siembra: es producción en esta app, así que suma.
          _tx(id: 's1', category: kExpenseCategorySowing, amount: 60000),
          // Equipo: inversión, no es costo de esta cosecha.
          _tx(id: 'e1', category: 'equipo', amount: 900000),
          // Borrado: tampoco.
          _tx(id: 'x1', amount: 999, deleted: true),
        ],
        sacoKg: 70,
      );

      expect(rows, hasLength(1));
      expect(rows.single.cherryKg, 300);
      expect(rows.single.sellableKg, 60);
      // (150.000 + 90.000 + 60.000) ÷ 60 kg vendibles.
      expect(rows.single.costPerSellableKg, 5000);
    });

    test('sin factor no hay fila', () {
      final rows = threshingRows(
        crops: [_crop()],
        harvests: [_h()],
        transactions: [_tx(id: 'b1')],
        sacoKg: 70,
      );
      expect(rows, isEmpty);
    });

    test('con factor pero sin cosecha tampoco hay fila', () {
      final rows = threshingRows(
        crops: [_crop(factor: 5)],
        harvests: const [],
        transactions: [_tx(id: 'b1')],
        sacoKg: 70,
      );
      expect(rows, isEmpty);
    });

    test('los kilos de otro cultivo no se mezclan', () {
      final rows = threshingRows(
        crops: [_crop(factor: 5)],
        harvests: [_h(id: 'h1', cropId: 'c2', kg: 500)],
        transactions: [_tx(id: 'b1')],
        sacoKg: 70,
      );
      expect(rows, isEmpty);
    });

    test('monedas mezcladas → costo null, nunca un promedio', () {
      final rows = threshingRows(
        crops: [_crop(factor: 5)],
        harvests: [_h(kg: 300)],
        transactions: [
          _tx(id: 'b1', amount: 150000),
          _tx(id: 'b2', amount: 30, currency: 'USD'),
        ],
        sacoKg: 70,
      );
      expect(rows.single.sellableKg, 60);
      expect(rows.single.costPerSellableKg, isNull);
    });
  });
}
