import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';

String formatMoney(BuildContext context, double value, {int decimals = 0}) {
  final tx = context.read<TransactionProvider>();
  final currency = tx.settings.currency;
  final locale = tx.settings.locale;
  final fmt = NumberFormat.currency(
    locale: locale,
    symbol: _symbolFor(currency),
    decimalDigits: decimals,
  );
  return fmt.format(value);
}

String _symbolFor(String currency) {
  switch (currency) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    default:
      return '\$';
  }
}