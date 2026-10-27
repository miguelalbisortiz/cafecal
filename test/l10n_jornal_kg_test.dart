import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tanda 2 · el campo de «kilos recolectados» del jornal.
///
/// Las cuatro frases viven en los dos idiomas. Si una falta, la app cae al
/// español sin avisar; si el texto cambia sin querer, el usuario lee otra cosa.
/// Este test es la puerta de la copy aprobada (Q4).
void main() {
  Map<String, dynamic> arb(String ruta) =>
      jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

  const es = {
    'jornalHarvestedKgLabel': 'Kilos recolectados (opcional)',
    'jornalHarvestedKgHelp': 'Para comparar lo cosechado con lo vendido.',
    'jornalHarvestedKgNoCrop': 'Elige el cultivo para anotar los kilos.',
    'jornalHarvestedKgInvalid': 'Ingresa los kilos recolectados (mayor que 0).',
  };

  const en = {
    'jornalHarvestedKgLabel': 'Harvested kilos (optional)',
    'jornalHarvestedKgHelp':
        'To compare what you harvested with what you sold.',
    'jornalHarvestedKgNoCrop': 'Select the crop to record the kilos.',
    'jornalHarvestedKgInvalid': 'Enter the harvested kilos (greater than 0).',
  };

  test('las cuatro frases están en ES con el texto aprobado', () {
    final a = arb('lib/l10n/app_es.arb');
    es.forEach((k, v) => expect(a[k], v, reason: k));
  });

  test('las cuatro frases están en EN con el texto aprobado', () {
    final a = arb('lib/l10n/app_en.arb');
    en.forEach((k, v) => expect(a[k], v, reason: k));
  });

  test('la copy no menciona bodega ni usa el signo de peso', () {
    final a = arb('lib/l10n/app_es.arb');
    for (final k in es.keys) {
      final v = a[k].toString().toLowerCase();
      expect(v, isNot(contains('bodega')), reason: k);
      expect(a[k].toString(), isNot(contains(r'$')), reason: k);
    }
  });
}
