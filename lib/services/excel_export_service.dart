import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/currencies.dart';
import '../models/settings.dart';
import '../models/transaction.dart';
import 'pdf_export_service.dart' show ReportPeriod;

/// Exporta reportes a Excel (XLSX) y la plantilla de balance (CSV compatible
/// con Excel) manteniendo la misma lógica de cálculo que el PDF.
class ExcelExportService {
  /// Genera un XLSX con 3 hojas: Resumen, Por cultivo y Movimientos.
  /// Devuelve los bytes listos para guardar/compartir. Puro Dart (sin binding).
  List<int> buildReport({
    required FarmSettings settings,
    required List<Transaction> transactions,
    required List<Crop> crops,
    required int year,
    int? month,
    required ReportPeriod period,
    required String periodName,
    required AppLocalizations l10n,
  }) {
    final active = transactions.where((t) => !t.deleted).toList();

    double sum(List<Transaction> list, TransactionType type) =>
        list.where((t) => t.type == type).fold(0.0, (a, t) => a + t.amount);

    final now = DateTime.now();
    final periodTx = switch (period) {
      ReportPeriod.month => active
          .where(
              (t) => t.date.year == year && t.date.month == (month ?? now.month))
          .toList(),
      ReportPeriod.year => active.where((t) => t.date.year == year).toList(),
      ReportPeriod.yearToDate => active
          .where((t) =>
              t.date.year == year &&
              !t.date.isAfter(
                  year < now.year ? DateTime(year, 12, 31) : now))
          .toList(),
    };
    final expenses = sum(periodTx, TransactionType.expense);
    final incomes = sum(periodTx, TransactionType.income);
    final balance = incomes - expenses;

    final incomeTotals = _groupTotals(
        periodTx.where((t) => t.type == TransactionType.income).toList());
    final expenseTotals = _groupTotals(
        periodTx.where((t) => t.type == TransactionType.expense).toList());
    final margen = incomes > 0 ? (balance / incomes) * 100 : null;
    final ratio = incomes > 0 ? (expenses / incomes) * 100 : null;

    final currency = settings.currency;
    final excel = Excel.createExcel();
    excel.rename('Sheet1', l10n.excelSheetSummary);

    _summarySheet(excel[l10n.excelSheetSummary],
        settings: settings,
        periodName: periodName,
        currency: currency,
        l10n: l10n,
        incomes: incomes,
        incomeTotals: incomeTotals,
        expenses: expenses,
        expenseTotals: expenseTotals,
        balance: balance,
        margen: margen,
        ratio: ratio);

    _cropsSheet(excel[l10n.excelSheetCrops],
        periodTx: periodTx, crops: crops, l10n: l10n);

    _movementsSheet(excel[l10n.excelSheetMovements],
        periodTx: periodTx,
        crops: crops,
        currency: currency,
        l10n: l10n);

    final bytes =
        excel.save(fileName: '${l10n.pdfFileNamePrefix}_$year.xlsx');
    if (bytes == null) {
      throw StateError('Excel export returned null bytes');
    }
    return bytes;
  }

