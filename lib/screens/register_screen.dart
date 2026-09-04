import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categories.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _category;
  String? _cropId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Fecha del registro',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tx = context.read<TransactionProvider>();
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    await tx.addTransaction(
      type: _type,
      category: _category ?? 'otro',
      cropId: _cropId,
      amount: amount,
      description: _descriptionController.text.trim(),
      date: _date,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro guardado'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    _descriptionController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final crops = tx.crops;
    final isExpense = _type.isExpense;
    final categories = isExpense
        ? expenseCategories.map((c) => (key: c.key, icon: c.icon, name: c.name)).toList()
        : incomeCategories.map((c) => (key: c.key, icon: c.icon, name: c.name)).toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Registrar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Tipo: gasto o ingreso
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Gasto'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Ingreso'),
                icon: Icon(Icons.add_circle_outline),
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
            decoration: const InputDecoration(
              labelText: 'Cultivo (opcional)',
              prefixIcon: Icon(Icons.grass_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Sin especificar'),
              ),
              ...crops.map((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text('${c.icon} ${c.name}'),
                  )),
            ],
            onChanged: (v) => setState(() => _cropId = v),
          ),
          const SizedBox(height: 16),

          // Categoría
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
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
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n <= 0) return 'Ingresa un monto válido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Fecha
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
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
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Guardar registro'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _type.isExpense
                ? 'Vas a registrar un GASTO. El monto se usará en tu resumen del mes.'
                : 'Vas a registrar un INGRESO. El monto se usará en tu resumen del mes.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}