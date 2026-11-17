import 'package:flutter/material.dart' show DateTimeRange;

import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import 'derived_harvests.dart';
import 'report_harvest_metrics.dart';

/// Aporte de un producto (cultivo): ingresos menos gastos directos.
///
/// Es **caja**, no costo de producción: aquí un gasto de lote no se reparte
/// —se informa aparte en [ProductContributionReport.lotExpensesByMonth]—
/// porque repartirlo exige un criterio que puede no existir (hectáreas,
/// jornales) y esta vista no inventa proporciones.
///
/// Igual que el resto de la app, **nunca se suman monedas distintas**: cada
/// mapa es `mes → moneda → monto`.
class ProductContributionRow {
  final String cropId;
  final String name;

  /// Ingresos por mes y moneda (`1..12` → código → monto).
  final Map<int, Map<String, double>> incomesByMonth;

  /// Gastos directos por mes y moneda.
  final Map<int, Map<String, double>> expensesByMonth;

  const ProductContributionRow({
    required this.cropId,
    required this.name,
    required this.incomesByMonth,
    required this.expensesByMonth,
  });

  /// Ingresos del período por moneda.
  Map<String, double> get incomeTotal => _sumMonths(incomesByMonth);

  /// Gastos directos del período por moneda.
  Map<String, double> get expenseTotal => _sumMonths(expensesByMonth);

  /// Aporte (ingresos − gastos directos) del período por moneda.
  Map<String, double> get netTotal => _net(incomeTotal, expenseTotal);

  /// Aporte de un mes, por moneda. Vacío si ese mes no tuvo movimiento.
  Map<String, double> netOf(int month) => _net(
      incomesByMonth[month] ?? const {}, expensesByMonth[month] ?? const {});

  /// true si hay algo que mostrar (positivo o negativo).
  bool get hasData => incomeTotal.isNotEmpty || expenseTotal.isNotEmpty;

  /// Meses con algún movimiento de este producto, en orden.
  List<int> get monthsWithData => <int>{
        ...incomesByMonth.keys,
        ...expensesByMonth.keys,
      }.toList()
        ..sort();
}

/// Cobertura de la inversión del café por parte de los otros productos.
///
/// La inversión es **acumulada**: gastos de siembra/establecimiento del café
/// (categoría `siembra` o `sowingId`, el mismo criterio de
/// `splitInvestmentAndOperation`) hasta el cierre del período. El aporte de
/// los otros productos también es acumulado hasta esa fecha: ingresos menos
/// gastos directos de todos los cultivos que no son café.
class CoffeeCoverage {
  final String coffeeName;

  /// Moneda única de la comparación.
  final String currency;

  /// Inversión acumulada del café en [currency].
  final double investment;

  /// Aporte acumulado de los otros productos en [currency]. Puede ser negativo.
  final double contributed;

  const CoffeeCoverage({
    required this.coffeeName,
    required this.currency,
    required this.investment,
    required this.contributed,
  });

  /// Porcentaje de la inversión cubierto, redondeado (puede ser negativo).
  int get percent =>
      investment > 0 ? (contributed / investment * 100).round() : 0;

  bool get isCovered => contributed >= investment;
}

/// El aporte por producto de un período, con lo que no se puede atribuir y la
/// cobertura del café.
class ProductContributionReport {
  /// Productos con algún movimiento, ordenados por aporte absoluto.
  final List<ProductContributionRow> rows;

  /// Gastos de lote (con terreno y sin cultivo) por mes y moneda.
  ///
  /// La vista **no** los reparte: se muestran como línea aparte para que el
  /// total siga cuadrando sin inventar proporciones.
  final Map<int, Map<String, double>> lotExpensesByMonth;

  /// Gastos sin cultivo ni lote («Costos comunes»).
  ///
  /// Solo gastos: antes esta línea también sumaba los ingresos sin
  /// cultivo, así que una subvención de la finca aparecía rotulada
  /// como gasto.
  final Map<int, Map<String, double>> commonExpensesByMonth;

  /// Ingresos sin cultivo ni lote. Van en su propia línea por la
  /// misma razón.
  final Map<int, Map<String, double>> commonIncomesByMonth;

  /// `null` cuando no se puede calcular sin mentir.
  final CoffeeCoverage? coverage;

  const ProductContributionReport({
    required this.rows,
    required this.lotExpensesByMonth,
    required this.commonExpensesByMonth,
    required this.commonIncomesByMonth,
    required this.coverage,
  });

  bool get hasData => rows.any((r) => r.hasData);

