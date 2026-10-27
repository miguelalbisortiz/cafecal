import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/widgets/terminology_guide.dart';

/// Dos reglas de la casa, aplicadas a la Ayuda:
///
/// 1. **Nada de copy huérfano.** Si una clave `help*` está escrita en el ARB y
///    nadie la pinta, es una pieza a medio hacer: o se pinta, o se borra. El
///    barrido mira `lib/` en producción —nunca el generado ni los tests—,
///    porque una clave usada solo en un test tampoco llega a la pantalla.
/// 2. **Nada de puertas que no existen.** El glosario no puede ofrecer una
///    elección que el agricultor no tiene: «Destino» (vendido o pérdida) salió
///    del menú y la cosecha se deriva de la venta, así que el término que se lee
///    en Reporte es «Vendido vs cosechado».
void main() {
  test('ninguna clave help* declarada queda sin pintar', () {
    final arb = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
        as Map<String, dynamic>;
    final declaradas = arb.keys
        .where((clave) => clave.startsWith('help') && !clave.startsWith('@'))
        .toList()
      ..sort();

    // El barrido tiene que estar viendo la Ayuda de verdad: si ve pocas claves,
    // el ARB cambió de sitio y esta guarda dejaría de vigilar sin avisar.
    expect(declaradas.length, greaterThan(80),
        reason: 'el barrido tiene que estar viendo la Ayuda entera');

    final produccion = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((archivo) => archivo.path.endsWith('.dart'))
        .where((archivo) =>
            !archivo.path.replaceAll(r'\', '/').contains('lib/l10n/'))
        .map((archivo) => archivo.readAsStringSync())
        .join('\n');

    final huerfanas =
        declaradas.where((clave) => !produccion.contains('l10n.$clave'));

    expect(huerfanas, isEmpty,
        reason: 'estas claves están escritas y nadie las pinta: se pintan o se '
            'borran, no se dejan a medias:\n${huerfanas.join('\n')}');
  });

  test('el glosario no promete un destino que no se puede registrar', () {
    const terminoPorIdioma = {
      'es': 'Vendido vs cosechado',
      'en': 'Sold vs harvested',
    };

    terminoPorIdioma.forEach((idioma, termino) {
      final glosario = buildGlossary(stringsFor(idioma));
      final terminos = glosario.map((e) => e.term).toList();

      expect(terminos, contains(termino),
          reason: '$idioma: el término que sí se ve en Reporte tiene que estar '
              'en el glosario');
      expect(terminos, isNot(contains('Destino')),
          reason: '$idioma: el agricultor no elige un destino; la cosecha se '
              'deriva de la venta');
      final texto = glosario.map((e) => e.definition).join(' ').toLowerCase();
      expect(texto, isNot(contains('vendido o pérdida')),
          reason: '$idioma: el glosario no puede ofrecer un destino inventado');
      expect(texto, isNot(contains('sold or loss')),
          reason: '$idioma: el mismo error en inglés');
    });
  });
}
