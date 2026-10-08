import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/currency_conversion.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/currency_totals.dart';

/// Cliente que nunca contesta: simula caída de red o de proveedor.
MockClient _redCaida([void Function()? onCall]) => MockClient((_) async {
      onCall?.call();
      throw Exception('sin conexión');
    });

/// Cliente con la respuesta del proveedor primario (`rates` → `to`).
MockClient _tasa(Map<String, num> rates) => MockClient((_) async =>
    http.Response('{"result":"success","rates":${jsonEncode(rates)}}', 200,
        headers: {'content-type': 'application/json'}));

Future<CurrencyConversionService> _service(
    SharedPreferences prefs, http.Client client) async =>
    CurrencyConversionService(
      rates: CurrencyRatesService(client: client),
      prefs: () async => prefs,
    );

Future<void> _seedTasa(SharedPreferences prefs, String key, double rate,
        DateTime when) =>
    prefs.setString(CurrencyConversionService.cacheKey, jsonEncode({
      key: {'rate': rate, 'fetchedAt': when.toUtc().toIso8601String()},
    }));

PeriodCurrencyTotals _mezcla() => PeriodCurrencyTotals.fromRecords([
      Transaction(
        id: 'i1',
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        currency: 'COP',
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      ),
      Transaction(
        id: 'e1',
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        currency: 'COP',
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      ),
      Transaction(
        id: 'i2',
        type: TransactionType.income,
        category: 'venta_otro',
        amount: 200,
        currency: 'EUR',
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      ),
      Transaction(
        id: 'e2',
        type: TransactionType.expense,
        category: 'transporte',
        amount: 50,
        currency: 'EUR',
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      ),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('caché de tasas (fx_rates_v1, TTL 24 h)', () {
    test('dentro del TTL responde sin tocar la red', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      await _seedTasa(
          prefs, 'COP->EUR', 4.5, DateTime.now().toUtc());

      var llamadas = 0;
      final service = await _service(prefs, _redCaida(() => llamadas++));

      expect(await service.rateFor('COP', 'EUR'), 4.5);
      expect(llamadas, 0, reason: 'con la caché fresca no hay peticiones');
    });

    test('fuera del TTL vuelve a pedirla y la guarda con hora nueva',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      await _seedTasa(
          prefs,
          'COP->EUR',
          4.0,
          DateTime.now().toUtc().subtract(const Duration(hours: 25)));

      final service = await _service(prefs, _tasa({'EUR': 4.25}));

      expect(await service.rateFor('COP', 'EUR'), 4.25,
          reason: 'la tasa vencida no se usa: se pide una nueva');

      final cache = jsonDecode(
              prefs.getString(CurrencyConversionService.cacheKey)!)
          as Map<String, dynamic>;
      final entrada = cache['COP->EUR'] as Map<String, dynamic>;
      expect(entrada['rate'], 4.25);
      expect(DateTime.parse(entrada['fetchedAt'] as String).toUtc().isBefore(
          DateTime.now().toUtc().add(const Duration(seconds: 5))),
          isTrue);
    });

    test('caché vencida y sin red → no hay tasa (no se inventa)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      await _seedTasa(
          prefs,
          'COP->EUR',
          4.0,
          DateTime.now().toUtc().subtract(const Duration(hours: 25)));

      final service = await _service(prefs, _redCaida());

      expect(await service.rateFor('COP', 'EUR'), isNull);
    });

    test('misma moneda → 1 sin red ni caché', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs, _redCaida());

      expect(await service.rateFor('COP', 'COP'), 1);
    });
  });

  group('convert: totales del período a la moneda de Ajustes', () {
    test('con todas las tasas devuelve un solo total convertido', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs, _tasa({'COP': 4.0}));

      final converted = await service.convert(_mezcla(), 'COP');

      expect(converted, isNotNull);
      expect(converted!.currency, 'COP');
      expect(converted.incomes, 5000 + 200 * 4.0);
      expect(converted.expenses, 1000 + 50 * 4.0);
      expect(converted.result, 4600);
    });

    test('si falta una tasa devuelve null (la UI cae en totales por moneda)',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      // El proveedor no trae tasa para el par que necesitamos.
      final service = await _service(prefs, _tasa({'BRL': 4.0}));

      final totales = PeriodCurrencyTotals.fromRecords([
        Transaction(
          id: 'i1',
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 5000,
          currency: 'COP',
          date: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
        Transaction(
          id: 'i2',
          type: TransactionType.income,
          category: 'venta_otro',
          amount: 100,
          currency: 'USD',
          date: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
      ]);

      expect(await service.convert(totales, 'COP'), isNull);
    });

    test('período de una sola moneda ya en destino: sin red, cifras exactas',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs, _redCaida());

      final totales = PeriodCurrencyTotals.fromRecords([
        Transaction(
          id: 'i1',
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 5000,
          currency: 'COP',
          date: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
      ]);

      final converted = await service.convert(totales, 'COP');

      expect(converted, isNotNull);
      expect(converted!.incomes, 5000);
      expect(converted.expenses, 0);
      expect(converted.result, 5000);
    });
  });
}
