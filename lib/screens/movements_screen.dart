import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';
import 'register_screen.dart';

enum _PeriodMode { month, year, all }

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  _PeriodMode _mode = _PeriodMode.all;
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;

  bool _matches(Transaction t) => switch (_mode) {
        _PeriodMode.month =>
          t.date.year == _year && t.date.month == _month,
        _PeriodMode.year => t.date.year == _year,
        _PeriodMode.all => true,
      };

  String _periodLabel(AppLocalizations l10n) => switch (_mode) {
        _PeriodMode.month => l10n.reportChipMonth(
            l10n.monthFull[_month - 1], _year),
        _PeriodMode.year => l10n.yearLabel(_year),
        _PeriodMode.all => l10n.allMovementsLabel,
      };

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final nameById = {for (final c in tx.crops) c.id: c.name};

    final records = tx.transactions.where((t) => !t.deleted).toList()
      ..sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
      });
    final filtered = records.where(_matches).toList();

    double totalsIn = 0;
    double totalsOut = 0;
    for (final t in filtered) {
      if (t.type.isExpense) {
        totalsOut += t.amount;
      } else {
        totalsIn += t.amount;
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tabHistory,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SegmentedButton<_PeriodMode>(
                    segments: [
                      ButtonSegment(
                        value: _PeriodMode.month,
                        label: Text(l10n.segMonth),
                        icon: const Icon(Icons.calendar_view_month_outlined),
                      ),
                      ButtonSegment(
                        value: _PeriodMode.year,
                        label: Text(l10n.segYear),
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                      ButtonSegment(
                        value: _PeriodMode.all,
                        label: Text(l10n.segAll),
                        icon: const Icon(Icons.view_list_outlined),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() {
                      _mode = s.first;
                      final now = DateTime.now();
                      _year = now.year;
                      _month = now.month;
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _periodLabel(l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Builder(
                      builder: (context) {
                        final scheme = Theme.of(context).colorScheme;
                        return Row(
                          children: [
                            Expanded(
                              child: _miniStat(l10n.incomeLabel, totalsIn,
                                  scheme.primary),
                            ),
                            Expanded(
                              child: _miniStat(
                                  l10n.expensesLabel, totalsOut, scheme.error),
                            ),
                            Expanded(
                              child: _miniStat(
                                  l10n.resultLabel, totalsIn - totalsOut,
                                  totalsIn - totalsOut >= 0
                                      ? scheme.primary
                                      : scheme.error),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(l10n.noMovements))
                  : _groupedList(filtered, nameById, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          formatMoney(context, value),
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _groupedList(List<Transaction> records, Map<String, String> nameById,
      AppLocalizations l10n) {
    final groups = <String, List<Transaction>>{};
    for (final t in records) {
      final key = '${t.date.year}-${t.date.month}';
      groups.putIfAbsent(key, () => []).add(t);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        for (final key in keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              '${l10n.monthFull[groups[key]!.first.date.month - 1]} '
              '${groups[key]!.first.date.year}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ...groups[key]!.map((t) => _row(t, nameById, l10n)),
        ],
      ],
    );
  }

  Widget _row(Transaction t, Map<String, String> nameById, AppLocalizations l10n) {
    final isExpense = t.type.isExpense;
    final label = isExpense
        ? l10n.expenseCategory(t.category)
        : l10n.incomeCategory(t.category);
    final cropName = t.cropId == null
        ? null
        : nameById[t.cropId] ?? t.cropId!;
    final dateStr = '${t.date.day.toString().padLeft(2, '0')}/'
        '${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';

    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? scheme.errorContainer
              : scheme.primaryContainer,
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? scheme.error : scheme.primary,
            size: 20,
          ),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            dateStr,
            if (t.description.isNotEmpty) t.description,
            if (cropName != null) cropName,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMoney(context, isExpense ? -t.amount : t.amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isExpense ? scheme.error : scheme.primary,
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(t),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RegisterScreen(editing: t),
        )),
      ),
    );
  }

  Future<void> _confirmDelete(Transaction t) async {
    final amountText = formatMoney(context, t.amount);
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        content: Text(t.type.isExpense
            ? l10n.confirmDeleteExpense(amountText)
            : l10n.confirmDeleteIncome(amountText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final tx = context.read<TransactionProvider>();
    await tx.deleteTransaction(t.id);
  }
}