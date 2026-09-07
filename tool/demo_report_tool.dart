// Demo: genera los PDF de reporte (mes y año) con datos de ejemplo para
// revisar el formato. Se ejecuta con:
//   flutter test tool/demo_report_tool.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

Transaction _t({
  required String id,
  required TransactionType type,
  required String category,
  required double amount,
  required int month,
  required int day,
  String? cropId,
}) {
  return Transaction(
    id: id,
    cropId: cropId,
    type: type,
    category: category,
    amount: amount,
    date: DateTime(2026, month, day),
    createdAt: DateTime(2026, month, day),
  );
}

void main() {
  test('genera PDFs demo (septiembre + anual 2026)', () async {
    const settings = FarmSettings(
      farmName: 'Finca El Progreso',
      currency: 'COP',
      locale: 'es_CO',
    );
    const crops = [
      Crop(id: 'cafe', name: 'Café'),
      Crop(id: 'platano', name: 'Plátano'),
      Crop(id: 'otro', name: 'Otro'),
    ];
    final list = <Transaction>[
      _t(id: 'a1', type: TransactionType.expense, category: 'siembra', amount: 1200000, month: 3, day: 5, cropId: 'cafe'),
      _t(id: 'a2', type: TransactionType.expense, category: 'fertilizante', amount: 850000, month: 4, day: 12, cropId: 'cafe'),
      _t(id: 'a3', type: TransactionType.expense, category: 'mano_obra', amount: 2000000, month: 5, day: 3, cropId: 'cafe'),
      _t(id: 'a4', type: TransactionType.expense, category: 'cosecha', amount: 1500000, month: 6, day: 20, cropId: 'cafe'),
      _t(id: 'a5', type: TransactionType.expense, category: 'transporte', amount: 600000, month: 7, day: 8, cropId: 'cafe'),
      _t(id: 'a6', type: TransactionType.expense, category: 'empaque', amount: 400000, month: 8, day: 15, cropId: 'cafe'),
      _t(id: 's1', type: TransactionType.income, category: 'venta_cafe', amount: 9000000, month: 5, day: 28, cropId: 'cafe'),
      _t(id: 's2', type: TransactionType.income, category: 'venta_cafe', amount: 12326000, month: 9, day: 16, cropId: 'cafe'),
      _t(id: 'p1', type: TransactionType.expense, category: 'mano_obra', amount: 800000, month: 9, day: 2, cropId: 'platano'),
      _t(id: 'p2', type: TransactionType.expense, category: 'transporte', amount: 1200000, month: 9, day: 10, cropId: 'platano'),
      _t(id: 'p3', type: TransactionType.income, category: 'venta_platano', amount: 3000000, month: 9, day: 20, cropId: 'platano'),
      _t(id: 'g1', type: TransactionType.expense, category: 'mantenimiento', amount: 350000, month: 9, day: 5, cropId: 'otro'),
    ];

    final l10n = stringsFor('es');
    TestWidgetsFlutterBinding.ensureInitialized();
    final svc = PdfExportService();
    Directory('reportes').createSync(recursive: true);

    final sept = await svc.buildReport(
      settings: settings,
      transactions: list,
      crops: crops,
      year: 2026,
      month: 9,
      period: ReportPeriod.month,
      periodName: l10n.reportPeriodMonth(l10n.monthFull[8], 2026),
      l10n: l10n,
    );
    File('reportes/demo-2026-septiembre.pdf').writeAsBytesSync(sept, flush: true);

    final annual = await svc.buildReport(
      settings: settings,
      transactions: list,
      crops: crops,
      year: 2026,
      period: ReportPeriod.year,
      periodName: l10n.yearLabel(2026),
      l10n: l10n,
    );
    File('reportes/demo-2026-anual.pdf').writeAsBytesSync(annual, flush: true);

    stderr.writeln('[tool] OK: PDFs demo en "reportes/"');
  });
}