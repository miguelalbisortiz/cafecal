import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/sowing.dart';
import '../providers/transaction_provider.dart';

/// F4 · Puerta de salida del bloqueo de área y plantas.
///
/// Cuando el cultivo ya tiene siembra inicial, el número de plantas sale de
/// las siembras: cualquier cosa tecleada en el editor se pierde en la próxima.
/// Para que el productor no quede encerrado, aquí anota **cuántas plantas
/// quedan** y la app escribe la resiembra que corresponde.
///
/// Un solo campo cubre los dos casos que él vive en la finca:
///
/// - **se murieron** → `quedan < las que había` → resiembra con 0 plantas
///   nuevas y `lostPlants` = la diferencia. Era justo lo que el validador
///   impedía: se registraba la mortandad sin reponer plantas.
/// - **no cuadraba su cuenta** → `quedan > las que había` → resiembra que
///   suma la diferencia. El ajuste de salida, por si se le olvidó anotar algo.
///
/// No se pisa ningún dato: el modelo ya sabe mover el contador con
/// `livePlants − perdidas + nuevas` (`recomputeCropState`), y el registro
/// queda en el historial como cualquier otra resiembra.
class CropLossDialog extends StatefulWidget {
  final Crop crop;

  /// Plantas que la app calcula hoy para este cultivo.
  final int currentPlants;

  const CropLossDialog({
    super.key,
    required this.crop,
    required this.currentPlants,
  });

  @override
  State<CropLossDialog> createState() => _CropLossDialogState();
}

class _CropLossDialogState extends State<CropLossDialog> {
  final _formKey = GlobalKey<FormState>();
  final _remainingController = TextEditingController();
  final _reasonController = TextEditingController();

  int? get _remaining {
    final t = _remainingController.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  /// Plantas de más (+) o de menos (−) frente a lo que la app calcula.
  int? get _delta {
    final r = _remaining;
    return r == null ? null : r - widget.currentPlants;
  }

  @override
  void dispose() {
    _remainingController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final delta = _delta;
    if (delta == null || delta == 0) return;

    final reason = _reasonController.text.trim();
    final tx = context.read<TransactionProvider>();
    await tx.addSowing(
      cropId: widget.crop.id,
      date: DateTime.now(),
      kind: SowingKind.resiembra,
      // `livePlants − perdidas + nuevas` = el total que él anotó.
      plants: delta > 0 ? delta : 0,
      lostPlants: delta < 0 ? -delta : null,
      reason: reason.isEmpty ? null : reason,
    );

    // Se devuelve el contador **recalculado**, no el que él tecleó: si sus
    // cuentas y las de la app no coincidían, manda lo que salga de las
    // siembras. Así el editor no se queda con un número viejo.
    int? nuevo;
    for (final c in tx.crops) {
      if (c.id == widget.crop.id) {
        nuevo = c.livePlants;
        break;
      }
    }

    if (!mounted) return;
    Navigator.pop(context, nuevo ?? _remaining);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final delta = _delta;

    return AlertDialog(
      title: Text(l10n.cropLossRegister),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cropLossCurrent(widget.currentPlants),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remainingController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.cropLossRemainingLabel,
                helperText: l10n.cropLossRemainingHelp,
                prefixIcon: const Icon(Icons.trending_down),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                final n = int.tryParse(t);
                if (n == null || n < 0) return l10n.cropLossInvalid;
                if (n == widget.currentPlants) return l10n.cropLossNoChange;
                return null;
              },
            ),
            if (delta != null && delta != 0) ...[
              const SizedBox(height: 8),
              Text(
                delta < 0
                    ? l10n.cropLossPreviewDied(-delta)
                    : l10n.cropLossPreviewAdded(delta),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: l10n.sowingReasonLabel,
                prefixIcon: const Icon(Icons.notes),
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
        FilledButton(onPressed: _save, child: Text(l10n.add)),
      ],
    );
  }
}
