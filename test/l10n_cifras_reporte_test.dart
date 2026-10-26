import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';

/// Copy del PRD «cifras del reporte»: las claves nuevas existen en los dos
/// idiomas y la Ayuda del gasto por hectárea ya nombra el lote.
void main() {
  test('la nota del lote sin repartir existe en ES y EN, sin «cohorte»', () {
    final es = stringsFor('es').perHaLotNotSplit;
    final en = stringsFor('en').perHaLotNotSplit;

    expect(es, contains('lote'));
    expect(en.toLowerCase(), contains('lot'));
    expect(es.toLowerCase(), isNot(contains('cohorte')));
    expect(en.toLowerCase(), isNot(contains('cohort')));
  });

  test('un lote cerrado se lee solo con su fecha en los dos idiomas', () {
    expect(stringsFor('es').sowingCohortDateOnly('12/03/2020'), '12/03/2020');
    expect(stringsFor('en').sowingCohortDateOnly('3/12/2020'), '3/12/2020');
  });

  test('la Ayuda del gasto por ha explica el reparto del lote', () {
    expect(stringsFor('es').helpPerHaCost.toLowerCase(), contains('lote'));
    expect(stringsFor('en').helpPerHaCost.toLowerCase(), contains('lot'));
  });
}
