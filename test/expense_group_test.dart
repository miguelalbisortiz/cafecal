import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/categories.dart';

/// P5 — los gastos del estado de resultados se agrupan en bloques
/// (producción / venta / fijos / otros) para responder "¿cuánto me costó
/// producir?" sin sumar a mano las 16 categorías.
void main() {
  group('expenseGroupOf (P5)', () {
    test('ninguna categoría conocida cae en "otros"', () {
      for (final c in expenseCategories) {
        if (c.key == 'otro') continue;
        expect(
          expenseGroupOf(c.key),
          isNot(ExpenseGroup.otros),
          reason: 'la categoría "${c.key}" no tiene grupo asignado: añádela '
              'a _productionKeys, _sellingKeys o _fixedKeys en '
              'lib/models/categories.dart',
        );
      }
    });

    test('producción = lo que hace crecer el cultivo', () {
      const keys = [
        'siembra',
        'semillas_insumos',
        'fertilizante',
        'mano_obra',
        'cosecha',
        'plagas',
        'riego',
      ];
      for (final k in keys) {
        expect(expenseGroupOf(k), ExpenseGroup.produccion, reason: k);
      }
    });

    test('venta = sacar el producto al mercado', () {
      for (final k in ['empaque', 'transporte']) {
        expect(expenseGroupOf(k), ExpenseGroup.venta, reason: k);
      }
    });

    test('fijos = no dependen de tener cosecha este mes', () {
      const keys = [
        'arriendo',
        'energia',
        'agua',
        'equipo',
        'mantenimiento',
        'impuestos',
      ];
      for (final k in keys) {
        expect(expenseGroupOf(k), ExpenseGroup.fijos, reason: k);
      }
    });

    test('"otro" y cualquier clave legada van a Otros: nada desaparece', () {
      expect(expenseGroupOf('otro'), ExpenseGroup.otros);
      expect(expenseGroupOf('categoria_inventada'), ExpenseGroup.otros);
      expect(expenseGroupOf(''), ExpenseGroup.otros);
    });
  });
}
