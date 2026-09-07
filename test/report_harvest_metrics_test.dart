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