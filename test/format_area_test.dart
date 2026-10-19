import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/utils/format.dart';

/// A7 · el área de un terreno se escribe como en Cultivos: hasta tres
/// decimales, sin ceros de sobra y con el separador decimal del idioma.
void main() {
  test('formatea hectáreas con el decimal del idioma', () {
    expect(formatAreaHa(0.4, 'es'), '0,4');
    expect(formatAreaHa(0.4, 'en'), '0.4');
  });

  test('un entero no lleva decimales', () {
    expect(formatAreaHa(2, 'es'), '2');
  });

  test('hasta tres decimales, sin ceros de sobra', () {
    expect(formatAreaHa(1.25, 'en'), '1.25');
    expect(formatAreaHa(0.125, 'en'), '0.125');
    expect(formatAreaHa(1.5, 'es'), '1,5');
  });
}
