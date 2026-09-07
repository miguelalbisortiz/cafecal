// Herramienta local: genera los PDF de reporte (septiembre 2026 y anual 2026)
// desde el respaldo local `reportes/datos.json` (exportado con web/backup.html).
//   flutter test tool/local_report_tool.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

void main() {
  test('genera PDFs desde datos locales (datos.json)', () async {
    final source = File('reportes/datos.json').readAsStringSync();
    final data = jsonDecode(source) as Map<String, dynamic>;

    final txs = (jsonDecode(data['transactions_v1'] as String) as List)
        .map((e) => Transaction.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final crops =
        (jsonDecode(data['crops_v1'] as String) as List)
            .map((e) => Crop.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
    final settings = FarmSettings.fromJson(
        jsonDecode(data['settings_v1'] as String) as Map<String, dynamic>);

    final l10n = stringsFor('es');
    const year = 2026;
    final month = DateTime.now().month;
    final svc = PdfExportService();
    Directory('reportes').createSync(recursive: true);

    stderr.writeln(
        '[tool] ${txs.length} transacciones · ${crops.length} cultivos · '
        'finca "${settings.farmName}" · ${settings.currency} · mes $month');

    final monthly = await svc.buildReport(
      settings: settings,
      transactions: txs,
      crops: crops,
      year: year,
      month: month,
      period: ReportPeriod.month,
      periodName: l10n.reportPeriodMonth(l10n.monthFull[month - 1], year),
      l10n: l10n,
    );
    File('reportes/local-$year-mensual.pdf')
        .writeAsBytesSync(monthly, flush: true);

    final annual = await svc.buildReport(
      settings: settings,
      transactions: txs,
      crops: crops,
      year: year,
      period: ReportPeriod.year,
      periodName: l10n.yearLabel(year),
      l10n: l10n,
    );
    File('reportes/local-$year-anual.pdf')
        .writeAsBytesSync(annual, flush: true);

    stderr.writeln('[tool] OK: PDFs generados en "reportes/"');
  });
}