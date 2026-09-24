import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/currencies.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import 'alert_service.dart';
import 'pdf_export_service.dart' show ReportPeriod;
import 'recommendations.dart';
import 'report_harvest_metrics.dart';
import 'report_payroll_metrics.dart';
import 'week_utils.dart';

/// Exporta reportes a Excel (XLSX) y la plantilla de balance (CSV compatible
/// con Excel) manteniendo la misma lógica de cálculo que el PDF.
class ExcelExportService {
  // Colores para headers y formatos condicionales (usando ExcelColor)
  static final _excelBrown = ExcelColor.fromHexString('FF6D4C41');
  static final _excelGreenSoft = ExcelColor.fromHexString('FFE8F5E9');
  static final _excelRedSoft = ExcelColor.fromHexString('FFFFF3E0');
  static const _excelWhite = ExcelColor.white;
  static final _excelGreen = ExcelColor.fromHexString('FF1F5E3F');
  static final _excelRed = ExcelColor.fromHexString('FFB3261E');
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
    List<Harvest> harvests = const [],
    List<Sowing> sowings = const [],
  }) {
    final active = transactions.where((t) => !t.deleted).toList();

    double sum(List<Transaction> list, TransactionType type) =>
        list.where((t) => t.type == type).fold(0.0, (a, t) => a + t.amount);

    final now = DateTime.now();
    final periodTx = switch (period) {
      ReportPeriod.week => () {
        final range = weekRange(year, month ?? 1);
        return active
            .where((t) =>
                !t.date.isBefore(range.start) && !t.date.isAfter(range.end))
            .toList();
      }(),
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

    final periodHarvests = switch (period) {
      ReportPeriod.week => () {
        final range = weekRange(year, month ?? 1);
        return harvests
            .where((h) =>
                !h.date.isBefore(range.start) && !h.date.isAfter(range.end))
            .toList();
      }(),
      ReportPeriod.month => harvests
          .where((h) =>
              h.date.year == year && h.date.month == (month ?? now.month))
          .toList(),
      ReportPeriod.year =>
        harvests.where((h) => h.date.year == year).toList(),
      ReportPeriod.yearToDate => harvests
          .where((h) =>
              h.date.year == year &&
              !h.date.isAfter(
                  year < now.year ? DateTime(year, 12, 31) : now))
          .toList(),
    };

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
        ratio: ratio,
        periodTx: periodTx,
        crops: crops,
        period: period,
        year: year,
        month: month);

    _cropsSheet(excel[l10n.excelSheetCrops],
        periodTx: periodTx, crops: crops, currency: currency, l10n: l10n);

    _movementsSheet(excel[l10n.excelSheetMovements],
        periodTx: periodTx,
        crops: crops,
        currency: currency,
        l10n: l10n);

    _harvestSheet(excel[l10n.excelSheetHarvests],
        periodTx: periodTx,
        periodHarvests: periodHarvests,
        crops: crops,
        sowings: sowings,
        harvests: harvests,
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
    String cell(String s, {bool formula = false}) {
      var out = s.replaceAll(';', ',').replaceAll('\r\n', ' ');
      if (!formula) out = _neutralizeFormula(out);
      return out;
    }

    // Evita inyección de fórmulas (H5): Excel ejecuta celdas que arrancan
    // con = + @ (y con - si no es un número). Las fórmulas internas del
    // template se marcan con formula:true y se preservan.
    void line(List<String> cols, {Set<int> formulaCols = const {}}) => buf
        .write('${cols.asMap().entries.map((e) => cell(e.value,
                formula: formulaCols.contains(e.key))).join(';')}\r\n');

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
    line([l10n.balanceTotalAssets, '=SUM(B5:B10)'], formulaCols: {1});
    line([]);
    line([l10n.balanceLiabilitiesTitle]);
    line([l10n.balanceRowLoans]);
    line([l10n.balanceRowPayables]);
    line([l10n.balanceRowTaxes]);
    line([l10n.balanceTotalLiabilities, '=SUM(B14:B16)'], formulaCols: {1});
    line([]);
    line([l10n.balanceEquityTitle]);
    line([l10n.balanceRowCapital]);
    line([l10n.balanceRowAccumulated]);
    line([
      l10n.balanceRowNetIncome(year),
      _decimal(utilidad),
    ]);
    line([l10n.balanceTotalEquity, '=SUM(B20:B22)'], formulaCols: {1});
    line([]);
    line([l10n.balanceCheckLabel, l10n.balanceCheckFormula],
        formulaCols: {1});
    line([]);
    line([l10n.balanceNote]);
    return Uint8List.fromList(
        [0xEF, 0xBB, 0xBF, ...utf8.encode(buf.toString())]);
  }

  String _decimal(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Helpers de estilo ──

  void _styleHeaderRow(Sheet sheet, int rowIdx, int colCount, ExcelColor bgColor) {
    for (var c = 0; c < colCount; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
      cell.cellStyle = CellStyle(
        backgroundColorHex: bgColor,
        fontColorHex: _excelWhite,
        bold: true,
        fontSize: 11,
      );
    }
  }

  void _applyCurrencyFormat(
      Sheet sheet, String currency, int col, int fromRow, int toRow) {
    final info = currencyInfo(currency);
    final decimals = info.decimals;
    final fmt = decimals > 0
        ? '#,##0.${'0' * decimals}'
        : '#,##0';
    final numFmt = NumFormat.custom(formatCode: fmt);
    for (var r = fromRow; r <= toRow; r++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
      if (cell.value is DoubleCellValue || cell.value is IntCellValue) {
        cell.cellStyle = CellStyle(numberFormat: numFmt);
      }
    }
  }

  void _applyConditionalColor(Sheet sheet, int col, int fromRow, int toRow) {
    for (var r = fromRow; r <= toRow; r++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
      final val = cell.value;
      if (val is DoubleCellValue) {
        cell.cellStyle = CellStyle(
          fontColorHex: val.value >= 0 ? _excelGreen : _excelRed,
          bold: true,
          fontSize: 10,
        );
      }
    }
  }

  void _styleTableHeader(Sheet sheet, int rowIdx, int colCount) {
    for (var c = 0; c < colCount; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
      cell.cellStyle = CellStyle(
        backgroundColorHex: _excelBrown,
        fontColorHex: _excelWhite,
        bold: true,
        fontSize: 10,
      );
    }
  }

  // ── Fin helpers ──

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
    required List<Transaction> periodTx,
    required List<Crop> crops,
    required ReportPeriod period,
    required int year,
    int? month,
  }) {
    void row(List<CellValue?> cols) => sheet.appendRow(cols);

    row([TextCellValue(settings.farmName)]);
    row([TextCellValue(l10n.pdfIncomeStatement(periodName))]);
    row([
      TextCellValue(l10n.pdfGeneratedOn(
          DateTime.now().toIso8601String().split('T').first, currency)),
    ]);
    row([null, null, null]);

    // ── Header de ingresos ──
    row([
      TextCellValue(l10n.pdfIncomesHeader),
      null,
      DoubleCellValue(incomes),
    ]);
    _styleHeaderRow(sheet, 4, 3, _excelBrown);
    for (final e in incomeTotals.entries) {
      row([
        TextCellValue('    ${l10n.incomeCategory(e.key)}'),
        TextCellValue(_pctOf(e.value, incomes)),
        DoubleCellValue(e.value),
      ]);
    }
    row([null, null, null]);
    // ── Header de gastos ──
    row([
      TextCellValue(l10n.pdfExpensesHeader),
      null,
      DoubleCellValue(-expenses),
    ]);
    _styleHeaderRow(sheet, 4 + incomeTotals.length + 1, 3, _excelBrown);
    for (final e in expenseTotals.entries) {
      row([
        TextCellValue('    ${l10n.expenseCategory(e.key)}'),
        TextCellValue(_pctOf(e.value, expenses)),
        DoubleCellValue(-e.value),
      ]);
    }
    row([null, null, null]);
    // ── Resultado ──
    row([
      TextCellValue(l10n.resultPeriodLabel),
      null,
      DoubleCellValue(balance),
    ]);
    final resultRowIdx = 5 + incomeTotals.length + 1 + expenseTotals.length + 1;
    _styleHeaderRow(sheet, resultRowIdx, 3,
        balance >= 0 ? _excelGreenSoft : _excelRedSoft);

    row([
      TextCellValue(l10n.marginLabel),
      TextCellValue(margen != null ? _pctOf(margen, 1) : '—'),
      null,
    ]);
    row([
      TextCellValue(l10n.ratioLabel),
      TextCellValue(ratio != null ? _pctOf(ratio, 1) : '—'),
      null,
    ]);

    // Formato de moneda en columna C
    _applyCurrencyFormat(sheet, currency, 2, 4, 4 + incomeTotals.length);
    _applyCurrencyFormat(sheet, currency, 2,
        6 + incomeTotals.length, 6 + incomeTotals.length + expenseTotals.length);
    _applyCurrencyFormat(sheet, currency, 2, resultRowIdx, resultRowIdx);

    // ── Ingresos y gastos por mes (períodos multi-mes: anual/año hasta hoy) ──
    if (period == ReportPeriod.year || period == ReportPeriod.yearToDate) {
      final now = DateTime.now();
      final lastMonth =
          (period == ReportPeriod.year || year < now.year) ? 12 : now.month;
      final incByMonth = List<double>.filled(lastMonth + 1, 0);
      final expByMonth = List<double>.filled(lastMonth + 1, 0);
      for (final t in periodTx) {
        if (t.date.month < 1 || t.date.month > lastMonth) continue;
        if (t.type.isExpense) {
          expByMonth[t.date.month] += t.amount;
        } else {
          incByMonth[t.date.month] += t.amount;
        }
      }

      row([null, null, null, null]);
      row([TextCellValue(l10n.excelMonthlyTitle)]);
      _styleHeaderRow(sheet, sheet.maxRows - 1, 4, _excelBrown);
      row([
        TextCellValue(l10n.segMonth),
        TextCellValue(l10n.pdfIncomesHeader),
        TextCellValue(l10n.pdfExpensesHeader),
        TextCellValue(l10n.excelColBalance),
      ]);
      _styleTableHeader(sheet, sheet.maxRows - 1, 4);
      final monthFrom = sheet.maxRows;
      for (var m = 1; m <= lastMonth; m++) {
        row([
          TextCellValue(l10n.monthFull[m - 1]),
          DoubleCellValue(incByMonth[m]),
          DoubleCellValue(expByMonth[m]),
          DoubleCellValue(incByMonth[m] - expByMonth[m]),
        ]);
      }
      row([
        TextCellValue(l10n.jornalTotalLabel),
        DoubleCellValue(incomes),
        DoubleCellValue(expenses),
        DoubleCellValue(balance),
      ]);
      final monthTo = sheet.maxRows - 1;
      for (var c = 1; c <= 3; c++) {
        _applyCurrencyFormat(sheet, currency, c, monthFrom, monthTo);
      }
      final mInfo = currencyInfo(currency);
      final mFmt = mInfo.decimals > 0
          ? '#,##0.${'0' * mInfo.decimals}'
          : '#,##0';
      final mNumFmt = NumFormat.custom(formatCode: mFmt);
      // Balance por mes en verde/rojo conservando el formato numérico.
      for (var r = monthFrom; r < monthTo; r++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
        final val = cell.value;
        if (val is DoubleCellValue) {
          cell.cellStyle = CellStyle(
            numberFormat: mNumFmt,
            fontColorHex: val.value >= 0 ? _excelGreen : _excelRed,
            bold: true,
            fontSize: 10,
          );
        }
      }
      // Fila Total: fondo marrón + números con formato.
      for (var c = 0; c < 4; c++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: monthTo));
        cell.cellStyle = c == 0
            ? CellStyle(
                backgroundColorHex: _excelBrown,
                fontColorHex: _excelWhite,
                bold: true,
                fontSize: 10,
              )
            : CellStyle(
                backgroundColorHex: _excelBrown,
                fontColorHex: _excelWhite,
                bold: true,
                fontSize: 10,
                numberFormat: mNumFmt,
              );
      }
    }

    // ── Gastos por categoría y cultivo (cruce) ──
    final expenseTx = periodTx.where((t) => t.type.isExpense).toList();
    if (expenseTx.isNotEmpty) {
      final nameById = {for (final c in crops) c.id: c.name};
      final byCatCrop = <String, Map<String?, double>>{};
      for (final t in expenseTx) {
        final byCrop =
            byCatCrop.putIfAbsent(t.category, () => <String?, double>{});
        byCrop[t.cropId] = (byCrop[t.cropId] ?? 0) + t.amount;
      }
      row([null, null, null]);
      row([TextCellValue(l10n.excelCrossExpensesTitle)]);
      _styleHeaderRow(sheet, sheet.maxRows - 1, 3, _excelBrown);
      row([
        TextCellValue(l10n.pdfColCategory),
        TextCellValue(l10n.pdfColCrop),
        TextCellValue(l10n.pdfColAmount),
      ]);
      _styleTableHeader(sheet, sheet.maxRows - 1, 3);
      final crossFrom = sheet.maxRows;
      // Categorías en el mismo orden (mayor a menor) del desglose superior.
      for (final cat in expenseTotals.keys) {
        final byCrop = byCatCrop[cat];
        if (byCrop == null) continue;
        final sorted = byCrop.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final e in sorted) {
          row([
            TextCellValue(l10n.expenseCategory(cat)),
            TextCellValue(e.key == null
                ? l10n.cropUnspecified
                : (nameById[e.key] ?? e.key!)),
            DoubleCellValue(e.value),
          ]);
        }
      }
      _applyCurrencyFormat(sheet, currency, 2, crossFrom, sheet.maxRows - 1);
    }

    // ── Nómina del período (solo con gastos de mano de obra) ──
    final payroll = const ReportPayrollMetrics().payroll(periodTx);
    if (!payroll.isEmpty) {
      row([null, null, null]);
      row([TextCellValue(l10n.reportPayrollSection)]);
      _styleHeaderRow(sheet, sheet.maxRows - 1, 3, _excelBrown);
      row([
        TextCellValue(l10n.reportPayrollWorker),
        TextCellValue(l10n.reportPayrollDays),
        TextCellValue(l10n.reportPayrollSubtotal),
      ]);
      _styleTableHeader(sheet, sheet.maxRows - 1, 3);
      final payrollFrom = sheet.maxRows;
      for (final r in payroll.rows) {
        row([
          TextCellValue(
              r.provider.isEmpty ? l10n.reportPayrollUnnamed : r.provider),
          r.days > 0 ? DoubleCellValue(r.days) : TextCellValue('—'),
          DoubleCellValue(r.subtotal),
        ]);
      }
      _applyCurrencyFormat(sheet, currency, 2, payrollFrom, sheet.maxRows - 1);
      row([
        TextCellValue(l10n.reportPayrollTotal),
        null,
        DoubleCellValue(payroll.total),
      ]);
      _applyCurrencyFormat(
          sheet, currency, 2, sheet.maxRows - 1, sheet.maxRows - 1);
      row([TextCellValue(
          l10n.reportPayrollEmployees(payroll.distinctEmployees))]);
    }

    // ── Caja menor por mes (solo con monto configurado) ──
    final cashRows = const ReportPayrollMetrics().cashBoxByMonth(
      periodTx: periodTx,
      budget: settings.cajaMenorMensual,
      period: period,
      year: year,
      month: month,
    );
    if (cashRows.isNotEmpty) {
      row([null, null, null]);
      row([TextCellValue(l10n.cashBoxTitle)]);
      _styleHeaderRow(sheet, sheet.maxRows - 1, 6, _excelBrown);
      row([
        TextCellValue(l10n.segMonth),
        TextCellValue(l10n.reportCashBoxBudget),
        TextCellValue(l10n.cashBoxLabor),
        TextCellValue(l10n.cashBoxExtras),
        TextCellValue(l10n.jornalTotalLabel),
        TextCellValue(l10n.reportCashBoxBalance),
      ]);
      _styleTableHeader(sheet, sheet.maxRows - 1, 6);
      final multiYear = cashRows.map((r) => r.year).toSet().length > 1;
      final cashFrom = sheet.maxRows;
      for (final r in cashRows) {
        row([
          TextCellValue(multiYear
              ? '${l10n.monthFull[r.month - 1]} ${r.year}'
              : l10n.monthFull[r.month - 1]),
          DoubleCellValue(r.budget),
          DoubleCellValue(r.labor),
          DoubleCellValue(r.extras),
          DoubleCellValue(r.total),
          DoubleCellValue(r.balance),
        ]);
      }
      final cashTo = sheet.maxRows - 1;
      for (var c = 1; c <= 5; c++) {
        _applyCurrencyFormat(sheet, currency, c, cashFrom, cashTo);
      }
      // Saldo en verde/rojo conservando el formato numérico.
      final info = currencyInfo(currency);
      final fmt = info.decimals > 0 ? '#,##0.${'0' * info.decimals}' : '#,##0';
      final numFmt = NumFormat.custom(formatCode: fmt);
      for (var r = cashFrom; r <= cashTo; r++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r));
        final val = cell.value;
        if (val is DoubleCellValue) {
          cell.cellStyle = CellStyle(
            numberFormat: numFmt,
            fontColorHex: val.value >= 0 ? _excelGreen : _excelRed,
            bold: true,
            fontSize: 10,
          );
        }
      }
    }

    sheet.setColumnWidth(0, 42);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 16);
  }

  void _cropsSheet(
    Sheet sheet, {
    required List<Transaction> periodTx,
    required List<Crop> crops,
    required String currency,
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
    _styleTableHeader(sheet, 0, 6);
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
    const startRow = 1;
    var r = startRow;
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
      // Colorear fila por ROI
      final roiNum = roi == '—' ? 0.0 : double.tryParse(roi.replaceAll('%', '')) ?? 0;
      if (roiNum != 0) {
        final bgColor = roiNum > 0 ? _excelGreenSoft : _excelRedSoft;
        for (var c = 0; c < 6; c++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              .cellStyle = CellStyle(backgroundColorHex: bgColor);
        }
      }
      r++;
    }
    // Formato de moneda en columnas de montos
    _applyCurrencyFormat(sheet, currency, 2, startRow, r - 1);
    _applyCurrencyFormat(sheet, currency, 3, startRow, r - 1);
    _applyCurrencyFormat(sheet, currency, 4, startRow, r - 1);
    // Color condicional en columna resultado
    _applyConditionalColor(sheet, 4, startRow, r - 1);

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
      TextCellValue(l10n.excelColCurrency),
      TextCellValue(l10n.pdfColAmount),
      TextCellValue(l10n.excelColQty),
      TextCellValue(l10n.excelColUnit),
      TextCellValue(l10n.excelColPricePerUnit),
      TextCellValue(l10n.excelColClient),
      TextCellValue(l10n.excelColProvider),
    ]);
    _styleTableHeader(sheet, 0, 12);
    final nameById = {for (final c in crops) c.id: c.name};
    const startRow = 1;
    var r = startRow;
    for (final t in periodTx) {
      final cropName = t.cropId == null
          ? l10n.cropUnspecified
          : (nameById[t.cropId] ?? t.cropId!);
      final pricePerUnit = (t.quantity != null && t.quantity! > 0)
          ? DoubleCellValue(t.amount / t.quantity!)
          : null;
      final unitLabel = t.unit == null
          ? null
          : switch (t.unit!) {
              'kg' => TextCellValue(l10n.unitKg),
              'lb' => TextCellValue(l10n.unitLb),
              'arroba' => TextCellValue(l10n.unitArroba),
              'saco' => TextCellValue(l10n.unitSaco),
              'carga' => TextCellValue(l10n.unitCarga),
              'racimo' => TextCellValue(l10n.unitRacimo),
              'cajon' => TextCellValue(l10n.unitCajon),
              _ => TextCellValue(t.unit!),
            };
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
        TextCellValue(t.currency),
        DoubleCellValue(t.type.isExpense ? -t.amount : t.amount),
        t.quantity == null ? null : DoubleCellValue(t.quantity!),
        unitLabel,
        pricePerUnit,
        t.client == null ? null : TextCellValue(t.client!),
        t.provider == null ? null : TextCellValue(t.provider!),
      ]);
      // Color condicional en columna monto
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r));
      final isExp = t.type.isExpense;
      cell.cellStyle = CellStyle(
        fontColorHex: isExp ? _excelRed : _excelGreen,
        bold: true,
      );
      r++;
    }
    // Formato de moneda en columna monto
    _applyCurrencyFormat(sheet, currency, 6, startRow, r - 1);

    for (var i = 0; i < 12; i++) {
      sheet.setColumnWidth(i, i == 3 ? 40 : (i == 5 ? 10 : 18));
    }
  }

  // ---- Nivel 2: hoja de cosechas (totales, costos, rendimiento, conciliación, "Qué hacer") ----

  void _harvestSheet(
    Sheet sheet, {
    required List<Transaction> periodTx,
    required List<Harvest> periodHarvests,
    required List<Crop> crops,
    required List<Sowing> sowings,
    required List<Harvest> harvests,
    required String currency,
    required AppLocalizations l10n,
  }) {
    void row(List<CellValue?> cols) => sheet.appendRow(cols);
    const metrics = ReportHarvestMetrics();
    final cropById = {for (final c in crops) c.id: c};

    row([TextCellValue(l10n.reportHarvestSection)]);
    if (periodHarvests.isEmpty) {
      row([TextCellValue(l10n.reportNoHarvestData)]);
      sheet.setColumnWidth(0, 42);
      return;
    }

    // Totales por cultivo.
    row([null, null, null]);
    row([TextCellValue(l10n.reportHarvestedTotal)]);
    row([
      TextCellValue(l10n.pdfColCrop),
      TextCellValue(l10n.pdfColAmount),
      TextCellValue(l10n.reportHarvestKg),
    ]);
    final byCrop = metrics.totalsByCrop(periodHarvests, crops);
    for (final c in byCrop) {
      row([
        TextCellValue(c.name),
        TextCellValue('${_decimal(c.amount)} ${c.unit}'),
        DoubleCellValue(c.kg),
      ]);
    }

    // Por destino.
    row([null, null, null]);
    row([TextCellValue(l10n.reportHarvestDestinations)]);
    final byDestination = metrics.totalsByDestination(periodHarvests);
    for (final e in byDestination.entries) {
      row([
        TextCellValue(_destinationLabel(e.key, l10n)),
        DoubleCellValue(e.value),
      ]);
    }

    // Costo de recogida por kg.
    final pickupKg = metrics.pickupCostPerKg(periodTx, periodHarvests);
    if (pickupKg != null) {
      row([null, null, null]);
      row([
        TextCellValue(l10n.reportPickupCostPerKg),
        DoubleCellValue(pickupKg),
      ]);
    }

    // Costo total por kg / inversión acumulada y rendimiento por cultivo.
    row([null, null, null]);
    for (final c in byCrop) {
      final crop = c.cropId == null ? null : cropById[c.cropId];
      if (crop == null) continue;
      final cropHarvests =
          periodHarvests.where((h) => h.cropId == crop.id).toList();
      final cropExpenses =
          periodTx.where((t) => t.cropId == crop.id).toList();
      final hasResiembra = sowings.any(
          (s) => s.cropId == crop.id && s.kind == SowingKind.resiembra);

      if (crop.phase == CropPhase.establecimiento ||
          crop.phase == CropPhase.renovacion) {
        final inv = metrics.accumulatedInvestment(cropExpenses);
        row([
          TextCellValue('${crop.name} — ${l10n.reportInvestmentEstablecimiento}'),
          DoubleCellValue(inv),
        ]);
      } else {
        final totalKg = metrics.totalCostPerKg(crop, cropExpenses, cropHarvests);
        if (totalKg != null) {
          row([
            TextCellValue('${crop.name} — ${l10n.reportTotalCostPerKg}'),
            DoubleCellValue(totalKg),
          ]);
        }
        final yieldArea = metrics.yieldPerArea(cropHarvests, crop.areaHa);
        if (yieldArea != null) {
          row([
            TextCellValue('${crop.name} — ${l10n.reportYieldPerArea}'
                '${hasResiembra ? ' ${l10n.reportApprox}' : ''}'),
            DoubleCellValue(yieldArea),
          ]);
        }
        final yieldPlant = metrics.yieldPerPlant(cropHarvests, crop.livePlants);
        if (yieldPlant != null) {
          row([
            TextCellValue('${crop.name} — ${l10n.reportYieldPerPlant}'
                '${hasResiembra ? ' ${l10n.reportApprox}' : ''}'),
            DoubleCellValue(yieldPlant),
          ]);
        }
      }
    }

    // Personal y kilos por cosecha (si se registraron).
    final staffHarvests = periodHarvests
        .where((h) => h.workers != null || h.equivalentKg != null)
        .toList();
    if (staffHarvests.isNotEmpty) {
      row([null, null, null]);
      row([
        TextCellValue(l10n.reportHarvestStaff),
        TextCellValue(l10n.harvestWorkersLabel),
        TextCellValue(l10n.reportEquivalentKg),
      ]);
      _styleTableHeader(sheet, sheet.maxRows - 1, 3);
      for (final h in staffHarvests) {
        final cropName = h.cropId == null
            ? l10n.cropUnspecified
            : (cropById[h.cropId]?.name ?? h.cropId!);
        row([
          TextCellValue(
              '${_fmtDate(h.date)} · $cropName'),
          h.workers != null
              ? IntCellValue(h.workers!)
              : TextCellValue('—'),
          h.equivalentKg != null
              ? DoubleCellValue(h.equivalentKg!)
              : TextCellValue('—'),
        ]);
      }
      _applyCurrencyFormat(sheet, currency, 2, sheet.maxRows - staffHarvests.length,
          sheet.maxRows - 1);
    }

    // Vendido vs cosechado.
    row([null, null, null]);
    row([TextCellValue(l10n.reportSoldVsHarvested)]);
    final soldVs = metrics.soldVsHarvested(
        periodTx, periodHarvests, crops, DateTime.now());
    if (soldVs.isEmpty) {
      row([TextCellValue(l10n.reportNoHarvestData)]);
    }
    for (final s in soldVs) {
      row([
        TextCellValue('${s.name} — ${l10n.reportSoldKg}'),
        DoubleCellValue(s.soldKg),
      ]);
      row([
        TextCellValue('${s.name} — ${l10n.reportHarvestedKg}'),
        DoubleCellValue(s.harvestedKg),
      ]);
    }

    // "Qué hacer" derivado del motor de reglas.
    row([null, null, null]);
    row([TextCellValue(l10n.reportWhatsNext)]);
    final alerts = const AlertService().evaluate(
      periodTx,
      crops,
      l10n,
      harvests: harvests,
      sowings: sowings,
    );
    final recommendations = const RecommendationService().derive(alerts, 4);
    if (recommendations.isEmpty) {
      row([TextCellValue(l10n.reportNoRecommendations)]);
    }
    for (var i = 0; i < recommendations.length; i++) {
      row([
        TextCellValue('${i + 1}. ${recommendations[i].title}'),
      ]);
      row([
        TextCellValue(recommendations[i].message),
      ]);
    }

    for (var i = 0; i < 3; i++) {
      sheet.setColumnWidth(i, i == 0 ? 46 : (i == 1 ? 20 : 18));
    }
  }

  String _destinationLabel(HarvestDestination d, AppLocalizations l10n) =>
      switch (d) {
        HarvestDestination.vendido => l10n.harvestDstVendido,
        HarvestDestination.almacenado => l10n.harvestDstAlmacenado,
        HarvestDestination.perdida => l10n.harvestDstPerdida,
      };

  String _pctOf(double part, double total) {
    if (total <= 0) return '—';
    final v = part / total * 100;
    return v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
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

/// Antepone una comilla simple cuando la celda arranca con un disparador de
/// fórmula de Excel (=, +, @ o un `-` no numérico) para impedir inyección CSV.
String _neutralizeFormula(String s) {
  if (s.isEmpty) return s;
  final first = s[0];
  final looksLikeNumber = first == '-' &&
      s.length > 1 &&
      (s.codeUnitAt(1) >= 0x30 && s.codeUnitAt(1) <= 0x39 || s[1] == '.');
  if (first == '=' ||
      first == '+' ||
      first == '@' ||
      (first == '-' && !looksLikeNumber)) {
    return "'$s";
  }
  return s;
}