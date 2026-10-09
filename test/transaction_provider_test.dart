import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Transaction cuenta gastos e ingresos del año', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final provider = TransactionProvider(store);

    final expense = Transaction(
      id: 't1',
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 100,
      date: DateTime(2026, 3, 1),
      createdAt: DateTime(2026, 3, 1),
    );
    final income = Transaction(
      id: 't2',
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 300,
      date: DateTime(2026, 10, 15),
      createdAt: DateTime(2026, 10, 15),
    );

    await provider.addTransaction(
      type: expense.type,
      category: expense.category,
      amount: expense.amount,
      date: expense.date,
    );
    await provider.addTransaction(
      type: income.type,
      category: income.category,
      amount: income.amount,
      date: income.date,
    );

    expect(provider.totalExpenses(year: 2026), 100);
    expect(provider.totalIncomes(year: 2026), 300);
    expect(provider.totalExpenses(year: 2025), 0);
  });

  test('delete marca la transacción y excluye del total', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final provider = TransactionProvider(store);

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'riego',
      amount: 50,
      date: DateTime(2026, 2, 1),
    );

    final id = provider.transactions.first.id;
    expect(provider.totalExpenses(year: 2026), 50);

    await provider.deleteTransaction(id);
    expect(provider.totalExpenses(year: 2026), 0);
    expect(provider.transactions.first.deleted, isTrue);
  });

  group('Crops — el pull deduplica por id, nunca por nombre', () {
    test('dos cultivos distintos que se llaman igual conviven', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));

      // Antes el remoto se descartaba por nombre y sus siembras, cosechas y
      // ventas quedaban sin cultivo.
      provider.mergeRemoteCrops(const [
        Crop(id: 'uuid-cafe-a', name: 'Café'),
        Crop(id: 'uuid-cafe-b', name: 'Café'),
      ]);

      expect(provider.crops.map((c) => c.id).toList(),
          ['uuid-cafe-a', 'uuid-cafe-b']);
    });

    test('el mismo cultivo solo entra una vez por id', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));

      provider.mergeRemoteCrops(const [Crop(id: 'uuid-cafe', name: 'Café')]);
      provider.mergeRemoteCrops(const [Crop(id: 'uuid-cafe', name: 'Café')]);

      expect(provider.crops, hasLength(1));
    });

    test('un cultivo borrado no revive mientras no se borre en la BD',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));
      final crop = await provider.addCrop('Café');

      await provider.deleteCrop(crop.id);
      expect(provider.deletedCrops, contains(crop.id));

      provider.mergeRemoteCrops([Crop(id: crop.id, name: 'Café')]);

      expect(provider.crops, isEmpty);
      expect(provider.deletedCrops, contains(crop.id));
    });

    test('borrar un cultivo deja sus movimientos sin cultivo', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));
      final crop = await provider.addCrop('Café');
      await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 100,
        cropId: crop.id,
      );

      await provider.deleteCrop(crop.id);

      // copyWith(cropId: null) no limpiaba el id: al subirlo, la BD rechazaba
      // el movimiento por apuntar a un cultivo ya borrado.
      expect(provider.transactions.single.cropId, isNull);
      expect(provider.transactions.single.pendingSync, isTrue);
    });

    test('borrar un cultivo desvincula también cosechas y siembras', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));
      final crop = await provider.addCrop('Café');
      final sowing = await provider.addSowing(
          cropId: crop.id, date: DateTime(2026, 1, 1), plants: 100);
      final harvest = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 9, 1), amount: 50);
      await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 100,
        cropId: crop.id,
        harvestId: harvest.id,
        sowingId: sowing.id,
      );

      await provider.deleteCrop(crop.id);

      final t = provider.transactions.single;
      expect(t.cropId, isNull);
      expect(t.harvestId, isNull,
          reason: 'harvest_id viaja en el payload y la fila ya no existe');
      expect(t.sowingId, isNull,
          reason: 'sowing_id viaja en el payload y la fila ya no existe');
      expect(t.pendingSync, isTrue);
    });

    test('markAllSynced olvida los borrados subidos y conserva los fallidos',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));
      final crop = await provider.addCrop('Café');
      await provider.deleteCrop(crop.id);

      await provider.markAllSynced(skip: {crop.id}); // falló: sigue pendiente
      expect(provider.deletedCrops, contains(crop.id));

      await provider.markAllSynced(); // llegó: ya se puede olvidar
      expect(provider.deletedCrops, isEmpty);
    });

    test('un cultivo legado adopta el id remoto y sus datos lo siguen',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      // Los cultivos por defecto antiguos vivían con id fijo 'cafe'.
      await store.saveCrops(const [Crop(id: 'cafe', name: 'Café')]);
      final provider = TransactionProvider(store);

      await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 100,
        cropId: 'cafe',
      );
      await provider.addSowing(
          cropId: 'cafe', date: DateTime(2026, 1, 1), plants: 100);
      await provider.addHarvest(
          cropId: 'cafe', date: DateTime(2026, 9, 1), amount: 50);

      provider.mergeRemoteCrops(const [Crop(id: 'uuid-cafe', name: 'Café')]);

      expect(provider.crops.map((c) => c.id).toList(), ['uuid-cafe'],
          reason: 'el local con id legado se sustituye, no conviven');
      expect(provider.transactions.single.cropId, 'uuid-cafe');
      expect(provider.sowings.single.cropId, 'uuid-cafe');
      expect(provider.harvests.single.cropId, 'uuid-cafe');
      expect(provider.transactions.single.pendingSync, isTrue,
          reason: 'hay que re-subirlo con el id bueno');
    });

    test('addCrop acepta el formulario completo en una sola escritura',
        () async {
      // C5: antes la pantalla de Cultivos tenía que hacer addCrop +
      // updateCrop para guardar lo que addCrop no aceptaba.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = TransactionProvider(LocalStore(prefs));

      final crop = await provider.addCrop(
        'Café',
        currency: 'USD',
        phase: CropPhase.establecimiento,
        cycle: CropCycle.perenne,
        defaultUnit: 'saco',
        areaHa: 1.5,
        livePlants: 1200,
        establishmentCost: 2500000,
      );

      expect(crop.phase, CropPhase.establecimiento);
      expect(crop.cycle, CropCycle.perenne);
      expect(crop.defaultUnit, 'saco');
      expect(crop.areaHa, 1.5);
      expect(crop.livePlants, 1200);
      expect(crop.establishmentCost, 2500000);
      expect(crop.currency, 'USD');
      expect(crop.pendingSync, isTrue,
          reason: 'debe quedar marcado para subir a Supabase');

      expect(provider.crops.single.areaHa, 1.5);
      expect(provider.crops.single.currency, 'USD');
    });

    test('loadCrops deduplica registros con el mismo id', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.crops_v1': '['
            '{"id":"cafe","name":"Café","phase":"produccion","cycle":"perenne"},'
            '{"id":"cafe","name":"Café repetido","phase":"produccion","cycle":"perenne"}'
            ']',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      expect(store.loadCrops().length, 1);
      expect(store.loadCrops().single.id, 'cafe');
    });

    test('loadCrops conserva dos cultivos distintos aunque se llamen igual',
        () async {
      // C4: deduplicar por nombre borraba uno y dejaba sus siembras y
      // cosechas huérfanas.
      SharedPreferences.setMockInitialValues({
        'flutter.crops_v1': '['
            '{"id":"cafe-1","name":"Café","phase":"produccion","cycle":"perenne"},'
            '{"id":"cafe-2","name":"Café","phase":"produccion","cycle":"perenne"}'
            ']',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      expect(store.loadCrops().map((c) => c.id).toList(),
          ['cafe-1', 'cafe-2']);
    });
  });

  group('P3 — fase automática', () {
    Future<TransactionProvider> newProvider() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return TransactionProvider(LocalStore(prefs));
    }

    test('addCrop arranca en establecimiento: todavía no se produce', () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      expect(crop.phase, CropPhase.establecimiento);
      expect(provider.crops.single.phase, CropPhase.establecimiento);
    });

    test('addCrop respeta la fase que pide el formulario completo',
        () async {
      // La pantalla de Cultivos sigue decidiendo la fase a mano.
      final provider = await newProvider();
      expect(
          (await provider.addCrop('Maíz', phase: CropPhase.produccion)).phase,
          CropPhase.produccion);
      expect(
          (await provider.addCrop('Vid', phase: CropPhase.renovacion)).phase,
          CropPhase.renovacion);
    });

    test('la primera cosecha promueve establecimiento → producción',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      expect(crop.phase, CropPhase.establecimiento);

      await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 50);

      expect(provider.crops.single.phase, CropPhase.produccion);
      expect(provider.crops.single.pendingSync, isTrue,
          reason: 'hay que avisar a Supabase del cambio de fase');
      expect(provider.harvests, hasLength(1));
    });

    test('promover es idempotente: la segunda cosecha no vuelve a tocarlo',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 50);
      final afterFirst = provider.crops.single;

      await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 11, 1), amount: 30);

      expect(provider.crops.single.phase, CropPhase.produccion);
      expect(provider.crops.single.pendingSync, afterFirst.pendingSync);
    });

    test('una cosecha no altera renovación ni producción', () async {
      final provider = await newProvider();
      final renov = await provider.addCrop('Vid', phase: CropPhase.renovacion);
      final prod = await provider.addCrop('Maíz', phase: CropPhase.produccion);

      await provider.addHarvest(
          cropId: renov.id, date: DateTime(2026, 10, 1), amount: 10);
      await provider.addHarvest(
          cropId: prod.id, date: DateTime(2026, 10, 1), amount: 10);

      expect(phaseOf(provider, renov.id), CropPhase.renovacion);
      expect(phaseOf(provider, prod.id), CropPhase.produccion);
    });

    test('una cosecha sin cultivo no se cuelga', () async {
      final provider = await newProvider();
      await provider.addCrop('Café');
      await provider.addHarvest(cropId: null, date: DateTime(2026, 10, 1),
          amount: 10);
      // Ninguna fase cambió porque ninguna cosecha estaba vinculada.
      expect(provider.crops.single.phase, CropPhase.establecimiento);
    });
  });

  group('F1 — venta ligada a la cosecha', () {
    Future<TransactionProvider> newProvider() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return TransactionProvider(LocalStore(prefs));
    }

    /// Venta viva ligada a esa cosecha (null si no hay).
    Transaction? saleOf(TransactionProvider p, String harvestId) {
      for (final t in p.transactions) {
        if (!t.deleted &&
            t.type == TransactionType.income &&
            t.harvestId == harvestId) {
          return t;
        }
      }
      return null;
    }

    List<Transaction> salesOf(TransactionProvider p) =>
        p.transactions.where((t) => !t.deleted && t.type == TransactionType.income).toList();

    test('con precio y destino vendido crea la venta (cantidad × precio)',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id,
          date: DateTime(2026, 10, 1),
          amount: 8,
          unit: 'saco');

      final sale =
          await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 300000);

      expect(sale, isNotNull);
      expect(sale!.amount, 2400000);
      expect(sale.type, TransactionType.income);
      expect(sale.category, kIncomeCategorySale);
      expect(sale.harvestId, h.id);
      expect(sale.cropId, crop.id);
      expect(sale.date, h.date);
      // quantity/unit/pricePerUnit es lo que el precio por kilo y la alerta
      // de "ventas sin kilos" necesitan encontrar.
      expect(sale.quantity, 8);
      expect(sale.unit, 'saco');
      expect(sale.pricePerUnit, 300000);
      expect(provider.totalIncomes(year: 2026), 2400000);
    });

    test('sin precio no se inventa la venta', () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);

      expect(await provider.reconcileHarvestSale(harvest: h), isNull);
      expect(salesOf(provider), isEmpty);
      expect(provider.totalIncomes(year: 2026), 0);
    });

    test('cambiar el precio actualiza la venta en vez de crear otra',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);

      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 300000);
      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 500000);

      expect(salesOf(provider), hasLength(1));
      expect(saleOf(provider, h.id)!.amount, 4000000);
      expect(provider.totalIncomes(year: 2026), 4000000);
    });

    test('editar la cantidad de la cosecha recalcula el importe de la venta',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);
      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 300000);

      final mas = h.copyWith(amount: 10);
      await provider.reconcileHarvestSale(harvest: mas, pricePerUnit: 300000);

      expect(salesOf(provider), hasLength(1));
      expect(saleOf(provider, h.id)!.amount, 3000000);
      expect(saleOf(provider, h.id)!.quantity, 10);
    });

    test('destino pérdida borra la venta ligada: no se vende una pérdida',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);
      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 300000);
      expect(salesOf(provider), hasLength(1));

      await provider.reconcileHarvestSale(
          harvest: h.copyWith(destination: HarvestDestination.perdida),
          pricePerUnit: 300000);

      expect(salesOf(provider), isEmpty);
      expect(provider.totalIncomes(year: 2026), 0);
    });

    test('quitar el precio no borra una venta que ya existía', () async {
      // Sacar dinero de los libros por editar un campo sería peor que
      // dejarlo: la plata sí se cobró.
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);
      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 300000);

      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: null);

      expect(salesOf(provider), hasLength(1));
      expect(provider.totalIncomes(year: 2026), 2400000);
    });

    test('la venta hereda la moneda del cultivo', () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café', currency: 'USD');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);

      final sale =
          await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 10);

      expect(sale!.currency, 'USD');
    });

    test('B1: borrar la cosecha borra la venta que creó la app', () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);
      await provider.reconcileHarvestSale(harvest: h, pricePerUnit: 300000);
      expect(salesOf(provider), hasLength(1));

      await provider.deleteHarvest(h.id);

      expect(salesOf(provider), isEmpty);
      expect(provider.totalIncomes(year: 2026), 0);
    });

    test('B1: el gasto de recolección se queda, solo pierde el vínculo',
        () async {
      final provider = await newProvider();
      final crop = await provider.addCrop('Café');
      final h = await provider.addHarvest(
          cropId: crop.id, date: DateTime(2026, 10, 1), amount: 8);
      await provider.addTransaction(
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 50000,
        date: DateTime(2026, 10, 1),
        harvestId: h.id,
      );

      await provider.deleteHarvest(h.id);

      final gastos = provider.transactions
          .where((t) => t.type == TransactionType.expense && !t.deleted)
          .toList();
      expect(gastos, hasLength(1),
          reason: 'esa plata ya salió y sigue siendo cierta');
      expect(gastos.first.harvestId, isNull,
          reason: 'B4: solo pierde el vínculo con la cosecha borrada');
      expect(provider.totalExpenses(year: 2026), 50000);
    });
  });
}

CropPhase phaseOf(TransactionProvider provider, String cropId) =>
    provider.crops.firstWhere((c) => c.id == cropId).phase;