import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/currencies.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/top_accounts.dart';
import '../models/transaction.dart';
import 'alert_service.dart';
import 'recommendations.dart';
import 'report_harvest_metrics.dart';

enum ReportPeriod { month, year, yearToDate }

const _pdfPositive = PdfColor.fromInt(0xFF1F5E3F);
const _pdfPositiveSoft = PdfColor.fromInt(0xFFE7F0EA);
const _pdfNegative = PdfColor.fromInt(0xFFB3261E);
const _pdfNegativeSoft = PdfColor.fromInt(0xFFF9E4E2);

class PdfExportService {
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

  static Future<pw.Font> _regularFont() async {
    return _cachedRegular ??= pw.Font
        .ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  }

  static Future<pw.Font> _boldFont() async {
    return _cachedBold ??= pw.Font
        .ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  }

  /// Genera un reporte PDF del período indicado.
  /// Devuelve los bytes listos para guardar/compartir.
  Future<Uint8List> buildReport({
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
  }) async {
    final active = transactions.where((t) => !t.deleted).toList();

    double sum(List<Transaction> list, TransactionType type) =>
        list.where((t) => t.type == type).fold(0.0, (a, t) => a + t.amount);

    final now = DateTime.now();
    final periodTx = switch (period) {
      ReportPeriod.month => active
          .where((t) => t.date.year == year && t.date.month == (month ?? now.month))
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

    final currency = settings.currency;
    final showYearAnnex = period != ReportPeriod.year;

    final incomeTotals = _groupTotals(
        periodTx.where((t) => t.type == TransactionType.income).toList());
    final expenseTotals = _groupTotals(
        periodTx.where((t) => t.type == TransactionType.expense).toList());
    final margen = incomes > 0 ? (balance / incomes) * 100 : null;
    final ratio = incomes > 0 ? (expenses / incomes) * 100 : null;
    final resultColor = balance < 0 ? _pdfNegative : _pdfPositive;

    final regular = await _regularFont();
    final bold = await _boldFont();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: regular,
          bold: bold,
        ),
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            settings.farmName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
          ),
          pw.Text(
            l10n.pdfIncomeStatement(periodName),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: PdfColors.brown600,
            ),
          ),
          pw.Text(
            l10n.pdfGeneratedOn(
              DateTime.now().toIso8601String().split('T').first,
              currency,
            ),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          _statementRow(l10n.pdfIncomesHeader, formatPdfMoney(incomes, currency),
              bold: true, valueColor: _pdfPositive),
          if (incomeTotals.isEmpty)
            _statementRow(l10n.pdfNoIncomeSub, '',
                small: true, valueColor: PdfColors.grey700),
          ...incomeTotals.entries.map((e) => _statementRow(
                '    ${l10n.incomeCategory(e.key)}',
                '${_pctOf(e.value, incomes)}%   '
                '${formatPdfMoney(e.value, currency)}',
                small: true,
                valueColor: _pdfPositive,
              )),
          _statementRow(l10n.pdfExpensesHeader,
              formatPdfMoney(-expenses, currency),
              bold: true, valueColor: _pdfNegative),
          if (expenseTotals.isEmpty)
            _statementRow(l10n.pdfNoExpensesSub, '',
                small: true, valueColor: PdfColors.grey700),
          ...expenseTotals.entries.map((e) => _statementRow(
                '    ${l10n.expenseCategory(e.key)}',
                '${_pctOf(e.value, expenses)}%   '
                '${formatPdfMoney(-e.value, currency)}',
                small: true,
                valueColor: _pdfNegative,
              )),
          pw.Divider(),
          _statementRow(l10n.resultPeriodLabel,
              formatPdfMoney(balance, currency),
              bold: true,
              valueColor: resultColor,
              background: balance < 0 ? _pdfNegativeSoft : _pdfPositiveSoft),
          _statementRow(
              l10n.marginLabel,
              margen != null ? '${_pctOf(margen, 1)}%' : '—',
              small: true,
              valueColor: resultColor),
          _statementRow(
              l10n.ratioLabel,
              ratio != null ? '${_pctOf(ratio, 1)}%' : '—',
              small: true,
              valueColor: PdfColors.grey700),
          pw.SizedBox(height: 20),
          _topAccounts(periodTx, l10n, currency),
          pw.SizedBox(height: 20),
          pw.Text(
            l10n.pdfCropBreakdown(periodName),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          _cropTable(context, periodTx, crops, currency, l10n),
          if (showYearAnnex) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.pdfYearAnnex(year),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            _cropTable(
                context, active.where((t) => t.date.year == year), crops, currency, l10n),
          ],
          pw.SizedBox(height: 20),
          _harvestSection(periodTx, periodHarvests, crops, sowings,
              currency, l10n),
          pw.SizedBox(height: 20),
          _soldVsHarvestedSection(
              periodTx, periodHarvests, crops, sowings, currency, l10n),
          pw.SizedBox(height: 20),
          _recommendationsSection(
              periodTx, crops, harvests, sowings, l10n),
          pw.SizedBox(height: 12),
          pw.Text(
            l10n.pdfRoiFootnote,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

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

  pw.Widget _statementRow(String label, String value,
      {bool bold = false,
      bool small = false,
      PdfColor? valueColor,
      PdfColor? background}) {
    final f = small ? 9.0 : 11.0;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration:
          background != null ? pw.BoxDecoration(color: background) : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: f,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: f,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  String formatPdfMoney(double value, String currency) {
    final info = currencyInfo(currency);
    final s = '${info.symbol}${value.abs().toStringAsFixed(info.decimals)}';
    return value < 0 ? '($s)' : s;
  }

  /// Sección "Principales compradores / proveedores" del período.
  /// Solo se muestra si hay ventas con cliente o gastos con proveedor.
  pw.Widget _topAccounts(Iterable<Transaction> source,
      AppLocalizations l10n, String currency) {
    final accounts = TopAccounts.from(source.toList());
    if (accounts.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (accounts.clients.isNotEmpty)
          _topAccountBlock(l10n.topClientsTitle, accounts.topClients(3),
              currency),
        if (accounts.providers.isNotEmpty)
          _topAccountBlock(l10n.topProvidersTitle, accounts.topProviders(3),
              currency),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _topAccountBlock(
      String title, List<MapEntry<String, AccountTotal>> rows, String currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ...rows.map((e) => _statementRow(
              '    ${e.key} (${e.value.count})',
              formatPdfMoney(e.value.amount, currency),
              small: true,
            )),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _cropTable(pw.Context context, Iterable<Transaction> source,
      List<Crop> crops, String currency, AppLocalizations l10n) {
    return pw.TableHelper.fromTextArray(
      headers: [
        l10n.pdfColCrop,
        l10n.pdfColMov,
        l10n.pdfColExpenses,
        l10n.pdfColIncomes,
        l10n.pdfColResult,
        l10n.pdfColRoi,
      ],
      data: _cropRows(context, source, crops, currency, l10n),
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  List<List<String>> _cropRows(pw.Context context, Iterable<Transaction> source,
      List<Crop> crops, String currency, AppLocalizations l10n) {
    final nameById = {for (final c in crops) c.id: c.name};
    final totals = <String?, _CropTotalRow>{
      null: _CropTotalRow(name: l10n.cropUnspecified),
    };
    for (final c in crops) {
      totals.putIfAbsent(c.id, () => _CropTotalRow(name: c.name));
    }

    for (final t in source) {
      final row = totals.putIfAbsent(t.cropId, () {
        final name = t.cropId == null
            ? l10n.cropUnspecified
            : (nameById[t.cropId] ?? t.cropId!);
        return _CropTotalRow(name: name);
      });
      if (t.type.isExpense) {
        row.expenses += t.amount;
      } else {
        row.incomes += t.amount;
      }
      row.count++;
    }

    return totals.values
        .where((r) => r.expenses > 0 || r.incomes > 0)
        .map((r) {
      final roi = r.expenses <= 0
          ? '—'
          : '${(((r.incomes - r.expenses) / r.expenses) * 100).toStringAsFixed(0)}%';
      return [
        r.name,
        r.count.toString(),
        formatPdfMoney(r.expenses, currency),
        formatPdfMoney(r.incomes, currency),
        formatPdfMoney(r.incomes - r.expenses, currency),
        roi,
      ];
    }).toList();
  }

  // ---- Nivel 2: cosechas, rendimiento, conciliación y "Qué hacer" ----

  pw.Widget _harvestSection(
      Iterable<Transaction> source,
      List<Harvest> periodHarvests,
      List<Crop> crops,
      List<Sowing> sowings,
      String currency,
      AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    if (periodHarvests.isEmpty) return pw.SizedBox.shrink();

    final byCrop = metrics.totalsByCrop(periodHarvests, crops);
    final byDestination = metrics.totalsByDestination(periodHarvests);
    final pickupKg = metrics.pickupCostPerKg(source.toList(), periodHarvests);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportHarvestSection,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          l10n.reportHarvestedTotal,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        ...byCrop.map((c) => _statementRow(
              '    ${c.name}',
              '${_num(c.amount)} ${c.unit}   '
              '(${_numKg(c.kg)} ${l10n.reportHarvestKg})',
              small: true,
            )),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.reportHarvestDestinations,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        ...byDestination.entries.map((e) => _statementRow(
              '    ${_destinationLabel(e.key, l10n)}',
              _num(e.value),
              small: true,
            )),
        if (pickupKg != null) ...[
          pw.SizedBox(height: 2),
          _statementRow(
            l10n.reportPickupCostPerKg,
            formatPdfMoney(pickupKg, currency),
            small: true,
            bold: true,
          ),
        ],
        // Costo total por kg e indicadores por cultivo (producción).
        ..._perCropHarvestRows(byCrop, crops, periodHarvests, source.toList(),
            sowings, currency, l10n),
      ],
    );
  }

  List<pw.Widget> _perCropHarvestRows(
      List<CropHarvestTotal> byCrop,
      List<Crop> crops,
      List<Harvest> harvests,
      List<Transaction> transactions,
      List<Sowing> sowings,
      String currency,
      AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    final cropById = {for (final c in crops) c.id: c};
    final out = <pw.Widget>[];

    for (final c in byCrop) {
      final crop = c.cropId == null ? null : cropById[c.cropId];
      if (crop == null) continue;
      final cropHarvests =
          harvests.where((h) => h.cropId == crop.id).toList();
      final cropExpenses =
          transactions.where((t) => t.cropId == crop.id).toList();
      final hasResiembra =
          sowings.any((s) => s.cropId == crop.id && s.kind == SowingKind.resiembra);

      if (crop.phase == CropPhase.establecimiento ||
          crop.phase == CropPhase.renovacion) {
        final inv = metrics.accumulatedInvestment(cropExpenses);
        out.add(_statementRow(
          '    ${crop.name} — ${l10n.reportInvestmentEstablecimiento}',
          formatPdfMoney(inv, currency),
          small: true,
        ));
      } else {
        final totalKg = metrics.totalCostPerKg(
            crop, cropExpenses, cropHarvests);
        if (totalKg != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.reportTotalCostPerKg}',
            formatPdfMoney(totalKg, currency),
            small: true,
          ));
        }
        final yieldArea = metrics.yieldPerArea(cropHarvests, crop.areaHa);
        if (yieldArea != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.reportYieldPerArea}',
            '${_numKg(yieldArea)}${hasResiembra ? ' ${l10n.reportApprox}' : ''}',
            small: true,
          ));
        }
        final yieldPlant = metrics.yieldPerPlant(cropHarvests, crop.livePlants);
        if (yieldPlant != null) {
          out.add(_statementRow(
            '    ${crop.name} — ${l10n.reportYieldPerPlant}',
            '${_numKg(yieldPlant)}${hasResiembra ? ' ${l10n.reportApprox}' : ''}',
            small: true,
          ));
        }
      }
    }
    return out;
  }

  pw.Widget _soldVsHarvestedSection(
      Iterable<Transaction> source,
      List<Harvest> periodHarvests,
      List<Crop> crops,
      List<Sowing> sowings,
      String currency,
      AppLocalizations l10n) {
    const metrics = ReportHarvestMetrics();
    final rows = metrics.soldVsHarvested(
        source.toList(), periodHarvests, crops, DateTime.now());
    if (rows.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportSoldVsHarvested,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        ...rows.map((r) => _statementRow(
              '    ${r.name} — ${l10n.reportSoldKg}',
              _numKg(r.soldKg),
              small: true,
            )),
        ...rows.map((r) => _statementRow(
              '    ${r.name} — ${l10n.reportHarvestedKg}',
              _numKg(r.harvestedKg),
              small: true,
            )),
      ],
    );
  }

  pw.Widget _recommendationsSection(
      Iterable<Transaction> source,
      List<Crop> crops,
      List<Harvest> harvests,
      List<Sowing> sowings,
      AppLocalizations l10n) {
    final alerts = const AlertService().evaluate(
      source.toList(),
      crops,
      l10n,
      harvests: harvests,
      sowings: sowings,
    );
    final recommendations = const RecommendationService().derive(alerts, 4);
    if (recommendations.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportWhatsNext,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        for (var i = 0; i < recommendations.length; i++) ...[
          _statementRow(
            '${i + 1}. ${recommendations[i].title}',
            '',
            small: true,
            bold: true,
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Text(
              recommendations[i].message,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ],
    );
  }

  String _destinationLabel(HarvestDestination d, AppLocalizations l10n) =>
      switch (d) {
        HarvestDestination.vendido => l10n.harvestDstVendido,
        HarvestDestination.almacenado => l10n.harvestDstAlmacenado,
        HarvestDestination.perdida => l10n.harvestDstPerdida,
      };

  String _num(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String _numKg(double v) => v >= 100
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
}

class _CropTotalRow {
  final String name;
  int count = 0;
  double expenses = 0;
  double incomes = 0;

  _CropTotalRow({required this.name});
}