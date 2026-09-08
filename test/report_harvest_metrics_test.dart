import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';

Harvest _h({
  required String id,
  required String? cropId,
  required DateTime date,
  required double amount,
  String unit = 'kg',
  HarvestDestination destination = HarvestDestination.vendido,
}) {
  return Harvest(
    id: id,
    cropId: cropId,
    date: date,
    amount: amount,
    unit: unit,
    destination: destination,
  );
}

void main() {
  const metrics = ReportHarvestMetrics();
  const crops = [
    Crop(id: 'cafe', name: 'Café', phase: CropPhase.produccion,
        areaHa: 0.5, livePlants: 1000),
    Crop(id: 'platano', name: 'Plátano'),
  ];

  group('totalsByCrop', () {
    test('suma por cultivo y normaliza a kg', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 2, unit: 'arroba'),
        _h(id: 'h2', cropId: 'cafe', date: DateTime(2026, 5, 2), amount: 10, unit: 'kg'),
      ];
      final byCrop = metrics.totalsByCrop(harvests, crops);
      final cafe = byCrop.firstWhere((c) => c.cropId == 'cafe');
      expect(cafe.amount, 12);
      // 2 arrobas = 25 kg + 10 kg = 35 kg
      expect(cafe.kg, 35);
    });
  });

  group('totalsByDestination', () {
    test('agrupa por destino', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 10),
        _h(id: 'h2', cropId: 'cafe', date: DateTime(2026, 5, 2), amount: 5,
            destination: HarvestDestination.almacenado),
      ];
      final byDest = metrics.totalsByDestination(harvests);
      expect(byDest[HarvestDestination.vendido], 10);
      expect(byDest[HarvestDestination.almacenado], 5);
    });
  });

  group('costos por kg', () {
    test('pickupCostPerKg divide gastos vinculados ÷ kg cosechados', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 40, unit: 'kg'),
      ];
      final attached = txn(amount: 2000, harvestId: 'h1');
      final unattached = txn(amount: 9999, harvestId: null);
      final cost = metrics.pickupCostPerKg([attached, unattached], harvests);
      expect(cost, 50); // 2000 / 40
    });

    test('totalCostPerKg solo en producción, usa gastos del cultivo', () {
      final crop = crops.first;
      final harvests = [_h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 100, unit: 'kg')];
      final expenses = [txn(amount: 5000, harvestId: null)];
      final cost = metrics.totalCostPerKg(crop, expenses, harvests);
      expect(cost, 50);
    });

    test('totalCostPerKg null en establecimiento', () {
      const establecimiento = Crop(id: 'nuevo', name: 'Nuevo',
          phase: CropPhase.establecimiento);
      final harvests = [_h(id: 'h1', cropId: 'nuevo', date: DateTime(2026, 5, 1), amount: 100)];
      final cost = metrics.totalCostPerKg(establecimiento, [txn(amount: 100, harvestId: null)], harvests);
      expect(cost, isNull);
    });
  });

  group('rendimiento', () {
    test('yieldPerArea y yieldPerPlant usan kg cosechados', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 200, unit: 'kg'),
      ];
      expect(metrics.yieldPerArea(harvests, 0.5), 400); // 200/0.5
      expect(metrics.yieldPerPlant(harvests, 1000), 0.2); // 200/1000
    });
  });

  group('soldVsHarvested', () {
    test('compara venta vs cosecha en kg por cultivo', () {
      final now = DateTime(2026, 6, 15);
      final sales = [
        Transaction(
          id: 'v1', type: TransactionType.income, cropId: 'cafe',
          category: 'venta_cafe', amount: 1000, quantity: 3, unit: 'arroba',
          date: DateTime(2026, 6, 1), createdAt: DateTime(2026, 6, 1),
        ),
      ];
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 10, unit: 'kg'),
      ];
      final rows = metrics.soldVsHarvested(sales, harvests, crops, now);
      final cafe = rows.firstWhere((r) => r.cropId == 'cafe');
      expect(cafe.soldKg, 37.5); // 3 arrobas = 37.5 kg
      expect(cafe.harvestedKg, 10);
    });
  });

  group('por hectárea y amortización', () {
    Transaction income(double a, {bool deleted = false}) => Transaction(
          id: 'i$a',
          type: TransactionType.income,
          category: 'Venta de café',
          amount: a,
          date: DateTime(2026, 5, 1),
          createdAt: DateTime(2026, 5, 1),
          deleted: deleted,
        );

    Transaction expense(double a) => Transaction(
          id: 'e$a',
          type: TransactionType.expense,
          category: 'Recogida',
          amount: a,
          date: DateTime(2026, 5, 1),
          createdAt: DateTime(2026, 5, 1),
        );

    test('revenuePerHa suma ingresos ÷ área', () {
      final txs = [income(3000000), income(2500000)];
      expect(metrics.revenuePerHa(txs, 2.0), 2750000);
    });

    test('revenuePerHa ignora gastos y eliminados, null sin área', () {
      final txs = [income(3000000, deleted: true), expense(999000)];
      expect(metrics.revenuePerHa(txs, 2.0), isNull); // sin ingresos válidos → null
      expect(metrics.revenuePerHa([income(1000)], null), isNull);
      expect(metrics.revenuePerHa([income(1000)], 0), isNull);
    });

    test('costPerHa suma gastos ÷ área', () {
      final txs = [expense(700000), expense(450000)];
      expect(metrics.costPerHa(txs, 2.0), 575000);
    });

    test('costPerHa ignora ingresos, null sin área', () {
      final txs = [income(1000), expense(999000)];
      expect(metrics.costPerHa(txs, 2.0), 499500);
      expect(metrics.costPerHa(txs, null), isNull);
    });

    test('marginPerHa resta ingresos − gastos, null si no hay dato', () {
      expect(metrics.marginPerHa(2750000, 575000), 2175000);
      expect(metrics.marginPerHa(null, null), isNull);
      expect(metrics.marginPerHa(2750000, null), 2750000);
      expect(metrics.marginPerHa(null, 575000), -575000);
    });

    test('recoveryRate = margen ÷ inversión', () {
      expect(metrics.recoveryRate(8000000, 3600000), closeTo(0.45, 0.001));
      expect(metrics.recoveryRate(null, 3600000), isNull);
      expect(metrics.recoveryRate(8000000, null), isNull);
      expect(metrics.recoveryRate(0, 3600000), isNull);
    });

    test('breakevenYears = inversión ÷ margen anual promedio medido', () {
      expect(metrics.breakevenYears(8000000, 2500000), closeTo(3.2, 0.001));
      expect(metrics.breakevenYears(8000000, 0), isNull);
      expect(metrics.breakevenYears(8000000, -100), isNull);
      expect(metrics.breakevenYears(null, 2500000), isNull);
      expect(metrics.breakevenYears(0, 2500000), isNull);
    });
  });
}

Transaction txn({required double amount, required String? harvestId}) {
  return Transaction(
    id: 't$amount',
    type: TransactionType.expense,
    cropId: 'cafe',
    category: 'recogida',
    amount: amount,
    harvestId: harvestId,
    date: DateTime(2026, 5, 1),
    createdAt: DateTime(2026, 5, 1),
  );
}