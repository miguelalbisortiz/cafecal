import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/harvest.dart';
import '../providers/transaction_provider.dart';

class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final harvests = [...tx.harvests]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuHarvests)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, tx, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.harvestAdd),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: harvests.isEmpty
              ? Center(child: Text(l10n.harvestEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: harvests.length,
                  itemBuilder: (context, i) => _row(context, tx, harvests[i],
                      nameById, l10n),
                ),
        ),
      ),
    );
  }

  Future<void> _openForm(
      BuildContext context, TransactionProvider tx, Harvest? editing) async {
    final crops = tx.crops;
    final cropById = {for (final c in crops) c.id: c};
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _HarvestForm(
        crops: crops,
        cropById: cropById,
        editing: editing,
      ),
    );
    if (result != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(editing == null
          ? AppLocalizations.of(context)!.harvestRecordSaved
          : AppLocalizations.of(context)!.harvestRecordUpdated),
      duration: const Duration(seconds: 1),
    ));
  }

  Widget _row(BuildContext context, TransactionProvider tx, Harvest h,
      Map<String, String> nameById, AppLocalizations l10n) {
    final destinationLabel = switch (h.destination) {
      HarvestDestination.vendido => l10n.harvestDstVendido,
      HarvestDestination.almacenado => l10n.harvestDstAlmacenado,
      HarvestDestination.perdida => l10n.harvestDstPerdida,
    };
    final unitLabel = switch (h.unit) {
      'kg' => l10n.unitKg,
      'arroba' => l10n.unitArroba,
      'saco' => l10n.unitSaco,
      'racimo' => l10n.unitRacimo,
      'cajon' => l10n.unitCajon,
      _ => h.unit,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.agriculture_outlined, size: 20),
        ),
        title: Text(
          '${h.amount.toStringAsFixed(h.amount % 1 == 0 ? 0 : 2)} $unitLabel',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            '${h.date.day.toString().padLeft(2, '0')}/'
                '${h.date.month.toString().padLeft(2, '0')}/${h.date.year}',
            if (h.cropId != null) nameById[h.cropId] ?? h.cropId!,
            destinationLabel,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: l10n.delete,
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _confirmDelete(context, tx, h, l10n),
        ),
        onTap: () => _openForm(context, tx, h),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionProvider tx,
      Harvest h, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.harvestConfirmDelete),
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
    if (!context.mounted || ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10nMsg = l10n.harvestRecordDeleted;
    await tx.deleteHarvest(h.id);
    messenger.showSnackBar(SnackBar(
      content: Text(l10nMsg),
      duration: const Duration(seconds: 1),
    ));
  }
}

class _HarvestForm extends StatefulWidget {
  final List<Crop> crops;
  final Map<String, Crop> cropById;
  final Harvest? editing;

  const _HarvestForm({
    required this.crops,
    required this.cropById,
    this.editing,
  });

  @override
  State<_HarvestForm> createState() => _HarvestFormState();
}

class _HarvestFormState extends State<_HarvestForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _cropId;
  DateTime _date = DateTime.now();
  String _unit = 'kg';
  HarvestDestination _destination = HarvestDestination.vendido;

  @override
  void initState() {
    super.initState();
    final h = widget.editing;
    if (h != null) {
      _cropId = h.cropId;
      _date = h.date;
      _unit = h.unit;
      _destination = h.destination;
      _amountController.text =
          h.amount % 1 == 0 ? h.amount.toInt().toString() : h.amount.toString();
    } else if (widget.crops.isNotEmpty) {
      _cropId = widget.crops.first.id;
      final defUnit = widget.crops.first.defaultUnit;
      if (defUnit != null) _unit = defUnit;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tx = context.read<TransactionProvider>();
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    final editing = widget.editing;
    if (editing != null) {
      await tx.updateHarvest(editing.copyWith(
        cropId: _cropId,
        date: _date,
        amount: amount,
        unit: _unit,
        destination: _destination,
      ));
    } else {
      await tx.addHarvest(
        cropId: _cropId,
        date: _date,
        amount: amount ?? 0,
        unit: _unit,
        destination: _destination,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _unitLabel(String key, AppLocalizations l10n) => switch (key) {
        'kg' => l10n.unitKg,
        'arroba' => l10n.unitArroba,
        'saco' => l10n.unitSaco,
        'racimo' => l10n.unitRacimo,
        'cajon' => l10n.unitCajon,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.editing != null
          ? l10n.harvestTitle
          : l10n.harvestAdd),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _cropId,
                decoration: InputDecoration(
                  labelText: l10n.cropFieldLabel,
                  border: const OutlineInputBorder(),
                ),
                items: widget.cropById.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.value.icon} ${e.value.name}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _cropId = v;
                  final def = widget.cropById[v]?.defaultUnit;
                  if (def != null) _unit = def;
                }),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.harvestAmountLabel,
                  prefixIcon: const Icon(Icons.scale_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return l10n.harvestAmountInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: InputDecoration(
                  labelText: l10n.harvestUnitLabel,
                  border: const OutlineInputBorder(),
                ),
                items: const ['kg', 'arroba', 'saco', 'racimo', 'cajon']
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(_unitLabel(u, l10n)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v ?? 'kg'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HarvestDestination>(
                value: _destination,
                decoration: InputDecoration(
                  labelText: l10n.harvestDestinationLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: HarvestDestination.vendido,
                    child: Text(l10n.harvestDstVendido),
                  ),
                  DropdownMenuItem(
                    value: HarvestDestination.almacenado,
                    child: Text(l10n.harvestDstAlmacenado),
                  ),
                  DropdownMenuItem(
                    value: HarvestDestination.perdida,
                    child: Text(l10n.harvestDstPerdida),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _destination = v ?? HarvestDestination.vendido),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.add)),
      ],
    );
  }
}
