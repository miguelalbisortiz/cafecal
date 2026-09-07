import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/transaction.dart';

void main() {
  Transaction base({
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? client,
    String? provider,
  }) {
    return Transaction(
      id: 't1',
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 40000,
      date: DateTime(2026, 9, 6),
      createdAt: DateTime(2026, 9, 6),
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      client: client,
      provider: provider,
    );
  }

  group('Serialización retrocompatible', () {
    test('registro sin campos nuevos carga null y conserva el resto', () {
      const json = {
        'id': 't_old',
        'crop_id': null,
        'type': 'expense',
        'category': 'fertilizante',
        'amount': 1000,
        'currency': 'COP',
        'description': 'compra vieja',
        'date': '2026-01-01T00:00:00.000',
        'created_at': '2026-01-01T00:00:00.000Z',
        'pending_sync': false,
        'deleted': false,
      };
      final t = Transaction.fromJson(json);
      expect(t.quantity, isNull);
      expect(t.unit, isNull);
      expect(t.pricePerUnit, isNull);
      expect(t.client, isNull);
      expect(t.provider, isNull);
      expect(t.amount, 1000);
      expect(t.category, 'fertilizante');
      expect(t.description, 'compra vieja');
    });

    test('toJson → fromJson conserva los campos nuevos', () {
      final t = base(
        quantity: 2,
        unit: 'arroba',
        pricePerUnit: 20000,
        client: 'Cooperativa Andina',
        provider: 'Agroinsumos SAS',
      );
      final round = Transaction.fromJson(t.toJson());
      expect(round.quantity, 2);
      expect(round.unit, 'arroba');
      expect(round.pricePerUnit, 20000);
      expect(round.client, 'Cooperativa Andina');
      expect(round.provider, 'Agroinsumos SAS');
      expect(round.amount, 40000);
    });

    test('toJson de registro sin campos no incluye claves problemáticas', () {
      final json = base().toJson();
      expect(json['quantity'], isNull);
      expect(json['unit'], isNull);
      expect(json['price_per_unit'], isNull);
      expect(json['client'], isNull);
      expect(json['provider'], isNull);
    });

    test('copyWith actualiza campos nuevos sin tocar el resto', () {
      final t = base();
      final updated = t.copyWith(quantity: 5, unit: 'kg', pricePerUnit: 8000);
      expect(updated.quantity, 5);
      expect(updated.unit, 'kg');
      expect(updated.pricePerUnit, 8000);
      expect(updated.amount, 40000);
      expect(updated.category, 'venta_cafe');
      // el original no muta
      expect(t.quantity, isNull);
    });
  });
}
