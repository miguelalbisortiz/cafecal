import 'dart:convert';
import 'dart:io' show ZLibDecoder;
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/services/unsold_stock.dart';

/// SC-G4 · la misma fila de stock, con la misma cifra y la misma acción, en
/// Reportes, PDF y Excel. Rojo antes de tocar los tres pintadores.

String _pdfText(Uint8List bytes) {
  final comoTexto = latin1.decode(bytes, allowInvalid: true);
  final streams = StringBuffer();
  for (final m in RegExp(r'stream\r?\n').allMatches(comoTexto)) {
    final inicio = m.end;
    final fin = comoTexto.indexOf('endstream', inicio);
    if (fin < 0) continue;
    var trozo = bytes.sublist(inicio, fin);
    while (trozo.isNotEmpty && (trozo.last == 10 || trozo.last == 13)) {
      trozo = trozo.sublist(0, trozo.length - 1);
    }
    try {
      streams.write(latin1.decode(ZLibDecoder().convert(trozo),
          allowInvalid: true));
    } catch (_) {
      // stream que no es Flate: no es texto.
    }
  }
  final todo = streams.toString();
  final salida = StringBuffer();
  for (final bloque in RegExp(r'beginbfchar(.*?)endbfchar', dotAll: true)
      .allMatches(todo)
      .map((m) => m.group(1)!)) {
    final cmap = <String, String>{};
    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
        .allMatches(bloque)) {
      final dst = m.group(2)!;
      final unidades = <int>[];
      for (var i = 0; i + 3 < dst.length; i += 4) {
        unidades.add(int.parse(dst.substring(i, i + 4), radix: 16));
      }
      cmap[m.group(1)!.toUpperCase()] = String.fromCharCodes(unidades);
    }
    void glifos(String hex) {
      for (var i = 0; i + 3 < hex.length; i += 4) {
        salida.write(cmap[hex.substring(i, i + 4).toUpperCase()] ?? '');
      }
    }

    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*Tj').allMatches(todo)) {
      glifos(m.group(1)!);
    }
    for (final m in RegExp(r'\[(.*?)\]\s*TJ', dotAll: true)
        .allMatches(todo)) {
      for (final h in RegExp(r'<([0-9A-Fa-f]+)>').allMatches(m.group(1)!)) {
        glifos(h.group(1)!);
      }
    }
  }
  return salida.toString().replaceAll(RegExp(r'\s'), '');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final es = stringsFor('es');

  Future<TransactionProvider> finca({int cultivos = 1}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final cafe = await p.addCrop('Café');
    final hoy = DateTime.now();
    await p.addHarvest(cropId: cafe.id, date: hoy, amount: 100);
    await p.addTransaction(
      type: TransactionType.income,
      category: 'venta',
      amount: 40000,
      cropId: cafe.id,
      date: hoy,
      quantity: 40,
      unit: 'kg',
    );
    if (cultivos == 2) {
      final platano = await p.addCrop('Plátano');
      await p.addHarvest(cropId: platano.id, date: hoy, amount: 50);
      await p.addTransaction(
        type: TransactionType.income,
        category: 'venta',
        amount: 15000,
        cropId: platano.id,
        date: hoy,
        quantity: 30,
        unit: 'kg',
      );
    }
    return p;
  }

  List<String> mensajes(TransactionProvider p) => unsoldStockByCrop(
        transactions: p.transactions,
        harvests: p.harvests,
        crops: p.crops,
        sacoKg: p.settings.sacoKg,
        now: DateTime.now(),
      ).map((r) => unsoldStockMessage(r, es, p.settings.numberLocale)).toList();

  Uint8List excel(TransactionProvider p) => Uint8List.fromList(
        ExcelExportService().buildReport(
          settings: p.settings,
          transactions: p.transactions,
          crops: p.crops,
          year: DateTime.now().year,
          month: DateTime.now().month,
          period: ReportPeriod.month,
          periodName: 'Mes',
          l10n: es,
          harvests: p.harvests,
          sowings: p.sowings,
          terrenos: p.terrenos,
        ),
      );

  Future<Uint8List> pdf(TransactionProvider p) => PdfExportService().buildReport(
        settings: p.settings,
        transactions: p.transactions,
        crops: p.crops,
        year: DateTime.now().year,
        month: DateTime.now().month,
        period: ReportPeriod.month,
        periodName: 'Mes',
        l10n: es,
        harvests: p.harvests,
        sowings: p.sowings,
        terrenos: p.terrenos,
      );

  Future<void> pumpReport(WidgetTester tester, TransactionProvider p) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('SC-G4 · un cultivo: la misma fila en los tres pintadores',
      (tester) async {
    final p = await finca();
    final esperado = mensajes(p).single;
    await pumpReport(tester, p);
    expect(find.text(esperado), findsOneWidget, reason: 'pantalla');

    final hojas = Excel.decodeBytes(excel(p)).tables.values;
    final textoExcel = hojas
        .map((s) => s.rows
            .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
            .join('\n'))
        .join('\n');
    expect(textoExcel, contains(esperado), reason: 'Excel');

    final textoPdf = _pdfText(await pdf(p));
    expect(textoPdf, contains(esperado.replaceAll(RegExp(r'\s'), '')),
        reason: 'PDF');
  });

  testWidgets('SC-1.2 · dos cultivos: dos filas sin dedupe en los tres',
      (tester) async {
    final p = await finca(cultivos: 2);
    final esperado = mensajes(p);
    expect(esperado, hasLength(2));

    await pumpReport(tester, p);
    for (final m in esperado) {
      expect(find.text(m), findsOneWidget, reason: 'pantalla · $m');
    }

    final hojas = Excel.decodeBytes(excel(p)).tables.values;
    final textoExcel = hojas
        .map((s) => s.rows
            .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
            .join('\n'))
        .join('\n');
    final textoPdf = _pdfText(await pdf(p));
    for (final m in esperado) {
      expect(textoExcel, contains(m), reason: 'Excel · $m');
      expect(textoPdf, contains(m.replaceAll(RegExp(r'\s'), '')),
          reason: 'PDF · $m');
    }
  });
}
