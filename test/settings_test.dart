import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/settings.dart';

void main() {
  test('FarmSettings round-trip conserva lastCropId', () {
    const original = FarmSettings(lastCropId: 'cafe');
    final restored = FarmSettings.fromJson(original.toJson());
    expect(restored.lastCropId, 'cafe');
    expect(restored.language, 'es');
    expect(restored.currency, 'COP');
  });

  test('copyWith puede limpiar lastCropId a null', () {
    const original = FarmSettings(lastCropId: 'cafe');
    final cleared = original.copyWith(lastCropId: null);
    expect(cleared.lastCropId, isNull);
    expect(cleared.farmName, original.farmName);
  });

  test('sin lastCropId el JSON no incluye la clave', () {
    const plain = FarmSettings();
    expect(plain.toJson().containsKey('last_crop_id'), isFalse);
  });
}