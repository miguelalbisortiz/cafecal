class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final int decimals;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimals = 0,
  });
}

/// Monedas soportadas: potencias en producción de café, banano o frutas
/// (región latinoamericana: Colombia, Ecuador/USD, Brasil, Perú, Chile,
/// Bolivia, Costa Rica).
const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'COP', name: 'Peso colombiano', symbol: r'$'),
  CurrencyInfo(code: 'USD', name: 'Dólar estadounidense', symbol: r'$', decimals: 2),
  CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', decimals: 2),
  CurrencyInfo(code: 'BRL', name: 'Real brasileño', symbol: r'R$', decimals: 2),
  CurrencyInfo(code: 'PEN', name: 'Sol peruano', symbol: 'S/', decimals: 2),
  CurrencyInfo(code: 'CLP', name: 'Peso chileno', symbol: r'$'),
  CurrencyInfo(code: 'BOB', name: 'Boliviano', symbol: 'Bs', decimals: 2),
  CurrencyInfo(code: 'CRC', name: 'Colón costarricense', symbol: '₡'),
];

CurrencyInfo currencyInfo(String code) => supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => const CurrencyInfo(
          code: 'COP', name: 'Peso colombiano', symbol: r'$'),
    );

/// Etiqueta de un monto con el símbolo y los decimales de **su** moneda:
/// `$5.000`, `€200,00`, `($1.000,00)` si es negativo.
///
/// No añade el código: quien muestra más de una moneda en la misma línea
/// debe ponerlo aparte (ver `byCurrencyText`), porque esta función solo
/// formatea un monto, nunca suma monedas distintas.
String formatMoneyLabel(double value, String currency) {
  final info = currencyInfo(currency);
  final s = '${info.symbol}${value.abs().toStringAsFixed(info.decimals)}';
  return value < 0 ? '($s)' : s;
}