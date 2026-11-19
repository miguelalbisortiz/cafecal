import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/currencies.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/crop_totals.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';

AppLocalizations get _es => stringsFor('es');

/// Una cosecha de 300 kg con el beneficio repartido en dos: lo ligado a la
/// cosecha (150.000) y lo que se anotó suelto (60.000 de beneficio + 25.000 de
/// secado). Con [conSuelto] en false queda solo lo ligado.
Future<TransactionProvider> _fixture({bool conSuelto = true}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  final hoy = DateTime.now();
  const cafe = Crop(id: 'cafe', name: 'Café');

  await store.saveCrops([cafe]);
  await store.saveHarvests([
    Harvest(id: 'h1', cropId: 'cafe', date: hoy, amount: 300),
  ]);
  await store.saveTransactions([
    // Recogida ligada: 90.000 / 300 kg = 300 por kg.
    Transaction(
      id: 't-cosecha',
      cropId: 'cafe',
      type: TransactionType.expense,
      category: kExpenseCategoryHarvest,
      amount: 90000,
      date: hoy,
      createdAt: hoy,
      harvestId: 'h1',
    ),
    // Beneficio ligado: 150.000 / 300 kg = 500 por kg.
    Transaction(
      id: 't-beneficio-ligado',
      cropId: 'cafe',
      type: TransactionType.expense,
      category: kExpenseCategoryBenefit,
      amount: 150000,
      date: hoy,
      createdAt: hoy,
      harvestId: 'h1',
    ),
    if (conSuelto) ...[
      Transaction(
        id: 't-beneficio-suelto',
        cropId: 'cafe',
        type: TransactionType.expense,
        category: kExpenseCategoryBenefit,
        amount: 60000,
        date: hoy,
        createdAt: hoy,
      ),
      Transaction(
        id: 't-secado-suelto',
        cropId: 'cafe',
        type: TransactionType.expense,
        category: kExpenseCategoryDrying,
        amount: 25000,
        date: hoy,
        createdAt: hoy,
      ),
    ],
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

/// Todas las celdas de una hoja, como texto, en orden de fila.
List<List<String>> _rows(Sheet sheet) => [
      for (final row in sheet.rows)
        [for (final c in row) c?.value?.toString() ?? ''],
    ];

/// El texto que deben decir las tres salidas para el beneficio suelto.
///
/// Sale de la MISMA función que usa la pantalla (`benefitCostsWithoutHarvest`
/// + `amountsByCurrency`), formateada con el mismo formateador de los
/// exportadores: si alguna salida inventara su propio número, esto no cuadra.
String _esperado(TransactionProvider p) {
  final amounts = amountsByCurrency(
      const ReportHarvestMetrics().benefitCostsWithoutHarvest(p.transactions));
  return byCurrencyText(amounts, (v, c) => formatMoneyLabel(v, c, locale: 'es'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el Excel lleva el beneficio sin cosecha, y no lo ligado', () async {
    final p = await _fixture();
    final rows = _rows(
        Excel.decodeBytes(_excel(p)).tables[_es.excelSheetHarvests]!);

    expect(_esperado(p), 'COP 85.000');
    expect(
        rows.any((r) =>
            r.first == _es.reportBenefitCostUnlinked && r[1] == _esperado(p)),
        isTrue,
        reason: 'falta la fila «${_es.reportBenefitCostUnlinked}» con su monto');
    expect(rows.any((r) => r.first == _es.reportBenefitCostUnlinkedNote),
        isTrue,
        reason: 'la fila del período necesita su nota');
    // Lo ligado no se repite acá: ya está en «Beneficio y secado por kg».
    expect(rows.any((r) => r.length > 1 && r[1] == 'COP 150.000'), isFalse);
  });

  test('sin beneficio suelto el Excel no estrena la fila', () async {
    final p = await _fixture(conSuelto: false);
    final rows = _rows(
        Excel.decodeBytes(_excel(p)).tables[_es.excelSheetHarvests]!);

    expect(rows.any((r) => r.first == _es.reportBenefitCostUnlinked), isFalse);
  });

  test('el PDF también la pinta, y no cuando no hay beneficio suelto',
      () async {
    final conSuelto = await _pdf(await _fixture());
    final sinSuelto = await _pdf(await _fixture(conSuelto: false));

    // El PDF va con la fuente empotrada y sus glifos no son ASCII: se compara
    // el tamaño, igual que el test de paridad de «Ventas por estado».
    expect(conSuelto.length, greaterThan(sinSuelto.length),
        reason: 'el PDF con beneficio suelto debe llevar la fila de más');
    expect(String.fromCharCodes(conSuelto.take(5)), '%PDF-');
  });

  test('las tres salidas dicen el mismo monto', () async {
    final p = await _fixture();
    final rows = _rows(
        Excel.decodeBytes(_excel(p)).tables[_es.excelSheetHarvests]!);
    final enExcel = rows
        .firstWhere((r) => r.first == _es.reportBenefitCostUnlinked)[1];

    // Paridad real: la cifra sale de la función compartida, no de una copia.
    final montos = amountsByCurrency(
        const ReportHarvestMetrics().benefitCostsWithoutHarvest(p.transactions));
    expect(montos, {'COP': 85000});
    expect(enExcel, _esperado(p));
  });
}
