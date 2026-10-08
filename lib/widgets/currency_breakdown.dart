import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/currencies.dart';
import '../utils/format.dart';

/// Totales de un período **separados por moneda**: ingresos, gastos y
/// resultado de cada moneda, con su código a la vista.
///
/// Se usa en vez de una cifra global cuando el período mezcla monedas, para
/// no imprimir un balance falso sumando pesos con dólares.
class CurrencyBreakdown extends StatelessWidget {
  final Map<String, double> incomes;
  final Map<String, double> expenses;
  final AppLocalizations l10n;
  final String locale;

  /// Título del bloque. Si es null usa `currencyMixedHint(n)`.
  final String? title;

  const CurrencyBreakdown({
    super.key,
    required this.incomes,
    required this.expenses,
    required this.l10n,
    required this.locale,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = {...incomes.keys, ...expenses.keys}.toList()..sort();
    final scheme = Theme.of(context).colorScheme;
    final heading =
        title ?? l10n.currencyMixedHint(currencies.length);

    Widget line(String label, String value,
        {Color? color, bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? scheme.onSurfaceVariant,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? scheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    String money(double v, String currency) =>
        formatAmount(v, currency: currency, locale: locale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_outlined,
                  size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final currency in currencies) ...[
            if (currency != currencies.first) const SizedBox(height: 8),
            Text(
              '${currencyInfo(currency).code} · ${currencyInfo(currency).name}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            line(
              l10n.incomeLabel,
              money(incomeOf(currency), currency),
              color: scheme.primary,
            ),
            line(
              l10n.expensesLabel,
              money(-expenseOf(currency), currency),
              color: scheme.error,
            ),
            line(
              l10n.resultLabel,
              money(resultOf(currency), currency),
              color: resultOf(currency) < 0 ? scheme.error : scheme.primary,
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  double incomeOf(String currency) => incomes[currency] ?? 0;

  double expenseOf(String currency) => expenses[currency] ?? 0;

  double resultOf(String currency) => incomeOf(currency) - expenseOf(currency);
}
