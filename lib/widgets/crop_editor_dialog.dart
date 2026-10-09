import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/currencies.dart';
import 'crop_loss_dialog.dart';

/// Editor de cultivo (crear y editar). Permite configurar fase/ciclo, unidad
/// preferida, área y plantas vivas. Al confirmar devuelve los valores editados.
class CropEditorDialog extends StatefulWidget {
  final Crop? crop;
  final List<String> existingNames;

  /// F3 · Suma sugerida de los gastos de siembra inicial del cultivo.
  ///
  /// Solo se usa si el campo de *Inversión total* viene vacío, y queda
  /// editable por si falta algo que no nació de un gasto de siembra
  /// (preparación de tierra, cercas, mano de obra).
  final double? suggestedEstablishmentCost;

  /// F4 · true cuando el número de plantas y el área **no los escribe** él:
  /// salen de las siembras, y cualquier cosa tecleada aquí se pierde en la
  /// próxima siembra. En ese caso los dos campos quedan en solo lectura.
  final bool sowingsLocked;

  const CropEditorDialog({
    super.key,
    this.crop,
    required this.existingNames,
    this.suggestedEstablishmentCost,
    this.sowingsLocked = false,
  });

  @override
  State<CropEditorDialog> createState() => _CropEditorDialogState();
}

class _CropEditorDialogState extends State<CropEditorDialog> {
  final _nameController = TextEditingController();
  String _icon = '🌱';
  String _color = '#2E7D32';
  // Un cultivo nuevo nace en establecimiento (P3): sin cosecha que lo
  // demuestre, todavía no es producción. Al editar lo pisa initState con la
  // fase real del cultivo.
  CropPhase _phase = CropPhase.establecimiento;
  CropCycle _cycle = CropCycle.perenne;
  String? _defaultUnit;
  String _currency = 'COP';
  final _areaController = TextEditingController();
  final _plantsController = TextEditingController();
  final _establishmentController = TextEditingController();
  String? _error;

