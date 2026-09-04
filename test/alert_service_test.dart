import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';

Transaction _txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String category = 'otro',
  String? cropId,
}) {
  return Transaction(
    id: '${type.name}_${amount}_${date.millisecondsSinceEpoch}',
    type: type,
    category: category,
    amount: amount,
    date: date,
    createdAt: DateTime(2026, 1, 1),
  );
}

List<Crop> _crops() => const [
      Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
      Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825'),
    ];

void main() {
  final now = DateTime(2026, 6, 15);

  group('Regla 1 — Gasto excesivo', () {
    test('dispara cuando mes actual > 2× promedio histórico', () {
      final txns = [
        // Histórico manual de obra 100/mes x 3 meses
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 1, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        // Mes actual: 300 > 2*100
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(
        alerts.any((a) => a.rule == AlertRule.excessiveSpending),
        isTrue,
        reason: 'debe dispararse excess spend',
      );
    });

    test('NO dispara si el gasto mes actual está dentro de 2×', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 1, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 150, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(
        alerts.where((a) => a.rule == AlertRule.excessiveSpending),
        isEmpty,
        reason: '150 no supera 2×100',
      );
    });
  });

  group('Regla 2 — Sin ingresos', () {
    test('dispara si la última venta tiene >= 60 días', () {
      final txns = [
        _txn(
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 3, 1),
          category: 'venta_cafe',
        ),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.any((a) => a.rule == AlertRule.noIncome), isTrue);
    });

    test('NO dispara si hubo venta reciente', () {
      final txns = [
        _txn(
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 6, 1),
          category: 'venta_cafe',
        ),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.where((a) => a.rule == AlertRule.noIncome), isEmpty);
    });
  });

  group('Regla 3 — Balance negativo 3+ meses', () {
    test('dispara con 3 meses consecutivos de pérdida', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 4, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 5, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 6, 10)),
        _txn(type: TransactionType.income, amount: 100, date: DateTime(2026, 4, 15)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.any((a) => a.rule == AlertRule.consecutiveLosses), isTrue);
    });

    test('NO dispara con solo 2 meses de pérdida', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 6, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 5, 10)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.where((a) => a.rule == AlertRule.consecutiveLosses), isEmpty);
    });
  });

  group('Regla 4 — Precio bajo', () {
    test('dispara si la media de los últimos 30 días es menor a la histórica', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.any((a) => a.rule == AlertRule.lowPrice), isTrue);
    });

    test('NO dispara si la media reciente es mayor o igual', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 500, date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 500, date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 500, date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 600, date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 600, date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.where((a) => a.rule == AlertRule.lowPrice), isEmpty);
    });
  });

  group('Regla 5 — Cultivo deficitario', () {
    test('dispara ROI < -30% en un cultivo', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10), cropId: 'cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.any((a) => a.rule == AlertRule.deficitCrop), isTrue);
    });

    test('NO dispara con ROI >= -30%', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10), cropId: 'cafe'),
        _txn(type: TransactionType.income, amount: 800, date: DateTime(2026, 2, 10), cropId: 'cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops());
      expect(alerts.where((a) => a.rule == AlertRule.deficitCrop), isEmpty);
    });
  });
}