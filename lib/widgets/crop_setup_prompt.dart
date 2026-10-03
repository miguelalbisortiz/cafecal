import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../providers/transaction_provider.dart';
import 'crop_editor_dialog.dart';

/// Aviso opcional "completa los datos de tu cultivo" (L2.5b).
///
/// Se muestra **después** de crear un cultivo desde una puerta corta
/// (Siembras, Registro, Asignar), nunca desde la pantalla de Cultivos, que ya
/// ofrece el formulario completo.
///
/// Es un banner superior, no un modal: no bloquea nada y se cierra con
/// "Ahora no". Si el productor dice que no, la preferencia queda guardada en
/// preferencias locales y la app **no vuelve a preguntar**.
class CropSetupPrompt {
  CropSetupPrompt._();

  static const String dismissedKey = 'crop_setup_prompt_dismissed_v1';

  /// true si todavía corresponde ofrecer completar los datos.
  static Future<bool> canAsk() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(dismissedKey) ?? false);
  }

  /// Marca la respuesta "Ahora no": no se pregunta nunca más.
  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dismissedKey, true);
  }

  /// Ofrece completar los datos de [crop] si el usuario todavía no dijo que
  /// no. [context] debe ser el de una pantalla viva con Scaffold.
  static Future<void> show(
    BuildContext context,
    TransactionProvider tx,
    Crop crop,
  ) async {
    if (!await canAsk()) return;
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
            markDismissed();
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
    ));
  }
}