  /// Plantilla de balance contable en CSV (delimitador ';') que abre en Excel
  /// con totales por fórmula y la utilidad del ejercicio precargada.
  Uint8List buildBalanceTemplate({
    required FarmSettings settings,
    required List<Transaction> transactions,
    required int year,
    required String periodName,
    required AppLocalizations l10n,
  }) {
    final active = transactions.where((t) => !t.deleted).toList();
    final yearTx = active.where((t) => t.date.year == year).toList();
    final incomes = yearTx
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (a, t) => a + t.amount);
    final expenses = yearTx
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (a, t) => a + t.amount);
    final utilidad = incomes - expenses;

    final buf = StringBuffer();
    String cell(String s) => s.replaceAll(';', ',').replaceAll('\r\n', ' ');
    void line(List<String> cols) =>
        buf.write('${cols.map(cell).join(';')}\r\n');

    line([l10n.balanceTemplateTitle(periodName)]);
    line([
      l10n.balanceTemplateFarm(settings.farmName,
          DateTime.now().toIso8601String().split('T').first)
    ]);
    line([l10n.balanceAssetsTitle]);
    line([l10n.balanceRowCash]);
    line([l10n.balanceRowReceivables]);
    line([l10n.balanceRowInventory]);
    line([l10n.balanceRowMachinery]);
    line([l10n.balanceRowLand]);
    line([l10n.balanceRowOtherAssets]);
    line([l10n.balanceTotalAssets, '=SUM(B5:B10)']);
    line([]);
    line([l10n.balanceLiabilitiesTitle]);
    line([l10n.balanceRowLoans]);
    line([l10n.balanceRowPayables]);
    line([l10n.balanceRowTaxes]);
    line([l10n.balanceTotalLiabilities, '=SUM(B14:B16)']);
    line([]);
    line([l10n.balanceEquityTitle]);
    line([l10n.balanceRowCapital]);
    line([l10n.balanceRowAccumulated]);
    line([
      l10n.balanceRowNetIncome(year),
      _decimal(utilidad),
    ]);
    line([l10n.balanceTotalEquity, '=SUM(B20:B22)']);
    line([]);
    line([
      l10n.balanceCheckLabel,
      l10n.balanceCheckFormula,
    ]);
    line([]);
    line([l10n.balanceNote]);
    return Uint8List.fromList(
        [0xEF, 0xBB, 0xBF, ...utf8.encode(buf.toString())]);
  }

  String _decimal(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  void _summarySheet(
    Sheet sheet, {
    required FarmSettings settings,
    required String periodName,
    required String currency,
    required AppLocalizations l10n,
    required double incomes,
    required Map<String, double> incomeTotals,
    required double expenses,
    required Map<String, double> expenseTotals,
    required double balance,
    required double? margen,
    required double? ratio,
  }) {
    void row(List<CellValue?> cols) => sheet.appendRow(cols);

    row([TextCellValue(settings.farmName)]);
    row([TextCellValue(l10n.pdfIncomeStatement(periodName))]);
    row([
      TextCellValue(l10n.pdfGeneratedOn(
          DateTime.now().toIso8601String().split('T').first, currency)),
    ]);
    row([null, null, null]);

    row([
      TextCellValue(l10n.pdfIncomesHeader),
      IntCellValue(incomes.round()),
    ]);
    for (final e in incomeTotals.entries) {
      row([
        TextCellValue('    ${l10n.incomeCategory(e.key)}'),
        TextCellValue(_pctOf(e.value, incomes)),
        DoubleCellValue(e.value),
      ]);
    }
    row([null, null, null]);
    row([
      TextCellValue(l10n.pdfExpensesHeader),
      IntCellValue(-expenses.round()),
    ]);
    for (final e in expenseTotals.entries) {
      row([
        TextCellValue('    ${l10n.expenseCategory(e.key)}'),
        TextCellValue(_pctOf(e.value, expenses)),
        DoubleCellValue(-e.value),
      ]);
    }
    row([null, null, null]);
    row([
      TextCellValue(l10n.resultPeriodLabel),
      TextCellValue(_money(balance, currency)),
    ]);
    row([
      TextCellValue(l10n.marginLabel),
      TextCellValue(margen != null ? _pctOf(margen, 1) : '—'),
    ]);
    row([
      TextCellValue(l10n.ratioLabel),
      TextCellValue(ratio != null ? _pctOf(ratio, 1) : '—'),
    ]);

    sheet.setColumnWidth(0, 42);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 20);
  }

  void _cropsSheet(
    Sheet sheet, {
    required List<Transaction> periodTx,
    required List<Crop> crops,
    required AppLocalizations l10n,
  }) {
    sheet.appendRow([
      TextCellValue(l10n.pdfColCrop),
      TextCellValue(l10n.pdfColMov),
      TextCellValue(l10n.pdfColExpenses),
      TextCellValue(l10n.pdfColIncomes),
      TextCellValue(l10n.pdfColResult),
      TextCellValue(l10n.pdfColRoi),
    ]);
    final nameById = {for (final c in crops) c.id: c.name};
    final totals = <String?, _CropTotalRow>{
      null: _CropTotalRow(name: l10n.cropUnspecified),
    };
    for (final c in crops) {
      totals.putIfAbsent(c.id, () => _CropTotalRow(name: c.name));
    }
    for (final t in periodTx) {
      final row = totals.putIfAbsent(t.cropId, () {
        final name = t.cropId == null
            ? l10n.cropUnspecified
            : (nameById[t.cropId] ?? t.cropId!);
        return _CropTotalRow(name: name);
      });
      row.count++;
      if (t.type.isExpense) {
        row.expenses += t.amount;
      } else {
        row.incomes += t.amount;
      }
    }
    for (final row in totals.values.where(
        (r) => r.expenses > 0 || r.incomes > 0)) {
      final roi = row.expenses <= 0
          ? '—'
          : '${(((row.incomes - row.expenses) / row.expenses) * 100).toStringAsFixed(0)}%';
      sheet.appendRow([
        TextCellValue(row.name),
        IntCellValue(row.count),
        DoubleCellValue(row.expenses),
        DoubleCellValue(row.incomes),
        DoubleCellValue(row.incomes - row.expenses),
        TextCellValue(roi),
      ]);
    }
    for (var i = 0; i < 6; i++) {
      sheet.setColumnWidth(
          i, i == 0 ? 24 : (i == 5 ? 12 : 16));
    }
  }

  void _movementsSheet(
    Sheet sheet, {
    required List<Transaction> periodTx,
    required List<Crop> crops,
    required String currency,
    required AppLocalizations l10n,
  }) {
    sheet.appendRow([
      TextCellValue(l10n.pdfColDate),
      TextCellValue(l10n.pdfColType),
      TextCellValue(l10n.pdfColCategory),
      TextCellValue(l10n.pdfColDescription),
      TextCellValue(l10n.pdfColCrop),
      TextCellValue(l10n.pdfColAmount),
    ]);
    final nameById = {for (final c in crops) c.id: c.name};
    for (final t in periodTx) {
      final cropName = t.cropId == null
          ? l10n.cropUnspecified
          : (nameById[t.cropId] ?? t.cropId!);
      sheet.appendRow([
        TextCellValue(t.date.toIso8601String().split('T').first),
        TextCellValue(
            t.type.isExpense ? l10n.expenseTypeLabel : l10n.incomeTypeLabel),
        TextCellValue(
            t.type.isExpense
                ? l10n.expenseCategory(t.category)
                : l10n.incomeCategory(t.category)),
        TextCellValue(t.description),
        TextCellValue(cropName),
        DoubleCellValue(t.type.isExpense ? -t.amount : t.amount),
      ]);
    }
    for (var i = 0; i < 6; i++) {
      sheet.setColumnWidth(i, i == 3 ? 40 : 18);
    }
  }

  String _pctOf(double part, double total) {
    if (total <= 0) return '—';
    final v = part / total * 100;
    return v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  String _money(double value, String currency) {
    final info = currencyInfo(currency);
    final s = '${info.symbol}${value.abs().toStringAsFixed(info.decimals)}';
    return value < 0 ? '($s)' : s;
  }

  Map<String, double> _groupTotals(List<Transaction> list) {
    final totals = <String, double>{};
    for (final t in list) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }
}

class _CropTotalRow {
  final String name;
  int count = 0;
  double expenses = 0;
  double incomes = 0;

  _CropTotalRow({required this.name});
}