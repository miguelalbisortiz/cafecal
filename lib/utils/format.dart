import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/currencies.dart';
import '../providers/transaction_provider.dart';

/// Área en hectáreas con el decimal del idioma, sin ceros de sobra:
/// `2 ha`, `0,4 ha`, `1,25 ha`.
///
/// Una sola regla para Cultivos, Reportes, PDF y Excel. Devuelve solo el
/// número: el sufijo ` ha` lo pone quien lo pinta, para poder decir también
/// «0,4 ha por planta» si algún día hace falta.
String formatAreaHa(double value, String locale) =>
    NumberFormat('0.###', locale).format(value);

/// Kilos de un lote: enteros desde 100 (`250`, `1.240`) y hasta dos decimales
/// por debajo (`12,25`, `0,8`). Misma regla en la tarjeta y en la Ayuda.
///
/// Devuelve solo el número: el sufijo ` kg` lo pone quien lo pinta.
String formatKg(double value, String locale) =>
    NumberFormat(value >= 100 ? '#,##0' : '#,##0.##', locale).format(value);

/// Kg por planta: siempre dos decimales (`0,36`), porque es un rendimiento y
/// el redondeo a entero borra justo la diferencia entre lotes.
String formatKgPerPlant(double value, String locale) =>
    NumberFormat('0.00', locale).format(value);

String formatMoney(BuildContext context, double value, {int? decimals}) {
  final tx = context.read<TransactionProvider>();
  return formatAmount(value,
      currency: tx.settings.currency,
      locale: tx.settings.numberLocale,
      decimals: decimals);
}

/// Formato de moneda con moneda explícita (para cuando la transacción
/// tiene su propia moneda distinta a la de ajustes).
String formatMoneyFor(BuildContext context, double value,
    {required String currency, int? decimals}) {
  final tx = context.read<TransactionProvider>();
  return formatAmount(value,
      currency: currency, locale: tx.settings.numberLocale, decimals: decimals);
}

/// Formato de moneda sin contexto — usado por PDF/HTML export.
/// Sin [decimals] usa los decimales naturales de la moneda (COP 0, PEN 2…).
/// El código de la moneda es el **único** indicador: `$` lo comparten COP,
/// USD y CLP en este mismo catálogo, así que el símbolo no identificaba nada,
/// y juntar símbolo y código (`$2.400.000 COP`) era decirlo dos veces.
String formatAmount(double value,
    {required String currency, required String locale, int? decimals}) {
  final digits = groupedDigits(value,
      currency: currency, locale: locale, decimals: decimals);
  final sign = value < 0 ? '-' : '';
  return '$sign$currency $digits';
}

/// Formato compacto para tarjetas: 2.400.000 → $2,4M; 96.000 → $96k.
/// Incluye el signo para valores negativos.
String formatCompact(BuildContext context, double value) {
  final tx = context.read<TransactionProvider>();
  return _formatCompactWith(value, tx.settings.currency);
}

/// Formato compacto con moneda explícita (para dashboards con moneda mixta).
String formatCompactExplicit(double value,
        {required String currency, required String locale}) =>
    _formatCompactWith(value, currency);

/// Igual que [formatAmount]: el código va solo, nunca el símbolo. `$` es de
/// COP, de USD y de CLP a la vez.
String _formatCompactWith(double value, String code) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();

  String core;
  if (abs >= 1000000000) {
    core = '${_compactDec(abs / 1000000000)}B';
  } else if (abs >= 1000000) {
    core = '${_compactDec(abs / 1000000)}M';
  } else if (abs >= 1000) {
    core = '${_compactDec(abs / 1000)}k';
  } else {
    core = abs.toStringAsFixed(0);
  }
  return '$sign$code $core';
}

String _compactDec(double v) {
  if (v % 1 == 0) return v.toStringAsFixed(0);
  if (v >= 100) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}
