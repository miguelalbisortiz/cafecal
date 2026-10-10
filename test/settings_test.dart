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

  group('A2 · sacoKg', () {
    test('por defecto es 70, el de la norma', () {
      expect(const FarmSettings().sacoKg, 70);
      expect(const FarmSettings().toJson()['saco_kg'], 70);
    });

    test('round-trip conserva el peso', () {
      const original = FarmSettings(sacoKg: 60);
      final restored = FarmSettings.fromJson(original.toJson());
      expect(restored.sacoKg, 60);
    });

    test('JSON viejo sin la clave → 70, nunca null ni un 0', () {
      final json = const FarmSettings().toJson()..remove('saco_kg');
      expect(FarmSettings.fromJson(json).sacoKg, 70);
    });

    test('copyWith cambia el peso sin tocar el resto', () {
      const original = FarmSettings(farmName: 'La Finca');
      final changed = original.copyWith(sacoKg: 60);
      expect(changed.sacoKg, 60);
      expect(changed.farmName, 'La Finca');
    });

    test('copyWith sin args lo conserva', () {
      const original = FarmSettings(sacoKg: 65);
      expect(original.copyWith().sacoKg, 65);
      expect(original.copyWith(currency: 'USD').sacoKg, 65);
    });
  });
}