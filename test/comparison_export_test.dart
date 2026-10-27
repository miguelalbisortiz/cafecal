import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// El comparativo de período tiene que llegar al Excel y al PDF con la misma
/// cifra y el mismo criterio que la pantalla.
AppLocalizations get _es => stringsFor('es');

FarmSettings get _settings =>
    const FarmSettings(farmName: 'Finca Test', currency: 'COP');

Transaction _tx({
  required TransactionType type,
  required double amount,
  required DateTime date,
}) =>
    Transaction(
      id: '${type.name}-$amount-${date.toIso8601String()}',
      type: type,
      category: type.isExpense ? 'fertilizante' : 'venta_cafe',
      amount: amount,
      date: date,
      createdAt: date,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ExcelExportService();

  dynamic cv(Data? cell) {
    final v = cell?.value;
    if (v == null) return null;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) return v.value.text;
    return null;
  }

  final transactions = [
    // Mes anterior.
    _tx(
        type: TransactionType.income,
        amount: 2000,
        date: DateTime(2026, 9, 5)),
    _tx(
        type: TransactionType.expense,
        amount: 800,
        date: DateTime(2026, 9, 6)),
    // Mes actual.
    _tx(
        type: TransactionType.income,
        amount: 3000,
        date: DateTime(2026, 10, 10)),
    _tx(
        type: TransactionType.expense,
        amount: 1000,
        date: DateTime(2026, 10, 11)),
  ];

  test('Excel: el Resumen trae el comparativo con la cifra de antes', () {
    final bytes = Uint8List.fromList(service.buildReport(
      settings: _settings,
      transactions: transactions,
      crops: const [],
      year: 2026,
      month: 10,
      period: ReportPeriod.month,
      periodName: 'Octubre 2026',
      l10n: _es,
    ));
    final rows = Excel.decodeBytes(bytes).tables['Resumen']!.rows;

    final idx = rows.indexWhere(
        (r) => cv(r[0]) == 'Comparado con el mes anterior');
    expect(idx, greaterThan(0), reason: 'falta el encabezado del comparativo');

    final header = rows[idx + 1];
    expect(cv(header[1]), 'Anterior');
    expect(cv(header[2]), 'Actual');
    expect(cv(header[3]), 'Cambio');

    final incomeRow = rows[idx + 2];
    expect(cv(incomeRow[0]), 'Ingresos');
    expect(cv(incomeRow[1]), 2000.0);
    expect(cv(incomeRow[2]), 3000.0);
    expect(cv(incomeRow[3]), '+50%');

    final resultRow = rows[idx + 4];
    expect(cv(resultRow[0]), 'RESULTADO DEL PERÍODO');
    expect(cv(resultRow[1]), 1200.0);
    expect(cv(resultRow[2]), 2000.0);
    expect(cv(resultRow[3]), '+67%');
  });

  test('Excel: sin datos del período anterior no hay comparativo', () {
    final bytes = Uint8List.fromList(service.buildReport(
      settings: _settings,
      transactions: transactions.where((t) => t.date.month == 10).toList(),
      crops: const [],
      year: 2026,
      month: 10,
      period: ReportPeriod.month,
      periodName: 'Octubre 2026',
      l10n: _es,
    ));
    final rows = Excel.decodeBytes(bytes).tables['Resumen']!.rows;

    expect(
        rows.any((r) => (cv(r[0])?.toString() ?? '').startsWith('Comparado')),
        isFalse);
  });

  test('PDF: se genera con el comparativo sin romper el documento', () async {
    final bytes = await PdfExportService().buildReport(
      settings: _settings,
      transactions: transactions,
      crops: const [],
      year: 2026,
      month: 10,
      period: ReportPeriod.month,
      periodName: 'Octubre 2026',
      l10n: _es,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
