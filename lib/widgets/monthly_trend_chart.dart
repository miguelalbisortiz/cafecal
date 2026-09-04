import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';

class MonthlyTrendChart extends StatelessWidget {
  final int year;

  const MonthlyTrendChart({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final expenses = _monthlyTotals(tx, TransactionType.expense);
    final incomes = _monthlyTotals(tx, TransactionType.income);

    final maxValue = [
      ...expenses,
      ...incomes,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gastos vs ingresos — $year',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
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
                      '${isIncome ? "Ingresos" : "Gastos"}\n'
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
                      const months = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      final idx = value.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          months[idx],
                          style: const TextStyle(fontSize: 11),
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
                        '${(value / 1000).toStringAsFixed(0)}k',
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
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: incomes[i],
                      color: Colors.green.shade600,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: expenses[i],
                      color: Colors.red.shade400,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
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
            _LegendDot(color: Colors.green.shade600, label: 'Ingresos'),
            const SizedBox(width: 16),
            _LegendDot(color: Colors.red.shade400, label: 'Gastos'),
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
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}