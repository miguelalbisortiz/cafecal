import 'dart:convert';
import 'dart:io' show ZLibDecoder;
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/currencies.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';
import 'package:mi_cafetal/services/report_insights_service.dart';
import 'package:mi_cafetal/services/report_period_records.dart';

/// Tanda 2B · paridad de los tres pintadores.
///
/// La conclusión, «Qué hacer» y «Principales compradores» nacen en Reportes;
/// el PDF y el Excel deben repetirlos con la misma regla y el mismo texto.
/// Ninguna cifra se inventa: todo sale de los mismos registros.

AppLocalizations get _es => stringsFor('es');

List<Crop> _crops() => const [
      Crop(id: 'cafe', name: 'Café', icon: 'X', color: '#6D4C41'),
    ];

const FarmSettings _settings = FarmSettings(farmName: 'Finca La Esperanza');

/// Junio con dos compradores y dos proveedores, mayo para la tendencia y un
/// registro borrado que no debe contar en ningún pintador.
List<Transaction> _transactions() => [
      Transaction(
        id: 's0',
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 300000,
        client: 'Comprador Andino',
        date: DateTime(2026, 5, 20),
        createdAt: DateTime(2026, 5, 20),
      ),
      Transaction(
        id: 'e0',
        type: TransactionType.expense,
        category: 'insumos',
        amount: 70000,
        provider: 'Proveedor Verde',
        date: DateTime(2026, 5, 8),
        createdAt: DateTime(2026, 5, 8),
      ),
      Transaction(
        id: 's1',
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 500000,
        client: 'Comprador Andino',
        cropId: 'cafe',
        quantity: 10,
        unit: 'kg',
        date: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 6, 10),
      ),
      Transaction(
        id: 'e1',
        type: TransactionType.expense,
        category: 'insumos',
        amount: 120000,
        provider: 'Proveedor Verde',
        cropId: 'cafe',
        date: DateTime(2026, 6, 5),
        createdAt: DateTime(2026, 6, 5),
      ),
      Transaction(
        id: 'e2',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 80000,
        provider: 'Cuadrilla Norte',
        cropId: 'cafe',
        date: DateTime(2026, 6, 12),
        createdAt: DateTime(2026, 6, 12),
      ),
      Transaction(
        id: 'e3',
        type: TransactionType.expense,
        category: 'energia',
        amount: 30000,
        date: DateTime(2026, 6, 15),
        createdAt: DateTime(2026, 6, 15),
      ),
      Transaction(
        id: 'borrado',
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 999999,
        client: 'No debe aparecer',
        date: DateTime(2026, 6, 16),
        createdAt: DateTime(2026, 6, 16),
        deleted: true,
      ),
    ];

Future<Uint8List> _pdf(List<Transaction> transactions) =>
    PdfExportService().buildReport(
      settings: _settings,
      transactions: transactions,
      crops: _crops(),
      year: 2026,
      month: 6,
      period: ReportPeriod.month,
      periodName: 'Junio de 2026',
      l10n: _es,
    );

Uint8List _excel(List<Transaction> transactions) => Uint8List.fromList(
      ExcelExportService().buildReport(
        settings: _settings,
        transactions: transactions,
        crops: _crops(),
        year: 2026,
        month: 6,
        period: ReportPeriod.month,
        periodName: 'Junio de 2026',
        l10n: _es,
      ),
    );

String _norm(String s) => s.replaceAll(RegExp(r'\s'), '');

/// Todo el texto de una hoja, para buscar frases sin depender de la fila.
String _excelText(Sheet sheet) => sheet.rows
    .map((r) => r.map((c) => c?.value?.toString() ?? '').join(' | '))
    .join('\n');

/// Texto de los streams FlateDecode del PDF, ya inflado.
String _pdfStreams(Uint8List bytes) {
  final comoTexto = latin1.decode(bytes, allowInvalid: true);
  final salida = StringBuffer();
  for (final m in RegExp(r'stream\r?\n').allMatches(comoTexto)) {
    final inicio = m.end;
    final fin = comoTexto.indexOf('endstream', inicio);
    if (fin < 0) continue;
    var trozo = bytes.sublist(inicio, fin);
    while (trozo.isNotEmpty && (trozo.last == 10 || trozo.last == 13)) {
      trozo = trozo.sublist(0, trozo.length - 1);
    }
    try {
      salida.write(
          latin1.decode(ZLibDecoder().convert(trozo), allowInvalid: true));
    } catch (_) {
      // Un stream que no es Flate (p. ej. datos binarios) no es texto.
    }
  }
  return salida.toString();
}

