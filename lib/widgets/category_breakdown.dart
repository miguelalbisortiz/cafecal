import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';

class CategoryBreakdown extends StatelessWidget {
  final int year;
  final int? month;
  final TransactionType type;

  const CategoryBreakdown({
    super.key,
    required this.year,
    this.month,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final rows = _groupByCategory(tx);

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Sin registros en este período.'),
      );
    }

    final maxAmount = rows.first.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.isExpense ? 'Gastos por categoría' : 'Ingresos por categoría',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...rows.map((row) {
          final width = (row.amount / maxAmount).clamp(0.04, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row.icon} ${row.label}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      formatMoney(context, row.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: width,
                    minHeight: 8,
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

  List<_CategoryRow> _groupByCategory(TransactionProvider provider) {
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
          ? expenseCategoryLabel(key)
          : incomeCategoryLabel(key);
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