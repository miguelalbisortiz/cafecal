import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/product_state.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/real_cost_vs_price.dart';

final _hoy = DateTime(2026, 11, 19);
final _dia = DateTime(2026, 10, 1);

Crop _cafe({double? factor = 5, String id = 'cafe', String name = 'Café'}) =>
    Crop(id: id, name: name, icon: '☕', areaHa: 2, threshingYield: factor);

/// 500 kg de cereza con factor 5 → 100 kg vendibles.
Harvest _cosecha({double kg = 500, DateTime? date, String cropId = 'cafe'}) =>
    Harvest(id: 'h-$cropId', cropId: cropId, date: date ?? _dia, amount: kg);

Transaction _gasto(
  double amount, {
  String category = kExpenseCategoryBenefit,
  String cropId = 'cafe',
  DateTime? date,
  String currency = 'COP',
}) =>
    Transaction(
      id: 'g-$amount-$category-$cropId',
      cropId: cropId,
      type: TransactionType.expense,
      category: category,
      amount: amount,
      currency: currency,
      date: date ?? _dia,
      createdAt: date ?? _dia,
    );

Transaction _venta(
  double amount, {
  double? kg = 100,
  ProductState? state = ProductState.pergamino,
  String cropId = 'cafe',
  DateTime? date,
  String currency = 'COP',
}) =>
    Transaction(
      id: 'v-$amount-$cropId-${state?.name ?? 'sin'}',
      cropId: cropId,
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: amount,
      currency: currency,
      quantity: kg,
      unit: 'kg',
      productState: state,
      date: date ?? _dia,
      createdAt: date ?? _dia,
    );

List<RealCostRow> _filas({
  required List<Transaction> tx,
  List<Crop>? crops,
  List<Harvest>? harvests,
}) =>
    realCostWarnings(
      transactions: tx,
      crops: crops ?? [_cafe()],
      harvests: harvests ?? [_cosecha()],
      sacoKg: 70,
      now: _hoy,
    );

