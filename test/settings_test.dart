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

  test('FarmSettings round-trip conserva lowPriceThresholdPerKg', () {
    const original = FarmSettings(lowPriceThresholdPerKg: 80000);
    final restored = FarmSettings.fromJson(original.toJson());
    expect(restored.lowPriceThresholdPerKg, 80000);
  });

  test('copyWith puede limpiar lowPriceThresholdPerKg a null', () {
    const original = FarmSettings(lowPriceThresholdPerKg: 80000);
    final cleared = original.copyWith(lowPriceThresholdPerKg: null);
    expect(cleared.lowPriceThresholdPerKg, isNull);
    expect(cleared.farmName, original.farmName);
  });

  test('copyWith sin args conserva lowPriceThresholdPerKg', () {
    const original = FarmSettings(lowPriceThresholdPerKg: 38000);
    final same = original.copyWith();
    expect(same.lowPriceThresholdPerKg, 38000);
  });

  group('cajaMenorMensual', () {
    test('round-trip conserva el monto', () {
      const original = FarmSettings(cajaMenorMensual: 800000);
      final restored = FarmSettings.fromJson(original.toJson());
      expect(restored.cajaMenorMensual, 800000);
    });

    test('sin monto el JSON no incluye la clave', () {
      expect(
          const FarmSettings()
              .toJson()
              .containsKey('caja_menor_mensual'),
          isFalse);
    });

    test('fromJson retrocompatible: sin la clave queda en null', () {
      final restored = FarmSettings.fromJson(const FarmSettings().toJson());
      expect(restored.cajaMenorMensual, isNull);
    });

    test('copyWith puede limpiar el monto a null', () {
      const original = FarmSettings(cajaMenorMensual: 800000);
      final cleared = original.copyWith(cajaMenorMensual: null);
      expect(cleared.cajaMenorMensual, isNull);
      expect(cleared.farmName, original.farmName);
    });

    test('copyWith sin args conserva el monto', () {
      const original = FarmSettings(cajaMenorMensual: 650000);
      expect(original.copyWith().cajaMenorMensual, 650000);
      expect(original.copyWith(farmName: 'Otra').cajaMenorMensual, 650000);
    });
  });
}