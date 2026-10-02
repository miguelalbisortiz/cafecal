import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/widgets/terminology_guide.dart';

void main() {
  test('el glosario cubre toda la jerga del hallazgo H5 (ES)', () {
    final entries = buildGlossary(stringsFor('es'));

    expect(entries, hasLength(16), reason: '5 originales + 11 nuevas');
    expect(
      entries.every((e) => e.term.isNotEmpty && e.definition.isNotEmpty),
      isTrue,
      reason: 'ninguna entrada puede quedar vacía',
    );

    final terms = entries.map((e) => e.term.toLowerCase()).toList();
    const needles = [
      'kg/ha',
      'kg/planta',
      'costo total por kg',
      'recogida',
      'establecimiento',
      'payback',
      'subtotal',
      'a la fecha',
      'nómina',
      'caja menor',
      'vendido vs cosechado',
    ];
    for (final needle in needles) {
      expect(
        terms.any((t) => t.contains(needle)),
        isTrue,
        reason: 'falta en el glosario: "$needle"',
      );
    }
  });

  test('el glosario en inglés tiene la misma cobertura que el español', () {
    final es = buildGlossary(stringsFor('es'));
    final en = buildGlossary(stringsFor('en'));

    expect(en.length, es.length);
    expect(en.every((e) => e.term.isNotEmpty && e.definition.isNotEmpty), isTrue);
  });

  test('los términos son únicos (no duplicados)', () {
    final terms = buildGlossary(stringsFor('es'))
        .map((e) => e.term.toLowerCase())
        .toList();
    expect(terms.toSet().length, terms.length,
        reason: 'no debe haber términos repetidos');
  });
}