void main() {
  group('realCostWarnings', () {
    test('avisa cuando el margen queda por debajo del 10%', () {
      // Costo 570.000 ÷ 100 kg = 5.700 por kg; precio 600.000 ÷ 100 = 6.000.
      final filas = _filas(tx: [_gasto(570000), _venta(600000)]);

      expect(filas.single.costPerKg, 5700);
      expect(filas.single.pricePerKg, 6000);
      expect(filas.single.margin, closeTo(0.05, 1e-9));
      expect(filas.single.state, ProductState.pergamino);
    });

    test('con el 10% justo no avisa', () {
      // 5.400 contra 6.000 es exactamente el 10%: el umbral no se cruza.
      expect(_filas(tx: [_gasto(540000), _venta(600000)]), isEmpty);
    });

    test('con margen cómodo no avisa', () {
      expect(_filas(tx: [_gasto(480000), _venta(600000)]), isEmpty);
    });

    test('el margen negativo se reporta negativo', () {
      final filas = _filas(tx: [_gasto(660000), _venta(600000)]);

      expect(filas.single.costPerKg, 6600);
      expect(filas.single.margin, closeTo(-0.1, 1e-9));
    });

    test('sin factor de trilla no hay costo por kg vendible', () {
      expect(
        _filas(tx: [_gasto(570000), _venta(600000)],
            crops: [_cafe(factor: null)]),
        isEmpty,
        reason: 'sin factor no se inventan kilos vendibles',
      );
    });

    test('sin cosecha en la ventana no hay kilos que repartir', () {
      expect(_filas(tx: [_gasto(570000), _venta(600000)], harvests: []),
          isEmpty);
    });

    test('sin ventas no hay precio logrado', () {
      expect(_filas(tx: [_gasto(570000)]), isEmpty);
    });

    test('una venta sin kilos no entra al promedio', () {
      // Sumar su plata sobre los kilos de las demás inflaría el precio y
      // escondería justo el margen que la regla busca.
      expect(
        _filas(tx: [_gasto(570000), _venta(600000, kg: null)]),
        isEmpty,
      );
    });

    test('no compara un precio en otra moneda que el costo', () {
      expect(
        _filas(tx: [_gasto(570000), _venta(600000, currency: 'USD')]),
        isEmpty,
      );
    });

    test('un estado vendido en dos monedas no tiene precio medio', () {
      expect(
        _filas(tx: [
          _gasto(570000),
          _venta(600000),
          _venta(620, kg: 100, currency: 'USD'),
        ]),
        isEmpty,
      );
    });

    test('cita el estado con peor margen, no el primero', () {
      final filas = _filas(tx: [
        _gasto(570000),
        // Cereza a 1.000 por kg contra un costo de 1.140 en su base → −14%.
        _venta(100000, state: ProductState.cereza),
        // Pergamino: 6.000 contra 5.700 → 5%.
        _venta(600000, state: ProductState.pergamino),
      ]);

      expect(filas.single.state, ProductState.cereza);
      expect(filas.single.costPerKg, 1140);
      expect(filas.single.margin, closeTo(-0.14, 1e-9));
    });

    test('la cereza se mide contra el costo en base cereza', () {
      // 1.300 por kg de cereza contra 1.140 de costo en cereza: 12% de margen.
      // Comparado contra el costo por kilo vendible (5.700) habría salido
      // −338% en toda venta de cereza, sin mirar el precio.
      expect(
        _filas(tx: [
          _gasto(570000),
          _venta(130000, state: ProductState.cereza),
        ]),
        isEmpty,
      );
    });

    test('verde y tueste no se comparan: falta el rendimiento', () {
      // Con un precio altísimo de tueste tampoco avisa, porque no hay
      // conversión anotada y suponerla sería inventar el margen.
      expect(
        _filas(tx: [
          _gasto(570000),
          _venta(2000000, state: ProductState.tueste, kg: 100),
        ]),
        isEmpty,
      );
    });

    test('una sola fila por cultivo aunque venda en varios estados flacos', () {
      final filas = _filas(tx: [
        _gasto(570000),
        // Cereza a 1.100 contra 1.140 de costo → −3,6%.
        _venta(110000, state: ProductState.cereza),
        // Pergamino → 5%.
        _venta(600000, state: ProductState.pergamino),
        // Verde: sin conversión, no entra.
        _venta(560000, state: ProductState.verde),
      ]);

      expect(filas.length, 1);
      expect(filas.single.state, ProductState.cereza);
    });

    test('cada cultivo tiene su propia fila', () {
      final filas = _filas(
        crops: [_cafe(), _cafe(id: 'platano', name: 'Plátano', factor: 2)],
        harvests: [
          _cosecha(),
          _cosecha(kg: 200, cropId: 'platano'),
        ],
        tx: [
          _gasto(570000),
          _venta(600000),
          _gasto(300000, cropId: 'platano'),
          // Plátano: costo en cereza 3.000 ÷ 2 de factor = 1.500; vende a
          // 1.400 → −7%.
          _venta(140000, cropId: 'platano', state: ProductState.cereza),
        ],
      );

      expect(filas.map((f) => f.crop.id), unorderedEquals(['cafe', 'platano']));
    });

    test('el equipo no entra al costo: es inversión, no producción', () {
      final filas = _filas(tx: [
        _gasto(570000),
        _gasto(900000, category: 'equipo'),
        _venta(600000),
      ]);

      expect(filas.single.costPerKg, 5700);
    });

    test('lo de hace más de 12 meses no cuenta', () {
      final viejo = DateTime(2025, 10, 1);
      expect(
        _filas(
          tx: [
            _gasto(570000, date: viejo),
            _venta(600000, date: viejo),
          ],
          harvests: [_cosecha(date: viejo)],
        ),
        isEmpty,
      );
    });
  });

  group('el aviso del motor', () {
    List<FarmAlert> avisos({
      required List<Transaction> tx,
      String locale = 'es',
      List<Harvest>? harvests,
    }) =>
        // El motor formatea los montos con el locale de los ajustes, igual
        // que en la app: en inglés el grupo de miles va con coma.
        AlertService(now: _hoy, locale: locale == 'en' ? 'en_US' : 'es_CO')
            .evaluate(
              tx,
              [_cafe()],
              stringsFor(locale),
              harvests: harvests ?? [_cosecha()],
              sacoKg: 70,
            )
            .where((a) => a.rule == AlertRule.realCostVsPrice)
            .toList();

    test('sale en amarillo con el precio, el costo y el margen', () {
      final aviso = avisos(tx: [_gasto(570000), _venta(600000)]).single;

      expect(aviso.id, 'real_cost_cafe');
      expect(aviso.severity, AlertSeverity.warning);
      expect(aviso.title, contains('Café'));
      expect(aviso.title, contains('Pergamino'));
      expect(aviso.title, contains('10%'));
      expect(aviso.message, contains('COP 6.000'));
      expect(aviso.message, contains('COP 5.700'));
      expect(aviso.message, contains('5,0%'));
      expect(aviso.suggestion, isNotEmpty);
    });

    test('con margen negativo va en rojo y lo dice', () {
      final aviso = avisos(tx: [_gasto(660000), _venta(600000)]).single;

      expect(aviso.severity, AlertSeverity.danger);
      expect(aviso.title, contains('por debajo del costo'));
      expect(aviso.message, contains('-10%'));
    });

    test('en inglés el texto y el decimal son los del idioma', () {
      final aviso = avisos(
        tx: [_gasto(570000), _venta(600000)],
        locale: 'en',
      ).single;

      expect(aviso.title, contains('less than 10% margin'));
      expect(aviso.title, contains('Parchment'));
      expect(aviso.message, contains('COP 6,000'));
      expect(aviso.message, contains('5.0%'));
    });

    test('un margen chico se imprime con decimales, no como «-0%»', () {
      // Costo 6.002,4 contra un precio de 6.000 → −0,04%.
      final aviso = avisos(tx: [_gasto(600240), _venta(600000)]).single;

      expect(aviso.message, contains('-0,04%'));
      expect(aviso.message, isNot(contains('-0%')));
      expect(aviso.message, isNot(contains(' 0%')));
    });

    test('el empate exacto no dice «0%» a secas', () {
      // Costo 6.000 contra precio 6.000 → margen 0.
      final aviso = avisos(tx: [_gasto(600000), _venta(600000)]).single;

      expect(aviso.message, contains('0,00%'));
      expect(aviso.message, isNot(contains('-0')));
    });

    test('sin factor de trilla el motor no avisa', () {
      final avisos = AlertService(now: _hoy).evaluate(
        [_gasto(570000), _venta(600000)],
        [_cafe(factor: null)],
        stringsFor('es'),
        harvests: [_cosecha()],
        sacoKg: 70,
      );

      expect(avisos.where((a) => a.rule == AlertRule.realCostVsPrice), isEmpty);
    });
  });
}
