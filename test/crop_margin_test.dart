import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/crop_margin.dart';
import 'package:mi_cafetal/services/crop_totals.dart';

/// Tanda 3 · hito 2 — margen por cultivo y por hectárea.
///
/// Rojo antes de la implementación: el servicio nuevo y la clave ARB no
/// existen. Los datos están elegidos para que el % y el $/ha no apunten al
/// mismo cultivo (D1) y para que la cesta del $/ha excluya el equipo.
const lote = Terreno(id: 'lote', name: 'Lote Alto', areaHa: 4);

Crop cafe({double? areaHa = 2}) => Crop(
      id: 'cafe',
      name: 'Café',
      areaHa: areaHa,
      terrenoId: 'lote',
    );

Crop platano({double? areaHa = 2}) => Crop(
      id: 'platano',
      name: 'Plátano',
      areaHa: areaHa,
      terrenoId: 'lote',
    );

Transaction tx({
  required TransactionType type,
  required double amount,
  String? cropId,
  String? terrenoId,
  String currency = 'COP',
  String category = 'venta',
}) =>
    Transaction(
      id: '${type.name}_${cropId ?? terrenoId ?? 'sin'}_$amount',
      type: type,
      category: category,
      amount: amount,
      currency: currency,
      cropId: cropId,
      terrenoId: terrenoId,
      date: DateTime(2026, 10, 5),
      createdAt: DateTime(2026, 10, 5),
    );

CropMarginRow? mejor({
  required List<Transaction> txs,
  List<Crop> crops = const [],
}) =>
    bestCropMargin(
      records: txs,
      crops: crops.isEmpty ? [cafe(), platano()] : crops,
      terrenos: const [lote],
      unspecifiedName: 'Sin cultivo',
      loteNoRepartidoName: (n) => 'Lote $n sin repartir',
    );

List<dynamic> filas({
  required List<Transaction> txs,
  List<Crop> crops = const [],
}) =>
    cropMarginRecommendations(
      records: txs,
      crops: crops.isEmpty ? [cafe(), platano()] : crops,
      terrenos: const [lote],
      unspecifiedName: 'Sin cultivo',
      loteNoRepartidoName: (n) => 'Lote $n sin repartir',
      l10n: stringsFor('es'),
      locale: 'es_CO',
    );

