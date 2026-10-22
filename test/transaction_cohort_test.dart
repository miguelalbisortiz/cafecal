import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';

/// Etapa B · el puntero al lote (`cohort_sowing_id`) en el modelo.
///
/// La puerta es `Transaction.fromJson`: lo que llega al revés se limpia y se
/// marca sucio, para que la corrección suba. Un puntero a una siembra que no
/// está **no** se limpia aquí: `fromJson` no conoce las siembras.
Transaction _jornal({
  String id = 't1',
  TransactionType type = TransactionType.expense,
  String category = 'mano_obra',
  String? task = kTaskCosechar,
  String? cropId = 'c1',
  String? terrenoId,
  double? harvestedKg = 250,
  String? cohortSowingId = 's1',
}) =>
    Transaction(
      id: id,
      cropId: cropId,
      terrenoId: terrenoId,
      type: type,
      category: category,
      amount: 50000,
      date: DateTime(2026, 3, 12),
      createdAt: DateTime(2026, 3, 12),
      task: task,
      harvestedKg: harvestedKg,
      cohortSowingId: cohortSowingId,
    );

void main() {
  group('Etapa B · modelo', () {
    test('round-trip conserva cohort_sowing_id', () {
      final t = _jornal();
      final vuelta = Transaction.fromJson(t.toJson());
      expect(vuelta.cohortSowingId, 's1');
      expect(t.toJson()['cohort_sowing_id'], 's1');
    });

    test('JSON sin la clave entra null y no marca sucio', () {
      final json = _jornal().toJson()..remove('cohort_sowing_id');
      final t = Transaction.fromJson(json);
      expect(t.cohortSowingId, isNull);
      expect(t.pendingSync, isFalse);
    });

    test('copyWith puede volver el puntero a null y no lo pierde si no se pasa',
        () {
      final t = _jornal();
      expect(t.copyWith(description: 'otra cosa').cohortSowingId, 's1');
      expect(t.copyWith(cohortSowingId: null).cohortSowingId, isNull);
      expect(t.copyWith(cohortSowingId: 's2').cohortSowingId, 's2');
    });

    test('un ingreso con cohort_sowing_id se limpia y queda pendingSync', () {
      final t = Transaction.fromJson(
        _jornal(type: TransactionType.income).toJson(),
      );
      expect(t.cohortSowingId, isNull);
      expect(t.pendingSync, isTrue, reason: 'la corrección tiene que subir');
    });

    test(
        'categoría distinta de mano_obra, labor distinta de cosechar, sin '
        'kilos, sin cultivo o con lote de terreno: el puntero se limpia', () {
      final casos = <String, Transaction>{
        'otra categoría': _jornal(category: 'fertilizante'),
        'otra labor': _jornal(task: 'abonar'),
        'sin labor': _jornal(task: null),
        'kg null': _jornal(harvestedKg: null),
        'kg cero': _jornal(harvestedKg: 0),
        'sin cultivo': _jornal(cropId: null),
        'con terreno': _jornal(terrenoId: 'l1'),
      };
      casos.forEach((nombre, t) {
        final limpio = Transaction.fromJson(t.toJson());
        expect(limpio.cohortSowingId, isNull, reason: nombre);
        expect(limpio.pendingSync, isTrue, reason: nombre);
      });
    });

    test('un puntero a una siembra que no está se conserva (no se limpia)', () {
      final t =
          Transaction.fromJson(_jornal(cohortSowingId: 'no-existe').toJson());
      expect(t.cohortSowingId, 'no-existe');
      expect(t.pendingSync, isFalse,
          reason: 'el pull puede llegar en desorden; la lectura lo ignora');
    });
  });
}
