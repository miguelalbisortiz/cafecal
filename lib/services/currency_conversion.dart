import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'currency_rates_service.dart';
import 'currency_totals.dart';

/// Totales de un período ya convertidos a la moneda de la app.
///
/// Solo existe cuando **todas** las monedas del período tienen tasa: nunca
/// lleva cifras inventadas ni aproximadas.
class ConvertedPeriodTotals {
  /// Moneda destino (la de Ajustes).
  final String currency;

  final double incomes;
  final double expenses;

  const ConvertedPeriodTotals({
    required this.currency,
    required this.incomes,
    required this.expenses,
  });

  double get result => incomes - expenses;
}

/// Conversor de totales con caché local.
///
/// - Usa [CurrencyRatesService] (proveedor primario + alternativo + reintentos).
/// - Cachea cada tasa en SharedPreferences con clave `fx_rates_v1` y TTL de
///   24 h: si está fresca, **no hay red**.
/// - Si falta **una sola** tasa, [convert] devuelve null: la UI cae en los
///   totales por moneda en vez de mostrar una cifra falsa.
class CurrencyConversionService {
  /// Clave del caché en SharedPreferences: `{"COP->USD": {"rate": .., "fetchedAt": ..}}`.
  static const String cacheKey = 'fx_rates_v1';

  /// Cuánto vale una tasa guardada antes de volver a pedirla.
  static const Duration ttl = Duration(hours: 24);

  final CurrencyRatesService rates;
  final Future<SharedPreferences> Function() _prefs;

  CurrencyConversionService({
    CurrencyRatesService? rates,
    Future<SharedPreferences> Function()? prefs,
  })  : rates = rates ?? CurrencyRatesService(),
        _prefs = prefs ?? SharedPreferences.getInstance;

  static CurrencyConversionService? _fallback;

  /// Instancia por defecto, para pantallas sin [CurrencyConversionScope].
  static CurrencyConversionService get fallback =>
      _fallback ??= CurrencyConversionService();

  /// Tasa de [from] a [to]. 1 si son la misma moneda; **null** si no está
  /// disponible (sin red, proveedor caído o caché vencida).
  Future<double?> rateFor(String from, String to) async {
    if (from == to) return 1.0;

    final prefs = await _prefs();
    final now = DateTime.now().toUtc();
    final cached = _readCache(prefs)[_key(from, to)];
    if (cached != null && now.difference(cached.$1).abs() < ttl) {
      return cached.$2;
    }

    try {
      final rate = await rates.fetchRate(from, to);
      await _writeCache(prefs, from, to, rate, now);
      return rate;
    } catch (_) {
      // Sin tasa fiable no se inventa nada: la UI muestra totales por moneda.
      return null;
    }
  }

  /// Convierte los totales del período a [to].
  ///
  /// Devuelve null si **cualquier** moneda no tiene tasa disponible.
  Future<ConvertedPeriodTotals?> convert(
    PeriodCurrencyTotals totals,
    String to,
  ) async {
    if (totals.currencies.isEmpty) return null;

    final currencies = totals.currencies.toList()..sort();
    final resolved = await Future.wait(currencies.map((c) => rateFor(c, to)));
    if (resolved.any((r) => r == null)) return null;

    var incomes = 0.0;
    var expenses = 0.0;
    for (var i = 0; i < currencies.length; i++) {
      final rate = resolved[i]!;
      incomes += totals.incomeOf(currencies[i]) * rate;
      expenses += totals.expenseOf(currencies[i]) * rate;
    }
    return ConvertedPeriodTotals(
      currency: to,
      incomes: incomes,
      expenses: expenses,
    );
  }

  static String _key(String from, String to) => '$from->$to';

  /// Entradas del caché: clave `"ORIGEN->DESTINO"` → (momento, tasa).
  Map<String, (DateTime, double)> _readCache(SharedPreferences prefs) {
    final raw = _readCacheRaw(prefs);
    final out = <String, (DateTime, double)>{};
    raw.forEach((key, value) {
      if (value is! Map<String, dynamic>) return;
      final rate = value['rate'];
      final fetchedAt = value['fetchedAt'];
      if (rate is! num || fetchedAt is! String) return;
      final when = DateTime.tryParse(fetchedAt);
      if (when == null) return;
      out[key] = (when.toUtc(), rate.toDouble());
    });
    return out;
  }

  Future<void> _writeCache(
    SharedPreferences prefs,
    String from,
    String to,
    double rate,
    DateTime now,
  ) async {
    final cache = Map<String, dynamic>.from(_readCacheRaw(prefs));
    cache[_key(from, to)] = {
      'rate': rate,
      'fetchedAt': now.toIso8601String(),
    };
    await prefs.setString(cacheKey, jsonEncode(cache));
  }

  Map<String, dynamic> _readCacheRaw(SharedPreferences prefs) {
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}
