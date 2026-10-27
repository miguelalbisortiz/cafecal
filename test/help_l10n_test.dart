import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';

/// La Ayuda tiene que servir en **cualquier región del mundo**: sin símbolo de
/// moneda, sin código de moneda, sin país y sin cultivo obligatorio. Los
/// ejemplos usan números redondos y «tu moneda».
///
/// También vigila que el texto esté en los dos idiomas: una clave que solo
/// existe en español deja media app muda.
void main() {
  Map<String, dynamic> arb(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  const rutas = ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb'];

  /// Prefijos del copy de la Ayuda nueva. Las claves de ayuda en línea de los
  /// formularios (`helpArea`, `helpPlants`…) no entran: no son esta pantalla.
  const prefijos = [
    'helpStart',
    'helpCase',
    'helpSelling',
    'helpStarting',
    'helpRenew',
    'helpWorkers',
    'helpRoutine',
    'helpDict',
    'helpTrouble',
    'helpExampleNote',
  ];

  List<String> clavesDeLaAyuda(Map<String, dynamic> datos) => datos.keys
      .where((clave) =>
          !clave.startsWith('@') &&
          prefijos.any((prefijo) => clave.startsWith(prefijo)))
      .toList()
    ..sort();

  test('la Ayuda nueva está completa en español y en inglés', () {
    final es = arb(rutas[0]);
    final en = arb(rutas[1]);
    final claves = clavesDeLaAyuda(es);

    expect(claves.length, greaterThan(80),
        reason: 'el barrido tiene que estar viendo la Ayuda entera: si ve '
            'pocas claves, los ARB cambiaron de sitio');

    for (final clave in claves) {
      expect(en[clave], isA<String>(), reason: 'falta «$clave» en inglés');
    }
    for (final clave in ['helpTabStart', 'helpTabRoutine', 'helpTabUnderstand']) {
      expect(es[clave], isA<String>(), reason: 'falta «$clave» en español');
      expect(en[clave], isA<String>(), reason: 'falta «$clave» en inglés');
    }
  });

  test('ningún texto de la Ayuda ata la app a una moneda', () {
    const codigos = ['COP', 'USD', 'EUR', 'MXN', 'CLP', 'ARS', 'PEN', 'GTQ'];
    for (final ruta in rutas) {
      final datos = arb(ruta);
      for (final clave in clavesDeLaAyuda(datos)) {
        final texto = datos[clave] as String;
        expect(texto, isNot(contains(r'$')),
            reason: '$ruta · $clave: la Ayuda no cita montos con el símbolo');
        for (final codigo in codigos) {
          expect(RegExp('\\b$codigo\\b').hasMatch(texto), isFalse,
              reason: '$ruta · $clave: la Ayuda no nombra el código $codigo');
        }
      }
    }
  });

  test('ningún texto de la Ayuda ata la app a un país ni a un cultivo', () {
    const paises = [
      'Colombia',
      'México',
      'Argentina',
      'Chile',
      'Perú',
      'Ecuador',
      'Cenicafé',
      'Brasil',
    ];
    for (final ruta in rutas) {
      final datos = arb(ruta);
      for (final clave in clavesDeLaAyuda(datos)) {
        final texto = (datos[clave] as String).toLowerCase();
        for (final pais in paises) {
          expect(texto, isNot(contains(pais.toLowerCase())),
              reason: '$ruta · $clave: nombra «$pais», y la Ayuda es global');
        }
      }
    }
  });

  test('los ejemplos hablan de «tu moneda»', () {
    final es = stringsFor('es');
    final en = stringsFor('en');
    expect(es.helpStartNote.toLowerCase(), contains('tu moneda'));
    expect(es.helpExampleNote.toLowerCase(), contains('tu moneda'));
    expect(en.helpStartNote.toLowerCase(), contains('your currency'));
    expect(en.helpExampleNote.toLowerCase(), contains('your currency'));
  });

  test('la Ayuda no manda a «Cosechas»: ese menú está oculto', () {
    for (final ruta in rutas) {
      final datos = arb(ruta);
      for (final clave in clavesDeLaAyuda(datos)) {
        final texto = datos[clave] as String;
        expect(texto.contains('Cosechas ›'), isFalse,
            reason: '$ruta · $clave: «Cosechas» no está en el menú');
        expect(texto.contains('Harvests ›'), isFalse,
            reason: '$ruta · $clave: «Harvests» no está en el menú');
      }
    }
  });
}
