import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fase 2 · las claves nuevas de la navegación existen en los dos idiomas.
///
/// El renombre «Historial → Movimientos» y el hub Finca se ven en toda la app:
/// una clave que falte en un idioma no rompe el build, pero deja un hueco en
/// inglés (o en español). Esta guarda compara los dos ARB completos.
void main() {
  Map<String, dynamic> arbDe(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  const nuevas = [
    'tabMovements',
    'tabReports',
    'registerTitle',
    'menuFinca',
    'fincaHubTitle',
    'fincaHubSubtitle',
  ];

  final es = arbDe('lib/l10n/app_es.arb');
  final en = arbDe('lib/l10n/app_en.arb');

  Set<String> claves(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  test('ES y EN tienen exactamente las mismas claves', () {
    expect(claves(en).difference(claves(es)), isEmpty,
        reason: 'claves solo en inglés');
    expect(claves(es).difference(claves(en)), isEmpty,
        reason: 'claves solo en español');
  });

  test('las claves nuevas de la navegación están en ambos idiomas', () {
    for (final clave in nuevas) {
      for (final entrada in {'ES': es, 'EN': en}.entries) {
        final valor = entrada.value[clave];
        expect(valor, isA<String>(),
            reason: '${entrada.key} · $clave falta');
        expect((valor as String).trim(), isNotEmpty,
            reason: '${entrada.key} · $clave está vacía');
      }
    }
  });

  test('el renombre deja de usar «Historial» en los dos idiomas', () {
    expect(es.containsKey('tabHistory'), isFalse);
    expect(en.containsKey('tabHistory'), isFalse);
    expect(es['tabMovements'], 'Movimientos');
    expect(en['tabMovements'], 'Movements');
  });
}
