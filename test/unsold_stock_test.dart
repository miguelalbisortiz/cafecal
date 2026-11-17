import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';
import 'package:mi_cafetal/services/unsold_stock.dart';

/// Tanda 3 · hito 1 — stock sin vender.
///
/// `cosechaKg − ventaKg` en 365 días móviles, por cultivo. Rojo antes de la
/// implementación: el servicio nuevo y el valor del enum todavía no existen.

const cafe = Crop(id: 'cafe', name: 'Café');
const platano = Crop(id: 'platano', name: 'Plátano');

void main() {
  final now = DateTime(2026, 11, 17);

  Harvest cosecha({
    String id = 'h',
    String? cropId = 'cafe',
    DateTime? date,
    double kg = 100,
    String unit = 'kg',
    double? equivalentKg,
  }) =>
      Harvest(
        id: id,
        cropId: cropId,
        date: date ?? now.subtract(const Duration(days: 10)),
        amount: kg,
        unit: unit,
        equivalentKg: equivalentKg,
      );

  Transaction venta({
    String id = 'v',
    String? cropId = 'cafe',
    DateTime? date,
    double kg = 40,
    String unit = 'kg',
    double? equivalentKg,
    String currency = 'COP',
  }) =>
      Transaction(
        id: id,
        cropId: cropId,
        type: TransactionType.income,
        category: 'venta',
        amount: kg * 1000,
        currency: currency,
        date: date ?? now.subtract(const Duration(days: 10)),
        createdAt: now,
        quantity: kg,
        unit: unit,
        equivalentKg: equivalentKg,
      );

  List<UnsoldStockRow> calcular({
    List<Transaction> ventas = const [],
    List<Harvest> cosechas = const [],
    List<Crop> cultivos = const [cafe],
    double sacoKg = 70,
    DateTime? fecha,
  }) =>
      unsoldStockByCrop(
        transactions: ventas,
        harvests: cosechas,
        crops: cultivos,
        sacoKg: sacoKg,
        now: fecha ?? now,
      );

  test('SC-1.1 · ventana rodante: día 364 cuenta, día 366 no', () {
    final dentro = calcular(
      ventas: [
        venta(id: 'v1', kg: 40, date: now.subtract(const Duration(days: 364)))
      ],
      cosechas: [
        cosecha(id: 'h1', kg: 100, date: now.subtract(const Duration(days: 364)))
      ],
    );
    expect(dentro, hasLength(1));
    expect(dentro.single.harvestedKg, 100);
    expect(dentro.single.soldKg, 40);
    expect(dentro.single.unsoldKg, 60);

    final fuera = calcular(
      ventas: [
        venta(id: 'v2', kg: 40, date: now.subtract(const Duration(days: 366)))
      ],
      cosechas: [
        cosecha(id: 'h2', kg: 500, date: now.subtract(const Duration(days: 366)))
      ],
    );
    expect(fuera, isEmpty,
        reason: 'el corte es rodante, no el año calendario');
  });

  test('SC-1.1 · límites inclusivos en now − 365 y en now', () {
    final corte = now.subtract(const Duration(days: 365));
    final rows = calcular(
      ventas: [
        venta(id: 'v1', kg: 10, date: corte),
        venta(id: 'v2', kg: 10, date: now),
      ],
      cosechas: [
        cosecha(id: 'h1', kg: 100, date: corte),
        cosecha(id: 'h2', kg: 100, date: now),
      ],
    );
    expect(rows.single.unsoldKg, 180);

    expect(
      calcular(
        ventas: [venta(kg: 10, date: now.subtract(const Duration(days: 366)))],
        cosechas: [
          cosecha(kg: 100, date: now.subtract(const Duration(days: 366)))
        ],
      ),
      isEmpty,
    );
  });

  test('SC-1.2 · una fila por cultivo, ordenada por kg, y recommendation', () {
    final ventas = [
      venta(id: 'v1', cropId: 'cafe', kg: 40),
      venta(id: 'v2', cropId: 'platano', kg: 30),
    ];
    final cosechas = [
      cosecha(id: 'h1', cropId: 'cafe', kg: 100),
      cosecha(id: 'h2', cropId: 'platano', kg: 50),
    ];
    final rows = calcular(
      ventas: ventas,
      cosechas: cosechas,
      cultivos: const [cafe, platano],
    );
    expect(rows.map((r) => r.cropId), ['cafe', 'platano']);
    expect(rows.map((r) => r.unsoldKg), [60.0, 20.0]);

    final mensaje = unsoldStockMessage(rows.first, stringsFor('es'), 'es_CO');
    expect(mensaje, contains('60'));
    expect(mensaje, contains('Café'));
    expect(mensaje, contains('Define comprador'));

    final recs = unsoldStockRecommendations(
      transactions: ventas,
      harvests: cosechas,
      crops: const [cafe, platano],
      sacoKg: 70,
      now: now,
      l10n: stringsFor('es'),
      locale: 'es_CO',
    );
    expect(recs, hasLength(2), reason: 'dos cultivos, dos filas: sin dedupe');
    expect(recs.first.rule, AlertRule.unsoldStock);
    expect(recs.first.severity, AlertSeverity.warning);
    expect(recs.first.suggestion, isEmpty,
        reason: 'la acción ya está en el mensaje, no se repite');
  });

  test('SC-1.2 / SC-1.3 · sin excedente no hay aviso', () {
    expect(
      calcular(
          ventas: [venta(kg: 50)], cosechas: [cosecha(kg: 50)]),
      isEmpty,
    );
    expect(
      calcular(
          ventas: [venta(kg: 50)], cosechas: [cosecha(kg: 40)]),
      isEmpty,
      reason: 'vender más de lo cosechado no es stock: nunca un número negativo',
    );
  });

  test('SC-1.3 · ventana vacía: ni 0 kg ni texto de sin datos', () {
    expect(calcular(), isEmpty);
  });

  test('SC-G3 / SC-1.4 · gemelos: sin peso la cifra no cambia', () {
    final ventas = [
      venta(id: 'v1', kg: 40),
      venta(
          id: 'v2', kg: 12, unit: 'cajon', equivalentKg: null),
    ];
    final cosechas = [
      cosecha(id: 'h1', kg: 100),
      cosecha(
          id: 'h2', kg: 8, unit: 'racimo', equivalentKg: null),
    ];
    expect(calcular(ventas: [ventas.first], cosechas: [cosechas.first]).single.unsoldKg,
        60);
    expect(calcular(ventas: ventas, cosechas: cosechas).single.unsoldKg, 60,
        reason: 'el peso en blanco se lista, nunca se suma');
    expect(pendingWeightHarvests(cosechas), hasLength(1));
    expect(pendingWeightSales(ventas), hasLength(1));
  });

  test('SC-G1 · solo registros sin peso: ninguna fila con 0', () {
    expect(
      calcular(
        ventas: [venta(kg: 12, unit: 'cajon')],
        cosechas: [cosecha(kg: 8, unit: 'racimo')],
      ),
      isEmpty,
    );
  });

  test('SC-G2 · moneda mixta: el aviso es de kilos y no cita moneda', () {
    final rows = calcular(
      cosechas: [cosecha(kg: 100)],
      ventas: [
        venta(id: 'v1', kg: 40, currency: 'COP'),
        venta(id: 'v2', kg: 20, currency: 'USD'),
      ],
    );
    expect(rows.single.unsoldKg, 40);
    final mensaje = unsoldStockMessage(rows.single, stringsFor('es'), 'es_CO');
    expect(mensaje, isNot(contains(r'$')));
    expect(mensaje, isNot(contains('COP')));
    expect(mensaje, isNot(contains('USD')));
  });

  test('SC-1.1 · usa el sacoKg de la finca, no el de la norma', () {
    final rows = calcular(
      cosechas: [cosecha(kg: 1, unit: 'saco')],
      sacoKg: 60,
    );
    expect(rows.single.unsoldKg, 60,
        reason: 'un saco de 60 no vale 70');
  });

  test('SC-1.2 · cosecha sin cultivo no genera fila', () {
    expect(
      calcular(cosechas: [cosecha(kg: 100, cropId: null)]),
      isEmpty,
      reason: 'sin cultivo no hay a quién dirigir la acción',
    );
  });
}
