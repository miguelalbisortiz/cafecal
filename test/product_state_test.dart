import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/product_state.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/sales_by_state.dart';

Transaction _tx({
  String id = 't1',
  TransactionType type = TransactionType.income,
  String category = 'venta',
  double amount = 100000,
  String currency = 'COP',
  double? quantity,
  String? unit,
  double? equivalentKg,
  double? deductionQty,
  ProductState? productState,
  bool deleted = false,
}) {
  final fecha = DateTime.parse('2026-11-01T00:00:00.000');
  return Transaction(
    id: id,
    type: type,
    category: category,
    amount: amount,
    currency: currency,
    date: fecha,
    createdAt: fecha,
    quantity: quantity,
    unit: unit,
    equivalentKg: equivalentKg,
    deductionQty: deductionQty,
    productState: productState,
    deleted: deleted,
  );
}

void main() {
  group('ProductState', () {
    test('serialize/parse van y vuelven', () {
      for (final s in ProductState.values) {
        expect(ProductState.parse(s.serialize), s);
      }
    });

    test('desconocido o vacío → null, nunca excepción', () {
      expect(ProductState.parse(null), isNull);
      expect(ProductState.parse(''), isNull);
      expect(ProductState.parse('maduro'), isNull);
    });
  });

  group('Transaction · product_state', () {
    test('una venta conserva el estado en JSON', () {
      final t = _tx(productState: ProductState.pergamino);
      final vuelta = Transaction.fromJson(t.toJson());
      expect(vuelta.productState, ProductState.pergamino);
    });

    test('sin estado guarda null (no un valor inventado)', () {
      final t = _tx();
      expect(t.toJson()['product_state'], isNull);
      expect(Transaction.fromJson(t.toJson()).productState, isNull);
    });

    test('copyWith puede borrar el estado', () {
      final t = _tx(productState: ProductState.verde);
      expect(t.copyWith(productState: null).productState, isNull);
      // Sin tocarlo, se conserva.
      expect(t.copyWith(amount: 1).productState, ProductState.verde);
    });

    test('un estado colgado de un gasto se limpia y se marca sucio', () {
      final t = _tx(
        type: TransactionType.expense,
        category: 'fertilizante',
        productState: ProductState.cereza,
      );
      final vuelta = Transaction.fromJson(t.toJson());
      expect(vuelta.productState, isNull);
      expect(vuelta.pendingSync, isTrue,
          reason: 'la corrección tiene que subir a Supabase');
    });

    test('una subvención no lleva estado', () {
      final t = _tx(category: 'subvenciones', productState: ProductState.tueste);
      final vuelta = Transaction.fromJson(t.toJson());
      expect(vuelta.productState, isNull);
      expect(vuelta.pendingSync, isTrue);
    });

    test('las claves viejas de venta sí lo conservan', () {
      final t = _tx(category: 'venta_cafe', productState: ProductState.cereza);
      expect(Transaction.fromJson(t.toJson()).productState,
          ProductState.cereza);
    });
  });

  group('salesByState', () {
    test('agrupa por estado y calcula precio medio por kilo', () {
      final txs = [
        _tx(
          id: 'a',
          amount: 600000,
          quantity: 100,
          unit: 'kg',
          productState: ProductState.cereza,
        ),
        _tx(
          id: 'b',
          amount: 400000,
          quantity: 50,
          unit: 'kg',
          productState: ProductState.cereza,
        ),
        _tx(
          id: 'c',
          amount: 900000,
          quantity: 60,
          unit: 'kg',
          productState: ProductState.pergamino,
        ),
      ];

      final r = salesByState(txs, currency: 'COP');

      expect(r.length, 2);
      final cereza = r.firstWhere((x) => x.state == ProductState.cereza);
      expect(cereza.amount, 1000000);
      expect(cereza.kg, 150);
      expect(cereza.pricePerKg, closeTo(6666.666, 0.01));

      final pergamino = r.firstWhere((x) => x.state == ProductState.pergamino);
      expect(pergamino.pricePerKg, closeTo(15000, 0.01));
    });

    test('respeta el orden de la cadena (cereza → tueste)', () {
      final r = salesByState([
        _tx(id: 'a', productState: ProductState.tueste, quantity: 1, unit: 'kg'),
        _tx(id: 'b', productState: ProductState.cereza, quantity: 1, unit: 'kg'),
      ], currency: 'COP');
      expect(r.map((x) => x.state).toList(),
          [ProductState.cereza, ProductState.tueste]);
    });

    test('ignora otras monedas, borradas y ventas sin estado', () {
      final r = salesByState([
        _tx(id: 'usd', currency: 'USD', productState: ProductState.verde),
        _tx(id: 'del', deleted: true, productState: ProductState.verde),
        _tx(id: 'sin', productState: null),
        _tx(id: 'ok', productState: ProductState.verde),
      ], currency: 'COP');

      expect(r.length, 1);
      expect(r.first.amount, 100000);
    });

    test('el descuento del comprador baja los kilos', () {
      final r = salesByState([
        _tx(
          quantity: 100,
          unit: 'kg',
          deductionQty: 20,
          amount: 800000,
          productState: ProductState.cereza,
        ),
      ], currency: 'COP');

      expect(r.first.kg, 80);
      expect(r.first.pricePerKg, 10000);
    });

    test('salesByStateByCurrency separa monedas y ordena sus códigos', () {
      final r = salesByStateByCurrency([
        _tx(id: 'usd', currency: 'USD', productState: ProductState.verde),
        _tx(id: 'cop', productState: ProductState.cereza),
        _tx(id: 'sin', productState: null),
        _tx(id: 'del', deleted: true, productState: ProductState.tueste),
      ]);

      expect(r.map((g) => g.currency).toList(), ['COP', 'USD']);
      expect(r.first.rows.single.state, ProductState.cereza);
      expect(r.last.rows.single.state, ProductState.verde);
    });

    test('un racimo sin peso no inventa kilos ni precio', () {
      final r = salesByState([
        _tx(quantity: 12, unit: 'racimo', productState: ProductState.cereza),
      ], currency: 'COP');

      expect(r.first.kg, 0);
      expect(r.first.pricePerKg, isNull);
    });
  });
}
