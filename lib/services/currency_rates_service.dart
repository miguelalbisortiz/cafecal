import 'dart:convert';

import 'package:http/http.dart' as http;

/// Obtiene tasas de cambio reales (API públicas gratuitas, sin key).
/// Devuelve cuántas unidades de [to] vale 1 unidad de [from].
class CurrencyRatesService {
  final http.Client _client;

  CurrencyRatesService({http.Client? client})
      : _client = client ?? http.Client();

  static const _primary = 'https://open.er-api.com/v6/latest/{from}';
  static const _fallback =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{from}.json';

  static const _maxAttempts = 3;

  Future<double> fetchRate(String from, String to) async {
    if (from == to) return 1;

    // Intenta el proveedor primario con reintentos ante fallos transitorios.
    for (var i = 0; i < _maxAttempts; i++) {
      try {
        final rate = await _requestPrimary(from, to);
        return rate;
      } catch (_) {
        if (i < _maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 400 * (i + 1)));
        }
      }
    }

    // Red de seguridad: proveedor alternativo.
    try {
      return await _requestFallback(from, to);
    } catch (_) {
      throw Exception('Tasa no disponible. Verifica tu conexión.');
    }
  }

  Future<double> _requestPrimary(String from, String to) async {
    final uri = Uri.parse(_primary.replaceFirst('{from}', from));
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['result'] != 'success') {
      throw Exception('Servicio de tasas no disponible');
    }
    final rate = (json['rates'] as Map<String, dynamic>)[to];
    if (rate is! num) {
      throw Exception('No hay tasa para la moneda $to');
    }
    return rate.toDouble();
  }

  Future<double> _requestFallback(String from, String to) async {
    final uri = Uri.parse(_fallback.replaceFirst('{from}', from.toLowerCase()));
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final values = json[from.toLowerCase()];
    if (values is! Map<String, dynamic>) {
      throw Exception('Servicio de tasas no disponible');
    }
    final rate = values[to.toLowerCase()];
    if (rate is! num) {
      throw Exception('No hay tasa para la moneda $to');
    }
    return rate.toDouble();
  }
}