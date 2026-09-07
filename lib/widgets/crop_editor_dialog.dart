import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';

/// Editor de cultivo (crear y editar). Permite configurar fase/ciclo, unidad
/// preferida, área y plantas vivas. Al confirmar devuelve los valores editados.
class CropEditorDialog extends StatefulWidget {
  final Crop? crop;
  final List<String> existingNames;

  const CropEditorDialog({super.key, this.crop, required this.existingNames});

  @override
  State<CropEditorDialog> createState() => _CropEditorDialogState();
}

class _CropEditorDialogState extends State<CropEditorDialog> {
  final _nameController = TextEditingController();
  String _icon = '🌱';
  String _color = '#2E7D32';
  CropPhase _phase = CropPhase.produccion;
  CropCycle _cycle = CropCycle.perenne;
  String? _defaultUnit;
  final _areaController = TextEditingController();
  final _plantsController = TextEditingController();
  String? _error;

  static const _unitOptions = ['kg', 'arroba', 'saco', 'racimo', 'cajon'];

  @override
  void initState() {
    super.initState();
    final c = widget.crop;
    if (c != null) {
      _nameController.text = c.name;
      _icon = c.icon;
      _color = c.color;
      _phase = c.phase;
      _cycle = c.cycle;
      _defaultUnit = c.defaultUnit;
      if (c.areaHa != null) _areaController.text = c.areaHa.toString();
      if (c.livePlants != null) _plantsController.text = c.livePlants.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _plantsController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = _nameController.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.cropNameRequired);
      return;
    }
    final dup = widget.existingNames
        .where((e) => e.toLowerCase() == n.toLowerCase() && e != widget.crop?.name)
        .toList();
    if (dup.isNotEmpty) {
      setState(() => _error = l10n.cropNameRequired);
      return;
    }
    final areaText = _areaController.text.trim().replaceAll(',', '.');
    final area = areaText.isEmpty ? null : double.tryParse(areaText);
    final plantsText = _plantsController.text.trim();
    final plants = plantsText.isEmpty ? null : int.tryParse(plantsText);
    Navigator.pop(context, CropFormData(
      name: n,
      icon: _icon,
      color: _color,
      phase: _phase,
      cycle: _cycle,
      defaultUnit: _defaultUnit,
      areaHa: area,
      livePlants: plants,
    ));
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
    final editing = widget.crop != null;
    return AlertDialog(
      title: Text(editing ? l10n.editCropTitle : l10n.newCropDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.cropNameLabel,
                errorText: _error,
                prefixIcon: const Icon(Icons.grass_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _defaultUnit,
              decoration: InputDecoration(
                labelText: l10n.defaultUnitLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(l10n.defaultUnitNone),
                ),
                ..._unitOptions.map((u) => DropdownMenuItem<String>(
                      value: u,
                      child: Text(_unitLabel(u, l10n)),
                    )),
              ],
              onChanged: (v) => setState(() => _defaultUnit = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CropCycle>(
              value: _cycle,
              decoration: InputDecoration(
                labelText: l10n.cycleLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: CropCycle.perenne,
                  child: Text(l10n.cyclePerenne),
                ),
                DropdownMenuItem(
                  value: CropCycle.anual,
                  child: Text(l10n.cycleAnual),
                ),
              ],
              onChanged: (v) => setState(() {
                _cycle = v ?? CropCycle.perenne;
                if (_cycle == CropCycle.anual) {
                  _phase = CropPhase.produccion;
                }
              }),
            ),
            // Fase se oculta para cultivos anuales (solo aplica a perennes).
            if (_cycle == CropCycle.perenne) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<CropPhase>(
                value: _phase,
                decoration: InputDecoration(
                  labelText: l10n.phaseLabel,
                  helperText: l10n.phaseHelp,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: CropPhase.establecimiento,
                    child: Text(l10n.phaseEstablecimiento),
                  ),
                  DropdownMenuItem(
                    value: CropPhase.produccion,
                    child: Text(l10n.phaseProduccion),
                  ),
                  DropdownMenuItem(
                    value: CropPhase.renovacion,
                    child: Text(l10n.phaseRenovacion),
                  ),
                ],
                onChanged: (v) => setState(() => _phase = v ?? CropPhase.produccion),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.areaHaLabel,
                prefixIcon: const Icon(Icons.square_foot_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plantsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.livePlantsLabel,
                prefixIcon: const Icon(Icons.park_outlined),
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
        FilledButton(onPressed: _submit, child: Text(l10n.add)),
      ],
    );
  }
}

class CropFormData {
  final String name;
  final String icon;
  final String color;
  final CropPhase phase;
  final CropCycle cycle;
  final String? defaultUnit;
  final double? areaHa;
  final int? livePlants;

  const CropFormData({
    required this.name,
    required this.icon,
    required this.color,
    required this.phase,
    required this.cycle,
    this.defaultUnit,
    this.areaHa,
    this.livePlants,
  });
}
