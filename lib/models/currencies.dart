import 'package:intl/intl.dart';

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

/// Dígitos de un monto agrupados por [locale] con los decimales de su moneda.
///
/// Es la **única** casa donde se decide cómo se separan los miles y los
/// decimales. El formato de pantalla, el PDF y el Excel pasan por aquí: los
/// exportadores usaban `toStringAsFixed` y salía `2400000` donde en pantalla
/// había `2.400.000`, y `€200.00` donde en pantalla había `€200,00`.
String groupedDigits(double value,
    {required String currency, required String locale, int? decimals}) {
  final info = currencyInfo(currency);
  final dec = decimals ?? info.decimals;
  final pattern = dec > 0 ? '#,##0.${'0' * dec}' : '#,##0';
  return NumberFormat(pattern, locale).format(value.abs());
}

/// Etiqueta de un monto con el código de **su** moneda como único indicador:
/// `COP 5.000`, `EUR 200,00`, `(COP 1.000,00)` si es negativo.
///
/// No usa el símbolo porque `$` lo comparten COP, USD y CLP en este mismo
/// catálogo: el símbolo no decía de qué moneda era la cifra. Y no añade el
/// código «por si acaso»: el código ya va, que es el único indicador.
///
/// Quien muestra más de una moneda en la misma línea debe seguirlas
/// distinguiendo aparte (ver `byCurrencyText`), porque esta función solo
/// formatea un monto, nunca suma monedas distintas.
///
/// [locale] es obligatorio a propósito: sin él no hay separador de miles
/// posible y la cifra sale `5000` en vez de `5.000`.
String formatMoneyLabel(double value, String currency,
    {required String locale}) {
  final digits = groupedDigits(value, currency: currency, locale: locale);
  final s = '$currency $digits';
  return value < 0 ? '($s)' : s;
}