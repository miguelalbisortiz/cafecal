import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/employee.dart';

/// Editor de trabajador (crear y editar): nombre + valor por día opcional.
/// Al confirmar devuelve los valores editados (patrón CropEditorDialog).
class EmployeeEditorDialog extends StatefulWidget {
  final Employee? employee;
  final List<String> existingNames;

  const EmployeeEditorDialog({
    super.key,
    this.employee,
    required this.existingNames,
  });

  @override
  State<EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<EmployeeEditorDialog> {
  final _nameController = TextEditingController();
  final _dayRateController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    if (e != null) {
      _nameController.text = e.name;
      if (e.dayRate != null) _dayRateController.text = e.dayRate.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayRateController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = _nameController.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.workerNameRequired);
      return;
    }
    final dup = widget.existingNames.any(
        (e) => e.toLowerCase() == n.toLowerCase() && e != widget.employee?.name);
    if (dup) {
      setState(() => _error = l10n.workerNameRequired);
      return;
    }
    final rateText = _dayRateController.text.trim().replaceAll(',', '.');
    double? rate;
    if (rateText.isNotEmpty) {
      rate = double.tryParse(rateText);
      if (rate == null || rate < 0) {
        setState(() => _error = l10n.amountInvalid);
        return;
      }
    }
    Navigator.pop(context, EmployeeFormData(name: n, dayRate: rate));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.employee != null;
    return AlertDialog(
      title: Text(editing ? l10n.editWorkerTitle : l10n.newWorkerDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.workerNameLabel,
                errorText: _error,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dayRateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.workerDayRateLabel,
                helperText: l10n.helpWorkerDayRate,
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpWorkerDayRate,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? l10n.saveChanges : l10n.add),
        ),
      ],
    );
  }
}

class EmployeeFormData {
  final String name;
  final double? dayRate;

  const EmployeeFormData({required this.name, this.dayRate});
}
