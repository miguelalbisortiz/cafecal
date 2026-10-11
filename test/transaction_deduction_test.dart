import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/transaction.dart';

/// E1 · la venta real.
///
/// En café no siempre se paga lo que se entrega: el comprador descuenta
/// impureza, humedad o piedras. Estos tests protegen la única cuenta que
/// ahora importa — entregado − descontado = pagado — y la regla de oro de la
/// app: `null` es oculto, nunca un cero inventado.
Transaction _sale({
  double? quantity = 480,
  double? deductionQty,
  String? deductionReason,
  bool paid = true,
  double amount = 2000000,
}) =>
    Transaction(
      id: 't1',
      type: TransactionType.income,
      category: 'venta',
      amount: amount,
      date: DateTime(2026, 10, 14),
      createdAt: DateTime(2026, 10, 14),
      quantity: quantity,
      unit: 'kg',
      deductionQty: deductionQty,
      deductionReason: deductionReason,
      paid: paid,
    );

void main() {
  group('netQuantity (E1)', () {
    test('sin descuento devuelve la cantidad tal cual', () {
      expect(_sale(quantity: 480).netQuantity, 480);
    });

    test('sin cantidad no hay nada que calcular', () {
      expect(_sale(quantity: null, deductionQty: 80).netQuantity, isNull);
    });

    test('resta el descuento y nunca baja de cero', () {
      expect(_sale(quantity: 480, deductionQty: 80).netQuantity, 400);
      expect(_sale(quantity: 80, deductionQty: 80).netQuantity, 0);
      expect(
        _sale(quantity: 40, deductionQty: 80).netQuantity,
        0,
        reason: 'un descuento mayor no puede producir cantidad negativa',
      );
    });

    test('un descuento en cero o negativo se trata como ninguno', () {
      expect(_sale(quantity: 480, deductionQty: 0).netQuantity, 480);
      expect(_sale(quantity: 480, deductionQty: -5).netQuantity, 480);
    });

    test('regresión: sin descuento el precio por unidad no cambia', () {
      // Antes de E1 el precio era amount / quantity. Con la resta incluida,
      // una venta sin descuento debe dar exactamente lo mismo.
      final t = _sale(quantity: 400, amount: 2000000);
      expect(t.netQuantity, t.quantity);
      expect(t.amount / t.netQuantity!, 5000);
    });
  });

  group('hasDeduction (E1)', () {
    test('solo cuenta descuentos reales', () {
      expect(_sale(quantity: 480, deductionQty: 80).hasDeduction, isTrue);
      expect(_sale(quantity: 480, deductionQty: 0).hasDeduction, isFalse);
      expect(_sale(quantity: 480).hasDeduction, isFalse);
    });
  });

  group('paid y descuento en el modelo (E1)', () {
    test('un dato viejo sin "paid" hereda true: ya era plata que entró', () {
      final t = Transaction.fromJson({
        'id': 't1',
        'type': 'income',
        'category': 'venta',
        'amount': 1000,
        'date': '2026-10-14',
        'created_at': '2026-10-14',
      });
      expect(t.paid, isTrue,
          reason: 'los registros antiguos no deben aparecer como por cobrar');
      expect(t.deductionQty, isNull);
      expect(t.deductionReason, isNull);
    });

    test('copyWith limpia el descuento con null', () {
      final t = _sale(
          quantity: 480, deductionQty: 80, deductionReason: 'impureza');
      final cleared =
          t.copyWith(deductionQty: null, deductionReason: null);
      expect(cleared.deductionQty, isNull);
      expect(cleared.deductionReason, isNull);
      expect(cleared.netQuantity, 480);
    });

    test('copyWith conserva descuento y estado cuando no se tocan', () {
      final t = _sale(quantity: 480, deductionQty: 80, paid: false);
      final kept = t.copyWith(pendingSync: true, amount: 2000000);
      expect(kept.deductionQty, 80, reason: 'subir a Supabase no lo borra');
      expect(kept.paid, isFalse, reason: 'subir a Supabase no lo borra');
    });

    test('el json lleva y devuelve los tres campos', () {
      final t = _sale(
        quantity: 480,
        deductionQty: 80,
        deductionReason: 'impureza',
        paid: false,
      );
      final round = Transaction.fromJson(t.toJson());
      expect(round.deductionQty, 80);
      expect(round.deductionReason, 'impureza');
      expect(round.paid, isFalse);
    });
  });
}
