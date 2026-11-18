import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/product_state.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

AppLocalizations get _es => stringsFor('es');

/// Ventas de café en dos estados y dos monedas: 100 kg de cereza en pesos y
/// 50 kg de pergamino en dólares. Es el mínimo que obliga a las dos reglas del
/// desglose: agrupar por estado y no cruzar monedas.
Future<TransactionProvider> _fixture({bool conEstados = true}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final p = TransactionProvider(LocalStore(prefs));
  final now = DateTime.now();
  final cafe = await p.addCrop('Café');

  await p.addTransaction(
    type: TransactionType.income,
    category: kIncomeCategorySale,
    cropId: cafe.id,
    amount: 600000,
    quantity: 100,
    unit: 'kg',
    date: now,
    productState: conEstados ? ProductState.cereza : null,
  );
  await p.addTransaction(
    type: TransactionType.income,
    category: kIncomeCategorySale,
    cropId: cafe.id,
    amount: 900,
    currency: 'USD',
    quantity: 50,
    unit: 'kg',
    date: now,
    productState: conEstados ? ProductState.pergamino : null,
  );
  return p;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el Excel lleva el desglose con los dos estados y sin cruzar monedas',
      () async {
    final p = await _fixture();
    final book = Excel.decodeBytes(_excel(p));
    final rows = _rows(book.tables[_es.excelSheetSummary]!);

    expect(rows.any((r) => r.first == _es.reportSalesByState), isTrue,
        reason: 'falta la sección «Ventas por estado»');

    for (final esperado in ['Cereza', 'Pergamino', _es.reportSalesByStateKg,
        _es.reportSalesByStatePrice]) {
      expect(rows.any((r) => r.first == esperado), isTrue,
          reason: 'falta la fila «$esperado»');
    }

    // Cada estado con su moneda: nunca un total que cruce COP y USD.
    expect(rows.any((r) => r.length > 1 && r[1] == '100 kg'), isTrue);
    expect(rows.any((r) => r.length > 1 && r[1] == '50 kg'), isTrue);
    expect(rows.any((r) => r.length > 1 && r[1] == 'COP 6.000'), isTrue);
    expect(rows.any((r) => r.length > 1 && r[1] == 'USD 18,00'), isTrue);

    // Las dos monedas se etiquetan porque el período es mixto.
    expect(rows.any((r) => r.first == 'COP'), isTrue);
    expect(rows.any((r) => r.first == 'USD'), isTrue);
  });

  test('sin ventas con estado el Excel no estrena la sección', () async {
    final p = await _fixture(conEstados: false);
    final book = Excel.decodeBytes(_excel(p));
    final rows = _rows(book.tables[_es.excelSheetSummary]!);

    expect(rows.any((r) => r.first == _es.reportSalesByState), isFalse);
  });

  test('el PDF también pinta el desglose, y no cuando no hay estados',
      () async {
    final conEstados = await _pdf(await _fixture());
    final sinEstados = await _pdf(await _fixture(conEstados: false));

    // El contenido del PDF sale de la misma lista que el Excel, así que si la
    // sección existe el archivo crece. No se compara texto: el PDF va con la
    // fuente empotrada y sus glifos no son ASCII.
    expect(conEstados.length, greaterThan(sinEstados.length),
        reason: 'el PDF con estados debe llevar la sección de más');

    // Y sigue siendo un PDF válido.
    expect(String.fromCharCodes(conEstados.take(5)), '%PDF-');
  });
}
