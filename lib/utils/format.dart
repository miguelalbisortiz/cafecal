import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';

String formatMoney(BuildContext context, double value, {int decimals = 0}) {
  final tx = context.read<TransactionProvider>();
  return formatAmount(value,
      currency: tx.settings.currency, locale: tx.settings.locale, decimals: decimals);
}

/// Formato de moneda sin contexto — usado por PDF/HTML export.
String formatAmount(double value,
    {required String currency, required String locale, int decimals = 0}) {
  final fmt = NumberFormat.currency(
    locale: locale,
    symbol: currency == 'COP'
        ? '\$'
        : currency == 'USD'
            ? '\$'
            : '€',
    decimalDigits: decimals,
  );
  return fmt.format(value);
}