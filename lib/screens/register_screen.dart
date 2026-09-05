import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/new_crop_dialog.dart';

class RegisterScreen extends StatefulWidget {
  final Transaction? editing;

  const RegisterScreen({super.key, this.editing});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _newCropOption = '__new__';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _category;
  String? _cropId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _amountController.text = (e.amount % 1 == 0)
          ? e.amount.toInt().toString()
          : e.amount.toString();
      _descriptionController.text = e.description;
      _type = e.type;
      _category = e.category;
      _cropId = e.cropId;
      _date = e.date;
    } else {
      // Preselecciona el último cultivo usado para agilizar los gastos
      // recurrentes del mismo cultivo. Solo si aún existe.
      final provider = context.read<TransactionProvider>();
      final last = provider.settings.lastCropId;
      if (last != null && provider.crops.any((c) => c.id == last)) {
        _cropId = last;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCrop() async {
    final tx = context.read<TransactionProvider>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => NewCropDialog(
        existingNames: tx.crops.map((c) => c.name).toList(),
      ),
    );
    if (!mounted) return;
    final n = name?.trim() ?? '';
    if (n.isEmpty) {
      setState(() {});
      return;
    }
    final matched = tx.crops
        .where((c) => c.name.toLowerCase() == n.toLowerCase())
        .toList();
    if (matched.isNotEmpty) {
      setState(() => _cropId = matched.first.id);
      return;
    }
    final crop = await tx.addCrop(n);
    if (!mounted) return;
    setState(() => _cropId = crop.id);
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: l10n.datePickerHelp,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final editing = widget.editing;
    if (editing != null) {
      await tx.updateTransaction(editing.copyWith(
        type: _type,
        category: _category ?? 'otro',
        cropId: _cropId,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _date,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.recordUpdated),
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
      return;
    }

    await tx.addTransaction(
      type: _type,
      category: _category ?? 'otro',
      cropId: _cropId,
      amount: amount,
      description: _descriptionController.text.trim(),
      date: _date,
    );

    // Recuerda el cultivo elegido para preseleccionarlo la próxima vez.
    // Null (= "Sin cultivo") limpia el recordatorio.
    await tx.updateSettings(tx.settings.copyWith(lastCropId: _cropId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.recordSaved),
        duration: const Duration(seconds: 1),
      ),
    );
    _descriptionController.clear();
    _amountController.clear();
  }

  Future<void> _confirmDelete() async {
    final editing = widget.editing;
    if (editing == null) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        content: Text(l10n.deleteDialogBody),
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
    await tx.deleteTransaction(editing.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.recordDeleted),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final crops = tx.crops;
    final isExpense = _type.isExpense;
    final categories = isExpense
        ? expenseCategories
            .map((c) => (key: c.key, icon: c.icon, name: l10n.expenseCategory(c.key)))
            .toList()
        : incomeCategories
            .map((c) => (key: c.key, icon: c.icon, name: l10n.incomeCategory(c.key)))
            .toList();

    final form = Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.editing != null ? l10n.registerEditTitle : l10n.tabRegister,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Tipo: gasto o ingreso
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text(l10n.expenseTypeLabel),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text(l10n.incomeTypeLabel),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _category = null;
            }),
          ),
          const SizedBox(height: 16),

          // Cultivo
          DropdownButtonFormField<String>(
            value: _cropId,
            decoration: InputDecoration(
              labelText: l10n.cropFieldLabel,
              prefixIcon: const Icon(Icons.grass_outlined),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(l10n.cropUnspecified),
              ),
              DropdownMenuItem<String>(
                value: _newCropOption,
                child: Text(l10n.cropNewOption),
              ),
              ...crops.map((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text('${c.icon} ${c.name}'),
                  )),
            ],
            onChanged: (v) {
              if (v == _newCropOption) {
                _createCrop();
              } else {
                setState(() => _cropId = v);
              }
            },
          ),
          const SizedBox(height: 4),
          Text(
            l10n.cropGroupHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Categoría
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: l10n.categoryFieldLabel,
              prefixIcon: const Icon(Icons.category_outlined),
              border: const OutlineInputBorder(),
            ),
            items: categories
                .map((c) => DropdownMenuItem<String>(
                      value: c.key,
                      child: Text('${c.icon} ${c.name}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),

          // Monto
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.amountFieldLabel,
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n <= 0) return l10n.amountInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Fecha
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.dateFieldLabel,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                MaterialLocalizations.of(context).formatShortDate(_date),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.descriptionFieldLabel,
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.notes),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(widget.editing != null ? l10n.saveChanges : l10n.saveRecord),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _type.isExpense ? l10n.expenseFootnote : l10n.incomeFootnote,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          ],
        ),
        ),
        ),
    );
    if (widget.editing != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.registerEditTitle),
          actions: [
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: form,
      );
    }
    return form;
  }
}