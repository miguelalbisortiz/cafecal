import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';

Transaction _tx({
  required String id,
  String category = kExpenseCategoryBenefit,
  double amount = 50000,
  String currency = 'COP',
  String? harvestId,
  bool deleted = false,
}) {
  final fecha = DateTime.parse('2026-11-01T00:00:00.000');
  return Transaction(
    id: id,
    type: TransactionType.expense,
    category: category,
    amount: amount,
    currency: currency,
    date: fecha,
    createdAt: fecha,
    harvestId: harvestId,
    deleted: deleted,
  );
}

Harvest _h(String id, double kg) => Harvest(
      id: id,
      cropId: 'c1',
      date: DateTime.parse('2026-11-01T00:00:00.000'),
      amount: kg,
      unit: 'kg',
    );

void main() {
  group('categorías de beneficio', () {
    test('beneficio y secado son gasto de producción, no inversión', () {
      expect(expenseGroupOf(kExpenseCategoryBenefit), ExpenseGroup.produccion);
      expect(expenseGroupOf(kExpenseCategoryDrying), ExpenseGroup.produccion);
    });

    test('están en el catálogo y se reconocen como beneficio', () {
      final keys = expenseCategories.map((c) => c.key).toSet();
      expect(keys, containsAll([kExpenseCategoryBenefit, kExpenseCategoryDrying]));
      expect(isBenefitCategory(kExpenseCategoryBenefit), isTrue);
      expect(isBenefitCategory(kExpenseCategoryDrying), isTrue);
      expect(isBenefitCategory(kExpenseCategoryHarvest), isFalse);
    });
  });

  group('costo de beneficio por kg', () {
    const metrics = ReportHarvestMetrics();

    test('suma los gastos ligados a cosecha y divide por los kg', () {
      final txs = [
        _tx(id: 'b1', harvestId: 'h1', amount: 40000),
        _tx(
            id: 'b2',
            category: kExpenseCategoryDrying,
            harvestId: 'h2',
            amount: 60000),
      ];
      final harvests = [_h('h1', 60), _h('h2', 140)];
      expect(metrics.benefitCostPerKg(txs, harvests), 500);
    });

    test('un gasto sin cosecha ligada no se reparte a ciegas', () {
      final txs = [_tx(id: 'b1', amount: 40000)];
      expect(metrics.benefitCostPerKg(txs, [_h('h1', 100)]), isNull);
    });

    test('sin gastos de beneficio devuelve null, nunca 0', () {
      final txs = [
        _tx(
            id: 'c1',
            category: kExpenseCategoryHarvest,
            harvestId: 'h1',
            amount: 20000),
      ];
      expect(metrics.benefitCostPerKg(txs, [_h('h1', 100)]), isNull);
    });

    test('sin kilos no hay costo por kg', () {
      final txs = [_tx(id: 'b1', harvestId: 'h1')];
      expect(metrics.benefitCostPerKg(txs, const []), isNull);
    });

    test('borrados no cuentan', () {
      final txs = [
        _tx(id: 'b1', harvestId: 'h1', amount: 40000),
        _tx(id: 'b2', harvestId: 'h1', amount: 60000, deleted: true),
      ];
      expect(metrics.benefitCostPerKg(txs, [_h('h1', 100)]), 400);
    });

    test('monedas mezcladas → null, y se pueden listar', () {
      final txs = [
        _tx(id: 'b1', harvestId: 'h1', amount: 40000),
        _tx(id: 'b2', harvestId: 'h1', amount: 10, currency: 'USD'),
      ];
      final harvests = [_h('h1', 100)];
      expect(metrics.benefitCostCurrencies(txs), hasLength(2));
      expect(metrics.benefitCostPerKg(txs, harvests), isNull);
    });
  });

  group('beneficio sin cosecha ligada', () {
    const metrics = ReportHarvestMetrics();

    test('lista solo los gastos de beneficio sin harvestId, sin borrados', () {
      final txs = [
        _tx(id: 'b1', amount: 40000, harvestId: 'h1'),
        _tx(id: 'b2', category: kExpenseCategoryDrying, amount: 25000),
        _tx(id: 'b3', amount: 10000, deleted: true),
        _tx(id: 'c1', category: kExpenseCategoryHarvest, amount: 5000),
      ];
      final out = metrics.benefitCostsWithoutHarvest(txs).toList();
      expect(out.map((t) => t.id), ['b2']);
      expect(amountsByCurrency(out), {'COP': 25000});
    });

    test('no se cuela en el costo por kg, que solo mira lo ligado', () {
      final txs = [
        _tx(id: 'b1', amount: 40000, harvestId: 'h1'),
        _tx(id: 'b2', amount: 60000),
      ];
      final harvests = [_h('h1', 100)];
      expect(metrics.benefitCostPerKg(txs, harvests), 400);
      expect(amountsByCurrency(metrics.benefitCostsWithoutHarvest(txs)),
          {'COP': 60000});
    });
  });

  group('beneficio no contamina la recogida', () {
    const metrics = ReportHarvestMetrics();

    test('un gasto de beneficio ligado a cosecha no entra en recogida', () {
      final txs = [
        _tx(
            id: 'c1',
            category: kExpenseCategoryHarvest,
            harvestId: 'h1',
            amount: 30000),
        _tx(id: 'b1', harvestId: 'h1', amount: 70000),
      ];
      // Solo los 30.000 de cosecha, entre 100 kg: el beneficio es otro eslabón.
      expect(metrics.pickupCostPerKg(txs, [_h('h1', 100)]), 300);
      expect(metrics.pickupCostCurrencies(txs), {'COP'});
    });
  });
}
