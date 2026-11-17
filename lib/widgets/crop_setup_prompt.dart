import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/sowing.dart';
import '../providers/transaction_provider.dart';
import 'crop_editor_dialog.dart';

/// Aviso opcional "completa los datos de tu cultivo" (L2.5b).
///
/// Se muestra **después** de crear un cultivo desde una puerta corta
/// (Siembras, Registro, Asignar), nunca desde la pantalla de Cultivos, que ya
/// ofrece el formulario completo.
///
/// Es un banner superior, no un modal: no bloquea nada y se cierra con
/// "Ahora no". El descarte es **por cultivo**: decir que no en uno no calla
/// los avisos de los demás, y un cultivo nuevo siempre merece su pregunta.
///
/// La clave vieja `crop_setup_prompt_dismissed_v1` era global y se ignora:
/// estaba mal porque convertía un "ahora no" puntual en un silencio para
/// siempre. Se deja de leer, no se migra su valor.
class CropSetupPrompt {
  CropSetupPrompt._();

  /// Ids de los cultivos a los que ya se les dijo "ahora no".
  static const String dismissedKey = 'crop_setup_prompt_dismissed_v2';

  static Future<List<String>> _dismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(dismissedKey) ?? const <String>[];
  }

  /// true si todavía corresponde ofrecer completar los datos de [cropId].
  static Future<bool> canAsk(String cropId) async {
    final ids = await _dismissedIds();
    return !ids.contains(cropId);
  }

  /// Marca la respuesta "Ahora no" para este cultivo únicamente.
  static Future<void> markDismissed(String cropId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(
        prefs.getStringList(dismissedKey) ?? const <String>[]);
    if (ids.contains(cropId)) return;
    ids.add(cropId);
    await prefs.setStringList(dismissedKey, ids);
  }

  /// Ofrece completar los datos de [crop] si el usuario todavía no dijo que
  /// no para **ese** cultivo. [context] debe ser el de una pantalla viva con
  /// Scaffold.
  static Future<void> show(
    BuildContext context,
    TransactionProvider tx,
    Crop crop,
  ) async {
    if (!await canAsk(crop.id)) return;
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    late final ScaffoldFeatureController<MaterialBanner,
        MaterialBannerClosedReason> controller;
    controller = messenger.showMaterialBanner(MaterialBanner(
      content: Text(l10n.cropSetupPrompt),
      actions: [
        TextButton(
          onPressed: () {
            controller.close();
            _openEditor(context, tx, crop);
          },
          child: Text(l10n.cropSetupComplete),
        ),
        TextButton(
          onPressed: () {
            controller.close();
            markDismissed(crop.id);
          },
          child: Text(l10n.cropSetupLater),
        ),
      ],
    ));
  }

  /// Abre el editor de cultivo y aplica lo que se cambie (updateCrop).
  static Future<void> _openEditor(
    BuildContext context,
    TransactionProvider tx,
    Crop crop,
  ) async {
    if (!context.mounted) return;
    final form = await showDialog<CropFormData>(
      context: context,
      builder: (_) => CropEditorDialog(
        crop: crop,
        existingNames: tx.crops.map((c) => c.name).toList(),
        suggestedEstablishmentCost: tx.initialSowingCost(crop.id),
        sowingsLocked: tx.sowings
            .any((s) => s.cropId == crop.id && s.kind == SowingKind.siembra),
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
      currency: form.currency,
      plantedAt: form.plantedAt,
      // E4: ídem crops_screen — el null del campo vacío borra la meta.
      expectedYieldPerHa: form.expectedYieldPerHa,
      // E5: ídem — la fecha estimada se puede borrar.
      primerCosechaEsperada: form.primerCosechaEsperada,
    ));
  }
}
