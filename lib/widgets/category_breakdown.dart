import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';

class CategoryBreakdown extends StatelessWidget {
  final int year;
  final int? month;
  final TransactionType type;
  final String? periodLabel;
  final VoidCallback? onAddTap;

  const CategoryBreakdown({
    super.key,
    required this.year,
    this.month,
    required this.type,
    this.periodLabel,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final rows = _groupByCategory(tx, l10n);

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              type.isExpense
                  ? Icons.trending_down
                  : Icons.payments_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              type.isExpense ? l10n.noExpensesPeriod : l10n.noIncomesPeriod,
            ),
            if (onAddTap != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add),
                label: Text(
                    type.isExpense ? l10n.recordExpense : l10n.recordIncome),
              ),
            ],
          ],
        ),
      );
    }

    final total = rows.fold<double>(0, (s, r) => s + r.amount);
    final maxAmount = rows.first.amount;
    final typeColor =
        type.isExpense ? Colors.red.shade600 : Colors.green.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                type.isExpense
                    ? l10n.expensesByCategory
                    : l10n.incomesByCategory,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (periodLabel != null)
              Text(
                periodLabel!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.categoryBreakdownTotal(formatMoney(context, total)),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...rows.map((row) {
          final width = (row.amount / maxAmount).clamp(0.04, 1.0);
          final pct = total > 0 ? row.amount / total * 100 : 0.0;
          final pctText =
              pct >= 10 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row.icon} ${row.label}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$pctText%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: row.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMoney(context, row.amount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: width,
                    minHeight: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(row.color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<_CategoryRow> _groupByCategory(
      TransactionProvider provider, AppLocalizations l10n) {
    final records = provider.where(type: type, year: year, month: month);
    final totals = <String, double>{};
    for (final t in records) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }

    final rows = totals.entries.map((e) {
      final key = e.key;
      final isExpense = type.isExpense;
      final icon = isExpense
          ? (expenseCategories.firstWhere((c) => c.key == key,
                  orElse: () => const ExpenseCategory(
                      key: 'otro', name: 'Otro', icon: '📦', color: '#757575')))
              .icon
          : (incomeCategories.firstWhere((c) => c.key == key,
                  orElse: () => const IncomeCategory(
                      key: 'venta_otro',
                      name: 'Venta otros',
                      icon: '💰',
                      color: '#2E7D32')))
              .icon;
      final color = isExpense
          ? expenseCategories
              .firstWhere((c) => c.key == key,
                  orElse: () => const ExpenseCategory(
                      key: 'otro', name: 'Otro', icon: '📦', color: '#757575'))
              .color
          : incomeCategories
              .firstWhere((c) => c.key == key,
                  orElse: () => const IncomeCategory(
                      key: 'venta_otro',
                      name: 'Venta otros',
                      icon: '💰',
                      color: '#2E7D32'))
              .color;
      final label = isExpense
          ? l10n.expenseCategory(key)
          : l10n.incomeCategory(key);
      return _CategoryRow(
        label: label,
        icon: icon,
        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
        amount: e.value,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return rows;
  }
}

class _CategoryRow {
  final String label;
  final String icon;
  final Color color;
  final double amount;

  const _CategoryRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.amount,
  });
}