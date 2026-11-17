import 'dart:convert';
import 'dart:io' show ZLibDecoder;
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/buyer_concentration.dart';
import 'package:mi_cafetal/services/currency_conversion.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/widgets/period_totals.dart';

/// Tanda 3 · hito 3 · SC-G4/SC-3.3/SC-3.4. La MISMA fila en Reportes, PDF y
/// Excel; oculta en los tres con 50 %, un comprador o moneda mixta.

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
  const locale = 'es_CO';

  Future<TransactionProvider> finca({
    String clientA = 'A',
    double amountA = 700,
    String clientB = 'B',
    double amountB = 300,
    bool mezcla = false,
    bool unSoloComprador = false,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final p = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();
    await p.addTransaction(
      type: TransactionType.income,
      category: 'venta',
      amount: amountA,
      client: clientA,
      currency: 'COP',
      date: hoy,
    );
    if (!unSoloComprador) {
      await p.addTransaction(
        type: TransactionType.income,
        category: 'venta',
        amount: amountB,
        client: clientB,
        currency: mezcla ? 'USD' : 'COP',
        date: hoy,
      );
    }
    return p;
  }

  String? esperado(TransactionProvider p) {
    final row = buyerConcentration(records: p.transactions);
    return row == null ? null : buyerConcentrationMessage(row, es, locale);
  }

  /// La frase que SÍ se emitiría si el umbral fallara: la buscamos para
  /// demostrar que los tres pintadores callan.
  String fraseSiSeEmitiera(double pct) => buyerConcentrationMessage(
        BuyerConcentrationRow(
          buyer: 'A',
          currency: 'COP',
          sharePct: pct,
          buyerAmount: 1000,
          salesTotal: 1000,
          buyerCount: 2,
        ),
        es,
        locale,
      );

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

  Future<void> pumpReport(
    WidgetTester tester,
    TransactionProvider p, {
    CurrencyConversionService? fx,
  }) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Widget tree = const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReportScreen(),
    );
    if (fx != null) tree = CurrencyConversionScope(service: fx, child: tree);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: p, child: tree));
    await tester.pumpAndSettle();
  }

  String textoExcel(Uint8List bytes) => Excel.decodeBytes(bytes)
      .tables
      .values
      .map((s) => s.rows
          .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
          .join('\n'))
      .join('\n');

  testWidgets('SC-G4 · la misma fila con % y nombre en los tres pintadores',
      (tester) async {
    final p = await finca();
    final mensaje = esperado(p);
    expect(mensaje, isNotNull);
    expect(mensaje, contains('70%'));
    expect(mensaje, contains('A'));

    await pumpReport(tester, p);
    expect(find.text(mensaje!), findsOneWidget, reason: 'pantalla');

    final textoXls = textoExcel(excel(p));
    expect(textoXls, contains(mensaje), reason: 'Excel');

    final textoPdf = _pdfText(await pdf(p));
    expect(textoPdf, contains(mensaje.replaceAll(RegExp(r'\s'), '')),
        reason: 'PDF');
  });

  testWidgets('SC-3.3 · con 50 % o un solo comprador no aparece en ninguno',
      (tester) async {
    final p50 = await finca(amountA: 500, amountB: 500);
    expect(esperado(p50), isNull);
    final frase50 = fraseSiSeEmitiera(50);

    await pumpReport(tester, p50);
    expect(find.text(frase50), findsNothing, reason: 'pantalla · 50 %');
    expect(textoExcel(excel(p50)), isNot(contains(frase50)), reason: 'Excel');
    expect(_pdfText(await pdf(p50)),
        isNot(contains(frase50.replaceAll(RegExp(r'\s'), ''))),
        reason: 'PDF · 50 %');

    final p1 = await finca(unSoloComprador: true);
    expect(esperado(p1), isNull);
    final frase100 = fraseSiSeEmitiera(100);

    await pumpReport(tester, p1);
    expect(find.text(frase100), findsNothing, reason: 'pantalla · 1 comprador');
    expect(textoExcel(excel(p1)), isNot(contains(frase100)), reason: 'Excel');
    expect(_pdfText(await pdf(p1)),
        isNot(contains(frase100.replaceAll(RegExp(r'\s'), ''))),
        reason: 'PDF · 1 comprador');
  });

  testWidgets('SC-3.4 / SC-G2 · con COP + USD la fila no aparece en ninguno',
      (tester) async {
    final sinMezcla = await finca();
    final frase = esperado(sinMezcla)!;
    final p = await finca(mezcla: true);
    expect(esperado(p), isNull, reason: 'sin conversión entre monedas');

    // Con dos monedas la pantalla pide una tasa: servicio sin red y se agotan
    // los reintentos para no dejar timers pendientes al dispose.
    final prefs = await SharedPreferences.getInstance();
    final fx = CurrencyConversionService(
      rates: CurrencyRatesService(
          client: MockClient((_) async => throw Exception('sin red'))),
      prefs: () async => prefs,
    );
    await pumpReport(tester, p, fx: fx);
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(find.text(frase), findsNothing, reason: 'pantalla');

    final textoXls = textoExcel(excel(p));
    expect(textoXls, isNot(contains(frase)), reason: 'Excel');

    final textoPdf = _pdfText(await pdf(p));
    expect(textoPdf,
        isNot(contains(frase.replaceAll(RegExp(r'\s'), ''))), reason: 'PDF');
  });
}
