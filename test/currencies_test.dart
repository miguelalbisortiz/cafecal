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

  test('formatAmount usa el símbolo y decimales de la moneda', () {
    expect(formatAmount(2500, currency: 'PEN', locale: 'es_CO'),
        'S/2.500,00');
    expect(
        formatAmount(2500, currency: 'PEN', locale: 'es_CO', decimals: 0),
        'S/2.500');
    expect(formatAmount(2500, currency: 'BRL', locale: 'es_CO'), 'R\$2.500,00');
    expect(formatAmount(2500, currency: 'BOB', locale: 'es_CO'), 'Bs2.500,00');
    expect(formatAmount(2500, currency: 'CRC', locale: 'es_CO'), '₡2.500');
    expect(formatAmount(-2500, currency: 'COP', locale: 'es_CO'), '-\$2.500');
  });

  test('formato PDF usa el símbolo y decimales de la moneda', () {
    final svc = PdfExportService();
    expect(svc.formatPdfMoney(2500, 'PEN'), 'S/2500.00');
    expect(svc.formatPdfMoney(-2500, 'BRL'), '(R\$2500.00)');
    expect(svc.formatPdfMoney(2500, 'CRC'), '₡2500');
  });
}