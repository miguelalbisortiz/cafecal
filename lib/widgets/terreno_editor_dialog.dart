import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/terreno.dart';

/// Editor de terreno (crear y editar): nombre, hectáreas opcionales, la
/// ubicación del lote y la lista de cultivos que van dentro.
///
/// La lista de cultivos va con **casillas** y no con un desplegable porque
/// el reparto no es "uno o ninguno": un mismo terreno guarda café con
/// plátano y sombra a la vez, que es justamente lo que hacía falta poder
/// decir. Y la casilla manda: lo marcado entra, lo desmarcado sale — mover
/// un cultivo de sitio es quitarle una etiqueta a uno y ponérsela a otro,
/// nunca borrarlo.
///
/// ## La ubicación
///
/// Es el punto del **lote**, no la posición del teléfono. Por eso hay tres
/// caminos y ninguno manda sobre otro: se puede **tomar desde el celular**,
/// **escribir a mano** (las coordenadas que le dé el agrónomo o su
/// comprador) o **borrarla**.
///
/// Y la regla que gobierna todo el bloque: **la app jamás vuelve a medir
/// sola**. La coordenada es un hecho de la tierra; re-medirla al abrir el
/// diálogo movería el lote sin avisar, que es exactamente inventar datos.
/// Por eso el botón solo actúa cuando él lo aprieta.
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
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  late final Set<String> _selected;

  /// El día en que se tomó la ubicación. Solo lo pone el botón: si él
  /// escribe a mano, se registra el día en que lo anota.
  DateTime? _locatedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.terreno?.name ?? '';
    final area = widget.terreno?.areaHa;
    if (area != null) _areaController.text = area.toString();
    final lat = widget.terreno?.lat;
    if (lat != null) _latController.text = lat.toString();
    final lng = widget.terreno?.lng;
    if (lng != null) _lngController.text = lng.toString();
    _locatedAt = widget.terreno?.locatedAt;
    _selected = {...widget.initialCropIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  /// Un solo punto de entrada para leer una coordenada. Vacío → `null`
  /// (sin ubicar); ilegible → también `null`, pero [ _submit] distingue
  /// ambos casos antes de avisar.
  double? _parseCoord(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// Toma la posición actual del equipo. **Solo se llama si él aprieta el
  /// botón** — nunca sola, ni al abrir el diálogo.
  Future<void> _captureLocation() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _error = l10n.terrenoLocationFailed);
        return;
      }
      // Precisión fina: la EUDR pide la coordenada con 6 decimales.
      // Funciona sin cobertura de datos, solo con señal de satélite.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        _locatedAt = DateTime.now();
        _error = null;
      });
    } catch (_) {
      // Sin GPS, sin permiso, o el equipo no puede decirlo: no se inventa
      // nada, se le avisa y se queda el camino manual.
      if (!mounted) return;
      setState(() => _error = l10n.terrenoLocationFailed);
    }
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

    // Ubicación: ninguna → sin ubicar. Solo una → no dice dónde está nada.
    // Las dos fuera de rango o ilegibles → dato mentiroso, no se guarda.
    final latRaw = _latController.text.trim();
    final lngRaw = _lngController.text.trim();
    double? lat;
    double? lng;
    if (latRaw.isNotEmpty || lngRaw.isNotEmpty) {
      if (latRaw.isEmpty || lngRaw.isEmpty) {
        setState(() => _error = l10n.terrenoLocationHalf);
        return;
      }
      lat = _parseCoord(latRaw);
      lng = _parseCoord(lngRaw);
      if (lat == null ||
          lng == null ||
          lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180) {
        setState(() => _error = l10n.terrenoLocationInvalid);
        return;
      }
    }

    // El día de registro se conserva si ya existía; si es la primera vez,
    // es hoy. Se borra junto con la coordenada: una fecha sin punto no dice
    // nada.
    final DateTime? locatedAt = (lat != null && lng != null)
        ? (_locatedAt ?? widget.terreno?.locatedAt ?? DateTime.now())
        : null;

    Navigator.pop(context, TerrenoFormData(
      name: n,
      areaHa: area,
      lat: lat,
      lng: lng,
      locatedAt: locatedAt,
      cropIds: _selected.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.terreno != null;
    final hasCrops = widget.crops.isNotEmpty;
    final locatedAt = _locatedAt;

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
                l10n.terrenoLocationSection,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.terrenoLocationHelper,
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _captureLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(l10n.terrenoLocationButton),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.terrenoLatLabel,
                        prefixIcon: const Icon(Icons.explore_outlined),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.terrenoLngLabel,
                        prefixIcon: const Icon(Icons.explore_outlined),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              if (locatedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.terrenoLocationDate(
                    DateFormat.yMMMMd(l10n.localeName).format(locatedAt),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
  final double? lat;
  final double? lng;
  final DateTime? locatedAt;
  final List<String> cropIds;

  const TerrenoFormData({
    required this.name,
    this.areaHa,
    this.lat,
    this.lng,
    this.locatedAt,
    this.cropIds = const [],
  });
}
