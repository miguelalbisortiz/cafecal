import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/employee.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';
import '../widgets/employee_editor_dialog.dart';

/// Gestión de trabajadores (lista fija): crear/editar/eliminar con valor por
/// día opcional. Los jornales históricos guardan el nombre como snapshot en
/// `transactions.provider`, por eso borrar un trabajador no toca el historial.
class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuWorkers)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.workerNewOption),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: tx.employees.isEmpty
              ? Center(child: Text(l10n.workersEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: tx.employees.length,
                  itemBuilder: (context, i) =>
                      _row(context, tx, tx.employees[i], l10n),
                ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final tx = context.read<TransactionProvider>();
    final form = await showDialog<EmployeeFormData>(
      context: context,
      builder: (_) => EmployeeEditorDialog(
        existingNames: tx.employees.map((e) => e.name).toList(),
      ),
    );
    if (form == null) return;
    await tx.addEmployee(form.name, dayRate: form.dayRate);
  }

  Future<void> _edit(BuildContext context, TransactionProvider tx,
      Employee employee) async {
    final form = await showDialog<EmployeeFormData>(
      context: context,
      builder: (_) => EmployeeEditorDialog(
        employee: employee,
        existingNames: tx.employees.map((e) => e.name).toList(),
      ),
    );
    if (form == null || !context.mounted) return;
    await tx.updateEmployee(
        employee.copyWith(name: form.name, dayRate: form.dayRate));
  }

  Future<void> _confirmDelete(BuildContext context, TransactionProvider tx,
      Employee employee) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workerConfirmDelete),
        content: Text(l10n.deleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await tx.deleteEmployee(employee.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.workerDeleted),
      duration: const Duration(seconds: 1),
    ));
  }

  /// Meses (aaaa-mm) con jornales de este trabajador, del más reciente al
  /// más antiguo. Usa el nombre snapshot de `provider` (decisión del plan).
  List<DateTime> _workedMonths(TransactionProvider tx, String name) {
    final seen = <String>{};
    final months = <DateTime>[];
    for (final t in tx.transactions) {
      if (t.deleted || t.type != TransactionType.expense) continue;
      if (t.category != 'mano_obra') continue;
      if (t.provider != name) continue;
      final month = DateTime(t.date.year, t.date.month);
      if (seen.add('${month.year}-${month.month}')) months.add(month);
    }
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  Widget _row(BuildContext context, TransactionProvider tx, Employee employee,
      AppLocalizations l10n) {
    final rateLine = employee.dayRate == null
        ? l10n.workerNoRate
        : '${l10n.workerDayRateShort}: ${formatMoney(context, employee.dayRate!)}';

    final months = _workedMonths(tx, employee.name);
    final workedLine = months.isEmpty
        ? l10n.workerNoJornales
        : '${l10n.workerWorkedIn}: '
            '${months.map((m) => '${l10n.monthShort[m.month - 1]} ${m.year}').join(', ')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person_outline),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rateLine, style: const TextStyle(fontSize: 12)),
            Text(workedLine, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _edit(context, tx, employee),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(context, tx, employee),
            ),
          ],
        ),
      ),
    );
  }
}