  /// Meses con algún movimiento, de enero a diciembre.
  List<int> get monthsWithData => <int>{
        ...rows.expand((r) => r.monthsWithData),
        ...lotExpensesByMonth.keys,
        ...commonExpensesByMonth.keys,
        ...commonIncomesByMonth.keys,
      }.toList()
        ..sort();

  Map<String, double> get lotExpenseTotal => _sumMonths(lotExpensesByMonth);

  Map<String, double> get commonExpenseTotal =>
      _sumMonths(commonExpensesByMonth);

  Map<String, double> get commonIncomeTotal =>
      _sumMonths(commonIncomesByMonth);
}

/// Construye el aporte por producto de [period] con **solo** lo que hay:
///
/// 1. Movimiento con cultivo → ingreso o gasto directo de ese producto.
///    Si el cultivo ya no existe, se conserva como fila con su id: la app no
///    borra la plata, pero tampoco le inventa un nombre.
/// 2. Gasto con lote y sin cultivo → [ProductContributionReport.lotExpensesByMonth],
///    sin repartir.
/// 3. Sin cultivo ni lote → «comunes», informados aparte y separados
///    por tipo: una línea de gastos y otra de ingresos, nunca sumados.
/// 4. Borrados y fechas fuera del período, fuera.
///
/// [coverageThrough] corta solo la cobertura (por ejemplo, «hoy» cuando el
/// período es el año en curso): así no se cuentan movimientos con fecha
/// futura. Nunca pasa del fin de [period].
///
/// [harvests] alimenta la cobertura: es lo que decide si unas cercas son
/// inversión (antes de la primera cosecha) u operación (después).
///
/// Función pura: misma entrada, misma salida.
ProductContributionReport buildProductContribution({
  required Iterable<Transaction> transactions,
  required List<Crop> crops,
  required DateTimeRange period,
  DateTime? coverageThrough,
  List<Harvest> harvests = const [],
}) {
  final filas = <String, _Acumulador>{};
  final lot = <int, Map<String, double>>{};
  final commonExpenses = <int, Map<String, double>>{};
  final commonIncomes = <int, Map<String, double>>{};

  for (final t in transactions) {
    if (t.deleted ||
        t.date.isBefore(period.start) ||
        t.date.isAfter(period.end)) {
      continue;
    }
    final month = t.date.month;
    final cropId = t.cropId;

    if (cropId != null) {
      final acumulador =
          filas.putIfAbsent(cropId, () => _Acumulador(cropId: cropId));
      final target =
          t.type.isExpense ? acumulador.expenses : acumulador.incomes;
      _add(target, month, t.currency, t.amount);
      continue;
    }

    // Sin cultivo: el gasto de lote va aparte y el resto se separa por
    // tipo.
    final target = t.type.isExpense
        ? (t.terrenoId != null ? lot : commonExpenses)
        : commonIncomes;
    _add(target, month, t.currency, t.amount);
  }

  final rows = <ProductContributionRow>[];
  for (final c in crops) {
    final a = filas.remove(c.id);
    if (a != null) rows.add(a.toRow(c.name));
  }
  // Ids que no resuelven: se conservan con su id, sin inventar un nombre.
  for (final a in filas.values) {
    rows.add(a.toRow(a.cropId));
  }
  rows.sort((a, b) {
    final porPeso = _peso(b).compareTo(_peso(a));
    if (porPeso != 0) return porPeso;
    final porNombre = a.name.compareTo(b.name);
    return porNombre != 0 ? porNombre : a.cropId.compareTo(b.cropId);
  });

  return ProductContributionReport(
    rows: rows,
    lotExpensesByMonth: lot,
    commonExpensesByMonth: commonExpenses,
    commonIncomesByMonth: commonIncomes,
    // La cobertura se corta al cierre del período: mirar enero no puede
    // incluir aportes de diciembre. La inversión sigue siendo acumulada.
    coverage: coffeeCoverage(
      transactions: transactions,
      crops: crops,
      until: _finDeCobertura(period.end, coverageThrough),
      harvests: harvests,
    ),
  );
}

