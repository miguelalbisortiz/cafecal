import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';

/// **Paridad del export (SC-5).** Congela el contenido del PDF y del Excel
/// **antes** de diferir las librerías: si al mover `pdf`/`excel` detrás de un
/// `deferred as` cambia una fila, un total o una página, esta guarda lo dice.
///
/// Nace verde y no tiene rojo: no arregla nada, fotografía lo que hoy sale.
/// Los cuatro números están escritos a mano (no se recalculan en el test) para
/// que el día que cambien haya que decidirlo a conciencia.
AppLocalizations get _es => stringsFor('es');

/// Fixture canónico: dos monedas, venta y gasto en cada una, mano de obra con
/// kilos medidos y un cultivo sin terreno. Nada de azar: mismas fechas, mismos
/// montos, mismo resultado en cada corrida.
Future<TransactionProvider> _fixture() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final p = TransactionProvider(LocalStore(prefs));
  final now = DateTime.now();

  final cafe = await p.addCrop('Café');
  final platano = await p.addCrop('Plátano');

  // Venta en pesos, con kilos.
  await p.addTransaction(
    type: TransactionType.income,
    category: kIncomeCategorySale,
    amount: 150000,
    cropId: cafe.id,
    quantity: 50,
    unit: 'kg',
    date: now,
  );

  // Venta en dólares, con kilos.
  await p.addTransaction(
    type: TransactionType.income,
    category: kIncomeCategorySale,
    amount: 30,
    currency: 'USD',
    cropId: platano.id,
    quantity: 10,
    unit: 'kg',
    date: now,
  );

  // Inversión en pesos.
  await p.addTransaction(
    type: TransactionType.expense,
    category: kExpenseCategorySowing,
    amount: 50000,
    cropId: cafe.id,
    date: now,
  );

  // Mano de obra con kilos medidos: la cosecha deja de derivarse de la venta.
  await p.addTransaction(
    type: TransactionType.expense,
    category: 'mano_obra',
    amount: 100000,
    cropId: cafe.id,
    quantity: 2,
    unit: 'día',
    pricePerUnit: 50000,
    provider: 'Juan',
    task: kTaskCosechar,
    harvestedKg: 60,
    date: now,
  );

  // Gasto en dólares.
  await p.addTransaction(
    type: TransactionType.expense,
    category: 'insumos',
    amount: 20,
    currency: 'USD',
    cropId: platano.id,
    date: now,
  );

  // Tanda 4 · peso variable: 12 racimos que pesaron 240 kg y una venta de 10
  // cajones que pesaron 200 kg. Antes el export contaba 12 y 10 kilos.
  final yuca = await p.addCrop('Yuca');
  await p.addHarvest(
    cropId: yuca.id,
    date: now,
    amount: 12,
    unit: 'racimo',
    equivalentKg: 240,
  );
  await p.addTransaction(
    type: TransactionType.income,
    category: kIncomeCategorySale,
    amount: 200000,
    cropId: yuca.id,
    quantity: 10,
    unit: 'cajon',
    equivalentKg: 200,
    date: now,
  );

  return p;
}

/// Filas del Excel que no son el encabezado.
int _movementRows(Sheet sheet) => sheet.rows.length - 1;

/// Texto de la celda de total de una sección de la hoja Resumen.
String _summaryTotal(Sheet sheet, String header) {
  for (final row in sheet.rows) {
    final first = row.isNotEmpty ? (row.first?.value?.toString() ?? '') : '';
    if (first == header) {
      return row.length > 2 ? (row[2]?.value?.toString() ?? '') : '';
    }
  }
  return '(sin fila: $header)';
}


/// Filas de reparto («· Inversión inicial», etc.) que van debajo de un cultivo
/// en la hoja «Por cultivo», con su monto ya parseado.
Map<String, double> _cropSplitRows(Sheet sheet, String crop) {
  final rows = sheet.rows;
  final start = rows.indexWhere(
      (r) => r.isNotEmpty && r.first?.value?.toString() == crop);
  final out = <String, double>{};
  if (start < 0) return out;
  for (var i = start + 1; i < rows.length; i++) {
    final label = rows[i].isNotEmpty
        ? (rows[i].first?.value?.toString() ?? '')
        : '';
    if (!label.contains('·')) break;
    final amount = double.tryParse(rows[i].length > 2
        ? (rows[i][2]?.value?.toString() ?? '')
        : '');
    out[label.replaceAll('·', '').trim()] = amount ?? -1;
  }
  return out;
}

