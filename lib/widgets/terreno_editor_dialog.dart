import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/terreno.dart';

/// Editor de terreno (crear y editar): nombre, hectáreas opcionales y la
/// lista de cultivos que van dentro.
///
/// La lista de cultivos va con **casillas** y no con un desplegable porque
/// el reparto no es "uno o ninguno": un mismo terreno guarda café con
/// plátano y sombra a la vez, que es justamente lo que hacía falta poder
/// decir. Y la casilla manda: lo marcado entra, lo desmarcado sale — mover
/// un cultivo de sitio es quitarle una etiqueta a uno y ponérsela a otro,
/// nunca borrarlo.
///
/// Devuelve los valores editados (patrón [CropEditorDialog]); quien confirme
/// aplica los cambios con `addTerreno` / `updateTerrenoWithCrops`.
class TerrenoEditorDialog extends StatefulWidget {
  /// null = creando un terreno nuevo.
  final Terreno? terreno;

  /// Los cultivos de la finca, para ofrecerlos como casillas.
  final List<Crop> crops;

  /// Los que ya vienen marcados (al editar: los que están en este terreno).
  final List<String> initialCropIds;

  /// Nombres ya usados, para no repetir. Se excluye el propio al editar.
  final List<String> existingNames;

  const TerrenoEditorDialog({
    super.key,
    this.terreno,
    required this.crops,
    this.initialCropIds = const [],
    this.existingNames = const [],
  });

  @override
  State<TerrenoEditorDialog> createState() => _TerrenoEditorDialogState();
}

class _TerrenoEditorDialogState extends State<TerrenoEditorDialog> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  late final Set<String> _selected;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.terreno?.name ?? '';
    final area = widget.terreno?.areaHa;
    if (area != null) _areaController.text = area.toString();
    _selected = {...widget.initialCropIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = _nameController.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.terrenoNameRequired);
      return;
    }
    final dup = widget.existingNames.any((e) =>
        e.toLowerCase() == n.toLowerCase() && e != widget.terreno?.name);
    if (dup) {
      setState(() => _error = l10n.terrenoNameTaken);
      return;
    }
    // Opcional y borrable: vacío → null → el terreno no tiene área y la app
    // no le inventa una (regla de oro: null → oculto, nunca 0).
    final areaText = _areaController.text.trim().replaceAll(',', '.');
    double? area;
    if (areaText.isNotEmpty) {
      area = double.tryParse(areaText);
      if (area == null || area <= 0) {
        setState(() => _error = l10n.terrenoAreaInvalid);
        return;
      }
    }
    Navigator.pop(context, TerrenoFormData(
      name: n,
      areaHa: area,
      cropIds: _selected.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.terreno != null;
    final hasCrops = widget.crops.isNotEmpty;

    return AlertDialog(
      title: Text(editing ? l10n.terrenoEdit : l10n.terrenoNew),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.terrenoNameLabel,
                  errorText: _error,
                  prefixIcon: const Icon(Icons.landscape_outlined),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.terrenoAreaLabel,
                  helperText: l10n.helpTerrenoArea,
                  prefixIcon: const Icon(Icons.square_foot_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.terrenoCropsLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.helpTerrenoCrops,
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 4),
              if (!hasCrops)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.terrenoCropsEmpty,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final c in widget.crops)
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    value: _selected.contains(c.id),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(c.id);
                      } else {
                        _selected.remove(c.id);
                      }
                    }),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? l10n.saveChanges : l10n.add),
        ),
      ],
    );
  }
}

class TerrenoFormData {
  final String name;
  final double? areaHa;
  final List<String> cropIds;

  const TerrenoFormData({
    required this.name,
    this.areaHa,
    this.cropIds = const [],
  });
}
