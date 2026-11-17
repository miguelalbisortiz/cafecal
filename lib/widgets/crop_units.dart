import '../l10n/generated/app_localizations.dart';

/// Unidades de medida de un cultivo, en un solo lugar.
///
/// Tanto el editor completo ([CropEditorDialog]) como el alta corta
/// ([NewCropDialog]) deben ofrecer exactamente las mismas opciones: si una
/// dijera "arroba" y la otra "Arrobas (12.5 kg)", el productor no sabría si
/// son la misma unidad.
const List<String> cropUnitOptions = [
  'kg',
  'lb',
  'arroba',
  'saco',
  'carga',
  'racimo',
  'cajon',
];

/// Etiqueta traducida de una clave de [cropUnitOptions].
String cropUnitLabel(String key, AppLocalizations l10n) => switch (key) {
      'kg' => l10n.unitKg,
      'arroba' => l10n.unitArroba,
      'saco' => l10n.unitSaco,
      'racimo' => l10n.unitRacimo,
      'cajon' => l10n.unitCajon,
      _ => key,
    };
