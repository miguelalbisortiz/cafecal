import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/services/threshing_yield.dart';

AppLocalizations get _es => stringsFor('es');

/// Café con 300 kg de cereza, factor 5,2 y 300.000 de gastos de producción:
/// 57,69 kg vendibles y 5.200 por kg vendible.
///
/// El factor lleva decimal a propósito: es lo que destapó que el PDF lo
/// escribía «5.20» y la pantalla «5,2».
Future<TransactionProvider> _fixture({double? factor = 5.2}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  final hoy = DateTime.now();

  await store.saveCrops([
    Crop(id: 'cafe', name: 'Café', threshingYield: factor),
  ]);
  await store.saveHarvests([
    Harvest(id: 'h1', cropId: 'cafe', date: hoy, amount: 300),
  ]);
  await store.saveTransactions([
    Transaction(
      id: 't-cosecha',
      cropId: 'cafe',
      type: TransactionType.expense,
      category: kExpenseCategoryHarvest,
      amount: 200000,
      date: hoy,
      createdAt: hoy,
      harvestId: 'h1',
    ),
    Transaction(
      id: 't-beneficio',
      cropId: 'cafe',
      type: TransactionType.expense,
      category: kExpenseCategoryBenefit,
      amount: 100000,
      date: hoy,
      createdAt: hoy,
      harvestId: 'h1',
    ),
  ]);
  return TransactionProvider(store);
}

Uint8List _excel(TransactionProvider p) => Uint8List.fromList(
      ExcelExportService().buildReport(
        settings: p.settings,
        transactions: p.transactions,
        crops: p.crops,
        year: DateTime.now().year,
        month: DateTime.now().month,
        period: ReportPeriod.month,
        periodName: 'Mes',
        l10n: _es,
        harvests: p.harvests,
      ),
    );

Future<Uint8List> _pdf(TransactionProvider p) => PdfExportService().buildReport(
      settings: p.settings,
      transactions: p.transactions,
      crops: p.crops,
      year: DateTime.now().year,
      month: DateTime.now().month,
      period: ReportPeriod.month,
      periodName: 'Mes',
      l10n: _es,
      harvests: p.harvests,
    );

List<List<String>> _rows(Sheet sheet) => [
      for (final row in sheet.rows)
        [for (final c in row) c?.value?.toString() ?? ''],
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el Excel lleva la fila del cultivo con su factor y sus kilos', () async {
    final p = await _fixture();
    final rows = _rows(
        Excel.decodeBytes(_excel(p)).tables[_es.excelSheetHarvests]!);

    // Paridad: los números salen de la función compartida y del formateador
    // del idioma, no de una copia del cálculo.
    final servicio = threshingRows(
      crops: p.crops,
      harvests: p.harvests,
      transactions: p.transactions,
      sacoKg: p.settings.sacoKg,
    ).single;
    expect(servicio.sellableKg, closeTo(57.69, 0.01));
    expect(servicio.costPerSellableKg, closeTo(5200, 0.01));

    // El formato es el del idioma, y se fija acá: coma en español, punto en
    // inglés. Las tres salidas usan estas mismas dos funciones.
    final etiqueta = threshingLabel(servicio, _es, 'es');
    expect(etiqueta, 'Café · factor 5,2');
    expect(threshingLabel(servicio, stringsFor('en'), 'en'),
        'Café · factor 5.2');

    expect(
        rows.any((r) =>
            r.first == etiqueta &&
            r.length > 1 &&
            r[1] == threshingKgLine(servicio, _es, 'es')),
        isTrue,
        reason: 'falta la fila del rendimiento de trilla');
    // El bug que esto cierra: `toStringAsFixed` daba «5.20» en el PDF.
    expect(rows.any((r) => r.first.contains('5.20')), isFalse);
    expect(rows.any((r) => r.first == _es.reportThreshingTitle), isTrue);
    expect(rows.any((r) => r.first == _es.reportThreshingCost), isTrue);
    expect(rows.any((r) => r.first == _es.reportThreshingNote), isTrue);
  });

  test('sin factor el Excel no estrena la sección', () async {
    final p = await _fixture(factor: null);
    final rows = _rows(
        Excel.decodeBytes(_excel(p)).tables[_es.excelSheetHarvests]!);

    expect(rows.any((r) => r.first == _es.reportThreshingTitle), isFalse);
    expect(rows.any((r) => r.first == _es.reportThreshingCost), isFalse);
  });

  test('el PDF también la pinta, y no cuando no hay factor', () async {
    final conFactor = await _pdf(await _fixture());
    final sinFactor = await _pdf(await _fixture(factor: null));

    expect(conFactor.length, greaterThan(sinFactor.length),
        reason: 'el PDF con factor debe llevar la sección de más');
    expect(String.fromCharCodes(conFactor.take(5)), '%PDF-');
  });
}
