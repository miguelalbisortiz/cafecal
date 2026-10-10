import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
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

Transaction _sale({
  required String id,
  required double amount,
  double? quantity,
  String unit = 'kg',
  TransactionType type = TransactionType.income,
  bool deleted = false,
}) {
  return Transaction(
    id: id,
    type: type,
    category: 'venta_cafe',
    amount: amount,
    quantity: quantity,
    unit: unit,
    deleted: deleted,
    date: DateTime(2026, 5, 1),
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  const metrics = ReportHarvestMetrics();

  group('periodCostPerKg (P2 — precio de venta vs costo por kilo)', () {
    test('gastos ÷ kg cosechados, normalizado a kg', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 10),
        _h(id: 'h2', cropId: 'cafe', date: DateTime(2026, 5, 2), amount: 5),
      ];
      expect(metrics.periodCostPerKg(1500, harvests), 100);
    });

    test('sin cosechas devuelve null, nunca 0 (un 0 compararía mal)', () {
      expect(metrics.periodCostPerKg(1500, []), isNull);
    });

    test('normaliza unidades que no son kg', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1), amount: 2,
            unit: 'arroba'),
      ];
      final cost = metrics.periodCostPerKg(300, harvests);
      expect(cost, isNotNull);
      expect(cost!, greaterThan(0));
    });
  });

  group('avgSalePricePerKg (P2 — precio de venta vs costo por kilo)', () {
    test('ingresos ÷ kilos vendidos', () {
      final rows = [
        _sale(id: 't1', amount: 10000, quantity: 10),
        _sale(id: 't2', amount: 20000, quantity: 10),
      ];
      expect(metrics.avgSalePricePerKg(rows), 1500);
    });

    test('las ventas sin kilos aportan cero, no inflan el promedio', () {
      final rows = [
        _sale(id: 't1', amount: 10000, quantity: 10),
        _sale(id: 't2', amount: 900000), // sin cantidad anotada
      ];
      expect(metrics.avgSalePricePerKg(rows), 1000);
    });

    test('ignora gastos y movimientos eliminados', () {
      final rows = [
        _sale(id: 't1', amount: 10000, quantity: 10),
        _sale(id: 't2', amount: 999999, quantity: 10,
            type: TransactionType.expense),
        _sale(id: 't3', amount: 999999, quantity: 10, deleted: true),
      ];
      expect(metrics.avgSalePricePerKg(rows), 1000);
    });

    test('si nadie anota kilos, null: no se inventa un precio', () {
      final rows = [_sale(id: 't1', amount: 10000)];
      expect(metrics.avgSalePricePerKg(rows), isNull);
      expect(metrics.avgSalePricePerKg(const []), isNull);
    });
  });

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

    test('A2: el kg de un saco sale del peso configurado', () {
      final harvests = [
        _h(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 1),
            amount: 3, unit: 'saco'),
      ];

      final norma = const ReportHarvestMetrics().totalsByCrop(harvests, crops);
      final suCostal = const ReportHarvestMetrics(sacoKg: 60)
          .totalsByCrop(harvests, crops);

      // 3 sacos: 210 kg con la norma, 180 kg si su costal pesa 60.
      expect(norma.firstWhere((c) => c.cropId == 'cafe').kg, 210);
      expect(suCostal.firstWhere((c) => c.cropId == 'cafe').kg, 180);
      // Las unidades que no son saco no se enteran del ajuste.
      final kilos = [
        _h(id: 'h2', cropId: 'cafe', date: DateTime(2026, 5, 2),
            amount: 5, unit: 'kg'),
      ];
      expect(const ReportHarvestMetrics(sacoKg: 60)
          .totalsByCrop(kilos, crops)
          .firstWhere((c) => c.cropId == 'cafe')
          .kg, 5);
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

    test('moneda única vs mezcla: nunca se suman monedas distintas', () {
      Transaction conMoneda(TransactionType type, double a, String c) =>
          Transaction(
            id: '${type.name}_${a}_$c',
            type: type,
            category: type.isExpense ? 'Recogida' : 'Venta de café',
            amount: a,
            currency: c,
            date: DateTime(2026, 5, 1),
            createdAt: DateTime(2026, 5, 1),
          );

      // Moneda única: la cifra de siempre (5.000 ÷ 2 ha).
      expect(
          metrics.revenuePerHa(
              [conMoneda(TransactionType.income, 3000, 'COP'),
               conMoneda(TransactionType.income, 2000, 'COP')],
              2.0),
          2500);
      expect(
          metrics.costPerHa([conMoneda(TransactionType.expense, 1000, 'COP')],
              2.0),
          500);

      // Moneda mixta: null, no un total inventado.
      expect(
          metrics.revenuePerHa(
              [conMoneda(TransactionType.income, 3000, 'COP'),
               conMoneda(TransactionType.income, 500, 'USD')],
              2.0),
          isNull,
          reason: '3.000 COP + 500 USD no es un ingreso por hectárea');
      expect(
          metrics.costPerHa(
              [conMoneda(TransactionType.expense, 1000, 'COP'),
               conMoneda(TransactionType.expense, 500, 'USD')],
              2.0),
          isNull,
          reason: '3.500 "totales" sería una cifra falsa');

      // Lo que no está mezclado sigue midiéndose: los ingresos en COP solos
      // son válidos aunque los gastos de otra moneda estén en la lista.
      expect(
          metrics.revenuePerHa(
              [conMoneda(TransactionType.income, 3000, 'COP'),
               conMoneda(TransactionType.expense, 500, 'USD')],
              2.0),
          1500);
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

  group('splitInvestmentAndOperation (L2.1 — inversión inicial vs operación)', () {
    Transaction expense(
      double amount, {
      String category = 'mano_obra',
      String? sowingId,
      bool deleted = false,
    }) {
      return Transaction(
        id: 'g$amount$category$sowingId$deleted',
        type: TransactionType.expense,
        cropId: 'cafe',
        category: category,
        amount: amount,
        sowingId: sowingId,
        deleted: deleted,
        date: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
      );
    }

    test('gasto de categoría siembra es inversión inicial', () {
      final split = metrics.splitInvestmentAndOperation(
          [expense(600000, category: kExpenseCategorySowing)]);
      expect(split.investment, 600000);
      expect(split.operation, 0);
    });

    test('gasto con sowingId anotado es inversión inicial', () {
      final split =
          metrics.splitInvestmentAndOperation([expense(250000, sowingId: 's1')]);
      expect(split.investment, 250000);
      expect(split.operation, 0);
    });

    test('gasto normal es operación del período', () {
      final split = metrics.splitInvestmentAndOperation([expense(400000)]);
      expect(split.investment, 0);
      expect(split.operation, 400000);
    });

    test('los borrados no cuentan en ninguna de las dos', () {
      final split = metrics.splitInvestmentAndOperation([
        expense(100000, category: kExpenseCategorySowing, deleted: true),
        expense(50000, deleted: true),
        expense(300000, category: kExpenseCategorySowing),
        expense(200000),
      ]);
      expect(split.investment, 300000);
      expect(split.operation, 200000);
      expect(split.total, 500000);
    });

    test('inversión + operación = total de gastos (sin duplicar ni perder)', () {
      final gastos = [
        expense(600000, category: kExpenseCategorySowing),
        expense(250000, sowingId: 's1'),
        expense(400000),
        expense(150000, category: 'fertilizante'),
      ];
      final total = gastos.fold<double>(0, (a, t) => a + t.amount);
      final split = metrics.splitInvestmentAndOperation(gastos);
      expect(split.investment + split.operation, total);
      expect(split.investment, 850000);
      expect(split.operation, 550000);
      // Sin gastos no hay nada que repartir: todo en cero, nunca null.
      final vacio = metrics.splitInvestmentAndOperation(const []);
      expect(vacio.investment, 0);
      expect(vacio.operation, 0);
      expect(vacio.total, 0);
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