import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';

/// SC-G6 · las claves del hito 2 existen en los dos idiomas, con los
/// placeholders en orden de frase y declarados `String`; sin `$` ni `→`
/// (el Roboto del PDF no trae ese glifo).

Map<String, dynamic> arbDe(String idioma) =>
    jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('margen por cultivo: ARB y generado en ES y EN', () {
    for (final idioma in ['es', 'en']) {
      final arb = arbDe(idioma);
      expect(arb['cropMarginTitle'], isA<String>(),
          reason: '$idioma · falta cropMarginTitle');
      expect(arb['cropMarginLine'], isA<String>(),
          reason: '$idioma · falta cropMarginLine');

      final meta = arb['@cropMarginLine'] as Map<String, dynamic>;
      final placeholders = meta['placeholders'] as Map<String, dynamic>;
      expect(placeholders.keys.toList(), ['crop', 'pct', 'money'],
          reason: '$idioma · orden de la firma');
      for (final clave in placeholders.keys) {
        expect((placeholders[clave] as Map)['type'], 'String',
            reason: '$idioma · $clave debe ser String');
      }

      final linea = arb['cropMarginLine'] as String;
      expect(linea.indexOf('{crop}'), lessThan(linea.indexOf('{pct}')));
      expect(linea.indexOf('{pct}'), lessThan(linea.indexOf('{money}')));
      expect(linea, isNot(contains(r'$')));
      expect(linea, isNot(contains('→')));
      for (final prohibida in ['densidad', 'variedad', 'sombra', 'recepa']) {
        expect(linea.toLowerCase(), isNot(contains(prohibida)),
            reason: '$idioma · la app no registra $prohibida');
      }

      final l10n = stringsFor(idioma);
      expect((l10n as dynamic).cropMarginTitle, isA<String>());
      expect((l10n as dynamic).cropMarginLine('Café', '60', 'COP 150.000'),
          isA<String>());
      expect((l10n as dynamic).cropMarginLine('Café', '60', 'COP 150.000'),
          contains('Café'));
    }

    expect(arbDe('es')['cropMarginTitle'], 'Margen por cultivo');
    expect(arbDe('en')['cropMarginTitle'], 'Margin by crop');
    // La acción de priorizar la mano de obra está en los dos idiomas.
    expect(arbDe('es')['cropMarginLine'].toLowerCase(), contains('mano de obra'));
    expect(arbDe('en')['cropMarginLine'].toLowerCase(), contains('labor'));
  });
}
