import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/categories.dart';
import '../models/currencies.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format.dart';
import '../widgets/new_crop_dialog.dart';
import '../widgets/employee_editor_dialog.dart';

class RegisterScreen extends StatefulWidget {
  final Transaction? editing;

  /// Tipo prefijado al abrir la pantalla (Gasto/Ingreso). Solo aplica cuando
  /// no se está editando un registro existente.
  final TransactionType? initialType;

  const RegisterScreen({super.key, this.editing, this.initialType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _newCropOption = '__new__';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _clientController = TextEditingController();
  final _providerController = TextEditingController();

  static const _jornalOtherOption = '__other__';
  static const _jornalCreateOption = '__create__';

  final _jornalOtherNameController = TextEditingController();
  final _jornalDaysController = TextEditingController();
  final _jornalRateController = TextEditingController();
  String? _jornalWorkerValue;
  int _jornalDropKey = 0;

  TransactionType _type = TransactionType.expense;
  String? _category;
  String? _cropId;
  String? _unit;
  String? _harvestId;
  String _currency = 'COP';
  DateTime _date = DateTime.now();

  static const _saleCategories = {
    'venta_cafe',
    'venta_platano',
    'venta_otro',
  };

  /// Gasto de mano de obra: activa el bloque jornal (trabajador + días ×
  /// valor día) y bloquea el campo Monto (se calcula solo).
  bool get _isJornal =>
      _type == TransactionType.expense && _category == 'mano_obra';

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
      _unit = e.unit;
      _currency = e.currency;
      _harvestId = e.harvestId;
      if (e.quantity != null) {
        _quantityController.text = (e.quantity! % 1 == 0)
            ? e.quantity!.toInt().toString()
            : e.quantity!.toString();
      }
      if (e.client != null) _clientController.text = e.client!;
      if (e.provider != null) _providerController.text = e.provider!;
      // Jornal: restaurar trabajador, días y valor día desde el snapshot.
      if (e.type == TransactionType.expense && e.category == 'mano_obra') {
        if (e.quantity != null) {
          _jornalDaysController.text = (e.quantity! % 1 == 0)
              ? e.quantity!.toInt().toString()
              : e.quantity!.toString();
          // Los días viven en el bloque jornal, no en el campo de ventas.
          _quantityController.clear();
        }
        final rate = e.pricePerUnit ??
            ((e.quantity != null && e.quantity! > 0)
                ? e.amount / e.quantity!
                : null);
        if (rate != null) {
          _jornalRateController.text =
              (rate % 1 == 0) ? rate.toInt().toString() : rate.toString();
        }
        final name = e.provider?.trim();
        if (name != null && name.isNotEmpty) {
          final tx = context.read<TransactionProvider>();
          final match = tx.employees
              .where((emp) => emp.name.toLowerCase() == name.toLowerCase())
              .toList();
          if (match.isNotEmpty) {
            _jornalWorkerValue = match.first.id;
          } else {
            // El trabajador ya no está en la lista: conservar el nombre
            // snapshot como "Otro nombre…" (sin romper el registro).
            _jornalWorkerValue = _jornalOtherOption;
            _jornalOtherNameController.text = name;
          }
        }
      }
    } else {
      // Preselecciona el último cultivo usado para agilizar los gastos
      // recurrentes del mismo cultivo. Solo si aún existe.
      final provider = context.read<TransactionProvider>();
      final last = provider.settings.lastCropId;
      if (last != null && provider.crops.any((c) => c.id == last)) {
        _cropId = last;
      }
      _currency = provider.settings.currency;
      if (widget.initialType != null) {
        _type = widget.initialType!;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _clientController.dispose();
    _providerController.dispose();
    _jornalOtherNameController.dispose();
    _jornalDaysController.dispose();
    _jornalRateController.dispose();
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
    final crop = await tx.addCrop(n, currency: _currency);
    if (!mounted) return;
    setState(() => _cropId = crop.id);
  }

  /// Reconstruye el campo Monto con días × valor por día cuando el bloque
  /// jornal está completo. No toca el monto si faltan datos.
  void _recalcJornalAmount() {
    final days = double.tryParse(
        _jornalDaysController.text.trim().replaceAll(',', '.'));
    final rate = double.tryParse(
        _jornalRateController.text.trim().replaceAll(',', '.'));
    if (days == null || days <= 0 || rate == null || rate <= 0) return;
    final total = days * rate;
    final text = total % 1 == 0 ? total.toInt().toString() : total.toString();
    if (_amountController.text != text) {
      _amountController.text = text;
    }
  }

  /// Abre el diálogo "Crear trabajador" desde el dropdown del bloque jornal.
  Future<void> _createJornalWorker() async {
    final tx = context.read<TransactionProvider>();
    final form = await showDialog<EmployeeFormData>(
      context: context,
      builder: (_) => EmployeeEditorDialog(
        existingNames: tx.employees.map((e) => e.name).toList(),
      ),
    );
    if (!mounted) return;
    if (form == null) {
      // Reinicia el dropdown para no quedarse en "Crear trabajador…".
      setState(() => _jornalDropKey++);
      return;
    }
    final employee = await tx.addEmployee(form.name, dayRate: form.dayRate);
    if (!mounted) return;
    setState(() {
      _jornalWorkerValue = employee.id;
      _jornalDropKey++;
      if (employee.dayRate != null) {
        final r = employee.dayRate!;
        _jornalRateController.text =
            (r % 1 == 0) ? r.toInt().toString() : r.toString();
      }
      _recalcJornalAmount();
    });
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
    final isSale = _type == TransactionType.income &&
        _saleCategories.contains(_category);
    double amount;
    double? quantity;
    String? unit;
    double? pricePerUnit;
    String? client;
    String? provider;
    if (_isJornal) {
      // Bloque jornal: total = días × valor día (Monto es solo lectura).
      final days = double.parse(
          _jornalDaysController.text.trim().replaceAll(',', '.'));
      final rate = double.parse(
          _jornalRateController.text.trim().replaceAll(',', '.'));
      amount = days * rate;
      quantity = days;
      unit = 'día';
      pricePerUnit = rate;
      final v = _jornalWorkerValue;
      if (v == _jornalOtherOption) {
        provider = _jornalOtherNameController.text.trim();
      } else if (v != null) {
        final match = tx.employees.where((e) => e.id == v).toList();
        provider = match.isEmpty ? null : match.first.name;
      } else {
        provider = null;
      }
      client = null;
    } else {
      amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final qtyText = _quantityController.text.trim().replaceAll(',', '.');
      quantity = qtyText.isEmpty ? null : double.tryParse(qtyText);
      unit = (isSale && quantity != null) ? (_unit ?? 'kg') : null;
      client = isSale ? _clientController.text.trim() : null;
      provider = _type == TransactionType.expense
          ? _providerController.text.trim()
          : null;
    }
    final harvestId = _type == TransactionType.expense ? _harvestId : null;

    final editing = widget.editing;
    if (editing != null) {
      // Construimos el objeto directamente (no copyWith) para que los campos
      // nullable de producción se puedan LIMPIAR con null al cambiar de tipo
      // o categoría (p.ej. una venta convertida en gasto).
      await tx.updateTransaction(Transaction(
        id: editing.id,
        cropId: _cropId,
        type: _type,
        category: _category ?? 'otro',
        amount: amount,
        currency: _currency,
        description: _descriptionController.text.trim(),
        date: _date,
        createdAt: editing.createdAt,
        deleted: editing.deleted,
        pendingSync: true,
        quantity: quantity,
        unit: unit,
        pricePerUnit: pricePerUnit,
        client: client,
        provider: provider,
        harvestId: harvestId,
        sowingId: editing.sowingId,
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
      currency: _currency,
      description: _descriptionController.text.trim(),
      date: _date,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      client: client,
      provider: provider,
      harvestId: harvestId,
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
    _quantityController.clear();
    _clientController.clear();
    _providerController.clear();
    _jornalOtherNameController.clear();
    _jornalDaysController.clear();
    _jornalRateController.clear();
    setState(() {
      _unit = (isSale && quantity != null) ? _unit : null;
      _jornalWorkerValue = null;
    });
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

  String _effectiveUnit(TransactionProvider tx) {
    // Si el usuario no eligió unidad y el cultivo tiene una preferida, la usa.
    // Una transacción guardada conserva su unidad almacenada.
    if (_unit != null) return _unit!;
    if (_cropId != null) {
      final matches = tx.crops.where((c) => c.id == _cropId).toList();
      if (matches.isNotEmpty && matches.first.defaultUnit != null) {
        return matches.first.defaultUnit!;
      }
    }
    return 'kg';
  }

  /// Cosechas del cultivo activo ordenadas de más reciente a más antigua,
  /// usadas para vincular el gasto con una cosecha.
  List<Harvest> _linkedHarvests(TransactionProvider tx) {
    if (_cropId == null) return const [];
    final list = tx.harvestsFor(_cropId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
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
                setState(() {
                  _cropId = v;
                  _unit = null;
                  _harvestId = null;
                  // Auto-usa la moneda del cultivo seleccionado
                  if (v != null) {
                    final match = tx.crops.where((c) => c.id == v).toList();
                    if (match.isNotEmpty && match.first.currency != null) {
                      _currency = match.first.currency!;
                    }
                  }
                });
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

          // Datos de producción (solo ventas de café/plátano/otro)
          if (_type == TransactionType.income &&
              _saleCategories.contains(_category)) ...[
            _ProdSectionHeader(label: l10n.prodSectionTitle),
            const SizedBox(height: 12),

            // Cantidad vendida
            TextFormField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.quantityFieldLabel,
                prefixIcon: const Icon(Icons.scale_outlined),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Unidad
            DropdownButtonFormField<String>(
              value: _effectiveUnit(tx),
              decoration: InputDecoration(
                labelText: l10n.unitFieldLabel,
                prefixIcon: const Icon(Icons.category_outlined),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'kg', child: Text(l10n.unitKg)),
                DropdownMenuItem(value: 'lb', child: Text(l10n.unitLb)),
                DropdownMenuItem(value: 'arroba', child: Text(l10n.unitArroba)),
                DropdownMenuItem(value: 'saco', child: Text(l10n.unitSaco)),
                DropdownMenuItem(value: 'carga', child: Text(l10n.unitCarga)),
                DropdownMenuItem(value: 'racimo', child: Text(l10n.unitRacimo)),
                DropdownMenuItem(value: 'cajon', child: Text(l10n.unitCajon)),
              ],
              onChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 12),

            // Cliente / comprador
            TextFormField(
              controller: _clientController,
              decoration: InputDecoration(
                labelText: l10n.clientFieldLabel,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Precio por unidad (auto)
            _PricePerUnitInfo(
              amount: double.tryParse(
                  _amountController.text.trim().replaceAll(',', '.')),
              quantity: double.tryParse(
                  _quantityController.text.trim().replaceAll(',', '.')),
              unit: _unit,
              currency: _currency,
              locale: tx.settings.locale,
              l10n: l10n,
            ),
            const SizedBox(height: 16),
          ],

          // Proveedor / Jornal (solo gastos)
          if (_type == TransactionType.expense) ...[
            _ProdSectionHeader(
                label:
                    _isJornal ? l10n.jornalSectionTitle : l10n.providerFieldLabel),
            const SizedBox(height: 12),

            if (_isJornal) ...[
              // Trabajador (dropdown de la lista + Otro nombre… + Crear…)
              DropdownButtonFormField<String>(
                key: ValueKey('jornal-$_jornalWorkerValue-$_jornalDropKey'),
                value: _jornalWorkerValue,
                decoration: InputDecoration(
                  labelText: l10n.jornalWorkerLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  hintText:
                      tx.employees.isEmpty ? l10n.jornalWorkerHint : null,
                ),
                items: [
                  ...tx.employees.map((e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(e.name),
                      )),
                  DropdownMenuItem<String>(
                    value: _jornalOtherOption,
                    child: Text(l10n.jornalOtherNameOption),
                  ),
                  DropdownMenuItem<String>(
                    value: _jornalCreateOption,
                    child: Text(l10n.jornalCreateOption),
                  ),
                ],
                validator: (v) {
                  if (v == null) return l10n.jornalWorkerRequired;
                  if (v == _jornalOtherOption &&
                      _jornalOtherNameController.text.trim().isEmpty) {
                    return l10n.workerNameRequired;
                  }
                  return null;
                },
                onChanged: (v) {
                  if (v == _jornalCreateOption) {
                    _createJornalWorker();
                    return;
                  }
                  setState(() {
                    _jornalWorkerValue = v;
                    if (v != null &&
                        v != _jornalOtherOption &&
                        v != _jornalCreateOption) {
                      final match = tx.employees
                          .where((e) => e.id == v)
                          .toList();
                      if (match.isNotEmpty &&
                          match.first.dayRate != null) {
                        final r = match.first.dayRate!;
                        _jornalRateController.text =
                            (r % 1 == 0) ? r.toInt().toString() : r.toString();
                      }
                    }
                    _recalcJornalAmount();
                  });
                },
              ),
              if (_jornalWorkerValue == _jornalOtherOption) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jornalOtherNameController,
                  decoration: InputDecoration(
                    labelText: l10n.workerNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 12),

              // Días trabajados
              TextFormField(
                controller: _jornalDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.jornalDaysLabel,
                  prefixIcon: const Icon(Icons.today_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return l10n.jornalDaysRequired;
                  return null;
                },
                onChanged: (_) => setState(_recalcJornalAmount),
              ),
              const SizedBox(height: 12),

              // Valor por día (autocompletado desde la ficha)
              TextFormField(
                controller: _jornalRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.workerDayRateShort,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse(
                      (v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return l10n.jornalRateRequired;
                  return null;
                },
                onChanged: (_) => setState(_recalcJornalAmount),
              ),
              const SizedBox(height: 8),

              // Total = días × valor día (reflejado en el campo Monto)
              _JornalTotalInfo(
                days: double.tryParse(_jornalDaysController.text
                    .trim()
                    .replaceAll(',', '.')),
                rate: double.tryParse(_jornalRateController.text
                    .trim()
                    .replaceAll(',', '.')),
                currency: _currency,
                locale: tx.settings.locale,
                l10n: l10n,
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextFormField(
                controller: _providerController,
                decoration: InputDecoration(
                  labelText: l10n.providerFieldLabel,
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Vincular a cosecha (solo gastos): las cosechas recientes del
            // cultivo elegido, para asociar el pago de recogida.
            if (_cropId != null && _linkedHarvests(tx).isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _harvestId,
                decoration: InputDecoration(
                  labelText: l10n.expenseLinkHarvestLabel,
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.expenseLinkHarvestNone),
                  ),
                  ..._linkedHarvests(tx).map((h) => DropdownMenuItem<String?>(
                        value: h.id,
                        child: Text(
                          '${h.date.day.toString().padLeft(2, '0')}/'
                          '${h.date.month.toString().padLeft(2, '0')}/'
                          '${h.date.year} · '
                          '${h.amount.toStringAsFixed(h.amount % 1 == 0 ? 0 : 2)}',
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _harvestId = v),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Monto (solo lectura cuando el bloque jornal lo calcula)
          TextFormField(
            controller: _amountController,
            readOnly: _isJornal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.amountFieldLabel,
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
              suffixIcon: _isJornal
                  ? Tooltip(
                      message: l10n.jornalTotalHint,
                      child: const Icon(Icons.lock_outline, size: 20),
                    )
                  : null,
            ),
            validator: (v) {
              if (_isJornal) {
                // El total lo defienden los validadores de días y valor día.
                final days = int.tryParse(_jornalDaysController.text.trim());
                final rate = double.tryParse(_jornalRateController.text
                    .trim()
                    .replaceAll(',', '.'));
                if (days == null || days <= 0) return l10n.jornalDaysRequired;
                if (rate == null || rate <= 0) {
                  return l10n.jornalRateRequired;
                }
                return null;
              }
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n <= 0) return l10n.amountInvalid;
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Moneda
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: InputDecoration(
              labelText: l10n.currencyLabel,
              prefixIcon: const Icon(Icons.monetization_on_outlined),
              border: const OutlineInputBorder(),
            ),
            items: supportedCurrencies
                .map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.symbol} ${c.name} (${c.code})'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _currency = v ?? 'COP'),
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

class _ProdSectionHeader extends StatelessWidget {
  final String label;
  const _ProdSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.factory_outlined,
            size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _JornalTotalInfo extends StatelessWidget {
  final double? days;
  final double? rate;
  final String currency;
  final String locale;
  final AppLocalizations l10n;

  const _JornalTotalInfo({
    required this.days,
    required this.rate,
    required this.currency,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final d = days;
    final r = rate;
    if (d == null || d <= 0 || r == null || r <= 0) {
      return Text(
        l10n.jornalTotalHint,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final total = d * r;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '${l10n.jornalTotalLabel}: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextSpan(
                    text: formatAmount(total,
                        currency: currency, locale: locale),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePerUnitInfo extends StatelessWidget {
  final double? amount;
  final double? quantity;
  final String? unit;
  final String currency;
  final String locale;
  final AppLocalizations l10n;

  const _PricePerUnitInfo({
    required this.amount,
    required this.quantity,
    required this.unit,
    required this.currency,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final a = amount;
    final q = quantity;
    final u = unit;
    if (a == null || q == null || q <= 0 || u == null) {
      return Text(
        l10n.pricePerUnitHint,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final perUnit = a / q;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '${l10n.pricePerUnitLabel} $u: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextSpan(
                    text: formatAmount(perUnit,
                        currency: currency, locale: locale, decimals: 2),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}