/// Páginas del PDF por dos vías: los objetos `/Type /Page` (sin contar
/// `/Pages`) y el `/Count` del nodo raíz.
({int objects, int count}) _pdfPages(Uint8List bytes) {
  final text = String.fromCharCodes(bytes);
  final objects = RegExp(r'/Type\s*/Page(?![s])').allMatches(text).length;
  final countMatch = RegExp(r'/Count\s+(\d+)').firstMatch(text);
  return (objects: objects, count: int.tryParse(countMatch?.group(1) ?? '') ?? -1);
}

/// Kilos de un cultivo en la tabla «Total cosechado por cultivo» del Excel.
double? _harvestKgFor(Sheet sheet, String crop) {
  for (final row in sheet.rows) {
    if (row.isEmpty) continue;
    if (row.first?.value?.toString() != crop) continue;
    final kg = row.length > 2 ? row[2]?.value : null;
    final n = double.tryParse(kg?.toString() ?? '');
    if (n != null) return n;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el Excel y el PDF de un período mezclado no cambian de contenido',
      () async {
    final p = await _fixture();
    final now = DateTime.now();

    final excelBytes = Uint8List.fromList(ExcelExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
      harvests: p.harvests,
    ));
    final book = Excel.decodeBytes(excelBytes);
    final movimientos = book.tables[_es.excelSheetMovements]!;
    final resumen = book.tables[_es.excelSheetSummary]!;

    final pdfBytes = await PdfExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
      harvests: p.harvests,
    );
    final pages = _pdfPages(pdfBytes);

    // Los cuatro números, congelados a mano el 2026-10-20 (T2, build
    // `e9c2761`). Si cambian, es una decisión: no se actualizan a ciegas.
    // 2026-11-10 · páginas 2 → 3: decisión de sacar «Nómina y caja» a un
    // anexo con salto de página (nómina, caja, obra y planilla).
    // 2026-11-16 · páginas 3 → 4: la fila de costo por kilo por cultivo lleva
    // su nota de «solo operación» (C10), una línea más por cultivo.
    const filasEsperadas = 6;
    const ingresosEsperados = 'COP 350.000 · USD 30,00';
    const gastosEsperados = '(COP 150.000) · (USD 20,00)';
    const paginasEsperadas = 4;

    expect(_movementRows(movimientos), filasEsperadas,
        reason: 'la hoja de movimientos cambió de tamaño');
    expect(_summaryTotal(resumen, _es.pdfIncomesHeader), ingresosEsperados,
        reason: 'los ingresos por moneda cambiaron');
    expect(_summaryTotal(resumen, _es.pdfTotalExpensesHeader), gastosEsperados,
        reason: 'los gastos por moneda cambiaron');
    expect(pages.objects, paginasEsperadas,
        reason: 'el PDF cambió de páginas (objetos /Type /Page)');
    // Las dos vías tienen que decir lo mismo; si no, manda `/Count`.
    expect(pages.count, paginasEsperadas,
        reason: 'el PDF cambió de páginas (Count del nodo /Pages)');

    // Tanda 4 · los kilos de racimos y cajones salen del peso anotado, y el
    // export no puede quedarse atrás de la pantalla.
    const metrics = ReportHarvestMetrics();
    final yuca = p.crops.firstWhere((c) => c.name == 'Yuca');
    final yucaHarvests = p.harvests.where((h) => h.cropId == yuca.id).toList();
    final totalYuca = metrics.totalsByCrop(yucaHarvests, p.crops).single;
    expect(totalYuca.kg, 240, reason: '12 racimos pesaron 240 kg, no 12');

    final svh = metrics
        .soldVsHarvested(p.transactions, p.harvests, p.crops, now)
        .firstWhere((r) => r.cropId == yuca.id);
    expect(svh.soldKg, 200, reason: '10 cajones pesaron 200 kg, no 10');

    final ventaCajones = p.transactions.firstWhere(
        (t) => t.cropId == yuca.id && t.amount == 200000);
    expect(metrics.avgSalePricePerKg([ventaCajones]), 1000,
        reason: '200.000 / 200 kg');

    final cosechas = book.tables[_es.excelSheetHarvests]!;
    expect(_harvestKgFor(cosechas, 'Yuca'), 240,
        reason: 'la hoja de cosechas del Excel también usa el peso real');
  });

  test('aporte por producto: la sección y la cobertura salen en el Excel',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final now = DateTime.now();

    final cafe = await p.addCrop('Café');
    final platano = await p.addCrop('Plátano');
    // Inversión acumulada del café y aporte del otro producto: 40 %. Todas
    // las fechas caen en el período para que el test no dependa del mes.
    await p.addTransaction(
      type: TransactionType.expense,
      category: kExpenseCategorySowing,
      amount: 100000,
      cropId: cafe.id,
      date: now,
    );
    await p.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 40000,
      cropId: platano.id,
      date: now,
    );

    final book = Excel.decodeBytes(Uint8List.fromList(
      ExcelExportService().buildReport(
        settings: p.settings,
        transactions: p.transactions,
        crops: p.crops,
        year: now.year,
        month: now.month,
        period: ReportPeriod.month,
        periodName: 'Mes',
        l10n: _es,
      ),
    ));
    final cells = [
      for (final r in book.tables[_es.excelSheetSummary]!.rows)
        for (final c in r) c?.value?.toString() ?? '',
    ];

    expect(cells, contains(_es.contributionTitle));
    expect(cells, contains(_es.contributionCoverageTitle));
    expect(cells.any((t) => t.contains('cubren 40%')), isTrue,
        reason: 'la cobertura del café se escribe con la misma frase que '
            'en pantalla: 40.000 de 100.000 = 40 %');
    expect(cells, contains('Café'));
    expect(cells, contains(_es.contributionNet));

    // El PDF no puede quedarse atrás: se genera con la misma sección sin
    // romper el documento.
    final pdf = await PdfExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
    );
    expect(pdf.length, greaterThan(1000));
  });

  // C10 · el costo por kilo que sale en el Excel es de operación: la compra
  // de equipo no lo infla (si no, una despulpadora de 2.500.000 sobre 1.500 kg
  // lo llevaría de 400 a 2.066).
  test('el costo por kilo del Excel excluye la inversión en equipo', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final now = DateTime.now();
    final cafe = await p.addCrop('Café',
        phase: CropPhase.produccion, areaHa: 3);
    await p.addHarvest(cropId: cafe.id, date: now, amount: 1500);

    for (final e in [
      ('fertilizante', 300000.0),
      ('mano_obra', 200000.0),
      ('equipo', 2500000.0),
      ('arriendo', 100000.0),
    ]) {
      await p.addTransaction(
        type: TransactionType.expense,
        category: e.$1,
        amount: e.$2,
        cropId: cafe.id,
        date: now,
      );
    }
    await p.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 2000000,
      cropId: cafe.id,
      quantity: 1500,
      unit: 'kg',
      date: now,
    );

    final book = Excel.decodeBytes(ExcelExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
      harvests: p.harvests,
    ));
    final cells = [
      for (final r in book.tables[_es.excelSheetSummary]!.rows)
        for (final c in r) c?.value?.toString() ?? '',
    ];

    expect(cells, contains(_es.ratioOperationOnlyNote),
        reason: 'la nota dice de qué está hecho el ratio');
    // El rótulo del total ya no dice «operacionales»: incluye la inversión en
    // equipo, y la nota de al lado habla solo de operación.
    expect(cells, contains(_es.pdfTotalExpensesHeader));
    expect(cells.any((t) => t.toUpperCase().contains('OPERACIONAL')), isFalse);
    expect(cells.any((t) => RegExp(r'COP\s?400\b').hasMatch(t)), isTrue,
        reason: '600.000 de operación ÷ 1.500 kg = 400');
    expect(cells.any((t) => t.contains('2.066') || t.contains('2066')), isFalse,
        reason: 'el equipo no puede aparecer en el costo por kilo');

    // La fila de costo por kilo POR CULTIVO (hoja «Cosechas») lleva su nota
    // pegada abajo, igual que la del estado de resultados.
    final harvestRows = book.tables[_es.excelSheetHarvests]!.rows;
    var costRow = -1;
    for (var i = 0; i < harvestRows.length; i++) {
      final first = harvestRows[i].first?.value?.toString() ?? '';
      if (first.contains(_es.reportTotalCostPerKg)) costRow = i;
    }
    expect(costRow, greaterThanOrEqualTo(0));
    expect(
      harvestRows[costRow].length > 1
          ? harvestRows[costRow][1]?.value?.toString()
          : null,
      '400',
      reason: 'la fila por cultivo también es de operación',
    );
    expect(harvestRows[costRow + 1].first?.value?.toString(),
        _es.ratioOperationOnlyNote);
  });

  // C9 · el café es inversión de establecimiento mientras no haya cosechado.
  // El Excel tiene que contar lo mismo que la pantalla: las cercas de antes de
  // la primera cosecha sí, las de después no.
  test('la cobertura del Excel respeta la primera cosecha del café', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final cafe = await p.addCrop('Café');
    final platano = await p.addCrop('Plátano');

    await p.addTransaction(
      type: TransactionType.expense,
      category: kExpenseCategorySowing,
      amount: 1000,
      cropId: cafe.id,
      date: DateTime(2023, 3, 1),
    );
    await p.addTransaction(
      type: TransactionType.expense,
      category: kExpenseCategoryFences,
      amount: 500,
      cropId: cafe.id,
      date: DateTime(2023, 6, 1),
    );
    await p.addHarvest(
      cropId: cafe.id,
      date: DateTime(2023, 12, 15),
      amount: 500,
    );
    await p.addTransaction(
      type: TransactionType.expense,
      category: kExpenseCategoryFences,
      amount: 300,
      cropId: cafe.id,
      date: DateTime(2024, 6, 1),
    );
    await p.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 400,
      cropId: platano.id,
      date: DateTime(2024, 7, 1),
    );

    final book = Excel.decodeBytes(ExcelExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: 2024,
      period: ReportPeriod.year,
      periodName: '2024',
      l10n: _es,
      harvests: p.harvests,
    ));
    final cells = [
      for (final r in book.tables[_es.excelSheetSummary]!.rows)
        for (final c in r) c?.value?.toString() ?? '',
    ];
    final line = cells.firstWhere((t) => t.contains('cubren'));
    expect(line, contains('27%'),
        reason: '400 de 1.500: solo las cercas de antes de la cosecha son '
            'inversión');
    expect(line, contains('1.500'));
  });

  test('el desglose exportado lleva el reparto de gastos de cada cultivo',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final now = DateTime.now();
    final cafe = await p.addCrop('Café');

    Future<void> gasto(String category, double amount) => p.addTransaction(
          type: TransactionType.expense,
          category: category,
          cropId: cafe.id,
          amount: amount,
          date: now,
        );
    await gasto(kExpenseCategorySowing, 600000);
    await gasto('equipo', 2500000);
    await gasto('fertilizante', 300000);
    await p.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      cropId: cafe.id,
      amount: 1200000,
      date: now,
    );

    final excelBytes = Uint8List.fromList(ExcelExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
      harvests: p.harvests,
    ));
    final book = Excel.decodeBytes(excelBytes);
    final porCultivo = book.tables[_es.excelSheetCrops]!;

    final reparto = _cropSplitRows(porCultivo, 'Café');
    expect(reparto[_es.cropBreakdownInvestment], 600000,
        reason: 'la siembra es inversión inicial');
    expect(reparto[_es.expenseGroupInversion], 2500000,
        reason: 'el equipo tiene su propia línea, no va a operación');
    expect(reparto[_es.cropBreakdownOperation], 300000,
        reason: 'la operación del período es el fertilizante');
    expect(reparto.values.fold<double>(0, (a, b) => a + b), 3400000,
        reason: 'el reparto suma el total de gastos de la fila');

    // La jerarquía en el Excel la da un prefijo explícito «· », no espacios de
    // relleno: el paquete no puede escribir sangría de celda.
    final etiquetas = porCultivo.rows
        .map((r) => r.isNotEmpty ? (r.first?.value?.toString() ?? '') : '')
        .where((t) => t.contains('·'))
        .toList();
    expect(etiquetas, [
      '· ${_es.cropBreakdownInvestment}',
      '· ${_es.expenseGroupInversion}',
      '· ${_es.cropBreakdownOperation}',
    ]);

    // El PDF se arma sin romperse con las mismas líneas; su contenido va por
    // el mismo helper (`cropSplitLines`) que el Excel y la pantalla.
    final pdfBytes = await PdfExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: now.year,
      month: now.month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
      harvests: p.harvests,
    );
    final pages = _pdfPages(pdfBytes);
    expect(pages.objects, greaterThan(0));
    expect(pages.count, pages.objects,
        reason: 'el PDF con reparto sigue siendo coherente entre sus dos vías');
  });
}
