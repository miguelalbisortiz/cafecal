import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/currencies.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/currency_totals.dart';
import '../utils/format.dart';

class MonthlyTrendChart extends StatelessWidget {
  final int year;

  const MonthlyTrendChart({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;

    final title = Text(
      l10n.chartTitle(year),
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );

    // Moneda mixta en el año: las barras sumarían pesos con dólares y el
    // eje sería mentira. En su lugar se lista el total de cada moneda.
    final yearRecords = tx.transactions
        .where((t) => !t.deleted && t.date.year == year)
        .toList();
    final incomesByCurrency =
        amountsByCurrency(yearRecords, type: TransactionType.income);
    final expensesByCurrency =
        amountsByCurrency(yearRecords, type: TransactionType.expense);
    final currencies = {
      ...incomesByCurrency.keys,
      ...expensesByCurrency.keys,
    }.toList()
      ..sort();
    if (currencies.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          _mixedHint(
            context,
            l10n.currencyMixedHint(currencies.length),
          ),
          const SizedBox(height: 8),
          for (final code in currencies)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                [
                  currencyInfo(code).code,
                  if (incomesByCurrency[code] != null)
                    '${l10n.incomeLabel} '
                    '${formatAmount(incomesByCurrency[code]!, currency: code, locale: tx.settings.locale)}',
                  if (expensesByCurrency[code] != null)
                    '${l10n.expensesLabel} '
                    '${formatAmount(expensesByCurrency[code]!, currency: code, locale: tx.settings.locale)}',
                ].join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      );
    }

    final expenses = _monthlyTotals(tx, TransactionType.expense);
    final incomes = _monthlyTotals(tx, TransactionType.income);

    final maxValue = [
      ...expenses,
      ...incomes,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    final currentIdx = DateTime.now().month - 1;
    final currency = tx.settings.currency;
    final symbol = currencyInfo(currency).symbol;
    final months = l10n.monthShort;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.15,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? l10n.incomeLabel : l10n.expensesLabel}\n'
                      '${formatMoney(context, rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      final isCurrent = idx == currentIdx;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isCurrent ? '${months[idx]}•' : months[idx],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value < 1000) return const SizedBox.shrink();
                      return Text(
                        '$symbol${(value / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(12, (i) {
                final dimmed = i > currentIdx;
                final incomeColor = Colors.green.shade700;
                final expenseColor = Colors.red.shade600;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: incomes[i],
                      color: dimmed
                          ? incomeColor.withOpacity(0.5)
                          : incomeColor,
                      width: 12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    BarChartRodData(
                      toY: expenses[i],
                      color: dimmed
                          ? expenseColor.withOpacity(0.5)
                          : expenseColor,
                      width: 12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendBar(
                color: Colors.green.shade700, label: l10n.incomeLabel),
            const SizedBox(width: 16),
            _LegendBar(
                color: Colors.red.shade600, label: l10n.expensesLabel),
          ],
        ),
      ],
    );
  }

  List<double> _monthlyTotals(
      TransactionProvider provider, TransactionType type) {
    final result = List<double>.filled(12, 0);
    for (final t in provider.transactions) {
      if (t.deleted || t.type != type || t.date.year != year) continue;
      result[t.date.month - 1] += t.amount;
    }
    return result;
  }

  /// Aviso breve de moneda mixta: el gráfico no se dibuja porque las barras
  /// sumarían monedas distintas. Nunca inventa una cifra.
  Widget _mixedHint(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.monetization_on_outlined, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendBar extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendBar({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}