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
  double? equivalentKg,
  HarvestDestination destination = HarvestDestination.vendido,
}) {
  return Harvest(
    id: id,
    cropId: cropId,
    date: date,
    amount: amount,
    unit: unit,
    equivalentKg: equivalentKg,
    destination: destination,
  );
}

Transaction _sale({
  required String id,
  required double amount,
  double? quantity,
  String unit = 'kg',
  double? equivalentKg,
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
    equivalentKg: equivalentKg,
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

    test('una venta en racimo usa el peso, no 1 kg por racimo', () {
      final rows = [
        _sale(
          id: 't1',
          amount: 1200000,
          quantity: 12,
          unit: 'racimo',
          equivalentKg: 240,
        ),
      ];
      expect(metrics.avgSalePricePerKg(rows), 5000,
          reason: '1.200.000 / 240 kg, no / 12');
    });

    test('una venta en racimo sin peso no entra al promedio', () {
      final rows = [
        _sale(id: 't1', amount: 10000, quantity: 10),
        _sale(id: 't2', amount: 900000, quantity: 12, unit: 'racimo'),
      ];
      expect(metrics.avgSalePricePerKg(rows), 1000,
          reason: 'los kilos del racimo no se conocen: se calla esa venta');
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

  group('cropExpensesOf — la venta no es costo', () {
    Transaction mov(TransactionType type, double amount,
            {String? cropId, bool deleted = false}) =>
        Transaction(
          id: '${type.name}_$amount',
          type: type,
          category: type.isExpense ? 'mano_obra' : 'venta_cafe',
          amount: amount,
          cropId: cropId,
          deleted: deleted,
          date: DateTime(2026, 5, 1),
          createdAt: DateTime(2026, 5, 1),
        );

    test('deja fuera los ingresos del mismo cultivo', () {
      final out = cropExpensesOf([
        mov(TransactionType.income, 1000, cropId: 'cafe'),
        mov(TransactionType.expense, 200, cropId: 'cafe'),
        mov(TransactionType.expense, 300, cropId: 'maiz'),
      ], 'cafe');
      expect(out.map((t) => t.amount), [200],
          reason: 'la venta de café no es un costo del café');
    });

    test('deja fuera los movimientos borrados', () {
      final out = cropExpensesOf([
        mov(TransactionType.expense, 200, cropId: 'cafe'),
        mov(TransactionType.expense, 500, cropId: 'cafe', deleted: true),
      ], 'cafe');
      expect(out.map((t) => t.amount), [200]);
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

  // Tanda 2 · el jornal medido mueve el denominador y nada más. No cambia el
  // pago (días × valor día) ni se suma dos veces: entra como una cosecha más.
  group('Jornal medido · efecto esperado', () {
    final cosechado = _h(
        id: 'j1', cropId: 'cafe', date: DateTime(2026, 10, 19), amount: 500);

    Transaction jornal() => Transaction(
          id: 'j1',
          cropId: 'cafe',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100000,
          currency: 'COP',
          quantity: 2,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan',
          task: 'cosechar',
          harvestedKg: 500,
          date: DateTime(2026, 10, 19),
          createdAt: DateTime(2026, 10, 19),
        );

    test('yieldPerArea incluye los kilos del jornal en el denominador', () {
      expect(metrics.yieldPerArea([cosechado], 1), 500);
      expect(metrics.yieldPerArea(const [], 1), isNull,
          reason: 'sin cosechas no hay rendimiento, ni un 0');
    });

    test('totalCostPerKg baja porque el denominador crece', () {
      const crop = Crop(
        id: 'cafe',
        name: 'Café',
        phase: CropPhase.produccion,
      );

      final costo = metrics.totalCostPerKg(crop, [jornal()], [cosechado]);

      expect(costo, 200, reason: '100.000 ÷ 500 kg medidos');
      expect(costo, lessThan(100000 / 480),
          reason: 'si el denominador fuera solo la venta, sería mayor');
    });

    test('pickupCostPerKg cuenta el jornal de Cosechar como gasto de recogida',
        () {
      expect(metrics.pickupCostPerKg([jornal()], [cosechado]), 200,
          reason: '100.000 ÷ 500 kg: cosechar con jornaleros cuesta, y ese '
              'costo es de la recogida');
    });

    test('pickupCostPerKg sin gastos de recogida es null, nunca 0', () {
      expect(metrics.pickupCostPerKg(const [], [cosechado]), isNull);
    });

    test('un jornal de Cosechar sin kilos no entra', () {
      final sinKilos = jornal().copyWith(harvestedKg: null);
      expect(metrics.pickupCostPerKg([sinKilos], [cosechado]), isNull);
    });

    test('un gasto que ya trae harvestId cuenta una sola vez', () {
      final conLazo = jornal().copyWith(harvestId: 'j1');
      expect(metrics.pickupCostPerKg([conLazo], [cosechado]), 200);
    });

    test('la moneda del jornal entra en el conjunto de la recogida', () {
      final enDolares = jornal().copyWith(id: 'j2', currency: 'USD');
      expect(metrics.pickupCostCurrencies([jornal(), enDolares]),
          {'COP', 'USD'});
      expect(metrics.pickupCostPerKg([jornal(), enDolares], [cosechado]),
          isNull,
          reason: 'no se dividen pesos con dólares');
    });
  });

  group('D1 · racimo y cajón usan el peso, no 1 kg por unidad', () {
    final racimos = [
      _h(
        id: 'h1',
        cropId: 'platano',
        date: DateTime(2026, 5, 1),
        amount: 12,
        unit: 'racimo',
        equivalentKg: 240,
      ),
    ];

    test('12 racimos con 240 kg suman 240 kg, no 12', () {
      final total = metrics.totalsByCrop(racimos, crops).single;
      expect(total.amount, 12, reason: 'la cantidad sigue siendo 12 racimos');
      expect(total.kg, 240, reason: 'los kilos son los del peso anotado');
    });

    test('10 cajones con 200 kg suman 200 kg', () {
      final total = metrics
          .totalsByCrop([
            _h(
              id: 'h2',
              cropId: 'cafe',
              date: DateTime(2026, 5, 1),
              amount: 10,
              unit: 'cajon',
              equivalentKg: 200,
            ),
          ], crops)
          .single;
      expect(total.kg, 200);
    });

    test('sin peso no suma kilos ni inventa 1 por unidad', () {
      final total = metrics
          .totalsByCrop([
            _h(
              id: 'h3',
              cropId: 'platano',
              date: DateTime(2026, 5, 1),
              amount: 12,
              unit: 'racimo',
            ),
          ], crops)
          .single;
      expect(total.amount, 12);
      expect(total.kg, 0, reason: 'sin peso no hay kilos que sumar');
    });

    test('kg/ha y kg/planta usan el peso real', () {
      expect(metrics.yieldPerArea(racimos, 2), 120);
      expect(metrics.yieldPerPlant(racimos, 100), 2.4);
    });

    test('el costo por kilo se calcula sobre los kilos reales', () {
      expect(
        metrics.periodCostPerKg(100000, racimos),
        closeTo(100000 / 240, 0.01),
      );
    });
  });

  group('Tanda 4 · registros sin peso', () {
    test('una cosecha en racimo sin peso se lista; con peso, no', () {
      final rows = [
        _h(
          id: 'h1',
          cropId: 'platano',
          date: DateTime(2026, 5, 1),
          amount: 12,
          unit: 'racimo',
        ),
        _h(
          id: 'h2',
          cropId: 'platano',
          date: DateTime(2026, 5, 2),
          amount: 10,
          unit: 'racimo',
          equivalentKg: 200,
        ),
        _h(
          id: 'h3',
          cropId: 'cafe',
          date: DateTime(2026, 5, 3),
          amount: 5,
          unit: 'kg',
        ),
      ];
      expect(pendingWeightHarvests(rows).map((h) => h.id), ['h1'],
          reason: 'solo la que no tiene peso: las demás ya suman kilos');
    });

    test('una venta en cajón sin peso se lista; con peso, gasto o borrada, no',
        () {
      final rows = [
        _sale(id: 't1', amount: 1, quantity: 10, unit: 'cajon'),
        _sale(
          id: 't2',
          amount: 1,
          quantity: 10,
          unit: 'cajon',
          equivalentKg: 200,
        ),
        _sale(
          id: 't3',
          amount: 1,
          quantity: 10,
          unit: 'cajon',
          type: TransactionType.expense,
        ),
        _sale(
          id: 't4',
          amount: 1,
          quantity: 10,
          unit: 'cajon',
          deleted: true,
        ),
        _sale(id: 't5', amount: 1, quantity: 10),
      ];
      expect(pendingWeightSales(rows).map((t) => t.id), ['t1']);
    });

    test('con todo completo no queda nada pendiente', () {
      expect(
        pendingWeightHarvests([
          _h(
            id: 'h1',
            cropId: 'platano',
            date: DateTime(2026, 5, 1),
            amount: 12,
            unit: 'racimo',
            equivalentKg: 240,
          ),
        ]),
        isEmpty,
      );
      expect(
        pendingWeightSales([
          _sale(
            id: 't1',
            amount: 1,
            quantity: 10,
            unit: 'cajon',
            equivalentKg: 200,
          ),
        ]),
        isEmpty,
      );
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