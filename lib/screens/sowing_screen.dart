import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/categories.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/new_crop_dialog.dart';

class SowingScreen extends StatelessWidget {
  const SowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final sowings = [...tx.sowings]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSowings)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, tx, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.sowingAdd),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: sowings.isEmpty
              ? Center(child: Text(l10n.sowingEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: sowings.length,
                  itemBuilder: (context, i) => _row(
                      context, tx, sowings[i], nameById, l10n),
                ),
        ),
      ),
    );
  }

  Future<void> _openForm(
      BuildContext context, TransactionProvider tx, Sowing? editing) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _SowingForm(cropNames: {
        for (final c in tx.crops) c.id: '${c.icon} ${c.name}',
      }, editing: editing),
    );
    if (result != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(editing == null
          ? AppLocalizations.of(context)!.sowingRecordSaved
          : AppLocalizations.of(context)!.sowingRecordUpdated),
      duration: const Duration(seconds: 1),
    ));
  }

  Widget _row(BuildContext context, TransactionProvider tx, Sowing s,
      Map<String, String> nameById, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: s.kind == SowingKind.siembra
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(
            s.kind == SowingKind.siembra
                ? Icons.grass_outlined
                : Icons.yard_outlined,
            size: 20,
          ),
        ),
        title: Text(
          s.kind == SowingKind.siembra
              ? l10n.sowingKindSiembra
              : l10n.sowingKindResiembra,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            '${s.date.day.toString().padLeft(2, '0')}/'
                '${s.date.month.toString().padLeft(2, '0')}/${s.date.year}',
            if (s.cropId != null) nameById[s.cropId] ?? s.cropId!,
            '${s.plants}',
            if (s.areaHa != null) '${s.areaHa!.toStringAsFixed(2)} ha',
            if (s.lostPlants != null) '-${s.lostPlants}',
            if (s.reason != null && s.reason!.isNotEmpty) s.reason!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: l10n.delete,
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _confirmDelete(context, tx, s, l10n),
        ),
        onTap: () => _openForm(context, tx, s),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionProvider tx,
      Sowing s, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.sowingConfirmDelete),
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
    final l10nMsg = l10n.sowingRecordDeleted;
    await tx.deleteSowing(s.id);
    messenger.showSnackBar(SnackBar(
      content: Text(l10nMsg),
      duration: const Duration(seconds: 1),
    ));
  }
}

class _SowingForm extends StatefulWidget {
  final Map<String, String> cropNames;
  final Sowing? editing;

  const _SowingForm({required this.cropNames, this.editing});

  @override
  State<_SowingForm> createState() => _SowingFormState();
}

class _SowingFormState extends State<_SowingForm> {
  static const _newCropOption = '__new__';

  final _formKey = GlobalKey<FormState>();
  final _plantsController = TextEditingController();
  final _areaController = TextEditingController();
  final _lostController = TextEditingController();
  final _reasonController = TextEditingController();
  final _costController = TextEditingController();

  late final Map<String, String> _cropNames = Map.of(widget.cropNames);
  String? _cropId;
  DateTime _date = DateTime.now();
  SowingKind _kind = SowingKind.siembra;

  @override
  void initState() {
    super.initState();
    final s = widget.editing;
    if (s != null) {
      _cropId = s.cropId;
      _date = s.date;
      _kind = s.kind;
      _plantsController.text = s.plants.toString();
      if (s.areaHa != null) _areaController.text = s.areaHa.toString();
      if (s.lostPlants != null) _lostController.text = s.lostPlants.toString();
      if (s.reason != null) _reasonController.text = s.reason!;
    } else if (_cropNames.isNotEmpty) {
      _cropId = _cropNames.keys.first;
    }
  }

