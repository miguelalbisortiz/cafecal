import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T13 · guarda de copy: lo que se agregó en la tanda 4 tiene que estar en los
/// dos idiomas. Un texto que solo existe en español deja media app muda.
void main() {
  test('las copy de la tanda 4 están en los dos ARB', () {
    final es = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
        as Map<String, dynamic>;
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;

    const claves = [
      // T4 · peso de la cosecha y de la venta.
      'harvestEquivalentKgLabel',
      'harvestEquivalentKgHint',
      'harvestEquivalentKgRequired',
      'harvestEquivalentKgInvalid',
      'reportPendingWeightTitle',
      'reportPendingWeightHint',
      'reportPendingWeightHarvests',
      'reportPendingWeightSales',
      // T10 · áreas del terreno.
      'terrenoAreaAssigned',
      'terrenoAreaOver',
      'terrenoAreaWithoutArea',
      'cropAreaShareHelp',
      // T11 · nota de kg/planta.
      'perHaPerPlantNote',
      // T12 · aviso de resiembra.
      'sowingMissingLossesTitle',
      'sowingMissingLossesBody',
      'sowingMissingLossesEnter',
      'sowingMissingLossesSave',
      // T13 · planilla y renovación.
      'reportPayrollBudgetNote',
      'helpCaseCTitle',
      'helpCaseC1',
      'helpCaseC2',
      'helpCaseC3',
      'helpCaseCEnd',
      // T15 · reparto de un gasto entre cultivos.
      'expenseSplitTitle',
      'expenseSplitBody',
      'expenseSplitHint',
      'expenseSplitUseAreas',
      'expenseSplitSum',
      'expenseSplitMustSum',
      'expenseSplitZero',
      'expenseSplitFew',
      'expenseSplitNoAreas',
      'expenseSplitChosen',
      'expenseSplitChange',
      'expenseSplitClear',
      'expenseSplitNeedAmount',
      'expenseSplitPercent',
    ];

    for (final clave in claves) {
      expect(es[clave], isA<String>(), reason: 'falta «$clave» en español');
      expect(en[clave], isA<String>(), reason: 'falta «$clave» en inglés');
    }
  });
}
