import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';

/// Resultado de [NewCropDialog].
///
/// El diálogo ya no decide en silencio por el usuario (C4: los nombres se
/// pueden repetir). Distingue los dos casos que antes eran indistinguibles:
///
/// * [existingId] con valor → el productor eligió **usar el cultivo que ya
///   tiene**; hay que seleccionar ese id, sin crear nada.
/// * [existingId] null → **cultivo nuevo** con ese nombre, aunque ya exista
///   otro con el mismo texto.
///
/// `null` como resultado completo significa "cancelado".
class NewCropResult {
  /// Nombre escrito por el productor (recortado).
  final String name;

  /// Id del cultivo existente elegido, o `null` si se crea uno nuevo.
  final String? existingId;

  const NewCropResult({required this.name, this.existingId});

  /// true si hay que crear un cultivo nuevo con [name].
  bool get isNew => existingId == null;
}

/// Diálogo para crear un cultivo nuevo.
///
/// Si el nombre coincide (sin distinguir mayúsculas) con uno ya existente,
/// muestra una **segunda pregunta** con tres salidas claras: usar el que ya
/// tienes, crear otro igual o cancelar. Nunca devuelve un nombre ambiguo.
class NewCropDialog extends StatefulWidget {
  final List<Crop> crops;

  const NewCropDialog({super.key, required this.crops});

  @override
  State<NewCropDialog> createState() => _NewCropDialogState();
}

class _NewCropDialogState extends State<NewCropDialog> {
  final _controller = TextEditingController();
  String? _error;

  /// Nombre escrito que choca con uno ya existente. Mientras haya valor, el
  /// diálogo muestra la segunda pregunta en vez del campo de texto.
  String? _duplicateName;
  Crop? _duplicateMatch;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final n = _controller.text.trim();
    if (n.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.cropNameRequired);
      return;
    }
    Crop? match;
    for (final c in widget.crops) {
      if (c.name.toLowerCase() == n.toLowerCase()) {
        match = c;
        break;
      }
    }
    if (match != null) {
      setState(() {
        _duplicateName = n;
        _duplicateMatch = match;
        _error = null;
      });
      return;
    }
    Navigator.pop(context, NewCropResult(name: n));
  }

  void _useExisting() {
    final match = _duplicateMatch;
    final name = _duplicateName;
    if (match == null || name == null) return;
    Navigator.pop(context, NewCropResult(name: name, existingId: match.id));
  }

  void _createAnother() {
    final name = _duplicateName;
    if (name == null) return;
    Navigator.pop(context, NewCropResult(name: name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duplicate = _duplicateName;
    if (duplicate != null) {
      return AlertDialog(
        title: Text(l10n.newCropDuplicateTitle),
        content: Text(l10n.newCropDuplicateBody(duplicate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: _useExisting,
            child: Text(l10n.newCropUseExisting),
          ),
          FilledButton(
            onPressed: _createAnother,
            child: Text(l10n.newCropCreateAnother),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(l10n.newCropDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.cropNameLabel,
          errorText: _error,
          prefixIcon: const Icon(Icons.grass_outlined),
        ),
        onSubmitted: (_) => _submit(),
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
