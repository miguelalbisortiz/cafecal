import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// Devuelve las traducciones para un código de idioma ('es' o 'en').
/// Se usa fuera del árbol de widgets (providers, servicios, tests).
AppLocalizations stringsFor(String language) =>
    lookupAppLocalizations(Locale(language));

extension L10nMonths on AppLocalizations {
  List<String> get monthFull => [
        monthJan,
        monthFeb,
        monthMar,
        monthApr,
        monthMay,
        monthJun,
        monthJul,
        monthAug,
        monthSep,
        monthOct,
        monthNov,
        monthDec,
      ];

  List<String> get monthShort =>
      monthFull.map((m) => m.length <= 3 ? m : m.substring(0, 3)).toList();

  /// Une nombres de mes con comas y una conjunción: "junio, mayo y abril".
  String listMonthsWithAnd(List<String> names) {
    if (names.length == 1) return names.first;
    return '${names.take(names.length - 1).join(', ')} $conjAnd ${names.last}';
  }
}

extension L10nCategories on AppLocalizations {
  String expenseCategory(String key) => switch (key) {
        'siembra' => catSiembra,
        'semillas_insumos' => catSemillasInsumos,
        'fertilizante' => catFertilizante,
        'mano_obra' => catManoObra,
        'cosecha' => catCosecha,
        'plagas' => catPlagas,
        'riego' => catRiego,
        'empaque' => catEmpaque,
        'transporte' => catTransporte,
        'equipo' => catEquipo,
        'mantenimiento' => catMantenimiento,
        'arriendo' => catArriendo,
        'impuestos' => catImpuestos,
        'otro' => catOtro,
        _ => key,
      };

  String incomeCategory(String key) => switch (key) {
        'venta_cafe' => catVentaCafe,
        'venta_platano' => catVentaPlatano,
        'subvenciones' => catSubvenciones,
        'venta_otro' => catVentaOtro,
        _ => key,
      };
}