import 'dart:convert';
import 'dart:io' show File, ZLibDecoder;
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// Tanda 2C · las dos atribuciones se nombran distinto.
///
/// Reparto por hectáreas (desglose y costo por kilo) ≠ aporte por producto
/// (sin reparto). El cálculo ya es correcto y distinto; aquí se guarda que el
/// rótulo también lo sea en los tres pintadores.

Map<String, dynamic> _arb(String locale) => jsonDecode(
      File('lib/l10n/app_$locale.arb').readAsStringSync(),
    ) as Map<String, dynamic>;

/// Acceso dinámico a propósito: si la clave generada aún no existe, el test
/// falla en rojo en vez de impedir que se compilen los demás.
String _rotulo(AppLocalizations l10n) =>
    (l10n as dynamic).cropBreakdownSplitNote as String;

Future<TransactionProvider> _finca() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final p = TransactionProvider(LocalStore(prefs));
  final cafe = await p.addCrop('Café');
  final platano = await p.addCrop('Plátano');
  // Un lote compartido dispara la nota de cultivos asociados, que es donde
  // vive el rótulo de reparto en los tres pintadores.
  await p.addTerreno('Lote El Alto', cropIds: [cafe.id, platano.id]);
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
        l10n: stringsFor('es'),
        harvests: p.harvests,
        sowings: p.sowings,
        terrenos: p.terrenos,
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
      l10n: stringsFor('es'),
      harvests: p.harvests,
      sowings: p.sowings,
      terrenos: p.terrenos,
    );

String _hoja(Sheet sheet) => sheet.rows
    .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
    .join('\n');

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

  test('los dos ARB y el generado nombran cada regla con su texto', () {
    final esArb = _arb('es');
    final enArb = _arb('en');

    expect(esArb['cropBreakdownSplitNote'], contains('reparte por hectáreas'));
    expect(enArb['cropBreakdownSplitNote'], contains('split by hectares'));
    expect(_rotulo(es), esArb['cropBreakdownSplitNote']);
    expect(_rotulo(stringsFor('en')), enArb['cropBreakdownSplitNote']);
    // Y el otro rótulo ya no afirma lo contrario.
    expect(esArb['contributionSubtitle'], contains('no reparte'));
    expect(enArb['contributionSubtitle'], contains('does not split'));
  });

  testWidgets('la pantalla rotula el reparto junto al desglose', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final p = await _finca();
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

    expect(find.text(_rotulo(es)), findsOneWidget,
        reason: 'el desglose y el aporte no pueden leerse igual');
  });

  test('el Excel rotula el reparto en la hoja Por cultivo', () async {
    final p = await _finca();
    final hoja = _hoja(Excel.decodeBytes(_excel(p)).tables[es.excelSheetCrops]!);
    expect(hoja, contains(_rotulo(es)));
  });

  test('el PDF rotula el reparto en el desglose', () async {
    final p = await _finca();
    final texto = _pdfText(await _pdf(p));
    expect(texto, contains(_rotulo(es).replaceAll(RegExp(r'\s'), '')));
  });
}
