import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/sowing.dart';
import '../providers/transaction_provider.dart';
import '../widgets/crop_editor_dialog.dart';

/// Gestión de cultivos: crear/editar/eliminar con fase, ciclo, unidad
/// preferida, área y plantas vivas. También es la puerta de entrada al
/// editor de cultivo desde el flujo "Asignar cultivos".
class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuCrops)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCrop(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.cropNewOption),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: tx.crops.isEmpty
              ? Center(child: Text(l10n.cropsEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: tx.crops.length,
                  itemBuilder: (context, i) =>
                      _row(context, tx, tx.crops[i], l10n),
                ),
        ),
      ),
    );
  }

  Future<void> _createCrop(BuildContext context) async {
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;
    final wasEmpty = tx.crops.isEmpty;
    var keepAdding = true;
    while (keepAdding) {
      if (!context.mounted) return;
      final form = await showDialog<CropFormData>(
        context: context,
        builder: (_) => CropEditorDialog(
          existingNames: tx.crops.map((c) => c.name).toList(),
        ),
      );
      if (form == null || !context.mounted) return;
      // Una sola escritura con todo el formulario (C5): antes era addCrop +
      // updateCrop, que guardaba y avisaba dos veces y disparaba el auto-sync
      // en dos pasadas.
      await tx.addCrop(
        form.name,
        icon: form.icon,
        color: form.color,
        currency: form.currency,
        phase: form.phase,
        cycle: form.cycle,
        defaultUnit: form.defaultUnit,
        areaHa: form.areaHa,
        livePlants: form.livePlants,
        establishmentCost: form.establishmentCost,
        plantedAt: form.plantedAt,
      );
      if (!wasEmpty || !context.mounted) return;
      // Primer cultivo: el onboarding invita a agregar varios existentes.
      keepAdding = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.onboardingCropAddedTitle),
              content: Text(l10n.onboardingAnotherPrompt),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.onboardingAnother),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.onboardingDone),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  Future<void> _editCrop(BuildContext context, TransactionProvider tx,
      Crop crop) async {
    final form = await showDialog<CropFormData>(
      context: context,
      builder: (_) => CropEditorDialog(
        crop: crop,
        existingNames: tx.crops.map((c) => c.name).toList(),
        suggestedEstablishmentCost: tx.initialSowingCost(crop.id),
        sowingsLocked: _hasInitialSowing(tx, crop),
      ),
    );
    if (form == null || !context.mounted) return;
    await tx.updateCrop(crop.copyWith(
      name: form.name,
      phase: form.phase,
      cycle: form.cycle,
      defaultUnit: form.defaultUnit,
      areaHa: form.areaHa,
      livePlants: form.livePlants,
      establishmentCost: form.establishmentCost,
      // C1: antes la moneda se descartaba en silencio al editar (solo se
      // guardaba al crear).
      currency: form.currency,
      // C1: lo mismo con la fecha. Solo se enseña el campo cuando no hay
      // siembras; si las hay, se devuelve tal cual la que ya traía.
      plantedAt: form.plantedAt,
    ));
  }

  /// C2: borrar un cultivo hace match con lo que hace `deleteCrop`
  /// (`transaction_provider.dart`) — borra siembras y cosechas y deja los
  /// gastos/ventas sin cultivo — así que lo avisamos antes de ejecutar.
  Future<void> _confirmDelete(BuildContext context, TransactionProvider tx,
      Crop crop, AppLocalizations l10n) async {
    final sowings = tx.sowings.where((s) => s.cropId == crop.id).length;
    final harvests = tx.harvests.where((h) => h.cropId == crop.id).length;
    final hasHistory = sowings > 0 || harvests > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCropTitle),
        content: Text(hasHistory
            ? l10n.deleteCropBody(sowings, harvests, crop.name)
            : l10n.deleteCropBodyEmpty(crop.name)),
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
    if (confirmed != true || !context.mounted) return;
    await tx.deleteCrop(crop.id);
  }

  /// F4 · true cuando el contador de plantas ya no lo escribe el usuario:
  /// sale de las siembras, así que lo tecleado en el editor se perdería en la
  /// próxima. Solo la siembra inicial fija el número (una resiembra lo mueve).
  static bool _hasInitialSowing(TransactionProvider tx, Crop crop) => tx.sowings
      .any((s) => s.cropId == crop.id && s.kind == SowingKind.siembra);

  /// Formato corto de hectáreas en lenguaje llano: `0,4 ha`, `2 ha`.
  static String _ha(TransactionProvider tx, double v) =>
      NumberFormat('0.###', tx.settings.locale).format(v);

  Widget _row(
      BuildContext context, TransactionProvider tx, Crop crop, AppLocalizations l10n) {
    String phaseLabel(CropPhase p) => switch (p) {
          CropPhase.establecimiento => l10n.phaseEstablecimiento,
          CropPhase.produccion => l10n.phaseProduccion,
          CropPhase.renovacion => l10n.phaseRenovacion,
        };
    // F5 · edad junto a la fase. Si no hay datos (nada sembrado y sin fecha
    // en el editor) no se pinta nada: mejor callar que inventar un 0.
    final edad = edadDeCrop(crop, tx.sowings);

    // L2.3 (patrón H10): la fase se ve con icono de forma distinta + texto,
    // nunca solo con color.
    IconData phaseIcon(CropPhase p) => switch (p) {
          CropPhase.establecimiento => Icons.spa_outlined,
          CropPhase.produccion => Icons.agriculture_outlined,
          CropPhase.renovacion => Icons.autorenew,
        };

    // L2.2: los nombres se pueden repetir (C4), así que el nombre ya no
    // distingue. Solo con empate se añade el subtítulo que separa cada fila;
    // con nombre único la lista queda como siempre.
    var sameName = 0;
    var ordinal = 0;
    for (final c in tx.crops) {
      if (c.name.toLowerCase() != crop.name.toLowerCase()) continue;
      sameName++;
      if (c.id == crop.id) ordinal = sameName;
    }
    final areaText =
        crop.areaHa == null ? null : '${_ha(tx, crop.areaHa!)} ha';
    final tag = sameName > 1 ? (areaText ?? l10n.cropLotTag(ordinal)) : null;

    final details = <String>[
      crop.cycle == CropCycle.anual ? l10n.cycleAnual : l10n.cyclePerenne,
      if (crop.defaultUnit != null) crop.defaultUnit!,
      if (areaText != null && areaText != tag) areaText,
      if (crop.livePlants != null) '${crop.livePlants}',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(crop.icon),
        ),
        title: Text(
          crop.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag != null)
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFED6C02),
                ),
              ),
            Row(
              children: [
                Icon(
                  phaseIcon(crop.phase),
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    phaseLabel(crop.phase),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (edad != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '· ${l10n.cropAge(edad)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            if (details.isNotEmpty)
              Text(
                details.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editCrop(context, tx, crop),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(context, tx, crop, l10n),
            ),
          ],
        ),
      ),
    );
  }
}