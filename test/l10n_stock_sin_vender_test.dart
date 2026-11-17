import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';

/// SC-G6 · las claves del hito 1 existen en los dos idiomas, con los
/// placeholders en orden de frase, sin `$` y sin `→` (el Roboto del PDF no
/// trae ese glifo).

Map<String, dynamic> arbDe(String idioma) =>
    jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('stock sin vender: ARB y generado en ES y EN', () {
    for (final idioma in ['es', 'en']) {
      final arb = arbDe(idioma);
      expect(arb['stockUnsoldTitle'], isA<String>(),
          reason: '$idioma · falta stockUnsoldTitle');
      expect(arb['stockUnsoldLine'], isA<String>(),
          reason: '$idioma · falta stockUnsoldLine');

      final linea = arb['stockUnsoldLine'] as String;
      expect(linea, contains('{kg}'));
      expect(linea, contains('{crop}'));
      expect(linea.indexOf('{kg}'), lessThan(linea.indexOf('{crop}')),
          reason: '$idioma · el orden de la frase manda en la firma');
      expect(linea, isNot(contains(r'$')));
      expect(linea, isNot(contains('→')));

      final l10n = stringsFor(idioma);
      expect((l10n as dynamic).stockUnsoldTitle, isA<String>());
      expect((l10n as dynamic).stockUnsoldLine('60', 'Café'), isA<String>());
    }

    expect(arbDe('es')['stockUnsoldLine'], contains('Define comprador'));
    expect(arbDe('en')['stockUnsoldLine'], contains('Define a buyer'));
  });
}
