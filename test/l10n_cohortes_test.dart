import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Etapa A · guarda de copy de las cohortes.
///
/// Todo lo que se ve de la etapa A tiene que existir en los dos idiomas, con los
/// mismos argumentos, sin la palabra «cohorte» (se dice «lote») y sin prometer
/// nada que el diseño no haga (kilos por lote).
void main() {
  final es = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
      as Map<String, dynamic>;
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;

  const claves = [
    // T14 · el formulario de siembra.
    'sowingWhatHappensOldPlants',
    'sowingExpandOption',
    'sowingRenewOption',
    'sowingRenewHint',
    'sowingReplaceCohortLabel',
    'sowingReplacePlantsLabel',
    'sowingReplacePlantsRequired',
    'sowingReplacePlantsPrefill',
    'sowingReplaceNoArea',
    'sowingReplaceAll',
    'sowingReplaceTooMany',
    'sowingReplaceAreaLabel',
    // T15 · la resiembra y el lote.
    'sowingCohortLabel',
    'sowingCohortOption',
    'sowingCohortNoneTitle',
    'sowingCohortNoneBody',
    'sowingCohortNoneSaveAs',
    'sowingNoCohortTag',
    'sowingDeleteCohortBody',
    // T16 · la tarjeta del cultivo.
    'cohortsCount',
    'cohortOpen',
    'cohortRenewed',
    'cohortRenewedOn',
    'cohortsHistoryTitle',
    'cohortsAreaFallback',
    'cohortsAreaMismatch',
    'cohortsNoLivingPlants',
    // T17 · ayuda.
    'helpCohortsRenewTitle',
    'helpCohortsRenew',
    // T19 · reportes.
    'perHaAgesAverage',
  ];

  test('las claves de cohortes están en los dos ARB', () {
    for (final clave in claves) {
      expect(es[clave], isA<String>(), reason: 'falta «$clave» en español');
      expect(en[clave], isA<String>(), reason: 'falta «$clave» en inglés');
    }
  });

  test('los placeholders coinciden en nombre y cantidad entre ES y EN', () {
    for (final clave in claves) {
      final pes = (es['@$clave']?['placeholders'] as Map?)?.keys.toList() ?? [];
      final pen = (en['@$clave']?['placeholders'] as Map?)?.keys.toList() ?? [];
      expect(pes.toSet(), pen.toSet(),
          reason: '«$clave» no declara los mismos argumentos en los dos idiomas');
      expect(pes.length, pen.length, reason: '«$clave» cambia de argumentos');
    }
  });

  test('el copy visible no usa «cohorte» ni «cohort»', () {
    for (final clave in claves) {
      final texto = (es[clave] as String).toLowerCase();
      expect(texto.contains('cohorte'), isFalse,
          reason: '«$clave» usa «cohorte»; se dice «lote»');
      final ingles = (en[clave] as String).toLowerCase();
      expect(ingles.contains('cohort'), isFalse,
          reason: '«$clave» usa «cohort»; se dice «lot»');
    }
  });

  test('ninguna clave nueva promete kilos por lote', () {
    for (final clave in claves) {
      expect((es[clave] as String).toLowerCase().contains('kg'), isFalse,
          reason: '«$clave» promete kilos por lote y el diseño no los calcula');
      expect((en[clave] as String).toLowerCase().contains('kg'), isFalse,
          reason: '«$clave» promete kilos por lote y el diseño no los calcula');
    }
  });
}
