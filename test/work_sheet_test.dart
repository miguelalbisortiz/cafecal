import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/report_payroll_metrics.dart';

/// E3 · la planilla: ¿en qué se gastó la gente?
///
/// Antes la nómina respondía "cuánto por persona", pero no "en qué". Con la
/// labor anotada, la planilla agrupa por (labor, cultivo) — que es como se
/// lee el mes en el papel: "Descolgar café, 4 hombres, 2 días".
///
/// Y sobre todo: **los jornales sin labor no se descartan**. Si se los
/// tirara, la planilla dejaría de cuadrar con el presupuesto de obra y
/// mentiría sobre cuánto se gastó.

Transaction _jornal({
  required double days,
  required double rate,
  String? task,
  String? cropId,
  String provider = 'Juan',
  String category = 'mano_obra',
  DateTime? date,
  bool deleted = false,
}) =>
    Transaction(
      id: 'j_${task ?? 'x'}_${cropId ?? 'y'}_${provider}_${days}_$rate',
      cropId: cropId,
      type: TransactionType.expense,
      category: category,
      amount: days * rate,
      quantity: days,
      unit: 'día',
      pricePerUnit: rate,
      provider: provider,
      task: task,
      date: date ?? DateTime(2026, 10, 14),
      createdAt: DateTime(2026, 10, 14),
      deleted: deleted,
    );

