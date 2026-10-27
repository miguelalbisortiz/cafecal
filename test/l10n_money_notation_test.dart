import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';

/// Regla de la casa: un monto se lee con su **código** de moneda (`COP 1.500`),
/// nunca con el símbolo `$` — que lo comparten COP, USD y CLP, así que no dice
/// de qué moneda se habla.
///
/// La única excepción son las **razones** en prosa («por cada `$100` vendidos»):
/// ahí el símbolo no cita un monto, cita una proporción, y no se refiere a
/// ninguna moneda concreta.
///
/// Los ejemplos de la Ayuda citaban sus cifras con el símbolo y el separador de
/// otro idioma («$500,000»), que la app nunca pinta: en pantalla eso se lee
/// «COP 500.000». Este test los fija y vigila que el símbolo no vuelva a ningún
/// texto que cite un monto.
void main() {
  // Razones, no montos: el símbolo aquí es una unidad de proporción.
  const razones = <String>{
    'metricMarginGood',
    'metricMarginFair',
    'metricMarginLow',
    'metricRatioHealthy',
    'metricRatioHigh',
    'metricRatioCritical',
  };

  test('ningún texto cita un monto con el símbolo', () {
    final conSimbolo = <String>{};
    var revisadas = 0;
    for (final ruta in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final arb =
          jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;
      arb.forEach((clave, valor) {
        if (clave.startsWith('@') || valor is! String) return;
        revisadas++;
        if (valor.contains(r'$')) conSimbolo.add(clave);
      });
    }
    final intrusas = conSimbolo.difference(razones);
    expect(revisadas, greaterThan(200),
        reason: 'el barrido tiene que estar viendo textos de verdad: si revisa '
            'pocos, los ARB cambiaron de sitio');
    expect(intrusas, isEmpty,
        reason: 'estos textos citan un monto con el símbolo, que no dice de qué '
            'moneda se habla; el monto se lee con su código (COP 1.500):\n'
            '${intrusas.join('\n')}');
  });

  test('los ejemplos de la Ayuda citan sus cifras sin moneda ni país', () {
    // Se leen del material generado —lo que de verdad pinta la pantalla—, no
    // del ARB: así el test también exige que se haya corrido gen-l10n.
    for (final idioma in ['es', 'en']) {
      final l10n = stringsFor(idioma);
      final ejemplos = <String, String>{
        'helpSellingExample1': l10n.helpSellingExample1,
        'helpSellingExample2': l10n.helpSellingExample2,
        'helpSellingExample3': l10n.helpSellingExample3,
        'helpStartingExample2': l10n.helpStartingExample2,
        'helpWorkersExample3': l10n.helpWorkersExample3,
      };
      ejemplos.forEach((clave, texto) {
        expect(texto, isNot(contains(r'$')),
            reason: '$idioma · $clave: el ejemplo no cita el símbolo');
        for (final codigo in ['COP', 'USD', 'EUR']) {
          expect(texto.contains(codigo), isFalse,
              reason: '$idioma · $clave: el ejemplo no nombra una moneda');
        }
      });
      expect(l10n.helpExampleNote.toLowerCase(),
          contains(idioma == 'es' ? 'moneda' : 'currency'),
          reason: '$idioma · helpExampleNote: el ejemplo dice en qué moneda va');
    }
  });
}
