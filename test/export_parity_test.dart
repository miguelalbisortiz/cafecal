import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
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
    const filasEsperadas = 6;
    const ingresosEsperados = 'COP 350.000 · USD 30,00';
    const gastosEsperados = '(COP 150.000) · (USD 20,00)';
    const paginasEsperadas = 2;

    expect(_movementRows(movimientos), filasEsperadas,
        reason: 'la hoja de movimientos cambió de tamaño');
    expect(_summaryTotal(resumen, _es.pdfIncomesHeader), ingresosEsperados,
        reason: 'los ingresos por moneda cambiaron');
    expect(_summaryTotal(resumen, _es.pdfExpensesHeader), gastosEsperados,
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
}
