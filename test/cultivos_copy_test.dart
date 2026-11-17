import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda de copy: el agricultor ve «cultivo», no «variedad», y la tarjeta
/// del aporte dice la regla que el código aplica de verdad.
void main() {
  Map<String, dynamic> arbDe(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  for (final ruta in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
    test('$ruta nombra cultivo y distingue las dos atribuciones', () {
      final arb = arbDe(ruta);
      final es = ruta.contains('_es.');

      for (final clave in [
        'helpStartingStep1',
        'cropNewOption',
        'cropGroupHint',
        'sowingCategoryHint',
        'newCropDialogTitle',
      ]) {
        expect(arb[clave], isA<String>(), reason: '$ruta · $clave falta');
        expect((arb[clave] as String).toLowerCase().contains('variedad'),
            isFalse,
            reason: '$ruta · $clave: el campo es nombre de cultivo, no variedad');
      }
      if (es) {
        expect(arb['helpStartingStep1'], contains('anual'));
        expect(arb['helpStartingStep1'].toString().contains('transitorio'),
            isFalse);
        // Tanda 2C · el aporte por producto NO reparte: decir lo contrario
        // hacía comparar dos cifras con reglas distintas como si fueran iguales.
        expect(arb['contributionSubtitle'], contains('no reparte'),
            reason: 'el aporte deja el gasto de lote y el común aparte');
        expect(arb['contributionSubtitle'], isNot(contains('se reparte')));
      } else {
        expect(arb['contributionSubtitle'], contains('does not split'),
            reason: 'the contribution leaves plot and common costs separate');
        expect(arb['contributionSubtitle'], isNot(contains('are split')));
      }
    });
  }
}
