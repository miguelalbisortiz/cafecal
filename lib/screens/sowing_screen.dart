import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/categories.dart';
import '../models/crop.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/crop_setup_prompt.dart';
import '../widgets/new_crop_dialog.dart';

class SowingScreen extends StatelessWidget {
  const SowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final nameById = {for (final c in tx.crops) c.id: c.name};
    final phaseById = {for (final c in tx.crops) c.id: c.phase};
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
                      context, tx, sowings[i], nameById, phaseById, l10n),
                ),
        ),
      ),
    );
  }

  Future<void> _openForm(
      BuildContext context, TransactionProvider tx, Sowing? editing) async {
    Crop? created;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _SowingForm(cropNames: {
        for (final c in tx.crops) c.id: '${c.icon} ${c.name}',
      }, editing: editing, onCropCreated: (c) => created = c),
    );
    // L2.5b: el aviso de "completar datos" sale recién al cerrar el
    // formulario, para no quedar tapado por el diálogo.
    final nuevo = created;
    if (nuevo != null && context.mounted) {
      await CropSetupPrompt.show(context, tx, nuevo);
    }
    if (result != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(editing == null
          ? AppLocalizations.of(context)!.sowingRecordSaved
          : AppLocalizations.of(context)!.sowingRecordUpdated),
      duration: const Duration(seconds: 1),
    ));
  }

  Widget _row(BuildContext context, TransactionProvider tx, Sowing s,
      Map<String, String> nameById, Map<String, CropPhase> phaseById,
      AppLocalizations l10n) {
    final noYield = s.cropId != null &&
        phaseById[s.cropId] == CropPhase.establecimiento;
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
            // L2.3: un cultivo que sigue en establecimiento todavía no rinde.
            if (noYield)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_outlined,
                        size: 12, color: Color(0xFFED6C02)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.cropPhaseNoYield,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFED6C02),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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

  /// L2.5b: se invoca cuando se crea un cultivo nuevo desde este formulario
  /// (puerta corta), para ofrecer completar sus datos después de cerrarlo.
  final void Function(Crop crop)? onCropCreated;

  const _SowingForm({
    required this.cropNames,
    this.editing,
    this.onCropCreated,
  });

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

  /// L2.4: solo la resiembra puede ofrecer pasar el cultivo a renovación.
  /// Nunca se marca solo.
  bool _renewCrop = false;

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
    final res = await showDialog<NewCropResult>(
      context: context,
      builder: (_) => NewCropDialog(crops: tx.crops),
    );
    if (res == null || !mounted) return;
    // L2.2: el diálogo ya resolvió la ambigüedad. Si devolvió un id, se usa
    // directo (nunca se vuelve a "matchear" por nombre); si no, se crea.
    if (res.existingId != null) {
      Crop? found;
      for (final c in tx.crops) {
        if (c.id == res.existingId) {
          found = c;
          break;
        }
      }
      final existing = found;
      if (existing == null) return;
      setState(() {
        _cropId = existing.id;
        _cropNames[existing.id] = '${existing.icon} ${existing.name}';
      });
      return;
    }
    final crop =
        await tx.addCrop(res.name, currency: tx.settings.currency);
    if (!mounted) return;
    setState(() {
      _cropId = crop.id;
      _cropNames[crop.id] = '${crop.icon} ${crop.name}';
    });
    widget.onCropCreated?.call(crop);
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

    // L2.4: la resiembra puede ofrecer pasar el cultivo a renovación, pero
    // solo si la casilla está marcada. Nunca automático ni en siembra inicial.
    if (_renewCrop && _kind == SowingKind.resiembra && _cropId != null) {
      Crop? found;
      for (final c in tx.crops) {
        if (c.id == _cropId) {
          found = c;
          break;
        }
      }
      final crop = found;
      if (crop != null) {
        await tx.updateCrop(crop.copyWith(
          phase: CropPhase.renovacion,
          pendingSync: true,
        ));
      }
    }

    // Costo opcional con costo > 0 → crea gasto vinculado a la siembra o a
    // la resiembra (F2). Entra al costo por kilo, porque report_harvest_metrics
    // suma los gastos que traen sowingId; en cambio NO cuenta para la
    // "Inversión total" del cultivo (F3), que sigue sumando solo siembras
    // iniciales.
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.helpSowingKind,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
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
                  labelText: l10n.sowingPlantsLabel,
                  helperText: l10n.helpSowingPlantsShort,
                  prefixIcon: const Icon(Icons.park_outlined),
                  suffixIcon: Tooltip(
                    message: l10n.helpSowingPlants,
                    child: const Icon(Icons.info_outline, size: 20),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final raw = (v ?? '').trim();
                  final n = raw.isEmpty ? 0 : int.tryParse(raw);
                  if (n == null || n < 0) return l10n.plantsInvalid;
                  if (!isResiembra) {
                    // La siembra inicial sí exige plantar algo.
                    if (n == 0) return l10n.plantsInvalid;
                    return null;
                  }
                  // F4: la mortandad se registra aunque no se repongan
                  // plantas (hoy estaba prohibido y la pérdida se perdía).
                  // Aun así hay que decirnos algo: o siembras o mueren.
                  final perdidas =
                      int.tryParse(_lostController.text.trim()) ?? 0;
                  if (n == 0 && perdidas <= 0) return l10n.sowingPlantsOrLost;
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
                    helperText: l10n.helpSowingLostPlantsShort,
                    prefixIcon: const Icon(Icons.trending_down),
                    suffixIcon: Tooltip(
                      message: l10n.helpSowingLostPlants,
                      child: const Icon(Icons.info_outline, size: 20),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final raw = (v ?? '').trim();
                    if (raw.isEmpty) return null;
                    final n = int.tryParse(raw);
                    // Se reutiliza el mensaje de plantas: es el mismo tipo
                    // de dato y así no hace falta otra clave.
                    if (n == null || n < 0) return l10n.plantsInvalid;
                    return null;
                  },
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
                const SizedBox(height: 4),
                // L2.4: solo la resiembra puede renovar el cultivo, y solo
                // si el productor lo pide a mano.
                CheckboxListTile(
                  value: _renewCrop,
                  onChanged: (v) => setState(() => _renewCrop = v ?? false),
                  title: Text(
                    l10n.sowingRenovacionCheckbox,
                    style: const TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.sowingAreaLabel,
                    // L2.5c: sin área se puede guardar igual, pero se avisa
                    // en palabras simples qué es lo que no se podrá ver.
                    helperText: _areaController.text.trim().isEmpty
                        ? l10n.sowingAreaMissingWarning
                        : l10n.helpSowingAreaShort,
                    helperStyle: _areaController.text.trim().isEmpty
                        ? const TextStyle(color: Color(0xFFED6C02))
                        : null,
                    prefixIcon: const Icon(Icons.square_foot_outlined),
                    suffixIcon: Tooltip(
                      message: l10n.helpSowingArea,
                      child: const Icon(Icons.info_outline, size: 20),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              // F2: el costo va en la siembra y también en la resiembra —
              // el recambio de plátano o un cafetal renovado también cuesta.
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final t = (v ?? '').trim().replaceAll(',', '.');
                  if (t.isEmpty) return null;
                  final n = double.tryParse(t);
                  if (n == null || n < 0) return l10n.sowingCostInvalid;
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l10n.sowingCostLabel,
                  helperText: l10n.sowingCostHintShort,
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixIcon: Tooltip(
                    message: l10n.sowingCostHint,
                    child: const Icon(Icons.info_outline, size: 20),
                  ),
                  border: const OutlineInputBorder(),
                ),
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
