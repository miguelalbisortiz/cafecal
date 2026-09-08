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
    List<Harvest> harvests = const [],
    List<Sowing> sowings = const [],
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

    final periodHarvests = switch (period) {
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
        ratio: ratio);

    _cropsSheet(excel[l10n.excelSheetCrops],
        periodTx: periodTx, crops: crops, l10n: l10n);

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
      TextCellValue(l10n.excelColQty),
      TextCellValue(l10n.excelColUnit),
      TextCellValue(l10n.excelColPricePerUnit),
      TextCellValue(l10n.excelColClient),
      TextCellValue(l10n.excelColProvider),
    ]);
    final nameById = {for (final c in crops) c.id: c.name};
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
              'arroba' => TextCellValue(l10n.unitArroba),
              'saco' => TextCellValue(l10n.unitSaco),
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
        DoubleCellValue(t.type.isExpense ? -t.amount : t.amount),
        t.quantity == null ? null : DoubleCellValue(t.quantity!),
        unitLabel,
        pricePerUnit,
        t.client == null ? null : TextCellValue(t.client!),
        t.provider == null ? null : TextCellValue(t.provider!),
      ]);
    }
    for (var i = 0; i < 11; i++) {
      sheet.setColumnWidth(i, i == 3 ? 40 : 18);
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