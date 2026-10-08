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
import 'crop_totals.dart';
import 'currency_totals.dart';
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

    // Totales del período por moneda: la fuente de verdad del encabezado.
    // Con una sola moneda se imprime la cifra de siempre; con dos o más
    // cada total va con su código, sin %, sin margen ni ratio.
    final periodTotals = PeriodCurrencyTotals.fromRecords(periodTx);

    final incomeGroups = groupAmountsByCurrency(
      periodTx.where((t) => t.type == TransactionType.income),
      keyOf: (t) => incomeGroupKey(t.category, t.cropId),
    );
    final expenseGroups = groupAmountsByCurrency(
      periodTx.where((t) => t.type == TransactionType.expense),
      keyOf: (t) => incomeGroupKey(t.category, t.cropId),
    );
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
        incomeGroups: incomeGroups,
        expenses: expenses,
        expenseGroups: expenseGroups,
        balance: balance,
        margen: margen,
        ratio: ratio,
        periodTotals: periodTotals,
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
  ///
  /// **Moneda mixta**: si el año toca más de una moneda no se imprime ninguna
  /// fórmula de total (sumar pesos con dólares daría un balance falso) y la
  /// utilidad del ejercicio sale una fila por moneda, cada una con su código.
  Uint8List buildBalanceTemplate({
    required FarmSettings settings,
    required List<Transaction> transactions,
    required int year,
    required String periodName,
    required AppLocalizations l10n,
  }) {
    final active = transactions.where((t) => !t.deleted).toList();
    final yearTx = active.where((t) => t.date.year == year).toList();
    final totals = PeriodCurrencyTotals.fromRecords(yearTx);
    final mixed = totals.isMixed;
    final currencies = totals.currencies.toList()..sort();
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
    //
    // Con moneda mixta no se emite **ninguna** fórmula: sería una celda que
    // suma monedas distintas al abrirla en Excel.
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
    if (mixed) {
      line([l10n.balanceTotalAssets]);
    } else {
      line([l10n.balanceTotalAssets, '=SUM(B5:B10)'], formulaCols: {1});
    }
    line([]);
    line([l10n.balanceLiabilitiesTitle]);
    line([l10n.balanceRowLoans]);
    line([l10n.balanceRowPayables]);
    line([l10n.balanceRowTaxes]);
    if (mixed) {
      line([l10n.balanceTotalLiabilities]);
    } else {
      line([l10n.balanceTotalLiabilities, '=SUM(B14:B16)'], formulaCols: {1});
    }
    line([]);
    line([l10n.balanceEquityTitle]);
    line([l10n.balanceRowCapital]);
    line([l10n.balanceRowAccumulated]);
    if (mixed) {
      // Una fila de utilidad por moneda: nunca una cifra que cruce monedas.
      for (final code in currencies) {
        line([
          '${l10n.balanceRowNetIncome(year)} · $code',
          _decimal(totals.resultOf(code)),
        ]);
      }
      line([l10n.balanceTotalEquity]);
    } else {
      line([
        l10n.balanceRowNetIncome(year),
        _decimal(utilidad),
      ]);
      line([l10n.balanceTotalEquity, '=SUM(B20:B22)'], formulaCols: {1});
    }
    line([]);
    if (mixed) {
      line([l10n.balanceCheckLabel]);
    } else {
      line([l10n.balanceCheckLabel, l10n.balanceCheckFormula],
          formulaCols: {1});
    }
    line([]);
    line([l10n.balanceNote]);
    if (mixed) {
      line([l10n.balanceMixedCurrencyNote(currencies.length)]);
    }
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
    required Map<String, Map<String, double>> incomeGroups,
    required double expenses,
    required Map<String, Map<String, double>> expenseGroups,
    required double balance,
    required double? margen,
    required double? ratio,
    required PeriodCurrencyTotals periodTotals,
    required List<Transaction> periodTx,
    required List<Crop> crops,
    required ReportPeriod period,
    required int year,
    int? month,
  }) {
    void row(List<CellValue?> cols) => sheet.appendRow(cols);

    // Con mezcla cada total sale moneda por moneda y sin %: el % sería
    // sobre un total que cruzaría monedas distintas.
    final mixedHeader = periodTotals.isMixed;

    /// Montos de un grupo con una sola moneda (solo se usa sin mezcla).
    double single(Map<String, double> amounts) => amounts.values.first;

    String byCurrency(Map<String, double> amounts, {bool negative = false}) =>
        byCurrencyText(
            negative
                ? {for (final e in amounts.entries) e.key: -e.value}
                : amounts,
            (v, c) => formatMoneyLabel(v, c));

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
      mixedHeader
          ? TextCellValue(byCurrency(periodTotals.incomes))
          : DoubleCellValue(incomes),
    ]);
    _styleHeaderRow(sheet, 4, 3, _excelBrown);
    for (final e in incomeGroups.entries) {
      row([
        TextCellValue('    ${l10n.incomeGroupLabel(e.key, crops)}'),
        mixedHeader ? null : TextCellValue(_pctOf(single(e.value), incomes)),
        mixedHeader
            ? TextCellValue(byCurrency(e.value))
            : DoubleCellValue(single(e.value)),
      ]);
    }
    row([null, null, null]);
    // ── Header de gastos ──
    row([
      TextCellValue(l10n.pdfExpensesHeader),
      null,
      mixedHeader
          ? TextCellValue(byCurrency(periodTotals.expenses, negative: true))
          : DoubleCellValue(-expenses),
    ]);
    _styleHeaderRow(sheet, 4 + incomeGroups.length + 1, 3, _excelBrown);
    for (final e in expenseGroups.entries) {
      row([
        TextCellValue('    ${l10n.expenseCategory(e.key)}'),
        mixedHeader ? null : TextCellValue(_pctOf(single(e.value), expenses)),
        mixedHeader
            ? TextCellValue(byCurrency(e.value, negative: true))
            : DoubleCellValue(-single(e.value)),
      ]);
    }
    row([null, null, null]);
    // ── Resultado ──
    row([
      TextCellValue(l10n.resultPeriodLabel),
      null,
      mixedHeader
          ? TextCellValue(byCurrency(periodTotals.results))
          : DoubleCellValue(balance),
    ]);
    final resultRowIdx = 5 + incomeGroups.length + 1 + expenseGroups.length + 1;
    final resultNegative = mixedHeader
        ? periodTotals.results.values.any((v) => v < 0)
        : balance < 0;
    _styleHeaderRow(sheet, resultRowIdx, 3,
        resultNegative ? _excelRedSoft : _excelGreenSoft);

    row([
      TextCellValue(l10n.marginLabel),
      TextCellValue(
          !mixedHeader && margen != null ? _pctOf(margen, 1) : '—'),
      null,
    ]);
    row([
      TextCellValue(l10n.ratioLabel),
      TextCellValue(!mixedHeader && ratio != null ? _pctOf(ratio, 1) : '—'),
      null,
    ]);
    if (mixedHeader) {
      row([
        TextCellValue(
            l10n.currencyMixedByCurrencyNote(periodTotals.currencies.length)),
      ]);
    }

    // Formato de moneda en columna C (las celdas de texto se ignoran)
    _applyCurrencyFormat(sheet, currency, 2, 4, 4 + incomeGroups.length);
    _applyCurrencyFormat(sheet, currency, 2,
        6 + incomeGroups.length, 6 + incomeGroups.length + expenseGroups.length);
    _applyCurrencyFormat(sheet, currency, 2, resultRowIdx, resultRowIdx);

    // ── Ingresos y gastos por mes (períodos multi-mes: anual/año hasta hoy) ──
    if (period == ReportPeriod.year || period == ReportPeriod.yearToDate) {
      final now = DateTime.now();
      final lastMonth =
          (period == ReportPeriod.year || year < now.year) ? 12 : now.month;
      // Monedas del período: con dos o más la serie sale mes × moneda,
      // porque sumar monedas distintas en una sola celda sería mentira.
      final seriesCodes = {for (final t in periodTx) t.currency}.toList()
        ..sort();
      final mixed = seriesCodes.length > 1;
      final codes = seriesCodes.isEmpty ? <String>[currency] : seriesCodes;

      final incByMonth = <String, List<double>>{
        for (final c in codes) c: List<double>.filled(lastMonth + 1, 0),
      };
      final expByMonth = <String, List<double>>{
        for (final c in codes) c: List<double>.filled(lastMonth + 1, 0),
      };
      final totInc = <String, double>{for (final c in codes) c: 0};
      final totExp = <String, double>{for (final c in codes) c: 0};
      for (final t in periodTx) {
        if (t.date.month >= 1 && t.date.month <= lastMonth) {
          final target =
              t.type.isExpense ? expByMonth[t.currency]! : incByMonth[t.currency]!;
          target[t.date.month] += t.amount;
        }
        if (t.type.isExpense) {
          totExp[t.currency] = (totExp[t.currency] ?? 0) + t.amount;
        } else {
          totInc[t.currency] = (totInc[t.currency] ?? 0) + t.amount;
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
      final rowCode = <int, String>{};
      for (var m = 1; m <= lastMonth; m++) {
        for (final code in codes) {
          final inc = incByMonth[code]![m];
          final exp = expByMonth[code]![m];
          row([
            TextCellValue(mixed
                ? '${l10n.monthFull[m - 1]} · $code'
                : l10n.monthFull[m - 1]),
            DoubleCellValue(inc),
            DoubleCellValue(exp),
            DoubleCellValue(inc - exp),
          ]);
          rowCode[sheet.maxRows - 1] = code;
        }
      }
      final totalFrom = sheet.maxRows;
      for (final code in codes) {
        final inc = totInc[code]!;
        final exp = totExp[code]!;
        row([
          TextCellValue(mixed
              ? '${l10n.jornalTotalLabel} · $code'
              : l10n.jornalTotalLabel),
          DoubleCellValue(inc),
          DoubleCellValue(exp),
          DoubleCellValue(inc - exp),
        ]);
        rowCode[sheet.maxRows - 1] = code;
      }
      final monthTo = sheet.maxRows - 1;

      // Formato de moneda: con mezcla cada fila usa la moneda que le
      // corresponde; con moneda única, la de Ajustes (como siempre).
      NumFormat fmtOf(int rowIndex) {
        final info = currencyInfo(mixed ? rowCode[rowIndex]! : currency);
        final f = info.decimals > 0 ? '#,##0.${'0' * info.decimals}' : '#,##0';
        return NumFormat.custom(formatCode: f);
      }

      for (var r = monthFrom; r <= monthTo; r++) {
        for (var c = 1; c <= 3; c++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
          if (cell.value is DoubleCellValue) {
            cell.cellStyle = CellStyle(numberFormat: fmtOf(r));
          }
        }
      }
      // Balance por mes en verde/rojo conservando el formato numérico.
      for (var r = monthFrom; r < totalFrom; r++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
        final val = cell.value;
        if (val is DoubleCellValue) {
          cell.cellStyle = CellStyle(
            numberFormat: fmtOf(r),
            fontColorHex: val.value >= 0 ? _excelGreen : _excelRed,
            bold: true,
            fontSize: 10,
          );
        }
      }
      // Filas Total: fondo marrón + números con formato.
      for (var r = totalFrom; r <= monthTo; r++) {
        for (var c = 0; c < 4; c++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
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
                  numberFormat: fmtOf(r),
                );
        }
      }
    }

    // ── Gastos por categoría y cultivo (cruce) ──
    final expenseTx = periodTx.where((t) => t.type.isExpense).toList();
    if (expenseTx.isNotEmpty) {
      final nameById = {for (final c in crops) c.id: c.name};
      // Cada celda guarda la moneda por separado: la suma aritmética solo
      // sirve para ordenar las filas, nunca se imprime.
      final byCatCrop = <String, Map<String?, Map<String, double>>>{};
      for (final t in expenseTx) {
        final byCrop = byCatCrop.putIfAbsent(
            t.category, () => <String?, Map<String, double>>{});
        final byCur = byCrop.putIfAbsent(t.cropId, () => <String, double>{});
        byCur[t.currency] = (byCur[t.currency] ?? 0) + t.amount;
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
      for (final cat in expenseGroups.keys) {
        final byCrop = byCatCrop[cat];
        if (byCrop == null) continue;
        final sorted = byCrop.entries.toList()
          ..sort((a, b) =>
              amountsTotal(b.value).compareTo(amountsTotal(a.value)));
        for (final e in sorted) {
          row([
            TextCellValue(l10n.expenseCategory(cat)),
            TextCellValue(e.key == null
                ? l10n.cropUnspecified
                : (nameById[e.key] ?? e.key!)),
            mixedHeader
                ? TextCellValue(byCurrency(e.value))
                : DoubleCellValue(single(e.value)),
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
          // Trabajador con varias monedas → cada moneda con su código.
          r.isMixed
              ? TextCellValue(
                  byCurrencyText(r.byCurrency, (v, c) => formatMoneyLabel(v, c)))
              : DoubleCellValue(r.subtotal),
        ]);
      }
      _applyCurrencyFormat(sheet, currency, 2, payrollFrom, sheet.maxRows - 1);
      row([
        TextCellValue(l10n.reportPayrollTotal),
        null,
        payroll.isMixed
            ? TextCellValue(byCurrencyText(
                payroll.totalByCurrency, (v, c) => formatMoneyLabel(v, c)))
            : DoubleCellValue(payroll.total),
      ]);
      _applyCurrencyFormat(
          sheet, currency, 2, sheet.maxRows - 1, sheet.maxRows - 1);
      if (payroll.isMixed) {
        row([
          TextCellValue(
              l10n.currencyMixedByCurrencyNote(payroll.totalByCurrency.length)),
        ]);
      }
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
      final cashMixed = <String>{
        for (final r in cashRows)
          if (r.isMixed) ...r.currencies,
      };
      final cashFrom = sheet.maxRows;
      for (final r in cashRows) {
        row([
          TextCellValue(multiYear
              ? '${l10n.monthFull[r.month - 1]} ${r.year}'
              : l10n.monthFull[r.month - 1]),
          DoubleCellValue(r.budget),
          // Mes con moneda mixta: cada moneda con su código y sin saldo
          // (compararlo con el presupuesto sería mentira).
          r.isMixed
              ? TextCellValue(byCurrencyText(
                  r.laborByCurrency, (v, c) => formatMoneyLabel(v, c)))
              : DoubleCellValue(r.labor),
          r.isMixed
              ? TextCellValue(byCurrencyText(
                  r.extrasByCurrency, (v, c) => formatMoneyLabel(v, c)))
              : DoubleCellValue(r.extras),
          r.isMixed
              ? TextCellValue(byCurrencyText(
                  r.totalByCurrency, (v, c) => formatMoneyLabel(v, c)))
              : DoubleCellValue(r.total),
          r.isMixed ? TextCellValue('—') : DoubleCellValue(r.balance),
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
      if (cashMixed.isNotEmpty) {
        row([
          TextCellValue(l10n.currencyMixedByCurrencyNote(cashMixed.length)),
        ]);
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
    // Mismo criterio que la pantalla y el PDF ([cropBreakdownRows]):
    // moneda única → números de siempre; mezcla → cada monto con su
    // código, sin resultado ni ROI, y una fila de aviso al final.
    final breakdown = cropBreakdownRows(
      records: periodTx,
      crops: crops,
      unspecifiedName: l10n.cropUnspecified,
    );
    const startRow = 1;
    var r = startRow;
    final mixedCurrencies = <String>{};
    for (final row in breakdown.where((row) => row.hasAnyAmount)) {
      if (row.isMixed) {
        mixedCurrencies.addAll(row.currencies);
        sheet.appendRow([
          TextCellValue(row.name),
          IntCellValue(row.count),
          TextCellValue(
              byCurrencyText(row.expenses, (v, c) => formatMoneyLabel(v, c))),
          TextCellValue(
              byCurrencyText(row.incomes, (v, c) => formatMoneyLabel(v, c))),
          TextCellValue('—'),
          TextCellValue('—'),
        ]);
        r++;
        continue;
      }
      final exp = row.expensesTotal;
      final inc = row.incomesTotal;
      final roi = exp <= 0
          ? '—'
          : '${(((inc - exp) / exp) * 100).toStringAsFixed(0)}%';
      sheet.appendRow([
        TextCellValue(row.name),
        IntCellValue(row.count),
        DoubleCellValue(exp),
        DoubleCellValue(inc),
        DoubleCellValue(inc - exp),
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
    if (mixedCurrencies.isNotEmpty) {
      sheet.appendRow([
        TextCellValue(
            l10n.currencyMixedByCurrencyNote(mixedCurrencies.length)),
      ]);
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

    // Costo de recogida por kg. Solo es válido si todos los montos que lo
    // componen son de una moneda; con mezcla sale en guion y se explica.
    final mixedCurrencies = <String>{};
    final pickupCurrencies = metrics.pickupCostCurrencies(periodTx);
    final pickupMixed = pickupCurrencies.length > 1;
    final pickupKg = metrics.pickupCostPerKg(periodTx, periodHarvests);
    if (pickupKg != null || pickupMixed) {
      if (pickupMixed) mixedCurrencies.addAll(pickupCurrencies);
      row([null, null, null]);
      row([
        TextCellValue(l10n.reportPickupCostPerKg),
        pickupMixed ? TextCellValue('—') : DoubleCellValue(pickupKg!),
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
      // Monedas de los montos del cultivo: con dos o más no hay ni costo
      // por kilo ni inversión en una sola cifra.
      final cropCurrencies = metrics.cropAmountCurrencies(cropExpenses);
      final cropMixed = cropCurrencies.length > 1;
      if (cropMixed) mixedCurrencies.addAll(cropCurrencies);

      if (crop.phase == CropPhase.establecimiento ||
          crop.phase == CropPhase.renovacion) {
        // Inversión: total en una moneda → cifra de siempre; con mezcla,
        // cada moneda con su código.
        row([
          TextCellValue('${crop.name} — ${l10n.reportInvestmentEstablecimiento}'),
          cropMixed
              ? TextCellValue(byCurrencyText(amountsByCurrency(cropExpenses),
                  (v, cur) => formatMoneyLabel(v, cur)))
              : DoubleCellValue(metrics.accumulatedInvestment(cropExpenses)),
        ]);
      } else {
        final totalKg = metrics.totalCostPerKg(crop, cropExpenses, cropHarvests);
        if (totalKg != null || cropMixed) {
          row([
            TextCellValue('${crop.name} — ${l10n.reportTotalCostPerKg}'),
            cropMixed ? TextCellValue('—') : DoubleCellValue(totalKg!),
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

    // Aviso: los costos por kilo no salen en una cifra porque los montos
    // que los componen están en más de una moneda.
    if (mixedCurrencies.isNotEmpty) {
      row([null, null, null]);
      row([
        TextCellValue(
            l10n.currencyMixedByCurrencyNote(mixedCurrencies.length)),
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