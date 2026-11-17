import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/buyer_concentration.dart';
import 'package:mi_cafetal/services/recommendations.dart';

/// Tanda 3 · hito 3 · SC-3.1..3.4 y SC-G1/G2. Servicio puro: ningún test
/// necesita widgets, reloj ni red. Rojo antes de crear el servicio.

void main() {
  final es = stringsFor('es');
  const locale = 'es_CO';
  var nextId = 0;

  Transaction venta(
    String? client,
    double amount, {
    String currency = 'COP',
    String category = 'venta',
    bool deleted = false,
  }) =>
      Transaction(
        id: 'tx-${nextId++}',
        type: TransactionType.income,
        category: category,
        amount: amount,
        currency: currency,
        client: client,
        deleted: deleted,
        date: DateTime(2026, 11, 15),
        createdAt: DateTime(2026, 11, 15),
      );

  BuyerConcentrationRow? fila(Iterable<Transaction> txs) =>
      buyerConcentration(records: txs);

  List<Recommendation> recs(Iterable<Transaction> txs) =>
      buyerConcentrationRecommendations(records: txs, l10n: es, locale: locale);

  test('SC-3.1 / SC-3.2 · dos compradores con >50 %', () {
    final txs = [venta('A', 700), venta('B', 300)];
    final row = fila(txs);
    expect(row, isNotNull);
    expect(row!.buyerCount, 2);
    expect(row.sharePct, 70);
    expect(row.buyer, 'A');
    expect(row.salesTotal, 1000);
    expect(row.currency, 'COP');

    final mensaje = buyerConcentrationMessage(row, es, locale);
    expect(mensaje, contains('70%'));
    expect(mensaje, contains('A'));
    expect(mensaje, contains('Busca un segundo comprador'));

    final derivadas = recs(txs);
    expect(derivadas, hasLength(1));
    expect(derivadas.single.rule, AlertRule.buyerConcentration);
    expect(derivadas.single.message, mensaje);
    expect(derivadas.single.suggestion, '');
  });

  test('D1 / SC-3.3 · exactamente 50 % no emite', () {
    final txs = [venta('A', 500), venta('B', 500)];
    expect(fila(txs), isNull);
    expect(recs(txs), isEmpty);
  });

  test('SC-3.3 / D4 del PRD · un solo comprador no emite aunque sea 100 %', () {
    final txs = [venta('A', 1000)];
    expect(fila(txs), isNull);
    expect(recs(txs), isEmpty);
  });

  test('SC-G1 / D4 · ventas sin comprador quedan fuera del denominador', () {
    expect(fila([venta(null, 700), venta('', 300)]), isNull);
    expect(recs([venta(null, 700), venta('', 300)]), isEmpty);

    // A 700 + B 300 dan 70 %. Añadir 300 sin comprador NO debe bajarlo a
    // 700/1300: el denominador solo cuenta ventas identificadas.
    final row = fila([venta('A', 700), venta('B', 300), venta(null, 300)]);
    expect(row, isNotNull);
    expect(row!.buyerCount, 2);
    expect(row.sharePct, 70);
    expect(row.salesTotal, 1000);
  });

  test('SC-3.4 · moneda mixta calla, incluso dentro de un mismo comprador', () {
    final entreCompradores = [venta('A', 700), venta('B', 300, currency: 'USD')];
    expect(fila(entreCompradores), isNull);
    expect(recs(entreCompradores), isEmpty);

    // Con otro comprador identificado el aviso tendría sentido; aun así la
    // guarda de moneda debe ganar antes de sumar.
    final mismoComprador = [
      venta('A', 700),
      venta('A', 300, currency: 'USD'),
      venta('B', 100),
    ];
    expect(fila(mismoComprador), isNull);
    expect(recs(mismoComprador), isEmpty);
  });

  test('D3 · nombres con mayúsculas y espacios cuentan como dos compradores',
      () {
    final txs = [venta('Café S.A.', 700), venta('café  s.a.', 300)];
    final row = fila(txs);
    expect(row, isNotNull);
    expect(row!.buyerCount, 2);
    expect(row.buyer, 'Café S.A.');
    final mensaje = buyerConcentrationMessage(row, es, locale);
    expect(mensaje, contains('Café S.A.'));
    expect(mensaje, isNot(contains('café  s.a.')));
  });

  test('SC-3.1 · solo ventas: subvenciones, legadas y borrados', () {
    final txs = [
      venta('A', 900, category: 'subvenciones'),
      venta('B', 100),
      venta('C', 50, category: 'venta_cafe'),
      venta('D', 1000, deleted: true),
    ];
    final row = fila(txs);
    expect(row, isNotNull);
    expect(row!.buyerCount, 2, reason: 'la subvención no es comprador');
    expect(row.buyer, 'B', reason: 'B 100 gana a la legada C 50');
    expect(row.salesTotal, 150, reason: 'ni subvención ni borrado suman');
    expect(row.sharePct, closeTo(100 * 100 / 150, 0.001));

    // Sin la legada quedaría un solo comprador: no se emite nada.
    expect(fila(txs.take(2)), isNull);
  });

  test('SC-G1 · sin ventas o con montos 0 no se inventa un 0 %', () {
    expect(fila(const <Transaction>[]), isNull);
    expect(recs(const <Transaction>[]), isEmpty);
    final ceros = [venta('A', 0), venta('B', 0)];
    expect(fila(ceros), isNull);
    expect(recs(ceros), isEmpty);
  });

  test('Determinismo · principal y cifra iguales con distinto orden', () {
    final unos = [venta('A', 600), venta('B', 300), venta('C', 100)];
    final otros = [venta('C', 100), venta('B', 300), venta('A', 600)];
    final primero = fila(unos)!;
    final segundo = fila(otros)!;
    expect(primero.sharePct, 60);
    expect(segundo.sharePct, 60);
    expect(segundo.buyer, primero.buyer);
    expect(segundo.buyerAmount, primero.buyerAmount);
  });
}
