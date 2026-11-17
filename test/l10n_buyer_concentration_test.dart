import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';

/// SC-G6 · las claves del hito 3 existen en los dos idiomas, con los
/// placeholders en orden de frase, declarados `String`, sin `$` ni `→`
/// (el Roboto del PDF no trae ese glifo).

Map<String, dynamic> arbDe(String idioma) =>
    jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('concentración de comprador: ARB y generado en ES y EN', () {
    for (final idioma in ['es', 'en']) {
      final arb = arbDe(idioma);
      expect(arb['buyerConcentrationTitle'], isA<String>(),
          reason: '$idioma · falta buyerConcentrationTitle');
      expect(arb['buyerConcentrationLine'], isA<String>(),
          reason: '$idioma · falta buyerConcentrationLine');

      final meta = arb['@buyerConcentrationLine'] as Map<String, dynamic>;
      final placeholders = meta['placeholders'] as Map<String, dynamic>;
      expect(placeholders.keys.toList(), ['pct', 'buyer'],
          reason: '$idioma · orden de la firma');
      for (final clave in placeholders.keys) {
        expect((placeholders[clave] as Map)['type'], 'String',
            reason: '$idioma · $clave debe ser String');
      }

      final linea = arb['buyerConcentrationLine'] as String;
      expect(linea.indexOf('{pct}'), lessThan(linea.indexOf('{buyer}')));
      expect(linea, isNot(contains(r'$')));
      expect(linea, isNot(contains('→')));
      // D2: la fila cita el porcentaje y el nombre, nunca un monto.
      expect(linea, isNot(contains('{money}')));
      expect(linea, isNot(contains('{amount}')));

      final l10n = stringsFor(idioma);
      expect((l10n as dynamic).buyerConcentrationTitle, isA<String>());
      expect((l10n as dynamic).buyerConcentrationLine('70', 'A'),
          isA<String>());
      expect((l10n as dynamic).buyerConcentrationLine('70', 'A'),
          contains('70'));
      expect((l10n as dynamic).buyerConcentrationLine('70', 'A'),
          contains('A'));
    }

    expect(arbDe('es')['buyerConcentrationTitle'],
        'Concentración de comprador');
    expect(arbDe('en')['buyerConcentrationTitle'], 'Buyer concentration');
    // La acción de buscar un segundo comprador está en los dos idiomas.
    expect(arbDe('es')['buyerConcentrationLine'].toLowerCase(),
        contains('segundo comprador'));
    expect(arbDe('en')['buyerConcentrationLine'].toLowerCase(),
        contains('second buyer'));
  });
}