/// Cobertura de la inversión acumulada del café por los otros productos.
///
/// Devuelve `null` —nunca un 0% inventado— cuando no hay ningún cultivo de
/// café, cuando el café no tiene inversión de siembra registrada o cuando las
/// dos mitades no comparten una única moneda.
///
/// Los movimientos sin cultivo no entran: no son aporte de ningún producto.
CoffeeCoverage? coffeeCoverage({
  required Iterable<Transaction> transactions,
  required List<Crop> crops,
  DateTime? until,
  /// Cosechas guardadas a mano. Los kilos medidos en un jornal de «Cosechar»
  /// se deducen acá dentro con [deriveHarvests]: es la misma lista que cuenta
  /// Reportes, y la primera cosecha es el corte de C9. Si el llamador ya
  /// entrega la lista derivada no cambia nada — derivar sobre lo derivado
  /// devuelve lo mismo, porque una cosecha derivada ya cuenta como manual.
  List<Harvest> harvests = const [],
}) {
  final allTx = transactions.toList();
  // La misma lista que publica `TransactionProvider.harvests`: manual +
  // deducidas. El llamador puede pasar las guardadas o las completas.
  final allHarvests =
      effectiveHarvests(transactions: allTx, manualHarvests: harvests);
  final coffeeIds = coffeeCropIds(crops);
  if (coffeeIds.isEmpty) return null;
  final coffeeName = crops
      .where((c) => coffeeIds.contains(c.id))
      .map((c) => c.name)
      .toList()
    ..sort();

  final investment = <String, double>{};
  final contributed = <String, double>{};
  // La primera cosecha de cada cultivo es el corte de C9: cercas antes de esa
  // fecha son establecimiento; después, mantenimiento.
  final firstHarvest = <String, DateTime?>{
    for (final c in crops) c.id: firstHarvestDateOf(allHarvests, c.id),
  };

  for (final t in allTx) {
    if (t.deleted || (until != null && t.date.isAfter(until))) continue;
    final cropId = t.cropId;
    if (cropId == null) continue;

    if (coffeeIds.contains(cropId)) {
      final isInvestment =
          isEstablishmentExpense(t, firstHarvestDate: firstHarvest[cropId]);
      if (t.type.isExpense && isInvestment) {
        investment[t.currency] = (investment[t.currency] ?? 0) + t.amount;
      }
      continue;
    }

    contributed[t.currency] = (contributed[t.currency] ?? 0) +
        (t.type.isExpense ? -t.amount : t.amount);
  }

  final currencies = <String>{...investment.keys, ...contributed.keys};
  if (currencies.length != 1) return null;

  final currency = currencies.single;
  final invested = investment[currency] ?? 0;
  if (invested <= 0) return null;

  return CoffeeCoverage(
    coffeeName: coffeeName.join(' + '),
    currency: currency,
    investment: invested,
    contributed: contributed[currency] ?? 0,
  );
}

/// Ids de los cultivos de café, por nombre normalizado.
///
/// No hay una tabla de especies a propósito (el mismo criterio de E4/E5): se
/// reconoce lo que el productor llamó café. «Café lote 1» cuenta igual que
/// «Café», y los dos suman su inversión.
Set<String> coffeeCropIds(List<Crop> crops) => {
      for (final c in crops)
        if (c.id == 'cafe' || _normalizar(c.name).contains('caf')) c.id,
    };

DateTime _finDeCobertura(DateTime periodEnd, DateTime? coverageThrough) =>
    coverageThrough != null && coverageThrough.isBefore(periodEnd)
        ? coverageThrough
        : periodEnd;

class _Acumulador {
  final String cropId;
  final Map<int, Map<String, double>> incomes = {};
  final Map<int, Map<String, double>> expenses = {};

  _Acumulador({required this.cropId});

  ProductContributionRow toRow(String name) => ProductContributionRow(
        cropId: cropId,
        name: name,
        incomesByMonth: incomes,
        expensesByMonth: expenses,
      );
}

void _add(
  Map<int, Map<String, double>> target,
  int month,
  String currency,
  double amount,
) {
  final byCurrency = target.putIfAbsent(month, () => <String, double>{});
  byCurrency[currency] = (byCurrency[currency] ?? 0) + amount;
}

Map<String, double> _sumMonths(Map<int, Map<String, double>> byMonth) {
  final out = <String, double>{};
  for (final m in byMonth.values) {
    for (final e in m.entries) {
      out[e.key] = (out[e.key] ?? 0) + e.value;
    }
  }
  return out;
}

Map<String, double> _net(
  Map<String, double> incomes,
  Map<String, double> expenses,
) {
  final out = <String, double>{...incomes};
  for (final e in expenses.entries) {
    out[e.key] = (out[e.key] ?? 0) - e.value;
  }
  return out;
}

/// Peso de una fila **solo para ordenar**. Con moneda mixta no es una cifra
/// que se pueda pintar: se usa el valor absoluto del neto.
double _peso(ProductContributionRow row) =>
    row.netTotal.values.fold(0.0, (sum, v) => sum + v.abs());

String _normalizar(String value) {
  const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final index = conAcento.indexOf(String.fromCharCode(rune));
    buffer.write(index >= 0 ? sinAcento[index] : String.fromCharCode(rune));
  }
  return buffer.toString();
}
