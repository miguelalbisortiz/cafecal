import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/terreno.dart';
import 'crop_units.dart';

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
/// Tanda 2A · el alta corta también puede traer el contexto mínimo que el
/// productor quiera dar en ese momento: [terrenoId], [areaHa] y [defaultUnit].
/// Los tres son opcionales; null significa "no lo sé todavía", no cero.
///
/// `null` como resultado completo significa "cancelado".
class NewCropResult {
  /// Nombre escrito por el productor (recortado).
  final String name;

  /// Id del cultivo existente elegido, o `null` si se crea uno nuevo.
  final String? existingId;

  /// Lote elegido en el alta corta, o `null` si no se eligió ninguno.
  final String? terrenoId;

  /// Hectáreas escritas en el alta corta, o `null` si se dejó vacío.
  final double? areaHa;

  /// Unidad preferida elegida en el alta corta, o `null` si no se eligió.
  final String? defaultUnit;

  const NewCropResult({
    required this.name,
    this.existingId,
    this.terrenoId,
    this.areaHa,
    this.defaultUnit,
  });

  /// true si hay que crear un cultivo nuevo con [name].
  bool get isNew => existingId == null;
}

/// Diálogo para crear un cultivo nuevo.
///
/// Si el nombre coincide (sin distinguir mayúsculas) con uno ya existente,
/// muestra una **segunda pregunta** con tres salidas claras: usar el que ya
/// tienes, crear otro igual o cancelar. Nunca devuelve un nombre ambiguo.
///
/// Tanda 2A · además del nombre ofrece, como opcionales, el lote (si hay
/// terrenos creados), el área y la unidad preferida. No es el formulario
/// completo: es lo que se puede contestar en dos segundos sin salir de la
/// pantalla que se estaba usando.
class NewCropDialog extends StatefulWidget {
  final List<Crop> crops;

  /// Lotes disponibles. Vacío = no se muestra el desplegable de terreno:
  /// no se le puede pedir que elija algo que todavía no existe.
  final List<Terreno> terrenos;

  const NewCropDialog({
    super.key,
    required this.crops,
    this.terrenos = const [],
  });

  @override
  State<NewCropDialog> createState() => _NewCropDialogState();
}

class _NewCropDialogState extends State<NewCropDialog> {
  final _controller = TextEditingController();
  final _areaController = TextEditingController();
  String? _error;

  /// Nombre escrito que choca con uno ya existente. Mientras haya valor, el
  /// diálogo muestra la segunda pregunta en vez del campo de texto.
  String? _duplicateName;
  Crop? _duplicateMatch;

  /// Contexto opcional del alta corta. `''` es un centinela para el terreno
  /// (los ids son uuid), no un id real.
  String? _terrenoId;
  String? _defaultUnit;
  double? _areaHa;

  @override
  void dispose() {
    _controller.dispose();
    _areaController.dispose();
    super.dispose();
  }

  NewCropResult _result(String name) => NewCropResult(
        name: name,
        terrenoId: _terrenoId,
        areaHa: _areaHa,
        defaultUnit: _defaultUnit,
      );

  /// Area en hectáreas, o null si el productor la dejó vacía.
  ///
  /// Devuelve false si escribió algo que no es un número positivo; el error
  /// se pinta en el campo para que pueda corregirlo sin perder el resto.
  bool _readArea(AppLocalizations l10n) {
    final text = _areaController.text.trim();
    if (text.isEmpty) {
      _areaHa = null;
      return true;
    }
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      _areaHa = null;
      _error = l10n.cropAreaInvalid;
      return false;
    }
    _areaHa = value;
    return true;
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = _controller.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.cropNameRequired);
      return;
    }
    if (!_readArea(l10n)) {
      setState(() {});
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
    Navigator.pop(context, _result(n));
  }

  void _useExisting() {
    final match = _duplicateMatch;
    final name = _duplicateName;
    if (match == null || name == null) return;
    // El cultivo elegido ya existe: su contexto es el que tiene, no lo que
    // se acaba de escribir aquí.
    Navigator.pop(context, NewCropResult(name: name, existingId: match.id));
  }

  void _createAnother() {
    final name = _duplicateName;
    if (name == null) return;
    Navigator.pop(context, _result(name));
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.cropNameLabel,
                errorText: _error,
                prefixIcon: const Icon(Icons.grass_outlined),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.terrenos.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _terrenoId ?? '',
                decoration: InputDecoration(
                  labelText: l10n.cropTerrenoLabel,
                  helperText: l10n.quickAddOptionalHelp,
                  prefixIcon: const Icon(Icons.landscape_outlined),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(l10n.cropTerrenoNone),
                  ),
                  for (final t in widget.terrenos)
                    DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(t.name),
                    ),
                ],
                onChanged: (v) => setState(
                    () => _terrenoId = (v == null || v.isEmpty) ? null : v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.areaHaLabel,
                helperText: l10n.quickAddOptionalHelp,
                prefixIcon: const Icon(Icons.square_foot_outlined),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _defaultUnit,
              decoration: InputDecoration(
                labelText: l10n.defaultUnitLabel,
                helperText: l10n.quickAddOptionalHelp,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(l10n.defaultUnitNone),
                ),
                ...cropUnitOptions.map((u) => DropdownMenuItem<String>(
                      value: u,
                      child: Text(cropUnitLabel(u, l10n)),
                    )),
              ],
              onChanged: (v) => setState(() => _defaultUnit = v),
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
