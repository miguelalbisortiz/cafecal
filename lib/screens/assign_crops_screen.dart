import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';
import '../widgets/new_crop_dialog.dart';

/// Asignación rápida de cultivo a los registros que quedaron sin uno.
/// Cada fila tiene un selector; los cambios se aplican juntos con "Guardar".
class AssignCropsScreen extends StatefulWidget {
  const AssignCropsScreen({super.key});

  @override
  State<AssignCropsScreen> createState() => _AssignCropsScreenState();
}

class _AssignCropsScreenState extends State<AssignCropsScreen> {
  static const _newCropOption = '__new__';

  /// txId -> cultivo elegido (null vuelve a "Sin cultivo").
  final Map<String, String?> _pending = {};

  Future<void> _onSelect(Transaction t, String? value) async {
    if (value == _newCropOption) {
      final tx = context.read<TransactionProvider>();
      final name = await showDialog<String>(
        context: context,
        builder: (_) => NewCropDialog(
          existingNames: tx.crops.map((c) => c.name).toList(),
        ),
      );
      if (name == null || !mounted) return;
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      final matched = tx.crops
          .where((c) => c.name.toLowerCase() == trimmed.toLowerCase())
          .toList();
      if (matched.isNotEmpty) {
        setState(() => _pending[t.id] = matched.first.id);
        return;
      }
      final crop = await tx.addCrop(trimmed);
      if (!mounted) return;
      setState(() => _pending[t.id] = crop.id);
      return;
    }
    setState(() {
      _pending[t.id] = value;
    });
  }

  Future<void> _save() async {
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final t in tx.transactions) t.id: t};
    var saved = 0;
    for (final entry in _pending.entries) {
      final current = byId[entry.key];
      if (current == null || current.cropId == entry.value) continue;
      await tx.updateTransaction(current.copyWith(cropId: entry.value));
      saved++;
    }
    if (!mounted) return;
    if (saved > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.assignCropsSaved('$saved')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final unassigned = tx.transactions
        .where((t) => !t.deleted && t.cropId == null)
        .toList()
      ..sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assignCropsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: unassigned.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 48, color: Colors.green),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.assignCropsEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        l10n.assignCropsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.assignCropsBanner('${unassigned.length}'),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: unassigned.length,
                        itemBuilder: (context, i) =>
                            _row(unassigned[i], tx, l10n),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed:
                              _pending.isEmpty ? null : _save,
                          icon: const Icon(Icons.check),
                          label: Text(l10n.assignCropsSave),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(Transaction t, TransactionProvider tx, AppLocalizations l10n) {
    final isExpense = t.type.isExpense;
    final label = isExpense
        ? l10n.expenseCategory(t.category)
        : l10n.incomeCategory(t.category);
    final selected = _pending[t.id] ?? t.cropId;
    final scheme = Theme.of(context).colorScheme;
    final dateStr = '${t.date.day.toString().padLeft(2, '0')}/'
        '${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isExpense ? scheme.errorContainer : scheme.primaryContainer,
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? scheme.error : scheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr · '
                    '${formatMoney(context, isExpense ? -t.amount : t.amount)}'
                        '${t.description.isNotEmpty ? ' · ${t.description}' : ''}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String?>(
                value: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.assignCropsUnassigned),
                  ),
                  DropdownMenuItem<String?>(
                    value: _newCropOption,
                    child: Text(l10n.assignCropsNewCrop),
                  ),
                  ...tx.crops.map((c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text('${c.icon} ${c.name}',
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => _onSelect(t, v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}