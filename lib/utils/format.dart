import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/currencies.dart';
import '../providers/transaction_provider.dart';

String formatMoney(BuildContext context, double value, {int? decimals}) {
  final tx = context.read<TransactionProvider>();
  return formatAmount(value,
      currency: tx.settings.currency, locale: tx.settings.locale, decimals: decimals);
}

/// Formato de moneda con moneda explícita (para cuando la transacción
/// tiene su propia moneda distinta a la de ajustes).
String formatMoneyFor(BuildContext context, double value,
    {required String currency, int? decimals}) {
  final tx = context.read<TransactionProvider>();
  return formatAmount(value,
      currency: currency, locale: tx.settings.locale, decimals: decimals);
}

/// Formato de moneda sin contexto — usado por PDF/HTML export.
/// Sin [decimals] usa los decimales naturales de la moneda (COP 0, PEN 2…).
String formatAmount(double value,
    {required String currency, required String locale, int? decimals}) {
  final info = currencyInfo(currency);
  final dec = decimals ?? info.decimals;
  final pattern = dec > 0 ? '#,##0.${'0' * dec}' : '#,##0';
  final digits = NumberFormat(pattern, locale).format(value.abs());
  final sign = value < 0 ? '-' : '';
  return '$sign${info.symbol}$digits';
}

/// Formato compacto para tarjetas: 2.400.000 → $2,4M; 96.000 → $96k.
/// Incluye el signo para valores negativos.
String formatCompact(BuildContext context, double value) {
  final tx = context.read<TransactionProvider>();
  final symbol = currencyInfo(tx.settings.currency).symbol;
  return _formatCompactWith(value, symbol);
}

/// Formato compacto con moneda explícita (para dashboards con moneda mixta).
String formatCompactExplicit(double value,
    {required String currency, required String locale}) {
  final symbol = currencyInfo(currency).symbol;
  return _formatCompactWith(value, symbol);
}

String _formatCompactWith(double value, String symbol) {
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
  return '$sign$symbol$core';
}

String _compactDec(double v) {
  if (v % 1 == 0) return v.toStringAsFixed(0);
  if (v >= 100) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}