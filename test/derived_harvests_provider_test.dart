import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/derived_harvests.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Fase 2** — la frontera entre los dos getters de cosecha.
///
/// * `harvests` = guardadas **+** deducidas de la venta → lo leen reportes,
///   alertas, la ficha del cultivo y el PDF/Excel.
/// * `storedHarvests` = solo lo guardado → lo leen el **sync** y el
///   **respaldo**.
///
/// Si un día un derivado se cuela en `storedHarvests`, la app empieza a
/// publicar un **cálculo** como si fuera dato, y el siguiente pull puede
/// revivirlo como zombi. Estos tests son los que impiden eso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<Transaction> vender(
    TransactionProvider p,
    String cropId, {
    double kg = 50,
  }) =>
      p.addTransaction(
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 150000,
        cropId: cropId,
        quantity: kg,
        unit: 'kg',
        date: DateTime(2026, 10, 15),
      );

  final dia = DateTime(2026, 10, 1);

  group('Fase 2 · el getter sabe más que el disco', () {
    test('una venta con cultivo y kilos aparece como cosecha', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);

      expect(p.harvests, hasLength(1));
      final h = p.harvests.single;
      expect(h.cropId, crop.id);
      expect(h.amount, 50);
      expect(h.unit, 'kg');
      expect(h.destination, HarvestDestination.vendido);

      expect(p.storedHarvests, isEmpty,
          reason: 'en disco no apareció nada nuevo: se calculó al leer');
    });

    test('una venta sin cultivo no aparece', () async {
      final p = await build();
      await p.addTransaction(
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 150000,
        quantity: 50,
        unit: 'kg',
        date: DateTime(2026, 10, 15),
        // Sin cultivo: no hay a quién atribuir los kilos.
      );

      expect(p.harvests, isEmpty);
      expect(p.storedHarvests, isEmpty);
    });

    test('una cosecha guardada manda: no se duplica encima (D2)', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final guardada =
          await p.addHarvest(cropId: crop.id, date: dia, amount: 40);
      await vender(p, crop.id);

      expect(p.harvests, hasLength(1),
          reason: 'ella ya midió; derivar encima doble-contaría los kilos');
      expect(p.harvests.single.id, guardada.id);
      expect(p.storedHarvests, hasLength(1));
    });

    test('cada cultivo se decide por su cuenta', () async {
      final p = await build();
      final cafe = await p.addCrop('Café');
      final platano = await p.addCrop('Plátano');
      await p.addHarvest(cropId: cafe.id, date: dia, amount: 40);
      await vender(p, cafe.id);
      await vender(p, platano.id);

      expect(p.harvests, hasLength(2), reason: 'la manual + la de plátano');
      expect(
        p.harvests.where((h) => h.cropId == cafe.id).single.id,
        isNot(startsWith(kSaleDerivedPrefix)),
        reason: 'plátano no tiene nada anotado, ese sí se deduce',
      );
      expect(
        p.harvests.where((h) => h.cropId == platano.id).single.id,
        startsWith(kSaleDerivedPrefix),
      );
    });

    test('harvestsFor —vincular un gasto— no se llena de derivadas', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);

      expect(p.harvests, hasLength(1));
      expect(p.harvestsFor(crop.id), isEmpty,
          reason: 'enlazar un gasto es de lo anotado a mano: una derivada no '
              'es un destino visible, y su enlace moriría con la venta');
    });
  });

  group('Fase 2 · no se sube ni se respalda', () {
    test('la cola de subida solo ve cosechas guardadas', () async {
      final p = await build();
      final cafe = await p.addCrop('Café');
      final platano = await p.addCrop('Plátano');
      final guardada =
          await p.addHarvest(cropId: cafe.id, date: dia, amount: 40);
      await vender(p, platano.id);

      // El sync hace exactamente esto.
      final cola = p.storedHarvests.where((h) => h.pendingSync).toList();

      expect(cola, hasLength(1), reason: 'la derivada nunca entra en la cola');
      expect(cola.single.id, guardada.id);
      expect(p.harvests, hasLength(2),
          reason: 'pero las dos existen para quien las lee');
    });

    test('el respaldo JSON incluye la guardada y deja fuera la derivada',
        () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final guardada =
          await p.addHarvest(cropId: crop.id, date: dia, amount: 40);
      await vender(p, crop.id);

      final json = p.exportBackupJson();

      expect(json, contains(guardada.id),
          reason: 'lo anotado a mano sí es suyo y se respalda');
      expect(json, isNot(contains(kSaleDerivedPrefix)),
          reason: 'subir un cálculo sería publicarlo como si fuera dato');
    });

    test('las derivadas salen marcadas para no subir, por si acaso', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);

      expect(p.harvests, hasLength(1));
      expect(p.harvests.single.pendingSync, isFalse);
    });
  });

  group('Fase 2 · se arregla al leer (D1)', () {
    test('borrar la venta apaga la cosecha', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final venta = await vender(p, crop.id);
      expect(p.harvests, hasLength(1));

      await p.deleteTransaction(venta.id);

      expect(p.harvests, isEmpty,
          reason: 'no hay nada que borrar: dejó de calcularse');
      expect(p.storedHarvests, isEmpty);
    });

    test('corregir los kilos de la venta corrige la cosecha', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);
      expect(p.harvests.single.amount, 50);

      await p.updateTransaction(p.transactions.single.copyWith(quantity: 80.0));

      expect(p.harvests.single.amount, 80.0,
          reason: 'el dato cuelga de la venta, no de una copia vieja');
    });

    test('borrar el cultivo también la apaga', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);
      expect(p.harvests, hasLength(1));

      await p.deleteCrop(crop.id);

      expect(p.harvests, isEmpty,
          reason: 'deleteCrop anula el cultivo de los movimientos');
    });

    test('recargar la app no las trae del disco: las vuelve a calcular',
        () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);
      expect(p.harvests, hasLength(1));

      await p.reloadFromCache();

      expect(p.harvests, hasLength(1), reason: 'mismo número, otro origen');
      expect(p.storedHarvests, isEmpty);
      expect(p.harvests.single.pendingSync, isFalse,
          reason: 'y sigue sin querer subirse');
    });
  });

  group('Tanda 2 · el jornal medido', () {
    Future<Transaction> jornal(
      TransactionProvider p,
      String cropId, {
      double kg = 120,
      String task = kTaskCosechar,
      DateTime? date,
    }) =>
        p.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100000,
          cropId: cropId,
          quantity: 2,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan',
          task: task,
          harvestedKg: kg,
          date: date ?? DateTime(2026, 10, 19),
        );

    test('addTransaction conserva los kilos y harvests deriva la cosecha',
        () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, crop.id);

      expect(j.harvestedKg, 120);
      expect(p.harvests, hasLength(1));
      final h = p.harvests.single;
      expect(h.id, 'der_jornal_${j.id}');
      expect(h.cropId, crop.id);
      expect(h.amount, 120);
      expect(h.unit, 'kg');
      expect(h.destination, HarvestDestination.vendido);
    });

    test('storedHarvests sigue conteniendo solo lo guardado', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await jornal(p, crop.id);

      expect(p.harvests, hasLength(1));
      expect(p.storedHarvests, isEmpty,
          reason: 'la del jornal se calcula al leer, no se persiste');
    });

    test('borrar el jornal apaga su cosecha', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, crop.id);

      await p.deleteTransaction(j.id);

      expect(p.harvests, isEmpty);
    });

    test('editar los kilos corrige la cosecha', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, crop.id);

      await p.updateTransaction(j.copyWith(harvestedKg: 200));

      expect(p.harvests.single.amount, 200);
    });

    test('cambiar la labor y limpiar los kilos apaga la cosecha', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final j = await jornal(p, crop.id);

      await p.updateTransaction(j.copyWith(task: 'abonar', harvestedKg: null));

      expect(p.harvests, isEmpty);
    });

    test('un jornal con kilos de un cultivo borrado no rompe la lectura',
        () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await jornal(p, crop.id);

      await p.deleteCrop(crop.id);

      expect(() => p.harvests, returnsNormally);
      expect(p.harvests, isEmpty,
          reason: 'sin cultivo no hay a quién atribuir la cosecha');
      expect(p.transactions.single.harvestedKg, 120,
          reason: 'el movimiento se queda; solo pierde el cultivo');
    });

    test('varios jornales del mismo cultivo dan una cosecha cada uno', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await jornal(p, crop.id, kg: 500);
      await jornal(p, crop.id, kg: 120, date: DateTime(2026, 10, 20));

      expect(p.harvests, hasLength(2));
      expect(p.harvests.map((h) => h.amount), [500, 120]);
    });
  });
}
