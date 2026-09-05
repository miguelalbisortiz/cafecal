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