void main() {
  test('SC-2.1 / D1 · manda el %, aunque el otro gane en \$/ha', () {
    final row = mejor(txs: [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'fertilizante'),
      tx(type: TransactionType.income, amount: 300000, cropId: 'platano'),
      tx(
          type: TransactionType.expense,
          amount: 150000,
          cropId: 'platano',
          category: 'fertilizante'),
    ], crops: [cafe(), platano(areaHa: 0.5)]);

    expect(row, isNotNull);
    expect(row!.cropId, 'cafe', reason: 'Café 60% > Plátano 50%');
    expect(row.marginPct, 60);
    expect(row.marginPerHa, 150000, reason: '250.000 ingreso/ha − 100.000 costo/ha');
  });

  test('SC-2.2 · la cesta del \$/ha excluye el equipo', () {
    final row = mejor(txs: [
      tx(type: TransactionType.income, amount: 400000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 100000,
          cropId: 'cafe',
          category: 'fertilizante'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'equipo'),
    ]);

    expect(row, isNotNull);
    expect(row!.marginPct, 25, reason: '(400.000 − 300.000) / 400.000');
    expect(row.costPerHa, 50000, reason: 'solo operación: 100.000 / 2 ha');
    expect(row.marginPerHa, 150000);
  });

  test('SC-2.3 / SC-G4 · una fila con las dos cifras y la acción', () {
    final recs = filas(txs: [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'fertilizante'),
    ]);
    expect(recs, hasLength(1));
    expect((recs.single as dynamic).rule, AlertRule.cropMargin);
    expect((recs.single as dynamic).suggestion, isEmpty,
        reason: 'la acción ya está en el mensaje, no se repite');

    final mensaje = (recs.single as dynamic).message as String;
    expect(mensaje, contains('Café'));
    expect(mensaje, contains('60%'));
    expect(mensaje, contains('COP 150.000'));
    expect(mensaje, contains('/ha'));
    expect(
      cropMarginMessage(mejor(txs: [
            tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
            tx(
                type: TransactionType.expense,
                amount: 200000,
                cropId: 'cafe',
                category: 'fertilizante'),
          ])!, stringsFor('es'), 'es_CO'),
      mensaje,
      reason: 'una sola redacción para los tres pintadores',
    );
  });

  test('SC-2.4 / D2 · sin área (nula o 0) se oculta la fila', () {
    final txs = [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'fertilizante'),
    ];
    expect(mejor(txs: txs, crops: [cafe(areaHa: null)]), isNull);
    expect(filas(txs: txs, crops: [cafe(areaHa: null)]), isEmpty);
    expect(mejor(txs: txs, crops: [cafe(areaHa: 0)]), isNull);
  });

  test('SC-2.4 · lote sin repartir: línea aparte, sin proporción inventada', () {
    final txs = [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'fertilizante'),
      tx(
          type: TransactionType.expense,
          amount: 400000,
          terrenoId: 'lote',
          category: 'fertilizante'),
    ];
    final crops = [cafe(), platano(areaHa: null)];
    final desglose = cropBreakdownRows(
      records: txs,
      crops: crops,
      terrenos: const [lote],
      unspecifiedName: 'Sin cultivo',
      loteNoRepartidoName: (n) => 'Lote $n sin repartir',
    );
    expect(desglose.any((r) => r.cropId == null && r.terrenoId == 'lote'), isTrue,
        reason: 'sin área en plátano el lote no se reparte');

    final row = mejor(txs: txs, crops: crops);
    expect(row, isNotNull);
    expect(row!.costPerHa, 100000,
        reason: 'el gasto del lote NO entra: 200.000 / 2 ha');
  });

  test('SC-2.5 / SC-G2 · moneda mixta calla la fila', () {
    expect(
      mejor(txs: [
        tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
        tx(
            type: TransactionType.expense,
            amount: 200000,
            cropId: 'cafe',
            category: 'fertilizante'),
        tx(
            type: TransactionType.income,
            amount: 300000,
            cropId: 'platano',
            currency: 'USD'),
        tx(
            type: TransactionType.expense,
            amount: 150000,
            cropId: 'platano',
            category: 'fertilizante',
            currency: 'USD'),
      ]),
      isNull,
      reason: 'no se comparan márgenes entre monedas',
    );

    expect(
      mejor(txs: [
        tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
        tx(
            type: TransactionType.expense,
            amount: 200000,
            cropId: 'cafe',
            category: 'fertilizante',
            currency: 'USD'),
      ]),
      isNull,
      reason: 'isMixed dentro de un cultivo también calla',
    );
  });

  test('SC-G1 · sin ingreso o sin gasto no hay candidato', () {
    expect(
      filas(txs: [
        tx(
            type: TransactionType.expense,
            amount: 200000,
            cropId: 'cafe',
            category: 'fertilizante'),
      ]),
      isEmpty,
    );
    expect(
      filas(txs: [
        tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      ]),
      isEmpty,
      reason: 'ni 100% ni 0: sin ambos datos no se calcula',
    );
  });

  test('SC-2.1 · no inventar el 100% ni el margen sin ingreso', () {
    expect(mejor(txs: [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
    ]), isNull);
    expect(mejor(txs: [
      tx(
          type: TransactionType.expense,
          amount: 100000,
          cropId: 'cafe',
          category: 'fertilizante'),
    ]), isNull);
  });

  test('Determinismo: desempate por \$/ha, luego nombre, sin reloj', () {
    final txs = [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'fertilizante'),
      tx(type: TransactionType.income, amount: 300000, cropId: 'platano'),
      tx(
          type: TransactionType.expense,
          amount: 120000,
          cropId: 'platano',
          category: 'fertilizante'),
    ];
    // Ambos dan 60%: Café 150.000/ha, Plátano 90.000/ha.
    final a = mejor(txs: txs);
    final b = mejor(txs: txs);
    expect(a, isNotNull);
    expect(b, isNotNull);
    expect(a!.cropId, 'cafe');
    expect(b!.cropId, a.cropId, reason: 'misma entrada, misma salida');
  });

  test('SC-2.1 / SC-2.2 · el reparto es el mismo del desglose', () {
    final txs = [
      tx(type: TransactionType.income, amount: 500000, cropId: 'cafe'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          cropId: 'cafe',
          category: 'fertilizante'),
      tx(type: TransactionType.income, amount: 300000, cropId: 'platano'),
      tx(
          type: TransactionType.expense,
          amount: 100000,
          cropId: 'platano',
          category: 'fertilizante'),
      tx(
          type: TransactionType.expense,
          amount: 200000,
          terrenoId: 'lote',
          category: 'fertilizante'),
    ];
    final shares = cropExpenseShares(records: txs, crops: [cafe(), platano()]);
    final partes = shares.of('cafe').fold<double>(0, (a, t) => a + t.amount);
    expect(partes, 300000,
        reason: '200.000 directos + 100.000 del lote (mitad de 200.000 entre 2+2 ha)');

    final row = mejor(txs: txs, crops: [cafe(), platano()]);
    expect(row, isNotNull);
    expect(row!.costPerHa, 150000,
        reason: '200.000 directos + 100.000 del lote, entre 2 ha');

    final otro = mejor(txs: txs, crops: [cafe(areaHa: 1), platano(areaHa: 3)]);
    expect(otro, isNotNull);
    expect(otro!.costPerHa, isNot(150000),
        reason: 'cambiar el área cambia la parte del lote y el costo/ha');
  });
}