String _pdfText(Uint8List bytes) {
  final streams = _pdfStreams(bytes);
  final mapas = RegExp(r'beginbfchar(.*?)endbfchar', dotAll: true)
      .allMatches(streams)
      .map((m) => m.group(1)!)
      .toList();
  final salida = StringBuffer();
  for (final bloque in mapas) {
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

    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*Tj').allMatches(streams)) {
      glifos(m.group(1)!);
    }
    for (final m in RegExp(r'\[(.*?)\]\s*TJ', dotAll: true)
        .allMatches(streams)) {
      for (final h in RegExp(r'<([0-9A-Fa-f]+)>').allMatches(m.group(1)!)) {
        glifos(h.group(1)!);
      }
    }
  }
  return salida.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la regla del período es compartida e ignora borrados', () {
    final all = _transactions();
    final current = recordsForPeriod(
      transactions: all,
      period: ReportPeriod.month,
      year: 2026,
      month: 6,
    );
    expect(current.map((t) => t.id), ['s1', 'e1', 'e2', 'e3']);

    final previous = previousMonthRecordsForPeriod(
      transactions: all,
      period: ReportPeriod.month,
      year: 2026,
      month: 6,
    );
    expect(previous.map((t) => t.id), ['s0', 'e0']);
  });

  test('PDF y Excel repiten la conclusión con las mismas cifras', () async {
    final all = _transactions();
    final current = recordsForPeriod(
      transactions: all,
      period: ReportPeriod.month,
      year: 2026,
      month: 6,
    );
    final previous = previousMonthRecordsForPeriod(
      transactions: all,
      period: ReportPeriod.month,
      year: 2026,
      month: 6,
    );
    final inYear = all.where((t) => !t.deleted && t.date.year == 2026).toList();
    final insights = const ReportInsightsService().build(
      now: DateTime.now(),
      current: current,
      previousMonth: previous,
      yearRecords: inYear,
      year: 2026,
      month: 6,
      crops: _crops(),
      l10n: _es,
      money: (v) => formatMoneyLabel(v, 'COP', locale: 'es_CO'),
    );
    expect(insights, isNotEmpty, reason: 'el fixture debe producir conclusión');

    final pdf = _norm(_pdfText(await _pdf(all)));
    final book = Excel.decodeBytes(_excel(all));
    final resumen = _norm(_excelText(book.tables[_es.excelSheetSummary]!));

    expect(pdf, contains(_norm(_es.insightsTitle)), reason: 'falta en el PDF');
    expect(resumen, contains(_norm(_es.insightsTitle)), reason: 'falta en Excel');
    for (final insight in insights) {
      expect(pdf, contains(_norm(insight.text)),
          reason: 'el PDF calla una conclusión de Reportes: ${insight.text}');
      expect(resumen, contains(_norm(insight.text)),
          reason: 'el Excel calla una conclusión de Reportes: ${insight.text}');
    }
  });

  test('el Resumen del Excel nombra compradores y proveedores reales', () {
    final book = Excel.decodeBytes(_excel(_transactions()));
    final resumen = _excelText(book.tables[_es.excelSheetSummary]!);
    expect(resumen, contains(_es.topClientsTitle));
    expect(resumen, contains(_es.topProvidersTitle));
    expect(resumen, contains('Comprador Andino'));
    expect(resumen, contains('Proveedor Verde'));
    expect(resumen, contains('Cuadrilla Norte'));
    expect(resumen, isNot(contains('No debe aparecer')));
  });

  test('el PDF dice «No hay recomendaciones» donde hoy calla', () async {
    final pdf = _norm(_pdfText(await _pdf(const [])));
    expect(pdf, contains(_norm(_es.reportNoRecommendations)),
        reason: 'el PDF es lo que se comparte: no puede callar el vacío');
    expect(pdf, contains(_norm(_es.insightsTitle)));
  });
}
