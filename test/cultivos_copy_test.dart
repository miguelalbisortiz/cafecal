import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda de copy: el agricultor ve «cultivo», no «variedad», y la tarjeta
/// del aporte dice la regla que el código aplica de verdad.
void main() {
  Map<String, dynamic> arbDe(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  for (final ruta in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
    test('$ruta nombra cultivo y explica el reparto por área', () {
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
        expect(arb['contributionSubtitle'], contains('reparte'),
            reason: 'el gasto de lote sí se reparte cuando hay áreas medidas');
      } else {
        expect(arb['contributionSubtitle'], contains('split'),
            reason: 'el gasto de lote sí se reparte cuando hay áreas medidas');
      }
    });
  }
}
