import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import '../models/crop.dart';
import '../models/categories.dart';

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
        kExpenseCategorySowing => catSiembra,
        'semillas_insumos' => catSemillasInsumos,
        'fertilizante' => catFertilizante,
        'mano_obra' => catManoObra,
        kExpenseCategoryHarvest => catCosecha,
        'plagas' => catPlagas,
        'riego' => catRiego,
        'energia' => catEnergia,
        'agua' => catAgua,
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
        kIncomeCategorySale => catVenta,
        'venta_cafe' => catVentaCafe,
        'venta_platano' => catVentaPlatano,
        'subvenciones' => catSubvenciones,
        'venta_otro' => catVentaOtro,
        _ => key,
      };

  /// Etiqueta de la categoría "Venta": "Venta {cultivo}" si hay cultivo,
  /// o "Venta" a secas si no. Solo para la clave nueva [kIncomeCategorySale];
  /// las claves legadas (venta_cafe…) usan [incomeCategory] tal cual.
  String incomeSaleLabel(String? cropName) =>
      (cropName == null || cropName.isEmpty)
          ? catVenta
          : catVentaCrop(cropName);

  /// Etiqueta de un grupo de ingresos formado por [incomeGroupKey] para los
  /// desgloses (Resumen, PDF, Excel): "Venta plátano", "Venta café",
  /// "Subvenciones y apoyos"… Si el cultivo del grupo ya no existe, "Venta".
  String incomeGroupLabel(String key, List<Crop> crops) {
    final sep = key.indexOf('|');
    if (sep == -1) return incomeCategory(key);
    return incomeSaleLabel(cropNameOf(crops, key.substring(sep + 1)));
  }
}

/// Clave de agrupación de un movimiento en los desgloses de ingresos.
/// La venta ligada a un cultivo se agrupa aparte por cultivo
/// (`venta|<cropId>`) para que el Resumen muestre filas distintas como
/// "Venta plátano" y "Venta café" — el mismo criterio que ya tenían las
/// claves legadas venta_cafe / venta_platano. Para gastos (o ventas sin
/// cultivo) devuelve la clave tal cual.
String incomeGroupKey(String category, String? cropId) =>
    (category == kIncomeCategorySale && cropId != null && cropId.isNotEmpty)
        ? '$kIncomeCategorySale|$cropId'
        : category;

/// Cultivo con ese id, o null si no existe.
Crop? cropOf(List<Crop> crops, String? cropId) {
  if (cropId == null || cropId.isEmpty) return null;
  for (final c in crops) {
    if (c.id == cropId) return c;
  }
  return null;
}

/// Nombre del cultivo con ese id, o null si no existe.
String? cropNameOf(List<Crop> crops, String? cropId) =>
    cropOf(crops, cropId)?.name;