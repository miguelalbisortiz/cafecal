import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/services/expense_split.dart';

/// T15 · el reparto de un gasto entre cultivos tiene que sumar el total.
///
/// Si los pedazos suman 99.999, la app estaría perdiendo un peso en el camino,
/// y si suman 100.001, inventando uno. El último hijo absorbe el redondeo.
void main() {
  group('splitAmounts', () {
    test('50/30/20 de 100.000 da tres gastos que suman 100.000', () {
      final amounts = splitAmounts(100000, [50, 30, 20]);
      expect(amounts, [50000, 30000, 20000]);
      expect(amounts!.fold<double>(0, (a, b) => a + b), 100000);
    });

    test('porcentajes con decimales cierran la cuenta exacta', () {
      final amounts = splitAmounts(100000, [33.33, 33.33, 33.34]);
      expect(amounts, [33330, 33330, 33340]);
      expect(amounts!.reduce((a, b) => a + b), closeTo(100000, 0.001));
    });

    test('el redondeo no deja un centavo perdido', () {
      // 10.000 / 3 = 3.333,333… y los porcentajes enteros no lo reparten
      // exacto; el último tiene que cerrar la cuenta.
      final amounts = splitAmounts(10000, [33, 33, 34]);
      expect(amounts!.reduce((a, b) => a + b), closeTo(10000, 0.001));
      expect(amounts.last, 3400);
    });

    test('si no suma 100 no hay reparto', () {
      expect(splitAmounts(100000, [50, 30]), isNull);
      expect(splitAmounts(100000, [50, 30, 21]), isNull);
    });

    test('menos de dos cultivos no es un reparto', () {
      expect(splitAmounts(100000, [100]), isNull);
    });
  });

  group('areaShares', () {
    Crop crop(String id, double? areaHa) =>
        Crop(id: id, name: id, areaHa: areaHa);

    test('reparte por hectáreas', () {
      final shares = areaShares([crop('a', 3), crop('b', 5)]);
      expect(shares.map((s) => s.cropId), ['a', 'b']);
      expect(shares.map((s) => s.percent), [37.5, 62.5]);
      expect(shares.fold<double>(0, (a, s) => a + s.percent), 100);
    });

    test('el último absorbe el remanente del redondeo', () {
      final shares = areaShares([crop('a', 1), crop('b', 1), crop('c', 1)]);
      expect(shares.map((s) => s.percent), [33.33, 33.33, 33.34]);
    });

    test('un cultivo sin área no entra: torcería el reparto', () {
      final shares = areaShares([crop('a', 3), crop('b', 5), crop('c', null)]);
      expect(shares.map((s) => s.cropId), ['a', 'b']);
    });

    test('con un solo cultivo medido no hay atajo', () {
      expect(areaShares([crop('a', 3), crop('b', null)]), isEmpty);
    });

    test('sin áreas no hay nada que proponer', () {
      expect(areaShares([crop('a', null), crop('b', null)]), isEmpty);
    });
  });
}