void main() {
  const cropNames = {'cafe': 'Café', 'platano': 'Plátano'};

  List<WorkSheetRow> rowsOf(List<Transaction> txns,
          {String unlabeled = 'Sin labor'}) =>
      const ReportPayrollMetrics().workSheetRows(
        periodTx: txns,
        cropNames: cropNames,
        unlabeledTaskName: unlabeled,
      );

  group('La lista de labores (E3)', () {
    test('está cerrada y "Otra…" es la válvula de escape', () {
      // Texto libre no se puede agrupar: "Descolgar café" y "descolgar"
      // serían dos renglones y la planilla dejaría de servir para leer.
      expect(farmTasks.map((t) => t.key).toSet().length, farmTasks.length,
          reason: 'sin teclas repetidas');
      expect(farmTasks.any((t) => t.key == kTaskOther), isTrue);

      for (final t in farmTasks) {
        expect(taskByKey(t.key), isNotNull);
        expect(taskLabel(t.key), t.name);
        expect(taskIcon(t.key), t.icon);
      }
    });

    test('lo que no está en la lista se muestra tal cual, sin romper nada', () {
      expect(taskByKey('desbrotar'), isNull);
      expect(isFreeTask('desbrotar'), isTrue);
      expect(taskLabel('desbrotar'), 'desbrotar',
          reason: 'el texto del productor manda');
      // El icono de lo libre es el de "Otra…": es lo que es.
      expect(taskIcon('desbrotar'), taskIcon(kTaskOther));
    });

    test('un dato viejo sin labor no revienta', () {
      expect(taskByKey(null), isNull);
      expect(isFreeTask(null), isFalse);
      expect(taskLabel(null), '');
      expect(taskIcon(null), taskIcon(kTaskOther));
    });

    test('los trabajos que la app ya reconocía por su categoría se anotan',
        () {
      // Cinco categorías de gasto decían "esto existe", pero no había forma
      // de anotar la labor que las produjo: el jornal quedaba en "Sin labor"
      // y la planilla no decía de qué era.
      const categoriaALabor = {
        'siembra': 'sembrar',
        'riego': 'regar',
        'empaque': 'empacar',
        'transporte': 'transportar',
        'mantenimiento': 'reparar',
      };
      for (final e in categoriaALabor.entries) {
        expect(expenseCategories.any((c) => c.key == e.key), isTrue,
            reason: 'sigue existiendo la categoría ${e.key}');
        expect(taskByKey(e.value), isNotNull,
            reason: 'falta la labor que corresponde a ${e.key}');
      }

      // Las nuevas quedan antes de "Otra…", que siempre cierra la lista,
      // y el orden relativo de las que ya estaban no se mueve.
      final otra = farmTasks.indexWhere((t) => t.key == kTaskOther);
      expect(otra, greaterThan(0));
      for (final k in categoriaALabor.values) {
        expect(farmTasks.indexWhere((t) => t.key == k), lessThan(otra),
            reason: '$k debe aparecer antes de Otra…');
      }
      final antes = ['descolgar', 'abonar', 'cosechar', 'deshierbar', 'aplicar'];
      final posiciones = [
        for (final k in antes) farmTasks.indexWhere((t) => t.key == k)
      ];
      expect(posiciones, List<int>.from(posiciones)..sort(),
          reason: 'las labores originales conservan su orden');
    });

    test('ninguna labor repite el icono de una categoría de gasto', () {
      // Un glifo compartido hace que "Cosechar" y "Cosecha y recolección"
      // parezcan la misma cosa justo donde se eligen, y la tarjeta de
      // nómina pinta la labor mientras el estado de resultados pinta la
      // categoría con el mismo dibujito.
      final deCategorias = {for (final c in expenseCategories) c.icon};
      for (final t in farmTasks) {
        expect(deCategorias.contains(t.icon), isFalse,
            reason: '"${t.name}" comparte icono con una categoría');
      }
      expect(farmTasks.map((t) => t.icon).toSet().length, farmTasks.length,
          reason: 'dos labores tampoco pueden compartir glifo');
    });
  });

  group('La planilla agrupa por labor y cultivo', () {
    test('una labor en dos personas suma días y dinero', () {
      final rows = rowsOf([
        _jornal(task: 'descolgar', cropId: 'cafe', days: 2, rate: 50000),
        _jornal(
            task: 'descolgar',
            cropId: 'cafe',
            days: 2,
            rate: 50000,
            provider: 'María'),
      ]);

      expect(rows, hasLength(1));
      expect(taskLabel(rows.first.task), 'Descolgar');
      expect(rows.first.cropName, 'Café');
      expect(rows.first.workers, 2, reason: 'dos personas distintas');
      expect(rows.first.days, 4, reason: '2 + 2 día-persona');
      expect(rows.first.total, 200000);
    });

    test('la misma labor en dos cultivos son dos renglones', () {
      final rows = rowsOf([
        _jornal(task: 'abonar', cropId: 'cafe', days: 1, rate: 50000),
        _jornal(task: 'abonar', cropId: 'platano', days: 1, rate: 40000),
      ]);

      expect(rows, hasLength(2));
      expect(rows.map((r) => r.cropName).toSet(), {'Café', 'Plátano'});
    });

    test('dos labores en el mismo cultivo son dos renglones', () {
      final rows = rowsOf([
        _jornal(task: 'descolgar', cropId: 'cafe', days: 1, rate: 50000),
        _jornal(task: 'abonar', cropId: 'cafe', days: 1, rate: 50000),
      ]);

      expect(rows, hasLength(2));
    });

    test('sale en el orden en que se trabaja, no por monto', () {
      final rows = rowsOf([
        // Abonar (2º de la lista) más caro que descolgar (1º): si se
        // ordenara por plata, saldría al revés de como se trabaja.
        _jornal(task: 'abonar', cropId: 'cafe', days: 9, rate: 90000),
        _jornal(task: 'descolgar', cropId: 'cafe', days: 1, rate: 50000),
      ]);

      expect(taskLabel(rows.first.task), 'Descolgar');
      expect(taskLabel(rows.last.task), 'Abonar');
    });

    test('el texto libre va al final y agrupa con lo idéntico', () {
      final rows = rowsOf([
        _jornal(task: 'desbrotar a mano', cropId: 'cafe', days: 1, rate: 1),
        _jornal(task: 'desbrotar a mano', cropId: 'cafe', days: 1, rate: 1),
        _jornal(task: 'descolgar', cropId: 'cafe', days: 1, rate: 1),
      ]);

      expect(rows, hasLength(2),
          reason: 'lo libre agrupa solo con lo idéntico');
      expect(rows.first.task, 'descolgar');
      expect(rows.last.task, 'desbrotar a mano');
      expect(isFreeTask(rows.last.task), isTrue);
    });
  });

  group('Los jornales sin labor no se pierden', () {
    test('salen agrupados bajo la leyenda, con su dinero', () {
      final rows = rowsOf([
        _jornal(task: 'descolgar', cropId: 'cafe', days: 2, rate: 50000),
        // Jornal viejo, anterior a E3: sin labor.
        _jornal(cropId: 'cafe', days: 1, rate: 50000, provider: 'Pedro'),
      ]);

      expect(rows, hasLength(2));
      final unlabeled = rows.firstWhere((r) => r.task == 'Sin labor');
      expect(unlabeled.days, 1);
      expect(unlabeled.total, 50000,
          reason: 'si se lo tirara, el total dejaría de cuadrar con la obra');
    });

    test('la leyenda vacía deja la labor en null, no inventa texto', () {
      final rows = const ReportPayrollMetrics().workSheetRows(
        periodTx: [_jornal(days: 1, rate: 50000)],
        cropNames: cropNames,
        unlabeledTaskName: '',
      );

      expect(rows.single.task, isNull);
    });

    test('mano de obra sin cantidad cuenta con 0 días pero su monto entra', () {
      final rows = rowsOf([
        _jornal(task: 'abonar', cropId: 'cafe', days: 0, rate: 0)
            .copyWith(amount: 70000, quantity: null),
      ]);

      expect(rows.single.days, 0);
      expect(rows.single.total, 70000,
          reason: 'el dinero se gastó, aunque no se anotaron los días');
    });

    test('otros gastos y los borrados quedan afuera', () {
      final rows = rowsOf([
        _jornal(task: 'abonar', cropId: 'cafe', days: 1, rate: 50000),
        _jornal(
            task: 'abonar',
            cropId: 'cafe',
            days: 1,
            rate: 50000,
            category: 'fertilizante'),
        _jornal(
            task: 'abonar',
            cropId: 'cafe',
            days: 1,
            rate: 50000,
            deleted: true),
      ]);

      expect(rows, hasLength(1));
      expect(rows.single.total, 50000);
    });
  });

  group('La labor viaja en la transacción', () {
    test('toJson/fromJson conservan la tecla y el texto libre', () {
      final keyed = _jornal(task: 'descolgar', days: 1, rate: 1);
      expect(keyed.toJson()['task'], 'descolgar');
      expect(Transaction.fromJson(keyed.toJson()).task, 'descolgar');

      final free = _jornal(task: 'desbrotar a mano', days: 1, rate: 1);
      expect(Transaction.fromJson(free.toJson()).task, 'desbrotar a mano');
    });

    test('un respaldo anterior a E3 nace sin labor', () {
      final map = Map<String, dynamic>.from(_jornal(days: 1, rate: 1).toJson())
        ..remove('task');

      expect(Transaction.fromJson(map).task, isNull,
          reason: 'dato viejo: sin labor, y la planilla lo dice explícito');
    });

    test('copyWith puede QUITAR la labor', () {
      final t = _jornal(task: 'descolgar', days: 1, rate: 1);

      // Sentinela: sin ella, `copyWith(task: null)` se leería como
      // "conserva el anterior" y no habría forma de deshacer una labor.
      expect(t.copyWith(task: null).task, isNull);
      expect(t.task, 'descolgar', reason: 'limpiar uno no toca el original');
      expect(t.copyWith(task: 'abonar').task, 'abonar');
    });
  });
}
