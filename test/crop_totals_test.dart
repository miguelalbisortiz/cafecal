import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/crop_totals.dart';

/// Regla de dominio: todo lo que se cosecha se vende y **nunca se suman
/// monedas distintas**. Estos tests fijan el criterio que comparten la
/// pantalla, el PDF y el Excel.
void main() {
  const cafe = Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41');
  const platano =
      Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#8BC34A');

  Transaction tx({
    required TransactionType type,
    required double amount,
    String currency = 'COP',
    String? cropId,
    String category = 'venta_cafe',
    bool deleted = false,
  }) =>
      Transaction(
        id: 't_${type.name}_${amount}_$currency',
        type: type,
        category: category,
        amount: amount,
        currency: currency,
        cropId: cropId,
        date: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5),
        deleted: deleted,
      );

  List<CropBreakdownRow> rowsOf(List<Transaction> txs) => cropBreakdownRows(
        records: txs,
        crops: const [cafe, platano],
        unspecifiedName: 'Sin cultivo',
      );

  CropBreakdownRow cropRow(List<Transaction> txs, String id) =>
      rowsOf(txs).firstWhere((r) => r.cropId == id);

  group('cropBreakdownRows', () {
    test('moneda única: la cifra de siempre, sin mezcla', () {
      final row = cropRow([
        tx(type: TransactionType.income, amount: 5000, cropId: 'cafe'),
        tx(
            type: TransactionType.expense,
            amount: 2000,
            category: 'fertilizante',
            cropId: 'cafe'),
      ], 'cafe');

      expect(row.name, 'Café');
      expect(row.count, 2);
      expect(row.isMixed, isFalse);
      expect(row.singleCurrency, 'COP');
      expect(row.incomes, {'COP': 5000.0});
      expect(row.expenses, {'COP': 2000.0});
      expect(row.incomesTotal, 5000.0);
      expect(row.expensesTotal, 2000.0);
      expect(row.hasAnyAmount, isTrue);
    });

    test('moneda mixta: cada moneda en su mapa y sin cifra única', () {
      final row = cropRow([
        tx(type: TransactionType.income, amount: 5000, cropId: 'cafe'),
        tx(
            type: TransactionType.income,
            amount: 200,
            currency: 'EUR',
            cropId: 'cafe'),
        tx(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante',
            cropId: 'cafe'),
        tx(
            type: TransactionType.expense,
            amount: 50,
            currency: 'EUR',
            category: 'transporte',
            cropId: 'cafe'),
      ], 'cafe');

      expect(row.isMixed, isTrue);
      expect(row.singleCurrency, isNull,
          reason: 'con dos monedas no hay cifra única que mostrar');
      expect(row.currencies, {'COP', 'EUR'});
      expect(row.incomes, {'COP': 5000.0, 'EUR': 200.0});
      expect(row.expenses, {'COP': 1000.0, 'EUR': 50.0},
          reason: 'los mapas jamás mezclan monedas entre sí');
      // Las sumas siguen existiendo, pero solo para ordenar filas.
      expect(row.incomesTotal, 5200.0);
      expect(row.hasAnyAmount, isTrue);
    });

    test('los borrados no cuentan', () {
      final row = cropRow([
        tx(type: TransactionType.income, amount: 5000, cropId: 'cafe'),
        tx(
            type: TransactionType.income,
            amount: 999,
            cropId: 'cafe',
            deleted: true),
      ], 'cafe');

      expect(row.count, 1);
      expect(row.incomes, {'COP': 5000.0});
    });

    test('cultivo sin movimientos sale con los mapas vacíos', () {
      final rows = rowsOf([
        tx(type: TransactionType.income, amount: 5000, cropId: 'cafe'),
      ]);
      final platanoRow = rows.firstWhere((r) => r.cropId == 'platano');

      expect(platanoRow.hasAnyAmount, isFalse,
          reason: 'el caller decide si pinta la fila vacía');
      expect(platanoRow.isMixed, isFalse);
    });

    test('los movimientos sin cultivo usan el rótulo indicado', () {
      final rows = rowsOf([
        tx(type: TransactionType.income, amount: 5000, cropId: 'cafe'),
        tx(type: TransactionType.income, amount: 100),
      ]);

      final sinCultivo = rows.firstWhere((r) => r.cropId == null);
      expect(sinCultivo.name, 'Sin cultivo');
      expect(sinCultivo.incomes, {'COP': 100.0});
    });
  });

  group('byCurrencyText', () {
    test('lista cada moneda ordenada con su código, sin sumarlas', () {
      // Formato de mentira: el helper solo une, nunca opera entre monedas.
      String fmt(double v, String c) => v.toStringAsFixed(0);

      expect(
        byCurrencyText({'EUR': 200.0, 'COP': 5000.0}, fmt),
        '5000 COP · 200 EUR',
        reason: 'orden alfabético de códigos y una cifra por moneda',
      );
    });

    test('un solo monto también sale con su código', () {
      expect(
        byCurrencyText({'COP': 5000.0}, (v, c) => v.toStringAsFixed(0)),
        '5000 COP',
      );
    });

    test('mapa vacío no deja texto suelto', () {
      expect(byCurrencyText({}, (v, c) => '$v'), '');
    });
  });
}
