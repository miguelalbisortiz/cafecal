import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/transaction.dart';

void main() {
  Transaction base({
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? client,
    String? provider,
    double? harvestedKg,
    double? equivalentKg,
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
      harvestedKg: harvestedKg,
      equivalentKg: equivalentKg,
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

  group('Kilos recolectados del jornal (Tanda 2)', () {
    test('un JSON con harvested_kg sobrevive al round-trip', () {
      final json = <String, dynamic>{
        'id': 'j1',
        'type': 'expense',
        'category': 'mano_obra',
        'amount': 100000,
        'date': '2026-10-19T00:00:00.000',
        'created_at': '2026-10-19T00:00:00.000Z',
        'harvested_kg': 120.5,
      };
      final t = Transaction.fromJson(json);
      expect(t.toJson()['harvested_kg'], 120.5);
    });

    test('toJson deja la clave en null, nunca en 0', () {
      final json = base().toJson();
      expect(json.containsKey('harvested_kg'), isTrue,
          reason: 'la clave viaja siempre: null = no medido, distinto de 0');
      expect(json['harvested_kg'], isNull);
    });

    test('fromJson sin la clave carga null (respaldo viejo)', () {
      final t = Transaction.fromJson(<String, dynamic>{
        'id': 'j_old',
        'type': 'expense',
        'category': 'mano_obra',
        'amount': 100000,
        'date': '2026-10-19T00:00:00.000',
        'created_at': '2026-10-19T00:00:00.000Z',
      });
      expect(t.harvestedKg, isNull);
    });

    test('round-trip con kilos conserva 120.5', () {
      final round = Transaction.fromJson(base(harvestedKg: 120.5).toJson());
      expect(round.harvestedKg, 120.5);
    });

    test('round-trip sin kilos conserva null', () {
      final round = Transaction.fromJson(base().toJson());
      expect(round.harvestedKg, isNull);
    });

    test('copyWith permite limpiar los kilos con null', () {
      final t = base(harvestedKg: 120.5);
      expect(t.copyWith(harvestedKg: null).harvestedKg, isNull,
          reason: 'un jornal que deja de ser Cosechar no conserva el dato');
    });

    test('copyWith sin argumento conserva los kilos', () {
      final t = base(harvestedKg: 120.5);
      expect(t.copyWith(quantity: 3).harvestedKg, 120.5);
    });
  });

  group('Tanda 4 · peso de la venta en racimo o cajón', () {
    test('toJson lleva el peso y fromJson lo devuelve', () {
      final round = Transaction.fromJson(
          base(quantity: 12, unit: 'racimo', equivalentKg: 240).toJson());
      expect(round.equivalentKg, 240);
      expect(round.unit, 'racimo');
      expect(round.quantity, 12);
    });

    test('sin peso la clave viaja en null, nunca en 0', () {
      final json = base(quantity: 12, unit: 'racimo').toJson();
      expect(json.containsKey('equivalent_kg'), isTrue,
          reason: 'null = sin peso, distinto de 0');
      expect(json['equivalent_kg'], isNull);
    });

    test('un respaldo viejo sin la clave carga null', () {
      final t = Transaction.fromJson(<String, dynamic>{
        'id': 'j_old',
        'type': 'income',
        'category': 'venta_cafe',
        'amount': 1000,
        'date': '2026-10-20T00:00:00.000',
        'created_at': '2026-10-20T00:00:00.000Z',
      });
      expect(t.equivalentKg, isNull);
    });

    test('copyWith permite limpiar el peso con null', () {
      final t = base(quantity: 12, unit: 'racimo', equivalentKg: 240);
      expect(t.copyWith(equivalentKg: null).equivalentKg, isNull,
          reason: 'al cambiar la unidad, el peso viejo no queda escondido');
    });

    test('copyWith sin argumento conserva el peso', () {
      final t = base(quantity: 12, unit: 'racimo', equivalentKg: 240);
      expect(t.copyWith(quantity: 13).equivalentKg, 240);
    });
  });
}
