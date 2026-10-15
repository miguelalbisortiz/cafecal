import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/services/report_harvest_metrics.dart';

/// **Fase 4 — reportes.** Dos cosas:
///
/// 1. **lo que se enciende**: la sección Cosechas, el rendimiento por
///    hectárea y el costo por kilo tenían `null` porque no había cosechas.
///    Ahora salen de la venta, sin pedirle nada.
/// 2. **lo que se apaga (D5)**: «vendido vs cosechado» mientras la única
///    fuente sea la venta sería comparar un número consigo mismo — y hay que
///    apagarlo en **los tres pintadores a la vez**, o dejan de decir lo mismo.
AppLocalizations get _es => stringsFor('es');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Una venta de 50 kg en el mes en curso: es todo lo que hace falta para
  /// que exista una cosecha derivada.
  Future<TransactionProvider> build() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final crop = await p.addCrop('Café');
    await p.addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      amount: 150000,
      cropId: crop.id,
      quantity: 50,
      unit: 'kg',
      date: DateTime.now(),
    );
    return p;
  }

  Future<void> pumpReport(
      WidgetTester tester, TransactionProvider provider) async {
    // El reporte es una ListView larga: sin viewport alto las tarjetas de
    // abajo quedan fuera del área construida.
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  // Extrae el valor nativo de una celda Excel.
  dynamic cv(Data? cell) {
    final v = cell?.value;
    if (v == null) return null;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) return v.value.text;
    return null;
  }

  bool hayFila(List<List<Data?>> rows, String texto) => rows.any(
      (r) => (cv(r[0])?.toString() ?? '').contains(texto));

  group('Lo que se enciende', () {
    testWidgets('la sección Cosechas aparece con solo una venta', (tester) async {
      final p = await build();
      expect(p.harvests, hasLength(1));

      await pumpReport(tester, p);

      expect(find.text(_es.reportHarvestSection), findsOneWidget,
          reason: '«Cosechas del período» ya no puede estar vacía');
      expect(find.text(_es.reportNoHarvestData), findsNothing,
          reason: 'los kilos de la venta SÍ son kilos cosechados');
    });

    test('rendimiento/ha y costo/kg salen de los kilos de la venta', () async {
      final p = await build();
      const m = ReportHarvestMetrics();
      final kg = p.harvests;

      expect(m.totalsByCrop(kg, p.crops).single.kg, 50);
      expect(m.yieldPerArea(kg, 0.5), 100, reason: '50 kg ÷ 0,5 ha');
      expect(m.periodCostPerKg(1500, kg), 30, reason: '1500 ÷ 50 kg');
      expect(m.yieldPerPlant(kg, 100), 0.5, reason: '50 kg ÷ 100 plantas');
    });

    test('sin kilos en la venta, todo sigue en null (nunca un 0)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final p = TransactionProvider(LocalStore(prefs));
      await p.addCrop('Café');
      await p.addTransaction(
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 5000,
        cropId: p.crops.first.id,
        // Sin kilos → no hay cosecha que derivar.
        date: DateTime.now(),
      );

      expect(p.harvests, isEmpty);

      const m = ReportHarvestMetrics();
      expect(m.totalsByCrop(p.harvests, p.crops), isEmpty);
      expect(m.yieldPerArea(p.harvests, 0.5), isNull);
      expect(m.periodCostPerKg(1500, p.harvests), isNull);
    });
  });

  group('D5 · vendido vs cosechado', () {
    testWidgets('queda OCULTA mientras todo venga de la venta', (tester) async {
      final p = await build();

      await pumpReport(tester, p);

      expect(find.text(_es.reportSoldVsHarvested), findsNothing,
          reason: 'comparar 50 vendidos contra 50 cosechados no dice nada');
    });

    testWidgets('se enciende sola con una cosecha medida a mano',
        (tester) async {
      final p = await build();
      await p.addHarvest(
        cropId: p.crops.single.id,
        date: DateTime.now(),
        amount: 60,
      );

      await pumpReport(tester, p);

      expect(find.text(_es.reportSoldVsHarvested), findsOneWidget,
          reason: 'ahí sí hay una segunda medida que confrontar');
    });

    testWidgets('sin cosechas tampoco se muestra', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final p = TransactionProvider(LocalStore(prefs));
      await p.addCrop('Café');

      await pumpReport(tester, p);

      expect(find.text(_es.reportSoldVsHarvested), findsNothing);
      expect(find.text(_es.reportNoHarvestData), findsOneWidget,
          reason: 'esa es la rama honesta de la sección Cosechas');
    });
  });

  group('Los tres pintadores dicen lo mismo', () {
    test('el Excel pinta exactamente los kilos que calcula la pantalla',
        () async {
      final p = await build();
      final now = DateTime.now();
      final bytes = Uint8List.fromList(ExcelExportService().buildReport(
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
      final rows = Excel.decodeBytes(bytes).tables[_es.excelSheetHarvests]!.rows;

      // El mismo número que pinta la pantalla en «Total cosechado por cultivo».
      final esperado =
          const ReportHarvestMetrics().totalsByCrop(p.harvests, p.crops).single.kg;
      expect(esperado, 50);

      expect(hayFila(rows, 'Café'), isTrue);
      expect(cv(rows.firstWhere((r) => (cv(r[0])?.toString() ?? '').contains('Café'))[2]),
          esperado,
          reason: 'la celda de kg del Excel = el kg de la pantalla');
      expect(hayFila(rows, _es.reportSoldVsHarvested), isFalse,
          reason: 'D5 también acá: sin cosecha independiente no hay conciliación');
    });

    test('el Excel sí muestra la conciliación con una cosecha a mano',
        () async {
      final p = await build();
      await p.addHarvest(
        cropId: p.crops.single.id,
        date: DateTime.now(),
        amount: 60,
      );
      final now = DateTime.now();
      final bytes = Uint8List.fromList(ExcelExportService().buildReport(
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
      final rows = Excel.decodeBytes(bytes).tables[_es.excelSheetHarvests]!.rows;

      expect(hayFila(rows, _es.reportSoldVsHarvested), isTrue,
          reason: 'la misma puerta que en pantalla: se enciende sola');
    });

    test('el PDF se construye con cosechas derivadas', () async {
      final p = await build();
      final now = DateTime.now();
      final bytes = await PdfExportService().buildReport(
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

      expect(String.fromCharCodes(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  });
}