  static const _unitOptions = ['kg', 'lb', 'arroba', 'saco', 'carga', 'racimo', 'cajon'];

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
      _currency = c.currency ?? 'COP';
      if (c.areaHa != null) _areaController.text = c.areaHa.toString();
      if (c.livePlants != null) _plantsController.text = c.livePlants.toString();
      if (c.establishmentCost != null) {
        _establishmentController.text = _importe(c.establishmentCost!);
      }
    }
    // F3: si no había inversión anotada, se propone la suma de los gastos de
    // siembra inicial. Nunca pisa lo que el productor ya puso a mano.
    if (_establishmentController.text.isEmpty &&
        widget.suggestedEstablishmentCost != null) {
      _establishmentController.text =
          _importe(widget.suggestedEstablishmentCost!);
    }
  }

  /// Importe para el campo, sin el ".0" que sueltan los doubles.
  static String _importe(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// F4 · Puerta de salida del bloqueo: el productor anota cuántas plantas
  /// quedan y la app escribe la resiembra que corresponda (0 plantas nuevas
  /// si hay mortandad). Al volver se refresca el contador en solo lectura.
  Future<void> _registerLoss() async {
    final crop = widget.crop;
    final actuales = crop?.livePlants;
    if (crop == null || actuales == null) return;

    final nuevo = await showDialog<int>(
      context: context,
      builder: (_) => CropLossDialog(crop: crop, currentPlants: actuales),
    );
    if (nuevo == null || !mounted) return;
    setState(() => _plantsController.text = nuevo.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _plantsController.dispose();
    _establishmentController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = _nameController.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.cropNameRequired);
      return;
    }
    final current = widget.crop?.name.toLowerCase();
    final dup = widget.existingNames.any((e) =>
        e.toLowerCase() == n.toLowerCase() && e.toLowerCase() != current);
    if (dup) {
      // C3: decía "el nombre es obligatorio", que era un mensaje para otra
      // cosa y dejaba al usuario reescribiendo el mismo nombre.
      setState(() => _error = l10n.cropNameTaken);
      return;
    }
    final areaText = _areaController.text.trim().replaceAll(',', '.');
    final area = areaText.isEmpty ? null : double.tryParse(areaText);
    final plantsText = _plantsController.text.trim();
    final plants = plantsText.isEmpty ? null : int.tryParse(plantsText);
    final estText = _establishmentController.text.trim().replaceAll(',', '.');
    final establishmentCost =
        estText.isEmpty ? null : double.tryParse(estText);
    Navigator.pop(context, CropFormData(
      name: n,
      icon: _icon,
      color: _color,
      phase: _effectivePhase,
      cycle: _cycle,
      defaultUnit: _defaultUnit,
      areaHa: area,
      livePlants: plants,
      establishmentCost: establishmentCost,
      currency: _currency,
    ));
  }

  /// Fase efectiva que se guarda.
  ///
  /// Invariante: un cultivo anual no tiene fases de cafetal, así que siempre
  /// queda en `produccion`. Se aplica **al guardar** y no solo en el
  /// `onChanged` del desplegable de ciclo, porque el desplegable de fase está
  /// oculto para los anuales: si un cultivo anual llegara aquí con otra fase
  /// (por un registro antiguo o por cualquier otro camino de escritura), sin
  /// esta regla se quedaría atascado y no habría forma de corregirlo desde la
  /// interfaz.
  CropPhase get _effectivePhase =>
      _cycle == CropCycle.anual ? CropPhase.produccion : _phase;

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
              onChanged: (_) {
                // El error no debe quedarse pegado mientras el usuario
                // escribe un nombre nuevo.
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l10n.cropNameLabel,
                errorText: _error,
                prefixIcon: const Icon(Icons.grass_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CropCycle>(
              value: _cycle,
              decoration: InputDecoration(
                labelText: l10n.cycleLabel,
                helperText: l10n.helpCycleShort,
                suffixIcon: Tooltip(
                  message: l10n.helpCycle,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
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
                  // Un cultivo anual no tiene fases de cafetal: el dropdown de
                  // fase se oculta, así que se fija producción a mano.
                  _phase = CropPhase.produccion;
                }
              }),
            ),
            if (_cycle == CropCycle.perenne) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<CropPhase>(
                value: _phase,
                decoration: InputDecoration(
                  labelText: l10n.phaseLabel,
                  helperText: l10n.phaseHelpShort,
                  suffixIcon: Tooltip(
                    message: l10n.phaseHelp,
                    child: const Icon(Icons.info_outline, size: 20),
                  ),
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
            DropdownButtonFormField<String>(
              value: _defaultUnit,
              decoration: InputDecoration(
                labelText: l10n.defaultUnitLabel,
                helperText: l10n.helpUnitShort,
                suffixIcon: Tooltip(
                  message: l10n.helpUnit,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
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
            TextField(
              controller: _areaController,
              // F4: el área la fija la siembra inicial; escribirla aquí no
              // tendría efecto, así que se muestra y no se toca.
              enabled: !widget.sowingsLocked,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.areaHaLabel,
                helperText:
                    widget.sowingsLocked ? l10n.cropLockedHint : l10n.helpAreaShort,
                prefixIcon: const Icon(Icons.square_foot_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpArea,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plantsController,
              // F4: las plantas vivas se recalculan con cada siembra.
              enabled: !widget.sowingsLocked,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.livePlantsLabel,
                helperText:
                    widget.sowingsLocked ? l10n.cropLockedHint : l10n.helpPlantsShort,
                prefixIcon: const Icon(Icons.park_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpPlants,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            // F4: el contador ya no lo escribe él, pero no se queda sin
            // salida — aquí anota cuántas plantas quedan.
            if (widget.sowingsLocked && widget.crop?.livePlants != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _registerLoss,
                  icon: const Icon(Icons.trending_down, size: 18),
                  label: Text(l10n.cropLossRegister),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _establishmentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.establishmentCostLabel,
                helperText: l10n.helpEstablishmentShort,
                prefixIcon: const Icon(Icons.savings_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpEstablishment,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(
                labelText: l10n.currencyLabel,
                helperText: l10n.helpCropCurrencyShort,
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                suffixIcon: Tooltip(
                  message: l10n.helpCropCurrency,
                  child: const Icon(Icons.info_outline, size: 20),
                ),
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
  final double? establishmentCost;
  final String currency;

  const CropFormData({
    required this.name,
    required this.icon,
    required this.color,
    required this.phase,
    required this.cycle,
    this.defaultUnit,
    this.areaHa,
    this.livePlants,
    this.establishmentCost,
    this.currency = 'COP',
  });
}
