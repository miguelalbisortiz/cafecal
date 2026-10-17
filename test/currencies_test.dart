import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_cafetal/models/currencies.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/utils/format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catálogo cubre las monedas de la región y sus símbolos', () {
    expect(supportedCurrencies.map((c) => c.code),
        containsAll(['COP', 'USD', 'EUR', 'BRL', 'PEN', 'CLP', 'BOB', 'CRC']));
    expect(currencyInfo('BRL').symbol, 'R\$');
    expect(currencyInfo('PEN').symbol, 'S/');
    expect(currencyInfo('BOB').symbol, 'Bs');
    expect(currencyInfo('CRC').symbol, '₡');
    expect(currencyInfo('COP').symbol, r'$');
  });

  test('fetchRate parsea la tasa real del API', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v6/latest/COP');
      return http.Response(
        jsonEncode({
          'result': 'success',
          'rates': {'PEN': 0.001, 'BRL': 0.00129},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final svc = CurrencyRatesService(client: client);
    expect(await svc.fetchRate('COP', 'PEN'), closeTo(0.001, 1e-9));
    expect(await svc.fetchRate('COP', 'COP'), 1);
  });

  test('fetchRate falla sin tasa para la moneda destino', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({'result': 'success', 'rates': {'USD': 1}}),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final svc = CurrencyRatesService(client: client);
    expect(() => svc.fetchRate('COP', 'PEN'), throwsException);
  });

  test('el código es el único indicador, con los decimales de la moneda', () {
    // `$` lo comparten COP, USD y CLP en este mismo catálogo, así que el
    // símbolo no identificaba nada. El código sí, y una sola vez: antes los
    // reportes imprimían `$2.400.000 COP`, con dos indicadores.
    expect(formatAmount(2500, currency: 'PEN', locale: 'es_CO'),
        'PEN 2.500,00');
    expect(
        formatAmount(2500, currency: 'PEN', locale: 'es_CO', decimals: 0),
        'PEN 2.500');
    expect(formatAmount(2500, currency: 'BRL', locale: 'es_CO'), 'BRL 2.500,00');
    expect(formatAmount(2500, currency: 'BOB', locale: 'es_CO'), 'BOB 2.500,00');
    expect(formatAmount(2500, currency: 'CRC', locale: 'es_CO'), 'CRC 2.500');
    expect(formatAmount(-2500, currency: 'COP', locale: 'es_CO'), '-COP 2.500');
  });

  test('el símbolo ambiguo no aparece en ninguna cifra', () {
    for (final moneda
        in ['COP', 'USD', 'CLP', 'EUR', 'BRL', 'PEN', 'BOB', 'CRC']) {
      final texto = formatAmount(2400000, currency: moneda, locale: 'es_CO');
      expect(texto, startsWith('$moneda '),
          reason: '$moneda debe identificarse por su código');
      expect(texto, isNot(contains(r'$')),
          reason: '\$ es de COP, de USD y de CLP a la vez: no dice nada');
    }
  });

  test('el PDF agrupa los miles igual que la pantalla', () {
    final svc = PdfExportService();
    // Antes imprimía `S/2500.00` mientras la misma app mostraba `S/2.500,00`
    // en pantalla: dos pintadores, dos cifras para el mismo número.
    expect(svc.formatPdfMoney(2500, 'PEN'), 'PEN 2.500,00');
    expect(svc.formatPdfMoney(-2500, 'BRL'), '(BRL 2.500,00)');
    expect(svc.formatPdfMoney(2500, 'CRC'), 'CRC 2.500');
    expect(svc.formatPdfMoney(2400000, 'COP'), 'COP 2.400.000');
    // Y lo que dice el export es exactamente lo que diría la pantalla.
    expect(svc.formatPdfMoney(2400000, 'COP'),
        formatAmount(2400000, currency: 'COP', locale: 'es'));
    expect(svc.formatPdfMoney(2500, 'PEN'),
        formatAmount(2500, currency: 'PEN', locale: 'es'));
  });
}