import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final int decimals;

  const CurrencyInfo({
    required this.code,
    required this.name,
    this.decimals = 0,
  });
}

/// Monedas soportadas: potencias en producción de café, banano o frutas
/// (región latinoamericana: Colombia, Ecuador/USD, Brasil, Perú, Chile,
/// Bolivia, Costa Rica).
///
/// Sin símbolo: `$` lo comparten COP, USD y CLP, así que no identifica nada.
/// El único indicador es el [code] (ver `formatMoneyLabel`).
const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'COP', name: 'Peso colombiano'),
  CurrencyInfo(code: 'USD', name: 'Dólar estadounidense', decimals: 2),
  CurrencyInfo(code: 'EUR', name: 'Euro', decimals: 2),
  CurrencyInfo(code: 'BRL', name: 'Real brasileño', decimals: 2),
  CurrencyInfo(code: 'PEN', name: 'Sol peruano', decimals: 2),
  CurrencyInfo(code: 'CLP', name: 'Peso chileno'),
  CurrencyInfo(code: 'BOB', name: 'Boliviano', decimals: 2),
  CurrencyInfo(code: 'CRC', name: 'Colón costarricense'),
];

CurrencyInfo currencyInfo(String code) => supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => const CurrencyInfo(code: 'COP', name: 'Peso colombiano'),
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
/// El paréntesis del negativo es la notación **de los exportadores** (PDF y
/// Excel): los lee un contador. En la pantalla el negativo lleva su signo, con
/// `formatAmount`, porque el paréntesis se lee como una cifra más si uno no lo
/// es (PRD del 2026-10-01).
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