  @override
  void dispose() {
    _plantsController.dispose();
    _areaController.dispose();
    _lostController.dispose();
    _reasonController.dispose();
    _costController.dispose();
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

  Future<void> _onCropChanged(String? value) async {
    if (value != _newCropOption) {
      setState(() => _cropId = value);
      return;
    }
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
      setState(() {
        final m = matched.first;
        _cropId = m.id;
        _cropNames[m.id] = '${m.icon} ${m.name}';
      });
      return;
    }
    final crop = await tx.addCrop(trimmed);
    if (!mounted) return;
    setState(() {
      _cropId = crop.id;
      _cropNames[crop.id] = '${crop.icon} ${crop.name}';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (_cropId == null) return;
    final plants = int.parse(_plantsController.text.trim());
    final areaText = _areaController.text.trim().replaceAll(',', '.');
    final area = _kind == SowingKind.siembra && areaText.isNotEmpty
        ? double.tryParse(areaText)
        : null;
    final lostText = _lostController.text.trim();
    final lost = _kind == SowingKind.resiembra && lostText.isNotEmpty
        ? int.tryParse(lostText)
        : null;
    final reason = _kind == SowingKind.resiembra
        ? _reasonController.text.trim()
        : null;

    final editing = widget.editing;
    final String sowingId;
    if (editing != null) {
      await tx.updateSowing(editing.copyWith(
        cropId: _cropId,
        date: _date,
        kind: _kind,
        plants: plants,
        areaHa: area,
        lostPlants: lost,
        reason: reason,
      ));
      sowingId = editing.id;
    } else {
      final sowing = await tx.addSowing(
        cropId: _cropId,
        date: _date,
        kind: _kind,
        plants: plants,
        areaHa: area,
        lostPlants: lost,
        reason: reason,
      );
      sowingId = sowing.id;
    }

    // Costo opcional: solo siembra inicial con costo > 0 → crea gasto vinculado.
    if (_kind == SowingKind.siembra) {
      final costText = _costController.text.trim().replaceAll(',', '.');
      final cost = costText.isEmpty ? null : double.tryParse(costText);
      if (cost != null && cost > 0) {
        final cropName = _cropNames[_cropId]?.trim() ?? '';
        await tx.addTransaction(
          type: TransactionType.expense,
          category: kExpenseCategorySowing,
          cropId: _cropId,
          amount: cost,
          description:
              cropName.isEmpty ? l10n.sowingTitle : '${l10n.sowingTitle} · $cropName',
          date: _date,
          sowingId: sowingId,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isResiembra = _kind == SowingKind.resiembra;
    return AlertDialog(
      title: Text(widget.editing != null
          ? l10n.editCropTitle
          : (isResiembra ? l10n.sowingKindResiembra : l10n.sowingKindSiembra)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String?>(
                value: _cropId,
                decoration: InputDecoration(
                  labelText: l10n.cropFieldLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: _newCropOption,
                    child: Text(l10n.sowingNewCropOption),
                  ),
                  ..._cropNames.entries.map((e) => DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value),
                      )),
                ],
                onChanged: (v) => _onCropChanged(v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<SowingKind>(
                segments: [
                  ButtonSegment(
                    value: SowingKind.siembra,
                    label: Text(l10n.sowingKindSiembra),
                  ),
                  ButtonSegment(
                    value: SowingKind.resiembra,
                    label: Text(l10n.sowingKindResiembra),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
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
                controller: _plantsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _kind == SowingKind.siembra
                      ? l10n.sowingPlantsLabel
                      : l10n.sowingPlantsLabel,
                  prefixIcon: const Icon(Icons.park_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return l10n.plantsInvalid;
                  return null;
                },
              ),
              if (isResiembra) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lostController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.sowingLostPlantsLabel,
                    prefixIcon: const Icon(Icons.trending_down),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.sowingReasonLabel,
                    prefixIcon: const Icon(Icons.notes),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.sowingAreaLabel,
                    prefixIcon: const Icon(Icons.square_foot_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.sowingCostLabel,
                    helperText: l10n.sowingCostHint,
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
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
